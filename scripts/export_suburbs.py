#!/usr/bin/env python3
"""Export the suburb reference data to the snapshot the engine loads at boot.

    python3 scripts/export_suburbs.py [dbname]      (default ancu_engine; libpq env: PGHOST)

Writes engine/erlang/priv/suburbs/suburbs.json.gz and suburb_sources.json: each one JSON
array of the table's rows (`row_to_json`, ordered by key), so the engine can insert it
with `jsonb_populate_recordset` in one statement (fh_engine_suburb_snapshot).

reproducible -> P-2 -> the suburb snapshot -> export
  Why a snapshot: the prod engine's App Platform dev database is reachable from the app
  only, so the build adapters (engine/build/suburbs, which write through
  ENGINE_DATABASE_URL) cannot fill it; the data they produced on the dev stack ships
  with the engine instead (behavior 37). Every source is CC BY 4.0 with redistribution
  'permitted' (suburb_sources) — the export refuses any source that is not. Re-run after
  an adapter run to refresh the file; the engine loads it only into an empty table.
"""
from __future__ import annotations

import gzip
import json
import subprocess
import sys
from pathlib import Path

OUT = Path(__file__).resolve().parents[1] / "engine" / "erlang" / "priv" / "suburbs"


def rows(db: str, sql: str) -> list[dict]:
    q = f"select coalesce(json_agg(t), '[]') from ({sql}) t"
    p = subprocess.run(["psql", "-d", db, "-AtX", "-c", q], capture_output=True, text=True)
    if p.returncode != 0:
        sys.exit(f"export_suburbs: psql failed: {p.stderr.strip()}")
    return json.loads(p.stdout)


def main(db: str) -> None:
    sources = rows(db, "select * from suburb_sources order by source_id")
    bad = [s["source_id"] for s in sources if s.get("redistribution") != "permitted"]
    if bad:
        sys.exit(f"export_suburbs: not redistributable: {', '.join(bad)}")
    suburbs = rows(db, "select * from suburbs order by sal_code")
    if not suburbs:
        sys.exit("export_suburbs: suburbs is empty — run the adapters first")
    for s in suburbs:
        s.pop("updated_at", None)          # the loading database stamps its own
    OUT.mkdir(parents=True, exist_ok=True)
    body = json.dumps(suburbs, ensure_ascii=False, separators=(",", ":"), sort_keys=True)
    # mtime=0: the same rows give the same bytes, so a re-export without changes is no diff
    with gzip.GzipFile(OUT / "suburbs.json.gz", "wb", compresslevel=9, mtime=0) as fh:
        fh.write(body.encode())
    (OUT / "suburb_sources.json").write_text(
        json.dumps(sources, ensure_ascii=False, indent=1, sort_keys=True) + "\n")
    size = (OUT / "suburbs.json.gz").stat().st_size
    print(f"suburbs: {len(suburbs)} rows, {size} bytes gz; sources: {len(sources)}")


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "ancu_engine")
