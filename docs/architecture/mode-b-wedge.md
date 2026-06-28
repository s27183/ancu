# Mode-B wedge — build plan + progress tracker

**Status: planning (authoring not started). Opened 2026-06-28.** This doc is the durable plan
*and* the task tracker for the Mode-B (Vietnam-parent-funded / AU-temp-resident foreign-person FHB)
wedge. The Claude Code Task list is ephemeral (it does not survive compaction); this file is the
source of truth for "what's left." The grounding-checklist carries a one-line pointer here.

Anchor / upstream: [`fact-model-unification.md`](fact-model-unification.md) (the deferred Mode-B
slots — `off_title_parties[]`, `visa_class`, off-title `funder{}`, the F14 close),
[`wedge-build-sequence.md`](wedge-build-sequence.md) (Mode B = the next foundation layer; unblocks
Mode D), [`mode-c-wedge.md`](mode-c-wedge.md) (the precedent this wedge mirrors — phasing, the
multi-blueprint runtime it reuses), [`engine-contract.md`](engine-contract.md) §9.1,
[`architecture.md`](architecture.md) §11.9. Conforming artifact:
[`../blueprints/fhb-foreign-au.md`](../blueprints/fhb-foreign-au.md).

## What's already done (the foundation the Mode-C wedge laid)

Mode B is **much cheaper than Mode C was** — three Mode-C deliverables carry straight over:

1. **The unification mechanism (A+C)** — one `profile.*` fact base, mode derived,
   `derived.firb_required_any` the single household FIRB aggregate, the canonical-slot-alias read
   convention. Mode B's `buyer_profile` repoints its legacy `profile_foreign` outcome onto the
   canonical `profile` (foreign lens), exactly as Mode C conformed `investor_profile_summary → profile`.
2. **The deferred fact-model slots are Mode B's to exercise.** `off_title_parties[]` (Mode A's scalar
   `non_buying_partner` → array; the VN funder is its second element), `visa_class`, off-title
   `funder{}`, and the **F14 close** (B publishes `firb_required_any = true` definitionally). Mode B is
   their **first-exercising instance**, so building them now is honest, not speculative
   ([[honest-deferral-not-rug]]) — and the same slots unblock Mode D.
3. **The multi-blueprint runtime (Mode-C P3)** — the compiler emits an in-scope **set**, a registry
   **per** in-scope blueprint (`blueprints[slug].registry`); the turn DAG + Layer-1/Layer-2 gates
   select by the card's `blueprint_slug`. Activating Mode B = adding `fhb-foreign-au` to
   `IN_SCOPE_BLUEPRINTS` + prove-selection, **not** new machinery. Mode-C's renderer precedent
   (`buying-strategy-card`, `opportunity-card` as Svelte component + dispatcher branch off an already
   §11.9-authored enum row) is the template for Mode B's two new renderers.

So this wedge is **fact-model activation + AU-side content + 2 renderers + activation**, sitting on a
built runtime.

## The load-bearing scoping decision — AU-side full, VN-side labelled placeholder (2026-06-28)

**Son's call (2026-06-28):** build the **full AU side** of Mode B now; make the **VN-side regulated
content a labelled placeholder**. Rationale: a Vietnam-parent-funded purchase is, to the buyer, an
**Australian property problem** — FIRB, AU lending, AU duty/surcharge, the AU purchase process — which
is where our authority and data are. The VN remittance side (SBV capital controls, VN PDP, VN-side
parent tax) is the buyer's own to run; we signpost it and fill in the detail later when we have data.

This is the wedge's defining decision and it **dissolves the launch-gate**: the only counsel-gated
content in Mode B was the VN side (strategy §9 — VN legal counsel). Making it a placeholder means the
full AU-side Mode B is buildable now with no counsel in the loop.

