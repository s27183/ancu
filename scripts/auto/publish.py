"""Publish what a job's agent left in its folder: one PR, one issue, or kb-verify's verdicts
(behavior 145).

Regulated figures are grounded -> R-3 -> The KB update -> the runner publishes only KB files, read with os, committed in its own repo
Invariant: what leaves this Mac from a job is a commit of regular files under docs/kb/ and
  docs/sources/, a PR and issue text with no secret in it, or a verdict bound to a head sha —
  never anything else the agent touched, and never by running git in the agent's folder.
Mechanism: plan() walks the folder with os (autolib.changed_files) against `git ls-tree` of
  the base in the runner's repo, leaves out what the base's .gitignore ignores, and refuses
  the whole set — "refused: <path>", nothing committed — if any changed or deleted path is
  outside the two roots, not a regular file, or if a file or the outbox text holds a secret.
  publish() builds the commit in the runner's repo with a private index (hash-object,
  update-index, write-tree, commit-tree), pushes it to a new kb-watch-* branch (never
  force), and opens the PR from .ancu-outbox/pr.md; issue.md becomes one issue for Son;
  kb-verify's verdict-<branch>.md files are recorded in ~/state/verdicts.json only when their
  sha is that branch's head as the runner fetched it, and posted as the PR comment.
Capability: publish(job, folder, base, stamp, log, repo=RUNNER, push=True) → 0, or 1 when
  it refused; plan() is pure enough for selftest.sh's property (Expect 2).
"""
from __future__ import annotations

import json
import os
import re
import stat
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import autolib as A  # noqa: E402

MAX_OUTBOX = 200_000
VERDICTS = ("kb-verified", "kb-hold")


def read_outbox(folder: Path, name: str) -> str | None:
    """An outbox file's text, or None; a symlink or non-regular file counts as refused."""
    p = folder / A.OUTBOX / name
    try:
        st = os.lstat(p)
    except FileNotFoundError:
        return None
    if not stat.S_ISREG(st.st_mode) or st.st_size > MAX_OUTBOX:
        raise ValueError(f"refused: {A.OUTBOX}/{name} is not a regular file under 200 kB")
    return p.read_text(encoding="utf-8", errors="replace")


def outbox_names(folder: Path) -> list[str]:
    d = folder / A.OUTBOX
    if os.path.islink(d) or not d.is_dir():
        return []
    return sorted(os.listdir(d))


def plan(folder: Path, repo: Path, base: str) -> tuple[dict, list[str], list[str]]:
    """(path -> bytes for changed files, deleted paths, refusals). Any refusal refuses all."""
    listing = A.base_listing(repo, base)
    walked = A.walk(folder)
    ign = A.ignored(repo, [p for p in walked if p not in listing])
    changed, deleted, problems = A.changed_files(folder, listing, ign)
    refused = [f"refused: {p}" for p in problems]
    for p in list(changed) + deleted:
        if not A.allowed_path(p):
            refused.append(f"refused: {p!r} is outside docs/kb/ and docs/sources/")
    data = {}
    known = A.secrets()
    if not refused:
        for p, f in changed.items():
            b = f.read_bytes()
            hits = A.secret_hits(b.decode("utf-8", errors="replace"), known)
            if hits:
                refused.append(f"refused: {p} holds {', '.join(hits)}")
            data[p] = b
    return data, sorted(deleted), refused


def build_commit(repo: Path, base: str, data: dict, deleted: list[str], msg: str,
                 stamp: str) -> str:
    """A commit on `base` with `data` and `deleted` applied, built with a private index in the
    runner's repo; its worktree and HEAD are untouched."""
    index = A.STATE / f"index-{stamp}"
    index.parent.mkdir(parents=True, exist_ok=True)
    env = {"GIT_INDEX_FILE": str(index), "GIT_AUTHOR_NAME": "ancu auto",
           "GIT_AUTHOR_EMAIL": f"{A.SON}@users.noreply.github.com",
           "GIT_COMMITTER_NAME": "ancu auto",
           "GIT_COMMITTER_EMAIL": f"{A.SON}@users.noreply.github.com"}
    try:
        A.git(repo, "read-tree", base, env=env)
        for p, b in sorted(data.items()):
            sha = A.git(repo, "hash-object", "-w", "--stdin", input=b, env=env).strip()
            A.git(repo, "update-index", "--add", "--cacheinfo", f"100644,{sha},{p}", env=env)
        for p in deleted:
            A.git(repo, "update-index", "--force-remove", "--", p, env=env)
        tree = A.git(repo, "write-tree", env=env).strip()
        return A.git(repo, "commit-tree", tree, "-p", base, "-F", "-", input=msg.encode(),
                     env=env).strip()
    finally:
        index.unlink(missing_ok=True)


def branch_name(repo: Path, prefix: str) -> str:
    name = prefix + time.strftime("%Y-%m-%d")
    taken = A.git(repo, "ls-remote", "--heads", "origin", f"{name}*")
    if f"refs/heads/{name}\n" in taken or taken.rstrip().endswith(f"refs/heads/{name}"):
        name += time.strftime("-%H%M")
    return name


