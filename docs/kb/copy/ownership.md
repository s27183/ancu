---
slug: kb.copy.ownership
effective_from: 2026-06-01
last_verified: 2026-06-01
---

# Ownership-planning component copy (bilingual)

User-facing copy-templates for the `ownership_planning` resolver half
(`fh_engine_ownership`): the recurring-cost `notes` and the lifecycle `alert_triggers_armed`
(FHG graduation window, the periodic rate review, the land-tax mode-switch). Each alert is a
`{trigger, action}` pair of free-text prose, so both halves are `{vi, en}`. Each template is
filled via `fh_engine_i18n:subst/2`.

Params are all **scalars** (same in both languages, §3b/§4): `{lvr}` the graduation LVR
threshold (a percent), `{cadence}` the review interval in months, `{state}` a state code,
`{threshold}` the land-tax threshold the resolver pre-formats with `fh_engine_money:money/1`.

This is a **copy doc**: it fills no slot and is not a blueprint anchor (reference-exempt;
only slug==path + content_json-parse gates apply). Vietnamese is authored for register —
not a transliteration of the English (trap #4). Decision-support tone, never advice (ASIC).

## Rules

Everything above is `content_md`. The `copy` block below is this doc's `content_json` —
template ids the resolver references, each a `{vi, en}` pair.

```jsonc
{
  "fills": [],
  "copy": {
    "note_indicative": {
      "vi": "Đây là khoảng ước tính hằng năm cho một căn nhà ở khu vực đô thị; con số chính thức nằm trên thông báo thuế/phí (rates notice) của bạn và (nếu là chung cư) bản công bố thông tin (disclosure statement).",
      "en": "Indicative annual ranges for a metro home; the binding figures are your rates notice and (if strata) the disclosure statement."
    },
    "note_mortgage_pending": {
      "vi": "Khoản trả nợ vay và tổng chi phí hằng tháng sẽ được tính khi bạn xác định số tiền vay và lãi suất.",
      "en": "Mortgage repayments and the all-in monthly total fill in once your loan amount and rate are set."
    },
    "alert_fhg_trigger": {
      "vi": "Tỷ lệ vay trên giá trị (LVR) của bạn giảm xuống dưới 80%",
      "en": "Your loan-to-value ratio drops below 80%"
    },
    "alert_fhg_action": {
      "vi": "Chương trình First Home Guarantee sẽ kết thúc khi LVR đạt {lvr}% mà bạn không phải trả thêm gì, đồng thời mở ra cơ hội tái cấp vốn không cần bảo hiểm LMI — chúng tôi sẽ nhắc bạn.",
      "en": "The First Home Guarantee falls away at {lvr}% LVR with nothing to repay, and a no-LMI refinance window opens — we will flag it."
    },
    "alert_review_trigger": {
      "vi": "Mỗi {cadence} tháng",
      "en": "Every {cadence} months"
    },
    "alert_review_action": {
      "vi": "Hãy so sánh lãi suất của bạn với thị trường; xin ngân hàng hiện tại điều chỉnh lãi suất thường rẻ hơn là chuyển sang ngân hàng khác.",
      "en": "Review your rate against the market; a same-lender reprice is often cheaper than switching."
    },
    "alert_landtax_trigger": {
      "vi": "Bạn dọn ra ngoài và cho thuê căn nhà này",
      "en": "You move out and rent this home"
    },
    "alert_landtax_action": {
      "vi": "Căn nhà không còn là nơi ở chính của bạn, nên quyền miễn thuế đất chấm dứt và thuế đất có thể áp dụng khi vượt ngưỡng của tiểu bang {state} ({threshold}).",
      "en": "It stops being your principal residence, so the land-tax exemption ends and land tax can apply above the {state} threshold ({threshold})."
    }
  }
}
```
