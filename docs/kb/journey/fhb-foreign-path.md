---
slug: kb.journey.fhb-foreign-path
effective_from: 2026-07-11
last_verified: 2026-07-11
---

# Mode-B foreign-FHB lifecycle journey (bilingual)

The whole-of-journey template for a Mode-B foreign-person first-home purchase — the **swimlane**
the `purchase_journey` resolver (`fh_engine_journey`, Mode-B branch) renders. Same six phases and
**Mode A's own four actors** (You / Government / Lender / Services — `plan-card-lifecycle-
restoration.md` §3.3: "B = A's shape + a FIRB gate + a currency-transfer milestone + surcharge",
not Mode C/D's six-actor investor set) with Mode B's content layered on top: a **FIRB approval
gate**, a **currency-transfer milestone**, and the **foreign-buyer surcharge**.

**Actors — reuses Mode A's four unchanged, no new row added.** You / Government / Lender /
Services. The swimlane's actor set must be a superset of every cash_event counterparty this
mode's figure-owners emit (`cash_position`, `disposition`) — government (stamp duty, foreign-
buyer surcharge, FIRB fee), lender (loan), "other"/services (deposit held in trust, transaction
costs) — all already sit inside Mode A's four. This matches `disposition`'s own dispatch
(`fh_engine_disposition:fill/2` routes Mode B onto `fill_owner_occupier/2`, the same function
Mode A uses, keyed on the absence of `tax_optimised_structure` upstream — Mode B never runs a
`tax_structure` component) — so the dispose-phase money cells already carry `counterparty =
<<"other">>` for `sale_proceeds`/`selling_costs`, exactly Mode A's convention, not Mode C/D's
`services`. A seventh actor for the cross-border transfer provider (Wise, OFX, bank wire) is not
needed for the same reason Mode D's six-actor set has none: it is a service the buyer engages
once, not a party with a recurring relationship — the transfer milestone narrates as `other`/
services cells. VN-side capital-control steps (SBV threshold check, declared-purpose
documentation) are `you`/`other` prose, not a jurisdiction-ambiguous `government` cell (AU FIRB
and VN SBV are two different governments).

**Phases.** Same six phase ids as every mode (`prepare → pre_approve → contract → settle → own →
dispose`). The **FIRB gate** is not a seventh phase — it is the literal condition-precedent
narrated across `pre_approve` (application prepared) through `contract` (submitted, fee paid;
`kb.firb.application-process` — the 30-day statutory decision clock starts only once the fee is
paid in full) to `settle` (approval confirmed before settlement can proceed; FATA 1975's
must-not-act-before-approval rule). The **currency-transfer milestone** runs the same span:
initiated at `contract` (to cover the deposit), completed by `settle` (to cover the balance) —
narrated on the `other`/services cells, mirroring `kb.journey.investor-foreign-path`'s placement.
The **foreign-buyer surcharge** is disclosed alongside standard stamp duty on the `contract`/
`settle` government cells — both fall due at settlement, with no first-home concession (Mode B is
a foreign person; the concession is domestic-buyer-only). The terminal `dispose` phase renders
only when a hold horizon `H` is set (honest-partial, same rule as every other mode).

**It stores no figures.** Every `{vi, en}` here is prose; the money flows on the timeline are
placed by the resolver from already-computed upstream outcomes — one-computer-per-figure. The
acquisition-phase amounts (deposit, stamp duty, foreign-buyer surcharge, FIRB fee, other buying
costs) come from `cash_position`'s `budget_envelope.cash_events`; the dispose-phase amounts (sale
proceeds, selling costs, loan payout) come from `disposition`'s `dispose_cash_events`.

**CGT is deliberately never asserted as exempt here** (unlike Mode A's `cell_dispose_government`).
`fh_engine_fill:buyer_profile_foreign/1` leaves `profile.tax_residency` unset by design (a
Mode-B applicant's tax residency at a future sale is genuinely unknown — foreign person, possibly
a temp resident who has since left or stayed), so `fh_engine_disposition:cgt/1` always falls
through to `to_verify`, never `exempt` (`plan-card-lifecycle-restoration.md` §11.8, task 11). The
dispose-phase government cell below narrates this honestly — "confirm your position", never "you
are exempt" — and `full_horizon_net_position` stays permanently null for the same reason (no
resolver computes a foreign owner's land-tax dollar figure — `kb.tax.land-tax-by-state` — for any
mode, task 11's Option-1 finding).

This is a **copy doc** (it fills no slot). It is a blueprint anchor (component 13, added
2026-07-11 alongside `phase_playbook`), so it must resolve; structurally only slug==path +
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
    "phase_prepare":     { "vi": "Chuẩn bị",        "en": "Prepare" },
    "phase_pre_approve": { "vi": "Duyệt vay sơ bộ", "en": "Pre-approval" },
    "phase_contract":    { "vi": "Ký hợp đồng",     "en": "Contract" },
    "phase_settle":      { "vi": "Bàn giao",        "en": "Settle" },
    "phase_own":         { "vi": "Sở hữu",          "en": "Own" },
    "phase_dispose":     { "vi": "Bán nhà",         "en": "Sell" },

    "actor_you":        { "vi": "Bạn",        "en": "You" },
    "actor_government": { "vi": "Nhà nước",   "en": "Government" },
    "actor_lender":     { "vi": "Ngân hàng",  "en": "Lender" },
    "actor_other":      { "vi": "Dịch vụ",    "en": "Services" },

    "cell_prepare_you": {
      "vi": "Xác định tình trạng FIRB của bạn và xem loại bất động sản nào bạn được phép mua (chỉ nhà mới xây hoặc đất trống).",
      "en": "Clarify your FIRB status and which property types you're eligible to buy (new-build or vacant land only)."
    },
    "cell_prepare_government": {
      "vi": "Không có chương trình hỗ trợ người mua nhà lần đầu nào áp dụng cho người nước ngoài — ước tính chi phí ở mức thuế đầy đủ, cộng phụ phí.",
      "en": "No first-home buyer scheme applies to a foreign person — costs are estimated at full duty, plus the surcharge."
    },
    "cell_prepare_lender": {
      "vi": "So sánh nhóm ngân hàng hẹp chấp nhận cho vay với người không cư trú hoặc thường trú tạm thời.",
      "en": "Compare the narrower pool of lenders willing to fund a non-resident or temporary-resident buyer."
    },
    "cell_prepare_other": {
      "vi": "Bắt đầu tìm hiểu các nhà cung cấp chuyển tiền được cấp phép (Wise, OFX, chuyển khoản ngân hàng) sớm.",
      "en": "Start researching licensed transfer providers (Wise, OFX, bank wire) early."
    },

    "cell_pre_approve_you": {
      "vi": "Chuẩn bị hồ sơ: hộ chiếu, giấy tờ visa, bằng chứng thu nhập, và bằng chứng nguồn vốn hợp pháp.",
      "en": "Gather your documents: passport, visa evidence, proof of income, and evidence of the legitimate source of your funds."
    },
    "cell_pre_approve_government": {
      "vi": "Bắt đầu chuẩn bị hồ sơ xin phê duyệt FIRB.",
      "en": "Begin preparing the FIRB application."
    },
    "cell_pre_approve_lender": {
      "vi": "Nhận duyệt vay sơ bộ có điều kiện dành cho người nước ngoài; mức đặt cọc yêu cầu thường cao hơn.",
      "en": "Get conditional pre-approval on the foreign-person loan path; the required deposit is typically higher."
    },
    "cell_pre_approve_other": {
      "vi": "Lên kế hoạch thời điểm chuyển tiền cùng với thời hạn dự kiến của các mốc mua nhà.",
      "en": "Plan your transfer timing alongside the expected buying-process milestones."
    },

    "cell_contract_you": {
      "vi": "Ra giá với điều kiện tùy thuộc vào việc được FIRB phê duyệt; đặt cọc khi ký hợp đồng.",
      "en": "Make an offer subject to FIRB approval; pay the deposit on exchange."
    },
    "cell_contract_government": {
      "vi": "Hồ sơ FIRB được nộp và phí được xác định theo giá trị bất động sản; thuế trước bạ đầy đủ cộng phụ phí người mua nước ngoài sẽ áp dụng — không có ưu đãi người mua nhà lần đầu.",
      "en": "The FIRB application is submitted and the fee is determined by property value; full stamp duty plus the foreign-buyer surcharge will apply — no first-home concession."
    },
    "cell_contract_lender": {
      "vi": "Nộp hồ sơ xin duyệt vay chính thức, có điều kiện tùy thuộc vào việc FIRB phê duyệt.",
      "en": "Submit for unconditional loan approval, conditional on FIRB approval."
    },
    "cell_contract_other": {
      "vi": "Kiểm tra nhà (với nhà mới xây, chú ý lỗi hoàn thiện); luật sư rà soát hợp đồng; khoản chuyển tiền cho tiền cọc được khởi động.",
      "en": "Inspect the property (for a new build, watch for completion defects); your conveyancer reviews the contract; the deposit transfer is initiated."
    },

    "cell_settle_you": {
      "vi": "Thanh toán phần còn lại — tổng tiền mặt cần để bàn giao, gồm cả phí FIRB và phụ phí người mua nước ngoài.",
      "en": "Pay the balance — the total cash needed to settle, including the FIRB fee and the foreign-buyer surcharge."
    },
    "cell_settle_government": {
      "vi": "Phê duyệt FIRB được xác nhận trước khi bàn giao; thuế trước bạ và phụ phí người mua nước ngoài đến hạn nộp.",
      "en": "FIRB approval is confirmed ahead of settlement; stamp duty and the foreign-buyer surcharge fall due."
    },
    "cell_settle_lender": {
      "vi": "Ngân hàng giải ngân; khoản vay của bạn bắt đầu.",
      "en": "The lender releases funds; your loan begins."
    },
    "cell_settle_other": {
      "vi": "Khoản chuyển tiền cho phần còn lại hoàn tất trước hạn bàn giao; bàn giao hoàn tất qua PEXA; sang tên trên sổ.",
      "en": "The balance transfer completes ahead of the settlement deadline; settlement completes via PEXA; the title transfers to you."
    },

    "cell_own_you": {
      "vi": "Dọn vào ở nếu đây là nơi ở của bạn; theo dõi tình trạng visa vì thay đổi có thể ảnh hưởng đến kế hoạch của bạn.",
      "en": "Move in if this is your home; keep an eye on your visa status, as a change can affect your plan."
    },
    "cell_own_government": {
      "vi": "Chủ sở hữu nước ngoài phải khai báo mức độ sử dụng hằng năm để tránh phí bỏ trống; không có miễn trừ thuế đất dành cho nơi ở chính đối với người nước ngoài ở hầu hết các tiểu bang.",
      "en": "Foreign owners must lodge an annual occupancy declaration to avoid the vacancy fee; most states offer no principal-residence land-tax exemption for a foreign owner."
    },
    "cell_own_lender": {
      "vi": "Cơ hội tái cấp vốn bị giới hạn trong nhóm ngân hàng hẹp dành cho người nước ngoài.",
      "en": "Refinance opportunities are limited to the narrower foreign-person lender pool."
    },

    "cell_own_recurring": {
      "vi": "Chi phí định kỳ hằng năm: thuế suất hội đồng và nước.",
      "en": "Ongoing yearly outgoings: council rates and water."
    },

    "cell_dispose_you": {
      "vi": "Quyết định bán và thời điểm bán; phần vốn (equity) bạn đã tích lũy có thể trở thành nguồn vốn cho bước tiếp theo.",
      "en": "Decide whether and when to sell; the equity you've built can become the funds for your next step."
    },
    "cell_dispose_government": {
      "vi": "Vị trí thuế lãi vốn (CGT) của bạn cần xác nhận — quyền miễn trừ nhà ở chính không tự động áp dụng cho người nước ngoài; xác nhận với chuyên viên thuế đã đăng ký trước khi bán.",
      "en": "Your capital gains tax position needs confirming — the main-residence exemption does not automatically apply to a foreign person; confirm with a registered tax agent before selling."
    },
    "cell_dispose_lender": {
      "vi": "Khoản vay còn lại được tất toán từ tiền bán nhà khi hoàn tất giao dịch.",
      "en": "Your remaining loan is discharged from the sale proceeds at settlement."
    },
    "cell_dispose_other": {
      "vi": "Đại lý bán nhà tiếp thị căn nhà; chuyên viên chuyển nhượng lo thủ tục sang tên; vốn ròng có thể cần chuyển về Việt Nam qua kênh chuyển tiền được cấp phép.",
      "en": "A selling agent markets the property; your conveyancer handles the transfer; the net proceeds may need to be transferred back to Vietnam via a licensed provider."
    },

    "assumption_indicative": {
      "vi": "Sơ đồ hành trình mang tính tổng quan cho người nước ngoài mua nhà lần đầu tại Úc; mốc thời gian, thứ tự, và các nghĩa vụ FIRB/chuyển tiền có thể thay đổi theo tiểu bang và theo giao dịch cụ thể.",
      "en": "This journey is a general overview for a foreign person buying a first home in Australia; timing, order, and FIRB/transfer obligations vary by state and by your specific transaction."
    },
    "assumption_figures": {
      "vi": "Các con số trên dòng thời gian được lấy từ phần tính toán của kế hoạch (tiền cọc, thuế trước bạ, phụ phí, phí FIRB) — không tính lại tại đây.",
      "en": "The figures on the timeline come from your plan's calculator (deposit, stamp duty, surcharge, FIRB fee) — they are not recomputed here."
    },
    "assumption_no_fhb_schemes": {
      "vi": "Không có chương trình hỗ trợ người mua nhà lần đầu nào áp dụng — người nước ngoài không đủ điều kiện tham gia Bảo lãnh Người mua nhà lần đầu, FHSS, hay ưu đãi thuế trước bạ của tiểu bang.",
      "en": "No first-home buyer scheme applies — a foreign person is not eligible for the First Home Guarantee, FHSS, or a state stamp-duty concession."
    }
  }
}
```
