---
slug: kb.copy.eligibility
effective_from: 2026-06-01
last_verified: 2026-06-01
---

# Eligibility component copy (bilingual)

User-facing copy-templates for the `eligibility` resolver (`fh_engine_eligibility`): the
scheme `notes`, rejection/confirmation `reason`s, status prefixes, and stacking-constraint
notes. Each is a `{vi, en}` pair the resolver fills via `fh_engine_i18n:subst/2`.

Two kinds here (bilingual-content.md §3b):

- **Sentence frames** — whole-sentence templates. `{cap}`/`{max}` are money figures
  (scalar — same in both languages, per the figure/locale boundary); `{a}`/`{b}` are
  scheme names (scalar proper nouns).
- **Label fragments** (`label_*`) — user-facing noun phrases naming an eligibility
  criterion. They are **bilingual params** dropped into the `reject_meets` / `confirm`
  frames; the resolver picks the vi fragment for the vi frame and the en for the en. The
  frames are colon/list-style so a noun phrase reads naturally in both languages.

Copy doc: fills no slot, not a blueprint anchor (reference-exempt). Vietnamese authored for
register, not transliterated (trap #4). Decision-support, never advice (ASIC).

## Rules

Everything above is `content_md`. The `copy` block is this doc's `content_json`.

```jsonc
{
  "fills": [],
  "copy": {
    "status_eligible":     { "vi": "Đủ điều kiện.", "en": "Eligible." },
    "status_conditional":  { "vi": "Có điều kiện.", "en": "Conditionally available." },
    "status_pending":      { "vi": "Có khả năng đủ điều kiện — còn chờ một vài chi tiết.", "en": "Likely eligible — pending a few details." },

    "band_cap_above":  { "vi": "Giới hạn giá bất động sản là {cap}; mức mục tiêu của bạn bắt đầu cao hơn mức đó.", "en": "Property price cap is {cap}; your target starts above it." },
    "band_straddle":   { "vi": "Đủ điều kiện cho bất động sản đến {max}; mức giới hạn chính xác tùy theo khu vực.", "en": "Eligible for properties up to {max}; the exact cap depends on the suburb." },
    "type_new_build":  { "vi": "Áp dụng cho nhà xây mới hoặc mua theo dự án (off-the-plan) đủ điều kiện.", "en": "Available for an eligible new build or off-the-plan purchase." },

    "reject_meets":    { "vi": "Chưa đáp ứng: {label}.", "en": "Does not meet: {label}." },
    "reject_generic":  { "vi": "Chưa đáp ứng các điều kiện đủ tư cách.", "en": "Does not meet the eligibility criteria." },
    "confirm":         { "vi": "Xác nhận {labels} để hoàn tất.", "en": "Confirm {labels} to finalise." },

    "per_applicant_eligible": { "vi": "Được xét theo từng người nộp đơn — mỗi người đủ điều kiện có thể tự thực hiện riêng.", "en": "Assessed per applicant — each eligible person can run their own." },
    "per_applicant_pending":  { "vi": "Xác nhận chưa từng rút khoản First Home Super Saver nào trước đây để hoàn tất.", "en": "Confirm no previous First Home Super Saver release to finalise." },
    "per_applicant_rejected": { "vi": "Không có người nộp đơn nào đáp ứng điều kiện FHSS.", "en": "No applicant meets the FHSS criteria." },

    "alternatives":    { "vi": "{a} và {b} là các lựa chọn thay thế nhau — chọn một.", "en": "{a} and {b} are alternatives — choose one." },
    "state_not_assessed": { "vi": "Các ưu đãi thuế trước bạ của tiểu bang bạn chưa được đánh giá ở đây — chỉ mới xét các chương trình liên bang.", "en": "State stamp-duty concessions for your state are not yet assessed here — federal schemes only." },

    "label_ownership_history":   { "vi": "lịch sử sở hữu nhà", "en": "ownership history" },
    "label_citizenship":         { "vi": "quốc tịch hoặc thường trú nhân Úc", "en": "Australian citizenship or permanent residency" },
    "label_age":                 { "vi": "từ 18 tuổi trở lên", "en": "age 18 or over" },
    "label_first_home_buyer":    { "vi": "tư cách người mua nhà lần đầu", "en": "first-home-buyer status" },
    "label_owner_occupier":      { "vi": "ý định ở tại căn nhà", "en": "intention to live in the home" },
    "label_no_prior_fhss":       { "vi": "không có lần rút FHSS nào trước đây", "en": "no previous FHSS release" },
    "label_not_currently_owning":{ "vi": "hiện không sở hữu bất động sản nào", "en": "not currently owning property" },
    "label_property_state":      { "vi": "một bất động sản tại tiểu bang của bạn", "en": "a property in your state" },
    "label_generic":             { "vi": "các điều kiện đủ tư cách", "en": "the eligibility details" }
  }
}
```
