---
slug: kb.property.suburb-risk-factors
effective_from: 2025-08-01
last_verified: 2026-07-06
sources:
  - url: https://www.abs.gov.au/census/guide-census-data/census-dictionary/2021/variables-topic/cultural-diversity/ancestry-multi-response-ancp
    retrieved: 2026-07-06
  - url: https://moneysmart.gov.au/home-insurance/storm-flood-and-fire-insurance
    retrieved: 2026-07-06
---

# Suburb-level risk and amenity factors

A property is only as sound as the **location** it sits in. The same dwelling is a different proposition in a flood-prone pocket versus a dry one, inside a strong school catchment versus a weak one, near transport versus stranded. This doc owns **how to read suburb-level signals into a viability read** — it grounds the `property_assessment` `location_factors` block (`flood_risk_band`, `school_catchment_quality`, `transport_score`, `vietnamese_community_proximity`, `planning_changes_pending`, all sourced from suburb enrichment) and the agent reasoning that folds them into `key_concerns` / `key_strengths` and the `viability_verdict`. It does **not** assess the dwelling itself (`kb.building-types.risk-by-type`), the building's strata health (the strata docs), or price (`kb.property.comparables-methodology`). Provenance is **CONVENTION / framework**; the underlying values come from suburb-enrichment data (ABS Census, state flood / planning / education feeds) and are **INDICATIVE**.

## The factors and how they read

- **Flood risk (`flood_risk_band`) — the load-bearing factor.** A high flood band is the suburb signal with the hardest financial edge: it **raises home-insurance premiums or sees flood cover excluded entirely**, and it **drags resale**. It is checked against **council flood mapping and historical flood records** (the suburb-enrichment feeds), not assumed from the band alone. A `high` band is a `key_concern` that the agent surfaces with its insurance and resale consequences; `unknown` means *go and check the council maps*, not *no risk*. (The insurance *binding date* on the property is owned by `kb.insurance.timing-of-risk-pass`; this doc owns the suburb-level *insurability/affordability* signal.)
- **Planning changes pending (`planning_changes_pending`) — cuts both ways.** Pending rezoning, overlays or major infrastructure can **lift** value (upzoning, a new station, urban renewal) or **impair** it (high-density development overshadowing a low-rise street, a heritage overlay restricting renovation, an industrial / flight-path / road-widening overlay). The agent **surfaces** each pending change and its direction — it does not pre-judge; some are strengths, some concerns.
- **School catchment quality (`school_catchment_quality`).** A strong catchment supports both **family demand** and **resale**, and matters disproportionately to family buyers. Catchment **boundaries can change**, so the plan flags the property's *current* zoning and notes the boundary is not permanent.
- **Transport score (`transport_score`).** Proximity to transit and employment supports demand and value — but check the **downside of being too close** (rail-line or arterial-road noise, a station-precinct development pipeline).
- **Vietnamese-community proximity (`vietnamese_community_proximity`) — the Mode-A strength signal.** Proximity to an established Vietnamese community (measured from **ABS Census ancestry** data plus the presence of language, food, religious and family networks) is a genuine **lifestyle and resale strength** for a Mode-A buyer — the platform's distinctive layer. It is **not** a risk; it reads into `key_strengths`, and a `high` reading is a positive the agent surfaces explicitly.

## Relevance for Vietnamese-Australian buyers (Mode A)

- **Flood risk is the suburb fact that costs real money.** A first-home buyer stretched on deposit and serviceability cannot absorb an uninsurable or premium-loaded holding cost; the plan elevates a high flood band, points the buyer at the council maps and historical records, and ties it to insurance and resale — before the offer, not after.
- **Community proximity is a real strength, surfaced plainly.** For many Mode-A buyers, proximity to the Vietnamese community is decisive — language, food, places of worship, family nearby. The plan treats it as a first-class `key_strength` (grounded in ABS ancestry data), not a soft preference.
- **Pending planning changes are surfaced, not pre-judged.** A nearby upzoning may be the buyer's upside or the reason the quiet street won't stay quiet; the plan lays out each change and its likely direction and lets the buyer weigh it.
- **Catchment and transport in the buyer's terms.** Strong school zoning and transport access are framed as resale and lifestyle strengths, with the boundary-can-change and noise-downside caveats stated.
- **Information, not advice.** The plan reads public suburb data into strengths and concerns and points the buyer to the council, the school authority and the state planning portal; it does not predict price movement or guarantee a catchment, an insurance outcome or a rezoning.

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **reference doc** — it fills no slot. The `location_factors` values are produced by **suburb enrichment**; this doc supplies the framework the `property_assessment` agent reasons with to fold them into `key_concerns` / `key_strengths` / `viability_verdict`.

