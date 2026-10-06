---
slug: kb.investor.portfolio-review-cadence
effective_from: 2025-07-01
last_verified: 2026-07-06
sources:
  - url: https://moneysmart.gov.au/property-investment/buying-an-investment-property
    retrieved: 2026-07-06
  - url: https://moneysmart.gov.au/home-loans/switching-home-loans
    retrieved: 2026-07-06
---

# Portfolio review cadence

An investment property isn't set-and-forget — it needs periodic review against the thesis, the loan, the rent, and the rest of the portfolio. This doc owns the **review cadence** — what an investor reviews, how often, and what each review triggers. It grounds `ownership_planning_investor.portfolio_position.valuation_review_cadence_months`, the `lifecycle_alerts` (rent review, refi review, depreciation aging, land-tax aggregation warning), and `refi_review_cadence_months`. It is a **reference** doc — it asserts no figure; the cadences are sensible defaults the investor adjusts. Informational; not advice to act at any review.

## The review cycle

- **Rent review — yearly.** At each lease anniversary/renewal, check the rent against current market ([`kb.investor.rental-appraisal-from-pm-agent`](rental-appraisal-from-pm-agent.md)); below-market rent quietly erodes yield. `rent_review_window_yearly` arms this.
- **Valuation review — ~24 months (default).** Periodically re-estimate the property's value to track equity and current LVR. The blueprint default is `valuation_review_cadence_months: 24`. Rising equity is the raw material for scale-up; a falling value is an early risk signal.
- **Refinance review — ~24 months (default).** Check whether the loan is still competitive — rate, structure (IO vs P&I rollover), offset use. `refi_review_cadence_months: 24`. A fixed-rate expiry or an IO term ending forces a review regardless of cadence; loan structure is owned by [`kb.lender.serviceability-investment-loans`](../lender/serviceability-investment-loans.md).
- **Depreciation schedule aging.** After a renovation (or as a schedule ages past its useful detail), refresh it — `depreciation_schedule_aging_alert` points to [`kb.investor.depreciation-schedule-procurement`](depreciation-schedule-procurement.md).
- **Land-tax aggregation warning.** As the portfolio grows, aggregated land value can cross a state threshold — `land_tax_aggregation_warning` fires, owned by [`kb.investor.land-tax-aggregation`](land-tax-aggregation.md).

## Why cadence, not constant attention

- **Reviews catch slow drift.** Below-market rent, a stale loan, an aging depreciation schedule, or a crossed land-tax threshold each erode return gradually — a periodic review catches what daily attention would miss in the noise.
- **A cadence is a default, not a deadline.** The intervals are sensible defaults; specific triggers (lease renewal, fixed-rate expiry, a renovation, a new purchase) force a review off-cadence. The alerts are reminders to *look*, not instructions to *act*.
- **Review feeds scale-up.** The valuation/equity review is the input to the scale-up decision ([`kb.investor.scale-up-using-equity`](scale-up-using-equity.md)) — "ready for the next property at an LVR of X" is checked at review.

## Relevance for Vietnamese-Australian investors (Mode C)

- **The plan schedules the reviews.** Rent yearly, valuation and refinance ~2-yearly, depreciation on renovation, land tax as the portfolio grows — armed as alerts so nothing drifts unseen.
- **Equity review enables the next move.** The plan ties the valuation review to scale-up readiness.
- **Alerts remind, they don't instruct.** The plan surfaces a review window; the investor decides whether to act. Information, not advice.

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **reference** doc — it fills no slot; the cadences and alerts live in `ownership_planning_investor`. This doc supplies the review cycle and the defaults.

```jsonc
{
  "fills": [],
  "lookup": {
    "review_cadences": {
      "note": "default review intervals + what each triggers — defaults the investor adjusts, not deadlines",
      "entries": [
        { "review": "rent_review", "cadence": "yearly (lease anniversary)", "checks": "rent vs market (kb.investor.rental-appraisal-from-pm-agent)", "trigger": "lease renewal" },
        { "review": "valuation_review", "cadence": "~24 months (default)", "checks": "value, equity, current LVR", "trigger": "feeds scale-up readiness" },
        { "review": "refinance_review", "cadence": "~24 months (default)", "checks": "rate, structure (IO/P&I), offset (kb.lender.serviceability-investment-loans)", "trigger": "fixed-rate expiry / IO term ending forces it" },
        { "review": "depreciation_schedule", "cadence": "on renovation / as it ages", "checks": "schedule currency", "trigger": "kb.investor.depreciation-schedule-procurement refresh" },
        { "review": "land_tax_aggregation", "cadence": "as portfolio grows", "checks": "aggregated land value vs state threshold", "trigger": "kb.investor.land-tax-aggregation warning" }
      ]
    }
  },
  "parameters": {
    "cadence_is_a_default_not_a_deadline": { "type": "bool", "value": true, "note": "the intervals are sensible defaults; specific triggers (lease renewal, fixed-rate expiry, reno, new purchase) force an off-cadence review" },
    "alerts_remind_not_instruct": { "type": "bool", "value": true, "note": "the lifecycle_alerts surface a review window — reminders to LOOK, not instructions to ACT (ASIC line)" },
    "valuation_review_feeds_scale_up": { "type": "bool", "value": true, "note": "the valuation/equity review is the input to the scale-up decision (kb.investor.scale-up-using-equity) — 'ready for the next property at LVR X'" }
  }
}
```

Notes:

- **No `fills`.** The cadences and alerts live in `ownership_planning_investor`. This doc supplies the review cycle and defaults.
- **Single-owner via cross-ref.** Rent vs market → `kb.investor.rental-appraisal-from-pm-agent`; loan structure → `kb.lender.serviceability-investment-loans`; depreciation refresh → `kb.investor.depreciation-schedule-procurement`; land-tax aggregation → `kb.investor.land-tax-aggregation`; scale-up → `kb.investor.scale-up-using-equity`. This doc owns the review cadence.
- **Reminders, not instructions.** Alerts prompt a look; the investor decides. ASIC line held.

## Sources

- ASIC Moneysmart — *Investing in property* (reviewing your investment; reviewing your loan) — https://moneysmart.gov.au/property-investment/investing-in-property
- ASIC Moneysmart — *Switching home loans* (when and why to review/refinance a loan) — https://moneysmart.gov.au/home-loans/switching-home-loans
