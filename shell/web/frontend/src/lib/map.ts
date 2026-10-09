// Pure map helpers (no Svelte, no DOM) for the suburb-intelligence home (8-S2):
// the GeoJSON projection of the engine's suburb rows, the data-driven CircleLayer
// paint (the Vietnamese-community-proximity layer — the killer layer), the minimal
// no-basemap style + the Protomaps basemap style (8-S2d, map-stack.md §2), and the
// per-state default view. Kept framework-free so it is unit-testable — the basemap
// builder just returns a plain style object; the `pmtiles://` protocol registration
// (a browser side effect) lives separately in lib/pmtiles.ts.
import type {
    CircleLayerSpecification,
    HeatmapLayerSpecification,
    StyleSpecification,
    ExpressionSpecification
} from 'maplibre-gl';
import type { FeatureCollection, Point } from 'geojson';
import { layers, namedFlavor, type Flavor } from '@protomaps/basemaps';
import type { Suburb } from '$lib/api';

/** The engine's CHECK-constrained state enum (003_suburbs.sql) — the map's query grain. */
export const AU_STATES = ['NSW', 'VIC', 'QLD', 'WA', 'SA', 'TAS', 'ACT', 'NT'] as const;
export type AuState = (typeof AU_STATES)[number];

/** The map's selectable scopes: a single state, or ALL (every state at once — the
 *  engine serves it via `?state=ALL`). ALL leads so it's the first option. */
export type MapScope = AuState | 'ALL';
export const MAP_SCOPES: MapScope[] = ['ALL', ...AU_STATES];

export const DEFAULT_STATE: MapScope = 'ALL'; // open on the whole continent

/** Full English state names — the selector shows "New South Wales (NSW)". Always
 *  English (proper place names), never routed through the chrome i18n. */
export const STATE_NAMES: Record<AuState, string> = {
    NSW: 'New South Wales',
    VIC: 'Victoria',
    QLD: 'Queensland',
    WA: 'Western Australia',
    SA: 'South Australia',
    TAS: 'Tasmania',
    ACT: 'Australian Capital Territory',
    NT: 'Northern Territory'
};

/** Where the map opens per scope — a state centres on the metro where the Vietnamese
 *  community clusters; ALL frames the whole continent. [lon, lat] (MapLibre order) + zoom. */
export const STATE_VIEW: Record<MapScope, { center: [number, number]; zoom: number }> = {
    ALL: { center: [134.0, -28.2], zoom: 3.4 }, // continental Australia
    NSW: { center: [150.95, -33.87], zoom: 9 }, // SW Sydney — Cabramatta / Fairfield
    VIC: { center: [144.95, -37.81], zoom: 9 }, // Footscray / Richmond / Springvale
    QLD: { center: [153.03, -27.47], zoom: 9 }, // Brisbane — Inala / Darra
    WA: { center: [115.86, -31.95], zoom: 9 },
    SA: { center: [138.6, -34.93], zoom: 9 },
    TAS: { center: [147.33, -42.88], zoom: 9 },
    ACT: { center: [149.13, -35.28], zoom: 10 },
    NT: { center: [130.84, -12.46], zoom: 9 }
};

/** GeoJSON properties carried into MapLibre features. Each metric is set only when
 *  the feed has it — so `['has', key]` cleanly separates "no data" from a real zero,
 *  per criterion. `sal_code` drives the click lookup. */
export interface SuburbFeatureProps {
    sal_code: string;
    name: string;
    vp?: number; // Vietnamese ancestry %  (the per-suburb dot value)
    vc?: number; // Vietnamese COUNT (= pct/100 × persons) — the heatmap weight
    se?: number; // SEIFA IRSAD decile (the economic index)
    pop?: number; // census total persons
    cr?: number; // crime incidents per 1,000
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
        const f = s.facts;
        if (typeof f.vietnamese_ancestry_pct === 'number') props.vp = f.vietnamese_ancestry_pct;
        if (typeof f.seifa_irsad_decile === 'number') props.se = f.seifa_irsad_decile;
        if (typeof f.census_total_persons === 'number') props.pop = f.census_total_persons;
        if (typeof f.crime_incidents_per_1000 === 'number') props.cr = f.crime_incidents_per_1000;
        // Vietnamese COUNT — the EXTENSIVE quantity (a count, not the % rate) that a KDE
        // heatmap can honestly sum; the dot still shows the % (props.vp).
        if (typeof f.vietnamese_ancestry_pct === 'number' && typeof f.census_total_persons === 'number') {
            props.vc = (f.vietnamese_ancestry_pct / 100) * f.census_total_persons;
        }
        features.push({
            type: 'Feature' as const,
            geometry: { type: 'Point' as const, coordinates: [s.centroid.lon, s.centroid.lat] },
            properties: props
        });
    }
    return { type: 'FeatureCollection', features };
}

