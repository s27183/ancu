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

**UI tab mapping** — unchanged from Mode A ([`../architecture/lifecycle-simulation-model.md`](../architecture/lifecycle-simulation-model.md) §7): Budget / Overview / Flow / Q&A (Budget lands first, 2026-08, Son's call). The Budget view additionally surfaces `existing_home_disposal`'s net-proceeds figure as a HAVE-side contributor, drilling to component 3 the same way every other cash-event row drills to its `source_component`.

```jsonc
{
  "ui_tabs": [
    { "tab_id": "budget",   "kind": "components", "interactive": true, "components": ["cash_position", "disposition"] },
    { "tab_id": "overview", "kind": "synthesis",  "components": ["buyer_profile", "existing_home_disposal", "mortgage_finance", "cash_position"] },
    { "tab_id": "flow",     "kind": "flow",        "components": ["purchase_journey", "phase_playbook", "settlement_prep"] },
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

**Parameters:** identical field set to Mode A's ([`fhb-domestic-au.md`](fhb-domestic-au.md) component 1) — declared in full here since each blueprint compiles to its own independent registry (a prose cross-reference alone leaves no `applicant.*` fields for `kb.firb.status-determination` to resolve against; P3 activation surfaced this), plus one Mode-E-specific addition at the end.

```jsonc
{
  "application": {
    "location_state": { "type": "enum", "options": ["NSW", "VIC", "QLD", "WA", "SA", "TAS", "ACT", "NT"], "value": "<initial>" },
    "applicant_count": { "type": "integer", "value": 1, "note": "= applicants[] length." },
    "dependents_count": { "type": "integer", "value": 0 },
    "intended_occupancy_use": { "type": "enum", "options": ["sole_occupier", "partial_rental", "granny_flat", "not_occupied"], "value": "sole_occupier", "note": "F12 — DWELLING-level use for the NEW home. Drives ownership_planning.land_tax_check." }
  },
  "applicants": {
    "type": "array<applicant>",
    "note": "F1 — one entry per person taking a legal/ownership interest in the NEW purchase. Same per-applicant FIRB gate as Mode A (constraint #10): a foreign co-applicant on an otherwise-domestic repeat purchase still trips the gate and is routed out (this blueprint's own out-of-scope note above) — Mode E is not exempt from the per-applicant classification kb.firb.status-determination performs.",
    "value": [
      {
        "role": { "type": "enum", "options": ["primary", "co_buyer"], "value": "primary" },
        "citizenship_status": { "type": "enum", "options": ["citizen", "permanent_resident", "temporary_resident", "non_resident"], "value": "<initial>" },
        "firb_status": { "type": "enum", "options": ["not_foreign_person", "foreign_person"], "value": "<initial>", "derived_from": "citizenship_status" },
        "tax_residency": { "type": "enum", "options": ["resident", "non_resident", "temporary_resident_for_tax"], "value": "<initial>" },
        "current_residence_country": { "type": "string", "value": "<initial>" },
        "age": { "type": "integer", "value": "<initial>" },
        "owner_occupier_intent": { "type": "bool", "value": true },
        "ownership_history": {
          "ever_owned_au_property": { "type": "bool", "value": "<initial>" },
          "ever_owned_and_occupied_residence": { "type": "bool", "value": "<initial>" },
          "years_since_last_au_property_interest": { "type": "integer", "value": "<initial>" },
          "prior_overseas_property_ownership": { "type": "bool", "value": false },
          "prior_fhss_release": { "type": "bool", "value": false, "note": "Mode E is never FHSS-eligible (a repeat buyer) — carried for schema parity with Mode A; always false at this mode's entry." },
          "currently_owns_property": { "type": "bool", "value": "<initial>", "note": "always true for the lead applicant at Mode-E entry (existing_home_ownership.currently_owns_ppor) — carried per-applicant for a co-buyer who may not share the existing home's title." }
        }
      }
    ],
    "_item_note": "Same per-applicant leaf shape as Mode A; at runtime one entry per buyer on the new purchase."
  },
  "off_title_parties": {
    "type": "array<off_title_party>",
    "note": "F4/F14 — identical canonical array to Mode A (architecture §11.9 off_title.* namespace). Mode E populates at most one couple-as-one partner, same as Mode A.",
    "value": [
      {
        "relationship": { "type": "enum", "options": ["spouse", "de_facto", "parent", "sibling", "other_family", "self_funding", "none"], "value": "none" },
        "counts_for_couple_as_one": { "type": "bool", "value": false },
        "ownership_history": {
          "ever_owned_au_property": { "type": "bool", "value": "<initial>" },
          "ever_owned_and_occupied_residence": { "type": "bool", "value": "<initial>" },
          "currently_owns_property": { "type": "bool", "value": "<initial>" }
        },
        "funder": {
          "expected_to_fund": { "type": "bool", "value": false },
          "residence_country": { "type": "enum", "options": ["AU", "VN", "other"], "value": "AU" },
          "contribution_capacity_aud": { "type": "money", "value": 0 }
        }
      }
    ],
    "_item_note": "[] (single buyer) or one couple-as-one entry — identical shape to Mode A."
  },
  "income": {
    "primary_taxable_income": { "type": "money_per_year", "value": "<initial>" },
    "secondary_income": { "type": "money_per_year", "value": 0 },
    "income_stability": { "type": "enum", "options": ["permanent_payg", "contractor", "self_employed", "casual", "mixed"], "value": "<initial>" },
    "foreign_sourced_component": { "type": "money_per_year", "value": 0 },
    "foreign_income_currency": { "type": "string", "value": "<initial>" }
  },
  "savings_and_deposit": {
    "cash_savings": { "type": "money", "value": "<initial>" },
    "genuine_savings_evidence_months": { "type": "integer", "value": "<initial>" },
    "family_gift_or_loan_amount": { "type": "money", "value": 0 },
    "fhss_contributions_to_date": { "type": "money", "value": 0, "note": "always 0 for Mode E — carried for schema parity, never populated (a repeat buyer has no FHSS eligibility)." },
    "funds_provenance": {
      "deposit_source": { "type": "enum", "options": ["genuine_savings", "family_gift", "family_loan", "sale_of_asset", "inheritance", "mixed"], "value": "<initial>", "note": "Mode E's most common value is sale_of_asset (the existing home) — see existing_home_disposal." },
      "cross_border_transfer": { "type": "bool", "value": false },
      "transfer_channel": { "type": "string", "value": "<initial>" }
    }
  },
  "debts": {
    "hecs_balance": { "type": "money", "value": "<initial>" },
    "credit_card_limits_total": { "type": "money", "value": "<initial>" },
    "personal_loans_balance": { "type": "money", "value": 0 },
    "car_loan_balance": { "type": "money", "value": 0 },
    "buy_now_pay_later_balance": { "type": "money", "value": 0 }
  },
  "timeline": {
    "target_purchase_months": { "type": "integer", "value": "<initial>" },
    "already_pre_approved": { "type": "bool", "value": false }
  },
  "purchase_target": {
    "target_price_range": { "type": "money_range", "value": "<initial>" },
    "target_zone": { "type": "array<string>", "value": "<initial>" },
    "hold_horizon_years": { "type": "integer", "value": "<initial>", "note": "the dispose-phase horizon for the NEW home — read by disposition (13), distinct from existing_home_disposal (3)'s now-sale of the CURRENT home." }
  },
  "existing_home_ownership": {
    "currently_owns_ppor": { "type": "bool", "value": true, "note": "Mode E is entered ONLY when true — a repeat owner-occupier who currently owns and lives in a home. Ground for existing_home_disposal (component 3)." },
    "ppor_estimated_value": { "type": "money", "value": "<initial>", "note": "the buyer's own estimate of their current home's value — user-attested, never a KB estimate. Read by existing_home_disposal as the sale-price basis." },
    "ppor_outstanding_loan_balance": { "type": "money", "value": "<initial>", "note": "user-attested; the loan-payout basis for existing_home_disposal." },
    "ppor_loan_rate_type": { "type": "enum", "options": ["fixed", "variable", "unknown"], "value": "<initial>", "note": "gates existing_home_disposal's break-cost to_verify flag (kb.existing-home-sale.net-proceeds)." },
    "ppor_rental_history": { "type": "bool", "value": false, "note": "true if the current home was ever rented out during ownership — gates the CGT main-residence exemption's partial/6-year-rule path (kb.tax.cgt-main-residence-exemption, reused by existing_home_disposal)." }
  }
}
```

**Outcome schema:** `profile` — identical field set to Mode A's ([`fhb-domestic-au.md`](fhb-domestic-au.md) component 1), declared in full (same reason as Parameters above):

```jsonc
{
  "type": "profile",
  "fields": {
    "applicants": "array<{ role, citizenship_status, firb_required, tax_residency, current_residence_country, age, owner_occupier_intent, ever_owned_au_property, ever_owned_and_occupied_residence, years_since_last_au_property_interest, prior_overseas_property_ownership, prior_fhss_release, currently_owns_property }>",
    "applicant_count": "integer",
    "firb_required_any": "bool",
    "off_title_parties": "array<{ relationship, counts_for_couple_as_one, ownership_history, funder }> | null",
    "non_buying_partner": "{ exists: bool, relationship: enum, ever_owned_au_property: bool, ever_owned_and_occupied_residence: bool, currently_owns_property: bool } | null",
    "intended_occupancy_use": "enum [sole_occupier, partial_rental, granny_flat, not_occupied]",
    "assessable_income": "money_per_year",
    "foreign_sourced_income_component": "money_per_year",
    "approx_borrowing_capacity": "money_range",
    "deposit_ready_for_purchase_amount": "money",
    "debts": "{ hecs_balance, credit_card_limits_total, personal_loans_balance, car_loan_balance, buy_now_pay_later_balance } | null",
    "target_price_range": "money_range",
    "target_zone": "array<string>",
    "hold_horizon_years": "integer",
    "key_constraints": "array<localized_text>",
    "key_strengths": "array<localized_text>",
    "existing_home_ownership": "{ currently_owns_ppor: bool, ppor_estimated_value: money|null, ppor_outstanding_loan_balance: money|null, ppor_loan_rate_type: enum [fixed, variable, unknown]|null, ppor_rental_history: bool }"
  }
}
```

---

### 2. property_assessment

**Unchanged from Mode A** — analyses the **new** property being considered, exactly as Mode A does. This component never reads or produces anything about the buyer's *existing* home; that is `existing_home_disposal`'s (3) exclusive concern — no overlap, no double-count. Declared in full below (not by cross-file prose — each blueprint compiles to its own independent registry, P3 activation finding).

**Goal:** Analyse the selected property for fit against the buyer's profile and produce a viability read.

**Inputs:** `property_card` (from user selection on map/URL paste) + `buyer_profile.outcome`

**KB anchors:** `kb.property.suburb-risk-factors`, `kb.property.comparables-methodology`, `kb.strata.health-indicators`, `kb.building-types.risk-by-type`

**Renderer:** `summary-card`

**UI tab hint:** Overview

**Parameters:**

```jsonc
{
  "basics": {
    "address": { "type": "string", "value": "<from_property_card>" },
    "suburb": { "type": "string", "value": "<from_property_card>" },
    "state": { "type": "enum", "value": "<from_property_card>" },
    "lga": { "type": "string", "value": "<from_suburb>", "note": "ABS local government area — neutral geo fact; feeds each scheme's own region tiering (e.g. FHG location_tier)" },
    "is_capital_city": { "type": "bool", "value": "<from_suburb>", "note": "neutral geo fact — property is in the state capital LGA" },
    "price": { "type": "money", "value": "<from_property_card>" },
    "property_type": { "type": "enum", "options": ["established_house", "established_apartment", "new_house", "new_apartment", "off_the_plan", "house_and_land", "vacant_land"], "value": "<from_property_card>" },
    "bedrooms": { "type": "integer", "value": "<from_property_card>" },
    "bathrooms": { "type": "integer", "value": "<from_property_card>" },
    "parking_spaces": { "type": "integer", "value": "<from_property_card>" }
  },
  "location_factors": {
    "flood_risk_band": { "type": "enum", "options": ["none", "low", "medium", "high", "unknown"], "value": "<from_suburb>" },
    "school_catchment_quality": { "type": "enum", "options": ["strong", "average", "weak", "unknown"], "value": "<from_suburb>" },
    "transport_score": { "type": "integer_0_100", "value": "<from_suburb>" },
    "vietnamese_community_proximity": { "type": "enum", "options": ["high", "medium", "low"], "value": "<from_suburb>" },
    "planning_changes_pending": { "type": "array<string>", "value": "<from_suburb>" }
  },
  "market_position": {
    "comparable_sales": { "type": "array<comparable_sale>", "value": [], "agent_reasoning_required": true, "reasoning_domain": "valuation" },
    "estimated_market_value_range": { "type": "money_range", "value": "<initial>", "agent_reasoning_required": true, "reasoning_domain": "valuation" },
    "asking_price_vs_market": { "type": "enum", "options": ["below_market", "fair", "above_market", "significantly_above"], "value": "<initial>", "agent_reasoning_required": true, "reasoning_domain": "valuation" },
    "days_on_market": { "type": "integer", "value": "<from_property_card>" }
  },
  "strata_or_building": {
    "applicable": { "type": "bool", "value": "<initial>", "derived_from": "basics.property_type" },
    "body_corporate_quarterly_fees": { "type": "money", "value": "<from_document>" },
    "sinking_fund_balance": { "type": "money", "value": "<from_document>" },
    "special_levies_in_last_3_years": { "type": "array<string>", "value": "<from_document>" },
    "structural_red_flags": { "type": "array<string>", "value": "<from_document>" }
  },
  "fit_against_buyer": {
    "price_within_borrowing_capacity": { "type": "bool", "value": "<initial>" },
    "lifestyle_match_score": { "type": "integer_0_10", "value": "<initial>", "agent_reasoning_required": true, "reasoning_domain": "lifestyle_fit" }
  }
}
```

**Outcome schema:** `property_fit`

```jsonc
{
  "type": "property_fit",
  "fields": {
    "state": "enum [NSW, VIC, QLD, WA, SA, TAS, ACT, NT]",
    "suburb": "string",
    "lga": "string",
    "is_capital_city": "bool",
    "price": "money",
    "property_type": "enum [established_house, established_apartment, new_house, new_apartment, off_the_plan, house_and_land, vacant_land]",
    "viability_verdict": "enum [proceed, proceed_with_caution, reconsider]",
    "key_strengths": "array<string>",
    "key_concerns": "array<string>",
    "market_price_assessment": "string",
    "scheme_eligibility_hint": "string"
  }
}
```

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
    "total_payout": { "type": "money_range", "value": "<initial>", "note": "outstanding_balance + discharge_fee (a [Lo, Hi] band, since discharge_fee is a band — fh_engine_existing_home_disposal:total_payout/2); null while break_cost_status = to_verify AND the rate is fixed (honest-partial — the break cost is an unknown addend, not zero)" }
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
    "loan_payout": "{ outstanding_balance: money|null, discharge_fee: money_range|null, break_cost_status: enum [not_applicable, to_verify], total_payout: money_range|null }",
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

**Unchanged from Mode A.** Same resolver, same `mortgage_plan` shape. Declared in full below (P3 activation finding — a cross-file "unchanged" pointer contributes nothing to this blueprint's own registry).

**Goal:** Determine optimal loan structure and lender shortlist — *with explicit debt-impact reasoning (HECS, credit cards, BNPL) and the FHG-backed vs LMI-payable path comparison*.

**Inputs:** `buyer_profile.outcome` only (profile, including debts). Mode A's own inputs line additionally names `eligibility.outcome` (scheme_stack) solely to detect FHG eligibility for `recommended_path`; Mode E has no `eligibility` component, so this read is simply absent. **No code or schema change is required**: the resolver's own `fill_fhb/2` already defaults `Stack = maps:get(<<"scheme_stack">>, Upstream, #{})` to `#{}` when the key is absent, and `has_fhg(#{})` correctly returns false — routing every Mode E buyer to the LMI-backed or 20%+-deposit path, never a spuriously-FHG-backed one. This is the correct answer independent of the missing component: a repeat buyer is never FHG-eligible either (First Home Guarantee is first-home-only), so the honest default and the regulatory fact agree.

**KB anchors:** `kb.lender.serviceability-basics`, `kb.lender.fhg-panel-list`, `kb.lender.hecs-treatment-by-lender`, `kb.lender.credit-card-treatment`, `kb.lender.bnpl-treatment-2026`, `kb.lender.hem-living-expenses`, `kb.tax.income-tax-resident-2026-27`, `kb.hecs.thresholds`, `kb.lmi.calculation`, `kb.lmi.providers`, `kb.offset-account.basics`, `kb.refinance.windows-and-triggers`

**Renderer:** `summary-card` + `data-table`

**UI tab hint:** Before you buy (detail) + Overview (summary)

**Scope:** `both` — base estimate against profile + target price range; refined per-property when specific property's loan amount is known

**Parameters:**

```jsonc
{
  "borrowing_capacity": {
    "with_current_debts": { "type": "money_range", "value": "<initial>" },
    "if_hecs_cleared": { "type": "money_range", "value": "<initial>" },
    "if_unused_credit_cards_closed": { "type": "money_range", "value": "<initial>" },
    "if_all_optimisations_applied": { "type": "money_range", "value": "<initial>" },
    "lender_buffer_rate_assumed": { "type": "percentage", "value": "<initial>", "note": "APRA-mandated buffer typically +3% above advertised rate" }
  },
  "debt_optimisation_recommendations": {
    "hecs": {
      "current_balance": { "type": "money", "value": "<from_buyer_profile>" },
      "clear_before_application_recommended": { "type": "bool", "value": "<initial>" },
      "estimated_capacity_uplift_if_cleared": { "type": "money", "value": "<initial>" },
      "trade_off_cash_drain": { "type": "money", "value": "<initial>" },
      "reasoning": { "type": "string", "value": "<initial>" }
    },
    "credit_cards": {
      "close_unused_cards_recommended": { "type": "bool", "value": "<initial>" },
      "limits_to_reduce": { "type": "array<string>", "value": [] },
      "estimated_capacity_uplift": { "type": "money", "value": "<initial>" }
    },
    "bnpl": {
      "close_before_application_recommended": { "type": "bool", "value": "<initial>" },
      "accounts_affected": { "type": "array<string>", "value": [] }
    },
    "personal_or_car_loans": {
      "consolidate_or_clear_recommended": { "type": "bool", "value": "<initial>" },
      "reasoning": { "type": "string", "value": "<initial>" }
    }
  },
  "loan_path_comparison": {
    "fhg_backed_path": {
      "applicable": { "type": "bool", "value": false, "note": "always false for Mode E — no eligibility/scheme_stack component; First Home Guarantee is first-home-only, so the honest default and the regulatory fact agree." },
      "deposit_percentage_required": { "type": "percentage", "value": 5 },
      "lmi_payable": { "type": "money", "value": 0 },
      "fhg_slot_reservation_required": { "type": "bool", "value": true },
      "panel_lender_shortlist": { "type": "array<{ lender, rate_range, processing_time }>", "value": [] }
    },
    "lmi_backed_path_5_to_20_deposit": {
      "deposit_percentage_required": { "type": "percentage", "value": "<initial>" },
      "lmi_payable_estimate": { "type": "money", "value": "<initial>" },
      "lmi_capitalised_into_loan": { "type": "bool", "value": true },
      "shortlist_if_fhg_not_available": { "type": "array<{ lender, rate_range, processing_time }>", "value": [] }
    },
    "twenty_plus_deposit_path": {
      "lmi_payable": { "type": "money", "value": 0 },
      "broader_lender_shortlist": { "type": "array<{ lender, rate_range, processing_time }>", "value": [] }
    },
    "recommended_path": { "type": "enum", "options": ["fhg_backed", "lmi_5_to_20", "twenty_plus", "user_specific_alternative"], "value": "<initial>", "note": "never fhg_backed for Mode E — has_fhg(#{}) on an absent scheme_stack correctly returns false" },
    "recommended_path_reasoning": { "type": "string", "value": "<initial>" }
  },
  "loan_structure": {
    "principal_and_interest_vs_interest_only": { "type": "enum", "options": ["principal_and_interest", "interest_only", "split"], "value": "principal_and_interest" },
    "fixed_vs_variable": { "type": "enum", "options": ["variable", "fixed_1yr", "fixed_2yr", "fixed_3yr", "split_fixed_variable"], "value": "<initial>", "agent_reasoning_required": true, "reasoning_domain": "lender_fit" },
    "offset_account_included": { "type": "bool", "value": "<initial>" },
    "offset_strategy": { "type": "string", "value": "<initial>" }
  },
  "lender_synthesis": {
    "most_likely_approval_lenders": { "type": "array<{ lender, approval_likelihood, reasoning }>", "value": [], "agent_reasoning_required": true, "reasoning_domain": "lender_fit" },
    "lenders_with_lenient_hecs": { "type": "array<string>", "value": [] },
    "lenders_with_lenient_genuine_savings": { "type": "array<string>", "value": [] },
    "broker_vs_direct_recommendation": { "type": "enum", "options": ["broker", "direct", "either"], "value": "broker" }
  },
  "pre_approval_workflow": {
    "documents_required": { "type": "array<{ document, status }>", "value": [] },
    "expected_processing_time_days": { "type": "integer", "value": "<initial>" },
    "pre_approval_validity_days": { "type": "integer", "value": 90 },
    "pre_approval_granted_date": { "type": "date", "value": "<initial>" },
    "pre_approval_expiry_date": { "type": "date", "value": "<initial>", "derived_from": "pre_approval_granted_date + pre_approval_validity_days" },
    "reapplication_required": { "type": "bool", "value": false }
  },
  "refinance_planning": {
    "fixed_rate_roll_off_date": { "type": "date", "value": "<initial>" },
    "lvr_graduation_estimate_year": { "type": "number", "value": "<initial>", "note": "When LVR < 80% — free refinance window opens (no FHG to end, but the graduation event still applies)" },
    "refinance_review_cadence_months": { "type": "integer", "value": 24 }
  }
}
```

**Outcome schema:** `mortgage_plan`

```jsonc
{
  "type": "mortgage_plan",
  "fields": {
    "recommended_path": "enum",
    "expected_borrowing_capacity": "money_range",
    "debt_optimisations_to_action": "array<{ action, expected_uplift, urgency }>",
    "recommended_lender_shortlist": "array<{ lender, reasoning: localized_text, approval_likelihood }>",
    "loan_structure_recommendation": "object",
    "pre_approval_action_plan": "array<localized_text>",
    "pre_approval_expiry": "date",
    "reapplication_required": "bool",
    "key_assumptions": "array<localized_text>"
  }
}
```

The `mortgage_plan` outcome feeds `cash_position` (loan amount + buffer requirements), `buying_strategy` (financing condition in offers), `settlement_prep` (lender milestones), and `ownership_planning` (refinance windows + LVR graduation tracking).

---

### 5. cash_position

**Goal:** Compute the buyer's full cash needs at settlement — **and now also a genuine HAVE-side source**, the net proceeds of selling their current home — identify any gap, and produce a budget envelope and verdict.

**Inputs:** `buyer_profile.outcome` + `property_assessment.outcome` + `mortgage_finance.outcome` + **`existing_home_disposal.outcome`** (new).

**KB anchors:** `kb.stamp-duty.calc-by-state`, `kb.buyer-costs.inspections-conveyancing-fees`, `kb.cash-reserve.lender-expectations`, `kb.lmi.calculation` — identical to Mode A's; no `eligibility`-linked anchor since no `scheme_stack` exists to gate a state concession (a repeat buyer pays full stamp duty — every state's first-home concession requires first-home status, so the absence of a concession is the regulatory fact, not a gap).

**Renderer:** `calculator`

**UI tab hint:** Budget (interactive financial spine) + Overview (summary)

**Parameters:** the NEED side (`deposit`, `stamp_duty`, `other_buying_costs`, `reserve_buffer`) is byte-identical logic to Mode A's, naturally evaluated at the **full** (no-concession) duty rate since no `scheme_stack` exists. The HAVE side (`inputs`/`totals`) is extended for Mode E's new cash source. Declared in full below (P3 activation finding).

```jsonc
{
  "inputs": {
    "property_price": { "type": "money", "value": "<from_property_assessment>" },
    "cash_on_hand": { "type": "money", "value": "<from_buyer_profile>" },
    "fhss_release_planned": { "type": "money", "value": 0, "note": "always 0 for Mode E — no eligibility/FHSS component; a repeat buyer has no FHSS eligibility" },
    "family_contribution": { "type": "money", "value": "<from_buyer_profile>" },
    "existing_home_net_sale_proceeds": { "type": "money", "value": "<from_existing_home_disposal>", "note": "MODE-E ADDITION — existing_home_disposal.net_sale_proceeds when computed; null at base (user-attested facts not captured at onboarding)." }
  },
  "deposit": {
    "minimum_required_percentage": { "type": "percentage", "value": 5 },
    "minimum_required_amount": { "type": "money", "value": "<initial>" },
    "recommended_amount": { "type": "money", "value": "<initial>" }
  },
  "stamp_duty": {
    "before_concession": { "type": "money", "value": "<initial>" },
    "concession_applied": { "type": "money", "value": 0, "note": "always 0 for Mode E — every state's first-home concession requires first-home status; a repeat buyer pays full duty (the regulatory fact, not a gap)" },
    "after_concession": { "type": "money", "value": "<initial>" }
  },
  "other_buying_costs": {
    "building_pest_inspection": { "type": "money", "value": "<initial>" },
    "conveyancing": { "type": "money", "value": "<initial>" },
    "lender_application_fee": { "type": "money", "value": "<initial>" },
    "mortgage_registration_fee": { "type": "money", "value": "<initial>" },
    "title_transfer_fee": { "type": "money", "value": "<initial>" },
    "first_year_building_insurance": { "type": "money", "value": "<initial>" },
    "utility_connections": { "type": "money", "value": "<initial>" },
    "moving_costs": { "type": "money", "value": "<initial>" }
  },
  "reserve_buffer": {
    "months_of_repayments_recommended": { "type": "integer", "value": 3 },
    "amount": { "type": "money", "value": "<initial>" }
  },
  "totals": {
    "total_cash_required_at_settlement": { "type": "money", "value": "<initial>" },
    "cash_available": { "type": "money_range", "value": "<initial>", "note": "MODE-E TYPE DIVERGENCE from Mode A (which declares this field scalar money): the HAVE side folds in existing_home_disposal.net_sale_proceeds, which is itself a money_range (banded off a user-attested sale-price estimate) — a genuine per-blueprint schema difference, not a copy error (fh_engine_cash:fill_fhb_nexthome/2 assigns the range straight through, one-computer-per-figure). Still null at BASE (existing_home_disposal's own inputs are user-attested facts not captured at onboarding), so this is a refine-turn improvement, not a base-turn one." },
    "cash_gap_or_surplus": { "type": "money_range", "value": "<initial>", "note": "MODE-E TYPE DIVERGENCE from Mode A — a range once cash_available (a range) offsets against total_cash_required (a range); fh_engine_cash:gap_range/2." },
    "verdict": { "type": "enum", "options": ["surplus", "tight", "short"], "value": "<initial>" }
  }
}
```

**Outcome schema:** `budget_envelope`

```jsonc
{
  "type": "budget_envelope",
  "fields": {
    "stamp_duty": "{ before_concession: money|null, concession_applied: money|null, after_concession: money|null, notes: array<localized_text> }",
    "deposit": "{ minimum_required_percentage: percentage|null, minimum_required_amount: money_range|null, notes: array<localized_text> }",
    "other_buying_costs": "{ total: money_range|null, registration_exact: money|null, notes: array<localized_text> }",
    "reserve_buffer": "{ months_of_repayments_recommended: integer, amount: money|null, notes: array<localized_text> }",
    "max_property_price_supported": "money",
    "actual_property_price": "money",
    "total_cash_required": "money_range",
    "cash_available": "money_range",           // MODE-E TYPE DIVERGENCE from Mode A (scalar money there) — folds in existing_home_disposal.net_sale_proceeds, itself a money_range; see Parameters note above
    "gap_or_surplus": "money_range",            // MODE-E TYPE DIVERGENCE from Mode A — a range once cash_available (a range) offsets total_cash_required (a range); fh_engine_cash:gap_range/2
    "verdict": "enum [surplus, tight, short]",
    "genuine_savings_verdict": "enum [meets, fails_recent_gift, insufficient_track_record, unknown]",
    "cash_events": "array<{ id: string, phase: string, label: localized_text, direction: enum [out, in], amount: money_range|null, is_estimate: bool, timing: enum [one_off, recurring], period: enum [once, monthly, quarterly, annual]|null, counterparty: string, source_component: string }>",
    "mitigation_options_if_short": "array<string>",
    "key_assumptions": "array<localized_text>"
  }
}
```

`gap_or_surplus` and `verdict` follow unchanged once any HAVE-side figure populates.

**Mode discriminator (engine note, not blueprint text — recorded here since it grounds the resolver P2 work):** `fh_engine_cash:fill/2` currently branches on `tax_optimised_structure` presence (investor) then `firb_required_any` (foreign) — neither distinguishes Mode A from Mode E, since both are domestic + owner-occupier. The Mode-E branch is selected by **`existing_home_disposal` outcome presence in Upstream** (mirroring how `tax_optimised_structure` presence marks the investor path) — only Mode E's DAG runs that component, so its presence is a clean, existing-pattern discriminator. This wiring (the DAG order + the Upstream key) is fixed by `IN_SCOPE_BLUEPRINTS` activation (P3) and `base_components/1` (P5), not by this document.

---

### 6. buying_strategy

**Unchanged from Mode A.** Declared in full below (P3 activation finding).

**Goal:** Produce a bid plan, negotiation strategy, and agent-tactics awareness for the active buying phase (offer or auction).

**Inputs:** `property_assessment.outcome` + `cash_position.outcome` (specifically `budget_envelope`)

**KB anchors:** `kb.auction.rules-by-state`, `kb.cooling-off.by-state`, `kb.negotiation.patterns-by-market-condition`, `kb.agent-tactics.detection`, `kb.comparables.reading-the-room`

**Renderer:** `buying-strategy-card`

**UI tab hint:** Buying

**Parameters:**

```jsonc
{
  "transaction_mode": {
    "type": { "type": "enum", "options": ["auction", "private_treaty_offer", "expression_of_interest", "tender", "off_the_plan_contract"], "value": "<initial>" },
    "scheduled_date": { "type": "date", "value": "<initial>" },
    "cooling_off_applies": { "type": "bool", "value": "<initial>", "derived_from": "transaction_mode.type" },
    "cooling_off_days": { "type": "integer", "value": "<initial>" }
  },
  "comparables": {
    "comparable_sales_set": { "type": "array<comparable_sale>", "value": [] },
    "median_comparable_sale_price": { "type": "money", "value": "<initial>" },
    "highest_comparable_relevance": { "type": "money", "value": "<initial>" },
    "lowest_comparable_relevance": { "type": "money", "value": "<initial>" }
  },
  "price_envelope": {
    "max_bid": {
      "value": { "type": "money", "value": "<initial>" },
      "confidence": { "type": "percentage_0_100", "value": "<initial>" },
      "reasoning": { "type": "string", "value": "<initial>" }
    },
    "walk_away_price": { "type": "money", "value": "<initial>" },
    "opening_bid_recommended": { "type": "money", "value": "<initial>" },
    "reserve_estimate_range": { "type": "money_range", "value": "<initial>", "agent_reasoning_required": true, "reasoning_domain": "negotiation" }
  },
  "bid_tactics": {
    "increment_size_recommended": { "type": "money", "value": "<initial>" },
    "drop_out_signal": { "type": "string", "value": "<initial>" },
    "early_offer_vs_wait": { "type": "enum", "options": ["make_early_offer", "wait_for_auction", "wait_for_post_auction_negotiation"], "value": "<initial>", "agent_reasoning_required": true, "reasoning_domain": "negotiation" }
  },
  "negotiation_style": {
    "recommended_style": { "type": "enum", "options": ["assertive", "patient", "early_offer", "low_anchor"], "value": "<initial>", "agent_reasoning_required": true, "reasoning_domain": "negotiation" },
    "rationale": { "type": "string", "value": "<initial>" }
  },
  "agent_tactics_watchlist": {
    "common_tactics_to_watch": { "type": "array<{ tactic, counter }>", "value": [] },
    "agent_pressure_signals": { "type": "array<string>", "value": [] }
  },
  "live_coach": {
    "armed": { "type": "bool", "value": false },
    "mobile_endpoint_ready": { "type": "bool", "value": false }
  },
  "conditions_to_include_in_offer": {
    "subject_to_finance": { "type": "bool", "value": true },
    "subject_to_building_pest": { "type": "bool", "value": true },
    "subject_to_satisfactory_strata_report": { "type": "bool", "value": "<initial>" },
    "other_special_conditions": { "type": "array<string>", "value": [] }
  }
}
```

**Outcome schema:** `bid_plan`

```jsonc
{
  "type": "bid_plan",
  "fields": {
    "max_bid_value": "money",
    "max_bid_confidence": "percentage_0_100",
    "max_bid_reasoning": "string",
    "walk_away_price": "money",
    "negotiation_style": "enum",
    "live_coach_armed": "bool",
    "conditions_to_request": "array<string>",
    "red_flags_to_monitor": "array<string>"
  }
}
```

---

### 7. due_diligence

**Unchanged from Mode A.** Declared in full below (P3 activation finding).

**Goal:** Surface document risks and required actions; produce a go/no-go recommendation against the contract / Section 32 / building+pest / strata report.

**Inputs:** `property_assessment.outcome` + uploaded documents (Section 32, Contract of Sale, building/pest report, strata report)

**KB anchors:** `kb.contract-of-sale.review-points-by-state`, `kb.s32.review-points`, `kb.building-pest.interpretation`, `kb.strata-report.red-flags`, `kb.special-conditions.standard-set`

**Renderer:** `risk-flag-list` + `checklist`

**UI tab hint:** Before you buy

**Parameters:**

```jsonc
{
  "documents_required": {
    "contract_of_sale": { "required": true, "received": "<initial>", "reviewed": "<initial>" },
    "section_32_vendor_statement": { "required": "<initial>", "received": "<initial>", "reviewed": "<initial>" },
    "building_inspection_report": { "required": true, "received": "<initial>", "reviewed": "<initial>" },
    "pest_inspection_report": { "required": true, "received": "<initial>", "reviewed": "<initial>" },
    "strata_report": { "required": "<initial>", "received": "<initial>", "reviewed": "<initial>" },
    "title_search": { "required": true, "received": "<initial>", "reviewed": "<initial>" }
  },
  "flags_by_document": {
    "contract_of_sale_flags": { "type": "array<{ severity, item, action }>", "value": [], "agent_reasoning_required": true, "reasoning_domain": "document_significance" },
    "s32_flags": { "type": "array<{ severity, item, action }>", "value": [], "agent_reasoning_required": true, "reasoning_domain": "document_significance" },
    "building_flags": { "type": "array<{ severity, item, action, estimated_repair_cost }>", "value": [], "agent_reasoning_required": true, "reasoning_domain": "document_significance" },
    "pest_flags": { "type": "array<{ severity, item, action }>", "value": [], "agent_reasoning_required": true, "reasoning_domain": "document_significance" },
    "strata_flags": { "type": "array<{ severity, item, action }>", "value": [], "agent_reasoning_required": true, "reasoning_domain": "document_significance" },
    "title_flags": { "type": "array<{ severity, item, action }>", "value": [], "agent_reasoning_required": true, "reasoning_domain": "document_significance" }
  },
  "special_conditions_to_request": { "type": "array<string>", "value": [] },
  "questions_to_ask_vendor_or_agent": { "type": "array<string>", "value": [] },
  "estimated_additional_costs_from_findings": { "type": "money_range", "value": "<initial>" },
  "go_no_go_recommendation": {
    "verdict": { "type": "enum", "options": ["proceed", "proceed_with_conditions", "renegotiate", "withdraw"], "value": "<initial>", "agent_reasoning_required": true, "reasoning_domain": "document_significance" },
    "rationale": { "type": "string", "value": "<initial>" }
  }
}
```

**Outcome schema:** `risk_assessment`

```jsonc
{
  "type": "risk_assessment",
  "fields": {
    "overall_verdict": "enum",
    "high_severity_flags": "array<{ source_doc, item, action }>",
    "actions_before_signing": "array<string>",
    "questions_for_vendor": "array<string>",
    "estimated_negotiation_lever": "money_range"
  }
}
```

---

### 8. settlement_prep

**Unchanged from Mode A.** Declared in full below (P3 activation finding). The schema keeps `scheme_application_milestones` (deleting fields from a shared resolver's declared shape is fictional — the resolver still emits the same map shape regardless of which blueprint runs it; `null`/empty values pass `fh_engine_outcome:validate` universally). For Mode E this block is always empty (`<initial>` never resolves — no scheme applications exist for a repeat buyer), same honest-absence posture as every other pending field.

**Goal:** Coordinate the 4–8 week settlement timeline — milestones, counterparty contacts, document deadlines.

**Inputs:** `property_assessment.outcome` + `bid_plan` (only if buying proceeded). Mode A's own inputs line additionally names `eligibility.outcome`, read solely for `scheme_application_milestones`; Mode E has no `eligibility` component, so this read is simply absent (the block itself stays in the schema, always empty).

**KB anchors:** `kb.settlement.process-by-state`, `kb.cooling-off.by-state`, `kb.pexa.settlement`, `kb.insurance.timing-of-risk-pass`, `kb.lender-docs.standard-timeline`

**Renderer:** `swimlane-diagram` + `checklist`

**UI tab hint:** Journey (follows `purchase_journey`, per-property) + Before you buy

**Parameters:**

```jsonc
{
  "key_dates": {
    "contract_signed_date": { "type": "date", "value": "<from_document>" },
    "cooling_off_end_date": { "type": "date", "value": "<initial>", "derived_from": "key_dates.contract_signed_date" },
    "deposit_due_date": { "type": "date", "value": "<initial>", "derived_from": "key_dates.contract_signed_date" },
    "finance_approval_deadline": { "type": "date", "value": "<initial>", "derived_from": "key_dates.contract_signed_date" },
    "settlement_date": { "type": "date", "value": "<from_document>" },
    "building_insurance_effective_date": { "type": "date", "value": "<initial>", "derived_from": "property_fit.state + key_dates.contract_signed_date + key_dates.settlement_date" }
  },
  "milestones": {
    "contract_signed": { "type": "milestone", "value": { "status": "<initial>", "due_date": "<initial>" } },
    "deposit_paid_to_trust": { "type": "milestone", "value": { "status": "<initial>", "due_date": "<initial>" } },
    "building_pest_satisfactory": { "type": "milestone", "value": { "status": "<initial>", "due_date": "<initial>" } },
    "finance_approval_unconditional": { "type": "milestone", "value": { "status": "<initial>", "due_date": "<initial>" } },
    "loan_documents_signed": { "type": "milestone", "value": { "status": "<initial>", "due_date": "<initial>" } },
    "insurance_bound": { "type": "milestone", "value": { "status": "<initial>", "due_date": "<initial>" } },
    "settlement_funds_released": { "type": "milestone", "value": { "status": "<initial>", "due_date": "<initial>" } },
    "title_registered": { "type": "milestone", "value": { "status": "<initial>", "due_date": "<initial>" } },
    "keys_received": { "type": "milestone", "value": { "status": "<initial>", "due_date": "<initial>" } }
  },
  "counterparties": {
    "lender": { "type": "string", "value": "<initial>" },
    "broker": { "type": "string", "value": "<initial>" },
    "conveyancer_solicitor": { "type": "string", "value": "<initial>" },
    "real_estate_agent": { "type": "string", "value": "<initial>" },
    "building_inspector": { "type": "string", "value": "<initial>" },
    "pest_inspector": { "type": "string", "value": "<initial>" },
    "insurer": { "type": "string", "value": "<initial>" }
  },
  "scheme_application_milestones": {
    "fhss_release_request_submitted": { "type": "milestone", "value": { "status": "<initial>" }, "note": "always <initial>/unpopulated for Mode E — no eligibility component" },
    "fhg_slot_reserved": { "type": "milestone", "value": { "status": "<initial>" }, "note": "always <initial>/unpopulated for Mode E" },
    "state_concession_application_lodged": { "type": "milestone", "value": { "status": "<initial>" }, "note": "always <initial>/unpopulated for Mode E" }
  }
}
```

**Outcome schema:** `settlement_checklist`

```jsonc
{
  "type": "settlement_checklist",
  "fields": {
    "settlement_date": "date",
    "critical_path_milestones": "array<{ name, due_date, status, dependency }>",
    "at_risk_milestones": "array<{ name, reason }>",
    "next_action_for_user": "string"
  }
}
```

---

### 9. ownership_planning

**Unchanged from Mode A** for the NEW home's own ongoing obligations. Declared in full below (P3 activation finding). The schema keeps `scheme_specific_alerts` (a shared resolver's shape is not deleted per-blueprint); for Mode E, `fhg_loan_active` never resolves true — a repeat buyer cannot hold an FHG-backed loan, so this stays honestly false/unpopulated.

**Goal:** Project ongoing costs and obligations after settlement, and set alert triggers for refinance windows, graduation events, and rate moves.

**Inputs:** `property_assessment.outcome` + `cash_position.outcome` + `mortgage_finance.outcome`. Mode A's own inputs line additionally names `eligibility.outcome` (scheme_stack); Mode E has no `eligibility` component, so this read is simply absent.

**KB anchors:** `kb.ongoing-costs.rates-water-strata`, `kb.refinance.windows-and-triggers`, `kb.graduation.lvr80`, `kb.land-tax.ppor-exemption`, `kb.maintenance.budget-by-property-type`

**Renderer:** `data-table` + `opportunity-card`

**UI tab hint:** After you buy

**Scope note — dual-ownership land tax deferred, not built.** While the buyer holds **both** the old and new home during the transition, the old home's land-tax exemption follows [`kb.land-tax.dual-ownership-transition`](../kb/land-tax/dual-ownership-transition.md) (authored in P1), not the single-PPOR `kb.land-tax.ppor-exemption` this component already reads for the **new** home. Wiring the transition-period check into `ownership_planning` (or a sibling resolver) is **not done in P2/P3** — it requires a fact this blueprint does not yet model (that the OLD home is still held, distinct from `existing_home_disposal`'s sale-in-progress tracking). Flagged here as an explicit, honest gap for a future phase — not silently absorbed into this component's existing `land_tax_check` field, which continues to describe only the NEW home.

