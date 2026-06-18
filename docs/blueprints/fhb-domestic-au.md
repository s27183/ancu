# FHB plan card blueprint — Mode A (domestic, AU citizen/PR)

> Part of the **Vietnamese Diaspora Property Platform** document set. See [README.md](../README.md) for the full index.
>
> **This is a working specification** consumed by:
>
> - The offline KB agent (Claude Code + maintainer) to validate KB anchor coverage and renderer consistency
> - The user-facing planning agent at session time (loaded as system prompt context, rendered as plan card UI)
> - The migration script at deployment time to publish the blueprint into the `blueprints` table (replacing the prior deploy; git holds history)
>
> Companion specs (to be drafted next): [fhb-foreign-au.md](fhb-foreign-au.md) (Mode B), [investor-domestic-au.md](investor-domestic-au.md) (Mode C), [investor-foreign-au.md](investor-foreign-au.md) (Mode D).

---

## Metadata

```jsonc
{
  "blueprint_id": "fhb-domestic-au",
  "effective_from": "2026-05-19",
  "effective_until": null,
  "buyer_mode": "fhb",
  "user_mode": "A",
  "audience": "Vietnamese-Australian citizen or PR buying first home in Australia",
  "firb_required": false,
  "language_primary": "en",
  "language_alternate": "vi",
  "renderer_set": "fhb"
}
```

This blueprint serves **Mode A** users only — Vietnamese-Australian citizens and permanent residents buying their first home. Foreign-person flows (Mode B — students, 485 holders, Vietnam-located parents) are served by a separate blueprint (`fhb-foreign-au`) because ~50% of components differ structurally. See [§11.9 in architecture.md](../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification) for the rationale.

The `firb_required: false` metadata above is the blueprint's **entry assumption** — the *lead* applicant is a non-foreign person — not a guarantee for the whole purchase. FIRB is determined **per applicant** at runtime in `buyer_profile`: a foreign *co*-applicant in an otherwise Mode-A purchase (e.g. a citizen buying jointly with a temporary-resident partner, or a Vietnam-based parent on title) still trips the gate (`profile.firb_required_any`, constraint #10), and that applicant's interest is routed to the foreign-person path (`fhb-foreign-au`). See `buyer_profile` and `eligibility` below.

---

## Component pipeline

The blueprint is a directed pipeline of eleven components. Each component has a single goal, atomic group of actions, typed inputs from upstream components, and a typed outcome that feeds downstream. The agent reasons within a component and commits a structured outcome; downstream components read the outcome (not the upstream parameters individually).

### Component scope (base plan vs property addendum)

Each component has a `scope` indicating when it runs in the plan card lifecycle:

| Component | Scope | Runs when |
|---|---|---|
| 1 buyer_profile | `base` | Onboarding; persistent across plan lifetime |
| 2 property_assessment | `per-property` | When a specific property is attached (Tìm Nhà handoff, URL paste, browser extension, or partner REA push) |
| 3 eligibility | `both` | Base: provisional scheme stack from profile facts + target price range at onboarding; refined per-property against the specific property's location + price |
| 4 mortgage_finance | `both` | Base estimate of borrowing capacity + lender shortlist + debt-optimisation recommendations at onboarding; refined per-property when loan amount known |
| 5 cash_position | `both` | Base estimate against target price range at onboarding; refined per-property in addendum |
| 6 buying_strategy | `per-property` | When user signals readiness to bid on a specific property |
| 7 due_diligence | `per-property` | When user uploads documents for a specific property |
| 8 settlement_prep | `per-property` | Activated when contract is signed on a specific property |
| 9 ownership_planning | `both` | Base estimate of ongoing costs at onboarding; refined per-property post-settlement |
| 10 purchase_journey | `base` | Onboarding; the property-agnostic whole-of-journey lifecycle overview (swimlane). Distinct from `settlement_prep` (8), which is the per-property settlement checklist. |
| 11 preparation | `base` | Onboarding; the property-agnostic readiness layer (document checklist, people to engage, money buffer) — the prototype's "Before you buy" content, surfaced before any property is attached. Distinct from `due_diligence` (7), the per-property document-risk review. |

Components with `scope: base` fill **once per user** in the persistent base plan. Components with `scope: per-property` fill **once per property** the user attaches, creating a property addendum on the plan card. Components with `scope: both` have a base form (using target price range and suburb medians) and a refined form (using specific property data).

```
[1] buyer_profile
       │   outcome: profile  (includes debts: hecs, credit cards, BNPL, loans)
       ▼
[2] property_assessment ◄── property_card from selection (per-property scope)
       │   outcome: property_fit
       ▼
[3] eligibility ◄── profile, property_fit
       │   outcome: scheme_stack
       ▼
[4] mortgage_finance ◄── profile (incl. debts), scheme_stack
       │   outcome: mortgage_plan (lender shortlist, debt optimisations, loan path)
       ▼
[5] cash_position ◄── profile, property_fit, scheme_stack, mortgage_plan
       │   outcome: budget_envelope, gap_analysis
       ▼
[6] buying_strategy ◄── property_fit, budget_envelope, mortgage_plan
       │   outcome: bid_plan
       ▼
[7] due_diligence ◄── property_fit, uploaded_docs
       │   outcome: risk_assessment
       ▼
[8] settlement_prep ◄── scheme_stack, property_fit, bid_plan, mortgage_plan
       │   outcome: settlement_checklist
       ▼
[9] ownership_planning ◄── property_fit, scheme_stack, cash_position, mortgage_plan
           outcome: ongoing_obligations, alert_triggers
```

> The diagram shows the acquisition pipeline (components 1–9). The two base-scope **projection** components — `purchase_journey` (10) and `preparation` (11) — read several of these outcomes and *place* their already-computed figures (they compute none of their own); see the full dependency graph at the end of this document.

