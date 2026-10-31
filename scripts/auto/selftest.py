"""Offline self-test of the local KB jobs (behavior 145): run by `bash scripts/auto/selftest.sh`,
one of the done checks.

Regulated figures are grounded -> R-3 -> The KB update -> selftest proves, offline and on every change, what the runner, publisher, archive gate and local gate let through
Invariant: the properties behavior 145 rests on hold on the code as committed: the agent's
  settings confine it; the publisher commits only regular files under docs/kb and
  docs/sources (Expect 2); archive_source fetches only https on a source host (Expect 3);
  the gate runs checks and merges only as its rules say (Expect 4); the launchd jobs run as
  ancuauto at the agreed local times (Expect 1).
Mechanism: seeded random draws (seed 145, 400 cases each) of the inputs an agent or a page
  would pick, each labelled by how it was built, checked against the real code: publish.plan
  and build_commit on a scratch repo, archive_source.py run with a stub curl on PATH that
  records whether it was called, gate.decide on drawn PR states; plus the static checks.
Capability: `python3 scripts/auto/selftest.py` → one `ok …` line per check and exit 0, or
  `FAIL …` lines with the first counterexample and exit 1.
"""
from __future__ import annotations

import os
import plistlib
import random
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
TMP = Path(tempfile.mkdtemp(prefix="ancu-selftest-"))
os.environ["ANCU_AUTO_HOME"] = str(TMP / "home")
os.environ["ANCU_AUTO_LOGS"] = str(TMP / "logs")
os.environ["ANCU_AUTO_SHARED"] = str(TMP / "shared")
sys.path.insert(0, str(HERE))
import autolib as A  # noqa: E402
import publish  # noqa: E402

SEED, N = 145, 400
FAILS: list[str] = []


def check(name: str, ok: bool, detail: str = "") -> None:
    print(f"{'ok  ' if ok else 'FAIL'} {name}" + (f" — {detail}" if detail and not ok else ""))
    if not ok:
        FAILS.append(name)


def sh(*args, cwd=None, input=None) -> str:
    env = {**os.environ, "GIT_CONFIG_GLOBAL": "/dev/null", "GIT_CONFIG_NOSYSTEM": "1",
           "GIT_AUTHOR_NAME": "t", "GIT_AUTHOR_EMAIL": "t@t", "GIT_COMMITTER_NAME": "t",
           "GIT_COMMITTER_EMAIL": "t@t"}
    return subprocess.run(args, cwd=cwd, input=input, check=True, capture_output=True,
                          env=env).stdout.decode()


# --- the agent's settings and the runner (Expect 1) -------------------------------------

