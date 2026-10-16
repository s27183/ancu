// Guest plans -> P-2 · The database is the single source of truth -> The web frontend -> the questions and the tap outlive the tab
//
// Behavior 97 (Son 2026-10-16: "the planning process is lost if the user's phone has
// screen lock in the middle … not atomic"). A phone that locks, or a switch to another
// app, can freeze the page or make Safari reload the tab. So the onboarding dialog keeps
// what it has in this tab's sessionStorage, step by step:
//   - the answers tapped so far (before the tap, a reloaded /plan reopens the questions
//     with them);
//   - the create key, written at the tap BEFORE the create is sent (after it, a
//     reloaded /plan sends the same create again; the shell answers a repeated key with
//     the plan it already made — fh_shell_h_plan_cards once/3 — so one tap is one plan);
//   - the new plan's id once the reply arrived (a reloaded /plan goes back to the wait).
// sessionStorage, not localStorage: it lives and dies with the tab, which is what a
// reload keeps and a new visit does not. Cleared when the dialog lands on its plan, is
// closed, or hands over to sign-in (pendingOnboarding.ts carries the answers there).
// Only the user's own taps are kept, nothing inferred; the server holds the plan.

import type { OnboardingAnswers } from '$lib/pendingOnboarding';

export interface OnboardingDraft {
    /** The state the plan is for (the planner's state picker). */
    scope: string;
    answers: OnboardingAnswers;
    /** Set at the tap, before the create leaves; absent before the tap. */
    createKey?: string;
    /** The plan the tap made, once its reply arrived. */
    planId?: string;
    ts: number;
}

const KEY = 'rau.onboardingDraft';
/** Older than this, a draft is dropped: a visitor back after an hour starts afresh. */
export const DRAFT_TTL_MS = 60 * 60 * 1000;

export function saveDraft(d: OnboardingDraft): void {
    try {
        sessionStorage.setItem(KEY, JSON.stringify(d));
    } catch {
        // storage blocked: the dialog works as before, without surviving a reload
    }
}

export function readDraft(now: number = Date.now()): OnboardingDraft | null {
    try {
        const raw = sessionStorage.getItem(KEY);
        if (!raw) return null;
        const d = JSON.parse(raw) as OnboardingDraft;
        if (typeof d?.scope !== 'string' || typeof d.answers !== 'object' || d.answers === null)
            return null;
        if (typeof d.ts !== 'number' || now - d.ts > DRAFT_TTL_MS || now < d.ts) return null;
        return d;
    } catch {
        return null;
    }
}

export function clearDraft(): void {
    try {
        sessionStorage.removeItem(KEY);
    } catch {
        // nothing to clear
    }
}

/** A fresh create key: one per tap. */
export function newCreateKey(): string {
    try {
        return crypto.randomUUID();
    } catch {
        // crypto.randomUUID needs a secure context; the shell takes 8-64 of [A-Za-z0-9_-]
        return `${Date.now().toString(36)}-${Math.random().toString(36).slice(2)}${Math.random().toString(36).slice(2)}`;
    }
}
