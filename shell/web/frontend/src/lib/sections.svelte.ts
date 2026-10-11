// The plan sheet's sections, shared by the suburb sheet and the plan inside it (behavior 68).
// Buyer-on-a-phone -> the plan sheet -> one floating section menu: on a phone the three
// stacked tab rails (zone/plan, the plan's lifecycle tabs, the budget's sub-tabs) gave
// ~200px of a sheet to navigation before any content (Son's screenshot, 2026-10-11).
// SuburbSheet owns the zone/plan switch and draws the menu; PlanProjection owns which
// lifecycle tab and budget sub-tab are shown and publishes them here, so the menu offers
// exactly the set the rails offer, from the same state — the rails stay on desktop.
import { getContext, setContext } from 'svelte';

export type SectionIcon =
    | 'zone'
    | 'overview'
    | 'flow'
    | 'budget'
    | 'portfolio'
    | 'family'
    | 'qa'
    | 'sub';

export type SectionItem = {
    id: string;
    label: string;
    icon: SectionIcon;
    active: boolean;
    /** The AI assistant keeps its accent look (behavior 55). */
    accent?: boolean;
    /** A budget sub-section, listed under its tab. */
    nested?: boolean;
    /** A tab whose sub-sections follow it: marked, but the ✓ goes on the sub-section. */
    parent?: boolean;
    /** The tour's data-tour name for this item (behavior 72). */
    tour?: string;
    select: () => void;
};

export type SectionGroup = { id: string; label?: string; items: SectionItem[] };

export class SectionRegistry {
    /** The plan's groups, published by PlanProjection while it is mounted. */
    plan = $state<SectionGroup[]>([]);
    /** The plan's current section, for the pill ("Kế hoạch · <this>"). */
    current = $state('');
    /** Opens the AI assistant, while a plan is shown and the assistant is not (the sheet
     *  head's "Hỏi AI" button, behavior 75); null otherwise. */
    ask = $state<(() => void) | null>(null);
}

const KEY = Symbol('section-menu');

export function provideSections(): SectionRegistry {
    return setContext(KEY, new SectionRegistry());
}

export function useSections(): SectionRegistry | undefined {
    return getContext<SectionRegistry | undefined>(KEY);
}
