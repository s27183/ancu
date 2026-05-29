# Erlang/OTP Design Checklist

Timeless patterns distilled from *The Erlanger Playbook* (Loic Hoguin) and validated against this codebase. Use as a review checklist when writing or reviewing Erlang modules.

---

## 1. Let It Crash

- Pattern-match the happy path: `{ok, X} = call()`, not `case call() of {ok,X} -> ...; {error,_} -> ...`
- Only handle errors you can meaningfully recover from
- Internal functions should crash on unexpected input — the supervisor handles recovery
- Exception: system boundaries (see rule 2)

## 2. Fail at the System Boundaries

- Validate ALL external input at HTTP handlers, WebSocket handlers, and port I/O
- Wrap `binary_to_integer`, `jsx:decode`, `list_to_atom` in `try/catch` at boundaries
- Return user-friendly errors (400/401/422), don't let Cowboy generate 500s
- Internal modules trust their callers — no defensive checks deep inside

## 3. Don't Swallow Exceptions

- Never `catch _:_ -> ok` without at least a `logger:debug` call
- Catch the specific exception class when possible: `catch error:badarg ->` over `catch _:_ ->`
- Silent failures cost debugging time — today's "impossible" error is tomorrow's production incident
- Cleanup code (port close, demonitor) is the one exception where silent catch is acceptable

## 4. Supervise Everything

- Every long-lived process must be supervised — no bare `spawn/1` for processes that matter
- Use `spawn_link/1` for short-lived tasks spawned from supervised processes — link propagates failures
- Bare `spawn/1` creates invisible processes: if they crash, nobody knows
- Fire-and-forget operations should still use `spawn_link` — Cowboy and gen_server handle linked exits gracefully

## 5. Defer Blocking Work from init/1

- `init/1` blocks the parent (supervisor or caller) until it returns
- Never do DB queries, network calls, or file I/O in `init/1`
- Options: lazy-load in `handle_call` (preferred), `gen_server:enter_loop/3`, or `{continue, init}` (OTP 21+)
- `self() ! do_init` and `{ok, State, 0}` (timeout) are both flawed — messages can arrive before init completes

## 6. Hibernate Long-Lived Connections

- WebSocket handlers and other idle-waiting processes should return `hibernate`
- Hibernation triggers GC, then suspends — reduces memory for processes that receive messages infrequently
- All Cowboy WebSocket callbacks support `{ok, State, hibernate}` and `{reply, Frames, State, hibernate}`

## 7. Records Stay Local

- Define `-record(...)` only in the module that uses it
- Never put records in header files (`.hrl`) — changes ripple across every including module
- If state must cross module boundaries, define an opaque type: `-opaque state() :: #state{}.`
- Maps are fine for flexible data (configs, settings); records are fine for gen_server state

## 8. Type Specs on Exports

- Every exported function gets a `-spec`
- Specs enable Dialyzer to catch type errors at compile time
- Callback modules (gen_server, cowboy_websocket) benefit from specs even though the framework defines the contract
- Use `-type` and `-opaque` for domain types, not just primitive types

## 9. ETS for Concurrent Reads

- Use ETS with `{read_concurrency, true}` when many processes read, one writes
- Serialize writes through a gen_server to avoid race conditions
- ETS survives process crashes if the table has an heir — use for registries
- Don't use ETS as a cache without understanding GC implications for large binaries

## 10. PGO Parameter Types

