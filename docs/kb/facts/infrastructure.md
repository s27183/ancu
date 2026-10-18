---
slug: kb.facts.infrastructure
effective_from: 2026-05-12
last_verified: 2026-10-18
next_edition: 2027-05
next_edition_at: https://investment.infrastructure.gov.au/
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
  - url: https://www.bitre.gov.au/sites/default/files/documents/bitre-yearbook-2025.pdf
    retrieved: 2026-10-18
    path: docs/sources/infrastructure/bitre-yearbook-2025-road-length-2026-10-18.txt
    note: "BITRE, Australian Infrastructure and Transport Statistics Yearbook 2025, Table 4.1a — Australian road length, by type of road."
  - url: https://www.bitre.gov.au/sites/default/files/documents/australian-infrastructure-and-transport-statistics--yearbook-2024--january-2025.pdf
    retrieved: 2026-10-18
    path: docs/sources/infrastructure/bitre-yearbook-2024-intercapital-distances-2026-10-18.txt
    note: "BITRE, Australian Infrastructure and Transport Statistics Yearbook 2024, Table 6.1 — intercapital road distances (the 2025 yearbook has no such table)."
  - url: https://en.wikipedia.org/wiki/Highway_1_(Australia)
    retrieved: 2026-10-18
    path: docs/sources/infrastructure/wikipedia-highway-1-australia-2026-10-18.txt
    kind: reference
    note: "Wikipedia, Highway 1 (Australia) — no government page gives Highway 1's route or length (searched 2026-10-18)."
---

# Infrastructure — facts for /facts

What the Australian Government has committed to roads and rail (behavior 132; Son 2026-10-18: "Australian infrastructure data (e.g roads, rails, airports ...)"). Every figure is from the Infrastructure Investment Program (IIP), the Commonwealth's land transport program: its home page for the national pipeline, and its eight 2026–27 Budget state overviews (one PDF per state and territory, archived as `pdftotext` reading-order text with the PDF's sha256, because each sets its text in two columns) for each state's ten-year commitment and the Budget's new projects. The figures are the Commonwealth's share only; a state funds its own part of a project on top. `as_of` is 2026-05, the Budget's month; the overviews say "as at the 2026-27 Budget".

