// Cloudflare Pages Function — proxy /health to the shell backend (deployment.md §3).
// Same mechanism/rationale as functions/api/[[path]].js. The SPA itself doesn't call
// /health; this exists so app.<apex>/health mirrors the shell's health for uptime
// checks that target the SPA origin. (The post-deploy smoke hits api.<apex>/health
// and engine.<apex>/health directly — deployment.md §5.)

export async function onRequest(context) {
  const { request, env } = context;
  const origin = env.SHELL_ORIGIN;
  if (!origin) {
    return new Response('SHELL_ORIGIN not configured', { status: 503 });
  }
  return fetch(new Request(origin.replace(/\/$/, '') + '/health', request));
}
