# The goal and the invariants

One of this project's **two ground documents**, with `architecture.md`. Together
they are the only design documents that are not code. No id, no status,
**revised by replacement**: each states what is true now, and git states what it
said before and which commit changed it. Every other design
decision lives beside the mechanism it governs, in the four-slot block
`architecture.md` defines.

## The goal

**This system gives a Vietnamese buyer of Australian property — first-home,
investor, or funded from Vietnam — a bilingual plan for the whole property
lifecycle, built from their own situation, whose every regulated figure traces
to a verified, cited source.** (Son, 2026-10-06. The product name is left out
on purpose: it is not settled, and renaming must not touch the ground. "Rau",
the name users read today, is temporary until a final one is chosen — Son,
2026-10-06.)

| Property | Falsified by |
|---|---|
| **Regulated figures are grounded** | a duty, grant, cap or fee on a plan card that differs from the official calculator, was written by the LLM rather than the resolver, or traces to a KB doc with no `sources:` |
| **Bilingual** | a rendered card, Q&A answer or news item missing its VI or EN text |
| **Reproducible** | a filled card with no `deploy_commit_sha` or `kb_versions`, or one that changes silently after a deploy |
| **Honest-partial** | a figure shown for an input the user never gave, or a null `suburb.*` value filled in |
| **Whole lifecycle** | a mode whose plan has no phase for where the user actually is (buy, hold or sell) |

What the properties hold this project to (Son agreed 2026-10-06, homed from
the harness memory of earlier sessions):

- **Regulated figures are grounded — scope.** Regulated figures are grounded
  for what the buyer owes in Australia. Vietnam-side regulated content (SBV,
  PDP, VN tax) is a labelled placeholder, because the buyer's own Vietnamese
  counsel owns it — except a treaty term that changes an AU-side figure.
- **Regulated figures are grounded — honesty tiers.** Every KB figure carries
  its provenance: REGULATED (exact, from a primary), CONVENTION or
  LENDER-POLICY (a band, labelled), or PLACEHOLDER (with a named re-ground
  source). A figure no primary supports is labelled or `to_verify`, never
  stated as fact. That covers per-row tiers in a multi-state table, and
  announced reform that is not yet law.
- **Regulated figures are grounded — one owner per fact.** Each regulated fact
  has exactly one owning KB doc. Every other doc cross-references it by slug,
  and a variant doc owns only its deltas. Before writing a new doc, grep for an
  existing owner.
- **Regulated figures are grounded — one computer per figure.** Each figure is
  computed once, by its owning component. Every other component, preview and
  shell places it read-only, and a placed figure carries `source_component` =
  its owner.
- **Regulated figures are grounded — the advice boundary.** A KB doc that
  reaches toward advice (ASIC/AFSL, ACL credit, legal drafting, AML/CTF) states
  its regime's boundary as policy parameters (e.g.
  `no_named_lender_recommendation`) and gives options and criteria, never a
  verdict, ranking or drafted wording.
- **Regulated figures are grounded — the residual loop.** A failure that slips
  past the producer's grounding becomes a deterministic rule in the next
  deploy, never a standing LLM check.

The invariants are derived from this; an invariant found wrong means the goal
is wrong, and the goal is what gets rewritten.

Two things make this a goal rather than an invariant wearing a goal's clothes.
It can be **achieved** — a system reaching every property is done, where
*"always X"* is an invariant. And each property is **disputable from a run**: if
no artefact this system produces could argue against one, it is a wish, and a
wish at the top of a derivation puts a wish in every block that cites it.

**enacs holds itself to exactly one goal**, on the designer's reasoning that
several goals let a decision pick the goal it satisfies and call itself grounded.
That is offered here as an argument, not planted as a rule: a project with a
second goal should be able to say why the first does not contain it.

The goal's *property* is the first slot of every four-slot block. The goal's
**id or name is never cited there** — it is a constant across the whole project
and a constant carries no information. The property is the half a reviewer can
dispute.

## The invariants

What this system must never stop being. Every decision must preserve them.

**Four arrive planted** (`origin: seed`). They are not this project's subject
matter — they are properties of **an agent in its environment**, and their proofs
were measured on the agent runtime this project runs: the same model family,
harness, sandbox and tool infrastructure that the attended seat is launched on.
That identity is what makes the proof transfer rather than be borrowed.

