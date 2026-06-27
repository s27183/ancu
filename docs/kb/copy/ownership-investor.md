---
slug: kb.copy.ownership-investor
effective_from: 2026-06-25
last_verified: 2026-06-25
---

# Investor ownership-planning component copy (bilingual)

User-facing copy-templates for the `ownership_planning_investor` resolver half
(`fh_engine_ownership:fill_investor/2`): the base `annual_tax_obligations` list and the
investor lifecycle `alert_triggers_armed` (rent review, refinance/equity review, depreciation
schedule refresh, land-tax aggregation). Each obligation is a single prose line; each alert is
a `{trigger, action}` pair — all `{vi, en}`, each filled via `fh_engine_i18n:subst/2`.

The cadences are **qualitative**, not month-numbered: the owning KB docs
(`kb.investor.portfolio-review-cadence`, `kb.investor.scale-up-using-equity`) frame review
intervals as *a default, not a deadline* and *remind, not instruct*. The specific intervals
(`refi_review_cadence_months`, `valuation_review_cadence_months`, `ready_for_next_property_at_lvr`)
live as the component's editable parameters, not baked into this reminder copy. The obligation +
alert templates are static prose; the one exception is the per-property opportunity-card action
`opportunity_equity_release_action`, which substitutes `{horizon}` (the hold horizon `H`) via
`fh_engine_i18n:subst/2`.

The `opportunity_equity_release_action` copy is the `action` of the `equity_release` opportunity
(`opportunities[]`, the opportunity-card surface, §11.9 `{ kind, modeled_benefit, action }`): a
per-property, figure-bearing opportunity surfaced when `disposition` projects a releasable-equity
band at the hold horizon. Its `modeled_benefit` (the projected releasable equity) is a
resolver-computed money band, not copy — only the `action` prose lives here. Projection-not-promise,
decision-support tone (ASIC: information; serviceability is the real ceiling, named in the copy).

Grounding: obligations ← `kb.investor.annual-tax-return-investor` (lodge/declare/records) +
`kb.investor.land-tax-aggregation` (annual assessment) + `kb.investor.property-management-vs-self-managed`
(annual PM review); alerts ← `kb.investor.portfolio-review-cadence` + `kb.investor.scale-up-using-equity`
(rent/refi review) + `kb.investor.annual-tax-return-investor` (depreciation) +
`kb.investor.land-tax-aggregation` (aggregation warning).

