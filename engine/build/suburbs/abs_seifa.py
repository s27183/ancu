"""abs_seifa_2021 — IRSAD socio-economic decile + score per SAL (the SES spine).

Source: ABS SEIFA 2021 (Socio-Economic Indexes for Areas), published at SAL
**directly** — no correspondence needed (suburb-data-foundation.md §5), the same
spine grain as the census layer. Contract verified live (Cabramatta SAL10738 →
IRSAD decile 1, score 823, URP 21142 — the URP matches census_total_persons
21142 exactly, cross-validating the SAL join key):

    host  https://data.api.abs.gov.au/rest
    flow  ABS_SEIFA2021_SAL
    key   SAL . SEIFAINDEXTYPE . SEIFA_MEASURE   (dim order from the CSV header)
          we pull all SALs (empty 1st position) . IRSAD . SCORE+RWAD+URP
            IRSAD = Index of Relative Socio-economic Advantage and Disadvantage
            SCORE → seifa_irsad_score   (raw, map-facing — the heatmap gradient)
            RWAD  → seifa_irsad_decile  (Rank Within Australia, Decile 1–10)
            URP   → seifa_irsad_population (Usual Resident Population)

Three deliberate divergences from `abs_census` (grounded, not taste):

  1. **Writes the decile DIRECTLY** — unlike the Vietnamese band (which is a
     FirstHomey interpretation → resolver projects it from a KB threshold), the
     SEIFA decile `RWAD` is an **official ABS national-distribution statistic**.
     There is no threshold for us to apply; §3 lists `seifa_irsad_decile` as the
     resolver-facing `suburb.*` field. So this adapter writes both the raw score
     (map) and the decile (resolver) — both sourced. (The §2/§8 "adapter writes
     raw, resolver projects the band" rule's boundary is *interpretive* bands;
     an ABS-published decile falls outside it.)
  2. **CSV, not SDMX-JSON** — this is an ENRICHMENT adapter (carries no name/state;
     the census spine owns those), so it needs no structure-section parsing for
     REGION→name and no per-state paging (the flow has no STATE dimension). The
     filtered CSV key is self-describing via column headers and ~3.4 MB.
  3. **Stores URP (population)** — same rationale as the census denominator: the
     small-n / SEIFA-exclusion floor for any future banding + the map population
     layer. Empty OBS_VALUE (ABS suppresses excluded areas) → honest-partial null.

Run:  cd engine/build && ENGINE_DATABASE_URL=… ../../.venv/bin/python -m suburbs.abs_seifa
"""
from __future__ import annotations

import csv
import io
import sys

import httpx

from . import db

BASE = "https://data.api.abs.gov.au/rest"
FLOW = "ABS_SEIFA2021_SAL"
INDEX = "IRSAD"
SEIFA_AS_OF = "2021-08-10"  # Census 2021 reference period (SEIFA is built from it)

# ABS SEIFA_MEASURE code → our facts_jsonb field. Decile + score + population.
MEASURE_FIELD = {
    "SCORE": "seifa_irsad_score",       # raw index score (map heatmap)
    "RWAD": "seifa_irsad_decile",       # national decile 1–10 (resolver suburb.*)
    "URP": "seifa_irsad_population",    # usual resident population (small-n floor)
}

SOURCE = {
    "source_id": "abs_seifa_2021",
    "name": "Socio-Economic Indexes for Areas (SEIFA) 2021 — IRSAD",
    "publisher": "Australian Bureau of Statistics",
    "license": "CC BY 4.0",
    "attribution": "Australian Bureau of Statistics, Socio-Economic Indexes for Areas (SEIFA) 2021",
    "redistribution": "permitted",
    "cadence": "5y",
    "url": f"{BASE}/data/{FLOW}",
    "notes": "IRSAD; SCORE→score, RWAD→national decile, URP→population; SAL-direct, no correspondence.",
}


def _fetch() -> str:
    """Pull the filtered CSV: all SALs . IRSAD . (SCORE+RWAD+URP)."""
    measures = "+".join(MEASURE_FIELD)  # SCORE+RWAD+URP
    with httpx.Client(timeout=180) as client:
        r = client.get(
            f"{BASE}/data/{FLOW}/.{INDEX}.{measures}",
            headers={"Accept": "application/vnd.sdmx.data+csv"},
        )
        r.raise_for_status()
        return r.text


def _parse(text: str) -> list[dict]:
    """CSV → enrichment rows {sal_code, facts, prov}. One row per SAL."""
    by_sal: dict[str, dict] = {}
    src = {"source_id": SOURCE["source_id"], "as_of": SEIFA_AS_OF}
    reader = csv.DictReader(io.StringIO(text))
    suppressed = 0
    for row in reader:
        sal = row["SAL"].strip()
        measure = row["SEIFA_MEASURE"].strip()
        raw = row["OBS_VALUE"].strip()
        field = MEASURE_FIELD.get(measure)
        if field is None:
            continue
        if raw == "":  # ABS-suppressed (excluded area) → honest-partial null
            suppressed += 1
            continue
        rec = by_sal.setdefault(f"SAL{sal}", {"facts": {}, "prov": {}})
        rec["facts"][field] = int(raw)  # score/decile/population are all integers
        rec["prov"][field] = src
    if suppressed:
        print(f"  {suppressed} suppressed observations (excluded SALs) → null", file=sys.stderr)
    return [{"sal_code": k, **v} for k, v in by_sal.items()]


def run() -> tuple[int, int]:
    """Enrich SEIFA into census-seeded rows; return (matched, missed)."""
    rows = _parse(_fetch())
    conn = db.connect()
    try:
        db.ensure_source(conn, SOURCE)
        matched, missed = db.update_facts(conn, rows)
        conn.commit()
    finally:
        conn.close()
    if missed:
        # SALs SEIFA covers but the census spine didn't seed — crosswalk drops,
        # logged not swallowed (§5). Expected near-zero (both are SAL-direct 2021).
        print(f"  {len(missed)} SEIFA SALs had no spine row (e.g. {missed[:5]})", file=sys.stderr)
    return matched, missed and len(missed) or 0


if __name__ == "__main__":
    matched, missed = run()
    print(f"abs_seifa_2021: enriched {matched} suburbs ({missed} unmatched)")