- PGO infers parameter types from PostgreSQL's query plan, not from the Erlang value you pass
- If a column is `timestamptz`, PGO expects `$N` to be an Erlang datetime tuple `{{Y,M,D},{H,Min,S}}` — passing a binary ISO string fails silently
- If a column is `uuid`, PGO may expect a specific encoding — use `$1::text::uuid` to force text input
- If a column is `interval`, PGO cannot encode `<<"3600 seconds">>` as interval. Fix: compute the target timestamp in Erlang and pass a datetime tuple instead of an interval. Example: `ExpiresAt = calendar:gregorian_seconds_to_datetime(calendar:datetime_to_gregorian_seconds(calendar:universal_time()) + TTLSeconds)` then use `$N` with the tuple directly
- If a column is `jsonb`, PGO may return the value as a raw binary string (not a decoded Erlang map). Never assume `is_map(Output)` — always handle the binary case: `is_binary(Output) -> jsx:decode(Output, [return_maps])`. This varies by query — some queries decode JSONB automatically, others don't.
- **Double-cast for types PGO doesn't know:** PGO tries to infer the parameter type from PG's query plan. For extension types (`vector`) or when PGO picks the wrong codec, it throws `function_clause` inside its encoder. Fix: double-cast `$N::text::target_type` — this tells PGO to send the param as text, then PG casts it. Examples: `$N::text::vector(1536)` for pgvector embeddings passed as `"[0.1,0.2,...]"` binary, `$N::text::jsonb` for JSONB passed as `jsx:encode()` binary. Same principle as `$N::text::uuid` for UUIDs.
- Always convert Erlang values to PGO-compatible types before passing as query parameters
- Never ignore `pgo:query` results — at minimum log errors so silent type mismatches become visible
- Example: `pgo:query("... WHERE ts >= $1", [<<"2026-03-01T...">>])` fails because PGO can't encode binary as timestamptz. Fix: `pgo:query("... WHERE ts >= $1", [parse_timestamp(Bin)])`

## 10b. base64url Encoding

- Standard base64url: `+` → `-`, `/` → `_`, strip `=` padding
- **NOT** `+` → `_`, `/` → `-` — this is a common swap error
- Matters for PKCE (RFC 7636): client and server must agree on encoding. Wrong mapping causes silent verification failure
- Erlang helper: `<< <<(case C of $+ -> $-; $/ -> $_; _ -> C end)>> || <<C>> <= base64:encode(Bin), C =/= $= >>`

## 11. Public Interface Design

- Module names are nouns: `plc_db`, `plc_thread_state`, `plc_sidecar`
- Function names are verbs: `get_context`, `broadcast_to_user`, `start_link`
- Export only what callers need — behavior callbacks (`init`, `handle_call`) are required exports, not public API
- Error convention: `{ok, Result}` / `{error, Reason}` for operations that can fail; crash for programming errors

## 12. Protocol-First Implementation

- Read the protocol spec before writing handler code — the answer is usually in the spec
- Implement what the protocol defines, don't invent workarounds for problems the protocol already solves
- Example: MCP Streamable HTTP spec defines SSE responses for long-running tool calls. Six different timeout/keepalive hacks failed before reading the spec and implementing SSE correctly.
- When something doesn't work, ask "does my implementation follow the protocol?" before "how do I patch around this?"

## 13. cowboy_loop for Long-Running Requests

- `init/2` can return `{ok, Req, State}` (immediate response) OR `{cowboy_loop, Req, State}` (async response via `info/3`)
- Use `cowboy_loop` when the response depends on messages from other processes (workers, supervisors, external events)
- Never block in `receive` inside `init/2` for operations that take more than a few seconds — it holds the Cowboy process hostage and no data flows on the socket
- `cowboy_req:stream_reply/3` opens a streaming response; `cowboy_req:stream_body/3` sends chunks; `stream_body(<<>>, fin, Req)` closes the stream
- Return `{ok, Req, State, hibernate}` from `info/3` for idle waiting — reduces memory between messages
- Return `{stop, Req, State}` from `info/3` when done — tells Cowboy the handler is finished

## 14. Decouple Work from Connections

- Long-running work (Agent SDK reasoning, external API calls) should store results independently of the requesting connection
- Pattern: ETS result store + waiter registry. Worker stores result in ETS and notifies all registered waiters. If no waiters (client disconnected), result persists for next request.
- On reconnect/retry, check ETS first → serve cached result as plain JSON (fast path)
- This transforms client disconnection from "lost work" to "non-event"

## 15. No Wall-Clock Timeouts on Supervised Ports

- `state_timeout` / `gen_server:timeout` can't distinguish "stuck" from "working" — they fire on elapsed time regardless
- Supervised ports already have structural safety nets:
  1. `exit_status` — Erlang gets notified immediately when the OS process crashes or exits
  2. Application-side timeouts (e.g., httpx 600s) — handle hung external calls where the work actually happens
  3. Inactivity timeouts (e.g., 30 min in `awaiting_user`) — handle user abandonment
- These three cover all failure modes without false positives
- Only use wall-clock timeouts when no structural signal can detect the failure

## 16. Durable State Must Outlive the Process It's Bound To

