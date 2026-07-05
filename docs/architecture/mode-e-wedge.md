# Mode-E wedge — build plan + progress tracker

**Status: P1 DONE (2026-07-05) — mode-derivation axis + blueprint slug (P0) and KB authoring (P1) landed; P2 (engine resolvers) next.** This doc is the durable
plan *and* the task tracker for the Mode-E (Vietnamese-AU citizen/PR, **not** first-home, buying to
live in — upsizer/downsizer/relocator) wedge. The Claude Code Task list is ephemeral (it does not
survive compaction); this file is the source of truth for "what's left." `wedge-build-sequence.md`
carries a one-line pointer here.

Anchor / upstream: [`fact-model-unification.md`](fact-model-unification.md) (the unified `profile.*`
fact base — Mode E needs no new fact-model generalization, only activation of the already-defined
`existing_portfolio.ppor_*` / `derived.ppor_equity_available_for_leverage` slots, same "content only"
position Mode D was in), [`wedge-build-sequence.md`](wedge-build-sequence.md) ("What's left" — Mode E
is the next foundational item, no external prerequisites), [`mode-c-wedge.md`](mode-c-wedge.md)
("Mode-E gap" section — where this was surfaced, at the P5-activate onboarding intent gate),
[`mode-b-wedge.md`](mode-b-wedge.md) + [`mode-d-wedge.md`](mode-d-wedge.md) (the two precedents this
wedge's phasing mirrors), [`engine-contract.md`](engine-contract.md) §9.1, [`architecture.md`](architecture.md)
§11.9. Conforming artifact: a new blueprint, not yet drafted (see naming below).

## The gap, restated

The P5-activate onboarding intent gate (`Onboarding.svelte`, built in the Mode-C wedge) splits
owner-occupier (first-home-gated → Mode A) from investor (citizen/PR only → Mode C). That leaves one
domestic cell out of scope by construction: **citizen/PR · not-first-home · buying to live in.** It
maps to none of the four built modes — Mode A's FHB schemes (FHG, FHSS, first-home stamp-duty
concessions) would assert benefits this buyer can't claim; Mode C's investor frame (yield, gearing,
CGT-as-primary-concern) is wrong for a home to live in. Routing this segment to either blueprint
produces wrong figures — the onboarding gate correctly shows "coming soon" rather than force a
mismatch. Mode E closes it.

## What Mode E inherits (the foundation already built)

1. **The unified fact base** — `existing_portfolio.ppor_owned` / `ppor_estimated_equity` and
   `derived.ppor_equity_available_for_leverage` are already defined in `fact-model-unification.md`
   and already active for Modes C/D. Mode E activates the same slots for a domestic owner-occupier —
   no schema change.
2. **Mode C's `disposition` two-path dispatch pattern** (`fh_engine_disposition:fill/2` branches on
   `tax_optimised_structure` presence → `fill_owner_occupier/2` vs `fill_investor/4`) — direct
   template for the CGT-on-sale-of-the-existing-home logic (main-residence exemption path, not the
   investor path).
3. **`kb.tax.cgt-main-residence-exemption`** (authored for Mode A's own future exit) — the exemption
   *rule* is already KB-grounded; Mode E's new need is applying it to a sale happening **now** (to
   fund this purchase), not a future exit.
4. **`docs/kb/land-tax/ppor-exemption.md`** already documents VIC's dual-PPR exemption covering the
   transition year where the buyer holds both the old and new home — direct evidence the KB already
   anticipated the upsizer transition case for at least one state.
5. **The multi-blueprint runtime + compiler** (`IN_SCOPE_BLUEPRINTS` as a set, structural gates
   already covering all existing blueprints) — adding a 5th blueprint is the same add-and-prove-
   selection move done three times already (B, C, D), not new machinery.
6. **The wedge-opening + phasing pattern itself** (this doc's shape mirrors `mode-b-wedge.md` /
   `mode-d-wedge.md`).

## The load-bearing scoping decision (proposed 2026-07-05, confirmed by Son)

1. **A new mode-derivation axis is required — this is the one genuinely new mechanism.** Mode
   is currently a strict 2×2 (`foreign axis × intent axis`); Mode E is domestic + owner-occupier, the
   *same cell as Mode A*. Neither axis distinguishes first-home from repeat-buyer. A third axis —
   `plan.buyer_stage: first_home | next_home` — is a required addition to the derivation model, not a
   pre-existing slot. It is **self-declared at onboarding**, the same way citizenship/intent are
   self-declared (not derived from any fact already on file — "is this your first home" is a fact
   only the user can state).
2. **Existing-home-sale arithmetic — full build.** Net sale proceeds of the buyer's *current* home
   (sale price − loan payout − selling costs − CGT via the main-residence exemption) feeding into
   `cash_position` as a new cash source. This is KB-groundable arithmetic with no licensure risk
   (informational, resolver-computed, no advice given) — same discipline as every other regulated
   figure in this codebase.
3. **Bridging finance mechanics — labelled placeholder, not full build.** Zero KB content exists
   today (every "bridging" hit in the KB is bridging *visa*, a FIRB/immigration term — not bridging
   *loans*). Recommending a specific bridging-loan structure (peak debt, capitalised interest) edges
   toward credit-advice / ACL territory — same caution as the standing "no named-lender
   recommendation" rule. Build the structure (a `bridging_finance_considered: bool` flag +
   `is_placeholder` marker on the relevant leaf), mark the mechanics pending, name the trigger (a
   bridging-finance KB source lined up) — [[honest-deferral-not-rug]].
