<script lang="ts">
    // The map-first home (8-S2): a full-bleed suburb-intelligence map. v1 is the
    // centroid bubble layer coloured by Vietnamese ancestry (the killer layer), a
    // state selector (the engine's query grain), a legend, the CC-BY attribution
    // strip (§6.1), and the click-sheet. Mobile-native: full-bleed canvas, the
    // sheet is a bottom-sheet on phone / side-panel on desktop (§7.1).
    import { onMount } from 'svelte';
    import {
        getSuburbs,
        listPlanCards,
        getAllNews,
        type Suburb,
        type SuburbSource,
        type NewsNote
    } from '$lib/api';
    import {
        MAP_SCOPES,
        STATE_NAMES,
        STATE_VIEW,
        DEFAULT_STATE,
        SIZE_CRITERIA,
        DEFAULT_SIZE_BY,
        legendFor,
        type MapScope,
        type SizeBy
    } from '$lib/map';
    import { signinFlag, type SigninFlag } from '$lib/auth';
    import { refreshSession, session, sessionExpired, dismissSessionExpired } from '$lib/stores/session';
    import { loginOpen } from '$lib/stores/ui';
    import { clickOutside } from '$lib/actions/clickOutside';
    import SuburbMap from '$lib/SuburbMap.svelte';
    import SuburbSheet from '$lib/SuburbSheet.svelte';
    import Onboarding from '$lib/Onboarding.svelte';
    import Login from '$lib/Login.svelte';
    import NewsTicker from '$lib/NewsTicker.svelte';
    import NewsListSheet from '$lib/NewsListSheet.svelte';
    import NewsDetailSheet from '$lib/NewsDetailSheet.svelte';
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
    let suburbs = $state<Suburb[]>([]);
    let attribution = $state<SuburbSource[]>([]);
    let loading = $state(true);
    let errored = $state(false);
    let selected = $state<Suburb | null>(null);
    // Onboarding opens over the map from the selected suburb's planning tab (8-S3).
    let planning = $state(false);
    // Bumped when a plan card is created → the sheet's Plan tab reloads in place to show
    // it (no close/reopen). Passed to SuburbSheet as `reloadPlan`.
    let planReload = $state(0);
    // The calm feedback banner the backend redirects back with (the login sheet's
    // open state now lives in the shared `loginOpen` store, opened from the header).
    let banner = $state<SigninFlag | null>(null);

    // Homepage KB-news ticker (kb-news-feature.md "Homepage ticker", 2026-07-08): every
    // compiled news note, unfiltered — distinct from PlanProjection's per-card,
    // relevance-filtered ticker, which is unchanged. No dismiss here (see NewsDetailSheet).
    let homeNews = $state<NewsNote[]>([]);
    // Two-layer flow ("News overview sheet", 2026-07-09): tapping the ticker opens the
    // categorized overview (layer 1, homeNewsListOpen); tapping a headline in it opens the
    // detail sheet (layer 2, selectedHomeNews) — same detail sheet the per-card ticker uses.
    let homeNewsListOpen = $state(false);
    let selectedHomeNews = $state<NewsNote | null>(null);
    // Real measured height of the ticker band, fed into --home-news-h so the
    // controls-cluster/signin-banner offsets never hardcode a magic constant
    // (kb-news-feature.md task 29's regression is the lesson here — measure, don't guess).
    let newsBandHeight = $state(0);
    // CC-BY attribution is required (§6.1) but space-cheap when collapsed to a chip.
    let attrOpen = $state(false);

    // --- Saved-plans + name filter (state × saved × name) --------------------
    // "Suburbs with a saved plan" = those whose name matches a plan-card title — the
    // SAME binding PlanProjection uses (title === suburb name). Signed-in only
    // (listPlanCards 401 → []). KNOWN LIMIT: a title is just the name, so under ALL
    // scope a duplicate name (Richmond Vic/NSW) matches in both states; fixing needs
    // state in the card title (a data-model change) — out of scope here.
    let savedTitles = $state<Set<string>>(new Set());
    let savedOnly = $state(false);
    let nameQuery = $state('');
    let comboFocused = $state(false);
    // The controls cluster collapses to a glass icon by default (Feature 2).
    let controlsOpen = $state(false);
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

    // Refresh the saved set on sign-in and after a new plan is created (planReload).
    $effect(() => {
        void $session; // re-run when the session resolves / changes
        void planReload; // …and when a plan is created
        listPlanCards().then((cards) => {
            savedTitles = new Set(cards.map((c) => c.title));
        });
    });
    // Signing out hides the saved checkbox — don't strand the filter on an empty set.
    $effect(() => {
        if (!$session) savedOnly = false;
    });

    // The visible set: state-fetched suburbs ∩ (saved?) ∩ (name search). All three AND.
    const visible = $derived.by(() => {
        let list = suburbs;
        if (savedOnly) list = list.filter((s) => savedTitles.has(s.name));
        const q = fold(nameQuery);
        if (q) list = list.filter((s) => fold(s.name).includes(q));
        return list;
    });
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

    // On load: learn the session, and surface any ?signin=… feedback from a redeem /
    // OAuth redirect, then strip the query so a reload doesn't replay it (§7.1 calm).
    onMount(() => {
        refreshSession();
        const flag = signinFlag(window.location.search);
        if (flag) {
            banner = flag;
            history.replaceState(null, '', window.location.pathname);
        }
        getAllNews().then((news) => (homeNews = news));
    });

    // Ticker tap opens the overview, not a specific note's detail — "which headline was
    // showing" doesn't matter, the friend's suggested flow always goes ticker -> list first.
    function onHomeTickerTap() {
        homeNewsListOpen = true;
    }
    function onHomeNewsListClose() {
        homeNewsListOpen = false;
    }
    function onHomeNewsListSelect(note: NewsNote) {
        homeNewsListOpen = false;
        selectedHomeNews = note;
    }
    function onHomeNewsClose() {
        selectedHomeNews = null;
    }

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

