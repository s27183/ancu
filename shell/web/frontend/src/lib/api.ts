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
import type { PlanCard, PlanCardSummary, ChecklistStatusMap } from '$lib/planCard';

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

// --- Simulate: preview a structural what-if (W9) ----------------------------
// POST /api/plan-cards/:id/simulate — the engine recomputes the base plan resolver-only
// under {target_price, state} overrides and returns the recomputed outcomes in the BODY.
// A PREVIEW: ephemeral, no persist, NO usage (so no token gate, unlike a chat turn). The
// returned `outcomes` are keyed by component_id (engine-contract §10.1) — the SAME keying
// as the GET card's content.components — so the projection merges them onto its existing
// entries by one key. Saving a previewed scenario is a separate refine turn (W8), not this.

/** The structural what-if overrides. All optional — send only the dimensions varied.
 *  `target_price` is a single number (the engine collapses it to a [p,p] point range);
 *  `state` is an AU state code; `horizon` is the dispose-phase hold years H (a positive
 *  integer — the engine rejects 0/non-int; its ABSENCE is the long/indefinite default,
 *  engine-contract §10.5). property_type is Phase-B (per-property) → engine 400. */
export interface SimulateOverrides {
    target_price?: number;
    state?: string;
    horizon?: number;
}

/** A discriminated preview outcome. `invalid` is the engine's 400 for a rejected
 *  override (e.g. property_type, or an unknown key) — surfaced calmly, not thrown. */
export type SimulateOutcome =
    | { kind: 'ok'; outcomes: Record<string, Record<string, unknown>> }
    | { kind: 'invalid' }
    | { kind: 'not_found' }
    | { kind: 'auth_required' }
    | { kind: 'error'; status: number };

/** POST a what-if preview. Returns the recomputed outcomes (component_id-keyed); the
 *  caller overlays them on the card's components and re-renders. Nothing is persisted. */
export async function simulatePlanCard(
    planCardId: string,
    overrides: SimulateOverrides,
    fetchFn: typeof fetch = fetch
): Promise<SimulateOutcome> {
    const res = await fetchFn(`/api/plan-cards/${encodeURIComponent(planCardId)}/simulate`, {
        method: 'POST',
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify({ overrides })
    });
    if (res.ok) {
        const body = (await res.json()) as { outcomes: Record<string, Record<string, unknown>> };
        return { kind: 'ok', outcomes: body.outcomes ?? {} };
    }
    if (res.status === 400) return { kind: 'invalid' };
    if (res.status === 404) return { kind: 'not_found' };
    if (res.status === 401) return { kind: 'auth_required' };
    return { kind: 'error', status: res.status };
}

/** A discriminated save outcome. `busy` is the engine's 409 (a turn is already running
 *  for this card); `invalid` its 400 for a rejected override — both surfaced calmly. */
export type RefineOutcome =
    | { kind: 'accepted'; turnId: string }
    | { kind: 'busy' }
    | { kind: 'invalid' }
    | { kind: 'not_found' }
    | { kind: 'auth_required' }
    | { kind: 'error'; status: number };

/** SAVE a previewed scenario (W8) — the COMMIT half of simulate. Same override shape;
 *  the engine persists the inputs + runs a base_resolver turn (answers 202 {turn_id}),
 *  and the recomputed components arrive over the SAME /events stream as the live fill —
 *  not in this reply. Resolver-only, so nothing is metered. */
export async function refinePlanCard(
    planCardId: string,
    overrides: SimulateOverrides,
    fetchFn: typeof fetch = fetch
): Promise<RefineOutcome> {
    const res = await fetchFn(`/api/plan-cards/${encodeURIComponent(planCardId)}/refine`, {
        method: 'POST',
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify({ overrides })
    });
    if (res.status === 202) {
        const body = (await res.json()) as { turn_id: string };
        return { kind: 'accepted', turnId: body.turn_id };
    }
    if (res.status === 409) return { kind: 'busy' };
    if (res.status === 400) return { kind: 'invalid' };
    if (res.status === 404) return { kind: 'not_found' };
    if (res.status === 401) return { kind: 'auth_required' };
    return { kind: 'error', status: res.status };
}

