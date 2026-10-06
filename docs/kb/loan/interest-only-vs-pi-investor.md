---
slug: kb.loan.interest-only-vs-pi-investor
effective_from: 2025-07-01
last_verified: 2026-07-09
sources:
  - url: https://handbook.apra.gov.au/ppg/apg-223
    retrieved: 2026-07-06
    path: docs/sources/apra/apg-223-residential-mortgage-lending_0.pdf
---

# Interest-only vs principal-and-interest — for investors

The repayment structure — **interest-only (IO)** or **principal-and-interest (P&I)** — is one of the first investment-loan decisions, and it interacts with both cash flow and tax. This doc owns the **trade-off framing** so `mortgage_finance` and `tax_structure` can present IO vs P&I as a decision-support comparison: what each does to cash flow, equity, lifetime cost, deductibility, and the eventual reversion. It does **not** tell the investor which to choose. It is **decision-support**, framed to the ACL line — options and consequences, never "choose IO."

## What each structure does

- **Interest-only** — repayments cover **interest only** for the IO period (commonly up to 5 years). Repayments are **lower**, freeing cash flow, but the **loan balance does not reduce** — no equity is built through repayment. At the end of the IO period the loan **reverts to P&I over the residual term** (a 30-year loan after a 5-year IO period amortises over the remaining 25 years), so repayments **step up sharply** — the payment shock.
- **Principal-and-interest** — repayments cover interest **and** principal from the start. Repayments are **higher**, but the balance reduces, equity builds through repayment, and **lifetime interest is lower**.

## The tax interaction

For an investment property, **interest is deductible; principal repayments are not**. IO maximises the **deductible** portion of each repayment and keeps the **deductible debt** high — which is why IO is common among investors using a negative-gearing strategy (cross-ref [`kb.tax.negative-gearing-mechanics`](../tax/negative-gearing-mechanics.md)). Paying down principal (P&I) reduces deductible interest over time. This is a genuine interaction, but it is **not** a reason to choose IO on its own: IO costs more in total interest, builds no equity through repayment, and the deduction is a saving on a real cost, not a gain. The plan presents the interaction, never a verdict.

**Reform interaction (enacted, not yet in effect).** The *Treasury Laws Amendment (Tax Reform No. 1) Act 2026* (Act No. 49 of 2026, assented 26 June 2026) **limits negative gearing to new builds** from **1 July 2027**, with established post-Budget purchases losing the wage offset (held-before-Budget grandfathered) — see the enacted-reform section of [`kb.tax.negative-gearing-mechanics`](../tax/negative-gearing-mechanics.md). The tax rationale for IO on an established post-Budget purchase weakens from that date (losses would offset only rental income / future capital gains, not wages). The plan computes current law, flags the enacted reform, and defers the post-2027 position to `to_verify` — it does not model the pre-effective-date position as already changed.

## The serviceability consequence

IO does **not** increase borrowing capacity. Lenders assess IO on a **P&I basis over the residual term** at the buffered rate (the residual-term method, owned by [`kb.lender.serviceability-investment-loans`](../lender/serviceability-investment-loans.md)) — so an IO loan yields a **lower** maximum loan, not a higher one. IO is a cash-flow choice, not a capacity lever.

## Relevance for Vietnamese-Australian investors (Mode C)

- **IO is a cash-flow tool, not free borrowing.** The plan shows the reversion step-up and that capacity is *lower* under IO — countering the idea that IO lets you borrow more.
- **The deduction is a saving on a cost.** The plan frames IO's tax appeal as keeping deductible interest high, not as a gain — and notes the enacted reform that narrows it for established purchases from 1 July 2027.
- **Plan for the reversion.** The IO period ends; the plan flags the residual-term P&I step-up as a future cash-flow event, not a surprise.
- **Decision-support only.** Options and consequences; the investor (with a broker / tax adviser) chooses (ACL line).

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **decision-support** doc — it fills no slot; it supplies the trade-off framing and the policy flag that keeps the comparison option-neutral. Repayment figures (IO repayment, the residual-term P&I step-up) are resolver-computed from the loan terms, not asserted.

```jsonc
{
  "fills": [],
  "parameters": {
    "io_vs_pi_is_decision_support":   { "type": "bool", "value": true, "note": "presents options + consequences; the plan never issues an IO-or-P&I verdict (ACL line)" },
    "io_reverts_to_pi_residual_term": { "type": "bool", "value": true, "note": "at the end of the IO period the loan amortises over the RESIDUAL term — repayments step up (payment shock); a planned future cash-flow event" },
    "io_max_term_years_typical":      { "type": "integer", "value": 5, "note": "CONVENTION — typical maximum initial IO term; lender policy (owned by kb.lender.investment-loan-policies)" },
    "principal_not_deductible_interest_deductible": { "type": "bool", "value": true, "note": "REGULATED (ATO) — for an investment property interest is deductible, principal is not; IO maximises the deductible portion and keeps deductible debt high (cross-ref kb.tax.negative-gearing-mechanics)" },
    "io_does_not_increase_capacity":  { "type": "bool", "value": true, "note": "IO is assessed as P&I over the residual term (kb.lender.serviceability-investment-loans) → IO yields a LOWER max loan, not a capacity lever" },
    "negative_gearing_reform_narrows_io_rationale": { "type": "bool", "value": true, "note": "ENACTED, not yet in effect — Tax Reform No. 1 Act 2026 (Act No. 49/2026, assented 26 Jun 2026) limits negative gearing to new builds from 1 Jul 2027; the IO tax rationale weakens for established post-Budget purchases from that date. Compute current law, flag, to_verify post-2027 (owned by kb.tax.negative-gearing-mechanics)" }
  }
}
```

Notes:

- **No `fills`.** The doc supplies the decision framing; repayment figures are resolver-computed from the loan terms (loan amount, rate + buffer, IO period, residual term) — §11.9 keeps the amortisation in code.
- **Decision-support, not a verdict.** `io_vs_pi_is_decision_support` enforces the option-neutral framing; the doc never asserts IO or P&I is "better."
- **Cross-refs, not duplicates.** Serviceability treatment is owned by `kb.lender.serviceability-investment-loans`; the negative-gearing mechanics and the enacted reform by `kb.tax.negative-gearing-mechanics`; the IO-term policy by `kb.lender.investment-loan-policies`. This doc owns the *IO-vs-P&I comparison*.
- **Reform handled per the cross-cutting rule.** Current law computed; the enacted 1 Jul 2027 negative-gearing change flagged; post-2027 position → `to_verify` (do not model the pre-effective-date position as already changed).

## Sources

- ATO — *Interest expenses* (interest on a loan to acquire an income-producing asset is deductible; principal is not) — https://www.ato.gov.au/individuals-and-families/investments-and-assets/property-and-land/residential-rental-properties/rental-expenses/interest-expenses
- APRA — *APG 223 Residential Mortgage Lending* (interest-only assessed over the residual term) — https://handbook.apra.gov.au/ppg/apg-223
- ASIC Moneysmart — *Interest-only home loans* (lower repayments now, higher later; no equity built; costs more overall) — https://moneysmart.gov.au/home-loans/interest-only-home-loans
- Federal Register of Legislation — *Treasury Laws Amendment (Tax Reform No. 1) Act 2026* (Act No. 49 of 2026, assented 26 Jun 2026 — negative gearing limited to new builds from 1 Jul 2027) — https://www.legislation.gov.au/C2026A00049/latest/text
