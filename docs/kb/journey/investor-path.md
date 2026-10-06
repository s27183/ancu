---
slug: kb.journey.investor-path
effective_from: 2026-07-10
last_verified: 2026-07-10
---

# Mode-C investor lifecycle journey (bilingual)

The whole-of-journey template for a Mode-C domestic-investor purchase — the **swimlane** the
`purchase_journey` resolver (`fh_engine_journey`, Mode-C branch) renders. Same shape as Mode A's
`kb.journey.fhg-path` (phases × actors × cells, plan-card-lifecycle-restoration.md §3.3) with
investor-specific content: no owner-occupier move-in, no FHB schemes, an **entity-ownership
decision** instead of scheme selection, and two actor rows Mode A has no need for — **Property
manager** and **Tenant** — because the Own phase is a landlord relationship, not a move-in.

**Actors.** Six rows, not Mode A's four: You / Government / Lender / Property manager / Tenant /
Services. Property manager and Tenant exist because rent is a real, actor-attributable cash flow
(`counterparty: tenant` for the rent inflow, `counterparty: property_manager` for the management
fee outflow) — collapsing them into a generic "Other" row would blur exactly the who-pays-whom
view `interactions` derives from cell counterparties (fhb-domestic-au.md component 10).

**Phases.** Same six phase ids as Mode A (`prepare → pre_approve → contract → settle → own →
dispose`) — investor and FHB journeys share a legal/temporal skeleton; only the content differs.
The `own` phase is labelled "Hold" here, not "Own", because the property is tenanted, not lived
in — but the phase **id** stays `own` to match `yield_modelling`/`tax_structure`'s own outcome
text ("placed at phase `own` over H", investor-domestic-au.md components 5/6). The terminal
`dispose` phase renders only when a hold horizon `H` is set, same honest-partial rule as Mode A.

**It stores no figures.** Every `{vi, en}` here is prose; the money flows on the timeline are
placed by the resolver from already-computed upstream outcomes — one-computer-per-figure. The
acquisition-phase amounts (deposit, stamp duty, other buying costs, entity setup, LMI) come from
`cash_position`'s `budget_envelope_investor`; the hold-phase amounts (rental income, operating
expenses, loan interest, tax refund) come from `yield_modelling`'s `cash_flow_projection` and
`tax_structure`'s `tax_optimised_structure`; the dispose-phase amounts come from `disposition`'s
`dispose_cash_events` (same shape Mode A already places).

