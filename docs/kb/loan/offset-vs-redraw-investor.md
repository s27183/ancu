---
slug: kb.loan.offset-vs-redraw-investor
effective_from: 2025-07-01
last_verified: 2026-10-27
sources:
  - url: https://www.ato.gov.au/law/view/document?docid=TXR/TR20002/NAT/ATO/00001
    retrieved: 2026-10-27
    path: docs/sources/ato/tr-2000-2.txt
    quotes:
      - "In this regard the term 'redraw' is a misnomer. It is in effect a new borrowing of funds."
      - "The deductibility of interest on a further borrowing of money under a redraw facility depends upon the use to which the redrawn funds are put."
      - "the loan account becomes a mixed purpose account and the same principles discussed above in relation to mixed purpose line of credit sub-accounts will apply to the mixed purpose loan account. There is an ongoing need to apportion interest on a mixed purpose loan account."
  - url: https://www.ato.gov.au/law/view/document?DocID=EV/1051960276405
    retrieved: 2026-10-27
    path: docs/sources/ato/pbr-1051960276405-offset-withdrawal.txt
    note: "ATO private ruling (edited, archived version — binds only its applicant; the ATO marks archived edited rulings as not necessarily its current view). It applies TR 2000/2 and TR 93/6 to an offset account."
    quotes:
      - "A withdrawal from an offset account is not a borrowing or a loan and therefore the use of the funds from an offset account is not relevant for tax purposes."
  - url: https://www.ato.gov.au/individuals-and-families/investments-and-assets/property-and-land/residential-rental-properties/rental-expenses/interest-expenses
    retrieved: 2026-10-27
    path: docs/sources/ato/rental-interest-expenses.txt
    quotes:
      - "All loan repayments must be apportioned across both rental and private portions of the loan for the length of the loan."
      - "Tyler must continue to apportion interest and repayments of principal in accordance with this ratio for the life of the loan."
  - url: https://moneysmart.gov.au/home-loans/choosing-a-home-loan
    retrieved: 2026-10-27
    path: docs/sources/asic/moneysmart-choosing-a-home-loan.txt
    quotes:
      - "If you're able to keep $50,000 of savings in the offset, you'll pay interest on $700,000."
---

# Offset vs redraw — for investors

An **offset account** and a **redraw facility** both let an investor park spare cash against the loan to reduce interest — but for an investment loan they have **opposite tax consequences**, and getting this wrong permanently contaminates the deductibility of a loan. This doc owns that distinction so `mortgage_finance` can frame which structure keeps an investment loan "clean." The deductibility rule is a **regulated ATO fact** (the "use" test, TR 2000/2), not a convention. Informational; the structure choice is decision-support and a tax adviser confirms the position.

## The mechanism — and why they differ for tax

- **Offset account** — a separate **deposit (transaction) account** linked to the loan. Its balance is netted against the loan balance for interest calculation, so it reduces interest **without reducing the loan balance**. Crucially, a **withdrawal from an offset account is not a borrowing** — it is your own money — so moving money in and out of an offset has **no effect on the loan's interest deductibility**. The investment loan stays fully deductible regardless of how the offset is used.
- **Redraw facility** — redraw lets you withdraw **extra repayments** you have made on the loan. A redraw is a **new borrowing**, and under the "use" test the deductibility of interest on the redrawn amount depends on **what the redrawn funds are used for**. Redraw from an investment loan for a **private** purpose (a holiday, a car) creates a **mixed-purpose loan**: the interest must be **apportioned**, and the private portion is **no longer deductible** — permanently contaminating a previously clean investment loan.

## The investor consequence

For an investor, an **offset account preserves deductibility** and is the structure that keeps an investment loan clean while still parking spare cash against it. **Redraw on an investment loan is a trap** when used for private spending — it silently converts deductible debt into partly non-deductible debt, and the apportionment persists for the life of the loan. The general guidance the plan surfaces: keep private cash in an offset, not parked as extra repayments you later redraw for private use; if you must access equity for a new *investment*, structure it as a separate split/loan so the use is clean (cross-ref [`kb.loan.refinance-strategies-portfolio-growth`](refinance-strategies-portfolio-growth.md)).