**UI tab mapping** — the eleven components are presented across seven UI tabs, ordered as a single **guided lifecycle rail** (Son's point 1): the tabs are not independent pills but one container that walks the buyer through the journey — overview first, the interactive financial spine second, then the legal/temporal spine, then the phase detail, then Q&A last.

| # | UI tab | Components rendered |
|---|---|---|
| 1 | Overview | "what this is" plan summary + aggregated read of `buyer_profile` + `eligibility` + `mortgage_finance` + `cash_position` |
| 2 | Cash calculator | `cash_position` rendered as the interactive **financial spine** (phased cash-flow + what-if form) |
| 3 | Journey | `purchase_journey` (base lifecycle swimlane — the **legal spine**) → `settlement_prep` (per-property, refines the Settle phase) |
| 4 | Before you buy | `preparation` (readiness — NEW) + `eligibility` + `cash_position` (detail) + `due_diligence` (per-property) |
| 5 | Buying | `buying_strategy` |
| 6 | After you buy | `ownership_planning` |
| 7 | Q&A | bilingual planning-agent chat (a shell surface over the engine Q&A stream — `kind: "qa"`, not a `component_filled`) |

UI tab assignment is a presentation concern; the blueprint defines the data model and reasoning structure. The two **spines** (calculator + swimlane) and the shared `cash_events` primitive both spines project are specified in [`../architecture/lifecycle-simulation-model.md`](../architecture/lifecycle-simulation-model.md); the segmented-rail UX and the explore→save simulation flow are specified in [`../04-ux-model.md`](../04-ux-model.md).

**Machine-readable form** — compiled to `ui_tabs` in the artifact and **canonical for the runtime** (the table above is the human view). Tabs render in the order listed (the lifecycle rail). `kind: synthesis` is a shell-composed summary (not a vocabulary renderer); `kind: "qa"` is the shell's chat surface over the engine's bilingual Q&A stream (no component fills it); `interactive: true` marks the calculator's what-if form (cash-on-hand resolves client-side; a *structural* what-if runs a free engine `simulate` preview — lifecycle-simulation-model §4, engine-contract §10). The `journey` tab leads with `purchase_journey` (the base lifecycle swimlane) and falls through to the per-property `settlement_prep` (an "attach a property" affordance until a property is attached). See [`../architecture/plan-card-lifecycle-restoration.md`](../architecture/plan-card-lifecycle-restoration.md) §3.2/§5/§7.

```jsonc
{
  "ui_tabs": [
    { "tab_id": "overview",        "kind": "synthesis",  "components": ["buyer_profile", "eligibility", "mortgage_finance", "cash_position"] },
    { "tab_id": "cash_calculator", "kind": "components", "interactive": true, "components": ["cash_position"] },
    { "tab_id": "journey",         "kind": "components", "components": ["purchase_journey", "settlement_prep"] },
    { "tab_id": "before_you_buy",  "kind": "components", "components": ["preparation", "eligibility", "cash_position", "due_diligence"] },
    { "tab_id": "buying",          "kind": "components", "components": ["buying_strategy"] },
    { "tab_id": "after_you_buy",   "kind": "components", "components": ["ownership_planning"] },
    { "tab_id": "qa",              "kind": "qa",         "components": [] }
  ]
}
```

---

## Components

### 1. buyer_profile

**Goal:** Capture and structure the buyer's situation — citizenship, residency, age, ownership history, income, savings, debt, family financial pooling, employment.

**Inputs:** User questions answered in chat; any uploaded documents (employer letter, NOA, payslips, bank statements). No upstream component dependency — this is the pipeline entry.

**KB anchors:** `kb.hecs.thresholds`, `kb.firb.status-determination`, `kb.lender.serviceability-basics`

**Renderer:** `summary-card`

**UI tab hint:** Overview (collapsed) + Before you buy (detail)

**Parameters:**

```jsonc
{
  "application": {
    "location_state": { "type": "enum", "options": ["NSW", "VIC", "QLD", "WA", "SA", "TAS", "ACT", "NT"], "value": "<initial>" },
    "applicant_count": { "type": "integer", "value": 1, "note": "= applicants[] length. Replaces the old buying_alone / co_buyer_count (buying_alone ≡ applicant_count == 1; co_buyer_count ≡ applicant_count − 1)." },
    "dependents_count": { "type": "integer", "value": 0 },
    "intended_occupancy_use": { "type": "enum", "options": ["sole_occupier", "partial_rental", "granny_flat", "not_occupied"], "value": "sole_occupier", "note": "F12 — DWELLING-level use, distinct from each applicant's owner_occupier_intent (who lives there). partial_rental (rent a room) / granny_flat flips the land-tax PPOR exemption, the CGT main-residence exemption, and can breach a scheme's occupancy condition; not_occupied puts the purchase outside owner-occupier schemes entirely (and, for a foreign applicant, into investor/FIRB territory). Drives ownership_planning.land_tax_check." }
  },
  "applicants": {
    "type": "array<applicant>",
    "note": "F1 — one entry per person taking a legal/ownership interest (on title and/or the loan). The eligibility-bearing facts (citizenship, FIRB status, owner-occupier intent, ownership history) are PER-APPLICANT — they vary by person. The FIRB gate (constraint #10) and every FHB scheme's all-applicants test resolve over THIS ARRAY, not over a single primary buyer: a foreign co-applicant in an otherwise Mode-A purchase still trips the gate, and most FHB schemes require EVERY applicant to satisfy the first-home + residency tests. Mode A is ENTERED by a non-foreign lead applicant; a foreign co-applicant's interest is routed to the FIRB path (see eligibility + fhb-foreign-au). A non-buying spouse/partner is NOT in this array — that fact is captured separately (couple-as-one schemes) [F4, pending].",
    "value": [
      {
        "role": { "type": "enum", "options": ["primary", "co_buyer"], "value": "primary" },
        "citizenship_status": { "type": "enum", "options": ["citizen", "permanent_resident", "temporary_resident", "non_resident"], "value": "<initial>" },
        "firb_status": { "type": "enum", "options": ["not_foreign_person", "foreign_person"], "value": "<initial>", "derived_from": "citizenship_status" },
        "tax_residency": { "type": "enum", "options": ["resident", "non_resident", "temporary_resident_for_tax"], "value": "<initial>", "note": "F2 — current tax residency, DISTINCT from citizenship/FIRB: a citizen living overseas is a non-foreign person (FIRB) yet may be a non-resident for tax (no CGT main-residence exemption, no 50% discount, possible land-tax surcharge) and may not be able to meet a scheme's occupancy requirement. Pairs with current_residence_country." },
        "current_residence_country": { "type": "string", "value": "<initial>", "note": "F2 — ISO country of current residence. AU vs overseas gates the feasibility of scheme occupancy requirements (move in within 12 months, reside 6–12)." },
        "age": { "type": "integer", "value": "<initial>" },
        "owner_occupier_intent": { "type": "bool", "value": true },
        "ownership_history": {
          "ever_owned_au_property": { "type": "bool", "value": "<initial>" },
          "ever_owned_and_occupied_residence": { "type": "bool", "value": "<initial>", "note": "F3 — has this applicant ever owned a home they OCCUPIED as a residence (AU or overseas). Distinct from ever_owned_au_property, which counts investment-only ownership too: some first-home tests turn on prior OCCUPATION, not mere ownership, so a rentvestor who never lived in an investment property can still qualify for those. Each scheme's criteria decides." },
          "years_since_last_au_property_interest": { "type": "integer", "value": "<initial>", "note": "0 / none if never owned AU property; else years since last disposal — feeds FHG 10-yr re-entry" },
          "prior_overseas_property_ownership": { "type": "bool", "value": false, "note": "Mode A diaspora hook — NON-disqualifying for FEDERAL schemes (FHG/FHSS test AU only), but some STATE concessions test residences worldwide and disqualify on it (e.g. kb.scheme.qld.fhnhc). Neutral fact; each scheme's criteria decides." },
          "prior_fhss_release": { "type": "bool", "value": false, "note": "FHSS scheme-usage history (one valid release per lifetime) — not property ownership; a first-home eligibility gate, feeds eligibility.fhss.eligible" },
          "currently_owns_property": { "type": "bool", "value": "<initial>", "note": "CURRENT ownership of any residential property in Australia OR overseas — distinct from the historical ever_owned_au_property / prior_overseas_property_ownership facts. Feeds Help to Buy's 'cannot currently own' test (kb.scheme.help-to-buy), which admits past owners who have since sold ('returning to home ownership'). Neutral fact; each scheme's criteria decides." }
        }
      }
    ],
    "_item_note": "Each array entry is one applicant with the shape shown above; the single example entry illustrates the per-applicant leaf schema. At runtime the array has one entry per buyer."
  },
  "non_buying_partner": {
    "exists": { "type": "bool", "value": false, "note": "F4 — a spouse / de-facto partner who is NOT on title or the loan (so not in applicants[]). FHOG and most state concessions test a married / de-facto COUPLE as one, so this partner's ownership can disqualify the buyer even though they take no legal interest. Captured separately for exactly that reason." },
    "relationship": { "type": "enum", "options": ["spouse", "de_facto", "none"], "value": "none" },
    "ownership_history": {
      "ever_owned_au_property": { "type": "bool", "value": "<initial>" },
      "ever_owned_and_occupied_residence": { "type": "bool", "value": "<initial>", "note": "F4 — same occupation-based distinction as the per-applicant field (F3); some couple-as-one tests turn on occupation, not mere ownership." },
      "currently_owns_property": { "type": "bool", "value": "<initial>", "note": "CURRENT ownership AU or overseas — feeds the couple-as-one current-ownership test (e.g. FHG, Help to Buy)." }
    }
  },
  "income": {
    "primary_taxable_income": { "type": "money_per_year", "value": "<initial>" },
    "secondary_income": { "type": "money_per_year", "value": 0 },
    "income_stability": { "type": "enum", "options": ["permanent_payg", "contractor", "self_employed", "casual", "mixed"], "value": "<initial>" },
    "foreign_sourced_component": { "type": "money_per_year", "value": 0, "note": "F6 — portion of income paid from OUTSIDE Australia (e.g. a Vietnamese business or employer). Lenders haircut or exclude offshore/FX income in serviceability, so mortgage_finance needs the source, not just the amount. Domestic self-employment is already captured by income_stability; this is specifically the cross-border case." },
    "foreign_income_currency": { "type": "string", "value": "<initial>", "note": "F6 — ISO currency of any foreign-sourced income (FX conversion + lender treatment); null if all income is AUD/AU-sourced." }
  },
  "savings_and_deposit": {
    "cash_savings": { "type": "money", "value": "<initial>" },
    "genuine_savings_evidence_months": { "type": "integer", "value": "<initial>" },
    "family_gift_or_loan_amount": { "type": "money", "value": 0 },
    "fhss_contributions_to_date": { "type": "money", "value": 0 },
    "funds_provenance": {
      "deposit_source": { "type": "enum", "options": ["genuine_savings", "family_gift", "family_loan", "sale_of_asset", "inheritance", "mixed"], "value": "<initial>", "note": "F5 — where the deposit comes from, distinct from the AMOUNT (family_gift_or_loan_amount). Source drives BOTH the lender's genuine-savings test and AUSTRAC source-of-funds expectations." },
      "cross_border_transfer": { "type": "bool", "value": false, "note": "F5 — true if any deposit funds are transferred from overseas (e.g. parents in Vietnam)." },
      "transfer_channel": { "type": "string", "value": "<initial>", "note": "F5 — the licensed channel for any cross-border transfer (bank / Wise / OFX / partner bank). VN capital controls: the route must be SBV-compliant; we educate on legitimate channels and never recommend informal ones (CLAUDE.md hard constraint). Informational only — we are never custodian of funds (AUSTRAC)." }
    }
  },
  "debts": {
    "hecs_balance": { "type": "money", "value": "<initial>" },
    "credit_card_limits_total": { "type": "money", "value": "<initial>" },
    "personal_loans_balance": { "type": "money", "value": 0 },
    "car_loan_balance": { "type": "money", "value": 0 },
    "buy_now_pay_later_balance": { "type": "money", "value": 0 }
  },
  "timeline": {
    "target_purchase_months": { "type": "integer", "value": "<initial>" },
    "already_pre_approved": { "type": "bool", "value": false }
  },
  "purchase_target": {
    "target_price_range": { "type": "money_range", "value": "<initial>", "note": "from onboarding (constraint #1) — base-scope cap + cash checks run against this until a property is attached" },
    "target_zone": { "type": "array<string>", "value": "<initial>", "note": "onboarding map-zone — target suburbs / regions" }
  }
}
```

**Outcome schema:** `profile`

```jsonc
{
  "type": "profile",
  "fields": {
    // legal-status & personal facts — PER-APPLICANT (F1). The eligibility fact surface is the applicant SET, not a single buyer.
    "applicants": "array<{ role, citizenship_status, firb_required, tax_residency, current_residence_country, age, owner_occupier_intent, ever_owned_au_property, ever_owned_and_occupied_residence, years_since_last_au_property_interest, prior_overseas_property_ownership, prior_fhss_release, currently_owns_property }>",  // each entry's facts feed FHG 10-yr re-entry, FHSS one-release, Help to Buy current-ownership, the worldwide-ownership state tests, occupation-based first-home tests [F3], and non-resident tax / occupancy feasibility [F2]
    "applicant_count": "integer",
    "firb_required_any": "bool",                      // derived: TRUE if ANY applicant is a foreign person — fires the FIRB gate (constraint #10) and routes that applicant's interest to the foreign-person path (fhb-foreign-au). Per-applicant firb_required lives inside applicants[].
    "non_buying_partner": "{ exists, relationship, ever_owned_au_property, ever_owned_and_occupied_residence, currently_owns_property } | null",  // F4 — couple-as-one: the eligibility resolver folds this partner's ownership into the all-applicants test even though they hold no legal interest
    "intended_occupancy_use": "enum [sole_occupier, partial_rental, granny_flat, not_occupied]",  // F12 — dwelling-use; feeds land_tax_check, CGT main-residence, and scheme occupancy compliance
    // neutral derived financials (facts, not verdicts) — household-level
    "assessable_income": "money_per_year",            // combined; per-scheme income caps (Help to Buy) decide individual-vs-combined
    "foreign_sourced_income_component": "money_per_year",  // F6 — offshore/FX portion lenders may haircut or exclude; mortgage_finance reads this, not just the total
    "approx_borrowing_capacity": "money_range",       // computed from combined income − debts
    "deposit_ready_for_purchase_amount": "money",     // cash + family + FHSS available
    // purchase-target facts (onboarding) — base-scope cap + cash checks run against these
    "target_price_range": "money_range",
    "target_zone": "array<string>",
    // narrative
    "key_constraints": "array<localized_text>",
    "key_strengths": "array<localized_text>"
    // REMOVED fhg_eligible_basic — a scheme verdict; now computed in `eligibility` (zero downstream readers, confirmed)
  }
}
```

---

### 2. property_assessment

**Goal:** Analyse the selected property for fit against the buyer's profile and produce a viability read.

**Inputs:** `property_card` (from user selection on map/URL paste) + `buyer_profile.outcome`

**KB anchors:** `kb.property.suburb-risk-factors`, `kb.property.comparables-methodology`, `kb.strata.health-indicators`, `kb.building-types.risk-by-type`

**Renderer:** `summary-card`

**UI tab hint:** Overview

**Parameters:**

```jsonc
{
  "basics": {
    "address": { "type": "string", "value": "<from_property_card>" },
    "suburb": { "type": "string", "value": "<from_property_card>" },
    "state": { "type": "enum", "value": "<from_property_card>" },
    "lga": { "type": "string", "value": "<from_suburb>", "note": "ABS local government area — neutral geo fact; feeds each scheme's own region tiering (e.g. FHG location_tier)" },
    "is_capital_city": { "type": "bool", "value": "<from_suburb>", "note": "neutral geo fact — property is in the state capital LGA" },
    "price": { "type": "money", "value": "<from_property_card>" },
    "property_type": { "type": "enum", "options": ["established_house", "established_apartment", "new_house", "new_apartment", "off_the_plan", "house_and_land", "vacant_land"], "value": "<from_property_card>" },
    "bedrooms": { "type": "integer", "value": "<from_property_card>" },
    "bathrooms": { "type": "integer", "value": "<from_property_card>" },
    "parking_spaces": { "type": "integer", "value": "<from_property_card>" }
  },
  "location_factors": {
    "flood_risk_band": { "type": "enum", "options": ["none", "low", "medium", "high", "unknown"], "value": "<from_suburb>" },
    "school_catchment_quality": { "type": "enum", "options": ["strong", "average", "weak", "unknown"], "value": "<from_suburb>" },
    "transport_score": { "type": "integer_0_100", "value": "<from_suburb>" },
    "vietnamese_community_proximity": { "type": "enum", "options": ["high", "medium", "low"], "value": "<from_suburb>" },
    "planning_changes_pending": { "type": "array<string>", "value": "<from_suburb>" }
  },
  "market_position": {
    "comparable_sales": { "type": "array<comparable_sale>", "value": [], "agent_reasoning_required": true, "reasoning_domain": "valuation" },
    "estimated_market_value_range": { "type": "money_range", "value": "<initial>", "agent_reasoning_required": true, "reasoning_domain": "valuation" },
    "asking_price_vs_market": { "type": "enum", "options": ["below_market", "fair", "above_market", "significantly_above"], "value": "<initial>", "agent_reasoning_required": true, "reasoning_domain": "valuation" },
    "days_on_market": { "type": "integer", "value": "<from_property_card>" }
  },
  "strata_or_building": {
    "applicable": { "type": "bool", "value": "<initial>", "derived_from": "basics.property_type" },
    "body_corporate_quarterly_fees": { "type": "money", "value": "<from_document>" },
    "sinking_fund_balance": { "type": "money", "value": "<from_document>" },
    "special_levies_in_last_3_years": { "type": "array<string>", "value": "<from_document>" },
    "structural_red_flags": { "type": "array<string>", "value": "<from_document>" }
  },
  "fit_against_buyer": {
    "price_within_borrowing_capacity": { "type": "bool", "value": "<initial>" },
    // price_within_scheme_cap removed — it is eligibility.fhg's cap criterion (property.price ≤ applicable_cap);
    // property_assessment runs before eligibility in the DAG and cannot know the cap. See eligibility component.
    "lifestyle_match_score": { "type": "integer_0_10", "value": "<initial>", "agent_reasoning_required": true, "reasoning_domain": "lifestyle_fit" }
  }
}
```

**Outcome schema:** `property_fit`

```jsonc
{
  "type": "property_fit",
  "fields": {
    // neutral property facts (the per-property fact surface) — the only route downstream
    // components (eligibility, mortgage_finance) read property data; never via basics.* params (§11.9 one access path)
    "state": "enum [NSW, VIC, QLD, WA, SA, TAS, ACT, NT]",
    "suburb": "string",
    "lga": "string",                                  // ABS LGA — feeds each scheme's own region tiering
    "is_capital_city": "bool",                        // neutral; FHG tier = capital OR designated regional centre
    "price": "money",
    "property_type": "enum [established_house, established_apartment, new_house, new_apartment, off_the_plan, house_and_land, vacant_land]",
    // viability verdicts/narrative (this component's own reasoning)
    "viability_verdict": "enum [proceed, proceed_with_caution, reconsider]",
    "key_strengths": "array<string>",
    "key_concerns": "array<string>",
    "market_price_assessment": "string",
    "scheme_eligibility_hint": "string"               // soft hint only — property_assessment runs before eligibility; authoritative verdict is eligibility.outcome
  }
}
```

---

### 3. eligibility

**Goal:** Determine all applicable schemes and produce an optimal stacked scheme stack with rationale for inclusion/exclusion.

**Scope:** `both` — base: provisional eligibility from profile facts + `target_price_range` (which schemes apply; FHG / FHSS / state-concession predicates; target-range-vs-cap check) **plus each scheme's benefit as a `money_range` quantified from the price range** (Decision 8 in [`eligibility-resolution.md`](../architecture/eligibility-resolution.md): duty saving via the shared `fh_engine_cash`, FHOG fixed, FHG LMI band; FHSS/Help-to-Buy honestly null). Refined per-property once the specific property's location + price are known (`applicable_cap_for_location_property`, `fhog.applicable`) — the ranges narrow to points.

**All-applicants resolution (F1).** Every scheme predicate resolves as the **AND over all `profile.applicants`** — a scheme is applicable to the joint application only if *every* applicant satisfies its first-home + residency + ownership tests. Two consequences: (a) if `profile.firb_required_any` is true (a foreign co-applicant), FHB schemes are unavailable to the joint application and that applicant's interest follows the FIRB path (`fhb-foreign-au`); (b) where the joint application fails an all-applicants test but a subset would qualify (e.g. the eligible applicant buying alone), the alternative is surfaced in `scheme_stack.structuring_options` rather than silently dropped. Per-scheme individual-vs-combined nuances (e.g. Help to Buy income caps) are resolved against the relevant applicants, not assumed joint. The test also folds in `profile.non_buying_partner` where present — a married / de-facto partner's ownership counts for FHOG and state concessions even when they take no legal interest (F4).

**Inputs:** base — `buyer_profile.outcome` (incl. `target_price_range`, `target_zone`); per-property — adds `property_assessment.outcome`

**KB anchors:** `kb.scheme.fhg`, `kb.scheme.fhss`, `kb.scheme.help-to-buy`, `kb.scheme.qld.fhc`, `kb.scheme.qld.fhnhc`, `kb.scheme.qld.fh-vacant-land`, `kb.scheme.vic.fhb-duty`, `kb.scheme.vic.fhog`, `kb.scheme.nsw.fhbas`, `kb.scheme.nsw.fhog`

**Renderer:** `scheme-stack-card`

**UI tab hint:** Overview (summary) + Before you buy (detail)

**Parameters:**

```jsonc
{
  "fhg": {
    "eligible": { "type": "bool", "value": "<initial>" },
    "applicable_cap_for_location_property": { "type": "money", "value": "<initial>" },
    "deposit_percentage_required": { "type": "percentage", "value": 5 },
    "lmi_savings_estimate": { "type": "money", "value": "<initial>" },
    "constraints": { "type": "array<string>", "value": [] }
  },
  "fhss": {
    "eligible": { "type": "bool", "value": "<initial>" },
    "available_release_amount": { "type": "money", "value": "<initial>" },
    "tax_offset_estimate": { "type": "money", "value": "<initial>" },
    "release_timeline_business_days": { "type": "integer", "value": 25 },
    "contract_window_months_after_release": { "type": "integer", "value": 12 }
  },
  "help_to_buy": {
    "eligible": { "type": "bool", "value": "<initial>" },
    "income_cap_compliance": { "type": "bool", "value": "<initial>" },
    "government_equity_percentage_offered": { "type": "percentage", "value": "<initial>" },
    "places_available": { "type": "bool", "value": "<initial>" }
  },
  "state_concession": {
    "scheme_name": { "type": "string", "value": "<initial>" },
    "applicable": { "type": "bool", "value": "<initial>" },
    "duty_savings": { "type": "money", "value": "<initial>" },
    "concession_type": { "type": "enum", "options": ["full_exemption", "partial_concession", "no_concession"], "value": "<initial>" }
  },
  "fhog": {
    "applicable": { "type": "bool", "value": "<initial>", "derived_from": "property_fit.property_type" },
    "amount": { "type": "money", "value": "<initial>" }
  }
}
```

**Outcome schema:** `scheme_stack`

```jsonc
{
  "type": "scheme_stack",
  "fields": {
    "applicable_schemes": "array<{ name, benefit_value: money_range, benefit_is_estimate: bool, role, notes: array<localized_text> }>",  // Decision 8 — benefit_value is a money_range (base: from target_price_range; per-property: narrowed). null when honestly unknown (FHSS/Help-to-Buy at base). benefit_is_estimate marks a banded estimate (FHG LMI) vs an exact regulated figure (duty, FHOG).
    "rejected_schemes": "array<{ name, reason: localized_text }>",
    "eligibility_basis": "enum [all_applicants_eligible, eligible_only_if_restructured, ineligible]",  // F1 — result of the all-applicants test over profile.applicants
    "structuring_options": "array<{ if_purchased_as, applicable_schemes, benefit_value: money_range, tradeoffs }>",  // F1 — populated when the joint application fails an all-applicants test but a subset qualifies (e.g. {if_purchased_as: 'lead applicant alone'}); also carries the foreign-co-applicant → FIRB-path note. Empty when all applicants qualify jointly.
    "total_benefit_value": "money_range",  // Decision 8 — sum over a COMPATIBLE stack (never alternatives together); excludes null-benefit schemes (noted).
    "stacking_constraints": "array<localized_text>",
    "recommended_application_order": "array<string>"
  }
}
```

---

### 4. mortgage_finance

**Goal:** Determine optimal loan structure and lender shortlist — *with explicit debt-impact reasoning (HECS, credit cards, BNPL) and the FHG-backed vs LMI-payable path comparison*.

**Inputs:** `buyer_profile.outcome` (profile — including debts) + `eligibility.outcome` (scheme_stack — particularly FHG eligibility and slot reservation availability)

**KB anchors:** `kb.lender.serviceability-basics`, `kb.lender.fhg-panel-list`, `kb.lender.hecs-treatment-by-lender`, `kb.lender.credit-card-treatment`, `kb.lender.bnpl-treatment-2026`, `kb.lmi.calculation`, `kb.lmi.providers`, `kb.offset-account.basics`, `kb.refinance.windows-and-triggers`

**Renderer:** `summary-card` + `data-table`

**UI tab hint:** Before you buy (detail) + Overview (summary)

**Scope:** `both` — base estimate against profile + target price range; refined per-property when specific property's loan amount is known

**Parameters:**

```jsonc
{
  "borrowing_capacity": {
    "with_current_debts": { "type": "money_range", "value": "<initial>" },
    "if_hecs_cleared": { "type": "money_range", "value": "<initial>" },
    "if_unused_credit_cards_closed": { "type": "money_range", "value": "<initial>" },
    "if_all_optimisations_applied": { "type": "money_range", "value": "<initial>" },
    "lender_buffer_rate_assumed": { "type": "percentage", "value": "<initial>", "note": "APRA-mandated buffer typically +3% above advertised rate" }
  },
  "debt_optimisation_recommendations": {
    "hecs": {
      "current_balance": { "type": "money", "value": "<from_buyer_profile>" },
      "clear_before_application_recommended": { "type": "bool", "value": "<initial>" },
      "estimated_capacity_uplift_if_cleared": { "type": "money", "value": "<initial>" },
      "trade_off_cash_drain": { "type": "money", "value": "<initial>" },
      "reasoning": { "type": "string", "value": "<initial>" }
    },
    "credit_cards": {
      "close_unused_cards_recommended": { "type": "bool", "value": "<initial>" },
      "limits_to_reduce": { "type": "array<string>", "value": [] },
      "estimated_capacity_uplift": { "type": "money", "value": "<initial>" }
    },
    "bnpl": {
      "close_before_application_recommended": { "type": "bool", "value": "<initial>" },
      "accounts_affected": { "type": "array<string>", "value": [] }
    },
    "personal_or_car_loans": {
      "consolidate_or_clear_recommended": { "type": "bool", "value": "<initial>" },
      "reasoning": { "type": "string", "value": "<initial>" }
    }
  },
  "loan_path_comparison": {
    "fhg_backed_path": {
      "applicable": { "type": "bool", "value": "<from_eligibility>" },
      "deposit_percentage_required": { "type": "percentage", "value": 5 },
      "lmi_payable": { "type": "money", "value": 0 },
      "fhg_slot_reservation_required": { "type": "bool", "value": true },
      "panel_lender_shortlist": { "type": "array<{ lender, rate_range, processing_time }>", "value": [] }
    },
    "lmi_backed_path_5_to_20_deposit": {
      "deposit_percentage_required": { "type": "percentage", "value": "<initial>" },
      "lmi_payable_estimate": { "type": "money", "value": "<initial>" },
      "lmi_capitalised_into_loan": { "type": "bool", "value": true },
      "shortlist_if_fhg_not_available": { "type": "array<{ lender, rate_range, processing_time }>", "value": [] }
    },
    "twenty_plus_deposit_path": {
      "lmi_payable": { "type": "money", "value": 0 },
      "broader_lender_shortlist": { "type": "array<{ lender, rate_range, processing_time }>", "value": [] }
    },
    "recommended_path": { "type": "enum", "options": ["fhg_backed", "lmi_5_to_20", "twenty_plus", "user_specific_alternative"], "value": "<initial>" },
    "recommended_path_reasoning": { "type": "string", "value": "<initial>" }
  },
  "loan_structure": {
    "principal_and_interest_vs_interest_only": { "type": "enum", "options": ["principal_and_interest", "interest_only", "split"], "value": "principal_and_interest", "note": "Mode A FHB typically P&I" },
    "fixed_vs_variable": { "type": "enum", "options": ["variable", "fixed_1yr", "fixed_2yr", "fixed_3yr", "split_fixed_variable"], "value": "<initial>", "agent_reasoning_required": true, "reasoning_domain": "lender_fit" },
    "offset_account_included": { "type": "bool", "value": "<initial>" },
    "offset_strategy": { "type": "string", "value": "<initial>" }
  },
  "lender_synthesis": {
    "most_likely_approval_lenders": { "type": "array<{ lender, approval_likelihood, reasoning }>", "value": [], "agent_reasoning_required": true, "reasoning_domain": "lender_fit" },
    "lenders_with_lenient_hecs": { "type": "array<string>", "value": [] },
    "lenders_with_lenient_genuine_savings": { "type": "array<string>", "value": [] },
    "broker_vs_direct_recommendation": { "type": "enum", "options": ["broker", "direct", "either"], "value": "broker" }
  },
  "pre_approval_workflow": {
    "documents_required": { "type": "array<{ document, status }>", "value": [] },
    "expected_processing_time_days": { "type": "integer", "value": "<initial>" },
    "pre_approval_validity_days": { "type": "integer", "value": 90 },
    "pre_approval_granted_date": { "type": "date", "value": "<initial>", "note": "F11 — when conditional pre-approval was granted; null until granted." },
    "pre_approval_expiry_date": { "type": "date", "value": "<initial>", "derived_from": "pre_approval_granted_date + pre_approval_validity_days", "note": "F11 — TRACKED expiry, not just a static validity window. The engine fires a re-application alert as this date approaches (the alerting mechanism is engine-owned; this is the date it watches). Common for slower, often overseas-coordinated, buyers who search > 90 days." },
    "reapplication_required": { "type": "bool", "value": false, "note": "F11 — set when pre_approval_expiry_date passes before a property is secured. Triggers a fresh serviceability + pre-approval cycle, since capacity and rates may have moved since the original assessment." }
  },
  "refinance_planning": {
    "fixed_rate_roll_off_date": { "type": "date", "value": "<initial>" },
    "lvr_graduation_estimate_year": { "type": "number", "value": "<initial>", "note": "When LVR < 80% — FHG ends, free refinance window opens" },
    "refinance_review_cadence_months": { "type": "integer", "value": 24 }
  }
}
```

**Outcome schema:** `mortgage_plan`

```jsonc
{
  "type": "mortgage_plan",
  "fields": {
    "recommended_path": "enum",
    "expected_borrowing_capacity": "money_range",
    "debt_optimisations_to_action": "array<{ action, expected_uplift, urgency }>",
    "recommended_lender_shortlist": "array<{ lender, reasoning: localized_text, approval_likelihood }>",
    "loan_structure_recommendation": "object",
    "pre_approval_action_plan": "array<localized_text>",
    "pre_approval_expiry": "date",                    // F11 — tracked expiry the engine watches for a re-application alert; null until pre-approval granted
    "reapplication_required": "bool",                 // F11 — true once expiry lapses before a property is secured
    "key_assumptions": "array<localized_text>"
  }
}
```

The `mortgage_plan` outcome feeds `cash_position` (loan amount + buffer requirements), `buying_strategy` (financing condition in offers), `settlement_prep` (lender milestones), and `ownership_planning` (refinance windows + LVR graduation tracking).

---

### 5. cash_position

**Goal:** Compute the buyer's full cash needs at settlement, identify any gap, and produce a budget envelope and verdict.

**Inputs:** `buyer_profile.outcome` + `property_assessment.outcome` + `eligibility.outcome`

**KB anchors:** `kb.stamp-duty.calc-by-state`, `kb.buyer-costs.inspections-conveyancing-fees`, `kb.cash-reserve.lender-expectations`, `kb.lmi.calculation`

**Renderer:** `calculator`

**UI tab hint:** Cash calculator (interactive) + Before you buy (summary)

**Parameters:**

```jsonc
{
  "inputs": {
    "property_price": { "type": "money", "value": "<from_property_assessment>" },
    "cash_on_hand": { "type": "money", "value": "<from_buyer_profile>" },
    "fhss_release_planned": { "type": "money", "value": "<from_eligibility>" },
    "family_contribution": { "type": "money", "value": "<from_buyer_profile>" }
  },
  "deposit": {
    "minimum_required_percentage": { "type": "percentage", "value": 5 },
    "minimum_required_amount": { "type": "money", "value": "<initial>" },
    "recommended_amount": { "type": "money", "value": "<initial>" }
  },
  "stamp_duty": {
    "before_concession": { "type": "money", "value": "<initial>" },
    "concession_applied": { "type": "money", "value": "<initial>" },
    "after_concession": { "type": "money", "value": "<initial>" }
  },
  "other_buying_costs": {
    "building_pest_inspection": { "type": "money", "value": "<initial>" },
    "conveyancing": { "type": "money", "value": "<initial>" },
    "lender_application_fee": { "type": "money", "value": "<initial>" },
    "mortgage_registration_fee": { "type": "money", "value": "<initial>" },
    "title_transfer_fee": { "type": "money", "value": "<initial>" },
    "first_year_building_insurance": { "type": "money", "value": "<initial>" },
    "utility_connections": { "type": "money", "value": "<initial>" },
    "moving_costs": { "type": "money", "value": "<initial>" }
  },
  "reserve_buffer": {
    "months_of_repayments_recommended": { "type": "integer", "value": 3 },
    "amount": { "type": "money", "value": "<initial>" }
  },
  "totals": {
    "total_cash_required_at_settlement": { "type": "money", "value": "<initial>" },
    "cash_available": { "type": "money", "value": "<initial>" },
    "cash_gap_or_surplus": { "type": "money", "value": "<initial>" },
    "verdict": { "type": "enum", "options": ["surplus", "tight", "short"], "value": "<initial>" }
  }
}
```

**Outcome schema:** `budget_envelope`

```jsonc
{
  "type": "budget_envelope",
  "fields": {
    "stamp_duty": "{ before_concession: money|null, concession_applied: money|null, after_concession: money|null, notes: array<localized_text> }",  // the calculator's transfer-duty breakdown — resolver-computed (mechanism B) by fh_engine_cash from kb.stamp-duty.calc-by-state + the eligible concession (architecture/stamp-duty-concession-mechanics.md). At base, evaluated at the target-range ceiling; the income/savings-dependent fields below stay null until a refine turn (honest partial output).
    "deposit": "{ minimum_required_percentage: percentage|null, minimum_required_amount: money_range|null, notes: array<localized_text> }",  // [NEW, Decision 9] minimum deposit for the recommended path — 5% when mortgage_plan.recommended_path = fhg_backed, else the 5% floor + note. money_range at base (over target_price_range); collapses to a point per-property. Resolver (fh_engine_cash) from kb.cash-reserve genuine_savings_pct_of_price.
    "other_buying_costs": "{ total: money_range|null, registration_exact: money|null, notes: array<localized_text> }",  // [NEW, Decision 9] transaction costs beyond deposit + duty: per-state land-titles registration (REGULATED, exact, per-state formula) + convention bands (inspection, conveyancing, insurance, utilities, moving). total = [reg+Σlo, reg+Σhi]. Resolver (fh_engine_cash) from kb.buyer-costs.inspections-conveyancing-fees.
    "reserve_buffer": "{ months_of_repayments_recommended: integer, amount: money|null, notes: array<localized_text> }",  // [NEW, Decision 9] post-settlement reserve = months × monthly repayment. amount NULL at base (needs the loan repayment/rate — a refine fact); EXCLUDED from total_cash_required (which is _at_settlement). kb.cash-reserve recommended_post_settlement_reserve_months.
    "max_property_price_supported": "money",
    "actual_property_price": "money",
    "total_cash_required": "money_range",  // [Decision 9] NEED side AT SETTLEMENT = deposit + stamp_duty.after_concession + other_buying_costs.total. money_range at base (over target_price_range); a point per-property. Excludes the post-settlement reserve_buffer.
    "cash_available": "money",  // HAVE side = cash_on_hand + fhss_release + family_contribution. NULL at base (onboarding captures no savings — plan-first; computes on a refine turn).
    "gap_or_surplus": "money",  // cash_available − total_cash_required. NULL at base (HAVE side null) → the verdict is PENDING by design.
    "verdict": "enum [surplus, tight, short]",
    "genuine_savings_verdict": "enum [meets, fails_recent_gift, insufficient_track_record, unknown]",  // F5 — DISTINCT from verdict (cash sufficiency). A buyer can read 'surplus' on cash yet fail the lender's 5% genuine-savings test (a recent family gift doesn't count — the '1% rule'). Resolver derives the determinate cases (gift-exclusion + savings-trail math) from buyer_profile.savings_and_deposit (genuine_savings_evidence_months, family_gift_or_loan_amount, funds_provenance.deposit_source) against the policy params in kb.cash-reserve.lender-expectations — the EXISTING owner of this gate (5%/3-month, 1% rule, rental-history substitute); already a cash_position anchor, NOT a new doc. Returns `unknown` to defer the irreducible cases (the 12-month rental-history substitute, ambiguous/mixed sources) to the agent.
    "cash_events": "array<{ id: string, phase: string, label: localized_text, direction: enum [out, in], amount: money_range|null, is_estimate: bool, timing: enum [one_off, recurring], period: enum [once, monthly, quarterly, annual]|null, counterparty: string, source_component: string }>",  // [two-spines, lifecycle-simulation-model §2] the ACQUISITION financial spine (phases Prepare→Settle) — the `calculator` renderer groups it by phase into a cumulative cash-flow. Each event PLACES an already-computed figure (one-computer-per-figure): the out-events (deposit.minimum_required_amount, stamp_duty.after_concession, other_buying_costs.total) are this component's own resolver figures; the in-events are PLACED from scheme_stack.applicable_schemes[].benefit_value — read, never recomputed — but ONLY for schemes with `role = grant` (FHOG): a grant is the only scheme benefit that is a genuine cash INFLOW. The other roles are NOT in-events, because counting them would double-count money already reflected on the out-side — the `stamp_duty_concession` is netted into the reduced `after_concession` duty out-event; `deposit_guarantee` (FHG) and `shared_equity` (Help to Buy) are avoided costs already embedded in the deposit/loan figures, never cash received; `deposit_savings` (FHSS) is the buyer's own released super, counted on the HAVE side (cash_available), not an inflow here. `amount` mirrors the source figure (money_range, or [v,v] for a point; null when honestly not yet computable — honest partial); `is_estimate` mirrors the source's estimate flag (e.g. FHG LMI band vs exact duty/FHOG). `counterparty` is the actor id (you / government / lender / other) the money flows to/from — this is what lets `purchase_journey` place each event as a swimlane cell at (phase, counterparty) and derive the who-pays-whom `interactions` WITHOUT recomputing. Own-phase recurring costs are NOT here (cash_position cannot see ownership_planning, which runs downstream); they live in `ongoing_obligations.recurring_costs_estimate` and are placed on the swimlane's Own column by `purchase_journey`.
    "mitigation_options_if_short": "array<string>",
    "key_assumptions": "array<localized_text>"
  }
}
```

---

### 6. buying_strategy

**Goal:** Produce a bid plan, negotiation strategy, and agent-tactics awareness for the active buying phase (offer or auction).

**Inputs:** `property_assessment.outcome` + `cash_position.outcome` (specifically `budget_envelope`)

**KB anchors:** `kb.auction.rules-by-state`, `kb.cooling-off.by-state`, `kb.negotiation.patterns-by-market-condition`, `kb.agent-tactics.detection`, `kb.comparables.reading-the-room`

**Renderer:** `buying-strategy-card`

**UI tab hint:** Buying (NEW dedicated tab)

**Parameters:**

```jsonc
{
  "transaction_mode": {
    "type": { "type": "enum", "options": ["auction", "private_treaty_offer", "expression_of_interest", "tender", "off_the_plan_contract"], "value": "<initial>" },
    "scheduled_date": { "type": "date", "value": "<initial>" },
    "cooling_off_applies": { "type": "bool", "value": "<initial>", "derived_from": "transaction_mode.type" },
    "cooling_off_days": { "type": "integer", "value": "<initial>" }
  },
  "comparables": {
    "comparable_sales_set": { "type": "array<comparable_sale>", "value": [] },
    "median_comparable_sale_price": { "type": "money", "value": "<initial>" },
    "highest_comparable_relevance": { "type": "money", "value": "<initial>" },
    "lowest_comparable_relevance": { "type": "money", "value": "<initial>" }
  },
  "price_envelope": {
    "max_bid": {
      "value": { "type": "money", "value": "<initial>" },
      "confidence": { "type": "percentage_0_100", "value": "<initial>" },
      "reasoning": { "type": "string", "value": "<initial>" }
    },
    "walk_away_price": { "type": "money", "value": "<initial>" },
    "opening_bid_recommended": { "type": "money", "value": "<initial>" },
    "reserve_estimate_range": { "type": "money_range", "value": "<initial>", "agent_reasoning_required": true, "reasoning_domain": "negotiation" }
  },
  "bid_tactics": {
    "increment_size_recommended": { "type": "money", "value": "<initial>" },
    "drop_out_signal": { "type": "string", "value": "<initial>" },
    "early_offer_vs_wait": { "type": "enum", "options": ["make_early_offer", "wait_for_auction", "wait_for_post_auction_negotiation"], "value": "<initial>", "agent_reasoning_required": true, "reasoning_domain": "negotiation" }
  },
  "negotiation_style": {
    "recommended_style": { "type": "enum", "options": ["assertive", "patient", "early_offer", "low_anchor"], "value": "<initial>", "agent_reasoning_required": true, "reasoning_domain": "negotiation" },
    "rationale": { "type": "string", "value": "<initial>" }
  },
  "agent_tactics_watchlist": {
    "common_tactics_to_watch": { "type": "array<{ tactic, counter }>", "value": [] },
    "agent_pressure_signals": { "type": "array<string>", "value": [] }
  },
  "live_coach": {
    "armed": { "type": "bool", "value": false },
    "mobile_endpoint_ready": { "type": "bool", "value": false }
  },
  "conditions_to_include_in_offer": {
    "subject_to_finance": { "type": "bool", "value": true },
    "subject_to_building_pest": { "type": "bool", "value": true },
    "subject_to_satisfactory_strata_report": { "type": "bool", "value": "<initial>" },
    "other_special_conditions": { "type": "array<string>", "value": [] }
  }
}
```

**Outcome schema:** `bid_plan`

```jsonc
{
  "type": "bid_plan",
  "fields": {
    "max_bid_value": "money",
    "max_bid_confidence": "percentage_0_100",
    "max_bid_reasoning": "string",
    "walk_away_price": "money",
    "negotiation_style": "enum",
    "live_coach_armed": "bool",
    "conditions_to_request": "array<string>",
    "red_flags_to_monitor": "array<string>"
  }
}
```

---

### 7. due_diligence

**Goal:** Surface document risks and required actions; produce a go/no-go recommendation against the contract / Section 32 / building+pest / strata report.

**Inputs:** `property_assessment.outcome` + uploaded documents (Section 32, Contract of Sale, building/pest report, strata report)

**KB anchors:** `kb.contract-of-sale.review-points-by-state`, `kb.s32.review-points`, `kb.building-pest.interpretation`, `kb.strata-report.red-flags`, `kb.special-conditions.standard-set`

**Renderer:** `risk-flag-list` + `checklist`

**UI tab hint:** Before you buy

**Parameters:**

```jsonc
{
  "documents_required": {
    "contract_of_sale": { "required": true, "received": "<initial>", "reviewed": "<initial>" },
    "section_32_vendor_statement": { "required": "<initial>", "received": "<initial>", "reviewed": "<initial>" },
    "building_inspection_report": { "required": true, "received": "<initial>", "reviewed": "<initial>" },
    "pest_inspection_report": { "required": true, "received": "<initial>", "reviewed": "<initial>" },
    "strata_report": { "required": "<initial>", "received": "<initial>", "reviewed": "<initial>" },
    "title_search": { "required": true, "received": "<initial>", "reviewed": "<initial>" }
  },
  "flags_by_document": {
    "contract_of_sale_flags": { "type": "array<{ severity, item, action }>", "value": [], "agent_reasoning_required": true, "reasoning_domain": "document_significance" },
    "s32_flags": { "type": "array<{ severity, item, action }>", "value": [], "agent_reasoning_required": true, "reasoning_domain": "document_significance" },
    "building_flags": { "type": "array<{ severity, item, action, estimated_repair_cost }>", "value": [], "agent_reasoning_required": true, "reasoning_domain": "document_significance" },
    "pest_flags": { "type": "array<{ severity, item, action }>", "value": [], "agent_reasoning_required": true, "reasoning_domain": "document_significance" },
    "strata_flags": { "type": "array<{ severity, item, action }>", "value": [], "agent_reasoning_required": true, "reasoning_domain": "document_significance" },
    "title_flags": { "type": "array<{ severity, item, action }>", "value": [], "agent_reasoning_required": true, "reasoning_domain": "document_significance" }
  },
  "special_conditions_to_request": { "type": "array<string>", "value": [] },
  "questions_to_ask_vendor_or_agent": { "type": "array<string>", "value": [] },
  "estimated_additional_costs_from_findings": { "type": "money_range", "value": "<initial>" },
  "go_no_go_recommendation": {
    "verdict": { "type": "enum", "options": ["proceed", "proceed_with_conditions", "renegotiate", "withdraw"], "value": "<initial>", "agent_reasoning_required": true, "reasoning_domain": "document_significance" },
    "rationale": { "type": "string", "value": "<initial>" }
  }
}
```

**Outcome schema:** `risk_assessment`

```jsonc
{
  "type": "risk_assessment",
  "fields": {
    "overall_verdict": "enum",
    "high_severity_flags": "array<{ source_doc, item, action }>",
    "actions_before_signing": "array<string>",
    "questions_for_vendor": "array<string>",
    "estimated_negotiation_lever": "money_range"
  }
}
```

---

### 8. settlement_prep

**Goal:** Coordinate the 4–8 week settlement timeline — milestones, counterparty contacts, document deadlines.

**Inputs:** `eligibility.outcome` + `property_assessment.outcome` + `bid_plan` (only if buying proceeded)

**KB anchors:** `kb.settlement.process-by-state`, `kb.cooling-off.by-state`, `kb.pexa.settlement`, `kb.insurance.timing-of-risk-pass`, `kb.lender-docs.standard-timeline`

**Renderer:** `swimlane-diagram` + `checklist`

**UI tab hint:** Journey (follows `purchase_journey`, per-property) + Before you buy

**Parameters:**

```jsonc
{
  "key_dates": {
    "contract_signed_date": { "type": "date", "value": "<from_document>" },
    "cooling_off_end_date": { "type": "date", "value": "<initial>", "derived_from": "key_dates.contract_signed_date" },
    "deposit_due_date": { "type": "date", "value": "<initial>", "derived_from": "key_dates.contract_signed_date" },
    "finance_approval_deadline": { "type": "date", "value": "<initial>", "derived_from": "key_dates.contract_signed_date" },
    "settlement_date": { "type": "date", "value": "<from_document>" },
    "building_insurance_effective_date": { "type": "date", "value": "<initial>", "derived_from": "property_fit.state + key_dates.contract_signed_date + key_dates.settlement_date", "note": "STATE-CONDITIONAL per kb.insurance.timing-of-risk-pass — QLD: on or before contract_signed_date (the standard REIQ contract passes risk to the buyer at 5pm the first business day after contract, so the buyer must insure on signing); NSW / VIC: settlement_date (risk stays with the vendor until settlement/possession). Deriving from settlement_date alone underinsures a QLD buyer for the entire contract→settlement window." }
  },
  "milestones": {
    "contract_signed": { "type": "milestone", "value": { "status": "<initial>", "due_date": "<initial>" } },
    "deposit_paid_to_trust": { "type": "milestone", "value": { "status": "<initial>", "due_date": "<initial>" } },
    "building_pest_satisfactory": { "type": "milestone", "value": { "status": "<initial>", "due_date": "<initial>" } },
    "finance_approval_unconditional": { "type": "milestone", "value": { "status": "<initial>", "due_date": "<initial>" } },
    "loan_documents_signed": { "type": "milestone", "value": { "status": "<initial>", "due_date": "<initial>" } },
    "insurance_bound": { "type": "milestone", "value": { "status": "<initial>", "due_date": "<initial>" } },
    "settlement_funds_released": { "type": "milestone", "value": { "status": "<initial>", "due_date": "<initial>" } },
    "title_registered": { "type": "milestone", "value": { "status": "<initial>", "due_date": "<initial>" } },
    "keys_received": { "type": "milestone", "value": { "status": "<initial>", "due_date": "<initial>" } }
  },
  "counterparties": {
    "lender": { "type": "string", "value": "<initial>" },
    "broker": { "type": "string", "value": "<initial>" },
    "conveyancer_solicitor": { "type": "string", "value": "<initial>" },
    "real_estate_agent": { "type": "string", "value": "<initial>" },
    "building_inspector": { "type": "string", "value": "<initial>" },
    "pest_inspector": { "type": "string", "value": "<initial>" },
    "insurer": { "type": "string", "value": "<initial>" }
  },
  "scheme_application_milestones": {
    "fhss_release_request_submitted": { "type": "milestone", "value": { "status": "<initial>" } },
    "fhg_slot_reserved": { "type": "milestone", "value": { "status": "<initial>" } },
    "state_concession_application_lodged": { "type": "milestone", "value": { "status": "<initial>" } }
  }
}
```

**Outcome schema:** `settlement_checklist`

```jsonc
{
  "type": "settlement_checklist",
  "fields": {
    "settlement_date": "date",
    "critical_path_milestones": "array<{ name, due_date, status, dependency }>",
    "at_risk_milestones": "array<{ name, reason }>",
    "next_action_for_user": "string"
  }
}
```

---

### 9. ownership_planning

**Goal:** Project ongoing costs and obligations after settlement, and set alert triggers for refinance windows, graduation events, and rate moves.

**Inputs:** `property_assessment.outcome` + `eligibility.outcome` + `cash_position.outcome` + `mortgage_finance.outcome` (the loan terms that drive P&I, graduation/LVR, and refinance windows — `mortgage_plan`; matches the pipeline diagram and the compiled `dag_reads`)

**KB anchors:** `kb.ongoing-costs.rates-water-strata`, `kb.refinance.windows-and-triggers`, `kb.graduation.lvr80`, `kb.land-tax.ppor-exemption`, `kb.maintenance.budget-by-property-type`

**Renderer:** `data-table` + `opportunity-card`

**UI tab hint:** After you buy

**Parameters:**

```jsonc
{
  "monthly_obligations": {
    "mortgage_principal_and_interest": { "type": "money_per_month", "value": "<initial>" },
    "utility_estimate_combined": { "type": "money_per_month", "value": "<initial>" }
  },
  "quarterly_obligations": {
    "council_rates": { "type": "money_per_quarter", "value": "<initial>" },
    "water_access_and_usage": { "type": "money_per_quarter", "value": "<initial>" },
    "strata_levies": { "type": "money_per_quarter", "value": "<initial>", "applicable": "<initial>" }
  },
  "annual_obligations": {
    "building_insurance_premium": { "type": "money_per_year", "value": "<initial>" },
    "contents_insurance_optional": { "type": "money_per_year", "value": "<initial>" },
    "land_tax_check": { "type": "enum", "options": ["exempt_ppor", "applicable", "to_verify"], "value": "exempt_ppor", "note": "F12 — resolves from application.intended_occupancy_use: sole_occupier → exempt_ppor; partial_rental / granny_flat → to_verify (partial exemption / apportionment per kb.land-tax.ppor-exemption); not_occupied → applicable." }
  },
  "maintenance_reserve": {
    "annual_target": { "type": "money_per_year", "value": "<initial>" },
    "percentage_of_property_value": { "type": "percentage", "value": 1 }
  },
  "lifecycle_alerts": {
    "graduation_event_lvr_target": { "type": "percentage", "value": 80 },
    "estimated_graduation_years": { "type": "number", "value": "<initial>" },
    "refi_review_cadence_months": { "type": "integer", "value": 24 },
    "first_refi_window_target": { "type": "date", "value": "<initial>" }
  },
  "scheme_specific_alerts": {
    "fhg_loan_active": { "type": "bool", "value": "<initial>" },
    "fhg_ends_at_lvr_80_or_payoff": { "type": "string", "value": "Notify user when LVR drops below 80% for free refi window" }
  }
}
```

**Outcome schema:** `ongoing_obligations`

```jsonc
{
  "type": "ongoing_obligations",
  "fields": {
    "total_monthly_outgoings_estimate": "money|null",   // null at base — mortgage-P&I-dominated, needs a firm loan amount + rate (refine turn)
    "total_annual_outgoings_estimate": "money|null",     // null at base — as above
    "maintenance_reserve_target": "money_per_year",      // resolver-computed (mechanism B) by fh_engine_ownership: reserve_pct × the target-range ceiling
    "recurring_costs_estimate": "{ statutory_band: { low: money|null, high: money|null, period, components: array<string> }, strata_levies: money|null, utilities: money|null, building_insurance: money|null, notes: array<localized_text> }",  // the data-table's non-mortgage cost breakdown — resolver-computed (mechanism B) from kb.ongoing-costs.rates-water-strata (architecture/ongoing-costs-projection.md). At base only statutory_band (council+water) is filled; strata (needs property type), utilities + building insurance (no KB band / property-specific) stay null until a refine/per-property turn (honest partial)
    "land_tax_check": "enum [exempt_ppor, applicable, to_verify]",  // F12 — regulated PPOR status from kb.land-tax.ppor-exemption; Mode-A owner-occupier → exempt_ppor
    "graduation_milestone": "{ target_lvr, estimated_year: number|null }",  // target_lvr determinate (80); estimated_year null at base (needs the LVR trajectory)
    "alert_triggers_armed": "array<{ trigger: localized_text, action: localized_text }>"   // FHG-graduation (if FHG in scheme_stack), periodic rate review, land-tax mode-switch
  }
}
```

---

### 10. purchase_journey

**Goal:** Present the whole-of-journey lifecycle as a swimlane — the phases of a first-home purchase across time (Prepare → Pre-approve → Contract → Settle → Own) against the actors who act in each (You / Government / Lender / Other), with the buyer's already-computed money flows placed on the timeline. This is the **base lifecycle spine** the prototype led with — property-agnostic, generated at onboarding.

**Scope:** `base` — the journey structure is generic to a Mode-A FHB purchase; it does not depend on a specific property. (`settlement_prep` (8) is the *per-property* settlement checklist that refines the Settle phase once a property is attached — a distinct component.)

**Inputs:** `eligibility.outcome` (scheme_stack) + `mortgage_finance.outcome` (mortgage_plan) + `cash_position.outcome` (budget_envelope, incl. its `cash_events`) + `ownership_planning.outcome` (ongoing_obligations — for the Own-phase recurring costs). It runs **last** precisely so it can place figures every upstream component already computed — it computes **no figure of its own** (one-computer-per-figure; the regulated duty / deposit / total / recurring are referenced, never recomputed). This is the **whole-lifecycle spine**: it reads `budget_envelope.cash_events` (the Prepare→Settle acquisition flow) and `ongoing_obligations.recurring_costs_estimate` (the Own phase) and PLACES each on the swimlane at its (phase, actor/counterparty) cell. Because every `cash_event` already carries a `counterparty`, both the cell placement and the who-pays/talks-to-whom `interactions` fall straight out — no new computation.

**KB anchors:** `kb.journey.fhg-path`

**Renderer:** `swimlane-diagram`

**UI tab hint:** Journey (leads the tab; `settlement_prep` follows per-property)

**Fill path:** resolver. The journey structure + bilingual cell prose are generic KB content (`kb.journey.fhg-path`); the figures are upstream outcomes placed on the timeline. No agent leaf.

**Outcome schema:** `journey_swimlane`

```jsonc
{
  "type": "journey_swimlane",
  "fields": {
    "phases": "array<{ id: string, label: localized_text }>",   // ordered lifecycle phases (Prepare → Pre-approve → Contract → Settle → Own)
    "actors": "array<{ id: string, label: localized_text }>",   // the swimlane rows (You / Government / Lender / Other)
    "cells": "array<{ phase: string, actor: string, item: localized_text, flow_marker: enum [none, money_out, money_in, document, milestone], amount: money_range, counterparty: string|null, source_component: string }>",  // one action per (phase, actor) that has one; amount is an upstream figure PLACED on the timeline (a point figure is emitted as [v, v]; null when no figure attaches) — NEVER computed here (one-computer-per-figure). counterparty is the OTHER end of a money flow (the actor the money goes to / comes from; null for non-money cells) — carried through from the source cash_event. source_component traces the cell to the figure's owner (cash_position / eligibility / ownership_planning) for the outcome-conformance gate.
    "interactions": "array<{ from_actor: string, to_actor: string, phase: string, flows: array<{ label: localized_text, direction: enum [out, in], amount: money_range }> }>",  // [two-spines] the who-pays/talks-to-whom view (Son's point 3) — a structural aggregation of the cells' (actor, counterparty, amount) tuples per phase (e.g. You → Other(vendor): deposit + balance in Contract/Settle; Government → You: grant in Settle). Derived by PLACEMENT from the same cash_events, not recomputed; this is the per-stage 'four parties, who interacts with whom' structure neither the prototype nor production had.
    "key_assumptions": "array<localized_text>"
  }
}
```

The `journey_swimlane` shape is **mode-general** (phases × actors × cells); Modes B/C/D reuse the same schema + the mode-agnostic `swimlane-diagram` renderer with their own `kb.journey.*` content and resolver (plan-card-lifecycle-restoration.md §3.3). Mode A is built; the rest are content-only follow-ons.

---

### 11. preparation

**Goal:** Surface the property-agnostic **readiness layer** the buyer can act on before any specific property exists — the documents to gather, the people to line up, the scheme applications to prepare, and the cash buffer to hold. This is the prototype's "Before you buy" content (document checklist, people to engage, money buffer), reclassified OUT of the per-property `due_diligence` (7) so it shows at onboarding with no property attached (Son's point 4).