**Parameters:**

```jsonc
{
  "monthly_obligations": {
    "mortgage_principal_and_interest": { "type": "money_per_month", "value": "<initial>" },
    "utility_estimate_combined": { "type": "money_per_month", "value": "<initial>" }
  },
  "quarterly_obligations": {
    "council_rates": { "type": "money_per_quarter", "value": "<initial>" },
    "water_access_and_usage": { "type": "money_per_quarter", "value": "<initial>" },
    "strata_levies": { "type": "money_per_quarter", "value": "<initial>", "applicable": "<initial>" }
  },
  "annual_obligations": {
    "building_insurance_premium": { "type": "money_per_year", "value": "<initial>" },
    "contents_insurance_optional": { "type": "money_per_year", "value": "<initial>" },
    "land_tax_check": { "type": "enum", "options": ["exempt_ppor", "applicable", "to_verify"], "value": "exempt_ppor", "note": "F12 — describes the NEW home only. resolves from application.intended_occupancy_use: sole_occupier → exempt_ppor; partial_rental / granny_flat → to_verify; not_occupied → applicable." }
  },
  "maintenance_reserve": {
    "annual_target": { "type": "money_per_year", "value": "<initial>" },
    "percentage_of_property_value": { "type": "percentage", "value": 1 }
  },
  "lifecycle_alerts": {
    "graduation_event_lvr_target": { "type": "percentage", "value": 80 },
    "estimated_graduation_years": { "type": "number", "value": "<initial>" },
    "refi_review_cadence_months": { "type": "integer", "value": 24 },
    "first_refi_window_target": { "type": "date", "value": "<initial>" }
  },
  "scheme_specific_alerts": {
    "fhg_loan_active": { "type": "bool", "value": false, "note": "always false for Mode E — no eligibility component, and a repeat buyer cannot hold an FHG-backed loan" },
    "fhg_ends_at_lvr_80_or_payoff": { "type": "string", "value": "Notify user when LVR drops below 80% for free refi window" }
  }
}
```

