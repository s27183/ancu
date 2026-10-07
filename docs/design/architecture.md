# Architecture — the coupling

One of this project's **two ground documents**, with `invariants.md`. Together
they are the only design documents that are not code. No id, no status,
**revised by replacement**: each states what is true now, and git states what it
said before and which commit changed it.

Everything else a designer would once have written as a record — every design
decision, every implementation decision, every verified fact about the runtime —
**lives beside the mechanism it governs**, in the source, in the same commit that
changes the mechanism. The shape it takes is the four-slot block below.

## What this document is for

**What depends on what, where a change propagates, and what put each coupling
there.** Who does what is `invariants.md` and this file; what each part *is* is the inline documentation in the code that part is
made of.

A coupling here with no reason behind it was inherited — it gets a reason or it
gets removed. That is the test, and it is worth running on this table
deliberately, because an architecture nobody deletes from becomes a picture
rather than a model.

## The parts

Each part has **one writer**. A part with two writers is a merge conflict
waiting for a session end.

| Part | Lives at | Written by | Grounded in |
|---|---|---|---|
| **The ground** — the goal, the invariants, this file | `docs/design/invariants.md`, `docs/design/architecture.md` | whoever changes the design, through the repo's usual review, **by replacement** | itself; the goal's properties |
| **Inline documentation** — every design decision, implementation decision and capability, in the code it governs | beside the mechanism, in this project's own source | whoever writes the mechanism, in the same commit | the four-slot block below |
| **Secrets** | this repo's `.env`, never committed | each developer, by hand | never in the repo or a model's context |
| **Mechanisms** — the checks that hold the design: tests, lint, CI, hooks | the repo's own tooling; a developer's local tools besides | code; no model in the loop | what a document cannot hold is code: a check, a hook |
| **The engine** — the planning engine: `/api/engine/*` HTTP/SSE, one `fh_engine_turn` per card turn, resolver and agent fills, the compliance pipeline, `usage` metering | `engine/erlang/` | its developers, in commits | P-1–P-6; `docs/architecture/engine-contract.md` |
| **The sidecar** — the planner the engine spawns per fill, over a `{packet,4}` port | `engine/python/` | its developers, in commits | P-3 |
| **The engine database** — `plan_card_events` (the record), `plan_cards`, `usage` events, the `suburbs` + `suburb_sources` tables | Postgres, `ENGINE_DATABASE_URL`; migrations in `engine/erlang/priv/migrations/` | the engine; the suburb tables by the suburb adapters | P-2; `engine-contract.md` §9.1 |
| **The KB** — fact docs, bilingual copy, news notes, blueprints, and the archived primaries they cite | `docs/kb/`, `docs/blueprints/`, `docs/sources/` | the KB update, by hand (`docs/architecture/kb-update-runbook.md`, Track A) | the goal's *regulated figures are grounded* and *bilingual* properties; P-7 |
| **The KB compiler** — gates the KB and emits the artifact the engine loads at boot | `engine/build/kb_compiler.py` → `engine/erlang/priv/kb/artifact.json` | its developers; the artifact by the compiler only — untracked (`.gitignore`), rebuilt from `docs/` at deploy, so git holds the docs and never the artifact | P-7; the goal's *reproducible* property |
| **The suburb adapters** — per-source batch ingest into the suburb tables | `engine/build/suburbs/` | their developers (`docs/architecture/suburb-adapter-workflow.md`, Track B) | the goal's *honest-partial* property |
| **The shell backend** — identity, commerce, the usage gate, the engine proxy | `shell/web/backend/` | its developers, in commits | P-4–P-6; `docs/architecture/billing.md` |
| **The shell database** — subscriptions, `usage_records`, charges, users | Postgres, `SHELL_DATABASE_URL`; migrations in `shell/web/backend/priv/migrations/`, sha256-guarded | the shell backend | P-2, P-5 |
| **The web frontend** — the SvelteKit SPA: map-first home, onboarding, plan projection, chat, the news ticker | `shell/web/frontend/` | its developers, in commits | P-4, P-6, P-7 |

**Where the code is.** One repo: the ground at `docs/design/`, the code
beside it, and the rest of `docs/` the team's (Son, 2026-09-28). The tools read
the whole repo outside `docs/` as code. One indented line in this file narrows
that, and the linter warns (W15) when a path it names is not there:

    code: <path relative to this repo>[, <path>]

Each line below answers one question about this project; a line still
holding its `<…>` template is unanswered, and the linter says so.

**Commit attribution.** Whether this repo's commits carry a Claude trailer is
its team's policy; the launch turns the answer into the harness setting, and
`none` makes the commit hook refuse a trailer. Unanswered, the harness default
— trailer and session link — stands, and the linter warns (W21):

    attribution: <none | co-author | co-author+session>

**The done checks** — the commands that say a step is green, one in backticks
each, `;` between. A step lands once they pass. Unanswered, "green" means nothing
and the linter warns (W23):

    checks: `<command>`[; `<command>`]

