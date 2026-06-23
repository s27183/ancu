# CLAUDE.md

Orientation for Claude Code working on this project. Read this every session.

## What this is

**Vietnamese property lifecycle planning service** — AI-augmented planning for the Vietnamese diaspora investing in Australian property, with human-curated property search (Tìm Nhà) when buyers are ready. Independent. Paid by users.

This is a **lifecycle planning service**, NOT a property tech platform. The data moat is Vietnamese buyer demand + cultural curation + agentic planning — not property data.

## Status

**Wedge 1a — build-complete (2026-06-23), not yet deployed.** The Mode-A FHB lifecycle plan works end-to-end. **Engine:** the full agentic stack — cowboy `/api/engine/*` gateway, `fh_engine_turn` gen_statem driving a supervised Python sidecar (real Anthropic Agent-SDK planner), resolver/agent two-path fill, FIRB→ASIC→AML compliance + outcome-conformance gates, `usage` metering, bilingual Q&A, `plan_card_events` SOT + SSE fan-out. **Shell:** the 8-S chain — SvelteKit SPA (map-first home, onboarding, plan projection + chat, the two-spine lifecycle: swimlane + cash calculator + the full buy→hold→sell temporal flow with disposition/full-horizon), Erlang/OTP backend (two-JWT identity, magic-link + Google login, commerce), all over the engine API. **Verified:** the whole income→borrowing-capacity→disposition full-horizon chain was confirmed **full-stack live-pixel (EN+VI)** on a real Footscray card — figures matching the engine to the dollar. Progress SOT = [`docs/grounding-checklist.md`](docs/grounding-checklist.md) (items 8/9/10/11 all `[x]`). **Remaining open work is deliberately trigger-gated:** identity-layer unification → Wedge 2 (item 2); investor-tax KB (`kb.tax.*`/`kb.investor.*`) → when Mode C ships. Next up: commit + a deploy pass (env: `CLAUDE_CODE_OAUTH_TOKEN` for the Q&A sidecar; the dev `qa_smoke` is green with it set).

## Documentation

Everything strategic, architectural, and product-facing lives in [`docs/`](docs/). Read [`docs/README.md`](docs/README.md) first; it's the index and audience guide.

Critical reference docs by purpose:

| If you need | Read |
|---|---|
| Strategic positioning, REA economics, wedge sequence | [`docs/03-strategy.md`](docs/03-strategy.md) |
| **The whole picture** — every structure (blueprint, KB, foundations, agentic flow, plan card, engine/shell) and how they relate across planes, in diagrams (**read first**) | [`docs/architecture/structure-map.md`](docs/architecture/structure-map.md) |
| Engine/shell split, three-layer architecture, blueprint model, property pipeline | [`docs/architecture/architecture.md`](docs/architecture/architecture.md) |
| Engine↔shell boundary: primitives, events, metering, compliance gate | [`docs/architecture/engine-contract.md`](docs/architecture/engine-contract.md) |
| When an operation needs the agent vs deterministic rules (resolver/agent decision rule) | [`docs/architecture/agentic-boundary.md`](docs/architecture/agentic-boundary.md) |
| How the reasoning runs: agent types, dynamic prompt structure, vendor layer, context management | [`docs/architecture/agentic-flow.md`](docs/architecture/agentic-flow.md) |
| Units of isolation: plan card vs turn, per-card serialization, conversation persistence, vendor config | [`docs/architecture/isolation-model.md`](docs/architecture/isolation-model.md) |
| UX model, four user modes, onboarding flow, plan card lifecycle | [`docs/04-ux-model.md`](docs/04-ux-model.md) |
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

6. **Slug-based KB references.** KB content lives in `docs/kb/**.md` files with frontmatter (`slug:`, `effective_from:`, `last_verified:`). A doc's **slug is its path under `docs/`** — `/`→`.`, `.md` dropped, no segments dropped (so `docs/kb/scheme/qld/fhnhc.md` → `kb.scheme.qld.fhnhc`; the `kb.` prefix is just the `kb/` root and marks KB anchors as distinct from registry-field refs like `profile.*`). Blueprints reference KB via slugs (e.g., `kb.scheme.fhg`, `kb.firb.application-process`). Migration script validates `slug == path` + resolution at deploy.

    **No semantic versioning (CI/CD).** Blueprints and KB are not version-numbered (no `v1.0`, no `@1.2` pinning). The repo is the source of truth; deploy publishes the latest, git holds the history. Reproducibility for the regulated audit trail comes from each filled plan card recording the **deploy commit SHA + a snapshot of the resolved KB content** at fill time. (Roadmap phase names like "Wedge 1" are planning language, not artifact versions.)

