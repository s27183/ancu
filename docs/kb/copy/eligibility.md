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

    "benefit_fhg":          { "vi": "Mua nhà với khoản đặt cọc 5% mà không phải trả bảo hiểm thế chấp (LMI).", "en": "Buy with a 5% deposit and no Lenders Mortgage Insurance." },
    "benefit_fhss":         { "vi": "Tích lũy tiền đặt cọc trong quỹ hưu trí và rút ra với ưu đãi thuế.", "en": "Save your deposit inside super and release it tax-effectively." },
    "benefit_help_to_buy":  { "vi": "Chính phủ cùng góp vốn sở hữu, giảm khoản đặt cọc và khoản vay bạn cần.", "en": "The government co-buys an equity share, cutting the deposit and loan you need." },
    "benefit_state_duty":   { "vi": "Miễn hoặc giảm thuế trước bạ chuyển nhượng.", "en": "Full or partial transfer-duty exemption." },
    "benefit_fhog":         { "vi": "Khoản trợ cấp $10,000 cho một căn nhà mới đủ điều kiện.", "en": "A $10,000 grant for an eligible new home." },

    "duty_phase_out":       { "vi": "Mức tiết kiệm cao nhất ở đầu thấp của khoảng giá và giảm dần về 0 khi đến mức trần.", "en": "The saving is largest at the lower end of your price range and tapers to nil at the cap." },
    "lmi_estimate":         { "vi": "Ước tính tham khảo — mức phí LMI chính xác là báo giá của công ty bảo hiểm khi nộp hồ sơ.", "en": "Indicative estimate — the exact LMI premium is the insurer's quote at application." },
    "fhog_if_new_build":    { "vi": "Chỉ áp dụng nếu bạn mua nhà xây mới; $0 đối với nhà đã qua sử dụng.", "en": "Applies only to a new build; $0 for an established home." },
    "total_excludes":       { "vi": "Tổng chưa bao gồm {names} (giá trị tùy theo chi tiết chưa xác định).", "en": "Total excludes {names} (value depends on details not yet known)." },

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
