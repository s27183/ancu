// Pure plan-card model: the engine's typed outcomes as the shell reads them, plus
// the bilingual + honest-partial helpers the renderers share. Two engine invariants
// shape every field here:
//   - The engine OWNS the content language (bilingual-content.md): free-text prose
//     arrives as LocalizedText {vi, en}; figures and enums are single-valued. We pick
//     the display locale here, NEVER route content through the chrome i18n ($t).
//   - Base-scope fills are honest-partial (base-turn-honest-partial-output): a field
//     the base turn cannot yet know is null/absent, never faked. So nearly every field
//     is nullable, and renderers show absence as a calm "pending" — never a zero.
// No Svelte/DOM imports — unit-testable, mirrors onboarding.ts.

export type Lang = 'vi' | 'en';

/** Free-text prose the engine localized at the source. */
export interface LocalizedText {
    vi: string;
    en: string;
}

/** Pick the display locale from an engine LocalizedText; '' if absent (so callers can
 *  treat empty as pending). Falls back to en only if the chosen locale is missing. */
export function pick(t: LocalizedText | null | undefined, lang: Lang): string {
    if (!t) return '';
    return t[lang] || t.en || t.vi || '';
}

/** A money range [low, high] in AUD, as the engine emits `money_range`. */
export type MoneyRange = [number, number];

// --- the five base-scope outcome types (registry.outcome_types) -------------
// Every field is optional + nullable: honest-partial. Renderers read defensively.

/** buyer_profile → summary-card (outcome type `profile`). */
export interface ProfileOutcome {
    applicant_count?: number | null;
    firb_required_any?: boolean | null;
    intended_occupancy_use?: string | null;
    assessable_income?: number | null;
    // Foreign-sourced slice of assessable_income (diaspora-relevant; the engine's profile
    // outcome key carries the `_income_` infix, distinct from the write endpoint's
    // income.foreign_sourced_component). Used to SEED the cockpit field (IC5).
    foreign_sourced_income_component?: number | null;
    // Raw debt facts (IC3 framing — profile holds facts, mortgage_finance reasons). The
    // five balances/limits the serviceability resolver reads; null/absent → honest-partial.
    debts?: {
        hecs_balance?: number | null;
        credit_card_limits_total?: number | null;
        personal_loans_balance?: number | null;
        car_loan_balance?: number | null;
        buy_now_pay_later_balance?: number | null;
    } | null;
    approx_borrowing_capacity?: MoneyRange | null;
    deposit_ready_for_purchase_amount?: number | null;
    target_price_range?: MoneyRange | null;
    target_zone?: string[] | null;
    key_constraints?: LocalizedText[] | null;
    key_strengths?: LocalizedText[] | null;
    // Domestic profiles (Mode A/C/E): the ordinarily-resident assumption when an applicant
    // may be a permanent resident (kb.copy.profile assume_pr_ordinarily_resident).
    key_assumptions?: LocalizedText[] | null;
}

export interface SchemeEntry {
    name?: string | null;
    // Decision 8: benefit_value is a money_range [low, high] (base: from target_price_range;
    // per-property: narrowed to a point). null when honestly unknown (FHSS/Help-to-Buy at base).
    benefit_value?: MoneyRange | null;
    role?: string | null;
    // estimate=true marks a banded estimate (e.g. FHG LMI-avoided) vs an exact regulated figure.
    benefit_is_estimate?: boolean | null;
    notes?: LocalizedText[] | null;
}
export interface RejectedScheme {
    name?: string | null;
    reason?: LocalizedText | null;
}
/** eligibility → scheme-stack-card (outcome type `scheme_stack`). */
export interface SchemeStackOutcome {
    applicable_schemes?: SchemeEntry[] | null;
    rejected_schemes?: RejectedScheme[] | null;
    eligibility_basis?: string | null;
    total_benefit_value?: MoneyRange | null;
    stacking_constraints?: LocalizedText[] | null;
    recommended_application_order?: string[] | null;
}

export interface LenderEntry {
    lender?: string | null;
    reasoning?: LocalizedText | null;
    approval_likelihood?: string | null;
}
/** mortgage_finance → summary-card + data-table (outcome type `mortgage_plan`). FOUR
 *  different field sets share this one type (fh_engine_mortgage.erl fill_fhb / fill_fhb_
 *  foreign / fill_investor / fill_investor_foreign) — all fields optional, union of all
 *  four shapes, exactly like ProfileOutcome above. A consumer reads only the fields its
 *  mode's shape actually populates; the rest are honestly absent, not null-by-mistake. */
export interface MortgagePlanOutcome {
    // Mode A/B (fill_fhb / fill_fhb_foreign)
    recommended_path?: string | null;
    pre_approval_action_plan?: LocalizedText[] | null;
    pre_approval_expiry?: string | null;
    reapplication_required?: boolean | null;
    key_assumptions?: LocalizedText[] | null;
    loan_structure_recommendation?: {
        type?: string | null;
        currency?: string | null;
        rate?: string | null;
        offset?: string | null;
    } | null;
    // Mode B/D (foreign axis)
    deposit_required?: number | null;
    firb_dependency_acknowledged?: boolean | null;
    // Mode C (fill_investor)
    recommended_loan_structure?: {
        repayment_type?: string | null;
        rate?: string | null;
        offset?: string | null;
        uses_existing_ppor_equity?: boolean | null;
        interest_only_period_years?: number | null;
    } | null;
    offset_strategy_recommendation?: string | null;
    refinance_plan_for_portfolio_growth?: {
        usable_equity_target_lvr_pct?: number | null;
        usable_equity_with_lmi_lvr_pct?: number | null;
        equity_release_triggers_serviceability_retest?: boolean | null;
        interest_only_term_years_typical?: number | null;
        usable_equity_estimate?: number | null;
        io_period_expiry_date?: string | null;
        next_property_equity_release_target_date?: string | null;
    } | null;
    debt_optimisations_to_action?: LocalizedText[] | null;
    // Mode C/D (investor axis)
    io_vs_pi_recommendation?: string | null;
    loan_cost_estimate_year_1?: number | null;
    // Mode D (fill_investor_foreign)
    fixed_vs_variable?: string | null;
    deposit_required_percentage?: number | null;
    deposit_required_amount?: number | null;
    rate_estimate?: MoneyRange | null;
    vn_income_acceptance_confirmed?: boolean | null;
    fx_risk_acknowledged?: boolean | null;
    // shared
    expected_borrowing_capacity?: MoneyRange | null;
    recommended_lender_shortlist?: LenderEntry[] | null;
}

