---
slug: kb.facts.visa-charges
effective_from: 2026-07-01
last_verified: 2026-10-18
sources:
  - url: https://www.legislation.gov.au/F1996B03551/2026-07-01/2026-07-01/text/original/pdf/1
    retrieved: 2026-10-18
    path: docs/sources/legislation/migration-regulations-2026-07-01-sch1-2026-10-18.txt
    note: "Migration Regulations 1994, Schedule 1, Compilation No. 288 (1 July 2026) — the charges from 1 July 2026."
  - url: https://www.legislation.gov.au/F1996B03551/2026-06-01/2026-06-01/text/original/pdf/1
    retrieved: 2026-10-18
    path: docs/sources/legislation/migration-regulations-2026-06-01-sch1-2026-10-18.txt
    note: "Migration Regulations 1994, Schedule 1, Compilation No. 287 (1 June 2026) — the charges before 1 July 2026."
  - url: https://immi.homeaffairs.gov.au/visas/getting-a-visa/fees-and-charges/current-visa-pricing
    retrieved: 2026-10-18
    path: docs/sources/homeaffairs/visa-price-list-2026-10-18.txt
    note: "Department of Home Affairs, current visa pricing — the price list behind the page, naming each subclass's base charge."
  - url: https://www.legislation.gov.au/F2026L00874/asmade/2026-06-30/es/original/pdf
    retrieved: 2026-10-18
    path: docs/sources/legislation/migration-amendment-f2026l00874-es-2026-10-18.txt
    note: "Explanatory statement to the amending regulations F2026L00874 — the 25% rise from 1 July 2026, a 2026–27 Budget measure."
---

# Visa application charges — facts for /facts

What the main visas cost to apply for from 1 July 2026 (behavior 125), drawn on /facts as a before → after dumbbell per visa. The figures are the same as the visa-charges news note's table (kb.news.2026-07-visa-application-charges-2026-27, behavior 120) and quote the same archives: each charge is the base application charge of the first instalment — the main applicant's charge, paid when the application is made — "for any other applicant" (not a concessional group), from Schedule 1 of the Migration Regulations 1994 as compiled on 1 June 2026 (before) and 1 July 2026 (from); Home Affairs' price list carries the same new figures and names the subclass each belongs to. The 25% rise, and that a family member applying with you pays a further charge, are the note under each card, quoted from the explanatory statement and the 1 July compilation.

Kept to the visas readers ask about: skilled (189, 190, 491), employer (186, 494), graduate (485), partner and parent. The student visa (behavior 131) is its own card because its rate depends on the passport: item 1222 of each compilation, the ASEAN rate for the countries its subitem (5A) lists (Vietnam among them; in June 2026 that subitem listed only Pacific countries and Timor-Leste, so a Vietnamese student then paid the $2,000 any other applicant paid). The ELICOS and non-award rate ($2,050 whatever the passport) and the family members' charges are left to the student note. Left out: 191 ($505 → $630, a second step after 491), the second instalment, the lower Pacific / Timor-Leste / ASEAN rates — the news note covers them. 189 is its points-tested stream; 186 and 494 their main streams. The 485 charge had already risen on 1 March 2026 (behavior 119), so its "before" is the 1 June 2026 compilation's $4,600.

`news` names the note that explains the rise; GATE 12 checks it is a current news note and /facts links it under the section.

## Facts

