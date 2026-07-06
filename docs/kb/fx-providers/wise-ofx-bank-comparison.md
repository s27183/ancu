---
slug: kb.fx-providers.wise-ofx-bank-comparison
effective_from: 2025-07-01
last_verified: 2026-07-06
sources:
  - url: https://wise.com/au/currency-converter/vnd-to-aud-rate
    retrieved: 2026-07-06
    note: "Wise VND→AUD — transparent upfront fee on the real mid-market rate ('no sneaky mark-up'), the model this doc contrasts against banks that embed the margin in the exchange rate. Confirms the 'rank by transparent landed cost' comparison dimension. Spread magnitudes remain owned by kb.fx.typical-spreads-vnd-aud."
---

# FX / money-transfer provider comparison — VN→AU transfers

This doc owns the **framework for comparing cross-border transfer providers** so `cross_border_funding` (component 7) can produce a **cost-ranked comparison** the user evaluates: the comparison dimensions, the selection rule, and the boundary that keeps it decision-support. It grounds `provider_selection` (`evaluated_providers`, `recommended_provider`, `recommendation_reasoning`). It does **not** own the spread magnitudes — those are owned by [`kb.fx.typical-spreads-vnd-aud`](../fx/typical-spreads-vnd-aud.md) — nor the VN-side capital-control process, owned by the VN placeholders [`kb.vn-capital-controls.sbv-thresholds-2026`](../vn-capital-controls/sbv-thresholds-2026.md) and [`kb.vn-capital-controls.declared-purpose-categories`](../vn-capital-controls/declared-purpose-categories.md).

This is the Mode-B FX analogue of [`kb.lender.non-resident-friendly-shortlist`](../lender/non-resident-friendly-shortlist.md) — but with a **different boundary**. Naming publicly-priced transfer utilities and ranking them by **transparent landed cost** *is* legitimate decision-support (like a product-comparison site); the line here is **AFSL / personal financial product advice**, not the ACL credit line. The comparison presents cost facts and ranks by cost; it never opines that a provider is *suitable for the person's circumstances*, and the platform takes **no referral fee** from any provider.

## What to compare — the dimensions

- **Total landed cost** — the single ranking metric: FX margin (owned by [`kb.fx.typical-spreads-vnd-aud`](../fx/typical-spreads-vnd-aud.md)) + fixed transfer fee + any receiving-bank fee = the AUD that actually arrives. Everything else is a tie-breaker.
- **Fee structure** (qualitative): specialist providers price mostly via a **transparent percentage fee at/near the mid-market rate**; margin-based providers build the cost **into the rate** and often **waive the fixed fee above a threshold**; banks add a **wire fee on top of a wider margin**.
- **Speed / ETA** — settlement timing matters against the transfer buffer before settlement.
- **Transfer limits** — a large VN-side lump sum may exceed a provider's per-transfer cap, forcing a split or a bank route.
- **VN-side compliance friction** — SBV documentation and declared purpose (owned by the VN placeholders) can make one channel far slower than another.
- **AUD receiving** — funds must arrive to the AU account in time for settlement.

## The selection rule — rank by landed cost for the amount

The resolver computes each candidate's **total landed cost for the user's specific amount** and ranks them; `recommendation_reasoning` states *why the top-ranked option is cheapest for that amount*. The **structural crossover**: for **small** transfers a flat-percentage-fee specialist usually wins; for **large** transfers a margin-based provider whose **margin shrinks with size** can beat it — so the cheapest *category* depends on the amount. The user then obtains a **live quote** (rates and fees move) and **picks**.

## The boundary — decision-support, not advice

