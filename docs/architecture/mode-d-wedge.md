# Mode-D wedge — build plan + progress tracker

**Status: P1 (KB) + P2 (engine resolvers) + P3 (multi-blueprint activation) done and verified
(2026-07-04). Opened 2026-07-03.** This doc is the
durable plan *and* the task tracker for the Mode-D (Vietnam-located foreign investor) wedge. The
Claude Code Task list is ephemeral (it does not survive compaction); this file is the source of
truth for "what's left." The grounding-checklist carries a one-line pointer here.

**P1 close-out note.** The compiler (`python3 tests/validate_build.py`) is the ground truth for
anchor resolution, not manual grep — it caught 5 stale slug references my first reconciliation
pass left in explanatory parentheticals (backtick-quoted tokens inside a `**KB anchors:**` line get
scanned as real anchors regardless of surrounding prose) and surfaced **7 more unbuilt anchors**
(component 3's off-the-plan anchor, component 5's mortgage-finance anchor cluster) my manual
grep-based sweep of the blueprint had not caught at all. Ran the compiler after the first pass,
fixed against its literal unbuilt-anchor list, re-ran to confirm 0 unbuilt / all gates green. **12
new KB files total** (1 more than the ~11 estimated): the synthesis + 7 new-content docs, the 3 VN
placeholders, plus `kb.lender.non-resident-investment-loan-shortlist` (surfaced only by the
compiler pass, not by the original blueprint-grep reconciliation).

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
primary · `[x]` done (bilingual, in-cluster, compiles when in-scope).

**P1-open anchor-index reconciliation (2026-07-03) — done, and it moved most of the work.** Read the
live content of every candidate overlap before authoring anything. Result: **6 of the tracker's
original 12 items already exist under a different slug** — built generically during Mode B/C (a
non-resident-tax / investor-tax fact that doesn't actually depend on owner-occupier vs investor
framing), not duplicated for Mode D. **1 item is moot** for an investor (never had a PPOR to lose the
exemption on). The blueprint body also references **2 more anchors not in the original 12** (spotted
via grep, not just the tracker list) — one reconciles the same way, one is genuinely new. Net: the
"~10 exclusive" estimate holds (11 new files: 1 synthesis + 7 new-content docs + 3 VN placeholders),
but the *composition* changed — more reuse, one genuinely-new item surfaced the blueprint didn't
originally name.

**RECONCILE — blueprint anchor rename, zero new KB doc** (fix `investor-foreign-au.md`'s anchor
references to point at the existing slug; the underlying fact is single-owned and mode-agnostic
already):

| Tracker anchor (as written) | Actual existing slug | Why it's already general, not Mode-B-specific |
|---|---|---|
| `kb.non-resident.serviceability-au-lenders` | `kb.lender.non-resident-friendly-shortlist` | criteria doc keyed on residency/visa, not on buyer intent (occupy vs invest) |
| `kb.non-resident.rental-income-withholding-tax` | `kb.non-resident-tax.withholding-on-rental-income` | assessment-not-withholding treatment is residency-driven, not occupancy-driven |
| `kb.non-resident.cgt-no-50-percent-discount-from-2012` | `kb.tax.cgt-50-percent-discount` | already explicitly scoped "Mode C/D" in its own header — authored investor-general from the start |
| `kb.foreign-investor.frcgw-on-sale` | `kb.non-resident-tax.foreign-resident-cgt-withholding` | FRCGW mechanism (15%, no threshold) is a residency fact, not an occupancy fact |
| `kb.tax.depreciation-non-resident` (blueprint line 525, not in original 12) | `kb.tax.depreciation-division-43-and-40` | Div 43/40 rates have no residency dependency at all — non-resident owners claim the identical schedule |

**MOOT — drop, no doc, fold into the new synthesis doc's reasoning:**

- `kb.non-resident.cgt-no-ppor-exemption` — Mode B's version of this doc is a genuine "the exemption
  the buyer *would have had* is removed" synthesis (an owner-occupier who becomes a foreign resident).
  Mode D's buyer is an **investor from day one** — the property was never a main residence, so the
  exemption never applied in the first place ([`kb.tax.cgt-main-residence-exemption`](../kb/tax/cgt-main-residence-exemption.md)'s
  base conditions already require "was the home... for the whole period"). Not a new regulated fact —
  a corollary of an existing one. Recorded as a note in the new synthesis doc, not a standalone anchor.

