# Plan-card refresh — recomputing a saved card against the current system

**Status:** dev primitive landed; production policy deferred (open question below).

## The problem

A plan card is a **computed snapshot**, not a live view. Its base components are filled once, by the base turn at creation, and written to `plan_cards.content_jsonb` (the projection) + `plan_card_events` (the append-only SOT). `PlanProjection` replays that snapshot. So a card drifts from what the current system would produce whenever any of its **three inputs** changes after the fill:

1. **Engine code** — a resolver changes (e.g. Decision 8 added base benefit ranges; VIC wired into `state_catalog`).
2. **The KB/blueprint artifact** — a scheme figure changes (a budget moves the FHG caps; a duty schedule updates) → a new `deploy_commit_sha`.
3. **The household fact base** — the profile is enriched (chat adds citizenship, income, FHSS history) → a richer fill becomes possible.

Restarting the engine reloads (1) and (2) but **does not recompute saved cards**. The East-Melbourne card that surfaced this was filled by the pre-Decision-8 resolver and stayed figure-less after every restart — correctly, because nothing re-ran its base turn.

## The primitive: base-turn re-run

Recompute a card's **base** plan against *today's* code + artifact + profile facts, in place.

- **Same identity.** Same `plan_card_id`, same profile. The turn inputs (`mode`, `intent`, `firb_required_any`, `onboarding`) are **reconstructed** from the card row + its profile (`fh_engine_store:get_card_rerun_context/1`), so the recompute reflects the *current* profile facts, not a frozen copy.
- **Scoped to base components.** The base turn commits only `?BASE_COMPONENTS` (keyed by `component_id` → overwrites those snapshots). **Per-property addenda and conversation are untouched** — they are not base components, so a base re-run never clobbers them.
- **Audit-preserving (constraint #6).** `plan_card_events` is append-only: the re-run appends a *new* turn's events, each stamped with the **current** `deploy_commit_sha` + the fill's `kb_versions`. The old fill's events remain — the regulated trail shows *every* computation and the artifact it ran against. `content_jsonb` updates to the latest projection.
- **Concurrency-safe.** `fh_engine_turn_registry:reserve/2` enforces one in-flight turn per card → a re-run while a turn is running returns **409**, never a double-fill.
- **Live update.** The new turn fans out `turn_started`/`component_filled`/`turn_completed` on the card's `pg` group, so an open `PlanProjection` (subscribed to `…/events`) updates in place.

### Provenance & staleness

The **authoritative per-fill provenance is the event log** (each base-fill event carries its `deploy_commit_sha` + `kb_versions`), not the `plan_cards.deploy_commit_sha` column (which records creation time and is deliberately **not** restamped — events are the SOT, and restamping optimistically before an async turn could lie if the turn fails). The re-run response reports `{previous_deploy_commit_sha (card column), current_deploy_commit_sha (engine)}` as a drift signal. A future staleness sweep reads the **latest base-fill event's** SHA per card and compares to current — re-running only the drifted cards via this same primitive.

## The dev endpoint

`POST /api/engine/plan-cards/:id/rerun`, **gated on `ENGINE_DEV_PROVISION`** (unset → 404, as if absent). Like `POST /dev/tenants`, it **trusts the caller** — it looks the card up by id alone (no tenant filter, no JWT) and recomputes it. That is a recompute-any-card surface and must never be open in production; in dev (single tenant) it is the friction-free way to refresh after a resolver change:

```
curl -X POST http://localhost:8080/api/engine/plan-cards/<plan_card_id>/rerun
```

The recompute itself is correctly tenant-scoped (the turn runs under the card's real `tenant_id`/`user_id` from the row); only the *lookup* skips the tenant filter, the dev concession.

## The refresh sweep — the primary mechanism

Manual per-card re-run is the *primitive*; the *primary* trigger is **coupled to the cause of drift** — a rebuild of the base-plan logic/artifact, or a workflow that mutates what saved cards should contain. Not a human remembering, and not (only) a user opening a card. A **sweep** enumerates the affected cards and re-runs each.

### Resolver-only re-run (so the sweep is free)

A sweep re-runs *what the change affected* — and what changes when you edit a resolver or the KB is the **deterministic** plan. So the sweep uses a **resolver-only re-run**: it re-runs the pure-resolver fills (`buyer_profile`, `eligibility`, `cash_position`, `ownership_planning`) and **skips the two-path component (`mortgage_finance`) entirely** — it does not re-run or re-commit it. The stored `mortgage_plan` is left **exactly as-is** (its agent-authored lender shortlist preserved untouched); the existing outcome is injected into the turn's `outcomes` only so downstream resolver reads stay consistent. **Zero LLM, deterministic, instant.**

This is the *correct scoping*: the agentic leaf's inputs didn't change, so re-running it would be wrong, not just wasteful (reserve the agent for the irreducible). It is also **fail-safe**: re-committing a stored agent leaf would re-validate it against the current outcome gate, and a legacy/non-conforming leaf (e.g. an English-only `reasoning` that predates the bilingual rule) would fail-closed and crash the refresh. Skipping avoids that entirely. The trade-off: a change to `mortgage_finance`'s *resolver figures* (e.g. the capacity formula) is **not** picked up by a resolver-only sweep — that needs a full re-run (the manual endpoint, or a future agent-aware sweep). Documented, not silent.

### Scope — which cards (provenance-driven)

Not every rebuild touches every card. The per-fill provenance makes the sweep **targetable**:
- each fill records `deploy_commit_sha` + the `kb_versions` (the KB slugs it consulted);
- so a sweep can select **exactly** the drifted cards: *build SHA ≠ current* (a code/artifact rebuild), *fills used slug `X`* (one scheme changed), or *blueprint = `Y`* (a blueprint changed). A coarse first cut — "all active base plans" — is correct; the provenance lets it become targeted later **without rework**. A sweep that bounds its scope (top-N, sampled, one-blueprint) must **log what it left out** — silent truncation reads as "refreshed everything" when it didn't.

### Triggers — one primitive, several callers

- **Rebuild/deploy.** Dev: a **boot-sweep** right after the artifact loads (rebuild + restart → cards refresh themselves), gated on the dev flag. Prod: a **deploy-pipeline step** calling an authenticated, throttled admin trigger.
- **Workflow.** Any job that mutates the card basis calls `sweep(scope)` as its final step.
- **Manual.** The dev `…/rerun` endpoint stays, for forcing a single card.

### Safety (inherited from the per-card primitive)

Base-scope only (per-property addenda + conversation untouched); **audit-preserving** (each re-run is a new fill with fresh `deploy_commit_sha` + `kb_versions`; the old fill survives in the append-only events); **one in-flight turn per card** (the registry → a card already running is skipped, not double-filled); **bounded concurrency** so a sweep doesn't stampede the engine or its metering budget. Prod triggers are authenticated + rate-limited — the antithesis of the open dev endpoint.

### Implementation

- **`fh_engine_turn`** gains a resolver-only turn kind (`base_resolver`): walk the base DAG, run the pure-resolver fills, and **skip** each two-path component — leave its stored outcome untouched, inject it (from the card snapshot passed in `existing_outcomes`) into `outcomes` for downstream reads, spawn **no** sidecar.
- **`fh_engine_refresh:sweep/1`** — enumerate active base plans (optionally scoped by SHA/slug/blueprint), re-run each resolver-only, throttled (bounded concurrency, registry-gated), logging skipped/in-flight cards.
- **Dev trigger:** a boot hook (gated on `ENGINE_DEV_PROVISION`) runs `sweep(all)` after the app starts + artifact loads.
- **Prod trigger:** an authenticated admin endpoint + the deploy-step call — deferred to when prod exists; the sweep primitive is the same.
