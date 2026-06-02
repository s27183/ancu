---
slug: kb.cash-reserve.lender-expectations
effective_from: 2025-01-01
last_verified: 2026-06-01
---

# Cash reserves — genuine savings and the post-settlement buffer

Two distinct "cash you must show" expectations sit around a home loan, and buyers routinely conflate them. **Genuine savings** is a *pre-approval lender gate*: for a low-deposit loan, most lenders require the buyer to have **saved** a portion of the price themselves and held it, to prove a savings habit — it is about *behaviour*, not just having the money. The **post-settlement reserve buffer** is a *planning* figure: cash left over after settlement so the buyer can absorb rate rises, repairs, or income gaps. This doc owns both, kept separate. It grounds `cash_position`'s `reserve_buffer` block and informs the deposit/genuine-savings narrative in the plan. It does **not** own the lender serviceability buffer (the APRA assessment-rate add-on) — that lives in [`kb.lender.serviceability-basics`](../lender/serviceability-basics.md).

## Genuine savings — the pre-approval gate

For loans **above roughly 85% LVR** (i.e. most 5–15% deposit loans, including [FHG](../scheme/fhg.md)-backed ones at many lenders), lenders generally require **5% of the purchase price in "genuine savings"**, **accumulated and held for at least 3 months**. The test is behavioural — it demonstrates the borrower can save, which lenders read as a proxy for being able to meet repayments.

What it means in practice:

- **What counts:** funds genuinely saved over time and held in the borrower's name (savings/offset/term-deposit), and — at many lenders — **shares held ≥3 months** (sometimes discounted) and **regular contributions** parked over time.
- **The "1% rule" — large lump sums don't count.** A deposit of **more than ~1% of the price** that landed in the account **within the last 3 months** is typically **excluded** from genuine savings — because it wasn't *saved*, it *arrived*. This is the crucial trap: a **family gift, an inheritance, or an FHSS release**, however large, generally does **not** satisfy genuine savings on its own.
- **Rental history as a substitute.** Several lenders accept **12+ months of on-time rental payments** (evidenced by a rental ledger from a licensed agent) as **equivalent to genuine savings** — a major alternative path for someone who has the deposit but not the 3-month saving trail.

## The post-settlement reserve buffer — the planning figure

Separately, prudent planning leaves a **cash reserve after settlement**. The plan's default is **~3 months of loan repayments** held in reserve (the `reserve_buffer.months_of_repayments_recommended` default). A common stronger heuristic is to aim for **8–10% of the purchase price in total cash** going in — covering deposit + all costs + a residual buffer — even when only a 5% deposit is being used. This is **planning prudence, not a lender rule**: lenders assess servicing with their own buffer (see [serviceability-basics](../lender/serviceability-basics.md)); the reserve here is for the *buyer's* resilience.

## Relevance for Vietnamese-Australian buyers (Mode A)

