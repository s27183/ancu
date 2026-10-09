-- 009_reference_snapshots.sql — which shipped reference-data snapshot a table last
-- loaded.
--
-- WHY. The engine ships the suburb reference data as a committed snapshot
-- (priv/suburbs/, scripts/export_suburbs.py) and loads it at boot
-- (fh_engine_suburb_snapshot), because the prod engine's App Platform dev database
-- is reachable from the app only. A filled table must still take a NEWER snapshot
-- (behavior 37: SEIFA deciles added after prod was first filled), and must not be
-- rewritten on every boot by the same one. So the loader records the sha256 of the
-- snapshot it loaded here, and loads again only when the shipped one differs.
--
-- WHAT. One row per snapshot name ('suburbs'); global reference bookkeeping, no
-- tenant_id (the same bucket as 003's suburbs).

CREATE TABLE reference_snapshots (
    name      text PRIMARY KEY,                 -- 'suburbs'
    sha256    text NOT NULL,                    -- hex, of the shipped snapshot files
    row_count integer NOT NULL,                 -- rows the load wrote
    loaded_at timestamptz NOT NULL DEFAULT now()
);
