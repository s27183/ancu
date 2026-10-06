---
slug: kb.loan.fixed-rate-roll-off-planning
effective_from: 2025-07-01
last_verified: 2026-07-06
sources:
  - url: https://handbook.apra.gov.au/ppg/apg-223
    retrieved: 2026-07-06
    path: docs/sources/apra/apg-223-residential-mortgage-lending_0.pdf
---

# Fixed-rate roll-off planning

A **fixed-rate** loan locks the interest rate for a set term (commonly **1–5 years**); when that term ends — the **roll-off** — the loan reverts to the lender's **revert rate** (usually a higher standard variable rate) unless the borrower acts. This doc owns the **roll-off planning** consideration so `mortgage_finance` can flag the roll-off as a scheduled future event and prompt the refinance/renegotiation window. It is a **reference** doc — informational, not a recommendation to fix or to refinance (ACL line).

## What happens at roll-off

At the end of the fixed term the loan **automatically reverts to the revert rate** — typically the lender's standard variable rate, often **higher** than both the expired fixed rate and the rates available to new customers. Repayments can step up sharply if the borrower does nothing. The roll-off is a **known, dated event** from the day the loan settles — the plan treats it as a scheduled cash-flow milestone, not a surprise.

## The refinance / renegotiation window

The action is to **review ahead of roll-off** — commonly **~2–3 months before** — and either renegotiate with the current lender or refinance to another. Acting before the revert rate kicks in avoids paying it even briefly. For an investor this review also re-tests the whole position (rates, structure, whether to re-fix or move to variable), and any refinance triggers a **full serviceability re-test** (owned by [`kb.lender.serviceability-investment-loans`](../lender/serviceability-investment-loans.md)).

## The "mortgage prison" risk

If serviceability has **tightened since the loan was written** — rates up, income down, more debt, or the DTI cap — the borrower may **not qualify to refinance** at roll-off and is **stuck on the revert rate** ("mortgage prison"). This is a real risk for geared investors whose capacity falls as the portfolio grows. The plan flags roll-off early so the borrower can prepare (reduce other debt, gather documents) rather than discover the constraint at roll-off.

## Break costs and fixed-rate restrictions

- **Break costs** — exiting a fixed loan **early** (refinancing or selling before the term ends) can incur **break costs**, which can be substantial when rates have fallen since fixing. The plan flags break costs as a consideration before fixing and before any early exit.
- **Restrictions during the fixed term** — fixed loans commonly **limit extra repayments** and may **not offer a full offset**, which matters for an investor managing cash flow and deductibility (cross-ref [`kb.loan.offset-vs-redraw-investor`](offset-vs-redraw-investor.md)). A common structure is to **split** the loan (part fixed, part variable-with-offset) — surfaced as a decision-support option, not a recommendation.

## Relevance for Vietnamese-Australian investors (Mode C)

- **Roll-off is a dated milestone.** The plan schedules the roll-off and the ~2–3-month review window so the borrower never silently lands on the revert rate.
- **Mortgage prison is a real geared-investor risk.** The plan flags that falling capacity can block refinancing at roll-off, prompting preparation ahead of time.
- **Fixing has trade-offs.** Break costs and restricted offset/extra repayments are surfaced so fixing is weighed against an investor's cash-flow and deductibility needs — a split is one option.
- **Information, not advice.** Whether to fix, re-fix, or move to variable is decided with a broker; the plan stays informational (ACL line).

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **reference** doc — it fills no slot; the roll-off **date** is placed by the resolver as a scheduled milestone from the fixed term and settlement date, and the revert-rate step-up is resolver-computed from the loan terms. The figures are loan-specific, not regulated constants.

```jsonc
{
  "fills": [],
  "parameters": {
    "fixed_term_years_typical_range": { "type": "string", "value": "1-5", "note": "CONVENTION — typical fixed-rate terms; the roll-off date is placed by the resolver from the term + settlement date as a scheduled milestone" },
    "reverts_to_revert_rate_at_roll_off": { "type": "bool", "value": true, "note": "at roll-off the loan auto-reverts to the lender's revert (standard variable) rate — usually higher; a known, dated future cash-flow step-up" },
    "refinance_review_window_months_before": { "type": "integer", "value": 3, "note": "CONVENTION — review ~2–3 months before roll-off to renegotiate or refinance before the revert rate applies; refinance triggers a full serviceability re-test" },
    "mortgage_prison_risk_if_serviceability_tightened": { "type": "bool", "value": true, "note": "if serviceability has tightened since the loan was written the borrower may not qualify to refinance and is stuck on the revert rate; a real geared-investor risk — flagged early to prepare" },
    "break_costs_on_early_exit":      { "type": "bool", "value": true, "note": "exiting a fixed loan early can incur substantial break costs (largest when rates have fallen since fixing); a consideration before fixing and before any early exit" },
    "fixed_restricts_offset_extra_repayments": { "type": "bool", "value": true, "note": "CONVENTION — fixed loans commonly limit extra repayments and may not offer a full offset; a split (fixed + variable-with-offset) is one decision-support option" }
  }
}
```

Notes:

- **No `fills`.** The roll-off date is placed by the resolver as a scheduled milestone (from the fixed term + settlement date); the revert-rate step-up is resolver-computed from the loan terms. The doc supplies the planning framing.
- **Loan-specific, not regulated.** Fixed terms, revert rates, break costs, and the review window are lender/loan specifics flagged as conventions — kept on the information side of the ACL line.
- **Cross-refs, not duplicates.** The serviceability re-test on refinance is owned by `kb.lender.serviceability-investment-loans`; offset/extra-repayment treatment by `kb.loan.offset-vs-redraw-investor`. This doc owns the *roll-off planning* consideration.

## Sources

- ASIC Moneysmart — *Fixed and variable home loans* (revert rate at the end of a fixed term; break costs; review before roll-off) — https://moneysmart.gov.au/home-loans/choosing-a-home-loan
- ASIC Moneysmart — *Switching home loans* (refinancing; comparing the revert rate; costs of switching) — https://moneysmart.gov.au/home-loans/switching-home-loans
- APRA — *APG 223 Residential Mortgage Lending* (serviceability re-test on refinance) — https://handbook.apra.gov.au/ppg/apg-223