**No new record is written to settle a question.** A rule that holds everywhere
becomes a sentence in one of the two ground documents. A rule that holds at one
mechanism becomes a four-slot block beside that mechanism. There is no third
place, and *"we have no record for this yet"* is never a reason to stop — there
is nothing to author first.

**Behaviors.** The unit of work is a behavior — what this system's end user
should see, stated so it can be run, and done when that run is observed on the
real system. An accepted behavior joins the project's suite, so it keeps being
checked; the line names the command that runs them all, or `none yet` (lint
W24 until answered):

    behaviors: `<command>` | none yet

A behavior that needs another repo meets it at a **contract**. Each repo owns
its own behaviors; the provider's contract is runnable on its side, the
consumer checks against recorded examples of it, and a change to it is
announced to each consumer by an issue before it lands. One line per contract:

    contract: <path> provides|consumes <repo>

### The four-slot block

Inline documentation is a part, so it has a shape. Every block names, in derivation order:

    goal property -> invariant -> architecture component -> capability

Top-down it reads as *why this exists*; bottom-up as *what would have to change
for it to be wrong*. Slots are omitted only when genuinely absent, never when
merely unknown.

The **goal property** is one of the properties this project's goal names, and it
is the load-bearing slot rather than the decorative one, because each property
carries its own falsifier (`invariants.md` §The goal). Citing the goal's *id*
would be a constant, and a constant carries no information — the property is the
half a reviewer can dispute.

The **invariant** is one of the four planted, or one of this project's own.

The **architecture component** is one of the parts named above. That is what
makes the table a vocabulary rather than a picture: a comment that cannot name
its part is describing something this file does not model, which is a finding
about this file, not about the comment.

The **capability** is a fact about the runtime, and it carries its measurement —
see below.

There is no decision slot: the code under the block is the decision, and git
holds when and by whom it was made. Why this and not the alternative, where it
matters, is the block's prose.

### The capability slot carries its measurement

A block may assert what the machine, the harness, the stack, the model or a third
party does. **Such a claim carries what was elicited from the thing it is about,
or it is marked `unmeasured` and names the command that would settle it.** Not
because assertion is forbidden — because the unmarked kind is indistinguishable
from the measured kind once written, and the next reader inherits it as fact.

**Three admissible forms, and they are not equal:**

1. **A probe** — a command that was run, quoted with its output and the build or
   OS version it ran against. The only form that settles what the thing *does*.
2. **An artifact read** — a file, binary or setting that was opened, with its
   path. Settles what is *installed*; does not settle runtime behaviour.
3. **Documentation** — the stack's own words, with version and section. This is
   **`documented`, not verified**, and stays so until a probe confirms it.

The list is illustrative, not a fence: anything with the same property qualifies,
because enumerating methods of observation fails the same way enumerating acts
does.

**And the fourth case is the one that costs.** Where nothing was elicited, write
`unmeasured` and the command that would settle it — not *unresolved*, not *open*,
not a question passed to the designer. One of those invites a probe; the other
closes the question with a shrug.

**And it names the state it was taken against**, because otherwise it does not
carry its measurement at all — only the number the measurement produced. A sha
for a repository fact, a clock for a host fact, a build for a harness fact, in
the sentence as written rather than in the commit around it. The test is
re-elicitation: if a reader cannot tell *what to run this against again*, the
claim has already decayed and nobody can see that it has.

Two shapes are exempt, and only these: a claim **dated to an event** is anchored
by the date and must not be refreshed — it says what was true then. A claim
**standing as current** names its state or decays.

**Design and probe define each other.** The design names what must be
probed; a probe that contradicts it is raised as a finding and, once agreed,
corrects the design where the design says it (its ground sentence or block) —
never a workaround in code beside a claim left standing. A capability the
project has never built on is probed against the stack itself — run it, read
its binary or source — before it is designed, and before it is declared
impossible: a missing mention in the documentation is not a missing
capability.

**A probe that settled a capability is kept.** The script, re-runnable, is
tracked in the repo whose code relies on the fact, and the block names its path
beside the result — so re-measuring after a new build is running one file, and a
number the design depends on (a threshold, a floor) can be moved by evidence
rather than by memory. It is never run by the test suite: it costs tokens and
answers about the runtime, not about the code.

**Boundary:** all of this governs claims about things *outside the block's
author*. A claim about what the design intends, or what a decision chooses, has
no thing to ask and is not covered.

## How this repo takes changes

