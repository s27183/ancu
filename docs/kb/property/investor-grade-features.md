---
slug: kb.property.investor-grade-features
effective_from: 2025-07-01
last_verified: 2026-06-23
---

# Investor-grade features — what makes a property fit for investment

A property that is a fine *home* is not automatically a fine *investment*. Investment fitness turns on a distinct set of physical and locational attributes — **land content, rentability, low holding-cost, and broad tenant appeal** — that drive yield, growth, and the durability of demand. This doc owns the **feature framework** the agent reasons over to populate `property_assessment.investor_grade_features.*` and the `investor_grade_overall` / `land_quality_score` verdicts. It is a **reference** doc: it describes *which* features matter and *why*, leaving the per-property scoring to agent reasoning and the actual figures to the property data. Decision-support — it grades against criteria, it does not declare a property "the best buy".

## The feature dimensions

- **Land content (land-to-asset ratio).** Land appreciates; buildings depreciate. A higher **land-to-asset ratio** (land value as a share of total price) is the classic capital-growth driver — which is why a house on land typically out-grows a high-density apartment over the long run, all else equal. (`land_to_asset_ratio`.)
- **Rentability — bedrooms, living areas, parking, outdoor space.** Broad tenant appeal widens the demand pool and shortens vacancy: a sensible **bedroom count** for the area, separate/usable **living areas**, secure **parking** (a strong driver in most markets), and usable **outdoor space**. (`rentable_bedroom_count`, `rentable_living_areas`, `parking_quality`, `outdoor_space_quality`.)
- **Dual-income / value-add potential.** A floorplan that supports a granny flat, dual occupancy, or a cosmetic renovation can lift yield or value — relevant to the `dual_income` / `value_add` strategy archetypes, surfaced as potential, not assumed.
- **Low holding cost.** Features that *reduce* recurring cost are investor-grade too: a low-maintenance build and (for strata) a healthy, well-run scheme with proportionate levies — because a high levy or a maintenance-heavy dwelling erodes net yield (cross-ref [`kb.strata.health-indicators-investor-lens`](../strata/health-indicators-investor-lens.md) and [`kb.investor.operating-expenses-typical-ratios`](../investor/operating-expenses-typical-ratios.md)).
- **Broad-market resale appeal.** Mainstream, liquid attributes (a configuration the widest pool of future buyers wants) protect resale; idiosyncratic or over-capitalised properties are harder to exit.

## Yield vs growth — the features pull differently

Investor-grade is not one axis. **Land content and broad appeal favour capital growth**; **bedroom/parking/dual-income features favour yield**. A property strong on one may be weak on the other, which is exactly the trade-off the investment thesis (owned by `kb.investor.strategy-archetypes`, Cluster S) has to resolve. This doc surfaces both so the agent can match features to the chosen archetype rather than scoring a single "good/bad".

## Relevance for Vietnamese-Australian investors (Mode C)

- **Land content is the growth lever.** The plan weights the land-to-asset ratio as the primary long-run growth feature, helping a buyer see why a house often out-grows an apartment — without dismissing apartments where yield or entry price is the goal.
- **Rentability shortens vacancy.** Parking, sensible bedrooms, and usable outdoor space widen tenant demand; the plan reads these as vacancy-reducing features, tying them back to the income model.
- **Features must match the thesis.** The plan presents yield-leaning vs growth-leaning features against the investor's strategy archetype, rather than a single grade — so the fit is to *this* investor's goal.
- **A grade, not a recommendation.** `investor_grade_overall` is a decision-support score against these criteria; the plan does not tell the buyer to purchase.

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **reference** doc — it fills no slot; the `investor_grade_features` parameters carry property facts, and `investor_grade_overall` / `land_quality_score` are **agent-reasoned** against this framework. No verdict is asserted here.

```jsonc
{
  "fills": [],
  "parameters": {
    "land_content_is_primary_growth_feature": { "type": "bool", "value": true, "note": "CONVENTION — a higher land-to-asset ratio is the classic long-run capital-growth driver (land appreciates, buildings depreciate); houses typically out-grow high-density apartments, all else equal" },
    "rentability_features": { "type": "array<string>", "value": ["sensible_bedroom_count_for_area", "separate_usable_living_areas", "secure_parking", "usable_outdoor_space"], "note": "CONVENTION — features that widen the tenant pool and shorten vacancy (yield-leaning)" },
    "dual_income_value_add_potential": { "type": "bool", "value": true, "note": "CONVENTION — granny-flat / dual-occupancy / cosmetic-reno potential can lift yield or value; surfaced as potential for the dual_income/value_add archetypes, not assumed" },
    "low_holding_cost_is_investor_grade": { "type": "bool", "value": true, "note": "CONVENTION — low-maintenance build and (strata) a healthy scheme with proportionate levies reduce recurring cost and protect net yield (cross-ref kb.strata.health-indicators-investor-lens, kb.investor.operating-expenses-typical-ratios)" },
    "broad_resale_appeal": { "type": "bool", "value": true, "note": "CONVENTION — mainstream, liquid attributes protect resale; idiosyncratic/over-capitalised properties are harder to exit" },
    "yield_vs_growth_features_differ": { "type": "string", "value": "land content + broad appeal → growth; bedrooms/parking/dual-income → yield", "note": "the dimensions pull differently — match features to the investment thesis (kb.investor.strategy-archetypes), don't score a single good/bad" },
    "grade_is_decision_support": { "type": "bool", "value": true, "note": "investor_grade_overall is a score against criteria, not a buy recommendation — agent-reasoned, decision-support" }
  }
}
```

Notes:

- **No `fills`.** No outcome leaf is set by a KB rule; the feature parameters carry property facts and the overall grade is agent-reasoned against this framework.
- **Two axes, not one.** Growth-leaning (land, broad appeal) and yield-leaning (bedrooms, parking, dual-income) features are surfaced separately so they can be matched to the strategy archetype, not collapsed into a single grade.
- **Single-owner via cross-ref.** Holding-cost features point to `kb.strata.health-indicators-investor-lens` and `kb.investor.operating-expenses-typical-ratios`; archetype matching to `kb.investor.strategy-archetypes`. This doc owns the *feature framework*.

## Sources

- ASIC Moneysmart — *Investing in property* (location, capital growth, rental demand and ongoing costs as the factors in a property's investment merit) — https://moneysmart.gov.au/property-investment/investing-in-property
- ATO — *Residential rental properties* (the property as an income-producing asset — context for the rentability and holding-cost features) — https://www.ato.gov.au/individuals-and-families/investments-and-assets/property-and-land/residential-rental-properties
