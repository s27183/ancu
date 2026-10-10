-- 005_guest_plans.sql — FirstHomey web shell: guest plans (behavior 45, Son 2026-10-10).
--
-- A visitor who is not signed in builds a full plan. The shell makes them a real
-- users row (guest = true, no email) on their first signed-out create and carries it
-- in the same fh_session cookie with the role "guest", so creation, ownership
-- (plan_card_views) and metering (usage_records) run unchanged. Signing in claims the
-- guest: its rows are re-pointed to the real user and the guest row is deleted. An
-- unclaimed guest is purged 7 days after it was made (fh_shell_guest_purge).
--
-- * users.email becomes nullable; a row without an email must be a guest.
-- * usage_records keeps a purged guest's spend: its user_id becomes nullable and the
--   FK sets NULL on delete instead of cascading, so the cost of every plan built stays
--   on the books (P-5 metering) after the guest that made it is gone. The §6 meter sums
--   by user_id, so an orphaned row counts against no one.
-- * guest_daily_creates counts signed-out creates per Sydney day, per guest and per
--   client address (X-Forwarded-For's first entry), for the 3-a-day cap.
--
-- Way back (only while no guest rows exist): DROP TABLE guest_daily_creates;
-- ALTER TABLE users DROP CONSTRAINT users_email_or_guest, DROP COLUMN guest,
-- ALTER COLUMN email SET NOT NULL; restore usage_records' NOT NULL + CASCADE FK.
--
-- Conventions carried from 001-004: forward-only; NO in-file BEGIN/COMMIT (the runner
-- wraps the file in one pgo:transaction).

ALTER TABLE users
    ALTER COLUMN email DROP NOT NULL,
    ADD COLUMN guest boolean NOT NULL DEFAULT false,
    ADD CONSTRAINT users_email_or_guest CHECK (guest OR email IS NOT NULL);

-- The purge's scan: unclaimed guests by age.
CREATE INDEX users_guest_created_idx ON users (created_at) WHERE guest;

ALTER TABLE usage_records
    ALTER COLUMN user_id DROP NOT NULL,
    DROP CONSTRAINT usage_records_user_id_fkey,
    ADD CONSTRAINT usage_records_user_id_fkey
        FOREIGN KEY (user_id) REFERENCES users (user_id) ON DELETE SET NULL;

CREATE TABLE guest_daily_creates (
    kind text    NOT NULL CHECK (kind IN ('guest', 'addr')),
    key  text    NOT NULL,
    day  date    NOT NULL,
    n    integer NOT NULL CHECK (n >= 0),
    PRIMARY KEY (kind, key, day)
);