<div class="map-shell" style="--home-news-h: {newsBandHeight}px">
    {#if homeNews.length > 0}
        <div class="home-news-band" bind:clientHeight={newsBandHeight}>
            <NewsTicker
                news={homeNews}
                onSelect={onHomeTickerTap}
                variant="marquee"
                ariaLabel={$t('home.news.aria')}
            />
        </div>
    {/if}

    {#if !loading && !errored}
        <SuburbMap
            bind:this={mapRef}
            suburbs={visible}
            center={view.center}
            zoom={view.zoom}
            {sizeBy}
            pulseSaved={savedOnly}
            {selected}
            onselect={(s) => (selected = s)}
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

    <!-- Session-expired cue (the 1-day JWT lapsed under a previously-signed-in user) —
         distinct from never-signed-in: prompt a calm re-login so the saved-plans surface
         doesn't just silently vanish. Signing in restores the checkbox + the saved set. -->
    {#if $sessionExpired}
        <div class="signin-banner signin-banner-cue" role="status">
            <span class="signin-banner-msg">{$t('auth.expired.cue')}</span>
            <span class="signin-banner-actions">
                <button
                    type="button"
                    class="signin-banner-action"
                    onclick={() => {
                        dismissSessionExpired();
                        loginOpen.set(true);
                    }}>{$t('auth.signin')}</button
                >
                <button
                    type="button"
                    onclick={dismissSessionExpired}
                    aria-label={$t('sheet.close')}>✕</button
                >
            </span>
        </div>
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
        <button
            type="button"
            class="controls-toggle"
            aria-expanded={controlsOpen}
            aria-label={$t('map.filters')}
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
        </button>

        {#if controlsOpen}
            <div class="map-controls">
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

                <!-- Saved-plans filter — signed-in only (no saved plans = a dead control
                     when logged out). The checkbox restricts the map to suburbs that have
                     a saved plan (bright pulse); the combobox narrows further by name. -->
                {#if $session}
                    <div class="control control-saved">
                        <label class="checkbox">
                            <input type="checkbox" bind:checked={savedOnly} />
                            <span>{$t('filter.saved')}</span>
                        </label>
                        <div class="combo">
                            <input
                                type="text"
                                class="combo-input"
                                placeholder={$t('filter.name.placeholder')}
                                bind:value={nameQuery}
                                onfocus={() => (comboFocused = true)}
                                autocomplete="off"
                            />
                            {#if comboFocused && suggestions.length}
                                <ul class="combo-list">
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
                                <ul class="combo-list">
                                    <li class="combo-empty">{$t('filter.nomatch')}</li>
                                </ul>
                            {/if}
                        </div>
                        {#if savedOnly && savedTitles.size === 0}
                            <p class="filter-hint">{$t('filter.saved.empty')}</p>
                        {/if}
                    </div>
                {/if}
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
                reloadPlan={planReload}
                onclose={() => (selected = null)}
                onplan={() => (planning = true)}
            />
        {/key}
    {/if}

    {#if planning && selected}
        <Onboarding
            stateCode={auState}
            suburbName={selected.name}
            suburbSal={selected.sal_code}
            oncreated={() => {
                planning = false;
                planReload++;
            }}
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

    {#if homeNewsListOpen}
        <NewsListSheet news={homeNews} onSelectNote={onHomeNewsListSelect} onClose={onHomeNewsListClose} />
    {/if}

    {#if selectedHomeNews}
        <NewsDetailSheet note={selectedHomeNews} onClose={onHomeNewsClose} />
    {/if}
</div>
