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

10 components. Two are new vs Mode A FHB (marked `★`); the rest are adapted for investor reasoning.

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

Mode C's base plan is sharper than Mode A's because investor reasoning often happens *before* property identification — the user decides their thesis, entity, target yield, target suburb characteristics, then looks for properties matching. This makes the base plan the central decision artifact for investors.

```
[1] investor_profile (replaces buyer_profile — investor-focused)
       │   outcome: investor_profile_summary
       ▼
[2] property_assessment (investor lens — rental + growth + depreciation)
       │   inputs: investor_profile_summary
       │   outcome: property_fit_investor
       ▼
[3] investment_strategy (replaces FHB eligibility — yield/growth/gearing goals)
       │   inputs: investor_profile_summary, property_fit_investor
       │   outcome: strategy_thesis
       ▼
[4] yield_modelling ★
       │   inputs: investor_profile_summary, property_fit_investor, strategy_thesis
       │   outcome: cash_flow_projection
       ▼
[5] tax_structure ★
       │   inputs: investor_profile_summary, yield_modelling.outcome
       │   outcome: tax_optimised_structure
       ▼
[6] cash_position (investor variant — investment loan, higher deposit, no schemes)
       │   inputs: investor_profile_summary, property_fit_investor, tax_optimised_structure
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
```

**UI tab mapping** for Mode C:

| UI tab | Components rendered |
|---|---|
| Overview | `investor_profile` + `property_assessment` + `strategy_thesis` summary |
| Investment strategy | `investment_strategy` (central) |
| Yield & Tax | `yield_modelling` + `tax_structure` |
| Property | `property_assessment` + `due_diligence` |
| Cash calculator | `cash_position` (interactive form) |
| Buying | `buying_strategy` |
| Temporal flow | `settlement_prep` |
| Portfolio | `ownership_planning_investor` (single-property view + portfolio-aggregate view) |

**Machine-readable form** — compiled to `ui_tabs` in the artifact, **canonical for the runtime** (the table above is the human view), in the canonical lifecycle order. `kind: synthesis` is a shell-composed summary; `interactive: true` is the client-side cash what-if. The `journey` tab gains `purchase_journey` (per-mode base swimlane) when Mode C content is built. Structure is authored now; **Mode C content is dormant** until `investor-domestic-au` comes in scope (see [`../architecture/plan-card-lifecycle-restoration.md`](../architecture/plan-card-lifecycle-restoration.md) §4).

```jsonc
{
  "ui_tabs": [
    { "tab_id": "overview",            "kind": "synthesis",  "components": ["investor_profile", "property_assessment", "investment_strategy"] },
    { "tab_id": "investment_strategy", "kind": "components", "components": ["investment_strategy"] },
    { "tab_id": "yield_tax",           "kind": "components", "components": ["yield_modelling", "tax_structure"] },
    { "tab_id": "cash_calculator",     "kind": "components", "interactive": true, "components": ["cash_position"] },
    { "tab_id": "journey",             "kind": "components", "components": ["settlement_prep"] },
    { "tab_id": "property",            "kind": "components", "components": ["property_assessment", "due_diligence"] },
    { "tab_id": "buying",              "kind": "components", "components": ["buying_strategy"] },
    { "tab_id": "portfolio",           "kind": "components", "components": ["ownership_planning_investor"] }
  ]
}
```

---

## Components

### 1. investor_profile (replaces buyer_profile)

**Goal:** Capture the investor's situation — citizenship, tax bracket, existing portfolio, investment experience, risk tolerance, and investment goals.

**Inputs:** User questions answered in chat; uploaded documents (NOA, payslips, depreciation schedules from existing properties if any).

**KB anchors:** `kb.investor.tax-brackets-2026`, `kb.investor.serviceability-investment-loans`, `kb.investor.experience-levels`

**Renderer:** `summary-card`

**UI tab hint:** Overview (collapsed) + Investment strategy (detail)

**Parameters:**

