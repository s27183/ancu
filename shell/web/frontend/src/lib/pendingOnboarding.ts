// Honest-partial -> P-2 · The database is the single source of truth -> The web frontend -> onboarding answers survive the sign-in round-trip, and nothing past it
//
// A signed-out user who answers onboarding is asked to sign in; the magic link (or the
// OAuth callback) lands on /?signin=ok as a fresh page load, which used to drop the
// answers (they were Onboarding's local $state). Only the user's own taps are kept —
// nothing is inferred — in this browser's localStorage, for an hour, and read once:
// takePending() removes the key whether or not it is still fresh. It is not a plan
// fact: the plan card is created only by the user's tap after the restore.

import type { Intent } from '$lib/onboarding';

/** What the user has tapped so far; null = not answered. `band` is a BUDGET_BANDS index. */
export interface OnboardingAnswers {
    intent: Intent | null;
    citizenPr: boolean | null;
    firstHome: boolean | null;
    band: number | null;
}

export interface PendingOnboarding {
    sal: string;
    /** The map scope the user was on (a state code or 'ALL'). */
    scope: string;
    /** Absent when a guest signs in from their plan (behavior 45): the sheet reopens on
     *  that suburb's Plan tab — the claimed plan — instead of the onboarding. */
    answers?: OnboardingAnswers;
    ts: number;
}

const KEY = 'rau.pendingOnboarding';
export const PENDING_TTL_MS = 60 * 60 * 1000;

export function savePending(p: PendingOnboarding): void {
    try {
        localStorage.setItem(KEY, JSON.stringify(p));
    } catch {
        // storage blocked (private window etc.) → the user lands on the plain map, as before
    }
}

/** Read and clear the pending onboarding; null if none, malformed or older than the TTL. */
export function takePending(now: number = Date.now()): PendingOnboarding | null {
    let raw: string | null = null;
    try {
        raw = localStorage.getItem(KEY);
        localStorage.removeItem(KEY);
    } catch {
        return null;
    }
    if (!raw) return null;
    try {
        const p = JSON.parse(raw) as PendingOnboarding;
        if (typeof p?.sal !== 'string' || typeof p?.scope !== 'string') return null;
        if (typeof p.ts !== 'number' || now - p.ts > PENDING_TTL_MS || now < p.ts) return null;
        return p;
    } catch {
        return null;
    }
}
