// The map's finding pointer (behavior 78): when the page opens, a text bubble beside the
// filter button says how to find a suburb — type its name there, or zoom into the map.
//
//   goal property: bilingual, self-serve — a guest builds a plan without sign-in (b45)
//   invariant: a pointer points, the visitor acts; it never blocks a control (it takes
//     no pointer events) and never talks over the first-visit sheet or the tour (b52),
//     whose first step already points at the search
//   component: this module + the bubble in routes/+page.svelte + Welcome.svelte (introOpen)
//   capability: shown on each page open until a suburb has once been opened in this
//     browser (HINT_KEY); gone for the page view on the first filter open, map zoom or
//     suburb opened; still, not bobbing, under reduced motion (app.css)
import { writable } from 'svelte/store';

/** Whether the first-visit sheet is open — set by Welcome.svelte. */
export const introOpen = writable(false);

const HINT_KEY = 'ancu-map-hint-done';

export function mapHintDone(): boolean {
    try {
        return localStorage.getItem(HINT_KEY) === '1';
    } catch {
        return false;
    }
}

/** A suburb was opened: the visitor has found the way, so no pointer on later visits. */
export function markMapHintDone(): void {
    try {
        localStorage.setItem(HINT_KEY, '1');
    } catch {
        /* storage blocked: the pointer simply shows again next visit */
    }
}