## Relevance for Vietnamese-Australian investors (Mode C)

- **Offset keeps the loan clean.** The plan recommends parking spare cash in an offset (not as redrawable extra repayments) so the investment loan's interest stays fully deductible.
- **Redraw-for-private-use is a deductibility trap.** The plan flags that redrawing from an investment loan for personal spending permanently reduces the deductible portion — a common, costly mistake.
- **Structure new borrowings cleanly.** Accessing equity for the next property should be a separate split with a clear investment use, not a redraw mixed with private spending.
- **Regulated fact, adviser confirms.** The deductibility rule is ATO law (the "use" test); the plan surfaces it and points to a tax adviser for the specific position (it is not financial/tax advice).

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **reference** doc — it fills no slot; it supplies the regulated deductibility facts the agent surfaces when reasoning about loan structure. The deductibility rules are REGULATED (ATO TR 2000/2, the "use" test); whether to use offset vs redraw is decision-support.

```jsonc
{
  "fills": [],
  "parameters": {
    "offset_preserves_deductibility":   { "type": "bool", "value": true, "note": "REGULATED (ATO TR 2000/2 + TR 93/6, as applied in ATO private ruling 1051960276405) — an offset is a deposit account; a withdrawal from it is NOT a borrowing, so offset use has no effect on the investment loan's interest deductibility" },
    "redraw_is_new_borrowing_use_test": { "type": "bool", "value": true, "note": "REGULATED (ATO 'use' test, Munro; TR 2000/2) — a redraw is a new borrowing; deductibility of interest on redrawn funds follows the USE of those funds" },
    "private_redraw_contaminates_loan": { "type": "bool", "value": true, "note": "REGULATED — redraw from an investment loan for a PRIVATE purpose creates a mixed-purpose loan; interest is apportioned and the private portion is no longer deductible — permanent contamination" },
    "mixed_purpose_loan_apportioned":   { "type": "bool", "value": true, "note": "REGULATED — where borrowed funds serve both investment and private purposes, interest is apportioned; only the income-producing portion is deductible" },
    "offset_vs_redraw_is_decision_support": { "type": "bool", "value": true, "note": "the structure choice is decision-support; a tax adviser confirms the specific position (not tax advice)" }
  }
}
```

Notes:

- **No `fills`.** The doc supplies regulated deductibility facts the agent surfaces; it computes no figure (interest saving from an offset is resolver-computed from the offset balance and rate where modelled).
- **Regulated, not convention.** The deductibility distinction is ATO law (the "use" test, TR 2000/2) — the strongest provenance tier in the finance cluster; flagged REGULATED, not CONVENTION.
- **The only decision-support flag is the choice itself.** *Whether* to use offset or redraw is decision-support; *the tax consequence of each* is regulated fact, not a preference.
- **Cross-ref for clean equity release.** Structuring a new borrowing cleanly (a separate split) is owned by `kb.loan.refinance-strategies-portfolio-growth`; this doc owns the offset-vs-redraw deductibility distinction.

## Sources

- ATO — *TR 2000/2 Income tax: deductibility of interest on moneys drawn down under line of credit facilities and redraw facilities* (redraw is a new borrowing; deductibility follows the use of the funds; a redraw facility has no separate deposit account, para 40) — https://www.ato.gov.au/law/view/document?docid=TXR/TR20002/NAT/ATO/00001
- ATO — private ruling 1051960276405 (an offset withdrawal is not a borrowing; TR 2000/2 applies to a loan account, not a deposit account — an edited, archived ruling that binds only its applicant) — https://www.ato.gov.au/law/view/document?DocID=EV/1051960276405
- ATO — *Interest expenses* (apportionment of interest on mixed-purpose loans, for the life of the loan) — https://www.ato.gov.au/individuals-and-families/investments-and-assets/property-and-land/residential-rental-properties/rental-expenses/interest-expenses
- ASIC Moneysmart — *Choosing a home loan* (how an offset reduces the balance interest is charged on) — https://moneysmart.gov.au/home-loans/choosing-a-home-loan