Left out: airports, ports and energy (not in this program; no government figure for them was read from the seat — BITRE's pages answered 404/403 on 2026-10-18), Infrastructure Australia's 2026 Infrastructure Priority List (priorities in prose, no figures per state), and projects already funded before this Budget (each overview lists them; the cards keep to totals and the new ones). When the next Budget's overviews are published (usually May), re-fetch all eight, re-archive, and update the figures and quotes together.

Behavior 133 (Son 2026-10-18, a friend's questions: "number of highways, longest high ways … a highway connecting all states"): three more cards. BITRE's yearbooks give the length of Australia's paved roads by type (2025 yearbook, 2024 figures) and the road distance between capitals (2024 yearbook; the 2025 one dropped the table). BITRE writes thousands with a space (475 612), so each of those values says it is read off the quoted row (`derived`). Australia keeps no count of its highways: BITRE measures roads by type (undivided, divided, freeway), not by named highway, so "how many highways" is answered by the length card. Whether one highway links every mainland state has no government answer; the Highway 1 card cites Wikipedia, named in GATE 12's FACT_REFERENCE_SOURCES and labelled "not a government source" on the card. Wikipedia's "longest single highway" (Great Northern Highway) is left out: it gives no source for the figure.

## Facts

```jsonc
{
  "title": {"en": "Infrastructure", "vi": "Hạ tầng"},
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
      "caption": {"en": "Federal commitment over the next 10 years by state and territory, A$ billion, as at the 2026–27 Budget",
                  "vi": "Cam kết của liên bang trong 10 năm tới theo bang và vùng lãnh thổ, tỷ AUD, tính đến Ngân sách 2026–27"},
      "as_of": "2026-05",
      "source": [1, 2, 3, 4, 5, 6, 7, 8],
      "items": [
        {"label": {"en": "Queensland", "vi": "Queensland (thủ phủ Brisbane)"}, "value": 26.5, "highlight": true},
        {"label": {"en": "Victoria", "vi": "Victoria (thủ phủ Melbourne)"}, "value": 21.5},
        {"label": {"en": "New South Wales", "vi": "New South Wales (thủ phủ Sydney)"}, "value": 17.3},
        {"label": {"en": "South Australia", "vi": "Nam Úc (SA)"}, "value": 8.1},
        {"label": {"en": "Western Australia", "vi": "Tây Úc (WA)"}, "value": 6.3},
        {"label": {"en": "Northern Territory", "vi": "Lãnh thổ Bắc Úc (NT)"}, "value": 2.8},
        {"label": {"en": "Tasmania", "vi": "Tasmania (thủ phủ Hobart)"}, "value": 2.2},
        {"label": {"en": "ACT ($646 million)", "vi": "Lãnh thổ Thủ đô Úc — ACT (646 triệu AUD)"}, "value": 0.646, "derived": "the overview's $646 million, in billions"}
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
    },
    {
      "id": "road_length",
      "visual": "figure",
      "unit": "km",
      "value": 475612,
      "derived": "Table 4.1a's 2024 row, paved total, written 475 612",
      "headline": {"en": "475,612 km of paved road in 2024, 5,087 km of it freeway",
                   "vi": "475.612 km đường trải nhựa năm 2024, trong đó 5.087 km là đường cao tốc"},
      "caption": {"en": "Australia's paved roads in 2024, all types. Australia counts its roads by length and type (undivided, divided, freeway), not by number of highways.",
                  "vi": "Đường trải nhựa của Úc năm 2024, mọi loại. Úc thống kê đường theo chiều dài và loại đường (không dải phân cách, có dải phân cách, cao tốc), không đếm số xa lộ."},
      "as_of": "2024-12",
      "source": [9],
      "quotes": ["Paved undivided Paved divided Paved freeway Paved total year (excluding freeway) Kilometres",
                 "2024 463 991 6 534 5 087 475 612",
                 "Source: BITRE estimates with reference to HERE 2025, OpenStreetMap database 2025."]
    },
    {
      "id": "capital_distances",
      "visual": "bars",
      "unit": "km",
      "headline": {"en": "Sydney to Perth is 3,934 km by road",
                   "vi": "Từ Sydney đến Perth là 3.934 km đường bộ"},
      "caption": {"en": "Road distance from Sydney to each capital, GPO to GPO by the fastest route, km",
                  "vi": "Khoảng cách đường bộ từ Sydney đến từng thủ phủ, tính từ bưu điện trung tâm theo tuyến nhanh nhất, km"},
      "as_of": "2023-11",
      "source": [10],
      "items": [
        {"label": {"en": "Darwin", "vi": "Darwin (Lãnh thổ Bắc Úc)"}, "value": 3936, "derived": "Table 6.1's Sydney row, written 3 936"},
        {"label": {"en": "Perth", "vi": "Perth (Tây Úc)"}, "value": 3934, "highlight": true, "derived": "Table 6.1's Sydney row, written 3 934"},
        {"label": {"en": "Adelaide", "vi": "Adelaide (Nam Úc)"}, "value": 1375, "derived": "Table 6.1's Sydney row, written 1 375"},
        {"label": {"en": "Brisbane", "vi": "Brisbane (thủ phủ Queensland)"}, "value": 911},
        {"label": {"en": "Melbourne", "vi": "Melbourne (thủ phủ Victoria)"}, "value": 878},
        {"label": {"en": "Canberra", "vi": "Canberra (thủ đô)"}, "value": 287}
      ],
      "note": {"en": "The longest drive between two capitals is Brisbane to Perth, 4,316 km; Perth to Darwin is 3,854 km.",
               "vi": "Quãng đường dài nhất giữa hai thủ phủ là Brisbane – Perth, 4.316 km; Perth – Darwin là 3.854 km."},
      "note_sources": [10],
      "note_quotes": ["Brisbane - - - 2 034 4 316 3 426 1 195",
                      "Perth - - - - - 3 854 3 716"],
      "quotes": ["Sydney Melbourne Brisbane Adelaide Perth Darwin Canberra km",
                 "Sydney - 878 911 1 375 3 934 3 936 287",
                 "Source: Google maps as at 16 November 2023"]
    },
    {
      "id": "highway_1",
      "visual": "statement",
      "headline": {"en": "One highway reaches every mainland state: Highway 1, about 14,500 km around the coast",
                   "vi": "Có một xa lộ đi qua mọi bang trên đất liền: Xa lộ số 1, khoảng 14.500 km quanh bờ biển"},
      "caption": {"en": "Highway 1 is a chain of highways sharing route number 1 that circles the country. It joins every mainland capital except Canberra and reaches every state, plus the Northern Territory; in Tasmania a separate Highway 1 runs from Hobart to Burnie. It is the longest national highway in the world.",
                  "vi": "Xa lộ số 1 là chuỗi các xa lộ cùng mang số hiệu 1, chạy vòng quanh nước Úc. Nó nối mọi thủ phủ trên đất liền trừ Canberra và đi qua mọi bang, cùng Lãnh thổ Bắc Úc; ở Tasmania có một đoạn Xa lộ số 1 riêng từ Hobart đến Burnie. Đây là xa lộ quốc gia dài nhất thế giới."},
      "as_of": "2026-10",
      "source": [11],
      "quotes": ["Highway 1 is a network of highways that circumnavigate the country, joining all mainland capital cities except the national capital, Canberra .",
                 "At a total length of approximately 14,500 kilometres (9,000 miles) , it is the longest national highway in the world",
                 "Highway 1 is the only route to reach across all Australian states, plus the Northern Territory.",
                 "A separate section in Tasmania connects Hobart to Burnie ."]
    }
  ]
}
```
