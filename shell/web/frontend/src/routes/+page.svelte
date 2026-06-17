<script lang="ts">
    // The map-first home (8-S2): a full-bleed suburb-intelligence map. v1 is the
    // centroid bubble layer coloured by Vietnamese ancestry (the killer layer), a
    // state selector (the engine's query grain), a legend, the CC-BY attribution
    // strip (§6.1), and the click-sheet. Mobile-native: full-bleed canvas, the
    // sheet is a bottom-sheet on phone / side-panel on desktop (§7.1).
    import { onMount } from 'svelte';
    import { getSuburbs, type Suburb, type SuburbSource } from '$lib/api';
    import {
        MAP_SCOPES,
        STATE_VIEW,
        DEFAULT_STATE,
        SIZE_CRITERIA,
        DEFAULT_SIZE_BY,
        legendFor,
        heatmapEnabled,
        OVERVIEW_MAX_ZOOM,
        type MapScope,
        type SizeBy
    } from '$lib/map';
    import { signinFlag, type SigninFlag } from '$lib/auth';
    import { refreshSession } from '$lib/stores/session';
    import { loginOpen } from '$lib/stores/ui';
    import SuburbMap from '$lib/SuburbMap.svelte';
    import SuburbSheet from '$lib/SuburbSheet.svelte';
    import Onboarding from '$lib/Onboarding.svelte';
    import Login from '$lib/Login.svelte';
    import { t, type MessageKey } from '$lib/i18n';

    // NB: never name a $state var `state` — svelte-check reads it as a store subscribe.
    let auState = $state<MapScope>(DEFAULT_STATE);
    // The criterion driving each suburb dot's colour + size (economic index default).
    let sizeBy = $state<SizeBy>(DEFAULT_SIZE_BY);
    const sizeLabelKey = {
        seifa: 'map.size.seifa',
        vietnamese: 'map.size.vietnamese',
        population: 'map.size.population',
        crime: 'map.size.crime'
    } as const;
    const legend = $derived(legendFor(sizeBy));
    // Live map zoom (reported by SuburbMap). Drives the overview hint for intensive
    // criteria, which have no heatmap and only reveal their dots once you zoom in.
    let mapZoom = $state(STATE_VIEW[DEFAULT_STATE].zoom);
    const showZoomHint = $derived(!heatmapEnabled(sizeBy) && mapZoom < OVERVIEW_MAX_ZOOM);
    let suburbs = $state<Suburb[]>([]);
    let attribution = $state<SuburbSource[]>([]);
    let loading = $state(true);
    let errored = $state(false);
    let selected = $state<Suburb | null>(null);
    // Onboarding opens over the map from the selected suburb's planning tab (8-S3).
    let planning = $state(false);
    // The calm feedback banner the backend redirects back with (the login sheet's
    // open state now lives in the shared `loginOpen` store, opened from the header).
    let banner = $state<SigninFlag | null>(null);
    // CC-BY attribution is required (§6.1) but space-cheap when collapsed to a chip.
    let attrOpen = $state(false);

    const view = $derived(STATE_VIEW[auState]);

    // On load: learn the session, and surface any ?signin=… feedback from a redeem /
    // OAuth redirect, then strip the query so a reload doesn't replay it (§7.1 calm).
    onMount(() => {
        refreshSession();
        const flag = signinFlag(window.location.search);
        if (flag) {
            banner = flag;
            history.replaceState(null, '', window.location.pathname);
        }
    });

    async function load(st: MapScope) {
        loading = true;
        errored = false;
        selected = null;
        try {
            const res = await getSuburbs(st);
            suburbs = res.suburbs;
            attribution = res.attribution;
        } catch {
            errored = true;
            suburbs = [];
            attribution = [];
        } finally {
            loading = false;
        }
    }

    // Fetch when the chosen state changes. This is a genuine side-effect (a network
    // read), which is what $effect is for — it reads only `auState` and writes a
    // disjoint set of state it never reads back, so there is no reactivity loop. A
    // +page.ts load would force a full-page error boundary; the inline loading/error/
    // retry below is the calm, never-blank-wait surface §7.1 calls for.
    $effect(() => {
        load(auState);
    });
