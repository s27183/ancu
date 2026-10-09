---
slug: kb.news.2026-07-income-tax-15pct-bracket
kb_slug: kb.tax.income-tax-resident-2026-27
category: tax
affected_kb_slugs:
  - kb.tax.income-tax-resident-2026-27
effective_from: 2026-07-01
authored_date: 2026-07-09
sources:
  - url: https://www.ato.gov.au/tax-rates-and-codes/tax-rates-australian-residents
    retrieved: 2026-10-09
    note: "PRIMARY (ATO) — 403 to WebFetch in-sandbox 2026-07-09; read 2026-10-09 (curl, browser user agent): carries the 2026-27 bases 4,020 / 31,020 / 51,370 at 15c, and the 2025-26 bases 4,288 / 31,288 / 51,638 at 16c — every figure of the diff."
---

## Headline (EN)

Income tax second bracket cut from 16% to 15% for 2026-27

## Headline (VI)

Bậc thuế thu nhập thứ hai giảm từ 16% xuống 15% cho năm 2026-27

## Summary (EN)

From 1 July 2026, the resident income-tax rate on income between **$18,201 and $45,000** dropped from **16% to 15%**. Every other bracket boundary and rate is unchanged. If your borrowing-capacity figures were calculated against last year's 2025-26 schedule, your net income — and therefore your capacity — is now **up to $268/year higher** than shown.

## Summary (VI)

Từ ngày 1/7/2026, mức thuế thu nhập cư trú áp dụng cho thu nhập từ **18.201 đến 45.000 đô la** đã giảm từ **16% xuống 15%**. Mọi bậc thuế khác không đổi. Nếu năng lực vay của bạn được tính theo bảng thuế năm 2025-26 trước đó, thu nhập ròng — và do đó năng lực vay — hiện có thể cao hơn tới **268 đô la/năm** so với con số đang hiển thị.

## Diff

```jsonc
{
  "old_value": { "fy": "2025-26", "second_bracket_rate_pct": 16, "second_band_base": 4288, "third_band_base": 31288, "top_band_base": 51638 },
  "new_value": { "fy": "2026-27", "second_bracket_rate_pct": 15, "second_band_base": 4020, "third_band_base": 31020, "top_band_base": 51370 }
}
```

Notes:

- **`sources:` pins this specific diff, not a live citation** — same discipline as the HECS note (`kb.news.2026-07-hecs-thresholds-2026-27`). Re-cited 2026-10-09 to the ATO page alone (behavior 39: news cites government pages only); the commercial corroborations are dropped, and the "Stage 3+" framing, which the ATO page does not carry, is cut. The figures are unchanged.
- **`affected_kb_slugs` names the 2026-27 doc, not its 2025-26 predecessor** — the predecessor is an immutable dated snapshot correctly consulted only by plan cards filled before 1 July 2026; this note is only relevant to cards that read the current schedule.
- **Immutable once authored.** A later bracket change (2027-28: 15%→14%) gets a new note, this one is never edited.
