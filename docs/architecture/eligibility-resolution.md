# Eligibility resolution — the base (property-agnostic) scheme stack

**Status:** Design pass (define → simulate → document), pending review before implementation. This specifies how the `eligibility` component resolves the `scheme_stack` outcome at **base scope** (no property attached) from `profile` facts + `target_price_range`. It is the load-bearing classification piece of the 2b-2b resolver remainder, and it touches three open findings (F1 all-applicants, F7 banded, F13 FHSS-individual), so it gets the standalone-rules treatment rather than on-the-fly code.

Builds on: [`agentic-boundary.md`](agentic-boundary.md) (eligibility is **resolver** — predicates over structured inputs), [`fact-model-unification.md`](fact-model-unification.md) (the `applicants[]` fact surface + `firb_required_any`), the interpreter [`fh_engine_resolver`](../../engine/erlang/src/fh_engine_resolver.erl) (the `criteria`/`lookup`/`parameter` evaluator, conformant to [`resolver_eval.py`](../../tests/resolver_eval.py)), and the blueprint [`fhb-domestic-au.md` §3](../blueprints/fhb-domestic-au.md). Scenario register: [`scenarios.md`](../blueprints/scenarios.md) (S1/S4/S5/S8/S9/S10/S15/S16).

---

## The finding in one line

The base `eligibility` fill is **not** a thin wrapper over each scheme's `eligible` rule: at base there is **no property**, yet every scheme's criteria mix **property-agnostic** predicates (the `applicant.*` tests) with **property-dependent** ones (`property_fit.price`, `property_fit.property_type`, `location_tier`). Running a scheme's rule as-is would feed `undefined` to the property criteria and the conservative resolver would compute **spuriously ineligible** for everyone. So the component must **decompose** each rule into a base partition (evaluate now) and a property partition (defer / band), and combine per-applicant and per-scheme semantics correctly.

---

## Update (2026-06-11) — three-valued resolution, and the base-turn fact gap

Implementing this surfaced a seam the original pass missed: the **base onboarding turn** carries only `{state, target_price_range, target_zone, intent}` + mode A — **not** the applicant facts (citizenship, age, ownership history, income, `prior_fhss_release`) that every walk W1–W6 below assumes. Those walks are **refine-turn** cases; the base turn has only mode-implied facts. Running the criteria against absent facts under the original **bi-state** resolver yields conservative `false` → a fact-less Mode-A buyer is classified *ineligible for everything*.

The fix is a **three-valued (Kleene) resolver over partially-known facts**, specified standalone in [`resolver-semantics.md`](resolver-semantics.md) (standalone because the compliance gate consumes the same rules under a different collapse policy, and the two must not drift). It changes three things below:

- **Decision 1** — a fact can now be a **possibility set** (Mode A → `citizenship = {citizen,PR}`, so `in [citizen,PR]` is definitely-true while `eq citizen` is `undetermined`), and the **G3 null-cap hazard is structurally closed**: a null threshold (`rhs`) → `undetermined`, never a spurious pass. The component still intercepts property-price criteria for the banded disposition (decision 5), but is no longer the *only* thing standing between a null cap and a wrong answer.
- **Decision 3** — `eligibility_basis` gains no enum value; instead a scheme whose base criteria resolve `undetermined` (some required fact pending) is reported **applicable-pending** with a missing-fact note ("confirm you are a citizen, not PR"), riding in `applicable_schemes[].notes` — **never a hard reject**. `all_applicants_eligible` still holds for the firmly-eligible schemes (FHG, state concession resolve `true` under Mode-A projection).
- **Decision 2 / F13** — per-applicant FHSS composes with three-valued: an applicant with a definite disqualifier is `false` (short-circuits over pending siblings); the household reports `eligible_applicants`. See the W-D walk in `resolver-semantics.md`.

`buyer_profile` must project the Mode-A possibility sets for the base turn to resolve correctly; that projection (definitional guarantees vs operational assumptions) is a `buyer_profile` decision. The decisions below stand as written for the **refine turn** (facts present); read them through the three-valued lens for the base turn.

## Update (2026-06-17) — state is a projection axis (the suburb), not the browse filter

