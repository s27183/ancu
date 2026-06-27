<script lang="ts">
    // One base component as a card: a titled section that dispatches to the renderer(s)
    // the engine named (entry.renderers — the §11.9 vocabulary; a component may compose >1,
    // engine-contract §4). Until the component is filled it shows a calm "computing" line if
    // the turn is live, or a quiet pending shell otherwise — never an empty box (§7.1).
    import { t } from '$lib/i18n';
    import type { ComponentEntry } from '$lib/planCard';
    import SummaryCard from './SummaryCard.svelte';
    import SchemeStackCard from './SchemeStackCard.svelte';
    import Calculator from './Calculator.svelte';
    import DataTable from './DataTable.svelte';
    import SwimlaneDiagram from './SwimlaneDiagram.svelte';
    import Checklist from './Checklist.svelte';
    import BuyingStrategyCard from './BuyingStrategyCard.svelte';
    import OpportunityCard from './OpportunityCard.svelte';
    import RiskFlagList from './RiskFlagList.svelte';

    let { componentId, entry, filling, density = 'compact' }: {
        componentId: string;
        entry: ComponentEntry | undefined;
        filling: boolean;
        // 'compact' = the in-map projection; 'full' = the export dossier. One outcome
        // model, two surfaces (plan-card-visual-spec §1). Only the hero renderers read
        // it; the rest are density-agnostic for now.
        density?: 'compact' | 'full';
    } = $props();

    const title = $derived($t(`plan.c.${componentId}` as 'plan.c.buyer_profile'));

    // A component may compose >1 renderer (engine-contract §4): render each in order over the
    // same outcome. `renderers` is the artifact's ordered list; fall back to [renderer] for
    // pre-§4 snapshots so every single-renderer component is unchanged.
    const renderers = $derived(
        entry ? (entry.renderers?.length ? entry.renderers : [entry.renderer]) : []
    );
</script>

<section class="pp-card">
    <h3 class="pp-card-title">{title}</h3>
    {#if entry}
        {#each renderers as r (r)}
            {#if r === 'summary-card'}
                <SummaryCard {componentId} outcome={entry.outcome} />
            {:else if r === 'scheme-stack-card'}
                <SchemeStackCard outcome={entry.outcome} {density} />
            {:else if r === 'calculator'}
                <Calculator outcome={entry.outcome} {density} />
            {:else if r === 'data-table'}
                <DataTable outcome={entry.outcome} {density} />
            {:else if r === 'swimlane-diagram'}
                <SwimlaneDiagram outcome={entry.outcome} {density} />
            {:else if r === 'checklist'}
                <Checklist outcome={entry.outcome} />
            {:else if r === 'risk-flag-list'}
                <RiskFlagList outcome={entry.outcome} />
            {:else if r === 'buying-strategy-card'}
                <BuyingStrategyCard outcome={entry.outcome} />
            {:else if r === 'opportunity-card'}
                <OpportunityCard outcome={entry.outcome} />
            {/if}
        {/each}
    {:else if filling}
        <p class="pp-computing"><span class="pp-spinner" aria-hidden="true"></span>{$t('plan.computing')}</p>
    {:else}
        <p class="pp-computing">{$t('plan.computing')}</p>
    {/if}
</section>
