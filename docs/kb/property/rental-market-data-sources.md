---
slug: kb.property.rental-market-data-sources
effective_from: 2025-07-01
last_verified: 2026-07-06
sources:
  - url: https://www.abs.gov.au/statistics/economy/price-indexes-and-inflation/total-value-dwellings/latest-release
    retrieved: 2026-07-06
  - url: https://sqmresearch.com.au/graph_vacancy.php?national=1&t=1
    retrieved: 2026-07-06
  - url: https://www.abs.gov.au/census/find-census-data/community-profiles/2021/AUS
    retrieved: 2026-07-06
---

# Rental market data — sources and provenance

The rental and growth figures an investor plan relies on — weekly rents, gross yields, vacancy rates, days-on-market, and historical capital growth — come from a small set of identifiable **data sources**, each with its own coverage, freshness, and reliability. This doc owns the **provenance map**: where each figure comes from, which sources are free/public vs paid/proprietary, and how to label reliability. It grounds the `property_assessment.rental_market.*` and `growth_indicators.*` figures and the `yield_modelling` income line by telling the agent and resolver **which source backs each number**. It is a **reference (source-list)** doc — it asserts no figure of its own, only the sourcing discipline. Informational.

## The sources, by figure

- **Weekly rents & rental yields** — **CoreLogic** and **PropTrack (REA Insights)** are the dominant commercial series (paid); **Domain** and **realestate.com.au** listing data give current asking rents; the **state rental bond authorities** (NSW Rental Bonds Online, Victoria RTBA, QLD RTA) hold *actual lodged-bond* rents — the most authoritative, if less timely. The agent's `estimated_weekly_rent_range` is grounded in comparable listings + bond data where available.
- **Vacancy rates** — **SQM Research** (free national/capital-city and some suburb series), **REIA** / state real-estate institutes, and **CoreLogic**. Per-suburb vacancy is the input to [`kb.investor.vacancy-rate-assumptions`](../investor/vacancy-rate-assumptions.md) (which falls back to a labelled-placeholder default when absent).
- **Historical capital growth (5/10-year)** — **ABS Total Value of Dwellings** (capital-city median prices + sale counts, free — the successor to the *Residential Property Price Indexes (RPPI)*, which ABS **discontinued after the December 2021 release**; the RPPI back-series remains a historical reference), **CoreLogic Home Value Index** (paid, suburb-level), and **state Valuer-General** median series. These are *historical* — they describe the past; the forward outlook is owned by [`kb.property.growth-corridors-au`](growth-corridors-au.md) and the projection band by [`kb.property.capital-growth-bands`](capital-growth-bands.md).
- **Days-on-market & tenant demand** — listing platforms (Domain, REA) and CoreLogic; these are market-temperature signals, treated as indicative.
- **Demographics & population** — **ABS** Census and Regional Population (free) — the Vietnamese-community proximity signal (ABS ancestry/ANCP) is the Mode-A/C differentiator, sourced here and surfaced as a *strength*.

## Free/public vs paid/proprietary — and the no-scraping line

- **Free / public:** ABS (Total Value of Dwellings [successor to the discontinued RPPI], Census, Regional Population), SQM Research (vacancy), state bond authorities, state Valuer-General.
- **Paid / proprietary:** CoreLogic, PropTrack/REA Insights, Domain analytics — richer suburb-level coverage, but licensed.

This doc is **provenance, not a pipeline**. Per the project's narrow-data-paths constraint, the platform does **not** scrape listing portals; rental/growth figures enter via **public feeds (ABS, bond authorities, SQM)**, **suburb enrichment**, **user-provided** data (a PM's rental appraisal, a listing the user pastes), and, where licensed, **partner/commercial feeds** — never a scraping pipeline.

## Reliability labelling

Every surfaced figure should carry, in effect, its provenance tier: **actual/lodged** (bond-authority rents — most authoritative), **published index** (ABS RPPI, SQM — reliable, periodic), **commercial estimate** (CoreLogic/PropTrack — broad coverage, modelled), and **listing/indicative** (asking rents, days-on-market — current but unverified). The agent presents figures with their reliability, and the binding rent figure for a specific property is a **property manager's written appraisal** (owned by `kb.investor.rental-appraisal-from-pm-agent`, Cluster S).

## Relevance for Vietnamese-Australian investors (Mode C)

- **Numbers carry their source.** The plan grounds each rental/growth figure in a named source and its reliability tier, so the investor knows whether a number is an actual lodged rent, a published index, or an indicative listing estimate.
- **Bond data is the most authoritative rent.** Where state bond-authority data is available, the plan leans on actual lodged rents over asking rents — the cleanest signal of what tenants really pay.
- **Community proximity is sourced from ABS.** The Vietnamese-community proximity strength comes from ABS Census ancestry data — a free, authoritative source, surfaced as a demand/liveability strength.
- **No scraping, by design.** Figures come from public feeds, suburb enrichment, and user/partner data — consistent with the platform's narrow-data-paths constraint; the property-specific binding figure is a PM appraisal.

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **reference (source-list)** doc — it fills no slot; it carries the provenance map the agent/resolver use to source and label `rental_market.*` / `growth_indicators.*` figures. It asserts no figure itself.

