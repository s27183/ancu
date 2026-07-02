---
slug: kb.fx.typical-spreads-vnd-aud
effective_from: 2025-07-01
last_verified: 2026-07-02
---

# Typical VND→AUD FX spreads — by provider category

This doc owns the **typical cost of converting Vietnamese-side funds to AUD** for the deposit and buying costs — the FX **spread**, banded by provider category. It grounds two components: `cash_position` (component 5, `fx_costs.estimated_fx_spread_percentage` — the planning default) and `cross_border_funding` (component 7, `fx_cost.estimated_total_fx_cost`). It owns only the **spread magnitude**. The **provider-selection framework** (how to compare and rank providers) is owned by [`kb.fx-providers.wise-ofx-bank-comparison`](../fx-providers/wise-ofx-bank-comparison.md); the **loan-currency boundary** (the loan is AUD; where FX risk actually sits) by [`kb.fx.loan-currency-considerations`](loan-currency-considerations.md); the **VN-side capital-control process** (SBV thresholds, declared purpose) by the VN placeholders [`kb.vn-capital-controls.sbv-thresholds-2026`](../vn-capital-controls/sbv-thresholds-2026.md) and [`kb.vn-capital-controls.declared-purpose-categories`](../vn-capital-controls/declared-purpose-categories.md).

## The spread — the real cost of the conversion

The FX cost is mostly the **exchange-rate margin** — the gap between the provider's rate and the mid-market (interbank) rate — plus any fixed transfer fee. For a lump-sum deposit transfer this margin is the **single largest FX cost**; the loan itself carries none (the loan is AUD — [`kb.fx.loan-currency-considerations`](loan-currency-considerations.md)). Because the Vietnamese đồng is a **managed, less-liquid** currency, VND↔AUD margins sit **wider** than a major pair like AUD/USD, and some providers route VND→USD→AUD.

## By provider category — typical bands

- **Specialist money-transfer providers (e.g. Wise, OFX):** total FX cost typically **~0.5–1.5%** of the amount — a transparent margin (or near-mid-market rate) plus a small or waived fixed fee. Usually the lower-cost route.
- **Bank telegraphic transfer:** total FX cost typically **~2.5–4%+** — an exchange margin of ~2.5–3% built into the rate, **plus** a fixed wire fee and possible intermediary / receiving-bank fees.
- **Planning default:** `cash_position` uses **1.5%** as a conservative mid-point (assuming a specialist route). The **actual** spread requires a **live quote** — rates move intraday and provider pricing changes.

## Why VND sits at the wider end

A managed float, lower market liquidity, and SBV-governed outbound flow mean VND↔AUD pricing is less competitive than AUD/USD. Plan on the **higher end** of each band for VND specifically, and treat the 1.5% default as the conservative specialist case, not a floor.

## Relevance for the Vietnam-parent-funded / temp-resident buyer (Mode B)

- **A genuine cost on the whole VN-side contribution.** On a $300k VN-funded deposit, 1.5% = **$4,500**; a bank route at 3% = **$9,000**. Provider choice is worth real money — which is why the comparison framework exists ([`kb.fx-providers.wise-ofx-bank-comparison`](../fx-providers/wise-ofx-bank-comparison.md)).
- **Distinct from the VN capital-control process.** This doc owns the *cost of the conversion*; the SBV documentation/thresholds that govern *whether and how* funds may leave Vietnam are owned by the VN placeholders.
- **Convention, not a fixed figure.** The plan bands the spread and states the default; it never asserts an exact VND/AUD rate — the buyer obtains a live quote before transferring.

## Rules

Pure-reference (`fills: []`). The `cash_position` resolver seeds `estimated_fx_spread_percentage` from `planning_default_spread_pct` (adjustable if the user selects a route), and `cross_border_funding` uses the category bands to estimate `estimated_total_fx_cost` for the amount. All figures are `CONVENTION` (provider pricing, live-quote dependent); no leaf asserted, no exact rate stored.

```jsonc
{
  "fills": [],
  "parameters": {
    "fx_cost_is_mostly_margin": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "the cost is the exchange-rate margin vs mid-market plus any fixed fee; the loan carries no FX (loan is AUD)." },
    "specialist_spread_pct_low": { "type": "percentage", "value": 0.5, "provenance": "CONVENTION", "note": "lower end for a specialist money-transfer provider (Wise/OFX) — transparent margin + small/waived fee." },
    "specialist_spread_pct_high": { "type": "percentage", "value": 1.5, "provenance": "CONVENTION", "note": "upper end for a specialist provider; VND's lower liquidity pushes toward this end." },
    "bank_wire_spread_pct_low": { "type": "percentage", "value": 2.5, "provenance": "CONVENTION", "note": "lower end for a bank telegraphic transfer — margin built into the rate plus a fixed wire fee." },
    "bank_wire_spread_pct_high": { "type": "percentage", "value": 4, "provenance": "CONVENTION", "note": "upper end for a bank wire; intermediary / receiving-bank fees can push higher." },
    "planning_default_spread_pct": { "type": "percentage", "value": 1.5, "provenance": "CONVENTION", "note": "conservative mid-point (specialist route) — seeds cash_position estimated_fx_spread_percentage; the actual spread needs a live quote." },
    "vnd_sits_at_wider_end": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "VND is a managed, less-liquid currency; VND/AUD margins sit wider than major pairs — plan on the higher end of each band." }
  }
}
```

Notes:

- **No `fills`; a banded convention.** No regulated figure — provider pricing is a `CONVENTION`, presented as bands with a live-quote caveat, never an asserted exact rate.
- **Single-owner cross-refs.** The selection framework → [`kb.fx-providers.wise-ofx-bank-comparison`](../fx-providers/wise-ofx-bank-comparison.md); the loan-currency boundary → [`kb.fx.loan-currency-considerations`](loan-currency-considerations.md); the VN capital-control process → the VN placeholders. This doc owns only the spread magnitude.
- **Freshness.** Provider pricing moves; `last_verified` is the freshness anchor. The bands are stable structural facts (specialist < bank); the exact numbers within them are indicative.

## Sources

- Wise — *Send money to Vietnam* (mid-market rate + transparent percentage fee) — https://wise.com/au/send-money/send-money-to-vietnam
- OFX — *AUD to VND exchange rate* (margin built into the rate; fixed fee waived above a threshold) — https://www.ofx.com/en-us/exchange-rates/aud-to-vnd/
- Wise — *OFX vs Wise* (margin vs transparent-fee cost structures; where each is cheaper) — https://wise.com/us/blog/ofx-vs-wise
- The Currency Shop — *Cheaper Ways to Send Money to Vietnam from Australia* (specialist vs bank cost comparison) — https://www.thecurrencyshop.com.au/international-money-transfers/send-money-to-vietnam
- ASIC Moneysmart — *International money transfers* (compare the exchange-rate margin and fees; the margin is the real cost) — https://moneysmart.gov.au/banking/international-money-transfers
