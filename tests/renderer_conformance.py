#!/usr/bin/env python3
"""Renderer field-conformance gate (shell-side, mirrors the engine's own gates).

Why this exists: the engine side already has a build-time gate that stops
docs/blueprint drift from shipping silently — kb_compiler's structural gates
(slug==path, renderer-in-enum, pipeline-acyclic) plus its semantic gates
(reference-integrity, coverage, type-compat). Nothing on the SHELL side checks
the inverse direction: that the frontend actually reads every field a
component's Outcome schema declares. §11.9's constrained renderer vocabulary
deliberately reuses ONE renderer name (and often one outcome TYPE name) across
several modes' blueprints — Mode C's `tax_structure` and Mode D's
`tax_structure_non_resident` both compose `data-table`, with different field
sets. A renderer written against the mode built first silently drops the
other mode's fields forever, because nothing else notices. Found live
2026-07-11 (three renderer bugs — mortgage/tax/cash-position Mode-D field
gaps) after a manual DB-grounded audit; this gate mechanizes that audit so
it runs on every change instead of only when a live user stumbles into it.

Method: parse every docs/blueprints/*.md component (kb_compiler.parse_blueprint
— the SAME parser the artifact compiler uses, so this can never drift from what
actually ships), then for each component with declared `outcome_fields`, check
that every TOP-LEVEL field name appears as a literal substring SOMEWHERE in the
shell frontend's `src/lib` tree (every .svelte/.ts file, not just the
component's narrowly-mapped renderer). Deliberately whole-tree, not per-renderer-
file: a field is often legitimately consumed by shell-composition code rather
than the component's own dispatched renderer — `phase_playbook.phases` is read
by `FlowView.svelte` (not `Checklist.svelte`, despite that being the blueprint's
declared renderer), `disposition.dispose_cash_events` is read via
`planCard.ts`'s cross-component `harvestCashEvents`, `cash_position.*`
what-if-cockpit fields are read by `PlanProjection.svelte` directly. A
per-renderer-file version of this check produced 142 false positives from
exactly this pattern on first run (2026-07-11) — narrowing the search to "the
one file ComponentCard.svelte dispatches to" assumes every field reaches the
user through that one path, which the architecture doesn't actually guarantee.
Whole-tree substring search is coarser but was confirmed (same run) to still
catch all three real bugs it was built to catch — none of their field names
(`negative_gearing_available_against_au_income`, `rental_withholding_rate`,
`channel_costs_total`) appeared ANYWHERE in `src/lib` before the fix.

Known blind spot (accepted, not solved): presence-only. A field that exists in
source for a DIFFERENT mode but is read unconditionally for a mode it doesn't
apply to (the `offset_strategy_recommendation`/`loan_structure_recommendation`
class of bug — real fields, wrongly un-gated for Mode D) will NOT be flagged
here, because the field name is genuinely present in the tree. That flavor
needs the kind of live-DB-grounded audit this session did by hand; this gate
only catches "a declared field is never referenced anywhere," not "a field is
referenced somewhere it shouldn't unconditionally apply."
"""
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
BP = ROOT / "docs" / "blueprints"
LIB = ROOT / "shell" / "web" / "frontend" / "src" / "lib"

sys.path.insert(0, str(ROOT / "engine" / "build"))
import kb_compiler  # noqa: E402 — path injected above

# (component_name, field_name) -> one-line reason it's legitimately never a literal
# substring anywhere in shell/web/frontend/src/lib. Add an entry ONLY after
# confirming (by reading the actual consumer) that the field's content really
# does reach the user some other way, or is genuinely internal/cross-component
# wiring that carries no independent display value — never to silence a real gap.
ALLOWLIST = {
    ("preparation", "document_checklist"): "Checklist.svelte's own preparation branch "
        "renders every preparation_plan field; data-table's second-renderer branch is "
        "intentionally empty (2026-07-11 audit) so it doesn't duplicate content. This "
        "entry exists only because 'document_checklist' as a literal string isn't in "
        "Checklist.svelte (it destructures the array directly) — the other four "
        "preparation_plan fields ARE literal substrings there already.",
    # Profile input facts other components read — the buyer's own answers, shown through
    # the components that reason on them, not echoed as a profile row (behavior 30, each
    # consumer read 2026-10-08).
    ("buyer_profile", "off_title_parties"): "the off-title funders/partners list; "
        "fh_engine_family reads it into family_coordination (FamilyViewCard) and "
        "fh_engine_firb into firb_workflow's documents_outstanding.",
    ("investor_profile_foreign", "off_title_parties"): "same list as buyer_profile's; read "
        "by fh_engine_family (FamilyViewCard) and fh_engine_firb (documents_outstanding).",
    ("buyer_profile", "non_buying_partner"): "the derived couple-as-one read of "
        "off_title_parties; fh_engine_eligibility reads it for the partner income gate, "
        "shown through eligibility's applicable/rejected schemes.",
    ("buyer_profile", "existing_home_ownership"): "the current home's facts; "
        "fh_engine_existing_home_disposal reads it into existing_home_disposal "
        "(Calculator's net-proceeds view).",
    ("investor_profile_foreign", "established_property_eligible"): "a calendar fact of "
        "kb.firb.established-dwelling-ban; the same fact reaches the screen as "
        "firb_workflow.foreign_person_eligible (FirbWorkflowCard).",
    ("investor_profile_foreign", "new_build_only_constraint"): "the inverse of "
        "established_property_eligible; shown as firb_workflow.foreign_person_eligible.",
    ("investor_profile_foreign", "available_capital_aud_equivalent"): "an input read by "
        "fh_engine_cash (cash_position) and fh_engine_cross_border; reaches the screen as "
        "their cash figures.",
}

