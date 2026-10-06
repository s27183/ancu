---
slug: kb.risks.fhb-foreign-by-phase
effective_from: 2026-07-11
last_verified: 2026-07-11
sources:
  - note: "NOT VERIFIED — bilingual copy/checklist doc: each risk is grounded in a named owning KB doc, not asserted independently here (same convention as kb.risks.fhb-by-phase / kb.risks.investor-foreign-by-phase)."
---

# Mode-B foreign-FHB per-phase risks and mitigations (bilingual)

The **risk-management layer** of the legal/temporal spine for a Mode-B foreign-person first-home
purchase — same role as `kb.risks.fhb-by-phase`, for each lifecycle phase the often-seen risks a
foreign-person first home buyer faces (compounding Mode A's owner-occupier risks with FIRB/
cross-border risks) and the mitigation for each. It is the content the `phase_playbook` resolver
(Mode-B branch) renders as a `risk-flag-list` behind each Flow-view phase sheet.

**Every risk here is grounded in the transactional KB, never generated**, each drawn from an
owning rulebook doc already declared as a KB anchor somewhere in `fhb-foreign-au.md`: the narrow
non-resident/temp-resident lender pool from `kb.lender.non-resident-friendly-shortlist`; the
higher deposit floor from `kb.lender.foreign-buyer-deposit-requirements`; the new-build-only
restriction from `kb.firb.eligible-property-types-foreign-persons` +
`kb.firb.established-dwelling-ban`; FIRB decision timing from `kb.firb.timelines-standard` +
`kb.firb.application-process`; auction/cooling-off (shared with Mode A) from
`kb.cooling-off.by-state` + `kb.auction.rules-by-state`; undisclosed defects (shared, reframed for
new-build stock) from `kb.building-pest.interpretation`; FX/transfer timing from
`kb.fx.typical-spreads-vnd-aud`; the foreign-buyer stamp-duty surcharge from
`kb.foreign-buyer-surcharge.by-state`; the FIRB vacancy-fee obligation from
`kb.firb.vacancy-fee-rules-2026` + `kb.firb.vacancy-fee-double-from-2024`; the no-PPOR-exemption
CGT/land-tax treatment from `kb.non-resident-tax.cgt-no-ppor-exemption`; the FRCGW withholding
(informational — not computed by `disposition` for this mode, task 11) from
`kb.non-resident-tax.foreign-resident-cgt-withholding`; selling costs and market timing (shared)
from `kb.selling-costs.agent-legal` + `kb.property.capital-growth-bands`. **Honest-partial: a
phase surfaces only the risks the KB substantiates** — a phase with no grounded risk shows none,
never a fabricated one.

