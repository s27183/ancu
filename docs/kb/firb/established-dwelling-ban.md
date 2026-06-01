---
slug: kb.firb.established-dwelling-ban
effective_from: 2025-04-01
last_verified: 2026-06-01
---

# Foreign-person ban on purchasing established dwellings (1 Apr 2025 – 30 Jun 2029)

From **1 April 2025**, a **foreign person** cannot purchase an **established dwelling** in Australia unless a limited exception applies. The measure was introduced as a two-year ban (to 31 March 2027) and **extended in the 2026–27 Budget by two years and three months, to 30 June 2029**. It is administered through the foreign investment framework (the *Foreign Acquisitions and Takeovers Act 1975*) and enforced by the **ATO** (foreign-investment compliance) and **Treasury**.

This is the architectural linchpin of the foreign-person modes (Mode B / Mode D). It is **not** a relevant constraint for Mode A — an Australian citizen or a permanent resident who is *ordinarily resident* in Australia is **not** a foreign person and is unaffected by this ban. (How a buyer is classified as a foreign person is a separate question — see [`kb.firb.status-determination`](status-determination.md).)

## Who the ban covers

A **foreign person** for this purpose includes:

- an individual **not ordinarily resident in Australia**;
- a **temporary resident** — an individual on a temporary visa permitting a continuous stay of more than 12 months, or on a bridging visa with a pending permanent-visa application. **Temporary residents are foreign persons** and are caught by the ban, including when buying an established dwelling to live in as their principal place of residence;
- a **foreign-owned company or trust** (broadly, ≥20% single foreign interest, or ≥40% aggregate).

A **permanent resident ordinarily resident in Australia** is **not** a foreign person, and so is **not** subject to the ban. (A permanent resident who is *not* ordinarily resident may still be a foreign person in some circumstances.)

## What an "established dwelling" is

An **established dwelling** is a dwelling on residential land that is **not a new dwelling** — i.e. existing housing stock that has been previously sold or occupied as a residence. It is the complement of the property types a foreign person **can** still buy (see [`kb.firb.eligible-property-types-foreign-persons`](eligible-property-types-foreign-persons.md) for the positive taxonomy and conditions):

- **new (or near-new) dwellings** — generally permitted, usually with no usage conditions;
- **vacant residential land** — permitted for development, conditional on completing construction (generally **within 4 years**) and not selling the land until construction is complete.

So the practical effect of the ban for a foreign-person buyer is a **new-build / vacant-land-only** constraint while the window is open.

## Limited exceptions

The ban does **not** apply where one of these exceptions is met. These are predominantly supply-increasing or commercial-scale pathways — **none typically fits an individual foreign-person first-home or single-investment buyer who intends to occupy or hold the dwelling as-is**, so for Modes B/D the working assumption is "ban applies → new-build/vacant-land only" unless the buyer is genuinely pursuing one of the following:

1. **Redevelopment that significantly increases housing supply** — generally requires the property to be **vacant at settlement**, **no part occupied** from settlement until construction is complete, **at least 20 additional dwellings** built on the land, and **construction completed within 4 years** of approval.
2. **Commercial-scale housing availability** — multi-unit developments such as **build-to-rent (BTR)**, retirement villages, assisted-living / aged-care facilities, and student accommodation (including indirect acquisitions of interests in entities that own such developments).
3. **PALM-scheme employer housing** — foreign companies employing workers from Pacific Island countries and Timor-Leste (including under the Pacific Australia Labour Mobility scheme) and required to house them may be approved to buy established dwellings for that use.
4. **New Zealand citizens / Special Category Visa (subclass 444) holders** — do not require foreign-investment approval to buy residential property, and are outside the ban.
5. **Spouse of an Australian citizen, permanent resident, or New Zealand citizen** — where the property is acquired by the couple **as joint tenants** (an existing carve-out from foreign-person treatment).

> ⚠ A buyer who *believes* an exception applies must still obtain the relevant foreign-investment approval **before** signing an unconditional contract. The exception changes whether approval can be granted, not whether the [application workflow](application-process.md) is required.

## Compliance and consequences

- **Approval before contract.** A foreign person must hold foreign-investment approval before acquiring an interest. The established-dwelling ban means an application to buy an established dwelling is **refused** unless an exception applies — it is not a fee question, it is an eligibility wall.
- **Enforcement.** The ATO runs an audit and compliance program (including land-banking crackdown). Penalties for non-compliance can include civil penalties, criminal liability, and **forced disposal** of the property. (Penalty detail: [`kb.firb.penalties-non-compliance`](penalties-non-compliance.md).)
- **Separate obligations still apply** to the permitted (new-build / vacant-land) paths: FIRB application fee, foreign-buyer stamp-duty surcharge (state), and the annual vacancy fee.

