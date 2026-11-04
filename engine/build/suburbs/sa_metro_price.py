"""sa_metro_price — SA suburb median house price: the §7 price layer (SA half).

Source: "Metro median house sales", Department for Housing and Urban Development
(South Australia), quarterly, **CC BY 3.0 AU** (note: 3.0 AU, attribution-only — NOT
4.0; still commercial-clean). Pre-aggregated median **by suburb** for METROPOLITAN
ADELAIDE ONLY (no free regional-SA equivalent — those suburbs keep median=null,
honest-partial, §7). So the correspondence is a NAME→SAL crosswalk (the shared
`_namecross` machine), the same shape as `vic_vpsr` — not a spatial join.

FETCH is **human-staged**, not a live pull: data.sa.gov.au refuses every programmatic
client (403 to curl/UA/Referer, sandboxed or not — a JS/cookie fingerprint check only a
real browser passes), while the data.gov.au CKAN harvester still serves the *metadata*.
Quarterly cadence makes a manual browser download legitimate (the same call as VPSR).
Because the file host walls automation it is also non-refetchable by the build → the
small (~37 KB) .xlsx is COMMITTED (data/README.md), not gitignored. Drop the latest
quarter's file at:

    engine/build/suburbs/data/lsg_stats_<YYYY>_q<N>.xlsx   (e.g. lsg_stats_2026_q1.xlsx)

Layout (grounded against the Q1 2026 file — single sheet 'Sheet1'): row 0 header
'City | Suburb | Sales <Q> <YYYY-1> | Median <Q> <YYYY-1> | Sales <Q> <YYYY> | Median <Q> <YYYY> | Median Change';
rows 1.. one per suburb. We read the LATEST 'Median <q>Q <year>' column (and its paired
'Sales' column = the small-n confidence denominator), discovered by header text so a
column reshuffle can't silently mis-read. 'City' is the council grouping: a suburb that
touches two councils is listed once PER council with the SAME whole-suburb figure
repeated (verified: 31/31 duplicate pairs identical, 0% spread) — so we dedup by suburb
name, and FAIL-CLOSED (skip + log) if a future quarter's duplicate rows ever DISAGREE,
rather than guess which to keep.

This is an ENRICHMENT-facts adapter (db.update_facts): the median lands in `facts_jsonb`
under the SAME keys as VIC (`median_house_price` + `median_house_sales_qtr`) so the map
renders VIC and SA price uniformly. House-only (the dataset has no unit series). UPDATE
against the census spine; source localities with no SAL (SA gazette ≈ but ≠ ABS SAL) are
logged drops, never guessed (§5, [[enforce-invariants-not-workflows]]). xlsx reader:
openpyxl.

Run:  cd engine/build && ENGINE_DATABASE_URL=… ../../.venv/bin/python -m suburbs.sa_metro_price
"""
from __future__ import annotations

import glob
import os
import re
import sys
from collections import defaultdict

import openpyxl

from . import _namecross, db

DATA_DIR = os.path.join(os.path.dirname(__file__), "data")
FILE_GLOB = "lsg_stats_*.xlsx"

_MEDIAN_RE = re.compile(r"^Median\s+(\d)Q\s+(\d{4})$", re.IGNORECASE)
_SALES_RE = re.compile(r"^Sales\s+(\d)Q\s+(\d{4})$", re.IGNORECASE)
_QUARTER_END = {1: "03-31", 2: "06-30", 3: "09-30", 4: "12-31"}

SOURCE = {
    "source_id": "sa_metro_price",
    "name": "Metro median house sales — median by suburb (house), quarterly (metro Adelaide only)",
    "publisher": "Department for Housing and Urban Development (South Australia)",
    "license": "CC BY 3.0 AU",
    "attribution": "© Government of South Australia (Department for Housing and Urban Development), Metro Median House Sales",
    "redistribution": "permitted",
    "cadence": "quarterly",
    "url": "https://data.sa.gov.au/data/dataset/metro-median-house-sales",
    "notes": "Human-staged .xlsx (data.sa.gov.au walls programmatic clients; resolve via data.gov.au CKAN). "
             "Metro Adelaide only → regional-SA suburbs keep median=null (§7). Median by suburb → name→SAL "
             "crosswalk; facts_jsonb median_house_price + median_house_sales_qtr (same keys as vic_vpsr).",
}


