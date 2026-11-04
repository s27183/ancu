"""abs_poa — the postcode of each suburb, for the listing sites' suburb links (behavior 150).

Honest-partial -> the suburb data the goal names -> the suburb build -> the postcode adapter
Goal:      Domain and Allhomes find a suburb's for-sale page only by name, state AND
           postcode (/sale/box-hill-vic-3128/; without it, not found — probe 2, 2026-11-04).
           realestate.com.au needs none. So each suburb gets facts_jsonb.postcode, the
           postal area (ABS POA, ASGS Ed. 3) that holds the suburb's centroid.
Invariant: a postcode is stored only as four digits whose first digit fits the suburb's
           state (NSW 2, ACT 02/26/29, VIC 3, QLD 4, SA 5, WA 6, TAS 7, NT 08) or that is
           one of the state's cross-border codes (CROSS_BORDER); anything else the
           service returns is dropped, counted, and any older stored value removed —
           so a missing postcode means "REA only", never a wrong link. Its provenance
           names the source and the method (the centroid's postal area).
Capability: one point query per suburb centroid against
               https://geo.abs.gov.au/arcgis/rest/services/ASGS2021/POA/MapServer/0/query
           (measured 2026-11-04: Box Hill (Vic.) → 3128, Richmond (Vic.) → 3121, ~0.2 s a
           query; the generalised polygon layer is 140 MB for 2,000 of 2,644 areas, so
           points, not polygons). Four workers; each answer cached in
           engine/build/suburbs/data/.poa_cache.json (gitignored), so a rerun resumes.
           A suburb near a state border can sit in the neighbour state's postal area
           (Albury/Wodonga); those are the cross-border drops the run reports.

Run:    cd engine/build && ENGINE_DATABASE_URL=… ../../.venv/bin/python -m suburbs.abs_poa
Check:  … -m suburbs.abs_poa --check   (Expect 2: the stored postcodes against the rule,
        and a fixture of hostile values that must all be dropped)
"""
from __future__ import annotations

import json
import pathlib
import sys
import threading
import time
from concurrent.futures import ThreadPoolExecutor

import httpx

from . import db

BASE = "https://geo.abs.gov.au/arcgis/rest/services/ASGS2021/POA/MapServer"
LAYER = 0
ASGS_AS_OF = "2021-07-01"
CACHE = pathlib.Path(__file__).resolve().parent / "data" / ".poa_cache.json"
WORKERS = 4
MIN_STORED = 15_320  # Expect 2: at least this many suburbs carry a postcode

SOURCE = {
    "source_id": "abs_asgs_2021_poa",
    "name": "Australian Statistical Geography Standard (ASGS) Edition 3 2021 — Postal Areas",
    "publisher": "Australian Bureau of Statistics",
    "license": "CC BY 4.0",
    "attribution": "Australian Bureau of Statistics, Australian Statistical Geography Standard (ASGS) Edition 3, 2021 — Postal Areas",
    "redistribution": "permitted",
    "cadence": "per-edition",
    "url": f"{BASE}/{LAYER}",
    "notes": "facts_jsonb.postcode = the postal area (POA) holding the suburb's SAL centroid; used to build Domain/Allhomes suburb links (behavior 150).",
}
PROV = {"source_id": SOURCE["source_id"], "as_of": ASGS_AS_OF, "method": "postal area of the suburb centroid"}

# First digits a state's postcodes start with (Australia Post's ranges, street postcodes).
STATE_PREFIXES = {
    "NSW": ("2",),
    "ACT": ("02", "26", "29"),
    "VIC": ("3",),
    "QLD": ("4",),
    "SA": ("5",),
    "WA": ("6",),
    "TAS": ("7",),
    "NT": ("08",),
}


# Australia Post's cross-border codes: towns whose postcode comes from the neighbouring
# state's range (measured 2026-11-04, behavior 150 probe 11 — the 39 the digit rule dropped:
# Barooga NSW 3644, Mungindi (Qld) 2406, the APY/Ngaanyatjarra lands 0872, Alpurrurulam NT
# 4825 among them). Fixed per state; a code outside its own state's list is still dropped.
CROSS_BORDER = {
    "NSW": {"3644", "3691", "3707", *(str(c) for c in range(4375, 4386))},
    "QLD": {"2406"},
    "SA": {"0872"},
    "WA": {"0872"},
    "NT": {"4825"},
}


def valid_postcode(state: str, code: object) -> bool:
    """Four ASCII digits whose start fits the state, or one of that state's cross-border
    codes; nothing else is ever stored."""
    if not isinstance(code, str) or len(code) != 4 or not all("0" <= c <= "9" for c in code):
        return False
    return code.startswith(STATE_PREFIXES.get(state, ())) or code in CROSS_BORDER.get(state, ())


def _query(client: httpx.Client, lon: float, lat: float) -> list[str]:
    for attempt in range(4):
        try:
            r = client.get(f"{BASE}/{LAYER}/query", params={
                "geometry": f"{lon},{lat}",
                "geometryType": "esriGeometryPoint",
                "inSR": 4326,
                "spatialRel": "esriSpatialRelIntersects",
                "outFields": "poa_code_2021",
                "returnGeometry": "false",
                "f": "json",
            })
            r.raise_for_status()
            body = r.json()
            if "error" in body:
                raise RuntimeError(body["error"])
            return [str((f.get("attributes") or {}).get("poa_code_2021") or "") for f in body.get("features") or []]
        except (httpx.HTTPError, RuntimeError, ValueError):
            if attempt == 3:
                raise
            time.sleep(2 ** attempt)
    return []


