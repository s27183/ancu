<script lang="ts">
    // The suburb-intelligence map (8-S2): MapLibre GL JS via MIERUNE svelte-maplibre-gl
    // (map-stack.md). The centroid CircleLayer — the Vietnamese-community-proximity layer
    // (the killer layer) — sits over the basemap. Click a bubble → onselect(suburb); the
    // parent owns the selection + the sheet.
    //
    // Basemap (8-S2d): VITE_PMTILES_URL set → a Protomaps pmtiles basemap; unset → the
    // no-basemap minimalStyle (the original 8-S2 behaviour — dev/build never regresses).
    // Dev/eval points at a Protomaps daily build; prod at the owned R2 AU extract.
    import 'maplibre-gl/dist/maplibre-gl.css'; // self-hosted, not the CDN autoload
    import { MapLibre, GeoJSONSource, CircleLayer, HeatmapLayer } from 'svelte-maplibre-gl';
    import type { MapLayerMouseEvent, Map as MlMap } from 'maplibre-gl';
    import type { Suburb } from '$lib/api';
    import {
        toFeatureCollection,
        circlePaintFor,
        heatmapPaintFor,
        minimalStyle,
        basemapStyle,
        firstLabelLayerId,
        DEFAULT_SIZE_BY,
        type SizeBy
    } from '$lib/map';
    import { ensurePmtilesProtocol } from '$lib/pmtiles';

    // Build-time: Vite statically replaces this; unset → undefined → no-basemap fallback.
    const PMTILES_URL = import.meta.env.VITE_PMTILES_URL;
    if (PMTILES_URL) ensurePmtilesProtocol();
    const mapStyle = PMTILES_URL ? basemapStyle(PMTILES_URL) : minimalStyle;
    // Insert the data BELOW the basemap's labels so place names stay on top of the dots
    // (undefined with no basemap → data on top, which is fine: there are no labels).
    const labelBeforeId = PMTILES_URL ? firstLabelLayerId() : undefined;

    let {
        suburbs,
        center,
        zoom,
        sizeBy = DEFAULT_SIZE_BY,
        onselect,
        onzoom
    }: {
        suburbs: Suburb[];
        center: [number, number];
        zoom: number;
        sizeBy?: SizeBy;
        onselect: (s: Suburb | null) => void;
        /** Reports the live map zoom up to the parent (drives the overview hint). */
        onzoom?: (z: number) => void;
    } = $props();

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

    function handleClick(ev: MapLayerMouseEvent) {
        const sal = ev.features?.[0]?.properties?.sal_code as string | undefined;
        onselect(sal ? (index.get(sal) ?? null) : null);
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
    attributionControl={PMTILES_URL ? { compact: true } : false}
    autoloadGlobalCss={false}
    inlineStyle="position:absolute;inset:0"
>
    <GeoJSONSource id="suburbs" {data}>
        <!-- KDE heatmap for the overplotted overview; sits below the dots. Only for
             extensive criteria — null (omitted) for intensive ones (SEIFA/crime). -->
        {#if heatPaint}
            <HeatmapLayer id="suburb-heat" paint={heatPaint} beforeId={labelBeforeId} />
        {/if}
        <CircleLayer
            id="suburb-bubbles"
            {paint}
            beforeId={labelBeforeId}
            onclick={handleClick}
            onmouseenter={(e: MapLayerMouseEvent) => setPointer(e, true)}
            onmouseleave={(e: MapLayerMouseEvent) => setPointer(e, false)}
        />
    </GeoJSONSource>
</MapLibre>
