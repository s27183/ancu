# Vietnamese Diaspora Property Platform — Research & Strategy

A **Vietnamese property lifecycle planning service** — AI-augmented planning for the Vietnamese diaspora investing in Australian property, with **human-curated property search (Tìm Nhà)** when buyers are ready. Independent. Paid by users.

The product is a lifecycle planning service, **not** a property tech platform. The data moat is Vietnamese buyer demand + cultural curation + agentic planning, not property data. The base plan generates immediately on onboarding (state + price range + zone + intent — no property data needed); specific properties layer in later via Tìm Nhà, URL paste, browser extension, or partner REA push.

This document set contains the research, strategy, architecture, UX model, and roadmap. Last verified: **May 2026**.

---

## The platform in one paragraph

The Vietnamese diaspora property segment is structurally unserved by independent, end-to-end planning tools. Vietnamese-Australians (318,760 Vietnam-born + 334,781 with Vietnamese ancestry) and Vietnam-located buyers (Vietnamese = 4th largest foreign buyers of Australian residential property, 8–10% of off-the-plan apartments) are large, growing, and unaddressed by incumbents (Aussie, Lendi, HTAG, banks). The platform serves four user modes (Vietnamese-AU FHB, Vietnam-parent funding AU property, AU investor, VN-located investor) on a unified architecture, with plan-first entry (property added when the user is ready) and FIRB-aware mode switching. Independence is the moat: buyers pay; REAs partner under fee structures that preserve buyer-side trust. Cultural + linguistic vertical, cross-border family coordination, and lifecycle continuity define the defensible position.

For the working Mode A prototype demonstrating property analysis, scheme stacking, and document review for Vietnamese-Australian FHBs, see [`first_home_buyer_plan.html`](first_home_buyer_plan.html).

---

## Document index