```jsonc
{
  "fills": [],
  "parameters": {
    "flood_risk_affects_insurability_and_resale": { "type": "bool", "value": true, "note": "CONVENTION (the load-bearing param) — a high flood band raises home-insurance premiums or sees flood cover excluded, and drags resale; check council flood mapping + historical records, don't infer from the band alone. 'unknown' means go and check, not no risk. Insurance binding date is owned by kb.insurance.timing-of-risk-pass; this doc owns the suburb-level insurability/affordability signal." },
    "planning_changes_cut_both_ways": { "type": "bool", "value": true, "note": "CONVENTION — pending rezoning/overlays/infrastructure can lift value (upzoning, new station, renewal) or impair it (high-density overshadowing, heritage overlay limiting renovation, industrial/flight-path/road-widening). Surface each change and its direction; do not pre-judge." },
    "vietnamese_community_proximity_is_a_strength": { "type": "bool", "value": true, "note": "CONVENTION (the Mode-A differentiator) — proximity to an established Vietnamese community (ABS Census ancestry + language/food/religious/family networks) is a lifestyle and resale STRENGTH, not a risk; a 'high' reading reads into key_strengths and the agent surfaces it explicitly." },
    "school_catchment_supports_demand_and_resale": { "type": "bool", "value": true, "note": "CONVENTION — a strong school catchment supports family demand and resale; matters disproportionately to family buyers. Catchment boundaries can change — flag the property's CURRENT zoning, not a permanent guarantee." },
    "transport_proximity_supports_value_with_a_downside": { "type": "bool", "value": true, "note": "CONVENTION — proximity to transit/employment supports demand and value, but check the downside of being too close (rail/arterial noise, station-precinct development pipeline)." }
  },
  "lookup": {
    "suburb_factor_read": {
      "note": "CONVENTION — how the agent reads each location factor into the viability verdict, its data source (suburb enrichment), and whether it is primarily a risk or a strength signal.",
      "entries": [
        { "factor": "flood_risk_band", "data_source": "state flood mapping + council historical records (suburb enrichment)", "direction": "risk", "reads_into": "key_concerns — insurability, premiums, resale (load-bearing)" },
        { "factor": "planning_changes_pending", "data_source": "state planning portal / DA & overlay feeds (suburb enrichment)", "direction": "both", "reads_into": "key_strengths or key_concerns per change direction" },
        { "factor": "school_catchment_quality", "data_source": "state education / catchment + ACARA (suburb enrichment)", "direction": "strength", "reads_into": "key_strengths — family demand, resale (boundary can change)" },
        { "factor": "transport_score", "data_source": "transit/accessibility scoring (suburb enrichment)", "direction": "strength", "reads_into": "key_strengths — demand/value (check noise downside)" },
        { "factor": "vietnamese_community_proximity", "data_source": "ABS Census ancestry (ANCP) + community amenities (suburb enrichment)", "direction": "strength", "reads_into": "key_strengths — Mode-A lifestyle + resale (not a risk)" }
      ]
    },
    "flood_band_action": {
      "note": "CONVENTION — how the agent treats each flood_risk_band value.",
      "entries": [
        { "band": "none", "action": "no flood concern; standard insurance expected" },
        { "band": "low", "action": "note; confirm standard flood cover available" },
        { "band": "medium", "action": "flag; obtain an insurance quote before committing; factor premium into holding cost" },
        { "band": "high", "action": "key_concern — premiums elevated or flood cover excluded; check council maps + historical records; weigh resale impact" },
        { "band": "unknown", "action": "go and check council flood mapping — absence of data is not absence of risk" }
      ]
    }
  }
}
```

Notes:

- **No `fills`.** No outcome leaf is set. The `location_factors` values come from **suburb enrichment**; this doc grounds the `property_assessment` agent's reasoning (`reasoning_domain: valuation` / viability) that turns them into `key_concerns` / `key_strengths` / `viability_verdict`. Same pure-reference shape as the other `property_assessment` anchors.
- **Flood risk is the load-bearing param.** Of the five factors it is the one with a hard financial edge (insurability, premium, resale) for a leveraged first-home buyer, so it is lifted into an explicit parameter and given its own band→action lookup.
- **Community proximity is a strength, not a risk — stated as such.** The Mode-A differentiator is encoded as a positive signal so the agent surfaces it as a `key_strength`, never miscategorised as a concern.
- **CONVENTION / framework; values INDICATIVE and data-sourced.** This doc holds *how to read* the factors, not the figures; the figures arrive per-suburb from enrichment (ABS Census ancestry/demographics, state flood/planning/education feeds — the narrow data paths, not scraping). Each is INDICATIVE and the agent surfaces the data source.
- **Single-owner across the property cluster.** This doc owns **suburb-level location factors**. The **dwelling's per-type risk** → `kb.building-types.risk-by-type`; **strata health** → `kb.strata.health-indicators` / `kb.strata-report.red-flags`; **price / comparables** → `kb.property.comparables-methodology`; **insurance binding date** → `kb.insurance.timing-of-risk-pass`. Cross-ref, not duplicated.

## Sources

**Canonical (data sources and risk framework):**

- Australian Bureau of Statistics — *2021 Census QuickStats* and *Community Profiles* (Ancestry multi-response variable ANCP — the basis for Vietnamese-community proximity; SAL-level demographics) — https://www.abs.gov.au/census/guide-census-data/about-census-tools/quickstats and https://www.abs.gov.au/census/guide-census-data/about-census-tools/community-profiles
- Moneysmart (ASIC) — *Storm, flood and fire insurance* (high flood risk → higher premiums or excluded flood cover; contact the local council for flood mapping and historical records) — https://moneysmart.gov.au/home-insurance/storm-flood-and-fire-insurance
- National Emergency Management Agency — *Hazards Insurance Partnership* (Commonwealth work on natural-hazard risk and insurance affordability) — https://www.nema.gov.au/our-work/resilience/hazards-insurance-partnership

**Canonical (suburb-enrichment feeds — named by authority; deep paths resolved at ingestion):**

- State flood mapping and historical flood records — the relevant state portal and local council (e.g. QLD FloodCheck; NSW flood data; VIC flood overlays via the state planning map). Named as the enrichment source; exact endpoints resolved by the suburb-enrichment ingestion jobs, not cited as fixed URLs here.
- State planning portals — pending rezoning, overlays and development-application feeds (the relevant state planning authority and council).
- State education authorities and ACARA — school-catchment zoning and school data.

**Point-in-time / practice (INDICATIVE):**

- All per-suburb values (flood band, catchment quality, transport score, community proximity, pending planning changes) are **data-sourced and INDICATIVE** — read against the specific suburb at fill time, surfaced with their source, and never presented as a prediction of price, insurability or a rezoning outcome.
