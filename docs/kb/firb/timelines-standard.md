---
slug: kb.firb.timelines-standard
effective_from: 2025-04-01
last_verified: 2026-06-28
---

# FIRB approval — standard decision timeline

This doc owns the **time it takes to obtain** a foreign-investment decision: the statutory decision period and what starts it. It is distinct from **how long an approval then lasts to settle** — that **approval-validity window** (~12 months) is owned by [`kb.firb.approval-to-settlement-timeline`](approval-to-settlement-timeline.md) (Cluster R4). Two different clocks: this doc = *time to get the answer*; that doc = *time the answer stays good*. It grounds the `firb_workflow` timing surface and the plan's settlement-readiness sequencing.

## The statutory decision period

- **Up to 30 days** to make a decision on a residential-land application, **after the correct fee has been received in full.**
- **The clock does not start until the fee is paid in full.** An incorrect or underpaid fee means the 30-day period has **not begun** — the single most common, and most avoidable, cause of delay.
- A **further short period to notify** the decision follows the decision itself.
- **Extensions exist.** The Treasurer may extend the period (e.g. by interim order), and an applicant may agree to an extension; complex or national-security cases can take longer. The 30 days is the **standard statutory target**, not a guarantee for every case.

## Practical timing for the plan

- **Apply early.** Because the clock starts only on full fee payment, and settlement cannot complete before approval, the application should be lodged as early as the property facts allow — typically alongside a **contract conditional on FIRB approval** ([`kb.firb.contract-conditional-on-approval`](contract-conditional-on-approval.md), R3) so the buyer is not racing the decision against an unconditional settlement date.
- **Off-the-plan is the timing trap.** For an off-the-plan purchase, the risk is not the 30-day decision but that a **slipped completion outruns the approval's validity window** — time the application to the **realistic completion**, not the contract date ([`kb.off-the-plan.risk-considerations`](../off-the-plan/risk-considerations.md), which owns that foreign-person trap, and [`kb.firb.approval-to-settlement-timeline`](approval-to-settlement-timeline.md) for the window).
- **The cross-border transfer runs in parallel.** Bank AML / source-of-funds checks and the VND→AUD transfer have their own lead times (Cluster X); the plan sequences them against the approval and settlement dates, not after.

## Rules

Pure-reference (`fills: []`). The 30-day-from-full-fee rule grounds the resolver's timing estimate and the readiness sequencing; no leaf is asserted, and the only number — 30 days — is the statutory period (a regulated duration, not a money figure), placed by the resolver.

```jsonc
{
  "fills": [],
  "parameters": {
    "statutory_decision_days": { "type": "integer", "value": 30, "provenance": "REGULATED", "note": "up to 30 days to decide a residential-land application, after the correct fee is received in full (FATA framework / ATO)." },
    "clock_starts_on_full_fee_payment": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "the 30-day period does not start until the correct fee is paid in full — the most common avoidable delay." },
    "extensions_possible": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "the Treasurer may extend (e.g. interim order) and an applicant may agree to an extension; complex/national-security cases can take longer. 30 days is the standard target, not a guarantee." },
    "decision_period_distinct_from_validity_window": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "time-to-decide (this doc) is a different clock from the approval's settle-by validity window (kb.firb.approval-to-settlement-timeline)." }
  }
}
```

Notes:

- **Two clocks, single owners.** *Time to get approval* (30 days from full fee) is owned here. *Time the approval stays valid to settle* (~12 months) is owned by [`kb.firb.approval-to-settlement-timeline`](approval-to-settlement-timeline.md) (R4). The plan reads both; neither restates the other.
- **The fee-payment trigger ties this doc to the fee docs.** The clock depends on full payment per [`kb.firb.fee-schedule-current`](fee-schedule-current.md) — an underpaid fee (e.g. against a stale, pre-reindex amount) silently fails to start the clock, which is why the fee schedule carries its 1 July re-ground obligation.
- **Decision-support framing.** Standard timing only; an individual application's timeline is confirmed via the ATO portal.

## Sources

- ATO — *Residential property application for foreign investors* (up to 30 days to consider an application after the correct fee is received in full; the statutory period does not start until the fee is paid) — https://www.ato.gov.au/individuals-and-families/investments-and-assets/foreign-resident-investments/foreign-investment-in-australia/residential-property-application-for-foreign-investors
- Foreign Investment in Australia (Treasury/FIRB) — *Guidance Note 6: Residential Land*, Version 3 (14 March 2025) — decision periods (30 days) — https://foreigninvestment.gov.au/sites/foreigninvestment.gov.au/files/2025-03/guidance-note-6-residential-land-v3.pdf
- Foreign Investment in Australia — *Fees* (the fee must be paid before processing) — https://foreigninvestment.gov.au/guidance/general/fees