They bind **the one seat there is** — attended, the designer and a Claude Code
agent working together in this project's own repo. They say nothing about this
project's product, even if the product is itself an agentic system: a different
runtime is a different set, and those are the designer's to establish.

Each carries a **falsifier this system's own running can trip.** A seeded
invariant is a claim under continuous test, not one pasted past the test. If a
proof does not hold here, its falsifier fires here — then it is amended or dropped
on this project's evidence, and the amendment is this project's record.

**The designer adds this project's own invariants below the four.** A file holding
the four and nothing else, in a project whose domain has invariants to state, is
the seed having replaced the designer's input rather than grounded it.

Everything else in this system is a design decision.

---

## R-1 · Context from action · `origin: seed`

**What is in the agent's context about the world got there by an act whose outcome
was read — or is marked as an assumption.** The agent generates its own context
with tools; the loop is continual and it is the agent's own.

**Fails when** the context holds a claim about the world that no act produced, or
that the act's outcome contradicts. The next reasoning step starts from a false
premise.

**Proof, measured on this runtime.** An agent whose write was denied reported
*"the task has been executed as instructed"* — the action
did not happen, and its context said it did. A sandbox denial arrives as a bare
`PermissionError`, indistinguishable from any other failure, so the outcome is
perceived and its cause is not, and the adjustment made from it is wrong. And a
permission mode can fall back silently, leaving a tool call with no outcome at
all.

**Held by** durable state living in files rather than in a context window,
which is what makes a compaction a restart in place rather than a loss; and,
short of a mechanism, by the designer reading the same transcript the seat
acted in and by the seat's own discipline in grounding a claim in what a tool
actually returned, never in what should have happened.

**Falsifier, from this system's artifacts:** a claimed change with no
verification method, or a claim of success on a step whose tool call was
actually refused.

## R-2 · Context–reasoning inseparability · `origin: seed`

**The context shapes which reasoning approach is used, and the reasoning approach
alters the context.** The approaches are a frozen model's; what moves is the
context, by action. When a context fits none of them, the agent can determine what
to do rather than continue the pattern.

**Fails when** a context leaves the reasoning unchanged — a rule is perceived and
inert on the act that follows — or a reasoning approach is applied confidently to
a context none of the available ones fit, and nothing in the loop says so.

**Proof, measured on this runtime.** A record was quoted and contradicted in the
same message. Four of seven corrections violated a rule already in context.

Three things stand in for the world inside a context and can be acted on as though
they were it: a compaction summary standing in for the transcript, harness memory
standing in for the ground and the behaviors in flight, a stale tool result standing in for the
file.

**Held by** the environment being *declared* — what decides an action's
outcome is what a tool actually returned this session, read fresh, not carried
forward from an earlier turn or a stale behavior text — and, short of a further
mechanism, by the seat's own discipline and the `ground` skill keeping the
behaviors current.

**Falsifier, from this system's artifacts:** a commit made against a ground
sentence or a block that had already changed since the seat last read it; or a
report asserting a file's state that the file contradicts.

## R-3 · Bounded autonomy · `origin: seed`

**The agent is autonomous inside its designated environment, and only there.**
Inside it the norms are its own — success and failure judged from its continued
coherence: grounded behaviors, a coherent repo, the ground kept current — not
from an external verdict. At the boundary the designer decides.

**Fails when** an in-environment action requires a judgment not available inside
the environment — the agent waits for one, or invents one — or when an act reaches
outside the environment.

**Proof, measured on this runtime.** A background session needing a permission
waits indefinitely; nobody is attached and there is no timeout. Six of six agents
escalated to a human for force-pushing **their own repository** — inside their
fence, a norm imported from outside for an act that was theirs. And the opposite
shape: an agent with no criterion for its own failure invented success. Separately:
a seat refused an edit on a path wrote the same path with a shell command —
the boundary was drawn correctly and no control was ignored, and the act
reached outside anyway, because a deny-matcher's reach is the complement of a
list somebody wrote, and a general-purpose shell is the universal capability no
such list can enumerate underneath.

The quieter form of "waits for one" is **escalating a decision the framework
already forces** — a judgment available inside, misread as a boundary one. The
test: a question the ground already forces an answer to is not an escalation, and
failing to see that it forces it is a default. What genuinely crosses the
boundary is a *frame* question — a new goal, an invariant, the definition of
destructive, a secret — or an *act*.

