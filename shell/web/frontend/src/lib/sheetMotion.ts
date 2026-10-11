// How a sheet opens and closes (behavior 66, Son 2026-10-11).
// Buyer-on-a-phone -> the planning sheets -> one motion: on a phone the suburb sheet and
// every popup slide up from the bottom edge and back down; on wider screens the centred
// card rises a few px and fades, as its CSS keyframes did before. Svelte 5 runs a
// transition's css() as Element.animate keyframes (WAAPI, read in svelte 5.56
// internal/client/dom/elements/transitions.js), and only transform and opacity change
// here, so the browser animates them on the compositor — no layout or paint per frame.
// fly() keeps the element's own computed transform (the desktop .sheet's centring) and
// adds the translate on top. The scrim fades with svelte's fade; it carries no
// backdrop-filter, the full-screen blur that made opening a popup stutter on iPhones.
import { fly, fade, type TransitionConfig } from 'svelte/transition';
import { cubicOut } from 'svelte/easing';

const WIDE = '(min-width: 48rem)';

function reduced(): boolean {
    return typeof matchMedia === 'function' && matchMedia('(prefers-reduced-motion: reduce)').matches;
}

function wide(): boolean {
    return typeof matchMedia === 'function' && matchMedia(WIDE).matches;
}

/** The card: slides from the bottom edge on a phone; rises and fades on wider screens. */
export function sheetMotion(node: Element): TransitionConfig {
    if (reduced()) return { duration: 0 };
    return wide()
        ? fly(node, { y: 8, opacity: 0, duration: 220, easing: cubicOut })
        : fly(node, { y: '100%', opacity: 1, duration: 300, easing: cubicOut });
}

/** The scrim behind a popup. */
export function scrimMotion(node: Element): TransitionConfig {
    if (reduced()) return { duration: 0 };
    return fade(node, { duration: 220 });
}
