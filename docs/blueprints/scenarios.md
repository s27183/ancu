# Scenario analysis — Mode A plan-card stress test

**Purpose.** Stress-test the Mode A blueprint ([`fhb-domestic-au.md`](fhb-domestic-au.md)) as a *foundation* — a sound anchor for the planning agent — by walking concrete, deliberately-nasty buyer scenarios through its component DAG and recording where the **structure** fails to represent reality. This is design/specification verification by simulation, run *before* the engine exists, while a fix is a doc edit rather than a schema migration. The catalogue doubles as the future integration/eval set.

**Status.** Pre-engine desk-walk. Scenarios are walked by hand against the blueprint's components (`inputs`, `parameters`, `outcome_schema`, `scope`, `kb_anchors`) and the pipeline DAG (`fhb-domestic-au.md` §"Component pipeline"). No execution.

## Scope

- **Mode A only** — Vietnamese-AU citizen / PR first-home buyer, no FIRB. The in-scope, KB-complete (45/45 anchors resolve) blueprint. B/C/D are out of scope (their KB is unauthored; a "break" there can't be distinguished from "KB not yet written").
- **Including mode-boundary detection** — scenarios where the buyer does *not* cleanly fit Mode A are in scope, because the test is whether Mode A correctly *notices* it isn't Mode A and routes (the FIRB gate, the all-applicants eligibility test). The diaspora's real cases live on these boundaries.

## What this tests — and what it does not

A blueprint is the **skeleton** the agent reasons within, not the reasoning. So:

- **In scope:** the blueprint's *expressive capacity*. Can its inputs capture the buyer's facts? Can an `outcome_schema` hold the result? Is there a `kb_anchor` to ground each regulated decision? Does the `scope` split (`base` / `per-property` / `both`) hold? Do the DAG edges express the real dependencies?
- **Out of scope:** the agent's *reasoning quality* (that's an eval harness, and needs the engine), and the *correctness of KB content* (that's the KB-authoring + canonical-source pass).

### The agent caveat, resolved

The agent handles out-of-nowhere situations, so the blueprint is **not** accountable for everything. It is accountable for being a sound **anchor**: structurally covering the **regulated** and **common** cases so the agent stands on solid ground and only improvises at genuine edges. Every scenario therefore lands in one of three buckets:

| Bucket | Meaning | Action |
|---|---|---|
| **COVERED** | A structural slot + anchor exists; the deterministic skeleton represents this. | None. |
| **DELEGATED** | Genuine novelty, correctly handed to the agent — *and the handoff is clean* (the agent has the context + an anchor to reason from). | None — the boundary is where it should be. This is the agent earning its keep. |
| **BREAK** | A *regulated-or-common* decision the blueprint gives the agent **no slot and no anchor** for. The agent is forced to invent a regulated answer from nothing. | A finding. Disposition: fix blueprint / author KB / re-confirm delegation. |

A BREAK's disposition is a design adjudication, not a defect ticket — three resolutions, not one:

1. **Fix the blueprint** — add the missing input / outcome field / edge / scope change.
2. **Author KB** — the structure is fine but a grounding doc is missing.
3. **Confirm delegation** — on reflection it *is* correctly the agent's, and the handoff already carries enough context + anchor. (Reclassify BREAK → DELEGATED.)

## Break taxonomy

Every finding is tagged with one or more:

| Code | Break type | The question it answers |
|---|---|---|
| **B1** | Missing input | Does a component capture this fact at all? |
| **B2** | Missing outcome slot | Can the `outcome_schema` represent this result (vs flattening a conditional/per-party reality into a scalar)? |
| **B3** | Missing kb_anchor | Is there a grounding doc for this *regulated* decision? |
| **B4** | Scope mismatch | Is this modeled `base` vs `per-property` correctly? |
| **B5** | DAG inadequacy | Do the edges express the real dependency (or force a cycle)? |
| **B6** | Mode-boundary leak | Does the mode-gate catch a buyer who isn't actually Mode A? |

## Scenario template

```
### S<n>. <title>
**Stresses:** <component(s)> · <break-type tag(s)>
**The buyer:** <concrete fact-set — onboarding inputs + the latent facts that emerge>
**Walk:** <DAG component-by-component: does each input resolve? does the outcome slot hold? is there an anchor?>
**Landing:** COVERED | DELEGATED | BREAK
**Finding:** <if BREAK/DELEGATED-with-caveat: what's missing, and the proposed disposition>
```

---

## Scenarios

### S1. Mixed-status couple — citizen + temporary resident buying jointly

**Stresses:** `buyer_profile`, `eligibility` · **B1, B2, B6**

**The buyer.** Linh is an Australian citizen (Vietnamese-Australian, born here). She is buying her first home *jointly* with her partner Đức, who is on a 482 temporary-skill visa (a **foreign person** under FIRB law). They onboard as Mode A — Linh answers the questions, picks NSW, a $900k–$1.05M range, an inner-west Sydney zone, owner-occupier intent. Đức's status surfaces only as "buying with my partner."

**Walk.**

- **`buyer_profile`** — `identity.citizenship_status` captures `citizen` (Linh). `household.buying_alone = false`, `co_buyer_count = 1`. But there is **no per-co-buyer attribute set** — Đức's `citizenship_status` / `firb_status` has nowhere to go. `firb_status` is a *scalar* derived from the single `citizenship_status`, so the profile asserts `firb_required = false` for the *application*, which is wrong: FIRB attaches to Đức's interest in the property. **(B1)** The `firb_required` outcome field is a single bool — it cannot express "one of two purchasers is a foreign person." **(B2)**
- **`eligibility`** — reads `profile`. Every scheme in the stack (FHG, FHSS, state concession) requires *all* purchasers to satisfy the first-home + residency tests; FHG in particular requires each applicant to be an eligible citizen/PR. With Đức a temp resident, the *joint* application fails FHG outright (or the couple must restructure to Linh-only, which changes serviceability). The `scheme_stack` outcome has no per-applicant dimension — `applicable_schemes` is application-level. It cannot represent "eligible for Linh alone, not as a couple." **(B2)**
- **FIRB gate** — constraint #10 says every flow branches on FIRB status and the gate is architectural, not a disclaimer. Here the gate never fires, because the foreign person is the *co-buyer*, and the profile only models the primary buyer's status. The plan would silently proceed as a clean Mode A FHB plan — the single highest-harm failure in the set. **(B6)**

**Landing.** **BREAK.**

**Finding.** The blueprint models the buyer as a single legal person with a scalar citizenship/FIRB status; `household` counts co-buyers but does not carry their *eligibility-bearing facts*. For the Vietnamese diaspora — where mixed-status couples (citizen + temp-resident/foreign partner) are common — this is both regulated (FIRB, constraint #10) and common, so it is a true BREAK, not delegable novelty.

*Proposed disposition (fix blueprint, B1/B2/B6):*
- `buyer_profile` carries an **array of applicants**, each with its own `citizenship_status` / `firb_status` / `ownership_history` eligibility-bearing facts (or, minimally, a `co_buyers: array<{citizenship_status, ever_owned_au_property, …}>`).
- `firb_required` becomes **per-applicant** (or `firb_required_any: bool` + which applicant), so the gate fires on *any* foreign purchaser.
- `eligibility` resolves schemes against the **applicant set** (all-applicants test), and `scheme_stack` can express "available only if structured as <subset>."
- Routing: when any co-buyer is a foreign person, the gate routes that applicant's interest through the Mode B/D FIRB path — even though the lead buyer is Mode A.

---

_The walked set follows, grouped by what it stresses. Each lands COVERED / DELEGATED / BREAK per the buckets above. A pattern emerges: the scheme-stacking, LVR-path, debt-optimisation, strata, and settlement-by-state machinery is largely **COVERED** — that's the blueprint's core competence. Breaks cluster in four places: **household composition** (multi-party applicants), **residence & funds provenance** (the diaspora-specific facts), **non-standard property structures**, and **time-decay / partial-use**._

### Identity & FIRB boundary (mode-boundary detection)

#### S2. Temp resident who believes they're Mode A — PR "imminent"

**Stresses:** `buyer_profile`, `eligibility` · **B6, B2 (minor)**

**The buyer.** Minh self-selects Mode A at onboarding but is on a 485 graduate visa; his PR application is lodged and "a few months away." He's a foreign person *now*.

**Walk.** `buyer_profile.citizenship_status` has `temporary_resident` as a valid option, so the fact is captured; `firb_status` derives to `foreign_person` and `firb_required = true` — the gate *can* fire. `eligibility` correctly rejects FHG/FHSS (citizen/PR only); `scheme_stack.rejected_schemes` carries `{name, reason}`, so "requires PR" is expressible as narrative. Two gaps: (a) there is **no blueprint-level construct to route him to the Mode B blueprint** — mode selection is an onboarding/engine act, not a component output; (b) the *temporal-conditional* shape "ineligible now, eligible on PR grant" can only live in a free-text `reason`, not as a structured "re-check on status change."

**Landing.** **DELEGATED.** Detection is covered (`firb_required` + `rejected_schemes.reason`); mode-routing is correctly an onboarding/engine responsibility — but that handoff *must exist* (confirm in the onboarding flow). The structured pending-status is a minor enhancement, not a regulated break.

#### S3. PR granted mid-plan — status change must re-resolve

**Stresses:** plan-card mutation, `buyer_profile` → all downstream · **B5 (engine)**

**The buyer.** Minh (S2) is granted PR at plan week 6. `citizenship_status` flips `temporary_resident → permanent_resident`.

**Walk.** The param is mutable; `firb_status` re-derives to `not_foreign_person`; `eligibility` now admits FHG/FHSS. The blueprint *schema* represents both the before and after states correctly — nothing structural is missing. What's missing is **re-resolution orchestration**: a status change must invalidate and re-run the downstream outcomes (`scheme_stack`, `mortgage_plan`, `budget_envelope`). That is owned by the engine/turn model ([isolation-model.md](../architecture/isolation-model.md)), not the blueprint.

**Landing.** **DELEGATED (engine).** One blueprint-level note: outcomes carry no `resolved_against` provenance, so staleness after an upstream change isn't *detectable* from the artifact alone — worth considering when the engine schema lands.

#### S4. Citizen buying with a Vietnam-based parent's money

**Stresses:** `buyer_profile`, `eligibility` · **B1, B2, B6** — *extends F1*

**The buyer.** Vy is a citizen FHB. Her parents in Vietnam are funding most of the purchase. Two sub-cases flip the entire plan: **(a) gift only** → Mode A, genuine-savings question (see S11); **(b) parent goes on title** to satisfy the lender → the parent is a co-owner who is a *foreign person* **and** not an owner-occupier.

**Walk.** Sub-case (a) is captured by `savings_and_deposit.family_gift_or_loan_amount`. Sub-case (b) is S1's break, sharper: the parent-on-title is (i) a foreign person → FIRB on their interest (no per-co-buyer status — B1/B6), and (ii) a non-occupying co-owner → breaks the owner-occupier and first-home tests for the application, which most schemes apply to *all* owners (no per-applicant `owner_occupier_intent` — B2). One fact (`on title?`) silently flips Mode A → a FIRB-gated, scheme-ineligible structure.

**Landing.** **BREAK** — same root as F1, and it *extends* the fix: the applicant array must carry per-applicant `owner_occupier_intent` and residency, not just citizenship.

#### S5. Dual citizen living overseas (citizen, non-resident)

**Stresses:** `buyer_profile`, `eligibility`, `ownership_planning` · **B1**

**The buyer.** Khanh is a Vietnamese-Australian citizen who has lived in HCMC for years and wants to buy in Melbourne (returning, or buying ahead of a return). Citizen → never a foreign person, so the FIRB gate correctly stays shut.

**Walk.** `identity` captures `citizenship_status` and `location_state` (the AU target state) but has **no current-country-of-residence or tax-residency fact**. This matters twice: (a) FHG / FHOG / state concessions carry **occupancy requirements** (move in within 12 months, reside 6–12 months) whose *feasibility* can't be assessed from `owner_occupier_intent: bool`; (b) a non-resident for tax pays different CGT (no main-residence exemption, no 50% discount apportionment) and may face land-tax surcharges — none of which `ownership_planning` can flag without a residency fact. **B1.**

**Landing.** **BREAK.** Add a `tax_residency` / `current_residence_country` fact to `buyer_profile.identity`. Regulated (scheme occupancy conditions + non-resident tax) and plausible for the returning diaspora.

### Ownership history

#### S6. Owns a property in Vietnam — QLD worldwide disqualifier vs federal favourable

**Stresses:** `buyer_profile`, `eligibility` · **COVERED**

**The buyer.** Thảo (citizen, QLD) still owns an apartment in Đà Nẵng.

**Walk.** `ownership_history.prior_overseas_property_ownership` and `currently_owns_property` capture it, and their param notes are explicit: federal schemes (FHG/FHSS) test AU-only and are unaffected; some state concessions test residences *worldwide* and disqualify (QLD FHNHC). `eligibility` resolves per-scheme against the per-scheme KB (`kb.scheme.qld.fhnhc` owns the worldwide test); `scheme_stack` carries FHG in `applicable_schemes` and QLD FHNHC in `rejected_schemes` with reason.

**Landing.** **COVERED** — the blueprint was explicitly designed for the signature diaspora case. *Minor:* `currently_owns_property` is one bool for AU-or-overseas; if a scheme treats *current AU* ownership differently from *current overseas*, that distinction is lost (relates to F7 banding, low severity).

#### S7. Owned AU property, sold >10 years ago — FHG re-entry

**Stresses:** `buyer_profile`, `eligibility` · **COVERED**

**The buyer.** Hùng owned a unit in 2011, sold in 2013; 13 years on he's buying again.

**Walk.** `ever_owned_au_property = true` with `years_since_last_au_property_interest = 13`; the param note says it feeds the FHG 10-year re-entry. `eligibility.fhg` resolves eligible via `kb.scheme.fhg`.

**Landing.** **COVERED.**

#### S8. Currently owns an AU investment property, never lived in it

**Stresses:** `buyer_profile`, `eligibility` · **B1**

**The buyer.** Nga rentvested — she owns an investment unit she has never occupied, and now wants to buy her first *home*.

**Walk.** `currently_owns_property = true` and `ever_owned_au_property = true` are captured; Help to Buy ("cannot currently own") and FHG ("not currently own") correctly fail via their notes. But several first-home tests turn on whether you ever owned a property **you occupied as a residence** — an investment-only owner can still qualify for some. The profile has no **owned-vs-occupied** distinction (no "ever owned a property you lived in"), so a scheme whose test is occupation-based can't be resolved correctly from the inputs. **B1.**

**Landing.** **BREAK.** Add an `ever_owned_and_occupied_residence` fact. Common (rentvesting) and scheme-determinative.

#### S9. Prior FHSS release — one per lifetime

**Stresses:** `buyer_profile`, `eligibility` · **COVERED**

**Walk.** `ownership_history.prior_fhss_release` exists precisely for this ("one valid release per lifetime"); `eligibility.fhss.eligible` resolves false.

**Landing.** **COVERED.**

#### S10. Partner's ownership history — even a non-buying spouse

**Stresses:** `buyer_profile`, `eligibility` · **B1** — *distinct from F1*

**The buyer.** An owns nothing and applies alone. But her husband (not on the loan, not on title) owns a unit he bought before they met. FHB schemes (FHOG, state concessions) generally test **the applicant *and* their spouse/partner** — a married/de-facto couple is treated as one, so the partner's ownership can disqualify An *even though he isn't buying*.

**Walk.** The profile captures only the buyer's own ownership history plus `co_buyer_count`. A *non-buying* partner's ownership history has no slot — and the F1 applicant-array fix (co-*buyers*) doesn't reach it, because this partner isn't a buyer. **B1.**

**Landing.** **BREAK** — distinct from F1: the relevant person isn't a co-buyer. Needs a "partner exists + partner's ownership history" fact regardless of whether the partner is on title/loan.

### Cash, deposit, income

#### S11. Gifted deposit from Vietnam — genuine savings, source-of-funds, capital controls

**Stresses:** `buyer_profile`, `cash_position`, `mortgage_finance` · **B1, B2** — *high* (~~B3 retracted~~ — see walk (c))

**The buyer.** Bảo's 15% deposit is a recent transfer from his parents in Vietnam. He has enough cash — but it's a gift, freshly arrived.

**Walk.** Inputs exist: `family_gift_or_loan_amount` and `genuine_savings_evidence_months`, and `mortgage_finance.lender_synthesis.lenders_with_lenient_genuine_savings` is a hook. Two gaps: (a) **no genuine-savings verdict slot** — `cash_position.budget_envelope.verdict` is `surplus | tight | short` on *cash sufficiency*; a buyer flush with gifted cash reads `surplus` while being **un-approvable** because the deposit fails the lender's 5% genuine-savings test (the "1% rule" — a recent gift doesn't count). The two gates (genuine savings = lender approval; reserve buffer = planning) are conflated into one verdict (B2). (b) **No funds-provenance fact** — source of funds (AUSTRAC) and the legitimacy of the cross-border transfer channel (SBV capital controls) are *hard regulatory constraints* in CLAUDE.md with no parameter (B1). (c) ~~No KB anchor (B3)~~ — **retracted on verification**: `kb.cash-reserve.lender-expectations` already *owns* genuine savings (its title: "genuine savings *and* the post-settlement buffer" — it carries the 5%/3-month rule, the 1% rule, the rental-history substitute, and APRA APG 223). I misread it as buffer-only. The gate is grounded; only the verdict *slot* was missing.

**Landing.** **BREAK** — regulated, the signature diaspora funding pattern. Needs a genuine-savings verdict distinct from cash-sufficiency (B2) and a funds-provenance fact (B1). The KB grounding already exists — no new doc.

#### S12. Self-employed / income partly remitted from Vietnam

**Stresses:** `buyer_profile`, `mortgage_finance` · **B1**

**The buyer.** Tâm runs a business; part of her income is paid from a Vietnamese entity.

**Walk.** Self-employment *is* captured — `income.income_stability` has `self_employed | contractor | mixed`, and serviceability nuance (2-yr financials, add-backs) is delegable to `mortgage_finance` + `kb.lender.serviceability-basics` (clean delegation). The gap is **foreign-sourced income**: lenders haircut or exclude offshore/FX income, and there is no fact for income *source country / currency*. `assessable_income` is a single figure. **B1.**

**Landing.** **BREAK** (scoped to foreign income; domestic self-employment is COVERED/DELEGATED). Add an income-source/currency fact; confirm a lender-treatment-of-foreign-income anchor.

#### S13. Deposit straddles 5% / 20% LVR

**Stresses:** `mortgage_finance` · **COVERED**

**Walk.** `loan_path_comparison` models exactly this three-way: `fhg_backed_path` (5%, no LMI), `lmi_backed_path_5_to_20`, `twenty_plus_deposit_path`, with `recommended_path` + reasoning and an offset interaction in `loan_structure`.

**Landing.** **COVERED** — a designed strength.

#### S14. HECS balance fails serviceability at the target price

**Stresses:** `buyer_profile`, `mortgage_finance` · **COVERED**

**Walk.** `borrowing_capacity` carries `with_current_debts` vs `if_hecs_cleared`; `debt_optimisation.hecs` carries `clear_before_application_recommended`, `estimated_capacity_uplift_if_cleared`, and `trade_off_cash_drain`. If capacity still falls short, `budget_envelope.verdict = short` with `mitigation_options_if_short`.

**Landing.** **COVERED** — a designed strength.

### Price / threshold cliffs

#### S15 + S16. Target range straddles a scheme price cap / a stamp-duty concession cliff

**Stresses:** `eligibility`, `cash_position` · **B2 (minor) — F7**

**The buyer.** Quân's $820k–$880k range straddles the FHG cap for his location (S15) and a state-duty concession cliff (S16): eligible at the bottom of the range, not the top.

**Walk.** The cap is a field (`eligibility.fhg.applicable_cap_for_location_property`), the range is known, and `state_concession.concession_type` has `full_exemption | partial_concession | no_concession` for phase-outs; the eligibility scope note explicitly calls out a "target-range-vs-cap check," and `stacking_constraints` can carry the banding as narrative. So the cliff *is* surfaced. The weakness: `fhg.eligible` is a **bool**, which flattens a banded reality ("eligible below $X, not above") — better expressed as a derived `max_eligible_price`.

**Landing.** **COVERED, with a minor flag (F7).** Anticipated by design; the enhancement is a structured banded result instead of a bool + narrative.

#### S17. Below-market price triggers a low bank valuation

**Stresses:** `property_assessment`, `mortgage_finance`, `cash_position`, `settlement_prep` · **B1, B5**

**The buyer.** Hoa's offer is accepted below asking — but the *lender's* valuation comes in under the contract price, so her LVR jumps, her deposit no longer reaches 80/95%, and LMI reappears.

**Walk.** `property_assessment.market_position` holds an *agent* estimate (`estimated_market_value_range`, `asking_price_vs_market`), but the **bank valuation** — a distinct post-contract lender event that *governs the loan* (`kb.lender-docs.standard-timeline`, `kb.property.comparables-methodology`) — has **no parameter anywhere**, and no `valuation_received` milestone in `settlement_prep`. So a valuation shortfall can't be ingested to re-trigger `mortgage_finance` → `cash_position` and recompute the deposit/LVR/LMI position. **B1** (missing input) **+ B5** (the dependency "bank valuation → recompute cash" has no edge).

**Landing.** **BREAK.** Add a bank-valuation input + a settlement milestone, and an edge that recomputes the cash position on a shortfall. Common and high-impact.

### Property type / scope

#### S18. Off-the-plan apartment — completion valuation gap, FHOG, long sunset

**Stresses:** `property_assessment`, `eligibility`, `buying_strategy`, `settlement_prep`, `due_diligence` · **COVERED, with flags — refs F8**

**Walk.** `property_type` has `off_the_plan` / `new_apartment`; `eligibility.fhog.applicable` derives from it (new-build grants); `buying_strategy.transaction_mode` has `off_the_plan_contract`; `settlement_prep.key_dates.settlement_date` is `<from_document>` so a 1–2-year settlement is representable (the "4–8 week" in the goal text is prose, not a constraint). Two carried risks: the **completion valuation gap** is the same missing bank-valuation input as F8; **sunset-clause rescission** risk relies on `due_diligence` (`kb.contract-of-sale.review-points-by-state`, `kb.special-conditions.standard-set`) covering off-the-plan sunset terms.

**Landing.** **COVERED, with flags.** Refs F8 for the valuation gap; confirm the due-diligence KB covers sunset clauses.

#### S19. House-and-land package — two contracts, duty on land only, staged draws

**Stresses:** `property_assessment`, `mortgage_finance`, `cash_position` · **B1, B2**

**The buyer.** Đạt buys a house-and-land package in a growth corridor: a land contract + a separate build contract, duty assessed on the land only, funded by a progressive-draw construction loan.

**Walk.** `property_type` lists `house_and_land`, but the rest of the model assumes **one property, one price**: `property_assessment.basics.price` and `cash_position.inputs.property_price` are single figures, so the land/build split can't be represented (B2); `cash_position.stamp_duty` would compute duty on the *whole* price, over-stating it where duty is land-only (B2); `mortgage_finance.loan_structure` offers `P&I | IO | split` but **no construction/progressive-draw loan** (B1). 

**Landing.** **BREAK.** H&L is a structurally different transaction; the single-price/single-contract model can't carry it. Popular with FHBs (new build + FHOG) — worth a decision on whether Mode A covers H&L or explicitly scopes it out.

#### S20. Established apartment with strata red flags

**Stresses:** `property_assessment`, `due_diligence` · **COVERED**

**Walk.** `property_assessment.strata_or_building` carries fees, sinking fund, special levies, structural red flags; `due_diligence` adds `strata_report` + agent-reasoned `strata_flags` (`document_significance`); `kb.strata.health-indicators` + `kb.strata-report.red-flags` ground it. Significance reasoning is a clean agent delegation.

**Landing.** **COVERED** — exemplary depth + clean engine/agent split.

#### S21. Regional/rural property — location tier, flood, lender LVR limits

**Stresses:** `property_assessment`, `eligibility`, `mortgage_finance` · **B1 (minor) — F10**

**Walk.** Location tier is captured (`basics.is_capital_city`, `lga`) and feeds `eligibility.fhg.applicable_cap_for_location_property`; `location_factors.flood_risk_band` feeds insurance. The gap: lenders impose **postcode/security-type LVR caps** (small towns, high-flood, high-density postcodes) with no structured input; `mortgage_finance.lender_synthesis` is agent-reasoned and could surface it, but there's no postcode-risk fact.

**Landing.** **DELEGATED, with a minor flag (F10).** Delegable to `lender_synthesis` + KB; confirm `kb.lender.serviceability-basics` covers postcode/security LVR restrictions.

### Timeline / plan-card mutation

#### S22 + S23. Applicant set changes mid-plan — co-buyer removed / added

**Stresses:** plan-card mutation, `buyer_profile`, `mortgage_finance`, `eligibility` · **B5 (engine)** — *refs F1*

**The buyer.** S22: a couple separates and the plan continues as a single buyer (one income, capacity ~halves). S23: a single buyer's partner joins (second income, but the partner's status/ownership now matter — S1/S10).

