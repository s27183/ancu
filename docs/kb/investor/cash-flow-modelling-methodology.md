---
slug: kb.investor.cash-flow-modelling-methodology
effective_from: 2025-07-01
last_verified: 2026-07-06
sources:
  - url: https://moneysmart.gov.au/property-investment/buying-an-investment-property
    retrieved: 2026-07-06
  - url: https://www.ato.gov.au/individuals-and-families/investments-and-assets/property-and-land/residential-rental-properties
    retrieved: 2026-07-06
---

# Cash-flow modelling — methodology

This doc owns the **methodology** that assembles the `yield_modelling` outcome (`cash_flow_projection`): how effective rental income, operating expenses and loan interest combine into the **yields** and **before-tax cash flow**, and how the year-1 figure is projected to **year 5 and year 10**. It is the spine that ties the other `yield_modelling` anchors together — it owns no input figure of its own, only the **order of operations** and the projection assumptions. Pure **reference**: every figure is resolver-computed (removed from the LLM's reach); the doc supplies the formulas and the labelled growth assumptions. Decision-support, not a forecast.

## The order of operations

The resolver builds the projection bottom-up so each layer is visible:

1. **Effective annual rental income** — gross rent × 52 × (1 − vacancy). Owned by [`kb.investor.rental-income-modelling`](rental-income-modelling.md) (+ [`kb.investor.vacancy-rate-assumptions`](vacancy-rate-assumptions.md)).
2. **Operating expenses (annual)** — the itemised cost lines summed. Owned by [`kb.investor.operating-expenses-typical-ratios`](operating-expenses-typical-ratios.md) (+ PM fees, land tax, body corporate by their owners).
3. **Loan interest (annual)** — the financing cost, modelled separately from operating expenses. Comes from the `mortgage_finance` loan structure (loan amount × assumed rate; interest-only vs P&I per [`kb.loan.interest-only-vs-pi-investor`](../loan/interest-only-vs-pi-investor.md)).

From these three the resolver derives:

- **Gross rental yield** = annual **gross** rent ÷ property price.
- **Net rental yield (pre-loan)** = (effective income − operating expenses) ÷ property price. The property's return *before financing* — comparable across properties regardless of how each is geared.
- **Net rental yield (post-loan, pre-tax)** = (effective income − operating expenses − loan interest) ÷ property price. After financing, before tax.
- **Cash flow before tax (year 1)** = effective income − operating expenses − loan interest. Positive, neutral, or **negative** (negatively geared) — the headline the investor feels each year, surfaced annually **and per week**.
- **Geared position** = the sign of the before-tax cash flow → `positive` / `neutral` / `negative`. The *tax* effect of negative gearing is modelled separately by `tax_structure` (owned by [`kb.tax.negative-gearing-mechanics`](../tax/negative-gearing-mechanics.md)) — never conflated with the pre-tax cash position.

## The multi-year projection — and its labelled assumptions

Year-1 figures are projected forward by growing income and expenses at assumed annual rates:

- **Rent growth assumed** — default **3% p.a.**
- **Expense growth assumed** — default **3% p.a.**

These are **planning assumptions, not forecasts** — flagged as such and surfaced in `key_assumptions`. The resolver compounds them to a **year-5** and **year-10** cash-flow estimate, carried as a banded/indicative figure (the assumptions drive it, so it moves with them). **Capital growth** is *not* modelled here — sale-value projection is owned by [`kb.property.capital-growth-bands`](../property/capital-growth-bands.md) and consumed by `disposition`; this doc projects only the **cash-flow** line, not the asset value.

## Relevance for Vietnamese-Australian investors (Mode C)

- **The investor sees the build-up, not a single number.** Income → less expenses → less interest → cash flow, with two yields (pre- and post-loan) so the property's intrinsic return and the geared return are both visible.
- **Pre-tax cash flow first, tax effect separately.** The plan shows the real annual (and weekly) cash position before tax, then `tax_structure` adds the negative-gearing tax effect — kept apart so neither is mistaken for the other.
- **The forward projection is assumption-driven.** Year-5/10 figures depend on the 3% rent/expense assumptions; the plan states them and treats the figures as indicative, not promises.
- **Information, not advice.** The plan models the cash flow; it makes no recommendation to buy, gear, or hold.

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **reference** doc — it fills no slot; the entire `cash_flow_projection` outcome is **resolver-computed** from the upstream figures by the formulas below (control flow → code, §11.9). The growth assumptions are labelled planning conventions.

```jsonc
{
  "fills": [],
  "parameters": {
    "gross_yield_formula": { "type": "string", "value": "gross_rental_yield = annual_gross_rental_income / property_price", "note": "resolver formula — uses GROSS rent" },
    "net_yield_pre_loan_formula": { "type": "string", "value": "net_yield_pre_loan = (effective_annual_rental_income − annual_operating_expenses) / property_price", "note": "resolver formula — the property's return before financing; comparable across properties" },
    "net_yield_post_loan_formula": { "type": "string", "value": "net_yield_post_loan_pre_tax = (effective_annual_rental_income − annual_operating_expenses − annual_interest) / property_price", "note": "resolver formula — after financing, before tax" },
    "cash_flow_before_tax_formula": { "type": "string", "value": "cash_flow_before_tax_year_1 = effective_annual_rental_income − annual_operating_expenses − annual_interest", "note": "resolver formula — the headline annual cash position; also surfaced per week (÷52)" },
    "geared_position_rule": { "type": "string", "value": "sign(cash_flow_before_tax_year_1) → positive | neutral | negative", "note": "the PRE-TAX geared position; the TAX effect of negative gearing is owned separately by tax_structure (kb.tax.negative-gearing-mechanics), never conflated" },
    "interest_is_separate_from_opex": { "type": "bool", "value": true, "note": "loan interest is a FINANCING cost modelled separately from operating expenses, so the pre-loan and post-loan yields are both visible" },
    "rent_growth_assumed_pct_pa": { "type": "percentage", "value": 3, "note": "CONVENTION / planning assumption (not a forecast) — annual rent growth used to project year-5/10 cash flow; stated in key_assumptions" },
    "expense_growth_assumed_pct_pa": { "type": "percentage", "value": 3, "note": "CONVENTION / planning assumption — annual operating-expense growth for the projection; stated in key_assumptions" },
    "projection_method": { "type": "string", "value": "compound year-1 income and expenses at the assumed growth rates to year 5 and year 10; surface as indicative, assumption-driven figures", "note": "the multi-year cash-flow projection method" },
    "capital_growth_not_modelled_here": { "type": "bool", "value": true, "note": "this doc projects CASH FLOW only; sale-value/capital-growth projection is owned by kb.property.capital-growth-bands and consumed by disposition — single-owner" }
  }
}
```

Notes:

- **No `fills`.** The whole `cash_flow_projection` outcome is resolver-computed from upstream figures; the doc owns the order of operations and the projection assumptions, not any input figure.
- **Pre-loan vs post-loan yield.** Two yields are computed so the property's intrinsic return (pre-financing) and the geared return (post-financing) are both shown — financing structure is isolated, not baked in.
- **Cash flow ≠ tax position.** The geared position here is pre-tax; the negative-gearing *tax* effect is owned by `kb.tax.negative-gearing-mechanics`. Kept apart per the single-owner discipline.
- **Capital growth is elsewhere.** Sale-value projection (the one genuinely uncertain input) is owned by `kb.property.capital-growth-bands`; this doc never projects asset value, only cash flow.

## Sources

- ASIC Moneysmart — *Investing in property* (rental yield, ongoing costs, and cash flow as the components of property return) — https://moneysmart.gov.au/property-investment/investing-in-property
- ATO — *Residential rental properties* (rental income and the deductible expenses that net against it) — https://www.ato.gov.au/individuals-and-families/investments-and-assets/property-and-land/residential-rental-properties
