---
slug: kb.tax.depreciation-division-43-and-40
effective_from: 2025-07-01
last_verified: 2026-06-23
---

# Depreciation — capital works (Div 43) and plant & equipment (Div 40)

A rental property generates two **non-cash** deductions that decline its taxable income without an annual outlay: **capital works deductions (Division 43)** on the building's structure, and **decline in value of depreciating assets (Division 40)** on the plant and equipment inside it. This doc owns **the two depreciation streams, their rates, the 9 May 2017 second-hand-plant restriction, and the CGT cost-base clawback on disposal** so the `tax_structure` component's **depreciation** figure and the `disposition` component's **cost-base / clawback** are **resolver-computed** from ATO rates — never authored by the LLM, and substantiated by a quantity surveyor's report ([`kb.tax.quantity-surveyor-reports`](quantity-surveyor-reports.md)), not estimated by the plan. Statutory rates to confirm with a registered tax agent / the ATO; informational only.

## Two streams, two rules

| Stream | What it covers | Rate | Period |
|---|---|---|---|
| **Division 43 — capital works** | the building's **structure** and fixed structural improvements (walls, roof, built-in fixtures) | **2.5%** per year (residential built after 15 Sept 1987); **4%** for certain structures | 40 years (or 25 years at 4%) |
| **Division 40 — plant & equipment** | removable / mechanical **depreciating assets** (carpet, blinds, oven, air-conditioner, hot-water system) | each asset's own **effective life** (ATO-determined or self-assessed) | per-asset |

Division 43 is a flat percentage of the **original construction cost** (not the purchase price, not the land); Division 40 is the decline in value of each asset over its effective life. The land itself is never depreciable.

## The 9 May 2017 second-hand-plant restriction

For a **residential** rental property **acquired on or after 7:30pm AEST on 9 May 2017**, an investor **cannot** claim Division 40 decline-in-value on **previously used (second-hand)** plant and equipment that came with the property. The Division 40 stream then applies only to **assets the investor buys new** for the property (a new oven, new carpet) and to **brand-new builds**. **Division 43 capital works is unaffected** — the structural 2.5% deduction continues regardless of when the property was acquired or whether the building is new. Investors who **acquired before** 7:30pm AEST 9 May 2017 retain the second-hand plant deductions. This is the single rule that most changes whether an established vs new property carries meaningful Division 40 depreciation.

## The disposition clawback — depreciation reduces the CGT cost base

Depreciation is not free on disposal. **Capital works deductions claimed (or claimable) reduce the property's CGT cost base**, which **increases the taxable capital gain** on sale — a clawback the `disposition` projection must account for so the after-tax sale proceeds are not overstated. Division 40 assets are handled by a **balancing adjustment** when the property is sold rather than through the cost base. Because the exact clawback depends on the construction-cost basis, the years claimed, and the QS schedule, the resolver returns **`to_verify`** for the precise clawback figure (deferring to a registered tax agent), while still **flagging** that depreciation claimed will increase the gain — it surfaces the mechanism, it does not assert a dollar clawback.

## Relevance for Vietnamese-Australian investors (Mode C)

- **Depreciation is the non-cash deduction that widens the tax–cash gap.** It can push a property into a negative *tax* position while it sits near cash-neutral (see [`kb.tax.negative-gearing-mechanics`](negative-gearing-mechanics.md)) — surfaced as both, never conflated.
- **New vs established changes the Division 40 story.** Post-9-May-2017, an established property carries little second-hand plant depreciation; a new build or new assets do. The plan flags this difference rather than assuming a generic depreciation benefit.
- **A QS report is the substantiation, not the plan.** Meaningful depreciation claims require a quantity surveyor's schedule; the plan points to one and does not author the figures itself.
- **The clawback is named on disposal.** Depreciation claimed increases the taxable gain at sale; the plan surfaces this so the dispose-phase net proceeds reflect the cost-base reduction rather than treating depreciation as a pure win.
- **Information, not advice.** The plan states the streams, rates, the 2017 restriction, and the clawback, and points to a registered tax agent / QS; it computes no binding depreciation schedule and issues no recommendation.

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **reference doc** — it fills no slot; the depreciation figure is **resolver-computed** from these rates and the construction-cost / QS basis (control flow → code, per §11.9), and the disposition clawback is flagged with the precise figure deferred to `to_verify`. Every rate here is a regulated ATO constant.