/** investment_strategy (Mode C/D) → summary-card (outcome type `strategy_thesis`). Two-path:
 *  `archetype`/`gearing_type`/`one_liner` are the three agent-authored leaves, merged into the
 *  resolver scaffold in the SAME base turn (fh_engine_fill.erl merge_agent/3) — real at base,
 *  not deferred to a refine turn. `target_gross_yield` is resolver-derived from `archetype` via
 *  KB defaults; `hold_period_years` is resolver-carried off profile.hold_horizon_years at base.
 *  migration_pathway_alignment/currency_hedging_strategy are Mode-D-only (absent on Mode C's
 *  investor-domestic-au — no foreign-investor lens there). */
export interface StrategyThesisOutcome {
    archetype?: string | null;
    one_liner?: string | null;
    target_gross_yield?: number | null;
    target_capital_growth?: number | null;
    gearing_type?: string | null;
    target_lvr?: number | null;
    hold_period_years?: number | null;
    exit_strategy?: string | null;
    migration_pathway_alignment?: string | null;
    currency_hedging_strategy?: string | null;
    is_property_aligned_with_thesis?: boolean | null;
}

export interface StampDuty {
    before_concession?: number | null;
    concession_applied?: number | null;
    after_concession?: number | null;
    notes?: LocalizedText[] | null;
}
// Decision 9: the NEED-side itemization. Each amount is a money_range at base (over
// the target price range), a point per-property. All nullable — honest-partial.
export interface Deposit {
    minimum_required_percentage?: number | null;
    minimum_required_amount?: MoneyRange | null;
    notes?: LocalizedText[] | null;
}
export interface OtherBuyingCosts {
    /** registration (exact) + convention bands → [lo, hi]. */
    total?: MoneyRange | null;
    /** the regulated, exact land-titles registration portion (at the range ceiling). */
    registration_exact?: number | null;
    notes?: LocalizedText[] | null;
}
export interface ReserveBuffer {
    months_of_repayments_recommended?: number | null;
    /** null at base — needs the loan repayment (a refine fact). */
    amount?: number | null;
    notes?: LocalizedText[] | null;
}
/** One money flow on the financial spine (plan-card-lifecycle §7) — the calculator's
 *  projection of the lifecycle, phase-aligned with the swimlane's `interactions`. The
 *  engine PLACES already-computed figures here (it computes none of its own); `amount`
 *  is a money_range ([v,v] for a point). `phase` matches the journey's phase ids. */
export interface CashEvent {
    id: string;
    label: LocalizedText;
    amount: MoneyRange;
    direction: 'in' | 'out';
    timing: 'one_off' | 'recurring';
    phase: string;
    counterparty?: string | null;
    period?: string | null;
    is_estimate?: boolean | null;
    source_component?: string | null;
}

/** cash_position → calculator (outcome type `budget_envelope`). */
export interface BudgetEnvelopeOutcome {
    /** The financial spine: every money flow across the lifecycle phases. */
    cash_events?: CashEvent[] | null;
    stamp_duty?: StampDuty | null;
    // NEED side (Decision 9) — real at base.
    deposit?: Deposit | null;
    other_buying_costs?: OtherBuyingCosts | null;
    reserve_buffer?: ReserveBuffer | null;
    /** NEED total AT SETTLEMENT = deposit + duty + other costs. money_range at base for
     *  Modes A/B/E's `budget_envelope`; a scalar `money` point for Modes C/D's
     *  `budget_envelope_investor` (fh_engine_cash.erl SEAMS note — a known cross-contract
     *  seam, not yet reconciled to a single shape). Consumers must accept either — see
     *  `asRange()` in `$lib/format`, which mirrors the Erlang-side `money_range/1` scalar→
     *  [v,v] upgrade `fh_engine_disposition` already applies when reading this same field. */
    total_cash_required?: MoneyRange | number | null;
    max_property_price_supported?: number | null;
    actual_property_price?: number | null;
    // HAVE side + verdict — null at base (no savings captured at onboarding; refine turn).
    cash_available?: number | null;
    gap_or_surplus?: number | null;
    verdict?: string | null;
    genuine_savings_verdict?: string | null;
    mitigation_options_if_short?: string[] | null;
    key_assumptions?: LocalizedText[] | null;
    // The FLAT summary-totals sibling shape (Mode B's `budget_envelope` and Modes C/D's
    // `budget_envelope_investor` — SAME outcome type names as the itemized fields above,
    // but NONE of stamp_duty/deposit/other_buying_costs/reserve_buffer: found 2026-07-11,
    // the renderer conformance check showed these never appearing anywhere in the shell for
    // 3 of the 5 blueprints. regulatory_imposts_total/channel_costs_total replace the
    // itemized breakdown with one FIRB+surcharge total and one everything-else total
    // (Mode B/D); family_capacity_available is Mode B's HAVE side (vs cash_available for
    // Mode A/E); loan_amount/lvr/lmi_payable are Modes C/D's loan-sizing figures.
    regulatory_imposts_total?: number | null;
    channel_costs_total?: number | null;
    family_capacity_available?: number | null;
    loan_amount?: number | null;
    lvr?: number | null;
    lmi_payable?: number | null;
}

