---
slug: kb.scheme.vic.fhog
effective_from: 2013-07-01
last_verified: 2026-07-06
sources:
  - url: https://www.sro.vic.gov.au/buying-property/first-home-owner-grant
    retrieved: 2026-07-06
---

# Victoria First Home Owner Grant (FHOG)

The **First Home Owner Grant** is a **$10,000 cash payment** for first home buyers who **buy or build a new home** in Victoria, administered by the **State Revenue Office (SRO)** under the *First Home Owner Grant and Home Buyer Schemes Act 2000*. Unlike the [First Home Buyer Duty Exemption/Concession](fhb-duty.md) (a *duty* benefit covering new and established homes) it is a **payment to the buyer** and is restricted to **new** homes; established dwellings do not qualify. The two **stack** for an eligible new home.

The grant is **not means tested** and is **not taxable**. (The former **regional Victorian $20,000** grant **closed on 30 June 2025**; the grant is now **$10,000 statewide**.)

## Eligibility

To claim the grant, the buyer must:

- Be buying or building a **new home** — newly built and **not previously sold, occupied as a home, leased, or used for short-term accommodation** (off-the-plan and substantially renovated qualify). **Established homes do not qualify** (use the [duty exemption/concession](fhb-duty.md) instead).
- Have **never owned residential property in Australia** (the buyer and spouse/partner) and never received the FHOG anywhere in Australia. ⚠ This is an **Australia-only** test — a prior home **overseas does not disqualify** — see [Relevance for Vietnamese-Australian buyers](#relevance-for-vietnamese-australian-buyers-mode-a).
- Be an **Australian citizen or permanent resident**, **aged 18 or over** (a New Zealand citizen also qualifies — from 26 November 2025, whether or not they hold a special category visa).
- Buy a new home with a value **at or under $750,000** (for off-the-plan, the contract price).
- **Live in the home** as the principal place of residence for at least **12 continuous months**, starting **within 12 months** of settlement or completion of construction.

## Grant amount and value cap

The grant is a flat **$10,000**, payable on a new home valued **at or under $750,000**. Above the cap, no grant is payable. The amount does not scale with price.

## Stacking with other support

The grant is independent of the federal schemes and **combines** with an [FHG](../fhg.md)-backed loan and an [FHSS](../fhss.md) deposit withdrawal. For an eligible new home it also **combines with the [Victorian First Home Buyer Duty Exemption/Concession](fhb-duty.md)** — both apply to the same purchase, one as a $10,000 payment and one as a duty reduction. Because the grant is new-homes-only, it pairs with the new-build end of the market.

## Relevance for Vietnamese-Australian buyers (Mode A)

- **Australia-only ownership test — favourable for the diaspora**, like the VIC duty benefit, NSW, and the federal schemes, and the opposite of the QLD concessions. A prior or current home **in Vietnam** does not block the grant.
- **New-homes-only is the binding constraint.** Where the typical Mode A purchase is an established dwelling, the grant is unavailable and only the duty exemption/concession applies. The grant rewards new builds / off-the-plan — which also aligns with what a *foreign person* may buy under FIRB (a bridge if a co-buyer's status is uncertain, Mode B/D).
- **Citizenship or PR qualifies**, so a Vietnamese-Australian PR is eligible.

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This grant fills the `eligibility.fhog.*` slot (distinct from the `state_concession` duty slot). The `amount` is a fixed parameter; eligibility is a `criteria` predicate.

```jsonc
{
  "fills": [
    { "leaf": "eligibility.fhog.applicable",
      "rule": { "kind": "criteria", "combine": "all_of", "criteria": [
        { "field": "property_fit.state",             "op": "eq",  "value": "VIC" },
        { "field": "applicant.ever_owned_au_property", "op": "eq",  "value": false },            // AU-only test — overseas ownership does NOT disqualify (favourable)
        { "combine": "any_of", "criteria": [                                                     // F4/G2 couple-as-one: a spouse/de-facto partner's prior AU ownership disqualifies even with no legal interest
          { "field": "non_buying_partner.exists",                 "op": "eq", "value": false },   // no partner → gate moot
          { "field": "non_buying_partner.ever_owned_au_property", "op": "eq", "value": false } ] },
        { "field": "applicant.age",                    "op": "gte", "value": 18 },
        { "field": "applicant.citizenship_status",     "op": "in",  "value": ["citizen", "permanent_resident"] },
        { "field": "applicant.owner_occupier_intent",  "op": "eq",  "value": true },             // live 12 continuous months, starting within 12 months
        { "field": "property_fit.property_type", "op": "in", "value": ["new_house", "new_apartment", "off_the_plan", "house_and_land"] },  // NEW homes only — established excluded
        { "field": "property_fit.price",             "op": "lte", "value": 750000 } ] } },
        // property_fit.* criteria activate in per-property scope; base scope evaluates the profile-only criteria → provisional

    { "leaf": "eligibility.fhog.amount",
      "rule": { "kind": "parameter", "type": "money", "value": 10000 } }
  ],
  "parameters": {
    "value_cap":                              { "type": "money",   "value": 750000 },          // new home (off-the-plan: contract price)
    "means_tested":                           { "type": "bool",    "value": false },
    "taxable":                                { "type": "bool",    "value": false },
    "move_in_window_months_after_settlement": { "type": "integer", "value": 12 },
    "min_continuous_occupancy_months":        { "type": "integer", "value": 12 },              // VIC requires 12 continuous months (cf. NSW 6)
    "regional_grant_closed":                  { "type": "date",    "value": "2025-06-30" }     // former regional $20k grant ended; now $10k statewide
  },
  "stacking": {
    "combines_with": ["kb.scheme.fhg", "kb.scheme.fhss", "kb.scheme.help-to-buy", "kb.scheme.vic.fhb-duty"],   // state doc declares federal↔state edges (symmetric, §11.9); the VIC FHOG↔duty edge is declared here (once). Help to Buy explicitly allows stacking FHOG.
    "order_hint": 25   // a grant arranged with finance / paid at settlement — between FHG (20) and the duty concession (30)
  }
}
```

Notes:

- **`amount` is a flat $10,000** — not means tested, not value-scaled (a grant, unlike the duty benefit whose value scales with price). Filled directly; no resolver arithmetic.
- **`ever_owned_au_property` only** — Australia-only test, so `prior_overseas_property_ownership` is deliberately not consulted.
- **`fhog.applicable` carries `derived_from: property_fit.property_type`** in the blueprint — the new-homes-only restriction is the substance of that derivation, encoded here as the `property_type in [...new...]` criterion.
- **The regional $20,000 grant is closed** (`regional_grant_closed: 2025-06-30`); only the $10,000 statewide grant applies now. Recorded as a parameter so the resolver/agent does not surface the lapsed higher regional figure.
- **Spouse OWNERSHIP history IS now encoded** (`non_buying_partner.ever_owned_au_property`, F4/G2) — `non_buying_partner` is now a typed namespace on the resolver-input registry ([`registry-projection.md`](../../architecture/registry-projection.md)), so the "promote to facts when load-bearing" threshold is met (a buyer with no partner, `non_buying_partner.exists = false`, passes). **Prior-FHOG-receipt** (buyer or spouse) is still **not** encoded (no backing fact); rare for a fresh Mode A FHB, documented rather than dangled.

## Sources

- State Revenue Office Victoria — *First Home Owner Grant* ($10,000; new-homes-only; $750k cap; citizen/PR aged 18+; Australia-only prior-ownership; 12 continuous months; NZ-citizen rule change 26 Nov 2025; regional $20k closed 30 Jun 2025) — https://www.sro.vic.gov.au/buying-property/first-home-owner-grant
- State Revenue Office Victoria — *Will I be eligible for the First Home Owner Grant?* — https://www.sro.vic.gov.au/buying-property/first-home-owner-grant/will-i-be-eligible-first-home-owner-grant
- State Revenue Office Victoria — *Regional First Home Owner Grant* (closed 30 June 2025) — https://www.sro.vic.gov.au/about-us/our-organisation/closed-taxes-levies-and-grants/regional-first-home-owner-grant