**Outcome schema:** `ongoing_obligations`

```jsonc
{
  "type": "ongoing_obligations",
  "fields": {
    "total_monthly_outgoings_estimate": "money|null",
    "total_annual_outgoings_estimate": "money|null",
    "maintenance_reserve_target": "money_per_year",
    "recurring_costs_estimate": "{ statutory_band: { low: money|null, high: money|null, period, components: array<string> }, strata_levies: money|null, utilities: money|null, building_insurance: money|null, notes: array<localized_text> }",
    "land_tax_check": "enum [exempt_ppor, applicable, to_verify]",
    "graduation_milestone": "{ target_lvr, estimated_year: number|null }",
    "alert_triggers_armed": "array<{ trigger: localized_text, action: localized_text }>"
  }
}
```

---

### 10. purchase_journey

**Unchanged from Mode A.** It does not need a direct read of `existing_home_disposal` — that component's cash effect (`net_sale_proceeds`) already surfaces through `cash_position.budget_envelope.cash_available`/`cash_events`, which this component already reads and places. Declared in full below (P3 activation finding).

**Goal:** Present the whole-of-journey lifecycle as a swimlane — the phases of a purchase across time (Prepare → Pre-approve → Contract → Settle → Own → **Dispose**) against the actors who act in each (You / Government / Lender / Other), with the buyer's already-computed money flows placed on the timeline. The terminal `dispose` phase places `disposition`'s (13) sale/cost/net figures, present only when a hold horizon `H` is set.

