---
slug: kb.fx.typical-spreads-vnd-aud
effective_from: 2025-07-01
last_verified: 2026-10-27
sources:
  - url: https://wise.com/gateway/v1/price?sourceAmount=1000000000&sourceCurrency=VND&targetCurrency=AUD
    retrieved: 2026-10-27
    path: docs/sources/fx/wise-price-vnd-aud-2026-10-27.txt
    note: "Wise's own price data for its VND→AUD route (the JSON behind its calculator): 1,000,000,000 VND to an AUD bank account costs 5,210,063 VND in fees (0.52% + 37,155 VND), at the mid-market rate 1 VND = 0.0000550401 AUD (1 AUD ≈ 18,168.6 VND)."
    quotes:
      - "\"payInMethod\":\"BANK_TRANSFER\",\"payOutMethod\":\"BANK_TRANSFER\",\"sourceCcy\":\"VND\",\"targetCcy\":\"AUD\",\"total\":5210063.0"
      - "\"variableFeePercent\":0.52"
      - "\"flatFee\":37155.0,\"midRate\":5.50401E-5"
  - url: https://wise.com/au/send-money/send-money-to-vietnam
    retrieved: 2026-10-27
    path: docs/sources/fx/wise-send-money-to-vietnam.txt
    quotes:
      - "We use the mid-market exchange rate — the fairest rate — and always show your fees upfront."
      - "Sending over 40,000 AUD or equivalent? We'll discount our fee"
  - url: https://portal.vietcombank.com.vn/Usercontrols/TVPortal.TyGia/pXML.aspx
    retrieved: 2026-10-27
    path: docs/sources/fx/vietcombank-exchange-rates-2026-10-27.txt
    note: "Vietcombank's own rate feed, 27 Oct 2026 11:01 (VN time): it sells AUD at 18,425.27 VND — 1.41% above Wise's mid-market 18,168.6 that morning; it sells USD at 26,040 — 0.79% above Wise's USD mid 25,837."
    quotes:
      - "<Exrate CurrencyCode=\"AUD\" CurrencyName=\"AUSTRALIAN DOLLAR \" Buy=\"17,674.51\" Transfer=\"17,853.04\" Sell=\"18,425.27\" />"
      - "<Exrate CurrencyCode=\"USD\" CurrencyName=\"US DOLLAR \" Buy=\"25,630.00\" Transfer=\"25,660.00\" Sell=\"26,040.00\" />"
  - url: https://bidv.com.vn/ServicesBIDV/ExchangeDetailServlet
    retrieved: 2026-10-27
    path: docs/sources/fx/bidv-exchange-rates-2026-10-27.txt
    note: "BIDV's own rate feed (the data behind its rates page), 27 Oct 2026 09:19: it sells AUD ('ban') at 18,564 VND — 2.18% above Wise's mid-market 18,168.6 that morning."
    quotes:
      - "\"muaTm\":\"17,820\",\"muaCk\":\"17,884\",\"currency\":\"AUD\",\"nameEN\":\"AUD\",\"ban\":\"18,564\""
  - url: https://www.ofx.com/en-au/faqs/are-there-any-transfer-fees/
    retrieved: 2026-10-27
    path: docs/sources/fx/ofx-are-there-any-transfer-fees.txt
    quotes:
      - "OFX charges a transaction fee of AU$15 when transferring under AU$10,000 (or foreign currency equivalent)."
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

- **Specialist money-transfer providers:** **Wise** prices its own VND→AUD route at the mid-market rate plus **0.52%** and a 37,155 VND flat fee (1,000,000,000 VND to an AUD bank account: 5,210,063 VND in fees, 27 Oct 2026). **OFX** builds its margin into the rate it quotes ("not indicative of OFX Customer Rates" — the interbank rate it shows) and charges AU$15 under AU$10,000; it publishes no margin, so the band's upper end (**~1.5%**) is a PLACEHOLDER until a live OFX quote grounds it.
- **Vietnamese bank conversion and wire:** the sending bank sells the sender AUD at its own rate. On 27 Oct 2026, **Vietcombank** sold AUD at 18,425.27 VND and **BIDV** at 18,564 VND, against Wise's mid-market 18,168.6 — a margin of **1.41%** and **2.18%**. On top sit the bank's own outward fee (Vietcombank 0.2%, minimum US$5, maximum US$200 for study/family-support purposes, plus a US$5 wire charge — owned by the `vn_outbound_bank_fee` line below) and any intermediary or receiving-bank fee. That puts the bank route at roughly **1.6–2.4%+** in total; the band carried here is **~1.6–4%**, the upper end a PLACEHOLDER for routes converting twice (VND→USD at the Vietnamese bank, USD→AUD at the Australian bank, whose margin no primary in hand states).
- **Planning default:** `cash_position` uses **1.5%** — a conservative planning choice, not a measured figure: about three times Wise's 0.52%, close to Vietcombank's 1.41% AUD margin. The **actual** spread requires a **live quote** — rates move intraday and provider pricing changes.

