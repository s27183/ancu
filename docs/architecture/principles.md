# ATP Architecture Principles

Six principles that shape every ATP design decision. Three are inherited from Erlang/OTP and the agentic-systems reference architecture. Two are ATP-specific, driven by the multi-shell multi-tenant engine role. One is a working discipline that governs the other five.

Each principle states the **rule**, the **why** (what failure mode it prevents), a **forcing-function test** (ask this question to apply the principle), and **what it rules out** (concrete patterns that violate it).

This doc is the root of the architecture tree. Read it before the contract, migration plan, or Erlang checklist.

---

## 1. Process isolation per thread

Every concurrent concern — a WebSocket subscriber, an agent run, a tool call, a blocking approval — is its own Erlang process. Processes share nothing. One failure is local; it cannot propagate.

**Why.** ATP is inherently concurrent (N tenants × M users × K active threads × L tool calls) and failure-prone (LLM APIs timeout, sidecars crash, DB connections drop). Without process isolation, one tenant's overloaded thread stalls every other tenant's thread. With it, a crashed sidecar triggers `terminate/3`, the supervisor cleans up, and siblings keep running.

**Forcing-function test.** If this piece of work crashed right now, what else would break?

**Rules out.**
- Shared mutable state (global process dictionaries, module-level counters).
- One gen_server handling all threads — you get one failure domain for the whole engine.
- Callback-registry patterns for multi-subscriber delivery (maps of pids to futures). Use ETS + monitors instead.

**Anchored in.** `mcp_orchestrator`, `mcp_skill_call`, `mcp_tool_worker` — one gen_statem/gen_server per thread per concern. Supervised under `one_for_one` so sibling threads are independent failure domains.

---

## 2. Database is the single source of truth

Durable state lives in Postgres. Processes hold transient working state only. If a process dies, the DB state survives. If a client reconnects, it replays from the DB.

