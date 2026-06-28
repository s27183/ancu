# FirstHomey Engine Contract

This document defines the public contract of the FirstHomey **planning engine** — the Erlang/OTP application plus its Python sidecars — for consumption by one or more user-facing shells. The engine runs the agentic planning workload (load blueprint + KB + plan-card state → reason → fill components → persist). A shell is any frontend+backend that provides UI/UX, user identity, commerce, and display-layer concerns on top of the engine.

Companion references: [`principles.md`](principles.md) (the six architecture principles this contract applies), [`erlang-design-checklist.md`](erlang-design-checklist.md) (OTP patterns for the engine), [`architecture.md`](architecture.md) (the three-layer model this engine implements), [`agentic-boundary.md`](agentic-boundary.md) (the resolver/agent decision rule), [`agentic-flow.md`](agentic-flow.md) (the agent types, prompt structure, vendor layer, and context management that run inside this contract), [`isolation-model.md`](isolation-model.md) (what `plan_card_id` / `turn_id` isolate, the per-card serialization invariant, and engine-owned conversation persistence), and [`lifecycle-simulation-model.md`](lifecycle-simulation-model.md) (the two-spines + simulation model whose engine seam §10 fixes). The shell-engine pattern is adapted from the ATP project; the boundary discipline is identical, the domain is not.

## 1. Invariant

**The engine exposes planning primitives. The engine does not expose UX views.**

Forcing function: if two different shells (web app, browser extension, Tìm Nhà curator console) would reasonably render the same plan-card data differently, that data is shell-owned and the engine must not shape it. The engine emits typed component outcomes + a renderer name; projection to pixels is the shell's job.

| Engine owns (agentic) | Shell owns (UX / commerce) |
|---|---|
| Running the planning turn — deterministic resolver fills + agent reasoning (architecture §11.9, two fill paths) | Onboarding UX (mode/state/price-range/zone capture) |
| Streaming typed events | Rendering the plan card (`summary-card`, `swimlane-diagram`, …) |
| Persisting plan-card state needed to resume (SOT) | The suburb-intelligence map + overlays |
| Resolving the blueprint + KB anchors for a turn | Document upload UX, blob storage |
| Compliance gate (FIRB branch, ASIC decision-support boundary, AML) | Bilingual disclaimer **copy** + where it renders |
| Tool-call sanitization (raw KB / prompt internals never leave the engine) | Tìm Nhà request **form**; curator console UX |
| Plan-card ID issuance + validation | Thread/plan title, label, archive, search |
| Cancellation of in-flight turns | Billing: subscription, one-time fees, success fee (§11.6) |
| Emitting `usage` events per LLM-call boundary | Pre-call gating on the commerce model; debiting after |
| Tenant-level resource protection (concurrency caps, abuse throttles) | Notifications, email, push, alerts |

The engine is the planning engine, not the everything engine. When in doubt, the engine returns raw typed outcomes; the shell projects.

**Metering vs. gating** (principle 5). The engine meters — it emits `usage` at each LLM-call boundary with enough detail for any commerce model (tokens, model, source). It does **not** gate on commerce. FirstHomey's pricing is per-moment and mixed (one-time document review, active-period subscription, settlement success fee — §11.6); that is exactly the "every shell has a different commerce model" case. Each shell pre-gates against its own tables *before* calling the engine and debits from the `usage` event after. Keeping commerce out of the engine also keeps **ASIC liability** out of the agent loop: the engine never decides whether work proceeds based on money. Note that only **LLM-call boundaries** meter — deterministic resolver fills (architecture §11.9, two fill paths) involve no LLM call and emit no `usage`, so a resolver-only turn (e.g. a `cash_position` recompute) is free to the shell. Document extraction (architecture §11.9) is also an LLM-call boundary and meters; a turn that parses an upload is therefore *not* resolver-only, even when every component fill that consumes the extracted facts is `resolver`.

**Compliance is a gate, not commerce.** The FIRB branch (foreign persons cannot buy established dwellings 1 Apr 2025 – 30 Jun 2029), the ASIC decision-support boundary (no financial/credit *advice*), and AML constraints protect the **agent's behavior**, not a shell's UX — so they are **engine-owned** and run as an extension pipeline on every turn (§4, §6). The *rendering* of a bilingual disclaimer is shell-owned; the *gate that prevents a non-compliant recommendation path* is engine-owned. This is constraint #10 ("build the gate into the architecture, not as a disclaimer") made structural.

## 2. Surfaces

The engine presents one public HTTP surface today, with a second reserved.

### 2.1 `/api/engine/*` — primitive HTTP/SSE for FirstHomey shells

The primary surface. Consumed by the web app, the browser extension, and the curator console. Endpoint groups:

