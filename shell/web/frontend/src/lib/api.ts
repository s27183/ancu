// Thin client for the shell BACKEND (Erlang, :8081) — never the engine directly
// (shell-architecture.md §1). In dev, vite proxies /api + /health to :8081; in prod
// the same backend serves this bundle. The auth'd surfaces (/api/me, /api/plan-cards,
// SSE proxy) land as the UX surfaces are built (8-S2..8-S4); 8-S0 ships only the
// health probe that proves the frontend↔backend proxy seam.

export interface Health {
    status: string;
    service: string;
}

/** GET /health on the shell backend. Throws on a non-2xx or transport error. */
export async function getHealth(fetchFn: typeof fetch = fetch): Promise<Health> {
    const res = await fetchFn('/health');
    if (!res.ok) throw new Error(`health ${res.status}`);
    return (await res.json()) as Health;
}
