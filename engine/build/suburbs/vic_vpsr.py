"""vic_vpsr — VIC suburb median house/unit price: the §7 price layer (VIC half).

Source: Victorian Property Sales Report (VPSR), Valuer-General Victoria, quarterly,
CC BY 4.0. Pre-aggregated median **by suburb** — so the correspondence is a NAME→SAL
crosswalk (suburb-data-foundation.md §5), NOT a spatial join (contrast the deferred
`nsw_vg_psi`, which is point→SAL = point-in-polygon against the SAL boundaries).

FETCH is **human-staged**, not a live pull: the .xls is a Crystal Reports BIFF export
served only from land.vic.gov.au behind a Cloudflare JS challenge (403 to any bot), and
the data.gov.au mirror's datastore API is stale. Quarterly cadence makes a manual
download legitimate — drop the current quarter's files (same quarter for both) at:

    engine/build/suburbs/data/vpsr-median-house.xls
    engine/build/suburbs/data/vpsr-median-unit.xls

Layout (grounded against the Oct–Dec 2025 file): rows 0–4 header, rows 5.. suburb rows,
final row a legend. The five quarter-median columns are 1,3,5,7,9 — col 9 is the LATEST
quarter, col 11 its sales count. col 0 = locality (UPPERCASE; LGA-qualified for
duplicates, e.g. 'ASCOT (GREATER BENDIGO)'). Footnote markers (col 10): '^' = fewer than
10 sales (thin market), '*' = no sales this quarter, figure carried forward.

This is an ENRICHMENT-facts adapter (db.update_facts): the medians land in `facts_jsonb`
(the map's raw-metric surface alongside seifa/ancestry; §6 — they are NOT columns), each
paired with its quarterly sales count as the small-n confidence denominator (the
[[adapter-band-sourced-vs-projected]] floor: ~200/772 localities are '^' thin markets).
UPDATE-only against the census spine — VPSR publishes its OWN valuation-locality gazette,
which is ≈ but ≠ ABS SAL, so localities with no SAL ('WESTGARTH', 'SYNDAL', sub-localities
ABS folds into a larger suburb) are logged drops, never guessed (§5,
[[enforce-invariants-not-workflows]]). ~96% of reported localities crosswalk; the ~2200
rural VIC SALs VPSR never reports keep median=null (honest-partial, §7). xls reader: xlrd
(legacy BIFF; openpyxl is .xlsx-only).

Run:  cd engine/build && ENGINE_DATABASE_URL=… ../../.venv/bin/python -m suburbs.vic_vpsr
"""
from __future__ import annotations

import os
import re
import sys
from collections import defaultdict

import xlrd

from . import db

DATA_DIR = os.path.join(os.path.dirname(__file__), "data")
MEDIAN_COL = 9   # rightmost of the five quarter-median columns (1,3,5,7,9) = latest quarter
SALES_COL = 11   # No. of Sales for that latest quarter (the small-n denominator)
FIRST_DATA_ROW = 5

# (file, median fact key, sales-count fact key)
FILES = [
    ("vpsr-median-house.xls", "median_house_price", "median_house_sales_qtr"),
    ("vpsr-median-unit.xls", "median_unit_price", "median_unit_sales_qtr"),
]

_QUARTER_END = {  # month-range label (row 1 of the median column) → quarter-end MM-DD
    "Jan-Mar": "03-31",
    "Apr-Jun": "06-30",
    "Jul-Sep": "09-30",
    "Oct-Dec": "12-31",
}

SOURCE = {
    "source_id": "vic_vpsr",
    "name": "Victorian Property Sales Report (VPSR) — median by suburb (house/unit), quarterly",
    "publisher": "Valuer-General Victoria (Department of Transport and Planning)",
    "license": "CC BY 4.0",
    "attribution": "© State of Victoria (Department of Transport and Planning), Victorian Property Sales Report",
    "redistribution": "permitted",
    "cadence": "quarterly",
    "url": "https://discover.data.vic.gov.au/dataset/victorian-property-sales-report-median-house-by-suburb",
    "notes": "Human-staged .xls (Cloudflare-gated). Median by suburb → name→SAL crosswalk; "
             "facts_jsonb median_{house,unit}_price + _sales_qtr. NSW/QLD price are separate (§7).",
}


def _norm(s: object) -> str:
    return re.sub(r"\s+", " ", str(s).strip()).upper()


# ABS SAL VIC names: bare ('Airport West'), state-tagged ('Abbotsford (Vic.)'),
# or LGA-disambiguated ('Ascot (Greater Bendigo - Vic.)'). → (base, lga|None).
_ABS_RE = re.compile(r"^(.*?)\s*\((?:(.+?)\s*-\s*)?Vic\.\)\s*$")
# VPSR localities: bare ('ABBOTSFORD') or LGA-qualified ('ASCOT (GREATER BENDIGO)').
_VPSR_RE = re.compile(r"^(.*?)\s*\((.+)\)\s*$")


def _abs_parse(name: str) -> tuple[str, str | None]:
    m = _ABS_RE.match(name)
    if m:
        return _norm(m.group(1)), (_norm(m.group(2)) if m.group(2) else None)
    return _norm(name), None


