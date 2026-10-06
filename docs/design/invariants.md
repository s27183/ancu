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
on purpose: it is not settled, and renaming must not touch the ground.)

| Property | Falsified by |
|---|---|
| Regulated figures are grounded | a duty, grant, cap or fee on a plan card that differs from the official calculator, was written by the LLM rather than the resolver, or traces to a KB doc with no `sources:` |
| Bilingual | a rendered card, Q&A answer or news item missing its VI or EN text |
| Reproducible | a filled card with no `deploy_commit_sha` or `kb_versions`, or one that changes silently after a deploy |
| Honest-partial | a figure shown for an input the user never gave, or a null `suburb.*` value filled in |
| Whole lifecycle | a mode whose plan has no phase for where the user actually is (buy, hold or sell) |

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

*None yet. The designer states them; the attended seat writes them in the form
above — statement, fails when, proof, held by, falsifier — and each needs a
failure shown in this system, not an aspiration. Each is headed
`## <ID> · <title>` and ends with the check that holds it, the test that
would trip its falsifier — in an Erlang or Elixir project, a PropEr property
where it ranges over inputs or states — one or more backticked paths or
commands; until one exists, the linter warns (W25):*

    **Checked by** `<path or command>`

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