def _latest_columns(header: tuple) -> tuple[int, int, int, str]:
    """Locate (suburb_col, median_col, sales_col, as_of) by header text — fail-closed.

    Picks the rightmost-in-time 'Median <q>Q <year>' column (max (year, quarter)) and its
    paired 'Sales' column, so the adapter reads the current quarter even if columns move."""
    sub_col = next((i for i, h in enumerate(header) if str(h).strip().lower() == "suburb"), None)
    if sub_col is None:
        raise ValueError(f"sa_metro_price: no 'Suburb' column in header {header!r} — layout changed?")

    medians: dict[tuple[int, int], int] = {}  # (year, q) -> col
    sales: dict[tuple[int, int], int] = {}
    for i, h in enumerate(header):
        cell = str(h).strip() if h is not None else ""
        m = _MEDIAN_RE.match(cell)
        if m:
            medians[(int(m.group(2)), int(m.group(1)))] = i
        s = _SALES_RE.match(cell)
        if s:
            sales[(int(s.group(2)), int(s.group(1)))] = i
    if not medians:
        raise ValueError(f"sa_metro_price: no 'Median <q>Q <year>' column in header {header!r}")
    key = max(medians)  # (year, quarter)
    year, q = key
    if q not in _QUARTER_END:
        raise ValueError(f"sa_metro_price: unrecognised quarter {q} in header — layout changed?")
    if key not in sales:
        raise ValueError(f"sa_metro_price: no 'Sales {q}Q {year}' to pair the latest median column")
    return sub_col, medians[key], sales[key], f"{year}-{_QUARTER_END[q]}"


def _num(v: object) -> float | None:
    try:
        return float(v)
    except (TypeError, ValueError):
        return None


def _read_file(path: str) -> tuple[dict[str, tuple[int, int | None]], str, list[str]]:
    """Parse the latest-quarter median/sales per suburb. Returns
    ({SUBURB: (median, sales|None)}, as_of, conflicts) — `conflicts` are suburbs whose
    duplicate council rows DISAGREE on the median (skipped, fail-closed)."""
    ws = openpyxl.load_workbook(path, read_only=True, data_only=True)["Sheet1"]
    it = ws.iter_rows(values_only=True)
    header = next(it)
    sub_col, med_col, sales_col, as_of = _latest_columns(header)

    out: dict[str, tuple[int, int | None]] = {}
    conflicts: list[str] = []
    for row in it:
        sub_raw = row[sub_col]
        med = _num(row[med_col]) if med_col < len(row) else None
        if not sub_raw or med is None or med <= 0:
            continue  # blank suburb / no median this quarter
        name = re.sub(r"\s+", " ", str(sub_raw).strip()).upper()
        median = int(round(med))
        sraw = _num(row[sales_col]) if sales_col < len(row) else None
        sales = int(round(sraw)) if sraw is not None else None
        if name in out:
            # Same suburb listed once per touching council — figures must agree.
            if out[name][0] != median:
                conflicts.append(name)
            continue
        out[name] = (median, sales)
    for c in conflicts:
        out.pop(c, None)
    return out, as_of, conflicts


def run() -> tuple[int, int]:
    if not os.path.isdir(DATA_DIR):
        raise SystemExit(f"sa_metro_price: staged-file dir missing: {DATA_DIR}")
    files = sorted(glob.glob(os.path.join(DATA_DIR, FILE_GLOB)))
    if not files:
        raise SystemExit(
            f"sa_metro_price: no {FILE_GLOB} in {DATA_DIR} — stage the latest quarter "
            "from https://data.sa.gov.au/data/dataset/metro-median-house-sales"
        )
    path = files[-1]  # lexically latest == most recent quarter (lsg_stats_YYYY_qN)

    by_suburb, as_of, conflicts = _read_file(path)
    print(f"  {os.path.basename(path)}: {len(by_suburb)} suburbs with a median (as_of {as_of})", file=sys.stderr)

    conn = db.connect()
    try:
        xw = _namecross.build(conn, "SA", "SA")
        src = {"source_id": SOURCE["source_id"], "as_of": as_of}
        facts: dict[str, dict] = defaultdict(dict)
        prov: dict[str, dict] = defaultdict(dict)
        dropped: list[str] = []
        for name, (median, sales) in by_suburb.items():
            sal = xw.resolve(name)
            if sal is None:
                dropped.append(name)
                continue
            facts[sal]["median_house_price"] = median
            prov[sal]["median_house_price"] = src
            if sales is not None:
                facts[sal]["median_house_sales_qtr"] = sales
                prov[sal]["median_house_sales_qtr"] = src

        update_rows = [{"sal_code": sal, "facts": facts[sal], "prov": prov[sal]} for sal in facts]
        db.ensure_source(conn, SOURCE)
        matched, missed = db.update_facts(conn, update_rows)
        conn.commit()
    finally:
        conn.close()

    if conflicts:
        print(f"  {len(conflicts)} suburbs had DISAGREEING duplicate rows (skipped): {conflicts[:5]}", file=sys.stderr)
    if dropped:
        # SA-gazette localities with no ABS SAL (≈ but ≠), or regional names — logged, never guessed.
        print(f"  {len(dropped)} SA localities had no SAL match (e.g. {dropped[:5]})", file=sys.stderr)
    if missed:
        print(f"  {len(missed)} SALs had no spine row (unexpected — e.g. {missed[:5]})", file=sys.stderr)
    return matched, len(missed)


if __name__ == "__main__":
    matched, missed = run()
    print(f"sa_metro_price: median price on {matched} SA (metro Adelaide) suburbs ({missed} unmatched spine rows)")