// --- The data-driven encoding ----------------------------------------------
// Both COLOUR and SIZE encode the SAME selected criterion (the user picks which via
// the size filter; the economic index is the default). Each criterion carries its
// own colour ramp + radius domain because the scales differ (a SEIFA decile is 1–10,
// a population is tens of thousands). Ramps are calm + sequential — "more of the
// metric" reads as a deeper tone, never alarm-red — and Vietnamese ancestry keeps its
// culturally-affirmative warm coral (shell-architecture.md §7.1). Crime stays a
// neutral grey ramp: a quantitative shade, never a valenced verdict
// (valuable-to-show-not-valid-to-decide).

export type SizeBy = 'seifa' | 'vietnamese' | 'population' | 'crime';
export const SIZE_CRITERIA: SizeBy[] = ['seifa', 'vietnamese', 'population', 'crime'];
export const DEFAULT_SIZE_BY: SizeBy = 'seifa'; // economic index

interface Criterion {
    /** the GeoJSON feature property carrying this metric (see SuburbFeatureProps). */
    field: 'se' | 'vp' | 'pop' | 'cr';
    /** [low, high] — the floor/ceiling for BOTH the colour interpolation and radius. */
    domain: [number, number];
    /** colour interpolate stops [metric value, hex]. */
    stops: [number, string][];
    /** legend endpoint display labels (numbers — not translated). */
    min: string;
    max: string;
    /** Overview heatmap config — present ONLY for EXTENSIVE (count-like) metrics, where
     *  a KDE density sum is honest. Absent for INTENSIVE metrics (a decile / a rate),
     *  where summing would just reproduce population density (then no overview heatmap;
     *  the dots reveal on zoom-in instead). `field` is the weight property (a count),
     *  which may differ from the dot `field` — e.g. community weights by count `vc`,
     *  not the % `vp`. */
    heat?: { field: 'vc' | 'pop'; domain: [number, number] };
}

// The map palette's one declaration (behavior 41): MapLibre paint takes literal colours,
// not CSS variables, so the ramps live here, beside the criteria they encode; the UI
// tokens live in app.css :root. seifa's ramp is the brand jade family (2026-10-09).
const CRITERIA: Record<SizeBy, Criterion> = {
    seifa: {
        field: 'se',
        domain: [1, 10],
        stops: [
            [1, '#cde6dd'],
            [4, '#8cc6b2'],
            [7, '#3d9a80'],
            [10, '#0b5a49']
        ],
        min: '1',
        max: '10'
    },
    vietnamese: {
        field: 'vp',
        domain: [0, 40],
        stops: [
            [0, '#fbe3c2'],
            [5, '#f7c98a'],
            [15, '#f0a04b'],
            [25, '#e36b46'],
            [40, '#b5341f']
        ],
        min: '0%',
        max: '40%+',
        heat: { field: 'vc', domain: [0, 8000] } // Vietnamese count (Cabramatta ≈ 8k)
    },
    population: {
        field: 'pop',
        domain: [0, 30000],
        stops: [
            [0, '#e4dff0'],
            [8000, '#b3a3d6'],
            [18000, '#7c64b0'],
            [30000, '#4a3490']
        ],
        min: '0',
        max: '30k+',
        heat: { field: 'pop', domain: [0, 30000] } // population IS a count → KDE is honest
    },
    crime: {
        field: 'cr',
        domain: [0, 150],
        // Pure achromatic greys (R=G=B) — deliberately zero hue, so this never reads as
        // "a duller jade" next to seifa's ramp. Distinct BY HUE FAMILY (chromatic jade
        // vs neutral grey), not just by saturation, so the two stay tellable apart at a
        // glance with only one on screen at a time. Still non-valenced (no shift toward
        // alarm-red) — see the comment on CRITERIA above.
        stops: [
            [0, '#b5b5b5'],
            [40, '#8f8f8f'],
            [90, '#666666'],
            [150, '#3a3a3a']
        ],
        min: '0',
        max: '150+'
    }
};