**Walk.** Both are the same mutation mirrored. The blueprint *schema* represents either applicant count; what changes is that the mutation must re-run serviceability and eligibility — **engine orchestration** ([isolation-model.md](../architecture/isolation-model.md)). The blueprint-level prerequisite is the F1 applicant array (so adding/removing a person has structured facts to add/remove).

**Landing.** **DELEGATED (engine)**, gated on F1.

#### S24. Buyer changes target state mid-plan (NSW → QLD)

**Stresses:** plan-card mutation, `eligibility`, `cash_position`, `buying_strategy`, `settlement_prep` · **B5 (engine), B1 (minor)**

**Walk.** `location_state` flips; every `*-by-state` resolution re-runs (state concession, stamp duty, cooling-off, auction rules, settlement process). The schema is fully state-parameterised, so this is engine re-resolution. One minor schema gap: `target_zone` (suburbs) isn't validated against `location_state`, so a stale NSW zone can survive a switch to QLD.

**Landing.** **DELEGATED (engine)**; minor zone/state consistency flag.

#### S25. Pre-approval expires before purchase

**Stresses:** `mortgage_finance`, (no owner of pre-settlement alerts) · **B1, B2**

**The buyer.** Linh gets pre-approval, then takes five months to find a place. Her 90-day pre-approval lapses; rates and her capacity may have moved.

