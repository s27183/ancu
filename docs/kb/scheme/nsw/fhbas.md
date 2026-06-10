---
slug: kb.scheme.nsw.fhbas
effective_from: 2023-07-01
last_verified: 2026-06-01
---

# NSW First Home Buyers Assistance Scheme (FHBAS)

The **First Home Buyers Assistance Scheme** is a New South Wales **transfer (stamp) duty** exemption/concession for first home buyers, administered by **Revenue NSW** under the *Duties Act 1997*. Like the QLD concessions it reduces a **settlement cost** — the duty otherwise payable on the transfer — but, unlike Queensland's split between new and established homes, **a single scheme covers new homes, established homes, and vacant land**, with the threshold depending on what is bought. It is independent of the federal [First Home Guarantee](../fhg.md) and [First Home Super Saver](../fhss.md), which operate through different mechanisms.

From **1 July 2023** the thresholds are: for a **home** (new or existing), **full exemption at $800,000 or under**, a **partial concession between $800,000 and $1,000,000**, and no concession above $1,000,000. For **vacant land** to build on, **full exemption at $350,000 or under** and a partial concession between **$350,000 and $450,000**. (This scheme replaced the short-lived First Home Buyer Choice annual-property-tax option, which was abolished.)

## Eligibility

To claim the benefit, the buyer must:

- Have **never owned or co-owned residential property in Australia.** ⚠ This is an **Australia-only** test — a prior home **overseas does not disqualify** — see [Relevance for Vietnamese-Australian buyers](#relevance-for-vietnamese-australian-buyers-mode-a).
- Not have **previously received** an exemption or concession under this scheme (and the same applies to a spouse/partner — see Notes).
- Be buying a **new or existing home, or vacant land, in NSW** within the [threshold amounts](#concession-amount).
- Have at least one of the first home buyers who is an **Australian citizen or permanent resident**.
- **Move into the home** within **12 months** of settlement (or completion of a new build) and live there as the **principal place of residence for at least 6 continuous months**.

## Concession amount

The benefit is value-banded and depends on what is bought:

- **Home (new or existing)** — **$800,000 or under**: no transfer duty (**full exemption**). **Over $800,000 to $1,000,000**: a **partial concession** that tapers as value rises. **Over $1,000,000**: no concession.
- **Vacant land** — **$350,000 or under**: no transfer duty. **Over $350,000 to $450,000**: a partial concession. **Over $450,000**: no concession.

The **dollar saving** for a given purchase is the duty otherwise payable (full exemption) or the difference between full and concessional duty (partial) — computed from the NSW transfer-duty rate schedule against the dutiable value (resolver arithmetic; see Notes).

## Stacking with other support

This is a **state duty concession**, independent of the federal schemes: it can apply alongside an [FHG](../fhg.md)-backed loan and an [FHSS](../fhss.md) deposit withdrawal. It also **combines with the [NSW First Home Owner (New Homes) Grant](fhog.md)** for an eligible new home — the duty concession and the $10,000 grant are different instruments. There is **no new-vs-established split** within NSW (unlike QLD), so FHBAS is the **sole** NSW first-home duty concession — it has no intra-state alternative.

## Relevance for Vietnamese-Australian buyers (Mode A)

- **The overseas-ownership test is favourable here — the opposite of Queensland.** FHBAS tests only **Australian** property history, so a Vietnamese-Australian buyer who once owned (or still owns) a home **in Vietnam** is **not disqualified** on that basis — the same posture as the federal FHG/FHSS. This is a sharp contrast with `kb.scheme.qld.fhnhc` / `kb.scheme.qld.fhc`, which test residences *worldwide* and disqualify on a prior overseas home. Surface the state difference explicitly when comparing target states.
- **The $800,000 full-exemption threshold is generous for the affordable end** but bites quickly in Sydney, where median prices sit above it — between $800k and $1M only a partial concession applies, and above $1M none. The target price range determines whether the benefit is full, partial, or nil.
- **Citizenship or PR qualifies** (at least one buyer), so a Vietnamese-Australian PR — a core Mode A user — is eligible, unlike `kb.scheme.help-to-buy` (citizens only).

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. The dollar `duty_savings` and the value-banded `concession_type` are **computed** by the resolver from the dutiable value against the NSW transfer-duty schedule and the thresholds below (not asserted here), so only the eligibility predicate and the scheme name are filled.

```jsonc
{
  "fills": [
    { "leaf": "eligibility.state_concession.applicable",
      "rule": { "kind": "criteria", "combine": "all_of", "criteria": [
        { "field": "property_fit.state",             "op": "eq",  "value": "NSW" },
        { "field": "applicant.ever_owned_au_property", "op": "eq",  "value": false },             // AU-only test — overseas ownership does NOT disqualify (favourable; opposite of QLD)
        { "field": "applicant.citizenship_status",     "op": "in",  "value": ["citizen", "permanent_resident"] },
        { "field": "applicant.owner_occupier_intent",  "op": "eq",  "value": true },              // move in within 12 mo, live 6 continuous mo
        { "field": "property_fit.price",             "op": "lte", "value": 1000000 } ] } },     // outer bound for a HOME; above $1M no concession. Vacant-land bands are lower — see Notes
        // property_fit.* criteria activate in per-property scope; base scope evaluates the profile-only criteria → provisional

    { "leaf": "eligibility.state_concession.scheme_name",
      "rule": { "kind": "parameter", "type": "string", "value": "NSW First Home Buyers Assistance Scheme" } }
  ],
  "parameters": {
    "home_exemption_threshold":               { "type": "money",   "value": 800000 },           // home (new or existing) at/under → duty nil
    "home_concession_cap":                    { "type": "money",   "value": 1000000 },          // $800k–$1M tapering partial; above → none
    "vacant_land_exemption_threshold":        { "type": "money",   "value": 350000 },
    "vacant_land_concession_cap":             { "type": "money",   "value": 450000 },
    "move_in_window_months_after_settlement": { "type": "integer", "value": 12 },
    "min_continuous_occupancy_months":        { "type": "integer", "value": 6 }
  },
  "stacking": {
    "combines_with": ["kb.scheme.fhg", "kb.scheme.fhss", "kb.scheme.help-to-buy"],   // state doc declares federal↔state edges (symmetric, §11.9); Help to Buy explicitly allows stacking stamp-duty concessions. The NSW FHOG↔FHBAS edge is declared on fhog.md.
    "order_hint": 30   // duty concession — claimed at settlement, latest in the buyer's timeline
  }
}
```

Notes:

- **`duty_savings`** (the `eligibility.state_concession.duty_savings` leaf) is **not** filled here — it is resolver arithmetic against the NSW transfer-duty rate schedule ([`kb.stamp-duty.calc-by-state`](../../stamp-duty/calc-by-state.md)) on the dutiable value. Same pattern as the QLD concessions and FHG's `lmi_savings_estimate`.
- **`concession_type`** is **resolver-derived**, not a flat parameter: for a home, `full_exemption` at or under `home_exemption_threshold`, `partial_concession` up to `home_concession_cap`, else `no_concession`; for vacant land, the lower `vacant_land_*` thresholds apply. Banded/property-type-dependent selection is control flow → resolver code, document-supplied numbers ("computed, not asserted").
- **Vacant land has its own lower thresholds**, and the `property_fit.property_type` enum now carries a distinct `vacant_land` value (separate from `house_and_land`, the bundled build package). FHBAS is a *single* type-agnostic scheme — it covers a home (new or existing) **and** vacant land — so the `applicable` predicate has no property-type criterion; it uses the home ceiling ($1M) as the coarse outer bound. The resolver branches the **band** on `property_fit.property_type`: `vacant_land` → the lower `vacant_land_*` thresholds ($350k exemption / $450k cut-off); the home types → `home_*` ($800k / $1M). The banded `concession_type` is the authoritative full/partial/none verdict (a $600k vacant-land purchase resolves `no_concession` even though it clears the coarse $1M bound).
- **`ever_owned_au_property` only** — FHBAS is Australia-only, so `prior_overseas_property_ownership` is **deliberately not** in the predicate (it would wrongly disqualify). This is the fact surface working as intended: the same neutral overseas fact that disqualifies under QLD is simply not consulted here.
- **The "previously received this scheme" gate and the spouse extension are not encoded as hard predicates.** There is no `profile.prior_fhbas_benefit` fact, and the spouse's ownership/benefit history is not on the surface. Both are rare for a fresh Mode A first-home buyer; documented here rather than dangling unbacked references — promote to facts only if they prove load-bearing. (Same treatment as FHNHC's "never claimed the vacant-land concession" edge case.)

## Sources

- Revenue NSW — *First Home Buyers Assistance scheme* (thresholds, eligibility, residence requirement, Australia-only prior-ownership test) — https://www.revenue.nsw.gov.au/grants-schemes/assistance-scheme
- NSW Government — *First Home Buyers Assistance Scheme* (home $800k exemption / $1M concession; vacant land $350k/$450k; citizen-or-PR; move-in 12 months, 6 continuous months) — https://www.nsw.gov.au/housing-and-construction/buying-and-selling-property/home-buying-assistance/first-home-buyers-assistance-scheme
- Revenue NSW — *First Home Buyers Assistance Scheme guide* — https://www.revenue.nsw.gov.au/property-professionals-resource-centre/duties-guides/first-home-buyers-assistance-scheme-guide
