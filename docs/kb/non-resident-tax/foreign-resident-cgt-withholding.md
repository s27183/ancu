---
slug: kb.non-resident-tax.foreign-resident-cgt-withholding
effective_from: 2025-07-01
last_verified: 2026-07-06
sources:
  - url: https://www.ato.gov.au/individuals-and-families/investments-and-assets/capital-gains-tax/foreign-residents-and-capital-gains-tax/foreign-resident-capital-gains-withholding/foreign-resident-capital-gains-withholding-overview
    retrieved: 2026-07-06
    note: "PRIMARY (ATO). Verified via WebSearch corroboration 2026-07-06 (ATO direct WebFetch returns 403 in-sandbox); the sub-pages for clearance certificates, variations, and paying the withholding are listed in the markdown Sources block below. 15% rate + removal of the A$750,000 threshold for contracts entered on/after 1 January 2025 confirmed UNCHANGED (was 12.5% / $750k floor to 31 Dec 2024)."

# Foreign resident capital gains withholding (FRCGW) — the collection mechanism at sale

This doc owns the **settlement-time CGT collection mechanism** that applies when a **foreign-resident** owner (Mode B) eventually **sells** the Australian property: the purchaser withholds a percentage of the price and remits it to the ATO. It grounds the disposition/sale side of `ownership_planning` (component 11) `non_resident_tax_obligations.cgt_on_eventual_sale_treatment`.

FRCGW is a **withholding (collection) mechanism, not a separate tax**. It is distinct from the CGT *liability* on the gain — owned by [`kb.non-resident-tax.cgt-no-ppor-exemption`](cgt-no-ppor-exemption.md) — and from the holding-phase income tax on rent — owned by [`kb.non-resident-tax.withholding-on-rental-income`](withholding-on-rental-income.md). The three form the foreign-resident tax picture across the lifecycle: rent (assessment) → gain (CGT, no exemption) → sale-day collection (FRCGW).

## The mechanism — 15%, threshold removed

For contracts entered into **on or after 1 January 2025**:

