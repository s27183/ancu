---
slug: kb.copy.yield
effective_from: 2026-07-10
last_verified: 2026-07-10
---

# Yield-modelling component copy (bilingual)

User-facing copy-templates for the `yield_modelling` resolver (`fh_engine_fill:yield_modelling/1`
/ `yield_cash_events/1`): the labels for the three hold-phase `cash_events` the resolver places
on the swimlane's Own/Hold column via `purchase_journey`'s generic multi-source harvest —
`rental_income` (in, counterparty `tenant`), `operating_expenses` (out, counterparty
`property_manager`), `loan_interest` (out, counterparty `lender`). Each is a param-free `{vi, en}`
pair — the figure rides in the event's `amount` (a `money_range` — rental income and operating
expenses are bands, per the §B0 banded-money-surface rule; loan interest is a representative-
leverage point collapsed to `[v, v]`), never interpolated into the label.

This is a **copy doc**: it fills no slot and is not a blueprint anchor (reference-exempt; only
slug==path + content_json-parse + bilingual-copy gates apply). The figures themselves are
resolver-computed, KB-grounded, and removed from the LLM's reach (investor-domestic-au.md
component 5); this doc supplies only the bilingual event labels. Vietnamese is authored for
register, not transliterated from the English (trap #4).

## Rules

```jsonc
{
  "fills": [],
  "copy": {
    "event_rental_income": {
      "vi": "Tiền thuê thu vào (hằng năm)",
      "en": "Rental income (annual)"
    },
    "event_operating_expenses": {
      "vi": "Chi phí vận hành (quản lý, thuế đất, bảo hiểm, bảo trì — hằng năm)",
      "en": "Operating expenses (management, land tax, insurance, maintenance — annual)"
    },
    "event_loan_interest": {
      "vi": "Lãi vay đầu tư (hằng năm)",
      "en": "Investment-loan interest (annual)"
    }
  }
}
```
