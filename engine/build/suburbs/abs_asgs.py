"""abs_asgs — SAL centroid (lat/lon) per suburb, the map-placement spine.

Source: ABS ASGS Edition 3 (2021) via the ArcGIS REST service — NOT the SDMX Data
API the census/seifa adapters use. The geography (boundaries, centroids) lives in
ArcGIS feature services, the statistics in the Data API. Centroids are **pre-computed**
by ABS as the SAL_PT layer, so no geometry library is needed (suburb-data-foundation.md
§5: "Point → SAL" is the correspondence mechanism, but the centroid itself is sourced):

    host   https://geo.abs.gov.au/arcgis/rest/services/ASGS2021/SAL/MapServer
    layer  2 = SAL_PT (boundary centroids; layer 0 = full polygons, 1 = generalised)
    query  /2/query?where=1=1&outFields=sal_code_2021,state_code_2021
           &returnGeometry=true&outSR=4326&f=geojson  (WGS84 lon/lat for the map)
    paging maxRecordCount=2000, supportsPagination → resultOffset/resultRecordCount;
           ~15.3k SALs ⇒ 8 pages. orderByFields=sal_code_2021 for stable paging.

This is an ENRICHMENT adapter writing real COLUMNS (centroid_lat/lon), not facts_jsonb
— so it uses `db.update_columns`, UPDATE-only against the census-seeded spine (§4 makes
centroid a column because the map filters/joins on it). sal_code_2021 is digits-only
('10738'); we prefix 'SAL' to match the census spine key (verified Cabramatta SAL10738
→ [150.936, -33.898], Sydney's south-west).

SCOPE (deliberate split along the §6 abs_asgs row's mechanism seam):
  * centroid_lat/lon — THIS adapter (ArcGIS REST, zero new deps). The load-bearing
    map-placement field — 8b–8d cannot place a suburb without it.
  * boundary_jsonb — deferred to 8d (the choropleth is its only consumer; §4 flags it
    "optional, large" — storing ~15k generalised polygons nothing reads yet is bloat).
  * lga_name / is_capital_city — deferred to a dedicated Mesh-Block correspondence
    sub-build (the first real §5 name/area correspondence: MB→SAL ⋈ MB→LGA/GCCSA,
    .xlsx allocation files, modal-aggregated to SAL — a distinct mechanism, not a pull).

Run:  cd engine/build && ENGINE_DATABASE_URL=… ../../.venv/bin/python -m suburbs.abs_asgs
"""
from __future__ import annotations

import sys

import httpx

from . import db

BASE = "https://geo.abs.gov.au/arcgis/rest/services/ASGS2021/SAL/MapServer"
LAYER = 2  # SAL_PT — boundary centroids
PAGE = 2000  # the layer's maxRecordCount
ASGS_AS_OF = "2021-07-01"  # ASGS Edition 3 operative period start

SOURCE = {
    "source_id": "abs_asgs_2021",
    "name": "Australian Statistical Geography Standard (ASGS) Edition 3 2021 — SAL boundaries",
    "publisher": "Australian Bureau of Statistics",
    "license": "CC BY 4.0",
    "attribution": "Australian Bureau of Statistics, Australian Statistical Geography Standard (ASGS) Edition 3, 2021",
    "redistribution": "permitted",
    "cadence": "per-edition",  # ASGS editions are ~5y (Ed.3 = Jul 2021–Jun 2026)
    "url": f"{BASE}/{LAYER}",
    "notes": "SAL_PT centroids (lon/lat, WGS84) → centroid_lat/lon. boundary_jsonb + lga/is_capital deferred (§6).",
}


def _fetch_page(client: httpx.Client, offset: int) -> dict:
    r = client.get(
        f"{BASE}/{LAYER}/query",
        params={
            "where": "1=1",
            "outFields": "sal_code_2021,state_code_2021",
            "returnGeometry": "true",
            "outSR": 4326,  # WGS84 → coordinates are [lon, lat]
            "orderByFields": "sal_code_2021",  # stable paging order
            "resultOffset": offset,
            "resultRecordCount": PAGE,
            "f": "geojson",
        },
    )
    r.raise_for_status()
    return r.json()


def _centroid(geom: dict | None) -> tuple[float, float] | None:
    """GeoJSON point/multipoint → (lon, lat). SAL_PT is MultiPoint; take the first part
    (ABS publishes one representative centroid; multipart is the multi-locality residue)."""
    if not geom:
        return None
    coords = geom.get("coordinates")
    if geom.get("type") == "MultiPoint":
        coords = coords[0] if coords else None
    if not coords or len(coords) < 2:
        return None
    return float(coords[0]), float(coords[1])


def _fetch() -> list[dict]:
    """Page the SAL_PT layer → enrichment rows {sal_code, cols, prov}."""
    src = {"source_id": SOURCE["source_id"], "as_of": ASGS_AS_OF}
    rows, offset, dropped = [], 0, 0
    with httpx.Client(timeout=120) as client:
        while True:
            fc = _fetch_page(client, offset)
            feats = fc.get("features") or []
            if not feats:
                break
            for f in feats:
                code = (f.get("properties") or {}).get("sal_code_2021", "").strip()
                lonlat = _centroid(f.get("geometry"))
                if not code or lonlat is None:
                    dropped += 1
                    continue
                lon, lat = lonlat
                rows.append({
                    "sal_code": f"SAL{code}",  # match the census spine key
                    "cols": {"centroid_lat": lat, "centroid_lon": lon},
                    "prov": {"centroid_lat": src, "centroid_lon": src},
                })
            offset += len(feats)
            if len(feats) < PAGE:
                break
    if dropped:
        print(f"  {dropped} features without a usable code/centroid → skipped", file=sys.stderr)
    return rows


def run() -> tuple[int, int]:
    rows = _fetch()
    conn = db.connect()
    try:
        db.ensure_source(conn, SOURCE)
        matched, missed = db.update_columns(conn, rows)
        conn.commit()
    finally:
        conn.close()
    if missed:
        # SALs with a centroid but no census spine row — crosswalk drops, logged (§5).
        # Expect the same 7 out-of-scope codes the census spine skipped, plus any
        # ASGS-only localities (e.g. 'no usual address' / offshore) not in C21_G08.
        print(f"  {len(missed)} centroids had no spine row (e.g. {missed[:5]})", file=sys.stderr)
    return matched, missed and len(missed) or 0


if __name__ == "__main__":
    matched, missed = run()
    print(f"abs_asgs_2021: centroid on {matched} suburbs ({missed} unmatched)")
