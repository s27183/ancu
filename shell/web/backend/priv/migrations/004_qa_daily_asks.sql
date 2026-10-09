-- 004_qa_daily_asks.sql — FirstHomey web shell: the daily assistant-question cap
-- (behavior 36, Son 2026-10-09: "cap an user's use of assistant to just one call per
-- day").
--
-- One row per (user, Sydney calendar day) counts the questions the shell let through
-- to the engine that day. fh_shell_store:claim_question/2 increments it in ONE
-- statement guarded by the limit (insert-or-increment WHERE n < limit), so two
-- concurrent asks cannot both pass; release_question/2 gives one back when the engine
-- did not start the turn. The day is computed in SQL (Australia/Sydney), never from
-- the Erlang wall clock (erlang-design-checklist §15). Old rows are inert history.
--
-- Conventions carried from 001-003: forward-only; NO in-file BEGIN/COMMIT (the runner
-- wraps the file in one pgo:transaction).

CREATE TABLE qa_daily_asks (
    user_id uuid    NOT NULL REFERENCES users (user_id) ON DELETE CASCADE,
    day     date    NOT NULL,
    n       integer NOT NULL CHECK (n >= 0),
    PRIMARY KEY (user_id, day)
);