## Why VND sits at the wider end

The same bank, the same morning, shows it: Vietcombank sold AUD 1.41% above mid-market but USD only 0.79% above. AUD is a thinner market against VND than USD is, so plan on the **higher end** of each band, and treat the 1.5% default as a conservative planning choice, not a floor.

## Relevance for the Vietnam-parent-funded / temp-resident buyer (Mode B)

- **A genuine cost on the whole VN-side contribution.** On a $300k VN-funded deposit, Wise's 0.52% ≈ **$1,560**, the 1.5% default = **$4,500**, BIDV's 2.18% margin alone ≈ **$6,540**. Provider choice is worth real money — which is why the comparison framework exists ([`kb.fx-providers.wise-ofx-bank-comparison`](../fx-providers/wise-ofx-bank-comparison.md)).
- **Distinct from the VN capital-control process.** This doc owns the *cost of the conversion*; the SBV documentation/thresholds that govern *whether and how* funds may leave Vietnam are owned by the VN placeholders.
- **Convention, not a fixed figure.** The plan bands the spread and states the default; it never asserts an exact VND/AUD rate — the buyer obtains a live quote before transferring.

## Rules

Pure-reference (`fills: []`). The `cash_position` resolver seeds `estimated_fx_spread_percentage` from `planning_default_spread_pct` (adjustable if the user selects a route), and `cross_border_funding` uses the category bands to estimate `estimated_total_fx_cost` for the amount. Each band names the providers' own pages it is drawn from (Wise, Vietcombank, BIDV — 27 Oct 2026); the ends no primary states are PLACEHOLDER. Provider pricing is live-quote dependent; no leaf asserted, no exact rate stored.

