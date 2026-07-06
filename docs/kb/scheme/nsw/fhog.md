---
slug: kb.scheme.nsw.fhog
effective_from: 2016-01-01
last_verified: 2026-07-06
sources:
  - url: https://www.nsw.gov.au/housing-and-construction/buying-and-selling-property/home-buying-assistance/first-home-owner-new-home-grant
    retrieved: 2026-07-06
---

# NSW First Home Owner (New Homes) Grant (FHOG)

The **First Home Owner (New Homes) Grant** is a **$10,000 cash grant** for first home buyers who **buy or build a new home** in New South Wales, administered by **Revenue NSW** under the *First Home Owner Grant and Shared Equity Act 2000*. Unlike the [First Home Buyers Assistance Scheme](fhbas.md) (a *duty* concession) it is a **payment to the buyer**, not a reduction in a settlement cost — and the two **stack** for an eligible new home. It is restricted to **new** homes; established dwellings do not qualify.

The grant is **not means tested** and is **not taxable**.

## Eligibility

To claim the grant, the buyer must:

- Be buying or building a **new home** — newly built, purchased **off the plan**, or **substantially renovated** — as a house, townhouse, apartment, unit, or similar. **Established homes do not qualify** (use FHBAS for duty relief on an established home).
- Have **never owned residential property in Australia** (the buyer and spouse/partner). ⚠ This is an **Australia-only** test — a prior home **overseas does not disqualify** — see [Relevance for Vietnamese-Australian buyers](#relevance-for-vietnamese-australian-buyers-mode-a).
- Be a **natural person at least 18 years old** (not a company or trust).
- Have at least one applicant who is an **Australian citizen or permanent resident** (a New Zealand citizen holding a special category visa also qualifies).
- Buy within the **value cap** (see [Grant amount and value cap](#grant-amount-and-value-cap)).
- **Move into the home** within **12 months** of completion/settlement and live there as the principal place of residence for at least **6 continuous months**.

## Grant amount and value cap

The grant is **$10,000**. The value cap depends on whether the home is bought complete or built:

- **Buying a newly built home** (complete) — total value must not exceed **$600,000**.
- **Building a new home** (vacant land + a comprehensive home building contract + any variations done together) — the combined value must not exceed **$750,000**.

Above the applicable cap, no grant is payable.

## Stacking with other support

The grant is independent of the federal schemes and **combines** with an [FHG](../fhg.md)-backed loan and an [FHSS](../fhss.md) deposit withdrawal. It also **combines with the [NSW First Home Buyers Assistance Scheme](fhbas.md)** — an eligible new home under the cap can receive **both** the $10,000 grant and the FHBAS duty exemption/concession, since one is a payment and the other reduces duty. Because the grant is new-homes-only, it pairs naturally with the new-build end of the market.

## Relevance for Vietnamese-Australian buyers (Mode A)

- **Australia-only ownership test — favourable for the diaspora**, the same posture as FHBAS and the federal schemes, and the opposite of the QLD concessions. A prior or current home **in Vietnam** does not block the grant.
- **New-homes-only is the binding constraint.** Much of the affordable diaspora-targeted stock is established; for those purchases the grant is unavailable and only FHBAS duty relief applies. The grant rewards new builds / off-the-plan — which also aligns with what a *foreign person* may buy under FIRB, a useful bridge if a co-buyer's status is uncertain (Mode B/D).
- **Citizenship or PR qualifies** (at least one buyer), so a Vietnamese-Australian PR is eligible.

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This grant fills the `eligibility.fhog.*` slot (distinct from the `state_concession` duty slot). The grant **amount** is a fixed parameter; eligibility is a `criteria` predicate; the cap selection (purchase vs build) is resolver-derived — see Notes.

```jsonc
{
  "fills": [
    { "leaf": "eligibility.fhog.applicable",
      "rule": { "kind": "criteria", "combine": "all_of", "criteria": [
        { "field": "property_fit.state",             "op": "eq",  "value": "NSW" },
        { "field": "applicant.ever_owned_au_property", "op": "eq",  "value": false },            // AU-only test — overseas ownership does NOT disqualify (favourable)
        { "combine": "any_of", "criteria": [                                                     // F4/G2 couple-as-one: a spouse/de-facto partner's prior AU ownership disqualifies even with no legal interest
          { "field": "non_buying_partner.exists",                 "op": "eq", "value": false },   // no partner → gate moot
          { "field": "non_buying_partner.ever_owned_au_property", "op": "eq", "value": false } ] },
        { "field": "applicant.age",                    "op": "gte", "value": 18 },
        { "field": "applicant.citizenship_status",     "op": "in",  "value": ["citizen", "permanent_resident"] },
        { "field": "applicant.owner_occupier_intent",  "op": "eq",  "value": true },             // move in within 12 mo, live 6 continuous mo
        { "field": "property_fit.property_type", "op": "in", "value": ["new_house", "new_apartment", "off_the_plan", "house_and_land"] },  // NEW homes only — established excluded
        { "field": "property_fit.price",             "op": "lte", "value": 750000 } ] } },     // outer bound (build cap); completed-purchase cap is lower ($600k) — see Notes
        // property_fit.* criteria activate in per-property scope; base scope evaluates the profile-only criteria → provisional

    { "leaf": "eligibility.fhog.amount",
      "rule": { "kind": "parameter", "type": "money", "value": 10000 } }
  ],
  "parameters": {
    "value_cap_new_home_purchase":            { "type": "money",   "value": 600000 },          // completed new home
    "value_cap_new_build":                    { "type": "money",   "value": 750000 },          // land + comprehensive building contract + variations
    "means_tested":                           { "type": "bool",    "value": false },
    "taxable":                                { "type": "bool",    "value": false },
    "move_in_window_months_after_settlement": { "type": "integer", "value": 12 },
    "min_continuous_occupancy_months":        { "type": "integer", "value": 6 }
  },
  "stacking": {
    "combines_with": ["kb.scheme.fhg", "kb.scheme.fhss", "kb.scheme.help-to-buy", "kb.scheme.nsw.fhbas"],   // state doc declares federal↔state edges (symmetric, §11.9); the NSW FHOG↔FHBAS edge is declared here (once). Help to Buy explicitly allows stacking FHOG.
    "order_hint": 25   // a grant arranged with finance / paid at settlement — between FHG (20) and the duty concession (30)
  }
}
```

Notes:

- **Cap selection is resolver-derived**: `value_cap_new_home_purchase` ($600k) applies to a completed new-home purchase; `value_cap_new_build` ($750k) applies to a building contract (`property_fit.property_type == house_and_land`). The `applicable` predicate uses $750k as the outer bound and the resolver applies the tighter $600k cap for a completed purchase. Document-supplied numbers, resolver-applied comparison.
- **`amount` is a flat $10,000** — not means tested, not value-scaled (a grant, unlike the duty concessions whose benefit scales with price). It is filled directly; no resolver arithmetic.
- **`ever_owned_au_property` only** — Australia-only test, so `prior_overseas_property_ownership` is deliberately not consulted (the same neutral fact that disqualifies under QLD is not in this predicate).
- **`fhog.applicable` already carries `derived_from: property_fit.property_type`** in the blueprint — the new-homes-only restriction is the substance of that derivation, encoded here as the `property_type in [...new...]` criterion.
- **Spouse ownership history IS now encoded** as a couple-as-one predicate (`non_buying_partner.ever_owned_au_property`, F4/G2). The earlier "no spouse facts on the surface" rationale no longer holds — `non_buying_partner` is now a typed namespace on the resolver-input registry ([`registry-projection.md`](../../architecture/registry-projection.md)), so the "promote to facts when load-bearing" threshold is met. A buyer with no partner declared (`non_buying_partner.exists = false`) passes the gate.

## Sources

- Revenue NSW — *First Home Owner (New Homes) Grant* ($10,000; $600k purchase / $750k build caps; new-homes-only; citizen/PR; not means tested; move-in 12 months, 6 continuous months) — https://www.revenue.nsw.gov.au/grants-schemes/first-home-owner-new-homes-grant
- NSW Government — *First Home Owner (New Home) Grant* — https://www.nsw.gov.au/housing-and-construction/buying-and-selling-property/home-buying-assistance/first-home-owner-new-home-grant
- *First Home Owner Grant and Shared Equity Act 2000 (NSW)* — https://legislation.nsw.gov.au/view/whole/html/inforce/current/act-2000-021
