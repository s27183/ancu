# Map Stack — ADR

> The mapping decision for the shell's map-first home (constraint #7 renderer vocabulary, [`shell-architecture.md` §7](shell-architecture.md#7-ux-surfaces--map-first)). Records *what we chose, what we rejected, and where each choice stops holding*. The map renders the **raw** suburb metrics the engine serves at [`GET /api/engine/suburbs`](engine-contract.md) (8-S1) — the shell-side reader of [`suburb-data-foundation.md` §2](suburb-data-foundation.md) "two readers."
>
> **Status:** Accepted — 2026-06-13. **Supersedes** the `Leaflet` placeholder in `shell-architecture.md` §7.
> **Scope:** the shell frontend map. Does not decide frontend *hosting* (still open — see §4 synergy note).

---

## 1. Context

The home surface (8-S2) is a full-bleed suburb-intelligence map; the **Vietnamese-community-proximity layer is the killer layer** and ships first. The decision is bound by three project constraints, not by map-framework fashion:

- **Independence / lean cost** (CLAUDE.md: independent, paid by users). A per-map-load meter or a mandatory vendor account is a commercial dependency baked into the home screen — disqualifying for the default basemap and tile path.
- **What the data *is* today vs. where it goes.** Verified against the dev engine DB this session: `suburbs` holds **0 polygons / 15,329 centroids** — the ABS-ASGS polygon/mesh-block mechanism was deferred ([[decompose-build-unit-by-mechanism]]). So **v1 is a point/bubble layer at centroids**, sized/coloured by `vietnamese_ancestry_pct` (with `seifa_irsad_decile`, `crime_incidents_per_1000`, `census_total_persons` as toggles). When polygons land, the killer layer wants a real **choropleth** — the engine choice must not have to change then.
- **Svelte 5.** The frontend is a Svelte 5 + runes SPA ([[firsthomey-svelte-conventions]]). The integration mechanism, not the library, is what Svelte cares about (§3).

## 2. Decision