def _load_cache() -> dict[str, list[str]]:
    try:
        return json.loads(CACHE.read_text())
    except (OSError, ValueError):
        return {}


def _fetch(suburbs: list[tuple[str, str, float, float]]) -> dict[str, list[str]]:
    cache = _load_cache()
    todo = [s for s in suburbs if s[0] not in cache]
    lock = threading.Lock()
    done = 0

    def one(client: httpx.Client, s: tuple[str, str, float, float]) -> None:
        nonlocal done
        codes = _query(client, s[3], s[2])
        with lock:
            cache[s[0]] = codes
            done += 1
            if done % 500 == 0:
                CACHE.write_text(json.dumps(cache))
                print(f"  {done}/{len(todo)} queried", file=sys.stderr)

    with httpx.Client(timeout=30) as client, ThreadPoolExecutor(WORKERS) as ex:
        for f in [ex.submit(one, client, s) for s in todo]:
            f.result()
    CACHE.parent.mkdir(parents=True, exist_ok=True)
    CACHE.write_text(json.dumps(cache))
    return cache


def run() -> dict[str, int]:
    conn = db.connect()
    try:
        with conn.cursor() as cur:
            cur.execute("SELECT sal_code, state, centroid_lat, centroid_lon FROM suburbs WHERE centroid_lat IS NOT NULL")
            suburbs = [(r[0], r[1], float(r[2]), float(r[3])) for r in cur.fetchall()]
        answers = _fetch(suburbs)
        counts = {"stored": 0, "no_area": 0, "cross_border": 0, "malformed": 0, "removed": 0}
        db.ensure_source(conn, SOURCE)
        with conn.cursor() as cur:
            for sal, state, _lat, _lon in suburbs:
                codes = answers.get(sal) or []
                code = codes[0] if len(codes) == 1 else None
                if code is not None and valid_postcode(state, code):
                    cur.execute(
                        "UPDATE suburbs SET facts_jsonb = facts_jsonb || %(f)s, provenance_jsonb = provenance_jsonb || %(p)s,"
                        " updated_at = now() WHERE sal_code = %(s)s",
                        {"f": db.Jsonb({"postcode": code}), "p": db.Jsonb({"postcode": PROV}), "s": sal},
                    )
                    counts["stored"] += 1
                    continue
                if not codes:
                    counts["no_area"] += 1
                elif code is not None and len(code) == 4 and code.isdigit():
                    counts["cross_border"] += 1
                else:
                    counts["malformed"] += 1
                cur.execute(
                    "UPDATE suburbs SET facts_jsonb = facts_jsonb - 'postcode', provenance_jsonb = provenance_jsonb - 'postcode',"
                    " updated_at = now() WHERE sal_code = %(s)s AND facts_jsonb ? 'postcode'",
                    {"s": sal},
                )
                counts["removed"] += cur.rowcount
        conn.commit()
    finally:
        conn.close()
    return counts


# Values the service could return that must never be stored (Expect 2's fixture).
HOSTILE = [
    ("VIC", ""), ("VIC", "312"), ("VIC", "31280"), ("VIC", "3l28"), ("VIC", "2128"),
    ("NSW", "3128"), ("ACT", "2000"), ("NT", "0200"), ("TAS", "6000"), ("QLD", " 400"),
    ("WA", "６０００"), ("SA", "5OOO"), ("VIC", None), ("VIC", 3128), ("XX", "3128"),
    ("VIC", "3128\n"), ("NSW", "2000; DROP TABLE suburbs"), ("NT", "0900"),
    # cross-border codes on a state not listed for them
    ("VIC", "0872"), ("TAS", "3644"), ("NT", "2406"), ("QLD", "4825\u0000"),
]


def check() -> int:
    bad_fixture = [v for v in HOSTILE if valid_postcode(*v)]
    conn = db.connect()
    try:
        with conn.cursor() as cur:
            cur.execute("SELECT sal_code, state, facts_jsonb->'postcode', provenance_jsonb->'postcode' FROM suburbs")
            rows = cur.fetchall()
    finally:
        conn.close()
    stored = [(s, st, pc, pv) for s, st, pc, pv in rows if pc is not None]
    wrong = [(s, st, pc) for s, st, pc, _ in stored if not valid_postcode(st, pc)]
    no_prov = [s for s, _st, _pc, pv in stored if not pv or pv.get("source_id") != SOURCE["source_id"]]
    print(f"suburbs {len(rows)}, with postcode {len(stored)} (need ≥{MIN_STORED}); "
          f"failing the state rule {len(wrong)}; without provenance {len(no_prov)}; "
          f"hostile fixture accepted {len(bad_fixture)}/{len(HOSTILE)}")
    for w in wrong[:10]:
        print("  wrong:", w)
    for b in bad_fixture:
        print("  fixture accepted:", b)
    ok = len(stored) >= MIN_STORED and not wrong and not no_prov and not bad_fixture
    print("PASS" if ok else "FAIL")
    return 0 if ok else 1


if __name__ == "__main__":
    if "--check" in sys.argv[1:]:
        raise SystemExit(check())
    c = run()
    print(f"abs_asgs_2021_poa: postcode on {c['stored']} suburbs; dropped {c['no_area']} with no postal area, "
          f"{c['cross_border']} in another state's area, {c['malformed']} malformed; removed {c['removed']} older values")
