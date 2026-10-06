---
slug: kb.buyer-costs.inspections-conveyancing-fees
effective_from: 2025-07-01
last_verified: 2026-07-06
sources:
  - url: https://moneysmart.gov.au/home-loans/buying-a-house
    retrieved: 2026-07-06
  - url: https://www.canstar.com.au/home-loans/building-inspection-cost/
    retrieved: 2026-07-06
  - url: https://whichrealestateagent.com.au/agent-fees/how-much-do-real-estate-agents-charge/
    retrieved: 2026-07-06
---

# Buyer-side transaction costs — inspections, conveyancing, and registration fees

Beyond the deposit, [stamp duty](../stamp-duty/calc-by-state.md), and [LMI](../lmi/calculation.md), a buyer faces a cluster of smaller transaction costs at settlement — building & pest inspection, conveyancing, the lender's application fee, the state land-titles registration fees, first-year building insurance, utility connections, and moving. Individually modest, together they typically add **a few thousand dollars** to the cash needed at settlement. This doc owns the **typical ranges and the regulated per-state registration fees** that ground every `other_buying_costs` line in `cash_position`. It deliberately separates three kinds of figure — **regulated** (state-set, exact), **lender-policy** (varies, drifts), and **convention** (market ranges, not fixed) — because they age differently and the agent must present them differently.

## The regulated costs — land-titles registration fees (per state)

When the buyer takes title and the lender registers its mortgage, the state land-titles registry charges fixed fees. These are **statutory, set per state, and indexed annually (1 July)**. They are the one **exact** part of this doc.

| State | Transfer registration | Mortgage registration | Notes |
|---|---|---|---|
| **NSW** (FY2025–26) | **$175.70** (flat, incl GST) | **$175.70** (flat, incl GST) | NSW LRS dealing fee — flat per dealing, does **not** scale with price |
| **VIC** (FY2025–26, electronic) | **$101.50 + $2.34 per whole $1,000** of consideration, **max $3,611** | **$125.70** | Land Use Victoria, electronic (PEXA) lodgement; paper lodgement is a few dollars higher |
| **QLD** (FY2026–27, eff 1 Jul 2026) | **$248.04 + $46.56 per $10,000** (or part) **over $180,000** | **$248.04** | Titles Queensland; transfer = base lodgement + value-based component |

**Worked anchors:** NSW is **$175.70 + $175.70 = $351.40** at any price. A **VIC $700,000** purchase: transfer $101.50 + $2.34 × 700 = **$1,739.50**, plus mortgage $125.70. A **QLD $600,000** purchase: transfer $248.04 + $46.56 × 42 = **$2,203.56** (42 = ($600,000 − $180,000) ÷ $10,000), plus mortgage $248.04.

## The lender-policy cost — loan application / establishment fee

Lenders charge an **application / establishment / settlement fee**, typically **$0 to ~$800**. Many lenders **waive** it (especially for owner-occupier or package products), so it is genuinely variable and **lender-specific** — the agent presents a range and notes it is often waived, never a fixed figure or a steer to a particular lender (ASIC: no credit advice).

## The convention costs — market ranges, not fixed amounts

These are **typical market ranges**, not regulated or quoted figures — they vary by provider, property, and location. The resolver uses them for a base-scope estimate; the actual figures come from the buyer's own quotes.

- **Building & pest inspection** — typically **$400–$800** combined; capital-city metro (esp. Sydney) often **$700–$1,000**; older/larger/difficult-access properties higher. Skippable on a new build or strata apartment (the body corporate covers the structure), which the agent should flag.
- **Conveyancing / legal** — **$800–$2,500** all-in (professional fee + disbursements such as title searches and certificates); licensed conveyancer at the lower end, solicitor higher; NSW metro tends highest.
- **First-year building insurance** — **$1,000–$3,000** for a **house** (lenders require cover from settlement). For a **strata** apartment/townhouse, building insurance sits in the **body-corporate levies**, not a separate settlement cost — that lives in `kb.ongoing-costs.rates-water-strata` (component 9). So this line is **near-zero for strata** (contents only) — don't double-count.
- **Utility connections** — **$100–$500** (electricity, gas, water, internet establishment).
- **Moving costs** — **$300–$2,000** depending on distance, volume, and whether professional removalists are used.

## Relevance for Vietnamese-Australian buyers (Mode A)