**The split, concretely (against the blueprint's anchors):**

| Side | Anchors | Treatment |
|---|---|---|
| **AU — full build** | all `kb.firb.*`, `kb.foreign-buyer*`, `kb.lender.*` (non-resident), `kb.non-resident-tax.*`, `kb.au-aml-ctf.*`, `kb.fx*` (provider/spread — AU-observable), `kb.lmi.*`, family/cultural | Regulated, primary-verified, resolver-computed + removed-from-reach, bilingual {vi,en} |
| **VN — labelled placeholder** | `kb.vn-capital-controls.sbv-thresholds-2026`, `kb.vn-capital-controls.declared-purpose-categories`, `kb.vn-pdp.cross-border-data-transfer`, *(VN-side parent tax — not yet an anchor)* | Structural placeholder: ⚠ banner + `is_placeholder` + named re-ground obligation + **bilingual buyer-pointer copy** ("handle the VN side with your VN bank / SBV"); surfaces PENDING, fabricates no threshold |

In `cross_border_funding`, the `vn_capital_control_compliance` block is placeholder-backed while the
**AU-facing half stays real** (FX provider comparison, AU AML/CTF source-of-funds, transfer
timing/milestones). The placeholder follows the project's FIFTH honesty move ([[kb-doc-authoring]],
[[honest-deferral-not-rug]]): structure built now, the genuinely-unsourced datum marked pending with
a named re-ground obligation — not omitted (the buyer still gets a VN-side signpost) and not faked.

## The regulated design concern — FIRB misadvice + cross-border

Mode B carries the product's highest cross-jurisdiction harm surface. Discipline for the whole wedge:

- **The established-dwelling ban is a hard gate, not a disclaimer** (constraint 10). Foreign persons
  cannot buy established dwellings 1 Apr 2025 – 30 Jun 2029. `firb_workflow.foreign_person_eligible`
  is **resolver-derived from the KB ban window** (self-expires; not hardcoded), and
  `blocking_for_contract` gates `buying_strategy` / `settlement_prep` in the engine, not in copy.
- **Regulated figures removed from the LLM's reach.** FIRB fee tiers, foreign-buyer surcharge %,
  vacancy fee, non-resident CGT/withholding rates are KB-grounded, resolver-computed, verified vs the
  primary source (ATO foreign-investor, state revenue offices). [[verify-regulated-figures-by-postcondition]].
- **ASIC/credit line held.** Non-resident lender content surfaces *criteria* + "consult a licensed
  broker"; never a named-lender recommendation crossing into credit advice (the Mode-C ACL pattern).
- **Bilingual {vi,en} at the source** ([[bilingual-first-class-engine-output]]); Mode B's
  `language_primary` is `vi`.

## The fail-closed activation rule (inherited from Mode-C P3)

Adding `fhb-foreign-au` to `IN_SCOPE_BLUEPRINTS` is **all-or-nothing**: its semantic gates (GATE 2
anchor-resolution, GATE 6 reference-integrity, GATE 7 coverage) demand *every* anchor resolve at once.
KB docs land in clusters while Mode B stays out-of-scope; the add happens only after all AU-side docs
are authored **and** the VN placeholders exist (a placeholder is a real resolvable doc — pure-ref
`fills: []` — so it satisfies the gate). **This is an addition, not a replacement** — the runtime is
multi-blueprint; activating Mode B never dormants Mode A or C. Onboarding dispatch (which makes Mode B
user-selectable) is **atomic-last** — after the add greens *and* the two new renderers exist — or a
foreign-person onboarding hits a missing blueprint or a blank renderer slot.

## Phase order

Mirrors Mode C, with a **P0 fact-model phase first** (the foundational piece — the deferred slots —
that the rest of Mode B reads).

- **P0 — Fact-model generalizations.** The deferred unification slots, docs-first (cross-contract):
  anchor (`fact-model-unification.md` — a "Mode-B activation" section parallel to "Mode-C activation")
  → contracts (engine-contract §9.1, architecture §11.9) → blueprint conform (Mode B `buyer_profile`
  → canonical `profile`; Mode A `non_buying_partner → off_title_parties[]` **retrofit**) → compiler
  gate. **Retrofit Mode A now** (Son, 2026-06-28): one shape across modes, A's single party = the
  array head, jsonb-additive (no migration); re-verify A's `eligibility` couple-as-one read against
  the array. F14: B publishes `firb_required_any`.
- **P1 — AU-side regulated KB** (clusters R → L → X → M below). One cluster per turn, each fact
  verified vs its primary source, ASIC/FIRB-framed. **VN-side ~3 anchors → labelled placeholders.**
  Commit as the foundation.
- **P2 — Engine resolvers.** `firb_workflow` (new — the FIRB fee/state-machine/eligibility resolver,
  the Mode-A `eligibility` analog), `mortgage_finance` foreign variant, `cash_position` foreign
  variant, `ownership_planning` foreign variant — each verified in isolation via a conformance escript
  against its KB (the Mode-C P5-engine rhythm). Regulated figures resolver-computed + removed-from-reach.
