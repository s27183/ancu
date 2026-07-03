---
slug: kb.non-resident.tax-treatment-overview
effective_from: 2025-07-01
last_verified: 2026-07-03
---

# Non-resident investor — AU tax treatment overview (the Mode-D synthesis)

This doc owns the **Mode-D disposition/holding-phase synthesis**: what AU tax treatment applies to a **non-resident foreign investor** (Vietnam-located, buying to invest, never to occupy). It is the entry point `tax_structure_non_resident` (component 7) reads first — it ties together facts that are each single-owned elsewhere, and states the one thing none of those docs individually say: **why Mode D's tax position is simpler than Mode B's, not more complex.** Informational; every figure below is owned and sourced by its cross-referenced doc, not restated here.

## Why Mode D is not Mode B with an investor label

Mode B (Vietnam-parent-funded / AU-temp-resident FHB) is a **transitional** case: the buyer starts as an owner-occupier, may become a foreign resident for tax, and the plan's job is to state which exemptions get *removed* by that shift ([`kb.non-resident-tax.cgt-no-ppor-exemption`](../non-resident-tax/cgt-no-ppor-exemption.md) — the main-residence exemption inverted from the Mode-A default).

Mode D's buyer is a **non-resident investor from day one.** The property was never a main residence and was never going to be — so there is no exemption to invert, no PPOR to lose, and no mode-switch-back-to-owner-occupier story. The base case is the same shape as Mode C's domestic investor (full CGT, no main-residence exemption, ever), with two deltas layered on for non-residency: the CGT discount is unavailable (not merely apportioned), and FRCGW applies at sale.

## The four facts, each owned elsewhere

- **Rental income is assessed, not withheld.** [`kb.non-resident-tax.withholding-on-rental-income`](../non-resident-tax/withholding-on-rental-income.md) — the field name `rental_income_withholding_applicable` is a misnomer for directly-held property; the correct treatment is an Australian tax return at foreign-resident rates, no tax-free threshold, no Medicare levy.
- **No 50% CGT discount on the foreign-resident-period gain.** [`kb.tax.cgt-50-percent-discount`](../tax/cgt-50-percent-discount.md) — already scoped "Mode C/D" in its own header; the discount is unavailable for the portion of the gain accruing while a foreign/temporary resident after 8 May 2012. Because Mode D's buyer is a foreign resident for tax for the whole hold (the common case — no earlier AU-resident period to apportion), the practical result is usually **zero** discount, not a partial one.
- **No PPOR exemption — moot, not removed.** The main-residence exemption ([`kb.tax.cgt-main-residence-exemption`](../tax/cgt-main-residence-exemption.md)) requires the dwelling to have been "the home... for the whole period you owned it." An investment property bought by a non-resident investor never meets that condition, so the exemption never applied — unlike Mode B's owner-occupier-turned-foreign-resident, who genuinely loses an exemption they otherwise would have had. `ppor_exemption_eligible = false` for both modes, but for a different reason; the plan should not present Mode D's investor as having "lost" something they never had.
- **FRCGW applies at sale.** [`kb.non-resident-tax.foreign-resident-cgt-withholding`](../non-resident-tax/foreign-resident-cgt-withholding.md) — 15% of the price withheld by the purchaser at settlement (contracts from 1 January 2025, no value threshold), credited against the vendor's actual CGT on assessment. Same mechanism as Mode B's eventual-disposal case; here it applies to an investment disposal, not a home disposal.

## What's genuinely new for Mode D (owned by this cluster's own docs)

