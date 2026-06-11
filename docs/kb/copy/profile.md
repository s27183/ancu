---
slug: kb.copy.profile
effective_from: 2026-06-01
last_verified: 2026-06-01
---

# Buyer-profile component copy (bilingual)

User-facing copy-templates for the `buyer_profile` resolver (`fh_engine_fill`): the base-turn
`key_constraints` and `key_strengths` narration. At the onboarding turn the deep applicant facts
(income, savings, debts; exact citizenship) are not yet gathered, so the base projection states
one honest constraint (financials pending — the plan refines as the buyer answers) and one
definitional strength (first-home-buyer → full Mode-A scheme access, pending the eligibility
checks). Each template is a `{vi, en}` pair; these two carry no `{param}` placeholders.

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
    }
  }
}
```
