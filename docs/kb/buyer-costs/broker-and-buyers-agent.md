---
slug: kb.buyer-costs.broker-and-buyers-agent
effective_from: 2021-01-01
last_verified: 2026-10-27
sources:
  - url: https://download.asic.gov.au/media/4213629/rep516-published-16-3-2017-1.pdf
    retrieved: 2026-10-16
    path: docs/sources/buyer-costs/asic-rep516-mortgage-broker-remuneration.txt
    quotes:
      - "For a $500,000 home loan, a typical upfront commission of 0.62% would result in a payment by the lender of $3,100 to the aggregator."
      - "Typically a trail commission of 0.18% would also be paid by the lender to the aggregator"
  - url: https://download.asic.gov.au/media/5641325/rg273-published-24-june-2020.pdf
    retrieved: 2026-10-16
    path: docs/sources/buyer-costs/asic-rg273-best-interests-duty.txt
    quotes:
      - "If you are a mortgage broker, you are required to act in the best interests of the consumer when providing credit assistance: s158LA and 158LE of the National Credit Act."
  - url: https://moneysmart.gov.au/home-loans/using-a-mortgage-broker
    retrieved: 2026-10-16
    path: docs/sources/buyer-costs/moneysmart-using-a-mortgage-broker.txt
    quotes:
      - "Lenders generally pay mortgage brokers a commission for distributing their products, so you don't pay them directly."
      - "Sometimes brokers might charge you a fee directly."
      - "You must sign a quote before a broker can provide services and request payment of a fee."
  - url: https://www.nsw.gov.au/housing-and-construction/buying-and-selling-property/buying-property-nsw/using-a-real-estate-agent-to-buy-a-property
    retrieved: 2026-10-16
    path: docs/sources/buyer-costs/nswgov-using-agent-to-buy.txt
    quotes:
      - "Buyer’s agents may charge a fixed fee or a percentage of purchase price. You can negotiate this price as it is not set by law."
  - url: https://www.consumer.vic.gov.au/housing/buying-and-selling-property/buying-property/seek-expert-advice-on-property
    retrieved: 2026-10-16
    path: docs/sources/buyer-costs/cav-seek-expert-advice.txt
    quotes:
      - "You can negotiate the cost of commissions and fees, as they are not set by law."
---

# Buyer-side professionals — mortgage broker and buyer's agent

Two professionals a buyer may hire before or while buying: a **mortgage broker**, who arranges the loan, and a **buyer's agent** (in Victoria a *buyer's advocate*), who searches for and negotiates the property. Their cost works very differently. The broker is **usually paid by the lender**, so the buyer typically pays nothing; the buyer's agent is **paid by the buyer** and is entirely optional. This doc owns both as `fee_lines` (behavior 83) so the plan shows each as its own labelled line.

## The lender-policy cost — mortgage broker

Lenders generally pay the broker a **commission** — a percentage of the loan, part upfront and part ongoing (trail) — so the buyer does not pay the broker directly. ASIC's review of broker remuneration (Report 516, 2017) found a typical **upfront commission of 0.62%** and **trail of 0.18%** a year, paid by the lender: on a $500,000 loan, about $3,100 upfront. Since 1 January 2021 brokers must act in the **consumer's best interests** (National Credit Act s158LA, ASIC RG 273).

Sometimes a broker charges the buyer a fee directly; it must be set out in a written quote the buyer signs before the broker provides services (Moneysmart). The line is therefore **$0 to the buyer**, with the drivers noting that a direct fee needs a signed quote.

## The convention cost — buyer's agent

Buyer's agent fees are **not set by law** (NSW Government; Consumer Affairs Victoria) — they are negotiated and written into the agency agreement. The agent may charge a **fixed fee or a percentage of the purchase price**. The plan carries **1%–3% of the price** as a **placeholder**: no buyer's agent's own published fee has been read for this doc yet, so the band is not grounded on a primary and the buyer's own quote replaces it. The line is a **percentage of price**, marked **optional** — the buyer may well not use one.

## Relevance for Vietnamese-Australian buyers (Mode A)

