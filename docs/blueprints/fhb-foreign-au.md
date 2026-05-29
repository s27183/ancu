# FHB plan card blueprint — Mode B (foreign-person, cross-border family)

> Part of the **Vietnamese Diaspora Property Platform** document set. See [README.md](../README.md) for the full index.
>
> **This is a working specification** consumed by:
>
> - The offline KB agent (Claude Code + maintainer) to validate KB anchor coverage and renderer consistency
> - The user-facing planning agent at session time (loaded as system prompt context, rendered as plan card UI)
> - The migration script at deployment time to publish the blueprint into the `blueprints` table (replacing the prior deploy; git holds history)
>
> Companion specs: [fhb-domestic-au.md](fhb-domestic-au.md) (Mode A). Investor blueprints (Modes C, D) to follow.

---

## Metadata

```jsonc
{
  "blueprint_id": "fhb-foreign-au",
  "effective_from": "2026-05-19",
  "effective_until": null,
  "buyer_mode": "fhb",
  "user_mode": "B",
  "audience": "Vietnam-located parents funding AU child's property OR AU temporary residents (student, 485, etc.) buying a first home in Australia. Foreign persons under FIRB.",
  "firb_required": true,
  "language_primary": "vi",
  "language_alternate": "en",
  "renderer_set": "fhb"
}
```

This blueprint serves **Mode B** users — Vietnamese parents in Vietnam funding their AU-resident child's property, AND Vietnamese students / 485 visa holders / other temporary residents in AU buying a first home. Both audience segments share the defining attribute: they are **foreign persons under FIRB** and therefore subject to:

- **Established-dwelling ban** (1 April 2025 – 30 June 2029) — new builds only
- **FIRB approval requirement** before contract
- **FIRB application fees** ($15.5k–$45k+, scaling with property value)
- **Foreign-buyer stamp duty surcharge** (~8% in NSW / VIC / QLD on top of standard duty)
- **Vacancy fee** if property is unoccupied / not genuinely available for rent ≥183 days/year
- **Non-resident tax treatment** (different CGT, restricted PPOR exemption)
- **Cross-border capital flow** (Vietnamese capital controls + Australian AML/CTF documentation + FX)

Compared to Mode A (`fhb-domestic-au`), this blueprint **replaces** the `eligibility` component (no FHG / FHSS / Help to Buy / state FHB concessions apply) with the new `firb_workflow` component and **adds** two cross-border-specific components (`family_context`, `cross_border_funding`). Other components (`buyer_profile`, `property_assessment`, `buying_strategy`, `due_diligence`, `settlement_prep`, `ownership_planning`) carry adapted parameters reflecting the foreign-person constraints.

---

## Component pipeline

The blueprint is a directed pipeline of ten components. Three are new vs Mode A (marked `★`); the rest are adapted.

### Component scope (base plan vs property addendum)

Each component has a `scope` indicating when it runs in the plan card lifecycle:

| Component | Scope | Runs when |
|---|---|---|
| 1 buyer_profile (foreign-person variant) | `base` | Onboarding |
| 2 family_context ★ | `base` | Onboarding for cross-border family scenarios |
| 3 property_assessment (foreign-person filter) | `per-property` | When specific property attached |
| 4 firb_workflow ★ | `both` | Base estimate of FIRB fee tier at onboarding (from target price range); refined per-property when specific property triggers approval workflow |
| 5 mortgage_finance (foreign-person variant) | `both` | Base estimate of non-resident-friendly lender shortlist + deposit requirements at onboarding; refined per-property when loan amount known |
| 6 cash_position (foreign-person variant) | `both` | Base estimate against target price range; refined per-property |
| 7 cross_border_funding ★ | `both` | Base capacity / provider selection at onboarding; refined per-property for specific transfer amount and timing |
| 8 buying_strategy (FIRB gate) | `per-property` | When user signals bid readiness |
| 9 due_diligence (cross-border docs) | `per-property` | When user uploads docs |
| 10 settlement_prep (FIRB + transfer milestones) | `per-property` | Activated when contract signed |
| 11 ownership_planning (vacancy fee + non-resident tax) | `both` | Base estimate of ongoing obligations at onboarding; refined per-property post-settlement |

The base plan for Mode B captures the most regulatory complexity even before a specific property: FIRB classification, family-funding capacity, cross-border transfer feasibility, foreign-buyer cost estimates. This makes Mode B's base plan genuinely valuable on its own — Vietnamese parents can validate the cross-border path before committing to a specific property.

```
[1] buyer_profile (foreign-person variant)
       │   outcome: profile_foreign
       ▼
[2] family_context ★
       │   inputs: profile_foreign
       │   outcome: family_funding_plan
       ▼
[3] property_assessment (foreign-person filter: new-build only)
       │   inputs: profile_foreign, family_funding_plan
       │   outcome: property_fit
       ▼
[4] firb_workflow ★ (replaces Mode A eligibility)
       │   inputs: profile_foreign, property_fit
       │   outcome: firb_status
       ▼
[5] cash_position (no schemes + foreign-buyer surcharge + FIRB fees + FX)
       │   inputs: profile_foreign, family_funding_plan, property_fit, firb_status
       │   outcome: budget_envelope
       ▼
[6] cross_border_funding ★
       │   inputs: family_funding_plan, budget_envelope
       │   outcome: transfer_plan
       ▼
[7] buying_strategy (similar to Mode A + FIRB approval gate)
       │   inputs: property_fit, budget_envelope, firb_status
       │   outcome: bid_plan
       ▼
[8] due_diligence (similar to Mode A + cross-border docs)
       │   inputs: property_fit, uploaded_docs
       │   outcome: risk_assessment
       ▼
[9] settlement_prep (+ FIRB approval milestone, + currency transfer milestone)
       │   inputs: property_fit, bid_plan, firb_status, transfer_plan
       │   outcome: settlement_checklist
       ▼
[10] ownership_planning (vacancy fee + non-resident tax)
        inputs: property_fit, profile_foreign
        outcome: ongoing_obligations
```

**UI tab mapping** — the 10 components are presented across additional UI tabs that activate for Mode B:

| UI tab | Components rendered | Notes |
|---|---|---|
| Overview | `buyer_profile` + `family_context` + `property_assessment` (summaries) | Bilingual headline |
| **Family view ★ (NEW for Mode B)** | `family_context` (central) — parent + child shared dashboard | Bilingual |
| **FIRB & Funding ★ (NEW for Mode B)** | `firb_workflow` + `cross_border_funding` | State machines + checklists |
| Property | `property_assessment` + `due_diligence` | New-build filter active |
| Cash calculator | `cash_position` (interactive form) | Foreign-buyer surcharge + FIRB fee + FX |
| Buying | `buying_strategy` | FIRB-approval gate enforced |
| Temporal flow | `settlement_prep` | Includes FIRB + transfer milestones |
| After you buy | `ownership_planning` | Vacancy fee + non-resident tax |

