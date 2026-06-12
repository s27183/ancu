"""abs_census_2021 — Vietnamese ancestry % per SAL (the killer layer).

Source: ABS Census 2021, table G08 (Ancestry), published at SAL **directly** — no
correspondence needed (suburb-data-foundation.md §5). Contract verified live
(Cabramatta SAL10738 → 37.82%, matching ABS QuickStats):

    host  https://data.api.abs.gov.au/rest        (the api.data.abs.gov.au host 301-moved here)
    flow  C21_G08_SAL
    key   ANCP . BPPP . REGION . REGION_TYPE . STATE
          ANCP 5107 = Vietnamese, _T = Total persons; BPPP _T = all parents;
          REGION_TYPE = SAL; STATE numeric (1=NSW … 8=ACT). One call per state.
    pct   persons(5107) / persons(_T) * 100

This writes the RAW metric `vietnamese_ancestry_pct` into facts_jsonb (the map's
heatmap reads the gradient — §2). It deliberately does NOT write the coarse band
`vietnamese_community_proximity`: that is a resolver-side projection from a KB
threshold at the <from_suburb> lookup (§1 interpretation-threshold-is-KB, §2
two-readers). See the §6 seam note.

Run:  cd engine/build && ENGINE_DATABASE_URL=… ../../.venv/bin/python -m suburbs.abs_census
"""
from __future__ import annotations

import sys

import httpx

from . import db

BASE = "https://data.api.abs.gov.au/rest"
FLOW = "C21_G08_SAL"
ANCP_VIET = "5107"
ANCP_TOTAL = "_T"
CENSUS_AS_OF = "2021-08-10"  # Census night

# ABS CL_STATE numeric → our two-letter (the suburbs.state CHECK domain). Code 9
# (Other Territories: Jervis Bay, Christmas/Cocos/Norfolk Is.) is outside that
# domain AND out of Wedge-1a scope — skipped explicitly, never silently (see run()).
STATE_CODE = {
    "1": "NSW", "2": "VIC", "3": "QLD", "4": "SA",
    "5": "WA", "6": "TAS", "7": "NT", "8": "ACT",
}

SOURCE = {
    "source_id": "abs_census_2021",
    "name": "Census of Population and Housing 2021 — G08 Ancestry",
    "publisher": "Australian Bureau of Statistics",
    "license": "CC BY 4.0",
    "attribution": "Australian Bureau of Statistics, Census of Population and Housing 2021",
    "redistribution": "permitted",
    "cadence": "5y",
    "url": f"{BASE}/data/{FLOW}",
    "notes": "ANCP=5107 Vietnamese / _T Total persons, BPPP=_T; SAL-direct, no correspondence.",
}


def _is_sal(region_id: str) -> bool:
    """A real SAL code is 5-digit numeric; excludes state ('1') / national ('AUS') aggregates."""
    return region_id.isdigit() and len(region_id) >= 5


def _fetch_state(client: httpx.Client, state: str) -> dict[str, dict]:
    """Return {sal_id: {'name', 'viet', 'total'}} for one state's SALs."""
    key = f"{ANCP_VIET}+{ANCP_TOTAL}.{ANCP_TOTAL}..SAL.{state}"
    r = client.get(
        f"{BASE}/data/{FLOW}/{key}",
        params={"dimensionAtObservation": "AllDimensions"},
        headers={"Accept": "application/vnd.sdmx.data+json"},
    )
    r.raise_for_status()
    d = r.json()["data"]
    struct = (d.get("structures") or [d["structure"]])[0]
    dims = struct["dimensions"]["observation"]
    pos = {dim["id"]: i for i, dim in enumerate(dims)}
    vals = {dim["id"]: dim["values"] for dim in dims}

    out: dict[str, dict] = {}
    dropped = 0
    for okey, ov in d["dataSets"][0]["observations"].items():
        idx = [int(x) for x in okey.split(":")]
        region = vals["REGION"][idx[pos["REGION"]]]
        if not _is_sal(region["id"]):
            dropped += 1
            continue
        ancp = vals["ANCP"][idx[pos["ANCP"]]]["id"]
        v = ov[0]
        if v is None:
            continue
        rec = out.setdefault(region["id"], {"name": region["name"], "viet": 0, "total": 0})
        if ancp == ANCP_VIET:
            rec["viet"] = int(v)
        elif ancp == ANCP_TOTAL:
            rec["total"] = int(v)
    if dropped:
        print(f"  [{state}] dropped {dropped} non-SAL aggregate observations", file=sys.stderr)
    return out


def _pct(viet: int, total: int) -> float | None:
    return round(100 * viet / total, 2) if total else None


def run() -> int:
    """Ingest all in-scope states; return rows upserted."""
    rows: list[dict] = []
    with httpx.Client(timeout=120) as client:
        for code, abbr in STATE_CODE.items():
            data = _fetch_state(client, code)
            for sal_id, rec in data.items():
                pct = _pct(rec["viet"], rec["total"])
                facts, prov = {}, {}
                src = {"source_id": SOURCE["source_id"], "as_of": CENSUS_AS_OF}
                # Total persons is the pct's own denominator: store it so the pct is
                # self-auditing AND the resolver's band projection can floor on
                # population (small-n SALs swing the pct — §8). Core census demographic.
                if rec["total"]:
                    facts["census_total_persons"] = rec["total"]
                    prov["census_total_persons"] = src
                if pct is not None:
                    facts["vietnamese_ancestry_pct"] = pct
                    prov["vietnamese_ancestry_pct"] = src
                rows.append({
                    "sal_code": f"SAL{sal_id}",
                    "name": rec["name"],
                    "state": abbr,
                    "facts": facts,
                    "prov": prov,
                })
            print(f"  [{abbr}] {len(data)} SALs")
    print("Other Territories (state 9) excluded — outside the suburbs.state CHECK domain + Wedge-1a scope")

    conn = db.connect()
    try:
        db.ensure_source(conn, SOURCE)
        n = db.upsert_facts(conn, rows)
        conn.commit()
    finally:
        conn.close()
    return n


if __name__ == "__main__":
    n = run()
    print(f"abs_census_2021: upserted {n} suburbs")
