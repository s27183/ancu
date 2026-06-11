# Ongoing-costs projection — `ownership_planning` base-turn mechanics

**Status:** DONE & verified — `fh_engine_ownership` + `ownership_eval.py`/`ownership_conformance.escript` (14+17 lockstep green), full seam smoke green. Design pass below (define → simulate → document).
**Component:** `ownership_planning` (component 9, `fhb-domestic-au`), outcome `ongoing_obligations`.
**Mechanism:** (B) per-component formula code — the same class as `cash_position`'s stamp duty
([stamp-duty-concession-mechanics.md](stamp-duty-concession-mechanics.md)), reading KB
reference data + upstream outcomes and doing arithmetic + assembly. `agent_leaves: []` → the
turn dispatches it to the in-process resolver (`fh_engine_fill`), no sidecar, no `usage`.

This doc's job is to fix **the base-turn honest-partial boundary** — what `ownership_planning`
can compute from onboarding-only facts versus what it must leave pending — *before* code, because
the failure mode here is asserting a recurring-cost number from absent data (an ASIC
decision-support figure: "what this home costs you each month"). It is a
[base-turn-honest-partial-output] instance.

---

## 1. Placement & grounding

| Surface | Binding |
|---|---|
| Blueprint | component 9 `ownership_planning`, scope `both` (base estimate at onboarding; per-property refine post-settlement) |
| Outcome | `ongoing_obligations` — `{ total_monthly_outgoings_estimate, total_annual_outgoings_estimate, maintenance_reserve_target, graduation_milestone:{target_lvr, estimated_year}, alert_triggers_armed:[{trigger, action}] }` |
| Renderer | `data-table` + `opportunity-card` (composed; fill returns the primary `data-table`, the outcome carries both surfaces — cost lines → table, alerts/graduation → opportunity-card) |
| `dag_reads` (engine-passed Upstream) | `["property_fit", "scheme_stack", "budget_envelope", "mortgage_plan"]` — from the compiled artifact (this is the **authoritative** input set, see §7 seam) |
| KB anchors (all authored, structured) | `kb.ongoing-costs.rates-water-strata`, `kb.maintenance.budget-by-property-type`, `kb.land-tax.ppor-exemption`, `kb.graduation.lvr80`, `kb.refinance.windows-and-triggers` |

The five KB docs carry their figures as `parameters` (indicative bands, conventions, regulated
thresholds) with **empty `fills`** — pure mechanism-B reference data. KB supplies the data;
code supplies the arithmetic + assembly.

---

## 2. The base-turn honest-partial boundary (the load-bearing decision)

At the onboarding turn the fill has: `target_price_range` (→ ceiling `V`), `state`, `intent =
owner_occupier`, `intended_occupancy_use = sole_occupier`, `scheme_stack` (whether FHG is
applicable), and **coarse** upstream — `budget_envelope` with deposit/loan `null`, `mortgage_plan`
with only `expected_borrowing_capacity` (a range, itself income-pending), **no P&I field**,
`property_fit` with **no property** (so no property *type*: house vs strata is unknown).

The headline `total_monthly_outgoings_estimate` is dominated by mortgage **P&I**, which needs a firm
loan amount (`price − deposit`) and a rate — none available, and *no upstream field carries a
repayment figure*. **Decision: do not invent it.** No representative-LVR/sample-rate fabrication —
that asserts an ASIC figure from absent data and contradicts `cash_position` leaving deposit/loan
`null`. P&I and any total *including* it stay pending; we surface the **non-mortgage** recurring
holding costs (which *are* knowable) plus the determinate obligations and alerts.

