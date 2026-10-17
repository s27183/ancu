<script lang="ts">
    // The plan projection (8-S4c): the base plan as it surfaces on the map-home — the
    // sole plan UI (no separate dashboard; firsthomey-shell-direction). It finds the
    // user's plan card for THIS zone (title === suburb, the onboarding zone label),
    // seeds from the GET snapshot, then merges live component_filled frames over the
    // SSE proxy. The zone→suburb gradient (per-suburb overlay) is deferred — this shows
    // the property-agnostic BASE components, identical across suburbs.
    import { onMount } from 'svelte';
    import { page } from '$app/state';
    import { pushState } from '$app/navigation';
    import { t } from '$lib/i18n';
    import Termed from '$lib/Termed.svelte';
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
    import { describeFailure, type FailureView } from '$lib/turnFailure';
    import {
        BASE_COMPONENT_ORDER,
        type ComponentEntry,
        type UiTab,
        type ProfileOutcome,
        type BudgetEnvelopeOutcome,
        type DepositBounds,
        type MoneyRange,
        type JourneySwimlaneOutcome,
        type PhasePlaybookOutcome,
        type DispositionOutcome,
        type ChecklistStatusMap,
        type PropertyAddendum,
        harvestCashEvents,
        firstComponentEntry,
        loanFit,
        PROFILE_COMPONENT_IDS
    } from '$lib/planCard';
    import { AU_STATES } from '$lib/map';
    import { money, moneyRange } from '$lib/format';
    import ComponentCard from '$lib/renderers/ComponentCard.svelte';
    import OverviewCard from '$lib/renderers/OverviewCard.svelte';
    import FlowView from '$lib/renderers/FlowView.svelte';
    import LifecycleSheet from '$lib/LifecycleSheet.svelte';
    import PlanHub from '$lib/PlanHub.svelte';
    import Tabs from '$lib/Tabs.svelte';
    import Chat from '$lib/Chat.svelte';
    import QaIntro from '$lib/QaIntro.svelte';
    import { useSections, type SectionGroup, type SectionIcon, type SectionItem } from '$lib/sections.svelte';
    import { guest } from '$lib/stores/session';
    import { loginOpen } from '$lib/stores/ui';
    import Modal from '$lib/Modal.svelte';

    let { suburbName, suburbState, onplan, cardId: openId }: {
        suburbName: string;
        /** '' on the planner page (behavior 81): the card's own state is used then. */
        suburbState: string;
        onplan: () => void;
        /** The planner page opens this card by id; the suburb sheet matches by title. */
        cardId?: string;
    } = $props();
    // The state the plan is read under: the suburb's on the map, else the one the engine
    // resolved for the card (GET card `state`, behavior 81).
    let cardState = $state('');
    const planBase = $derived(suburbState || cardState);

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

    // Behavior 95: the budget is one sheet chain (the statement → phase sheets → line
    // details, LifecycleSheet); the cockpit, table, breakdown and full-horizon sub-tabs are gone.
    // A statement line's detail opens Hành trình at a step that links it (openStep).

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
    // The turn_failed payload mapped to what the user sees (turnFailure.ts); null = no failure.
    let failure = $state<FailureView | null>(null);
    const turnFailed = $derived(failure !== null);
    // The card user-set layer (the Flow checklist done-toggles), seeded from the GET card
    // and overlaid onto phase_playbook actions at render. The engine is SOT: a toggle is
    // optimistic for immediacy, then reconciled from the PATCH response (revert on failure).
    let checklistStatus = $state<ChecklistStatusMap>({});

    // Behavior 55: the head's "Hỏi AI" (the plan's one way to the assistant since behavior
    // 93 took the foot bar off) opens it; the page scrolls its body to the top.
    async function openQa() {
        await leaveLayer();
        enter('qa');
    }

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
    // behavior 101: the deposit the visitor chooses on "Tài chính của bạn" ('' = the plan's
    // own), and the range the engine refused it against (its 400 names min and max).
    let depositInput = $state('');
    let depositRefused = $state<{ min: number; max: number } | null>(null);
    // An AUD amount as typed — 700000, 700.000 or 700,000 are all the same whole dollars.
    function aud(s: string): number | null {
        const d = s.replace(/[^0-9]/g, '');
        return s.trim() !== '' && d !== '' ? Number(d) : null;
    }
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
    // The statement's hold-years chips drive the same horizon what-if as the cockpit's
    // slider. (A line opens its own detail in place, behavior 93 — no component card.)
    function chooseHold(years: number) {
        horizonValue = years;
        void runPreview();
    }
    // Behavior 93: the statement opens with a hold picked, so its bottom line shows at
    // once — a plan saved with no hold previews DEFAULT_HOLD years, as a tap on that chip
    // would. Once per load (`holdDefaulted`; a reset re-arms it); the cockpit's slider can
    // still clear it. The hold is shown on the statement's chips; no banner: since behavior
    // 109 the chips' hold is the only preview, and the finances sheet saves (updateFinances).
    const DEFAULT_HOLD = 10;
    let holdDefaulted = false;
    $effect(() => {
        // Behavior 92: as soon as the budget is there, not after the turn — the slow AI
        // pass does not move the statement's figures (measured 2026-10-16), and the engine
        // simulates a hold while the turn still runs, so the plan lands complete.
        if (holdDefaulted || !cardId || viewingProperty) return;
        if (!components.cash_position || baselineHorizon !== 0 || horizonValue !== 0) return;
        holdDefaulted = true;
        chooseHold(DEFAULT_HOLD);
    });
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

    // Cash-on-hand is the Mua sheet's "Tiền bạn có" row (LifecycleSheet, behavior 95).

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
        finSeeded = JSON.stringify(buildFinancials());
    }
    // behavior 109: the financials as last seeded, so "Cập nhật tài chính" writes them only
    // when the visitor changed one.
    let finSeeded = '';

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
        apState = planBase;
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

    // Whole lifecycle -> bilingual; information as is -> the web frontend -> the planner's two places
    // Goal:      behavior 95 — the plan's section menu (behavior 68, sections.svelte.ts) holds
    //            two fixed entries, "Ngân sách" (the statement chain) and "Hành trình" (the
    //            lifecycle checklist), no sub-items; the assistant is the head's "Hỏi AI"
    //            (sectionReg.ask), never a menu entry.
    // Invariant: the engine's ui_tabs stay its declaration (invariants.md: a shell may ignore
    //            them); the two entries are its interactive tab (cash_position) and its flow
    //            tab — "Tổng quan", "Danh mục" and "Gia đình" are not offered. A card with
    //            neither (an engine before ui_tabs) lists its tabs as before, so a version
    //            skew never blanks the menu.
    // Capability: picking Ngân sách from any sheet returns to the statement (leaveLayer pops
    //            an open phase sheet or step); picking Hành trình opens the swimlane.
    const sectionReg = useSections();
    const budgetTab = $derived(uiTabs.find((tb) => tb.interactive));
    const flowTab = $derived(uiTabs.find((tb) => tb.kind === 'flow'));

    // Whole lifecycle -> bilingual; information as is -> the web frontend -> the plan's levels
    // Goal:      behavior 106 (Son 2026-10-17, his friend could not find her way back to the
    //            overview): a plan opens on its hub (PlanHub: a Ngân sách card with the total
    //            over the hold, a Hành trình card with steps done of all and the next one);
    //            a card opens that sheet. Every level is one history entry — the hub is the
    //            plan's own (page.state.overList); Ngân sách, Hành trình and the assistant
    //            push `planView`; a phase sheet `lifecycle` (LifecycleSheet); a step of
    //            Hành trình `flowPhase` (FlowView). The plan head's one back button
    //            (routes/plan/+page.svelte) names the level above and is history.back(), so
    //            it, the browser's back and a swipe cannot disagree — the button is the way
    //            back (Son: the iPhone swipe is hard to use, never relied on).
    // Invariant: the hub computes nothing — its total is lifecycle_budget.costs_total (the
    //            statement's bottom line) and its count the playbook's actions under the
    //            card's checklist_status (every blueprint carries a playbook: 30–35 steps,
    //            measured 2026-10-17). A card with neither tab has no hub (version skew).
    // Capability: the floating menu switches Ngân sách ↔ Hành trình in place (sub), so back
    //            from either goes to the hub; it is drawn on those two sheets only — not on
    //            the hub, whose cards are the way in, nor on a level below them (a phase
    //            sheet, "Tài chính của bạn", a step: page.state.lifecycle / flowPhase;
    //            behavior 109), where the sheet's own back or submit is the way on.

    // A pick from the menu, or "Hỏi AI", leaves an open phase sheet or step first, and
    // waits for that back to land so a push that follows lands over the sheet, not under it.
    function leaveLayer(): Promise<void> {
        if (!page.state.lifecycle && !page.state.flowPhase) return Promise.resolve();
        return new Promise((done) => {
            addEventListener('popstate', () => setTimeout(done, 0), { once: true });
            history.back();
        });
    }
    // Behavior 106: the hub, or a view over it. A card with neither the budget nor the
    // flow tab (an engine before ui_tabs) has no hub: its tabs show as before.
    const hasHub = $derived(!!(budgetTab || flowTab));
    const onHub = $derived(hasHub && !page.state.planView);
    function enter(tab: string) {
        if (hasHub && !page.state.planView) pushState('', { ...page.state, planView: true });
        sub = tab;
    }
    // A line's detail names a step: Hành trình at that step, one level under the sheet.
    async function openStep(st: { phase: string; id: string }) {
        await leaveLayer();
        if (flowTab) sub = flowTab.tab_id;
        pushState('', { ...page.state, flowPhase: st.phase, flowAction: st.id });
    }
    const sectionGroups = $derived.by<SectionGroup[]>(() => {
        if (railTabs.length === 0) return [];
        const entry = (tb: UiTab, icon: SectionIcon): SectionItem => ({
            id: tb.tab_id,
            label: $t(`plan.ltab.${tb.tab_id}` as 'plan.ltab.overview'),
            icon,
            active: sub === tb.tab_id,
            select: async () => {
                await leaveLayer();
                sub = tb.tab_id;
            }
        });
        const items: SectionItem[] =
            budgetTab || flowTab
                ? [
                      ...(budgetTab ? [entry(budgetTab, 'budget')] : []),
                      ...(flowTab ? [entry(flowTab, 'flow')] : [])
                  ]
                : railTabs.map((tb) => entry(tb, 'overview'));
        return [{ id: 'plan', label: $t('sheet.tab.plan'), items }];
    });
    const sectionCurrent = $derived.by(() => {
        if (sub === 'qa') return $t('plan.tab.qa_short');
        if (!activeTab) return '';
        return $t(`plan.ltab.${activeTab.tab_id}` as 'plan.ltab.overview');
    });
    $effect(() => {
        if (!sectionReg) return;
        // behavior 106: the hub's cards are the way in; the menu is for the sheets under it
        // behavior 109: and only on Ngân sách and Hành trình themselves — a phase sheet,
        // "Tài chính của bạn" (whose submit takes the menu's place) or a step hides it
        const deeper = !!(page.state.lifecycle || page.state.flowPhase);
        sectionReg.plan = onHub || deeper ? [] : sectionGroups;
        sectionReg.current = onHub ? '' : sectionCurrent;
        // The sheet head's "Hỏi AI" (behavior 75): offered where the ask bar is.
        sectionReg.ask = (onHub || sub !== 'qa') && uiTabs.length > 0 ? openQa : null;
    });
    $effect(() => {
        const reg = sectionReg;
        return () => {
            if (reg) {
                reg.plan = [];
                reg.current = '';
                reg.ask = null;
            }
        };
    });

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
    const currentPriceIsPoint = $derived.by((): boolean => {
        const o = firstComponentEntry(components, PROFILE_COMPONENT_IDS)?.outcome as
            | ProfileOutcome
            | undefined;
        const r = o?.target_price_range as MoneyRange | null | undefined;
        return Array.isArray(r) && r.length === 2 && r[0] === r[1];
    });

    // behavior 101: the deposit range of the plan on screen (a preview's, once previewed).
    const depositBounds = $derived(
        ((viewComponents.cash_position?.outcome as BudgetEnvelopeOutcome | undefined)
            ?.deposit_bounds ?? null) as DepositBounds | null
    );
    const fit = $derived(loanFit(viewComponents));
    const pricePreview = $derived(aud(priceInput));
    function outright() {
        const p = aud(priceInput) ?? depositBounds?.price ?? null;
        if (p !== null) depositInput = String(p);
    }

    // The overrides the current inputs describe — shared by preview and save so the saved
    // scenario is exactly the one on screen. Only a CHANGED state is an override (the
    // suburb's own state is the baseline); a non-positive / blank price is omitted.
    // behavior 109: the hold chips preview the hold alone (withInputs false); the price and
    // deposit typed on "Tài chính của bạn" are only ever saved, by updateFinances.
    function buildOverrides(withInputs = true): SimulateOverrides {
        const overrides: SimulateOverrides = {};
        const p = withInputs ? aud(priceInput) : null;
        if (p !== null && p > 0) overrides.target_price = p;
        const d = withInputs ? aud(depositInput) : null;
        if (d !== null) overrides.deposit = d;
        // horizon: only a positive H that differs from the card's baseline (omit 0 — the
        // engine has no "clear horizon" override; absence IS the indefinite default).
        if (horizonValue >= 1 && horizonValue !== baselineHorizon) overrides.horizon = horizonValue;
        return overrides;
    }

    async function runPreview() {
        if (!cardId) return;
        const overrides = buildOverrides(false);
        // Nothing varied → clear any prior preview rather than round-trip a no-op.
        if (Object.keys(overrides).length === 0) {
            previewOutcomes = null;
            previewError = false;
            return;
        }
        previewing = true;
        previewError = false;
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
    async function saveScenario(): Promise<boolean> {
        if (!cardId) return false;
        const overrides = buildOverrides();
        if (Object.keys(overrides).length === 0) return true;
        saving = true;
        saveError = false;
        depositRefused = null;
        const res = await refinePlanCard(cardId, overrides);
        saving = false;
        if (res.kind === 'accepted') {
            turnDone = false;
            committing = true;
            return true;
        } else if (res.kind === 'invalid' && res.min !== undefined && res.max !== undefined) {
            depositRefused = { min: res.min, max: res.max };
        } else {
            saveError = true;
        }
        return false;
    }

    // Whole lifecycle -> P-2 · The database is the single source of truth -> The web frontend -> one submit for "Tài chính của bạn"
    // Goal:      behavior 109 (Son 2026-10-17: "I update the finance, then the whole plan
    //            update accordingly"): "Cập nhật tài chính", pinned at the foot of the
    //            finances sheet (LifecycleSheet's .ls-fin-submit), is its one submit; it
    //            saves what changed and goes back to Ngân sách. No unsaved preview, no
    //            "Xem thử" / "Lưu" / "Đặt lại" — the plan shown is the saved plan.
    // Invariant: a field left alone keeps the plan's value: a blank price or deposit sends no
    //            override, and the household form is seeded from the engine's profile, its
    //            write sent only when it differs from that seed (finSeeded). The two writes
    //            never overlap (refine 409s while a turn runs; a profile write mid-turn
    //            recomputes nothing), so when both changed the profile write waits for the
    //            refine's turn to end (onDone, profileAfterRefine). Measured 2026-10-17 in
    //            Chrome: price + HECS in one tap both landed (loan needed 712.500, HECS 0).
    // Capability: a refused write keeps the visitor on the sheet with its message;
    //            "Tiền bạn có" is kept as typed; Enter in price or deposit submits too.
    let profileAfterRefine = $state(false);
    const updating = $derived(saving || finSaving);
    async function updateFinances() {
        if (!cardId || finBusy || saving) return;
        const refine = aud(priceInput) !== null || aud(depositInput) !== null;
        const profile = JSON.stringify(buildFinancials()) !== finSeeded;
        if (refine) {
            if (!(await saveScenario())) return;
            profileAfterRefine = profile;
        } else if (profile) {
            await saveFinancials();
            if (finError) return;
        }
        if (page.state.lifecycle === 'finances') history.back();
    }

    function resetPreview() {
        previewOutcomes = null;
        previewError = false;
        saveError = false;
        priceInput = '';
        depositInput = '';
        depositRefused = null;
        horizonValue = baselineHorizon;
        holdDefaulted = false;
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
        cardState = '';
        blueprintSlug = '';
        turnDone = false;
        failure = null;

        // Signed-out or no cards → listPlanCards() returns []; no zone match → the CTA.
        const cards = await listPlanCards();
        if (myGen !== gen) return;
        const match =
            (openId
                ? cards.find((c) => c.plan_card_id === openId)
                : cards.find((c) => c.title === suburbName)) ?? null;
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
                    if (failed) failure = describeFailure(failed);
                    turnDone = true;
                    // A just-committed save (W8): the recomputed components are now merged
                    // live (== what was previewed), so drop the preview overlay and reset
                    // the inputs — the hand-off is invisible thanks to commit==preview parity.
                    if (committing) {
                        committing = false;
                        resetPreview();
                        // behavior 109: the income or debts changed with the price — now
                        // that the refine's turn is over, write them too.
                        if (profileAfterRefine && !failed) {
                            profileAfterRefine = false;
                            void saveFinancials();
                        }
                    } else if (previewOutcomes && !failed) {
                        // A preview made while the turn ran (the default hold, behavior 92)
                        // overlays every component: re-run it so the detail sheets carry
                        // the turn's finished notes. Same figures; nothing flickers.
                        void runPreview();
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
            if (!uiTabs.some((t) => t.tab_id === sub))
                sub = (uiTabs.find((t) => t.interactive) ?? uiTabs[0])?.tab_id ?? '';
            cardId = match.plan_card_id;
            cardState = res.card.state ?? '';
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
        <button type="button" class="primary" data-tour="plan-cta" onclick={onplan}
            >{$t('onboarding.cta')}</button
        >
    </div>
{:else if phase === 'error'}
    <div class="pp-state">
        <p>{$t('plan.error')}</p>
        <button type="button" onclick={load}>{$t('plan.retry')}</button>
    </div>
{:else}
    <!-- Behavior 92: once the budget is there the plan reads as finished — the AI's notes
         fill the detail sheets quietly, each card showing its own filling state. -->
    {#if running && !components.cash_position}
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


<!-- Behavior 101: the price and the deposit, first on "Tài chính của bạn"; behavior 109:
     saved with everything else by the sheet's one "Cập nhật tài chính" (updateFinances). -->
{#snippet scenario()}
    <div class="pp-price">
        <label class="pp-price-row">
            <span class="pp-price-label">{$t('plan.sheet.price')}</span>
            <input
                id="fin-price"
                type="text"
                inputmode="numeric"
                bind:value={priceInput}
                placeholder={currentPriceLabel ?? $t('plan.cash.whatif.placeholder')}
                onkeydown={(e) => e.key === 'Enter' && updateFinances()}
            />
        </label>
        {#if pricePreview}<p class="pp-fin-shown">{$t('plan.fin.shown').replace('{x}', money(pricePreview, $lang) ?? '')}</p>{/if}
        {#if currentPriceLabel}<p class="pp-fin-hint">{$t(currentPriceIsPoint ? 'plan.fin.price_hint_point' : 'plan.fin.price_hint').replace('{r}', currentPriceLabel)}</p>{/if}
        <p class="pp-fin-effect"><Termed text={$t('plan.fin.price_effect')} /></p>
    </div>
    {#if depositBounds}
        {@const b = depositBounds}
        <div class="pp-price">
            <label class="pp-price-row">
                <span class="pp-price-label">{$t('plan.fin.deposit')}</span>
                <input
                    id="fin-deposit"
                    type="text"
                    inputmode="numeric"
                    bind:value={depositInput}
                    placeholder={money(b.chosen ?? b.assumed ?? b.min, $lang) ?? ''}
                    onkeydown={(e) => e.key === 'Enter' && updateFinances()}
                />
                <button type="button" class="pp-fin-outright" onclick={outright}>{$t('plan.fin.outright')}</button>
            </label>
            {#if aud(depositInput) !== null}<p class="pp-fin-shown">{$t('plan.fin.shown').replace('{x}', money(aud(depositInput) ?? 0, $lang) ?? '')}</p>{/if}
            <p class="pp-fin-hint">
                {$t('plan.fin.deposit_hint')
                    .replace('{x}', money(b.chosen ?? b.assumed ?? b.min, $lang) ?? '—')
                    .replace('{min}', money(b.min, $lang) ?? '—')
                    .replace('{p}', String(b.min_pct))}
            </p>
            {#if depositRefused}
                <p class="pp-wi-error" role="alert">
                    {$t('plan.fin.deposit_out')
                        .replace('{min}', money(depositRefused.min, $lang) ?? '—')
                        .replace('{max}', money(depositRefused.max, $lang) ?? '—')}
                </p>
            {/if}
            <p class="pp-fin-effect"><Termed text={$t('plan.fin.deposit_effect')} /></p>
        </div>
    {/if}
    {#if saveError}
        <p class="pp-wi-error">{$t('plan.whatif.saveerror')}</p>
    {/if}
{/snippet}

<!-- The household figures behind the loan (IC5), closed under the Mua sheet's
     "Tiền bạn có" (behavior 95: the cockpit's other half). -->
{#snippet household()}
    <div class="pp-fin-wrap">
        <h4 class="pp-fin-title">{$t('plan.sheet.finances')}</h4>
        <p class="pp-fin-effect"><Termed text={$t('plan.fin.household_effect')} /></p>
        <p class="pp-fin-capacity" data-capacity>
            {#if fit.capacity}{$t('plan.fin.capacity').replace('{x}', (moneyRange(fit.capacity, $lang) ?? ''))}{:else}{$t('plan.fin.capacity_none')}{/if}
            {#if fit.loan}{$t('plan.fin.loan_needed').replace('{x}', money(fit.loan, $lang) ?? '')}{/if}
        </p>
        <!-- Household financials (IC5): a persisted FACT — income + debts —
             distinct from the what-if scenario above and the client-side
             cash-on-hand. Commits via POST /profile → the engine recomputes
             borrowing capacity → the full-horizon net position arrives over
             the live SSE. Seeded from the engine SOT; full-replace on submit. -->
        <section class="pp-fin">
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
    </div>
{/snippet}

<!-- Behavior 109: the finances sheet's one submit, pinned at its foot (LifecycleSheet). -->
{#snippet finSubmit()}
    <button type="button" class="primary" data-fin-update onclick={updateFinances} disabled={finBusy || updating}>
        {updating ? $t('plan.fin.saving') : $t('plan.fin.save')}
    </button>
{/snippet}

    {#snippet settleCta()}
        <div class="pp-settle-cta">
            <button type="button" class="pp-attach-btn" onclick={openSettle}>
                {settleStatus === 'active'
                    ? $t('plan.settle.cta_update')
                    : $t('plan.settle.cta_enter')}
            </button>
        </div>
    {/snippet}

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


    <div class="pp-subcontent">
        {#if onHub}
            <PlanHub
                components={viewComponents}
                {checklistStatus}
                filling={running}
                hasBudget={!!budgetTab}
                hasFlow={!!flowTab}
                onbudget={() => budgetTab && enter(budgetTab.tab_id)}
                onflow={() => flowTab && enter(flowTab.tab_id)}
            />
        {:else if sub === 'qa'}
            <!-- Chat runs over the FILLED card; the engine 409s a qa turn while the base
                 turn is still running, so gate it on the base turn having finished. -->
            {#if $guest}
                <QaIntro onpick={() => loginOpen.set(true)} />
                <div class="pp-guest" role="note">
                    <p>{$t('guest.notice')}</p>
                    <button type="button" class="primary" onclick={() => loginOpen.set(true)}
                        >{$t('auth.signin')}</button
                    >
                </div>
            {:else if cardId && turnDone && !turnFailed}
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
            <!-- Whole lifecycle -> P-4 · The engine is coupled to no shell -> The web
                 frontend -> settlement_prep under the swimlane (behavior 25, #35)
                 Every blueprint lists settlement_prep in the flow tab (docs/blueprints/*.md
                 ui_tabs) and FlowView draws only journey + playbook, so the per-property card
                 and its date CTA render here, with the components branch's guard. Measured
                 2026-10-07: Box Hill attach → settlement_prep filled (event 8411), and before
                 this nothing showed it. -->
            {#if supportsPhaseB && viewingProperty && viewComponents.settlement_prep}
                <ComponentCard
                    componentId="settlement_prep"
                    entry={viewComponents.settlement_prep}
                    filling={running}
                />
                {@render settleCta()}
            {/if}
        {:else if activeTab?.interactive}
            <!-- The Cash-calculator tab: the financial spine + the cockpit that drives it
                 (the prototype's interactive calculator, engine-driven). price/state →
                 simulate (re-renders every tab); cash-on-hand → client-side verdict only;
                 property type is per-property (Phase B) so it's shown locked, not faked.
                 The interactive tab is [cash_position]; any other component falls through. -->
            <section class="pp-card pp-calc pp-flat">
                {#if viewComponents.cash_position}
                    <LifecycleSheet
                        components={viewComponents}
                        filling={running}
                        horizon={horizonValue}
                        planState={planBase}
                        busy={previewing}
                        onhorizon={chooseHold}
                        planId={cardId}
                        scenario={viewingProperty ? undefined : scenario}
                        household={viewingProperty ? undefined : household}
                        submit={viewingProperty ? undefined : finSubmit}
                        onstep={openStep}
                    />
                {:else if running}
                    <p class="pp-computing"><span class="pp-spinner" aria-hidden="true"></span>{$t('plan.computing')}</p>
                {:else}
                    <!-- Behavior 94: the turn has ended (or crashed) without a budget — say
                         so, never "Đang tính…"; "Thử lại" makes the plan again for its state
                         (a failed card does not recompute by itself). -->
                    <div class="pp-state" data-testid="plan-unfinished">
                        <p>{$t(failure?.key ?? 'plan.failed')}</p>
                        {#if !failure || failure.retry}<button type="button" onclick={onplan}
                                >{$t('plan.retry')}</button
                            >{/if}
                    </div>
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
                        {@render settleCta()}
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

    {#if failure && !(activeTab?.interactive && !viewComponents.cash_position)}
        <div class="pp-state">
            <p>{$t(failure.key)}</p>
            {#if failure.retry}<button type="button" onclick={load}>{$t('plan.retry')}</button>{/if}
        </div>
    {/if}
    <!-- Behavior 45: a guest's plan says what it is — kept 7 days, sign in to keep it;
         one line since behavior 93 (the full notice stays on the assistant's tab). Since
         behavior 95 it sits at the foot, over the disclaimer, so nothing but the head is
         above the plan's first sheet. -->
    {#if $guest && (onHub || sub !== 'qa')}
        <p class="pp-guest pp-guest-line" role="note">
            {$t('guest.notice_short')} ·
            <button type="button" class="pp-guest-signin" onclick={() => loginOpen.set(true)}
                >{$t('auth.signin')}</button
            >
        </p>
    {/if}

    <!-- Behavior 20: every plan carries the ASIC decision-support line; a foreign-buyer
         plan (Mode B fhb-foreign-au, Mode D investor-foreign-au) also the FIRB line.
         Behavior 93: shown as one line, "Xem thêm" opening the full text — shortened,
         never removed (the goal: information as is, not advice). -->
    <footer class="pp-disclaimers">
        <details class="pp-disclaimer-more">
            <summary>{$t('disclaimer.short')} <span class="pp-more">{$t('disclaimer.more')}</span></summary>
            <p>{$t('disclaimer.asic')}</p>
            {#if blueprintSlug.includes('-foreign-')}<p>{$t('disclaimer.firb')}</p>{/if}
        </details>
    </footer>
{/if}
