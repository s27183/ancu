#!/usr/bin/env python3
# Bilingual -> P-7 · The KB -> The done checks -> every Australian acronym the app writes has an explanation
# Behavior 102, Expect 2: the user-facing strings — the "vi"/"en" values of
# docs/kb/copy/*.md and shell/web/frontend/src/lib/i18n.ts — are scanned for acronyms
# (two or more capitals, whole words, e.g. LMI, FIRB, HECS/HELP). Each must be a form of a
# term in docs/kb/terms/*.md, or one of NOT_TERMS below: names a reader already knows
# (a state, a currency, a bank, the app's own words) or capitals used for emphasis.
# A new acronym in the copy with no term fails the check until it gets one.
# Planted check: a stub acronym with no term must be reported (run with --self-test).
import glob
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "engine" / "build"))
from kb_compiler import fenced_jsonc_after, parse_jsonc  # noqa: E402

ACRONYM = re.compile(r"(?<!\w)[A-Z][A-Z0-9]+(?:/[A-Z]{2,})?(?!\w)")

NOT_TERMS = {
    # places, currencies, the countries
    "AU", "VN", "AUD", "VND", "NSW", "VIC", "QLD", "WA", "SA", "TAS", "ACT", "NT", "NSW/VIC",
    # banks and providers named as themselves
    "ANZ", "CBA", "NAB", "OFX",
    # the app's own words and file kinds
    "AI", "PDF", "KB",
    # the statistics bureau, named as a source
    "ABS",
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
            if a in forms or a in NOT_TERMS:
                continue
            # "HECS/HELP" is covered when both halves are
            if "/" in a and all(p in forms or p in NOT_TERMS for p in a.split("/")):
                continue
            missing.setdefault(a, pathlib.Path(f).name)
    return missing


def main():
    forms = term_forms()
    if "--self-test" in sys.argv:
        planted = uncovered([("planted", "Phí ZQXW khi mua")], forms)
        print("PASS — planted acronym reported" if "ZQXW" in planted else "FAIL — planted acronym missed")
        return 0 if "ZQXW" in planted else 1
    if not forms:
        print("FAIL — docs/kb/terms/*.md hold no terms")
        return 1
    missing = uncovered(copy_strings(), forms)
    if missing:
        print("FAIL — acronyms in the app's copy with no term in docs/kb/terms/:")
        for a, f in sorted(missing.items()):
            print(f"  {a}  (first seen in {f})")
        return 1
    # the planted check runs every time too, so a broken scanner cannot pass silently
    if "ZQXW" not in uncovered([("planted", "Phí ZQXW khi mua")], forms):
        print("FAIL — the scanner missed a planted acronym")
        return 1
    print(f"PASS — every acronym in the copy is a term ({len(forms)} forms) or a known name")
    return 0


if __name__ == "__main__":
    sys.exit(main())
