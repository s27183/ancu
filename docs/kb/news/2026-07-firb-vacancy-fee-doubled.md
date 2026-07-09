---
slug: kb.news.2026-07-firb-vacancy-fee-doubled
kb_slug: kb.firb.vacancy-fee-double-from-2024
category: finance
affected_kb_slugs:
  - kb.firb.vacancy-fee-double-from-2024
effective_from: 2024-04-09
authored_date: 2026-07-09
sources:
  - url: https://foreigninvestment.gov.au/sites/foreigninvestment.gov.au/files/2024-08/gn-10-fees-fi-apps-aug-2024.pdf
    retrieved: 2026-07-06
    path: docs/sources/firb/gn10-fees-fi-apps-v5-aug-2024.pdf
---

## Headline (EN)

FIRB annual vacancy fee doubled for vacancy years from 9 Apr 2024

## Headline (VI)

Phí bỏ trống hàng năm của FIRB tăng gấp đôi từ năm bỏ trống 9/4/2024

## Summary (EN)

The FIRB annual vacancy fee — owed by a foreign owner whose dwelling isn't occupied or genuinely available for rent at least 183 days a year — **doubled** for any vacancy year starting on or after **9 April 2024**. The fee equals **2×** the original foreign-investment application fee (was 1×). The cutover keys off when the *vacancy year* starts, not the purchase date, so this reaches existing foreign-held dwellings on their next vacancy-year roll — not only new purchases. If your plan's vacancy-fee-at-risk figure predates this, it understates the current liability by half.

## Summary (VI)

Phí bỏ trống hàng năm của FIRB — áp dụng cho chủ sở hữu nước ngoài có nhà không được ở hoặc không thực sự cho thuê ít nhất 183 ngày mỗi năm — đã **tăng gấp đôi** đối với bất kỳ năm bỏ trống nào bắt đầu từ **9/4/2024** trở đi. Mức phí bằng **2 lần** phí đăng ký đầu tư nước ngoài ban đầu (trước đây là 1 lần). Thời điểm áp dụng tính theo ngày bắt đầu *năm bỏ trống*, không phải ngày mua, nên quy định này áp dụng cả với nhà đã sở hữu trước đó khi bước sang năm bỏ trống tiếp theo — không chỉ giao dịch mua mới. Nếu số liệu rủi ro phí bỏ trống trong kế hoạch của bạn được tính trước thay đổi này, con số đó đang thấp hơn một nửa so với mức phí thực tế hiện nay.

## Diff

```jsonc
{
  "old_value": { "vacancy_year_starts_before": "2024-04-09", "multiplier": 1 },
  "new_value": { "vacancy_year_starts_on_or_after": "2024-04-09", "multiplier": 2 }
}
```

Notes:

- **`sources:` reuses `kb.firb.vacancy-fee-double-from-2024`'s own citation, unchanged from its last verify (2026-07-06).**
- **Dormant for now.** No currently active blueprint anchors `kb.firb.vacancy-fee-double-from-2024` (it's a Mode B/D — foreign-buyer — doc; Wedge 1a is Mode A only). This is expected, not a gap: `affected_components` is computed over every blueprint at compile time, so the mapping is ready the instant B/D activate ([kb-news-feature.md "Component-target mapping"](../../architecture/kb-news-feature.md)).
- **Immutable once authored.**
