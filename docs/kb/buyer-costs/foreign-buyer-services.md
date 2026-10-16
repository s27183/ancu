---
slug: kb.buyer-costs.foreign-buyer-services
effective_from: 2026-10-16
last_verified: 2026-10-16
sources:
  - url: https://www.naati.com.au/resources/dfat-translation-requirements/
    retrieved: 2026-10-16
    path: docs/sources/foreign-buyer/naati-dfat-translation-requirements.txt
    quotes:
      - "a translation submitted to DFAT must include the Translator’s NAATI stamp (either physical or digital) clearly showing:"
      - "From 1 July 2018, DFAT is only able to accept translations completed by translators with NAATI certification"
  - url: https://translayte.com/certified-translations/naati-translator
    retrieved: 2026-10-16
    path: docs/sources/foreign-buyer/translayte-naati-translation.txt
    quotes:
      - "Our NAATI translation prices start from A$59.00 per page."
  - url: https://australiantranslationservices.com.au/languages/naati-vietnamese-translator/
    retrieved: 2026-10-16
    path: docs/sources/foreign-buyer/ats-naati-vietnamese.txt
    quotes:
      - "NAATI-Certified Vietnamese Translations from AU $60/Page (No GST Applicable)"
  - url: https://birthcertificatetranslation.com.au/vietnamese-birth-certificate-translation-naati/
    retrieved: 2026-10-16
    path: docs/sources/foreign-buyer/bct-vietnamese-naati.txt
    quotes:
      - "Vietnamese birth certificate translation for as low as $79 AUD?"
  - url: https://lawhandbook.sa.gov.au/ch26s04s08.php
    retrieved: 2026-10-16
    path: docs/sources/foreign-buyer/sa-law-handbook-jp.txt
    quotes:
      - "Their services are provided free of charge . Notaries public also witness legal documents but mainly documents that are for use in foreign courts or by foreign authorities. Notaries public can charge for their services."
  - url: https://www.notarypublichub.com.au/pricing
    retrieved: 2026-10-16
    path: docs/sources/foreign-buyer/notary-public-hub-pricing.txt
    quotes:
      - "Certified copy (up to 5 pages) per document Compare original with copy, issue notarial certificate and bind (up to 5 pages) Ex GST (online) $212.50 $250.00 Inc GST (online) $233.75 $275.00"
  - url: https://mynotary.com.au/
    retrieved: 2026-10-16
    path: docs/sources/foreign-buyer/mynotary-fees.txt
    quotes:
      - "Certifying two to five individual copy documents (of up to five pages each) under one notarial certificate $185"
  - url: https://www.fogartyoliverandrothschild.com.au/insights/conveyancing-fees-melbourne
    retrieved: 2026-10-16
    path: docs/sources/foreign-buyer/fogarty-conveyancing-fees-melbourne.txt
    quotes:
      - "$660 — Standard residential sale or purchase, no complexity"
      - "$990 — Multi-title properties, FIRB transactions, restrictive covenant analysis"
  - url: https://skyvia.com.au/posts/firb-foreign-buyer-guide/
    retrieved: 2026-10-16
    path: docs/sources/foreign-buyer/skyvia-firb-foreign-buyer-guide.txt
    quotes:
      - "很多人选择让律师代为提交 FIRB 申请，费用大约 $1,000-$3,000（律师服务费，不含 FIRB 申请费本身）"
---

# Foreign-buyer services — certified translation, document certification, FIRB application help

A buyer based in Vietnam (Modes B and D) pays for a few services a domestic buyer never needs: **NAATI-certified translation** of Vietnamese documents into English, **certification** of copies (a JP in Australia, or a notary for documents used overseas), and — optionally — a **lawyer or adviser to prepare the FIRB application**. None of these has a regulated price; each is a provider's quote. This doc owns the **typical ranges** so the plan can place each one as its own line before the buyer has a quote. The **FIRB government application fee itself** is regulated and owned by [`kb.firb.fee-schedule-current`](../firb/fee-schedule-current.md) — it is not one of these lines.

## Certified translation (NAATI)

An Australian government agency, court or lender expects a document in Vietnamese (birth or marriage certificate, bank statements, income evidence, a gift letter from a parent) to be translated by a **NAATI-certified translator**. NAATI is the national standards and certification body; a certified translation carries the translator's NAATI stamp (physical or digital) showing their practitioner ID, language and certification type, name, date and signature. DFAT accepts only translations by NAATI-certified translators.