Mode B activates two new surfaces (Family view, FIRB & Funding) that don't appear in Mode A. The remaining tabs map similarly but with foreign-person-aware content.

---

## Components

### 1. buyer_profile (foreign-person variant)

**Goal:** Capture the AU-side member's situation, FIRB classification, and entry-point family context. *Distinct from Mode A: gathers visa class, residency duration, family-in-VN intent.*

**Inputs:** User questions answered in chat; any uploaded documents (visa grant letter, passport, employer letter if employed in AU, NOA if filed). No upstream component dependency — this is the pipeline entry.

**KB anchors:** `kb.firb.status-determination`, `kb.visas.au-temporary-residency-classes`, `kb.au-temp-residents.banking-and-tax-basics`

**Renderer:** `summary-card`

**UI tab hint:** Overview (collapsed) + Family view (detail)

**Parameters:**

```jsonc
{
  "user_location": {
    "physical_country": { "type": "enum", "options": ["VN", "AU", "other"], "value": "<initial>" },
    "physical_state": { "type": "enum", "options": ["NSW", "VIC", "QLD", "WA", "SA", "TAS", "ACT", "NT", "n/a"], "value": "<initial>" },
    "language_preference": { "type": "enum", "options": ["vi", "en"], "value": "vi" }
  },
  "au_member": {
    "present": { "type": "bool", "value": "<initial>" },
    "visa_class": { "type": "enum", "options": ["student_500", "graduate_485", "skilled_482", "skilled_186", "spouse_309", "spouse_820", "other_temporary", "non_resident", "permanent_resident", "citizen"], "value": "<initial>" },
    "visa_grant_date": { "type": "date", "value": "<initial>" },
    "residency_duration_months": { "type": "integer", "value": "<initial>", "derived_from": "visa_grant_date" },
    "firb_classification": { "type": "enum", "options": ["foreign_person", "not_foreign_person"], "value": "<initial>", "derived_from": "visa_class" },
    "employment_status": { "type": "enum", "options": ["full_time_au", "part_time_au", "studying_only", "not_employed_au"], "value": "<initial>" },
    "annual_income_aud": { "type": "money_per_year", "value": "<initial>" },
    "au_savings_aud": { "type": "money", "value": "<initial>" },
    "hecs_balance": { "type": "money", "value": 0 }
  },
  "vn_family_member": {
    "present": { "type": "bool", "value": "<initial>" },
    "relationship_to_au_member": { "type": "enum", "options": ["parent", "spouse_in_vn", "sibling", "other_family", "self_funding_from_vn"], "value": "<initial>" },
    "vn_residency_state_or_city": { "type": "string", "value": "<initial>" },
    "expected_to_fund": { "type": "bool", "value": "<initial>" }
  },
  "intent": {
    "intended_use": { "type": "enum", "options": ["personal_residence_for_au_member", "future_personal_when_pr_granted", "family_investment", "mixed"], "value": "<initial>" },
    "target_purchase_months": { "type": "integer", "value": "<initial>" },
    "pr_pathway_timeline_estimate": { "type": "string", "value": "<initial>" }
  }
}
```

**Outcome schema:** `profile_foreign`

```jsonc
{
  "type": "profile_foreign",
  "fields": {
    "firb_required": "bool",                       // always true for Mode B
    "au_member_present": "bool",
    "vn_funding_member_present": "bool",
    "established_property_eligible": "bool",       // always false 1 April 2025 – 30 June 2029
    "new_build_only_constraint": "bool",
    "approx_au_side_contribution_capacity": "money",
    "approx_vn_side_contribution_capacity": "money",
    "key_constraints": "array<string>",
    "key_strengths": "array<string>"
  }
}
```

---

### 2. family_context ★ (NEW for Mode B)

**Goal:** Establish the cross-border family funding plan — who contributes how much from where, and who holds decision authority. Enables the Family view surface.

**Inputs:** `buyer_profile.outcome` (profile_foreign)

**KB anchors:** `kb.vietnamese-family.financial-patterns`, `kb.cross-border.decision-authority-cultural`, `kb.bilingual.coordination-norms`

**Renderer:** `family-view-card`

**UI tab hint:** Family view (central)

**Parameters:**

```jsonc
{
  "contributors": {
    "au_member": {
      "contribution_amount": { "type": "money", "value": "<initial>" },
      "contribution_source": { "type": "array<enum>", "options": ["personal_savings_au", "personal_savings_vn", "income_from_au", "loan_from_family", "other"], "value": [] },
      "contribution_currency_origin": { "type": "enum", "options": ["AUD", "VND", "USD", "mixed"], "value": "<initial>" }
    },
    "vn_parent_or_family": {
      "contribution_amount": { "type": "money_aud_equivalent", "value": "<initial>" },
      "contribution_source": { "type": "array<enum>", "options": ["savings_vn", "sale_of_asset", "family_pool", "loan_from_au_member_to_be_repaid", "other"], "value": [] },
      "documentation_readiness": { "type": "enum", "options": ["ready", "partial", "not_started"], "value": "<initial>" }
    },
    "other_contributors": { "type": "array<contributor>", "value": [] }
  },
  "totals": {
    "total_family_capacity_aud": { "type": "money", "value": "<initial>" },
    "au_side_percentage": { "type": "percentage", "value": "<initial>" },
    "vn_side_percentage": { "type": "percentage", "value": "<initial>" }
  },
  "decision_authority": {
    "primary_decision_maker": { "type": "enum", "options": ["au_member", "vn_parent", "joint", "family_council"], "value": "<initial>" },
    "consultation_required_for_purchase": { "type": "enum", "options": ["au_member_only", "vn_parent_only", "both_required", "family_council"], "value": "<initial>" }
  },
  "coordination": {
    "bilingual_view_active": { "type": "bool", "value": false },
    "shared_dashboard_invited_parties": { "type": "array<{ name, role, language }>", "value": [] },
    "language_per_party": { "type": "object<party_id, language>", "value": {} }
  }
}
```

**Outcome schema:** `family_funding_plan`

```jsonc
{
  "type": "family_funding_plan",
  "fields": {
    "total_capacity_aud": "money",
    "contribution_breakdown": "array<{ party, amount_aud, source, currency_origin }>",
    "decision_authority": "enum",
    "bilingual_coordination_required": "bool",
    "funding_complexity_score": "integer_1_10",
    "documentation_gaps": "array<string>"
  }
}
```

---

### 3. property_assessment (foreign-person filter applied)

**Goal:** Analyse the selected property for fit — *with explicit foreign-person eligibility filtering*. Refuses established dwellings; flags new-build / off-the-plan eligibility and FIRB fee tier.

