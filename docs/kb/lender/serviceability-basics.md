---
slug: kb.lender.serviceability-basics
effective_from: 2021-10-06
last_verified: 2026-07-06
sources:
  - url: https://www.apra.gov.au/activating-debt-to-income-limits-as-a-macroprudential-policy-tool
    retrieved: 2026-07-06
    note: 27 Nov 2025 announcement — serviceability buffer remains steady at 3 per cent; DTI ≥6 = high-DTI, capped at 20% of new lending from Feb 2026
  - url: https://www.apra.gov.au/news-and-publications/apra-announces-update-on-macroprudential-settings
    retrieved: 2026-07-06
    note: 23 Jul 2025 update — "the mortgage serviceability buffer will remain at 3 percentage points"
---

# Lender serviceability basics

**Serviceability** is a lender's test of whether a borrower can afford the loan: assessable income, minus living expenses, minus existing debt commitments, must cover the repayment **assessed at a buffered interest rate**. It is the gate that sets borrowing capacity — distinct from eligibility (whether a scheme applies) and from the cash-at-settlement test ([`kb.cash-reserve.lender-expectations`](../cash-reserve/lender-expectations.md)). This doc owns the **universal framework** that every lender shares; the per-lender variation in treating specific debts lives in the lender-specific docs ([`kb.lender.hecs-treatment-by-lender`](hecs-treatment-by-lender.md), [`kb.lender.credit-card-treatment`](credit-card-treatment.md), [`kb.lender.bnpl-treatment-2026`](bnpl-treatment-2026.md)).

It is the grounding for three components: `buyer_profile` (framing the income/debt facts and the `approx_borrowing_capacity` estimate), `eligibility` (whether a buyer can service a scheme-backed loan), and `mortgage_finance` (the borrowing-capacity figures and debt-optimisation reasoning).

## The APRA serviceability buffer

The one regulated constant: when assessing a new loan, an ADI must test the borrower's ability to repay at an interest rate **at least 3.0 percentage points above** the loan product rate. APRA set the buffer at **3.0 pp on 6 October 2021** (up from 2.5 pp) and **reaffirmed it in November 2025**. So a borrower offered 6.0% is assessed at **9.0%** — the buffer, not the actual rate, sets capacity.

A consequence for the FHB plan: capacity is materially lower than the headline rate implies, and a rate cut does **not** lift capacity unless lenders move the assessment floor. The buffer is why `mortgage_finance` models capacity at `product_rate + 3pp`, not at the product rate.

## What counts as income (and how much)

Lenders **shade** non-base income to allow for variability — exact factors are lender policy, but the conventions are:

- **Base PAYG salary** — counted in full.
- **Overtime, bonuses, commissions** — typically counted at **~80%** (some lenders less for volatile income).
- **Casual / contract income** — counted with a haircut and often a minimum employment-tenure requirement.
- **Self-employed** — usually two years' tax returns, averaged; the hardest to assess.
- **Rental income** (for an investment or dual-occupancy) — typically counted at **~80%** to allow for vacancy and costs.

`income_stability` on the profile surface (`permanent_payg` / `contractor` / `self_employed` / `casual` / `mixed`) is the fact that drives which shading applies.

## What counts against capacity (expenses and debts)

- **Living expenses** — the greater of the borrower's **declared** expenses or the lender's **HEM** (Household Expenditure Measure) benchmark, which scales by income, location, and household size. A borrower cannot declare implausibly low expenses to inflate capacity; HEM floors it.
- **HECS-HELP** — the compulsory repayment at the borrower's income is a committed expense (schedule: [`kb.hecs.thresholds`](../hecs/thresholds.md)). Drag scales with income, not balance.
- **Credit cards** — assessed on the **limit, not the balance** (a minimum monthly repayment on the full limit), so an unused card with a high limit still cuts capacity. This is why closing or reducing limits is a common pre-application optimisation.
- **BNPL, personal and car loans** — counted at their committed repayment.

## Debt-to-income (DTI) monitoring

Beyond serviceability, APRA monitors **high-DTI** lending as a macroprudential setting: a loan at **total debt ≥ 6× gross income** is flagged as high-DTI, and lenders limit the share of such loans they write. A borrower near 6× DTI may pass the buffer test yet still be constrained by the lender's DTI policy. This is a ceiling distinct from the buffer.

## Genuine savings

For a loan above 80% LVR (the typical FHB / LMI / FHG case), most lenders require **genuine savings**: commonly **~5% of the purchase price** accumulated and **held for at least 3 months** (regular savings, not a sudden lump sum). A family gift can fund the deposit but may not count as genuine savings on its own — relevant to the Mode A `family_gift_or_loan_amount` and `genuine_savings_evidence_months` facts.

## Relevance for Vietnamese-Australian buyers (Mode A)

- **Family gifting is common in the diaspora**, but a lump-sum gift may fail the genuine-savings test — surface the 3-month-held / 5% convention early so the buyer structures the deposit to qualify.
- **Professional incomes with HECS** are the typical profile; the buffer + HECS drag together are usually the binding capacity constraint, ahead of the deposit.
- **The figures other than the 3.0 pp buffer are lender-policy conventions, not regulated constants** — surface them as typical ranges and defer the precise treatment to the lender-specific docs and a broker, staying on the information / decision-support side of the ASIC line (no credit advice).

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **reference doc** — it fills no slot. `approx_borrowing_capacity` and the `mortgage_finance` capacity figures are **resolver/agent-computed** from these parameters (formula → code, per §11.9), not asserted. The only regulated constant is the buffer; the rest are representative conventions flagged as such.