**Scope:** `base` — generic to a Mode-A FHB. (`due_diligence` (7) remains the *per-property* document-risk review — contract / S32 / building+pest / strata; a different component for a different artifact set.)

**Inputs:** `eligibility.outcome` (scheme_stack — which scheme applications to prepare for) + `cash_position.outcome` (budget_envelope — the buffer / genuine-savings figures surfaced as readiness; PLACED, never recomputed).

**KB anchors:** `kb.preparation.fhb-readiness`

**Renderer:** `checklist` + `data-table`

**UI tab hint:** Before you buy (leads the tab)

**Fill path:** resolver. The checklist items + people-to-engage roles are generic bilingual KB content (`kb.preparation.fhb-readiness`); the money-buffer figures are upstream outcomes placed on the readiness table. No agent leaf.

**Outcome schema:** `preparation_plan`

```jsonc
{
  "type": "preparation_plan",
  "fields": {
    "document_checklist": "array<{ id, item: localized_text, why: localized_text, status: enum [not_started, gathered] }>",  // generic FHB document set (photo ID, NOA, payslips, bank statements, deposit evidence) from kb.preparation.fhb-readiness. status is a USER-ATTESTED fact (the 'Chưa có / Đã có' toggle — Son's point 4: the user sets it), stored on the card; resolver seeds it not_started. NOT the per-property contract/S32/inspection docs (those are due_diligence).
    "people_to_engage": "array<{ role: localized_text, when: localized_text, why: localized_text }>",  // generic roles to line up (mortgage broker, conveyancer/solicitor, buyer's agent if used) — bilingual KB content; the named individuals are filled per-property in settlement_prep.counterparties.
    "scheme_applications_to_prepare": "array<{ scheme, action: localized_text }>",  // PLACED from scheme_stack.applicable_schemes (e.g. FHSS release request, FHG slot reservation) — read, not recomputed.
    "money_buffer": "{ genuine_savings_verdict: enum [meets, fails_recent_gift, insufficient_track_record, unknown], reserve_buffer: money|null, notes: array<localized_text> }",  // PLACED from budget_envelope.genuine_savings_verdict + budget_envelope.reserve_buffer (one-computer-per-figure; null at base until a refine turn). The readiness read of the buffer the calculator owns.
    "key_assumptions": "array<localized_text>"
  }
}
```