- **P3 — Multi-blueprint activation.** Add `fhb-foreign-au` to `IN_SCOPE_BLUEPRINTS`; green its
  semantic gates; re-emit artifact; **prove per-card selection** (Mode A/C registries unchanged, no
  regression). The machinery exists (Mode-C P3) — this is the flip + proof.
- **P4 — Shell renderers.** 2 net-new to the shell: `family-view-card`, `firb-workflow-card` (enum +
  §11.9 rows already authored with the blueprint) → Svelte component + dispatcher branch. Plus the
  Family-view and FIRB&Funding tabs (already declared in the blueprint's `ui_tabs`, dormant).
- **P5 — Mode-B base engine + onboarding activation (atomic-last).** The foreign-person base spine
  (`?BASE_COMPONENTS_FOREIGN` per-blueprint `base_components/1` sequence) **+** onboarding dispatch
  (`fh_engine_h_plan_cards:blueprint_for/1` selects `fhb-foreign-au` by foreign-person + intent) **+**
  the onboarding visa/foreign-person picker — landing **together** once the base turn computes
  end-to-end. Closes the foreign branch logged at Mode-C P5-activate ("Mode-E next-home gap").

## P0 — fact-model generalizations tracker

| Status | Item |
|---|---|
| `[x]` | **Anchor** — `fact-model-unification.md` "Mode-B activation" section (2026-06-28): `off_title_parties[]`, `funder{}`, `visa_class`, F14 → active; VN-side `funder{}` regulated content = placeholder; Mode-A retrofit bound to now; top status line updated (both triggers fired) |
| `[ ]` | **Contracts** — engine-contract §9.1 (`facts_jsonb` adds the slots, no migration) + architecture §11.9 (off-title read convention; `funder{}` consumer = `family_context`/`cross_border_funding`) |
| `[ ]` | **Blueprint conform** — Mode B `buyer_profile` `profile_foreign → profile` (foreign lens: `applicants[]` AU member, `off_title_parties[]` VN funder, per-applicant `tax{}`, `derived.firb_required_any=true`) |
| `[ ]` | **Mode-A retrofit** — `non_buying_partner → off_title_parties[]` (A's single party = head element); re-verify `eligibility` couple-as-one read; conformance escript green, artifact diff reviewed |
| `[ ]` | **Compiler gate** — recompile; structural gates green over all blueprints; prove the slots materialize in the registry |

## P1 — AU-side KB authoring tracker

Status legend (Mode-C convention): `[ ]` not started · `[~]` drafting · `[v]` facts verified vs
primary · `[x]` done (bilingual, in-cluster, compiles when in-scope). **Counts are provisional** — the
blueprint's component-level anchor lists and its index table diverge (e.g. component 5's
`kb.lender.non-resident-*` slugs are not all in the 42-slug index); a **P1-opening anchor
reconciliation** pins the exact set first (the Mode-C precedent: 47 → 45 after seam reconciliation).
Shared-with-Mode-A anchors (non-italic in the blueprint index — `status-determination`,
`established-dwelling-ban`, suburb/strata/contract/settlement commons) are **already authored**; only
the Mode-B-only set below is new.

### Cluster R — FIRB / regulatory (the centerpiece) — source: FIRB / ATO foreign-investor / Treasury

- [ ] `kb.visas.au-temporary-residency-classes`
- [ ] `kb.au-temp-residents.banking-and-tax-basics`
- [ ] `kb.firb.eligible-property-types-foreign-persons`
- [ ] `kb.firb.fee-tiers-by-value`
- [ ] `kb.firb.fee-schedule-current`
- [ ] `kb.firb.application-process`
- [ ] `kb.firb.documents-required`
- [ ] `kb.firb.timelines-standard`
- [ ] `kb.firb.exemption-certificates-developer`
- [ ] `kb.firb.approval-conditions-typical`
- [ ] `kb.firb.penalties-non-compliance`
- [ ] `kb.firb.contract-conditional-on-approval`
- [ ] `kb.foreign-buyer.subject-to-firb-clauses`
- [ ] `kb.firb.contract-clauses-required`
- [ ] `kb.firb.approval-to-settlement-timeline`
- [ ] `kb.firb.vacancy-fee-rules-2026`
- [ ] `kb.firb.vacancy-fee-double-from-2024`
- [ ] `kb.off-the-plan.risk-considerations`

### Cluster L — Non-resident lending — source: lender published policy + APRA (ACL: informational only)

- [ ] `kb.lender.non-resident-friendly-shortlist` *(criteria, not a named-lender recommendation)*
- [ ] `kb.lender.temp-resident-lending-policies`
- [ ] `kb.lender.485-visa-treatment`
- [ ] `kb.lender.foreign-buyer-deposit-requirements`
- [ ] `kb.lender.firb-approval-as-condition-precedent`
- [ ] `kb.lender.documentation-non-resident`
- [ ] `kb.fx.loan-currency-considerations`
- [ ] `kb.lmi.calculation-for-foreign-persons`

*(Reconcile against the index at P1-open; the Mode-A `kb.lender.serviceability-basics` may be the shared keeper for the serviceability core.)*

### Cluster X — Cross-border (AU-side), FX, surcharge, non-resident tax — source: ATO + state revenue + provider data

- [ ] `kb.foreign-buyer-surcharge.by-state` *(regulated, per-state — the Mode-A land-tax discipline)*
- [ ] `kb.fx.typical-spreads-vnd-aud`
- [ ] `kb.fx-providers.wise-ofx-bank-comparison`
- [ ] `kb.au-aml-ctf.bank-due-diligence-expectations`
- [ ] `kb.au-aml-ctf.source-of-funds-documentation`
- [ ] `kb.cross-border.source-of-funds-letter-template`
- [ ] `kb.cross-border-settlement.coordination-best-practices`
- [ ] `kb.non-resident-tax.cgt-no-ppor-exemption`
- [ ] `kb.non-resident-tax.withholding-on-rental-income`
- [ ] `kb.non-resident-tax.foreign-resident-cgt-withholding`

### Cluster M — Family / cultural coordination — source: reference / behavioural (decision-support framed)

- [ ] `kb.vietnamese-family.financial-patterns`
- [ ] `kb.cross-border.decision-authority-cultural`
- [ ] `kb.bilingual.coordination-norms`

### VN-side — labelled placeholders (structure now, datum pending; buyer-pointer copy)

- [ ] `kb.vn-capital-controls.sbv-thresholds-2026` — ⚠ placeholder + buyer pointer (SBV / VN bank)
- [ ] `kb.vn-capital-controls.declared-purpose-categories` — ⚠ placeholder + buyer pointer
- [ ] `kb.vn-pdp.cross-border-data-transfer` — ⚠ placeholder + named re-ground obligation
- [ ] *(VN-side parent tax — new placeholder anchor; blueprint open-Q #2)*

## P2–P5 — engine + shell tracker

| Status | Phase | Item |
|---|---|---|
| [ ] | P2 | `firb_workflow` resolver (new module) — eligibility from the KB ban window, fee tier from value, state machine; `blocking_for_contract` gate; conformance escript vs KB |
| [ ] | P2 | `mortgage_finance` foreign variant (branch the shared resolver) — non-resident serviceability, 30%+ deposit, FIRB-as-condition-precedent |
| [ ] | P2 | `cash_position` foreign variant — foreign-buyer surcharge + FIRB fee + FX + no-scheme; `regulatory_imposts_total` / `channel_costs_total` split |
| [ ] | P2 | `ownership_planning` foreign variant — vacancy fee + non-resident tax; `mode_switch_eligible` on PR grant |
| [ ] | P2 | `family_context` + `cross_border_funding` (AU-half real, VN-half placeholder-backed) |
| [ ] | P3 | Add `fhb-foreign-au` to `IN_SCOPE_BLUEPRINTS`; green semantic gates; re-emit artifact; prove per-card selection (A/C unchanged) |
| [ ] | P4 | Shell renderer: `family-view-card` (Svelte component + dispatcher branch) |
| [ ] | P4 | Shell renderer: `firb-workflow-card` (Svelte component + dispatcher branch) |
| [ ] | P5 | `?BASE_COMPONENTS_FOREIGN` per-blueprint `base_components/1` sequence + DAG-walk conformance |
| [ ] | P5 | Onboarding dispatch (`blueprint_for/1` selects `fhb-foreign-au` by foreign-person + intent) + onboarding foreign-person/visa picker — **atomic-last** |

## Open seams (surface-and-track, reconcile in-phase)

- **Anchor index vs component lists diverge** — reconcile at P1-open (count + the lender slugs).
- **`profile_foreign` → `profile` repoint** ripples Mode B's downstream `<from_buyer_profile>` reads;
  reconcile all consumers when P0 conforms the blueprint ([[spec-seams-surface-on-implementation]]).
- **VN-side parent tax** is blueprint open-Q #2 (not yet an anchor) — created as a placeholder in P1.
- **Mode-switch on PR grant** (blueprint open-Q #1) — B→A/C refresh UX; design-first when it triggers.
