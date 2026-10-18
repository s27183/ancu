---
slug: kb.facts.australian-economy
effective_from: 2026-10-18
last_verified: 2026-10-18
recent_since: 2025-01
sources:
  - url: https://www.dfat.gov.au/sites/default/files/aust-cef.pdf
    retrieved: 2026-10-18
    path: docs/sources/dfat/aust-cef-2026-10-18.txt
    note: "DFAT Trade Data Section, Australia country/economy fact sheet (ABS and DFAT-adjusted ABS data, calendar 2025) — key economic indicators, major goods and services exports, principal export destinations."
  - url: https://www.dfat.gov.au/sites/default/files/viet-cef.pdf
    retrieved: 2026-10-18
    path: docs/sources/dfat/viet-cef-2026-10-18.txt
    note: "DFAT Trade Data Section, Vietnam country/economy fact sheet — Australia's goods and services trade with Vietnam, 2025 (DFAT-adjusted ABS data)."
---

# Australia's economy — facts for /facts

The figures the "Kinh tế Úc" / "Australia's economy" section draws on /facts (behavior 124, of 121). Every figure is read off DFAT's two economic fact sheets (the Trade Data Section compiles them from ABS data), archived as `pdftotext -layout` text under docs/sources/dfat/ with the sha256 of the PDF fetched; the compiler checks each quote against that text (GATE 12). The sheets are for calendar 2025, so each fact's `as_of` is 2025-12. DFAT gives GDP in US dollars and trade in Australian dollars; the unit is said in each caption (FACT_UNITS has no currency-in-billions unit, so the figures are drawn as plain numbers). When DFAT republishes the sheets with 2026 data, re-fetch both, re-archive, and update the figures and quotes together.

## Facts

