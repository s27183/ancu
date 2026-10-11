#!/usr/bin/env python3
"""Every quote a KB doc's source carries is found, word for word, in its saved copy.

    .venv/bin/python tests/kb_quote_check.py [<doc.md> ...]     (default: every docs/kb doc)

Regulated figures are grounded -> P-7 -> The KB update -> a changed figure quotes its saved primary
Behavior 74 (Son 2026-10-12: the weekly KB update publishes itself when verified). A figure
the kb-watch routine changes carries, on the source it came from, the saved copy of that
page (`path:` under docs/sources/, written by scripts/archive_source.py) and the exact
sentences that state the figure (`quotes:`):

    sources:
      - url: https://www.revenue.nsw.gov.au/...
        retrieved: 2026-10-12
        path: docs/sources/nsw-revenue/surcharge-purchaser-duty.txt
        quotes:
          - "Surcharge purchaser duty is 9% of the dutiable value"

This check proves each quote is in the saved copy (whitespace collapsed, as GATE 12 does
for the first-visit facts). It cannot tell whether the quote is the right row or state —
the independent kb-verify routine checks that — but it cannot misread either. A quoted
source's copy must be text (.txt, .html or .docx): a PDF is saved as its extracted text.
Docs with no `quotes:` are not checked here (the older docs cite by note); scripts/kb_gate.py
requires quotes for every figure a kb-watch PR changes. Exit 1 on any failure.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "engine" / "build"))
from kb_compiler import archived_text, frontmatter_end, normalize_ws  # noqa: E402

TEXT_SUFFIXES = {".txt", ".html", ".docx"}


def parse_sources(text: str) -> list[dict]:
    """The frontmatter `sources:` list with each entry's `quotes:` — the compiler's
    parse_sources_block subset, plus the quotes list it ignores."""
    end = frontmatter_end(text)
    fm = text[:end] if end > 0 else ""
    out: list[dict] = []
    cur: dict | None = None
    in_block = in_quotes = False
    for line in fm.splitlines():
        if re.match(r"^sources:\s*$", line):
            in_block = True
            continue
        if not in_block:
            continue
        if re.match(r"^\S", line):
            break
        m = re.match(r"^\s*-\s*(url|note):\s*(.+?)\s*$", line)
        if m and len(line) - len(line.lstrip()) <= 4:
            cur = {m.group(1): m.group(2).strip('"'), "quotes": []}
            out.append(cur)
            in_quotes = False
            continue
        if cur is None:
            continue
        if re.match(r"^\s+quotes:\s*$", line):
            in_quotes = True
            continue
        m = re.match(r"^\s+-\s*(.+?)\s*$", line)
        if in_quotes and m:
            q = m.group(1)
            if len(q) >= 2 and q[0] == q[-1] and q[0] in "\"'":
                q = q[1:-1].replace('\\"', '"')
            cur["quotes"].append(q)
            continue
        m = re.match(r"^\s+(retrieved|path|kind|note):\s*(.+?)\s*$", line)
        if m:
            cur[m.group(1)] = m.group(2).strip('"')
            in_quotes = False
    return out


def doc_fails(path: Path, text: str | None = None, copy_text=None) -> list[str]:
    """Why a doc's quotes do not hold, one line each; [] if they hold. `text` and
    `copy_text(path) -> str | None` stand in for reading the doc and its saved copies
    from the working tree (the gate reads both as the PR's head commit has them)."""
    rel = path.relative_to(ROOT) if path.is_absolute() and ROOT in path.parents else path
    out = []
    for i, src in enumerate(parse_sources(text if text is not None else path.read_text())):
        if not src.get("quotes"):
            continue
        where = f"{rel}: source {i} ({src.get('url') or src.get('note')})"
        sp = src.get("path")
        if not sp:
            out.append(f"{where}: has quotes but no `path:` to a saved copy")
            continue
        if str(rel).startswith("docs/kb/") and not sp.startswith("docs/sources/"):
            out.append(f"{where}: path {sp!r} is not under docs/sources/")
        f = ROOT / sp
        if f.suffix not in TEXT_SUFFIXES:
            out.append(f"{where}: {sp} is not text ({', '.join(sorted(TEXT_SUFFIXES))}); save a PDF as its extracted text")
            continue
        text = copy_text(sp) if copy_text else archived_text(f)
        if text is None:
            out.append(f"{where}: saved copy {sp} not found")
            continue
        for q in src["quotes"]:
            if normalize_ws(q) not in text:
                out.append(f"{where}: quote not in {sp}: {q!r}")
    return out


FIXTURES = ROOT / "tests" / "fixtures" / "kb_quote"


def self_test() -> list[str]:
    """The check still tells a present quote from an absent one (its own fixtures)."""
    out = []
    if doc_fails(FIXTURES / "good.md"):
        out.append("self-test: fixtures/kb_quote/good.md should pass and does not")
    if not doc_fails(FIXTURES / "bad.md"):
        out.append("self-test: fixtures/kb_quote/bad.md should fail and does not")
    return out


def main(argv: list[str]) -> int:
    docs = [Path(a).resolve() for a in argv] or sorted((ROOT / "docs" / "kb").rglob("*.md"))
    fails = [line for d in docs for line in doc_fails(d)]
    if not argv:
        fails += self_test()
    for line in fails:
        print(line)
    quoted = sum(1 for d in docs for s in parse_sources(d.read_text()) if s.get("quotes"))
    print(f"kb_quote_check: {len(docs)} docs, {quoted} quoted sources, {len(fails)} failures")
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
