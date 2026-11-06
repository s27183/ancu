---
slug: kb.facts.vietnamese-buyers
effective_from: 2026-10-09
last_verified: 2026-10-09
sources:
  - url: https://foreigninvestment.gov.au/news-and-reports/reports-and-publications/quarterly-report-jan-mar-2026
    retrieved: 2026-10-09
    path: docs/sources/firb/quarterly-report-jan-mar-2026.docx
    note: "Foreign Investment Review Board, Quarterly Report January–March 2026, Table 4 'Top 10 sources of investment by value of approved residential real estate proposals' (number and value, current quarter / previous quarter / 2025-26 YTD / 2024-25 / 2023-24)."
  - url: https://foreigninvestment.gov.au/guidance/general/key-concepts
    retrieved: 2026-10-10
    path: docs/sources/firb/key-concepts-2026-10-10.txt
    note: "Foreign Investment Review Board, Key concepts: a foreign person is 'a person not ordinarily resident in Australia'; ordinarily resident = presence 'not subject to any limitation', e.g. a permanent residence visa — so a temporary-visa holder is a foreign person."
  - url: https://foreigninvestment.gov.au/getting-started/investment-information/residential
    retrieved: 2026-10-10
    path: docs/sources/firb/residential-real-estate-2026-10-10.txt
    note: "Foreign Investment Review Board, Residential real estate: 'When an application is not required' — Australian citizens living abroad, holders of Australian permanent residency visas: No."
  - url: https://www.ato.gov.au/individuals-and-families/investments-and-assets/foreign-resident-investments/foreign-investment-in-australia/register-of-foreign-ownership-of-australian-assets/register-of-foreign-ownership-of-australian-assets-reports/register-of-foreign-ownership-of-australian-assets-2024-25-report/residential-land
    retrieved: 2026-10-13
    path: docs/sources/ato/register-foreign-ownership-residential-land-2024-25.txt
    note: "Australian Taxation Office, Register of Foreign Ownership of Australian Assets 2024–25 report, Residential land (last updated 5 March 2026): Table 9 'Registered interests in residential land – Top 20 countries', held by foreign persons at 30 June 2025; who must register and who is exempt (Australian citizens living offshore, permanent residents)."
---

# Vietnamese demand for Australian homes — facts for /demand and the first-visit sheet

The figures of the "Nhu cầu mua nhà ở Úc của người Việt" / "Vietnamese demand for Australian homes" figures, drawn on their own page /demand from the home's first card (behavior 164, Son 2026-11-06: «a separate card in the main page, on top … we move those facts out of the "Australia in figures" card»; never on /facts) and first in the first-visit sheet (behavior 163: split from kb.facts.vietnamese-in-australia, each figure and source unchanged). Each fact quotes the archived primary it comes from; the compiler checks every quote against that file (GATE 12). FIRB counts are **approved proposals**, not completed purchases: a proposal involving more than one source country is counted against each. They count only **foreign persons** — people who must apply to FIRB: anyone without Australian citizenship or permanent residency, temporary-visa holders in Australia included. A home bought in the name of a citizen or permanent resident (a child funded by family in Vietnam, say) needs no approval and is not in them; both FIRB facts carry that as their `note` (behavior 46, Son 2026-10-10), quoted from sources 1 and 2.

The ATO register fact (behavior 77, Son 2026-10-13) counts homes **held** by foreign persons at 30 June 2025, as registered with the ATO since 1 July 2016 — the same foreign persons FIRB counts, so it carries the same note, quoted from the ATO page (source 3). The ATO says the register is self-registered and not a full stocktake; its country tables are national only (no state, suburb, CBD or dwelling type), and its data.gov.au spreadsheet is live and drifts from the dated report, so the fact cites the report.

Not shown, because no primary supports them (docs/01-market.md §5.6 cites VnExpress / Wikipedia only): "4th largest foreign buyer", the 60/30/10 purchase-purpose split, the 8–10% off-the-plan share. The 8–10% is a developer's sales director speaking at a seminar (VnExpress, 28 April 2025); Son 2026-10-13 asked for a primary, and none states an apartment or CBD share by nationality (FIRB, the ATO register, Revenue NSW, the SRO and the Census searched), so the ATO register fact stands in its place.

## Facts

