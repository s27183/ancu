---
slug: kb.lender.non-resident-investment-loan-shortlist
effective_from: 2025-07-01
last_verified: 2026-10-27
sources:
  - url: https://brighten.com.au/home-loans/non-resident/
    retrieved: 2026-10-27
    path: docs/sources/lenders/brighten-non-resident-home-loan.txt
    note: "Brighten's own page: \"Owner occupied or investment property\"; \"Interest only (up to 5 years)\"; rental income \"(Accepting rental income outside Australia)\" (no shading % stated)"
  - url: https://www.latrobefinancial.com.au/lending/international-borrower-loan/
    retrieved: 2026-10-27
    path: docs/sources/lenders/latrobe-international-borrower-loan.txt
    note: "La Trobe Financial's own page: Non-resident Loan for \"International borrowers looking to invest in Australian real estate with Foreign Investment Review Board approval\"; \"Repayment Type: Principal & Interest\""
  - url: https://www.latrobefinancial.com.au/wp-content/uploads/latrobefinancial-international-borrower-term-sheet.pdf
    retrieved: 2026-10-27
    path: docs/sources/lenders/latrobe-international-borrower-term-sheet.txt
    note: "La Trobe Financial term sheet, Non-Resident Loan: Repayment Type \"Principal & interest.\""
---

# Non-resident investment loan shortlist — criteria for the narrowest pool in the AU market

This doc owns the **shortlist criteria for the combination** non-residency **and** investment purpose — the narrowest lender pool in the Australian market, narrower than either axis alone. It grounds `mortgage_finance` (component 5) `loan_path.non_resident_investor_loan_shortlist` (an **agent-path** leaf, `reasoning_domain: lender_fit`). Same ACL discipline as its two parent docs: criteria and reasoning the agent applies to produce a shortlist; lenders appear only as facts from their own pages (alphabetical), **never recommended or ranked**, always "confirm with a licensed mortgage broker."

## The two axes compound, they don't just add

[`kb.lender.non-resident-friendly-shortlist`](non-resident-friendly-shortlist.md) owns the non-residency criteria (foreign-income acceptance, visa appetite, FIRB-conditional handling, documentation capability, deposit/LVR). [`kb.lender.investor-friendly-shortlist`](investor-friendly-shortlist.md) owns the domestic-investor criteria (investment-loan serviceability shading, IO availability, rental-income treatment). A **non-resident investor** needs a lender that clears **both** sets of criteria simultaneously. Of the lenders whose own pages publish a non-resident loan, both take investment purpose: **Brighten** ("Owner occupied or investment property") and **La Trobe Financial** (its Non-resident Loan is for borrowers "looking to invest in Australian real estate"). How many lenders in all clear both is not published anywhere; the plan says the pool is small and a broker confirms it. The agent reasons over both criteria sets together, not either in isolation.

## What's specific to the combination (not owned by either parent doc)

- **Rental-income treatment for a non-resident investor.** Brighten's page accepts rental income, including "rental income outside Australia", but neither lender's page states what share of rent it counts. The plan's 70–80% band is a `PLACEHOLDER` (distinct from the foreign-*employment*-income shading owned by [`kb.lender.temp-resident-lending-policies`](temp-resident-lending-policies.md)).
- **A further rate premium above the domestic-investor rate.** No lender's own page states a non-resident investment premium over its domestic investor rate. The plan's 100–200 bp band is a `PLACEHOLDER`, kept so the Mode D rate range computes, and deferred to a broker for a current quote.
- **IO availability is lender-specific, not a given.** Interest-only structuring — the domestic-investor default reasoning owned by [`kb.loan.interest-only-vs-pi-investor`](../loan/interest-only-vs-pi-investor.md) — differs between the two lenders that publish a non-resident loan: La Trobe Financial's Non-resident Loan is "Principal & Interest" only; Brighten offers "Interest only (up to 5 years)". The agent confirms IO availability as a shortlist criterion, never assumes it.
- **VN income treatment is the parent doc's, unchanged.** [`kb.lender.temp-resident-lending-policies`](temp-resident-lending-policies.md) already owns the VND-acceptance and shading criteria; this doc adds no new VN-income fact, it composes the existing one with the investment-serviceability axis.

## Relevance for Vietnam-located investors (Mode D)

