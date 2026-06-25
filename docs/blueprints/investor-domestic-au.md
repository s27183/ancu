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

12 components. Two are new vs Mode A FHB (marked `★`); `disposition` (12) is added by the full-temporal-flow reframe ([`../architecture/lifecycle-simulation-model.md` §8](../architecture/lifecycle-simulation-model.md)) as the dispose-phase figure-owner — **design-first / dormant** until Mode C ships, the same as the rest of this blueprint; the remainder are adapted for investor reasoning.

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
| 12 disposition | `base` | Dispose-phase figure-owner — projected sale proceeds, selling costs, loan payout, and **full CGT** (50%-discount-if-held-over-12-months, depreciation clawback) over the hold horizon `H`; the full-horizon net position. Resolver, no agent leaf. *Design-first* (§8.5). |

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

**UI tab mapping** for Mode C:

| UI tab | Components rendered |
|---|---|
| Overview | `investor_profile` + `property_assessment` + `strategy_thesis` summary |
| Investment strategy | `investment_strategy` (central) |
| Yield & Tax | `yield_modelling` + `tax_structure` |
| Property | `property_assessment` + `due_diligence` |
| Cash calculator | `cash_position` + `disposition` (full-horizon net position: acquire → hold over `H` → dispose; horizon slider = structural what-if) |
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
    { "tab_id": "cash_calculator",     "kind": "components", "interactive": true, "components": ["cash_position", "disposition"] },
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

**KB anchors:** `kb.tax.income-tax-resident-2025-26`, `kb.lender.serviceability-investment-loans`, `kb.investor.experience-levels`

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
          "marginal_rate": { "type": "percentage", "value": "<initial>", "derived_from": "taxable_income", "note": "per-applicant marginal rate (kb.tax.income-tax-resident-2025-26); read as applicant.tax.marginal_rate by tax_structure / disposition." },
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

**Hold-phase `cash_events` (full-temporal-flow wiring, design-first — §8.5/§8.6).** `yield_modelling` owns the **recurring hold-phase** flows that the full-horizon financial spine places at phase `own` over the horizon `H`: rental income (`money_in`, `timing: recurring`, `period: year`), operating expenses and loan interest (`money_out`, recurring/year), each `source_component: yield_modelling`, gated by the §13 placement/provenance check. These are the holding-years entries the truncated (acquire-only) model had nowhere to put; `tax_structure` adds the negative-gearing tax effect on the same axis (below).

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
    "annual_tax_refund_year_1": "money",
    "after_tax_cash_flow_year_1": "money",
    "after_tax_cash_flow_per_week": "money",
    "total_depreciation_year_1": "money",
    "cgt_discount_eligible": "bool",
    "cgt_marginal_rate": "percentage",
    "cost_base_depreciation_clawback": "bool",
    "annual_compliance_cost": "money",
    "setup_costs": "money"
  }
}
```

**Hold-phase + dispose wiring (full-temporal-flow, design-first — §8.5).** `tax_structure` owns the **recurring hold-phase** negative-gearing tax effect — the annual tax refund (`money_in`, `timing: recurring`, `period: year`, `source_component: tax_structure`) placed at phase `own` over `H` — and supplies the **CGT determinants** (`cgt_determinants` block above: discount eligibility, marginal rate, depreciation clawback) to `disposition` (component 12), which owns the **dispose-phase CGT figure** and its cash_event. The previously-homeless `cgt_projection` is thus resolved: hold-phase tax effects stay here; the dispose-phase gain/payable lands at the `dispose` phase, owned by the one computer for that figure.

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
    "annual_tax_obligations": "array<localized_text>",  // user-facing prose → bilingual {vi,en}, validator-enforced (matches disposition.key_assumptions)
    "portfolio_diversification_score": "integer_0_10",
    "opportunities": "array<{ kind, modeled_benefit, action }>"  // the opportunity-card surface (§11.9). [] at base — an opportunity is defined by its modeled_benefit, a figure off an OWNED property (equity release, rent review, scale-up); none exist plan-first. Populates per-property (Phase B). The producer half of the P4 opportunity-card seam, closed here; the consumer half (shell renders only renderers[0]) is a separate shell unit.
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

## KB anchor index (for this blueprint)

42 slugs referenced. Italics mark Mode C-only anchors (not in Mode A FHB); the two growth/selling-cost anchors at component 12 are **shared with Mode A** (non-italic).

| Slug | Component(s) | Owns |
|---|---|---|
| `kb.tax.income-tax-resident-2025-26` | 1 | Resident income-tax brackets + marginal rates (shared with Mode A) |
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

---

## Renderer vocabulary used

| Renderer | Used by component(s) |
|---|---|
| `summary-card` | 1 investor_profile, 2 property_assessment, 3 investment_strategy |
| `calculator` | 4 yield_modelling, 5 tax_structure, 6 cash_position, 12 disposition |
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

**Fill-path classification.** Per [agentic-boundary.md](../architecture/agentic-boundary.md), `agent_reasoning_required: true` marks agent-path leaves; all others resolve deterministically. Mode C agent-path leaves: rent + property valuation (`property_assessment.rental_market.estimated_weekly_rent_range`, `market_position.*`), investment thesis (`investment_strategy.strategy_archetype`, `thesis_one_liner`, `gearing_type`), investor loan structure + lender fit (`mortgage_finance.uses_existing_ppor_equity`, IO/PI, `fixed_vs_variable`, `offset_account_strategy`, `investor_friendly_lender_shortlist`), entity structuring (`tax_structure.recommended_entity`), negotiation style, and lease interpretation (`due_diligence.investor_specific_flags.current_tenancy_unfavourable_terms`). Resolver: all yield/cashflow math, land tax, depreciation predicates, tax-rate lookups, vacancy assumptions, concession eligibility, yield-anchored max price, and **all of `disposition`** (growth projection, selling costs, loan payout, taxable gain, CGT, the full-horizon roll-up — KB-grounded computations deliberately removed from the agent's reach, §8.5).

---

## Cross-component output dependency graph

```
investor_profile         → outcome: profile
property_assessment      → outcome: property_fit_investor      (reads: profile)
investment_strategy      → outcome: strategy_thesis            (reads: profile, property_fit_investor)
yield_modelling          → outcome: cash_flow_projection       (reads: profile, property_fit_investor, strategy_thesis)
tax_structure            → outcome: tax_optimised_structure    (reads: profile, cash_flow_projection)
cash_position            → outcome: budget_envelope_investor   (reads: profile, property_fit_investor, tax_optimised_structure)
buying_strategy          → outcome: bid_plan_investor          (reads: property_fit_investor, budget_envelope_investor, strategy_thesis)
due_diligence            → outcome: risk_assessment_investor   (reads: property_fit_investor, uploaded_docs)
settlement_prep          → outcome: settlement_checklist       (reads: property_fit_investor, bid_plan_investor, tax_optimised_structure)
ownership_planning_investor → outcome: portfolio_position      (reads: property_fit_investor, tax_optimised_structure, cash_flow_projection)
disposition              → outcome: disposition              (reads: strategy_thesis, property_fit_investor, cash_flow_projection, tax_optimised_structure, budget_envelope_investor)
```

No cycles. `tax_structure` is on the critical path because it informs `cash_position` (entity setup costs) and `ownership_planning_investor` (annual compliance). `disposition` is a **pure sink** — it reads the upstream figure-owners (`strategy_thesis` for the horizon `H`, the yield/tax/cash outcomes for the acquire+hold flows it places and the CGT determinants it consumes) and is read by no one, so it adds a leaf, not a cycle.

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
