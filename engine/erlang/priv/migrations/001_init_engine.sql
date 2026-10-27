-- 001_init_engine.sql — FirstHomey engine: initial runtime-state schema.
--
-- Source of truth for this schema: docs/architecture/engine-contract.md §9.1
-- (the table list) reconciled with Decision 1 in
-- docs/architecture/fact-model-unification.md (the fact-base ↔ plan split).
--
-- Scope: the engine's RUNTIME state only — the unit of isolation is the plan
-- card (docs/architecture/isolation-model.md). NOT in this migration:
--   * KB + blueprints — git-authored, compiled to an in-memory artifact at
--     deploy (persistent_term); never Postgres tables (engine-contract §9.1).
--   * suburbs / properties — build-time enrichment + optional, narrow-path
--     property data; a later migration (CLAUDE.md "Where to start building" 2-3, 9).
--   * shell tables (identity, commerce, usage mirror) — a different database
--     entirely (engine-contract §9.2); the API is the only contract.
--
-- Forward-only. Postgres ≥ 13 (gen_random_uuid via pgcrypto; IDENTITY columns).
-- Status/intent/mode use text + CHECK rather than ENUM types so the value set
-- can evolve without an ALTER TYPE dance.
--
-- NO in-file BEGIN/COMMIT. The boot-time runner (fh_engine_migrations) wraps each
-- file in a single pgo:transaction, so the whole file + its schema_migrations
-- row commit atomically or roll back together. A stray in-file BEGIN/COMMIT would
-- fight the runner's transaction (pgo uses one pooled connection per transaction).

CREATE EXTENSION IF NOT EXISTS pgcrypto;  -- gen_random_uuid()

