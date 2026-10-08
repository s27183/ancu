# FHB plan card blueprint — Mode B (foreign-person, cross-border family)

> Part of the **Vietnamese Diaspora Property Platform** document set. See [README.md](../README.md) for the full index.
>
> **This is a working specification** consumed by:
>
> - The offline KB agent (Claude Code + maintainer) to validate KB anchor coverage and renderer consistency
> - The user-facing planning agent at session time (loaded as system prompt context, rendered as plan card UI)
> - The migration script at deployment time to publish the blueprint into the `blueprints` table (replacing the prior deploy; git holds history)
>
> Companion specs: [fhb-domestic-au.md](fhb-domestic-au.md) (Mode A). Investor blueprints (Modes C, D) to follow.

---

## Metadata

```jsonc
{
  "blueprint_id": "fhb-foreign-au",
  "effective_from": "2026-05-19",
  "effective_until": null,
  "buyer_mode": "fhb",
  "user_mode": "B",
  "audience": "Vietnam-located parents funding AU child's property OR AU temporary residents (student, 485, etc.) buying a first home in Australia. Foreign persons under FIRB.",
  "firb_required": true,
  "language_primary": "vi",
  "language_alternate": "en",
  "renderer_set": "fhb"
}
```

This blueprint serves **Mode B** users — Vietnamese parents in Vietnam funding their AU-resident child's property, AND Vietnamese students / 485 visa holders / other temporary residents in AU buying a first home. Both audience segments share the defining attribute: they are **foreign persons under FIRB** and therefore subject to:

- **Established-dwelling ban** (1 April 2025 – 30 June 2029) — new builds only
- **FIRB approval requirement** before contract
- **FIRB application fees** ($15.5k–$45k+, scaling with property value)
- **Foreign-buyer stamp duty surcharge** (~8% in NSW / VIC / QLD on top of standard duty)
- **Vacancy fee** if property is unoccupied / not genuinely available for rent ≥183 days/year
- **Non-resident tax treatment** (different CGT, restricted PPOR exemption)
- **Cross-border capital flow** (Vietnamese capital controls + Australian AML/CTF documentation + FX)

Compared to Mode A (`fhb-domestic-au`), this blueprint **replaces** the `eligibility` component (no FHG / FHSS / Help to Buy / state FHB concessions apply) with the new `firb_workflow` component and **adds** two cross-border-specific components (`family_context`, `cross_border_funding`). Other components (`buyer_profile`, `property_assessment`, `buying_strategy`, `due_diligence`, `settlement_prep`, `ownership_planning`) carry adapted parameters reflecting the foreign-person constraints.

---

## Component pipeline

