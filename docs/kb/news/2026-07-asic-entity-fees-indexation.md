---
slug: kb.news.2026-07-asic-entity-fees-indexation
kb_slug: kb.tax.entity-setup-costs
category: finance
affected_kb_slugs:
  - kb.tax.entity-setup-costs
effective_from: 2026-07-01
authored_date: 2026-07-09
sources:
  - url: https://asic.gov.au/for-business/payments-fees-and-invoices/asic-fees/fees-for-commonly-lodged-documents/
    retrieved: 2026-07-06
  - url: https://www.asic.gov.au/for-business-and-companies/forms-and-fees/all-fees/fee-indexation/
    retrieved: 2026-07-06
---

## Headline (EN)

ASIC company fees indexed for FY2026-27: registration $611→$636, review $67→$70

## Headline (VI)

Phí ASIC được điều chỉnh FY2026-27: đăng ký $611→$636, phí duyệt $67→$70

## Summary (EN)

ASIC's annual 1 July indexation lifted two statutory fees relevant to an investor holding property through a company or SMSF corporate trustee, effective **1 July 2026**: the one-off **company registration fee** rose from **$611 (FY2025-26) to $636 (FY2026-27)**, and the **special-purpose-company annual review fee** (the one an SMSF corporate trustee pays) rose from **$67 to $70**. These are the regulated portion of entity setup/ongoing cost — the surrounding accounting, deed, and audit charges remain indicative market bands, unchanged by this indexation. If your plan's cash-position or settlement-prep figures were sized against the FY2025-26 fees, the corporate-trustee/company setup line understates the current statutory cost by $25 upfront and $3/year ongoing — small in absolute terms, but the kind of drift that compounds across every indexation cycle if the underlying doc isn't re-verified each July.

## Summary (VI)

Đợt điều chỉnh chỉ số phí hàng năm của ASIC vào ngày 1/7 đã nâng hai khoản phí theo quy định liên quan đến nhà đầu tư sở hữu bất động sản qua công ty hoặc quỹ hưu trí tự quản (SMSF) có công ty được ủy thác, có hiệu lực từ **1/7/2026**: **phí đăng ký công ty** một lần tăng từ **611 AUD (FY2025-26) lên 636 AUD (FY2026-27)**, và **phí duyệt xét hàng năm cho công ty mục đích đặc biệt** (khoản mà công ty được ủy thác của SMSF phải nộp) tăng từ **67 AUD lên 70 AUD**. Đây là phần chi phí theo quy định trong tổng chi phí thành lập/duy trì thực thể — các khoản phí kế toán, soạn thảo văn kiện, và kiểm toán xung quanh vẫn là mức tham khảo thị trường, không thay đổi do đợt điều chỉnh này. Nếu kế hoạch của bạn tính dòng tiền hoặc chuẩn bị hoàn tất giao dịch dựa trên mức phí FY2025-26, dòng chi phí thành lập công ty/công ty được ủy thác đang thấp hơn thực tế 25 AUD ban đầu và 3 AUD/năm duy trì — chênh lệch nhỏ về số tuyệt đối, nhưng là kiểu sai lệch tích lũy qua mỗi chu kỳ điều chỉnh nếu tài liệu gốc không được xác minh lại mỗi tháng 7.

## Diff

```jsonc
{
  "old_value": { "fy": "2025-26", "asic_company_registration_fee": 611, "asic_special_purpose_company_review": 67 },
  "new_value": { "fy": "2026-27", "asic_company_registration_fee": 636, "asic_special_purpose_company_review": 70 }
}
```

Notes:

- **`sources:` reuses `kb.tax.entity-setup-costs`'s own citation, unchanged from its 2026-07-06 verify** — ASIC renders dollar values client-side, so the underlying doc corroborates the FY2026-27 figures via convergent independent professional fee schedules rather than a direct page read; this note doesn't repeat new corroboration, it just carries the citation forward.
- **The ATO SMSF supervisory levy ($259/yr) is unchanged since FY2014-15** and is not part of this diff — only the two ASIC-indexed fees moved.
- **Live now, Mode C.** Unlike most notes this session, this one is anchored on an in-scope-adjacent doc (`kb.tax.entity-setup-costs` is a Mode C — domestic investor — reference), so `affected_components` should resolve against `blueprints.investor-domestic-au` immediately, not dormant.
- **Immutable once authored.**
