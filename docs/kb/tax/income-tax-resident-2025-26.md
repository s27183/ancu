---
slug: kb.tax.income-tax-resident-2025-26
effective_from: 2025-07-01
last_verified: 2026-07-06
sources:
  - url: https://www.ato.gov.au/tax-rates-and-codes/tax-rates-australian-residents
    retrieved: 2026-07-06
  - url: https://www.ato.gov.au/individuals-and-families/medicare-and-private-health-insurance/medicare-levy
    retrieved: 2026-06-22
  - url: https://www.ato.gov.au/about-ato/new-legislation/in-detail/individuals/personal-income-tax-new-tax-cuts-for-every-australian-taxpayer
    retrieved: 2026-06-22
---

# Resident individual income tax — 2025-26 schedule

Australian-resident individual income tax for the **2025-26 income year** (1 July 2025 – 30 June 2026): a marginal-bracket schedule plus the 2% Medicare levy. This doc owns the **rate schedule** so `mortgage_finance` can compute **net (after-tax) income** — the load-bearing input to borrowing capacity (a lender assesses surplus *after* tax, not gross). It is a universal regulated schedule, not Mode-A-specific; Modes C/D reuse it for investor tax when those modes are built (it replaces the unbuilt `kb.investor.tax-brackets-2026` placeholder anchor — income tax brackets are not investor-specific).

These are the post-"Stage 3" resident rates that took effect 1 July 2024 and **continue unchanged for 2025-26**. The further legislated cut (the 16% bracket → 15% from 1 July 2026, → 14% from 1 July 2027) does **not** apply to 2025-26 — author a `…-2026-27` doc when that year opens, do not edit this one.

## Resident rate schedule (2025-26)

| Taxable income | Tax on this income |
|---|---|
| $0 – $18,200 | Nil |
| $18,201 – $45,000 | 16c per $1 over $18,200 |
| $45,001 – $135,000 | $4,288 + 30c per $1 over $45,000 |
| $135,001 – $190,000 | $31,288 + 37c per $1 over $135,000 |
| $190,001 + | $51,638 + 45c per $1 over $190,000 |

The base amounts compound cleanly: $4,288 = 16% × ($45,000 − $18,200); $31,288 = $4,288 + 30% × ($135,000 − $45,000); $51,638 = $31,288 + 37% × ($190,000 − $135,000). The rates **exclude** the Medicare levy.

## Medicare levy

A **2%** levy on taxable income applies on top of the rate schedule for most residents. A low-income reduction phases the levy in from a single-person threshold (~$27,000) up to ~1.25× that; **above the phase-in every serviceability-relevant income pays the full 2%**, so for borrowing-capacity purposes the resolver applies a flat 2% (the phase-in only matters below the HECS repayment threshold, where capacity is not the binding question). Medicare levy *surcharge* (for high earners without private hospital cover) is **not** modelled — it is conditional on cover status the plan does not capture, and surfacing it would overstate the tax drag.

## Why it matters to borrowing capacity

Serviceability is assessed on **net monthly surplus**: a lender works from after-tax income, subtracts living expenses and debt commitments, and capitalises what remains at the buffered rate. Using gross income would overstate capacity by ~25–30% at typical first-home-buyer incomes — not a band, simply wrong. So `mortgage_finance` computes net income = gross − (this schedule) − Medicare, **before** subtracting the HECS compulsory repayment ([`kb.hecs.thresholds`](../hecs/thresholds.md), treated as a commitment, not double-counted in tax) and other debt commitments. The tax schedule is the **verifiable** half of the capacity estimate (regulated, to-the-dollar); the living-expenses band ([`kb.lender.hem-living-expenses`](../lender/hem-living-expenses.md)) is the labelled-convention half.

## Relevance for Vietnamese-Australian buyers (Mode A)

- Most Mode A buyers are PAYG professionals; net income computed from this schedule is the spine of their borrowing capacity.
- Where income includes a **foreign-sourced component** (`profile.income.foreign_sourced_component`), tax residency still governs — a tax *resident* is taxed on worldwide income on this schedule; the lender's *separate* shading of offshore income (serviceability, not tax) lives in [`kb.lender.serviceability-basics`](../lender/serviceability-basics.md). Keep the two distinct.

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **reference doc** — it fills no slot; net income and the tax figure are **resolver-computed** from this schedule (control flow → code, per §11.9), not asserted. Every figure here is a regulated ATO constant.

