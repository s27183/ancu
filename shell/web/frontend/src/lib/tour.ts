// The first-visit tour (behavior 52, made map-only by behavior 81): the first time a
// visitor opens the map page (/explore), a short guided tour shows how to find a suburb
// and what its sheet tells, one bubble at a time, each pointing at the real control they
// tap next. It never acts for them (except the 'Try Cabramatta' chip, which picks that
// suburb): every step advances on an event the page already has. Tour.svelte draws it.
// The plan is no longer on the map (it is /plan, reached from the home), so the tour
// ends at the suburb's facts.
//
//   goal property: bilingual, self-serve
//   invariant: the tour points, the visitor acts; it never blocks a control (the layer
//     takes no pointer events but the bubble's own)
//   component: this store + Tour.svelte + data-tour='<target>' on the controls
//   capability: start (the map page's first visit in this browser, or 'Show me around'
//     in "Vì sao Úc?"), advance on events, skip/finish → remembered per browser (TOUR_KEY)
import { writable, get } from 'svelte/store';

/** 0 = off; 1 = find a suburb; 2 = its facts. */
export type TourStep = 0 | 1 | 2;
export const TOUR_STEPS = 2;

export const tourStep = writable<TourStep>(0);
/** Bumped on every start, so the page can reset to the map (close a sheet, open search). */
export const tourRun = writable(0);

const TOUR_KEY = 'ancu-tour-done';

export function tourDone(): boolean {
    try {
        return localStorage.getItem(TOUR_KEY) === '1';
    } catch {
        return false;
    }
}

export function startTour() {
    tourRun.update((n) => n + 1);
    tourStep.set(1);
}

/** Skip or Done: the tour is over and does not start by itself again in this browser. */
export function endTour() {
    tourStep.set(0);
    try {
        localStorage.setItem(TOUR_KEY, '1');
    } catch {
        /* storage blocked: it simply may show again next visit */
    }
}

export type TourEvent =
    | 'suburb' // a suburb's sheet opened
    | 'unsuburb'; // the suburb sheet closed

export function tourEvent(e: TourEvent) {
    const s = get(tourStep);
    if (s === 0) return;
    // Closing the suburb's sheet after reading it is as good as 'Done'.
    if (e === 'unsuburb' && s === 2) return endTour();
    if (e === 'suburb' && s === 1) tourStep.set(2);
}