**Scope:** `base` — the journey structure is generic to a purchase; it does not depend on a specific property.

**Inputs:** `mortgage_finance.outcome` (mortgage_plan) + `cash_position.outcome` (budget_envelope, incl. its `cash_events`) + `ownership_planning.outcome` (ongoing_obligations — for the Own-phase recurring costs) + `disposition.outcome` (the Dispose-phase sale/cost/net `cash_events`). Mode A's own inputs line additionally names `eligibility.outcome` (scheme_stack); Mode E has no `eligibility` component, so this read is simply absent. It computes **no figure of its own** (one-computer-per-figure) — it PLACES each upstream figure on the swimlane at its (phase, actor/counterparty) cell.

**KB anchors:** `kb.journey.fhg-path`

**Renderer:** `swimlane-diagram`

**UI tab hint:** Journey (leads the tab; `settlement_prep` follows per-property)

**Fill path:** resolver. The journey structure + bilingual cell prose are generic KB content (`kb.journey.fhg-path`); the figures are upstream outcomes placed on the timeline. No agent leaf.

**Outcome schema:** `journey_swimlane`

```jsonc
{
  "type": "journey_swimlane",
  "fields": {
    "phases": "array<{ id: string, label: localized_text }>",
    "actors": "array<{ id: string, label: localized_text }>",
    "cells": "array<{ phase: string, actor: string, item: localized_text, flow_marker: enum [none, money_out, money_in, document, milestone], amount: money_range, counterparty: string|null, source_component: string }>",
    "interactions": "array<{ from_actor: string, to_actor: string, phase: string, flows: array<{ label: localized_text, direction: enum [out, in], amount: money_range }> }>",
    "key_assumptions": "array<localized_text>"
  }
}
```