```jsonc
{
  "title": {"en": "Australia's economy", "vi": "Kinh tế Úc"},
  "facts": [
    {
      "id": "gdp",
      "visual": "figure",
      "unit": "usd_bn",
      "decimals": 1,
      "value": 1841.6,
      "compare": {"label": "2024", "now_label": "2025", "value": 1800.7},
      "headline": {"en": "Australia's economy produced US$1,841.6 billion in 2025",
                   "vi": "GDP của Úc năm 2025 đạt 1.841,6 tỷ USD"},
      "caption": {"en": "Nominal GDP, US$ billion, 2025 (2024: 1,800.7)",
                  "vi": "GDP danh nghĩa, tỷ USD, năm 2025 (năm 2024: 1.800,7)"},
      "as_of": "2025-12",
      "source": 0,
      "quotes": ["Nominal GDP Real GDP growth Unemployment Population (USD billions)",
                 "2025 1,841.6 2025 2.0", "2024 1,800.7 2024 1.1"]
    },
    {
      "id": "real_gdp_growth",
      "visual": "figure",
      "unit": "pct",
      "decimals": 1,
      "value": 2.0,
      "compare": {"label": "2024", "now_label": "2025", "value": 1.1},
      "headline": {"en": "The economy grew 2.0% in 2025, after 1.1% in 2024",
                   "vi": "Kinh tế Úc tăng trưởng 2,0% năm 2025, sau 1,1% năm 2024"},
      "caption": {"en": "Real GDP growth, % change on the year before",
                  "vi": "Tăng trưởng GDP thực, % so với năm trước"},
      "as_of": "2025-12",
      "source": 0,
      "quotes": ["Real GDP growth Unemployment Population (USD billions) (% change YOY)",
                 "2025 1,841.6 2025 2.0", "2024 1,800.7 2024 1.1"]
    },
    {
      "id": "unemployment",
      "visual": "figure",
      "unit": "pct",
      "decimals": 1,
      "value": 4.2,
      "compare": {"label": "2024", "now_label": "2025", "value": 4.0},
      "headline": {"en": "4.2% of the labour force was unemployed in 2025",
                   "vi": "Tỷ lệ thất nghiệp năm 2025 là 4,2% lực lượng lao động"},
      "caption": {"en": "Unemployment, % of the labour force (2024: 4.0%)",
                  "vi": "Thất nghiệp, % lực lượng lao động (năm 2024: 4,0%)"},
      "as_of": "2025-12",
      "source": 0,
      "quotes": ["(% change YOY) (% of labour force) (People, millions)",
                 "2025 2.0 2025 4.2 2025 27.7", "2024 1.1 2024 4.0 2024 27.4"]
    },
    {
      "id": "population",
      "visual": "figure",
      "unit": "million",
      "decimals": 1,
      "value": 27.7,
      "compare": {"label": "2024", "now_label": "2025", "value": 27.4},
      "headline": {"en": "27.7 million people lived in Australia in 2025",
                   "vi": "Úc có 27,7 triệu dân năm 2025"},
      "caption": {"en": "Population, millions (2024: 27.4)",
                  "vi": "Dân số, triệu người (năm 2024: 27,4)"},
      "as_of": "2025-12",
      "source": 0,
      "quotes": ["(% of labour force) (People, millions)",
                 "2025 4.2 2025 27.7", "2024 4.0 2024 27.4"]
    },
    {
      "id": "top_exports",
      "visual": "bars",
      "unit": "aud_bn",
      "decimals": 1,
      "headline": {"en": "Iron ore is Australia's largest export, then coal, gas and gold",
                   "vi": "Quặng sắt là mặt hàng xuất khẩu lớn nhất của Úc, rồi đến than, khí đốt và vàng"},
      "caption": {"en": "Largest goods and services exports, 2025 (A$ billion); education of overseas students is fifth",
                  "vi": "Các mặt hàng và dịch vụ xuất khẩu lớn nhất, năm 2025 (tỷ AUD); giáo dục cho du học sinh đứng thứ năm"},
      "as_of": "2025-12",
      "source": 0,
      "items": [
        {"label": {"en": "Iron ore", "vi": "Quặng sắt (iron ore)"}, "value": 121.0, "highlight": true},
        {"label": {"en": "Coal", "vi": "Than đá"}, "value": 64.1},
        {"label": {"en": "Natural gas", "vi": "Khí đốt tự nhiên"}, "value": 59.7},
        {"label": {"en": "Gold", "vi": "Vàng"}, "value": 59.5},
        {"label": {"en": "Education-related travel", "vi": "Giáo dục (du học sinh)"}, "value": 55.0}
      ],
      "quotes": ["Australia's major goods and services trade, 2025 Source: DFAT-adjusted ABS data. Exports A$b",
                 "Iron ore & concentrates 121.0", "Coal 64.1", "Natural gas 59.7", "Gold 59.5",
                 "Education-related travel 55.0"]
    },
    {
      "id": "export_destinations",
      "visual": "bars",
      "unit": "pct",
      "decimals": 1,
      "headline": {"en": "China buys 29.4% of Australia's exports, more than the next four together",
                   "vi": "Trung Quốc mua 29,4% hàng xuất khẩu của Úc, nhiều hơn bốn nước kế tiếp cộng lại"},
      "caption": {"en": "Principal export destinations, share of goods and services exports, 2025",
                  "vi": "Thị trường xuất khẩu chính, tỷ trọng xuất khẩu hàng hóa và dịch vụ, năm 2025"},
      "as_of": "2025-12",
      "source": 0,
      "items": [
        {"label": {"en": "China", "vi": "Trung Quốc"}, "value": 29.4, "highlight": true},
        {"label": {"en": "Japan", "vi": "Nhật Bản"}, "value": 9.8},
        {"label": {"en": "United States", "vi": "Hoa Kỳ"}, "value": 9.0},
        {"label": {"en": "Republic of Korea", "vi": "Hàn Quốc"}, "value": 6.7},
        {"label": {"en": "India", "vi": "Ấn Độ"}, "value": 4.8}
      ],
      "quotes": ["Principal export destinations Principal import sources Destination Share Rank",
                 "China 29.4% 1", "Japan 9.8% 2", "United States 9.0% 3",
                 "Republic of Korea 6.7% 4", "India 4.8% 5"]
    },
    {
      "id": "trade_with_vietnam",
      "visual": "bars",
      "unit": "aud_m",
      "decimals": 1,
      "headline": {"en": "In 2025 Australia bought more from Vietnam than it sold there",
                   "vi": "Năm 2025 Úc nhập từ Việt Nam nhiều hơn xuất sang Việt Nam"},
      "caption": {"en": "Australia's trade with Vietnam, 2025 (A$ million): Vietnam is its 13th-largest export market and 13th-largest import source",
                  "vi": "Thương mại Úc – Việt Nam, năm 2025 (triệu AUD): Việt Nam là thị trường xuất khẩu lớn thứ 13 và nguồn nhập khẩu lớn thứ 13 của Úc"},
      "as_of": "2025-12",
      "source": 1,
      "items": [
        {"label": {"en": "Australia's exports to Vietnam", "vi": "Úc xuất sang Việt Nam"}, "value": 13387.0},
        {"label": {"en": "Australia's imports from Vietnam", "vi": "Úc nhập từ Việt Nam"}, "value": 16575.9, "highlight": true}
      ],
      "quotes": ["Australia's goods and services trade with Vietnam, 2025",
                 "Exports Destination Ranking: 13 Imports Source Ranking: 13",
                 "Total 13,387.0 Total 16,575.9"]
    }
  ]
}
```