```jsonc
{
  "fills": [],
  "parameters": {
    "fx_cost_is_mostly_margin": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "the cost is the exchange-rate margin vs mid-market plus any fixed fee; the loan carries no FX (loan is AUD)." },
    "specialist_spread_pct_low": { "type": "percentage", "value": 0.5, "provenance": "CONVENTION", "note": "CONVENTION band from the provider's own price — Wise: VND→AUD at mid-market + 0.52% (+37,155 VND flat), 27 Oct 2026. OFX publishes no margin (it is built into its quoted rate)." },
    "specialist_spread_pct_high": { "type": "percentage", "value": 1.5, "provenance": "PLACEHOLDER", "note": "PLACEHOLDER — no primary states this; re-ground on a live OFX customer quote for VND→AUD (OFX builds its margin into the rate and publishes none). Upper end for a specialist provider." },
    "bank_wire_spread_pct_low": { "type": "percentage", "value": 1.6, "provenance": "CONVENTION", "note": "CONVENTION band from the banks' own rates, 27 Oct 2026 — Vietcombank: sells AUD at 18,425.27 VND (1.41% over Wise's mid 18,168.6); BIDV: 18,564 VND (2.18%); plus the bank's outward fee (Vietcombank 0.2%). Was 2.5, which both banks' own rates undercut." },
    "bank_wire_spread_pct_high": { "type": "percentage", "value": 4, "provenance": "PLACEHOLDER", "note": "PLACEHOLDER — the two banks' own rates reach ~2.4% with fees; 4% covers a double conversion (VND→USD in Vietnam, USD→AUD at the Australian bank) whose second margin no primary in hand states — re-ground on an Australian bank's own published USD/AUD telegraphic-transfer rate against the RBA's published rate." },
    "planning_default_spread_pct": { "type": "percentage", "value": 1.5, "provenance": "CONVENTION", "note": "a conservative planning choice, not a measured figure — above Wise's 0.52% (27 Oct 2026), near Vietcombank's 1.41% AUD margin; seeds cash_position estimated_fx_spread_percentage; the actual spread needs a live quote." },
    "vnd_sits_at_wider_end": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "Vietcombank, 27 Oct 2026: sells AUD 1.41% over mid-market but USD 0.79% over — the AUD/VND margin is wider; plan on the higher end of each band." }
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
          "note": "low = specialist_spread_pct_low (Wise 0.52%, its own price); high = bank_wire_spread_pct_high (PLACEHOLDER 4% for a double conversion; Vietcombank/BIDV own AUD margins 1.41–2.18%, 27 Oct 2026)",
          "label": {
            "vi": "Chênh lệch tỷ giá khi chuyển tiền từ Việt Nam sang Úc (FX spread)",
            "en": "FX spread on money sent from Vietnam"
          },
          "payer": {
            "vi": "Người mua chịu — nằm trong tỷ giá, không hiện thành phí riêng",
            "en": "The buyer bears it — built into the rate, not shown as a fee"
          },
          "drivers": {
            "vi": "Thấp (~0,5–1,5%) khi dùng dịch vụ chuyển tiền chuyên biệt (Wise: 0,52%); cao hơn (~1,6–4%) khi ngân hàng Việt Nam bán AUD và chuyển đi (Vietcombank, BIDV: chênh 1,4–2,2% so với tỷ giá giữa thị trường, chưa tính phí). AUD ít thanh khoản với VND nên thường ở mức cao của mỗi khoảng.",
            "en": "Low (~0.5–1.5%) through a specialist transfer service (Wise: 0.52%); higher (~1.6–4%) when a Vietnamese bank sells the AUD and wires it (Vietcombank, BIDV: 1.4–2.2% over mid-market before fees). AUD trades thinly against VND, so it sits toward the top of each band."
          },
          "source": "https://wise.com/gateway/v1/price?sourceAmount=1000000000&sourceCurrency=VND&targetCurrency=AUD",
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
          "note": "PLACEHOLDER — the inbound (VND→AUD) bands reused for AUD→VND; re-ground on Wise's own AUD→VND price and a Vietnamese bank's own AUD buy rate. Applied to the projected sale price",
          "label": {
            "vi": "Chênh lệch tỷ giá khi chuyển tiền bán nhà về Việt Nam (FX spread)",
            "en": "FX spread on sale proceeds sent back to Vietnam"
          },
          "payer": {
            "vi": "Người bán chịu — nằm trong tỷ giá",
            "en": "The seller bears it — built into the rate"
          },
          "drivers": {
            "vi": "Chỉ phát sinh nếu đưa tiền bán nhà về Việt Nam. Dùng cùng khoảng như chiều vào (tạm tính): dịch vụ chuyên biệt rẻ hơn chuyển khoản ngân hàng.",
            "en": "Only if the proceeds are sent back to Vietnam. The inbound bands are reused as a placeholder: a specialist service costs less than a bank wire."
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

- **No `fills`; bands from providers' own pages.** No regulated figure — each band end names the provider page it is drawn from (Wise's own price, Vietcombank's and BIDV's own rate feeds, 27 Oct 2026) or is PLACEHOLDER; presented with a live-quote caveat, never an asserted exact rate.
- **Single-owner cross-refs.** The selection framework → [`kb.fx-providers.wise-ofx-bank-comparison`](../fx-providers/wise-ofx-bank-comparison.md); the loan-currency boundary → [`kb.fx.loan-currency-considerations`](loan-currency-considerations.md); the VN capital-control process → the VN placeholders. This doc owns only the spread magnitude.
- **Freshness.** Provider pricing moves; `last_verified` is the freshness anchor. The bands are stable structural facts (specialist < bank); the exact numbers within them are indicative.

## Sources

- Wise — own price data for VND→AUD (mid-market rate + 0.52% + 37,155 VND flat) — https://wise.com/gateway/v1/price?sourceAmount=1000000000&sourceCurrency=VND&targetCurrency=AUD
- Wise — *Send money to Vietnam* (mid-market rate + upfront fee; fee discount over AU$40,000) — https://wise.com/au/send-money/send-money-to-vietnam
- Vietcombank — own exchange-rate feed (AUD and USD sell rates, 27 Oct 2026) — https://portal.vietcombank.com.vn/Usercontrols/TVPortal.TyGia/pXML.aspx
- BIDV — own exchange-rate feed (AUD sell rate, 27 Oct 2026) — https://bidv.com.vn/ServicesBIDV/ExchangeDetailServlet
- OFX — *Are there any transfer fees?* (AU$15 under AU$10,000) — https://www.ofx.com/en-au/faqs/are-there-any-transfer-fees/
- OFX — *AUD to VND exchange rate* (the interbank rate shown is not OFX's customer rate — the margin is in the quote) — https://www.ofx.com/en-us/exchange-rates/aud-to-vnd/
- ASIC Moneysmart — *Sending money overseas* (providers choose the exchange rate they use and charge fees; compare both) — https://moneysmart.gov.au/banking/sending-money-overseas
