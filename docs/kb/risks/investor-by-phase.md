---
slug: kb.risks.investor-by-phase
effective_from: 2026-07-10
last_verified: 2026-07-10
sources:
  - note: "NOT VERIFIED — bilingual copy/checklist doc: each risk is grounded in a named owning KB doc, not asserted independently here (same convention as kb.risks.fhb-by-phase)."
---

# Mode-C investor per-phase risks and mitigations (bilingual)

The **risk-management layer** of the legal/temporal spine for a Mode-C domestic-investor
purchase — same role as `kb.risks.fhb-by-phase`, for each lifecycle phase the often-seen risks a
domestic investor faces and the mitigation for each. It is the content the `phase_playbook`
resolver (Mode-C branch) renders as a `risk-flag-list` behind each Flow-view phase sheet.

**Every risk here is grounded in the transactional KB, never generated**, each drawn from an
owning rulebook doc already declared as a KB anchor somewhere in `investor-domestic-au.md`:
serviceability haircut and lender pool from `kb.lender.serviceability-investment-loans` +
`kb.lender.investor-friendly-shortlist` + `kb.lender.hecs-treatment-by-lender`; the negative-
gearing reform from `kb.tax.negative-gearing-mechanics`; auction/cooling-off (shared with Mode A)
from `kb.cooling-off.by-state` + `kb.auction.rules-by-state`; yield discipline from
`kb.investor.yield-anchored-pricing` + `kb.investor.bid-discipline`; building/pest (shared) from
`kb.building-pest.interpretation`; depreciation from `kb.tax.depreciation-division-43-and-40`;
entity timing from `kb.investor.entity-setup-timeline`; vacancy from
`kb.investor.vacancy-rate-assumptions`; settlement (shared) from `kb.settlement.process-by-state`
+ `kb.pexa.settlement`; land tax aggregation from `kb.investor.land-tax-aggregation` +
`kb.tax.land-tax-by-state`; rate roll-off from `kb.loan.fixed-rate-roll-off-planning`; CGT and its
discount from `kb.tax.cgt-50-percent-discount`; selling costs and market timing (shared) from
`kb.selling-costs.agent-legal` + `kb.property.capital-growth-bands`; tenancy-in-situ complications
at sale from `kb.investor.tenancy-in-situ-considerations`. **Honest-partial: a phase surfaces only
the risks the KB substantiates** — a phase with no grounded risk shows none, never a fabricated
one.

