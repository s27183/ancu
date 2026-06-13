<script lang="ts">
    // The map-first home (8-S2): a full-bleed suburb-intelligence map. v1 is the
    // centroid bubble layer coloured by Vietnamese ancestry (the killer layer), a
    // state selector (the engine's query grain), a legend, the CC-BY attribution
    // strip (§6.1), and the click-sheet. Mobile-native: full-bleed canvas, the
    // sheet is a bottom-sheet on phone / side-panel on desktop (§7.1).
    import { getSuburbs, type Suburb, type SuburbSource } from '$lib/api';
    import { AU_STATES, STATE_VIEW, DEFAULT_STATE, type AuState } from '$lib/map';
    import SuburbMap from '$lib/SuburbMap.svelte';
    import SuburbSheet from '$lib/SuburbSheet.svelte';
    import { t } from '$lib/i18n';

    // NB: never name a $state var `state` — svelte-check reads it as a store subscribe.
    let auState = $state<AuState>(DEFAULT_STATE);
    let suburbs = $state<Suburb[]>([]);
    let attribution = $state<SuburbSource[]>([]);
    let loading = $state(true);
    let errored = $state(false);
    let selected = $state<Suburb | null>(null);

    const view = $derived(STATE_VIEW[auState]);

    async function load(st: AuState) {
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
            onselect={(s) => (selected = s)}
        />
    {/if}

    <!-- State selector — the engine's query grain; native <select> is the most
         thumb-friendly control on phone (§7.1). -->
    <div class="state-picker">
        <label for="state-select">{$t('map.state.label')}</label>
        <select id="state-select" bind:value={auState}>
            {#each AU_STATES as s (s)}
                <option value={s}>{s}</option>
            {/each}
        </select>
    </div>

    <!-- Vietnamese-ancestry legend -->
    <div class="legend" aria-hidden="true">
        <span class="legend-title">{$t('map.legend.title')}</span>
        <div class="legend-bar"></div>
        <div class="legend-scale"><span>0%</span><span>40%+</span></div>
        <div class="legend-nodata"><span class="swatch"></span>{$t('map.legend.nodata')}</div>
    </div>

    {#if loading}
        <div class="overlay"><p>{$t('map.loading')}</p></div>
    {:else if errored}
        <div class="overlay">
            <p>{$t('map.error')}</p>
            <button type="button" onclick={() => load(auState)}>{$t('map.retry')}</button>
        </div>
    {/if}

    {#if attribution.length}
        <div class="attribution">
            {#each attribution as src (src.source_id)}<span>{src.attribution}</span>{/each}
        </div>
    {/if}

    {#if selected}
        {#key selected.sal_code}
            <SuburbSheet suburb={selected} onclose={() => (selected = null)} />
        {/key}
    {/if}
</div>
