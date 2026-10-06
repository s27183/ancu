---
slug: kb.risks.investor-foreign-by-phase
effective_from: 2026-07-10
last_verified: 2026-07-10
sources:
  - note: "NOT VERIFIED — bilingual copy/checklist doc: each risk is grounded in a named owning KB doc, not asserted independently here (same convention as kb.risks.investor-by-phase / kb.risks.fhb-by-phase)."
---

# Mode-D foreign-investor per-phase risks and mitigations (bilingual)

The **risk-management layer** of the legal/temporal spine for a Mode-D Vietnam-located-investor
purchase — same role as `kb.risks.investor-by-phase`, for each lifecycle phase the often-seen
risks a foreign investor faces (compounding Mode B's foreign-person risks with Mode C's investor
risks) and the mitigation for each. It is the content the `phase_playbook` resolver (Mode-D
branch) renders as a `risk-flag-list` behind each Flow-view phase sheet.

**Every risk here is grounded in the transactional KB, never generated**, each drawn from an
owning rulebook doc already declared as a KB anchor somewhere in `investor-foreign-au.md`: the
narrow non-resident lender pool + rate premium from `kb.lender.non-resident-investment-loan-
shortlist`; the higher deposit floor from `kb.non-resident.investment-loan-deposit-requirements`;
the new-build-only restriction from `kb.firb.eligible-property-types-foreign-persons` +
`kb.firb.established-dwelling-ban`; FIRB decision timing from `kb.firb.timelines-standard` +
`kb.firb.approval-conditions-typical`; auction/cooling-off (shared with Modes A/C) from
`kb.cooling-off.by-state` + `kb.auction.rules-by-state`; undisclosed defects (shared) from
`kb.building-pest.interpretation`; FX/transfer timing from `kb.fx.typical-spreads-vnd-aud`; entity
setup timing from `kb.non-resident.entity-options-au-property`; vacancy-before-tenant (shared)
from `kb.investor.vacancy-rate-assumptions`; the FIRB vacancy-fee obligation from `kb.firb.vacancy-
fee-rules-2026`; the land-tax foreign-owner surcharge from `kb.tax.land-tax-by-state`; the narrow
refinance pool (same shortlist doc); depreciation clawback (shared) from `kb.tax.depreciation-
division-43-and-40`; no CGT discount for a foreign resident from `kb.tax.cgt-50-percent-discount`;
the FRCGW withholding from `kb.non-resident-tax.foreign-resident-cgt-withholding`; repatriation /
VN capital-control thresholds from `kb.vn-capital-controls.sbv-thresholds-2026`; selling costs and
market timing (shared) from `kb.selling-costs.agent-legal` + `kb.property.capital-growth-bands`;
tenancy-in-situ complications at sale (shared) from `kb.investor.tenancy-in-situ-considerations`.
**Honest-partial: a phase surfaces only the risks the KB substantiates** — a phase with no
grounded risk shows none, never a fabricated one.

