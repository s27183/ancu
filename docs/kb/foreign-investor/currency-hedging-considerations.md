---
slug: kb.foreign-investor.currency-hedging-considerations
effective_from: 2025-07-01
last_verified: 2026-07-03
---

# VND/AUD currency exposure across the investment hold — considerations, not a hedging product

This doc owns the **FX exposure a Vietnam-located investor carries across the full hold**, beyond the one-off transfer spread already owned elsewhere. It grounds `investment_strategy` (component 4) currency-risk reasoning and feeds `ownership_planning_foreign_investor`'s ongoing-obligations surface. It is **informational** — no retail hedging product is assumed available or recommended; the plan states where the exposure sits and the (mostly structural, not product-based) ways it is commonly reduced.

## Where the exposure actually sits, across the lifecycle

Building on [`kb.fx.loan-currency-considerations`](../fx/loan-currency-considerations.md)'s boundary (the loan is always AUD, no loan-side FX) and [`kb.fx.typical-spreads-vnd-aud`](../fx/typical-spreads-vnd-aud.md) (the one-off transfer cost), a Vietnam-located **investor** carries FX exposure the domestic Mode-C investor does not, at three further points:

1. **On the initial transfer** (one-off) — already owned by the FX-spread doc; not restated here.
2. **On rental income, if repatriated rather than reinvested.** Rent is collected in AUD; if the investor converts some or all of it back to VND periodically (rather than accumulating it in an AUD account to service the AUD loan or fund AU-side costs), each conversion carries the spread and rate-movement exposure again.
3. **On the eventual sale proceeds.** The largest single exposure in the lifecycle — a lump sum converted at whatever the VND/AUD rate is at the time of repatriation, after FRCGW withholding and CGT are settled (owned by [`kb.non-resident-tax.foreign-resident-cgt-withholding`](../non-resident-tax/foreign-resident-cgt-withholding.md) and [`kb.tax.cgt-50-percent-discount`](../tax/cgt-50-percent-discount.md)).

## Why a natural hedge already exists, and what remains open

**Servicing the loan from AUD rental income is a natural hedge on the recurring cash flow.** Because the loan is AUD-denominated and rent is collected in AUD, an investor who leaves rental income in Australia to service the mortgage and cover AU-side holding costs (rather than converting it VND-and-back) carries **no FX exposure on the recurring hold-phase cash flow at all** — the exposure only crystallises at the points funds actually cross currencies. This is the single highest-leverage structural choice: **minimise the number of conversions, not the amount converted per conversion.**

What remains genuinely open, and where retail hedging products are generally **not** practical for an individual property investor at this scale:

- **Forward FX contracts** (locking a future rate) exist at the institutional/large-transaction level through some specialist providers, but are uncommon and often uneconomic for a single property's rental cash flow or a one-off sale-proceeds transfer at retail scale — the plan should not present "hedge with a forward contract" as a routine recommendation without the investor obtaining a specific quote.
- **Timing discretion on the sale-proceeds transfer** — the investor typically retains some control over *when* to convert and repatriate sale proceeds (subject to the VN-side capital-control process, still a labelled placeholder — [`kb.vn-capital-controls.sbv-thresholds-2026`](../vn-capital-controls/sbv-thresholds-2026.md)) — is a structural lever the plan can name, without asserting a rate view.
- **Provider choice at each conversion point** stays the load-bearing cost lever the FX-spread doc already owns — a specialist provider's tighter margin matters more, cumulatively, than attempting to time the market.

## Relevance for Vietnam-located investors (Mode D)

- **Fewer conversions beats trying to time the rate.** The plan states the natural-hedge structure (service the loan from AUD rent) as the primary, no-cost lever — before any product-based hedging idea.
- **The sale is the big exposure.** The plan flags the eventual repatriation of sale proceeds as the largest single FX event in the lifecycle, distinct from and larger than the recurring rental-conversion exposure.
- **No hedging product is recommended.** This is decision-support naming where exposure sits and the structural (not product) levers available; a specific hedging instrument, if genuinely warranted at the investor's scale, is a conversation with a licensed FX/financial adviser, not a plan output.
- **Information, not advice.** The plan makes no rate forecast and recommends no financial product.

## Rules

Pure-reference (`fills: []`). This is a decision-support doc — it fills no slot; the agent reasons over the exposure points and the natural-hedge structure when discussing currency risk in `investment_strategy`'s reasoning, and `ownership_planning_foreign_investor` surfaces the repatriation-timing consideration as an ongoing qualitative note, not a computed figure.

```jsonc
{
  "fills": [],
  "parameters": {
    "loan_is_aud_no_loan_side_fx": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "restates kb.fx.loan-currency-considerations — the loan carries no FX; exposure sits on transfers and conversions, not the debt itself." },
    "servicing_from_au_rent_is_a_natural_hedge": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "leaving rental income in AUD to service the AUD loan and AU-side costs eliminates recurring hold-phase FX exposure entirely — the highest-leverage structural lever, no product needed." },
    "sale_proceeds_repatriation_is_the_largest_single_exposure": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "a lump-sum conversion of net sale proceeds is the largest single FX event across the lifecycle." },
    "retail_forward_contracts_generally_impractical_at_this_scale": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "forward FX contracts are uncommon/uneconomic for a single property's cash flow or one-off transfer at retail scale; not a routine recommendation without a specific provider quote." },
    "no_hedging_product_recommended": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "the plan names exposure points and structural levers; it does not recommend a specific financial/FX product — ASIC line." }
  }
}
```

Notes:

- **No `fills`.** Decision-support; no figure or product recommendation.
- **Single-owner via cross-ref.** Loan-currency boundary → `kb.fx.loan-currency-considerations`; transfer spread → `kb.fx.typical-spreads-vnd-aud`; sale-proceeds tax/withholding → `kb.non-resident-tax.foreign-resident-cgt-withholding` + `kb.tax.cgt-50-percent-discount`; VN-side repatriation compliance → the `vn-capital-controls` placeholders. This doc owns only the *ongoing exposure + structural-lever* framing.

## Sources

- ASIC Moneysmart — *International money transfers* (exchange-rate margin as the real cost; applies at every conversion point, not just the initial transfer) — https://moneysmart.gov.au/banking/international-money-transfers
- Wise — *Send money to Vietnam* (specialist-provider margin and mechanics, applicable at any conversion point in the lifecycle, not only the initial deposit transfer) — https://wise.com/au/send-money/send-money-to-vietnam
