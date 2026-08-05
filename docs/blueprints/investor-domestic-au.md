# Investor plan card blueprint — Mode C (domestic, AU citizen/PR)

> Part of the **Vietnamese Diaspora Property Platform** document set. See [README.md](../README.md) for the full index.
>
> **This is a working specification** for the investor blueprint serving Vietnamese-Australian citizens/PRs investing in Australian property. Companion specs: [fhb-domestic-au.md](fhb-domestic-au.md) (Mode A FHB), [fhb-foreign-au.md](fhb-foreign-au.md) (Mode B foreign FHB), [investor-foreign-au.md](investor-foreign-au.md) (Mode D foreign investor).

---

## Metadata

```jsonc
{
  "blueprint_id": "investor-domestic-au",
  "effective_from": "2026-05-19",
  "effective_until": null,
  "buyer_mode": "investor",
  "user_mode": "C",
  "audience": "Vietnamese-Australian citizen or PR investing in Australian residential property — often a Mode A graduate now buying their first or subsequent investment property.",
  "firb_required": false,
  "language_primary": "en",
  "language_alternate": "vi",
  "renderer_set": "investor"
}
```

This blueprint serves **Mode C** users — Vietnamese-Australian citizens and permanent residents investing in residential property. They are **not** foreign persons, so no FIRB regime applies. First Home Buyer schemes (FHG, FHSS, Help to Buy, state FHB concessions) do **not** apply because the property is investment, not principal place of residence. The reasoning shifts from "can I afford and qualify" to "is this a good investment for my goals."

Compared to Mode A FHB, this blueprint **replaces** four FHB-specific components (`eligibility` → `investment_strategy`; FHB-flavoured `cash_position`, `buying_strategy`, `ownership_planning` → investor variants) and **adds** two genuinely new components (`yield_modelling`, `tax_structure`). Shared components (`property_assessment`, `buying_strategy` core, `due_diligence`, `settlement_prep`) carry adapted parameters reflecting investor lens.

**Direct competitive context:** HTAG AI Copilot (launched Feb 2026) targets exactly this audience — Australian property investors with AI-native analytics — but in English and aimed at professional investors. Mode C competes on Vietnamese language + family-financial-pattern fluency + lifecycle continuity from Mode A graduation, not on portfolio-analytics depth alone.

---

## Component pipeline

14 components. Two are new vs Mode A FHB (marked `★`); `disposition` (12) is added by the full-temporal-flow reframe ([`../architecture/lifecycle-simulation-model.md` §8](../architecture/lifecycle-simulation-model.md)) as the dispose-phase figure-owner; `purchase_journey` (13) and `phase_playbook` (14) were added 2026-07-10 (the B/C/D lifecycle-spine restructure, `plan-card-lifecycle-restoration.md` §11, task 4) as the whole-of-journey swimlane + its actionable per-phase layer — mode-general schema/renderers reused from Mode A, investor-specific KB content. The remainder are adapted for investor reasoning.

### Component scope (base plan vs property addendum)

| Component | Scope | Runs when |
|---|---|---|
| 1 investor_profile | `base` | Onboarding |
| 2 property_assessment (investor lens) | `per-property` | When specific property attached |
| 3 investment_strategy | `base` | Onboarding — investment thesis against target criteria |
| 4 mortgage_finance (investor variant) | `both` | Base loan structure + investor-friendly lender shortlist + IO-vs-PI decision; refined per-property when loan amount known |
| 5 yield_modelling ★ | `both` | Base estimate of typical yield in target suburb / price range; refined per-property |
| 6 tax_structure ★ | `both` | Base recommendation of entity structure + estimated tax position (incl. negative gearing analysis using mortgage_plan); refined per-property |
| 7 cash_position (investor variant) | `both` | Base estimate; refined per-property |
| 8 buying_strategy (investor tactics) | `per-property` | When user signals bid readiness |
| 9 due_diligence (investor focus) | `per-property` | When user uploads docs |
| 10 settlement_prep (+ entity setup) | `per-property` | Activated when contract signed |
| 11 ownership_planning_investor | `both` | Base estimate of portfolio fit + ongoing operations; refined per-property post-settlement |
| 12 disposition | `base` | Dispose-phase figure-owner — projected sale proceeds, selling costs, loan payout, and **full CGT** (50%-discount-if-held-over-12-months, depreciation clawback) over the hold horizon `H`; the full-horizon net position. Resolver, no agent leaf. |
| 13 purchase_journey | `base` | Whole-of-journey lifecycle swimlane — six-actor phases × cells, harvests `cash_events` off components 5/6/7/12, places them, computes nothing. Resolver, no agent leaf. |
| 14 phase_playbook | `base` | Per-phase actionable checklist + risks, behind each Flow phase sheet. Resolver, no agent leaf. |

Mode C's base plan is sharper than Mode A's because investor reasoning often happens *before* property identification — the user decides their thesis, entity, target yield, target suburb characteristics, then looks for properties matching. This makes the base plan the central decision artifact for investors.

```
[1] investor_profile (replaces buyer_profile — investor-focused)
       │   outcome: profile
       ▼
[2] property_assessment (investor lens — rental + growth + depreciation)
       │   inputs: profile
       │   outcome: property_fit_investor
       ▼
[3] investment_strategy (replaces FHB eligibility — yield/growth/gearing goals)
       │   inputs: profile, property_fit_investor
       │   outcome: strategy_thesis
       ▼
[4] yield_modelling ★
       │   inputs: profile, property_fit_investor, strategy_thesis
       │   outcome: cash_flow_projection
       ▼
[5] tax_structure ★
       │   inputs: profile, yield_modelling.outcome
       │   outcome: tax_optimised_structure
       ▼
[6] cash_position (investor variant — investment loan, higher deposit, no schemes)
       │   inputs: profile, property_fit_investor, tax_optimised_structure
       │   outcome: budget_envelope_investor
       ▼
[7] buying_strategy (investor tactics — less emotional, more analytical)
       │   inputs: property_fit_investor, budget_envelope_investor, strategy_thesis
       │   outcome: bid_plan_investor
       ▼
[8] due_diligence (investor focus — rental market, depreciation report, building quality)
       │   inputs: property_fit_investor, uploaded_docs
       │   outcome: risk_assessment_investor
       ▼
[9] settlement_prep (similar to Mode A + investor entity setup)
       │   inputs: property_fit_investor, bid_plan_investor, tax_optimised_structure
       │   outcome: settlement_checklist
       ▼
[10] ownership_planning_investor (replaces FHB ownership — property mgmt, portfolio, tax)
        inputs: property_fit_investor, tax_optimised_structure, cash_flow_projection
        outcome: portfolio_position
        │
        ▼
[11] disposition (NEW — dispose-phase figure-owner, full CGT, full-horizon net position)
        inputs: strategy_thesis (hold_period_years = H, exit_strategy), property_fit_investor,
                cash_flow_projection, tax_optimised_structure, budget_envelope_investor
        outcome: disposition
```

