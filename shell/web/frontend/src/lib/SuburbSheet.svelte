<script lang="ts">
    // The suburb-click detail (8-S2): a bottom-sheet on phone, a side-panel on desktop
    // (one layout, adjusted — shell-architecture.md §7.1). Two tabs: zone-data (the raw
    // facts, rendered from the already-loaded list payload — no detail endpoint needed)
    // and a planning placeholder (the plan projection lands in 8-S4). Raw figures read
    // as calm reference, never a verdict (crime is map-display only, not a rating).
    import type { Suburb } from '$lib/api';
    import { t } from '$lib/i18n';
    import { lang } from '$lib/stores/lang';
    import PlanProjection from '$lib/PlanProjection.svelte';

    let { suburb, onclose, onplan, reloadPlan = 0 }: {
        suburb: Suburb;
        onclose: () => void;
        onplan: () => void;
        /** Bumped by the parent when a plan is created → remounts PlanProjection (via
         *  `{#key reloadPlan}`) so the Plan tab shows the new plan without a close/reopen.
         *  The user is already on the Plan tab here (the create CTA lives there). */
        reloadPlan?: number;
    } = $props();

    // Opens on the zone tab. The parent remounts this component per suburb
    // ({#key suburb.sal_code}), so `tab` resets naturally on a new selection —
    // no reset-in-$effect needed.
    type Tab = 'zone' | 'plan';
    let tab = $state<Tab>('zone');

    const nf = $derived(new Intl.NumberFormat($lang === 'vi' ? 'vi-VN' : 'en-AU'));
    const f = $derived(suburb.facts);

    function pct(n: number | undefined): string {
        return typeof n === 'number' ? `${nf.format(n)}%` : '';
    }
</script>

<div class="sheet" role="dialog" aria-modal="false" aria-label={suburb.name}>
    <header class="sheet-head">
        <div class="title">
            <h2>{suburb.name} - {suburb.state}</h2>
            {#if suburb.lga_name}
                <p class="sub">{suburb.lga_name}</p>
            {/if}
        </div>
        <button type="button" class="close" onclick={onclose} aria-label={$t('sheet.close')}
            >✕</button
        >
    </header>

    <div class="tabs" role="tablist">
        <button
            type="button"
            role="tab"
            aria-selected={tab === 'zone'}
            class:active={tab === 'zone'}
            onclick={() => (tab = 'zone')}>{$t('sheet.tab.zone')}</button
        >
        <button
            type="button"
            role="tab"
            aria-selected={tab === 'plan'}
            class:active={tab === 'plan'}
            onclick={() => (tab = 'plan')}>{$t('sheet.tab.plan')}</button
        >
    </div>

    <div class="body">
        {#if tab === 'zone'}
            <!-- Vietnamese community — the killer metric, surfaced first + emphasised. -->
            <div class="metric hero">
                <span class="label">{$t('sheet.viet')}</span>
                {#if typeof f.vietnamese_ancestry_pct === 'number'}
                    <span class="value">{pct(f.vietnamese_ancestry_pct)}</span>
                {:else}
                    <span class="value muted">{$t('sheet.nodata')}</span>
                {/if}
            </div>

            <div class="metric">
                <span class="label">{$t('sheet.seifa')}</span>
                {#if typeof f.seifa_irsad_decile === 'number'}
                    <span class="value">{f.seifa_irsad_decile}<span class="unit">/10</span></span>
                    <span class="note">{$t('sheet.seifa.note')}</span>
                {:else}
                    <span class="value muted">{$t('sheet.nodata')}</span>
                {/if}
            </div>

            <div class="metric">
                <span class="label">{$t('sheet.population')}</span>
                {#if typeof f.census_total_persons === 'number'}
                    <span class="value">{nf.format(f.census_total_persons)}</span>
                {:else}
                    <span class="value muted">{$t('sheet.nodata')}</span>
                {/if}
            </div>

            <div class="metric">
                <span class="label">{$t('sheet.crime')}</span>
                {#if typeof f.crime_incidents_per_1000 === 'number'}
                    <span class="value"
                        >{nf.format(f.crime_incidents_per_1000)}
                        <span class="unit">{$t('sheet.crime.unit')}</span></span
                    >
                    <span class="note"
                        >{$t('sheet.crime.note')}{#if f.crime_period} · {f.crime_period}{/if}</span
                    >
                {:else}
                    <span class="value muted">{$t('sheet.nodata')}</span>
                {/if}
            </div>
        {:else}
            <!-- The plan projection mounts lazily when this tab is shown; it finds the
                 user's card for THIS zone, or renders the create CTA itself (8-S4c).
                 Keyed by reloadPlan so a freshly-created plan reloads it in place. -->
            {#key reloadPlan}
                <PlanProjection suburbName={suburb.name} suburbState={suburb.state} {onplan} />
            {/key}
        {/if}
    </div>
</div>
