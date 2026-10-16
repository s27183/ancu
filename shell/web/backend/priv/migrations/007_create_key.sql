-- 007_create_key.sql — FirstHomey web shell: a plan create is made once per tap
-- (behavior 97, Son 2026-10-16: "the planning process is lost if the user's phone has
-- screen lock in the middle … not atomic").
--
-- The onboarding dialog sends a create key with each tap ("Lập kế hoạch") and sends it
-- again when the reply was lost (the phone locked, the tab reloaded). The shell records
-- the key on the view it makes for that create; a repeat with the same key from the same
-- owner returns that view's plan_card_id instead of making a second plan or claiming a
-- second guest create (fh_shell_h_plan_cards). Unique per user only: two users' keys
-- never meet. NULL for every create made before this file and for a client that sends
-- no key — those stay unchecked, as before.
--
-- Way back: DROP INDEX plan_card_views_create_key_idx;
--           ALTER TABLE plan_card_views DROP COLUMN create_key;
--
-- Conventions carried from 001-006: forward-only; NO in-file BEGIN/COMMIT (the runner
-- wraps the file in one pgo:transaction).

ALTER TABLE plan_card_views ADD COLUMN create_key text;

CREATE UNIQUE INDEX plan_card_views_create_key_idx
    ON plan_card_views (user_id, create_key) WHERE create_key IS NOT NULL;