## Relevance for Vietnamese diaspora buyers

- **Mode A (citizen / PR ordinarily resident): not affected.** Do not surface the ban as a constraint on a Mode A plan; it only causes confusion. The ban is a Mode B/D concern.
- **Mode B (Vietnam-parent funding an AU child; AU temporary resident FHB): central.** A temporary-resident AU member (student / graduate / skilled temporary visa) **is** a foreign person and is caught — they can buy **new builds, off-the-plan, or house-and-land**, but **not** an established house or apartment, until the window closes (or PR ordinarily-resident status is reached). The spouse carve-out matters where the AU member is the spouse of a citizen/PR and buys **as joint tenants**.
- **Mode D (Vietnam-located investor): central.** Same new-build/vacant-land constraint; the supply-increasing exceptions are commercial-scale and rarely fit a single-dwelling investor.
- This is why the foreign-person blueprints **filter to new-build/off-the-plan at `property_assessment`** and gate the authoritative verdict in `firb_workflow` — the ban is built into the architecture, not left as a disclaimer (constraint #10).

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. This doc is the **single owner** of the ban window and the new-build constraint: the ban dates live here once as `parameter` leaves, and the consuming component (`firb_workflow`, Modes B/D — wired as a `kb_anchor`) reads them rather than asserting the window itself. Per §11.9's "no control flow in `content_json`" rule, the window/date comparisons are **resolver code** consuming these numbers (the same discipline as stamp-duty brackets and LMI), not declarative rules.

```jsonc
{
  "fills": [
    // The in-ban purchase-eligibility predicate for a foreign person against THIS property.
    // any_of: not a foreign person (ban N/A — this branch also absorbs the NZ-citizen/SCV and
    // spouse-as-joint-tenants carve-outs, which resolve upstream at kb.firb.status-determination to
    // firb_required=false) OR the property is a new/near-new build (permitted). The resolver GATES this
    // predicate with the ban window (see established_dwelling_ban_applies in Notes): outside the window an
    // established dwelling is purchasable with approval, so this predicate is decisive only while the ban
    // is in force. The commercial-scale exceptions (redevelopment ≥20 dwellings, BTR, PALM) are
    // agent-surfaced, not resolver predicates — see Notes.
    { "leaf": "firb_workflow.eligibility.foreign_person_can_purchase",
      "rule": { "kind": "criteria", "combine": "any_of", "criteria": [
        { "field": "profile.firb_required",      "op": "eq", "value": false },
        { "field": "property_fit.property_type", "op": "in", "value": ["new_house", "new_apartment", "off_the_plan", "house_and_land"] } ] } },

    { "leaf": "firb_workflow.eligibility.firb_application_required",
      "rule": { "kind": "parameter", "type": "bool", "value": true } }  // approval required on every permitted foreign-person path
  ],
  "parameters": {
    "ban_start_date":               { "type": "date", "value": "2025-04-01" },
    "ban_end_date":                 { "type": "date", "value": "2029-06-30", "note": "extended from 2027-03-31 in the 2026-27 Budget (+2yr 3mo)" },
    "covered_persons":              { "type": "array<string>", "value": [
      "foreign person not ordinarily resident in Australia",
      "temporary resident (visa permitting >12 months' continuous stay, or bridging visa with pending PR application)",
      "foreign-owned company or trust (>=20% single / >=40% aggregate foreign interest)"
    ] },
    "permitted_property_types_for_foreign_persons": { "type": "array<string>", "value": [
      "new_house", "new_apartment", "off_the_plan", "house_and_land", "vacant_residential_land"
    ], "note": "vacant land conditional on construction completed within ~4 years and not on-sold until complete" },
    "exceptions": { "type": "array<string>", "value": [
      "Redevelopment significantly increasing supply: vacant at settlement, unoccupied until construction complete, >=20 additional dwellings, completed within 4 years of approval",
      "Commercial-scale housing: build-to-rent, retirement villages, assisted living / aged care, student accommodation (incl. indirect interests)",
      "PALM-scheme employer housing for Pacific Island / Timor-Leste workers",
      "New Zealand citizens / Special Category Visa (444) holders — no foreign-investment approval required",
      "Spouse of an Australian citizen, PR, or NZ citizen acquiring as joint tenants"
    ] },
    "approval_required_before_contract": { "type": "bool", "value": true },
    "non_compliance_consequences":  { "type": "array<string>", "value": [
      "Application to buy an established dwelling refused unless an exception applies",
      "ATO audit / land-banking compliance program",
      "Civil penalties, possible criminal liability, and forced disposal of the property"
    ] }
  }
}
```

Notes:

- **The exception lattice is split by layer, not flattened into one predicate (design resolution).** The five exceptions fall into two kinds, each handled at its correct layer rather than re-encoded here:
  - **Status-level carve-outs** — New Zealand citizens / SCV (444) holders, and the spouse-of-citizen/PR/NZ-citizen acquiring **as joint tenants** — change whether the buyer is a *foreign person requiring approval* at all. They resolve **upstream** at [`kb.firb.status-determination`](status-determination.md) to `profile.firb_required == false`, which the `foreign_person_can_purchase` `any_of` already absorbs. No predicate is dropped; it is captured one layer up.
  - **Supply-increasing / commercial-scale exceptions** — redevelopment (≥20 dwellings), BTR / retirement / aged-care / student accommodation, PALM employer housing — turn on the buyer's **development intent**, which is not a Mode B/D FHB or single-dwelling-investor fact (no `redevelopment_intent` / `is_btr` field in the surface). Encoding them as hard predicates would dangle unbacked references, so they are **agent-surfaced** pathways ("if you are buying to redevelop into 20+ dwellings…") — reserving the agent for the irreducible. Promote one to a profile fact only if it proves load-bearing (rare for these buyers).
- **`established_dwelling_ban_applies` is resolver-derived from the window, so it is not a `fills` rule** (same pattern as FHNHC `duty_savings` / FHG `lmi_savings_estimate`, which are resolver-computed, not asserted). The resolver reads `ban_start_date`/`ban_end_date` from this doc and computes `start ≤ today ≤ end`; when the window closes 30 Jun 2029 the verdict flips with **no blueprint edit** — "computed, not asserted." It also **gates** `foreign_person_can_purchase`: out of window, the new-build-only predicate stops being decisive. The `firb_workflow` blueprint param was changed from a hardcoded `value: true` to this resolver derivation as part of wiring (below).
- **No `context.current_date` / `value_ref` (design resolution).** An earlier draft modelled the window check as a `criteria` rule over `context.current_date` with a `value_ref` to a parameter. §11.9 sanctions neither — the registry has no `context.*` external source, and the grammar forbids control flow in `content_json`. The correct shape (used here) is **dates as `parameter` leaves + the comparison in resolver code**; no schema extension was needed.
- **Single-owner wiring (done).** The ban window and new-build constraint were also asserted in `buyer_profile` (`established_property_eligible` / `new_build_only_constraint`, dates hardcoded in a comment) and warned in `property_assessment.key_concerns`. To give the regulated value exactly one home, this doc is now wired as a `kb_anchor` on `firb_workflow` (Mode B; Mode D inherits it by reference) **and** on `buyer_profile` (Modes B + D), and the hardcoded dates in both `buyer_profile` outcomes were replaced with a reference to this doc. `property_assessment`'s `key_concerns` warning is prose, not a regulated-number home, so it carries no date assertion and needs no change.
- **Relationship to [`kb.firb.eligible-property-types-foreign-persons`](eligible-property-types-foreign-persons.md).** That doc owns the *positive* property-type taxonomy and conditions (what a foreign person may buy and the development obligations). This doc owns the *prohibition* — the window, who is covered, the exceptions, and the compliance consequences. They cross-reference; neither duplicates the other's list.

## Sources

- Australian Taxation Office — *Foreign investment: extending the ban on foreign purchases of established dwellings* (extension to 30 June 2029; who is covered; enforcement) — https://www.ato.gov.au/about-ato/new-legislation/in-detail/international/banning-foreign-purchases-of-established-dwellings
- Foreign Investment in Australia (Treasury/FIRB) — *Changes to foreign purchases of established dwellings* (1 April 2025 start; foreign persons incl. temporary residents) — https://foreigninvestment.gov.au/news-and-reports/news/changes-foreign-purchases-established-dwellings
- Foreign Investment in Australia — *Residential land* (permitted property types; vacant-land 4-year construction condition; redevelopment exception) — https://foreigninvestment.gov.au/guidance/types-investments/residential-land
- ATO — *Are you a foreign person buying property in Australia?* (foreign person / temporary resident / permanent resident definitions) — https://www.ato.gov.au/individuals-and-families/investments-and-assets/foreign-resident-investments/foreign-investment-in-australia/are-you-a-foreign-person-buying-property-in-australia
- Treasury Ministers — *More homes and a fair go for first home buyers* (Budget 2026–27 extension of the ban) — https://ministers.treasury.gov.au/ministers/clare-oneil-2025/media-releases/more-homes-and-fair-go-first-home-buyers
