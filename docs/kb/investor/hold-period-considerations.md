---
slug: kb.investor.hold-period-considerations
effective_from: 2025-07-01
last_verified: 2026-06-23
---

# Hold-period considerations

How long an investor intends to hold a property shapes almost every other figure — whether the CGT discount applies, how acquisition costs amortise, how much growth has time to compound, and how vacancy/maintenance shocks average out. This doc owns the **hold-period decision factors** — the considerations that set a realistic `hold_period_years` and the thresholds that make hold length matter. It grounds `investment_strategy.targets.hold_period_years` (which becomes the horizon `H` read by `disposition`). The **regulated 12-month CGT-discount threshold** is owned by [`kb.tax.cgt-50-percent-discount`](../tax/cgt-50-percent-discount.md) and referenced here, not re-stated. It is a **reference** doc — it asserts no figure of its own. Informational.

## What hold length governs

- **The CGT 12-month threshold (regulated — owned elsewhere).** Holding an asset for **more than 12 months** before the CGT event qualifies an individual/trust for the **50% CGT discount** — the single sharpest hold-length cliff. The rule, eligibility, and the proposed post-2027 change are owned by [`kb.tax.cgt-50-percent-discount`](../tax/cgt-50-percent-discount.md); this doc only flags that a sub-12-month sale forfeits the discount. The discount itself is applied by `disposition`, not here.
- **Amortising transaction costs.** Stamp duty, conveyancing, LMI, and selling costs are large, one-off, and **not recoverable** — spread over a short hold they can erase years of net return. A longer hold dilutes them. The acquisition cost bands are owned by [`kb.buyer-costs.investor-additional-costs`](../buyer-costs/investor-additional-costs.md) and the selling-cost bands by `disposition`'s anchors.
- **Time for growth to compound — and to be uncertain.** A capital-growth or land-banking thesis needs years; a short horizon exposes the investor to the timing risk that growth simply hasn't arrived. The projection band is the labelled placeholder [`kb.property.capital-growth-bands`](../property/capital-growth-bands.md) — explicitly not a forecast.
- **Averaging out shocks.** Vacancy and maintenance are lumpy; over a longer hold the modelled rates ([`kb.investor.vacancy-rate-assumptions`](vacancy-rate-assumptions.md), [`kb.investor.operating-expenses-typical-ratios`](operating-expenses-typical-ratios.md)) are more representative of the actual experience.
- **The exit must be coherent with the hold.** The intended hold and the exit strategy ([`kb.investor.exit-strategy-options`](exit-strategy-options.md)) are two sides of one decision — a 3-year hold with a "hold perpetually" exit is internally inconsistent.

## Typical horizons (decision-support, not prescriptive)

- **Short (< ~3 years)** — forfeits the CGT discount if sold under 12 months; transaction costs poorly amortised; high timing risk. Usually only a `value_add` flip thesis tolerates it, and even then the costs are punishing.
- **Medium (~3–7 years)** — the discount is secured; growth has some time; the common range for a `balanced` thesis.
- **Long (~7+ years)** — transaction costs well diluted; growth compounds; the natural horizon for `capital_growth` and `land_banking`. The trade-off is opportunity cost and the household's own life/cash-flow changes over a long horizon.

## Relevance for Vietnamese-Australian investors (Mode C)

- **The 12-month cliff is flagged, not buried.** The plan notes that selling under 12 months forfeits the CGT 50% discount, pointing to the tax doc for the rule.
- **Short holds are expensive.** The plan shows how one-off acquisition and selling costs erode return over a short hold, so the horizon is set with eyes open.
- **Growth needs time and isn't promised.** A growth thesis is paired with a realistic horizon and the explicit caveat that the projection band is a placeholder, not a forecast.
- **Hold and exit must agree.** The plan checks that the chosen hold length and exit strategy are coherent. Information, not advice.

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **reference** doc — it fills no slot; `hold_period_years` is an investor input (the horizon `H`), and this doc supplies the considerations that set it realistically. The CGT threshold is referenced from the tax doc.

```jsonc
{
  "fills": [],
  "parameters": {
    "cgt_12_month_threshold_owner": { "type": "string", "value": "kb.tax.cgt-50-percent-discount", "note": "OWNED ELSEWHERE — holding >12 months qualifies for the 50% CGT discount; a sub-12-month sale forfeits it; the rule + post-2027 reform live in the tax doc; the discount is applied by disposition" },
    "transaction_costs_amortise_over_hold": { "type": "bool", "value": true, "note": "one-off, non-recoverable acquisition + selling costs are diluted by a longer hold; bands owned by kb.buyer-costs.investor-additional-costs (acquisition) and disposition's anchors (selling)" },
    "growth_needs_time_and_is_uncertain": { "type": "bool", "value": true, "note": "a growth thesis needs years; the projection band is a labelled placeholder (kb.property.capital-growth-bands), not a forecast" },
    "hold_and_exit_must_be_coherent": { "type": "bool", "value": true, "note": "hold_period_years and exit strategy (kb.investor.exit-strategy-options) are one decision; the agent flags an inconsistent pairing" }
  },
  "lookup": {
    "typical_horizons": {
      "note": "decision-support bands, not prescriptive — the trade-offs at each horizon",
      "entries": [
        { "band": "short", "range_years": "<3", "implication": "CGT discount forfeited if sold <12mo; poor cost amortisation; high timing risk; mainly value_add flip" },
        { "band": "medium", "range_years": "3-7", "implication": "discount secured; some growth time; common balanced-thesis range" },
        { "band": "long", "range_years": "7+", "implication": "costs well diluted; growth compounds; natural capital_growth / land_banking horizon; trade-off is opportunity cost + life changes" }
      ]
    }
  }
}
```

Notes:

- **No `fills`.** `hold_period_years` is an investor input read as the horizon `H` by `disposition`; this doc supplies the considerations that make it realistic.
- **Single-owner via cross-ref.** CGT threshold → `kb.tax.cgt-50-percent-discount`; growth band → `kb.property.capital-growth-bands`; acquisition costs → `kb.buyer-costs.investor-additional-costs`; vacancy/opex → the Cluster-Y modelling docs; exit → `kb.investor.exit-strategy-options`. This doc owns only the hold-period decision factors.
- **Horizons are decision-support.** The bands frame trade-offs; they are not a prescription of how long to hold.

## Sources

- ATO — *CGT discount* (the more-than-12-months holding rule for the 50% discount — referenced; owned by kb.tax.cgt-50-percent-discount) — https://www.ato.gov.au/individuals-and-families/investments-and-assets/capital-gains-tax/cgt-discount
- ASIC Moneysmart — *Investing in property* (property is a long-term investment; transaction costs and time horizon) — https://moneysmart.gov.au/property-investment/investing-in-property
