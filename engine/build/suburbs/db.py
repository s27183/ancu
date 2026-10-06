"""Shared DB layer for the suburb-data build adapters.

Every adapter (abs_census, abs_seifa, crime, …) performs the *same* write: merge its
own field-subset into `suburbs.facts_jsonb` + `provenance_jsonb` without clobbering
fields another adapter owns. That shared merge-upsert lives here; only fetch+transform
differs per source (suburb-data-foundation.md §6).

The merge is `jsonb || jsonb` (shallow, right-wins) — each adapter owns disjoint keys,
so concatenation composes the full metric set across runs (proven: census + a later
seifa field coexist in one row).

Two adapter roles (a NOT-NULL fact, not a style choice):
  * SPINE adapter — `upsert_facts`, INSERT-or-update. Owns row creation, so it MUST
    carry `name`+`state`. `abs_census_2021` is the spine (it covers all ~15k SALs).
    Postgres evaluates the `name NOT NULL` constraint on the *proposed insert tuple*
    BEFORE the ON CONFLICT arbiter redirects to UPDATE — so an INSERT with NULL name
    raises even when the row already exists. Hence the spine, not enrichment, inserts.
  * ENRICHMENT adapter — `update_facts`, UPDATE-only by `sal_code`. SEIFA / crime /
    VG-price carry no spine; they enrich rows the spine seeded. A row the UPDATE
    doesn't match is a named-suburb→SAL crosswalk miss (§5) — `update_facts` returns
    the matched count so the caller can log the drop (no silent truncation).

Target: the engine runtime PG (ENGINE_DATABASE_URL). The `suburbs` table is GLOBAL —
no tenant_id (the reference-data category, suburb-data-foundation.md §1).
"""
from __future__ import annotations

import os

# Reproducible -> P-2 · The database is the single source of truth -> The suburb adapters -> sync psycopg3 driver
# psycopg3 sync, not asyncpg: the adapters are sequential offline batches, the runtime DB
# tier is Erlang/pgo, and the sidecar never touches Postgres, so nothing here gains from
# async. Concluded (design choice; no probe needed).
import psycopg
from psycopg.types.json import Jsonb


def connect() -> psycopg.Connection:
    dsn = os.environ.get("ENGINE_DATABASE_URL")
    if not dsn:
        raise SystemExit("ENGINE_DATABASE_URL not set (e.g. postgres://engine:…@localhost:5433/firsthomey_engine)")
    return psycopg.connect(dsn)


_UPSERT_FACTS = """
INSERT INTO suburbs (sal_code, name, state, facts_jsonb, provenance_jsonb)
VALUES (%(sal_code)s, %(name)s, %(state)s, %(facts)s, %(prov)s)
ON CONFLICT (sal_code) DO UPDATE SET
    name             = COALESCE(EXCLUDED.name, suburbs.name),
    state            = COALESCE(EXCLUDED.state, suburbs.state),
    facts_jsonb      = suburbs.facts_jsonb || EXCLUDED.facts_jsonb,
    provenance_jsonb = suburbs.provenance_jsonb || EXCLUDED.provenance_jsonb,
    updated_at       = now()
"""


def upsert_facts(conn: psycopg.Connection, rows: list[dict]) -> int:
    """Merge-upsert suburb rows. Each row: {sal_code, name?, state?, facts: dict, prov: dict}."""
    params = [
        {
            "sal_code": r["sal_code"],
            "name": r.get("name"),
            "state": r.get("state"),
            "facts": Jsonb(r.get("facts") or {}),
            "prov": Jsonb(r.get("prov") or {}),
        }
        for r in rows
    ]
    with conn.cursor() as cur:
        cur.executemany(_UPSERT_FACTS, params)
    return len(params)


_UPDATE_FACTS = """
UPDATE suburbs SET
    facts_jsonb      = facts_jsonb || %(facts)s,
    provenance_jsonb = provenance_jsonb || %(prov)s,
    updated_at       = now()
WHERE sal_code = %(sal_code)s
"""


