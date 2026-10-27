---
slug: kb.fx.loan-currency-considerations
effective_from: 2025-07-01
last_verified: 2026-10-27
sources:
  - url: https://www.apra.gov.au/system/files/2025-06/Prudential%20Practice%20Guide%20APG%20223%20Residential%20Mortgage%20Lending%20-%20Clean.pdf
    retrieved: 2026-10-27
    path: docs/sources/apra/apg-223-2025-06.txt
  - url: https://www.macquarie.com.au/assets/bfs/documents/broker/mortgages/macquarie_broker-credit-guidelines.pdf
    retrieved: 2026-10-27
    path: docs/sources/lenders/macquarie-credit-guidelines-v15.txt
---

# Loan currency and FX exposure — where the risk actually sits

This doc owns the **boundary question** for a Vietnam-parent-funded / temp-resident buyer: *in what currency is the loan, and where does FX risk fall?* It grounds the `mortgage_finance` foreign-person variant (component 5) — specifically `loan_structure.currency_of_loan` (a fixed `AUD`) and the `recommended_path_reasoning` — by settling a common misconception before it distorts the plan. It deliberately does **not** own FX **spreads or provider pricing**: the cost of converting VN funds to AUD is owned by [`kb.fx.typical-spreads-vnd-aud`](typical-spreads-vnd-aud.md) and the transfer mechanics by the `cross_border_funding` component and its anchors. This doc draws the line; those own the numbers.

## The load-bearing fact: plan on an AUD loan

**The plan assumes the loan is in AUD.** APRA's prudential guide says "it is not prudent to extend foreign currency-denominated loans against domestic currency (e.g. Australian dollar) income streams or against domestic currency collateral" (APG 223) — and Australian property is domestic-currency collateral. Lenders say the same of their own book: "Macquarie Bank originates loans in Australian dollars" (Macquarie credit guidelines v15.0). APRA does allow that "an ADI may occasionally extend a foreign-currency loan to a borrower with a foreign currency-denominated income stream", so a foreign-currency mortgage is rare rather than impossible; a VND loan against Australian property is not something a buyer should plan on. So `currency_of_loan` is fixed at `AUD` in the plan, and the plan says so plainly, because buyers funded from Vietnam often assume otherwise.

A consequence worth surfacing: because the loan is AUD, the **loan repayments carry no FX conversion on the debt itself** — the schedule is a fixed AUD obligation. FX risk does not live on the loan; it lives in two other places.

## Where FX risk actually sits

1. **On the capital transfer (one-off).** Moving the deposit and buying costs from VND to AUD incurs an FX spread — the cost owned by [`kb.fx.typical-spreads-vnd-aud`](typical-spreads-vnd-aud.md) and optimised by the `cross_border_funding` plan. This is the largest single FX cost and it is a *transfer* cost, not a *loan* cost.
2. **On ongoing servicing, only if income is foreign (recurring).** A borrower who **services an AUD loan from VND income** carries genuine ongoing FX risk: the income is earned in VND, the repayment is due in AUD, and the exchange rate moves between them. Lenders price this risk in advance through **foreign-income shading** — Macquarie counts "only 80% of the amount after conversion at current exchange rates", and APRA calls it "good practice to discount offshore income in assessing a borrower's loan servicing capacity"  ([`kb.lender.temp-resident-lending-policies`](../lender/temp-resident-lending-policies.md)) — which is *why* foreign income is shaded. A **485/AU-income** borrower earning AUD locally has **no** servicing FX risk, which is part of why that path is favourable ([`kb.lender.485-visa-treatment`](../lender/485-visa-treatment.md)).

So the plan's FX story is: **loan = AUD (no choice, no loan-side FX)**; **transfer = the one-off spread (owned by the FX-spread doc)**; **servicing = ongoing FX risk only for a foreign-income borrower, already priced via shading.**

## Relevance for the Vietnam-parent-funded / temp-resident buyer (Mode B)

- **Dispel the foreign-currency-loan idea early.** Plan on an AUD loan; a VND mortgage against Australian property is not on offer in practice. This reframes the funding question as *how to move AUD-equivalent funds efficiently*, not *what currency to borrow in*.
- **The servicing-currency question drives the path.** If ongoing repayments will come from VND income, the shading (and its capacity cost) bites; if from AUD income, it does not — this feeds `recommended_path`.
- **The spread is owned elsewhere.** This doc points to [`kb.fx.typical-spreads-vnd-aud`](typical-spreads-vnd-aud.md); it never quotes a spread.

## Rules

Pure-reference (`fills: []`). The `mortgage_finance` resolver holds `loan_structure.currency_of_loan` at `AUD` (fixed) and uses the servicing-currency distinction below in `recommended_path_reasoning`; this doc supplies the grounded boundary. No leaf asserted; no FX spread quoted here.

```jsonc
{
  "fills": [],
  "parameters": {
    "loan_currency_is_always_aud": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "the plan fixes currency_of_loan at AUD: APRA APG 223 calls foreign-currency loans against AUD collateral not prudent (an ADI may occasionally lend in a foreign currency to a foreign-income borrower); Macquarie originates loans in AUD only." },
    "no_fx_risk_on_loan_repayment_itself": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "the repayment schedule is a fixed AUD obligation; FX risk sits on the funds transfer and on servicing from foreign income, not on the loan denomination." },
    "fx_risk_on_capital_transfer": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "converting VN funds to AUD for the deposit/costs incurs an FX spread — a one-off TRANSFER cost, owned by kb.fx.typical-spreads-vnd-aud (not this doc)." },
    "servicing_fx_risk_only_if_foreign_income": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "servicing an AUD loan from VND income carries ongoing FX risk, priced by lenders via foreign-income shading (kb.lender.temp-resident-lending-policies); AU-income borrowers have none." },
    "fx_spread_owned_elsewhere": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "this doc draws the boundary; the spread figure is owned by kb.fx.typical-spreads-vnd-aud and the transfer plan by cross_border_funding — never quoted here." }
  }
}
```

Notes:

- **Single-owner.** This doc owns the *loan-currency boundary* (loan is AUD; where FX risk falls). The FX **spread** → [`kb.fx.typical-spreads-vnd-aud`](typical-spreads-vnd-aud.md); the **foreign-income shading** that prices servicing risk → [`kb.lender.temp-resident-lending-policies`](../lender/temp-resident-lending-policies.md); the **transfer plan** → the `cross_border_funding` component.
- **No figures.** Deliberately quotes no spread or rate — it settles the *structure* (AUD loan, three places FX can sit), grounded on APRA's guide and a lender's own policy.
- **Feeds the path decision.** The servicing-currency distinction is an input to `recommended_path` alongside the deposit and shading deltas.

## Sources

- APRA — *APG 223 Residential Mortgage Lending* ("Foreign currency loans": not prudent against AUD income or collateral; occasional foreign-currency loan to a foreign-income borrower; good practice to discount offshore income) — https://www.apra.gov.au/system/files/2025-06/Prudential%20Practice%20Guide%20APG%20223%20Residential%20Mortgage%20Lending%20-%20Clean.pdf
- Macquarie Bank — *Residential Home Loans Credit Guidelines* v15.0 (originates loans in AUD; 80% of converted foreign income used for servicing; accepted currencies GBP, EUR, HKD, NZD, SGD, USD, CAD, JPY, CHF — VND not among them) — https://www.macquarie.com.au/assets/bfs/documents/broker/mortgages/macquarie_broker-credit-guidelines.pdf
