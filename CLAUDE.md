# CLAUDE.md

Orientation for Claude Code working on this project. Read this every session.

## What this is

**Vietnamese property lifecycle planning service** — AI-augmented planning for the Vietnamese diaspora investing in Australian property, with human-curated property search (Tìm Nhà) when buyers are ready. Independent. Paid by users.

This is a **lifecycle planning service**, NOT a property tech platform. The data moat is Vietnamese buyer demand + cultural curation + agentic planning — not property data.

## Status

**Pre-implementation.** Documentation complete; first concrete blueprints drafted. About to start Wedge 1a (Vietnamese-AU FHB base plan, 4–6 weeks). Python project scaffolded (`pyproject.toml`, `.venv`); no production code yet.

## Documentation

Everything strategic, architectural, and product-facing lives in [`docs/`](docs/). Read [`docs/README.md`](docs/README.md) first; it's the index and audience guide.

Critical reference docs by purpose:

| If you need | Read |
|---|---|
| Strategic positioning, REA economics, wedge sequence | [`docs/03-strategy.md`](docs/03-strategy.md) |
| Three-layer architecture, blueprint model, property pipeline | [`docs/architecture/architecture.md`](docs/architecture/architecture.md) |
| UX model, four user modes, onboarding flow, plan card lifecycle | [`docs/05-ux-model.md`](docs/05-ux-model.md) |
| The four concrete plan card blueprints | [`docs/blueprints/`](docs/blueprints/) |
| What a real property card looks like (test output) | [`docs/samples/property-card-example.html`](docs/samples/property-card-example.html) |

**The docs are the working agreement.** As implementation decisions get made and edge cases emerge, update the docs in place. Don't let them drift behind the code.

## Critical architectural constraints

These are not preferences. They are decisions locked into the architecture. Violating them undoes substantial strategic work.

1. **Plan-first onboarding, NOT property-first.** Users enter with mode + state + target price range + zone, NOT by selecting a specific property. The base plan generates immediately.

2. **Base plan + property addenda.** Every plan card has one persistent base plan (property-agnostic) and zero-or-more property addenda (one per attached property). Components have `scope: base | per-property | both`.

3. **No property scraping pipeline.** We do not operate at scale in the property data acquisition market. Property data flows only via narrow paths: suburb enrichment from public feeds (ABS), user URL paste, browser extension, Tìm Nhà human curation, and (later) partner REA push. See [`docs/architecture/architecture.md#1110-property-data-pipeline--narrow-and-demand-driven`](docs/architecture/architecture.md).

4. **Fully agentic.** The planning agent reasons over context (KB + user state + uploads) and produces structured output. Tìm Nhà human curators are a tool the agent invokes, not a replacement for agency.

5. **Component-flow architecture.** Each blueprint is a directed acyclic pipeline of components with `goal`, `inputs`, `parameters`, `outcome_schema`. Outcomes are typed interfaces; downstream components read outcomes, not upstream parameters. See [`docs/architecture/architecture.md#119-blueprint-as-data-model--presentation-specification`](docs/architecture/architecture.md).

6. **Slug-based KB references.** KB content lives in `docs/kb/*.md` files with frontmatter (`slug:`, `effective_from:`, `last_verified:`). Blueprints reference KB via slugs (e.g., `scheme.fhg`, `kb.firb.application-process`). Migration script validates slugs at deploy.

    **No semantic versioning (CI/CD).** Blueprints and KB are not version-numbered (no `v1.0`, no `@1.2` pinning). The repo is the source of truth; deploy publishes the latest, git holds the history. Reproducibility for the regulated audit trail comes from each filled plan card recording the **deploy commit SHA + a snapshot of the resolved KB content** at fill time. (Roadmap phase names like "Wedge 1" are planning language, not artifact versions.)

7. **Constrained renderer vocabulary.** Blueprints can only use renderers from the enum defined in §11.9 (`summary-card`, `swimlane-diagram`, `checklist`, `data-table`, `calculator`, `buying-strategy-card`, `risk-flag-list`, `comparison-grid`, `opportunity-card`, `scheme-stack-card`, `firb-workflow-card`, `family-view-card`, `decision-trail`). New renderers are intentional design decisions, not arbitrary additions.

8. **Independence preserved.** Buyer is the customer. REAs are partners under fee structures that never bias recommendations. No commission share, no per-property-sold fees. Buyer chooses; REA pays when chosen. See [`docs/03-strategy.md#85-rea-partnership-economics--two-tier-complementary-model`](docs/03-strategy.md).

