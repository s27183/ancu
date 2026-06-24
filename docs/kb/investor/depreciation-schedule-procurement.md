---
slug: kb.investor.depreciation-schedule-procurement
effective_from: 2025-07-01
last_verified: 2026-06-23
---

# Depreciation schedule — procurement timeline

A depreciation schedule is procured once, after settlement, and then claimed for decades. This doc owns the **post-settlement procurement milestone** — when to engage the quantity surveyor, when the schedule must be ready, and when it needs refreshing. The report's **purpose and cost** are owned by [`kb.tax.quantity-surveyor-reports`](../tax/quantity-surveyor-reports.md); the **due-diligence validation lens** (getting a pre-purchase estimate) by [`kb.investor.depreciation-report-quantity-surveyor`](depreciation-report-quantity-surveyor.md); the **rates/rules** by [`kb.tax.depreciation-division-43-and-40`](../tax/depreciation-division-43-and-40.md). This doc owns only the *settlement-phase timeline*. It grounds `settlement_prep.investor_specific_milestones.quantity_surveyor_engaged` and `depreciation_schedule_received`, and the `ownership_planning_investor` refresh alert. It is a **reference** doc — it asserts no figure. Informational.

## The procurement timeline

- **Engage the QS after settlement, once you own and can access the property.** A full schedule typically needs a site inspection (or a documented basis for one), so it's procured post-settlement, not before. The DD-stage artifact is a *quote/estimate* (the DD-lens doc); the *schedule* is procured now.
- **Have it ready before the first tax return / first depreciation claim.** The schedule must exist before depreciation is claimed in the first financial year of ownership — the milestone is "schedule received before the first return that includes this property". Engaging promptly after settlement leaves margin.
- **Apportion for a part-year first claim.** If settlement falls mid-financial-year, the first year's depreciation is apportioned for the days the property was available to rent — the schedule supports the apportionment; the calculation is the tax cluster's.
- **Refresh after a renovation.** A renovation adds new capital works and plant — and may scrap and write off the old. The `depreciation_schedule_refresh_if_renovated` / `depreciation_schedule_aging_alert` flags in `ownership_planning_investor` trigger a schedule refresh so post-reno deductions (and scrapping) are captured. This is the procurement doc's recurring touch-point.

## The settlement-prep milestones

- `quantity_surveyor_engaged` — engage the QS promptly after settlement.
- `depreciation_schedule_received` — schedule in hand before the first tax return claiming this property.

Both are *task* milestones (not contract gates like entity setup) — they don't block settlement, but missing them defers a year of deductions.

## Relevance for Vietnamese-Australian investors (Mode C)

- **Procure after settlement, before the first return.** The plan sequences the QS engagement right after settlement and the schedule before the first tax return, so the first year's depreciation isn't lost.
- **Part-year first claim is handled.** The plan notes a mid-year settlement apportions the first year's depreciation, with the schedule supporting it.
- **Refresh after renovating.** The plan arms an aging/refresh alert so a renovation triggers a new schedule and captures scrapping.
- **Every adjacent fact has one owner.** Cost, rates, and the DD estimate are referenced from their own docs. Information, not advice.

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **reference** doc — it fills no slot; the QS-engaged and schedule-received milestones are settlement-prep tasks, and the refresh alert lives in ownership planning. This doc owns the procurement timeline; cost/rates/DD-estimate are cross-ref'd.

```jsonc
{
  "fills": [],
  "parameters": {
    "engage_qs_after_settlement": { "type": "bool", "value": true, "note": "a full schedule typically needs a site inspection — procured post-settlement once you own and can access; the DD-stage artifact is a quote (kb.investor.depreciation-report-quantity-surveyor)" },
    "schedule_before_first_tax_return": { "type": "bool", "value": true, "note": "the schedule must exist before depreciation is claimed in the first financial year of ownership; engage promptly to leave margin" },
    "part_year_first_claim_apportioned": { "type": "bool", "value": true, "note": "a mid-financial-year settlement apportions the first year's depreciation for days available to rent; the schedule supports it, the calc is the tax cluster's" },
    "refresh_after_renovation": { "type": "bool", "value": true, "note": "a reno adds new capital works/plant and may scrap the old; depreciation_schedule_refresh_if_renovated / aging alert in ownership_planning_investor trigger a refresh" },
    "report_purpose_and_cost_owner": { "type": "string", "value": "kb.tax.quantity-surveyor-reports", "note": "OWNED ELSEWHERE — purpose + cost of the report" },
    "dd_estimate_owner": { "type": "string", "value": "kb.investor.depreciation-report-quantity-surveyor", "note": "OWNED ELSEWHERE — the pre-purchase due-diligence estimate lens" },
    "rates_and_rules_owner": { "type": "string", "value": "kb.tax.depreciation-division-43-and-40", "note": "OWNED ELSEWHERE — Div 43/40 rates, second-hand-plant restriction, clawback, apportionment calc" },
    "milestones_are_tasks_not_gates": { "type": "bool", "value": true, "note": "quantity_surveyor_engaged + depreciation_schedule_received are task milestones (don't block settlement) — but missing them defers a year of deductions" }
  }
}
```

Notes:

- **No `fills`.** The QS-engaged / schedule-received milestones are settlement-prep tasks; the refresh alert lives in ownership planning. This doc owns the procurement timeline.
- **Single-owner reconciliation (the QS-report overlap).** `kb.tax.quantity-surveyor-reports` owns purpose+cost; `kb.investor.depreciation-report-quantity-surveyor` owns the **DD validation lens** (pre-purchase estimate); **this doc** owns the **post-settlement procurement milestone + refresh**. Rates/calc → tax doc. No fact duplicated.
- **Tasks, not gates.** Unlike entity setup, these don't block settlement — but missing them costs a year of deductions.

## Sources

- ATO — *Capital works deductions* and *Depreciating assets* (when deductions can be claimed; apportionment for days available to rent — referenced; owned by kb.tax.depreciation-division-43-and-40) — https://www.ato.gov.au/individuals-and-families/investments-and-assets/property-and-land/residential-rental-properties/rental-expenses
- ASIC Moneysmart — *Investing in property* (depreciation as part of the ongoing tax picture) — https://moneysmart.gov.au/property-investment/investing-in-property
