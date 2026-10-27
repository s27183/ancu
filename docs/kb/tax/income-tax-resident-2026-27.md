---
slug: kb.tax.income-tax-resident-2026-27
effective_from: 2026-07-01
last_verified: 2026-10-27
sources:
  - url: https://www.ato.gov.au/tax-rates-and-codes/tax-rates-australian-residents
    retrieved: 2026-10-27
    path: docs/sources/ato/tax-rates-australian-residents.txt
    note: "PRIMARY (ATO) — the 2026-27 resident rates and the Medicare levy rate."
    quotes:
      - "$4,020 plus 30c for each $1 over $45,000"
      - "$51,370 plus 45c for each $1 over $190,000"
      - "The above rates do not include the Medicare levy of 2%."
  - url: https://www.legislation.gov.au/C2025A00028/asmade/text
    retrieved: 2026-10-27
    note: "PRIMARY (law) — Treasury Laws Amendment (More Cost of Living Relief) Act 2025 (No. 28, 2025): 15% for 2026-27, 14% from 2027-28. Archived from the ATO's copy of the Act (next entry)."
  - url: https://www.ato.gov.au/law/view/pdf/acts/20250028.pdf
    retrieved: 2026-10-27
    path: docs/sources/legislation/more-cost-of-living-relief-act-2025.txt
    quotes:
      - "Tax rates for resident taxpayers for the 2026-27 year of income"
      - "Tax rates for resident taxpayers for the 2027-28 year of income or a later year of"
  - url: https://www.ato.gov.au/individuals-and-families/medicare-and-private-health-insurance/medicare-levy/medicare-levy-reduction/medicare-levy-reduction-for-low-income-earners
    retrieved: 2026-10-27
    path: docs/sources/ato/medicare-levy-reduction-low-income-earners.txt
    note: "PRIMARY (ATO) — the lower Medicare levy threshold for a single taxpayer, 2025-26 (the latest the ATO publishes; no 2026-27 figure yet)."
    quotes:
      - "In 2025–26, you don't have to pay the Medicare levy if your taxable income is equal to or less than the lower Medicare levy threshold."
      - "$28,011"
---

# Resident individual income tax — 2026-27 schedule

Australian-resident individual income tax for the **2026-27 income year** (1 July 2026 – 30 June 2027): a marginal-bracket schedule plus the 2% Medicare levy. Sibling of [`kb.tax.income-tax-resident-2025-26`](income-tax-resident-2025-26.md) (not an edit of it — that doc is a dated snapshot, per its own "author a sibling doc and re-anchor; do not mutate this one"). This doc owns the **current** rate schedule so `mortgage_finance` can compute **net (after-tax) income**, the load-bearing input to borrowing capacity, for any plan filled on or after 1 July 2026.

This is the **second phase of the "Stage 3+" cuts** legislated under the *Treasury Laws Amendment (More Cost of Living Relief) Act 2025*: the second marginal bracket drops from **16% to 15%** on income between $18,201 and $45,000. Every other bracket boundary and rate is unchanged from 2025-26. A further legislated step (16%→15%→**14%** from 1 July 2027) does **not** apply to 2026-27 — author a `…-2027-28` doc when that year opens, do not edit this one.

## Resident rate schedule (2026-27)

| Taxable income | Tax on this income |
|---|---|
| $0 – $18,200 | Nil |
| $18,201 – $45,000 | **15c** per $1 over $18,200 |
| $45,001 – $135,000 | $4,020 + 30c per $1 over $45,000 |
| $135,001 – $190,000 | $31,020 + 37c per $1 over $135,000 |
| $190,001 + | $51,370 + 45c per $1 over $190,000 |

The base amounts compound cleanly: $4,020 = 15% × ($45,000 − $18,200); $31,020 = $4,020 + 30% × ($135,000 − $45,000); $51,370 = $31,020 + 37% × ($190,000 − $135,000). Only the second-bracket rate and its downstream base amounts moved — the tax-free threshold and every bracket *boundary* are unchanged from 2025-26. The rates **exclude** the Medicare levy.

## Medicare levy

Unchanged from 2025-26: a **2%** levy on taxable income (the ATO rates page: "The above rates do not include the Medicare levy of 2%."), full rate above the low-income phase-in (all serviceability-relevant incomes) — see [`kb.tax.income-tax-resident-2025-26`](income-tax-resident-2025-26.md) for the phase-in detail. A single taxpayer pays no levy at or below the **lower threshold, $28,011 for 2025-26** — the latest year the ATO publishes; the 2026-27 threshold is not yet published, so the plan uses the 2025-26 figure until it is. Medicare levy surcharge remains **not modelled**, same reasoning as the prior doc.

## Why it matters to borrowing capacity

Unchanged mechanism from 2025-26: `mortgage_finance` computes net income = gross − (this schedule) − Medicare, **before** subtracting the HECS compulsory repayment ([`kb.hecs.thresholds`](../hecs/thresholds.md)) and other debt commitments. What changed is only the **figure**: at the same gross income, 2026-27 net income for anyone earning above $18,200 is **up to $268/year higher** than the 2025-26 schedule would have computed (the 1-point rate cut × the $26,800-wide second bracket) — a plan filled today must read this doc, not the 2025-26 one, or it understates capacity by that amount.

