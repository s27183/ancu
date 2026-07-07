#!/usr/bin/env python3
"""KB freshness scanner — turns "did anything go stale?" from memory into a command.

The KB is static (compiled to `persistent_term` at deploy); staleness is an
*audit* question, not a runtime gate (engine-contract §9.1). Nothing else in the
build checks it — `kb_compiler.py` validates structure + references, never age.
This script fills that gap: it reads the `last_verified` frontmatter of every
`docs/kb/**.md` doc, compares it against a per-cadence re-verification budget,
and reports which docs are overdue for a re-verify pass against their primary
source.

The cadence tiers are NOT invented here — they come straight from the update
cadence table in `docs/architecture/architecture.md §11.2`:

  - Monthly   — lender policy, RBA cash rate, FHG panel / participating lenders.
  - Per-event — FIRB regime changes, budgets, ASIC bulletins (no fixed period —
                triggered on demand when the maintainer notices the event, not
                by any scheduler/RSS watcher); we still apply a long
                *safety-net* re-verify budget so a doc can't drift unbounded
                between events.
  - Quarterly — everything else: scheme structures, state duty schedules, FHOG,
                HECS thresholds, process knowledge, document templates. This is
                §11.2's catch-all, so it is the DEFAULT here.

Only the two namespaces that §11.2 singles out as faster (lender/LMI = monthly)
and the one it singles out as event-driven (FIRB) deviate from the default. Copy
docs (`kb.copy.*`) go stale when the *fact doc they interpolate* changes, not on
a calendar — they default to quarterly here as a safety net; the real trigger is
"the paired fact doc moved" (see the runbook).

Advisory by default (exit 0 — a stale doc is not a build error). Pass `--strict`
to exit 1 when anything is overdue (e.g. to gate a deploy). Pass
`--asof YYYY-MM-DD` to evaluate against a fixed date instead of today (testing /
reproducibility).

Usage:
    python3 tests/kb_freshness.py
    python3 tests/kb_freshness.py --strict
    python3 tests/kb_freshness.py --asof 2026-09-01
"""
import datetime
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
KB_DIR = ROOT / "docs" / "kb"

# Re-verification budget per cadence tier, in days. Grounded in architecture
# §11.2; the day counts give a small grace over the nominal period.
BUDGET_DAYS = {
    "monthly": 31,
    "quarterly": 92,
    "per-event": 183,  # no fixed cadence — safety-net so it can't drift forever
}

# Longest-prefix-first cadence assignment. Only the deviations from the default
# need listing (§11.2): lender/LMI move monthly, FIRB is event-driven. Everything
# else falls through to DEFAULT_CADENCE.
CADENCE_RULES = [
    ("kb.lender", "monthly"),
    ("kb.lmi", "monthly"),
    ("kb.firb", "per-event"),
]
DEFAULT_CADENCE = "quarterly"


def cadence_for(slug):
    for prefix, cadence in CADENCE_RULES:
        if slug == prefix or slug.startswith(prefix + "."):
            return cadence
    return DEFAULT_CADENCE


def parse_frontmatter(path):
    """Pull slug + last_verified from the YAML frontmatter (3 fields, no deps —
    same regex approach as kb_compiler.parse_kb_doc, kept standalone on purpose
    so a freshness check never drags in the whole compile machinery)."""
    text = path.read_text()
    slug_m = re.search(r"^slug:\s*(\S+)", text, re.M)
    ver_m = re.search(r"^last_verified:\s*(\S+)", text, re.M)
    return (
        slug_m.group(1) if slug_m else None,
        ver_m.group(1) if ver_m else None,
    )


def parse_args(argv):
    strict = "--strict" in argv
    asof = datetime.date.today()
    for i, a in enumerate(argv):
        if a == "--asof" and i + 1 < len(argv):
            asof = datetime.date.fromisoformat(argv[i + 1])
        elif a.startswith("--asof="):
            asof = datetime.date.fromisoformat(a.split("=", 1)[1])
    return strict, asof


def main():
    strict, asof = parse_args(sys.argv[1:])

    rows = []      # (slug, cadence, last_verified, age_days, budget, status)
    errors = []    # docs missing slug / last_verified — a real problem

    for path in sorted(KB_DIR.rglob("*.md")):
        slug, last_verified = parse_frontmatter(path)
        rel = path.relative_to(ROOT)
        if not slug or not last_verified:
            missing = []
            if not slug:
                missing.append("slug")
            if not last_verified:
                missing.append("last_verified")
            errors.append((rel, ", ".join(missing)))
            continue
        try:
            lv = datetime.date.fromisoformat(last_verified)
        except ValueError:
            errors.append((rel, f"unparseable last_verified: {last_verified!r}"))
            continue
        cadence = cadence_for(slug)
        budget = BUDGET_DAYS[cadence]
        age = (asof - lv).days
        status = "STALE" if age > budget else "ok"
        rows.append((slug, cadence, last_verified, age, budget, status))

    stale = [r for r in rows if r[5] == "STALE"]
    # Most overdue first; ties broken by slug for a stable report.
    stale.sort(key=lambda r: (-(r[3] - r[4]), r[0]))

    print(f"KB freshness — as of {asof.isoformat()} ({len(rows)} docs scanned)\n")

    if errors:
        print("FRONTMATTER ERRORS (fix before relying on this report):")
        for rel, why in errors:
            print(f"  ✗ {rel} — {why}")
        print()

    if stale:
        print(f"OVERDUE FOR RE-VERIFY ({len(stale)}):")
        print(f"  {'slug':<34} {'cadence':<10} {'verified':<12} {'age':>5} {'budget':>7}")
        for slug, cadence, lv, age, budget, _ in stale:
            print(f"  {slug:<34} {cadence:<10} {lv:<12} {age:>4}d {budget:>6}d  (+{age - budget}d)")
        print()
    else:
        print("All scanned docs are within their re-verification budget.\n")

    # Per-cadence summary so the operator sees the shape at a glance.
    print("By cadence:")
    for cadence in ("monthly", "quarterly", "per-event"):
        grp = [r for r in rows if r[1] == cadence]
        grp_stale = [r for r in grp if r[5] == "STALE"]
        print(f"  {cadence:<10} {len(grp):>2} docs, {len(grp_stale)} overdue  (budget {BUDGET_DAYS[cadence]}d)")

    # Exit policy: frontmatter errors always fail (a doc with no last_verified
    # can't be audited). Staleness fails only under --strict.
    if errors:
        return 1
    if stale and strict:
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
