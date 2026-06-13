<script lang="ts">
    // The suburb-intelligence map (8-S2): MapLibre GL JS via MIERUNE svelte-maplibre-gl
    // (map-stack.md). v1 = a centroid CircleLayer — the Vietnamese-community-proximity
    // layer (the killer layer) — over a minimal no-basemap style. Click a bubble →
    // onselect(suburb); the parent owns the selection + the sheet.
    import 'maplibre-gl/dist/maplibre-gl.css'; // self-hosted, not the CDN autoload
    import { MapLibre, GeoJSONSource, CircleLayer } from 'svelte-maplibre-gl';
    import type { MapLayerMouseEvent } from 'maplibre-gl';
    import type { Suburb } from '$lib/api';
    import { toFeatureCollection, circlePaint, minimalStyle } from '$lib/map';

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
    style={minimalStyle}
    {center}
    {zoom}
    attributionControl={false}
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