**Walk.** `mortgage_finance.pre_approval_workflow.pre_approval_validity_days = 90` is a **static int**, not a tracked expiry *date* with a re-application trigger. Alert machinery exists only in `ownership_planning` (post-settlement). Some pre-purchase time-windows *are* captured (`eligibility.fhss.contract_window_months_after_release = 12`; cooling-off dates in `settlement_prep`), but **pre-approval expiry has no tracked date or alert** — no component owns pre-settlement time-decay for it.

**Landing.** **BREAK** (scoped). Track pre-approval as an expiring date with a re-application trigger; common for slower (often overseas-coordinated) buyers.

### State-specific traps

#### S26. QLD time-of-essence settlement — no notice-to-complete

**Stresses:** `settlement_prep` · **COVERED**

**Walk.** `settlement_prep` reads `property_fit.state` and resolves the timeline from `kb.settlement.process-by-state`, which owns the QLD time-of-essence asymmetry (no Notice-to-Complete, unlike NSW/VIC). `settlement_checklist.critical_path_milestones` + `at_risk_milestones` surface it.

**Landing.** **COVERED** — the state asymmetry lives in KB; the blueprint reads state and surfaces critical path.

#### S27. VIC land-tax PPOR trap — renting out a room

**Stresses:** `buyer_profile`, `eligibility`, `ownership_planning` · **B1**

