---
slug: kb.scheme.fhg
effective_from: 2025-10-01
last_verified: 2026-07-06
sources:
  - url: https://firsthomebuyers.gov.au/australian-government-5-percent-deposit-scheme/property-price-caps
    retrieved: 2026-07-06
  - url: https://firsthomebuyers.gov.au/australian-government-5-percent-deposit-scheme
    retrieved: 2026-07-06
---

# First Home Guarantee (FHG)

The **First Home Guarantee** is a federal scheme administered by **Housing Australia**. The government guarantees part of an eligible buyer's home loan so they can buy with a deposit **as low as 5%** and **avoid Lenders Mortgage Insurance (LMI)**. It is a guarantee on the loan, not a cash grant — no money changes hands to the buyer.

From **1 October 2025** the scheme was materially expanded: **place caps removed** (unlimited guarantees), **income caps removed**, and **property price caps raised**. The former Regional First Home Buyer Guarantee was folded into this single scheme.

## Eligibility

A buyer must:

- Be an **Australian citizen or permanent resident** at the time they enter the loan. (Permanent residents are eligible — the scheme is not citizen-only.)
- Be **at least 18 years old**.
- Be a **first home buyer, or a previous owner who has not held an interest in Australian real property in the past 10 years**. (The scheme is no longer strictly first-home-only; the 10-year re-entry path covers people re-establishing after divorce, prior ownership overseas, etc.)
- Intend to **live in the property as an owner-occupier**. It is not available for investment property.
- Buy a **residential property** within the applicable price cap (below).
- Apply through a **participating lender** (Housing Australia maintains the panel; the guarantee is accessed only via those lenders).

There are **no income caps** and **no limit on the number of places** as of 1 October 2025.

## Deposit and LMI

- Eligible deposit range: **at least 5% and less than 20%** of the property price.
- The government guarantees the portion of the loan between the buyer's deposit and 20%, so the lender does not require **LMI**. On a typical purchase this avoids a one-off cost that can run into the tens of thousands of dollars (the exact saving depends on price and deposit; estimate against the specific purchase).
- The guarantee is not a cash payment and does not reduce the loan principal — the buyer still borrows the full balance and repays it in full.

## Property price caps (effective 1 October 2025)

The cap is set by location. The higher "city / regional centre" cap applies to each state's capital and to designated large regional centres; the lower "rest of state" cap applies elsewhere.

| State / Territory | City / regional centre | Rest of state |
|---|---|---|
| NSW | $1,500,000 | $800,000 |
| VIC | $950,000 | $650,000 |
| QLD | $1,000,000 | $700,000 |
| WA | $850,000 | $600,000 |
| SA | $900,000 | $500,000 |
| TAS | $700,000 | $550,000 |
| ACT | $1,000,000 | — |
| NT | $750,000 | $600,000 |
| Jervis Bay Territory / Norfolk Island | $550,000 | — |
| Christmas Island / Cocos (Keeling) Islands | $400,000 | — |

**Designated regional centres** that receive the higher (capital-city) cap: Illawarra and Newcastle/Lake Macquarie (NSW), Geelong (VIC), and the Gold Coast and Sunshine Coast (QLD).

The price cap is on the **purchase price**, assessed against the property's location, not the buyer's residence.

## Stacking with other support

The FHG is a **deposit-gap guarantee**. It is independent of, and does not consume, separate forms of support that operate through different mechanisms — notably the **First Home Super Saver** scheme (a savings/withdrawal vehicle), **state First Home Owner Grants**, and **state stamp-duty concessions**. Those are assessed on their own eligibility rules and can generally apply alongside an FHG-backed loan. The **Help to Buy** shared-equity scheme is a different government-equity mechanism with its own places and income tests; treat FHG and Help to Buy as alternative paths to assess against each other rather than assume they combine, and verify the current rule for any specific case.

## Relevance for Vietnamese-Australian buyers (Mode A)

- **Permanent residents qualify**, not only citizens — this matters for diaspora buyers on PR who have not yet naturalised.
- The **10-year re-entry rule** can cover a buyer who previously owned property **in Vietnam or elsewhere overseas** but has not held Australian real property in the past decade — eligibility turns on Australian ownership history.
- The scheme requires **owner-occupier** intent, so it does not apply to the investor modes (C/D).

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above this section is `content_md`. Figures here are the source of truth for the resolver; the prose narrates the same facts for the reader and must be kept in step.