def static_checks() -> None:
    for job in A.JOBS_TABLE:
        doc = (ROOT / A.JOBS_TABLE[job][0]).read_text()
        p = A.prompt(job)
        check(f"prompt {job} is its doc's one ---8<--- block",
              doc.count("---8<---\n") == 2 and p and p in doc)
    s = A.settings(Path("/Users/Shared/ancu-auto/jobs/x"))
    perm, sb = s["permissions"], s["sandbox"]
    allow = perm["allow"]
    check("settings: Read and Edit only ./**",
          [a for a in allow if not a.startswith("WebFetch(")] == ["Read(./**)", "Edit(./**)"])
    hosts = {a[len("WebFetch(domain:"):-1].lstrip("*.") for a in allow if a.startswith("WebFetch(")}
    check("settings: WebFetch only the source hosts", hosts == set(A.source_hosts()))
    check("settings: dontAsk", perm["defaultMode"] == "dontAsk")
    check("settings: Bash sandbox required, no unsandboxed escape",
          sb["enabled"] and sb["failIfUnavailable"] and sb["allowUnsandboxedCommands"] is False)
    fs = sb["filesystem"]
    check("settings: sandbox denyRead /Users, allowRead only the folder and toolchain",
          fs["denyRead"] == ["/Users"] and fs["allowWrite"] == ["/Users/Shared/ancu-auto/jobs/x"]
          and set(fs["allowRead"]) == {"/Users/Shared/ancu-auto/jobs/x", "/Users/ancuagent/.local",
                                       str(A.PY_DIR), "/Users/ancuagent/.claude-jobs"})
    check("settings: sandbox network only the source hosts",
          {d.lstrip("*.") for d in sb["network"]["allowedDomains"]} == set(A.source_hosts()))
    env = A.agent_env()
    check("agent env holds no GitHub token", not any(k.startswith(("GH_", "GITHUB")) for k in env))
    w = (HERE / "ancu-agent.sh").read_text()
    check("the agent runs as ancuagent only through the wrapper, with an environment of its own",
          A.AGENT_USER == "ancuagent" and str(A.WRAPPER) == "/usr/local/libexec/ancu-agent"
          and 'unset "$v"' in w and "umask 007" in w and 'exec "$H/.local/bin/claude" "$@"' in w
          and "GH_" not in w and "JOBS=/Users/Shared/ancu-auto/jobs" in w
          and '"sudo", "-n", "-u", AGENT_USER, str(WRAPPER)' in (HERE / "autolib.py").read_text()
          and "refusing to run the agent as the runner's" in (HERE / "autolib.py").read_text())
    rj = (HERE / "run_job.sh").read_text()
    check("run_job.sh runs the runner from its own checkout at origin/main, hooks off",
          "checkout --quiet --force --detach origin/main" in rj and "core.hooksPath=/dev/null" in rj
          and "exec /usr/bin/python3 scripts/auto/runner.py" in rj)
    rn = (HERE / "runner.py").read_text()
    check("runner publishes with its own publish.py, never from the job folder",
          "import publish" in rn and "sys.path.insert(0, str(Path(__file__)" in rn
          and rn.count("sys.path") == 1 and not re.search(r"runpy|exec\(|import_module|"
                                                          r"\[\"python|\.venv/bin|folder\s*/\s*\"scripts", rn))
    check("git in the runner: hooks and fsmonitor off, no global or system config",
          "core.hooksPath=/dev/null" in (HERE / "autolib.py").read_text()
          and A.git_env().get("GIT_CONFIG_GLOBAL") == "/dev/null")


PLISTS = {  # job -> launchd StartCalendarInterval (local time)
    "canary": {"Hour": 5, "Minute": 45},
    "news-watch": {"Hour": 6, "Minute": 0},
    "kb-watch": {"Weekday": 1, "Hour": 6, "Minute": 0},
    "kb-verify": {"Hour": 9, "Minute": 0},
    "gate": {"Hour": 9, "Minute": 45},
    "suburb-watch": {"Day": 1, "Hour": 7, "Minute": 0},
}


def plist_checks() -> None:
    d = ROOT / "ops" / "launchd"
    for job, when in PLISTS.items():
        p = d / f"com.s27183.ancu-auto.{job}.plist"
        if not p.is_file():
            check(f"plist {job}", False, f"{p} missing")
            continue
        lint = subprocess.run(["plutil", "-lint", str(p)], capture_output=True) \
            if shutil.which("plutil") else None
        pl = plistlib.loads(p.read_bytes())
        check(f"plist {job}: lint, UserName ancuauto, {when}",
              (lint is None or lint.returncode == 0) and pl.get("UserName") == "ancuauto"
              and pl.get("Label") == f"com.s27183.ancu-auto.{job}"
              and pl.get("StartCalendarInterval") == when
              and pl.get("ProgramArguments", [])[-1] == job
              and "/Users/ancuauto/ancu/scripts/auto/run_job.sh" in pl.get("ProgramArguments", []))


# --- the publisher (Expect 2) -----------------------------------------------------------

BASE_FILES = {"docs/kb/a.md": "a\n", "docs/kb/news/n.md": "n\n", "docs/sources/s.txt": "s\n",
              "scripts/x.py": "x\n", ".github/workflows/w.yml": "w\n", "tests/t.py": "t\n",
              ".gitignore": "ignored.json\n"}

OK_OPS = ["add docs/kb/news/{r}.md", "mod docs/kb/a.md", "add docs/sources/x/{r}.txt",
          "del docs/kb/news/n.md", "add docs/kb/a b {r}.md", "add docs/kb/tin-tức-{r}.md",
          "add ignored.json", "out ../outside-{r}.txt", "out /abs-{r}.txt"]
