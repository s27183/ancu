---
slug: kb.tax.quantity-surveyor-reports
effective_from: 2025-07-01
last_verified: 2026-10-27
sources:
  - url: https://www.ato.gov.au/individuals-and-families/investments-and-assets/property-and-land/residential-rental-properties/rental-expenses/depreciating-assets-in-rental-properties
    retrieved: 2026-10-27
    path: docs/sources/ato/depreciating-assets-in-rental-properties.txt
    quotes:
      - "A quantity surveyor can prepare a report at the time a rental property is purchased."
  - url: https://www.ato.gov.au/law/view/document?docid=TXR/TR9725/NAT/ATO/00001
    retrieved: 2026-10-27
    path: docs/sources/ato/tr-97-25.txt
    quotes:
      - "a quantity surveyor, who has expertise in the relevant type of construction;"
      - "27. Unless they are otherwise qualified, valuers, real estate agents, accountants and solicitors generally have neither the relevant qualifications nor experience to make such an estimate."
  - url: https://www.ato.gov.au/forms-and-instructions/rental-properties-2026/rental-expenses
    retrieved: 2026-10-27
    path: docs/sources/ato/rental-properties-2026-rental-expenses.txt
    quotes:
      - "Where a new owner can't precisely determine the construction expenditure associated with a building, an estimate provided by an appropriately qualified person may be used."
      - "quantity surveyor’s fees"
      - "For most depreciating assets you can choose to work out the effective life yourself or to use an effective life determined by the Commissioner of Taxation."
---

# Quantity surveyor tax depreciation schedules

A **tax depreciation schedule** prepared by a qualified **quantity surveyor (QS)** is the document that substantiates a property investor's depreciation claims — both **capital works (Division 43)** and **plant & equipment (Division 40)** — over the life of the asset. This doc owns **what the schedule is, why a QS is the recognised preparer, when one is needed, and its (indicative) cost** so `tax_structure` knows the depreciation claim must be QS-substantiated (not plan-estimated) and `cash_position` / `due_diligence` can size and sequence the report. It is the procurement/cost companion to [`kb.tax.depreciation-division-43-and-40`](depreciation-division-43-and-40.md) (which owns the *rates*). Informational; the schedule itself is prepared by a licensed QS, not the plan.

## Why a quantity surveyor

Where a new owner cannot work out the actual construction cost, the ATO accepts "an estimate provided by an appropriately qualified person" (*Rental properties 2026*). **Taxation Ruling TR 97/25** (para 28) lists who that can be: a quantity surveyor "who has expertise in the relevant type of construction", a clerk of works, a supervising architect, or a builder experienced in estimating construction costs of similar projects — and (para 27) "Unless they are otherwise qualified, valuers, real estate agents, accountants and solicitors generally have neither the relevant qualifications nor experience to make such an estimate." So a valuation, an agent's appraisal or the purchase price cannot substitute for the *construction cost* behind Div 43. For Div 40 plant, the ATO lets an owner "choose to work out the effective life yourself or to use an effective life determined by the Commissioner of Taxation"; in practice a QS report lists both (the ATO: "A quantity surveyor can prepare a report at the time a rental property is purchased."). This is why the plan **defers the depreciation figure to a QS schedule** rather than estimating it (the [remove-from-reach discipline]): the schedule, not the plan, produces the claimable numbers.

## When a schedule is worth obtaining

A QS schedule is generally worthwhile for an investment property that carries meaningful depreciation — typically **newer buildings** (more Div 43 capital works remaining) and properties with **depreciable plant** the investor is entitled to claim (subject to the 9 May 2017 second-hand-plant restriction owned by the depreciation doc). For an older established property bought after 9 May 2017 with little new plant, the benefit is thinner — the plan flags this rather than assuming a schedule always pays off. The schedule is a **once-off** report covering the life of the asset (updated only if significant capital works are added).

## Cost (indicative) and deductibility

A residential tax depreciation schedule is put at **~$385–$770** (an established home ~$590–$770) — a **PLACEHOLDER** band: no primary is cited for it yet (no regulator publishes QS fees); re-ground on several QS firms' own published price pages. The fee is itself **tax-deductible**: the ATO lists "quantity surveyor’s fees" among the expenses you may claim immediately in the year incurred. The plan surfaces the cost as a small upfront due-diligence/setup outlay and notes it is recoverable via the deduction — it does not promise a specific depreciation return (that depends on the property and is the QS's determination).

## Relevance for Vietnamese-Australian investors (Mode C)

- **The depreciation figure comes from the QS, not the plan.** The plan states depreciation is QS-substantiated and sizes the report cost; it does not author a claimable depreciation figure.
- **New vs established changes the value.** A newer property warrants a schedule more than an older established one post-2017 — the plan flags the difference rather than assuming a uniform benefit.
- **Small cost, deductible, once-off.** ~$385–$770 (PLACEHOLDER band), tax-deductible, covering the life of the asset — surfaced as a due-diligence outlay.
- **Information, not advice.** The plan points to a qualified QS; it computes no binding depreciation schedule.

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **reference doc** — it fills no slot; the report cost is **placed by the resolver** as a banded figure and the depreciation claim is **deferred to the QS schedule** (not plan-estimated). The QS recognition is a regulated ATO fact; the cost is a PLACEHOLDER band pending QS firms' own price pages.