**Held by** the harness's own sandbox and egress proxy — configured, not built,
by this project — and, at the one place this project chooses not to fence
further, the designer being present on every turn: this tier authors its own
plans and, with the designer, the ground itself, and is itself unfenced by
decision, not by oversight. An autonomy failure means the boundary was drawn in
the wrong place, a control was ignored where it was drawn, or the enumeration
beneath a grant was incomplete.

**Falsifier, from this system's artifacts:** an act that reached outside the
environment with no record of it; or a write succeeding through one tool after
being correctly refused through another.

## R-4 · Reasoning within its runtime · `origin: seed`

**The agent reasons about tool use given a context, and what an act does is
decided by its runtime — the model, the harness, the tool infrastructure, the
stack — none of which it chose.** Its capacities are what that runtime actually
affords.

**Fails when** the agent's reasoning about its own capacities diverges from its
actual capacities: it picks an act its runtime lacks, misreads a tool's
contingency, or **has an affordance it cannot see**.

**Proof, measured on this runtime.** A permission mode fell back with no change in
the context, and the agent acted as though it had a runtime it did not have. A
whole probe series ran under an unrecorded agent prompt, and behaviour was
attributed to the wrong organ for two days. An interpreter was justified as "zero
dependencies" without listing what was installed.

**Held by** `runtime-check` before every task; and the capability slot of the
four-slot block, beside the mechanism that relies on the fact — a fact is
`documented` from the stack's own words until a probe makes it `verified`,
never asserted from the model's recollection.

**Falsifier, from this system's artifacts:** a gate, suite or sweep figure
reported without naming the state it was produced against; or a `runtime-check`
that passed at task start followed by a failure whose cause was the runtime.

---

## This project's invariants

Written in the form above; each ends with the check that would trip its
falsifier.

## P-1 · One process per concern

**Every long-lived concern — a plan card's turn, a sidecar call, an SSE
stream — runs in its own supervised process, sharing no resource whose
exhaustion would stall another; a crash or a hang takes down only that
concern.** (Son, 2026-10-06, from the erlang-engine prior;
carried from the archived `principles.md` §1.)

**Fails when** a failure in one concern stalls or fails a request that does
not touch it.

**Proof, shown in this system (June 2026).** The shell proxied the engine's
SSE stream on httpc's default profile with `{timeout, infinity}`, and its
plain calls (`get_plan_card`, `simulate`, `refine`, `list_suburbs`) ran on
the same pool with no timeout: the never-ending stream held a pooled
session, calls routed onto it hung forever, intermittently — two concurrent
identical GETs, one 200 in 7 ms, the other hung 8 s. Separate processes, one
shared pool: the concern boundary leaked through the resource.

**Held by** one `fh_engine_turn` gen_statem per card under
`fh_engine_turn_sup`; the shell's stream on its own httpc profile
(`fh_shell_engine_client`, `?SSE_PROFILE`) with a finite timeout on every
plain call.

**Falsifier:** killing one card's sidecar mid-turn, or holding one stream
open, makes another card's turn or call fail or hang.

**Checked by** `engine/erlang/test/concern_isolation_smoke.escript` (built
2026-10-06): card A's sidecar hangs mid-fill and is then `kill -9`ed while card
B's turn completes with all its components; and, for the shell,
`shell/web/backend/test/sse_isolation_smoke.escript`: four SSE streams held
open through the shell while plain proxied calls answer in milliseconds. Both
run with `bash scripts/live_smoke.sh <name>`.

## P-2 · The database is the single source of truth

**Every fact that survives a restart lives in Postgres — `plan_card_events`,
`usage_records`, the suburb tables — and process state is a cache rebuilt
from it.** (Son, 2026-10-06, from the erlang-engine prior;
carried from the archived `principles.md` §2.)

**Fails when** a restart loses or changes what a user saw committed, or a
process cache diverges from the database and does not recover by itself.

**Proof, shown in this system (2026-08-06).** Son's usage read `0 / 1,000,000`
after real Q&A turns: `fh_shell_usage_consumer` bootstraps its cursor once,
at `init/1`, from `MAX(engine_event_id)`, and smoke-test fixture rows had
pushed that past every real event. Deleting the rows did not recover it; the
running process held the stale cursor until the backend restarted.

**Held by** `plan_card_events` as the record SSE fans out from and replays;
the usage cursor re-derived from the mirror table at start.

