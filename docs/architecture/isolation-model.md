# Isolation Model — units of isolation in the platform flow

This document defines **what is isolated from what** in the FirstHomey engine, and the two concepts that carry that isolation: the **plan card** (persistent state) and the **turn** (ephemeral execution). It is the FirstHomey counterpart to a "per-thread architecture" doc, but the answer is deliberately *not* "one universal key per thread" — FirstHomey's own constraints decompose isolation across several axes.

Companion references: [`engine-contract.md`](engine-contract.md) (the events, identity, and `sessions`/`plan_cards` tables this model populates), [`agentic-flow.md`](agentic-flow.md) (the agent types and run modes a turn dispatches), [`agentic-boundary.md`](agentic-boundary.md) (resolver vs agent — what a turn fills deterministically vs by LLM), [`principles.md`](principles.md) (process isolation, DB-as-SOT, stateless sidecar). The pattern is adapted from the ATP / `plc_agent` lineage; where a borrowed mechanism is deliberately reshaped or dropped, the reason is recorded.

---

## 1. The contrast: one universal key vs decomposed axes

`plc_agent` uses a single universal key — `system_id` — scoped identically across every layer: one conversation = one thread = one long-lived agent process = one address namespace = one job scope. That works because `plc_agent`'s model is **one stateful agent per thread**: a live process (`plc_sidecar`, registered per `system_id`) carries the accumulated conversation, and the conversation *is* the agent's memory.

FirstHomey cannot collapse to one key, because three of its own constraints pull the responsibilities apart:

