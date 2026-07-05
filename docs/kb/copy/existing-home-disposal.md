---
slug: kb.copy.existing-home-disposal
effective_from: 2026-07-05
last_verified: 2026-07-05
---

# Existing-home-disposal component copy (bilingual)

User-facing copy-templates for the `existing_home_disposal` resolver (`fh_engine_existing_home_disposal`,
Mode E). Covers the pieces genuinely new to this component — the loan-payout basis (discharge fee,
break-cost caveat) and the no-facts-yet honest-partial note. The CGT and selling-cost assumption lines
are **reused from `kb.copy.disposition`** (`assumption_cgt_exempt`, `assumption_cgt_to_verify`,
`assumption_selling_costs`) — the same regulated figures, same bilingual prose, one copy doc, not
duplicated here. Each template is filled via `fh_engine_i18n:subst/2` — no Vietnamese literal in
Erlang (bilingual-content.md §3b).

This is a **copy doc**: it fills no slot and is not a blueprint anchor (reference-exempt).

## Rules

```jsonc
{
  "fills": [],
  "copy": {
    "assumption_no_existing_home_facts": {
      "vi": "Hãy cho biết giá trị ước tính và số dư khoản vay của nhà hiện tại để xem tiền bán ròng.",
      "en": "Provide your current home's estimated value and outstanding loan balance to see the net sale proceeds."
    },
    "assumption_discharge_fee": {
      "vi": "Phí tất toán khoản vay là ước tính quy ước ({low}–{high}), do bên cho vay quyết định, không phải quy định pháp luật.",
      "en": "The loan discharge fee is a conventional estimate ({low}–{high}), lender-set, not a regulated figure."
    },
    "assumption_break_cost_to_verify": {
      "vi": "Vì khoản vay có lãi suất cố định, phí phạt tất toán sớm cần bên cho vay xác nhận — không phải là một tỷ lệ cố định, chúng tôi không ước tính con số này.",
      "en": "Because the loan is fixed-rate, an early-repayment break cost applies and needs your lender to quote it — it is not a fixed percentage, so we don't estimate a figure."
    },
    "assumption_no_exit_fee_variable": {
      "vi": "Với khoản vay lãi suất thả nổi, không có phí phạt tất toán sớm (quy định từ 1/7/2011) — chỉ có phí tất toán hành chính.",
      "en": "For a variable-rate loan, there is no early-exit penalty (banned from 1 July 2011) — only the administrative discharge fee applies."
    },
    "assumption_settlement_mismatch": {
      "vi": "Ngày tất toán nhà mới sớm hơn ngày bán nhà hiện tại dự kiến — bạn có thể cần vay bắc cầu (bridging finance); hãy trao đổi với chuyên viên cho vay.",
      "en": "The new home's settlement date is earlier than your current home's expected sale settlement — you may need bridging finance; discuss this with a mortgage broker or lender."
    }
  }
}
```

Notes:

- **No `fills`.** No outcome leaf is set by a KB rule. `net_sale_proceeds` is resolver-computed from
  user-attested facts + the reused selling-costs/CGT figures + this doc's loan-payout bands; this doc
  supplies only labels and assumption prose.
- **Reuses `kb.copy.disposition`'s CGT/selling-cost prose deliberately.** The regulated content is
  identical whichever component applies it (a current sale vs. a future one) — one copy doc per
  regulated concept, not a second copy fork per consuming component.
