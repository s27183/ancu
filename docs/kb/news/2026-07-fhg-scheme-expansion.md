---
slug: kb.news.2026-07-fhg-scheme-expansion
kb_slug: kb.scheme.fhg
category: scheme
affected_kb_slugs:
  - kb.scheme.fhg
effective_from: 2025-10-01
authored_date: 2026-07-09
sources:
  - url: https://www.housingaustralia.gov.au/media/unlimited-places-higher-property-price-caps-first-home-buyers-1-october-2025
    retrieved: 2026-07-06
  - url: https://www.housingaustralia.gov.au/support-buy-home/first-home-guarantee
    retrieved: 2026-07-06
---

## Headline (EN)

First Home Guarantee: place caps and income caps removed from 1 Oct 2025

## Headline (VI)

Bảo lãnh Ngôi nhà Đầu tiên: bỏ giới hạn suất và thu nhập từ 1/10/2025

## Summary (EN)

From 1 October 2025 the First Home Guarantee was materially expanded: **unlimited places** (the old annual cap is gone), **no income caps**, and **higher property price caps** by location. The former Regional First Home Buyer Guarantee was folded into this single scheme. If you were assessed against the pre-October-2025 scheme — a place-limited, income-tested version with lower price caps — re-check eligibility and the cap for your target suburb; you may now qualify or have more room than previously shown.

## Summary (VI)

Từ ngày 1/10/2025, chương trình Bảo lãnh Ngôi nhà Đầu tiên đã được mở rộng đáng kể: **không giới hạn số suất** (bỏ mức trần hàng năm trước đây), **không giới hạn thu nhập**, và **nâng mức trần giá bất động sản** theo từng khu vực. Chương trình Bảo lãnh Người mua nhà lần đầu vùng nông thôn trước đây đã được gộp vào chương trình này. Nếu bạn từng được đánh giá theo phiên bản trước tháng 10/2025 — có giới hạn suất, xét thu nhập và mức trần giá thấp hơn — hãy kiểm tra lại điều kiện và mức trần cho khu vực bạn nhắm đến; bạn có thể hiện đủ điều kiện hoặc có dư địa nhiều hơn so với trước.

## Diff

```jsonc
{
  "old_value": { "places_capped": true, "income_capped": true, "regional_scheme_separate": true, "example_cap_note": "lower price caps, place-limited annual allocation" },
  "new_value": { "places_capped": false, "income_capped": false, "regional_scheme_separate": false, "caps_by_state": { "NSW": [1500000, 800000], "VIC": [950000, 650000], "QLD": [1000000, 700000], "WA": [850000, 600000], "SA": [900000, 500000], "TAS": [700000, 550000], "ACT": [1000000, null], "NT": [750000, 600000] } }
}
```

Notes:

- **`sources:` reuses `kb.scheme.fhg`'s own citation, unchanged from its last verify (2026-07-06)** — this note pins what was actually checked for the fact doc, not a fresh fetch performed today; the fact doc itself is the citation of record.
- **`affected_kb_slugs` is just `kb.scheme.fhg`** — the scheme's own doc already carries the full current cap table; this note is the ticker-facing announcement of the October 2025 step-change, not a duplicate of the figures.
- **Immutable once authored.**
