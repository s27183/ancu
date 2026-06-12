"""bocsar — NSW suburb crime rate: the §6 crime layer (NSW third of the crime family).

Source: BOCSAR "Recorded Criminal Incidents by month – by suburb", quarterly, CC BY 4.0.
The fetch is a clean **live-pull** (contrast vic_vpsr's human-staged .xls): SuburbData.zip
sits on an Azure blob with no auth/Cloudflare wall, so the adapter pulls + streams it. The
zip holds one wide CSV — (Suburb, Offence category, Subcategory, then a column per month
from Jan 1995 to the latest) of raw monthly incident COUNTS. No rate, no population.

So the adapter computes the rate itself: sum **all** offence subcategories over the
**trailing 12 months** per suburb → an annual incident count, then

    crime_incidents_per_1000 = annual / census_total_persons * 1000

— the population denominator the census adapter stored for exactly this (§8). Summing ALL
offences is the least-interpretive composite (it privileges no category); a
residential-safety subset (e.g. dropping liquor / transport-regulatory) is KB-band
curation, deferred (§8). The COUNT and window are stored too (`crime_incidents_annual`,
`crime_period`) as the small-n confidence floor — a 30-person locality with 5 incidents
reads as a huge rate, so the resolver's band projection floors on population (§8); the
adapter stays mechanical and stores the numerator so the floor has it.

The `crime_safety_band` enum is **not** stored: the resolver projects it from the rate + a
KB threshold (§8), because BOCSAR publishes no band — OUR interpretive band, not a sourced
one ([[adapter-band-sourced-vs-projected]]).

ENRICHMENT-facts (db.update_facts), UPDATE-only against the NSW census spine via the shared
name→SAL crosswalk (`_namecross`; 100% coverage measured — the NSW gazette enforces name
uniqueness, LGA-qualifying only the duplicate tail, both sides). NSW SALs BOCSAR never
reports keep crime=null (honest-partial). VIC / QLD crime are separate adapters
(`csa_vic`, `qps` — §6).

Run:  cd engine/build && ENGINE_DATABASE_URL=… ../../.venv/bin/python -m suburbs.bocsar
"""
from __future__ import annotations

import csv
import io
import sys
import zipfile
from collections import defaultdict

import httpx

from . import _namecross, db

ZIP_URL = "https://bocsarblob.blob.core.windows.net/bocsar-open-data/SuburbData.zip"
WINDOW_MONTHS = 12        # trailing window → the current annual rate
FIRST_MONTH_COL = 3       # cols 0,1,2 = Suburb, Offence category, Subcategory

# Quarter-end month → MM-DD. BOCSAR releases quarterly, so the latest column is always a
# quarter-end month; fail-closed on anything else rather than guess a figure's currency
# (same discipline as vic_vpsr._as_of).
_MONTH_END = {"Mar": "03-31", "Jun": "06-30", "Sep": "09-30", "Dec": "12-31"}

SOURCE = {
    "source_id": "bocsar",
    "name": "BOCSAR Recorded Criminal Incidents by month – by suburb",
    "publisher": "NSW Bureau of Crime Statistics and Research",
    "license": "CC BY 4.0",
    "attribution": "© State of New South Wales (NSW Bureau of Crime Statistics and Research)",
    "redistribution": "permitted",
    "cadence": "quarterly",
    "url": "https://data.nsw.gov.au/data/dataset/crime-by-offence-by-nsw-suburb",
    "notes": "Live-pull SuburbData.zip (Azure blob). Monthly incident counts → trailing-12mo "
             "sum / census_total_persons * 1000 = crime_incidents_per_1000 (NSW). All offences "
             "summed; band is resolver-projected (§8). VIC/QLD crime are separate (§6).",
}


def _as_of(last_label: str) -> str:
    """Latest month column header ('Dec 2025') → window-end date ('2025-12-31'),
    fail-closed on a non-quarter-end month (BOCSAR is quarterly)."""
    parts = last_label.split()
    if len(parts) != 2 or parts[0] not in _MONTH_END:
        raise ValueError(f"bocsar: unrecognised latest-month header {last_label!r} — layout changed?")
    return f"{parts[1]}-{_MONTH_END[parts[0]]}"


