-- 004_plan_target_overlay.sql — the per-journey plan-target overlay (W7b).
--
-- Source of truth: docs/architecture/lifecycle-simulation-model.md §4.3 +
-- fact-model-unification.md ("Per-override storage mapping") + engine-contract.md §10.2.
--
-- WHY. Saving a structural what-if (the simulate COMMIT half — the refine turn) must
-- persist the override INPUTS, not only the recomputed snapshot, or the next refresh
-- sweep (plan-card-refresh.md) recomputes from STALE facts and silently clobbers the
-- saved scenario. `target {price_range, zone, state}` is a PLAN (per-journey, mutable —
-- Decision 1 / scenario S24) fact, so the override lands on the CARD, never the profile:
-- profiles.facts_jsonb is leak-free ONLY while profile:card is 1:1 (today's Wedge-1
-- shape) and would clobber a sibling journey the moment a profile gains a 2nd card.
--
-- WHAT. A card-level store = the canonical `plan.target`, this is fact-model item-4's
-- first storage slice. It is ADDITIVE: the default '{}' means "no override" → the
-- base-turn read uses the profile onboarding unchanged, so every existing card reads
-- byte-identically (no backfill, no behaviour change). A refine writes the FULL
-- effective onboarding here (not a sparse patch — so "a state save STRIPS the pin"
-- needs no patch-deletion semantics); get_card_rerun_context overlays it when non-empty.

ALTER TABLE plan_cards
    ADD COLUMN target_jsonb jsonb NOT NULL DEFAULT '{}'::jsonb;
