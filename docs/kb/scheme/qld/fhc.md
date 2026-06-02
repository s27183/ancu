---
slug: kb.scheme.qld.fhc
effective_from: 2024-06-09
last_verified: 2026-06-01
---

# Queensland First Home Concession (FHC)

The **First Home Concession** is a Queensland **transfer (stamp) duty** concession for a first home buyer who buys an **established** home to live in. It is administered by the **Queensland Revenue Office (QRO)**. Like the [First Home (New Home) Concession](fhnhc.md) it reduces a **settlement cost** — the duty otherwise payable on the transfer — but unlike that concession it applies to **existing** dwellings and is **capped by property value**. It sits on top of the general **home concession** (`kb.scheme.qld.home-concession`, to be authored), adding a further first-home reduction.

From **9 June 2024** the concession was expanded: for an eligible first home valued at **$700,000 or under**, the first home concession amount matches the home concession rate so that **no transfer duty is payable**. Between **$700,000 and $800,000** the first-home concession **tapers**, and **above $800,000 the first home concession does not apply** (the general home concession may still apply, but that is not a first-home scheme). The maximum first-home saving is **$24,525**. The change applies to agreements **dated 9 June 2024 or later** — the contract date is the signing date, not settlement.

## Eligibility

To claim the concession, the buyer must:

- Have **never held an interest in another residence anywhere in Australia or overseas.** ⚠ This is a **worldwide** test — see [Relevance for Vietnamese-Australian buyers](#relevance-for-vietnamese-australian-buyers-mode-a); it diverges sharply from the federal schemes' Australia-only tests.
- Be **at least 18 years old** (QRO may allow an exception for a minor only where the transaction is not part of a duty-avoidance scheme).
- **Move into the home** with their personal belongings and live there on a daily basis **within 1 year of settlement** — this period **cannot be extended**.
- Be acquiring the property **as an individual** (not through a company or trust).
- Be buying a home valued **under $800,000** (above this, no first home concession — see [Concession amount](#concession-amount)).

**Citizenship is not required.** A buyer does not have to be an Australian citizen or permanent resident to claim the concession. (A *foreign person* still faces FIRB approval, the established-dwelling ban, and the foreign-buyer duty surcharge separately — but those are Mode B/D concerns; this concession's own eligibility does not test residency.)

## What this concession covers

The First Home Concession applies to an **established home** (an existing dwelling that has been previously occupied or sold as a residence) bought as the buyer's first home. A **new** home — never previously occupied or sold, or substantially renovated — is instead covered by the [First Home (New Home) Concession](fhnhc.md), which reduces duty to **nil with no value cap** and is the better claim for a new build. Buying **vacant land to build** on is covered by the separate **First Home Vacant Land Concession** (`kb.scheme.qld.fh-vacant-land`). A buyer claims **one** of these for a given purchase, determined by what is being bought — see [Stacking](#stacking-with-other-support).

## Concession amount

The first home concession reduces the duty otherwise payable, capped by value:

- **$700,000 or under** — the first home concession brings transfer duty to **nil**.
- **Over $700,000 to $800,000** — a **partial** first home concession applies; the reduction tapers as value rises toward $800,000.
- **Over $800,000** — the first home concession **does not apply**; the general home concession may still reduce duty, but that is a separate (non-first-home) concession.

The maximum first-home saving is **$24,525**. The **dollar saving** for a given purchase is the difference between the duty otherwise payable and the concessional duty — computed from the Queensland transfer-duty rate schedule against the purchase price (resolver arithmetic; see Notes).

## Retention requirements

The concession can be wholly or partly **clawed back** if occupancy/retention conditions are not met:

- **Before moving in** — the buyer must not **sell or transfer** all or part of the property, and must not **lease, rent, or grant exclusive possession** of all or part of it.
- **Within 1 year after moving in** — the buyer must not **lease the whole** property. Leasing **part** is permitted only if the lease arrangement **starts on or after 10 September 2024** and the buyer **continues to live** in the property.
- **Selling or transferring** all or part of the property **within 1 year after moving in** may reduce the entitlement to a **partial concession**.

If a retention condition is breached, the buyer must notify QRO (Form D2.4); QRO reassesses and may charge the unpaid duty plus unpaid-tax interest and penalty tax.

## Stacking with other support

This is a **state duty concession** and is independent of the federal schemes: it can apply alongside an [FHG](../fhg.md)-backed loan and an [FHSS](../fhss.md) deposit withdrawal, which operate through entirely different mechanisms. It is an **alternative to** the other Queensland first-home transfer-duty concessions — the [First Home (New Home) Concession](fhnhc.md) (for new homes) and the **First Home Vacant Land Concession** (`kb.scheme.qld.fh-vacant-land`) — since which one applies is determined by what is being bought. The Queensland **First Home Owner Grant** (a cash grant for new homes) is a separate program with its own rules and is not part of this concession.

## Relevance for Vietnamese-Australian buyers (Mode A)

- **The overseas-ownership test is the key trap, and it reverses the usual diaspora hook.** The federal schemes test only *Australian* property history — a Vietnamese-Australian buyer who once owned a home **in Vietnam** can still qualify for **FHG** and **FHSS**. The Queensland concession tests **"another residence anywhere in Australia or overseas"**, so that *same* prior Vietnamese home **disqualifies** the buyer here. Surface this explicitly so the plan does not over-promise the duty saving.
- **This is the concession most diaspora Mode-A buyers will reach for**, because established dwellings dominate the affordable end of the market and the federal schemes (FHG, FHSS) attach to the loan and deposit rather than the property type. But the **$800,000 value cap** bites in higher-priced suburbs — above it the first-home saving vanishes, so the target price range matters to whether this benefit is real.
- **Citizenship/PR is not required** for the concession, so a PR (or even a temporary resident) is not excluded on residency grounds — but a foreign person still hits FIRB and the foreign-buyer duty surcharge, which can dwarf the concession.

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. The dollar `duty_savings` and the value-banded `concession_type` are **computed** by the resolver from price against the Queensland transfer-duty rate schedule and the thresholds below (not asserted here), so only the eligibility predicate and the scheme name are filled.

```jsonc
{
  "fills": [
    { "leaf": "eligibility.state_concession.applicable",
      "rule": { "kind": "criteria", "combine": "all_of", "criteria": [
        { "field": "property_fit.state",                       "op": "eq",  "value": "QLD" },
        { "field": "profile.ever_owned_au_property",           "op": "eq",  "value": false },
        { "field": "profile.prior_overseas_property_ownership", "op": "eq", "value": false },  // ⚠ QLD tests residences ANYWHERE — diverges from FHG/FHSS (AU-only)
        { "field": "profile.age",                              "op": "gte", "value": 18 },
        { "field": "profile.owner_occupier_intent",            "op": "eq",  "value": true },   // move in within 1 yr of settlement, live daily
        { "field": "property_fit.property_type", "op": "in", "value": ["established_house", "established_apartment"] },  // established branch — disjoint from fhnhc (new) and fh-vacant-land
        { "field": "property_fit.price",                       "op": "lte", "value": 800000 } ] } },
        // property_fit.* criteria activate in per-property scope; base scope evaluates the profile-only criteria → provisional

    { "leaf": "eligibility.state_concession.scheme_name",
      "rule": { "kind": "parameter", "type": "string", "value": "QLD First Home Concession" } }
  ],
  "parameters": {
    "value_cap":                                 { "type": "money",   "value": 800000 },       // no first home concession above this
    "nil_duty_threshold":                        { "type": "money",   "value": 700000 },       // at or under → duty nil; $700k–$800k tapers to partial
    "max_first_home_saving":                     { "type": "money",   "value": 24525 },
    "move_in_window_months_after_settlement":    { "type": "integer", "value": 12 },           // cannot be extended
    "clawback_window_months_after_move_in":      { "type": "integer", "value": 12 },
    "part_lease_allowed_from":                   { "type": "date",    "value": "2024-09-10" },
    "retention_constraints": { "type": "array<string>", "value": [
      "Move into the home within 1 year of settlement and live there daily (cannot be extended)",
      "Do not sell, transfer, lease, or grant exclusive possession of any part before moving in",
      "Within 1 year after moving in, do not lease the whole property (leasing part is allowed only if the lease starts on or after 10 Sep 2024 and you keep living there)",
      "Selling or transferring within 1 year after moving in may reduce the concession to a partial concession",
      "Notify QRO (Form D2.4) if a retention condition is breached — reassessment plus interest and penalty tax may apply"
    ] }
  },
  "stacking": {
    "combines_with": ["kb.scheme.fhg", "kb.scheme.fhss", "kb.scheme.help-to-buy"],   // the state doc declares the federal↔state edges (symmetric, §11.9); the federal docs do not list state concessions. Help to Buy explicitly allows stacking stamp-duty concessions.
    "alternative_to": ["kb.scheme.qld.fhnhc", "kb.scheme.qld.fh-vacant-land"],   // intra-slot exclusivity (all three fill the eligibility state_concession slot) — slug-grained, so expressible; also enforced by disjoint `applicable` criteria (established vs new vs vacant)
    "order_hint": 30
  }
}
```

Notes:

- **`duty_savings`** (the `eligibility.state_concession.duty_savings` leaf) is **not** filled here — it is resolver arithmetic: the difference between full transfer duty and concessional duty on `property_fit.price`, from the Queensland transfer-duty rate schedule ([`kb.stamp-duty.calc-by-state`](../../stamp-duty/calc-by-state.md)), capped at `max_first_home_saving`. Cross-doc orchestration, the same pattern as FHG's `lmi_savings_estimate` and FHNHC's `duty_savings`.
- **`concession_type`** (the `eligibility.state_concession.concession_type` leaf) is likewise **resolver-derived**, not a flat parameter as in FHNHC — it is value-banded: `full_exemption` at or under `nil_duty_threshold` ($700k), `partial_concession` above that up to `value_cap` ($800k), `no_concession` above `value_cap`. The enum cannot be expressed as a `criteria` fill (criteria yield bools), so the resolver assigns it from `property_fit.price` against the two thresholds. Document-supplied numbers, resolver-applied comparison — the "computed, not asserted" line.
- **`prior_overseas_property_ownership` carries opposite verdicts across schemes** — non-disqualifying for `kb.scheme.fhg`/`kb.scheme.fhss`, disqualifying here. This is the fact surface working as intended (the profile holds the neutral fact; each scheme's `criteria` decides). QLD's statutory test is "another **residence**"; our fact is property-level (slightly broader), a conservative approximation — flag if a residence-vs-any-interest distinction ever becomes load-bearing.
- **`order_hint: 30`** (after FHSS 10 and FHG 20) — a duty concession is claimed at **settlement** (self-assessed via the transfer), the latest of the three in the buyer's timeline. Matches FHNHC, since only one of the two ever fills the slot for a given purchase.

## Sources

- Queensland Revenue Office — *First home concession* (eligibility, $800k cap, $700k nil-duty threshold, $24,525 max saving, worldwide prior-ownership test, retention rules, effective 9 June 2024) — https://qro.qld.gov.au/duties/transfer-duty/concessions/homes/first-home/
- Queensland Revenue Office — *Home concession* (the base concession the first-home concession builds on) — https://qro.qld.gov.au/duties/transfer-duty/concessions/homes/home-concession/
- Queensland Revenue Office — *Transfer duty home concession rates* — https://qro.qld.gov.au/duties/transfer-duty/calculate/concession-rates/
- Queensland Government — *Transfer duty (stamp duty) concessions and exemptions* — https://www.qld.gov.au/housing/buying-owning-home/home-buyers-financial-help/transfer-duty