- **Multi-shell** — the engine serves web + browser extension + curator console (a tenancy axis `plc_agent` doesn't have).
- **Constraint #9** (ground in current state, not history) — the running process does not need to carry the conversation; it is rebuilt from `plan_cards` each turn.
- **Principle 3** (stateless, disposable sidecar) — so there is no reason to keep a long-lived process per thread at all.

Isolation therefore decomposes across axes rather than collapsing into one key:

| Axis | Unit | Lifetime | Isolates | `plc_agent` analog |
|---|---|---|---|---|
| Security / tenancy | `tenant_id` (× `user_id`) | account | one shell / one user from another | none (single-tenant) |
| **State / grounding / conversation / audit** | **`plan_card_id`** | **persistent** | one plan's state + KB snapshot + Q&A thread + event log | `system_id` (the conversation) |
| **Runtime / process / crash blast-radius** | **`turn_id`** | **ephemeral** | one in-flight reasoning execution | `plc_sidecar` — but theirs is long-lived, ours per-trigger |
| Leaf-fill | *(none)* | none | isolation by **statelessness**, no id needed | child-agent path |

The load-bearing move is the **plan-card / turn split** (§2). `plc_agent`'s `system_id` is both the conversation *and* the process because the process holds the conversation. FirstHomey separates the **persistent state container** (the plan card, source of truth in Postgres) from the **ephemeral execution over it** (the turn). Leaf-fills need no isolation id at all — being stateless one-shots, two fills are as isolated as two pure-function calls ([`agentic-flow.md`](agentic-flow.md) §3).

---

## 2. Plan card vs turn

**Plan card** — the persistent container. One per (user, plan): base plan + zero-or-more property addenda, `content_jsonb` is the source of truth for the agent's grounding (constraint #9), `plan_cards` + `plan_card_events` reconstruct it after any crash (principle 2). It outlives every process that ever touched it.

**Turn** — one ephemeral execution against one plan card. A turn is:

> one **trigger** (onboarding, message, property attach, refresh) against one plan card → the engine's `gen_statem` walks the affected slice of the blueprint DAG — deterministic resolver fills + zero-or-more **stateless** agent leaf-fills, *or* one Q&A run — runs the compliance pipeline, commits, and emits **one terminal event**.

What the split buys, each tied to a constraint:

- **Stateless sidecar (P3).** Because state lives in the plan card, not the process, the sidecar can be a disposable port: full context in on stdin, events out on stdout, exit. Nothing to keep alive between turns.
- **Vendor-switch freedom (§5).** No long-lived process means no format-locked history stranded in memory; the backend can change vendor between turns.
- **Per-turn crash isolation (P1).** A failed turn never endangers the card — the card is in Postgres; the turn's `gen_statem` is the only thing that dies.

### `turn` is not `plc_agent`'s `exchange`

`plc_agent`'s unit is an **exchange**: one user message → one agentic loop (one model, ~35 items of reasoning / tool-calls / outputs) → one final assistant message, all persisted to the session. An exchange is intrinsically conversational and single-agent.

A FirstHomey turn is a **DAG walk that may fan out to several independent stateless fills**. An onboarding turn runs `buyer_profile` → `eligibility` → `mortgage_finance` (base) … — several leaf-fills, each a separate `run_blocking`, with no conversation anywhere. Consequences:

- A turn may carry **many LLM-call boundaries → many `usage` events**, or **zero** (a resolver-only turn emits `component_filled` with `fill_path: resolver` and no `usage`).
- Only a **Q&A turn** resembles a `plc_agent` exchange. "Turn" is the more general concept; "exchange" is one shape of it.

---

## 3. The serialization invariant

**`plan_card_id` is the serialization key: at most one in-flight turn per plan card; concurrent triggers queue.**

This is currently *inferable* from the engine contract's ordering guarantee (§4: "event IDs monotonic per `(tenant_id, plan_card_id)`") but is stated here as a first-class isolation rule, because it is the thing that bites at implementation time. It is the FirstHomey analog of `plc_agent`'s "`plc_sidecar` registered in ETS per `system_id`" — except registered per **plan card** and **short-lived** (one registration per turn, released at the terminal event).

Why serialize rather than allow concurrent turns within a card:

- The card's `content_jsonb` is the single mutable grounding surface. Two turns mutating it concurrently (a refine arriving mid-base-turn) would race on the source of truth.
- Serialization keeps the monotonic per-card event order the contract promises to shells for `Last-Event-ID` replay.
- It keeps the model simple: one `gen_statem` registered per card at a time, no intra-card locking story.

Cross-card concurrency is unaffected — different plan cards run fully in parallel; the cap is tenant-level resource protection, not a per-card constraint.

---

## 4. Conversation persistence — engine-owned, not a sidecar session

`plc_agent` persists conversation via the agent SDK's `SQLAlchemySession`: the runtime loads the full item list (`session.get_items()`), merges new input, persists (`session.add_items()`), then compresses/truncates at read time before the LLM call. The session **is** the agent's memory, lives **in the sidecar**, and grows unbounded — which is the entire reason its three-layer management apparatus exists.

FirstHomey **does not adopt `SQLAlchemySession`**, and the inversion is structural:

| | Who owns the session | What is persisted | Reloaded as grounding? |
|---|---|---|---|
| `plc_agent` | the agent runtime (SDK) | full vendor-format items (reasoning, tool pairs, signatures) | **yes** — it is the memory |
| **FirstHomey** | the **engine** (Erlang + Postgres `sessions`) | vendor-neutral glue `(turn_id, user_text, assistant_text, ts)` | **no** — the card re-grounds; glue is for coherence + user re-reading |

Three reasons, each a constraint:

1. **Constraint #9 inverts what the session is for.** `plc_agent` grounds the agent in history; FirstHomey grounds in the current plan card, re-injected fresh each turn. Fill turns have *no* conversation to persist. Q&A turns keep history as **glue only** (pronoun resolution, "the other one"), explicitly not grounding ([`agentic-flow.md`](agentic-flow.md) §4). A `SQLAlchemySession` is built to be grounding — using it would smuggle history-as-grounding back in.
2. **Principle 3 — the sidecar is stateless and disposable.** A `SQLAlchemySession` lives in the sidecar, holds a DB connection, and owns persistence — making the sidecar stateful and giving it a second responsibility it must not have.
3. **Postgres is SOT, owned by Erlang.** A sidecar session is a *second writer*, splitting the source of truth. The engine's **`sessions` table** (`session_id = user_id × plan_card_id`) is the conversation home, written by Erlang.

So the session is **data passed in on stdin** (Erlang assembles the glue a Q&A turn needs and includes it in the sidecar payload), never a stateful object the sidecar holds. The sidecar returns its answer as events; Erlang persists the new glue pair.

### What is persisted — and what is not

Persisted glue is exactly `(turn_id, user_text, assistant_text, ts)`. Deliberately **not** persisted cross-turn:

- **Reasoning items.** Needed *within* a single Q&A run (Anthropic requires the thinking block + `signature` passed back on a continuation inside the loop) — so they live transiently in `RunResult.history` during the one run and are gone when the sidecar exits. Not persisted as glue: constraint #9 means the next turn re-grounds from the card, not from last turn's reasoning. (`plc_agent` confirms this even for its own design — its Anthropic compression strips thinking blocks from prior exchanges as "turn-specific context, not useful for prior exchanges.") Persisting them would also re-introduce vendor-format lock-in (§5).
- **Pinned file ids.** `plc_agent` pins these for dual-vendor pre-upload + rehydration — machinery [`agentic-flow.md`](agentic-flow.md) §8 omits. In FirstHomey, document bytes meet an LLM in exactly one place (the extraction sidecar) and come out as structured facts stored *in the plan card*; a Q&A question about a document grounds in those facts or resolves the extraction **artifact by opaque id**. There is no vendor file handle to pin. The pinned prefix here is **KB**, not uploads.

Because we persist vendor-*neutral* text, `plc_agent`'s three-layer management mostly dissolves ([`agentic-flow.md`](agentic-flow.md) §8): Layer 1 (compress) applies lightly to glue, Layer 2 (truncate) is trivial, Layer 3 (server compaction) is a flag-gated safety net. None of the orphan-tool-pair repair, reasoning-item rescue, or rehydration-window logic is needed — those are all artifacts of persisting full vendor items, which we do not.

---

## 5. Vendor selection — engine config, never user-facing

Vendor and model are **engine-internal configuration** (`.env`), resolved by Erlang at turn start and passed into the sidecar's `RunConfig`. The sidecar is *told* which adapter to use; it never decides.

- Vendor/model is **not** in the JWT, **not** a tenant attribute, **not** a user toggle. The engine-contract identity claims (`tenant_id`, `user_id`, `exp`, `iat`) are unchanged. Users are never shown a vendor option.
- Config is keyed **per agent role** — extraction, leaf-fill, and Q&A may each map to a different model (e.g. extraction on a cheaper model, Q&A on the strongest). Still backend-decided, still invisible to users; `.env` holds a model-per-role map rather than a single value. The role→run-mode keys are the [`agentic-flow.md`](agentic-flow.md) §7 table.

**Resolution policy: per turn, no thread pinning (interpretation A).** Each turn resolves its model from current config; a plan card is **not** pinned to a vendor for its lifetime. This is safe — not despite the "no mid-conversation switch" rule but *because of* the neutral-glue property (§4): since nothing vendor-format is persisted, a switch between turns strands no format-locked history and causes no quality whiplash within a turn. `.env` changes at operator cadence (a deploy/restart event — new model, pricing, failover), so in practice a conversation sees one vendor; a long thread *may* cross a config change harmlessly. We do **not** pay for a hard per-thread pin, because the event it would guard against is harmless by construction and pinning would add per-card vendor state plus a dead-vendor staleness problem.

"No mid-conversation switch" therefore means **no user-driven switch and no in-turn whiplash** — both satisfied by operator-cadence config without pinning. The `usage.model` field records the actual model per turn, so the served model is always verifiable after the fact for audit.

---

## 6. Staged turns — when one trigger spans agent types

A turn is one terminal event even when it internally crosses agent-type boundaries. The canonical case is a **document uploaded mid-Q&A** ("what do you think of these reports?" + attachments):

```
upload + question   (one trigger → one turn)
  └─ gen_statem stages:
     1. extraction sidecar: bytes → structured facts            [usage #1]
     2. affected fills: <from_document> slots (resolver) +
        document_significance leaf-fill (agent)                 [usage #2, component_filled]
     3. re-ground from the NOW-updated card → Q&A run           [usage #3, text_delta]
     4. persist glue (user_text, answer); terminal event
```

The wall between agent types holds: **the Q&A agent never calls extraction.** The `gen_statem` sequences the stages; the Q&A agent only ever sees the *result*. By the time stage 3 runs, stages 1–2 have written the documents' facts into the card, and constraint #9 means the Q&A run grounds in the now-updated card — so the answer references the documents "for free," never by the conversation agent touching bytes. This is why the Q&A agent holds a `kb_lookup` tool but **no document tool**: a document tool would collapse normalization into conversation and re-introduce bytes-in-the-reasoning-context that [`agentic-flow.md`](agentic-flow.md) §8 exists to avoid.

Two implications the staged model makes explicit:

- **`component_filled` can precede `text_delta` within one turn.** A turn the user experiences as "chatting" emits `component_filled` (and possibly `compliance_gate`) before the streamed answer. The shell renders a freshened due-diligence card *and* a chat answer from a single `turn_id`.
- **An upload mid-Q&A is a document-review moment, not free Q&A.** Extraction is an LLM boundary (→ `usage`), and one-time **document review** is its own pricing moment ([architecture.md §11.6](architecture.md#116-pricing-implications); metering-not-gating in [`engine-contract.md`](engine-contract.md) §1). The shell pre-gates the attachments-present case on the **document-review** entitlement — separately from, and before, whatever gates plain Q&A. A user who thinks "I'm only chatting" is invoking the priciest path; the gate must catch it before the turn runs.

**Framing chosen: one turn, staged** — not two serialized turns (attach-turn then message-turn). One turn matches the user's single conversational beat, produces one glue entry, and ties the answer causally to the upload. The cost — a heterogeneous event stream within the turn — is acceptable; the `gen_statem` state set carries the stages.

---

## 7. Summary of the model

1. **No universal key.** Isolation decomposes: `tenant_id`×`user_id` (security), `plan_card_id` (state·grounding·conversation·audit, persistent), `turn_id` (execution, ephemeral). Leaf-fills isolate by statelessness, no id.
2. **Plan card vs turn** is the load-bearing split — persistent SOT vs ephemeral execution over it — and is what buys stateless sidecar, vendor-switch freedom, and per-turn crash isolation.
3. **Turn** = one trigger → DAG-slice walk (resolver + 0..n stateless leaf-fills, *or* one Q&A run) → compliance → one terminal event. May carry many `usage` events or none. Not `plc_agent`'s conversational "exchange."
4. **`plan_card_id` serializes** — at most one in-flight turn per card; triggers queue; cross-card runs parallel.
5. **Conversation is engine-owned**, not a sidecar `SQLAlchemySession`. Persisted glue = `(turn_id, user_text, assistant_text, ts)` only — no reasoning items, no pinned file ids.
6. **Vendor = engine `.env` config, role-keyed, resolved per turn, never pinned, never user-facing** (interpretation A); safe because of neutral-glue persistence.
7. **Turns may be staged** across agent types (extraction → fill → Q&A) under one terminal event; the Q&A agent never touches bytes; upload-mid-Q&A gates on document-review entitlement.
