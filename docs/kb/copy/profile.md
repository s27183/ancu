---
slug: kb.copy.profile
effective_from: 2026-06-01
last_verified: 2026-10-07
---

# Profile component copy (bilingual)

User-facing copy-templates for the profile resolvers (`fh_engine_fill`): the base-turn
`key_constraints` and `key_strengths` narration for `buyer_profile` (Mode A domestic +
Mode B foreign-person, same component name, dispatched internally), `investor_profile`
(Mode C), and `investor_profile_foreign` (Mode D, distinct component name, same canonical
`profile` outcome type per the 2026-07-03 outcome-type conformance reconciliation). At the
onboarding turn the deep applicant facts (income, savings, debts; exact citizenship;
portfolio) are not yet gathered, so the base projection states one honest constraint
(financials pending — the plan refines as the user answers, mode-neutral and shared across
all four) and one definitional strength per mode: first-home-buyer → full Mode-A scheme
access (`strength_first_home_buyer`); domestic investor → no FIRB / no foreign-buyer
surcharge / resident CGT-discount eligible (`strength_domestic_investor`); Mode-B foreign
person → a structured, FIRB-aware cross-border plan from day one
(`strength_cross_border_family_plan`); Mode-D Vietnam-located investor → FIRB + non-resident
tax + cross-border funding surfaced from day one (`strength_foreign_investor`). Each template
is a `{vi, en}` pair; these carry no `{param}` placeholders.

One `key_assumptions` line, `assume_pr_ordinarily_resident`, is stated by the domestic
profiles (`buyer_profile` Mode A / E, `investor_profile` Mode C) whenever an applicant may be
a permanent resident: onboarding asks "citizen or PR?" but not where the buyer lives, and
`applicant.firb_required = false` for a PR holds only while they are ordinarily resident in
Australia. The line names the assumption and its consequence (a PR living abroad is a foreign
person: approval needed, established dwellings barred) and notes that a citizen needs no
approval wherever they live (FATR reg 35(1)(a)). The law it restates is owned by
[`kb.firb.status-determination`](../firb/status-determination.md); this doc owns only the
wording.

This is a **copy doc**: it fills no slot and is not a blueprint anchor (reference-exempt; only
slug==path + content_json-parse gates apply). Vietnamese is authored for register — not a
transliteration of the English (trap #4). Decision-support tone, never advice (ASIC): the
strength names scheme *access*, not a recommendation.

## Rules

Everything above is `content_md`. The `copy` block below is this doc's `content_json` —
template ids the resolver references, each a `{vi, en}` pair.

```jsonc
{
  "fills": [],
  "copy": {
    "constraint_financials_pending": {
      "vi": "Thông tin tài chính của bạn (thu nhập, tiền tiết kiệm, các khoản nợ) chưa có — kế hoạch sẽ được hoàn thiện dần khi bạn cung cấp thêm.",
      "en": "Applicant financial details (income, savings, debts) pending — the base plan refines as you answer."
    },
    "assume_pr_ordinarily_resident": {
      "vi": "Kế hoạch này giả định rằng thường trú nhân (PR) trong hồ sơ đang sinh sống tại Úc — có mặt ở Úc từ 200 ngày trở lên trong 12 tháng qua. Nếu một thường trú nhân đang sống ở nước ngoài, người đó bị coi là người nước ngoài theo quy định FIRB: phải xin phê duyệt FIRB trước khi mua và không được mua nhà đã qua sử dụng (chỉ được mua nhà xây mới hoặc đất trống). Công dân Úc thì không cần phê duyệt, dù đang sống ở đâu.",
      "en": "This plan assumes any permanent resident on it lives in Australia — in Australia for 200 or more days of the past 12 months. A permanent resident living overseas is a foreign person under FIRB rules: they need FIRB approval before buying and cannot buy an established home (new builds or vacant land only). Australian citizens need no approval wherever they live."
    },
    "strength_first_home_buyer": {
      "vi": "Người mua nhà lần đầu — đủ điều kiện tiếp cận đầy đủ các chương trình hỗ trợ thuộc nhóm A (còn chờ kiểm tra điều kiện chi tiết).",
      "en": "First home buyer — full Mode A scheme access (pending eligibility checks)."
    },
    "strength_domestic_investor": {
      "vi": "Nhà đầu tư trong nước (công dân/thường trú nhân) — không cần phê duyệt FIRB hay phụ phí dành cho người mua nước ngoài, và đủ điều kiện hưởng chiết khấu thuế lãi vốn (CGT) dành cho cư dân (còn chờ kiểm tra chi tiết).",
      "en": "Domestic investor (citizen/PR) — no FIRB approval or foreign-buyer surcharge, and resident CGT-discount eligible (pending detailed checks)."
    },
    "strength_cross_border_family_plan": {
      "vi": "Mua nhà có tài trợ tài chính xuyên biên giới từ gia đình — các yêu cầu FIRB, kế hoạch tài trợ và chi phí dành cho người nước ngoài được xác định rõ ngay từ đầu (còn chờ thông tin chi tiết).",
      "en": "Cross-border family-funded purchase — FIRB requirements, the funding plan, and foreign-buyer costs surfaced from day one (pending detailed checks)."
    },
    "strength_foreign_investor": {
      "vi": "Nhà đầu tư tại Việt Nam — kế hoạch tuân thủ FIRB, thuế không cư trú và chuyển tiền xuyên biên giới được xác định rõ ngay từ đầu (còn chờ thông tin chi tiết).",
      "en": "Vietnam-located investor — FIRB compliance, non-resident tax, and cross-border funding surfaced from day one (pending detailed checks)."
    }
  }
}
```
