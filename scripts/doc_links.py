#!/usr/bin/env python3
"""Broken intra-repo links and #anchors in the docs tree, as file:line -> target.

Usage: .venv/bin/python scripts/doc_links.py [root ...]   (default: docs)
Exit 0 when every link resolves, 1 when any is broken.
"""
# Reproducible -> P-7 · One declaration per outcome shape -> Mechanisms -> a done check fails on a doc link that no longer lands
# Analogue of P-7: a link is a hand-kept copy of a path and a heading. Its target is a file in this repo and, after '#', a heading slug in it; both rot silently
# when a doc moves or a heading is reworded (measured 2026-10-06: 1889 links over 257 docs, 16
# live broken targets). docs/design/archive is history, kept as written, so it is not checked
# as a source; links INTO it are still checked. External URLs are not fetched, and a path
# that leaves the repo (a sibling project's doc) is skipped: it resolves only on one machine. Slugs follow
# GitHub's rendering: lowercase, punctuation dropped except '-' and '_', spaces to '-', letters
# of any script kept (Vietnamese headings included), a repeated heading gets -1, -2 (behavior 16).
import re
import sys
import unicodedata
from functools import lru_cache
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
EXCLUDE = [REPO / "docs" / "design" / "archive"]

LINK = re.compile(r"(?<!!)\[(?:[^\[\]]|\[[^\]]*\])*\]\(\s*<?([^)\s>]+)>?(?:\s+\"[^\"]*\")?\s*\)")
IMG = re.compile(r"!\[[^\]]*\]\(\s*<?([^)\s>]+)>?(?:\s+\"[^\"]*\")?\s*\)")
REFDEF = re.compile(r"^\s{0,3}\[[^\]]+\]:\s*<?(\S+?)>?(?:\s+.*)?$")
HEADING = re.compile(r"^\s{0,3}(#{1,6})\s+(.*?)\s*#*\s*$")
HTML_ID = re.compile(r"""<a\s+[^>]*(?:name|id)\s*=\s*["']([^"']+)["']""", re.I)
FENCE = re.compile(r"^\s{0,3}(`{3,}|~{3,})")
INLINE_CODE = re.compile(r"(`+)(?:(?!\1).)+?\1")
SCHEME = re.compile(r"^[a-zA-Z][a-zA-Z0-9+.-]*:")


def slug(text: str) -> str:
    text = re.sub(r"<[^>]+>", "", text)                       # inline html
    text = re.sub(r"!?\[([^\]]*)\]\([^)]*\)", r"\1", text)    # links keep their text
    text = text.replace("`", "").lower()
    out = []
    for ch in text:
        cat = unicodedata.category(ch)
        if ch in "-_" or cat[0] in "LN" or cat in ("Mn", "Mc"):
            out.append(ch)
        elif ch == " ":
            out.append("-")
    return "".join(out)


def strip_code(lines):
    """Yield (lineno, text) with fenced blocks dropped and inline code blanked."""
    fence = None
    for n, line in enumerate(lines, 1):
        m = FENCE.match(line)
        if fence:
            if m and m.group(1)[0] == fence[0] and len(m.group(1)) >= len(fence):
                fence = None
            continue
        if m:
            fence = m.group(1)
            continue
        yield n, INLINE_CODE.sub(lambda c: " " * len(c.group(0)), line)


@lru_cache(maxsize=None)
def anchors(path: Path) -> frozenset:
    seen: dict[str, int] = {}
    found = set()
    lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
    for _, line in strip_code(lines):
        for a in HTML_ID.findall(line):
            found.add(a)
        m = HEADING.match(line)
        if not m:
            continue
        s = slug(m.group(2))
        k = seen.get(s, 0)
        seen[s] = k + 1
        found.add(s if k == 0 else f"{s}-{k}")
    return frozenset(found)


def check(md: Path):
    lines = md.read_text(encoding="utf-8", errors="replace").splitlines()
    for n, line in strip_code(lines):
        targets = LINK.findall(line) + IMG.findall(line)
        m = REFDEF.match(line)
        if m:
            targets.append(m.group(1))
        for t in targets:
            if SCHEME.match(t) or t.startswith("//"):
                continue
            path_part, _, frag = t.partition("#")
            path_part = path_part.split("?")[0]
            if path_part:
                base = REPO if path_part.startswith("/") else md.parent
                dest = (base / path_part.lstrip("/")).resolve()
                if not dest.is_relative_to(REPO):
                    continue  # a sibling repo's doc: not intra-repo, depends on the checkout's neighbours
                if not dest.exists():
                    yield "file", n, t
                    continue
            else:
                dest = md
            if frag and dest.is_file() and dest.suffix.lower() == ".md":
                from urllib.parse import unquote
                if unquote(frag).lower() not in {a.lower() for a in anchors(dest)}:
                    yield "anchor", n, t


def main(argv):
    roots = [Path(a).resolve() for a in argv] or [REPO / "docs"]
    files = []
    for r in roots:
        files += [r] if r.is_file() else sorted(r.rglob("*.md"))
    files = [f for f in files if not any(f.is_relative_to(e) for e in EXCLUDE)]
    counts = {"file": 0, "anchor": 0}
    for f in files:
        for kind, n, t in check(f):
            counts[kind] += 1
            rel = f.relative_to(REPO) if f.is_relative_to(REPO) else f
            print(f"{rel}:{n} -> {t}  ({'missing file' if kind == 'file' else 'no such anchor'})")
    print(f"doc_links: {len(files)} files, broken-file={counts['file']} broken-anchor={counts['anchor']}")
    return 1 if any(counts.values()) else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
