// Shared, viewport-aware Svelte transitions for the map overlays (8-S UI polish).
// Direction is chosen at call time from the viewport so one directive gives the right
// motion on both form factors: a side drawer on desktop, a bottom-sheet on phone.
// (prefers-reduced-motion is honoured globally in app.css.)
import { cubicOut } from 'svelte/easing';
import type { TransitionConfig } from 'svelte/transition';

const isDesktop = (): boolean =>
    typeof window !== 'undefined' && window.matchMedia('(min-width: 48rem)').matches;

/** The suburb sheet: slides in from the right edge on desktop (a full-height drawer),
 *  rises from the bottom on phone (a bottom-sheet). */
export function sheet(_node: Element, { duration = 260 } = {}): TransitionConfig {
    const desktop = isDesktop();
    return {
        duration,
        easing: cubicOut,
        css: (t) =>
            desktop
                ? `transform: translateX(${(1 - t) * 100}%)`
                : `transform: translateY(${(1 - t) * 100}%)`
    };
}

/** A modal card: rises + fades on phone (bottom-aligned), lifts + scales in on desktop
 *  (centred). */
export function modalCard(_node: Element, { duration = 260 } = {}): TransitionConfig {
    const desktop = isDesktop();
    return {
        duration,
        easing: cubicOut,
        css: (t) =>
            desktop
                ? `opacity: ${t}; transform: translateY(${(1 - t) * 10}px) scale(${0.97 + t * 0.03})`
                : `transform: translateY(${(1 - t) * 100}%)`
    };
}
