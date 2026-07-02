---
slug: kb.non-resident-tax.cgt-no-ppor-exemption
effective_from: 2025-07-01
last_verified: 2026-07-02
---

# Foreign-resident CGT on the eventual sale — no main-residence exemption

This doc owns the **Mode-B disposition-phase synthesis**: what happens to capital gains tax (CGT) when a **foreign-person** owner (Vietnam-parent-funded / AU temporary-resident FHB) eventually sells the home. It grounds `ownership_planning` (component 11) `non_resident_tax_obligations.cgt_on_eventual_sale_treatment`.

It owns the **foreign-person lifecycle consequence + the mode-switch interaction** — it does **not** restate the underlying statutory rules. The two rules it depends on are single-owned in the Mode-A/investor tax docs:

- **The main-residence exemption is removed for foreign residents** — owned by [`kb.tax.cgt-main-residence-exemption`](../tax/cgt-main-residence-exemption.md) (removed for disposals from 7:30pm AEST 9 May 2017 unless the life-events test is met).
- **The 50% CGT discount is apportioned for foreign/temporary residents** — owned by [`kb.tax.cgt-50-percent-discount`](../tax/cgt-50-percent-discount.md) (no discount for the portion of the gain accruing while a foreign or temporary resident after 8 May 2012).

## The Mode-B default: a taxable disposal, not an exempt one

Mode A's disposition base case is **CGT-exempt** — the owner-occupier's main residence, sold as their home, pays no CGT ([`kb.tax.cgt-main-residence-exemption`](../tax/cgt-main-residence-exemption.md)). **Mode B inverts that default.** A buyer who is a **foreign resident for tax at the time of the disposal** cannot claim the main-residence exemption for the foreign-resident period, so the eventual sale is a **taxable CGT event**, and the plan must not silently treat the sale proceeds as tax-free the way the Mode-A base case does.

The load-bearing distinction is **tax residency, not FIRB status** (the two are separate facts — `buyer_profile` F2 `tax_residency` / `residency_for_tax`):

- A buyer who holds and sells while a **non-resident (foreign resident) for tax** loses the main-residence exemption for that period and the full 50% discount for that period.
- A buyer who is an **Australian resident for tax** at the relevant time (including a temporary resident who meets the residency test) may access the exemption / discount for the **resident** portion of ownership — which is exactly what the mode switch below turns on.

Because the apportionment across resident and non-resident periods depends on day-counts and residency spans the plan does not fully capture, the resolver returns a **`to_verify` / deferring** treatment — it states that foreign-resident CGT applies and no PPOR exemption is available for the foreign-resident period, and points to a registered tax agent; it does **not** author an estimated taxable-gain figure.

## The mode-switch interaction

Mode B is a **transitional** state. When the buyer is granted **PR or citizenship** and becomes an **Australian resident for tax**, the plan offers to migrate to Mode A (owner-occupier) or Mode C (investor) — and from that point the main-residence exemption and the full discount become available for the **resident** period of ownership. The CGT treatment is therefore period-dependent: the foreign-resident span is taxable; a later resident span can qualify. This is why `ownership_planning.lifecycle_alerts.pr_grant_event_triggers_mode_switch` carries a CGT consequence, not just a re-labelling.

## Relevance for the Vietnam-parent-funded / temp-resident buyer (Mode B)

