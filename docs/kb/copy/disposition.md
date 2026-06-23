---
slug: kb.copy.disposition
effective_from: 2026-06-22
last_verified: 2026-06-22
---

# Disposition component copy (bilingual)

User-facing copy-templates for the `disposition` resolver (`fh_engine_disposition`): the
dispose-phase `dispose_cash_events` labels (sale proceeds, selling costs, loan payout, CGT)
and the `key_assumptions` lines (the hold horizon, the **placeholder** capital-growth band,
the CGT exemption basis, the selling-cost basis, the representative loan-rate basis). Each template is filled via
`fh_engine_i18n:subst/2` — no Vietnamese literal in Erlang (the `io:format ~s` >255-codepoint
trap; bilingual-content.md §3b).

Params are all **scalars** (same in both languages, §3b/§4): `{years}` the hold horizon `H`,
`{low}` / `{high}` the capital-growth band percentages. The money figures themselves are
structured `amount` / `money_range` fields, never interpolated into copy.

This is a **copy doc**: it fills no slot and is not a blueprint anchor (reference-exempt; only
slug==path + content_json-parse + copy-template gates apply). The dispose figures are
resolver-computed and removed from the LLM's reach (lifecycle-simulation-model §8.4); this doc
supplies only the bilingual labels and assumption prose. ASIC: every assumption line states a
basis — decision-support, never a forecast or advice.

## Rules

```jsonc
{
  "fills": [],
  "copy": {
    "event_sale_proceeds": {
      "vi": "Tiền bán nhà (dự phóng)",
      "en": "Sale proceeds (projected)"
    },
    "event_selling_costs": {
      "vi": "Chi phí bán (môi giới, pháp lý, quảng cáo)",
      "en": "Selling costs (agent, legal, marketing)"
    },
    "event_loan_payout": {
      "vi": "Tất toán khoản vay khi bán",
      "en": "Loan payout at sale"
    },
    "event_cgt": {
      "vi": "Thuế lãi vốn (CGT)",
      "en": "Capital gains tax (CGT)"
    },
    "assumption_set_horizon": {
      "vi": "Hãy đặt số năm bạn dự định nắm giữ để xem dự phóng khi bán.",
      "en": "Set how many years you plan to hold to project your sell-side outcome."
    },
    "assumption_horizon": {
      "vi": "Giả định nắm giữ {years} năm trước khi bán.",
      "en": "Assumes holding for {years} years before selling."
    },
    "assumption_growth_placeholder": {
      "vi": "Mức tăng giá {low}–{high}%/năm là GIẢ ĐỊNH TẠM, chưa lấy từ nguồn chính thức — chỉ để tham khảo, không phải dự báo.",
      "en": "The {low}–{high}% per-year capital-growth band is a PLACEHOLDER, not yet drawn from an authoritative series — a planning aid, not a forecast."
    },
    "assumption_cgt_exempt": {
      "vi": "Nhà ở chính mà bạn sinh sống thường được miễn thuế lãi vốn — hãy xác nhận với chuyên viên thuế.",
      "en": "A main residence you live in is generally exempt from capital gains tax — confirm with a registered tax agent."
    },
    "assumption_cgt_to_verify": {
      "vi": "Việc miễn thuế lãi vốn cần được kiểm tra (cho thuê một phần, không cư trú thuế, hoặc đất trên 2 ha).",
      "en": "The capital gains tax exemption needs checking (part rental, non-resident for tax, or land over 2 ha)."
    },
    "assumption_selling_costs": {
      "vi": "Chi phí bán là ước tính theo dải; hoa hồng môi giới có thể thương lượng.",
      "en": "Selling costs are banded estimates; agent commission is negotiable."
    },
    "assumption_loan_rate": {
      "vi": "Khoản tất toán vay được tính theo lãi suất tham chiếu {rate}%/năm trong {term} năm — GIẢ ĐỊNH quy ước, không phải lãi suất sản phẩm thực tế của bạn.",
      "en": "Loan payout assumes the loan amortises at a representative {rate}%/year over {term} years — a CONVENTION, not your actual product rate."
    }
  }
}
```

Notes:

- **No `fills`.** No outcome leaf is set by a KB rule. The dispose figures are resolver-computed
  from `kb.property.capital-growth-bands` + `kb.selling-costs.agent-legal` + the upstream figures;
  this doc supplies only labels and assumption prose.
- **The growth-band caveat is load-bearing.** `assumption_growth_placeholder` carries the
  PLACEHOLDER warning into the user-facing plan — the band must be re-grounded against a named
  series before any figure is surfaced as more than a banded planning aid (Son, 2026-06-21).