| File | Covers | Read if |
|---|---|---|
| **[01-market.md](01-market.md)** | Federal + state scheme landscape (FHG, Help to Buy, FHSS, state stamp duty concessions, QLD new-home concession, FIRB regime), the temporal transaction flow, FHB pain points (Finder 2025), market sizing across four Vietnamese-diaspora segments | …you want to understand the underlying market mechanics and segment sizes |
| **[02-competitive-landscape.md](02-competitive-landscape.md)** | Existing tools (firsthomebuyers.gov.au, Aussie, Lendi, CBA, HTAG, Proper Inspect, DocoCheck, Tomo, Habito), the current Vietnamese buyer channel structure with chain comparisons across all four user modes, gap analysis | …you want to understand who's already in the space and where the cost / inefficiency in the current Vietnamese buyer chain sits |
| **[03-strategy.md](03-strategy.md)** | Positioning (five moats + augmentation framing), REA partnership economics (two-tier complementary model: Vietnamese-community + mainstream), policy intelligence as secondary moat, hard truths and cross-border / FIRB risks, the 30-month four-wedge build sequence | …you want the business strategy and go-to-market plan |
| **[architecture/architecture.md](architecture/architecture.md)** | Three-layer architecture (static KB / user state / agentic reasoning), update cadences, interaction intensity by phase, product modes, Claude Code fit, the user state trap, context-and-flow framing (the agentic platform formula), flow taxonomy, org structure | …you want the technical strategy and build approach |
| **[architecture/structure-map.md](architecture/structure-map.md)** | The hub — every structure (blueprint, KB, the two foundations, agentic flow, plan card, profile/plan, renderers, engine/shell) and how they relate across five planes (build-time, runtime data, agentic turn, persistence, engine/shell), in mermaid, with a map↔architecture index | …you want the whole picture in one place — **read this first** for orientation |
| **[architecture/agentic-boundary.md](architecture/agentic-boundary.md)** | The resolver/agent decision rule — when an operation needs the LLM vs deterministic rules; the three-trigger test; worked boundary categories; the validating simulation | …you need to decide whether something is resolver-path or agent-path |
| **[architecture/agentic-flow.md](architecture/agentic-flow.md)** | How the reasoning runs — the four agent types, dynamic prompt structure, vendor-neutral run layer, KB access split, and context management (and which plc_agent machinery is deliberately omitted) | …you're building the planning agent's runtime |
| **[architecture/isolation-model.md](architecture/isolation-model.md)** | Units of isolation — plan card vs turn, the per-card serialization invariant, engine-owned conversation persistence (not a sidecar session), vendor-as-config, and staged turns | …you need to know what is isolated from what, or what a "turn" is |
| **[architecture/engine-contract.md](architecture/engine-contract.md)** | The engine↔shell boundary — primitives (`/api/engine/*`), the typed event taxonomy, metering (`usage`), the compliance gate, and the PG schema (§9.1 — `profiles` ⟵ `plan_cards`, mode derived) | …you're building across the engine/shell API or the persistence layer |
| **[architecture/fact-model-unification.md](architecture/fact-model-unification.md)** | Design finding + Decision 1 — the one mode-independent buyer fact base (`profile.*`), per-journey plan cards, mode derived (never a key), and the concrete unified schema | …you're touching the buyer fact model, the modes, or the profile/plan split |
| **[architecture/property-model-foundation.md](architecture/property-model-foundation.md)** | The second foundation — completing the property structure: the `property_type` enum (incl. `vacant_land`), the `property_fit` surface, the property-dependent scheme structure, and the build-time-structure-vs-runtime-data discipline | …you're touching property types, the property fact surface, or property-dependent schemes |
| **[04-ux-model.md](04-ux-model.md)** | Plan-first entry, four user modes, seven UX surfaces, two worked journeys (Sarah for Mode A Vietnamese-AU FHB; An Tran's cross-border family for Mode B with FIRB workflow), MVP scope for Wedge 1, six traps to avoid | …you want to understand the user experience, surfaces, and concrete user journeys |
| **[05-roadmap.md](05-roadmap.md)** | Next steps for a builder pursuing this — user research, regulatory scoping, MVP scope, distribution tests, partnership exploration | …you want the execution checklist |
| **[references.md](references.md)** | All 54 numbered references + document control + disclaimers | …you want to verify a specific claim or follow a source |
| **[blueprints/](blueprints/)** | Plan card blueprint specifications — concrete data + presentation specs that the offline KB agent maintains, the user-facing planning agent reads at session time, and the UI renders | …you want the working specs Claude Code builds against |
| **[blueprints/fhb-domestic-au.md](blueprints/fhb-domestic-au.md)** | Mode A — Vietnamese-AU citizen / PR FHB — **9-component pipeline** (buyer_profile → property_assessment → eligibility → **mortgage_finance** → cash_position → buying_strategy → due_diligence → settlement_prep → ownership_planning) | …you're building the Mode A flow |
| **[blueprints/fhb-foreign-au.md](blueprints/fhb-foreign-au.md)** | Mode B — Vietnam-parent funding AU child OR AU temp resident FHB — **11-component pipeline** adding `family_context`, `firb_workflow`, `mortgage_finance` (non-resident variant), `cross_border_funding`; foreign-buyer surcharge + FIRB fees + FX; vacancy fee + non-resident tax | …you're building the cross-border / FIRB-aware FHB flow |
| **[blueprints/investor-domestic-au.md](blueprints/investor-domestic-au.md)** | Mode C — Vietnamese-AU investor (citizen / PR) — **11-component pipeline** with `investment_strategy`, `mortgage_finance` (investor variant: IO + offset + investor lenders), `yield_modelling`, `tax_structure` (incl. negative gearing); investor-tactics buying; portfolio planning. Competes directly with HTAG | …you're building the domestic investor flow |
| **[blueprints/investor-foreign-au.md](blueprints/investor-foreign-au.md)** | Mode D — Vietnam-located investor — **13-component pipeline** combining Mode B foreign-person components with Mode C investor components, plus `mortgage_finance` (non-resident investor — most restrictive lender pool); non-resident tax (FRCGW, no CGT discount); repatriation strategy; most complex of the four | …you're building the Vietnam-located investor flow |
| **[first_home_buyer_plan.html](first_home_buyer_plan.html)** | Mode A example output — Overview, Temporal flow, Before you buy, After you buy, Cash calculator tabs demonstrating what a filled plan card looks like | …you want the working prototype demonstrating property analysis + scheme stacking + document review |

---

## Audience guide — what to read

**If you're an investor or partner evaluating the opportunity:**
1. This README (5 min) — get the framing
2. [01-market.md](01-market.md) §5 Market sizing + §5.6 Vietnamese-diaspora segment + §5.8 FIRB regime (10 min) — quantitative case
3. [02-competitive-landscape.md](02-competitive-landscape.md) §6.8 The current Vietnamese buyer channel structure (10 min) — the inefficiency being solved
4. [03-strategy.md](03-strategy.md) §8 Strategic positioning + §10 Wedge sequence (15 min) — the business plan
5. [04-ux-model.md](04-ux-model.md) §13.5 An Tran's cross-border family journey (5 min) — the differentiated flow nobody else does
6. [first_home_buyer_plan.html](first_home_buyer_plan.html) Strategy + UX model tabs — the working prototype

**If you're a technical co-founder or early hire:**
1. This README (5 min)
2. [architecture/structure-map.md](architecture/structure-map.md) (10 min) — the hub map: every structure and how they relate, the orientation before the detail
3. [architecture/architecture.md](architecture/architecture.md) entire (20 min) — three-layer architecture + context-and-flow framing + Claude Code fit
4. [04-ux-model.md](04-ux-model.md) entire (15 min) — surfaces, modes, journeys
5. [03-strategy.md](03-strategy.md) §10 Wedge sequence (10 min) — what to build first and why
6. [02-competitive-landscape.md](02-competitive-landscape.md) §6.5 AI-native point tools + §6.8 chain structure (10 min) — context for product decisions

**If you're a Vietnamese-community REA being approached as a partner:**
1. [03-strategy.md](03-strategy.md) §8.4 Augmentation positioning + §8.5 Tier 1 — Vietnamese-community REAs (10 min) — how the partnership works and why it's cooperative
2. [04-ux-model.md](04-ux-model.md) §13.2 The four user modes (5 min) — who the platform serves
3. [first_home_buyer_plan.html](first_home_buyer_plan.html) Overview + UX model tabs — see the buyer-side experience

**If you're a mainstream REA (Ray White, McGrath, etc.) considering Tier 2 partnership:**
1. [03-strategy.md](03-strategy.md) §8.5 Tier 2 — Mainstream REAs (10 min) — what you get, what you pay
2. [02-competitive-landscape.md](02-competitive-landscape.md) §6.8 chain analysis (10 min) — the Vietnamese demand you currently can't reach
3. [04-ux-model.md](04-ux-model.md) §13.4 Plan-first onboarding (5 min) — how the platform routes buyers to you

**If you're a regulator or policy contact:**
1. This README (5 min)
2. [03-strategy.md](03-strategy.md) §8.6 Policy intelligence as a secondary moat (10 min) — the data-feed positioning
3. [03-strategy.md](03-strategy.md) §9.2 Cross-border and FIRB-specific risks (10 min) — the compliance approach
4. [01-market.md](01-market.md) §5.8 FIRB regime (5 min) — how the platform respects the regulatory frame

---

## Quick links

- **Example output (Mode A prototype):** [first_home_buyer_plan.html](first_home_buyer_plan.html) — open in browser, 5 interactive tabs (Overview, Temporal flow, Before you buy, After you buy, Cash calculator) demonstrating the kind of personalised plan the platform produces for a Vietnamese-Australian FHB
- **Legacy single document:** [findings-legacy.md](findings-legacy.md) — the full document set in single-file form (pre-split), kept for reference
- **Source verification dates:** all federal scheme data verified as of May 2026; state scheme data verified through 1 May 2025 budget cycle; market sizing data verified Q4 2025 ABS + 2024 Home Affairs

---

## Section numbering reference

Sections retain their original numbering across the split (§1–§14). To find a referenced section quickly:

| Section | Lives in |
|---|---|
| §1–§5 | [01-market.md](01-market.md) |
| §6–§7 | [02-competitive-landscape.md](02-competitive-landscape.md) |
| §8–§10 | [03-strategy.md](03-strategy.md) |
| §11–§12 | [architecture/architecture.md](architecture/architecture.md) |
| §13 | [04-ux-model.md](04-ux-model.md) |
| §14 | [05-roadmap.md](05-roadmap.md) |
| References + Document control | [references.md](references.md) |

In-narrative references like *"see §8.5"* will navigate within their containing file. References to sections in other files are linked explicitly (e.g., *"see [§6.8 in 02-competitive-landscape.md](02-competitive-landscape.md#68-the-current-vietnamese-buyer-channel-structure)"*).

### Key subsections worth knowing about

| Subsection | Lives in | Why it matters |
|---|---|---|
| §6.8 Current Vietnamese buyer channel structure | [02-competitive-landscape.md](02-competitive-landscape.md) | Maps the existing chain across all four user modes with cost breakdowns; the inefficiency the platform addresses |
| §8.4 Augmentation positioning | [03-strategy.md](03-strategy.md) | "Augmentation, not disintermediation" — the cooperative framing for the channel |
| §8.5 REA partnership economics (two-tier) | [03-strategy.md](03-strategy.md) | Tier 1 (community REAs) + Tier 2 (mainstream REAs) with independence guardrails |
| §10 Build strategy & wedge sequence | [03-strategy.md](03-strategy.md) | The 30-month four-wedge plan |
| §11.9 Blueprint as data model + presentation specification | [architecture/architecture.md](architecture/architecture.md) | The dual-role plan card blueprint — data model AND UI driver; storage/deployment; system prompt construction |
| §11.10 Property data pipeline — narrow and demand-driven | [architecture/architecture.md](architecture/architecture.md) | The platform does NOT operate a property scraping pipeline. Property data flows only via narrow demand-driven paths: suburb enrichment (public feeds), user URL paste, browser extension, and (later) partner REA push |
| §11.11 Tìm Nhà property search service | [architecture/architecture.md](architecture/architecture.md) | Agent-invoked, human-curated property search. Vietnamese-speaking curators manually research listings. $200–500 per engagement |
| §13.2 The four user modes | [04-ux-model.md](04-ux-model.md) | Mode A/B/C/D with FIRB status, default flows |
| §13.4 Plan-first onboarding + suburb-intelligence map | [04-ux-model.md](04-ux-model.md) | Replaces property-first entry. User enters with situation; map shows suburb intelligence (investment / yield / family / Vietnamese community), not property pins |
| §13.5 Worked examples (Sarah + An Tran) | [04-ux-model.md](04-ux-model.md) | Two concrete journeys: Mode A FHB + Mode B cross-border family |
| §13.9 Agent / user flow + plan card lifecycle | [04-ux-model.md](04-ux-model.md) | End-to-end sequence from map → property card → plan tab → planning agent → filled card → persistence |

---

## Document control

- **Status:** Living document set, May 2026
- **Maintenance:** Quarterly re-verification recommended for §1 (federal schemes) and §2 (state schemes) in [01-market.md](01-market.md); monthly recommended for market sizing data in §5
- **Companion artefact:** [first_home_buyer_plan.html](first_home_buyer_plan.html) (interactive prototype)
- **Disclaimer:** This document set is general information only — not financial, legal, mortgage, immigration, or migration advice. All scheme eligibility, stamp duty calculations, FIRB requirements, and cross-border tax obligations should be confirmed with licensed professionals (mortgage broker, conveyancer, FIRB lawyer, Vietnam-licensed legal counsel, registered tax agent) before commitment.