```jsonc
{
  "title": {"en": "Visa application charges", "vi": "Phí visa"},
  "news": ["kb.news.2026-07-visa-application-charges-2026-27", "kb.news.2026-07-student-visa-charges-2026-27"],
  "facts": [
    {
      "id": "skilled_employer",
      "visual": "growth",
      "unit": "aud",
      "headline": {"en": "Skilled, graduate and employer visas now cost $5,750 to $6,140 to apply for — 25% more",
                   "vi": "Visa tay nghề, tốt nghiệp và chủ lao động nay tốn $5.750 đến $6.140 khi nộp đơn — tăng 25%"},
      "caption": {"en": "Main applicant's charge, paid when applying: before → from 1 July 2026",
                  "vi": "Phí của người nộp đơn chính, trả khi nộp đơn: trước → từ 1/7/2026"},
      "as_of": "2026-07",
      "source": [0, 1, 2],
      "items": [
        {"label": {"en": "Skilled Independent (189)", "vi": "Tay nghề độc lập (189)"}, "from": 4910, "value": 6135, "highlight": true},
        {"label": {"en": "Skilled Nominated (190)", "vi": "Tay nghề được bang đề cử (190)"}, "from": 4910, "value": 6140},
        {"label": {"en": "Skilled Work Regional (491)", "vi": "Tay nghề vùng regional (491)"}, "from": 4910, "value": 6140},
        {"label": {"en": "Employer Nomination (186)", "vi": "Chủ lao động đề cử (186)"}, "from": 4910, "value": 6140},
        {"label": {"en": "Employer Sponsored Regional (494)", "vi": "Chủ lao động bảo lãnh vùng regional (494)"}, "from": 4910, "value": 6140},
        {"label": {"en": "Temporary Graduate (485)", "vi": "Tốt nghiệp tạm trú (485)"}, "from": 4600, "value": 5750}
      ],
      "note": {"en": "The charge rose by 25% for most visas from 1 July 2026, a 2026–27 Budget measure. Each family member who applies with you pays a further charge.",
               "vi": "Phí đã tăng 25% với hầu hết các loại visa từ 1/7/2026, một biện pháp trong Ngân sách 2026–27. Mỗi thành viên gia đình nộp đơn cùng bạn phải trả thêm một khoản phí."},
      "note_sources": [3, 0],
      "note_quotes": ["a system-wide increase to the first instalment of the VAC by 25 per cent from 1 July 2026",
                      "implement 2026–27 Budget measures relating to the first instalment for visa application charges",
                      "Additional applicant charge is paid by an applicant who claims to be a member of the family unit of another applicant and seeks to combine the application with that applicant’s application."],
      "quotes": ["1137 Skilled—Independent (Permanent) (Class SI)",
                 "(b) for any other applicant: First instalment—Visas in the Points-tested stream etc. Item Component Amount 1 Base application charge $6 135",
                 "(ii) for any other applicant: First instalment Item Component Amount 1 Base application charge $6 140",
                 "(3) Visa application charge—first instalment (payable at the time the application is made): First instalment—Visas in the Points-tested stream etc. Item Component Amount 1 Base application charge $4 910",
                 "1138 Skilled—Nominated (Permanent) (Class SN) (1) Form: The approved form specified by the Minister in a legislative instrument made for this item under subregulation 2.07(5). (2) Visa application charge: (a) first instalment (payable at the time the application is made): First instalment Item Component Amount 1 Base application charge $4 910",
                 "1241 Skilled Work Regional (Provisional) (Class PS) (1) Form: The approved form specified by the Minister in a legislative instrument made for the purposes of this item under subregulation 2.07(5). (2) Visa application charge: (a) first instalment (payable at the time the application is made): First instalment Item Component Amount 1 Base application charge $4 910",
                 "1114B Employer Nomination (Permanent) (Class EN) (1) Form: The approved form specified by the Minister in a legislative instrument made for this item under subregulation 2.07(5). (2) Visa application charge: (a) first instalment (payable at the time the application is made): First instalment Item Component Amount 1 Base application charge $4 910",
                 "1242 Skilled Employer Sponsored Regional (Provisional) (Class PE)",
                 "\"visaSubclassText\":\"Skilled Independent visa (subclass 189) - Points tested stream\",\"streamCode\":\"\",\"streamText\":\"\",\"onShore\":\"No\",\"basePrice\":\"AUD6,135.00\"",
                 "\"visaSubclassText\":\"Skilled Nominated visa (subclass 190)\",\"streamCode\":\"\",\"streamText\":\"\",\"onShore\":\"No\",\"basePrice\":\"AUD6,140.00\"",
                 "\"visaSubclassText\":\"Skilled Work Regional (Provisional) visa (subclass 491)\",\"streamCode\":\"\",\"streamText\":\"\",\"onShore\":\"No\",\"basePrice\":\"AUD6,140.00\"",
                 "\"visaSubclassText\":\"Employer Nomination Scheme visa (subclass 186) - Direct Entry stream\",\"streamCode\":\"\",\"streamText\":\"\",\"onShore\":\"No\",\"basePrice\":\"AUD6,140.00\"",
                 "\"visaSubclassText\":\"Skilled Employer Sponsored Regional (Provisional) visa (subclass 494) - Employer Sponsored stream\",\"streamCode\":\"\",\"streamText\":\"\",\"onShore\":\"No\",\"basePrice\":\"AUD6,140.00\"",
                 "1229 Skilled (Provisional) (Class VC)",
                 "(iv) for any other applicant: First instalment Item Component Amount 1 Base application charge $5 750",
                 "(iv) for any other applicant: First instalment Item Component Amount 1 Base application charge $4 600",
                 "\"visaSubclassText\":\"Temporary Graduate visa (subclass 485) - Post-Higher Education Work stream\",\"streamCode\":\"\",\"streamText\":\"\",\"onShore\":\"No\",\"basePrice\":\"AUD5,750.00\""]
    },
    {
      "id": "partner_parent",
      "visual": "growth",
      "unit": "aud",
      "headline": {"en": "A partner visa now costs $11,710 to apply for — 25% more",
                   "vi": "Visa Partner (vợ/chồng) nay tốn $11.710 khi nộp đơn — tăng 25%"},
      "caption": {"en": "Main applicant's charge, paid when applying: before → from 1 July 2026",
                  "vi": "Phí của người nộp đơn chính, trả khi nộp đơn: trước → từ 1/7/2026"},
      "as_of": "2026-07",
      "source": [0, 1, 2],
      "items": [
        {"label": {"en": "Partner (820/801, 309/100)", "vi": "Vợ/chồng — Partner (820/801, 309/100)"}, "from": 9365, "value": 11710, "highlight": true},
        {"label": {"en": "Parent (103, 804)", "vi": "Cha mẹ — Parent (103, 804)"}, "from": 5280, "value": 6600},
        {"label": {"en": "Contributory Parent (143, 864)", "vi": "Cha mẹ có đóng góp (143, 864)"}, "from": 5040, "value": 6300}
      ],
      "note": {"en": "The charge rose by 25% for most visas from 1 July 2026, a 2026–27 Budget measure. Each family member who applies with you pays a further charge.",
               "vi": "Phí đã tăng 25% với hầu hết các loại visa từ 1/7/2026, một biện pháp trong Ngân sách 2026–27. Mỗi thành viên gia đình nộp đơn cùng bạn phải trả thêm một khoản phí."},
      "note_sources": [3, 0],
      "note_quotes": ["a system-wide increase to the first instalment of the VAC by 25 per cent from 1 July 2026",
                      "implement 2026–27 Budget measures relating to the first instalment for visa application charges",
                      "Additional applicant charge is paid by an applicant who claims to be a member of the family unit of another applicant and seeks to combine the application with that applicant’s application."],
      "quotes": ["1124B Partner (Residence) (Class BS)",
                 "1129 Partner (Migrant) (Class BC)",
                 "(iii) for any other applicant: First instalment Item Component Amount 1 Base application charge $11 710",
                 "(vii) for any other applicant: First instalment Item Component Amount 1 Base application charge $9 365",
                 "1124 Parent (Migrant) (Class AX)",
                 "1124A Aged Parent (Residence) (Class BP)",
                 "(ii) for any other applicant: First instalment Item Component Amount 1 Base application charge $6 600",
                 "1124 Parent (Migrant) (Class AX) (1) Form: The approved form specified by the Minister in a legislative instrument made for this item under subregulation 2.07(5). (2) Visa application charge: (a) first instalment (payable at the time the application is made): First instalment Item Component Amount 1 Base application charge $5 280",
                 "1130 Contributory Parent (Migrant) (Class CA)",
                 "1130A Contributory Aged Parent (Residence) (Class DG)",
                 "(xi) for any other applicant: First instalment Item Component Amount 1 Base application charge $6 300",
                 "(vi) for any other applicant: First instalment Item Component Amount 1 Base application charge $5 040",
                 "\"visaSubclassText\":\"Partner visa (subclass 820/801)\",\"streamCode\":\"\",\"streamText\":\"\",\"onShore\":\"No\",\"basePrice\":\"AUD11,710.00\"",
                 "\"visaSubclassText\":\"Partner (Provisional and Migrant) visa (subclass 309/100)\",\"streamCode\":\"\",\"streamText\":\"\",\"onShore\":\"No\",\"basePrice\":\"AUD11,710.00\"",
                 "\"visaSubclassText\":\"Parent visa (subclass 103)\",\"streamCode\":\"\",\"streamText\":\"\",\"onShore\":\"No\",\"basePrice\":\"AUD6,600.00\"",
                 "\"visaSubclassText\":\"Aged Parent (subclass 804)\",\"streamCode\":\"\",\"streamText\":\"\",\"onShore\":\"No\",\"basePrice\":\"AUD6,600.00\"",
                 "\"visaSubclassText\":\"Contributory Parent visa (subclass 143) - Applicant meets conditions defined in Note 19d2\",\"streamCode\":\"\",\"streamText\":\"\",\"onShore\":\"No\",\"basePrice\":\"AUD6,300.00\"",
                 "\"visaSubclassText\":\"Contributory Aged Parent visa (subclass 864) - any other applicants see note\",\"streamCode\":\"\",\"streamText\":\"\",\"onShore\":\"No\",\"basePrice\":\"AUD6,300.00\""]
    },
    {
      "id": "student",
      "visual": "growth",
      "unit": "aud",
      "headline": {"en": "A student visa now costs $2,500 to apply for — $2,050 with a Vietnamese passport",
                   "vi": "Visa du học nay tốn $2.500 khi nộp đơn — $2.050 nếu mang hộ chiếu Việt Nam"},
      "caption": {"en": "Student visa (500), main applicant's charge, paid when applying: before → from 1 July 2026",
                  "vi": "Visa du học (500), phí của người nộp đơn chính, trả khi nộp đơn: trước → từ 1/7/2026"},
      "as_of": "2026-07",
      "source": [0, 1, 2],
      "items": [
        {"label": {"en": "Vietnamese and other ASEAN passports", "vi": "Hộ chiếu Việt Nam và các nước ASEAN khác"}, "from": 2000, "value": 2050, "highlight": true},
        {"label": {"en": "Most other passports", "vi": "Hầu hết hộ chiếu khác"}, "from": 2000, "value": 2500},
        {"label": {"en": "Pacific Island and Timor-Leste passports", "vi": "Hộ chiếu các quốc đảo Thái Bình Dương và Timor-Leste"}, "from": 730, "value": 745}
      ],
      "note": {"en": "Most students pay 25% more from 1 July 2026; students from ASEAN countries, Vietnam included, were exempted from that rise. Each family member who applies with you pays a further charge.",
               "vi": "Từ 1/7/2026 hầu hết du học sinh trả thêm 25%; du học sinh từ các nước ASEAN, gồm Việt Nam, được miễn mức tăng đó. Mỗi thành viên gia đình nộp đơn cùng bạn phải trả thêm một khoản phí."},
      "note_sources": [3, 0],
      "note_quotes": ["The base application charge component of the first instalment for primary applicants increases from $2,000 to $2,500.",
                      "The Amendment Regulations also exempts Student (Subclass 500) visa applicants from ASEAN countries from the broader increase and maintains current VAC levels.",
                      "Additional applicant charge is paid by an applicant who claims to be a member of the family unit of another applicant and seeks to combine the application with that applicant’s application."],
      "quotes": ["1222 Student (Temporary) (Class TU)",
                 "who holds a valid passport issued by a country specified in subitem (5A): First instalment Item Component Amount 1 Base application charge $2 050",
                 "(i) Thailand; (j) Vietnam.",
                 "(ii) for any other applicant: First instalment Item Component Amount 1 Base application charge $2 500 2 Additional applicant charge for any other applicant who is at least 18 $1 530",
                 "(ii) for any other applicant: First instalment Item Component Amount 1 Base application charge $2 000 2 Additional applicant charge for any other applicant who is at least 18 $1 225",
                 "who holds a valid passport issued by a Pacific-regional country: First instalment Item Component Amount 1 Base application charge $745",
                 "First instalment Item Component Amount 1 Base application charge $730",
                 "(5A) For the purposes of subparagraph (2)(a)(ia), the following countries are specified: (a) Federated States of Micronesia;",
                 "\"visaSubclassText\":\"Student visa (subclass 500) - All other students\",\"streamCode\":\"5133\",\"streamText\":\"All other students\",\"onShore\":\"Yes\",\"basePrice\":\"AUD2,500.00\""]
    }
  ]
}
```
