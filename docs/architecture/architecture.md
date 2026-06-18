# Architecture & context-flow framing

> Part of the **Vietnamese Diaspora Property Platform — Research & Strategy** document set. See [README.md](../README.md) for the full index.
>
> **This document covers:** The engine/shell deployable split (§11.0), the three-layer architecture (static KB / user state / agentic reasoning), update cadences, interaction intensity by phase, product modes, Claude Code fit, the user state trap, the context-and-flow framing that explains why this shape, the agentic platform formula, flow taxonomy, and implications for org structure.
>
> **Related documents:** [03-strategy.md](../03-strategy.md) (business strategy that this architecture serves), [04-ux-model.md](../04-ux-model.md) (user-facing surfaces over this architecture).

---

## 11. Architecture & interaction model

The product cleanly separates into three layers with different update cadences and engineering disciplines. Designing this separation correctly is the single biggest leverage point for build speed, operating cost, and product depth.

### 11.0 Engine / shell split (deployable shape)

The three layers below are the *logical* model. Physically, the platform is two independently-deployable halves — a pattern adapted from the ATP project (see [`engine-contract.md`](engine-contract.md) for the full contract and [`principles.md`](principles.md) for the six principles that govern it):

- **Engine** — Erlang/OTP gateway + stateless Python sidecars. Runs the agentic planning workload: resolves the blueprint + KB anchors, runs the planning agent over current plan-card state, fills components, enforces the compliance gate, persists, and streams typed events. Exposes **primitives** (`/api/engine/*`), never views. Owns Layer 1 and Layer 2 as the source of truth, and the Layer 3 runtime.
- **Shell(s)** — web app, browser extension, Tìm Nhà curator console (Svelte frontend + Erlang backend). Own UX, identity, commerce, and display projection. Consume engine primitives and render the typed component outcomes via the constrained renderer vocabulary (§11.9).

