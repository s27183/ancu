---
slug: kb.buyer-costs.investor-additional-costs
effective_from: 2024-09-01
last_verified: 2026-06-23
---

# Buyer-side costs — additional costs specific to investors

An investor faces the same core acquisition costs as a first home buyer — deposit, stamp duty, LMI, conveyancing, inspections, registration — **plus** a set of investor-specific one-off costs at acquisition, and **minus** the first-home concessions an investor cannot use. This doc owns the **investor-only acquisition cost adders** so `cash_position` can sum the full cash-at-purchase for an investment property. It is a **delta** on the FHB [`kb.buyer-costs.inspections-conveyancing-fees`](inspections-conveyancing-fees.md): the shared inspection/conveyancing/registration ranges are owned there and referenced, not re-banded; this doc adds only what is investor-specific. Figures are **banded** except the regulated minimum-standards driver. Informational; the binding figures are the investor's own quotes and compliance assessment.

## The investor-only acquisition adders

- **Minimum rental / housing standards compliance (REGULATED — the load-bearing investor-only cost).** A property let to a tenant must meet the state's **minimum rental standards** — a regulated bar an owner-occupier never faces. If the property doesn't already comply, bringing it up to standard is a **one-off acquisition cost** (commonly heating, safety switches/RCDs, smoke alarms, locks, ventilation, mould/damp, hot/cold water). The standards and their commencement vary by state:
  - **VIC** — 14 rental minimum standards under the *Residential Tenancies Regulations 2021*, applying to agreements signed on/after **29 March 2021** (heating, electrical/gas safety checks, WELS-rated tapware/toilets, etc.).
  - **QLD** — **minimum housing standards** under the RTRA framework: new tenancies from **1 Sept 2023**, **all tenancies from 1 Sept 2024**.
  - **NSW** — **7 minimum standards** (fitness for habitation) plus mandatory working **smoke alarms** (landlord-maintained) under the *Residential Tenancies Act 2010* and regulation.
  - Other states have their own equivalents (confirm per state). The cost is **banded** (depends entirely on the property's starting condition) and surfaced as a compliance check, not a fixed figure.
- **Lease / tenancy-in-situ review.** If the property is sold **with a tenant in place**, the investor's conveyancer should review the existing lease (term, rent, bond, special conditions). This is an investor-specific conveyancing **add-on** (a few hundred dollars) — distinct from the standard contract review owned by the FHB doc. (The tenancy-in-situ *implications* are owned by `kb.investor.tenancy-in-situ-considerations`, Cluster S.)
- **Initial letting / tenant-placement.** If the property is **vacant** at settlement, placing the first tenant carries a one-off **letting fee** (1–2 weeks' rent) and advertising — owned as a recurring/periodic figure by [`kb.investor.property-management-fees`](../investor/property-management-fees.md); flagged here as a settlement-adjacent cash item so it isn't missed.

## Costs owned elsewhere — referenced, not duplicated

These investor cash items are real but each has a single owner; `cash_position` sums them from their own anchors:

- **Depreciation schedule (QS report)** — a quantity surveyor's report to substantiate depreciation: owned by [`kb.tax.quantity-surveyor-reports`](../tax/quantity-surveyor-reports.md).
- **Entity setup cost** — if buying via a trust/company/SMSF: owned by [`kb.tax.entity-setup-costs`](../tax/entity-setup-costs.md).
- **Full stamp duty (no FHB concession)** — an investor pays the full transfer-duty scale: owned by [`kb.stamp-duty.calc-by-state`](../stamp-duty/calc-by-state.md); the **no-concession / no-foreign-surcharge-for-domestic** framing by [`kb.investor.deposit-requirements-investment-loans`](../investor/deposit-requirements-investment-loans.md).
- **Landlord insurance (first year)** — a recurring operating expense (owned by [`kb.investor.operating-expenses-typical-ratios`](../investor/operating-expenses-typical-ratios.md)), not an acquisition cost; flagged so it's planned from settlement, but counted on the holding side to avoid double-counting.

## Relevance for Vietnamese-Australian investors (Mode C)

- **Minimum standards are a regulated, easy-to-miss cost.** The plan flags that a let property must meet the state's rental minimum standards, and bands the upgrade cost where the property may not comply — a cost owner-occupiers never face and first-time investors often overlook.
- **No first-home help, full stamp duty.** The plan makes clear an investor gets no FHB concessions and pays the full duty (referenced from the duty doc), so the cash-at-purchase isn't under-estimated from an owner-occupier mindset.
- **Tenant-in-situ needs a lease review.** If buying with a tenant, the plan adds the lease-review cost and points to the tenancy-in-situ implications.
- **Every cost has one owner.** The QS report, entity setup, duty, and landlord insurance are summed from their own anchors — this doc adds only the investor-specific acquisition adders. Information, not advice.

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **reference** doc — it fills no slot; the investor cost adders are **resolver-estimated** from these bands and summed into `cash_position` alongside the costs owned by sibling docs. The minimum-standards driver is regulated; the dollar cost is banded.

```jsonc
{
  "fills": [],
  "parameters": {
    "minimum_rental_standards_apply": { "type": "bool", "value": true, "note": "REGULATED — a let property must meet the state's minimum rental/housing standards; non-compliance → a one-off upgrade cost at acquisition (an investor-only cost an owner-occupier never faces)" },
    "lease_review_tenancy_in_situ": { "type": "bool", "value": true, "note": "CONVENTION — if sold with a tenant in place, an investor-specific conveyancing add-on (~a few hundred dollars) to review the existing lease; implications owned by kb.investor.tenancy-in-situ-considerations" },
    "initial_letting_if_vacant": { "type": "string", "value": "kb.investor.property-management-fees", "note": "OWNED ELSEWHERE — one-off letting fee (1–2 weeks rent) + advertising to place the first tenant if vacant at settlement; flagged here as a settlement-adjacent cash item" },
    "qs_depreciation_report_cost": { "type": "string", "value": "kb.tax.quantity-surveyor-reports", "note": "OWNED ELSEWHERE — QS report to substantiate depreciation; summed by cash_position from its own anchor" },
    "entity_setup_cost": { "type": "string", "value": "kb.tax.entity-setup-costs", "note": "OWNED ELSEWHERE — trust/company/SMSF setup if applicable; cross-ref" },
    "full_stamp_duty_no_concession": { "type": "string", "value": "kb.stamp-duty.calc-by-state", "note": "OWNED ELSEWHERE — investor pays the full duty scale (no FHB concession); no foreign surcharge for a domestic investor (kb.investor.deposit-requirements-investment-loans)" },
    "landlord_insurance_is_holding_cost": { "type": "bool", "value": true, "note": "landlord insurance is a recurring OPERATING expense (kb.investor.operating-expenses-typical-ratios), not an acquisition cost — flagged to plan from settlement, counted on the holding side to avoid double-counting" },
    "shared_costs_owner": { "type": "string", "value": "kb.buyer-costs.inspections-conveyancing-fees", "note": "OWNED ELSEWHERE — the shared inspection/conveyancing/registration/utility ranges; this doc is the investor DELTA on top, not a re-band" }
  },
  "lookup": {
    "minimum_rental_standards_by_state": {
      "note": "REGULATED — the state minimum-standards regimes that can trigger an upgrade cost. The standards are regulated; the dollar upgrade cost is banded (depends on the property's starting condition).",
      "entries": [
        { "state": "VIC", "regime": "14 rental minimum standards", "instrument": "Residential Tenancies Regulations 2021", "applies_from": "2021-03-29", "verification": "regulator-confirmed (Consumer Affairs Victoria / VBA)" },
        { "state": "QLD", "regime": "minimum housing standards", "instrument": "RTRA framework (RTA)", "applies_from": "2023-09-01 new tenancies; 2024-09-01 all tenancies", "verification": "regulator-confirmed (Residential Tenancies Authority)" },
        { "state": "NSW", "regime": "7 minimum standards (fitness for habitation) + mandatory working smoke alarms", "instrument": "Residential Tenancies Act 2010 + Regulation", "applies_from": "ongoing", "verification": "regulator-confirmed (NSW Fair Trading); to_verify — sections not pinpointed" },
        { "state": "SA/WA/TAS/ACT/NT", "regime": "state equivalents apply", "instrument": "per-state residential tenancy law", "applies_from": "to_verify", "verification": "INDICATIVE — to_verify against each state's tenancy authority" }
      ]
    }
  }
}
```

Notes:

- **No `fills`.** No outcome leaf is set; the investor cost adders are resolver-estimated and summed into `cash_position` with the sibling-owned costs. The doc supplies the investor-specific adders, asserting no buyer-specific total.
- **Delta, not a re-band.** The shared inspection/conveyancing/registration ranges are owned by `kb.buyer-costs.inspections-conveyancing-fees`; QS report, entity setup, duty, and landlord insurance by their own anchors. This doc owns only the investor-only adders (minimum-standards compliance, lease review, initial letting flag) — single-owner via cross-ref.
- **Minimum standards: regulated regime, banded cost.** The standards and commencement dates are regulated and per-state (VIC 29 Mar 2021, QLD all-tenancies 1 Sep 2024, NSW ongoing); the *upgrade cost* is banded because it depends on the property's starting condition. SA/WA/TAS/ACT/NT regimes are `to_verify` (row-level verification tier, the same honest-partial move as `kb.tax.land-tax-by-state`).
- **No double-count.** Landlord insurance is a holding cost (operating expenses), flagged here only so it's planned from settlement, not summed into acquisition.

## Sources

**Minimum rental standards (REGULATED — state tenancy authorities):**

- Consumer Affairs Victoria — *Rental properties – minimum standards* (14 standards; agreements on/after 29 March 2021) — https://www.consumer.vic.gov.au/housing/renting/repairs-alterations-safety-and-pets/minimum-standards/minimum-standards-for-rental-properties
- Residential Tenancies Authority (QLD) — *Minimum housing standards* (new tenancies 1 Sept 2023; all tenancies 1 Sept 2024) — https://www.rta.qld.gov.au/during-a-tenancy/maintenance-and-repairs/minimum-housing-standards
- NSW Government — *Minimum standards for rental properties* (7 standards; fitness for habitation) — https://www.nsw.gov.au/housing-and-construction/rules/minimum-standards-for-rental-properties
- NSW Government — *Smoke alarms in a rental property* (mandatory working smoke alarms; landlord-maintained) — https://www.nsw.gov.au/housing-and-construction/rules/smoke-alarms-a-rental-property

**Investor acquisition cost context (CONVENTION / ASIC):**

- ASIC Moneysmart — *Investing in property* (the upfront and ongoing costs of an investment property) — https://moneysmart.gov.au/property-investment/investing-in-property
