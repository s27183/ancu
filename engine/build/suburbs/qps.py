"""QLD suburb crime — Queensland Police Service, Reported Offences by police division.

The QLD third of the crime family (NSW=bocsar, VIC=csa_vic, QLD=this). Same metric
MECHANISM — sum offences over the latest annual window per area → /census_total_persons
* 1000 = crime_incidents_per_1000, map-only, no resolver band ([[adapter-band-sourced-vs-projected]]).
Two grounded differences lower coverage by SOURCE, not by choice:

  * GRAIN is POLICE DIVISION, not suburb. QPS publishes no suburb-level data (the open
    "Reported Offences by Suburb" data-request confirms it). A division ≈ a locality (Inala,
    Acacia Ridge ARE divisions) but its boundary ≠ ABS SAL, and only ~335 divisions exist for
    ~3,235 QLD SALs. So division-name → SAL is best-effort: division-named suburbs get a rate,
    the rest stay null (honest-partial). Solid on the SE-QLD metro hubs, sparse rurally.
  * NO double-count. The CSV's 91 offence columns are a HIERARCHY (leaves + subtotals).
    Total = the THREE top-level QPS divisions — "Offences Against the Person" + "Offences
    Against Property" + "Other Offences" — verified mutually exclusive & exhaustive
    ("Other Offences" == Σ its 11 mid-subtotals, 2000/2000 rows). Summing all 91 triple-counts.

FETCH is human-staged: data.qld.gov.au sits behind an AWS WAF challenge (bot-walled like VPSR),
refetchable only via a browser → the staged CSV is gitignored, refetch URL in data/README.md.
Long-format CSV: one row per (Division, "Month Year" = MONYY); we take the trailing 12 months
ending at the latest month present.

Run:  cd engine/build && ENGINE_DATABASE_URL=… ../../.venv/bin/python -m suburbs.qps
"""
from __future__ import annotations

import calendar
import csv
import glob
import os
import sys
from collections import defaultdict

from . import _namecross, db

DATA_DIR = os.path.join(os.path.dirname(__file__), "data")
FILE_GLOB = "division_Reported_Offences_Number.csv"
WINDOW_MONTHS = 12
TOP = ("Offences Against the Person", "Offences Against Property", "Other Offences")
_MON = {"JAN": 1, "FEB": 2, "MAR": 3, "APR": 4, "MAY": 5, "JUN": 6,
        "JUL": 7, "AUG": 8, "SEP": 9, "OCT": 10, "NOV": 11, "DEC": 12}
_MON_NAME = {v: k.title() for k, v in _MON.items()}

# Honest-partial -> R-1 · Context from action -> The suburb adapters -> source grain skip threshold
# A coarse-grain source ships best-effort only when one source unit is close to one SAL by
# name (QPS: ~335 divisions, many named for a suburb). Coarser than that is skipped to null:
# WA Police publishes bulk crime only by District (~15 for ~1,700 SALs; suburb-level is
# interactive-only), so there is no WA adapter and WA crime stays null. WA measured June
# 2026 by a WebSearch sweep; the threshold itself is concluded, not measured.
SOURCE = {
    "source_id": "qps",
    "name": "Reported Offences by police division, monthly",
    "publisher": "Queensland Police Service",
    "license": "CC BY 4.0",
    "attribution": "© State of Queensland (Queensland Police Service)",
    "redistribution": "permitted",
    "cadence": "monthly",
    "url": "https://www.data.qld.gov.au/dataset/offence-numbers-police-divisions-monthly-from-july-2001",
    "notes": "Human-staged CSV (AWS-WAF-walled portal). Grain = POLICE DIVISION (QPS publishes no "
             "suburb-level). Total = Person + Property + Other (top-level QPS partition, no double-count) "
             "over trailing 12mo → /census_total_persons * 1000 = crime_incidents_per_1000 (QLD). "
             "division→SAL best-effort; map-only, no band. Coverage < NSW/VIC (division-named suburbs only).",
}


def _staged_file() -> str:
    hits = sorted(glob.glob(os.path.join(DATA_DIR, FILE_GLOB)))
    if not hits:
        raise SystemExit(f"qps: no staged file {FILE_GLOB} in {DATA_DIR} "
                         "(download the QPS 'police divisions monthly' CSV there)")
    return hits[-1]


def _mkey(m: str) -> tuple[int, int]:
    """'MAY26' → (2026, 5). 2-digit year: <90 → 2000s."""
    yy = int(m[3:])
    return (2000 + yy if yy < 90 else 1900 + yy, _MON[m[:3].upper()])