**The buyer.** To afford repayments, Phúc plans to rent out a room (or a granny flat) in his Melbourne PPOR.

**Walk.** `ownership_planning.annual_obligations.land_tax_check` has `exempt_ppor | applicable | to_verify` and `kb.land-tax.ppor-exemption` owns the rule — but the **trigger** isn't representable: `owner_occupier_intent` is a *binary* bool with no "partial rental / rent-a-room / granny flat" state. Partial rental flips land-tax exemption, the CGT main-residence exemption, *and* FHB scheme occupancy conditions (you must occupy, and renting part may breach some) — a single fact touching three components, with nowhere to put it.

**Landing.** **BREAK.** Replace the binary intent with an occupancy mode (`sole_occupier | partial_rental | …`). Diaspora-relevant (multi-gen / affordability), regulated on three axes.

#### S28. Cooling-off divergence (NSW / VIC / QLD) on the same strategy

**Stresses:** `buying_strategy`, `settlement_prep` · **COVERED**

**Walk.** `buying_strategy.transaction_mode.cooling_off_applies` + `cooling_off_days` derive from the transaction type and resolve state-specifics from `kb.cooling-off.by-state` + `kb.auction.rules-by-state` (auction = no cooling-off; private-treaty periods vary by state). State comes from `property_fit`.