/** yield_modelling → calculator (outcome type `cash_flow_projection`, Mode C/D). All
 *  null at base until a property is attached (fh_engine_fill.erl base_cfp/0) — every
 *  figure is a money_range EXCEPT the geared verdict (a closed 3-value enum) and
 *  annual_interest_year_1 (a scalar, representative-leverage POINT, not a band). */
export interface CashFlowProjectionOutcome {
    annual_rental_income_year_1?: MoneyRange | null;
    annual_operating_expenses_year_1?: MoneyRange | null;
    annual_interest_year_1?: number | null;
    cash_flow_before_tax_year_1?: MoneyRange | null;
    cash_flow_before_tax_per_week?: MoneyRange | null;
    gross_yield?: MoneyRange | null;
    net_yield_pre_loan?: MoneyRange | null;
    net_yield_post_loan_pre_tax?: MoneyRange | null;
    year_5_projected_cash_flow?: MoneyRange | null;
    year_10_projected_cash_flow?: MoneyRange | null;
    is_positive_neutral_or_negative_geared_pre_tax?: string | null;
    cash_events?: CashEvent[] | null;
}

/** disposition → calculator (outcome type `disposition`). The TERMINAL dispose-phase
 *  figure-owner (lifecycle-simulation-model §8): the sell-side projection over a hold
 *  horizon `H` + the full-horizon net position (buy → hold → sell). It OWNS the dispose
 *  figures and PLACES the acquire/hold figures into the roll-up (one-computer-per-figure).
 *  Honest-partial: `horizon_years` null → no projection (Mode-A long/indefinite default);
 *  `H` set but loan unknown (no income captured) → sale/selling banded, loan/net/full null.
 *  Mode-A CGT = main-residence exemption (`cgt` always null, `cgt_status` exempt|to_verify —
 *  never an estimated taxable gain; verify-regulated-figures-by-postcondition). */
export interface DispositionOutcome {
    horizon_years?: number | null;
    sale_proceeds?: MoneyRange | null;
    selling_costs?: MoneyRange | null;
    loan_payout?: MoneyRange | null;
    /** Always null on the Mode-A main-residence path (no taxable-gain estimate). */
    cgt?: MoneyRange | null;
    cgt_status?: 'exempt' | 'to_verify' | string | null;
    net_proceeds?: MoneyRange | null;
    /** THE headline: net proceeds − acquisition cash − hold costs × H. May be negative. */
    full_horizon_net_position?: MoneyRange | null;
    /** The Dispose-phase entries of the shared spine (same shape as cash_events). */
    dispose_cash_events?: CashEvent[] | null;
    key_assumptions?: LocalizedText[] | null;
}

/** existing_home_disposal → calculator (outcome type `existing_home_disposal`). Mode-E ONLY
 *  (nexthome-domestic-au.md component 3): the net proceeds of selling the buyer's CURRENT
 *  home (already owned, lived in) to fund THIS purchase — feeds cash_position's HAVE side.
 *  DISTINCT from DispositionOutcome (the future exit of the property this plan is FOR); both
 *  share the `calculator` renderer and both carry a `cgt_status` field of the same shape, so
 *  the renderer discriminates on `bridging_finance_is_placeholder` (unique to this outcome),
 *  never on `cgt_status` alone. Honest-partial: no onboarding capture of the existing home's
 *  sale price / loan balance (plan-first) — every figure is null until a refine turn supplies
 *  the buyer's own attested facts. */
export interface ExistingHomeDisposalOutcome {
    estimated_sale_price?: number | null;
    loan_payout?: {
        outstanding_balance?: number | null;
        discharge_fee?: MoneyRange | null;
        break_cost_status?: 'not_applicable' | 'to_verify' | string | null;
        total_payout?: MoneyRange | null;
    } | null;
    selling_costs?: MoneyRange | null;
    cgt?: MoneyRange | null;
    cgt_status?: 'exempt' | 'to_verify' | string | null;
    net_sale_proceeds?: MoneyRange | null;
    settlement_timing_mismatch?: boolean | null;
    bridging_finance_considered?: boolean | null;
    bridging_finance_is_placeholder?: boolean | null;
    key_assumptions?: LocalizedText[] | null;
}

/** tax_structure → data-table (outcome type `tax_optimised_structure`). The investor tax cluster:
 *  the recommended ownership entity (agent leaf), the resolver-computed gearing/CGT figures (banded
 *  where rent-derived; null until their inputs arrive), and the negative-gearing reform note — a
 *  bilingual decision-support caveat, property-conditional, NEVER null (base → the general caveat). */
export interface TaxOptimisedStructureOutcome {
    recommended_entity?: string | null;
    negative_gearing_active?: boolean | null;
    annual_tax_refund_year_1?: MoneyRange | null;
    after_tax_cash_flow_year_1?: MoneyRange | null;
    after_tax_cash_flow_per_week?: MoneyRange | null;
    total_depreciation_year_1?: number | null;
    cgt_discount_eligible?: boolean | null;
    cgt_marginal_rate?: number | null;
    cost_base_depreciation_clawback?: boolean | null;
    annual_compliance_cost?: number | null;
    /** entity setup, INDICATIVE band from kb.tax.entity-setup-costs; [lo, null] = "from lo". */
    setup_costs?: [number, number | null] | null;
    negative_gearing_reform_note?: LocalizedText | null;
}

