<script lang="ts">
    // Bilingual -> The web frontend -> the suburb sheet on the map page
    // The suburb-click detail (8-S2): a bottom-sheet on phone, a centred panel on desktop
    // (one layout, adjusted — shell-architecture.md §7.1): the suburb's raw facts,
    // rendered from the already-loaded list payload (no detail endpoint). Raw figures read
    // as calm reference, never a verdict (crime is map-display only, not a rating). Its
    // Plan tab, the section menu and the head's way to the plan left with behavior 81:
    // the plan is the planner page's (/plan), so the sheet is the facts alone and as tall
    // as they are on a phone (.sheet-facts). The heart in its head saves the suburb
    // (behavior 84): red when saved, the colour of the saved pulse on the map.
    import type { Suburb } from '$lib/api';
    import { t } from '$lib/i18n';
    import { lang } from '$lib/stores/lang';
    import { sheetMotion, scrimMotion } from '$lib/sheetMotion';

    let {
        suburb,
        saved = false,
        saving = false,
        ontogglesaved,
        onclose
    }: {
        suburb: Suburb;
        /** Whether the signed-in user has saved this suburb (behavior 84). */
        saved?: boolean;
        /** A save or unsave is on its way: the heart waits for the database's answer. */
        saving?: boolean;
        /** The heart: the page saves or unsaves, or asks a signed-out visitor to sign in. */
        ontogglesaved: () => void;
        onclose: () => void;
    } = $props();

    const nf = $derived(new Intl.NumberFormat($lang === 'vi' ? 'vi-VN' : 'en-AU'));
    const f = $derived(suburb.facts);

    function pct(n: number | undefined): string {
        return typeof n === 'number' ? `${nf.format(n)}%` : '';
    }
</script>

<!-- The veil behind the sheet (behavior 71): dims the map as "Giới thiệu" dims the page;
     a tap on it closes the sheet. Not in the tab order — the ✕ and Esc are the keyboard way. -->
<button
    type="button"
    class="sheet-scrim"
    tabindex="-1"
    aria-label={$t('sheet.close')}
    onclick={onclose}
    transition:scrimMotion|global
></button>
<div class="sheet sheet-facts" role="dialog" aria-modal="false" aria-label={suburb.name} transition:sheetMotion|global>
    <header class="sheet-head">
        <div class="title">
            <h2>{suburb.name} <span class="state-chip">{suburb.state}</span></h2>
            {#if suburb.lga_name}
                <p class="sub">{suburb.lga_name}</p>
            {/if}
        </div>
        <button
            type="button"
            class="save-heart"
            class:on={saved}
            aria-pressed={saved}
            aria-label={$t(saved ? 'sheet.unsave' : 'sheet.save')}
            title={$t(saved ? 'sheet.unsave' : 'sheet.save')}
            disabled={saving}
            onclick={ontogglesaved}
            ><svg viewBox="0 0 24 24" width="18" height="18" aria-hidden="true"
                ><path
                    d="M12 20.5s-7.5-4.6-7.5-10.1A4.3 4.3 0 0 1 12 7.6a4.3 4.3 0 0 1 7.5 2.8c0 5.5-7.5 10.1-7.5 10.1Z"
                    fill={saved ? 'currentColor' : 'none'}
                    stroke="currentColor"
                    stroke-width="2"
                    stroke-linejoin="round"
                /></svg
            ></button
        >
        <button type="button" class="close" onclick={onclose} aria-label={$t('sheet.close')}
            >✕</button
        >
    </header>

    <div class="body" data-tour="facts">
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
    </div>
</div>
