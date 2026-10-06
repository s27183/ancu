---
slug: kb.journey.investor-foreign-phase-actions
effective_from: 2026-07-10
last_verified: 2026-07-10
---

# Mode-D foreign-investor per-phase action checklist (bilingual)

The **actionable layer** of the legal/temporal spine for a Mode-D Vietnam-located-investor
purchase — same role as Mode C's `kb.journey.investor-phase-actions`, for each lifecycle phase
(Prepare → Pre-approve → Contract → Settle → Hold → Sell) the ordered "do these, in this sequence"
steps a foreign investor works through, including the FIRB application, entity setup, cross-border
transfer, and repatriation steps Mode C has no need for. It is the content the `phase_playbook`
resolver (Mode-D branch) renders as a `checklist` behind each Flow-view phase sheet.

**It stores no figures.** An action may carry a `budget_ref` — the `id` of a `cash_event` the
investor's calculators already computed. `kb.journey.investor-foreign-path`'s preamble declares
the id vocabulary: acquisition (`deposit`, `stamp_duty`, `firb_fee`, `other_buying_costs`,
`entity_setup_costs`, `lmi`), hold (`rental_income`, `operating_expenses`, `loan_interest`),
dispose (`dispose_sale_proceeds`, `dispose_selling_costs`, `dispose_loan_payout`, `dispose_cgt` —
reused unchanged from `disposition`, same ids as every other mode). **Not every id is live yet**
— `cash_position`'s Mode-D fill has no per-property branch (a separate, already-flagged
`cash_position` build, out of scope here), so the acquisition ids resolve to nothing today; the
resolver's honest-partial rule (`fh_engine_phase_playbook:keep_valid/2`) drops any `budget_ref`
with no matching live `cash_event.id` to `null` rather than fabricate a figure — exactly Mode
A/C's rule, and exactly why the `dispose` phase's actions below carry no `budget_ref` at all
(Mode C's own precedent — `disposition`'s dispose ids are surfaced via the swimlane's dispose
cells, not linked from an action). An action may also carry a `component_ref` — the id of a
component whose renderer opens as the item's backing detail. Both are optional; `null` means no
link.

