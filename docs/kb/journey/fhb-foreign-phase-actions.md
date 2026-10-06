---
slug: kb.journey.fhb-foreign-phase-actions
effective_from: 2026-07-11
last_verified: 2026-07-11
---

# Mode-B foreign-FHB per-phase action checklist (bilingual)

The **actionable layer** of the legal/temporal spine for a Mode-B foreign-person first-home
purchase — same role as `kb.journey.phase-actions` (Mode A), for each lifecycle phase (Prepare →
Pre-approve → Contract → Settle → Own → Sell) the ordered "do these, in this sequence" steps a
foreign-person first home buyer works through, including the FIRB application and cross-border
transfer steps Mode A has no need for. It is the content the `phase_playbook` resolver (Mode-B
branch) renders as a `checklist` behind each Flow-view phase sheet.

**It stores no figures.** An action may carry a `budget_ref` — the `id` of a `cash_event` the
buyer's calculator already computed. `fh_engine_cash:fill_fhb_foreign/2` (task 12) emits five:
`deposit`, `firb_fee` (both at `contract`), `stamp_duty`, `foreign_buyer_surcharge`,
`other_buying_costs` (all three at `settle`) — the honest-partial rule
(`fh_engine_phase_playbook:keep_valid/2`) drops any `budget_ref` with no matching live
`cash_event.id` to `null` rather than fabricate a figure, exactly Mode A's rule. Dispose-phase
actions carry no `budget_ref` (Mode A's own precedent — `disposition`'s dispose ids surface via
the swimlane's dispose cells, not linked from an action). An action may also carry a
`component_ref` — the id of a component whose renderer opens as the item's backing detail. Mode
B has no `eligibility`/`preparation` components (replaced by `firb_workflow`; there is no
Mode-B-specific document-checklist component), so actions that would reference them in Mode A
point at `firb_workflow` or `mortgage_finance` instead. Both fields are optional; `null` means no
link.

This is a **copy doc** (it fills no slot). It is a blueprint anchor (component 14, added
2026-07-11 alongside `purchase_journey`), so it must resolve; structurally only slug==path +
content_json-parse + the bilingual copy gate apply. Vietnamese is authored for register, not
transliterated from the English (trap #4). Decision-support tone, never advice (ASIC/FIRB/AML):
the checklist is informational, and steps touching finance, credit, tax, FIRB, or VN
capital-control law direct the buyer to their licensed professional — the buyer decides. `status`
is a **user-attested** fact (`not_started | done`), same mechanism as every other mode's
`phase_playbook.actions[].status`.

## Rules

Everything above is `content_md`. The `content_json` below has two parts, same shape as
`kb.journey.phase-actions`: `layout.phases[]` (the structure) and `copy` (the bilingual prose).

Resolver mapping mirrors Mode A's `fh_engine_phase_playbook`: for each `layout.phases[].actions[]`
entry, emit `{ id, order, budget_ref, component_ref, label ← action_<phase>_<id>_label, detail ←
action_<phase>_<id>_detail, status: not_started }`, sorted by `order`, dropping any `budget_ref`
with no matching live `cash_event.id`.

```jsonc
{
  "fills": [],
  "layout": {
    "phases": [
      {
        "phase": "prepare",
        "actions": [
          { "id": "build_deposit",              "order": 1, "budget_ref": "deposit", "component_ref": "cash_position" },
          { "id": "check_firb_eligible_property","order": 2, "budget_ref": null,      "component_ref": "firb_workflow" },
          { "id": "compare_non_resident_lenders","order": 3, "budget_ref": null,      "component_ref": "mortgage_finance" },
          { "id": "map_family_funding",          "order": 4, "budget_ref": null,      "component_ref": "family_context" },
          { "id": "research_transfer_providers", "order": 5, "budget_ref": null,      "component_ref": "cross_border_funding" }
        ]
      },
      {
        "phase": "pre_approve",
        "actions": [
          { "id": "gather_documents",       "order": 1, "budget_ref": null, "component_ref": "mortgage_finance" },
          { "id": "submit_preapproval",      "order": 2, "budget_ref": null, "component_ref": "mortgage_finance" },
          { "id": "prepare_firb_application","order": 3, "budget_ref": null, "component_ref": "firb_workflow" },
          { "id": "plan_transfer_timing",    "order": 4, "budget_ref": null, "component_ref": "cross_border_funding" }
        ]
      },
      {
        "phase": "contract",
        "actions": [
          { "id": "inspect_property",             "order": 1, "budget_ref": null,                      "component_ref": "due_diligence" },
          { "id": "review_contract",              "order": 2, "budget_ref": null,                      "component_ref": "due_diligence" },
          { "id": "confirm_new_build_eligibility","order": 3, "budget_ref": null,                      "component_ref": "buying_strategy" },
          { "id": "pay_deposit",                  "order": 4, "budget_ref": "deposit",                 "component_ref": "cash_position" },
          { "id": "submit_firb_application",      "order": 5, "budget_ref": "firb_fee",                "component_ref": "firb_workflow" },
          { "id": "seek_unconditional_finance",   "order": 6, "budget_ref": null,                      "component_ref": "mortgage_finance" },
          { "id": "initiate_deposit_transfer",    "order": 7, "budget_ref": null,                      "component_ref": "cross_border_funding" }
        ]
      },
      {
        "phase": "settle",
        "actions": [
          { "id": "confirm_firb_approval",     "order": 1, "budget_ref": null,                     "component_ref": "firb_workflow" },
          { "id": "pay_stamp_duty",            "order": 2, "budget_ref": "stamp_duty",             "component_ref": "cash_position" },
          { "id": "pay_foreign_buyer_surcharge","order": 3, "budget_ref": "foreign_buyer_surcharge","component_ref": "cash_position" },
          { "id": "complete_transfer",         "order": 4, "budget_ref": null,                     "component_ref": "cross_border_funding" },
          { "id": "settle_other_costs",        "order": 5, "budget_ref": "other_buying_costs",     "component_ref": "cash_position" },
          { "id": "bind_insurance",            "order": 6, "budget_ref": null,                     "component_ref": "settlement_prep" },
          { "id": "final_inspection",          "order": 7, "budget_ref": null,                     "component_ref": "settlement_prep" },
          { "id": "settlement_completes",      "order": 8, "budget_ref": null,                     "component_ref": "settlement_prep" }
        ]
      },
      {
        "phase": "own",
        "actions": [
          { "id": "move_in",                  "order": 1, "budget_ref": null, "component_ref": "ownership_planning" },
          { "id": "budget_ongoing",           "order": 2, "budget_ref": null, "component_ref": "ownership_planning" },
          { "id": "declare_vacancy_occupancy","order": 3, "budget_ref": null, "component_ref": "ownership_planning" },
          { "id": "monitor_visa_status",      "order": 4, "budget_ref": null, "component_ref": "buyer_profile" },
          { "id": "watch_refinance",          "order": 5, "budget_ref": null, "component_ref": "ownership_planning" }
        ]
      },
      {
        "phase": "dispose",
        "actions": [
          { "id": "decide_to_sell",                  "order": 1, "budget_ref": null, "component_ref": "disposition" },
          { "id": "engage_selling_agent",             "order": 2, "budget_ref": null, "component_ref": "disposition" },
          { "id": "confirm_cgt_tax_residency_position","order": 3, "budget_ref": null, "component_ref": "disposition" },
          { "id": "discharge_mortgage",               "order": 4, "budget_ref": null, "component_ref": "disposition" },
          { "id": "plan_next_step",                   "order": 5, "budget_ref": null, "component_ref": "disposition" }
        ]
      }
    ]
  },
  "copy": {
    "action_prepare_build_deposit_label": { "vi": "Tích lũy tiền cọc", "en": "Build your deposit" },
    "action_prepare_build_deposit_detail": {
      "vi": "Người nước ngoài thường cần mức đặt cọc từ 30% trở lên — cao hơn nhiều so với người mua trong nước.",
      "en": "A foreign person typically needs a 30%+ deposit — well above the domestic-buyer norm."
    },
    "action_prepare_check_firb_eligible_property_label": { "vi": "Xác nhận loại bất động sản bạn được phép mua", "en": "Confirm which property types you're eligible to buy" },
    "action_prepare_check_firb_eligible_property_detail": {
      "vi": "Lệnh cấm mua nhà đã xây sẵn có hiệu lực đến 30/6/2029 — bạn chỉ được mua nhà mới xây, gần như mới xây, hoặc đất trống.",
      "en": "The established-dwelling ban runs until 30 June 2029 — you may only buy new, near-new, or vacant land."
    },
    "action_prepare_compare_non_resident_lenders_label": { "vi": "So sánh ngân hàng cho vay với người nước ngoài", "en": "Compare non-resident-friendly lenders" },
    "action_prepare_compare_non_resident_lenders_detail": {
      "vi": "Chỉ một nhóm nhỏ ngân hàng chấp nhận cho vay với người không cư trú hoặc thường trú tạm thời; lãi suất thường cao hơn.",
      "en": "Only a narrower pool of lenders fund a non-resident or temporary-resident buyer, typically at a rate premium."
    },
    "action_prepare_map_family_funding_label": { "vi": "Lập bản đồ ai đóng góp bao nhiêu", "en": "Map who's contributing what" },
    "action_prepare_map_family_funding_detail": {
      "vi": "Ghi rõ phần đóng góp từ Việt Nam và phần đóng góp tại Úc để tránh nhầm lẫn khi lập kế hoạch chuyển tiền.",
      "en": "Record the Vietnam-side and Australia-side contributions clearly, so the transfer plan isn't guessing at amounts."
    },
    "action_prepare_research_transfer_providers_label": { "vi": "Tìm hiểu các nhà cung cấp chuyển tiền được cấp phép", "en": "Research licensed transfer providers" },
    "action_prepare_research_transfer_providers_detail": {
      "vi": "So sánh Wise, OFX, và chuyển khoản ngân hàng theo tổng chi phí thực tế; không dùng kênh không chính thức.",
      "en": "Compare Wise, OFX, and bank wire by total landed cost; never use an informal channel."
    },

    "action_pre_approve_gather_documents_label": { "vi": "Chuẩn bị hồ sơ vay", "en": "Gather your loan documents" },
    "action_pre_approve_gather_documents_detail": {
      "vi": "Hộ chiếu, giấy tờ visa, bằng chứng thu nhập, và bằng chứng nguồn vốn hợp pháp.",
      "en": "Passport, visa evidence, proof of income, and evidence of the legitimate source of your funds."
    },
    "action_pre_approve_submit_preapproval_label": { "vi": "Nộp hồ sơ duyệt vay sơ bộ", "en": "Apply for pre-approval" },
    "action_pre_approve_submit_preapproval_detail": {
      "vi": "Xin duyệt vay sơ bộ có điều kiện trên đường vay dành cho người nước ngoài để biết ngân sách trước khi tìm nhà.",
      "en": "Get conditional pre-approval on the foreign-person loan path so you know your budget before house-hunting."
    },
    "action_pre_approve_prepare_firb_application_label": { "vi": "Chuẩn bị hồ sơ xin phê duyệt FIRB", "en": "Prepare the FIRB application" },
    "action_pre_approve_prepare_firb_application_detail": {
      "vi": "Bắt đầu sớm — hộ chiếu, bằng chứng nguồn vốn, và chi tiết bất động sản cần có trước khi nộp hồ sơ.",
      "en": "Start early — passport, source-of-funds evidence, and property details are needed before you can submit."
    },
    "action_pre_approve_plan_transfer_timing_label": { "vi": "Lên kế hoạch thời điểm chuyển tiền", "en": "Plan your transfer timing" },
    "action_pre_approve_plan_transfer_timing_detail": {
      "vi": "Ước tính khi nào tiền cọc và phần còn lại cần về đến Úc, tính cả thời gian xử lý chuyển tiền.",
      "en": "Estimate when the deposit and the balance need to land in Australia, allowing for transfer processing time."
    },

    "action_contract_inspect_property_label": { "vi": "Kiểm tra nhà", "en": "Inspect the property" },
    "action_contract_inspect_property_detail": {
      "vi": "Đặt kiểm tra khi có thể — ngay cả nhà mới xây cũng có thể có lỗi hoàn thiện cần ghi nhận trước khi bàn giao.",
      "en": "Book an inspection where possible — even a new build can have completion defects worth recording before settlement."
    },
    "action_contract_review_contract_label": { "vi": "Luật sư rà soát hợp đồng", "en": "Have your conveyancer review the contract" },
    "action_contract_review_contract_detail": {
      "vi": "Để chuyên viên chuyển nhượng rà soát hợp đồng, kể cả điều kiện tùy thuộc vào việc FIRB phê duyệt.",
      "en": "Have your conveyancer review the contract, including the condition subject to FIRB approval."
    },
    "action_contract_confirm_new_build_eligibility_label": { "vi": "Xác nhận bất động sản đủ điều kiện trước khi ra giá", "en": "Confirm the property is eligible before bidding" },
    "action_contract_confirm_new_build_eligibility_detail": {
      "vi": "Nhà đã xây sẵn thường không được phép mua — xác nhận với chuyên viên trước khi ra giá hoặc đấu giá.",
      "en": "An established dwelling is usually off-limits — confirm with your adviser before bidding or entering an auction."
    },
    "action_contract_pay_deposit_label": { "vi": "Đặt cọc khi ký hợp đồng", "en": "Pay the deposit on exchange" },
    "action_contract_pay_deposit_detail": {
      "vi": "Tiền cọc được nộp khi ký hợp đồng; khoản chuyển tiền từ Việt Nam cần được khởi động sớm để kịp hạn.",
      "en": "The deposit is paid on exchange; the transfer from Vietnam needs to be initiated early enough to clear in time."
    },
    "action_contract_submit_firb_application_label": { "vi": "Nộp hồ sơ xin phê duyệt FIRB", "en": "Submit the FIRB application" },
    "action_contract_submit_firb_application_detail": {
      "vi": "Phí FIRB được tính theo giá trị bất động sản và phải nộp đủ cùng hồ sơ; thời gian chờ quyết định tiêu chuẩn là 30 ngày, tính từ ngày nộp đủ phí.",
      "en": "The FIRB fee is assessed by property value and must be paid in full with the application; the standard decision window is 30 days, running from full payment."
    },
    "action_contract_seek_unconditional_finance_label": { "vi": "Xin duyệt vay chính thức", "en": "Submit for unconditional loan approval" },
    "action_contract_seek_unconditional_finance_detail": {
      "vi": "Hoàn tất hồ sơ cho ngân hàng, với điều kiện khoản vay vẫn tùy thuộc vào việc FIRB phê duyệt.",
      "en": "Complete the lender's requirements, with the loan still conditional on FIRB approval."
    },
    "action_contract_initiate_deposit_transfer_label": { "vi": "Khởi động chuyển tiền cho tiền cọc", "en": "Initiate the deposit transfer" },
    "action_contract_initiate_deposit_transfer_detail": {
      "vi": "Gửi khoản chuyển tiền cho tiền cọc sớm để có thời gian dự phòng trước hạn ký hợp đồng.",
      "en": "Send the deposit transfer early to leave a buffer before the exchange deadline."
    },

    "action_settle_confirm_firb_approval_label": { "vi": "Xác nhận FIRB đã phê duyệt", "en": "Confirm FIRB approval" },
    "action_settle_confirm_firb_approval_detail": {
      "vi": "Việc bàn giao không thể tiến hành cho đến khi có thư phê duyệt chính thức từ FIRB.",
      "en": "Settlement cannot proceed until the formal FIRB approval letter is in hand."
    },
    "action_settle_pay_stamp_duty_label": { "vi": "Nộp thuế trước bạ", "en": "Pay stamp duty" },
    "action_settle_pay_stamp_duty_detail": {
      "vi": "Thuế trước bạ đầy đủ đến hạn nộp khi bàn giao — không có ưu đãi người mua nhà lần đầu.",
      "en": "Full stamp duty falls due at settlement — no first-home concession applies."
    },
    "action_settle_pay_foreign_buyer_surcharge_label": { "vi": "Nộp phụ phí người mua nước ngoài", "en": "Pay the foreign-buyer surcharge" },
    "action_settle_pay_foreign_buyer_surcharge_detail": {
      "vi": "Phụ phí thuế trước bạ dành cho người mua nước ngoài đến hạn nộp cùng đợt với thuế trước bạ tiêu chuẩn.",
      "en": "The foreign-buyer stamp-duty surcharge falls due alongside the standard duty."
    },
    "action_settle_complete_transfer_label": { "vi": "Hoàn tất chuyển tiền phần còn lại", "en": "Complete the balance transfer" },
    "action_settle_complete_transfer_detail": {
      "vi": "Xác nhận khoản chuyển tiền đã về đến tài khoản tại Úc và đã thông khoản trước ngày hẹn bàn giao.",
      "en": "Confirm the transfer has landed in your Australian account and cleared ahead of the settlement date."
    },
    "action_settle_settle_other_costs_label": { "vi": "Thanh toán các chi phí giao dịch còn lại", "en": "Pay the remaining transaction costs" },
    "action_settle_settle_other_costs_detail": {
      "vi": "Phí chuyển nhượng, phí đăng bộ, phí FIRB (nếu chưa nộp) và các khoản điều chỉnh được thanh toán khi bàn giao.",
      "en": "Conveyancing, registration, the FIRB fee (if not already paid) and adjustments are paid at settlement."
    },
    "action_settle_bind_insurance_label": { "vi": "Mua bảo hiểm nhà từ thời điểm rủi ro chuyển sang bạn", "en": "Bind building insurance from when risk passes" },
    "action_settle_bind_insurance_detail": {
      "vi": "Thời điểm rủi ro chuyển sang người mua khác nhau theo tiểu bang — mua bảo hiểm có hiệu lực từ đúng thời điểm đó.",
      "en": "The point risk passes to the buyer varies by state — hold insurance effective from that point."
    },
    "action_settle_final_inspection_label": { "vi": "Kiểm tra lần cuối trước khi bàn giao", "en": "Final inspection before settlement" },
    "action_settle_final_inspection_detail": {
      "vi": "Kiểm tra lần cuối để xác nhận tình trạng nhà đúng như hợp đồng.",
      "en": "Do a final inspection to confirm the property's condition matches the contract."
    },
    "action_settle_settlement_completes_label": { "vi": "Hoàn tất bàn giao", "en": "Settlement completes" },
    "action_settle_settlement_completes_detail": {
      "vi": "Việc bàn giao hoàn tất qua PEXA; ngân hàng giải ngân và sổ được sang tên cho bạn.",
      "en": "Settlement completes via PEXA; the lender releases funds and the title transfers to you."
    },

    "action_own_move_in_label": { "vi": "Dọn vào ở", "en": "Move in" },
    "action_own_move_in_detail": {
      "vi": "Dọn vào ở nếu đây là nơi ở của bạn — việc này ảnh hưởng đến nghĩa vụ khai báo tình trạng sử dụng hằng năm.",
      "en": "Move in if this is your home — this shapes your annual occupancy declaration obligation."
    },
    "action_own_budget_ongoing_label": { "vi": "Lập ngân sách cho chi phí định kỳ", "en": "Budget for ongoing costs" },
    "action_own_budget_ongoing_detail": {
      "vi": "Thuế suất hội đồng, tiền nước và phí chung cư (nếu có) là các khoản chi định kỳ — hãy dự trù và giữ một khoản dự phòng.",
      "en": "Council rates, water and strata (if applicable) are recurring — plan for them and keep a buffer."
    },
    "action_own_declare_vacancy_occupancy_label": { "vi": "Khai báo tình trạng sử dụng hằng năm", "en": "Lodge your annual vacancy declaration" },
    "action_own_declare_vacancy_occupancy_detail": {
      "vi": "Chủ sở hữu nước ngoài phải khai báo mức độ sử dụng hằng năm; không đạt ngưỡng sẽ phát sinh phí bỏ trống.",
      "en": "Foreign owners must lodge an annual occupancy declaration; falling short of the threshold triggers the vacancy fee."
    },
    "action_own_monitor_visa_status_label": { "vi": "Theo dõi tình trạng visa của bạn", "en": "Monitor your visa status" },
    "action_own_monitor_visa_status_detail": {
      "vi": "Khi được cấp thường trú nhân hoặc quốc tịch, kế hoạch của bạn có thể chuyển sang mô hình trong nước — hãy cập nhật hồ sơ khi điều đó xảy ra.",
      "en": "When you're granted permanent residency or citizenship, your plan may be eligible to switch to a domestic mode — update your profile when that happens."
    },
    "action_own_watch_refinance_label": { "vi": "Theo dõi cơ hội tái cấp vốn", "en": "Watch for a refinance window" },
    "action_own_watch_refinance_detail": {
      "vi": "Cơ hội tái cấp vốn dành cho người nước ngoài bị giới hạn hơn — theo dõi trong nhóm ngân hàng hẹp phù hợp.",
      "en": "Refinance options for a foreign person are more limited — watch within the narrower eligible lender pool."
    },

    "action_dispose_decide_to_sell_label": { "vi": "Quyết định bán và chọn thời điểm", "en": "Decide to sell and set your timing" },
    "action_dispose_decide_to_sell_detail": {
      "vi": "Số năm bạn giữ nhà và điều kiện thị trường khi bán quyết định số tiền thu về; kế hoạch chiếu một dải ước tính thận trọng, không phải dự báo.",
      "en": "How long you hold and market conditions at sale shape the proceeds; the plan projects a conservative band, not a forecast."
    },
    "action_dispose_engage_selling_agent_label": { "vi": "Chọn đại lý bán và thỏa thuận hoa hồng", "en": "Engage a selling agent and agree the commission" },
    "action_dispose_engage_selling_agent_detail": {
      "vi": "Hoa hồng đại lý, cùng chi phí pháp lý và tiếp thị, làm giảm phần vốn ròng bạn thu về.",
      "en": "Agent commission, together with legal and marketing costs, reduces the net proceeds you walk away with."
    },
    "action_dispose_confirm_cgt_tax_residency_position_label": { "vi": "Xác nhận vị trí thuế lãi vốn theo tình trạng cư trú thuế", "en": "Confirm your CGT position by tax residency" },
    "action_dispose_confirm_cgt_tax_residency_position_detail": {
      "vi": "Quyền miễn thuế lãi vốn cho nhà ở chính không tự động áp dụng cho người nước ngoài — xác nhận với chuyên viên thuế đã đăng ký trước khi bán; kế hoạch nêu trạng thái 'cần kiểm tra', không giả định miễn thuế.",
      "en": "The main-residence CGT exemption does not automatically apply to a foreign person — confirm with a registered tax agent before selling; the plan flags this as 'to verify', not an assumed exemption."
    },
    "action_dispose_discharge_mortgage_label": { "vi": "Sắp xếp tất toán khoản vay còn lại", "en": "Arrange to discharge your remaining loan" },
    "action_dispose_discharge_mortgage_detail": {
      "vi": "Khoản vay còn lại được trả cho ngân hàng từ tiền bán nhà khi hoàn tất giao dịch.",
      "en": "Your remaining loan is repaid to the lender from the sale proceeds at settlement."
    },
    "action_dispose_plan_next_step_label": { "vi": "Lập kế hoạch dùng vốn ròng cho bước tiếp theo", "en": "Plan how your net equity funds your next step" },
    "action_dispose_plan_next_step_detail": {
      "vi": "Vốn ròng thu về sau khi bán có thể trở thành nguồn vốn cho bước tiếp theo tại Úc, hoặc cần chuyển về Việt Nam qua kênh chuyển tiền được cấp phép.",
      "en": "The net equity realised at sale can fund your next step in Australia, or may need transferring back to Vietnam via a licensed channel."
    },

    "assumption_indicative": {
      "vi": "Đây là danh sách hành động tổng quát cho người nước ngoài mua nhà lần đầu tại Úc; thứ tự và thời điểm cụ thể thay đổi theo tiểu bang và theo giao dịch của bạn.",
      "en": "This is a general action list for a foreign person buying a first home in Australia; the exact order and timing vary by state and by your specific transaction."
    },
    "assumption_informational": {
      "vi": "Đây là thông tin tham khảo, không phải tư vấn tài chính, thuế, hay pháp lý. Hãy xác nhận với chuyên gia có giấy phép tại Úc và tại Việt Nam trước khi quyết định.",
      "en": "This is general information, not financial, tax, or legal advice. Confirm with a licensed professional in Australia and in Vietnam before you decide."
    }
  }
}
```
