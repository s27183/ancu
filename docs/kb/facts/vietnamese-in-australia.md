---
slug: kb.facts.vietnamese-in-australia
effective_from: 2026-10-09
last_verified: 2026-10-09
sources:
  - url: https://foreigninvestment.gov.au/news-and-reports/reports-and-publications/quarterly-report-jan-mar-2026
    retrieved: 2026-10-09
    path: docs/sources/firb/quarterly-report-jan-mar-2026.docx
    note: "Foreign Investment Review Board, Quarterly Report January–March 2026, Table 4 'Top 10 sources of investment by value of approved residential real estate proposals' (number and value, current quarter / previous quarter / 2025-26 YTD / 2024-25 / 2023-24)."
  - url: https://www.homeaffairs.gov.au/research-and-statistics/statistics/country-profiles/profiles/vietnam
    retrieved: 2026-10-09
    path: docs/sources/homeaffairs/country-profile-vietnam-2026-10-09.txt
    note: "Department of Home Affairs, Country profile – Vietnam: population (ABS, Australia's Population by Country of Birth, June 2024), Table 2 temporary visa grants, Table 4 geographic distribution (Census 2021)."
---

# Vietnamese buyers and residents in Australia — facts for the first-visit sheet

The figures the first-visit sheet draws in its "Vietnamese in Australia" section (behavior 42). Each fact quotes the archived primary it comes from; the compiler checks every quote against that file (GATE 12). FIRB counts are **approved proposals**, not completed purchases: a proposal involving more than one source country is counted against each.

Not shown, because no primary supports them (docs/01-market.md §5.6 cites VnExpress / Wikipedia only): "4th largest foreign buyer", the 60/30/10 purchase-purpose split, the 8–10% off-the-plan share.

## Facts

```jsonc
{
  "title": {"en": "Vietnamese buyers in Australia", "vi": "Người Việt mua nhà tại Úc"},
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
      "quotes": ["Vietnam | 65 | 106 | 237 | 383 | 363"]
    },
    {
      "id": "vietnam_born_population",
      "visual": "figure",
      "unit": "people",
      "value": 318760,
      "compare": {"label": {"en": "in 2014", "vi": "năm 2014"}, "value": 228530},
      "headline": {"en": "318,760 Vietnam-born people live in Australia — the 6th largest migrant community",
                   "vi": "318.760 người sinh ra tại Việt Nam đang sống ở Úc — cộng đồng di dân lớn thứ 6"},
      "caption": {"en": "Up 39.5% in ten years (June 2014 → June 2024)",
                  "vi": "Tăng 39,5% trong mười năm (6/2014 → 6/2024)"},
      "as_of": "2024-06",
      "source": 1,
      "quotes": ["318,760 Vietnamese-born people were living in Australia",
                 "39.5% more than the number (228,530) at 30 June 2014",
                 "sixth largest migrant community"]
    },
    {
      "id": "vietnam_born_by_state",
      "visual": "split",
      "unit": "pct",
      "headline": {"en": "Three in four live in New South Wales or Victoria",
                   "vi": "Ba phần tư sống ở New South Wales hoặc Victoria"},
      "caption": {"en": "Where Vietnam-born residents live, Census 2021",
                  "vi": "Nơi cư trú của người sinh ra tại Việt Nam, Điều tra dân số 2021"},
      "as_of": "2021-08",
      "source": 1,
      "items": [
        {"label": "NSW", "value": 38, "highlight": true},
        {"label": "Victoria", "value": 36, "highlight": true},
        {"label": "Queensland", "value": 9},
        {"label": "SA", "value": 7},
        {"label": "WA", "value": 7},
        {"label": {"en": "Other", "vi": "Khác"}, "value": 4, "derived": "Tas 1 + NT 1 + ACT 2"}
      ],
      "quotes": ["Of Vietnamese-born 38 36 9 7 7 1 1 2"]
    },
    {
      "id": "vietnam_student_visas",
      "visual": "figure",
      "unit": "people",
      "value": 12251,
      "headline": {"en": "12,251 student visas granted to Vietnamese nationals in 2024–25",
                   "vi": "12.251 visa du học cấp cho công dân Việt Nam năm 2024–25"},
      "caption": {"en": "Plus 4,288 Working Holiday and 59,816 visitor visas",
                  "vi": "Cùng 4.288 visa Working Holiday và 59.816 visa du lịch"},
      "as_of": "2025-06",
      "source": 1,
      "quotes": ["Student 9,243 18,814 15,436 12,251", "Working Holiday Maker 1,945 3,986 3,605 4,288",
                 "Visitor 25,167 113,592 105,810 59,816"]
    }
  ]
}
```
