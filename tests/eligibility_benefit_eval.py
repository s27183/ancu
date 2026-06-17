#!/usr/bin/env python3
"""Eligibility base-benefit eval harness — Decision 8 (quantitative-where-grounded).

Companion to `cash_duty_eval.py`. Where that harness checks the duty FORMULA, this one
checks how `fh_engine_eligibility` QUANTIFIES each scheme's base `benefit_value` as a
`money_range` from `target_price_range` (docs/architecture/eligibility-resolution.md §8):

  - state duty concession → the saving at each price endpoint, via the SAME duty kernel
    cash_position uses (one computer per figure — this harness imports cash_duty_eval, it
    does not re-implement duty). Ordered [min, max]; the saving tapers as price rises.
  - FHG → LMI-avoided INDICATIVE band (estimate): 5% deposit ⇒ 95% LVR ⇒ the 91-95 band
    of kb.lmi.calculation; premium ≈ rate × (95% of price), floored at the insurer minimum.
  - FHOG → fixed grant, conditional on a new build ⇒ [0, amount] at base.
  - FHSS / Help-to-Buy → null at base (needs income/contributions; equity is not a saving).
  - total_benefit_value → sum over the COMPATIBLE stack (the null-benefit schemes drop out).

The anchors are the ground truth; the SAME anchors are asserted against the Erlang
`fh_engine_eligibility:fill` by engine/erlang/test/eligibility_benefit_conformance.escript,
so the two implementations are locked to each other. The duty endpoints trace to the
official revenue-office figures already locked in cash_duty_eval. Run from repo root.
"""

import json
import math
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
ARTIFACT = ROOT / "engine" / "erlang" / "priv" / "kb" / "artifact.json"
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import cash_duty_eval as cd  # noqa: E402  — the shared duty kernel (one computer)


def _eround(x):
    """Erlang round/1 for non-negatives: round half up (floor(x + 0.5))."""
    return math.floor(x + 0.5)


# --- the benefit computations (mirror fh_engine_eligibility) -----------------

def duty_saving_range(artifact, state, lo, hi):
    slo = cd.stamp_duty(artifact, state, True, lo)["concession_applied"]
    shi = cd.stamp_duty(artifact, state, True, hi)["concession_applied"]
    return sorted([slo, shi])


def lmi_avoided_range(artifact, lo, hi):
    cj = cd._kb(artifact, "kb.lmi.calculation")
    entries = cj["lookup"]["indicative_premium_by_lvr_band"]["entries"]
    band = next(e for e in entries if e["lvr_band"] == "91-95")
    rate_lo = band["indicative_rate_pct_of_loan_low"]
    rate_hi = band["indicative_rate_pct_of_loan_high"]
    minp = cj["parameters"]["min_premium_aud_qbe"]["value"]
    plo = max(minp, _eround(rate_lo / 100 * _eround(0.95 * lo)))
    phi = max(minp, _eround(rate_hi / 100 * _eround(0.95 * hi)))
    return sorted([plo, phi])


_FHOG_SLUG = {"NSW": "kb.scheme.nsw.fhog", "VIC": "kb.scheme.vic.fhog"}


def fhog_amount(artifact, state):
    fills = cd._kb(artifact, _FHOG_SLUG[state])["fills"]
    f = next(x for x in fills if x.get("leaf") == "eligibility.fhog.amount")
    return f["rule"]["value"]


def compute(artifact, state, lo, hi):
    duty = duty_saving_range(artifact, state, lo, hi)
    fhg = lmi_avoided_range(artifact, lo, hi)
    fhog = [0, fhog_amount(artifact, state)]
    # compatible stack: the null-benefit schemes (FHSS, Help-to-Buy) drop out of the total.
    total = [duty[0] + fhg[0] + fhog[0], duty[1] + fhg[1] + fhog[1]]
    return {"deposit_guarantee": fhg, "stamp_duty_concession": duty, "grant": fhog,
            "deposit_savings": None, "shared_equity": None, "total": total}


# --- anchors: expected benefit ranges (ground truth) ------------------------
# (state, [lo, hi], expected) — expected duty endpoints trace to cash_duty_eval's
# official figures; FHG is the indicative LMI band; FHOG the fixed grant.
CASES = [
    # VIC East-Melbourne — the live screenshot case. Duty $31,070 @600k → $0 @750k
    # (phase-out; $700k = $12,357 in cash_duty_eval). FHG LMI 2.5–4.0% of ~95% loan.
    ("VIC", [600000, 750000], {
        "deposit_guarantee": [14250, 28500],
        "stamp_duty_concession": [0, 31070],
        "grant": [0, 10000],
        "deposit_savings": None,
        "shared_equity": None,
        "total": [14250, 69570],
    }),
    # NSW — FHBAS straddle [750k below exemption $800k, 900k in the $800k–$1M band].
    ("NSW", [750000, 900000], {
        "deposit_guarantee": [17813, 34200],
        "stamp_duty_concession": [15206, 28162],
        "grant": [0, 10000],
        "deposit_savings": None,
        "shared_equity": None,
        "total": [33019, 72362],
    }),
]


def main():
    if not ARTIFACT.is_file():
        print(f"FAIL — artifact not found: {ARTIFACT.relative_to(ROOT)} "
              f"(run engine/build/kb_compiler.py first)")
        return 2
    artifact = json.loads(ARTIFACT.read_text())
    fails = []
    for state, (lo, hi), expected in CASES:
        got = compute(artifact, state, lo, hi)
        if got != expected:
            fails.append(f"{state} [{lo},{hi}]:\n    got      {got}\n    expected {expected}")
    if fails:
        print(f"FAIL — {len(fails)}/{len(CASES)} benefit cases failed:")
        for f in fails:
            print(f"  {f}")
        return 1
    print(f"PASS — all {len(CASES)} eligibility base-benefit cases green "
          f"(duty via the shared kernel, FHG LMI band, FHOG fixed, total over the compatible stack).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