/** The saved/selected-suburb pulse: saturated magenta, distinct from every criterion
 *  ramp, with a white rim so the centre dot reads on any dot colour. */
export const PULSE = '#ff1f8f';
export const PULSE_RIM = '#ffffff';

const NO_DATA = '#d6d0c4'; // warm stone (app.css --border-strong family) — visibly "no data", not zero

function interpolateStops(c: Criterion, valueExpr: unknown): unknown[] {
    const interp: unknown[] = ['interpolate', ['linear'], valueExpr];
    for (const [v, col] of c.stops) interp.push(v, col);
    return interp;
}

function colorExpr(c: Criterion): ExpressionSpecification {
    const interp = interpolateStops(c, ['get', c.field]);
    return ['case', ['has', c.field], interp, NO_DATA] as unknown as ExpressionSpecification;
}

// Radius grows with both the metric and the zoom, but stays SMALL relative to the
// centroid spacing so the dots don't blanket the basemap labels at metro zoom (a
// high-value dot peaks ~13px across, not ~22px). Colour carries the metric; size is
// the secondary cue. No-data dots stay tiny + neutral.
function radiusExpr(c: Criterion): ExpressionSpecification {
    const f = ['get', c.field];
    const [lo, hi] = c.domain;
    return [
        'interpolate',
        ['linear'],
        ['zoom'],
        6, ['case', ['has', c.field], ['interpolate', ['linear'], f, lo, 1.5, hi, 4], 1.2],
        10, ['case', ['has', c.field], ['interpolate', ['linear'], f, lo, 2.5, hi, 6.5], 2.5],
        14, ['case', ['has', c.field], ['interpolate', ['linear'], f, lo, 3.5, hi, 8.5], 3.5]
    ] as unknown as ExpressionSpecification;
}

// --- Semantic zoom: heatmap below the handoff, individual dots above ----------
// MEASURED (engine `suburbs`, 15,329 centroids, 6px cell, MapLibre 512-tile world):
// 95th-pct points/cell = 29 @z3.4, 6 @z5, 3 @z6, 2 @z7, 1 @z8; overplotted share =
// 94% @z3.4 → 41% @z6 → 20% @z7 → 5% @z8 → 0.5% @z9. So individuals only become
// resolvable around z8–9. Below that we render a KERNEL-DENSITY HEATMAP (the only
// honest representation when marks ≫ pixels); we cross-fade to the dots over z7→z9.
const Z_FADE_LO = 7; // heatmap still dominant; dots start appearing
const Z_FADE_HI = 9; // dots fully resolvable; heatmap gone

// Dots gate IN across the handoff, then hold a clear, CONFIDENT fill — because the
// labels render on top of the data, the colour can be saturated enough to read (encode
// the metric) without hiding place names. A soft BORDERLESS colour disc, no hard edge.
// Slightly lower at the handoff (where dense inner-metro dots overlap) than at suburb
// zoom (where they're separated and the colour should be vivid).
const circleOpacityByZoom: ExpressionSpecification = [
    'interpolate',
    ['linear'],
    ['zoom'],
    Z_FADE_LO, 0,
    Z_FADE_HI, 0.42,
    12, 0.62,
    16, 0.55
] as unknown as ExpressionSpecification;

/** The CircleLayer paint for a chosen criterion — a soft borderless colour disc whose
 *  fill gates in at the handoff and lightens as you zoom (basemap + labels show
 *  through). Colour + size carry the metric; see the measurement note above. */
export function circlePaintFor(sizeBy: SizeBy): CircleLayerSpecification['paint'] {
    const c = CRITERIA[sizeBy];
    return {
        'circle-color': colorExpr(c),
        'circle-radius': radiusExpr(c),
        'circle-opacity': circleOpacityByZoom
    };
}

