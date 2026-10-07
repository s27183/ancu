---
slug: kb.investor.gearing-types-and-implications
effective_from: 2025-07-01
last_verified: 2026-07-06
sources:
  - url: https://www.ato.gov.au/individuals-and-families/investments-and-assets/property-and-land/residential-rental-properties
    retrieved: 2026-07-06
  - url: https://moneysmart.gov.au/glossary/negative-gearing
    retrieved: 2026-07-06
  - url: https://www.aph.gov.au/Parliamentary_Business/Bills_Legislation/bd/bd2526/26bd067
    retrieved: 2026-07-06
    path: docs/sources/legislation/treasury-laws-amendment-tax-reform-no-1-act-2026-no49.pdf
---

# Gearing types and their implications

"Gearing" is borrowing to invest, and how the rental income compares to the cost of holding the property defines the gearing **type**. This doc owns the **gearing taxonomy and its decision-support implications** — what positive, neutral, and negative gearing mean, what each does to cash flow and tax, and the trade-offs an investor weighs. It grounds `investment_strategy.gearing_strategy.gearing_type` (the `agent_reasoning_required` enum `positive_geared | neutral_geared | negatively_geared`). The **tax mechanism** of negative gearing — how the loss offsets other income — is owned by [`kb.tax.negative-gearing-mechanics`](../tax/negative-gearing-mechanics.md) and referenced here, not re-derived. This is **decision-support** — it lays out the trade-offs; it does not advise a gearing level. Informational; ASIC line — no financial advice.

## The three gearing types

Gearing type is decided by the sign of the **net holding position**: rental income minus all deductible holding costs (interest, management, rates, insurance, maintenance, depreciation).

- **Positive geared** — rental income **exceeds** holding costs. The property generates a cash surplus before tax; that surplus is **taxable income**. Lower risk to household cash flow; the investor is not relying on growth to justify the hold. Favoured by a `cash_flow` thesis ([`kb.investor.strategy-archetypes`](strategy-archetypes.md)).
- **Neutral geared** — income roughly **equals** holding costs. The property is self-funding; the return is whatever growth occurs, at no ongoing cash cost.
- **Negatively geared** — holding costs **exceed** rental income. The property runs at a cash loss each year; that loss **reduces the investor's taxable income** (the tax mechanism owned by `kb.tax.negative-gearing-mechanics`). The after-tax cost is smaller than the pre-tax loss, but it is still a real out-of-pocket cost the household must fund from other income. The thesis only works if **capital growth** outweighs the cumulative after-tax losses over the hold.

## What each implies

- **Cash flow demand.** Negative gearing requires the household to carry a recurring shortfall — the binding question is *can the household fund it through vacancy, a rate rise, or a job loss?* The deal-breaker `maximum_negative_gearing_loss_acceptable` exists for exactly this.
- **Reliance on growth.** The more negative the gearing, the more the return depends on growth materialising — and growth is **not assured** ([`kb.property.capital-growth-bands`](../property/capital-growth-bands.md) is a historical band, not a forecast). A negatively-geared property in a flat market loses money on both legs.
- **Tax is a discount, not a reason.** A loss that saves tax is still a loss. The plan never frames negative gearing as attractive *because* of the tax benefit — the tax effect reduces the cost of a strategy chosen on its merits.
- **Interest-only vs P&I and offset** interact with gearing — owned by [`kb.lender.serviceability-investment-loans`](../lender/serviceability-investment-loans.md) and the F-cluster loan-policy docs.

## The 2026-27 Budget reform (now law, not yet in effect)

The *Treasury Laws Amendment (Tax Reform No. 1) Act 2026* (Act No. 49 of 2026, assented **26 June 2026**) **limits negative gearing to new builds** from **1 July 2027** — established properties purchased after Budget night (7:30pm AEST 12 May 2026) lose the wage-offset from that date; holdings before Budget night are grandfathered. The plan computes **current law** (full negative gearing available through the transition), **flags the enacted reform** prominently, and marks any post-1-July-2027 position as `to_verify`. The detail and status are owned by [`kb.tax.negative-gearing-mechanics`](../tax/negative-gearing-mechanics.md).

## Relevance for Vietnamese-Australian investors (Mode C)