BAD_OPS = ["mod scripts/x.py", "add .github/workflows/e{r}.yml", "add tests/n{r}.py",
           "del scripts/x.py", "link docs/kb/l{r}.md", "linkdir docs/kb/d{r}",
           "add docs/kb/.hidden{r}.md", "add docs/kb/a\nb{r}.md", "fifo docs/sources/f{r}",
           "secret docs/kb/news/s{r}.md", "add scripts/auto/publish.py", "add README.md"]


def apply(folder: Path, op: str, outside: Path) -> None:
    kind, path = op.split(" ", 1)
    p = folder / path
    if kind == "out":
        (outside / Path(path).name).write_text("outside\n")
        return
    p.parent.mkdir(parents=True, exist_ok=True)
    if kind in ("add", "mod"):
        p.write_text(f"{kind} {path}\n")
    elif kind == "del":
        p.unlink()
    elif kind == "link":
        os.symlink("/etc/hosts", p)
    elif kind == "linkdir":
        os.symlink("/Users", p)
    elif kind == "fifo":
        os.mkfifo(p)
    elif kind == "secret":
        p.write_text("token ghp_" + "Ab1" * 12 + "\n")


def publisher_property() -> None:
    rng = random.Random(SEED)
    repo, pristine = TMP / "runner", TMP / "pristine"
    repo.mkdir()
    sh("git", "init", "-q", "-b", "main", cwd=repo)
    for f, t in BASE_FILES.items():
        (repo / f).parent.mkdir(parents=True, exist_ok=True)
        (repo / f).write_text(t)
    sh("git", "add", "-A", cwd=repo)
    sh("git", "commit", "-q", "-m", "base", cwd=repo)
    base = sh("git", "rev-parse", "HEAD", cwd=repo).strip()
    sh("git", "clone", "-q", str(repo), str(pristine))
    drawn_cases = []
    for case in range(N):
        pool = OK_OPS + (BAD_OPS if rng.random() < 0.5 else [])
        drawn = [rng.choice(pool) for _ in range(rng.randint(1, 4))]
        ops = [t.format(r=rng.randrange(999)) for t in drawn]
        drawn_cases.append((case, drawn, ops, rng.random() < 0.9))

    def run(c):
        case, drawn, ops, with_pr = c
        folder, outside = TMP / "f" / str(case) / "job", TMP / "f" / str(case)
        shutil.copytree(pristine, folder, symlinks=True)
        for op in dict.fromkeys(ops):
            try:
                apply(folder, op, outside)
            except (FileNotFoundError, FileExistsError):
                pass
        if with_pr:
            (folder / A.OUTBOX).mkdir(exist_ok=True)
            (folder / A.OUTBOX / "pr.md").write_text("news-watch test\nbody\n")
        changes = [o for o in dict.fromkeys(ops) if not o.startswith(("out ", "add ignored"))]
        any_bad = any(t in BAD_OPS for t in drawn)
        expect_commit = bool(changes) and not any_bad and with_pr
        lines: list[str] = []
        rc = publish.publish("news-watch", folder, base, f"t{case}", lines.append, repo=repo,
                             push=False)
        commit = next((l.split()[2] for l in lines if l.startswith("news-watch: commit ")), None)
        shutil.rmtree(outside, ignore_errors=True)
        if bool(commit) != expect_commit or (any_bad and not any(l.startswith("refused: ")
                                                                 for l in lines)):
            return (f"case {case} ops {ops} pr {with_pr}: expected commit {expect_commit}, "
                    f"got rc {rc} {lines[:3]}")
        if commit:
            names = {n for n in sh("git", "diff", "-z", "--name-only", base, commit,
                                   cwd=repo).split("\0") if n}
            if not names or not all(A.allowed_path(n) for n in names):
                return f"case {case}: commit holds {sorted(names)}"
        return None

    from concurrent.futures import ThreadPoolExecutor
    with ThreadPoolExecutor(8) as ex:
        bad = [r for r in ex.map(run, drawn_cases) if r]
    check(f"publisher property: {N} cases, seed {SEED}", not bad,
          f"{len(bad)} counterexamples, first: {bad[0] if bad else ''}")


# --- archive_source's URL gate (Expect 3) -----------------------------------------------

STUB = """#!/bin/sh
echo called >> "$STUB_LOG"
for a; do last=$a; done
printf '<html><title>t</title><p>page</p></html>\\n%s' "${STUB_FINAL:-$last}"
"""


