---
slug: kb.lender.serviceability-investment-loans
effective_from: 2026-02-01
last_verified: 2026-07-06
sources:
  - url: https://www.apra.gov.au/activating-debt-to-income-limits-as-a-macroprudential-policy-tool
    retrieved: 2026-07-06
    note: 27 Nov 2025 — APRA activating a binding DTI limit; ADIs must limit new lending at DTI ≥6 to 20% of all new mortgage lending from Feb 2026, applied to owner-occupier and investor portfolios separately
  - url: https://handbook.apra.gov.au/ppg/apg-223
    retrieved: 2026-07-06
    path: docs/sources/apra/apg-223-residential-mortgage-lending_0.pdf
    note: APG 223 — interest-only assessed on P&I over the residual term; prudent IO practices
---

# Serviceability — investment loans

Investment-loan serviceability shares the universal framework owned by [`kb.lender.serviceability-basics`](serviceability-basics.md) — assessable income, minus living expenses (HEM floor), minus debt commitments, must cover the repayment **assessed at the product rate + the APRA 3.0 pp buffer**. This doc owns only the **investment-specific deltas** that make an investor's borrowing capacity differ from an owner-occupier's: how rental income is counted, how interest-only is assessed, the investment-rate premium, how existing-property commitments stack, and the macroprudential DTI cap that bites investor portfolios. It does **not** re-own the buffer, HEM, or genuine-savings rules (those live in `serviceability-basics`).