9. **Agent grounds in current state, NOT conversation history.** System prompt is dynamically constructed from current plan card state + property context + uploads + KB anchors. Conversation log is preserved for user re-reading; not for agent grounding. Saves tokens; prevents drift.

10. **FIRB status as first-class user attribute.** Every flow branches on it. Foreign persons cannot buy established dwellings 1 Apr 2025 – 30 Jun 2029. Misadvice has real harm; build the gate into the architecture, not as a disclaimer.

## Four user modes

| Mode | Audience | FIRB | Blueprint |
|---|---|---|---|
| A | Vietnamese-AU citizen / PR FHB | No | [`blueprints/fhb-domestic-au.md`](docs/blueprints/fhb-domestic-au.md) |
| B | Vietnam-parent funding AU child / AU temp resident FHB | Yes | [`blueprints/fhb-foreign-au.md`](docs/blueprints/fhb-foreign-au.md) |
| C | Vietnamese-AU investor (citizen / PR) | No | [`blueprints/investor-domestic-au.md`](docs/blueprints/investor-domestic-au.md) |
| D | Vietnam-located investor | Yes | [`blueprints/investor-foreign-au.md`](docs/blueprints/investor-foreign-au.md) |

Wedge 1 targets Mode A only. Mode B / C / D blueprints are drafted but not in scope for Wedge 1a.

## Where to start building (Wedge 1a)

In order of value + dependency:

1. **DB schema + migration script** — `kb_anchors`, `blueprints`, `plan_cards`, `sessions`, `suburbs`, `properties` tables. Migration script reads `docs/kb/*.md` and `docs/blueprints/*.md`, validates slugs + renderer enum, generates SQL. Note: `properties` table is OPTIONAL in v1 — not load-bearing.

2. **First KB doc** — `docs/kb/scheme/federal/fhg.md` with frontmatter + body. Validates the markdown format. Then `scheme/state/qld/fhnhc.md`, `scheme/federal/fhss.md`, `firb/established-dwelling-ban.md` to bootstrap Mode A KB.

3. **Suburb enrichment ingestion** — ABS Data API adapter for SAL-level Census 2021 data (Vietnamese ancestry %, demographics, family composition, dwelling characteristics). State education / planning / flood adapters as separate jobs. RBA FX rate daily feed. CoreLogic / PropTrack are PAID, deferred — don't subscribe yet.

4. **Mode A FHB blueprint loader + planning agent (base scope only)** — load `fhb-domestic-au.md`, validate kb_anchors resolve, implement the agent prompt for each `scope: base` component (`buyer_profile`, `eligibility`, `mortgage_finance` base, `cash_position` base, `ownership_planning` base).

5. **Onboarding UI** — mode picker, state picker, VND/AUD price range, map zone selection, intent tags. Saves to `plan_cards` table.

6. **Base plan rendering** — render Mode A base plan from filled blueprint components. Reuse the design language from [`docs/first_home_buyer_plan.html`](docs/first_home_buyer_plan.html) as the visual template.

7. **Suburb intelligence map** — Leaflet / Mapbox + ABS-data overlays. Vietnamese-community proximity is the killer layer; ship that first.

8. **Tìm Nhà request flow** — user submits request from base plan; agent generates search brief; brief lands in curator queue. Curator side can be manual / spreadsheet-driven in v1. Defer when ready.

9. **User URL paste handler** — synchronous fetch of REA / Domain via headless Chrome (Playwright); normalise to canonical Property schema; create property addendum. This activates Phase B (per-property components).

## Conventions

### File / repo organisation

```
firsthomey/
├── CLAUDE.md (this file)
├── docs/                         (strategic + architectural docs — the working agreement)
│   ├── README.md
│   ├── 01-market.md, 02-competitive-landscape.md, 03-strategy.md, 05-ux-model.md, 06-roadmap.md
│   ├── architecture/                  (architecture doc + design principles)
│   │   ├── architecture.md            (three-layer architecture, blueprint model, property pipeline)
│   │   ├── principles.md
│   │   └── erlang-design-checklist.md
│   ├── blueprints/
│   │   ├── fhb-domestic-au.md
│   │   ├── fhb-foreign-au.md
│   │   ├── investor-domestic-au.md
│   │   └── investor-foreign-au.md
│   ├── kb/                       (to be created: curated KB markdown files with frontmatter)
│   │   ├── scheme/
│   │   ├── firb/
│   │   ├── lender/
│   │   ├── property/
│   │   └── ... (one slug per file; folder structure mirrors slug namespace)
│   ├── samples/
│   │   └── property-card-example.html
│   └── first_home_buyer_plan.html (Mode A example output, design reference)
├── src/                          (to be created: production code)
├── tests/                        (to be created)
├── migrations/                   (to be created: SQL migrations)
├── pyproject.toml
└── .venv/
```

