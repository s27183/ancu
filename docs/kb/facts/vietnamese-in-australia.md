---
slug: kb.facts.vietnamese-in-australia
effective_from: 2026-10-09
last_verified: 2026-10-09
sources:
  - url: https://www.homeaffairs.gov.au/research-and-statistics/statistics/country-profiles/profiles/vietnam
    retrieved: 2026-10-09
    path: docs/sources/homeaffairs/country-profile-vietnam-2026-10-09.txt
    note: "Department of Home Affairs, Country profile – Vietnam: population (ABS, Australia's Population by Country of Birth, June 2024), Table 2 temporary visa grants, Table 4 geographic distribution (Census 2021)."
---

# Vietnamese in Australia — facts for /facts and the first-visit sheet

The figures of the "Người Việt tại Úc" / "Vietnamese in Australia" section: the Vietnam-born community, where it lives and the student visas granted to Vietnamese nationals, from the Home Affairs country profile (source 0). Each fact quotes the archived primary it comes from; the compiler checks every quote against that file (GATE 12). The buying figures (FIRB approvals, the ATO register) are kb.facts.vietnamese-buyers' since behavior 163.

## Facts

```jsonc
{
  "title": {"en": "Vietnamese in Australia", "vi": "Người Việt tại Úc"},
  "facts": [
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
      "source": 0,
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
      "source": 0,
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
      "source": 0,
      "quotes": ["Student 9,243 18,814 15,436 12,251", "Working Holiday Maker 1,945 3,986 3,605 4,288",
                 "Visitor 25,167 113,592 105,810 59,816"]
    }
  ]
}
```
