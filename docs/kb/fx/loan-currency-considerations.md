---
slug: kb.fx.loan-currency-considerations
effective_from: 2025-07-01
last_verified: 2026-07-02
---

# Loan currency and FX exposure — where the risk actually sits

This doc owns the **boundary question** for a Vietnam-parent-funded / temp-resident buyer: *in what currency is the loan, and where does FX risk fall?* It grounds the `mortgage_finance` foreign-person variant (component 5) — specifically `loan_structure.currency_of_loan` (a fixed `AUD`) and the `recommended_path_reasoning` — by settling a common misconception before it distorts the plan. It deliberately does **not** own FX **spreads or provider pricing**: the cost of converting VN funds to AUD is owned by [`kb.fx.typical-spreads-vnd-aud`](typical-spreads-vnd-aud.md) and the transfer mechanics by the `cross_border_funding` component and its anchors. This doc draws the line; those own the numbers.

## The load-bearing fact: the loan is always AUD

**All Australian residential property loans are denominated in AUD.** Australian lenders **no longer offer foreign-currency mortgages** — a borrower cannot take out a VND-denominated (or any non-AUD) loan against Australian property. So `currency_of_loan` is fixed at `AUD`; there is no loan-currency choice to make. The plan states this plainly, because buyers funded from Vietnam often assume otherwise.

A consequence worth surfacing: because the loan is AUD, the **loan repayments carry no FX conversion on the debt itself** — the schedule is a fixed AUD obligation. FX risk does not live on the loan; it lives in two other places.

## Where FX risk actually sits

1. **On the capital transfer (one-off).** Moving the deposit and buying costs from VND to AUD incurs an FX spread — the cost owned by [`kb.fx.typical-spreads-vnd-aud`](typical-spreads-vnd-aud.md) and optimised by the `cross_border_funding` plan. This is the largest single FX cost and it is a *transfer* cost, not a *loan* cost.
2. **On ongoing servicing, only if income is foreign (recurring).** A borrower who **services an AUD loan from VND income** carries genuine ongoing FX risk: the income is earned in VND, the repayment is due in AUD, and the exchange rate moves between them. Lenders price this risk in advance through **foreign-income shading** ([`kb.lender.temp-resident-lending-policies`](temp-resident-lending-policies.md)) — which is *why* foreign income is shaded. A **485/AU-income** borrower earning AUD locally has **no** servicing FX risk, which is part of why that path is favourable ([`kb.lender.485-visa-treatment`](485-visa-treatment.md)).

So the plan's FX story is: **loan = AUD (no choice, no loan-side FX)**; **transfer = the one-off spread (owned by the FX-spread doc)**; **servicing = ongoing FX risk only for a foreign-income borrower, already priced via shading.**

## Relevance for the Vietnam-parent-funded / temp-resident buyer (Mode B)

- **Dispel the foreign-currency-loan idea early.** There is no VND mortgage; the loan is AUD. This reframes the funding question as *how to move AUD-equivalent funds efficiently*, not *what currency to borrow in*.
- **The servicing-currency question drives the path.** If ongoing repayments will come from VND income, the shading (and its capacity cost) bites; if from AUD income, it does not — this feeds `recommended_path`.
- **The spread is owned elsewhere.** This doc points to [`kb.fx.typical-spreads-vnd-aud`](typical-spreads-vnd-aud.md); it never quotes a spread.

## Rules

Pure-reference (`fills: []`). The `mortgage_finance` resolver holds `loan_structure.currency_of_loan` at `AUD` (fixed) and uses the servicing-currency distinction below in `recommended_path_reasoning`; this doc supplies the grounded boundary. No leaf asserted; no FX spread quoted here.

```jsonc
{
  "fills": [],
  "parameters": {
    "loan_currency_is_always_aud": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "all AU residential property loans are AUD-denominated; foreign-currency mortgages are no longer offered by Australian lenders — currency_of_loan is fixed, not a choice." },
    "no_fx_risk_on_loan_repayment_itself": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "the repayment schedule is a fixed AUD obligation; FX risk sits on the funds transfer and on servicing from foreign income, not on the loan denomination." },
    "fx_risk_on_capital_transfer": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "converting VN funds to AUD for the deposit/costs incurs an FX spread — a one-off TRANSFER cost, owned by kb.fx.typical-spreads-vnd-aud (not this doc)." },
    "servicing_fx_risk_only_if_foreign_income": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "servicing an AUD loan from VND income carries ongoing FX risk, priced by lenders via foreign-income shading (kb.lender.temp-resident-lending-policies); AU-income borrowers have none." },
    "fx_spread_owned_elsewhere": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "this doc draws the boundary; the spread figure is owned by kb.fx.typical-spreads-vnd-aud and the transfer plan by cross_border_funding — never quoted here." }
  }
}
```

Notes:

- **Single-owner.** This doc owns the *loan-currency boundary* (loan is AUD; where FX risk falls). The FX **spread** → [`kb.fx.typical-spreads-vnd-aud`](typical-spreads-vnd-aud.md); the **foreign-income shading** that prices servicing risk → [`kb.lender.temp-resident-lending-policies`](temp-resident-lending-policies.md); the **transfer plan** → the `cross_border_funding` component.
- **No figures.** Deliberately quotes no spread or rate — it settles the *structure* (AUD loan, three places FX can sit), which is a stable convention.
- **Feeds the path decision.** The servicing-currency distinction is an input to `recommended_path` alongside the deposit and shading deltas.

## Sources

- Home Loan Experts — *Foreign Currency Home Loans For Australian Property* (Australian lenders no longer offer foreign-currency loans; borrow in AUD to buy AU property) — https://www.homeloanexperts.com.au/non-resident-mortgages/foreign-currency-mortgages/
- Home Loan Experts — *Proving Your Foreign Income When Applying For A Mortgage* (foreign income converted to AUD with a risk buffer / shading for exchange-rate risk) — https://www.homeloanexperts.com.au/non-resident-mortgages/proving-foreign-income/
- Wise — *Australian mortgages and home loans for non-residents* (loans denominated in AUD; foreign income converted at current rates) — https://wise.com/us/blog/getting-a-mortgage-in-australia
