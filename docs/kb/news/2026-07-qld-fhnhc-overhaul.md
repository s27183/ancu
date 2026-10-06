---
slug: kb.news.2026-07-qld-fhnhc-overhaul
kb_slug: kb.scheme.qld.fhnhc
category: scheme
affected_kb_slugs:
  - kb.scheme.qld.fhnhc
effective_from: 2025-05-01
authored_date: 2026-07-09
sources:
  - url: https://qro.qld.gov.au/duties/transfer-duty/concessions/homes/first-home-new-home/
    retrieved: 2026-07-06
---

## Headline (EN)

QLD First Home (New Home) Concession: nil duty, no cap, from 1 May 2025

## Headline (VI)

QLD: Ưu đãi Nhà Mới miễn thuế hoàn toàn, không giới hạn, từ 1/5/2025

## Summary (EN)

From **1 May 2025** Queensland's **First Home (New Home) Concession** was overhauled: an eligible new-home purchase now pays **nil transfer duty with no value cap at all** — replacing the older concession, which was capped and tapered out above a threshold. QRO illustrates the saving at around **$9,096** on a median-priced Queensland house-and-land package, but the real saving scales with price and is now uncapped. If your plan modelled a Queensland new-build purchase against the old capped concession, the duty saving is now larger, and the value cap that used to limit it no longer applies. The buyer's worldwide prior-ownership test still applies, and the change only covers contracts dated 1 May 2025 or later.

## Summary (VI)

Từ ngày **1/5/2025**, **Ưu đãi Nhà Mới (First Home New Home Concession)** của Queensland đã được cải tổ toàn diện: một giao dịch mua nhà mới đủ điều kiện nay **hoàn toàn không phải trả thuế chuyển nhượng, không giới hạn giá trị** — thay thế cho ưu đãi cũ vốn có giới hạn và giảm dần khi vượt một ngưỡng nhất định. QRO minh họa mức tiết kiệm khoảng **$9.096** trên một gói đất-và-nhà giá trung bình ở Queensland, nhưng mức tiết kiệm thực tế tăng theo giá trị và nay không còn giới hạn trần. Nếu kế hoạch của bạn từng tính ưu đãi này cho việc mua nhà mới ở Queensland theo mức giới hạn cũ, khoản tiết kiệm thuế nay lớn hơn và mức trần giá trị trước đây không còn áp dụng. Điều kiện xét lịch sử sở hữu nhà của người mua vẫn áp dụng trên toàn thế giới, và thay đổi này chỉ áp dụng cho hợp đồng ký từ ngày 1/5/2025 trở đi.

## Diff

```jsonc
{
  "old_value": { "concession_type": "capped, tapered out above a threshold", "value_cap": "capped (pre-1-May-2025 QRO schedule)" },
  "new_value": { "concession_type": "full_exemption", "value_cap": null, "illustrative_saving_median_house_and_land": 9096, "effective": "contracts dated 1 May 2025 or later" }
}
```

Notes:

- **`sources:` reuses `kb.scheme.qld.fhnhc`'s own citation, unchanged from its last verify (2026-07-06).**
- The underlying doc states the overhaul qualitatively ("replaced the older capped concession") without restating the exact pre-1-May-2025 cap figure — `old_value` above records that framing, not an invented number.
- **Immutable once authored.**