**Why.** In a multi-shell multi-device system, any subscriber on any device must be able to reconstruct thread state after any disconnect — including after the gen_statem serving the thread has crashed and restarted. Process-memory event logs (Rung's pattern) work for single-device single-shell scenarios; they don't survive crash + multi-subscriber replay. The durable `thread_events` table is the load-bearing element of rule 14 of the Erlang checklist ("decouple work from connections") applied engine-wide.

**Forcing-function test.** If the process serving this state died right now, could a new subscriber reconstruct what the old one saw?

**Rules out.**
- Event logs kept only in gen_statem state.
- Client-side caches of server state that drift without invalidation.
- Any "the frontend already has it, we don't need to persist" argument for agent-facing state.

**Anchored in.** `thread_events` (the event log), `agent_messages` (the SDK session store), `result_blobs` + `evidence_blobs` (tool outputs), `audit_events` (skill invocation audit). All keyed by `thread_id`, all scoped by `tenant_id`.

---

## 3. AI sidecar is stateless and disposable

The Python orchestrator sidecar receives full context on stdin, streams JSON-RPC events to stdout, returns the result, and exits. No state leaks between runs. No connection pooling. No long-lived servers.

**Why.** The AI ecosystem (Anthropic SDK, OpenAI SDK, MCP protocol) lives in Python — don't fight it. But Python concurrency and crash semantics are worse than Erlang's. Make the sidecar a pure function: Erlang owns lifecycle, persistence, and broadcast; Python owns model calls and agent-loop mechanics. Kill, restart, or replace the sidecar without affecting anything else.

**Forcing-function test.** If we force-killed this sidecar and spawned a fresh one, would the system be in a consistent state?

**Rules out.**
- In-process caches in the Python sidecar that expect to survive across turns (use DB or pass context on stdin).
- Long-lived Python servers that Erlang talks to over sockets. One port per turn, stdin for request, stdout for events, exit when done.
- Connection pools or global handles in the sidecar.

**Anchored in.** `tools/orchestrator_sidecar.py`, spawned by `mcp_orchestrator` via port. Exit after each turn. BlobCache is per-process and disposed on exit — its persistence is only within the turn.

---

## 4. Engine exposes primitives; shells own UX and commerce

The ATP engine exposes agentic primitives (`/mcp` for agentic clients, `/api/engine/*` for rich-UX shells). Shells — Svelte, Django/Next.js, `adi-atp-plugin` — own user identity, commerce, display projections, thread titles/labels/search, notifications, and admin UIs. No shell concern ever grows into the engine.

**Why.** ATP serves multiple shells with genuinely different UX and commerce models. Svelte runs a credit system; Django will run a different one; the plugin runs inside a chat client with its own billing. If engine code accumulates fields for "the Svelte dashboard" or "the Django admin view," every new shell has to negotiate with the engine team. The contract locks this by making the engine ignorant of shell UX concerns.

**Forcing-function test.** Would Svelte, Django, and the plugin render this field differently? If yes, it's shell-owned. Does this API endpoint protect the agent's behavior or the shell's UX? If UX, it belongs on the shell.

**Rules out.**
- Title, label, archive flag, color, pinned status on engine `threads` table. These live in shell DB and FK to `thread_id`.
- `total_client_cost` on `GET /api/engine/threads` response. Shell joins its own `usage_records` (populated from `usage` event stream) for cost rendering.
- Pandoc conversion of reports inside the engine. Engine emits markdown; shells run `pandoc` themselves with their own templates.
- User-facing endpoints like `/api/me`, `/api/auth/*`, `/api/billing/*` on the engine.

**Anchored in.** `docs/architecture/engine-contract.md` §1 (invariant) and §8 (out-of-scope list). The contract is the concrete application of this principle.

---

## 5. Metering, not gating

The engine emits `usage` events per turn. It does not gate on commerce. Shells pre-gate against their own credit/quota/subscription tables before calling the engine. The one engine-owned exception is tenant-level resource protection (concurrency caps, abuse prevention) — that's infrastructure, not commerce.

**Why.** Every shell has a different commerce model. Credit debit, flat subscription, per-seat billing, free-tier-with-usage-caps, corporate account pre-pay. Putting gating logic in the engine forces the engine to understand all of them — or lock every shell into one model. Emit the usage event; let each shell's commerce code decide.

**Forcing-function test.** Does this code path decide whether work proceeds based on money? If yes, it doesn't belong in the engine.

**Rules out.**
- `mcp_credits:check_sufficient` calls in tool-dispatch handlers.
- Per-turn `debit` calls in orchestrator/pipeline/tool_worker.
- Markup / currency / tier logic in the engine.
- Any table in engine DB shaped like `credits` or `credit_transactions`.

**Anchored in.** Contract §1 "Metering vs. gating." Implemented across Phases 0–6: `mcp_usage_events.erl` emits `usage`; engine-side commerce has been stripped (migrations 017, 023, 025); `mcp_billing.erl` moved to shell as `mcp_shell_billing.erl`; `mcp_credits.erl` retains only a residual admin check. Shells tail the outbox (`mcp_shell_usage_consumer`) and debit in their own ledger. See [billing.md](billing.md).

---

## 6. Protocol-first over pattern-improvised

When a protocol defines the mechanism — MCP Streamable HTTP for tool calls, vendor SDK events for streaming, JSON-RPC for sidecar I/O — implement the protocol, don't invent a parallel mechanism. When a vendor SDK names its events, mirror those names instead of coining FSM-internal ones.

**Why.** Most "weird" problems in agentic systems (tool-call timeouts, SSE disconnect recovery, multi-vendor prompt divergence, event replay) are problems someone else already solved in a spec. The protocol-first discipline is how the system stays composable: shells written against the MCP spec work; shells written against our custom event names break the moment we touch internals.

**Forcing-function test.** Did we read the spec before designing this handler? Do our event names match what a vendor SDK client would expect, or are they FSM internals leaking out?

**Rules out.**
- Event names like `awaiting_user`, `step_started`, `context_questions`. These are FSM state leaks — replace with `user_input_required`, `tool_use`/`tool_result`.
- Ad-hoc keepalive / timeout hacks for long-running tool calls. MCP Streamable HTTP defines SSE for this; use it.
- Custom JSON shapes for sidecar I/O when JSON-RPC would fit.
- Bypassing vendor SDK session stores in favor of a homegrown in-memory buffer.

**Anchored in.** Contract §4 (event taxonomy — vendor-aligned). Migration plan Phase 3 (taxonomy migration). `mcp_http_handler.erl` (MCP Streamable HTTP transport). `_orchestrator_history.py` + `SQLAlchemySession` (vendor SDK session pattern).

---

## Pointers

- **[engine-contract.md](engine-contract.md)** — the stable contract between engine and shells. Concrete application of principles 4 and 5.
- **[../design/engine-contract-migration.md](../design/engine-contract-migration.md)** — per-endpoint migration from today's mixed state to the contract. Seven phases.
- **[erlang-design-checklist.md](erlang-design-checklist.md)** — Erlang-specific playbook. Concrete application of principles 1 and 2 in OTP terms.

When adding a new endpoint, table, or event: run it past the six forcing-function tests above. If it fails any of them, the design is wrong — not the principle.