**Engine dependency, not yet built (tracked for the restructure's engine-wiring pass).** Unlike
Mode A's `budget_envelope.cash_events`, the current `budget_envelope_investor` / `cash_flow_projection`
/ `tax_optimised_structure` outcome schemas (investor-domestic-au.md components 5/6/7) do **not**
yet carry a `cash_events[]` array — the underlying figures exist (`deposit_amount`,
`annual_gross_rental_income`, `annual_tax_refund_year_1`, …) but are not yet exposed under stable
event ids. This doc declares the **id vocabulary** the resolver will place against once that
array is added; `kb.journey.investor-phase-actions`'s honest-partial rule ("drop the `budget_ref`
if no matching `cash_event.id` exists") covers the interim so no figure is ever fabricated.

- **Acquisition** (`prepare`/`contract`/`settle`): `deposit`, `stamp_duty`, `other_buying_costs`,
  `entity_setup_costs`, `lmi`.
- **Hold** (`own`, recurring/year): `rental_income` (in, counterparty `tenant`), `operating_expenses`
  (out, counterparty `property_manager` — the PM-collected aggregate: management fee, council/water
  rates, insurance, land tax, maintenance), `loan_interest` (out, counterparty `lender`),
  `tax_refund` (in, counterparty `government` — the negative-gearing offset, when applicable).
- **Dispose**: reuses `disposition.dispose_cash_events` unchanged (`sale_proceeds`, `selling_costs`,
  `loan_payout`, `cgt`) — already built, same shape as Mode A.

This is a **copy doc** (it fills no slot). It is a blueprint anchor (component 10 — not yet added
to the pipeline; tracked as the restructure's blueprint-wiring pass), so it must resolve;
structurally only slug==path + content_json-parse + the bilingual copy gate apply. Vietnamese is
authored for register, not transliterated from the English (trap #4). Decision-support tone,
never advice (ASIC) — where a cell touches finance, credit, tax or law, it directs the reader to
their licensed professional rather than recommending.

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
      "vi": "Xác định chiến lược đầu tư: lợi suất mục tiêu, mức tăng trưởng kỳ vọng, và đòn bẩy vay.",
      "en": "Clarify your investment thesis: target yield, expected growth, and gearing approach."
    },
    "cell_prepare_lender": {
      "vi": "So sánh các ngân hàng cho vay đầu tư — khả năng vay bị tính giảm phần thu nhập cho thuê.",
      "en": "Compare investment-loan lenders — rental income is haircut in the serviceability test."
    },
    "cell_prepare_services": {
      "vi": "Cân nhắc gặp kế toán để xác định pháp nhân đứng tên sở hữu (cá nhân, quỹ ủy thác, hay công ty).",
      "en": "Consider an accountant to decide the ownership entity (personal, trust, or company)."
    },

    "cell_pre_approve_you": {
      "vi": "Chuẩn bị hồ sơ: phiếu lương, giấy tờ tùy thân, sao kê ngân hàng, bằng chứng vốn/tài sản hiện có.",
      "en": "Gather your documents: payslips, ID, bank statements, evidence of existing equity."
    },
    "cell_pre_approve_lender": {
      "vi": "Nhận duyệt vay đầu tư sơ bộ có điều kiện; quyết định vay chỉ trả lãi hay trả gốc và lãi.",
      "en": "Get conditional investment-loan pre-approval; decide interest-only vs principal & interest."
    },
    "cell_pre_approve_services": {
      "vi": "Cân nhắc dùng chuyên viên môi giới vay chuyên về khoản vay đầu tư.",
      "en": "Consider a broker who specialises in investment lending."
    },

    "cell_contract_you": {
      "vi": "Ra giá theo kỷ luật lợi suất mục tiêu; đặt cọc khi ký hợp đồng.",
      "en": "Bid within your yield-anchored discipline; pay the deposit on exchange."
    },
    "cell_contract_government": {
      "vi": "Thuế trước bạ được tính — không có ưu đãi cho người mua nhà lần đầu vì đây là bất động sản đầu tư.",
      "en": "Stamp duty applies in full — no first-home concession, since this is an investment property."
    },
    "cell_contract_lender": {
      "vi": "Nộp hồ sơ để được duyệt vay đầu tư chính thức (vô điều kiện).",
      "en": "Submit for unconditional investment-loan approval."
    },
    "cell_contract_property_manager": {
      "vi": "Đơn vị quản lý cho thuê đưa ra ước tính tiền thuê tham khảo cho căn nhà.",
      "en": "A property manager provides a rental appraisal for the property."
    },
    "cell_contract_tenant": {
      "vi": "Nếu nhà đang có người thuê, xem lại hợp đồng thuê và lịch sử cho thuê trước khi ký.",
      "en": "If the property is already tenanted, review the lease and rental history before signing."
    },
    "cell_contract_services": {
      "vi": "Kiểm tra nhà và mối; đặt báo giá báo cáo khấu hao từ chuyên viên khảo sát; luật sư rà soát hợp đồng.",
      "en": "Building & pest inspection; get a depreciation-schedule quote from a quantity surveyor; conveyancer reviews the contract."
    },

    "cell_settle_you": {
      "vi": "Thanh toán phần còn lại — tổng tiền mặt cần để bàn giao.",
      "en": "Pay the balance — the total cash needed to settle."
    },
    "cell_settle_government": {
      "vi": "Thuế trước bạ đến hạn nộp.",
      "en": "Stamp duty falls due."
    },
    "cell_settle_lender": {
      "vi": "Ngân hàng giải ngân khoản vay đầu tư.",
      "en": "The lender releases the investment-loan funds."
    },
    "cell_settle_property_manager": {
      "vi": "Chỉ định đơn vị quản lý cho thuê; mua bảo hiểm cho chủ nhà cho thuê.",
      "en": "Appoint a property manager; bind landlord insurance."
    },
    "cell_settle_services": {
      "vi": "Hoàn tất thủ tục lập pháp nhân (nếu dùng); thuê chuyên viên khảo sát lập báo cáo khấu hao; hoàn tất bàn giao qua PEXA.",
      "en": "Complete entity setup (if applicable); engage a quantity surveyor for the depreciation schedule; settlement completes via PEXA."
    },

    "cell_own_you": {
      "vi": "Theo dõi dòng tiền thực tế so với dự tính; xem lại mức phù hợp với chiến lược đầu tư ban đầu.",
      "en": "Track actual cash flow against projection; review fit against your investment thesis."
    },
    "cell_own_government": {
      "vi": "Thuế đất có thể áp dụng (không có miễn trừ như nhà ở chính); khai thuế hằng năm, có thể được hoàn thuế nếu lỗ cho thuê được khấu trừ.",
      "en": "Land tax may apply (no principal-home exemption); lodge an annual return, with a possible refund if the property is negatively geared."
    },
    "cell_own_lender": {
      "vi": "Cơ hội tái cấp vốn hoặc rút vốn chủ sở hữu cho căn nhà tiếp theo mở ra khi tỷ lệ vay trên giá trị giảm.",
      "en": "A refinance or equity-release window for your next property opens as your loan-to-value ratio drops."
    },
    "cell_own_property_manager": {
      "vi": "Quản lý việc cho thuê, thu tiền thuê, thanh toán các chi phí định kỳ, và xem lại hiệu quả quản lý hằng năm.",
      "en": "Manages the tenancy, collects rent, pays recurring outgoings, and reviews performance annually."
    },
    "cell_own_tenant": {
      "vi": "Trả tiền thuê nhà định kỳ.",
      "en": "Pays rent on an ongoing basis."
    },
    "cell_own_services": {
      "vi": "Kế toán nộp tờ khai thuế hằng năm; báo cáo khấu hao được cập nhật nếu có cải tạo.",
      "en": "Your accountant lodges the annual tax return; the depreciation schedule is refreshed if renovated."
    },
    "cell_own_recurring": {
      "vi": "Dòng tiền định kỳ hằng năm: tiền thuê thu vào; chi phí vận hành, lãi vay, và khoản hoàn thuế (nếu có) chi/thu ra.",
      "en": "Ongoing yearly cash flow: rent received; operating costs, loan interest, and any tax refund flowing the other way."
    },

    "cell_dispose_you": {
      "vi": "Quyết định bán và thời điểm bán, dựa trên chiến lược thoát vốn đã đặt ra; vốn ròng thu về có thể tài trợ cho lần mua tiếp theo.",
      "en": "Decide whether and when to sell, per your exit strategy; the net proceeds can fund your next purchase."
    },
    "cell_dispose_government": {
      "vi": "Thuế lãi vốn (CGT) áp dụng khi bán — không được miễn như nhà ở chính; có thể được giảm 50% nếu giữ trên 12 tháng.",
      "en": "Capital gains tax (CGT) applies on sale — no main-residence exemption; a 50% discount may apply if held over 12 months."
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
      "vi": "Đại lý bán nhà tiếp thị căn nhà; chuyên viên chuyển nhượng lo thủ tục sang tên.",
      "en": "A selling agent markets the property; your conveyancer handles the transfer."
    },

    "assumption_indicative": {
      "vi": "Sơ đồ hành trình mang tính tổng quan cho nhà đầu tư bất động sản trong nước tại Úc; mốc thời gian và thứ tự có thể thay đổi theo tiểu bang và theo giao dịch cụ thể.",
      "en": "This journey is a general overview for a domestic investor purchase in Australia; timing and order vary by state and by your specific transaction."
    },
    "assumption_figures": {
      "vi": "Các con số trên dòng thời gian được lấy từ phần tính toán của kế hoạch (tiền cọc, thuế trước bạ, dòng tiền cho thuê, thuế) — không tính lại tại đây.",
      "en": "The figures on the timeline come from your plan's calculators (deposit, stamp duty, rental cash flow, tax) — they are not recomputed here."
    },
    "assumption_no_fhb_schemes": {
      "vi": "Không có chương trình hỗ trợ người mua nhà lần đầu nào áp dụng — đây là bất động sản đầu tư, không phải nơi ở chính.",
      "en": "No first-home buyer schemes apply — this is an investment property, not a principal place of residence."
    }
  }
}
```