```jsonc
{
  "fills": [
    { "leaf": "eligibility.fhg.eligible",
      "rule": { "kind": "criteria", "combine": "all_of", "criteria": [
        { "field": "applicant.citizenship_status", "op": "in",  "value": ["citizen", "permanent_resident"] },
        { "field": "applicant.age",                 "op": "gte", "value": 18 },
        { "combine": "any_of", "criteria": [
          { "field": "applicant.ever_owned_au_property",                "op": "eq",  "value": false },
          { "field": "applicant.years_since_last_au_property_interest", "op": "gte", "value": 10 } ] },
        { "field": "applicant.owner_occupier_intent", "op": "eq",  "value": true },
        { "field": "property_fit.price", "op": "lte", "ref": "eligibility.fhg.applicable_cap_for_location_property" } ] } },
        // the property_fit.price criterion activates in per-property scope; base scope evaluates the profile-only criteria → provisional eligibility

    { "leaf": "eligibility.fhg.applicable_cap_for_location_property",
      "rule": { "kind": "lookup",
        "key": ["property_fit.state", "location_tier"],   // location_tier is resolver-derived (see parameters + note), not a published field
        "table": [
          { "when": ["NSW", "capital_or_regional_centre"], "value": 1500000 },
          { "when": ["NSW", "rest_of_state"],              "value": 800000  },
          { "when": ["VIC", "capital_or_regional_centre"], "value": 950000  },
          { "when": ["VIC", "rest_of_state"],              "value": 650000  },
          { "when": ["QLD", "capital_or_regional_centre"], "value": 1000000 },
          { "when": ["QLD", "rest_of_state"],              "value": 700000  },
          { "when": ["WA",  "capital_or_regional_centre"], "value": 850000  },
          { "when": ["WA",  "rest_of_state"],              "value": 600000  },
          { "when": ["SA",  "capital_or_regional_centre"], "value": 900000  },
          { "when": ["SA",  "rest_of_state"],              "value": 500000  },
          { "when": ["TAS", "capital_or_regional_centre"], "value": 700000  },
          { "when": ["TAS", "rest_of_state"],              "value": 550000  },
          { "when": ["ACT", "capital_or_regional_centre"], "value": 1000000 },
          { "when": ["NT",  "capital_or_regional_centre"], "value": 750000  },   // Darwin cap raised to $750k; NT now split (was a single $600k territory-wide cap)
          { "when": ["NT",  "rest_of_state"],              "value": 600000  }
        ],
        "default": null } },                            // unmapped (state, tier) ⇒ resolver flags a curation gap

    { "leaf": "eligibility.fhg.deposit_percentage_required",
      "rule": { "kind": "parameter", "type": "percentage", "value": 5 } },

    { "leaf": "eligibility.fhg.constraints",
      "rule": { "kind": "parameter", "type": "array<string>", "value": [
        "Must apply through a Housing Australia participating lender",
        "Owner-occupier only — not available for investment"
      ] } }
  ],
  "parameters": {
    "designated_regional_centre_lgas": { "type": "array<string>", "value": [
      "Illawarra", "Newcastle", "Lake Macquarie",   // NSW
      "Geelong",                                     // VIC
      "Gold Coast", "Sunshine Coast"                 // QLD
    ], "note": "LGAs/regions that receive the capital-city cap. FHG-specific (region tiering differs per scheme), so it lives here, not in the neutral property fact surface. Resolver: location_tier = capital_or_regional_centre if property_fit.is_capital_city OR property_fit.lga ∈ this list, else rest_of_state." }
  },
  "stacking": {
    "combines_with": ["kb.scheme.fhss"],   // concrete slugs only; the fhg↔state-concession edge is declared on each state-concession doc (combines_with is symmetric — see §11.9), never enumerated here
    "alternative_to": ["kb.scheme.help-to-buy"],
    "order_hint": 20
  }
}
```

Notes on the cap lookup:

- **`location_tier`** is a *resolver-local intermediate*, **not** a published registry field (§11.9): region tiering is per-scheme, so there is no single shared tier. The FHG resolver derives it from neutral published geo facts — `location_tier = capital_or_regional_centre` if `property_fit.is_capital_city` **or** `property_fit.lga ∈ designated_regional_centre_lgas` (the parameter above), else `rest_of_state` — then uses it as the cap-lookup key. The designated-centre list is FHG-specific data and lives in this doc's `parameters` (not in the neutral `property_fit` surface, and not a separate slug — nothing else references it); the classification is resolver code.
- **ACT** has a single territory-wide cap, mapped to the `capital_or_regional_centre` tier. **NT** is split ($750k Darwin/capital tier, $600k rest-of-NT) as of the current firsthomebuyers.gov.au caps.
- **External territories** (Jervis Bay / Norfolk Island $550k; Christmas / Cocos $400k) are in the prose but **out of the current `property.state` enum** (NSW…NT), so they are not in the lookup.
- `eligibility.fhg.lmi_savings_estimate` is **not** filled here — it is resolver arithmetic against the specific purchase using `kb.lmi.calculation` (cross-doc orchestration).

## Sources

- Housing Australia — *Unlimited places, higher property price caps for first home buyers from 1 October 2025* — https://www.housingaustralia.gov.au/media/unlimited-places-higher-property-price-caps-first-home-buyers-1-october-2025
- Housing Australia — *First Home Guarantee* (scheme page, eligibility) — https://www.housingaustralia.gov.au/support-buy-home/first-home-guarantee
