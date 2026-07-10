---
slug: kb.copy.disposition
effective_from: 2026-06-22
last_verified: 2026-07-10
---

# Disposition component copy (bilingual)

User-facing copy-templates for the `disposition` resolver (`fh_engine_disposition`): the
dispose-phase `dispose_cash_events` labels (sale proceeds, selling costs, loan payout, CGT)
and the `key_assumptions` lines (the hold horizon, the **placeholder** capital-growth band,
the CGT basis — owner-occupier exemption *or* the Mode-C/D investor computed/to_verify lines plus
the 2026-27 reform flag — the selling-cost basis, the representative loan-rate basis, and
(Mode D only) the FRCGW prepayment note `assumption_frcgw`). `vn_side_cgt_note` is Mode-D's
informational VN-side pointer (never a VN tax figure — points to the buyer's own VN-based tax
advisor, per the AU-side-full/VN-side-placeholder scoping decision). Each template is filled via
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
    },
    "assumption_cgt_computed": {
      "vi": "Thuế lãi vốn được ước tính từ phần lãi dự phóng (giảm 50% nếu nắm giữ trên 12 tháng) theo thuế suất biên của bạn — chỉ là ước tính, không phải tư vấn; hãy xác nhận với chuyên viên thuế.",
      "en": "Capital gains tax is estimated from the projected gain (50% discount if held over 12 months) at your marginal rate — an estimate, not advice; confirm with a registered tax agent."
    },
    "assumption_cgt_investor_to_verify": {
      "vi": "Thuế lãi vốn ở đây cần chuyên viên thuế xác định — phụ thuộc vào khấu hao đã khấu trừ (làm tăng phần lãi), loại hình sở hữu, và tình trạng cư trú thuế của bạn, nên chúng tôi không ước tính con số.",
      "en": "Capital gains tax here needs a registered tax agent — it depends on depreciation claimed (which raises the gain), the ownership entity, and your tax residency, so we don't estimate the figure."
    },
    "assumption_cgt_reform": {
      "vi": "Phần này áp dụng luật hiện hành (giảm 50% thuế lãi vốn). Một cải cách trong Ngân sách 2026-27 — thay bằng cách điều chỉnh theo lạm phát trên giá vốn cộng thuế tối thiểu 30% — nay đã thành luật (có hiệu lực từ 26/6/2026) nhưng chưa áp dụng cho đến 1/7/2027; hãy xác nhận với chuyên viên thuế có đăng ký.",
      "en": "This uses current law (the 50% CGT discount). A 2026-27 Budget reform replacing it with cost-base indexation plus a 30% minimum tax is now law (enacted 26 June 2026) but does not take effect until 1 July 2027; confirm the position with a registered tax agent."
    },
    "assumption_frcgw": {
      "vi": "Khi bán, người mua sẽ giữ lại 15% giá bán để nộp cho Sở Thuế Úc (ATO) — đây là khoản TẠM ỨNG được khấu trừ vào thuế lãi vốn thực tế của bạn khi quyết toán, không phải là một khoản phí thêm.",
      "en": "At sale, the purchaser withholds 15% of the sale price and remits it to the ATO — a PREPAYMENT credited against your actual capital gains tax on assessment, not an additional cost."
    },
    "vn_side_cgt_note": {
      "vi": "Khoản lãi từ việc bán bất động sản tại Úc có thể phải chịu thuế tại Việt Nam theo quy định thuế Việt Nam — nội dung cụ thể (bao gồm khả năng khấu trừ thuế đã nộp tại Úc theo hiệp định thuế Việt Nam - Úc) chưa được xây dựng đầy đủ; hãy tham khảo chuyên viên thuế tại Việt Nam của bạn.",
      "en": "The gain on selling AU property may also be taxable in Vietnam under VN tax law — the specifics (including a possible credit for AU tax paid, under the AU-VN tax treaty) are not yet fully built out here; consult your own VN-based tax advisor."
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
