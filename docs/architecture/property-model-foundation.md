# Property model foundation — completing the property structure

**Status:** Direction accepted; the **`property_type` enum completeness call is resolved** (add `vacant_land`; see Decisions); the canonical fact surface (`property_fit`) and enrichment surface (`suburb.*`) are **already shared and stay** — this is *completion, not unification*. The build-time **structure** is specified here; authoring the one missing scheme doc and wiring it is the executable remainder (item 3b of [`grounding-checklist.md`](../grounding-checklist.md)). Runtime property **data** depth (split-contract draws, completion-valuation gap — the data half of F9) stays deferred by design.

**Why this exists.** This is the **second** build-time foundation, the companion to [`fact-model-unification.md`](fact-model-unification.md). It was surfaced the same way: the artifact compiler ([`../../engine/build/kb_compiler.py`](../../engine/build/kb_compiler.py)), on first run, caught a dangling `kb.scheme.qld.fh-vacant-land` stacking ref. The reflex was to defer it to Phase B ("the property model doesn't have a vacant-land path yet"); that conflated two layers. Separating them is the whole point of this doc, so the analysis is an artifact to decide against rather than reasoned from memory each time.

Read alongside [`structure-map.md`](structure-map.md) (the hub mapping all structures and their relations) and [`fact-model-unification.md`](fact-model-unification.md) (the parallel buyer-side foundation).

---

## The finding in one line

The property layer was **never forked per mode** — all four blueprints publish the one `property_fit` shape, unlike the buyer layer's four divergent profile types. So the property work is **completion, not unification**: the shared surface is right, but its **structure has holes** — the `property_type` enum is missing a value three regulated consumers already need, the enum is re-declared per blueprint, and one scheme doc is referenced but unauthored.

## The asymmetry, inverted

[`fact-model-unification.md`](fact-model-unification.md) diagnosed the buyer side as *shared at the property layer, forked at the identity layer*. This doc is the other half of that same sentence: the property layer is the shared one. The contrast sets the scope:

| | Buyer / identity layer | Property layer |
|---|---|---|
| Outcome type | **forked** — 4 types (`profile` / `profile_foreign` / …) | **shared** — one `property_fit`, all modes |
| The work | **unification** (collapse 4 → 1) | **completion** (fill structural holes in the 1) |
| Root bug class | facts have 4 shapes → cross-mode field-name bugs (F14) | structure has holes → regulated rules reference values/docs that don't exist |

There is no buyer-style identity fork to undo here. The risk is the opposite kind: a shared surface that *looks* complete but is missing structure several rules silently assume.

## The governing principle — structure is built now, data flows later

The category error the compiler finding exposed (recorded in memory as build-time-structure-vs-runtime-data):

| | Build-time **structure** | Runtime **data** |
|---|---|---|
| What | the `property_type` enum, the `property_fit` fact surface, the `suburb.*` enrichment surface, the property-dependent **scheme structure** | a specific property's values |
| When | compiled at deploy — **complete now**, property-agnostic | flows only via narrow Phase-B paths (URL paste, Tìm Nhà, partner push) |
| Governed by | this foundation | `scope: per-property` (the base-vs-Phase-B split) |

The base-vs-Phase-B split governs **WHEN a component runs against data, never WHETHER its structure exists.** `property_assessment` is `scope: per-property` — its *structure* (every parameter leaf, the `property_fit` outcome, the enum) is in the blueprint now; it merely doesn't *execute* until a property is attached. Deferring **structure** to a data-trigger is the category error. This is constraint #1/#2 (the base plan works with zero property data) applied to the property model itself.

**Corollary for F9 (house-and-land / vacant-land — a real Mode A diaspora path, lean-cover per [`../blueprints/scenarios.md`](../blueprints/scenarios.md)):** split F9 by this line. Its **structure half** — the `vacant_land` enum value, the `fh-vacant-land` scheme branch — is built now. Its **data half** — split-contract progress draws, the construction-loan structure, the completion-valuation gap — stays deferred. "Lean-cover" *means* exactly this split.

## The three structural holes

What the live source actually shows is missing — the work-list the foundation closes. Note the first two are **absent-but-needed structure**, which the compiler's reference-integrity gate **cannot see** (it checks that references resolve, not that needed values exist); only the third is a dangling *reference* the gate catches.

### 1. `property_type` is missing `vacant_land` — and three regulated consumers already need it

The enum is `[established_house, established_apartment, new_house, new_apartment, off_the_plan, house_and_land]`. Raw vacant land (buy the block, build later) is **not** `house_and_land` (a bundled land-plus-build *package*, treated as a new-home purchase). Three independent regulated rules already treat them differently:

