#!/usr/bin/env python3
"""Mortgage-finance eval harness — the two-path structural + §98 detector.

Companion to `ownership_eval.py` / `cash_duty_eval.py`, but `mortgage_finance` is a
TWO-PATH component (mortgage-finance-two-path.md): the resolver assembles the figures
+ loan-path structure, the agent authors only the two `lender_fit` leaves, and Erlang
merges. At the BASE turn income + debts are absent, so every figure is honestly
PENDING — there is no computed number to verify. So this harness checks the STRUCTURE
and the §98 boundary, not arithmetic:

  - the loan-path structure (recommended_path from FHG presence; P&I default);
  - the honest-partial PENDING fields (capacity null, debt-optimisations empty);
  - the §98 postcondition — the agent's output schema (LenderFitLeaves) carries NO
    money/number field, so the LLM structurally cannot author a capacity figure;
  - the slot-scoped merge — folding the two agent leaves changes ONLY those two slots,
    leaving every figure byte-identical (the LLM cannot move a figure).

The same anchors are asserted against `fh_engine_mortgage` by
`engine/erlang/test/mortgage_conformance.escript`, locking the two implementations to
each other. Run from repo root.
"""

import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
ARTIFACT = ROOT / "engine" / "erlang" / "priv" / "kb" / "artifact.json"


# --- artifact access (same data fh_engine_mortgage reads) -------------------

def _param(artifact, slug, key):
    return artifact["kb"][slug]["content_json"]["parameters"][key]["value"]


# --- the resolver structure (mortgage-finance-two-path.md §5) ----------------

def has_fhg(stack):
    return any(s.get("role") == "deposit_guarantee"
               for s in stack.get("applicable_schemes", []))


def recommended_path(stack):
    return "fhg_backed" if has_fhg(stack) else None


def merge_agent(resolver_outcome, agent_values):
    """Mirror fh_engine_mortgage:merge_agent/2 — slot-scoped: fold the two agent
    leaves into their outcome slots, touching nothing else."""
    out = dict(resolver_outcome)
    out["recommended_lender_shortlist"] = agent_values.get(
        "recommended_lender_shortlist", [])
    ls = dict(out["loan_structure_recommendation"])
    ls["rate"] = agent_values.get("fixed_vs_variable")
    out["loan_structure_recommendation"] = ls
    return out


# --- the §98 schema postcondition (import the agent's output model) ----------

def lender_fit_schema_has_no_number():
    """The agent's output schema must contain no number-typed field (so the LLM
    cannot author a figure). Inspect LenderFitLeaves' JSON schema."""
    sys.path.insert(0, str(ROOT / "engine" / "python"))
    from planner import LenderFitLeaves  # noqa: E402
    schema = LenderFitLeaves.model_json_schema()
    bad = []
    _walk_for_numbers(schema, schema.get("$defs", {}), bad, path="LenderFitLeaves")
    return bad


def _walk_for_numbers(node, defs, bad, path):
    if not isinstance(node, dict):
        return
    t = node.get("type")
    if t in ("number", "integer"):
        bad.append(path)
    if "$ref" in node:
        name = node["$ref"].split("/")[-1]
        _walk_for_numbers(defs.get(name, {}), defs, bad, path + "->" + name)
    for key in ("items", "additionalProperties"):
        if key in node:
            _walk_for_numbers(node[key], defs, bad, path + "." + key)
    for pname, pschema in node.get("properties", {}).items():
        _walk_for_numbers(pschema, defs, bad, path + "." + pname)
    for variant in node.get("anyOf", []) + node.get("allOf", []):
        _walk_for_numbers(variant, defs, bad, path)


# --- anchors -----------------------------------------------------------------

STACK_FHG = {"applicable_schemes": [{"role": "deposit_guarantee"}, {"role": "grant"}]}
STACK_NO_FHG = {"applicable_schemes": [{"role": "deposit_savings"}, {"role": "grant"}]}

PATH_CASES = [(STACK_FHG, "fhg_backed"), (STACK_NO_FHG, None), ({}, None)]
FHG_CASES = [(STACK_FHG, True), (STACK_NO_FHG, False), ({}, False)]

# a representative resolver outcome (base turn: every figure PENDING).
RESOLVER_OUTCOME = {
    "recommended_path": "fhg_backed",
    "expected_borrowing_capacity": None,
    "debt_optimisations_to_action": [],
    "recommended_lender_shortlist": None,
    "loan_structure_recommendation": {
        "type": "principal_and_interest", "rate": None, "offset": None},
    "pre_approval_action_plan": ["step a", "step b"],
    "pre_approval_expiry": None,
    "reapplication_required": False,
    "key_assumptions": ["APRA buffer", "conventions", "pending income/debts"],
}
AGENT_VALUES = {
    "recommended_lender_shortlist": [
        {"lender": "A major (FHG panel)", "reasoning": "wide panel",
         "approval_likelihood": "indicative"}],
    "fixed_vs_variable": "variable",
}


def main():
    if not ARTIFACT.is_file():
        print(f"FAIL — artifact not found: {ARTIFACT.relative_to(ROOT)} "
              f"(run engine/build/kb_compiler.py first)")
        return 2
    artifact = json.loads(ARTIFACT.read_text())
    fails = []
    n = 0

    # the one regulated constant is present in KB (the buffer the assumptions cite).
    n += 1
    buffer_pp = _param(artifact, "kb.lender.serviceability-basics",
                       "apra_serviceability_buffer_pp")
    if buffer_pp != 3.0:
        fails.append(f"apra_serviceability_buffer_pp = {buffer_pp}, expected 3.0")

    for stack, expected in PATH_CASES:
        n += 1
        got = recommended_path(stack)
        if got != expected:
            fails.append(f"recommended_path({stack}) = {got!r}, expected {expected!r}")

    for stack, expected in FHG_CASES:
        n += 1
        got = has_fhg(stack)
        if got != expected:
            fails.append(f"has_fhg({stack}) = {got}, expected {expected}")

    # §98: the agent's schema carries no number field.
    n += 1
    bad = lender_fit_schema_has_no_number()
    if bad:
        fails.append(f"§98 BREACH — LenderFitLeaves has number field(s): {bad}")

    # merge is slot-scoped: only the two slots change; every figure byte-identical.
    merged = merge_agent(RESOLVER_OUTCOME, AGENT_VALUES)
    checks = {
        "merge places shortlist":
            merged["recommended_lender_shortlist"]
            == AGENT_VALUES["recommended_lender_shortlist"],
        "merge places rate":
            merged["loan_structure_recommendation"]["rate"] == "variable",
        "merge leaves capacity null":
            merged["expected_borrowing_capacity"] is None,
        "merge leaves debt-optimisations empty":
            merged["debt_optimisations_to_action"] == [],
        "merge leaves recommended_path unchanged":
            merged["recommended_path"] == RESOLVER_OUTCOME["recommended_path"],
        "merge leaves key_assumptions unchanged":
            merged["key_assumptions"] == RESOLVER_OUTCOME["key_assumptions"],
        "merge leaves loan_structure.type unchanged":
            merged["loan_structure_recommendation"]["type"]
            == "principal_and_interest",
    }
    for label, ok in checks.items():
        n += 1
        if not ok:
            fails.append(label)

    if fails:
        print(f"FAIL — {len(fails)}/{n} mortgage checks failed:")
        for f in fails:
            print(f"  {f}")
        return 1
    print(f"PASS — all {n} mortgage checks green "
          f"(loan-path structure + honest-partial PENDING + §98 no-number schema + "
          f"slot-scoped merge).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
