-- 002_commerce.sql — FirstHomey web shell: commerce + usage-mirror schema.
--
-- Source of truth for this schema: docs/architecture/billing.md §10 (the shell
-- commerce table list), itself the shell-side companion to engine-contract.md §8
-- (commerce is out of scope for the engine). Billing is SHELL-OWNED: the engine
-- emits `usage` (tokens, no cost, no debit) and never gates on money — constraint
-- #11 (engine meters, shell gates) + principles.md Principle 5. This migration
-- lays the tables that 8-S5b–f fill:
--   * subscriptions — tier + Stripe lifecycle + the current billing period.
--   * usage_records — the pull-model outbox mirror (one idempotent row per engine
--     `usage` event); the period token meter is Σ(tokens_total) over this table.
--   * charges      — one-time add-ons (doc review / Tìm Nhà / success fee), §9.
--
-- The reshape from ATP (billing.md §3): pay-as-you-go → subscription. So there is
-- NO debit ledger (ATP's credit_balances/credit_transactions); the meter is an
-- AGGREGATE over usage_records windowed to [current_period_start, current_period_end),
-- and the shell gates a new agent turn when that sum crosses the tier limit (§7).
--
-- Cross-boundary handles (plan_card_id, turn_id, engine_event_id) are BARE values
-- from the engine DB — NO cross-DB foreign keys or joins (engine-contract §9.3).
-- The only FK targets here are this DB's own users(user_id).
--
-- Two groundings against the live schema (over billing.md §10's illustrative form):
--   * FK target is users(user_id) — the actual PK in 001_init_shell.sql (§10 wrote
--     "users.id"; the live column is user_id).
--   * surrogate PKs follow 001's <entity>_id convention (subscription_id / …),
--     not the doc's bare `id`.
--
-- Conventions carried from 001: text + CHECK over ENUM (value set evolves without
-- ALTER TYPE); forward-only; NO in-file BEGIN/COMMIT (the runner wraps the file in
-- one pgo:transaction — the whole file + its schema_migrations row commit together).
--
-- Cursor model (resolved at 8-S5b, grounded in the live engine + the aleap pattern):
-- NO separate cursor table. usage_records.engine_event_id is the engine's
-- plan_card_events.event_id (a `bigint GENERATED ALWAYS AS IDENTITY`, globally
-- monotonic), serving BOTH as the idempotency key (UNIQUE → ON CONFLICT DO NOTHING)
-- AND as the cursor source: the consumer bootstraps its high-water mark from
-- MAX(engine_event_id) (0 on a fresh DB). It is therefore bigint, NOT text — §10's
-- illustrative `text` predates grounding the live event_id type, and MAX(text) orders
-- lexicographically ("9" > "10"), which would break the cursor.

CREATE EXTENSION IF NOT EXISTS pgcrypto;  -- gen_random_uuid() (already present from 001)

-- ─────────────────────────────────────────────────────────────────────────────
-- Subscriptions. One row per user (UNIQUE user_id) — billing.md §9 upserts by
-- user_id on the Stripe webhook. Absence of a row = the free tier (the §7 gate
-- defaults to free); a free user need not have a Stripe subscription, so
-- stripe_subscription_id is nullable. tier gates feature access + the token quota
-- (§5); status drives whether the subscription is honoured. The current period
-- window is the meter's accounting boundary (§6).
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE subscriptions (
    subscription_id        uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id                uuid        NOT NULL UNIQUE
                                         REFERENCES users(user_id) ON DELETE CASCADE,
    tier                   text        NOT NULL DEFAULT 'free'
                                         CHECK (tier IN ('free', 'plus', 'pro')),
    stripe_subscription_id text,
    status                 text        NOT NULL DEFAULT 'active'
                                         CHECK (status IN ('active', 'past_due', 'canceled')),
    current_period_start   timestamptz,
    current_period_end     timestamptz,
    updated_at             timestamptz NOT NULL DEFAULT now()
);

-- ─────────────────────────────────────────────────────────────────────────────
-- Usage records — the pull-model outbox mirror (billing.md §2/§6). The consumer
-- (fh_shell_usage_consumer, 8-S5b) tails the engine's `usage` events by cursor and
-- writes ONE row each, idempotently: engine_event_id is the engine's monotonic
-- event id, UNIQUE so a replayed event is `ON CONFLICT DO NOTHING` (no double
-- count). tokens_total is the metered quantity; shadow_cost is the §4 Opus-rate
-- valuation (dashboard / margin only — the enforced quota is tokens, not dollars).
-- billed = false for admin-bypass rows (attribution without charge, §9).
-- plan_card_id / turn_id are bare engine handles (§9.3).
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE usage_records (
    usage_record_id       uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id               uuid        NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    engine_event_id       bigint      NOT NULL UNIQUE,   -- idempotency key + cursor source
    plan_card_id          uuid,
    turn_id               uuid,
    source                text,
    model                 text,
    input_tokens          integer     NOT NULL DEFAULT 0,
    output_tokens         integer     NOT NULL DEFAULT 0,
    cache_read_tokens     integer     NOT NULL DEFAULT 0,
    cache_creation_tokens integer     NOT NULL DEFAULT 0,
    tokens_total          integer     NOT NULL DEFAULT 0,  -- the metered quantity
    shadow_cost           numeric(12,6) NOT NULL DEFAULT 0,
    billed                boolean     NOT NULL DEFAULT true,
    created_at            timestamptz NOT NULL DEFAULT now()
);

-- The §6 period meter: Σ(tokens_total) WHERE user_id=$1 AND created_at >= period_start.
CREATE INDEX usage_records_user_created_idx ON usage_records (user_id, created_at);

-- ─────────────────────────────────────────────────────────────────────────────
-- Charges — one-time add-ons (billing.md §9), orthogonal to the tier subscription.
-- stripe_payment_intent_id nullable (e.g. a ledger-only REA success fee). plan_card_id
-- is the optional context (e.g. the addendum reviewed) — a bare engine handle (§9.3).
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE charges (
    charge_id                uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id                  uuid        NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    kind                     text        NOT NULL
                                           CHECK (kind IN ('doc_review', 'timnha', 'success_fee')),
    amount                   numeric(12,2) NOT NULL,
    stripe_payment_intent_id text,
    plan_card_id             uuid,
    created_at               timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX charges_user_idx ON charges (user_id);
