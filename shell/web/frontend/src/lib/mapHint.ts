// Bilingual -> a pointer points, the visitor acts -> the web frontend -> the map's finding pointer
// Goal:      behaviors 78/115 — a guest on the map learns how to find a suburb without help: a
//            bubble under "Tìm & lọc" says type its name there, or zoom into the map.
// Invariant: it never blocks a control (it takes no pointer events) and never talks over the
//            first-visit sheet or the tour (b52), whose first step already points at the search;
//            this module + the bubble in routes/explore/+page.svelte + Welcome.svelte (introOpen).
// Capability: under "Tìm & lọc" at the map's top right, its arrow on that button, never on
//            "Trang chủ" at the top left (measured 2026-10-18 in Chrome: arrow x 359 inside the
//            button's 269–388 at 400px; before behavior 115 it sat at x≈29, over "Trang chủ");
//            shown on each page open until a suburb has once been opened in this browser
//            (HINT_KEY); gone for the page view on the first filter open, map zoom or suburb
//            opened; still, not bobbing, under reduced motion (app.css).
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
