---
slug: kb.facts.infrastructure
effective_from: 2026-05-12
last_verified: 2026-10-18
sources:
  - url: https://investment.infrastructure.gov.au/
    retrieved: 2026-10-18
    path: docs/sources/infrastructure/infrastructure-investment-program-2026-10-18.txt
    note: "Infrastructure Investment Program (Australian Government), home page — the 10-year, over $120 billion land transport pipeline."
  - url: https://investment.infrastructure.gov.au/sites/default/files/documents/nsw-state-overview-2026-27-budget.pdf
    retrieved: 2026-10-18
    path: docs/sources/infrastructure/nsw-state-overview-2026-27-budget-2026-10-18.txt
    note: "New South Wales, Infrastructure Investment Program, 2026–27 Budget state overview."
  - url: https://investment.infrastructure.gov.au/sites/default/files/documents/vic-state-overview-2026-27-budget.pdf
    retrieved: 2026-10-18
    path: docs/sources/infrastructure/vic-state-overview-2026-27-budget-2026-10-18.txt
    note: "Victoria, Infrastructure Investment Program, 2026–27 Budget state overview."
  - url: https://investment.infrastructure.gov.au/sites/default/files/documents/qld-state-overview-2026-27-budget.pdf
    retrieved: 2026-10-18
    path: docs/sources/infrastructure/qld-state-overview-2026-27-budget-2026-10-18.txt
    note: "Queensland, Infrastructure Investment Program, 2026–27 Budget state overview."
  - url: https://investment.infrastructure.gov.au/sites/default/files/documents/western-australia-state-overview-2026-27-budget.pdf
    retrieved: 2026-10-18
    path: docs/sources/infrastructure/wa-state-overview-2026-27-budget-2026-10-18.txt
    note: "Western Australia, Infrastructure Investment Program, 2026–27 Budget state overview."
  - url: https://investment.infrastructure.gov.au/sites/default/files/documents/sa-state-overview-2026-27-budget.pdf
    retrieved: 2026-10-18
    path: docs/sources/infrastructure/sa-state-overview-2026-27-budget-2026-10-18.txt
    note: "South Australia, Infrastructure Investment Program, 2026–27 Budget state overview."
  - url: https://investment.infrastructure.gov.au/sites/default/files/documents/tas-state-overview-2026-27-budget.pdf
    retrieved: 2026-10-18
    path: docs/sources/infrastructure/tas-state-overview-2026-27-budget-2026-10-18.txt
    note: "Tasmania, Infrastructure Investment Program, 2026–27 Budget state overview."
  - url: https://investment.infrastructure.gov.au/sites/default/files/documents/act-state-overview-2026-27-budget.pdf
    retrieved: 2026-10-18
    path: docs/sources/infrastructure/act-state-overview-2026-27-budget-2026-10-18.txt
    note: "Australian Capital Territory, Infrastructure Investment Program, 2026–27 Budget state overview."
  - url: https://investment.infrastructure.gov.au/sites/default/files/documents/nt-state-overview-2026-27-budget.pdf
    retrieved: 2026-10-18
    path: docs/sources/infrastructure/nt-state-overview-2026-27-budget-2026-10-18.txt
    note: "Northern Territory, Infrastructure Investment Program, 2026–27 Budget state overview."
---

# Infrastructure — facts for /facts

What the Australian Government has committed to roads and rail (behavior 132; Son 2026-10-18: "Australian infrastructure data (e.g roads, rails, airports ...)"). Every figure is from the Infrastructure Investment Program (IIP), the Commonwealth's land transport program: its home page for the national pipeline, and its eight 2026–27 Budget state overviews (one PDF per state and territory, archived as `pdftotext` reading-order text with the PDF's sha256, because each sets its text in two columns) for each state's ten-year commitment and the Budget's new projects. The figures are the Commonwealth's share only; a state funds its own part of a project on top. `as_of` is 2026-05, the Budget's month; the overviews say "as at the 2026-27 Budget".

