---
slug: kb.copy.ownership-foreign-investor
effective_from: 2026-07-03
last_verified: 2026-07-03
---

# Mode-D foreign-investor ownership-planning component copy (bilingual)

User-facing copy-templates for the Mode-D `ownership_planning_foreign_investor` fill
(`fh_engine_ownership:fill_foreign_investor/2`, blueprint investor-foreign-au.md
component 13): the base-computable, property-agnostic `annual_au_tax_obligations` /
`annual_vn_tax_obligations` prose, and the non-vacancy `alert_triggers_armed` entries (AU
tax filing deadline, VN tax filing deadline, FX repatriation opportunity, PR-grant
mode-switch). The vacancy-fee alert reuses `kb.copy.ownership-foreign`'s existing
`alert_vacancy_*` templates (Mode B's, mode-neutral to the vacancy regime itself); the
periodic loan-review alert reuses `kb.copy.ownership`'s `alert_review_*` (mode-neutral);
`obligation_pm_review` reuses `kb.copy.ownership-investor`'s existing template — no
duplication of an already-owned line.

Each template is a `{vi, en}` pair; these carry no `{param}` placeholders. This is a
**copy doc**: it fills no slot and is not a blueprint anchor (reference-exempt; only
slug==path + content_json-parse gates apply). Vietnamese is authored for register — not a
transliteration of the English (trap #4). Decision-support tone, never advice (ASIC): the
VN-side obligation line points to the buyer's own VN-based tax advisor (the AU-side-full /
VN-side-placeholder scoping decision, mode-d-wedge.md 2026-07-03) — it never states a VN
tax rule.

## Rules

Everything above is `content_md`. The `copy` block below is this doc's `content_json` —
template ids the resolver references, each a `{vi, en}` pair.

```jsonc
{
  "fills": [],
  "copy": {
    "obligation_au_tax_return": {
      "vi": "Nộp tờ khai thuế thu nhập tại Úc hằng năm cho khoản thu nhập cho thuê (người không cư trú thuế khai theo hình thức đánh giá, không phải khấu trừ tại nguồn).",
      "en": "Lodge an annual Australian tax return for the rental income (a non-resident is taxed by assessment, not a final withholding)."
    },
    "obligation_land_tax_foreign_surcharge": {
      "vi": "Thuế đất hằng năm áp dụng, cộng thêm phụ phí dành cho chủ sở hữu nước ngoài/vắng mặt tùy theo tiểu bang.",
      "en": "Annual land tax applies, plus the foreign/absentee-owner surcharge in the relevant state."
    },
    "obligation_vn_tax_filing": {
      "vi": "Nghĩa vụ khai thuế tại Việt Nam đối với thu nhập từ bất động sản ở Úc — nội dung cụ thể chưa được xây dựng đầy đủ; hãy tham khảo ý kiến chuyên viên thuế tại Việt Nam của bạn.",
      "en": "VN-side tax filing on the AU-sourced property income — not yet fully built out here; consult your own VN-based tax advisor."
    },
    "alert_au_tax_filing_deadline_trigger": {
      "vi": "Hằng năm, theo hạn khai thuế thu nhập cá nhân của Úc",
      "en": "Annually, by the Australian individual tax-return deadline"
    },
    "alert_au_tax_filing_deadline_action": {
      "vi": "Chuẩn bị hồ sơ (thu nhập cho thuê, chi phí, khấu hao) cho chuyên viên thuế đã đăng ký của bạn.",
      "en": "Prepare records (rental income, expenses, depreciation) for your registered tax agent."
    },
    "alert_vn_tax_filing_deadline_trigger": {
      "vi": "Hằng năm, theo hạn khai thuế tại Việt Nam",
      "en": "Annually, by the Vietnam tax-filing deadline"
    },
    "alert_vn_tax_filing_deadline_action": {
      "vi": "Xác nhận với chuyên viên thuế tại Việt Nam của bạn về nghĩa vụ khai báo thu nhập từ Úc.",
      "en": "Confirm your VN-side filing obligation for the AU-sourced income with your Vietnam-based tax advisor."
    },
    "alert_fx_repatriation_trigger": {
      "vi": "Khi bạn có kế hoạch chuyển tiền thu nhập cho thuê hoặc tiền bán nhà về Việt Nam",
      "en": "When you plan to repatriate rental income or sale proceeds to Vietnam"
    },
    "alert_fx_repatriation_action": {
      "vi": "So sánh nhà cung cấp chuyển tiền được cấp phép (Wise, OFX, ngân hàng) trước khi chuyển — không dùng kênh không chính thức.",
      "en": "Compare licensed transfer providers (Wise, OFX, bank) before transferring — never an informal channel."
    },
    "alert_pr_mode_switch_trigger": {
      "vi": "Khi bạn được cấp thường trú nhân (PR) hoặc quốc tịch Úc",
      "en": "On being granted Australian permanent residency or citizenship"
    },
    "alert_pr_mode_switch_action": {
      "vi": "Kế hoạch sẽ chuyển sang chế độ nhà đầu tư trong nước — mở khóa chiết khấu 50% thuế lãi vốn cho các khoản lãi trong tương lai và không cần phê duyệt FIRB cho lần mua tiếp theo.",
      "en": "The plan switches to the domestic-investor mode — unlocking the 50% CGT discount on future gains and no FIRB approval for your next purchase."
    }
  }
}
```