A saved card surfaced with `onboarding.state = "ALL"` (the map's all-states browse filter, persisted as the plan-card state) + `target_zone = ["East Melbourne"]`. Decisions 1 & 7 below assume `property_fit.state` **is** the onboarding state (*"the buyer buys in their state"*) — but `"ALL"` is not a state, so `state_catalog("ALL") = []` and every state-specific scheme (duty concession, FHOG, the FHG cap tier) silently drops, no matter how correct the resolver. This is **map-first by design**, not a data error: the user browses all states and pins a suburb; the suburb (East Melbourne) unambiguously *is* the state (VIC).

**The clarification (aligned with plan-first + map-first):** state-specific schemes are **per-suburb projection content**, never a frozen card attribute.

- **Plan-first** — the base plan's **invariant core** (eligibility predicates, FHSS, Help-to-Buy, federal FHG eligibility) is state-agnostic; it generates from mode + price + zone, no property.
- **Map-first** — the **state slice** (state duty concession, FHOG, FHG cap tier) resolves from the **projection suburb's state** (the suburb you view; default = the onboarding zone). `onboarding.state` is demoted to a **map browse-filter** that scopes which suburbs the map shows; it **never gates the scheme stack**. The `suburbs` table is the authority on suburb→state.

**Scope — two layers, both already-deferred shapes:**
- **Now (zone-default projection):** the projection state = the onboarding **zone's** suburb state (East Melbourne → VIC), resolved via `suburbs`. Refines Decisions 1 & 7 below.
- **Later (per-suburb overlay, deferred):** re-resolve the state slice per *viewed* suburb (uniform within a state → ≤8, resolver-only). The FHG cap tier rides the same axis ([`PlanProjection`](../../shell/web/frontend/src/lib/PlanProjection.svelte) already defers the zone→suburb overlay).

**Both `fh_engine_eligibility` and `fh_engine_cash` consume the projection state** (cash gates the duty concession on it too), so it is one **derived value** both read via a shared helper — never two independent reads of `onboarding.state`.

---

## The resolution decisions (DEFINE)

> Decisions 1–7 resolve *which* schemes apply (predicates, banding, basis); **Decision 8** (added 2026-06-17) quantifies the benefit **dollars** — the stance change from qualitative-at-base to quantitative-where-grounded; **Decision 9** (added 2026-06-17) extends the same stance to the `budget_envelope` **NEED side** (deposit + duty + other costs → `total_cash_required`, all `money_range`; HAVE side + verdict stay PENDING by design). The **2026-06-17 state-projection update** (above) refines Decisions 1 & 7: `property_fit.state` is the *projection suburb's* state, not the browse filter.

### 1. The base-knowable field set — what can be evaluated without a property

Partition every criterion by its field token:

| Field | At base | Handling |
|---|---|---|
| `applicant.*` (citizenship, age, ownership history, intent, prior_fhss_release, …) | **known** (from `profile.applicants[]`; thin at onboarding, enriched by chat) | evaluate via the interpreter |
| `property_fit.state` | **known** = the **projection suburb's state** (default: the onboarding *zone*'s suburb), via the `suburbs` table — **not** the browse-filter `onboarding.state`, which may be `ALL` (2026-06-17 update) | supply to the interpreter |
| `property_fit.price` | **unknown** — substitute `target_price_range` | **banded check** (decision 5) |
| `property_fit.property_type` | **unknown** (no property) | **defer** — scheme is *conditional on type* (decision 6) |
| `location_tier` | **unknown** (needs the suburb) | FHG cap becomes a **state-band range** (decision 5) |

**Why not just let the lookup default fire.** The FHG cap `lookup` returns `null` when `location_tier` is absent, and the price criterion is `price lte ref:cap`. In Erlang term order a number sorts *below* every atom, so `1_200_000 =< null` is **true** — a null cap would make the price check spuriously *pass*. The component must therefore never hand a property-dependent criterion to the raw evaluator at base; it intercepts them per this table.

**Decomposition mechanism (decision, grounded in the existing data):** the component partitions a scheme's `criteria` tree by the field-token table above — **no KB re-authoring**. The base partition (all `applicant.*` + `property_fit.state` criteria) is evaluated by the interpreter; the property partition is routed to the banded/deferred logic. The field namespace *is* the signal; encoding a redundant `scope` tag per criterion in the KB is rejected (it would duplicate what the namespace already says, and drift from it).

