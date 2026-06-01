---
slug: kb.hecs.thresholds
effective_from: 2025-07-01
last_verified: 2026-06-01
---

# HECS-HELP repayment thresholds and lender treatment

A **HECS-HELP** (Higher Education Loan Program) debt is a compulsory study-loan liability repaid through the tax system once income passes a threshold. It matters to a first-home plan for one reason: lenders count the **compulsory repayment** as a committed expense that reduces borrowing capacity. This doc owns the **repayment schedule** (the universal ATO rules) so `buyer_profile` can frame the `hecs_balance` fact and `mortgage_finance` can reason about the capacity impact of clearing it. The **per-lender** variation in how HECS is treated (some exclude a near-paid-off balance) lives in [`kb.lender.hecs-treatment-by-lender`](../lender/hecs-treatment-by-lender.md); the general serviceability framework lives in [`kb.lender.serviceability-basics`](../lender/serviceability-basics.md).

## The 2025-26 reform — a marginal system (changed the snapshot)

From the **2025-26 income year (1 July 2025)** the repayment rules changed substantially, and the change **inverts** older guidance:

- **Minimum repayment threshold raised to $67,000** (from $54,435 in 2024-25). Below this, no compulsory repayment.
- **Marginal calculation.** Repayment is now charged **only on income above the threshold**, not as a flat percentage of total income. This removes the old "cliff" where crossing a bracket taxed the whole income.
- **One-off 20% debt reduction.** Every HELP balance was cut by **20% as at 1 June 2025** (applied before that year's indexation). A balance quoted from before this date overstates the debt.
- **Indexation reform (context).** Since 2023 HELP is indexed to the **lower of CPI or the Wage Price Index**, capping runaway indexation.

## Repayment schedule (2025-26)

Compulsory repayment is computed from **repayment income** (broadly taxable income plus some add-backs):

| Repayment income | Compulsory repayment |
|---|---|
| $0 – $67,000 | Nil |
| $67,001 – $125,000 | 15c per $1 **over $67,000** |
| $125,001 – $179,285 | $8,700 + 17c per $1 **over $125,000** |
| $179,286 + | **10% of total** repayment income |

The bands meet cleanly: at $179,285 the marginal calculation ($8,700 + 17% × $54,285 ≈ $17,928) equals 10% of total, after which the top band charges a flat 10% of the **whole** income (the one place the system is not marginal — a catch-up for high earners).

## Why it matters to borrowing capacity

A lender treats the **annual compulsory repayment at the borrower's income** as a recurring commitment, subtracting roughly its monthly equivalent from assessable surplus. The capacity drag therefore scales with income, not with the balance — a key nuance for the `mortgage_finance` "clear HECS before applying?" reasoning:

- **Clearing a HECS balance removes the repayment commitment**, lifting borrowing capacity — but only by the capitalised value of that repayment stream, and it drains cash needed for the deposit. The trade-off (capacity uplift vs cash drain) is exactly what `mortgage_finance.debt_optimisation_recommendations.hecs` weighs.
- **A small balance near payoff** may be excluded by some lenders (lender-specific — see [`kb.lender.hecs-treatment-by-lender`](../lender/hecs-treatment-by-lender.md)), which can make *not* clearing it the better call.

## Relevance for Vietnamese-Australian buyers (Mode A)

- Many Mode A buyers are university-educated professionals carrying a HECS balance; it is one of the most common capacity drags after credit-card limits.
- The reform **helps** these buyers: the higher $67,000 threshold and marginal rates mean a smaller compulsory repayment at typical FHB incomes, so the same income now services a larger loan than under the old flat system. Surface this when income sits in the $67k–$90k band, where the change is largest.
- The 20% cut means a balance the buyer remembers may be materially lower now — re-pull the current ATO balance rather than relying on the user's figure.

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **reference doc** — it fills no eligibility slot; it supplies the repayment schedule as a `lookup` plus threshold `parameter`s that the resolver/agent reads when reasoning about the serviceability impact of `profile.hecs_balance`. The actual compulsory-repayment figure for a given income is **resolver-computed** from this schedule (control flow → code, per §11.9), not asserted here.

```jsonc
{
  "fills": [],
  "parameters": {
    "minimum_repayment_threshold":   { "type": "money",      "value": 67000,  "note": "2025-26; below this no compulsory repayment (was $54,435 in 2024-25)" },
    "prior_year_threshold":          { "type": "money",      "value": 54435,  "note": "2024-25 minimum — kept for context; do not use for current calcs" },
    "second_band_floor":             { "type": "money",      "value": 125000, "note": "15%→17% marginal transition" },
    "top_band_floor":                { "type": "money",      "value": 179285, "note": "above this: flat 10% of TOTAL income (not marginal)" },
    "marginal_rate_band1":           { "type": "percentage", "value": 15,     "note": "on income $67,001–$125,000" },
    "marginal_rate_band2":           { "type": "percentage", "value": 17,     "note": "on income $125,001–$179,285, plus $8,700 base" },
    "band2_base_amount":             { "type": "money",      "value": 8700,   "note": "= 15% × ($125,000 − $67,000)" },
    "top_band_rate_of_total_income": { "type": "percentage", "value": 10,     "note": "flat, applied to whole repayment income above $179,285" },
    "one_off_debt_reduction_pct":    { "type": "percentage", "value": 20,     "note": "all HELP balances cut by 20% as at this date, before indexation" },
    "one_off_debt_reduction_date":   { "type": "date",       "value": "2025-06-01" },
    "indexation_basis":              { "type": "string",     "value": "lower of CPI or Wage Price Index", "note": "since 2023; caps indexation" }
  },
  "lookup": {
    "repayment_schedule_2025_26": {
      "note": "ordered marginal bands; resolver selects the band for the borrower's repayment income and computes the compulsory repayment — schedule supplied here, arithmetic in resolver code",
      "entries": [
        { "band": "nil",       "income_from": 0,      "income_to": 67000,  "marginal_rate_pct": 0,  "base_amount": 0 },
        { "band": "lower",     "income_from": 67001,  "income_to": 125000, "marginal_rate_pct": 15, "base_amount": 0,    "marginal_over": 67000 },
        { "band": "upper",     "income_from": 125001, "income_to": 179285, "marginal_rate_pct": 17, "base_amount": 8700, "marginal_over": 125000 },
        { "band": "top_flat",  "income_from": 179286, "income_to": null,   "flat_rate_of_total_pct": 10 }
      ]
    }
  }
}
```

Notes:

- **No `fills`.** Nothing in `buyer_profile`'s or `mortgage_finance`'s outcome is set directly by this doc — `hecs_balance` is a raw user fact, and the compulsory repayment / capacity uplift are **resolver-computed** from this schedule (the same "computed, not asserted" discipline as stamp duty and LMI). The doc is reference data the resolver and agent read.
- **The top band is the one non-marginal step.** Above $179,285 the charge is 10% of *total* income, not a marginal slice — encoded as `flat_rate_of_total_pct` so the resolver branches correctly. The other bands carry `marginal_over` (the income floor the rate applies above) plus a `base_amount`.
- **`lookup` not `parameter` for the schedule** because it is a keyed/ordered band table the resolver indexes into — the vocabulary's intended use for a table of bands. The scalar thresholds are duplicated as `parameter`s for direct reference (e.g. the agent surfacing "$67,000 threshold") without parsing the lookup.
- **Balance freshness.** The 20% cut (1 Jun 2025) means a user-remembered balance is likely stale; the agent should reason against the current ATO balance, not the figure the user volunteers. This is a data-currency note, not a rule.

## Sources

- Australian Taxation Office — *Study and training support loans — rates and repayment thresholds* (2025-26 marginal schedule; $67,000 minimum threshold) — https://www.ato.gov.au/tax-rates-and-codes/study-and-training-support-loans-rates-and-repayment-thresholds
- Department of Education — *Making HELP and student loan repayments fairer* (marginal system, $67,000 threshold, effective 2025-26) — https://www.education.gov.au/higher-education-loan-program/making-help-and-student-loan-repayments-fairer
- Australian Taxation Office — *Study and training loans — what's new* (20% one-off reduction as at 1 June 2025; indexation reform) — https://www.ato.gov.au/individuals-and-families/study-and-training-support-loans/study-and-training-loans-what-s-new
