---
slug: kb.preparation.fhb-readiness
effective_from: 2026-06-01
last_verified: 2026-06-18
sources:
  - note: "NOT VERIFIED — bilingual copy/checklist doc (kb.copy.*-adjacent in kind, though not in that namespace): every readiness item is grounded internally in its owning KB doc (the scheme, FIRB, or lender fact it points to), not asserted independently here. No external Sources section by design. Checked 2026-07-06 during the Phase B backfill."
---

# Mode-A FHB readiness template (bilingual)

The property-agnostic **readiness layer** a Mode-A first-home buyer can act on before any
specific property exists — the documents to gather, the people to line up, the scheme
applications to prepare, and the cash buffer to hold. It is the template the `preparation`
resolver (component 11) renders as a `checklist` + `data-table`. It is the prototype's
"Before you buy" content, surfaced at onboarding rather than buried in the per-property
`due_diligence` (7).

**It stores no figures.** The buffer figures on the readiness table (`reserve_buffer`, the
`genuine_savings_verdict`) are placed by the resolver from the buyer's already-computed
`budget_envelope` — one-computer-per-figure: referenced, never recomputed here. Likewise
*which* scheme applications appear is placed from the buyer's `scheme_stack`; this doc only
carries the bilingual **action** prose per scheme. So every `{vi, en}` here is prose; the
numbers and the applicable-scheme set ride in the outcome.