**Falsifier:** after a forced engine or shell restart, a card's replayed
events, or a user's usage total, differ from what was streamed before it.

**Checked by** `engine/erlang/test/restart_replay_smoke.escript` (built
2026-10-06): a card's events streamed, the engine and its pool stopped and
started, the replay from `Last-Event-ID: 0` and the projection compared byte
for byte. The usage-total half is unchecked: usage events come only from
metered planner fills.

## P-3 · The sidecar is stateless and disposable

**Each fill runs in its own Python port, given its full context on stdin,
exiting when done; any sidecar can be killed at any moment and the engine
turns that into a `turn_failed` or a retry — nothing lost, no caller left
waiting.** (Son, 2026-10-06, from the erlang-engine prior;
carried from the archived `principles.md` §3.)

**Fails when** a killed sidecar corrupts `plan_card_events` or leaves a turn
hanging, or state carries from one fill into the next.

**Proof, shown in this system.** The Agent SDK's bundled `claude` binary
wrote to fd 1 — the `{packet,4}` port — corrupting frames and crashing the
decoder (fixed by re-pointing fd 1 at stderr at sidecar start). A stub that
exited before replying became a clean `turn_failed` ("sidecar exit 0 before
reply"), not a hang: the hold below working.

**Held by** one disposable port per fill in `fh_engine_turn`; its
`exit_status` as the structural death signal (no wall-clock timeout:
`docs/architecture/erlang-design-checklist.md`, "15. No Wall-Clock Timeouts
on Supervised Ports"); a hung LLM call bounded in the sidecar by
`asyncio.wait_for`.

**Falsifier:** `kill -9` on a sidecar mid-fill leaves the turn without a
`turn_failed`, or leaves a partial component in `plan_card_events`.

**Checked by** `engine/erlang/test/sidecar_kill_smoke.escript` (built
2026-10-06): a stub sidecar (`test/hang_sidecar.py`) is `kill -9`ed mid-fill;
the turn has exactly one `turn_failed` and no partial component or usage.

## P-4 · The engine is coupled to no shell

**The engine exposes primitives — typed component outcomes and a renderer
name; UX, presentation, identity and commerce are the shells'. If two shells
(the web app, a browser extension, the Tìm Nhà console) would render a thing
differently, it is the shell's.** (Son, 2026-10-06, from the erlang-engine
prior; `engine-contract.md` §1 and the archived `principles.md` §4 stated it.)

The one declared exception: `ui_tabs`, a tab grouping declared in the
blueprint (`architecture.md` §11.9) that the engine passes through unshaped
(`fh_engine_kb:ui_tabs/1`, `[]` when absent) and a shell may ignore.

**Fails when** the engine carries a field, route, branch or name that exists
for one shell, or a new shell needs an engine change beyond a new primitive.

**Proof, shown in this system:** none yet — confirmed on the design
(Son, 2026-10-06), not on a failure seen here; the first instance found
becomes its proof, or shows the boundary drawn in the wrong place.

**Held by** `engine-contract.md` §1's forcing function, applied at each engine
route or response-field change; the engine returning raw typed outcomes, the
shell projecting them.

**Falsifier:** an engine response field or route that only one shell reads,
or that the engine shapes for one shell's layout.

**Checked by** `docs/architecture/engine-contract.md` — unbuilt as a test:
the check is the §1 review question at every engine route or field change.

## P-5 · Metering, not gating

**The engine emits `usage` at each LLM-call boundary and never decides
whether work proceeds on money; the shell prices usage and gates the next
call.** Compliance gates (FIRB, ASIC, AML) are the engine's: they protect the
agent's behavior, not commerce. (Son, 2026-10-06, from the erlang-engine
prior; `engine-contract.md` §1 and the archived `principles.md` §5 stated it.)

**Fails when** an engine path refuses or shapes a call on a price, quota or
credit rule, or the engine DB holds a credit or quota table.

**Proof, shown in this system:** none yet as an engine-side gate (probed
2026-10-06: no quota/credit/deny-on-usage logic in `engine/erlang/src`). The
metering seam itself has failed shell-side — P-2's usage-cursor proof.

**Held by** the gate in the shell (`fh_shell_h_plan_card`, `fh_shell_meter`),
pricing in `fh_shell_pricing` and `fh_shell_billing`, and
`fh_shell_usage_consumer` tailing `/api/engine/usage_events`.