**Landing.** **COVERED** — explicitly modelled and KB-grounded.

---

## Findings register

One row per finding (BREAK or DELEGATED-with-caveat). Status: `open` = surfaced, awaiting disposition decision. No blueprint edits made yet — this pass is find-only.

| ID | Scenario(s) | Break | Component(s) | Disposition (proposed) | Severity | Status |
|---|---|---|---|---|---|---|
| **F1** | S1, S4, S22/23 | B1, B2, B6 | buyer_profile, eligibility | Fix blueprint — **applicant array** with per-applicant `citizenship_status` / `firb_status` / `owner_occupier_intent` / ownership history; `firb_required` per-applicant; eligibility resolves against the applicant set; route any foreign applicant's interest to the FIRB path | **high** (FIRB gate, constraint #10) | **applied** — `buyer_profile` params (`application` + `applicants[]`) + `profile` outcome (`applicants[]`, `firb_required_any`); `eligibility` all-applicants scope note + `scheme_stack.eligibility_basis` / `structuring_options`; metadata `firb_required` reconciled. Validator green (45/45). |
| **F2** | S5 | B1 | buyer_profile, eligibility, ownership_planning | Fix blueprint — add `tax_residency` / `current_residence_country` per applicant; enables occupancy-feasibility + non-resident CGT/land-tax flags | med | **applied** — per-applicant `tax_residency` + `current_residence_country` in `applicants[]` + `profile` outcome. (Non-resident tax *rules* → KB verification.) |
| **F3** | S8 | B1 | buyer_profile, eligibility | Fix blueprint — add `ever_owned_and_occupied_residence` (owned-vs-occupied distinction; some FHB tests turn on occupation) | med | **applied** — per-applicant `ever_owned_and_occupied_residence` in `ownership_history` + `profile` outcome. (Per-scheme occupation tests → KB verification.) |
| **F4** | S10 | B1 | buyer_profile, eligibility | Fix blueprint — capture a non-buying partner's existence + ownership history (couple treated as one for FHOG/state schemes); **distinct from F1** — person isn't a co-buyer | med | **applied** — separate `non_buying_partner` block (chosen over an applicants[] flag) + `profile` outcome field + eligibility all-applicants fold-in. (Couple-as-one *rules* → KB verification.) |
| **F5** | S11 | B1, B2, ~~B3~~ | buyer_profile, cash_position, mortgage_finance | Fix blueprint — genuine-savings verdict *distinct from* cash-sufficiency; funds-provenance fact (AUSTRAC source-of-funds + VN capital-controls channel). ~~New KB doc~~ — not needed | **high** (signature diaspora pattern) | **applied** — `savings_and_deposit.funds_provenance` + `budget_envelope.genuine_savings_verdict` (resolver for determinate cases, `unknown` defers the rental-substitute to the agent). **B3 retracted**: genuine savings already owned by `kb.cash-reserve.lender-expectations` (existing cash_position anchor — 5%/3-mo, 1% rule, rental substitute, APRA APG 223); verdict points there, no duplicate doc. **Remaining**: AUSTRAC source-of-funds + VN capital-controls grounding for `funds_provenance` = compliance-gate / Wedge-2, not a Mode-A KB doc. |
| **F6** | S12 | B1 | buyer_profile, mortgage_finance | Fix blueprint — income source-country/currency fact; confirm a lender-treatment-of-foreign-income anchor (domestic self-employment already covered) | med | **applied** — `income.foreign_sourced_component` + `foreign_income_currency`; surfaced in `profile` outcome. (Lender foreign-income treatment → KB confirm.) |
| **F7** | S6, S15/16 | B2 | eligibility | Enhancement — replace scheme-eligibility bools with a structured banded result (`max_eligible_price`) instead of bool + narrative; also splits current-AU vs current-overseas ownership | low | **deferred** — base-scope but low; do alongside the per-property eligibility refinement |
| **F8** | S17, S18 | B1, B5 | property_assessment, mortgage_finance, cash_position, settlement_prep | Fix blueprint — **bank-valuation input** (distinct from agent estimate) + a `valuation_received` milestone + an edge recomputing cash on a shortfall | **high** (common, high-impact) | **deferred (Phase B)** — `property_assessment` / `settlement_prep` are per-property components, built later; add the slot then |
| **F9** | S19 | B1, B2 | property_assessment, mortgage_finance, cash_position | ~~Decision~~ **Defer (Phase B)** — same per-property bucket as F8; H&L only bites once a specific property is attached, so it's not a Wedge-1a decision. When it surfaces, **lean toward COVERING** (growth-corridor H&L is a primary FHB entry path, concentrated near the Vietnamese community hubs) | med | **deferred (Phase B)** |
| **F10** | S21 | B1 | mortgage_finance | Confirm KB — postcode/security-type LVR caps; delegable to `lender_synthesis` (agent) if `kb.lender.serviceability-basics` covers it | low | **deferred** — KB-confirm only, no schema change |
| **F11** | S25 | B1, B2 | mortgage_finance | Fix blueprint — track pre-approval as an expiring **date** with a re-application trigger (no owner of pre-settlement time-decay today) | med | **applied** — `pre_approval_granted_date` / `pre_approval_expiry_date` (derived) / `reapplication_required` in `pre_approval_workflow` + `mortgage_plan` outcome. (Alert firing is engine-owned.) |
| **F12** | S27 | B1 | buyer_profile, eligibility, ownership_planning | Fix blueprint — add an **occupancy mode** (`sole_occupier | partial_rental | …`); one fact touches land-tax + CGT + scheme occupancy | med-high (3 regulated axes) | **applied** — application-level `intended_occupancy_use` enum **+ kept** per-applicant `owner_occupier_intent` (chosen over collapsing the two); wired to `ownership_planning.land_tax_check` + `profile` outcome. |