/** tax_structure_non_resident → data-table (SAME outcome type `tax_optimised_structure`,
 *  a DIFFERENT field set — Mode D's non-resident-investor tax cluster: FRCGW/PPOR-exemption
 *  determinants disposition reads, no discount for foreign residents, VN treaty relief.
 *  Found 2026-07-11: DataTable's isTax branch read only TaxOptimisedStructureOutcome's Mode-C
 *  field names (negative_gearing_active/after_tax_cash_flow_year_1), neither of which exists
 *  on this shape — real content (gearing status, marginal rate is shared, compliance cost)
 *  silently rendered as Pending. */
export interface TaxOptimisedStructureForeignOutcome {
    recommended_entity?: string | null;
    rental_withholding_rate?: number | null;
    annual_au_tax_payable_on_rental?: number | null;
    negative_gearing_available_against_au_income?: boolean | null;
    annual_depreciation_year_1?: number | null;
    cgt_discount_eligible?: boolean | null;
    ppor_exemption_eligible?: boolean | null;
    cgt_marginal_rate?: number | null;
    frcgw_applicable?: boolean | null;
    vn_tax_treaty_relief_applicable?: boolean | null;
    annual_compliance_cost_au?: number | null;
}

export interface StatutoryBand {
    low?: number | null;
    high?: number | null;
    period?: string | null;
    components?: string[] | null;
}
export interface RecurringCosts {
    statutory_band?: StatutoryBand | null;
    strata_levies?: number | null;
    utilities?: number | null;
    building_insurance?: number | null;
    notes?: LocalizedText[] | null;
}
export interface AlertTrigger {
    trigger?: LocalizedText | null;
    action?: LocalizedText | null;
}
/** The "graduation" event — when LVR crosses the target (typ. 80%), the FHG falls away
 *  and a no-LMI refinance window opens. `estimated_year` is PENDING until a loan/savings
 *  fact lets the engine estimate it. */
export interface GraduationMilestone {
    target_lvr?: number | null;
    estimated_year?: number | null;
}
/** ownership_planning → data-table (outcome type `ongoing_obligations`). */
export interface OngoingObligationsOutcome {
    total_monthly_outgoings_estimate?: number | null;
    total_annual_outgoings_estimate?: number | null;
    maintenance_reserve_target?: number | null;
    recurring_costs_estimate?: RecurringCosts | null;
    land_tax_check?: string | null;
    graduation_milestone?: GraduationMilestone | null;
    alert_triggers_armed?: AlertTrigger[] | null;
}

// --- Investor (Mode C) outcome types ----------------------------------------
// The two renderers Mode C adds (buying-strategy-card, opportunity-card). Both have live
// producers (fh_engine_buying.erl / fh_engine_ownership.erl fill_investor/2), reachable
// today via property-attach — the "no live producer yet" claim this comment carried until
// 2026-07-11 was stale (found in the same audit that fixed the field-name drift below).

/** buying_strategy → buying-strategy-card (outcome type `bid_plan_investor`,
 *  fh_engine_buying.erl). Corrected 2026-07-11 — the renderer had drifted onto a
 *  never-real §11.9 draft shape (max_bid/walk_away/comparables/style/conditions/
 *  key_assumptions); NONE of those keys exist on the real outcome. The real shape below
 *  is grounded against fh_engine_buying.erl directly + a live filled card. Every money
 *  field is a yield-anchored BAND (the rent input is a band); max_bid_confidence is
 *  currently always null (no producer wires it yet — no merge_agent slot exists for it,
 *  unlike negotiation_style). */
export interface BidPlanInvestorOutcome {
    yield_anchored_max_price?: MoneyRange | null;
    thesis_alignment?: 'aligned' | 'stretched' | 'misaligned' | string | null;
    max_bid_value?: MoneyRange | null;
    max_bid_confidence?: number | string | null;
    max_bid_reasoning?: LocalizedText | null;
    walk_away_price?: MoneyRange | null;
    negotiation_style?: 'assertive' | 'patient' | 'early_offer' | 'low_anchor' | 'thesis_walk_away' | string | null;
    live_coach_armed?: boolean | null;
    conditions_to_request?: LocalizedText[] | null;
    /** PLACED verbatim from property_fit_investor.key_concerns — real, populated content
     *  the renderer dropped entirely before this fix (never read at all, not honest-
     *  partial-pending). */
    red_flags_to_monitor?: LocalizedText[] | null;
}

/** One modelled opportunity (rent review, equity release, scale-up). `modeled_benefit`
 *  is a banded estimate (range) or a point. */
export interface Opportunity {
    kind?: string | null;
    modeled_benefit?: MoneyRange | number | null;
    action?: LocalizedText | null;
}
/** ownership_planning_investor → opportunity-card (§11.9 { kind, modeled_benefit,
 *  action }). list-tolerant: an `opportunities[]` or a single opportunity. The PRODUCER
 *  half of the seam is closed (mode-c-wedge P5-engine 6): portfolio_position now declares +
 *  emits opportunities[] ([] at base — populates per-property). The CONSUMER half remains: the
 *  shell renders only renderers[0], so this card is unreached until dual-renderer support lands. */
export interface OpportunityCardOutcome extends Opportunity {
    opportunities?: Opportunity[] | null;
}

