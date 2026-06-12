-- 003_suburbs.sql — FirstHomey engine: the suburb.* reference surface.
--
-- Source of truth for this schema: docs/architecture/suburb-data-foundation.md
-- §4 (the DDL), reconciled with architecture.md §11.10 (strategic scope) and the
-- registry surface in property-model-foundation.md (the suburb.* fields).
--
-- Scope: SHARED REFERENCE DATA — the third bucket, distinct from the two in 001.
-- It is neither compiled STRUCTURE (the KB/blueprint artifact in persistent_term)
-- nor user RUNTIME-STATE (plan cards, events, sessions). It is slowly-changing,
-- tenant-independent geo-socio-economic data that FEEDS planning: ~15k Australian
-- suburbs × N metrics, ingested build-time from gov feeds (ABS Census/SEIFA, state
-- Valuer-General, crime agencies, GTFS, school locations), a rebuildable projection
-- of the gov source. The resolver reads a coarse projection (suburb.*); the shell
-- map reads the raw metrics. See suburb-data-foundation.md §1-§3.
--
-- TWO consequences of the reference-data category, both visible below:
--   * NO tenant_id — these rows are GLOBAL, shared across all tenants, unlike
--     every table in 001 (which is tenant-scoped). A WHERE tenant_id filter would
--     be a category error here (suburb-data-foundation.md §1, §8).
--   * facts_jsonb (not flat metric columns) — the metric set evolves (PropTrack
--     rent in Wedge 1c, growth/yield composites in Wedge 3) with no ALTER, the
--     same reason profiles.facts_jsonb / plan_cards.content_jsonb are jsonb. The
--     join/filter keys (sal_code, state, name, is_capital_city, centroid) ARE
--     columns — the map queries by state, the resolver pulls by sal_code.
--
-- Keyed at ABS Suburb-and-Locality (SAL, ~15k) — the join grain (§5): buyers and
-- schemes think in suburbs; mesh blocks are privacy-suppressed; SA1 has no human
-- name. Census + SEIFA are published at SAL directly (no correspondence).
--
-- Forward-only. text + CHECK over ENUM (value sets evolve). NO in-file
-- BEGIN/COMMIT — the boot runner (fh_engine_migrations) wraps each file in one
-- pgo:transaction. No new extension needed (no uuid keys here — sal_code is the PK).

-- ─────────────────────────────────────────────────────────────────────────────
-- The suburb data. One row per SAL. facts_jsonb carries both the coarse suburb.*
-- surface the resolver projects AND the raw map-facing fields (vietnamese_
-- ancestry_pct, seifa_irsad_score, crime_incidents_per_1000, medians, demographics).
-- provenance_jsonb maps each filled field -> {source_id, as_of} so a stale metric
-- is detectable per field and the CI completeness gate (§11.10) can assert freshness.
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE suburbs (
    sal_code         text PRIMARY KEY,                    -- ABS SAL code, e.g. 'SAL10738'
    name             text NOT NULL,                       -- 'Cabramatta'
    state            text NOT NULL
                     CHECK (state IN ('NSW','VIC','QLD','WA','SA','TAS','ACT','NT')),
    lga_name         text,
    is_capital_city  boolean,
    centroid_lat     double precision,                    -- for map placement
    centroid_lon     double precision,
    facts_jsonb      jsonb NOT NULL DEFAULT '{}'::jsonb,  -- suburb.* surface + raw map fields
    provenance_jsonb jsonb NOT NULL DEFAULT '{}'::jsonb,  -- { field: { source_id, as_of } }
    boundary_jsonb   jsonb,                               -- SAL polygon (GeoJSON) for choropleth; optional, large
    updated_at       timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_suburbs_state ON suburbs (state);
CREATE INDEX idx_suburbs_name  ON suburbs (state, name);

-- ─────────────────────────────────────────────────────────────────────────────
-- The source / license REGISTER — one row per feed. Doubles as the adapter
-- manifest (§6) and the license-compliance artifact (§6.1): the ACARA
-- redistribution constraint is a first-class row here, not a comment. An adapter
-- whose source row is redistribution = 'restricted' must not write a field the
-- shell will publish (NAPLAN/ICSEA are restricted; school_catchment_quality is
-- derived from permitted locations + catchments instead). CC BY 4.0 requires the
-- attribution string to render wherever its layer shows — the map attribution strip.
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE suburb_sources (
    source_id      text PRIMARY KEY,                      -- 'abs_census_2021', 'nsw_vg_psi', 'bocsar'
    name           text NOT NULL,
    publisher      text NOT NULL,
    license        text NOT NULL,                         -- 'CC BY 4.0', 'CC BY 3.0', 'restricted-acara'
    attribution    text NOT NULL,                         -- the exact CC-BY attribution string to render
    redistribution text NOT NULL DEFAULT 'permitted'
                   CHECK (redistribution IN ('permitted','attribution_only','restricted')),
    cadence        text NOT NULL,                         -- '5y','quarterly','weekly','daily','annual','per-event'
    url            text,
    notes          text
);