Published per-page prices for Vietnamese → English certified translation start at about **$59–$79 per page**. A typical foreign-buyer document set is **3 to 6 single-page documents**, so the plan places **~$180–$475** in total. More pages, multi-page bank statements, or an urgent turnaround push it higher.

## Certifying copies — JP or notary

- **In Australia, a Justice of the Peace certifies true copies free of charge.** That covers most copies an Australian agency or lender asks for.
- **A notary public** charges for documents that will be used overseas, or where a notarial certificate is required. Published prices run about **$185 for 2–5 copy documents under one certificate** (the Victorian notaries' benchmark scale, ex GST) to **$275 incl. GST per certified copy** (a NSW notary's online rate).

So the plan places **$0–$275**: $0 when a JP's certification is enough, up to one notarial sitting when it is not.

## FIRB application help (optional)

The buyer can lodge the FIRB application themselves; many hire a lawyer or adviser to prepare it. Published pricing is thin. A Melbourne law firm prices a FIRB purchase at **$990** fixed against **$660** for a standard purchase, so FIRB work adds about **$330** when the conveyancing lawyer handles it in-house. A foreign-buyer guide puts a lawyer's fee to prepare the application at **about $1,000–$3,000** (excluding the government fee). The plan places **$330–$3,000** and marks the line optional.

## Relevance for buyers based in Vietnam (Modes B, D)

- **Small lines, but certain ones.** Translation and certification are near-certain for a Vietnam-based buyer. Showing them as lines stops them surprising the buyer during the loan application.
- **The FIRB government fee is separate and much larger.** It is regulated and placed from [`kb.firb.fee-schedule-current`](../firb/fee-schedule-current.md). This doc covers only the optional professional help.
- **Information, not advice.** The ranges describe the market; the plan names no translator, notary or law firm.

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **reference doc**: it fills no slot. Each line below becomes one cash event for the foreign modes (behavior 83).

