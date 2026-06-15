<script lang="ts">
    // One base component as a card: a titled section that dispatches to the renderer
    // the engine named (entry.renderer — the singular primitive, constraint #7). Until
    // the component is filled it shows a calm "computing" line if the turn is live, or
    // a quiet pending shell otherwise — never an empty box (§7.1).
    import { t } from '$lib/i18n';
    import type { ComponentEntry } from '$lib/planCard';
    import SummaryCard from './SummaryCard.svelte';
    import SchemeStackCard from './SchemeStackCard.svelte';
    import Calculator from './Calculator.svelte';
    import DataTable from './DataTable.svelte';

    let { componentId, entry, filling }: {
        componentId: string;
        entry: ComponentEntry | undefined;
        filling: boolean;
    } = $props();

    const title = $derived($t(`plan.c.${componentId}` as 'plan.c.buyer_profile'));
</script>

<section class="pp-card">
    <h3 class="pp-card-title">{title}</h3>
    {#if entry}
        {#if entry.renderer === 'summary-card'}
            <SummaryCard {componentId} outcome={entry.outcome} />
        {:else if entry.renderer === 'scheme-stack-card'}
            <SchemeStackCard outcome={entry.outcome} />
        {:else if entry.renderer === 'calculator'}
            <Calculator outcome={entry.outcome} />
        {:else if entry.renderer === 'data-table'}
            <DataTable outcome={entry.outcome} />
        {/if}
    {:else if filling}
        <p class="pp-computing"><span class="pp-spinner" aria-hidden="true"></span>{$t('plan.computing')}</p>
    {:else}
        <p class="pp-computing">{$t('plan.computing')}</p>
    {/if}
</section>
