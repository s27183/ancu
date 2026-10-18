// Bilingual -> P-7 · The KB -> The web frontend -> an Australian term the app writes explains itself on a tap
// Behavior 102 (Son 2026-10-17, his friend): LMI, the First Home Guarantee, FIRB … mean
// nothing to a Vietnamese buyer on their own. Every place that draws engine copy, sheet
// copy, a news summary or an AI answer runs it through markTerms/markTermsHtml: the first
// time a term's surface form appears in a block it becomes a tappable span (data-term),
// and a tap opens the one TermCard (lib/TermCard.svelte) with the term's names, meaning,
// why it matters and its KB source.
// Holds:   matching is whole-word (no letter or digit on either side), longest form first;
//          an all-capitals form (LMI, FIRB) matches its exact case only, any other form
//          ignores case; forms of both languages match in either UI language (vi copy
//          carries the English acronyms). One block = one `seen` set: a term is marked
//          once per block. Inside <a>, <code> and <pre> nothing is marked.
// The list: GET /api/terms (docs/kb/terms/*.md, compiled like docs/kb/facts); until it
//          arrives (or if it fails) nothing is marked — the text reads as before.

import { writable, get } from 'svelte/store';
import type { Term } from '$lib/termMatch';
export { markTerms, markTermsHtml, pickL, type Term, type Segment, type Localized } from '$lib/termMatch';

export const terms = writable<Term[]>([]);
/** The term whose card is open, and the element to give focus back to on close. */
export const openTerm = writable<{ term: Term; from: HTMLElement | null } | null>(null);

export function termById(id: string): Term | undefined {
    return get(terms).find((t) => t.id === id);
}

export function showTerm(term: Term, from: HTMLElement | null): void {
    openTerm.set({ term, from });
}

/** For a container whose HTML came from markTermsHtml: one click/keydown handler opens
 *  the card for the [data-term] span hit, and keeps the tap from reaching a parent
 *  (a <summary> would otherwise open or close its line). */
export function termEvent(e: MouseEvent | KeyboardEvent): void {
    const el = (e.target as HTMLElement | null)?.closest?.('[data-term]') as HTMLElement | null;
    if (!el) return;
    if (e instanceof KeyboardEvent && e.key !== 'Enter' && e.key !== ' ') return;
    const t = termById(el.dataset.term ?? '');
    if (!t) return;
    e.preventDefault();
    e.stopPropagation();
    showTerm(t, el);
}

let loading: Promise<void> | null = null;
/** GET /api/terms once per page load, and again (`reload`) when the KB is replaced
 *  (behavior 135); a failure leaves the list as it was (at first empty: nothing marked). */
export function loadTerms(fetchFn: typeof fetch = fetch, reload = false): Promise<void> {
    if (loading && !reload) return loading;
    loading = (async () => {
        try {
            const res = await fetchFn('/api/terms');
            if (!res.ok) return;
            const body = (await res.json()) as { terms?: Term[] };
            if (Array.isArray(body.terms)) terms.set(body.terms);
        } catch {
            /* the text reads as before */
        }
    })();
    return loading;
}

/** Svelte action for a container drawn with {@html markTermsHtml(...)}: its term spans
 *  open their card on a tap or Enter/Space (the spans carry role="button", tabindex 0). */
export function termClicks(node: HTMLElement) {
    node.addEventListener('click', termEvent);
    node.addEventListener('keydown', termEvent);
    return {
        destroy() {
            node.removeEventListener('click', termEvent);
            node.removeEventListener('keydown', termEvent);
        }
    };
}