| Outcome element | Base turn | Source / why |
|---|---|---|
| `land_tax_check` (→ note + alert) | **DETERMINATE** `exempt_ppor` | Mode-A owner-occupier `sole_occupier` → PPOR exempt all states (`ppor_exempt_all_states`). Regulated status. |
| `maintenance_reserve_target` | **COMPUTABLE** `0.01 × V` | `reserve_pct_of_value_default = 1%` × the range ceiling (a reserve, not a bill). Property-type caveat noted (house = full reserve; strata = interior-only, structural in the levy — don't double-count). |
| Recurring statutory costs (council rates + water) | **COMPUTABLE band** | KB bands: council `$1,200–2,500/yr` + water `$800–1,400/yr` = `$2,000–3,900/yr`. Orientation ranges; "binding figure is your rates notice." |
| `graduation_milestone.target_lvr` | **DETERMINATE** `80` | `graduation_lvr_threshold_pct`. |
| `alert_triggers_armed` | **ARMABLE** | FHG-graduation (if FHG in `scheme_stack`), periodic rate review (24-mo cadence), land-tax mode-switch (if home ceases to be PPOR → state threshold). The `opportunity-card` value even when totals are pending. |
| `graduation_milestone.estimated_year` | **PENDING** (KB band 4–8yr as orientation only) | Needs the LVR trajectory (starting LVR ← deposit, amortisation, growth) — income/deposit-dependent. |
| mortgage P&I; `total_monthly/annual_outgoings_estimate` incl. mortgage | **PENDING** | No firm loan/rate; no upstream repayment field. |
| strata levies | **PENDING** (conditional) | Needs property *type* (apartment/townhouse) — unknown at base (no property). |
| building-insurance premium; utilities (electricity/gas) | **PENDING** | No KB band; property/household-specific → per-property/refine (see §7 seam). |

The base output is therefore real and honest: **recurring statutory costs band + maintenance
reserve + PPOR land-tax status + armed lifecycle alerts**, with the mortgage-dependent and
property-type-dependent terms explicitly pending — never asserted.

---

## 3. Composition contract (field ← source)

```
total_monthly_outgoings_estimate   = null            (pending: P&I-dominated)
total_annual_outgoings_estimate    = null            (pending: P&I-dominated)
  recurring_statutory_costs_band   = { low:  council_low  + water_low,
                                       high: council_high + water_high }   ← ongoing-costs KB
  ( surfaced as a data-table line + note; excludes mortgage by construction )
maintenance_reserve_target         = round(0.01 × V)                       ← maintenance KB × ceiling
graduation_milestone               = { target_lvr: 80, estimated_year: null }  ← graduation KB
alert_triggers_armed               = [ FHG-graduation? , periodic-review , land-tax-mode-switch ]
                                                                            ← scheme_stack + refinance/land-tax KB
notes                              = [ pending-reasons, "binding figure is your rates notice", PPOR status ]
```

Every figure is KB-param-sourced or a stated arithmetic of one (`0.01 × V`); no literals in code.
`V` = the range **ceiling** (conservative, consistent with `cash_position` — highest costs there).

---

## 4. Verification discipline (the difference from stamp duty)

Stamp duty is a **regulated figure reproducible against an official calculator** → verified by
postcondition to the dollar ([verify-regulated-figures-by-postcondition]). Ongoing costs are
**mostly KB-curated indicative estimates** — there is *no* official "council rates calculator" to
match. So the verification splits:

- **Regulated postcondition (one item):** `land_tax_check = exempt_ppor` for the Mode-A
  owner-occupier; the per-state thresholds cited in the mode-switch alert (NSW $1.075M, VIC $50k,
  QLD $600k) are regulated figures **carried from KB**, not computed at base.
- **KB-param conformance (the estimates):** the conformance suite asserts the formula reads the KB
  band and applies the stated arithmetic — `maintenance = round(0.01 × V)` exactly; band =
  `Σ KB-lows .. Σ KB-highs`; `target_lvr = graduation_lvr_threshold_pct`. Ground truth is the **KB
  parameters (the SOT)**, not an external calculator. **Do not over-claim** "verified against
  official figures" for the cost estimates — they are orientation ranges, surfaced as ranges.

Same cross-language shape as cash: `tests/ownership_eval.py` (reads `artifact.json`) +
`ownership_conformance.escript` (calls the module) assert the same anchors → both locked to the KB
SOT and to each other.

---

## 5. Surfaced seams (flag, don't silently resolve)

- **(a) Blueprint input-set drift.** Component 9's prose header (blueprint:794) lists *Inputs:
  property_assessment + eligibility + cash_position* — **omitting `mortgage_finance`**. The pipeline
  diagram (blueprint:85) and the compiled `dag_reads` both **include `mortgage_plan`**. The artifact
  is authoritative (and semantically right — graduation/refi/P&I all depend on the loan). Fix: add
  `mortgage_finance.outcome` to the header. Doc-only; no code impact.
- **(b) KB gap: utilities & building-insurance premium.** The blueprint's
  `utility_estimate_combined` (electricity/gas) and `building_insurance_premium` have **no KB band**
  (the ongoing-costs doc owns council/water/strata only). At base these are pending → either author a
  band later or confirm they are intentionally per-property/refine (building insurance's sum-insured
  is genuinely property-specific). Flagged, not patched.

---

## 6. Code shape & build plan

1. `engine/erlang/src/fh_engine_ownership.erl` — `fill(Args, Upstream) -> {Outcome, <<"data-table">>, KbVersions}`.
   Reads `scheme_stack` (FHG?) + `intended_occupancy_use` + ceiling `V`; pulls KB params via
   `fh_engine_kb:kb_rules/1`; assembles the §3 contract; reuses `fh_engine_money:money/1` for notes
   and the cash `round-half-up` convention for `0.01 × V` (local `dollars/1` or shared — match cash).
2. `engine/erlang/src/fh_engine_fill.erl` — replace the provisional `ownership_planning` clause with
   `fh_engine_ownership:fill/2`.
3. `tests/ownership_eval.py` + `engine/erlang/test/ownership_conformance.escript` — KB-param
   conformance (maintenance, band, target_lvr, land_tax derivation, alert assembly) in lockstep.
4. Recompile, run resolver + cash-duty + ownership conformance, full seam smoke (NSW $700k).

## 7. Boundaries (refine-turn / per-property — explicitly NOT base)

mortgage P&I and totals-incl-mortgage (firm loan + rate); `estimated_graduation_year` and
`first_refi_window` (LVR trajectory + settlement date); strata levies (property type); building
insurance & utilities (per-property/behaviour); the post-settlement per-property refinement that
`scope: both` implies. Each fills when its facts arrive — never asserted at base.

---

**Sources.** KB: the five anchors in §1 (`docs/kb/...`). Upstream contract:
`engine/erlang/src/fh_engine_turn.erl` (`upstream_for`/`dag_reads`), the compiled `dag_reads`.
Pattern: [stamp-duty-concession-mechanics.md](stamp-duty-concession-mechanics.md),
[base-turn-honest-partial-output], [verify-regulated-figures-by-postcondition].
