"""The local KB gate: merge a verified kb-watch PR, or hold it for Son as one issue (behavior 145;
it replaces .github/workflows/kb-gate.yml).

Regulated figures are grounded -> P-7 -> The KB update -> the local gate merges a kb-watch PR only on this Mac's own verdict and checks for its head
Invariant: a PR merges here only if it is a same-repo kb-watch-* branch whose every changed
  path is under docs/kb/ or docs/sources/, this Mac's kb-verify recorded kb-verified for its
  exact head sha, the done checks passed here on that sha, and scripts/kb_gate.py from
  origin/main says merge. Nothing from a PR runs before its paths are classified; a label,
  a comment or a fork's branch name counts for nothing.
Mechanism: plan_pr() is the pure rule (selftest's Expect 4 property draws its inputs);
  run() lists open PRs with the runner's token, fetches each candidate head into the
  runner's checkout (at origin/main, so kb_gate.py and the checks are main's), classifies
  its paths with `git diff --no-renames` before anything runs, runs the done checks in a
  fresh clone at the head (the same setup CI had: uv sync, kb_compiler, npm ci), caches the
  result by sha, then asks kb_gate.py with --labels from ~/state/verdicts.json. A merge is
  `gh pr merge --merge --match-head-commit <sha>`; a hold comments on the PR and keeps one
  issue `kb-gate: #<n> held` for Son. A PR whose sha and decision are unchanged since the
  last run is left alone, so a held PR is not commented on every day.
Capability: `run_job.sh gate` → `python3 gate.py`; self_test(check, seed, n) for selftest.py.
"""
from __future__ import annotations

import json
import random
import shutil
import subprocess
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import autolib as A  # noqa: E402

PREFIX = "kb-watch-"


def plan_pr(pr: dict, paths: list[str] | None, verdict: dict | None, run_checks, kb_decide) -> dict:
    """What the gate does with one open PR. `paths` is the head's diff against main (None if
    the head could not be read); `verdict` this Mac's kb-verify entry for the branch;
    run_checks(sha) -> bool and kb_decide(labels, checks_ok) -> 'merge'|'hold' are called
    only when the rule allows (the property counts their calls)."""
    sha, branch = pr["headRefOid"], pr["headRefName"]
    if pr.get("isCrossRepository") or pr.get("baseRefName") != "main" \
            or not branch.startswith(PREFIX):
        return {"action": "skip", "why": "not a same-repo kb-watch-* PR into main"}
    if paths is None:
        return {"action": "skip", "why": "its head could not be read"}
    outside = [p for p in paths if not A.allowed_path(p)]
    if outside or not paths:
        return {"action": "hold", "why": "changes outside docs/kb and docs/sources: "
                + ", ".join(outside[:10]) if outside else "an empty diff", "checks": None}
    ok = bool(run_checks(sha))
    labels = set()
    if verdict and verdict.get("sha") == sha and verdict.get("verdict") in ("kb-verified", "kb-hold"):
        labels.add(verdict["verdict"])
    decision = kb_decide(labels, ok)
    merge = decision == "merge" and ok and labels == {"kb-verified"}
    return {"action": "merge" if merge else "hold", "checks": ok, "labels": sorted(labels),
            "why": "kb-verified here at its head, checks passed here, kb_gate: merge" if merge
            else f"kb_gate: {decision}; checks {'passed' if ok else 'failed'}; "
                 f"local verdict {sorted(labels) or 'none for this sha'}"}


def diff_paths(sha: str) -> list[str] | None:
    try:
        A.git(A.RUNNER, "cat-file", "-e", f"{sha}^{{commit}}")
        out = A.git(A.RUNNER, "diff", "--no-renames", "-z", "--name-only", f"origin/main...{sha}")
    except RuntimeError:
        return None
    return [p for p in out.split("\0") if p]


