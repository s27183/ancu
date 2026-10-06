---
slug: kb.news.2026-07-frcgw-rate-increase
kb_slug: kb.non-resident-tax.foreign-resident-cgt-withholding
category: finance
affected_kb_slugs:
  - kb.non-resident-tax.foreign-resident-cgt-withholding
effective_from: 2025-01-01
authored_date: 2026-07-09
sources:
  - url: https://www.ato.gov.au/individuals-and-families/investments-and-assets/capital-gains-tax/foreign-residents-and-capital-gains-tax/foreign-resident-capital-gains-withholding/foreign-resident-capital-gains-withholding-overview
    retrieved: 2026-07-06
    note: "PRIMARY (ATO). Verified via WebSearch corroboration 2026-07-06 (ATO direct WebFetch returns 403 in-sandbox); 15% rate + removal of the A$750,000 threshold for contracts entered on/after 1 January 2025 confirmed UNCHANGED (was 12.5% / $750k floor to 31 Dec 2024)."
---

## Headline (EN)

Foreign-resident CGT withholding raised to 15%, $750k threshold removed

## Headline (VI)

Thuế khấu lưu CGT với người không cư trú tăng lên 15%, bỏ ngưỡng $750k

## Summary (EN)

For contracts entered on or after **1 January 2025**, the Foreign Resident Capital Gains Withholding (FRCGW) rate rose from **12.5% to 15%** of the sale price, and the earlier **A$750,000 property-value threshold was removed** — FRCGW now applies to **every** disposal of Australian taxable real property by a foreign resident, not just those above a value floor. The purchaser still withholds the amount at settlement and remits it to the ATO; it remains a **prepayment credited against the vendor's actual CGT liability** on assessment, not a separate tax, and a variation notice can still reduce the amount withheld where the real gain is smaller. This matters for the sale-day cash flow of any Mode B foreign-resident vendor — and, symmetrically, for a Mode B buyer purchasing from a foreign-resident vendor, who is themselves the withholder. If your plan's disposition or purchase modelling used the pre-2025 12.5%/$750k figures, it understated the withholding by 2.5 percentage points and missed properties below the old threshold entirely.

## Summary (VI)

Đối với hợp đồng ký kết từ **1/1/2025** trở đi, mức thuế khấu lưu thuế lãi vốn đối với người không cư trú (FRCGW) tăng từ **12,5% lên 15%** giá bán, và **ngưỡng giá trị bất động sản 750.000 AUD** trước đây đã bị **bãi bỏ** — FRCGW nay áp dụng cho **mọi** giao dịch chuyển nhượng bất động sản chịu thuế tại Úc của người không cư trú, không chỉ những giao dịch trên một mức giá trị nhất định. Người mua vẫn khấu lưu khoản này tại thời điểm hoàn tất giao dịch và nộp cho Sở Thuế (ATO); đây vẫn là **khoản tạm nộp được khấu trừ vào nghĩa vụ thuế lãi vốn thực tế** của người bán khi quyết toán, không phải một loại thuế riêng, và người bán vẫn có thể xin thông báo điều chỉnh để giảm mức khấu lưu nếu lãi thực tế thấp hơn. Điều này ảnh hưởng đến dòng tiền ngày bán của người bán không cư trú thuộc Mode B — và tương tự, đối với người mua thuộc Mode B mua từ người bán không cư trú, chính họ là người phải khấu lưu. Nếu kế hoạch của bạn từng tính toán dựa trên mức 12,5%/ngưỡng 750.000 AUD trước 2025, số liệu đó đã thấp hơn thực tế 2,5 điểm phần trăm và bỏ sót các bất động sản dưới ngưỡng cũ.

## Diff

```jsonc
{
  "old_value": { "rate_pct": 12.5, "threshold_aud": 750000, "applies_to": "disposals at or above the threshold" },
  "new_value": { "rate_pct": 15, "threshold_aud": null, "applies_to": "all disposals of Australian taxable real property by a foreign resident, regardless of value" }
}
```

Notes:

- **`sources:` reuses `kb.non-resident-tax.foreign-resident-cgt-withholding`'s own citation, unchanged from its 2026-07-06 verify** (ATO primary; direct fetch 403s in-sandbox, corroborated via WebSearch).
- **Dormant for now.** No currently active blueprint anchors this Mode-B doc (Wedge 1a is Mode A only) — expected, not a gap; `affected_components` is computed over every blueprint, so the mapping is ready the instant Mode B activates.
- **Immutable once authored.**