- **Gearing is a cash-flow decision first.** The plan frames the gearing type by what it demands of the household's monthly cash flow, not by the tax headline — a household carrying its own mortgage feels a negative-gearing shortfall directly.
- **The tax saving never justifies a loss.** The plan presents negative gearing as a cost partly offset by tax, never as a benefit in itself.
- **Reform is enacted but not yet in effect.** If negative gearing is part of the thesis, the plan notes the enacted 1 July 2027 new-builds-only change and marks the post-2027 position to-verify.
- **Decision-support, not advice.** The plan lays out the gearing trade-offs and the household's capacity to carry them; the investor decides. No financial advice.

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **decision-support reference** doc — it fills no slot; `gearing_type` is agent-reasoned and the cash-flow position is computed by `yield_modelling`/`cash_position`. This doc supplies the taxonomy and trade-offs; the tax mechanism is cross-ref'd.

```jsonc
{
  "fills": [],
  "lookup": {
    "gearing_types": {
      "note": "the gearing_type enum and its cash-flow/tax implications — decision-support, not a recommended level",
      "entries": [
        { "type": "positive_geared", "net_position": "income > holding costs", "cash_flow": "surplus (taxable)", "implication": "lower household cash-flow risk; not reliant on growth" },
        { "type": "neutral_geared", "net_position": "income ≈ holding costs", "cash_flow": "self-funding", "implication": "return is growth at no ongoing cash cost" },
        { "type": "negatively_geared", "net_position": "holding costs > income", "cash_flow": "recurring shortfall (after-tax cost)", "implication": "loss reduces taxable income (kb.tax.negative-gearing-mechanics); works only if growth outweighs cumulative after-tax losses" }
      ]
    }
  },
  "parameters": {
    "gearing_type_is_agent_reasoned": { "type": "bool", "value": true, "note": "gearing_type is agent-reasoned; the underlying net position is computed by yield_modelling/cash_position" },
    "tax_mechanism_owner": { "type": "string", "value": "kb.tax.negative-gearing-mechanics", "note": "OWNED ELSEWHERE — how a rental loss offsets other income; referenced, not re-derived" },
    "tax_saving_never_justifies_a_loss": { "type": "bool", "value": true, "note": "negative gearing is a cost partly offset by tax, never a benefit in itself; never frame the tax saving as the reason to gear negatively (ASIC line)" },
    "negative_gearing_reliant_on_growth": { "type": "bool", "value": true, "note": "the more negative the gearing, the more the return depends on growth materialising — growth is NOT assured (kb.property.capital-growth-bands is historical, not a forecast)" },
    "ng_reform_proposed_not_law": { "type": "bool", "value": true, "note": "2026-27 Budget reform (NG limited to new builds from 1 Jul 2027) is now ENACTED — Tax Reform No. 1 Act 2026 (Act No. 49/2026), assented 26 Jun 2026 — but not yet in effect; compute current law, flag the enacted change, to_verify post-2027 — detail owned by kb.tax.negative-gearing-mechanics (key name retained for reference stability)" }
  }
}
```

Notes:

- **No `fills`.** `gearing_type` is agent-reasoned; the net cash-flow position is computed by `yield_modelling`/`cash_position`. This doc supplies the taxonomy and trade-offs.
- **Single-owner via cross-ref.** Tax mechanism → `kb.tax.negative-gearing-mechanics`; growth uncertainty → `kb.property.capital-growth-bands`; loan-structure interaction → `kb.lender.serviceability-investment-loans`. This doc owns the gearing taxonomy and its decision-support implications.
- **Reform: enacted, not yet in effect.** Current law computed, enacted reform flagged, post-1-July-2027 → `to_verify`; status owned by the negative-gearing doc.
- **ASIC line.** Decision-support only — the trade-offs and the household's capacity to carry them; no recommended gearing level.

## Sources

- ATO — *Rental properties – claiming a loss (negative gearing)* (the gearing position and how a loss is treated) — https://www.ato.gov.au/individuals-and-families/investments-and-assets/property-and-land/residential-rental-properties
- ASIC Moneysmart — *Property investment* (positive vs negative gearing as a cash-flow and risk trade-off; the loss is real) — https://moneysmart.gov.au/property-investment
- Parliament of Australia — *Treasury Laws Amendment (Tax Reform No. 1) Bill 2026* bill digest (negative-gearing change from 1 July 2027; passed both Houses 25 Jun 2026, assented 26 Jun 2026 — Act No. 49 of 2026) — https://www.aph.gov.au/Parliamentary_Business/Bills_Legislation/bd/bd2526/26bd067
- Federal Register of Legislation — *Treasury Laws Amendment (Tax Reform No. 1) Act 2026* (Act No. 49 of 2026) — https://www.legislation.gov.au/C2026A00049/latest/text (archived: `docs/sources/legislation/treasury-laws-amendment-tax-reform-no-1-act-2026-no49.pdf`)
