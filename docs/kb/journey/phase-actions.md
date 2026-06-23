---
slug: kb.journey.phase-actions
effective_from: 2026-06-01
last_verified: 2026-06-20
---

# Mode-A FHB per-phase action checklist (bilingual)

The **actionable layer** of the legal/temporal spine — for each lifecycle phase (Prepare →
Pre-approve → Contract → Settle → Own → Sell), the ordered "do these, in this sequence" steps
a Mode-A first-home buyer works through. The terminal **Sell** (`dispose`) phase is the full
temporal arc (lifecycle-simulation-model §8); its actions link to the `disposition` component
for the sale / cost / net figures (`component_ref`, no `budget_ref` — the dispose figures live
on `disposition.dispose_cash_events`, not the acquisition `budget_envelope.cash_events`). It is the content the `phase_playbook` resolver
(component 12) renders as a `checklist` behind each Flow-view phase sheet. The swimlane
(`kb.journey.fhg-path`) shows *what happens*; this doc turns that into *what you do, in what
order*.

**It stores no figures.** An action may carry a `budget_ref` — the `id` of a `cash_event`
the buyer's calculator already computed (`deposit`, `stamp_duty`, `other_buying_costs`) — so
the checklist item and its money consequence pair on the same `phase`. The **id** is
referenced; the **amount** is joined at render from `budget_envelope.cash_events`, never
recomputed or stored here (one-computer-per-figure, extended to this consumer). An action may
also carry a `component_ref` — the id of a component whose renderer opens as the item's
backing detail (e.g. `eligibility` behind "Reserve a First Home Guarantee place"). Both are
optional; `null` means no link.