// --- Profile financials: enrich income/debts → recompute capacity (IC5) ------
// POST /api/plan-cards/:id/profile — write the household financial FACTS (income +
// debts) to the profiles SOT (IC4). Unlike simulate/refine (structural what-ifs) and
// cash-on-hand (a client-side verdict figure), this is a persisted FACT: it commits
// directly (no preview) and the engine recomputes borrowing capacity resolver-only,
// re-deriving every card on the profile (a fact is profile-shared). The recomputed
// outcomes — capacity → mortgage_finance → disposition full-horizon — arrive over the
// SAME /events stream as the live fill, NOT in this reply. Resolver-only → no usage,
// no meter gate. FULL-REPLACE: the cockpit owns the whole financials object and submits
// it whole, so omitting a field clears it (honest-partial → null downstream).

/** The household financial facts the serviceability resolver consumes (IC4 scope).
 *  All fields optional — capacity computes once income is present. Money figures are
 *  non-negative numbers; the engine validates fail-closed and rejects any other key. */
export interface HouseholdFinancials {
    income?: {
        assessable_income?: number;
        foreign_sourced_component?: number;
    };
    debts?: {
        hecs_balance?: number;
        credit_card_limits_total?: number;
        personal_loans_balance?: number;
        car_loan_balance?: number;
        buy_now_pay_later_balance?: number;
    };
}

/** A discriminated write outcome. `accepted` carries `cardsRecomputing` — the count of
 *  profile cards that actually started a recompute; 0 means the addressed card was mid-
 *  turn and skipped (it picks up the facts on its next recompute → "try again shortly").
 *  `invalid` carries the engine's human-readable 400 detail (a rejected field/non-number). */
export type ProfileFinancialsOutcome =
    | { kind: 'accepted'; cardsRecomputing: number }
    | { kind: 'invalid'; detail: string }
    | { kind: 'not_found' }
    | { kind: 'auth_required' }
    | { kind: 'error'; status: number };

/** POST the household financials. The recomputed components do NOT come back here — they
 *  stream over the card's /events (this card is one of the recomputing siblings); this
 *  returns only whether the write was accepted and how many cards started. */
