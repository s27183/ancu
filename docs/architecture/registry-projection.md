# Schema-driven registry surface — projecting structured fact entities

**Status:** Design pass (define → simulate → document), pending review before implementation. Specifies how the **resolver-input registry** derives its *referenceable, type-checked token surface* from the fact-model schema **systematically**, replacing the per-entity special-casing that exists today. It unifies the hardcoded `applicant.*` projection with nested objects like `non_buying_partner.*`, and makes every future structured entity automatic.

This is a change to the **materialized foundation** (`engine/build/kb_compiler.py`'s `build_registry`) — the registry every KB rule binds to, and the thing whose hand-reconstruction the registry was built to kill ([[reason-from-materialized-ground]]). It is consumed by the compiler's reference-integrity + type-compat gates and defines what any criterion can reference, so it gets the standalone-rules treatment. Referenced from [`architecture.md` §11.9](architecture.md) (the registry definition) and the compiler header.

Builds on: the registry as it stands (`kb_compiler.py` `Registry` / `field_meta` / `build_registry`), [`fact-model-unification.md`](fact-model-unification.md) (the unified household fact base), [`resolver-semantics.md`](resolver-semantics.md) (the resolver that consumes the projected facts).

---

## The finding in one line

The registry flattens outcome fields **exactly one level** (`outcome_type.field`) and treats anything nested as an **opaque type string**. But the fact model has structure — and the registry *already* projects one nested entity (`applicants[]` → `applicant.*`) through **bespoke, hardcoded code**. `non_buying_partner` is the *same shape of problem* (a structured sub-entity whose fields must be referenceable) that simply never got the same hand-treatment, so `non_buying_partner.ever_owned_au_property` fails reference-integrity (`missing_ns`). The B/C/D + investor roadmap will add more (`guarantor`, `co_buyer`, `existing_properties[]`, `trust_structure`). **Special-casing each one is O(n) manual foundation edits — the exact "hand-reconstructed foundation" failure the registry exists to prevent, relocated one level up.**

---

## DEFINE — the structured-entity projection rule

### 1. A structured fact entity

A **structured entity** is an outcome field whose declared type is a composite of typed sub-fields:

| Declared type | Cardinality | Namespace | Evaluated |
|---|---|---|---|
| object `{ f₁, f₂, … }` (optionally `\| null`) | **singleton** | the field name (`non_buying_partner`) | once, from shared facts |
| `array<{ f₁, f₂, … }>` | **per-element** | a declared singular alias (`applicants` → `applicant`) | per element, ∀-combined |

Each sub-field `fᵢ` becomes a referenceable, type-checked token `namespace.fᵢ`. **`applicant` is reclassified as an instance of this rule** (the `applicants` array entity, alias `applicant`), not a special case. `non_buying_partner` is an instance (a singleton object entity). Every future structured entity is an instance — declare it in the fact-model schema, and its fields are referenceable with **zero compiler edits**.

### 2. Where each entity's typed schema lives (the one dispatch)

Sub-field **types** come from the entity's *authoritative* typed source — and an entity has exactly one:

- **Array entities seeded with a typed parameter element** (`applicants` — the `buyer_profile.applicants` parameter carries the rich typed element + options + seed values). Types from the parameter element. *This is today's `applicant` source, preserved — the parameter is the entity's SOT, so forcing its types into the outcome string would duplicate it (drift).*
- **Object entities declared by a typed nested type-string** (`non_buying_partner`). Types from the type-string, which must therefore carry them: `{ exists: bool, ever_owned_au_property: bool, … }` rather than names-only.

Both forms are "the fact-model schema"; the registry reads whichever the entity uses. A sub-field with no typed source resolves **referenceable but type-unknown** (the existing graceful state — `applicant_fields` already stores `None` for unknown), so the projection never *blocks* on missing types; it just type-checks where types exist.

### 3. The projection (what `build_registry` does)

For each outcome field across all components:
1. parse its declared type; if it's an object or `array<object>`, it is a structured entity;
2. extract its sub-field **names** (and **types**, per the dispatch in §2);
3. register a namespace (singleton or per-element, §1) with those typed sub-fields.

`field_meta(ns, rest)` then resolves `ns` against the projected namespaces uniformly — the `ns == "applicant"` branch dissolves into "is `ns` a projected entity namespace?". The opaque-type-string fallthrough (`non_buying_partner` as a `profile` field) is *superseded* by the projected `non_buying_partner` namespace.

### 4. The resolver side — already generic for singletons

`fh_engine_resolver:resolve_field` already reads `applicant.*` from the per-element map and **every other `ns.rest` from the shared facts namespace** (`maps:get(Ns, Facts)`). So **singleton entities need no resolver change** — `non_buying_partner.*` resolves today, once `eligibility` puts `non_buying_partner` into the facts. Only the *registry* (reference-integrity + typing) blocks it. **Per-element** entities beyond `applicant` (a future `existing_properties[]` with "∀ property …" criteria) would need the resolver to learn the new namespace's per-element cardinality — a **noted extension point**, not built here (no such entity exists yet).

---

## SIMULATE — walk the rule

**W1 — `applicant.*` under the new rule (backward-compat).** `applicants` is an `array<{…}>` outcome field → per-element entity, alias `applicant`, types from the `buyer_profile.applicants` parameter element (exactly today's source). The projected `applicant_fields` map is **identical** to what `build_registry` produces today — same names, same types, same `None`-for-unknown. The special-case became an instance with **no behavioral change**. The four-mode reference-integrity run is the guard.

**W2 — `non_buying_partner.ever_owned_au_property` (the G2 unblock).** `non_buying_partner` is an object outcome field on `profile` → singleton entity, namespace `non_buying_partner`, types from its (enriched) typed type-string → `ever_owned_au_property: bool`. `field_meta("non_buying_partner", "ever_owned_au_property")` → `field, {type: bool}` (was `missing_ns`). A criterion `… eq false` type-checks (bool field, `eq` op). Reference-integrity **green**.

**W3 — a future `guarantor` object.** Add `guarantor: { exists: bool, … }` to an outcome schema. It projects automatically — `guarantor.*` referenceable + typed, **zero compiler change**. The adaptivity criterion, realized.

**W4 — the G2 criterion end-to-end.** `any_of(non_buying_partner.exists eq false, non_buying_partner.ever_owned_au_property eq false)` passes reference-integrity (W2); the resolver evaluates it from `facts.non_buying_partner` (§4, no resolver change); under three-valued, an absent partner field → `undetermined` unless `buyer_profile` projects `non_buying_partner = #{exists => false}` (the single-buyer default), which makes the `any_of` definitely-true (no base-turn noise).

**W5 — boundary: a future per-element `existing_properties[]`.** Projects as referenceable + typed (registry side works), **but** a criterion "∀ owned property: value < X" needs the resolver to ∀-evaluate over `existing_properties` like it does `applicants`. The resolver currently hardcodes `applicant` as the per-element namespace → this needs a resolver cardinality hook. **Flagged, not built** — the trigger is the first per-element entity beyond `applicant` (investor mode, not Wedge 1).

---

## Boundary — where this stops

- **One level of declared nesting, not arbitrary recursion.** It projects the structure the fact model actually declares (outcome → object → fields; outcome → array → element fields). A sub-field that is *itself* a nested object is not recursively projected unless a real entity needs it — match the schema, no more.
- **It does not replace the stringly-typed declarations with a structured schema language.** Outcome types stay type-strings parsed by regex; the projection enriches *nested* strings to carry types. Moving the whole fact model to a structured schema (no regex parsing) is a larger, separate move this does not block — and a reason to keep the projection rule small and legible.
- **Per-element entities beyond `applicant` need a resolver cardinality hook** (W5) — registry-side generality outruns resolver-side generality by one step, deliberately, until a per-element entity exists.
- **Singleton entities are fully unblocked now** — `non_buying_partner` and any future object entity, registry + resolver, no further work.

---

## Backward-compatibility guarantee (the safety property)

> **The projected `applicant_fields` (names + types + `None`-unknowns) and every existing `ns.field` resolution are unchanged; the only *new* resolutions are previously-`missing_ns` nested tokens.**

`applicant` sources types from the same parameter element as today (§2); no existing outcome field changes meaning. So every current KB rule's reference-integrity verdict is identical, across all four modes. The `validate_build` four-mode green run is the executable guard — the artifact's `registry.applicant_fields` must be byte-identical before/after, and the in-scope anchor/type-check counts unchanged (47 KB docs, the current totals).

---

## What changes where (for the tracker — not yet implemented)

| Surface | Change |
|---|---|
| `kb_compiler.py` `build_registry` | generalize the `applicant` projection into a structured-entity projection over all outcome fields (object → singleton ns, `array<object>` → per-element ns); `applicant` becomes an alias instance |
| `kb_compiler.py` `field_meta` | resolve `ns` against projected entity namespaces uniformly; drop the hardcoded `applicant` branch |
| `kb_compiler.py` type parsing | parse typed nested type-strings (`{ f: type, … }`) for object entities |
| fact-model schema (blueprint `profile` outcome) | enrich `non_buying_partner`'s type-string to carry sub-field types |
| `fh_engine_resolver` | **none** for singletons (already generic); a noted cardinality hook for future per-element entities |
| artifact `registry` | gains the projected entity namespaces (e.g. `non_buying_partner.*`); `applicant_fields` unchanged |

**G2 rides on top of this** (the five changes from the prior scoping — KB criteria on the 4 NSW/VIC couple-as-one schemes, the Notes reversal, `buyer_profile`'s `non_buying_partner` default, `eligibility` passing it into facts) once `non_buying_partner.*` is a referenceable, type-checked surface. Closes the G2 blocker and pays down the latent O(n)-special-cases debt in one move.

---

## Mode-B activation update (P0.4, 2026-06-28) — the two namespaces after the off-title generalization

The fact base generalized `profile.non_buying_partner` (scalar) into the canonical `profile.off_title_parties[]` array ([`fact-model-unification.md`](fact-model-unification.md) "Mode-B activation"). Under the projection rule above, that splits the registry surface into **two namespaces from one fact base**, with **no compiler-code change** — both ride the existing structured-entity projection:

- **`off_title_parties` — the array fact (SOT).** Declared `array<{ relationship, counts_for_couple_as_one, ownership_history, funder }> | null` on the `profile` outcome. As an `array<{…}>` field it is **not** auto-projected as a namespace (only `applicant` is aliased today, §1) — referenceable as `profile.off_title_parties`, not `off_title.*`. A per-element `off_title` alias + its **resolver cardinality hook** is the W5 boundary case, built when the N-valued **funder** consumers land (Mode B, P2/P3) — they read the array directly in Erlang.
- **`non_buying_partner` — a derived read-model (a view, not a second fact).** Stays a `{ … }` object field on the `profile` outcome, so the **singleton projection (§1) still produces the `non_buying_partner.*` namespace unchanged** — the 4 NSW/VIC couple-as-one KB criteria keep resolving and type-checking byte-for-byte. Two deltas from the pre-P0.4 source: (a) its types now come from the **inline typed type-string** (`{ exists: bool, ever_owned_au_property: bool, … }`) since the `buyer_profile.non_buying_partner` **parameter block is gone** (replaced by the `off_title_parties[]` param) — the §2 dispatch's "else inline" branch; (b) its **value** is produced by `fh_engine_fill:couple_as_one_view/1`, which filters the array by `counts_for_couple_as_one`, enforces the **dyadic ≤1** invariant fail-closed, and projects the head — the role-flag filter lives in the resolver (Erlang), the KB predicate language stays simple. `non_buying_partner.*` is therefore a **projection of the array**, not an independent entity.

**Backward-compat guarantee holds.** `applicant_fields` is untouched; `non_buying_partner.*` resolves and type-checks identically (inline types replace the param types, same `bool` leaves); the only *new* outcome field is `off_title_parties` (opaque, no namespace yet). The `validate_build` four-mode green run + the artifact `registry` diff are the executable guard (P0.5).
