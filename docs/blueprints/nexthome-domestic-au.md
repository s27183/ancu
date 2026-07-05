# Next-home plan card blueprint — Mode E (domestic, AU citizen/PR, repeat owner-occupier)

> Part of the **Vietnamese Diaspora Property Platform** document set. See [README.md](../README.md) for the full index.
>
> **This is a working specification** consumed by:
>
> - The offline KB agent (Claude Code + maintainer) to validate KB anchor coverage and renderer consistency
> - The user-facing planning agent at session time (loaded as system prompt context, rendered as plan card UI)
> - The migration script at deployment time to publish the blueprint into the `blueprints` table (replacing the prior deploy; git holds history)
>
> **Status: drafted 2026-07-05 (Mode-E wedge P2).** Not yet in `IN_SCOPE_BLUEPRINTS` (P3) or wired into onboarding dispatch (P5) — see [`../architecture/mode-e-wedge.md`](../architecture/mode-e-wedge.md). This blueprint is the closest sibling to [`fhb-domestic-au.md`](fhb-domestic-au.md) (Mode A) of any pair in the set: same domestic + owner-occupier cell (`fact-model-unification.md`'s "Mode is derived — three axes"), differing only in `plan.buyer_stage` (`first_home` vs `next_home`). Twelve of thirteen components are reused from Mode A verbatim or near-verbatim; **one is swapped** (`eligibility` → `existing_home_disposal`) and **one gets a new branch** (`cash_position`). Where a component below is unchanged from Mode A, its section says so explicitly and the schema is still fully declared here (each blueprint compiles to its own independent registry, [engine-contract.md](../architecture/engine-contract.md) §9.1 — "not one merged map").

---

## Metadata

```jsonc
{
  "blueprint_id": "nexthome-domestic-au",
  "effective_from": "2026-07-05",
  "effective_until": null,
  "buyer_mode": "nexthome",
  "user_mode": "E",
  "audience": "Vietnamese-Australian citizen or PR buying their next home (not first home) to live in — upsizer, downsizer, or relocator",
  "firb_required": false,
  "language_primary": "en",
  "language_alternate": "vi",
  "renderer_set": "fhb"
}
```

This blueprint serves **Mode E** users only — Vietnamese-Australian citizens and permanent residents who are **not** first-home buyers, purchasing a home to live in. The domestic + owner-occupier cell is shared with Mode A; the axis that separates them is `plan.buyer_stage` (`first_home` → Mode A, `next_home` → Mode E — [`fact-model-unification.md`](../architecture/fact-model-unification.md)). `buyer_stage` is **self-declared at onboarding**, never derived from `ownership_history` — a repeat buyer mis-flagged `first_home` would wrongly see FHG/FHSS/first-home-stamp-duty entitlements they cannot claim (misadvice risk, [`mode-e-wedge.md`](../architecture/mode-e-wedge.md) scoping decision).

A **foreign** next-home buyer (not citizen/PR + not-first-home + owner-occupier) is a **separate, out-of-scope combination** — established-dwelling-ban interaction with an already-owned AU property is a distinct regulated question. `blueprint_for/N` must fail closed on it (`{error, unsupported_combination}`), mirroring Mode D's SMSF-exclusion precedent — it is not silently absorbed into this blueprint or into Mode D.

---

## Component pipeline

The blueprint is a directed pipeline of thirteen components — the same count as Mode A, with `eligibility` (Mode A's #3) replaced by `existing_home_disposal`.

### Component scope (base plan vs property addendum)

| Component | Scope | Runs when |
|---|---|---|
| 1 buyer_profile | `base` | Onboarding; persistent across plan lifetime. **Unchanged from Mode A** — see component 1 below. |
| 2 property_assessment | `per-property` | When a specific (new) property is attached. **Unchanged from Mode A.** |
| 3 existing_home_disposal | `base` | Onboarding; projects the net proceeds of selling the buyer's **current** home to fund this purchase. **NEW — replaces Mode A's `eligibility` in this DAG slot.** |
| 4 mortgage_finance | `both` | Base estimate of borrowing capacity + lender shortlist. **Unchanged from Mode A** (its own `scheme_stack`-absence default already routes correctly with no `eligibility` component — see component 4). |
| 5 cash_position | `both` | Base estimate against target price range at onboarding. **Extended** — a new Mode-E branch folds `existing_home_disposal.net_sale_proceeds` into the HAVE side; the NEED side (duty, deposit, other costs) is byte-identical to Mode A's, with duty naturally computed at the **full** (no-concession) rate since no `scheme_stack` exists to gate a concession. |
| 6 buying_strategy | `per-property` | **Unchanged from Mode A.** |
| 7 due_diligence | `per-property` | **Unchanged from Mode A.** |
| 8 settlement_prep | `per-property` | **Unchanged from Mode A.** |
| 9 ownership_planning | `both` | **Unchanged from Mode A** for the NEW home's own ongoing obligations. Does **not** yet model land tax on the OLD home during a dual-ownership transition window — scoped out of P2, see the component's own note. |
| 10 purchase_journey | `base` | **Unchanged from Mode A**, reading `existing_home_disposal`'s outcome is not required (its cash effect surfaces through `cash_position`, which purchase_journey already reads). |
| 11 preparation | `base` | **Unchanged from Mode A.** |
| 12 phase_playbook | `base` | **Unchanged from Mode A.** |
| 13 disposition | `base` | **Reused unchanged.** Projects the **future** exit of the NEW home this plan is for — distinct from `existing_home_disposal` (3), which projects the **current** home being sold **now**. Same owner-occupier CGT path Mode A already runs (`fill_owner_occupier/2` — no code change; [`mode-e-wedge.md`](../architecture/mode-e-wedge.md) decision). |

```
[1] buyer_profile
       │   outcome: profile  (unchanged from Mode A)
       ▼
[2] property_assessment ◄── property_card from selection (per-property scope)
       │   outcome: property_fit  (unchanged from Mode A)
       ▼
[3] existing_home_disposal ◄── profile (household facts) + user-attested existing-home facts
       │   outcome: existing_home_disposal  (NEW)
       ▼
[4] mortgage_finance ◄── profile (incl. debts)   [[no scheme_stack input — none exists for Mode E]]
       │   outcome: mortgage_plan  (unchanged from Mode A; fill_fhb/2 already defaults gracefully to no-FHG when scheme_stack is absent)
       ▼
[5] cash_position ◄── profile, property_fit, mortgage_plan, existing_home_disposal
       │   outcome: budget_envelope  (Mode-E branch — HAVE side extended)
       ▼
[6] buying_strategy ◄── property_fit, budget_envelope, mortgage_plan
       │   outcome: bid_plan  (unchanged from Mode A)
       ▼
[7] due_diligence ◄── property_fit, uploaded_docs
       │   outcome: risk_assessment  (unchanged from Mode A)
       ▼
[8] settlement_prep ◄── property_fit, bid_plan, mortgage_plan
       │   outcome: settlement_checklist  (unchanged from Mode A; no scheme_application_milestones since no scheme_stack)
       ▼
[9] ownership_planning ◄── property_fit, cash_position, mortgage_plan
           outcome: ongoing_obligations  (unchanged from Mode A; dual-ownership land tax deferred, see component note)
```

> `existing_home_disposal` takes `eligibility`'s DAG slot (right after `buyer_profile`, before `mortgage_finance`) as a placement convention, not a data dependency — unlike `eligibility`, it needs no `property_fit` and nothing downstream except `cash_position` reads it. `mortgage_finance` reads only `profile`, same as Mode A's own inputs list already declares (Mode A's `scheme_stack` read exists only to detect FHG — absent here by construction, not by a missing edge). `disposition` (13) and the remaining base-scope projection components (`purchase_journey` 10, `preparation` 11, `phase_playbook` 12) are unchanged from Mode A's own diagram — see [`fhb-domestic-au.md`](fhb-domestic-au.md) for their full text; they are still declared component-by-component below since this blueprint compiles independently.

**UI tab mapping** — unchanged from Mode A ([`../architecture/lifecycle-simulation-model.md`](../architecture/lifecycle-simulation-model.md) §7): Overview / Flow / Budget / Q&A. The Budget view additionally surfaces `existing_home_disposal`'s net-proceeds figure as a HAVE-side contributor, drilling to component 3 the same way every other cash-event row drills to its `source_component`.

```jsonc
{
  "ui_tabs": [
    { "tab_id": "overview", "kind": "synthesis",  "components": ["buyer_profile", "existing_home_disposal", "mortgage_finance", "cash_position"] },
    { "tab_id": "flow",     "kind": "flow",        "components": ["purchase_journey", "phase_playbook", "settlement_prep"] },
    { "tab_id": "budget",   "kind": "components", "interactive": true, "components": ["cash_position", "disposition"] },
    { "tab_id": "qa",       "kind": "qa",          "components": [] }
  ]
}
```

---

## Components

### 1. buyer_profile

**Unchanged from Mode A.** Same goal, inputs, KB anchors, renderer, parameters, and `profile` outcome schema as [`fhb-domestic-au.md`](fhb-domestic-au.md) component 1 — the unified fact base is mode-independent by design ([`fact-model-unification.md`](../architecture/fact-model-unification.md)); Mode E populates the same subset a Mode A rentvestor would (`household_financials.existing_portfolio.ppor_owned`/`ppor_estimated_equity` are already-defined slots, active here for the first time in a domestic owner-occupier context rather than an investor one).

**Goal:** Capture and structure the buyer's situation — citizenship, residency, age, ownership history, income, savings, debt, family financial pooling, employment.

**Inputs:** User questions answered in chat; any uploaded documents. No upstream component dependency — this is the pipeline entry.

**KB anchors:** `kb.hecs.thresholds`, `kb.firb.status-determination`, `kb.lender.serviceability-basics`

**Renderer:** `summary-card`

**UI tab hint:** Overview (collapsed) + Before you buy (detail)

**Parameters:** identical to Mode A's — `application` (incl. `intended_occupancy_use`), `applicants[]`, `off_title_parties[]`, `income`, `savings_and_deposit`, `debts`, `timeline`, `purchase_target`. One addition specific to Mode E's need:

```jsonc
{
  "existing_home_ownership": {
    "currently_owns_ppor": { "type": "bool", "value": true, "note": "Mode E is entered ONLY when true — a repeat owner-occupier who currently owns and lives in a home. Ground for existing_home_disposal (component 3)." },
    "ppor_estimated_value": { "type": "money", "value": "<initial>", "note": "the buyer's own estimate of their current home's value — user-attested, never a KB estimate. Read by existing_home_disposal as the sale-price basis." },
    "ppor_outstanding_loan_balance": { "type": "money", "value": "<initial>", "note": "user-attested; the loan-payout basis for existing_home_disposal." },
    "ppor_loan_rate_type": { "type": "enum", "options": ["fixed", "variable", "unknown"], "value": "<initial>", "note": "gates existing_home_disposal's break-cost to_verify flag (kb.existing-home-sale.net-proceeds)." },
    "ppor_rental_history": { "type": "bool", "value": false, "note": "true if the current home was ever rented out during ownership — gates the CGT main-residence exemption's partial/6-year-rule path (kb.tax.cgt-main-residence-exemption, reused by existing_home_disposal)." }
  }
}
```

**Outcome schema:** `profile` — identical field set to Mode A's ([`fhb-domestic-au.md`](fhb-domestic-au.md) component 1), plus:

```jsonc
{
  "existing_home_ownership": "{ currently_owns_ppor: bool, ppor_estimated_value: money|null, ppor_outstanding_loan_balance: money|null, ppor_loan_rate_type: enum [fixed, variable, unknown]|null, ppor_rental_history: bool }"
}
```

---

### 2. property_assessment

**Unchanged from Mode A.** Same goal, inputs, KB anchors, renderer, parameters, and `property_fit` outcome schema as [`fhb-domestic-au.md`](fhb-domestic-au.md) component 2 — analyses the **new** property being considered, exactly as Mode A does. This component never reads or produces anything about the buyer's *existing* home; that is `existing_home_disposal`'s (3) exclusive concern — no overlap, no double-count.

---

### 3. existing_home_disposal

**Goal:** Project the net proceeds of selling the buyer's **current** home — the one they already own and live in — to fund this purchase. This is a **different transaction from `disposition`** (13): `disposition` projects the **future** exit of the property this plan is *for* (years out, present only when a hold horizon is set); this component projects the **current** home being sold **now**, feeding `cash_position`'s HAVE side as a new cash source. It is the one genuinely new component Mode E requires — no prior mode sells a currently-held property mid-plan ([`kb.existing-home-sale.net-proceeds`](../kb/existing-home-sale/net-proceeds.md)).

**Scope:** `base` — runs at onboarding against the buyer's own attested facts about their current home (`buyer_profile.existing_home_ownership`). There is no per-property refinement of *this* component (the property being sold is not one the user "attaches" via Tìm Nhà/URL-paste/browser-extension — it is the home they already live in, described entirely by user attestation).

**Inputs:** `buyer_profile.outcome` (`profile.existing_home_ownership` — the sale-price estimate, outstanding loan balance, loan rate type, rental history; `profile.applicants[].tax_residency` — the CGT non-resident trap) + the plan's own settlement-timing facts (the new purchase's expected settlement vs. the existing home's sale status — captured the same way `settlement_prep`'s dates are, via structured attestation, not extraction).

**KB anchors:** `kb.existing-home-sale.net-proceeds`, `kb.selling-costs.agent-legal` (reused, not duplicated — same computer `fh_engine_disposition:selling_costs/1`), `kb.tax.cgt-main-residence-exemption` (reused — same computer `fh_engine_disposition:cgt/1`), `kb.bridging-finance.mechanics` (placeholder hand-off on a timing mismatch)

**Renderer:** `calculator`

**UI tab hint:** Overview (summary) + Budget (feeds the HAVE side alongside `cash_position`)

**Fill path:** resolver. Loan payout, selling costs, and CGT are all deterministic from KB + user-attested facts — no agent leaf. Reliability is structural: the break-cost dollar figure is never estimated (only a `to_verify` flag), and CGT/selling-costs are **one-computer-per-figure** reuses of `fh_engine_disposition`'s existing `cgt/1` and `selling_costs/1`, never re-derived.

**Parameters:**

```jsonc
{
  "sale_basis": {
    "estimated_sale_price": { "type": "money", "value": "<from_buyer_profile>", "note": "profile.existing_home_ownership.ppor_estimated_value" }
  },
  "loan_payout": {
    "outstanding_balance": { "type": "money", "value": "<from_buyer_profile>", "note": "profile.existing_home_ownership.ppor_outstanding_loan_balance — user-attested, never inferred" },
    "discharge_fee": { "type": "money_range", "value": "<initial>", "note": "kb.existing-home-sale.net-proceeds discharge_fee_low_aud/high_aud — market convention, not regulated" },
    "break_cost_status": { "type": "enum", "options": ["not_applicable", "to_verify"], "value": "<initial>", "derived_from": "profile.existing_home_ownership.ppor_loan_rate_type", "note": "variable → not_applicable (exit-fee ban, kb.existing-home-sale.net-proceeds); fixed → to_verify (lender-quoted break cost, never estimated); unknown → to_verify" },
    "total_payout": { "type": "money", "value": "<initial>", "note": "outstanding_balance + discharge_fee; null while break_cost_status = to_verify AND the rate is fixed (honest-partial — the break cost is an unknown addend, not zero)" }
  },
  "selling_costs": {
    "total": { "type": "money_range", "value": "<initial>", "note": "REUSED from kb.selling-costs.agent-legal via fh_engine_disposition:selling_costs/1 — same computer as disposition's own selling_costs, applied to estimated_sale_price instead of a projected future sale_proceeds" }
  },
  "cgt": {
    "status": { "type": "enum", "options": ["exempt", "to_verify"], "value": "<initial>", "note": "REUSED from kb.tax.cgt-main-residence-exemption via fh_engine_disposition:cgt/1 — exempt for the clean main-residence case; to_verify once profile.existing_home_ownership.ppor_rental_history is true or an applicant's tax_residency is non_resident" },
    "estimate": { "type": "money", "value": "<initial>", "note": "null on the exempt path — Mode E never estimates a taxable gain, same discipline as Mode A's own disposition" }
  },
  "net_sale_proceeds": {
    "amount": { "type": "money_range", "value": "<initial>", "note": "estimated_sale_price − loan_payout.total_payout − selling_costs.total − cgt.estimate (null when any contributing line is pending — honest-partial, never a partial sum)" }
  },
  "settlement_timing": {
    "new_purchase_settlement_date": { "type": "date", "value": "<initial>" },
    "existing_home_sale_status": { "type": "enum", "options": ["not_yet_listed", "listed", "under_contract", "settled"], "value": "<initial>" },
    "mismatch_detected": { "type": "bool", "value": "<initial>", "note": "true when new_purchase_settlement_date precedes the existing home's expected/actual sale settlement, or existing_home_sale_status is not yet under_contract/settled by that date — a plain date/status comparison, no professional judgement" }
  },
  "bridging_finance": {
    "considered": { "type": "bool", "value": "<initial>", "derived_from": "settlement_timing.mismatch_detected" },
    "is_placeholder": { "type": "bool", "value": true, "note": "kb.bridging-finance.mechanics — the economics (peak debt, capitalised interest, lender terms) are NOT computed here; only the structural timing fact is detected. ACL/credit-advice risk, per mode-e-wedge.md scoping decision #3." }
  }
}
```

**Outcome schema:** `existing_home_disposal`

```jsonc
{
  "type": "existing_home_disposal",
  "fields": {
    "estimated_sale_price": "money|null",              // user-attested; null until the buyer provides it (honest-partial, no onboarding capture of this fact — plan-first)
    "loan_payout": "{ outstanding_balance: money|null, discharge_fee: money_range|null, break_cost_status: enum [not_applicable, to_verify], total_payout: money|null }",
    "selling_costs": "money_range|null",               // REUSED figure — fh_engine_disposition:selling_costs/1, not a second computer
    "cgt": "money_range|null",                         // REUSED figure — fh_engine_disposition:cgt/1
    "cgt_status": "enum [exempt, to_verify]",
    "net_sale_proceeds": "money_range|null",           // sale_price − loan_payout.total_payout − selling_costs − cgt; null if any line is pending
    "settlement_timing_mismatch": "bool",              // structural fact — new purchase settling before the existing home sale settles
    "bridging_finance_considered": "bool",             // set from settlement_timing_mismatch; never computes economics itself
    "bridging_finance_is_placeholder": "bool",         // always true until kb.bridging-finance.mechanics is re-grounded
    "key_assumptions": "array<localized_text>"
  }
}
```

At base, `estimated_sale_price` / `outstanding_balance` are honestly null (no onboarding capture — plan-first, constraint #1); `net_sale_proceeds` is therefore null until a refine turn supplies the buyer's own attested figures, the same honest-partial posture Mode A's `budget_envelope.cash_available` holds at base for want of a savings figure.

---

### 4. mortgage_finance

**Unchanged from Mode A.** Same goal, KB anchors, renderer, parameters, and `mortgage_plan` outcome schema as [`fhb-domestic-au.md`](fhb-domestic-au.md) component 4.

**Inputs:** `buyer_profile.outcome` only (profile, including debts). Mode A's own inputs line additionally names `eligibility.outcome` (scheme_stack) solely to detect FHG eligibility for `recommended_path`; Mode E has no `eligibility` component, so this read is simply absent. **No code or schema change is required**: the resolver's own `fill_fhb/2` already defaults `Stack = maps:get(<<"scheme_stack">>, Upstream, #{})` to `#{}` when the key is absent, and `has_fhg(#{})` correctly returns false — routing every Mode E buyer to the LMI-backed or 20%+-deposit path, never a spuriously-FHG-backed one. This is the correct answer independent of the missing component: a repeat buyer is never FHG-eligible either (First Home Guarantee is first-home-only), so the honest default and the regulatory fact agree.

---

### 5. cash_position

**Goal:** Compute the buyer's full cash needs at settlement — **and now also a genuine HAVE-side source**, the net proceeds of selling their current home — identify any gap, and produce a budget envelope and verdict.

**Inputs:** `buyer_profile.outcome` + `property_assessment.outcome` + `mortgage_finance.outcome` + **`existing_home_disposal.outcome`** (new).

**KB anchors:** `kb.stamp-duty.calc-by-state`, `kb.buyer-costs.inspections-conveyancing-fees`, `kb.cash-reserve.lender-expectations`, `kb.lmi.calculation` — identical to Mode A's; no `eligibility`-linked anchor since no `scheme_stack` exists to gate a state concession (a repeat buyer pays full stamp duty — every state's first-home concession requires first-home status, so the absence of a concession is the regulatory fact, not a gap).

**Renderer:** `calculator`

**UI tab hint:** Budget (interactive financial spine) + Overview (summary)

**Parameters:** identical to Mode A's `deposit`, `stamp_duty`, `other_buying_costs`, `reserve_buffer` blocks (see [`fhb-domestic-au.md`](fhb-domestic-au.md) component 5) — the NEED side is byte-identical logic, naturally evaluated at the **full** (no-concession) duty rate. One addition:

```jsonc
{
  "totals": {
    "cash_available": { "type": "money", "value": "<from_property_assessment>", "note": "MODE-E EXTENSION: HAVE side now includes existing_home_disposal.net_sale_proceeds when computed (in addition to cash_on_hand + fhss_release + family_contribution, all still honestly null at base pending a refine turn — Mode E has no FHSS/family-gift concept beyond what buyer_profile already captures). Still null at BASE (existing_home_disposal's own inputs are user-attested facts not captured at onboarding), so this is a refine-turn improvement, not a base-turn one — the base honest-partial posture is unchanged from Mode A." }
  }
}
```

**Outcome schema:** `budget_envelope` — identical field set and shape to Mode A's (see [`fhb-domestic-au.md`](fhb-domestic-au.md) component 5), with `cash_available`'s note extended: **HAVE side = cash_on_hand + fhss_release + family_contribution + `existing_home_disposal.net_sale_proceeds`** (the last term is Mode E's own addition; the rest reads exactly as Mode A). `gap_or_surplus` and `verdict` follow unchanged once any HAVE-side figure populates.

**Mode discriminator (engine note, not blueprint text — recorded here since it grounds the resolver P2 work):** `fh_engine_cash:fill/2` currently branches on `tax_optimised_structure` presence (investor) then `firb_required_any` (foreign) — neither distinguishes Mode A from Mode E, since both are domestic + owner-occupier. The Mode-E branch is selected by **`existing_home_disposal` outcome presence in Upstream** (mirroring how `tax_optimised_structure` presence marks the investor path) — only Mode E's DAG runs that component, so its presence is a clean, existing-pattern discriminator. This wiring (the DAG order + the Upstream key) is fixed by `IN_SCOPE_BLUEPRINTS` activation (P3) and `base_components/1` (P5), not by this document.

---

### 6. buying_strategy

**Unchanged from Mode A.** Same goal, inputs, KB anchors, renderer, parameters, and `bid_plan` outcome schema as [`fhb-domestic-au.md`](fhb-domestic-au.md) component 6.

---

### 7. due_diligence

**Unchanged from Mode A.** Same goal, inputs, KB anchors, renderer, parameters, and `risk_assessment` outcome schema as [`fhb-domestic-au.md`](fhb-domestic-au.md) component 7.

---

### 8. settlement_prep

**Unchanged from Mode A**, less the `scheme_application_milestones` block (no scheme applications to track — no `eligibility` component). Same goal, KB anchors, renderer, and remaining parameters/outcome schema as [`fhb-domestic-au.md`](fhb-domestic-au.md) component 8.

**Inputs:** `property_assessment.outcome` + `bid_plan` (only if buying proceeded) — Mode A's own inputs line additionally names `eligibility.outcome`, read solely for `scheme_application_milestones`; that block is dropped here (see outcome schema below), so the read is dropped with it.

**Outcome schema:** `settlement_checklist` — identical to Mode A's `key_dates` / `milestones` / `counterparties` fields; **`scheme_application_milestones` is omitted** (no scheme applications exist for a repeat buyer).

---

### 9. ownership_planning

**Goal:** Project ongoing costs and obligations after settlement **for the new home**, and set alert triggers for refinance windows, graduation events, and rate moves — **unchanged from Mode A**.

**Inputs:** `property_assessment.outcome` + `cash_position.outcome` + `mortgage_finance.outcome` — identical to Mode A's, less `eligibility.outcome` (no `scheme_specific_alerts.fhg_loan_active` — a repeat buyer cannot hold an FHG-backed loan).

**KB anchors:** `kb.ongoing-costs.rates-water-strata`, `kb.refinance.windows-and-triggers`, `kb.graduation.lvr80`, `kb.land-tax.ppor-exemption`, `kb.maintenance.budget-by-property-type` — identical to Mode A's.

**Scope note — dual-ownership land tax deferred, not built.** While the buyer holds **both** the old and new home during the transition, the old home's land-tax exemption follows [`kb.land-tax.dual-ownership-transition`](../kb/land-tax/dual-ownership-transition.md) (authored in P1), not the single-PPOR `kb.land-tax.ppor-exemption` this component already reads for the **new** home. Wiring the transition-period check into `ownership_planning` (or a sibling resolver) is **not done in P2** — it was not named in the P2 scope (`mode-e-wedge.md`'s own phase table lists only the existing-home-disposal resolver, the eligibility drop, and disposition reuse) and requires a fact this blueprint does not yet model (that the OLD home is still held, distinct from `existing_home_disposal`'s sale-in-progress tracking). Flagged here as an explicit, honest gap for a future phase — not silently absorbed into this component's existing `land_tax_check` field, which continues to describe only the NEW home.

**Parameters and outcome schema:** identical to Mode A's (see [`fhb-domestic-au.md`](fhb-domestic-au.md) component 9), less `scheme_specific_alerts`.

---

### 10. purchase_journey

**Unchanged from Mode A.** Same goal, inputs, KB anchors, renderer, and `journey_swimlane` outcome schema as [`fhb-domestic-au.md`](fhb-domestic-au.md) component 10. It does not need a direct read of `existing_home_disposal` — that component's cash effect (`net_sale_proceeds`) already surfaces through `cash_position.budget_envelope.cash_available`/`cash_events`, which this component already reads and places.

---

### 11. preparation

**Unchanged from Mode A**, less any scheme-application readiness items (no `eligibility` component to place from). Same goal, KB anchors, renderer, and outcome schema as [`fhb-domestic-au.md`](fhb-domestic-au.md) component 11; `scheme_applications_to_prepare` is always empty for Mode E (honestly, not silently — the field stays in the schema, populated `[]`).

---

### 12. phase_playbook

**Unchanged from Mode A.** Same goal, inputs, KB anchors, renderer, and `phase_playbook` outcome schema as [`fhb-domestic-au.md`](fhb-domestic-au.md) component 12.

---

### 13. disposition

**Reused unchanged — zero code change.** Projects the financial outcome of disposing of the **new** property (the one this plan is for) after a hold horizon `H` — the same **future**-exit projection Mode A runs, on the exact same owner-occupier CGT path (`fh_engine_disposition:fill_owner_occupier/2`, dispatched because no `tax_optimised_structure` outcome exists upstream — identical to Mode A's own dispatch condition). See [`fhb-domestic-au.md`](fhb-domestic-au.md) component 13 for the full goal, inputs, KB anchors, renderer, parameters, and `disposition` outcome schema — all identical here.

**Why this is a genuine, verified reuse, not an assumption.** `fill_owner_occupier/2` reads `budget_envelope` (from `cash_position`) and `mortgage_plan` (from `mortgage_finance`) — both outcome **types**, not mode-specific shapes. Mode E's `cash_position` (component 5) still produces a `budget_envelope`-typed outcome (extended, not retyped) and Mode E's `mortgage_finance` (component 4) still produces `mortgage_plan` unchanged — so `disposition`'s existing dispatch and computation apply without modification. This is the distinct **future**-exit counterpart to `existing_home_disposal` (3)'s **current**-sale computation; the two never read each other and never double-count a figure.

---

## KB anchor index (for this blueprint)

| Slug | Component(s) | Owns |
|---|---|---|
| `kb.hecs.thresholds` | 1 | HECS repayment thresholds, treatment by lenders |
| `kb.firb.status-determination` | 1 | How to determine FIRB classification from visa/citizenship status |
| `kb.lender.serviceability-basics` | 1, 4 | Lender serviceability assessment basics |
| `kb.property.suburb-risk-factors` | 2 | Suburb-level risk factors |
| `kb.property.comparables-methodology` | 2 | Comparable-sales methodology |
| `kb.strata.health-indicators` | 2 | Strata report red flags |
| `kb.building-types.risk-by-type` | 2 | Risk profiles by property type |
| `kb.existing-home-sale.net-proceeds` | 3 | **NEW** — loan-payout mechanics (discharge fee, break-cost framing, exit-fee ban) for the current home sold now; the reused selling-costs/CGT figures are pointed to, not re-derived here |
| `kb.selling-costs.agent-legal` | 3, 13 | Sale-side cost bands — REUSED by both the current-sale (3) and future-exit (13) computations, one computer |
| `kb.tax.cgt-main-residence-exemption` | 3, 13 | Main-residence CGT exemption — REUSED by both computations |
| `kb.bridging-finance.mechanics` | 3 | **NEW, placeholder** — settlement-timing-mismatch detection only; economics gated |
| `kb.lender.fhg-panel-list` | 4 | Referenced defensively (never applies — no FHG for a repeat buyer; the resolver's own scheme_stack-absence default already routes correctly) |
| `kb.lender.hecs-treatment-by-lender` | 4 | Per-lender HECS treatment |
| `kb.lender.credit-card-treatment` | 4 | Credit-card treatment |
| `kb.lender.bnpl-treatment-2026` | 4 | BNPL treatment |
| `kb.lmi.calculation` | 4, 5 | LMI estimation (no FHG path for Mode E — always the LMI-backed or 20%+-deposit path) |
| `kb.offset-account.basics` | 4 | Offset account mechanics |
| `kb.stamp-duty.calc-by-state` | 5 | Stamp duty — always the FULL (no-concession) rate for Mode E |
| `kb.buyer-costs.inspections-conveyancing-fees` | 5 | Buyer-side transaction costs |
| `kb.cash-reserve.lender-expectations` | 5 | Post-settlement reserve expectations |
| `kb.auction.rules-by-state` | 6 | Auction rules |
| `kb.cooling-off.by-state` | 6, 8 | Cooling-off periods |
| `kb.negotiation.patterns-by-market-condition` | 6 | Negotiation patterns |
| `kb.agent-tactics.detection` | 6 | Agent tactics and counters |
| `kb.comparables.reading-the-room` | 6 | Interpreting comparables |
| `kb.contract-of-sale.review-points-by-state` | 7 | CoS review points |
| `kb.s32.review-points` | 7 | Section 32 review points (VIC) |
| `kb.building-pest.interpretation` | 7 | Building/pest report interpretation |
| `kb.strata-report.red-flags` | 7 | Strata report red flags |
| `kb.special-conditions.standard-set` | 7 | Standard special conditions |
| `kb.settlement.process-by-state` | 8 | Settlement process per state |
| `kb.pexa.settlement` | 8 | PEXA mechanics |
| `kb.insurance.timing-of-risk-pass` | 8 | Risk-pass timing |
| `kb.lender-docs.standard-timeline` | 8 | Lender document timeline |
| `kb.ongoing-costs.rates-water-strata` | 9 | Council/water/strata ranges |
| `kb.refinance.windows-and-triggers` | 4, 9 | Refinance mechanics |
| `kb.graduation.lvr80` | 9 | 80% LVR graduation |
| `kb.land-tax.ppor-exemption` | 9 | Land-tax PPOR exemption — the NEW home only |
| `kb.land-tax.dual-ownership-transition` | *(not yet wired — deferred, see component 9's scope note)* | Per-state transition-window land tax when holding both properties |
| `kb.maintenance.budget-by-property-type` | 9 | Maintenance budget heuristics |
| `kb.journey.fhg-path` | 10 | Reused lifecycle template — bilingual prose is generic to the purchase lifecycle, not first-home-specific; `kb.journey.*` naming stays as-is (content-only reuse, same as Mode B/C/D) |
| `kb.preparation.fhb-readiness` | 11 | Reused readiness template — generic document/people checklist; the FHB-specific items degrade to empty per component 11's note |
| `kb.journey.phase-actions` | 12 | Reused per-phase action template |
| `kb.risks.fhb-by-phase` | 12 | Reused per-phase risk template |
| `kb.property.capital-growth-bands` | 13 | Reused capital-growth placeholder band |

---

## Renderer vocabulary used

Same 9 renderers as Mode A ([architecture.md §11.9](../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)) — no new renderer required (confirms `mode-e-wedge.md` P4's expectation).

| Renderer | Used by component(s) |
|---|---|
| `summary-card` | 1 buyer_profile, 2 property_assessment, 4 mortgage_finance |
| `calculator` | 3 existing_home_disposal, 5 cash_position, 13 disposition |
| `buying-strategy-card` | 6 buying_strategy |
| `risk-flag-list` | 7 due_diligence, 12 phase_playbook |
| `checklist` | 7 due_diligence, 8 settlement_prep, 11 preparation, 12 phase_playbook |
| `swimlane-diagram` | 8 settlement_prep, 10 purchase_journey |
| `data-table` | 4 mortgage_finance, 9 ownership_planning, 11 preparation |
| `opportunity-card` | 9 ownership_planning |

---

## Cross-component output dependency graph

```
buyer_profile           → outcome: profile                    (no upstream)
property_assessment     → outcome: property_fit               (reads: profile)
existing_home_disposal  → outcome: existing_home_disposal     (reads: profile)
mortgage_finance        → outcome: mortgage_plan               (reads: profile)
cash_position           → outcome: budget_envelope             (reads: profile, property_fit, mortgage_plan, existing_home_disposal)
buying_strategy         → outcome: bid_plan                    (reads: property_fit, budget_envelope, mortgage_plan)
due_diligence           → outcome: risk_assessment             (reads: property_fit, uploaded_docs)
settlement_prep         → outcome: settlement_checklist        (reads: property_fit, bid_plan, mortgage_plan)
ownership_planning      → outcome: ongoing_obligations         (reads: property_fit, budget_envelope, mortgage_plan)
disposition             → outcome: disposition                 (reads: profile, property_fit, mortgage_plan, budget_envelope, ongoing_obligations)
purchase_journey        → outcome: journey_swimlane            (reads: mortgage_plan, budget_envelope, ongoing_obligations, disposition)
phase_playbook          → outcome: phase_playbook               (reads: budget_envelope, journey_swimlane)
preparation             → outcome: preparation_plan             (reads: budget_envelope)
```

No cycles. `existing_home_disposal` has no upstream dependency beyond `profile` — it could in principle run in parallel with `property_assessment`; it is ordered right after `buyer_profile` (mirroring `eligibility`'s old DAG slot) as a placement convention. `cash_position` is the only component reading `existing_home_disposal`, so that edge is the sole reason it must precede `cash_position`. Every other edge is identical to Mode A's own dependency graph, less the `scheme_stack` edges `eligibility` used to supply.

---

## Open questions / future iteration

1. **Dual-ownership land tax during the transition** — deferred from P2 (component 9's scope note). A future phase should decide whether this rides `ownership_planning` (an added `old_home_land_tax_check` field) or a new sibling resolver, once a real trigger (a live Mode-E plan holding both properties) surfaces the need.
2. **Bridging finance mechanics** — placeholder per `kb.bridging-finance.mechanics`; re-ground before computing peak debt or naming a lender.
3. **Multi-state dual-ownership confidence gaps** — WA's transition-exemption duration and NT's no-land-tax status are flagged `to_verify` in the KB doc itself; re-verify before this blueprint's own confidence in `existing_home_disposal`'s downstream framing is upgraded.
4. **Blueprint slug naming** — `nexthome-domestic-au` was chosen over forcing `fhb`/`investor` prefixes (see `mode-e-wedge.md` decision #5 and [architecture.md §11.9](../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification) "Mode E's slug deliberately drops...").

---

## Document control

- **Status:** draft, 2026-07-05 — Mode-E wedge P2
- **Author:** Strategic design synthesis (Claude + maintainer)
- **Consumers:** Offline KB agent, user-facing planning agent, migration script, UI renderer layer
- **Sibling blueprint:** [`fhb-domestic-au.md`](fhb-domestic-au.md) (Mode A) — the closest structural pair in the set; 12 of 13 components reused verbatim or near-verbatim
- **Disclaimer:** This is a working spec, not a regulatory document. Actual tax, land-tax, and lending rules must be confirmed against authoritative sources (resolved via kb_anchor lookups) at runtime.