## Relevance for Vietnamese-Australian buyers (Mode A)

Unchanged from 2025-26 — see that doc. This doc supersedes it as the **current** schedule; the relevance reasoning (PAYG professionals, foreign-sourced-income residency treatment) carries over unmodified.

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **reference doc** — it fills no slot; net income and the tax figure are **resolver-computed** from this schedule (control flow → code, per §11.9), not asserted. Every figure here is a regulated ATO constant.

```jsonc
{
  "fills": [],
  "parameters": {
    "tax_free_threshold":        { "type": "money",      "value": 18200, "note": "REGULATED (ATO) — unchanged from 2025-26; below this, nil income tax" },
    "medicare_levy_pct":         { "type": "percentage", "value": 2,     "note": "REGULATED — unchanged from 2025-26" },
    "medicare_low_income_single_threshold": { "type": "money", "value": 28011, "note": "REGULATED (ATO, Medicare levy reduction for low-income earners) — the 2025-26 lower threshold for a single taxpayer, the latest the ATO publishes; the 2026-27 figure is not yet published (re-confirm when it is). Not load-bearing for capacity (below the HECS threshold)." },
    "second_band_base":          { "type": "money",      "value": 4020,  "note": "tax at $45,000 = 15% × ($45,000 − $18,200) — was $4,288 at the 2025-26 16% rate" },
    "third_band_base":           { "type": "money",      "value": 31020, "note": "tax at $135,000 = $4,020 + 30% × $90,000 — was $31,288" },
    "top_band_base":             { "type": "money",      "value": 51370, "note": "tax at $190,000 = $31,020 + 37% × $55,000 — was $51,638" }
  },
  "lookup": {
    "resident_rates_2026_27": {
      "note": "ordered marginal brackets; resolver selects the band for taxable income and computes tax = base_amount + marginal_rate_pct × (income − marginal_over) — schedule supplied here, arithmetic in resolver code (mirrors kb.hecs.thresholds)",
      "entries": [
        { "band": "tax_free", "income_from": 0,      "income_to": 18200,  "marginal_rate_pct": 0,  "base_amount": 0,     "marginal_over": 0 },
        { "band": "b1",       "income_from": 18201,  "income_to": 45000,  "marginal_rate_pct": 15, "base_amount": 0,     "marginal_over": 18200 },
        { "band": "b2",       "income_from": 45001,  "income_to": 135000, "marginal_rate_pct": 30, "base_amount": 4020,  "marginal_over": 45000 },
        { "band": "b3",       "income_from": 135001, "income_to": 190000, "marginal_rate_pct": 37, "base_amount": 31020, "marginal_over": 135000 },
        { "band": "b4",       "income_from": 190001, "income_to": null,   "marginal_rate_pct": 45, "base_amount": 51370, "marginal_over": 190000 }
      ]
    }
  }
}
```

Notes:

- **No `fills`.** Same "computed, not asserted" discipline as the 2025-26 doc — net income and tax are resolver-computed, not directly filled.
- **Only the rate changed.** Every threshold ($18,200 / $45,000 / $135,000 / $190,000) is identical to 2025-26; only the second-bracket `marginal_rate_pct` (16→15) and the three downstream `base_amount`s moved.
- **2026-27 only.** When 2027-28 opens (15%→14%, per the same legislated schedule), author a sibling doc and re-anchor; do not mutate this one — a filled plan card records the schedule it used.
- **Medicare surcharge excluded by design**, same reasoning as 2025-26.

## Sources

- Australian Taxation Office — *Tax rates – Australian resident* (2026-27 resident rates: "$4,020 plus 30c for each $1 over $45,000", "$51,370 plus 45c for each $1 over $190,000"; "The above rates do not include the Medicare levy of 2%.") — https://www.ato.gov.au/tax-rates-and-codes/tax-rates-australian-residents (retrieved 2026-10-27; archived at docs/sources/ato/tax-rates-australian-residents.txt)
- *Treasury Laws Amendment (More Cost of Living Relief) Act 2025* (No. 28, 2025) — the 15% rate for 2026-27 and 14% for 2027-28 and later years — https://www.legislation.gov.au/C2025A00028/asmade/text ; the ATO's PDF of the Act, https://www.ato.gov.au/law/view/pdf/acts/20250028.pdf (retrieved 2026-10-27; archived at docs/sources/legislation/more-cost-of-living-relief-act-2025.txt)
- Australian Taxation Office — *Medicare levy reduction for low-income earners* ("In 2025–26, you don't have to pay the Medicare levy if your taxable income is equal to or less than the lower Medicare levy threshold"; all other taxpayers, lower threshold $28,011) — https://www.ato.gov.au/individuals-and-families/medicare-and-private-health-insurance/medicare-levy/medicare-levy-reduction/medicare-levy-reduction-for-low-income-earners (retrieved 2026-10-27; archived at docs/sources/ato/medicare-levy-reduction-low-income-earners.txt)
