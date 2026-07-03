---
slug: kb.copy.mortgage
effective_from: 2026-06-01
last_verified: 2026-06-01
---

# Mortgage component copy (bilingual)

User-facing copy-templates for the `mortgage_finance` resolver half (`fh_engine_mortgage`):
the `key_assumptions` and `pre_approval_action_plan` narration for both the Mode-A FHB
path (`fill_fhb/2`) and the Mode-B foreign-person path (`fill_fhb_foreign/2`). Each
template is a `{vi, en}` pair with `{param}` placeholders the resolver fills via
`fh_engine_i18n:subst/2`; the numeric params (the APRA buffer, the genuine-savings
convention, the foreign-deposit convention) come from
[`kb.lender.serviceability-basics`](../lender/serviceability-basics.md) /
[`kb.lender.foreign-buyer-deposit-requirements`](../lender/foreign-buyer-deposit-requirements.md)
— facts stay in the fact doc, presentation copy lives here (bilingual-content.md §3b).

This is a **copy doc**: it fills no slot and is not a blueprint anchor (reference-exempt;
only slug==path + content_json-parse gates apply). Vietnamese is authored for register —
not a transliteration of the English (trap #4). Decision-support tone, never advice (ASIC).

## Rules

Everything above is `content_md`. The `copy` block below is this doc's `content_json` —
template ids the resolver references, each a `{vi, en}` pair. `{param}` tokens are filled
by the resolver; a scalar fills both languages identically, a money/label value per its
kind (bilingual-content.md §3b).

```jsonc
{
  "fills": [],
  "copy": {
    "action_genuine_savings": {
      "vi": "Chuẩn bị bằng chứng tiết kiệm thực sự: giữ khoảng {pct}% giá trị căn nhà trong {months}+ tháng (tiết kiệm đều đặn, không phải một khoản tiền lớn đột ngột).",
      "en": "Build genuine-savings evidence: about {pct}% of the purchase price held for {months}+ months (regular savings, not a sudden lump sum)."
    },
    "action_income_evidence": {
      "vi": "Thu thập bằng chứng thu nhập (phiếu lương gần đây; tờ khai thuế nếu bạn tự kinh doanh).",
      "en": "Gather income evidence (recent payslips; tax returns if self-employed)."
    },
    "action_list_debts": {
      "vi": "Liệt kê các khoản nợ hiện tại kèm hạn mức (HECS, thẻ tín dụng, mua trước trả sau, vay cá nhân/mua xe) — hạn mức, chứ không phải số dư, mới quyết định khả năng trả nợ.",
      "en": "List current debts with their limits (HECS, credit cards, BNPL, personal/car loans) — limits, not balances, drive serviceability."
    },
    "action_compare_panel": {
      "vi": "So sánh các ngân hàng trong nhóm First Home Guarantee, hoặc nhờ một chuyên viên vay vốn có liên kết với nhiều ngân hàng trong nhóm.",
      "en": "Compare lenders across the First Home Guarantee panel, or engage a broker who covers many panel lenders."
    },
    "assume_buffer": {
      "vi": "Khả năng vay được đánh giá ở mức lãi suất sản phẩm của bạn cộng thêm {buffer_pp} điểm phần trăm (biên đệm khả năng trả nợ của APRA — một hằng số theo quy định).",
      "en": "Borrowing capacity is assessed at your product rate + {buffer_pp} percentage points (the APRA serviceability buffer — a regulated constant)."
    },
    "assume_conventions": {
      "vi": "Việc chiết giảm thu nhập (~80% tiền tăng ca/thưởng/cho thuê), quy tắc tiết kiệm thực sự, và trần tỷ lệ nợ trên thu nhập cao (khoảng 6 lần thu nhập) là các thông lệ chung của ngân hàng, không phải chính sách của ngân hàng cụ thể của bạn — một chuyên viên vay vốn sẽ xác nhận chi tiết.",
      "en": "Income shading (~80% of overtime/bonus/rental), the genuine-savings rule, and the high-DTI ceiling (about 6× income) are lender conventions, not your actual lender's policy — a broker confirms the specifics."
    },
    "assume_pending": {
      "vi": "Các con số về khả năng vay và tối ưu hóa nợ của bạn đang chờ — chúng sẽ được tính khi bạn nhập thu nhập và các khoản nợ.",
      "en": "Your borrowing capacity and debt-optimisation figures are pending — they compute once your income and debts are entered."
    },
    "assume_fhg": {
      "vi": "Chương trình First Home Guarantee cho phép bạn vay với khoản đặt cọc 5% và không phải mua bảo hiểm LMI; không có khoản lãi suất cộng thêm khi sử dụng chương trình này.",
      "en": "The First Home Guarantee lets you borrow with a 5% deposit and no LMI; there is no rate premium for using the guarantee."
    },
    "action_gather_visa_and_documents": {
      "vi": "Chuẩn bị hồ sơ thị thực, hộ chiếu và giấy tờ tùy thân (cho cả người mua tại Úc và người tài trợ ở Việt Nam nếu có) — hồ sơ dành cho người không thường trú thường cần nhiều giấy tờ hơn.",
      "en": "Gather visa grant evidence, passport, and identity documents (for the AU-side buyer and the Vietnam-side funder if applicable) — the non-resident document pack typically asks for more than a domestic application."
    },
    "action_start_firb_in_parallel": {
      "vi": "Bắt đầu nộp đơn FIRB song song với việc xin phê duyệt vay trước — hai quy trình chạy đồng thời, không cần chờ cái này xong mới làm cái kia.",
      "en": "Start the FIRB application alongside loan pre-approval — the two run in parallel, not one after the other."
    },
    "action_source_of_funds_evidence": {
      "vi": "Nếu một phần tiền đến từ Việt Nam, chuẩn bị sớm bằng chứng nguồn tiền (có thể cần bản dịch công chứng) — đây là yêu cầu của cả ngân hàng và quy định phòng chống rửa tiền.",
      "en": "If any of the funds come from Vietnam, prepare source-of-funds evidence early (a certified translation may be needed) — both a lender requirement and an AML/CTF obligation."
    },
    "action_compare_non_resident_lenders": {
      "vi": "So sánh nhóm nhỏ các ngân hàng chấp nhận cho người không thường trú vay (thường khoảng 5–10 ngân hàng), tốt nhất là qua một chuyên viên vay vốn có kinh nghiệm với hồ sơ nước ngoài.",
      "en": "Compare the small pool of non-resident-friendly lenders (typically 5–10), ideally through a broker experienced with foreign-person applications."
    },
    "action_understand_deposit_convention": {
      "vi": "Hiểu rằng khoản đặt cọc {pct}% là thông lệ phổ biến dành cho người mua nước ngoài (không phải chính sách của một ngân hàng cụ thể) — con số này có thể giảm khi biết rõ thị thực và thu nhập của bạn.",
      "en": "Understand that the {pct}% deposit is the typical non-resident convention (not a specific lender's policy) — it may reduce once your visa and income situation is known."
    }
  }
}
```
