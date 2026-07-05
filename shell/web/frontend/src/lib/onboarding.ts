// Pure (framework-free) onboarding model — the domestic capture set (CLAUDE.md
// constraint #1 plan-first; shell-architecture.md §7). The map gives the state + zone
// (plan cards pin to a zone); onboarding adds the intent choice (owner_occupier → Mode A
// FHB; investment → Mode C domestic investor — mode-c-wedge.md P5-activate), a
// mode-qualifying gate, and a target budget band. The chosen intent selects the engine
// blueprint. Unit-testable; no Svelte/DOM imports.

import type { OnboardingInput } from '$lib/api';

/** The buying intent the gate branches on (engine-contract §9.1). owner_occupier still
 *  requires a first-home answer (Mode A); investment does not (Mode C). */
export type Intent = OnboardingInput['intent'];

/** The buyer-stage axis (mode-e-wedge.md P0/P5) — only asked when intent=owner_occupier;
 *  first_home → Mode A/B, next_home → Mode E (domestic) / out-of-scope (foreign). */
export type BuyerStage = NonNullable<OnboardingInput['buyer_stage']>;

/** A target price range the buyer picks as a single tap (AUD). A band — not a free
 *  slider — keeps the choice to one low-cognitive-load decision (§7.1). The engine's
 *  cash/ownership fills use the ceiling (`hi`); `lo` rides through for display.
 *  VND framing (constraint #1) is deferred until the RBA FX reference feed is wired
 *  — we do not invent a rate. */
export interface BudgetBand {
    lo: number;
    hi: number;
}

export const BUDGET_BANDS: readonly BudgetBand[] = [
    { lo: 0, hi: 500_000 },
    { lo: 500_000, hi: 650_000 },
    { lo: 650_000, hi: 800_000 },
    { lo: 800_000, hi: 1_000_000 },
    { lo: 1_000_000, hi: 1_300_000 },
    { lo: 1_300_000, hi: 2_000_000 }
];

/** Build the engine onboarding payload (the body of POST /api/plan-cards). Shapes
 *  exactly the fields the base turn reads: state, target_price_range [lo,hi],
 *  target_zone, target_sal, intent, foreign_person, buyer_stage (fh_engine_h_plan_cards +
 *  the base-turn fills). target_sal is the stable opaque state key (the suburb is always
 *  map-selected, so the SAL is in hand); it decouples state resolution from the name
 *  string, which is also the title + match key. target_zone/state stay for display +
 *  as fallbacks. foreign_person defaults false (domestic, unchanged) — mode-b-wedge.md
 *  P5's foreign-person gate is the only caller that passes true. buyerStage is omitted
 *  entirely for intent=investment (meaningless, mode-e-wedge.md) — only owner_occupier
 *  callers pass it, and always explicitly (never relying on the engine's next_home
 *  default, mode-e-wedge.md P5). */
export function buildOnboardingInput(
    stateCode: string,
    suburbName: string,
    suburbSal: string,
    band: BudgetBand,
    intent: Intent,
    foreignPerson = false,
    buyerStage?: BuyerStage
): OnboardingInput {
    return {
        state: stateCode,
        target_price_range: [band.lo, band.hi],
        target_zone: [suburbName],
        target_sal: suburbSal,
        intent,
        foreign_person: foreignPerson,
        ...(buyerStage ? { buyer_stage: buyerStage } : {})
    };
}
