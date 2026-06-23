---
slug: kb.risks.fhb-by-phase
effective_from: 2026-06-01
last_verified: 2026-06-20
---

# Mode-A FHB per-phase risks and mitigations (bilingual)

The **risk-management layer** of the legal/temporal spine — for each lifecycle phase, the
often-seen risks a Mode-A first-home buyer faces and the mitigation for each. It is the
content the `phase_playbook` resolver (component 12) renders as a `risk-flag-list` behind
each Flow-view phase sheet. Where the action checklist (`kb.journey.phase-actions`) says
*what to do*, this doc says *what tends to go wrong, and how buyers manage it*.

**Every risk here is grounded in the transactional KB, never generated.** Each risk is drawn
from an owning rulebook doc and carries that provenance in `content_md` below: the auction
"no escape" rule from `kb.cooling-off.by-state` + `kb.auction.rules-by-state`; subject-to-
finance from `kb.special-conditions.standard-set`; building/pest from
`kb.building-pest.interpretation`; disclosure from `kb.s32.review-points` +
`kb.contract-of-sale.review-points-by-state`; selling-agent tactics from
`kb.agent-tactics.detection`; insurance timing from `kb.insurance.timing-of-risk-pass`;
land tax from `kb.land-tax.ppor-exemption`; ongoing costs from
`kb.ongoing-costs.rates-water-strata`; genuine savings / capacity from
`kb.cash-reserve.lender-expectations` + `kb.lender.serviceability-basics`. **Honest-partial:
a phase surfaces only the risks the KB substantiates** — a phase with no grounded risk shows
none, never a fabricated one.

