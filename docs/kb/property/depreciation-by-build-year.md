---
slug: kb.property.depreciation-by-build-year
effective_from: 2025-07-01
last_verified: 2026-06-23
---

# Depreciation by build year — the property-attribute classification

How much **depreciation** an investment property carries is largely fixed by **when it was built** (and whether it is new or second-hand at purchase). This doc owns the **build-year → depreciation-eligibility classification** that fills the `property_assessment.depreciation_potential.*` parameters and feeds the `depreciation_attractiveness` verdict — the *property-attribute lens*. The **tax rules, rates, and the CGT clawback** are owned by [`kb.tax.depreciation-division-43-and-40`](../tax/depreciation-division-43-and-40.md); the **substantiating report** by [`kb.tax.quantity-surveyor-reports`](../tax/quantity-surveyor-reports.md). This doc maps a property's build year onto those rules — it asserts no rate and no dollar figure. Informational; a quantity surveyor's schedule is the binding basis.

## The two build-year cut-offs that decide eligibility

- **15 September 1987 — capital works (Division 43).** A residential building constructed **after 15 Sept 1987** carries the structural **2.5%/year capital-works deduction** (owned by the tax doc). Built **before** that date, the original structure generally has no Division 43 claim — though **post-1987 renovations/extensions** (even by a previous owner) can still be depreciable capital works. So `post_1987_capital_works_depreciable` is derived from the build year, with renovation history as a modifier.
- **9 May 2017, 7:30pm AEST — second-hand plant (Division 40).** For a property **acquired on/after** this time, **previously used** plant and equipment that came with it is **not** Division-40 depreciable; only assets the investor buys **new**, and **brand-new builds**, carry plant depreciation (owned by the tax doc). So `plant_and_equipment_depreciable` turns on **new vs established at purchase**, not just build year.

## The classification, by property condition

| Property at purchase | Division 43 (structure) | Division 40 (plant) | Attractiveness |
|---|---|---|---|
| **Brand-new build** (incl. off-the-plan, house & land) | Yes — full 2.5% from construction cost | **Yes** — full new plant | **Strong** |
| **Established, built after 15 Sept 1987** | Yes — 2.5% on remaining structure life | **No** second-hand plant (post-9-May-2017 rule); only new assets the investor adds | **Moderate** |
| **Established, built before 15 Sept 1987** | Generally no original-structure claim; **post-1987 renos** can qualify | No second-hand plant; only new assets added | **Weak** (unless substantially renovated) |

`estimated_annual_depreciation_year_1` is **resolver-computed** from the construction-cost basis and the tax-doc rates once a property is attached; this doc supplies the *eligibility classification*, the tax doc supplies the *rates*, and the QS report supplies the *actual schedule*.

## Relevance for Vietnamese-Australian investors (Mode C)

- **Build year sets the depreciation story before any inspection.** The plan classifies depreciation attractiveness from the year built and new/established status — so a buyer comparing a new apartment against a 1970s house sees the depreciation difference up front.
- **New vs established is the bigger lever than age alone.** The plan flags that the post-9-May-2017 rule strips second-hand plant from an established purchase, so a new build's depreciation advantage is structural, not just cosmetic.
- **Pre-1987 isn't always a dead end.** The plan notes that substantial post-1987 renovations on an old building can still carry capital-works deductions — a check, not an assumption.
- **The schedule comes from a QS, not the plan.** Attractiveness is a classification; the dollar figure needs a quantity surveyor's report (`kb.tax.quantity-surveyor-reports`). Information, not advice.

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **reference** doc — it fills no slot; the `depreciation_potential` predicates are **resolver-derived** from build year + new/established status against these cut-offs, and the dollar figure is computed from the tax-doc rates and the QS basis. No rate is declared here (single-owner with the tax doc).

```jsonc
{
  "fills": [],
  "parameters": {
    "div43_build_year_cutoff": { "type": "string", "value": "15 September 1987", "note": "REGULATED (ATO) — residential buildings constructed after this date carry Div 43 capital-works deductions; before it, only post-1987 renovations qualify. Rate/rule owned by kb.tax.depreciation-division-43-and-40" },
    "post_1987_predicate_rule": { "type": "string", "value": "post_1987_capital_works_depreciable = year_built > 1987-09-15 OR has_post_1987_renovations", "note": "resolver-derived predicate — build year with renovation history as a modifier" },
    "secondhand_plant_cutoff": { "type": "string", "value": "7:30pm AEST 9 May 2017", "note": "REGULATED (ATO) — property acquired on/after this time gets no Div 40 on previously used plant; only new assets / new builds. Rule owned by the tax doc; here it derives the plant predicate" },
    "plant_predicate_rule": { "type": "string", "value": "plant_and_equipment_depreciable = is_new_build OR assets_purchased_new_by_investor (post-9-May-2017 acquisition)", "note": "resolver-derived predicate — turns on new-vs-established at purchase, not build year alone" },
    "attractiveness_classification": { "type": "string", "value": "new_build → strong; established post-1987 → moderate; established pre-1987 (unrenovated) → weak", "note": "the depreciation_attractiveness enum derived from the classification table; a property-attribute verdict, not a dollar figure" },
    "year_1_figure_is_resolver_computed": { "type": "bool", "value": true, "note": "estimated_annual_depreciation_year_1 is resolver-computed from the construction-cost basis and the tax-doc rates; binding schedule = a QS report (kb.tax.quantity-surveyor-reports)" },
    "rates_owned_by_tax_doc": { "type": "string", "value": "kb.tax.depreciation-division-43-and-40", "note": "OWNED ELSEWHERE — Div 43 2.5%/40yr, Div 40 effective-life method, and the CGT cost-base clawback; this doc declares no rate, only the build-year eligibility mapping" }
  }
}
```

Notes:

- **No `fills`.** The depreciation predicates are resolver-derived from build year and new/established status; the dollar figure is resolver-computed from the tax-doc rates and the QS basis. The doc owns the *classification*, not the rate or the schedule.
- **Single-owner with the tax doc.** Rates, the 9-May-2017 restriction's tax effect, and the disposal clawback are owned by `kb.tax.depreciation-division-43-and-40`; the QS report by `kb.tax.quantity-surveyor-reports`. This doc maps a property's build year onto those rules — cross-ref, no rate duplicated.
- **The two cut-offs are the load-bearing facts.** 15 Sept 1987 (Div 43 eligibility) and 9 May 2017 (Div 40 second-hand restriction) together classify the property's depreciation; both are regulated ATO dates, verified in the tax doc.

## Sources

- ATO — *Capital works deductions* (residential construction after 15 Sept 1987 qualifies for the 2.5% capital-works deduction) — https://www.ato.gov.au/businesses-and-organisations/income-deductions-and-concessions/depreciation-and-capital-expenses-and-allowances/capital-works-deductions
- ATO — *Second-hand depreciating assets* (no Div 40 on previously used plant for residential rental property acquired on/after 7:30pm AEST 9 May 2017; new assets and new builds unaffected) — https://www.ato.gov.au/individuals-and-families/investments-and-assets/property-and-land/residential-rental-properties/rental-expenses/depreciating-assets-in-rental-properties/second-hand-depreciating-assets