7. **Constrained renderer vocabulary.** Blueprints can only use renderers from the enum defined in §11.9 (`summary-card`, `swimlane-diagram`, `checklist`, `data-table`, `calculator`, `buying-strategy-card`, `risk-flag-list`, `comparison-grid`, `opportunity-card`, `scheme-stack-card`, `firb-workflow-card`, `family-view-card`, `decision-trail`). New renderers are intentional design decisions, not arbitrary additions.

8. **Independence preserved.** Buyer is the customer. REAs are partners under fee structures that never bias recommendations. No commission share, no per-property-sold fees. Buyer chooses; REA pays when chosen. See [`docs/03-strategy.md#85-rea-partnership-economics--two-tier-complementary-model`](docs/03-strategy.md).

9. **Agent grounds in current state, NOT conversation history.** System prompt is dynamically constructed from current plan card state + property context + uploads + KB anchors. Conversation log is preserved for user re-reading; not for agent grounding. Saves tokens; prevents drift.

10. **FIRB status as first-class user attribute.** Every flow branches on it. Foreign persons cannot buy established dwellings 1 Apr 2025 – 30 Jun 2029. Misadvice has real harm; build the gate into the architecture, not as a disclaimer.

11. **Engine / shell split.** Two independently-deployable halves: an Erlang/OTP + Python **engine** that runs the planning agent and exposes primitives (`/api/engine/*`, typed events), and **shell(s)** (web, extension, curator console) that own UX, identity, and commerce. The engine **meters** (emits `usage`); shells **gate** on commerce — keeping billing *and* ASIC liability out of the agent loop. Compliance (FIRB/ASIC/AML) is a gate on agent behavior → engine-owned. If two shells would render the same data differently, it's shell-owned. See [`docs/architecture/engine-contract.md`](docs/architecture/engine-contract.md).

## Four user modes

| Mode | Audience | FIRB | Blueprint |
|---|---|---|---|
| A | Vietnamese-AU citizen / PR FHB | No | [`blueprints/fhb-domestic-au.md`](docs/blueprints/fhb-domestic-au.md) |
| B | Vietnam-parent funding AU child / AU temp resident FHB | Yes | [`blueprints/fhb-foreign-au.md`](docs/blueprints/fhb-foreign-au.md) |
| C | Vietnamese-AU investor (citizen / PR) | No | [`blueprints/investor-domestic-au.md`](docs/blueprints/investor-domestic-au.md) |
| D | Vietnam-located investor | Yes | [`blueprints/investor-foreign-au.md`](docs/blueprints/investor-foreign-au.md) |

Wedge 1 targets Mode A only. Mode B / C / D blueprints are drafted but not in scope for Wedge 1a.

## Where to start building (Wedge 1a)

In order of value + dependency. **Engine is the dependency root** (the shell renders what the engine produces); build-time KB curation feeds the engine. Tags: `[engine]` runtime, `[build-time]` offline KB agent, `[shell]` Svelte. See [`docs/architecture/engine-contract.md`](docs/architecture/engine-contract.md).

1. **`[engine]` PG schema + KB/blueprint artifact compiler** — two distinct things. (a) PG migration creates `plan_cards` (base + addenda, `deploy_commit_sha`), `plan_card_events`, `sessions`, `suburbs`, `properties` (OPTIONAL — not load-bearing); PGO from Erlang. (b) The offline KB agent's build-time deploy reads `docs/kb/*.md` + `docs/blueprints/*.md`, validates slugs (globally unique + every blueprint `kb_anchor` resolves) + renderer enum + acyclic pipeline, and **compiles a versioned artifact** (loaded into `persistent_term` at boot). **KB + blueprints are NOT Postgres tables** — git is SOT, the artifact is a rebuildable projection. See [`docs/architecture/engine-contract.md`](docs/architecture/engine-contract.md) §9.1.

2. **`[build-time]` First KB docs** — `docs/kb/scheme/fhg.md` (validates the format), then `scheme/qld/fhnhc.md`, `scheme/fhss.md`, `firb/established-dwelling-ban.md` to bootstrap Mode A KB.

