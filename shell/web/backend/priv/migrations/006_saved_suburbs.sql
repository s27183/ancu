-- 006_saved_suburbs.sql — FirstHomey web shell: saved suburbs (behavior 84, Son 2026-10-16).
--
-- Until now a "saved" suburb was a suburb with a plan: the map matched the user's plan
-- titles to suburb names. Plans are now made per state on the planner page (behavior
-- 81), so a saved suburb becomes its own record: one row per (user, suburb), written
-- by the heart on the map's suburb sheet (/api/saved-suburbs).
--
-- * name and state are the suburb's display label as the map knew it when saved, so
--   the saved list needs no engine read; sal_code is the key (the engine's suburbs).
-- * users.saved_seeded_at marks the one-time seed from the user's older suburb-titled
--   plans (fh_shell_saved_suburbs:seed/1). NULL = not yet seeded. A sign-in that claims
--   a guest's plans resets it, so those plans' suburbs are seeded too.
-- * A plan's deletion does not touch this table; a user's deletion cascades.
--
-- Way back: DROP TABLE saved_suburbs; ALTER TABLE users DROP COLUMN saved_seeded_at;
--
-- Conventions carried from 001-005: forward-only; NO in-file BEGIN/COMMIT (the runner
-- wraps the file in one pgo:transaction).

CREATE TABLE saved_suburbs (
    user_id  uuid        NOT NULL REFERENCES users (user_id) ON DELETE CASCADE,
    sal_code text        NOT NULL CHECK (sal_code ~ '^SAL[0-9]{5}$'),
    name     text        NOT NULL CHECK (length(name) BETWEEN 1 AND 120),
    state    text        NOT NULL CHECK (state IN ('NSW', 'VIC', 'QLD', 'WA', 'SA', 'TAS', 'ACT', 'NT')),
    saved_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, sal_code)
);

ALTER TABLE users ADD COLUMN saved_seeded_at timestamptz;
