// Cloudflare Pages Function — same-origin reverse proxy for /api/*.
//
// FH's SPA calls RELATIVE /api/* (no API-base env) so the browser sees ONE origin
// (app.<apex>). This Function forwards each call server-side to the shell backend and
// relays the response verbatim — including Set-Cookie (the shell sets a host-only,
// Secure, SameSite=Lax cookie, which the browser then attaches to app.<apex>) and
// streaming bodies (SSE plan-card events, 8-S4b). This keeps the shell's no-CORS,
// host-only-cookie design working unchanged (deployment.md §3/§4 step 7).
//
// Why a Function and not a _redirects rule: Cloudflare Pages _redirects "will only
// support relative URLs on your site. You cannot proxy external domains" (and 200
// rewrites are unsupported) — so an external proxy MUST be a Pages Function.
//
// Config: set SHELL_ORIGIN (Pages Function runtime env var, e.g. https://api.<apex>)
// in the Cloudflare Pages dashboard. This catch-all matches /api/* only; the SPA
// fallback (static/_redirects) handles everything else.

export async function onRequest(context) {
  const { request, env } = context;
  const origin = env.SHELL_ORIGIN;
  if (!origin) {
    return new Response('SHELL_ORIGIN not configured', { status: 503 });
  }
  const url = new URL(request.url);
  // Preserve the full /api/... path + query; the shell owns the /api/* routes.
  const target = origin.replace(/\/$/, '') + url.pathname + url.search;
  // new Request(target, request) copies method, headers (incl. cookie/authorization),
  // and the body stream. Returning the fetch Response streams it back (SSE-safe) and
  // preserves response headers, including Set-Cookie.
  return fetch(new Request(target, request));
}
