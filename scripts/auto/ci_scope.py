"""Is this PR a KB-only kb-watch head? One rule for GitHub's done-checks job and the local gate
(behavior 145).

Regulated figures are grounded -> R-3 -> The KB update -> CI skips the done checks only for a same-repo kb-watch-* diff of regular KB files
Invariant: "done checks" passes without running its checks only when the PR's head is a
  branch of this repo named kb-watch-* and every path its diff changes is a regular file
  (mode 100644, or deleted) under docs/kb/ or docs/sources/; any other diff on such a
  branch — code, workflows, a rename out of the KB, a symlink, a submodule, or nothing at
  all — runs the full checks, as every other PR does. The local gate holds the same diffs.
Mechanism: `git diff --raw -z --no-renames <base>...<head>` read entry by entry (a rename
  is a delete plus an add, so both paths are judged); allowed_path() is the one path rule,
  which the publisher (autolib) imports from here. Standard library only: GitHub runs this
  with the runner's python3 before anything is installed.
  Bound, not a wall: on `pull_request` GitHub runs the workflow and this file as the PR
  carries them, so a holder of a push credential could rewrite both; what keeps that
  credential from a job's agent is the two-user split (auto-jobs.md), not this file.
Capability: `python3 scripts/auto/ci_scope.py` with EVENT, HEAD_REPO, REPO, HEAD_REF,
  BASE_SHA, HEAD_SHA in the environment → prints `kb_only=true|false` (for $GITHUB_OUTPUT)
  and the reason on stderr; kb_only(), problems() and diff_entries() for gate.py and selftest.
"""
from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path

ALLOWED_ROOTS = ("docs/kb/", "docs/sources/")
PREFIX = "kb-watch-"
REGULAR = ("100644", "000000")  # a regular file, or a deletion


def allowed_path(p: str) -> bool:
    """A path the publisher may commit: relative, normalised, under docs/kb or docs/sources,
    no dot segment, no control or backslash character."""
    if not p or p.startswith("/") or "\\" in p or any(ord(c) < 32 or ord(c) == 127 for c in p):
        return False
    segs = p.split("/")
    if any(s in ("", ".", "..") or s.startswith(".") for s in segs):
        return False
    return p.startswith(ALLOWED_ROOTS)


def parse_raw(out: str) -> list[tuple[str, str]]:
    """(path, new mode) for each entry of `git diff --raw -z --no-renames`."""
    parts = out.split("\0")
    entries, i = [], 0
    while i + 1 < len(parts) and parts[i].startswith(":"):
        meta = parts[i][1:].split()
        entries.append((parts[i + 1], meta[1]))
        i += 2
    return entries


def problems(entries: list[tuple[str, str]]) -> list[str]:
    """Why these changes are not KB-only (empty when they are)."""
    if not entries:
        return ["an empty diff"]
    out = []
    for path, mode in entries:
        if not allowed_path(path):
            out.append(f"{path!r} is outside docs/kb and docs/sources")
        elif mode not in REGULAR:
            out.append(f"{path!r} has mode {mode}, not a regular file")
    return out


def kb_only(same_repo: bool, head_ref: str, entries: list[tuple[str, str]] | None) -> tuple[bool, str]:
    if not same_repo or not head_ref.startswith(PREFIX):
        return False, "not a same-repo kb-watch-* head"
    if entries is None:
        return False, "its diff could not be read"
    p = problems(entries)
    return (not p), ("; ".join(p[:5]) if p else "every change is a regular file under docs/kb or docs/sources")


def diff_entries(repo: Path, base: str, head: str, env: dict | None = None) -> list[tuple[str, str]] | None:
    r = subprocess.run(["git", "-c", "core.hooksPath=/dev/null", "diff", "--raw", "-z",
                        "--no-renames", "--no-abbrev", f"{base}...{head}"], cwd=repo,
                       capture_output=True, env=env)
    if r.returncode:
        return None
    return parse_raw(r.stdout.decode("utf-8", errors="surrogateescape"))


def main() -> int:
    e = os.environ
    if e.get("EVENT") != "pull_request":
        ok, why = False, f"event {e.get('EVENT')!r}, not a pull request"
    else:
        same = bool(e.get("HEAD_REPO")) and e.get("HEAD_REPO") == e.get("REPO")
        entries = diff_entries(Path.cwd(), e.get("BASE_SHA", ""), e.get("HEAD_SHA", "")) \
            if same else []
        ok, why = kb_only(same, e.get("HEAD_REF", ""), entries)
    print(f"kb_only={'true' if ok else 'false'}")
    print(f"ci_scope: {'KB-only kb-watch head, the local gate ran the checks' if ok else 'full done checks'}"
          f" — {why}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
