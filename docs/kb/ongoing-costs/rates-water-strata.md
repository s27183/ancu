---
slug: kb.ongoing-costs.rates-water-strata
effective_from: 2025-07-01
last_verified: 2026-07-06
sources:
  - url: https://moneysmart.gov.au/home-loans/buying-a-house
    retrieved: 2026-07-06
  - url: https://www.nsw.gov.au/housing-and-construction/strata/living/levies-finances-insurance
    retrieved: 2026-07-06
---

# Ongoing ownership costs — council rates, water, and strata levies

Beyond the mortgage, an owner-occupier carries recurring **statutory and building costs**: **council rates** (local-government charges on the property), **water rates** (a utility's service + usage charges), and — for apartments and townhouses — **strata levies** (the owners-corporation contributions that fund common-property running costs and a capital-works reserve). This doc owns **what each cost is and indicative ranges for budgeting**; it grounds `ownership_planning.quarterly_obligations.{council_rates, water_access_and_usage, strata_levies}`. The figures are **indicative ranges** — the binding numbers come from the property's rates notice and the strata disclosure; the **interpretation of strata health** (sinking-fund adequacy, red flags) is owned by `kb.strata.health-indicators` and `kb.strata-report.red-flags` (sibling anchors, to be authored under Components 2/6), not here.

## Council rates

- **What it is.** A local-government charge levied on each property, generally based on the land/property value (methods vary by council and state under the state Local Government Acts). It funds local services — waste, roads, parks. Usually **billed quarterly**, sometimes with a fixed base plus a valuation component.
- **Indicative range.** Commonly **~$1,200–$2,500 per year** for a typical metropolitan home — but it varies materially by council and property value. The exact figure is on the property's **rates notice**.

## Water rates

- **What it is.** A water utility charges a **fixed service/access charge** (for the connection, billed regardless of use) **plus a usage charge** (per kilolitre consumed). For houses the owner pays both; in many strata schemes the access charge sits with the owners corporation while usage may be separately metered — check the scheme.
- **Indicative range.** Commonly **~$800–$1,400 per year** combined (access + usage) for a household, varying by utility, household size and (for houses) garden/pool use.

## Strata levies (apartments and townhouses)

- **What it is.** Where the property is part of a strata/owners-corporation scheme, each owner pays **levies** in two funds: an **administrative fund** (day-to-day running of common property — insurance, cleaning, management, shared utilities) and a **capital-works / sinking fund** (a reserve for major future works — roof, lifts, repainting, structural). Usually **billed quarterly**.
- **Indicative range.** Highly variable: commonly **~$3,000–$6,000 per year** for a standard apartment, and **materially higher** for buildings with lifts, pools, gyms or concierge. The figure is disclosed in the **strata records**; whether the levy is *adequate* (a healthy sinking fund vs an under-funded one facing a special levy) is a **strata-health question** owned by `kb.strata.health-indicators`.

## Relevance for Vietnamese-Australian buyers (Mode A)

- **Strata levies are the hidden cost that changes the buy decision.** A Mode A buyer comparing an apartment against a house often anchors on the price and forgets the **$3k–$6k+/yr levy** — which can exceed council + water combined. The plan surfaces it as a standing quarterly obligation so the comparison is honest.
- **Levies bundle maintenance for strata properties.** Common-property maintenance is funded *through* the levy, so it must not be double-counted against a separate maintenance budget — see [`kb.maintenance.budget-by-property-type`](../maintenance/budget-by-property-type.md).
- **Information, not advice.** Ranges are for budgeting; the binding figures are the rates notice and strata disclosure, which the plan directs the buyer to obtain.

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **reference doc** — it fills no slot. The quarterly obligation figures are **resolver/agent estimates** from these indicative ranges (and the actual rates notice / strata disclosure when a property is attached); the doc supplies the cost definitions and the order-of-magnitude bands.

```jsonc
{
  "fills": [],
  "parameters": {
    "council_rates_billed":              { "type": "string", "value": "quarterly", "note": "CONVENTION — council rates usually billed quarterly; basis (land/property value + fixed charge) varies by council under state Local Government Acts" },
    "council_rates_indicative_aud_year_low":  { "type": "money", "value": 1200, "note": "INDICATIVE — lower end of typical annual council rates for a metro home; binding figure is the property's rates notice" },
    "council_rates_indicative_aud_year_high": { "type": "money", "value": 2500, "note": "INDICATIVE — upper end; varies materially by council and property value" },
    "water_indicative_aud_year_low":     { "type": "money", "value": 800,  "note": "INDICATIVE — lower end of typical combined water access + usage per year for a household; utility-dependent" },
    "water_indicative_aud_year_high":    { "type": "money", "value": 1400, "note": "INDICATIVE — upper end; varies by utility, household size and (houses) garden/pool use" },
    "strata_two_funds":                  { "type": "array<string>", "value": ["administrative_fund", "capital_works_sinking_fund"], "note": "strata levies split into an admin fund (day-to-day common-property running) and a capital-works/sinking fund (reserve for major future works)" },
    "strata_levy_indicative_aud_year_low":  { "type": "money", "value": 3000, "note": "INDICATIVE — typical lower end of annual strata levies for a standard apartment; binding figure is the strata disclosure" },
    "strata_levy_indicative_aud_year_high": { "type": "money", "value": 6000, "note": "INDICATIVE — typical upper end; materially higher with lifts/pool/gym/concierge — wide variance, treat as orientation only" }
  }
}
```

Notes:

- **No `fills`.** No outcome leaf is set. The quarterly obligations are resolver/agent estimates from these bands (refined by the actual rates notice and strata disclosure once a property is attached). The doc supplies definitions and indicative ranges.
- **All figures INDICATIVE or CONVENTION — none statutory.** Council/water/strata costs are set per council, per utility and per scheme; no regulator publishes a single figure. Tagged so the agent presents "typically ~$X–$Y / confirm on the notice," never as a fixed amount.
- **Single-owner: cost vs interpretation.** This doc owns the levy as a **recurring cost line**. Whether a scheme's levy/sinking fund is **healthy or a red flag** is owned by `kb.strata.health-indicators` / `kb.strata-report.red-flags` — cross-ref, not duplicated.
- **No double-counting with maintenance.** Strata levies already fund common-property maintenance, so the separate maintenance budget in [`kb.maintenance.budget-by-property-type`](../maintenance/budget-by-property-type.md) applies to the interior only for strata properties — flagged so the two cost docs don't stack the same expense twice.

## Sources

**Canonical (regulator / government — concepts and definitions):**

- ASIC Moneysmart — *Buying a house* (the ongoing costs of owning a home: council rates, water, insurance, strata fees and maintenance) — https://moneysmart.gov.au/home-loans/buying-a-house
- NSW Government — *Your strata levies, finances and insurance* (strata levies are normally paid quarterly and kept in separate funds; they pay for maintenance and repairs to the building and common property) — https://www.nsw.gov.au/housing-and-construction/strata/living/levies-finances-insurance
- Consumer Affairs Victoria — *Fees — owners corporations* (annual fees cover general administration, maintenance, insurance and other ongoing costs; special fees set separately) — https://www.consumer.vic.gov.au/housing/owners-corporations/finance-insurance-and-record-keeping/fees
- Queensland Government — *Funds for managing a body corporate* (a body corporate must have an administrative fund and a sinking fund; the sinking fund reserves for major future spending) — https://www.qld.gov.au/law/housing-and-neighbours/body-corporate/finance-insurance/funds

**Indicative cost ranges** — vary by council/utility/scheme; the binding figures are the property's rates notice and strata disclosure. The ranges above are order-of-magnitude budgeting bands, not published rates.