def done_checks(sha: str, log) -> bool:
    """The done checks on a fresh clone at `sha`, cached by sha in ~/state/checks.json."""
    cache_file = A.STATE / "checks.json"
    cache = json.loads(cache_file.read_text()) if cache_file.is_file() else {}
    if sha in cache:
        log(f"  done checks at {sha[:10]}: {cache[sha]['result']} (cached {cache[sha]['at']})")
        return cache[sha]["result"] == "pass"
    d = A.STATE / f"checks-{sha[:12]}"
    shutil.rmtree(d, ignore_errors=True)
    tmp = A.STATE / "tmp"
    tmp.mkdir(parents=True, exist_ok=True)
    env = {"PATH": A.TOOLCHAIN_PATH, "HOME": str(A.HOME), "LANG": "en_US.UTF-8", "TMPDIR": str(tmp),
           "GIT_CONFIG_NOSYSTEM": "1", "GIT_CONFIG_GLOBAL": "/dev/null", **A.net_env()}
    steps = [["git", "-c", "core.hooksPath=/dev/null", "clone", "--quiet", "--no-checkout",
              str(A.RUNNER), str(d)],
             ["git", "-c", "core.hooksPath=/dev/null", "-C", str(d), "checkout", "--quiet", sha],
             ["uv", "sync", "--frozen", "--quiet"],
             [".venv/bin/python", "engine/build/kb_compiler.py"],
             ["npm", "ci", "--silent", "--prefix", "shell/web/frontend"],
             ["bash", "scripts/done_checks.sh"]]
    result, tail = "pass", ""
    t0 = time.time()
    for i, s in enumerate(steps):
        r = subprocess.run(s, cwd=A.STATE if i == 0 else d, env=env, capture_output=True,
                           text=True, timeout=3600)
        if r.returncode:
            result, tail = "fail", f"{' '.join(s[:3])}: " + (r.stdout + r.stderr)[-1500:]
            break
        last = r.stdout.strip().splitlines()
        tail = last[-1] if last else tail
    log(f"  done checks at {sha[:10]}: {result} in {time.time() - t0:.0f}s — {tail.strip()[:300]}")
    cache[sha] = {"result": result, "at": time.strftime("%Y-%m-%dT%H:%M:%S%z")}
    A.write_json(cache_file, cache)
    shutil.rmtree(d, ignore_errors=True)
    return result == "pass"


def kb_gate(base: str, sha: str, branch: str, labels: set, ok: bool, pr: str, out: Path) -> dict:
    """scripts/kb_gate.py from the runner's checkout (origin/main), as the workflow ran it."""
    subprocess.run([sys.executable, str(A.RUNNER / "scripts/kb_gate.py"), "--base", base,
                    "--head", sha, "--branch", branch, "--labels", ",".join(sorted(labels)),
                    "--checks-ok", "yes" if ok else "no", "--live", "yes", "--out", str(out),
                    "--pr", pr], cwd=A.RUNNER, check=True, capture_output=True)
    return json.loads((out / "decision.json").read_text())


def run() -> int:
    stamp = time.strftime("%Y%m%dT%H%M%S")
    import runner
    log = runner.Log(A.LOGS / f"gate-{stamp}.log")
    A.STATE.mkdir(parents=True, exist_ok=True)
    import fcntl
    lock = open(A.STATE / "lock", "w")
    try:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        log("gate: another job is running; skipped")
        return 1
    try:
        base = runner.fetch_runner(log)
        prs = json.loads(A.gh("pr", "list", "-R", A.REPO_SLUG, "--state", "open", "--limit", "100",
                              "--json", "number,headRefName,headRefOid,baseRefName,"
                                        "isCrossRepository") or "[]")
        vfile, gfile = A.STATE / "verdicts.json", A.STATE / "gate.json"
        verdicts = json.loads(vfile.read_text()) if vfile.is_file() else {}
        seen = json.loads(gfile.read_text()) if gfile.is_file() else {}
        log(f"gate: {len(prs)} open PR(s)")
        for pr in prs:
            n, sha, branch = str(pr["number"]), pr["headRefOid"], pr["headRefName"]
            same = not pr.get("isCrossRepository") and branch.startswith(PREFIX)
            if same:
                A.git(A.RUNNER, "fetch", "--quiet", "origin", sha, check=False)
            paths = diff_paths(sha) if same else None
            out = A.STATE / f"gate-{n}"
            got: dict = {}

            def decide(labels, ok):
                got.update(kb_gate(base, sha, branch, labels, ok, n, out))
                return got["decision"]

            p = plan_pr(pr, paths, verdicts.get(branch), lambda s: done_checks(s, log), decide)
            log(f"#{n} {branch} {sha[:10]}: {p['action']} — {p['why']}")
            if p["action"] == "skip":
                continue
            key = f"{sha}:{p['action']}:{','.join(p.get('labels') or [])}"
            if seen.get(n) == key:
                log(f"  #{n}: unchanged since the last run; nothing to say")
                continue
            if p["action"] == "merge":
                A.gh("pr", "merge", n, "-R", A.REPO_SLUG, "--merge", "--match-head-commit", sha)
                log(f"  #{n}: merged at {sha[:10]}")
            else:
                body = (out / "comment.md").read_text() if (out / "comment.md").is_file() else \
                    f"kb-gate (local): held — {p['why']}\n"
                A.gh("pr", "comment", n, "-R", A.REPO_SLUG, "--body-file", "-",
                     input=body + "\n_Local gate on Son's Mac (behavior 145)._\n")
                issue = (out / "issue.md").read_text() if (out / "issue.md").is_file() else \
                    f"PR #{n} ({branch}) is held: {p['why']}\n"
                A.file_issue(f"kb-gate: #{n} held", issue, log)
            seen[n] = key
            A.write_json(gfile, seen)
            shutil.rmtree(out, ignore_errors=True)
        return 0
    except Exception as e:
        log(f"gate: stopped — {type(e).__name__}: {e}")
        return 1