### 2. Per-scheme combine semantics — JOINT vs INDIVIDUAL (closes F13)

A scheme's benefit is either **joint** (accrues to the application — every applicant must qualify) or **individual** (accrues per-person independently):

| Scheme | Resolution | Why |
|---|---|---|
| FHG, FHOG, state concessions, Help to Buy | **joint** — ∀ over `applicants[]` (+ `non_buying_partner`, decision 4) | one property, one application; the benefit is the purchase's |
| **FHSS** | **per-applicant** — each applicant holds their own super; `eligible_applicants[]`, release = **sum** of eligible applicants' releases | individual super accounts release independently |

This is the **F13 close**: FHSS today is one joint bool with ∀ semantics, which reads a two-applicant/one-qualifies household as ineligible. Per-applicant resolution makes it "applicant A releases." The discriminator is a new per-scheme **`resolution: joint | per_applicant`** marker (KB metadata, decision 7) — *not* inferred, so it is auditable.

> **Conformance signal:** when this lands, `resolver_eval.py`'s `fhss-two-applicants-one-qualifies` xfail flips to **XPASS** (and the Erlang `resolver_conformance.escript` likewise). That flip is the executable close-criterion for F13.

### 3. `eligibility_basis` — the all-applicants verdict (F1)

For each **joint** scheme, the ∀ over applicants yields one of:

- **`all_applicants_eligible`** — every applicant passes the base partition.
- **`eligible_only_if_restructured`** — the joint application fails, but a **subset** of applicants would pass alone → populate `structuring_options` (decision 4).
- **`ineligible`** — no qualifying subset.

`scheme_stack.eligibility_basis` is the **application-level** roll-up (the strongest basis across the applicable schemes). Per-scheme detail rides in `applicable_schemes[].notes` / `rejected_schemes[].reason`.

### 4. Structuring options + the FIRB branch + the non-buying partner (F1, F4)