```jsonc
{
  "fills": [],
  "parameters": {
    "apra_serviceability_buffer_pp": { "type": "percentage", "value": 3.0,  "note": "REGULATED — assess at product_rate + 3.0pp; set 6 Oct 2021, reaffirmed Nov 2025" },
    "high_dti_threshold":            { "type": "number",     "value": 6,    "note": "total debt ÷ gross income ≥6 flagged high-DTI by APRA; lenders cap the share of such loans" },
    "genuine_savings_min_pct":       { "type": "percentage", "value": 5,    "note": "CONVENTION (lender policy) — typical genuine-savings requirement above 80% LVR, as % of purchase price" },
    "genuine_savings_min_months":    { "type": "integer",    "value": 3,    "note": "CONVENTION — minimum hold period for funds to count as genuine savings" },
    "income_shading_overtime_bonus_pct": { "type": "percentage", "value": 80, "note": "CONVENTION — typical proportion of overtime/bonus/commission counted; lender-specific" },
    "income_shading_rental_pct":     { "type": "percentage", "value": 80,   "note": "CONVENTION — typical proportion of rental income counted (vacancy/cost allowance); lender-specific" },
    "living_expenses_basis":         { "type": "string",     "value": "greater of declared expenses or HEM benchmark", "note": "HEM scales by income, location, household size — no single figure; the convention BAND the capacity resolver subtracts is owned by kb.lender.hem-living-expenses (the 'gets its own doc' note below, now authored)" },
    "representative_product_rate_pct": { "type": "percentage", "value": 6.0, "note": "CONVENTION — representative owner-occupier variable rate used as the capacity assessment BASE when no specific product is chosen; assessment rate = this + apra_serviceability_buffer_pp (= 9.0%). Labelled, re-groundable; the agent's lender_fit rate NEVER overrides this resolver figure (§98 — capacity removed from the LLM's reach)" },
    "loan_term_years":                 { "type": "integer",    "value": 30,  "note": "CONVENTION — standard P&I term for the capacity present-value inversion (matches fh_engine_disposition's amortisation constant)" },
    "consumer_loan_monthly_repayment_pct_of_balance": { "type": "percentage", "value": 2.5, "note": "CONVENTION — personal/car/BNPL balances are counted as a monthly commitment ≈ this % of balance (conservative; over-stating a commitment under-states capacity, the safe direction). Credit cards use the card-specific limit band in kb.lender.credit-card-treatment; HECS uses the income-contingent schedule in kb.hecs.thresholds" }
  }
}
```

Notes:

- **No `fills`.** The capacity outputs (`profile.approx_borrowing_capacity`, `mortgage_finance.borrowing_capacity.*`) are **computed** by the resolver/agent from these parameters and the buyer's income/debts — a formula, which §11.9 keeps in code, not in `content_json`. The doc supplies the buffer and conventions the formula consumes.
- **One regulated constant, the rest conventions.** Only `apra_serviceability_buffer_pp` is a hard regulatory figure (and it is the load-bearing one — it sets capacity). The shading percentages, genuine-savings rule, and DTI threshold are **industry conventions / macroprudential guidance** and are flagged `CONVENTION` in their notes so the agent presents them as typical, not as the borrower's actual lender policy. This keeps the doc on the information side of the ASIC line ([CLAUDE.md] no credit advice).
- **Per-lender debt treatment lives elsewhere.** This doc states the *principle* (credit cards assessed on limit; HECS repayment as a commitment); the *specific* lender-by-lender treatment that drives the `mortgage_finance` shortlist is owned by [`kb.lender.hecs-treatment-by-lender`](hecs-treatment-by-lender.md), [`kb.lender.credit-card-treatment`](credit-card-treatment.md), and [`kb.lender.bnpl-treatment-2026`](bnpl-treatment-2026.md). No duplication — this is the framework, those are the variations.
- **HEM has no single value.** It is a benchmark table varying by income / location / household, maintained by the Melbourne Institute and applied per-lender. Recorded as a basis string, not a number; if a HEM lookup is ever needed it gets its own doc.

## Sources

- APRA — *APRA announces update on macroprudential settings* (Nov 2025; serviceability buffer retained at 3.0 percentage points) — https://www.apra.gov.au/news-and-publications/apra-announces-update-on-macroprudential-settings
- APRA — *APRA increases banks' loan serviceability expectations* (6 October 2021; buffer raised to 3.0 pp) — https://www.apra.gov.au/news-and-publications/apra-increases-banks%E2%80%99-loan-serviceability-expectations-to-counter-rising
- ASIC Moneysmart — *How much you can borrow* (serviceability, living expenses, buffer) — https://moneysmart.gov.au/home-loans/how-much-you-can-borrow
- APRA — *Macroprudential policy: high debt-to-income lending* (DTI ≥6 monitoring) — https://www.apra.gov.au/news-and-publications/apra-announces-update-on-macroprudential-settings