// Heatmap intensity/radius grow gently with zoom (screen px); opacity fades OUT across
// the handoff so the dots take over. All criterion-independent.
const heatIntensityByZoom: ExpressionSpecification = [
    'interpolate', ['linear'], ['zoom'], 3, 0.6, 6, 1, 8, 1.4
] as unknown as ExpressionSpecification;

const heatRadiusByZoom: ExpressionSpecification = [
    'interpolate', ['linear'], ['zoom'], 3, 7, 6, 16, 8, 28
] as unknown as ExpressionSpecification;

const heatOpacityByZoom: ExpressionSpecification = [
    'interpolate', ['linear'], ['zoom'], 6, 1, Z_FADE_LO, 0.8, Z_FADE_HI, 0
] as unknown as ExpressionSpecification;

// KDE weight: the criterion's COUNT property, normalised to [0,1] over its domain
// (no-data → 0, so blank suburbs don't contribute). Weighting by a count (not a rate)
// is what keeps the density sum honest and makes the criteria differ — community
// concentration (vc) vs total population (pop).
function heatWeightExpr(h: { field: string; domain: [number, number] }): ExpressionSpecification {
    const [lo, hi] = h.domain;
    return [
        'case',
        ['has', h.field],
        ['interpolate', ['linear'], ['get', h.field], lo, 0, hi, 1],
        0
    ] as unknown as ExpressionSpecification;
}

// The density ramp reuses the criterion's colour sequence (transparent at 0 so empty
// areas show the basemap), so the heatmap and the dots read as the same colour story.
function heatColorExpr(c: Criterion): ExpressionSpecification {
    const colors = c.stops.map(([, col]) => col);
    const n = colors.length;
    const expr: unknown[] = ['interpolate', ['linear'], ['heatmap-density'], 0, 'rgba(255,255,255,0)'];
    colors.forEach((col, i) => {
        const d = 0.1 + (0.9 * i) / (n - 1); // first colour at 0.1, last at 1.0
        expr.push(d, col);
    });
    return expr as unknown as ExpressionSpecification;
}

/** The HeatmapLayer paint for a chosen criterion — or `null` for an INTENSIVE metric
 *  (a decile / a rate), where a density heatmap would be dishonest, so we render none
 *  and the dots reveal on zoom-in instead. Weight + colour adapt to the criterion. */
export function heatmapPaintFor(sizeBy: SizeBy): HeatmapLayerSpecification['paint'] | null {
    const c = CRITERIA[sizeBy];
    if (!c.heat) return null;
    return {
        'heatmap-weight': heatWeightExpr(c.heat),
        'heatmap-intensity': heatIntensityByZoom,
        'heatmap-color': heatColorExpr(c),
        'heatmap-radius': heatRadiusByZoom,
        'heatmap-opacity': heatOpacityByZoom
    };
}

// --- Overview for INTENSIVE criteria: cluster-average bubbles ----------------
// A rate/decile can't honestly feed a density-sum heatmap (heatmapPaintFor above) —
// summing SEIFA deciles across a dense area would just reproduce population density,
// not the economic character of the area. The honest aggregate of a rate is an
// AVERAGE, not a sum. MapLibre's GeoJSON source can cluster points natively and
// accumulate `clusterProperties` per cluster; we accumulate a sum + a count (over
// only the points that HAVE the field, so "no data" suburbs don't drag the average
// down) and divide at paint time. This gives seifa/crime a real overview — a
// proportional-symbol map (bubble size = suburb count, colour = average) — instead
// of literal nothing below the dot-resolvable zoom.
export const CLUSTER_RADIUS_PX = 60; // screen px; bigger than the 50 default for a chunkier continental read
export const CLUSTER_MAX_ZOOM = Z_FADE_HI - 1; // clusters give way to leaf dots by the existing handoff

/** clusterProperties for a GeoJSON cluster source, aggregating ONE intensive
 *  criterion's field into `<field>_sum` / `<field>_cnt` (points lacking the field
 *  contribute 0 to both, so the average is over real data only). */
