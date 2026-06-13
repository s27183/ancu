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

// --- Suburb map data (8-S2) -------------------------------------------------
// The map's RAW-metric source (suburb-data-foundation §2 "two readers"). The shell
// backend proxies the engine's GET /api/engine/suburbs (8-S1) and relays the body
// verbatim; the engine passes facts_jsonb through, so these fields mirror the DB.
// PUBLIC: this read carries no user JWT (the map is the pre-login landing surface).

/** Raw per-suburb metrics, verbatim from the engine's facts_jsonb (all optional —
 *  a suburb may be missing any feed). Vietnamese ancestry is the killer layer;
 *  crime is RAW map-display only — never a band or verdict (it is not a decision
 *  input; valuable-to-show-not-valid-to-decide). */
export interface SuburbFacts {
    vietnamese_ancestry_pct?: number;
    seifa_irsad_decile?: number;
    seifa_irsad_score?: number;
    seifa_irsad_population?: number;
    census_total_persons?: number;
    crime_incidents_per_1000?: number;
    crime_incidents_annual?: number;
    crime_period?: string;
}

export interface Suburb {
    sal_code: string;
    name: string;
    state: string;
    lga_name: string | null;
    is_capital_city: boolean;
    /** null for the non-geographic pseudo-localities — they have no map point. */
    centroid: { lat: number; lon: number } | null;
    facts: SuburbFacts;
}

/** A feed's CC-BY attribution line — rendered in the map's attribution strip (§6.1). */
export interface SuburbSource {
    source_id: string;
    name: string;
    publisher: string;
    license: string;
    attribution: string;
}

export interface SuburbsResponse {
    state: string;
    suburbs: Suburb[];
    attribution: SuburbSource[];
}

/** GET /api/suburbs?state=… via the shell backend. `state` is required (the engine's
 *  query grain); throws on a non-2xx (incl. the engine's 400 missing/invalid_state). */
export async function getSuburbs(
    state: string,
    fetchFn: typeof fetch = fetch
): Promise<SuburbsResponse> {
    const res = await fetchFn(`/api/suburbs?state=${encodeURIComponent(state)}`);
    if (!res.ok) throw new Error(`suburbs ${res.status}`);
    return (await res.json()) as SuburbsResponse;
}