> The diagram numbers are sequential reading order, not component IDs (the IDs are the scope table's 1–12; `mortgage_finance` is omitted from the sketch above). `disposition` runs **last among the base figure-owners** — it places acquire figures (from `cash_position`), hold figures (from `yield_modelling`/`tax_structure` over `H`), and owns the dispose figures, so it reads every upstream figure-owner and is read by none (acyclic).

**UI tab mapping** — the fourteen components surface through **four top-level views + a Q&A tab** ([`../architecture/plan-card-lifecycle-restoration.md`](../architecture/plan-card-lifecycle-restoration.md) §11.3), not the earlier flat eight-tab rail. Applying §11.2's placement test to Mode C: `investment_strategy` is phase-shaped (a pre-Contract one-time thesis step) → folds into a Flow phase's action checklist (visible in Overview as a synthesis read, not its own tab); `yield_modelling`/`tax_structure` are money-shaped → fold into Budget as hold-phase cash rows; `ownership_planning_investor` is state-shaped with no completion point (persists across the whole plan, forward + recurring, multi-property) → earns its own **Portfolio** view, same as Mode D. `property_assessment`, `buying_strategy`, `due_diligence` are per-property and reached as backing detail via `phase_playbook.actions[].component_ref`, not as tabs.

| # | View | `kind` | What it shows |
|---|---|---|---|
| 1 | Budget | `components` (interactive) | the financial spine — `cash_position` as the phased acquisition cash-flow + what-if cockpit; `yield_modelling`/`tax_structure` as the hold-phase rental-income/expense/loan-interest/tax-refund rows; `disposition` as the full-horizon net position (buy → hold over `H` → sell) + horizon slider; each cash-event row drills to its `source_component` — lands first (2026-08, Son's call) so the buyer goes straight into cash planning |
| 2 | Overview | `synthesis` | "what this is" + aggregated read of `investor_profile` + `investment_strategy` + `mortgage_finance` + `cash_position` |
| 3 | Flow | `flow` | the legal/temporal spine — `purchase_journey` (swimlane, Prepare → … → Own → **Dispose**) as navigation; each phase opens a sheet = swimlane slice + `phase_playbook` actions (ordered, budget-linked — including `investment_strategy`'s pre-Contract thesis step) + `phase_playbook` risks; `settlement_prep` enriches the Settle phase per-property |
| 4 | Portfolio | `components` | `ownership_planning_investor` — single-property view + portfolio-aggregate view; the only Mode-C concept that's state-shaped with no completion point, so it doesn't fold into Flow or Budget |
| 5 | Q&A | `qa` | bilingual planning-agent chat (a shell surface over the engine Q&A stream — not a `component_filled`) |

**Machine-readable form** — compiled to `ui_tabs` in the artifact, **canonical for the runtime** (the table above is the human view). Rewritten 2026-07-10 (task 5, `plan-card-lifecycle-restoration.md` §11.5) from the stale pre-restructure flat vocabulary to this five-view spine, mirroring [`fhb-domestic-au.md`](fhb-domestic-au.md)'s `overview`/`flow`/`budget`/`qa` shape exactly, plus `portfolio`.

```jsonc
{
  "ui_tabs": [
    { "tab_id": "budget",    "kind": "components", "interactive": true, "components": ["cash_position", "yield_modelling", "tax_structure", "disposition"] },
    { "tab_id": "overview",  "kind": "synthesis",  "components": ["investor_profile", "investment_strategy", "mortgage_finance", "cash_position"] },
    { "tab_id": "flow",      "kind": "flow",        "components": ["purchase_journey", "phase_playbook", "settlement_prep"] },
    { "tab_id": "portfolio", "kind": "components", "components": ["ownership_planning_investor"] },
    { "tab_id": "qa",        "kind": "qa",          "components": [] }
  ]
}
```

---

## Components

### 1. investor_profile (replaces buyer_profile)

**Goal:** Capture the investor's situation — citizenship, tax bracket, existing portfolio, investment experience, risk tolerance, and investment goals.

**Inputs:** User questions answered in chat; uploaded documents (NOA, payslips, depreciation schedules from existing properties if any).

**KB anchors:** `kb.tax.income-tax-resident-2026-27`, `kb.lender.serviceability-investment-loans`, `kb.investor.experience-levels`

**Renderer:** `summary-card`

**UI tab hint:** Overview (collapsed) + Investment strategy (detail)

**Parameters:**

```jsonc
{
  "application": {
    "location_state": { "type": "enum", "options": ["NSW", "VIC", "QLD", "WA", "SA", "TAS", "ACT", "NT"], "value": "<initial>" },
    "applicant_count": { "type": "integer", "value": 1, "note": "= applicants[] length. Replaces the old buying_alone / co_investor_count (buying_alone ≡ applicant_count == 1; co_investor_count ≡ applicant_count − 1)." },
    "dependents_count": { "type": "integer", "value": 0 }
  },
  "applicants": {
    "type": "array<applicant>",
    "note": "F1 — one entry per person taking an ownership interest. Mode C: 1..N citizen/PR investors. The tax-bearing facts (marginal rate, tax residency) are PER-APPLICANT — a joint investment is assessed per owner. citizenship_status is citizen/PR only; a foreign co-investor routes to the FIRB path (→ Mode D). No first-home ownership_history / owner_occupier_intent — not eligibility-bearing for an investor (the canonical applicant element carries them; an investor simply does not fill them).",
    "value": [
      {
        "role": { "type": "enum", "options": ["primary", "co_investor"], "value": "primary" },
        "citizenship_status": { "type": "enum", "options": ["citizen", "permanent_resident"], "value": "<initial>" },
        "firb_required": { "type": "bool", "value": false, "derived_from": "citizenship_status", "note": "Mode C = domestic; false for every applicant. The household aggregate profile.firb_required_any is the single FIRB fact read across modes." },
        "taxable_income": { "type": "money_per_year", "value": "<initial>", "note": "per-applicant assessable income; the household assessable_income aggregates the array." },
        "tax": {
          "residency_for_tax": { "type": "enum", "options": ["resident", "non_resident", "temporary_resident_for_tax"], "value": "resident", "note": "Mode-C-activated tax{} (fact-model-unification.md 'Mode-C activation'). Drives the CGT 50% discount + main-residence interactions read by tax_structure / disposition." },
          "marginal_rate": { "type": "percentage", "value": "<initial>", "derived_from": "taxable_income", "note": "per-applicant marginal rate (kb.tax.income-tax-resident-2026-27); read as applicant.tax.marginal_rate by tax_structure / disposition." },
          "jurisdiction": { "type": "enum", "options": ["AU"], "value": "AU", "note": "Mode C = AU tax jurisdiction; Mode D adds VN." }
        }
      }
    ],
    "_item_note": "Each array entry is one investor with the shape shown; the single example entry illustrates the per-applicant leaf schema."
  },
  "income": {
    "income_stability": { "type": "enum", "options": ["permanent_payg", "contractor", "self_employed", "casual", "mixed"], "value": "<initial>" }
  },
  "existing_portfolio": {
    "ppor_owned": { "type": "bool", "value": "<initial>" },
    "ppor_estimated_equity": { "type": "money", "value": 0 },
    "existing_investment_properties_count": { "type": "integer", "value": 0 },
    "existing_investment_portfolio_value": { "type": "money", "value": 0 },
    "existing_investment_portfolio_loans": { "type": "money", "value": 0 },
    "existing_portfolio_net_yield_estimate": { "type": "percentage", "value": "<initial>" }
  },
  "investment_experience": {
    // experience_level → profile.traits.experience_level (Mode-C-activated; a persistent trait that accumulates across journeys, NOT a per-journey posture)
    "experience_level": { "type": "enum", "options": ["first_investment", "second_or_third", "experienced_4_plus"], "value": "<initial>" },
    "depreciation_strategies_used": { "type": "bool", "value": "<initial>" },
    "trust_or_company_structures_used": { "type": "bool", "value": "<initial>" }
  },
  // investment_goals + risk_tolerance are plan.* facts (per-journey), NOT profile facts (engine-contract §9.1, architecture §11.9):
  // collected here pending the item-4 storage split, exactly as Mode A still keeps purchase_target in buyer_profile params.
  "investment_goals": {
    "primary_goal": { "type": "enum", "options": ["cash_flow", "capital_growth", "balanced", "tax_optimisation", "diversification"], "value": "<initial>" },
    "secondary_goal": { "type": "enum", "options": ["cash_flow", "capital_growth", "balanced", "tax_optimisation", "diversification", "none"], "value": "none" },
    "intended_hold_period_years": { "type": "integer", "value": "<initial>" },
    "exit_strategy": { "type": "enum", "options": ["sell_at_target", "hold_perpetually", "leverage_into_next", "transfer_to_family"], "value": "<initial>" }
  },
  "risk_tolerance": {
    "comfort_with_negative_gearing": { "type": "enum", "options": ["preferred", "acceptable", "avoid"], "value": "<initial>" },
    "comfort_with_vacancy_months": { "type": "integer", "value": "<initial>" },
    "leverage_comfort_lvr": { "type": "percentage", "value": "<initial>" }
  }
}
```

**Outcome schema:** `profile`

```jsonc
{
  "type": "profile",   // canonical, mode-independent identity shape — Mode C projects the investor subset (fact-model-unification.md "Mode-C activation"); NOT a private profile type
  "fields": {
    // legal-status & tax facts — PER-APPLICANT (read as applicant.*). Mode C: 1..N citizen/PR investors.
    "applicants": "array<{ role, citizenship_status, firb_required, tax }>",  // role ∈ {primary, co_investor}; per-applicant tax{ residency_for_tax, marginal_rate, jurisdiction } (Mode-C-activated nested object, jurisdiction=AU). No owner_occupier_intent / first-home ownership_history — not eligibility-bearing for an investor.
    "applicant_count": "integer",
    "firb_required_any": "bool",                      // derived = false for Mode C (domestic citizen/PR) — the SINGLE household FIRB fact, read uniformly across all modes (B/D = true)
    // household-level FACTS (not verdicts)
    "assessable_income": "money_per_year",            // aggregate of applicants[].taxable_income
    "approx_borrowing_capacity": "money_range",       // canonical name, investment-loan flavoured by plan.intent (§98 — banded, resolver-computed)
    "deposit_ready_for_purchase_amount": "money",
    "ppor_equity_available_for_leverage": "money",    // equity release from an owned PPOR; read by mortgage_finance
    "debts": "{ hecs_balance, credit_card_limits_total, personal_loans_balance, car_loan_balance, buy_now_pay_later_balance } | null",  // raw debt facts the serviceability resolver reads (profile HOLDS facts; mortgage reasons over them). null until captured (honest-partial).
    "existing_portfolio": "{ ppor_owned, ppor_estimated_equity, investment_count, investment_value, investment_loans, net_yield_estimate } | null",  // Mode-C-activated household_financials.existing_portfolio
    "traits": "{ experience_level } | null",          // Mode-C-activated — persistent disposition, accumulates across journeys (per-journey posture is plan.risk_tolerance, NOT here)
    // narrative
    "key_constraints": "array<localized_text>",       // bilingual (engine-output), canonical type — was array<string>
    "key_strengths": "array<localized_text>"
    // DROPPED primary_investment_goal → plan.investment_goals.primary (a plan fact, not an identity fact)
    // DROPPED negative_gearing_attractive → a tax_structure verdict (outcomes carry facts, not verdicts; §11.9)
  }
}
```

> **Identity-layer conformance (2026-06-23).** This component's outcome is now the **canonical `profile`** (not a per-mode `profile`), projecting the Mode-C-activated generalizations — per-applicant `tax{}`, `existing_portfolio`, `traits` ([`../architecture/fact-model-unification.md`](../architecture/fact-model-unification.md) "Mode-C activation"). Downstream components read `profile.*` / `applicant.*` / `plan.*` (architecture §11.9 read-namespace convention). **Deferred to the Mode-C wedge:** the downstream components' precise field-path reads, the investor KB (`kb.investor.*` / `kb.tax.*`), flipping Mode C **in-scope**, and the compiler's **semantic**-gate extension. This unit conforms the identity layer and keeps the **structural** gates green.

---

### 2. property_assessment (investor lens)

**Goal:** Analyse the property *with investor metrics* — rental yield potential, capital growth indicators, depreciation potential, area dynamics.

**Inputs:** `property_card` (from selection) + `investor_profile.outcome`

**KB anchors:** `kb.property.rental-market-data-sources`, `kb.property.growth-corridors-au`, `kb.property.depreciation-by-build-year`, `kb.property.investor-grade-features`, `kb.property.comparables-methodology`, `kb.strata.health-indicators-investor-lens`

**Renderer:** `summary-card`

**UI tab hint:** Property + Overview

**Parameters:**

```jsonc
{
  "basics": {
    "address": { "type": "string", "value": "<from_property_card>" },
    "suburb": { "type": "string", "value": "<from_property_card>" },
    "state": { "type": "enum", "value": "<from_property_card>" },
    "price": { "type": "money", "value": "<from_property_card>" },
    "property_type": { "type": "enum", "options": ["established_house", "established_apartment", "new_house", "new_apartment", "off_the_plan", "house_and_land", "dual_occupancy", "nrass"], "value": "<from_property_card>" },
    "year_built": { "type": "integer", "value": "<initial>" },
    "land_size_sqm": { "type": "integer", "value": "<initial>" },
    "internal_area_sqm": { "type": "integer", "value": "<initial>" }
  },
  "investor_grade_features": {
    "land_to_asset_ratio": { "type": "percentage", "value": "<initial>" },
    "rentable_bedroom_count": { "type": "integer", "value": "<initial>" },
    "rentable_living_areas": { "type": "integer", "value": "<initial>" },
    "outdoor_space_quality": { "type": "enum", "options": ["excellent", "good", "minimal", "none"], "value": "<initial>" },
    "parking_quality": { "type": "enum", "options": ["double_garage", "single_garage", "covered_carport", "off_street", "street_only"], "value": "<initial>" }
  },
  "rental_market": {
    "estimated_weekly_rent_range": { "type": "money_range_per_week", "value": "<initial>", "agent_reasoning_required": true, "reasoning_domain": "rentability" },
    "rental_market_vacancy_rate_suburb": { "type": "percentage", "value": "<initial>" },
    "days_on_market_typical_for_rent": { "type": "integer", "value": "<initial>" },
    "tenant_demand_score": { "type": "integer_0_10", "value": "<initial>" },
    "rental_yield_estimate_gross": { "type": "percentage", "value": "<initial>" }
  },
  "growth_indicators": {
    "5_year_capital_growth_suburb": { "type": "percentage", "value": "<initial>" },
    "10_year_capital_growth_suburb": { "type": "percentage", "value": "<initial>" },
    "population_growth_local_government_area": { "type": "percentage_per_year", "value": "<initial>" },
    "infrastructure_pipeline_score": { "type": "integer_0_10", "value": "<initial>" },
    "supply_pipeline_concern": { "type": "enum", "options": ["low", "moderate", "high", "concerning"], "value": "<initial>" }
  },
  "depreciation_potential": {
    "build_year_estimated": { "type": "integer", "value": "<initial>", "derived_from": "basics.year_built" },
    "post_1987_capital_works_depreciable": { "type": "bool", "value": "<initial>", "derived_from": "build_year_estimated" },
    "plant_and_equipment_depreciable": { "type": "bool", "value": "<initial>", "note": "Only applies to new properties or substantial renovations post May 2017" },
    "estimated_annual_depreciation_year_1": { "type": "money", "value": "<initial>" }
  },
  "location_factors": {
    "school_catchment_quality": { "type": "enum", "options": ["strong", "average", "weak", "unknown"], "value": "<initial>" },
    "transport_score": { "type": "integer_0_100", "value": "<initial>" },
    "flood_risk_band": { "type": "enum", "options": ["none", "low", "medium", "high", "unknown"], "value": "<initial>" },
    "planning_changes_pending": { "type": "array<string>", "value": [] }
  },
  "strata_or_building": {
    "applicable": { "type": "bool", "value": "<initial>", "derived_from": "basics.property_type" },
    "body_corporate_quarterly_fees": { "type": "money", "value": "<initial>" },
    "sinking_fund_balance": { "type": "money", "value": "<initial>" },
    "special_levies_in_last_3_years": { "type": "array<string>", "value": [] }
  },
  "market_position": {
    "comparable_sales": { "type": "array<comparable_sale>", "value": [], "agent_reasoning_required": true, "reasoning_domain": "valuation" },
    "estimated_market_value_range": { "type": "money_range", "value": "<initial>", "agent_reasoning_required": true, "reasoning_domain": "valuation" },
    "asking_price_vs_market": { "type": "enum", "options": ["below_market", "fair", "above_market", "significantly_above"], "value": "<initial>", "agent_reasoning_required": true, "reasoning_domain": "valuation" }
  }
}
```

**Outcome schema:** `property_fit_investor`

```jsonc
{
  "type": "property_fit_investor",
  "fields": {
    // neutral property facts (per-property fact surface) — the only route downstream components
    // read property data; never via basics.* params (§11.9 one access path). estimated_weekly_rent_range
    // is a computed property fact (agent leaf in rental_market) that yield_modelling reads.
    "state": "enum [NSW, VIC, QLD, WA, SA, TAS, ACT, NT]",
    "suburb": "string",
    "price": "money",
    "property_type": "enum [established_house, established_apartment, new_house, new_apartment, off_the_plan, house_and_land]",
    "estimated_weekly_rent_range": "money_range_per_week",
    // viability verdicts (this component's own reasoning)
    "viability_verdict": "enum [strong_investment, acceptable_investment, marginal, reconsider]",
    "rental_yield_gross_estimate": "percentage",
    "capital_growth_outlook": "enum [strong, moderate, flat, declining]",
    "depreciation_attractiveness": "enum [strong, moderate, weak]",
    "land_quality_score": "integer_0_10",
    "key_strengths": "array<string>",
    "key_concerns": "array<string>",
    "investor_grade_overall": "integer_0_10"
  }
}
```

---

### 3. investment_strategy (replaces FHB eligibility)

**Goal:** Articulate a clear investment thesis for this property — yield target, growth target, gearing target, hold period, exit strategy. Tied to investor's goals from `investor_profile`.

**Inputs:** `investor_profile.outcome` + `property_fit_investor.outcome`

**KB anchors:** `kb.investor.strategy-archetypes`, `kb.investor.gearing-types-and-implications`, `kb.investor.hold-period-considerations`, `kb.investor.exit-strategy-options`, `kb.investor.target-yield-by-archetype`

**Renderer:** `summary-card`

**UI tab hint:** Investment strategy (central) + Overview

**Parameters:**

```jsonc
{
  "thesis": {
    "strategy_archetype": { "type": "enum", "options": ["cash_flow", "capital_growth", "balanced", "dual_income", "value_add", "land_banking"], "value": "<initial>", "agent_reasoning_required": true, "reasoning_domain": "investment_thesis" },
    "thesis_one_liner": { "type": "string", "value": "<initial>", "agent_reasoning_required": true, "reasoning_domain": "investment_thesis" }
  },
  "targets": {
    "target_gross_yield": { "type": "percentage", "value": "<initial>" },
    "target_capital_growth_per_year": { "type": "percentage", "value": "<initial>" },
    "target_combined_return_per_year": { "type": "percentage", "value": "<initial>" },
    "hold_period_years": { "type": "integer", "value": "<initial>" }
  },
  "gearing_strategy": {
    "gearing_type": { "type": "enum", "options": ["positive_geared", "neutral_geared", "negatively_geared"], "value": "<initial>", "agent_reasoning_required": true, "reasoning_domain": "investment_thesis" },
    "target_lvr": { "type": "percentage", "value": "<initial>" },
    "interest_only_vs_pi": { "type": "enum", "options": ["interest_only", "principal_and_interest"], "value": "<initial>" },
    "offset_account_strategy": { "type": "enum", "options": ["use_for_buffer", "use_for_other_property", "not_applicable"], "value": "<initial>" }
  },
  "exit_strategy": {
    "primary_exit": { "type": "enum", "options": ["sell_at_target_growth", "hold_perpetually", "leverage_into_next_property", "rent_perpetually", "transfer_to_family"], "value": "<initial>" },
    "secondary_exit_if_primary_fails": { "type": "enum", "options": ["sell_at_loss", "hold_longer", "convert_to_ppor", "subdivide_or_renovate"], "value": "<initial>" }
  },
  "deal_breakers": {
    "minimum_yield_acceptable": { "type": "percentage", "value": "<initial>" },
    "maximum_negative_gearing_loss_acceptable": { "type": "money_per_year", "value": "<initial>" },
    "minimum_growth_outlook_acceptable": { "type": "enum", "options": ["strong", "moderate", "flat", "any"], "value": "<initial>" }
  }
}
```

**Outcome schema:** `strategy_thesis`

```jsonc
{
  "type": "strategy_thesis",
  "fields": {
    "archetype": "enum",
    "one_liner": "string",
    "target_gross_yield": "percentage",
    "target_capital_growth": "percentage",
    "gearing_type": "enum",
    "target_lvr": "percentage",
    "hold_period_years": "integer",
    "exit_strategy": "enum",
    "is_property_aligned_with_thesis": "bool",
    "alignment_reasoning": "string"
  }
}
```

---

### 4. mortgage_finance (investor variant)

**Goal:** Determine **investment loan structure** (IO vs P&I; offset strategy; fixed vs variable), shortlist investor-friendly lenders, plan refinance triggers for portfolio growth, with explicit reasoning about how loan structure interacts with negative gearing strategy.

**Inputs:** `investor_profile.outcome` (profile — including debts, marginal tax rate, existing portfolio) + `investment_strategy.outcome` (strategy_thesis — particularly gearing_type and target_lvr)

**KB anchors:** `kb.lender.investment-loan-policies`, `kb.lender.investor-friendly-shortlist`, `kb.loan.interest-only-vs-pi-investor`, `kb.loan.offset-vs-redraw-investor`, `kb.loan.refinance-strategies-portfolio-growth`, `kb.lender.hecs-treatment-by-lender`, `kb.loan.fixed-rate-roll-off-planning`, `kb.lender.serviceability-investment-loans`

**Renderer:** `summary-card` + `data-table`

**UI tab hint:** Investment strategy (detail) + Yield & Tax (loan cost context)

**Scope:** `both` — base estimate against profile + target price range + strategy thesis; refined per-property when actual loan amount known

**Parameters:**

```jsonc
{
  "borrowing_capacity": {
    "investment_loan_assessment": { "type": "money_range", "value": "<initial>", "note": "Investment loans use different serviceability — typically excludes rental income at full value (lenders haircut ~20–30%)" },
    "lender_pool_size": { "type": "integer", "value": "<initial>" },
    "uses_existing_ppor_equity": { "type": "bool", "value": "<initial>", "agent_reasoning_required": true, "reasoning_domain": "lender_fit" },
    "equity_release_amount": { "type": "money", "value": "<initial>", "derived_from": "investor_profile.existing_portfolio.ppor_estimated_equity" }
  },
  "loan_structure": {
    "principal_and_interest_vs_interest_only": { "type": "enum", "options": ["principal_and_interest", "interest_only"], "value": "<initial>", "agent_reasoning_required": true, "reasoning_domain": "lender_fit", "note": "Most investors choose IO for tax efficiency; agent reasons based on strategy thesis" },
    "interest_only_period_years": { "type": "integer", "value": 5, "note": "Standard IO term is 5 years; max 10 with renewal" },
    "fixed_vs_variable": { "type": "enum", "options": ["variable", "fixed_1yr", "fixed_2yr", "fixed_3yr", "split_fixed_variable"], "value": "<initial>", "agent_reasoning_required": true, "reasoning_domain": "lender_fit" },
    "offset_account_strategy": { "type": "enum", "options": ["full_offset_on_this_property", "offset_pointed_at_ppor_for_tax_efficiency", "redraw_only", "no_offset"], "value": "<initial>", "agent_reasoning_required": true, "reasoning_domain": "lender_fit", "note": "For investors with existing PPOR, offset should typically be on the PPOR not the investment property — tax efficiency" }
  },
  "lender_synthesis": {
    "investor_friendly_lender_shortlist": { "type": "array<{ lender, rate_range, investment_loan_specialty, processing_time }>", "value": [], "agent_reasoning_required": true, "reasoning_domain": "lender_fit" },
    "lenders_lenient_on_rental_income_haircut": { "type": "array<string>", "value": [] },
    "lenders_with_offset_on_investment_loans": { "type": "array<string>", "value": [] }
  },
  "debt_optimisation_recommendations": {
    "hecs": {
      "current_balance": { "type": "money", "value": "<from_investor_profile>" },
      "clear_before_application_recommended": { "type": "bool", "value": "<initial>" },
      "investor_lender_treatment": { "type": "string", "value": "<initial>" }
    },
    "consolidate_other_debts_into_ppor": { "type": "bool", "value": "<initial>", "note": "Sometimes worth consolidating personal/credit-card debt into PPOR loan (lower rate) before applying for investment loan" }
  },
  "refinance_planning": {
    "fixed_rate_roll_off_date": { "type": "date", "value": "<initial>" },
    "io_period_expiry_date": { "type": "date", "value": "<initial>" },
    "io_extension_strategy": { "type": "enum", "options": ["extend_io", "switch_to_pi", "refinance_to_new_io"], "value": "<initial>" },
    "next_property_equity_release_target_date": { "type": "date", "value": "<initial>", "note": "When refinance for equity release becomes feasible (typically 18–24 months after settlement with growth)" },
    "lvr_target_for_next_purchase": { "type": "percentage", "value": 70 }
  },
  "smsf_lrba_specifics": {
    "applicable": { "type": "bool", "value": "<initial>", "derived_from": "investment_strategy.tax_structure.recommended_entity" },
    "lrba_lender_shortlist": { "type": "array<string>", "value": [], "note": "Very limited lender pool for SMSF Limited Recourse Borrowing Arrangements" }
  }
}
```

**Outcome schema:** `mortgage_plan`

```jsonc
{
  "type": "mortgage_plan",
  "fields": {
    "recommended_loan_structure": "object",
    "recommended_lender_shortlist": "array<{ lender, reasoning, approval_likelihood }>",
    "io_vs_pi_recommendation": "enum",
    "offset_strategy_recommendation": "enum",
    "refinance_plan_for_portfolio_growth": "object",
    "debt_optimisations_to_action": "array<string>",
    "loan_cost_estimate_year_1": "money"
  }
}
```

The `mortgage_plan` outcome feeds `yield_modelling.loan_costs` (the loan cost calculation for cash flow projection), `tax_structure.negative_gearing_analysis` (negative gearing depends on loan structure), `cash_position` (loan amount + LMI), and `ownership_planning_investor.portfolio_position` (refinance plan for next property).

---

### 5. yield_modelling ★ (NEW)

**Goal:** Model rental income, operating expenses, and cash flow before and after tax. Produce a cash flow projection over the hold period.

**Inputs:** `investor_profile.outcome` + `property_fit_investor.outcome` + `strategy_thesis`

**KB anchors:** `kb.investor.rental-income-modelling`, `kb.investor.operating-expenses-typical-ratios`, `kb.investor.vacancy-rate-assumptions`, `kb.investor.cash-flow-modelling-methodology`, `kb.investor.property-management-fees`, `kb.lender.serviceability-basics`, `kb.lender.serviceability-investment-loans`, `kb.investor.deposit-requirements-investment-loans`, `kb.loan.interest-only-vs-pi-investor`

> The last four anchors are the **post-loan financing provenance** (Slice B3a): the cash-flow interest is computed at a representative leverage — loan = price × the LVR baseline (`deposit-requirements`, 80%), rate = OO product rate (`serviceability-basics`) + the investment premium (`serviceability-investment-loans`), interest-only basis (`interest-only-vs-pi-investor`). This equals the `mortgage_plan`→`yield_modelling.loan_costs` figure the prose below intends, modelled here until `mortgage_finance` runs per-property.

**Renderer:** `calculator`

**UI tab hint:** Yield & Tax (central)

**Parameters:**

```jsonc
{
  "rental_income": {
    "weekly_rent_estimate": { "type": "money_per_week", "value": "<from_property_assessment>" },
    "annual_gross_rental_income": { "type": "money_per_year", "value": "<initial>" },
    "vacancy_rate_assumed": { "type": "percentage", "value": "<initial>" },
    "effective_annual_rental_income": { "type": "money_per_year", "value": "<initial>" }
  },
  "operating_expenses": {
    "property_management_percentage_of_rent": { "type": "percentage", "value": 7.5 },
    "property_management_annual": { "type": "money_per_year", "value": "<initial>" },
    "council_rates_annual": { "type": "money_per_year", "value": "<initial>" },
    "water_rates_annual": { "type": "money_per_year", "value": "<initial>" },
    "body_corporate_annual": { "type": "money_per_year", "value": "<initial>", "applicable": "<initial>" },
    "landlord_insurance_annual": { "type": "money_per_year", "value": "<initial>" },
    "building_insurance_annual": { "type": "money_per_year", "value": "<initial>" },
    "land_tax_annual": { "type": "money_per_year", "value": "<initial>" },
    "maintenance_repairs_reserve_annual": { "type": "money_per_year", "value": "<initial>" },
    "letting_fees_periodic": { "type": "money_per_year", "value": "<initial>" }
  },
  "loan_costs": {
    "loan_amount": { "type": "money", "value": "<initial>" },
    "interest_rate_assumed": { "type": "percentage", "value": "<initial>" },
    "interest_only_period_years": { "type": "integer", "value": 5 },
    "annual_interest_expense_year_1": { "type": "money_per_year", "value": "<initial>" }
  },
  "yields_and_cash_flow": {
    "gross_rental_yield": { "type": "percentage", "value": "<initial>" },
    "net_rental_yield_pre_loan": { "type": "percentage", "value": "<initial>" },
    "net_rental_yield_post_loan_pre_tax": { "type": "percentage", "value": "<initial>" },
    "cash_flow_before_tax_year_1": { "type": "money_per_year", "value": "<initial>" },
    "cash_flow_before_tax_per_week": { "type": "money_per_week", "value": "<initial>" }
  },
  "multi_year_projection": {
    "rent_growth_assumed_per_year": { "type": "percentage", "value": 3 },
    "expense_growth_assumed_per_year": { "type": "percentage", "value": 3 },
    "year_5_cash_flow_estimate": { "type": "money_per_year", "value": "<initial>" },
    "year_10_cash_flow_estimate": { "type": "money_per_year", "value": "<initial>" }
  }
}
```

**Outcome schema:** `cash_flow_projection`

```jsonc
{
  "type": "cash_flow_projection",
  "fields": {
    "annual_rental_income_year_1": "money_range",
    "annual_operating_expenses_year_1": "money_range",
    "annual_interest_year_1": "money",
    "cash_flow_before_tax_year_1": "money_range",
    "cash_flow_before_tax_per_week": "money_range",
    "gross_yield": "percentage_range",
    "net_yield_pre_loan": "percentage_range",
    "net_yield_post_loan_pre_tax": "percentage_range",
    "year_5_projected_cash_flow": "money_range",
    "year_10_projected_cash_flow": "money_range",
    "is_positive_neutral_or_negative_geared_pre_tax": "enum",
    "cash_events": "array<{ id: string, phase: 'own', label: localized_text, direction: enum [out, in], amount: money_range, is_estimate: bool, timing: 'recurring', period: 'year', counterparty: string, source_component: 'yield_modelling' }>"  // the hold-phase recurring spine (rental_income in/tenant, operating_expenses out/property_manager, loan_interest out/lender) — purchase_journey's generic multi-source harvest places these at phase `own`; a scalar figure (loan_interest) collapses to [v,v], matching the registry's money_range type (2026-07-10, task 4)
  }
}
```

**The banded money surface (Slice B0 — the cross-contract seam, decided).** The weekly rent is an irreducible **range** (`property_fit_investor.estimated_weekly_rent_range`), and the KB methodology carries it as such — *"the income line, and the yields built on it, are surfaced as ranges, not false-precision points"* (`kb.investor.rental-income-modelling`). So every rent-dependent figure here is a **`money_range` / `percentage_range`** `[lo, hi]` band, not a scalar — matching `disposition`'s already-banded surface (`sale_proceeds`, `net_proceeds`, …) and the `calculator` renderer, which renders a band as `$lo – $hi` and **collapses `[x, x]` to a single `$x`** for a point figure. The **one exception is `annual_interest_year_1`** (`money`, scalar): interest is `loan × rate` — deterministic given the loan, *not* rent-derived, so it carries no band. The disposition consumer (`full_horizon_investor`) coerces a scalar to `[x, x]` (`money_range/1`), so the band propagation is backward-compatible. `percentage_range` is a validated figure type (a `[lo, hi]` list of numbers), added to the compiler `SCALAR_TYPES` + the outcome validator alongside `money_range`.

**Hold-phase `cash_events` (full-temporal-flow wiring — RESOLVED 2026-07-10, task 4).** `yield_modelling` owns the **recurring hold-phase** flows that the full-horizon financial spine places at phase `own` over the horizon `H`: rental income (`money_in`, `timing: recurring`, `period: year`), operating expenses and loan interest (`money_out`, recurring/year), each `source_component: yield_modelling`, gated by the §13 placement/provenance check. These are the holding-years entries the truncated (acquire-only) model had nowhere to put; `tax_structure` adds the negative-gearing tax effect on the same axis (below). Implemented by `fh_engine_fill:yield_cash_events/1` (`engine/erlang/src/fh_engine_fill.erl`); an event is emitted only when its figure is non-null (honest-partial — the strata opex gap, or no property attached, drop the corresponding event, never fabricate one).

---

### 6. tax_structure ★ (NEW)

**Goal:** Determine the tax-optimised ownership structure and quantify negative gearing benefit + depreciation + CGT projection.

**Inputs:** `investor_profile.outcome` + `property_fit_investor` + `cash_flow_projection`

> `property_fit_investor` (its `property_type`) drives the **negative-gearing reform note** (established → loses the wage offset from 1 Jul 2027; new build → keeps it; absent → the general caveat). Absent at base → the general caveat; present per-property → the concrete established-vs-new determination.

**KB anchors:** `kb.tax.entity-comparison-personal-trust-company-smsf`, `kb.tax.negative-gearing-mechanics`, `kb.tax.depreciation-division-43-and-40`, `kb.tax.cgt-50-percent-discount`, `kb.tax.quantity-surveyor-reports`, `kb.tax.land-tax-by-state`

**Renderer:** `data-table` + `calculator`

**UI tab hint:** Yield & Tax

**Parameters:**

```jsonc
{
  "ownership_entity": {
    "recommended_entity": { "type": "enum", "options": ["personal_sole", "personal_joint", "discretionary_trust", "unit_trust", "company", "smsf", "smsf_with_lrba"], "value": "<initial>", "agent_reasoning_required": true, "reasoning_domain": "entity_structuring" },
    "reasoning": { "type": "string", "value": "<initial>" },
    "setup_cost_estimate": { "type": "money", "value": "<initial>" },
    "annual_compliance_cost_estimate": { "type": "money_per_year", "value": "<initial>" }
  },
  "negative_gearing_analysis": {
    "applicable": { "type": "bool", "value": "<initial>" },
    "annual_taxable_loss_year_1": { "type": "money_per_year", "value": "<initial>" },
    "marginal_tax_rate_at_which_offset": { "type": "percentage", "value": "<from_investor_profile>" },
    "annual_tax_refund_year_1": { "type": "money_per_year", "value": "<initial>" },
    "after_tax_cash_flow_year_1": { "type": "money_per_year", "value": "<initial>" },
    "after_tax_cash_flow_per_week": { "type": "money_per_week", "value": "<initial>" }
  },
  "depreciation_schedule": {
    "quantity_surveyor_report_required": { "type": "bool", "value": true },
    "quantity_surveyor_report_cost": { "type": "money", "value": "<initial>" },
    "capital_works_depreciation_year_1": { "type": "money", "value": "<initial>" },
    "plant_and_equipment_depreciation_year_1": { "type": "money", "value": "<initial>" },
    "total_depreciation_year_1": { "type": "money", "value": "<initial>" },
    "total_depreciation_year_5": { "type": "money", "value": "<initial>" },
    "total_depreciation_year_10": { "type": "money", "value": "<initial>" }
  },
  "cgt_determinants": {
    // RESOLVED (§8.5): the previously-homeless `cgt_projection` (a figure with no phase, no
    // cash_event, no owner) is reframed here as the CGT *determinants*. The dispose-phase CGT
    // FIGURE (projected gain, taxable gain, cgt payable) is computed and OWNED by `disposition`
    // (component 12) at the `dispose` phase, where it lands as a cash_event — one-computer-per-figure.
    // This block supplies only the inputs to that calc.
    "50_percent_discount_eligible": { "type": "bool", "value": true, "note": "Resolver — true if held >12 months (kb.tax.cgt-50-percent-discount); read by disposition" },
    "marginal_tax_rate_for_cgt": { "type": "percentage", "value": "<from_investor_profile>", "note": "rate at which the (discounted) gain is taxed; read by disposition" },
    "cost_base_depreciation_clawback": { "type": "bool", "value": true, "note": "capital-works (Div 43) claimed reduces the cost base → larger gain at sale; the depreciation interplay (§8.5), applied by disposition" }
  },
  "annual_compliance": {
    "tax_return_complexity": { "type": "enum", "options": ["simple_personal", "joint", "trust_distribution", "company", "smsf"], "value": "<initial>" },
    "accountant_fees_annual": { "type": "money_per_year", "value": "<initial>" },
    "bas_required": { "type": "bool", "value": false }
  },
  "smsf_specific": {
    "is_smsf": { "type": "bool", "value": "<initial>", "derived_from": "ownership_entity.recommended_entity" },
    "lrba_arrangement_required": { "type": "bool", "value": "<initial>" },
    "trust_deed_compliant_for_property": { "type": "bool", "value": "<initial>" },
    "smsf_audit_fees_annual": { "type": "money_per_year", "value": "<initial>" }
  }
}
```

**Outcome schema:** `tax_optimised_structure`

```jsonc
{
  "type": "tax_optimised_structure",
  "fields": {
    "recommended_entity": "enum",
    "negative_gearing_active": "bool",
    "annual_tax_refund_year_1": "money_range",
    "after_tax_cash_flow_year_1": "money_range",
    "after_tax_cash_flow_per_week": "money_range",
    "total_depreciation_year_1": "money",  // band-vs-point pends the deferred QS/cost-basis producer's input shape (banded-vs-scalar rule); scalar until then
    "cgt_discount_eligible": "bool",
    "cgt_marginal_rate": "percentage",
    "cost_base_depreciation_clawback": "bool",
    "annual_compliance_cost": "money_range",  // KB entity-setup-costs: indicative cost band, "never a point quote" → banded by the banded-vs-scalar rule
    "setup_costs": "money_range",  // KB entity-setup-costs: indicative cost band, "never a point quote" → banded by the banded-vs-scalar rule
    // The announced 2026-27 Budget negative-gearing reform (NG limited to new builds from 1 Jul
    // 2027 — kb.tax.negative-gearing-mechanics, PROPOSED not law). A bilingual decision-support
    // caveat, resolver-selected from property_fit_investor.property_type (established → loses the
    // wage offset; new build → keeps it; no property → general caveat). Never null — at base it is
    // the general caveat. Copy in kb.copy.tax-structure; the figure itself stays out of the LLM's reach.
    "negative_gearing_reform_note": "localized_text | null",
    "cash_events": "array<{ id: 'tax_refund', phase: 'own', label: localized_text, direction: 'in', amount: money_range, is_estimate: bool, timing: 'recurring', period: 'year', counterparty: 'government', source_component: 'tax_structure' }>"  // the negative-gearing tax-refund leg of the hold-phase spine — emitted only when negatively geared AND the marginal rate is known (honest-partial); purchase_journey's generic multi-source harvest places it at phase `own` (2026-07-10, task 4)
  }
}
```

**Hold-phase + dispose wiring (full-temporal-flow — RESOLVED 2026-07-10, task 4).** `tax_structure` owns the **recurring hold-phase** negative-gearing tax effect — the annual tax refund (`money_in`, `timing: recurring`, `period: year`, `source_component: tax_structure`) placed at phase `own` over `H` — and supplies the **CGT determinants** (`cgt_determinants` block above: discount eligibility, marginal rate, depreciation clawback) to `disposition` (component 12), which owns the **dispose-phase CGT figure** and its cash_event. The previously-homeless `cgt_projection` is thus resolved: hold-phase tax effects stay here; the dispose-phase gain/payable lands at the `dispose` phase, owned by the one computer for that figure. Implemented by `fh_engine_fill:tax_cash_events/1`.

---

### 7. cash_position (investor variant)

**Goal:** Compute cash needs — *investment-loan terms (no schemes, typically 20%+ deposit), no FHB stamp duty concessions, but no foreign-buyer surcharge either*.

**Inputs:** `investor_profile.outcome` + `property_fit_investor.outcome` + `tax_optimised_structure`

**KB anchors:** `kb.stamp-duty.calc-by-state`, `kb.investor.deposit-requirements-investment-loans`, `kb.lmi.calculation`, `kb.buyer-costs.investor-additional-costs`, `kb.tax.quantity-surveyor-reports`, `kb.tax.entity-setup-costs`

**Renderer:** `calculator`

**UI tab hint:** Cash calculator

**Parameters:**

```jsonc
{
  "inputs": {
    "property_price": { "type": "money", "value": "<from_property_assessment>" },
    "available_cash": { "type": "money", "value": "<from_investor_profile>" },
    "ppor_equity_for_leverage": { "type": "money", "value": "<from_investor_profile>" },
    "preferred_funding_split": { "type": "enum", "options": ["cash_only", "equity_release_only", "mixed"], "value": "<initial>" }
  },
  "deposit": {
    "minimum_required_percentage_investment_loan": { "type": "percentage", "value": 10, "note": "Some lenders accept 10% with LMI; 20% standard" },
    "recommended_percentage": { "type": "percentage", "value": 20 },
    "deposit_amount": { "type": "money", "value": "<initial>" }
  },
  "stamp_duty": {
    "standard_stamp_duty": { "type": "money", "value": "<initial>" },
    "first_home_concession_applicable": { "type": "bool", "value": false },
    "investor_concession_applicable_if_any": { "type": "bool", "value": "<initial>" }
  },
  "other_buying_costs": {
    "building_pest_inspection": { "type": "money", "value": "<initial>" },
    "conveyancing": { "type": "money", "value": "<initial>" },
    "lender_application_fee": { "type": "money", "value": "<initial>" },
    "mortgage_registration_fee": { "type": "money", "value": "<initial>" },
    "title_transfer_fee": { "type": "money", "value": "<initial>" },
    "first_year_building_insurance": { "type": "money", "value": "<initial>" },
    "first_year_landlord_insurance": { "type": "money", "value": "<initial>" },
    "quantity_surveyor_report": { "type": "money", "value": "<from_tax_structure>" }
  },
  "entity_setup_costs": {
    "applicable": { "type": "bool", "value": "<initial>", "derived_from": "tax_optimised_structure.recommended_entity" },
    "trust_setup_or_company_incorporation": { "type": "money", "value": "<initial>" },
    "smsf_setup_if_applicable": { "type": "money", "value": 0 }
  },
  "lmi_if_lvr_above_80": {
    "applicable": { "type": "bool", "value": "<initial>" },
    "estimated_amount": { "type": "money", "value": "<initial>" }
  },
  "reserve_buffer": {
    "months_of_repayments_recommended": { "type": "integer", "value": 6, "note": "Higher than Mode A — investment property carries vacancy risk" },
    "amount": { "type": "money", "value": "<initial>" }
  },
  "totals": {
    "total_cash_required_at_settlement": { "type": "money", "value": "<initial>" },
    "cash_available_blended": { "type": "money", "value": "<initial>" },
    "cash_gap_or_surplus": { "type": "money", "value": "<initial>" },
    "verdict": { "type": "enum", "options": ["surplus", "tight", "short"], "value": "<initial>" }
  }
}
```

**Outcome schema:** `budget_envelope_investor`

```jsonc
{
  "type": "budget_envelope_investor",
  "fields": {
    "max_property_price_supported": "money",
    "actual_property_price": "money",
    "total_cash_required": "money",
    "loan_amount": "money",
    "lvr": "percentage",
    "lmi_payable": "money",
    "gap_or_surplus": "money",
    "verdict": "enum",
    "mitigation_options_if_short": "array<string>",
    "cash_events": "array<{ id: string, phase: enum [contract, settle], label: localized_text, direction: 'out', amount: money_range, is_estimate: bool, timing: 'one_off', period: null, counterparty: string, source_component: 'cash_position' }>"  // the investor ACQUISITION spine (RESOLVED 2026-07-10, task 4) — deposit (contract, counterparty services), stamp_duty (settle, government), other_buying_costs (settle, services), lmi (settle, lender); a scalar figure collapses to [v,v]. entity_setup_costs is NOT yet an event (the underlying tax_optimised_structure.setup_costs figure is permanently null — a separate, still-open entity-cost seam). Implemented by `fh_engine_cash:cash_events_investor/4`; purchase_journey's generic multi-source harvest places these on the swimlane
  }
}
```

---

### 8. buying_strategy (investor tactics)

**Goal:** Produce a bid plan with *investor discipline* — strict adherence to thesis-aligned price, less emotional flex than FHB.

**Inputs:** `property_fit_investor.outcome` + `budget_envelope_investor` + `strategy_thesis`

**KB anchors:** Mode A buying_strategy anchors + `kb.investor.bid-discipline`, `kb.investor.yield-anchored-pricing`

**Renderer:** `buying-strategy-card`

**UI tab hint:** Buying

**Parameters:**

Same as [Mode A buying_strategy](fhb-domestic-au.md#6-buying_strategy) with these adjustments:

```jsonc
{
  // all Mode A parameters, plus:
  "investor_anchoring": {
    "yield_anchored_max_price": { "type": "money", "value": "<initial>", "note": "Calculated from target_yield × annual_rent / 100" },
    "thesis_alignment_check": { "type": "enum", "options": ["aligned", "stretched", "misaligned"], "value": "<initial>" },
    "walk_away_more_strictly_enforced": { "type": "bool", "value": true, "note": "Investor discipline: don't chase property above yield-anchored max" }
  },
  "negotiation_style": {
    "recommended_style": { "type": "enum", "options": ["assertive", "patient", "early_offer", "low_anchor", "thesis_walk_away"], "value": "<initial>", "agent_reasoning_required": true, "reasoning_domain": "negotiation" }
  },
  "conditions_to_include_in_offer": {
    "subject_to_finance": { "type": "bool", "value": true },
    "subject_to_building_pest": { "type": "bool", "value": true },
    "subject_to_satisfactory_strata_report": { "type": "bool", "value": "<initial>" },
    "subject_to_satisfactory_rental_appraisal": { "type": "bool", "value": true },
    "other_special_conditions": { "type": "array<string>", "value": [] }
  }
}
```

**Outcome schema:** `bid_plan_investor` (Mode A `bid_plan` + the two investor fields `yield_anchored_max_price` and `thesis_alignment`)

```jsonc
{
  "type": "bid_plan_investor",
  "fields": {
    // --- the investor-specific yield discipline (resolver; removed from the LLM's reach) ---
    "yield_anchored_max_price": "money_range",   // = annual_rent × 100 ÷ target_gross_yield; a BAND because rent is a band (Slice B0 convention)
    "thesis_alignment": "enum",                  // actual price vs the anchored band → aligned | stretched | misaligned

    // --- Mode A bid_plan fields, investor-typed ---
    "max_bid_value": "money_range",              // = the yield-anchored band (the discipline line, NOT "bid this"); resolver
    "max_bid_confidence": "percentage_0_100",    // honest-partial null (needs market depth not wired)
    "max_bid_reasoning": "localized_text",       // bilingual yield-anchor frame via kb.copy.buying-strategy (no English literal in code)
    "walk_away_price": "money_range",            // = the yield-anchored band (walk away above it); resolver
    "negotiation_style": "enum",                 // the ONE agent leaf (reasoning_domain: negotiation)
    "live_coach_armed": "bool",                  // false (live-coach feature not built)
    "conditions_to_request": "array<localized_text>",  // standard investor offer conditions, bilingual via kb.copy
    "red_flags_to_monitor": "array<localized_text>"    // PLACED from property_fit_investor.key_concerns (already {vi,en}) — place-don't-recompute
  }
}
```

> **The figure posture (§98, [[verify-regulated-figures-by-postcondition]]).** Every money figure here is **resolver-computed and removed from the LLM's reach** — the agent's output schema (`NegotiationLeaves`) carries only `recommended_style`, so it has no slot for a price. `max_bid_value`/`walk_away_price` are the *yield-anchored discipline line* (the price at which the property meets the investor's target gross yield), not an instruction to bid; they are surfaced as **bands** because the rent input is a band. Property price is **not** a financial product (the ASIC/AFSL personal-liability line governs the finance/credit side — `mortgage_finance`/`eligibility`); the relevant constraint here is ACL misleading-conduct, met by computing from KB methodology + the bilingual decision-support framing. `buying_strategy` is nonetheless marked `advice_adjacent` (→ ASIC `boundary_held`) as a consistent decision-support hedge.

---

### 9. due_diligence (investor focus)

**Goal:** Surface document risks *plus rental market validation and depreciation report procurement*.

**Inputs:** `property_fit_investor.outcome` + uploaded documents

**KB anchors:** `kb.investor.rental-appraisal-from-pm-agent`, `kb.investor.depreciation-report-quantity-surveyor`, `kb.investor.tenancy-in-situ-considerations`, `kb.copy.due-diligence` (the document-risk anchors — building/pest, strata records, conveyancing review — activate with the upload pipeline: due_diligence B)

**Renderer:** `risk-flag-list` + `checklist`

**UI tab hint:** Property

**Parameters:**

Same as [Mode A due_diligence](fhb-domestic-au.md#7-due_diligence) with these additions:

```jsonc
{
  // all Mode A document categories, plus:
  "investor_specific_documents": {
    "rental_appraisal_from_pm_agent": { "required": true, "received": "<initial>", "reviewed": "<initial>" },
    "depreciation_schedule_quote_from_quantity_surveyor": { "required": true, "received": "<initial>", "reviewed": "<initial>" },
    "current_tenancy_lease_if_tenanted": { "required": "<initial>", "received": "<initial>", "reviewed": "<initial>" },
    "rental_history_last_2_years": { "required": "<initial>", "received": "<initial>", "reviewed": "<initial>" }
  },
  "investor_specific_flags": {
    "rental_appraisal_significantly_below_expectation": { "type": "bool", "value": "<initial>" },
    // lease interpretation (due_diligence B, BUILT 2026-06-27): the lease_interpretation agent leaf
    // reads the UPLOADED lease (the `<from_document>` upload pipeline — DocumentUpload → inline
    // base64 → the engine `document` turn, bytes transient/never persisted) and authors the
    // qualitative tenancy-risk judgment grounded in kb.investor.tenancy-in-situ-considerations. The
    // marker makes the component two-path-CAPABLE; the turn fires the sidecar ONLY when a lease is
    // present (effective_fill_path/2) — a plain property attach with no lease stays resolver-only at
    // A (honest-partial, no LLM call), so "resolver-only at A" still holds for the no-lease path.
    "current_tenancy_unfavourable_terms": { "type": "array<string>", "value": [], "agent_reasoning_required": true, "reasoning_domain": "lease_interpretation" },
    "rental_yield_below_thesis_threshold": { "type": "bool", "value": "<initial>" }
  }
}
```

**Outcome schema:** `risk_assessment_investor`

```jsonc
{
  "type": "risk_assessment_investor",
  "fields": {
    // honest-partial signal. `pending_upload` until the user supplies the due-diligence documents
    // (rental appraisal, depreciation quote, lease) — the upload pipeline is NOT built (CLAUDE.md
    // item 9; the only Phase-B input today is the source-supplied property_card of neutral property
    // facts, not the user's uploaded documents). `reviewed` once documents are uploaded + assessed →
    // the document-risk surfacing (high_severity_flags, the negotiation lever, the lease-interpretation
    // agent leaf) lights up. Deferred to a separate cross-contract unit (mode-c-wedge.md "due_diligence B").
    "docs_status": "enum: pending_upload | reviewed",
    // overall risk verdict. `pending_documents` until docs are uploaded; the substantive verdicts (B).
    "overall_verdict": "enum: pending_documents | low_risk | proceed_with_actions | high_risk",
    // the investor document PROCUREMENT checklist (KB-grounded, property-generic): what an investor
    // must gather (rental appraisal, depreciation quote, lease-if-tenanted, rental history). required +
    // why are known now; received/reviewed false until the upload pipeline (B).
    "document_checklist": "array<{ id, name: localized_text, required: bool, received: bool, reviewed: bool, why: localized_text }>",
    // the COMPUTABLE investor risk flag: property_fit_investor.rental_yield_gross_estimate <
    // strategy_thesis.target_gross_yield. resolver-computed, removed from the LLM's reach (§8.5).
    // null until both inputs exist (needs the per-property yield AND the strategy target).
    "rental_yield_below_thesis_threshold": "bool | null",
    // surfaced investor concerns (risk-flag-list renderer). At A: the yield-below-thesis concern if it
    // fires. The document-derived concerns (appraisal below expectation, unfavourable tenancy) follow in B.
    "investor_specific_concerns": "array<{ id, severity: enum, detail: localized_text }>",
    // due-diligence ACTIONS the buyer should take before signing — bilingual, investor-generic (A).
    "actions_before_signing": "array<localized_text>",
    // questions to ask the vendor / agent — bilingual, investor-generic (A).
    "questions_for_vendor": "array<localized_text>",
    // high-severity flags EXTRACTED from uploaded documents — [] until the upload pipeline (B).
    "high_severity_flags": "array<{ source_doc, item: localized_text, action: localized_text }>",
    // a negotiation lever estimated from document findings — null until documents reviewed (B).
    "estimated_negotiation_lever": "money_range | null",
    // honest: upload the due-diligence documents to complete the assessment (A).
    "next_action_for_user": "localized_text"
  }
}
```

**Fill-path / honest-partial posture.** `due_diligence` is **document-gated two-path** (due_diligence B,
BUILT 2026-06-27). Its one agent leaf — `investor_specific_flags.current_tenancy_unfavourable_terms`,
`reasoning_domain: lease_interpretation` — reads the *uploaded lease*, so the turn fires the sidecar
ONLY when a lease is present (`effective_fill_path/2`): a plain property attach with no lease runs
**resolver-only** (honest-partial, no LLM), and an uploaded lease (the `<from_document>` upload
pipeline — DocumentUpload → inline base64 → the engine `document` turn; bytes transient, never
persisted) runs the leaf, which authors the qualitative tenancy-risk judgment (the
lease-interpretation concern, the high-severity lease flags, the `overall_verdict`) grounded in
`kb.investor.tenancy-in-situ-considerations`. `merge_agent` folds them, flips `docs_status` →
`reviewed` (the non-null `overall_verdict` is the durable reviewed signal, recovered on refresh by
`agent_values_from_outcome`), and flips the lease checklist entry. The `estimated_negotiation_lever`
(money) stays resolver/`null` — no KB methodology computes a lever from lease terms (honest-partial),
and no figure is ever agent-authored (§98). The non-lease document risks (building/pest/strata —
`document_significance`, Mode A) remain a later input surface. So this component fills the **knowable
structure now** — the investor document *procurement* checklist (what to gather + why),
the bilingual due-diligence actions + vendor questions, and the **computable** `rental_yield_below_thesis_threshold`
flag (the per-property yield vs the strategy target, removed from the LLM's reach) — and marks the
document-dependent fields PENDING (`docs_status: pending_upload`, `overall_verdict: pending_documents`,
`high_severity_flags []`, `estimated_negotiation_lever null`), never fabricating a finding. The thesis
flag needs `strategy_thesis.target_gross_yield`, so `strategy_thesis` is declared a `due_diligence`
input (DAG reads below) — without it the component's most distinctive output would be silently null.

---

### 10. settlement_prep (similar to Mode A + entity setup)

**Goal:** Coordinate settlement *with entity setup, depreciation schedule procurement, property management appointment*.

**Inputs:** `property_fit_investor.outcome` + `bid_plan_investor` + `tax_optimised_structure`

**KB anchors:** `kb.settlement.process-by-state`, `kb.insurance.timing-of-risk-pass`, `kb.copy.settlement`, `kb.investor.entity-setup-timeline`, `kb.investor.depreciation-schedule-procurement`, `kb.investor.property-management-appointment-timeline` (the date-arithmetic anchors `kb.cooling-off.by-state`, `kb.pexa.settlement`, `kb.lender-docs.standard-timeline` power the dated path once contract dates are supplied — settlement_prep B, engine-contract §11)

**Renderer:** `swimlane-diagram` + `checklist`

**UI tab hint:** Temporal flow

**Parameters:**

Same as [Mode A settlement_prep](fhb-domestic-au.md#8-settlement_prep) with these additions:

```jsonc
{
  // user-attested transaction facts — the `<from_transaction>` input layer (architecture §11.9;
  // engine-contract §11). Supplied POST-ATTACH via the transaction submit, NOT a property fact and
  // NOT document-extracted. Present → the dated critical path activates (dates_status: active, the
  // milestone due-dates back-calculated from settlement_date via the date-arithmetic anchors); absent
  // → dates_status: pending_contract (honest-partial). Resolver-path (no agent_reasoning_required).
  "contract_dates": {
    "contract_signed_date": { "type": "date", "value": "<from_transaction>" },
    "settlement_date":      { "type": "date", "value": "<from_transaction>" }
  },
  // all Mode A milestones, plus:
  "investor_specific_milestones": {
    "entity_setup_completed_if_applicable": { "type": "milestone", "value": { "status": "<initial>", "due_date": "<initial>" } },
    "quantity_surveyor_engaged": { "type": "milestone", "value": { "status": "<initial>", "due_date": "<initial>" } },
    "depreciation_schedule_received": { "type": "milestone", "value": { "status": "<initial>", "due_date": "<initial>" } },
    "property_management_appointed": { "type": "milestone", "value": { "status": "<initial>", "due_date": "<initial>" } },
    "landlord_insurance_bound": { "type": "milestone", "value": { "status": "<initial>", "due_date": "<initial>" } }
  }
}
```

**Outcome schema:** `settlement_checklist`

```jsonc
{
  "type": "settlement_checklist",
  "fields": {
    // honest-partial signal. `pending_contract` until the user supplies the signed-contract dates
    // (contract_signed_date + settlement_date — a per-property transaction-input surface, NOT a
    // property fact; supplied via the transaction submit, engine-contract §11 / `<from_transaction>`).
    // `active` once dates exist → the dated critical path + at-risk detection + swimlane light up.
    "dates_status": "enum: pending_contract | active",
    "settlement_date": "date | null",                                   // PENDING until contract dates supplied
    // the standard settlement milestone sequence + dependency DAG (KB-grounded, property-generic).
    // due_date null + status `pending` until dates_status=active.
    "critical_path_milestones": "array<{ id, name: localized_text, due_date: date | null, status, dependency: id | null }>",
    // investor-specific milestones. entity-setup is CONDITIONED on upstream: applicable iff
    // tax_optimised_structure.recommended_entity requires establishing a legal entity (∉
    // {personal_sole, joint, null}). QS engagement, depreciation schedule, PM appointment and
    // landlord insurance are always-applicable for an investor (whether depreciation is claimable
    // is a QS judgment, surfaced in `why` — not pre-decided from build-year, which we don't carry).
    "investor_milestones": "array<{ id, name: localized_text, applicable: bool, why: localized_text, due_date: date | null, status }>",
    // state-conditional building-insurance timing RULE (resolver-selected from
    // kb.insurance.timing-of-risk-pass.risk_passing_by_state: QLD → day after contract; NSW/VIC →
    // settlement). The RULE is knowable without dates; the dated milestone is part of B.
    "insurance_timing_rule": "localized_text | null",
    "at_risk_milestones": "array<{ name, reason }>",                     // [] until dates_status=active
    "next_action_for_user": "localized_text"                            // honest: supply contract dates to activate
  }
}
```

**Fill-path / honest-partial posture.** `settlement_prep` is **resolver-only** (zero agent leaves
per the Fill-path classification note below; no `reasoning_domain`). Its defining
output — the *dated* settlement critical path with at-risk detection — depends on
`contract_signed_date` + `settlement_date`. These arrive via **`<from_transaction>`** — facts the
user **attests** about their transaction (engine-contract §11), the *light* input surface built as
**settlement_prep B** (the same dates may *later* also be extracted via `<from_document>` from the
uploaded signed contract — the heavier upload pipeline, architecture §11.10; one fact layer, two
mechanisms). **Two states, one resolver:**
- **Dates absent** → the **knowable structure now**: the milestone sequence + dependency DAG, the
  upstream-conditioned investor milestones, and the state-conditional insurance-timing *rule*, with
  every date PENDING (`dates_status: pending_contract`), never fabricating a date.
- **Dates present** (a `<from_transaction>` submit) → `dates_status: active`: the milestone due-dates
  **back-calculated from `settlement_date`** via `kb.cooling-off.by-state` + `kb.pexa.settlement` +
  `kb.lender-docs.standard-timeline`, the dated swimlane, and **at-risk detection** (a milestone whose
  computed due-date is past / too close to today). Still resolver-only — a transaction submit is a
  **resolver-only turn** (no `usage`, engine-contract §11).

This resolver is also the **state-conditional building-insurance fix** flagged in
`kb.insurance.timing-of-risk-pass` (the blueprint's single `derived_from: settlement_date` hint is
wrong for QLD).

---

### 11. ownership_planning_investor (replaces Mode A ownership_planning)

**Goal:** Plan ongoing investment operations — property management, tax reporting, cash flow tracking, portfolio review, scale-up planning.

**Inputs:** `property_fit_investor.outcome` + `tax_optimised_structure` + `cash_flow_projection`

**KB anchors:** `kb.investor.property-management-vs-self-managed`, `kb.investor.annual-tax-return-investor`, `kb.investor.cash-flow-tracking`, `kb.investor.portfolio-review-cadence`, `kb.investor.scale-up-using-equity`, `kb.investor.land-tax-aggregation`

**Renderer:** `data-table` + `opportunity-card`

**UI tab hint:** Portfolio

**Parameters:**

```jsonc
{
  "property_management": {
    "management_mode": { "type": "enum", "options": ["self_managed", "professional_pm", "hybrid"], "value": "<initial>" },
    "pm_agent_appointed": { "type": "string", "value": "<initial>" },
    "pm_fee_percentage": { "type": "percentage", "value": 7.5 },
    "letting_fee": { "type": "money", "value": "<initial>" }
  },
  "annual_obligations": {
    "tax_return_due_date": { "type": "date_recurring_annual", "value": "<initial>" },
    "land_tax_assessment_received_date": { "type": "date_recurring_annual", "value": "<initial>" },
    "depreciation_schedule_refresh_if_renovated": { "type": "bool", "value": "<initial>" },
    "annual_pm_review": { "type": "date_recurring_annual", "value": "<initial>" }
  },
  "quarterly_obligations": {
    "council_rates": { "type": "money_per_quarter", "value": "<initial>" },
    "water_rates": { "type": "money_per_quarter", "value": "<initial>" },
    "body_corporate_levies": { "type": "money_per_quarter", "value": "<initial>", "applicable": "<initial>" }
  },
  "cash_flow_tracking": {
    "monthly_net_cash_flow_actual_vs_projected": { "type": "comparison", "value": "<initial>" },
    "vacancy_events_to_date": { "type": "array<{ start, end, weeks }>", "value": [] },
    "maintenance_events_to_date": { "type": "array<{ date, cost, category }>", "value": [] },
    "cumulative_cash_flow_year_to_date": { "type": "money", "value": 0 }
  },
  "portfolio_position": {
    "equity_built_in_this_property": { "type": "money", "value": "<initial>" },
    "lvr_current": { "type": "percentage", "value": "<initial>" },
    "valuation_review_cadence_months": { "type": "integer", "value": 24 },
    "ready_for_next_property_at_lvr": { "type": "percentage", "value": 70 }
  },
  "scale_up_planning": {
    "next_property_target_date": { "type": "date", "value": "<initial>" },
    "equity_release_required_for_next": { "type": "money", "value": "<initial>" },
    "portfolio_diversification_strategy": { "type": "enum", "options": ["same_location_scale", "different_state_diversify", "different_property_type", "commercial_pivot"], "value": "<initial>" }
  },
  "lifecycle_alerts": {
    "rent_review_window_yearly": { "type": "bool", "value": true },
    "refi_review_cadence_months": { "type": "integer", "value": 24 },
    "depreciation_schedule_aging_alert": { "type": "bool", "value": true },
    "land_tax_aggregation_warning": { "type": "bool", "value": "<initial>", "note": "Trigger when aggregated land value exceeds state threshold" }
  }
}
```

**Outcome schema:** `portfolio_position`

```jsonc
{
  "type": "portfolio_position",
  "fields": {
    "monthly_net_cash_flow_actual": "money",
    "ytd_cash_flow_vs_projection": "comparison",
    "current_lvr": "percentage",
    "equity_built": "money",
    "ready_for_next_property": "bool",
    "alert_triggers_armed": "array<{ trigger, action }>",
    "annual_tax_obligations": "array<localized_text>",  // user-facing prose → bilingual {vi,en}, validator-enforced (matches disposition.key_assumptions)
    "portfolio_diversification_score": "integer_0_10",
    "opportunities": "array<{ kind, modeled_benefit, action }>"  // the opportunity-card surface (§11.9). [] at base. PER-PROPERTY + figure-bearing: emitted only when a figure off THIS property exists (never padding the property-agnostic alert_triggers_armed). At attach the one such figure is kind=equity_release — releasable equity projected at the hold horizon, modeled_benefit a resolver money band placed from disposition.sale_proceeds/loan_payout; [] when no hold horizon is set. kind ∈ {equity_release, rent_review, scale_up}: rent_review (in-place-vs-market gap, needs the lease → due_diligence B) and scale_up (readiness, needs post-settlement actuals) stay in the enum, deferred honest-partial. modeled_benefit is removed from the LLM's reach (resolver-computed band). Both halves of the seam are now built: producer = fh_engine_ownership:fill_investor/2; consumer reached via the renderers[] carry (engine-contract §4).
  }
}
```

---

### 12. disposition (NEW — the dispose-phase figure-owner)

> **Design-first / dormant.** Added by the full-temporal-flow reframe ([`../architecture/lifecycle-simulation-model.md` §8.5](../architecture/lifecycle-simulation-model.md)). The *structure* (this component, the `dispose` phase, the full-horizon spine) is built across all modes now; the **Mode-C investor tax content** — negative gearing, the CGT 50% discount, depreciation clawback — is authored when Mode C enters scope, against the currently-dangling `kb.tax.*` anchors (§8.7, the worked "kind-3" instance of the kb-update-runbook Phase-0 classifier). Mode-A's `disposition` ([`fhb-domestic-au.md`](fhb-domestic-au.md) component 13) is the same shape on the *main-residence-exempt* path (`cgt: null`); this is the same shape on the **full-CGT** path.

**Goal:** Project the position at sale over the hold horizon `H` and own the dispose-phase figures the old `cgt_projection` placeholder lacked a home for: sale proceeds (growth-projected), selling costs, loan payout, and **CGT** (taxable gain after the 50% discount and depreciation clawback, at the marginal rate). Roll the acquire and hold flows up into a **full-horizon net position** — the investor's core *"over buy → hold → sell, where do I stand?"* question.

**Inputs:** `strategy_thesis` (`hold_period_years` = the horizon `H`, `exit_strategy`) + `property_fit_investor.outcome` (growth indicators, purchase price) + `cash_flow_projection` (yield_modelling — the hold-phase recurring flows to roll up) + `tax_optimised_structure` (tax_structure — the **CGT determinants**: `cgt_discount_eligible`, `cgt_marginal_rate`, `cost_base_depreciation_clawback`) + `budget_envelope_investor` (cash_position — acquisition cash to roll up; loan amount for the payout)

**KB anchors:** `kb.property.capital-growth-bands` (the banded growth assumption — **labelled placeholder**, re-ground before surfacing), `kb.selling-costs.agent-legal` (selling-cost bands), `kb.tax.cgt-50-percent-discount` *(dangling — Mode-C, design-first)*, `kb.tax.depreciation-division-43-and-40` *(dangling — the cost-base clawback, design-first)*

**Renderer:** `calculator` (the full-horizon net position; no new renderer — constraint #7, §8.8)

**Fill path:** **resolver, no agent leaf.** Growth/selling-costs/CGT are KB-grounded resolver computations, never LLM-paraphrased — the figures are removed from the agent's reach ([verify-regulated-figures-by-postcondition], [no-judge-ground-the-producer]). Banded and PENDING when the growth assumption is unparameterized (honest-partial).

**Parameters:**

```jsonc
{
  "horizon": {
    "hold_horizon_years": { "type": "integer", "value": "<from strategy_thesis.hold_period_years>", "note": "the §8.3 horizon H; a structural what-if (simulate/refine override on the plan-target overlay), not an agent leaf" }
  },
  "growth_assumption": {
    "capital_growth_band_pct_pa": { "type": "percentage_range", "value": "<from kb.property.capital-growth-bands>", "note": "PLACEHOLDER band — re-ground vs ABS RPPI / CoreLogic / Valuer-General before any figure is surfaced; banded, honest-partial" }
  },
  "cgt": {
    "50_percent_discount_applied": { "type": "bool", "value": "<from tax_structure.cgt_determinants>", "note": "true if held >12 months — read from tax_structure, not re-derived" },
    "marginal_rate": { "type": "percentage", "value": "<from tax_structure.cgt_determinants>" },
    "cost_base_depreciation_clawback_applied": { "type": "bool", "value": "<from tax_structure.cgt_determinants>" }
  }
}
```

**Outcome schema:** `disposition`

```jsonc
{
  "type": "disposition",
  "fields": {
    "horizon_years": "integer",                       // the hold H this projection assumes
    "sale_proceeds": "money_range",                    // purchase_price grown over H by the banded assumption; PENDING when unparameterized
    "selling_costs": "money_range",                    // agent commission + legal/marketing at sale
    "loan_payout": "money_range",                      // remaining principal discharged at settlement of sale
    "taxable_gain": "money_range",                     // (proceeds − adjusted cost base) × (1 − discount); cost base reduced by Div 43 clawback
    "cgt": "money_range",                              // taxable_gain × marginal_rate — the investor path computes it (NOT null/exempt, unlike Mode A's main residence)
    "cgt_status": "enum [computed, to_verify]",        // computed from KB determinants; to_verify = surfaced for a registered tax agent (never asserted as advice)
    "net_proceeds": "money_range",                     // sale_proceeds − selling_costs − loan_payout − cgt
    "full_horizon_net_position": "money_range",        // acquire (from budget_envelope_investor) + hold net over H (from cash_flow_projection) + dispose net_proceeds
    "dispose_cash_events": "array<{ phase: 'dispose', timing: 'one_off', direction, amount, counterparty, source_component: 'disposition' }>",
    "key_assumptions": "array<localized_text>"         // the growth band, the held period, the discount basis, the clawback — each labelled as estimate/regulated
  }
}
```

- **One-computer-per-figure.** `disposition` owns these dispose figures + the full-horizon roll-up; it **places** acquire (from `cash_position`) and hold (from `yield_modelling`/`tax_structure` over `H`) figures, never recomputing them ([place-upstream-figures-dont-recompute]). It emits the dispose-phase `cash_events`, gated by §13 placement/provenance.
- **ASIC.** CGT and growth are KB-grounded estimates surfaced as ranges with the basis stated, with `cgt_status: to_verify` directing the user to a registered tax agent — decision support, never tax advice (the §1018 disclaimer covers it).

---

### 13. purchase_journey (NEW — the whole-of-journey lifecycle swimlane)

> **Added 2026-07-10** (the B/C/D lifecycle-spine restructure, `plan-card-lifecycle-restoration.md` §11, task 4). Same shape as Mode A's `purchase_journey` ([`fhb-domestic-au.md`](fhb-domestic-au.md) component 10) — the `journey_swimlane` outcome type and the `swimlane-diagram` renderer are mode-general and reused unchanged; only the KB content and the actor set differ.

**Goal:** Present the whole-of-journey lifecycle as a swimlane — the phases of an investor purchase across time (Prepare → Pre-approve → Contract → Settle → Hold → **Dispose**) against the actors who act in each (You / Government / Lender / **Property manager** / **Tenant** / Services), with the buyer's already-computed money flows placed on the timeline. Six actor rows, not Mode A's four — a landlord relationship has two real, actor-attributable cash-flow counterparties (the tenant paying rent, the property manager collecting the management fee) that a generic "Other" row would blur (`kb.journey.investor-path`'s own rationale). The `own` phase is labelled "Hold" (tenanted, not lived in) but keeps the `own` phase id, matching `yield_modelling`/`tax_structure`'s own outcome text.

**Scope:** `base` — the journey structure is generic to a Mode-C investor purchase; it does not depend on a specific property.

**Inputs:** `cash_position.outcome` (`budget_envelope_investor`, incl. its `cash_events`) + `yield_modelling.outcome` (`cash_flow_projection`, incl. its `cash_events`) + `tax_structure.outcome` (`tax_optimised_structure`, incl. its `cash_events`) + `disposition.outcome` (the Dispose-phase `dispose_cash_events`). It runs **last** so it can place figures every upstream component already computed — it computes **no figure of its own**. Unlike Mode A (one acquisition-spine source), Mode C harvests `cash_events` from **three** upstream outcomes (`fh_engine_journey:harvest_cash_events/1`, a generic multi-source concatenation — not a Mode-C-specific read).

**KB anchors:** `kb.journey.investor-path`

**Renderer:** `swimlane-diagram`

**UI tab hint:** Flow (leads the tab; folds into the restructure's five-view spine, §5 above — not yet rewritten, tracked in `wedge-build-sequence.md`)

**Fill path:** resolver. The journey structure + bilingual cell prose are generic KB content (`kb.journey.investor-path`); the figures are upstream outcomes placed on the timeline. No agent leaf.

**Outcome schema:** `journey_swimlane` — same shape as Mode A's (`fhb-domestic-au.md` component 10); the compiler parses the fenced block per-blueprint (it does not inherit across files), so it is repeated below rather than only cross-referenced. `actors` carries six entries (`you`, `government`, `lender`, `property_manager`, `tenant`, `services`) instead of Mode A's four.

```jsonc
{
  "type": "journey_swimlane",
  "fields": {
    "phases": "array<{ id: string, label: localized_text }>",   // ordered lifecycle phases (prepare → pre_approve → contract → settle → own → dispose); own is labelled 'Hold' (tenanted) but keeps the own phase id, matching yield_modelling/tax_structure's own outcome text. The terminal dispose phase is present only when a hold horizon H is set.
    "actors": "array<{ id: string, label: localized_text }>",   // the swimlane rows: you / government / lender / property_manager / tenant / services — six, not Mode A's four, since a landlord relationship has two real actor-attributable cash-flow counterparties (kb.journey.investor-path's own rationale)
    "cells": "array<{ phase: string, actor: string, item: localized_text, flow_marker: enum [none, money_out, money_in, document, milestone], amount: money_range, counterparty: string|null, source_component: string }>",  // one action per (phase, actor) that has one; amount is an upstream figure PLACED on the timeline — NEVER computed here. source_component traces the cell to the figure's owner (cash_position / yield_modelling / tax_structure / disposition) for the outcome-conformance gate.
    "interactions": "array<{ from_actor: string, to_actor: string, phase: string, flows: array<{ label: localized_text, direction: enum [out, in], amount: money_range }> }>",  // the who-pays/talks-to-whom view, derived by PLACEMENT from the same cash_events, not recomputed
    "key_assumptions": "array<localized_text>"
  }
}
```

---

### 14. phase_playbook (NEW — the actionable per-phase checklist + risks)

> **Added 2026-07-10**, same restructure. Same schema + renderers as Mode A's `phase_playbook` ([`fhb-domestic-au.md`](fhb-domestic-au.md) component 12); only the KB content differs.

**Goal:** Behind each Flow-view phase sheet, present the actionable, temporally-ordered checklist for that phase and the often-seen risks + mitigations — investor-specific (entity setup, serviceability haircut, negative-gearing-reform exposure, CGT-on-sale risk) rather than Mode A's FHB content.

**Scope:** `base` — phase-keyed, property-agnostic. Per-property components (`property_assessment`, `buying_strategy`, `due_diligence`, `settlement_prep`) enrich a phase via their own outcomes, reached through an action's `component_ref`; `phase_playbook` itself stays base.

**Inputs:** `cash_position.outcome` + `yield_modelling.outcome` + `tax_structure.outcome` (so each action's `budget_ref` resolves to a real `cash_event.id` — harvested the same way `purchase_journey` harvests them, `fh_engine_phase_playbook:harvest_cash_events/1`) + `purchase_journey.outcome` (to share the phase set). Runs **last** (after `purchase_journey`).

**KB anchors:** `kb.journey.investor-phase-actions`, `kb.risks.investor-by-phase`

**Renderer:** `checklist` + `risk-flag-list`

**UI tab hint:** Flow (the per-phase drill-down sheet)

**Fill path:** resolver. Actions, ordering, risks, and mitigations are bilingual KB content keyed by phase; the only upstream read is `cash_event.id` resolution for `budget_ref`. No agent leaf — the risks are KB-grounded, never LLM-generated.

**Outcome schema:** `phase_playbook` — identical shape to Mode A's (`fhb-domestic-au.md` component 12); repeated below since the compiler parses this fenced block per-blueprint, not by cross-reference.

```jsonc
{
  "type": "phase_playbook",
  "fields": {
    "phases": "array<{ phase: string, actions: array<{ id: string, label: localized_text, detail: localized_text, order: integer, budget_ref: string|null, component_ref: string|null, status: enum [not_started, done] }>, risks: array<{ severity: enum [low, medium, high], item: localized_text, action: localized_text }> }>",
    // one entry per lifecycle phase (prepare → pre_approve → contract → settle → own → dispose); phase ids align with purchase_journey.phases + cash_event.phase.
    //   ACTION: order = temporal sequence within the phase. budget_ref → a cash_event.id (harvested off cash_position/yield_modelling/tax_structure; null when no cash consequence). component_ref → a component id (e.g. tax_structure behind 'Lodge annual return'; null when none). status is USER-ATTESTED via the §10.4 toggle-write, overlaid at read.
    //   RISK: item = the risk; action = the mitigation. KB-grounded (kb.risks.investor-by-phase), never generated. Honest-partial: a phase with no substantiated risk emits NO risk.
    "key_assumptions": "array<localized_text>"
  }
}
```

---

## KB anchor index (for this blueprint)

58 slugs referenced (corrected 2026-07-10 — a stale count; the table itself was already larger than the previously-stated "42" before this pass's three additions). Italics mark Mode C-only anchors (not in Mode A FHB); the two growth/selling-cost anchors at component 12 are **shared with Mode A** (non-italic).

| Slug | Component(s) | Owns |
|---|---|---|
| `kb.tax.income-tax-resident-2026-27` | 1 | Resident income-tax brackets + marginal rates (shared with Mode A) |
| *`kb.lender.serviceability-investment-loans`* | 1, 4 | Investment-loan serviceability assessment (approx borrowing capacity) |
| *`kb.investor.experience-levels`* | 1 | How investor experience affects lender treatment |
| `kb.property.suburb-risk-factors` | 2 | Suburb risk factors |
| `kb.property.comparables-methodology` | 2 | Comparable sales methodology |
| *`kb.property.rental-market-data-sources`* | 2 | Where to source rental market data (CoreLogic, REA Insights, etc.) |
| *`kb.property.growth-corridors-au`* | 2 | Australian growth corridor analysis methodology |
| *`kb.property.depreciation-by-build-year`* | 2 | Build-year implications for depreciation eligibility |
| *`kb.property.investor-grade-features`* | 2 | Features that make property investor-grade |
| *`kb.strata.health-indicators-investor-lens`* | 2 | Strata health from investor perspective |
| *`kb.investor.strategy-archetypes`* | 3 | Investment strategy archetypes (cash flow, growth, balanced, etc.) |
| *`kb.investor.gearing-types-and-implications`* | 3 | Positive / neutral / negative gearing |
| *`kb.investor.hold-period-considerations`* | 3 | Hold period strategy |
| *`kb.investor.exit-strategy-options`* | 3 | Exit strategy options for investors |
| *`kb.investor.rental-income-modelling`* | 4 | Rental income modelling methodology |
| *`kb.investor.operating-expenses-typical-ratios`* | 4 | Typical operating expense ratios by property type |
| *`kb.investor.vacancy-rate-assumptions`* | 4 | Vacancy rate assumptions by suburb / property type |
| *`kb.investor.cash-flow-modelling-methodology`* | 4 | Cash flow modelling methodology |
| *`kb.investor.property-management-fees`* | 4, 10 | PM fee structures and benchmarks |
| *`kb.tax.entity-comparison-personal-trust-company-smsf`* | 5 | Entity comparison for property investment |
| *`kb.tax.negative-gearing-mechanics`* | 5 | Negative gearing tax mechanics |
| *`kb.tax.depreciation-division-43-and-40`* | 5, 12 | Capital works (Div 43) and plant & equipment (Div 40) depreciation; the cost-base clawback at disposition |
| *`kb.tax.cgt-50-percent-discount`* | 5, 12 | CGT 50% discount eligibility; the dispose-phase CGT figure at disposition |
| *`kb.tax.quantity-surveyor-reports`* | 5, 6 | Quantity surveyor depreciation reports |
| *`kb.tax.land-tax-by-state`* | 5 | Land tax thresholds and rates by state |
| *`kb.tax.entity-setup-costs`* | 6 | Entity setup cost ranges |
| `kb.stamp-duty.calc-by-state` | 6 | Stamp duty by state |
| *`kb.investor.deposit-requirements-investment-loans`* | 6 | Deposit requirements for investment loans |
| `kb.lmi.calculation` | 6 | LMI calculation |
| *`kb.buyer-costs.investor-additional-costs`* | 6 | Additional costs specific to investors |
| `kb.auction.rules-by-state` | 7 | Auction rules |
| `kb.cooling-off.by-state` | 7, 9 | Cooling-off periods |
| `kb.negotiation.patterns-by-market-condition` | 7 | Negotiation patterns |
| `kb.agent-tactics.detection` | 7 | Agent tactics |
| *`kb.investor.bid-discipline`* | 7 | Investor bidding discipline |
| *`kb.investor.yield-anchored-pricing`* | 7 | Yield-anchored max-price methodology |
| `kb.contract-of-sale.review-points-by-state` | 8 | CoS review |
| `kb.building-pest.interpretation` | 8 | Building / pest report interpretation |
| `kb.strata-report.red-flags` | 8 | Strata red flags |
| *`kb.investor.rental-appraisal-from-pm-agent`* | 8 | Rental appraisal procurement |
| *`kb.investor.depreciation-report-quantity-surveyor`* | 8 | QS depreciation report procurement |
| *`kb.investor.tenancy-in-situ-considerations`* | 8 | Considerations when buying with tenant in place |
| `kb.settlement.process-by-state` | 9 | Settlement process |
| `kb.pexa.settlement` | 9 | PEXA mechanics |
| *`kb.investor.entity-setup-timeline`* | 9 | Entity setup timeline relative to settlement |
| *`kb.investor.depreciation-schedule-procurement`* | 9 | Depreciation schedule procurement workflow |
| *`kb.investor.property-management-appointment-timeline`* | 9 | PM agent appointment workflow |
| *`kb.investor.property-management-vs-self-managed`* | 10 | PM vs self-managed comparison |
| *`kb.investor.annual-tax-return-investor`* | 10 | Annual tax return workflow for investors |
| *`kb.investor.cash-flow-tracking`* | 10 | Cash flow tracking methodology |
| *`kb.investor.portfolio-review-cadence`* | 10 | Portfolio review cadence |
| *`kb.investor.scale-up-using-equity`* | 10 | Equity release for next property |
| *`kb.investor.land-tax-aggregation`* | 10 | Land tax aggregation rules across portfolio |
| `kb.property.capital-growth-bands` | 12 | Banded capital-growth assumption for sale-proceeds projection (**labelled placeholder** — re-ground vs ABS RPPI / CoreLogic / Valuer-General; shared with Mode A) |
| `kb.selling-costs.agent-legal` | 12 | Selling-cost bands — agent commission + legal + marketing at the dispose phase (shared with Mode A) |
| *`kb.journey.investor-path`* | 13 | The whole-of-journey swimlane — six-actor phases × cells, bilingual prose |
| *`kb.journey.investor-phase-actions`* | 14 | Per-phase actionable checklist, bilingual |
| *`kb.risks.investor-by-phase`* | 14 | Per-phase risks + mitigations, bilingual |

---

## Renderer vocabulary used

| Renderer | Used by component(s) |
|---|---|
| `summary-card` | 1 investor_profile, 2 property_assessment, 3 investment_strategy |
| `calculator` | 4 yield_modelling, 5 tax_structure, 6 cash_position, 12 disposition |
| `data-table` | 5 tax_structure, 10 ownership_planning_investor |
| `buying-strategy-card` | 7 buying_strategy |
| `risk-flag-list` | 8 due_diligence, 14 phase_playbook |
| `checklist` | 8 due_diligence, 9 settlement_prep, 14 phase_playbook |
| `swimlane-diagram` | 9 settlement_prep, 13 purchase_journey |
| `opportunity-card` | 10 ownership_planning_investor |

---

## Parameter signal vocabulary

Same as Mode A + B with one Mode C-exclusive addition:

| Signal | Used for |
|---|---|
| `<initial>` | Never-filled |
| `<from_property_card>` | From property selection |
| `<from_investor_profile>` | From `investor_profile.outcome` (Mode C exclusive) |
| `<from_property_assessment>` | From `property_assessment.outcome` |
| `<from_tax_structure>` | From `tax_structure.outcome` (Mode C exclusive) |

**Fill-path classification.** Per [agentic-boundary.md](../architecture/agentic-boundary.md), `agent_reasoning_required: true` marks agent-path leaves; all others resolve deterministically. Mode C agent-path leaves: rent + property valuation (`property_assessment.rental_market.estimated_weekly_rent_range`, `market_position.*`), investment thesis (`investment_strategy.strategy_archetype`, `thesis_one_liner`, `gearing_type`), investor loan structure + lender fit (`mortgage_finance.uses_existing_ppor_equity`, IO/PI, `fixed_vs_variable`, `offset_account_strategy`, `investor_friendly_lender_shortlist`), entity structuring (`tax_structure.recommended_entity`), negotiation style, and lease interpretation (`due_diligence.investor_specific_flags.current_tenancy_unfavourable_terms`). Resolver: all yield/cashflow math, land tax, depreciation predicates, tax-rate lookups, vacancy assumptions, concession eligibility, yield-anchored max price, and **all of `disposition`** (growth projection, selling costs, loan payout, taxable gain, CGT, the full-horizon roll-up — KB-grounded computations deliberately removed from the agent's reach, §8.5).

---

## Cross-component output dependency graph

```
investor_profile         → outcome: profile
property_assessment      → outcome: property_fit_investor      (reads: profile)
investment_strategy      → outcome: strategy_thesis            (reads: profile, property_fit_investor)
yield_modelling          → outcome: cash_flow_projection       (reads: profile, property_fit_investor, strategy_thesis)
tax_structure            → outcome: tax_optimised_structure    (reads: profile, property_fit_investor, cash_flow_projection)
cash_position            → outcome: budget_envelope_investor   (reads: profile, property_fit_investor, tax_optimised_structure)
buying_strategy          → outcome: bid_plan_investor          (reads: property_fit_investor, budget_envelope_investor, strategy_thesis)
due_diligence            → outcome: risk_assessment_investor   (reads: property_fit_investor, strategy_thesis, uploaded_docs)
settlement_prep          → outcome: settlement_checklist       (reads: property_fit_investor, bid_plan_investor, tax_optimised_structure)
disposition              → outcome: disposition              (reads: strategy_thesis, property_fit_investor, cash_flow_projection, tax_optimised_structure, budget_envelope_investor)
ownership_planning_investor → outcome: portfolio_position      (reads: property_fit_investor, tax_optimised_structure, cash_flow_projection, disposition)
purchase_journey          → outcome: journey_swimlane          (reads: budget_envelope_investor, cash_flow_projection, tax_optimised_structure, disposition)   // harvests cash_events off the three figure-owners + dispose_cash_events; places, computes nothing
phase_playbook            → outcome: phase_playbook            (reads: budget_envelope_investor, cash_flow_projection, tax_optimised_structure, journey_swimlane)  // links cash_event.id via budget_ref; runs last
```

No cycles. `tax_structure` is on the critical path because it informs `cash_position` (entity setup costs) and `ownership_planning_investor` (annual compliance). `ownership_planning_investor` runs before the new spine — its `portfolio_position.opportunities[]` (the opportunity-card surface) carries `equity_release`, which **places** `disposition`'s projected `sale_proceeds`/`loan_payout` to model the releasable equity at the hold horizon (one-computer-per-figure: it derives the band, it does not recompute the placed figures). `purchase_journey`/`phase_playbook` (added 2026-07-10, task 4) run **last**: `purchase_journey` reads no `ownership_planning_investor` output (`portfolio_position` carries no `cash_events`) but is positioned after it, mirroring Mode A's "figure-owners, then the spine that places them" DAG shape; `phase_playbook` follows, reading `purchase_journey`'s phase set. Acyclic throughout.

---

## Open questions / future iteration

1. **Portfolio-aggregate view** — Mode C investors often have multiple plan cards (one per property). The current design captures per-property data; a future iteration should specify how `ownership_planning_investor` outcomes aggregate into a portfolio dashboard.
2. **SMSF-specific complexity** — SMSF + LRBA arrangements have additional compliance requirements (sole purpose test, trust deed compliance, audit). A future iteration may extract SMSF into a sub-blueprint variant.
3. **Land tax aggregation across states** — investors with properties in multiple states face state-specific aggregation rules. A future iteration should add a cross-property land tax forecasting flow.
4. **Rentvest scenario** — investor still rents PPOR while owning investments. The current design assumes investor has PPOR; a future iteration should support the rentvest pattern (common among Vietnamese-AU younger investors).
5. **Commercial property pivot** — currently residential only. A future iteration may extend to commercial residential, NDIS/SDA, dual-occupancy.

---

## Document control

- **Status:** draft, May 2026 — third concrete blueprint (Mode C investor, domestic)
- **Author:** Strategic design synthesis (Claude + maintainer)
- **Companion blueprints:** [`fhb-domestic-au`](fhb-domestic-au.md), [`fhb-foreign-au`](fhb-foreign-au.md). Pending: `investor-foreign-au` (Mode D).
- **Direct competitor positioning:** This blueprint produces the same depth of investor analytics HTAG offers, but in Vietnamese + with family-financial-pattern fluency + integrated with the lifecycle (Mode A graduates).
- **Disclaimer:** This is a working spec, not regulatory or tax advice. Tax entity selection, negative gearing implications, depreciation schedules, CGT projections, and land tax obligations must be verified with a registered tax agent or accountant before commitment. The blueprint produces structured reasoning; the user must confirm strategic decisions with licensed professionals.
