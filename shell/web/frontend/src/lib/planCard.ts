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
// The two renderers Mode C adds (buying-strategy-card, opportunity-card). No live
// producer yet — buying_strategy and ownership_planning_investor are Phase-B/agent
// components, unwired in both modes — so these are typed against the §11.9 renderer
// CONTRACT, honest-partial (every field nullable). See mode-c-wedge.md P4.

/** One comparable sale backing the bid plan. */
export interface Comparable {
    address?: string | null;
    price?: number | null;
    note?: LocalizedText | null;
}
/** buying_strategy → buying-strategy-card (outcome type `bid_plan_investor`). The
 *  investor bid-discipline plan: §11.9 { max_bid, walk_away, comparables[], style } +
 *  the blueprint's yield_anchored_max_price / thesis_alignment. Decision-support: the
 *  yield ceiling + walk-away frame the max bid; the engine owns the figures. */
export interface BidPlanInvestorOutcome {
    max_bid?: number | null;
    walk_away?: number | null;
    yield_anchored_max_price?: number | null;
    thesis_alignment?: 'aligned' | 'stretched' | 'misaligned' | string | null;
    style?: string | null;
    comparables?: Comparable[] | null;
    conditions?: LocalizedText[] | null;
    key_assumptions?: LocalizedText[] | null;
}

/** One modelled opportunity (rent review, equity release, scale-up). `modeled_benefit`
 *  is a banded estimate (range) or a point. */
export interface Opportunity {
    kind?: string | null;
    modeled_benefit?: MoneyRange | number | null;
    action?: LocalizedText | null;
}
/** ownership_planning_investor → opportunity-card (§11.9 { kind, modeled_benefit,
 *  action }). list-tolerant: an `opportunities[]` or a single opportunity. NOTE the
 *  producer seam — portfolio_position emits alert_triggers_armed (DataTable renders it),
 *  NOT this shape; opportunities[] is owed when the component is wired (mode-c-wedge P4). */
export interface OpportunityCardOutcome extends Opportunity {
    opportunities?: Opportunity[] | null;
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
    content: { components?: Record<string, ComponentEntry> };
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
