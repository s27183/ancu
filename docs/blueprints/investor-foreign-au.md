# Investor plan card blueprint — Mode D (foreign, Vietnam-located investor)

> Part of the **Vietnamese Diaspora Property Platform** document set. See [README.md](../README.md) for the full index.
>
> **This is a working specification** for the investor blueprint serving Vietnam-located investors buying Australian property as investment. Companion specs: [investor-domestic-au.md](investor-domestic-au.md) (Mode C), [fhb-foreign-au.md](fhb-foreign-au.md) (Mode B), [fhb-domestic-au.md](fhb-domestic-au.md) (Mode A).

---

## Metadata

```jsonc
{
  "blueprint_id": "investor-foreign-au",
  "effective_from": "2026-05-19",
  "effective_until": null,
  "buyer_mode": "investor",
  "user_mode": "D",
  "audience": "Vietnam-located individual or couple investing in Australian residential property as investment / wealth diversification. Foreign persons under FIRB.",
  "firb_required": true,
  "language_primary": "vi",
  "language_alternate": "en",
  "renderer_set": "investor"
}
```

This blueprint serves **Mode D** users — Vietnamese individuals or couples based in Vietnam investing in Australian property. They are **foreign persons** under FIRB and subject to all the foreign-person constraints documented in Mode B (`fhb-foreign-au`), AND they apply investor reasoning documented in Mode C (`investor-domestic-au`).

Mode D is the **most complex of the four blueprints** because it combines:

1. **Foreign-person regulatory regime** (from Mode B) — FIRB ban on established dwellings, FIRB application + fees, foreign-buyer surcharge, vacancy fee, non-resident tax, AU AML/CTF, VN capital controls, VN PDP
2. **Investor reasoning** (from Mode C) — yield modelling, tax structure (non-resident variant), strategy thesis, portfolio planning, depreciation
3. **Cross-border specifics unique to Mode D** — VN-based investors may operate solo (no AU-side member), use Vietnamese investment advisors, face VN-side tax on AU income, and have different exit strategies

**Direct competitor positioning vs HTAG:** HTAG targets professional investors in English. Mode D's wedge is Vietnamese language + foreign-investor compliance (FIRB + AML + non-resident tax) handled natively + cross-border family / advisor coordination. HTAG cannot serve this audience without committing to a Vietnamese-language vertical and FIRB-aware product surface — neither of which is in their stated roadmap.

---

## Component pipeline

12 components. Borrows from Mode B (foreign-person) and Mode C (investor) with Mode D-specific adaptations marked `★`.

### Component scope (base plan vs property addendum)

Mode D's base plan captures the deepest pre-property reasoning of all four blueprints. Vietnam-located investors typically commit to AU investment in principle (including FIRB engagement, cross-border funding, tax structure) *before* identifying a specific property. The base plan is the strategic-decision artifact; addenda layer specific properties later.

| Component | Scope | Runs when |
|---|---|---|
| 1 investor_profile_foreign ★ | `base` | Onboarding |
| 2 property_assessment (investor + foreign-person filter) | `per-property` | When specific property attached |
| 3 firb_workflow | `both` | Base FIRB fee tier estimate at onboarding; refined per-property |
| 4 investment_strategy (foreign-investor specific) | `base` | Onboarding |
| 5 mortgage_finance (non-resident investor variant) | `both` | Base loan structure + non-resident investor lender shortlist + IO-vs-PI + FX risk reasoning; refined per-property |
| 6 yield_modelling (non-resident tax aware) | `both` | Base estimate; refined per-property |
| 7 tax_structure_non_resident ★ | `both` | Base recommendation (incl. negative gearing analysis with FRCGW + treaty considerations); refined per-property |
| 8 cash_position (foreign + investor cost stack) | `both` | Base estimate; refined per-property |
| 9 cross_border_funding | `both` | Base capacity / provider; refined per-property |
| 10 buying_strategy (investor + FIRB gate) | `per-property` | When user signals bid readiness |
| 11 due_diligence (investor + cross-border) | `per-property` | When user uploads docs |
| 12 settlement_prep (investor + FIRB + transfer) | `per-property` | Activated when contract signed |
| 13 ownership_planning_foreign_investor ★ | `both` | Base estimate of vacancy/tax/repatriation obligations; refined per-property post-settlement |

This base-heavy structure is genuinely well-suited to Mode D's audience: Vietnam-located investors making major capital allocation decisions across borders. They need to validate the strategic shape (entity, FIRB path, currency transfer plan, tax structure, target yield) before they're ready to commit to a specific property.

```
[1] investor_profile_foreign ★ (combines Mode B buyer_profile + Mode C investor_profile)
       │   outcome: investor_profile_foreign_summary
       ▼
[2] property_assessment (investor lens + foreign-person filter: new-build only)
       │   inputs: investor_profile_foreign_summary
       │   outcome: property_fit_investor_foreign
       ▼
[3] firb_workflow (from Mode B — mandatory)
       │   inputs: investor_profile_foreign_summary, property_fit_investor_foreign
       │   outcome: firb_status
       ▼
[4] investment_strategy (investor — yield/growth/gearing; foreign-investor specific)
       │   inputs: investor_profile_foreign_summary, property_fit_investor_foreign
       │   outcome: strategy_thesis_foreign
       ▼
[5] yield_modelling (from Mode C — non-resident tax aware)
       │   inputs: property_fit_investor_foreign, strategy_thesis_foreign
       │   outcome: cash_flow_projection_foreign
       ▼
[6] tax_structure_non_resident ★ (non-resident tax variant of Mode C)
       │   inputs: investor_profile_foreign_summary, cash_flow_projection_foreign
       │   outcome: tax_structure_non_resident_summary
       ▼
[7] cash_position (Mode B foreign-buyer costs + Mode C investor costs)
       │   inputs: investor_profile_foreign_summary, property_fit_investor_foreign, firb_status, tax_structure_non_resident_summary
       │   outcome: budget_envelope_foreign_investor
       ▼
[8] cross_border_funding (from Mode B)
       │   inputs: investor_profile_foreign_summary, budget_envelope_foreign_investor
       │   outcome: transfer_plan
       ▼
[9] buying_strategy (Mode C investor discipline + Mode B FIRB gate)
       │   inputs: property_fit_investor_foreign, budget_envelope_foreign_investor, firb_status, strategy_thesis_foreign
       │   outcome: bid_plan_foreign_investor
       ▼
[10] due_diligence (Mode C investor + Mode B cross-border docs)
        inputs: property_fit_investor_foreign, uploaded_docs
        outcome: risk_assessment_foreign_investor
       ▼
[11] settlement_prep (Mode C investor + Mode B FIRB + transfer milestones)
        inputs: property_fit_investor_foreign, bid_plan_foreign_investor, firb_status, transfer_plan, tax_structure_non_resident_summary
        outcome: settlement_checklist_foreign
       ▼
[12] ownership_planning_foreign_investor ★ (Mode C portfolio + Mode B vacancy/tax)
        inputs: property_fit_investor_foreign, tax_structure_non_resident_summary, cash_flow_projection_foreign
        outcome: portfolio_position_foreign
```