def url_property() -> None:
    rng = random.Random(SEED)
    hosts = A.source_hosts()
    stubdir = TMP / "stub"
    stubdir.mkdir()
    (stubdir / "curl").write_text(STUB)
    (stubdir / "curl").chmod(0o755)

    def good():
        h = rng.choice(hosts)
        sub = rng.choice(["", "www.", "immi.", "a-b.c."])
        port = rng.choice(["", "", ":443"])
        path = rng.choice(["/", "/x/y.html", "/a?b=c&d=e", "#f", "/news/2026-10"])
        return f"https://{sub}{h}{port}{path}"

    def bad():
        h = rng.choice(hosts)
        return rng.choice([
            f"http://{h}/", "file:///Users/ancuauto/.config/ancu-auto/gh-token",
            f"file://{h}/etc/passwd", "data:text/html,<p>x</p>", f"ftp://{h}/x",
            f"https://evil.com\\@{h}/", f"https://evil.com@{h}/", f"https://{h}@evil.com/",
            f"https://{h}%2f@evil.com/", f"https://evil.com%2f{h}/", f"https://evil-{h}/",
            f"https://{h}.evil.com/", f"https://x{h}/", f"https://{h}:8443/",
            f"https://{h}:80/", f"https://аto.gov.au/", f"https://{h.upper()}/",
            f"HTTPS://{h}/", f" https://{h}/", f"https://{h}\\x/", "https:///x",
            f"//{h}/x", f"https://{h}:443@evil.com/", "javascript:alert(1)"])

    cases = []
    for case in range(N):
        is_good = rng.random() < 0.4
        url = good() if is_good else bad()
        cases.append((case, url, is_good, is_good and rng.random() < 0.25))
    (TMP / "arch").mkdir()

    def run(c):
        case, url, is_good, redirect_off = c
        log, out = TMP / "arch" / f"stub-{case}.log", TMP / "arch" / f"x-{case}.txt"
        env = {"PATH": f"{stubdir}:/usr/bin:/bin", "STUB_LOG": str(log), "HOME": str(TMP)}
        if redirect_off:
            env["STUB_FINAL"] = "https://evil.example/landing"
        r = subprocess.run([sys.executable, str(ROOT / "scripts/archive_source.py"), url, str(out)],
                           capture_output=True, text=True, env=env)
        called = log.is_file()
        if is_good and not redirect_off:
            ok = r.returncode == 0 and called and out.is_file()
        elif redirect_off:
            ok = r.returncode == 2 and not out.is_file()
        else:
            ok = r.returncode == 2 and not called and not out.is_file()
        return None if ok else (f"case {case} {url!r} good={is_good} redirect_off={redirect_off}: "
                                f"rc {r.returncode}, curl called {called}, {r.stderr.strip()[-200:]}")

    from concurrent.futures import ThreadPoolExecutor
    with ThreadPoolExecutor(8) as ex:
        bad_cases = [b for b in ex.map(run, cases) if b]
    check(f"archive_source URL property: {N} cases, seed {SEED}", not bad_cases,
          f"{len(bad_cases)} counterexamples, first: {bad_cases[0] if bad_cases else ''}")


# --- CI's scope and the gate agree on KB-only (Expect 12) ------------------------------

SCOPE_GOOD = ["add docs/kb/n{r}.md", "mod docs/kb/a.md", "del docs/kb/news/n.md",
              "add docs/sources/x/{r}.txt", "add docs/kb/tin tức {r}.md", "mv docs/kb/a.md docs/kb/m{r}.md"]
SCOPE_BAD = ["mod scripts/x.py", "add .github/workflows/e{r}.yml", "mv docs/kb/a.md scripts/a{r}.md",
             "mv scripts/x.py docs/kb/x{r}.py", "link docs/kb/l{r}.md", "sub docs/kb/s{r}",
             "exec docs/kb/e{r}.sh", "add docs/kb/.h{r}.md", "add tests/t{r}.py"]


