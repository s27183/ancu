-- 001_init_shell.sql — FirstHomey web shell: initial identity + view schema.
--
-- Source of truth for this schema: docs/architecture/shell-architecture.md §6
-- (the shell DB table list) + §3 (the two-JWT identity model).
--
-- Scope: the shell's OWN state — identity (users, magic-link tokens, OAuth
-- linkage) and the shell's *view* of engine plan cards (titles, archive, last
-- tab — NOT plan content). NOT in this migration:
--   * subscriptions / charges / usage_records / timnha_requests — commerce +
--     the usage mirror; a later migration (8-S5, docs/architecture/billing.md).
--   * engine tables (profiles, plan_cards, plan_card_events, sessions, suburbs,
--     audit_events) — a DIFFERENT database entirely (engine-contract §9.2). The
--     API is the only contract; there are NO cross-DB foreign keys or joins
--     (§9.3) — engine_plan_card_id below is a bare uuid, not a FK.
--
-- Forward-only. Postgres >= 13 (gen_random_uuid via pgcrypto). Role/locale use
-- text + CHECK rather than ENUM types so the value set can evolve without an
-- ALTER TYPE dance (the 001_init_engine.sql convention).
--
-- NO in-file BEGIN/COMMIT. The boot-time runner (fh_shell_migrations) wraps each
-- file in a single pgo:transaction, so the whole file + its schema_migrations row
-- commit atomically or roll back together.

CREATE EXTENSION IF NOT EXISTS pgcrypto;  -- gen_random_uuid()

-- ─────────────────────────────────────────────────────────────────────────────
-- Identity. One user table, all roles (shell-architecture.md §6). role defaults
-- to 'buyer' on signup; curator/admin are operator-granted, never signup-assignable.
-- locale is a DISPLAY preference (which of the engine's {vi, en} to show) — default
-- 'vi' (the product is VI-first; bilingual-content.md).
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE users (
    user_id     uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    email       text        NOT NULL UNIQUE,
    role        text        NOT NULL DEFAULT 'buyer'
                              CHECK (role IN ('buyer', 'curator', 'admin')),
    extra_roles text[]      NOT NULL DEFAULT '{}',
    locale      text        NOT NULL DEFAULT 'vi'
                              CHECK (locale IN ('vi', 'en')),
    created_at  timestamptz NOT NULL DEFAULT now()
);

-- Resend magic-link issuance + single-use redemption. Only the token HASH is
-- stored (the raw token rides the email link); a redeemed or expired token is
-- dead. email is captured here so a link can create the user on first redemption.
CREATE TABLE magic_tokens (
    token_id    uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    email       text        NOT NULL,
    token_hash  text        NOT NULL UNIQUE,
    expires_at  timestamptz NOT NULL,
    redeemed_at timestamptz,
    created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX magic_tokens_email_idx ON magic_tokens (email);

-- Google OAuth subject <-> user linkage. (provider, subject) is the external
-- identity; one user may link multiple providers.
CREATE TABLE oauth_identities (
    identity_id uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     uuid        NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    provider    text        NOT NULL CHECK (provider IN ('google')),
    subject     text        NOT NULL,
    created_at  timestamptz NOT NULL DEFAULT now(),
    UNIQUE (provider, subject)
);

CREATE INDEX oauth_identities_user_idx ON oauth_identities (user_id);

-- ─────────────────────────────────────────────────────────────────────────────
-- The shell's VIEW of an engine plan card (shell-architecture.md §2/§6). Display
-- state only — title, archive flag, last-opened tab. The canonical plan content
-- lives in engine plan_cards; engine_plan_card_id is the cross-boundary handle
-- (a bare uuid — NO cross-DB FK, engine-contract §9.3).
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE plan_card_views (
    view_id             uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             uuid        NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    engine_plan_card_id uuid        NOT NULL,
    title               text,
    archived            boolean     NOT NULL DEFAULT false,
    last_opened_tab     text,
    created_at          timestamptz NOT NULL DEFAULT now(),
    updated_at          timestamptz NOT NULL DEFAULT now(),
    UNIQUE (user_id, engine_plan_card_id)
);

CREATE INDEX plan_card_views_user_idx ON plan_card_views (user_id);