def self_test(check, seed: int, n: int) -> None:
    """Expect 4: for all drawn gate inputs, checks run and merges happen only as the rule says."""
    rng = random.Random(seed)
    bad = []
    for case in range(n):
        sha = "%040x" % rng.getrandbits(160)
        fork = rng.random() < 0.25
        branch = rng.choice(["kb-watch-2026-11-02", "kb-watch-news-2026-11-01", "b145-x",
                             "main", "kb-watchx", "fix/kb-watch-1"])
        base_ref = rng.choice(["main"] * 5 + ["release"])
        paths = rng.choice([
            ["docs/kb/news/a.md"], ["docs/sources/x/y.txt", "docs/kb/f.md"],
            ["scripts/kb_gate.py"], ["docs/kb/a.md", ".github/workflows/x.yml"],
            ["tests/t.py"], ["docs/kb/../../scripts/x.py"], [], None, ["docs/kb/.hidden"]])
        verdict = rng.choice([None, {"sha": sha, "verdict": "kb-verified"},
                              {"sha": "%040x" % rng.getrandbits(160), "verdict": "kb-verified"},
                              {"sha": sha, "verdict": "kb-hold"}])
        labels_on_github = rng.choice([[], ["kb-verified"], ["kb-verified", "kb-hold"]])
        checks_pass = rng.random() < 0.7
        kb_says = rng.choice(["merge", "hold"])
        calls = {"checks": 0, "kb": 0}

        def rc(s):
            calls["checks"] += 1
            return checks_pass

        def kd(labels, ok):
            calls["kb"] += 1
            return kb_says

        pr = {"number": case, "headRefOid": sha, "headRefName": branch, "baseRefName": base_ref,
              "isCrossRepository": fork, "labels": labels_on_github}
        p = plan_pr(pr, paths, verdict, rc, kd)
        eligible = (not fork and base_ref == "main" and branch.startswith("kb-watch-")
                    and paths is not None and bool(paths) and all(A.allowed_path(x) for x in paths))
        may_merge = (eligible and verdict is not None and verdict["sha"] == sha
                     and verdict["verdict"] == "kb-verified" and checks_pass and kb_says == "merge")
        if (calls["checks"] > 0) != eligible or (p["action"] == "merge") != may_merge:
            bad.append(f"case {case}: fork {fork} {branch} base {base_ref} paths {paths} "
                       f"verdict {verdict} checks {checks_pass} kb {kb_says} → {p}, "
                       f"checks run {calls['checks']}")
    check(f"gate property: {n} cases, seed {seed}", not bad,
          f"{len(bad)} counterexamples, first: {bad[0] if bad else ''}")


if __name__ == "__main__":
    sys.exit(run())
