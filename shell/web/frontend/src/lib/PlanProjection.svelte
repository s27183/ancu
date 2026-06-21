<script lang="ts">
    // The plan projection (8-S4c): the base plan as it surfaces on the map-home — the
    // sole plan UI (no separate dashboard; firsthomey-shell-direction). It finds the
    // user's plan card for THIS zone (title === suburb, the onboarding zone label),
    // seeds from the GET snapshot, then merges live component_filled frames over the
    // SSE proxy. The zone→suburb gradient (per-suburb overlay) is deferred — this shows
    // the property-agnostic BASE components, identical across suburbs.
    import { onMount } from 'svelte';
    import { t } from '$lib/i18n';
    import { lang } from '$lib/stores/lang';
    import {
        getPlanCard,
        listPlanCards,
        simulatePlanCard,
        refinePlanCard,
        setChecklistStatus,
        type SimulateOverrides
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
        type BudgetEnvelopeOutcome,
        type ChecklistStatusMap
    } from '$lib/planCard';
    import { AU_STATES } from '$lib/map';
    import { money, moneyRange } from '$lib/format';
    import ComponentCard from '$lib/renderers/ComponentCard.svelte';
    import OverviewCard from '$lib/renderers/OverviewCard.svelte';
    import Calculator from '$lib/renderers/Calculator.svelte';
    import FlowView from '$lib/renderers/FlowView.svelte';
    import Tabs from '$lib/Tabs.svelte';
    import Chat from '$lib/Chat.svelte';

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

    // The budget (Cash-calculator) tab's three sub-tabs (§7.3): the cockpit inputs + the
    // "Bạn đã đủ chưa?" verdict → the cash-events table → the breakdown detail. Labels reuse
    // the existing calculator keys. A self-owned table row routes here to 'detail'.
    let budgetSub = $state<string>('ready');
    const budgetTabs = $derived([
        { id: 'ready', label: $t('plan.cash.ready') },
        { id: 'table', label: $t('plan.cash.spine') },
        { id: 'detail', label: $t('plan.cash.breakdown') }
    ]);

    let phase = $state<'loading' | 'ready' | 'no_card' | 'error'>('loading');
    let components = $state<Record<string, ComponentEntry>>({});
    let cardId = $state<string | null>(null);
    let turnDone = $state(false);
    let turnFailed = $state(false);
    // The card user-set layer (the Flow checklist done-toggles), seeded from the GET card
    // and overlaid onto phase_playbook actions at render. The engine is SOT: a toggle is
    // optimistic for immediacy, then reconciled from the PATCH response (revert on failure).
    let checklistStatus = $state<ChecklistStatusMap>({});

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

    // The components the tabs render: live outcomes, or — under an active preview — each
    // entry with its outcome swapped for the previewed one (renderer/scope/etc preserved,
    // merged by component_id). A component absent from the preview keeps its live outcome.
    const viewComponents = $derived.by((): Record<string, ComponentEntry> => {
        if (!previewOutcomes) return components;
        const pv = previewOutcomes;
        return Object.fromEntries(
            Object.entries(components).map(([cid, entry]) => [
                cid,
                pv[cid] ? { ...entry, outcome: pv[cid] } : entry
            ])
        );
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
    const flowCashEvents = $derived(
        (viewComponents.cash_position?.outcome as BudgetEnvelopeOutcome | undefined)
            ?.cash_events ?? []
    );

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
    const currentPriceLabel = $derived.by((): string | null => {
        const o = components.buyer_profile?.outcome as ProfileOutcome | undefined;
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
    }

    async function load() {
        resetPreview();
        const myGen = ++gen;
        stream?.close();
        stream = null;
        phase = 'loading';
        components = {};
        checklistStatus = {};
        uiTabs = [];
        cardId = null;
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

        const res = await getPlanCard(match.plan_card_id);
        if (myGen !== gen) return;
        if (res.kind === 'ok') {
            components = res.card.content.components ?? {};
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
            // Live fill from the cursor. Merge is idempotent (keyed by component_id).
            stream = subscribePlanCard(match.plan_card_id, {
                onComponentFilled: (entry) => {
                    if (myGen !== gen) return;
                    components = { ...components, [entry.component_id]: entry };
                },
                onDone: (failed) => {
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
                }
                // onError: EventSource auto-reconnects; stay calm (no banner).
            }, res.card.event_cursor);
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

    <!-- Sub-tabs: one per plan section + a Q&A tab — each section shows on its own, so
         the user never scrolls a long plan. Horizontally scrollable on narrow screens. -->
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

    <div class="pp-subcontent">
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
                        {:else}
                            <!-- Tab 3: the breakdown detail, inline. -->
                            <Calculator
                                outcome={viewComponents.cash_position.outcome}
                                view="detail"
                                components={viewComponents}
                                density="full"
                            />
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
                    <ComponentCard
                        componentId={cid}
                        entry={viewComponents[cid]}
                        filling={running}
                    />
                {:else if turnDone && !turnFailed}
                    <section class="pp-card">
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