```jsonc
{
  "identity": {
    "citizenship_status": { "type": "enum", "options": ["citizen", "permanent_resident"], "value": "<initial>" },
    "location_state": { "type": "enum", "options": ["NSW", "VIC", "QLD", "WA", "SA", "TAS", "ACT", "NT"], "value": "<initial>" },
    "language_preference": { "type": "enum", "options": ["en", "vi"], "value": "en" }
  },
  "household": {
    "buying_alone": { "type": "bool", "value": "<initial>" },
    "co_investor_count": { "type": "integer", "value": 0 },
    "dependents_count": { "type": "integer", "value": 0 }
  },
  "income_and_tax": {
    "primary_taxable_income": { "type": "money_per_year", "value": "<initial>" },
    "marginal_tax_rate_estimate": { "type": "percentage", "value": "<initial>", "derived_from": "primary_taxable_income" },
    "income_stability": { "type": "enum", "options": ["permanent_payg", "contractor", "self_employed", "casual", "mixed"], "value": "<initial>" },
    "spousal_income_if_joint": { "type": "money_per_year", "value": 0 }
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
    "experience_level": { "type": "enum", "options": ["first_investment", "second_or_third", "experienced_4_plus"], "value": "<initial>" },
    "depreciation_strategies_used": { "type": "bool", "value": "<initial>" },
    "trust_or_company_structures_used": { "type": "bool", "value": "<initial>" }
  },
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

**Outcome schema:** `investor_profile_summary`

```jsonc
{
  "type": "investor_profile_summary",
  "fields": {
    "marginal_tax_rate": "percentage",
    "approx_borrowing_capacity_investment_loan": "money_range",
    "ppor_equity_available_for_leverage": "money",
    "experience_level": "enum",
    "primary_investment_goal": "enum",
    "negative_gearing_attractive": "bool",
    "key_strengths": "array<string>",
    "key_constraints": "array<string>"
  }
}
```

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

**KB anchors:** `kb.investor.strategy-archetypes`, `kb.investor.gearing-types-and-implications`, `kb.investor.hold-period-considerations`, `kb.investor.exit-strategy-options`

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

**Inputs:** `investor_profile.outcome` (investor_profile_summary — including debts, marginal tax rate, existing portfolio) + `investment_strategy.outcome` (strategy_thesis — particularly gearing_type and target_lvr)

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

**KB anchors:** `kb.investor.rental-income-modelling`, `kb.investor.operating-expenses-typical-ratios`, `kb.investor.vacancy-rate-assumptions`, `kb.investor.cash-flow-modelling-methodology`, `kb.investor.property-management-fees`

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
    "annual_rental_income_year_1": "money",
    "annual_operating_expenses_year_1": "money",
    "annual_interest_year_1": "money",
    "cash_flow_before_tax_year_1": "money",
    "cash_flow_before_tax_per_week": "money",
    "gross_yield": "percentage",
    "net_yield_pre_loan": "percentage",
    "net_yield_post_loan_pre_tax": "percentage",
    "year_5_projected_cash_flow": "money",
    "year_10_projected_cash_flow": "money",
    "is_positive_neutral_or_negative_geared_pre_tax": "enum"
  }
}
```

---

### 6. tax_structure ★ (NEW)

**Goal:** Determine the tax-optimised ownership structure and quantify negative gearing benefit + depreciation + CGT projection.

**Inputs:** `investor_profile.outcome` + `cash_flow_projection`

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
  "cgt_projection": {
    "estimated_capital_gain_at_exit": { "type": "money", "value": "<initial>" },
    "50_percent_discount_eligible": { "type": "bool", "value": true, "note": "Applies if held >12 months" },
    "taxable_capital_gain": { "type": "money", "value": "<initial>" },
    "cgt_payable_estimate": { "type": "money", "value": "<initial>" }
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
    "annual_tax_refund_year_1": "money",
    "after_tax_cash_flow_year_1": "money",
    "after_tax_cash_flow_per_week": "money",
    "total_depreciation_year_1": "money",
    "cgt_projection_at_exit": "money",
    "annual_compliance_cost": "money",
    "setup_costs": "money"
  }
}
```

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
    "mitigation_options_if_short": "array<string>"
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

**Outcome schema:** `bid_plan_investor` (same as Mode A bid_plan with added `yield_anchored_max_price` and `thesis_alignment` fields)

---

### 9. due_diligence (investor focus)

**Goal:** Surface document risks *plus rental market validation and depreciation report procurement*.

**Inputs:** `property_fit_investor.outcome` + uploaded documents

**KB anchors:** Mode A due_diligence anchors + `kb.investor.rental-appraisal-from-pm-agent`, `kb.investor.depreciation-report-quantity-surveyor`, `kb.investor.tenancy-in-situ-considerations`

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
    "current_tenancy_unfavourable_terms": { "type": "array<string>", "value": [], "agent_reasoning_required": true, "reasoning_domain": "lease_interpretation" },
    "rental_yield_below_thesis_threshold": { "type": "bool", "value": "<initial>" }
  }
}
```

