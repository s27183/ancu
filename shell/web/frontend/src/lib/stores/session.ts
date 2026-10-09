// The current user session (login flow). The backend holds the truth in an httpOnly
// cookie; this store is the SPA's cached read of GET /api/me. `null` = signed out,
// and `loaded` flips true once the first /api/me has resolved so the UI can avoid a
// sign-in flash before we know. Refreshed after a sign-in redirect lands (?signin=ok).
import { writable } from 'svelte/store';
import { browser } from '$app/environment';
import { getMe, type Session } from '$lib/auth';

export const session = writable<Session | null>(null);
export const sessionLoaded = writable<boolean>(false);
// Guest plans -> P-5 · Metering, not gating -> The web frontend -> a guest is signed out, with a plan
// Behavior 45 (Son, 2026-10-10): a signed-out create makes a guest session (role guest,
// no email). For the header, the saved-plans filter and the expired-session cue a guest
// is signed out — `session` stays null — and `guest` says this browser holds a
// temporary plan, so the plan sheet shows the 7-day notice and Q&A asks for sign-in.
export const guest = writable<boolean>(false);
// True when /api/me resolves to null but we HAD a session before — the 1-day session
// JWT (fh_shell_jwt, no refresh) lapsed under the user. This is distinct from
// never-signed-in: the UI prompts a calm re-login instead of silently dropping the
// saved-plans surface (which is gated on `$session`). The "had a session" fact is
// persisted to localStorage so the cue survives a reload until re-login or an explicit
// sign-out (which is intentional, not an expiry).
export const sessionExpired = writable<boolean>(false);

const PRIOR_KEY = 'fh-had-session';
const hadPriorSession = (): boolean => browser && localStorage.getItem(PRIOR_KEY) === '1';

/** Re-read /api/me and update the store. Safe to call repeatedly. */
export async function refreshSession(): Promise<void> {
    if (!browser) return;
    let s: Session | null = null;
    try {
        s = await getMe();
    } catch {
        s = null;
    }
    const isGuest = !!s?.guest;
    guest.set(isGuest);
    if (isGuest) s = null;
    session.set(s);
    if (s) {
        localStorage.setItem(PRIOR_KEY, '1');
        sessionExpired.set(false);
    } else {
        // null + a prior session on record ⇒ the cookie lapsed (not never-signed-in).
        sessionExpired.set(hadPriorSession());
    }
    sessionLoaded.set(true);
}

/** Acknowledge the expired-session cue (dismiss). Clears the prior-session marker so a
 *  reload doesn't replay it — mirrors the ?signin=… banner's no-replay behaviour. */
export function dismissSessionExpired(): void {
    sessionExpired.set(false);
    if (browser) localStorage.removeItem(PRIOR_KEY);
}

export async function signOut(): Promise<void> {
    const { logout } = await import('$lib/auth');
    await logout();
    session.set(null);
    guest.set(false);
    // An intentional sign-out is not an expiry — clear the marker so no cue fires.
    sessionExpired.set(false);
    if (browser) localStorage.removeItem(PRIOR_KEY);
}