- **Turn execution.** Create a plan card (mode + state + target price range + target zone) and run the base planning turn; append a message / refine; stream events; cancel.
- **Simulation.** Preview a structural what-if (`target_price` / `state` / `property_type`) — a non-persisting resolver recompute of the financial spine — then save the chosen scenario as a refine turn. The preview is *not* a turn (no persistence, no metering, exempt from per-card serialization); see §10.
- **Plan-card primitives.** Fetch the raw filled plan-card state (base + addenda) and the event log since an event ID. List a user's active plan cards. The state fetch (`GET /api/engine/plan-cards/:id`) returns the typed content **plus two sync fields**: `event_cursor` — the snapshot's as-of `plan_card_events.event_id` (the same monotonic cursor §9's usage outbox uses) — and `turn_running` (is a turn in flight, from the turn registry). A client renders the snapshot, then subscribes to the SSE **from `event_cursor`** so the replay carries only post-snapshot (live) events — never an OLD turn replayed over the latest snapshot (a card has many turns, §4 "onboarding, message, property attach, refresh"; the canonical snapshot-then-resume-tail read). `turn_running` gives the initial done-state when the cursor leaves no terminal to replay.
- **Property attachment.** Attach a property (URL paste / extension capture / Tìm Nhà shortlist / partner push) → activates per-property components as an addendum (the attach primitive + the addendum namespace + the per-property render contract: §12).
- **Per-property transaction facts.** Submit the user-attested `contract_signed_date` + `settlement_date` for an already-attached property → a resolver-only re-fill that activates `settlement_prep`'s dated path; see §11.
- **Session replay.** Reconnect to an in-flight turn and receive accumulated events from `Last-Event-ID`.
- **Artifact primitives.** Resolve an engine-produced artifact by opaque ID (document report, Tìm Nhà search brief, decision-trail entry). The engine never pre-renders; shells render however they want.
- **Usage events.** Pull or subscribe to `usage` records for commerce conversion.
- **Health / readiness.**

### 2.2 `/mcp` — deferred

Not built for Wedge 1a. FirstHomey's clients are its own shells (REST+SSE suffices). Add a spec-compliant MCP Streamable HTTP surface only when a third-party agentic client (e.g., exposing planning as a tool to an external host) becomes real. Until then, do not add it — the absence is a deliberate scope decision, not an omission.

## 3. Tenant and user identity

The engine validates identity tokens; it does not originate them (principle 4).

On `/api/engine/*`: shell-minted JWT bearer tokens. Required claims:

- `tenant_id` — the shell instance (`web`, `extension`, `curator-console`).
- `user_id` — opaque end-user identifier within that tenant. For the curator console, the `user_id` is the curator; authorization to act on a given plan card's Tìm Nhà brief is carried as an additional claim, not inferred by the engine.
- `exp`, `iat`.

The shell signs with a key registered per tenant. The engine enforces signature validation, **tenant scoping** on every ETS entry / DB row / gen_statem registration, and user scoping on per-user endpoints. Per-user authorization (RBAC, suspension, row-level policy) is the shell's job; the engine treats `user_id` as opaque.

## 4. Event taxonomy

The engine emits typed events over SSE. Event names and field sets are part of the public contract; adding fields is non-breaking, renaming/removing is breaking. The taxonomy mirrors what the Anthropic SDK emits natively (principle 6) — internal FSM states (assembling, reasoning) are *not* events; they surface as `tool_use`/`tool_result` or `component_filled`.

**Lifecycle events** — frame every turn.

- `turn_started` — `{plan_card_id, turn_id}`. First event; replayed before accumulated events on reconnect.
- `turn_completed` — `{plan_card_id, turn_id, result_ref?}`. Terminal success; stream closes.
- `turn_cancelled` — `{plan_card_id, turn_id}`. Terminal; stream closes.
- `turn_failed` — `{plan_card_id, turn_id, code, message}`. Terminal; stream closes.

**Model output events** — incremental output from the vendor SDK.

- `text_delta` — `{text, lang?}`. `lang` ∈ `vi | en` tags which language this chunk belongs to; absent only on a legacy single-language stream. A **Q&A answer is bilingual** (`{vi, en}`, constraint engine-owned content-language, [`bilingual-content.md`](bilingual-content.md)) and is delivered as `text_delta` frames tagged by `lang`, so the shell concatenates per language and picks display (show one + toggle, or both stacked — shell-owned). It is **gated before emit** (buffer-then-gate, §6 + [`compliance-pipeline.md`](compliance-pipeline.md) §10): for the regulated free-text surface the engine buffers the complete answer, runs the compliance pipeline, and only then emits — Wedge-1a Q&A is therefore not true token streaming (the field shape keeps that door open for later chunk-gated streaming).
- `reasoning_delta` — `{text, signature}`. Only when `include_reasoning: true`; `signature` preserved verbatim for continuations.
- `tool_use` — `{tool_use_id, tool_name, display_name, arguments_summary}`. Tool-internal identifiers (raw KB lookups, curator dispatch) are sanitized into `display_name`.
- `tool_result` — `{tool_use_id, status, result_summary?, error?}`.

**Component events** — *the FirstHomey-distinctive family.* A blueprint component committed a typed outcome.

- `component_filled` — `{plan_card_id, component_id, scope, renderer, renderers, outcome, kb_versions, fill_path, property_id?, confidence?}`. `scope` ∈ `base | per-property | both`; `outcome` is the typed interface downstream components read. **This is the core contract surface: the shell renders `outcome` via the renderer(s) and never re-derives it.** **Renderer(s).** A component may **compose** two renderers (architecture §11.9, e.g. `data-table + opportunity-card` on `ownership_planning_investor`); each is one of the constrained vocabulary (constraint #7). `renderers` is the **ordered list** the blueprint declares for the component, carried verbatim from the compiled artifact (the SOT — the engine does not synthesize it). The shell renders **each renderer in `renderers`, in order, over the same `outcome`**. `renderer` is retained as `renderers[0]` for back-compat: a single-renderer component has `renderers: [renderer]`, and every existing single-renderer consumer is unchanged. (This carries the second renderer end-to-end; before it, the snapshot held only `renderer`, so a component's second declared renderer was unreached — the gap that left `ownership_planning_investor`'s `opportunity-card` dark.) `kb_versions` records which KB anchors were active (audit, see §7-equivalent in architecture §11.9). `fill_path` ∈ `resolver | agent` records which path produced the outcome (architecture §11.9, two fill paths; the decision rule for which path is [`agentic-boundary.md`](agentic-boundary.md)): `resolver` is a deterministic pure-function fill (copies, `derived_from`, calculator math, rules engine) and emits **no** `usage`; `agent` is an LLM turn and does. The shell renders both identically; the field exists for audit and cost attribution. On a **Phase-B (per-property) turn** the event additionally carries `property_id` — the addendum it fills (§12); a base turn omits it. A shell merges per-property fills into `addenda.<property_id>.components` keyed by `(property_id, component_id)`, the per-property analogue of the base `component_id`-keyed merge.

**Input-required events** — when the engine needs more before continuing.

- `user_input_required` — `{prompt_type, payload}`. `prompt_type` ∈ `free_text | structured` (`payload.questions: [Question]`). Resolved via `POST /api/engine/plan-cards/:id/messages`.
- `curator_input_required` — `{plan_card_id, brief_ref}`. The planning agent invoked Tìm Nhà; the search brief is persisted and surfaced to the **curator console** shell. Resolved when a curated shortlist is posted back (one addendum per returned property). This is the human-in-the-loop blocking state (principle 1: the awaiting process is isolated; the turn's gen_statem parks in `awaiting_curator`).

**Compliance events** — from the extension pipeline (§6).

- `compliance_gate` — `{plan_card_id, gate, disposition, detail}`. `gate` ∈ `firb | asic | aml`; `disposition` ∈ `branch | block | annotate`. Example: a foreign-person plan card hitting the established-dwelling ban emits `{gate: firb, disposition: branch, detail: new_build_only}`. The shell renders the consequence (e.g., `risk-flag-list`, bilingual disclaimer copy); the engine has already enforced the branch in the agent's reasoning path.

**Metering events.**

- `usage` — `{plan_card_id, turn_id, tenant_id, user_id, source, source_detail, model, input_tokens, output_tokens, cache_read_tokens, cache_creation_tokens}`. Tokens only; cost is shell-owned. Emitted per LLM-call boundary before the terminal lifecycle event.

**Error events (non-terminal).**

- `error` — `{code, message}`. Recoverable (KB lookup retry, vendor transient 5xx). Fatal errors surface as `turn_failed`.

**Ordering guarantees.** SSE event IDs are monotonic per `(tenant_id, plan_card_id)`; reconnect supplies `Last-Event-ID`. Within a turn: `turn_started` precedes all output; `usage` (when the turn invoked the agent) precedes the terminal event; terminal event is last. A **resolver-only turn** — one whose triggering change reaches no `agent_reasoning_required` parameter and invokes no document extraction (architecture §11.9) — emits `component_filled` events (each with `fill_path: resolver`) and a terminal event but **no** `usage`. `tool_result` follows its matching `tool_use`. `turn_id ≠ plan_card_id` — a plan card is the persistent container; a turn is one trigger (onboarding, message, property attach, refresh) → one terminal event.

**Serialization invariant.** `plan_card_id` is the serialization key: **at most one in-flight turn per plan card**; concurrent triggers queue. This is what makes the per-card monotonic event order above well-defined — two turns mutating one card's `content_jsonb` (e.g. a refine arriving mid-base-turn) would race on the source of truth. Different plan cards run fully in parallel (the only ceiling is tenant-level resource protection). See [`isolation-model.md`](isolation-model.md) §3.

**Staged turns.** A single turn may cross agent-type boundaries and so emit a *heterogeneous* event stream under one `turn_id`: a document uploaded mid-Q&A runs extraction → affected fills → Q&A, so `component_filled` (and possibly `compliance_gate`) precede the `text_delta` answer within that one turn. The Q&A agent never calls extraction — the `gen_statem` sequences the stages and the agent grounds in the now-updated card ([`isolation-model.md`](isolation-model.md) §6). Shells must be prepared to render a freshened component card *and* a streamed answer from one turn.

## 5. Attachments

Shells own blob storage; the engine accepts references. Turn input accepts `attachments: [Attachment]`:

- `{kind: "url", url, mime_type, sha256?}` — dereferenced at turn time; shell owns access control. (The synchronous user-URL-paste path per architecture §11.10 lands here — the engine fetches a single page via the Playwright sidecar; no scraping pipeline.)
- `{kind: "inline", mime_type, data_base64}` — small payloads; engine-enforced size cap.
- `{kind: "ref", blob_id, mime_type}` — shell-provided opaque ID resolved via a per-tenant registered resolver.

The engine maps attachments to the vendor SDK content-block shape; unsupported MIME types surface as `error{code: unsupported_attachment}`, never silently dropped. The engine does not persist attachment bytes beyond the consuming turn.

A turn carrying attachments invokes document extraction (an LLM-call boundary → `usage`), so it is a **document-review** moment even when the user experiences it as chat (the upload-mid-Q&A case, [`isolation-model.md`](isolation-model.md) §6). The engine meters it; the shell pre-gates the attachments-present case on its **document-review** entitlement (architecture §11.6 pricing), separately from and before whatever gates plain Q&A — consistent with metering-not-gating (§1).

## 6. Compliance extension pipeline

On every turn, the engine runs a fixed pipeline of compliance extensions over the agent's proposed output before it is committed and streamed (analogous to ATP's policy/legal/transactional extensions). For a structured fill the "proposed output" is the whole component outcome; for a **Q&A answer** it is the complete buffered free-text answer — the engine **buffers to completion, gates, then emits** (`text_delta`), never forwarding answer tokens live, because an ungated advice crossing cannot be un-shown ([`compliance-pipeline.md`](compliance-pipeline.md) §10). `tool_use`/`tool_result` machinery signals are not answer prose and do stream live.

- **FIRB** — branches on `firb_status` (first-class user attribute, constraint #10). For foreign persons, enforces the established-dwelling ban window and the new-build-only filter; annotates surcharge + vacancy-fee obligations.
- **ASIC** — enforces the decision-support boundary: the agent may surface options + reasoning (lender shortlist, scheme stack) but must not cross into licensed financial/credit *advice*. Outputs that cross the line are gated and rewritten or flagged.
- **AML** — never custodian of funds; money-transfer guidance must route to licensed partners; informal-channel routes are blocked.

Each extension emits a `compliance_gate` event and writes an `audit_events` row (no cost). The pipeline is engine-owned because it protects agent behavior, not shell UX. Disclaimer *copy* and its placement are shell-owned.

## 7. Reasoning stream toggle & cancellation

`include_reasoning: bool` (default `false`) — when true and the model supports it, the engine emits `reasoning_delta`; otherwise it disables reasoning at the vendor call. Reasoning is a display/cost decision; the engine provides the switch, not a view on it.

**Vendor/model is engine config, never user-facing.** The active vendor and model are engine-internal configuration (`.env`), keyed per agent role (extraction / leaf-fill / Q&A), resolved by Erlang at turn start and passed into the sidecar's run config. Vendor/model is **not** a JWT claim, **not** a tenant attribute, **not** a user toggle (§3 claims are unchanged). Resolution is per turn with no thread pinning — safe because the persisted glue is vendor-neutral (above), so a config change between turns strands no format-locked history. `usage.model` records the model actually served per turn for audit. See [`isolation-model.md`](isolation-model.md) §5 and [`agentic-flow.md`](agentic-flow.md) §7.

Cancellation: `POST /api/engine/plan-cards/:id/cancel`. Signals the running sidecar gen_statem to stop; emits `usage` for work done; terminates with `turn_cancelled`; partial component fills are persisted and replayable; idempotent (`204` on already-finished); per-plan-card scope; caller `(tenant_id, user_id)` must own the plan card.

## 8. Out of scope for the engine

These belong to the shell, even when every shell wants them. The engine exposes no endpoints for them.

- Onboarding wizard, mode picker, map zone selection UX.
- Plan-card visual rendering, the suburb-intelligence map, overlay toggles, tab layout.
- *Display*-locale: VND/AUD number formatting, timezone, canned-chrome copy (fixed disclaimers), and enum→label maps (the renderer vocabulary, constraint #7). **Not** content-language: the bilingual `{vi, en}` *generated content* (agent rationale, resolver notes/assumptions) is **engine-owned** — the agent authors both languages and the resolver fills bilingual copy-templates, snapshotted at fill time for the audit trail ([`bilingual-content.md`](bilingual-content.md)). The shell chooses which language to show (or both, side-by-side for the Mode B family view); it never translates engine content.
- Document-upload UI, attachment thumbnails, blob storage.
- Tìm Nhà request form, curator queue UI, curator assignment workflow.
- Commerce: Stripe, subscriptions, one-time fees, success-fee invoicing, regional pricing, credit/quota gating.
- Notifications, email, push, alert digests, refi/rate watchers' delivery.
- User profile beyond opaque `user_id`; thread/plan titles, labels, archive, search.

When a shell is tempted to ask the engine for something here, consume the primitive events and project the view. If every shell would implement the projection identically, promote it to a shared library — not to the engine surface.

## 9. Database architecture

The engine runs its own Postgres. Each shell runs its own. The API is the only contract: shells never read/write engine tables; the engine never reads shell tables (principle 2, principle 4).

### 9.1 Engine database

| Table | Purpose |
|---|---|
| `tenants`, `tenant_signing_keys` | Per-tenant keys, resource-protection quotas |
| `profiles` | `{profile_id, tenant_id, user_id, facts_jsonb, created_at, updated_at}` — the persistent **household fact base** (Decision 1, [`fact-model-unification.md`](fact-model-unification.md)): mode-independent buyer facts (`applicants[]` with per-applicant `tax{}`, `household_financials` incl. `existing_portfolio`, `traits`, `derived.firb_required_any`; `off_title_parties[]` with per-party `funder{}` for the cross-border modes), accumulating across journeys = the lifecycle moat. **`facts_jsonb` is schemaless: a mode populates the subset it needs and a later mode adds its slots as new keys — no migration** (the Mode-C-activated slots `tax{}`/`existing_portfolio`/`traits` populate now; the **Mode-B-activated** `off_title_parties[]`/`funder{}`/`applicants[].visa_class` populate with the Mode-B build — the VN-side *regulated* `funder{}` content (SBV/VN-PDP/VN tax) a **labelled placeholder** under the AU-side-full / VN-side-placeholder scope — [`fact-model-unification.md`](fact-model-unification.md) "Mode-B activation"). SOT for *current* facts; outlives every plan card |
| `plan_cards` | `{plan_card_id, tenant_id, profile_id, blueprint_slug, intent, mode, status, deploy_commit_sha, content_jsonb}` — one per **purchase journey** (FK → `profiles`), 1..N per household; base plan + addenda in `content_jsonb`. `mode` is a **derived** label (`firb_required_any × intent`), never a key (Decision 1). **Journey-level *input* facts (`plan.*`) live at this plan layer, not in `profiles`: `intent` as a column, and the investment-journey inputs `risk_tolerance`/`investment_goals` (Mode-C activated) join the `target` overlay (§10) as additive plan facts** — the profile/plan split (Decision 1). SOT for the agent's grounding (constraint #9) |
| `plan_card_events` | Durable typed-event log (§4). SOT for `Last-Event-ID` replay |
| `sessions` | Conversation log, `session_id = user_id × plan_card_id`. Stores vendor-neutral glue `(turn_id, user_text, assistant_text, ts)` only — **not** reasoning items, **not** pinned file ids (those are in-turn-transient / vendor-format; [`isolation-model.md`](isolation-model.md) §4). For user re-reading + Q&A coherence + audit; **not** agent grounding (constraint #9) |
| `audit_events` | Compliance-pipeline attribution + which KB versions were active per fill. No cost fields |
| `artifacts` | Content-addressed engine outputs (document reports, Tìm Nhà briefs, decision-trail entries) backing artifact refs |

**Fact base ↔ plan split (Decision 1, [`fact-model-unification.md`](fact-model-unification.md)).** Buyer facts live **once** in `profiles` (the accumulating moat), not per plan card — so a household's first-home journey and a later investment journey share one fact base, and a mode/journey change never orphans it. `plan_cards` reference it by FK. At each fill, the resolved facts + KB content are **snapshotted into `plan_cards.content_jsonb`** (with `deploy_commit_sha`) for the reproducible audit trail (architecture §11.9) and as the card's grounding surface; `profiles` stays live. **Serialization:** the per-`plan_card_id` invariant ([`isolation-model.md`](isolation-model.md) §3) covers Wedge 1 (one plan card per household); when multiple journeys exist, writes to the shared `profiles` row serialize per `profile_id` (a household-level turn) and plan-card turns read the profile at turn start. `mode` is never a partition key — derived per plan and per applicant.

The engine schema evolves on the engine's cadence; no shell coordinates on an engine migration.

**KB + blueprints are not Postgres tables.** They are git-authored (`docs/kb`, `docs/blueprints`), compiled into a versioned artifact shipped with the engine release and loaded into memory (`persistent_term`) at boot — each KB entry `{slug, effective_from, last_verified, content_md, content_json}`. Git is the source of truth; the artifact is a deterministic, rebuildable projection (rebuild from the deploy commit SHA). The engine is the **sole reader** — all KB access, including future online curator UIs, goes through engine primitives, never a direct store read/write. The offline KB agent's deploy-time compile (architecture §11.9) emits this artifact — that is the build-time/runtime handoff point. (Reproducibility for the audit trail lives in the plan-card snapshot — `plan_cards.deploy_commit_sha` + the resolved KB content copied into `content_jsonb` at fill time, architecture §11.9 "Audit trail" — not in a live KB table.)

**The artifact is multi-blueprint; the blueprint is resolved per plan-card.** The product is four modes (A/B/C/D), and more than one ships live at once — so the artifact carries a **set** of in-scope blueprints (Wedge 1a: `fhb-domestic-au`; Mode-C activation adds `investor-domestic-au`), **each with its own registry** (outcome types, resolver-input leaves, param slots). The runtime resolves which blueprint a turn runs **from the card's `plan_cards.blueprint_slug`** — set at creation from `intent` (+ FIRB status) — *not* from a single global in-scope label. The turn DAG (`fh_engine_turn:base_components`/`dag_reads`), the Layer-2 component-name gate, and the Layer-1 outcome-type validation (`fh_engine_outcome`) all key off the card's blueprint, and read **that blueprint's** registry. **Why per-blueprint registries, not one merged map:** outcome-type *names* are shared across modes (`profile`, `mortgage_plan`, `disposition`) but their fields/enums diverge — e.g. `disposition.cgt_status` is `[exempt, to_verify]` for an owner-occupier vs `[computed, to_verify]` for an investor — so a single flat map keyed by outcome-type name cannot represent both; each blueprint validates against its own. The consequence is the load-bearing one: **modes coexist — activating one never dormants another.** A blueprint absent from the in-scope set is parsed structurally and reported as inventory, never run (the standing scope call; the compiler gates each in-scope blueprint's registry independently — architecture §11.9).

### 9.2 Shell databases

One per shell, each owning its schema. Examples: `users`/`user_profiles` (identity, locale, bilingual *display* prefs — which language to show; engine content is already bilingual, [`bilingual-content.md`](bilingual-content.md)); the shell's *view* of plan cards (`{engine_plan_card_id, title, archived, last_opened_tab}`); commerce tables (subscriptions, one-time charges, success-fee ledger); `usage_records` (mirror of engine `usage`, aggregated for billing); Tìm Nhà request/queue state for the curator console; auth UX tables.

### 9.3 Cross-boundary

No cross-DB joins, ever. A shell rendering "my plans with titles and cost" queries the engine API for plan-card primitives and its own DB for display+commerce, then merges in application code (caching engine primitives with TTL/subscription invalidation if hot). The engine emits `usage` once; each shell mirrors its own tenant's events via the **pull-model outbox** (a shell consumer tails `usage` by cursor) — never RPC into engine tables. The outbox endpoint is **`GET /api/engine/usage_events?after=<cursor>&limit=<n>`** (8-S5b): tenant-authenticated + tenant-scoped, returning `type='usage'` events with `event_id > after` (ASC, capped), envelope `{events, count, cursor}`. The cursor is the monotonic `plan_card_events.event_id` (a `bigint`); the shell needs no cursor table — it bootstraps from `MAX(engine_event_id)` in its mirror. Each event carries `user_id` (the acting user, §9 above) so the shell attributes tokens without a join.

## 10. Simulation: structural what-ifs and the saved scenario

This section fixes the engine seam for [`lifecycle-simulation-model.md`](lifecycle-simulation-model.md) — the two-spines model and its one-saved-scenario rule. A plan card is steerable: the user explores what-ifs freely and persists exactly one chosen scenario. Two compute paths, one persistence rule.

### 10.1 The simulate primitive (preview — never persists)

`POST /api/engine/plan-cards/:id/simulate`, body `{overrides}` where overrides are the structural facts the financial spine depends on. **At base (Wedge 1a) the accepted overrides are `target_price`, `state`, and `horizon`** — the facts that move a computed base figure (duty = f(state, price); the full-horizon net position = f(horizon), lifecycle §8). The growth assumption is **not** a user override: it is KB-grounded and resolver-computed (§10.5, lifecycle §8.4) — surfaced banded, never typed in. `property_type` is a **Phase-B (per-property) dimension**: at base there is no property attached, so it moves *zero* base figures (eligibility's `property_fit.property_type` branch stays unpopulated — honest-partial); base simulate **rejects it with a clear reason** (no silent drop), and it becomes a real override only once a property is attached. It runs the **resolver-only recompute of the full base DAG** (`fh_engine_turn:base_components/0` — buyer_profile → eligibility → mortgage_finance *resolver half* → cash_position → ownership_planning → disposition → purchase_journey → preparation; [`resolver-semantics.md`](resolver-semantics.md), the same walk [`plan-card-refresh.md`](plan-card-refresh.md)'s resolver-only sweep uses) so the override flows through to every downstream outcome that places its figures, and returns the recomputed outcomes in the **response body**.

Response shape: `200 {plan_card_id, overrides, outcomes}` where `outcomes` is keyed by **`component_id`** (`{cash_position: <budget_envelope outcome>, mortgage_finance: <mortgage_plan outcome>, …}`) — the *same* keying as the committed snapshot (`content_jsonb.components`), so a shell merges `outcomes[component_id]` onto its existing component entry by one key, exactly as it would read a refreshed snapshot ("preview is commit minus persistence" at the response layer, not just the compute layer). Internally the resolver walk accumulates by `outcome_type` (downstream components read upstream outcomes by type); the handler re-keys to `component_id` via `base_components/0`, which is the single source of the `component_id ↔ outcome_type` pairing — the shell holds no second copy of that mapping.

It is a **preview, not a turn**: it does **not** write `content_jsonb`, does **not** append `plan_card_events`, does **not** advance `event_cursor`, emits **no** `usage`, writes **no** `audit_events`. Because it touches no source of truth it is **exempt from the per-card serialization invariant** (§4) — previews can run while a real turn is in flight and can never race the snapshot. The figures it returns are the *same* verified figures a save would commit (same resolver code path; duty to the dollar — [`stamp-duty-concession-mechanics.md`](stamp-duty-concession-mechanics.md)). This is the structural answer to "make the calculator interactive without a second, unverified computer": the prototype's client-side JS duty formula is exactly what the engine recompute replaces.

Cash-on-hand is **not** a simulate override — it is pure subtraction against the already-returned `total_cash_required`, done in the client with no round-trip (anchor §4.1). Only `target_price` / `state` round-trip at base (and `property_type` once a property is attached, Phase B), because only they change a *computed, regulated* figure.

### 10.2 Save = a refine turn (persists the one scenario)

Saving a previewed scenario is an ordinary **refine turn** (`POST /api/engine/plan-cards/:id/refine` carrying the chosen overrides): a resolver-only turn (§4 — `component_filled` with `fill_path: resolver`, a terminal event, and **no `usage`**) that commits the recompute as a new `content_jsonb` snapshot + a `plan_card_events` row, stamped with `deploy_commit_sha` + resolved KB for the audit trail (constraint #6, §9.1).

Persistence rule (one saved scenario): **the card's current snapshot *is* the saved scenario.** There is no scenarios table and no fork — save *advances* the single current snapshot; history is the append-only `plan_card_events` log. This adds no new unit of isolation ([`isolation-model.md`](isolation-model.md)).

Where the overrides land: **every base override is a `plan` (per-journey) fact** — `target_price` (→ `target.price_range`), the projection `state`, and the projection pin (`target_sal`/`target_zone`) are all attributes of *this* journey's target, mutable per journey (Decision 1, scenario S24). They persist **on the card**, via a plan-target overlay (the canonical `plan.target`, realized as a card-level store, overlaid on the profile onboarding at read), and are snapshotted into `content_jsonb`. A base refine **never writes `profiles`** — the persistent household facts (applicants, financials, `derived`) do not move. (`property_type` is a Phase-B per-property dimension, not a base override — §10.1.) The per-override profile-vs-card mapping is pinned in [`fact-model-unification.md`](fact-model-unification.md) ("Per-override storage mapping") and realized by [`lifecycle-simulation-model.md`](lifecycle-simulation-model.md) §4.3; an empty overlay reads exactly as the 1:1 Wedge-1 shape does today.

### 10.3 Compliance: preview vs commit

The full FIRB/ASIC/AML pipeline (§6) runs at **commit** (the refine turn), as on every persisted turn. The **preview** runs only the structural outcome-conformance gate ([`outcome-conformance.md`](outcome-conformance.md), fail-closed — Layer 1, the type walk + the W6g placement/provenance check). That asymmetry is sound: a structural figure what-if (`target_price` / `state` / `horizon`, and Phase-B `property_type`) is deterministic and cannot change `firb_status` or cross the ASIC advice boundary — it re-derives figures, it does not re-reason. `horizon` only re-projects how far the resolver runs the hold/dispose math; the growth/CGT figures it surfaces are resolver-computed from KB bands and rendered as decision-support with their assumption stated (lifecycle §8.4), never as advice or a forecast — the same ASIC line the acquisition figures hold. An override that *would* move a regulated branch is by definition not a figure what-if; it must go through a normal agent turn (§4 staged turns), never `simulate`.

### 10.4 The `phase_playbook` component and the per-phase surface

The phase-sheet reshape ([`lifecycle-simulation-model.md`](lifecycle-simulation-model.md) §7, [`architecture.md`](architecture.md) §11.9) adds **one new base-scope component**, `phase_playbook`, owning the per-phase action checklist + risks. It needs **no new event or endpoint** — it rides the existing §4 taxonomy:

- **It emits an ordinary `component_filled`** — `{scope: base, renderers: ["checklist"], fill_path: resolver, outcome: <phase_playbook>}`. (Its blueprint composes `checklist + risk-flag-list`, but the engine emits a single `"checklist"` renderer — `fh_engine_phase_playbook.erl`: the risks travel **inside** the same `phase_playbook` outcome and are rendered by the **FlowView hero surface** per phase, not dispatched as a second top-level renderer. So this component does **not** exercise the multi-renderer dispatch above; `ownership_planning_investor`'s `data-table + opportunity-card` is the first that does.) Filled at the base turn; like `purchase_journey` it runs **late** (it reads `cash_position.cash_events` for each action's `budget_ref` and other components for `component_ref`) and **computes no figure** — it places id references, not amounts (one-computer-per-figure, [`outcome-conformance.md`](outcome-conformance.md) gates that every `budget_ref` resolves to a real `cash_event.id` and every risk traces to a KB anchor).
- **It is what-if-invariant, so `simulate` (§10.1) need not recompute it.** Its outcome is KB content + *stable id references*; a `target_price`/`state` what-if changes the **amounts inside `cash_events`**, never their **ids**. So the playbook outcome is unchanged under a structural preview — the new figures surface through `cash_position`'s refreshed `cash_events`, which the playbook's `budget_ref` points *into* at render time (a render-time join, not a recompute). The simulate walk stays the figure-bearing subset; the playbook is filled once at the base turn and left alone.

**The `status` user-toggle write — built on the card's user-set layer.** A checklist whose items cannot be ticked is not actionable, so the write is part of the foundation, not a follow-on. Both `phase_playbook.actions[].status` and `preparation.document_checklist[].status` are *user-attested* (`not_started | done`). User-set per-card state **cannot** live in `content_jsonb` (the resolver re-seeds it on every recompute → silent clobber, the §10.2 / [`lifecycle-simulation-model.md`](lifecycle-simulation-model.md) §4.3 problem) **nor** in `profiles.facts_jsonb` (it would leak across the profile's other cards). It belongs in the **card user-set layer** — the same card-level store the plan-target overlay already established (lifecycle §4.3), now carrying a **second member**: a status map keyed by stable item id (`{ component_id: { item_id: status } }`).

- **Write:** `PATCH /api/engine/plan-cards/:id/checklist-status` — authenticated, tenant-scoped, body `{ component_id, item_id, status }`. Writes the user-set layer + appends a `plan_card_events` row (audit, constraint #6 / §9.1). **No recompute, no `usage`** — it sets a user fact, it does not re-derive the plan.
- **Read overlay (the clobber fix):** the resolver seeds `status: not_started` at fill; GET (and any refresh / simulate recompute) **overlay the user-set status onto the seed** before returning the outcome, so the effective `status` survives recompute exactly as the plan-target overlay survives it (lifecycle §4.3). An empty layer reads as the seed — backward-compatible with every card created today.
- **One mechanism, both components.** This is foundation, not a `phase_playbook` special case: it simultaneously closes `preparation`'s pre-existing same gap. The shell still only renders `outcome.status`; it never re-derives it (§4).

### 10.5 The `disposition` component and the hold-horizon what-if

The full temporal flow ([`lifecycle-simulation-model.md`](lifecycle-simulation-model.md) §8) extends the lifecycle past `own` to a terminal `dispose` phase and makes `own` horizon-aware. On this seam it adds **one new base-scope component** (`disposition`) and **one new override dimension** (`horizon`). Like §10.4 it needs **no new event or endpoint** — it rides the existing §4 taxonomy and the §10.1/§10.2 primitives.

- **The phase enum gains `dispose`.** `phase` ∈ `prepare | pre_approve | contract | settle | own | dispose` (was `…| own`). `own` carries the multi-year hold as `recurring`/`period: year` `cash_events`; `dispose` carries the one-off sale events. This is the only enum change (the `cash_event` shape is otherwise unchanged — `timing`/`period` already absorb hold and disposal, lifecycle §8.1). Adding an enum value is non-breaking (§4).

- **`disposition` emits an ordinary `component_filled`** — `{scope: base, renderer: "calculator", fill_path: resolver, outcome: <disposition>}`. It is the **figure-owner** for the dispose phase (the placeholder `cgt_projection` lacked one): it owns `sale_proceeds`, `selling_costs`, `loan_payout`, `cgt`, `net_proceeds` and emits the dispose-phase `cash_events` — `sale_proceeds` (in), `selling_costs`/`loan_payout`/`cgt` (out) — each `source_component: disposition`, gated by the placement/provenance check ([`outcome-conformance.md`](outcome-conformance.md): every emitted figure traces to its owner; CGT/growth trace to a KB anchor). The **spines place, never recompute**: the financial spine's full-horizon net position (lifecycle §8.6) and the swimlane's `dispose` column both *read* these `cash_events`; they are the `calculator` and `swimlane-diagram` renderers **extended**, **no new renderer** (constraint #7; the outcome type + renderer composition are pinned in `architecture.md` §11.9). It runs **late** in the base DAG (after `cash_position`/`ownership_planning`, reading their `cash_events` and the year-`H` loan balance).
  - **Mode-A path (built now):** owner-occupier principal residence is CGT-**exempt**, so `cgt` is typically `null` and the dispose value is *equity at sale → next purchase* (the graduation story). 
  - **Mode-C path (design-first):** the 50%-discount CGT, depreciation, and the recurring holding-phase gearing events (owned by `yield_modelling`/`tax_structure`) are the same structure, populated when the dangling `kb.tax.*`/`kb.investor.*` anchors are authored (lifecycle §8.7).

- **`horizon` is a new simulate/refine override (§10.1, §10.2).** Unlike `phase_playbook` (what-if-*invariant*, excluded from the simulate recompute, §10.4), `disposition` is **figure-bearing**: varying `horizon` re-projects the hold span and the disposal, so a `horizon` simulate **does** recompute it through the same resolver-only walk. It is therefore a free what-if — `simulate` emits no `usage`, a `refine` commit is a resolver-only turn (`fill_path: resolver`, no `usage`, §10.2). The growth assumption is **not** an override (KB-grounded, resolver-computed — §8.4); the user varies only `horizon`.

- **`horizon` persists where `target_*` persists.** It is a `plan` (per-journey) fact, not a profile fact — one more member of the plan-target overlay (§10.2 "where the overrides land"; [`lifecycle-simulation-model.md`](lifecycle-simulation-model.md) §4.3). A base refine **never writes `profiles`**; an empty overlay (no horizon set) reads as the mode default (investor: from `exit_strategy`; owner-occupier: long/indefinite — §8.3). **No new persistence store.**

## 11. Per-property transaction facts

Once a contract is signed, the plan needs two facts the user **attests about their own transaction** — `contract_signed_date` and `settlement_date` — to activate `settlement_prep`'s dated critical path (`dates_status: active`: the back-calculated milestone due-dates, at-risk detection, and the dated swimlane). These are the **third per-property input layer** (architecture §11.9, `<from_transaction>`): neither neutral *property* facts (the `<from_property_card>` selection, supplied at §2.1 property-attachment time) nor facts *extracted* from an uploaded document (`<from_document>`, the metered upload pipeline, architecture §11.10). They arrive **post-attach** (a contract is signed long after a property is selected) via a **structured submit**, so they get their own primitive — not the attach payload, not an upload.

**The submit primitive.** `POST /api/engine/plan-cards/:id/properties/:pid/transaction`, body `{contract_signed_date, settlement_date}` (ISO dates). Authenticated and tenant-scoped; caller `(tenant_id, user_id)` must own the card; the property `:pid` **must already be attached** (its addendum exists) — else `409`, no silent create (mirroring "attach MUST run before the per-property turn", §9.1). Dates are validated (well-formed; `settlement_date` after `contract_signed_date`) → a malformed or wrongly-ordered submit returns a clear `error{code}`, never a silent drop (the §10.1 `property_type`-rejection discipline). There is **no preview/what-if primitive** for transaction facts (unlike §10.1 simulate): a settlement date is a fact the user attests once, not a parameter they sweep, so it commits directly. (If a genuine date what-if need emerges, a §10-style preview can be added later.)

**Persistence — the `transaction` slot.** The dates are written to `content_jsonb.addenda.<pid>.transaction`, a **sibling** of the addendum's `property_card` and `components` (§9.1) — the per-property analogue of the card-level user-set layer (§10.4), which holds *base* user-attested facts. Per-property because a transaction is the acquisition of *this* property. A new store write establishes/refreshes the slot, mirroring `attach_property` / `snapshot_addendum_component`. Re-submitting **refreshes** the dates (it does not accumulate); when the heavy `<from_document>` path later extracts the same dates from the uploaded signed contract, it writes the **same slot** — one fact layer, two input mechanisms (architecture §11.9).

**The re-fill — a resolver-only per-property turn.** The submit triggers a turn over the per-property components whose leaves read `<from_transaction>` (today: `settlement_prep`; `due_diligence`'s date-dependent fields join when its document path lands). Because `<from_transaction>` is a resolver copy (no `agent_reasoning_required` leaf, no document extraction), it is a **resolver-only turn** (§4): `component_filled` with `fill_path: resolver` plus a terminal event, **no `usage`** — free to the shell, exactly like a base `refine` (§10.2). It commits a new `content_jsonb` snapshot + a `plan_card_events` row, `deploy_commit_sha`-stamped (constraint #6, §9.1), under the per-card serialization invariant (§4). Compliance runs as for any resolver-only turn: `settlement_prep`'s milestones / dates / insurance-timing are process & statutory facts, so it records `no_advice_surface` (§6, the catch-all pass-through). The recomputed `settlement_checklist` streams via the client's existing SSE subscription (the snapshot-then-resume-tail read, §2.1) — no separate response-body contract needed.

## 12. Property attachment

Attaching a property activates the per-property (Phase-B) components as an **addendum**. The engine's contract is "given a normalized `property_card`, run Phase B"; what *produces* the card (URL paste / extension capture / Tìm Nhà shortlist / partner push, §2.1) is a separate shell concern (architecture §11.10). Attachment is logically **prior** to §11's transaction submit: a property is attached, then — once its contract is signed — its dates are submitted against the addendum §11 created here.

**The attach primitive.** `POST /api/engine/plan-cards/:id/properties`, body the **normalized property_card**: required `{price (a positive number), state, suburb, property_type}` — the neutral facts the resolver copies and grounds the gross-yield ratio on; optional `{year_built, land_size, strata}` — agent-grounding facts for `property_assessment` (depreciation, land quality, strata health). Authenticated and tenant-scoped; caller `(tenant_id, user_id)` must own the card. The engine **generates** `property_id` (a server-side uuid) — the client does not supply it. Phase B is wired for the **investor blueprint only** (Slice A): a non-`investor-domestic-au` card returns `400 {error: phase_b_not_supported_for_blueprint}`; a missing/invalid required field `400 {error: invalid_property_card, detail}`; an unknown card `404`; a turn already in flight `409 {error: turn_in_flight}` (the per-card serialization invariant, §4). Success is `202 {plan_card_id, property_id, turn_id}`.

**The turn — an agent turn (unlike §11 transaction).** Attach triggers a per-property turn beginning with `property_assessment`, whose two-path fill invokes the agent (rent band + verdicts) → it **emits `usage`** (§4) and is metered. This is the load-bearing contrast with §11's transaction re-fill (resolver-only, no `usage`): attach is a **paid agent turn**, so a shell **gates** it on its agent-turn entitlement (billing.md §5, the same posture as a chat turn) — separately from and before minting the tenant JWT — metering-not-gating (§1).

**Persistence — the addendum namespace.** The property is written to `content_jsonb.addenda.<property_id> = {property_card, components: {}}`, a **sibling** of the base `content.components` (§9.1) — **not a new table** (`properties` is optional / not load-bearing, architecture §11.10). Per-property fills snapshot into `addenda.<property_id>.components.<component_id>`; the base sweep (refine/refresh) touches only `content.components` and leaves the addenda untouched. The later `transaction` slot (§11) is the third sibling under the same addendum.

**The consumer render contract.** On a Phase-B turn each `component_filled` carries `property_id` (§4) identifying its addendum; base turns omit it. A shell reconstructs per-property state by merging these fills into `addenda.<property_id>.components`, keyed by `(property_id, component_id)` — the per-property analogue of the base `component_id`-keyed merge. The `GET /api/engine/plan-cards/:id` snapshot already returns `content.addenda` (§2.1), so the canonical read is the same snapshot-then-resume-tail (§2.1): render the snapshot's addenda, then apply post-cursor per-property fills from the SSE.

## Appendix: relationship to the principles

- **Principle 1 (process isolation per thread)** → one gen_statem per plan-card turn; `awaiting_curator` (Tìm Nhà) is an isolated parked state.
- **Principle 2 (DB is SOT)** → `plan_cards` + `plan_card_events`; any shell/device reconstructs after crash. Reinforces constraint #9.
- **Principle 3 (stateless sidecar)** → the planning agent runs in a disposable Python port; Erlang owns lifecycle/persistence/streaming.
- **Principle 4 (engine = primitives, shells = UX/commerce)** → §1 ownership table; §8 out-of-scope.
- **Principle 5 (metering, not gating)** → §1 metering paragraph; `usage` event; commerce + ASIC kept out of the engine.
- **Principle 6 (protocol-first)** → §4 event names mirror the Anthropic SDK; JSON-RPC over the sidecar port; `/mcp` reserved for the spec, not a parallel mechanism.
