---
slug: kb.copy.settlement
effective_from: 2026-06-01
last_verified: 2026-06-26
---

# settlement_prep component copy (bilingual)

User-facing copy-templates for the `settlement_prep` resolver half (`fh_engine_settlement`): the
bilingual **names of the standard settlement critical-path milestones**, the **investor-specific
milestone names + why each matters**, the **state-conditional building-insurance timing rule**
(restating `kb.insurance.timing-of-risk-pass` in `{vi,en}` register), the strata-building note, and
the honest `next_action_for_user` that asks the user to supply contract dates to activate the dated
timeline. Each template is a `{vi, en}` pair; no placeholders (the dates themselves are PENDING in
the resolver's honest-partial output and never appear in copy).

This is a **copy doc**: it fills no slot and is not a blueprint anchor's data source (reference-exempt;
only slug==path + content_json-parse + the bilingual copy gate apply, [[kb-doc-authoring]]). Vietnamese
is authored for register, not transliterated from the English (trap #4). Tone is **information /
process, never advice** — settlement milestones and the statutory insurance-timing rule are stated as
fact; the buyer is directed to their conveyancer, lender and insurer.

The factual authority for the insurance rule is `kb.insurance.timing-of-risk-pass`
(`risk_passing_by_state`); these strings restate the per-state `buyer_insures_from` in both languages.
The milestone sequence's factual authority is `kb.settlement.process-by-state`.

## Rules

Everything above is `content_md`. The `copy` block below is this doc's `content_json` — template
ids the resolver references, each a `{vi, en}` pair.

```jsonc
{
  "fills": [],
  "copy": {
    "mil_contract_signed": {
      "vi": "Ký hợp đồng",
      "en": "Contract signed"
    },
    "mil_deposit_paid_to_trust": {
      "vi": "Đặt cọc vào tài khoản tín thác",
      "en": "Deposit paid to trust account"
    },
    "mil_building_pest_satisfactory": {
      "vi": "Kiểm tra công trình và mối mọt đạt yêu cầu",
      "en": "Building & pest inspection satisfactory"
    },
    "mil_finance_approval_unconditional": {
      "vi": "Khoản vay được duyệt vô điều kiện",
      "en": "Finance approved unconditionally"
    },
    "mil_loan_documents_signed": {
      "vi": "Ký hồ sơ vay",
      "en": "Loan documents signed"
    },
    "mil_insurance_bound": {
      "vi": "Mua bảo hiểm công trình",
      "en": "Building insurance bound"
    },
    "mil_settlement_funds_released": {
      "vi": "Giải ngân vốn thanh toán",
      "en": "Settlement funds released"
    },
    "mil_title_registered": {
      "vi": "Đăng ký quyền sở hữu",
      "en": "Title registered"
    },
    "mil_keys_received": {
      "vi": "Nhận chìa khóa",
      "en": "Keys received"
    },
    "inv_entity_setup": {
      "vi": "Hoàn tất thiết lập pháp nhân",
      "en": "Entity setup completed"
    },
    "inv_entity_setup_why": {
      "vi": "Nếu mua qua công ty hoặc quỹ tín thác, pháp nhân phải được thành lập trước khi ký hợp đồng để đứng tên người mua.",
      "en": "If buying through a company or trust, the entity must be established before contract so it is named as the buyer."
    },
    "inv_quantity_surveyor_engaged": {
      "vi": "Thuê chuyên viên định lượng (quantity surveyor)",
      "en": "Quantity surveyor engaged"
    },
    "inv_quantity_surveyor_engaged_why": {
      "vi": "Để lập báo cáo khấu hao cho tài sản đầu tư.",
      "en": "To prepare the depreciation schedule for the investment property."
    },
    "inv_depreciation_schedule_received": {
      "vi": "Nhận lịch khấu hao",
      "en": "Depreciation schedule received"
    },
    "inv_depreciation_schedule_received_why": {
      "vi": "Lịch khấu hao cho phép khai khấu hao công trình và thiết bị khi quyết toán thuế.",
      "en": "The depreciation schedule lets you claim building and fixtures depreciation at tax time."
    },
    "inv_property_management_appointed": {
      "vi": "Bổ nhiệm công ty quản lý cho thuê",
      "en": "Property manager appointed"
    },
    "inv_property_management_appointed_why": {
      "vi": "Để quản lý việc cho thuê, thu tiền thuê và tuân thủ luật cho thuê của tiểu bang.",
      "en": "To manage the tenancy, collect rent and comply with state tenancy law."
    },
    "inv_landlord_insurance_bound": {
      "vi": "Mua bảo hiểm chủ nhà cho thuê",
      "en": "Landlord insurance bound"
    },
    "inv_landlord_insurance_bound_why": {
      "vi": "Bảo hiểm chủ nhà bảo vệ trước rủi ro mất tiền thuê và thiệt hại do người thuê gây ra — khác với bảo hiểm công trình.",
      "en": "Landlord insurance covers loss of rent and tenant-caused damage — distinct from building insurance."
    },
    "ins_rule_NSW": {
      "vi": "Tại NSW, rủi ro thuộc về bên bán cho đến khi hoàn tất giao dịch — bạn cần có bảo hiểm công trình từ ngày thanh toán (settlement). Ngân hàng sẽ yêu cầu giấy chứng nhận bảo hiểm trước khi giải ngân.",
      "en": "In NSW, risk stays with the vendor until completion — you need building insurance in force from settlement. Your lender will require a certificate of currency before releasing funds."
    },
    "ins_rule_VIC": {
      "vi": "Tại VIC, rủi ro thuộc về bên bán cho đến khi bạn được quyền sở hữu (settlement); bảo hiểm của bên bán bảo vệ bạn trong thời gian chuyển tiếp. Hãy mua bảo hiểm công trình từ ngày thanh toán; ngân hàng sẽ yêu cầu trước khi giải ngân.",
      "en": "In VIC, risk stays with the vendor until you are entitled to possession (settlement); the vendor's policy covers you in the interim. Bind building insurance from settlement; your lender will require it before releasing funds."
    },
    "ins_rule_QLD": {
      "vi": "Tại QLD, rủi ro chuyển sang người mua lúc 5 giờ chiều ngày làm việc đầu tiên sau ngày ký hợp đồng — bạn phải mua bảo hiểm công trình NGAY sau khi ký, không đợi đến ngày thanh toán.",
      "en": "In QLD, risk passes to the buyer at 5pm the first business day after the contract date — you must bind building insurance immediately after signing, not at settlement."
    },
    "ins_rule_other": {
      "vi": "Ngân hàng yêu cầu bảo hiểm công trình có hiệu lực trước ngày thanh toán ở mọi tiểu bang. Hãy xác nhận thời điểm rủi ro chuyển sang người mua với luật sư/chuyên viên chuyển nhượng của bạn cho tiểu bang này.",
      "en": "Your lender requires building insurance in force by settlement in every state. Confirm the date risk passes to the buyer for this state with your conveyancer."
    },
    "ins_strata_note": {
      "vi": "Nếu là căn hộ/chung cư, tòa nhà đã được ban quản trị (body corporate) mua bảo hiểm — bạn chỉ cần bảo hiểm nội thất (contents), không cần bảo hiểm công trình.",
      "en": "For a strata apartment, the building is insured by the body corporate — you need contents insurance only, not a building policy."
    },
    "next_action": {
      "vi": "Nhập ngày ký hợp đồng và ngày thanh toán (settlement) để kích hoạt lịch trình thanh toán theo ngày, kèm cảnh báo các mốc có rủi ro.",
      "en": "Enter your contract date and settlement date to activate the dated settlement timeline with at-risk milestone alerts."
    }
  }
}
```