4. **Foreign next-home buyer — explicitly out of scope, fails closed.** A repeat/upsizing buyer who
   is *not* a citizen/PR combines the FIRB axis with the next-home axis — a real combinatorial cell,
   but a separate one (established-dwelling-ban interaction with an existing AU property is a distinct
   regulated question). `blueprint_for/N` must fail closed on this combination (`{error,
   unsupported_combination}`), mirroring Mode D's SMSF-exclusion precedent — logged as a future cell,
   not silently absorbed into Mode E or Mode D.
5. **Blueprint slug — RESOLVED at P0 (2026-07-05): `nexthome-domestic-au.md`.** Drops the `fhb`/
   `investor` segment prefixes entirely rather than forcing a fit — `fhb` would misname a repeat buyer
   (asserting a first-home segment), `investor` is simply wrong. `nexthome` names the actual segment,
   keeping the `{segment}-{firb-axis}-au` shape. No `nexthome-foreign-au` exists (or is planned) — that
   cell is decision #4's fail-closed combination, not a fifth-plus blueprint. See
   [`architecture.md`](architecture.md) §11.9 "Four blueprints."

## Regulated design concern (inherits Mode A's + Mode C's, adds one new surface)

- **Everything from `mode-c-wedge.md`'s regulated concern** on CGT/tax-structuring figures:
  decision-support only, resolver-computed, verified against ATO primaries — applies identically to
  the existing-home-sale CGT calculation.
- **The new surface: bridging finance.** Per the scoping decision above, this stays a labelled
  placeholder specifically *because* of ACL/credit-advice risk — do not build past a flag +
  placeholder until a KB source is lined up. This is the wedge's one genuinely new regulated-harm
  surface (Mode A/B/C/D's harm surfaces were all inherited, not novel).
- **Misadvice risk if the buyer_stage axis is wrong**: a repeat buyer mis-flagged as first-home would
  see FHG/FHSS eligibility they can't claim (real financial harm, same class of risk as the FIRB
  established-dwelling-ban gate) — `buyer_stage` must be a hard onboarding gate input, never inferred
  or defaulted to `first_home`.

## Phases

| Status | Phase | Item |
|---|---|---|
| `[x]` | P0 | Mode-derivation axis: `plan.buyer_stage` added to [`fact-model-unification.md`](fact-model-unification.md) (the `plan{}` schema + the "Mode is derived — three axes" section, replacing the old 2×2) and the blueprint table in [`architecture.md`](architecture.md) §11.9 (Mode E row + naming rationale added); blueprint slug resolved to `nexthome-domestic-au` (decision #5 above); scoping decision anchored as this doc. **Done 2026-07-05.** Not yet touched at P0 (by design — no code changes until P2/P5): `fh_engine_h_plan_cards:blueprint_for/2` (still 2-arg; the foreign+next-home cell still has no engine-level backstop, shell-only gate) and `engine-contract.md` §9.1's `mode` derivation prose (still says `firb_required_any × intent`) — both ride P5. |
| `[x]` | P1 | KB authoring, **done 2026-07-05**: [`kb.existing-home-sale.net-proceeds`](kb/existing-home-sale/net-proceeds.md) (loan-payout mechanics new; selling-costs + CGT reused from existing docs, not duplicated); [`kb.land-tax.dual-ownership-transition`](kb/land-tax/dual-ownership-transition.md) (NSW/QLD/SA/TAS/ACT confirmed — QLD + TAS direct-fetched, NSW/SA/ACT snippet-confirmed; WA existence-confirmed but duration/conditions still `to_verify`; NT's no-land-tax status is secondary-corroborated only — both gaps named, not silently resolved); [`kb.bridging-finance.mechanics`](kb/bridging-finance/mechanics.md) (labelled placeholder — structural timing-mismatch detection built, economics/lender-recommendation content gated behind `is_placeholder`, per decision #3). **Follow-up recommended before any of these three docs' `last_verified` is next extended:** re-fetch WA's exemption duration, NT's revenue-office primary, and pin the exact exit-fee-ban amending-instrument citation — named in each doc's own Notes section, not blocking P2. |
| `[ ]` | P2 | Engine resolvers: new existing-home-disposal resolver (net proceeds → `cash_position` input); `eligibility` component dropped/branched (no FHG/FHSS/first-home concessions); `disposition`'s owner-occupier path reused for the *new* home's future exit unchanged |
| `[ ]` | P3 | Multi-blueprint activation: add the new blueprint to `IN_SCOPE_BLUEPRINTS`, run the compiler, resolve any shared-anchor/outcome-key conformance gaps (expect the same class of surprise P3 found for Mode B/D — prose-only cross-references, private outcome-type names) |
| `[ ]` | P4 | Shell dispatcher branches — confirm existing renderers cover the new component (expect no new renderer needed; if one is, that's a §11.9 vocabulary decision, not a default) |
| `[ ]` | P5 | Onboarding dispatch — `buyer_stage` picker (first-home / next-home) wired into the existing intent gate; `blueprint_for/N` extended to the 3-axis dispatch + fail-closed on foreign+next-home; atomic-last, same discipline as every prior wedge |

## Cross-references

- **Roadmap SOT:** [`wedge-build-sequence.md`](wedge-build-sequence.md) "What's left."
- **Where the gap was found:** [`mode-c-wedge.md`](mode-c-wedge.md) "Mode-E gap."
- **The shared foundation:** [`fact-model-unification.md`](fact-model-unification.md).
- **Phasing precedent:** [`mode-b-wedge.md`](mode-b-wedge.md), [`mode-d-wedge.md`](mode-d-wedge.md).
