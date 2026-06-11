# Resolver semantics — three-valued evaluation over partially-known facts

**Status:** Design pass (define → simulate → document), pending review before implementation. 2026-06-11. Specifies a **three-valued (Kleene) resolver** over a fact model that represents *partial knowledge*. Supersedes the bi-state (`true`/`false`, absent → `false`) semantics of the current resolver (`fh_engine_resolver` / its spec `tests/resolver_eval.py`).

This is **cross-cutting**, not eligibility-specific: the same rules feed both the `eligibility` advisory fill and the FIRB/ASIC/AML **compliance gate**, and the two must not drift on what a partially-known fact *means*. So it lives standalone (per the standalone-rules discipline) and is referenced by [`eligibility-resolution.md`](eligibility-resolution.md) (the advisory consumer) and the engine compliance gate (the fail-closed consumer).

Builds on: [`agentic-boundary.md`](agentic-boundary.md) (the resolver is deterministic predicates over structured inputs), [`fact-model-unification.md`](fact-model-unification.md) (the accumulating household fact base — *partial knowledge is its steady state*), the interpreter [`fh_engine_resolver`](../../engine/erlang/src/fh_engine_resolver.erl) and its executable spec [`resolver_eval.py`](../../tests/resolver_eval.py).

---

## The finding in one line

A fact at base is often **partially known** — constrained but not pinned (citizenship is the *set* `{citizen, permanent_resident}` under Mode A; age is the *range* `≥ 18`; `prior_fhss_release` is *absent*). The current resolver is bi-state and collapses every non-scalar to a definite verdict: **absent → `false`**. That is correct for a *gate* (deny on doubt) but **wrong for advisory presentation** — it tells a fact-less Mode-A buyer they are *ineligible* for FHG when we simply have not asked their citizenship yet. And it **cannot represent** the one thing Mode A actually guarantees: citizen-*or*-PR, which makes `in [citizen,PR]` definitely-true while `eq citizen` stays unknown. Bi-state forces those two to the same (wrong) answer.

Partial knowledge is **not an edge case** — the lifecycle moat *is* "facts accumulate over time," so every refine turn moves facts from undetermined → determined. Modeling `undetermined` is modeling the domain, not future-proofing.

---

## DEFINE — the semantics

### 1. Facts carry possibility, not just value

Every fact is a **possibility set** `L` — the values it could be, given what we know:

| Representation | Meaning | Example |
|---|---|---|
| **scalar** `s` | pinned — a singleton `{s}` | `ever_owned_au_property = false` |
| **set** `[s₁…sₙ]` | one of these, unknown which | `citizenship_status = {citizen, permanent_resident}` (Mode A) |
| **range** `[lo, hi]` | an interval over an ordered domain | `age = [18, ∞)` (adult buyer) |
| **absent** (key missing) | fully unknown — the universe `⊤` | `prior_fhss_release`, `assessable_income` at onboarding |

A scalar is the degenerate possibility set. This is the **only** new structure the fact base needs; it is not a constraint solver.

### 2. A predicate over a possibility set is three-valued

For criterion `(field op rhs)`, let `L` be the field's possibility set and `sat(p) = (p op rhs)` the ordinary two-valued predicate at a concrete `p`:

- **`true`** — `sat(p)` holds for **all** `p ∈ L`
- **`false`** — `sat(p)` holds for **no** `p ∈ L`
- **`undetermined`** — otherwise (some do, some don't)

Evaluated structurally by `L`'s representation (never by enumeration):

| `L` | `eq R` | `in [..]` | `gte R` | `lte R` |
|---|---|---|---|---|
| scalar `s` | `s==R` | `s∈[..]` | `s>=R` | `s<=R` | ← **two-valued, unchanged** |
| set `S` | all/none/some of `S` `== R` | `S⊆`/`S∩=∅`/mixed | — (sets are unordered) | — |
| range `[lo,hi]` | `lo=hi=R` / `R∉[lo,hi]` / else | degenerate only | `lo≥R` / `hi<R` / else | `hi≤R` / `lo>R` / else |
| absent `⊤` | undetermined | undetermined | undetermined | undetermined |

Two further sources of `undetermined`, both load-bearing:

- **`rhs` is null/unresolved** (e.g. the FHG cap `lookup` returns its `null` default when `location_tier` is absent) → the criterion is `undetermined`. This **structurally kills the G3 hazard**: under bi-state, `price ≤ null` is *spuriously true* (a number sorts below every atom in Erlang term order); under three-valued, a null threshold is "can't decide" → `undetermined`, never a spurious pass. *(The eligibility component still intercepts property-price criteria for the richer banded disposition — decision 5 there — but the resolver is now safe even if one slips through.)*
- **absent fact** → `undetermined` (this is the change from bi-state's absent → `false`).

### 3. Combinators are strong Kleene (K3)

```
all_of(children) =  false         if any child is false        ← definite disqualifier wins
                    undetermined  else if any child undetermined
                    true          else
any_of(children) =  true          if any child is true         ← definite qualifier wins
                    undetermined  else if any child undetermined
                    false         else
```

The short-circuits are the safety property: a scheme with **one definite disqualifier** is `false` (rejected) **even amid pending siblings** — "pending" never masks a real rejection. Symmetrically a definite qualifier in an `any_of` wins over an unknown sibling.

### 4. The verdict is policy-free; each consumer supplies a collapse

The resolver returns `true | false | undetermined` (plus, for the advisory consumer, the **set of undetermined criteria** — the "why pending" trace). It applies **no** disposition policy. The consumer does:

| Consumer | `true` | `false` | `undetermined` |
|---|---|---|---|
| **`eligibility`** (advisory) | applicable | rejected (reason) | **applicable-pending** — carry the missing-fact note ("confirm you are a citizen, not PR"); **never a hard reject** |
| **compliance gate** (FIRB/ASIC/AML) | clear | deny | **fail-closed → deny** (deny on doubt); reads the trace to say *what* it needs |

This is the principled split the bi-state model hid: `absent → false` is right for the gate and wrong for advisory. Three-valued **names** the distinction — same rules, two collapse policies, by consumer. The gate is **not loosened**; it receives a richer input and still fails closed.

### 5. The backward-compatibility guarantee (the migration-safety property)

> **If every referenced fact is a pinned scalar, the three-valued resolver returns exactly the bi-state resolver's `true`/`false` and never `undetermined`.**

Proof sketch: scalar `L` is a singleton, so every operator row reduces to `sat(s) ∈ {true,false}`; K3 combinators over only `{true,false}` children reduce to `all`/`any`. ∎

Every current `resolver_eval.py` case uses scalar facts → **all stay green, unchanged**. The conformance suite *is* the guard for this property. The only behavioral change touching existing data is *absent → `undetermined`* (was `false`), and no current case relies on absent → `false`.

---

## SIMULATE — walk the semantics

**W-A — Mode-A base turn (NSW, target `[600k, 700k]`, the actual onboarding facts).** `buyer_profile` projects: `citizenship = {citizen,PR}`, `ever_owned = false`, `currently_owns = false`, `owner_occupier_intent = true`, `age = [18,∞)`; `prior_fhss_release`, `assessable_income` absent; `property_fit.price` absent (→ banded).

- **FHG**: `in [citizen,PR]` over `{citizen,PR}` → **true**; `age gte 18` over `[18,∞)` → **true**; `any_of(ever_owned eq false → true, …)` → **true**; `owner_occupier_intent` → **true**; price → component-banded (`hi 700k ≤ both NSW caps`) → **true**. `all_of` → **true** → **eligible**.
- **Help-to-Buy**: `citizenship eq citizen` over `{citizen,PR}` → **undetermined**; rest true. `all_of` → **undetermined** → **applicable-pending** ("confirm Australian citizen vs PR"); plus income cap (absent → undetermined) and `alternative_to FHG` → presented as the conditional alternative.
- **FHSS**: first three true; `prior_fhss_release eq false` over absent → **undetermined**. `all_of` → **undetermined** → **applicable-pending** ("confirm you haven't previously released FHSS savings").
- **NSW FHBAS** (selected by `state=NSW`): `state eq NSW` true; applicant tests true; `price lte 1,000,000` banded (`hi 700k ≤ 1M`) → **true**. → **eligible**.

Result: FHG + NSW concession **eligible** (`eligibility_basis = all_applicants_eligible`); FHSS + Help-to-Buy ride **applicable-pending** with confirm-notes. The honest base-turn outcome — *no* outcome-schema enum change, *no* one wrongly rejected. (Bi-state gave all four **ineligible**.)

**W-B — prior owner, unknown when (the "undetermined, not false" case).** Refine turn: `ever_owned = true`, `years_since_last_au_property_interest` absent. FHG's nested `any_of(ever_owned eq false → false, years_since gte 10 → undetermined)` → **undetermined** → FHG **pending** ("confirm whether 10+ years since you last held property"). Bi-state gave **false** — wrongly ineligible for someone who may qualify under the 10-year rule.

**W-C — full scalar facts = an existing conformance case (backward-compat).** `fhg-single-eligible-under-cap`: every fact scalar, `location_tier` present → every criterion two-valued → `fhg.eligible = true`, identical to today, no `undetermined` arises. The guarantee in §5, executable.

**W-D — F13, two applicants, per-applicant + three-valued.** FHSS `resolution: per_applicant`. A `{age 30, ever_owned false, oo true, prior_fhss false}` → **true** (eligible). B `{ever_owned true, …}` → `ever_owned eq false → false` → `all_of` **false** (short-circuits over any pending sibling). → `eligible_applicants = [A]`. Bi-state joint-∀ gave **false** for the household; per-applicant + K3 gives "A releases." F13 closes, and composes cleanly with three-valued.

**W-E — gate collapse (fail-closed).** A temp-resident applicant of unknown visa subclass → `firb_required` resolves **undetermined**. The compliance gate collapses **undetermined → deny** → routes to the FIRB-required path (does *not* assume "no FIRB needed"). Same fact, opposite collapse from the advisory consumer — the §4 split, realized.

---

## The resolver-eval contract change (`tests/resolver_eval.py` + the Erlang port)

`resolver_eval.py` is the executable spec; `fh_engine_resolver` is its 1:1 Erlang port; `resolver_conformance.escript` asserts they agree. All three move together:

1. **`_cmp` → three-valued over possibility sets.** Input `lhs` is a possibility set (scalar still allowed and is the singleton case); returns `TRUE | FALSE | UNDET` (a sentinel distinct from `None`, which already means "missing" / lookup-default). `rhs is None → UNDET`. Scalar-`lhs` rows return plain `TRUE/FALSE` (the §5 reduction).
2. **`_criteria` combinators → K3** (`all_of`/`any_of` per §3). `_criteria_joint` stays ∀ for **joint** schemes; **per-applicant** schemes (FHSS, by the KB `resolution` marker) return per-applicant verdicts / `eligible_applicants` (the F13 close).
3. **`leaf()` return type widens** to three-valued; the harness's expected values gain `UNDET` where a fact is partial. Consumers (not the resolver) collapse.
4. **New CASES** (the partial-knowledge cases that pin the new semantics): a set-valued citizenship case (`eq citizen → UNDET`, `in [citizen,PR] → TRUE`), an absent-fact case (`→ UNDET`, not `False`), the W-B prior-owner-unknown-years case, and a null-`rhs` (absent-`location_tier`) case (`→ UNDET`, proving G3 is structurally safe). **Existing scalar CASES are unchanged** — they are the §5 guard.
5. **F13 xfail** is reframed: with `resolution: per_applicant` + three-valued, `fhss-two-applicants-one-qualifies` expects `eligible_applicants = [A]` (or a per-applicant verdict) → **XPASS / close**.

The Erlang `fh_engine_resolver` mirrors each: a three-valued result type (`true | false | undetermined`), K3 in `criteria/5`, `cmp/3` over possibility sets, `undefined`-rhs → `undetermined`. `resolver_conformance.escript` carries the same new cases.

---

## Boundaries — where this stops holding

- **Not probabilistic.** `undetermined` is "could be either," not a likelihood. No Bayesian weighting; the resolver stays a deterministic, auditable function.
- **Only criteria gain three-valued.** `lookup`/`parameter` are value producers, unchanged; a `null` they produce makes the *consuming criterion* `undetermined` (§2), it does not make the lookup itself three-valued.
- **The gate is not loosened.** Three-valued is a richer *input* to the compliance gate; the gate's collapse is still fail-closed (§4). Anyone reading this as "undetermined lets a foreign buyer through" has inverted it.
- **Possibility sets are minimal:** scalar | set | range | absent. Not arbitrary predicates over facts; if a fact needs richer structure, that is a separate decision.
- **`buyer_profile` must project possibility sets** (Mode A → `citizenship = {citizen,PR}`, `age = [18,∞)`, FHB scalars) for the base turn to resolve as W-A. *What* mode A guarantees (definitional) vs assumes (operational, e.g. age ≥ 18) is a `buyer_profile` decision documented there — the resolver consumes the sets without caring about provenance.

---

## What changes where (for the tracker — not yet implemented)

| Surface | Change |
|---|---|
| `tests/resolver_eval.py` | three-valued `_cmp`/`_criteria`, possibility-set facts, new CASES, F13 reframe (the spec moves first) |
| `engine/erlang/src/fh_engine_resolver.erl` | 1:1 port of the above (three-valued result, K3, `undefined`-rhs → `undetermined`) |
| `engine/erlang/test/resolver_conformance.escript` | the same new cases; F13 XPASS |
| KB scheme docs | per-scheme `resolution: joint \| per_applicant` marker (only FHSS is `per_applicant`); recompile |
| `eligibility` consumer ([`eligibility-resolution.md`](eligibility-resolution.md)) | collapse `undetermined → applicable-pending` + missing-fact note; decisions 1/3 updated for three-valued |
| compliance gate consumer | collapse `undetermined → deny` (fail-closed); reads the trace for "what's needed" |
| `buyer_profile` fill | project Mode-A possibility sets (citizenship set, age range, FHB scalars) |

**Findings:** **G3 structurally closed** (null-`rhs` → `undetermined`, no spurious pass). **F13 closes** via `resolution` marker + per-applicant + K3. The bi-state `absent → false` is retained *only* as the gate's collapse policy, not as resolver behavior.