It grounds `mortgage_finance` (the investor `approx_borrowing_capacity` figure, banded and resolver-computed, §98 — removed from the LLM's reach) for Mode C.

## Rental income is shaded

Lenders **shade** assessable rental income to allow for vacancy, management, and holding costs — typically counting **~80%** of gross rent (the convention is owned by `serviceability-basics`; for an investor it is the *defining* income delta). A few lenders use a net-rental method instead. The shaded rent is added to assessable income; the property's full mortgage repayment (at the buffered rate) is counted against capacity. For a negatively geared property the **net** effect on capacity is usually negative — the buffered repayment exceeds the shaded rent — which is why an investor's capacity can fall as the portfolio grows even though each property "pays for itself" on paper.

## Interest-only is assessed as P&I over the residual term

This is the load-bearing investment-serviceability fact. Even when an investor applies for an **interest-only (IO)** loan, lenders assess capacity on a **principal-and-interest basis over the residual term** — the term remaining *after* the IO period ends (a 30-year loan with a 5-year IO period is assessed on 25-year P&I repayments), at the buffered rate. This **residual-term method** (per APRA's APG 223 prudent-practice guidance) means an IO loan yields a **lower** maximum loan size than an equivalent P&I loan, not a higher one — the cash-flow relief of IO does not translate into more borrowing capacity. The plan models IO capacity on the shorter residual P&I term, never on the IO repayment.

## The investment-rate premium

Investment loans are typically priced **~0.2–0.5 percentage points above** the equivalent owner-occupier rate (a CONVENTION — differential pricing varies by lender and over time). Because capacity is assessed at *product rate + buffer*, the higher product rate compounds into a lower assessed capacity. The plan uses a representative investment rate (labelled, re-groundable) as the assessment base; the agent's lender-fit reasoning never overrides this resolver figure.

## Existing-property commitments stack

For a portfolio investor, **every existing mortgage** is a committed expense in the new assessment — counted at the buffered rate (some lenders use the actual or a floor rate for debts held with other lenders; "debt-to-income" tightens regardless). Some lenders **add back** the tax benefit of negative gearing (the deduction's cash effect) when assessing — a CONVENTION that varies materially by lender and is not guaranteed. The plan does not assume a negative-gearing add-back; it surfaces it as a lender-policy variable a broker confirms.

## The DTI cap bites investors

Beyond the buffer, APRA's macroprudential **DTI limit** is a hard ceiling from **February 2026**: ADIs must limit new lending with **total debt ≥ 6× gross income to 20% of all new mortgage lending**, applied to **owner-occupier and investor portfolios separately**. Investors — who carry more total debt relative to income as the portfolio grows — hit this ceiling sooner than owner-occupiers. A borrower can pass the buffer test yet be declined or constrained because the lender has filled its high-DTI quota. This is distinct from the buffer and is the binding constraint on portfolio scale-up (cross-ref [`kb.loan.refinance-strategies-portfolio-growth`](../loan/refinance-strategies-portfolio-growth.md)).

## Relevance for Vietnamese-Australian investors (Mode C)

- **Capacity can shrink as the portfolio grows.** Shaded rent rarely covers the buffered repayment on a geared property; the plan shows capacity falling, not rising, with each acquisition — countering the "the rent pays the loan" intuition.
- **IO does not buy more borrowing.** The residual-term assessment means IO is a cash-flow choice, not a capacity lever — surfaced so an investor does not over-estimate what IO unlocks.
- **The DTI cap is the real ceiling for scale-up.** Past 6× income, the plan flags that the constraint is the lender's high-DTI quota, not affordability — and that it is checked at every new application and refinance.
- **Information, not credit advice.** The figures other than the buffer and the DTI cap are lender-policy conventions; the plan surfaces them as typical, defers the precise treatment to a broker, and never recommends a lender or a loan structure (ACL line).

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **reference doc** — it fills no slot; the investor `approx_borrowing_capacity` is **resolver-computed** (formula → code, §11.9) from these parameters and the buyer's income/rent/debts, never asserted by the agent. The buffer / HEM / genuine-savings framework is **owned by `kb.lender.serviceability-basics`** and referenced, not re-declared. The DTI cap is regulated; the rate premium and add-back are conventions.

```jsonc
{
  "fills": [],
  "parameters": {
    "io_assessed_as_pi_residual_term":   { "type": "bool", "value": true, "note": "REGULATED guidance (APRA APG 223) — interest-only loans assessed on P&I over the RESIDUAL term (term after the IO period), at the buffered rate; IO yields a LOWER max loan than equivalent P&I" },
    "rental_income_shading_pct":         { "type": "percentage", "value": 80, "note": "CONVENTION (lender policy) — typical proportion of gross rent counted as assessable income (vacancy/cost allowance); the general convention is owned by kb.lender.serviceability-basics — referenced here as the investor-defining delta, not re-owned" },
    "investment_rate_premium_pp":        { "type": "percentage", "value": 0.35, "note": "CONVENTION — representative premium of investment over owner-occupier product rate (~0.2–0.5pp, differential pricing varies); the assessment base = OO representative rate + this + the APRA buffer (owned by serviceability-basics). Labelled, re-groundable; the agent's lender_fit rate NEVER overrides this resolver figure (§98)" },
    "existing_property_repayments_assessed": { "type": "bool", "value": true, "note": "every existing mortgage is counted as a committed expense at the buffered rate (some lenders use actual/floor for external debt); stacks across a portfolio" },
    "negative_gearing_addback_varies":   { "type": "bool", "value": true, "note": "CONVENTION — some lenders add back the cash benefit of negative-gearing deductions in serviceability; varies materially by lender, NOT assumed by the plan — surfaced as a broker-confirmed variable" },
    "dti_high_lending_cap_share_pct":    { "type": "percentage", "value": 20, "note": "REGULATED (APRA, from Feb 2026) — ADIs must limit new lending at DTI ≥6 to 20% of new mortgage lending, applied to owner-occupier and INVESTOR portfolios SEPARATELY; the binding ceiling on portfolio scale-up. DTI threshold (6) and the buffer (3.0pp) are owned by kb.lender.serviceability-basics" }
  }
}
```

Notes:

- **No `fills`.** The investor `approx_borrowing_capacity` is computed by the resolver from these parameters plus the buyer's income, shaded rent, and existing debts — a formula §11.9 keeps in code. The doc supplies the investment-specific deltas the formula consumes.
- **Builds on, does not duplicate, `serviceability-basics`.** The buffer (3.0pp), HEM living-expense basis, genuine-savings rule, and the DTI *threshold* (6×) are owned there and referenced here; this doc declares only the investment-specific parameters. No re-declaration of the buffer.
- **Two provenance tiers.** `io_assessed_as_pi_residual_term` and `dti_high_lending_cap_share_pct` are REGULATED (APRA guidance / macroprudential setting); the rate premium, rental shading, and negative-gearing add-back are CONVENTIONS flagged so the agent presents them as typical, not as the borrower's actual lender policy — keeping the doc on the information side of the ACL line (no credit advice).
- **Removed from the LLM's reach.** Capacity is the resolver's figure; the agent reasons about *lender fit*, never recomputes the number (§98, `verify-regulated-figures-by-postcondition`).

## Sources

- APRA — *APG 223 Residential Mortgage Lending* (serviceability; interest-only assessed over the residual term; prudent IO practices) — https://handbook.apra.gov.au/ppg/apg-223
- APRA — *APRA announces update on macroprudential settings* (serviceability buffer retained at 3.0 pp; high-DTI monitoring) — https://www.apra.gov.au/news-and-publications/apra-announces-update-on-macroprudential-settings
- APRA — *Activating debt-to-income limits as a macroprudential policy tool* (from Feb 2026, DTI ≥6 lending limited to 20% of new lending, owner-occupier and investor portfolios separately) — https://www.apra.gov.au/activating-debt-to-income-limits-as-a-macroprudential-policy-tool
- ASIC Moneysmart — *Borrowing to invest* (gearing, investment-loan risks) — https://moneysmart.gov.au/how-to-invest/borrowing-to-invest
