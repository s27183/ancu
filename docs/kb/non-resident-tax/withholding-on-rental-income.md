---
slug: kb.non-resident-tax.withholding-on-rental-income
effective_from: 2025-07-01
last_verified: 2026-07-06
sources:
  - url: https://www.ato.gov.au/individuals-and-families/coming-to-australia-or-going-overseas/your-tax-residency/foreign-and-temporary-residents
    retrieved: 2026-07-06
    note: "PRIMARY (ATO) — foreign residents cannot claim the tax-free threshold; taxed on Australian-source income. Verified via WebSearch corroboration 2026-07-06 (ATO direct WebFetch 403 in-sandbox): no tax-free threshold, no Medicare levy, must lodge return — all CONFIRMED unchanged."
  - url: https://www.ato.gov.au/individuals-and-families/investments-and-assets/property-and-land/residential-rental-properties/rental-income-you-must-declare
    retrieved: 2026-07-06
    note: "PRIMARY (ATO) — rent for an Australian property is declared as income in an Australian tax return (net rental income)."
  - url: https://www.ato.gov.au/individuals-and-families/coming-to-australia-or-going-overseas/australian-income-of-foreign-residents/foreign-resident-payg-withholding-individual-entities
    retrieved: 2026-07-06
    note: "RE-VERIFY ANCHOR for the doc's central 'no final withholding on directly-held residential rent' claim. Several commercial expat-tax sources (Odin, expat blogs) assert a property manager MUST withhold on non-resident rent; the doc's position is that directly-held residential rent is NOT a prescribed foreign-resident withholding payment (assessed by return instead). This ATO page is the primary to confirm the letter of it — could not be WebFetched (403) this session. See NEEDS REVIEW in the backfill report."

# Non-resident rental income — taxed by assessment, not final withholding

This doc owns the **holding-phase income-tax treatment** of Australian rental income for a **foreign-resident** owner (Mode B — Vietnam-parent-funded / AU temporary-resident FHB who lets the property rather than occupying it). It grounds `ownership_planning` (component 11) `non_resident_tax_obligations.rental_income_withholding_applicable` and `annual_obligations.non_resident_tax_filing_required`.

## The honest correction: assessment, not a final withholding tax

The blueprint field is named `rental_income_withholding_applicable`, but for **directly-held Australian residential real property the rent is not subject to a final withholding tax**. The correct treatment is **assessment**: the foreign-resident owner declares the rental income (net of deductible expenses) in an **Australian tax return** and is taxed at **foreign-resident rates**. The property manager / tenant does not withhold a final tax on the rent. The plan states the *return-lodgement obligation*, not a phantom withholding — surfacing "withholding applicable = false, but a return and foreign-resident-rate assessment are required" is the honest fill.

(The one genuine *withholding* in this buyer's lifecycle is at the **eventual sale** — the purchaser's foreign-resident capital gains withholding — which is a CGT-collection mechanism, not a tax on rent; owned by [`kb.non-resident-tax.foreign-resident-cgt-withholding`](foreign-resident-cgt-withholding.md).)

## What the foreign-resident owner actually owes

- **Declare all Australian rental income.** Any rent or lease payments for the Australian property are declared as income in an Australian tax return, whether or not actually paid to the owner.
- **No tax-free threshold.** Foreign residents cannot claim the tax-free threshold — they are taxed **from the first dollar** of Australian income at the foreign-resident rate schedule (which starts higher than the resident schedule). The specific bracket figures are the ATO's statutory rate table and are **not restated here** — the resolver defers the assessed figure to the return / a registered tax agent.
- **No Medicare levy.** Foreign residents do not pay the Medicare levy (they are not entitled to Medicare).
- **A tax return is required.** A foreign resident with Australian-sourced rental income **must lodge an Australian tax return** — so `non_resident_tax_filing_required` is **true** whenever the property produces income for a foreign-resident owner.
- **Treaty interaction.** The Australia–Vietnam position may affect the final liability; the plan flags that a treaty may apply and points to a professional (VN-side tax coordination is a labelled placeholder — [`kb.bilingual.coordination-norms`](../bilingual/coordination-norms.md) for the coordination surface).

