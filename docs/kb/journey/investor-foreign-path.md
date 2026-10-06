---
slug: kb.journey.investor-foreign-path
effective_from: 2026-07-10
last_verified: 2026-07-10
---

# Mode-D foreign-investor lifecycle journey (bilingual)

The whole-of-journey template for a Mode-D Vietnam-located-investor purchase — the **swimlane**
the `purchase_journey` resolver (`fh_engine_journey`, Mode-D branch) renders. Same shape as Mode
C's `kb.journey.investor-path` (phases × actors × cells, plan-card-lifecycle-restoration.md §3.3,
§11.2/§11.3) with Mode D's content layered on top: a **FIRB approval gate**, a **cross-border
currency-transfer milestone**, **entity setup**, **non-resident tax treatment**, and **rental-income
repatriation** — the five concepts §3.3 named for Mode D's journey (`FIRB gate + transfer + entity
+ non-resident tax + repatriation`).

**Actors — reuses Mode C's six unchanged, no new row added.** You / Government / Lender /
Property manager / Tenant / Services. The swimlane's actor set must be a superset of every
cash_event counterparty this mode's figure-owners emit (`cash_position`, `yield_modelling`,
`tax_structure_non_resident`, `disposition`); every one of those — government (FIRB fee, stamp
duty + surcharge, land tax, FRCGW), lender (non-resident loan), tenant (rent), property_manager
(management fee) — already sits inside Mode C's six. The cross-border transfer provider (Wise,
OFX, bank wire) is a **service the investor engages once, not a party with a recurring
relationship** the way tenant/property_manager are — the same bucket `services` already holds for
the conveyancer and quantity surveyor — so it renders as `services` cells, not a seventh actor
row. VN-side capital-control steps (SBV threshold check, declared-purpose documentation) are
`you`/`services` prose too, not a jurisdiction-ambiguous `government` cell (AU FIRB and VN SBV are
two different governments; collapsing them into one `government` row would blur which
jurisdiction's obligation a cell is narrating).

**Phases.** Same six phase ids as Modes A/C (`prepare → pre_approve → contract → settle → own →
dispose`). The **FIRB gate** is not a seventh phase — it is the literal condition-precedent
narrated across `pre_approve` (application prepared/submitted) through `contract` (bid made
subject to approval) to `settle` (approval confirmed, fee paid) — mirroring how §11.2 places
`firb_workflow` as a Flow *gating phase*, not its own tab. The **cross-border transfer milestone**
runs the same span: initiated at `contract` (to cover the deposit), completed by `settle` (to
cover the balance) — §3.3's own description. The `own` phase is labelled "Hold" (tenanted, not
lived in), same as Mode C, keeping the `own` id to match `yield_modelling`/`tax_structure_non_
resident`'s own outcome text ("placed at phase `own` over H"). The terminal `dispose` phase
renders only when a hold horizon `H` is set (honest-partial, same rule as every other mode).

**It stores no figures.** Every `{vi, en}` here is prose; the money flows on the timeline are
placed by the resolver from already-computed upstream outcomes — one-computer-per-figure. The
acquisition-phase amounts (deposit, stamp duty + foreign-buyer surcharge, FIRB fee, other buying
costs, entity setup, LMI) come from `cash_position`'s `budget_envelope_investor`; the hold-phase
amounts (rental income, operating expenses, loan interest, the AU tax on rental) come from
`yield_modelling`'s `cash_flow_projection` and `tax_structure_non_resident`'s `tax_optimised_
structure`; the dispose-phase amounts (sale proceeds, selling costs, loan payout, the full-CGT +
FRCGW figure) come from `disposition`'s `dispose_cash_events`.

**Known limitation (flagged, not fixed here — a `cash_position` build, out of scope for this
KB/wiring pass).** Unlike Mode C's `cash_position`, Mode D's `fill_investor_foreign/2` has no
per-property branch yet — every acquisition figure is null even once a property is attached, so
`budget_envelope_investor.cash_events` is `[]` at base **and** stays `[]` today. `yield_modelling`
is shared code with Mode C and already lights up per-property; `tax_structure_non_resident`'s hold-
phase tax figure needs a non-resident marginal-rate KB table that does not exist yet (same honest-
partial gap the blueprint's own component 7 note already discloses). So today's swimlane renders
the full **legal/prose spine** (every phase, every actor cell) but the **money spine** stays
sparse until those two seams close — an honest, not a broken, state.

This is a **copy doc** (it fills no slot). It is a blueprint anchor (component 15, added
2026-07-10 alongside `phase_playbook`), so it must resolve; structurally only slug==path +
content_json-parse + the bilingual copy gate apply. Vietnamese is authored for register, not
transliterated from the English (trap #4). Decision-support tone, never advice (ASIC) — where a
cell touches finance, credit, tax, FIRB, or VN capital-control law, it directs the reader to their
licensed professional (AU tax agent / lawyer, or VN-licensed counsel) rather than recommending.

## Rules

Everything above is `content_md`. The `copy` block below is this doc's `content_json` — the
template ids the resolver references, each a `{vi, en}` pair (no `{param}` placeholders: the
figures are structured `amount` fields, not interpolated into prose).

```jsonc
{
  "fills": [],
  "copy": {
    "phase_prepare":     { "vi": "Chuẩn bị",          "en": "Prepare" },
    "phase_pre_approve": { "vi": "Duyệt vay sơ bộ",   "en": "Pre-approval" },
    "phase_contract":    { "vi": "Ký hợp đồng",       "en": "Contract" },
    "phase_settle":      { "vi": "Bàn giao",          "en": "Settle" },
    "phase_own":         { "vi": "Giữ (cho thuê)",    "en": "Hold" },
    "phase_dispose":     { "vi": "Bán nhà",           "en": "Sell" },

    "actor_you":              { "vi": "Bạn",                          "en": "You" },
    "actor_government":       { "vi": "Nhà nước",                     "en": "Government" },
    "actor_lender":            { "vi": "Ngân hàng",                   "en": "Lender" },
    "actor_property_manager": { "vi": "Đơn vị quản lý cho thuê",      "en": "Property manager" },
    "actor_tenant":            { "vi": "Người thuê nhà",              "en": "Tenant" },
    "actor_services":          { "vi": "Dịch vụ",                     "en": "Services" },

    "cell_prepare_you": {
      "vi": "Xác định chiến lược đầu tư và cân nhắc pháp nhân đứng tên sở hữu, kể cả tình trạng FIRB của bạn với tư cách người nước ngoài.",
      "en": "Clarify your investment thesis and consider your ownership entity, including your FIRB status as a foreign person."
    },
    "cell_prepare_lender": {
      "vi": "So sánh các ngân hàng chấp nhận cho vay đầu tư với người không cư trú — nhóm ngân hàng này hẹp hơn nhiều so với vay trong nước.",
      "en": "Compare lenders willing to fund a non-resident investor — a much narrower pool than the domestic-investor lender list."
    },
    "cell_prepare_services": {
      "vi": "Cân nhắc gặp chuyên viên tư vấn đầu tư tại Việt Nam và kế toán tại Úc để lên kế hoạch pháp nhân, hồ sơ FIRB, và kênh chuyển tiền.",
      "en": "Consider a Vietnam-based investment advisor and an Australian accountant to plan your entity, FIRB application, and transfer channel."
    },

    "cell_pre_approve_you": {
      "vi": "Chuẩn bị hồ sơ: hộ chiếu, bằng chứng cư trú, sao kê ngân hàng, và bằng chứng nguồn vốn hợp pháp.",
      "en": "Gather your documents: passport, residency evidence, bank statements, and evidence of the legitimate source of your funds."
    },
    "cell_pre_approve_lender": {
      "vi": "Nhận duyệt vay đầu tư sơ bộ có điều kiện dành cho người không cư trú; thu nhập từ Việt Nam thường bị tính giảm.",
      "en": "Get conditional non-resident investment-loan pre-approval; income from Vietnam is typically discounted."
    },
    "cell_pre_approve_services": {
      "vi": "Bắt đầu chuẩn bị hồ sơ xin phê duyệt FIRB và liên hệ nhà cung cấp chuyển tiền được cấp phép cho khoản chuyển tiền sắp tới.",
      "en": "Begin preparing the FIRB application and engage a licensed transfer provider ahead of the transfer."
    },

    "cell_contract_you": {
      "vi": "Ra giá với điều kiện tùy thuộc vào việc được FIRB phê duyệt; đặt cọc khi ký hợp đồng.",
      "en": "Bid subject to FIRB approval; pay the deposit on exchange."
    },
    "cell_contract_government": {
      "vi": "Hồ sơ FIRB được nộp và phí được xác định theo giá trị bất động sản; thuế trước bạ đầy đủ cộng phụ phí dành cho người mua nước ngoài sẽ áp dụng — không có ưu đãi cho người mua nhà lần đầu.",
      "en": "The FIRB application is submitted and the fee is determined by property value; full stamp duty plus the foreign-buyer surcharge will apply — no first-home concession."
    },
    "cell_contract_lender": {
      "vi": "Nộp hồ sơ xin duyệt vay chính thức, có điều kiện tùy thuộc vào việc FIRB phê duyệt.",
      "en": "Submit for unconditional loan approval, conditional on FIRB approval."
    },
    "cell_contract_property_manager": {
      "vi": "Đơn vị quản lý cho thuê đưa ra ước tính tiền thuê tham khảo (chỉ áp dụng cho nhà mới xây, do quy định FIRB).",
      "en": "A property manager provides a rental appraisal (new-build only, per the FIRB restriction)."
    },
    "cell_contract_tenant": {
      "vi": "Nếu nhà đang có người thuê, xem lại hợp đồng thuê trước khi ký (thường không áp dụng — người nước ngoài chỉ được mua nhà mới xây).",
      "en": "If already tenanted, review the lease before signing (typically not applicable — foreign persons may only buy new-build stock)."
    },
    "cell_contract_services": {
      "vi": "Kiểm tra nhà và mối (nếu áp dụng); đặt báo giá báo cáo khấu hao; luật sư rà soát hợp đồng; khoản chuyển tiền cho tiền cọc được khởi động.",
      "en": "Building & pest inspection (where relevant); get a depreciation-schedule quote; conveyancer reviews the contract; the deposit transfer is initiated."
    },

    "cell_settle_you": {
      "vi": "Thanh toán phần còn lại — tổng tiền mặt cần để bàn giao, gồm cả phí FIRB và phụ phí người mua nước ngoài.",
      "en": "Pay the balance — the total cash needed to settle, including the FIRB fee and the foreign-buyer surcharge."
    },
    "cell_settle_government": {
      "vi": "Phê duyệt FIRB được xác nhận trước khi bàn giao; thuế trước bạ, phụ phí người mua nước ngoài, và phí FIRB đến hạn nộp.",
      "en": "FIRB approval is confirmed ahead of settlement; stamp duty, the foreign-buyer surcharge, and the FIRB fee fall due."
    },
    "cell_settle_lender": {
      "vi": "Ngân hàng giải ngân khoản vay đầu tư dành cho người không cư trú.",
      "en": "The lender releases the non-resident investment-loan funds."
    },
    "cell_settle_property_manager": {
      "vi": "Chỉ định đơn vị quản lý cho thuê (thường bắt buộc với chủ sở hữu ở nước ngoài); mua bảo hiểm cho chủ nhà cho thuê.",
      "en": "Appoint a property manager (typically required for an offshore owner); bind landlord insurance."
    },
    "cell_settle_services": {
      "vi": "Hoàn tất thủ tục lập pháp nhân (nếu dùng); khoản chuyển tiền cho phần còn lại hoàn tất trước hạn bàn giao; bàn giao hoàn tất qua PEXA.",
      "en": "Complete entity setup (if applicable); the balance transfer completes ahead of the settlement deadline; settlement completes via PEXA."
    },

    "cell_own_you": {
      "vi": "Theo dõi dòng tiền thực tế và lên kế hoạch chuyển lợi nhuận cho thuê về Việt Nam theo tần suất bạn chọn.",
      "en": "Track actual cash flow and plan how often you repatriate rental income to Vietnam."
    },
    "cell_own_government": {
      "vi": "Thuế đất có phụ phí dành cho chủ sở hữu nước ngoài/vắng mặt; khai báo mức độ sử dụng hằng năm để tránh phí bỏ trống; nộp tờ khai thuế thu nhập tại Úc theo hình thức đánh giá (không phải khấu trừ tại nguồn).",
      "en": "Land tax carries a foreign/absentee-owner surcharge; declare occupancy annually to avoid the vacancy fee; lodge an Australian tax return by assessment (not a withholding tax)."
    },
    "cell_own_lender": {
      "vi": "Cơ hội tái cấp vốn hạn chế hơn — cùng nhóm ngân hàng hẹp dành cho người không cư trú.",
      "en": "Refinance opportunities are more limited — the same narrow non-resident lender pool applies."
    },
    "cell_own_property_manager": {
      "vi": "Quản lý việc cho thuê, thu tiền thuê, thanh toán chi phí định kỳ, và có thể xử lý việc chuyển khoản khấu trừ nếu áp dụng.",
      "en": "Manages the tenancy, collects rent, pays recurring outgoings, and may handle withholding remittance where applicable."
    },
    "cell_own_tenant": {
      "vi": "Trả tiền thuê nhà định kỳ.",
      "en": "Pays rent on an ongoing basis."
    },
    "cell_own_services": {
      "vi": "Kế toán tại Úc nộp tờ khai thuế hằng năm; chuyên viên thuế tại Việt Nam xác nhận nghĩa vụ khai báo thu nhập từ Úc.",
      "en": "Your Australian accountant lodges the annual tax return; your Vietnam-side tax adviser confirms the AU-income declaration obligation."
    },

    "cell_dispose_you": {
      "vi": "Quyết định bán và thời điểm bán; khoản khấu trừ FRCGW sẽ được giữ lại tại thời điểm bàn giao và trừ vào thuế lãi vốn phải nộp.",
      "en": "Decide whether and when to sell; the FRCGW withholding will be held back at settlement and credited against the CGT payable."
    },
    "cell_dispose_government": {
      "vi": "Thuế lãi vốn áp dụng đầy đủ — không giảm 50%, không miễn trừ nhà ở chính (vì đây chưa từng là nơi ở); khấu trừ FRCGW của liên bang giữ lại một phần tiền bán tại thời điểm bàn giao.",
      "en": "Capital gains tax applies in full — no 50% discount, no main-residence exemption (it was never a home); the federal FRCGW withholding holds back part of the sale proceeds at settlement."
    },
    "cell_dispose_lender": {
      "vi": "Khoản vay còn lại được tất toán từ tiền bán nhà khi hoàn tất giao dịch.",
      "en": "The remaining loan is discharged from the sale proceeds at settlement."
    },
    "cell_dispose_property_manager": {
      "vi": "Nếu nhà đang có người thuê, phối hợp thời hạn báo trước và bàn giao nhà trống trước khi bán.",
      "en": "If tenanted, coordinates notice periods and vacant possession ahead of the sale."
    },
    "cell_dispose_services": {
      "vi": "Đại lý bán nhà tiếp thị căn nhà; chuyên viên chuyển nhượng lo thủ tục sang tên; vốn ròng thu về được chuyển về Việt Nam qua kênh chuyển tiền được cấp phép.",
      "en": "A selling agent markets the property; your conveyancer handles the transfer; the net proceeds are repatriated to Vietnam via a licensed transfer provider."
    },

    "assumption_indicative": {
      "vi": "Sơ đồ hành trình mang tính tổng quan cho nhà đầu tư ở Việt Nam mua bất động sản tại Úc; mốc thời gian, thứ tự, và các nghĩa vụ FIRB/chuyển tiền có thể thay đổi theo tiểu bang và theo giao dịch cụ thể.",
      "en": "This journey is a general overview for a Vietnam-located investor buying Australian property; timing, order, and FIRB/transfer obligations vary by state and by your specific transaction."
    },
    "assumption_figures": {
      "vi": "Các con số trên dòng thời gian được lấy từ phần tính toán của kế hoạch (tiền cọc, thuế trước bạ, phí FIRB, dòng tiền cho thuê, thuế) — không tính lại tại đây.",
      "en": "The figures on the timeline come from your plan's calculators (deposit, stamp duty, FIRB fee, rental cash flow, tax) — they are not recomputed here."
    },
    "assumption_no_fhb_schemes": {
      "vi": "Không có chương trình hỗ trợ người mua nhà lần đầu nào áp dụng — đây là bất động sản đầu tư mua bởi người nước ngoài, không phải nơi ở chính.",
      "en": "No first-home buyer schemes apply — this is an investment property bought by a foreign person, not a principal place of residence."
    }
  }
}
```