/** ownership_planning_investor → data-table (outcome type `portfolio_position`). The
 *  hold/operate view. `data-table` is named by THREE outcome shapes (FHB ongoing_obligations,
 *  tax_optimised_structure, this) — DataTable.svelte shape-discriminates so this rich producer
 *  isn't dropped ([[thin-surface-vs-dropped-richness]]). Two arrays are filled at base/attach
 *  (bilingual, engine-authored): annual_tax_obligations (the headline) + alert_triggers_armed.
 *  `opportunities` rides the SECOND renderer (opportunity-card), not this one. The six figure
 *  fields are honest-partial — null until post-settlement actuals. */
export interface PortfolioPositionOutcome {
    annual_tax_obligations?: LocalizedText[] | null;
    alert_triggers_armed?: AlertTrigger[] | null;
    opportunities?: Opportunity[] | null;
    monthly_net_cash_flow_actual?: number | null;
    ytd_cash_flow_vs_projection?: string | null;
    current_lvr?: number | null;
    equity_built?: number | null;
    ready_for_next_property?: boolean | null;
    portfolio_diversification_score?: number | null;
}

/** ownership_planning_foreign_investor → data-table (outcome type `portfolio_position_
 *  foreign`, Mode D). NOT PortfolioPositionOutcome reused — fh_engine_ownership.erl's
 *  fill_foreign_investor/2 is its own 8-field shape (AU/VN split tax obligations, FIRB
 *  vacancy/FRCGW figures, PR-mode-switch eligibility), all null at base pending
 *  post-acquisition actuals except the two obligation lists + alerts (KB-grounded,
 *  property-agnostic, so base-computable). */
export interface PortfolioPositionForeignOutcome {
    monthly_net_cash_flow_after_withholding?: number | null;
    vacancy_fee_at_risk_status?: string | null;
    frcgw_reserve_at_exit?: number | null;
    ready_for_next_property?: boolean | null;
    annual_au_tax_obligations?: LocalizedText[] | null;
    annual_vn_tax_obligations?: LocalizedText[] | null;
    alert_triggers_armed?: AlertTrigger[] | null;
    mode_switch_eligible_on_pr?: boolean | null;
}

// --- Foreign-buyer (Mode B) outcome types -----------------------------------
// The two renderers Mode B adds (family-view-card, firb-workflow-card — §11.9). Both
// producers are real and conformance-tested (mode-b-wedge.md P2/P3 CLOSED); no live turn
// reaches them yet (P5, base_components/1 has no Mode-B clause). None of these three
// modules emit bilingual {vi,en} prose (fh_engine_family/firb/cross_border.erl grounded
// directly) — every array field is a snake_case CODE, not free text; the shell owns the
// code→label lookup ($t, closed set + raw-fallback, mirroring thesisLabel/styleLabel).

/** One family funding contribution line. `amount_aud` is always in AUD (the field name
 *  is explicit) regardless of `currency_origin`, which names the funder's home currency
 *  (fh_engine_family:residence_currency/1 — exhaustively VND | AUD | null). `source` is
 *  always null at base (captured on a later refine turn; honest-partial). */
export interface ContributionLine {
    party?: string | null;
    amount_aud?: number | null;
    source?: string | null;
    currency_origin?: 'VND' | 'AUD' | string | null;
}
/** family_context → family-view-card (outcome type `family_funding_plan`). The
 *  cross-border family funding plan: who contributes how much from where, and who
 *  holds decision authority. `decision_authority` is always null at base (undetermined,
 *  prompt don't profile); `funding_complexity_score` floors at 1 (never guesses a
 *  family's pattern — kb.vietnamese-family.financial-patterns' own discipline extended
 *  to the resolver side). */
export interface FamilyFundingPlanOutcome {
    total_capacity_aud?: number | null;
    contribution_breakdown?: ContributionLine[] | null;
    decision_authority?: 'au_member' | 'vn_parent' | 'joint' | 'family_council' | string | null;
    bilingual_coordination_required?: boolean | null;
    funding_complexity_score?: number | null;
    documentation_gaps?: string[] | null;
}

/** firb_workflow → firb-workflow-card (outcome type `firb_status`). The FIRB approval
 *  state machine — mandatory gate before contract signing (blueprint §4). `blocking_for_
 *  contract` is the critical downstream gate: true while not approved OR foreign_person_
 *  eligible == false. */
export interface FirbStatusOutcome {
    foreign_person_eligible?: boolean | null;
    firb_fee_tier?: string | null;
    total_firb_fee_payable?: number | null;
    current_stage?:
        | 'not_started' | 'in_preparation' | 'submitted' | 'under_review'
        | 'approved' | 'approved_with_conditions' | 'rejected' | 'withdrawn'
        | string | null;
    approval_received?: boolean | null;
    approval_conditions?: string[] | null;
    days_to_expected_decision?: number | null;
    blocking_for_contract?: boolean | null;
    documents_outstanding?: string[] | null;
}

/** cross_border_funding → firb-workflow-card (used here as a state-machine renderer for
 *  the transfer workflow, per the blueprint's own note) + checklist (the compliance-step
 *  + critical-path sub-lists — Checklist.svelte's third shape). `provider`/dates stay
 *  null at base (live-quote / settlement-date dependent, not resolver-computable from
 *  facts alone). */
export interface TransferPlanOutcome {
    provider?:
        | 'wise' | 'ofx' | 'bank_wire_anz' | 'bank_wire_cba' | 'bank_wire_nab'
        | 'bank_wire_westpac' | 'other' | string | null;
    total_transfer_amount_aud?: number | null;
    estimated_fx_cost?: number | null;
    vn_compliance_steps?: string[] | null;
    au_compliance_steps?: string[] | null;
    transfer_initiated_by_date?: string | null;
    transfer_received_by_date?: string | null;
    critical_path_dependencies?: string[] | null;
}