- **Transparent-cost comparison, not personal advice.** Ranking publicly-priced transfer services by landed cost is decision-support; it is **not personal financial product advice** (no suitability opinion on the person's circumstances — the AFSL line).
- **No referral bias.** The platform takes **no commission or referral fee** from any provider; the ranking is by cost only (independence — principle 8).
- **Execution is licensed and user-driven.** The transfer is executed through a **licensed money-transfer provider or bank**; the platform is informational, and the user obtains the live quote and confirms.

## Relevance for the Vietnam-parent-funded / temp-resident buyer (Mode B)

- **The amount decides the cheapest category.** VN-parent deposits are often large enough to sit near the specialist/margin crossover — so the plan ranks *for the actual amount*, not by a blanket "use Wise."
- **Compliance friction is a real tie-breaker.** A marginally cheaper channel that stalls on SBV documentation can miss settlement; the plan weighs speed and VN-side friction alongside cost.
- **Information, not advice.** The comparison surfaces transparent cost + trade-offs; the user picks and gets a live quote (AFSL line).

## Rules

Pure-reference (`fills: []`). The resolver builds `evaluated_providers` by computing each candidate's landed cost for the amount (magnitudes from [`kb.fx.typical-spreads-vnd-aud`](../fx/typical-spreads-vnd-aud.md)), ranks by total landed cost, and sets `recommended_provider` + `recommendation_reasoning` as a **cost ranking**. The boundary flags below make the AFSL line machine-checkable. No leaf asserted; no spread magnitude stored here.

```jsonc
{
  "fills": [],
  "parameters": {
    "comparison_is_cost_decision_support": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "the comparison ranks publicly-priced providers by transparent landed cost; it is decision-support, not advice." },
    "ranked_by_total_landed_cost": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "the single ranking metric is total landed cost (margin + fixed fee + receiving fee) for the user's specific amount; magnitudes owned by kb.fx.typical-spreads-vnd-aud." },
    "not_personal_financial_product_advice": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "AFSL boundary — no suitability opinion on the person's circumstances; a cost ranking of publicly-priced utilities is not personal financial product advice." },
    "no_provider_referral_fee": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "independence (principle 8) — the platform takes no commission/referral from any provider; ranking is by cost only." },
    "user_obtains_live_quote_and_picks": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "rates and fees move; the user obtains a live quote and confirms the choice." },
    "defer_execution_to_licensed_provider": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "the transfer is executed through a licensed money-transfer provider or bank; the platform stays informational." },
    "cheapest_category_depends_on_amount": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "small transfers favour flat-%-fee specialists; large transfers can favour margin-based providers whose margin shrinks with size — rank for the actual amount." }
  },
  "lookup": {
    "comparison_dimensions": {
      "note": "the dimensions the resolver reasons over to build a cost-ranked comparison; total landed cost is the ranking metric, the rest are tie-breakers. Magnitudes are owned by kb.fx.typical-spreads-vnd-aud, not duplicated here.",
      "entries": [
        { "dimension": "total_landed_cost", "role": "ranking_metric", "owner": "kb.fx.typical-spreads-vnd-aud" },
        { "dimension": "fee_structure", "role": "cost_shape", "note": "specialist %-fee at mid-market vs margin-in-rate (fee waived above threshold) vs bank margin + wire fee" },
        { "dimension": "speed_eta", "role": "tie_breaker", "note": "against the transfer buffer before settlement" },
        { "dimension": "transfer_limits", "role": "tie_breaker", "note": "large VN-side sums may exceed a provider cap" },
        { "dimension": "vn_side_compliance_friction", "role": "tie_breaker", "owner": "kb.vn-capital-controls.declared-purpose-categories" },
        { "dimension": "aud_receiving", "role": "tie_breaker", "note": "funds must arrive to the AU account before settlement" }
      ]
    }
  }
}
```

Notes:

- **No `fills`; a framework + boundary doc.** The doc owns the *dimensions*, the *ranking rule*, and the *AFSL boundary flags*; it holds no spread magnitude (→ [`kb.fx.typical-spreads-vnd-aud`](../fx/typical-spreads-vnd-aud.md)). The ranked comparison is produced at runtime for the actual amount, and the user picks.
- **Boundary as data.** The six flags make the AFSL line machine-checkable (cost-decision-support, ranked-by-cost, not-advice, no-referral-fee, user-picks-with-quote, defer-execution) — the FX analogue of [`kb.lender.non-resident-friendly-shortlist`](../lender/non-resident-friendly-shortlist.md), tuned to AFSL rather than ACL.
- **Naming is allowed here.** Unlike the lender case (no named lenders — credit advice), naming publicly-priced transfer utilities and ranking by transparent cost is legitimate; the blueprint enum (`wise`, `ofx`, `bank_wire_*`) reflects this. The discipline is *cost ranking + no suitability opinion + no referral bias*.

## Sources

- ASIC Moneysmart — *International money transfers* (compare the exchange-rate margin and fees; total cost is margin + fees) — https://moneysmart.gov.au/banking/international-money-transfers
- Wise — *OFX vs Wise* (transparent %-fee vs margin-in-rate; where each is cheaper by amount) — https://wise.com/us/blog/ofx-vs-wise
- Wise — *Send money to Vietnam* (mid-market rate + upfront percentage fee; transfer limits) — https://wise.com/au/send-money/send-money-to-vietnam
- OFX — *AUD to VND exchange rate* (margin-based pricing; fixed fee waived above a threshold; large-transfer positioning) — https://www.ofx.com/en-us/exchange-rates/aud-to-vnd/
- The Currency Shop — *Cheaper Ways to Send Money to Vietnam from Australia* (specialist vs bank landed-cost comparison) — https://www.thecurrencyshop.com.au/international-money-transfers/send-money-to-vietnam
