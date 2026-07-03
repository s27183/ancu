---
slug: kb.copy.ownership-foreign
effective_from: 2026-07-03
last_verified: 2026-07-03
---

# Foreign-person ownership-planning component copy (bilingual)

User-facing copy-templates for the Mode-B foreign-person `ownership_planning` fill
(`fh_engine_ownership:fill_foreign/2`, blueprint fhb-foreign-au.md component 11): the
vacancy-fee `alert_triggers_armed` entry (the annual FIRB vacancy-fee declaration
reminder, kb.firb.vacancy-fee-rules-2026's lodgement trap — non-lodgement makes the fee
payable regardless of actual occupancy). The periodic loan-review alert is SHARED with
Mode A/C (`kb.copy.ownership`'s `alert_review_trigger`/`alert_review_action`, mode-neutral
— no edit needed here).

Each template is a `{vi, en}` pair, `{param}` placeholders filled via
`fh_engine_i18n:subst/2`. This is a **copy doc**: it fills no slot and is not a blueprint
anchor (reference-exempt; only slug==path + content_json-parse gates apply). Vietnamese
is authored for register — not a transliteration of the English (trap #4).
Decision-support tone, never advice (ASIC): the reminder states the regime and the
lodgement trap, never a specific compliance verdict for the buyer's situation.

## Rules

Everything above is `content_md`. The `copy` block below is this doc's `content_json` —
template ids the resolver references, each a `{vi, en}` pair.

```jsonc
{
  "fills": [],
  "copy": {
    "alert_vacancy_trigger": {
      "vi": "Hằng năm, trong vòng 30 ngày sau khi kết thúc năm cư trú (vacancy year)",
      "en": "Annually, within 30 days of the end of each vacancy year"
    },
    "alert_vacancy_action": {
      "vi": "Nộp tờ khai phí bỏ trống (vacancy fee return) cho FIRB dù bạn ở hay cho thuê nhà — KHÔNG nộp tờ khai đúng hạn sẽ khiến bạn phải nộp phí này dù đã ở đủ 183 ngày. Phí ước tính ({amount}) gấp đôi lệ phí xin FIRB kể từ 9/4/2024.",
      "en": "Lodge the annual vacancy fee return with FIRB whether you live in or rent out the property — NOT lodging on time makes the fee payable even if you occupied it for the full 183 days. The at-risk figure ({amount}) is double the FIRB application fee, since 9 Apr 2024."
    },
    "alert_vacancy_action_amount_pending": {
      "vi": "Nộp tờ khai phí bỏ trống (vacancy fee return) cho FIRB dù bạn ở hay cho thuê nhà — KHÔNG nộp tờ khai đúng hạn sẽ khiến bạn phải nộp phí này dù đã ở đủ 183 ngày. Số tiền cụ thể sẽ hiện ra khi biết mức lệ phí FIRB của bạn.",
      "en": "Lodge the annual vacancy fee return with FIRB whether you live in or rent out the property — NOT lodging on time makes the fee payable even if you occupied it for the full 183 days. The specific amount fills in once your FIRB fee is known."
    }
  }
}
```