This is a **copy doc** (it fills no slot). It is a blueprint anchor (component 12 — tracked as the
restructure's blueprint-wiring pass), so it must resolve; structurally only slug==path +
content_json-parse + the bilingual copy gate apply. Vietnamese is authored for register, not
transliterated from the English (trap #4). **Decision-support, not advice (ASIC):** risks are
surfaced informationally, each with a mitigation that points to the investor's licensed
professional where finance, credit, tax or law is involved — never as a recommendation.

## Risk provenance (per phase)

- **prepare** — *serviceability haircut* (lenders discount projected rental income when assessing
  capacity): `kb.lender.serviceability-investment-loans`. *negative-gearing reform* (limited to
  new builds from 1 Jul 2027 for established property bought after Budget night — enacted, not
  yet in effect): `kb.tax.negative-gearing-mechanics`.
- **pre_approve** — *smaller lender pool* (fewer lenders compete on investment loans, and terms
  can be less favourable): `kb.lender.investor-friendly-shortlist`. *existing debts reduce
  capacity* (HECS, credit cards, BNPL): `kb.lender.hecs-treatment-by-lender`.
- **contract** — *auction has no escape* (shared with Mode A — no cooling-off, no subject-to-
  finance/inspection): `kb.cooling-off.by-state`, `kb.auction.rules-by-state`. *chasing above the
  yield-anchored price* (bidding past the price the target yield supports): `kb.investor.yield-
  anchored-pricing`, `kb.investor.bid-discipline`. *undisclosed defects* (shared — no builder
  warranty on an established home): `kb.building-pest.interpretation`. *depreciation not yet
  confirmed* (the deduction depends on a report not yet in hand): `kb.tax.depreciation-division-
  43-and-40`.
- **settle** — *entity not ready in time* (trust/company setup can take weeks and may delay
  settlement): `kb.investor.entity-setup-timeline`. *vacancy before a tenant is found* (no rental
  income immediately after settlement): `kb.investor.vacancy-rate-assumptions`. *settlement
  shortfall* (shared): `kb.settlement.process-by-state`, `kb.pexa.settlement`.
- **own** — *land tax aggregation* (multiple properties can push aggregated land value over a
  state threshold): `kb.investor.land-tax-aggregation`, `kb.tax.land-tax-by-state`. *negative-
  gearing reform reduces the offset* (established property bought after Budget night loses the
  wage offset from 1 Jul 2027): `kb.tax.negative-gearing-mechanics`. *rate roll-off* (a fixed or
  interest-only term ending raises repayments): `kb.loan.fixed-rate-roll-off-planning`.
- **dispose** — *no CGT exemption* (unlike a main residence, tax is payable on the gain, though a
  50% discount may apply if held over 12 months): `kb.tax.cgt-50-percent-discount`. *depreciation
  clawback* (capital-works deductions claimed reduce the cost base, enlarging the taxable gain):
  `kb.tax.depreciation-division-43-and-40`. *selling costs erode net proceeds* (shared):
  `kb.selling-costs.agent-legal`. *market timing* (shared — proceeds depend on growth, not
  guaranteed): `kb.property.capital-growth-bands`. *tenant in place complicates timing* (notice
  periods and vacant-possession requirements before settlement of the sale):
  `kb.investor.tenancy-in-situ-considerations`.

## Rules

Everything above is `content_md`. The `content_json` below has two parts, same shape as
`kb.risks.fhb-by-phase`: `layout.phases[]` (the structure) and `copy` (the bilingual prose).

Resolver mapping mirrors Mode A's `fh_engine_phase_playbook`: for each `layout.phases[].risks[]`
entry, emit a `risk-flag-list` item `{ severity, item ← risk_<phase>_<id>_item, action ←
risk_<phase>_<id>_action }`. The resolver **merges by `phase`** with
`kb.journey.investor-phase-actions` so each phase's outcome carries both its `actions` and its
`risks`.

```jsonc
{
  "fills": [],
  "layout": {
    "phases": [
      {
        "phase": "prepare",
        "risks": [
          { "id": "serviceability_haircut", "severity": "medium" },
          { "id": "ng_reform",              "severity": "medium" }
        ]
      },
      {
        "phase": "pre_approve",
        "risks": [
          { "id": "smaller_lender_pool", "severity": "low" },
          { "id": "existing_debts",      "severity": "medium" }
        ]
      },
      {
        "phase": "contract",
        "risks": [
          { "id": "auction_no_escape",       "severity": "high" },
          { "id": "chasing_above_yield",     "severity": "medium" },
          { "id": "undisclosed_defects",     "severity": "high" },
          { "id": "depreciation_unconfirmed","severity": "low" }
        ]
      },
      {
        "phase": "settle",
        "risks": [
          { "id": "entity_not_ready",        "severity": "medium" },
          { "id": "vacancy_before_tenant",   "severity": "medium" },
          { "id": "settlement_shortfall",    "severity": "medium" }
        ]
      },
      {
        "phase": "own",
        "risks": [
          { "id": "land_tax_aggregation", "severity": "medium" },
          { "id": "ng_reform_hold",       "severity": "medium" },
          { "id": "rate_roll_off",        "severity": "medium" }
        ]
      },
      {
        "phase": "dispose",
        "risks": [
          { "id": "no_cgt_exemption",       "severity": "high" },
          { "id": "depreciation_clawback",  "severity": "medium" },
          { "id": "selling_costs_erode",    "severity": "medium" },
          { "id": "market_timing",          "severity": "low" },
          { "id": "tenant_in_place",        "severity": "low" }
        ]
      }
    ]
  },
  "copy": {
    "risk_prepare_serviceability_haircut_item": {
      "vi": "Ngân hàng thường chỉ tính một phần thu nhập cho thuê dự kiến khi xét khả năng vay, khiến khả năng vay thực tế thấp hơn kỳ vọng.",
      "en": "Lenders typically discount projected rental income when assessing capacity, so real borrowing capacity is often lower than expected."
    },
    "risk_prepare_serviceability_haircut_action": {
      "vi": "So sánh cách các ngân hàng khác nhau tính thu nhập cho thuê và chọn ngân hàng có chính sách linh hoạt hơn nếu phù hợp.",
      "en": "Compare how different lenders treat rental income and choose a more lenient one if it suits your case."
    },
    "risk_prepare_ng_reform_item": {
      "vi": "Đối với bất động sản đã xây sẵn mua sau đêm công bố ngân sách, khoản lỗ cho thuê sẽ không còn được khấu trừ vào thu nhập khác (lương) kể từ 1/7/2027 — đã thành luật.",
      "en": "For an established property purchased after Budget night, a net rental loss will no longer be deductible against other income (wages) from 1 July 2027 — this is now law."
    },
    "risk_prepare_ng_reform_action": {
      "vi": "Tính toán dòng tiền sau thuế theo cả quy định hiện hành và quy định sau cải cách; cân nhắc nhà xây mới nếu việc khấu trừ đầy đủ quan trọng với chiến lược của bạn.",
      "en": "Model after-tax cash flow under both current and post-reform rules; consider a new build if the full offset matters to your strategy."
    },

    "risk_pre_approve_smaller_lender_pool_item": {
      "vi": "Số ngân hàng cạnh tranh cho vay đầu tư ít hơn vay mua nhà ở, và điều khoản có thể kém thuận lợi hơn.",
      "en": "Fewer lenders compete for investment loans than owner-occupier loans, and terms can be less favourable."
    },
    "risk_pre_approve_smaller_lender_pool_action": {
      "vi": "So sánh nhiều ngân hàng hoặc dùng chuyên viên môi giới vay chuyên về khoản vay đầu tư.",
      "en": "Compare multiple lenders or use a broker who specialises in investment lending."
    },
    "risk_pre_approve_existing_debts_item": {
      "vi": "Khoản vay HECS, thẻ tín dụng, và mua-trả-sau (BNPL) làm giảm khả năng vay đầu tư, dù đã có bất động sản đang giữ.",
      "en": "HECS, credit cards and buy-now-pay-later limits reduce investment-loan capacity, even with an existing property held."
    },
    "risk_pre_approve_existing_debts_action": {
      "vi": "Xem lại các khoản nợ và hạn mức tín dụng hiện có trước khi nộp hồ sơ; đóng các hạn mức không dùng tới.",
      "en": "Review your existing debts and credit limits before applying; close unused limits."
    },

    "risk_contract_auction_no_escape_item": {
      "vi": "Khi đấu giá, không có thời gian cân nhắc rút lui, không có điều kiện “tùy thuộc duyệt vay” hay “tùy thuộc kiểm tra” — bạn bị ràng buộc ngay khi búa gõ.",
      "en": "At auction there is no cooling-off, no subject-to-finance and no subject-to-inspection — you are bound on the fall of the hammer."
    },
    "risk_contract_auction_no_escape_action": {
      "vi": "Hoàn tất duyệt vay chính thức, kiểm tra nhà và mối, và có ước tính tiền thuê trước khi tham gia đấu giá.",
      "en": "Complete unconditional finance, building & pest inspections, and get a rental appraisal before you bid at auction."
    },
    "risk_contract_chasing_above_yield_item": {
      "vi": "Cảm xúc trong lúc đấu giá hoặc thương lượng có thể đẩy giá vượt mức lợi suất mục tiêu ban đầu.",
      "en": "Emotion during bidding or negotiation can push the price above the level your target yield supports."
    },
    "risk_contract_chasing_above_yield_action": {
      "vi": "Giữ mức giá dừng theo kỷ luật lợi suất đã đặt ra và sẵn sàng bỏ qua nếu vượt mức đó.",
      "en": "Hold your yield-anchored walk-away price and be willing to pass if the bidding exceeds it."
    },
    "risk_contract_undisclosed_defects_item": {
      "vi": "Nhà cũ không có bảo hành xây dựng theo luật; lỗi kết cấu nghiêm trọng hoặc mối đang hoạt động có thể rất tốn kém.",
      "en": "An established home has no statutory builder's warranty; major structural defects or active termites can be costly."
    },
    "risk_contract_undisclosed_defects_action": {
      "vi": "Đặt kiểm tra nhà và kiểm tra mối, và phân biệt lỗi nghiêm trọng với hao mòn thông thường.",
      "en": "Commission building and pest inspections, and separate major defects from ordinary wear and tear."
    },
    "risk_contract_depreciation_unconfirmed_item": {
      "vi": "Mức khấu hao thực tế chưa được xác nhận cho đến khi có báo cáo từ chuyên viên khảo sát — ước tính ban đầu có thể khác con số thật.",
      "en": "The real depreciation benefit isn't confirmed until the quantity surveyor's report — an early estimate can differ from the actual figure."
    },
    "risk_contract_depreciation_unconfirmed_action": {
      "vi": "Đặt báo giá báo cáo khấu hao sớm và xem con số trước hợp đồng như một ước tính, không phải số cuối cùng.",
      "en": "Get a depreciation-schedule quote early and treat the pre-contract figure as an estimate, not the final number."
    },

    "risk_settle_entity_not_ready_item": {
      "vi": "Thủ tục lập quỹ ủy thác hoặc công ty có thể mất vài tuần và làm chậm ngày bàn giao nếu không chuẩn bị sớm.",
      "en": "Setting up a trust or company can take several weeks and may delay settlement if not started early."
    },
    "risk_settle_entity_not_ready_action": {
      "vi": "Bắt đầu thủ tục lập pháp nhân ngay khi ký hợp đồng, không chờ đến gần ngày bàn giao.",
      "en": "Start entity setup as soon as you exchange contracts, not close to settlement."
    },
    "risk_settle_vacancy_before_tenant_item": {
      "vi": "Nếu nhà chưa có người thuê khi bàn giao, sẽ không có tiền thuê thu vào trong thời gian tìm người thuê.",
      "en": "If the property has no tenant at settlement, there's no rental income while a tenant is found."
    },
    "risk_settle_vacancy_before_tenant_action": {
      "vi": "Chỉ định đơn vị quản lý cho thuê sớm và bắt đầu quảng cáo cho thuê trước hoặc ngay khi bàn giao.",
      "en": "Appoint a property manager early and start marketing for a tenant before or at settlement."
    },
    "risk_settle_settlement_shortfall_item": {
      "vi": "Tiền chưa về kịp hoặc thiếu hụt vào ngày bàn giao có thể làm chậm việc bàn giao và phát sinh lãi phạt.",
      "en": "Funds not cleared, or a shortfall on the day, can delay settlement and incur penalty interest."
    },
    "risk_settle_settlement_shortfall_action": {
      "vi": "Xác nhận tổng tiền mặt cần để bàn giao đã có sẵn và đã thông khoản trước ngày hẹn.",
      "en": "Confirm the total cash to settle is available and cleared ahead of the date."
    },

    "risk_own_land_tax_aggregation_item": {
      "vi": "Nếu giữ nhiều bất động sản đầu tư, tổng giá trị đất có thể vượt ngưỡng của tiểu bang và phát sinh thuế đất cao hơn dự tính.",
      "en": "If you hold multiple investment properties, aggregated land value can exceed a state threshold and trigger higher land tax than expected."
    },
    "risk_own_land_tax_aggregation_action": {
      "vi": "Theo dõi tổng giá trị đất đang sở hữu qua các tiểu bang và tính thuế đất vào dòng tiền trước khi mua thêm.",
      "en": "Track aggregated land value across the states you hold in and factor land tax into cash flow before buying again."
    },
    "risk_own_ng_reform_hold_item": {
      "vi": "Đối với bất động sản đã xây sẵn mua sau đêm công bố ngân sách, khoản khấu trừ vào lương sẽ mất từ 1/7/2027 — làm thay đổi dòng tiền sau thuế trong quá trình giữ nhà.",
      "en": "For an established property bought after Budget night, the wage offset is lost from 1 July 2027 — changing after-tax cash flow partway through the hold."
    },
    "risk_own_ng_reform_hold_action": {
      "vi": "Lập ngân sách cho dòng tiền sau thuế thấp hơn kể từ 1/7/2027 và xác nhận với kế toán khi ngày đó đến gần.",
      "en": "Budget for lower after-tax cash flow from 1 July 2027 and confirm with your accountant as the date approaches."
    },
    "risk_own_rate_roll_off_item": {
      "vi": "Khi thời hạn lãi suất cố định hoặc thời hạn vay chỉ trả lãi kết thúc, khoản trả nợ hằng tháng có thể tăng đáng kể.",
      "en": "When a fixed-rate term or interest-only period ends, monthly repayments can rise significantly."
    },
    "risk_own_rate_roll_off_action": {
      "vi": "Ghi nhớ ngày hết hạn và xem lại lựa chọn tái cấp vốn hoặc gia hạn trước khi đến hạn.",
      "en": "Track the expiry date and review refinance or extension options before it arrives."
    },

    "risk_dispose_no_cgt_exemption_item": {
      "vi": "Khác với nhà ở chính, bất động sản đầu tư không được miễn thuế lãi vốn — thuế được tính trên phần lãi khi bán.",
      "en": "Unlike a main residence, an investment property has no CGT exemption — tax is payable on the gain when sold."
    },
    "risk_dispose_no_cgt_exemption_action": {
      "vi": "Tính thuế lãi vốn vào kỳ vọng vốn ròng ngay từ đầu; xác nhận mức giảm 50% (nếu giữ trên 12 tháng) với chuyên viên thuế.",
      "en": "Factor CGT into your net-equity expectation from the start; confirm the 50% discount (if held over 12 months) with a tax professional."
    },
    "risk_dispose_depreciation_clawback_item": {
      "vi": "Khoản khấu hao đã yêu cầu (Div 43) làm giảm cơ sở tính giá vốn, khiến phần lãi chịu thuế khi bán lớn hơn.",
      "en": "Capital-works depreciation already claimed (Div 43) reduces the cost base, making the taxable gain at sale larger."
    },
    "risk_dispose_depreciation_clawback_action": {
      "vi": "Xác nhận với kế toán cơ sở tính giá vốn đã điều chỉnh trước khi ước tính vốn ròng thu về.",
      "en": "Confirm the adjusted cost base with your accountant before estimating net proceeds."
    },
    "risk_dispose_selling_costs_erode_item": {
      "vi": "Chi phí bán nhà — hoa hồng đại lý, phí pháp lý và tiếp thị — làm giảm phần vốn bạn thực nhận.",
      "en": "Selling costs — agent commission, legal and marketing — reduce the equity you actually receive."
    },
    "risk_dispose_selling_costs_erode_action": {
      "vi": "Tính chi phí bán vào kỳ vọng vốn ròng và thương lượng mức hoa hồng; kế hoạch chiếu các chi phí này như một dải, không phải con số cố định.",
      "en": "Factor selling costs into your net-equity expectation and negotiate the commission; the plan shows these as a band, not a fixed figure."
    },
    "risk_dispose_market_timing_item": {
      "vi": "Tiền bán nhà phụ thuộc vào tăng trưởng giá trị tại thời điểm bạn bán; tăng trưởng không được bảo đảm và có thể chững lại hoặc giảm.",
      "en": "Sale proceeds depend on capital growth at the time you sell; growth is not guaranteed and can stall or fall."
    },
    "risk_dispose_market_timing_action": {
      "vi": "Xem phần tiền thu về dự kiến như một dải ước tính thận trọng, không phải dự báo.",
      "en": "Treat projected proceeds as a conservative band, not a forecast."
    },
    "risk_dispose_tenant_in_place_item": {
      "vi": "Nếu nhà đang có người thuê, thời hạn báo trước và yêu cầu bàn giao nhà trống có thể ảnh hưởng đến thời điểm bán.",
      "en": "If the property is tenanted, notice periods and vacant-possession requirements can affect your selling timeline."
    },
    "risk_dispose_tenant_in_place_action": {
      "vi": "Phối hợp với đơn vị quản lý cho thuê để xác định thời hạn báo trước sớm khi lên kế hoạch bán.",
      "en": "Coordinate with your property manager to confirm notice periods early when planning the sale."
    }
  }
}
```
