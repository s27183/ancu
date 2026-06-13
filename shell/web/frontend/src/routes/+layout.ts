// Static SPA: no SSR. The shell is auth-cookie driven and serves from a static
// host (shell-architecture.md §8 / aleap's pattern); a single client-side source
// of truth for auth-driven UI. Flip to SSR only once the cookie-forwarding load
// path is exercised end-to-end (a later slice, when login lands).
export const ssr = false;
export const prerender = false;
