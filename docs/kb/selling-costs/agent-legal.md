---
slug: kb.selling-costs.agent-legal
effective_from: 2026-06-21
last_verified: 2026-10-16
sources:
  - url: https://whichrealestateagent.com.au/agent-fees/how-much-do-real-estate-agents-charge/
    retrieved: 2026-07-06
    path: docs/sources/selling-costs/wrea-how-much-agents-charge.txt
    quotes:
      - "On average, real estate agents in Australia charge between 2% and 3% of your home’s final selling price ."
      - "In Hobart and regional areas, commission rates are higher (around 3% or more)"
  - url: https://www.yourpropertyguide.com.au/guides/real-estate-agent-fees-australia
    retrieved: 2026-10-16
    path: docs/sources/selling-costs/ypg-real-estate-agent-fees.txt
    quotes:
      - "Australian real estate commission is negotiable and typically ranges from 1.5% to 3.5% of the sale price, depending on state, suburb and property value."
      - "Marketing costs (photography, online listings, signboard, styling) are usually charged separately on top of commission and typically run $3,000 to $6,000 for an average home."
  - url: https://www.openagent.com.au/blog/cost-selling-house
    retrieved: 2026-10-16
    path: docs/sources/selling-costs/openagent-cost-selling-house.txt
    quotes:
      - "For advertising and marketing, you can expect to pay anywhere between $600 - $10,000, depending on what package you opt for."
      - "Depending on what package you opt for, expect to pay anywhere from $500 - $8000 for advertising and marketing in Victoria"
      - "As for legal fees, NSW solicitors and conveyancers typically charge around $700 - $2500."
      - "In terms of other selling costs in the Sunshine State, conveyancing ranges anywhere from $500 to $2200."
---

# Selling costs — agent commission, legal, and marketing

When a property is **sold** (the `dispose` phase), the proceeds are reduced by the **costs of selling**: the **agent's commission**, **legal / conveyancing** on the sale side, and **marketing / advertising** (plus, for an auction, the auctioneer fee). This doc owns the **conventional ranges** for those costs, which the `disposition` resolver places as the dispose-phase `selling_costs` (`money_out`). They are **estimates surfaced as bands**, not regulated figures — the only regulated transaction cost at sale (land-titles dealing fees) is small and state-specific, and the buyer-side transaction costs at *purchase* are owned separately by `kb.buyer-costs.inspections-conveyancing-fees`.

## Agent commission — the dominant cost

The selling agent's commission is the largest selling cost and is **negotiable**; it varies by **state**, by **price**, and by **agency**. Conventionally it runs roughly **1.5%–3.5% of the sale price** (lower in higher-priced, more competitive metro markets such as parts of NSW/VIC; historically higher in QLD and regional areas). It may be a flat percentage or a tiered/incentive structure. Because it is a percentage of the sale price, the `disposition` resolver applies it to the **projected** `sale_proceeds`, so it is itself a `money_range` when the proceeds are banded.

## Legal / conveyancing on sale

Sale-side **conveyancing or solicitor** costs to prepare the contract of sale / vendor statement and handle settlement run conventionally around **$500–$2,500**, broadly similar to the buyer-side figure (`kb.buyer-costs`). State-specific document requirements (e.g. a VIC Section 32 vendor statement) sit at the higher end.

## Marketing / advertising