| Layer | Choice | One-line why |
|---|---|---|
| **Rendering engine** | **MapLibre GL JS** | BSD/open (no token, no per-load meter, no telemetry); WebGL vector does the bubble layer now **and** the future polygon choropleth on the same engine — no migration tax. |
| **Svelte wrapper** | **MIERUNE [`svelte-maplibre-gl`](https://github.com/MIERUNE/svelte-maplibre-gl)** | Runes-native *by design* (born in the Svelte-5 era, no v4 rewrite debt); Apache-2.0; org-backed by a geospatial firm; tracks `@sveltejs/kit` releases. |
| **Basemap tiles** | **Protomaps (`pmtiles`)**, self-hosted on **Cloudflare R2 + Workers** | Single static file we own; flat ~$3–11/mo for a *global* set, an AU extract is a fraction; no egress, no token, no lock-in. |
| **Integration** | Svelte 5 **`{@attach}`** (the wrapper uses it internally) | The blessed Svelte-5 hook for imperative DOM libs (since 5.29): mount → effect, return teardown on unmount, re-runs on read `$state`. |

Net: **MapLibre GL JS + MIERUNE `svelte-maplibre-gl` + Protomaps pmtiles on Cloudflare R2.**

## 3. Why Svelte-friendliness is *not* the discriminator

Every map library is a framework-agnostic imperative JS lib. Svelte 5's `{@attach}` gives all of them the **same** clean mount/teardown hook:

```svelte
<div {@attach (el) => {
    const map = new maplibregl.Map({ container: el, /* style, center, zoom */ });
    return () => map.remove();   // teardown on unmount
}}></div>
```

So "which lib works best *with Svelte 5*" largely dissolves — the glue is the same ~15 lines regardless of engine. The decision falls back on the libs' own properties (license, rendering engine) and **wrapper-ecosystem depth**, which is the only place they diverged: MapLibre has two runes-era wrappers + an official MapTiler Svelte guide; Leaflet has one. Picking the wrapper buys *declarative layer management* (`<Map><GeoJSONSource><CircleLayer/>`), which pays off as the map accrues layers (Vietnamese % → SEIFA → crime → transport → schools → price → click-sheet → choropleth).

## 4. Alternatives rejected

- **Mapbox GL JS** — proprietary v2+: account + token required, **billed per map load**, telemetry. Direct hit on independence/cost. Rejected.
- **Leaflet** — open and fine for a point layer *today*, but a **raster/SVG** engine: the polygon choropleth (the killer layer at full fidelity, once polygons land) is its weak path, so we'd migrate engines later. One Svelte-5 wrapper ([`sveaflet`](https://github.com/GrayFrost/sveaflet)) vs MapLibre's two. Rejected to avoid the future re-choice.
- **dimfeld [`svelte-maplibre`](https://github.com/dimfeld/svelte-maplibre)** — more popular (511★ vs 313★) and an excellent maintainer, but its Svelte-5 support is a **rewrite of a v4-era lib**, and it's bus-factor-1. *Boundary:* this is the right pick if community mass / a longer track record outweighs runes-native purity for you — it was a close call, not a knockout.
- **MapTiler free-tier tiles** — fastest turn-up, but a keyed, **metered, external** dependency: the long-term commercial coupling we're avoiding. We already settled "foundations-first, forget the demo," so the long-term pick dominates the speed pick.
- **Wrap `maplibre-gl` directly (no wrapper)** — viable for the first single-layer slice and keeps us purely inside our autofixer/svelte-check loop, but loses declarative layer management as layers multiply. Adopting the wrapper from the start avoids a second migration; the wrapper composes with `{@attach}` so first-slice simplicity is preserved.

## 5. Consequences and boundaries

- **v1 is bubbles, not a choropleth.** With centroids-only, the first layer is `CircleLayer` over a GeoJSON FeatureCollection built from `/api/engine/suburbs?state=…`. The choropleth (`FillLayer` data-driven by `vietnamese_ancestry_pct`) is unlocked only when the deferred ABS-ASGS polygon mechanism populates `boundary_jsonb`. MapLibre is chosen precisely so *that* day requires no engine change — just a new layer.
- **The click-sheet is a bottom-sheet on phone, a side-panel on desktop.** The suburb-click detail (zone-data + planning tabs) is the first concrete instance of the mobile-native principle ([`shell-architecture.md` §7.1](shell-architecture.md#71-mobile-native-minimal-cognitive-load)): full-bleed map + thumb-reachable bottom-sheet on the phone, the *same* tabbed content rendered as a side-panel on desktop — one layout, adjusted, not two. One language on the surface (VI-default); the second a tap away.
- **Protomaps uses its own layer schema.** We author a Protomaps-compatible MapLibre style, not a drop-in Mapbox/MapTiler style. ([Protomaps Cloudflare docs](https://docs.protomaps.com/deploy/cloudflare)) **Implemented at 8-S2d** via `@protomaps/basemaps` (`layers('protomaps', namedFlavor('light'), {lang})`) + the `pmtiles` protocol — the basemap source is a configurable `VITE_PMTILES_URL` (unset → the no-basemap `minimalStyle` fallback, so the dev/build loop never regresses), dev/eval against a Protomaps daily build and **prod against the owned R2 extract** (provisioned at deploy-build). The glyphs/sprite assets load from `protomaps.github.io` in dev and self-host in prod (deploy-build).
- **R2 read latency** can be ~500ms; mitigated by the Workers/CDN cache in front. Acceptable for a basemap (cached, tiled), watch it if it bites.
- **The wrapper tracks two release lines** (`maplibre-gl` *and* Svelte/Kit). MIERUNE's recent commits show it does; revisit if that lapses.
- **Hosting synergy — flagged, not decided here.** Protomaps-on-R2/Workers sits naturally on Cloudflare, which `shell-architecture.md` (§5, §8) already names as the frontend's "Cloudflare Pages adapter." That alignment is convenient but the **frontend-hosting fork** (Erlang-serves-static vs `adapter-cloudflare`, the deferred 8-S0 decision) stays a separate decision — this ADR does not settle it.

## 6. Cross-references

- [`shell-architecture.md` §7](shell-architecture.md#7-ux-surfaces--map-first) — the map-first home surface (this ADR is the engine/wrapper/tiles detail behind its one line).
- [`suburb-data-foundation.md` §2](suburb-data-foundation.md) — "two readers": the map reads raw `facts_jsonb`; the resolver reads the coarse `suburb.*` band.
- [`engine-contract.md`](engine-contract.md) — `GET /api/engine/suburbs` (8-S1), the map's data source.
