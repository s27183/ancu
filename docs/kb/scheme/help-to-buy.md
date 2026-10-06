---
slug: kb.scheme.help-to-buy
effective_from: 2025-12-05
last_verified: 2026-07-06
sources:
  - url: https://firsthomebuyers.gov.au/australian-government-help-buy-scheme
    retrieved: 2026-07-06
---

# Help to Buy (federal shared-equity scheme)

**Help to Buy** is an Australian Government **shared-equity** scheme administered by **Housing Australia**. The government takes an **equity share** in the home in exchange for contributing to the purchase price, which lets an eligible buyer purchase with a deposit as low as **2%** and a smaller mortgage. It is **not a loan, grant, or guarantee** — the government **co-owns** the property up to its contributed share. Applications opened on **5 December 2025**; the first participating lenders were Commonwealth Bank and Bank Australia, with more expected through 2026.

This differs fundamentally from the other federal supports: [First Home Guarantee](fhg.md) (FHG) is a **guarantee** that lets you borrow with a 5% deposit and avoid LMI while you keep **100% of the equity**; [First Home Super Saver](fhss.md) (FHSS) is a **savings vehicle**. Help to Buy instead **reduces how much you borrow** by having the government own part of the home — so you and the government share both the cost and the future capital gain. FHG and Help to Buy are **mutually exclusive** (see [Stacking](#stacking-with-other-support)).

## How the equity share works

- The government contributes up to **40% of the purchase price for a new home** and up to **30% for an existing home**, taking an equity share of the same size.
- The buyer needs a minimum **2% deposit** and finances the rest with an ordinary mortgage from a participating lender.
- The buyer can **buy back** the government's share over time (in minimum increments, subject to scheme rules) and must repay the government's share — proportional to the home's value at the time — when the home is **sold**, or when eligibility ends (e.g. income exceeds the cap for two consecutive years, or the home stops being the principal residence).
- Because the government's equity already brings the loan below the LMI threshold, **no LMI** is payable and the FHG guarantee is redundant — which is why the two cannot be combined.

## Eligibility

To be eligible, the buyer must:

- Be an **Australian citizen** — **permanent residents do not qualify** for Help to Buy (this is stricter than FHG, which admits PRs). ⚠ Material for Mode A — see [Relevance for Vietnamese-Australian buyers](#relevance-for-vietnamese-australian-buyers-mode-a).
- Be **at least 18 years old**.
- **Not currently own** any property (residential or otherwise) **in Australia or overseas**. This is a **current**-ownership test, not a historical one — a buyer who previously owned a home and has since **sold** it can qualify ("returning to home ownership"). (A single parent who jointly owns and is buying out the other party's share is a specific permitted exception.)
- Buy the home as an **owner-occupier** — it must be the **principal place of residence**; investment properties are excluded.
- Have a taxable income at or below the **income cap**: **$103,000** for a single applicant, **$165,000** for joint applicants or a single parent (assessed on the financial year preceding application). These caps rose from $100,000 / $160,000 on **1 July 2026** and are **wage-indexed annually** each 1 July.
- Buy a home at or below the **property price cap** for the location (see [Property price caps](#property-price-caps)).
- Secure one of the limited **places** — **10,000 per financial year**, **40,000 over the four-year program** (unlike FHG, Help to Buy is **capped**, not unlimited).

## Property price caps

Price caps vary by state/territory and by capital-city vs regional location; Housing Australia publishes a postcode lookup. The current capital-city caps are: **Sydney $1,300,000**, **Melbourne $950,000**, **Brisbane $1,000,000**, **Perth $850,000**, **Adelaide $700,000**, **Hobart $700,000**, **Darwin $700,000**, **Canberra $900,000**; regional caps are lower (down to around $600,000 in some regional areas). **Tasmania does not yet have the enabling legislation** to participate, so the scheme is currently unavailable there.

## Stacking with other support

- **Mutually exclusive with [First Home Guarantee](fhg.md) (and the wider Home Guarantee Scheme).** The scheme rules prohibit combining Help to Buy with "funding from other Australian Government shared equity programs, home-buyer assistance schemes, guarantees, loans, or loans from state and territory programs." FHG is a guarantee toward the same deposit/LMI problem, so a buyer uses **one or the other**, not both. This is the central first-home financing fork for an eligible Mode A buyer.
- **Combines with [FHSS](fhss.md)** — FHSS releases the buyer's **own** super contributions to fund the 2% deposit; it is not government equity/guarantee/loan funding, so it can supply the deposit. *(Not explicitly enumerated in the scheme's published combine-list; modelled as combinable because FHSS is buyer-sourced deposit money — flag in Notes.)*
- **Combines with state stamp-duty concessions and the state First Home Owner Grant** — Housing Australia explicitly allows using "First Home Owners Grant, stamp duty concessions, and similar government incentives to help make up your deposit." Per the [§11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification) stacking convention, those symmetric federal↔state edges are declared on the **state** docs (`kb.scheme.qld.fhc`, `kb.scheme.qld.fhnhc`, `kb.scheme.nsw.fhbas`, `kb.scheme.nsw.fhog`, `kb.scheme.vic.fhb-duty`, `kb.scheme.vic.fhog`), so this federal doc does not enumerate them.

## Relevance for Vietnamese-Australian buyers (Mode A)

- **Citizenship-only is the first filter.** Help to Buy requires Australian **citizenship**; a Vietnamese-Australian **permanent resident** — squarely a Mode A user — is **not eligible**, even though they qualify for FHG, FHSS, and state concessions. Surface this early so the plan does not present Help to Buy to a PR.
- **The ownership test is *current*, not historical — and that cuts both ways for the diaspora.** A buyer who **currently owns** a home in Vietnam (or anywhere) is **disqualified**; but one who **previously owned and has since sold** is fine. This differs from FHG/FHSS (which look at Australian history only) and from the QLD concessions (which disqualify on *any* prior overseas residence). The neutral `currently_owns_property` fact decides it here.
- **The income caps bite.** $103k single / $165k joint is low for a dual-income metropolitan household; many diaspora couples will exceed $165k and fall out, even where FHG (no income-driven exclusion of this kind) still applies.
- **Frame the FHG-vs-Help-to-Buy fork as decision support, not advice.** Help to Buy means a far smaller mortgage and no LMI, but the government **shares the capital gain** and the buyer must eventually buy back or repay the share — a real trade-off against FHG's "keep 100% of the upside, pay LMI-free with a 5% deposit." Lay out the trade-off; the buyer chooses (ASIC line — informational only).

## Rules

The resolver rules the artifact compiler extracts as this doc's `content_json` (schema: [architecture.md §11.9](../../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification)). Everything above is `content_md`. Only the citizen/age/current-ownership/owner-occupier predicate is filled as `criteria`; the income-cap, equity-share, and places-available leaves are **resolver-derived** from the parameters below (banded/conditional/dynamic — not expressible as a single criteria bool).

```jsonc
{
  "fills": [
    { "leaf": "eligibility.help_to_buy.eligible",
      "rule": { "kind": "criteria", "combine": "all_of", "criteria": [
        { "field": "applicant.citizenship_status",      "op": "eq",  "value": "citizen" },   // ⚠ citizen ONLY — PRs excluded (diverges from FHG)
        { "field": "applicant.age",                      "op": "gte", "value": 18 },
        { "field": "applicant.currently_owns_property",  "op": "eq",  "value": false },        // CURRENT ownership AU or overseas; past owners who sold are OK
        { "field": "applicant.owner_occupier_intent",    "op": "eq",  "value": true } ] } }
    // income_cap_compliance, government_equity_percentage_offered, places_available are resolver-derived — see Notes
  ],
  "parameters": {
    "commencement_date":              { "type": "date",    "value": "2025-12-05" },
    "citizenship_required":           { "type": "string",  "value": "citizen" },             // PRs not eligible
    "min_age":                        { "type": "integer", "value": 18 },
    "min_deposit_percentage":         { "type": "percentage", "value": 2 },
    "income_cap_single":              { "type": "money_per_year", "value": 103000 },          // rose from 100000 on 1 Jul 2026; wage-indexed annually
    "income_cap_joint":               { "type": "money_per_year", "value": 165000 },          // also single parents; rose from 160000 on 1 Jul 2026; wage-indexed annually
    "equity_share_existing_home_max": { "type": "percentage", "value": 30 },
    "equity_share_new_home_max":      { "type": "percentage", "value": 40 },
    "annual_places":                  { "type": "integer", "value": 10000 },
    "total_places":                   { "type": "integer", "value": 40000 },                 // over the 4-year program — capped, unlike FHG
    "property_price_caps_capital": { "type": "lookup", "key": "property_fit.state", "table": {
      "NSW": 1300000, "VIC": 950000, "QLD": 1000000, "WA": 850000,
      "SA": 700000, "ACT": 900000, "NT": 700000, "TAS": null
    }, "note": "capital-city caps; regional caps are lower (postcode lookup); TAS null — no enabling legislation yet" },
    "non_participating_states":       { "type": "array<string>", "value": ["TAS"] }
  },
  "stacking": {
    "alternative_to": ["kb.scheme.fhg"],   // mutually exclusive — both address the deposit/LMI gap; scheme rules bar combining with other gov shared-equity/guarantee/loan programs
    "combines_with": ["kb.scheme.fhss"],    // FHSS = buyer's own super, sources the 2% deposit (not gov funding); state concessions/FHOG combine too but those edges are declared on the state docs (§11.9 convention)
    "order_hint": 20                        // same slot as FHG (its alternative) — a financing-structure decision made at loan approval
  }
}
```

Notes:

- **`income_cap_compliance`** (the `eligibility.help_to_buy.income_cap_compliance` leaf) is **resolver-derived**, not a flat fill: the resolver compares `profile.assessable_income` against `income_cap_single` when the buyer is single (`profile.buying_alone == true`) or `income_cap_joint` for joint applicants/single parents. Conditional threshold selection is control flow → resolver code, document-supplied numbers ("computed, not asserted").
- **`government_equity_percentage_offered`** is **resolver-derived** from `property_fit.property_type`: up to `equity_share_new_home_max` (40%) for new homes, up to `equity_share_existing_home_max` (30%) for existing. The "up to" ceiling is the scheme maximum; the actual share depends on the buyer's deposit and loan size (resolver/lender). Base scope (no property attached) reports the applicable maximum band provisionally.
- **`places_available`** is **dynamic/external** — it depends on current program take-up against `annual_places` and on whether the buyer's jurisdiction participates (`non_participating_states`). It is not a static KB value; the resolver sets it from program-availability state (an external source) and is provisional in base scope. The capped places (`total_places: 40000`) are the key contrast with FHG's post-Oct-2025 unlimited model.
- **`currently_owns_property` is a new profile fact** introduced to encode this scheme's *current*-ownership test — distinct from `ever_owned_au_property` / `prior_overseas_property_ownership`, which are historical and would wrongly disqualify a returning buyer. Surfaced via rule-encoding (the same way `prior_fhss_release` was), added to the `buyer_profile` fact surface in `fhb-domestic-au.md`.
- **`alternative_to: kb.scheme.fhg`** captures the central financing fork. The resolver should never include both in `applicable_schemes`; the recommendation reasons about the trade-off (smaller mortgage + shared gain vs full equity + LMI-free 5% deposit) and the buyer picks (ASIC: informational only).
- **State-side combine edges** (`help-to-buy` ↔ state duty concessions / FHOG) are declared on the state docs per §11.9, so they are absent here by design — not an omission.

## Sources

- First Home Buyers (Australian Government) — *Australian Government Help to Buy Scheme* (income caps $100k/$160k, equity 30%/40%, 2% deposit, citizen-only, current-ownership test, 10,000 places/year, owner-occupier) — https://firsthomebuyers.gov.au/australian-government-help-buy-scheme
- Housing Australia — *Applications now open for the Australian Government Help to Buy Scheme* (commenced 5 Dec 2025; 40,000 households; equity 30%/40%; initial lenders) — https://www.housingaustralia.gov.au/media/applications-now-open-australian-government-help-buy-scheme
- money.com.au — *Help to Buy Scheme Australia (2026 guide)* (price caps by state, exclusion of other gov shared-equity/guarantee/loan programs, allowed combination with FHOG and stamp-duty concessions) — https://www.money.com.au/home-loans/help-to-buy-scheme
- Treasury — *Supporting people into home ownership* (scheme policy context) — https://treasury.gov.au/policy-topics/housing/home-ownership-support
