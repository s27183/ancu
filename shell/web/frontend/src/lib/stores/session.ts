// The current user session (login flow). The backend holds the truth in an httpOnly
// cookie; this store is the SPA's cached read of GET /api/me. `null` = signed out,
// and `loaded` flips true once the first /api/me has resolved so the UI can avoid a
// sign-in flash before we know. Refreshed after a sign-in redirect lands (?signin=ok).
import { writable } from 'svelte/store';
import { browser } from '$app/environment';
import { getMe, type Session } from '$lib/auth';

export const session = writable<Session | null>(null);
export const sessionLoaded = writable<boolean>(false);

/** Re-read /api/me and update the store. Safe to call repeatedly. */
export async function refreshSession(): Promise<void> {
    if (!browser) return;
    try {
        session.set(await getMe());
    } catch {
        session.set(null);
    } finally {
        sessionLoaded.set(true);
    }
}

export async function signOut(): Promise<void> {
    const { logout } = await import('$lib/auth');
    await logout();
    session.set(null);
}
