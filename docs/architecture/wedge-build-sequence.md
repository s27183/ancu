# Wedge build sequence — the dependency order

> **What this is.** The **build-dependency** view of the remaining wedges: what each one depends on, which external (non-code) prerequisites gate it, and the resulting topological build order. This is a *different lens* on the same wedges that [§10 in 03-strategy.md](../03-strategy.md#10-build-strategy--wedge-sequence) sequences by **go-to-market time** (willingness-to-pay, cross-sell, trust earned). Both orderings are valid; they **diverge** (see the decision below). Per-item status lives in [`grounding-checklist.md`](../grounding-checklist.md) — this doc holds the wedge-level map, not the item detail.
>
> **Audience:** anyone deciding what to build next, or why the build order is what it is.

---

## Two orderings, one wedge set

The same three wedges can be ordered on two independent axes:

| Axis | Lives in | Orders by | Result |
|---|---|---|---|
| **GTM time** | strategy §10 | willingness-to-pay, parent cross-sell, trust earned by the prior wedge | Wedge 1 → 2 (Vietnam-parent) → 3 (investor) |
| **Build dependency** | *this doc* | foundationality — fewest open upstream deps, unblocks the most | unification → Mode **C** → Mode **B** → Mode **D** |

The divergence is real and deliberate: GTM puts **Mode B before Mode C** (Vietnam-parent has the highest WTP and a built-in cross-sell from Wedge-1 customers' parents); build-dependency puts **Mode C before Mode B** (Mode C carries *no external prerequisites*, Mode B's launch is gated on legal/partnership work that isn't code). Which axis governs is a **decision** (below), not a default.

---

## Status: the foundation layer is almost entirely done

The architecture was deliberately built **mode-generic** (one `profile.*` fact base, mode *derived*; structural compiler gates already run over all four blueprints). So mode expansion is *activate-a-blueprint, not rebuild*. The dependency roots are closed:

| Foundation | Checklist item | Status |
|---|---|---|
| Buyer fact-base (unified `profile.*`, mode derived) — *unblocks 2 & 5* | 1 | `[x]` |
| Property model foundation | 3 | `[x]` |
| Artifact compiler + gates (structural gates cover **all 4** blueprints; *semantic* gates Mode-A scoped) | 4 | `[x]` |
| PG migration + runner + OTP skeleton (`profiles` ⟵ `plan_cards`) | 5 | `[x]` |
| **Identity-layer unification (multi-mode)** | **2** | **`[x]` — deferred half landed via the Mode-B build (2026-07-03): `off_title_parties[]`, `tax_residency → tax{}`, the §11.9 read-namespace convention, and the F14 close all shipped** |

**All five foundations are now closed.** Every mode-expansion wedge that sat on item 2 (B, C, D) has since been built to completion — see the wedge table below.

---

## Dependency graph of the remaining wedges

| Wedge | Mode | Depends on (code) | External (non-code) prereqs | Buildable to completion now? |
|---|---|---|---|---|
| **Identity-layer unification** | — (foundation) | item 1 (done) only | none | **Done** |
| **Wedge 3 — domestic investor** | C | unification + investor-tax KB (`kb.tax.*` / `kb.investor.*`, authorable) + extend semantic gates + the drafted `investor-domestic-au` blueprint | **none** — no FIRB, no cross-border | **Done — build-complete, full-stack live-verified (2026-06-27/28)** |
| **Wedge 2 — Vietnam-parent** | B | unification + `firb_workflow` + `cross_border_funding` + `family_context` | VN legal counsel (day 1), money-transfer partner (pre-launch), VN-PDP data-residency capability — strategy §9 | **Code done, live-turn-verified (2026-07-03)** — launch still gated on the external prereqs |
| **Wedge 3 — foreign investor** | D | unification **+ Mode C** (investor machinery, done) **+ Mode B** (FIRB / residency, done) | all of Mode B's (inherited via `cross_border_funding` reuse) | **Done — build-complete (P1–P5, 2026-07-04), live-verified; grounding fix 2026-07-05.** See [`mode-d-wedge.md`](mode-d-wedge.md) |
| **Wedge 1b / 1c** — Tìm Nhà / URL-paste + extension | A | Wedge 1a (done) + Phase-B addenda activation | 1b: curator ops; 1c: none | Yes — **orthogonal track**, no mode-foundation dependency; noted for future, not started |
| **Mode E — domestic next-home owner-occupier** *(new, surfaced 2026-07-04)* | E | unification (done) + `plan.buyer_stage` axis (**done, P0**) + KB (**done, P1**) + blueprint + resolvers (**done, P2**) + multi-blueprint activation (**done, P3**) + shell dispatcher (**done, P4**) + onboarding dispatch (**done, P5**) | none known | **P0–P5 done 2026-07-05 — build-complete.** Axis, 3 KB docs, blueprint draft (`nexthome-domestic-au.md`, fully inlined per-component), engine resolvers, `IN_SCOPE_BLUEPRINTS` activation, the shell dispatcher (Calculator shape-collision fix + OverviewCard tab-surfacing fix), and onboarding dispatch (`base_components/1`'s missing nexthome clause + `blueprint_for/3`'s 3-axis dispatch, fail-closed on both foreign+next-home and a missing `buyer_stage` + the shell's `Onboarding.svelte` gate widened) all landed. See [`mode-e-wedge.md`](mode-e-wedge.md) |

The investor-tax KB that Mode C needed was the same `kb.tax.*` / `kb.investor.*` set [grounding-checklist item 10](../grounding-checklist.md) (full-temporal-flow, T-doc 6) recorded as trigger-gated to "when Mode C ships" — **authored and shipped as part of the Mode-C wedge** (45 KB docs, P1).

---

## What's left (the roadmap SOT — 2026-07-05)

This section is the single forward-looking "what's left" answer. It replaces the overlapping copies that used to live in `grounding-checklist.md` §2/§3 prose, CLAUDE.md's Status paragraph, and `05-roadmap.md` (all now point here instead of re-narrating).

| Item | State | Gate |
|---|---|---|
| **Deploy pass** | Not done | Nothing is in production; env `CLAUDE_CODE_OAUTH_TOKEN` needed for the Q&A sidecar (dev `qa_smoke` green with it set) |
| **Mode B launch** (vs. build, which is done) | Code done, launch blocked | External: VN legal counsel, a money-transfer partner, VN-PDP data-residency capability (strategy §9) |
| **Mode E — domestic next-home owner-occupier** | **Build-complete, P0–P5 done 2026-07-05** | `plan.buyer_stage` axis, 3 KB docs, blueprint draft (`nexthome-domestic-au.md`), engine resolvers (`fh_engine_existing_home_disposal` new + `fh_engine_cash` extended; `mortgage_finance`/`disposition` verified-reused unchanged), `IN_SCOPE_BLUEPRINTS` activation, the shell dispatcher, and onboarding dispatch all landed. P3 also fully inlined 10 previously prose-only components' schemas (a larger-than-expected registry gap) and fixed two real bugs it surfaced (an atom/binary enum mismatch, a scalar/range type mismatch); P4 found + fixed a shape-collision bug (`existing_home_disposal` misread as `disposition` by `Calculator.svelte`'s discriminator) and a tab-surfacing gap (its own card was never reachable via any live tab — `OverviewCard.svelte` extended with a 5th, presence-gated headline tile); P5 found + fixed a missing `base_components/1` clause (the base turn would have silently run without `existing_home_disposal`), corrected its own first design draft mid-phase — `buyer_stage` now fails closed (400 `missing_buyer_stage`) rather than silently defaulting either direction when absent, after a silent-default draft was caught misrouting the Mode-A seam smoke to Mode E — and, building the live seam smoke a second `advisor()` call insisted on, found a real production bug no escript could reach: `plan_cards.mode`'s Postgres CHECK never admitted `'E'` (fixed via new migration `006_mode_e.sql`). `mode_e_seam_smoke.escript` now passes end-to-end against the real sidecar, alongside the other four modes' own seam smokes (re-verified post-migration) — Mode E is genuinely live-verified, not just escript-verified below the seam — see [`mode-e-wedge.md`](mode-e-wedge.md) (scoping decision + full P0–P5 detail) |
| **KB news feature** — surface KB changes (e.g. a scheme cap, a threshold) to the buyer whose plan they affect | **Backend done + live-verified 2026-07-07, shell open** | Compiler (GATE 11, `docs/kb/news/*.md` → `artifact["news"]`), engine (`fh_engine_kb:news_for_slugs/1`, `GET`/`PATCH /api/engine/plan-cards/:id/news`), storage (migration `007_news_dismissed.sql`) all landed and proven end-to-end against Docker PG (`news_smoke.escript`, all assertions pass). Shell rendering (the inline plan-card badge) not started — see [`kb-news-feature.md`](kb-news-feature.md) for the detailed todo list + open design questions |
| **Wedge 1b/1c** — Tìm Nhà curation + browser-extension URL-paste | Not started | Orthogonal track, no mode-foundation dependency |
| Grounding-checklist §2 — F1 (`applicants[]` cross-mode scope), `applicant.*` namespace confirm | Open, non-blocking | Design/verification nits, no trigger |
| Grounding-checklist §3 — F8/F9(data half)/F10 | Deliberately deferred | Trigger-gated: Phase-B property data / KB-confirm |

Per-wedge build detail stays in the mode-X-wedge docs; this table is the only place their *aggregate* status should be summarized going forward.

---

## Topological build order

1. **Identity-layer unification (item 2 deferred half)** — the shared root for B, C, *and* D. No external prereqs. **Done.**
2. **Mode C — domestic investor** — the lowest-dependency *full wedge*: unification + authorable KB + the drafted blueprint. **Zero external blockers. Done.**
3. **Mode B — Vietnam-parent** — code-buildable on the unification, but its *launch* is gated on legal/partnership prerequisites that are not code. **Code done; launch still gated.**
4. **Mode D — foreign investor** — sits on top of both B and C. **Done (2026-07-04).**
5. **Mode E — domestic next-home owner-occupier** — new blueprint, no mode-foundation blockers (unification already covers it). **Done, P0–P5, 2026-07-05.**

All five wedges (unification, C, B-code, D, E) are now closed — the topological order above is history.

**Orthogonal:** Mode A's **Wedge 1b/1c** (Tìm Nhà, URL-paste + extension) don't touch the mode foundation — they activate the Phase-B per-property path and can slot into any point of the sequence on their own track.

---

## Decision — ordering principle = foundationality (2026-06-23)

**Build by dependency order: Mode C before Mode B.** Chosen by Son on 2026-06-23 ("we will proceed with wedges that are more foundational").

**Rationale.** Of the two full wedges unblocked by the shared foundation, Mode C is buildable end-to-end with no external dependencies (no FIRB, no cross-border funding, no VN data-residency review, no legal/partnership prerequisites), whereas Mode B is *code*-buildable but *launch*-gated on work outside the codebase. Building the fully-buildable wedge first maximizes shippable surface and exercises the mode-generic architecture against a genuinely-unlike second instance ([[prove-generality-against-unlike-instances]]) before the regulated cross-border machinery lands.

**This deliberately diverges from the strategy §10 GTM order**, which puts Mode B second for willingness-to-pay and parent cross-sell. That GTM logic is unchanged and still governs *go-to-market*; it is a market-priority argument, not a foundationality one. When Mode B's external prerequisites (VN legal counsel, money-transfer partner, data-residency capability) are in motion, revisit whether GTM should re-assert and pull Mode B forward. **Revisit trigger:** Mode B's external prerequisites begin, or a paying-customer signal makes Vietnam-parent WTP the binding constraint.

**Actual build order superseded this decision in practice (2026-06-23 → 2026-07-04): Mode B was built to completion before Mode D was even opened, i.e. B *and* C both landed, not strictly C-then-B-then-pause; Mode D then landed too (P1–P5, 2026-07-04, plus a grounding fix 2026-07-05).** All three mode-expansion wedges are now build-complete and live-verified; the divergence didn't cost anything (no rework, no regression) because the runtime is genuinely multi-blueprint (item 2) — landing order among already-unblocked wedges was a scheduling choice, not a dependency violation.

**Next call (2026-07-05): Mode E.** With unification, C, B, and D all done, the next foundational-order item is the newly-surfaced **Mode E** gap (domestic next-home owner-occupier — see "What's left" above and `mode-c-wedge.md`'s "Mode-E gap" section). It has no external prerequisites and no mode-foundation blockers (the unification already covers it), so it follows the same foundationality logic that put C before B: build the unblocked, no-external-dependency wedge next. Production deploy and Mode B's launch-gate externals remain deferred behind it (Son, 2026-07-05) — same call as before, just re-affirmed with Mode E added ahead of them.

---

## The first unit — identity-layer unification

Because it crosses the **engine↔shell contract** *and* the **blueprint contract**, the build is **docs-first, one doc at a time, review between** ([[foundation-first-for-cross-contract-reframe]]):

1. **Anchor** — [`fact-model-unification.md`](fact-model-unification.md): promote `off_title_parties[]` / `tax{}` from "canonical-target, Mode-A scalar filling" to the actual generalized schema.
2. **Contracts** — [`engine-contract.md`](engine-contract.md) §9.1 + the §11.9 *read-namespace convention* in [`architecture.md`](architecture.md) (how mode-specific pipelines read the unified fact base).
3. **Conforming artifact** — the blueprint(s) + the compiler gate (run the compiler; structural gates already cover all four blueprints — extend the semantic gates as each mode's content lands).

Split discipline: build the mode-generic **mechanism** now (the unification); author the **wedge's mode content** (Mode-C blueprint fills + investor KB) as part of that wedge — not before its trigger ([[honest-deferral-not-rug]]).

---

## Cross-references

- **GTM order (complementary):** [§10 Build strategy & wedge sequence in 03-strategy.md](../03-strategy.md#10-build-strategy--wedge-sequence); external Wedge-2 prerequisites in [§9](../03-strategy.md).
- **Item status:** [`grounding-checklist.md`](../grounding-checklist.md) — items 1–5 (foundations, all closed), §2/§3 (narrow fact-surface findings only — wedge-level status lives here, not there).
- **The shared foundation:** [`fact-model-unification.md`](fact-model-unification.md) (Decision 1 + the unified schema).
- **The four modes / blueprints:** [`blueprints/investor-domestic-au.md`](../blueprints/investor-domestic-au.md) (C), [`fhb-foreign-au.md`](../blueprints/fhb-foreign-au.md) (B), [`investor-foreign-au.md`](../blueprints/investor-foreign-au.md) (D).
- **The Mode-E gap:** [`mode-c-wedge.md`](mode-c-wedge.md) "Mode-E gap" section (where it was surfaced); [`mode-e-wedge.md`](mode-e-wedge.md) (the durable plan + tracker, opened 2026-07-05).
- **Update mechanics when a mode's content lands:** [`kb-update-runbook.md`](kb-update-runbook.md) (the Phase-0 scope classifier).