A branch per behavior, a draft PR, Son merges; no CI, CONTRIBUTING or PR
template (probed 2026-10-06). The done checks run from the repo root, offline —
no LLM, no live stack, a few seconds each (all passed at 26f811d). The escript
smokes under `engine/erlang/test/` and `shell/web/backend/test/` need Postgres
and some the planner; a behavior runs the ones it touches. The conformance escripts are the exception: offline, so
`scripts/conformance_sweep.sh` runs all of them as the last done check (about
8 s, measured 2026-10-06), after `kb_compiler.py` has emitted the artifact it
reads.

    checks: `.venv/bin/python tests/validate_build.py`; `.venv/bin/python tests/resolver_eval.py`; `.venv/bin/python tests/eligibility_benefit_eval.py`; `.venv/bin/python tests/cash_duty_eval.py`; `.venv/bin/python tests/mortgage_eval.py`; `.venv/bin/python tests/ownership_eval.py`; `.venv/bin/python tests/bilingual_eval.py`; `.venv/bin/python tests/outcome_validate.py`; `.venv/bin/python tests/shell_contract_check.py`; `.venv/bin/python scripts/doc_links.py docs`; `(cd engine/erlang && rebar3 compile)`; `(cd shell/web/backend && rebar3 compile)`; `(cd shell/web/frontend && npm run check)`; `bash scripts/conformance_sweep.sh`
    attribution: co-author+session
    behaviors: none yet

## The couplings

Read each row as: *when the left changes, the right must follow, by this route,
and this is what makes it follow.* The "Held by" column is the one that matters —
a coupling held by nothing is a hope, and naming it here does not make it hold.

| When this changes | This must follow | By what route | Held by |
|---|---|---|---|
| a verified step completes | it lands as a commit, one concern each | once the `checks:` line passes | prompt, rule 3 |
| a blueprint/mode is added | a `fh_engine_turn:base_components/1` clause, onboarding `blueprint_for`, a `plan_cards.mode` CHECK migration, every shared renderer's shape branch, the `ui_tabs` kind it lands under, and a live seam smoke | by hand, as the mode is built | nothing: a missing slug falls through to Mode A (`fh_engine_turn.erl`), and `006_mode_e.sql` was found missing only by a live POST |
| a KB doc is re-anchored to a new slug or lookup key | every blueprint `KB anchors:` line, plus resolver literals (`fh_engine_mortgage.erl` `?TAX`/`?HECS` and lookup keys, `fh_engine_fill.erl`'s provenance list) and the conformance escripts | grep the old slug across `engine/erlang` | nothing: the compiler cannot see Erlang literals |

Rows two and three: Son agreed 2026-10-06, homed from earlier sessions' memory.

## Design rules

Hold everywhere in this repo (Son agreed 2026-10-06, homed from the harness
memory of earlier sessions):

- **Enforce at chokepoints.** A rule is enforced where every artifact crosses
  (the compiler; the turn's commit seam). The check discovers what to check
  from declared schema rather than an enumerated list, fails closed, and fails
  if it discovers nothing.
- **A unification is a projection.** A new view of the plan is a projection — a
  filter, tab, zoom or overlay — of an existing outcome through an existing
  renderer. A change that needs new renderers to unify views has not found the
  shared primitive.
- **Admission to the decision layer.** A data layer enters the plan or resolver
  only if a component reads it and banding it would not mislead; otherwise it
  stays raw on the surface, for the user to interpret.
- **An honest-partial null carries its reason.** An honest-partial `null` is set
  with a comment at that line saying why the value is absent; a null with no
  reason beside it is treated as a dropped value, not as honest-partial.
- **Non-ASCII Erlang binaries carry `/utf8`.** Every Erlang binary literal
  holding non-ASCII text carries `/utf8`; without it each codepoint truncates
  to one byte and `json:encode` crashes, so VI copy is byte-fragile in both
  Erlang parts. Nothing checks this today.

## What is deliberately not coupled

*Empty at plant.* A thing that looks like it should be coupled and is not is
worth stating, with the reason — otherwise the next reader couples it.

## Where this is unbuilt

*Empty at plant.* What this document describes that does not exist yet, so a
reader can tell a plan from a mechanism.

<!-- planted from the enacs seed @ c38bd97; edit below freely — `plant.py --dry-run` reports what changed upstream -->

## Where this project's existing design lives

Migration input, by path; what is still true moves into these two documents or
into a block beside its mechanism (`/migrate`), and nothing here is ground until it does.

- `docs/architecture/` — 37 design docs; `architecture.md`, `engine-contract.md` and `structure-map.md` are the hubs, and
  `kb-update-runbook.md` + `suburb-adapter-workflow.md` the canonical KB and
  suburb-data processes
- `docs/01-market.md`, `02-competitive-landscape.md`, `03-strategy.md`, `04-ux-model.md` — the strategy set
- `docs/README.md` — the docs index; `docs/local-dev.md` — the local stack how-to
- `docs/blueprints/`, `docs/kb/`, `docs/sources/` — the KB the compiler reads and its archived primaries
- `docs/design/archive/` — superseded history (`05-roadmap.md`, `findings-legacy.md`, `grounding-checklist.md`)
- `git issue list` — the open findings carried out of `grounding-checklist.md` (#1–#6)
- harness memory, `~/.claude*/projects/-Users-son-s2718-firsthomey/memory/` — 76 files,
  no longer loaded; 40 of them are cited from tracked docs as `[[name]]` links
- each contributor's own `CLAUDE.md` (personal, not read by enacs; this repo still tracks one)
