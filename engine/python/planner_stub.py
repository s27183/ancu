#!/usr/bin/env python3
"""FirstHomey planning sidecar — STUB (Wedge-1a #8, slice 1).

A stateless, disposable sidecar (principle 3): full context in on stdin, JSON-RPC
events out on stdout, exit. This stub proves the Erlang<->Python seam WITHOUT an LLM
(ablation: isolate transport/lifecycle from reasoning). Given a `run_base_turn`
request it emits one `component_filled` per Mode-A base-scope component with a
schema-shaped canned outcome, then `turn_completed`, then exits.

Slice 2 replaces this with the real planner: load blueprint + KB from the compiled
artifact, build the dynamic system prompt from current plan-card state (constraint
#9), run the resolver/agent two-path fill via the Anthropic SDK, validate each
outcome against its outcome_schema (Pydantic), and emit `usage` per LLM-call.

Wire framing: 4-byte big-endian length prefix + UTF-8 JSON (Erlang port {packet,4}).
"""

import json
import struct
import sys


def _readn(n):
    buf = b""
    while len(buf) < n:
        chunk = sys.stdin.buffer.read(n - len(buf))
        if not chunk:
            return None
        buf += chunk
    return buf


def read_frame():
    header = _readn(4)
    if header is None:
        return None
    (length,) = struct.unpack(">I", header)
    body = _readn(length)
    if body is None:
        return None
    return json.loads(body.decode("utf-8"))


def write_frame(obj):
    data = json.dumps(obj).encode("utf-8")
    sys.stdout.buffer.write(struct.pack(">I", len(data)))
    sys.stdout.buffer.write(data)
    sys.stdout.buffer.flush()


def notify(method, params):
    write_frame({"method": method, "params": params})


# Mode-A base-scope components, in pipeline order (fhb-domestic-au.md §"Component
# scope"): buyer_profile -> eligibility -> mortgage_finance -> cash_position ->
# ownership_planning. Outcomes are schema-shaped fixtures, not real planning — they
# exist to prove the renderer/outcome contract end to end.
COMPONENTS = [
    {
        "component_id": "buyer_profile",
        "scope": "base",
        "renderer": "summary-card",
        "fill_path": "agent",
        "kb_versions": [{"slug": "kb.hecs.thresholds"}],
        "outcome": {
            "applicants": [{
                "role": "primary", "citizenship_status": "citizen",
                "firb_required": False, "owner_occupier_intent": True,
                "ever_owned_au_property": False,
            }],
            "applicant_count": 1,
            "firb_required_any": False,
            "intended_occupancy_use": "sole_occupier",
            "assessable_income": 95000,
            "approx_borrowing_capacity": [480000, 540000],
            "deposit_ready_for_purchase_amount": 65000,
            "target_price_range": [600000, 700000],
            "target_zone": ["Cabramatta", "Canley Vale"],
            "key_constraints": ["HECS balance reduces borrowing capacity"],
            "key_strengths": ["Stable PAYG income",
                              "First home buyer — full scheme access"],
        },
    },
    {
        "component_id": "eligibility",
        "scope": "both",
        "renderer": "scheme-stack-card",
        "fill_path": "resolver",
        "kb_versions": [{"slug": "kb.scheme.fhg"}, {"slug": "kb.scheme.fhss"}],
        "outcome": {
            "applicable_schemes": [
                {"name": "First Home Guarantee", "benefit_value": 0,
                 "role": "deposit_support", "notes": "5% deposit, LMI waived"},
                {"name": "FHSS", "benefit_value": 4200,
                 "role": "deposit_boost", "notes": "tax-advantaged release"},
            ],
            "rejected_schemes": [
                {"name": "Help to Buy", "reason": "scheme places allocated"},
            ],
            "eligibility_basis": "all_applicants_eligible",
            "structuring_options": [],
            "total_benefit_value": 4200,
            "stacking_constraints": [
                "FHG cannot combine with FHOG on established dwellings"],
            "recommended_application_order": [
                "FHSS release request", "FHG slot reservation"],
        },
    },
    {
        "component_id": "mortgage_finance",
        "scope": "both",
        "renderer": "summary-card",
        "fill_path": "agent",
        "kb_versions": [{"slug": "kb.lender.serviceability-basics"}],
        "outcome": {
            "recommended_path": "fhg_backed",
            "expected_borrowing_capacity": [480000, 540000],
            "debt_optimisations_to_action": [
                {"action": "Reduce credit card limit to $2k",
                 "expected_uplift": 15000, "urgency": "before_application"}],
            "recommended_lender_shortlist": [
                {"lender": "Lender A (FHG panel)",
                 "reasoning": "lenient HECS treatment",
                 "approval_likelihood": "high"}],
            "loan_structure_recommendation": {
                "type": "principal_and_interest", "rate": "variable",
                "offset": True},
            "pre_approval_action_plan": ["Gather 2 recent payslips", "NOA"],
            "pre_approval_expiry": None,
            "reapplication_required": False,
            "key_assumptions": ["APRA buffer +3%", "income stable PAYG"],
        },
    },
    {
        "component_id": "cash_position",
        "scope": "both",
        "renderer": "calculator",
        "fill_path": "resolver",
        "kb_versions": [{"slug": "kb.stamp-duty.calc-by-state"}],
        "outcome": {
            "max_property_price_supported": 690000,
            "actual_property_price": None,
            "total_cash_required": 52000,
            "cash_available": 65000,
            "gap_or_surplus": 13000,
            "verdict": "surplus",
            "genuine_savings_verdict": "meets",
            "mitigation_options_if_short": [],
            "key_assumptions": ["5% deposit via FHG", "3 months reserve buffer"],
        },
    },
    {
        "component_id": "ownership_planning",
        "scope": "both",
        "renderer": "data-table",
        "fill_path": "resolver",
        "kb_versions": [{"slug": "kb.land-tax.ppor-exemption"}],
        "outcome": {
            "monthly_obligations": {
                "mortgage_principal_and_interest": 2600, "utilities": 250},
            "annual_obligations": {
                "council_rates": 1800, "insurance": 1400,
                "land_tax_check": "exempt_ppor"},
            "maintenance_reserve_annual": 6500,
            "alert_triggers": [
                {"type": "lvr_graduation", "estimated_years": 4},
                {"type": "refinance_review", "cadence_months": 24}],
            "key_assumptions": ["1% of value maintenance reserve"],
        },
    },
]


def main():
    request = read_frame()
    if request is None:
        return
    params = request.get("params", {})
    plan_card_id = params.get("plan_card_id")
    for component in COMPONENTS:
        notify("component_filled", {
            "component_id": component["component_id"],
            "scope": component["scope"],
            "renderer": component["renderer"],
            "fill_path": component["fill_path"],
            "kb_versions": component["kb_versions"],
            "outcome": component["outcome"],
        })
    notify("turn_completed", {"plan_card_id": plan_card_id})


if __name__ == "__main__":
    main()