3. **`[build-time]` Suburb enrichment ingestion** — jobs writing the engine `suburbs` table: ABS Data API for SAL-level Census 2021 (Vietnamese ancestry %, demographics, family composition, dwellings); state education / planning / flood adapters; RBA FX daily. CoreLogic / PropTrack are PAID — deferred.

4. **`[engine]` Gateway + planning sidecar (base scope)** — Erlang `/api/engine/*` + `gen_statem` per plan-card turn; Python sidecar loads `fhb-domestic-au.md`, validates kb_anchors resolve, runs each `scope: base` component (`buyer_profile`, `eligibility`, `mortgage_finance`/`cash_position`/`ownership_planning` base), streams `component_filled`. Wire the ASIC boundary into the compliance pipeline from day one. **Slice 1 DONE** — the Erlang↔Python seam, gateway (`fh_engine_http` + handlers), ed25519 JWT auth, real `fh_engine_turn` lifecycle driving a supervised `{packet,4}` Python port, FIRB→ASIC→AML compliance pipeline (Mode-A pass-through), `plan_card_events` SOT + `content_jsonb` snapshot + `pg` SSE fan-out, all proven end-to-end with a **stub** sidecar (`engine/python/planner_stub.py`) against Docker PG (`engine/erlang/test/seam_smoke.escript`). **Slice 2 DONE** — the real Anthropic Agent-SDK sidecar (`engine/python/planner.py`) replaced the stub: compiled artifact → `persistent_term` at boot, dynamic per-call prompt from plan-card state, resolver/agent **two-path** fill, `usage` metering, real FIRB→ASIC→AML + outcome-conformance gates at the commit seam, and bilingual Q&A streaming + KB-lookup tool. Auth draws the **Max-subscription `CLAUDE_CODE_OAUTH_TOKEN`** (not pay-as-you-go `ANTHROPIC_API_KEY`). All verified end-to-end with real Opus. **8a engine COMPLETE.** See [`docs/grounding-checklist.md`](docs/grounding-checklist.md) item 8.

5. **`[shell]` Onboarding** — mode / state / VND-AUD range / map-zone / intent tags; calls the engine to create the plan card + run the base turn.

6. **`[shell]` Base plan rendering** — the base plan is **engine state, not a standalone dashboard**. It surfaces only as a **plan projection** on the map-home (zone-default → per-suburb: invariant core — eligibility, cash math, scheme stack — plus a per-suburb overlay), rendered from `component_filled` outcomes via the renderer vocabulary. Its only no-map form is an on-demand **export dossier** — reuse [`docs/first_home_buyer_plan.html`](docs/first_home_buyer_plan.html) as that export's design language, not as a home screen. See [`docs/04-ux-model.md`](docs/04-ux-model.md) §13.3/§13.4.

7. **`[shell]` Suburb-intelligence map** — Leaflet / Mapbox + ABS-data overlays. Vietnamese-community proximity is the killer layer; ship that first.

8. **`[shell+engine]` Tìm Nhà request flow** — shell submits a request; the engine's agent emits `curator_input_required` + a search brief; the curator console (shell; manual / spreadsheet-driven in v1) returns a shortlist → addenda. Defer when ready.

9. **`[engine]` User URL paste handler** — synchronous single-page fetch via Playwright (engine sidecar, user-initiated); normalise to canonical Property schema; attach as addendum → activates Phase B (per-property components).

## Conventions

### File / repo organisation