- **These are the "hidden" costs that surprise first home buyers** — the deposit and stamp duty dominate the conversation, but the cluster above can be **$3,000–$8,000** that a first-timer hasn't budgeted. Surfacing them explicitly in the cash calculator is exactly the planning value, and several are **avoidable or reducible** (skip the building inspection on a new build; shop conveyancing; many lenders waive the application fee) — presented as information, the buyer decides.
- **State choice shifts the registration fees too** — small next to duty, but the per-state structure (NSW flat, VIC/QLD value-scaled) compounds the duty difference when comparing target states.
- **Information, not advice.** Ranges and the regulated fees are shown transparently with assumptions; the doc does not recommend a specific conveyancer, inspector, insurer, or lender.

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This is a **reference doc** — it fills no slot. The `cash_position.other_buying_costs.*` leaves are **resolver-estimated** from these ranges and the per-state registration lookup; the binding figures are the buyer's own quotes and the registry fee at lodgement.

```jsonc
{
  "fills": [],
  "parameters": {
    "lender_application_fee_low":           { "type": "money", "value": 0,    "note": "LENDER POLICY — application/establishment/settlement fee; frequently waived, so the low end is $0; lender-specific, present as a range" },
    "lender_application_fee_high":          { "type": "money", "value": 800,  "note": "LENDER POLICY — typical upper end; varies by lender and product" },
    "building_pest_inspection_low":         { "type": "money", "value": 400,  "note": "CONVENTION — typical combined building+pest; lower end / regional" },
    "building_pest_inspection_high":        { "type": "money", "value": 1000, "note": "CONVENTION — capital-city metro / older / difficult-access upper end; skippable on new build or strata" },
    "conveyancing_low":                     { "type": "money", "value": 800,  "note": "CONVENTION — licensed conveyancer, all-in incl disbursements, lower end" },
    "conveyancing_high":                    { "type": "money", "value": 2500, "note": "CONVENTION — solicitor / complex transaction / NSW metro upper end" },
    "first_year_building_insurance_low":    { "type": "money", "value": 1000, "note": "CONVENTION — house; near-zero for strata (building cover is in body-corporate levies — see kb.ongoing-costs.rates-water-strata; don't double-count)" },
    "first_year_building_insurance_high":   { "type": "money", "value": 3000, "note": "CONVENTION — house, upper end" },
    "utility_connections_low":              { "type": "money", "value": 100,  "note": "CONVENTION — electricity/gas/water/internet establishment, lower end" },
    "utility_connections_high":             { "type": "money", "value": 500,  "note": "CONVENTION — upper end" },
    "moving_costs_low":                     { "type": "money", "value": 300,  "note": "CONVENTION — short local move, minimal volume" },
    "moving_costs_high":                    { "type": "money", "value": 2000, "note": "CONVENTION — professional removalists, distance/volume, upper end" },
    "registration_fees_indexed_annually":   { "type": "bool",  "value": true, "note": "REGULATED — state land-titles registration fees are reset each 1 July; figures in the lookup are FY-stamped, re-verify annually (drives last_verified)" }
  },
  "lookup": {
    "state_registration_fees": {
      "note": "REGULATED — statutory land-titles registration fees, per state. NSW is flat; VIC and QLD add a value-based component to a base. FY stamped per state (NSW/VIC FY2025-26; QLD FY2026-27 effective 1 Jul 2026). Resolver computes the transfer fee per state's formula.",
      "entries": [
        { "state": "NSW", "fy": "2025-26", "gst_inclusive": true,
          "transfer_registration_flat": 175.70,
          "mortgage_registration_flat": 175.70,
          "transfer_scales_with_value": false,
          "note": "NSW LRS dealing fee — flat $175.70 incl GST per dealing, independent of price" },
        { "state": "VIC", "fy": "2025-26", "basis": "electronic_pexa_lodgement",
          "transfer_registration_base": 101.50,
          "transfer_registration_per_1000_consideration": 2.34,
          "transfer_registration_max": 3611,
          "mortgage_registration_flat": 125.70,
          "transfer_scales_with_value": true,
          "note": "Land Use Victoria; transfer = 101.50 + 2.34 per whole $1,000 of consideration, capped $3,611 (electronic). Paper lodgement ~$10 higher" },
        { "state": "QLD", "fy": "2026-27", "effective_from": "2026-07-01",
          "transfer_lodgement_base": 248.04,
          "transfer_additional_per_10000_over_threshold": 46.56,
          "transfer_additional_threshold": 180000,
          "mortgage_registration_flat": 248.04,
          "transfer_scales_with_value": true,
          "note": "Titles Queensland; transfer = 248.04 + 46.56 per $10,000 (or part) of consideration over $180,000; mortgage = standard instrument lodgement 248.04" }
      ]
    }
  }
}
```