**NEW — genuinely net-new content** (7 docs, all AU-side per the scoping decision above):

- [x] `kb.non-resident.tax-treatment-overview` — the Mode-D synthesis/pointer doc (mirrors Mode B's
  per-topic synthesis pattern, consolidated to one doc since there's no exemption to invert): ties
  together the 4 reused docs above + the PPOR-moot note + this doc's own entity-restriction content,
  as the anchor `tax_structure_non_resident` actually reads first.
- [x] `kb.non-resident.entity-options-au-property` — non-resident-specific entity restrictions the
  base [`kb.tax.entity-comparison-personal-trust-company-smsf`](../kb/tax/entity-comparison-personal-trust-company-smsf.md)
  doesn't cover: FIRB applies regardless of entity look-through, SMSF generally unavailable to a
  non-resident (super residency test — CMC ordinarily in Australia, ≥50% AU-resident active-member
  value), foreign/absentee trust land-tax surcharges (cross-ref `kb.tax.land-tax-by-state`, already
  primary-verified per-state). **Resolves open-seam "SMSF exclusion confirmation" below** — verified
  against the ATO's CMC/active-member residency tests (2026-07-03).
- [x] `kb.non-resident.investment-loan-deposit-requirements` — synthesis of the foreign-buyer deposit
  band ([`kb.lender.foreign-buyer-deposit-requirements`](../kb/lender/foreign-buyer-deposit-requirements.md),
  30–40%) with the investment-purpose delta (no FHB schemes, no owner-occupier LMI leniency) the pure
  foreign-buyer doc doesn't state.
- [x] `kb.foreign-investor.thesis-archetypes` — a FIRB-driven viability overlay on the existing
  archetype vocabulary ([`kb.investor.strategy-archetypes`](../kb/investor/strategy-archetypes.md)):
  the established-dwelling ban narrows which archetypes are practically reachable for a foreign buyer
  (new-build / off-the-plan / vacant-land-for-build stay open; established-property `value_add` does not).
- [x] `kb.foreign-investor.currency-hedging-considerations` — VND/AUD exposure across the hold (rental
  income conversion timing, eventual repatriation); informational, no retail hedging product assumed;
  states the AUD-loan natural-hedge structure as the primary lever ahead of any product idea.
- [x] `kb.foreign-investor.future-migration-pathway-considerations` — the mode-switch structural doc
  (PR/citizenship grant moves the investor off the non-resident tax/FIRB track — echoes Mode B/C's
  mode-switch design, mostly cross-referencing the docs that already carry the individual consequences).
- [x] `kb.foreign-investor.repatriation-strategy` — AU-side only per the scoping decision: sending
  rental income / sale proceeds back to Vietnam through a licensed provider (cross-ref the `fx` docs +
  `au-aml-ctf` docs); the VN-receiving-side rule is a placeholder pointer to the existing
  `vn-capital-controls` docs, not new VN-side content.
- [x] `kb.foreign-investor.absentee-owner-management` — remote-management practicalities (POA, PM
  selection from overseas), cross-referencing the existing
  [`kb.investor.property-management-vs-self-managed`](../kb/investor/property-management-vs-self-managed.md),
  [`kb.firb.vacancy-fee-rules-2026`](../kb/firb/vacancy-fee-rules-2026.md), and the land-tax absentee
  surcharges already in `kb.tax.land-tax-by-state`.

**NEW — surfaced only by the compiler pass, not the original blueprint-grep sweep** (component 3's
off-the-plan anchor and component 5's mortgage-finance anchor cluster — 7 anchors the original P1-open
reconciliation missed entirely because it worked from the tracker's 12-item list + a manual grep, not
the compiler's literal per-blueprint unbuilt-anchor inventory):

- [x] `kb.off-the-plan.foreign-investor-considerations` → **RECONCILED**, no new doc — the existing
  [`kb.off-the-plan.risk-considerations`](../kb/off-the-plan/risk-considerations.md) already grounds
  Mode B's `property_assessment` on off-the-plan risk for a foreign buyer restricted to new-build
  stock, an investor-agnostic constraint identical for Mode D.
- [x] `kb.lender.foreign-investor-deposit-requirements` → **RECONCILED** to
  `kb.non-resident.investment-loan-deposit-requirements` (shared across components 5 and 8 — single-owner).
- [x] `kb.lender.vn-income-treatment` → **RECONCILED** to the already-general
  [`kb.lender.temp-resident-lending-policies`](../kb/lender/temp-resident-lending-policies.md).
- [x] `kb.loan.interest-only-non-resident-investor` → **RECONCILED** to the already-general
  [`kb.loan.interest-only-vs-pi-investor`](../kb/loan/interest-only-vs-pi-investor.md) for the trade-off
  framing; the IO-availability-by-lender caveat folded into the new shortlist doc below.
- [x] `kb.lender.investment-loan-policies-non-resident` + `kb.lender.foreign-investor-rate-premiums` +
  `kb.lender.non-resident-investment-loan-shortlist` → **ONE new doc**,
  [`kb.lender.non-resident-investment-loan-shortlist`](../kb/lender/non-resident-investment-loan-shortlist.md) —
  the combination-specific facts a non-resident-**investment** lender pool needs beyond either the
  non-resident-owner-occupier criteria or the domestic-investor criteria alone (narrower pool,
  70–80% rental-income shading, a further ~100–200bp rate premium above the domestic-investor rate
  **flagged as an indicative CONVENTION band, not independently primary-verified this pass**, and the
  IO-availability-by-lender caveat).

**Total: 12 new KB files** (1 more than the ~11 first estimated — the shortlist doc above was invisible
to the manual reconciliation and only surfaced via `python3 tests/validate_build.py`'s literal
unbuilt-anchor inventory). **Verified 2026-07-03: 0 unbuilt anchors for `investor-foreign-au`, all
compiler gates green (`--no-emit`).**

### VN-side — labelled placeholders (structure now, datum pending; buyer-pointer copy)

Mirrors Mode B's VN-side treatment exactly (`kb-doc-authoring`'s fifth honesty move): structure built,
the genuinely-VN-side datum marked pending, bilingual copy points the buyer to their own VN-based tax
advisor. No GDT-Vietnam or DTA primary-source verification work — that's explicitly out of scope per
the 2026-07-03 scoping decision above.

- [x] `kb.vn-tax.brackets-2026` — ⚠ placeholder + buyer pointer ("consult your VN-based tax advisor")
- [x] `kb.vn-tax.income-from-foreign-property` — ⚠ placeholder + buyer pointer
- [x] `kb.au-vn-tax-treaty` — ⚠ placeholder, **except** any AU-side withholding-rate effect discovered
  while authoring Cluster FI's non-resident withholding docs — that piece is AU-side and belongs there,
  not here. **Checked while authoring `kb.non-resident.tax-treatment-overview`: no AU-side treaty rate
  modification identified this pass** — FRCGW (15%) and the rental-assessment treatment are stated as
  ordinary domestic-law rates. Flagged as a live open item inside the treaty placeholder (not a closed
  deferral) for a future pass to re-check specifically, distinct from the rest of the placeholder's
  content which is deferred per the scoping decision.

## P2–P5 — engine + shell tracker

**P2 done and verified (2026-07-03).** All ten base-turn resolver items landed. A prerequisite
surfaced mid-phase and is now closed: **five of the blueprint's own "Outcome schema" `type`
fields were private per-mode names** (`investor_profile_foreign_summary`, `strategy_thesis_foreign`,
`cash_flow_projection_foreign`, `tax_structure_non_resident_summary`, `budget_envelope_foreign_investor`)
that would have broken the shared-component-name dispatch discipline `fh_engine_mortgage`/
`fh_engine_cash`/`fh_engine_disposition` already establish live for Mode B/C (a component NAME can
differ per mode; the outcome-schema `type` — the runtime Upstream dispatch key — must stay
canonical). Reconciled to `profile` / `strategy_thesis` / `cash_flow_projection` /
`tax_optimised_structure` / `budget_envelope_investor` respectively (investor-foreign-au.md's own
"Outcome-type conformance" section, added 2026-07-03, records the full rationale). This is what let
four of the ten items land as **near-zero-code reuse** (firb_workflow, yield_modelling both
unchanged; cross_border_funding + cash_position's investor-path routing needed no new dispatch
logic) rather than new modules.

One tracker claim was wrong and is corrected here: **`cross_border_funding` DID need a real
branch**, not zero-delta reuse — Mode D has no `family_context` component (solo/couple investors,
no parent-funding-child pattern), so `family_funding_plan` is never in Upstream; added a fallback
to `profile.available_capital_aud_equivalent`.

The misadvice-critical correctness point: `investor_profile_foreign` sets
`applicant.tax.residency_for_tax = non_resident` DEFINITIONALLY (not a possibility-set projection
the way Mode A/C project citizenship). This is what makes `fh_engine_disposition`'s ALREADY-BUILT
`cgt_investor/4` (the SAME function Mode C uses, unmodified) route every Mode-D turn to
`cgt_status = to_verify` by construction — proven in `mode_d_p2_conformance.escript` with a
deliberately "clean-looking" entity/rate/clawback fixture (to show the routing is residency-driven,
not an accident of a messy fixture). `tax_structure_non_resident` sets `cgt_discount_eligible: false`
DEFINITIONALLY too (not holding-period-conditional, unlike Mode C's constant) and
`frcgw_applicable: true`; `fh_engine_disposition:fill_investor/3` (shared with Mode C) was extended
with `frcgw_withheld_at_settlement` (15% of the projected sale-proceeds band, KB-grounded,
resolver-computed, never LLM-authored) and `vn_side_cgt_note` — both null/absent-equivalent for
Mode C (regression-proven).

Verified: `rebar3 compile` clean (0 warnings); `python3 tests/validate_build.py` PASS (structural +
semantic gates, investor-foreign-au still correctly out-of-scope, 0 unbuilt anchors carried from
P1); all 19 pre-existing Mode A/B/C conformance escripts still PASS (zero regression); the new
`test/mode_d_p2_conformance.escript` — 82 assertions across all ten P2 items — PASSES.

**P3 done and verified (2026-07-04).** `investor-foreign-au` added to `IN_SCOPE_BLUEPRINTS` (now a
4-member set); the per-card multi-blueprint runtime (Mode-C wedge P3) and its N-blueprint
generalization (Mode-B wedge P3) needed **zero engine code change** — both already key registries
and validation by `blueprint_slug`, built for an open-ended set.

But the flip itself was not a mechanical one-liner, unlike Mode B's: **flipping in-scope turns on
SEMANTIC gates for the first time**, and those caught two real prerequisite gaps P2 (structural-gates-
only) couldn't see:

1. **The compiler parses each blueprint file independently — no cross-file JSON stitching.**
   `firb_workflow` (component 3) and `cross_border_funding` (component 9) were written prose-only
   ("Same as Mode B — no changes", a markdown link, no inline JSON), because their Erlang resolvers
   really are reused verbatim. But `build_registry` only materializes fields from JSON blocks present
   in *this* blueprint's *own* file — a prose-only component contributes nothing to its blueprint's
   registry, even when the underlying code is genuinely shared. This broke the shared anchors
   `kb.firb.established-dwelling-ban` / `kb.firb.status-determination` (both `firb_workflow`-scoped)
   the moment semantic gates ran against investor-foreign-au. **Fix: inlined Mode B's Parameters +
   Outcome-schema JSON verbatim into both components** (doc-only; zero engine change — the resolvers
   were already correct). Mode B's own `bid_plan`/`risk_assessment`/`settlement_checklist` use the
   same prose-only pattern successfully *only* because no KB anchor's `fills` rule happens to
   reference their fields — the gap is latent there too, just not yet triggered.
2. **`property_assessment`'s outcome was wrongly kept private.** P2's outcome-type-conformance pass
   (2026-07-03) explicitly reasoned `property_fit_investor_foreign` "stays private (per-property/no
   shared discriminator dependency)" — true only because P2 never ran this blueprint's semantic
   gates to check. It does have a shared-discriminator dependency: `firb_workflow` is Mode B's
   `fh_engine_firb` reused verbatim, and it reads `Upstream.property_fit` (confirmed by source read,
   not assumption) — plus the established-dwelling-ban anchor's own `fills` rule hardcodes
   `property_fit.property_type` literally. **Reconciled to the canonical `property_fit`** (matching
   Mode A/B, who already declare it), superseding the P2 note. **Correctly left open** (not decided
   at P3, nothing regresses today because no property resolver runs until P2-continuation/property-
   scope): `fh_engine_disposition`/`fh_engine_cash`'s already-built Mode-D investor paths read
   `property_fit_investor` (Mode C's key) — a third name. Whichever key `property_assessment`
   actually emits under, one of the two reader sets needs a fallback; decide when that component is
   built, not here (advisor-checked before implementing — the temptation was to "fix" this by editing
   `fh_engine_firb`/`fh_engine_disposition` now, which would have been scope creep with zero P3
   benefit, since neither module is exercised by any P3 selection proof).

Also fixed: `mode_b_p3_scope_conformance.escript`'s own `in_scope_blueprints` assertion was a
hardcoded "exactly the three bare stems" — now stale by construction. Updated to four, matching the
same "activation is additive" discipline the escript itself proves for A/B/C.

Verified: `python3 tests/validate_build.py` PASS (4 in-scope registries, 0 fails); artifact re-emitted
(169 KB entries, 4 blueprints, 4 in-scope registries); `rebar3 compile` clean; new
`test/mode_d_p3_scope_conformance.escript` (23 assertions: scope set, registry materialization,
Layer-1 conformance for all 10 P2 outcome types against the investor-foreign-au registry specifically,
and a 4-way A/B/C/D modes-coexist proof) — PASSES; `mode_b_p3_scope_conformance.escript` (fixed
assertion) — PASSES; `mode_d_p2_conformance.escript` — still 82/82; full escript sweep (51 files) —
47 pass, the same 4 pre-existing failures confirmed **identical on the unmodified baseline**
(`due_diligence_conformance`, `investor_seam_smoke`, `property_assessment_seam`, `qa_smoke` — verified
by `git stash`-ing this session's two changed files, re-emitting, recompiling, and re-running each;
all four fail identically pre-change) — zero regression.

| Status | Phase | Item |
|---|---|---|
| [x] | P2 | `investor_profile_foreign` resolver (merge of `buyer_profile` foreign lens + `investor_profile`; canonical `profile` outcome; `residency_for_tax=non_resident` definitional) |
| [x] | P2 | `firb_workflow` reuse — confirmed unchanged at base turn (reads `profile.*`; no property yet regardless of the future `property_fit` vs `property_fit_investor` key-naming seam, flagged below for P2-property-scope) |
| [x] | P2 | `investment_strategy` foreign-investor variant (`fh_engine_fill:investment_strategy/2` — new Args-based dispatch mirroring `mortgage_finance`; same 3-leaf agent-slot discipline, shared `strategy_thesis` type, 2 Mode-D-only resolver fields) |
| [x] | P2 | `mortgage_finance` non-resident-investor branch (4th branch: `strategy_thesis` present AND `firb_required_any`; new 2×2 compound discriminator in `merge_agent`/`agent_values_from_outcome` — also fixed a latent single-key-priority bug the 2×2 replaces) |
| [x] | P2 | `yield_modelling` — confirmed unchanged (property-absent base scaffold is mode-agnostic under the renamed canonical `cash_flow_projection` key) |
| [x] | P2 | `tax_structure_non_resident` ★ two-path component (entity-structuring leaf + non-resident CGT/FRCGW constants, all definitional not holding-period-conditional — most regulated surface) |
| [x] | P2 | `cash_position` foreign+investor branch (4th discriminator branch, reused `budget_envelope_investor` key so `disposition`'s existing investor placement needed zero change) |
| [x] | P2 | `cross_border_funding` — real branch needed (tracker's "no delta" claim corrected above): falls back to `profile.available_capital_aud_equivalent` when `family_funding_plan` is absent |
| [x] | P2 | `ownership_planning_foreign_investor` ★ new sibling module (vacancy fee + AU/VN tax obligation prose + portfolio; no `disposition`/`opportunities` edge — confirmed against the blueprint's own declared inputs/outcome fields, simpler than Mode C's sibling) |
| [x] | P2 | `disposition` foreign-resident branch — NOT a new branch: extended the shared `fill_investor/3` (Mode C's own function) with FRCGW + the VN-side note, gated on `tax_optimised_structure.frcgw_applicable`; the CGT no-discount/no-PPOR-exemption/to_verify routing needed zero new code (falls out of `residency_for_tax=non_resident` + `cgt_discount_eligible=false`) |
| [x] | P3 | Add `investor-foreign-au` to `IN_SCOPE_BLUEPRINTS`; green semantic gates; re-emit artifact; prove per-card selection (A/B/C unchanged) |
| [ ] | P4 | Dispatcher branches for the 4 new outcome shapes onto existing renderer components (no new `.svelte` expected — verify at P4-open) |
| [ ] | P5 | `?BASE_COMPONENTS_FOREIGN_INVESTOR` per-blueprint `base_components/1` sequence + DAG-walk conformance |
| [ ] | P5 | Onboarding dispatch (`blueprint_for/1` — foreign-person AND investor-intent predicate) + onboarding picker — atomic-last |

## Open seams (surface-and-track, reconcile in-phase)

- ~~**Anchor index vs component-level lists diverge**~~ — **RESOLVED at P1 (2026-07-03).** Reconciled
  against the compiler's literal per-blueprint unbuilt-anchor inventory (`python3 tests/validate_build.py`),
  not just the tracker's provisional "~77"/"~87" counts — see the P1 section above for the full table.
  0 unbuilt anchors, all gates green.
- ~~**`firb_status` shape compatibility**~~ — **RESOLVED at P2 (2026-07-03), NARROWED at P3
  (2026-07-04).** `fh_engine_firb:fill/2` reused verbatim (zero code change) — confirmed against its
  live source: it reads `Upstream.profile.*` and `Upstream.property_fit` (undefined at every Mode-D
  base turn regardless, same as every other mode pre-property), so the shape question was moot for
  P2's base scope. P2 flagged a 3-way property-key naming split (`property_fit` / `property_fit_investor`
  / `property_fit_investor_foreign`) and deferred it to `property_assessment`'s own build. Flipping
  investor-foreign-au in-scope at P3 forced part of that decision early — not by choice, by the
  compiler's semantic gate: the shared anchor `kb.firb.established-dwelling-ban`'s own `fills` rule
  reads `property_fit.property_type`, and that string must resolve to a real registry namespace for
  ANY in-scope blueprint referencing it. **Reconciled `property_assessment`'s declared outcome type
  to the canonical `property_fit`** (matching Mode A/B — doc-only, no engine change, no resolver
  exists for this component yet so nothing runtime-regresses). **Still correctly open, NOT decided at
  P3** (advisor-checked: editing `fh_engine_firb`/`fh_engine_disposition` now would be scope creep with
  zero P3 benefit, since P3's selection proof never exercises a property-attached turn): the
  already-built `fh_engine_disposition`/`fh_engine_cash` Mode-D investor paths still read
  `property_fit_investor` (Mode C's key) — a second name that doesn't match `property_fit`. Whichever
  key `property_assessment` actually emits under, one of the two reader sets needs a small fallback
  read — decide at that component's build, not here.
- **`property_type` enum drift** (grounding-checklist item 3's recorded Wedge-2 reconciliation) —
  `investor-foreign-au:313` still carries the pre-`vacant_land` 6-value enum; adopt `vacant_land` when
  this wedge's `property_assessment` component is built.
- **FIRB naming** (same grounding-checklist item 3 note) — map `vacant_residential_land` (FIRB's term)
  to the neutral `vacant_land` enum when the permitted-purchase-types content is authored for this mode.
- **Mode-switch on PR grant** (blueprint open-Q #3) — D→B/C refresh UX when a Mode-D investor's
  residency status changes; design-first when it triggers, not in this wedge's scope.
- **Multi-property portfolio-level FIRB tracking** (blueprint open-Q #1) — current design is
  per-property; portfolio-level compliance tracking is future iteration, not this wedge.
- ~~**SMSF exclusion confirmation**~~ (blueprint open-Q #5) — **RESOLVED at P1 (2026-07-03)**, by
  [`kb.non-resident.entity-options-au-property`](../kb/non-resident/entity-options-au-property.md).
  Not the sole-purpose test (that applies to every SMSF) — the actual disqualifier is **fund
  residency**: the central-management-and-control test (ordinarily in Australia; permanent offshore
  CMC fails it) and the active-member test (≥50% AU-resident active-member value), verified against
  the ATO. A fund controlled from Vietnam by someone who was never an AU resident cannot ordinarily
  satisfy either — `recommended_entity`'s agent-path comparison should not present SMSF as live for a
  genuinely Vietnam-located investor absent an existing AU-resident-controlled fund.
