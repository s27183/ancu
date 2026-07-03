# Mode-D wedge — build plan + progress tracker

**Status: planning (authoring not started). Opened 2026-07-03.** This doc is the durable plan
*and* the task tracker for the Mode-D (Vietnam-located foreign investor) wedge. The Claude Code
Task list is ephemeral (it does not survive compaction); this file is the source of truth for
"what's left." The grounding-checklist carries a one-line pointer here.

Anchor / upstream: [`fact-model-unification.md`](fact-model-unification.md) ("Mode D adds no new
identity-layer generalization — it reuses B's `funder{}`/`off_title_parties[]` + C's
`existing_portfolio`/`tax{}`, content only"), [`wedge-build-sequence.md`](wedge-build-sequence.md)
(Mode D sits on top of both B and C — both now built, so Mode D is the next genuinely-unblocked
foundational wedge), [`mode-b-wedge.md`](mode-b-wedge.md) + [`mode-c-wedge.md`](mode-c-wedge.md)
(the two precedents this wedge combines — phasing, the multi-blueprint runtime, the resolver
branch-on-discriminator pattern), [`engine-contract.md`](engine-contract.md) §9.1,
[`architecture.md`](architecture.md) §11.9. Conforming artifact:
[`../blueprints/investor-foreign-au.md`](../blueprints/investor-foreign-au.md) (14 components, the
deepest pipeline of the four blueprints — combines Mode B's foreign-person regime with Mode C's
investor reasoning, plus ~10 Mode-D-exclusive non-resident-tax/FRCGW/treaty anchors).

## What's already done (the foundation Mode D inherits from both B and C)

Mode D is **structurally the cheapest of the three post-Mode-A wedges** — it is the only one that
adds *zero* new identity-layer generalization (confirmed in `fact-model-unification.md`: "Mode D
adds no new identity-layer generalization… only content"). Everything foundational it needs already
exists, built by B and C:

1. **The unification mechanism (A+B+C)** — canonical `profile.*`, `off_title_parties[]` +
   per-party `funder{}` + `visa_class` (Mode B), `tax{}` + `existing_portfolio` + `traits` (Mode C).
   `investor_profile_foreign` (component 1) is a straight *merge* of Mode B's `buyer_profile`
   foreign lens and Mode C's `investor_profile` — no new schema.
2. **The multi-blueprint runtime (Mode-C P3)** — `IN_SCOPE_BLUEPRINTS` is already a set
   (`{fhb-domestic-au, investor-domestic-au, fhb-foreign-au}` — verified in
   `engine/build/kb_compiler.py:70`); the turn DAG + Layer-1/Layer-2 gates already select by
   `blueprint_slug`. Adding `investor-foreign-au` is the same add-and-prove-selection move done
   twice already, not new machinery.
3. **Direct resolver reuse, not new modules, for 3 of 14 components:**
   - `firb_workflow` (component 3) — "from Mode B — mandatory." Same eligibility/fee-tier/
     state-machine logic; Mode D's `firb_status` outcome needs checking against Mode B's shape
     (likely identical or a thin superset).
   - `cross_border_funding` (component 9) — "from Mode B." Same transfer/FX/AML resolver,
     including its **already-placeholder** VN capital-control (SBV/PDP) content — no new decision
     needed there (see the scoping decision below).
   - The Mode-C `disposition` two-path dispatch pattern
     (`fh_engine_disposition:fill/2` branches on `tax_optimised_structure` presence →
     `fill_owner_occupier/2` vs `fill_investor/4`) is the direct template for a **third branch**
     Mode D needs (foreign-resident CGT: no 50% discount, no PPOR exemption, + FRCGW). Same for the
     `cash_position` / `mortgage_finance` shared-name discriminator-branch pattern (both modules
     already branch FHB-domestic / FHB-foreign / investor-domestic on upstream discriminators — Mode
     D adds a 4th combinatorial branch, not a new mechanism).
4. **Zero net-new shell renderers.** Cross-checking the blueprint's renderer table against the
   already-built vocabulary: `summary-card`, `firb-workflow-card`, `calculator`, `data-table`,
   `buying-strategy-card`, `risk-flag-list`, `checklist`, `swimlane-diagram`, `opportunity-card` —
   **every one of these 9 renderers already has a Svelte component**, built for Mode A/B/C. P4 is
   dispatcher-branch-only (new outcome *shapes* — `investor_profile_foreign_summary`,
   `tax_structure_non_resident_summary`, `portfolio_position_foreign` — feeding existing components),
   not new component authoring.
5. **~77 of Mode D's ~87 KB anchors already exist** (35 shared with Mode B, 40 shared with Mode C, 2
   shared with Mode A). Only **~10 are Mode-D-exclusive** (see P1 below) — the smallest net-new KB
   surface of any wedge so far (Mode B authored ~32 AU-side + 3 VN placeholders from a much smaller
   reuse base; Mode C authored all 45 from a cold start).

So this wedge is **~10 KB docs + resolver reuse/branching + activation** — genuinely the smallest of
the three, sitting on two already-built runtimes.

## The load-bearing scoping decision — AU-side full, VN-side placeholder, same split as Mode B (Son, 2026-07-03)

**Son's call:** VN-resident investors care about what they owe **in Australia** — they retain their
own VN-based lawyers/tax advisors to handle VN-side filing and treaty matters. So Mode D takes the
**same split as Mode B**: build the AU-side content in full; the VN-side tax content is a labelled
placeholder, not a regulated build.

This **overturns my earlier recommendation** (below, for the record) that VN-tax content should be a
full build because it's a first-order input to the tax_structure recommendation. Son's correction: the
*recommendation itself* is still fully AU-side — non-resident CGT rules, no PPOR exemption, no 50%
discount, FRCGW withheld at settlement, non-resident withholding on rental income — all resolver-computed,
KB-grounded, AU-primary-sourced, exactly as scoped originally. What the VN-tax cluster would have added
is the buyer's *downstream* VN-side liability on top of that AU figure — genuinely a separate
jurisdiction's tax return, which is exactly the "their own lawyer" boundary. **Reclassified:**
`kb.vn-tax.brackets-2026`, `kb.vn-tax.income-from-foreign-property`, `kb.au-vn-tax-treaty` move from
Cluster FI (regulated build) to the **VN-side placeholder section** in P1 below — structure now
(⚠ banner + `is_placeholder` + bilingual buyer-pointer to "consult your VN-based tax advisor"), no
VN primary-source verification work. This also removes the one open scoping decision that was blocking
P1 — **P1 can start.**

*(My original recommendation, superseded above, is left here for the record rather than deleted: VN
tax liability on AU-sourced income is a first-order input to the investor's *total* return, so a
placeholder there is honest-deferral not a rug **only** because Son has now explicitly named the VN
lawyer as the channel that closes it — same discipline as any labelled placeholder,
[[honest-deferral-not-rug]].)*

## The regulated design concern — Mode B's + Mode C's, scoped to AU only

Mode D carries Mode B's FIRB/cross-border harm surface and Mode C's ASIC/tax-advice line at once, both
entirely on the AU side per the scoping decision above. Discipline for the whole wedge:

- **Everything from `mode-b-wedge.md`'s regulated concern** (established-dwelling ban as a hard
  resolver gate not a disclaimer; FIRB fee/surcharge/vacancy-fee figures resolver-computed and
  removed from the LLM's reach; ACL line held on non-resident lender content).
- **Everything from `mode-c-wedge.md`'s regulated concern** (decision-support only on entity
  structuring — never "set up a trust"; 50%-discount/land-tax/depreciation figures resolver-computed
  and verified against ATO/state-revenue primaries).
