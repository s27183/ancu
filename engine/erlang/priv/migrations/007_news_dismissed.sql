-- 007_news_dismissed.sql — per-card dismissed-news state (a third slice of the
-- card user-set layer, alongside 004's plan-target overlay and 005's checklist
-- status).
--
-- Source of truth: docs/architecture/kb-update-runbook.md "authoring a news
-- note" + docs/architecture/plan-card-refresh.md (kb_versions provenance).
--
-- WHY. A news note (docs/kb/news/*.md, compiled into artifact["news"]) is
-- matched to a card by intersecting its affected_kb_slugs against the card's
-- accumulated audit_events.kb_versions_jsonb slugs (already-recorded
-- provenance, no new lookup mechanism). Whether the USER has seen/dismissed a
-- given note is a separate question — USER-ATTESTED state, not a computed
-- figure, so it cannot live in content_jsonb (the computed snapshot a
-- refresh/refine recompute overwrites) or in the compiled KB artifact (git is
-- SOT for the note itself, never for a reader's per-card interaction with it).
--
-- WHAT. A card-level sparse map: {"<news_slug>": true}. Only dismissed slugs
-- are present; an absent news_slug reads as "not yet dismissed" — the same
-- seed-default discipline as 005's checklist_status_jsonb. Default '{}' means
-- every existing card reads byte-identically (no backfill, no behaviour
-- change).

ALTER TABLE plan_cards
    ADD COLUMN dismissed_news_jsonb jsonb NOT NULL DEFAULT '{}'::jsonb;
