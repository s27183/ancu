// The first-visit tour (behavior 52): after the first-visit sheet closes, a short guided
// tour walks a visitor from the map to a plan, one bubble at a time, each pointing at the
// real control they tap next. It never acts for them (except the 'Try Cabramatta' chip,
// which picks that suburb): every step advances on an event the app already has, sent
// here by the component that owns it. Tour.svelte draws the current step.
//
//   goal property: bilingual, self-serve — a guest builds a plan without sign-in (b45)
//   invariant: the tour points, the visitor acts; it never blocks a control (the layer
//     takes no pointer events but the bubble's own)
//   component: this store + Tour.svelte + data-tour='<target>' on the controls
//   capability: start (first close of the auto-opened sheet, or 'Show me around'),
//     advance on events, skip/finish → remembered per browser (TOUR_KEY)
import { writable, get } from 'svelte/store';

/** 0 = off; 'questions' = onboarding is open (no bubble while answering). */
export type TourStep = 0 | 1 | 2 | 3 | 'questions' | 4;
export const TOUR_STEPS = 4;

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
    | 'unsuburb' // the suburb sheet closed
    | 'plan-tab' // the sheet's Plan tab shown
    | 'zone-tab' // back to the sheet's Zone tab
    | 'onboarding' // the questions opened
    | 'onboarding-closed' // the questions closed without a plan
    | 'plan-ready'; // a plan finished rendering in the Plan tab

export function tourEvent(e: TourEvent) {
    const s = get(tourStep);
    if (s === 0) return;
    // Closing the sheet over the finished plan is as good as 'Done'.
    if (e === 'unsuburb' && s === 4) return endTour();
    const next: TourStep | null =
        e === 'suburb' && s === 1
            ? 2
            : e === 'unsuburb' && (s === 2 || s === 3 || s === 'questions')
                ? 1
                : e === 'plan-tab' && s === 2
                    ? 3
                    : e === 'zone-tab' && s === 3
                        ? 2
                        : e === 'onboarding' && s === 3
                            ? 'questions'
                            : e === 'onboarding-closed' && s === 'questions'
                                ? 3
                                : e === 'plan-ready' && (s === 3 || s === 'questions')
                                    ? 4
                                    : null;
    if (next !== null) tourStep.set(next);
}