- If durable ETS state is keyed by an identity (session id, correlation id, etc.), do not tie that identity's lifetime to a process whose lifetime is shorter than the state it guards
- Specifically: `monitor(process, Pid)` + `{'DOWN', ...}` → `ets:delete` is a cleanup pattern, *not* a lifetime binding. The monitored pid must outlive every consumer of the state
- Ephemeral Cowboy POST handlers fail this test — one pid per request. Binding session rows to a handler pid deletes the session when the request returns. Subsequent requests create fresh sessions and any session-scoped state is lost
- Symptoms: the registry name implies "survives the session" but every request re-mints the session ID; session-scoped lookups silently return `not_found`; any code that's the first real consumer of the session-keyed state exposes the bug (earlier consumers that keyed by a bare id were unaffected, masking the flaw)
- Allowed: monitor a long-lived process (worker, supervisor, GET /mcp SSE handler) — those outlive individual state entries
- Cleanup alternatives that don't require monitoring a caller pid: TTL sweep (see `mcp_evidence_store` / `mcp_session_registry`), explicit delete endpoints, or parent-linked supervision
- Checklist when adding a new `monitor(process, Pid)` for cleanup: (1) who is Pid — a worker, a handler, or a caller? (2) does Pid outlive every reader of the state? (3) if not, use TTL + explicit delete instead

## 17. gen_statem vs gen_server — the OTP Rule

- Use `gen_statem` when the process is convenient to describe as a state machine **and** you need any one of:
  1. Co-located callback code per state (for `call`, `cast`, `info`)
  2. **Postponing events** — a substitute for selective receive
  3. **Inserted events** — internal self-events
  4. **State enter calls** — entry actions co-located with the state's callbacks
  5. **state_timeout, event_timeout, or named generic timers**
- For simple state machines without any of these, `gen_server` is fine — the ~1µs call-overhead difference is not a tiebreaker (per OTP design-principles docs)
- **Anti-pattern:** `gen_server` with a `status` field that drives conditionals. This is a state machine in denial; you lose compile-time visibility of legal transitions and `handle_common`/`postpone`, and any item mis-placed in `Data` instead of `State` becomes a hard-to-find bug when postpone is introduced (OTP docs: "an incorrect design decision of what belongs in the state may become a hard to find bug some time later")
- **ATP application:**
  - Flow controllers (per-turn or per-call; states + timeouts + DOWN-handling that differ by state) → `gen_statem`. Examples: `mcp_orchestrator`, `mcp_skill_call`
  - Side workers and ETS owners (port lifecycle, registry mutation, caches) → `gen_server`. Examples: `mcp_tool_worker`, `mcp_session_registry`, `mcp_auth`, `mcp_evidence_store`
- **Companion discipline (rule 2 + principle 2):** a flow-controller `gen_statem` should not also be the durable event log. Externalize history (e.g. `thread_events`) so `state_timeout` GC in `done` can reclaim flow-controller memory without taking the log with it

---

## Quick Review Checklist

Before merging Erlang code, verify:

- [ ] No bare `spawn/1` — use `spawn_link/1` or a supervisor
- [ ] No `catch _:_ -> ok` without logging (except cleanup)
- [ ] All external input validated at the handler, not deep inside
- [ ] No blocking I/O in `init/1`
- [ ] All exported functions have `-spec`
- [ ] WS handlers return `hibernate`
- [ ] Records defined in the module that uses them, not in `.hrl`
- [ ] Long-running handlers use `cowboy_loop`, not blocking `receive` in `init/2`
- [ ] Protocol spec read before implementing transport-level code
- [ ] Work that outlives connections stores results in ETS (not just in handler state)
- [ ] base64url uses `+`→`-`, `/`→`_` (not swapped) — critical for PKCE/OAuth
- [ ] No wall-clock timeouts on supervised ports — use `exit_status` + app-side timeouts
- [ ] Durable ETS state keyed by an identity is not tied to a process whose lifetime is shorter than the state (no `monitor(process, Pid)` on ephemeral handler pids as a cleanup mechanism)
- [ ] `gen_statem` only when the OTP triggers fire (postpone, state-enter, state_timeout, generic timers, inserted events); flow controllers are ephemeral, event logs are durable

---

*Source: The Erlanger Playbook (Loic Hoguin, 2020). Patterns validated against Erlang/OTP 28.*
