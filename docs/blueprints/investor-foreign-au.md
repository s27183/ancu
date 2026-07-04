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

14 components. Borrows from Mode B (foreign-person) and Mode C (investor) with Mode D-specific adaptations marked `★`. `disposition` (14) is added by the full-temporal-flow reframe ([`../architecture/lifecycle-simulation-model.md` §8](../architecture/lifecycle-simulation-model.md)) — **design-first / dormant**, the foreign-resident-CGT path of the same dispose-phase owner.

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
| 14 disposition ★ | `base` | Dispose-phase figure-owner — sale proceeds, selling costs, loan payout, and **foreign-resident CGT** (no 50% discount, no PPOR exemption, plus FRCGW withheld at settlement of sale) over the hold horizon `H`; the full-horizon net position. Resolver, no agent leaf. *Design-first* (§8.5). |

This base-heavy structure is genuinely well-suited to Mode D's audience: Vietnam-located investors making major capital allocation decisions across borders. They need to validate the strategic shape (entity, FIRB path, currency transfer plan, tax structure, target yield) before they're ready to commit to a specific property.

```
[1] investor_profile_foreign ★ (combines Mode B buyer_profile + Mode C investor_profile)
       │   outcome: profile
       ▼
[2] property_assessment (investor lens + foreign-person filter: new-build only)
       │   inputs: profile
       │   outcome: property_fit
       ▼
[3] firb_workflow (from Mode B — mandatory)
       │   inputs: profile, property_fit
       │   outcome: firb_status
       ▼
[4] investment_strategy (investor — yield/growth/gearing; foreign-investor specific)
       │   inputs: profile, property_fit
       │   outcome: strategy_thesis
       ▼
[5] yield_modelling (from Mode C — non-resident tax aware)
       │   inputs: property_fit, strategy_thesis
       │   outcome: cash_flow_projection
       ▼
[6] tax_structure_non_resident ★ (non-resident tax variant of Mode C)
       │   inputs: profile, cash_flow_projection
       │   outcome: tax_optimised_structure
       ▼
[7] cash_position (Mode B foreign-buyer costs + Mode C investor costs)
       │   inputs: profile, property_fit, firb_status, tax_optimised_structure
       │   outcome: budget_envelope_investor
       ▼
[8] cross_border_funding (from Mode B)
       │   inputs: profile, budget_envelope_investor
       │   outcome: transfer_plan
       ▼
[9] buying_strategy (Mode C investor discipline + Mode B FIRB gate)
       │   inputs: property_fit, budget_envelope_investor, firb_status, strategy_thesis
       │   outcome: bid_plan_foreign_investor
       ▼
[10] due_diligence (Mode C investor + Mode B cross-border docs)
        inputs: property_fit, uploaded_docs
        outcome: risk_assessment_foreign_investor
       ▼
[11] settlement_prep (Mode C investor + Mode B FIRB + transfer milestones)
        inputs: property_fit, bid_plan_foreign_investor, firb_status, transfer_plan, tax_optimised_structure
        outcome: settlement_checklist_foreign
       ▼
[12] ownership_planning_foreign_investor ★ (Mode C portfolio + Mode B vacancy/tax)
        inputs: property_fit, tax_optimised_structure, cash_flow_projection
        outcome: portfolio_position_foreign
       │
       ▼
[13] disposition ★ (NEW — dispose-phase figure-owner, foreign-resident CGT + FRCGW, full-horizon net position)
        inputs: strategy_thesis (hold_period_years = H, exit_strategy), property_fit,
                cash_flow_projection, tax_optimised_structure, budget_envelope_investor
        outcome: disposition
```