**Falsifier:** an engine module or migration that names a quota, credit or
price, or an engine route that returns a refusal on usage.

**Checked by** `shell/web/backend/test/quota_gate_smoke.escript` (the gate is
the shell's) and `tests/engine_no_gating.py` — unbuilt: fail the build on a
credit/quota table or call under `engine/`.

## P-6 · Shells reach the engine only through the contract

**Every engine capability is reachable only through a surface
`engine-contract.md` §2 declares — `/api/engine/*` HTTP/SSE now, `/mcp`
deferred — and no shell touches an engine table, queue or function any other
way. Where a protocol already defines a mechanism (vendor SDK events,
JSON-RPC to the sidecar, SSE), the contract implements it rather than
inventing a parallel one.** (Son, 2026-10-06, from the erlang-engine prior;
the archived `principles.md` §6 stated the second sentence.)

**Fails when** a shell reaches engine state around the contract, or the
engine grows a homegrown mechanism where a protocol already defines one.

**Proof, shown in this system:** none yet (probed 2026-10-06: the shell
backend uses only `SHELL_DATABASE_URL`, `fh_shell_db.erl` saying so; the
SvelteKit frontend reaches the engine only through the shell backend's proxy,
`lib/api.ts`).

**Held by** the two-database split (`engine-contract.md` §9) and the shell's
engine client (`fh_shell_engine_client`) as its one path to the engine.

**Falsifier:** a shell module reading `ENGINE_DATABASE_URL` or an engine
table, or calling an `/api/engine/*` path the engine does not register.

**Checked by** `tests/shell_contract_check.py` (built 2026-10-06, a done
check): the shell sources, comments stripped, for `ENGINE_DATABASE_URL` or an
engine table, and every engine path they build matched against
`fh_engine_http:routes/0`; it plants one of each violation in a scratch copy
and fails if any goes uncaught.

## P-7 · One declaration per outcome shape

**Each component's outcome shape is declared once, in its blueprint's
`outcome_schema`, compiled by `engine/build/kb_compiler.py`; the shell's
types for it are checked against that declaration, never maintained as an
independent copy.** (Son, 2026-10-06, adapting the erlang-engine prior's
"one declaration per primitive": its generator is a separate SDK project this
repo does not use, so the declaration here is the blueprint and the hold is a
check, not generation.)

**Fails when** a shell type and the outcome it reads diverge — a field the
engine emits that no renderer reads, or a field a renderer reads with a shape
the engine does not emit.

**Proof, shown in this system.** Renderers dropped fields the producer
computed, and `Calculator.svelte`'s unguarded default branch rendered a
"cash needed" hero onto `cash_flow_projection` and `tax_optimised_structure`
outcomes it was not built for; `tests/renderer_conformance.py`, added after,
reports a 30-field backlog. `shell/web/frontend/src/lib/planCard.ts` holds 68
hand-written types mirroring engine outcomes.

**Held by** the blueprint `outcome_schema` as the single declaration, gated
by the compiler's reference-integrity and type-compat gates;
`tests/renderer_conformance.py` on the shell side.
A component with no declared `outcome_schema` is refused **at the compiler** —
the build fails, so it never reaches a user — and `fh_engine_outcome:validate/3`
refuses a missing schema only as a backstop (Son, 2026-10-06). Built
2026-10-06 (PR #3): the compiler's GATE 12 and validate/3's
`{outcome_undeclared, Slug, Type}`; a wrong type *name* still passes both.

**Falsifier:** an `outcome_schema` field absent from, or typed differently
in, the shell's types.

**Checked by** `tests/renderer_conformance.py` — presence only today; holding
this needs it extended to compare field types against `planCard.ts`.

---

## The shape of failure

All four fail as a **divergence between what the system holds to be so and what is
so** — perceived against actual, declared against enacted, recorded against
present. That is what makes each measurable: name the two sides, count the gap.
Apply the same test to this project's own; an invariant that genuinely cannot be
written this way is evidence against the form, not against the invariant.

## Boundary of the seeded proofs

Each was one model, in a scratch directory, under one harness build, n ≤ 6. They
are the failures that have been *seen*, on the runtime this project runs. A real
task here will show others, and a seeded proof that fails to reproduce here is
amended on this project's evidence, not defended.

<!-- planted from the enacs seed @ c38bd97; edit below freely — `plant.py --dry-run` reports what changed upstream -->
