// Pure map helpers (no Svelte, no DOM) for the suburb-intelligence home (8-S2):
// the GeoJSON projection of the engine's suburb rows, the data-driven CircleLayer
// paint (the Vietnamese-community-proximity layer — the killer layer), the minimal
// no-basemap style (v1; the real Protomaps basemap is a follow-on, map-stack.md §5),
// and the per-state default view. Kept framework-free so it is unit-testable.
import type {
    CircleLayerSpecification,
    StyleSpecification,
    ExpressionSpecification
} from 'maplibre-gl';
import type { FeatureCollection, Point } from 'geojson';
import type { Suburb } from '$lib/api';

/** The engine's CHECK-constrained state enum (003_suburbs.sql) — the map's query grain. */
export const AU_STATES = ['NSW', 'VIC', 'QLD', 'WA', 'SA', 'TAS', 'ACT', 'NT'] as const;
export type AuState = (typeof AU_STATES)[number];

export const DEFAULT_STATE: AuState = 'NSW'; // largest Vietnamese-AU population (Cabramatta)

/** Where the map opens per state — centred on the capital/metro where the Vietnamese
 *  community clusters. [lon, lat] (MapLibre order) + an initial zoom. */
export const STATE_VIEW: Record<AuState, { center: [number, number]; zoom: number }> = {
    NSW: { center: [150.95, -33.87], zoom: 9 }, // SW Sydney — Cabramatta / Fairfield
    VIC: { center: [144.95, -37.81], zoom: 9 }, // Footscray / Richmond / Springvale
    QLD: { center: [153.03, -27.47], zoom: 9 }, // Brisbane — Inala / Darra
    WA: { center: [115.86, -31.95], zoom: 9 },
    SA: { center: [138.6, -34.93], zoom: 9 },
    TAS: { center: [147.33, -42.88], zoom: 9 },
    ACT: { center: [149.13, -35.28], zoom: 10 },
    NT: { center: [130.84, -12.46], zoom: 9 }
};

/** GeoJSON id property carried into MapLibre features (used for the click lookup). */
export interface SuburbFeatureProps {
    sal_code: string;
    name: string;
    /** Only set when the feed has it — so `['has','vp']` cleanly separates "no data". */
    vp?: number;
    [k: string]: unknown;
}

/** Project the engine's suburb rows to a Point FeatureCollection. Rows without a
 *  centroid (the non-geographic pseudo-localities) have no map point and are dropped
 *  — an absent location is absent, not a zero point. */
export function toFeatureCollection(suburbs: Suburb[]): FeatureCollection<Point, SuburbFeatureProps> {
    const features = [];
    for (const s of suburbs) {
        if (!s.centroid) continue;
        const props: SuburbFeatureProps = { sal_code: s.sal_code, name: s.name };
        if (typeof s.facts.vietnamese_ancestry_pct === 'number') {
            props.vp = s.facts.vietnamese_ancestry_pct;
        }
        features.push({
            type: 'Feature' as const,
            geometry: { type: 'Point' as const, coordinates: [s.centroid.lon, s.centroid.lat] },
            properties: props
        });
    }
    return { type: 'FeatureCollection', features };
}

// Sequential warm scale for Vietnamese ancestry %: a calm cream at 0 → an affirmative
// deep coral at the top of the observed range (~38%, Cabramatta). Warm = "more
// community here", which reads as positive (and is culturally affirmative), never
// alarming (shell-architecture.md §7.1). Suburbs with no Census ancestry datum get a
// muted neutral dot — present on the map, visibly "no data", not coloured as zero.
const NO_DATA = '#cbd5e1'; // slate-300
const vp: ExpressionSpecification = ['get', 'vp'];

const colorByVp: ExpressionSpecification = [
    'case',
    ['has', 'vp'],
    [
        'interpolate',
        ['linear'],
        vp,
        0, '#fdf4e3',
        5, '#fcd9a6',
        15, '#f4a261',
        25, '#e76f51',
        40, '#b5341f'
    ],
    NO_DATA
];

// Radius grows with both the metric and the zoom, so high-Vietnamese suburbs pop at
// the opening zoom yet the layer stays legible as you zoom out.
const radiusByVp: ExpressionSpecification = [
    'interpolate',
    ['linear'],
    ['zoom'],
    7, ['case', ['has', 'vp'], ['interpolate', ['linear'], vp, 0, 3, 40, 11], 2.5],
    12, ['case', ['has', 'vp'], ['interpolate', ['linear'], vp, 0, 5, 40, 22], 4]
];

export const circlePaint: CircleLayerSpecification['paint'] = {
    'circle-color': colorByVp,
    'circle-radius': radiusByVp,
    'circle-opacity': 0.82,
    'circle-stroke-width': 1,
    'circle-stroke-color': '#ffffff',
    'circle-stroke-opacity': 0.7
};

/** v1 has no external basemap (Protomaps-on-R2 is a follow-on, map-stack.md §5). A
 *  minimal background-only style: the centroid bubbles sit at real lat/lon, so the
 *  Sydney/Melbourne Vietnamese clusters read as shape without a basemap. Zero network
 *  tile dependency — proven entirely in the dev/svelte-check loop. */
export const minimalStyle: StyleSpecification = {
    version: 8,
    sources: {},
    layers: [{ id: 'bg', type: 'background', paint: { 'background-color': '#eef2f6' } }]
};
