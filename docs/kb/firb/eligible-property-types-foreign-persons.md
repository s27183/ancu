---
slug: kb.firb.eligible-property-types-foreign-persons
effective_from: 2025-04-01
last_verified: 2026-06-28
---

# What property types a foreign person may buy — the positive taxonomy

This doc owns the **positive** side of the foreign-investment residential rules: *what a foreign person (including a temporary resident) may buy, and the conditions attached.* Its complement, [`kb.firb.established-dwelling-ban`](established-dwelling-ban.md), owns the **prohibition** (the window, who is covered, the exceptions, the consequences). They cross-reference; neither restates the other's list. It is read by **`property_assessment`** (component 3 — the new-build filter) and **`firb_workflow`** (component 4 — eligibility), and it grounds the `property_fit.property_type` → permitted-or-not mapping. Foreign-investment **approval is still required** on every permitted path (the taxonomy says *what may be approved*, not that approval is unnecessary).

While the [established-dwelling ban](established-dwelling-ban.md) is in force (1 Apr 2025 – 30 Jun 2029), the practical effect of this taxonomy is a **new-build / vacant-land-only** constraint for the individual foreign-person buyer.

## The permitted types

### New (or near-new) dwellings — permitted, usually no usage conditions

A **new dwelling** is one built on residential land that has **not previously been sold as a dwelling and not previously occupied** (or, if in a development, not previously occupied for more than 12 months). Foreign persons may buy new dwellings, and the approval is **not usually subject to conditions concerning usage** (a foreign person may leave it vacant, rent it, or — for a temporary-resident AU member — live in it), though the annual **vacancy fee** still applies if a dwelling is left unoccupied (owned by [`kb.firb.vacancy-fee-rules-2026`](vacancy-fee-rules-2026.md)).

A **near-new dwelling** is one that has not been previously occupied for more than 12 months and was not previously sold as a dwelling — typically a development the developer sold off-the-plan but where that earlier sale did not complete. Near-new dwellings are treated as new for this purpose.

Mapped onto the `property_type` enum: **`new_house`, `new_apartment`, `off_the_plan`, `house_and_land`** are permitted new-dwelling paths. (Off-the-plan and house-and-land are the most common foreign-person paths because new stock is where they are allowed — their *risks* are owned by [`kb.off-the-plan.risk-considerations`](../off-the-plan/risk-considerations.md).)

### Vacant residential land — permitted, with development conditions

Foreign persons may buy **vacant residential land** to develop, conditional on:

- **completing construction within 4 years** of approval; and
- **not selling the land until construction is complete.**

