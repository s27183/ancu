---
slug: kb.cash-reserve.lender-expectations
effective_from: 2025-01-01
last_verified: 2026-10-27
sources:
  - url: https://www.macquarie.com.au/assets/bfs/documents/broker/mortgages/macquarie_broker-credit-guidelines.pdf
    retrieved: 2026-10-27
    path: docs/sources/lenders/macquarie-credit-guidelines-v15.txt
    note: "Macquarie credit guidelines v15.0 §2E Contributions & Genuine Savings: 'Where LVR > 85% (excluding low deposit fee capitalisation), 5% of purchase price is required to be evidenced as genuine savings.'; 'Funds held or accumulated in a personal savings account or term deposit for 3 or more months.'; 'Lump sum deposits may be acceptable if investigated and the applicant can demonstrate that the funds resulted from genuine savings.'; gifts and inheritance unacceptable unless held three months or more. One lender's policy; others vary."
  - url: https://www.apra.gov.au/system/files/2025-06/Prudential%20Practice%20Guide%20APG%20223%20Residential%20Mortgage%20Lending%20-%20Clean.pdf
    retrieved: 2026-10-27
    path: docs/sources/apra/apg-223-2025-06.txt
    note: "APG 223: the genuine-savings principle and limited appetite for non-genuine savings such as family gifts."
---

# Cash reserves — genuine savings and the post-settlement buffer

Two distinct "cash you must show" expectations sit around a home loan, and buyers routinely conflate them. **Genuine savings** is a *pre-approval lender gate*: for a low-deposit loan, most lenders require the buyer to have **saved** a portion of the price themselves and held it, to prove a savings habit — it is about *behaviour*, not just having the money. The **post-settlement reserve buffer** is a *planning* figure: cash left over after settlement so the buyer can absorb rate rises, repairs, or income gaps. This doc owns both, kept separate. It grounds `cash_position`'s `reserve_buffer` block and informs the deposit/genuine-savings narrative in the plan. It does **not** own the lender serviceability buffer (the APRA assessment-rate add-on) — that lives in [`kb.lender.serviceability-basics`](../lender/serviceability-basics.md).

## Genuine savings — the pre-approval gate

APRA's guide sets the principle: "Imposing a minimum 'genuine savings' requirement … is considered an important means of reducing default risk" (APG 223). Lenders set the figures. Macquarie, for example: "Where LVR > 85% (excluding low deposit fee capitalisation), 5% of purchase price is required to be evidenced as genuine savings", counting "Funds held or accumulated in a personal savings account or term deposit for 3 or more months." So the plan uses **5% of the price, held at least 3 months, above 85% LVR** (most 5–15% deposit loans, including [FHG](../scheme/fhg.md)-backed ones) as the typical gate — one lender's published policy, with others varying the threshold and holding period. The test is behavioural — it demonstrates the borrower can save, which lenders read as a proxy for being able to meet repayments.

What it means in practice:

- **What counts:** funds genuinely saved over time and held in the borrower's name (savings/offset/term-deposit), and — at Macquarie — "Shares or managed fund units purchased and held for at least 3 months" and loan repayments made ahead of schedule.
- **Recent lump sums are questioned.** Macquarie: "Lump sum deposits may be acceptable if investigated and the applicant can demonstrate that the funds resulted from genuine savings", and it lists "Gifts and inheritance (can be considered acceptable where the amount has been held for three months or more)" among unacceptable forms. This is the crucial trap: a **recent family gift or inheritance**, however large, generally does **not** satisfy genuine savings on its own. A fixed "1% of price" cut-off for what counts as a lump sum is a working assumption — no lender page found publishes it (PLACEHOLDER below).
- **Rental history as a substitute.** Some lenders are reported to accept a record of on-time rent (a rental ledger) in place of genuine savings, but no lender page found states it as its own policy, and Macquarie does not list it among acceptable forms. Treat it as a question to put to the broker, not a known path (PLACEHOLDER below).

## The post-settlement reserve buffer — the planning figure

Separately, prudent planning leaves a **cash reserve after settlement**. The plan's default is **~3 months of loan repayments** held in reserve (the `reserve_buffer.months_of_repayments_recommended` default). The plan also shows a stronger working figure of **8–10% of the purchase price in total cash** going in — deposit + all costs + a residual buffer — even when only a 5% deposit is being used. No primary states this band (PLACEHOLDER below); it is **planning prudence, not a lender rule**: lenders assess servicing with their own buffer (see [serviceability-basics](../lender/serviceability-basics.md)); the reserve here is for the *buyer's* resilience.

## Relevance for Vietnamese-Australian buyers (Mode A)