- **Plan for a genuinely small shortlist.** The combined criteria narrow the field further than either Mode B's or Mode C's shortlist alone — the plan should set that expectation early rather than imply the broader non-resident or investor pool applies unchanged.
- **Rate and IO terms need a live quote.** Both the rate premium and IO availability are lender-specific and move; the plan shows the premium as a placeholder band and routes to a broker rather than asserting a figure no lender publishes.
- **Information, not credit advice.** The shortlist is criteria + reasoning; the user picks, with a licensed broker (ACL line) — same discipline as both parent docs.

## Rules

Pure-reference (`fills: []`). `non_resident_investor_loan_shortlist` remains agent-path (`reasoning_domain: lender_fit`); the agent composes both parent criteria sets plus the combination-specific facts below.

```jsonc
{
  "fills": [],
  "parameters": {
    "shortlist_is_decision_support": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "mirrors both parent docs — criteria + reasoning; lenders appear only as facts from their own pages, never recommended or ranked (the app does not recommend a lender)." },
    "lender_pool_narrower_than_either_axis_alone": { "type": "bool", "value": true, "provenance": "LENDER-POLICY", "note": "the pool must clear both the non-resident and the investment criteria; of the lenders whose own pages publish a non-resident loan, Brighten and La Trobe Financial take investment purpose. The total count is not published anywhere — no count is asserted." },
    "non_resident_investor_rental_income_shading_pct_low": { "type": "int", "value": 70, "provenance": "PLACEHOLDER", "note": "PLACEHOLDER — Brighten's page accepts rental income (including from outside Australia) but no lender's page states the share counted. Re-ground on Brighten's product guide or La Trobe Financial's credit guide." },
    "non_resident_investor_rental_income_shading_pct_high": { "type": "int", "value": 80, "provenance": "PLACEHOLDER", "note": "PLACEHOLDER — upper end; same re-ground as the low end." },
    "rate_premium_above_domestic_investor_bp_low": { "type": "int", "value": 100, "provenance": "PLACEHOLDER", "note": "PLACEHOLDER — no lender's own page states a non-resident investment premium over its domestic investor rate. Re-ground by comparing La Trobe Financial's and Brighten's non-resident rates with a domestic investor rate on the same lender's own page; live quote required." },
    "rate_premium_above_domestic_investor_bp_high": { "type": "int", "value": 200, "provenance": "PLACEHOLDER", "note": "PLACEHOLDER — upper end; same re-ground; band, not a quote." },
    "io_availability_lender_specific_not_assumed": { "type": "bool", "value": true, "provenance": "LENDER-POLICY", "note": "La Trobe Financial's Non-resident Loan is principal and interest only; Brighten offers interest only up to 5 years — confirm per lender, never assume IO." }
  }
}
```

Notes:

- **No `fills`, no recommended lender.** Mirrors both parent docs' ACL-boundary discipline: lenders are named only as facts from their own pages, alphabetically, never as a recommendation.
- **Single-owner via cross-ref.** Non-residency criteria → `kb.lender.non-resident-friendly-shortlist`; investor criteria → `kb.lender.investor-friendly-shortlist`; VN income treatment → `kb.lender.temp-resident-lending-policies`; IO-vs-PI trade-off framing → `kb.loan.interest-only-vs-pi-investor`; deposit band → `kb.non-resident.investment-loan-deposit-requirements`. This doc owns only the *combination-specific* facts (narrower pool, rental-income shading, the further rate premium, IO-availability caveat).
- **Rate premium and rental shading are placeholders.** No lender's own page states either; both are `PLACEHOLDER` bands naming the lender pages to re-ground on, and the plan defers to a live broker quote.

## Sources

- Brighten — *Non-Resident Home Loans* (owner occupied or investment; interest only up to 5 years; rental income from outside Australia accepted) — https://brighten.com.au/home-loans/non-resident/
- La Trobe Financial — *International Borrower* (Non-resident Loan to invest with FIRB approval; principal and interest) — https://www.latrobefinancial.com.au/lending/international-borrower-loan/
- La Trobe Financial — *International Borrower term sheet* (Non-Resident Loan repayment type principal and interest) — https://www.latrobefinancial.com.au/wp-content/uploads/latrobefinancial-international-borrower-term-sheet.pdf