Mapped onto the enum: **`vacant_residential_land`** (the foreign-mode enum value; the domestic enum's `vacant_land` is the Mode-A analog). This path suits a build-your-own approach and carries the 4-year construction obligation as its defining condition.

### Developer new-dwelling exemption certificate — the simplified path

A developer that holds a **new-dwelling exemption certificate** may sell new dwellings in the development to foreign persons **without each buyer lodging an individual FIRB application** (the developer's certificate covers the buyer). This is the smoothest foreign-person path and is common for large off-the-plan projects. The mechanics + when it simplifies the workflow are owned by [`kb.firb.exemption-certificates-developer`](exemption-certificates-developer.md); this doc records only that the certificate makes a new-dwelling purchase eligible with a simplified application.

## The prohibited type

**Established dwellings** — `established_house`, `established_apartment` — are **not** available to a foreign person while the ban is in force, including to a temporary resident buying to live in. The ban window, the covered persons, and the limited (commercial-scale / status) exceptions are owned by [`kb.firb.established-dwelling-ban`](established-dwelling-ban.md). `property_assessment` surfaces an early non-authoritative warning when a foreign buyer views an established dwelling; `firb_workflow` issues the authoritative `foreign_person_eligible = false`.

## Rules

Pure-reference (`fills: []`). The in-ban purchase predicate (`firb_workflow.eligibility.foreign_person_can_purchase`) is owned by [`kb.firb.established-dwelling-ban`](established-dwelling-ban.md) (it reads the permitted-types enum + the ban window); `is_new_build_or_vacant_land` is resolver-derived from `property_fit.property_type`. This doc supplies the **taxonomy + conditions** the resolver and agent read, asserting no leaf.

```jsonc
{
  "fills": [],
  "parameters": {
    "approval_required_on_every_permitted_path": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "the taxonomy says what may be approved, not that approval is unnecessary." },
    "vacant_land_construction_years": { "type": "integer", "value": 4, "provenance": "REGULATED", "note": "construction must complete within 4 years of approval; land not sold until complete (foreigninvestment.gov.au Residential land)." },
    "new_dwelling_usually_no_usage_conditions": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "new-dwelling approval not usually conditioned on usage; the annual vacancy fee still applies (kb.firb.vacancy-fee-rules-2026)." },
    "near_new_treated_as_new": { "type": "bool", "value": true, "provenance": "REGULATED", "note": "a near-new dwelling (not occupied >12 months, not previously sold as a dwelling) is treated as a new dwelling." }
  },
  "lookup": {
    "property_type_foreign_eligibility": {
      "keydim": ["property_type"],
      "provenance": "REGULATED (FIRB / Treasury — Residential land)",
      "rows": [
        { "property_type": "established_house",        "foreign_person_permitted": false, "basis": "established dwelling — banned while window in force" },
        { "property_type": "established_apartment",    "foreign_person_permitted": false, "basis": "established dwelling — banned while window in force" },
        { "property_type": "new_house",                "foreign_person_permitted": true,  "basis": "new dwelling — permitted, approval required, usually no usage conditions" },
        { "property_type": "new_apartment",            "foreign_person_permitted": true,  "basis": "new dwelling — permitted, approval required, usually no usage conditions" },
        { "property_type": "off_the_plan",             "foreign_person_permitted": true,  "basis": "new dwelling — permitted; developer exemption certificate often applies" },
        { "property_type": "house_and_land",           "foreign_person_permitted": true,  "basis": "new dwelling — permitted, approval required" },
        { "property_type": "vacant_residential_land",  "foreign_person_permitted": true,  "basis": "permitted with development conditions (construct within 4 years; no on-sale until complete)" }
      ]
    }
  }
}
```

Notes:

- **Single-owner split with the ban doc (restated for clarity).** This doc = the positive taxonomy + conditions; [`kb.firb.established-dwelling-ban`](established-dwelling-ban.md) = the prohibition (window, covered persons, exceptions, consequences). The permitted-types enum appears in both — here as the documented taxonomy, there as the predicate's input list — by design; the conditions (4-year construction, near-new, usage) live **only** here.
- **`foreign_person_permitted` is the in-ban steady state, not the eventual law.** When the ban window closes (30 Jun 2029, owned by the ban doc), established dwellings become purchasable with approval again — so the resolver's authoritative verdict comes from the ban doc's window-gated predicate, not from this lookup read in isolation. This lookup is the *property-type taxonomy*; the *temporal gate* is the ban doc's.
- **Vacancy fee, off-the-plan risk, developer certificate, fees** are each owned by their own doc and cross-referenced — this doc does not restate them.
- **ASIC/independence line.** Informational taxonomy only; no figure beyond the regulated construction window is asserted, and the FIRB application fee (the cost of the permitted path) is owned by [`kb.firb.fee-schedule-current`](fee-schedule-current.md).

## Sources

- Foreign Investment in Australia (Treasury/FIRB) — *Residential land* (new/near-new dwellings permitted, usually no usage conditions; vacant land — construct within 4 years, no on-sale until complete; redevelopment case-by-case) — https://foreigninvestment.gov.au/guidance/types-investments/residential-land
- Foreign Investment in Australia — *Changes to foreign purchases of established dwellings* (the established-dwelling prohibition; permitted alternatives) — https://foreigninvestment.gov.au/news-and-reports/news/changes-foreign-purchases-established-dwellings
- ATO — *Foreign investment in Australia: residential property* (new dwellings, near-new dwellings, vacant land; developer exemption certificates) — https://www.ato.gov.au/individuals-and-families/investments-and-assets/foreign-resident-investments/foreign-investment-in-australia