**UI tab mapping** for Mode D:

| UI tab | Components rendered |
|---|---|
| Overview | `investor_profile_foreign` + `property_assessment` + `strategy_thesis_foreign` summary |
| Investment strategy | `investment_strategy` (central) |
| FIRB & Funding | `firb_workflow` + `cross_border_funding` |
| Yield & Tax | `yield_modelling` + `tax_structure_non_resident` |
| Property | `property_assessment` + `due_diligence` |
| Cash calculator | `cash_position` (interactive form) |
| Buying | `buying_strategy` |
| Temporal flow | `settlement_prep` |
| Portfolio | `ownership_planning_foreign_investor` |

Note: Mode D does NOT activate Mode B's Family view tab by default — Vietnam-located investors are typically solo / couple operations, not parent-funding-child. If the user invites a co-investor or family member, the platform offers the family-view layer as an opt-in.

---

## Components

### 1. investor_profile_foreign ★

**Goal:** Capture the Vietnam-located investor's situation — residency, Vietnamese tax bracket, existing AU/VN/other property holdings, investment experience, risk tolerance, investment goals, and language preferences.

**Inputs:** User questions; uploaded documents (Vietnamese passport, residency proof, prior AU FIRB approvals if any, financial statements).

**KB anchors:** `kb.firb.status-determination`, `kb.firb.established-dwelling-ban`, `kb.vn-tax.brackets-2026`, `kb.vn-tax.income-from-foreign-property`, `kb.non-resident.serviceability-au-lenders`, `kb.investor.experience-levels`

**Renderer:** `summary-card`

**UI tab hint:** Overview + Investment strategy

**Parameters:**

```jsonc
{
  "identity": {
    "primary_residence_country": { "type": "enum", "options": ["VN", "other_non_au"], "value": "VN" },
    "vn_residency_state_or_city": { "type": "string", "value": "<initial>" },
    "citizenship": { "type": "enum", "options": ["vietnamese_citizen", "overseas_vietnamese_with_other_citizenship", "non_vietnamese"], "value": "<initial>" },
    "firb_classification": { "type": "enum", "value": "foreign_person", "agent_reasoning_required": false },
    "language_preference": { "type": "enum", "options": ["vi", "en"], "value": "vi" }
  },
  "investor_unit": {
    "investing_alone": { "type": "bool", "value": "<initial>" },
    "co_investor_count": { "type": "integer", "value": 0 },
    "co_investor_relationship": { "type": "enum", "options": ["spouse", "business_partner", "family_pool", "none"], "value": "none" }
  },
  "income_and_vn_tax": {
    "vn_taxable_income_vnd": { "type": "money_vnd_per_year", "value": "<initial>" },
    "vn_marginal_tax_rate": { "type": "percentage", "value": "<initial>" },
    "income_source_country": { "type": "enum", "options": ["vn_only", "vn_and_other", "diversified_global"], "value": "<initial>" },
    "vn_tax_treaty_implications_au": { "type": "string", "value": "<initial>" }
  },
  "existing_portfolio": {
    "au_property_count": { "type": "integer", "value": 0 },
    "vn_property_count": { "type": "integer", "value": "<initial>" },
    "other_country_property_count": { "type": "integer", "value": 0 },
    "total_global_portfolio_value": { "type": "money_aud_equivalent", "value": "<initial>" },
    "prior_firb_approvals": { "type": "array<{ year, property, approval_number }>", "value": [] }
  },
  "investment_experience": {
    "experience_level": { "type": "enum", "options": ["first_au_investment", "second_or_third_au", "experienced_au_4_plus"], "value": "<initial>" },
    "uses_vn_investment_advisor": { "type": "bool", "value": "<initial>" },
    "uses_au_buyers_agent": { "type": "bool", "value": "<initial>" }
  },
  "investment_goals": {
    "primary_goal": { "type": "enum", "options": ["wealth_diversification", "cash_flow", "capital_growth", "balanced", "future_migration_pathway", "child_education_property"], "value": "<initial>" },
    "secondary_goal": { "type": "enum", "options": ["wealth_diversification", "cash_flow", "capital_growth", "balanced", "future_migration_pathway", "child_education_property", "none"], "value": "none" },
    "intended_hold_period_years": { "type": "integer", "value": "<initial>" },
    "exit_strategy": { "type": "enum", "options": ["sell_at_growth_target", "hold_perpetually", "transfer_to_family_in_au", "convert_to_ppor_on_migration"], "value": "<initial>" }
  },
  "risk_tolerance": {
    "comfort_with_vacancy_months": { "type": "integer", "value": "<initial>" },
    "leverage_comfort_lvr": { "type": "percentage", "value": "<initial>" },
    "currency_volatility_concern": { "type": "enum", "options": ["high", "medium", "low"], "value": "<initial>" }
  },
  "vn_capital_resources": {
    "available_capital_aud_equivalent": { "type": "money", "value": "<initial>" },
    "source_of_funds_categories": { "type": "array<enum>", "options": ["business_proceeds", "vn_property_sale", "family_pool", "savings_long_term", "vn_investment_returns", "other"], "value": [] },
    "source_of_funds_documentation_ready": { "type": "enum", "options": ["ready", "partial", "not_started"], "value": "<initial>" }
  }
}
```

**Outcome schema:** `investor_profile_foreign_summary`

```jsonc
{
  "type": "investor_profile_foreign_summary",
  "fields": {
    "firb_required": "bool",                       // always true for Mode D
    "established_property_eligible": "bool",       // false while the ban is in force — derived from kb.firb.established-dwelling-ban (single owner of the window)
    "new_build_only_constraint": "bool",
    "vn_marginal_tax_rate": "percentage",
    "available_capital_aud_equivalent": "money",
    "experience_level": "enum",
    "primary_investment_goal": "enum",
    "currency_volatility_concern": "enum",
    "key_constraints": "array<string>",
    "key_strengths": "array<string>"
  }
}
```

---

### 2. property_assessment (investor lens + foreign-person filter)

**Goal:** Analyse the property with *both* investor metrics (yield, growth, depreciation) AND foreign-person eligibility filtering (new-build only).

**Inputs:** `property_card` + `investor_profile_foreign.outcome`

