<script lang="ts">
    // The plan projection (8-S4c): the base plan as it surfaces on the map-home — the
    // sole plan UI (no separate dashboard; firsthomey-shell-direction). It finds the
    // user's plan card for THIS zone (title === suburb, the onboarding zone label),
    // seeds from the GET snapshot, then merges live component_filled frames over the
    // SSE proxy. The zone→suburb gradient (per-suburb overlay) is deferred — this shows
    // the property-agnostic BASE components, identical across suburbs.
    import { onMount, tick } from 'svelte';
    import { t } from '$lib/i18n';
    import { lang } from '$lib/stores/lang';
    import {
        getPlanCard,
        listPlanCards,
        simulatePlanCard,
        refinePlanCard,
        setProfileFinancials,
        setChecklistStatus,
        attachProperty,
        setTransactionDates,
        uploadDocument,
        type SimulateOverrides,
        type HouseholdFinancials,
        type PropertyCardInput,
        type TransactionDatesInput
    } from '$lib/api';
    import { subscribePlanCard, type PlanCardStream } from '$lib/planCardStream';
    import {
        BASE_COMPONENT_ORDER,
        type ComponentEntry,
        type UiTab,
        type ProfileOutcome,
        type MoneyRange,
        type JourneySwimlaneOutcome,
        type PhasePlaybookOutcome,
        type DispositionOutcome,
        type ChecklistStatusMap,
        type PropertyAddendum,
        harvestCashEvents,
        firstComponentEntry,
        PROFILE_COMPONENT_IDS
    } from '$lib/planCard';
    import { AU_STATES } from '$lib/map';
    import { money, moneyRange } from '$lib/format';
    import ComponentCard from '$lib/renderers/ComponentCard.svelte';
    import OverviewCard from '$lib/renderers/OverviewCard.svelte';
    import Calculator from '$lib/renderers/Calculator.svelte';
    import FlowView from '$lib/renderers/FlowView.svelte';
    import Tabs from '$lib/Tabs.svelte';
    import Chat from '$lib/Chat.svelte';
    import Modal from '$lib/Modal.svelte';

    let { suburbName, suburbState, onplan }: {
        suburbName: string;
        suburbState: string;
        onplan: () => void;
    } = $props();

    // The plan is shown one lifecycle TAB at a time (the blueprint's ui_tabs spine —
    // plan-card-lifecycle-restoration.md §3 — plus a Q&A tab) so the user never scrolls a
    // long plan. `sub` is a tab_id (or 'qa'); it defaults to the first declared tab.
    let sub = $state<string>('');
    // The lifecycle tabs the engine's in-scope blueprint declares (travels with the GET
    // card). Fallback for an older engine with no ui_tabs: one tab per base component,
    // preserving the pre-lifecycle behaviour so a version skew never blanks the plan.
    let uiTabs = $state<UiTab[]>([]);
    const FALLBACK_TABS: UiTab[] = BASE_COMPONENT_ORDER.map((c) => ({
        tab_id: c,
        kind: 'components',
        components: [c]
    }));
    const activeTab = $derived(uiTabs.find((t) => t.tab_id === sub) ?? uiTabs[0]);
    // The lifecycle rail renders every tab EXCEPT the chat surface: qa is the shell's
    // own (kind: 'qa', no component fills it — engine-contract), rendered once via the
    // Q&A button below + the `sub === 'qa'` content branch. The engine declares qa last
    // in ui_tabs; rendering it in the rail too would duplicate the button AND crash
    // (there is deliberately no plan.ltab.qa label — qa uses plan.tab.qa).
    const railTabs = $derived(uiTabs.filter((t) => t.kind !== 'qa'));

    // Sub-tab rail grouping (2026-07-09, Son's request), updated 2026-07-11 once Mode B's
    // task-13 rewrite retired the last blueprint on the pre-restructure flat tab vocabulary
    // (plan-card-lifecycle-restoration.md §11.3) — every in-scope blueprint now declares at
    // most 5 rail tabs (overview/flow/budget/[portfolio|family]/qa), under RAIL_GROUP_THRESHOLD,
    // so grouping is currently dormant everywhere; kept as a static map (not deleted) since a
    // future blueprint growing past the threshold again just needs an entry added here.
    // `overview` and `qa` are never grouped (always-visible anchors); everything else buckets
    // into the coarse halves of this project's buy→hold→sell mental model (see the swimlane's
    // own finer-grained `plan.phase.*` labels below for the 6-step version this coarsens).
    // An unmapped future tab_id defaults into 'buy' rather than silently vanishing.
    const TAB_GROUP: Record<string, 'buy' | 'hold'> = {
        flow: 'buy',
        family: 'buy',
        budget: 'hold',
        portfolio: 'hold'
    };
    const RAIL_GROUP_THRESHOLD = 5;
    const overviewTab = $derived(railTabs.find((t) => t.tab_id === 'overview'));
    const nonOverviewRailTabs = $derived(railTabs.filter((t) => t.tab_id !== 'overview'));
    const railGrouped = $derived(nonOverviewRailTabs.length > RAIL_GROUP_THRESHOLD);
    // Pure derivation from `sub`, not a $state mutated in an $effect (the autofixer
    // flags that pattern) — this also means the group toggle always follows `sub`
    // automatically, including any programmatic jump elsewhere in this file, same
    // "derive, don't clamp" idiom as NewsTicker's safeIdx. Defaults to 'buy' while
    // `sub` is 'overview'/'qa' (group-less) or on first render.
    const railGroup = $derived(TAB_GROUP[sub] ?? 'buy');
    const groupedRailTabs = $derived(
        nonOverviewRailTabs.filter((t) => (TAB_GROUP[t.tab_id] ?? 'buy') === railGroup)
    );
    // Selecting a group the current tab isn't in jumps to that group's first tab —
    // railGroup then follows for free (it's derived from `sub`, not set here).
    // Re-clicking the group `sub` is already in is a no-op, matching the toggle's
    // "already active" visual state.
    function selectGroup(g: 'buy' | 'hold') {
        if ((TAB_GROUP[sub] ?? 'buy') === g) return;
        const first = nonOverviewRailTabs.find((t) => (TAB_GROUP[t.tab_id] ?? 'buy') === g);
        if (first) sub = first.tab_id;
    }

    // The budget (Cash-calculator) tab's three sub-tabs (§7.3): the cockpit inputs + the
    // "Bạn đã đủ chưa?" verdict → the cash-events table → the breakdown detail. Labels reuse
    // the existing calculator keys. A self-owned table row routes here to 'detail'.
    let budgetSub = $state<string>('ready');
    // The budget sub-tabs are derived below, after `viewComponents` (the 4th "Full horizon"
    // tab is gated on the disposition component existing).

    let phase = $state<'loading' | 'ready' | 'no_card' | 'error'>('loading');
    let components = $state<Record<string, ComponentEntry>>({});
    // Per-property addenda (engine-contract §12), keyed by property_id — a sibling of the
    // base `components` map. Seeded from the GET snapshot's content.addenda, then merged by
    // the SSE (a property_id-tagged component_filled routes here, not into base). The
    // selected property (null = base plan) overlays its components into viewComponents.
    let addenda = $state<Record<string, PropertyAddendum>>({});
    let selectedPropertyId = $state<string | null>(null);
    let cardId = $state<string | null>(null);
    // The card's blueprint (engine GET) — gates the attach affordance: only the investor
    // blueprint has a built per-property turn (engine supports_phase_b/1 is Slice-A-exact),
    // so the "+ Attach property" entry point shows only for it (a Mode-A card would 400).
    let blueprintSlug = $state<string>('');
    let turnDone = $state(false);
    let turnFailed = $state(false);
    // The card user-set layer (the Flow checklist done-toggles), seeded from the GET card
    // and overlaid onto phase_playbook actions at render. The engine is SOT: a toggle is
    // optimistic for immediacy, then reconciled from the PATCH response (revert on failure).
    let checklistStatus = $state<ChecklistStatusMap>({});

    // The rendered height of the sticky sub-tab rail region, fed to --tabrail-top so
    // the nested Budget sub-rail's own sticky offset tracks the rail's real, variable
    // height (it grows a row when the rail is grouped) instead of a stale hardcoded
    // rem (see the .pp-sticky-top / .pp-subcontent markup below).
    let stickyTopHeight = $state(0);

    let stream: PlanCardStream | null = null;
    // A generation token so a retry's async can't be clobbered by a stale in-flight one.
    let gen = 0;

    const running = $derived(phase === 'ready' && !turnDone && !turnFailed);

    // ── Structural what-if (W9, engine-contract §10.1) ──────────────────────
    // Vary target_price / state → POST /simulate → the engine recomputes the base plan
    // resolver-only and returns outcomes keyed by component_id (same keying as the GET
    // snapshot). EPHEMERAL: previewOutcomes overlays the live components for ALL tabs but
    // nothing persists — saving a scenario is a separate refine turn (W8). property_type
    // is Phase-B (per-property), so it's not offered here. State seeds from the suburb the
    // card is projected under; only a CHANGED state is sent as an override.
    let priceInput = $state('');
    // Seeded to suburbState by resetPreview() (called at the top of load()), not at init —
    // $state captures only the initial prop value, and the bar only renders post-load.
    let stateSelect = $state('');
    // The horizon slider (TW6): the dispose-phase hold years H — a structural what-if at
    // PLAN scope (it re-renders the Full-horizon tab + the Flow dispose column, not just one
    // renderer — preview-is-commit-minus-persistence, place-at-scope-of-effect), so it lives
    // in the cockpit alongside price/state. 0 = no sale projection (the Mode-A long/indefinite
    // default — the engine rejects horizon=0, so we omit it rather than send it). Seeded from
    // the card's current H; only a value that differs from that baseline is sent as an override.
    let horizonValue = $state(0);
    const baselineHorizon = $derived(
        (components.disposition?.outcome as DispositionOutcome | undefined)?.horizon_years ?? 0
    );
    let previewOutcomes = $state<Record<string, Record<string, unknown>> | null>(null);
    let previewing = $state(false);
    let previewError = $state(false);
    const previewActive = $derived(previewOutcomes !== null);
    // Save (W8) — the COMMIT half: refine persists the previewed overrides + runs a
    // base_resolver turn whose recomputed components arrive over the SAME SSE. `committing`
    // is set on a 202 so onDone clears the preview once the saved (== previewed) snapshot
    // is live, making the hand-off seamless (commit == preview parity).
    let saving = $state(false);
    let saveError = $state(false);
    let committing = $state(false);

    // Cash-on-hand (the cockpit's 4th input) — CLIENT-SIDE only: a subtraction against the
    // engine's verified need range, never a regulated recompute. Independent of the price/
    // state scenario (it's the user's own figure), so it survives a scenario reset.
    let cashOnHandInput = $state('');
    const cashOnHand = $derived.by((): number | null => {
        const n = Number(cashOnHandInput.replace(/[^0-9.]/g, ''));
        return cashOnHandInput.trim() !== '' && Number.isFinite(n) && n >= 0 ? n : null;
    });

    // ── Household financials (IC5) ──────────────────────────────────────────
    // A persisted FACT — income + debts — distinct from the what-if above (price/state/
    // horizon → ephemeral simulate) and from cash-on-hand (a client-side verdict figure).
    // It commits directly (a fact, no preview) via POST /profile (IC4); the engine
    // recomputes borrowing capacity resolver-only and the new figures (capacity →
    // mortgage_finance → disposition full-horizon) arrive over the SAME /events SSE — this
    // card is one of the recomputing siblings. No usage → no meter gate (like refine).
    let finIncome = $state('');
    let finForeign = $state('');
    let finHecs = $state('');
    let finCards = $state('');
    let finPersonal = $state('');
    let finCar = $state('');
    let finBnpl = $state('');
    let finSaving = $state(false);
    // A profile write committed (cards_recomputing>0); the live recompute is in flight, so
    // the inputs lock and we re-seed from the engine SOT once onDone fires.
    let finRecomputing = $state(false);
    let finError = $state<null | 'busy' | 'invalid' | 'error'>(null);
    let finErrorDetail = $state('');
    const finBusy = $derived(running || finSaving || finRecomputing);

    // Seed the finance fields from the live profile outcome (engine SOT). LOAD-BEARING
    // for correctness, not just UX: the write is FULL-REPLACE, so the form must hold the
    // whole financials object — seeding keeps untouched figures intact across an edit (else
    // editing income would wipe stored debts). Honest-partial: a null/absent figure → blank.
    // Resolved via PROFILE_COMPONENT_IDS, not a literal `buyer_profile` — Mode C/D name
    // this component investor_profile / investor_profile_foreign (planCard.ts comment).
    function seedFinancials() {
        const o = firstComponentEntry(components, PROFILE_COMPONENT_IDS)?.outcome as
            | ProfileOutcome
            | undefined;
        const num = (v: unknown): string => (typeof v === 'number' ? String(v) : '');
        finIncome = num(o?.assessable_income);
        finForeign = num(o?.foreign_sourced_income_component);
        const d = o?.debts ?? undefined;
        finHecs = num(d?.hecs_balance);
        finCards = num(d?.credit_card_limits_total);
        finPersonal = num(d?.personal_loans_balance);
        finCar = num(d?.car_loan_balance);
        finBnpl = num(d?.buy_now_pay_later_balance);
    }

    // Build the FULL financials object from the form (full-replace — a blank field is
    // omitted → cleared downstream → honest-partial null). Parses non-negative numbers,
    // matching the engine's fail-closed validator (which is the backstop, not the gate).
    function buildFinancials(): HouseholdFinancials {
        const n = (s: string): number | undefined => {
            const v = Number(s.replace(/[^0-9.]/g, ''));
            return s.trim() !== '' && Number.isFinite(v) && v >= 0 ? v : undefined;
        };
        const income: Record<string, number> = {};
        const inc = n(finIncome);
        if (inc !== undefined) income.assessable_income = inc;
        const fgn = n(finForeign);
        if (fgn !== undefined) income.foreign_sourced_component = fgn;
        const debts: Record<string, number> = {};
        const pairs: Array<[string, string]> = [
            ['hecs_balance', finHecs],
            ['credit_card_limits_total', finCards],
            ['personal_loans_balance', finPersonal],
            ['car_loan_balance', finCar],
            ['buy_now_pay_later_balance', finBnpl]
        ];
        for (const [key, raw] of pairs) {
            const v = n(raw);
            if (v !== undefined) debts[key] = v;
        }
        const hf: HouseholdFinancials = {};
        if (Object.keys(income).length) hf.income = income;
        if (Object.keys(debts).length) hf.debts = debts;
        return hf;
    }

    // Submit the financials (the COMMIT — a fact, no preview). On 202 with a started
    // recompute, flip to recomputing (turnDone=false hides the settled state, blocks a
    // racing 2nd submit); the recomputed capacity arrives over the live SSE and onDone
    // re-seeds from SOT. cards_recomputing===0 → the card was mid-turn (skipped) → retry.
    async function saveFinancials() {
        if (!cardId || finBusy) return;
        finError = null;
        finErrorDetail = '';
        finSaving = true;
        const res = await setProfileFinancials(cardId, buildFinancials());
        finSaving = false;
        if (res.kind === 'accepted') {
            if (res.cardsRecomputing > 0) {
                turnDone = false;
                finRecomputing = true;
            } else {
                finError = 'busy';
            }
        } else if (res.kind === 'invalid') {
            finError = 'invalid';
            finErrorDetail = res.detail;
        } else {
            finError = 'error';
        }
    }

    // True when the user has selected an attached property to view (vs the base plan).
    const viewingProperty = $derived(
        selectedPropertyId !== null && !!addenda[selectedPropertyId]
    );

    // The components the tabs render — three projections of ONE map (unify-views):
    //   • a selected property → base components with that addendum's per-property
    //     components overlaid ON TOP (the property's real figures win). No what-if overlay:
    //     a fixed property has no price/state/horizon to sweep.
    //   • the base plan, under an active preview → each entry with its outcome swapped for
    //     the previewed one (renderer/scope preserved, merged by component_id).
    //   • the base plan, no preview → the live base components.
    //
    // Whole lifecycle -> P-4 · The engine is coupled to no shell -> The web frontend -> per-property addendum overlay
    // A per-property addendum overlays viewComponents with zero new renderers, and selecting
    // a property suppresses the what-if cockpit. Concluded at Mode-C Phase B.
    const viewComponents = $derived.by((): Record<string, ComponentEntry> => {
        if (viewingProperty && selectedPropertyId) {
            return { ...components, ...addenda[selectedPropertyId].components };
        }
        if (!previewOutcomes) return components;
        const pv = previewOutcomes;
        return Object.fromEntries(
            Object.entries(components).map(([cid, entry]) => [
                cid,
                pv[cid] ? { ...entry, outcome: pv[cid] } : entry
            ])
        );
    });

    // The property selector rail (Mode-C Phase-B): "Base plan" + one entry per attached
    // property (id '' = base, id = property_id). Labelled from the property_card suburb,
    // honest-partial to a generic label when a live attach hasn't seeded it yet.
    const propertyIds = $derived(Object.keys(addenda));
    const propertyTabs = $derived([
        { id: '', label: $t('plan.prop.base') },
        ...propertyIds.map((pid, i) => {
            const pc = addenda[pid].property_card;
            return { id: pid, label: pc.suburb || `${$t('plan.prop.untitled')} ${i + 1}` };
        })
    ]);

    // Switch the projection between the base plan and an attached property. Choosing a
    // property clears any base what-if preview (a fixed property has nothing to sweep).
    function selectProperty(pid: string | null) {
        selectedPropertyId = pid;
        if (pid !== null) resetPreview();
    }

    // ── Attach a property (Phase B, Mode-C investor) ─────────────────────────
    // The first PRODUCER of a normalized property_card (engine §12): a manual entry form.
    // Richer sources (URL paste #9, Tìm Nhà #8, extension) POST the SAME contract when
    // built; this is the substrate they reduce to. Gated to the investor blueprint — the
    // engine's per-property turn (property_assessment) is wired for it alone (Slice A).
    const supportsPhaseB = $derived(blueprintSlug === 'investor-domestic-au');
    let showAttach = $state(false);
    let apPrice = $state('');
    let apSuburb = $state('');
    let apState = $state('');
    let apType = $state('');
    let apYear = $state('');
    let apLand = $state('');
    let apStrata = $state(false);
    let attaching = $state(false);
    // null = no error; otherwise a calm reason for the modal (the upgrade prompt carries
    // the tier so the copy can name it). Cleared on each (re)open + each submit.
    let attachError = $state<null | { kind: 'over_limit'; tier: string } | { kind: 'busy' }
        | { kind: 'invalid'; detail: string } | { kind: 'error' }>(null);

    // The property_type options the form offers. These are NOT free strings: property_type
    // rides through to the engine's `property_fit_investor` outcome, which validates it against
    // a CLOSED enum at the commit seam — a value outside it crashes the Phase-B turn
    // (outcome_nonconforming). So these MUST be exactly the engine enum (the producer is the
    // SOT). The established-vs-new split is also the load-bearing investor distinction
    // (depreciation eligibility). Labels are bilingual via i18n; the value is the stored fact.
    const PROPERTY_TYPES = [
        'established_house', 'established_apartment', 'new_house',
        'new_apartment', 'off_the_plan', 'house_and_land'
    ] as const;

    function openAttach() {
        apPrice = '';
        apSuburb = suburbName; // seed from the projected suburb — the common case
        apState = suburbState;
        apType = '';
        apYear = '';
        apLand = '';
        apStrata = false;
        attachError = null;
        showAttach = true;
    }

    // Build the property_card from the form. price + suburb + state + property_type are
    // required (the submit button is disabled until they're present + price parses); the
    // three optional facts are sent only when filled (honest-partial — absent ≠ zero).
    function buildPropertyCard(): PropertyCardInput | null {
        const price = Number(apPrice.replace(/[^0-9.]/g, ''));
        if (!(Number.isFinite(price) && price > 0)) return null;
        if (!apSuburb.trim() || !apState.trim() || !apType) return null;
        const pc: PropertyCardInput = {
            price,
            suburb: apSuburb.trim(),
            state: apState,
            property_type: apType
        };
        const year = Number(apYear.replace(/[^0-9]/g, ''));
        if (apYear.trim() !== '' && Number.isFinite(year) && year > 0) pc.year_built = year;
        const land = Number(apLand.replace(/[^0-9.]/g, ''));
        if (apLand.trim() !== '' && Number.isFinite(land) && land > 0) pc.land_size = land;
        if (apStrata) pc.strata = true;
        return pc;
    }
    const attachReady = $derived(buildPropertyCard() !== null && !attaching);

    // Submit → POST the attach. On 202, seed the addendum with the submitted property_card
    // (so the selector shows the new property immediately, honest-partial: empty components
    // render PENDING) and SELECT it; the per-property components stream in over the live SSE
    // (load()'s onComponentFilled routes them by property_id, preserving this property_card).
    // turnDone=false surfaces the running indicator while the Phase-B turn fills.
    async function submitAttach() {
        if (!cardId) return;
        const pc = buildPropertyCard();
        if (!pc) return;
        attaching = true;
        attachError = null;
        const res = await attachProperty(cardId, pc);
        attaching = false;
        if (res.kind === 'accepted') {
            const pid = res.result.property_id;
            addenda = { ...addenda, [pid]: { property_card: pc, components: {} } };
            selectedPropertyId = pid;
            resetPreview();
            turnDone = false;
            showAttach = false;
        } else if (res.kind === 'over_limit') {
            attachError = { kind: 'over_limit', tier: res.tier };
        } else if (res.kind === 'busy') {
            attachError = { kind: 'busy' };
        } else if (res.kind === 'invalid') {
            attachError = { kind: 'invalid', detail: res.detail };
        } else {
            attachError = { kind: 'error' };
        }
    }

    // ── Submit transaction dates (settlement_prep B, engine-contract §11) ─────
    // Once a contract is signed, two dates the user ATTESTS activate settlement_prep's
    // dated critical path. A per-property submit (not the attach payload, not an upload):
    // resolver-only → NO meter gate (unlike attach). Offered only for the selected attached
    // property when its settlement_prep is present (the journey tab). The recomputed
    // settlement_checklist streams over the SAME open SSE — no re-subscribe.
    const settleEntry = $derived(viewComponents.settlement_prep);
    const settleStatus = $derived(
        (settleEntry?.outcome as { dates_status?: string } | undefined)?.dates_status ?? null
    );
    let showSettle = $state(false);
    let stContract = $state('');
    let stSettlement = $state('');
    let savingDates = $state(false);
    let settleError = $state<
        null | { kind: 'not_attached' } | { kind: 'busy' } | { kind: 'invalid'; code: string }
        | { kind: 'error' }
    >(null);

    function openSettle() {
        const tx = selectedPropertyId ? addenda[selectedPropertyId]?.transaction : null;
        stContract = tx?.contract_signed_date ?? '';
        stSettlement = tx?.settlement_date ?? '';
        settleError = null;
        showSettle = true;
    }

    // Both dates required; settlement strictly after contract (ISO yyyy-mm-dd sorts
    // lexically, so a string compare mirrors the engine's date check — fail-fast before
    // the round trip; the engine re-validates authoritatively).
    function buildTransactionDates(): TransactionDatesInput | null {
        if (!stContract || !stSettlement) return null;
        if (!(stSettlement > stContract)) return null;
        return { contract_signed_date: stContract, settlement_date: stSettlement };
    }
    const settleReady = $derived(buildTransactionDates() !== null && !savingDates);

    async function submitSettle() {
        if (!cardId || !selectedPropertyId) return;
        const dates = buildTransactionDates();
        if (!dates) return;
        savingDates = true;
        settleError = null;
        const res = await setTransactionDates(cardId, selectedPropertyId, dates);
        savingDates = false;
        if (res.kind === 'accepted') {
            // Optimistic-seed the addendum's transaction slot from the SUBMITTED dates (the
            // client's own attested truth, echoed back by the engine); the recomputed
            // settlement_checklist arrives over the live SSE. turnDone=false surfaces the
            // running indicator while the resolver-only re-fill runs.
            const pid = selectedPropertyId;
            addenda = {
                ...addenda,
                [pid]: { ...addenda[pid], transaction: dates }
            };
            turnDone = false;
            showSettle = false;
        } else if (res.kind === 'not_attached') {
            settleError = { kind: 'not_attached' };
        } else if (res.kind === 'busy') {
            settleError = { kind: 'busy' };
        } else if (res.kind === 'invalid') {
            settleError = { kind: 'invalid', code: res.code };
        } else {
            settleError = { kind: 'error' };
        }
    }

    // ── Upload a lease document (due_diligence B, the `<from_document>` surface) ──
    // Uploading the current lease of a tenanted property runs due_diligence's lease_interpretation
    // leaf — a DOCUMENT-GATED two-path re-fill (an AGENT turn → metered → the over_limit gate
    // applies, UNLIKE the resolver-only transaction submit). Offered for the selected attached
    // property on its due_diligence card. The reviewed risk_assessment_investor streams over the
    // SAME open SSE — no re-subscribe. The bytes are sent inline + are never persisted engine-side.
    const ddEntry = $derived(viewComponents.due_diligence);
    const ddStatus = $derived(
        (ddEntry?.outcome as { docs_status?: string } | undefined)?.docs_status ?? null
    );
    let showLease = $state(false);
    let leaseFile = $state<File | null>(null);
    let uploadingLease = $state(false);
    let leaseError = $state<
        null | { kind: 'not_attached' } | { kind: 'busy' } | { kind: 'invalid'; code: string }
        | { kind: 'over_limit' } | { kind: 'error' }
    >(null);

    function openLease() {
        leaseFile = null;
        leaseError = null;
        showLease = true;
    }

    function onLeaseFile(e: Event) {
        const input = e.target as HTMLInputElement;
        leaseFile = input.files?.[0] ?? null;
    }
    const leaseReady = $derived(leaseFile !== null && !uploadingLease);

    async function submitLease() {
        if (!cardId || !selectedPropertyId || !leaseFile) return;
        uploadingLease = true;
        leaseError = null;
        const res = await uploadDocument(cardId, selectedPropertyId, leaseFile);
        uploadingLease = false;
        if (res.kind === 'accepted') {
            // The reviewed risk_assessment_investor arrives over the live SSE; surface the
            // running indicator while the document-gated two-path re-fill runs.
            turnDone = false;
            showLease = false;
        } else if (res.kind === 'not_attached') {
            leaseError = { kind: 'not_attached' };
        } else if (res.kind === 'busy') {
            leaseError = { kind: 'busy' };
        } else if (res.kind === 'over_limit') {
            leaseError = { kind: 'over_limit' };
        } else if (res.kind === 'invalid') {
            leaseError = { kind: 'invalid', code: res.code };
        } else {
            leaseError = { kind: 'error' };
        }
    }

    // The budget (Cash-calculator) sub-tabs (§7.3): cockpit + verdict → cash-events table →
    // breakdown detail → the disposition projection. The 4th "Full horizon" tab is present
    // only when the engine emits a disposition component (honest-partial tab presence; its
    // own content is honest-partial too — an invitation until a hold horizon H is set). TW5.
    const budgetTabs = $derived([
        { id: 'ready', label: $t('plan.cash.ready') },
        { id: 'table', label: $t('plan.cash.spine') },
        { id: 'detail', label: $t('plan.cash.breakdown') },
        ...(viewComponents.disposition ? [{ id: 'horizon', label: $t('plan.cash.horizon') }] : [])
    ]);

    // Whole lifecycle -> P-7 · One declaration per outcome shape -> The web frontend -> the Budget breakdown draws the declared cards
    // The interactive Budget tab drew only the Calculator, so every other component its ui_tabs
    // entry declares was computed and never shown (measured 2026-10-07 in Chrome: a Mode C
    // card's tax_structure, with its setup band, on no tab; B and D drop firb_workflow,
    // cross_border_funding, yield and non-resident tax the same way). The breakdown sub-tab
    // now draws them below the Calculator; cash_position and disposition keep their own
    // sub-tabs, and an uncomputed card is skipped, not shown pending (behavior 11).
    const budgetCards = $derived(
        (activeTab?.interactive ? activeTab.components : []).filter(
            (cid) => cid !== 'cash_position' && cid !== 'disposition' && viewComponents[cid]
        )
    );

    // ── Flow view (task 10) ────────────────────────────────────────────────
    // The legal/temporal spine's three live inputs, read from viewComponents so a what-if
    // preview re-renders the Flow too: the journey (swimlane spine), the playbook (per-phase
    // actions + risks), and cash_events (the budget figures the actions LINK to by id).
    // settlement_prep is Phase-B → simply absent at base (honest-partial in FlowView).
    const flowJourney = $derived(
        viewComponents.purchase_journey?.outcome as JourneySwimlaneOutcome | undefined
    );
    const flowPlaybook = $derived(
        viewComponents.phase_playbook?.outcome as PhasePlaybookOutcome | undefined
    );
    // Harvested from every viewComponents entry exposing cash_events (not just
    // cash_position) — mirrors the engine's own multi-source harvest so a Mode-C hold-phase
    // action's budget_ref (e.g. lodge_annual_return → tax_refund, sourced from tax_structure)
    // resolves to an amount chip here too. See harvestCashEvents in $lib/planCard.
    const flowCashEvents = $derived(harvestCashEvents(viewComponents));

    // Toggle one phase action's done-state. The engine is SOT: flip optimistically for
    // immediacy, PATCH, then set checklistStatus from the AUTHORITATIVE returned map;
    // revert to the pre-flip snapshot on any failure. Zero-cost (no usage, no meter gate).
    async function toggleChecklist(
        phaseId: string,
        actionId: string,
        next: 'done' | 'not_started'
    ) {
        if (!cardId) return;
        const prev = checklistStatus;
        // Optimistic overlay (new objects so $state sees the change).
        const phaseMap = { ...(prev[phaseId] ?? {}) };
        if (next === 'done') phaseMap[actionId] = 'done';
        else delete phaseMap[actionId];
        checklistStatus = { ...prev, [phaseId]: phaseMap };

        const res = await setChecklistStatus(cardId, phaseId, actionId, next);
        if (res.kind === 'ok') checklistStatus = res.checklistStatus;
        else checklistStatus = prev; // reconcile to the engine: revert the optimistic flip
    }

    // The card's current target price (band or point), shown as the what-if baseline hint.
    // Resolved via PROFILE_COMPONENT_IDS — see seedFinancials above for why.
    const currentPriceLabel = $derived.by((): string | null => {
        const o = firstComponentEntry(components, PROFILE_COMPONENT_IDS)?.outcome as
            | ProfileOutcome
            | undefined;
        const r = o?.target_price_range as MoneyRange | null | undefined;
        if (!Array.isArray(r) || r.length !== 2) return null;
        return r[0] === r[1] ? money(r[0], $lang) : moneyRange(r, $lang);
    });

    // The overrides the current inputs describe — shared by preview and save so the saved
    // scenario is exactly the one on screen. Only a CHANGED state is an override (the
    // suburb's own state is the baseline); a non-positive / blank price is omitted.
    function buildOverrides(): SimulateOverrides {
        const overrides: SimulateOverrides = {};
        const p = Number(priceInput.replace(/[^0-9.]/g, ''));
        if (priceInput.trim() !== '' && Number.isFinite(p) && p > 0) overrides.target_price = p;
        if (stateSelect && stateSelect !== suburbState) overrides.state = stateSelect;
        // horizon: only a positive H that differs from the card's baseline (omit 0 — the
        // engine has no "clear horizon" override; absence IS the indefinite default).
        if (horizonValue >= 1 && horizonValue !== baselineHorizon) overrides.horizon = horizonValue;
        return overrides;
    }

    async function runPreview() {
        if (!cardId) return;
        const overrides = buildOverrides();
        // Nothing varied → clear any prior preview rather than round-trip a no-op.
        if (Object.keys(overrides).length === 0) {
            previewOutcomes = null;
            previewError = false;
            return;
        }
        previewing = true;
        previewError = false;
        saveError = false;
        const res = await simulatePlanCard(cardId, overrides);
        previewing = false;
        if (res.kind === 'ok') {
            previewOutcomes = res.outcomes;
        } else {
            previewError = true;
            previewOutcomes = null;
        }
    }

    // Save the previewed scenario (W8) → POST the refine commit. On 202 the override inputs
    // are persisted and a base_resolver turn recomputes the snapshot; we flip to running
    // (turnDone=false hides the bar and blocks a racing 2nd save) and keep the preview
    // overlay shown until onDone swaps in the now-live committed components.
    async function saveScenario() {
        if (!cardId) return;
        const overrides = buildOverrides();
        if (Object.keys(overrides).length === 0) return;
        saving = true;
        saveError = false;
        const res = await refinePlanCard(cardId, overrides);
        saving = false;
        if (res.kind === 'accepted') {
            turnDone = false;
            committing = true;
        } else {
            saveError = true;
        }
    }

    function resetPreview() {
        previewOutcomes = null;
        previewError = false;
        saveError = false;
        priceInput = '';
        stateSelect = suburbState;
        horizonValue = baselineHorizon;
    }

    async function load() {
        resetPreview();
        const myGen = ++gen;
        stream?.close();
        stream = null;
        phase = 'loading';
        components = {};
        addenda = {};
        selectedPropertyId = null;
        checklistStatus = {};
        uiTabs = [];
        cardId = null;
        blueprintSlug = '';
        turnDone = false;
        turnFailed = false;

        // Signed-out or no cards → listPlanCards() returns []; no zone match → the CTA.
        const cards = await listPlanCards();
        if (myGen !== gen) return;
        const match = cards.find((c) => c.title === suburbName) ?? null;
        if (!match) {
            phase = 'no_card';
            return;
        }

        // Live fill from a cursor. Merge is idempotent (keyed by component_id). Opens a
        // FRESH EventSource each call rather than being called once: subscribePlanCard
        // closes its stream on every terminal event by design (correct for chat's
        // single-turn use — subscribeConversation stays open instead). This card's page
        // visit spans MANY turns (scenario save, financials commit, checklist toggle,
        // property attach, ...) all reusing the same `stream` var, so onDone below
        // reopens from the terminal's own event id — without this, the channel dies
        // after the visit's first turn and every later action's spinner never resolves
        // (turnDone flips false but nothing is left alive to flip it back to true).
        function subscribeLive(cid: string, cursor?: number) {
            stream = subscribePlanCard(cid, {
                onComponentFilled: (entry) => {
                    if (myGen !== gen) return;
                    if (entry.property_id) {
                        // A Phase-B (per-property) fill → route into its addendum (engine §12),
                        // not the base map. Create the addendum if a live attach beat the
                        // snapshot (its property_card seeds from the snapshot re-read / the
                        // attach flow, Slice 3); merge is idempotent (keyed by component_id).
                        const pid = entry.property_id;
                        const ad = addenda[pid] ?? { property_card: {}, components: {} };
                        addenda = {
                            ...addenda,
                            [pid]: {
                                ...ad,
                                components: { ...ad.components, [entry.component_id]: entry }
                            }
                        };
                    } else {
                        components = { ...components, [entry.component_id]: entry };
                    }
                },
                onDone: (failed, lastEventId) => {
                    if (myGen !== gen) return;
                    if (failed) turnFailed = true;
                    turnDone = true;
                    // A just-committed save (W8): the recomputed components are now merged
                    // live (== what was previewed), so drop the preview overlay and reset
                    // the inputs — the hand-off is invisible thanks to commit==preview parity.
                    if (committing) {
                        committing = false;
                        resetPreview();
                    }
                    // A just-committed financials write (IC5): the recomputed capacity is
                    // now live, so re-seed the fields from the engine SOT (reflects what was
                    // actually stored, incl. any normalization). Gated on finRecomputing so
                    // an unrelated onDone (base turn / scenario save) never clobbers an
                    // in-progress finance draft.
                    if (finRecomputing) {
                        finRecomputing = false;
                        seedFinancials();
                    }
                    // Reopen from this terminal's own id so the NEXT action in this visit
                    // has a live channel too (see the comment above subscribeLive).
                    subscribeLive(cid, lastEventId ?? undefined);
                }
                // onError: EventSource auto-reconnects; stay calm (no banner).
            }, cursor);
        }

        const res = await getPlanCard(match.plan_card_id);
        if (myGen !== gen) return;
        if (res.kind === 'ok') {
            components = res.card.content.components ?? {};
            addenda = res.card.content.addenda ?? {}; // per-property snapshots (engine §12)
            blueprintSlug = res.card.blueprint_slug ?? ''; // gates the attach affordance
            horizonValue = baselineHorizon; // seed the slider from the card's saved H
            seedFinancials(); // seed income/debts from the card's stored profile facts (IC5)
            checklistStatus = res.card.checklist_status ?? {};
            uiTabs = res.card.ui_tabs?.length ? res.card.ui_tabs : FALLBACK_TABS;
            if (!uiTabs.some((t) => t.tab_id === sub)) sub = uiTabs[0]?.tab_id ?? '';
            cardId = match.plan_card_id;
            phase = 'ready';
            // The GET snapshot is the authoritative latest projection. Take the done-state
            // from turn_running (a settled card has no terminal to replay once we subscribe
            // from the cursor), and subscribe the SSE FROM the snapshot's event_cursor so the
            // replay carries only post-snapshot (live) events — never an OLD turn from the
            // append-only log replayed over the fresh snapshot.
            turnDone = res.card.turn_running === false;
            subscribeLive(match.plan_card_id, res.card.event_cursor);
        } else if (res.kind === 'error') {
            phase = 'error';
        } else {
            // not_found | auth_required → no plan for this zone yet → the CTA.
            phase = 'no_card';
        }
    }

    onMount(() => {
        load();
        return () => {
            gen++;
            stream?.close();
        };
    });
