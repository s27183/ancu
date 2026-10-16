#!/usr/bin/env python3
"""The kb-gate tells a provider's own price from a secondary one, on fixture PRs.

    .venv/bin/python tests/kb_gate_eval.py

Regulated figures are grounded -> P-7 -> The KB update -> a provider's own price is the primary for its own fee
Behavior 85 (Son 2026-10-16): a fee change quoted from the provider's own page merges
by itself; the same change quoted from a comparison site is held as a secondary source,
and a provider's site proves nothing for a doc that is not about its fee. Each case is a
pair of commits built from git objects alone (a scratch index, commit-tree): no branch,
no checkout, nothing in the working tree moves; the objects are unreferenced and gc'd.
Exit 1 on any case that decides otherwise.
"""
from __future__ import annotations

import os
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "scripts"))
import kb_gate  # noqa: E402

COPY = "docs/sources/fx/fixture-provider-fee-page.txt"
PAGE = "Our transfer fee to Vietnam is 2.0% of the amount you send.\n"


def doc(slug: str, url: str, pct: str, quoted: bool) -> str:
    quote = (f"    path: {COPY}\n    quotes:\n      - \"Our transfer fee to Vietnam is {pct}% of the amount you send.\"\n"
             if quoted else "")
    return (f"---\nslug: {slug}\ntitle: Fixture provider fee\nlast_verified: 2026-10-01\n"
            f"sources:\n  - url: {url}\n    retrieved: 2026-10-01\n{quote}---\n\n"
            f"The provider charges {pct}% of the amount sent.\n")


def git(*args: str, env: dict | None = None, data: bytes | None = None) -> str:
    return subprocess.run(["git", *args], cwd=ROOT, check=True, capture_output=True,
                          input=data, env=env).stdout.decode().strip()


def commit(parent: str, files: dict[str, str], msg: str) -> str:
    with tempfile.TemporaryDirectory() as d:
        env = {**os.environ, "GIT_INDEX_FILE": str(Path(d) / "index")}
        git("read-tree", parent, env=env)
        for path, text in files.items():
            blob = git("hash-object", "-w", "--stdin", data=text.encode())
            git("update-index", "--add", "--cacheinfo", f"100644,{blob},{path}", env=env)
        tree = git("write-tree", env=env)
    return git("commit-tree", tree, "-p", parent, "-m", msg)


def case(path: str, url: str) -> dict:
    base = commit("HEAD", {path: doc("kb.fixture.provider-fee", url, "1.5", False)}, "fixture base")
    head = commit(base, {path: doc("kb.fixture.provider-fee", url, "2.0", True), COPY: PAGE}, "fixture head")
    return kb_gate.decide(base, head, "kb-watch-fixture", {"kb-verified"}, True)


CASES = [
    ("an FX provider doc, quoted from the provider's own page", "docs/kb/fx-providers/fixture-provider-fee.md",
     "https://wise.com/au/pricing/send-money", "merge", None),
    ("the same change, quoted from a comparison site", "docs/kb/fx-providers/fixture-provider-fee.md",
     "https://www.finder.com.au/international-money-transfers", "hold", "secondary source"),
    ("the provider's page quoted for a doc that is not about its fee", "docs/kb/selling-costs/fixture-provider-fee.md",
     "https://wise.com/au/pricing/send-money", "hold", "secondary source"),
]


def main() -> int:
    fails = 0
    for name, path, url, want, reason in CASES:
        d = case(path, url)
        ok = d["decision"] == want and (reason is None or any(reason in r for r in d["reasons"]))
        fails += not ok
        print(f"{'ok  ' if ok else 'FAIL'} {name} → {d['decision']}" + ("" if ok else f" {d['reasons']}"))
    print(f"kb_gate_eval: {len(CASES) - fails}/{len(CASES)} cases")
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