export function clusterPropertiesFor(sizeBy: SizeBy): Record<string, unknown> {
    const { field } = CRITERIA[sizeBy];
    const has = ['has', field];
    return {
        [`${field}_sum`]: ['+', ['case', has, ['get', field], 0]],
        [`${field}_cnt`]: ['+', ['case', has, 1, 0]]
    };
}

// Fades out across the same handoff the dots fade in across (Z_FADE_LO→Z_FADE_HI),
// so cluster bubbles cross-fade into leaf dots exactly where they become resolvable.
const clusterOpacityByZoom: ExpressionSpecification = [
    'interpolate',
    ['linear'],
    ['zoom'],
    3, 0.82,
    Z_FADE_LO, 0.78,
    Z_FADE_HI, 0
] as unknown as ExpressionSpecification;

// A proportional-symbol radius: bubble size carries HOW MANY suburbs were folded in.
// This layer only ever receives cluster features (the caller filters on
// `['has', 'point_count']`) — unclustered leaf points render through the normal
// per-point `circlePaintFor` layer instead, so they get its finer zoom/value-driven
// sizing rather than a flat "cluster of one" radius.
const clusterRadiusExpr: ExpressionSpecification = [
    'interpolate',
    ['linear'],
    ['get', 'point_count'],
    1, 6,
    10, 10,
    50, 14,
    200, 19,
    1000, 25,
    5000, 32
] as unknown as ExpressionSpecification;

/** The CircleLayer paint for the cluster-average overview of an INTENSIVE criterion —
 *  colour = cluster average, radius = how many suburbs the bubble represents. Apply to
 *  a layer filtered on `['has', 'point_count']`, on a source created with
 *  `cluster: true` + `clusterPropertiesFor(sizeBy)`. */
export function clusterPaintFor(sizeBy: SizeBy): CircleLayerSpecification['paint'] {
    const c = CRITERIA[sizeBy];
    const sumField = `${c.field}_sum`;
    const cntField = `${c.field}_cnt`;
    const avgInterp = interpolateStops(c, ['/', ['get', sumField], ['max', ['get', cntField], 1]]);
    const color = [
        'case',
        ['>', ['get', cntField], 0],
        avgInterp,
        NO_DATA
    ] as unknown as ExpressionSpecification;
    return {
        'circle-color': color,
        'circle-radius': clusterRadiusExpr,
        'circle-opacity': clusterOpacityByZoom
    };
}

/** Legend descriptor for a criterion — the gradient + endpoint labels the +page
 *  legend renders (the title is chrome → i18n in the component). */
export interface SizeLegend {
    gradient: string; // CSS gradient stop list (caller wraps in `linear-gradient(...)`)
    min: string;
    max: string;
}
export function legendFor(sizeBy: SizeBy): SizeLegend {
    const c = CRITERIA[sizeBy];
    const [lo, hi] = c.domain;
    const span = hi - lo || 1;
    const gradient = c.stops
        .map(([v, col]) => `${col} ${Math.round(((v - lo) / span) * 100)}%`)
        .join(', ');
    return { gradient, min: c.min, max: c.max };
}

/** v1 has no external basemap (Protomaps-on-R2 is a follow-on, map-stack.md §5). A
 *  minimal background-only style: the centroid bubbles sit at real lat/lon, so the
 *  Sydney/Melbourne Vietnamese clusters read as shape without a basemap. Zero network
 *  tile dependency — proven entirely in the dev/svelte-check loop. */
export const minimalStyle: StyleSpecification = {
    version: 8,
    sources: {},
    layers: [{ id: 'bg', type: 'background', paint: { 'background-color': '#e9ecea' } }] // = app.css --map-ground
};

// Protomaps basemap (8-S2d). Static assets (glyphs/sprite) load from protomaps.github.io
// in dev/eval; prod self-hosts them alongside the owned R2 `.pmtiles` extract (map-stack.md
// §2, deploy-build). The `light` flavor is a calm modern colour basemap — muted enough
// that the data bubbles still read on top (§7.1). These basemap layers sit BELOW the
// bubble layer — svelte-maplibre-gl adds the CircleLayer after the style loads, so the
// data layer stays on top of the basemap.
/** Who the basemap credits (ODbL / Protomaps terms). The page shows these in its one "i"
 *  credit popup (behavior 43); MapLibre's own attribution control is off. */