```jsonc
{
  "title": {"en": "Vietnamese demand for Australian homes", "vi": "Nhu cầu mua nhà ở Úc của người Việt"},
  "facts": [
    {
      "id": "firb_top_sources_quarter",
      "visual": "bars",
      "unit": "count",
      "headline": {"en": "Vietnam is the 3rd largest source of approved foreign home purchases",
                   "vi": "Việt Nam đứng thứ 3 về số hồ sơ mua nhà của người nước ngoài được duyệt"},
      "caption": {"en": "Approved residential real estate proposals, Jan–Mar 2026",
                  "vi": "Hồ sơ bất động sản nhà ở được duyệt, quý 1/2026"},
      "as_of": "2026-03",
      "source": 0,
      "items": [
        {"label": {"en": "China", "vi": "Trung Quốc"}, "value": 156},
        {"label": {"en": "Taiwan", "vi": "Đài Loan"}, "value": 76},
        {"label": {"en": "Vietnam", "vi": "Việt Nam"}, "value": 65, "highlight": true},
        {"label": {"en": "India", "vi": "Ấn Độ"}, "value": 58},
        {"label": {"en": "Hong Kong", "vi": "Hồng Kông"}, "value": 43}
      ],
      "note": {"en": "Counts only buyers who must apply to FIRB: people without Australian citizenship or permanent residency, including Vietnamese on temporary visas in Australia. Homes bought in the name of an Australian citizen or permanent resident — including children funded by family in Vietnam — are not included.",
               "vi": "Chỉ tính người mua phải xin phép FIRB: người không có quốc tịch hay thường trú Úc, kể cả người Việt đang ở Úc bằng visa tạm trú. Nhà đứng tên công dân hoặc thường trú nhân Úc — kể cả con em được gia đình ở Việt Nam gửi tiền mua — không nằm trong con số này."},
      "note_sources": [1, 2],
      "note_quotes": ["a person not ordinarily resident in Australia",
                      "Your continued presence in Australia must not be subject to any limitation.",
                      "For example, you may hold a permanent residence visa.",
                      "Australian citizens living abroad No",
                      "Holders of Australian permanent residency visas No"],
      "quotes": ["China | 156 | 248", "Taiwan | 76 | 111", "Vietnam | 65 | 106", "India | 58 | 61", "Hong Kong, SAR | 43 | 45"]
    },
    {
      "id": "firb_vietnam_by_year",
      "visual": "series",
      "unit": "count",
      "headline": {"en": "Hundreds of Vietnamese home purchases approved every year",
                   "vi": "Hàng trăm hồ sơ mua nhà của người Việt được duyệt mỗi năm"},
      "caption": {"en": "Approved residential proposals from Vietnam, by financial year (2025–26: July–March)",
                  "vi": "Hồ sơ nhà ở từ Việt Nam được duyệt, theo năm tài chính (2025–26: tháng 7 – tháng 3)"},
      "as_of": "2026-03",
      "source": 0,
      "items": [
        {"label": "2023–24", "value": 363},
        {"label": "2024–25", "value": 383},
        {"label": {"en": "2025–26 (9 mo.)", "vi": "2025–26 (9 th.)"}, "value": 237, "partial": true}
      ],
      "note": {"en": "Counts only buyers who must apply to FIRB: people without Australian citizenship or permanent residency, including Vietnamese on temporary visas in Australia. Homes bought in the name of an Australian citizen or permanent resident — including children funded by family in Vietnam — are not included.",
               "vi": "Chỉ tính người mua phải xin phép FIRB: người không có quốc tịch hay thường trú Úc, kể cả người Việt đang ở Úc bằng visa tạm trú. Nhà đứng tên công dân hoặc thường trú nhân Úc — kể cả con em được gia đình ở Việt Nam gửi tiền mua — không nằm trong con số này."},
      "note_sources": [1, 2],
      "note_quotes": ["a person not ordinarily resident in Australia",
                      "Your continued presence in Australia must not be subject to any limitation.",
                      "For example, you may hold a permanent residence visa.",
                      "Australian citizens living abroad No",
                      "Holders of Australian permanent residency visas No"],
      "quotes": ["Vietnam | 65 | 106 | 237 | 383 | 363"]
    },
    {
      "id": "ato_register_top_holders",
      "visual": "bars",
      "unit": "count",
      "headline": {"en": "Vietnam is the 6th largest foreign owner of Australian homes",
                   "vi": "Việt Nam đứng thứ 6 trong số người nước ngoài sở hữu nhà ở Úc"},
      "caption": {"en": "Homes held by foreign persons on the ATO register, 30 June 2025",
                  "vi": "Số nhà do người nước ngoài sở hữu theo sổ đăng ký của Sở Thuế Úc (ATO), 30/6/2025"},
      "as_of": "2025-06",
      "source": 3,
      "items": [
        {"label": {"en": "China", "vi": "Trung Quốc"}, "value": 22272},
        {"label": {"en": "Hong Kong", "vi": "Hồng Kông"}, "value": 3396},
        {"label": "Singapore", "value": 1978},
        {"label": "Malaysia", "value": 1795},
        {"label": {"en": "Japan", "vi": "Nhật Bản"}, "value": 1711},
        {"label": {"en": "Vietnam", "vi": "Việt Nam"}, "value": 1658, "highlight": true}
      ],
      "note": {"en": "Counts only foreign persons, including temporary-visa holders. Homes held by Australian citizens or permanent residents — including children funded by family in Vietnam — are not included.",
               "vi": "Chỉ tính người nước ngoài, kể cả người có visa tạm trú. Nhà do công dân hoặc thường trú nhân Úc sở hữu — kể cả con em được gia đình ở Việt Nam gửi tiền mua — không nằm trong con số này."},
      "note_sources": [3],
      "note_quotes": ["foreign persons (which include temporary residents and entities with foreign ownership of 20% or more)",
                      "Australian citizens living offshore", "permanent residents"],
      "quotes": ["Table 9: Registered interests in residential land – Top 20 countries",
                 "People's Republic of China 22,272", "Hong Kong, SAR 3,396", "Singapore 1,978",
                 "Malaysia 1,795", "Japan 1,711", "Vietnam 1,658"]
    }
  ]
}
```
