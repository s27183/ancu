#!/usr/bin/env python3
"""KB freshness scanner — turns "did anything go stale?" from memory into a command.

The KB is static (compiled to `persistent_term` at deploy); staleness is an
*audit* question, not a runtime gate (engine-contract §9.1). Nothing else in the
build checks it — `kb_compiler.py` validates structure + references, never age.
This script fills that gap: it reads the `last_verified` frontmatter of every
`docs/kb/**.md` doc, compares it against a per-cadence re-verification budget,
and reports which docs are overdue for a re-verify pass against their primary
source. `docs/kb/news/*.md` is excluded — those are dated, immutable
announcements with `authored_date` (kb_compiler.py's `parse_news_doc`), not
living fact docs with a re-verification cadence.

The cadence tiers are NOT invented here — they come straight from the update
cadence table in `docs/architecture/architecture.md §11.2`:

  - Weekly    — the RBA's AUD/VND reference reading (behavior 85).
  - Monthly   — lender policy, RBA cash rate, FHG panel / participating lenders;
                lender and FX-provider fees (behavior 85).
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

Regulated figures are grounded -> P-7 -> The KB -> a fact read off a yearly edition is re-read from the next edition once that edition is due
Behavior 134 (Son 2026-10-19: readers open the facts daily). Re-checking a doc
re-opens its own `sources:` URLs, so an edition published at a new URL (the next
Budget's state overviews, BITRE's next yearbook, the 1 July fee table) is never
seen. A doc read off such an edition says when the next one is expected:
  next_edition: <yyyy-mm>      the month the next edition is due
  next_edition_at: <url>       where it will appear (an index page, optional)
From the first day of that month the doc is listed under NEW EDITION DUE, ahead
of the overdue list, and kb-watch takes those docs first (kb-watch-routine.md
step 1). kb-watch sets `next_edition:` to the following year once it has read
the new edition. Measured 2026-10-19: 201 docs, 147 overdue.

Regulated figures are grounded -> P-7 -> The KB -> a doc with nothing a primary could confirm is not re-verified
Behavior 147 (Son 2026-11-01, issue #198). A doc whose sources are notes only (no
`url:`), that says nothing is REGULATED and that states no figure (a %, a $ amount,
a day/week/month/year count, a thousands-grouped number) has nothing kb-watch can
re-open or re-check: a copy template, a terms list, a placeholder. Such a doc is
listed under NOTHING TO RE-VERIFY and kept out of the overdue list kb-watch draws
its 30 from, so the weekly check stops reporting it as could-not-verify. A note-only
doc that does state a figure stays overdue: kb-watch checks it against the owner
docs its note names (kb-watch-routine.md step 2). Measured 2026-11-01: 201 docs,
18 listed. `--self-test` runs the rule over every doc plus four planted fixtures
(tests/fixtures/kb_freshness/) against a separately written reading of it.

Usage:
    python3 tests/kb_freshness.py
    python3 tests/kb_freshness.py --strict
    python3 tests/kb_freshness.py --asof 2026-09-01
    python3 tests/kb_freshness.py --self-test
"""
import datetime
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
KB_DIR = ROOT / "docs" / "kb"
NEWS_DIR = KB_DIR / "news"
FIXTURES = ROOT / "tests" / "fixtures" / "kb_freshness"

# A figure a primary could confirm: a %, a $ amount, a day/week/month/year count
# (optionally a range, optionally business/calendar/clear days), or a number with
# thousands separators.
FIGURE = re.compile(
    r"\d\s*%"
    r"|\$\s?\d"
    r"|\b\d+(?:\.\d+)?(?:\s*[–-]\s*\d+)?\s+(?:business\s+|calendar\s+|clear\s+)?"
    r"(?:day|week|month|year)s?\b"
    r"|\b\d{1,3}(?:,\d{3})+\b",
    re.I,
)


def nothing_to_reverify(text):
    """True when the doc has no `url:` source, no REGULATED line and no figure."""
    m = re.match(r"---\n(.*?)\n---\n", text, re.S)
    front = m.group(1) if m else ""
    if re.search(r"^\s*-?\s*url:\s*\S", front, re.M):
        return False
    if "REGULATED" in text:
        return False
    return not FIGURE.search(text)

# Re-verification budget per cadence tier, in days. Grounded in architecture
# §11.2; the day counts give a small grace over the nominal period.
BUDGET_DAYS = {
    "weekly": 8,
    "monthly": 31,
    "quarterly": 92,
    "per-event": 183,  # no fixed cadence — safety-net so it can't drift forever
}