This is a **copy doc** (it fills no slot). It is a blueprint anchor (component 14, added
2026-07-11 alongside `phase_playbook`), so it must resolve; structurally only slug==path +
content_json-parse + the bilingual copy gate apply. Vietnamese is authored for register, not
transliterated from the English (trap #4). **Decision-support, not advice (ASIC/FIRB/AML):** risks
are surfaced informationally, each with a mitigation that points to the buyer's licensed
professional (AU tax agent/lawyer, or VN-licensed counsel) where finance, credit, tax, FIRB, or VN
capital-control law is involved — never as a recommendation.

## Risk provenance (per phase)

- **prepare** — *narrow non-resident/temp-resident lender pool* (typically 5–10 lenders willing,
  most pricing a premium): `kb.lender.non-resident-friendly-shortlist`. *established-dwelling
  confusion* (mistakenly considering a property type the ban excludes):
  `kb.firb.established-dwelling-ban`, `kb.firb.eligible-property-types-foreign-persons`.
- **pre_approve** — *higher deposit floor* (typically 30%+, above the domestic-buyer norm):
  `kb.lender.foreign-buyer-deposit-requirements`. *pre-approval lapses* (shared with Mode A,
  ~90-day conditional validity): `kb.lender-docs.standard-timeline`.
- **contract** — *FIRB decision timing risk* (the standard 30-day window runs from full fee
  payment and can extend; a contract must be conditional on approval, or exchanged via the
  conditional-contract route): `kb.firb.timelines-standard`, `kb.firb.application-process`.
  *auction has no escape* (shared with Mode A — no cooling-off, no subject-to-finance/inspection,
  and no subject-to-FIRB condition possible): `kb.cooling-off.by-state`, `kb.auction.rules-by-state`.
  *undisclosed defects* (reframed for new-build stock — completion defects, not established-home
  termite risk): `kb.building-pest.interpretation`.
- **settle** — *transfer timing / FX volatility* (the balance must clear before settlement, and
  VND-AUD spreads move day to day): `kb.fx.typical-spreads-vnd-aud`. *surcharge under-budgeted*
  (the foreign-buyer surcharge is often overlooked on top of standard duty — it typically runs
  ~8% of the price in NSW/VIC/QLD): `kb.foreign-buyer-surcharge.by-state`.
- **own** — *FIRB vacancy-fee exposure* (an annual occupancy declaration is mandatory; falling
  short of the threshold doubles the fee from 9 April 2024): `kb.firb.vacancy-fee-rules-2026`,
  `kb.firb.vacancy-fee-double-from-2024`. *no PPOR land-tax exemption* (most states offer no
  principal-residence land-tax exemption to a foreign owner, unlike a domestic owner-occupier):
  `kb.non-resident-tax.cgt-no-ppor-exemption`. *visa status change* (a PR/citizenship grant can
  make the plan eligible to switch to a domestic mode — or a visa lapse can affect the plan;
  `fh_engine_ownership:fill_foreign/2`'s own `mode_switch_eligible` starting-value comment).
- **dispose** — *CGT position uncertain* (the main-residence exemption does not automatically
  apply to a foreign person — `fh_engine_disposition:cgt/1` always returns `to_verify` for Mode B,
  never `exempt`, task 11): `kb.non-resident-tax.cgt-no-ppor-exemption`. *FRCGW may apply*
  (informational — the withholding is not computed by this plan's `disposition` component for
  Mode B; confirm with a tax agent): `kb.non-resident-tax.foreign-resident-cgt-withholding`.
  *selling costs erode net proceeds* (shared): `kb.selling-costs.agent-legal`. *market timing*
  (shared — proceeds depend on growth, not guaranteed): `kb.property.capital-growth-bands`.

## Rules

Everything above is `content_md`. The `content_json` below has two parts, same shape as
`kb.risks.fhb-by-phase`: `layout.phases[]` (the structure) and `copy` (the bilingual prose).

Resolver mapping mirrors Mode A's `fh_engine_phase_playbook`: for each `layout.phases[].risks[]`
entry, emit a `risk-flag-list` item `{ severity, item ← risk_<phase>_<id>_item, action ←
risk_<phase>_<id>_action }`. The resolver **merges by `phase`** with
`kb.journey.fhb-foreign-phase-actions` so each phase's outcome carries both its `actions` and its
`risks`.

```jsonc
{
  "fills": [],
  "layout": {
    "phases": [
      {
        "phase": "prepare",
        "risks": [
          { "id": "narrow_lender_pool",              "severity": "medium" },
          { "id": "established_dwelling_confusion",  "severity": "medium" }
        ]
      },
      {
        "phase": "pre_approve",
        "risks": [
          { "id": "higher_deposit_floor", "severity": "medium" },
          { "id": "preapproval_lapses",   "severity": "medium" }
        ]
      },
      {
        "phase": "contract",
        "risks": [
          { "id": "firb_decision_timing", "severity": "high" },
          { "id": "auction_no_escape",    "severity": "high" },
          { "id": "undisclosed_defects",  "severity": "medium" }
        ]
      },
      {
        "phase": "settle",
        "risks": [
          { "id": "transfer_timing_fx",     "severity": "high" },
          { "id": "surcharge_underbudgeted","severity": "medium" }
        ]
      },
      {
        "phase": "own",
        "risks": [
          { "id": "vacancy_fee_exposure",  "severity": "high" },
          { "id": "no_ppor_land_tax",      "severity": "medium" },
          { "id": "visa_status_change",    "severity": "low" }
        ]
      },
      {
        "phase": "dispose",
        "risks": [
          { "id": "cgt_position_uncertain","severity": "high" },
          { "id": "frcgw_may_apply",       "severity": "medium" },
          { "id": "selling_costs_erode",   "severity": "medium" },
          { "id": "market_timing",         "severity": "low" }
        ]
      }
    ]
  },
  "copy": {
    "risk_prepare_narrow_lender_pool_item": {
      "vi": "Chỉ một nhóm nhỏ ngân hàng tại Úc chấp nhận cho vay với người không cư trú hoặc thường trú tạm thời, và hầu hết đều tính lãi suất cao hơn.",
      "en": "Only a narrower pool of Australian lenders fund a non-resident or temporary-resident buyer, and most price a premium."
    },
    "risk_prepare_narrow_lender_pool_action": {
      "vi": "So sánh nhóm ngân hàng hẹp này sớm và cân nhắc dùng chuyên viên môi giới vay chuyên về khoản vay dành cho người nước ngoài.",
      "en": "Compare this narrower lender pool early and consider a broker who specialises in foreign-person lending."
    },
    "risk_prepare_established_dwelling_confusion_item": {
      "vi": "Lệnh cấm mua nhà đã xây sẵn với người nước ngoài có hiệu lực đến 30/6/2029 — nhầm lẫn về loại bất động sản đủ điều kiện là lỗi phổ biến.",
      "en": "The established-dwelling ban on foreign persons runs until 30 June 2029 — confusion about which property types qualify is a common mistake."
    },
    "risk_prepare_established_dwelling_confusion_action": {
      "vi": "Xác nhận loại bất động sản đủ điều kiện (nhà mới xây, gần như mới xây, hoặc đất trống) trước khi bắt đầu tìm nhà.",
      "en": "Confirm the eligible property type (new, near-new, or vacant land) before you start searching."
    },

    "risk_pre_approve_higher_deposit_floor_item": {
      "vi": "Khoản vay dành cho người nước ngoài thường yêu cầu tiền cọc từ 30% trở lên — cao hơn nhiều so với người mua trong nước.",
      "en": "A foreign-person loan typically requires a 30%+ deposit — well above the domestic-buyer norm."
    },
    "risk_pre_approve_higher_deposit_floor_action": {
      "vi": "Lập ngân sách với mức cọc cao hơn ngay từ đầu để tránh bất ngờ khi xin duyệt vay chính thức.",
      "en": "Budget for the higher deposit from the start to avoid a surprise at unconditional approval."
    },
    "risk_pre_approve_preapproval_lapses_item": {
      "vi": "Duyệt vay sơ bộ có điều kiện và thường chỉ có hiệu lực khoảng 90 ngày — nó có thể hết hạn hoặc bị xét lại.",
      "en": "Pre-approval is conditional and typically valid for only about 90 days — it can lapse or be re-assessed."
    },
    "risk_pre_approve_preapproval_lapses_action": {
      "vi": "Theo dõi ngày hết hạn và tránh ra giá dựa trên hồ sơ đã cũ; xin gia hạn nếu việc tìm nhà kéo dài.",
      "en": "Track the expiry and avoid making an offer on a stale approval; ask to renew it if your search runs long."
    },

    "risk_contract_firb_decision_timing_item": {
      "vi": "Thời gian chờ quyết định FIRB tiêu chuẩn là 30 ngày kể từ khi nộp đủ phí nhưng có thể kéo dài hơn; hợp đồng phải có điều kiện tùy thuộc vào việc được phê duyệt.",
      "en": "The standard FIRB decision window is 30 days from full fee payment but can extend; the contract must be made conditional on approval."
    },
    "risk_contract_firb_decision_timing_action": {
      "vi": "Nộp hồ sơ và phí FIRB càng sớm càng tốt và đưa điều kiện tùy thuộc vào phê duyệt FIRB vào hợp đồng.",
      "en": "Submit the FIRB application and fee as early as possible and include the subject-to-FIRB-approval condition in the contract."
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
      "vi": "Ngay cả nhà mới xây cũng có thể có lỗi hoàn thiện chưa được ghi nhận.",
      "en": "Even a new build can have completion defects that haven't been recorded."
    },
    "risk_contract_undisclosed_defects_action": {
      "vi": "Đặt kiểm tra nhà khi có thể và ghi lại các lỗi hoàn thiện trước khi bàn giao.",
      "en": "Commission an inspection where possible and record completion defects before settlement."
    },

    "risk_settle_transfer_timing_fx_item": {
      "vi": "Khoản chuyển tiền từ Việt Nam cần thời gian xử lý, và tỷ giá VND-AUD biến động hằng ngày — chậm trễ có thể ảnh hưởng đến ngày bàn giao.",
      "en": "The transfer from Vietnam needs processing time, and the VND-AUD rate moves daily — a delay can put the settlement date at risk."
    },
    "risk_settle_transfer_timing_fx_action": {
      "vi": "Khởi động khoản chuyển tiền sớm với thời gian dự phòng, và theo dõi tỷ giá trước ngày cần chuyển.",
      "en": "Initiate the transfer early with a buffer, and watch the rate ahead of the date you need to send."
    },
    "risk_settle_surcharge_underbudgeted_item": {
      "vi": "Phụ phí thuế trước bạ dành cho người mua nước ngoài (thường khoảng 8% giá mua ở NSW/VIC/QLD) dễ bị bỏ sót khi lập ngân sách ban đầu.",
      "en": "The foreign-buyer stamp-duty surcharge (typically around 8% of the price in NSW/VIC/QLD) is easy to overlook in an early budget."
    },
    "risk_settle_surcharge_underbudgeted_action": {
      "vi": "Tính cả phụ phí vào tổng tiền mặt cần để bàn giao ngay từ đầu, không chỉ thuế trước bạ tiêu chuẩn.",
      "en": "Include the surcharge in your total cash-to-settle from the start, not just the standard duty."
    },

    "risk_own_vacancy_fee_exposure_item": {
      "vi": "Chủ sở hữu nước ngoài phải khai báo mức độ sử dụng hằng năm; không đạt ngưỡng sẽ phát sinh phí bỏ trống, đã tăng gấp đôi từ 9/4/2024.",
      "en": "Foreign owners must lodge an annual occupancy declaration; falling short of the threshold triggers the vacancy fee, doubled from 9 April 2024."
    },
    "risk_own_vacancy_fee_exposure_action": {
      "vi": "Đặt lịch nhắc khai báo hằng năm, dù bạn đang ở hay cho thuê nhà.",
      "en": "Set an annual declaration reminder, whether you're living in the property or renting it out."
    },
    "risk_own_no_ppor_land_tax_item": {
      "vi": "Hầu hết các tiểu bang không áp dụng miễn trừ thuế đất cho nơi ở chính đối với chủ sở hữu nước ngoài, khác với người mua trong nước.",
      "en": "Most states offer no principal-residence land-tax exemption to a foreign owner, unlike a domestic owner-occupier."
    },
    "risk_own_no_ppor_land_tax_action": {
      "vi": "Đừng giả định được miễn thuế đất chỉ vì bạn đang ở trong nhà — xác nhận quy định của tiểu bang bạn mua.",
      "en": "Don't assume land-tax exemption just because you live in the home — confirm your state's rule."
    },
    "risk_own_visa_status_change_item": {
      "vi": "Khi được cấp thường trú nhân hay quốc tịch, kế hoạch của bạn có thể đủ điều kiện chuyển sang mô hình trong nước; visa hết hạn cũng có thể ảnh hưởng đến kế hoạch của bạn.",
      "en": "A PR or citizenship grant may make your plan eligible to switch to a domestic mode; a lapsed visa can also affect your plan."
    },
    "risk_own_visa_status_change_action": {
      "vi": "Cập nhật hồ sơ khi tình trạng visa của bạn thay đổi để kế hoạch phản ánh đúng tình trạng hiện tại.",
      "en": "Update your profile when your visa status changes so the plan reflects your current situation."
    },

    "risk_dispose_cgt_position_uncertain_item": {
      "vi": "Quyền miễn thuế lãi vốn (CGT) cho nhà ở chính không tự động áp dụng cho người nước ngoài.",
      "en": "The main-residence CGT exemption does not automatically apply to a foreign person."
    },
    "risk_dispose_cgt_position_uncertain_action": {
      "vi": "Xác nhận với chuyên viên thuế đã đăng ký trước khi bán — kế hoạch nêu trạng thái 'cần kiểm tra' thay vì giả định miễn thuế.",
      "en": "Confirm with a registered tax agent before selling — the plan flags this as 'to verify' rather than assuming the exemption."
    },
    "risk_dispose_frcgw_may_apply_item": {
      "vi": "Nếu bạn là người không cư trú về thuế tại thời điểm bán, một phần tiền bán có thể bị khấu trừ tại thời điểm bàn giao theo cơ chế FRCGW liên bang.",
      "en": "If you're a non-resident for tax at the time of sale, a portion of the sale proceeds may be withheld at settlement under the federal FRCGW mechanism."
    },
    "risk_dispose_frcgw_may_apply_action": {
      "vi": "Xác nhận tình trạng cư trú thuế của bạn tại thời điểm bán với chuyên viên thuế trước khi lên kế hoạch dòng tiền.",
      "en": "Confirm your tax-residency status at the time of sale with a tax adviser before planning your cash flow."
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
    }
  }
}
```
