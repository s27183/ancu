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
    import { tourEvent } from '$lib/tour';
    import SectionMenu from '$lib/SectionMenu.svelte';
    import { provideSections, type SectionGroup } from '$lib/sections.svelte';
    import { sheetMotion, scrimMotion } from '$lib/sheetMotion';

    let { suburb, onclose, onplan, reloadPlan = 0 }: {
        suburb: Suburb;
        onclose: () => void;
        onplan: () => void;
        /** Bumped by the parent when a plan is created → remounts PlanProjection (via
         *  `{#key reloadPlan}`) so the Plan tab shows the new plan without a close/reopen.
         *  A bump also switches to the Plan tab: after a sign-in restore (behavior 18) the
         *  sheet reopens on Zone, not on the Plan tab where the create CTA was. */
        reloadPlan?: number;
    } = $props();

    // Opens on the zone tab. The parent remounts this component per suburb
    // ({#key suburb.sal_code}), so `tab` resets naturally on a new selection —
    // no reset-in-$effect needed.
    type Tab = 'zone' | 'plan';
    let tab = $state<Tab>('zone');

    // Why not open the restored sheet on Plan: measured 2026-10-07 (Chrome, dev stack,
    // twice): opened on Plan over an existing plan, the new plan stayed "Computing…" — its
    // /events got no headers while the engine had the turn completed, and the shell hung
    // up ~60 s later; opened on Zone it filled. Concluded cause: the old projection's
    // stream (nothing to replay) is cancelled by the remount before its first byte, and
    // that wedges the shell's stream relay. Switching only once the plan exists avoids it.
    // svelte-ignore state_referenced_locally
    let seenReload = reloadPlan;
    $effect(() => {
        if (reloadPlan !== seenReload) {
            seenReload = reloadPlan;
            tab = 'plan';
        }
    });

    // The phone's floating section menu (behavior 68): Khu vực, then the plan's own
    // groups once the plan is shown (PlanProjection publishes them), or one "Kế hoạch"
    // entry while the zone tab is up.
    const sections = provideSections();
    const menuGroups = $derived<SectionGroup[]>([
        {
            id: 'zone',
            items: [
                {
                    id: 'zone',
                    label: $t('sheet.tab.zone'),
                    icon: 'zone',
                    active: tab === 'zone',
                    select: () => (tab = 'zone')
                }
            ]
        },
        ...(tab === 'plan' && sections.plan.length > 0
            ? sections.plan
            : [
                  {
                      id: 'plan',
                      items: [
                          {
                              id: 'plan',
                              label: $t('sheet.tab.plan'),
                              icon: 'overview' as const,
                              active: tab === 'plan',
                              select: () => (tab = 'plan')
                          }
                      ]
                  }
              ])
    ]);
    const menuCurrent = $derived(
        tab === 'zone'
            ? $t('sheet.tab.zone')
            : sections.current
              ? `${$t('sheet.tab.plan')} · ${sections.current}`
              : $t('sheet.tab.plan')
    );
    let bodyEl: HTMLDivElement | undefined = $state();
    // A section picked from the menu starts at its top, as a tab tap shows it.
    function toTop() {
        bodyEl?.scrollTo({ top: 0 });
    }

    // The tour (behavior 52) follows which tab is shown.
    $effect(() => {
        tourEvent(tab === 'plan' ? 'plan-tab' : 'zone-tab');
    });

    const nf = $derived(new Intl.NumberFormat($lang === 'vi' ? 'vi-VN' : 'en-AU'));
    const f = $derived(suburb.facts);

    function pct(n: number | undefined): string {
        return typeof n === 'number' ? `${nf.format(n)}%` : '';
    }
</script>

<!-- The veil behind the sheet (behavior 71): dims the map as "Vì sao Úc?" dims the page;
     a tap on it closes the sheet. Not in the tab order — the ✕ and Esc are the keyboard way. -->
<button
    type="button"
    class="sheet-scrim"
    tabindex="-1"
    aria-label={$t('sheet.close')}
    onclick={onclose}
    transition:scrimMotion|global
></button>
<div class="sheet" role="dialog" aria-modal="false" aria-label={suburb.name} transition:sheetMotion|global>
    <header class="sheet-head">
        <div class="title">
            <h2>{suburb.name} <span class="state-chip">{suburb.state}</span></h2>
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
            data-tour="plan-tab"
            class:active={tab === 'plan'}
            onclick={() => (tab = 'plan')}>{$t('sheet.tab.plan')}</button
        >
    </div>

    <div class="body" data-tour={tab === 'plan' ? 'plan' : undefined} bind:this={bodyEl}>
        {#if tab === 'zone'}
            <div class="metrics">
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
                        <span class="decile" aria-hidden="true">
                            {#each Array.from({ length: 10 }, (_, i) => i) as i (i)}
                                <span class:on={i < (f.seifa_irsad_decile ?? 0)}></span>
                            {/each}
                        </span>
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
    <SectionMenu groups={menuGroups} current={menuCurrent} onpick={toTop} />
</div>
