---
slug: kb.lender.non-resident-investment-loan-shortlist
effective_from: 2025-07-01
last_verified: 2026-07-06
sources:
  - url: https://www.canstar.com.au/home-loans/non-resident-home-loans/
    retrieved: 2026-07-06
    note: "Non-resident lender pool is small (a select few, mostly non-banks) and priced higher — context for the narrowest combined non-resident+investor pool. The rate-premium band (100-200bp) and the criteria framing remain FirstHomey editorial / unverified-this-pass conventions, as the doc itself flags — a live broker quote is required"
---

# Non-resident investment loan shortlist — criteria for the narrowest pool in the AU market

This doc owns the **shortlist criteria for the combination** non-residency **and** investment purpose — the narrowest lender pool in the Australian market, narrower than either axis alone. It grounds `mortgage_finance` (component 5) `loan_path.non_resident_investor_loan_shortlist` (an **agent-path** leaf, `reasoning_domain: lender_fit`). Same ACL discipline as its two parent docs: criteria and reasoning the agent applies to produce a shortlist, **never a named or ranked lender**, always "confirm with a licensed mortgage broker."

## The two axes compound, they don't just add

[`kb.lender.non-resident-friendly-shortlist`](non-resident-friendly-shortlist.md) owns the non-residency criteria (foreign-income acceptance, visa appetite, FIRB-conditional handling, documentation capability, deposit/LVR). [`kb.lender.investor-friendly-shortlist`](investor-friendly-shortlist.md) owns the domestic-investor criteria (investment-loan serviceability shading, IO availability, rental-income treatment). A **non-resident investor** needs a lender that clears **both** sets of criteria simultaneously — typically **3–5 lenders** in practice, materially fewer than either the non-resident-owner-occupier pool or the domestic-investor pool alone. The agent reasons over both criteria sets together, not either in isolation.

## What's specific to the combination (not owned by either parent doc)

- **Rental-income treatment for a non-resident investor.** Lenders that do count foreign-sourced rent toward serviceability typically count **~70–80%** of the projected AU rental income (a shading similar in spirit to, but distinct from, the foreign-*employment*-income shading owned by [`kb.lender.temp-resident-lending-policies`](temp-resident-lending-policies.md)).
- **A further rate premium above the domestic-investor rate.** Beyond the general non-resident premium ([`kb.lender.non-resident-friendly-shortlist`](non-resident-friendly-shortlist.md)'s ~50–150bp above domestic *owner-occupier*), a non-resident **investment** loan typically prices at a further premium above the **domestic investor** rate — commonly cited in the **~100–200bp** range. This figure is a lender-policy convention, not independently primary-verified this pass (the market moves; live quotes vary by lender and by the borrower's specific profile) — presented as an indicative band, deferred to a broker for a current quote.
- **IO availability is lender-specific, not a given.** Interest-only structuring — the domestic-investor default reasoning owned by [`kb.loan.interest-only-vs-pi-investor`](../loan/interest-only-vs-pi-investor.md) — is not uniformly offered to non-resident borrowers; some lenders in the non-resident-friendly pool restrict non-resident loans to P&I only. The agent should confirm IO availability as a shortlist criterion, not assume it.
- **VN income treatment is the parent doc's, unchanged.** [`kb.lender.temp-resident-lending-policies`](temp-resident-lending-policies.md) already owns the VND-acceptance and shading criteria; this doc adds no new VN-income fact, it composes the existing one with the investment-serviceability axis.

## Relevance for Vietnam-located investors (Mode D)

- **Plan for a genuinely small shortlist.** The combined criteria narrow the field further than either Mode B's or Mode C's shortlist alone — the plan should set that expectation early rather than imply the broader non-resident or investor pool applies unchanged.
- **Rate and IO terms need a live quote.** Both the rate premium and IO availability are lender-specific and move; the plan bands them and routes to a broker rather than asserting a figure the agent cannot verify.
- **Information, not credit advice.** The shortlist is criteria + reasoning; the user picks, with a licensed broker (ACL line) — same discipline as both parent docs.

## Rules

Pure-reference (`fills: []`). `non_resident_investor_loan_shortlist` remains agent-path (`reasoning_domain: lender_fit`); the agent composes both parent criteria sets plus the combination-specific facts below.

```jsonc
{
  "fills": [],
  "parameters": {
    "shortlist_is_decision_support": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "mirrors both parent docs — criteria + reasoning, never a named/ranked lender." },
    "lender_pool_narrower_than_either_axis_alone": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "typically 3-5 lenders willing to clear both the non-resident AND investment criteria simultaneously — narrower than either pool alone." },
    "non_resident_investor_rental_income_shading_pct_low": { "type": "int", "value": 70, "provenance": "CONVENTION", "note": "lower end of the projected AU rental income counted toward serviceability for a non-resident investor." },
    "non_resident_investor_rental_income_shading_pct_high": { "type": "int", "value": 80, "provenance": "CONVENTION", "note": "upper end." },
    "rate_premium_above_domestic_investor_bp_low": { "type": "int", "value": 100, "provenance": "CONVENTION", "note": "indicative lower end of the further premium above the domestic-investor rate; not independently primary-verified this pass — live quote required." },
    "rate_premium_above_domestic_investor_bp_high": { "type": "int", "value": 200, "provenance": "CONVENTION", "note": "indicative upper end; band, not a quote." },
    "io_availability_lender_specific_not_assumed": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "interest-only is not uniformly available to non-resident borrowers; some lenders restrict to P&I — confirm per lender, don't assume IO." }
  }
}
```

Notes:

- **No `fills`, no named lenders.** Mirrors both parent docs' ACL-boundary discipline exactly.
- **Single-owner via cross-ref.** Non-residency criteria → `kb.lender.non-resident-friendly-shortlist`; investor criteria → `kb.lender.investor-friendly-shortlist`; VN income treatment → `kb.lender.temp-resident-lending-policies`; IO-vs-PI trade-off framing → `kb.loan.interest-only-vs-pi-investor`; deposit band → `kb.non-resident.investment-loan-deposit-requirements`. This doc owns only the *combination-specific* facts (narrower pool, rental-income shading, the further rate premium, IO-availability caveat).
- **Rate-premium figure flagged as unverified-this-pass.** Consistent with the project's honesty discipline — a CONVENTION band, not asserted as primary-confirmed; re-verify against a live broker quote before treating as load-bearing.

## Sources

- Canstar — *Non-Resident Home Loans in Australia* (non-resident lender pool size and pricing context) — https://www.canstar.com.au/home-loans/non-resident-home-loans/
- Finder — *Investment Loan Rates 2026* (domestic investor rate baseline the non-resident-investor premium is measured against) — https://www.finder.com.au/home-loans/investment-property-home-loans
- La Trobe Financial — *Tailored lending for international residents* (non-resident/international-borrower loan product example, indicative pricing) — https://www.latrobefinancial.com.au/lending/international-borrower-loan/