-- ─────────────────────────────────────────────────────────────────────────────
-- Tenancy. Per-tenant signing keys + resource-protection quotas (engine-contract
-- §3, §9.1). The engine meters; commerce/identity are shell concerns.
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE tenants (
    tenant_id    uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    name         text        NOT NULL,
    quotas_jsonb jsonb       NOT NULL DEFAULT '{}'::jsonb,  -- resource-protection limits
    created_at   timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE tenant_signing_keys (
    key_id     uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id  uuid        NOT NULL REFERENCES tenants(tenant_id) ON DELETE CASCADE,
    public_key text        NOT NULL,
    algo       text        NOT NULL,                     -- e.g. 'ed25519'
    status     text        NOT NULL DEFAULT 'active'
                           CHECK (status IN ('active', 'retired')),
    created_at timestamptz NOT NULL DEFAULT now(),
    rotated_at timestamptz
);

CREATE INDEX idx_tenant_signing_keys_tenant ON tenant_signing_keys (tenant_id);

-- ─────────────────────────────────────────────────────────────────────────────
-- profiles — the persistent HOUSEHOLD FACT BASE (Decision 1).
--
-- The mode-INDEPENDENT buyer facts: facts_jsonb holds the canonical `profile`
-- shape (applicants[], off_title_parties[], household_financials, traits,
-- derived{ firb_required_any, new_build_only_constraint, ... }, narrative) —
-- see fact-model-unification.md "The unified fact-base schema". One row per
-- household; it ACCUMULATES across journeys and is the lifecycle moat. It is the
-- SOT for *current* facts and outlives every plan card. Mode is NOT stored here
-- (it is derived per plan + per applicant).
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE profiles (
    profile_id  uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id   uuid        NOT NULL REFERENCES tenants(tenant_id) ON DELETE CASCADE,
    user_id     uuid        NOT NULL,            -- owning account; household membership lives inside facts_jsonb
    facts_jsonb jsonb       NOT NULL DEFAULT '{}'::jsonb,
    created_at  timestamptz NOT NULL DEFAULT now(),
    updated_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_profiles_tenant_user ON profiles (tenant_id, user_id);

-- ─────────────────────────────────────────────────────────────────────────────
-- plan_cards — one per PURCHASE JOURNEY (Decision 1), FK → profiles (1..N per
-- household; Wedge 1 populates exactly one). content_jsonb is the base plan +
-- property addenda AND the per-fill snapshot (resolved facts + KB content as of
-- the fill, with deploy_commit_sha) = the reproducible audit trail (architecture
-- §11.9) and the agent's grounding surface (constraint #9).
--
-- `mode` is a DERIVED label (firb_required_any × intent), a denormalised cache
-- for routing/queries — NEVER a partition key (Decision 1). For Wedge 1 (Mode A)
-- it is always 'A'.
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE plan_cards (
    plan_card_id     uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id        uuid        NOT NULL REFERENCES tenants(tenant_id) ON DELETE CASCADE,
    profile_id       uuid        NOT NULL REFERENCES profiles(profile_id) ON DELETE CASCADE,
    blueprint_slug   text        NOT NULL,            -- which mode-specific pipeline, e.g. 'fhb-domestic-au'
    intent           text        NOT NULL DEFAULT 'owner_occupier'
                                 CHECK (intent IN ('owner_occupier', 'investment')),  -- the intent axis of mode
    mode             text        NOT NULL DEFAULT 'A'  -- DERIVED cache (firb_required_any × intent); not a key
                                 CHECK (mode IN ('A', 'B', 'C', 'D')),
    status           text        NOT NULL DEFAULT 'active'
                                 CHECK (status IN ('active', 'archived')),
    deploy_commit_sha text       NOT NULL,            -- deploy that produced the latest fills (audit/reproducibility)
    content_jsonb    jsonb       NOT NULL DEFAULT '{}'::jsonb,
    created_at       timestamptz NOT NULL DEFAULT now(),
    updated_at       timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_plan_cards_profile ON plan_cards (profile_id);
CREATE INDEX idx_plan_cards_tenant  ON plan_cards (tenant_id);

-- ─────────────────────────────────────────────────────────────────────────────
-- plan_card_events — durable typed-event log (engine-contract §4). SOT for
-- Last-Event-ID replay. The contract promises event IDs MONOTONIC per
-- (tenant_id, plan_card_id); a global IDENTITY is monotonic per card a fortiori,
-- and the (tenant_id, plan_card_id, event_id) index serves replay (event_id >
-- last-seen). Append-only.
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE plan_card_events (
    event_id     bigint      GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id    uuid        NOT NULL REFERENCES tenants(tenant_id) ON DELETE CASCADE,
    plan_card_id uuid        NOT NULL REFERENCES plan_cards(plan_card_id) ON DELETE CASCADE,
    type         text        NOT NULL,                -- e.g. 'component_filled', 'turn_completed', 'curator_input_required'
    payload_jsonb jsonb      NOT NULL DEFAULT '{}'::jsonb,
    ts           timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_plan_card_events_replay ON plan_card_events (tenant_id, plan_card_id, event_id);

-- ─────────────────────────────────────────────────────────────────────────────
-- sessions / session_turns — conversation log (engine-contract §9.1,
-- isolation-model §4). session_id is one row per (user_id × plan_card_id).
-- Stores VENDOR-NEUTRAL GLUE only: (turn_id, user_text, assistant_text, ts).
-- NOT reasoning items, NOT pinned file ids (in-turn-transient / vendor-format).
-- For user re-reading + Q&A coherence + audit — NOT agent grounding (#9).
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE sessions (
    session_id   uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id    uuid        NOT NULL REFERENCES tenants(tenant_id) ON DELETE CASCADE,
    user_id      uuid        NOT NULL,
    plan_card_id uuid        NOT NULL REFERENCES plan_cards(plan_card_id) ON DELETE CASCADE,
    created_at   timestamptz NOT NULL DEFAULT now(),
    UNIQUE (user_id, plan_card_id)   -- session_id = user_id × plan_card_id (engine-contract §9.1)
);

CREATE TABLE session_turns (
    turn_id        uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id     uuid        NOT NULL REFERENCES sessions(session_id) ON DELETE CASCADE,
    user_text      text,
    assistant_text text,
    ts             timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_session_turns_session ON session_turns (session_id, ts);

-- ─────────────────────────────────────────────────────────────────────────────
-- audit_events — compliance-pipeline attribution + which KB versions were active
-- per fill (engine-contract §9.1, compliance pipeline §6). NO cost fields
-- (metering lives in the `usage` event stream / shell mirror, never here).
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE audit_events (
    audit_id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id         uuid        NOT NULL REFERENCES tenants(tenant_id) ON DELETE CASCADE,
    plan_card_id      uuid        NOT NULL REFERENCES plan_cards(plan_card_id) ON DELETE CASCADE,
    component_id      text        NOT NULL,            -- which blueprint component filled
    fill_path         text        NOT NULL             -- 'resolver' or 'agent'
                                  CHECK (fill_path IN ('resolver', 'agent')),
    kb_versions_jsonb jsonb       NOT NULL DEFAULT '[]'::jsonb,  -- [{slug, effective_from, last_verified}] active at fill
    compliance_jsonb  jsonb       NOT NULL DEFAULT '{}'::jsonb,  -- compliance-pipeline result/attribution
    deploy_commit_sha text        NOT NULL,
    ts                timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_audit_events_plan_card ON audit_events (plan_card_id, ts);

-- ─────────────────────────────────────────────────────────────────────────────
-- artifacts — content-addressed engine outputs (document reports, Tìm Nhà
-- briefs, decision-trail entries) backing artifact refs (engine-contract §9.1).
-- artifact_id IS the content hash (e.g. 'sha256:…') → identical content dedupes.
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE artifacts (
    artifact_id   text        PRIMARY KEY,             -- content hash, e.g. 'sha256:abc…'
    tenant_id     uuid        NOT NULL REFERENCES tenants(tenant_id) ON DELETE CASCADE,
    kind          text        NOT NULL
                              CHECK (kind IN ('document_report', 'tim_nha_brief', 'decision_trail_entry')),
    content_jsonb jsonb       NOT NULL DEFAULT '{}'::jsonb,
    created_at    timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_artifacts_tenant ON artifacts (tenant_id);