```
firsthomey/
├── CLAUDE.md (this file)
├── docs/                         (strategic + architectural docs — the working agreement)
│   ├── README.md
│   ├── 01-market.md, 02-competitive-landscape.md, 03-strategy.md, 04-ux-model.md, 05-roadmap.md
│   ├── architecture/                  (architecture doc + engine/shell contract + agentic + design principles)
│   │   ├── architecture.md            (engine/shell split, three-layer model, blueprint, property pipeline)
│   │   ├── engine-contract.md         (engine↔shell boundary: primitives, events, metering, compliance gate)
│   │   ├── agentic-boundary.md        (resolver/agent decision rule — when an op needs the LLM)
│   │   ├── agentic-flow.md            (agent types, prompt structure, vendor layer, context management)
│   │   ├── isolation-model.md         (plan card vs turn, per-card serialization, conversation persistence, vendor config)
│   │   ├── principles.md              (six architecture principles, adapted from ATP)
│   │   └── erlang-design-checklist.md (OTP patterns for the engine)
│   ├── blueprints/
│   │   ├── fhb-domestic-au.md
│   │   ├── fhb-foreign-au.md
│   │   ├── investor-domestic-au.md
│   │   └── investor-foreign-au.md
│   ├── kb/                       (curated KB markdown files with frontmatter — Mode-A set authored; one slug per file)
│   │   ├── scheme/
│   │   ├── firb/
│   │   ├── lender/
│   │   ├── property/
│   │   └── ... (one slug per file; folder structure mirrors slug namespace)
│   ├── samples/
│   │   └── property-card-example.html
│   └── first_home_buyer_plan.html (Mode A example output, design reference)
├── engine/                       (Erlang/OTP gateway + Python sidecars — agentic planning)
│   ├── build/                    (offline KB+blueprint artifact compiler — kb_compiler.py: materializes the registry, runs structural+semantic gates, emits priv/kb/artifact.json)
│   ├── erlang/                   (cowboy /api/engine/*, gen_statem per plan-card turn, compliance, metering, PGO)
│   │   ├── priv/migrations/      (engine PG schema: plan-card state, events, sessions)
│   │   └── priv/kb/              (compiled KB + blueprint artifact, emitted at deploy)
│   └── python/                   (stateless disposable sidecars — planner_stub.py built; real Anthropic-SDK planner + Playwright fetch = slice 2)
├── shell/                        (SvelteKit frontend + Erlang/OTP backend — UX, identity, commerce; 8-S0 scaffold + JWT-mint seam landed)
│   ├── web/frontend/             (SvelteKit SPA — scaffold built; onboarding, suburb map, plan projection, chat layer = 8-S2+)
│   ├── web/backend/              (Erlang/OTP fh_shell_* — boot+migrations+health+two-JWT seam built; login/proxy/commerce = later slices)
│   └── extension/                (browser extension — Phase B property capture)
├── tests/                        (build validation + resolver eval — validate_build.py, resolver_eval.py)
└── pyproject.toml                (sidecar deps; .venv)
```

See [`docs/architecture/engine-contract.md`](docs/architecture/engine-contract.md) for what lives where and why; `engine/` and `shell/` deploy independently with the API as the only contract.

### Code style (when written)

The platform is an **engine** (agentic planning) + **shell(s)** (UX/commerce). See [`docs/architecture/engine-contract.md`](docs/architecture/engine-contract.md).

- **Engine — Erlang/OTP.** Cowboy gateway (`/api/engine/*`, REST+SSE), `gen_statem` per plan-card turn, supervised Python ports, compliance pipeline, metering. PostgreSQL via PGO; `jsonb` for plan-card content; **Postgres is the source of truth for runtime state** (plan cards, events, sessions). **KB + blueprints are not in Postgres** — they are git-authored and compiled to an in-memory artifact at deploy (`persistent_term`; git is SOT). Follow [`docs/architecture/erlang-design-checklist.md`](docs/architecture/erlang-design-checklist.md); use the Erlang MCP server (per global CLAUDE.md).
- **Engine sidecars — Python** with type hints; Pydantic for blueprint / KB / plan-card / outcome schemas; the planning agent uses the Claude API via the Anthropic SDK (no LangChain unless materially justified). Sidecars are **stateless and disposable** (principle 3) — full context in on stdin, JSON-RPC events out on stdout, exit. Playwright for the synchronous user-URL-paste fetch (engine sidecar, user-initiated only).
- **Shell — Svelte** (use the Svelte MCP server, per global CLAUDE.md). Owns onboarding, suburb map, plan-card rendering (constrained renderer vocabulary), identity, and commerce. Gates on commerce; the engine only meters.

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
4. UX / surface questions → §13 in `docs/04-ux-model.md`.
5. Strategic positioning questions → §8 in `docs/03-strategy.md`.
6. "Should the platform do X?" → if X requires a market position in property data acquisition, the answer is no.

## Maintenance

This file should evolve as the project evolves. Specifically:

- Add commands to "Where to start building" as they get implemented and stabilise.
- Note any architectural decisions made during implementation that aren't yet in the docs.
- Update the "Don't" list when a new pitfall is encountered.
- Keep this file under ~200 lines. If it grows, refactor — link out to docs/ instead.

Last updated: June 2026 — Wedge 1a build-complete (engine 8a + shell 8-S + two-spines + full temporal flow + income→capacity), full-stack live-pixel confirmed; next is commit + deploy.