> The diagram numbers are sequential reading order, not component IDs (the IDs are the scope table's 1–14; `mortgage_finance` is omitted from the sketch). `disposition` runs **last among the base figure-owners** — a pure sink reading every upstream figure-owner (acquire from `cash_position`, hold from `yield_modelling`/`tax_structure_non_resident` over `H`, the CGT determinants from `tax_structure_non_resident`) and read by none (acyclic). The foreign-resident path strips the main-residence exemption and the 50% discount and adds FRCGW (see component 14).

**UI tab mapping** for Mode D:

| UI tab | Components rendered |
|---|---|
| Overview | `investor_profile_foreign` + `property_assessment` + `strategy_thesis` summary |
| Investment strategy | `investment_strategy` (central) |
| FIRB & Funding | `firb_workflow` + `cross_border_funding` |
| Yield & Tax | `yield_modelling` + `tax_structure_non_resident` |
| Property | `property_assessment` + `due_diligence` |
| Cash calculator | `cash_position` + `disposition` (full-horizon net position: acquire → hold over `H` → dispose; horizon slider = structural what-if) |
| Buying | `buying_strategy` |
| Temporal flow | `settlement_prep` |
| Portfolio | `ownership_planning_foreign_investor` |

**Machine-readable form** — compiled to `ui_tabs` in the artifact, **canonical for the runtime** (the table above is the human view), in the canonical lifecycle order. `kind: synthesis` is a shell-composed summary; `interactive: true` is the client-side cash what-if. The `journey` tab gains `purchase_journey` (per-mode base swimlane) when Mode D content is built. Structure is authored now; **Mode D content is dormant** until `investor-foreign-au` comes in scope (see [`../architecture/plan-card-lifecycle-restoration.md`](../architecture/plan-card-lifecycle-restoration.md) §4).

```jsonc
{
  "ui_tabs": [
    { "tab_id": "overview",            "kind": "synthesis",  "components": ["investor_profile_foreign", "property_assessment", "investment_strategy"] },
    { "tab_id": "investment_strategy", "kind": "components", "components": ["investment_strategy"] },
    { "tab_id": "firb_funding",        "kind": "components", "components": ["firb_workflow", "cross_border_funding"] },
    { "tab_id": "yield_tax",           "kind": "components", "components": ["yield_modelling", "tax_structure_non_resident"] },
    { "tab_id": "cash_calculator",     "kind": "components", "interactive": true, "components": ["cash_position", "disposition"] },
    { "tab_id": "journey",             "kind": "components", "components": ["settlement_prep"] },
    { "tab_id": "property",            "kind": "components", "components": ["property_assessment", "due_diligence"] },
    { "tab_id": "buying",              "kind": "components", "components": ["buying_strategy"] },
    { "tab_id": "portfolio",           "kind": "components", "components": ["ownership_planning_foreign_investor"] }
  ]
}
```

Note: Mode D does NOT activate Mode B's Family view tab by default — Vietnam-located investors are typically solo / couple operations, not parent-funding-child. If the user invites a co-investor or family member, the platform offers the family-view layer as an opt-in.

---

## Components

### 1. investor_profile_foreign ★

**Goal:** Capture the Vietnam-located investor's situation — residency, Vietnamese tax bracket, existing AU/VN/other property holdings, investment experience, risk tolerance, investment goals, and language preferences.

**Inputs:** User questions; uploaded documents (Vietnamese passport, residency proof, prior AU FIRB approvals if any, financial statements).

**KB anchors:** `kb.firb.status-determination`, `kb.firb.established-dwelling-ban`, `kb.vn-tax.brackets-2026`, `kb.vn-tax.income-from-foreign-property`, `kb.lender.non-resident-friendly-shortlist`, `kb.investor.experience-levels`

*(Reconciled 2026-07-03 — the serviceability anchor was drafted as `kb.non-resident.serviceability-au-lenders` before P1 found the mode-agnostic equivalent already built for Mode B.)*

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

**Outcome schema:** `profile` (canonical, mode-independent identity shape — Mode D projects the
foreign-investor subset, the same discipline as `buyer_profile_foreign`/`investor_profile`; NOT a
private `profile` type. *Reconciled 2026-07-03 — see the "outcome-type
conformance" note at the end of this blueprint: the shared-component-name outcome-TYPE-stability
discipline established for Mode B/C requires this, since `firb_workflow`/`mortgage_finance`/
`cash_position`/`disposition` all dispatch by sniffing the canonical `profile` key upstream.*)

```jsonc
{
  "type": "profile",
  "fields": {
    // legal-status & tax facts — PER-APPLICANT (read as applicant.*). Mode D: 1..N Vietnam-
    // located investors, every entry a foreign person under FIRB AND non-resident for AU tax
    // (both DEFINITIONAL for Mode D — see fh_engine_fill:investor_profile_foreign/1).
    "applicants": "array<{ role, citizenship_status, firb_status, firb_required, tax }>",  // role ∈ {primary, co_investor}; per-applicant tax{ residency_for_tax, jurisdiction } (jurisdiction=AU — the AU-side-full/VN-side-placeholder scoping split)
    "applicant_count": "integer",
    "firb_required_any": "bool",                    // definitional = true for Mode D — the SINGLE household FIRB fact, read uniformly across all modes (mirrors Mode B's F14 close)
    "established_property_eligible": "bool",       // false while the ban is in force — derived from kb.firb.established-dwelling-ban (single owner of the window)
    "new_build_only_constraint": "bool",
    "off_title_parties": "array<{ role, ... }>",   // canonical array (fact-model-unification.md) — [] at base (co-investor/family-pool captured on a refine turn)
    // household-level FACTS (not verdicts)
    "assessable_income": "money_per_year",
    "foreign_sourced_income_component": "money_per_year",
    "debts": "{ hecs_balance, credit_card_limits_total, personal_loans_balance, car_loan_balance, buy_now_pay_later_balance } | null",
    "target_price_range": "money_range",
    "target_zone": "array<string>",
    "hold_horizon_years": "integer | null",
    // Mode-D-specific (genuinely unset at onboarding — captured on a refine turn)
    "vn_marginal_tax_rate": "percentage | null",
    "available_capital_aud_equivalent": "money | null",
    "experience_level": "enum | null",
    "primary_investment_goal": "enum | null",
    "currency_volatility_concern": "enum | null",
    // narrative
    "key_constraints": "array<string>",
    "key_strengths": "array<string>"
  }
}
```

---

### 2. property_assessment (investor lens + foreign-person filter)

**Goal:** Analyse the property with *both* investor metrics (yield, growth, depreciation) AND foreign-person eligibility filtering (new-build only).

**Inputs:** `property_card` + `investor_profile_foreign.outcome`

**KB anchors:** Mode C property_assessment anchors + Mode B foreign-person filter anchors + `kb.firb.eligible-property-types-foreign-persons`, `kb.firb.fee-tiers-by-value`, `kb.off-the-plan.risk-considerations`

*(Reconciled 2026-07-03 — was `kb.off-the-plan.foreign-investor-considerations`; the existing doc already grounds Mode B's `property_assessment` on off-the-plan risk for a foreign buyer restricted to new-build stock, an investor-agnostic constraint that applies identically to Mode D.)*

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

**Outcome schema:** `property_fit`

```jsonc
{
  "type": "property_fit",
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

**Inputs:** `investor_profile_foreign.outcome` + `property_fit.outcome`

**KB anchors:** `kb.firb.established-dwelling-ban`, `kb.firb.application-process`, `kb.firb.fee-schedule-current`, `kb.firb.documents-required`, `kb.firb.timelines-standard`, `kb.firb.exemption-certificates-developer`, `kb.firb.approval-conditions-typical`, `kb.firb.penalties-non-compliance`

**Renderer:** `firb-workflow-card`

**UI tab hint:** FIRB & Funding (central)

**Same as [Mode B firb_workflow](fhb-foreign-au.md#4-firb_workflow--new--replaces-mode-a-eligibility)** — no changes for Mode D. Reused **verbatim** at the engine layer (`fh_engine_firb`, confirmed unchanged at P2); inlined below in full (not just by reference) so this blueprint's own per-file registry materializes it — the compiler parses each blueprint file independently (P3, 2026-07-04 — the prose-only "same as Mode B" reference alone left this component's registry empty and broke the shared `kb.firb.established-dwelling-ban`/`kb.firb.status-determination` anchor gates once investor-foreign-au went in-scope).

**Parameters:**

```jsonc
{
  "eligibility": {
    // FIRB eligibility determination — moved here from property_assessment (firb_workflow owns FIRB verdicts).
    // Reads neutral property facts (property_fit.property_type) + profile (firb_status); resolver, not agent.
    "is_new_build_or_vacant_land": { "type": "bool", "value": "<initial>", "derived_from": "property_fit.property_type" },
    "established_dwelling_ban_applies": { "type": "bool", "value": "<initial>", "derived_from": "kb.firb.established-dwelling-ban (current date within ban_start_date..ban_end_date)", "agent_reasoning_required": false },  // resolver-derived from the KB window — not hardcoded, so it self-expires 30 Jun 2029
    "foreign_person_can_purchase": { "type": "bool", "value": "<initial>", "note": "false ⇒ firb_status.foreign_person_eligible=false ⇒ blocking_for_contract. Developer new-dwelling exemption handled in exemption_pathway below." },
    "firb_application_required": { "type": "bool", "value": true }
  },
  "application_state": {
    "current_stage": { "type": "enum", "options": ["not_started", "in_preparation", "submitted", "under_review", "approved", "approved_with_conditions", "rejected", "withdrawn"], "value": "not_started" },
    "stage_entered_at": { "type": "date", "value": "<initial>" }
  },
  "fee_calculation": {
    "property_value_tier": { "type": "enum", "options": ["under_1m", "1m_to_2m", "2m_to_3m", "3m_to_5m", "over_5m"], "value": "<initial>", "derived_from": "property_fit.price" },
    "base_application_fee": { "type": "money", "value": "<initial>" },
    "additional_fees_if_any": { "type": "money", "value": 0 },
    "total_firb_fee_payable": { "type": "money", "value": "<initial>" }
  },
  "documents_required": {
    "passport_investor": { "required": true, "uploaded": "<initial>" },
    "visa_or_residency_evidence": { "required": true, "uploaded": "<initial>" },
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
    // FIRB verdicts (authoritative — moved here from property_assessment)
    "foreign_person_eligible": "bool",          // false when foreign person + established dwelling (ban) → blocking_for_contract
    "firb_fee_tier": "enum",
    "total_firb_fee_payable": "money",
    // approval state machine
    "current_stage": "enum",
    "approval_received": "bool",
    "approval_conditions": "array<string>",
    "days_to_expected_decision": "integer",
    "blocking_for_contract": "bool",            // true while not approved OR foreign_person_eligible == false
    "documents_outstanding": "array<string>"
  }
}
```

The `blocking_for_contract` field is the critical gate downstream — `buying_strategy` will refuse to commit a bid plan and `settlement_prep` will not advance settlement milestones while FIRB approval is unconfirmed.

---

### 4. investment_strategy (foreign-investor-specific)

**Goal:** Articulate the investment thesis. Foreign-investor-specific considerations: future migration pathway, child-education-property motive, currency hedging preference, exit-on-migration plan.

**Inputs:** `investor_profile_foreign.outcome` + `property_fit.outcome`

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

**Outcome schema:** `strategy_thesis` (reused key — `investment_strategy` is the SAME component
name as Mode C's; `mortgage_finance`/`disposition` dispatch by sniffing this key upstream, so the
type must stay canonical. *Reconciled 2026-07-03, see the outcome-type conformance note.*)

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
    "migration_pathway_alignment": "enum",
    "currency_hedging_strategy": "enum",
    "is_property_aligned_with_thesis": "bool"
  }
}
```

---

### 5. mortgage_finance (non-resident investor variant)

**Goal:** Determine the **non-resident investor loan path** — the most restrictive lender pool in the AU market — with investor-grade loan structure (IO vs P&I), foreign-buyer-specific deposit requirements, and FIRB-approval-precedes-unconditional-offer gating.

**Inputs:** `investor_profile_foreign.outcome` (profile — including existing portfolio, VN-side income) + `firb_workflow.outcome` (firb_status) + `investment_strategy.outcome` (strategy_thesis — gearing type, target LVR)

**KB anchors:** `kb.lender.non-resident-investment-loan-shortlist`, `kb.non-resident.investment-loan-deposit-requirements`, `kb.lender.temp-resident-lending-policies`, `kb.loan.interest-only-vs-pi-investor`, `kb.lender.firb-approval-as-condition-precedent`, `kb.fx.loan-currency-considerations`

*(Reconciled 2026-07-03 — 4 anchors drafted for this component (`kb.lender.foreign-investor-deposit-requirements`, `kb.lender.vn-income-treatment`, `kb.lender.investment-loan-policies-non-resident`, `kb.loan.interest-only-non-resident-investor`, `kb.lender.foreign-investor-rate-premiums`) reconciled onto 3 existing/new anchors: the deposit band → `kb.non-resident.investment-loan-deposit-requirements` (shared with component 8); VN income treatment → the already-general `kb.lender.temp-resident-lending-policies`; the IO trade-off framing → the already-general `kb.loan.interest-only-vs-pi-investor`; the combination-specific facts (narrower shortlist, rental-income shading, the further rate premium, IO-availability-by-lender) folded into the new `kb.lender.non-resident-investment-loan-shortlist`.)*

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
    "rate_premium_above_domestic_investor": { "type": "percentage_range", "value": "<initial>", "note": "Typically 100–200bp above domestic investor rates" }
  },
  "loan_structure": {
    "principal_and_interest_vs_interest_only": { "type": "enum", "options": ["interest_only", "principal_and_interest"], "value": "<initial>", "agent_reasoning_required": true, "reasoning_domain": "lender_fit", "note": "Investor-typical IO for tax efficiency; non-resident IO availability varies by lender — agent reasons based on strategy thesis + lender-pool availability" },
    "interest_only_period_years": { "type": "integer", "value": "<initial>" },
    "fixed_vs_variable": { "type": "enum", "options": ["variable", "fixed_1yr", "fixed_2yr", "fixed_3yr"], "value": "<initial>", "agent_reasoning_required": true, "reasoning_domain": "lender_fit" },
    "offset_account_available_for_non_resident": { "type": "bool", "value": "<initial>", "note": "Some non-resident loans don't include offset; check per lender — a lender-capability FACT, not an agent strategy recommendation (Mode D has no AU PPOR to point an offset at, unlike Mode C's offset_strategy_recommendation)" }
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
    "recommended_lender_shortlist": "array<{ lender, reasoning, approval_likelihood }>",
    "expected_borrowing_capacity": "money_range",
    "deposit_required_percentage": "percentage",
    "deposit_required_amount": "money",
    "io_vs_pi_recommendation": "enum",
    "fixed_vs_variable": "enum",
    "rate_estimate": "percentage_range",
    "firb_dependency_acknowledged": "bool",
    "vn_income_acceptance_confirmed": "bool",
    "fx_risk_acknowledged": "bool",
    "loan_cost_estimate_year_1": "money"
  }
}
```

*(Reconciled 2026-07-04 — the first-drafted `recommended_lender`/`recommended_lender_reasoning` singular-pick pair collapsed the agent's lender_fit judgment to ONE named lender with no visible alternative, which is the exact "let the agent decide which lender to recommend" pattern the project's own ACL/credit-advice guardrail warns against (CLAUDE.md common pitfalls). Modes A/B/C all surface a `recommended_lender_shortlist` — an array of `{lender, reasoning, approval_likelihood}` the user compares and picks from, never a bare directive — and Mode D's own `non_resident_investor_loan_shortlist` Parameter already intended a shortlist; the Outcome schema just never carried it through. Reconciled onto the same `recommended_lender_shortlist` shape Mode C's `mortgage_plan` uses (same shared Python `lender_fit_investor` reasoning-domain schema, `LenderFitInvestorLeaves.recommended_lender_shortlist`) — caught live, mode-d-wedge.md P5 live-turn check.)*

*(Reconciled 2026-07-05 — the same live-turn check surfaced a second gap: this Outcome schema never carried `fixed_vs_variable` through even though it was already a drafted Parameter (`loan_structure.fixed_vs_variable` above) and the shared Python leaf-fill already computed it every turn — silently discarded by `fh_engine_mortgage:merge_agent_investor_foreign/2`, costing tokens for no rendered value. Reconciling it exposed a DEEPER issue: the fill that computed it, `fill_mortgage_finance_investor` (Mode C's function), was being reused verbatim for Mode D and told the agent it was reasoning "for a domestic investor" while asking it to judge `uses_existing_ppor_equity` — a concept that presumes an existing AU principal residence this Vietnam-located non-resident investor does not have (CLAUDE.md #9 — the agent must ground in current state, not a reused frame). Fixed by giving Mode D its OWN Python schema/prompt/domain (`LenderFitNonResidentInvestorLeaves`, reasoning_domain `lender_fit_investor_foreign`, `planner.py`) authoring only the THREE leaves that actually apply here — `io_vs_pi_recommendation`, `fixed_vs_variable`, `recommended_lender_shortlist` — correctly grounded as a non-resident foreign investor, with NO offset-strategy or PPOR-equity leaves (Mode D's blueprint has no PPOR concept at all; the VN-side capital analogue is the separate `cross_border_funding` component). `fixed_vs_variable` also uses its own 4-option enum here (`variable | fixed_1yr | fixed_2yr | fixed_3yr`, no `split_fixed_variable` — matches this component's own `loan_structure.fixed_vs_variable` Parameter above, a domestic-lender product not offered in the non-resident pool), not Mode C's 5-option `RateStructure`.)*

The `mortgage_plan` outcome feeds `yield_modelling.loan_costs`, `tax_structure_non_resident.depreciation_strategy_non_resident` (depreciation is offset against rental income which is net of loan interest), `cash_position.deposit + loan amount`, `cross_border_funding.transfer_amount` (deposit + buying costs determines transfer), `buying_strategy.firb_gate + financing condition`, `settlement_prep` (lender + FIRB + transfer milestones).

---

### 6. yield_modelling (non-resident tax aware)

**Goal:** Model rental income, expenses, cash flow — *with non-resident tax treatment*.

**Inputs:** `property_fit.outcome` + `strategy_thesis`

**KB anchors:** Mode C yield_modelling anchors + `kb.non-resident-tax.withholding-on-rental-income`

*(Reconciled 2026-07-03 — this anchor was drafted as `kb.non-resident.rental-income-withholding-tax` before P1 found the equivalent already built for Mode B, mode-agnostic. The PPOR-exemption anchor originally listed here belongs to the dispose-phase, not the hold-phase — dropped from this component; see component 7/14.)*

**Renderer:** `calculator`

**UI tab hint:** Yield & Tax

**Parameters:**

Same as [Mode C yield_modelling](investor-domestic-au.md#5-yield_modelling--new) PLUS:

```jsonc
{
  // all Mode C yield_modelling parameters, plus:
  "non_resident_tax_withholding": {
    "rental_income_withholding_applicable": { "type": "bool", "value": "<initial>", "note": "resolver-set to false with an assessment note per kb.non-resident-tax.withholding-on-rental-income — directly-held AU rent is NOT subject to a final withholding tax, it is taxed by assessment via a lodged return; do not hardcode true" },
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

**Outcome schema:** `cash_flow_projection` (reused key — `yield_modelling` is the SAME component
name as Mode C's; `tax_structure_non_resident`/`disposition` read this key upstream. *Reconciled
2026-07-03, see the outcome-type conformance note.*)

```jsonc
{
  "type": "cash_flow_projection",
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

**Hold-phase `cash_events` (full-temporal-flow wiring, design-first — §8.5/§8.6).** `yield_modelling` owns the **recurring hold-phase** flows the full-horizon financial spine places at phase `own` over `H`: rental income (`money_in`, recurring/year), operating expenses, loan interest, and the **non-resident rental withholding** (`money_out`, recurring/year), each `source_component: yield_modelling`, gated by the §13 placement check. `tax_structure_non_resident` adds the negative-gearing tax effect (offset against AU-source income only) on the same axis.

---

### 7. tax_structure_non_resident ★

**Goal:** Determine the tax-optimised structure for a *non-resident investor* — typically more constrained than Mode C (negative gearing limited; no CGT discount on properties held by foreign residents from May 2012; no PPOR exemption).

**Inputs:** `investor_profile_foreign.outcome` + `cash_flow_projection`

**KB anchors:** `kb.non-resident.tax-treatment-overview`, `kb.tax.cgt-50-percent-discount`, `kb.non-resident.entity-options-au-property`, `kb.au-vn-tax-treaty`, `kb.tax.depreciation-division-43-and-40`

*(Reconciled 2026-07-03 — 3 of these anchors already existed under a different, mode-agnostic slug. The standalone PPOR-exemption anchor was dropped as moot for an investor who never held a main residence — folded into `kb.non-resident.tax-treatment-overview`'s reasoning instead of a standalone anchor.)*

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
  "cgt_determinants_non_resident": {
    // RESOLVED (§8.5): the previously-homeless `cgt_projection_non_resident` (figures with no
    // phase, no cash_event, no owner) is reframed here as the foreign-resident CGT *determinants*.
    // The dispose-phase CGT FIGURE (gain, payable, FRCGW) is computed and OWNED by `disposition`
    // (component 14) at the `dispose` phase, where it lands as cash_events — one-computer-per-figure.
    "fifty_percent_discount_eligible": { "type": "bool", "value": false, "note": "Removed for foreign residents from 8 May 2012 (kb.tax.cgt-50-percent-discount); read by disposition" },
    "ppor_exemption_eligible": { "type": "bool", "value": false, "note": "Moot, not removed — the property was never a main residence, so the exemption in kb.tax.cgt-main-residence-exemption never applied in the first place (an investor from acquisition, unlike Mode B's owner-occupier-turned-foreign-resident case); read by disposition" },
    "cgt_marginal_rate": { "type": "percentage", "value": "<initial>", "note": "foreign-resident marginal rate the gain is taxed at; read by disposition" },
    "frcgw_applicable": { "type": "bool", "value": true, "note": "Federal (ATO) foreign-resident CGT withholding applies at settlement of sale; read by disposition" },
    "frcgw_rate_and_threshold": { "type": "string", "value": "<from kb.non-resident-tax.foreign-resident-cgt-withholding>", "note": "rate + any value threshold resolve from KB, NOT hardcoded; disposition applies them to compute the withheld amount" }
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

**Outcome schema:** `tax_optimised_structure` (reused key, NOT a private
`tax_optimised_structure` type — `tax_structure_non_resident` is a distinct component
NAME from Mode C's `tax_structure`, but `disposition`/`cash_position` dispatch their investor path
by sniffing `tax_optimised_structure`'s PRESENCE upstream, so the type must stay canonical across
both component names. *Reconciled 2026-07-03, see the outcome-type conformance note.*)

```jsonc
{
  "type": "tax_optimised_structure",
  "fields": {
    "recommended_entity": "enum",
    "rental_withholding_rate": "percentage",
    "annual_au_tax_payable_on_rental": "money",
    "negative_gearing_available_against_au_income": "bool",
    "annual_depreciation_year_1": "money",
    "cgt_discount_eligible": "bool",
    "ppor_exemption_eligible": "bool",
    "cgt_marginal_rate": "percentage",
    "frcgw_applicable": "bool",
    "vn_tax_treaty_relief_applicable": "bool",
    "annual_compliance_cost_au": "money"
  }
}
```

**Hold-phase + dispose wiring (full-temporal-flow, design-first — §8.5).** `tax_structure_non_resident` owns the **recurring hold-phase** non-resident tax effect — the annual AU tax on rental (net of the negative-gearing offset against AU-source income), placed at phase `own` over `H` — and supplies the **foreign-resident CGT determinants** (`cgt_determinants_non_resident` above: no discount, no PPOR exemption, the marginal rate, FRCGW applicability/rate) to `disposition` (component 14), which owns the **dispose-phase CGT + FRCGW figures** and their cash_events. `yield_modelling` owns the recurring rental/expense/interest/withholding hold-phase events on the same axis. The previously-homeless `cgt_projection_non_resident` is thus resolved: hold-phase effects stay here; the dispose-phase gain/payable/FRCGW land at the `dispose` phase, owned by the one computer for those figures.

---

### 8. cash_position (foreign + investor cost stack)

**Goal:** Compute cash needs — *combines Mode B foreign-buyer regulatory imposts (FIRB + surcharge + FX) with Mode C investor costs (entity setup, larger deposit, QS report)*.

**Inputs:** `investor_profile_foreign.outcome` + `property_fit.outcome` + `firb_status` + `tax_optimised_structure`

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
    "foreign_buyer_surcharge_percentage": { "type": "percentage", "value": "<initial>", "derived_from": "property_fit.state" },
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

**Outcome schema:** `budget_envelope_investor` (reused key — `cash_position` is the SAME component
name as Mode C's; `disposition` dispatches its investor acquire-figure placement by reading THIS
key. *Reconciled 2026-07-03, see the outcome-type conformance note.*)

```jsonc
{
  "type": "budget_envelope_investor",
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

**Inputs:** `investor_profile_foreign.outcome` + `budget_envelope_investor`

**KB anchors:** `kb.fx-providers.wise-ofx-bank-comparison`, `kb.fx.typical-spreads-vnd-aud`, `kb.vn-capital-controls.sbv-thresholds-2026`, `kb.vn-capital-controls.declared-purpose-categories`, `kb.au-aml-ctf.bank-due-diligence-expectations`, `kb.au-aml-ctf.source-of-funds-documentation`, `kb.vn-pdp.cross-border-data-transfer`

**Renderer:** `firb-workflow-card` (used here as a state-machine renderer for the transfer workflow) + `checklist`

**UI tab hint:** FIRB & Funding (central)

**Same as [Mode B cross_border_funding](fhb-foreign-au.md#7-cross_border_funding--new)**, inlined below in full for the same reason as `firb_workflow` above (P3, 2026-07-04 — the compiler parses each blueprint file independently; a prose-only reference left this component's registry empty too). One note: Mode D `declared_purpose_category` typically defaults to `property_investment_foreign_direct_investment` rather than `student_tuition_and_living_expenses` (which is Mode B's typical category for student-funding scenarios) — reflected in the parameter default below. Also: Mode D has no `family_context` component (solo/couple investors, no parent-funding-child pattern), so `transfer_amount` is sourced from `investor_profile_foreign.available_capital_aud_equivalent`, not `family_context` (P2, `fh_engine_cross_border`'s real branch — the tracker's original "no delta" claim was wrong).

**Parameters:**

```jsonc
{
  "transfer_amount": {
    "total_amount_aud": { "type": "money", "value": "<from_cash_position>" },
    "from_investor_capital_amount_aud": { "type": "money", "value": "<from_investor_profile_foreign>" }
  },
  "provider_selection": {
    "evaluated_providers": { "type": "array<{ provider, spread_percentage, fee, total_cost, eta_days }>", "value": [] },
    "recommended_provider": { "type": "enum", "options": ["wise", "ofx", "bank_wire_anz", "bank_wire_cba", "bank_wire_nab", "bank_wire_westpac", "other"], "value": "<initial>" },
    "recommendation_reasoning": { "type": "string", "value": "<initial>" }
  },
  "vn_capital_control_compliance": {
    "amount_exceeds_sbv_threshold": { "type": "bool", "value": "<initial>" },
    "sbv_approval_required": { "type": "bool", "value": "<initial>" },
    "declared_purpose_category": { "type": "enum", "options": ["student_tuition_and_living_expenses", "family_remittance", "property_investment_foreign_direct_investment", "other"], "value": "property_investment_foreign_direct_investment" },
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

### 10. buying_strategy (investor discipline + FIRB gate)

**Goal:** Investor-disciplined bid plan *with FIRB approval gate*.

**Inputs:** `property_fit.outcome` + `budget_envelope_investor` + `firb_status` + `strategy_thesis`

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

**Inputs:** `property_fit.outcome` + uploaded documents

**KB anchors:** Mode C due_diligence anchors + Mode B cross-border doc anchors

**Renderer:** `risk-flag-list` + `checklist`

**UI tab hint:** Property

**Parameters:**

Combines [Mode C investor_specific_documents](investor-domestic-au.md#9-due_diligence-investor-focus) with [Mode B cross-border documentation](fhb-foreign-au.md#9-due_diligence-similar-to-mode-a--cross-border-documentation). All FHB documents plus investor docs plus cross-border docs.

**Outcome schema:** `risk_assessment_foreign_investor`

---

### 12. settlement_prep (Mode C investor + Mode B FIRB/transfer)

**Goal:** Coordinate settlement *with entity setup, depreciation procurement, PM appointment, FIRB approval milestone, currency transfer milestone*.

**Inputs:** `property_fit.outcome` + `bid_plan_foreign_investor` + `firb_status` + `transfer_plan` + `tax_optimised_structure`

**KB anchors:** Mode C settlement_prep anchors + Mode B FIRB/transfer milestone anchors

**Renderer:** `swimlane-diagram` + `checklist`

**UI tab hint:** Temporal flow

**Parameters:** Combines [Mode C investor_specific_milestones](investor-domestic-au.md#10-settlement_prep-similar-to-mode-a--entity-setup) with [Mode B firb_milestones + currency_transfer_milestones](fhb-foreign-au.md#10-settlement_prep--firb-approval-milestone--currency-transfer-milestone).

**Outcome:** `settlement_checklist_foreign` (combines investor + cross-border milestones)

---

### 13. ownership_planning_foreign_investor ★

**Goal:** Plan ongoing investment operations — *property management + portfolio growth + vacancy fee monitoring + non-resident tax compliance + currency repatriation strategy*.

**Inputs:** `property_fit.outcome` + `tax_optimised_structure` + `cash_flow_projection`

**KB anchors:** Mode C ownership_planning_investor anchors + Mode B ownership_planning foreign-person anchors + `kb.foreign-investor.repatriation-strategy`, `kb.non-resident-tax.foreign-resident-cgt-withholding`, `kb.foreign-investor.absentee-owner-management`

*(Reconciled 2026-07-03 — the FRCGW anchor was drafted as `kb.foreign-investor.frcgw-on-sale` before P1 found the equivalent already built for Mode B.)*

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
    // SUPERSEDED by `disposition` (component 14, §8.5): the dispose-phase figures (FRCGW, net
    // proceeds, the gain) are OWNED there now — one-computer-per-figure. ownership_planning keeps
    // only the PPOR-conversion-on-PR planning flag; it PLACES disposition's figures, never recomputes.
    "convert_to_ppor_eligibility_when_pr_granted": { "type": "bool", "value": "<initial>", "note": "on PR grant the mode switches to C — future gains then get the 50% discount; dispose figures themselves are owned by disposition" }
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

### 14. disposition ★ (NEW — the dispose-phase figure-owner)

> **Was design-first / dormant; now active (P1, 2026-07-03).** Added by the full-temporal-flow reframe ([`../architecture/lifecycle-simulation-model.md` §8.5](../architecture/lifecycle-simulation-model.md)). This is the **foreign-resident** path of the same dispose-phase owner: Mode-A is main-residence-exempt (`cgt: null`), Mode-C is full-CGT-with-discount, Mode-D is **full-CGT, no discount, no PPOR exemption (moot, not removed — never a main residence), plus FRCGW** withheld at settlement.

**Goal:** Project the position at sale over the hold horizon `H` and own the dispose-phase figures the old `cgt_projection_non_resident` / `ownership_planning.exit_planning` placeholders lacked a single home for: sale proceeds (growth-projected), selling costs, loan payout, **foreign-resident CGT** (no 50% discount, no PPOR exemption, at the marginal rate), the **FRCGW withheld at settlement** (a prepayment credited against the final CGT — *not* an additional cost), and the **full-horizon net position**. Surface the VN-side CGT / treaty-relief note for completeness.

**Inputs:** `strategy_thesis` (`hold_period_years` = the horizon `H`, `exit_strategy`) + `property_fit.outcome` (growth indicators, purchase price) + `cash_flow_projection` (the hold-phase recurring flows to roll up) + `tax_optimised_structure` (the **CGT determinants**: `cgt_discount_eligible: false`, `ppor_exemption_eligible: false`, `cgt_marginal_rate`, `frcgw_applicable`) + `budget_envelope_investor` (acquisition cash to roll up; loan amount for the payout)

**KB anchors:** `kb.property.capital-growth-bands` (banded growth — **labelled placeholder**, re-ground before surfacing), `kb.selling-costs.agent-legal` (selling-cost bands), `kb.tax.cgt-50-percent-discount`, `kb.tax.cgt-main-residence-exemption`, `kb.non-resident-tax.foreign-resident-cgt-withholding`

*(Reconciled 2026-07-03 — the discount anchor was drafted as `kb.non-resident.cgt-no-50-percent-discount-from-2012`; the main-residence anchor (grounding the PPOR-moot reasoning) was the dangling `kb.non-resident.cgt-no-ppor-exemption`; the FRCGW anchor was `kb.foreign-investor.frcgw-on-sale` — all three reconciled to the mode-agnostic slugs already built for Mode B/C.)*

**Renderer:** `calculator` (the full-horizon net position; no new renderer — constraint #7, §8.8)

**Fill path:** **resolver, no agent leaf.** Growth/selling-costs/CGT/FRCGW are KB-grounded resolver computations, never LLM-paraphrased (the figures are removed from the agent's reach — [verify-regulated-figures-by-postcondition], [no-judge-ground-the-producer]). Banded and PENDING when the growth assumption is unparameterized (honest-partial).

**Outcome schema:** `disposition`

```jsonc
{
  "type": "disposition",
  "fields": {
    "horizon_years": "integer",
    "sale_proceeds": "money_range",                    // purchase_price grown over H; PENDING when unparameterized
    "selling_costs": "money_range",                     // agent commission + legal/marketing at sale
    "loan_payout": "money_range",                       // remaining principal at settlement of sale
    "taxable_gain": "money_range",                      // proceeds − adjusted cost base; NO 50% discount (foreign resident)
    "cgt": "money_range",                               // taxable_gain × marginal_rate — full, no discount/exemption
    "frcgw_withheld_at_settlement": "money_range",      // purchaser withholds at settlement; a PREPAYMENT credited against cgt, not an extra cost
    "cgt_status": "enum [computed, to_verify]",         // to_verify directs the user to a registered tax agent (never asserted as advice)
    "vn_side_cgt_note": "localized_text",               // VN tax on the AU gain + treaty relief (kb.au-vn-tax-treaty) — informational
    "net_proceeds": "money_range",                      // sale_proceeds − selling_costs − loan_payout − cgt  (FRCGW is inside cgt, not double-counted)
    "full_horizon_net_position": "money_range",         // acquire + hold net over H + dispose net_proceeds
    "dispose_cash_events": "array<{ phase: 'dispose', timing: 'one_off', direction, amount, counterparty, source_component: 'disposition' }>",
    "key_assumptions": "array<localized_text>"
  }
}
```

- **One-computer-per-figure.** `disposition` owns the dispose figures + the full-horizon roll-up; it **places** acquire (from `cash_position`) and hold (from `yield_modelling`/`tax_structure_non_resident` over `H`) figures, never recomputing them ([place-upstream-figures-dont-recompute]). FRCGW is modelled as a withholding *inside* the CGT figure, **not** added on top of `net_proceeds` (no double-count). It emits the dispose-phase `cash_events`, gated by §13.
- **ASIC.** CGT, FRCGW, and growth are KB-grounded estimates surfaced as ranges with the basis stated, `cgt_status: to_verify` directing the user to a registered tax agent — decision support, never tax advice.
- **`cgt_status` is always `to_verify` for Mode D by construction, not by special-casing.** `disposition`'s shared `cgt_investor/4` (the same function Mode C uses) treats a purchase as CGT-"clean"-computable only when every applicant is resident-for-tax; `investor_profile_foreign`'s canonical `profile.applicants[].tax.residency_for_tax` is always `non_resident`, so the Clean check fails unconditionally and `taxable_gain` is shown undiscounted (`cgt_discount_eligible: false` from `tax_optimised_structure`) while `cgt` stays `to_verify`. This is the intended, asserted Mode D behaviour (a conformance escript covers it), not an accident of the entity-enum mismatch.

## Outcome-type conformance (P2, 2026-07-03)

Five components share a component NAME (or a mode-independent dispatch discriminator) with an
existing Mode B/C component: `investor_profile_foreign`→`profile`, `investment_strategy`→
`strategy_thesis`, `yield_modelling`→`cash_flow_projection`, `tax_structure_non_resident`→
`tax_optimised_structure`, `cash_position`→`budget_envelope_investor`. `firb_workflow` /
`cross_border_funding` / `disposition` already declared their canonical shared types. Per the
established discipline (`fh_engine_mortgage`/`fh_engine_cash`/`fh_engine_disposition`'s own module
headers: "shared component NAME... DIFFERENT outcome shapes... same TYPE, mode-appropriate
computation"), the outcome-schema `type` field is the runtime Upstream dispatch key — the compiler
UNIONS `outcome_fields` per type across every producer (`kb_compiler.py` `build_registry`), so a
mode-specific field superset is expected and safe (Mode B's `budget_envelope`/`mortgage_plan`
already do this live). This blueprint's five "Outcome schema" jsonc blocks above were drafted with
private per-mode type names before this discipline was consistently re-applied here; reconciled to
the canonical keys 2026-07-03 (mode-d-wedge.md P2). `bid_plan_foreign_investor`,
`risk_assessment_foreign_investor`, `settlement_checklist_foreign`, `portfolio_position_foreign` stay
private (per-property/no shared discriminator dependency).

**Correction (P3, 2026-07-04).** The P2 pass above wrongly kept `property_assessment`'s outcome
private as `property_fit_investor_foreign` — P2 never ran investor-foreign-au's semantic gates (the
blueprint was still out-of-scope), so the omission wasn't visible. Flipping the blueprint in-scope at
P3 surfaced it: `firb_workflow` is Mode B's `fh_engine_firb` module reused **verbatim**, and the
shared anchor `kb.firb.established-dwelling-ban`'s own `fills` rule reads `property_fit.property_type`
— a real shared-discriminator dependency P2's per-property/no-consumer reasoning missed. Reconciled to
the canonical `property_fit` (matching Mode A/B, who already declare it) — component 2's outcome
schema below is renamed accordingly, with its investor-specific fields kept as a superset (same
mode-specific-superset discipline as every other reconciled type in this section). **Left open,
correctly deferred to `property_assessment`'s own P2-continuation build** (not decided at P3, no
resolver runs yet so nothing regresses today): `fh_engine_disposition`/`fh_engine_cash`'s already-built
Mode-D investor paths read the property outcome under `property_fit_investor` (Mode C's key), a third
name that still doesn't match `property_fit`. Whichever key `property_assessment` actually emits
under, one of the two reader sets needs a fallback — decide when that component is built.

---

## KB anchor index summary

Mode D references ~77 KB slugs:

- 35 shared with Mode B (foreign-person components)
- 40 shared with Mode C (investor components)
- 2 shared with Mode A — `kb.property.capital-growth-bands` + `kb.selling-costs.agent-legal` (component 14 `disposition`; the FRCGW-specific anchors stay Mode-D-exclusive, below)
- ~10 Mode-D-exclusive (non-resident tax, FRCGW, repatriation, VN-AU treaty, foreign-investor strategy)

**Reconciled 2026-07-03 (P1-open pass) — see `mode-d-wedge.md` P1 for the full table.** Genuinely
new (7 docs + `kb.non-resident.tax-treatment-overview` synthesis): `kb.non-resident.tax-treatment-overview`,
`kb.non-resident.entity-options-au-property`, `kb.non-resident.investment-loan-deposit-requirements`,
`kb.foreign-investor.thesis-archetypes`, `kb.foreign-investor.currency-hedging-considerations`,
`kb.foreign-investor.future-migration-pathway-considerations`, `kb.foreign-investor.repatriation-strategy`,
`kb.foreign-investor.absentee-owner-management`. VN-side placeholders (3, per the scoping decision):
`kb.vn-tax.brackets-2026`, `kb.vn-tax.income-from-foreign-property`, `kb.au-vn-tax-treaty`. Reused under
an existing slug (not new files — anchor renamed in this blueprint): `kb.lender.non-resident-friendly-shortlist`,
`kb.non-resident-tax.withholding-on-rental-income`, `kb.tax.cgt-50-percent-discount`,
`kb.non-resident-tax.foreign-resident-cgt-withholding`, `kb.tax.depreciation-division-43-and-40`. Dropped
as moot: the standalone PPOR-exemption anchor (an investor never held a main residence to lose the
exemption on — folded into the tax-treatment-overview doc's reasoning, grounded in `kb.tax.cgt-main-residence-exemption`).

The offline KB agent's Mode D onboarding workstream is the largest of the four — these are the most legally and operationally sensitive content domains across the blueprint set.

---

## Renderer vocabulary used

| Renderer | Used by component(s) |
|---|---|
| `summary-card` | 1 investor_profile_foreign, 2 property_assessment, 4 investment_strategy |
| `firb-workflow-card` | 3 firb_workflow, 8 cross_border_funding |
| `calculator` | 5 yield_modelling, 6 tax_structure_non_resident, 7 cash_position, 14 disposition |
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

**Fill-path classification.** Per [agentic-boundary.md](../architecture/agentic-boundary.md), `agent_reasoning_required: true` marks agent-path leaves. Mode-D-specific agent leaves: off-the-plan foreign-investor judgment (`property_assessment.off_the_plan_specific_considerations_for_foreign_investor.*`), investment thesis (`investment_strategy.strategy_archetype`), non-resident lender fit (`mortgage_finance.non_resident_investor_loan_shortlist`), and entity structuring (`tax_structure_non_resident.recommended_entity`). All FIRB fees / surcharges / predicates, VN tax rates / treatment / filing, withholding rates, non-resident deposit minimums, and the FX-risk note are **resolver** — rule-governed (VN cross-border tax is complex but determined by tax law + the VN–AU DTA; encode it in KB rather than reason it per turn). Valuation, strategy, and loan-structure judgment are inherited from Mode C; cross-border document-gap flags from Mode B. **All of `disposition`** (component 14) is **resolver** — growth projection, selling costs, loan payout, taxable gain, foreign-resident CGT, FRCGW, and the full-horizon roll-up are KB-grounded computations deliberately removed from the agent's reach (§8.5); the VN-side treaty note is a resolver KB lookup, not a per-turn judgment.

---

## Cross-component output dependency graph

```
investor_profile_foreign       → outcome: profile
property_assessment            → outcome: property_fit      (reads: profile)
firb_workflow                  → outcome: firb_status                         (reads: profile, property_fit)
investment_strategy            → outcome: strategy_thesis             (reads: profile, property_fit)
yield_modelling                → outcome: cash_flow_projection        (reads: property_fit, strategy_thesis)
tax_structure_non_resident     → outcome: tax_optimised_structure  (reads: profile, cash_flow_projection)
cash_position                  → outcome: budget_envelope_investor    (reads: profile, property_fit, firb_status, tax_optimised_structure)
cross_border_funding           → outcome: transfer_plan                       (reads: profile, budget_envelope_investor)
buying_strategy                → outcome: bid_plan_foreign_investor           (reads: property_fit, budget_envelope_investor, firb_status, strategy_thesis)
due_diligence                  → outcome: risk_assessment_foreign_investor    (reads: property_fit, uploaded_docs)
settlement_prep                → outcome: settlement_checklist_foreign        (reads: property_fit, bid_plan_foreign_investor, firb_status, transfer_plan, tax_optimised_structure)
ownership_planning_foreign_investor → outcome: portfolio_position_foreign     (reads: property_fit, tax_optimised_structure, cash_flow_projection)
disposition                    → outcome: disposition                       (reads: strategy_thesis, property_fit, cash_flow_projection, tax_optimised_structure, budget_envelope_investor)
```

No cycles. Mode D's pipeline has the deepest dependency graph of the four blueprints — `cash_position` reads four upstream outcomes (investor profile, property fit, FIRB status, tax structure) reflecting the combinatorial complexity of foreign + investor. `disposition` is a **pure sink** — it reads the upstream figure-owners (the horizon from `strategy_thesis`, the acquire/hold flows and CGT determinants from the cash/yield/tax outcomes) and is read by none, so it adds a leaf, not a cycle.

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
