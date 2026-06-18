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
    approx_borrowing_capacity?: MoneyRange | null;
    deposit_ready_for_purchase_amount?: number | null;
    target_price_range?: MoneyRange | null;
    target_zone?: string[] | null;
    key_constraints?: LocalizedText[] | null;
    key_strengths?: LocalizedText[] | null;
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
/** mortgage_finance → summary-card (outcome type `mortgage_plan`). */
export interface MortgagePlanOutcome {
    recommended_path?: string | null;
    expected_borrowing_capacity?: MoneyRange | null;
    recommended_lender_shortlist?: LenderEntry[] | null;
    pre_approval_action_plan?: LocalizedText[] | null;
    pre_approval_expiry?: string | null;
    key_assumptions?: LocalizedText[] | null;
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
/** cash_position → calculator (outcome type `budget_envelope`). */
export interface BudgetEnvelopeOutcome {
    stamp_duty?: StampDuty | null;
    // NEED side (Decision 9) — real at base.
    deposit?: Deposit | null;
    other_buying_costs?: OtherBuyingCosts | null;
    reserve_buffer?: ReserveBuffer | null;
    /** NEED total AT SETTLEMENT = deposit + duty + other costs. money_range at base. */
    total_cash_required?: MoneyRange | null;
    max_property_price_supported?: number | null;
    actual_property_price?: number | null;
    // HAVE side + verdict — null at base (no savings captured at onboarding; refine turn).
    cash_available?: number | null;
    gap_or_surplus?: number | null;
    verdict?: string | null;
    genuine_savings_verdict?: string | null;
    mitigation_options_if_short?: string[] | null;
    key_assumptions?: LocalizedText[] | null;
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
/** ownership_planning → data-table (outcome type `ongoing_obligations`). */
export interface OngoingObligationsOutcome {
    total_monthly_outgoings_estimate?: number | null;
    total_annual_outgoings_estimate?: number | null;
    maintenance_reserve_target?: number | null;
    recurring_costs_estimate?: RecurringCosts | null;
    land_tax_check?: string | null;
    alert_triggers_armed?: AlertTrigger[] | null;
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
export interface JourneySwimlaneOutcome {
    phases?: JourneyPhase[] | null;
    actors?: JourneyActor[] | null;
    cells?: JourneyCell[] | null;
    key_assumptions?: LocalizedText[] | null;
}

// --- the plan-card envelope (fh_engine_store:get_plan_card) ------------------

/** One filled component as the engine snapshots it (fh_engine_turn entry / the
 *  component_filled SSE payload). `renderer` is the singular presentation primitive
 *  (first of the blueprint's `renderers`); `outcome` is the typed result above. */
export interface ComponentEntry {
    component_id: string;
    scope: 'base' | 'both' | 'per-property';
    renderer: string;
    outcome: Record<string, unknown>;
    kb_versions: string[];
    fill_path: 'resolver' | 'two_path' | 'agent';
}

/** One lifecycle tab the in-scope blueprint declares (engine artifact `ui_tabs`,
 *  plan-card-lifecycle-restoration.md §3). The shell renders these tabs in order, not
 *  the raw component list. `kind: synthesis` is a shell-composed summary (Overview);
 *  `interactive` marks the client-side cash what-if (B2). `components` are the
 *  blueprint's own component ids surfaced under this tab. */
export interface UiTab {
    tab_id: string;
    kind?: 'synthesis' | 'components';
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
    content: { components?: Record<string, ComponentEntry> };
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
