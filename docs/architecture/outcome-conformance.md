# Outcome conformance — enforcing invariants that survive workflow change

> **Status: PROPOSED — §9 step 1 (build-time half) IMPLEMENTED; runtime half pending 2c.**
> Decision owner: Son. The build-time half is live: the compiler runs a fail-closed
> bilingual gate over every discovered `copy` block (`kb_compiler.py` GATE 8, driven off a
> single `LOCALES` constant), and `tests/bilingual_eval.py` discovers copy docs instead of
> enumerating them. The runtime half (`localized_text` in `outcome_schema` + `validate/2` at
> the `fh_engine_turn` seam) is recorded below and folds into 2c (§9 step 2).
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
surface grow. The same shape already bit us once: the blueprint still declares an unused
`application.language_preference` input (`fhb-domestic-au.md:124`) left over from before the
bilingual-always decision — a workflow-attached artifact that nothing updated when the
workflow moved on.

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
2. **With 2c (first new producer) — the runtime half**: introduce `localized_text` in
   `outcome_schema`, generate `LocalizedText` + the type from `LOCALES`, and add
   `validate(outcome, outcome_schema)` at `fh_engine_turn.erl:180` as the general
   outcome-conformance step (bilingual being its first clause). 2c is the right trigger
   because a second producer is exactly what the runtime seam-check exists to cover —
   building it then proves it against a real second producer rather than speculatively.

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
- **Index wiring deferred:** when implemented, add an entry to `docs/README.md` and a node to
  [`structure-map.md`](structure-map.md) (the coherence hub maps *built* structures); this
  note is a proposal until then.

## Open decisions for Son

1. **Build the runtime half with 2c (recommended) or sooner?** §9 sequences it with 2c as
   the first producer that proves it.
2. **`localized_text` as a new `type` value, or a `"localized": true` flag on a `string`
   field?** A distinct type is cleaner for the total-walk; a flag is a smaller spec change.
   (Leaning: distinct type — it makes the inverse error in §2 a type mismatch, not a missing
   flag.)
3. **Where does `LOCALES` live** — a top-level key in the compiled artifact, or engine
   config? (Leaning: artifact — keeps git as SOT and snapshots it for the audit trail.)