- **QLD** ([`../kb/scheme/qld/fhc.md`](../kb/scheme/qld/fhc.md), [`fhnhc.md`](../kb/scheme/qld/fhnhc.md)): three first-home transfer-duty concessions — `fhc` (established), `fhnhc` (new home, nil duty no cap), and **`fh-vacant-land`** (vacant land to build) — are `alternative_to` each other, selected by *what is bought*. With no `vacant_land` value the resolver cannot pick the vacant-land concession; `house_and_land` routes to `fhnhc`, the wrong scheme for a raw-land purchase.
- **NSW FHBAS** ([`../kb/scheme/nsw/fhbas.md`](../kb/scheme/nsw/fhbas.md)): vacant land has its **own lower thresholds** ($350k exemption / $450k cap vs the home $800k/$1M). The doc explicitly flags the gap (`:80`): the resolver currently has to special-case land-only purchases because the surface can't express them.
- **FIRB ban** ([`../kb/firb/established-dwelling-ban.md`](../kb/firb/established-dwelling-ban.md) `:90`): `permitted_property_types_for_foreign_persons` already lists `vacant_residential_land` (build within ~4 years) — a value the enum doesn't contain.

This is **Decision 1** below.

### 2. The enum is re-declared per blueprint (the property analogue of the buyer fork)