Left out: airports, ports and energy (not in this program; no government figure for them was read from the seat — BITRE's pages answered 404/403 on 2026-10-18), Infrastructure Australia's 2026 Infrastructure Priority List (priorities in prose, no figures per state), and projects already funded before this Budget (each overview lists them; the cards keep to totals and the new ones). When the next Budget's overviews are published (usually May), re-fetch all eight, re-archive, and update the figures and quotes together.

## Facts

```jsonc
{
  "title": {"en": "Roads and rail", "vi": "Đường bộ và đường sắt"},
  "facts": [
    {
      "id": "pipeline",
      "visual": "figure",
      "unit": "aud_bn",
      "value": 120,
      "headline": {"en": "Over $120 billion of federal money for roads and rail over 10 years",
                   "vi": "Hơn 120 tỷ AUD tiền liên bang cho đường bộ và đường sắt trong 10 năm"},
      "caption": {"en": "The Australian Government's 10-year land transport pipeline (Infrastructure Investment Program), as at the 2026–27 Budget",
                  "vi": "Chương trình đầu tư giao thông đường bộ và đường sắt 10 năm của Chính phủ Úc (Infrastructure Investment Program), tính đến Ngân sách 2026–27"},
      "as_of": "2026-05",
      "source": [0, 1],
      "quotes": ["The Australian Government is committed to a 10-year, over $120 billion infrastructure investment pipeline, ensuring a rolling program of sustainable land transport infrastructure projects.",
                 "investing over $120 billion over 10 years in the infrastructure investment pipeline."]
    },
    {
      "id": "by_state",
      "visual": "bars",
      "unit": "aud_bn",
      "headline": {"en": "Queensland gets the most: $26.5 billion over 10 years",
                   "vi": "Queensland được nhiều nhất: 26,5 tỷ AUD trong 10 năm"},
      "caption": {"en": "Federal commitment over the next 10 years by state and territory, A$ billion, as at the 2026–27 Budget (ACT: $646 million)",
                  "vi": "Cam kết của liên bang trong 10 năm tới theo bang và vùng lãnh thổ, tỷ AUD, tính đến Ngân sách 2026–27 (ACT: 646 triệu AUD)"},
      "as_of": "2026-05",
      "source": [1, 2, 3, 4, 5, 6, 7, 8],
      "items": [
        {"label": {"en": "Queensland", "vi": "Queensland (thủ phủ Brisbane)"}, "value": 26.5, "highlight": true},
        {"label": {"en": "Victoria", "vi": "Victoria (thủ phủ Melbourne)"}, "value": 21.5},
        {"label": {"en": "New South Wales", "vi": "New South Wales (thủ phủ Sydney)"}, "value": 17.3},
        {"label": {"en": "South Australia", "vi": "Nam Úc (SA)"}, "value": 8.1},
        {"label": {"en": "Western Australia", "vi": "Tây Úc (WA)"}, "value": 6.3},
        {"label": {"en": "Northern Territory", "vi": "Lãnh thổ Bắc Úc (NT)"}, "value": 2.8},
        {"label": {"en": "Tasmania", "vi": "Tasmania (thủ phủ Hobart)"}, "value": 2.2}
      ],
      "note": {"en": "Most of each state's money goes to major road and rail projects (Queensland $24.0 billion, Victoria $19.1 billion, NSW $13.9 billion); the rest to smaller programs such as Roads to Recovery and Black Spot.",
               "vi": "Phần lớn số tiền của mỗi bang dành cho các dự án đường bộ và đường sắt lớn (Queensland 24,0 tỷ AUD, Victoria 19,1 tỷ, NSW 13,9 tỷ); phần còn lại cho các chương trình nhỏ hơn như Roads to Recovery và Black Spot."},
      "note_sources": [3, 2, 1],
      "note_quotes": ["$24.0 billion towards major road and rail projects",
                      "$19.1 billion towards major road and rail projects",
                      "$13.9 billion towards major road and rail projects and $3.4 billion for smaller projects and programs such as the Roads to Recovery, Safer Local Roads and Infrastructure, and Black Spot programs."],
      "quotes": ["Queensland under the IIP over the next 10 years, is $26.5 billion",
                 "Victoria under the IIP, over the next 10 years, is $21.5 billion",
                 "New South Wales under the IIP, over the next 10 years, is $17.3 billion",
                 "South Australia under the IIP, over the next 10 years, is $8.1 billion",
                 "Western Australia under the IIP, over the next 10 years, is $6.3 billion",
                 "Northern Territory under the IIP, over the next 10 years, is $2.8 billion",
                 "Tasmania under the IIP, over the next 10 years, is $2.2 billion",
                 "over the next 10 years, is $646 million"]
    },
    {
      "id": "new_projects",
      "visual": "bars",
      "unit": "aud_m",
      "headline": {"en": "The 2026–27 Budget's biggest new project: $812.5 million for the Bruce Highway",
                   "vi": "Dự án mới lớn nhất trong Ngân sách 2026–27: 812,5 triệu AUD cho Xa lộ Bruce"},
      "caption": {"en": "New projects in the 2026–27 Budget, federal funding, A$ million",
                  "vi": "Các dự án mới trong Ngân sách 2026–27, vốn liên bang, triệu AUD"},
      "as_of": "2026-05",
      "source": [3, 4, 2, 1, 7, 8],
      "items": [
        {"label": {"en": "Bruce Highway, Gateway Motorway to Dohles Rocks Road (QLD)", "vi": "Xa lộ Bruce, đoạn Gateway Motorway – Dohles Rocks Road (QLD)"}, "value": 812.5, "highlight": true},
        {"label": {"en": "Westport, Anketell Road upgrades (WA)", "vi": "Westport, nâng cấp đường Anketell (WA)"}, "value": 552.0},
        {"label": {"en": "Melton Line electrification, development (VIC)", "vi": "Điện khí hóa tuyến tàu Melton, giai đoạn chuẩn bị (VIC)"}, "value": 76.4},
        {"label": {"en": "Sydney to Canberra rail corridor upgrade (NSW)", "vi": "Nâng cấp hành lang đường sắt Sydney – Canberra (NSW)"}, "value": 50.0},
        {"label": {"en": "Western Freeway, Melton to Caroline Springs (VIC)", "vi": "Xa lộ Western, Melton – Caroline Springs (VIC)"}, "value": 50.0},
        {"label": {"en": "Drake Brockman Drive duplication (ACT)", "vi": "Mở rộng đường Drake Brockman Drive (ACT)"}, "value": 50.0},
        {"label": {"en": "M1 safety improvements (NSW)", "vi": "Cải thiện an toàn xa lộ M1 (NSW)"}, "value": 45.0},
        {"label": {"en": "Bagot Road safety and capacity (NT)", "vi": "Nâng cấp an toàn và sức chứa đường Bagot (NT)"}, "value": 24.0}
      ],
      "note": {"en": "Each overview also lists new money for projects already under way.",
               "vi": "Mỗi bản tóm tắt cũng liệt kê khoản tiền mới cho các dự án đang thực hiện."},
      "note_sources": [1],
      "note_quotes": ["Government has committed $95 million to new projects and $300 million to existing projects"],
      "quotes": ["Bruce Highway - Gateway Motorway to Dohles Rocks Road (Stage 2) 812.5",
                 "Westport - Anketell Road Upgrades - Stage 1A and 1B 552.0",
                 "Melton Line Electrification - Development 76.4",
                 "Sydney to Canberra Rail Corridor Upgrade 50.0",
                 "Western Freeway Upgrade (Melton to Caroline Springs) - Preconstruction 50.0",
                 "Drake Brockman Drive Duplication 50.0",
                 "M1 Safety Improvements 45.0",
                 "Bagot Road Safety and Capacity Upgrades 24.0"]
    }
  ]
}
```
