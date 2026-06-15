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
    import { BASE_COMPONENT_ORDER, type ComponentEntry } from '$lib/planCard';
    import ComponentCard from '$lib/renderers/ComponentCard.svelte';
    import Chat from '$lib/Chat.svelte';

    let { suburbName, onplan }: { suburbName: string; onplan: () => void } = $props();

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
            cardId = match.plan_card_id;
            phase = 'ready';
            // Live fill. Replay reconstructs state if the turn already ended; the merge
            // is idempotent (keyed by component_id), so duplicates are harmless.
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
            });
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
    <div class="pp-projection">
        {#each BASE_COMPONENT_ORDER as cid (cid)}
            <ComponentCard componentId={cid} entry={components[cid]} filling={running} />
        {/each}
    </div>
    {#if turnFailed}
        <div class="pp-state">
            <p>{$t('plan.failed')}</p>
            <button type="button" onclick={load}>{$t('plan.retry')}</button>
        </div>
    {/if}
    <!-- Chat asks questions over the FILLED card; the engine 409s a qa turn while the
         base turn is still running, so gate it on the base turn having finished. -->
    {#if cardId && turnDone && !turnFailed}
        <Chat planCardId={cardId} />
    {/if}
{/if}
