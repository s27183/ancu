---
slug: kb.investor.vacancy-rate-assumptions
effective_from: 2025-07-01
last_verified: 2026-06-23
---

# Vacancy-rate assumptions — methodology + labelled-placeholder default

A cash-flow projection over a multi-year hold must assume some **vacancy** — the fraction of the year a property sits un-let between tenancies. This doc owns the **vacancy assumption** the resolver applies in [`kb.investor.rental-income-modelling`](rental-income-modelling.md) to bridge gross rent to *effective* rent. There are two cases, handled differently: a **suburb-specific** vacancy rate when the suburb data carries one (sourced, used as-is), and a **conservative default planning band** when it doesn't — and that default is a **labelled placeholder**, not yet wired to a live series. Decision-support, never a forecast of a particular property's occupancy.

> **⚠ The default band is a LABELLED PLACEHOLDER.** When no suburb-specific vacancy figure is available, the resolver falls back to the conservative default band below. That band is **not** drawn from a live, per-suburb authoritative feed yet — it is a deliberately conservative planning assumption held so the income model has a vacancy input. Before a per-suburb figure is surfaced as sourced, the assumption **must** be re-grounded against a named series (candidates: **SQM Research vacancy rates**, **REIA** / state REI vacancy data, **CoreLogic**, or state **rental bond board** turnover data). Until then the resolver surfaces income computed on the default as a **banded estimate with the vacancy assumption stated in `key_assumptions`**, never as a property-specific occupancy claim.

## Two cases

1. **Suburb-specific vacancy (preferred).** When `property_assessment.rental_market.rental_market_vacancy_rate_suburb` carries a figure from the suburb data, the resolver uses it directly — it is the property's real local market signal. This is the sourced path and carries no placeholder caveat (beyond the data's own provenance, owned by [`kb.property.rental-market-data-sources`](../property/rental-market-data-sources.md)).
2. **Default planning band (fallback, placeholder).** When no suburb figure is present, the resolver applies the conservative default band below.

## The conservative default band (placeholder, to be replaced)

Pending a per-suburb feed, the default is held **conservatively high relative to current actuals** so that, if used, it *under-promises* collected rent rather than over-promising:

- **Default vacancy assumption:** **~3%** (≈ 1.5 weeks un-let per year), within a planning band of **~2–4%**.

This is intentionally above recent national actuals: as a market-context anchor (not a per-property figure), SQM Research reported the **national residential vacancy rate at ~1.2–1.4%** through late 2025 / early 2026 — historically tight. A 2–4% planning band therefore errs on the side of caution. **These figures are placeholders for the default path** and must not be cited as a sourced per-suburb rate.

## Relevance for Vietnamese-Australian investors (Mode C)

- **Vacancy is the gap between lease rent and collected rent.** The plan reduces gross rent by the vacancy assumption so the cash flow reflects realistic occupancy, not a perfect 52 weeks let.
- **Suburb data beats the default.** Where the suburb carries a real vacancy figure, the plan uses it; the conservative default is only the fallback, and it is flagged as an assumption to confirm.
- **Conservative by design.** A default above current tight-market actuals keeps the income line honest; an optimistic vacancy figure would flatter the projection.
- **Re-grounding is a tracked obligation.** Because the default is a labelled placeholder, the freshness pass treats it as **stale-by-construction** until a named per-suburb series replaces it.

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **reference** doc — it fills no slot; the vacancy rate feeds the resolver's effective-income computation (in `kb.investor.rental-income-modelling`). The suburb-specific path is sourced; the default band is a labelled placeholder.

```jsonc
{
  "fills": [],
  "parameters": {
    "prefer_suburb_specific_vacancy": { "type": "bool", "value": true, "note": "use property_assessment.rental_market.rental_market_vacancy_rate_suburb when present (sourced, real local signal, kb.property.rental-market-data-sources); the default band is only the fallback" },
    "is_placeholder": { "type": "bool", "value": true, "note": "TRUE for the DEFAULT band — not drawn from a live per-suburb authoritative feed; re-ground before surfacing as a sourced rate" },
    "default_vacancy_assumed_pct": { "type": "percentage", "value": 3, "note": "PLACEHOLDER — conservative default vacancy assumption (~1.5 weeks/yr) when no suburb figure; within a 2–4% planning band; intentionally above recent ~1.2–1.4% national actuals to under-promise" },
    "default_vacancy_band_low_pct": { "type": "percentage", "value": 2, "note": "PLACEHOLDER — lower end of the default planning band" },
    "default_vacancy_band_high_pct": { "type": "percentage", "value": 4, "note": "PLACEHOLDER — upper end of the default planning band" },
    "national_vacancy_context_pct": { "type": "string", "value": "~1.2–1.4% (SQM Research, late 2025 / early 2026)", "note": "market-context anchor ONLY — national, not per-property; informs how conservative the default band is, not a figure to surface as the property's rate" },
    "surface_as": { "type": "string", "value": "banded income estimate with the vacancy assumption stated in key_assumptions; never a property-specific occupancy claim", "note": "decision-support discipline — an assumption, not a forecast" },
    "reground_against": { "type": "string", "value": "SQM Research vacancy rates | REIA / state REI vacancy data | CoreLogic | state rental bond board turnover", "note": "candidate authoritative series to replace the default placeholder; update last_verified on re-grounding" }
  }
}
```

Notes:

- **No `fills`.** No outcome leaf is set by a KB rule; the vacancy rate is an input to the resolver's effective-income formula (owned by `kb.investor.rental-income-modelling`).
- **Sourced path vs placeholder path.** The suburb-specific figure is sourced and used as-is; only the *default fallback band* is the labelled placeholder. Same honesty discipline as `kb.property.capital-growth-bands` — build the structure, label the unsourced datum.
- **Conservative default.** The default sits above current tight-market actuals so the income line under-promises; it is a planning assumption, not a per-property forecast.
- **Re-grounding obligation.** Replace the default band with a named per-suburb series and update `last_verified`; treat as stale-by-construction until then.

## Sources

- SQM Research — *Residential Vacancy Rates* (national and capital-city vacancy series — the market-context anchor; candidate re-grounding series) — https://sqmresearch.com.au/graph_vacancy.php?national=1&t=1
- ASIC Moneysmart — *Investing in property* (vacancy as a factor reducing rental return) — https://moneysmart.gov.au/property-investment/investing-in-property

**Per-suburb default band:** not yet wired to a live feed — labelled placeholder pending one of the candidate series above.
