---
slug: kb.investor.cash-flow-tracking
effective_from: 2025-07-01
last_verified: 2026-06-23
---

# Cash-flow tracking

A cash-flow projection is a forecast; tracking is checking the forecast against what actually happened. This doc owns the **ongoing cash-flow tracking discipline** — what an investor records during the hold, how actual-vs-projected feeds the plan, and why lumpy events (vacancy, maintenance) need capturing. It grounds `ownership_planning_investor.cash_flow_tracking` (`monthly_net_cash_flow_actual_vs_projected`, `vacancy_events_to_date`, `maintenance_events_to_date`, `cumulative_cash_flow_year_to_date`). The **projection methodology** it's tracked against is owned by [`kb.investor.cash-flow-modelling-methodology`](cash-flow-modelling-methodology.md). It is a **reference** doc — it asserts no figure; the actuals are the investor's own data. Informational.

## What to track

- **Actual net cash flow vs projected.** Each period's actual income-minus-expenses against the modelled figure — the `comparison` that tells the investor whether the property is performing to thesis. A persistent negative variance is the signal to revisit the model or the property.
- **Vacancy events** — start, end, weeks vacant. These validate (or refute) the modelled vacancy rate ([`kb.investor.vacancy-rate-assumptions`](vacancy-rate-assumptions.md)); a string of vacancies means the placeholder default or the suburb assumption was wrong for *this* property.
- **Maintenance events** — date, cost, category. These accumulate against the modelled maintenance reserve ([`kb.investor.operating-expenses-typical-ratios`](operating-expenses-typical-ratios.md)); a capital-improvement (vs a repair) also flags a possible depreciation-schedule refresh ([`kb.investor.depreciation-schedule-procurement`](depreciation-schedule-procurement.md)).
- **Cumulative cash flow year-to-date** — the running total that feeds the annual tax return ([`kb.investor.annual-tax-return-investor`](annual-tax-return-investor.md)) and the next year's model.

## Why it matters

- **Closes the loop on a forecast.** The projection assumes rent, vacancy, and opex; tracking reveals whether those held. The model is only as good as its feedback.
- **Lumpy events average wrongly if not recorded.** Vacancy and maintenance are bursty — a single bad year looks catastrophic and a single good year looks fine. Tracking events over time builds the *actual* rate this property runs at, which beats the modelling default once enough history exists.
- **Feeds tax and the next decision.** The actuals are both the raw material for the annual return and the evidence base for portfolio review ([`kb.investor.portfolio-review-cadence`](portfolio-review-cadence.md)) and scale-up ([`kb.investor.scale-up-using-equity`](scale-up-using-equity.md)).
- **It records, it doesn't recompute.** Tracking *captures* actuals; the model and the tax calc consume them. The plan places the actuals against the projection — it never re-derives the projection from the actuals on the fly.

## Relevance for Vietnamese-Australian investors (Mode C)

- **See the thesis hold (or not).** The plan tracks actual net cash flow against the projection, so an under-performing property is caught early, not at tax time.
- **Real vacancy beats the assumption.** The plan records actual vacancy and maintenance events, building this property's true experience against the modelled defaults.
- **Tracking feeds the return and the next move.** The recorded actuals feed the annual return and the portfolio-review/scale-up decisions.
- **Recording, not re-forecasting.** The plan captures actuals against the projection; it doesn't quietly re-derive the forecast. Information, not advice.

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **reference** doc — it fills no slot; the tracking fields live in `ownership_planning_investor` and the actuals are the investor's own data. This doc supplies the tracking discipline.

```jsonc
{
  "fills": [],
  "parameters": {
    "track_actual_vs_projected": { "type": "bool", "value": true, "note": "each period's actual net cash flow vs the modelled figure; a persistent negative variance signals revisiting the model or the property" },
    "record_vacancy_events": { "type": "bool", "value": true, "note": "start/end/weeks — validate or refute the modelled vacancy rate (kb.investor.vacancy-rate-assumptions) for THIS property" },
    "record_maintenance_events": { "type": "bool", "value": true, "note": "date/cost/category against the maintenance reserve (kb.investor.operating-expenses-typical-ratios); a capital improvement flags a depreciation-schedule refresh (kb.investor.depreciation-schedule-procurement)" },
    "ytd_feeds_return_and_next_year": { "type": "bool", "value": true, "note": "cumulative cash flow YTD feeds the annual return (kb.investor.annual-tax-return-investor) and the next year's model" },
    "projection_methodology_owner": { "type": "string", "value": "kb.investor.cash-flow-modelling-methodology", "note": "OWNED ELSEWHERE — the projection this is tracked against; tracking captures actuals, the model/tax calc consume them" },
    "tracking_records_does_not_recompute": { "type": "bool", "value": true, "note": "place-don't-recompute — tracking captures actuals against the projection; it never re-derives the forecast on the fly" }
  }
}
```

Notes:

- **No `fills`.** The tracking fields live in `ownership_planning_investor`; the actuals are the investor's data. This doc supplies the discipline.
- **Single-owner via cross-ref.** Projection methodology → `kb.investor.cash-flow-modelling-methodology`; vacancy → `kb.investor.vacancy-rate-assumptions`; opex/maintenance → `kb.investor.operating-expenses-typical-ratios`; return → `kb.investor.annual-tax-return-investor`. This doc owns the tracking discipline.
- **Records, doesn't recompute.** Tracking captures actuals against the projection; the model and tax calc consume them — no on-the-fly re-derivation.

## Sources

- ASIC Moneysmart — *Investing in property* (keeping track of income and expenses; reviewing performance) — https://moneysmart.gov.au/property-investment/investing-in-property
- ATO — *Residential rental properties – keeping records* (records of income and expenses through the year) — https://www.ato.gov.au/individuals-and-families/investments-and-assets/property-and-land/residential-rental-properties
