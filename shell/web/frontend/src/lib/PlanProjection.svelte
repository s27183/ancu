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
    import { getPlanCard, listPlanCards, simulatePlanCard, type SimulateOverrides } from '$lib/api';
    import { subscribePlanCard, type PlanCardStream } from '$lib/planCardStream';
    import {
        BASE_COMPONENT_ORDER,
        type ComponentEntry,
        type UiTab,
        type ProfileOutcome,
        type MoneyRange
    } from '$lib/planCard';
    import { AU_STATES } from '$lib/map';
    import { money, moneyRange } from '$lib/format';
    import ComponentCard from '$lib/renderers/ComponentCard.svelte';
    import OverviewCard from '$lib/renderers/OverviewCard.svelte';
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

    let phase = $state<'loading' | 'ready' | 'no_card' | 'error'>('loading');
    let components = $state<Record<string, ComponentEntry>>({});
    let cardId = $state<string | null>(null);
    let turnDone = $state(false);
    let turnFailed = $state(false);

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

    // The card's current target price (band or point), shown as the what-if baseline hint.
    const currentPriceLabel = $derived.by((): string | null => {
        const o = components.buyer_profile?.outcome as ProfileOutcome | undefined;
        const r = o?.target_price_range as MoneyRange | null | undefined;
        if (!Array.isArray(r) || r.length !== 2) return null;
        return r[0] === r[1] ? money(r[0], $lang) : moneyRange(r, $lang);
    });

    async function runPreview() {
        if (!cardId) return;
        const overrides: SimulateOverrides = {};
        const p = Number(priceInput.replace(/[^0-9.]/g, ''));
        if (priceInput.trim() !== '' && Number.isFinite(p) && p > 0) overrides.target_price = p;
        if (stateSelect && stateSelect !== suburbState) overrides.state = stateSelect;
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

    function resetPreview() {
        previewOutcomes = null;
        previewError = false;
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
        {#each uiTabs as tab (tab.tab_id)}
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

    <!-- Structural what-if bar (W9): a plan-level control — varying price/state re-renders
         EVERY tab, so it lives above the tabs, not inside a renderer. Hidden on Q&A (chat
         runs over the committed card, not a preview) and until the base plan has filled. -->
    {#if cardId && turnDone && !turnFailed && sub !== 'qa'}
        <div class="pp-whatif" class:active={previewActive}>
            <div class="pp-wi-controls">
                <label class="pp-wi-field">
                    <span class="pp-wi-label">{$t('plan.whatif.price')}</span>
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
                <label class="pp-wi-field">
                    <span class="pp-wi-label">{$t('plan.whatif.state')}</span>
                    <select bind:value={stateSelect}>
                        {#each AU_STATES as s (s)}
                            <option value={s}>{s}</option>
                        {/each}
                    </select>
                </label>
                <button type="button" class="primary" onclick={runPreview} disabled={previewing}>
                    {previewing ? $t('plan.whatif.running') : $t('plan.whatif.run')}
                </button>
                {#if previewActive}
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
                        interactive={activeTab.interactive ?? false}
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
