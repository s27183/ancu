---
slug: kb.fx.typical-spreads-vnd-aud
effective_from: 2025-07-01
last_verified: 2026-10-16
sources:
  - url: https://wise.com/au/send-money/send-money-to-vietnam
    retrieved: 2026-07-06
  - url: https://www.vietcombank.com.vn/-/media/Project/VCB-Sites/VCB/KHCN/Bieu-mau-Bieu-phi-KHCN/Update-30062026/BP-dich-vu-chuyen-tien-nuoc-ngoai.pdf
    retrieved: 2026-10-16
    path: docs/sources/fx/vietcombank-bieu-phi-chuyen-tien-nuoc-ngoai-2026.txt
    quotes:
      - "Chuyển tiền cho mục đích du học/khám chữa 0,2% 0,2%"
      - "bệnh/trợ cấp nhân thân/du lịch nước ngoài/ Tối thiểu: 5 USD"
      - "công tác nước ngoài Tối đa: 200 USD"
      - "Chuyển đi bằng ngoại tệ khác 20 USD/giao dịch"
      - "1.3. Điện phí 5 USD/điện"
      - "thủ quy định quản lý ngoại hối của NHNN và Tối đa: 990 USD"
  - url: https://techcombank.com/content/dam/techcombank/public-site/documents/bieu-phi-dich-vu-ngan-hang-dien-tu-va-chuyen-tien-ca-nhan-24122025.pdf
    retrieved: 2026-10-16
    path: docs/sources/fx/techcombank-bieu-phi-chuyen-tien-ca-nhan-2025.txt
    quotes:
      - "AUD/CHF/CAD/SGD/THB 25 USD"
      - "tệ online cho KH thường (tối thiểu 10"
      - "0.2%/lệnh (tối"
  - url: https://wise.com/au/currency-converter/usd-to-aud-rate
    retrieved: 2026-10-16
    path: docs/sources/fx/wise-usd-to-aud-rate.txt
    quotes:
      - "$1 USD = 1.443 AUD"
  - url: https://www.commbank.com.au/personal/international/international-money-transfer.html
    retrieved: 2026-10-16
    path: docs/sources/fx/cba-international-money-transfer.txt
    quotes:
      - "For credit of a Commonwealth Bank Australian dollar (AUD) account (regardless of currency) 6 Up to $11.00 per transfer"
  - url: https://www.westpac.com.au/international-travel/international-transfers/
    retrieved: 2026-10-16
    path: docs/sources/fx/westpac-international-transfers.txt
    quotes:
      - "Westpac charge a $12 AUD processing fee when you receive money from overseas. This fee is waived if you're receiving the equivalent of $100 AUD or less."
  - url: https://www.nab.com.au/important-information/personal/fees-charges
    retrieved: 2026-10-16
    path: docs/sources/fx/nab-personal-fees-charges.txt
    quotes:
      - "Transfers to NAB in Australian or overseas currency"
      - "Up to $15"
      - "In some cases, the sending party may instruct us to charge our fee to them. Where we do this, we won’t charge the payment beneficiary"
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
  },
  "lookup": {
    "fee_lines": {
      "note": "one entry per fee the buyer cannot know until they hire someone or get a quote; the engine emits one cash event per applicable entry (behavior 83)",
      "entries": [
        {
          "id": "fx_spread_in",
          "phase": "prepare",
          "timing": "one_off",
          "tier": "CONVENTION",
          "basis": "pct_of_transfer",
          "low": 0.5,
          "high": 4.0,
          "applies": {
            "modes": [
              "fhb-foreign-au",
              "investor-foreign-au"
            ],
            "states": "all",
            "property": "any"
          },
          "optional": false,
          "note": "low = specialist_spread_pct_low; high = bank_wire_spread_pct_high (this doc's parameters)",
          "label": {
            "vi": "Chênh lệch tỷ giá khi chuyển tiền từ Việt Nam sang Úc (FX spread)",
            "en": "FX spread on money sent from Vietnam"
          },
          "payer": {
            "vi": "Người mua chịu — nằm trong tỷ giá, không hiện thành phí riêng",
            "en": "The buyer bears it — built into the rate, not shown as a fee"
          },
          "drivers": {
            "vi": "Thấp (~0,5–1,5%) khi dùng dịch vụ chuyển tiền chuyên biệt; cao (~2,5–4%) khi chuyển khoản ngân hàng (bank wire). VND ít thanh khoản nên thường ở mức cao của mỗi khoảng.",
            "en": "Low (~0.5–1.5%) through a specialist transfer service; high (~2.5–4%) through a bank wire. VND is less liquid, so it sits toward the top of each band."
          },
          "source": "https://wise.com/au/send-money/send-money-to-vietnam",
          "explains": ["cross_border_funding"]
        },
        {
          "id": "vn_outbound_bank_fee",
          "phase": "prepare",
          "timing": "one_off",
          "tier": "CONVENTION",
          "basis": "fixed",
          "low": 15,
          "high": 325,
          "applies": {
            "modes": [
              "fhb-foreign-au",
              "investor-foreign-au"
            ],
            "states": "all",
            "property": "any"
          },
          "optional": false,
          "note": "US$10 (0.2% minimum 5 + wire 5) to US$225 (cap 200 + wire 5 + OUR 20) × 1.443 AUD/USD; the 'other purpose' cap (US$990) is a driver, not the band",
          "label": {
            "vi": "Phí chuyển tiền đi nước ngoài của ngân hàng Việt Nam (mỗi lần chuyển)",
            "en": "Vietnamese bank's outward-transfer fee (per transfer)"
          },
          "payer": {
            "vi": "Người gửi ở Việt Nam trả",
            "en": "The sender in Vietnam pays"
          },
          "drivers": {
            "vi": "Biểu phí ngân hàng: khoảng 0,1–0,2% số tiền (tối thiểu ~5–10 USD) cộng điện phí ~5 USD, thêm ~20–25 USD nếu người gửi chịu luôn phí ngân hàng nhận (OUR). Mức trần ~200 USD với mục đích du học/trợ cấp thân nhân; mục đích khác có thể tới 990 USD. Tính cho mỗi lần chuyển — chia nhiều lần thì tốn nhiều lần.",
            "en": "Bank tariffs: about 0.1–0.2% of the amount (minimum ~US$5–10) plus a ~US$5 wire charge, and ~US$20–25 more if the sender also pays the receiving bank's fee (OUR). Capped ~US$200 for study/family-support purposes; other purposes up to US$990. Charged per transfer — splitting the money multiplies it."
          },
          "source": "https://www.vietcombank.com.vn/-/media/Project/VCB-Sites/VCB/KHCN/Bieu-mau-Bieu-phi-KHCN/Update-30062026/BP-dich-vu-chuyen-tien-nuoc-ngoai.pdf",
          "explains": ["cross_border_funding"]
        },
        {
          "id": "au_inbound_bank_fee",
          "phase": "prepare",
          "timing": "one_off",
          "tier": "CONVENTION",
          "basis": "fixed",
          "low": 0,
          "high": 15,
          "applies": {
            "modes": [
              "fhb-foreign-au",
              "investor-foreign-au"
            ],
            "states": "all",
            "property": "any"
          },
          "optional": false,
          "label": {
            "vi": "Phí nhận tiền quốc tế của ngân hàng Úc (mỗi lần nhận)",
            "en": "Australian bank's inward-transfer fee (per transfer)"
          },
          "payer": {
            "vi": "Người nhận ở Úc trả — $0 nếu người gửi chọn chịu phí (OUR)",
            "en": "The recipient in Australia pays — $0 if the sender chose to pay it (OUR)"
          },
          "drivers": {
            "vi": "Ngân hàng lớn ở Úc thu tới khoảng $11–$15 mỗi lần nhận; một số miễn phí với khoản nhỏ hoặc khi người gửi đã trả phí.",
            "en": "Major Australian banks charge up to about $11–$15 per incoming transfer; some waive it for small amounts or when the sender has paid."
          },
          "source": "https://www.nab.com.au/important-information/personal/fees-charges",
          "explains": ["cross_border_funding"]
        },
        {
          "id": "fx_back",
          "phase": "dispose",
          "timing": "one_off",
          "tier": "CONVENTION",
          "basis": "pct_of_sale",
          "low": 0.5,
          "high": 4.0,
          "applies": {
            "modes": [
              "fhb-foreign-au",
              "investor-foreign-au"
            ],
            "states": "all",
            "property": "any"
          },
          "optional": true,
          "note": "same bands as fx_spread_in, applied to the projected sale price",
          "label": {
            "vi": "Chênh lệch tỷ giá khi chuyển tiền bán nhà về Việt Nam (FX spread)",
            "en": "FX spread on sale proceeds sent back to Vietnam"
          },
          "payer": {
            "vi": "Người bán chịu — nằm trong tỷ giá",
            "en": "The seller bears it — built into the rate"
          },
          "drivers": {
            "vi": "Chỉ phát sinh nếu đưa tiền bán nhà về Việt Nam. Cùng khoảng như chiều vào: dịch vụ chuyên biệt rẻ hơn chuyển khoản ngân hàng.",
            "en": "Only if the proceeds are sent back to Vietnam. Same bands as the inbound direction: a specialist service costs less than a bank wire."
          },
          "source": "https://wise.com/au/send-money/send-money-to-vietnam",
          "explains": ["cross_border_funding"]
        }
      ]
    }
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