- **Subset analysis (F1, S1/S4):** when a joint scheme fails the ∀ but passes for a subset (e.g. the non-foreign lead alone), emit `structuring_options: [{if_purchased_as: "lead applicant alone", applicable_schemes, benefit_value, tradeoffs}]`. The tradeoff (lower serviceability on one income) is narrative; the figure is `mortgage_finance`'s downstream concern.
- **FIRB branch (constraint #10):** if `profile.firb_required_any` is true, FHB schemes are unavailable to the joint application; the foreign applicant's interest routes to the FIRB path (`fhb-foreign-au`). This is surfaced as a `structuring_options` note **and** is the engine compliance gate's concern (decision 7 — the gate is engine-owned; eligibility states the consequence).
- **Non-buying partner fold-in (F4, S10):** for **couple-as-one** schemes (FHOG, state concessions), the partner's ownership counts even though they hold no legal interest. **Finding:** the current criteria reference only `applicant.*` — they do **not** read `non_buying_partner.*`. So the fold-in needs either (a) the criteria to add a `non_buying_partner.ever_owned_au_property` term for couple-as-one schemes, or (b) the component to inject the partner as a synthetic applicant for those schemes' ∀. **Recommendation: (a)** — it keeps the rule auditable in the KB and the partner's *non-occupancy* explicit (the partner fails `owner_occupier_intent`, so a naive synthetic-applicant injection would wrongly fail the scheme on intent). This is a KB-criteria addition, flagged below.

### 5. The banded price check (F7) — `max_eligible_price`

The property-price criterion (`property_fit.price lte X`) becomes a band comparison of `target_price_range = [lo, hi]` against the threshold `X`:

| target vs X | disposition | reported |
|---|---|---|
| `hi ≤ X` | **fully within cap** | eligible |
| `lo > X` | **above cap** | price-ineligible (narrative: "cap is $X") |
| `lo ≤ X < hi` | **straddles** | eligible up to `max_eligible_price = X` |

- For **fixed-threshold** schemes (FHBAS, FHOG price caps) `X` is the scheme's price-cap parameter.
- For **FHG**, `X = applicable_cap(state, location_tier)` and `location_tier` is unknown at base → `X` is the **state band** `[rest_of_state_cap, capital_cap]`. The disposition compares `target_price_range` against the band: report `max_eligible_price = capital_cap` with the note that the exact cap resolves once the suburb's tier is known. (This is the structured-banded result F7 asked for; the bool+narrative is replaced by `max_eligible_price` + disposition.)

### 6. Property-type-conditional schemes (deferred at base)

`property_fit.property_type` is unknown at base, so schemes whose eligibility turns on it are **conditional**:

- **FHOG** (new/off-the-plan only) — present as "available for a new build / off-the-plan purchase," not asserted/rejected.
- **QLD state concession** is a **type partition** (verified disjoint in the property-model foundation): `fhc` (established), `fhnhc` (new incl. house-and-land), `fh-vacant-land` (vacant land). At base, QLD presents the **conditional set** ("which concession applies depends on the property type you choose"), each with its own `applicant.*` eligibility already resolved. NSW/VIC concessions are type-agnostic → resolved at base (modulo the banded price check).

### 7. State-concession dispatch + stacking + order

- **State dispatch:** `eligibility.state_concession.*` is multi-filled by every state doc (the interpreter's last-wins merge is wrong here). The component **selects by `property_fit.state`** — the **projection suburb's state** (default the onboarding zone's suburb, via the `suburbs` table; **not** the browse-filter `onboarding.state`, which may be `ALL` — 2026-06-17 update): NSW→`fhbas`, VIC→`fhb-duty`, QLD→{`fhc`,`fhnhc`,`fh-vacant-land`} (the conditional set, decision 6). When the zone resolves to no single state (ambiguous/blank), the state slice is **omitted with a note** — never defaulted to a wrong state.
- **Stacking + order — already in the KB:** each scheme's `content_json.stacking` carries `alternative_to` / `combines_with` / `order_hint`. The component reads these (no new logic): FHSS `combines_with` FHG (`order_hint` 10 → first); FHG `alternative_to` Help-to-Buy (mutually exclusive), `combines_with` FHSS (20). `stacking_constraints` = the `alternative_to` edges among applicable schemes; `recommended_application_order` = applicable schemes sorted by `order_hint`.
- **Help to Buy income cap — in the KB params, not the criteria:** `kb.scheme.help-to-buy` parameters carry `income_cap_single` / `income_cap_joint` + `property_price_caps_capital`. The `eligible` criteria fill checks only the four `applicant.*` tests, so the component must additionally test `profile.assessable_income` against the (single vs joint) cap parameter. **Not a gap — a component step**; flagged so it is not forgotten.

---

### 8. Base benefit quantification — the scheme_stack dollar figures (2026-06-17)

**Stance change.** Decisions 1–7 leave `benefit_value` qualitative (prose) and `total_benefit_value` null ("quantified per-property"). That makes the base stack a checklist, not a plan — the figures the buyer reasons against are absent exactly where they're most decision-shaping (the bare East-Melbourne card is this stance made visible). Decision 8 makes base benefits **quantitative-where-grounded**: each applicable scheme carries a computed `benefit_value` as a **`money_range`** derived from `target_price_range`, refined to a tight range/point on a per-property turn (`scope: both`). Resolver-only — the figures are arithmetic over KB schedules, never the LLM (agentic-boundary §98). Honest-partial governs throughout: a figure needing a fact absent at base stays `null` with a note, never faked.

**One computer per figure** (this reconciles the out-of-scope line below). The duty saving is **not** recomputed here. [`fh_engine_cash:stamp_duty/3`](../../engine/erlang/src/fh_engine_cash.erl) is already the single, conformance-locked duty computer, exported as a pure function. Eligibility surfaces the state-concession benefit by **calling that function** — not by reading `cash_position`'s outcome (which the DAG forbids). Same function, same KB, so the scheme-stack benefit and the `budget_envelope` duty line can never disagree. The other benefits are eligibility-side (grant param, LMI band) or honestly null.

**Per-scheme computation** (base, from `target_price_range = [lo, hi]`):

| Scheme (role) | base `benefit_value` | source / computer | figure kind | per-property |
|---|---|---|---|---|
| state concession (`stamp_duty_concession`) | `[saving@lo, saving@hi]`, saving = `stamp_duty(State,true,V).concession_applied` | **`fh_engine_cash`** (shared), from `kb.stamp-duty.calc-by-state` | **regulated** -> exact, postcondition | exact at price |
| FHG (`deposit_guarantee`) | LMI-avoided band at est. loan (~95% of price within cap) | `kb.lmi.calculation` indicative bands | **estimate** -> banded, labelled indicative | tighten to loan (still insurer-bound) |
| FHOG (`grant`) | `$10k` if new-build; type unknown at base -> `[0, 10000]` + "if new build" note | `kb.scheme.{state}.fhog` (fixed) | **regulated** -> exact | collapses to `0` or `10000` on type |
| FHSS (`deposit_savings`) | `null` + note (offset needs marginal rate; release needs contribution split) | — | unknown at base | refine with income + contributions |
| Help to Buy (`shared_equity`) | `null` — not a cash saving (gov takes equity, repaid on exit); the value is loan/deposit reduction, surfaced as a note | — | N/A | — |

**`total_benefit_value` (money_range) respects stacking (decision 7).** Sum a **compatible** stack only — never alternatives together (FHG `alternative_to` Help-to-Buy means at most one). Compute `[sum-lo, sum-hi]` over the quantified, mutually-compatible applicable schemes (the FHG path dominates here); **exclude** the `null`/qualitative ones and say so ("excludes FHSS — needs your income"). A naive sum over `applicable_schemes` would double-count mutually-exclusive paths; the `alternative_to` edges already in the KB are the guard.

**Honesty properties (verifiable):**
- A **phased-out** concession surfaces as `[positive, 0]` across the band — e.g. a VIC $600–750k target: large saving near $600k, ~nil by $750k (the s.57JA taper; the `cash_duty` anchor pins VIC $700k -> saving $12,357 as the band's midpoint). The range *reveals* a taper a single point would hide — the foundation earning its keep, not a defect.
- **Regulated vs estimate is visible:** duty + FHOG are exact (postcondition-locked); LMI carries an "indicative" note + band; the renderer marks estimates distinctly.
- `benefit_value` becomes a **typed figure** (money_range), so it falls under the outcome-conformance figure-gate — a string can no longer slip through, as the prose does today.

**Dependency.** Quantifying the VIC/QLD duty benefit requires those concessions to be *applicable* — i.e. the `state_catalog/1` wiring (today NSW-only — the explicit Wedge-1 limit in [`fh_engine_eligibility`](../../engine/erlang/src/fh_engine_eligibility.erl)). Decision 8 and that wiring land together.

### 9. Base cash-need quantification — the `budget_envelope` NEED side (2026-06-17)

**Stance change.** [`fh_engine_cash`](../../engine/erlang/src/fh_engine_cash.erl) fills only the `stamp_duty.*` sub-tree at base; `total_cash_required`, `cash_available`, `gap_or_surplus`, `verdict`, and the deposit / other-costs / buffer lines are all `null` (its own scope note, `fh_engine_cash.erl:16-17`). So the cash section is a lone duty figure, not the "what does it cost to get in" answer the section exists to give. Decision 9 makes the **NEED side quantitative-where-grounded**: `total_cash_required` (at settlement) = `deposit` + `stamp_duty` + `other_buying_costs`, each a **`money_range`** derived from `target_price_range`, refined to a point on a per-property turn (`scope: both`). Resolver-only — arithmetic over KB schedules, never the LLM (agentic-boundary §98). Honest-partial governs: a line needing a fact absent at base stays `null` with a note, never faked.

**The NEED/HAVE asymmetry is the load-bearing honesty property.** The blueprint splits the envelope into `total_cash_required = deposit + stamp_duty + other_buying_costs` (NEED) and `cash_available = cash_on_hand + fhss_release + family_contribution` (HAVE). Onboarding captures **no savings** (plan-first minimalism, §7.1; `buyer_profile` defers financials to a refine turn), so the **HAVE side is null at base** → `gap_or_surplus` / `verdict` stay `null` (PENDING by design, not a gap to patch — we do **not** expand onboarding to capture savings). The base cash hero answers *"here's what it costs to get in,"* and the verdict computes on refine once savings arrive. This is the deliberate scope (Son, 2026-06-17).

**One computer per figure** (mirrors Decision 8). The duty line is **not** recomputed — it is the existing `stamp_duty/3` already in this outcome. The two new computers are cash-local:

| NEED line | base value | source / computer | figure kind | per-property |
|---|---|---|---|---|
| `deposit.minimum_required_amount` | `[5%·lo, 5%·hi]` when `recommended_path = fhg_backed` (from upstream `mortgage_plan`); else the 5% floor + note | `kb.cash-reserve` `genuine_savings_pct_of_price` / blueprint deposit min | **convention** → banded | exact % at price |
| `stamp_duty.after_concession` | already built (Decision 8 shares the same computer) | **`fh_engine_cash`** (shared) | **regulated** → exact, postcondition | exact at price |
| `other_buying_costs.total` | per-state registration (NSW flat / VIC + QLD value-formula) **+** Σ convention bands (inspection, conveyancing, insurance, utils, moving) → `[reg+Σlo, reg+Σhi]` | `kb.buyer-costs.inspections-conveyancing-fees` (registration **regulated/exact**; the rest **convention/lender-policy** ranges) | **mixed** → exact reg + banded rest | tighten on property type (zero strata insurance) + buyer quotes |
| `reserve_buffer.amount` | `null` + note — `= months × monthly repayment`, needs the loan rate (agent/refine fact) | `kb.cash-reserve` `recommended_post_settlement_reserve_months` | unknown at base | computes once repayment known |
| `total_cash_required` | `[Σlo, Σhi]` of deposit + duty + other-costs (the three settlement lines; **excludes** the post-settlement buffer — the blueprint names it `_at_settlement`) | sum (resolver) | banded | narrows to a point |

**Honesty properties (verifiable):**
- **Registration fees are regulated → postcondition-locked**, exactly like duty: NSW `$351.40` flat (transfer $175.70 + mortgage $175.70); VIC $700k → transfer $1,739.50 + mortgage $125.70; QLD $600k → transfer $2,203.56 + mortgage $248.04. The conformance harness pins these to the dollar against the registry schedules ([[verify-regulated-figures-by-postcondition]]).
- **Regulated vs convention is visible:** registration exact; the inspection/conveyancing/insurance/utility/moving lines are CONVENTION ranges (the buyer's own quotes bind) — surfaced as a band with the "~"/indicative marker, never a fixed figure.
- The new lines are **typed figures** (`money_range`), so they fall under the outcome-conformance figure-gate — a string can't slip through.

**Schema.** Add to the `budget_envelope` outcome (`[NEW]`, blueprint §5): `deposit { minimum_required_percentage, minimum_required_amount: money_range }`, `other_buying_costs { total: money_range, registration_exact: money, notes }`, `reserve_buffer { months_of_repayments_recommended, amount: money|null }`; type `total_cash_required` as `money_range` at base (point per-property). `cash_available`/`gap_or_surplus`/`verdict` unchanged (null at base).

---

## Simulation (walk the rules)

Each walk is `(facts) → expected scheme_stack` under the decisions above. These become Erlang conformance cases (extending `resolver_conformance.escript`).

**W1 — clean single applicant, NSW capital, target $1.2M.** One citizen, never owned, owner-occupier. Base partition of FHG passes (citizenship/age/ownership/intent ✓); banded price: `hi=1.2M ≤ capital_cap 1.5M` → fully within. FHSS per-applicant → `[applicant_0]` eligible. → `applicable_schemes: [FHG, FHSS]`, `eligibility_basis: all_applicants_eligible`, FHSS+FHG stack (order 10 then 20), Help-to-Buy `alternative_to` FHG → not added. ✔ matches the existing green resolver_eval cases.

**W2 — mixed-status couple (S1: Linh citizen + Đức temp resident).** `firb_required_any = true`. Joint FHG ∀ fails (Đức is temp resident; FHG needs citizen/PR). Subset {Linh} passes → `eligibility_basis: eligible_only_if_restructured`; `structuring_options: [{if_purchased_as: "Linh alone", applicable_schemes: [FHG, FHSS], tradeoffs: "single-income serviceability"}]`; FIRB-path note for Đức's interest. FHSS per-applicant: Linh eligible, Đức not (not first-home? temp resident still could hold super — but fails owner-occupier/first-home depending; resolved per his facts). → the outcome **expresses "eligible for Linh alone"** — the F1 structural fix realized.

**W3 — prior overseas ownership, QLD (S8).** Citizen, never owned **AU** property, but owned & sold an apartment in Saigon (`prior_overseas_property_ownership = true`). FHG/FHSS test AU-only → pass. QLD `fhnhc` criteria include `prior_overseas_property_ownership eq false` → **fails** → in `rejected_schemes` with reason "QLD new-home concession tests worldwide ownership." Same person, two schemes, opposite verdicts — per-scheme resolution. ✔ (the signature diaspora case).

**W4 — prior FHSS release (S9).** `prior_fhss_release = true` → FHSS criterion `prior_fhss_release eq false` fails → FHSS rejected ("one release per lifetime, already used"). Other schemes unaffected.

**W5 — banded straddle (S15/16, F7).** NSW, FHBAS price cap (full exemption) at e.g. $800k, `target_price_range = [750k, 900k]`. `lo ≤ 800k < hi` → straddles → state_concession reported `eligible up to max_eligible_price = 800k (full exemption); partial concession above`. The structured banded result, not a bool.

**W6 — two applicants, one qualifies for FHSS (F13).** A: first-home, eligible; B: owned AU property. **Per-applicant** FHSS → `eligible_applicants: [A]`, release = A's. (The joint-∀ model wrongly returned ineligible — this walk is the F13 xfail's XPASS.)

**W7 — base benefit quantification, the live case: East Melbourne, VIC, target $600–750k (Decision 8).** VIC `fhb-duty` is wired into `state_catalog` (the Decision-8 dependency). `benefit_value` for the state concession = `fh_engine_cash:stamp_duty(VIC, true, V).concession_applied` over the band → `[saving@600k, saving@750k]`, a large-to-~nil range (the s.57JA phase-out; midpoint anchored at $700k → $12,357), carrying the phase-out note. FHG: within the VIC capital cap $950k → applicable; `benefit_value` = the LMI-avoided indicative band at ~95% LVR on the range, labelled estimate. FHSS: applicant facts absent at base → `null` + "confirm income/contributions." Help-to-Buy: `alternative_to` FHG → not summed; `null` benefit + equity-share note. `total_benefit_value = [sum-lo, sum-hi]` over {VIC duty, FHG-LMI} with FHSS excluded-and-noted. The bare card (qualitative, null total) becomes a quantified, honest **range** stack — this walk is the screenshot's fix, and the close-criterion for the foundation.

---

## What this changes — KB / interpreter / component split

**KB additions (build-time, small):**
1. A per-scheme **`resolution: joint | per_applicant`** marker in each scheme's `content_json` (decision 2). Only FHSS is `per_applicant`; the rest `joint`. Auditable, not inferred.
2. The `non_buying_partner` couple-as-one criteria term on FHOG + state-concession `applicable` rules (decision 4, F4) — a KB-criteria addition (verify against each scheme's couple test).

**Interpreter (`fh_engine_resolver`) extensions:**
3. A **criteria-partition** helper: split a `criteria` tree into base / property partitions by the decision-1 field set, evaluate the base partition. (Or the component walks the tree — see below.)
4. The banded price disposition (decision 5) — likely component-side (it consumes `target_price_range`, not a single fact), reading the cap from the scheme's `lookup`/parameter.

**Component (`fh_engine_fill` eligibility):** orchestrates — per scheme: select-by-state (7), partition criteria (1), evaluate base partition joint-∀ or per-applicant (2), subset analysis → `eligibility_basis` + `structuring_options` (3,4), banded price (5), type-conditional framing (6), assemble `applicable`/`rejected`/stacking/order (7). The Help-to-Buy income-cap step (7).

**Findings surfaced (for the tracker):**
- **G1** — Help-to-Buy income cap is in KB *parameters* but not the `eligible` criteria → component must apply it (decision 7). *Not a defect; a required step.*
- **G2** — `non_buying_partner` couple-as-one fold-in not yet in any scheme's criteria (F4) → KB-criteria addition (decision 4).
- **G3** — the FHG-cap `null`-default + Erlang number-`<`-atom ordering hazard (decision 1) → the component must never pass a property-dependent criterion to the raw evaluator at base. *Resolver-safety note.*
- **G4** — `property_fit.state` was sourced from `onboarding.state`, which is the map **browse-filter** and can be `"ALL"` → all state-specific schemes silently drop (2026-06-17 update). Fix: source it from the **projection suburb's state** (the onboarding zone, via `suburbs`). *Map-first alignment, not just a bug.*

**Decision 8 changes (base benefit quantification) — beyond eligibility:**
- **Schema (blueprint [§3](../blueprints/fhb-domestic-au.md)):** type `applicable_schemes[].benefit_value` and `structuring_options[].benefit_value` as **`money_range`**; `total_benefit_value` `money` → **`money_range`**; move the prose benefit blurb to `notes`. Update §3's scope wording (base now quantifies benefit ranges) and the out-of-scope line below.
- **Outcome-conformance ([outcome-conformance.md §2](outcome-conformance.md)):** `benefit_value` / `total_benefit_value` join the figure set (null-or-number, range-typed) — the figure-gate now covers them.
- **`fh_engine_cash`:** **no change** (already exports `stamp_duty/3`); eligibility calls it for the duty benefit. Note the shared use in [stamp-duty-concession-mechanics.md §1](stamp-duty-concession-mechanics.md).
- **`state_catalog/1` wiring (the Wedge-1 correctness gap):** add VIC + QLD concessions to [`fh_engine_eligibility`](../../engine/erlang/src/fh_engine_eligibility.erl) (QLD = the conditional type-set, decision 6). Couple-as-one (G2) stays its own held item.
- **Conformance:** new `tests/eligibility_benefit_eval.py` (+ Erlang conformance) — anchors: the VIC taper range incl. the $700k → $12,357 midpoint, FHOG fixed $10k, the alternative-stack total (FHG+FHSS path summed, Help-to-Buy NOT added), an LMI band. Regulated figures postcondition-verified, same discipline as `cash_duty_eval`.
- **Renderer ([plan-card-visual-spec.md §3.2](plan-card-visual-spec.md)):** the scheme-stack hero reads `money_range` `benefit_value`s — bar sized by each scheme's range-midpoint within the compatible stack, legend showing ranges (collapse `[x,x]` → `$x`), an estimate marker for LMI, `null` (FHSS / Help-to-Buy) → hatch + "see notes", total as a range. This **supersedes §3.2's "the data already flows" premise** (it didn't — benefit_value was prose/null).

**State-projection changes (2026-06-17 update) — the G4 fix:**
- **Projection state, one derived value:** resolve the projection state from the onboarding **zone**'s suburb via the `suburbs` table (the authority), with a shared helper both `fh_engine_eligibility` and `fh_engine_cash` call — replacing their current `onboarding_state/2` reads of `onboarding.state`. `onboarding.state` stays the map browse-filter (it no longer reaches the resolvers).
- **Shell (precision, recommended):** pass the pinned suburb's **SAL** at card creation so the derivation is collision-proof (a suburb *name* can repeat across states); fall back to name→state otherwise.
- **Fail-honest:** zone → no single state ⇒ omit the state slice with a note (the `state_not_assessed` copy), never default to a wrong state.
- **Deferred (the per-suburb overlay):** re-resolving the state slice for a *viewed* suburb that differs from the zone's state is the deferred zone→suburb projection; the zone-default above is the in-scope slice now.

**Findings closed:** **F13** (FHSS per-applicant — decision 2, with the xfail→XPASS close-criterion); **F7** (banded `max_eligible_price` for the base — decision 5).

**Out of scope (per-property / per-suburb refinement):** the exact `applicable_cap_for_location_property` once the suburb's `location_tier` is known; `fhog.applicable` / the QLD concession selection once `property_type` is known; the **per-suburb state overlay** (state slice re-resolved for a viewed suburb other than the zone — 2026-06-17). Base benefit **ranges** + the **zone-default state projection** are in scope (Decision 8 + the 2026-06-17 update), computed by the shared `fh_engine_cash` + KB; the per-property turn **narrows** them to points (exact price → exact duty/LMI, resolved cap/type) rather than introducing them.