### Engine-owned (not blueprint findings)

Surfaced by S2/S3/S22/S23/S24 — recorded so they aren't lost, but they belong to the engine/turn model ([isolation-model.md](../architecture/isolation-model.md)), not the blueprint:

- **Mode routing** (S2) — selecting/switching the mode→blueprint is an onboarding/engine act; confirm the onboarding flow routes a mis-self-selected foreign person to Mode B.
- **Re-resolution on mutation** (S3, S22/23, S24) — an upstream change (status, applicant set, target state) must invalidate + re-run downstream outcomes.
- **Outcome staleness provenance** (S3) — outcomes carry no `resolved_against` marker, so staleness isn't detectable from the artifact; consider when the engine schema lands.
- **target_zone ↔ location_state consistency** (S24) — not validated; a stale zone can survive a state switch.

### Pattern summary

Of 28 scenarios: **11 COVERED** (incl. 3 with minor flags), **6 DELEGATED**, **12 findings** (F1–F12; some scenarios share a finding). The COVERED set is the blueprint's core — scheme stacking, LVR-path comparison, debt optimisation, strata, settlement-by-state, cooling-off. Findings cluster in four bands:

1. **Household composition** — F1, F4 (+S4): the model assumes a single legal person; multi-party purchases (mixed-status couples, parent-on-title, non-buying spouses) are where the FIRB gate and the all-applicants eligibility test leak. *Highest-value band.*
2. **Residence & funds provenance** — F2, F5, F6: the diaspora-specific facts (overseas residence/tax-residency, gifted/foreign funds, foreign income) the single-buyer domestic model doesn't carry. *Most regulated band (FIRB-adjacent, AUSTRAC, capital controls).*
3. **Non-standard property structures** — F8, F9: bank valuation as a first-class post-contract input, and house-and-land as a different transaction shape.
4. **Time-decay & partial-use** — F11, F12: pre-approval expiry, and partial-rental occupancy.
