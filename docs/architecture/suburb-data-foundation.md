# Suburb data foundation — the `suburb.*` reference surface and its ingestion

**Status:** Direction accepted (Son, June 2026 — "we are building the geo-socio-economic KB here"). This doc **completes the third shared surface** named by the registry — `profile.* ⊕ applicant.* ⊕ property_fit.* ⊕ suburb.*` ([structure-map](structure-map.md) plane 2). The `suburb.*` *surface* and its `<from_suburb>` lookup were already specified ([property-model-foundation §`suburb.*`](property-model-foundation.md), [architecture §11.10 "Suburb enrichment pipeline"](architecture.md#1110-property-data-pipeline--narrow-and-demand-driven), blueprint `fhb-domestic-au.md` lines 247–260); what was **never specified** is the *engineering* — the `suburbs` table schema, the per-state adapters, the join grain + correspondences, and the provenance/license model. This doc owns that. It is *completion, not duplication*: §11.10 holds the strategic scope (no scraping, suburb-level only, free-tier-first) and the verified ABS access points; this doc holds the materialization.

The executable remainder is one migration (`003_suburbs.sql`) + the `engine/build/` adapters. **`003_suburbs.sql` landed** (June 2026 — both tables + the source register, validated against dev PG); the per-state adapters remain.

---

## 1. The category decision — reference data, not a prose KB

Son's framing is "the geo-socio-economic KB," and the *discipline* is the KB's: grounded against the primary gov source, build-time ingested, provenance-stamped. But the **materialization differs**, and conflating them is a category error ([[build-time-structure-vs-runtime-data]]):

| | Planning KB (`docs/kb/**.md`) | Suburb data (this doc) |
|---|---|---|
| Shape | curated **prose + rules** (`content_md` + `content_json`) | **tabular** — ~15k suburbs × N metrics |
| Author | a human writes each slug | an **adapter** ingests a gov feed |
| Store | compiled to the **`persistent_term` artifact** | the **`suburbs` PG table**, queried at runtime |
| Provenance | frontmatter `last_verified` (regulated audit) | per-metric `{source, as_of, license}` (freshness + license) |
| SOT | git | the gov source; the table is a rebuildable projection |

So: **no `docs/kb/geo/**.md` content docs.** You do not author 15,000 suburb markdown files — that is runtime reference data, not a slugged corpus. The only thing that crosses into the planning KB is the *interpretation thresholds* (what counts as `high` Vietnamese proximity, the FHG **price cap** — already `kb.scheme.fhg`), which are tiny rule-config that rides with the consuming component. The "FHG-eligible price band" map layer is a **join** of an existing KB cap against this reference data, not new content.

A third bucket, distinct from both: this is neither compiled **structure** (artifact) nor user **runtime-state** (plan cards) — it is **shared reference data** (slowly-changing, tenant-independent, feeds planning). That third-ness drives two schema properties below: **no `tenant_id`** (global), and **feed-cadence refresh** (not deploy-time, not per-turn).

---

## 2. The two readers — coarse for the resolver, raw for the map

The same `suburbs` row is read two ways, and the split mirrors the engine/shell boundary:

- **Resolver (engine) reads the coarse `suburb.*` surface** — banded enums the blueprint already declares (`flood_risk_band`, `vietnamese_community_proximity: high|medium|low`, `school_catchment_quality`). Coarse because the resolver feeds *regulation-adjacent* reasoning and must be honest-partial ([[base-turn-honest-partial-output]]) — a band degrades gracefully to `unknown`; a raw number invites false precision.
- **Map (shell) reads the raw metrics** — `vietnamese_ancestry_pct` (the killer-layer **heatmap** needs the gradient, not the 3-bucket enum), SEIFA score, crime rate, median price. The shell renders; it does not reason.

So the table is the **superset**; `suburb.*` (the registry term the resolver reads) is a **coarse projection** of it. The shell hits a read endpoint for the raw fields. One source, two projections — the same discipline as outcomes-carry-facts-not-verdicts.

---

## 3. The `suburb.*` surface (resolver-facing, canonical)

The seven fields the blueprint reads today **stay verbatim** (ground vocabularies in the authoritative source — [[ground-design-choices]]), plus the additions this research enables. Coarse/banded by design:

| `suburb.*` field | Type | Source family | Status |
|---|---|---|---|
| `lga` | string | ABS ASGS | existing |
| `is_capital_city` | bool | ABS ASGS | existing |
| `flood_risk_band` | enum `none·low·medium·high·unknown` | state planning/emergency | existing |
| `school_catchment_quality` | enum `strong·average·weak·unknown` | state education + school locations | existing |
| `transport_score` | int 0–100 | GTFS proximity | existing |
| `vietnamese_community_proximity` | enum `high·medium·low` | ABS Census ancestry | existing |
| `planning_changes_pending` | array&lt;string&gt; | state planning | existing |
| `seifa_irsad_decile` | int 1–10 (`null`=unknown) | **ABS SEIFA** | **new — socio-economic spine.** Unlike `vietnamese_community_proximity` (an *interpretive* band → resolver-projected from a KB threshold, §8), the decile is sourced **directly** — ABS publishes it as the official national-distribution rank (`RWAD`), so the adapter writes it, no threshold to apply. |
| `crime_safety_band` | enum `very_low·low·medium·high·unknown` | **state crime agency** | **new** |
| `median_house_price` | int AUD (**`null` per state**) | **state Valuer-General** | **new — asymmetric (§7)** |
| `median_unit_price` | int AUD (`null` per state) | state Valuer-General | new |

The raw map-facing fields (`vietnamese_ancestry_pct`, `seifa_irsad_score`, `crime_incidents_per_1000`, `median_*_as_of`, demographics) live in `facts_jsonb` but are **not** part of the resolver registry surface — the shell reads them, the resolver does not. Adding a `suburb.*` field is a registry change → the compiler's reference-integrity gate covers it (a blueprint `<from_suburb>` ref to an absent field fails the build).

---

## 4. The `suburbs` table schema (`003_suburbs.sql`, sketch)

Follows migration-001 conventions: `text + CHECK` over ENUM, `jsonb` for the evolving metric set, forward-only, no in-file `BEGIN/COMMIT`. **Two tables** — the data and a source register:

```sql
-- Global reference data — NO tenant_id (shared across all tenants), unlike
-- every table in 001. Keyed at ABS Suburb-and-Locality (SAL) — the join grain (§5).
CREATE TABLE suburbs (
    sal_code         text PRIMARY KEY,                 -- ABS SAL code, e.g. 'SAL10738'
    name             text NOT NULL,                    -- 'Cabramatta'
    state            text NOT NULL
                     CHECK (state IN ('NSW','VIC','QLD','WA','SA','TAS','ACT','NT')),
    lga_name         text,
    is_capital_city  boolean,
    centroid_lat     double precision,                 -- for map placement
    centroid_lon     double precision,
    facts_jsonb      jsonb NOT NULL DEFAULT '{}'::jsonb,  -- the suburb.* surface + raw map fields
    provenance_jsonb jsonb NOT NULL DEFAULT '{}'::jsonb,  -- { field: { source_id, as_of } }
    boundary_jsonb   jsonb,                            -- SAL polygon (GeoJSON) for choropleth; optional, large
    updated_at       timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idx_suburbs_state ON suburbs (state);
CREATE INDEX idx_suburbs_name  ON suburbs (state, name);

-- The source/license REGISTER — one row per feed. Doubles as the adapter manifest
-- (§6) and the license-compliance artifact (§6.1). The ACARA redistribution
-- constraint is a first-class row here, not a comment.
CREATE TABLE suburb_sources (
    source_id      text PRIMARY KEY,                   -- 'abs_census_2021', 'nsw_vg_psi', 'bocsar'
    name           text NOT NULL,
    publisher      text NOT NULL,
    license        text NOT NULL,                      -- 'CC BY 4.0', 'CC BY 3.0', 'restricted-acara'
    attribution    text NOT NULL,                      -- the exact CC-BY attribution string to render
    redistribution text NOT NULL DEFAULT 'permitted'
                   CHECK (redistribution IN ('permitted','attribution_only','restricted')),
    cadence        text NOT NULL,                      -- '5y','quarterly','weekly','daily','annual'
    url            text,
    notes          text
);
```

`facts_jsonb` (not flat columns) for the metric set — same reason `profiles.facts_jsonb` and `plan_cards.content_jsonb` are jsonb: the metric surface evolves (add PropTrack rent later, add growth composites in Wedge 3) without an `ALTER`. The **join/filter keys** (`sal_code`, `state`, `name`, `is_capital_city`, centroid) are columns because the map queries by state and the resolver pulls by `sal_code`. `provenance_jsonb` maps each filled field → `{source_id, as_of}`, so a stale metric is detectable per field and the CI completeness gate (§11.10) can assert freshness.

---

## 5. The join grain — SAL — and the one fiddly bit (correspondences)

**SAL (Suburb and Locality, ~15k nationally) is the click target and the join key**, confirming the earlier "click = suburb, not mesh block" call. Mesh blocks are privacy-suppressed (the killer layer would blank); SA1 has no human name; named suburbs are how buyers and schemes think. ABS Census **and** SEIFA are both published *directly* at SAL — so the spine of the data needs **no correspondence at all**.

Correspondence is needed only where a source isn't already at SAL, and there are exactly **two mechanisms**:

1. **Point → SAL (spatial join).** School locations, GTFS stops, and NSW VG sale *addresses* are points → point-in-polygon against the ABS SAL boundary file (GeoPackage). Deterministic, offline.
2. **Named-suburb → SAL (name crosswalk).** BOCSAR crime and the VIC VPSR publish by *their own* gazetted suburb list, which is ≈ but ≠ ABS SAL (spelling, splits/merges). A name+state crosswalk (with a spatial fallback for the residue) reconciles them. This is **the** fiddly bit — budget for a hand-curated crosswalk for the unmatched tail, and `log()` the drop (no silent truncation — [[enforce-invariants-not-workflows]]).

The build emits `suburbs.boundary_jsonb` from the SAL boundary file for the choropleth; the spatial joins reuse the same boundaries.

---

## 6. The per-state adapter set (the build-time jobs)

Each adapter: a `engine/build/` job that fetches → transforms → upserts a field-subset into `suburbs.facts_jsonb` with provenance, and ensures its `suburb_sources` row. **Free-tier-first** (§11.10 deployment tiers); paid feeds deferred.

| `source_id` | Feed | Grain → SAL | Cadence | License | `suburb.*` / raw fields |
|---|---|---|---|---|---|
| `abs_census_2021` ✅ | ABS Data API (SDMX-JSON, no key) — flow `C21_G08_SAL` | **SAL direct** | 5y | CC BY 4.0 | `vietnamese_ancestry_pct` (raw); demographics/dwellings later |
| `abs_seifa_2021` ✅ | ABS SEIFA (IRSAD), flow `ABS_SEIFA2021_SAL` | **SAL direct** | 5y | CC BY 4.0 | `seifa_irsad_score` (raw), `seifa_irsad_decile` (sourced), `seifa_irsad_population` |
| `abs_asgs_2021` ◑ | ABS **ArcGIS REST** (`ASGS2021/SAL`: layer 2 SAL_PT centroids ✅; layer 1 SAL_GEN polygons ⏳) + MB allocation ⏳ | SAL-direct (centroid); MB→SAL (lga/gccsa) | per-edition | CC BY 4.0 | `centroid_*` ✅; `lga`·`is_capital_city`·`boundary_jsonb` deferred (§6 note) |
| `nsw_vg_psi` | NSW VG **Bulk PSI** — actual sales `.DAT`/LGA | point→SAL | **weekly** | CC BY (data.NSW) | `median_house_price`, `median_unit_price` (aggregated) |
| `vic_vpsr` | VIC **Property Sales Report** — median/suburb | name→SAL | **quarterly** | CC BY 4.0 | `median_house_price`, `median_unit_price` (direct) |
| `qld_price` | — **(none free; §7)** | — | — | — | `median_*` → **`null`** |
| `bocsar` / `csa_vic` / `qps` | state crime agency (CSV/API) | name→SAL | quarterly | CC BY (verify per state) | `crime_incidents_per_1000`→`crime_safety_band` |
| `gtfs_*` | TfNSW / DTP Vic / TransLink GTFS | point→SAL | static+live | CC BY 4.0 | `transport_score` |
| `schools_*` | ACARA **locations** + state catchments | point/boundary→SAL | annual | locations ok; **NAPLAN/ICSEA restricted** | `school_catchment_quality` |
| `planning_*` | state planning/emergency portals | boundary→SAL | per-event | CC BY (mostly) | `flood_risk_band`, `planning_changes_pending` |
| `rba_fx` | RBA/interbank | national | daily | CC BY | VND/AUD (not a `suburbs` field — onboarding-time conversion) |

**First adapter implemented** (`engine/build/suburbs/`, June 2026): `abs_census_2021` + the shared merge-upsert (`db.upsert_facts` — `jsonb || jsonb`, so adapters never clobber each other's fields). Two facts the live build confirmed/corrected:

- **API host moved.** `api.data.abs.gov.au` now **301-redirects to `data.api.abs.gov.au/rest`** — the working base. (The §11.10 / memory references to the old host are stale; the adapter uses the new one.)
- **The adapter writes the RAW metric, not the band.** §3 lists both `vietnamese_ancestry_pct` (raw, map-facing) and `vietnamese_community_proximity` (coarse, resolver-facing); the adapter writes **only the raw pct**. The coarse band is a *resolver-side projection from a KB threshold* at the `<from_suburb>` lookup (§1 interpretation-threshold-is-KB, §2 the-table-is-the-superset-suburb.*-is-a-projection). So this table's "→ band" entries denote *lineage* (this feed ultimately drives that field), **not** that the adapter materializes the enum. Result validated end-to-end: Cabramatta 7995/21142 = **37.82%** (matches ABS QuickStats), and the national top-12 are the known diaspora suburbs (Cabramatta, Canley Heights, Sunshine North, Inala…).

**Second adapter implemented** (June 2026): `abs_seifa_2021` — the socio-economic spine, the first **enrichment** adapter (`db.update_facts`, UPDATE-only, no spine; it enriches the census-seeded rows). Three grounded divergences from the census adapter, each verified against the live ABS contract:

- **The decile is written DIRECTLY, not projected** (the one departure from the raw-metric-only discipline above). ABS publishes the IRSAD national decile as the official statistic `RWAD` (Rank Within Australia, Decile) — there is no FirstHomey threshold to apply, so the adapter materializes `seifa_irsad_decile` itself (plus the raw `seifa_irsad_score` for the map). The §2/§8 "adapter writes raw, resolver projects the band" rule's boundary is *interpretive* bands; an ABS-published decile falls outside it. The decile's near-uniform 1–10 distribution (~1445 SALs each) cross-checks that `RWAD` is the true national rank.
- **CSV, not SDMX-JSON.** An enrichment adapter carries no `name`/`state` (the spine owns those) and the flow has no STATE dimension, so it needs neither structure-section parsing for REGION→name nor per-state paging — the filtered CSV key `.IRSAD.SCORE+RWAD+URP` (~3.4 MB) is self-describing via column headers.
- **Stores `seifa_irsad_population` (URP).** Same rationale as the census denominator (the small-n / SEIFA-exclusion floor + map population). Notably **URP survives index suppression**: ABS suppresses the index for tiny areas (1780 suppressed observations → honest-partial `null` decile/score) but still publishes population, so a 3-person SAL keeps its population while its decile is correctly absent.

Validated end-to-end against dev PG: all **15,345** spine rows enriched (decile/score on 14,457 after suppression; population on all 15,345); SEIFA `URP` for Cabramatta = **21,142**, byte-identical to census `census_total_persons` (the SAL join key is consistent across feeds); the **7** unmatched SEIFA SALs are exactly the out-of-scope codes the census spine deliberately skipped (`SAL9000x` Other Territories / `SAL99797` no-usual-address), logged not swallowed (§5); census and SEIFA fields coexist in one row with per-field provenance (no clobber, the `jsonb || jsonb` merge proven across two adapters).

**Third adapter implemented** (June 2026): `abs_asgs_2021` — SAL **centroids**, the map-placement spine. Three things distinguish it, each grounded against the live ABS contract:

- **A different ABS surface — ArcGIS REST, not the SDMX Data API.** The geography (boundaries, centroids) lives in ABS feature services (`https://geo.abs.gov.au/arcgis/rest/services/ASGS2021/SAL/MapServer`), the statistics in the Data API. The SAL service has three layers — `0` full polygons, `1` generalised polygons (SAL_GEN), `2` **boundary centroids** (SAL_PT). Centroids are **pre-computed by ABS**, so a representative lon/lat per SAL needs *no* geometry library — `outSR=4326&f=geojson`, paged at the layer's `maxRecordCount` 2000 (~15.3k SALs ⇒ 8 pages, `orderByFields=sal_code_2021` for stable paging). The §5 "Point → SAL spatial join" is unneeded for the centroid itself.
- **Writes real COLUMNS, not `facts_jsonb`** (§4 makes centroid a column — the map filters/joins on it). A third db role joins the spine/enrichment pair: `db.update_columns` (UPDATE-only by `sal_code`, a **whitelisted** dynamic SET so a column name can never come from feed data, provenance still merged into `provenance_jsonb` for uniform freshness). `sal_code_2021` is digits-only (`10738`) → prefixed `SAL` to match the census spine key.
- **The adapter is deliberately split along the §6 row's *mechanism* seam.** This session shipped only `centroid_*` (ArcGIS REST, zero new deps — the load-bearing field, since 8b–8d cannot place a suburb without it). **`boundary_jsonb` is deferred to 8d** (the choropleth is its only consumer; §4 flags it "optional, large" — storing ~15k generalised polygons nothing reads yet is premature bloat). **`lga_name` + `is_capital_city` are deferred to a dedicated Mesh-Block correspondence sub-build** — the first real §5 *name/area* correspondence (SAL is a non-ABS structure carrying no LGA/GCCSA; the route is the ABS MB allocation files MB→SAL ⋈ MB→LGA/GCCSA, `.xlsx`, modal-aggregated to SAL — a distinct mechanism, not a REST pull, warranting its own focused build).

Validated end-to-end against dev PG: **15,329** of the 15,345 spine rows got a centroid; the **16** that did not are *exactly* the non-geographic pseudo-localities (`No usual address` + `Migratory – Offshore – Shipping`, one pair per state/territory) — they have no location, honest-partial `null` is correct, not a miss. Spot-checks land: Cabramatta `(-33.898, 150.936)` Sydney SW, Footscray `(-37.801, 144.895)` Melbourne W, Inala `(-27.590, 152.973)` Brisbane SW; the only centroid outside the mainland box is **Lord Howe Island** `(-31.5, 159.1)` — a real NSW external territory, accurate. The **5** unmatched ASGS codes are the out-of-scope `SAL9000x` (Other Territories) the census spine deliberately skipped — logged not swallowed (§5).

### 6.1 License compliance is a real obligation, not a footnote

CC BY 4.0 **requires attribution** (render the `suburb_sources.attribution` string wherever a layer shows) — the shell map needs an attribution strip. **ACARA is the exception**: NAPLAN/ICSEA are `redistribution: restricted` (no redistribution, "must not compete with My School," Data Access Program application). So `school_catchment_quality` derives from **school locations + state catchment boundaries** (permitted), **not** from redistributing ACARA performance data. The `suburb_sources` register makes this enforceable: an adapter whose source row is `redistribution: restricted` must not write a field the shell will publish. Don't ship what you're not licensed to.

---

## 7. The price asymmetry — and Son's (a) decision

Suburb median price is **free but uneven across the three Wedge-1a states**, and ABS itself does *not* provide it at suburb grain (the SA2-level Residential Property Price Index was **discontinued Dec 2021**; *Total Value of Dwellings* is capital-city + rest-of-state only):

- **NSW** — VG **Bulk PSI**: actual sales since 1990, weekly, free → aggregate to a current suburb median. ✅
- **VIC** — **VPSR**: median by suburb (house/unit/land), quarterly, free, pre-aggregated. ✅
- **QLD** — suburb medians are **closed** (IP/revenue; QVAS extracts quoted >$20k). QLD Globe gives *valuations* not sales; RTA gives median *rents*; REIQ is an industry body (redistribution unclear). ❌

**Son's decision: (a) ship NSW/VIC real medians; QLD `median_* = null` → the shell shows "range / unavailable."** This is just honest-partial again — and it costs the base plan nothing, because the user's **target price range is a user input** (constraint #1), never derived from the suburb. The median is decoration ("is my budget realistic here?"), not load-bearing. QLD fills behind the same nullable column when a feed appears (paid CoreLogic in Wedge 3, or a future free QLD release).

---

## 8. The `<from_suburb>` resolver-lookup contract

`<from_suburb>` (architecture line 316, blueprint line 935) is a **session-start pull**, not an agent call: when a plan card's zone is known, the resolver `SELECT … FROM suburbs WHERE sal_code = $1` and projects the coarse `suburb.*` fields into the registry. Contract:

- **Missing suburb / missing field → the coarse `unknown` band**, never a crash and never a guess. `flood_risk_band: unknown`, `median_house_price: null` propagate as honest-partial; downstream resolvers already tolerate `unknown` (the K3 collapse — [[firsthomey-data-model-direction]]).
- The pulled values + their `provenance_jsonb` snapshot into the plan card's `content_jsonb` at fill (the same audit-snapshot discipline as KB content), so a filled card is reproducible even after the suburb feed refreshes.
- No `tenant_id` filter — `suburbs` is global.
- **The band projection must floor on population (small-n caveat — denominator now stored).** The census build surfaced tiny remote SALs where a handful of people swing `vietnamese_ancestry_pct` to a misleadingly high value (e.g. "South Plantations, WA" — **27.13% off just 188 persons**, vs Cabramatta's 37.82% off 21,142; ABS small-cell perturbation amplifies this). So when the `<from_suburb>` resolver projects the coarse `vietnamese_community_proximity` band from the raw pct + KB threshold, it must **also gate on total persons** (below a floor → `unknown`/`low`, not `high`). The adapter therefore **stores `census_total_persons`** (the pct's own denominator) — not a speculative field: it has three real consumers (the band-projection floor, pct self-auditing/provenance, and the map's population layer), and population is core census demographics already in the §6 remit. (This reverses an earlier "defer until the band projection is built" note — the denominator is already fetched to compute the pct, and its consumers exist today.)

---

## 9. Worked simulation (define → simulate → document)

Three suburbs, one per Wedge-1a state, proving the schema carries the asymmetry. Ancestry **and SEIFA** figures are now **real** (`abs_census_2021` + `abs_seifa_2021`, ingested June 2026); price figures remain illustrative pending the VG adapters (§7):

| | Cabramatta (NSW) | Footscray (VIC) | Inala (QLD) |
|---|---|---|---|
| `sal_code` | SAL10738 | SAL20935 | SAL31388 |
| `centroid_lat, lon` (real, `abs_asgs`) | **-33.898, 150.936** | **-37.801, 144.895** | **-27.590, 152.973** |
| `vietnamese_ancestry_pct` (raw) | **37.82%** | **10.03%** | **27.64%** |
| `vietnamese_community_proximity` (coarse, **KB-threshold projection, §8**) | `high` | `high?` (10% is the borderline the KB threshold must adjudicate) | `high` |
| `seifa_irsad_decile` (real, sourced) | **1** | **8** | **1** |
| `median_house_price` | **$1.02M** (NSW VG PSI) | **$915k** (VIC VPSR) | **`null`** (QLD closed) |
| `crime_safety_band` | `medium` (BOCSAR) | `medium` (CSA) | `medium` (QPS) |
| Map renders | choropleth + $ | choropleth + $ | choropleth + **"price unavailable"** |
| Resolver reads | coarse bands; price decoration | same | same; `median: null` → honest-partial |

The killer layer (Vietnamese ancestry) is **free and present in all three** — vs a ~1% national baseline, every one is strongly elevated; the asymmetry is isolated to one nullable column (price) in one state. The schema does not special-case QLD — `null` is a value the contract already handles. (The coarse *band* is the resolver's KB-thresholded projection, §8 — not stored; Footscray's 10% shows why the threshold + a population floor are the load-bearing curation, not the ingestion.) The real SEIFA also shows the two free layers **decorrelate** — Cabramatta/Inala are decile 1 (genuinely disadvantaged) but **Footscray is decile 8** (gentrified to relative advantage despite the migrant heritage), so the SES spine is a distinct signal from ancestry, not a proxy for it — exactly why both layers earn their place.

---

## 10. Reconciliation with §11.10 (corrections this research surfaced)

§11.10's "Suburb enrichment pipeline" predates this research; these are **factual updates to fold back** (flagged, not silently patched — [[surface-adjacent-doc-drift]]):

1. **Price free-tier is stronger than stated.** §11.10's source table credits VG only with "Capital improved values (rates valuation — stale but indicative)." NSW VG **Bulk PSI = actual sales, weekly** and VIC **VPSR = median/suburb, quarterly** give a *current, transaction-based* free median for NSW/VIC — so CoreLogic (Wedge 3) is needed mainly for **QLD + growth/yield composites**, not basic current median.
2. **QLD price asymmetry** is unstated — add it (§7).
3. **Crime** is absent from §11.10's source table — Son added it; new adapter family (§6).
4. **SEIFA** is absent (§11.10 lists Census demographics, not the derived socio-economic indexes) — it is the socio-economic spine; add it.
5. **ACARA nuance** — §11.10 says "school rankings (free)"; NAPLAN/ICSEA are **restricted** (§6.1). Catchment *quality* must derive from locations + catchments, not redistributed performance data.

**Applied** (June 2026): §11.10's source table now carries the SEIFA + crime rows, the corrected VG-actual-sales + QLD-`null` price reality, and the ACARA restriction; its deployment-tier bullets reflect free NSW/VIC current medians (CoreLogic reduced to QLD-median + composites); and a pointer to this doc as the engineering spec. `structure-map.md` carries the `suburb data` node.

---

## 11. What's deferred (named triggers)

- **Paid feeds** — PropTrack (current rent, days-on-market; Wedge 1c, ~$80/mo) and CoreLogic (current sale price + growth + yield; Wedge 3, ~$140/mo). The schema's nullable price + jsonb metric set absorb them with no migration.
- **Investment-grade composites** (yield/growth scores) — need the paid feeds; deferred with them (Mode C/D, not Wedge 1a).
- **2026 Census** — refresh `abs_census_2021` → `abs_census_2026` when released (in progress per §11.10); provenance `as_of` makes the swap auditable.
- **QLD median** — fills the nullable column when a free release or the paid feed lands.
- **Commercial map APIs — a *fourth* data-flow kind, shell-owned, never persisted.** Google Maps Platform / Mapbox do **not** originate the AU socio-economic origin data that is this surface's differentiator (Vietnamese %, SEIFA, crime, school catchments) — that depth isn't their product here; it's the free gov spine above. Two things they *do* offer, on different axes:
  - **Map canvas / rendering** (Mapbox tiles+SDK vs MapLibre+open tiles) — a shell rendering decision, decided when the map ships; not data, no bearing on this `suburbs` projection.
  - **Live amenity / commute / geocode augmentation** — Google Places (nearby supermarkets, the Vietnamese-grocer layer), Routes/Distance-Matrix (commute-to-CBD), Geocoding (the Phase-B URL-paste address→coords). Gov feeds give these poorly.

  This augmentation is a **fourth bucket** beside the three in [[build-time-structure-vs-runtime-data]] (compiled structure / runtime state / persisted reference): **live third-party API — per-session, ToS-bound, attributed at point of use, not stored.** It is **architecturally distinct from this surface** and must never flow into the `suburbs` table: Google Maps Platform ToS *prohibits* caching/storing its content (sole exceptions: lat/lon/distance/duration/ETA cacheable ≤30 days, `place_id` indefinitely) — storing it, or using it to build a competing dataset, is grounds for termination. The persisted-projection design here is only legal because the gov spine is CC-BY; commercial data may not enter it. So this layer is **shell-owned, live-call, deferred** to the map build (a `<from_suburb>` field is never sourced from it), and is recorded here only to fix the boundary.
- **The adapters** — `003_suburbs.sql` is **done** (`suburbs` + `suburb_sources`, the §4 DDL, validated against dev PG: CHECK constraints + jsonb round-trip + a clean rolled-back apply); the `engine/build/` per-state ingestion jobs (§6) are the remaining executable piece.
