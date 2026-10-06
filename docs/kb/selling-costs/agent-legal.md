---
slug: kb.selling-costs.agent-legal
effective_from: 2026-06-21
last_verified: 2026-07-06
sources:
  - url: https://whichrealestateagent.com.au/agent-fees/how-much-do-real-estate-agents-charge/
    retrieved: 2026-07-06
---

# Selling costs — agent commission, legal, and marketing

When a property is **sold** (the `dispose` phase), the proceeds are reduced by the **costs of selling**: the **agent's commission**, **legal / conveyancing** on the sale side, and **marketing / advertising** (plus, for an auction, the auctioneer fee). This doc owns the **conventional ranges** for those costs, which the `disposition` resolver places as the dispose-phase `selling_costs` (`money_out`). They are **estimates surfaced as bands**, not regulated figures — the only regulated transaction cost at sale (land-titles dealing fees) is small and state-specific, and the buyer-side transaction costs at *purchase* are owned separately by `kb.buyer-costs.inspections-conveyancing-fees`.

## Agent commission — the dominant cost

The selling agent's commission is the largest selling cost and is **negotiable**; it varies by **state**, by **price**, and by **agency**. Conventionally it runs roughly **1.5%–3.5% of the sale price** (lower in higher-priced, more competitive metro markets such as parts of NSW/VIC; historically higher in QLD and regional areas). It may be a flat percentage or a tiered/incentive structure. Because it is a percentage of the sale price, the `disposition` resolver applies it to the **projected** `sale_proceeds`, so it is itself a `money_range` when the proceeds are banded.

## Legal / conveyancing on sale

Sale-side **conveyancing or solicitor** costs to prepare the contract of sale / vendor statement and handle settlement run conventionally around **$800–$2,500**, broadly similar to the buyer-side figure (`kb.buyer-costs`). State-specific document requirements (e.g. a VIC Section 32 vendor statement) sit at the higher end.

## Marketing / advertising

**Marketing** (photography, listing portals, signboard, copywriting, and — for an auction — the auctioneer fee) is typically paid by the vendor and runs conventionally around **$1,000–$8,000** depending on the campaign and price point. Premium campaigns (video, staging/styling) push higher; a low-key private-treaty sale lower.

## Relevance for Vietnamese-Australian buyers (Mode A)

- **Selling costs net down the equity-at-sale.** For a Mode A owner the dispose phase is the **graduation / upgrade** story — equity realised at sale → the next purchase. Selling costs (agent + legal + marketing) are the real haircut on that equity, so the plan places them explicitly rather than leaving the net proceeds overstated.
- **Banded, because they are estimates.** Commission is negotiable and marketing is campaign-dependent; the plan surfaces a **range** with the assumption stated, not a single asserted figure.
- **Information, not advice.** The plan states conventional ranges and notes they are negotiable; it does not recommend an agent or a commission rate.

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json`. Everything above is `content_md`. This is a **reference doc** — it fills no slot; `disposition.selling_costs` is **resolver-computed** by applying the commission band to the projected `sale_proceeds` and adding the legal + marketing bands.

```jsonc
{
  "fills": [],
  "parameters": {
    "agent_commission_low_pct":   { "type": "percentage", "value": 1.5, "note": "ESTIMATE — conventional low end of selling-agent commission as % of sale price; negotiable, varies by state/price/agency" },
    "agent_commission_high_pct":  { "type": "percentage", "value": 3.5, "note": "ESTIMATE — conventional high end of selling-agent commission as % of sale price (higher in QLD/regional, lower in competitive metro)" },
    "legal_conveyancing_low_aud": { "type": "money", "value": 800,  "note": "ESTIMATE — sale-side conveyancing / solicitor, low end" },
    "legal_conveyancing_high_aud":{ "type": "money", "value": 2500, "note": "ESTIMATE — sale-side conveyancing / solicitor, high end (VIC S32 vendor statement etc. at the top)" },
    "marketing_low_aud":          { "type": "money", "value": 1000, "note": "ESTIMATE — vendor marketing / advertising (photography, portals, signboard), low end" },
    "marketing_high_aud":         { "type": "money", "value": 8000, "note": "ESTIMATE — vendor marketing / advertising, high end (premium campaign, auctioneer, staging)" },
    "commission_applied_to":      { "type": "string", "value": "projected sale_proceeds over horizon H — so selling_costs is itself a money_range when proceeds are banded", "note": "the resolver applies the commission band to the disposition.sale_proceeds range" },
    "surface_as":                 { "type": "string", "value": "banded money_range (selling_costs = commission% × sale_proceeds + legal + marketing) with the negotiable/estimate basis stated in key_assumptions", "note": "estimates, not regulated — surfaced as ranges, never single asserted figures" }
  }
}
```

Notes:

- **No `fills`.** No outcome leaf is set by a KB rule. `disposition.selling_costs` is resolver-computed from these bands applied to the projected proceeds; the doc supplies the bands and the method.
- **ESTIMATES, not regulated.** Unlike the buyer-side *registration* fees (regulated, per-state, exact — `kb.buyer-costs`) or duty (`kb.stamp-duty.calc-by-state`), selling agent commission and marketing are **negotiable, market-set estimates** — surfaced as bands and labelled as such, consistent with the verify-by-postcondition discipline (regulated figures to the dollar; estimates as ranges).
- **Scope discipline.** Buyer-side purchase transaction costs are owned by `kb.buyer-costs.inspections-conveyancing-fees`; this doc owns only the **sale-side** costs at the dispose phase.

## Sources

**Estimates — conventional market ranges (not a regulated primary):**

- Conventional Australian selling-agent commission ranges and vendor marketing costs are market-set and negotiable; the bands above are conservative conventional ranges to be periodically sanity-checked against current state-level agent-fee surveys (e.g. state consumer-affairs / fair-trading guidance and reputable agent-comparison data). Re-verify the bands on the regulatory/data freshness cadence; update `last_verified`.