- **Family contribution is common — and the genuine-savings trap bites it.** Many Mode A buyers receive a parental gift toward the deposit (the blueprint's `family_contribution` input). That money helps the **deposit** but, under the **1% rule**, generally **fails genuine savings** if it arrived recently. The plan must surface this early: a $100k gift can fund the deposit yet still leave the buyer needing **5% saved over 3 months** or a **rental ledger** to clear the lender's gate. Missing this derails an otherwise-fundable purchase.
- **Rental history is the unlock for long-term renters.** A large share of Mode A buyers have rented for years with clean ledgers — the **12-month rental-history substitute** is often the cleanest route to satisfy genuine savings alongside a family-funded deposit. Surface it as an option to confirm with the lender/broker.
- **FHG doesn't remove genuine savings.** The [FHG](../scheme/fhg.md) removes LMI and allows a 5% deposit, but most panel lenders still apply their genuine-savings policy — flag that the two are separate gates.
- **Information, not advice.** The plan explains the gates and the substitutes and shows the buffer maths; it does not direct the buyer to a lender with a particular genuine-savings policy (ASIC: no credit advice).

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **reference doc** — it fills no slot. `cash_position.reserve_buffer.amount` is resolver-computed (months × monthly repayment); the genuine-savings assessment is **agent-reasoned** from `profile` facts (deposit composition, `family_contribution`, rental history) against these policy parameters.

```jsonc
{
  "fills": [],
  "parameters": {
    "genuine_savings_pct_of_price":              { "type": "percentage", "value": 5,  "note": "LENDER POLICY/CONVENTION — most lenders require 5% of price as genuine savings for high-LVR loans; the threshold percentage itself is fairly standard, the policy around it varies" },
    "genuine_savings_min_months_held":           { "type": "integer",    "value": 3,  "note": "CONVENTION — funds must be held/accumulated ≥3 months to count as genuine savings" },
    "genuine_savings_required_above_lvr_pct":    { "type": "percentage", "value": 85, "note": "CONVENTION — genuine savings generally required above ~85% LVR; some lenders apply at 80%, some only at 90%+ — varies, present as typical" },
    "large_deposit_excluded_above_pct_of_price": { "type": "percentage", "value": 1,  "note": "CONVENTION — 'the 1% rule': a lump sum >1% of price arriving within the last 3 months is excluded from genuine savings (gift/inheritance/FHSS release don't count as saved)" },
    "rental_history_accepted_as_genuine_savings": { "type": "bool",      "value": true, "note": "LENDER POLICY — several lenders accept a 12+ month on-time rental ledger as equivalent to genuine savings; not universal, confirm with lender" },
    "rental_history_min_months":                 { "type": "integer",    "value": 12, "note": "LENDER POLICY — rental ledger length typically required for the rent-as-genuine-savings substitute" },
    "recommended_post_settlement_reserve_months": { "type": "integer",   "value": 3,  "note": "CONVENTION/planning — default cash reserve held after settlement, in months of loan repayments; matches cash_position.reserve_buffer.months_of_repayments_recommended" },
    "prudent_total_cash_pct_of_price_low":       { "type": "percentage", "value": 8,  "note": "CONVENTION/planning — 'buffer rule' lower end: aim for 8% of price in total cash (deposit + costs + reserve), even on a 5% deposit scheme; NOT a lender requirement" },
    "prudent_total_cash_pct_of_price_high":      { "type": "percentage", "value": 10, "note": "CONVENTION/planning — buffer-rule upper end" }
  }
}
```

Notes:

- **No `fills`.** No outcome leaf is set. `cash_position.reserve_buffer.amount` is the resolver applying `recommended_post_settlement_reserve_months` to the monthly repayment; whether a buyer clears the **genuine-savings** gate is agent-reasoned from deposit composition (`family_contribution`, savings trail, rental history) against these parameters. The doc supplies the policy facts, not a verdict.
- **Two gates, deliberately separated.** **Genuine savings** is a *lender approval* requirement (pre-settlement, behavioural); the **reserve buffer** is *planning prudence* (post-settlement, resilience). They are different numbers for different purposes — documented apart so the agent never presents the planning buffer as a lender rule or vice versa.
- **All figures are CONVENTION or LENDER POLICY — none regulated.** Genuine savings is not a regulatory requirement (it is lender risk policy, downstream of APRA responsible-lending expectations); the buffer is planning advice. Tagged so the agent presents them as "most lenders / a prudent rule," never as law. The one genuinely regulatory buffer (the APRA serviceability assessment rate) is owned by [`kb.lender.serviceability-basics`](../lender/serviceability-basics.md) — not re-derived here.
- **The 1% rule is the load-bearing Mode A fact.** It is what makes a family-gifted deposit insufficient on its own, so it is captured as an explicit parameter (not buried in prose) for the agent to reason over `family_contribution`.

## Sources

**Canonical (regulator):**

- APRA — *Prudential Practice Guide APG 223 Residential Mortgage Lending* — primary, ¶ on minimum deposit requirements: "ADIs typically require a borrower to provide an initial deposit primarily drawn from the borrower's own funds. Imposing a minimum 'genuine savings' requirement … is considered an important means of reducing default risk. A prudent ADI would have limited appetite for taking into account non-genuine savings, such as gifts from a family member." This is the regulatory basis for the genuine-savings gate and the exclusion of recent large deposits (the 1% rule). — https://www.apra.gov.au/prudential-practice-guide-apg-223-residential-mortgage-lending (primary: `docs/sources/apra/apg-223-residential-mortgage-lending_0.pdf` — the July 2019 text; the genuine-savings guidance is unchanged in later versions, though the provided copy predates the June 2025 HELP-debt amendments)

**Lender / LMI-insurer operational policy** — the 5% / 3-month / 1% specifics are not published by any single regulator; APG 223 sets the principle, these articulate prevailing lender practice:

- Hunter Galloway — *What is genuine savings?* / *Minimum deposit for home loan Australia 2026* (the 1% rule excluding recent large deposits; rental history as equivalent; 8–10% total-cash buffer) — https://www.huntergalloway.com.au/what-is-genuine-savings/
- loans.com.au — *Do you need genuine savings for a house deposit?* (genuine vs non-genuine; gifts/inheritance excluded; 5% / 3-month rule above 85–90% LVR) — https://www.loans.com.au/home-loans/do-you-need-genuine-savings-for-a-house-deposit
