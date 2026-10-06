---
slug: kb.journey.investor-phase-actions
effective_from: 2026-07-10
last_verified: 2026-07-10
---

# Mode-C investor per-phase action checklist (bilingual)

The **actionable layer** of the legal/temporal spine for a Mode-C domestic-investor purchase —
same role as Mode A's `kb.journey.phase-actions` (plan-card-lifecycle-restoration.md §3.3), for
each lifecycle phase (Prepare → Pre-approve → Contract → Settle → Hold → Sell) the ordered
"do these, in this sequence" steps a domestic investor works through. It is the content the
`phase_playbook` resolver (Mode-C branch, mirroring Mode A component 12) renders as a `checklist`
behind each Flow-view phase sheet. The swimlane (`kb.journey.investor-path`) shows *what
happens*; this doc turns that into *what you do, in what order*.

**It stores no figures.** An action may carry a `budget_ref` — the `id` of a `cash_event` the
investor's calculators already computed. `kb.journey.investor-path`'s preamble declares the full
id vocabulary this doc's `budget_ref`s draw from: acquisition (`deposit`, `stamp_duty`,
`other_buying_costs`, `entity_setup_costs`, `lmi`), hold (`rental_income`, `operating_expenses`,
`loan_interest`, `tax_refund`), dispose (`sale_proceeds`, `selling_costs`, `loan_payout`, `cgt` —
reused unchanged from `disposition`). Not every id is live yet — `budget_envelope_investor` /
`cash_flow_projection` / `tax_optimised_structure` don't carry a `cash_events[]` array today
(tracked for the restructure's engine-wiring pass) — so the resolver mapping below is
honest-partial by construction: **if a `budget_ref` does not match any `cash_event.id` present in
the investor's outcomes, drop the ref (set `null`) — never fabricate a figure**, exactly Mode A's
rule. An action may also carry a `component_ref` — the id of a component whose renderer opens as
the item's backing detail. Both are optional; `null` means no link.

This is a **copy doc** (it fills no slot). It is a blueprint anchor (component 12 — not yet added
to the Mode-C pipeline; tracked as the restructure's blueprint-wiring pass), so it must resolve;
structurally only slug==path + content_json-parse + the bilingual copy gate apply. Vietnamese is
authored for register, not transliterated from the English (trap #4). Decision-support tone,
never advice (ASIC): the checklist is informational, and steps touching finance, credit, tax or
law direct the investor to their licensed professional — the investor decides. `status` is a
**user-attested** fact (`not_started | done`), same user-set-layer mechanism as Mode A's
`preparation.document_checklist[].status` / `phase_playbook.actions[].status` (engine-contract
§10.4, lifecycle-simulation-model §7.4a) so a recompute never clobbers it.

## Rules

Everything above is `content_md`. The `content_json` below has two parts, same shape as
`kb.journey.phase-actions`: `layout.phases[]` (the structure) and `copy` (the bilingual prose).

Resolver mapping mirrors Mode A's `fh_engine_phase_playbook`: for each
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
          { "id": "clarify_thesis",       "order": 1, "budget_ref": null, "component_ref": "investment_strategy" },
          { "id": "compare_lenders",      "order": 2, "budget_ref": null, "component_ref": "mortgage_finance" },
          { "id": "consider_entity",      "order": 3, "budget_ref": null, "component_ref": "tax_structure" },
          { "id": "build_deposit",        "order": 4, "budget_ref": null, "component_ref": "cash_position" }
        ]
      },
      {
        "phase": "pre_approve",
        "actions": [
          { "id": "gather_documents",     "order": 1, "budget_ref": null, "component_ref": "mortgage_finance" },
          { "id": "consider_broker",      "order": 2, "budget_ref": null, "component_ref": "mortgage_finance" },
          { "id": "submit_preapproval",   "order": 3, "budget_ref": null, "component_ref": "mortgage_finance" }
        ]
      },
      {
        "phase": "contract",
        "actions": [
          { "id": "get_rental_appraisal",   "order": 1, "budget_ref": null,      "component_ref": "due_diligence" },
          { "id": "get_depreciation_quote", "order": 2, "budget_ref": null,      "component_ref": "due_diligence" },
          { "id": "inspect_building_pest",  "order": 3, "budget_ref": null,      "component_ref": "due_diligence" },
          { "id": "review_contract",        "order": 4, "budget_ref": null,      "component_ref": "due_diligence" },
          { "id": "decide_offer_strategy",  "order": 5, "budget_ref": null,      "component_ref": "buying_strategy" },
          { "id": "pay_deposit",            "order": 6, "budget_ref": "deposit", "component_ref": "cash_position" },
          { "id": "seek_unconditional",     "order": 7, "budget_ref": null,      "component_ref": "mortgage_finance" }
        ]
      },
      {
        "phase": "settle",
        "actions": [
          { "id": "pay_stamp_duty",        "order": 1, "budget_ref": "stamp_duty",         "component_ref": "cash_position" },
          { "id": "settle_other_costs",    "order": 2, "budget_ref": "other_buying_costs", "component_ref": "cash_position" },
          { "id": "complete_entity_setup", "order": 3, "budget_ref": "entity_setup_costs",  "component_ref": "settlement_prep" },
          { "id": "engage_qs",             "order": 4, "budget_ref": null,                  "component_ref": "settlement_prep" },
          { "id": "appoint_pm",            "order": 5, "budget_ref": null,                  "component_ref": "settlement_prep" },
          { "id": "bind_landlord_insurance","order": 6,"budget_ref": null,                  "component_ref": "settlement_prep" },
          { "id": "settlement_completes",  "order": 7, "budget_ref": null,                  "component_ref": "settlement_prep" }
        ]
      },
      {
        "phase": "own",
        "actions": [
          { "id": "track_cash_flow",       "order": 1, "budget_ref": null,           "component_ref": "ownership_planning_investor" },
          { "id": "lodge_annual_return",   "order": 2, "budget_ref": "tax_refund",   "component_ref": "tax_structure" },
          { "id": "monitor_land_tax",      "order": 3, "budget_ref": null,           "component_ref": "ownership_planning_investor" },
          { "id": "watch_equity_release",  "order": 4, "budget_ref": null,           "component_ref": "ownership_planning_investor" },
          { "id": "review_pm_performance", "order": 5, "budget_ref": null,           "component_ref": "ownership_planning_investor" }
        ]
      },
      {
        "phase": "dispose",
        "actions": [
          { "id": "decide_to_sell",         "order": 1, "budget_ref": null, "component_ref": "disposition" },
          { "id": "engage_selling_agent",   "order": 2, "budget_ref": null, "component_ref": "disposition" },
          { "id": "confirm_cgt_position",   "order": 3, "budget_ref": null, "component_ref": "disposition" },
          { "id": "discharge_mortgage",     "order": 4, "budget_ref": null, "component_ref": "disposition" },
          { "id": "plan_next_purchase",     "order": 5, "budget_ref": null, "component_ref": "disposition" }
        ]
      }
    ]
  },
  "copy": {
    "action_prepare_clarify_thesis_label": {
      "vi": "Xác định chiến lược đầu tư",
      "en": "Clarify your investment thesis"
    },
    "action_prepare_clarify_thesis_detail": {
      "vi": "Chọn hướng đi: lợi suất cho thuê hay tăng trưởng vốn, mức đòn bẩy vay, và số năm dự định giữ nhà.",
      "en": "Decide your direction: cash flow or capital growth, gearing approach, and how long you plan to hold."
    },
    "action_prepare_compare_lenders_label": {
      "vi": "So sánh ngân hàng cho vay đầu tư",
      "en": "Compare investment lenders"
    },
    "action_prepare_compare_lenders_detail": {
      "vi": "Khả năng vay đầu tư khác với vay mua nhà ở — ngân hàng thường chỉ tính một phần thu nhập cho thuê dự kiến.",
      "en": "Investment-loan capacity differs from an owner-occupier loan — lenders typically discount projected rental income."
    },
    "action_prepare_consider_entity_label": {
      "vi": "Cân nhắc pháp nhân đứng tên sở hữu",
      "en": "Consider your ownership entity"
    },
    "action_prepare_consider_entity_detail": {
      "vi": "Cá nhân, quỹ ủy thác (trust), hay công ty — mỗi lựa chọn có chi phí thiết lập, nghĩa vụ khai báo, và cách tính thuế khác nhau.",
      "en": "Personal name, a trust, or a company — each carries different setup cost, compliance obligations, and tax treatment."
    },
    "action_prepare_build_deposit_label": {
      "vi": "Tích lũy tiền cọc đầu tư",
      "en": "Build your investment deposit"
    },
    "action_prepare_build_deposit_detail": {
      "vi": "Khoản vay đầu tư thường yêu cầu tiền cọc từ 20% trở lên để tránh phí bảo hiểm khoản vay (LMI).",
      "en": "Investment loans typically require a 20%+ deposit to avoid lenders mortgage insurance (LMI)."
    },

    "action_pre_approve_gather_documents_label": {
      "vi": "Chuẩn bị hồ sơ vay",
      "en": "Gather your loan documents"
    },
    "action_pre_approve_gather_documents_detail": {
      "vi": "Giấy tờ tùy thân, phiếu lương, sao kê ngân hàng, và bằng chứng vốn hoặc tài sản hiện có (kể cả vốn chủ sở hữu trong nhà đang ở, nếu dùng để đòn bẩy).",
      "en": "ID, payslips, bank statements, and evidence of existing funds or equity (including equity in your home, if you plan to leverage it)."
    },
    "action_pre_approve_consider_broker_label": {
      "vi": "Cân nhắc dùng chuyên viên môi giới vay",
      "en": "Consider a mortgage broker"
    },
    "action_pre_approve_consider_broker_detail": {
      "vi": "Một chuyên viên môi giới vay chuyên về khoản vay đầu tư có thể so sánh nhiều ngân hàng; bạn vẫn là người quyết định.",
      "en": "A broker who specialises in investment lending can compare lenders; you still decide."
    },
    "action_pre_approve_submit_preapproval_label": {
      "vi": "Nộp hồ sơ duyệt vay sơ bộ",
      "en": "Apply for pre-approval"
    },
    "action_pre_approve_submit_preapproval_detail": {
      "vi": "Xin duyệt vay đầu tư sơ bộ có điều kiện để biết ngân sách trước khi tìm bất động sản.",
      "en": "Get conditional investment-loan pre-approval so you know your budget before searching."
    },

    "action_contract_get_rental_appraisal_label": {
      "vi": "Lấy ước tính tiền thuê tham khảo",
      "en": "Get a rental appraisal"
    },
    "action_contract_get_rental_appraisal_detail": {
      "vi": "Một đơn vị quản lý cho thuê ước tính mức tiền thuê thực tế — dùng để kiểm tra lợi suất so với mục tiêu.",
      "en": "A property manager estimates the realistic achievable rent — used to check yield against your target."
    },
    "action_contract_get_depreciation_quote_label": {
      "vi": "Lấy báo giá báo cáo khấu hao",
      "en": "Get a depreciation-schedule quote"
    },
    "action_contract_get_depreciation_quote_detail": {
      "vi": "Chuyên viên khảo sát khối lượng (quantity surveyor) lập báo cáo khấu hao, xác định khoản khấu trừ thuế có thể yêu cầu.",
      "en": "A quantity surveyor prepares a depreciation schedule, which determines the tax deductions you can claim."
    },
    "action_contract_inspect_building_pest_label": {
      "vi": "Kiểm tra nhà và kiểm tra mối",
      "en": "Building and pest inspections"
    },
    "action_contract_inspect_building_pest_detail": {
      "vi": "Đặt hai cuộc kiểm tra riêng — kết cấu và mối/mọt — vì nhà cũ không có bảo hành xây dựng theo luật.",
      "en": "Book two separate inspections — structural and timber pest — because an established home has no statutory builder's warranty."
    },
    "action_contract_review_contract_label": {
      "vi": "Luật sư rà soát hợp đồng",
      "en": "Have your conveyancer review the contract"
    },
    "action_contract_review_contract_detail": {
      "vi": "Để chuyên viên chuyển nhượng hoặc luật sư rà soát hợp đồng trước khi bạn ký, kể cả tên pháp nhân đứng mua.",
      "en": "Have your conveyancer or solicitor review the contract before signing, including the purchasing entity's name."
    },
    "action_contract_decide_offer_strategy_label": {
      "vi": "Quyết định cách ra giá theo kỷ luật lợi suất",
      "en": "Decide your yield-anchored offer strategy"
    },
    "action_contract_decide_offer_strategy_detail": {
      "vi": "Đặt một mức giá tối đa dựa trên lợi suất mục tiêu và giữ kỷ luật đó, dù mua theo thương lượng hay đấu giá.",
      "en": "Set a maximum price anchored to your target yield and hold that discipline, whether buying by private treaty or at auction."
    },
    "action_contract_pay_deposit_label": {
      "vi": "Đặt cọc khi ký hợp đồng",
      "en": "Pay the deposit on exchange"
    },
    "action_contract_pay_deposit_detail": {
      "vi": "Tiền cọc được nộp khi ký hợp đồng và giữ trong tài khoản ủy thác cho đến khi bàn giao.",
      "en": "The deposit is paid on exchange and held in trust until settlement."
    },
    "action_contract_seek_unconditional_label": {
      "vi": "Xin duyệt vay chính thức (vô điều kiện)",
      "en": "Submit for unconditional loan approval"
    },
    "action_contract_seek_unconditional_detail": {
      "vi": "Hoàn tất hồ sơ để ngân hàng duyệt vay đầu tư chính thức trong thời hạn điều kiện “tùy thuộc duyệt vay”.",
      "en": "Complete the lender's requirements for unconditional investment-loan approval within your subject-to-finance deadline."
    },

    "action_settle_pay_stamp_duty_label": {
      "vi": "Nộp thuế trước bạ",
      "en": "Pay stamp duty"
    },
    "action_settle_pay_stamp_duty_detail": {
      "vi": "Thuế trước bạ đến hạn nộp khi bàn giao — không có ưu đãi cho người mua nhà lần đầu.",
      "en": "Stamp duty falls due at settlement — no first-home concession applies."
    },
    "action_settle_settle_other_costs_label": {
      "vi": "Thanh toán các chi phí mua nhà còn lại",
      "en": "Pay the remaining buying costs"
    },
    "action_settle_settle_other_costs_detail": {
      "vi": "Phí chuyển nhượng, phí đăng bộ, và bảo hiểm năm đầu được thanh toán khi bàn giao.",
      "en": "Conveyancing, registration fees and first-year insurance are paid at settlement."
    },
    "action_settle_complete_entity_setup_label": {
      "vi": "Hoàn tất lập pháp nhân (nếu dùng)",
      "en": "Complete entity setup (if applicable)"
    },
    "action_settle_complete_entity_setup_detail": {
      "vi": "Nếu dùng quỹ ủy thác hay công ty, hoàn tất thủ tục lập pháp nhân đúng thời hạn để không làm chậm bàn giao.",
      "en": "If using a trust or company, complete the entity's setup in time so it doesn't delay settlement."
    },
    "action_settle_engage_qs_label": {
      "vi": "Thuê chuyên viên khảo sát khối lượng",
      "en": "Engage a quantity surveyor"
    },
    "action_settle_engage_qs_detail": {
      "vi": "Đặt lịch lập báo cáo khấu hao sớm sau khi bàn giao để bắt đầu khấu trừ thuế từ năm đầu.",
      "en": "Book the depreciation schedule soon after settlement so deductions start from year one."
    },
    "action_settle_appoint_pm_label": {
      "vi": "Chỉ định đơn vị quản lý cho thuê",
      "en": "Appoint a property manager"
    },
    "action_settle_appoint_pm_detail": {
      "vi": "Chọn quản lý chuyên nghiệp hay tự quản lý; thời gian nhà trống càng ngắn, dòng tiền càng ổn định.",
      "en": "Choose professional management or self-manage; the shorter the vacancy, the steadier the cash flow."
    },
    "action_settle_bind_landlord_insurance_label": {
      "vi": "Mua bảo hiểm cho chủ nhà cho thuê",
      "en": "Bind landlord insurance"
    },
    "action_settle_bind_landlord_insurance_detail": {
      "vi": "Bảo hiểm cho chủ nhà cho thuê khác với bảo hiểm nhà ở thông thường — bao gồm mất tiền thuê và thiệt hại do người thuê.",
      "en": "Landlord insurance differs from standard home insurance — it covers lost rent and tenant damage."
    },
    "action_settle_settlement_completes_label": {
      "vi": "Hoàn tất bàn giao",
      "en": "Settlement completes"
    },
    "action_settle_settlement_completes_detail": {
      "vi": "Việc bàn giao hoàn tất qua PEXA; ngân hàng giải ngân và sổ được sang tên cho bạn (hoặc pháp nhân của bạn).",
      "en": "Settlement completes via PEXA; the lender releases funds and the title transfers to you (or your entity)."
    },

    "action_own_track_cash_flow_label": {
      "vi": "Theo dõi dòng tiền thực tế",
      "en": "Track actual cash flow"
    },
    "action_own_track_cash_flow_detail": {
      "vi": "So sánh dòng tiền thực tế với dự tính hằng tháng; điều chỉnh nếu tiền thuê hoặc chi phí lệch nhiều.",
      "en": "Compare actual cash flow against the projection monthly; adjust if rent or costs drift significantly."
    },
    "action_own_lodge_annual_return_label": {
      "vi": "Nộp tờ khai thuế hằng năm",
      "en": "Lodge your annual tax return"
    },
    "action_own_lodge_annual_return_detail": {
      "vi": "Kê khai thu nhập cho thuê, chi phí, và khấu hao; nếu lỗ cho thuê được khấu trừ, khoản hoàn thuế phản ánh trong dòng tiền sau thuế.",
      "en": "Declare rental income, expenses, and depreciation; if negatively geared, the tax refund shows up in your after-tax cash flow."
    },
    "action_own_monitor_land_tax_label": {
      "vi": "Theo dõi thuế đất",
      "en": "Monitor land tax"
    },
    "action_own_monitor_land_tax_detail": {
      "vi": "Bất động sản đầu tư không được miễn thuế đất; nếu có nhiều bất động sản, giá trị đất có thể được cộng dồn để tính thuế.",
      "en": "Investment property has no land-tax exemption; if you hold multiple properties, land values may be aggregated for assessment."
    },
    "action_own_watch_equity_release_label": {
      "vi": "Theo dõi cơ hội rút vốn chủ sở hữu",
      "en": "Watch for an equity-release window"
    },
    "action_own_watch_equity_release_detail": {
      "vi": "Khi tỷ lệ vay trên giá trị giảm và giá trị nhà tăng, cơ hội tái cấp vốn để mua thêm bất động sản có thể mở ra.",
      "en": "As your loan-to-value ratio falls and the property's value grows, a refinance window to fund your next purchase may open."
    },
    "action_own_review_pm_performance_label": {
      "vi": "Xem lại hiệu quả quản lý cho thuê",
      "en": "Review property-management performance"
    },
    "action_own_review_pm_performance_detail": {
      "vi": "Xem lại mức phí, thời gian nhà trống, và chất lượng chăm sóc người thuê định kỳ hằng năm.",
      "en": "Review fees, vacancy periods, and tenant-care quality on an annual cadence."
    },

    "action_dispose_decide_to_sell_label": {
      "vi": "Quyết định bán và chọn thời điểm",
      "en": "Decide to sell and set your timing"
    },
    "action_dispose_decide_to_sell_detail": {
      "vi": "Số năm giữ nhà và chiến lược thoát vốn đã đặt ra định hình khi nào bán hợp lý; kế hoạch chiếu một dải ước tính thận trọng, không phải dự báo.",
      "en": "Your hold period and exit strategy shape when selling makes sense; the plan projects a conservative band, not a forecast."
    },
    "action_dispose_engage_selling_agent_label": {
      "vi": "Chọn đại lý bán và thỏa thuận hoa hồng",
      "en": "Engage a selling agent and agree the commission"
    },
    "action_dispose_engage_selling_agent_detail": {
      "vi": "Hoa hồng đại lý có thể thương lượng; các khoản này cùng chi phí pháp lý và tiếp thị làm giảm phần vốn ròng bạn thu về.",
      "en": "Agent commission is negotiable; together with legal and marketing costs, these reduce the net proceeds you walk away with."
    },
    "action_dispose_confirm_cgt_position_label": {
      "vi": "Xác nhận vị trí thuế lãi vốn (CGT)",
      "en": "Confirm your capital gains tax (CGT) position"
    },
    "action_dispose_confirm_cgt_position_detail": {
      "vi": "Khác với nhà ở chính, bất động sản đầu tư không được miễn thuế lãi vốn; giảm 50% có thể áp dụng nếu giữ trên 12 tháng — xác nhận với chuyên viên thuế đã đăng ký trước khi bán.",
      "en": "Unlike a main residence, an investment property has no CGT exemption; a 50% discount may apply if held over 12 months — confirm with a registered tax agent before selling."
    },
    "action_dispose_discharge_mortgage_label": {
      "vi": "Sắp xếp tất toán khoản vay còn lại",
      "en": "Arrange to discharge your remaining loan"
    },
    "action_dispose_discharge_mortgage_detail": {
      "vi": "Khoản vay còn lại được trả cho ngân hàng từ tiền bán nhà khi hoàn tất giao dịch; phần còn lại sau chi phí bán, thuế và tất toán vay là vốn ròng của bạn.",
      "en": "Your remaining loan is repaid to the lender from the sale proceeds at settlement; what's left after selling costs, tax and the loan payout is your net equity."
    },
    "action_dispose_plan_next_purchase_label": {
      "vi": "Lập kế hoạch dùng vốn ròng cho bất động sản tiếp theo",
      "en": "Plan how your net equity funds your next property"
    },
    "action_dispose_plan_next_purchase_detail": {
      "vi": "Vốn ròng thu về sau khi bán có thể trở thành vốn cho bất động sản tiếp theo trong danh mục đầu tư.",
      "en": "The net equity realised at sale can become the funding for the next property in your portfolio."
    },

    "assumption_indicative": {
      "vi": "Đây là danh sách hành động tổng quát cho nhà đầu tư bất động sản trong nước tại Úc; thứ tự và thời điểm cụ thể thay đổi theo tiểu bang và theo giao dịch của bạn.",
      "en": "This is a general action list for a domestic property investor in Australia; the exact order and timing vary by state and by your specific transaction."
    },
    "assumption_informational": {
      "vi": "Đây là thông tin tham khảo, không phải tư vấn tài chính, thuế, hay pháp lý. Hãy xác nhận với chuyên gia có giấy phép trước khi quyết định.",
      "en": "This is general information, not financial, tax, or legal advice. Confirm with a licensed professional before you decide."
    }
  }
}
```