The user can mark `document_checklist[].status` and run a structural **what-if** on the buffer (via the calculator's `simulate` preview) without spending a turn; saving a chosen readiness state is an ordinary resolver-only refine turn (lifecycle-simulation-model §4, engine-contract §10).

---

## KB anchor index (for this blueprint)

The following kb_anchor slugs are referenced by components in this blueprint. The offline KB agent must ensure each slug resolves to a curated KB document. Slugs use dot-notation; lookups are case-sensitive.

| Slug | Component(s) | Owns |
|---|---|---|
| `kb.hecs.thresholds` | 1 | HECS repayment thresholds, treatment by lenders |
| `kb.firb.status-determination` | 1 | How to determine FIRB classification from visa/citizenship status |
| `kb.lender.serviceability-basics` | 1, 4 | Lender serviceability assessment basics (income, debts, buffer rate) |
| `kb.property.suburb-risk-factors` | 2 | Suburb-level risk (flood, planning, school catchment data sources) |
| `kb.property.comparables-methodology` | 2 | How to identify and weight comparable sales |
| `kb.strata.health-indicators` | 2 | Strata report red flags, sinking fund interpretation |
| `kb.building-types.risk-by-type` | 2 | Risk profiles for established house, apartment, off-the-plan |
| `kb.scheme.fhg` | 3 | Federal First Home Guarantee — rules, caps by location, mechanics |
| `kb.scheme.fhss` | 3 | First Home Super Saver — contribution limits, release process, tax |
| `kb.scheme.help-to-buy` | 3 | Federal Help to Buy shared equity scheme |
| `kb.scheme.qld.fhc` | 3 | QLD First Home Concession (established homes) |
| `kb.scheme.qld.fhnhc` | 3 | QLD First Home (New Home) Concession |
| `kb.scheme.vic.fhb-duty` | 3 | VIC First Home Buyer Duty Exemption / Concession |
| `kb.scheme.vic.fhog` | 3 | VIC First Home Owner Grant |
| `kb.scheme.nsw.fhbas` | 3 | NSW First Home Buyer Assistance Scheme |
| `kb.scheme.nsw.fhog` | 3 | NSW First Home Owner Grant |
| `kb.lender.fhg-panel-list` | 4 | FHG participating-lender panel (closed list; no rate premium) |
| `kb.lender.hecs-treatment-by-lender` | 4 | Per-lender HECS/HELP treatment in serviceability |
| `kb.lender.credit-card-treatment` | 4 | Credit-card limit treatment in serviceability |
| `kb.lender.bnpl-treatment-2026` | 4 | BNPL treatment in serviceability (NCCP commencement 2025) |
| `kb.lmi.providers` | 4 | LMI provider landscape; lender (not borrower) selects the insurer |
| `kb.offset-account.basics` | 4 | Offset account mechanics |
| `kb.stamp-duty.calc-by-state` | 5 | Stamp duty calculation methodology per state |
| `kb.buyer-costs.inspections-conveyancing-fees` | 5 | Typical ranges for buyer-side transaction costs |
| `kb.cash-reserve.lender-expectations` | 5 | Lender expectations for post-settlement cash reserves |
| `kb.lmi.calculation` | 4, 5 | LMI estimation when not using FHG |
| `kb.auction.rules-by-state` | 6 | Auction rules, cooling-off applicability, bidder registration |
| `kb.cooling-off.by-state` | 6, 8 | Cooling-off periods by state and transaction mode |
| `kb.negotiation.patterns-by-market-condition` | 6 | Negotiation patterns in hot vs cold markets |
| `kb.agent-tactics.detection` | 6 | Common real estate agent tactics and counters |
| `kb.comparables.reading-the-room` | 6 | Interpreting comparables in the context of an active offer |
| `kb.contract-of-sale.review-points-by-state` | 7 | Standard CoS review points per state |
| `kb.s32.review-points` | 7 | Section 32 review points (VIC) |
| `kb.building-pest.interpretation` | 7 | Interpreting building and pest reports |
| `kb.strata-report.red-flags` | 7 | Strata report red flags and what they mean |
| `kb.special-conditions.standard-set` | 7 | Standard special conditions to request |
| `kb.settlement.process-by-state` | 8 | Settlement process and timelines per state |
| `kb.pexa.settlement` | 8 | PEXA electronic settlement mechanics |
| `kb.insurance.timing-of-risk-pass` | 8 | When risk passes to buyer; insurance binding timing |
| `kb.lender-docs.standard-timeline` | 8 | Lender document timeline from approval to settlement |
| `kb.ongoing-costs.rates-water-strata` | 9 | Council rates, water rates, strata levy ranges |
| `kb.refinance.windows-and-triggers` | 4, 9 | When and how to refinance; lender switching mechanics |
| `kb.graduation.lvr80` | 9 | The 80% LVR graduation event and FHG implications |
| `kb.land-tax.ppor-exemption` | 9 | Land tax PPOR exemption rules |
| `kb.maintenance.budget-by-property-type` | 9 | Maintenance budget heuristics by property type |
| `kb.journey.fhg-path` | 10 | The Mode-A FHB lifecycle template — phase + actor labels, per-cell bilingual prose, journey assumptions (the swimlane's structure + copy; figures are placed from upstream, not stored here) |
| `kb.preparation.fhb-readiness` | 11 | The Mode-A FHB readiness template — generic document checklist + people-to-engage roles + bilingual prose (buffer figures are placed from upstream, not stored here) |

---

## Renderer vocabulary used

This blueprint uses 9 of the constrained renderer vocabulary defined in [§11.9 in architecture.md](../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification):

| Renderer | Used by component(s) |
|---|---|
| `summary-card` | 1 buyer_profile, 2 property_assessment, 4 mortgage_finance |
| `scheme-stack-card` | 3 eligibility |
| `calculator` | 5 cash_position |
| `buying-strategy-card` | 6 buying_strategy |
| `risk-flag-list` | 7 due_diligence |
| `checklist` | 7 due_diligence, 8 settlement_prep, 11 preparation |
| `swimlane-diagram` | 8 settlement_prep, 10 purchase_journey |
| `data-table` | 4 mortgage_finance, 9 ownership_planning, 11 preparation |
| `opportunity-card` | 9 ownership_planning |

---

## Parameter signal vocabulary

This blueprint uses signal placeholders defined in [§11.9 in architecture.md](../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification):

| Signal | Used for |
|---|---|
| `<initial>` | Never-filled parameter — most common |
| `<from_property_card>` | Pulled from property selection (e.g., address, price, suburb) |
| `<from_suburb>` | Pulled from the suburb enrichment record (`suburbs` table) — resolver lookup |
| `<from_document>` | Pulled from facts extracted from an uploaded document — resolver copy (extraction sidecar ran upstream) |
| `<from_buyer_profile>` | Pulled from upstream `buyer_profile` outcome |
| `<from_property_assessment>` | Pulled from upstream `property_assessment` outcome |
| `<from_eligibility>` | Pulled from upstream `eligibility` outcome |

Future iterations may add `<pending: user>`, `<pending: agent>`, `<stale: 90d>`, `<conflict: user_override>`.

**Fill-path classification.** A leaf carrying `agent_reasoning_required: true` is filled by an agent turn (LLM); every other leaf resolves deterministically (copy, `derived_from`, formula, or rules engine). Which leaves clear the agent bar is governed by [agentic-boundary.md](../architecture/agentic-boundary.md). In this blueprint the agent-path leaves are exactly: property valuation (`property_assessment.market_position.comparable_sales` / `estimated_market_value_range` / `asking_price_vs_market`, `fit_against_buyer.lifestyle_match_score`); lender fit + rate structure (`mortgage_finance.lender_synthesis.most_likely_approval_lenders`, `loan_structure.fixed_vs_variable`); negotiation reads (`buying_strategy.negotiation_style.recommended_style`, `bid_tactics.early_offer_vs_wait`, `price_envelope.reserve_estimate_range`); and document significance + go/no-go (`due_diligence.flags_by_document.*`, `go_no_go_recommendation.verdict`). Everything else — **eligibility, scheme stacking, all cash / serviceability math, dates, settlement, ownership projections** — is resolver.

---

## Cross-component output dependency graph

For migration script validation: confirm that every `<from_X>` reference in a component's parameters resolves either to an output in an upstream component or to a recognised external source (`<from_property_card>`, `<from_suburb>`, `<from_document>`), and that the pipeline is acyclic.

```
buyer_profile         → outcome: profile               (no upstream)
property_assessment   → outcome: property_fit          (reads: profile)
eligibility           → outcome: scheme_stack          (reads: profile, property_fit)
mortgage_finance      → outcome: mortgage_plan         (reads: profile, scheme_stack)
cash_position         → outcome: budget_envelope       (reads: profile, property_fit, scheme_stack, mortgage_plan)
buying_strategy       → outcome: bid_plan              (reads: property_fit, budget_envelope, mortgage_plan)
due_diligence         → outcome: risk_assessment       (reads: property_fit, uploaded_docs)
settlement_prep       → outcome: settlement_checklist  (reads: scheme_stack, property_fit, bid_plan, mortgage_plan)
ownership_planning    → outcome: ongoing_obligations   (reads: property_fit, scheme_stack, budget_envelope, mortgage_plan)
preparation           → outcome: preparation_plan      (reads: scheme_stack, budget_envelope)
purchase_journey      → outcome: journey_swimlane      (reads: scheme_stack, mortgage_plan, budget_envelope, ongoing_obligations)
```

No cycles. `due_diligence` is independent of `buying_strategy` (parallel — buyer can run due diligence before deciding to bid). `mortgage_finance` slots in between `eligibility` and `cash_position` because cash math needs the loan amount + LMI / FHG path decision from the mortgage plan. `purchase_journey` runs **last** so it can place figures from every figure-owner — its new read of `ongoing_obligations` (for the Own phase) is a forward edge (9 → 10), so the graph stays acyclic; it still computes nothing of its own. `preparation` reads only upstream base outcomes (`scheme_stack`, `budget_envelope`) and likewise places, never recomputes.

---

## Open questions / future iteration

These were deferred from the current design and should be considered in a future iteration:

1. **Multi-property comparison view** — when a user has multiple plan cards (one per property), should the blueprint specify how to render aggregate comparison? Or is this a UI-layer concern outside the blueprint?
2. **Pre-approval lifecycle** — currently absent; should be a sub-component within `buyer_profile` or a separate `preapproval_status` component with its own outcome.
3. **Refresh semantics** — when a plan card was filled against an earlier deploy and the blueprint is redeployed, what's the exact prompt and refresh UX?
4. **Live coach state machine** — the buying_strategy component has `live_coach.armed: bool`, but the actual auction-day state machine (pre-brief, live bid, win, post-loss) is not yet specified. Consider extracting to its own ephemeral micro-component.
5. **Mode B (foreign-person FHB) variant** — the companion `fhb-foreign-au` blueprint needs FIRB workflow component, currency transfer component, cross-border family component, and modifications to cash_position (foreign-buyer surcharge), eligibility (FHG/FHSS not eligible), property_assessment (new-build filter due to established-dwelling ban).

---

## Document control

- **Status:** draft, May 2026 — first concrete blueprint specification
- **Author:** Strategic design synthesis (Claude + maintainer)
- **Consumers:** Offline KB agent, user-facing planning agent, migration script, UI renderer layer
- **Companion blueprints (pending):** `fhb-foreign-au`, `investor-domestic-au`, `investor-foreign-au`
- **Disclaimer:** This is a working spec, not a regulatory document. Actual scheme rules, FIRB regulations, and state stamp duty schedules must be confirmed against authoritative sources (resolved via kb_anchor lookups) at runtime. Wrong eligibility advice has real consequences; the blueprint must be paired with rigorous KB curation discipline and agent reasoning verification.
