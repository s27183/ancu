---
slug: kb.scheme.qld.fhnhc
effective_from: 2025-05-01
last_verified: 2026-05-31
---

# Queensland First Home (New Home) Concession (FHNHC)

The **First Home (New Home) Concession** is a Queensland **transfer (stamp) duty** concession for a first home buyer who buys or builds a **new** home to live in. It is administered by the **Queensland Revenue Office (QRO)**. Unlike the federal [First Home Guarantee](../fhg.md) (a loan guarantee) and [First Home Super Saver](../fhss.md) (a savings vehicle), this concession reduces a **settlement cost** — the duty otherwise payable on the property transfer.

From **1 May 2025** the concession was overhauled: for an eligible new-home purchase it reduces transfer duty to **nil with no value cap**. This replaced the older capped concession (which tapered out above a threshold). The change applies to contracts **dated 1 May 2025 or later** — the contract date is the signing date, not settlement.

## Eligibility

To claim the concession, the buyer must:

- Have **never held an interest in another residence anywhere in Australia or overseas.** ⚠ This is a **worldwide** test — see [Relevance for Vietnamese-Australian buyers](#relevance-for-vietnamese-australian-buyers-mode-a); it diverges sharply from the federal schemes' Australia-only tests.
- Be **at least 18 years old** (QRO may allow an exception for a minor only where the transaction is not part of a duty-avoidance scheme).
- **Move into the home** with their personal belongings and live there on a daily basis **within 1 year of settlement** — this period **cannot be extended**.
- Have **never previously claimed the first home vacant land concession**.
- Be acquiring the property **as an individual** (not through a company or trust).

**Citizenship is not required.** A buyer does not have to be an Australian citizen or permanent resident to claim the concession. (A *foreign person* still faces FIRB approval, the established-dwelling ban, and the foreign-buyer duty surcharge separately — but those are Mode B/D concerns; this concession's own eligibility does not test residency.)

## What counts as a "new home"

A **new home** is one that:

- **has not been previously occupied or sold** as a place of residence; **or**
- is a **substantially renovated home** — where the sale is a taxable supply under the GST Act and the home, as renovated, has not been previously occupied or sold as a place of residence.

Buying **vacant land to build** on is covered by the separate **First Home Vacant Land Concession** (`kb.scheme.qld.fh-vacant-land`), which is an alternative to this one — a buyer claims one or the other for a given purchase, not both.

## Concession amount

For an eligible new-home purchase with a contract dated 1 May 2025 or later, the concession reduces transfer duty to **nil**, and **there is no value cap** on the home and the residential land attributed to it. Where a property includes non-residential land, duty still applies to the **non-residential portion** only.

The **dollar saving** is the full transfer duty that would otherwise be payable — computed from the Queensland transfer-duty rate schedule against the purchase price (resolver arithmetic; see Notes). QRO illustrates the saving as around **$9,096** on a median-priced Queensland house-and-land package — illustrative only; the actual saving scales with price.

## Retention requirements

The concession can be wholly or partly **clawed back** if occupancy/retention conditions are not met:

- **Before moving in** — the buyer must not **sell or transfer** all or part of the property, and must not **lease, rent, or grant exclusive possession** of all or part of it.
- **Within 1 year after moving in** — the buyer must not **lease the whole** property. Leasing **part** is permitted only if the lease arrangement **starts on or after 10 September 2024** and the buyer **continues to live** in the property.
- **Selling or transferring** all or part of the property **within 1 year after moving in** may reduce the entitlement to a **partial concession**.

If a retention condition is breached, the buyer must notify QRO (Form D2.4); QRO reassesses and may charge the unpaid duty plus unpaid-tax interest and penalty tax.

## Stacking with other support

This is a **state duty concession** and is independent of the federal schemes: it can apply alongside an **FHG**-backed loan and an **FHSS** deposit withdrawal, which operate through entirely different mechanisms. It is an **alternative to** the other Queensland first-home transfer-duty concessions — the **First Home Concession** (`kb.scheme.qld.fhc`, for established homes) and the **First Home Vacant Land Concession** (`kb.scheme.qld.fh-vacant-land`) — since which one applies is determined by what is being bought. The Queensland **First Home Owner Grant** (a cash grant for new homes) is a separate program with its own rules and is not part of this concession.

## Relevance for Vietnamese-Australian buyers (Mode A)

- **The overseas-ownership test is the key trap, and it reverses the usual diaspora hook.** The federal schemes test only *Australian* property history — a Vietnamese-Australian buyer who once owned a home **in Vietnam** can still qualify for **FHG** and **FHSS**. The Queensland concession tests **"another residence anywhere in Australia or overseas"**, so that *same* prior Vietnamese home **disqualifies** the buyer here. A diaspora buyer can therefore be eligible for the federal guarantee yet not for the Queensland duty concession — surface this explicitly so the plan does not over-promise the duty saving.
- **Citizenship/PR is not required** for the concession, so a PR (or even a temporary resident) is not excluded on residency grounds — but a foreign person still hits FIRB and the foreign-buyer duty surcharge, which can dwarf the concession.
- The concession rewards buying **new** (new build, off-the-plan, substantially renovated) — which also aligns with what a *foreign person* is permitted to buy under FIRB, a useful bridge if the buyer's status is uncertain.

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. The dollar `duty_savings` is **computed** by the resolver from the Queensland transfer-duty rate schedule (not asserted here), so only the eligibility predicate, the concession type, and the retention parameters are filled.

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
        { "field": "property_fit.property_type", "op": "in", "value": ["new_house", "new_apartment", "off_the_plan", "house_and_land"] } ] } },
        // property_fit.* criteria activate in per-property scope; base scope evaluates the profile-only criteria → provisional

    { "leaf": "eligibility.state_concession.scheme_name",
      "rule": { "kind": "parameter", "type": "string", "value": "QLD First Home (New Home) Concession" } },

    { "leaf": "eligibility.state_concession.concession_type",
      "rule": { "kind": "parameter", "type": "enum", "value": "full_exemption" } }  // duty → nil, no value cap (contract dated 1 May 2025+)
  ],
  "parameters": {
    "value_cap":                                 { "type": "money",   "value": null },        // no cap since 1 May 2025
    "move_in_window_months_after_settlement":    { "type": "integer", "value": 12 },          // cannot be extended
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
    "alternative_to": ["kb.scheme.qld.fhc", "kb.scheme.qld.fh-vacant-land"],   // intra-slot exclusivity (all three fill the eligibility state_concession slot) — slug-grained, so expressible; also enforced by disjoint `applicable` criteria (new vs established vs vacant)
    "order_hint": 30
  }
}
```

Notes:

- **`duty_savings`** (the `eligibility.state_concession.duty_savings` leaf) is **not** filled here — it is resolver arithmetic: the full transfer duty otherwise payable on `property_fit.price`, from the Queensland transfer-duty rate schedule (`kb.scheme.qld.transfer-duty-rates`, to be authored). Cross-doc orchestration, the same pattern as FHG's `lmi_savings_estimate`.
- **`prior_overseas_property_ownership` carries opposite verdicts across schemes** — non-disqualifying for `kb.scheme.fhg`/`kb.scheme.fhss`, disqualifying here. This is the fact surface working as intended (the profile holds the neutral fact; each scheme's `criteria` decides). QLD's statutory test is "another **residence**"; our fact is property-level (slightly broader), a conservative approximation — flag if a residence-vs-any-interest distinction ever becomes load-bearing.
- **"Never claimed the first home vacant land concession"** is modelled as scheme-level mutual exclusion (`alternative_to: kb.scheme.qld.fh-vacant-land`), not as a profile fact. The historical-claim edge case (a buyer who previously claimed the vacant-land concession on an earlier purchase) is **not** encoded as a hard predicate — it would need a `profile.prior_qld_fh_vacant_land_concession` fact not in the surface, and it is rare for a fresh Mode A first-home buyer. Documented here rather than dangling an unbacked reference; promote to a fact only if it proves load-bearing.
- **`order_hint: 30`** (after FHSS 10 and FHG 20) — a duty concession is claimed at **settlement** (self-assessed via the transfer), the latest of the three in the buyer's timeline.
- **`value_cap: null`** encodes "no cap" since 1 May 2025; the resolver treats null as no upper bound.

## Sources

- Queensland Revenue Office — *First home (new home) concession* (eligibility, new-home definition, nil duty / no value cap, retention rules) — https://qro.qld.gov.au/duties/transfer-duty/concessions/homes/first-home-new-home/
- Queensland Revenue Office — *Changes to transfer duty from 1 May 2025* — https://qro.qld.gov.au/webinar/changes-from-1-may/
- Queensland Government — *No stamp duty for first home buyers on new builds* (median house-and-land saving illustration) — https://aplacetocallhome.initiatives.qld.gov.au/initiatives/stamp-duty-concession
