---
slug: kb.tax.quantity-surveyor-reports
effective_from: 2025-07-01
last_verified: 2026-06-23
sources:
  - url: https://www.ato.gov.au/individuals-and-families/investments-and-assets/property-and-land/residential-rental-properties/rental-expenses/depreciating-assets-in-rental-properties
    retrieved: 2026-06-23
  - url: https://www.ato.gov.au/law/view/document?docid=TXR/TR9725/NAT/ATO/00001
    retrieved: 2026-06-23
---

# Quantity surveyor tax depreciation schedules

A **tax depreciation schedule** prepared by a qualified **quantity surveyor (QS)** is the document that substantiates a property investor's depreciation claims — both **capital works (Division 43)** and **plant & equipment (Division 40)** — over the life of the asset. This doc owns **what the schedule is, why a QS is the recognised preparer, when one is needed, and its (indicative) cost** so `tax_structure` knows the depreciation claim must be QS-substantiated (not plan-estimated) and `cash_position` / `due_diligence` can size and sequence the report. It is the procurement/cost companion to [`kb.tax.depreciation-division-43-and-40`](depreciation-division-43-and-40.md) (which owns the *rates*). Informational; the schedule itself is prepared by a licensed QS, not the plan.

## Why a quantity surveyor

The **ATO recognises quantity surveyors** (under **Tax Ruling TR 97/25**) as one of the few professions with the **construction-costing expertise** required to estimate building and asset costs for depreciation purposes where the investor does not have the actual construction costs. A real-estate agent's appraisal, a valuation, or the purchase price cannot substitute — depreciation on the *construction cost* (Div 43) and the *effective life of assets* (Div 40) must be professionally estimated. This is why the plan **defers the depreciation figure to a QS schedule** rather than estimating it (the [remove-from-reach discipline]): the schedule, not the plan, produces the claimable numbers.

## When a schedule is worth obtaining

A QS schedule is generally worthwhile for an investment property that carries meaningful depreciation — typically **newer buildings** (more Div 43 capital works remaining) and properties with **depreciable plant** the investor is entitled to claim (subject to the 9 May 2017 second-hand-plant restriction owned by the depreciation doc). For an older established property bought after 9 May 2017 with little new plant, the benefit is thinner — the plan flags this rather than assuming a schedule always pays off. The schedule is a **once-off** report covering the life of the asset (updated only if significant capital works are added).

## Cost (indicative) and deductibility

A residential tax depreciation schedule typically costs **~$385–$770** (a standard established home commonly ~$590–$770); the figure is an **INDICATIVE market band** (no regulator publishes QS fees). The fee is itself **tax-deductible**. The plan surfaces the cost as a small upfront due-diligence/setup outlay and notes it is recoverable via the deduction — it does not promise a specific depreciation return (that depends on the property and is the QS's determination).

## Relevance for Vietnamese-Australian investors (Mode C)

- **The depreciation figure comes from the QS, not the plan.** The plan states depreciation is QS-substantiated and sizes the report cost; it does not author a claimable depreciation figure.
- **New vs established changes the value.** A newer property warrants a schedule more than an older established one post-2017 — the plan flags the difference rather than assuming a uniform benefit.
- **Small cost, deductible, once-off.** ~$385–$770, tax-deductible, covering the life of the asset — surfaced as a due-diligence outlay.
- **Information, not advice.** The plan points to a qualified QS; it computes no binding depreciation schedule.

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **reference doc** — it fills no slot; the report cost is **placed by the resolver** as a banded figure and the depreciation claim is **deferred to the QS schedule** (not plan-estimated). The QS recognition is a regulated ATO fact; the cost is an INDICATIVE market band.

```jsonc
{
  "fills": [],
  "parameters": {
    "qs_recognised_for_construction_costs": { "type": "bool", "value": true, "note": "REGULATED (ATO TR 97/25) — quantity surveyors are recognised to estimate construction costs for depreciation where actual costs are unknown; agent appraisals/valuations/price cannot substitute" },
    "depreciation_deferred_to_qs_schedule": { "type": "bool", "value": true, "note": "the depreciation figure is QS-substantiated, not plan-estimated (remove-from-reach); the plan sizes the report, not the claim" },
    "qs_schedule_is_once_off":              { "type": "bool", "value": true, "note": "a schedule covers the life of the asset; updated only if significant capital works are added" },
    "qs_schedule_fee_deductible":           { "type": "bool", "value": true, "note": "the QS schedule fee is itself tax-deductible" }
  },
  "lookup": {
    "qs_schedule_cost_band": {
      "note": "INDICATIVE residential QS depreciation schedule cost (market, no regulator publishes QS fees); resolver places a band, never a point quote",
      "entries": [
        { "scope": "residential_typical",      "cost": "385-770", "tier": "INDICATIVE" },
        { "scope": "established_home_standard", "cost": "590-770", "tier": "INDICATIVE" }
      ]
    }
  }
}
```

Notes:

- **No `fills`.** The report cost is placed by the resolver as a banded due-diligence/setup outlay; the depreciation claim is deferred to the QS schedule. The doc supplies the recognition fact and the cost band, not a depreciation figure.
- **Single-owner split.** Depreciation *rates / the 2017 restriction / the CGT clawback* are owned by `kb.tax.depreciation-division-43-and-40`; this doc owns the *report* (why a QS, when, cost). The settlement-phase *procurement timeline* is owned by the Cluster-S settlement docs (`kb.investor.depreciation-schedule-procurement`) — cross-ref, not duplicated.
- **Regulated recognition, indicative cost.** The QS recognition (TR 97/25) is a regulated ATO fact; the fee is an INDICATIVE market band.

## Sources

**Canonical (Australian Taxation Office):**

- ATO — *Depreciating assets in rental properties* (construction-cost estimates for depreciation; quantity surveyor's role) — https://www.ato.gov.au/individuals-and-families/investments-and-assets/property-and-land/residential-rental-properties/rental-expenses/depreciating-assets-in-rental-properties
- ATO — *Taxation Ruling TR 97/25* (qualified quantity surveyors recognised to estimate construction costs for capital works deductions) — https://www.ato.gov.au/law/view/document?docid=TXR/TR9725/NAT/ATO/00001

**Indicative market range (point-in-time, labelled INDICATIVE — verified 2026-06-23):**

- Quantity-surveyor published fee schedules (residential tax depreciation schedule ~$385–$770; established home commonly ~$590–$770) — band only; confirm a current quote with a qualified QS.
