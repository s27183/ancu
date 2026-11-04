---
slug: kb.facts.capital-cities
effective_from: 2026-11-04
last_verified: 2026-11-04
sources:
  - url: https://www.abs.gov.au/statistics/people/population/regional-population/latest-release
    retrieved: 2026-11-04
    path: docs/sources/abs/regional-population-2024-25.txt
    note: "ABS Regional population, 2024-25 financial year (released 31/03/2026) — Population change by capital city (Greater Capital City Statistical Areas), ERP at 30 June 2025."
  - url: https://www.abs.gov.au/statistics/economy/price-indexes-and-inflation/total-value-dwellings/jun-quarter-2026/643202.xlsx
    retrieved: 2026-10-07
    path: docs/sources/abs/643202-total-value-dwellings-jun-qtr-2026-table2.xlsx
    note: "ABS 6432.0 Total Value of Dwellings, June Quarter 2026, Table 2 — capital-city median prices. The figures are owned by kb.property.capital-growth-bands (its derivation table); the median facts below quote that doc."
---

# The states and their capital cities — facts for /explore's filter and /facts

Behavior 154 (Son 2026-11-04: «in the suburb filter box … some info about each state, ranked by their city's population (Sydney first?)»). Each state's capital city, its population and its median prices. The map's filter ranks the states by the first fact (stateInfo.ts) and shows a chosen state's three figures; /facts draws the three as charts. Items run by population, largest first, in every fact, so the charts read in the filter's order. A capital city is the ABS Greater Capital City Statistical Area. The median prices are **owned by kb.property.capital-growth-bands** and quoted from its derivation table (`"owner"`), so the two can never disagree.

## Facts

```jsonc
{
  "title": {"en": "States and capital cities", "vi": "Các bang và thủ phủ"},
  "facts": [
    {
      "id": "capital_city_population",
      "visual": "bars",
      "unit": "people",
      "headline": {"en": "Sydney and Melbourne are each home to more than 5 million people",
                   "vi": "Sydney và Melbourne mỗi nơi có hơn 5 triệu dân"},
      "caption": {"en": "Population of each state's capital city, 30 June 2025",
                  "vi": "Dân số thủ phủ của từng bang, 30/6/2025"},
      "as_of": "2025-06",
      "source": 0,
      "items": [
        {"label": "Sydney", "value": 5638830},
        {"label": "Melbourne", "value": 5435590},
        {"label": "Brisbane", "value": 2833524},
        {"label": "Perth", "value": 2452765},
        {"label": "Adelaide", "value": 1491015},
        {"label": "Canberra", "value": 484630},
        {"label": "Hobart", "value": 255250},
        {"label": "Darwin", "value": 159284}
      ],
      "quotes": ["Sydney 5,638,830 75,230 1.4", "Melbourne 5,435,590 105,030 2.0", "Brisbane 2,833,524 58,223 2.1", "Perth 2,452,765 58,088 2.4", "Adelaide 1,491,015 18,647 1.3", "Canberra 484,630 6,200 1.3", "Hobart 255,250 542 0.2", "Darwin 159,284 2,719 1.7"]
    },
    {
      "id": "capital_city_house_median",
      "visual": "bars",
      "unit": "aud_k",
      "headline": {"en": "The median house in Sydney sold for $1.49 million",
                   "vi": "Giá nhà riêng trung vị ở Sydney là 1,49 triệu AUD"},
      "caption": {"en": "Median established-house price in each capital city, June quarter 2026 ($'000)",
                  "vi": "Giá nhà riêng trung vị ở từng thủ phủ, quý 6/2026 (nghìn AUD)"},
      "as_of": "2026-06",
      "source": 1,
      "owner": "kb.property.capital-growth-bands",
      "items": [
        {"label": "Sydney", "value": 1487.6},
        {"label": "Melbourne", "value": 850.0},
        {"label": "Brisbane", "value": 1155.0},
        {"label": "Perth", "value": 1010.0},
        {"label": "Adelaide", "value": 975.0},
        {"label": "Canberra", "value": 1030.0},
        {"label": "Hobart", "value": 750.0},
        {"label": "Darwin", "value": 752.5}
      ],
      "quotes": ["| Sydney | 495.0 \u2192 1,487.6 | 5.66% | 390.0 \u2192 840.0 |", "| Melbourne | 345.0 \u2192 850.0 | 4.61% | 306.6 \u2192 590.0 |", "| Brisbane | 330.0 \u2192 1,155.0 | 6.46% | 295.0 \u2192 830.1 |", "| Perth | 415.0 \u2192 1,010.0 | 4.55% | 332.5 \u2192 730.0 |", "| Adelaide | 286.0 \u2192 975.0 | 6.32% | 235.0 \u2192 725.0 |", "| Canberra | 399.5 \u2192 1,030.0 | 4.85% | 325.0 \u2192 615.0 |", "| Hobart | 270.0 \u2192 750.0 | 5.24% | 229.0 \u2192 600.0 |", "| Darwin | 349.5 \u2192 752.5 | 3.91% | 245.0 \u2192 445.5 |"]
    },
    {
      "id": "capital_city_attached_median",
      "visual": "bars",
      "unit": "aud_k",
      "headline": {"en": "An apartment or townhouse costs less than a house in every capital city",
                   "vi": "Ở mọi thủ phủ, căn hộ hay nhà liền kề rẻ hơn nhà riêng"},
      "caption": {"en": "Median attached-dwelling price (apartments, townhouses) in each capital city, June quarter 2026 ($'000)",
                  "vi": "Giá trung vị căn hộ và nhà liền kề ở từng thủ phủ, quý 6/2026 (nghìn AUD)"},
      "as_of": "2026-06",
      "source": 1,
      "owner": "kb.property.capital-growth-bands",
      "items": [
        {"label": "Sydney", "value": 840.0},
        {"label": "Melbourne", "value": 590.0},
        {"label": "Brisbane", "value": 830.1},
        {"label": "Perth", "value": 730.0},
        {"label": "Adelaide", "value": 725.0},
        {"label": "Canberra", "value": 615.0},
        {"label": "Hobart", "value": 600.0},
        {"label": "Darwin", "value": 445.5}
      ],
      "quotes": ["| Sydney | 495.0 \u2192 1,487.6 | 5.66% | 390.0 \u2192 840.0 |", "| Melbourne | 345.0 \u2192 850.0 | 4.61% | 306.6 \u2192 590.0 |", "| Brisbane | 330.0 \u2192 1,155.0 | 6.46% | 295.0 \u2192 830.1 |", "| Perth | 415.0 \u2192 1,010.0 | 4.55% | 332.5 \u2192 730.0 |", "| Adelaide | 286.0 \u2192 975.0 | 6.32% | 235.0 \u2192 725.0 |", "| Canberra | 399.5 \u2192 1,030.0 | 4.85% | 325.0 \u2192 615.0 |", "| Hobart | 270.0 \u2192 750.0 | 5.24% | 229.0 \u2192 600.0 |", "| Darwin | 349.5 \u2192 752.5 | 3.91% | 245.0 \u2192 445.5 |"]
    }
  ]
}
```
