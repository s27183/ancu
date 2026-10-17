<script lang="ts">
    // Bilingual -> the first-screen sentence -> The web frontend -> the map page (/explore)
    // The suburb-intelligence map (8-S2), its own page since behavior 81 (Son 2026-10-16:
    // the home leads to Plan or Explore; the map no longer opens first): a full-bleed
    // centroid bubble layer, a state selector (the engine's query grain), a legend, the
    // CC-BY attribution strip (§6.1), and the click-sheet with the suburb's facts — the
    // plan lives on /plan now. Mobile-native: full-bleed canvas, the sheet is a
    // bottom-sheet on phone / centred panel on desktop (§7.1). The news band, sign-in
    // sheet and banners are the layout's.
    import { untrack } from 'svelte';
    import {
        getSuburbs,
        listSavedSuburbs,
        saveSuburb,
        unsaveSuburb,
        type SavedSuburb,
        type Suburb,
        type SuburbSource
    } from '$lib/api';
    import {
        MAP_SCOPES,
        STATE_NAMES,
        STATE_VIEW,
        DEFAULT_STATE,
        SIZE_CRITERIA,
        DEFAULT_SIZE_BY,
        legendFor,
        BASEMAP_CREDIT,
        type MapScope,
        type SizeBy
    } from '$lib/map';
    import { session } from '$lib/stores/session';
    import { loginOpen } from '$lib/stores/ui';
    import { clickOutside } from '$lib/actions/clickOutside';
    import SuburbMap from '$lib/SuburbMap.svelte';
    import SuburbSheet from '$lib/SuburbSheet.svelte';
    import { savePending, takePending, type PendingOnboarding } from '$lib/pendingOnboarding';
    import Tour from '$lib/Tour.svelte';
    import HomeBack from '$lib/HomeBack.svelte';
    import { tourStep, tourRun, tourEvent, tourDone, startTour } from '$lib/tour';
    import { introOpen, mapHintDone, markMapHintDone } from '$lib/mapHint';
    import { t } from '$lib/i18n';

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
    let suburbs = $state<Suburb[]>([]);
    let attribution = $state<SuburbSource[]>([]);
    let loading = $state(true);
    let errored = $state(false);
    let selected = $state<Suburb | null>(null);
    // The suburb whose sheet the visitor just closed — pulses on the map, red if saved (behavior 70), else jade, so they can
    // find where they were (behavior 54). Set by the sheet's close, cleared when any
    // suburb opens (that one pulses magenta) or the tour resets; never persisted.
    let recent = $state<Suburb | null>(null);
    $effect(() => {
        if (selected) recent = null;
    });
    // The sign-in round-trip (pendingOnboarding.ts): a guest who opened sign-in with a
    // suburb's sheet open comes back to that suburb, once its scope's suburbs are in.
    let pendingRestore = $state<PendingOnboarding | null>(null);
    let loadedScope = $state<MapScope | null>(null);
    let pendingTaken = false;

    // CC-BY attribution is required (§6.1) but space-cheap when collapsed to a chip.
    let attrOpen = $state(false);
    let basemapOn = $state(false);

    // --- Saved suburbs + name filter (state × saved × name) -------------------
    // Behavior 84 (Son 2026-10-16): a saved suburb is its own record, keyed by SAL code
    // (/api/saved-suburbs; the shell seeds it once from a user's older suburb-titled
    // plans), saved and unsaved by the heart on the suburb sheet. Signed-in only: a guest
    // or a signed-out visitor holds none, and the heart asks them to sign in.
    let saved = $state<SavedSuburb[]>([]);
    const savedSals = $derived(new Set(saved.map((s) => s.sal_code)));
    let savedOnly = $state(false);
    let nameQuery = $state('');
    let comboFocused = $state(false);
    // The controls cluster collapses to a glass icon by default (Feature 2).
    let controlsOpen = $state(false);
    // The finding pointer beside the filter button (behavior 78, mapHint.ts): gone for
    // this page view once the filter opens, the map zooms or a suburb opens; a suburb
    // opened ends it for this browser. Only the visitor's own acts count: the tour opens
    // the panel, a suburb and flies the map itself, and the pointer must still show once
    // it ends (measured 2026-10-15: without the guard, skipping the tour left no pointer).
    // `untrack` so a tour ending with the panel or a suburb open is not read as an act.
    let hintGone = $state(mapHintDone());
    const byVisitor = () => untrack(() => $tourStep) === 0;
    $effect(() => {
        if (controlsOpen && byVisitor()) hintGone = true;
    });
    $effect(() => {
        if (selected && byVisitor()) {
            hintGone = true;
            markMapHintDone();
        }
    });
    const showMapHint = $derived(!hintGone && !$introOpen && $tourStep === 0 && !loading && !errored);
    // The map component instance — for fly-to from the name combobox.
    let mapRef = $state<SuburbMap>();

    // Diacritic/case-insensitive (Vietnamese đ folded) so "Footscray"/"footscray" and
    // any accented input match the same suburb.
    const fold = (s: string) =>
        s
            .normalize('NFD')
            .replace(/[̀-ͯ]/g, '') // strip combining diacritics
            .replace(/đ/g, 'd') // đ → d (no NFD decomposition)
            .toLowerCase()
            .trim();

    // Refresh the saved set on sign-in; a sign-out empties it.
    $effect(() => {
        if (!$session) {
            saved = [];
            return;
        }
        listSavedSuburbs().then((list) => (saved = list));
    });
    // The heart: signed in, it saves or unsaves (the reply is the whole list, so the
    // pulse and the list follow the database, never a guess); otherwise it opens sign-in,
    // and the round-trip below brings them back to this suburb to save it.
    let saving = $state(false);
    async function toggleSaved(s: Suburb) {
        if (!$session) {
            loginOpen.set(true);
            return;
        }
        if (saving) return;
        saving = true;
        try {
            const list = savedSals.has(s.sal_code) ? await unsaveSuburb(s.sal_code) : await saveSuburb(s);
            if (list) saved = list;
        } finally {
            saving = false;
        }
    }
    // A saved suburb from the list: open it here if its scope is loaded, else switch to
    // its state and open it once that has loaded (the sign-in restore's path).
    function openSaved(x: SavedSuburb) {
        const s = suburbs.find((y) => y.sal_code === x.sal_code);
        if (s) return pickSuburb(s);
        pendingRestore = { page: 'explore', sal: x.sal_code, scope: x.state, ts: Date.now() };
        auState = x.state as MapScope;
    }
    // Signing out hides the saved checkbox — don't strand the filter on an empty set.
    $effect(() => {
        if (!$session) savedOnly = false;
    });

    // The visible set: state-fetched suburbs ∩ (saved?) ∩ (name search). All three AND.
    const visible = $derived.by(() => {
        let list = suburbs;
        if (savedOnly) list = list.filter((s) => savedSals.has(s.sal_code));
        const q = fold(nameQuery);
        if (q) list = list.filter((s) => fold(s.name).includes(q));
        return list;
    });
    // Every saved suburb in the fetched state(s), for the map's red overlay while the
    // saved filter is off (behavior 76) — kept while a name is typed, so a visitor never
    // loses sight of what they saved.
    const savedSuburbs = $derived(
        savedOnly || savedSals.size === 0 ? [] : suburbs.filter((s) => savedSals.has(s.sal_code))
    );
    // Name-combobox suggestions: the current visible set with a point, capped — only
    // while typing (an empty query shows none, so the dropdown is gone after a pick).
    const suggestions = $derived(
        fold(nameQuery) ? visible.filter((s) => s.centroid).slice(0, 8) : []
    );

    function pickSuburb(s: Suburb) {
        if (s.centroid) mapRef?.flyTo(s.centroid.lon, s.centroid.lat);
        selected = s;
        nameQuery = '';
        comboFocused = false;
        controlsOpen = false;
    }

    const view = $derived(STATE_VIEW[auState]);

    // --- The first-visit tour (behavior 52; flow in tour.ts) ---------------------------
    // It follows the suburb sheet opening and closing…
    $effect(() => {
        tourEvent(selected ? 'suburb' : 'unsuburb');
    });
    // …starts by itself on this browser's first visit to the map (behavior 81: the map is
    // its own page now, so the tour no longer waits on the home's "Giới thiệu")…
    $effect(() => {
        if (untrack(() => $tourStep) === 0 && !tourDone()) startTour();
    });
    // …starts from the bare map (a replay may begin over an open sheet)…
    let seenRun = 0;
    $effect(() => {
        if ($tourRun === seenRun) return;
        seenRun = $tourRun;
        selected = null;
        recent = null;
    });
    // …and shows the suburb search on step 1, the control it points at.
    $effect(() => {
        if ($tourStep === 1) controlsOpen = true;
    });
    // "Try Cabramatta": fly there and open its sheet, as a pick from the search does.
    // Outside the loaded scope it switches to NSW first and picks once that has loaded.
    const TRY_SUBURB = { name: 'Cabramatta', scope: 'NSW' as MapScope };
    let tryPending = $state(false);
    function tryTourSuburb() {
        const s = suburbs.find((x) => x.name === TRY_SUBURB.name);
        if (s) return pickSuburb(s);
        tryPending = true;
        auState = TRY_SUBURB.scope;
    }
    $effect(() => {
        if (!tryPending || loading || loadedScope !== TRY_SUBURB.scope) return;
        tryPending = false;
        const s = suburbs.find((x) => x.name === TRY_SUBURB.name);
        if (s) pickSuburb(s);
    });


    // After the first load the map stays mounted (behavior 79, SuburbMap flyToView):
    // a later state's dots load behind the current ones, with no loading cover.
    let loadedOnce = $state(false);
    async function load(st: MapScope) {
        loading = true;
        errored = false;
        selected = null;
        loadedScope = null;
        try {
            const res = await getSuburbs(st);
            if (st !== auState) return; // a later pick superseded this one
            suburbs = res.suburbs;
            attribution = res.attribution;
            loadedScope = st;
            loadedOnce = true;
        } catch {
            if (st !== auState) return;
            errored = true;
            suburbs = [];
            attribution = [];
        } finally {
            if (st === auState) loading = false;
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
    // …and fly the map from where it is to the new state's view (behavior 79). Only a
    // real change: the scope the map already shows does nothing. If the map is not
    // mounted (first load, or after an error) it opens at `view` when it mounts.
    let viewScope: MapScope = untrack(() => auState);
    $effect(() => {
        const st = auState;
        if (st === viewScope) return;
        viewScope = st;
        const v = STATE_VIEW[st];
        untrack(() => mapRef)?.flyToView(v.center, v.zoom);
    });

    // Once signed in, take the suburb the user left for the sign-in (read once, so a
    // reload never reopens it) and switch to the scope they were on…
    $effect(() => {
        if (!$session || pendingTaken) return;
        pendingTaken = true;
        const p = takePending('explore');
        if (p && (MAP_SCOPES as string[]).includes(p.scope)) {
            pendingRestore = p;
            auState = p.scope as MapScope;
        }
    });
    // …then, when that scope's suburbs are in, reopen that suburb.
    $effect(() => {
        const p = pendingRestore;
        if (!p || loading || loadedScope !== p.scope) return;
        pendingRestore = null;
        const s = suburbs.find((x) => x.sal_code === p.sal);
        if (s) pickSuburb(s);
    });
    // Behavior 45: a guest opening sign-in with a suburb's sheet open (the header's menu)
    // comes back to that suburb after the round-trip (the home routes it here, b81) — and
    // since behavior 84 any signed-out visitor, whom the sheet's heart sends to sign in.
    $effect(() => {
        if ($loginOpen && !$session && selected)
            savePending({ page: 'explore', sal: selected.sal_code, scope: auState, ts: Date.now() });
    });
</script>

<div class="map-shell">

    {#if loadedOnce && !errored}
        <SuburbMap
            bind:this={mapRef}
            bind:basemap={basemapOn}
            suburbs={visible}
            center={view.center}
            zoom={view.zoom}
            {sizeBy}
            pulseSaved={savedOnly}
            saved={savedSuburbs}
            {selected}
            {recent}
            recentSaved={!!recent && savedSals.has(recent.sal_code)}
            onselect={(s) => (selected = s)}
            onuserzoom={() => {
                if (byVisitor()) hintGone = true;
            }}
        />
    {/if}

    <!-- Map controls — collapsed to a glass icon by default; click to expand, click
         OUTSIDE to collapse (an action, not a backdrop — a backdrop would block the
         map). Holds state (the query grain) + the size/colour criterion + the saved-
         plans filter (state × saved × name). -->
    <div
        class="controls-cluster"
        class:open={controlsOpen}
        use:clickOutside={() => (controlsOpen = false)}
    >
        <!-- Behavior 88: the way home first, top-left, where the planner and the News
             page carry it in their heads; behavior 115: the filters' button at the far
             right of the same row, the pointer and the panel under it. -->
        <div class="controls-row">
        <HomeBack />
        <button
            type="button"
            class="controls-toggle"
            data-tour="controls"
            aria-expanded={controlsOpen}
            onclick={() => (controlsOpen = !controlsOpen)}
        >
            <svg
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="2"
                stroke-linecap="round"
                stroke-linejoin="round"
                aria-hidden="true"
            >
                <line x1="4" y1="7" x2="20" y2="7" />
                <line x1="4" y1="12" x2="20" y2="12" />
                <line x1="4" y1="17" x2="20" y2="17" />
                <circle cx="9" cy="7" r="2.4" fill="var(--surface)" />
                <circle cx="15" cy="12" r="2.4" fill="var(--surface)" />
                <circle cx="9" cy="17" r="2.4" fill="var(--surface)" />
            </svg>
            <span class="controls-label">{$t('map.filters')}</span>
        </button>
        </div>

        {#if showMapHint && !controlsOpen}
            <p class="map-hint" role="note">{$t('map.hint')}</p>
        {/if}

        {#if controlsOpen}
            <div class="map-controls">
                <p class="controls-purpose">{$t('map.filters.purpose')}</p>
                <div class="control">
                    <label for="state-select">{$t('map.state.label')}</label>
                    <div class="select-wrap">
                        <select id="state-select" bind:value={auState}>
                            {#each MAP_SCOPES as s (s)}
                                <option value={s}
                                    >{s === 'ALL'
                                        ? $t('map.state.all')
                                        : `${STATE_NAMES[s]} (${s})`}</option
                                >
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

                <!-- Saved-suburbs filter — signed-in only (none saved = a dead control
                     when logged out). The checkbox restricts the map to the saved suburbs
                     (bright pulse), listed below the search; the combobox narrows by name. The
                     name search is for everyone (behavior 52: the tour's first bubble points
                     at it, and a guest can build a plan since behavior 45). -->
                <div class="control control-saved">
                    {#if $session}
                        <label class="checkbox">
                            <input type="checkbox" bind:checked={savedOnly} />
                            <span>{$t('filter.saved')}</span>
                        </label>
                    {/if}
                    <div class="combo" data-tour="search">
                        <input
                            type="text"
                            class="combo-input"
                            placeholder={$t('filter.name.placeholder')}
                            bind:value={nameQuery}
                            onfocus={() => (comboFocused = true)}
                            autocomplete="off"
                        />
                        {#if comboFocused && suggestions.length}
                            <ul class="combo-list" data-tour-part>
                                {#each suggestions as s (s.sal_code)}
                                    <li>
                                        <button type="button" onclick={() => pickSuburb(s)}>
                                            <span class="combo-name">{s.name}</span>
                                            <span class="combo-state">{s.state}</span>
                                        </button>
                                    </li>
                                {/each}
                            </ul>
                        {:else if comboFocused && fold(nameQuery)}
                            <ul class="combo-list" data-tour-part>
                                <li class="combo-empty">{$t('filter.nomatch')}</li>
                            </ul>
                        {/if}
                    </div>
                    {#if $session && saved.length === 0}
                        <p class="filter-hint">{$t('filter.saved.empty')}</p>
                    {:else if $session}
                        <!-- The saved suburbs, newest first: a tap opens one (behavior 84). -->
                        <ul class="saved-list" aria-label={$t('filter.saved.list')}>
                            {#each saved as x (x.sal_code)}
                                <li>
                                    <button type="button" onclick={() => openSaved(x)}>
                                        <span class="combo-name">{x.name}</span>
                                        <span class="combo-state">{x.state}</span>
                                    </button>
                                </li>
                            {/each}
                        </ul>
                    {/if}
                </div>
            </div>
        {/if}
    </div>

    <!-- Legend — reflects the selected criterion. Hidden in saved-only mode, where the
         dots are a uniform bright pulse, not the criterion ramp. -->
    {#if !savedOnly}
        <div class="legend" aria-hidden="true">
            <span class="legend-title">{$t(sizeLabelKey[sizeBy])}</span>
            <div
                class="legend-bar"
                style="background:linear-gradient(to right, {legend.gradient})"
            ></div>
            <div class="legend-scale"><span>{legend.min}</span><span>{legend.max}</span></div>
            <div class="legend-nodata"><span class="swatch"></span>{$t('map.legend.nodata')}</div>
        </div>
    {/if}

    {#if loading && !loadedOnce}
        <div class="overlay"><p>{$t('map.loading')}</p></div>
    {:else if errored}
        <div class="overlay">
            <p>{$t('map.error')}</p>
            <button type="button" onclick={() => load(auState)}>{$t('map.retry')}</button>
        </div>
    {/if}

    {#if attribution.length || basemapOn}
        <!-- One "i" holds every credit: the basemap's (Protomaps © OpenStreetMap) and
             each data source's (CC-BY §6.1). A tap anywhere outside closes it — the
             scrim takes that tap, so it never also selects a suburb (behavior 43). -->
        {#if attrOpen}
            <div class="attr-scrim" aria-hidden="true" onpointerdown={() => (attrOpen = false)}></div>
        {/if}
        <div class="attribution" class:open={attrOpen}>
            {#if attrOpen}
                <div class="attr-list" id="attr-list" role="dialog" aria-label={$t('map.sources')}>
                    {#if basemapOn}
                        <span class="attr-map"
                            >{$t('map.basemap')}: {#each BASEMAP_CREDIT as c, i (c.name)}{#if i > 0}{' © '}{/if}<a
                                    href={c.url}
                                    target="_blank"
                                    rel="noopener">{c.name}</a
                                >{/each}</span
                        >
                    {/if}
                    {#each attribution as src (src.source_id)}<span>{src.attribution}</span>{/each}
                    <!-- The standing disclaimer, one tap away on every visit (behavior 44). -->
                    <span class="attr-disclaimer">{$t('disclaimer.asic')}</span>
                </div>
            {/if}
            <button
                type="button"
                class="attr-toggle"
                aria-expanded={attrOpen}
                aria-controls="attr-list"
                aria-label={$t('map.sources')}
                onclick={() => (attrOpen = !attrOpen)}
            >
                <svg viewBox="0 0 16 16" width="14" height="14" aria-hidden="true"
                    ><circle cx="8" cy="8" r="7" fill="none" stroke="currentColor" stroke-width="1.5" /><rect
                        x="7.25"
                        y="7"
                        width="1.5"
                        height="5"
                        rx=".75"
                        fill="currentColor"
                    /><circle cx="8" cy="4.6" r="1" fill="currentColor" /></svg
                >
            </button>
        </div>
    {/if}

    {#if selected}
        {#key selected.sal_code}
            <SuburbSheet
                suburb={selected}
                saved={savedSals.has(selected.sal_code)}
                {saving}
                ontogglesaved={() => selected && toggleSaved(selected)}
                onclose={() => {
                    recent = selected;
                    selected = null;
                }}
            />
        {/key}
    {/if}

    <Tour ontry={tryTourSuburb} />
</div>
