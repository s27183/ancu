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
    import { MapLibre, GeoJSONSource, CircleLayer } from 'svelte-maplibre-gl';
    import type { MapLayerMouseEvent } from 'maplibre-gl';
    import type { Suburb } from '$lib/api';
    import { toFeatureCollection, circlePaint, minimalStyle, basemapStyle } from '$lib/map';
    import { ensurePmtilesProtocol } from '$lib/pmtiles';

    // Build-time: Vite statically replaces this; unset → undefined → no-basemap fallback.
    const PMTILES_URL = import.meta.env.VITE_PMTILES_URL;
    if (PMTILES_URL) ensurePmtilesProtocol();
    const mapStyle = PMTILES_URL ? basemapStyle(PMTILES_URL) : minimalStyle;

    let {
        suburbs,
        center,
        zoom,
        onselect
    }: {
        suburbs: Suburb[];
        center: [number, number];
        zoom: number;
        onselect: (s: Suburb | null) => void;
    } = $props();

    const data = $derived(toFeatureCollection(suburbs));
    const index = $derived(new Map(suburbs.map((s) => [s.sal_code, s])));

    function handleClick(ev: MapLayerMouseEvent) {
        const sal = ev.features?.[0]?.properties?.sal_code as string | undefined;
        onselect(sal ? (index.get(sal) ?? null) : null);
    }
    function setPointer(ev: MapLayerMouseEvent, on: boolean) {
        ev.target.getCanvas().style.cursor = on ? 'pointer' : '';
    }
</script>

<MapLibre
    style={mapStyle}
    {center}
    {zoom}
    attributionControl={PMTILES_URL ? { compact: true } : false}
    autoloadGlobalCss={false}
    inlineStyle="position:absolute;inset:0"
>
    <GeoJSONSource id="suburbs" {data}>
        <CircleLayer
            id="suburb-bubbles"
            paint={circlePaint}
            onclick={handleClick}
            onmouseenter={(e: MapLayerMouseEvent) => setPointer(e, true)}
            onmouseleave={(e: MapLayerMouseEvent) => setPointer(e, false)}
        />
    </GeoJSONSource>
</MapLibre>