**Outcome schema:** `risk_assessment_investor` (same as Mode A risk_assessment plus `investor_specific_concerns` field)

---

### 10. settlement_prep (similar to Mode A + entity setup)

**Goal:** Coordinate settlement *with entity setup, depreciation schedule procurement, property management appointment*.

**Inputs:** `property_fit_investor.outcome` + `bid_plan_investor` + `tax_optimised_structure`

**KB anchors:** Mode A settlement_prep anchors + `kb.investor.entity-setup-timeline`, `kb.investor.depreciation-schedule-procurement`, `kb.investor.property-management-appointment-timeline`

**Renderer:** `swimlane-diagram` + `checklist`

**UI tab hint:** Temporal flow

**Parameters:**

Same as [Mode A settlement_prep](fhb-domestic-au.md#8-settlement_prep) with these additions:

```jsonc
{
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

**Outcome schema:** `settlement_checklist` (same as Mode A with added investor milestones)

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
    "annual_tax_obligations": "array<string>",
    "portfolio_diversification_score": "integer_0_10"
  }
}
```

---

## KB anchor index (for this blueprint)

40 slugs referenced. Italics mark Mode C-only anchors (not in Mode A FHB).

| Slug | Component(s) | Owns |
|---|---|---|
| *`kb.investor.tax-brackets-2026`* | 1 | Australian tax brackets 2026 with marginal rates |
| *`kb.investor.serviceability-investment-loans`* | 1 | Investment loan serviceability assessment |
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
| *`kb.tax.depreciation-division-43-and-40`* | 5 | Capital works (Div 43) and plant & equipment (Div 40) depreciation |
| *`kb.tax.cgt-50-percent-discount`* | 5 | CGT 50% discount eligibility |
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

---

## Renderer vocabulary used

| Renderer | Used by component(s) |
|---|---|
| `summary-card` | 1 investor_profile, 2 property_assessment, 3 investment_strategy |
| `calculator` | 4 yield_modelling, 5 tax_structure, 6 cash_position |
| `data-table` | 5 tax_structure, 10 ownership_planning_investor |
| `buying-strategy-card` | 7 buying_strategy |
| `risk-flag-list` | 8 due_diligence |
| `checklist` | 8 due_diligence, 9 settlement_prep |
| `swimlane-diagram` | 9 settlement_prep |
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

**Fill-path classification.** Per [agentic-boundary.md](../architecture/agentic-boundary.md), `agent_reasoning_required: true` marks agent-path leaves; all others resolve deterministically. Mode C agent-path leaves: rent + property valuation (`property_assessment.rental_market.estimated_weekly_rent_range`, `market_position.*`), investment thesis (`investment_strategy.strategy_archetype`, `thesis_one_liner`, `gearing_type`), investor loan structure + lender fit (`mortgage_finance.uses_existing_ppor_equity`, IO/PI, `fixed_vs_variable`, `offset_account_strategy`, `investor_friendly_lender_shortlist`), entity structuring (`tax_structure.recommended_entity`), negotiation style, and lease interpretation (`due_diligence.investor_specific_flags.current_tenancy_unfavourable_terms`). Resolver: all yield/cashflow math, land tax, depreciation predicates, tax-rate lookups, vacancy assumptions, concession eligibility, yield-anchored max price.

---

## Cross-component output dependency graph

```
investor_profile         → outcome: investor_profile_summary
property_assessment      → outcome: property_fit_investor      (reads: investor_profile_summary)
investment_strategy      → outcome: strategy_thesis            (reads: investor_profile_summary, property_fit_investor)
yield_modelling          → outcome: cash_flow_projection       (reads: investor_profile_summary, property_fit_investor, strategy_thesis)
tax_structure            → outcome: tax_optimised_structure    (reads: investor_profile_summary, cash_flow_projection)
cash_position            → outcome: budget_envelope_investor   (reads: investor_profile_summary, property_fit_investor, tax_optimised_structure)
buying_strategy          → outcome: bid_plan_investor          (reads: property_fit_investor, budget_envelope_investor, strategy_thesis)
due_diligence            → outcome: risk_assessment_investor   (reads: property_fit_investor, uploaded_docs)
settlement_prep          → outcome: settlement_checklist       (reads: property_fit_investor, bid_plan_investor, tax_optimised_structure)
ownership_planning_investor → outcome: portfolio_position      (reads: property_fit_investor, tax_optimised_structure, cash_flow_projection)
```

No cycles. `tax_structure` is on the critical path because it informs `cash_position` (entity setup costs) and `ownership_planning_investor` (annual compliance).

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
