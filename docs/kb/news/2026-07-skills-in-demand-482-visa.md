---
slug: kb.news.2026-07-skills-in-demand-482-visa
kb_slug: kb.visas.au-temporary-residency-classes
category: visa
affected_kb_slugs:
  - kb.visas.au-temporary-residency-classes
effective_from: 2024-12-07
authored_date: 2026-07-09
sources:
  - url: https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/repealed-visas/temporary-skill-shortage-short-term-visa-subclass-482
    retrieved: 2026-10-09
    note: "PRIMARY (Home Affairs) — \"On December 7 2024, the Skills in Demand (SID) visa replaced the Temporary Skills Shortage (TSS) visa.\""
  - url: https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/skills-in-demand-visa-subclass-482
    retrieved: 2026-10-09
    note: "PRIMARY (Home Affairs) — three streams (Core Skills, Specialist Skills, Labour agreement); stay up to 4 years."
  - url: https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/skills-in-demand-visa-subclass-482/core-skills-stream
    retrieved: 2026-10-09
    note: "PRIMARY (Home Affairs) — work in Australia for up to 4 years, only for the sponsor or an associated entity; if eligible, apply for permanent residence."
  - url: https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/employer-nomination-scheme-186/temporary-residence-transition-stream
    retrieved: 2026-10-09
    note: "PRIMARY (Home Affairs) — subclass 186 Temporary Residence Transition: 2 years eligible sponsored employment in the 3 years before applying."
  - url: https://foreigninvestment.gov.au/guidance/general/key-concepts
    retrieved: 2026-10-09
    note: "PRIMARY (FIRB) — temporary residents are taken to be foreign investors."
  - url: https://foreigninvestment.gov.au/guidance/types-investments/residential-land
    retrieved: 2026-10-09
    note: "PRIMARY (FIRB) — 1 April 2025 to 30 June 2029: foreign investors generally prohibited from purchasing established dwellings."
---

## Headline (EN)

Skills in Demand (482) visa replaced the TSS visa on 7 Dec 2024

## Headline (VI)

Visa Kỹ năng Cần thiết (482) thay thế visa TSS từ 7/12/2024

## Summary (EN)

The employer-sponsored **Skills in Demand (subclass 482)** visa **replaced the Temporary Skill Shortage (TSS) visa** on **7 December 2024**. It has three streams (Core Skills, Specialist Skills, Labour agreement), lets the holder work in Australia for up to **4 years** — for the sponsor, in the nominated occupation — and opens a permanent-residence pathway via subclass 186 after **2 years** of sponsored work. For FIRB purposes nothing changes: a 482 holder is a **temporary resident, so a foreign person**, for as long as they hold it — the established-dwelling ban (1 April 2025 – 30 June 2029) and the FIRB approval requirement still apply. If your plan referenced the old TSS visa, it should now reference the 482.

## Summary (VI)

Visa **Kỹ năng Cần thiết (diện phụ 482)** do chủ lao động bảo lãnh đã **thay thế visa Thiếu hụt Kỹ năng Tạm thời (TSS)** từ ngày **7/12/2024**. Visa này có ba luồng (Kỹ năng Cốt lõi, Kỹ năng Chuyên gia, Thỏa thuận Lao động), cho phép làm việc tại Úc tối đa **4 năm** — cho chủ bảo lãnh, trong ngành nghề được đề cử — và mở lộ trình thường trú qua diện 186 sau **2 năm** làm việc có bảo lãnh. Về mặt FIRB, không có gì thay đổi: người giữ visa 482 là **thường trú tạm thời, tức người nước ngoài**, trong suốt thời gian giữ visa — lệnh cấm mua nhà đã xây (1/4/2025 – 30/6/2029) và yêu cầu phê duyệt FIRB vẫn áp dụng. Nếu kế hoạch của bạn từng tham chiếu visa TSS cũ, nay nên tham chiếu visa 482.

## Diff

```jsonc
{
  "old_value": { "visa_class": "Temporary Skill Shortage (TSS), subclass 482 (pre-reform)" },
  "new_value": { "visa_class": "Skills in Demand, subclass 482", "replaced_from": "2024-12-07", "streams": 3, "max_duration_years": 4, "work_rights": "for the sponsor, in the nominated occupation", "pr_pathway": "subclass 186 TRT, 2 years sponsored employment" }
}
```

Notes:

- **`sources:` re-cited 2026-10-09 to government pages only (behavior 39): the MinterEllison citation is gone; "three salary-based streams" became the three named streams (Labour agreement is not salary-based), "full work rights" became the sponsor-only condition the Home Affairs page states, and the lending-signal sentence — on no government page — was cut.**
- **Dormant for now.** The only blueprint anchoring `kb.visas.au-temporary-residency-classes` is Mode B (`fhb-foreign-au`), not yet in Wedge 1a scope (Mode A only). This is expected — `affected_components` is computed over every blueprint at compile time, so the mapping is ready the instant Mode B activates.
- **Immutable once authored.**
