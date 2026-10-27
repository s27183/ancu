---
slug: kb.selling-costs.agent-legal
effective_from: 2026-06-21
last_verified: 2026-10-27
sources:
  - url: https://www.nsw.gov.au/housing-and-construction/buying-and-selling-property/selling-a-property/agency-agreements
    retrieved: 2026-10-27
    path: docs/sources/selling-costs/nswgov-agency-agreements.txt
    quotes:
      - "You can negotiate with the agent about the amounts of any commissions, fees or other expenses that you may be required to pay."
      - "Ask each agent for a printed list of their fees and commission rates and the expenses (for example, advertising) they charge."
---

# Selling costs — agent commission, legal, and marketing

When a property is **sold** (the `dispose` phase), the proceeds are reduced by the **costs of selling**: the **agent's commission**, **legal / conveyancing** on the sale side, and **marketing / advertising** (plus, for an auction, the auctioneer fee). This doc owns the **conventional ranges** for those costs, which the `disposition` resolver places as the dispose-phase `selling_costs` (`money_out`). They are **estimates surfaced as bands**, not regulated figures — the only regulated transaction cost at sale (land-titles dealing fees) is small and state-specific, and the buyer-side transaction costs at *purchase* are owned separately by `kb.buyer-costs.inspections-conveyancing-fees`.

## Agent commission — the dominant cost

The selling agent's commission is the largest selling cost and is **negotiable**: the NSW Government says a seller "can negotiate with the agent about the amounts of any commissions, fees or other expenses", and that commission may change with the price (a tiered or incentive structure) rather than be a flat fee. It varies by **state**, by **price**, and by **agency**. The plan carries **1.5%–3.5% of the sale price** as a **placeholder** — no selling agency's own published commission has been read for this doc yet, so the band is not grounded on a primary; the agent's written agency agreement is the figure. Because it is a percentage of the sale price, the `disposition` resolver applies it to the **projected** `sale_proceeds`, so it is itself a `money_range` when the proceeds are banded.

## Legal / conveyancing on sale

Sale-side **conveyancing or solicitor** costs cover preparing the contract of sale / vendor statement and handling settlement. The plan carries **$500–$2,500** as a **placeholder** — no conveyancer's own published sale fee grounds the band yet; the conveyancer's quote is the figure. State-specific document requirements (e.g. a VIC Section 32 vendor statement) push it up.

## Marketing / advertising

**Marketing** (photography, listing portals, signboard, copywriting, and — for an auction — the auctioneer fee) is typically paid by the vendor; in NSW the agency agreement must state these expenses, and the government tells sellers to ask each agent for "a printed list of their fees and commission rates and the expenses (for example, advertising) they charge". The plan carries **$600–$8,000** as a **placeholder** — no agency's own published campaign price grounds it yet. Premium campaigns (video, staging/styling) push higher; a low-key private-treaty sale lower.

## Relevance for Vietnamese-Australian buyers (Mode A)

- **Selling costs net down the equity-at-sale.** For a Mode A owner the dispose phase is the **graduation / upgrade** story — equity realised at sale → the next purchase. Selling costs (agent + legal + marketing) are the real haircut on that equity, so the plan places them explicitly rather than leaving the net proceeds overstated.
- **Banded, because they are estimates — and placeholders.** Commission is negotiable and marketing is campaign-dependent; the plan surfaces a **range** labelled as a placeholder, not a single asserted figure, until the bands are re-grounded on providers' own published fees.
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
          "note": "PLACEHOLDER — no primary states this band; re-ground on several selling agencies' own published commission rates (an agency's own fee page or its standard agency agreement). The NSW Government confirms only that commission is negotiable and may change with price.",
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
            "vi": "Bang, khu vực, giá nhà và từng công ty môi giới; có thể thương lượng, và có thể thay đổi theo giá bán. Hợp đồng ủy quyền (agency agreement) ghi con số thật.",
            "en": "State, suburb, price and agency; negotiable, and it can change with the sale price. The written agency agreement holds the real figure."
          },
          "source": "https://www.nsw.gov.au/housing-and-construction/buying-and-selling-property/selling-a-property/agency-agreements"
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
          "note": "PLACEHOLDER — no primary states this band; re-ground on several selling agencies' own published marketing or advertising campaign prices (an agency's own price list, or the expenses its agency agreement states).",
          "label": {
            "vi": "Chi phí quảng cáo bán nhà (marketing)",
            "en": "Sale marketing and advertising"
          },
          "payer": {
            "vi": "Người bán trả, thường trước khi bán xong",
            "en": "The seller pays, often before the sale completes"
          },
          "drivers": {
            "vi": "Gói quảng cáo: ảnh chụp, đăng tin trên các trang bất động sản, bảng hiệu, dàn dựng nội thất (styling); gói cao cấp hoặc đấu giá cao hơn. Hỏi môi giới danh sách phí in sẵn.",
            "en": "The package: photography, listings on property portals, signboard, styling; a premium campaign or auction costs more. Ask the agent for a printed list of its expenses."
          },
          "source": "https://www.nsw.gov.au/housing-and-construction/buying-and-selling-property/selling-a-property/agency-agreements"
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
          "note": "PLACEHOLDER — no primary states this band; re-ground on several conveyancers' or solicitors' own published fixed fees for a residential sale (a firm's own fee page), per state.",
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
          "source": null
        }
      ]
    }
  }
}
```

Notes:

- **No `fills`.** No outcome leaf is set by a KB rule. `disposition.selling_costs` is resolver-computed from these bands applied to the projected proceeds; the doc supplies the bands and the method.
- **PLACEHOLDER bands.** The three bands keep their values (the engine sums them into `selling_costs`) but none is yet grounded on a provider's own published price; each note names the provider page to re-ground on. A comparison site, directory or another firm's market article never grounds them.
- **ESTIMATES, not regulated.** Unlike the buyer-side *registration* fees (regulated, per-state, exact — `kb.buyer-costs`) or duty (`kb.stamp-duty.calc-by-state`), selling agent commission and marketing are **negotiable, market-set estimates** — surfaced as bands and labelled as such, consistent with the verify-by-postcondition discipline (regulated figures to the dollar; estimates as ranges).
- **Scope discipline.** Buyer-side purchase transaction costs are owned by `kb.buyer-costs.inspections-conveyancing-fees`; this doc owns only the **sale-side** costs at the dispose phase.

## Sources

**Regulator:**

- NSW Government — *Agency agreements for the sale of property in NSW* (commissions, fees and expenses are negotiable; commission may change with price; ask each agent for a printed list of fees, commission rates and expenses such as advertising) — https://www.nsw.gov.au/housing-and-construction/buying-and-selling-property/selling-a-property/agency-agreements

**Bands — PLACEHOLDER (no primary yet):**

- Commission 1.5%–3.5%, marketing $600–$8,000 and sale conveyancing $500–$2,500 are placeholders. Re-ground each on several providers' own published prices: selling agencies' own commission and campaign price lists, and conveyancers' own fixed sale fees. Update `last_verified` when they are.
