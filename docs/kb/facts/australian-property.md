---
slug: kb.facts.australian-property
effective_from: 2026-10-09
last_verified: 2026-10-09
sources:
  - url: https://www.abs.gov.au/statistics/economy/price-indexes-and-inflation/total-value-dwellings/jun-quarter-2026/643202.xlsx
    retrieved: 2026-10-07
    path: docs/sources/abs/643202-total-value-dwellings-jun-qtr-2026-table2.xlsx
    note: "ABS 6432.0 Total Value of Dwellings, June Quarter 2026, Table 2 — capital-city median prices. The figures are owned by kb.property.capital-growth-bands (its derivation table); the facts below quote that doc."
  - url: https://www.abs.gov.au/statistics/people/population/national-state-and-territory-population/latest-release
    retrieved: 2026-10-09
    path: docs/sources/abs/national-state-territory-population-mar-qtr-2026.txt
    note: "ABS National, state and territory population, March 2026 (released 17/09/2026) — Key statistics."
  - url: https://www.abs.gov.au/statistics/people/housing/housing-census/2021
    retrieved: 2026-10-09
    path: docs/sources/abs/housing-census-2021.txt
    note: "ABS Housing: Census, 2021 (released 28/06/2022) — tenure of occupied private dwellings."
---

# Why property in Australia — facts for the first-visit sheet

The figures the first-visit sheet draws in its "Why Australian property" section (behavior 42). Each fact quotes its primary; the compiler checks every quote (GATE 12). The 20-year price figures are **owned by kb.property.capital-growth-bands** — the facts here quote its derivation table (`"owner"`), so the two can never disagree. Past growth is shown as history, never as a forecast (the plan's projections use the 3–6% band that doc owns).

## Facts

```jsonc
{
  "title": {"en": "Why property in Australia", "vi": "Vì sao chọn bất động sản Úc"},
  "facts": [
    {
      "id": "capital_city_house_prices_20y",
      "visual": "growth",
      "unit": "aud_k",
      "headline": {"en": "House prices in every capital city at least doubled in 20 years",
                   "vi": "Giá nhà ở mọi thủ phủ tăng ít nhất gấp đôi sau 20 năm"},
      "caption": {"en": "Median established-house price, June 2006 → June 2026 ($'000)",
                  "vi": "Giá nhà trung vị, 6/2006 → 6/2026 (nghìn AUD)"},
      "as_of": "2026-06",
      "source": 0,
      "owner": "kb.property.capital-growth-bands",
      "items": [
        {"label": "Sydney", "from": 495.0, "value": 1487.6},
        {"label": "Brisbane", "from": 330.0, "value": 1155.0, "highlight": true},
        {"label": "Perth", "from": 415.0, "value": 1010.0},
        {"label": "Adelaide", "from": 286.0, "value": 975.0},
        {"label": "Melbourne", "from": 345.0, "value": 850.0}
      ],
      "quotes": ["| Sydney    | 495.0 → 1,487.6 |", "| Brisbane  | 330.0 → 1,155.0 |", "| Perth     | 415.0 → 1,010.0 |",
                 "| Adelaide  | 286.0 → 975.0   |", "| Melbourne | 345.0 → 850.0   |"]
    },
    {
      "id": "population_growth",
      "visual": "figure",
      "unit": "people",
      "value": 392700,
      "headline": {"en": "Australia grew by 392,700 people in a year — 1.4%",
                   "vi": "Dân số Úc tăng 392.700 người trong một năm — 1,4%"},
      "caption": {"en": "27,921,150 people at 31 March 2026; 292,100 of the growth came from overseas migration",
                  "vi": "27.921.150 người vào 31/3/2026; 292.100 người trong số tăng thêm đến từ di cư"},
      "as_of": "2026-03",
      "source": 1,
      "quotes": ["Australia’s population was 27,921,150 people at 31 March 2026",
                 "The annual growth was 392,700 people (1.4%)",
                 "net overseas migration was 292,100"]
    },
    {
      "id": "home_ownership",
      "visual": "split",
      "unit": "pct",
      "headline": {"en": "Two in three Australian homes are owned by the people living in them",
                   "vi": "Hai phần ba số nhà ở Úc do chính người ở sở hữu"},
      "caption": {"en": "Occupied private dwellings by tenure, Census 2021",
                  "vi": "Nhà ở có người ở theo hình thức sở hữu, Điều tra dân số 2021"},
      "as_of": "2021-08",
      "source": 2,
      "items": [
        {"label": {"en": "Owned outright", "vi": "Sở hữu hoàn toàn"}, "value": 31, "highlight": true},
        {"label": {"en": "Owned with a mortgage", "vi": "Sở hữu có thế chấp"}, "value": 35, "highlight": true},
        {"label": {"en": "Rented", "vi": "Thuê"}, "value": 30.6},
        {"label": {"en": "Other / not stated", "vi": "Khác / không ghi"}, "value": 3.4}
      ],
      "quotes": ["31 per cent are owned outright, 35 per cent are owned with a mortgage and 30.6 per cent are rented",
                 "remaining 3.4 per cent"]
    }
  ]
}
```