def verdicts(folder: Path, repo: Path, log) -> int:
    """kb-verify: record each verdict bound to the branch head the runner fetched, and post it."""
    state_file = A.STATE / "verdicts.json"
    state = json.loads(state_file.read_text()) if state_file.is_file() else {}
    n = 0
    for name in outbox_names(folder):
        m = re.fullmatch(r"verdict-(kb-watch-[A-Za-z0-9._-]+)\.md", name)
        if not m:
            continue
        branch = m.group(1)
        text = read_outbox(folder, name) or ""
        lines = text.splitlines()
        if len(lines) < 2 or lines[0].strip() not in VERDICTS or not re.fullmatch(
                r"sha [0-9a-f]{40}", lines[1].strip()):
            log(f"refused: {name}: not `<{'|'.join(VERDICTS)}>` then `sha <40 hex>`")
            continue
        verdict, sha = lines[0].strip(), lines[1].strip()[4:]
        head = A.git(repo, "rev-parse", "--verify", "--quiet", f"refs/remotes/origin/{branch}",
                     check=False).strip()
        if head != sha:
            log(f"refused: {name}: sha {sha[:10]} is not {branch}'s head {head[:10] or '(none)'}")
            continue
        comment = "\n".join(lines[2:]).strip()
        if A.secret_hits(comment):
            log(f"refused: {name}: its comment holds a secret's shape")
            continue
        state[branch] = {"sha": sha, "verdict": verdict, "at": time.strftime("%Y-%m-%dT%H:%M:%S%z")}
        A.write_json(state_file, state)
        prs = json.loads(A.gh("pr", "list", "-R", A.REPO_SLUG, "--head", branch, "--state",
                              "open", "--json", "number,headRefOid") or "[]")
        for pr in prs:
            if pr.get("headRefOid") == sha:
                A.gh("pr", "comment", str(pr["number"]), "-R", A.REPO_SLUG, "--body-file", "-",
                     input=f"<!-- kb-verify {sha} -->\n**{verdict}** at `{sha[:10]}` "
                           f"(local kb-verify, behavior 145)\n\n{comment}\n")
        log(f"verdict {verdict} for {branch} at {sha[:10]}")
        n += 1
    log(f"kb-verify: {n} verdict(s) recorded")
    return 0


def publish(job: str, folder: Path, base: str, stamp: str, log, repo: Path = A.RUNNER,
            push: bool = True) -> int:
    _doc, prefix, _model, _turns = A.JOBS_TABLE[job]
    try:
        if job == "kb-verify":
            return verdicts(folder, repo, log)
        data, deleted, refused = plan(folder, repo, base)
        pr = read_outbox(folder, "pr.md")
        issue = read_outbox(folder, "issue.md")
    except ValueError as e:
        refused, data, deleted, pr, issue = [str(e)], {}, [], None, None
    for text, name in ((pr, "pr.md"), (issue, "issue.md")):
        if text and A.secret_hits(text):
            refused.append(f"refused: {A.OUTBOX}/{name} holds a secret's shape")
    if (data or deleted) and prefix is None:
        refused.append(f"refused: {job} may not change files")
    if (data or deleted) and not pr:
        refused.append(f"refused: files changed but {A.OUTBOX}/pr.md is missing")
    if refused:
        for r in refused:
            log(r)
        log(f"{job}: nothing published")
        if push:
            A.file_issue(f"ancu-auto: {job} refused {time.strftime('%Y-%m-%d')}",
                         "The local runner published nothing from this run (behavior 145):\n\n"
                         + "\n".join(f"- {r}" for r in refused[:50]) + "\n", log)
        return 1
    if issue:
        title, _, body = issue.partition("\n")
        title = " ".join(title.lstrip("# ").split())[:200]
        if push:
            A.file_issue(title, body.strip() + f"\n\n_Filed by the local {job} job (behavior 145)._\n", log)
        else:
            log(f"would file issue: {title}")
    if not (data or deleted):
        log(f"{job}: no file changed; no PR")
        return 0
    title, _, body = pr.partition("\n")
    title = " ".join(title.lstrip("# ").split())[:200]
    msg = f"{title}\n\nOpened by the local {job} job (behavior 145), run {stamp}.\n"
    commit = build_commit(repo, base, data, deleted, msg, stamp)
    log(f"{job}: commit {commit[:10]} on {base[:10]}: {len(data)} changed, {len(deleted)} deleted")
    for p in sorted(data) + deleted:
        log(f"  {p}")
    if not push:
        return 0
    branch = branch_name(repo, prefix)
    A.git(repo, "push", "--quiet", "origin", f"{commit}:refs/heads/{branch}")
    url = A.gh("pr", "create", "-R", A.REPO_SLUG, "--base", "main", "--head", branch, "--title",
               title, "--body-file", "-", input=body.strip() + "\n").strip()
    log(f"{job}: PR {url} from {branch}")
    return 0
