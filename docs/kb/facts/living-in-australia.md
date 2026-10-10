---
slug: kb.facts.living-in-australia
effective_from: 2026-10-10
last_verified: 2026-10-10
recent_since: 2024-01
sources:
  - url: https://www.abs.gov.au/statistics/people/population/life-expectancy/latest-release
    retrieved: 2026-10-10
    path: docs/sources/abs/life-expectancy-2022-2024.txt
    note: "ABS Life expectancy, 2022–2024 (released 11/11/2025) — key statistics."
  - url: https://www.abs.gov.au/statistics/people/crime-and-justice/crime-victimisation-australia/latest-release
    retrieved: 2026-10-10
    path: docs/sources/abs/crime-victimisation-2024-25.txt
    note: "ABS Crime Victimisation, Australia, 2024–25 (released 25/03/2026) — selected personal crimes."
  - url: https://www.dcceew.gov.au/environment/land/nrs/science/capad/2024
    retrieved: 2026-10-10
    path: docs/sources/dcceew/capad-2024-2026-10-10.txt
    note: "DCCEEW, Collaborative Australian Protected Areas Database (CAPAD) 2024, updated to September 2025."
  - url: https://www.pbs.gov.au/info/healthpro/explanatory-notes/front/fee
    retrieved: 2026-10-10
    path: docs/sources/pbs/fees-2026-10-10.txt
    note: "Pharmaceutical Benefits Scheme, fees and patient contributions — general patient co-payment from 1 January 2026."
  - url: https://www.health.gov.au/topics/medicare/about
    retrieved: 2026-10-10
    path: docs/sources/health/medicare-about-2026-10-10.txt
    note: "Department of Health, About Medicare — what it covers and who is eligible."
  - url: https://www.abs.gov.au/statistics/people/education/schools/latest-release
    retrieved: 2026-10-10
    path: docs/sources/abs/schools-2025.txt
    note: "ABS Schools, 2025 (released 05/03/2026) — key statistics."
  - url: https://www.fairwork.gov.au/pay-and-wages/minimum-wages
    retrieved: 2026-10-10
    path: docs/sources/fairwork/minimum-wages-2026-10-10.txt
    note: "Fair Work Ombudsman, Minimum wages — the National Minimum Wage from 1 July 2026."
---

# Settling in Australia — facts for the first-visit sheet

The figures the first-visit sheet draws in its third section, "Settling in Australia" (behavior 47). Families buy a home in Australia because they mean to live there, so this section shows what living there gives them: long lives, safety, nature, healthcare, schooling and fair pay — one benefit per card. Each fact quotes the archived government primary it comes from (GATE 12), and every figure is from the latest release, dated 2024 or later (`recent_since`, Son 2026-10-10: "select facts that have recent figures"). Where a benefit comes with permanent residency or citizenship, the card says so as a step of settling.

Left out, and why:
- Air quality: the latest national finding is State of the Environment 2021 — older than 2024.
- System statistics (total health spending, the number of schools): they describe the system, not what a family gets from it.
- Free public schooling for residents: no national or state government page found that says who it is free for in a quotable sentence (education.nsw.gov.au enrolment pages speak of citizens and permanent residents enrolling; vic.gov.au says schools "provide students with free instruction" without saying for whom; measured 2026-10-10). The schooling card shows the ABS figures only.

## Facts

