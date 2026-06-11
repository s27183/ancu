#!/usr/bin/env python3
"""Cash stamp-duty eval harness — the duty-mechanics detector (mechanism B).

Companion to `resolver_eval.py`. Where that harness checks the declarative
resolver (mechanism A), this one checks the per-component FORMULA code (mechanism
B) that composes the statutory transfer-duty scale with the eligible first-home
concession into `cash_position.stamp_duty.{before_concession, concession_applied,
after_concession}`. Design + derivation: `docs/architecture/stamp-duty-concession-
mechanics.md`.

It carries a reference implementation of the shared `duty(V, scale)` marginal
kernel + the three per-state taper functions, reading the bracket/threshold data
from the emitted artifact (`kb.stamp-duty.calc-by-state`, the three scheme docs) —
exactly the data the Erlang `fh_engine_cash` reads. It then asserts each computed
figure against the **official revenue-office calculator output** at named anchors
(NSW $850k → after $9,853 / saving $22,809; VIC $700k → $24,713 / $12,357; QLD
$730k → $6,555). That postcondition match is the correctness criterion for these
regulated figures — not the algebra in isolation.

The same anchors are asserted against `fh_engine_cash` by
`engine/erlang/test/cash_duty_conformance.escript`, so the two implementations are
locked together AND to the ground truth. Run from repo root.
"""

import json
import math
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
ARTIFACT = ROOT / "engine" / "erlang" / "priv" / "kb" / "artifact.json"


# --- artifact access (same data fh_engine_cash reads) -----------------------

def _kb(artifact, slug):
    return artifact["kb"][slug]["content_json"]


def _scale(artifact, name):
    return _kb(artifact, "kb.stamp-duty.calc-by-state")["lookup"][name]


def _param_money(artifact, slug, key):
    return _kb(artifact, slug)["parameters"][key]["value"]


# --- the shared marginal-bracket kernel (mechanics §3) ----------------------