- **Rate: 15%** of the price (or market value if not at arm's length) — up from the earlier 12.5%.
- **Threshold removed: applies to all property regardless of value.** The earlier A$750,000 threshold is gone — from 1 January 2025 FRCGW applies to **every** disposal of Australian taxable real property, not just those at or above a value floor.
- **The purchaser withholds and remits.** The buyer of the property withholds the amount at settlement and pays it to the ATO; the foreign-resident vendor receives the net.

## How it interacts with the actual CGT liability

FRCGW is a **prepayment credited against the vendor's real CGT**, not the final tax:

- **It is credited on the return.** The withheld 15% is credited against the foreign-resident vendor's actual CGT liability when they lodge their Australian tax return; if the true CGT is lower than the amount withheld, the excess is refunded on assessment.
- **A variation can reduce it up front.** A foreign-resident vendor who expects the withheld amount to exceed the real CGT (e.g. a modest gain, or a loss) can apply to the ATO for a **variation notice** to reduce the amount the purchaser withholds — supplied to the purchaser before settlement.
- **The Australian-resident side uses a clearance certificate.** An **Australian-resident** vendor avoids FRCGW entirely by giving the purchaser a **clearance certificate** at or before settlement. This is the resident/foreign-resident hinge: after a **mode switch** on a PR/citizenship grant, an owner who is a resident for tax at the sale can supply a clearance certificate and is not subject to FRCGW.

## Relevance for the Vietnam-parent-funded / temp-resident buyer (Mode B)

- **The sale-day cash flow, not the tax bill.** FRCGW reduces the proceeds the foreign-resident vendor receives *at settlement* by 15% of the price, well before the CGT return is lodged — a cash-flow fact the disposition projection must surface, separate from the eventual assessed CGT.
- **Variation is the lever.** Where the real gain is small (or the exemption/discount apportionment leaves little taxable), a variation notice avoids over-withholding — the plan flags the option and points to a registered tax agent to lodge it.
- **The symmetric purchaser-side duty.** A Mode-B buyer *purchasing* from a foreign-resident vendor is themselves the withholder — so the same mechanism appears on the buy side; the plan notes it but the primary framing here is the buyer's own eventual disposal.
- **Information, not advice.** The plan states the rate, the threshold removal, the credit-on-return and variation mechanics, and points to a registered tax agent / the ATO; it never computes a binding withholding or CGT figure.

## Rules

Pure-reference (`fills: []`). The `ownership_planning` resolver surfaces the FRCGW mechanism against `cgt_on_eventual_sale_treatment` — the sale-day withholding and its credit against the vendor's return — as a `REGULATED` fact, and defers the withheld/assessed amounts to a registered tax agent (no authored figure). The clearance-certificate path is the resident-for-tax exit reached after a mode switch.

```jsonc
{
  "fills": [],
  "parameters": {
    "frcgw_rate_percent": { "type": "number", "value": 15, "provenance": "REGULATED", "note": "ATO — FRCGW rate for contracts on or after 1 January 2025 (up from 12.5%); withheld by the purchaser on the price / market value." },
    "frcgw_threshold_removed_from_2025": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "ATO — from 1 January 2025 the A$750,000 value threshold is removed; FRCGW applies to all disposals of Australian taxable real property regardless of value." },
    "frcgw_contract_date_basis": { "type": "string", "value": "contracts entered on or after 1 January 2025", "provenance": "REGULATED", "note": "the 15% / no-threshold rules key off the contract date, not settlement." },
    "withheld_amount_credited_against_cgt": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "ATO — the withheld amount is credited against the vendor's actual CGT on lodging the return; excess is refunded on assessment. FRCGW is a prepayment, not a separate tax." },
    "variation_can_reduce_withholding": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "ATO — a foreign-resident vendor can apply for a variation notice to reduce the amount withheld where it would exceed the real CGT; supplied to the purchaser before settlement." },
    "clearance_certificate_is_the_resident_exit": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "ATO — an Australian-resident vendor avoids FRCGW by giving the purchaser a clearance certificate at/before settlement; reachable after a mode switch on a PR/citizenship grant." }
  }
}
```

Notes:

- **No `fills`; a mechanism doc.** It owns the *sale-time collection mechanism*; the *CGT liability on the gain* → [`kb.non-resident-tax.cgt-no-ppor-exemption`](cgt-no-ppor-exemption.md); the *holding-phase rental tax* → [`kb.non-resident-tax.withholding-on-rental-income`](withholding-on-rental-income.md).
- **A prepayment, not a tax.** The 15% is credited against the vendor's real CGT (refundable excess); the plan surfaces it as a settlement-day cash-flow reduction distinct from the assessed CGT.
- **Figures deferred.** The resolver states the rate/threshold/mechanism; the withheld and assessed amounts are deferred to a registered tax agent — never authored.

## Sources

- ATO — *Foreign resident capital gains withholding overview* (15% rate, threshold removed, for contracts on or after 1 January 2025; applies to all vendors of taxable real property) — https://www.ato.gov.au/individuals-and-families/investments-and-assets/capital-gains-tax/foreign-residents-and-capital-gains-tax/foreign-resident-capital-gains-withholding/foreign-resident-capital-gains-withholding-overview
- ATO — *Australian residents and clearance certificates* (Australian-resident vendors supply a clearance certificate at/before settlement to avoid withholding; otherwise the purchaser withholds up to 15%) — https://www.ato.gov.au/individuals-and-families/investments-and-assets/capital-gains-tax/foreign-residents-and-capital-gains-tax/foreign-resident-capital-gains-withholding/australian-residents-and-clearance-certificates
- ATO — *Foreign residents and variations* (a foreign-resident vendor can apply for a variation to reduce the amount withheld) — https://www.ato.gov.au/individuals-and-families/investments-and-assets/capital-gains-tax/foreign-residents-and-capital-gains-tax/foreign-resident-capital-gains-withholding/foreign-residents-and-variations
- ATO — *Paying the foreign resident capital gains withholding* (the purchaser pays the withheld amount to the ATO; it is credited against the vendor's CGT on assessment) — https://www.ato.gov.au/individuals-and-families/investments-and-assets/capital-gains-tax/foreign-residents-and-capital-gains-tax/foreign-resident-capital-gains-withholding/paying-the-foreign-resident-capital-gains-withholding