def _vpsr_parse(locality: str) -> tuple[str, str | None]:
    m = _VPSR_RE.match(locality.strip())
    if m:
        return _norm(m.group(1)), _norm(m.group(2))
    return _norm(locality), None


def _build_index(conn) -> dict[str, list[tuple[str, str | None]]]:
    """VIC census-spine names → {base_name: [(sal_code, lga|None), …]} for the crosswalk."""
    idx: dict[str, list[tuple[str, str | None]]] = defaultdict(list)
    with conn.cursor() as cur:
        cur.execute("SELECT sal_code, name FROM suburbs WHERE state = 'VIC'")
        for sal, name in cur.fetchall():
            base, lga = _abs_parse(name)
            idx[base].append((sal, lga))
    return idx


def _resolve(base: str, lga: str | None, idx: dict) -> str | None:
    """Name→SAL: unique base wins; a multi-SAL base is disambiguated by the LGA qualifier.
    Returns the sal_code, or None when absent/ambiguous (the caller logs the drop)."""
    cands = idx.get(base)
    if not cands:
        return None
    if len(cands) == 1:
        return cands[0][0]
    hit = [sal for sal, clga in cands if clga is not None and clga == lga]
    return hit[0] if len(hit) == 1 else None


def _as_of(sheet) -> str:
    """Derive the data quarter from the latest median column's header (row 1 range +
    row 2 year), e.g. 'Oct-Dec' 2025 → '2025-12-31'. Fail-closed if unrecognised — we do
    not guess the currency of a regulated-adjacent figure."""
    label = str(sheet.cell_value(1, MEDIAN_COL)).strip()
    year = int(float(sheet.cell_value(2, MEDIAN_COL)))
    if label not in _QUARTER_END:
        raise ValueError(f"vic_vpsr: unrecognised quarter label {label!r} at col {MEDIAN_COL} — layout changed?")
    return f"{year}-{_QUARTER_END[label]}"


def _read_file(path: str) -> tuple[list[tuple[str, int, int | None]], str]:
    """Parse one VPSR sheet → ([(locality, median_int, sales_int|None)], as_of)."""
    sheet = xlrd.open_workbook(path).sheet_by_index(0)
    as_of = _as_of(sheet)
    out: list[tuple[str, int, int | None]] = []
    for r in range(FIRST_DATA_ROW, sheet.nrows):
        locality = str(sheet.cell_value(r, 0)).strip()
        raw = str(sheet.cell_value(r, MEDIAN_COL)).strip()
        if not locality or not raw.replace(".", "").isdigit():
            continue  # legend row / suppressed median
        median = int(round(float(raw)))
        sraw = str(sheet.cell_value(r, SALES_COL)).strip()
        sales = int(round(float(sraw))) if sraw.replace(".", "").isdigit() else None
        out.append((locality, median, sales))
    return out, as_of


def run() -> tuple[int, int]:
    if not os.path.isdir(DATA_DIR):
        raise SystemExit(f"vic_vpsr: staged-file dir missing: {DATA_DIR} (download VPSR .xls there)")

    conn = db.connect()
    try:
        idx = _build_index(conn)
        # Accumulate facts per SAL across both files so each SAL gets one UPDATE carrying
        # whichever of house/unit it has.
        facts: dict[str, dict] = defaultdict(dict)
        prov: dict[str, dict] = defaultdict(dict)
        dropped: list[str] = []

        for fname, price_key, sales_key in FILES:
            path = os.path.join(DATA_DIR, fname)
            if not os.path.exists(path):
                raise SystemExit(f"vic_vpsr: missing staged file {path}")
            rows, as_of = _read_file(path)
            src = {"source_id": SOURCE["source_id"], "as_of": as_of}
            hit = 0
            for locality, median, sales in rows:
                base, lga = _vpsr_parse(locality)
                sal = _resolve(base, lga, idx)
                if sal is None:
                    dropped.append(f"{fname}:{locality}")
                    continue
                facts[sal][price_key] = median
                prov[sal][price_key] = src
                if sales is not None:
                    facts[sal][sales_key] = sales
                    prov[sal][sales_key] = src
                hit += 1
            print(f"  {fname}: {hit}/{len(rows)} localities crosswalked (as_of {as_of})", file=sys.stderr)

        update_rows = [
            {"sal_code": sal, "facts": facts[sal], "prov": prov[sal]} for sal in facts
        ]
        db.ensure_source(conn, SOURCE)
        matched, missed = db.update_facts(conn, update_rows)
        conn.commit()
    finally:
        conn.close()

    if dropped:
        # VPSR localities with no ABS SAL (its gazette ≈ but ≠ SAL) — logged, never guessed.
        print(f"  {len(dropped)} VPSR localities had no SAL match (e.g. {dropped[:5]})", file=sys.stderr)
    if missed:
        print(f"  {len(missed)} SALs had no spine row (unexpected — e.g. {missed[:5]})", file=sys.stderr)
    return matched, len(missed)


if __name__ == "__main__":
    matched, missed = run()
    print(f"vic_vpsr: median price on {matched} VIC suburbs ({missed} unmatched spine rows)")