export async function setProfileFinancials(
    planCardId: string,
    financials: HouseholdFinancials,
    fetchFn: typeof fetch = fetch
): Promise<ProfileFinancialsOutcome> {
    const res = await fetchFn(`/api/plan-cards/${encodeURIComponent(planCardId)}/profile`, {
        method: 'POST',
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify({ household_financials: financials })
    });
    if (res.status === 202) {
        const body = (await res.json()) as { cards_recomputing?: number };
        return { kind: 'accepted', cardsRecomputing: body.cards_recomputing ?? 0 };
    }
    if (res.status === 400) {
        const body = (await res.json().catch(() => ({}))) as { detail?: string };
        return { kind: 'invalid', detail: body.detail ?? '' };
    }
    if (res.status === 404) return { kind: 'not_found' };
    if (res.status === 401) return { kind: 'auth_required' };
    return { kind: 'error', status: res.status };
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

// --- Checklist status: attest a phase action done/not (Flow view) ------------
// PATCH /api/plan-cards/:id/checklist-status — the user-set layer (task 7). USER-ATTESTED
// state, not a computed figure: a small jsonb patch, NO recompute and NO usage (zero-cost,
// so no meter gate). The engine is SOT — the 200 returns the AUTHORITATIVE checklist_status
// map, so the caller renders engine state, not a local guess (optimistic flip, reconciled
// from this response; revert on failure). Cross-tab live fan-out (the engine also emits
// checklist_status_changed over SSE) is a future consumer — a fresh GET reflects it.

/** A discriminated toggle outcome. `ok` carries the engine's authoritative map. */
export type ChecklistStatusOutcome =
    | { kind: 'ok'; checklistStatus: ChecklistStatusMap }
    | { kind: 'invalid' }
    | { kind: 'auth_required' }
    | { kind: 'not_found' }
    | { kind: 'error'; status: number };

/** PATCH one phase action's status. Returns the full updated checklist_status map (the
 *  engine SOT) so the caller can set state from it rather than trust the optimistic flip. */
export async function setChecklistStatus(
    planCardId: string,
    phase: string,
    actionId: string,
    status: 'done' | 'not_started',
    fetchFn: typeof fetch = fetch
): Promise<ChecklistStatusOutcome> {
    const res = await fetchFn(
        `/api/plan-cards/${encodeURIComponent(planCardId)}/checklist-status`,
        {
            method: 'PATCH',
            headers: { 'content-type': 'application/json' },
            body: JSON.stringify({ phase, action_id: actionId, status })
        }
    );
    if (res.ok) {
        const body = (await res.json()) as { checklist_status?: ChecklistStatusMap };
        return { kind: 'ok', checklistStatus: body.checklist_status ?? {} };
    }
    if (res.status === 400) return { kind: 'invalid' };
    if (res.status === 401) return { kind: 'auth_required' };
    if (res.status === 404) return { kind: 'not_found' };
    return { kind: 'error', status: res.status };
}

// --- Property attachment: Phase B (Mode-C investor) --------------------------
// POST /api/plan-cards/:id/properties — attach a property to the card and run the
// per-property (Phase-B) turn (engine-contract §12). The body is a NORMALIZED
// property_card (the neutral facts a source supplies); who PRODUCES it (URL paste,
// curator, extension) is a separate deferred unit — this manual form is the first
// producer (Slice 3). The engine GENERATES the property_id and answers 202; the
// per-property component_filled events stream over the SAME /events SSE, tagged with
// property_id (routed into content.addenda.<pid> by the projection). This is an AGENT
// turn (property_assessment is two-path) → it EMITS usage, so the shell meter-gates it
// like `ask`: an over-limit user is blocked 402 BEFORE the turn starts (billing.md §7).

/** The normalized property facts the engine's property_assessment resolver reads. The
 *  four required facts ground the resolver-computed gross yield + verdict; the optional
 *  facts (year_built, land_size, strata) are agent grounding for the richer fill. */
export interface PropertyCardInput {
    price: number;
    state: string;
    suburb: string;
    property_type: string;
    year_built?: number;
    land_size?: number;
    strata?: boolean;
}

/** The engine's 202 reply: the new property + the Phase-B turn now running async. */
export interface AttachPropertyResult {
    plan_card_id: string;
    property_id: string;
    turn_id: string;
}

/** A discriminated attach outcome so the UI branches calmly. `over_limit` is the meter
 *  402 (carrying the tier + token usage so the modal can prompt an upgrade); `busy` the
 *  409 (a turn is already running for this card); `invalid` the engine's 400 (a non-
 *  investor blueprint, or a missing/invalid property fact — `detail` is human-readable). */
export type AttachOutcome =
    | { kind: 'accepted'; result: AttachPropertyResult }
    | { kind: 'over_limit'; tier: string; used: number; limit: number }
    | { kind: 'busy' }
    | { kind: 'invalid'; detail: string }
    | { kind: 'auth_required' }
    | { kind: 'not_found' }
    | { kind: 'error'; status: number };

/** POST a property_card to attach + run Phase B. The per-property components do NOT come
 *  back here — they stream over the card's /events; this returns only the handles (incl.
 *  property_id) so the caller can select the new property and route its live fills. */
export async function attachProperty(
    planCardId: string,
    property: PropertyCardInput,
    fetchFn: typeof fetch = fetch
): Promise<AttachOutcome> {
    const res = await fetchFn(`/api/plan-cards/${encodeURIComponent(planCardId)}/properties`, {
        method: 'POST',
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify(property)
    });
    if (res.status === 202) {
        return { kind: 'accepted', result: (await res.json()) as AttachPropertyResult };
    }
    if (res.status === 402) {
        const body = (await res.json().catch(() => ({}))) as {
            tier?: string;
            used_tokens?: number;
            limit_tokens?: number;
        };
        return {
            kind: 'over_limit',
            tier: body.tier ?? '',
            used: body.used_tokens ?? 0,
            limit: body.limit_tokens ?? 0
        };
    }
    if (res.status === 409) return { kind: 'busy' };
    if (res.status === 400) {
        const body = (await res.json().catch(() => ({}))) as { detail?: string };
        return { kind: 'invalid', detail: body.detail ?? '' };
    }
    if (res.status === 401) return { kind: 'auth_required' };
    if (res.status === 404) return { kind: 'not_found' };
    return { kind: 'error', status: res.status };
}
