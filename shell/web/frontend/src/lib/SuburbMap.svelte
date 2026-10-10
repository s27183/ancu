<script lang="ts">
    // The suburb-intelligence map (8-S2): MapLibre GL JS via MIERUNE svelte-maplibre-gl
    // (map-stack.md). The centroid CircleLayer — the Vietnamese-community-proximity layer
    // (the killer layer) — sits over the basemap. Click a bubble → onselect(suburb); the
    // parent owns the selection + the sheet.
    //
    // Basemap (8-S2d): VITE_PMTILES_URL set → a Protomaps pmtiles basemap; unset → the
    // no-basemap minimalStyle (the original 8-S2 behaviour — dev/build never regresses).
    // Dev/eval points at a Protomaps daily build; prod at the owned R2 planet
    // (https://tiles.maiancu.com/planet.pmtiles, behavior 40).
    // A daily-build URL carries its date and was seen to 404 within about 4 weeks
    // (memory, mid-2026; unmeasured since): a dev map with no basemap is first a stale
    // VITE_PMTILES_URL, and the fallback below then renders minimalStyle.
    //
    // Runtime basemap-error fallback (2026-07-09): svelte-maplibre-gl gates EVERY
    // source/layer — including our own suburb-bubbles GeoJSON, unrelated to the basemap
    // — on the base style reaching MapLibre's internal `loaded()` state (contexts.svelte.js
    // waitForStyleLoaded). If the Protomaps vector source can't load for ANY reason (a
    // transient CORS/edge-cache glitch on the public daily build, an ad blocker, a flaky
    // network, a corp proxy stripping Range headers — this is not incognito-specific and
    // can hit the owned R2 extract in prod too), `loaded()` never becomes true and NOTHING
    // renders, not just the basemap. Catch the map's 'error' event for that source and
    // drop to `minimalStyle` — already this codebase's first-class, zero-network-dependency
    // rendering (used whenever VITE_PMTILES_URL is unset), not a degraded error state.
    import 'maplibre-gl/dist/maplibre-gl.css'; // self-hosted, not the CDN autoload
    import { MapLibre, GeoJSONSource, CircleLayer, HeatmapLayer } from 'svelte-maplibre-gl';
    import type {
        MapLayerMouseEvent,
        Map as MlMap,
        CircleLayerSpecification,
        MapLibreEvent,
        ErrorEvent as MlErrorEvent,
        GeoJSONSource as MlGeoJSONSource
    } from 'maplibre-gl';
    import type { FeatureCollection, Point } from 'geojson';
    import type { Suburb } from '$lib/api';
    import {
        toFeatureCollection,
        circlePaintFor,
        heatmapPaintFor,
        clusterPaintFor,
        clusterPropertiesFor,
        CLUSTER_RADIUS_PX,
        CLUSTER_MAX_ZOOM,
        minimalStyle,
        basemapStyle,
        firstLabelLayerId,
        BASEMAP_SOURCE_ID,
        DEFAULT_SIZE_BY,
        PULSE,
        PULSE_RIM,
        PULSE_RECENT,
        type SizeBy
    } from '$lib/map';
    import { ensurePmtilesProtocol } from '$lib/pmtiles';

    // Build-time: Vite statically replaces this; unset → undefined → no-basemap fallback.
    const PMTILES_URL = import.meta.env.VITE_PMTILES_URL;
    if (PMTILES_URL) ensurePmtilesProtocol();
    // Flips once, permanently, on a basemap source error — never flips back (a retry
    // would re-trigger the same failure class for a still-broken network/CDN state).
    let basemapFailed = $state(false);
    const usingBasemap = $derived(!!PMTILES_URL && !basemapFailed);
    $effect(() => {
        basemap = usingBasemap;
    });
    const mapStyle = $derived(usingBasemap ? basemapStyle(PMTILES_URL) : minimalStyle);
    // Insert the data BELOW the basemap's labels so place names stay on top of the dots
    // (undefined with no basemap → data on top, which is fine: there are no labels).
    const labelBeforeId = $derived(usingBasemap ? firstLabelLayerId() : undefined);

    // Only BEFORE the map's first `load`: that is the gate the fallback exists for. After
    // it, swapping the whole style to minimalStyle would drop the suburb sources and
    // layers with it (seen in prod, behavior 40, 2026-10-09: tiles blocked mid-session →
    // an empty grey map); a tile that fails then just stays a gap and the suburbs keep
    // drawing.
    let mapLoaded = false;
    function onMapError(e: MapLibreEvent<MlErrorEvent> & { sourceId?: string }) {
        if (!mapLoaded && e.sourceId === BASEMAP_SOURCE_ID) basemapFailed = true;
    }

    let {
        suburbs,
        center,
        zoom,
        sizeBy = DEFAULT_SIZE_BY,
        pulseSaved = false,
        selected = null,
        recent = null,
        onselect,
        onzoom,
        basemap = $bindable(false)
    }: {
        suburbs: Suburb[];
        center: [number, number];
        zoom: number;
        sizeBy?: SizeBy;
        /** Saved-plans mode: render the (few) suburbs as a uniform bright pulse instead
         *  of the criterion ramp — they're already filtered to the saved set upstream. */
        pulseSaved?: boolean;
        /** The currently-selected suburb — gets a prominent pulse wherever it is (saved
         *  or not), so the click/combobox target is unmistakable on the map. */
        selected?: Suburb | null;
        /** The suburb whose sheet was just closed (behavior 54) — a jade pulse, so the
         *  visitor can find where they just were. Null while a sheet is open. */
        recent?: Suburb | null;
        onselect: (s: Suburb | null) => void;
        /** Reports the live map zoom up to the parent (drives the overview hint). */
        onzoom?: (z: number) => void;
        /** Out: whether the Protomaps basemap is drawn — its credit then belongs in the
         *  page's one "i" credit popup (behavior 43), not a MapLibre control. */
        basemap?: boolean;
    } = $props();

    /** Fly to a suburb (the name combobox picks one). Zooms in enough to resolve it. */
    export function flyTo(lon: number, lat: number) {
        map?.flyTo({ center: [lon, lat], zoom: Math.max(map.getZoom(), 11) });
    }

    // Track the live zoom via the map instance (separate from the initial `zoom` prop,
    // which still drives recentre-on-state-change). Reported up for the overview hint.
    let map = $state<MlMap>();
    $effect(() => {
        if (!map) return;
        const m = map;
        const report = () => onzoom?.(m.getZoom());
        m.on('zoom', report);
        report();
        return () => m.off('zoom', report);
    });

    const data = $derived(toFeatureCollection(suburbs));
    const index = $derived(new Map(suburbs.map((s) => [s.sal_code, s])));
    // Colour + radius both follow the selected criterion; recomputed when it changes.
    const paint = $derived(circlePaintFor(sizeBy));
    // Below the measured handoff (~z7–9) the points overplot, so a KDE heatmap (weight
    // + colour adapting to the criterion) shows the distribution; it cross-fades to the
    // dots as you zoom in. See the measurement note in lib/map.ts.
    const heatPaint = $derived(heatmapPaintFor(sizeBy));
    // INTENSIVE criteria (no heatPaint — a rate/decile can't honestly density-sum) get a
    // cluster-average overview instead: bubble colour = average, size = suburb count.
    const clusterPaint = $derived(clusterPaintFor(sizeBy));
    const clusterProps = $derived(clusterPropertiesFor(sizeBy));

    // --- Pulse highlight -----------------------------------------------------
    // ONE bright pulse signal — a solid centre dot + an expanding ring animated by rAF
    // — shared by (a) the saved suburbs in saved-only mode, (b) the SELECTED suburb
    // (saved or not) and, in jade, (c) the suburb just closed (behavior 54). The ring is JS-driven (MapLibre paint can't read time), so we
    // re-derive its paint each frame — fine for a handful of points. prefers-reduced-
    // motion → a static mid-expansion ring (no animation).

    // A suburb as a 0/1-feature source for its own (always-on) pulse.
    function onePoint(s: Suburb | null): FeatureCollection<Point> {
        return {
            type: 'FeatureCollection',
            features: s?.centroid
                ? [
                      {
                          type: 'Feature' as const,
                          geometry: {
                              type: 'Point' as const,
                              coordinates: [s.centroid.lon, s.centroid.lat]
                          },
                          properties: {}
                      }
                  ]
                : []
        };
    }
    const selectedData = $derived(onePoint(selected));
    const hasSelectedPoint = $derived(!!selected?.centroid);
    // The just-closed suburb (behavior 54): same shape, jade instead of magenta.
    const recentData = $derived(onePoint(recent));
    const hasRecentPoint = $derived(!!recent?.centroid);

    let pulse = $state(0); // 0→1→0 eased ring progress
    $effect(() => {
        if (!pulseSaved && !hasSelectedPoint && !hasRecentPoint) return;
        const reduce =
            typeof matchMedia === 'function' &&
            matchMedia('(prefers-reduced-motion: reduce)').matches;
        if (reduce) {
            pulse = 0.5;
            return;
        }
        let raf = 0;
        let start: number | null = null;
        const tick = (ts: number) => {
            if (start === null) start = ts;
            const phase = (((ts - start) / 1500) % 1) * 2 * Math.PI; // 1.5s period
            pulse = 0.5 - 0.5 * Math.cos(phase); // smooth 0→1→0
            raf = requestAnimationFrame(tick);
        };
        raf = requestAnimationFrame(tick);
        return () => cancelAnimationFrame(raf);
    });

    // The solid centre dot (always visible at any zoom — the pulse must read at the
    // continental overview, where the criterion dots are fully faded out). Big + bold.
    const dotPaint = {
        'circle-color': PULSE,
        'circle-opacity': 0.95,
        'circle-radius': 7,
        'circle-stroke-color': PULSE_RIM,
        'circle-stroke-width': 2
    } satisfies CircleLayerSpecification['paint'];
    // The expanding ring — radius grows, stroke fades, as `pulse` runs 0→1.
    const ringPaint = $derived({
        'circle-color': PULSE,
        'circle-opacity': 0,
        'circle-radius': 7 + pulse * 26,
        'circle-stroke-color': PULSE,
        'circle-stroke-width': 3,
        'circle-stroke-opacity': 0.85 * (1 - pulse)
    } satisfies CircleLayerSpecification['paint']);

    const recentDotPaint = {
        ...dotPaint,
        'circle-color': PULSE_RECENT
    } satisfies CircleLayerSpecification['paint'];
    const recentRingPaint = $derived({
        ...ringPaint,
        'circle-stroke-color': PULSE_RECENT
    } satisfies CircleLayerSpecification['paint']);

    function handleClick(ev: MapLayerMouseEvent) {
        const sal = ev.features?.[0]?.properties?.sal_code as string | undefined;
        onselect(sal ? (index.get(sal) ?? null) : null);
    }
    // Cluster bubbles have no sal_code (they're an aggregate, not one suburb) — click
    // zooms into the cluster instead of selecting. Leaf points (unclustered — a lone
    // suburb far from any other) fall through to the normal select behaviour.
    async function handleClusterClick(ev: MapLayerMouseEvent) {
        const f = ev.features?.[0];
        if (!f?.properties?.cluster) {
            handleClick(ev);
            return;
        }
        const src = map?.getSource<MlGeoJSONSource>('suburbs-cluster');
        if (!src || f.properties.cluster_id == null) return;
        const expandZoom = await src.getClusterExpansionZoom(f.properties.cluster_id as number);
        const [lon, lat] = (f.geometry as Point).coordinates;
        map?.easeTo({ center: [lon, lat], zoom: expandZoom });
    }
    function setPointer(ev: MapLayerMouseEvent, on: boolean) {
        ev.target.getCanvas().style.cursor = on ? 'pointer' : '';
    }