The blueprint is a directed pipeline of fourteen components. Six carry a `★` (marked new — either unique to Mode B, or added to this document after the original May 2026 draft) — `family_context`, `firb_workflow`, `cross_border_funding` (Mode-B-exclusive), `disposition` (added 2026-07-11 for dispose-phase parity, §11.4 below), and `purchase_journey`/`phase_playbook` (added 2026-07-11 alongside `disposition`'s wiring, task 12 — the whole-of-journey swimlane + its actionable checklist; both exist in Mode A too, base-scope in every mode, just newly wired into THIS blueprint); the rest are adapted.

### Component scope (base plan vs property addendum)

Each component has a `scope` indicating when it runs in the plan card lifecycle:

| Component | Scope | Runs when |
|---|---|---|
| 1 buyer_profile (foreign-person variant) | `base` | Onboarding |
| 2 family_context ★ | `base` | Onboarding for cross-border family scenarios |
| 3 property_assessment (foreign-person filter) | `per-property` | When specific property attached |
| 4 firb_workflow ★ | `both` | Base estimate of FIRB fee tier at onboarding (from target price range); refined per-property when specific property triggers approval workflow |
| 5 mortgage_finance (foreign-person variant) | `both` | Base estimate of non-resident-friendly lender shortlist + deposit requirements at onboarding; refined per-property when loan amount known |
| 6 cash_position (foreign-person variant) | `both` | Base estimate against target price range; refined per-property |
| 7 cross_border_funding ★ | `both` | Base capacity / provider selection at onboarding; refined per-property for specific transfer amount and timing |
| 8 buying_strategy (FIRB gate) | `per-property` | When user signals bid readiness |
| 9 due_diligence (cross-border docs) | `per-property` | When user uploads docs |
| 10 settlement_prep (FIRB + transfer milestones) | `per-property` | Activated when contract signed |
| 11 ownership_planning (vacancy fee + non-resident tax) | `both` | Base estimate of ongoing obligations at onboarding; refined per-property post-settlement |
| 12 disposition ★ | `base` | Onboarding; the dispose-phase figure-owner — added 2026-07-11 for parity with Modes A/C/D (`plan-card-lifecycle-restoration.md` §11.4) — a foreign FHB can still face a forced or voluntary sale (visa status change, relocation), and the FIRB vacancy-fee obligation makes "what if I need to sell" a live question |
| 13 purchase_journey ★ | `base` | Onboarding; the whole-of-journey lifecycle swimlane — Mode A's own four-actor phases × cells, harvests `cash_events` off components 6 (`cash_position`) + 11 (`ownership_planning`) + 12 (`disposition`), places them, computes nothing. Resolver, no agent leaf. Added 2026-07-11 (task 12, `plan-card-lifecycle-restoration.md` §11.5) |
| 14 phase_playbook ★ | `base` | Onboarding; the actionable per-phase checklist + risk-flag-list behind the swimlane. Resolver, no agent leaf. Added 2026-07-11 (task 12) |

The base plan for Mode B captures the most regulatory complexity even before a specific property: FIRB classification, family-funding capacity, cross-border transfer feasibility, foreign-buyer cost estimates. This makes Mode B's base plan genuinely valuable on its own — Vietnamese parents can validate the cross-border path before committing to a specific property.

```
[1] buyer_profile (foreign-person variant)
       │   outcome: profile
       ▼
[2] family_context ★
       │   inputs: profile
       │   outcome: family_funding_plan
       ▼
[3] property_assessment (foreign-person filter: new-build only)
       │   inputs: profile, family_funding_plan
       │   outcome: property_fit
       ▼
[4] firb_workflow ★ (replaces Mode A eligibility)
       │   inputs: profile, property_fit
       │   outcome: firb_status
       ▼
[5] cash_position (no schemes + foreign-buyer surcharge + FIRB fees + FX)
       │   inputs: profile, family_funding_plan, property_fit, firb_status
       │   outcome: budget_envelope
       ▼
[6] cross_border_funding ★
       │   inputs: family_funding_plan, budget_envelope
       │   outcome: transfer_plan
       ▼
[7] buying_strategy (similar to Mode A + FIRB approval gate)
       │   inputs: property_fit, budget_envelope, firb_status
       │   outcome: bid_plan
       ▼
[8] due_diligence (similar to Mode A + cross-border docs)
       │   inputs: property_fit, uploaded_docs
       │   outcome: risk_assessment
       ▼
[9] settlement_prep (+ FIRB approval milestone, + currency transfer milestone)
       │   inputs: property_fit, bid_plan, firb_status, transfer_plan
       │   outcome: settlement_checklist
       ▼
[10] ownership_planning (vacancy fee + non-resident tax)
        inputs: property_fit, profile
        outcome: ongoing_obligations
       │
       ▼
[11] disposition ★ (NEW — the dispose-phase figure-owner, added 2026-07-11)
        inputs: profile, mortgage_plan, budget_envelope, ongoing_obligations
        outcome: disposition
       │
       ▼
[12] purchase_journey ★ (NEW — the whole-of-journey swimlane, added 2026-07-11)
        inputs: budget_envelope (cash_events), ongoing_obligations, disposition (dispose_cash_events)
        outcome: journey_swimlane
       │
       ▼
[13] phase_playbook ★ (NEW — the per-phase checklist + risks, added 2026-07-11)
        inputs: budget_envelope (cash_events, for budget_ref validation)
        outcome: phase_playbook
```

> This diagram omits `mortgage_finance` (a pre-existing doc/code divergence, harmless to
> order — see `fh_engine_turn.erl`'s `?BASE_COMPONENTS_FOREIGN` macro comment); `disposition`/
> `purchase_journey`/`phase_playbook` are numbered `[11]`/`[12]`/`[13]` continuing this diagram's
> own numbering, not the 14-row scope table above.

**UI tab mapping** — the fourteen components surface through **four top-level views + a Q&A tab** ([`../architecture/plan-card-lifecycle-restoration.md`](../architecture/plan-card-lifecycle-restoration.md) §11.3), not the earlier flat eight-tab rail. Applying §11.2's placement test to Mode B: `firb_workflow` is phase-shaped (a literal gate between Pre-approve and Contract) → its approval-state narrative folds into a Flow phase, while its **fee** is money-shaped → also a Budget row (same dual placement `eligibility` gets in Mode A's Overview+Flow). `cross_border_funding` is §3.3's own "currency-transfer milestone" → Flow milestone + Budget row (FX/transfer cost). `family_context` is state-shaped with no completion point (persists across the whole plan — who contributes how much from where, decision authority) → earns its own **Family** view, the same treatment Portfolio gets in Modes C/D, and unlike Mode D's opt-in Family layer this one is **always on** (Mode B's entry assumption is a cross-border family purchase, not solo). `property_assessment`, `buying_strategy`, `due_diligence`, `settlement_prep`, `ownership_planning` are per-property or phase-recurring and reached as backing detail via `phase_playbook.actions[].component_ref`, not as tabs — `ownership_planning`'s vacancy-fee/non-resident-tax obligations narrate through the Own phase's actions rather than a standalone tab or Budget row (its `recurring_costs_estimate` is an honest-partial gap at base, per task 12).

| # | View | `kind` | What it shows |
|---|---|---|---|
| 1 | Budget | `components` (interactive) | the financial spine — `cash_position` as the phased acquisition cash-flow + what-if cockpit (deposit, stamp duty + foreign-buyer surcharge, FIRB fee); `firb_workflow`'s fee as its own row; `cross_border_funding`'s FX/transfer cost as its own row; `disposition` as the dispose-phase figure owner; each cash-event row drills to its `source_component` — lands first (2026-08, Son's call) so the buyer goes straight into cash planning |
| 2 | Overview | `synthesis` | "what this is" + aggregated read of `buyer_profile` + `firb_workflow` (the FIRB gate headline — same treatment Mode A gives `eligibility`) + `mortgage_finance` + `cash_position` |
| 3 | Flow | `flow` | the legal/temporal spine — `purchase_journey` (swimlane, Prepare → … → Own → **Dispose**, FIRB gate + transfer milestone narrated across Pre-approve→Contract→Settle) as navigation; each phase opens a sheet = swimlane slice + `phase_playbook` actions (ordered, budget-linked — including `firb_workflow`'s application/approval steps and `cross_border_funding`'s transfer steps) + `phase_playbook` risks; `settlement_prep` enriches the Settle phase per-property |
| 4 | Family | `components` | `family_context` — the parent + child cross-border funding dashboard; the only Mode-B concept that's state-shaped with no completion point, so it doesn't fold into Flow or Budget |
| 5 | Q&A | `qa` | bilingual planning-agent chat (a shell surface over the engine Q&A stream — not a `component_filled`) |

**Machine-readable form** — compiled to `ui_tabs` in the artifact, **canonical for the runtime** (the table above is the human view). Rewritten 2026-07-11 (task 13, `plan-card-lifecycle-restoration.md` §11.5) from the stale pre-restructure flat eight-tab rail to this five-view spine, mirroring [`investor-foreign-au.md`](investor-foreign-au.md)'s `overview`/`flow`/`budget`/`family`/`qa` shape (Family replacing Portfolio as the state-shaped view — Mode B has no portfolio concept, Mode D has no default family concept).

```jsonc
{
  "ui_tabs": [
    { "tab_id": "budget",   "kind": "components", "interactive": true, "components": ["cash_position", "firb_workflow", "cross_border_funding", "disposition"] },
    { "tab_id": "overview", "kind": "synthesis",  "components": ["buyer_profile", "firb_workflow", "mortgage_finance", "cash_position"] },
    { "tab_id": "flow",     "kind": "flow",        "components": ["purchase_journey", "phase_playbook", "settlement_prep"] },
    { "tab_id": "family",   "kind": "components", "components": ["family_context"], "note": "Mode B central surface; bilingual; always-on (unlike Mode D's opt-in Family layer)" },
    { "tab_id": "qa",       "kind": "qa",          "components": [] }
  ]
}
```

---

## Components

### 1. buyer_profile (foreign-person variant)

**Goal:** Capture the AU-side member's situation, FIRB classification, and entry-point family context. *Distinct from Mode A: gathers visa class, residency duration, family-in-VN intent.*

**Inputs:** User questions answered in chat; any uploaded documents (visa grant letter, passport, employer letter if employed in AU, NOA if filed). No upstream component dependency — this is the pipeline entry.

**KB anchors:** `kb.firb.established-dwelling-ban`, `kb.visas.au-temporary-residency-classes`, `kb.au-temp-residents.banking-and-tax-basics`

**Renderer:** `summary-card`

**UI tab hint:** Overview (collapsed) + Family view (detail)

**Parameters:**

```jsonc
{
  "user_location": {
    "physical_country": { "type": "enum", "options": ["VN", "AU", "other"], "value": "<initial>" },
    "physical_state": { "type": "enum", "options": ["NSW", "VIC", "QLD", "WA", "SA", "TAS", "ACT", "NT", "n/a"], "value": "<initial>" },
    "language_preference": { "type": "enum", "options": ["vi", "en"], "value": "vi" }
  },
  "applicants": {
    "type": "array<applicant>",
    "note": "F1 — one entry per person taking a legal/ownership interest (canonical applicant element, shared with Mode A/C). Mode B: 1..N AU-SIDE members (the buyer(s) on title/loan). The eligibility- and tax-bearing facts are PER-APPLICANT. For Mode B EVERY applicant is a foreign person under FIRB — firb_required = true per applicant, and the household aggregate profile.firb_required_any = true (the single FIRB fact read across modes; the F14 close). visa_class is the B-activated finer detail (drives non-resident lending + FIRB nuance). The VN funding parent is NOT in this array (they take no title/loan interest) — they are an off_title_parties[] entry with the funder role.",
    "value": [
      {
        "role": { "type": "enum", "options": ["primary", "co_buyer"], "value": "primary" },
        "citizenship_status": { "type": "enum", "options": ["temporary_resident", "non_resident"], "value": "<initial>", "note": "Mode B = foreign person; citizen/PR route to Mode A. A PR/citizen co-buyer in an otherwise-foreign purchase still has the household trip the FIRB gate via the foreign co-applicant." },
        "firb_status": { "type": "enum", "options": ["foreign_person"], "value": "foreign_person", "note": "Mode B entry assumption — every applicant is a foreign person." },
        "firb_required": { "type": "bool", "value": true, "derived_from": "firb_status", "note": "true for every Mode B applicant; the household aggregate profile.firb_required_any is the single FIRB fact read across modes (the F14 close)." },
        "visa_class": { "type": "enum", "options": ["student_500", "graduate_485", "skilled_482", "skilled_186", "spouse_309", "spouse_820", "other_temporary", "non_resident", "permanent_resident", "citizen"], "value": "<initial>", "note": "B-activated (fact-model-unification.md 'Mode-B activation') — finer detail when temporary_resident; read as applicant.visa_class by mortgage_finance (non-resident lending policy) and firb_workflow (classification nuance)." },
        "visa_grant_date": { "type": "date", "value": "<initial>" },
        "residency_duration_months": { "type": "integer", "value": "<initial>", "derived_from": "visa_grant_date" },
        "taxable_income_aud": { "type": "money_per_year", "value": "<initial>", "note": "per-applicant AU-source assessable income; the household assessable_income aggregates the array." },
        "tax": {
          "residency_for_tax": { "type": "enum", "options": ["resident", "non_resident", "temporary_resident_for_tax"], "value": "<initial>", "note": "B-activated tax{} (foreign lens) — DISTINCT from FIRB status: a foreign person is commonly a non_resident or temporary_resident_for_tax (no CGT main-residence exemption, withholding on rental income), read by ownership_planning / cash_position." },
          "marginal_rate": { "type": "percentage", "value": "<initial>", "derived_from": "taxable_income_aud" },
          "jurisdiction": { "type": "enum", "options": ["AU"], "value": "AU", "note": "Mode B reasons on the AU-side tax position; VN-side parent tax is a labelled placeholder (AU-side-full / VN-side-placeholder scope)." }
        },
        "employment_status": { "type": "enum", "options": ["full_time_au", "part_time_au", "studying_only", "not_employed_au"], "value": "<initial>" }
      }
    ],
    "_item_note": "Each array entry is one AU-side member with the shape shown; the single example entry illustrates the per-applicant leaf schema. At runtime the array has one entry per AU-side buyer."
  },
  "off_title_parties": {
    "type": "array<off_title_party>",
    "note": "F4/F14 — people LINKED to the purchase but NOT on title or the loan (so not in applicants[]). Canonical array shared with Mode A (a non-buying partner) — Mode B is the first to populate the funder role (the Vietnam funding parent / family pool). One party can carry TWO roles at once, so each consumer reads BY ROLE FLAG, not by position (architecture §11.9 off_title.* namespace; fact-model-unification.md sub-question 1 MERGE): eligibility reads counts_for_couple_as_one; the funder consumers (family_context, cross_border_funding) read funder.*.",
    "value": [
      {
        "relationship": { "type": "enum", "options": ["spouse", "de_facto", "parent", "sibling", "other_family", "self_funding", "none"], "value": "parent", "note": "canonical relationship enum (union across modes; shared with Mode A). Mode B's canonical party is the Vietnam funding parent (location is on funder.residence_country, not the relationship enum)." },
        "counts_for_couple_as_one": { "type": "bool", "value": false, "note": "role flag → eligibility (the dyadic ≤1 couple-as-one subset). false for the funding parent; canonical so a foreign-mode spouse is captured the same way as Mode A (Mode B replaces eligibility with firb_workflow, so the gate is dormant here, but the flag stays canonical)." },
        "ownership_history": {
          "ever_owned_au_property": { "type": "bool", "value": "<initial>", "note": "couple-as-one input — left unfilled for a pure funder (honest-partial); populated only when counts_for_couple_as_one = true." },
          "ever_owned_and_occupied_residence": { "type": "bool", "value": "<initial>" },
          "currently_owns_property": { "type": "bool", "value": "<initial>" }
        },
        "funder": {
          "expected_to_fund": { "type": "bool", "value": "<initial>", "note": "role flag — true marks this party as a funder; the funder consumers (family_context, cross_border_funding) filter the array on this. Mode B's first real use of the funder role." },
          "residence_country": { "type": "enum", "options": ["VN", "AU", "other"], "value": "VN", "note": "where the funding originates — VN for the canonical Vietnam parent. Gates the cross-border (VN-side) compliance block, whose regulated content is a labelled placeholder." },
          "contribution_capacity_aud": { "type": "money", "value": "<initial>", "note": "AUD-equivalent the party can contribute — the AU-side-buildable funder fact. The VN-side REGULATED content the funder triggers (SBV thresholds / VN-PDP / VN-side parent tax) is a labelled placeholder, not built here (AU-side-full / VN-side-placeholder scope)." }
        }
      }
    ],
    "_item_note": "Each array entry is one off-title party with the canonical shape (shared with Mode A); the single example illustrates the role-tagged leaf schema. Mode B's canonical entry is the VN funding parent (funder.expected_to_fund = true, residence_country = VN; ownership_history left off — funder role, not couple-as-one)."
  },
  "income": {
    "income_stability": { "type": "enum", "options": ["permanent_payg", "contractor", "self_employed", "casual", "studying_only", "mixed"], "value": "<initial>" }
  },
  "savings_and_deposit": {
    "au_savings_aud": { "type": "money", "value": "<initial>" }
  },
  "debts": {
    "hecs_balance": { "type": "money", "value": 0 }
  },
  "intent": {
    "intended_use": { "type": "enum", "options": ["personal_residence_for_au_member", "future_personal_when_pr_granted", "family_investment", "mixed"], "value": "<initial>" },
    "target_purchase_months": { "type": "integer", "value": "<initial>" },
    "pr_pathway_timeline_estimate": { "type": "string", "value": "<initial>" }
  }
}
```

**Outcome schema:** `profile`

```jsonc
{
  "type": "profile",   // canonical, mode-independent identity shape — Mode B projects the foreign-person subset (fact-model-unification.md "Mode-B activation"); NOT a private profile_foreign type
  "fields": {
    // legal-status & tax facts — PER-APPLICANT (read as applicant.*). Mode B: 1..N foreign-person AU-side members.
    "applicants": "array<{ role, citizenship_status, firb_required, visa_class, tax }>",  // every entry firb_required = true; visa_class (B-activated) feeds non-resident lending + FIRB classification; per-applicant tax{ residency_for_tax, marginal_rate, jurisdiction: AU } (foreign lens — commonly non_resident / temporary_resident_for_tax). No first-home ownership_history / owner_occupier_intent — Mode B has no FHB schemes.
    "applicant_count": "integer",
    "firb_required_any": "bool",                      // = TRUE for Mode B (foreign mode) — the SINGLE household FIRB fact, read uniformly across all modes. Published from a foreign mode (true definitionally) = the F14 close; the aggregate kb.firb.established-dwelling-ban already reads it. Per-applicant firb_required lives inside applicants[].
    "off_title_parties": "array<{ relationship, counts_for_couple_as_one, ownership_history, funder }> | null",  // F4/F14 canonical array (shared with Mode A — identical element shape). Mode B is the first to populate the funder role: funder{ expected_to_fund, residence_country, contribution_capacity_aud } — the VN funding parent / family pool. Read BY ROLE FLAG (architecture §11.9 off_title.* namespace): eligibility ← counts_for_couple_as_one (the dyadic ≤1 subset); family_context / cross_border_funding ← funder. ownership_history left off for a pure funder (honest-partial). The VN-side REGULATED funder content (SBV/PDP/VN tax) is a labelled placeholder. null until captured (honest-partial).
    // neutral derived financials (facts, not verdicts) — household-level
    "assessable_income": "money_per_year",            // aggregate of applicants[].taxable_income_aud (AU-source)
    "approx_borrowing_capacity": "money_range",       // non-resident-lender flavoured (stricter serviceability) — banded, resolver-computed; refined in mortgage_finance
    "deposit_ready_for_purchase_amount": "money",     // AU-side savings + expected funder contributions available
    "debts": "{ hecs_balance, credit_card_limits_total, personal_loans_balance, car_loan_balance, buy_now_pay_later_balance } | null",  // raw debt facts the serviceability resolver reads (profile HOLDS facts; mortgage_finance reasons over them, §11.9). null until captured (honest-partial).
    // narrative
    "key_constraints": "array<localized_text>",       // bilingual (engine-output), canonical type — was array<string>
    "key_strengths": "array<localized_text>"
    // REMOVED firb_required (scalar) → now per-applicant + the household firb_required_any aggregate
    // REMOVED established_property_eligible / new_build_only_constraint — FIRB verdicts; owned by firb_workflow (outcomes carry facts, not verdicts; §11.9)
    // REMOVED approx_*_side_contribution_capacity — funder capacity now lives per-party in off_title_parties[].funder.contribution_capacity_aud
  }
}
```

> **Identity-layer conformance (2026-06-28).** This component's outcome is now the **canonical `profile`** (not a per-mode `profile_foreign`), projecting the Mode-B-activated generalizations — per-applicant `visa_class` + `tax{}` (foreign lens), the canonical `off_title_parties[]` with the **funder role** (the Vietnam funding parent), and `firb_required_any = true` published from a foreign mode (**the F14 close**) ([`../architecture/fact-model-unification.md`](../architecture/fact-model-unification.md) "Mode-B activation"). Downstream components read `profile.*` / `applicant.*` / `off_title.*` / `plan.*` (architecture §11.9 read-namespace convention; off-title parties read **by role flag**, not position). **Deferred to later Mode-B phases:** the downstream components' precise field-path reads → **P2** (engine resolvers — `firb_workflow`, `mortgage_finance`/`cash_position`/`ownership_planning` foreign variants, `family_context` + `cross_border_funding`); the AU-side KB (`kb.firb.*`, `kb.lender.non-resident-*`, `kb.foreign-buyer-surcharge.*`, …) → **P1**; flipping Mode B **in-scope** + the compiler's **semantic**-gate extension → **P3**; the VN-side *regulated* `funder{}` content stays a **labelled placeholder**. This unit conforms the identity layer and keeps the **structural** gates green.

---

### 2. family_context ★ (NEW for Mode B)

**Goal:** Establish the cross-border family funding plan — who contributes how much from where, and who holds decision authority. Enables the Family view surface.

**Inputs:** `buyer_profile.outcome` (profile)

**KB anchors:** `kb.vietnamese-family.financial-patterns`, `kb.cross-border.decision-authority-cultural`, `kb.bilingual.coordination-norms`

**Renderer:** `family-view-card`

**UI tab hint:** Family view (central)

**Parameters:**

```jsonc
{
  "contributors": {
    "au_member": {
      "contribution_amount": { "type": "money", "value": "<initial>" },
      "contribution_source": { "type": "array<enum>", "options": ["personal_savings_au", "personal_savings_vn", "income_from_au", "loan_from_family", "other"], "value": [] },
      "contribution_currency_origin": { "type": "enum", "options": ["AUD", "VND", "USD", "mixed"], "value": "<initial>" }
    },
    "vn_parent_or_family": {
      "contribution_amount": { "type": "money_aud_equivalent", "value": "<initial>" },
      "contribution_source": { "type": "array<enum>", "options": ["savings_vn", "sale_of_asset", "family_pool", "loan_from_au_member_to_be_repaid", "other"], "value": [] },
      "documentation_readiness": { "type": "enum", "options": ["ready", "partial", "not_started"], "value": "<initial>" }
    },
    "other_contributors": { "type": "array<contributor>", "value": [] }
  },
  "totals": {
    "total_family_capacity_aud": { "type": "money", "value": "<initial>" },
    "au_side_percentage": { "type": "percentage", "value": "<initial>" },
    "vn_side_percentage": { "type": "percentage", "value": "<initial>" }
  },
  "decision_authority": {
    "primary_decision_maker": { "type": "enum", "options": ["au_member", "vn_parent", "joint", "family_council"], "value": "<initial>" },
    "consultation_required_for_purchase": { "type": "enum", "options": ["au_member_only", "vn_parent_only", "both_required", "family_council"], "value": "<initial>" }
  },
  "coordination": {
    "bilingual_view_active": { "type": "bool", "value": false },
    "shared_dashboard_invited_parties": { "type": "array<{ name, role, language }>", "value": [] },
    "language_per_party": { "type": "object<party_id, language>", "value": {} }
  }
}
```

**Outcome schema:** `family_funding_plan`

```jsonc
{
  "type": "family_funding_plan",
  "fields": {
    "total_capacity_aud": "money",
    "contribution_breakdown": "array<{ party, amount_aud, source, currency_origin }>",
    "decision_authority": "enum",
    "bilingual_coordination_required": "bool",
    "funding_complexity_score": "integer_1_10",
    "documentation_gaps": "array<string>"
  }
}
```

---

### 3. property_assessment (foreign-person filter applied)

**Goal:** Analyse the selected property for fit — *with explicit foreign-person eligibility filtering*. Refuses established dwellings; flags new-build / off-the-plan eligibility and FIRB fee tier.

**Inputs:** `property_card` (from selection) + `buyer_profile.outcome` (profile) + `family_context.outcome`

**KB anchors:** `kb.firb.eligible-property-types-foreign-persons`, `kb.firb.fee-tiers-by-value`, `kb.property.suburb-risk-factors`, `kb.property.comparables-methodology`, `kb.strata.health-indicators`, `kb.building-types.risk-by-type`, `kb.off-the-plan.risk-considerations`

**Renderer:** `summary-card`

**UI tab hint:** Property

**Parameters:**

Same structure as [Mode A property_assessment](fhb-domestic-au.md#2-property_assessment) with these additions and changes:

```jsonc
{
  "basics": { /* same as Mode A — address, suburb, state, price, type, beds, baths, parking */ },
  "location_factors": { /* same as Mode A */ },
  "market_position": { /* same as Mode A — comparables, asking_price_vs_market, days_on_market */ },
  "strata_or_building": { /* same as Mode A */ },

  // FIRB eligibility + fee determination moved to firb_workflow (it owns FIRB verdicts — the Mode-A
  // eligibility analog). Foreign-buyer stamp-duty surcharge lives in cash_position's stamp_duty_and_surcharge
  // (it is state duty, not a FIRB fee). property_assessment stays FIRB-agnostic — neutral facts + property-fit,
  // plus an early non-authoritative ban warning in key_concerns (see outcome).

  "fit_against_buyer": {
    "price_within_family_capacity": { "type": "bool", "value": "<initial>" },
    "lifestyle_match_score_au_member": { "type": "integer_0_10", "value": "<initial>", "agent_reasoning_required": true, "reasoning_domain": "lifestyle_fit" },
    "rentability_score_if_unoccupied": { "type": "integer_0_10", "value": "<initial>", "agent_reasoning_required": true, "reasoning_domain": "rentability" }
  }
}
```

**Outcome schema:** `property_fit`

```jsonc
{
  "type": "property_fit",
  "fields": {
    // neutral property facts (per-property fact surface) — the only route downstream components
    // read property data; never via basics.* params (§11.9 one access path)
    "state": "enum [NSW, VIC, QLD, WA, SA, TAS, ACT, NT]",
    "suburb": "string",
    "price": "money",
    "property_type": "enum [established_house, established_apartment, new_house, new_apartment, off_the_plan, house_and_land]",
    // property-fit verdicts (this component's own reasoning) — FIRB verdicts now live in firb_workflow.
    // No `blocked_foreign_person_ineligible`: property_assessment runs before firb_workflow and cannot
    // own the FIRB verdict. Instead it emits an EARLY, non-authoritative ban warning in key_concerns
    // (from neutral facts: profile.firb_status foreign + established property_type); firb_workflow issues
    // the authoritative foreign_person_eligible=false + blocking_for_contract.
    "viability_verdict": "enum [proceed, proceed_with_caution, reconsider]",
    "key_strengths": "array<string>",
    "key_concerns": "array<string>",   // carries the early FIRB-ban warning when foreign + established
    "market_price_assessment": "string"
  }
}
```

When the buyer is a foreign person and the property is an established dwelling, property_assessment surfaces an **early ban warning** in `key_concerns` (non-authoritative, from neutral facts) so the user sees it at the property card. The **authoritative** determination is `firb_workflow`'s — `foreign_person_eligible == false` → `blocking_for_contract == true`. Downstream components (`mortgage_finance`, `buying_strategy`, `settlement_prep`) gate on `firb_status.blocking_for_contract`, not on property_assessment, and the agent surfaces alternative new-build options at that point.

---

### 4. firb_workflow ★ (NEW — replaces Mode A eligibility)

**Goal:** Manage the FIRB approval state machine — fee calculation, document preparation, application submission, decision tracking. Mandatory gate before contract signing.

**Inputs:** `buyer_profile.outcome` + `property_assessment.outcome`

**KB anchors:** `kb.firb.established-dwelling-ban`, `kb.firb.application-process`, `kb.firb.fee-schedule-current`, `kb.firb.documents-required`, `kb.firb.timelines-standard`, `kb.firb.exemption-certificates-developer`, `kb.firb.approval-conditions-typical`, `kb.firb.penalties-non-compliance`

**Renderer:** `firb-workflow-card`

**UI tab hint:** FIRB & Funding (central)

**Parameters:**

```jsonc
{
  "eligibility": {
    // FIRB eligibility determination — moved here from property_assessment (firb_workflow owns FIRB verdicts).
    // Reads neutral property facts (property_fit.property_type) + profile (firb_status); resolver, not agent.
    "is_new_build_or_vacant_land": { "type": "bool", "value": "<initial>", "derived_from": "property_fit.property_type" },
    "established_dwelling_ban_applies": { "type": "bool", "value": "<initial>", "derived_from": "kb.firb.established-dwelling-ban (current date within ban_start_date..ban_end_date)", "agent_reasoning_required": false },  // resolver-derived from the KB window — not hardcoded, so it self-expires 30 Jun 2029
    "foreign_person_can_purchase": { "type": "bool", "value": "<initial>", "note": "false ⇒ firb_status.foreign_person_eligible=false ⇒ blocking_for_contract. Developer new-dwelling exemption handled in exemption_pathway below." },
    "firb_application_required": { "type": "bool", "value": true }
  },
  "application_state": {
    "current_stage": { "type": "enum", "options": ["not_started", "in_preparation", "submitted", "under_review", "approved", "approved_with_conditions", "rejected", "withdrawn"], "value": "not_started" },
    "stage_entered_at": { "type": "date", "value": "<initial>" }
  },
  "fee_calculation": {
    "property_value_tier": { "type": "enum", "options": ["under_1m", "1m_to_2m", "2m_to_3m", "3m_to_5m", "over_5m"], "value": "<initial>", "derived_from": "property_fit.price" },
    "base_application_fee": { "type": "money", "value": "<initial>" },
    "additional_fees_if_any": { "type": "money", "value": 0 },
    "total_firb_fee_payable": { "type": "money", "value": "<initial>" }
  },
  "documents_required": {
    "passport_au_member": { "required": true, "uploaded": "<initial>" },
    "passport_vn_funder_if_applicable": { "required": "<initial>", "uploaded": "<initial>" },
    "visa_grant_evidence": { "required": true, "uploaded": "<initial>" },
    "property_details_contract_or_listing": { "required": true, "uploaded": "<initial>" },
    "source_of_funds_evidence": { "required": true, "uploaded": "<initial>" },
    "vendor_or_developer_details": { "required": true, "uploaded": "<initial>" }
  },
  "submission": {
    "submitted_via": { "type": "enum", "options": ["ato_online_foreign_investor_portal", "via_lawyer", "other"], "value": "ato_online_foreign_investor_portal" },
    "submitted_date": { "type": "date", "value": "<initial>" },
    "case_reference_number": { "type": "string", "value": "<initial>" }
  },
  "decision": {
    "expected_decision_window_days": { "type": "integer_range", "value": [30, 60] },
    "decision_received_date": { "type": "date", "value": "<initial>" },
    "decision_outcome": { "type": "enum", "options": ["approved", "approved_with_conditions", "rejected"], "value": "<initial>" },
    "approval_conditions": { "type": "array<string>", "value": [] },
    "approval_number": { "type": "string", "value": "<initial>" }
  },
  "exemption_pathway": {
    "developer_holds_new_dwelling_exemption_certificate": { "type": "bool", "value": "<initial>" },
    "if_yes_application_simplified": { "type": "bool", "value": "<initial>", "derived_from": "developer_holds_new_dwelling_exemption_certificate" }
  },
  "compliance_gates": {
    "must_be_approved_before_contract_signing": { "type": "bool", "value": true },
    "must_settle_within_approval_window_months": { "type": "integer", "value": 12 }
  }
}
```

**Outcome schema:** `firb_status`

```jsonc
{
  "type": "firb_status",
  "fields": {
    // FIRB verdicts (authoritative — moved here from property_assessment)
    "foreign_person_eligible": "bool",          // false when foreign person + established dwelling (ban) → blocking_for_contract
    "firb_fee_tier": "enum",
    "total_firb_fee_payable": "money",
    // approval state machine
    "current_stage": "enum",
    "approval_received": "bool",
    "approval_conditions": "array<string>",
    "days_to_expected_decision": "integer",
    "blocking_for_contract": "bool",            // true while not approved OR foreign_person_eligible == false
    "documents_outstanding": "array<string>"
  }
}
```

The `blocking_for_contract` field is the critical gate downstream — `buying_strategy` will refuse to commit a bid plan and `settlement_prep` will not advance settlement milestones while FIRB approval is unconfirmed.

---

### 5. mortgage_finance (foreign-person variant)

**Goal:** Determine the **non-resident-friendly lender shortlist**, deposit structure (typically 30%+ for foreign-person investment / temp-resident FHB), and loan path — with explicit FIRB-approval-precedes-unconditional-offer gating.

**Inputs:** `buyer_profile.outcome` (profile — including debts, visa class) + `firb_workflow.outcome` (firb_status — applicable; fee tier)

**KB anchors:** `kb.lender.non-resident-friendly-shortlist`, `kb.lender.temp-resident-lending-policies`, `kb.lender.485-visa-treatment`, `kb.lender.foreign-buyer-deposit-requirements`, `kb.lender.firb-approval-as-condition-precedent`, `kb.lender.documentation-non-resident`, `kb.fx.loan-currency-considerations`

**Renderer:** `summary-card` + `data-table`

**UI tab hint:** FIRB & Funding

**Scope:** `both` — base estimate at onboarding using profile + target price + FIRB fee estimate; refined per-property when specific loan amount is known

**Parameters:**

```jsonc
{
  "borrowing_capacity": {
    "non_resident_lender_assessment": { "type": "money_range", "value": "<initial>", "note": "Non-resident lenders typically apply stricter serviceability — lower borrowing power than equivalent domestic profile" },
    "lender_pool_size": { "type": "integer", "value": "<initial>", "note": "Typically 5–10 lenders willing to lend to foreign persons / temp residents" },
    "income_assessment_currency": { "type": "enum", "options": ["AUD_au_employment_only", "VND_with_haircut", "blended"], "value": "<initial>" }
  },
  "deposit_requirements": {
    "minimum_required_percentage_typical": { "type": "percentage", "value": 30, "note": "Most non-resident-friendly lenders require 30%+; some accept 20% with LMI" },
    "minimum_required_amount": { "type": "money", "value": "<initial>" },
    "recommended_amount": { "type": "money", "value": "<initial>" }
  },
  "loan_path": {
    "standard_non_resident_loan": {
      "lender_shortlist": { "type": "array<{ lender, rate_range, deposit_min_percentage, processing_time }>", "value": [] },
      "rate_premium_above_standard": { "type": "percentage_range", "value": "<initial>", "note": "Typically 50–150bp above domestic owner-occupier" }
    },
    "temp_resident_loan_485_or_student_with_au_income": {
      "applicable": { "type": "bool", "value": "<initial>" },
      "lender_shortlist": { "type": "array<string>", "value": [] }
    },
    "recommended_path": { "type": "enum", "options": ["standard_non_resident", "temp_resident_with_au_income", "wait_for_pr"], "value": "<initial>" },
    "recommended_path_reasoning": { "type": "string", "value": "<initial>" }
  },
  "debt_optimisation_recommendations": {
    "hecs": {
      "current_balance": { "type": "money", "value": "<from_buyer_profile>" },
      "treatment_for_non_resident_lender": { "type": "string", "value": "<initial>" },
      "clear_before_application_recommended": { "type": "bool", "value": "<initial>" }
    },
    "credit_cards_and_loans": {
      "lender_treatment_notes": { "type": "string", "value": "<initial>" },
      "optimisations_recommended": { "type": "array<string>", "value": [] }
    }
  },
  "firb_gate": {
    "firb_approval_must_precede_unconditional_offer": { "type": "bool", "value": true },
    "lender_requires_firb_approval_before_loan_settlement": { "type": "bool", "value": true },
    "loan_offer_can_be_conditional_on_firb": { "type": "bool", "value": true }
  },
  "loan_structure": {
    "principal_and_interest_vs_interest_only": { "type": "enum", "options": ["principal_and_interest", "interest_only"], "value": "principal_and_interest", "note": "Mode B FHB usually P&I (intent is owner-occupier)" },
    "currency_of_loan": { "type": "enum", "value": "AUD", "note": "All AU property loans denominated in AUD; FX exposure is on VN-side capital flow, not loan" }
  },
  "pre_approval_workflow": {
    "documents_required_for_non_resident": { "type": "array<{ document, status }>", "value": [], "note": "Includes visa grant, passport, employment evidence (AU or VN), source-of-funds letter, FIRB application reference" },
    "expected_processing_time_days": { "type": "integer", "value": "<initial>", "note": "Non-resident loans typically 4–8 weeks vs 2–4 weeks for domestic" }
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
    "deposit_required": "money",
    "recommended_lender_shortlist": "array<{ lender, reasoning, approval_likelihood }>",
    "firb_dependency_acknowledged": "bool",
    "loan_structure_recommendation": "object",
    "pre_approval_action_plan": "array<string>"
  }
}
```

The `mortgage_plan` outcome feeds `cash_position` (loan amount + deposit), `cross_border_funding` (transfer amount = deposit + buying costs), `buying_strategy` (financing conditions in offer), `settlement_prep` (lender + FIRB milestones).

---

### 6. cash_position (foreign-person variant)

**Goal:** Compute the buyer's full cash needs at settlement — *with foreign-buyer surcharge, FIRB fees, FX spread; no scheme stacking benefits*.

**Inputs:** `buyer_profile.outcome` + `family_context.outcome` + `property_assessment.outcome` + `firb_workflow.outcome`

**KB anchors:** `kb.stamp-duty.calc-by-state`, `kb.foreign-buyer-surcharge.by-state`, `kb.firb.fee-schedule-current`, `kb.fx.typical-spreads-vnd-aud`, `kb.buyer-costs.inspections-conveyancing-fees`, `kb.cash-reserve.lender-expectations`, `kb.lmi.calculation-for-foreign-persons`

**Renderer:** `calculator`

**UI tab hint:** Cash calculator (interactive) + FIRB & Funding (summary)

**Parameters:**

```jsonc
{
  "inputs": {
    "property_price_aud": { "type": "money", "value": "<from_property_assessment>" },
    "au_member_cash_aud": { "type": "money", "value": "<from_buyer_profile>" },
    "vn_family_contribution_aud_equivalent": { "type": "money", "value": "<from_family_context>" },
    "firb_fee_payable": { "type": "money", "value": "<from_firb_workflow>" }
  },
  "deposit": {
    "minimum_required_percentage_for_foreign_person": { "type": "percentage", "value": "<initial>" },
    "typical_required_percentage": { "type": "percentage", "value": 20 },
    "minimum_required_amount": { "type": "money", "value": "<initial>" },
    "recommended_amount": { "type": "money", "value": "<initial>" }
  },
  "stamp_duty_and_surcharge": {
    "standard_stamp_duty_before_concession": { "type": "money", "value": "<initial>" },
    "first_home_concession_applicable_for_foreign_person": { "type": "bool", "value": false },
    "foreign_buyer_surcharge_percentage": { "type": "percentage", "value": "<initial>", "derived_from": "property_fit.state" },
    "foreign_buyer_surcharge_amount": { "type": "money", "value": "<initial>" },
    "total_state_duty_payable": { "type": "money", "value": "<initial>" }
  },
  "firb_costs": {
    "firb_application_fee": { "type": "money", "value": "<from_firb_workflow>" }
  },
  "fx_costs": {
    "vn_to_au_transfer_amount_aud": { "type": "money", "value": "<initial>", "derived_from": "vn_family_contribution_aud_equivalent" },
    "estimated_fx_spread_percentage": { "type": "percentage", "value": 1.5 },
    "estimated_fx_cost": { "type": "money", "value": "<initial>" }
  },
  "other_buying_costs": {
    "building_inspection": { "type": "money", "value": "<initial>" },
    "conveyancing_solicitor": { "type": "money", "value": "<initial>" },
    "lender_application_fee": { "type": "money", "value": "<initial>" },
    "mortgage_registration_fee": { "type": "money", "value": "<initial>" },
    "title_transfer_fee": { "type": "money", "value": "<initial>" },
    "first_year_building_insurance": { "type": "money", "value": "<initial>" },
    "lmi_if_lvr_above_80": { "type": "money", "value": "<initial>" }
  },
  "reserve_buffer": {
    "months_of_repayments_recommended": { "type": "integer", "value": 6, "note": "Higher than Mode A due to non-resident lender expectations" },
    "amount": { "type": "money", "value": "<initial>" }
  },
  "totals": {
    "total_cash_required_at_settlement": { "type": "money", "value": "<initial>" },
    "total_family_capacity_available": { "type": "money", "value": "<initial>" },
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
    "max_property_price_supported": "money",
    "actual_property_price": "money",
    "total_cash_required": "money",
    "regulatory_imposts_total": "money",
    "channel_costs_total": "money",
    "family_capacity_available": "money",
    "gap_or_surplus": "money",
    "verdict": "enum [surplus, tight, short]",
    "mitigation_options_if_short": "array<string>",
    "cash_events": "array<{ id: string, phase: string, label: localized_text, direction: enum [out, in], amount: money_range|null, is_estimate: bool, timing: enum [one_off, recurring], period: enum [once, monthly, quarterly, annual]|null, counterparty: string, source_component: string }>",  // Mode B's ACQUISITION financial spine (task 12, 2026-07-11) — deposit + firb_fee (contract), stamp_duty + foreign_buyer_surcharge + other_buying_costs (settle); a scalar figure collapses to [v,v]. Live at base (Mode B's ceiling-estimate convention computes these figures from target_price_range alone, unlike Mode D's cash_position which is permanently null pre-property). Implemented by `fh_engine_cash:cash_events_foreign/5`; `purchase_journey`'s generic multi-source harvest places these on the swimlane
    "key_assumptions": "array<string>"
  }
}
```

Note `regulatory_imposts_total` (FIRB fee + foreign-buyer surcharge + LMI if applicable) and `channel_costs_total` (everything else) are tracked separately. Mode B regulatory imposts on a $1M property typically run $90k–$160k; channel costs run $25–50k. This breakdown lets the agent surface the foreign-person-specific cost transparently to the user — a defining trust signal for the platform.

---

### 7. cross_border_funding ★ (NEW)

**Goal:** Plan the cross-border capital flow — provider selection, Vietnamese capital-control compliance, Australian AML/CTF documentation, timing, FX cost optimisation.

**Inputs:** `family_context.outcome` + `cash_position.outcome`

**KB anchors:** `kb.fx-providers.wise-ofx-bank-comparison`, `kb.fx.typical-spreads-vnd-aud`, `kb.vn-capital-controls.sbv-thresholds-2026`, `kb.vn-capital-controls.declared-purpose-categories`, `kb.au-aml-ctf.bank-due-diligence-expectations`, `kb.au-aml-ctf.source-of-funds-documentation`, `kb.vn-pdp.cross-border-data-transfer`

**Renderer:** `firb-workflow-card` (used here as a state-machine renderer for the transfer workflow) + `checklist`

**UI tab hint:** FIRB & Funding (central)

**Parameters:**

```jsonc
{
  "transfer_amount": {
    "total_amount_aud": { "type": "money", "value": "<from_cash_position>" },
    "from_vn_side_amount_aud_equivalent": { "type": "money", "value": "<from_family_context>" },
    "from_au_side_amount_aud": { "type": "money", "value": "<from_family_context>" }
  },
  "provider_selection": {
    "evaluated_providers": { "type": "array<{ provider, spread_percentage, fee, total_cost, eta_days }>", "value": [] },
    "recommended_provider": { "type": "enum", "options": ["wise", "ofx", "bank_wire_anz", "bank_wire_cba", "bank_wire_nab", "bank_wire_westpac", "other"], "value": "<initial>" },
    "recommendation_reasoning": { "type": "string", "value": "<initial>" }
  },
  "vn_capital_control_compliance": {
    "amount_exceeds_sbv_threshold": { "type": "bool", "value": "<initial>" },
    "sbv_approval_required": { "type": "bool", "value": "<initial>" },
    "declared_purpose_category": { "type": "enum", "options": ["student_tuition_and_living_expenses", "family_remittance", "property_investment_foreign_direct_investment", "other"], "value": "<initial>" },
    "purpose_documentation_required": { "type": "array<string>", "value": [] },
    "vn_bank_used": { "type": "string", "value": "<initial>" }
  },
  "au_aml_ctf_compliance": {
    "source_of_funds_letter_prepared": { "type": "bool", "value": "<initial>" },
    "supporting_documents": { "type": "array<{ document, status }>", "value": [] },
    "bank_pre_engagement_completed": { "type": "bool", "value": "<initial>" },
    "expected_enhanced_due_diligence": { "type": "bool", "value": true }
  },
  "timing_and_milestones": {
    "transfer_initiated_date": { "type": "date", "value": "<initial>" },
    "transfer_received_date": { "type": "date", "value": "<initial>" },
    "settled_in_aud_held_at": { "type": "string", "value": "<initial>" },
    "buffer_days_before_settlement": { "type": "integer", "value": 14, "note": "Recommended buffer to absorb processing delays" }
  },
  "fx_cost": {
    "estimated_total_fx_cost": { "type": "money", "value": "<initial>" },
    "vs_worst_case_bank_wire_savings": { "type": "money", "value": "<initial>" }
  }
}
```

**Outcome schema:** `transfer_plan`

```jsonc
{
  "type": "transfer_plan",
  "fields": {
    "provider": "enum",
    "total_transfer_amount_aud": "money",
    "estimated_fx_cost": "money",
    "vn_compliance_steps": "array<string>",
    "au_compliance_steps": "array<string>",
    "transfer_initiated_by_date": "date",
    "transfer_received_by_date": "date",
    "critical_path_dependencies": "array<string>"
  }
}
```

---

### 8. buying_strategy (similar to Mode A + FIRB approval gate)

**Goal:** Produce a bid plan and negotiation strategy — *with explicit FIRB approval gate before any contract is signed*.

**Inputs:** `property_assessment.outcome` + `cash_position.outcome` (budget_envelope) + `firb_workflow.outcome` (firb_status)

**KB anchors:** All Mode A buying_strategy anchors + `kb.firb.contract-conditional-on-approval`, `kb.foreign-buyer.subject-to-firb-clauses`

**Renderer:** `buying-strategy-card`

**UI tab hint:** Buying

**Parameters:**

Identical to [Mode A buying_strategy](fhb-domestic-au.md#6-buying_strategy) with these additions:

```jsonc
{
  // ... all Mode A parameters ...
  "firb_gate": {
    "firb_approval_required_before_contract": { "type": "bool", "value": true },
    "firb_approval_confirmed": { "type": "bool", "value": "<from_firb_workflow>" },
    "if_not_approved_offer_subject_to_firb": { "type": "bool", "value": true },
    "agent_should_block_unconditional_offer_if_no_approval": { "type": "bool", "value": true }
  },
  "conditions_to_include_in_offer": {
    "subject_to_finance": { "type": "bool", "value": true },
    "subject_to_building_pest": { "type": "bool", "value": true },
    "subject_to_satisfactory_strata_report": { "type": "bool", "value": "<initial>" },
    "subject_to_firb_approval": { "type": "bool", "value": true },
    "subject_to_currency_transfer_completion": { "type": "bool", "value": "<initial>" },
    "other_special_conditions": { "type": "array<string>", "value": [] }
  }
}
```

The agent enforces the FIRB gate: it refuses to recommend an unconditional bid until `firb_workflow.outcome.approval_received == true`.

**Outcome schema:** `bid_plan` (same as Mode A, plus `firb_approval_status` field)

Declared as Mode A's `bid_plan` ([`fhb-domestic-au.md`](fhb-domestic-au.md)), the shape the shared resolver emits; the foreign-only additions named above are not emitted by any resolver yet, so they are not declared (Son, 2026-10-06, P-7: an undeclared shape fails the build).

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

### 9. due_diligence (similar to Mode A + cross-border documentation)

**Goal:** Surface document risks and required actions, *including cross-border documentation needs*.

**Inputs:** `property_assessment.outcome` + uploaded documents (Contract of Sale, building/pest, strata report, **+ source-of-funds documents for foreign person**)

**KB anchors:** All Mode A due_diligence anchors + `kb.firb.contract-clauses-required`, `kb.cross-border.source-of-funds-letter-template`

**Renderer:** `risk-flag-list` + `checklist`

**UI tab hint:** Property

**Parameters:**

Same as [Mode A due_diligence](fhb-domestic-au.md#7-due_diligence) plus:

```jsonc
{
  "documents_required": {
    // ... all Mode A documents ...
    "source_of_funds_letter": { "required": true, "received": "<initial>", "reviewed": "<initial>" },
    "vn_parent_documentation": { "required": "<initial>", "received": "<initial>", "reviewed": "<initial>" }
  },
  "cross_border_flags": {
    "vn_documentation_gaps": { "type": "array<{ severity, item, action }>", "value": [], "agent_reasoning_required": true, "reasoning_domain": "cross_border_documentation" },
    "au_aml_documentation_gaps": { "type": "array<{ severity, item, action }>", "value": [], "agent_reasoning_required": true, "reasoning_domain": "cross_border_documentation" }
  },
  "firb_specific_conditions_review": {
    "contract_includes_firb_approval_clause": { "type": "bool", "value": "<initial>" },
    "contract_includes_currency_transfer_buffer": { "type": "bool", "value": "<initial>" }
  }
}
```

**Outcome schema:** `risk_assessment` (same as Mode A, plus `cross_border_risks` field)

Declared as Mode A's `risk_assessment` ([`fhb-domestic-au.md`](fhb-domestic-au.md)), the shape the shared resolver emits; the foreign-only additions named above are not emitted by any resolver yet, so they are not declared (Son, 2026-10-06, P-7: an undeclared shape fails the build).

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

### 10. settlement_prep (+ FIRB approval milestone, + currency transfer milestone)

**Goal:** Coordinate the settlement timeline — *with FIRB approval and currency transfer as critical-path milestones*.

**Inputs:** `property_assessment.outcome` + `bid_plan` + `firb_workflow.outcome` + `cross_border_funding.outcome` (transfer_plan)

**KB anchors:** All Mode A settlement_prep anchors + `kb.firb.approval-to-settlement-timeline`, `kb.cross-border-settlement.coordination-best-practices`

**Renderer:** `swimlane-diagram` + `checklist`

**UI tab hint:** Temporal flow

**Parameters:**

Same as [Mode A settlement_prep](fhb-domestic-au.md#8-settlement_prep) plus:

```jsonc
{
  // ... all Mode A parameters ...
  "firb_milestones": {
    "firb_application_submitted": { "type": "milestone", "value": { "status": "<initial>", "due_date": "<initial>" } },
    "firb_approval_received": { "type": "milestone", "value": { "status": "<initial>", "due_date": "<initial>" } },
    "firb_approval_in_force_through_settlement": { "type": "milestone", "value": { "status": "<initial>", "due_date": "<initial>" } }
  },
  "currency_transfer_milestones": {
    "transfer_initiated_vn_side": { "type": "milestone", "value": { "status": "<initial>", "due_date": "<initial>" } },
    "sbv_compliance_documented": { "type": "milestone", "value": { "status": "<initial>", "due_date": "<initial>" } },
    "au_bank_aml_due_diligence_completed": { "type": "milestone", "value": { "status": "<initial>", "due_date": "<initial>" } },
    "funds_received_in_aud_trust_account": { "type": "milestone", "value": { "status": "<initial>", "due_date": "<initial>" } }
  },
  "language_specific_counterparties": {
    "vietnamese_speaking_conveyancer": { "type": "string", "value": "<initial>" },
    "vietnamese_speaking_immigration_lawyer_if_needed": { "type": "string", "value": "<initial>" }
  }
}
```

**Outcome schema:** `settlement_checklist` (same as Mode A, plus `firb_critical_path_status` and `transfer_critical_path_status` fields)

Declared as Mode A's `settlement_checklist` ([`fhb-domestic-au.md`](fhb-domestic-au.md)), the shape the shared resolver emits; the foreign-only additions named above are not emitted by any resolver yet, so they are not declared (Son, 2026-10-06, P-7: an undeclared shape fails the build).

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

### 11. ownership_planning (foreign-person variant — vacancy fee + non-resident tax)

**Goal:** Project ongoing costs and obligations — *with foreign-person specific vacancy fee monitoring and non-resident tax treatment*.

**Inputs:** `property_assessment.outcome` + `buyer_profile.outcome`

**KB anchors:** All Mode A ownership_planning anchors except the PPOR land-tax exemption (not applicable to foreign persons). Plus: `kb.firb.vacancy-fee-rules-2026`, `kb.firb.vacancy-fee-double-from-2024`, `kb.non-resident-tax.cgt-no-ppor-exemption`, `kb.non-resident-tax.withholding-on-rental-income`, `kb.non-resident-tax.foreign-resident-cgt-withholding`

**Renderer:** `data-table` + `opportunity-card`

**UI tab hint:** After you buy

**Parameters:**

Same as [Mode A ownership_planning](fhb-domestic-au.md#9-ownership_planning) with these critical differences:

```jsonc
{
  "monthly_obligations": { /* same as Mode A */ },
  "quarterly_obligations": { /* same as Mode A */ },
  "annual_obligations": {
    "building_insurance_premium": { "type": "money_per_year", "value": "<initial>" },
    "contents_insurance_optional": { "type": "money_per_year", "value": "<initial>" },
    "land_tax_check": { "type": "enum", "options": ["applicable_for_foreign_person", "to_verify"], "value": "applicable_for_foreign_person", "note": "Foreign owners pay land tax including surcharge in most states; no PPOR exemption" },
    "non_resident_tax_filing_required": { "type": "bool", "value": "<initial>" }
  },
  "foreign_person_specific_obligations": {
    "vacancy_fee_monitoring": {
      "annual_occupancy_threshold_days": { "type": "integer", "value": 183 },
      "fee_if_unoccupied_below_threshold": { "type": "money", "value": "<initial>", "note": "Double the FIRB application fee from 9 April 2024" },
      "annual_declaration_deadline": { "type": "date", "value": "<initial>" },
      "current_year_occupancy_status": { "type": "enum", "options": ["compliant_owner_occupier", "compliant_genuinely_rented", "at_risk", "non_compliant"], "value": "<initial>" },
      "occupancy_tracker_armed": { "type": "bool", "value": "<initial>" }
    },
    "non_resident_tax_obligations": {
      "rental_income_withholding_applicable": { "type": "bool", "value": "<initial>" },
      "cgt_on_eventual_sale_treatment": { "type": "string", "value": "Foreign-resident CGT applies; no PPOR exemption available for foreign-resident periods" },
      "annual_tax_filing_strategy": { "type": "string", "value": "<initial>" }
    }
  },
  "lifecycle_alerts": {
    "vacancy_declaration_reminder_armed": { "type": "bool", "value": true },
    "pr_grant_event_triggers_mode_switch": { "type": "bool", "value": true, "note": "When user becomes PR/citizen, switch to Mode A or C blueprint" },
    "refi_review_cadence_months": { "type": "integer", "value": 24 }
  }
}
```

**Outcome schema:** `ongoing_obligations`

```jsonc
{
  "type": "ongoing_obligations",
  "fields": {
    "total_monthly_outgoings_estimate": "money",
    "total_annual_outgoings_estimate": "money",
    "vacancy_fee_at_risk_amount": "money",
    "current_year_occupancy_status": "enum",
    "non_resident_tax_filing_required": "bool",
    "alert_triggers_armed": "array<{ trigger, action }>",
    "mode_switch_eligible": "bool"
  }
}
```

The `mode_switch_eligible` field signals when the user's status has changed (e.g., PR granted, citizenship granted) — at which point the platform offers to migrate the plan card to Mode A (fhb-domestic-au) or Mode C (investor-domestic-au) blueprint.

---

### 12. disposition ★ (NEW — the dispose-phase figure-owner, added 2026-07-11)

> **Added for parity** (`plan-card-lifecycle-restoration.md` §11.4, task 11). Mode B was the only mode with no dispose-phase figure owner at all — a foreign FHB can still face a forced or voluntary sale (visa status change, relocation), and the FIRB vacancy-fee obligation makes "what if I need to sell" a live question, not a hypothetical. **No new resolver code** — `fh_engine_disposition:fill/2` already dispatches Mode B onto the same `fill_owner_occupier/2` path Mode A uses (keyed on the absence of a `tax_optimised_structure` upstream outcome; Mode B never runs a `tax_structure` component). This section wires the existing, mode-general `disposition` component into Mode B's base turn.

**Goal:** Project the financial outcome of disposing of the property after a hold horizon `H` — the sale proceeds (growth-projected), the costs of selling, the loan payout, the CGT, and the net proceeds. Same shape as [Mode A's `disposition`](fhb-domestic-au.md#13-disposition); see that component for the full mechanism (§8.6). This entry documents only where Mode B's inputs/outputs diverge.

**Scope:** `base` — runs at onboarding against `target_price_range` + the hold horizon `H`; present only when `H` is set (same honest-partial default as every other mode: no disposal projection until the user asks "what if I sell in N years?").

**Inputs:** `buyer_profile.outcome` (`hold_horizon_years`, `target_price_range`, `intended_occupancy_use`) + `mortgage_finance.outcome` (`expected_borrowing_capacity`) + `cash_position.outcome` (`budget_envelope.total_cash_required`) + `ownership_planning.outcome` (`ongoing_obligations`). Runs **after `cash_position` + `ownership_planning`** (so the acquire + hold figures exist to place) — last in the base DAG.

**KB anchors:** `kb.property.capital-growth-bands`, `kb.selling-costs.agent-legal`, `kb.tax.cgt-main-residence-exemption`, `kb.lender.serviceability-basics` — the same four Mode A anchors; no Mode-B-specific KB content needed.

**Renderer:** `calculator`

**UI tab hint:** Cash calculator (pending §11.3's Flow/Budget restructure, task 13)

**Fill path:** resolver. No agent leaf — same as every other mode's disposition (growth/CGT/amortisation are KB-grounded, removed from the LLM's reach).

**Two Mode-B-specific calls, both grounded and explicit, not silent defaults:**

- **`intended_occupancy_use: "sole_occupier"` is asserted; `tax_residency` is deliberately left unset.** Mode A asserts both (a citizen/PR is definitionally an AU tax resident). Mode B's applicant tax residency is genuinely unknown at base — a foreign person may be a temporary resident or not yet in Australia — and CGT-consequential (the 2019 reform removed the main-residence exemption for foreign residents at time of sale, `kb.tax.cgt-main-residence-exemption`). Leaving `tax_residency` unset routes `cgt/1` to its `to_verify` branch unconditionally — `cgt_status` is **always `to_verify` for Mode B**, never `exempt`, by construction (mirrors how Mode D's `cgt_status` is always `to_verify` by the same mechanism, `investor-foreign-au.md` component 14).
- **`full_horizon_net_position` is honestly `null` for Mode B, permanently, not pending.** It PLACES `ownership_planning.ongoing_obligations.recurring_costs_estimate.statutory_band` — a field Mode B's foreign-person `ongoing_obligations` outcome (component 11 above) does not carry (it is built around FIRB compliance monitoring — vacancy fee, alerts, mode-switch eligibility — not a cost estimate). A correct Mode-B statutory band would need the foreign-owner land-tax surcharge, which `kb.tax.land-tax-by-state` deliberately never resolver-computes for **any** mode ("a per-property estimate would mislead without the portfolio-wide aggregate land value... kept out of the agent's reach"). The dispose-phase figures this component was added for (`sale_proceeds`/`selling_costs`/`loan_payout`/`cgt`/`net_proceeds`) are unaffected — only the full-horizon roll-up is gapped.

**Outcome schema:** `disposition` — identical shape to [Mode A's](fhb-domestic-au.md#13-disposition); repeated below since the compiler parses this fenced block per-blueprint, not by cross-reference.

```jsonc
{
  "type": "disposition",
  "fields": {
    "horizon_years": "integer|null",
    "sale_proceeds": "money_range|null",
    "selling_costs": "money_range|null",
    "loan_payout": "money_range|null",
    "cgt": "money_range|null",                        // always null for Mode B (to_verify path only — never the exempt path)
    "cgt_status": "enum [exempt, to_verify]",         // always to_verify for Mode B, by construction (tax_residency unset — see above)
    "net_proceeds": "money_range|null",
    "full_horizon_net_position": "money_range|null",  // always null for Mode B (permanent gap — see above, not honest-partial-pending)
    "dispose_cash_events": "array<{ id: string, phase: string, label: localized_text, direction: enum [out, in], amount: money_range|null, is_estimate: bool, timing: enum [one_off, recurring], period: enum [once, monthly, quarterly, annual]|null, counterparty: string, source_component: string }>",
    "key_assumptions": "array<localized_text>"
  }
}
```

---

### 13. purchase_journey ★ (NEW — the whole-of-journey swimlane, added 2026-07-11)

> **Added for lifecycle-spine parity** (`plan-card-lifecycle-restoration.md` §11.5, task 12). Mode B is an owner-occupier FHB by mode definition, so this component reuses **Mode A's own four-actor swimlane shape** (You / Government / Lender / Services), not Modes C/D's six-actor investor set (§3.3: "B = A's shape + a FIRB gate + a currency-transfer milestone + surcharge"). Same shape as [Mode A's `purchase_journey`](fhb-domestic-au.md#10-purchase_journey); see that component for the full mechanism (two-spines, lifecycle-simulation-model §2/§7). This entry documents only where Mode B's content diverges.

**Goal:** Render the whole-of-journey lifecycle swimlane — phases × actors × cells, the legal/prose spine plus the money flows PLACED from every upstream figure-owner. Computes no figure of its own (one-computer-per-figure).

**Scope:** `base` — runs at onboarding; the terminal Dispose phase/column renders only once a hold horizon `H` is set (honest-partial, same rule as every mode).

**Inputs:** `cash_position.outcome` (`budget_envelope`, incl. its `cash_events`) + `ownership_planning.outcome` (`ongoing_obligations` — for the Own-phase recurring costs, honestly empty for Mode B; see below) + `disposition.outcome` (the Dispose-phase `dispose_cash_events`). Runs **last among the base figure-owners**, after `disposition`.

**KB anchors:** `kb.journey.fhb-foreign-path` — Mode B's own bilingual swimlane copy doc (layers the FIRB gate + transfer milestone + surcharge onto Mode A's four-actor/six-phase structure; no new KB anchors otherwise, same discipline as Mode A's `purchase_journey`).

**Renderer:** `swimlane-diagram`

**UI tab hint:** Temporal flow (pending §11.3's Flow/Budget restructure, task 13)

**Fill path:** resolver. No agent leaf — the journey structure is generic KB content; the money cells are placed, never recomputed (`fh_engine_journey:fill_fhb_foreign/1`).

**One grounded call, not a silent default: Mode B's Own-phase recurring cell stays honestly absent.** Mode A's `own_recurring_cells/1` places a yearly council-rates/water band from `ongoing_obligations.recurring_costs_estimate.statutory_band` — a field Mode B's foreign-person `ownership_planning` outcome (component 11) does not carry (built around FIRB vacancy-fee/alert monitoring, not a cost estimate — the same gap `disposition`'s `full_horizon_net_position` already discloses, task 11). The shared `money_cells/2` builder is reused unchanged; it simply emits no recurring cell when the band is absent (honest-partial, not a fabricated figure).

**Outcome schema:** `journey_swimlane` — identical shape to [Mode A's](fhb-domestic-au.md#10-purchase_journey); repeated below since the compiler parses this fenced block per-blueprint, not by cross-reference.

```jsonc
{
  "type": "journey_swimlane",
  "fields": {
    "phases": "array<{ id: string, label: localized_text }>",
    "actors": "array<{ id: string, label: localized_text }>",
    "cells": "array<{ phase: string, actor: string, item: localized_text, flow_marker: enum [none, document, milestone, money_out, money_in], amount: money_range|null, counterparty: string|null, source_component: string }>",
    "interactions": "array<{ from_actor: string, to_actor: string, phase: string, flows: array<{ label: localized_text, direction: enum [out, in], amount: money_range }> }>",
    "key_assumptions": "array<localized_text>"
  }
}
```

---

### 14. phase_playbook ★ (NEW — the per-phase checklist + risks, added 2026-07-11)

> **Added for lifecycle-spine parity** (`plan-card-lifecycle-restoration.md` §11.5, task 12). Same shape as [Mode A's `phase_playbook`](fhb-domestic-au.md#12-phase_playbook); see that component for the full mechanism. This entry documents only where Mode B's content diverges.

**Goal:** Render, per lifecycle phase, the ordered "what you do, in what order" action checklist plus the often-seen risks + mitigations — the actionable layer behind `purchase_journey`'s swimlane.

**Scope:** `base` — runs at onboarding, alongside every phase (the terminal `dispose` phase's actions/risks are always present in the outcome; the swimlane's own Dispose column is what's honest-partial-gated on `H`).

**Inputs:** `cash_position.outcome` (`budget_envelope.cash_events`, for `budget_ref` validation only — the same harvested-id-set mechanism every mode uses).

**KB anchors:** `kb.journey.fhb-foreign-phase-actions` (the per-phase action checklist — FIRB application + cross-border transfer steps layered onto Mode A's own action set; no `preparation`/`eligibility` component_refs since Mode B has neither, replaced by `firb_workflow`/`mortgage_finance`), `kb.risks.fhb-foreign-by-phase` (the per-phase risk-flag-list — compounding Mode A's owner-occupier risks with FIRB/cross-border risks, each grounded in an owning KB doc per that document's own "Risk provenance" section).

**Renderer:** `checklist` + `risk-flag-list`

**UI tab hint:** Temporal flow (pending §11.3's Flow/Budget restructure, task 13)

**Fill path:** resolver. No agent leaf — actions, ordering, risks and mitigations are bilingual KB content keyed by phase; the model never authors the risk list (reliability is structural, not a judge).

**Outcome schema:** `phase_playbook` — identical shape to [Mode A's](fhb-domestic-au.md#12-phase_playbook); repeated below since the compiler parses this fenced block per-blueprint, not by cross-reference.

```jsonc
{
  "type": "phase_playbook",
  "fields": {
    "phases": "array<{ phase: string, actions: array<{ id: string, order: integer, budget_ref: string|null, component_ref: string|null, label: localized_text, detail: localized_text, status: enum [not_started, done] }>, risks: array<{ severity: enum [low, medium, high], item: localized_text, action: localized_text }> }>",
    "key_assumptions": "array<localized_text>"
  }
}
```

---

## KB anchor index (for this blueprint)

73 slugs referenced (kb.firb.status-determination dropped 2026-10-06: Mode B sets firb_required by definition and never evaluates it, #6). Italics mark Mode B-only anchors (not in Mode A).

| Slug | Component(s) | Owns |
|---|---|---|
| `kb.firb.established-dwelling-ban` | 1, 4 | The 1 Apr 2025 – 30 Jun 2029 established-dwelling ban on foreign persons |
| *`kb.visas.au-temporary-residency-classes`* | 1 | AU temporary residency visa classes and their FIRB implications |
| *`kb.au-temp-residents.banking-and-tax-basics`* | 1 | Banking and tax basics for AU temporary residents |
| *`kb.vietnamese-family.financial-patterns`* | 2 | Vietnamese family financial pooling patterns, decision authority norms |
| *`kb.cross-border.decision-authority-cultural`* | 2 | Cultural patterns of cross-border family decision-making |
| *`kb.bilingual.coordination-norms`* | 2 | Bilingual coordination patterns for VN-AU families |
| *`kb.firb.eligible-property-types-foreign-persons`* | 3 | What property types foreign persons can buy (new build / vacant land only) |
| *`kb.firb.fee-tiers-by-value`* | 3, 4 | FIRB application fee tiers by property value |
| `kb.property.suburb-risk-factors` | 3 | Suburb-level risk |
| `kb.property.comparables-methodology` | 3 | Comparable sales methodology |
| `kb.strata.health-indicators` | 3, 8 | Strata report red flags |
| `kb.building-types.risk-by-type` | 3 | Risk profiles by property type |
| *`kb.off-the-plan.risk-considerations`* | 3 | Off-the-plan specific risks (relevant since foreign persons restricted to new builds) |
| *`kb.firb.application-process`* | 4 | FIRB application end-to-end process |
| *`kb.firb.fee-schedule-current`* | 4, 5 | Current FIRB fee schedule (2025–26 cycle) |
| *`kb.firb.documents-required`* | 4 | Standard FIRB application document list |
| *`kb.firb.timelines-standard`* | 4 | Standard FIRB decision timelines |
| *`kb.firb.exemption-certificates-developer`* | 4 | Developer new-dwelling exemption certificate pathway |
| *`kb.firb.approval-conditions-typical`* | 4 | Typical FIRB approval conditions |
| *`kb.firb.penalties-non-compliance`* | 4 | Penalties for FIRB non-compliance |
| `kb.stamp-duty.calc-by-state` | 5 | Stamp duty by state |
| *`kb.foreign-buyer-surcharge.by-state`* | 5 | Foreign-buyer stamp duty surcharge by state |
| *`kb.fx.typical-spreads-vnd-aud`* | 5, 6 | Typical VND/AUD FX spreads by provider |
| `kb.buyer-costs.inspections-conveyancing-fees` | 5 | Typical buyer-side costs |
| `kb.cash-reserve.lender-expectations` | 5 | Lender expectations (higher buffer for non-resident) |
| *`kb.lmi.calculation-for-foreign-persons`* | 5 | LMI calculation when LVR >80% for foreign person |
| *`kb.lender.non-resident-friendly-shortlist`* | 5 | Non-resident-friendly lender criteria (not a named-lender recommendation) |
| *`kb.lender.temp-resident-lending-policies`* | 5 | Temporary-resident lending policies |
| *`kb.lender.485-visa-treatment`* | 5 | 485 graduate-visa lending treatment |
| *`kb.lender.foreign-buyer-deposit-requirements`* | 5 | Foreign-buyer deposit requirements (typically 30%+) |
| *`kb.lender.firb-approval-as-condition-precedent`* | 5 | FIRB approval as loan condition precedent |
| *`kb.lender.documentation-non-resident`* | 5 | Non-resident loan documentation requirements |
| *`kb.fx.loan-currency-considerations`* | 5 | Loan-currency considerations (AUD-denominated loan; FX is on VN-side capital flow) |
| *`kb.fx-providers.wise-ofx-bank-comparison`* | 6 | FX provider comparison for VN-AU transfers |
| *`kb.vn-capital-controls.sbv-thresholds-2026`* | 6 | SBV outbound transfer thresholds requiring approval |
| *`kb.vn-capital-controls.declared-purpose-categories`* | 6 | Declared-purpose categories for SBV transfers |
| *`kb.au-aml-ctf.bank-due-diligence-expectations`* | 6 | AU bank enhanced due diligence on cross-border funds |
| *`kb.au-aml-ctf.source-of-funds-documentation`* | 6 | Source-of-funds documentation standards |
| *`kb.vn-pdp.cross-border-data-transfer`* | 6 | Vietnamese PDP Decree 13/2023 cross-border transfer requirements |
| `kb.auction.rules-by-state` | 7 | Auction rules |
| `kb.cooling-off.by-state` | 7, 9 | Cooling-off periods |
| `kb.negotiation.patterns-by-market-condition` | 7 | Negotiation patterns |
| `kb.agent-tactics.detection` | 7 | Agent tactics detection |
| *`kb.firb.contract-conditional-on-approval`* | 7 | Subject-to-FIRB-approval contract clauses |
| *`kb.foreign-buyer.subject-to-firb-clauses`* | 7 | Standard FIRB contract conditions |
| `kb.contract-of-sale.review-points-by-state` | 8 | Standard CoS review |
| `kb.s32.review-points` | 8 | Section 32 review (VIC) |
| `kb.building-pest.interpretation` | 8 | Building and pest report interpretation |
| `kb.strata-report.red-flags` | 8 | Strata report red flags |
| `kb.special-conditions.standard-set` | 8 | Standard special conditions |
| *`kb.firb.contract-clauses-required`* | 8 | FIRB-required contract clauses for foreign person |
| *`kb.cross-border.source-of-funds-letter-template`* | 8 | Source-of-funds letter template |
| `kb.settlement.process-by-state` | 9 | Settlement process by state |
| `kb.pexa.settlement` | 9 | PEXA mechanics |
| `kb.insurance.timing-of-risk-pass` | 9 | Insurance timing |
| `kb.lender-docs.standard-timeline` | 9 | Lender document timeline |
| *`kb.firb.approval-to-settlement-timeline`* | 9 | FIRB approval to settlement timeline |
| *`kb.cross-border-settlement.coordination-best-practices`* | 9 | Cross-border settlement coordination |
| `kb.ongoing-costs.rates-water-strata` | 10 | Ongoing cost ranges |
| `kb.refinance.windows-and-triggers` | 10 | Refi windows |
| `kb.maintenance.budget-by-property-type` | 10 | Maintenance budget heuristics |
| *`kb.firb.vacancy-fee-rules-2026`* | 10 | FIRB vacancy fee rules |
| *`kb.firb.vacancy-fee-double-from-2024`* | 10 | Doubled vacancy fee from 9 April 2024 |
| *`kb.non-resident-tax.cgt-no-ppor-exemption`* | 10 | Foreign resident CGT — no PPOR exemption |
| *`kb.non-resident-tax.withholding-on-rental-income`* | 10 | Non-resident rental income withholding |
| *`kb.non-resident-tax.foreign-resident-cgt-withholding`* | 10 | Foreign resident CGT withholding on sale |
| `kb.property.capital-growth-bands` | 12 | The capital-growth assumption band `disposition` compounds over the hold horizon H — 3–6% p.a. from ABS Total Value of Dwellings (CONVENTION), shared with Mode A |
| `kb.selling-costs.agent-legal` | 12 | Agent commission + legal/marketing bands at sale |
| `kb.tax.cgt-main-residence-exemption` | 12 | Main-residence CGT exemption + the non-resident-at-disposal trap (Mode B always routes to `to_verify` via this trap) |
| `kb.lender.serviceability-basics` | 12 | The representative product rate `disposition` amortises `expected_borrowing_capacity` at, for the loan-payout-at-horizon figure |
| *`kb.journey.fhb-foreign-path`* | 13 | Mode B's bilingual swimlane copy — FIRB gate + transfer milestone + surcharge layered onto Mode A's four-actor shape |
| *`kb.journey.fhb-foreign-phase-actions`* | 14 | Mode B's per-phase action checklist — FIRB application + cross-border transfer steps |
| *`kb.risks.fhb-foreign-by-phase`* | 14 | Mode B's per-phase risk-flag-list — FIRB/cross-border risks compounding Mode A's owner-occupier risks |

---

## Renderer vocabulary used

This blueprint uses 10 of the constrained renderer vocabulary defined in [§11.9 in architecture.md](../architecture/architecture.md#119-blueprint-as-data-model--presentation-specification):

| Renderer | Used by component(s) |
|---|---|
| `summary-card` | 1 buyer_profile, 3 property_assessment |
| `family-view-card` | 2 family_context (Mode B exclusive) |
| `firb-workflow-card` | 4 firb_workflow (Mode B exclusive), 6 cross_border_funding |
| `calculator` | 5 cash_position, 12 disposition |
| `buying-strategy-card` | 7 buying_strategy |
| `risk-flag-list` | 8 due_diligence, 14 phase_playbook |
| `checklist` | 6 cross_border_funding, 8 due_diligence, 9 settlement_prep, 14 phase_playbook |
| `swimlane-diagram` | 9 settlement_prep, 13 purchase_journey |
| `data-table` | 10 ownership_planning |
| `opportunity-card` | 10 ownership_planning |

Mode B activates two Mode-B-exclusive renderers (`family-view-card`, `firb-workflow-card`) that don't appear in Mode A.

---

## Parameter signal vocabulary

This blueprint uses the same signal placeholders as Mode A, with one addition for Mode B:

| Signal | Used for |
|---|---|
| `<initial>` | Never-filled parameter — most common |
| `<from_property_card>` | Pulled from property selection |
| `<from_buyer_profile>` | Pulled from `buyer_profile.outcome` |
| `<from_family_context>` | Pulled from `family_context.outcome` (Mode B exclusive) |
| `<from_property_assessment>` | Pulled from `property_assessment.outcome` |
| `<from_firb_workflow>` | Pulled from `firb_workflow.outcome` (Mode B exclusive) |
| `<from_cash_position>` | Pulled from `cash_position.outcome` |

**Fill-path classification.** Per [agentic-boundary.md](../architecture/agentic-boundary.md), a leaf carrying `agent_reasoning_required: true` is agent-path; all others resolve deterministically. Mode B's FIRB mechanics (classification, eligibility predicate, fee + surcharge schedules) and cross-border compliance (SBV threshold, declared-purpose category, provider selection, withholding) are **all resolver** — rules and lookups. The only Mode-B-specific agent leaves are the subjective fit scores (`property_assessment.fit_against_buyer.lifestyle_match_score_au_member`, `rentability_score_if_unoccupied`) and the cross-border document-gap flags (`due_diligence.cross_border_flags.*`). Shared components (`buying_strategy`, `due_diligence` base, `settlement_prep`, `ownership_planning`) inherit Mode A's classification.

---

## Cross-component output dependency graph

```
buyer_profile          → outcome: profile
family_context         → outcome: family_funding_plan       (reads: profile)
property_assessment    → outcome: property_fit              (reads: profile, family_funding_plan)
firb_workflow          → outcome: firb_status               (reads: profile, property_fit)
cash_position          → outcome: budget_envelope           (reads: profile, family_funding_plan, property_fit, firb_status)
cross_border_funding   → outcome: transfer_plan             (reads: family_funding_plan, budget_envelope)
buying_strategy        → outcome: bid_plan                  (reads: property_fit, budget_envelope, firb_status)
due_diligence          → outcome: risk_assessment           (reads: property_fit, uploaded_docs)
settlement_prep        → outcome: settlement_checklist      (reads: property_fit, bid_plan, firb_status, transfer_plan)
ownership_planning     → outcome: ongoing_obligations       (reads: property_fit, profile)
disposition            → outcome: disposition               (reads: profile, budget_envelope, ongoing_obligations)
purchase_journey       → outcome: journey_swimlane          (reads: budget_envelope, ongoing_obligations, disposition)   // harvests cash_events off budget_envelope + disposition's dispose_cash_events; places, computes nothing
phase_playbook         → outcome: phase_playbook            (reads: budget_envelope)   // harvests cash_events off budget_envelope only, to validate action budget_refs
```

No cycles. Mode B specifically adds two critical-path dependencies: `firb_status` blocks `buying_strategy` (no unconditional bid without FIRB approval) and `transfer_plan` is a critical-path input to `settlement_prep` (currency transfer is on the settlement critical path). `purchase_journey`/`phase_playbook` (added 2026-07-11, task 12) run **last of all** — `purchase_journey` reads `ongoing_obligations` even though Mode B's own foreign-person outcome carries no `recurring_costs_estimate` (the Own-phase recurring cell simply stays absent, honest-partial — see component 13's own note); `phase_playbook` follows, reading no journey output directly (it harvests `cash_events` independently, the same generic mechanism every mode uses). Both positioned after every figure-owner including `disposition`, mirroring every other mode's "figure-owners, then the spine that places them" DAG shape.

---

## Open questions / future iteration

These deferred from the current design:

1. **Mode switch on PR grant** — when the AU member becomes PR or citizen, the user is no longer a foreign person. The plan card should signal a mode switch to `fhb-domestic-au` or `investor-domestic-au`. The current design captures this signal but doesn't specify the refresh UX; a future iteration should specify.
2. **Multi-jurisdiction tax planning** — Vietnamese parents may face Vietnamese tax implications on funding AU property. This blueprint doesn't address VN-side tax obligations. A future iteration should add a `vn_side_tax_implications` component or sub-component.
3. **Family decision rollback** — if the VN parent decides not to fund after AU member commits, what's the rollback path? A future iteration needs a `decision_rollback` workflow.
4. **Currency hedging** — large transfers exposed to VND/AUD volatility between commitment and transfer. A future iteration could add hedging guidance to `cross_border_funding`.
5. **Joint family applications** — if multiple AU-side members co-buy, the `buyer_profile` and `family_context` need to capture multiple AU members. The current design assumes a single AU member; a future iteration should support joint.

---

## Document control

- **Status:** draft, May 2026 — second concrete blueprint specification (Mode B)
- **Author:** Strategic design synthesis (Claude + maintainer)
- **Consumers:** Offline KB agent, user-facing planning agent, migration script, UI renderer layer
- **Companion blueprints:** [`fhb-domestic-au`](fhb-domestic-au.md) (Mode A — drafted). Pending: `investor-domestic-au` (Mode C), `investor-foreign-au` (Mode D).
- **Disclaimer:** This is a working spec, not a regulatory document. FIRB regulations, foreign-buyer surcharge percentages, vacancy-fee rules, Vietnamese capital control thresholds, AML/CTF requirements, and non-resident tax treatments must be confirmed against authoritative sources (resolved via kb_anchor lookups) at runtime. Wrong advice across jurisdictions has real legal consequences in both Australia and Vietnam; the blueprint must be paired with rigorous KB curation, agent reasoning verification, and Vietnam-licensed legal partnership.
