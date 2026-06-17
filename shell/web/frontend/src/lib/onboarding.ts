// Pure (framework-free) onboarding model — the Wedge-1a Mode-A capture set
// (CLAUDE.md constraint #1 plan-first; shell-architecture.md §7). The map gives the
// state + zone (plan cards pin to a zone); onboarding adds the mode-qualifying gate
// + a target budget band. intent is fixed to owner_occupier — Mode A is a first-home
// owner-occupier; investment is Mode C, out of Wedge-1a scope, so we don't ask it
// (one fewer decision, §7.1). Unit-testable; no Svelte/DOM imports.

import type { OnboardingInput } from '$lib/api';

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
 *  target_zone, target_sal, intent (fh_engine_h_plan_cards + the base-turn fills).
 *  target_sal is the stable opaque state key (the suburb is always map-selected, so
 *  the SAL is in hand); it decouples state resolution from the name string, which is
 *  also the title + match key. target_zone/state stay for display + as fallbacks. */
export function buildOnboardingInput(
    stateCode: string,
    suburbName: string,
    suburbSal: string,
    band: BudgetBand
): OnboardingInput {
    return {
        state: stateCode,
        target_price_range: [band.lo, band.hi],
        target_zone: [suburbName],
        target_sal: suburbSal,
        intent: 'owner_occupier'
    };
}
