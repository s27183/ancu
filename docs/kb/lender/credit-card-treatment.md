---
slug: kb.lender.credit-card-treatment
effective_from: 2019-01-01
last_verified: 2026-06-01
---

# Credit-card treatment in serviceability — by lender

A credit card reduces borrowing capacity even when its balance is zero, because lenders assess it on the **limit, not the balance**. That principle is stated in [`kb.lender.serviceability-basics`](serviceability-basics.md); this doc owns the **detail and the variation** — the assumed-repayment convention lenders apply to the limit, and why reducing or closing limits is the single most reliable pre-application capacity lever. It grounds `mortgage_finance.debt_optimisation_recommendations.credit_cards`.

## Why the limit, not the balance

A balance fluctuates month to month and can be cleared before settlement; the **limit** is the maximum the borrower could draw at any time, so lenders treat the **full limit** as the exposure to service. An unused card with a $20,000 limit is assessed as if it carried a committed repayment on $20,000 — even at a zero balance. This is why **lowering a limit or closing a card** lifts capacity immediately and predictably, unlike most other optimisations.

## The assumed-repayment convention

For home-loan serviceability, lenders convert the limit into a monthly commitment using an **assumed minimum repayment**, conventionally **~3% to 3.8% of the limit per month** (the figure varies by lender). So a $10,000 limit is assessed as roughly **$300–$380/month** of commitment regardless of the actual balance or the card's real minimum payment.

This sits on top of a separate, **regulated** rule that governs the **card issuer's own** responsible-lending assessment: since **1 January 2019**, a credit-card provider must assess a new card (or limit increase) on the borrower's ability to **repay the full credit limit within a set period** (ASIC set this at **three years**). That issuer-side rule and the home-loan serviceability convention are related (both anchor on repaying the limit, not the balance) but distinct — the 3-year rule binds the card issuer; the ~3–3.8%/month figure is what a *mortgage* lender subtracts from surplus.

## The optimisation

- **Close unused cards** entirely before applying — removes the full assumed commitment.
- **Reduce limits** on cards the borrower keeps to the level actually needed — capacity rises in proportion to the limit cut.
- **Timing.** Limit reductions and closures should be done **before** submitting, and evidenced, since the assessment reads current limits. This is the content of `mortgage_finance.debt_optimisation_recommendations.credit_cards.limits_to_reduce` and `close_unused_cards_recommended`.

## Relevance for Vietnamese-Australian buyers (Mode A)

- Credit-card limits are one of the **most common silent capacity drags** for Mode A buyers — often a high limit on a barely-used card. It is also the **cheapest to fix**: closing or reducing a limit costs nothing and the capacity uplift is immediate, unlike clearing HECS (which drains deposit cash).
- Surface this early, alongside the HECS reasoning, as a no-cost lever — but as **information**: the agent shows the assessed cost of the limit and the uplift from reducing it; the buyer decides. No direction to a specific product or lender (ASIC: no credit advice).

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **reference doc** — it fills no slot. The assessed credit-card commitment and the capacity uplift from reducing a limit are **resolver/agent-computed** from `profile.credit_card_limits_total` and these parameters, not asserted here.

```jsonc
{
  "fills": [],
  "parameters": {
    "assessed_on_limit_not_balance":        { "type": "bool",    "value": true, "note": "lenders assess the full credit limit as exposure, independent of the current balance — closing/reducing a limit is the lever" },
    "assumed_monthly_repayment_pct_of_limit_low":  { "type": "percentage", "value": 3.0,  "note": "CONVENTION — low end of the assumed monthly minimum repayment applied to the limit in home-loan serviceability; lender-specific" },
    "assumed_monthly_repayment_pct_of_limit_high": { "type": "percentage", "value": 3.8,  "note": "CONVENTION — high end of the same assumed-repayment range; lender-specific, not a regulated figure" },
    "issuer_repay_limit_within_years":      { "type": "integer", "value": 3,    "note": "REGULATED (ASIC, from 1 Jan 2019) — a CARD ISSUER must assess ability to repay the full limit within 3 years; binds the issuer, distinct from the mortgage-serviceability convention above" }
  }
}
```

Notes:

- **No `fills`.** No outcome leaf is set. The assessed monthly commitment (limit × assumed %) and the uplift from a limit reduction are resolver-computed in `mortgage_finance` from `profile.credit_card_limits_total`. The doc supplies the convention range and the limit-not-balance principle.
- **One regulated figure, the rest convention.** Only `issuer_repay_limit_within_years` (the 3-year rule) is a hard regulatory constant, and it governs the **card issuer**, not the mortgage assessment. The ~3–3.8%/month range a mortgage lender applies is **industry convention**, flagged `CONVENTION` and given as a low/high band rather than a single number — the agent presents it as typical, defers the exact figure to the lender. Same ASIC-line discipline as [`kb.lender.serviceability-basics`](serviceability-basics.md).
- **Band as two parameters, not a `lookup`.** The convention is a simple low/high range, not a keyed table, so it is two scalar parameters the resolver reads — `lookup` would be over-modelling (cf. the HECS schedule, which genuinely needs ordered bands).

## Sources

- ASIC — *Credit cards: Responsible lending assessments* (CP 303; from 1 January 2019 issuers assess ability to repay the credit limit within a prescribed period — set at three years) — https://download.asic.gov.au/media/4801736/cp303-published-4-july-2018.pdf
- ASIC Instrument 20-0746 (prescribed period for credit-card responsible-lending assessment) — https://download.asic.gov.au/media/5734771/asic-instrument-20-0746.pdf
- ASIC Moneysmart — *How much you can borrow* (lenders assess existing debts including credit-card limits against borrowing capacity) — https://moneysmart.gov.au/home-loans/how-much-you-can-borrow