**Inputs:** `property_card` (from selection) + `buyer_profile.outcome` (profile_foreign) + `family_context.outcome`

**KB anchors:** `kb.firb.eligible-property-types-foreign-persons`, `kb.firb.fee-tiers-by-value`, `kb.property.suburb-risk-factors`, `kb.property.comparables-methodology`, `kb.strata.health-indicators`, `kb.building-types.risk-by-type`, `kb.off-the-plan.risk-considerations`

**Renderer:** `summary-card`

**UI tab hint:** Property

**Parameters:**

Same structure as [Mode A property_assessment](fhb-domestic-au.md#2-property_assessment) with these additions and changes:

```jsonc
{
  "basics": { /* same as Mode A — address, suburb, state, price, type, beds, baths, parking */ },
  "location_factors": { /* same as Mode A */ },
  "market_position": { /* same as Mode A — comparables, asking_price_vs_market, days_on_market */ },
  "strata_or_building": { /* same as Mode A */ },

  "foreign_person_eligibility": {
    "is_new_build_or_vacant_land": { "type": "bool", "value": "<initial>", "derived_from": "basics.property_type" },
    "established_dwelling_ban_applies": { "type": "bool", "value": true, "agent_reasoning_required": false },
    "foreign_person_can_purchase": { "type": "bool", "value": "<initial>" },
    "developer_exemption_certificate_held": { "type": "bool", "value": "<initial>" },
    "firb_application_required": { "type": "bool", "value": true }
  },
  "firb_fee_estimate": {
    "value_tier": { "type": "enum", "options": ["under_1m", "1m_to_2m", "2m_to_3m", "3m_to_5m", "over_5m"], "value": "<initial>", "derived_from": "basics.price" },
    "estimated_application_fee": { "type": "money", "value": "<initial>" }
  },
  "foreign_buyer_surcharge_estimate": {
    "applicable_surcharge_percentage": { "type": "percentage", "value": "<initial>", "derived_from": "basics.state" },
    "estimated_surcharge_amount": { "type": "money", "value": "<initial>" }
  },
  "fit_against_buyer": {
    "price_within_family_capacity": { "type": "bool", "value": "<initial>" },
    "lifestyle_match_score_au_member": { "type": "integer_0_10", "value": "<initial>", "agent_reasoning_required": true },
    "rentability_score_if_unoccupied": { "type": "integer_0_10", "value": "<initial>", "agent_reasoning_required": true }
  }
}
```

**Outcome schema:** `property_fit`

```jsonc
{
  "type": "property_fit",
  "fields": {
    "viability_verdict": "enum [proceed, proceed_with_caution, reconsider, blocked_foreign_person_ineligible]",
    "foreign_person_eligible": "bool",
    "firb_fee_tier": "enum",
    "foreign_buyer_surcharge_amount": "money",
    "key_strengths": "array<string>",
    "key_concerns": "array<string>",
    "market_price_assessment": "string"
  }
}
```

If `foreign_person_eligible == false` (the property is established and the buyer is a foreign person), the agent stops here and surfaces alternative new-build options. The downstream components don't fill until viability_verdict ≠ `blocked_foreign_person_ineligible`.

---

### 4. firb_workflow ★ (NEW — replaces Mode A eligibility)

**Goal:** Manage the FIRB approval state machine — fee calculation, document preparation, application submission, decision tracking. Mandatory gate before contract signing.

**Inputs:** `buyer_profile.outcome` + `property_assessment.outcome`

**KB anchors:** `kb.firb.application-process`, `kb.firb.fee-schedule-current`, `kb.firb.documents-required`, `kb.firb.timelines-standard`, `kb.firb.exemption-certificates-developer`, `kb.firb.approval-conditions-typical`, `kb.firb.penalties-non-compliance`

**Renderer:** `firb-workflow-card`

**UI tab hint:** FIRB & Funding (central)

**Parameters:**

```jsonc
{
  "application_state": {
    "current_stage": { "type": "enum", "options": ["not_started", "in_preparation", "submitted", "under_review", "approved", "approved_with_conditions", "rejected", "withdrawn"], "value": "not_started" },
    "stage_entered_at": { "type": "date", "value": "<initial>" }
  },
  "fee_calculation": {
    "property_value_tier": { "type": "enum", "options": ["under_1m", "1m_to_2m", "2m_to_3m", "3m_to_5m", "over_5m"], "value": "<from_property_assessment>" },
    "base_application_fee": { "type": "money", "value": "<initial>" },
    "additional_fees_if_any": { "type": "money", "value": 0 },
    "total_firb_fee_payable": { "type": "money", "value": "<initial>" }
  },
  "documents_required": {
    "passport_au_member": { "required": true, "uploaded": "<initial>" },
    "passport_vn_funder_if_applicable": { "required": "<initial>", "uploaded": "<initial>" },
    "visa_grant_evidence": { "required": true, "uploaded": "<initial>" },
    "property_details_contract_or_listing": { "required": true, "uploaded": "<initial>" },
    "source_of_funds_evidence": { "required": true, "uploaded": "<initial>" },
    "vendor_or_developer_details": { "required": true, "uploaded": "<initial>" }
  },
  "submission": {
    "submitted_via": { "type": "enum", "options": ["ato_online_foreign_investor_portal", "via_lawyer", "other"], "value": "ato_online_foreign_investor_portal" },
    "submitted_date": { "type": "date", "value": "<initial>" },
    "case_reference_number": { "type": "string", "value": "<initial>" }
  },
  "decision": {
    "expected_decision_window_days": { "type": "integer_range", "value": [30, 60] },
    "decision_received_date": { "type": "date", "value": "<initial>" },
    "decision_outcome": { "type": "enum", "options": ["approved", "approved_with_conditions", "rejected"], "value": "<initial>" },
    "approval_conditions": { "type": "array<string>", "value": [] },
    "approval_number": { "type": "string", "value": "<initial>" }
  },
  "exemption_pathway": {
    "developer_holds_new_dwelling_exemption_certificate": { "type": "bool", "value": "<initial>" },
    "if_yes_application_simplified": { "type": "bool", "value": "<initial>", "derived_from": "developer_holds_new_dwelling_exemption_certificate" }
  },
  "compliance_gates": {
    "must_be_approved_before_contract_signing": { "type": "bool", "value": true },
    "must_settle_within_approval_window_months": { "type": "integer", "value": 12 }
  }
}
```

**Outcome schema:** `firb_status`

```jsonc
{
  "type": "firb_status",
  "fields": {
    "current_stage": "enum",
    "total_firb_fee_payable": "money",
    "approval_received": "bool",
    "approval_conditions": "array<string>",
    "days_to_expected_decision": "integer",
    "blocking_for_contract": "bool",
    "documents_outstanding": "array<string>"
  }
}
```

The `blocking_for_contract` field is the critical gate downstream — `buying_strategy` will refuse to commit a bid plan and `settlement_prep` will not advance settlement milestones while FIRB approval is unconfirmed.

---

### 5. mortgage_finance (foreign-person variant)

**Goal:** Determine the **non-resident-friendly lender shortlist**, deposit structure (typically 30%+ for foreign-person investment / temp-resident FHB), and loan path — with explicit FIRB-approval-precedes-unconditional-offer gating.

**Inputs:** `buyer_profile.outcome` (profile_foreign — including debts, visa class) + `firb_workflow.outcome` (firb_status — applicable; fee tier)

**KB anchors:** `kb.lender.non-resident-friendly-shortlist`, `kb.lender.temp-resident-lending-policies`, `kb.lender.485-visa-treatment`, `kb.lender.foreign-buyer-deposit-requirements`, `kb.lender.firb-approval-as-condition-precedent`, `kb.lender.documentation-non-resident`, `kb.fx.loan-currency-considerations`

**Renderer:** `summary-card` + `data-table`

**UI tab hint:** FIRB & Funding

**Scope:** `both` — base estimate at onboarding using profile + target price + FIRB fee estimate; refined per-property when specific loan amount is known

**Parameters:**

```jsonc
{
  "borrowing_capacity": {
    "non_resident_lender_assessment": { "type": "money_range", "value": "<initial>", "note": "Non-resident lenders typically apply stricter serviceability — lower borrowing power than equivalent domestic profile" },
    "lender_pool_size": { "type": "integer", "value": "<initial>", "note": "Typically 5–10 lenders willing to lend to foreign persons / temp residents" },
    "income_assessment_currency": { "type": "enum", "options": ["AUD_au_employment_only", "VND_with_haircut", "blended"], "value": "<initial>" }
  },
  "deposit_requirements": {
    "minimum_required_percentage_typical": { "type": "percentage", "value": 30, "note": "Most non-resident-friendly lenders require 30%+; some accept 20% with LMI" },
    "minimum_required_amount": { "type": "money", "value": "<initial>" },
    "recommended_amount": { "type": "money", "value": "<initial>" }
  },
  "loan_path": {
    "standard_non_resident_loan": {
      "lender_shortlist": { "type": "array<{ lender, rate_range, deposit_min_percentage, processing_time }>", "value": [] },
      "rate_premium_above_standard": { "type": "percentage_range", "value": "<initial>", "note": "Typically 50–150bp above domestic owner-occupier" }
    },
    "temp_resident_loan_485_or_student_with_au_income": {
      "applicable": { "type": "bool", "value": "<initial>" },
      "lender_shortlist": { "type": "array<string>", "value": [] }
    },
    "recommended_path": { "type": "enum", "options": ["standard_non_resident", "temp_resident_with_au_income", "wait_for_pr"], "value": "<initial>" },
    "recommended_path_reasoning": { "type": "string", "value": "<initial>" }
  },
  "debt_optimisation_recommendations": {
    "hecs": {
      "current_balance": { "type": "money", "value": "<from_buyer_profile>" },
      "treatment_for_non_resident_lender": { "type": "string", "value": "<initial>" },
      "clear_before_application_recommended": { "type": "bool", "value": "<initial>" }
    },
    "credit_cards_and_loans": {
      "lender_treatment_notes": { "type": "string", "value": "<initial>" },
      "optimisations_recommended": { "type": "array<string>", "value": [] }
    }
  },
  "firb_gate": {
    "firb_approval_must_precede_unconditional_offer": { "type": "bool", "value": true },
    "lender_requires_firb_approval_before_loan_settlement": { "type": "bool", "value": true },
    "loan_offer_can_be_conditional_on_firb": { "type": "bool", "value": true }
  },
  "loan_structure": {
    "principal_and_interest_vs_interest_only": { "type": "enum", "options": ["principal_and_interest", "interest_only"], "value": "principal_and_interest", "note": "Mode B FHB usually P&I (intent is owner-occupier)" },
    "currency_of_loan": { "type": "enum", "value": "AUD", "note": "All AU property loans denominated in AUD; FX exposure is on VN-side capital flow, not loan" }
  },
  "pre_approval_workflow": {
    "documents_required_for_non_resident": { "type": "array<{ document, status }>", "value": [], "note": "Includes visa grant, passport, employment evidence (AU or VN), source-of-funds letter, FIRB application reference" },
    "expected_processing_time_days": { "type": "integer", "value": "<initial>", "note": "Non-resident loans typically 4–8 weeks vs 2–4 weeks for domestic" }
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
    "deposit_required": "money",
    "recommended_lender_shortlist": "array<{ lender, reasoning, approval_likelihood }>",
    "firb_dependency_acknowledged": "bool",
    "loan_structure_recommendation": "object",
    "pre_approval_action_plan": "array<string>"
  }
}
```

The `mortgage_plan` outcome feeds `cash_position` (loan amount + deposit), `cross_border_funding` (transfer amount = deposit + buying costs), `buying_strategy` (financing conditions in offer), `settlement_prep` (lender + FIRB milestones).

---

### 6. cash_position (foreign-person variant)

**Goal:** Compute the buyer's full cash needs at settlement — *with foreign-buyer surcharge, FIRB fees, FX spread; no scheme stacking benefits*.

**Inputs:** `buyer_profile.outcome` + `family_context.outcome` + `property_assessment.outcome` + `firb_workflow.outcome`

**KB anchors:** `kb.stamp-duty.calc-by-state`, `kb.foreign-buyer-surcharge.by-state`, `kb.firb.fee-schedule-current`, `kb.fx.typical-spreads-vnd-aud`, `kb.buyer-costs.inspections-conveyancing-fees`, `kb.cash-reserve.lender-expectations`, `kb.lmi.calculation-for-foreign-persons`

**Renderer:** `calculator`

**UI tab hint:** Cash calculator (interactive) + FIRB & Funding (summary)

**Parameters:**

```jsonc
{
  "inputs": {
    "property_price_aud": { "type": "money", "value": "<from_property_assessment>" },
    "au_member_cash_aud": { "type": "money", "value": "<from_buyer_profile>" },
    "vn_family_contribution_aud_equivalent": { "type": "money", "value": "<from_family_context>" },
    "firb_fee_payable": { "type": "money", "value": "<from_firb_workflow>" }
  },
  "deposit": {
    "minimum_required_percentage_for_foreign_person": { "type": "percentage", "value": "<initial>" },
    "typical_required_percentage": { "type": "percentage", "value": 20 },
    "minimum_required_amount": { "type": "money", "value": "<initial>" },
    "recommended_amount": { "type": "money", "value": "<initial>" }
  },
  "stamp_duty_and_surcharge": {
    "standard_stamp_duty_before_concession": { "type": "money", "value": "<initial>" },
    "first_home_concession_applicable_for_foreign_person": { "type": "bool", "value": false },
    "foreign_buyer_surcharge_percentage": { "type": "percentage", "value": "<initial>", "derived_from": "property_assessment.basics.state" },
    "foreign_buyer_surcharge_amount": { "type": "money", "value": "<initial>" },
    "total_state_duty_payable": { "type": "money", "value": "<initial>" }
  },
  "firb_costs": {
    "firb_application_fee": { "type": "money", "value": "<from_firb_workflow>" }
  },
  "fx_costs": {
    "vn_to_au_transfer_amount_aud": { "type": "money", "value": "<initial>", "derived_from": "vn_family_contribution_aud_equivalent" },
    "estimated_fx_spread_percentage": { "type": "percentage", "value": 1.5 },
    "estimated_fx_cost": { "type": "money", "value": "<initial>" }
  },
  "other_buying_costs": {
    "building_inspection": { "type": "money", "value": "<initial>" },
    "conveyancing_solicitor": { "type": "money", "value": "<initial>" },
    "lender_application_fee": { "type": "money", "value": "<initial>" },
    "mortgage_registration_fee": { "type": "money", "value": "<initial>" },
    "title_transfer_fee": { "type": "money", "value": "<initial>" },
    "first_year_building_insurance": { "type": "money", "value": "<initial>" },
    "lmi_if_lvr_above_80": { "type": "money", "value": "<initial>" }
  },
  "reserve_buffer": {
    "months_of_repayments_recommended": { "type": "integer", "value": 6, "note": "Higher than Mode A due to non-resident lender expectations" },
    "amount": { "type": "money", "value": "<initial>" }
  },
  "totals": {
    "total_cash_required_at_settlement": { "type": "money", "value": "<initial>" },
    "total_family_capacity_available": { "type": "money", "value": "<initial>" },
    "cash_gap_or_surplus": { "type": "money", "value": "<initial>" },
    "verdict": { "type": "enum", "options": ["surplus", "tight", "short"], "value": "<initial>" }
  }
}
```

**Outcome schema:** `budget_envelope`

```jsonc
{
  "type": "budget_envelope",
  "fields": {
    "max_property_price_supported": "money",
    "actual_property_price": "money",
    "total_cash_required": "money",
    "regulatory_imposts_total": "money",
    "channel_costs_total": "money",
    "family_capacity_available": "money",
    "gap_or_surplus": "money",
    "verdict": "enum [surplus, tight, short]",
    "mitigation_options_if_short": "array<string>",
    "key_assumptions": "array<string>"
  }
}
```

Note `regulatory_imposts_total` (FIRB fee + foreign-buyer surcharge + LMI if applicable) and `channel_costs_total` (everything else) are tracked separately. Mode B regulatory imposts on a $1M property typically run $90k–$160k; channel costs run $25–50k. This breakdown lets the agent surface the foreign-person-specific cost transparently to the user — a defining trust signal for the platform.

---

### 7. cross_border_funding ★ (NEW)

**Goal:** Plan the cross-border capital flow — provider selection, Vietnamese capital-control compliance, Australian AML/CTF documentation, timing, FX cost optimisation.

**Inputs:** `family_context.outcome` + `cash_position.outcome`

**KB anchors:** `kb.fx-providers.wise-ofx-bank-comparison`, `kb.fx.typical-spreads-vnd-aud`, `kb.vn-capital-controls.sbv-thresholds-2026`, `kb.vn-capital-controls.declared-purpose-categories`, `kb.au-aml-ctf.bank-due-diligence-expectations`, `kb.au-aml-ctf.source-of-funds-documentation`, `kb.vn-pdp.cross-border-data-transfer`

**Renderer:** `firb-workflow-card` (used here as a state-machine renderer for the transfer workflow) + `checklist`

**UI tab hint:** FIRB & Funding (central)

**Parameters:**

```jsonc
{
  "transfer_amount": {
    "total_amount_aud": { "type": "money", "value": "<from_cash_position>" },
    "from_vn_side_amount_aud_equivalent": { "type": "money", "value": "<from_family_context>" },
    "from_au_side_amount_aud": { "type": "money", "value": "<from_family_context>" }
  },
  "provider_selection": {
    "evaluated_providers": { "type": "array<{ provider, spread_percentage, fee, total_cost, eta_days }>", "value": [] },
    "recommended_provider": { "type": "enum", "options": ["wise", "ofx", "bank_wire_anz", "bank_wire_cba", "bank_wire_nab", "bank_wire_westpac", "other"], "value": "<initial>" },
    "recommendation_reasoning": { "type": "string", "value": "<initial>" }
  },
  "vn_capital_control_compliance": {
    "amount_exceeds_sbv_threshold": { "type": "bool", "value": "<initial>" },
    "sbv_approval_required": { "type": "bool", "value": "<initial>" },
    "declared_purpose_category": { "type": "enum", "options": ["student_tuition_and_living_expenses", "family_remittance", "property_investment_foreign_direct_investment", "other"], "value": "<initial>" },
    "purpose_documentation_required": { "type": "array<string>", "value": [] },
    "vn_bank_used": { "type": "string", "value": "<initial>" }
  },
  "au_aml_ctf_compliance": {
    "source_of_funds_letter_prepared": { "type": "bool", "value": "<initial>" },
    "supporting_documents": { "type": "array<{ document, status }>", "value": [] },
    "bank_pre_engagement_completed": { "type": "bool", "value": "<initial>" },
    "expected_enhanced_due_diligence": { "type": "bool", "value": true }
  },
  "timing_and_milestones": {
    "transfer_initiated_date": { "type": "date", "value": "<initial>" },
    "transfer_received_date": { "type": "date", "value": "<initial>" },
    "settled_in_aud_held_at": { "type": "string", "value": "<initial>" },
    "buffer_days_before_settlement": { "type": "integer", "value": 14, "note": "Recommended buffer to absorb processing delays" }
  },
  "fx_cost": {
    "estimated_total_fx_cost": { "type": "money", "value": "<initial>" },
    "vs_worst_case_bank_wire_savings": { "type": "money", "value": "<initial>" }
  }
}
```

**Outcome schema:** `transfer_plan`

```jsonc
{
  "type": "transfer_plan",
  "fields": {
    "provider": "enum",
    "total_transfer_amount_aud": "money",
    "estimated_fx_cost": "money",
    "vn_compliance_steps": "array<string>",
    "au_compliance_steps": "array<string>",
    "transfer_initiated_by_date": "date",
    "transfer_received_by_date": "date",
    "critical_path_dependencies": "array<string>"
  }
}
```

---

### 8. buying_strategy (similar to Mode A + FIRB approval gate)

**Goal:** Produce a bid plan and negotiation strategy — *with explicit FIRB approval gate before any contract is signed*.

**Inputs:** `property_assessment.outcome` + `cash_position.outcome` (budget_envelope) + `firb_workflow.outcome` (firb_status)

**KB anchors:** All Mode A buying_strategy anchors + `kb.firb.contract-conditional-on-approval`, `kb.foreign-buyer.subject-to-firb-clauses`

**Renderer:** `buying-strategy-card`

**UI tab hint:** Buying

**Parameters:**

Identical to [Mode A buying_strategy](fhb-domestic-au.md#5-buying_strategy) with these additions:

```jsonc
{
  // ... all Mode A parameters ...
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
    "subject_to_firb_approval": { "type": "bool", "value": true },
    "subject_to_currency_transfer_completion": { "type": "bool", "value": "<initial>" },
    "other_special_conditions": { "type": "array<string>", "value": [] }
  }
}
```

The agent enforces the FIRB gate: it refuses to recommend an unconditional bid until `firb_workflow.outcome.approval_received == true`.

**Outcome schema:** `bid_plan` (same as Mode A, plus `firb_approval_status` field)

---

### 9. due_diligence (similar to Mode A + cross-border documentation)

**Goal:** Surface document risks and required actions, *including cross-border documentation needs*.

**Inputs:** `property_assessment.outcome` + uploaded documents (Contract of Sale, building/pest, strata report, **+ source-of-funds documents for foreign person**)

**KB anchors:** All Mode A due_diligence anchors + `kb.firb.contract-clauses-required`, `kb.cross-border.source-of-funds-letter-template`

**Renderer:** `risk-flag-list` + `checklist`

**UI tab hint:** Property

**Parameters:**

Same as [Mode A due_diligence](fhb-domestic-au.md#6-due_diligence) plus:

```jsonc
{
  "documents_required": {
    // ... all Mode A documents ...
    "source_of_funds_letter": { "required": true, "received": "<initial>", "reviewed": "<initial>" },
    "vn_parent_documentation": { "required": "<initial>", "received": "<initial>", "reviewed": "<initial>" }
  },
  "cross_border_flags": {
    "vn_documentation_gaps": { "type": "array<{ severity, item, action }>", "value": [], "agent_reasoning_required": true },
    "au_aml_documentation_gaps": { "type": "array<{ severity, item, action }>", "value": [], "agent_reasoning_required": true }
  },
  "firb_specific_conditions_review": {
    "contract_includes_firb_approval_clause": { "type": "bool", "value": "<initial>" },
    "contract_includes_currency_transfer_buffer": { "type": "bool", "value": "<initial>" }
  }
}
```

**Outcome schema:** `risk_assessment` (same as Mode A, plus `cross_border_risks` field)

---

### 10. settlement_prep (+ FIRB approval milestone, + currency transfer milestone)

**Goal:** Coordinate the settlement timeline — *with FIRB approval and currency transfer as critical-path milestones*.

**Inputs:** `property_assessment.outcome` + `bid_plan` + `firb_workflow.outcome` + `cross_border_funding.outcome` (transfer_plan)

**KB anchors:** All Mode A settlement_prep anchors + `kb.firb.approval-to-settlement-timeline`, `kb.cross-border-settlement.coordination-best-practices`

**Renderer:** `swimlane-diagram` + `checklist`

**UI tab hint:** Temporal flow

**Parameters:**

Same as [Mode A settlement_prep](fhb-domestic-au.md#7-settlement_prep) plus:

```jsonc
{
  // ... all Mode A parameters ...
  "firb_milestones": {
    "firb_application_submitted": { "type": "milestone", "value": { "status": "<initial>", "due_date": "<initial>" } },
    "firb_approval_received": { "type": "milestone", "value": { "status": "<initial>", "due_date": "<initial>" } },
    "firb_approval_in_force_through_settlement": { "type": "milestone", "value": { "status": "<initial>", "due_date": "<initial>" } }
  },
  "currency_transfer_milestones": {
    "transfer_initiated_vn_side": { "type": "milestone", "value": { "status": "<initial>", "due_date": "<initial>" } },
    "sbv_compliance_documented": { "type": "milestone", "value": { "status": "<initial>", "due_date": "<initial>" } },
    "au_bank_aml_due_diligence_completed": { "type": "milestone", "value": { "status": "<initial>", "due_date": "<initial>" } },
    "funds_received_in_aud_trust_account": { "type": "milestone", "value": { "status": "<initial>", "due_date": "<initial>" } }
  },
  "language_specific_counterparties": {
    "vietnamese_speaking_conveyancer": { "type": "string", "value": "<initial>" },
    "vietnamese_speaking_immigration_lawyer_if_needed": { "type": "string", "value": "<initial>" }
  }
}
```

**Outcome schema:** `settlement_checklist` (same as Mode A, plus `firb_critical_path_status` and `transfer_critical_path_status` fields)

---

### 11. ownership_planning (foreign-person variant — vacancy fee + non-resident tax)

**Goal:** Project ongoing costs and obligations — *with foreign-person specific vacancy fee monitoring and non-resident tax treatment*.

**Inputs:** `property_assessment.outcome` + `buyer_profile.outcome`

**KB anchors:** All Mode A ownership_planning anchors except `kb.land-tax.ppor-exemption` (not applicable). Plus: `kb.firb.vacancy-fee-rules-2026`, `kb.firb.vacancy-fee-double-from-2024`, `kb.non-resident-tax.cgt-no-ppor-exemption`, `kb.non-resident-tax.withholding-on-rental-income`, `kb.non-resident-tax.foreign-resident-cgt-withholding`

**Renderer:** `data-table` + `opportunity-card`

**UI tab hint:** After you buy

**Parameters:**

Same as [Mode A ownership_planning](fhb-domestic-au.md#8-ownership_planning) with these critical differences:

```jsonc
{
  "monthly_obligations": { /* same as Mode A */ },
  "quarterly_obligations": { /* same as Mode A */ },
  "annual_obligations": {
    "building_insurance_premium": { "type": "money_per_year", "value": "<initial>" },
    "contents_insurance_optional": { "type": "money_per_year", "value": "<initial>" },
    "land_tax_check": { "type": "enum", "options": ["applicable_for_foreign_person", "to_verify"], "value": "applicable_for_foreign_person", "note": "Foreign owners pay land tax including surcharge in most states; no PPOR exemption" },
    "non_resident_tax_filing_required": { "type": "bool", "value": "<initial>" }
  },
  "foreign_person_specific_obligations": {
    "vacancy_fee_monitoring": {
      "annual_occupancy_threshold_days": { "type": "integer", "value": 183 },
      "fee_if_unoccupied_below_threshold": { "type": "money", "value": "<initial>", "note": "Double the FIRB application fee from 9 April 2024" },
      "annual_declaration_deadline": { "type": "date", "value": "<initial>" },
      "current_year_occupancy_status": { "type": "enum", "options": ["compliant_owner_occupier", "compliant_genuinely_rented", "at_risk", "non_compliant"], "value": "<initial>" },
      "occupancy_tracker_armed": { "type": "bool", "value": "<initial>" }
    },
    "non_resident_tax_obligations": {
      "rental_income_withholding_applicable": { "type": "bool", "value": "<initial>" },
      "cgt_on_eventual_sale_treatment": { "type": "string", "value": "Foreign-resident CGT applies; no PPOR exemption available for foreign-resident periods" },
      "annual_tax_filing_strategy": { "type": "string", "value": "<initial>" }
    }
  },
  "lifecycle_alerts": {
    "vacancy_declaration_reminder_armed": { "type": "bool", "value": true },
    "pr_grant_event_triggers_mode_switch": { "type": "bool", "value": true, "note": "When user becomes PR/citizen, switch to Mode A or C blueprint" },
    "refi_review_cadence_months": { "type": "integer", "value": 24 }
  }
}
```

**Outcome schema:** `ongoing_obligations`

```jsonc
{
  "type": "ongoing_obligations",
  "fields": {
    "total_monthly_outgoings_estimate": "money",
    "total_annual_outgoings_estimate": "money",
    "vacancy_fee_at_risk_amount": "money",
    "current_year_occupancy_status": "enum",
    "non_resident_tax_filing_required": "bool",
    "alert_triggers_armed": "array<{ trigger, action }>",
    "mode_switch_eligible": "bool"
  }
}
```

The `mode_switch_eligible` field signals when the user's status has changed (e.g., PR granted, citizenship granted) — at which point the platform offers to migrate the plan card to Mode A (fhb-domestic-au) or Mode C (investor-domestic-au) blueprint.

---

## KB anchor index (for this blueprint)

42 slugs referenced. Italics mark Mode B-only anchors (not in Mode A).

| Slug | Component(s) | Owns |
|---|---|---|
| `kb.firb.status-determination` | 1, 4 | How to determine FIRB classification from visa/citizenship status |
| *`kb.visas.au-temporary-residency-classes`* | 1 | AU temporary residency visa classes and their FIRB implications |
| *`kb.au-temp-residents.banking-and-tax-basics`* | 1 | Banking and tax basics for AU temporary residents |
| *`kb.vietnamese-family.financial-patterns`* | 2 | Vietnamese family financial pooling patterns, decision authority norms |
| *`kb.cross-border.decision-authority-cultural`* | 2 | Cultural patterns of cross-border family decision-making |
| *`kb.bilingual.coordination-norms`* | 2 | Bilingual coordination patterns for VN-AU families |
| *`kb.firb.eligible-property-types-foreign-persons`* | 3 | What property types foreign persons can buy (new build / vacant land only) |
| *`kb.firb.fee-tiers-by-value`* | 3, 4 | FIRB application fee tiers by property value |
| `kb.property.suburb-risk-factors` | 3 | Suburb-level risk |
| `kb.property.comparables-methodology` | 3 | Comparable sales methodology |
| `kb.strata.health-indicators` | 3, 8 | Strata report red flags |
| `kb.building-types.risk-by-type` | 3 | Risk profiles by property type |
| *`kb.off-the-plan.risk-considerations`* | 3 | Off-the-plan specific risks (relevant since foreign persons restricted to new builds) |
| *`kb.firb.application-process`* | 4 | FIRB application end-to-end process |
| *`kb.firb.fee-schedule-current`* | 4, 5 | Current FIRB fee schedule (2025–26 cycle) |
| *`kb.firb.documents-required`* | 4 | Standard FIRB application document list |
| *`kb.firb.timelines-standard`* | 4 | Standard FIRB decision timelines |
| *`kb.firb.exemption-certificates-developer`* | 4 | Developer new-dwelling exemption certificate pathway |
| *`kb.firb.approval-conditions-typical`* | 4 | Typical FIRB approval conditions |
| *`kb.firb.penalties-non-compliance`* | 4 | Penalties for FIRB non-compliance |
| `kb.stamp-duty.calc-by-state` | 5 | Stamp duty by state |
| *`kb.foreign-buyer-surcharge.by-state`* | 5 | Foreign-buyer stamp duty surcharge by state |
| *`kb.fx.typical-spreads-vnd-aud`* | 5, 6 | Typical VND/AUD FX spreads by provider |
| `kb.buyer-costs.inspections-conveyancing-fees` | 5 | Typical buyer-side costs |
| `kb.cash-reserve.lender-expectations` | 5 | Lender expectations (higher buffer for non-resident) |
| *`kb.lmi.calculation-for-foreign-persons`* | 5 | LMI calculation when LVR >80% for foreign person |
| *`kb.fx-providers.wise-ofx-bank-comparison`* | 6 | FX provider comparison for VN-AU transfers |
| *`kb.vn-capital-controls.sbv-thresholds-2026`* | 6 | SBV outbound transfer thresholds requiring approval |
| *`kb.vn-capital-controls.declared-purpose-categories`* | 6 | Declared-purpose categories for SBV transfers |
| *`kb.au-aml-ctf.bank-due-diligence-expectations`* | 6 | AU bank enhanced due diligence on cross-border funds |
| *`kb.au-aml-ctf.source-of-funds-documentation`* | 6 | Source-of-funds documentation standards |
| *`kb.vn-pdp.cross-border-data-transfer`* | 6 | Vietnamese PDP Decree 13/2023 cross-border transfer requirements |
| `kb.auction.rules-by-state` | 7 | Auction rules |
| `kb.cooling-off.by-state` | 7, 9 | Cooling-off periods |
| `kb.negotiation.patterns-by-market-condition` | 7 | Negotiation patterns |
| `kb.agent-tactics.detection` | 7 | Agent tactics detection |
| *`kb.firb.contract-conditional-on-approval`* | 7 | Subject-to-FIRB-approval contract clauses |
| *`kb.foreign-buyer.subject-to-firb-clauses`* | 7 | Standard FIRB contract conditions |
| `kb.contract-of-sale.review-points-by-state` | 8 | Standard CoS review |
| `kb.s32.review-points` | 8 | Section 32 review (VIC) |
| `kb.building-pest.interpretation` | 8 | Building and pest report interpretation |
| `kb.strata-report.red-flags` | 8 | Strata report red flags |
| `kb.special-conditions.standard-set` | 8 | Standard special conditions |
| *`kb.firb.contract-clauses-required`* | 8 | FIRB-required contract clauses for foreign person |
| *`kb.cross-border.source-of-funds-letter-template`* | 8 | Source-of-funds letter template |
| `kb.settlement.process-by-state` | 9 | Settlement process by state |
| `kb.pexa.settlement` | 9 | PEXA mechanics |
| `kb.insurance.timing-of-risk-pass` | 9 | Insurance timing |
| `kb.lender-docs.standard-timeline` | 9 | Lender document timeline |
| *`kb.firb.approval-to-settlement-timeline`* | 9 | FIRB approval to settlement timeline |
| *`kb.cross-border-settlement.coordination-best-practices`* | 9 | Cross-border settlement coordination |
| `kb.ongoing-costs.rates-water-strata` | 10 | Ongoing cost ranges |
| `kb.refi.windows-and-triggers` | 10 | Refi windows |
| `kb.maintenance.budget-by-property-type` | 10 | Maintenance budget heuristics |
| *`kb.firb.vacancy-fee-rules-2026`* | 10 | FIRB vacancy fee rules |
| *`kb.firb.vacancy-fee-double-from-2024`* | 10 | Doubled vacancy fee from 9 April 2024 |
| *`kb.non-resident-tax.cgt-no-ppor-exemption`* | 10 | Foreign resident CGT — no PPOR exemption |
| *`kb.non-resident-tax.withholding-on-rental-income`* | 10 | Non-resident rental income withholding |
| *`kb.non-resident-tax.foreign-resident-cgt-withholding`* | 10 | Foreign resident CGT withholding on sale |

---

## Renderer vocabulary used

This blueprint uses 10 of the constrained renderer vocabulary defined in [§11.9 in architecture.md](../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification):

| Renderer | Used by component(s) |
|---|---|
| `summary-card` | 1 buyer_profile, 3 property_assessment |
| `family-view-card` | 2 family_context (Mode B exclusive) |
| `firb-workflow-card` | 4 firb_workflow (Mode B exclusive), 6 cross_border_funding |
| `calculator` | 5 cash_position |
| `buying-strategy-card` | 7 buying_strategy |
| `risk-flag-list` | 8 due_diligence |
| `checklist` | 6 cross_border_funding, 8 due_diligence, 9 settlement_prep |
| `swimlane-diagram` | 9 settlement_prep |
| `data-table` | 10 ownership_planning |
| `opportunity-card` | 10 ownership_planning |

Mode B activates two Mode-B-exclusive renderers (`family-view-card`, `firb-workflow-card`) that don't appear in Mode A.

---

## Parameter signal vocabulary

This blueprint uses the same signal placeholders as Mode A, with one addition for Mode B:

| Signal | Used for |
|---|---|
| `<initial>` | Never-filled parameter — most common |
| `<from_property_card>` | Pulled from property selection |
| `<from_buyer_profile>` | Pulled from `buyer_profile.outcome` |
| `<from_family_context>` | Pulled from `family_context.outcome` (Mode B exclusive) |
| `<from_property_assessment>` | Pulled from `property_assessment.outcome` |
| `<from_firb_workflow>` | Pulled from `firb_workflow.outcome` (Mode B exclusive) |
| `<from_cash_position>` | Pulled from `cash_position.outcome` |

**Fill-path classification.** Per [agentic-boundary.md](../architecture/agentic-boundary.md), a leaf carrying `agent_reasoning_required: true` is agent-path; all others resolve deterministically. Mode B's FIRB mechanics (classification, eligibility predicate, fee + surcharge schedules) and cross-border compliance (SBV threshold, declared-purpose category, provider selection, withholding) are **all resolver** — rules and lookups. The only Mode-B-specific agent leaves are the subjective fit scores (`property_assessment.fit_against_buyer.lifestyle_match_score_au_member`, `rentability_score_if_unoccupied`) and the cross-border document-gap flags (`due_diligence.cross_border_flags.*`). Shared components (`buying_strategy`, `due_diligence` base, `settlement_prep`, `ownership_planning`) inherit Mode A's classification.

---

## Cross-component output dependency graph

```
buyer_profile          → outcome: profile_foreign
family_context         → outcome: family_funding_plan       (reads: profile_foreign)
property_assessment    → outcome: property_fit              (reads: profile_foreign, family_funding_plan)
firb_workflow          → outcome: firb_status               (reads: profile_foreign, property_fit)
cash_position          → outcome: budget_envelope           (reads: profile_foreign, family_funding_plan, property_fit, firb_status)
cross_border_funding   → outcome: transfer_plan             (reads: family_funding_plan, budget_envelope)
buying_strategy        → outcome: bid_plan                  (reads: property_fit, budget_envelope, firb_status)
due_diligence          → outcome: risk_assessment           (reads: property_fit, uploaded_docs)
settlement_prep        → outcome: settlement_checklist      (reads: property_fit, bid_plan, firb_status, transfer_plan)
ownership_planning     → outcome: ongoing_obligations       (reads: property_fit, profile_foreign)
```

No cycles. Mode B specifically adds two critical-path dependencies: `firb_status` blocks `buying_strategy` (no unconditional bid without FIRB approval) and `transfer_plan` is a critical-path input to `settlement_prep` (currency transfer is on the settlement critical path).

---

## Open questions / future iteration

These deferred from the current design:

1. **Mode switch on PR grant** — when the AU member becomes PR or citizen, the user is no longer a foreign person. The plan card should signal a mode switch to `fhb-domestic-au` or `investor-domestic-au`. The current design captures this signal but doesn't specify the refresh UX; a future iteration should specify.
2. **Multi-jurisdiction tax planning** — Vietnamese parents may face Vietnamese tax implications on funding AU property. This blueprint doesn't address VN-side tax obligations. A future iteration should add a `vn_side_tax_implications` component or sub-component.
3. **Family decision rollback** — if the VN parent decides not to fund after AU member commits, what's the rollback path? A future iteration needs a `decision_rollback` workflow.
4. **Currency hedging** — large transfers exposed to VND/AUD volatility between commitment and transfer. A future iteration could add hedging guidance to `cross_border_funding`.
5. **Joint family applications** — if multiple AU-side members co-buy, the `buyer_profile` and `family_context` need to capture multiple AU members. The current design assumes a single AU member; a future iteration should support joint.

---

## Document control

- **Status:** draft, May 2026 — second concrete blueprint specification (Mode B)
- **Author:** Strategic design synthesis (Claude + maintainer)
- **Consumers:** Offline KB agent, user-facing planning agent, migration script, UI renderer layer
- **Companion blueprints:** [`fhb-domestic-au`](fhb-domestic-au.md) (Mode A — drafted). Pending: `investor-domestic-au` (Mode C), `investor-foreign-au` (Mode D).
- **Disclaimer:** This is a working spec, not a regulatory document. FIRB regulations, foreign-buyer surcharge percentages, vacancy-fee rules, Vietnamese capital control thresholds, AML/CTF requirements, and non-resident tax treatments must be confirmed against authoritative sources (resolved via kb_anchor lookups) at runtime. Wrong advice across jurisdictions has real legal consequences in both Australia and Vietnam; the blueprint must be paired with rigorous KB curation, agent reasoning verification, and Vietnam-licensed legal partnership.