This is a **copy doc** (it fills no slot). It is a blueprint anchor (component 16, added
2026-07-10 alongside `purchase_journey`), so it must resolve; structurally only slug==path +
content_json-parse + the bilingual copy gate apply. Vietnamese is authored for register, not
transliterated from the English (trap #4). Decision-support tone, never advice (ASIC/FIRB/AML):
the checklist is informational, and steps touching finance, credit, tax, FIRB, or VN capital-
control law direct the investor to their licensed professional — the investor decides. `status` is
a **user-attested** fact (`not_started | done`), same mechanism as every other mode's `phase_
playbook.actions[].status`.

## Rules

Everything above is `content_md`. The `content_json` below has two parts, same shape as
`kb.journey.investor-phase-actions`: `layout.phases[]` (the structure) and `copy` (the bilingual
prose).

Resolver mapping mirrors Mode C's `fh_engine_phase_playbook`: for each
`layout.phases[].actions[]` entry, emit `{ id, order, budget_ref, component_ref, label ←
action_<phase>_<id>_label, detail ← action_<phase>_<id>_detail, status: not_started }`, sorted by
`order`, dropping any `budget_ref` with no matching live `cash_event.id`.

```jsonc
{
  "fills": [],
  "layout": {
    "phases": [
      {
        "phase": "prepare",
        "actions": [
          { "id": "clarify_thesis",              "order": 1, "budget_ref": null, "component_ref": "investment_strategy" },
          { "id": "compare_non_resident_lenders", "order": 2, "budget_ref": null, "component_ref": "mortgage_finance" },
          { "id": "consider_entity",              "order": 3, "budget_ref": null, "component_ref": "tax_structure_non_resident" },
          { "id": "engage_vn_advisor",             "order": 4, "budget_ref": null, "component_ref": "investor_profile_foreign" }
        ]
      },
      {
        "phase": "pre_approve",
        "actions": [
          { "id": "gather_documents",           "order": 1, "budget_ref": null, "component_ref": "mortgage_finance" },
          { "id": "submit_preapproval",          "order": 2, "budget_ref": null, "component_ref": "mortgage_finance" },
          { "id": "prepare_firb_application",    "order": 3, "budget_ref": null, "component_ref": "firb_workflow" },
          { "id": "engage_transfer_provider",    "order": 4, "budget_ref": null, "component_ref": "cross_border_funding" }
        ]
      },
      {
        "phase": "contract",
        "actions": [
          { "id": "get_rental_appraisal",     "order": 1, "budget_ref": null,        "component_ref": "due_diligence" },
          { "id": "get_depreciation_quote",   "order": 2, "budget_ref": null,        "component_ref": "due_diligence" },
          { "id": "inspect_building_pest",    "order": 3, "budget_ref": null,        "component_ref": "due_diligence" },
          { "id": "review_contract",          "order": 4, "budget_ref": null,        "component_ref": "due_diligence" },
          { "id": "submit_firb_application",  "order": 5, "budget_ref": "firb_fee",  "component_ref": "firb_workflow" },
          { "id": "pay_deposit",              "order": 6, "budget_ref": "deposit",   "component_ref": "cash_position" },
          { "id": "seek_unconditional_finance","order": 7, "budget_ref": null,       "component_ref": "mortgage_finance" }
        ]
      },
      {
        "phase": "settle",
        "actions": [
          { "id": "confirm_firb_approval",     "order": 1, "budget_ref": null,                 "component_ref": "firb_workflow" },
          { "id": "pay_stamp_duty_surcharge",  "order": 2, "budget_ref": "stamp_duty",          "component_ref": "cash_position" },
          { "id": "pay_firb_fee",              "order": 3, "budget_ref": "firb_fee",            "component_ref": "cash_position" },
          { "id": "complete_transfer",         "order": 4, "budget_ref": null,                  "component_ref": "cross_border_funding" },
          { "id": "complete_entity_setup",     "order": 5, "budget_ref": "entity_setup_costs",  "component_ref": "settlement_prep" },
          { "id": "appoint_pm",                "order": 6, "budget_ref": null,                  "component_ref": "settlement_prep" },
          { "id": "bind_landlord_insurance",   "order": 7, "budget_ref": null,                  "component_ref": "settlement_prep" },
          { "id": "settlement_completes",      "order": 8, "budget_ref": null,                  "component_ref": "settlement_prep" }
        ]
      },
      {
        "phase": "own",
        "actions": [
          { "id": "track_cash_flow",           "order": 1, "budget_ref": null, "component_ref": "ownership_planning_foreign_investor" },
          { "id": "lodge_au_tax_return",        "order": 2, "budget_ref": null, "component_ref": "tax_structure_non_resident" },
          { "id": "declare_vacancy_occupancy",  "order": 3, "budget_ref": null, "component_ref": "ownership_planning_foreign_investor" },
          { "id": "monitor_land_tax_surcharge", "order": 4, "budget_ref": null, "component_ref": "ownership_planning_foreign_investor" },
          { "id": "plan_repatriation",          "order": 5, "budget_ref": null, "component_ref": "ownership_planning_foreign_investor" },
          { "id": "review_pm_performance",      "order": 6, "budget_ref": null, "component_ref": "ownership_planning_foreign_investor" }
        ]
      },
      {
        "phase": "dispose",
        "actions": [
          { "id": "decide_to_sell",            "order": 1, "budget_ref": null, "component_ref": "disposition" },
          { "id": "engage_selling_agent",      "order": 2, "budget_ref": null, "component_ref": "disposition" },
          { "id": "confirm_cgt_frcgw_position","order": 3, "budget_ref": null, "component_ref": "disposition" },
          { "id": "discharge_mortgage",        "order": 4, "budget_ref": null, "component_ref": "disposition" },
          { "id": "repatriate_proceeds",       "order": 5, "budget_ref": null, "component_ref": "disposition" },
          { "id": "plan_next_purchase",        "order": 6, "budget_ref": null, "component_ref": "disposition" }
        ]
      }
    ]
  },
  "copy": {
    "action_prepare_clarify_thesis_label": { "vi": "Xác định chiến lược đầu tư", "en": "Clarify your investment thesis" },
    "action_prepare_clarify_thesis_detail": {
      "vi": "Chọn hướng đi: lợi suất cho thuê hay tăng trưởng vốn, mức đòn bẩy vay, và số năm dự định giữ nhà.",
      "en": "Decide your direction: cash flow or capital growth, gearing approach, and how long you plan to hold."
    },
    "action_prepare_compare_non_resident_lenders_label": { "vi": "So sánh ngân hàng cho vay với người không cư trú", "en": "Compare non-resident lenders" },
    "action_prepare_compare_non_resident_lenders_detail": {
      "vi": "Số ngân hàng chấp nhận cho vay đầu tư với người không cư trú tại Úc rất hạn chế; thu nhập từ Việt Nam thường bị tính giảm khi xét khả năng vay.",
      "en": "Very few Australian lenders fund a non-resident investor; income from Vietnam is typically discounted in the serviceability test."
    },
    "action_prepare_consider_entity_label": { "vi": "Cân nhắc pháp nhân đứng tên sở hữu", "en": "Consider your ownership entity" },
    "action_prepare_consider_entity_detail": {
      "vi": "Cá nhân, quỹ ủy thác, hay công ty có cổ đông nước ngoài — mỗi lựa chọn có chi phí thiết lập, nghĩa vụ khai báo, và cách tính thuế khác nhau cho người không cư trú.",
      "en": "Personal name, a trust, or a company with a foreign shareholder — each carries different setup cost, compliance obligations, and non-resident tax treatment."
    },
    "action_prepare_engage_vn_advisor_label": { "vi": "Cân nhắc dùng chuyên viên tư vấn đầu tư tại Việt Nam", "en": "Consider a Vietnam-based investment advisor" },
    "action_prepare_engage_vn_advisor_detail": {
      "vi": "Một chuyên viên hiểu cả quy định FIRB của Úc và kiểm soát vốn của Việt Nam có thể giúp bạn phối hợp hai bên.",
      "en": "An advisor who understands both Australian FIRB rules and Vietnamese capital controls can help you coordinate both sides."
    },

    "action_pre_approve_gather_documents_label": { "vi": "Chuẩn bị hồ sơ vay", "en": "Gather your loan documents" },
    "action_pre_approve_gather_documents_detail": {
      "vi": "Hộ chiếu, bằng chứng cư trú tại Việt Nam, sao kê ngân hàng, và bằng chứng nguồn vốn hợp pháp.",
      "en": "Passport, evidence of Vietnam residency, bank statements, and evidence of the legitimate source of your funds."
    },
    "action_pre_approve_submit_preapproval_label": { "vi": "Nộp hồ sơ duyệt vay sơ bộ", "en": "Apply for pre-approval" },
    "action_pre_approve_submit_preapproval_detail": {
      "vi": "Xin duyệt vay đầu tư sơ bộ có điều kiện dành cho người không cư trú để biết ngân sách trước khi tìm bất động sản.",
      "en": "Get conditional non-resident investment-loan pre-approval so you know your budget before searching."
    },
    "action_pre_approve_prepare_firb_application_label": { "vi": "Chuẩn bị hồ sơ xin phê duyệt FIRB", "en": "Prepare the FIRB application" },
    "action_pre_approve_prepare_firb_application_detail": {
      "vi": "Bắt đầu sớm — hộ chiếu, bằng chứng nguồn vốn, và chi tiết bất động sản cần có trước khi nộp hồ sơ.",
      "en": "Start early — passport, source-of-funds evidence, and property details are needed before you can submit."
    },
    "action_pre_approve_engage_transfer_provider_label": { "vi": "Liên hệ nhà cung cấp chuyển tiền được cấp phép", "en": "Engage a licensed transfer provider" },
    "action_pre_approve_engage_transfer_provider_detail": {
      "vi": "So sánh Wise, OFX, và chuyển khoản ngân hàng theo tổng chi phí thực tế; không dùng kênh không chính thức.",
      "en": "Compare Wise, OFX, and bank wire by total landed cost; never use an informal channel."
    },

    "action_contract_get_rental_appraisal_label": { "vi": "Lấy ước tính tiền thuê tham khảo", "en": "Get a rental appraisal" },
    "action_contract_get_rental_appraisal_detail": {
      "vi": "Một đơn vị quản lý cho thuê ước tính mức tiền thuê thực tế cho bất động sản mới xây bạn được phép mua.",
      "en": "A property manager estimates the realistic achievable rent for the new-build stock you're eligible to buy."
    },
    "action_contract_get_depreciation_quote_label": { "vi": "Lấy báo giá báo cáo khấu hao", "en": "Get a depreciation-schedule quote" },
    "action_contract_get_depreciation_quote_detail": {
      "vi": "Chuyên viên khảo sát khối lượng lập báo cáo khấu hao, xác định khoản khấu trừ thuế có thể yêu cầu tại Úc.",
      "en": "A quantity surveyor prepares a depreciation schedule, which determines the AU tax deductions you can claim."
    },
    "action_contract_inspect_building_pest_label": { "vi": "Kiểm tra nhà và kiểm tra mối", "en": "Building and pest inspections" },
    "action_contract_inspect_building_pest_detail": {
      "vi": "Đặt kiểm tra khi có thể — ngay cả nhà mới xây cũng có thể có lỗi hoàn thiện cần ghi nhận trước khi bàn giao.",
      "en": "Book inspections where possible — even a new build can have completion defects worth recording before settlement."
    },
    "action_contract_review_contract_label": { "vi": "Luật sư rà soát hợp đồng", "en": "Have your conveyancer review the contract" },
    "action_contract_review_contract_detail": {
      "vi": "Để chuyên viên chuyển nhượng rà soát hợp đồng, kể cả điều kiện tùy thuộc vào việc FIRB phê duyệt.",
      "en": "Have your conveyancer review the contract, including the condition subject to FIRB approval."
    },
    "action_contract_submit_firb_application_label": { "vi": "Nộp hồ sơ xin phê duyệt FIRB", "en": "Submit the FIRB application" },
    "action_contract_submit_firb_application_detail": {
      "vi": "Phí FIRB được tính theo giá trị bất động sản và phải nộp cùng hồ sơ; thời gian chờ quyết định thường 30–60 ngày.",
      "en": "The FIRB fee is assessed by property value and paid with the application; the decision typically takes 30–60 days."
    },
    "action_contract_pay_deposit_label": { "vi": "Đặt cọc khi ký hợp đồng", "en": "Pay the deposit on exchange" },
    "action_contract_pay_deposit_detail": {
      "vi": "Tiền cọc được nộp khi ký hợp đồng; khoản chuyển tiền từ Việt Nam cần được khởi động sớm để kịp hạn.",
      "en": "The deposit is paid on exchange; the transfer from Vietnam needs to be initiated early enough to clear in time."
    },
    "action_contract_seek_unconditional_finance_label": { "vi": "Xin duyệt vay chính thức", "en": "Submit for unconditional loan approval" },
    "action_contract_seek_unconditional_finance_detail": {
      "vi": "Hoàn tất hồ sơ cho ngân hàng, với điều kiện khoản vay vẫn tùy thuộc vào việc FIRB phê duyệt.",
      "en": "Complete the lender's requirements, with the loan still conditional on FIRB approval."
    },

    "action_settle_confirm_firb_approval_label": { "vi": "Xác nhận FIRB đã phê duyệt", "en": "Confirm FIRB approval" },
    "action_settle_confirm_firb_approval_detail": {
      "vi": "Hợp đồng không thể tiến hành bàn giao cho đến khi có thư phê duyệt chính thức từ FIRB.",
      "en": "Settlement cannot proceed until the formal FIRB approval letter is in hand."
    },
    "action_settle_pay_stamp_duty_surcharge_label": { "vi": "Nộp thuế trước bạ và phụ phí người mua nước ngoài", "en": "Pay stamp duty and the foreign-buyer surcharge" },
    "action_settle_pay_stamp_duty_surcharge_detail": {
      "vi": "Thuế trước bạ đầy đủ cộng phụ phí dành cho người mua nước ngoài đến hạn nộp khi bàn giao — không có ưu đãi.",
      "en": "Full stamp duty plus the foreign-buyer surcharge falls due at settlement — no concession applies."
    },
    "action_settle_pay_firb_fee_label": { "vi": "Nộp phí FIRB", "en": "Pay the FIRB fee" },
    "action_settle_pay_firb_fee_detail": {
      "vi": "Phí FIRB được nộp cùng đợt với các chi phí bàn giao khác nếu chưa nộp khi xin phê duyệt.",
      "en": "The FIRB fee is settled alongside your other settlement costs if not already paid with the application."
    },
    "action_settle_complete_transfer_label": { "vi": "Hoàn tất chuyển tiền phần còn lại", "en": "Complete the balance transfer" },
    "action_settle_complete_transfer_detail": {
      "vi": "Xác nhận khoản chuyển tiền đã về đến tài khoản tại Úc và đã thông khoản trước ngày hẹn bàn giao.",
      "en": "Confirm the transfer has landed in your Australian account and cleared ahead of the settlement date."
    },
    "action_settle_complete_entity_setup_label": { "vi": "Hoàn tất lập pháp nhân (nếu dùng)", "en": "Complete entity setup (if applicable)" },
    "action_settle_complete_entity_setup_detail": {
      "vi": "Nếu dùng quỹ ủy thác hay công ty, hoàn tất thủ tục lập pháp nhân đúng thời hạn để không làm chậm bàn giao.",
      "en": "If using a trust or company, complete the entity's setup in time so it doesn't delay settlement."
    },
    "action_settle_appoint_pm_label": { "vi": "Chỉ định đơn vị quản lý cho thuê", "en": "Appoint a property manager" },
    "action_settle_appoint_pm_detail": {
      "vi": "Với chủ sở hữu ở nước ngoài, dùng quản lý chuyên nghiệp thường là điều kiện bắt buộc, không chỉ là lựa chọn.",
      "en": "For an offshore owner, professional management is typically a practical requirement, not just an option."
    },
    "action_settle_bind_landlord_insurance_label": { "vi": "Mua bảo hiểm cho chủ nhà cho thuê", "en": "Bind landlord insurance" },
    "action_settle_bind_landlord_insurance_detail": {
      "vi": "Bảo hiểm cho chủ nhà cho thuê bao gồm mất tiền thuê và thiệt hại do người thuê — quan trọng hơn khi bạn ở xa.",
      "en": "Landlord insurance covers lost rent and tenant damage — more important still when you're managing remotely."
    },
    "action_settle_settlement_completes_label": { "vi": "Hoàn tất bàn giao", "en": "Settlement completes" },
    "action_settle_settlement_completes_detail": {
      "vi": "Việc bàn giao hoàn tất qua PEXA; ngân hàng giải ngân và sổ được sang tên cho bạn (hoặc pháp nhân của bạn).",
      "en": "Settlement completes via PEXA; the lender releases funds and the title transfers to you (or your entity)."
    },

    "action_own_track_cash_flow_label": { "vi": "Theo dõi dòng tiền thực tế", "en": "Track actual cash flow" },
    "action_own_track_cash_flow_detail": {
      "vi": "So sánh dòng tiền thực tế với dự tính hằng tháng, đặc biệt khi quản lý từ xa.",
      "en": "Compare actual cash flow against the projection monthly, especially important when managing remotely."
    },
    "action_own_lodge_au_tax_return_label": { "vi": "Nộp tờ khai thuế thu nhập tại Úc", "en": "Lodge your Australian tax return" },
    "action_own_lodge_au_tax_return_detail": {
      "vi": "Thu nhập cho thuê tại Úc được khai theo hình thức đánh giá hằng năm, không phải khấu trừ tại nguồn.",
      "en": "AU rental income is declared by annual assessment, not a final withholding tax."
    },
    "action_own_declare_vacancy_occupancy_label": { "vi": "Khai báo tình trạng sử dụng hằng năm", "en": "Lodge your annual vacancy declaration" },
    "action_own_declare_vacancy_occupancy_detail": {
      "vi": "Chủ sở hữu nước ngoài phải khai báo mức độ sử dụng hằng năm; không đạt ngưỡng cho thuê tối thiểu sẽ phát sinh phí bỏ trống.",
      "en": "Foreign owners must lodge an annual occupancy declaration; falling short of the minimum rental threshold triggers the vacancy fee."
    },
    "action_own_monitor_land_tax_surcharge_label": { "vi": "Theo dõi thuế đất và phụ phí", "en": "Monitor land tax and the surcharge" },
    "action_own_monitor_land_tax_surcharge_detail": {
      "vi": "Chủ sở hữu nước ngoài chịu phụ phí thuế đất bổ sung ở hầu hết các tiểu bang, cộng vào thuế đất tiêu chuẩn.",
      "en": "Foreign owners pay an additional land-tax surcharge in most states, on top of the standard land tax."
    },
    "action_own_plan_repatriation_label": { "vi": "Lập kế hoạch chuyển lợi nhuận về Việt Nam", "en": "Plan your repatriation of rental income" },
    "action_own_plan_repatriation_detail": {
      "vi": "Chọn tần suất chuyển tiền (hằng tháng, hằng quý, hay tái đầu tư tại Úc) và dùng kênh chuyển tiền được cấp phép.",
      "en": "Choose your repatriation frequency (monthly, quarterly, or reinvest in Australia) and use a licensed transfer channel."
    },
    "action_own_review_pm_performance_label": { "vi": "Xem lại hiệu quả quản lý cho thuê", "en": "Review property-management performance" },
    "action_own_review_pm_performance_detail": {
      "vi": "Xem lại mức phí, thời gian nhà trống, và chất lượng liên lạc định kỳ hằng năm — quan trọng hơn khi bạn ở xa.",
      "en": "Review fees, vacancy periods, and communication quality on an annual cadence — more important when you're offshore."
    },

    "action_dispose_decide_to_sell_label": { "vi": "Quyết định bán và chọn thời điểm", "en": "Decide to sell and set your timing" },
    "action_dispose_decide_to_sell_detail": {
      "vi": "Số năm giữ nhà và chiến lược thoát vốn định hình khi nào bán hợp lý; kế hoạch chiếu một dải ước tính thận trọng.",
      "en": "Your hold period and exit strategy shape when selling makes sense; the plan projects a conservative band."
    },
    "action_dispose_engage_selling_agent_label": { "vi": "Chọn đại lý bán và thỏa thuận hoa hồng", "en": "Engage a selling agent and agree the commission" },
    "action_dispose_engage_selling_agent_detail": {
      "vi": "Hoa hồng đại lý, cùng chi phí pháp lý và tiếp thị, làm giảm phần vốn ròng bạn thu về.",
      "en": "Agent commission, together with legal and marketing costs, reduces the net proceeds you walk away with."
    },
    "action_dispose_confirm_cgt_frcgw_position_label": { "vi": "Xác nhận vị trí thuế lãi vốn và khấu trừ FRCGW", "en": "Confirm your CGT and FRCGW position" },
    "action_dispose_confirm_cgt_frcgw_position_detail": {
      "vi": "Là người không cư trú, bạn không được giảm 50% thuế lãi vốn và bị khấu trừ FRCGW tại thời điểm bàn giao — khoản khấu trừ này trừ vào thuế phải nộp, không phải chi phí thêm — xác nhận với chuyên viên thuế đã đăng ký trước khi bán.",
      "en": "As a non-resident you get no 50% CGT discount, and FRCGW is withheld at settlement — a credit against the tax owed, not an extra cost — confirm with a registered tax agent before selling."
    },
    "action_dispose_discharge_mortgage_label": { "vi": "Sắp xếp tất toán khoản vay còn lại", "en": "Arrange to discharge your remaining loan" },
    "action_dispose_discharge_mortgage_detail": {
      "vi": "Khoản vay còn lại được trả cho ngân hàng từ tiền bán nhà khi hoàn tất giao dịch.",
      "en": "Your remaining loan is repaid to the lender from the sale proceeds at settlement."
    },
    "action_dispose_repatriate_proceeds_label": { "vi": "Chuyển vốn ròng về Việt Nam", "en": "Repatriate the net proceeds" },
    "action_dispose_repatriate_proceeds_detail": {
      "vi": "Sau khi trừ chi phí bán, thuế, và tất toán vay, phần vốn ròng còn lại được chuyển về qua kênh chuyển tiền được cấp phép.",
      "en": "After selling costs, tax, and the loan payout, the remaining net equity is transferred back via a licensed channel."
    },
    "action_dispose_plan_next_purchase_label": { "vi": "Lập kế hoạch dùng vốn ròng cho bất động sản tiếp theo", "en": "Plan how your net equity funds your next property" },
    "action_dispose_plan_next_purchase_detail": {
      "vi": "Mỗi bất động sản tiếp theo cần hồ sơ FIRB riêng — vốn ròng thu về có thể trở thành vốn cho lần mua kế tiếp.",
      "en": "Each new property needs its own fresh FIRB application — the net equity realised at sale can fund your next purchase."
    },

    "assumption_indicative": {
      "vi": "Đây là danh sách hành động tổng quát cho nhà đầu tư ở Việt Nam mua bất động sản tại Úc; thứ tự và thời điểm cụ thể thay đổi theo tiểu bang và theo giao dịch của bạn.",
      "en": "This is a general action list for a Vietnam-located investor buying Australian property; the exact order and timing vary by state and by your specific transaction."
    },
    "assumption_informational": {
      "vi": "Đây là thông tin tham khảo, không phải tư vấn tài chính, thuế, hay pháp lý. Hãy xác nhận với chuyên gia có giấy phép tại Úc và tại Việt Nam trước khi quyết định.",
      "en": "This is general information, not financial, tax, or legal advice. Confirm with a licensed professional in Australia and in Vietnam before you decide."
    }
  }
}
```
