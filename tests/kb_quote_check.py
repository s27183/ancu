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

# Behavior 148 (Son 2026-11-01): a source whose host answers scripts with a bot challenge
# (legislation.nsw.gov.au: HTTP 403 `cf-mitigated: challenge`, measured 2026-11-01) is
# marked `browser_only: <why, when measured>`. Son saves it in a browser; its saved copy is
# the only evidence, so it must carry quotes, and its own `Retrieved: <date>` header —
# the date tests/kb_freshness.py's RE-SAVE IN A BROWSER reads, which a date-only edit to
# the doc does not move. Copies start with the archive_source header (Source/Retrieved).
RETRIEVED_HEADER = re.compile(r"(?:^|\s)Retrieved: (\d{4}-\d{2}-\d{2})")
HEADER_SPAN = 400


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
        m = re.match(r"^\s+(retrieved|path|kind|note|browser_only):\s*(.+?)\s*$", line)
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
        where = f"{rel}: source {i} ({src.get('url') or src.get('note')})"
        browser_only = bool(src.get("browser_only"))
        if not src.get("quotes"):
            if browser_only:
                out.append(f"{where}: browser_only: but no `quotes:` from its saved copy")
            continue
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
        if browser_only and not RETRIEVED_HEADER.search(text[:HEADER_SPAN]):
            out.append(f"{where}: browser_only: saved copy {sp} has no `Retrieved: <date>` header line")
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
    if doc_fails(FIXTURES / "browser-only-good.md"):
        out.append("self-test: fixtures/kb_quote/browser-only-good.md should pass and does not")
    if not doc_fails(FIXTURES / "browser-only-no-quotes.md"):
        out.append("self-test: fixtures/kb_quote/browser-only-no-quotes.md should fail and does not")
    return out + browser_only_property()


ACT = ("Retrieved: 2026-06-02\n(1) The risk in respect of damage to land shall not pass\n"
       "to the purchaser until the completion of the sale. (a) within 28 days after the\n"
       "purchaser first became aware of the damage")
ACT_NO_HEADER = ACT.split("\n", 1)[1]
QUOTES = ["shall not pass to the purchaser until the completion of the sale",
          "within 28 days after the purchaser first became aware of the damage"]


def _oracle(browser_only, path, copy, quotes) -> bool:
    """Independent of doc_fails: passes iff no rule is broken, rules read off the
    docstring and behavior 148, whitespace compared by str.split."""
    if not quotes:
        return not browser_only
    if path is None or not path.endswith((".txt", ".html", ".docx")) or copy is None:
        return False
    words = " ".join(copy.split())
    if browser_only and "Retrieved: 2026-" not in " ".join(copy.split()[:4]):
        return False
    return all(" ".join(q.split()) in words for q in quotes)


def _mutate(rng, q: str) -> str:
    i = rng.randrange(len(q))
    return q[:i] + rng.choice("0123456789xyz ") + q[i + 1:] if rng.random() < 0.8 else q.upper()


def browser_only_property(n_random: int = 160, seed: int = 148) -> list[str]:
    """Property (behavior 148, Expect 2): for every source shape — browser-only or not,
    path none/.txt/.pdf, copy missing/with header/without, 0–2 quotes, quotes mutated at
    random — doc_fails passes exactly when the oracle does."""
    import itertools
    import random
    rng = random.Random(seed)
    cases = []
    for bo, path, copy, nq in itertools.product(
            (False, True), (None, "docs/sources/nsw/act.txt", "docs/sources/nsw/act.pdf"),
            (None, ACT, ACT_NO_HEADER), (0, 1, 2)):
        cases.append((bo, path, copy, QUOTES[:nq]))
    for _ in range(n_random):
        qs = [_mutate(rng, q) if rng.random() < 0.5 else q for q in rng.sample(QUOTES, rng.randint(1, 2))]
        cases.append((rng.random() < 0.7, "docs/sources/nsw/act.txt", rng.choice((ACT, ACT_NO_HEADER)), qs))
    bad = []
    for bo, path, copy, quotes in cases:
        lines = ["---", "slug: kb.fixture.p148", "sources:", "  - url: https://legislation.nsw.gov.au/x",
                 "    retrieved: 2026-06-02"]
        if bo:
            lines.append('    browser_only: "fixture"')
        if path:
            lines.append(f"    path: {path}")
        if quotes:
            lines.append("    quotes:")
            lines += [f'      - "{q}"' for q in quotes]
        lines += ["---", ""]
        got = not doc_fails(Path("docs/kb/fixture.md"), "\n".join(lines),
                            lambda sp, c=copy: None if c is None else normalize_ws(c))
        if got != _oracle(bo, path, copy, quotes):
            bad.append(f"self-test property: browser_only={bo} path={path} quotes={quotes!r} "
                       f"header={copy is not None and copy.startswith('Retrieved')}: check {got}, oracle {not got}")
    print(f"kb_quote_check property: {len(cases)} cases, seed {seed}, {len(bad)} counterexamples")
    return bad


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