---

### 11. preparation

**Unchanged from Mode A**, less any scheme-application readiness items (no `eligibility` component to place from — `scheme_applications_to_prepare` is always empty for Mode E, honestly, not silently: the field stays in the schema, populated `[]`). Declared in full below (P3 activation finding).

**Goal:** Surface the property-agnostic readiness layer the buyer can act on before any specific property exists — the documents to gather, the people to line up, the scheme applications to prepare (always none, for Mode E), and the cash buffer to hold.

**Scope:** `base` — generic to Mode E.

**Inputs:** `cash_position.outcome` (budget_envelope — the buffer / genuine-savings figures surfaced as readiness; PLACED, never recomputed). Mode A's own inputs line additionally names `eligibility.outcome` (scheme_stack); Mode E has no `eligibility` component, so `scheme_applications_to_prepare` is always `[]`.

**KB anchors:** `kb.preparation.fhb-readiness`

**Renderer:** `checklist` + `data-table`

**UI tab hint:** Before you buy (leads the tab)

**Fill path:** resolver. The checklist items + people-to-engage roles are generic bilingual KB content (`kb.preparation.fhb-readiness`); the money-buffer figures are upstream outcomes placed on the readiness table. No agent leaf.

**Outcome schema:** `preparation_plan`

```jsonc
{
  "type": "preparation_plan",
  "fields": {
    "document_checklist": "array<{ id, item: localized_text, why: localized_text, status: enum [not_started, gathered] }>",
    "people_to_engage": "array<{ role: localized_text, when: localized_text, why: localized_text }>",
    "scheme_applications_to_prepare": "array<{ scheme, action: localized_text }>",
    "money_buffer": "{ genuine_savings_verdict: enum [meets, fails_recent_gift, insufficient_track_record, unknown], reserve_buffer: money|null, notes: array<localized_text> }",
    "key_assumptions": "array<localized_text>"
  }
}
```

