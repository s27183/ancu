-- 005_checklist_status.sql — the per-phase action checklist status (the second
-- slice of the card user-set layer).
--
-- Source of truth: docs/architecture/lifecycle-simulation-model.md §7 +
-- structure-map.md (Plane 4, "User-attested state lives in the card user-set
-- layer — never in the computed snapshot").
--
-- WHY. The Flow phase sheet (04-ux-model.md §13.4) lets a buyer tick off the
-- per-phase actions authored by the `phase_playbook` component. That status is
-- USER-ATTESTED state, not a computed figure — it cannot live in content_jsonb
-- (the computed snapshot, which a refresh/refine recompute overwrites via
-- snapshot_component) or in profiles.facts_jsonb (a sibling journey would share
-- it the moment a profile gains a 2nd card). It is the card user-set tier — the
-- same tier as the plan-target overlay (004), built the same additive way.
--
-- WHAT. A card-level sparse map: {"<phase>": {"<action_id>": "done"}}. Only
-- ticked actions are present; an absent (phase, action_id) reads as the seed
-- `not_started`. The default '{}' means "nothing ticked" → every existing card
-- reads byte-identically (no backfill, no behaviour change). It is READ as an
-- overlay onto the phase_playbook seed (the client attaches status to the
-- current action list at render; an orphaned key — an action a later recompute
-- dropped — is simply ignored, honest-partial). A toggle is a small jsonb_set
-- patch with no recompute and no `usage`; the audit trail is the
-- `checklist_status_changed` plan_card_events row the PATCH appends.

ALTER TABLE plan_cards
    ADD COLUMN checklist_status_jsonb jsonb NOT NULL DEFAULT '{}'::jsonb;