# Outcome fields the blueprint designs but the engine emits no value for yet (absent, or
# always null / []): reported as INVENTORY like UNBUILT_COMPONENTS — visible, not gated,
# never claimed to reach the user. Measured 2026-10-08 against engine src and live plans
# (behavior 30). Remove an entry the day its producer fills it — then it is a gap again
# until a renderer shows it.
UNBUILT_FIELDS = {
    ("investor_profile", "existing_portfolio"): "Mode-C-activated household portfolio; "
        "not emitted (investor-domestic-au.md defers it to the Mode-C wedge).",
    ("investor_profile", "ppor_equity_available_for_leverage"): "not emitted; deferred "
        "with existing_portfolio.",
    ("investor_profile", "traits"): "not emitted; deferred with existing_portfolio.",
    ("investor_profile_foreign", "experience_level"): "always null "
        "(fh_engine_fill.erl base fill; no capture turn yet).",
    ("investor_profile_foreign", "primary_investment_goal"): "always null; no capture yet.",
    ("investor_profile_foreign", "currency_volatility_concern"): "always null; no capture yet.",
    ("investor_profile_foreign", "vn_marginal_tax_rate"): "always null; no capture yet.",
    ("investment_strategy", "alignment_reasoning"): "always null "
        "(investment_strategy_conformance asserts it at base; no producer fills it).",
    ("eligibility", "structuring_options"): "always [] "
        "(fh_engine_eligibility.erl, multi-applicant refine-turn concern not built).",
}

# Components whose renderer is a documented, not-yet-built gap — reported separately as
# INVENTORY (visible, not silently dropped — [[no-silent-caps]]), never folded into
# ALLOWLIST: an allowlist entry claims "this field correctly reaches the user some other
# way," which is false here. property_assessment's `property_fit` outcome is confirmed
# (SummaryCard.svelte's own header comment, 2026-07-11) to render NOTHING by design —
# "per-property scope, no dedicated hero yet" — consistent with Phase-B property-attach
# itself being unbuilt for 4 of 5 modes (`supportsPhaseB` gates to investor-domestic-au
# only in PlanProjection.svelte). Remove an entry here the day its renderer ships.
UNBUILT_COMPONENTS = {
    "property_assessment": "Phase-B per-property hero not built yet (SummaryCard.svelte "
        "renders nothing for property_fit by design); property-attach itself is "
        "investor-domestic-au-only today.",
}


def load_tree():
    parts = []
    for p in LIB.rglob("*"):
        if p.suffix in (".svelte", ".ts") and p.is_file():
            parts.append(p.read_text())
    return "\n".join(parts)


field_inventory = set()


def check_blueprint(path, tree):
    slug, comps, _producer, _reads, _tabs = kb_compiler.parse_blueprint(path)
    gaps, inventory = [], []
    for c in comps:
        if not c.outcome_fields:
            continue
        if c.name in UNBUILT_COMPONENTS:
            inventory.append((slug, c.name))
            continue
        for field in c.outcome_fields:
            if field in tree:
                continue
            if (c.name, field) in ALLOWLIST:
                continue
            if (c.name, field) in UNBUILT_FIELDS:
                field_inventory.add((c.name, field))
                continue
            gaps.append((slug, c.name, field))
    return gaps, inventory


def main():
    tree = load_tree()
    all_gaps, all_inventory = [], []
    for path in sorted(BP.glob("*.md")):
        gaps, inventory = check_blueprint(path, tree)
        all_gaps.extend(gaps)
        all_inventory.extend(inventory)

    if all_inventory:
        seen = sorted(set(c for _, c in all_inventory))
        print(f"renderer_conformance: {len(all_inventory)} component instance(s) "
              f"skipped as documented-unbuilt (not gated, not silently dropped):")
        for c in seen:
            print(f"  {c}: {UNBUILT_COMPONENTS[c]}")
        print()

    if field_inventory:
        print(f"renderer_conformance: {len(field_inventory)} outcome field(s) skipped as "
              f"not-yet-produced (not gated, not silently dropped):")
        for key in sorted(field_inventory):
            print(f"  {key[0]}.{key[1]}: {UNBUILT_FIELDS[key]}")
        print()

    if not all_gaps:
        print(f"renderer_conformance: OK — every gated outcome field is referenced "
              f"somewhere in shell/web/frontend/src/lib, across "
              f"{len(list(BP.glob('*.md')))} blueprints.")
        return 0

    print(f"renderer_conformance: {len(all_gaps)} unexplained field gap(s):\n")
    for slug, comp, field in all_gaps:
        print(f"  {slug} :: {comp} -> outcome field {field!r} never appears "
              f"anywhere in shell/web/frontend/src/lib")
    print(
        "\nEach gap means: the blueprint declares this field in the component's "
        "Outcome schema, but no shell frontend file contains that field name "
        "anywhere — so a real value the engine fills can never reach the screen. "
        "Either a renderer/shell file needs a branch for this shape (see "
        "docs/blueprints/*.md for the field's meaning), or — if the field "
        "genuinely carries no independent display value — add a one-line "
        "ALLOWLIST entry explaining why."
    )
    return 1


if __name__ == "__main__":
    sys.exit(main())