// --- due_diligence (Mode C, Phase B) → risk-flag-list + checklist -------------
// outcome `risk_assessment_investor`. The investor due-diligence assessment. DOCUMENT-GATED
// two-path (due_diligence B): at A (no lease) the resolver fills the document PROCUREMENT
// checklist + the computable yield-vs-thesis concern, everything document-derived PENDING;
// uploading the lease (DocumentUpload → the engine `document` turn → the lease_interpretation
// leaf) flips docs_status → reviewed and adds the lease concerns/flags + overall_verdict. TWO
// renderers split the rich shape (constraint #7 — both shape-discriminate, no new renderer):
// risk-flag-list renders the RISK surface (verdict + concerns + high-severity flags),
// checklist the PROCUREMENT surface (document_checklist + actions + questions + next_action).
// estimated_negotiation_lever stays null (no KB methodology — honest-partial); no figure is
// agent-authored (§98). [[thin-surface-vs-dropped-richness]]: the producer is rich; recover it.

/** One investor due-diligence PROCUREMENT document — what to gather + why; received/reviewed
 *  flip true once the uploaded lease is interpreted (the lease entry only). */
export interface DueDiligenceDoc {
    id: string;
    name: LocalizedText;
    required: boolean;
    received: boolean;
    reviewed: boolean;
    why?: LocalizedText | null;
}
/** A surfaced investor concern — the computable yield-vs-thesis one at A, plus the lease-derived
 *  ones after review. id · severity · bilingual detail. */
export interface InvestorConcern {
    id: string;
    severity: 'low' | 'medium' | 'high';
    detail: LocalizedText;
}
/** A high-severity flag extracted from an uploaded document (here the lease) — what it is +
 *  what to do (both bilingual); source_doc names the document. */
export interface HighSeverityFlag {
    source_doc: string;
    item: LocalizedText;
    action: LocalizedText;
}
export interface RiskAssessmentInvestorOutcome {
    docs_status: 'pending_upload' | 'reviewed';
    overall_verdict: 'pending_documents' | 'low_risk' | 'proceed_with_actions' | 'high_risk';
    document_checklist?: DueDiligenceDoc[] | null;
    rental_yield_below_thesis_threshold?: boolean | null;
    investor_specific_concerns?: InvestorConcern[] | null;
    actions_before_signing?: LocalizedText[] | null;
    questions_for_vendor?: LocalizedText[] | null;
    high_severity_flags?: HighSeverityFlag[] | null;
    estimated_negotiation_lever?: MoneyRange | null;
    next_action_for_user?: LocalizedText | null;
}

// --- preparation → checklist (outcome type `readiness`) ---------------------
// The property-agnostic readiness layer (the prototype's "Before you buy"): documents
// to gather (with WHY each is needed), people to engage (role · when · why), the money
// buffer, and scheme applications to start. Bilingual prose throughout.

export interface ChecklistDoc {
    id: string;
    item: LocalizedText;
    /** not_started | in_progress | done (engine-set; no persisted user toggle yet). */
    status?: string | null;
    why?: LocalizedText | null;
}
export interface PersonToEngage {
    role: LocalizedText;
    when?: LocalizedText | null;
    why?: LocalizedText | null;
}
export interface SchemeApplication {
    scheme: string;
    action: LocalizedText;
}
export interface MoneyBuffer {
    genuine_savings_verdict?: string | null;
    reserve_buffer?: number | null;
    notes?: LocalizedText[] | null;
}
export interface PreparationOutcome {
    document_checklist?: ChecklistDoc[] | null;
    people_to_engage?: PersonToEngage[] | null;
    scheme_applications_to_prepare?: SchemeApplication[] | null;
    money_buffer?: MoneyBuffer | null;
    key_assumptions?: LocalizedText[] | null;
}

// --- settlement_prep → checklist (outcome type `settlement_checklist`) --------
// The DATED settlement critical path (engine-contract §11; fh_engine_settlement),
// RESOLVER-ONLY + per-property (Phase B). Two states keyed by dates_status:
// `pending_contract` (every due_date null — honest-partial, awaiting the user's
// attested contract dates) and `active` (each milestone back-calculated from the two
// dates, with at-risk detection). It SHARES the `checklist` renderer with
// PreparationOutcome — Checklist.svelte branches on dates_status (constraint #7: no new
// renderer; the engine names "checklist" for both). The dates are submitted via the
// settlement_prep B form (setTransactionDates, §11).

export type MilestoneStatus = 'pending' | 'done' | 'scheduled' | 'at_risk';

/** A critical-path milestone — name, back-calculated due_date (null when pending), the
 *  DAG edge to its prerequisite (null for the root, contract_signed). */
export interface SettlementMilestone {
    id: string;
    name: LocalizedText;
    due_date?: string | null;
    status: MilestoneStatus;
    dependency?: string | null;
}
/** An investor-specific milestone (entity setup, depreciation schedule, PM appointment,
 *  landlord insurance). `applicable` is false when the upstream entity needs no setup. */
export interface InvestorMilestone {
    id: string;
    name: LocalizedText;
    applicable: boolean;
    why?: LocalizedText | null;
    due_date?: string | null;
    status: MilestoneStatus;
}
/** A milestone whose due_date has passed (no completion signal exists, so "at-risk" means
 *  "the date has passed — confirm", per the engine). */