This is a **copy doc** (it fills no slot). It is a blueprint anchor (component 11 references
it), so it must resolve; structurally only slug==path + content_json-parse + the bilingual
copy gate apply. Vietnamese is authored for register, not transliterated from the English
(trap #4). Decision-support tone, never advice — the checklist and roles are informational
(ASIC: no financial/credit advice; the buyer decides). The `document_checklist[].status` is
a **user-attested** fact (the "Chưa có / Đã có" toggle): the resolver seeds every item
`not_started`; the user sets it, and it is stored on the card.

## Rules

Everything above is `content_md`. The `copy` block below is this doc's `content_json` — the
template ids the `preparation` resolver references, each a `{vi, en}` pair (no `{param}`
placeholders: the figures are structured outcome fields, not interpolated into prose).

Resolver mapping (the shape `fh_engine_preparation` assembles, W6):
- `document_checklist[]` — one entry per `doc_*` pair: stable `id` ∈ {`photo_id`, `noa`,
  `payslips`, `bank_statements`, `deposit_evidence`}, `item` ← `doc_<id>_item`, `why` ←
  `doc_<id>_why`, `status` seeded `not_started`.
- `people_to_engage[]` — one entry per `person_*` triple: `role` ← `person_<id>_role`,
  `when` ← `person_<id>_when`, `why` ← `person_<id>_why`, for `id` ∈ {`broker`,
  `conveyancer`, `buyers_agent`}.
- `scheme_applications_to_prepare[]` — placed by iterating `scheme_stack.applicable_schemes`;
  `action` ← `scheme_action_<scheme>` if present, else `scheme_action_default`.
- `money_buffer.notes[]` — `buffer_note_general` plus `buffer_note_<genuine_savings_verdict>`
  for the verdict placed from `budget_envelope`.
- `key_assumptions[]` — the `assumption_*` lines.

```jsonc
{
  "fills": [],
  "copy": {
    "doc_photo_id_item": {
      "vi": "Giấy tờ tùy thân có ảnh",
      "en": "Photo ID"
    },
    "doc_photo_id_why": {
      "vi": "Bằng lái xe hoặc hộ chiếu để xác minh danh tính khi nộp hồ sơ vay.",
      "en": "A driver licence or passport to verify your identity for the loan application."
    },
    "doc_noa_item": {
      "vi": "Thông báo quyết toán thuế (Notice of Assessment)",
      "en": "Notice of Assessment (NOA)"
    },
    "doc_noa_why": {
      "vi": "Bản mới nhất từ ATO; ngân hàng thường yêu cầu để xác nhận thu nhập, nhất là khi bạn tự kinh doanh.",
      "en": "Your latest from the ATO; lenders often require it to confirm income, especially if you are self-employed."
    },
    "doc_payslips_item": {
      "vi": "Phiếu lương gần đây",
      "en": "Recent payslips"
    },
    "doc_payslips_why": {
      "vi": "Thường là 2–3 kỳ lương gần nhất để chứng minh thu nhập ổn định.",
      "en": "Usually your last 2–3 payslips, to show stable income."
    },
    "doc_bank_statements_item": {
      "vi": "Sao kê ngân hàng",
      "en": "Bank statements"
    },
    "doc_bank_statements_why": {
      "vi": "3–6 tháng gần nhất, cho thấy thu nhập, chi tiêu và quá trình tiết kiệm của bạn.",
      "en": "The last 3–6 months, showing your income, spending and savings pattern."
    },
    "doc_deposit_evidence_item": {
      "vi": "Bằng chứng tiền cọc và tiền tiết kiệm tích lũy",
      "en": "Evidence of your deposit and genuine savings"
    },
    "doc_deposit_evidence_why": {
      "vi": "Sao kê cho thấy bạn đã tích lũy khoản tiết kiệm theo thời gian; nhiều ngân hàng xem đây là “genuine savings”.",
      "en": "Statements showing savings you have built up over time; many lenders treat this as “genuine savings”."
    },

    "person_broker_role": {
      "vi": "Chuyên viên môi giới vay (mortgage broker)",
      "en": "Mortgage broker"
    },
    "person_broker_when": {
      "vi": "Trước khi đi xem nhà — ở giai đoạn duyệt vay sơ bộ.",
      "en": "Before house-hunting — at the pre-approval stage."
    },
    "person_broker_why": {
      "vi": "Để so sánh các ngân hàng và giúp bạn hiểu các chương trình hỗ trợ người mua nhà lần đầu. Bạn là người quyết định chọn ngân hàng nào.",
      "en": "To compare lenders and help you understand the first-home-buyer schemes. You decide which lender to choose."
    },
    "person_conveyancer_role": {
      "vi": "Luật sư hoặc chuyên viên chuyển nhượng (conveyancer)",
      "en": "Conveyancer or solicitor"
    },
    "person_conveyancer_when": {
      "vi": "Trước khi ra giá hoặc ký hợp đồng.",
      "en": "Before you make an offer or sign a contract."
    },
    "person_conveyancer_why": {
      "vi": "Để rà soát hợp đồng và bản tiết lộ thông tin (Mục 32 / Contract of Sale), lo thủ tục pháp lý và việc bàn giao.",
      "en": "To review the contract and disclosure statement (Section 32 / Contract of Sale) and handle the legal work and settlement."
    },
    "person_buyers_agent_role": {
      "vi": "Chuyên viên đại diện người mua (buyer’s agent) — tùy chọn",
      "en": "Buyer’s agent (optional)"
    },
    "person_buyers_agent_when": {
      "vi": "Nếu bạn muốn được hỗ trợ tìm nhà và thương lượng giá.",
      "en": "If you want help searching for and negotiating a purchase."
    },
    "person_buyers_agent_why": {
      "vi": "Đại diện cho quyền lợi của bạn — khác với đại lý bán, vốn đại diện cho người bán.",
      "en": "Represents your interests — unlike the selling agent, who acts for the vendor."
    },

    "scheme_action_fhg": {
      "vi": "Giữ chỗ trong chương trình Bảo lãnh Người mua nhà lần đầu (First Home Guarantee) qua một ngân hàng tham gia chương trình.",
      "en": "Reserve a place in the First Home Guarantee through a participating lender."
    },
    "scheme_action_fhss": {
      "vi": "Yêu cầu ATO xác định và giải ngân khoản tiết kiệm FHSS trước khi bạn cần dùng tiền.",
      "en": "Request your FHSS determination and release from the ATO before you need the funds."
    },
    "scheme_action_help_to_buy": {
      "vi": "Nộp hồ sơ tham gia chương trình Help to Buy qua ngân hàng tham gia (số suất mỗi năm có hạn).",
      "en": "Apply for Help to Buy through a participating lender (annual places are limited)."
    },
    "scheme_action_state_concession": {
      "vi": "Chuẩn bị hồ sơ xin miễn/giảm thuế trước bạ của tiểu bang — thường nộp khi ký hợp đồng, qua chuyên viên chuyển nhượng.",
      "en": "Prepare your state stamp-duty concession or exemption — usually lodged at contract, through your conveyancer."
    },
    "scheme_action_default": {
      "vi": "Chuẩn bị các giấy tờ mà chương trình này yêu cầu trước khi bạn ký hợp đồng.",
      "en": "Prepare the documents this scheme requires before you sign a contract."
    },

    "buffer_note_general": {
      "vi": "Ngoài tiền cọc và các chi phí mua nhà, hãy giữ một khoản dự phòng cho những chi phí phát sinh sau khi dọn vào ở.",
      "en": "Beyond your deposit and buying costs, keep a buffer for unexpected expenses after you move in."
    },
    "buffer_note_meets": {
      "vi": "Quá trình tiết kiệm của bạn có vẻ đáp ứng yêu cầu “genuine savings” điển hình của ngân hàng.",
      "en": "Your savings record appears to meet lenders’ typical “genuine savings” requirement."
    },
    "buffer_note_fails_recent_gift": {
      "vi": "Một khoản tiền được tặng gần đây có thể không được tính là “genuine savings”; hãy hỏi ngân hàng hoặc chuyên viên môi giới.",
      "en": "A recent gift may not count as “genuine savings”; check with your lender or broker."
    },
    "buffer_note_insufficient_track_record": {
      "vi": "Bạn có thể cần thêm thời gian tích lũy để đạt yêu cầu về lịch sử tiết kiệm.",
      "en": "You may need a longer savings history to meet the requirement."
    },
    "buffer_note_unknown": {
      "vi": "Khả năng đáp ứng yêu cầu “genuine savings” sẽ rõ hơn khi bạn bổ sung thông tin thu nhập và tiền tiết kiệm.",
      "en": "Whether you meet the “genuine savings” requirement will become clearer once you add your income and savings."
    },

    "assumption_indicative": {
      "vi": "Đây là danh sách chuẩn bị tổng quát cho người mua nhà lần đầu tại Úc; yêu cầu cụ thể thay đổi theo ngân hàng, theo tiểu bang và theo hoàn cảnh của bạn.",
      "en": "This is a general readiness list for first-home buyers in Australia; the exact requirements vary by lender, by state and by your circumstances."
    },
    "assumption_informational": {
      "vi": "Đây là thông tin tham khảo, không phải tư vấn tài chính hay pháp lý. Hãy xác nhận với chuyên gia có giấy phép trước khi quyết định.",
      "en": "This is general information, not financial or legal advice. Confirm with a licensed professional before you decide."
    }
  }
}
```
