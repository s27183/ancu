#!/usr/bin/env python3
# Bilingual -> P-7 · The KB -> The done checks -> every Australian acronym the app writes has an explanation
# Behavior 102, Expect 2: the user-facing strings — the "vi"/"en" values of
# docs/kb/copy/*.md and shell/web/frontend/src/lib/i18n.ts, and (behavior 105) every news
# note's headlines and summaries, whoever wrote it — are scanned for acronyms
# (two or more capitals, whole words, e.g. LMI, FIRB, HECS/HELP). Each must be a form of a
# term in docs/kb/terms/*.md, or one of NOT_TERMS below: names a reader already knows
# (a state, a currency, a bank, the app's own words) or capitals used for emphasis.
# A new acronym in the copy with no term fails the check until it gets one.
# A financial-year label (FY2026) is a date, not a term. Joined forms (HECS-HELP,
# HECS/HELP) count as one. Planted checks: a stub acronym in the copy and one in a news
# summary must both be reported (run with --self-test; they also run every time).
import glob
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "engine" / "build"))
from kb_compiler import fenced_jsonc_after, parse_jsonc  # noqa: E402

ACRONYM = re.compile(r"(?<![\w-])[A-Z][A-Z0-9]+(?:[/-][A-Z]{2,})?(?![\w-])")
NOT_TERM_PATTERN = re.compile(r"FY\d{2,4}")

NOT_TERMS = {
    # places, currencies, the countries
    "AU", "VN", "AUD", "VND", "NSW", "VIC", "QLD", "WA", "SA", "TAS", "ACT", "NT", "NSW/VIC",
    # banks and providers named as themselves
    "ANZ", "CBA", "NAB", "OFX",
    # the app's own words and file kinds
    "AI", "PDF", "KB",
    # the statistics bureau, named as a source; the regional bloc Vietnam belongs to
    "ABS", "ASEAN",
    # capitals for emphasis in a sentence
    "NOT", "PLACEHOLDER", "CONVENTION", "PREPAYMENT", "TYPICAL", "NGAY",
}


def copy_strings():
    out = []
    for f in sorted(glob.glob(str(ROOT / "docs/kb/copy/*.md"))):
        out += [(f, v) for v in re.findall(r'"(?:vi|en)":\s*"((?:[^"\\]|\\.)*)"', open(f).read())]
    i18n = ROOT / "shell/web/frontend/src/lib/i18n.ts"
    out += [(str(i18n), v) for v in re.findall(r"(?:vi|en):\s*'((?:[^'\\]|\\.)*)'", i18n.read_text())]
    return out


NEWS_SECTIONS = re.compile(r"^## (Headline|Summary) \((EN|VI)\)\s*$")


def news_strings(text, name="note"):
    """(name, text) for each headline and summary section of a news note."""
    out, cur = [], None
    for line in text.splitlines():
        if line.startswith("## "):
            cur = [] if NEWS_SECTIONS.match(line) else None
            if cur is not None:
                out.append((name, cur))
            continue
        if cur is not None:
            cur.append(line)
    return [(n, "\n".join(ls)) for n, ls in out]


def all_news():
    out = []
    for f in sorted(glob.glob(str(ROOT / "docs/kb/news/*.md"))):
        out += news_strings(open(f).read(), f)
    return out


PLANTED_NOTE = "---\nslug: kb.news.planted\n---\n## Headline (EN)\nZQNW rises\n## Summary (VI)\nPhí ZQNW tăng.\n## Notes\nQQQQ is reviewer-only\n"


def planted_ok(forms):
    copy_hit = "ZQXW" in uncovered([("planted", "Phí ZQXW khi mua")], forms)
    news = uncovered(news_strings(PLANTED_NOTE), forms)
    return copy_hit and "ZQNW" in news and "QQQQ" not in news


def term_forms():
    forms = set()
    for f in sorted((ROOT / "docs/kb/terms").glob("*.md")):
        block = fenced_jsonc_after(f.read_text(), "## Terms")
        for t in (parse_jsonc(block) or {}).get("terms", []) if block else []:
            forms.update(t.get("forms") or [])
    return forms


def uncovered(strings, forms):
    missing = {}
    for f, v in strings:
        for a in ACRONYM.findall(v):
            if a in forms or a in NOT_TERMS or NOT_TERM_PATTERN.fullmatch(a):
                continue
            # "HECS/HELP", "AU-VN" are covered when both halves are
            if re.search(r"[/-]", a) and all(p in forms or p in NOT_TERMS for p in re.split(r"[/-]", a)):
                continue
            missing.setdefault(a, pathlib.Path(f).name)
    return missing


def main():
    forms = term_forms()
    if "--self-test" in sys.argv:
        ok = planted_ok(forms)
        print("PASS — a planted acronym in the copy and one in a news summary are reported; one in a note's reviewer Notes is not"
              if ok else "FAIL — a planted acronym was missed (copy or news), or a Notes section was scanned")
        return 0 if ok else 1
    if not forms:
        print("FAIL — docs/kb/terms/*.md hold no terms")
        return 1
    news = all_news()
    missing = uncovered(copy_strings() + news, forms)
    if missing:
        print("FAIL — acronyms in the app's copy or news with no term in docs/kb/terms/:")
        for a, f in sorted(missing.items()):
            print(f"  {a}  (first seen in {f})")
        return 1
    # the planted check runs every time too, so a broken scanner cannot pass silently
    if not planted_ok(forms):
        print("FAIL — the scanner missed a planted acronym")
        return 1
    print(f"PASS — every acronym in the copy and in {len(news)} news headlines and summaries is a term ({len(forms)} forms) or a known name")
    return 0


if __name__ == "__main__":
    sys.exit(main())
