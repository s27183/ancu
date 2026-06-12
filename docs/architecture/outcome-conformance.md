# Outcome conformance — enforcing invariants that survive workflow change

> **Status: ACCEPTED — build-time half SHIPPED; runtime Layer 1 SHIPPED at 2b-4b**
> (Layer 2, the regulated rider, is 2b-4c; [`compliance-pipeline.md`](compliance-pipeline.md)
> is that layer). Decision owner: Son — all three Open Decisions resolved (§"Resolved
> decisions"). The build-time half is live: the compiler runs a fail-closed bilingual gate over
> every discovered `copy` block (`kb_compiler.py` GATE 8, driven off a single `LOCALES`
> constant), and `tests/bilingual_eval.py` discovers copy docs instead of enumerating them.
> **The runtime half is now built (2b-4b):** `localized_text` is a first-class `outcome_schema`
> type (the compiler emits `registry.outcome_types`, a parsed `{kind}` tree), and
> `fh_engine_outcome:validate/2` runs at the `fh_engine_turn` commit seam (before snapshot,
> fail-closed) walking every field of every fill against its declared type — localized
> (present · non-empty · pairwise-distinct), enum-in-options, and the §98 figure-type guard.
> The pure walk `check/3` is in lockstep with the reference spec `tests/outcome_validate.py`
> (21 shared cases) via `engine/erlang/test/outcome_conformance.escript`, which also proves the
> seam crashes fail-closed against the real artifact. **Layer 2 (2b-4c) then CONSUMES Layer 1's
> figure-type verdict** rather than re-deriving it — 2b-4's ASIC gate needs exactly this
> seam-level post-condition, so the second producer that proves the seam check is the compliance
> pipeline, not 2c (§9).
> Motivated by the bilingual rollout ([`bilingual-content.md`](bilingual-content.md)):
> that work is correct, but its *enforcement* is attached to the current workflow
> (specific producers, a hardcoded copy-doc list, hand-written conformance cases), so it
> must be re-extended every time the workflow changes. This note records the durable
> alternative — attach enforcement to the **invariant**, checked at the two points every
> fill crosses regardless of how it was produced — and the sequencing that gets there
> without throwaway work. Bilingual is the **first clause** of a general property, not a
> special case.

## 0. The problem: enforcement attached to the workflow

Today the "user-facing text is localized" rule is guarded at three places, each tied to a
*workflow detail* rather than the rule:

- `tests/bilingual_eval.py` walks a **hardcoded** `COPY_DOCS` list → a new `kb.copy.*`
  doc is unchecked until someone edits the list.
- `engine/erlang/test/bilingual_conformance.escript` asserts the postconditions over
  **hand-written cases** → a new resolver output field is unchecked until someone adds a
  case.
- `LocalizedText` (Pydantic) forces the agent's `reasoning` to be bilingual — but only for
  a field **typed** `LocalizedText`; a new agent leaf typed `str` is silently English-only.

Every one of these *enumerates what to check*. Enumeration fails exactly when the author of
the next change does not know the rule — which is the normal case as the team and the
surface grow. The same shape already bit us once: the Mode-A blueprint declared an unused
`application.language_preference` input left over from before the bilingual-always decision —
a workflow-attached artifact that nothing updated when the workflow moved on (**removed at
2b-4a**; the B/C/D blueprints still carry it, recorded as a Wedge-2 reconciliation — they are
unbuilt, so the removal rides their build rather than churning them speculatively).

The question this note answers: **what enforcement survives the workflow changing** — new
producers (a Q&A sidecar in 2c, a refine turn, a curator brief), new languages
({vi,en}→{vi,en,zh}), components moving across the resolver/agent boundary?

## 1. The principle: attach enforcement to the invariant, not the workflow

The producers, languages, and components change. The **invariant** does not:

> *Every user-facing text field is localized (present + non-empty in every required locale).*

And — the load-bearing observation — every fill, **whoever produced it**, crosses exactly
two points that are themselves invariant under workflow change:

1. **Build time — the compiler** (`engine/build/kb_compiler.py`). Every KB doc and
   blueprint passes through it; it already materializes the registry and runs structural +
   semantic gates.
2. **Runtime — the outcome-serialization seam** (`fh_engine_turn` commit,
   `fh_engine_turn.erl:180–181`: `snapshot_component` → `emit(component_filled)`). **Every**
   component's output crosses here on its way to `plan_cards.content_jsonb` and the
   `component_filled` event — a resolver fill, an agent merge, a future 2c answer, a refine
   turn, a curator console fill all funnel through this one seam.

   *Verified current state:* this seam performs **no schema-conformance check** today — the
   `Entry` is snapshotted and emitted as-is. That is both why English-only content *could*
   slip through and why the runtime half of this proposal is genuinely new work.

Enforce the invariant at those two points, driven off declared schema, and it holds for any
workflow that routes content through them — which, by construction of the engine, is all of
them.

## 2. The reframe: bilingual ⊂ outcome-schema conformance

The engine already has the right spine: each component declares a typed `outcome_schema`,
and downstream reads **outcomes**, not upstream parameters (architecture constraint #5,
§11.9). So the outcome schema is the natural home for the localization *declaration*, and
"does this fill match its declared outcome shape?" is the natural *check*.

Two moves:

- **Make `localized_text` a first-class type in `outcome_schema`** — declared exactly the
  way fields already carry `"type": "enum" | "integer" | "bool" | "string" | …`. The author
  states intent **in the schema**, not in a test list. A field's localization requirement
  travels with the field.
- **Add `validate(outcome, outcome_schema)` at the seam** (the step missing at
  `fh_engine_turn.erl:180`). It walks every field of the actual fill against its declared
  type:
  - a `localized_text` field → the required locale set is present, each non-empty;
  - an `enum` field → the value is in `options`;
  - a figure → null-or-number, never a string (this *is* the §98 guard, generalized);
  - a `localized_text` requirement is, conversely, **forbidden** on a field typed as a
    figure/enum (catches the inverse error — a number wrapped in `{vi,en}`).

Bilingual correctness then falls out as a **corollary** of a property the engine wants
anyway. That is the adaptive payoff: the same walk later catches enum drift, figure-type
drift, and §98 violations — the machinery is not bilingual-specific, so it does not rot when
the bilingual specifics change.

Note this is a **different axis** from the compiler's existing type-compat gate
(`check_type_compat`, `kb_compiler.py:418`), which checks resolver *rule predicates against
input registry field types* — the input side. Outcome conformance is the **output** side and
is unchecked today at both build and runtime.

## 3. Three properties that make it survive change — each with its boundary

| Property | Why it survives workflow change | Boundary / failure mode |
|---|---|---|
| **Declarative** (schema, not lists/cases) | A new field is checked the instant its schema declares its type — nothing to remember to extend | Only as strong as the schema. An author who declares prose as `"string"` instead of `localized_text` escapes the net. Mitigate: the compiler **reports** any `string`-typed outcome field for human review (a nudge, not a hard fail — some strings are genuinely ids/codes). |
| **Total** (walk every field of every fill) | Coverage is structural, not by-example — a field cannot slip through un-checked | Costs one walk per fill; negligible beside an LLM call. Does not check *register quality* (that VI reads naturally) — that stays a human-curation loop, named honestly, never claimed by the gate. |
| **Locale-set-agnostic** | One declared `LOCALES` constant feeds the compiler gate, the seam check, the generated `LocalizedText`, and the shell's display picker. Adding `zh` = change it in **one** place | The "vi carries a diacritic" anti-fallback is **vi-specific** and must stay an **isolated, named heuristic**. The durable, locale-agnostic anti-fallback is "all required locales present, non-empty, **pairwise-distinct**"; per-locale validators (vi-diacritic, zh-Han-range) plug in beside it and are never the load-bearing rule. |

## 4. Trusted vs untrusted producers — defense in depth where it is earned

The check placement differs by how much the producer can be trusted:

- **Agent (LLM) — untrusted / non-deterministic.** Keep **both** guards: the Pydantic type
  is the *generation-time* constraint (the SDK forces the output shape), and the seam check
  is the *post-condition* (the model could still emit an empty `vi` inside a well-typed
  object). Two layers, because the producer can violate the contract it was handed.
- **Resolver (deterministic Erlang) — trusted.** The seam check alone suffices; there is no
  second producer to disagree with it.

Boundary: defense-in-depth is justified **only** for the untrusted producer. Double-guarding
the resolver would be ceremony — the seam post-condition already fully covers it.

## 5. What it absorbs beyond bilingual — and what it does not

**Absorbs (the adaptive payoff):** because enforcement attaches to `outcome_schema` + the
seam — both invariant under *who produces a field* — these all come for free:

- the resolver↔agent boundary (`agentic-boundary.md`) can move a field from one producer to
  the other and the field stays checked;
- a new producer (2c Q&A, refine turn, curator brief) is covered the moment its output is an
  outcome crossing the seam;
- a new locale is one-line;
- §98 (no LLM-authored figure) becomes a *typed* post-condition, not a prose plea.

**Does not (the boundary):** this is **not** a general runtime type system for all engine
state. It is scoped to *outcomes against their `outcome_schema`* at the one seam. Input
validation, event-envelope validation, and DB-row validation are separate concerns with
their own homes; folding them in here would over-couple. If outcomes were few, stable, and
single-producer forever, this layer would be over-engineering — see §8.

## 6. Single source of truth for the locale set

`{vi, en}` is implicit today (baked into `fh_engine_i18n`, `planner.py`'s `LocalizedText`,
and the eval's diacritic heuristic). The durable form is one declared `LOCALES` — carried in
the compiled artifact (git-authored, consistent with "git is SOT, artifact is the
projection") — read by:

- the **compiler** copy-template gate,
- the **seam** `validate/2`,
- the **generated** `LocalizedText` (Pydantic) and `fh_engine_i18n:localized()` type,
- the **shell**'s display-language picker.

Adding a locale touches `LOCALES` and the per-locale validator registry — nowhere else.

## 7. Fail-closed semantics

A non-conforming outcome at the seam is a **turn error**, not a silently-persisted bad value:
crash the turn (supervised — the OTP idiom; let it surface, don't swallow). The compiler gate
is **fail-closed** the same way: deploy fails. This matches the project's "verifiable property
over asserted" stance — the artifact and the snapshot carry a *checked* post-condition, with
an audit trail of the failure, rather than an assumed-good string.

## 8. Boundary on the whole approach

This earns its cost **precisely under the premise that workflows multiply** — more
producers, more languages, more components. If they were to stay frozen at three producers /
two languages, the cheap point-fix (discover-don't-enumerate + the compiler copy gate, §9
step 1) would be sufficient and the full schema-conformance layer would be over-engineering.
The proposal is right *because* the premise (workflows will change) is asserted; state the
premise with the conclusion so a future reader can re-decide if it no longer holds.

## 9. Sequencing — nothing throwaway

1. **DONE — the build-time half + discover-don't-enumerate** (the cheap lever):
   `tests/bilingual_eval.py` discovers every doc carrying a `copy` block instead of a
   hardcoded list (with a zero-discovery sanity floor); the compiler gained GATE 8
   (`check_copy_template` + `LOCALES`) asserting every `copy` template is well-formed in
   every locale, **fail-closed at deploy** (verified: a vi=en or ASCII-vi injection fails the
   build; reverts clean). 46 templates across 4 docs gated. This closes the most common
   future edit (curators adding/editing copy) and is **literally the build-time half of this
   design** — a down-payment, not a patch to rip out.
2. **With 2b-4 (the compliance pipeline) — the runtime half**: introduce `localized_text` in
   `outcome_schema`, generate `LocalizedText` + the type from `LOCALES`, and add
   `validate(outcome, outcome_schema)` at the `fh_engine_turn` commit seam as the general
   outcome-conformance step (bilingual being its first clause). **2b-4 — not 2c — is the
   proving producer:** the ASIC gate ([`compliance-pipeline.md`](compliance-pipeline.md)) needs
   a seam-level post-condition that the agent's output stays decision-support (no LLM-authored
   figure — §98), and that post-condition is the *figure-type* clause of this same validator.
   So the regulated layer **consumes** Layer 1's verdict rather than re-deriving it: one source
   of truth for "this outcome conforms," two readers (the structural fail-closed crash, and
   ASIC's regulated attestation). Building it now proves the seam check against a real second
   consumer — exactly the non-speculative trigger §8 asks for — and it arrives a slice earlier
   than the original 2c plan because a regulated consumer materialized first.

   **The two layers, ordered at the seam** (full regulated detail in
   [`compliance-pipeline.md`](compliance-pipeline.md)):
   - **Layer 1 — `validate(outcome, outcome_schema)`** (this note): structural, producer- and
     mode-agnostic, **fail-closed crash** on any non-conformance. Runs first.
   - **Layer 2 — FIRB→ASIC→AML** (the compliance note): regulated dispositions + the
     `audit_events` trail; ASIC reads Layer 1's figure-type verdict. Runs second, on a
     Layer-1-conforming outcome.

## 10. Worked simulation (define → simulate)

Walk concrete *future* changes through the design; show the enumerate-approach misses each.

| Future change | Outcome-conformance | Enumerate-approach (today) |
|---|---|---|
| Curator adds `kb.copy.firb.md` | Compiler gate validates its templates at deploy — **caught** | Unchecked until someone adds it to `COPY_DOCS` |
| 2c Q&A sidecar emits an `answer` field declared `localized_text`, English-only | Seam `validate/2` fails → turn fails closed — **caught** | No conformance case exists → **slips through** |
| Add `zh` for a new diaspora segment | Change `LOCALES`; all four sites + per-locale validator update from it | Edit the diacritic heuristic, every eval, every Pydantic type by hand |
| Move a field resolver→agent (boundary shift) | Field keeps its `outcome_schema` type → still checked at the seam — **caught** | Conformance case was written against the resolver output → **goes stale** |
| Author declares prose as `"string"` (mistake) | Compiler **reports** it for review (the §3 declarative boundary) | No signal at all |

## 11. What this is NOT

- **Not** a bilingual-only mechanism — bilingual is one clause of outcome conformance.
- **Not** a general runtime type system — scoped to outcomes-vs-`outcome_schema` at one seam
  (§5 boundary).
- **Not** a register-quality check — that fluent-VI quality bar is a human-curation loop,
  not a gate (§3 boundary).
- **Not** a replacement for the agent's Pydantic schema — it *complements* it (§4
  defense-in-depth for the untrusted producer).

## 12. Situate in the engine

- **Spine reused:** `outcome_schema` as the typed interface (constraint #5, architecture
  §11.9); the compiler's existing gate suite; the `fh_engine_turn` commit seam.
- **Relates to:** [`bilingual-content.md`](bilingual-content.md) (the first clause + the
  classification rule for *which* fields are localized), [`engine-contract.md`](engine-contract.md)
  (content-language engine-owned, §8/§9.2), [`agentic-boundary.md`](agentic-boundary.md)
  (the resolver/agent boundary this makes movable), §98 (becomes a typed post-condition).
- **Index wiring (done at 2b-4c, when the pair completed):** [`structure-map.md`](structure-map.md)
  gained a **commit-seam compliance** node in the inventory (both layers) + an `audit_events`
  entity in the Plane-4 persistence ER + cross-links from Plane 3. The `docs/README.md` table was
  deliberately **not** extended: it indexes the major architecture/strategy docs, not the tier of
  implementation design notes (eligibility-resolution, mortgage-finance-two-path, bilingual-content
  are likewise absent) — adding only these two would be inconsistent. The hub (structure-map) is
  the right home for built-structure discovery; CLAUDE.md and the grounding-checklist carry the
  pointers.

## Resolved decisions (Son, at 2b-4)

1. **Runtime half timing → build now, with 2b-4.** The original §9 deferred it to 2c "the
   first new producer that proves it." A regulated consumer (the ASIC gate) materialized
   first and needs exactly this seam post-condition, so 2b-4 *is* the proving producer.
   Built now, not speculatively — the §8 premise (a real second consumer) is satisfied by the
   compliance pipeline.
2. **`localized_text` → a distinct `type` value** (not a `"localized": true` flag on a
   `string`). The total-walk reads one type per field; a distinct type makes the inverse error
   (§2 — prose-localization on a figure/enum) a plain type mismatch the walk already catches,
   rather than a flag someone forgot. Slightly larger spec change, paid once.
3. **`LOCALES` → a top-level key in the compiled artifact** (not engine config). Git stays
   SOT; the artifact snapshots it into every fill's audit trail; the compiler gate, the seam
   `validate/2`, the generated `LocalizedText`, and the shell picker all read the one value
   (§6). Per-locale validators (the vi-diacritic heuristic) sit in an isolated registry beside
   it, never load-bearing (§3).