def _parse(path: str) -> tuple[dict[str, int], str, str]:
    """Long CSV → ({division: annual_total}, as_of, period). Total = the three top-level QPS
    divisions summed over the trailing WINDOW_MONTHS months ending at the latest month."""
    with open(path, newline="", encoding="utf-8-sig") as fh:
        r = csv.reader(fh)
        hdr = next(r)
        idx = {h: i for i, h in enumerate(hdr)}
        try:
            top_cols = [idx[t] for t in TOP]
            i_div, i_mon = idx["Division"], idx["Month Year"]
        except KeyError as e:
            raise SystemExit(f"qps: column {e} missing — layout changed? header[:4]={hdr[:4]}")
        last_col = max(top_cols + [i_div, i_mon])
        monthly: dict[str, dict[tuple[int, int], int]] = defaultdict(dict)
        months: set[tuple[int, int]] = set()
        for row in r:
            if len(row) <= last_col:
                continue
            mk = _mkey(row[i_mon])
            months.add(mk)
            t = 0
            for c in top_cols:
                v = row[c].strip()
                if v.lstrip("-").isdigit():
                    t += int(v)
            monthly[row[i_div]][mk] = monthly[row[i_div]].get(mk, 0) + t
    if not months:
        raise SystemExit("qps: no rows parsed — layout changed?")
    window = set(sorted(months)[-WINDOW_MONTHS:])
    totals = {div: sum(v for mk, v in mks.items() if mk in window) for div, mks in monthly.items()}
    last = max(window)
    first = min(window)
    as_of = f"{last[0]}-{last[1]:02d}-{calendar.monthrange(last[0], last[1])[1]:02d}"
    period = f"{_MON_NAME[first[1]]} {first[0]} – {_MON_NAME[last[1]]} {last[0]}"
    return totals, as_of, period


def _population(conn) -> dict[str, int]:
    """{sal_code: census_total_persons} for QLD — the rate denominator (§8)."""
    pop: dict[str, int] = {}
    with conn.cursor() as cur:
        cur.execute(
            "SELECT sal_code, (facts_jsonb->>'census_total_persons')::int "
            "FROM suburbs WHERE state = 'QLD' AND facts_jsonb ? 'census_total_persons'"
        )
        for sal, persons in cur.fetchall():
            pop[sal] = persons
    return pop


def run() -> tuple[int, int]:
    totals, as_of, period = _parse(_staged_file())
    conn = db.connect()
    try:
        xw = _namecross.build(conn, "QLD", "Qld.")
        pop = _population(conn)
        src = {"source_id": SOURCE["source_id"], "as_of": as_of}

        by_sal: dict[str, int] = defaultdict(int)
        dropped: list[str] = []
        for division, annual in totals.items():
            sal = xw.resolve(division)
            if sal is None:
                dropped.append(division)
                continue
            by_sal[sal] += annual  # a division name maps to its SAL; >1 division → same SAL folds

        rows: list[dict] = []
        no_pop = 0
        for sal, annual in by_sal.items():
            facts = {"crime_incidents_annual": annual, "crime_period": period}
            prov = {"crime_incidents_annual": src, "crime_period": src}
            persons = pop.get(sal)
            if persons and persons > 0:
                facts["crime_incidents_per_1000"] = round(annual / persons * 1000, 1)
                prov["crime_incidents_per_1000"] = src
            else:
                no_pop += 1  # honest-partial: count stored, rate null
            rows.append({"sal_code": sal, "facts": facts, "prov": prov})

        db.ensure_source(conn, SOURCE)
        matched, missed = db.update_facts(conn, rows)
        conn.commit()
    finally:
        conn.close()

    print(f"  window {period} (as_of {as_of}); {len(totals)} QPS divisions → {len(by_sal)} SALs",
          file=sys.stderr)
    if dropped:
        # divisions with no matching SAL name (a division ≠ a gazetted suburb) — logged, never guessed.
        print(f"  {len(dropped)} divisions had no SAL match (e.g. {dropped[:5]})", file=sys.stderr)
    if no_pop:
        print(f"  {no_pop} matched SALs had no population → rate null (count kept)", file=sys.stderr)
    if missed:
        print(f"  {len(missed)} SALs had no spine row (unexpected — e.g. {missed[:5]})", file=sys.stderr)
    return matched, len(missed)


if __name__ == "__main__":
    matched, missed = run()
    print(f"qps: crime rate on {matched} QLD suburbs ({missed} unmatched spine rows)")