**Marketing** (photography, listing portals, signboard, copywriting, and — for an auction — the auctioneer fee) is typically paid by the vendor and runs conventionally around **$600–$8,000** (about $3,000–$6,000 for an average home) depending on the campaign and price point. Premium campaigns (video, staging/styling) push higher; a low-key private-treaty sale lower.

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
    "commission_applied_to":      { "type": "string", "value": "projected sale_proceeds over horizon H — so selling_costs is itself a money_range when proceeds are banded", "note": "the resolver applies the commission fee line's band to the disposition.sale_proceeds range" },
    "surface_as":                 { "type": "string", "value": "banded money_range (selling_costs = the sum of the non-optional dispose fee_lines: commission% × sale_proceeds + marketing + sale_conveyancing + mortgage_discharge) with the negotiable/estimate basis stated in key_assumptions", "note": "estimates, not regulated — surfaced as ranges, never single asserted figures" }
  },
  "lookup": {
    "fee_lines": {
      "note": "one entry per fee the buyer cannot know until they hire someone or get a quote; the engine emits one cash event per applicable entry (behavior 83)",
      "entries": [
        {
          "id": "commission",
          "phase": "dispose",
          "timing": "one_off",
          "tier": "CONVENTION",
          "basis": "pct_of_sale",
          "low": 1.5,
          "high": 3.5,
          "applies": {
            "modes": [
              "fhb-domestic-au",
              "fhb-foreign-au",
              "investor-domestic-au",
              "investor-foreign-au",
              "nexthome-domestic-au"
            ],
            "states": "all",
            "property": "any"
          },
          "optional": false,
          "label": {
            "vi": "Hoa hồng môi giới bán nhà (agent commission)",
            "en": "Selling agent's commission"
          },
          "payer": {
            "vi": "Người bán trả, trừ vào tiền bán nhà",
            "en": "The seller pays, from the sale proceeds"
          },
          "drivers": {
            "vi": "Bang, khu vực và giá nhà: thành phố lớn cạnh tranh thường ~2–2,5%; Hobart và vùng xa ~3% trở lên. Có thể thương lượng.",
            "en": "State, suburb and price: competitive capital cities are often ~2–2.5%; Hobart and regional areas ~3% or more. Negotiable."
          },
          "source": "https://www.yourpropertyguide.com.au/guides/real-estate-agent-fees-australia"
        },
        {
          "id": "marketing",
          "phase": "dispose",
          "timing": "one_off",
          "tier": "CONVENTION",
          "basis": "fixed",
          "low": 600,
          "high": 8000,
          "applies": {
            "modes": [
              "fhb-domestic-au",
              "fhb-foreign-au",
              "investor-domestic-au",
              "investor-foreign-au",
              "nexthome-domestic-au"
            ],
            "states": "all",
            "property": "any"
          },
          "optional": false,
          "note": "$600 is the low end of the national $600–$10,000; $8,000 the top of the Victorian $500–$8,000 (the prior marketing band was $1,000–$8,000)",
          "label": {
            "vi": "Chi phí quảng cáo bán nhà (marketing)",
            "en": "Sale marketing and advertising"
          },
          "payer": {
            "vi": "Người bán trả, thường trước khi bán xong",
            "en": "The seller pays, often before the sale completes"
          },
          "drivers": {
            "vi": "Gói quảng cáo: ảnh chụp, đăng tin trên các trang bất động sản, bảng hiệu, dàn dựng nội thất (styling). Nhà trung bình khoảng $3.000–$6.000; gói cao cấp hoặc đấu giá cao hơn.",
            "en": "The package: photography, listings on property portals, signboard, styling. An average home is about $3,000–$6,000; a premium campaign or auction costs more."
          },
          "source": "https://www.openagent.com.au/blog/cost-selling-house"
        },
        {
          "id": "sale_conveyancing",
          "phase": "dispose",
          "timing": "one_off",
          "tier": "CONVENTION",
          "basis": "fixed",
          "low": 500,
          "high": 2500,
          "applies": {
            "modes": [
              "fhb-domestic-au",
              "fhb-foreign-au",
              "investor-domestic-au",
              "investor-foreign-au",
              "nexthome-domestic-au"
            ],
            "states": "all",
            "property": "any"
          },
          "optional": false,
          "note": "QLD $500–$2,200, NSW $700–$2,500",
          "label": {
            "vi": "Phí luật sư/chuyển nhượng khi bán (conveyancing)",
            "en": "Conveyancing / legal on the sale"
          },
          "payer": {
            "vi": "Người bán trả",
            "en": "The seller pays"
          },
          "drivers": {
            "vi": "Bang (VIC cần bản kê của người bán — Section 32 — nên cao hơn), độ phức tạp của hợp đồng và chọn chuyên viên chuyển nhượng (conveyancer) hay luật sư.",
            "en": "State (VIC needs a vendor's statement — Section 32 — so costs more), the contract's complexity, and a conveyancer versus a solicitor."
          },
          "source": "https://www.openagent.com.au/blog/cost-selling-house"
        }
      ]
    }
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
