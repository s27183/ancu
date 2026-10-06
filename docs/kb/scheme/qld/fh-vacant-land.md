---
slug: kb.scheme.qld.fh-vacant-land
effective_from: 2025-05-01
last_verified: 2026-07-06
sources:
  - url: https://qro.qld.gov.au/duties/transfer-duty/concessions/homes/first-home-vacant-land/
    retrieved: 2026-07-06
---

# Queensland First Home Vacant Land Concession

The **First Home Vacant Land Concession** is a Queensland **transfer (stamp) duty** concession for a first home buyer who buys **vacant land to build their first home on**. It is administered by the **Queensland Revenue Office (QRO)**. Like the [First Home Concession](fhc.md) (established homes) and the [First Home (New Home) Concession](fhnhc.md) (new homes) it reduces a **settlement cost** — the duty otherwise payable on the transfer — but it applies to a purchase of **land only**, where no dwelling exists yet and the buyer undertakes to build.

From **1 May 2025** the concession was overhauled in step with the new-home concession: for eligible vacant land it reduces transfer duty to **nil with no value cap**. This replaced the older capped concession (9 June 2024 – 30 April 2025: nil at $350,000 or under, tapering to no concession at $500,000 or more, maximum saving $10,675). The change applies to contracts **dated 1 May 2025 or later** — the contract date is the signing date, not settlement.

## Eligibility

To claim the concession, the buyer must:

- Have **never held an interest in a residence anywhere in Australia or overseas.** ⚠ This is a **worldwide** test — see [Relevance for Vietnamese-Australian buyers](#relevance-for-vietnamese-australian-buyers-mode-a); it diverges sharply from the federal schemes' Australia-only tests.
- Have **never previously claimed the first home vacant land concession** on another property.
- Be **at least 18 years old** (QRO may allow an exception for a minor only where the transaction is not part of a duty-avoidance scheme).
- **Build the first home on the land, move in** with their personal belongings, and live there on a daily basis **within 2 years of settlement** — this period **cannot be extended**, and **only one home** may be built on the land.
- Be acquiring the property **as an individual** (not through a company or trust) and **paying market value**.

**Citizenship is not required.** A buyer does not have to be an Australian citizen or permanent resident to claim the concession. (A *foreign person* still faces FIRB approval, the foreign-buyer duty surcharge, and — for residential land — the FIRB permitted-purchase rules separately; those are Mode B/D concerns, and this concession's own eligibility does not test residency.)

## What this concession covers

This concession applies to a purchase of **vacant residential land** that the buyer will **build their first home on**. It is distinct from a **house-and-land package**, where land and a new build are acquired together under a bundled contract — that is a **new home** purchase covered by the [First Home (New Home) Concession](fhnhc.md). The split matters for which scheme applies: land-only (buyer builds separately, 2-year window) → this concession; bundled package → FHNHC. An **established** or **new** home with a dwelling already on it is covered by the [First Home Concession](fhc.md) / FHNHC respectively. A buyer claims **one** of the three for a given purchase, determined by what is being bought — see [Stacking](#stacking-with-other-support).

## Concession amount

For eligible vacant land with a contract dated 1 May 2025 or later, the concession reduces transfer duty to **nil**, and **there is no value cap**. The **dollar saving** is the full transfer duty that would otherwise be payable — computed from the Queensland transfer-duty rate schedule against the purchase price (resolver arithmetic; see Notes).

## Retention requirements

The concession can be wholly or partly **clawed back** if the build/occupancy/retention conditions are not met:

- **Before moving in** — the buyer must not **sell or transfer** all or part of the property, and must not **lease, rent, or grant exclusive possession** of all or part of it.
- **Within 1 year after moving in** — the buyer must not **lease the whole** property. Leasing **part** is permitted only if the lease arrangement **starts on or after 10 September 2024** and the buyer **continues to live** in the property.
- **Selling or transferring** all or part of the property **within 1 year after moving in** may reduce the entitlement to a **partial concession**.

If a condition is breached (including failing to build and move in within 2 years), the buyer must notify QRO (Form D2.4); QRO reassesses and may charge the unpaid duty plus unpaid-tax interest and penalty tax.

## Stacking with other support

This is a **state duty concession** and is independent of the federal schemes: it can apply alongside an [FHG](../fhg.md)-backed loan and an [FHSS](../fhss.md) deposit withdrawal, which operate through entirely different mechanisms. It is an **alternative to** the other Queensland first-home transfer-duty concessions — the [First Home Concession](fhc.md) (established homes) and the [First Home (New Home) Concession](fhnhc.md) (new homes) — since which one applies is determined by what is being bought. The Queensland **First Home Owner Grant** (a cash grant for new builds) is a separate program with its own rules and is not part of this concession.

## Relevance for Vietnamese-Australian buyers (Mode A)

- **The overseas-ownership test is the key trap, and it reverses the usual diaspora hook** — identical to `kb.scheme.qld.fhc` / `kb.scheme.qld.fhnhc`. The federal schemes test only *Australian* property history, so a Vietnamese-Australian buyer who once owned a home **in Vietnam** can still qualify for **FHG** and **FHSS**; this concession tests **"a residence anywhere in Australia or overseas"**, so that same prior Vietnamese home **disqualifies** the buyer here. Surface this explicitly so the plan does not over-promise the duty saving.
- **Building on vacant land near Vietnamese-community hubs is a real diaspora path** — land releases on the growth fringe of Brisbane/Logan/Ipswich are where affordable house-and-land and land-only purchases concentrate. The **2-year build-and-move-in window** (not 1 year as for the established/new concessions) is the load-bearing difference: a buyer who buys land but does not build and occupy in time loses the concession and faces reassessment.
- **Citizenship/PR is not required**, so a PR (or temporary resident) is not excluded on residency grounds — but a foreign person still hits FIRB (residential vacant land carries its own FIRB rules) and the foreign-buyer duty surcharge, which can dwarf the concession.

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. The dollar `duty_savings` is **computed** by the resolver from the Queensland transfer-duty rate schedule (not asserted here), so only the eligibility predicate, the concession type, and the retention parameters are filled.

```jsonc
{
  "fills": [
    { "leaf": "eligibility.state_concession.applicable",
      "rule": { "kind": "criteria", "combine": "all_of", "criteria": [
        { "field": "property_fit.state",                       "op": "eq",  "value": "QLD" },
        { "field": "applicant.ever_owned_au_property",           "op": "eq",  "value": false },
        { "field": "applicant.prior_overseas_property_ownership", "op": "eq", "value": false },  // ⚠ QLD tests residences ANYWHERE — diverges from FHG/FHSS (AU-only)
        { "field": "applicant.age",                              "op": "gte", "value": 18 },
        { "field": "applicant.owner_occupier_intent",            "op": "eq",  "value": true },   // build + move in within 2 yrs of settlement, live daily
        { "field": "property_fit.property_type",                 "op": "eq",  "value": "vacant_land" } ] } },
        // vacant-land branch — disjoint from fhc (established) and fhnhc (new + house_and_land package).
        // property_fit.* criteria activate in per-property scope; base scope evaluates the profile-only criteria → provisional

    { "leaf": "eligibility.state_concession.scheme_name",
      "rule": { "kind": "parameter", "type": "string", "value": "QLD First Home Vacant Land Concession" } },

    { "leaf": "eligibility.state_concession.concession_type",
      "rule": { "kind": "parameter", "type": "enum", "value": "full_exemption" } }  // duty → nil, no value cap (contract dated 1 May 2025+)
  ],
  "parameters": {
    "value_cap":                                 { "type": "money",   "value": null },        // no cap since 1 May 2025
    "build_and_move_in_window_months_after_settlement": { "type": "integer", "value": 24 },   // 2 years — cannot be extended; DISTINCT from fhc/fhnhc (12)
    "dwellings_permitted":                       { "type": "integer", "value": 1 },           // only one home may be built on the land
    "clawback_window_months_after_move_in":      { "type": "integer", "value": 12 },
    "part_lease_allowed_from":                   { "type": "date",    "value": "2024-09-10" },
    "retention_constraints": { "type": "array<string>", "value": [
      "Build your first home and move in within 2 years of settlement, living there daily (cannot be extended)",
      "Build only one home on the land",
      "Do not sell, transfer, lease, or grant exclusive possession of any part before moving in",
      "Within 1 year after moving in, do not lease the whole property (leasing part is allowed only if the lease starts on or after 10 Sep 2024 and you keep living there)",
      "Selling or transferring within 1 year after moving in may reduce the concession to a partial concession",
      "Notify QRO (Form D2.4) if a condition is breached — reassessment plus interest and penalty tax may apply"
    ] }
  },
  "stacking": {
    "combines_with": ["kb.scheme.fhg", "kb.scheme.fhss", "kb.scheme.help-to-buy"],   // the state doc declares the federal↔state edges (symmetric, §11.9); the federal docs do not list state concessions. Help to Buy explicitly allows stacking stamp-duty concessions.
    "alternative_to": ["kb.scheme.qld.fhc", "kb.scheme.qld.fhnhc"],   // intra-slot exclusivity (all three fill the eligibility state_concession slot) — slug-grained, so expressible; also enforced by disjoint `applicable` criteria (vacant vs established vs new). The symmetric edge: fhc/fhnhc already declare this slug.
    "order_hint": 30
  }
}
```

Notes:

- **`duty_savings`** (the `eligibility.state_concession.duty_savings` leaf) is **not** filled here — it is resolver arithmetic: the full transfer duty otherwise payable on `property_fit.price`, from the Queensland transfer-duty rate schedule ([`kb.stamp-duty.calc-by-state`](../../stamp-duty/calc-by-state.md)). Cross-doc orchestration, the same pattern as FHNHC's `duty_savings` and FHG's `lmi_savings_estimate`.
- **`concession_type` is a flat `full_exemption` parameter** (not resolver-banded as in FHC/FHBAS) — since 1 May 2025 the concession is nil with no value cap, so there is no value band to select against. This matches FHNHC.
- **`value_cap: null`** encodes "no cap" since 1 May 2025; the resolver treats null as no upper bound. The prior capped regime ($350k nil / $500k cut-off, max $10,675) applied only to contracts dated 9 Jun 2024 – 30 Apr 2025 and is out of scope for a current Wedge-1 buyer.
- **The 2-year build-and-move-in window is the distinguishing parameter** from FHC/FHNHC (both 12 months). It exists because the buyer must construct the dwelling before occupying — modelled as `build_and_move_in_window_months_after_settlement: 24`, separate from the `clawback_window_months_after_move_in` (12) that runs from move-in.
- **"Never previously claimed the first home vacant land concession"** is the scheme's own first-claim test. As with FHNHC's "never claimed the vacant-land concession" edge case, the *historical-claim* case (a buyer who claimed it on an earlier purchase) is **not** encoded as a hard predicate — it would need a `profile.prior_qld_fh_vacant_land_concession` fact not on the surface, and it is rare for a fresh Mode A first-home buyer. Documented here rather than dangling an unbacked reference; promote to a fact only if it proves load-bearing.
- **`prior_overseas_property_ownership` carries opposite verdicts across schemes** — non-disqualifying for `kb.scheme.fhg`/`kb.scheme.fhss`, disqualifying here (and in FHC/FHNHC). The fact surface working as intended: the profile holds the neutral fact; each scheme's `criteria` decides. QLD's statutory test is "a **residence**"; our fact is property-level (slightly broader), a conservative approximation — flag if a residence-vs-any-interest distinction ever becomes load-bearing.
- **`order_hint: 30`** (after FHSS 10 and FHG 20) — a duty concession is claimed at **settlement** (self-assessed via the transfer), the latest of the three in the buyer's timeline. Matches FHC/FHNHC, since only one of the three ever fills the slot for a given purchase.

## Sources

- Queensland Revenue Office — *First home vacant land concession* (eligibility, worldwide prior-ownership test, nil duty / no value cap from 1 May 2025, 2-year build-and-move-in window, single-dwelling rule, retention rules; prior $350k/$500k/$10,675 regime for 9 Jun 2024 – 30 Apr 2025) — https://qro.qld.gov.au/duties/transfer-duty/concessions/homes/first-home-vacant-land/
- Queensland Revenue Office — *Changes to transfer duty from 1 May 2025* — https://qro.qld.gov.au/webinar/changes-from-1-may/
- Queensland Revenue Office — *Transfer duty rates* (the rate schedule the dollar saving is computed against) — https://qro.qld.gov.au/duties/transfer-duty/calculate/rates/
