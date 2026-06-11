#!/usr/bin/env python3
"""Ownership-planning eval harness — the ongoing-costs detector (mechanism B).

Companion to `cash_duty_eval.py`. Same class of check (per-component FORMULA code,
mechanism B), but the VERIFICATION DISCIPLINE DIFFERS: ongoing costs are KB-curated
INDICATIVE estimates, not regulated figures with an official calculator. So the
ground truth here is the **KB parameters themselves** (the SOT the artifact emits) +
the stated arithmetic — NOT an external calculator. The one regulated postcondition
is the PPOR land-tax exemption status. Design: `docs/architecture/ongoing-costs-
projection.md`.

It carries a reference implementation of the `ownership_planning` base-turn formulas
(maintenance reserve, the council+water statutory band, the graduation LVR target,
the per-state land-tax thresholds, the land-tax status derivation, FHG detection),
reading the same KB params the Erlang `fh_engine_ownership` reads. The same anchors
are asserted against `fh_engine_ownership` by
`engine/erlang/test/ownership_conformance.escript`, locking the two implementations
to each other and to the KB SOT. Run from repo root.
"""

import json
import math
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
ARTIFACT = ROOT / "engine" / "erlang" / "priv" / "kb" / "artifact.json"


# --- artifact access (same data fh_engine_ownership reads) ------------------

def _param(artifact, slug, key):
    return artifact["kb"][slug]["content_json"]["parameters"][key]["value"]


def _dollars(x):
    return 0 if x <= 0 else math.floor(x + 0.5)  # round half up; identical in Erlang


# --- the base-turn formulas (projection §3) ---------------------------------

def maintenance_target(artifact, v):
    if v is None:
        return None
    pct = _param(artifact, "kb.maintenance.budget-by-property-type",
                 "reserve_pct_of_value_default")
    return _dollars(pct * v / 100)


def statutory_band(artifact):
    slug = "kb.ongoing-costs.rates-water-strata"
    return {
        "low": _param(artifact, slug, "council_rates_indicative_aud_year_low")
        + _param(artifact, slug, "water_indicative_aud_year_low"),
        "high": _param(artifact, slug, "council_rates_indicative_aud_year_high")
        + _param(artifact, slug, "water_indicative_aud_year_high"),
    }


def graduation_target_lvr(artifact):
    return _param(artifact, "kb.graduation.lvr80", "graduation_lvr_threshold_pct")


_LAND_TAX_KEY = {"NSW": "nsw_general_threshold_aud",
                 "VIC": "vic_threshold_aud",
                 "QLD": "qld_threshold_individual_aud"}


def land_tax_threshold(artifact, state):
    return _param(artifact, "kb.land-tax.ppor-exemption", _LAND_TAX_KEY[state])


def land_tax_check(artifact, intent):
    if intent == "owner_occupier":
        return "exempt_ppor" if _param(
            artifact, "kb.land-tax.ppor-exemption", "ppor_exempt_all_states") \
            else "to_verify"
    return "applicable"


def has_fhg(stack):
    return any(s.get("role") == "deposit_guarantee"
               for s in stack.get("applicable_schemes", []))


# --- anchors: ground truth = the KB params (the SOT), not a calculator ------

# maintenance reserve = 1% of value at the ceiling, round half up.
MAINT_CASES = [
    (700000, 7000),
    (1000000, 10000),
    (650000, 6500),
    (None, None),
]

# the council+water statutory band (council 1200-2500 + water 800-1400).
BAND_EXPECTED = {"low": 2000, "high": 3900}

# graduation LVR milestone.
LVR_EXPECTED = 80

# per-state land-tax thresholds (regulated figures carried from KB).
THRESHOLD_CASES = [("NSW", 1075000), ("VIC", 50000), ("QLD", 600000)]

# land-tax status derivation (the regulated postcondition).
LAND_TAX_CASES = [("owner_occupier", "exempt_ppor"), ("investor", "applicable")]

# FHG detection from the eligibility scheme_stack (by role, the stable key).
FHG_CASES = [
    ({"applicable_schemes": [{"role": "deposit_guarantee"}, {"role": "grant"}]}, True),
    ({"applicable_schemes": [{"role": "deposit_savings"}, {"role": "grant"}]}, False),
    ({}, False),
]


def main():
    if not ARTIFACT.is_file():
        print(f"FAIL — artifact not found: {ARTIFACT.relative_to(ROOT)} "
              f"(run engine/build/kb_compiler.py first)")
        return 2
    artifact = json.loads(ARTIFACT.read_text())
    fails = []

    for v, expected in MAINT_CASES:
        got = maintenance_target(artifact, v)
        if got != expected:
            fails.append(f"maintenance_target({v}) = {got}, expected {expected}")

    band = statutory_band(artifact)
    if band != BAND_EXPECTED:
        fails.append(f"statutory_band = {band}, expected {BAND_EXPECTED}")

    lvr = graduation_target_lvr(artifact)
    if lvr != LVR_EXPECTED:
        fails.append(f"graduation_target_lvr = {lvr}, expected {LVR_EXPECTED}")

    for state, expected in THRESHOLD_CASES:
        got = land_tax_threshold(artifact, state)
        if got != expected:
            fails.append(f"land_tax_threshold({state}) = {got}, expected {expected}")

    for intent, expected in LAND_TAX_CASES:
        got = land_tax_check(artifact, intent)
        if got != expected:
            fails.append(f"land_tax_check({intent}) = {got}, expected {expected}")

    for stack, expected in FHG_CASES:
        got = has_fhg(stack)
        if got != expected:
            fails.append(f"has_fhg({stack}) = {got}, expected {expected}")

    total = (len(MAINT_CASES) + 1 + 1 + len(THRESHOLD_CASES)
             + len(LAND_TAX_CASES) + len(FHG_CASES))
    if fails:
        print(f"FAIL — {len(fails)}/{total} ownership checks failed:")
        for f in fails:
            print(f"  {f}")
        return 1
    print(f"PASS — all {total} ownership checks green "
          f"(maintenance + band + LVR + land-tax thresholds/status + FHG detection), "
          f"matching the KB params (the SOT).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