```jsonc
{
  "fills": [],
  "lookup": {
    "rental_market_data_sources": {
      "note": "provenance map — which source backs each figure, free vs paid, and reliability tier. FACTUAL landscape (the source list), not a figure assertion.",
      "entries": [
        { "figure": "weekly_rent / gross_yield", "free_public": ["state rental bond authorities (NSW RBO, VIC RTBA, QLD RTA) — actual lodged rents", "Domain/REA listings — asking rents"], "paid_proprietary": ["CoreLogic", "PropTrack (REA Insights)"], "binding": "a property manager's written rental appraisal (kb.investor.rental-appraisal-from-pm-agent)", "tier": "lodged > index > commercial estimate > listing" },
        { "figure": "vacancy_rate", "free_public": ["SQM Research", "REIA / state REIs"], "paid_proprietary": ["CoreLogic"], "binding": "per-suburb feed (else labelled-placeholder default, kb.investor.vacancy-rate-assumptions)", "tier": "published index" },
        { "figure": "historical_capital_growth_5_10yr", "free_public": ["ABS Total Value of Dwellings (successor to the RPPI, which ABS discontinued after Dec 2021; RPPI back-series remains a historical reference)", "state Valuer-General medians"], "paid_proprietary": ["CoreLogic Home Value Index (suburb-level)"], "binding": "historical only — forward outlook owned by kb.property.growth-corridors-au; projection band by kb.property.capital-growth-bands", "tier": "published index > commercial estimate" },
        { "figure": "days_on_market / tenant_demand", "free_public": ["listing platforms (indicative)"], "paid_proprietary": ["CoreLogic", "PropTrack"], "binding": "indicative market-temperature signal only", "tier": "listing/indicative" },
        { "figure": "demographics / population / community_proximity", "free_public": ["ABS Census (ancestry/ANCP)", "ABS Regional Population"], "paid_proprietary": [], "binding": "ABS — authoritative; community proximity surfaced as a STRENGTH (Mode-A/C differentiator)", "tier": "published index (census)" }
      ]
    },
    "no_scraping_paths": {
      "note": "data enters via narrow paths only — NOT a listing-scraping pipeline (project constraint)",
      "entries": [
        { "path": "public feeds", "examples": ["ABS", "state bond authorities", "SQM"] },
        { "path": "suburb enrichment" },
        { "path": "user-provided", "examples": ["PM rental appraisal", "user-pasted listing"] },
        { "path": "partner/commercial feeds (licensed)", "examples": ["CoreLogic", "PropTrack"] }
      ]
    }
  },
  "parameters": {
    "binding_rent_is_pm_appraisal": { "type": "bool", "value": true, "note": "the binding per-property rent figure is a property manager's written appraisal (kb.investor.rental-appraisal-from-pm-agent), not a data-series estimate" },
    "bond_data_is_most_authoritative_rent": { "type": "bool", "value": true, "note": "state rental-bond-authority lodged rents are the most authoritative rent signal (actual, not asking)" },
    "no_listing_scraping": { "type": "bool", "value": true, "note": "data enters via public feeds / suburb enrichment / user-provided / licensed partner feeds — NEVER a scraping pipeline (project narrow-data-paths constraint)" }
  }
}
```

Notes:

- **No `fills`.** No outcome leaf is set; the doc supplies the provenance map the agent/resolver use to source and label figures — it asserts no figure of its own.
- **FACTUAL source landscape.** The source list is a factual landscape (free vs paid, reliability tier), not a recommendation of a provider; figures carry their tier so the user sees actual-vs-estimated-vs-indicative.
- **Single-owner via cross-ref.** Vacancy default → `kb.investor.vacancy-rate-assumptions`; forward growth → `kb.property.growth-corridors-au` + `kb.property.capital-growth-bands`; binding rent → `kb.investor.rental-appraisal-from-pm-agent`. This doc owns the *provenance map*.
- **No-scraping line.** Consistent with the platform constraint, data enters only via public feeds, suburb enrichment, user-provided, and licensed partner feeds.

## Sources

- ABS — *Total Value of Dwellings* (free capital-city median prices + sale counts; the successor to the *Residential Property Price Indexes*, which ABS discontinued after the Dec 2021 release — historical growth provenance) — https://www.abs.gov.au/statistics/economy/price-indexes-and-inflation/total-value-dwellings/latest-release (RPPI back-series: https://www.abs.gov.au/statistics/economy/price-indexes-and-inflation/residential-property-price-indexes-eight-capital-cities)
- ABS — *Census* (ancestry/ANCP — the Vietnamese-community proximity signal) — https://www.abs.gov.au/census
- SQM Research — *Residential Vacancy Rates* (free national/capital-city vacancy series) — https://sqmresearch.com.au/graph_vacancy.php?national=1&t=1
- NSW Fair Trading — *Rental Bonds Online* (state-held lodged-bond rental data — actual rents) — https://www.nsw.gov.au/housing-and-construction/rental-bonds-online
