---
slug: kb.journey.fhg-path
effective_from: 2026-06-01
last_verified: 2026-06-18
---

# Mode-A FHB lifecycle journey (bilingual)

The whole-of-journey template for a Mode-A first-home purchase — the **swimlane** the
`purchase_journey` resolver (`fh_engine_journey`) renders. It carries the journey's
*structure as copy*: the five phase labels (Prepare → Pre-approve → Contract → Settle →
Own), the four actor-row labels (You / Government / Lender / Services), one bilingual line
per meaningful (phase, actor) cell, and the journey's assumptions.

**It stores no figures.** The money flows on the timeline (deposit, stamp duty, total cash
to settle, scheme benefit) are placed by the resolver from the buyer's already-computed
upstream outcomes (`budget_envelope`, `scheme_stack`) — one-computer-per-figure: the
regulated figures are referenced, never recomputed on the journey. So every `{vi, en}` here
is prose; the numbers ride in the outcome's `amount` field, sourced from the calculator.

This is a **copy doc** (it fills no slot). It is a blueprint anchor (component 10 references
it), so it must resolve; structurally only slug==path + content_json-parse + the bilingual
copy gate apply. Vietnamese is authored for register, not transliterated from the English
(trap #4). Decision-support tone, never advice (ASIC). The same `journey_swimlane` shape and
the mode-agnostic `swimlane-diagram` renderer serve Modes B/C/D via their own `kb.journey.*`
docs (plan-card-lifecycle-restoration.md §3.3).

## Rules

Everything above is `content_md`. The `copy` block below is this doc's `content_json` —
the template ids the resolver references, each a `{vi, en}` pair (no `{param}` placeholders:
the figures are structured `amount` fields, not interpolated into prose).

```jsonc
{
  "fills": [],
  "copy": {
    "phase_prepare":     { "vi": "Chuẩn bị",        "en": "Prepare" },
    "phase_pre_approve": { "vi": "Duyệt vay sơ bộ", "en": "Pre-approval" },
    "phase_contract":    { "vi": "Ký hợp đồng",     "en": "Contract" },
    "phase_settle":      { "vi": "Bàn giao",        "en": "Settle" },
    "phase_own":         { "vi": "Sở hữu",          "en": "Own" },

    "actor_you":        { "vi": "Bạn",        "en": "You" },
    "actor_government": { "vi": "Nhà nước",   "en": "Government" },
    "actor_lender":     { "vi": "Ngân hàng",  "en": "Lender" },
    "actor_other":      { "vi": "Dịch vụ",    "en": "Services" },

    "cell_prepare_you": {
      "vi": "Tích lũy tiền cọc và xây dựng lịch sử tiết kiệm thực sự.",
      "en": "Build your deposit and a genuine-savings record."
    },
    "cell_prepare_government": {
      "vi": "Mở tài khoản FHSS và kiểm tra các chương trình hỗ trợ bạn đủ điều kiện.",
      "en": "Open an FHSS account and check which schemes you qualify for."
    },
    "cell_prepare_lender": {
      "vi": "So sánh khả năng vay giữa các ngân hàng.",
      "en": "Compare borrowing capacity across lenders."
    },

    "cell_pre_approve_you": {
      "vi": "Chuẩn bị hồ sơ: phiếu lương, giấy tờ tùy thân, sao kê ngân hàng.",
      "en": "Gather your documents: payslips, ID, bank statements."
    },
    "cell_pre_approve_government": {
      "vi": "Giữ chỗ trong chương trình bảo lãnh cho người mua nhà lần đầu (nếu đủ điều kiện).",
      "en": "Reserve a First Home Guarantee place (if eligible)."
    },
    "cell_pre_approve_lender": {
      "vi": "Nhận duyệt vay sơ bộ có điều kiện, thường có hiệu lực 90 ngày.",
      "en": "Get conditional pre-approval, typically valid for 90 days."
    },
    "cell_pre_approve_other": {
      "vi": "Cân nhắc dùng chuyên viên môi giới vay (mortgage broker).",
      "en": "Consider engaging a mortgage broker."
    },

    "cell_contract_you": {
      "vi": "Ra giá hoặc đấu giá; đặt cọc khi ký hợp đồng.",
      "en": "Make an offer or bid; pay the deposit on exchange."
    },
    "cell_contract_government": {
      "vi": "Nộp hồ sơ xin ưu đãi thuế trước bạ của tiểu bang.",
      "en": "Lodge your state stamp-duty concession application."
    },
    "cell_contract_lender": {
      "vi": "Nộp hồ sơ để được duyệt vay chính thức (vô điều kiện).",
      "en": "Submit for unconditional loan approval."
    },
    "cell_contract_other": {
      "vi": "Kiểm tra nhà và mối; luật sư hoặc chuyên viên chuyển nhượng rà soát hợp đồng.",
      "en": "Building & pest inspection; your conveyancer reviews the contract."
    },

    "cell_settle_you": {
      "vi": "Thanh toán phần còn lại — tổng tiền mặt cần để bàn giao.",
      "en": "Pay the balance — the total cash needed to settle."
    },
    "cell_settle_government": {
      "vi": "Thuế trước bạ (stamp duty) đến hạn nộp.",
      "en": "Stamp duty falls due."
    },
    "cell_settle_lender": {
      "vi": "Ngân hàng giải ngân; khoản vay của bạn bắt đầu.",
      "en": "The lender releases funds; your loan begins."
    },
    "cell_settle_other": {
      "vi": "Hoàn tất bàn giao qua PEXA; sang tên trên sổ.",
      "en": "Settlement completes via PEXA; the title transfers to you."
    },

    "cell_own_you": {
      "vi": "Dọn vào ở; chương trình bảo lãnh kết thúc khi LVR còn 80%.",
      "en": "Move in; the guarantee falls away once your LVR reaches 80%."
    },
    "cell_own_government": {
      "vi": "Được miễn thuế đất vì đây là nơi ở chính của bạn.",
      "en": "Land tax is exempt — this is your principal home."
    },
    "cell_own_lender": {
      "vi": "Cơ hội tái cấp vốn mở ra khi LVR xuống dưới 80%.",
      "en": "A refinance window opens once your LVR drops below 80%."
    },

    "cell_own_recurring": {
      "vi": "Chi phí định kỳ hằng năm: thuế suất hội đồng và nước.",
      "en": "Ongoing yearly outgoings: council rates and water."
    },

    "assumption_indicative": {
      "vi": "Sơ đồ hành trình mang tính tổng quan cho người mua nhà lần đầu tại Úc; mốc thời gian và thứ tự có thể thay đổi theo tiểu bang và theo giao dịch cụ thể.",
      "en": "This journey is a general overview for first-home buyers in Australia; timing and order vary by state and by your specific transaction."
    },
    "assumption_figures": {
      "vi": "Các con số trên dòng thời gian được lấy từ phần tính toán của kế hoạch (tiền cọc, thuế trước bạ, tổng tiền mặt) — không tính lại tại đây.",
      "en": "The figures on the timeline come from your plan's calculator (deposit, stamp duty, total cash) — they are not recomputed here."
    }
  }
}
```
