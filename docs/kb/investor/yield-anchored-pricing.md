---
slug: kb.investor.yield-anchored-pricing
effective_from: 2025-07-01
last_verified: 2026-06-23
---

# Yield-anchored pricing

An investor's discipline is that the price is derived from the income the property produces, not from what the market is asking. This doc owns the **yield-anchored price-ceiling method** — how a maximum purchase price is computed from a target gross yield and the property's rent, so the bid plan has a defensible walk-away anchor. It grounds `buying_strategy.investor_anchoring.yield_anchored_max_price` (the blueprint's `"Calculated from target_yield × annual_rent"` field). It is a **reference (method)** doc — the figure is **resolver-computed** from inputs the upstream components already own; this doc asserts no rent and no yield of its own. Informational; ASIC line — the ceiling is decision-support, not a valuation or advice to bid.

## The method

Gross yield, price, and rent are three views of one relationship:

```
gross_yield = annual_rent / price
```

Rearranged, the **maximum price** that still meets a target gross yield is:

```
yield_anchored_max_price = annual_rent / target_gross_yield
```

where `annual_rent = weekly_rent × 52` (the methodology owned by [`kb.investor.rental-income-modelling`](rental-income-modelling.md)) and `target_gross_yield` comes from the investor's thesis (`investment_strategy.targets.target_gross_yield`). Worked: a property appraised at **$600/week** ($31,200/year) against a **5%** target gross yield anchors a maximum price of **$31,200 / 0.05 = $624,000**. Bidding above that means accepting a yield below the thesis target.

## How it's used in the bid plan

- **It's a ceiling, not a target.** Buying below the anchor *improves* the yield; the anchor is the line above which the deal stops meeting the thesis. `walk_away_more_strictly_enforced` is the investor-discipline flag ([`kb.investor.bid-discipline`](bid-discipline.md)).
- **`thesis_alignment_check`** (`aligned | stretched | misaligned`) reports where the *likely market price* sits relative to the anchor: at/below = aligned, modestly above = stretched, well above = misaligned.
- **Gross, not net.** The anchor uses **gross** yield (rent ÷ price) because it's a clean, comparable acquisition signal. The net position — after opex, vacancy, and loan costs — is the fuller picture, owned by [`kb.investor.cash-flow-modelling-methodology`](cash-flow-modelling-methodology.md); the gross anchor is the bid-side discipline, the net model is the hold-side reality.
- **The rent input is only as good as its source.** The binding rent is a property manager's written appraisal ([`kb.investor.rental-appraisal-from-pm-agent`](rental-appraisal-from-pm-agent.md)), not a listing estimate — a soft rent figure makes the anchor soft.

## Relevance for Vietnamese-Australian investors (Mode C)

- **The price follows the income.** The plan computes the maximum thesis-consistent price from the rent and the target yield, giving the investor a number to hold the line at — not an emotional ceiling.
- **Above the anchor is a conscious choice.** The plan shows that bidding above the yield-anchored price means knowingly accepting a lower yield, rather than discovering it later.
- **Gross anchors the bid; net governs the hold.** The plan uses gross yield for the bid ceiling and points to the net cash-flow model for the holding reality.
- **Decision-support, not a valuation.** The anchor is a discipline tool, not a property valuation or advice to bid a particular number. Information, not advice.

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **reference (method)** doc — it fills no slot; `yield_anchored_max_price` is **resolver-computed** from `annual_rent` (kb.investor.rental-income-modelling) and `target_gross_yield` (the thesis). This doc supplies the formula and the gross-vs-net discipline.

```jsonc
{
  "fills": [],
  "parameters": {
    "gross_yield_relationship": { "type": "string", "value": "gross_yield = annual_rent / price", "note": "the identity the anchor inverts" },
    "yield_anchored_max_price_formula": { "type": "string", "value": "yield_anchored_max_price = annual_rent / target_gross_yield", "note": "resolver-computed; annual_rent from kb.investor.rental-income-modelling (weekly_rent × 52), target_gross_yield from investment_strategy.targets" },
    "anchor_is_a_ceiling_not_a_target": { "type": "bool", "value": true, "note": "buying below the anchor improves the yield; the anchor is the walk-away line above which the deal stops meeting the thesis (kb.investor.bid-discipline)" },
    "anchor_uses_gross_yield": { "type": "bool", "value": true, "note": "gross (rent ÷ price) for a clean comparable bid signal; the net position is owned by kb.investor.cash-flow-modelling-methodology" },
    "rent_input_owner": { "type": "string", "value": "kb.investor.rental-appraisal-from-pm-agent", "note": "the binding rent is a PM's written appraisal, not a listing estimate — a soft rent makes the anchor soft" },
    "is_decision_support_not_a_valuation": { "type": "bool", "value": true, "note": "ASIC line — the ceiling is a discipline tool, not a property valuation or advice to bid a particular number" }
  }
}
```

Notes:

- **No `fills`.** `yield_anchored_max_price` is resolver-computed (place-don't-recompute: it reads the rent and target the upstream components own). This doc supplies the formula, not the figure.
- **Single-owner via cross-ref.** Rent methodology → `kb.investor.rental-income-modelling`; binding rent source → `kb.investor.rental-appraisal-from-pm-agent`; net position → `kb.investor.cash-flow-modelling-methodology`; walk-away discipline → `kb.investor.bid-discipline`. This doc owns the gross-yield price-ceiling method.
- **Gross vs net.** The anchor is deliberately gross (bid-side); the net cash-flow model is the hold-side reality. The two are not interchangeable.
- **ASIC line.** Decision-support — a discipline anchor, not a valuation or a bid recommendation.

## Sources

- ASIC Moneysmart — *Investing in property* (rental yield = annual rent as a percentage of the price; how to assess it) — https://moneysmart.gov.au/property-investment/investing-in-property