- **The AU-VN DTA's *AU-side* consequence stays in scope where it changes an AU figure** — e.g. if the
  treaty modifies an AU withholding rate on rental income or FRCGW for a VN-tax-resident, that's an AU
  withholding rule and belongs in the AU-side non-resident-tax cluster (verify at authoring time whether
  it actually changes the computation before adding content for it — don't assume a treaty effect that
  isn't there). Anything about how VN *itself* taxes the income stays out (their lawyer's job).
- **Bilingual {vi,en} at the source**, `language_primary: vi` (Mode D's audience is entirely
  Vietnam-located — more bilingual-load-bearing than Mode B's mixed AU/VN household).

## The fail-closed activation rule (inherited from Mode-C P3 / Mode-B P3)

Adding `investor-foreign-au` to `IN_SCOPE_BLUEPRINTS` is **all-or-nothing**: GATE 2/6/7 demand every
anchor resolve at once. KB docs land in clusters while Mode D stays out-of-scope; the add happens only
after all ~10 exclusive docs are authored (the ~77 reused anchors already resolve — they're already
in-scope via B and C). **Addition, not replacement** — activating Mode D never dormants A, B, or C.
Onboarding dispatch is **atomic-last** — after the add greens *and* the per-blueprint `base_components/1`
sequence computes end-to-end — or a foreign-investor onboarding hits a half-built turn.

## Phase order

Mirrors Mode B/C, compressed — no P0 fact-model phase (nothing to generalize; see above).

- **P1 — Mode-D-exclusive KB.** The AU-side regulated cluster (Cluster FI, the real authoring work) +
  the 3 VN-side labelled placeholders (cheap — structure + buyer-pointer copy, no VN primary-source
  work, per the scoping decision above) + an **anchor-index reconciliation** (the blueprint's own
  "~77"/"~87" counts are provisional, same caveat Mode B and C both hit at P1-open — pin the exact set
  first).
- **P2 — Engine resolvers**, in DAG order, reusing the branch-on-discriminator pattern throughout:
  `investor_profile_foreign` (merge of two existing fills — cheapest resolver in the suite),
  `firb_workflow` (direct reuse — confirm outcome-shape compatibility, no new logic expected),
  `investment_strategy` foreign-investor variant (new agent-leaf domain, mirrors Mode C's
  `investment_thesis`), `mortgage_finance` non-resident-investor branch (3rd/4th branch on the
  existing shared module), `yield_modelling` non-resident-tax-aware variant, `tax_structure_non_resident`
  ★ (new two-path component — the most regulated surface in the wedge, combines Mode C's
  entity-structuring agent leaf with non-resident CGT/FRCGW constants), `cash_position` foreign+investor
  branch (4th branch), `cross_border_funding` (direct reuse, no changes), `ownership_planning_foreign_investor`
  ★ (new sibling module, mirrors Mode C's `ownership_planning_investor`), `disposition` foreign-resident
  branch (3rd branch in `fh_engine_disposition` — no discount, no PPOR exemption, FRCGW withheld at
  settlement, modelled inside CGT with no double-count per the blueprint's own instruction). Each
  verified in isolation via a conformance escript against its KB, the Mode-B/C P2 rhythm.
- **P3 — Multi-blueprint activation.** Add `investor-foreign-au` to `IN_SCOPE_BLUEPRINTS` (now a
  4-member set); green semantic gates; re-emit artifact; prove per-card selection across all four
  registries, no regression on A/B/C.
- **P4 — Shell dispatcher branches.** Per the "zero net-new renderers" finding above: extend the
  existing `ComponentCard.svelte` dispatchers to route the 4 new outcome shapes into their (already-built)
  renderer components. No new `.svelte` files expected unless an outcome shape genuinely doesn't fit
  an existing component's props (check at P4-open, don't assume).
- **P5 — Mode-D base engine + onboarding activation (atomic-last).** `?BASE_COMPONENTS_FOREIGN_INVESTOR`
  per-blueprint `base_components/1` sequence + onboarding dispatch (`blueprint_for/1` selects
  `investor-foreign-au` by foreign-person **AND** investor intent — the one truly new dispatch
  predicate, since B dispatches on foreign-person alone and C on investor-intent alone) + the
  onboarding foreign-investor picker, landing together.

## P1 — Mode-D-exclusive KB authoring tracker

Status legend (Mode-B/C convention): `[ ]` not started · `[~]` drafting · `[v]` facts verified vs
primary · `[x]` done (bilingual, in-cluster, compiles when in-scope). **Provisional** — the blueprint's
"~77 reused / ~10 exclusive" split needs a P1-opening reconciliation pass against the live 3-blueprint
artifact (same caveat every prior wedge's P1-open hit).

### Cluster FI — Foreign-investor-specific (non-resident AU tax + strategy) — source: ATO foreign-investor + FIRB

- [ ] `kb.non-resident.serviceability-au-lenders`
- [ ] `kb.non-resident.rental-income-withholding-tax`
- [ ] `kb.non-resident.cgt-no-50-percent-discount-from-2012`
- [ ] `kb.non-resident.cgt-no-ppor-exemption`
- [ ] `kb.non-resident.entity-options-au-property`
- [ ] `kb.non-resident.investment-loan-deposit-requirements`
- [ ] `kb.foreign-investor.thesis-archetypes`
- [ ] `kb.foreign-investor.currency-hedging-considerations`
- [ ] `kb.foreign-investor.future-migration-pathway-considerations`
- [ ] `kb.foreign-investor.repatriation-strategy`
- [ ] `kb.foreign-investor.frcgw-on-sale`
- [ ] `kb.foreign-investor.absentee-owner-management`

*(Reconcile against the blueprint's KB anchor index summary + the component-level anchor lists at
P1-open — the Mode-B/C precedent found these diverge slightly on first pass.)*

### VN-side — labelled placeholders (structure now, datum pending; buyer-pointer copy)

Mirrors Mode B's VN-side treatment exactly (`kb-doc-authoring`'s fifth honesty move): structure built,
the genuinely-VN-side datum marked pending, bilingual copy points the buyer to their own VN-based tax
advisor. No GDT-Vietnam or DTA primary-source verification work — that's explicitly out of scope per
the 2026-07-03 scoping decision above.

- [ ] `kb.vn-tax.brackets-2026` — ⚠ placeholder + buyer pointer ("consult your VN-based tax advisor")
- [ ] `kb.vn-tax.income-from-foreign-property` — ⚠ placeholder + buyer pointer
- [ ] `kb.au-vn-tax-treaty` — ⚠ placeholder, **except** any AU-side withholding-rate effect discovered
  while authoring Cluster FI's non-resident withholding docs — that piece is AU-side and belongs there,
  not here (verify whether the treaty actually changes an AU figure before assuming it does)

## P2–P5 — engine + shell tracker

| Status | Phase | Item |
|---|---|---|
| [ ] | P2 | `investor_profile_foreign` resolver (merge of `buyer_profile` foreign lens + `investor_profile`) |
| [ ] | P2 | `firb_workflow` reuse — confirm outcome-shape compatibility with Mode B, wire the dispatch clause |
| [ ] | P2 | `investment_strategy` foreign-investor agent-leaf variant (new `_DOMAINS` entry, mirrors `investment_thesis`) |
| [ ] | P2 | `mortgage_finance` non-resident-investor branch (3rd/4th branch on the shared module) |
| [ ] | P2 | `yield_modelling` non-resident-tax-aware variant |
| [ ] | P2 | `tax_structure_non_resident` ★ two-path component (entity-structuring leaf + non-resident CGT/FRCGW constants — most regulated surface) |
| [ ] | P2 | `cash_position` foreign+investor branch (4th discriminator branch) |
| [ ] | P2 | `cross_border_funding` reuse — confirm no Mode-D-specific delta beyond Mode B's build |
| [ ] | P2 | `ownership_planning_foreign_investor` ★ new sibling module (vacancy fee + non-resident tax + portfolio) |
| [ ] | P2 | `disposition` foreign-resident branch (3rd branch — no discount, no PPOR exemption, FRCGW inside CGT) |
| [ ] | P3 | Add `investor-foreign-au` to `IN_SCOPE_BLUEPRINTS`; green semantic gates; re-emit artifact; prove per-card selection (A/B/C unchanged) |
| [ ] | P4 | Dispatcher branches for the 4 new outcome shapes onto existing renderer components (no new `.svelte` expected — verify at P4-open) |
| [ ] | P5 | `?BASE_COMPONENTS_FOREIGN_INVESTOR` per-blueprint `base_components/1` sequence + DAG-walk conformance |
| [ ] | P5 | Onboarding dispatch (`blueprint_for/1` — foreign-person AND investor-intent predicate) + onboarding picker — atomic-last |

## Open seams (surface-and-track, reconcile in-phase)

- **Anchor index vs component-level lists diverge** — reconcile at P1-open (the blueprint's own "~77"/"~87" are provisional counts).
- **`firb_status` shape compatibility** — Mode D's component 3 claims direct reuse "from Mode B," but
  hasn't been diffed field-by-field against Mode B's live `firb_status` outcome; confirm at P2-open,
  don't assume identical.
- **`property_type` enum drift** (grounding-checklist item 3's recorded Wedge-2 reconciliation) —
  `investor-foreign-au:262` still carries the pre-`vacant_land` 6-value enum; adopt `vacant_land` when
  this wedge's `property_assessment` component is built.
- **FIRB naming** (same grounding-checklist item 3 note) — map `vacant_residential_land` (FIRB's term)
  to the neutral `vacant_land` enum when the permitted-purchase-types content is authored for this mode.
- **Mode-switch on PR grant** (blueprint open-Q #3) — D→B/C refresh UX when a Mode-D investor's
  residency status changes; design-first when it triggers, not in this wedge's scope.
- **Multi-property portfolio-level FIRB tracking** (blueprint open-Q #1) — current design is
  per-property; portfolio-level compliance tracking is future iteration, not this wedge.
- **SMSF exclusion confirmation** (blueprint open-Q #5) — likely unavailable to VN-resident investors
  (AU-residency sole-purpose test); needs explicit confirm-and-exclude in `tax_structure_non_resident`'s
  entity options, not a silent omission.