</script>

{#if phase === 'loading'}
    <div class="pp-state"><p>{$t('plan.loading')}</p></div>
{:else if phase === 'no_card'}
    <div class="plan-cta">
        <p class="placeholder">{$t('sheet.plan.placeholder')}</p>
        <button type="button" class="primary" onclick={onplan}>{$t('onboarding.cta')}</button>
    </div>
{:else if phase === 'error'}
    <div class="pp-state">
        <p>{$t('plan.error')}</p>
        <button type="button" onclick={load}>{$t('plan.retry')}</button>
    </div>
{:else}
    {#if running}
        <p class="pp-running"><span class="pp-spinner" aria-hidden="true"></span>{$t('plan.running')}</p>
    {/if}

    <!-- Property bar (Mode-C Phase-B): the base-vs-property selector (shown once ≥1 property
         is attached; selecting one overlays its addendum into every tab) + the "+ Attach
         property" entry point (shown for the investor blueprint — the only one with a built
         per-property turn). The button is the FIRST attach affordance + a producer of the
         normalized property_card; richer sources (URL paste, Tìm Nhà) POST the same contract. -->
    {#if supportsPhaseB}
        <div class="pp-propbar">
            {#if propertyIds.length > 0}
                <Tabs
                    tabs={propertyTabs}
                    active={selectedPropertyId ?? ''}
                    onSelect={(id) => selectProperty(id === '' ? null : id)}
                />
            {/if}
            <button type="button" class="pp-attach-btn" onclick={openAttach}>
                + {$t('plan.attach.cta')}
            </button>
        </div>
    {/if}

    {#if showAttach}
        <Modal title={$t('plan.attach.title')} onClose={() => (showAttach = false)}>
            <form class="pp-attach-form" onsubmit={(e) => { e.preventDefault(); submitAttach(); }}>
                <p class="pp-attach-intro">{$t('plan.attach.intro')}</p>
                <label class="pp-af-field">
                    <span class="pp-af-label">{$t('plan.attach.price')}</span>
                    <input type="text" inputmode="numeric" bind:value={apPrice}
                        placeholder={$t('plan.attach.price_ph')} />
                </label>
                <label class="pp-af-field">
                    <span class="pp-af-label">{$t('plan.attach.suburb')}</span>
                    <input type="text" bind:value={apSuburb} />
                </label>
                <label class="pp-af-field">
                    <span class="pp-af-label">{$t('plan.attach.state')}</span>
                    <select bind:value={apState}>
                        {#each AU_STATES as s (s)}
                            <option value={s}>{s}</option>
                        {/each}
                    </select>
                </label>
                <label class="pp-af-field">
                    <span class="pp-af-label">{$t('plan.attach.ptype')}</span>
                    <select bind:value={apType}>
                        <option value="" disabled>{$t('plan.attach.ptype_ph')}</option>
                        {#each PROPERTY_TYPES as pt (pt)}
                            <option value={pt}>{$t(`plan.attach.ptype.${pt}` as 'plan.attach.ptype.established_house')}</option>
                        {/each}
                    </select>
                </label>
                <p class="pp-af-optional">{$t('plan.attach.optional')}</p>
                <label class="pp-af-field">
                    <span class="pp-af-label">{$t('plan.attach.year')}</span>
                    <input type="text" inputmode="numeric" bind:value={apYear} />
                </label>
                <label class="pp-af-field">
                    <span class="pp-af-label">{$t('plan.attach.land')}</span>
                    <input type="text" inputmode="numeric" bind:value={apLand} />
                </label>
                <label class="pp-af-check">
                    <input type="checkbox" bind:checked={apStrata} />
                    <span>{$t('plan.attach.strata')}</span>
                </label>

                {#if attachError}
                    <p class="pp-af-error">
                        {#if attachError.kind === 'over_limit'}
                            {$t('plan.attach.err.over_limit')}
                        {:else if attachError.kind === 'busy'}
                            {$t('plan.attach.err.busy')}
                        {:else if attachError.kind === 'invalid'}
                            {attachError.detail || $t('plan.attach.err.invalid')}
                        {:else}
                            {$t('plan.attach.err.generic')}
                        {/if}
                    </p>
                {/if}

                <div class="pp-af-actions">
                    <button type="button" class="pp-af-cancel" onclick={() => (showAttach = false)}>
                        {$t('plan.attach.cancel')}
                    </button>
                    <button type="submit" class="primary" disabled={!attachReady}>
                        {attaching ? $t('plan.attach.submitting') : $t('plan.attach.submit')}
                    </button>
                </div>
            </form>
        </Modal>
    {/if}

    <!-- settlement_prep B: the two attested transaction dates (engine-contract §11). A
         resolver-only re-fill (no usage / no meter gate); the recomputed settlement_checklist
         streams over the live SSE. Opened from the journey tab for a selected property. -->
    {#if showSettle}
        <Modal title={$t('plan.settle.title')} onClose={() => (showSettle = false)}>
            <form class="pp-attach-form" onsubmit={(e) => { e.preventDefault(); submitSettle(); }}>
                <p class="pp-attach-intro">{$t('plan.settle.intro')}</p>
                <label class="pp-af-field">
                    <span class="pp-af-label">{$t('plan.settle.contract_date')}</span>
                    <input type="date" bind:value={stContract} />
                </label>
                <label class="pp-af-field">
                    <span class="pp-af-label">{$t('plan.settle.settlement_date')}</span>
                    <input type="date" bind:value={stSettlement} min={stContract || undefined} />
                </label>

                {#if settleError}
                    <p class="pp-af-error">
                        {#if settleError.kind === 'not_attached'}
                            {$t('plan.settle.err.not_attached')}
                        {:else if settleError.kind === 'busy'}
                            {$t('plan.settle.err.busy')}
                        {:else if settleError.kind === 'invalid'}
                            {settleError.code === 'settlement_not_after_contract'
                                ? $t('plan.settle.err.order')
                                : $t('plan.settle.err.invalid')}
                        {:else}
                            {$t('plan.settle.err.generic')}
                        {/if}
                    </p>
                {/if}

                <div class="pp-af-actions">
                    <button type="button" class="pp-af-cancel" onclick={() => (showSettle = false)}>
                        {$t('plan.settle.cancel')}
                    </button>
                    <button type="submit" class="primary" disabled={!settleReady}>
                        {savingDates ? $t('plan.settle.submitting') : $t('plan.settle.submit')}
                    </button>
                </div>
            </form>
        </Modal>
    {/if}

    {#if showLease}
        <Modal title={$t('plan.lease.title')} onClose={() => (showLease = false)}>
            <form class="pp-attach-form" onsubmit={(e) => { e.preventDefault(); submitLease(); }}>
                <p class="pp-attach-intro">{$t('plan.lease.intro')}</p>
                <label class="pp-af-field">
                    <span class="pp-af-label">{$t('plan.lease.file')}</span>
                    <input
                        type="file"
                        accept=".pdf,.txt,application/pdf,text/plain"
                        onchange={onLeaseFile}
                    />
                </label>

                {#if leaseError}
                    <p class="pp-af-error">
                        {#if leaseError.kind === 'not_attached'}
                            {$t('plan.lease.err.not_attached')}
                        {:else if leaseError.kind === 'busy'}
                            {$t('plan.lease.err.busy')}
                        {:else if leaseError.kind === 'over_limit'}
                            {$t('plan.lease.err.over_limit')}
                        {:else if leaseError.kind === 'invalid'}
                            {$t('plan.lease.err.invalid')}
                        {:else}
                            {$t('plan.lease.err.generic')}
                        {/if}
                    </p>
                {/if}

                <div class="pp-af-actions">
                    <button type="button" class="pp-af-cancel" onclick={() => (showLease = false)}>
                        {$t('plan.lease.cancel')}
                    </button>
                    <button type="submit" class="primary" disabled={!leaseReady}>
                        {uploadingLease ? $t('plan.lease.uploading') : $t('plan.lease.submit')}
                    </button>
                </div>
            </form>
        </Modal>
    {/if}

    <!-- Sticky region atop the scrolling plan body: the lifecycle sub-tab rail. Its real
         rendered height is measured via bind:clientHeight and fed to --tabrail-top below,
         so the nested Budget sub-rail (Tabs.svelte) — which stacks its own sticky rail
         just below this region — tracks the rail's presence instead of a stale
         hand-picked rem. (A per-card KB-news ticker used to live here, then as a sticky
         footer below the tab content — removed 2026-07-09, Son's call: the homepage's
         unfiltered ticker is enough, and the per-card fetch/render/dismiss UI added
         clutter for little payoff. Backend untouched — GET/PATCH .../news, GATE 11, the
         compiled artifact's news entries are all still live; this was a shell-only
         removal, easy to re-wire if wanted later.) -->
    <div class="pp-sticky-top" bind:clientHeight={stickyTopHeight}>
        <!-- Sub-tabs: one per plan section + a Q&A tab — each section shows on its own,
             so the user never scrolls a long plan. Horizontally scrollable on narrow
             screens. Past RAIL_GROUP_THRESHOLD rail tabs (Modes B/C/D), a second row
             appears: Overview/group-toggle/Q&A always visible on top, the active
             group's tabs below — under the threshold (Modes A/E) this renders the
             original single flat row, unchanged. -->
        <div class="pp-subtabs-outer">
            {#if railGrouped}
                <div class="pp-subtabs" role="tablist">
                    {#if overviewTab}
                        <button
                            type="button"
                            role="tab"
                            aria-selected={sub === overviewTab.tab_id}
                            class:active={sub === overviewTab.tab_id}
                            onclick={() => overviewTab && (sub = overviewTab.tab_id)}
                            >{$t('plan.ltab.overview')}</button
                        >
                    {/if}
                    <button
                        type="button"
                        role="tab"
                        class="pp-railgroup-btn"
                        aria-selected={railGroup === 'buy'}
                        class:active={railGroup === 'buy'}
                        onclick={() => selectGroup('buy')}>{$t('plan.railgroup.buy')}</button
                    >
                    <button
                        type="button"
                        role="tab"
                        class="pp-railgroup-btn"
                        aria-selected={railGroup === 'hold'}
                        class:active={railGroup === 'hold'}
                        onclick={() => selectGroup('hold')}>{$t('plan.railgroup.hold')}</button
                    >
                    <button
                        type="button"
                        role="tab"
                        aria-selected={sub === 'qa'}
                        class:active={sub === 'qa'}
                        onclick={() => (sub = 'qa')}>{$t('plan.tab.qa')}</button
                    >
                </div>
                <div
                    class="pp-subtabs pp-subtabs-group"
                    role="tablist"
                    aria-label={$t(`plan.railgroup.${railGroup}` as 'plan.railgroup.buy')}
                >
                    {#each groupedRailTabs as tab (tab.tab_id)}
                        <button
                            type="button"
                            role="tab"
                            aria-selected={sub === tab.tab_id}
                            class:active={sub === tab.tab_id}
                            onclick={() => (sub = tab.tab_id)}
                            >{$t(`plan.ltab.${tab.tab_id}` as 'plan.ltab.overview')}</button
                        >
                    {/each}
                </div>
            {:else}
                <div class="pp-subtabs" role="tablist">
                    {#each railTabs as tab (tab.tab_id)}
                        <button
                            type="button"
                            role="tab"
                            aria-selected={sub === tab.tab_id}
                            class:active={sub === tab.tab_id}
                            onclick={() => (sub = tab.tab_id)}
                            >{$t(`plan.ltab.${tab.tab_id}` as 'plan.ltab.overview')}</button
                        >
                    {/each}
                    <button
                        type="button"
                        role="tab"
                        aria-selected={sub === 'qa'}
                        class:active={sub === 'qa'}
                        onclick={() => (sub = 'qa')}>{$t('plan.tab.qa')}</button
                    >
                </div>
            {/if}
        </div>
    </div>

    <!-- Cross-tab what-if indicator: the price/state cockpit lives in the Cash-calculator
         tab (the financial spine is where you reason about money), but a scenario re-renders
         EVERY tab — so on the other tabs, signpost that the figures are a preview, with a
         reset. The calculator tab shows the full cockpit instead (below). -->
    {#if previewActive && sub !== 'qa' && !activeTab?.interactive}
        <div class="pp-whatif active">
            <p class="pp-wi-banner">{$t('plan.whatif.banner')}</p>
            <button type="button" class="pp-wi-reset" onclick={resetPreview}
                >{$t('plan.whatif.reset')}</button
            >
        </div>
    {/if}

    <div class="pp-subcontent" style="--tabrail-top: {stickyTopHeight}px">
        {#if sub === 'qa'}
            <!-- Chat runs over the FILLED card; the engine 409s a qa turn while the base
                 turn is still running, so gate it on the base turn having finished. -->
            {#if cardId && turnDone && !turnFailed}
                <Chat planCardId={cardId} />
            {:else}
                <p class="pp-pending">{$t('plan.qa.pending')}</p>
            {/if}
        {:else if activeTab?.kind === 'synthesis'}
            <!-- The Overview tab: a shell-composed synthesis over the filled base
                 outcomes (the "plan in 90 seconds"), not the raw component cards. -->
            <OverviewCard components={viewComponents} filling={running} />
        {:else if activeTab?.kind === 'flow'}
            <!-- The Flow view: the legal/temporal spine — the journey swimlane as the
                 overview, each phase drilling into its actions (with the done-toggle +
                 budget/component links) and KB-grounded risks. -->
            <FlowView
                journey={flowJourney}
                playbook={flowPlaybook}
                cashEvents={flowCashEvents}
                components={viewComponents}
                {checklistStatus}
                onToggle={toggleChecklist}
                filling={running}
            />
        {:else if activeTab?.interactive}
            <!-- The Cash-calculator tab: the financial spine + the cockpit that drives it
                 (the prototype's interactive calculator, engine-driven). price/state →
                 simulate (re-renders every tab); cash-on-hand → client-side verdict only;
                 property type is per-property (Phase B) so it's shown locked, not faked.
                 The interactive tab is [cash_position]; any other component falls through. -->
            <section class="pp-card pp-calc pp-flat">
                {#if viewComponents.cash_position}
                    <Tabs tabs={budgetTabs} active={budgetSub} onSelect={(id) => (budgetSub = id)} />

                    {#if budgetSub === 'ready'}
                        {#if viewingProperty}
                            <!-- A selected property shows its OWN cash figures (the per-property
                                 budget_envelope_investor). The base what-if cockpit + financials
                                 editor are base-plan controls, so they're hidden here; the table/
                                 detail/horizon sub-tabs already read the per-property outcome. -->
                            <p class="pp-calc-intro">{$t('plan.prop.viewing')}</p>
                            <Calculator
                                outcome={viewComponents.cash_position.outcome}
                                view="verdict"
                                {cashOnHand}
                                components={viewComponents}
                                density="full"
                            />
                        {:else}
                        <!-- Tab 1: the cockpit inputs + the "Bạn đã đủ chưa?" verdict. -->
                        <p class="pp-calc-intro">{$t('plan.cockpit.intro')}</p>
                        <div class="pp-cockpit">
                            <label class="pp-ck-field">
                                <span class="pp-ck-label">{$t('plan.whatif.price')}</span>
                                <input
                                    type="text"
                                    inputmode="numeric"
                                    bind:value={priceInput}
                                    placeholder={currentPriceLabel
                                        ? `${$t('plan.whatif.current')} ${currentPriceLabel}`
                                        : $t('plan.cash.whatif.placeholder')}
                                    onkeydown={(e) => e.key === 'Enter' && runPreview()}
                                />
                            </label>
                            <label class="pp-ck-field">
                                <span class="pp-ck-label">{$t('plan.whatif.state')}</span>
                                <select bind:value={stateSelect} onchange={runPreview}>
                                    {#each AU_STATES as s (s)}
                                        <option value={s}>{s}</option>
                                    {/each}
                                </select>
                            </label>
                            <!-- Horizon slider (TW6): drag to project the sell-side over H
                                 years; oninput shows the live value, onchange (on release)
                                 runs ONE simulate (not per-tick during the drag). 0 = no sale
                                 projection (the Mode-A default) → omitted from the override. -->
                            <label class="pp-ck-field pp-ck-horizon">
                                <span class="pp-ck-label">
                                    {$t('plan.whatif.horizon')}
                                    <span class="pp-ck-hval">
                                        {horizonValue >= 1
                                            ? `${horizonValue} ${$t('plan.whatif.years_unit')}`
                                            : $t('plan.whatif.horizon_off')}
                                    </span>
                                </span>
                                <input
                                    type="range"
                                    min="0"
                                    max="30"
                                    step="1"
                                    bind:value={horizonValue}
                                    onchange={runPreview}
                                />
                            </label>
                            <label class="pp-ck-field pp-ck-locked">
                                <span class="pp-ck-label">{$t('plan.cockpit.ptype')}</span>
                                <select disabled>
                                    <option>{$t('plan.attach_property')}</option>
                                </select>
                            </label>
                            <label class="pp-ck-field">
                                <span class="pp-ck-label">{$t('plan.cash.whatif.label')}</span>
                                <input
                                    type="text"
                                    inputmode="numeric"
                                    bind:value={cashOnHandInput}
                                    placeholder={$t('plan.cash.whatif.placeholder')}
                                />
                            </label>
                        </div>
                        <div class="pp-cockpit-actions">
                            <button type="button" class="primary" onclick={runPreview} disabled={previewing}>
                                {previewing ? $t('plan.whatif.running') : $t('plan.whatif.run')}
                            </button>
                            {#if previewActive}
                                <button type="button" class="pp-wi-save" onclick={saveScenario} disabled={saving}>
                                    {saving ? $t('plan.whatif.saving') : $t('plan.whatif.save')}
                                </button>
                                <button type="button" class="pp-wi-reset" onclick={resetPreview}
                                    >{$t('plan.whatif.reset')}</button
                                >
                            {/if}
                        </div>
                        {#if previewActive}
                            <p class="pp-wi-banner">{$t('plan.whatif.banner')}</p>
                        {:else if previewError}
                            <p class="pp-wi-error">{$t('plan.whatif.error')}</p>
                        {/if}
                        {#if saveError}
                            <p class="pp-wi-error">{$t('plan.whatif.saveerror')}</p>
                        {/if}
                        <Calculator
                            outcome={viewComponents.cash_position.outcome}
                            view="verdict"
                            {cashOnHand}
                            components={viewComponents}
                            density="full"
                        />

                        <!-- Household financials (IC5): a persisted FACT — income + debts —
                             distinct from the what-if scenario above and the client-side
                             cash-on-hand. Commits via POST /profile → the engine recomputes
                             borrowing capacity → the full-horizon net position arrives over
                             the live SSE. Seeded from the engine SOT; full-replace on submit. -->
                        <section class="pp-fin">
                            <h4 class="pp-fin-title">{$t('plan.fin.title')}</h4>
                            <p class="pp-fin-intro">{$t('plan.fin.intro')}</p>
                            <div class="pp-fin-grid">
                                <label class="pp-ck-field pp-fin-wide">
                                    <span class="pp-ck-label">{$t('plan.fin.income')}</span>
                                    <input
                                        type="text"
                                        inputmode="numeric"
                                        bind:value={finIncome}
                                        placeholder={$t('plan.fin.placeholder')}
                                        disabled={finBusy}
                                    />
                                    <span class="pp-fin-hint">{$t('plan.fin.income_hint')}</span>
                                </label>
                                <label class="pp-ck-field">
                                    <span class="pp-ck-label">{$t('plan.fin.foreign')}</span>
                                    <input
                                        type="text"
                                        inputmode="numeric"
                                        bind:value={finForeign}
                                        placeholder={$t('plan.fin.placeholder0')}
                                        disabled={finBusy}
                                    />
                                </label>
                            </div>
                            <span class="pp-ck-label pp-fin-debts-label">{$t('plan.fin.debts_label')}</span>
                            <div class="pp-fin-grid">
                                <label class="pp-ck-field">
                                    <span class="pp-ck-label">{$t('plan.fin.hecs')}</span>
                                    <input type="text" inputmode="numeric" bind:value={finHecs}
                                        placeholder={$t('plan.fin.placeholder0')} disabled={finBusy} />
                                </label>
                                <label class="pp-ck-field">
                                    <span class="pp-ck-label">{$t('plan.fin.cards')}</span>
                                    <input type="text" inputmode="numeric" bind:value={finCards}
                                        placeholder={$t('plan.fin.placeholder0')} disabled={finBusy} />
                                </label>
                                <label class="pp-ck-field">
                                    <span class="pp-ck-label">{$t('plan.fin.personal')}</span>
                                    <input type="text" inputmode="numeric" bind:value={finPersonal}
                                        placeholder={$t('plan.fin.placeholder0')} disabled={finBusy} />
                                </label>
                                <label class="pp-ck-field">
                                    <span class="pp-ck-label">{$t('plan.fin.car')}</span>
                                    <input type="text" inputmode="numeric" bind:value={finCar}
                                        placeholder={$t('plan.fin.placeholder0')} disabled={finBusy} />
                                </label>
                                <label class="pp-ck-field">
                                    <span class="pp-ck-label">{$t('plan.fin.bnpl')}</span>
                                    <input type="text" inputmode="numeric" bind:value={finBnpl}
                                        placeholder={$t('plan.fin.placeholder0')} disabled={finBusy} />
                                </label>
                            </div>
                            <div class="pp-cockpit-actions">
                                <button type="button" class="primary" onclick={saveFinancials} disabled={finBusy}>
                                    {finSaving ? $t('plan.fin.saving') : $t('plan.fin.save')}
                                </button>
                            </div>
                            {#if finRecomputing}
                                <p class="pp-wi-banner">{$t('plan.fin.recomputing')}</p>
                            {:else if finError === 'busy'}
                                <p class="pp-wi-error">{$t('plan.fin.busy')}</p>
                            {:else if finError === 'invalid'}
                                <p class="pp-wi-error">{$t('plan.fin.error')} {finErrorDetail}</p>
                            {:else if finError === 'error'}
                                <p class="pp-wi-error">{$t('plan.fin.error')}</p>
                            {/if}
                            <p class="pp-fin-disclaimer">{$t('plan.fin.disclaimer')}</p>
                        </section>
                        {/if}
                    {:else}
                        <!-- Tabs 2/3: the cockpit is on tab 1, so signpost an active preview here. -->
                        {#if previewActive}
                            <div class="pp-whatif active">
                                <p class="pp-wi-banner">{$t('plan.whatif.banner')}</p>
                                <button type="button" class="pp-wi-reset" onclick={resetPreview}
                                    >{$t('plan.whatif.reset')}</button
                                >
                            </div>
                        {/if}
                        {#if budgetSub === 'table'}
                            <!-- Tab 2: the cash-events table. A self-owned row → the Detail tab. -->
                            <Calculator
                                outcome={viewComponents.cash_position.outcome}
                                view="table"
                                components={viewComponents}
                                onShowDetail={() => (budgetSub = 'detail')}
                                density="full"
                            />
                        {:else if budgetSub === 'horizon'}
                            <!-- Tab 4 (TW5): the disposition projection — the sell-side +
                                 full-horizon net position, a SEPARATE outcome via the same
                                 calculator renderer. Honest-partial: invitation until H set. -->
                            {#if viewComponents.disposition}
                                <Calculator
                                    outcome={viewComponents.disposition.outcome}
                                    view="disposition"
                                    components={viewComponents}
                                    density="full"
                                />
                            {:else}
                                <p class="pp-pending">{$t('plan.computing')}</p>
                            {/if}
                        {:else}
                            <!-- Tab 3: the breakdown detail, inline. -->
                            <Calculator
                                outcome={viewComponents.cash_position.outcome}
                                view="detail"
                                components={viewComponents}
                                density="full"
                            />
                            {#each budgetCards as cid (cid)}
                                <ComponentCard componentId={cid} entry={viewComponents[cid]} filling={running} />
                            {/each}
                        {/if}
                    {/if}
                {:else if running}
                    <p class="pp-computing"><span class="pp-spinner" aria-hidden="true"></span>{$t('plan.computing')}</p>
                {:else}
                    <p class="pp-pending">{$t('plan.computing')}</p>
                {/if}
            </section>
        {:else if activeTab}
            <!-- A lifecycle tab renders its mapped components in order. A component with no
                 entry once the base turn has finished is not part of the base plan (a
                 per-property component, or the not-yet-built base swimlane) → an honest
                 affordance, never a perpetual "computing". -->
            {#each activeTab.components as cid (cid)}
                {#if viewComponents[cid]}
                    <ComponentCard componentId={cid} entry={viewComponents[cid]} filling={running} />
                    <!-- settlement_prep B affordance: once a contract is signed, attest the two
                         dates to activate the dated critical path. Investor + selected-property
                         only; label tracks whether dates are already active. -->
                    {#if cid === 'settlement_prep' && supportsPhaseB && viewingProperty}
                        <div class="pp-settle-cta">
                            <button type="button" class="pp-attach-btn" onclick={openSettle}>
                                {settleStatus === 'active'
                                    ? $t('plan.settle.cta_update')
                                    : $t('plan.settle.cta_enter')}
                            </button>
                        </div>
                    {/if}
                    {#if cid === 'due_diligence' && supportsPhaseB && viewingProperty}
                        <div class="pp-settle-cta">
                            <button type="button" class="pp-attach-btn" onclick={openLease}>
                                {ddStatus === 'reviewed'
                                    ? $t('plan.lease.cta_update')
                                    : $t('plan.lease.cta_upload')}
                            </button>
                        </div>
                    {/if}
                {:else if turnDone && !turnFailed}
                    <section class="pp-card" data-component={cid}>
                        <h3 class="pp-card-title">
                            {$t(`plan.c.${cid}` as 'plan.c.buyer_profile')}
                        </h3>
                        <p class="pp-pending">{$t('plan.attach_property')}</p>
                    </section>
                {:else}
                    <ComponentCard componentId={cid} entry={undefined} filling={running} />
                {/if}
            {/each}
        {/if}
    </div>

    {#if turnFailed}
        <div class="pp-state">
            <p>{$t('plan.failed')}</p>
            <button type="button" onclick={load}>{$t('plan.retry')}</button>
        </div>
    {/if}
{/if}