def update_facts(conn: psycopg.Connection, rows: list[dict]) -> tuple[int, list[str]]:
    """Enrichment path: UPDATE-only (no insert), for adapters with no spine (name/state).

    Returns (matched, missed) — `missed` is the sal_codes no row matched, i.e. the
    named-suburb→SAL crosswalk drops (§5) the caller must log, never silently swallow.
    """
    matched, missed = 0, []
    with conn.cursor() as cur:
        for r in rows:
            cur.execute(_UPDATE_FACTS, {
                "sal_code": r["sal_code"],
                "facts": Jsonb(r.get("facts") or {}),
                "prov": Jsonb(r.get("prov") or {}),
            })
            if cur.rowcount:
                matched += 1
            else:
                missed.append(r["sal_code"])
    return matched, missed


# Real columns an enrichment adapter may write (vs facts_jsonb). Whitelisted so the
# dynamic SET below can never take a column name from feed data — suburb-data-foundation
# §4 makes these columns (not jsonb) because the map filters/joins on them.
_COLUMN_WRITABLE = {
    "name", "state", "lga_name", "is_capital_city",
    "centroid_lat", "centroid_lon", "boundary_jsonb",
}
_JSONB_COLUMNS = {"boundary_jsonb"}


def update_columns(conn: psycopg.Connection, rows: list[dict]) -> tuple[int, list[str]]:
    """Enrichment path for real COLUMNS (centroid/lga/is_capital/boundary), not facts_jsonb.

    Each row: {sal_code, cols: {column: value}, prov: {field: src}}. UPDATE-only by
    sal_code (same crosswalk-miss semantics as `update_facts`); provenance still merges
    into provenance_jsonb so a column field's freshness is detectable uniformly (§4).
    Returns (matched, missed) — `missed` is the sal_codes no spine row matched.
    """
    matched, missed = 0, []
    with conn.cursor() as cur:
        for r in rows:
            cols = r.get("cols") or {}
            bad = set(cols) - _COLUMN_WRITABLE
            if bad:
                raise ValueError(f"refusing to write non-whitelisted column(s): {bad}")
            sets = ", ".join(f"{c} = %({c})s" for c in cols)
            params = {
                c: (Jsonb(v) if c in _JSONB_COLUMNS else v) for c, v in cols.items()
            }
            params["sal_code"] = r["sal_code"]
            params["prov"] = Jsonb(r.get("prov") or {})
            cur.execute(
                f"UPDATE suburbs SET {sets}, "
                f"provenance_jsonb = provenance_jsonb || %(prov)s, updated_at = now() "
                f"WHERE sal_code = %(sal_code)s",
                params,
            )
            if cur.rowcount:
                matched += 1
            else:
                missed.append(r["sal_code"])
    return matched, missed


_UPSERT_SOURCE = """
INSERT INTO suburb_sources (source_id, name, publisher, license, attribution,
                            redistribution, cadence, url, notes)
VALUES (%(source_id)s, %(name)s, %(publisher)s, %(license)s, %(attribution)s,
        %(redistribution)s, %(cadence)s, %(url)s, %(notes)s)
ON CONFLICT (source_id) DO UPDATE SET
    name=EXCLUDED.name, publisher=EXCLUDED.publisher, license=EXCLUDED.license,
    attribution=EXCLUDED.attribution, redistribution=EXCLUDED.redistribution,
    cadence=EXCLUDED.cadence, url=EXCLUDED.url, notes=EXCLUDED.notes
"""


def ensure_source(conn: psycopg.Connection, src: dict) -> None:
    """Register/refresh the feed's license row (the §6.1 compliance artifact)."""
    src = {**{"url": None, "notes": None}, **src}
    with conn.cursor() as cur:
        cur.execute(_UPSERT_SOURCE, src)
