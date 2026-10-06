---
slug: kb.news.2026-07-qld-fhc-expansion
kb_slug: kb.scheme.qld.fhc
category: scheme
affected_kb_slugs:
  - kb.scheme.qld.fhc
effective_from: 2024-06-09
authored_date: 2026-07-09
sources:
  - url: https://qro.qld.gov.au/duties/transfer-duty/concessions/homes/first-home/
    retrieved: 2026-07-06
  - url: https://qro.qld.gov.au/duties/transfer-duty/calculate/concession-rates/
    retrieved: 2026-07-06
---

## Headline (EN)

QLD First Home Concession expanded: nil duty to $700k, from 9 Jun 2024

## Headline (VI)

QLD: Ưu đãi Ngôi nhà Đầu tiên mở rộng — miễn thuế đến $700k, từ 9/6/2024

## Summary (EN)

From **9 June 2024** Queensland's **First Home Concession** (for an established home) was expanded: a first home valued at **$700,000 or under** now pays **no transfer duty at all**. Between $700,000 and $800,000 the concession **tapers**; above $800,000 it doesn't apply. The maximum first-home saving is **$24,525**. This is a materially bigger benefit than the pre-9-June-2024 version, so any pre-existing plan modelling this concession for an established-home purchase in Queensland should be re-checked against the new $700k/$800k thresholds. The buyer's own prior-ownership test still applies worldwide (a prior home in Vietnam disqualifies), and the concession only applies to contracts dated 9 June 2024 or later.

## Summary (VI)

Từ ngày **9/6/2024**, **Ưu đãi Ngôi nhà Đầu tiên (First Home Concession)** của Queensland (áp dụng cho nhà đã qua sử dụng) đã được mở rộng: một ngôi nhà đầu tiên có giá trị **từ $700.000 trở xuống** nay **hoàn toàn không phải trả thuế chuyển nhượng**. Từ $700.000 đến $800.000, mức ưu đãi **giảm dần**; trên $800.000 không còn áp dụng. Mức tiết kiệm tối đa cho người mua nhà lần đầu là **$24.525**. Đây là một lợi ích lớn hơn đáng kể so với phiên bản trước ngày 9/6/2024, vì vậy bất kỳ kế hoạch nào đã tính ưu đãi này cho việc mua nhà đã qua sử dụng ở Queensland trước đó cần được kiểm tra lại theo ngưỡng $700k/$800k mới. Điều kiện xét lịch sử sở hữu nhà của người mua vẫn áp dụng trên toàn thế giới (từng sở hữu nhà ở Việt Nam sẽ không đủ điều kiện), và ưu đãi chỉ áp dụng cho hợp đồng ký từ ngày 9/6/2024 trở đi.

## Diff

```jsonc
{
  "old_value": { "nil_duty_threshold": "lower than $700,000", "concession_scope": "narrower band, lower max saving (pre-9-Jun-2024 QRO schedule)" },
  "new_value": { "nil_duty_threshold": 700000, "taper_ceiling": 800000, "max_first_home_saving": 24525, "effective": "contracts dated 9 Jun 2024 or later" }
}
```

Notes:

- **`sources:` reuses `kb.scheme.qld.fhc`'s own citation, unchanged from its last verify (2026-07-06).**
- The underlying doc frames this as an explicit expansion ("From 9 June 2024 the concession was expanded") but does not restate the exact pre-9-Jun-2024 threshold figures — `old_value` above records the doc's own qualitative framing ("narrower, lower max saving"), not invented numbers.
- **Immutable once authored.**