## Relevance for the Vietnam-parent-funded / temp-resident buyer (Mode B)

- **Letting the property creates an annual filing obligation.** A foreign-resident owner who rents the home out (rather than occupying it — note the vacancy-fee interaction, since a genuinely-rented property also satisfies the FIRB occupancy test) must lodge an Australian return each year and be assessed at foreign-resident rates.
- **"Withholding" is the wrong mental model for rent.** The plan corrects the common expectation of a flat final withholding on rent — it is assessment on the net rental income, so deductible expenses reduce the taxable amount, and the figure is a return outcome, not a headline rate.
- **Information, not advice.** The plan states the return obligation, the no-tax-free-threshold and no-Medicare facts, and points to a registered tax agent / the ATO for the assessed figure; it never computes a binding assessment.

## Rules

Pure-reference (`fills: []`). The `ownership_planning` resolver sets `rental_income_withholding_applicable` to the **honest value (no final withholding on directly-held rent)** with the assessment note, and sets `non_resident_tax_filing_required = true` whenever a foreign-resident owner's property produces income. The treatment facts are `REGULATED` (ATO); the specific bracket figures are **removed from reach** (deferred to the return / a professional), not asserted.

```jsonc
{
  "fills": [],
  "parameters": {
    "final_withholding_on_directly_held_rent": { "type": "bool", "value": false, "provenance": "REGULATED", "note": "directly-held Australian residential rent is NOT subject to a final withholding tax; it is taxed by assessment via a lodged return — the honest value behind the mis-named rental_income_withholding_applicable field." },
    "rental_income_taxed_by_assessment": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "the foreign-resident owner declares net rental income in an Australian tax return and is taxed at foreign-resident rates." },
    "no_tax_free_threshold_for_foreign_resident": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "foreign residents cannot claim the tax-free threshold — taxed from the first dollar at the foreign-resident schedule; specific brackets are the ATO rate table, deferred not restated." },
    "no_medicare_levy_for_foreign_resident": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "foreign residents do not pay the Medicare levy (not entitled to Medicare)." },
    "australian_tax_return_required_if_income": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "a foreign resident with Australian-sourced rental income must lodge an Australian tax return — seeds non_resident_tax_filing_required = true when the property produces income." }
  }
}
```

Notes:

- **No `fills`; a treatment doc.** It owns the *holding-phase income-tax treatment*; the *sale-time CGT withholding* → [`kb.non-resident-tax.foreign-resident-cgt-withholding`](foreign-resident-cgt-withholding.md); the *CGT-on-gain treatment* → [`kb.non-resident-tax.cgt-no-ppor-exemption`](cgt-no-ppor-exemption.md).
- **Corrects the field name.** `rental_income_withholding_applicable` is a misnomer for directly-held property; the resolver sets it to the honest value and states the assessment obligation, rather than asserting a phantom withholding.
- **Figures removed from reach.** The bracket schedule is the ATO's; the resolver defers the assessed amount to the return / a registered tax agent and never authors a rate-times-income figure.

## Sources

- ATO — *Foreign and temporary residents* (foreign residents cannot claim the tax-free threshold; taxed on Australian-sourced income) — https://www.ato.gov.au/individuals-and-families/coming-to-australia-or-going-overseas/your-tax-residency/foreign-and-temporary-residents
- ATO — *Rental income you must declare* (rent or lease payments for an Australian property are declared as income in an Australian tax return) — https://www.ato.gov.au/individuals-and-families/investments-and-assets/property-and-land/residential-rental-properties/rental-income-you-must-declare
- ATO — *Tax on Australian income for foreign residents* (foreign residents must lodge an Australian tax return and pay tax on Australian-sourced income; no Medicare levy) — https://www.ato.gov.au/businesses-and-organisations/international-tax-for-business/in-detail/income/tax-on-australian-income-for-foreign-residents
- ATO — *Tax rates – foreign resident* (the foreign-resident rate schedule; no tax-free threshold) — https://www.ato.gov.au/tax-rates-and-codes/tax-rates-foreign-residents