def scope_property() -> None:
    import ci_scope
    import gate as G
    rng = random.Random(SEED)
    repo = TMP / "scope"
    repo.mkdir()
    sh("git", "init", "-q", "-b", "main", cwd=repo)
    for f, t in BASE_FILES.items():
        (repo / f).parent.mkdir(parents=True, exist_ok=True)
        (repo / f).write_text(t)
    sh("git", "add", "-A", cwd=repo)
    sh("git", "commit", "-q", "-m", "base", cwd=repo)
    base = sh("git", "rev-parse", "HEAD", cwd=repo).strip()
    bad = []
    for case in range(N):
        same = rng.random() < 0.75
        ref = rng.choice(["kb-watch-2026-11-02", "kb-watch-news-2026-11-01", "b145-x", "kb-watchx",
                          "fix/kb-watch-1"])
        pool = SCOPE_GOOD + (SCOPE_BAD if rng.random() < 0.5 else [])
        ops = list(dict.fromkeys(rng.choice(pool).format(r=rng.randrange(999))
                                 for _ in range(rng.randint(0, 3))))
        sh("git", "checkout", "-q", "-f", "-B", f"c{case}", base, cwd=repo)
        sh("git", "clean", "-fdq", cwd=repo)
        applied, gitlinks = [], []
        for op in ops:
            kind, path = op.split(" ", 1)
            p = repo / path
            if kind == "mv":
                src, dst = path.split(" ", 1) if path.count(" ") == 1 else (None, None)
                if src is None or not (repo / src).is_file():
                    continue
                (repo / dst).parent.mkdir(parents=True, exist_ok=True)
                (repo / src).rename(repo / dst)
            elif kind == "del":
                if not p.is_file():
                    continue
                p.unlink()
            elif kind == "sub":
                gitlinks.append(path)
            else:
                p.parent.mkdir(parents=True, exist_ok=True)
                if kind == "link":
                    os.symlink("../../scripts/x.py", p)
                else:
                    p.write_text(f"{op}\n")
                    if kind == "exec":
                        p.chmod(0o755)
            applied.append(op)
        sh("git", "add", "-A", cwd=repo)
        for g in gitlinks:
            sh("git", "update-index", "--add", "--cacheinfo", f"160000,{base},{g}", cwd=repo)
        sh("git", "commit", "-q", "--allow-empty", "-m", f"case {case}", cwd=repo)
        head = sh("git", "rev-parse", "HEAD", cwd=repo).strip()
        entries = ci_scope.diff_entries(repo, base, head)
        got, why = ci_scope.kb_only(same, ref, entries)
        is_bad = any(_matches(op, t) for op in applied for t in SCOPE_BAD)
        want = same and ref.startswith("kb-watch-") and bool(applied) and not is_bad
        calls = {"checks": 0}
        pr = {"number": case, "headRefOid": head, "headRefName": ref, "baseRefName": "main",
              "isCrossRepository": not same}
        G.plan_pr(pr, entries, {"sha": head, "verdict": "kb-verified"},
                  lambda _s: calls.__setitem__("checks", calls["checks"] + 1) or True,
                  lambda labels, ok: "merge")
        if got != want or (calls["checks"] > 0) != want:
            bad.append(f"case {case}: same {same} {ref} ops {applied} → kb_only {got} ({why}), "
                       f"gate ran checks {calls['checks']}, expected {want}")
    check(f"ci scope property: {N} cases, seed {SEED} (CI skips and the gate checks the same PRs)",
          not bad, f"{len(bad)} counterexamples, first: {bad[0] if bad else ''}")


def _matches(op: str, template: str) -> bool:
    """Whether `op` was drawn from `template` ({r} stands for digits)."""
    import re as _re
    pat = "^" + _re.escape(template).replace(_re.escape("{r}"), r"\d+") + "$"
    return bool(_re.match(pat, op))


def main() -> int:
    try:
        static_checks()
        if "--no-plists" not in sys.argv:
            plist_checks()
        publisher_property()
        url_property()
        gate = HERE / "gate.py"
        if gate.is_file() and "--no-gate" not in sys.argv:
            import gate as G
            G.self_test(check, SEED, N)
            scope_property()
    finally:
        shutil.rmtree(TMP, ignore_errors=True)
    print(f"selftest: {'ok' if not FAILS else f'{len(FAILS)} failed'}")
    return 1 if FAILS else 0


if __name__ == "__main__":
    sys.exit(main())
