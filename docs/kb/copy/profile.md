---
slug: kb.copy.profile
effective_from: 2026-06-01
last_verified: 2026-06-01
---

# Profile component copy (bilingual)

User-facing copy-templates for the profile resolvers (`fh_engine_fill`): the base-turn
`key_constraints` and `key_strengths` narration for `buyer_profile` (Mode A domestic +
Mode B foreign-person, same component name, dispatched internally) and `investor_profile`
(Mode C). At the onboarding turn the deep applicant facts (income, savings, debts; exact
citizenship; portfolio) are not yet gathered, so the base projection states one honest
constraint (financials pending — the plan refines as the user answers, mode-neutral and
shared across all three) and one definitional strength per mode: first-home-buyer → full
Mode-A scheme access (`strength_first_home_buyer`); domestic investor → no FIRB / no
foreign-buyer surcharge / resident CGT-discount eligible (`strength_domestic_investor`);
Mode-B foreign person → a structured, FIRB-aware cross-border plan from day one
(`strength_cross_border_family_plan`). Each template is a `{vi, en}` pair; these carry no
`{param}` placeholders.

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
    }
  }
}
```
