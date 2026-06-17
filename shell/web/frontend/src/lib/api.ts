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

// --- Onboarding: create a plan card (8-S3) ----------------------------------
// POST /api/plan-cards on the shell backend (fh_shell_h_plan_cards): plan-first
// (constraint #1) — the body carries mode-derived inputs, never a property. The
// shell mints the tenant JWT and forwards to the engine, then records its view.

/** The onboarding payload — exactly the fields the engine base turn reads. */
export interface OnboardingInput {
    state: string;
    target_price_range: [number, number];
    target_zone: string[];
    /** The pinned suburb's SAL code — the stable opaque key the engine's
     *  projection_state() prefers for resolving the scheme-eligibility state. Today's
     *  ABS names are state-qualified ("Richmond (Vic.)") so the name-based target_zone
     *  lookup already resolves a single state; the SAL just decouples state resolution
     *  from that name string, which is otherwise overloaded (it's also the plan-card
     *  title + the frontend's card match key). target_zone/state stay as fallbacks. */
    target_sal: string;
    intent: 'owner_occupier' | 'investment';
}

/** The engine's 202 reply: the new plan card + the base turn now running async. */
export interface CreatePlanCardResult {
    plan_card_id: string;
    turn_id: string;
}

/** A discriminated outcome so the UI can branch calmly (§7.1) without try/catch.
 *  `auth_required` is the EXPECTED pre-login path: the shell requires a user JWT and
 *  the login flow is a later slice, so an unauthenticated create returns 401 today. */
export type CreateOutcome =
    | { kind: 'created'; result: CreatePlanCardResult }
    | { kind: 'auth_required' }
    | { kind: 'error'; status: number };

/** POST /api/plan-cards. No auth header is attached here yet — the login slice will
 *  decide how the user JWT travels (cookie vs bearer) and wire it in; until then a
 *  create returns 401 → `auth_required`. */
export async function createPlanCard(
    body: OnboardingInput,
    fetchFn: typeof fetch = fetch
): Promise<CreateOutcome> {
    const res = await fetchFn('/api/plan-cards', {
        method: 'POST',
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify(body)
    });
    if (res.status === 202) {
        return { kind: 'created', result: (await res.json()) as CreatePlanCardResult };
    }
    if (res.status === 401) return { kind: 'auth_required' };
    return { kind: 'error', status: res.status };
}

// --- Plan projection: read a card + list a user's cards (8-S4c) --------------
// Both go to the shell backend, which gates on the (user, card) ownership binding
// (plan_card_views) before touching the engine — the engine treats user_id as opaque
// (§9.3, no cross-DB join). An unowned/unknown/malformed id is a uniform 404. Live
// fill streams over SSE separately (planCardStream.ts).
import type { PlanCard, PlanCardSummary } from '$lib/planCard';

/** A discriminated read outcome so the projection branches calmly (§7.1). 404 is the
 *  EXPECTED "no plan for this zone yet / not signed in" path → onboarding CTA. */
export type PlanCardOutcome =
    | { kind: 'ok'; card: PlanCard }
    | { kind: 'not_found' }
    | { kind: 'auth_required' }
    | { kind: 'error'; status: number };

/** GET /api/plan-cards/:id via the shell backend (relays the engine's typed state). */
export async function getPlanCard(
    id: string,
    fetchFn: typeof fetch = fetch
): Promise<PlanCardOutcome> {
    const res = await fetchFn(`/api/plan-cards/${encodeURIComponent(id)}`);
    if (res.ok) return { kind: 'ok', card: (await res.json()) as PlanCard };
    if (res.status === 404) return { kind: 'not_found' };
    if (res.status === 401) return { kind: 'auth_required' };
    return { kind: 'error', status: res.status };
}

/** GET /api/plan-cards — the signed-in user's plan-card display handles (shell-DB
 *  read, no engine call). 401 (signed out) returns an empty list — the caller treats
 *  "no card" and "signed out" identically (both → the create CTA). */
export async function listPlanCards(
    fetchFn: typeof fetch = fetch
): Promise<PlanCardSummary[]> {
    const res = await fetchFn('/api/plan-cards');
    if (!res.ok) return [];
    const body = (await res.json()) as { plan_cards?: PlanCardSummary[] };
    return body.plan_cards ?? [];
}

// --- Chat: ask a question about the card (8-S4d) ----------------------------
// POST /api/plan-cards/:id/messages — starts a kind:qa turn over the FILLED card.
// The engine answers 202 {turn_id} immediately; the bilingual answer + machinery
// (tool_use/tool_result/text_delta) stream over the SAME /events EventSource
// (subscribeConversation). 409 = a turn is already in flight (one per card) → the
// caller asks the user to wait; the engine, not the shell, owns serialization.

/** A discriminated send outcome so the chat branches calmly. `busy` is the EXPECTED
 *  path while another turn (e.g. the base fill) is still running. */
export type MessageOutcome =
    | { kind: 'accepted'; turnId: string }
    | { kind: 'busy' }
    | { kind: 'auth_required' }
    | { kind: 'not_found' }
    | { kind: 'error'; status: number };

/** POST a chat message. The answer does NOT come back here — it streams over the
 *  card's event stream; this returns only the turn handle to attribute those frames. */
export async function postMessage(
    planCardId: string,
    message: string,
    fetchFn: typeof fetch = fetch
): Promise<MessageOutcome> {
    const res = await fetchFn(`/api/plan-cards/${encodeURIComponent(planCardId)}/messages`, {
        method: 'POST',
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify({ message })
    });
    if (res.status === 202) {
        const body = (await res.json()) as { turn_id: string };
        return { kind: 'accepted', turnId: body.turn_id };
    }
    if (res.status === 409) return { kind: 'busy' };
    if (res.status === 401) return { kind: 'auth_required' };
    if (res.status === 404) return { kind: 'not_found' };
    return { kind: 'error', status: res.status };
}