This is a **copy doc** (it fills no slot). It is a blueprint anchor (component 12 references
it), so it must resolve; structurally only slug==path + content_json-parse + the bilingual
copy gate apply. Vietnamese is authored for register, not transliterated from the English
(trap #4). Decision-support tone, never advice (ASIC): the checklist is informational ("do
these in this order"), and the steps that touch finance, credit or law direct the buyer to
the relevant licensed professional — the buyer decides. `status` is a **user-attested** fact
(`not_started | done`): the resolver seeds every action `not_started`; the user sets it, and
the effective value is stored in the card's **user-set layer** so a recompute never clobbers
it (engine-contract §10.4, lifecycle-simulation-model §7.4a — the same mechanism
`preparation.document_checklist[].status` uses).

## Rules

Everything above is `content_md`. The `content_json` below has two parts:

- `layout.phases[]` — the **structure** the resolver reads: per phase, an ordered `actions[]`
  list, each with a stable `id`, `order` (temporal sequence within the phase),
  `budget_ref` (a `cash_event.id` or `null`) and `component_ref` (a component id or `null`).
  The label/detail prose is referenced by convention: `action_<phase>_<id>_label` and
  `action_<phase>_<id>_detail` in `copy`.
- `copy` — the flat `{vi, en}` prose templates (the bilingual-gated part), plus the
  `assumption_*` lines.

Resolver mapping (the shape `fh_engine_phase_playbook` assembles, W-slice 2): for each
`layout.phases[].actions[]` entry, emit `{ id, order, budget_ref, component_ref, label ←
action_<phase>_<id>_label, detail ← action_<phase>_<id>_detail, status: not_started }`,
sorted by `order`. **Honest-partial:** if a `budget_ref` does not match any `cash_event.id`
present in the buyer's `budget_envelope`, drop the ref (set `null`) — never fabricate a
figure. `key_assumptions[]` ← the `assumption_*` lines.

```jsonc
{
  "fills": [],
  "layout": {
    "phases": [
      {
        "phase": "prepare",
        "actions": [
          { "id": "build_deposit",       "order": 1, "budget_ref": "deposit", "component_ref": "cash_position" },
          { "id": "check_eligibility",   "order": 2, "budget_ref": null,      "component_ref": "eligibility" },
          { "id": "set_up_fhss",         "order": 3, "budget_ref": null,      "component_ref": "eligibility" },
          { "id": "compare_borrowing",   "order": 4, "budget_ref": null,      "component_ref": "mortgage_finance" },
          { "id": "gather_documents",    "order": 5, "budget_ref": null,      "component_ref": "preparation" }
        ]
      },
      {
        "phase": "pre_approve",
        "actions": [
          { "id": "consider_broker",     "order": 1, "budget_ref": null, "component_ref": "mortgage_finance" },
          { "id": "submit_preapproval",  "order": 2, "budget_ref": null, "component_ref": "mortgage_finance" },
          { "id": "reserve_fhg",         "order": 3, "budget_ref": null, "component_ref": "eligibility" },
          { "id": "note_validity",       "order": 4, "budget_ref": null, "component_ref": "mortgage_finance" }
        ]
      },
      {
        "phase": "contract",
        "actions": [
          { "id": "inspect_building_pest", "order": 1, "budget_ref": null,      "component_ref": "due_diligence" },
          { "id": "review_contract",       "order": 2, "budget_ref": null,      "component_ref": "due_diligence" },
          { "id": "decide_offer_strategy", "order": 3, "budget_ref": null,      "component_ref": "buying_strategy" },
          { "id": "include_conditions",    "order": 4, "budget_ref": null,      "component_ref": "buying_strategy" },
          { "id": "pay_deposit",           "order": 5, "budget_ref": "deposit", "component_ref": "cash_position" },
          { "id": "lodge_concession",      "order": 6, "budget_ref": null,      "component_ref": "eligibility" },
          { "id": "seek_unconditional",    "order": 7, "budget_ref": null,      "component_ref": "mortgage_finance" }
        ]
      },
      {
        "phase": "settle",
        "actions": [
          { "id": "bind_insurance",       "order": 1, "budget_ref": null,                "component_ref": "settlement_prep" },
          { "id": "pay_stamp_duty",       "order": 2, "budget_ref": "stamp_duty",        "component_ref": "cash_position" },
          { "id": "settle_other_costs",   "order": 3, "budget_ref": "other_buying_costs","component_ref": "cash_position" },
          { "id": "final_inspection",     "order": 4, "budget_ref": null,                "component_ref": "settlement_prep" },
          { "id": "settlement_completes", "order": 5, "budget_ref": null,                "component_ref": "settlement_prep" }
        ]
      },
      {
        "phase": "own",
        "actions": [
          { "id": "move_in",         "order": 1, "budget_ref": null, "component_ref": "ownership_planning" },
          { "id": "budget_ongoing",  "order": 2, "budget_ref": null, "component_ref": "ownership_planning" },
          { "id": "keep_ppor",       "order": 3, "budget_ref": null, "component_ref": "ownership_planning" },
          { "id": "watch_refinance", "order": 4, "budget_ref": null, "component_ref": "ownership_planning" }
        ]
      },
      {
        "phase": "dispose",
        "actions": [
          { "id": "decide_to_sell",        "order": 1, "budget_ref": null, "component_ref": "disposition" },
          { "id": "engage_selling_agent",  "order": 2, "budget_ref": null, "component_ref": "disposition" },
          { "id": "confirm_cgt_exemption", "order": 3, "budget_ref": null, "component_ref": "disposition" },
          { "id": "discharge_mortgage",    "order": 4, "budget_ref": null, "component_ref": "disposition" },
          { "id": "plan_next_purchase",    "order": 5, "budget_ref": null, "component_ref": "disposition" }
        ]
      }
    ]
  },
  "copy": {
    "action_prepare_build_deposit_label": {
      "vi": "Tích lũy tiền cọc và lịch sử tiết kiệm",
      "en": "Build your deposit and savings record"
    },
    "action_prepare_build_deposit_detail": {
      "vi": "Tích lũy tiền cọc đều đặn theo thời gian; nhiều ngân hàng xem khoản tiết kiệm tích lũy này là “genuine savings” khi xét duyệt vay.",
      "en": "Build your deposit steadily over time; many lenders treat a track record of saved funds as “genuine savings” when assessing your loan."
    },
    "action_prepare_check_eligibility_label": {
      "vi": "Kiểm tra các chương trình bạn đủ điều kiện",
      "en": "Check which schemes you qualify for"
    },
    "action_prepare_check_eligibility_detail": {
      "vi": "Xem bạn có đủ điều kiện cho Bảo lãnh Người mua nhà lần đầu (FHG), FHSS và ưu đãi thuế trước bạ của tiểu bang hay không.",
      "en": "See whether you qualify for the First Home Guarantee (FHG), FHSS, and your state's stamp-duty concession."
    },
    "action_prepare_set_up_fhss_label": {
      "vi": "Nếu dùng FHSS, đóng góp sớm",
      "en": "If using FHSS, contribute early"
    },
    "action_prepare_set_up_fhss_detail": {
      "vi": "Các khoản đóng góp tự nguyện vào FHSS cần thời gian; việc rút ra phải có quyết định xác định (determination) của ATO trước khi bạn cần dùng tiền.",
      "en": "FHSS voluntary contributions take time to build, and withdrawing them needs an ATO determination before you need the funds."
    },
    "action_prepare_compare_borrowing_label": {
      "vi": "So sánh khả năng vay giữa các ngân hàng",
      "en": "Compare borrowing capacity across lenders"
    },
    "action_prepare_compare_borrowing_detail": {
      "vi": "Khả năng vay khác nhau giữa các ngân hàng và bị giảm bởi khoản vay HECS, thẻ tín dụng và mua-trả-sau (BNPL); hãy tính đến các khoản này.",
      "en": "Borrowing capacity differs between lenders and is reduced by HECS, credit cards and buy-now-pay-later limits; account for these."
    },
    "action_prepare_gather_documents_label": {
      "vi": "Chuẩn bị giấy tờ hồ sơ vay",
      "en": "Gather your loan documents"
    },
    "action_prepare_gather_documents_detail": {
      "vi": "Giấy tờ tùy thân có ảnh, phiếu lương, Thông báo quyết toán thuế (NOA) và sao kê ngân hàng — xem danh sách chuẩn bị đầy đủ.",
      "en": "Photo ID, payslips, your Notice of Assessment (NOA) and bank statements — see the full readiness list."
    },

    "action_pre_approve_consider_broker_label": {
      "vi": "Cân nhắc dùng chuyên viên môi giới vay",
      "en": "Consider a mortgage broker"
    },
    "action_pre_approve_consider_broker_detail": {
      "vi": "Một chuyên viên môi giới vay có thể so sánh nhiều ngân hàng và giải thích các chương trình hỗ trợ; bạn vẫn là người quyết định chọn ngân hàng.",
      "en": "A broker can compare lenders and explain the schemes; you still decide which lender to choose."
    },
    "action_pre_approve_submit_preapproval_label": {
      "vi": "Nộp hồ sơ duyệt vay sơ bộ",
      "en": "Apply for pre-approval"
    },
    "action_pre_approve_submit_preapproval_detail": {
      "vi": "Xin duyệt vay sơ bộ có điều kiện để biết ngân sách trước khi đi xem nhà.",
      "en": "Get conditional pre-approval so you know your budget before house-hunting."
    },
    "action_pre_approve_reserve_fhg_label": {
      "vi": "Giữ chỗ trong chương trình FHG (nếu đủ điều kiện)",
      "en": "Reserve a First Home Guarantee place (if eligible)"
    },
    "action_pre_approve_reserve_fhg_detail": {
      "vi": "Suất tham gia chương trình Bảo lãnh Người mua nhà lần đầu có hạn và được giữ chỗ qua một ngân hàng tham gia chương trình; hãy giữ chỗ sớm.",
      "en": "First Home Guarantee places are limited and reserved through a participating lender; reserve yours early."
    },
    "action_pre_approve_note_validity_label": {
      "vi": "Ghi nhớ thời hạn hiệu lực của duyệt vay sơ bộ",
      "en": "Note your pre-approval validity window"
    },
    "action_pre_approve_note_validity_detail": {
      "vi": "Duyệt vay sơ bộ thường có hiệu lực khoảng 90 ngày và có điều kiện; theo dõi ngày hết hạn để không ra giá dựa trên hồ sơ đã cũ.",
      "en": "Pre-approval is typically valid for about 90 days and is conditional; track the expiry so you don't make an offer on a stale approval."
    },

    "action_contract_inspect_building_pest_label": {
      "vi": "Kiểm tra nhà và kiểm tra mối",
      "en": "Building and pest inspections"
    },
    "action_contract_inspect_building_pest_detail": {
      "vi": "Đặt hai cuộc kiểm tra riêng — kiểm tra kết cấu nhà và kiểm tra mối/mọt — vì nhà cũ không có bảo hành xây dựng theo luật.",
      "en": "Book two separate inspections — building and timber pest — because an established home has no statutory builder's warranty."
    },
    "action_contract_review_contract_label": {
      "vi": "Luật sư rà soát hợp đồng / Mục 32",
      "en": "Have your conveyancer review the contract / Section 32"
    },
    "action_contract_review_contract_detail": {
      "vi": "Để chuyên viên chuyển nhượng hoặc luật sư rà soát hợp đồng (và bản tiết lộ Mục 32 ở VIC) trước khi bạn ký.",
      "en": "Have your conveyancer or solicitor review the contract (and the Section 32 disclosure in VIC) before you sign."
    },
    "action_contract_decide_offer_strategy_label": {
      "vi": "Quyết định cách ra giá và mức giá dừng",
      "en": "Decide your offer strategy and walk-away price"
    },
    "action_contract_decide_offer_strategy_detail": {
      "vi": "Định giá độc lập từ các căn so sánh và đặt một mức giá tối đa bạn sẽ dừng lại, dù mua theo thương lượng hay đấu giá.",
      "en": "Value independently from comparable sales and set a maximum walk-away price, whether buying by private treaty or at auction."
    },
    "action_contract_include_conditions_label": {
      "vi": "Đưa điều kiện bảo vệ vào lời đề nghị (mua thương lượng)",
      "en": "Include protective conditions in a private-treaty offer"
    },
    "action_contract_include_conditions_detail": {
      "vi": "Khi mua theo thương lượng, đề nghị các điều kiện “tùy thuộc duyệt vay” và “tùy thuộc kết quả kiểm tra” — chúng không áp dụng khi đấu giá.",
      "en": "On a private-treaty offer, request subject-to-finance and subject-to-inspection conditions — they are not available at auction."
    },
    "action_contract_pay_deposit_label": {
      "vi": "Đặt cọc khi ký hợp đồng",
      "en": "Pay the deposit on exchange"
    },
    "action_contract_pay_deposit_detail": {
      "vi": "Tiền cọc (thường khoảng 10%) được nộp khi ký hợp đồng và giữ trong tài khoản ủy thác cho đến khi bàn giao.",
      "en": "The deposit (commonly around 10%) is paid on exchange and held in trust until settlement."
    },
    "action_contract_lodge_concession_label": {
      "vi": "Nộp hồ sơ xin ưu đãi thuế trước bạ",
      "en": "Lodge your stamp-duty concession"
    },
    "action_contract_lodge_concession_detail": {
      "vi": "Hồ sơ xin miễn/giảm thuế trước bạ của tiểu bang thường được nộp khi ký hợp đồng, qua chuyên viên chuyển nhượng của bạn.",
      "en": "Your state stamp-duty concession or exemption is usually lodged at contract, through your conveyancer."
    },
    "action_contract_seek_unconditional_label": {
      "vi": "Xin duyệt vay chính thức (vô điều kiện)",
      "en": "Submit for unconditional loan approval"
    },
    "action_contract_seek_unconditional_detail": {
      "vi": "Hoàn tất hồ sơ để ngân hàng duyệt vay chính thức trong thời hạn của điều kiện “tùy thuộc duyệt vay”.",
      "en": "Complete the lender's requirements for unconditional approval within your subject-to-finance deadline."
    },

    "action_settle_bind_insurance_label": {
      "vi": "Mua bảo hiểm nhà từ thời điểm rủi ro chuyển sang bạn",
      "en": "Bind building insurance from when risk passes"
    },
    "action_settle_bind_insurance_detail": {
      "vi": "Ở QLD rủi ro chuyển sang người mua ngay ngày làm việc kế tiếp sau khi ký hợp đồng; ở NSW và VIC là từ lúc bàn giao. Mua bảo hiểm có hiệu lực từ đúng thời điểm đó.",
      "en": "In QLD risk passes to the buyer the business day after contract; in NSW and VIC it passes at settlement. Hold insurance effective from that point."
    },
    "action_settle_pay_stamp_duty_label": {
      "vi": "Nộp thuế trước bạ",
      "en": "Pay stamp duty"
    },
    "action_settle_pay_stamp_duty_detail": {
      "vi": "Thuế trước bạ (đã trừ ưu đãi nếu có) đến hạn nộp khi bàn giao.",
      "en": "Stamp duty (net of any concession) falls due at settlement."
    },
    "action_settle_settle_other_costs_label": {
      "vi": "Thanh toán các chi phí mua nhà còn lại",
      "en": "Pay the remaining buying costs"
    },
    "action_settle_settle_other_costs_detail": {
      "vi": "Phí chuyển nhượng, phí đăng bộ và các khoản điều chỉnh được thanh toán khi bàn giao.",
      "en": "Conveyancing, registration fees and adjustments are paid at settlement."
    },
    "action_settle_final_inspection_label": {
      "vi": "Kiểm tra lần cuối trước khi bàn giao",
      "en": "Final inspection before settlement"
    },
    "action_settle_final_inspection_detail": {
      "vi": "Kiểm tra lần cuối để xác nhận tình trạng nhà và các hạng mục kèm theo đúng như hợp đồng.",
      "en": "Do a final inspection to confirm the property's condition and agreed inclusions match the contract."
    },
    "action_settle_settlement_completes_label": {
      "vi": "Hoàn tất bàn giao",
      "en": "Settlement completes"
    },
    "action_settle_settlement_completes_detail": {
      "vi": "Việc bàn giao hoàn tất qua PEXA; ngân hàng giải ngân và sổ được sang tên cho bạn.",
      "en": "Settlement completes via PEXA; the lender releases funds and the title transfers to you."
    },

    "action_own_move_in_label": {
      "vi": "Dọn vào ở",
      "en": "Move in"
    },
    "action_own_move_in_detail": {
      "vi": "Dọn vào ở; chương trình bảo lãnh FHG kết thúc khi tỷ lệ vay trên giá trị (LVR) của bạn còn 80%.",
      "en": "Move in; the First Home Guarantee falls away once your loan-to-value ratio (LVR) reaches 80%."
    },
    "action_own_budget_ongoing_label": {
      "vi": "Lập ngân sách cho chi phí định kỳ",
      "en": "Budget for ongoing costs"
    },
    "action_own_budget_ongoing_detail": {
      "vi": "Thuế suất hội đồng (council rates), tiền nước và phí chung cư (nếu có) là các khoản chi định kỳ — hãy dự trù và giữ một khoản dự phòng.",
      "en": "Council rates, water and strata (if applicable) are recurring — plan for them and keep a buffer."
    },
    "action_own_keep_ppor_label": {
      "vi": "Giữ nhà là nơi ở chính của bạn",
      "en": "Keep the home as your principal residence"
    },
    "action_own_keep_ppor_detail": {
      "vi": "Việc miễn thuế đất và cơ sở “ở để dùng” của các chương trình phụ thuộc vào việc đây là nơi ở chính của bạn; hãy hỏi chuyên gia trước khi đổi mục đích sử dụng.",
      "en": "Your land-tax exemption and the owner-occupier basis of your schemes depend on this staying your principal home; get advice before changing its use."
    },
    "action_own_watch_refinance_label": {
      "vi": "Theo dõi cơ hội tái cấp vốn",
      "en": "Watch for a refinance window"
    },
    "action_own_watch_refinance_detail": {
      "vi": "Khi LVR xuống dưới 80%, cơ hội tái cấp vốn sang lãi suất tốt hơn có thể mở ra.",
      "en": "Once your LVR drops below 80%, a window to refinance to a better rate may open."
    },

    "action_dispose_decide_to_sell_label": {
      "vi": "Quyết định bán và chọn thời điểm",
      "en": "Decide to sell and set your timing"
    },
    "action_dispose_decide_to_sell_detail": {
      "vi": "Số năm bạn giữ nhà (hold horizon) và điều kiện thị trường khi bán quyết định số tiền thu về; kế hoạch chiếu một dải ước tính thận trọng, không phải dự báo.",
      "en": "How long you hold and market conditions at sale shape the proceeds; the plan projects a conservative band, not a forecast."
    },
    "action_dispose_engage_selling_agent_label": {
      "vi": "Chọn đại lý bán và thỏa thuận hoa hồng",
      "en": "Engage a selling agent and agree the commission"
    },
    "action_dispose_engage_selling_agent_detail": {
      "vi": "Hoa hồng đại lý có thể thương lượng và thường vào khoảng 1,5%–3,5% giá bán, cộng chi phí pháp lý và tiếp thị; các khoản này làm giảm phần vốn bạn thu về.",
      "en": "Agent commission is negotiable and conventionally around 1.5%–3.5% of the sale price, plus legal and marketing costs; these reduce the equity you walk away with."
    },
    "action_dispose_confirm_cgt_exemption_label": {
      "vi": "Xác nhận quyền miễn thuế lãi vốn cho nhà ở chính",
      "en": "Confirm your main-residence CGT exemption"
    },
    "action_dispose_confirm_cgt_exemption_detail": {
      "vi": "Nhà ở chính thường được miễn thuế lãi vốn (CGT). Nếu bạn từng cho thuê nhà, đã dọn ra nước ngoài và thành người không cư trú về thuế, hoặc đất rộng hơn 2 ha, hãy hỏi chuyên viên thuế trước khi bán.",
      "en": "Your main residence is generally CGT-exempt. If you've ever rented it out, moved overseas and become a non-resident for tax, or the land is over 2 hectares, confirm with a tax professional before selling."
    },
    "action_dispose_discharge_mortgage_label": {
      "vi": "Sắp xếp tất toán khoản vay còn lại",
      "en": "Arrange to discharge your remaining loan"
    },
    "action_dispose_discharge_mortgage_detail": {
      "vi": "Khoản vay còn lại được trả cho ngân hàng từ tiền bán nhà khi hoàn tất giao dịch; phần còn lại sau chi phí bán và tất toán vay là vốn ròng của bạn.",
      "en": "Your remaining loan is repaid to the lender from the sale proceeds at settlement; what's left after selling costs and the loan payout is your net equity."
    },
    "action_dispose_plan_next_purchase_label": {
      "vi": "Lập kế hoạch dùng vốn ròng cho lần mua tiếp theo",
      "en": "Plan how your net equity funds your next purchase"
    },
    "action_dispose_plan_next_purchase_detail": {
      "vi": "Vốn ròng thu về sau khi bán có thể trở thành tiền cọc cho căn nhà tiếp theo — câu chuyện nâng cấp dần của người mua nhà lần đầu.",
      "en": "The net equity realised at sale can become the deposit for your next home — the step-up story for a first-home buyer."
    },

    "assumption_indicative": {
      "vi": "Đây là danh sách hành động tổng quát cho người mua nhà lần đầu tại Úc; thứ tự và thời điểm cụ thể thay đổi theo tiểu bang và theo giao dịch của bạn.",
      "en": "This is a general action list for first-home buyers in Australia; the exact order and timing vary by state and by your specific transaction."
    },
    "assumption_informational": {
      "vi": "Đây là thông tin tham khảo, không phải tư vấn tài chính hay pháp lý. Hãy xác nhận với chuyên gia có giấy phép trước khi quyết định.",
      "en": "This is general information, not financial or legal advice. Confirm with a licensed professional before you decide."
    }
  }
}
```