- **Family contribution is common — and the genuine-savings trap bites it.** Many Mode A buyers receive a parental gift toward the deposit (the blueprint's `family_contribution` input). That money helps the **deposit** but generally **fails genuine savings** if it arrived recently (Macquarie accepts a gift only once "held for three months or more"). The plan must surface this early: a $100k gift can fund the deposit yet still leave the buyer needing **5% saved over 3 months** to clear the lender's gate. Missing this derails an otherwise-fundable purchase.
- **Ask about rental history.** Many Mode A buyers have rented for years with clean ledgers. Whether any lender counts that in place of genuine savings is unconfirmed (no lender page found states it); surface it as a question for the broker, not a route.
- **FHG doesn't remove genuine savings.** The [FHG](../scheme/fhg.md) removes LMI and allows a 5% deposit, but most panel lenders still apply their genuine-savings policy — flag that the two are separate gates.
- **Information, not advice.** The plan explains the gates and the substitutes and shows the buffer maths; it does not direct the buyer to a lender with a particular genuine-savings policy (ASIC: no credit advice).

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **reference doc** — it fills no slot. `cash_position.reserve_buffer.amount` is resolver-computed (months × monthly repayment); the genuine-savings assessment is **agent-reasoned** from `profile` facts (deposit composition, `family_contribution`, rental history) against these policy parameters.

```jsonc
{
  "fills": [],
  "parameters": {
    "genuine_savings_pct_of_price":              { "type": "percentage", "value": 5,  "note": "LENDER-POLICY band — Macquarie: 'Where LVR > 85% … 5% of purchase price is required to be evidenced as genuine savings.' Other lenders vary." },
    "genuine_savings_min_months_held":           { "type": "integer",    "value": 3,  "note": "LENDER-POLICY band — Macquarie: 'Funds held or accumulated in a personal savings account or term deposit for 3 or more months.' Other lenders vary." },
    "genuine_savings_required_above_lvr_pct":    { "type": "percentage", "value": 85, "note": "LENDER-POLICY band — Macquarie: genuine savings required 'Where LVR > 85% (excluding low deposit fee capitalisation)'. Other lenders vary; present as typical." },
    "large_deposit_excluded_above_pct_of_price": { "type": "percentage", "value": 1,  "note": "PLACEHOLDER — no primary states this; re-ground on the Macquarie credit guidelines §2E (https://www.macquarie.com.au/assets/bfs/documents/broker/mortgages/macquarie_broker-credit-guidelines.pdf): 'Lump sum deposits may be acceptable if investigated and the applicant can demonstrate that the funds resulted from genuine savings.' — no fixed percentage." },
    "rental_history_accepted_as_genuine_savings": { "type": "bool",      "value": true, "note": "PLACEHOLDER — no primary states this; no lender page found states it as its own policy, and Macquarie §2E does not list it. Re-ground on a lender's own credit policy (e.g. https://distributor.amp.com.au/home-loans/policies). Confirm with the lender." },
    "rental_history_min_months":                 { "type": "integer",    "value": 12, "note": "PLACEHOLDER — no primary states this; re-ground on a lender's own credit policy (e.g. https://distributor.amp.com.au/home-loans/policies) alongside rental_history_accepted_as_genuine_savings." },
    "recommended_post_settlement_reserve_months": { "type": "integer",   "value": 3,  "note": "CONVENTION/planning — default cash reserve held after settlement, in months of loan repayments; matches cash_position.reserve_buffer.months_of_repayments_recommended" },
    "prudent_total_cash_pct_of_price_low":       { "type": "percentage", "value": 8,  "note": "PLACEHOLDER — no primary states this; re-ground on an ASIC Moneysmart home-buying costs page (none found stating a total-cash figure, 2026-10-27). Planning figure: total cash (deposit + costs + reserve) on a 5% deposit; NOT a lender requirement." },
    "prudent_total_cash_pct_of_price_high":      { "type": "percentage", "value": 10, "note": "PLACEHOLDER — no primary states this; re-ground with prudent_total_cash_pct_of_price_low. Planning upper end." }
  }
}
```

Notes:

- **No `fills`.** No outcome leaf is set. `cash_position.reserve_buffer.amount` is the resolver applying `recommended_post_settlement_reserve_months` to the monthly repayment; whether a buyer clears the **genuine-savings** gate is agent-reasoned from deposit composition (`family_contribution`, savings trail, rental history) against these parameters. The doc supplies the policy facts, not a verdict.
- **Two gates, deliberately separated.** **Genuine savings** is a *lender approval* requirement (pre-settlement, behavioural); the **reserve buffer** is *planning prudence* (post-settlement, resilience). They are different numbers for different purposes — documented apart so the agent never presents the planning buffer as a lender rule or vice versa.
- **All figures are CONVENTION or LENDER POLICY — none regulated.** Genuine savings is not a regulatory requirement (it is lender risk policy, downstream of APRA responsible-lending expectations); the buffer is planning advice. Tagged so the agent presents them as "most lenders / a prudent rule," never as law. The one genuinely regulatory buffer (the APRA serviceability assessment rate) is owned by [`kb.lender.serviceability-basics`](../lender/serviceability-basics.md) — not re-derived here.
- **The recent-gift trap is the load-bearing Mode A fact.** It is what makes a family-gifted deposit insufficient on its own, so it is captured as an explicit parameter (`large_deposit_excluded_above_pct_of_price`, a PLACEHOLDER figure over a grounded rule) for the agent to reason over `family_contribution`.

## Sources

**Canonical (regulator):**

- APRA — *Prudential Practice Guide APG 223 Residential Mortgage Lending* — primary, ¶ on minimum deposit requirements: "ADIs typically require a borrower to provide an initial deposit primarily drawn from the borrower's own funds. Imposing a minimum 'genuine savings' requirement … is considered an important means of reducing default risk. A prudent ADI would have limited appetite for taking into account non-genuine savings, such as gifts from a family member." This is the regulatory basis for the genuine-savings gate and the exclusion of recent gifts. — https://www.apra.gov.au/system/files/2025-06/Prudential%20Practice%20Guide%20APG%20223%20Residential%20Mortgage%20Lending%20-%20Clean.pdf (archived: `docs/sources/apra/apg-223-2025-06.txt`, the June 2025 text)

**Lender policy** — APG 223 sets the principle; each lender sets its own figures. The 5% / 85% LVR / 3-month figures are Macquarie's published policy:

- Macquarie — *Residential Home Loans Credit Guidelines* v15.0, §2E Contributions & Genuine Savings — https://www.macquarie.com.au/assets/bfs/documents/broker/mortgages/macquarie_broker-credit-guidelines.pdf
