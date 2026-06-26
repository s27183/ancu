---
slug: kb.copy.buying-strategy
effective_from: 2026-06-01
last_verified: 2026-06-26
---

# buying_strategy component copy (bilingual)

User-facing copy-templates for the `buying_strategy` resolver half (`fh_engine_buying`): the
standard investor offer `conditions_to_request` (a fixed, non-property-specific list — finance,
building & pest, strata, rental appraisal) and the `max_bid_reasoning` frame that explains the
yield-anchored discipline line. Each template is a `{vi, en}` pair; the only placeholder is
`{yield}` (the investor's target gross yield %, passed raw by the resolver — `fh_engine_i18n:subst/2`
stringifies it). The money figures themselves are NOT in this doc — they ride in the outcome's
`money_range` fields, computed by the resolver and removed from the LLM's reach (§98).

This is a **copy doc**: it fills no slot and is not a blueprint anchor (reference-exempt; only
slug==path + content_json-parse + the bilingual copy gate apply, [[kb-doc-authoring]]). Vietnamese
is authored for register, not transliterated from the English (trap #4). Tone is **decision-support,
never advice** (ASIC / ACL): the yield anchor is a discipline guide, never an instruction to bid.

## Rules

Everything above is `content_md`. The `copy` block below is this doc's `content_json` — template
ids the resolver references, each a `{vi, en}` pair.

```jsonc
{
  "fills": [],
  "copy": {
    "cond_subject_to_finance": {
      "vi": "Phụ thuộc vào việc khoản vay được duyệt",
      "en": "Subject to finance approval"
    },
    "cond_subject_to_building_pest": {
      "vi": "Phụ thuộc vào kết quả kiểm tra công trình và mối mọt đạt yêu cầu",
      "en": "Subject to a satisfactory building & pest inspection"
    },
    "cond_subject_to_strata": {
      "vi": "Phụ thuộc vào báo cáo strata đạt yêu cầu (nếu là nhà chung cư)",
      "en": "Subject to a satisfactory strata report (where applicable)"
    },
    "cond_subject_to_rental_appraisal": {
      "vi": "Phụ thuộc vào thẩm định giá thuê đạt yêu cầu",
      "en": "Subject to a satisfactory rental appraisal"
    },
    "reasoning_yield_anchor": {
      "vi": "Khoảng giá này được neo theo tỷ suất lợi nhuận gộp mục tiêu {yield}% của bạn — vượt mức này, lợi nhuận cho thuê không còn đạt luận điểm đầu tư. Đây là hướng dẫn kỷ luật, không phải lệnh trả giá; hãy tự xác minh các con số.",
      "en": "This price band is anchored to your target gross yield of {yield}% — above it, the rental return no longer meets your investment thesis. A discipline guide, not a bid instruction; confirm the figures independently."
    }
  }
}
```
