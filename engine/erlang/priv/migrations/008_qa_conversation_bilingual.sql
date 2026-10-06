-- 008_qa_conversation_bilingual.sql — session_turns carries both locales, so the
-- Q&A conversation-read endpoint (fh_engine_h_conversation, GET .../conversation)
-- can hand the shell a real bilingual history instead of the EN-only internal
-- coherence glue (fh_engine_store:read_glue/3, unchanged, still EN-only — its
-- purpose stays pronoun-resolution glue for the agent prompt, not display).
--
-- WHY. bilingual-content.md: VI is co-equal by design, forced by schema at the
-- source. assistant_text (EN-only) was fine while session_turns had no reader
-- outside the engine process; a shell-facing history endpoint showing only
-- English to a VI-reading user would violate that rule. The full bilingual
-- answer already exists per turn (fh_engine_turn:emit_answer emits both
-- text_delta{lang} frames) — this just persists what commit_qa already has in
-- hand (`Answer`) instead of dropping the vi half.
--
-- Pre-deploy (no live rows to migrate): a straight rename + add, not a backfill.

ALTER TABLE session_turns RENAME COLUMN assistant_text TO assistant_text_en;
ALTER TABLE session_turns ADD COLUMN assistant_text_vi text;
