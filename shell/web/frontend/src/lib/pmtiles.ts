// Register the `pmtiles://` protocol with MapLibre once per app lifecycle (8-S2d).
// Kept OUT of the pure lib/map.ts (which only builds plain style objects, so it stays
// unit-testable): this touches the maplibregl global and is a browser-only side effect.
// The Protomaps basemap source is a single `.pmtiles` archive addressed via a
// `pmtiles://` URL; MapLibre needs this protocol handler to HTTP-range-read tiles out
// of it. addProtocol "works best called once in the application lifecycle" (pmtiles
// docs), so the call is idempotent. The maplibre-gl singleton here is the same instance
// svelte-maplibre-gl uses (one version in node_modules).
import maplibregl from 'maplibre-gl';
import { Protocol } from 'pmtiles';

let registered = false;

export function ensurePmtilesProtocol(): void {
    if (registered) return;
    const protocol = new Protocol();
    maplibregl.addProtocol('pmtiles', protocol.tile);
    registered = true;
}