```jsonc
{
  "fills": [],
  "parameters": {
    "naati_translation_per_page_low":  { "type": "money", "value": 59, "note": "CONVENTION — published NAATI-certified translation price per page, lower end" },
    "naati_translation_per_page_high": { "type": "money", "value": 79, "note": "CONVENTION — published Vietnamese NAATI translation price per page, upper end" },
    "typical_document_pages_low":  { "type": "integer", "value": 3, "note": "ASSUMPTION — a minimal foreign-buyer set (ID/birth certificate, one income or funds document, one gift or relationship document)" },
    "typical_document_pages_high": { "type": "integer", "value": 6, "note": "ASSUMPTION — a fuller set (marriage certificate, several statements)" },
    "firb_government_fee_owner": { "type": "string", "value": "kb.firb.fee-schedule-current", "note": "OWNED ELSEWHERE — the regulated FIRB application fee; not a fee line here" }
  },
  "lookup": {
    "fee_lines": {
      "note": "one entry per fee the buyer cannot know until they hire someone or get a quote; the engine emits one cash event per applicable entry (behavior 83)",
      "entries": [
        {
          "id": "document_translation",
          "phase": "prepare",
          "timing": "one_off",
          "tier": "CONVENTION",
          "basis": "fixed",
          "low": 180, "high": 475,
          "applies": { "modes": ["fhb-foreign-au", "investor-foreign-au"], "states": "all", "property": "any" },
          "optional": false,
          "note": "per-page prices $59–$79 (published) × a typical 3–6 page document set",
          "label":   { "vi": "Dịch thuật công chứng NAATI (tiếng Việt → tiếng Anh)", "en": "NAATI-certified translation (Vietnamese → English)" },
          "payer":   { "vi": "Người mua trả", "en": "The buyer pays" },
          "drivers": { "vi": "Số trang cần dịch (giấy khai sinh, giấy đăng ký kết hôn, sao kê ngân hàng, thư tặng tiền), độ phức tạp và yêu cầu làm gấp. Giá niêm yết khoảng $59–$79 mỗi trang.", "en": "How many pages need translating (birth or marriage certificate, bank statements, a gift letter), their complexity and turnaround. Published prices are about $59–$79 a page." },
          "source":  "https://translayte.com/certified-translations/naati-translator"
        },
        {
          "id": "document_certification",
          "phase": "prepare",
          "timing": "one_off",
          "tier": "CONVENTION",
          "basis": "fixed",
          "low": 0, "high": 275,
          "applies": { "modes": ["fhb-foreign-au", "investor-foreign-au"], "states": "all", "property": "any" },
          "optional": false,
          "label":   { "vi": "Chứng thực bản sao (JP hoặc công chứng viên – notary)", "en": "Certifying copies (JP or notary public)" },
          "payer":   { "vi": "Người mua trả", "en": "The buyer pays" },
          "drivers": { "vi": "JP (Justice of the Peace) ở Úc chứng thực bản sao miễn phí. Chỉ tốn tiền khi cần công chứng viên (notary) — giấy tờ dùng ở nước ngoài hoặc cần chứng nhận công chứng: khoảng $185–$275 một lần.", "en": "A Justice of the Peace in Australia certifies copies free. It costs money only when a notary is needed — documents for use overseas or needing a notarial certificate: about $185–$275 a sitting." },
          "source":  "https://www.notarypublichub.com.au/pricing"
        },
        {
          "id": "firb_application_help",
          "phase": "prepare",
          "timing": "one_off",
          "tier": "CONVENTION",
          "basis": "fixed",
          "low": 330, "high": 3000,
          "applies": { "modes": ["fhb-foreign-au", "investor-foreign-au"], "states": "all", "property": "any" },
          "optional": true,
          "note": "low = a law firm's published FIRB premium over its standard purchase fee ($990 − $660); high = a foreign-buyer guide's $1,000–$3,000 lawyer fee. Few firms publish a FIRB-only price — re-ground when two do",
          "label":   { "vi": "Phí luật sư/tư vấn chuẩn bị hồ sơ FIRB (không gồm lệ phí FIRB)", "en": "Help preparing the FIRB application (not the FIRB fee)" },
          "payer":   { "vi": "Người mua trả — không bắt buộc, có thể tự nộp", "en": "The buyer pays — optional; the buyer can lodge it themselves" },
          "drivers": { "vi": "Rẻ nhất khi luật sư làm thủ tục mua nhà (conveyancing) xử lý luôn FIRB; đắt hơn khi thuê riêng, khi mua qua công ty/quỹ tín thác (trust) hoặc hồ sơ phức tạp.", "en": "Lowest when the conveyancing lawyer handles FIRB in-house; higher when hired separately, or when buying through a company or trust, or the case is complex." },
          "source":  "https://skyvia.com.au/posts/firb-foreign-buyer-guide/"
        }
      ]
    }
  }
}
```

Notes:

- **No `fills`.** Each line is a cash event the engine emits for Modes B and D; no outcome leaf is set.
- **CONVENTION, never regulated.** Translators, notaries and lawyers set their own prices. The plan shows a range and the buyer's quote replaces it.
- **The translation band is derived.** Published per-page prices × an assumed 3–6 page set (the `typical_document_pages_*` parameters); the derivation is stated so a re-ground can redo it.
- **FIRB help is thinly sourced.** Only one firm publishes a FIRB-specific price, and one guide gives the $1,000–$3,000 range. Re-ground when two providers publish a FIRB-only fixed fee.
- **Single owner.** The FIRB government fee → `kb.firb.fee-schedule-current`; the money transfer from Vietnam → `kb.fx.typical-spreads-vnd-aud`.

## Sources

- NAATI — *DFAT requirements for translators* (what a certified translator's stamp shows; DFAT accepts only NAATI-certified translations) — https://www.naati.com.au/resources/dfat-translation-requirements/
- Published NAATI translation prices — https://translayte.com/certified-translations/naati-translator ; https://australiantranslationservices.com.au/languages/naati-vietnamese-translator/ ; https://birthcertificatetranslation.com.au/vietnamese-birth-certificate-translation-naati/
- Law Handbook (SA Government) — *Justices of the Peace* (JP services are free; notaries can charge) — https://lawhandbook.sa.gov.au/ch26s04s08.php
- Published notary prices — https://www.notarypublichub.com.au/pricing ; https://mynotary.com.au/ (Society of Notaries of Victoria benchmark scale)
- FIRB application help — https://www.fogartyoliverandrothschild.com.au/insights/conveyancing-fees-melbourne ; https://skyvia.com.au/posts/firb-foreign-buyer-guide/