export const BASEMAP_CREDIT = [
    { name: 'Protomaps', url: 'https://protomaps.com' },
    { name: 'OpenStreetMap', url: 'https://openstreetmap.org/copyright' }
] as const;

const PROTOMAPS_ASSETS = 'https://protomaps.github.io/basemaps-assets';
// The vector source id, shared between `sources` (below) and `layers()`'s first arg
// (which bakes `"source": BASEMAP_SOURCE_ID` into every generated layer) — also the id
// SuburbMap.svelte matches a MapLibre 'error' event's `sourceId` against to detect a
// failed basemap and fall back to `minimalStyle` (see its runtime-fallback comment).
export const BASEMAP_SOURCE_ID = 'protomaps';

// Mai An Cư's basemap: Protomaps 'light' with its land, water and green areas re-tinted
// to the app palette (app.css :root, behavior 41). The stock flavour's cyan water and
// saturated park greens competed with the jade suburb fills; here the ground is warm
// paper (≈ --bg), water a quiet slate blue, and parks a faint sage, so the choropleth
// is the only strong colour on the map. MapLibre needs literals, so they live here.
const MAP_FLAVOR: Flavor = {
    ...namedFlavor('light'),
    background: '#e9ecea',
    earth: '#efebe3',
    water: '#c9d8e2',
    ocean_label: '#6f8798',
    park_a: '#e4e6dc',
    park_b: '#d9dfcf',
    wood_a: '#e4e6dc',
    wood_b: '#d9dfcf',
    scrub_a: '#e6e5dc',
    scrub_b: '#dcdfd2',
    sand: '#ece6d8',
    beach: '#ece6d8',
    glacier: '#f1efea',
    buildings: '#e0dbd1',
    pedestrian: '#ebe6dc',
    boundaries: '#b8b1a3',
    city_label: '#3b4658',
    subplace_label: '#646a73',
    // Low-zoom landcover (the whole continent at z3-6): stock greens and yellows read as
    // data; a near-flat warm paper keeps them as texture only.
    landcover: {
        grassland: '#ebe9df',
        barren: '#f1ebdf',
        urban_area: '#e6e1d8',
        farmland: '#ebe8dd',
        glacier: '#f6f4ef',
        scrub: '#ece9dd',
        forest: '#e2e5d9'
    }
};

/** A Protomaps-backed MapLibre style for a given `.pmtiles` archive URL. The caller must
 *  have registered the `pmtiles://` protocol first (ensurePmtilesProtocol, lib/pmtiles.ts).
 *  Returns a plain object — no DOM, no protocol side effect — so this stays unit-testable. */
/** The id of the basemap's first label (symbol) layer. Inserting the data layers
 *  *before* this (CircleLayer/HeatmapLayer `beforeId`) keeps every place name — cities,
 *  suburbs, roads — rendering ON TOP of the dots, so labels stay readable however dense
 *  the data gets. Returns undefined if the flavor somehow has no symbol layer (then the
 *  data sits on top, the no-basemap behaviour). */
export function firstLabelLayerId(): string | undefined {
    return layers(BASEMAP_SOURCE_ID, MAP_FLAVOR, { lang: 'en' }).find(
        (l) => l.type === 'symbol'
    )?.id;
}

export function basemapStyle(pmtilesUrl: string): StyleSpecification {
    return {
        version: 8,
        glyphs: `${PROTOMAPS_ASSETS}/fonts/{fontstack}/{range}.pbf`,
        sprite: `${PROTOMAPS_ASSETS}/sprites/v4/light`,
        sources: {
            [BASEMAP_SOURCE_ID]: {
                type: 'vector',
                url: `pmtiles://${pmtilesUrl}`,
                attribution: BASEMAP_CREDIT.map((c) => `<a href="${c.url}">${c.name}</a>`).join(' © ')
            }
        },
        layers: layers(BASEMAP_SOURCE_ID, MAP_FLAVOR, { lang: 'en' })
    };
}