Each blueprint hand-writes the `property_type` list. They have already drifted: Mode A / B / D carry the 6 values; Mode C (investor) adds `dual_occupancy`, `nrass`. This is the same failure mode as the buyer-identity fork, one level down — a vocabulary that should be **one canonical enum** is copy-declared, so a value added in one place (or this foundation's `vacant_land`) doesn't propagate. **Decision 2.**

### 3. `kb.scheme.qld.fh-vacant-land` is referenced but unauthored (the dangling ref)

`fhc.md` and `fhnhc.md` both declare `alternative_to: [..., "kb.scheme.qld.fh-vacant-land"]` in their `content_json` stacking, and reference it in prose. The doc does not exist. This is a build-time **structure hole**, not a data-deferral — the fix is to **author the lean scheme**, not to remove the edge or punt to Phase B. The compiler stays **red** until it exists; that red is the signal the foundation isn't done. **Decision 3.**

## Decisions

The canonical ground, in priority (same as [`fact-model-unification.md`](fact-model-unification.md)): **strategy** → **architecture principles + §11.9 component-flow** → **the designed scenarios** → **the live blueprints**. Each decision is adjudicated by that corpus, not by taste.

### 1. `property_type` — add `vacant_land` as a distinct value

**Resolved: ADD `vacant_land`.** Ground: the live blueprints + KB are the consuming components, and three regulated consumers (QLD concessions, NSW FHBAS bands, FIRB permitted-types) each already treat vacant land as distinct from `house_and_land` (hole #1). Folding the two would make a regulated resolver pick the wrong scheme — a compliance defect, not a modelling nicety. `house_and_land` keeps its current meaning (a land-plus-build *package*, a new-home purchase); `vacant_land` is a raw-land purchase with a later, separate build.

Canonical Mode-A residential enum becomes:

```
property_type = [ established_house, established_apartment,
                  new_house, new_apartment, off_the_plan,
                  house_and_land, vacant_land ]
```

Naming note: FIRB's `established-dwelling-ban.md` uses `vacant_residential_land` (FIRB's own term distinguishing residential from commercial land). Within our all-residential surface the qualifier is redundant; the canonical value is **`vacant_land`**. Aligning the FIRB doc's permitted-types string is a Mode-B/D-side reconciliation (that doc is a Mode-B/D bootstrap) — flagged, deferred under "build nothing for B/C/D," not done now.

**Investor extensions (`dual_occupancy`, `nrass`) are NOT added now.** They are Mode-C-only and out of Wedge 1a scope. They belong to the canonical enum's deferred extension (Mode C populates them at Wedge 2), exactly as B/C/D populate the buyer schema's deferred fields — not built now.

### 2. One canonical enum; blueprints reference, not re-declare

**Resolved: the canonical `property_type` vocabulary lives in one place (the property foundation / KB), and blueprints reference it.** Ground: §11.9's constrained-vocabulary discipline (renderers are a fixed enum, not re-declared per blueprint) and one-access-path. This is the completion analogue of the buyer model's "one schema, a mode fills a subset": one enum, a mode uses a subset (Mode A: the 7 residential values; Mode C: + `dual_occupancy`, `nrass`). The mechanical reconciliation (point each blueprint's `property_type` at the canonical enum, or at minimum stop them drifting) is item-3b structure work; for Wedge 1 only Mode A's declaration is load-bearing, and it gets the `vacant_land` value now.

### 3. Author `kb.scheme.qld.fh-vacant-land` (lean) and wire it

**Resolved: complete the structure — author the lean scheme doc now.** Ground: build-time-structure-vs-runtime-data — a dangling *structure* reference is a hole to fill, not a data-deferral to punt. Scope of the doc, per the kb-doc-authoring discipline (source-verified against QRO; lean — the structure and the load-bearing parameter, not exhaustive depth):

- frontmatter (`slug: kb.scheme.qld.fh-vacant-land`, `effective_from`, `last_verified`), `content_md` prose, and a `## Rules` `content_json` block;
- an `applicable` criterion keyed on `property_fit.property_type == vacant_land` (disjoint from `fhc`'s established branch and `fhnhc`'s new branch — completing the three-way QLD split);
- the symmetric `alternative_to: [kb.scheme.qld.fhc, kb.scheme.qld.fhnhc]` declared **on this doc's own side** (a symmetric stacking edge is declared once, on either endpoint, and read from all three — `fhc`/`fhnhc` need no re-edit);
- wire `kb.scheme.qld.fh-vacant-land` into the **`eligibility` component's KB anchors** in [`../blueprints/fhb-domestic-au.md`](../blueprints/fhb-domestic-au.md) (currently lists `fhc`, `fhnhc` but not the third).

The **data half** (the QLD vacant-land duty *schedule* depth, construction-loan modelling) is lean-deferred; the structure (the branch, the enum value, the exclusivity edge) is built now.

## What stays — the surface is already right

Nothing here argues against the property-flow machinery; these are strategy/§11.9-required and do not move:

- **`property_fit` as the one neutral fact surface** ⟸ one-access-path (§11.9): downstream components read property data *only* via `property_fit.*`, never via `basics.*` params. Already shared across all four modes. Completion fills holes in it; it does not get re-shaped.
- **`suburb.*` as the enrichment surface** ⟸ the narrow demand-driven pipeline (constraint #3): suburb facts (`lga`, `is_capital_city`, `flood_risk_band`, `vietnamese_community_proximity`, …) enter via `<from_suburb>` resolver lookups against the `suburbs` table, fed by the build-time ABS/state ingestion — *not* via property scraping. `vacant_land` adds no new `suburb.*` field; suburb facts are property-type-independent.
- **`property_card` as the only specific-property ingress** ⟸ constraint #3 + #6: the synchronous user-URL-paste / Tìm Nhà / partner-push paths, normalised to the canonical Property schema, are the sole route a specific property's data reaches `property_assessment`. This foundation defines the *structure* that ingress fills; it adds no new ingress path.

## Wedge-1 staging — no scope expansion

`vacant_land` **is** a Mode A path: a domestic FHB buying a block to build a first home claims NSW vacant-land FHBAS bands or the QLD vacant-land concession — both first-home programs. So this is in-scope structure completion, not new scope. The standing lean-cover call ([`../blueprints/scenarios.md`](../blueprints/scenarios.md) F9) already placed vacant-land / house-and-land as a primary diaspora FHB path. The only cost now is **structure**: one enum value, one lean scheme doc, one anchor wire-up, and an enum-declaration reconciliation. Build nothing for B/C/D (their enum extensions and the FIRB naming alignment ride Wedge 2).

## The structure-completeness pass (what the compiler can't see)

The compiler gates structure-**reference** integrity (every `field`/`ref`/stacking slug resolves) but **cannot see absent-but-needed structure** — a missing enum value that no rule references *yet* is invisible to it (holes #1 and #2 are exactly this; only #3 trips the gate). So closing this foundation needs a **human structure-completeness pass**, not just a green compiler. The pass for the vacant-land / house-and-land path:

1. `vacant_land` added to the canonical enum (Decision 1) and to Mode A's `property_assessment` parameter + `property_fit` outcome declaration.
2. `kb.scheme.qld.fh-vacant-land` authored, source-verified, and wired into `eligibility` anchors (Decision 3).
3. NSW FHBAS `applicable` predicate re-pointed to use `property_type == vacant_land` for the land-only bands (closing the `:80` flag) — verify the resolver no longer special-cases land-only by absence.
4. Grep all four blueprints' `property_type` declarations: confirm Mode A carries `vacant_land`; record (do not yet fix) B/C/D drift and the FIRB `vacant_residential_land` naming, as flagged Wedge-2 reconciliations.
5. Re-run the compiler: the `fh-vacant-land` stacking ref now resolves (gate green); emit is unblocked.

Only after this pass does the compiler's emit gate (held red on this foundation) open — which is item 4's closeout.

## Relationship to the other foundation and parked work

- The buyer foundation ([`fact-model-unification.md`](fact-model-unification.md)) and this one are the **two build-time foundations**, built before any runtime/engine work ("foundations first", [`grounding-checklist.md`](../grounding-checklist.md)). The artifact compiler is the shared **instrument** that materializes and validates both; it does not emit until both are structurally complete.
- The dangling-edge disposition recorded earlier (relocate the symmetric declaration) is **superseded** here: the fix is to *complete the structure* (author the lean scheme), of which declaring its symmetric edge is an intrinsic part — not a relocate-or-remove.
- F9's data half (split-contract / construction-loan / completion-valuation) remains deferred; this foundation takes only its structure half.