This is a **copy doc** (it fills no slot). It is a blueprint anchor (component 12 references
it), so it must resolve; structurally only slug==path + content_json-parse + the bilingual
copy gate apply. Vietnamese is authored for register, not transliterated from the English
(trap #4). **Decision-support, not advice (ASIC):** risks are surfaced informationally ("here
is what often goes wrong and how buyers manage it"), each with a stated mitigation that
points to the buyer's licensed professional where finance, credit or law is involved — never
as a recommendation.

## Risk provenance (per phase)

- **prepare** — *genuine savings* (a recent large gift may not count): `kb.cash-reserve.lender-expectations`, `kb.preparation.fhb-readiness`. *capacity overestimate* (HECS/BNPL/credit cards reduce capacity): `kb.lender.serviceability-basics`, `kb.lender.hecs-treatment-by-lender`, `kb.lender.bnpl-treatment-2026`, `kb.lender.credit-card-treatment`.
- **pre_approve** — *pre-approval lapses* (conditional, ~90-day validity): `kb.lender-docs.standard-timeline`, `kb.journey.fhg-path`. *FHG places limited* (reserved via panel lender): `kb.lender.fhg-panel-list`.
- **contract** — *auction has no escape* (no cooling-off, no subject-to-finance/inspection): `kb.cooling-off.by-state`, `kb.auction.rules-by-state`. *finance falls through* (no subject-to-finance ⇒ deposit at risk): `kb.special-conditions.standard-set`. *short cooling-off* (3–5 business days, penalty-bearing): `kb.cooling-off.by-state`. *undisclosed defects* (no builder warranty; structural/termite): `kb.building-pest.interpretation`. *contract/disclosure gaps* (easements, overlays, OC, notices): `kb.s32.review-points`, `kb.contract-of-sale.review-points-by-state`. *selling-agent pressure*: `kb.agent-tactics.detection`.
- **settle** — *insurance gap* (QLD risk passes day after contract): `kb.insurance.timing-of-risk-pass`. *settlement shortfall* (funds not cleared ⇒ delay/penalty interest): `kb.settlement.process-by-state`, `kb.pexa.settlement`. *changed condition at handover*: `kb.special-conditions.standard-set`.
- **own** — *PPOR status* (land-tax exemption / owner-occupier basis depend on it): `kb.land-tax.ppor-exemption`. *ongoing costs under-budgeted*: `kb.ongoing-costs.rates-water-strata`, `kb.maintenance.budget-by-property-type`.
- **dispose** — *selling costs erode equity* (agent commission + legal + marketing reduce the net): `kb.selling-costs.agent-legal`. *CGT exemption trap* (lost if rented out / non-resident for tax at disposal / land > 2 ha): `kb.tax.cgt-main-residence-exemption`. *market timing* (proceeds depend on capital growth, not guaranteed — a conservative band, not a forecast): `kb.property.capital-growth-bands`.

## Rules

Everything above is `content_md`. The `content_json` below has two parts:

- `layout.phases[]` — the **structure** the resolver reads: per phase, a `risks[]` list, each
  with a stable `id` and `severity` (`low | medium | high`). The risk/mitigation prose is
  referenced by convention: `risk_<phase>_<id>_item` (the often-seen risk) and
  `risk_<phase>_<id>_action` (the mitigation) in `copy`.
- `copy` — the flat `{vi, en}` prose templates (the bilingual-gated part).

Resolver mapping (the shape `fh_engine_phase_playbook` assembles, W-slice 3): for each
`layout.phases[].risks[]` entry, emit a `risk-flag-list` item `{ severity, item ←
risk_<phase>_<id>_item, action ← risk_<phase>_<id>_action }`. The resolver **merges by
`phase`** with `kb.journey.phase-actions` so each phase's outcome carries both its `actions`
and its `risks`.

```jsonc
{
  "fills": [],
  "layout": {
    "phases": [
      {
        "phase": "prepare",
        "risks": [
          { "id": "genuine_savings",      "severity": "medium" },
          { "id": "capacity_overestimate","severity": "medium" }
        ]
      },
      {
        "phase": "pre_approve",
        "risks": [
          { "id": "preapproval_lapses", "severity": "medium" },
          { "id": "fhg_places_limited", "severity": "medium" }
        ]
      },
      {
        "phase": "contract",
        "risks": [
          { "id": "auction_no_escape",   "severity": "high" },
          { "id": "finance_falls_through","severity": "high" },
          { "id": "short_cooling_off",   "severity": "medium" },
          { "id": "undisclosed_defects", "severity": "high" },
          { "id": "disclosure_gaps",     "severity": "medium" },
          { "id": "agent_pressure",      "severity": "medium" }
        ]
      },
      {
        "phase": "settle",
        "risks": [
          { "id": "insurance_gap",        "severity": "high" },
          { "id": "settlement_shortfall", "severity": "medium" },
          { "id": "changed_condition",    "severity": "low" }
        ]
      },
      {
        "phase": "own",
        "risks": [
          { "id": "ppor_status",       "severity": "medium" },
          { "id": "ongoing_underbudget","severity": "medium" }
        ]
      },
      {
        "phase": "dispose",
        "risks": [
          { "id": "selling_costs_erode", "severity": "medium" },
          { "id": "cgt_trap",            "severity": "medium" },
          { "id": "market_timing",       "severity": "low" }
        ]
      }
    ]
  },
  "copy": {
    "risk_prepare_genuine_savings_item": {
      "vi": "Một khoản tiền được tặng gần đây có thể không được tính là “genuine savings”, làm chậm việc duyệt vay.",
      "en": "A recent large gift may not count as “genuine savings”, which can hold up your loan approval."
    },
    "risk_prepare_genuine_savings_action": {
      "vi": "Tích lũy khoản tiết kiệm đều đặn theo thời gian, hoặc xác nhận với ngân hàng/chuyên viên môi giới xem khoản nào được chấp nhận.",
      "en": "Build a steady savings record over time, or confirm with your lender or broker which funds will be accepted."
    },
    "risk_prepare_capacity_overestimate_item": {
      "vi": "Khả năng vay thực tế thường thấp hơn dự tính một khi tính đến khoản vay HECS, thẻ tín dụng và mua-trả-sau (BNPL).",
      "en": "Your real borrowing capacity is often lower than expected once HECS, credit cards and buy-now-pay-later limits are counted."
    },
    "risk_prepare_capacity_overestimate_action": {
      "vi": "So sánh khả năng vay giữa các ngân hàng và cân nhắc giảm hoặc đóng các hạn mức tín dụng không dùng tới.",
      "en": "Compare capacity across lenders and consider reducing or closing unused credit limits."
    },

    "risk_pre_approve_preapproval_lapses_item": {
      "vi": "Duyệt vay sơ bộ có điều kiện và thường chỉ có hiệu lực khoảng 90 ngày — nó có thể hết hạn hoặc bị xét lại.",
      "en": "Pre-approval is conditional and typically valid for only about 90 days — it can lapse or be re-assessed."
    },
    "risk_pre_approve_preapproval_lapses_action": {
      "vi": "Theo dõi ngày hết hạn và tránh ra giá dựa trên hồ sơ đã cũ; xin gia hạn nếu việc tìm nhà kéo dài.",
      "en": "Track the expiry and avoid making an offer on a stale approval; ask to renew it if your search runs long."
    },
    "risk_pre_approve_fhg_places_limited_item": {
      "vi": "Suất tham gia chương trình Bảo lãnh Người mua nhà lần đầu (FHG) có hạn và được giữ chỗ qua ngân hàng tham gia chương trình.",
      "en": "First Home Guarantee places are limited and are reserved through a participating lender."
    },
    "risk_pre_approve_fhg_places_limited_action": {
      "vi": "Giữ chỗ sớm qua một ngân hàng trong danh sách tham gia chương trình thay vì để đến phút chót.",
      "en": "Reserve a place early through a panel lender rather than leaving it to the last minute."
    },

    "risk_contract_auction_no_escape_item": {
      "vi": "Khi đấu giá, không có thời gian cân nhắc rút lui (cooling-off), không có điều kiện “tùy thuộc duyệt vay” hay “tùy thuộc kiểm tra” — bạn bị ràng buộc ngay khi búa gõ.",
      "en": "At auction there is no cooling-off, no subject-to-finance and no subject-to-inspection — you are bound on the fall of the hammer."
    },
    "risk_contract_auction_no_escape_action": {
      "vi": "Hoàn tất duyệt vay chính thức (vô điều kiện), kiểm tra nhà và mối, và rà soát hợp đồng TRƯỚC khi tham gia đấu giá.",
      "en": "Complete unconditional finance, building & pest inspections, and contract review BEFORE you bid at auction."
    },
    "risk_contract_finance_falls_through_item": {
      "vi": "Không có điều kiện “tùy thuộc duyệt vay”, nếu khoản vay bị từ chối bạn có thể mất tiền cọc.",
      "en": "Without a subject-to-finance condition, a failed loan can mean you forfeit your deposit."
    },
    "risk_contract_finance_falls_through_action": {
      "vi": "Khi mua theo thương lượng, đưa điều kiện “tùy thuộc duyệt vay” với một ngày duyệt vay thực tế vào lời đề nghị.",
      "en": "On a private-treaty offer, include a subject-to-finance condition with a realistic approval date."
    },
    "risk_contract_short_cooling_off_item": {
      "vi": "Thời gian cân nhắc rút lui khi mua theo thương lượng rất ngắn (3–5 ngày làm việc) và việc rút lui phải chịu phạt (~0,25% giá mua).",
      "en": "The private-treaty cooling-off window is short (3–5 business days) and withdrawing carries a penalty (around 0.25% of the price)."
    },
    "risk_contract_short_cooling_off_action": {
      "vi": "Dùng khoảng thời gian này cho việc kiểm tra và luật sư rà soát; đừng xem nó như một lối thoát miễn phí.",
      "en": "Use the window for inspections and solicitor review; don't treat it as a free exit."
    },
    "risk_contract_undisclosed_defects_item": {
      "vi": "Nhà cũ không có bảo hành xây dựng theo luật; lỗi kết cấu nghiêm trọng hoặc mối đang hoạt động có thể rất tốn kém.",
      "en": "An established home has no statutory builder's warranty; major structural defects or active termites can be costly."
    },
    "risk_contract_undisclosed_defects_action": {
      "vi": "Đặt kiểm tra nhà và kiểm tra mối, và phân biệt lỗi nghiêm trọng với hao mòn thông thường.",
      "en": "Commission building and pest inspections, and separate major defects from ordinary wear and tear."
    },
    "risk_contract_disclosure_gaps_item": {
      "vi": "Hợp đồng / Mục 32 có thể ẩn chứa quyền sử dụng đất của người khác (easement), quy hoạch hạn chế, vấn đề của ban quản trị chung cư, hoặc các thông báo của cơ quan công quyền.",
      "en": "The contract / Section 32 may hide easements, restrictive planning overlays, owners-corporation problems, or authority notices."
    },
    "risk_contract_disclosure_gaps_action": {
      "vi": "Để chuyên viên chuyển nhượng hoặc luật sư rà soát bản tiết lộ trước khi bạn ký.",
      "en": "Have your conveyancer or solicitor review the disclosure before you sign."
    },
    "risk_contract_agent_pressure_item": {
      "vi": "Đại lý bán đại diện cho người bán — báo giá thấp để hút khách, bịa “đã có người trả giá”, hoặc tạo gấp gáp giả để đẩy giá lên.",
      "en": "The selling agent acts for the vendor — underquoting to draw a crowd, claiming phantom offers, or creating false urgency to push the price up."
    },
    "risk_contract_agent_pressure_action": {
      "vi": "Định giá độc lập, giữ một mức giá dừng, và không bao giờ ký khi chưa có duyệt vay và chưa thẩm định xong.",
      "en": "Value independently, hold a walk-away number, and never sign without finance approval and completed due diligence."
    },

    "risk_settle_insurance_gap_item": {
      "vi": "Ở QLD rủi ro chuyển sang người mua ngay ngày làm việc kế tiếp sau khi ký hợp đồng; chậm mua bảo hiểm để lại một khoảng trống không được bảo vệ trước khi bàn giao.",
      "en": "In QLD risk passes to the buyer the business day after contract; delaying insurance leaves an uninsured gap before settlement."
    },
    "risk_settle_insurance_gap_action": {
      "vi": "Mua bảo hiểm nhà có hiệu lực từ đúng thời điểm rủi ro chuyển sang bạn theo luật của tiểu bang.",
      "en": "Bind building insurance effective from the moment risk passes under your state's rules."
    },
    "risk_settle_settlement_shortfall_item": {
      "vi": "Tiền chưa về kịp hoặc thiếu hụt vào ngày bàn giao có thể làm chậm việc bàn giao và phát sinh lãi phạt.",
      "en": "Funds not cleared, or a shortfall on the day, can delay settlement and incur penalty interest."
    },
    "risk_settle_settlement_shortfall_action": {
      "vi": "Xác nhận tổng tiền mặt cần để bàn giao đã có sẵn và đã thông khoản trước ngày hẹn.",
      "en": "Confirm the total cash to settle is available and cleared ahead of the date."
    },
    "risk_settle_changed_condition_item": {
      "vi": "Tình trạng nhà hoặc các hạng mục kèm theo đã thỏa thuận có thể thay đổi giữa lúc ký hợp đồng và lúc bàn giao.",
      "en": "The property's condition or the agreed inclusions may have changed between contract and settlement."
    },
    "risk_settle_changed_condition_action": {
      "vi": "Kiểm tra lần cuối trước khi bàn giao để đối chiếu với hợp đồng.",
      "en": "Do a final inspection before settlement to check against the contract."
    },

    "risk_own_ppor_status_item": {
      "vi": "Việc miễn thuế đất và cơ sở “ở để dùng” của các chương trình phụ thuộc vào việc nhà vẫn là nơi ở chính; cho thuê hoặc dọn ra có thể làm phát sinh thuế đất.",
      "en": "Your land-tax exemption and the owner-occupier basis of your schemes depend on this staying your principal home; renting it out or moving out can trigger land tax."
    },
    "risk_own_ppor_status_action": {
      "vi": "Giữ nhà là nơi ở chính, hoặc hỏi ý kiến chuyên gia trước khi thay đổi mục đích sử dụng.",
      "en": "Keep the home as your principal residence, or get advice before changing its use."
    },
    "risk_own_ongoing_underbudget_item": {
      "vi": "Thuế suất hội đồng, tiền nước và phí chung cư là các khoản định kỳ rất dễ bị tính thiếu sau khi dọn vào ở.",
      "en": "Council rates, water and strata are recurring costs that are easy to under-budget after you move in."
    },
    "risk_own_ongoing_underbudget_action": {
      "vi": "Dự trù các khoản chi định kỳ và giữ một khoản dự phòng cho chi phí phát sinh.",
      "en": "Budget for the recurring outgoings and keep a buffer for unexpected costs."
    },

    "risk_dispose_selling_costs_erode_item": {
      "vi": "Chi phí bán nhà — hoa hồng đại lý (~1,5%–3,5%), phí pháp lý và tiếp thị — làm giảm phần vốn bạn thực nhận, dễ bị bỏ sót khi ước tính tiền thu về.",
      "en": "Selling costs — agent commission (~1.5%–3.5%), legal and marketing — reduce the equity you actually receive, and are easy to overlook when estimating proceeds."
    },
    "risk_dispose_selling_costs_erode_action": {
      "vi": "Tính chi phí bán vào kỳ vọng vốn ròng và thương lượng mức hoa hồng; kế hoạch chiếu các chi phí này như một dải, không phải con số cố định.",
      "en": "Factor selling costs into your net-equity expectation and negotiate the commission; the plan shows these as a band, not a fixed figure."
    },
    "risk_dispose_cgt_trap_item": {
      "vi": "Quyền miễn thuế lãi vốn (CGT) cho nhà ở chính có thể mất nếu bạn đã cho thuê nhà, trở thành người không cư trú về thuế khi bán, hoặc đất rộng hơn 2 ha.",
      "en": "The main-residence CGT exemption can be lost if you've rented the home out, become a non-resident for tax at the time of sale, or the land is over 2 hectares."
    },
    "risk_dispose_cgt_trap_action": {
      "vi": "Nếu bất kỳ trường hợp nào áp dụng, hãy xác nhận với chuyên viên thuế đã đăng ký hoặc ATO trước khi bán — kế hoạch nêu trạng thái “cần kiểm tra” thay vì giả định miễn thuế.",
      "en": "If any of these apply, confirm with a registered tax agent or the ATO before selling — the plan flags this as 'to verify' rather than assuming the exemption."
    },
    "risk_dispose_market_timing_item": {
      "vi": "Tiền bán nhà phụ thuộc vào tăng trưởng giá trị tại thời điểm bạn bán; tăng trưởng không được bảo đảm và có thể chững lại hoặc giảm.",
      "en": "Sale proceeds depend on capital growth at the time you sell; growth is not guaranteed and can stall or fall."
    },
    "risk_dispose_market_timing_action": {
      "vi": "Xem phần tiền thu về dự kiến như một dải ước tính thận trọng, không phải dự báo, và đừng phụ thuộc vào một mức tăng trưởng cụ thể.",
      "en": "Treat projected proceeds as a conservative band, not a forecast, and don't rely on a specific growth rate."
    }
  }
}
```