This is a **copy doc** (it fills no slot). It is a blueprint anchor (component 16, added
2026-07-10 alongside `phase_playbook`), so it must resolve; structurally only slug==path +
content_json-parse + the bilingual copy gate apply. Vietnamese is authored for register, not
transliterated from the English (trap #4). **Decision-support, not advice (ASIC/FIRB/AML):** risks
are surfaced informationally, each with a mitigation that points to the investor's licensed
professional (AU tax agent/lawyer, or VN-licensed counsel) where finance, credit, tax, FIRB, or VN
capital-control law is involved — never as a recommendation.

## Risk provenance (per phase)

- **prepare** — *narrow non-resident lender pool* (typically 3–5 lenders willing, all pricing a
  premium over domestic-investor rates): `kb.lender.non-resident-investment-loan-shortlist`.
  *entity choice interacts with FIRB and non-resident tax* (a trust/company with a foreign
  beneficiary has different setup and compliance implications than personal name):
  `kb.non-resident.entity-options-au-property`.
- **pre_approve** — *higher deposit floor* (typically 30%+, well above the domestic-investor
  norm): `kb.non-resident.investment-loan-deposit-requirements`. *rate premium above domestic
  investor pricing* (typically 100–200bp): `kb.lender.non-resident-investment-loan-shortlist`.
- **contract** — *new-build-only restriction narrows the pool* (the established-dwelling ban
  applies until 30 Jun 2029): `kb.firb.established-dwelling-ban`,
  `kb.firb.eligible-property-types-foreign-persons`. *FIRB decision timing risk* (the standard
  30–60 day window can extend, and a contract must be conditional on approval):
  `kb.firb.timelines-standard`, `kb.firb.approval-conditions-typical`. *auction has no escape*
  (shared with Modes A/C — no cooling-off, no subject-to-finance/inspection):
  `kb.cooling-off.by-state`, `kb.auction.rules-by-state`. *undisclosed defects* (shared):
  `kb.building-pest.interpretation`.
- **settle** — *transfer timing / FX volatility* (the balance must clear before settlement, and
  VND-AUD spreads move day to day): `kb.fx.typical-spreads-vnd-aud`. *entity not ready in time*
  (trust/company setup can take weeks): `kb.non-resident.entity-options-au-property`. *vacancy
  before a tenant is found* (shared): `kb.investor.vacancy-rate-assumptions`.
- **own** — *FIRB vacancy-fee exposure* (an annual occupancy declaration is mandatory; falling
  short of the threshold doubles the fee from 9 April 2024): `kb.firb.vacancy-fee-rules-2026`.
  *land-tax foreign-owner surcharge* (most states add a surcharge on top of standard land tax for
  a foreign owner): `kb.tax.land-tax-by-state`. *narrow refinance pool* (equity-release options are
  limited to the same small non-resident lender list): `kb.lender.non-resident-investment-loan-
  shortlist`. *depreciation clawback risk builds during the hold* (capital-works deductions claimed
  reduce the cost base, enlarging the eventual taxable gain): `kb.tax.depreciation-division-43-
  and-40`.
- **dispose** — *no CGT discount for a foreign resident* (unlike a domestic investor, no 50%
  discount applies regardless of hold period): `kb.tax.cgt-50-percent-discount`. *FRCGW withheld
  at settlement* (a portion of the sale proceeds is withheld and credited against the final CGT —
  not an extra cost, but it reduces cash in hand at settlement of the sale):
  `kb.non-resident-tax.foreign-resident-cgt-withholding`. *repatriation may need SBV
  documentation* (a large transfer back to Vietnam can trigger a State Bank of Vietnam threshold
  and declared-purpose requirement): `kb.vn-capital-controls.sbv-thresholds-2026`. *selling costs
  erode net proceeds* (shared): `kb.selling-costs.agent-legal`. *market timing* (shared — proceeds
  depend on growth, not guaranteed): `kb.property.capital-growth-bands`. *tenant in place
  complicates timing* (shared): `kb.investor.tenancy-in-situ-considerations`.

## Rules

Everything above is `content_md`. The `content_json` below has two parts, same shape as
`kb.risks.investor-by-phase`: `layout.phases[]` (the structure) and `copy` (the bilingual prose).

Resolver mapping mirrors Mode C's `fh_engine_phase_playbook`: for each `layout.phases[].risks[]`
entry, emit a `risk-flag-list` item `{ severity, item ← risk_<phase>_<id>_item, action ←
risk_<phase>_<id>_action }`. The resolver **merges by `phase`** with
`kb.journey.investor-foreign-phase-actions` so each phase's outcome carries both its `actions` and
its `risks`.

```jsonc
{
  "fills": [],
  "layout": {
    "phases": [
      {
        "phase": "prepare",
        "risks": [
          { "id": "narrow_lender_pool", "severity": "medium" },
          { "id": "entity_choice_interacts_with_firb", "severity": "medium" }
        ]
      },
      {
        "phase": "pre_approve",
        "risks": [
          { "id": "higher_deposit_floor", "severity": "medium" },
          { "id": "rate_premium",         "severity": "low" }
        ]
      },
      {
        "phase": "contract",
        "risks": [
          { "id": "new_build_only_restriction", "severity": "medium" },
          { "id": "firb_decision_timing",        "severity": "high" },
          { "id": "auction_no_escape",           "severity": "high" },
          { "id": "undisclosed_defects",         "severity": "medium" }
        ]
      },
      {
        "phase": "settle",
        "risks": [
          { "id": "transfer_timing_fx",   "severity": "high" },
          { "id": "entity_not_ready",     "severity": "medium" },
          { "id": "vacancy_before_tenant","severity": "medium" }
        ]
      },
      {
        "phase": "own",
        "risks": [
          { "id": "vacancy_fee_exposure",       "severity": "high" },
          { "id": "land_tax_foreign_surcharge", "severity": "medium" },
          { "id": "narrow_refinance_pool",      "severity": "low" },
          { "id": "depreciation_clawback_builds","severity": "low" }
        ]
      },
      {
        "phase": "dispose",
        "risks": [
          { "id": "no_cgt_discount",       "severity": "high" },
          { "id": "frcgw_withheld",        "severity": "medium" },
          { "id": "repatriation_sbv_docs", "severity": "medium" },
          { "id": "selling_costs_erode",   "severity": "medium" },
          { "id": "market_timing",         "severity": "low" },
          { "id": "tenant_in_place",       "severity": "low" }
        ]
      }
    ]
  },
  "copy": {
    "risk_prepare_narrow_lender_pool_item": {
      "vi": "Chỉ khoảng 3–5 ngân hàng tại Úc chấp nhận cho vay đầu tư với người không cư trú, và tất cả đều tính lãi suất cao hơn so với nhà đầu tư trong nước.",
      "en": "Only about 3–5 Australian lenders fund a non-resident investor, and all of them price a premium above domestic-investor rates."
    },
    "risk_prepare_narrow_lender_pool_action": {
      "vi": "So sánh nhóm ngân hàng hẹp này sớm và cân nhắc dùng chuyên viên môi giới vay chuyên về khoản vay không cư trú.",
      "en": "Compare this narrow lender pool early and consider a broker who specialises in non-resident lending."
    },
    "risk_prepare_entity_choice_interacts_with_firb_item": {
      "vi": "Pháp nhân đứng tên sở hữu (cá nhân, quỹ ủy thác, hay công ty có cổ đông nước ngoài) ảnh hưởng đến cách tính thuế không cư trú và có thể ảnh hưởng đến hồ sơ FIRB.",
      "en": "The ownership entity (personal, trust, or a company with a foreign shareholder) affects non-resident tax treatment and can affect the FIRB application."
    },
    "risk_prepare_entity_choice_interacts_with_firb_action": {
      "vi": "Quyết định pháp nhân trước khi nộp hồ sơ FIRB, với sự tư vấn của kế toán tại Úc và chuyên viên tư vấn tại Việt Nam.",
      "en": "Decide the entity before submitting the FIRB application, with advice from your Australian accountant and Vietnam-based adviser."
    },

    "risk_pre_approve_higher_deposit_floor_item": {
      "vi": "Khoản vay đầu tư dành cho người không cư trú thường yêu cầu tiền cọc từ 30% trở lên — cao hơn nhiều so với nhà đầu tư trong nước.",
      "en": "Non-resident investment loans typically require a 30%+ deposit — well above the domestic-investor norm."
    },
    "risk_pre_approve_higher_deposit_floor_action": {
      "vi": "Lập ngân sách với mức cọc cao hơn ngay từ đầu để tránh bất ngờ khi xin duyệt vay chính thức.",
      "en": "Budget for the higher deposit from the start to avoid a surprise at unconditional approval."
    },
    "risk_pre_approve_rate_premium_item": {
      "vi": "Lãi suất cho vay đầu tư không cư trú thường cao hơn 1–2% so với lãi suất nhà đầu tư trong nước.",
      "en": "Non-resident investment-loan rates typically run 100–200bp above domestic-investor pricing."
    },
    "risk_pre_approve_rate_premium_action": {
      "vi": "Tính mức lãi suất cao hơn vào dòng tiền dự tính, không dùng lãi suất nhà đầu tư trong nước làm cơ sở.",
      "en": "Factor the premium into your projected cash flow rather than benchmarking off domestic-investor rates."
    },

    "risk_contract_new_build_only_restriction_item": {
      "vi": "Lệnh cấm mua nhà đã xây sẵn với người nước ngoài có hiệu lực đến 30/6/2029, giới hạn lựa chọn của bạn chỉ còn nhà mới xây hoặc đất trống.",
      "en": "The established-dwelling ban on foreign persons runs until 30 June 2029, narrowing your choice to new-build stock or vacant land."
    },
    "risk_contract_new_build_only_restriction_action": {
      "vi": "Xác nhận loại bất động sản đủ điều kiện trước khi ra giá — nhà đã xây sẵn thường không được phép mua.",
      "en": "Confirm the property type is eligible before bidding — an established dwelling is usually off-limits."
    },
    "risk_contract_firb_decision_timing_item": {
      "vi": "Thời gian chờ quyết định FIRB tiêu chuẩn là 30–60 ngày nhưng có thể kéo dài hơn; hợp đồng phải có điều kiện tùy thuộc vào việc được phê duyệt.",
      "en": "The standard FIRB decision window is 30–60 days but can extend; the contract must be made conditional on approval."
    },
    "risk_contract_firb_decision_timing_action": {
      "vi": "Nộp hồ sơ FIRB càng sớm càng tốt và đưa điều kiện tùy thuộc vào phê duyệt FIRB vào hợp đồng.",
      "en": "Submit the FIRB application as early as possible and include the subject-to-FIRB-approval condition in the contract."
    },
    "risk_contract_auction_no_escape_item": {
      "vi": "Khi đấu giá, không có thời gian cân nhắc rút lui và không có điều kiện tùy thuộc vào FIRB — cần có phê duyệt FIRB trước khi đấu giá.",
      "en": "At auction there is no cooling-off and no subject-to-FIRB condition possible — FIRB approval is needed before you bid."
    },
    "risk_contract_auction_no_escape_action": {
      "vi": "Hoàn tất phê duyệt FIRB, duyệt vay chính thức, và kiểm tra nhà trước khi tham gia đấu giá.",
      "en": "Complete FIRB approval, unconditional finance, and inspections before you bid at auction."
    },
    "risk_contract_undisclosed_defects_item": {
      "vi": "Ngay cả nhà mới xây cũng có thể có lỗi hoàn thiện; nhà đã xây sẵn (nếu đủ điều kiện mua) không có bảo hành xây dựng theo luật.",
      "en": "Even a new build can have completion defects; an established home, where eligible, carries no statutory builder's warranty."
    },
    "risk_contract_undisclosed_defects_action": {
      "vi": "Đặt kiểm tra nhà khi có thể và phân biệt lỗi nghiêm trọng với hao mòn hoặc hoàn thiện thông thường.",
      "en": "Commission inspections where possible and separate major defects from ordinary wear or completion issues."
    },

    "risk_settle_transfer_timing_fx_item": {
      "vi": "Khoản chuyển tiền từ Việt Nam cần thời gian xử lý, và tỷ giá VND-AUD biến động hằng ngày — chậm trễ có thể ảnh hưởng đến ngày bàn giao.",
      "en": "The transfer from Vietnam needs processing time, and the VND-AUD rate moves daily — a delay can put the settlement date at risk."
    },
    "risk_settle_transfer_timing_fx_action": {
      "vi": "Khởi động khoản chuyển tiền sớm với thời gian dự phòng, và theo dõi tỷ giá trước ngày cần chuyển.",
      "en": "Initiate the transfer early with a buffer, and watch the rate ahead of the date you need to send."
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

    "risk_own_vacancy_fee_exposure_item": {
      "vi": "Chủ sở hữu nước ngoài phải khai báo mức độ sử dụng hằng năm; không đạt ngưỡng cho thuê tối thiểu sẽ phát sinh phí bỏ trống, đã tăng gấp đôi từ 9/4/2024.",
      "en": "Foreign owners must lodge an annual occupancy declaration; falling short of the minimum rental threshold triggers the vacancy fee, doubled from 9 April 2024."
    },
    "risk_own_vacancy_fee_exposure_action": {
      "vi": "Đặt lịch nhắc khai báo hằng năm và giữ nhà có người thuê trên ngưỡng tối thiểu.",
      "en": "Set an annual declaration reminder and keep the property tenanted above the minimum threshold."
    },
    "risk_own_land_tax_foreign_surcharge_item": {
      "vi": "Hầu hết các tiểu bang áp thêm phụ phí thuế đất dành cho chủ sở hữu nước ngoài, cộng vào thuế đất tiêu chuẩn.",
      "en": "Most states add a foreign-owner land-tax surcharge on top of the standard land tax."
    },
    "risk_own_land_tax_foreign_surcharge_action": {
      "vi": "Tính cả phụ phí vào dòng tiền hằng năm khi lập ngân sách, không chỉ thuế đất tiêu chuẩn.",
      "en": "Budget for the surcharge in your annual cash flow, not just the standard land tax."
    },
    "risk_own_narrow_refinance_pool_item": {
      "vi": "Cơ hội tái cấp vốn hoặc rút vốn chủ sở hữu bị giới hạn trong cùng nhóm ngân hàng hẹp dành cho người không cư trú.",
      "en": "Refinance or equity-release options are limited to the same narrow non-resident lender pool."
    },
    "risk_own_narrow_refinance_pool_action": {
      "vi": "Lên kế hoạch tái cấp vốn sớm và không giả định có nhiều lựa chọn ngân hàng như nhà đầu tư trong nước.",
      "en": "Plan any refinance well ahead and don't assume the same lender choice a domestic investor has."
    },
    "risk_own_depreciation_clawback_builds_item": {
      "vi": "Khoản khấu hao đã yêu cầu tích lũy trong suốt thời gian giữ nhà, làm giảm cơ sở tính giá vốn và làm tăng phần lãi chịu thuế khi bán sau này.",
      "en": "Depreciation claimed accumulates over the hold, reducing the cost base and enlarging the eventual taxable gain at sale."
    },
    "risk_own_depreciation_clawback_builds_action": {
      "vi": "Giữ hồ sơ khấu hao đầy đủ theo từng năm để kế toán dễ tính cơ sở giá vốn đã điều chỉnh khi bán.",
      "en": "Keep a full year-by-year depreciation record so your accountant can compute the adjusted cost base at sale easily."
    },

    "risk_dispose_no_cgt_discount_item": {
      "vi": "Khác với nhà đầu tư trong nước, người không cư trú không được giảm 50% thuế lãi vốn dù giữ nhà bao lâu.",
      "en": "Unlike a domestic investor, a non-resident gets no 50% CGT discount regardless of how long the property is held."
    },
    "risk_dispose_no_cgt_discount_action": {
      "vi": "Tính thuế lãi vốn đầy đủ vào kỳ vọng vốn ròng ngay từ đầu, không giả định có mức giảm 50%.",
      "en": "Factor the full, undiscounted CGT into your net-equity expectation from the start — don't assume the 50% discount applies."
    },
    "risk_dispose_frcgw_withheld_item": {
      "vi": "Một phần tiền bán bị khấu trừ tại thời điểm bàn giao theo cơ chế FRCGW liên bang — khoản này được trừ vào thuế lãi vốn phải nộp, nhưng làm giảm tiền mặt thực nhận ngay lúc bán.",
      "en": "A portion of the sale proceeds is withheld at settlement under the federal FRCGW mechanism — it's credited against the CGT owed, but it reduces the cash you receive at the time of sale."
    },
    "risk_dispose_frcgw_withheld_action": {
      "vi": "Lập kế hoạch dòng tiền quanh thời điểm bán có tính đến khoản khấu trừ tạm thời này, không phải toàn bộ tiền bán về tay ngay.",
      "en": "Plan your cash flow around the sale expecting this temporary withholding, not the full sale price landing immediately."
    },
    "risk_dispose_repatriation_sbv_docs_item": {
      "vi": "Chuyển một khoản tiền lớn về Việt Nam có thể vượt ngưỡng của Ngân hàng Nhà nước và yêu cầu hồ sơ khai báo mục đích sử dụng vốn.",
      "en": "Transferring a large amount back to Vietnam can exceed a State Bank of Vietnam threshold and require declared-purpose documentation."
    },
    "risk_dispose_repatriation_sbv_docs_action": {
      "vi": "Chuẩn bị hồ sơ nguồn gốc và mục đích sử dụng vốn sớm, và dùng kênh chuyển tiền được cấp phép cho khoản chuyển về.",
      "en": "Prepare source-of-funds and declared-purpose documentation early, and use a licensed channel for the transfer home."
    },
    "risk_dispose_selling_costs_erode_item": {
      "vi": "Chi phí bán nhà — hoa hồng đại lý, phí pháp lý và tiếp thị — làm giảm phần vốn bạn thực nhận.",
      "en": "Selling costs — agent commission, legal and marketing — reduce the equity you actually receive."
    },
    "risk_dispose_selling_costs_erode_action": {
      "vi": "Tính chi phí bán vào kỳ vọng vốn ròng; kế hoạch chiếu các chi phí này như một dải, không phải con số cố định.",
      "en": "Factor selling costs into your net-equity expectation; the plan shows these as a band, not a fixed figure."
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