### Code style (when written)

- Python with type hints throughout
- Pydantic for blueprint / KB / plan card schema validation
- FastAPI for the user-facing planning agent service
- PostgreSQL with `jsonb` columns for blueprint / plan card content
- Headless Chrome (Playwright) for the synchronous URL fetch path
- The agentic layer uses Claude API via the Anthropic SDK; no LangChain or similar wrapper unless materially justified

### Testing approach

- KB validation tests: every `kb_anchors` slug in every blueprint resolves
- Blueprint validation tests: every `renderer` is in the enum; pipeline is acyclic
- Component eval harnesses: per-component eval sets with expected `outcome` shape
- Mode-specific integration tests: walk through a worked example (e.g., Sarah's day-7 plan refinement) end-to-end

## Don't

- **Don't add property scraping infrastructure.** §11.10 deliberately scopes out the multi-source scraping pipeline. If a feature seems to need it, the design is wrong.
- **Don't make plan card creation depend on a specific property.** Base plan must work with no property data.
- **Don't recommend specific lenders / brokers in a way that requires AFSL or ACL licensure.** Stay in "decision support" / "informational" mode. ASIC line is real and personal liability is on the table.
- **Don't give financial advice or legal advice** without a licensed professional in the loop. Bilingual disclaimers everywhere.
- **Don't store Vietnam-located user data outside Vietnam** without Decree 13/2023 (PDP) compliance review. Plan for VN-side data residency from Wedge 2.
- **Don't bake property listing scraping into any module.** The synchronous user-URL-paste path is the only place a single page is fetched, and it's user-initiated.
- **Don't merge buyer_profile.debts data into mortgage_finance parameters.** Profile holds facts; mortgage_finance reasons about facts. Keep the separation per §11.9 component-flow principle.
- **Don't use conversation history as agent grounding.** Plan card state + current query is the agent's context. History is for user re-reading.
- **Don't add new renderers without updating the §11.9 vocabulary table.** New renderer = intentional design decision.

## Hard regulatory constraints

- **ASIC (Australia)** — no financial advice without AFSL; no credit advice without ACL. Information / decision support only.
- **FIRB (foreign persons)** — established-dwelling ban 1 Apr 2025 – 30 Jun 2029. Approval required before contract. Foreign-buyer stamp duty surcharge. Vacancy fee.
- **AUSTRAC (AML/CTF)** — never custodian of funds. Money transfer must go through licensed partners (Wise, OFX, partner banks).
- **VN PDP (Decree 13/2023)** — applies to Vietnam-located users. Cross-border data transfer requires Impact Assessment + government notification.
- **VN capital controls** — SBV approval thresholds for outbound transfers. Educate on legitimate channels; never recommend informal routes.

## Common pitfalls

- "We need property data to plan" — no. The base plan is property-agnostic. Only Phase B addenda need property data.
- "Just scrape REA" — no. Legally fraught, operationally fragile, and not where our value lies.
- "Let the agent decide which lender to recommend" — careful. Agent surfaces lender shortlist + reasoning; user picks. Crossing the line into "recommendation" can trigger credit-advice licensure issues.
- "Conversation history feels useful" — for user re-reading yes, for agent grounding no. Keep them separate.
- "Just make the property card the central artifact" — no. The plan card is the central artifact. Properties are inputs to it via property addenda.

## When in doubt

1. Re-read the relevant section of the docs (the README has an audience-guided reading path).
2. Update the docs to reflect the new understanding before writing code that depends on the new understanding.
3. Component-flow questions → §11.9 in `docs/architecture/architecture.md`.
4. UX / surface questions → §13 in `docs/05-ux-model.md`.
5. Strategic positioning questions → §8 in `docs/03-strategy.md`.
6. "Should the platform do X?" → if X requires a market position in property data acquisition, the answer is no.

## Maintenance

This file should evolve as the project evolves. Specifically:

- Add commands to "Where to start building" as they get implemented and stabilise.
- Note any architectural decisions made during implementation that aren't yet in the docs.
- Update the "Don't" list when a new pitfall is encountered.
- Keep this file under ~200 lines. If it grows, refactor — link out to docs/ instead.

Last updated: May 2026 — pre-implementation, all blueprints drafted, ready for Wedge 1a.
