<script lang="ts">
    // The map-first home (8-S2): a full-bleed suburb-intelligence map. v1 is the
    // centroid bubble layer coloured by Vietnamese ancestry (the killer layer), a
    // state selector (the engine's query grain), a legend, the CC-BY attribution
    // strip (§6.1), and the click-sheet. Mobile-native: full-bleed canvas, the
    // sheet is a bottom-sheet on phone / side-panel on desktop (§7.1).
    import { onMount, tick } from 'svelte';
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
        BASEMAP_CREDIT,
        type MapScope,
        type SizeBy
    } from '$lib/map';
    import { signinFlag, type SigninFlag } from '$lib/auth';
    import { refreshSession, session, guest, sessionExpired, dismissSessionExpired } from '$lib/stores/session';
    import { loginOpen } from '$lib/stores/ui';
    import { clickOutside } from '$lib/actions/clickOutside';
    import SuburbMap from '$lib/SuburbMap.svelte';
    import SuburbSheet from '$lib/SuburbSheet.svelte';
    import Onboarding from '$lib/Onboarding.svelte';
    import {
        savePending,
        takePending,
        type OnboardingAnswers,
        type PendingOnboarding
    } from '$lib/pendingOnboarding';
    import Login from '$lib/Login.svelte';
    import NewsTicker from '$lib/NewsTicker.svelte';
    import NewsListSheet from '$lib/NewsListSheet.svelte';
    import NewsDetailSheet from '$lib/NewsDetailSheet.svelte';
    import Welcome from '$lib/Welcome.svelte';
    import Tour from '$lib/Tour.svelte';
    import { tourStep, tourRun, tourEvent, endTour } from '$lib/tour';
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
    // The sign-in round-trip (pendingOnboarding.ts): answers to reopen onboarding with, the
    // pending restore waiting for its scope's suburbs, and the scope those suburbs are for.
    let restoreAnswers = $state<OnboardingAnswers | undefined>(undefined);
    let pendingRestore = $state<PendingOnboarding | null>(null);
    let loadedScope = $state<MapScope | null>(null);
    let pendingTaken = false;
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
    // Lifted out of NewsListSheet (rather than local $state there) because the sheet is
    // conditionally mounted ({#if homeNewsListOpen} below) — closing a detail note and
    // reopening the list (onHomeNewsClose) remounts NewsListSheet fresh, which would
    // silently drop a local active-tab selection back to 'all' right after the back-nav
    // fix restored "return to where you were." Tabs.svelte's own contract is "the parent
    // owns the active id" — this makes +page.svelte that parent across remounts, not just
    // within one mount.
    let homeNewsActiveCategory = $state('all');
    // Real measured height of the ticker band, fed into --home-news-h so the
    // controls-cluster/signin-banner offsets never hardcode a magic constant
    // (kb-news-feature.md task 29's regression is the lesson here — measure, don't guess).
    let newsBandHeight = $state(0);
    // CC-BY attribution is required (§6.1) but space-cheap when collapsed to a chip.
    let attrOpen = $state(false);
    let basemapOn = $state(false);

    // --- Saved-plans + name filter (state × saved × name) --------------------
    // "Suburbs with a saved plan" = those whose name matches a plan-card title — the
    // SAME binding PlanProjection uses (title === suburb name). Signed-in only
    // (listPlanCards 401 → []). The name is a sound key under ALL scope: ABS SAL names
    // are nationally unique, state-tagged where they collide ("Richmond (Vic.)" vs
    // "Richmond (NSW)"); measured 2026-10-07, 15,345 suburbs, 0 duplicate names
    // (behavior 19). If a future source ever drops the tag, bind on sal_code instead.
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

    // --- The first-visit tour (behavior 52; flow in tour.ts) ---------------------------
    // It follows the suburb sheet opening and closing…
    $effect(() => {
        tourEvent(selected ? 'suburb' : 'unsuburb');
    });
    // …starts from the bare map (a replay may begin over an open sheet)…
    let seenRun = 0;
    $effect(() => {
        if ($tourRun === seenRun) return;
        seenRun = $tourRun;
        planning = false;
        selected = null;
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

    // On load: learn the session, and surface any ?signin=… feedback from a redeem /
    // OAuth redirect, then strip the query so a reload doesn't replay it (§7.1 calm).
    onMount(() => {
        refreshSession();
        const flag = signinFlag(window.location.search);
        if (flag) {
            banner = flag;
            history.replaceState(null, '', window.location.pathname);
            // "You're signed in" is a confirmation, not a task: it clears itself so it
            // never sits over a sheet. A failure flag stays until dismissed.
            if (flag === 'ok') setTimeout(() => banner === 'ok' && (banner = null), 4000);
        }
        getAllNews().then((news) => (homeNews = news));
    });

    // Ticker tap opens that specific note's detail directly (2026-08-06, Son) — the list
    // stays reachable as the fallback closing a ticker-opened note lands on
    // (onHomeNewsClose, unchanged), it's just no longer the ticker's own first stop.
    function onHomeTickerTap(note: NewsNote) {
        selectedHomeNews = note;
    }
    function onHomeNewsListClose() {
        homeNewsListOpen = false;
    }
    function onHomeNewsListSelect(note: NewsNote) {
        homeNewsListOpen = false;
        selectedHomeNews = note;
    }
    // Closing the detail sheet (✕/backdrop/Escape) returns to the list it was opened
    // from, or to the list when the note came straight from the ticker
    // (onHomeTickerTap above opens the detail without the list, so "back" lands on a list
    // the buyer never saw — the fallback Son chose 2026-08-06). Previously this fully
    // closed, so re-opening a different note required tapping the ticker again.
    function onHomeNewsClose() {
        selectedHomeNews = null;
        homeNewsListOpen = true;
    }

    async function load(st: MapScope) {
        loading = true;
        errored = false;
        selected = null;
        loadedScope = null;
        try {
            const res = await getSuburbs(st);
            suburbs = res.suburbs;
            attribution = res.attribution;
            loadedScope = st;
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

    // Once signed in, take any onboarding the user left for the sign-in (read once, so a
    // reload never reopens it) and switch to the scope they were on…
    $effect(() => {
        if (!$session || pendingTaken) return;
        pendingTaken = true;
        const p = takePending();
        if (p && (MAP_SCOPES as string[]).includes(p.scope)) {
            pendingRestore = p;
            auState = p.scope as MapScope;
        }
    });
    // …then, when that scope's suburbs are in, reopen the suburb and onboarding prefilled.
    $effect(() => {
        const p = pendingRestore;
        if (!p || loading || loadedScope !== p.scope) return;
        pendingRestore = null;
        const s = suburbs.find((x) => x.sal_code === p.sal);
        if (!s) return;
        pickSuburb(s);
        if (!p.answers) {
            // A guest who signed in from their plan: back to that suburb's Plan tab, where
            // the claimed plan now sits (SuburbSheet switches tab on a reloadPlan change
            // after it has mounted, hence the tick).
            void tick().then(() => planReload++);
            return;
        }
        restoreAnswers = p.answers;
        planning = true;
    });
    // Behavior 45: a guest opening sign-in with a suburb's sheet open (the plan notice,
    // the Q&A reason, or the header) comes back to that suburb after the round-trip.
    // The onboarding's own sign-in (the daily cap) saves its answers instead.
    $effect(() => {
        if ($loginOpen && $guest && selected && !planning)
            savePending({ sal: selected.sal_code, scope: auState, ts: Date.now() });
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
            bind:basemap={basemapOn}
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
    {#if $sessionExpired && !$guest}
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
            data-tour="controls"
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
                     a saved plan (bright pulse); the combobox narrows further by name. The
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
                    {#if savedOnly && savedTitles.size === 0}
                        <p class="filter-hint">{$t('filter.saved.empty')}</p>
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

    {#if loading}
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
                reloadPlan={planReload}
                onclose={() => (selected = null)}
                onplan={() => {
                    restoreAnswers = undefined;
                    planning = true;
                    tourEvent('onboarding');
                }}
            />
        {/key}
    {/if}

    {#if planning && selected}
        <Onboarding
            stateCode={auState}
            suburbName={selected.name}
            suburbSal={selected.sal_code}
            initial={restoreAnswers}
            oncreated={() => {
                planning = false;
                planReload++;
                // A signed-out create made this browser a guest (behavior 45): re-read
                // /api/me so the plan shows the 7-day notice.
                void refreshSession();
            }}
            onclose={() => {
                planning = false;
                tourEvent('onboarding-closed');
            }}
            onsignin={(answers) => {
                endTour();
                if (selected)
                    savePending({
                        sal: selected.sal_code,
                        scope: auState,
                        answers,
                        ts: Date.now()
                    });
                planning = false;
                loginOpen.set(true);
            }}
        />
    {/if}

    {#if $loginOpen}
        <Login onclose={() => loginOpen.set(false)} />
    {/if}

    {#if homeNewsListOpen}
        <NewsListSheet
            news={homeNews}
            active={homeNewsActiveCategory}
            onSelectCategory={(id) => (homeNewsActiveCategory = id)}
            onSelectNote={onHomeNewsListSelect}
            onClose={onHomeNewsListClose}
        />
    {/if}

    {#if selectedHomeNews}
        <NewsDetailSheet note={selectedHomeNews} onClose={onHomeNewsClose} />
    {/if}

    <!-- First visit: the case for Australian property, then a launcher to reopen it (behavior 42). -->
    <Welcome />
    <Tour ontry={tryTourSuburb} />
</div>