- **Entity restrictions specific to non-residency** — FIRB's foreign-person look-through applies regardless of the holding structure, and an SMSF is generally impractical for a genuinely non-resident investor (the central-management-and-control test). Owned by [`kb.non-resident.entity-options-au-property`](entity-options-au-property.md).
- **Negative gearing is available, narrower in effect.** A non-resident investor can still deduct a net rental loss against **other AU-source income** ([`kb.tax.negative-gearing-mechanics`](../tax/negative-gearing-mechanics.md), current law) — but most non-resident investors have little or no other AU-source income to offset against, so the deduction is often carried forward rather than used in the year it arises. The plan states this mechanically rather than assuming the domestic-investor negative-gearing story applies unchanged.
- **Depreciation is unaffected by residency.** [`kb.tax.depreciation-division-43-and-40`](../tax/depreciation-division-43-and-40.md) — Div 43/40 rates and the 9 May 2017 second-hand-plant restriction have no residency dependency; a non-resident investor claims the identical schedule as a domestic one.
- **Land tax's foreign/absentee surcharge stacks on top of ordinary land tax.** [`kb.tax.land-tax-by-state`](../tax/land-tax-by-state.md) already carries the per-state foreign/absentee surcharges (NSW 5%, VIC 4%, QLD 3%, TAS 2% FILTS) as reasoning context — Mode D reads the same anchor Mode C does, with the surcharge row now load-bearing rather than dormant.

## The AU-VN treaty carve-out

The Australia–Vietnam DTA is otherwise VN-side content (placeholder, [`kb.au-vn-tax-treaty`](../au-vn-tax-treaty.md)) per the 2026-07-03 scoping decision — but where it changes an **AU-side** withholding rate (e.g. a treaty-modified rate on AU-sourced rental income or FRCGW for a VN-tax-resident), that piece belongs here, not in the VN placeholder. As of this authoring, no such AU-side rate modification has been identified against the docs above — the FRCGW rate and the rental-assessment treatment are stated as ordinary domestic-law rates, not treaty-adjusted ones. Re-verify this against the treaty text if a future pass sources it and finds otherwise.

## Relevance for Vietnam-located investors (Mode D)

- **The base case is a taxable disposal from day one — same as Mode C, not an inversion of Mode A.** The plan should not frame Mode D's CGT/rental treatment as something "removed"; it was never available to an investor.
- **Non-residency adds two deltas on top of the investor base case:** the discount is unavailable (not apportioned, in the common no-prior-AU-residency case) and FRCGW applies at sale.
- **Information, not advice.** The plan states these treatments and points to a registered tax agent / the ATO; it never computes a binding assessment or an entity recommendation.

## Rules

Pure-reference (`fills: []`). This is a synthesis/pointer doc — it fills no slot itself; `tax_structure_non_resident` reads this doc first to orient, then the resolver draws the individual figures from each cross-referenced doc's own rules.

```jsonc
{
  "fills": [],
  "parameters": {
    "mode_d_is_investor_base_case_plus_two_deltas": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "Mode D = Mode C's investor CGT/tax base case (never CGT-exempt) + non-residency deltas (no discount, FRCGW) — not Mode B's owner-occupier exemption-removal story inverted." },
    "ppor_exemption_moot_not_removed": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "the property was never a main residence, so kb.tax.cgt-main-residence-exemption's conditions never applied — distinct from Mode B's genuine loss of an exemption the buyer otherwise would have had." },
    "no_au_side_treaty_rate_modification_identified": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "as of this authoring, no AU-VN DTA provision modifying an AU withholding/FRCGW rate has been sourced; re-verify if a future pass finds otherwise, per the AU-side carve-out in the Mode-D scoping decision." }
  }
}
```

Notes:

- **No `fills`; a synthesis/pointer doc.** Every figure is owned and sourced by its cross-referenced doc — this doc's job is orientation and the "why is this simpler than Mode B" framing, not restating figures.
- **Single-owner discipline preserved.** Rental assessment → `kb.non-resident-tax.withholding-on-rental-income`; discount → `kb.tax.cgt-50-percent-discount`; PPOR → `kb.tax.cgt-main-residence-exemption`; FRCGW → `kb.non-resident-tax.foreign-resident-cgt-withholding`; entity → `kb.non-resident.entity-options-au-property`; depreciation → `kb.tax.depreciation-division-43-and-40`; land tax → `kb.tax.land-tax-by-state`.

## Sources

None directly — this is a synthesis doc. See the Sources section of each cross-referenced doc above for the primary citations behind each fact.
