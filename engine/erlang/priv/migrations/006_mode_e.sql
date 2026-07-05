-- 006_mode_e.sql
-- Widen plan_cards.mode to admit 'E' (mode-e-wedge.md).
--
-- 001's inline CHECK (mode IN ('A', 'B', 'C', 'D')) anticipated the four modes known at
-- the time it was authored. Mode E (domestic next-home owner-occupier, surfaced
-- 2026-07-04) is a later, unplanned fifth cell — fh_engine_h_plan_cards:blueprint_for/3
-- (mode-e-wedge.md P5) now derives mode = 'E' for domestic + owner_occupier + next_home,
-- but nothing had widened this constraint to admit it: a real Mode-E onboarding submission
-- fails the plan_cards INSERT with plan_cards_mode_check, discovered only by
-- mode_e_seam_smoke.escript's live HTTP walk (below-the-seam escripts never touch
-- Postgres, so none of them could have caught this).
--
-- The runner is forward-only with a checksum guard (fh_engine_migrations): 001 is
-- locked, so this is a new migration, not an edit. No in-file BEGIN/COMMIT — the runner
-- owns the per-file transaction.

ALTER TABLE plan_cards
    DROP CONSTRAINT plan_cards_mode_check,
    ADD  CONSTRAINT plan_cards_mode_check
         CHECK (mode IN ('A', 'B', 'C', 'D', 'E'));
