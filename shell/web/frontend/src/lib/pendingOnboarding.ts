// Honest-partial -> P-2 · The database is the single source of truth -> The web frontend -> onboarding answers survive the sign-in round-trip, and nothing past it
//
// A signed-out user who answers onboarding is asked to sign in; the magic link (or the
// OAuth callback) lands on /?signin=ok as a fresh page load, which used to drop the
// answers (they were Onboarding's local $state). Only the user's own taps are kept —
// nothing is inferred — in this browser's localStorage, for an hour, and read once:
// takePending(page) removes the key unless a fresh entry belongs to the other page (the
// home routes a returning sign-in there first, pendingPage()). It is not a plan
// fact: the plan card is created only by the user's tap after the restore.

import type { Intent } from '$lib/onboarding';

/** What the user has tapped so far; null = not answered. `band` is a BUDGET_BANDS index. */
export interface OnboardingAnswers {
    intent: Intent | null;
    citizenPr: boolean | null;
    firstHome: boolean | null;
    band: number | null;
}

export type PendingPage = 'explore' | 'plan';

export interface PendingOnboarding {
    /** The page that restores it (behavior 81): the map reopens a suburb, the planner its
     *  plan. The sign-in lands on the home, which routes to this page. Absent in an entry
     *  saved before behavior 81 — read as 'explore'. */
    page?: PendingPage;
    /** The suburb whose sheet was open (the map only). */
    sal?: string;
    /** The map scope the user was on (a state code or 'ALL'); on the planner, the state. */
    scope: string;
    /** Absent when a guest signs in from their plan (behavior 45): the page reopens the
     *  claimed plan instead of the onboarding. */
    answers?: OnboardingAnswers;
    ts: number;
}

const KEY = 'rau.pendingOnboarding';
export const PENDING_TTL_MS = 60 * 60 * 1000;

export function savePending(p: PendingOnboarding): void {
    try {
        localStorage.setItem(KEY, JSON.stringify(p));
    } catch {
        // storage blocked (private window etc.) → the user lands on the plain page, as before
    }
}

function parse(raw: string | null, now: number): PendingOnboarding | null {
    if (!raw) return null;
    try {
        const p = JSON.parse(raw) as PendingOnboarding;
        if (typeof p?.scope !== 'string') return null;
        if (p.page !== 'plan' && typeof p.sal !== 'string') return null;
        if (typeof p.ts !== 'number' || now - p.ts > PENDING_TTL_MS || now < p.ts) return null;
        return { ...p, page: p.page ?? 'explore' };
    } catch {
        return null;
    }
}

/** The page a fresh pending onboarding belongs to, without taking it; null if none. */
export function pendingPage(now: number = Date.now()): PendingPage | null {
    try {
        return parse(localStorage.getItem(KEY), now)?.page ?? null;
    } catch {
        return null;
    }
}

/** Read and clear the pending onboarding for this page; null if none, malformed, older
 *  than the TTL, or another page's (left for that page to take). */
export function takePending(page: PendingPage, now: number = Date.now()): PendingOnboarding | null {
    try {
        const p = parse(localStorage.getItem(KEY), now);
        if (p && p.page !== page) return null;
        localStorage.removeItem(KEY);
        return p;
    } catch {
        return null;
    }
}
