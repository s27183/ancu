---
slug: kb.investor.depreciation-report-quantity-surveyor
effective_from: 2025-07-01
last_verified: 2026-06-23
---

# Depreciation report — the due-diligence lens

A depreciation schedule turns a property's building and plant into years of deductible expense — but only if the deductions are actually there. This doc owns the **due-diligence lens** on the quantity-surveyor depreciation report: getting a QS *quote/estimate* before buying so the depreciation the cash-flow thesis assumes is validated, not hoped for. The report's **purpose and cost** are owned by [`kb.tax.quantity-surveyor-reports`](../tax/quantity-surveyor-reports.md); the build-year **eligibility** by [`kb.property.depreciation-by-build-year`](../property/depreciation-by-build-year.md); the depreciation **rates and rules** (Div 43/40, the 9 May 2017 second-hand-plant restriction, cost-base clawback) by [`kb.tax.depreciation-division-43-and-40`](../tax/depreciation-division-43-and-40.md). The **post-settlement procurement timeline** is owned by [`kb.investor.depreciation-schedule-procurement`](depreciation-schedule-procurement.md). This doc owns only the *DD-time* lens. It is a **reference** doc — it asserts no figure. Informational.

## Why it belongs in due diligence

- **Depreciation is a thesis input, not an afterthought.** Div 43 capital-works and Div 40 plant deductions reduce taxable rental income — for a negatively-geared property they materially change the *after-tax* holding cost. If the thesis leans on depreciation, the deduction needs validating *before* the bid, not discovered after settlement.
- **A pre-purchase QS estimate sizes the benefit.** A quantity surveyor can give an indicative first-few-years depreciation estimate for a property before purchase. This grounds the `tax_structure` and `yield_modelling` after-tax figures with a real number rather than an assumption.
- **Eligibility can kill the deduction.** A property's build year and the 9 May 2017 second-hand-plant restriction can sharply limit what's claimable ([`kb.property.depreciation-by-build-year`](../property/depreciation-by-build-year.md)) — a pre-1987, never-renovated established dwelling bought after 9 May 2017 may have *little* depreciation. Surfacing this in DD prevents a thesis built on a deduction that isn't there.
- **The quote itself is a settlement document.** `due_diligence.investor_specific_documents.depreciation_schedule_quote_from_quantity_surveyor` is the DD artifact; the actual schedule is procured post-settlement (the procurement doc).

## What this doc does and doesn't own

- **Owns:** the DD discipline of validating depreciation before buying, and how the estimate feeds the after-tax thesis.
- **Doesn't own:** the report's purpose/cost (tax cluster), the rates/rules (tax cluster), the build-year eligibility (property cluster), or the post-settlement procurement milestone (the procurement doc). All referenced, none duplicated.

## Relevance for Vietnamese-Australian investors (Mode C)

- **Validate the deduction before bidding.** The plan flags getting a QS estimate during due diligence, so the after-tax cash-flow figures rest on a real depreciation number, not an assumption.
- **Old, un-renovated properties may depreciate little.** The plan surfaces the build-year and second-hand-plant eligibility limits during DD — a guard against a thesis that over-counts depreciation.
- **Every adjacent fact has one owner.** Cost, rates, eligibility, and the procurement timeline are referenced from their own docs. Information, not advice.

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **reference** doc — it fills no slot; the QS quote is a DD document and the depreciation estimate grounds the after-tax thesis. This doc owns the DD lens; cost/rates/eligibility/timeline are cross-ref'd.

```jsonc
{
  "fills": [],
  "parameters": {
    "depreciation_is_a_thesis_input": { "type": "bool", "value": true, "note": "Div 43/40 deductions change the after-tax holding cost; if the thesis leans on depreciation, validate it before bidding, not after settlement" },
    "get_pre_purchase_qs_estimate": { "type": "bool", "value": true, "note": "a QS can give an indicative first-years depreciation estimate pre-purchase; grounds the tax_structure / yield_modelling after-tax figures" },
    "report_purpose_and_cost_owner": { "type": "string", "value": "kb.tax.quantity-surveyor-reports", "note": "OWNED ELSEWHERE — the report's purpose + cost; referenced, not duplicated" },
    "rates_and_rules_owner": { "type": "string", "value": "kb.tax.depreciation-division-43-and-40", "note": "OWNED ELSEWHERE — Div 43/40 rates, the 9 May 2017 second-hand-plant restriction, the cost-base clawback" },
    "eligibility_owner": { "type": "string", "value": "kb.property.depreciation-by-build-year", "note": "OWNED ELSEWHERE — build-year → eligibility classification; old un-renovated dwellings may depreciate little" },
    "procurement_timeline_owner": { "type": "string", "value": "kb.investor.depreciation-schedule-procurement", "note": "OWNED ELSEWHERE — the post-settlement procurement milestone (engage QS, schedule before first tax return, refresh after reno)" }
  }
}
```

Notes:

- **No `fills`.** The QS quote is a DD document; the estimate grounds the after-tax thesis. This doc owns the DD lens only.
- **Single-owner reconciliation (the QS-report overlap).** Three docs touch the QS report by design: `kb.tax.quantity-surveyor-reports` owns **purpose + cost**; this doc owns the **due-diligence validation lens** (validate the deduction before buying); `kb.investor.depreciation-schedule-procurement` owns the **post-settlement procurement milestone**. Rates/rules → tax doc; eligibility → property doc. No fact is duplicated.
- **Eligibility can zero the benefit.** The build-year + second-hand-plant limits are surfaced in DD so the thesis doesn't over-count depreciation.

## Sources

- ATO — *Capital works deductions* and *Depreciating assets* (what a depreciation schedule substantiates; referenced — owned by kb.tax.depreciation-division-43-and-40) — https://www.ato.gov.au/individuals-and-families/investments-and-assets/property-and-land/residential-rental-properties/rental-expenses
- ASIC Moneysmart — *Investing in property* (depreciation as part of the investment-property running cost/tax picture) — https://moneysmart.gov.au/property-investment/investing-in-property
