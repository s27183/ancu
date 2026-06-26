---
slug: kb.copy.due-diligence
effective_from: 2026-06-01
last_verified: 2026-06-26
---

# due_diligence component copy (bilingual)

User-facing copy-templates for the `due_diligence` investor-variant resolver half
(`fh_engine_due_diligence`): the bilingual **names + why-lines of the investor document procurement
checklist** (the documents an investor must gather — rental appraisal, depreciation quote, lease,
rental history), the **due-diligence actions before signing**, the **questions to ask the vendor /
agent**, the **yield-below-thesis concern** detail, and the honest `next_action_for_user` that asks
the user to upload the documents to complete the assessment. Each template is a `{vi, en}` pair; no
placeholders (the computable thesis flag is a resolver figure, never copy).

This is a **copy doc**: it fills no slot and is not a blueprint anchor's data source
(reference-exempt; only slug==path + content_json-parse + the bilingual copy gate apply,
[[kb-doc-authoring]]). Vietnamese is authored for register, not transliterated from the English
(trap #4). Tone is **information / decision-support, never advice** — the checklist names documents
to obtain and questions to ask; the buyer is directed to their conveyancer, property manager and
quantity surveyor. The factual authority for *what* an investor procures is
`kb.investor.rental-appraisal-from-pm-agent`, `kb.investor.depreciation-report-quantity-surveyor`
and `kb.investor.tenancy-in-situ-considerations`; these strings restate it in both languages.

## Rules

Everything above is `content_md`. The `copy` block below is this doc's `content_json` — template
ids the resolver references, each a `{vi, en}` pair.

```jsonc
{
  "fills": [],
  "copy": {
    "doc_rental_appraisal": {
      "vi": "Thư định giá tiền thuê từ công ty quản lý",
      "en": "Rental appraisal from a property manager"
    },
    "doc_rental_appraisal_why": {
      "vi": "Để xác minh độc lập mức tiền thuê dự kiến, làm cơ sở cho dòng tiền và lợi suất.",
      "en": "To independently verify the expected rent that underpins your cash flow and yield."
    },
    "doc_depreciation_quote": {
      "vi": "Báo giá lịch khấu hao từ chuyên viên định lượng (quantity surveyor)",
      "en": "Depreciation schedule quote from a quantity surveyor"
    },
    "doc_depreciation_quote_why": {
      "vi": "Để ước tính khoản khấu hao công trình và thiết bị có thể khai khi quyết toán thuế.",
      "en": "To estimate the building and fixtures depreciation you can claim at tax time."
    },
    "doc_lease": {
      "vi": "Hợp đồng thuê hiện tại (nếu đang có người thuê)",
      "en": "Current lease (if the property is tenanted)"
    },
    "doc_lease_why": {
      "vi": "Hợp đồng thuê có thời hạn ràng buộc người mua — bạn cần biết tiền thuê, ngày kết thúc và tiền đặt cọc.",
      "en": "A fixed-term lease binds the buyer — you need the rent, end date and bond before signing."
    },
    "doc_rental_history": {
      "vi": "Lịch sử cho thuê hai năm gần nhất",
      "en": "Rental history for the last two years"
    },
    "doc_rental_history_why": {
      "vi": "Để đánh giá tỷ lệ trống và mức tiền thuê thực tế so với dự kiến.",
      "en": "To assess the vacancy pattern and the rent actually achieved versus the estimate."
    },
    "act_rental_appraisal": {
      "vi": "Lấy thư định giá tiền thuê độc lập từ một công ty quản lý tại địa phương để kiểm chứng mức thuê dự kiến.",
      "en": "Obtain an independent rental appraisal from a local property manager to verify the expected rent."
    },
    "act_depreciation_estimate": {
      "vi": "Đặt một chuyên viên định lượng ước tính khấu hao để xác nhận khoản khấu hao có thể khai.",
      "en": "Commission a quantity surveyor's depreciation estimate to confirm the claimable depreciation."
    },
    "act_review_building_pest": {
      "vi": "Nhờ rà soát báo cáo kiểm tra công trình và mối mọt trước khi hết thời gian cân nhắc (cooling-off).",
      "en": "Have a building & pest inspection report reviewed before the cooling-off period ends."
    },
    "act_confirm_tenancy": {
      "vi": "Nếu đang có người thuê, xác nhận điều khoản hợp đồng, tiền thuê hiện tại và tiền đặt cọc trước khi ký.",
      "en": "If tenanted, confirm the lease terms, current rent and bond before signing."
    },
    "q_tenanted": {
      "vi": "Tài sản hiện có người thuê không, và theo điều khoản nào (tiền thuê, ngày kết thúc hợp đồng, tiền cọc)?",
      "en": "Is the property currently tenanted, and on what terms (rent, lease end date, bond)?"
    },
    "q_current_rent": {
      "vi": "Tiền thuê hàng tuần hiện tại là bao nhiêu, và được điều chỉnh lần gần nhất khi nào?",
      "en": "What is the current weekly rent, and when was it last reviewed?"
    },
    "q_rental_history": {
      "vi": "Lịch sử cho thuê và tỷ lệ trống trong hai năm qua như thế nào?",
      "en": "What is the rental and vacancy history over the last two years?"
    },
    "q_strata_levies": {
      "vi": "Có khoản phí đặc biệt, lỗi công trình hay công việc sắp tới nào do ban quản trị (body corporate) ghi nhận không?",
      "en": "Are there any special levies, defects or upcoming works recorded by the body corporate?"
    },
    "concern_yield_below_thesis": {
      "vi": "Lợi suất cho thuê ước tính thấp hơn mục tiêu trong chiến lược của bạn — hãy cân nhắc xem mức giá này có còn phù hợp với luận điểm đầu tư hay không.",
      "en": "The estimated rental yield is below your strategy's target — consider whether this price still meets your investment thesis."
    },
    "next_action": {
      "vi": "Tải lên thư định giá tiền thuê, báo giá khấu hao và (nếu đang cho thuê) hợp đồng thuê để hoàn tất phần thẩm định.",
      "en": "Upload the rental appraisal, depreciation quote and (if tenanted) the lease to complete your due-diligence assessment."
    }
  }
}
```