```jsonc
{
  "fills": [],
  "parameters": {
    "div43_capital_works_rate_pct":      { "type": "percentage", "value": 2.5,  "note": "REGULATED (ATO, Div 43) — standard capital works deduction rate for residential construction after 15 Sept 1987; 2.5% of original construction cost per year over 40 years" },
    "div43_capital_works_years":         { "type": "integer",    "value": 40,   "note": "REGULATED (ATO) — capital works are written off over 40 years at 2.5% (or 25 years at 4% for certain structures)" },
    "div43_alt_rate_pct":                { "type": "percentage", "value": 4,    "note": "REGULATED (ATO) — alternative 4% rate over 25 years for certain structural improvement types" },
    "div43_basis":                       { "type": "string",     "value": "original construction cost (excludes land and purchase price)", "note": "REGULATED (ATO) — Div 43 applies to the construction cost of the building, not the land or the price paid" },
    "div40_method":                      { "type": "string",     "value": "decline in value over each asset's effective life", "note": "REGULATED (ATO, Div 40) — plant & equipment depreciate over their effective life (ATO-determined or self-assessed), per asset" },
    "secondhand_plant_restricted_from":  { "type": "string",     "value": "7:30pm AEST 9 May 2017", "note": "REGULATED (ATO) — for residential rental property acquired on/after this time, no Div 40 deduction on previously used (second-hand) plant; new assets and new builds are unaffected; Div 43 is unaffected" },
    "div43_reduces_cgt_cost_base":       { "type": "bool",       "value": true, "note": "REGULATED (ATO) — capital works deductions claimed (or claimable) reduce the CGT cost base, increasing the taxable gain on disposal (the clawback). Div 40 is handled by a balancing adjustment on sale" },
    "depreciation_disposition_figure":   { "type": "string",     "value": "flag that depreciation claimed increases the disposal gain; precise clawback = to_verify (defer to a tax agent / QS schedule)", "note": "the resolver verdict surface — surface the clawback mechanism, defer the dollar figure" }
  }
}
```

Notes:

- **No `fills`.** The depreciation figure is resolver-computed from the rates and the QS/construction-cost basis; the disposition clawback is flagged with the precise figure deferred to `to_verify`. The doc supplies the rates and rules, not a schedule.
- **REGULATED — verified against the ATO.** The Div 43 rate (2.5% / 40 years, 4% alternative), the Div 40 decline-in-value method, the 9 May 2017 second-hand-plant restriction, and the capital-works cost-base reduction were confirmed against the ATO *Capital works deductions*, *Depreciating assets in rental properties*, and *Second-hand depreciating assets* pages (verified 2026-06-23).
- **The 2017 restriction is the load-bearing branch.** Whether a property carries second-hand plant depreciation depends on the acquisition date and new/established status — the resolver branches on it rather than assuming a generic Div 40 benefit.
- **The clawback links to disposition.** Depreciation claimed reduces the CGT cost base (increases the gain); `fh_engine_disposition` consumes this flag in the investor cgt branch alongside `kb.tax.cgt-50-percent-discount`, deferring the precise dollar clawback to `to_verify`.

## Sources

**Canonical (Australian Taxation Office):**

- ATO — *Capital works deductions* (2.5% over 40 years, or 4% over 25 years; the building structure, not the land) — https://www.ato.gov.au/businesses-and-organisations/income-deductions-and-concessions/depreciation-and-capital-expenses-and-allowances/capital-works-deductions
- ATO — *Depreciating assets in rental properties* (Division 40 decline in value over each asset's effective life) — https://www.ato.gov.au/individuals-and-families/investments-and-assets/property-and-land/residential-rental-properties/rental-expenses/depreciating-assets-in-rental-properties
- ATO — *Second-hand depreciating assets* (no Div 40 deduction on previously used plant for residential rental property acquired on/after 7:30pm AEST 9 May 2017; new assets and new builds unaffected) — https://www.ato.gov.au/individuals-and-families/investments-and-assets/property-and-land/residential-rental-properties/rental-expenses/depreciating-assets-in-rental-properties/second-hand-depreciating-assets
- ATO — *Work out your capital works deductions* (capital works deductions reduce the CGT cost base) — https://www.ato.gov.au/individuals-and-families/investments-and-assets/property-and-land/residential-rental-properties/rental-expenses/capital-expenses/work-out-your-capital-works-deductions