```jsonc
{
  "fills": [],
  "parameters": {
    "tax_free_threshold":        { "type": "money",      "value": 18200, "note": "REGULATED (ATO) — below this, nil income tax" },
    "medicare_levy_pct":         { "type": "percentage", "value": 2,     "note": "REGULATED — 2% of taxable income; full rate applies above the low-income phase-in (all serviceability-relevant incomes)" },
    "medicare_low_income_single_threshold": { "type": "money", "value": 27222, "note": "CONTEXT — single-person low-income threshold below which the levy phases in/out; not load-bearing for capacity (below the HECS threshold). 2024-25 figure; re-confirm on the annual pass." },
    "second_band_base":          { "type": "money",      "value": 4288,  "note": "tax at $45,000 = 16% × ($45,000 − $18,200)" },
    "third_band_base":           { "type": "money",      "value": 31288, "note": "tax at $135,000 = $4,288 + 30% × $90,000" },
    "top_band_base":             { "type": "money",      "value": 51638, "note": "tax at $190,000 = $31,288 + 37% × $55,000" }
  },
  "lookup": {
    "resident_rates_2025_26": {
      "note": "ordered marginal brackets; resolver selects the band for taxable income and computes tax = base_amount + marginal_rate_pct × (income − marginal_over) — schedule supplied here, arithmetic in resolver code (mirrors kb.hecs.thresholds)",
      "entries": [
        { "band": "tax_free", "income_from": 0,      "income_to": 18200,  "marginal_rate_pct": 0,  "base_amount": 0,     "marginal_over": 0 },
        { "band": "b1",       "income_from": 18201,  "income_to": 45000,  "marginal_rate_pct": 16, "base_amount": 0,     "marginal_over": 18200 },
        { "band": "b2",       "income_from": 45001,  "income_to": 135000, "marginal_rate_pct": 30, "base_amount": 4288,  "marginal_over": 45000 },
        { "band": "b3",       "income_from": 135001, "income_to": 190000, "marginal_rate_pct": 37, "base_amount": 31288, "marginal_over": 135000 },
        { "band": "b4",       "income_from": 190001, "income_to": null,   "marginal_rate_pct": 45, "base_amount": 51638, "marginal_over": 190000 }
      ]
    }
  }
}
```

Notes:

- **No `fills`.** Nothing in any outcome is set directly by this doc — net income and tax are **resolver-computed** from this schedule (same "computed, not asserted" discipline as stamp duty, LMI, and the HECS repayment). The doc is reference data the resolver reads.
- **`lookup` not `parameter` for the schedule** because it is an ordered band table the resolver indexes into (the vocabulary's intended use); the scalar thresholds are duplicated as `parameter`s for direct reference.
- **2025-26 only.** When 2026-27 opens (16% → 15%), author a sibling doc and re-anchor; do not mutate this one — a filled plan card records the schedule it used.
- **Medicare surcharge excluded by design** (conditional on private-cover status the plan does not capture).

## Sources

- Australian Taxation Office — *Tax rates – Australian resident* (2025-26 resident rates; Medicare levy excluded from the schedule) — https://www.ato.gov.au/tax-rates-and-codes/tax-rates-australian-residents (2025-26 schedule re-confirmed 2026-07-06, unchanged; ATO blocks automated fetch — read via the archived snapshot of this page)
- Australian Taxation Office — *Medicare levy* (2% of taxable income) — https://www.ato.gov.au/individuals-and-families/medicare-and-private-health-insurance/medicare-levy
- ATO — *Personal income tax — new tax cuts for every Australian taxpayer* (Stage-3 rates from 1 Jul 2024, continuing 2025-26; 15%/14% steps from 1 Jul 2026 / 2027) — https://www.ato.gov.au/about-ato/new-legislation/in-detail/individuals/personal-income-tax-new-tax-cuts-for-every-australian-taxpayer