- **A broker usually costs the buyer nothing** — worth knowing for a first-timer who assumes advice must be paid for. The commission is the lender's cost; the best-interests duty is the protection. Ask the broker how they are paid.
- **A buyer's agent can be a real cost** — at the placeholder 1%–3%, a $700,000 home would be $7,000–$21,000; the agent's own written quote is the figure. Shown as optional so it never inflates the committed total.
- **Information, not advice.** The doc describes the market; it does not recommend a broker, a buyer's agent, or whether to use one.

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json`. This is a **reference doc** — it fills no slot; the engine reads `lookup.fee_lines`.

```jsonc
{
  "fills": [],
  "parameters": {},
  "lookup": {
    "fee_lines": {
      "note": "one entry per fee the buyer cannot know until they hire someone or get a quote; the engine emits one cash event per applicable entry (behavior 83)",
      "entries": [
        {
          "id": "mortgage_broker",
          "phase": "settle", "timing": "one_off", "tier": "LENDER-POLICY", "basis": "fixed",
          "low": 0, "high": 0,
          "applies": {
            "modes": ["fhb-domestic-au", "fhb-foreign-au", "investor-domestic-au", "investor-foreign-au", "nexthome-domestic-au"],
            "states": "all",
            "property": "any", "loan": true
          },
          "optional": false,
          "label":   { "vi": "Môi giới vay (mortgage broker)", "en": "Mortgage broker" },
          "payer":   { "vi": "Thường ngân hàng trả hoa hồng cho môi giới; người mua trả $0", "en": "Usually the lender pays the broker (commission); $0 to the buyer" },
          "drivers": { "vi": "Ngân hàng trả hoa hồng khoảng 0,62% khoản vay lúc giải ngân và 0,18% mỗi năm (ASIC, 2017). Đôi khi môi giới thu phí trực tiếp từ bạn; khi đó họ phải báo giá bằng văn bản và bạn phải ký trước khi họ làm việc.", "en": "The lender pays a commission of about 0.62% of the loan upfront and 0.18% a year in trail (ASIC, 2017). Sometimes a broker charges the buyer a fee directly; it must be set out in a written quote the buyer signs before the broker provides services." },
          "source": "https://moneysmart.gov.au/home-loans/using-a-mortgage-broker"
        },
        {
          "id": "buyers_agent",
          "phase": "settle", "timing": "one_off", "tier": "CONVENTION", "basis": "pct_of_price",
          "low": 1, "high": 3,
          "note": "PLACEHOLDER — no primary states this band; re-ground on two or more buyer's agencies' own published fee pages (a percentage-of-price or fixed fee, plus any engagement fee). NSW Government and Consumer Affairs Victoria confirm only that the fee is a fixed fee or a percentage and is not set by law.",
          "applies": {
            "modes": ["fhb-domestic-au", "fhb-foreign-au", "investor-domestic-au", "investor-foreign-au", "nexthome-domestic-au"],
            "states": "all",
            "property": "any"
          },
          "optional": true,
          "label":   { "vi": "Đại lý mua nhà (buyer's agent)", "en": "Buyer's agent" },
          "payer":   { "vi": "Người mua trả, nếu thuê", "en": "The buyer pays, if they hire one" },
          "drivers": { "vi": "Phí không do luật quy định, có thể thương lượng: tính theo % giá nhà hoặc phí cố định. Dịch vụ trọn gói (tìm, kiểm tra, thương lượng) ở mức cao; chỉ thương lượng hoặc đấu giá thì thấp hơn. Thường cộng GST và một khoản phí ký hợp đồng ban đầu (engagement fee).", "en": "Not set by law and negotiable: a percentage of price or a fixed fee. A full search-to-negotiation service sits at the top; negotiation-only or auction bidding costs less. Usually plus GST and an upfront engagement fee." },
          "source": "https://www.nsw.gov.au/housing-and-construction/buying-and-selling-property/buying-property-nsw/using-a-real-estate-agent-to-buy-a-property"
        }
      ]
    }
  }
}
```

Notes:

- **No `fills`, no parameters.** The engine reads only the `fee_lines` lookup.
- **Two tiers.** The broker line is **LENDER-POLICY** — the commission is the lender's cost and the rates are ASIC's 2017 measure, not a fixed schedule. The buyer's agent line is **CONVENTION** in kind — fees are not set by law (the state guides confirm it is negotiable, fixed or a percentage) — but its 1%–3% figure is a **PLACEHOLDER**: no buyer's agency's own fee page grounds it yet. Re-ground on several agencies' own published fees.
- **Percentage band, excluding GST.** The placeholder is a percentage of price before GST; a re-ground that finds fixed fees converts them at typical prices.
- **`effective_from` 2021-01-01** is the start of the mortgage broker best-interests duty (National Credit Act Pt 3-5A).

## Sources

- ASIC — *Report 516: Review of mortgage broker remuneration* (March 2017) — upfront 0.62% and trail 0.18% paid by the lender
- ASIC — *Regulatory Guide 273: Mortgage brokers: Best interests duty* (June 2020) — s158LA and s158LE of the National Credit Act
- ASIC Moneysmart — *Using a mortgage broker* — lenders generally pay the commission; a direct fee needs a signed written quote
- NSW Government — *Using a real estate agent to buy a property* — buyer's agent fees fixed or a percentage, not set by law
- Consumer Affairs Victoria — *Seek expert advice on property* — buyer's agent fees negotiable, not set by law
- Buyer's agent 1%–3% band — PLACEHOLDER; no buyer's agency's own fee page read yet (re-ground on several agencies' own published fees)
