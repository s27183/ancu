-- 002_audit_fill_path_two_path.sql
-- Widen audit_events.fill_path to the real runtime domain.
--
-- 001's inline CHECK allowed only {resolver, agent}. The two-path fill
-- (mortgage-finance-two-path.md, slice 2f) added a third commit path — the resolver
-- computes the figures, then a disposable sidecar fills only the agent leaves — so the
-- turn now commits components with fill_path ∈ {resolver, two_path, agent}. The 2b-4c
-- compliance-pipeline audit writer (fh_engine_store:append_audit) stamps that same
-- fill_path onto every audit row, so leaving the constraint at {resolver, agent} would
-- reject every two-path component's audit row (mortgage_finance) and fail the turn.
--
-- The runner is forward-only with a checksum guard (fh_engine_migrations): 001 is
-- locked, so this is a new migration, not an edit. No in-file BEGIN/COMMIT — the runner
-- owns the per-file transaction.

ALTER TABLE audit_events
    DROP CONSTRAINT audit_events_fill_path_check,
    ADD  CONSTRAINT audit_events_fill_path_check
         CHECK (fill_path IN ('resolver', 'two_path', 'agent'));