This is a **copy doc**: it fills no slot and is not a blueprint anchor (reference-exempt;
only slug==path + content_json-parse + bilingual-copy gates apply). Vietnamese is authored for
register — not a transliteration of the English (trap #4). Decision-support tone, never advice
(ASIC/TPB line: a registered tax agent prepares the return; figures are informational).

## Rules

Everything above is `content_md`. The `copy` block below is this doc's `content_json` —
template ids the resolver references, each a `{vi, en}` pair.

```jsonc
{
  "fills": [],
  "copy": {
    "obligation_tax_return": {
      "vi": "Nộp tờ khai thuế hằng năm, khai thu nhập cho thuê và yêu cầu khấu trừ các chi phí (hạn 31 tháng 10, hoặc trễ hơn nếu dùng đại lý thuế có đăng ký).",
      "en": "Lodge an annual tax return declaring the rental income and claiming the deductible expenses (by 31 October, or later through a registered tax agent)."
    },
    "obligation_depreciation_schedule": {
      "vi": "Duy trì bảng khấu hao (depreciation schedule) để tiếp tục khai khấu trừ công trình (Div 43) và thiết bị (Div 40).",
      "en": "Keep a depreciation schedule current so you keep claiming the Div 43 capital-works and Div 40 plant deductions."
    },
    "obligation_land_tax_assessment": {
      "vi": "Chuẩn bị cho thông báo thuế đất (land tax) hằng năm — thuế đất tính trên tổng giá trị đất bạn sở hữu trong mỗi tiểu bang, không tính riêng từng căn.",
      "en": "Expect an annual land-tax assessment — it is assessed on your total taxable land in each state, not property by property."
    },
    "obligation_pm_review": {
      "vi": "Mỗi năm xem lại đơn vị quản lý cho thuê và mức phí quản lý — phí quản lý là một quyết định ảnh hưởng đến lợi suất.",
      "en": "Review your property manager and the management fee once a year — the fee is a yield decision."
    },
    "obligation_keep_records": {
      "vi": "Lưu giữ chứng từ — sao kê tiền thuê, bảng tổng hợp lãi vay, hoá đơn, và hồ sơ giá gốc (cost base) cho việc tính thuế lãi vốn (CGT) khi bán sau này.",
      "en": "Keep your records — rental statements, the loan-interest summary, invoices, and the cost-base records for the eventual CGT calculation on sale."
    },
    "alert_rent_review_trigger": {
      "vi": "Mỗi năm, vào kỳ gia hạn hợp đồng thuê",
      "en": "Each year, at lease renewal"
    },
    "alert_rent_review_action": {
      "vi": "So sánh tiền thuê với mặt bằng thị trường khu vực để tiền thuê không bị tụt lại sau — đây là nhắc nhở, không phải bắt buộc.",
      "en": "Compare the rent against the local market so it does not fall behind — a reminder, not an instruction."
    },
    "alert_refi_review_trigger": {
      "vi": "Định kỳ (một mốc mặc định, không phải hạn chót)",
      "en": "Periodically (a default cadence, not a deadline)"
    },
    "alert_refi_review_action": {
      "vi": "So sánh khoản vay của bạn với thị trường; tái cấp vốn hoặc rút bớt vốn chủ sở hữu (equity) có thể tạo nguồn đặt cọc cho căn tiếp theo — nhưng khả năng trả nợ (serviceability) mới là trần thật sự.",
      "en": "Review your loan against the market; refinancing or releasing equity can fund the next deposit — but serviceability, not equity, is the real ceiling."
    },
    "alert_depreciation_refresh_trigger": {
      "vi": "Sau khi cải tạo, sửa chữa lớn",
      "en": "After any renovation or major works"
    },
    "alert_depreciation_refresh_action": {
      "vi": "Cập nhật lại bảng khấu hao để phần công trình mới được tính vào khấu trừ Div 43/40.",
      "en": "Refresh the depreciation schedule so the new works count toward the Div 43/40 deductions."
    },
    "alert_land_tax_aggregation_trigger": {
      "vi": "Khi bạn mua thêm một căn trong cùng tiểu bang",
      "en": "When you add a second property in the same state"
    },
    "alert_land_tax_aggregation_action": {
      "vi": "Thuế đất tính trên tổng đất bạn nắm trong tiểu bang — căn thứ hai có thể làm phát sinh thuế đất mà căn đầu chưa chạm tới, và vì biểu thuế luỹ tiến, nâng mức thuế áp lên toàn bộ phần đất bạn sở hữu.",
      "en": "Land tax is assessed on your total land in the state — a second property can trigger land tax the first never reached and, because the scale is progressive, lift the rate across your whole holding."
    },
    "opportunity_equity_release_action": {
      "vi": "Nếu giữ đến năm {horizon}, căn này được dự phóng sẽ tích luỹ phần vốn chủ sở hữu có thể rút ra — bạn có thể tái cấp vốn (tới mức LVR 80%) để tạo nguồn đặt cọc cho căn tiếp theo. Khả năng trả nợ (serviceability), chứ không phải vốn chủ sở hữu, mới là trần thật sự; và đây là dự phóng, không phải cam kết.",
      "en": "Held to year {horizon}, this property is projected to build releasable equity — you could refinance (up to an 80% LVR) to fund the deposit on your next property. Serviceability, not equity, is the real ceiling, and this is a projection, not a promise."
    }
  }
}
```