- **The home is not automatically CGT-free.** Unlike the Mode-A first home, a foreign-resident owner's eventual sale is a taxable event for the foreign-resident period — the plan states this plainly so the disposition net proceeds are not silently overstated.
- **Residency at the disposal date is the hinge.** Selling while still a foreign resident forfeits the exemption and the full discount; selling after becoming a resident for tax can recover them for the resident period. The plan names the trigger rather than asserting a fixed treatment.
- **Information, not advice.** The plan states the treatment and the triggers and points to a registered tax agent / the ATO; it never computes a binding CGT assessment. Distinct from the **collection mechanism** at settlement (the purchaser's 15% withholding), owned by [`kb.non-resident-tax.foreign-resident-cgt-withholding`](foreign-resident-cgt-withholding.md).

## Rules

Pure-reference (`fills: []`). The `ownership_planning` resolver sets `non_resident_tax_obligations.cgt_on_eventual_sale_treatment` from the foreign-resident default below and returns a `to_verify` verdict (deferring to a registered tax agent) once resident/non-resident-period apportionment is in play — never an estimated gain. The underlying rules are `REGULATED` but **owned elsewhere** (cross-referenced, not restated); this doc's parameters are the Mode-B application.

```jsonc
{
  "fills": [],
  "parameters": {
    "main_residence_exemption_unavailable_for_foreign_resident_period": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "owned by kb.tax.cgt-main-residence-exemption (removed for foreign residents at disposal from 9 May 2017, life-events test aside); the Mode-B default is a taxable disposal for the foreign-resident period, not exempt." },
    "cgt_discount_apportioned_for_foreign_resident_period": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "owned by kb.tax.cgt-50-percent-discount (no full discount for the gain accruing while a foreign/temporary resident after 8 May 2012); not restated here." },
    "treatment_is_residency_dependent_not_firb_dependent": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "the CGT treatment turns on tax residency at the relevant time (buyer_profile F2 tax_residency), a distinct fact from FIRB/visa status." },
    "mode_switch_restores_resident_period_treatment": { "type": "bool", "value": true, "provenance": "CONVENTION", "note": "on a PR/citizenship grant the buyer becomes a resident for tax; the exemption/discount become available for the resident period of ownership — the CGT consequence carried by pr_grant_event_triggers_mode_switch." },
    "cgt_on_eventual_sale_treatment_default": { "type": "string", "value": "Foreign-resident CGT applies; no main-residence exemption for the foreign-resident period, and the 50% discount is apportioned — confirm apportionment with a registered tax agent.", "provenance": "REGULATED", "note": "seeds ownership_planning.non_resident_tax_obligations.cgt_on_eventual_sale_treatment; the resolver defers apportionment to a professional (to_verify), never an authored gain." }
  }
}
```

Notes:

- **No `fills`; a synthesis/pointer doc.** It owns the *Mode-B disposition consequence + the mode-switch interaction*; the *exemption-removal rule* → [`kb.tax.cgt-main-residence-exemption`](../tax/cgt-main-residence-exemption.md); the *discount apportionment* → [`kb.tax.cgt-50-percent-discount`](../tax/cgt-50-percent-discount.md); the *settlement withholding mechanism* → [`kb.non-resident-tax.foreign-resident-cgt-withholding`](foreign-resident-cgt-withholding.md).
- **Inverts the Mode-A default.** Mode A disposes CGT-exempt; Mode B disposes taxable for the foreign-resident period — the plan must state the taxable treatment rather than inherit the exempt base case.
- **`to_verify`, not an estimate.** Apportionment across resident/non-resident periods depends on day-counts the plan does not hold; the resolver defers to a registered tax agent and never authors a taxable-gain figure.

## Sources

- ATO — *Main residence exemption for foreign residents* (removed for disposals from 7:30pm AEST 9 May 2017 unless the life-events test is met; transitional to 30 June 2020) — https://www.ato.gov.au/individuals-and-families/investments-and-assets/capital-gains-tax/foreign-residents-and-capital-gains-tax/main-residence-exemption-for-foreign-residents
- ATO — *Your residency status and CGT* (foreign residents are not entitled to the main residence exemption unless the life-events test is met) — https://www.ato.gov.au/individuals-and-families/investments-and-assets/capital-gains-tax/foreign-residents-and-capital-gains-tax/your-residency-status-and-cgt
- ATO — *CGT discount* (the discount is not available for the portion of a gain accruing while a foreign or temporary resident after 8 May 2012; apportioned for periods of Australian residency) — https://www.ato.gov.au/individuals-and-families/investments-and-assets/capital-gains-tax/cgt-discount
