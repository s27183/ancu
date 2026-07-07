---
slug: kb.news.2026-07-hecs-thresholds-2026-27
kb_slug: kb.hecs.thresholds
affected_kb_slugs:
  - kb.hecs.thresholds
effective_from: 2026-07-01
authored_date: 2026-07-06
sources:
  - url: https://www.ato.gov.au/tax-rates-and-codes/study-and-training-support-loans-rates-and-repayment-thresholds
    note: "PRIMARY (ATO) — same corroboration caveat as kb.hecs.thresholds's own citation: 403 Forbidden to WebFetch in-sandbox 2026-07-06; figures corroborated to the digit against the two secondary sources below."
  - url: https://www.scalesuite.com.au/resources/understanding-stsl-tax-a-comprehensive-guide
    retrieved: 2026-07-06
  - url: https://www.wagecalculator.com.au/guides/hecs-help-repayment
    retrieved: 2026-07-06
---

## Summary (EN)

The compulsory HECS-HELP repayment threshold rose from **$67,000** (2025-26) to
**$69,528** (2026-27), with an updated marginal-band schedule. If your
borrowing-capacity figures were calculated against last year's threshold, your
HECS repayment commitment — and therefore your capacity — may now be slightly
higher than shown.

## Summary (VI)

Ngưỡng hoàn trả HECS-HELP bắt buộc đã tăng từ **67.000 đô la** (năm 2025-26)
lên **69.528 đô la** (năm 2026-27), cùng với bảng bậc thuế biên mới. Nếu năng
lực vay của bạn được tính theo ngưỡng năm ngoái, khoản hoàn trả HECS — và do đó
năng lực vay — có thể hiện đã cao hơn một chút so với con số đang hiển thị.

## Diff

```jsonc
{
  "old_value": { "fy": "2025-26", "minimum_repayment_threshold": 67000 },
  "new_value": {
    "fy": "2026-27",
    "minimum_repayment_threshold": 69528,
    "bands": [
      { "band": "nil",      "income_to": 69528,  "marginal_rate_pct": 0 },
      { "band": "lower",    "income_to": 129717, "marginal_rate_pct": 15 },
      { "band": "upper",    "income_to": 186050, "marginal_rate_pct": 17, "base_amount": 9028 },
      { "band": "top_flat", "income_to": null,   "flat_rate_of_total_pct": 10 }
    ]
  }
}
```

Notes:

- **`sources:` pins this specific diff, not a live citation.** It's the same
  primary + corroborating URLs as `kb_slug` (`kb.hecs.thresholds`)'s own
  `sources:` at the moment this note was authored — copied at zero extra
  gathering cost since the author already had them open for Phase 1. This does
  NOT drift when the fact doc is next re-verified: the note is immutable, so
  it stays a correct historical record of what was checked for *this* change,
  never a live pointer that needs to track the doc's current state.
- **`affected_kb_slugs` is the relevance-filter key.** The engine intersects
  this list against a plan card's per-fill `kb_versions` provenance
  (`plan-card-refresh.md`) — already-recorded data, no new lookup mechanism —
  to decide which cards see this note.
- **Immutable once authored.** Unlike a fact doc (`last_verified`, re-checked
  on a budget), a news note is a dated announcement — if the fact changes
  again later, a new note is authored, this one is not edited.