| Layer | Engine owns | Shell owns |
|---|---|---|
| L1 — Static KB | Compiled KB + blueprint artifact (git-authored `docs/kb` + `docs/blueprints`; offline KB agent compiles + validates at deploy, loaded into memory at boot — build-time flow). **Not** Postgres tables; git is SOT. | — |
| L2 — User state | `plan_cards`, `sessions` (SOT; the agent's grounding, §11.9 / constraint #9) | A *view* of plan cards — title, layout, prefs |
| L3 — Agentic reasoning | Planning agent in a disposable Python sidecar; `gen_statem` per plan-card turn; compliance pipeline; metering | Onboarding / map / upload UX; renders outcomes; commerce gating |

The forcing function: if two shells would render the same data differently, it is shell-owned and the engine must not shape it. The engine **meters** (emits `usage` events) but does not **gate** on commerce — shells gate, which keeps both billing and ASIC liability out of the agent loop. Compliance (FIRB / ASIC / AML) is a *gate on agent behavior*, so it is engine-owned: the regulatory boundary is structural (constraint #10), not a disclaimer. OTP patterns for the engine live in [`erlang-design-checklist.md`](erlang-design-checklist.md).

**Repository layout** (target — supersedes the earlier flat `src/`):

```
firsthomey/
├── engine/                      ← agentic planning workload
│   ├── erlang/src/              gateway: cowboy /api/engine/*, gen_statem per plan-card turn,
│   │                            sidecar lifecycle, compliance pipeline, metering, PGO
│   ├── erlang/priv/migrations/  engine PG schema (plan-card state, events, sessions)
│   ├── erlang/priv/kb/          compiled KB + blueprint artifact (offline KB agent emits at deploy)
│   ├── python/                  stateless sidecars (planning agent — Anthropic SDK; Playwright URL fetch)
│   └── python/pyproject.toml
└── shell/
    ├── web/frontend/            SvelteKit: onboarding, suburb map, plan projection, chat layer, uploads
    ├── web/backend/             Erlang/OTP: identity, user/engine JWT, commerce (subscription / one-time / success fee), usage consumer
    └── extension/               browser extension (Phase B property capture)
```

`engine/` and `shell/` deploy independently; the API is the only contract between them.

### 11.1 The three layers

```
┌─────────────────────────────────────────────────────────┐
│  LAYER 3 — AGENTIC REASONING (live, per-session)        │
│  Document analysis · eligibility synthesis ·            │
│  property evaluation · negotiation coaching · alerts    │
└─────────────────────────────────────────────────────────┘
                          ↑ reads from
┌─────────────────────────────────────────────────────────┐
│  LAYER 2 — USER STATE (persistent, mutable)             │
│  Profile · savings · debt · property shortlist ·        │
│  document library · application status · decision trail │
└─────────────────────────────────────────────────────────┘
                          ↑ grounded in
┌─────────────────────────────────────────────────────────┐
│  LAYER 1 — STATIC KNOWLEDGE BASE (batch-updated)        │
│  Schemes · duty schedules · lender policies · process · │
│  templates. RAG index over verified sources.            │
└─────────────────────────────────────────────────────────┘
```

**Layer 1 — Static knowledge base.** Scheme rules, state stamp duty schedules, lender policies (where published), process knowledge, document templates, regulatory boundaries. Updated periodically by scripted jobs that re-fetch official sources, diff against current state, and flag changes for human review.

**Layer 2 — User state.** Per-user profile (income, savings, debt, location, preferences), property shortlist, document library, application status, and decision trail. CRUD over a relational store with append-only history for audit and "what did we conclude about X" recall.

**Layer 3 — Agentic reasoning.** Document analysis, eligibility synthesis, property evaluation, negotiation coaching, monitoring alerts. Built as discrete capability modes — each with its own prompt, tool set, and evaluation harness. Reads from Layers 1 and 2; never writes directly to Layer 1.

### 11.2 Update cadences and offline KB agent roles

The offline KB agent (Claude Code + maintainer working on the local repo) has **three distinct roles**, all operating on different cadences:

1. **Curate domain KB** — schemes, FIRB regs, state duty schedules, lender policies, process knowledge, document templates. Re-fetch from official sources, diff, review, publish.
2. **Ingest property data** — normalise partner REA uploads, cache user URL pastes, integrate council/developer feeds (no scraping, §11.10). Output: unified `properties` table (OPTIONAL in v1) for the user-facing agent to query.
3. **Curate blueprints** — when laws or transaction mechanisms change, update the FHB or investor plan card blueprint and redeploy. Git holds the history; reproducibility comes from the deploy commit SHA + KB snapshot recorded on each filled plan card (see §11.9).

All three roles produce **batch-updated context** that the user-facing planning agent reads at session time but never writes back to.

| Cadence | Content | Mechanism |
|---|---|---|
| Quarterly | Scheme structures (FHG, Help to Buy, FHSS), state duty schedules, FHOG amounts, process knowledge, document templates, HECS thresholds | Scripted re-fetch + diff + review |
| Monthly | Lender policy updates, RBA cash rate, FHG panel changes, participating lender lists | Scripted monitor + diff + alerts |
| Weekly / daily | Partner REA inventory sync, user URL paste cache, FX rates for Mode D | Scripted ingestion (no scraping, §11.10) |
| Per-event | Federal Budget (May annually), State Budgets (June annually), Housing Australia rule changes, ABS quarterly releases, ASIC bulletins, FIRB regime changes | Calendar-triggered + RSS / news watchers; triggers blueprint review |
| Real-time | Buyer's situation, specific property selection, uploaded document, live negotiation, current chat message | Never batchable — Layer 3 territory |

Almost nothing in this domain requires sub-day knowledge freshness. What needs to be real-time is **the buyer's situation against the knowledge**, not the knowledge itself. This is a structural cost advantage if architected correctly — Layer 1 ops are predictable scripts, not data engineering.

### 11.3 Agentic interaction intensity by phase

| Phase | Intensity | Pattern |
|---|---|---|
| Aspiration (–24 to –6 mo) | Low | Exploratory, occasional sessions |
| Preparation (–12 to –3 mo) | Medium, episodic | Q&A as new information arrives |
| Pre-approval + scheme stacking (–3 to –1 mo) | **High burst** | Concentrated 2–4 week window — docs gathered, schemes synthesised, lenders shortlisted |
| Property search (–3 to settle) | **Very high frequency** | 3–10 properties/week during active search |
| Due diligence (1–2 wks post-offer) | **Very high burst** | S32 + Contract of Sale + building + pest + strata, multiple sessions per property |
| Negotiation / auction (active days) | **Real-time critical** | Highest stakes, highest emotional load, often mobile |
| Settlement (4–8 wks) | Low | Process Q&A; conveyancer handles execution |
| Move-in (settle to mo 3) | Low | Checklist and reminders |
| Ownership yr 1–3 | Low background + spikes | Passive monitoring, alerts on rate / refi / graduation |
| Lifecycle events (yr 3+) | Event-driven spikes | On-demand questions + opportunistic alerts |

### 11.4 The five high-intensity moments

These are where agentic interaction creates the most value:

1. **Document upload and parse** — pre-approval and due diligence phases. Magic moment: 60-page report → 2-page summary.
2. **Per-property evaluation** during active search — comparative analysis, suburb risks, agent strategy decoding.
3. **Real-time negotiation coaching** during offers and auctions — highest stakes, most differentiating moment.
4. **Scheme-stacking synthesis** at pre-approval and when scheme rules change — personalised application of static knowledge.
5. **Opportunistic ownership alerts** — rate moves, refinance windows, LVR graduation events.

Everything else is informational or process — useful but not what defines the product.

### 11.5 Product modes follow interaction intensity

| Mode | Surface | Use cases |
|---|---|---|
| Quick question | Fast chat, low context, mobile-first | Aspiration, preparation, Q&A throughout |
| Document workspace | Upload-heavy, side-by-side annotation, multi-doc context | Pre-approval, due diligence |
| Property workbench | Per-property dashboards, comparison view, decision support | Property search |
| Live coach | Minimal UI, voice or one-line input, instant response | Auctions, negotiations — most differentiating, hardest to build |
| Background monitor | Async, alert-driven, low-touch | Ownership phase |

### 11.6 Pricing implications

Pricing should mirror interaction intensity:

- **One-time fees** for burst-intensity moments (document review, S32 parse): $20–50 each
- **Subscription during active period** (preparation through settlement): $20–30/month
- **Success fee at settlement:** $500–1,000
- **Low-cost long-tail subscription** during ownership: $5/month or free with paid alerts — keeps the lifecycle continuity moat alive cheaply

This structure captures value at each high-intensity moment without forcing committed subscription on aspirational users.

### 11.7 Claude Code fit by layer

| Layer | Fit | Why |
|---|---|---|
| L1 — Static KB | Excellent | Python scripts that fetch, diff, embed, index. ~2–4 weeks for v1; quarterly maintenance scripts thereafter. |
| L2 — User state | Excellent | Schema design + CRUD + auth + audit trail. Standard SaaS plumbing. |
| L3 — Agentic reasoning | Strong, *with discipline* | Each mode must be a self-contained capability with its own prompts, tools, and eval harness. The trap is building one mega-agent — Claude Code productivity drops sharply when evaluation gets fuzzy. |

**Practical implication for Wedge A:** shippable in 4–6 weeks with Claude Code:

- Layer 1 for document review is narrow (just contract conventions, building report patterns, state-specific terms): ~1–2 weeks
- Layer 2 is minimal (upload, store, surface previous uploads): few days
- Layer 3 is one focused prompt + one mode with eval set: ~1–2 weeks of iteration

### 11.8 The user state trap

Most teams underinvest in Layer 2 and regret it later. Specifically:

- **Document history** — every contract reviewed, every report parsed, every property shortlisted. Buyers will come back asking *"what did we conclude about that one in Indooroopilly?"*
- **Decision trail** — why an option was ruled out, what scheme combination was chosen, what borrowing capacity was on a given date. This becomes the agent's memory.
- **Change-impact tracking** — when a scheme threshold moves, you need to know which users' previous calculations were invalidated and alert them.

These aren't real-time concerns but they're not batch-updateable either — they're **transactional and append-only**. Worth designing for from day 1 or you build a goldfish, not a co-pilot.

### 11.9 Blueprint as data model + presentation specification

A foundational architectural decision: the platform organises agent reasoning around a **plan card blueprint** structured as a **directed acyclic pipeline of components**. The blueprint is simultaneously:

1. **A computational pipeline** — components with explicit inputs, atomic actions, and typed outcomes that flow as interfaces to downstream components
2. **A presentation specification** — components carry renderer hints and UI tab assignments that drive the visual plan card UI

The UI is a *view of the filled blueprint instance*, and the agent reasons within and across *the same component pipeline*. One template; two consumers.

> **Read [`structure-map.md`](structure-map.md) first** for the hub map — all the structures and how they relate across planes (build-time, runtime data, agentic turn, persistence, engine/shell), in mermaid, with the containers, the concrete FHG trace, and the addressing convention. This section is the detailed formalisation of the runtime-data plane; that doc is the picture it formalises and the index into every other section.

Reference: [`docs/blueprints/fhb-domestic-au.md`](../blueprints/fhb-domestic-au.md) is the first concrete blueprint following this model. The remainder of this section formalises the model.

#### Component pipeline as a DAG

Each component represents an **atomic unit of agent reasoning** — a coherent group of actions sharing one goal. Components form a directed acyclic pipeline:

- Each component has a **goal** (the functional outcome it produces) and a single coherent group of actions
- **Inputs** are explicit — upstream component outcomes or external sources (property card, uploaded documents)
- **Outcome** is a **typed structure** that downstream components read as their interface
- Pipeline is **acyclic** (validated at deploy by the migration script)
- Pipeline **allows parallelism** — independent branches can be filled concurrently
- **Display order is derived** from the pipeline DAG; UI may aggregate multiple components into a single tab

The key abstraction: downstream components read **outcomes** (curated, structured), not upstream parameters (raw, hierarchical). This makes the pipeline composable, the agent's reasoning bounded, and migrations tractable.

**Outcomes carry facts, not verdicts.** An upstream outcome exposes *normalised facts* — residency, age, ownership history, income, derived financials — never the result of applying a particular scheme's rules to them. A verdict ("FHG-eligible") is produced by the component that *owns* those rules (`eligibility`), in base or per-property scope, and is never pre-baked into a profile that the rule-owning component then reads from. One place owns each rule; the same facts feed every scheme's predicate; the judgment is auditable where it is made. (This is the component-flow rule in [CLAUDE.md](../../CLAUDE.md): *profile holds facts; downstream reasons about facts*.)

#### Component structure (template)

A blueprint contains a list of components. Each component looks roughly like this (excerpt from the FHB Mode A blueprint, `eligibility` component):

```jsonc
{
  "id": "eligibility",
  "goal": "Determine all applicable schemes and produce an optimal stacked scheme stack with rationale for inclusion/exclusion.",
  "inputs": ["buyer_profile.outcome", "property_assessment.outcome"],
  "kb_anchors": [
    "kb.scheme.fhg", "kb.scheme.fhss", "kb.scheme.help-to-buy",
    "kb.scheme.qld.fhc", "kb.scheme.qld.fhnhc",
    "kb.scheme.vic.fhb-duty", "kb.scheme.vic.fhog",
    "kb.scheme.nsw.fhbas", "kb.scheme.nsw.fhog"
  ],
  "renderer": "scheme-stack-card",
  "ui_tab_hint": "overview",
  "parameters": {
    "fhg": {
      "eligible":               { "type": "bool",       "value": "<initial>" },   // resolver: predicate over the fact surface (agentic-boundary.md)
      "applicable_cap":         { "type": "money",      "value": "<initial>" },   // resolver: lookup by (state, location_tier)
      "deposit_percentage":     { "type": "percentage", "value": 5 },
      "lmi_savings_estimate":   { "type": "money",      "value": "<initial>" }
    },
    "fhss": {
      "eligible":                { "type": "bool",  "value": "<initial>" },
      "available_release_amount":{ "type": "money", "value": "<initial>" },
      "tax_offset_estimate":     { "type": "money", "value": "<initial>" }
    }
    // ... state_concession, fhog, help_to_buy
  },
  "outcome_schema": {
    "type": "scheme_stack",
    "fields": {
      "applicable_schemes": "array<{ name, benefit_value, role, notes }>",
      "rejected_schemes":   "array<{ name, reason }>",
      "total_benefit_value":"money",
      "stacking_constraints":"array<string>"
    }
  }
}
```

Each component carries: `id`, `goal`, `inputs`, `kb_anchors`, `renderer`, `ui_tab_hint`, `parameters` (hierarchical with simple atomic leaves), and `outcome_schema` (the typed interface for downstream components). Each leaf parameter carries: `type`, `value` (or signal like `<initial>`), optional `agent_reasoning_required` flag, optional `options` (for enums), optional `derived_from` (for parameters computed from other parameters).

#### The fact surface and the resolver-input registry

Because outcomes carry facts (above), each component's `outcome_schema` *is* the typed **fact surface** the next components read. Resolver rules — eligibility predicates, lookups, and the parameters formulas consume (the KB rules layer, `content_json`) — may reference inputs only from the **resolver-input registry**: the union of the `outcome_schema` fields of all upstream components along the pipeline DAG, plus the declared external sources (property card, suburb enrichment). For `eligibility` the registry is `profile.*` ⊕ `applicant.*` ⊕ `property_fit.*` ⊕ `suburb.*` — note it reads the property *outcome* (`property_fit.*`), never `property_assessment`'s raw `basics.*` parameters, per the one-access-path rule below. (This is why the neutral property facts a scheme needs — `state`, `price`, `property_type`, `lga`, `is_capital_city` — are published in `property_fit`, not left in `basics`.)

The **`applicant.*` namespace** is a registry projection of the `profile.applicants` array's *element* type: every per-applicant leaf (`applicant.citizenship_status`, `applicant.age`, `applicant.ever_owned_au_property`, …) resolves and type-checks against that element schema, exactly like a flat `profile.*` field. It exists because the eligibility-bearing facts are per-applicant (a joint application has several), and the declarative rule layer has no quantifier (no control flow — see below). The quantification therefore lives in **resolver code**, fixed by which side the namespace appears on: a `criteria` `field` in `applicant.*` is evaluated for **every** element and the results **AND**-ed (the all-applicants test — `eligibility` §3 scope note); a `fills` rule whose `leaf` is in `applicant.*` is computed **per element** (a map over the array, e.g. `applicant.firb_required` derived from `applicant.citizenship_status`). Neither is control flow in the data — the criterion stays `{field, op, value}`; the ∀/map is a resolver behaviour the namespace selects. An application-scoped aggregate of a per-applicant fact is published as its own flat field (e.g. `profile.firb_required_any`), read like any other registry field.

The registry makes two properties checkable at deploy by the artifact compiler:

- **Reference integrity** — every field a rule names resolves to a registry field of compatible type. A predicate that needs an input no upstream outcome produces is a *build error* — this is the check that catches a scheme rule requiring a fact the profile never collected.
- **One access path** — resolver and agent both read *outcomes only*; the registry is just the typed enumeration of that surface, so there is no separate route into raw parameters.

Some values a rule consumes are *derived* rather than collected. Two cases, kept distinct:

- **Derived published facts** live in an outcome and are read like any other registry field — e.g. `applicant.firb_required` (per-applicant, from `applicant.citizenship_status`) and its application-scoped aggregate `profile.firb_required_any`, or `property_fit.is_capital_city`. They are neutral facts, scheme-agnostic, so they are published once and reused.
- **Resolver-local intermediates** are computed inside one scheme's rule and not published — e.g. FHG's `location_tier` (`capital_or_regional_centre` / `rest_of_state`). It is *not* a registry field: region tiering is per-scheme (state duty concessions tier regions differently), so there is no single published tier. The FHG resolver derives it from published geo facts (`property_fit.state`, `.lga`, `.is_capital_city`) plus FHG's own `designated_regional_centre_lgas` parameter (in `kb.scheme.fhg`), then uses it as the key into the cap lookup. The data (the LGA list, the cap table) is declarative KB; the classification is resolver code — no new `content_json` rule kind.

#### Four blueprints — one per user mode

The platform ships four blueprints, one for each user mode (§13.2):

| Blueprint | Mode | Audience | FIRB applies | Status |
|---|---|---|---|---|
| `fhb-domestic-au` | A | Vietnamese-AU citizen / PR FHB | No | **drafted** |
| `fhb-foreign-au` | B | Vietnam-parent funding AU child; AU student / 485 holder | Yes | drafted |
| `investor-domestic-au` | C | Vietnamese-AU investor (citizen / PR) | No | drafted |
| `investor-foreign-au` | D | Vietnam-located investor | Yes | drafted |

Each Mode gets its own blueprint rather than activating FIRB conditionally in a shared blueprint because ~50% of components differ structurally between domestic and foreign-person modes (FHG/FHSS not eligible for foreign persons; established-dwelling ban; foreign-buyer surcharge; FIRB approval workflow; currency transfer; cross-border family coordination). Shared component patterns (`property_assessment`, `due_diligence`, `decision_trail`) are imported by reference rather than duplicated, keeping authoring efficient without entangling reasoning.

#### Storage and deployment

| Table | Content | Update pattern |
|---|---|---|
| `blueprints` | Templates (jsonb column for content), keyed by slug | Redeployed in place on each deploy; git holds prior states. Filled plan cards record the deploy commit SHA for reproducibility, not a row version. |
| `plan_cards` | Filled instances (jsonb), references the blueprint by slug | Created at onboarding from mode + state + price range + zone (no property required, per plan-first); refilled on user interaction or system event |
| `properties` | Normalised property data (OPTIONAL in v1; not load-bearing) | Populated only via narrow demand-driven paths (§11.10): user URL paste, browser extension, Tìm Nhà human curation, and later partner REA push. No scraping pipeline. |
| `sessions` | Conversation log by `(session_id = user_id × plan_card_id)` | Append-only |

Filled plan cards **snapshot the resolved KB content and record the deploy commit SHA** active when filled. When laws or transaction mechanisms change, the blueprint is updated and redeployed; existing plan cards remain valid as historical artifacts — reproducible from their snapshot + commit SHA — but display a "plan updated — refresh?" prompt when the user revisits. Refresh is opt-in, not destructive.

This separation reflects the §11.2 cadence model: blueprint = static KB (batch-updated by offline agent); filled plan card = user state (transactional); session log = user state (append-only).

#### System prompt construction — always show latest parameter values

The planning agent's system prompt is **dynamically constructed at request time** from the current state of the user's plan card. Conceptually:

```
System prompt =
  [KB anchors referenced by blueprint sections]
  +
  [Current plan card state, serialised — each parameter shown with current value]
  +
  [Property card context — from property selection]
  +
  [Uploaded document summaries — if any]
  +
  [Buyer profile fields — citizenship, FIRB status, etc.]
  +
  [Agent reasoning instructions — fill the `agent_reasoning_required` leaves still `<initial>`, respect `requires`, ask user when ambiguous]
```

Critically, **conversation history is not appended**. Planning is grounded in the current context (plan card + property + uploads + current query). This both reduces token consumption and prevents the agent from drifting on stale conversational context. The session log is preserved for user re-reading, not for agent grounding.

#### Initial-signal vocabulary

The `<initial>` placeholder is the agent's cue that a parameter needs filling. The FHB blueprint also uses **upstream-reference signals** that point to outcomes from earlier components or external sources:

| Signal | Meaning | Agent behaviour |
|---|---|---|
| `<initial>` | Never filled | Reason if prerequisites met; otherwise ask user |
| `<from_property_card>` | Value comes from the user's property selection | Pull from property card at session-start; no reasoning needed |
| `<from_buyer_profile>` | Value comes from upstream `buyer_profile.outcome` | Pull from upstream component's filled outcome |
| `<from_property_assessment>` | Value comes from upstream `property_assessment.outcome` | Same pattern |
| `<from_eligibility>` | Value comes from upstream `eligibility.outcome` | Same pattern |
| `<from_suburb>` | Value comes from the suburb enrichment record (§11.10) | Pull from the `suburbs` table by suburb at session-start; no reasoning needed |
| `<from_document>` | Value comes from facts extracted from an uploaded document | Pull from the extraction sidecar's structured output; no reasoning needed (extraction ran upstream) |

Future signal expansions (deferred to v1.1):

| Signal | Meaning | Agent behaviour |
|---|---|---|
| `<pending: user>` | Needs user input before agent can fill | Surface a clear question to the user |
| `<pending: agent>` | Prerequisites met; agent should reason | Compute and fill on next pass |
| `<stale: 90d>` | Was filled but blueprint or property data updated | Flag in UI; offer refresh |
| `<conflict: user_override>` | User explicitly set a value contrary to agent's recommendation | Preserve user value; note disagreement in decision trail |

V1 implementation uses `<initial>` + the five upstream-reference signals. Pending/stale/conflict signals are added as the agent matures and edge cases emerge.

#### Two fill paths — deterministic resolver vs agent turn

Filling a component is not monolithic. Each leaf parameter declares *how* it is filled — via the signal vocabulary above plus the `agent_reasoning_required` / `derived_from` flags (§11.9 component shape). That declaration partitions every parameter into one of two fill paths. **Which path a given operation belongs to is governed by the decision rule in [agentic-boundary.md](agentic-boundary.md); this section covers how that decision is encoded and executed; how the agent path runs (agent types, prompt structure, vendor layer, context management) is [agentic-flow.md](agentic-flow.md).**

- **Deterministic resolver** (no LLM) — fills `<from_X>` copies, `derived_from` computations, unflagged formula leaves (stamp duty, LMI, deposit amounts, totals, threshold verdicts), *and* the rules engine (eligibility predicates, scheme-stacking constraints). A pure function of current plan-card state + resolved KB. Instant, free, and **reproducible**: identical inputs always produce identical figures — which is what makes the audit trail and the ASIC "computed, not advised" posture defensible.
- **Agent turn** (LLM) — fills only `agent_reasoning_required: true` leaves: the operations that clear the three-trigger test in [agentic-boundary.md](agentic-boundary.md) — valuation read, lender fit, negotiation style, synthesis of unstructured-document significance, and open-ended Q&A over the card. This is the reasoning the platform exists to provide.

The resolver runs **first**; the agent turn then sees a plan card whose deterministic leaves are already filled and reasons only over what remains (hence the system-prompt instruction above fills the `agent_reasoning_required` leaves *still* `<initial>`). This is why the `cash_position` calculator (renderer `calculator`) recomputes a budget envelope on every what-if with no model call — its parameters are entirely resolver-path (cash-on-hand resolves instantly in the client; a *structural* what-if — price/state/type — runs a free engine resolver preview, [`lifecycle-simulation-model.md`](lifecycle-simulation-model.md) §4 + engine-contract §10) — while `property_assessment` (valuation) and `mortgage_finance` (lender fit) carry `agent_reasoning_required` leaves and need the turn. Even `eligibility` — an intricate multi-scheme determination — is resolver: its criteria are rules, not judgment.

The partition is **derivable from the blueprint**: a leaf is agent-path iff it carries `agent_reasoning_required: true`; everything else (`<from_X>` copies, `derived_from` computations, unflagged formula leaves) is resolver-path. The corollary discipline: every leaf that needs judgment **must** be flagged, or it silently falls to the resolver. A component with zero flagged leaves (e.g. `settlement_prep` — a date + dependency engine) is a pure resolver component even though it activates per-property; **scope (`base | per-property | both`) is independent of fill path.**

**Document extraction is not a third path — it is input normalisation.** Parsing an uploaded S32, contract, or building report into structured facts is the unstructured-document analogue of the URL-paste Playwright fetch (§11.10): an LLM-bearing sidecar reads the document and writes structured facts into the plan card's input layer, which resolver-path leaves then copy via `<from_document>`. The extraction step *is* an LLM-call boundary, so it meters (`usage`), but it is not itself a `component_filled` — it sits upstream of both fill paths. This keeps the component-fill partition exactly two and preserves facts-in-leaves / judgment-in-outcome: the model extracts `body_corporate_quarterly_fees` (a fact, resolver-copied into `property_assessment`), while the *interpretation* of those facts into `key_concerns` is the agent turn's judgment.

**Extraction is projection onto the blueprint schema, not accumulation — so the plan card does not grow unboundedly with upload volume.** A card does not gain a field per document; it has *predeclared* `<from_document>` slots and a fixed set of flag arrays (e.g. the six `due_diligence.flags_by_document.*`). Extraction output is schema-constrained — there is no untyped field for a verbose or sloppy extractor to dump raw text into, so **the schema is the growth bound, not the extractor's good behaviour.** Three further bounds: bytes are never persisted past the consuming turn ([engine-contract.md](engine-contract.md) §5); re-uploading a revised document *refreshes* its flags rather than appending a second set (`scope: both`, refined form); and due diligence is scoped per attached property, not a global pile. Fifty uploads against one property still resolve to the same handful of slots. Verbose per-document analysis lives in the `artifacts` table by opaque id — *out of* the re-injected grounding path — so the heavy content accumulates where accumulation is cheap and harmless. Extraction **quality** therefore affects *correctness within the bound* (precision, slot routing, conflict detection when two documents assert different values for one slot) — decoupled from the *size* of the card. The growth question and the quality question are separate: you cannot make the card balloon by feeding it garbage, only make it wrong, which the typed outcomes + compliance gate exist to catch.

**A fact with no home feeds the build-time curation loop, never an ad-hoc field.** When an uploaded document contains informative content the blueprint did not anticipate, the wrong fix is letting the card grow an arbitrary field — that breaks the typed-outcome contract every downstream component and renderer depends on. Instead: surface a drop-with-note to the user now ("this document mentioned X, which this plan doesn't track"), *and* emit a curation signal — a no-home fact is evidence the blueprint **schema** is incomplete, routed into the same agent-fallback → KB-curation loop as a silent rule ([agentic-flow.md](agentic-flow.md) §2). The next deploy adds the slot. The runtime stays schema-bounded; the gap becomes a build-time improvement rather than a runtime hack.

Both paths emit `component_filled` ([engine-contract.md](engine-contract.md) §4); a `resolver` fill emits no `usage` of its own — any LLM cost lives in an upstream extraction or a prior agent turn. Keeping money math out of the LLM is deliberate: LLMs do arithmetic unreliably, and a hallucinated stamp-duty figure is both a product defect and a compliance hazard.

#### Re-fill triggers

The filled plan card is updated (re-filled) on these events:

- **User interaction** that adds or changes context — uploaded a document, answered an agent question, updated profile field, changed property
- **System event** that invalidates parameters — blueprint updated, scheme rule changed in KB, property data refreshed, FIRB regime change
- **Time-based stale check** — parameters older than threshold (e.g., 90 days) flagged for re-fill on next session

**Which path a trigger takes follows from the DAG.** A trigger re-runs the deterministic resolver over the affected components; it escalates to an agent turn **iff** the changed input feeds — directly or transitively through the pipeline DAG — a leaf flagged `agent_reasoning_required`. A hypothetical price change that only moves calculator inputs stays resolver-only (instant, free, no `usage`); the same change crossing a scheme cap — which flips an `agent_reasoning_required` eligibility leaf — escalates to a turn. This is statically decidable from the blueprint, so the engine knows *before* running whether a given edit costs an LLM call.

The blueprint template itself never changes per user — only the filled instance does.

#### KB anchors — slug-based references

Components reference curated KB content via **slug-based references** rather than embedded content or hard-coded URLs. The operational chain:

```
1. Offline KB agent maintains markdown files in repo:
     docs/kb/scheme/fhg.md
     docs/kb/scheme/qld/fhnhc.md
     docs/kb/firb/established-dwelling-ban.md
     docs/kb/process/auction-rules-vic.md
   
   Each file has frontmatter:
     ---
     slug: kb.scheme.qld.fhnhc
     effective_from: 2025-05-01
     last_verified: 2026-05-19
     ---

2. Artifact compiler (run at deploy, build-time):
   - Walks docs/kb/ and docs/blueprints/
   - Validates slugs are globally unique
   - Validates every blueprint's kb_anchors resolve to existing slugs (CI gate)
   - Validates renderer enum + acyclic pipeline
   - Parses frontmatter; splits the body — the `## Rules` fenced `jsonc` block is `content_json`, the remaining prose is `content_md`
   - Compiles a versioned KB + blueprint artifact shipped with the engine
     release; each KB entry is:
       (slug, effective_from, last_verified, content_md, content_json)
   - NOT a Postgres write: git is SOT, the artifact is a deterministic,
     rebuildable projection (rebuild from the deploy commit SHA)

3. Blueprints reference KB via slug only:
     "kb_anchors": ["kb.scheme.fhg", "kb.scheme.qld.fhnhc"]

4. At runtime, system prompt construction:
   - Resolves slugs against the in-memory artifact (loaded into persistent_term
     at boot); the engine is the sole reader (incl. future curator UIs, which go
     through engine primitives)
   - Injects relevant content into prompt
```

Tracking and linking:

- **Build-time validation** — CI verifies every `kb_anchors` slug in every blueprint resolves to an existing KB record. Broken references block deployment.
- **Always latest** — blueprints reference KB by slug only and always resolve the currently deployed content. There is no version pinning; reproducibility is handled by snapshotting the resolved content onto the filled plan card (see Audit trail).
- **Change propagation** — when a KB doc updates, the deploy recompiles the artifact with the new `effective_from` + `last_verified`. Plan cards filled before the update detect content drift via the `<stale: 90d>` signal (their snapshot's `last_verified` now lags the deployed doc).
- **Audit trail** — every filled plan card records the deploy commit SHA and a snapshot of the resolved KB content active when filled, so historical decisions are reproducible.

This pattern is essentially how DBT, Terraform, and OpenAPI work — content lives as files in the repo, IDs are stable, deploy is a script. The FHB blueprint references 40 distinct KB slugs across its 9 components; the offline KB agent's first responsibility is ensuring every slug has a curated doc.

#### KB rules — the `content_json` layer

A KB doc carries two bodies: **`content_md`** — prose for agent grounding and Q&A — and **`content_json`** — the *evaluable rules* the resolver runs. The rule vocabulary is **grounded in the resolver primitives** defined in [agentic-boundary.md](agentic-boundary.md): the resolver's algorithms are code; `content_json` supplies the data they operate on. One rule kind exists per resolver primitive that consumes KB data — no more.

| Kind | Resolver primitive | Produces | Shape |
|---|---|---|---|
| `criteria` | eligibility predicates | bool leaves | `all_of` / `any_of` of `{ field, op, value \| ref }`; fixed ops `eq, neq, in, nin, gte, gt, lte, lt, between` |
| `lookup` | lookups / bracketed rates | caps, amounts, bracket values | keyed table `key: [dims] → value` with an explicit `default` |
| `parameter` | arithmetic + date coefficients | formula inputs, fixed-value leaves | a fixed typed value (scalar or list) a resolver (code) formula consumes, or copies into a leaf |
| `stacking` | scheme-stacking constraint-satisfaction | the outcome's `stacking_constraints` + application order | per-scheme relations (`combines_with` / `alternative_to` / `requires`, `order_hint`) the resolver aggregates |

The first three are **leaf-producing** — each binds to one outcome-leaf `path` and lives in the doc's `fills[]`. `stacking` is **relational** — it declares how this scheme combines with others, which the cross-scheme resolver aggregates into the eligibility outcome; it sits in its own block, not `fills`. Its references are **concrete KB slugs** (e.g. `kb.scheme.fhss`), validated by reference-integrity like any field. `combines_with` / `alternative_to` are **symmetric**: the resolver unions every such edge across all docs into one undirected graph and dedups, so each edge is declared **once, on either endpoint** — a federal scheme therefore **never enumerates state concessions**; each state-concession doc declares its own `combines_with` to the federal slugs, and that single edge is read from both sides. (`requires` is directional.) Do not confuse a stacking ref with the eligibility component's `state_concession` **slot** — the slot is a fill namespace (`eligibility.state_concession.*`, filled by whichever state scheme is `applicable`); a stacking ref is a slug. Intra-slot exclusivity (e.g. `kb.scheme.qld.fhnhc` vs `kb.scheme.qld.fhc`, which compete for that slot) is expressible precisely because refs are slug-grained, not slot-grained. `copies` (`<from_suburb>`, `<from_property_card>`) are a resolver primitive too, but the signal vocabulary handles them, so they need no KB rule.

Free coefficients that feed a resolver formula but bind to no single leaf — e.g. the FHSS contribution caps behind `available_release_amount` — sit in a top-level **`parameters{}`** map the resolver code reads by name; leaf-bound fixed values stay as `parameter` rules in `fills[]`. So a doc's `content_json` is `{ fills[], parameters{}, stacking{} }`, any of which may be absent.

Three design rules govern the layer:

- **Declarative, not a DSL.** Fixed operator set; no arithmetic, no control flow in `content_json`. The FHSS releasable-amount formula, stamp-duty brackets, LMI, and serviceability all live in **resolver code** (testable, reproducible); `content_json` supplies only the numbers they consume. This keeps each rule auditable by inspection, lets a new scheme be added as *data* rather than an engine deploy, and — for money / eligibility figures — enforces "computed, not asserted" (agentic-boundary "What this rules out"; an ASIC line).
- **Bound + validated.** Each `fills` rule names the outcome leaf it produces; every `field` / key-dim resolves against the resolver-input registry (above). The artifact compiler gates on *coverage* (every resolver leaf a slug feeds has a rule) and *reference integrity* (every field resolves to a registry field of compatible type; every `stacking` ref resolves to a KB slug).
- **A doc owns only its own leaves.** Cross-doc composition — e.g. FHG's `lmi_savings_estimate` computed via `kb.lmi.calculation` — is resolver orchestration, not one doc reaching into another.

Worked example — `kb.scheme.fhg` `content_json` (the facts live once, as data; the prose a buyer reads stays in `content_md`):

```jsonc
{
  "fills": [
    { "leaf": "eligibility.fhg.eligible",
      "rule": { "kind": "criteria", "combine": "all_of", "criteria": [   // applicant.* ⇒ ∀ applicants (all-applicants test)
        { "field": "applicant.citizenship_status", "op": "in",  "value": ["citizen","permanent_resident"] },
        { "field": "applicant.age",                 "op": "gte", "value": 18 },
        { "combine": "any_of", "criteria": [
          { "field": "applicant.ever_owned_au_property",                "op": "eq",  "value": false },
          { "field": "applicant.years_since_last_au_property_interest", "op": "gte", "value": 10 } ] },
        { "field": "applicant.owner_occupier_intent", "op": "eq",  "value": true },
        { "field": "property.price", "op": "lte", "ref": "eligibility.fhg.applicable_cap_for_location_property" } ] } },

    { "leaf": "eligibility.fhg.applicable_cap_for_location_property",
      "rule": { "kind": "lookup",
        "key": ["property_fit.state", "location_tier"],  // location_tier = resolver-local, derived from property_fit.{state,lga,is_capital_city} + designated_regional_centre_lgas (not a published field)
        "table": [
          { "when": ["NSW","capital_or_regional_centre"], "value": 1500000 },
          { "when": ["NSW","rest_of_state"],               "value": 800000  },
          { "when": ["QLD","capital_or_regional_centre"],  "value": 1000000 }
          /* … remaining rows mirror the content_md cap table … */ ],
        "default": null } },                       // unmapped location ⇒ resolver flags a curation gap

    { "leaf": "eligibility.fhg.deposit_percentage_required",
      "rule": { "kind": "parameter", "type": "percentage", "value": 5 } }
  ],
  "stacking": {
    "combines_with": ["kb.scheme.fhss"],   // concrete slugs only; the fhg↔state-concession edge is declared on the state doc (symmetric)
    "alternative_to": ["kb.scheme.help-to-buy"],      // assess against, do not sum
    "order_hint": 20
  }
}
```

#### Renderer vocabulary — constrained enum

The platform's UI has a constrained set of renderer components. Blueprints can only reference renderers in this enum, validated at build time. This prevents fragmentation, eases evaluation, and makes adding new renderers an intentional design decision. A component may **compose** two renderers (e.g. `risk-flag-list + checklist`, `data-table + opportunity-card`); each must independently be in the enum, and the compiler validates the pair.

| Renderer | Purpose | Outcome shape (rough) |
|---|---|---|
| `summary-card` | Short prose + key facts | `{ headline, key_facts[], call_to_action? }` |
| `swimlane-diagram` | Temporal flow across actors + who-pays/talks-to-whom | `{ phases[], actors[], cells[{ …, counterparty }], interactions[{ from_actor, to_actor, phase, flows }] }` |
| `checklist` | Tickable items with status | `{ items[{ label, status, doc_ref? }] }` |
| `data-table` | Tabular data | `{ headers[], rows[] }` |
| `calculator` | Interactive financial spine — phased cash-flow + what-if form | `{ inputs[], cash_events[] (by phase), outputs[], verdict? }` |
| `buying-strategy-card` | Bid plan with confidence | `{ max_bid, walk_away, comparables[], style }` |
| `decision-trail` | Chronological list of decisions | `{ entries[{ date, decision, reasoning }] }` |
| `risk-flag-list` | Flagged items with severity | `{ flags[{ severity, item, action }] }` |
| `comparison-grid` | Side-by-side comparison | `{ subjects[], dimensions[], cells[][] }` |
| `opportunity-card` | Alerts and recommendations | `{ kind, modeled_benefit, action }` |
| `scheme-stack-card` | Eligibility + applicable schemes | `{ applicable[], rejected[], total_benefit }` |
| `firb-workflow-card` | FIRB approval state machine (Mode B/D) | `{ stage, fees, documents[], next_action }` |
| `family-view-card` | Cross-border bilingual coordination (Mode B) | `{ child_view, parent_view, sync_state }` |

The FHB Mode A blueprint uses 9 of these (summary-card, scheme-stack-card, calculator, buying-strategy-card, risk-flag-list, checklist, swimlane-diagram, data-table, opportunity-card). Mode B blueprints will activate firb-workflow-card and family-view-card. New renderers are added as new component types emerge; each addition is a deliberate, reviewed change to this vocabulary.

**The two-spines + simulation model ([`lifecycle-simulation-model.md`](lifecycle-simulation-model.md)) extends shapes, not the enum.** Realizing it needs **zero new renderers** — a deliberate result, not an accident (constraint #7):

- **`cash_events` is a shared outcome primitive, not a renderer.** `cash_position` emits an ordered `cash_events[]` (`{phase, label, direction, amount: money_range, timing, counterparty, source_component}`); the `calculator` projects it onto the money×phase axis and `swimlane-diagram` (the `purchase_journey` component) reads the *same* list for its amount-bearing cells. Both **place** figures; neither recomputes — one-computer-per-figure extended to every consumer (outcomes-are-interfaces). The union is assembled by placement from the figure-owning components (`cash_position`, `eligibility`, `ownership_planning`) and gated by [`outcome-conformance.md`](outcome-conformance.md) so every placed event traces to an owner.
- **`interactions` extends the `swimlane-diagram` outcome**, not the vocabulary — the `counterparty` on each event yields the who-pays/talks-to-whom edges, at purchase *and* in ownership. (This also reconciles the rough shape's `cells[]` with the blueprint's field name; the earlier `events[]` sketch was a drift.)
- **Q&A is a conversational *tab kind*, not a renderer.** It is a shell surface over the engine's existing bilingual Q&A stream (engine-contract §4 `text_delta`, §6 buffer-then-gate) plus the `sessions` log — there is no `component_filled` outcome, so `ui_tabs` gains a `kind: "qa"` tab carrying no components; the renderer enum is untouched.
- **Base-scope preparation content** (document checklist / people-to-engage / money buffer) is a new **component** at `scope: base` (reclassified out of the per-property `due_diligence`), composing the existing `checklist` + `data-table` renderers.

So the Mode-A renderer count stays at 9; the model lands as extended outcome shapes + one new `ui_tabs` kind + one new base-scope component.

#### Why this architecture is sharp

- **The component becomes the unit of agent reasoning** — bounded scope, typed outcome, clear inputs. Easier to evaluate, harder to hallucinate against.
- **The blueprint becomes the unit of work** for the offline KB agent (Claude Code + maintainer): create components, evolve blueprints, redeploy.
- **The filled plan card becomes the unit of value** for the user: persistent, returnable, structured.
- **The UI is a thin renderer** over the blueprint + filled state — easy to build, easy to extend (add a new component → assign a renderer → CI validates).
- **Outcomes are interfaces, not parameters** — downstream components read structured outcomes (not raw upstream parameters), making the pipeline composable and the agent's reasoning bounded.
- **Token economics are favourable** — system prompt is bounded by current plan card + property + uploads, not by accumulated history.
- **Two fill paths keep math out of the model** — the per-leaf `agent_reasoning_required` flag splits each component into a deterministic resolver (copies, `derived_from`, calculator math — reproducible, free, no LLM) and an agent turn (judgment only). A what-if recompute costs nothing (resolver-path, no LLM): cash-on-hand resolves instantly in the client, a structural what-if (price/state/type) via a free engine resolver preview (engine-contract §10, [`lifecycle-simulation-model.md`](lifecycle-simulation-model.md)); only edits that reach an agent-flagged leaf spend a turn.
- **Blueprint evolution is decoupled from instance migration** — laws change frequently; user plan cards remain stable until they opt to refresh.
- **KB anchors and renderers are validated at build time** — the artifact compiler gates deployment on schema correctness, preventing the agent from referencing missing content or undefined renderers in production.

This is the operational substrate of the §11.1 three layers. Layer 1 produces blueprints + KB anchors; Layer 2 stores filled plan cards + sessions; Layer 3 runs the planning agent over the assembled context. The blueprint is the bridge — domain knowledge structured as a computational pipeline for agent reasoning *and* as a presentation specification for user-facing rendering.

### 11.10 Property data pipeline — narrow and demand-driven

**Architectural decision (May 2026):** the platform does NOT operate a comprehensive property listing scraping pipeline. We have no market position in property data acquisition (REA / Domain / CoreLogic dominate; scraping is legally fraught; API licensing is enterprise-grade). Building this would commit foundational engineering to a market where we have zero leverage.

Instead, property data feeds the platform via three narrow, demand-driven paths:

1. **Suburb enrichment** — public data feeds (ABS demographics, council planning, school catchments, flood maps, rental yield) compiled offline; populates the suburb-intelligence overlay in the base plan
2. **User URL paste** — when a user has a specific property in mind from REA / Domain / partner inventory, they paste the URL; synchronous fetch + normalise + cache; creates a property addendum on the user's plan card
3. **Browser extension capture** — Vietnamese-language analysis button on REA / Domain listings; user clicks → captures listing context → creates property addendum

A **fourth path** activates later in the wedge sequence (Wedge 1d, months 9+):

4. **Partner REA inbound push** — Tier 1 + Tier 2 partner REAs supply inventory via API or batch upload, in exchange for access to the qualified Vietnamese buyer demand pool. This is the eventual primary property source once partnership economics are visible.

#### What this means in practice

Property data is **not** load-bearing for the platform's primary value proposition. The base plan works without any property data at all. Property data only matters for the Phase B property addendum (per-property analysis), and only when the user has chosen to engage with a specific property.

Specifically:

| Use case | Property data needed | Source |
|---|---|---|
| Base plan — eligibility, scheme stacking, FIRB workflow, cash math against target price range, family coordination, investment strategy | None — just state + target price range + zone | User-supplied at onboarding |
| Map view — suburb-intelligence overlay (investment grade, rental yield, family-friendly, Vietnamese-community proximity) | Suburb-level only — no individual property data | Public data feeds (offline-curated) |
| Tìm Nhà property search service (§11.11) | Property listings from REA / Domain / partner inventory — manually researched by Vietnamese-speaking curator team | Human curation (legally permitted manual research) |
| Phase B property addendum — property_assessment, due_diligence, buying_strategy, settlement_prep | Specific property details | User URL paste OR browser extension OR Tìm Nhà handoff OR (later) partner REA push |

The platform asset is **Vietnamese buyer demand + lifecycle planning intelligence**, not property data. REA partners eventually push inventory because that is how they earn access to the demand pool — see [§8.5 in 03-strategy.md](../03-strategy.md#85-rea-partnership-economics--two-tier-complementary-model) for the partnership economics.

#### Suburb enrichment pipeline

The one pipeline we *do* operate offline. Compiles public + lightly-subscribed data into a `suburbs` table keyed at the ABS **Suburb and Locality (SAL)** geography level. Source breakdown verified against actual ABS API access patterns (May 2026 research):

| Source | Tier | Cost | Update frequency | Fields contributed |
|---|---|---|---|---|
| **ABS Data API — Census 2021 (SAL-level)** | Free | $0 | 5-yearly (2021 latest, 2026 in progress) | Vietnamese ancestry %, country of birth, language at home, family composition, age distribution, education, dwelling characteristics, median dwelling value (Census-time), median rent (Census-time) |
| **ABS Data API — non-Census series (SA2-level)** | Free | $0 | Quarterly | Estimated resident population, dwelling indicators, sub-state Lending Indicators (where granular enough) |
| **ABS SEIFA 2021 (SAL-level)** | Free | $0 | 5-yearly | Socio-economic indexes (IRSAD/IRSD/IER/IEO) → `seifa_irsad_decile` — the socio-economic spine |
| **State Education + ACARA school locations** | Free | $0 | Annual | School catchments + school locations (lat/lon). **NAPLAN/ICSEA performance data is licence-restricted** (no redistribution, Data Access Program) — `school_catchment_quality` derives from locations + catchments, *not* redistributed rankings |
| **State Emergency / Planning portals** | Free | $0 | Per-event + periodic | Flood risk bands, bushfire zones, planning changes |
| **State Valuer-General — actual sales** | Free | $0 | NSW weekly · VIC quarterly | **Current** suburb median sale price — NSW **Bulk PSI** (actual sales → aggregate), VIC **Property Sales Report** (median/suburb, pre-aggregated). **QLD suburb median is closed** (IP/revenue; QVAS >$20k) → `median_* = null` |
| **State crime agencies (BOCSAR · CSA Vic · QPS)** | Free | $0 | Quarterly | Recorded incidents by suburb/LGA → raw `crime_incidents_per_1000` (**map-only — no resolver band**; see suburb-data-foundation §1) |
| **RBA / interbank FX rates** | Free | $0 | Daily | VND/AUD rate for price-range conversion |
| **PropTrack subscription (optional)** | Paid | ~$79/month | Continuous | Current median rent, days on market, rental demand by suburb |
| **CoreLogic / Cotality subscription (optional)** | Paid | ~$139/month | Continuous | Current median sale prices, capital growth rates, yields, suburb-level market stats |

This is **batch-updateable** and operates parallel to §11.9 blueprint KB curation. CI gate validates that every suburb referenced by the base plan has a complete enrichment record before deployment. The **engineering spec** — the `suburbs` table schema, the per-state adapters, the SAL join grain + correspondences, and the provenance/license register (the ACARA restriction is a first-class row) — is [`suburb-data-foundation.md`](suburb-data-foundation.md); this section holds the strategic scope, that doc holds the materialization. Note: suburb data is **reference data in Postgres**, *not* a prose KB compiled to the artifact (it is neither structure nor runtime-state — a third bucket).

**Deployment tier optionality:**

- **Wedge 1a minimum (free tier only):** ABS Census + **SEIFA** (socio-economic) + **current transaction-based suburb medians for NSW/VIC** (VG Bulk PSI / VPSR — *not* just stale rates-valuations) + **crime bands** + qualitative tags (Vietnamese-community proximity, school catchment, flood risk) are sufficient for the base plan's overlay. **QLD median is `null`** (closed) — honest-partial, and harmless because the target price range is a *user input* (constraint #1), so the median is decoration, not load-bearing. Vietnamese-community proximity — the signature field — is free at SAL level. The base plan works with zero paid subscription.
- **Wedge 1c upgrade (~$80/month):** Add PropTrack for current rent + days-on-market signal. Improves Mode A buying strategy quality and Mode C yield modelling.
- **Wedge 3 upgrade (~$220/month combined):** Add CoreLogic for **QLD current median** (the one state without a free sales feed) + capital-growth / yield **composites**. NSW/VIC current median is already free above; CoreLogic is required only for investor-grade analytics (Mode C/D) and to close the QLD price gap.

**Verified suburb-data access points (May 2026):**

- ABS Data API: `https://api.data.abs.gov.au/data/{dataflow}/{key}` — SDMX-formatted JSON / XML / CSV; no API key for the main Data API
- ABS Census QuickStats: `https://abs.gov.au/census/find-census-data/quickstats/2021/SAL{ID}` (e.g., Cabramatta = SAL10738 at 37.8% Vietnamese ancestry; Footscray = SAL20935)
- ABS DataPacks: bulk Census-tier-1 + tier-2 downloads for offline ingestion
- TableBuilder: interactive builder requiring organisation registration (useful for non-programmatic exploration, not for the pipeline)

The Vietnamese-community proximity field — the **most distinctive enrichment for our positioning** — is fully sourceable from the free ABS Data API at SAL granularity. This is genuinely good news: the platform's signature differentiating field has zero data-acquisition cost.

#### User URL paste handler

The synchronous path when a user has a specific property. Lightweight adapter that:

1. Receives a URL (REA, Domain, allhomes, partner REA, any source)
2. Fetches the page (via headless Chrome / Playwright for JS-rendered portals; direct fetch for SSR sources)
3. Extracts canonical fields per the Property schema (see below)
4. Caches the result keyed by URL hash with 24-hour TTL
5. Returns a property_id for the plan card to reference

If the fetch fails or returns shell-only, the handler reports honestly to the user and offers manual property detail entry as a fallback.

This is the **critical-path** property data mechanism for Phase B. Most active Mode A users will use it — they're already browsing REA / Domain themselves and bring URLs to us.

#### Browser extension capture

Companion to user URL paste. Installed on the user's browser, shows a "Phân tích bằng tiếng Việt" (Analyse in Vietnamese) button on every REA / Domain listing. Click captures listing context client-side (HTML scraping happens in the user's browser, not on our servers — this avoids ToS issues with portal terms-of-service) and posts the captured context to the platform as a Phase B activation event.

#### Canonical Property schema (unchanged from prior §11.10 draft)

After normalisation, all properties — from any source — conform to a common shape. The schema sketched in the previous §11.10 design still applies; the only change is that the *acquisition pipeline* feeding it is narrower than originally specified.

#### What we explicitly do NOT do

- **No scheduled scraping of REA.com.au or Domain at scale** — this is legally fraught, expensive to maintain, and unnecessary given our base-plan + on-demand-fetch design
- **No comprehensive property database** — we don't try to know about every Australian property
- **No competing with REA / Domain on listings discovery** — they're the discovery layer; we're the planning layer
- **No paying for CoreLogic / PropTrack full property feeds** — too expensive for what we'd use; suburb-level subscription is the maximum we need

This restraint is the architectural decision. We are deliberately *not* operating in the property data acquisition market.

### 11.11 Tìm Nhà property search service — agent-invoked, human-curated

**Tìm Nhà** ("Find a Home" in Vietnamese) is the platform's property search **service**, distinct from the property data pipeline (§11.10). It is the bridge between base plan and property addendum for users who don't already have a specific property in mind. The service is **agent-invoked and human-fulfilled**.

#### Why a service, not an algorithm

We don't operate a property listing scraper or recommendation engine (§11.10). For users who want specific property suggestions, a Vietnamese-speaking human curator manually researches REA, Domain, and partner REA inventory based on the user's base plan criteria, and returns a shortlist. The curator works in a **legally permissible manual research mode** — the same way a buyer's agent or financial planner would research property options for a client.

This is genuinely defensible:

- Vietnamese language + cultural fluency in curation (filtering for community-relevant suburbs, Vietnamese-friendly REA agents, family-appropriate properties)
- Skilled human pattern-matching that an automated recommendation engine couldn't replicate well at the platform's current scale
- No legal exposure (manual research, not scraping at scale)
- High margin (~$50–100/hour curator cost × ~2 hours per engagement; charge $200–500 per engagement)

#### Agent integration — Tìm Nhà as a tool

The planning agent invokes Tìm Nhà as a tool when appropriate. The flow:

```
[Base plan complete; user signals readiness for specific properties]
                  ↓
[Agent decides: invoke Tìm Nhà tool]
                  ↓
[Agent generates structured search brief from base plan state:]
   {
     buyer_mode: "A",
     state: "VIC",
     target_price_range: { min: 600000, max: 750000 },
     target_zones: ["Footscray", "Sunshine", "Yarraville", "Maidstone"],
     property_type_preference: ["established_apartment", "new_apartment"],
     bedrooms_min: 2,
     scheme_eligibility: { fhg: true, vic_fhb_partial: true },
     family_context: { funding_capacity: 800000, ... },
     intent_tags: ["close_to_vietnamese_community", "good_transport", "investor_with_owner_occupier_intent"],
     additional_criteria: [/* free-text from user */]
   }
                  ↓
[Brief routed to Vietnamese-speaking curator team queue]
                  ↓
[Curator manually researches REA, Domain, partner REA inventory]
[24–48 hour SLA — curator returns 3–5 properties]
                  ↓
[Agent receives curated shortlist + curator notes]
[Agent reasons: ranks against plan, generates per-property pre-assessment]
[Agent presents to user with rationale per property]
                  ↓
[User picks one or more → URL paste triggers Phase B addendum activation]
                  ↓
[Property addendum filled by agent in plan card]
```

The **agent is orchestrating throughout**. Humans do one specific task (curation of listings) inside an agent-driven workflow. This preserves the fully-agentic architecture while leveraging the human-only-can-do task of culturally-aware manual research.

#### Curator team operations

| Aspect | Detail |
|---|---|
| Team | Vietnamese-speaking property research curators (initially contracted; full-time as volume grows) |
| Required skills | Vietnamese fluency, basic understanding of AU property market, familiarity with REA / Domain search filters, sensitivity to Vietnamese-community suburb preferences |
| Tools provided | Access to base plan, search brief, REA + Domain (their normal user accounts), partner REA inventory portal, internal scoring sheet, plan handoff template |
| Output format | Shortlist of 3–5 properties with: URL, headline summary, fit-against-plan notes, recommended rank, curator comments |
| SLA | 24–48 hours from request to delivery |
| Pricing | $200–500 per engagement (user-facing); curator cost ~$50–100/hour × ~2 hours per engagement |
| Volume estimate Year 2 | ~800 engagements/year (3 per active Mode A user × ~25% of active base) — $280k revenue |
| Volume estimate Year 3 | ~2,500 engagements/year across Modes A–D — $750k–$1M revenue |

#### Quality control + REA partnership intelligence

Each Tìm Nhà engagement produces **two artifacts**:

1. **The shortlist for the user** (primary deliverable)
2. **An internal note** identifying which REAs / agents appeared in the search, how good their inventory was, how Vietnamese-buyer-friendly their listings were

The second artifact compounds into REA partnership intelligence over time. After ~6 months of Tìm Nhà operations, the platform has empirical data on which REAs are best at serving Vietnamese buyers. This list becomes the foundation for the Tier 1 partner REA pitch (§8.5) — we approach the REAs we've already identified as good for our segment.

This is a clean feedback loop: **the human service surfaces REA quality data that informs future automated partner integrations.**

#### Why Tìm Nhà is the right shape, not just a workaround

Three reasons this is genuinely better than a recommendation algorithm would be at this stage:

1. **The Vietnamese-community suburb knowledge is hard to encode** — what makes a suburb "Vietnamese-family-friendly" combines language ecosystem, community institutions, restaurants, schools, transport, family-network density. A curator captures this implicitly; an algorithm would need years of training data we don't have.

2. **High-touch curation IS the differentiation** — Vietnamese buyers tell their family + community network about good services. A culturally-fluent human curator builds the word-of-mouth that compounds Vietnamese-AU and Vietnamese-VN community trust faster than any algorithm.

3. **It's profitable from day 1** — unlike a recommendation algorithm that needs significant scale before paying back the infrastructure investment, Tìm Nhà has positive unit economics from the first engagement. This funds the rest of the build.

This is the operational substrate of the §11.10 narrow-and-demand-driven property data approach. The platform's property data dependency is bounded; the human service fills the gap precisely where automation can't reach. The four blueprints' `property_assessment` and downstream property-specific components consume property data from either Tìm Nhà handoff, user URL paste, browser extension, or (eventually) partner REA push — all narrow, demand-driven paths.

---

## 12. Context and flow are the moats

§11 answered *what* we're building. This section is the *why* — the strategic framing that determines where engineering investment compounds and what makes the platform defensible.

### 12.1 The agentic platform formula

> **Quality(agent) = Quality(LLM) × Quality(Context) × Quality(Flow)**

Three observations follow:

1. **LLM quality is the thing you don't own.** It's commoditising — Claude, GPT, Gemini, Llama are converging on capability. Anything built on LLM capability alone is rented infrastructure.
2. **Context quality is your data moat.** Everything accumulated — curated KB, per-user state, decision trails, anonymised cross-user patterns. Hard to copy because it takes years.
3. **Flow quality is your engineering moat.** This is the IP. Most "agent failures" are flow failures, not LLM failures. Teams mistake LLM choice for product quality; it almost never is.

By 2027 every serious competitor has access to roughly the same LLMs as you. You compete on context and flow. Nothing else.

### 12.2 Layer mapping — same architecture, moat lens

| Layer (§11) | Moat-lens reading |
|---|---|
| Layer 1 — Static knowledge base | **Curated context** — team-decided facts, update cadence, source verification, change detection |
| Layer 2 — User state | **Accumulated context** — what each user brings to every interaction |
| Layer 3 — Agentic reasoning | **Flow** — orchestration over assembled context |

The vocabulary matters because it makes the defensibility visible. The three-layer diagram is a moat diagram in disguise.

### 12.3 Context engineering as a discipline

Context has a budget. At inference time you have ~200k tokens (or whatever the model allows). You cannot put everything in. Context engineering decisions:

- What's static vs retrieved per session
- What's summarised vs verbatim
- What's relevant for *this* query vs the user's full history
- What cross-user signal (anonymised) is worth surfacing — *"Sarah's situation looks like 47 prior users at this stage; here's how their outcomes informed her recommendations"*

This is where the **policy intelligence moat ([§8.6 in 03-strategy.md](../03-strategy.md#86-policy-intelligence-as-a-secondary-moat)) and product reasoning converge** — same accumulated dataset, two uses.

### 12.4 Flow is testable; context is auditable

Both are observable, which makes them improvable:

- Each flow gets an eval set (what % correctly identifies HECS-blocking-FHG cases? What % correctly flags a problematic Section 32 clause?)
- Each KB update gets a diff review (did this rule change invalidate any user's prior recommendation? Notify them.)
- Each user state mutation gets a log (the decision trail)

You can swap LLMs every six months without losing the IP. You cannot swap your eval sets, your KB curation discipline, or your user state schema. So investment goes there.

### 12.5 The context decay problem

User state grows linearly; relevance does not. Sarah's Day 7 contract is critical context at Day 365 for refi reasoning, but irrelevant for daily Q&A. Three context tiers:

- **Active context** — current session + recent state + flagged-relevant artifacts
- **Cold context** — archived but retrievable on demand
- **Summarised context** — rollups (*"user has reviewed 25 properties, 3 shortlisted, comparison ready"*)

Retrieval and summarisation strategy *is* context engineering. Under-invested teams find their agents getting weird once user state grows past 50k tokens.

### 12.6 Flow taxonomy

Flows are the testable unit. Six types worth distinguishing for this product:

| Flow type | Example | Pattern |
|---|---|---|
| Single-shot synthesis | "Should I clear my HECS?" | Retrieve context → reason → return |
| Document pipeline | Upload S32 → parse → extract → flag → format → save artifact | Multi-step with verification gates |
| State machine | Pre-approval (gather → verify → submit → track) | Explicit stages with progression rules |
| Event-driven | RBA cut → check user LVR → if graduated, alert | Triggered by external signals |
| Conversational | Quick chat Q&A | Multi-turn with shared state |
| Hybrid | Background monitor + user-initiated session | Async background + sync foreground |

Each flow type needs its own eval harness, its own context strategy, its own quality bar. The mistake is treating them all as "the agent" — they are six different products built on shared infrastructure (Layer 1 KB + Layer 2 state).

### 12.7 The flywheel

The two moats compound:

```
More users → more context → better flows possible
            ↑                              ↓
       More users    ←    Better outcomes
```

Neither moat works alone. Context without flow is a database; flow without context is generic AI. Both together is a defensible platform.

### 12.8 Implications for org structure

The engineering team should reflect the moats:

| Function | Owns |
|---|---|
| **Context engineering** | Layer 1 curation, Layer 2 schema, retrieval, summarisation, change-detection ops |
| **Flow engineering** | Layer 3 modes, prompt design, tool integration, eval harnesses |
| **Application engineering** | The surfaces (UX) on top of context + flow |

Many AI-first companies collapse this into "AI engineers" and end up with everyone doing everything badly. Splitting it gives faster iteration and clearer ownership of the moats.

### 12.9 The pitch implication

Not *"we have AI"* or *"we have prompts."* Anyone has those.

> *"We have N years of Australian first home buyer journey context, and a library of evaluated flows that operate on it."*

That is the asset. To investors, partners, hires — that is the asset. Everything else is replicable.

---