export interface AtRiskMilestone {
    name: LocalizedText;
    reason: LocalizedText;
}
export interface SettlementChecklistOutcome {
    dates_status: 'pending_contract' | 'active';
    settlement_date?: string | null;
    critical_path_milestones?: SettlementMilestone[] | null;
    investor_milestones?: InvestorMilestone[] | null;
    insurance_timing_rule?: LocalizedText | null;
    at_risk_milestones?: AtRiskMilestone[] | null;
    next_action_for_user?: LocalizedText | null;
}

// --- purchase_journey → swimlane-diagram (outcome type `journey_swimlane`) ---
// The base lifecycle spine (plan-card-lifecycle-restoration §7): phases × actors ×
// cells. The engine PLACES already-computed upstream figures on the timeline (it
// computes none of its own); `amount` is a money_range ([v,v] for a point) or null.

export type FlowMarker = 'none' | 'money_out' | 'money_in' | 'document' | 'milestone';

export interface JourneyPhase {
    id: string;
    label: LocalizedText;
}
export interface JourneyActor {
    id: string;
    label: LocalizedText;
}
export interface JourneyCell {
    phase: string;
    actor: string;
    item: LocalizedText;
    flow_marker: FlowMarker;
    amount?: MoneyRange | null;
}
/** One money flow within an interaction — who pays/sends what to whom. */
export interface InteractionFlow {
    label: LocalizedText;
    direction: 'in' | 'out';
    amount?: MoneyRange | null;
}
/** Who deals with whom in a phase (the swimlane's "who talks to whom" — same shared
 *  flows as cash_events, the two spines' common primitive). actor ids match `actors`. */
export interface JourneyInteraction {
    phase: string;
    from_actor: string;
    to_actor: string;
    flows?: InteractionFlow[] | null;
}
export interface JourneySwimlaneOutcome {
    phases?: JourneyPhase[] | null;
    actors?: JourneyActor[] | null;
    cells?: JourneyCell[] | null;
    interactions?: JourneyInteraction[] | null;
    key_assumptions?: LocalizedText[] | null;
}

// --- phase_playbook → checklist + risk-flag-list (outcome `phase_playbook`) --
// The actionable layer of the legal/temporal spine (the Flow view's drill-down):
// per-phase action checklists + KB-grounded risks. The engine PLACES this — actions
// LINK to figures by id (budget_ref → a cash_event.id, amount joined at render; never
// a placed amount) and to backing components by id (component_ref). honest-partial: a
// budget_ref naming no cash_event in THIS buyer's budget is already null (engine-side).

/** One temporally-ordered action in a phase. `status` is the resolver's seed
 *  (`not_started`); the user-set layer overlays `done` at render. `budget_ref` is a
 *  cash_event id (or null); `component_ref` a backing component id (or null). */
export interface PhaseAction {
    id: string;
    order: number;
    label: LocalizedText;
    detail: LocalizedText;
    budget_ref?: string | null;
    component_ref?: string | null;
    status: 'not_started' | 'done';
}
/** One KB-grounded risk + its mitigation for a phase (the risk-flag-list). */
export interface PhaseRisk {
    severity: 'low' | 'medium' | 'high';
    item: LocalizedText;
    action: LocalizedText;
}
export interface PhasePlaybookPhase {
    phase: string;
    actions?: PhaseAction[] | null;
    risks?: PhaseRisk[] | null;
}
export interface PhasePlaybookOutcome {
    phases?: PhasePlaybookPhase[] | null;
    key_assumptions?: LocalizedText[] | null;
}

/** The card user-set layer (fh_engine_store, migration 005): a SPARSE map of the
 *  user's own `done` attestations, `{ "<phase>": { "<action_id>": "done" } }`. Only
 *  `done` is ever stored (not_started removes the key); absent reads as not_started.
 *  Overlaid onto the current phase_playbook actions at render — never merged into the
 *  computed content snapshot. Returned as a sibling of `content` on the GET card. */
export type ChecklistStatusMap = Record<string, Record<string, string>>;

// --- the plan-card envelope (fh_engine_store:get_plan_card) ------------------

/** One filled component as the engine snapshots it (fh_engine_turn entry / the
 *  component_filled SSE payload). `renderer` is the first presentation primitive (back-compat
 *  = `renderers[0]`); `renderers` is the blueprint's ordered list — a component may compose two
 *  (engine-contract §4, e.g. `data-table + opportunity-card` on ownership_planning_investor). The
 *  shell renders each renderer in `renderers`, in order, over the same `outcome`. `outcome` is the
 *  typed result above. */
export interface ComponentEntry {
    component_id: string;
    scope: 'base' | 'both' | 'per-property';
    renderer: string;
    /** The ordered renderer list from the artifact (SOT). Absent on pre-§4 snapshots → the
     *  consumer falls back to `[renderer]` (every single-renderer component is unchanged). */
    renderers?: string[];
    outcome: Record<string, unknown>;
    kb_versions: string[];
    fill_path: 'resolver' | 'two_path' | 'agent';
    /** Present on a Phase-B (per-property) fill (engine-contract §4/§12): the addendum
     *  this outcome belongs to. Absent on a base fill. The projection routes a tagged
     *  fill into content.addenda.<property_id>.components, not the base map. */
    property_id?: string;
}

/** componentIds whose outcome is the canonical `profile` shape across all four blueprints
 *  (fact-model-unification.md "Mode-C activation" + Mode-D's straight merge): Mode A/B share
 *  `buyer_profile`, Mode C is `investor_profile`, Mode D is `investor_profile_foreign`. Any
 *  consumer that reads the profile outcome by a fixed componentId must resolve through this
 *  list, not a single literal — a lesson from `plan.c.${id}` id-cast key drift applied one
 *  layer down, to `components[id]` lookups themselves. */