**KB anchors:** Mode C property_assessment anchors + Mode B foreign-person filter anchors + `kb.firb.eligible-property-types-foreign-persons`, `kb.firb.fee-tiers-by-value`, `kb.off-the-plan.foreign-investor-considerations`

**Renderer:** `summary-card`

**UI tab hint:** Property

**Parameters:**

Same structure as [Mode C property_assessment](investor-domestic-au.md#2-property_assessment-investor-lens) PLUS:

```jsonc
{
  // all Mode C investor parameters, plus:
  // FIRB eligibility + fee determination moved to firb_workflow (it owns FIRB verdicts). Foreign-buyer
  // stamp-duty surcharge lives in cash_position's stamp_duty_and_surcharge (state duty, not a FIRB fee).
  // property_assessment stays FIRB-agnostic — neutral facts + investor property-fit, plus an early
  // non-authoritative ban warning in key_concerns (see outcome). Same consolidation as Mode B.
  "off_the_plan_specific_considerations_for_foreign_investor": {
    "developer_track_record_check": { "type": "enum", "options": ["strong", "acceptable", "concerning", "unknown"], "value": "<initial>", "agent_reasoning_required": true, "reasoning_domain": "off_the_plan" },
    "sunset_clause_protection_assessment": { "type": "enum", "options": ["adequate", "concerning"], "value": "<initial>", "agent_reasoning_required": true, "reasoning_domain": "off_the_plan" },
    "vendor_disclosure_completeness": { "type": "enum", "options": ["complete", "partial", "minimal"], "value": "<initial>", "agent_reasoning_required": true, "reasoning_domain": "off_the_plan" }
  }
}
```

**Outcome schema:** `property_fit_investor_foreign`

```jsonc
{
  "type": "property_fit_investor_foreign",
  "fields": {
    // neutral property facts (per-property fact surface) — the only route downstream components
    // read property data; never via basics.* params (§11.9 one access path)
    "state": "enum [NSW, VIC, QLD, WA, SA, TAS, ACT, NT]",
    "suburb": "string",
    "price": "money",
    "property_type": "enum [established_house, established_apartment, new_house, new_apartment, off_the_plan, house_and_land]",
    // investor property-fit verdicts (this component's own reasoning) — FIRB verdicts now live in firb_workflow.
    // No `blocked_foreign_person_ineligible`: property_assessment runs before firb_workflow. It emits an EARLY,
    // non-authoritative ban warning in key_concerns (foreign profile + established property_type); firb_workflow
    // issues the authoritative foreign_person_eligible=false + blocking_for_contract.
    "viability_verdict": "enum [strong_investment, acceptable_investment, marginal, reconsider]",
    "rental_yield_gross_estimate": "percentage",
    "capital_growth_outlook": "enum",
    "depreciation_attractiveness": "enum",
    "investor_grade_overall": "integer_0_10",
    "key_strengths": "array<string>",
    "key_concerns": "array<string>"
  }
}
```

---

### 3. firb_workflow (from Mode B)

**Goal:** Manage FIRB approval state machine.

**Inputs:** `investor_profile_foreign.outcome` + `property_fit_investor_foreign.outcome`

**Same as [Mode B firb_workflow](fhb-foreign-au.md#4-firb_workflow--new--replaces-mode-a-eligibility)**. No changes for Mode D — same parameters, same outcome schema, same KB anchors. The component is reused across foreign-person blueprints.

**Outcome:** `firb_status` (same as Mode B)

---

### 4. investment_strategy (foreign-investor-specific)

**Goal:** Articulate the investment thesis. Foreign-investor-specific considerations: future migration pathway, child-education-property motive, currency hedging preference, exit-on-migration plan.

**Inputs:** `investor_profile_foreign.outcome` + `property_fit_investor_foreign.outcome`

**KB anchors:** Mode C investment_strategy anchors + `kb.foreign-investor.thesis-archetypes`, `kb.foreign-investor.currency-hedging-considerations`, `kb.foreign-investor.future-migration-pathway-considerations`

**Renderer:** `summary-card`

**UI tab hint:** Investment strategy

**Parameters:**

Same as [Mode C investment_strategy](investor-domestic-au.md#3-investment_strategy-replaces-fhb-eligibility) with these additions and adapted enums:

```jsonc
{
  "thesis": {
    "strategy_archetype": { "type": "enum", "options": ["cash_flow", "capital_growth", "balanced", "wealth_diversification", "future_migration_pathway", "child_education_property", "land_banking"], "value": "<initial>", "agent_reasoning_required": true, "reasoning_domain": "investment_thesis" },
    "thesis_one_liner": { "type": "string", "value": "<initial>" }
  },
  "targets": { /* same as Mode C */ },
  "gearing_strategy": { /* same as Mode C */ },
  "exit_strategy": {
    "primary_exit": { "type": "enum", "options": ["sell_at_target_growth", "hold_perpetually", "transfer_to_au_family", "convert_to_ppor_on_migration", "sell_on_pr_grant_to_avoid_cgt"], "value": "<initial>" }
  },
  "foreign_investor_specific_considerations": {
    "currency_hedging_preference": { "type": "enum", "options": ["fully_hedged", "natural_hedge_aud_only", "partial_hedge", "unhedged"], "value": "<initial>" },
    "migration_pathway_alignment": { "type": "enum", "options": ["aligned_with_future_migration", "child_education", "no_migration_intent", "unsure"], "value": "<initial>" },
    "currency_volatility_buffer_aud": { "type": "money", "value": "<initial>" }
  },
  "deal_breakers": { /* same as Mode C */ }
}
```

**Outcome schema:** `strategy_thesis_foreign`

```jsonc
{
  "type": "strategy_thesis_foreign",
  "fields": {
    "archetype": "enum",
    "one_liner": "string",
    "target_gross_yield": "percentage",
    "target_capital_growth": "percentage",
    "gearing_type": "enum",
    "target_lvr": "percentage",
    "hold_period_years": "integer",
    "exit_strategy": "enum",
    "migration_pathway_alignment": "enum",
    "currency_hedging_strategy": "enum",
    "is_property_aligned_with_thesis": "bool"
  }
}
```

---

### 5. mortgage_finance (non-resident investor variant)

**Goal:** Determine the **non-resident investor loan path** — the most restrictive lender pool in the AU market — with investor-grade loan structure (IO vs P&I), foreign-buyer-specific deposit requirements, and FIRB-approval-precedes-unconditional-offer gating.

**Inputs:** `investor_profile_foreign.outcome` (investor_profile_foreign_summary — including existing portfolio, VN-side income) + `firb_workflow.outcome` (firb_status) + `investment_strategy.outcome` (strategy_thesis_foreign — gearing type, target LVR)

**KB anchors:** `kb.lender.non-resident-investment-loan-shortlist`, `kb.lender.foreign-investor-deposit-requirements`, `kb.lender.vn-income-treatment`, `kb.lender.investment-loan-policies-non-resident`, `kb.loan.interest-only-non-resident-investor`, `kb.lender.firb-approval-as-condition-precedent`, `kb.fx.loan-currency-considerations`, `kb.lender.foreign-investor-rate-premiums`

**Renderer:** `summary-card` + `data-table`

**UI tab hint:** Investment strategy + FIRB & Funding

**Scope:** `both` — base estimate at onboarding using profile + target price + FIRB fee estimate; refined per-property when loan amount known

**Parameters:**

```jsonc
{
  "borrowing_capacity": {
    "non_resident_investment_loan_assessment": { "type": "money_range", "value": "<initial>", "note": "Most restrictive pool in AU market — typically 3–5 lenders willing; income from Vietnam usually accepted with 20–40% haircut" },
    "vn_income_acceptance_by_lender": { "type": "array<{ lender, accepts_vn_income, haircut_percentage }>", "value": [] },
    "rental_income_treatment": { "type": "string", "value": "<initial>", "note": "Typically 70–80% of projected rental income counted toward serviceability" }
  },
  "deposit_requirements": {
    "minimum_required_percentage_typical": { "type": "percentage", "value": 35, "note": "Foreign-investor investment loans typically 30–40% deposit; rarely below 30%" },
    "minimum_required_amount": { "type": "money", "value": "<initial>" },
    "recommended_amount": { "type": "money", "value": "<initial>" }
  },
  "loan_path": {
    "non_resident_investor_loan_shortlist": { "type": "array<{ lender, rate_range, deposit_min, vn_income_accepted, processing_time }>", "value": [], "agent_reasoning_required": true, "reasoning_domain": "lender_fit" },
    "rate_premium_above_domestic_investor": { "type": "percentage_range", "value": "<initial>", "note": "Typically 100–200bp above domestic investor rates" },
    "recommended_lender": { "type": "string", "value": "<initial>" },
    "recommended_lender_reasoning": { "type": "string", "value": "<initial>" }
  },
  "loan_structure": {
    "principal_and_interest_vs_interest_only": { "type": "enum", "options": ["interest_only", "principal_and_interest"], "value": "interest_only", "note": "Investor-typical IO for tax efficiency; non-resident IO availability varies by lender" },
    "interest_only_period_years": { "type": "integer", "value": "<initial>" },
    "fixed_vs_variable": { "type": "enum", "options": ["variable", "fixed_1yr", "fixed_2yr", "fixed_3yr"], "value": "<initial>" },
    "offset_account_available_for_non_resident": { "type": "bool", "value": "<initial>", "note": "Some non-resident loans don't include offset; check per lender" }
  },
  "firb_gate": {
    "firb_approval_must_precede_unconditional_offer": { "type": "bool", "value": true },
    "lender_requires_firb_approval_before_loan_settlement": { "type": "bool", "value": true },
    "loan_offer_can_be_conditional_on_firb": { "type": "bool", "value": true }
  },
  "currency_considerations": {
    "loan_denomination_currency": { "type": "enum", "value": "AUD", "note": "All AU property loans in AUD; FX risk is on VN-side capital flow + ongoing repayments if investor's income is VND" },
    "fx_risk_on_ongoing_repayments": { "type": "string", "value": "<initial>", "note": "Material risk if investor's income is VND and repayments are AUD — VND volatility affects net cost over time" }
  },
  "pre_approval_workflow": {
    "documents_required_for_non_resident_investor": { "type": "array<{ document, status }>", "value": [], "note": "Includes passport, visa proof if any, VN tax returns, VN bank statements, source-of-funds letter, FIRB application reference, intended-use declaration" },
    "expected_processing_time_days": { "type": "integer", "value": "<initial>", "note": "Non-resident investor loans typically 6–10 weeks" }
  },
  "refinance_planning": {
    "io_period_expiry_date": { "type": "date", "value": "<initial>" },
    "refinance_pool_at_io_expiry": { "type": "string", "value": "<initial>", "note": "Limited — same restrictive non-resident lender pool. Pre-plan a switch-to-PI strategy if IO renewal not granted." }
  }
}
```

**Outcome schema:** `mortgage_plan`

```jsonc
{
  "type": "mortgage_plan",
  "fields": {
    "recommended_lender": "string",
    "expected_borrowing_capacity": "money_range",
    "deposit_required_percentage": "percentage",
    "deposit_required_amount": "money",
    "io_vs_pi_recommendation": "enum",
    "rate_estimate": "percentage_range",
    "firb_dependency_acknowledged": "bool",
    "vn_income_acceptance_confirmed": "bool",
    "fx_risk_acknowledged": "bool",
    "loan_cost_estimate_year_1": "money"
  }
}
```

The `mortgage_plan` outcome feeds `yield_modelling.loan_costs`, `tax_structure_non_resident.depreciation_strategy_non_resident` (depreciation is offset against rental income which is net of loan interest), `cash_position.deposit + loan amount`, `cross_border_funding.transfer_amount` (deposit + buying costs determines transfer), `buying_strategy.firb_gate + financing condition`, `settlement_prep` (lender + FIRB + transfer milestones).

---

### 6. yield_modelling (non-resident tax aware)

**Goal:** Model rental income, expenses, cash flow — *with non-resident tax treatment*.

**Inputs:** `property_fit_investor_foreign.outcome` + `strategy_thesis_foreign`

**KB anchors:** Mode C yield_modelling anchors + `kb.non-resident.rental-income-withholding-tax`, `kb.non-resident.no-cgt-ppor-exemption`

**Renderer:** `calculator`

**UI tab hint:** Yield & Tax

**Parameters:**

Same as [Mode C yield_modelling](investor-domestic-au.md#5-yield_modelling--new) PLUS:

```jsonc
{
  // all Mode C yield_modelling parameters, plus:
  "non_resident_tax_withholding": {
    "rental_income_withholding_applicable": { "type": "bool", "value": true },
    "withholding_rate_applicable": { "type": "percentage", "value": "<initial>" },
    "annual_withholding_amount": { "type": "money_per_year", "value": "<initial>" },
    "net_rental_income_after_withholding": { "type": "money_per_year", "value": "<initial>" }
  },
  "vacancy_fee_impact": {
    "vacancy_fee_at_risk_annually": { "type": "money_per_year", "value": "<initial>", "note": "Applies if property unoccupied / not genuinely available for rent ≥183 days/year" },
    "vacancy_fee_doubled_post_2024": { "type": "bool", "value": true }
  }
}
```

**Outcome schema:** `cash_flow_projection_foreign`

```jsonc
{
  "type": "cash_flow_projection_foreign",
  "fields": {
    "annual_rental_income_year_1": "money",
    "annual_operating_expenses_year_1": "money",
    "annual_interest_year_1": "money",
    "annual_withholding_tax": "money",
    "vacancy_fee_at_risk": "money",
    "cash_flow_before_au_income_tax_year_1": "money",
    "cash_flow_per_week_aud": "money",
    "gross_yield": "percentage",
    "net_yield_post_loan_post_withholding": "percentage",
    "year_5_projected_cash_flow": "money",
    "year_10_projected_cash_flow": "money"
  }
}
```

---

### 7. tax_structure_non_resident ★

**Goal:** Determine the tax-optimised structure for a *non-resident investor* — typically more constrained than Mode C (negative gearing limited; no CGT discount on properties held by foreign residents from May 2012; no PPOR exemption).

**Inputs:** `investor_profile_foreign.outcome` + `cash_flow_projection_foreign`

**KB anchors:** `kb.non-resident.tax-treatment-overview`, `kb.non-resident.cgt-no-50-percent-discount-from-2012`, `kb.non-resident.cgt-no-ppor-exemption`, `kb.non-resident.entity-options-au-property`, `kb.au-vn-tax-treaty`, `kb.tax.depreciation-non-resident`

**Renderer:** `data-table` + `calculator`

**UI tab hint:** Yield & Tax

**Parameters:**

```jsonc
{
  "ownership_entity": {
    "recommended_entity": { "type": "enum", "options": ["personal_sole_non_resident", "personal_joint_non_resident", "au_company_with_foreign_shareholder", "au_unit_trust_with_foreign_beneficiary", "other"], "value": "<initial>", "agent_reasoning_required": true, "reasoning_domain": "entity_structuring" },
    "reasoning": { "type": "string", "value": "<initial>" },
    "setup_cost_estimate": { "type": "money", "value": "<initial>" },
    "annual_compliance_cost_estimate": { "type": "money_per_year", "value": "<initial>" }
  },
  "rental_income_taxation": {
    "withholding_applicable": { "type": "bool", "value": true },
    "withholding_rate": { "type": "percentage", "value": "<initial>" },
    "annual_au_tax_payable_on_rental": { "type": "money_per_year", "value": "<initial>" },
    "negative_gearing_offset_against_au_income_only": { "type": "bool", "value": true, "note": "Non-resident losses can offset other Australian-source income but not foreign income" }
  },
  "depreciation_strategy_non_resident": {
    "quantity_surveyor_report_required": { "type": "bool", "value": true },
    "capital_works_depreciation_available": { "type": "bool", "value": true },
    "plant_and_equipment_depreciation_available": { "type": "bool", "value": "<initial>", "note": "Only for new properties or substantial renovations post May 2017" },
    "total_depreciation_year_1": { "type": "money", "value": "<initial>" }
  },
  "cgt_projection_non_resident": {
    "fifty_percent_discount_eligible": { "type": "bool", "value": false, "note": "Removed for foreign residents from 8 May 2012" },
    "ppor_exemption_eligible": { "type": "bool", "value": false, "note": "Removed for foreign residents on disposal from 1 July 2020 with limited transition" },
    "estimated_capital_gain_at_exit": { "type": "money", "value": "<initial>" },
    "cgt_payable_at_marginal_rate": { "type": "money", "value": "<initial>" },
    "foreign_resident_capital_gains_withholding_at_sale": { "type": "money", "value": "<initial>", "note": "12.5% (NSW/VIC) withholding on sale price by purchaser for properties >$750k" }
  },
  "vn_side_tax_implications": {
    "vn_tax_on_au_rental_income": { "type": "string", "value": "<initial>" },
    "vn_tax_on_au_capital_gain": { "type": "string", "value": "<initial>" },
    "au_vn_tax_treaty_relief_available": { "type": "bool", "value": "<initial>" },
    "foreign_tax_credit_for_au_tax_paid_in_vn": { "type": "bool", "value": "<initial>" }
  },
  "annual_compliance_au": {
    "au_tax_return_required": { "type": "bool", "value": true },
    "tax_agent_fees_annual": { "type": "money_per_year", "value": "<initial>" }
  }
}
```

**Outcome schema:** `tax_structure_non_resident_summary`

```jsonc
{
  "type": "tax_structure_non_resident_summary",
  "fields": {
    "recommended_entity": "enum",
    "rental_withholding_rate": "percentage",
    "annual_au_tax_payable_on_rental": "money",
    "negative_gearing_available_against_au_income": "bool",
    "annual_depreciation_year_1": "money",
    "cgt_at_exit_estimate": "money",
    "frcgw_at_sale_estimate": "money",
    "vn_tax_treaty_relief_applicable": "bool",
    "annual_compliance_cost_au": "money"
  }
}
```

---

### 8. cash_position (foreign + investor cost stack)

**Goal:** Compute cash needs — *combines Mode B foreign-buyer regulatory imposts (FIRB + surcharge + FX) with Mode C investor costs (entity setup, larger deposit, QS report)*.

**Inputs:** `investor_profile_foreign.outcome` + `property_fit_investor_foreign.outcome` + `firb_status` + `tax_structure_non_resident_summary`

**KB anchors:** Mode B cash_position anchors + Mode C cash_position anchors + `kb.non-resident.investment-loan-deposit-requirements`

**Renderer:** `calculator`

**UI tab hint:** Cash calculator

**Parameters:**

```jsonc
{
  "inputs": {
    "property_price_aud": { "type": "money", "value": "<from_property_assessment>" },
    "available_capital_aud_equivalent": { "type": "money", "value": "<from_investor_profile>" },
    "firb_fee_payable": { "type": "money", "value": "<from_firb_workflow>" }
  },
  "deposit": {
    "minimum_required_percentage_non_resident_investment_loan": { "type": "percentage", "value": "<initial>", "note": "Typically 30%+ for non-resident investment loans" },
    "typical_required_percentage": { "type": "percentage", "value": 30 },
    "minimum_required_amount": { "type": "money", "value": "<initial>" },
    "recommended_amount": { "type": "money", "value": "<initial>" }
  },
  "stamp_duty_and_surcharge": {
    "standard_stamp_duty": { "type": "money", "value": "<initial>" },
    "foreign_buyer_surcharge_percentage": { "type": "percentage", "value": "<initial>", "derived_from": "property_fit_investor_foreign.state" },
    "foreign_buyer_surcharge_amount": { "type": "money", "value": "<initial>" },
    "total_state_duty_payable": { "type": "money", "value": "<initial>" }
  },
  "firb_costs": {
    "firb_application_fee": { "type": "money", "value": "<from_firb_workflow>" }
  },
  "fx_costs": {
    "transfer_amount_aud": { "type": "money", "value": "<initial>" },
    "estimated_fx_spread_percentage": { "type": "percentage", "value": 1.5 },
    "estimated_fx_cost": { "type": "money", "value": "<initial>" }
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
    "applicable": { "type": "bool", "value": "<initial>", "derived_from": "tax_structure_non_resident.recommended_entity" },
    "au_company_or_trust_setup": { "type": "money", "value": "<initial>" }
  },
  "reserve_buffer": {
    "months_of_repayments_recommended": { "type": "integer", "value": 9, "note": "Higher than Mode B (6) and Mode C (6) — non-resident lender plus investment property compounds reserve expectation" },
    "amount": { "type": "money", "value": "<initial>" }
  },
  "totals": {
    "total_cash_required_at_settlement": { "type": "money", "value": "<initial>" },
    "regulatory_imposts_total": { "type": "money", "value": "<initial>", "note": "FIRB + foreign-buyer surcharge + FRCGW reserve" },
    "channel_costs_total": { "type": "money", "value": "<initial>" },
    "capital_available_blended": { "type": "money", "value": "<initial>" },
    "cash_gap_or_surplus": { "type": "money", "value": "<initial>" },
    "verdict": { "type": "enum", "options": ["surplus", "tight", "short"], "value": "<initial>" }
  }
}
```

**Outcome schema:** `budget_envelope_foreign_investor`

```jsonc
{
  "type": "budget_envelope_foreign_investor",
  "fields": {
    "max_property_price_supported": "money",
    "actual_property_price": "money",
    "total_cash_required": "money",
    "regulatory_imposts_total": "money",
    "channel_costs_total": "money",
    "loan_amount": "money",
    "lvr": "percentage",
    "gap_or_surplus": "money",
    "verdict": "enum"
  }
}
```

Mode D regulatory imposts on a $1M property typically run $130–200k (FIRB application $15.5k–$45k + foreign-buyer surcharge ~$80k + no concessions); channel costs $30–60k (investor + cross-border). The full transparency breakdown is a defining trust signal.

---

### 9. cross_border_funding (from Mode B)

**Goal:** Plan cross-border capital flow — Wise/OFX, VN capital control compliance, AU AML/CTF documentation.

**Inputs:** `investor_profile_foreign.outcome` + `budget_envelope_foreign_investor`

**Same as [Mode B cross_border_funding](fhb-foreign-au.md#7-cross_border_funding--new)** with one note: Mode D `declared_purpose_category` typically defaults to `property_investment_foreign_direct_investment` rather than `student_tuition_and_living_expenses` (which is Mode B's typical category for student-funding scenarios).

**Outcome:** `transfer_plan` (same as Mode B)

---

### 10. buying_strategy (investor discipline + FIRB gate)

**Goal:** Investor-disciplined bid plan *with FIRB approval gate*.

**Inputs:** `property_fit_investor_foreign.outcome` + `budget_envelope_foreign_investor` + `firb_status` + `strategy_thesis_foreign`

**KB anchors:** Mode C buying_strategy anchors + Mode B FIRB gate anchors

**Renderer:** `buying-strategy-card`

**UI tab hint:** Buying

**Parameters:**

Combines [Mode C buying_strategy investor_anchoring](investor-domestic-au.md#8-buying_strategy-investor-tactics) with [Mode B firb_gate](fhb-foreign-au.md#8-buying_strategy-similar-to-mode-a--firb-approval-gate). Specifically:

```jsonc
{
  // all Mode C buying_strategy parameters (yield_anchored_max_price, thesis_alignment), plus:
  "firb_gate": {
    "firb_approval_required_before_contract": { "type": "bool", "value": true },
    "firb_approval_confirmed": { "type": "bool", "value": "<from_firb_workflow>" },
    "if_not_approved_offer_subject_to_firb": { "type": "bool", "value": true },
    "agent_should_block_unconditional_offer_if_no_approval": { "type": "bool", "value": true }
  },
  "conditions_to_include_in_offer": {
    "subject_to_finance": { "type": "bool", "value": true },
    "subject_to_building_pest": { "type": "bool", "value": true },
    "subject_to_satisfactory_strata_report": { "type": "bool", "value": "<initial>" },
    "subject_to_satisfactory_rental_appraisal": { "type": "bool", "value": true },
    "subject_to_firb_approval": { "type": "bool", "value": true },
    "subject_to_currency_transfer_completion": { "type": "bool", "value": "<initial>" }
  }
}
```

**Outcome schema:** `bid_plan_foreign_investor` (combines bid_plan_investor + firb_approval_status fields)

---

### 11. due_diligence (investor + cross-border docs)

**Goal:** Surface document risks *including investor-specific docs (rental appraisal, depreciation schedule) AND cross-border docs (source of funds)*.

**Inputs:** `property_fit_investor_foreign.outcome` + uploaded documents

**KB anchors:** Mode C due_diligence anchors + Mode B cross-border doc anchors

**Renderer:** `risk-flag-list` + `checklist`

**UI tab hint:** Property

**Parameters:**

Combines [Mode C investor_specific_documents](investor-domestic-au.md#9-due_diligence-investor-focus) with [Mode B cross-border documentation](fhb-foreign-au.md#9-due_diligence-similar-to-mode-a--cross-border-documentation). All FHB documents plus investor docs plus cross-border docs.

**Outcome schema:** `risk_assessment_foreign_investor`

---

### 12. settlement_prep (Mode C investor + Mode B FIRB/transfer)

**Goal:** Coordinate settlement *with entity setup, depreciation procurement, PM appointment, FIRB approval milestone, currency transfer milestone*.

**Inputs:** `property_fit_investor_foreign.outcome` + `bid_plan_foreign_investor` + `firb_status` + `transfer_plan` + `tax_structure_non_resident_summary`

**KB anchors:** Mode C settlement_prep anchors + Mode B FIRB/transfer milestone anchors

**Renderer:** `swimlane-diagram` + `checklist`

**UI tab hint:** Temporal flow

**Parameters:** Combines [Mode C investor_specific_milestones](investor-domestic-au.md#10-settlement_prep-similar-to-mode-a--entity-setup) with [Mode B firb_milestones + currency_transfer_milestones](fhb-foreign-au.md#10-settlement_prep--firb-approval-milestone--currency-transfer-milestone).

**Outcome:** `settlement_checklist_foreign` (combines investor + cross-border milestones)

---

### 13. ownership_planning_foreign_investor ★

**Goal:** Plan ongoing investment operations — *property management + portfolio growth + vacancy fee monitoring + non-resident tax compliance + currency repatriation strategy*.

**Inputs:** `property_fit_investor_foreign.outcome` + `tax_structure_non_resident_summary` + `cash_flow_projection_foreign`

**KB anchors:** Mode C ownership_planning_investor anchors + Mode B ownership_planning foreign-person anchors + `kb.foreign-investor.repatriation-strategy`, `kb.foreign-investor.frcgw-on-sale`, `kb.foreign-investor.absentee-owner-management`

**Renderer:** `data-table` + `opportunity-card`

**UI tab hint:** Portfolio

**Parameters:**

Combines Mode C `ownership_planning_investor` (property management, tax reporting, cash flow tracking, portfolio review, scale-up) with Mode B `ownership_planning` foreign-person obligations (vacancy fee, non-resident tax):

```jsonc
{
  "property_management": {
    "management_mode": { "type": "enum", "options": ["professional_pm_au_based"], "value": "professional_pm_au_based", "note": "Non-resident owners typically must use professional PM" },
    "pm_agent_appointed": { "type": "string", "value": "<initial>" },
    "pm_fee_percentage": { "type": "percentage", "value": 8, "note": "Often slightly higher for non-resident owners due to remote-owner complexity" },
    "pm_handles_withholding_remittance": { "type": "bool", "value": "<initial>" }
  },
  "vacancy_fee_monitoring": {
    "annual_occupancy_threshold_days": { "type": "integer", "value": 183 },
    "fee_if_unoccupied_below_threshold": { "type": "money", "value": "<initial>", "note": "Double the FIRB application fee from 9 April 2024" },
    "annual_declaration_deadline": { "type": "date", "value": "<initial>" },
    "occupancy_tracker_armed": { "type": "bool", "value": true }
  },
  "tax_obligations_au": {
    "annual_au_tax_return_required": { "type": "bool", "value": true },
    "rental_withholding_remittance_responsibility": { "type": "enum", "options": ["pm_agent", "owner_direct"], "value": "<initial>" },
    "tax_agent_fees_annual": { "type": "money_per_year", "value": "<initial>" },
    "land_tax_with_foreign_surcharge": { "type": "money_per_year", "value": "<initial>" }
  },
  "tax_obligations_vn": {
    "vn_tax_filing_required_on_au_income": { "type": "bool", "value": "<initial>" },
    "au_vn_treaty_relief_applied": { "type": "bool", "value": "<initial>" },
    "foreign_tax_credit_documented": { "type": "bool", "value": "<initial>" }
  },
  "repatriation_strategy": {
    "rental_income_repatriation_frequency": { "type": "enum", "options": ["monthly", "quarterly", "annually", "reinvest_in_au"], "value": "<initial>" },
    "rental_income_held_in_au_account": { "type": "bool", "value": "<initial>" },
    "fx_strategy_for_repatriation": { "type": "enum", "options": ["spot_when_needed", "scheduled_periodic", "rate_alerts", "hedged"], "value": "<initial>" }
  },
  "portfolio_growth": {
    "equity_built_in_this_property": { "type": "money", "value": "<initial>" },
    "current_lvr": { "type": "percentage", "value": "<initial>" },
    "valuation_review_cadence_months": { "type": "integer", "value": 24 },
    "next_property_target_date": { "type": "date", "value": "<initial>" },
    "expanded_portfolio_increases_firb_complexity": { "type": "bool", "value": true, "note": "Each new property requires fresh FIRB application" }
  },
  "exit_planning": {
    "frcgw_at_sale_estimate": { "type": "money", "value": "<from_tax_structure>" },
    "vn_side_tax_on_gain": { "type": "money", "value": "<initial>" },
    "estimated_net_proceeds_after_taxes": { "type": "money", "value": "<initial>" },
    "convert_to_ppor_eligibility_when_pr_granted": { "type": "bool", "value": "<initial>" }
  },
  "lifecycle_alerts": {
    "vacancy_declaration_reminder_armed": { "type": "bool", "value": true },
    "annual_tax_filing_deadline_au": { "type": "date_recurring_annual", "value": "<initial>" },
    "annual_tax_filing_deadline_vn": { "type": "date_recurring_annual", "value": "<initial>" },
    "fx_repatriation_opportunity_alerts": { "type": "bool", "value": true },
    "pr_grant_event_triggers_mode_switch": { "type": "bool", "value": true, "note": "On PR grant, switch to Mode C blueprint; benefits unlocked: 50% CGT discount on future gains, no FIRB on future purchases" }
  }
}
```

**Outcome schema:** `portfolio_position_foreign`

```jsonc
{
  "type": "portfolio_position_foreign",
  "fields": {
    "monthly_net_cash_flow_after_withholding": "money",
    "annual_au_tax_obligations": "array<string>",
    "annual_vn_tax_obligations": "array<string>",
    "vacancy_fee_at_risk_status": "enum",
    "frcgw_reserve_at_exit": "money",
    "ready_for_next_property": "bool",
    "mode_switch_eligible_on_pr": "bool",
    "alert_triggers_armed": "array<{ trigger, action }>"
  }
}
```

---

## KB anchor index summary

Mode D references ~75 KB slugs:

- 35 shared with Mode B (foreign-person components)
- 40 shared with Mode C (investor components)
- ~10 Mode-D-exclusive (non-resident tax, FRCGW, repatriation, VN-AU treaty, foreign-investor strategy)

Mode-D-exclusive slugs include: `kb.vn-tax.brackets-2026`, `kb.vn-tax.income-from-foreign-property`, `kb.non-resident.serviceability-au-lenders`, `kb.non-resident.rental-income-withholding-tax`, `kb.non-resident.cgt-no-50-percent-discount-from-2012`, `kb.non-resident.cgt-no-ppor-exemption`, `kb.non-resident.entity-options-au-property`, `kb.au-vn-tax-treaty`, `kb.foreign-investor.thesis-archetypes`, `kb.foreign-investor.currency-hedging-considerations`, `kb.foreign-investor.future-migration-pathway-considerations`, `kb.foreign-investor.repatriation-strategy`, `kb.foreign-investor.frcgw-on-sale`, `kb.foreign-investor.absentee-owner-management`, `kb.non-resident.investment-loan-deposit-requirements`.

The offline KB agent's Mode D onboarding workstream is the largest of the four — these are the most legally and operationally sensitive content domains across the blueprint set.

---

## Renderer vocabulary used

| Renderer | Used by component(s) |
|---|---|
| `summary-card` | 1 investor_profile_foreign, 2 property_assessment, 4 investment_strategy |
| `firb-workflow-card` | 3 firb_workflow, 8 cross_border_funding |
| `calculator` | 5 yield_modelling, 6 tax_structure_non_resident, 7 cash_position |
| `data-table` | 6 tax_structure_non_resident, 12 ownership_planning_foreign_investor |
| `buying-strategy-card` | 9 buying_strategy |
| `risk-flag-list` | 10 due_diligence |
| `checklist` | 8 cross_border_funding, 10 due_diligence, 11 settlement_prep |
| `swimlane-diagram` | 11 settlement_prep |
| `opportunity-card` | 12 ownership_planning_foreign_investor |

Note: Mode D does NOT use `family-view-card` by default (no parent-funding-child pattern), though it remains available as an opt-in for joint-investor or family-pool scenarios.

---

## Parameter signal vocabulary

All Mode A + B + C signals apply. Mode D introduces:

| Signal | Used for |
|---|---|
| `<from_investor_profile>` | From `investor_profile_foreign.outcome` (note: signal name reused from Mode C; resolves to Mode D variant based on blueprint context) |
| `<from_tax_structure>` | From `tax_structure_non_resident.outcome` (Mode D variant) |

**Fill-path classification.** Per [agentic-boundary.md](../architecture/agentic-boundary.md), `agent_reasoning_required: true` marks agent-path leaves. Mode-D-specific agent leaves: off-the-plan foreign-investor judgment (`property_assessment.off_the_plan_specific_considerations_for_foreign_investor.*`), investment thesis (`investment_strategy.strategy_archetype`), non-resident lender fit (`mortgage_finance.non_resident_investor_loan_shortlist`), and entity structuring (`tax_structure_non_resident.recommended_entity`). All FIRB fees / surcharges / predicates, VN tax rates / treatment / filing, withholding rates, non-resident deposit minimums, and the FX-risk note are **resolver** — rule-governed (VN cross-border tax is complex but determined by tax law + the VN–AU DTA; encode it in KB rather than reason it per turn). Valuation, strategy, and loan-structure judgment are inherited from Mode C; cross-border document-gap flags from Mode B.

---

## Cross-component output dependency graph

```
investor_profile_foreign       → outcome: investor_profile_foreign_summary
property_assessment            → outcome: property_fit_investor_foreign      (reads: investor_profile_foreign_summary)
firb_workflow                  → outcome: firb_status                         (reads: investor_profile_foreign_summary, property_fit_investor_foreign)
investment_strategy            → outcome: strategy_thesis_foreign             (reads: investor_profile_foreign_summary, property_fit_investor_foreign)
yield_modelling                → outcome: cash_flow_projection_foreign        (reads: property_fit_investor_foreign, strategy_thesis_foreign)
tax_structure_non_resident     → outcome: tax_structure_non_resident_summary  (reads: investor_profile_foreign_summary, cash_flow_projection_foreign)
cash_position                  → outcome: budget_envelope_foreign_investor    (reads: investor_profile_foreign_summary, property_fit_investor_foreign, firb_status, tax_structure_non_resident_summary)
cross_border_funding           → outcome: transfer_plan                       (reads: investor_profile_foreign_summary, budget_envelope_foreign_investor)
buying_strategy                → outcome: bid_plan_foreign_investor           (reads: property_fit_investor_foreign, budget_envelope_foreign_investor, firb_status, strategy_thesis_foreign)
due_diligence                  → outcome: risk_assessment_foreign_investor    (reads: property_fit_investor_foreign, uploaded_docs)
settlement_prep                → outcome: settlement_checklist_foreign        (reads: property_fit_investor_foreign, bid_plan_foreign_investor, firb_status, transfer_plan, tax_structure_non_resident_summary)
ownership_planning_foreign_investor → outcome: portfolio_position_foreign     (reads: property_fit_investor_foreign, tax_structure_non_resident_summary, cash_flow_projection_foreign)
```

No cycles. Mode D's pipeline has the deepest dependency graph of the four blueprints — `cash_position` reads four upstream outcomes (investor profile, property fit, FIRB status, tax structure) reflecting the combinatorial complexity of foreign + investor.

---

## Open questions / future iteration

1. **Multi-property foreign-investor portfolio** — each new property requires fresh FIRB application + foreign-buyer surcharge. The current design captures per-property; a future iteration should specify portfolio-level FIRB compliance tracking.
2. **VN-AU tax treaty specifics** — the AU-VN double tax agreement has nuances on rental income, capital gains, withholding. A future iteration should embed treaty-specific reasoning in `tax_structure_non_resident`.
3. **Mode switch on PR grant** — when a Mode D investor's AU-resident status changes (e.g., spouse becomes PR, investor migrates), the plan card should signal migration to Mode C. The current design captures the signal; a future iteration should specify the refresh UX.
4. **Currency hedging product integration** — the current design surfaces `currency_hedging_strategy` as a parameter but doesn't recommend specific hedging products. A future iteration could integrate with FX hedging providers.
5. **SMSF for Vietnamese-resident investors** — typically not available (SMSF requires Australian residency for sole purpose test), but worth explicit confirmation. A future iteration should clearly exclude or note.
6. **Sole-investor vs family-pool variations** — the current design supports `co_investor_relationship: family_pool` but doesn't fully specify the family-pool decision authority and disclosure mechanics. A future iteration should formalise.

---

## Document control

- **Status:** draft, May 2026 — fourth and final concrete blueprint (Mode D — foreign investor)
- **Author:** Strategic design synthesis (Claude + maintainer)
- **Companion blueprints:** [`fhb-domestic-au`](fhb-domestic-au.md), [`fhb-foreign-au`](fhb-foreign-au.md), [`investor-domestic-au`](investor-domestic-au.md)
- **Complexity:** Mode D is the most complex of the four blueprints — combines foreign-person regulatory regime (FIRB, surcharge, vacancy fee, AML, VN capital controls, VN PDP) with investor analytics (yield, tax structure, gearing, portfolio) plus non-resident-specific tax treatment (no CGT discount, no PPOR exemption, FRCGW on sale, AU-VN treaty).
- **Direct competitor:** HTAG AI Copilot (English / professional). Mode D's wedge is Vietnamese language + foreign-investor compliance handled natively. The Vietnamese investor segment is genuinely underserved by HTAG and all other current AU property tech.
- **Disclaimer:** This is a working spec, not regulatory, tax, or financial advice. Non-resident tax treatment, FIRB compliance, VN capital controls, AU-VN tax treaty interpretation, AML/CTF requirements, and cross-border entity structures must be verified with Australian-registered tax agents AND Vietnamese-licensed legal counsel before commitment. Wrong advice across two jurisdictions has real consequences for the user in both. The blueprint produces structured reasoning; licensed professionals confirm strategic decisions.