Notes:

- **No `fills`.** No outcome leaf is set. Each `cash_position.other_buying_costs.*` line is a resolver estimate from these figures; the doc supplies the ranges and the regulated per-state fees, asserting no buyer-specific total.
- **Three provenance tiers, deliberately separated.** The per-state registration fees are **REGULATED** (statutory, exact, indexed annually — the one part the agent can state as fact); `lender_application_fee_*` is **LENDER POLICY** (varies, often waived — present as a range, never a steer); the inspection/conveyancing/insurance/utility/moving ranges are **CONVENTION** (market typical, not fixed — the buyer's quotes bind). Same tagging discipline as the [lender-treatment docs](../lender/credit-card-treatment.md).
- **Registration-fee FY mismatch is intentional and stamped.** NSW and VIC figures are FY2025–26 (in force now); QLD is FY2026–27 (effective 1 Jul 2026, the schedule supplied). Each entry carries its `fy`/`effective_from`, and `registration_fees_indexed_annually` flags that all three reset each July — re-verify at the next indexation.
- **Strata vs house insurance — don't double-count.** First-year building insurance is a house cost; for strata, building cover is inside the body-corporate levy owned by `kb.ongoing-costs.rates-water-strata`. The low end is the house figure; the resolver zeroes this line for strata. Single-owner discipline keeps the strata levy in the ongoing-costs doc.
- **NSW registration is GST-inclusive; VIC/QLD figures are the fee payable.** NSW LRS (a privatised registry) charges GST, so $175.70 is the incl-GST amount the buyer pays. The figure the calculator shows is in each case the amount payable.

## Sources

**Registry fees (REGULATED — confirmed against primary documents in `docs/sources/`):**

- NSW Land Registry Services — *2025/26 Fees Update* (Transfer pursuant to s46 RPA and Mortgage each $160.19 excl / $175.70 incl GST, from 1 July 2025) — announcement https://www.nswlrs.com.au/about-us/announcements/new-regulated-customer-fees-1-july-2025/ ; official schedule https://nswlrs.com.au/assets/f/1129775276948026/d3060f1be0/2025-2026-nsw-lrs-fees-update.pdf (primary: `docs/sources/nsw/2025-2026-nsw-lrs-fees-update-final-1.pdf`)
- Land Use Victoria — *Guide to Transfer of Land Act fees 2025–26* (Transfer on sale s45 electronic: 101.50 + 2.34 per whole $1,000, max 3,611; Mortgage or charge s74 electronic: 125.70) — https://www.land.vic.gov.au/land-registration/fees-guides-and-forms/2025-26-fees (primary: `docs/sources/vic/Guide-to-TLA-fees-2025-2026.docx`)
- Titles Queensland — *FY2026/27 Fees* (Land Title Act 1994: lodging a transfer of ownership for 1 lot $248.04; additional $46.56 per $10,000 or part over $180,000 consideration; any other instrument (e.g. mortgage) $248.04) — https://www.titlesqld.com.au/fees-payments/ (primary: `docs/sources/qld/Titles-Registry-Fees_FY-2026-to-2027.pdf`)

**Inspection / conveyancing cost ranges (CONVENTION — market surveys; no regulator publishes these dollar ranges; ASIC Moneysmart confirms the cost categories):**

- ASIC Moneysmart — *Buying a house* (canonical confirmation of the upfront cost categories: conveyancer/solicitor contract review, building & pest inspection, stamp duty) — https://moneysmart.gov.au/home-loans/buying-a-house
- Canstar — *How much does a building inspection cost?* (indicative — combined building & pest typically $400–$800, metro higher) — https://www.canstar.com.au/home-loans/building-inspection-cost/
- which real estate agent — *Conveyancing costs — fees by state 2026* (indicative — $800–$2,500 typical; conveyancer vs solicitor) — https://whichrealestateagent.com.au/agent-fees/conveyancing-costs/