def _fetch() -> bytes:
    with httpx.Client(timeout=180, follow_redirects=True) as client:
        r = client.get(ZIP_URL)
        r.raise_for_status()
        return r.content


def _parse(zip_bytes: bytes) -> tuple[dict[str, int], str, str]:
    """Stream the wide CSV → ({suburb: annual_incident_count}, as_of, period_label).

    Sums all offence subcategory rows over the trailing WINDOW_MONTHS columns per suburb;
    the 432MB CSV is read row-by-row (never fully in memory)."""
    zf = zipfile.ZipFile(io.BytesIO(zip_bytes))
    name = next(n for n in zf.namelist() if n.lower().endswith(".csv"))
    totals: dict[str, int] = defaultdict(int)
    with zf.open(name) as fh:
        reader = csv.reader(io.TextIOWrapper(fh, encoding="utf-8-sig"))
        header = next(reader)
        win = list(range(len(header)))[-WINDOW_MONTHS:]  # last 12 month columns
        as_of = _as_of(header[win[-1]].strip())
        period = f"{header[win[0]].strip()} – {header[win[-1]].strip()}"
        for row in reader:
            if len(row) <= win[-1]:
                continue
            n = 0
            for c in win:
                v = row[c].strip()
                if v.isdigit():
                    n += int(v)
            totals[row[0].strip()] += n
    return dict(totals), as_of, period


def _population(conn) -> dict[str, int]:
    """{sal_code: census_total_persons} for NSW — the rate denominator (§8)."""
    pop: dict[str, int] = {}
    with conn.cursor() as cur:
        cur.execute(
            "SELECT sal_code, (facts_jsonb->>'census_total_persons')::int "
            "FROM suburbs WHERE state = 'NSW' AND facts_jsonb ? 'census_total_persons'"
        )
        for sal, persons in cur.fetchall():
            pop[sal] = persons
    return pop


def run() -> tuple[int, int]:
    totals, as_of, period = _parse(_fetch())
    conn = db.connect()
    try:
        xw = _namecross.build(conn, "NSW", "NSW")
        pop = _population(conn)
        src = {"source_id": SOURCE["source_id"], "as_of": as_of}
        rows: list[dict] = []
        dropped: list[str] = []
        no_pop = 0
        for suburb, annual in totals.items():
            sal = xw.resolve(suburb)
            if sal is None:
                dropped.append(suburb)
                continue
            facts = {"crime_incidents_annual": annual, "crime_period": period}
            prov = {"crime_incidents_annual": src, "crime_period": src}
            persons = pop.get(sal)
            if persons and persons > 0:
                facts["crime_incidents_per_1000"] = round(annual / persons * 1000, 1)
                prov["crime_incidents_per_1000"] = src
            else:
                no_pop += 1  # honest-partial: count stored, rate null (no denominator)
            rows.append({"sal_code": sal, "facts": facts, "prov": prov})

        db.ensure_source(conn, SOURCE)
        matched, missed = db.update_facts(conn, rows)
        conn.commit()
    finally:
        conn.close()

    print(f"  window {period} (as_of {as_of}); {len(totals)} BOCSAR suburbs", file=sys.stderr)
    if dropped:
        # BOCSAR localities with no ABS SAL (its gazette ≈ but ≠ SAL) — logged, never guessed.
        print(f"  {len(dropped)} BOCSAR localities had no SAL match (e.g. {dropped[:5]})", file=sys.stderr)
    if no_pop:
        print(f"  {no_pop} matched SALs had no population → rate null (count kept)", file=sys.stderr)
    if missed:
        print(f"  {len(missed)} SALs had no spine row (unexpected — e.g. {missed[:5]})", file=sys.stderr)
    return matched, len(missed)


if __name__ == "__main__":
    matched, missed = run()
    print(f"bocsar: crime rate on {matched} NSW suburbs ({missed} unmatched spine rows)")
