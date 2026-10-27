---
slug: kb.fx-providers.wise-ofx-bank-comparison
effective_from: 2025-07-01
last_verified: 2026-10-27
sources:
  - url: https://wise.com/au/currency-converter/vnd-to-aud-rate
    retrieved: 2026-10-27
    path: docs/sources/fx/wise-vnd-to-aud-rate.txt
    note: "Wise on its own pricing: the mid-market rate with an upfront fee. Spread magnitudes are owned by kb.fx.typical-spreads-vnd-aud."
    quotes:
      - "We use the real, mid-market rate with no sneaky mark-up to hide the fees."
  - url: https://wise.com/au/send-money/send-money-to-vietnam
    retrieved: 2026-10-27
    path: docs/sources/fx/wise-send-money-to-vietnam.txt
    quotes:
      - "Low fees — fees get cheaper the more you send"
      - "Sending over 40,000 AUD or equivalent? We'll discount our fee"
      - "We use the mid-market exchange rate — the fairest rate — and always show your fees upfront."
  - url: https://www.ofx.com/en-au/faqs/are-there-any-transfer-fees/
    retrieved: 2026-10-27
    path: docs/sources/fx/ofx-are-there-any-transfer-fees.txt
    quotes:
      - "OFX charges a transaction fee of AU$15 when transferring under AU$10,000 (or foreign currency equivalent)."
      - "If you are comparing rates, you should bear in mind that an attractive exchange rate may be offset by a high transaction fee (or vice versa)."
      - "Third-party banks may deduct a fee from your transfer before paying your recipient."
  - url: https://www.ofx.com/en-us/exchange-rates/aud-to-vnd/
    retrieved: 2026-10-27
    path: docs/sources/fx/ofx-aud-to-vnd.txt
    quotes:
      - "The amounts above are calculated using the Market (Interbank) rate and are not indicative of OFX Customer Rates."
  - url: https://moneysmart.gov.au/banking/sending-money-overseas
    retrieved: 2026-10-27
    path: docs/sources/asic/moneysmart-sending-money-overseas.txt
    quotes:
      - "Providers choose the exchange rate they use. They also charge fees."
      - "the 'margin' fee to convert your currency"
---

# FX / money-transfer provider comparison — VN→AU transfers

This doc owns the **framework for comparing cross-border transfer providers** so `cross_border_funding` (component 7) can produce a **cost-ranked comparison** the user evaluates: the comparison dimensions, the selection rule, and the boundary that keeps it decision-support. It grounds `provider_selection` (`evaluated_providers`, `recommended_provider`, `recommendation_reasoning`). It does **not** own the spread magnitudes — those are owned by [`kb.fx.typical-spreads-vnd-aud`](../fx/typical-spreads-vnd-aud.md) — nor the VN-side capital-control process, owned by the VN placeholders [`kb.vn-capital-controls.sbv-thresholds-2026`](../vn-capital-controls/sbv-thresholds-2026.md) and [`kb.vn-capital-controls.declared-purpose-categories`](../vn-capital-controls/declared-purpose-categories.md).

This is the Mode-B FX analogue of [`kb.lender.non-resident-friendly-shortlist`](../lender/non-resident-friendly-shortlist.md) — but with a **different boundary**. Naming publicly-priced transfer utilities and ranking them by **transparent landed cost** *is* legitimate decision-support (like a product-comparison site); the line here is **AFSL / personal financial product advice**, not the ACL credit line. The comparison presents cost facts and ranks by cost; it never opines that a provider is *suitable for the person's circumstances*, and the platform takes **no referral fee** from any provider.

## What to compare — the dimensions

- **Total landed cost** — the single ranking metric: FX margin (owned by [`kb.fx.typical-spreads-vnd-aud`](../fx/typical-spreads-vnd-aud.md)) + fixed transfer fee + any receiving-bank fee = the AUD that actually arrives. Everything else is a tie-breaker.
- **Fee structure** (qualitative, from each provider's own page): Wise prices at **the mid-market rate plus an upfront fee** that falls as the amount rises (a discount over AU$40,000); OFX builds its margin **into the rate it quotes** and charges **AU$15 under AU$10,000**, none above; a bank sells the currency at **its own rate** and adds its **wire fee** (owned, with the magnitudes, by [`kb.fx.typical-spreads-vnd-aud`](../fx/typical-spreads-vnd-aud.md)).
- **Speed / ETA** — settlement timing matters against the transfer buffer before settlement.
- **Transfer limits** — a large VN-side lump sum may exceed a provider's per-transfer cap, forcing a split or a bank route.
- **VN-side compliance friction** — SBV documentation and declared purpose (owned by the VN placeholders) can make one channel far slower than another.
- **AUD receiving** — funds must arrive to the AU account in time for settlement.

## The selection rule — rank by landed cost for the amount

The resolver computes each candidate's **total landed cost for the user's specific amount** and ranks them; `recommendation_reasoning` states *why the top-ranked option is cheapest for that amount*. The **structural crossover**: a percentage fee and a margin-in-rate scale differently with the amount, and OFX's fixed fee falls away above AU$10,000 while Wise discounts above AU$40,000 — so which category is cheapest depends on the amount, and the ranking is computed for it, never assumed. OFX itself warns that "an attractive exchange rate may be offset by a high transaction fee (or vice versa)". The user then obtains a **live quote** (rates and fees move) and **picks**.

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
    "cheapest_category_depends_on_amount": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "percentage-fee and margin-in-rate pricing scale differently with the amount (OFX: AU$15 fee under AU$10,000 only; Wise: fee discount over AU$40,000) — rank for the actual amount, never by category." }
  },
  "lookup": {
    "comparison_dimensions": {
      "note": "the dimensions the resolver reasons over to build a cost-ranked comparison; total landed cost is the ranking metric, the rest are tie-breakers. Magnitudes are owned by kb.fx.typical-spreads-vnd-aud, not duplicated here.",
      "entries": [
        { "dimension": "total_landed_cost", "role": "ranking_metric", "owner": "kb.fx.typical-spreads-vnd-aud" },
        { "dimension": "fee_structure", "role": "cost_shape", "note": "Wise: mid-market + upfront fee; OFX: margin in the quoted rate + AU$15 under AU$10,000; bank: its own sell rate + wire fee" },
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

- ASIC Moneysmart — *Sending money overseas* (providers choose their exchange rate and charge fees; compare the margin and the fees) — https://moneysmart.gov.au/banking/sending-money-overseas
- Wise — *Send money to Vietnam* (mid-market rate + upfront fee; fee discount over AU$40,000) — https://wise.com/au/send-money/send-money-to-vietnam
- Wise — *VND to AUD rate* (the mid-market rate, no mark-up) — https://wise.com/au/currency-converter/vnd-to-aud-rate
- OFX — *Are there any transfer fees?* (AU$15 under AU$10,000; third-party bank fees) — https://www.ofx.com/en-au/faqs/are-there-any-transfer-fees/
- OFX — *AUD to VND exchange rate* (the interbank rate shown is not OFX's customer rate) — https://www.ofx.com/en-us/exchange-rates/aud-to-vnd/
