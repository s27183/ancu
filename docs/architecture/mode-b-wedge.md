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
| `[x]` | **Contracts** (2026-06-28) — engine-contract §9.1 `profiles` row flipped to Mode-B-active (`off_title_parties[]`/`funder{}`/`visa_class` populate now, VN-side regulated `funder{}` = placeholder; in-scope-set flip left to P3) + architecture §11.9 new **`off_title.*` namespace** (array projection, read **by role flag**: `eligibility` ← `counts_for_couple_as_one`, `funder{}` consumers `family_context`/`cross_border_funding` ← `funder`) + canonical-slot-reads flipped (Mode B activates cross-border slots + closes F14) |
| `[x]` | **Blueprint conform** (2026-06-28) — Mode B `buyer_profile` outcome `profile_foreign → profile` (canonical, mirrors the Mode-C identity conform): params restructured `au_member`→`applicants[]` (with `visa_class` + `tax{}` foreign lens, `firb_required=true`) and `vn_family_member`→`off_title_parties[]` (role-tagged `funder{expected_to_fund, residence_country, contribution_capacity_aud}` + `counts_for_couple_as_one`); outcome projects `firb_required_any=true` (F14 close) + household financials; conformance note added; `profile_foreign` scrubbed from pipeline diagram + dep graph + input annotations. **Deferred:** downstream precise field reads → P2, AU-side KB → P1, in-scope flip + semantic gates → P3, VN-side `funder{}` regulated content = placeholder. Structural gates green by construction (no renderer/slug/DAG change) |
| `[x]` | **Mode-A retrofit** (2026-06-28, decision (B) — array-is-SOT + derived dyadic read-model) — `profile.off_title_parties[]` is the sole fact base (A's scalar `non_buying_partner` gone); the couple-as-one read binds **per consumer**: funder subset (N) → Erlang array reads (Mode B P2); couple-as-one subset (**dyadic ≤1 by domain law**) → `fh_engine_fill:couple_as_one_view/1` filters by role flag, **enforces ≤1 fail-closed**, projects the flat `non_buying_partner.*` read-model the KB gates read **unchanged**. So the role-flag filter lives in the resolver, the regulated KB predicate language + the 4 NSW/VIC criteria + compiler registry stay **byte-stable**. Mode-B element reconciled to the shared canonical schema (`relationship` union enum + `ownership_history` + `funder`). **Verified:** erlang-checker + rebar3 clean; compiler + validate_build four-mode green; artifact — `off_title_parties` SOT materialized, `non_buying_partner.*` typed singleton intact, `applicant_fields`=13 unchanged; conformance escripts green (`eligibility_benefit` 12/12, `outcome_conformance`, `profile_write`). Edited: both FHB blueprints, architecture §11.9, registry-projection.md, fact-model-unification.md, `fh_engine_fill.erl`, `fh_engine_eligibility.erl`. **Compiler code untouched** (parse_object_entity rejects `array<…>`; inline-typed singleton needs no param) |
| `[x]` | **Compiler gate** (2026-06-28) — satisfied inline during the P0.4 retrofit: recompiled artifact (4 blueprints, 2 in-scope registries); structural gates green over **all** blueprints (Mode B reconciled-element structural-green out-of-scope); slots proven in the in-scope Mode-A registry (`off_title_parties` SOT materialized, `non_buying_partner.*` derived typed singleton intact, `applicant_fields`=13 unchanged; validate_build four-mode PASS). **Mode-B-registry materialization** (its `off_title_parties[]`/`funder`/`visa_class` slots) is structurally gated on the **P3 in-scope flip** — its 42 anchors currently inventory as unbuilt — so that proof rides P3, not P0 |

## P1 — AU-side KB authoring tracker

Status legend (Mode-C convention): `[ ]` not started · `[~]` drafting · `[v]` facts verified vs
primary · `[x]` done (bilingual, in-cluster, compiles when in-scope). Shared-with-Mode-A anchors
(non-italic in the blueprint index — `status-determination`, `established-dwelling-ban`,
suburb/strata/contract/settlement commons) are **already authored**; only the Mode-B-only set below is
new.

**P1-open anchor reconciliation — done (2026-06-28).** Ground truth is the **compiler's gate
surface**, not the index prose: `kb_compiler.py` extracts anchors only from each component's
`**KB anchors:**` line (regex `kb\.[a-z0-9.\-]+`) — it does **not** read the index table and does
**not** expand "All Mode A … anchors" prose. The gate surface is **52 tokens**; **42 have no file** =
the P1 author set, confirmed by the build's own inventory (`[inventory] fhb-foreign-au: 42 unbuilt
anchor(s)`). The 42 map **exactly** onto the clusters below (R 18 + L 8 + X 10 + M 3 + VN 3 = 42); the
**+1 VN parent-tax** placeholder (open-Q #2) is introduced with its cluster, bringing P1 to **43 docs**.
Three divergences were found and dispositioned:
- **Fixed — gate-surface defect.** Component 11's line read "All Mode A anchors **except**
  `kb.land-tax.ppor-exemption`", but the regex captured the excluded slug as a positive anchor
  (passing GATE 2 only because the file exists, while polluting Mode-B's leaf map). Rewrote to drop the
  bare token; the unbuilt count is unchanged (that doc exists).
- **Fixed — index drift (human-doc only; the compiler ignores the index).** Header `42 → 67` (the
  table actually lists 67 distinct slugs after repair); added the 8 component-referenced rows missing
  from the index (the 7 component-5 lender/fx slugs + `established-dwelling-ban`); fixed the
  `kb.refi.windows-and-triggers` → `kb.refinance.windows-and-triggers` typo (Mode A references it
  correctly). Recompiled + `validate_build` four-mode **PASS**; Mode-A/C in-scope registries byte-stable.
- **Tracked as a P3 seam (not a P1 blocker).** Four components declare anchors as "All Mode A …
  anchors + X" prose; the regex captures only the foreign-specific extras and **silently drops the
  inherited shared anchors** from Mode-B's set. The shared docs exist (in scope via Mode A) so P1 is
  unaffected; the P3 in-scope flip must decide whether to expand the literal lists (see Open seams).

### Cluster R — FIRB / regulatory (the centerpiece) — source: FIRB / ATO foreign-investor / Treasury

- [x] `kb.visas.au-temporary-residency-classes` *(R1, 2026-06-28 — pure-ref; per-class catalogue + FIRB/lending signal; status owned by status-determination)*
- [x] `kb.au-temp-residents.banking-and-tax-basics` *(R1, 2026-06-28 — pure-ref; 3 tax-residency categories; tax≠FIRB; Subdiv 768-R; foreign-resident no-threshold/Medicare)*
- [x] `kb.firb.eligible-property-types-foreign-persons` *(R1, 2026-06-28 — pure-ref; positive taxonomy + 4yr vacant-land; complement of established-dwelling-ban)*
- [x] `kb.firb.fee-tiers-by-value` *(R2, 2026-06-28 — pure-ref; owns the banding selection rule (price→band→table), asserts no figure so reindex-immune)*
- [x] `kb.firb.fee-schedule-current` *(R2, 2026-06-28 — pure-ref; owns the dated dollar figures, Schedule of Fees v6 2-Jan-2026 / FY25-26 Table 2; ⚠ 1-July reindex flag + named re-ground obligation (last_verified 3 days before the 2026-27 reindex); est-dwelling 3× off-path)*
- [x] `kb.firb.application-process` *(R2, 2026-06-28 — pure-ref; the spine: notify-before-settle / conditional-contract route, ATO Online Services portal, fee→30-day-clock; references fee/docs/timing/conditions owners, restates none)*
- [x] `kb.firb.documents-required` *(R2, 2026-06-28 — pure-ref; application field checklist; load-bearing FIRB-docs≠bank-AML-source-of-funds separation)*
- [x] `kb.firb.timelines-standard` *(R2, 2026-06-28 — pure-ref; owns the 30-day-from-full-fee decision clock; distinct from R4's approval-validity window (two clocks, single owners))*
- [x] `kb.firb.exemption-certificates-developer` *(R3, 2026-06-28 — pure-ref; developer New/Near-New Dwelling Exemption Certificate path; owns the $3M buyer cap + 50% developer cap; path-selector before application-process)*
- [x] `kb.firb.approval-conditions-typical` *(R3, 2026-06-28 — pure-ref; NON condition catalogue by property type; new=light, vacant=4yr-construction/30-day-evidence/no-disposal; Register of Foreign Ownership; GN6 v4)*
- [x] `kb.firb.penalties-non-compliance` *(R3, 2026-06-28 — pure-ref; REGULATED, figures in penalty units (s4AA dollar value indexes → re-ground flag); criminal 10yr/15,000PU, civil greatest-of value-linked, tiers 12/60/300, self-disclosure→Tier1, disposal orders; GN14 v4; removed-from-reach)*
- [x] `kb.firb.contract-conditional-on-approval` *(R3, 2026-06-28 — pure-ref; STRATEGY — when/why conditional vs approve-then-sign, auction trap; owns route decision; GN6 v4 fn3)*
- [x] `kb.foreign-buyer.subject-to-firb-clauses` *(R3, 2026-06-28 — pure-ref; new foreign-buyer/ namespace; clause ANATOMY — approval-by date/termination/deposit-treatment/good-faith; no drafting)*
- [x] `kb.firb.contract-clauses-required` *(R3, 2026-06-28 — pure-ref; due-diligence pre-signing CHECKLIST; the three contract docs form decide→understand→confirm chain; FIRB-checklist≠bank-AML)*
- [x] `kb.firb.approval-to-settlement-timeline` *(R4, 2026-06-28 — pure-ref; the SECOND FIRB clock (validity 12mo unless Treasurer extends; lapse→fresh application+fee); distinct from timelines-standard's 30-day decision clock; carries the window the OTP-completion trap turns on; GN38 + GN6 v4)*
- [x] `kb.firb.vacancy-fee-rules-2026` *(R4, 2026-06-28 — pure-ref; the REGIME — Part 6A, 183-day/≥30-day-continuous test (short-stay<30d excluded), 12mo vacancy year from right-to-occupy, 30-day return, Register reference; LODGEMENT TRAP (no return→liable regardless); amount application-fee-linked → removed-from-reach (dollars owned by fee-schedule-current); GN6 v4 §J + GN10 v5 §G)*
- [x] `kb.firb.vacancy-fee-double-from-2024` *(R4, 2026-06-28 — pure-ref; owns the MULTIPLIER+cutover (2× on/after 9 Apr 2024, 1× before); non-obvious: keys on VACANCY-YEAR start not purchase → pre-2024 holdings also pay double; multiplier not dollars (reindex-immune, penalty-units split); GN10 v5 §G + Fees Regs s67(2))*
- [x] `kb.off-the-plan.risk-considerations` *(R1, 2026-06-28 — pure-ref; OTP risk catalogue; owns the foreign-person FIRB-window-vs-completion trap; valuation-gap/sunset → building-types, cooling-off → cooling-off.by-state)*

### Cluster L — Non-resident lending — source: lender published policy + APRA (ACL: informational only)

- [x] `kb.lender.non-resident-friendly-shortlist` *(L1, 2026-07-02 — pure-ref; ACL-boundary CRITERIA doc, the Mode-B mirror of investor-friendly-shortlist; 4 machine-checkable ACL flags (decision-support/user-picks/no-named-recommendation/defer-to-broker) + criterion→owner lookup; NO named lenders; rate premium ~50–150bp as CONVENTION band)*
- [x] `kb.lender.temp-resident-lending-policies` *(L1, 2026-07-02 — pure-ref; the foreign-axis HUB-DELTA, analogue of serviceability-basics — owns ONLY what changes for a foreign borrower (foreign-income shading ~20% [range 10–40%], acceptable-currency lists, ~5–10 lender pool, visa tenure), cross-refs serviceability-basics for the unchanged buffer/HEM/DTI; load-bearing axis = AU-income vs foreign-income, not visa label; CONVENTION-flagged, removed-from-reach)*
- [x] `kb.lender.485-visa-treatment` *(L1, 2026-07-02 — pure-ref; the FAVOURABLE branch — 485/student earning AUD in AU assessed near-domestic (up to 80% LVR solo, no foreign shading), 95% + FIRB/surcharge/ban all removed via joint-tenant AU-partner purchase; FIRB/ban facts are REGULATED but cross-ref'd to kb.firb.* owners, not restated)*
- [x] `kb.lender.foreign-buyer-deposit-requirements` *(L1, 2026-07-02 — pure-ref; owns the DEPOSIT/LVR bands only — non-resident 30–40% (LVR 60–70%), temp-AU-income 20%, AU-partner 5%; deposit ≠ total-cash-to-settle (FIRB fee/surcharge/FX owned by cash_position anchors, don't double-count); genuine-savings still applies (lump-sum overseas gift trap))*
- [x] `kb.lender.firb-approval-as-condition-precedent` *(L2, 2026-07-02 — pure-ref; the LOAN-side FIRB gate (parallel to Cluster-R's CONTRACT-side conditional docs): pre-approval before FIRB ∥, offer can be conditional-on-FIRB, but no fund advance/settlement until the No Objection Notification is sighted; approval letter = settlement doc + join to documentation-non-resident; lender behaviours CONVENTION, the approval-before-acquisition requirement REGULATED but owned by kb.firb.*)*
- [x] `kb.lender.documentation-non-resident` *(L2, 2026-07-02 — pure-ref; owns the DOCUMENT PACK + processing timeline (~4–8wk non-resident vs ~2–4wk domestic) only; checklist references owners not duplicates (source-of-funds→au-aml-ctf, FIRB ref→firb-approval-as-condition-precedent, income→temp-resident-lending-policies); source-of-funds + certified-translation = the Mode-B pinch points; CONVENTION)*
- [x] `kb.fx.loan-currency-considerations` *(L2, 2026-07-02 — pure-ref; new fx/ namespace; owns the BOUNDARY — loan is ALWAYS AUD (foreign-currency mortgages no longer offered), so no loan-side FX; risk sits in TWO other places: one-off capital-transfer spread (owned by fx.typical-spreads-vnd-aud, NOT here) + ongoing servicing FX only for foreign-income borrowers (already priced via shading in temp-resident-lending-policies); quotes NO figure)*
- [x] `kb.lmi.calculation-for-foreign-persons` *(L2, 2026-07-02 — pure-ref; split-by-axis vs kb.lmi.calculation (universal premium sizing stays there) — owns only the foreign-person AVAILABILITY delta: LMI mostly UNAVAILABLE to a foreign-income borrower (LVR capped ≤80%, insurers restrict non-resident cover) → lmi_if_lvr_above_80 typically $0; re-enters on AU-income + joint-AU-partner paths (then sized by kb.lmi.calculation); consumed by BOTH component 5 AND cash_position component 6)*

*(**Reconciliation settled at P1-open (2026-07-02):** `kb.lender.serviceability-basics` STAYS the shared keeper of the universal serviceability core (APRA buffer, HEM, DTI, shading, genuine savings) — it already declares itself owner of "the universal framework every lender shares". The Mode-B lending docs own only the **non-resident DELTAS** and cross-ref it; none fold away → all 8 L docs stand. `temp-resident-lending-policies` is the foreign-axis hub-delta.)*

### Cluster X — Cross-border (AU-side), FX, surcharge, non-resident tax — source: ATO + state revenue + provider data

- [x] `kb.foreign-buyer-surcharge.by-state` *(X1, 2026-07-02 — pure-ref, REGULATED per-state (Mode-A land-tax discipline); owns the ONE-OFF duty surcharge rate only — NSW 9% (Jan-2025), VIC 8%, QLD 8% (AFAD, Jul-2024), WA 7%, SA 7%, TAS 8% (FIDS, Jul-2024), ACT/NT none; three-owner split (standard duty→stamp-duty.calc-by-state, annual land-tax surcharge→tax.land-tax-by-state, FIRB fee→firb.fee-schedule-current) so regulatory_imposts_total never double-counts; resolver computes amount=value×rate, postcondition vs state calculator; QLD+TAS rate-history primary-confirmed to effective date)*
- [x] `kb.fx.typical-spreads-vnd-aud` *(X1, 2026-07-02 — pure-ref, CONVENTION; owns the spread MAGNITUDE only (specialist 0.5–1.5%, bank 2.5–4%+, planning default 1.5%); VND managed/less-liquid → wider end; loan carries no FX (loan is AUD); seeds cash_position estimated_fx_spread_percentage + cross_border_funding fx_cost; framework→fx-providers.*, VN process→vn-capital-controls.*; banded, live-quote caveat, never an asserted rate)*
- [x] `kb.fx-providers.wise-ofx-bank-comparison` *(X1, 2026-07-02 — pure-ref, CONVENTION; new fx-providers/ namespace; FX analogue of non-resident-friendly-shortlist tuned to AFSL not ACL — owns the comparison FRAMEWORK (dimensions + rank-by-total-landed-cost rule + crossover: small→flat-%-specialist, large→margin-based) + 6 machine-checkable boundary flags; naming publicly-priced utilities + cost-ranking IS legit decision-support (blueprint enum names wise/ofx/bank_wire_*), boundary = no suitability opinion + no referral fee; spread magnitudes owned by fx.typical-spreads-vnd-aud, not restated)*
- [x] `kb.au-aml-ctf.bank-due-diligence-expectations` *(X2, 2026-07-02 — pure-ref, new au-aml-ctf/ namespace; owns the BANK-side regime + what-to-expect (component 7): the bank/provider is the reporting entity NOT the buyer + NEVER the platform (AUSTRAC never-custodian, architectural); ECDD assumed on a large inbound third-party gift; IFTI reported by the bank for ANY value + TTR for cash ≥A$10k (both bank filings, distinct thresholds, REGULATED vs AUSTRAC primary); pre-engage-bank-before-transfer converts a post-arrival hold into a pre-arrival checklist (bank_pre_engagement_completed); seeds expected_enhanced_due_diligence=true)*
- [x] `kb.au-aml-ctf.source-of-funds-documentation` *(X2, 2026-07-02 — pure-ref; the OWNER firb.documents-required + lender.documentation-non-resident already point to for "source-of-funds"; owns the evidence STANDARDS (component 7 supporting_documents): two-leg paper trail (parent's ORIGIN-of-funds = the under-evidenced pinch point vs the transfer records), document-before-funds-land, genuine-gift-not-loan (repayable = borrowed deposit), certified-translation; category lookup by leg; NOT a FIRB field (AML obligation, separate gate); requirement REGULATED / categories CONVENTION)*
- [x] `kb.cross-border.source-of-funds-letter-template` *(X2, 2026-07-02 — pure-ref, new cross-border/ namespace; owns the letter ANATOMY not drafting (mirrors foreign-buyer.subject-to-firb-clauses) — required-elements lookup (parties+relationship, amount+currency, GENUINE-GIFT clause [the decisive, most-rejected element], source-of-funds, signature/witness); consumed by due_diligence (9) + cross_border_funding (7) source_of_funds_letter_prepared; English + certified translation if VN-signed; use the institution's own template + a registered professional for a stat-dec; CONVENTION)*
- [x] `kb.cross-border-settlement.coordination-best-practices` *(X2, 2026-07-02 — pure-ref, new cross-border-settlement/ namespace; owns the two-country critical-path SEQUENCE + buffer rationale (component 10 currency_transfer_milestones + buffer_days_before_settlement=14): 5-step ordering (FIRB-in-force-through-settlement → VN outbound → transfer-with-buffer → AU ECDD clearance → funds-in-AUD-trust), the two unpredictable legs (VN outbound + AU ECDD) the 14-day buffer is sized for, one-held-leg-defaults-the-contract → milestones tracked as critical path not checklist; each milestone's substance owned elsewhere (FIRB validity/AML/provider/VN), coordination LAYER only; CONVENTION over a REGULATED FIRB-validity dependency it cross-refs not restates)*
- [x] `kb.non-resident-tax.cgt-no-ppor-exemption` *(X3, 2026-07-02 — pure-ref, new non-resident-tax/ namespace; Mode-B disposition SYNTHESIS/pointer feeding ownership_planning (11) cgt_on_eventual_sale_treatment: INVERTS the Mode-A exempt default (foreign resident at disposal → taxable for that period); the two underlying rules single-owned elsewhere, cross-refed not restated (main-residence removal → tax.cgt-main-residence-exemption, discount apportionment → tax.cgt-50-percent-discount); treatment is RESIDENCY-dependent not FIRB-dependent; mode-switch on PR grant restores resident-period exemption/discount; resolver returns to_verify (defers apportionment), never an authored gain; REGULATED (owned elsewhere) + CONVENTION application flags)*
- [x] `kb.non-resident-tax.withholding-on-rental-income` *(X3, 2026-07-02 — pure-ref, REGULATED vs ATO; HONEST-CORRECTS the mis-named blueprint field — directly-held residential rent is NOT a final withholding, taxed BY ASSESSMENT (lodge a return at foreign-resident rates, no tax-free threshold, no Medicare); sets rental_income_withholding_applicable=false-with-note + non_resident_tax_filing_required=true when the property produces income; bracket figures REMOVED FROM REACH (deferred to the return/agent, not asserted); the only real rent-side "withholding" mental-model correction, distinct from the sale-day FRCGW)*
- [x] `kb.non-resident-tax.foreign-resident-cgt-withholding` *(X3, 2026-07-02 — pure-ref, REGULATED vs ATO; owns the SALE-DAY collection MECHANISM (not a separate tax): purchaser withholds 15% of price (up from 12.5%) for contracts on/after 1 Jan 2025, A$750k threshold REMOVED (all property regardless of value), keyed off contract date; a PREPAYMENT credited against the vendor's real CGT on the return (excess refunded), variation notice reduces it up front, clearance certificate is the resident-for-tax exit (reachable after mode-switch); symmetric purchaser-side duty noted; figures deferred; completes the 3-doc foreign-resident lifecycle picture rent→gain→sale-day-collection)*

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

- **Anchor index vs component lists diverge** — ~~reconcile at P1-open~~ **done 2026-06-28** (header
  42→67, 8 missing rows added, `refi→refinance` typo fixed; see the P1-open reconciliation note above).
- **"All Mode A … anchors" prose under-populates Mode-B's anchor set (P3)** — the compiler captures
  only literal `kb.*` tokens, so the 4 prose-inheritance components (`buying_strategy`, `due_diligence`,
  `settlement_prep`, `ownership_planning`) drop their inherited shared anchors from Mode-B's registry.
  Harmless while out-of-scope (the docs exist via Mode A). At the **P3 in-scope flip**, decide: expand
  the literal lists (so Mode-B's registry + leaf-filler map carry the inherited anchors) or accept the
  drop. Verify Mode-B coverage (GATE 7) green either way.
- **`profile_foreign` → `profile` repoint** ripples Mode B's downstream `<from_buyer_profile>` reads;
  reconcile all consumers when P0 conforms the blueprint ([[spec-seams-surface-on-implementation]]).
- **VN-side parent tax** is blueprint open-Q #2 (not yet an anchor) — created as a placeholder in P1.
- **Mode-switch on PR grant** (blueprint open-Q #1) — B→A/C refresh UX; design-first when it triggers.
