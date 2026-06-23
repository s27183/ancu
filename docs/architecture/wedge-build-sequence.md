# Wedge build sequence — the dependency order

> **What this is.** The **build-dependency** view of the remaining wedges: what each one depends on, which external (non-code) prerequisites gate it, and the resulting topological build order. This is a *different lens* on the same wedges that [§10 in 03-strategy.md](../03-strategy.md#10-build-strategy--wedge-sequence) sequences by **go-to-market time** (willingness-to-pay, cross-sell, trust earned). Both orderings are valid; they **diverge** (see the decision below). Per-item status lives in [`grounding-checklist.md`](../grounding-checklist.md) — this doc holds the wedge-level map, not the item detail.
>
> **Audience:** anyone deciding what to build next, or why the build order is what it is.

---

## Two orderings, one wedge set

The same four wedges can be ordered on two independent axes:

| Axis | Lives in | Orders by | Result |
|---|---|---|---|
| **GTM time** | strategy §10 | willingness-to-pay, parent cross-sell, trust earned by the prior wedge | Wedge 1 → 2 (Vietnam-parent) → 3 (investor) → 4 |
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
| **Identity-layer unification (multi-mode)** | **2** | **`[~]` — spec reconciled; build half deferred to "Wedge-2"** |

**Item 2's deferred half is the one open foundation.** Every mode-expansion wedge sits on it. From the checklist, the deferred pieces are: `non_buying_partner → off_title_parties[]`, `tax_residency → tax{}`, the §11.9 *read-namespace convention*, B/D publishing `firb_required_any` (the F14 close), and extending the compiler's **semantic** gates per mode.

---

## Dependency graph of the remaining wedges

| Wedge | Mode | Depends on (code) | External (non-code) prereqs | Buildable to completion now? |
|---|---|---|---|---|
| **Identity-layer unification** | — (foundation) | item 1 (done) only | none | **Yes — the root for B, C, D** |
| **Wedge 3 — domestic investor** | C | unification + investor-tax KB (`kb.tax.*` / `kb.investor.*`, authorable) + extend semantic gates + the drafted `investor-domestic-au` blueprint | **none** — no FIRB, no cross-border | **Yes, fully** |
| **Wedge 2 — Vietnam-parent** | B | unification + `firb_workflow` + `cross_border_funding` + `family_context` | VN legal counsel (day 1), money-transfer partner (pre-launch), VN-PDP data-residency capability — strategy §9 | code-yes, **launch-gated on external** |
| **Wedge 3 — foreign investor** | D | unification **+ Mode C** (investor machinery) **+ Mode B** (FIRB / residency) | all of Mode B's | No — 13-component pipeline sits on both B and C |
| **Wedge 1b / 1c** — Tìm Nhà / URL-paste + extension | A | Wedge 1a (done) + Phase-B addenda activation | 1b: curator ops; 1c: none | Yes — **orthogonal track**, no mode-foundation dependency |
| **Wedge 4 — multi-CALD** | — | everything above | — | No |

The investor-tax KB that Mode C needs is the same `kb.tax.*` / `kb.investor.*` set [grounding-checklist item 10](../grounding-checklist.md) (full-temporal-flow, T-doc 6) records as **trigger-gated to "when Mode C ships."** Authoring it *is* part of the Mode-C wedge.

---

## Topological build order

1. **Identity-layer unification (item 2 deferred half)** — the shared root for B, C, *and* D. No external prereqs.
2. **Mode C — domestic investor** — the lowest-dependency *full wedge*: unification + authorable KB + the drafted blueprint. **Zero external blockers.**
3. **Mode B — Vietnam-parent** — code-buildable on the unification, but its *launch* is gated on legal/partnership prerequisites that are not code.
4. **Mode D — foreign investor** — sits on top of both B and C.
5. **Wedge 4 — multi-CALD** — depends on everything.

**Orthogonal:** Mode A's **Wedge 1b/1c** (Tìm Nhà, URL-paste + extension) don't touch the mode foundation — they activate the Phase-B per-property path and can slot into any point of the sequence on their own track.

---

## Decision — ordering principle = foundationality (2026-06-23)

**Build by dependency order: Mode C before Mode B.** Chosen by Son on 2026-06-23 ("we will proceed with wedges that are more foundational").

**Rationale.** Of the two full wedges unblocked by the shared foundation, Mode C is buildable end-to-end with no external dependencies (no FIRB, no cross-border funding, no VN data-residency review, no legal/partnership prerequisites), whereas Mode B is *code*-buildable but *launch*-gated on work outside the codebase. Building the fully-buildable wedge first maximizes shippable surface and exercises the mode-generic architecture against a genuinely-unlike second instance ([[prove-generality-against-unlike-instances]]) before the regulated cross-border machinery lands.

**This deliberately diverges from the strategy §10 GTM order**, which puts Mode B second for willingness-to-pay and parent cross-sell. That GTM logic is unchanged and still governs *go-to-market*; it is a market-priority argument, not a foundationality one. When Mode B's external prerequisites (VN legal counsel, money-transfer partner, data-residency capability) are in motion, revisit whether GTM should re-assert and pull Mode B forward. **Revisit trigger:** Mode B's external prerequisites begin, or a paying-customer signal makes Vietnam-parent WTP the binding constraint.

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
- **Item status:** [`grounding-checklist.md`](../grounding-checklist.md) — items 1–5 (foundations), item 2 (the open foundation), item 10 (investor-tax KB trigger).
- **The shared foundation:** [`fact-model-unification.md`](fact-model-unification.md) (Decision 1 + the unified schema).
- **The four modes / blueprints:** [`blueprints/investor-domestic-au.md`](../blueprints/investor-domestic-au.md) (C), [`fhb-foreign-au.md`](../blueprints/fhb-foreign-au.md) (B), [`investor-foreign-au.md`](../blueprints/investor-foreign-au.md) (D).
- **Update mechanics when a mode's content lands:** [`kb-update-runbook.md`](kb-update-runbook.md) (the Phase-0 scope classifier).