export const PROFILE_COMPONENT_IDS = [
    'buyer_profile',
    'investor_profile',
    'investor_profile_foreign'
] as const;

/** The first present entry among a set of alias componentIds (e.g. `PROFILE_COMPONENT_IDS`). */
export function firstComponentEntry(
    components: Record<string, ComponentEntry>,
    ids: readonly string[]
): ComponentEntry | undefined {
    for (const id of ids) {
        if (components[id]) return components[id];
    }
    return undefined;
}

/** Harvest every `cash_events` array across all live components — mirrors the engine's own
 *  `harvest_cash_events/1` (fh_engine_journey.erl / fh_engine_phase_playbook.erl,
 *  [[unify-views-as-projections-of-one-primitive]]) so a `phase_playbook` action's
 *  `budget_ref` — validated against that SAME harvest at fill time — always resolves to an
 *  amount here too, not just the ones on `cash_position`. Mode A has one source
 *  (`cash_position`); Mode C adds `yield_modelling`/`tax_structure` — reading only
 *  `cash_position` would silently drop the amount chip on their hold-phase actions even
 *  though the engine already validated the link. `dispose_cash_events` (disposition) is
 *  deliberately excluded — the engine harvest excludes it too (no authored action links a
 *  dispose-phase budget_ref), so including it here would diverge from what was validated. */
export function harvestCashEvents(components: Record<string, ComponentEntry>): CashEvent[] {
    return Object.values(components).flatMap(
        (c) => (c.outcome as { cash_events?: CashEvent[] | null }).cash_events ?? []
    );
}

/** A normalized property as the engine stores it under content.addenda.<pid>.property_card
 *  (engine-contract §12) — the neutral facts the attach endpoint accepts. Every field is
 *  optional so a partially-seeded addendum (a live attach before the snapshot re-read)
 *  renders honest-partial rather than throwing. */
export interface PropertyCard {
    price?: number;
    state?: string;
    suburb?: string;
    property_type?: string;
    year_built?: number | null;
    land_size?: number | null;
    /** A boolean FLAG from the manual attach form ("is this a strata property?"), or a
     *  richer facts object from a future source (URL paste extracting levies). The engine
     *  doesn't validate strata (agent grounding), so the stored value is whatever the
     *  producer wrote — today a boolean. */
    strata?: boolean | Record<string, unknown> | null;
}

/** One attached property's addendum (engine-contract §12): the property_card + its
 *  per-property component fills (the same ComponentEntry shape as base) + the optional
 *  transaction slot (settlement_prep B, §11). A sibling of base content.components. */
export interface PropertyAddendum {
    property_card: PropertyCard;
    components: Record<string, ComponentEntry>;
    transaction?: { contract_signed_date?: string; settlement_date?: string } | null;
}

/** One lifecycle tab the in-scope blueprint declares (engine artifact `ui_tabs`,
 *  plan-card-lifecycle-restoration.md §3). The shell renders these tabs in order, not
 *  the raw component list. `kind: synthesis` is a shell-composed summary (Overview);
 *  `kind: flow` is the legal/temporal spine — the purchase_journey swimlane as overview
 *  with a per-phase phase_playbook drill-down (FlowView); `kind: qa` is the shell's chat
 *  surface (no component fills it — rendered by the shell's Q&A tab, not in the lifecycle
 *  rail); `interactive` marks the client-side cash what-if (B2). `components` are the
 *  blueprint's own component ids under this tab. */
export interface UiTab {
    tab_id: string;
    kind?: 'synthesis' | 'components' | 'flow' | 'qa';
    interactive?: boolean;
    components: string[];
    note?: string;
}

export interface PlanCard {
    plan_card_id: string;
    blueprint_slug: string;
    intent: string;
    mode: string;
    status: 'active' | 'retired';
    content: {
        components?: Record<string, ComponentEntry>;
        /** Per-property addenda (engine-contract §12), keyed by property_id — a sibling of
         *  base components, populated once a property is attached. Absent on a base-only card. */
        addenda?: Record<string, PropertyAddendum>;
    };
    /** The card user-set layer (sibling of content, never merged): the user's `done`
     *  checklist attestations, overlaid onto phase_playbook actions at render. Absent
     *  / {} on an untouched card (every action reads not_started). */
    checklist_status?: ChecklistStatusMap;
    /** The blueprint's lifecycle-tab spine (engine GET; absent/[] on an older engine). */
    ui_tabs?: UiTab[];
    // The snapshot's as-of event cursor + whether a turn is in flight (engine GET).
    // The projection subscribes to the SSE from `event_cursor` so a replay of an OLD
    // turn in the append-only log can't regress this (latest) snapshot, and takes its
    // done-state from `turn_running`. (Optional for backward-compat with an older engine.)
    event_cursor?: number;
    turn_running?: boolean;
}

/** A display handle from GET /api/plan-cards (shell-DB read, no engine call). */
export interface PlanCardSummary {
    plan_card_id: string;
    title: string;
    created_at: string;
}

/** The base components in DAG order — the projection renders in this order. The
 *  engine fills them in the same order (fh_engine_turn ?BASE_COMPONENTS). */
export const BASE_COMPONENT_ORDER = [
    'buyer_profile',
    'eligibility',
    'mortgage_finance',
    'cash_position',
    'ownership_planning'
] as const;

export type BaseComponentId = (typeof BASE_COMPONENT_ORDER)[number];
