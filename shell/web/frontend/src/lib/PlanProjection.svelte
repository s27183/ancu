<script lang="ts">
    // The plan projection (8-S4c): the base plan as it surfaces on the map-home — the
    // sole plan UI (no separate dashboard; firsthomey-shell-direction). It finds the
    // user's plan card for THIS zone (title === suburb, the onboarding zone label),
    // seeds from the GET snapshot, then merges live component_filled frames over the
    // SSE proxy. The zone→suburb gradient (per-suburb overlay) is deferred — this shows
    // the property-agnostic BASE components, identical across suburbs.
    import { onMount } from 'svelte';
    import { t } from '$lib/i18n';
    import { getPlanCard, listPlanCards } from '$lib/api';
    import { subscribePlanCard, type PlanCardStream } from '$lib/planCardStream';
    import { BASE_COMPONENT_ORDER, type ComponentEntry, type UiTab } from '$lib/planCard';
    import ComponentCard from '$lib/renderers/ComponentCard.svelte';
    import OverviewCard from '$lib/renderers/OverviewCard.svelte';
    import Chat from '$lib/Chat.svelte';

    let { suburbName, onplan }: { suburbName: string; onplan: () => void } = $props();

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

    async function load() {
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
            <OverviewCard {components} filling={running} />
        {:else if activeTab}
            <!-- A lifecycle tab renders its mapped components in order. A component with no
                 entry once the base turn has finished is not part of the base plan (a
                 per-property component, or the not-yet-built base swimlane) → an honest
                 affordance, never a perpetual "computing". -->
            {#each activeTab.components as cid (cid)}
                {#if components[cid]}
                    <ComponentCard
                        componentId={cid}
                        entry={components[cid]}
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