# Longest-prefix-first cadence assignment. Only the deviations from the default
# need listing (§11.2): lender/LMI move monthly, FIRB is event-driven. Everything
# else falls through to DEFAULT_CADENCE.
CADENCE_RULES = [
    # Behavior 85 (Son 2026-10-16): the RBA's AUD/VND reading moves daily and is
    # re-read every weekly run; what a buyer pays a lender or a transfer provider
    # (its own published price) is re-checked monthly. Market bands drawn from
    # comparison sites (conveyancing, inspections, agents, insurance) stay quarterly.
    ("kb.fx.rba-aud-vnd", "weekly"),
    ("kb.fx.typical-spreads-vnd-aud", "monthly"),
    ("kb.fx-providers", "monthly"),
    ("kb.existing-home-sale.net-proceeds", "monthly"),
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
    ed_m = re.search(r"^next_edition:\s*['\"]?(\d{4}-\d{2})", text, re.M)
    at_m = re.search(r"^next_edition_at:\s*(\S+)", text, re.M)
    return (
        slug_m.group(1) if slug_m else None,
        ver_m.group(1) if ver_m else None,
        ed_m.group(1) if ed_m else None,
        at_m.group(1) if at_m else None,
    )


# Behavior 148 (Son 2026-11-01): a source marked `browser_only:` sits behind a bot challenge
# no script passes (legislation.nsw.gov.au, measured 2026-11-01), so kb-watch never opens
# it; its evidence is the copy Son saved in a browser. Its age is the `Retrieved: <date>`
# header of that saved copy — not the doc's `retrieved:`, which a date-only kb-watch edit
# could move and so silence this list. Once the copy is older than the doc's budget, the
# doc is listed under RE-SAVE IN A BROWSER and kb-watch puts it in Son's issue (step 6).
COPY_RETRIEVED = re.compile(r"(?:^|\s)Retrieved: (\d{4}-\d{2}-\d{2})")


def browser_only_sources(text):
    """(url, path) of each frontmatter source carrying `browser_only:`."""
    m = re.match(r"---\n(.*?)\n---", text, re.S)
    out, cur = [], None
    for line in (m.group(1) if m else "").splitlines():
        s = re.match(r"^\s*-\s*(url|note):\s*(.+?)\s*$", line)
        if s and len(line) - len(line.lstrip()) <= 4:
            cur = {s.group(1): s.group(2).strip('"')}
            out.append(cur)
            continue
        s = re.match(r"^\s+(browser_only|path):\s*(.+?)\s*$", line)
        if s and cur is not None:
            cur[s.group(1)] = s.group(2).strip('"')
    return [(c.get("url", ""), c.get("path", "")) for c in out if c.get("browser_only")]


def copy_retrieved(path_str):
    """The saved copy's own Retrieved: date, or None (missing copy or header)."""
    f = ROOT / path_str if path_str else None
    if not f or not f.is_file():
        return None
    m = COPY_RETRIEVED.search(f.read_text(errors="ignore")[:400])
    return m.group(1) if m else None


def resaves(text, asof, budget):
    """(url, copy date or 'none') for each browser-only source whose saved copy is
    older than `budget` days at `asof`, or has no dated copy at all."""
    out = []
    for url, path_str in browser_only_sources(text):
        d = copy_retrieved(path_str)
        if d is None or (asof - datetime.date.fromisoformat(d)).days > budget:
            out.append((url, d or "none"))
    return out


def resave_self_test():
    """Planted browser-only fixtures at a fixed date, against an oracle that reads the
    copy's header with plain string splitting."""
    asof = datetime.date(2026, 11, 1)
    planted = {"browser-only-fresh.md": False, "browser-only-old.md": True,
               "browser-only-no-copy.md": True}
    bad = []

    def oracle(text):
        parts = text.split("---")
        fm = parts[1] if len(parts) > 2 else ""
        blocks = fm.split("- url:")[1:]
        for b in blocks:
            if "browser_only:" not in b:
                continue
            path = [l.split("path:", 1)[1].strip() for l in b.split("\n") if l.strip().startswith("path:")]
            f = ROOT / path[0] if path else None
            if not f or not f.is_file():
                return True
            head = [l for l in f.read_text().split("\n")[:5] if l.startswith("Retrieved: ")]
            if not head:
                return True
            y, mo, d = head[0].split()[1].split("-")
            if (asof - datetime.date(int(y), int(mo), int(d))).days > 92:
                return True
        return False

    for name, want in planted.items():
        text = (FIXTURES / name).read_text()
        got = bool(resaves(text, asof, 92))
        if oracle(text) != want:
            bad.append(f"{name}: the oracle reads it as {oracle(text)}, planted as {want}")
        if got != want:
            bad.append(f"{name}: listed for re-save={got}, expected {want}")
    for p in sorted(KB_DIR.rglob("*.md")):
        if NEWS_DIR in p.parents:
            continue
        text = p.read_text()
        slug, *_ = parse_frontmatter(p)
        got = bool(resaves(text, asof, BUDGET_DAYS[cadence_for(slug or "")]))
        if BUDGET_DAYS[cadence_for(slug or "")] == 92 and got != oracle(text):
            bad.append(f"{p.relative_to(ROOT)}: listed for re-save={got}, oracle {oracle(text)}")
    return len(planted), bad


def self_test():
    """Every doc and each planted fixture: listed exactly when an independent
    reading says it has no url source, no REGULATED line and no figure."""
    def oracle(text):
        lines = text.split("\n")
        end = lines.index("---", 1) if lines and lines[0] == "---" and "---" in lines[1:] else 0
        has_url = any(l.strip().lstrip("- ").startswith("url:") and l.split("url:", 1)[1].strip()
                      for l in lines[1:end])
        has_reg = any("REGULATED" in l for l in lines)
        words = text.replace("\n", " ")
        has_fig = bool(
            re.search(r"[0-9] ?%", words)
            or re.search(r"\$ ?[0-9]", words)
            or re.search(r"(?i)\b[0-9][0-9.]*(?: ?[–-] ?[0-9]+)? +(?:(?:business|calendar|clear) +)?(?:days?|weeks?|months?|years?)\b", words)
            or re.search(r"\b[0-9]{1,3}(?:,[0-9]{3})+\b", words)
        )
        return not (has_url or has_reg or has_fig)

    expected = {"note-no-figure.md": True, "note-figure.md": False,
                "note-regulated.md": False, "url-no-figure.md": False}
    paths = [p for p in sorted(KB_DIR.rglob("*.md")) if NEWS_DIR not in p.parents]
    paths += [FIXTURES / name for name in sorted(expected)]
    bad = []
    for p in paths:
        text = p.read_text()
        got = nothing_to_reverify(text)
        want = expected.get(p.name, None) if p.parent == FIXTURES else oracle(text)
        if p.parent == FIXTURES and oracle(text) != want:
            bad.append(f"{p.name}: the oracle reads it as {oracle(text)}, planted as {want}")
        if got != want:
            bad.append(f"{p.relative_to(ROOT)}: listed={got}, expected {want}")
    n_resave, bad_resave = resave_self_test()
    bad += bad_resave
    print(f"kb_freshness self-test: {len(paths) + n_resave} cases, {len(bad)} counterexamples")
    for b in bad:
        print(f"  ✗ {b}")
    return 1 if bad else 0


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
    if "--self-test" in sys.argv[1:]:
        return self_test()
    strict, asof = parse_args(sys.argv[1:])

    rows = []      # (slug, cadence, last_verified, age_days, budget, status)
    errors = []    # docs missing slug / last_verified — a real problem
    due = []       # (slug, next_edition, next_edition_at) — a new edition is due
    quiet = []     # slugs with nothing a primary could confirm (behavior 147)
    resave = []    # (slug, url, copy date) — a browser-only copy past budget (behavior 148)

    for path in sorted(KB_DIR.rglob("*.md")):
        if NEWS_DIR in path.parents:
            # docs/kb/news/*.md is a different doc class (kb_compiler.py's
            # parse_news_doc / GATE 11): a dated, IMMUTABLE announcement with
            # authored_date, not a living fact doc with last_verified. It never
            # gets re-verified — there's nothing to be "stale" relative to, so
            # no cadence budget applies. Skip rather than flag.
            continue
        slug, last_verified, next_edition, next_at = parse_frontmatter(path)
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
        if nothing_to_reverify(path.read_text()):
            quiet.append(slug)
            continue
        if next_edition and next_edition <= asof.isoformat()[:7]:
            due.append((slug, next_edition, next_at or ""))
        cadence = cadence_for(slug)
        budget = BUDGET_DAYS[cadence]
        resave += [(slug, url, d) for url, d in resaves(path.read_text(), asof, budget)]
        age = (asof - lv).days
        status = "STALE" if age > budget else "ok"
        rows.append((slug, cadence, last_verified, age, budget, status))

    stale = [r for r in rows if r[5] == "STALE"]
    # Most overdue first; ties broken by slug for a stable report.
    stale.sort(key=lambda r: (-(r[3] - r[4]), r[0]))

    print(f"KB freshness — as of {asof.isoformat()} ({len(rows) + len(quiet)} docs scanned)\n")

    if errors:
        print("FRONTMATTER ERRORS (fix before relying on this report):")
        for rel, why in errors:
            print(f"  ✗ {rel} — {why}")
        print()

    if due:
        due.sort(key=lambda r: (r[1], r[0]))
        print(f"NEW EDITION DUE ({len(due)}):")
        for slug, month, at in due:
            print(f"  {slug:<34} due {month}  {at}".rstrip())
        print()

    if stale:
        print(f"OVERDUE FOR RE-VERIFY ({len(stale)}):")
        print(f"  {'slug':<34} {'cadence':<10} {'verified':<12} {'age':>5} {'budget':>7}")
        for slug, cadence, lv, age, budget, _ in stale:
            print(f"  {slug:<34} {cadence:<10} {lv:<12} {age:>4}d {budget:>6}d  (+{age - budget}d)")
        print()
    else:
        print("All scanned docs are within their re-verification budget.\n")

    if resave:
        print(f"RE-SAVE IN A BROWSER ({len(resave)}): a browser-only source's saved copy is past the doc's budget")
        for slug, url, d in resave:
            print(f"  {slug:<34} {url}  (copy of {d})")
        print()

    if quiet:
        print(f"NOTHING TO RE-VERIFY ({len(quiet)}): no url source, no REGULATED line, no figure")
        for slug in sorted(quiet):
            print(f"  {slug}")
        print()

    # Per-cadence summary so the operator sees the shape at a glance.
    print("By cadence:")
    for cadence in ("weekly", "monthly", "quarterly", "per-event"):
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
