# FirstHomey Engine Contract

This document defines the public contract of the FirstHomey **planning engine** — the Erlang/OTP application plus its Python sidecars — for consumption by one or more user-facing shells. The engine runs the agentic planning workload (load blueprint + KB + plan-card state → reason → fill components → persist). A shell is any frontend+backend that provides UI/UX, user identity, commerce, and display-layer concerns on top of the engine.

Companion references: [`principles.md`](principles.md) (the six architecture principles this contract applies), [`erlang-design-checklist.md`](erlang-design-checklist.md) (OTP patterns for the engine), [`architecture.md`](architecture.md) (the three-layer model this engine implements), [`agentic-boundary.md`](agentic-boundary.md) (the resolver/agent decision rule), [`agentic-flow.md`](agentic-flow.md) (the agent types, prompt structure, vendor layer, and context management that run inside this contract), and [`isolation-model.md`](isolation-model.md) (what `plan_card_id` / `turn_id` isolate, the per-card serialization invariant, and engine-owned conversation persistence). The shell-engine pattern is adapted from the ATP project; the boundary discipline is identical, the domain is not.

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
- **Plan-card primitives.** Fetch the raw filled plan-card state (base + addenda) and the event log since an event ID. List a user's active plan cards.
- **Property attachment.** Attach a property (URL paste / extension capture / Tìm Nhà shortlist / partner push) → activates per-property components as an addendum.
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

- `text_delta` — `{text}`.
- `reasoning_delta` — `{text, signature}`. Only when `include_reasoning: true`; `signature` preserved verbatim for continuations.
- `tool_use` — `{tool_use_id, tool_name, display_name, arguments_summary}`. Tool-internal identifiers (raw KB lookups, curator dispatch) are sanitized into `display_name`.
- `tool_result` — `{tool_use_id, status, result_summary?, error?}`.

**Component events** — *the FirstHomey-distinctive family.* A blueprint component committed a typed outcome.

- `component_filled` — `{plan_card_id, component_id, scope, renderer, outcome, kb_versions, fill_path, confidence?}`. `scope` ∈ `base | per-property | both`; `renderer` is one of the constrained vocabulary (constraint #7); `outcome` is the typed interface downstream components read. **This is the core contract surface: the shell renders `outcome` via `renderer` and never re-derives it.** `kb_versions` records which KB anchors were active (audit, see §7-equivalent in architecture §11.9). `fill_path` ∈ `resolver | agent` records which path produced the outcome (architecture §11.9, two fill paths; the decision rule for which path is [`agentic-boundary.md`](agentic-boundary.md)): `resolver` is a deterministic pure-function fill (copies, `derived_from`, calculator math, rules engine) and emits **no** `usage`; `agent` is an LLM turn and does. The shell renders both identically; the field exists for audit and cost attribution.

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

On every turn, the engine runs a fixed pipeline of compliance extensions over the agent's proposed output before it is committed and streamed (analogous to ATP's policy/legal/transactional extensions):

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
- Bilingual disclaimer copy, VND/AUD display formatting, locale, timezone.
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
| `plan_cards` | `{plan_card_id, tenant_id, user_id, blueprint_slug, mode, status, deploy_commit_sha, content_jsonb}` — base plan + addenda; SOT for the agent's grounding (constraint #9) |
| `plan_card_events` | Durable typed-event log (§4). SOT for `Last-Event-ID` replay |
| `sessions` | Conversation log, `session_id = user_id × plan_card_id`. Stores vendor-neutral glue `(turn_id, user_text, assistant_text, ts)` only — **not** reasoning items, **not** pinned file ids (those are in-turn-transient / vendor-format; [`isolation-model.md`](isolation-model.md) §4). For user re-reading + Q&A coherence + audit; **not** agent grounding (constraint #9) |
| `audit_events` | Compliance-pipeline attribution + which KB versions were active per fill. No cost fields |
| `artifacts` | Content-addressed engine outputs (document reports, Tìm Nhà briefs, decision-trail entries) backing artifact refs |

The engine schema evolves on the engine's cadence; no shell coordinates on an engine migration.

**KB + blueprints are not Postgres tables.** They are git-authored (`docs/kb`, `docs/blueprints`), compiled into a versioned artifact shipped with the engine release and loaded into memory (`persistent_term`) at boot — each KB entry `{slug, effective_from, last_verified, content_md, content_json}`. Git is the source of truth; the artifact is a deterministic, rebuildable projection (rebuild from the deploy commit SHA). The engine is the **sole reader** — all KB access, including future online curator UIs, goes through engine primitives, never a direct store read/write. The offline KB agent's deploy-time compile (architecture §11.9) emits this artifact — that is the build-time/runtime handoff point. (Reproducibility for the audit trail lives in the plan-card snapshot — `plan_cards.deploy_commit_sha` + the resolved KB content copied into `content_jsonb` at fill time, architecture §11.9 "Audit trail" — not in a live KB table.)

### 9.2 Shell databases

One per shell, each owning its schema. Examples: `users`/`user_profiles` (identity, locale, bilingual prefs); the shell's *view* of plan cards (`{engine_plan_card_id, title, archived, last_opened_tab}`); commerce tables (subscriptions, one-time charges, success-fee ledger); `usage_records` (mirror of engine `usage`, aggregated for billing); Tìm Nhà request/queue state for the curator console; auth UX tables.

### 9.3 Cross-boundary

No cross-DB joins, ever. A shell rendering "my plans with titles and cost" queries the engine API for plan-card primitives and its own DB for display+commerce, then merges in application code (caching engine primitives with TTL/subscription invalidation if hot). The engine emits `usage` once; each shell mirrors its own tenant's events via the **pull-model outbox** (a shell consumer tails `usage` by cursor) — never RPC into engine tables.

## Appendix: relationship to the principles

- **Principle 1 (process isolation per thread)** → one gen_statem per plan-card turn; `awaiting_curator` (Tìm Nhà) is an isolated parked state.
- **Principle 2 (DB is SOT)** → `plan_cards` + `plan_card_events`; any shell/device reconstructs after crash. Reinforces constraint #9.
- **Principle 3 (stateless sidecar)** → the planning agent runs in a disposable Python port; Erlang owns lifecycle/persistence/streaming.
- **Principle 4 (engine = primitives, shells = UX/commerce)** → §1 ownership table; §8 out-of-scope.
- **Principle 5 (metering, not gating)** → §1 metering paragraph; `usage` event; commerce + ASIC kept out of the engine.
- **Principle 6 (protocol-first)** → §4 event names mirror the Anthropic SDK; JSON-RPC over the sidecar port; `/mcp` reserved for the spec, not a parallel mechanism.