---

### 12. phase_playbook

**Unchanged from Mode A.** Declared in full below (P3 activation finding).

**Goal:** Behind each Flow-view phase sheet, present the actionable, temporally-ordered checklist for that phase and the often-seen risks + mitigations for that phase.

**Scope:** `base` — generic to Mode E's lifecycle; phase-keyed, property-agnostic.

**Inputs:** `cash_position.outcome` (budget_envelope — so each action's `budget_ref` resolves to a real `cash_event.id`) + `purchase_journey.outcome` (journey_swimlane — to share the phase set). Computes no figure and places no amount — links to figures by id.

**KB anchors:** `kb.journey.phase-actions`, `kb.risks.fhb-by-phase`

**Renderer:** `checklist` + `risk-flag-list`

**UI tab hint:** Flow (the per-phase drill-down sheet)

**Fill path:** resolver. Actions, ordering, risks, and mitigations are bilingual KB content keyed by phase; the only upstream read is `cash_event.id` resolution for `budget_ref`. No agent leaf.

**Outcome schema:** `phase_playbook`

```jsonc
{
  "type": "phase_playbook",
  "fields": {
    "phases": "array<{ phase: string, actions: array<{ id: string, label: localized_text, detail: localized_text, order: integer, budget_ref: string|null, component_ref: string|null, status: enum [not_started, done] }>, risks: array<{ severity: enum [low, medium, high], item: localized_text, action: localized_text }> }>",
    "key_assumptions": "array<localized_text>"
  }
}
```

---

### 13. disposition

**Reused unchanged — zero code change.** Projects the financial outcome of disposing of the **new** property (the one this plan is for) after a hold horizon `H` — the same **future**-exit projection Mode A runs, on the exact same owner-occupier CGT path (`fh_engine_disposition:fill_owner_occupier/2`, dispatched because no `tax_optimised_structure` outcome exists upstream — identical to Mode A's own dispatch condition).

**Why this is a genuine, verified reuse, not an assumption.** `fill_owner_occupier/2` reads `budget_envelope` (from `cash_position`) and `mortgage_plan` (from `mortgage_finance`) — both outcome **types**, not mode-specific shapes. Mode E's `cash_position` (component 5) still produces a `budget_envelope`-typed outcome (extended, not retyped) and Mode E's `mortgage_finance` (component 4) still produces `mortgage_plan` unchanged — so `disposition`'s existing dispatch and computation apply without modification. This is the distinct **future**-exit counterpart to `existing_home_disposal` (3)'s **current**-sale computation; the two never read each other and never double-count a figure. Declared in full below (P3 activation finding).

**Goal:** Project the financial outcome of disposing of the property after a hold horizon `H` — the sale proceeds (growth-projected), the costs of selling, the loan payout, the CGT, and the net proceeds — and roll them up with the acquisition and ownership figures into a full-horizon net position (buy → hold → sell). For a repeat owner-occupier the dispose value is the equity realised at sale; CGT is the main-residence exemption (`cgt: null`) on the clean path — same as Mode A.

**Scope:** `base` — the projection runs at onboarding against `target_price_range` + the hold horizon `H`; it narrows per-property when a specific property's price attaches. Present only when `H` is set.

**Inputs:** `buyer_profile.outcome` (`hold_horizon_years` H, `target_price_range`, `intended_occupancy_use`, `tax_residency`) + `property_assessment.outcome` (`price`, per-property) + `mortgage_finance.outcome` (`expected_borrowing_capacity`) + `cash_position.outcome` (`budget_envelope.total_cash_required`) + `ownership_planning.outcome` (`ongoing_obligations`).

**KB anchors:** `kb.property.capital-growth-bands`, `kb.selling-costs.agent-legal`, `kb.tax.cgt-main-residence-exemption`, `kb.lender.serviceability-basics`

**Renderer:** `calculator`

**UI tab hint:** Budget (the full-horizon net position + horizon slider) + Flow → Dispose phase sheet

**Fill path:** resolver. Sale proceeds, selling costs, loan payout, CGT, net proceeds, and the full-horizon roll-up are all deterministic from KB + upstream figures. No agent leaf.

**Parameters:**

```jsonc
{
  "horizon": {
    "hold_horizon_years": { "type": "integer", "value": "<from_buyer_profile>", "note": "H; null = no disposal projection." },
    "growth_band_used": { "type": "string", "value": "<initial>", "note": "the ABS-sourced band from kb.property.capital-growth-bands" }
  },
  "proceeds": {
    "purchase_price_basis": { "type": "money", "value": "<initial>" },
    "projected_sale_proceeds": { "type": "money_range", "value": "<initial>" }
  },
  "costs": {
    "agent_commission": { "type": "money_range", "value": "<initial>" },
    "legal_conveyancing": { "type": "money_range", "value": "<initial>" },
    "marketing": { "type": "money_range", "value": "<initial>" },
    "total_selling_costs": { "type": "money_range", "value": "<initial>" }
  },
  "loan_payout": {
    "estimated_balance_at_horizon": { "type": "money", "value": "<initial>" }
  },
  "cgt": {
    "main_residence_exempt": { "type": "bool", "value": "<initial>", "derived_from": "buyer_profile.intended_occupancy_use + buyer_profile.tax_residency" },
    "cgt_estimate": { "type": "money", "value": "<initial>", "note": "stays null on the exempt path — never an estimated taxable gain" }
  },
  "net": {
    "net_proceeds_at_sale": { "type": "money_range", "value": "<initial>" },
    "full_horizon_net_position": { "type": "money_range", "value": "<initial>" }
  }
}
```

**Outcome schema:** `disposition`

```jsonc
{
  "type": "disposition",
  "fields": {
    "horizon_years": "integer|null",
    "sale_proceeds": "money_range|null",
    "selling_costs": "money_range|null",
    "loan_payout": "money_range|null",
    "cgt": "money_range|null",
    "cgt_status": "enum [exempt, to_verify]",
    "net_proceeds": "money_range|null",
    "full_horizon_net_position": "money_range|null",
    "dispose_cash_events": "array<{ id: string, phase: string, label: localized_text, direction: enum [out, in], amount: money_range|null, is_estimate: bool, timing: enum [one_off, recurring], period: enum [once, monthly, quarterly, annual]|null, counterparty: string, source_component: string }>",
    "key_assumptions": "array<localized_text>"
  }
}
```

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
| `kb.property.capital-growth-bands` | 13 | Reused capital-growth band (ABS Total Value of Dwellings) |

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