```jsonc
{
  "fills": [],
  "parameters": {
    "qs_recognised_for_construction_costs": { "type": "bool", "value": true, "note": "REGULATED (ATO TR 97/25 paras 27-28) — a quantity surveyor (with a clerk of works, supervising architect or experienced builder) is an appropriately qualified person to estimate construction costs where actual costs are unknown; valuers, real estate agents, accountants and solicitors generally are not" },
    "depreciation_deferred_to_qs_schedule": { "type": "bool", "value": true, "note": "the depreciation figure is QS-substantiated, not plan-estimated (remove-from-reach); the plan sizes the report, not the claim" },
    "qs_schedule_is_once_off":              { "type": "bool", "value": true, "note": "a schedule covers the life of the asset; updated only if significant capital works are added" },
    "qs_schedule_fee_deductible":           { "type": "bool", "value": true, "note": "REGULATED (ATO Rental properties 2026) — quantity surveyor's fees are an immediate deduction in the year incurred" }
  },
  "lookup": {
    "fee_lines": {
      "note": "one entry per fee the buyer cannot know until they hire someone or get a quote; the engine emits one cash event per applicable entry (behavior 83)",
      "entries": [
        {
          "id": "depreciation_schedule",
          "phase": "settle",
          "timing": "one_off",
          "tier": "PLACEHOLDER",
          "basis": "fixed",
          "low": 385,
          "high": 770,
          "applies": {
            "modes": [
              "investor-domestic-au",
              "investor-foreign-au"
            ],
            "states": "all",
            "property": "any"
          },
          "optional": false,
          "note": "PLACEHOLDER — no primary states this band; re-ground on several quantity-surveying firms' own published price pages for a residential tax depreciation schedule. The $385–$770 band (established home ~$590–$770) is kept from an earlier read, not yet re-read as primaries",
          "label": {
            "vi": "Lập lịch khấu hao thuế (depreciation schedule) bởi chuyên viên định giá xây dựng (quantity surveyor)",
            "en": "Tax depreciation schedule by a quantity surveyor"
          },
          "payer": {
            "vi": "Chủ nhà trả một lần; phí này được khấu trừ thuế",
            "en": "The owner pays once; the fee is tax-deductible"
          },
          "drivers": {
            "vi": "Nhà mới hoặc mới sửa nhiều thì đáng làm hơn nhà cũ. Nhà có sẵn thường ~$590–$770; căn hộ hoặc nhà nhỏ có thể rẻ hơn. Làm một lần, dùng suốt đời tài sản.",
            "en": "Worth more on a new or recently renovated property than an old one. An established home is typically ~$590–$770; a unit or small home can cost less. Done once, used for the asset's life."
          },
          "source": null
        }
      ]
    }
  }
}
```

Notes:

- **No `fills`.** The report cost is placed by the resolver as a banded due-diligence/setup outlay; the depreciation claim is deferred to the QS schedule. The doc supplies the recognition fact and the cost band, not a depreciation figure.
- **Single-owner split.** Depreciation *rates / the 2017 restriction / the CGT clawback* are owned by `kb.tax.depreciation-division-43-and-40`; this doc owns the *report* (why a QS, when, cost). The settlement-phase *procurement timeline* is owned by the Cluster-S settlement docs (`kb.investor.depreciation-schedule-procurement`) — cross-ref, not duplicated.
- **Regulated recognition, placeholder cost.** The QS recognition (TR 97/25) is a regulated ATO fact; the fee band is a PLACEHOLDER until QS firms' own price pages are cited.

## Sources

**Canonical (Australian Taxation Office):**

- ATO — *Depreciating assets in rental properties* ("A quantity surveyor can prepare a report at the time a rental property is purchased.") — https://www.ato.gov.au/individuals-and-families/investments-and-assets/property-and-land/residential-rental-properties/rental-expenses/depreciating-assets-in-rental-properties (archived at docs/sources/ato/depreciating-assets-in-rental-properties.txt)
- ATO — *Taxation Ruling TR 97/25* (paras 27-28: who is appropriately qualified to estimate construction costs) — https://www.ato.gov.au/law/view/document?docid=TXR/TR9725/NAT/ATO/00001 (archived at docs/sources/ato/tr-97-25.txt)
- ATO — *Rental properties 2026 — Rental expenses* (estimate by an appropriately qualified person; quantity surveyor's fees immediately deductible; effective life self-assessed or the Commissioner's) — https://www.ato.gov.au/forms-and-instructions/rental-properties-2026/rental-expenses (archived at docs/sources/ato/rental-properties-2026-rental-expenses.txt)

**Fee band — PLACEHOLDER:** no primary cited; re-ground on several quantity-surveying firms' own published price pages for a residential tax depreciation schedule.