</script>

<MapLibre
    bind:map
    style={mapStyle}
    {center}
    {zoom}
    attributionControl={false}
    autoloadGlobalCss={false}
    inlineStyle="position:absolute;inset:0"
    onerror={onMapError}
    onload={() => (mapLoaded = true)}
>
    {#if pulseSaved}
        <!-- Saved-plans mode: an expanding ring (declared first → below the dot) and
             a solid bright centre dot. Uniform bright highlight, no criterion ramp. -->
        <GeoJSONSource id="suburbs" {data}>
            <CircleLayer id="suburb-pulse" paint={ringPaint} beforeId={labelBeforeId} />
            <CircleLayer
                id="suburb-saved"
                paint={dotPaint}
                beforeId={labelBeforeId}
                onclick={handleClick}
                onmouseenter={(e: MapLayerMouseEvent) => setPointer(e, true)}
                onmouseleave={(e: MapLayerMouseEvent) => setPointer(e, false)}
            />
        </GeoJSONSource>
    {:else if heatPaint}
        <!-- EXTENSIVE criteria (population/vietnamese): a KDE density heatmap honestly
             represents the overplotted overview, cross-fading to individual dots as
             you zoom in. See the measurement note in lib/map.ts. -->
        <GeoJSONSource id="suburbs" {data}>
            <HeatmapLayer id="suburb-heat" paint={heatPaint} beforeId={labelBeforeId} />
            <CircleLayer
                id="suburb-bubbles"
                {paint}
                beforeId={labelBeforeId}
                onclick={handleClick}
                onmouseenter={(e: MapLayerMouseEvent) => setPointer(e, true)}
                onmouseleave={(e: MapLayerMouseEvent) => setPointer(e, false)}
            />
        </GeoJSONSource>
    {:else}
        <!-- INTENSIVE criteria (SEIFA/crime): a density-sum heatmap would be dishonest
             for a rate, so the overview is a cluster-AVERAGE proportional-symbol map
             instead (bubble colour = average, size = suburb count) — cross-fading to
             the same individual dots at the same handoff. See lib/map.ts. -->
        <GeoJSONSource
            id="suburbs-cluster"
            data={data}
            cluster={true}
            clusterRadius={CLUSTER_RADIUS_PX}
            clusterMaxZoom={CLUSTER_MAX_ZOOM}
            clusterProperties={clusterProps}
        >
            <CircleLayer
                id="suburb-cluster-bubbles"
                paint={clusterPaint}
                filter={['has', 'point_count']}
                beforeId={labelBeforeId}
                onclick={handleClusterClick}
                onmouseenter={(e: MapLayerMouseEvent) => setPointer(e, true)}
                onmouseleave={(e: MapLayerMouseEvent) => setPointer(e, false)}
            />
            <CircleLayer
                id="suburb-cluster-leaves"
                {paint}
                filter={['!', ['has', 'point_count']]}
                beforeId={labelBeforeId}
                onclick={handleClick}
                onmouseenter={(e: MapLayerMouseEvent) => setPointer(e, true)}
                onmouseleave={(e: MapLayerMouseEvent) => setPointer(e, false)}
            />
        </GeoJSONSource>
    {/if}

    <!-- The selected suburb's own pulse — always on (saved or not), sitting on its own
         single-feature source so it shows over any base layer. No click handler: the
         dot underneath still handles re-selection. -->
    <!-- The just-closed suburb's jade pulse (behavior 54), under the selected one. Both
         remount whenever the base block above does (saved filter, criterion): a layer
         added later goes on top, so without the key a saved suburb's magenta dot hid the
         green one (measured 2026-10-10, Cabramatta saved and just closed). -->
    {#key `${pulseSaved}:${sizeBy}`}
    {#if hasRecentPoint}
        <GeoJSONSource id="suburb-recent" data={recentData}>
            <CircleLayer id="recent-pulse" paint={recentRingPaint} beforeId={labelBeforeId} />
            <CircleLayer id="recent-dot" paint={recentDotPaint} beforeId={labelBeforeId} />
        </GeoJSONSource>
    {/if}
    {#if hasSelectedPoint}
        <GeoJSONSource id="suburb-selected" data={selectedData}>
            <CircleLayer id="sel-pulse" paint={ringPaint} beforeId={labelBeforeId} />
            <CircleLayer id="sel-dot" paint={dotPaint} beforeId={labelBeforeId} />
        </GeoJSONSource>
    {/if}
    {/key}
</MapLibre>