</script>

<div class="map-shell">
    {#if !loading && !errored}
        <SuburbMap
            {suburbs}
            center={view.center}
            zoom={view.zoom}
            {sizeBy}
            onselect={(s) => (selected = s)}
            onzoom={(z) => (mapZoom = z)}
        />
    {/if}

    {#if banner}
        <div class="signin-banner" class:ok={banner === 'ok'} role="status">
            <span>{$t(`auth.flag.${banner}` as MessageKey)}</span>
            <button type="button" onclick={() => (banner = null)} aria-label={$t('sheet.close')}
                >✕</button
            >
        </div>
    {/if}

    <!-- Map controls — state (the engine's query grain) + the size/colour criterion.
         Native <select>s, restyled: the most thumb-friendly control on phone (§7.1). -->
    <div class="map-controls">
        <div class="control">
            <label for="state-select">{$t('map.state.label')}</label>
            <div class="select-wrap">
                <select id="state-select" bind:value={auState}>
                    {#each MAP_SCOPES as s (s)}
                        <option value={s}>{s === 'ALL' ? $t('map.state.all') : s}</option>
                    {/each}
                </select>
            </div>
        </div>
        <div class="control">
            <label for="size-select">{$t('map.size.label')}</label>
            <div class="select-wrap">
                <select id="size-select" bind:value={sizeBy}>
                    {#each SIZE_CRITERIA as c (c)}
                        <option value={c}>{$t(sizeLabelKey[c])}</option>
                    {/each}
                </select>
            </div>
        </div>
    </div>

    <!-- Legend — reflects the selected criterion (its label + gradient + endpoints). -->
    <div class="legend" aria-hidden="true">
        <span class="legend-title">{$t(sizeLabelKey[sizeBy])}</span>
        <div class="legend-bar" style="background:linear-gradient(to right, {legend.gradient})"></div>
        <div class="legend-scale"><span>{legend.min}</span><span>{legend.max}</span></div>
        <div class="legend-nodata"><span class="swatch"></span>{$t('map.legend.nodata')}</div>
    </div>

    <!-- Intensive criteria (a rate / an index) get no overview heatmap — a density sum
         would be dishonest — so prompt to zoom in where the per-suburb dots read. -->
    {#if showZoomHint}
        <div class="zoom-hint">{$t('map.zoomhint')}</div>
    {/if}

    {#if loading}
        <div class="overlay"><p>{$t('map.loading')}</p></div>
    {:else if errored}
        <div class="overlay">
            <p>{$t('map.error')}</p>
            <button type="button" onclick={() => load(auState)}>{$t('map.retry')}</button>
        </div>
    {/if}

    {#if attribution.length}
        <!-- Collapsed to a small chip by default (CC-BY stays accessible, §6.1). -->
        <div class="attribution" class:open={attrOpen}>
            <button
                type="button"
                class="attr-toggle"
                aria-expanded={attrOpen}
                onclick={() => (attrOpen = !attrOpen)}
            >
                <span class="attr-mark" aria-hidden="true">©</span>
                <span class="attr-label">{$t('map.sources')}</span>
            </button>
            {#if attrOpen}
                <div class="attr-list">
                    {#each attribution as src (src.source_id)}<span>{src.attribution}</span>{/each}
                </div>
            {/if}
        </div>
    {/if}

    {#if selected}
        {#key selected.sal_code}
            <SuburbSheet
                suburb={selected}
                onclose={() => (selected = null)}
                onplan={() => (planning = true)}
            />
        {/key}
    {/if}

    {#if planning && selected}
        <Onboarding
            stateCode={auState}
            suburbName={selected.name}
            onclose={() => (planning = false)}
            onsignin={() => {
                planning = false;
                loginOpen.set(true);
            }}
        />
    {/if}

    {#if $loginOpen}
        <Login onclose={() => loginOpen.set(false)} />
    {/if}
</div>
