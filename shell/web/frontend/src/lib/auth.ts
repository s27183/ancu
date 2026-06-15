// Login client for the shell BACKEND (Erlang, :8081) — the browser<->shell identity
// seam (shell-architecture.md §3). The session is an httpOnly `fh_session` cookie set
// by the backend on magic-link redemption / Google callback; JS never sees the token.
// So these calls carry no Authorization header — the cookie rides automatically
// (same-origin in prod, vite-proxied in dev) — and `credentials: 'same-origin'` is the
// browser default for that. We only ever learn the session via GET /api/me.

export interface Session {
    user_id: string;
    email: string;
    roles: string[];
    locale: 'vi' | 'en';
}

/** GET /api/me → the current session, or null when signed out (the backend's 401). */
export async function getMe(fetchFn: typeof fetch = fetch): Promise<Session | null> {
    const res = await fetchFn('/api/me');
    if (res.status === 200) return (await res.json()) as Session;
    return null;
}

/** POST /api/auth/magic {email}. Always resolves (the backend answers 202 whether or
 *  not the address exists — no account enumeration). `dev_link` is present only in dev
 *  (AUTH_DEV_EXPOSE_LINK) so the loop works with no inbox. */
export async function requestMagicLink(
    email: string,
    fetchFn: typeof fetch = fetch
): Promise<{ sent: boolean; dev_link?: string }> {
    const res = await fetchFn('/api/auth/magic', {
        method: 'POST',
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify({ email })
    });
    if (res.status === 202) return (await res.json()) as { sent: boolean; dev_link?: string };
    return { sent: false };
}

/** POST /api/auth/logout — clears the session cookie. */
export async function logout(fetchFn: typeof fetch = fetch): Promise<void> {
    await fetchFn('/api/auth/logout', { method: 'POST' });
}

/** The Google sign-in entry point — a full-page navigation (the OAuth consent +
 *  redirect flow is browser-driven, not fetch). The backend 302s to Google. */
export const GOOGLE_SIGNIN_HREF = '/api/auth/google';

/** The calm sign-in feedback the backend redirects back with (?signin=…). */
export type SigninFlag = 'ok' | 'expired' | 'invalid' | 'error' | 'google_unavailable';

export function signinFlag(search: string): SigninFlag | null {
    const v = new URLSearchParams(search).get('signin');
    return v === 'ok' || v === 'expired' || v === 'invalid' || v === 'error' ||
        v === 'google_unavailable'
        ? v
        : null;
}