def _roundup100(x):
    return 0 if x <= 0 else ((x + 99) // 100) * 100


def _bracket_for(v, entries):
    for e in entries:
        ub = e["upper_bound"]
        if ub is None or v <= ub:
            return e
    raise ValueError(f"no bracket for {v}")


def duty(artifact, v, scale_name):
    scale = _scale(artifact, scale_name)
    entries = scale["entries"]
    rounds = scale.get("rounds_marginal_to_part_of_100", False)
    b = _bracket_for(v, entries)
    ct = b["calc_type"]
    if ct == "nil":
        raw = 0
    elif ct == "flat_on_total":
        raw = b["flat_rate_pct"] * v / 100
    elif ct == "marginal":
        excess = v - b["lower_bound"]
        if rounds:
            excess = _roundup100(excess)
        raw = b["base_duty"] + b["marginal_rate_pct"] * excess / 100
    else:
        raise ValueError(f"unknown calc_type {ct}")
    return max(raw, b.get("min_duty", 0))


# --- the three per-state taper functions (mechanics §3) ---------------------

def nsw_after(artifact, v):
    ex = _param_money(artifact, "kb.scheme.nsw.fhbas", "home_exemption_threshold")
    cap = _param_money(artifact, "kb.scheme.nsw.fhbas", "home_concession_cap")
    if v <= ex:
        return 0
    if v < cap:
        return duty(artifact, v, "nsw_standard_scale") \
            - duty(artifact, ex, "nsw_standard_scale") * (cap - v) / (cap - ex)
    return duty(artifact, v, "nsw_standard_scale")


def vic_after(artifact, v):
    ex = _param_money(artifact, "kb.scheme.vic.fhb-duty", "exemption_threshold")
    cap = _param_money(artifact, "kb.scheme.vic.fhb-duty", "concession_cap")
    if v <= ex:
        return 0
    if v <= cap:
        return duty(artifact, v, "vic_general_scale") * (v - ex) / (cap - ex)
    return duty(artifact, v, "vic_general_scale")


def _fhc_amount(artifact, v):
    entries = _kb(artifact, "kb.scheme.qld.fhc")["lookup"]["first_home_concession_amount"]["entries"]
    for e in entries:
        mx = e["max_value"]
        if mx is None or v <= mx:
            return e["amount"]
    raise ValueError(f"no fhc band for {v}")


def qld_after(artifact, v):
    cap = _param_money(artifact, "kb.scheme.qld.fhc", "value_cap")
    if v <= cap:
        return max(0, duty(artifact, v, "qld_home_concession_scale") - _fhc_amount(artifact, v))
    return duty(artifact, v, "qld_standard_scale")


_TAPER = {"NSW": nsw_after, "VIC": vic_after, "QLD": qld_after}
_STD = {"NSW": "nsw_standard_scale", "VIC": "vic_general_scale", "QLD": "qld_standard_scale"}


def _dollars(x):
    return 0 if x <= 0 else math.floor(x + 0.5)  # round half up; identical in Erlang


def stamp_duty(artifact, state, has_conc, v):
    before = _dollars(duty(artifact, v, _STD[state]))
    after = _dollars(_TAPER[state](artifact, v)) if has_conc else before
    return {"before_concession": before, "concession_applied": before - after,
            "after_concession": after}


# --- anchors: the verified official-calculator outputs (ground truth) -------

# duty() kernel checks — bracket mechanics, the VIC flat-on-total quirk, the NSW min.
KERNEL_CASES = [
    # (scale, value, expected_duty)  — expected rounded to the dollar via _dollars
    ("nsw_standard_scale", 800000, 30412),   # calc-by-state.md anchor
    ("nsw_standard_scale", 1000, 20),        # below the $20 minimum → min applies
    ("vic_general_scale", 700000, 37070),    # calc-by-state.md anchor
    ("vic_general_scale", 1500000, 82500),   # the $960k–$2M flat-on-total quirk (5.5% of whole)
    ("qld_standard_scale", 600000, 20025),   # calc-by-state.md anchor
    ("qld_home_concession_scale", 730000, 18700),  # QRO worked example
    ("qld_home_concession_scale", 700000, 17350),  # = max first-home amount (zeroes the duty)
]

# stamp_duty() checks — (state, has_conc, value, before, saving, after)
DUTY_CASES = [
    # NSW FHBAS — phase-out
    ("NSW", True,  850000, 32662, 22809, 9853),   # official: saving $22,809; duty ≈ $10k
    ("NSW", True,  900000, 34912, 15206, 19706),
    ("NSW", True,  800000, 30412, 30412, 0),      # exemption boundary
    ("NSW", True,  750000, 28162, 28162, 0),      # below exemption
    ("NSW", True,  1000000, 39412, 0, 39412),     # at cap → no concession
    ("NSW", False, 850000, 32662, 0, 32662),      # concession not granted → full duty
    # VIC FHB duty — phase-in
    ("VIC", True,  700000, 37070, 12357, 24713),  # SRO worked example, exact
    ("VIC", True,  650000, 34070, 22713, 11357),  # cross-check: ~$11k payable
    ("VIC", True,  600000, 31070, 31070, 0),      # exemption boundary
    ("VIC", True,  750000, 40070, 0, 40070),      # at cap → concession tapers to 0
    # QLD FHC — second scale minus stepped table
    ("QLD", True,  730000, 25875, 19320, 6555),   # QRO worked example, exact
    ("QLD", True,  700000, 24525, 24525, 0),      # = $24,525 max saving (full exemption via floor)
    ("QLD", True,  800000, 29025, 7175, 21850),   # cap boundary — FHC still applies (home-conc rate)
    ("QLD", True,  850000, 31275, 0, 31275),      # above cap → standard duty (no first-home)
]


def main():
    if not ARTIFACT.is_file():
        print(f"FAIL — artifact not found: {ARTIFACT.relative_to(ROOT)} "
              f"(run engine/build/kb_compiler.py first)")
        return 2
    artifact = json.loads(ARTIFACT.read_text())
    fails = []

    for scale, v, expected in KERNEL_CASES:
        got = _dollars(duty(artifact, v, scale))
        if got != expected:
            fails.append(f"duty({scale}, {v}) = {got}, expected {expected}")

    for state, hc, v, before, saving, after in DUTY_CASES:
        got = stamp_duty(artifact, state, hc, v)
        exp = {"before_concession": before, "concession_applied": saving,
               "after_concession": after}
        if got != exp:
            fails.append(f"stamp_duty({state}, has_conc={hc}, {v}) = {got}, expected {exp}")

    total = len(KERNEL_CASES) + len(DUTY_CASES)
    if fails:
        print(f"FAIL — {len(fails)}/{total} cash-duty checks failed:")
        for f in fails:
            print(f"  {f}")
        return 1
    print(f"PASS — all {total} cash-duty checks green "
          f"({len(KERNEL_CASES)} kernel + {len(DUTY_CASES)} stamp_duty), "
          f"matching the official revenue-office figures.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