```jsonc
{
  "title": {"en": "Settling in Australia", "vi": "An cư ở Úc"},
  "facts": [
    {
      "id": "life_expectancy",
      "visual": "series",
      "unit": "years",
      "headline": {"en": "Australians live long lives",
                   "vi": "Người Úc sống thọ"},
      "caption": {"en": "Life expectancy at birth, 2022–2024",
                  "vi": "Tuổi thọ trung bình tính từ lúc sinh, 2022–2024"},
      "as_of": "2024-12",
      "source": 0,
      "items": [
        {"label": {"en": "Men", "vi": "Nam giới"}, "value": 81.1},
        {"label": {"en": "Women", "vi": "Nữ giới"}, "value": 85.1, "highlight": true}
      ],
      "quotes": ["Life expectancy at birth was 81.1 years for males and 85.1 years for females in 2022 – 2024"]
    },
    {
      "id": "personal_safety",
      "visual": "split",
      "unit": "pct",
      "headline": {"en": "96 in 100 people were not victims of a personal crime in a year",
                   "vi": "96 trên 100 người không bị tội phạm xâm hại trong một năm"},
      "caption": {"en": "People aged 15 and over who experienced a selected personal crime (assault, threatened assault, robbery, sexual assault), 2024–25",
                  "vi": "Người từ 15 tuổi trở lên từng bị một trong các tội xâm hại cá nhân (hành hung, đe dọa hành hung, cướp, xâm hại tình dục), 2024–25"},
      "as_of": "2025-06",
      "source": 1,
      "items": [
        {"label": {"en": "No such crime", "vi": "Không bị xâm hại"}, "value": 96.1, "highlight": true, "derived": "100 − 3.9"},
        {"label": {"en": "Experienced one", "vi": "Từng bị xâm hại"}, "value": 3.9}
      ],
      "quotes": ["In 2024-25, an estimated 3.9% of persons aged 15 years and over (861,400) experienced one or more selected personal crimes"]
    },
    {
      "id": "protected_nature",
      "visual": "series",
      "unit": "pct",
      "headline": {"en": "A quarter of the land and half the seas are protected",
                   "vi": "Một phần tư đất liền và một nửa vùng biển được bảo tồn"},
      "caption": {"en": "Share of Australia covered by protected areas, September 2025",
                  "vi": "Tỷ lệ diện tích nước Úc thuộc khu bảo tồn, tháng 9/2025"},
      "as_of": "2025-09",
      "source": 2,
      "items": [
        {"label": {"en": "Land", "vi": "Đất liền"}, "value": 24.92},
        {"label": {"en": "Waters", "vi": "Vùng biển"}, "value": 52, "highlight": true}
      ],
      "quotes": ["As of September 2025, terrestrial protected areas cover 24.92% of our landmass.",
                 "now covers 52% of Australian waters."]
    },
    {
      "id": "medicine_copay",
      "visual": "figure",
      "unit": "aud",
      "value": 25.00,
      "headline": {"en": "A subsidised prescription costs at most $25",
                   "vi": "Mỗi đơn thuốc được trợ giá tối đa 25 đô"},
      "caption": {"en": "The most a general patient pays for a PBS-listed prescription, from 1 January 2026 (concession card holders: $7.70)",
                  "vi": "Mức tối đa bệnh nhân thông thường trả cho một đơn thuốc trong danh mục PBS, từ 1/1/2026 (người có thẻ ưu đãi: 7,70 đô)"},
      "as_of": "2026-01",
      "source": 3,
      "quotes": ["From 1 January 2026 for PBS prescriptions general patients (those without a concession card) can be charged up to $25.00.",
                 "General $25.00 Concessional $7.70"],
      "note": {"en": "Medicare, Australia's public health insurance, gives access to a wide range of health and hospital services at low or no cost — once you are a permanent resident or citizen (or have applied for permanent residency, with conditions).",
               "vi": "Medicare, bảo hiểm y tế công của Úc, cho khám chữa bệnh và nằm viện với chi phí thấp hoặc miễn phí — khi là thường trú nhân hoặc công dân (hoặc đã nộp đơn thường trú, có điều kiện)."},
      "note_sources": [4],
      "note_quotes": ["Medicare is Australia’s universal health insurance scheme. It guarantees all Australians (and some overseas visitors) access to a wide range of health and hospital services at low or no cost.",
                      "be an Australian or New Zealand citizen",
                      "be an Australian permanent resident",
                      "have applied for permanent residency (some conditions apply)"]
    },
    {
      "id": "school_class_size",
      "visual": "figure",
      "unit": "count",
      "value": 12.8,
      "headline": {"en": "12.8 students for every teacher",
                   "vi": "Cứ 12,8 học sinh có một giáo viên"},
      "caption": {"en": "Students per teaching staff, all schools, 2025 — and 81.3% of students stay on to Year 12",
                  "vi": "Số học sinh trên mỗi giáo viên, mọi trường, 2025 — và 81,3% học sinh học tiếp đến lớp 12"},
      "as_of": "2025-08",
      "source": 5,
      "quotes": ["the average student to teaching staff ratio for all schools was 12.8 students to one teacher.",
                 "the apparent retention rate for full-time students in years 7/8 to 12 was 81.3%"]
    },
    {
      "id": "minimum_wage",
      "visual": "figure",
      "unit": "aud",
      "value": 26.44,
      "headline": {"en": "The minimum wage is $26.44 an hour",
                   "vi": "Lương tối thiểu là 26,44 đô một giờ"},
      "caption": {"en": "National Minimum Wage from 1 July 2026, or $1004.90 a week",
                  "vi": "Lương tối thiểu quốc gia từ 1/7/2026, tức 1.004,90 đô một tuần"},
      "as_of": "2026-07",
      "source": 6,
      "quotes": ["As of 1 July 2026, the National Minimum Wage is $26.44 per hour or $1004.90 per week."]
    }
  ]
}
```
