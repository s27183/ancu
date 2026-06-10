#!/usr/bin/env python3
"""Resolver eval harness — the rule-semantics detector (grounding-checklist §1 / #6).

The compiler ([`engine/build/kb_compiler.py`]) validates that every `content_json`
rule *references* real registry fields and that each `leaf` maps to a real slot —
structure and reference integrity. It never *executes* a rule. That is the blind
spot §1 names "rule *semantics*": a rule can reference all-valid fields and still
compute the wrong outcome. F13 is the open instance — FHSS is an **individual**
scheme, but its eligibility is modelled as one joint bool with ∀-over-applicants
semantics, so a household where one of two applicants qualifies reads as ineligible
rather than "one applicant releases".

This harness closes that class. It carries a small **reference resolver** that
interprets the emitted artifact's `content_json` rules (criteria / lookup /
parameter) against worked-example fact-sets and asserts each computed outcome leaf
against an expected value drawn from the KB prose (the ground truth). A mismatch
surfaces a rule-semantics bug. The reference resolver also doubles as the executable
spec the engine's production resolver (Python sidecar / Erlang) must conform to —
when that lands, this becomes its conformance suite.

It binds to the **materialized artifact** (`engine/erlang/priv/kb/artifact.json`),
not re-parsed docs — the same ground the engine loads (reason-from-materialized-ground).

Applicant semantics: a criteria rule is evaluated PER APPLICANT and ∀-combined into
the joint leaf — the §11.9 `applicant.*` repoint's modelled semantics ("all
applicants eligible"; conservative and correct for a single applicant). F13 is
precisely where ∀ is the wrong collapse for an individual scheme.

Known-open findings carry an `xfail` marker (the finding id):
  - an xfail case that still mismatches  → confirmed-open gap; does NOT fail the run.
  - an xfail case that now MATCHES        → surfaced loudly as the finding's close-signal.
  - a non-xfail mismatch (or resolver error) → hard failure (exit 1).

Run: `python3 tests/resolver_eval.py`  (no artifact write; pure read + assert).
"""
import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
ARTIFACT = ROOT / "engine" / "erlang" / "priv" / "kb" / "artifact.json"


class ResolverError(Exception):
    """A rule could not be evaluated (malformed rule, unresolved ref). Hard failure."""


# --------------------------------------------------------------------------- #
# Reference resolver — interprets content_json rules against a fact-set.
#
# Fact-set shape (a worked example supplies it):
#   {
#     "applicants": [ {<applicant.* field>: value, ...}, ... ],   # 1..N
#     "property_fit": {<field>: value, ...},                       # shared, namespaced
#     "profile":      {<field>: value, ...},                       # shared, namespaced
#     "locals":  {<resolver-local intermediate>: value, ...},      # e.g. location_tier
#     "refs":    {<leaf>: value, ...},                             # pre-supplied cross-doc refs
#   }
# Only `applicants` is special-cased (per-applicant ∀); everything else is a
# namespace dict resolved by dotted token.
# --------------------------------------------------------------------------- #
def _cmp(op, lhs, rhs):
    """Apply a criterion operator. A missing fact (lhs is None) fails the criterion
    conservatively — the resolver never invents a pass from absent data."""
    if lhs is None:
        return False
    if op == "eq":
        return lhs == rhs
    if op == "neq":
        return lhs != rhs
    if op == "gte":
        return lhs >= rhs
    if op == "gt":
        return lhs > rhs
    if op == "lte":
        return lhs <= rhs
    if op == "lt":
        return lhs < rhs
    if op == "in":
        return lhs in rhs
    if op == "nin":
        return lhs not in rhs
    if op == "between":
        return isinstance(rhs, list) and len(rhs) == 2 and rhs[0] <= lhs <= rhs[1]
    raise ResolverError(f"unknown op {op!r}")


class Resolver:
    def __init__(self, rules):
        self.rules = rules  # leaf -> rule (merged across all in-scope docs)

    # -- public ------------------------------------------------------------- #
    def leaf(self, leaf, facts):
        if leaf not in self.rules:
            raise ResolverError(f"no rule fills leaf {leaf!r}")
        return self._rule(self.rules[leaf], facts, (leaf,))

    # -- rule dispatch ------------------------------------------------------ #
    def _rule(self, rule, facts, stack):
        kind = rule.get("kind")
        if kind == "parameter":
            return rule.get("value")
        if kind == "lookup":
            return self._lookup(rule, facts)
        if kind == "criteria":
            return self._criteria_joint(rule, facts, stack)
        raise ResolverError(f"unknown rule kind {kind!r}")

    # -- criteria: per-applicant ∀ ------------------------------------------ #
    def _criteria_joint(self, node, facts, stack):
        """Evaluate the criteria tree once per applicant and ∀-combine — the joint
        bool is true iff EVERY applicant satisfies it. (Rules with no applicant.*
        field yield the same bool for each applicant, so ∀ is idempotent there.)"""
        applicants = facts.get("applicants") or [{}]
        return all(self._criteria(node, facts, appl, stack) for appl in applicants)

    def _criteria(self, node, facts, appl, stack):
        combine = node.get("combine", "all_of")
        results = []
        for crit in node.get("criteria", []):
            if "combine" in crit:
                results.append(self._criteria(crit, facts, appl, stack))
            else:
                results.append(self._leaf_crit(crit, facts, appl, stack))
        return all(results) if combine == "all_of" else any(results)

    def _leaf_crit(self, crit, facts, appl, stack):
        lhs = self._resolve_field(crit["field"], facts, appl)
        rhs = self._resolve_ref(crit["ref"], facts, stack) if "ref" in crit else crit.get("value")
        return _cmp(crit.get("op"), lhs, rhs)

    # -- lookup ------------------------------------------------------------- #
    def _lookup(self, rule, facts):
        key_vals = [self._resolve_keydim(dim, facts) for dim in rule.get("key", [])]
        for row in rule.get("table", []):
            if row.get("when") == key_vals:
                return row.get("value")
        return rule.get("default")

    # -- token resolution --------------------------------------------------- #
    def _resolve_field(self, token, facts, appl):
        ns, dot, rest = token.partition(".")
        if not dot:  # bare token — resolver-local intermediate
            return (facts.get("locals") or {}).get(token)
        if ns == "applicant":
            return appl.get(rest)
        scope = facts.get(ns)
        return scope.get(rest) if isinstance(scope, dict) else None

    def _resolve_keydim(self, dim, facts):
        # lookups read shared facts only (no applicant context).
        return self._resolve_field(dim, facts, {})

    def _resolve_ref(self, ref, facts, stack):
        if ref in stack:
            raise ResolverError(f"ref cycle through {ref!r}")
        if ref in (facts.get("refs") or {}):
            return facts["refs"][ref]
        if ref in self.rules:
            return self._rule(self.rules[ref], facts, stack + (ref,))
        raise ResolverError(f"unresolved ref {ref!r}")


# --------------------------------------------------------------------------- #
# Worked examples (the eval set). Expected values are the ground truth from the
# KB prose, not what the current model happens to compute — that gap is the point.
# Seeded focused for v1; scenarios.md is the source to grow this from.
# --------------------------------------------------------------------------- #
CASES = [
    {
        "name": "fhss-single-eligible",
        "note": "One applicant meeting every FHSS criterion → eligible. Green path.",
        "facts": {"applicants": [
            {"age": 30, "ever_owned_au_property": False,
             "owner_occupier_intent": True, "prior_fhss_release": False},
        ]},
        "expect": {"eligibility.fhss.eligible": True},
    },
    {
        "name": "fhss-two-applicants-one-qualifies",
        "note": ("FHSS is per-person (KB: 'assessed per person … two eligible buyers "
                 "can each run their own FHSS'). Applicant A qualifies, B previously "
                 "owned AU property. Correct outcome: FHSS is available (A releases). "
                 "The current joint-bool ∀ model computes False — that mismatch IS F13."),
        "facts": {"applicants": [
            {"age": 30, "ever_owned_au_property": False,
             "owner_occupier_intent": True, "prior_fhss_release": False},   # A: eligible
            {"age": 32, "ever_owned_au_property": True,
             "owner_occupier_intent": True, "prior_fhss_release": False},   # B: owned AU property
        ]},
        "expect": {"eligibility.fhss.eligible": True},
        "xfail": "F13",
    },
    {
        "name": "fhg-single-eligible-under-cap",
        "note": ("Citizen FHB, never owned, owner-occupier, NSW capital, $1.2M ≤ $1.5M cap. "
                 "Exercises nested any_of, the property_fit.price ↔ lookup-cap ref, and the "
                 "(state, location_tier) lookup."),
        "facts": {
            "applicants": [
                {"citizenship_status": "citizen", "age": 30,
                 "ever_owned_au_property": False, "years_since_last_au_property_interest": 0,
                 "owner_occupier_intent": True},
            ],
            "property_fit": {"state": "NSW", "price": 1200000},
            "locals": {"location_tier": "capital_or_regional_centre"},
        },
        "expect": {
            "eligibility.fhg.applicable_cap_for_location_property": 1500000,
            "eligibility.fhg.eligible": True,
        },
    },
    {
        "name": "fhg-single-over-cap",
        "note": "Same applicant, $1.6M > $1.5M NSW-capital cap → price criterion fails → ineligible.",
        "facts": {
            "applicants": [
                {"citizenship_status": "citizen", "age": 30,
                 "ever_owned_au_property": False, "years_since_last_au_property_interest": 0,
                 "owner_occupier_intent": True},
            ],
            "property_fit": {"state": "NSW", "price": 1600000},
            "locals": {"location_tier": "capital_or_regional_centre"},
        },
        "expect": {"eligibility.fhg.eligible": False},
    },
]


# --------------------------------------------------------------------------- #
# Runner
# --------------------------------------------------------------------------- #
def load_rules(artifact):
    """Merge every in-scope doc's fills into one leaf -> rule map (refs resolve globally)."""
    rules = {}
    for slug, doc in artifact["kb"].items():
        cj = doc.get("content_json") or {}
        for fill in cj.get("fills", []):
            leaf, rule = fill.get("leaf"), fill.get("rule")
            if leaf and rule is not None:
                rules[leaf] = rule
    return rules


def run():
    if not ARTIFACT.is_file():
        print(f"FAIL — artifact not found: {ARTIFACT.relative_to(ROOT)} "
              f"(run engine/build/kb_compiler.py first)")
        return 1
    artifact = json.loads(ARTIFACT.read_text())
    resolver = Resolver(load_rules(artifact))

    hard_fails, xfail_confirmed, xpass, passed = [], [], [], []

    for case in CASES:
        name, facts, xfail = case["name"], case["facts"], case.get("xfail")
        mism = []  # (leaf, got, want)
        erred = None
        for leaf, want in case["expect"].items():
            try:
                got = resolver.leaf(leaf, facts)
            except ResolverError as e:
                erred = f"{leaf}: {e}"
                break
            if got != want:
                mism.append((leaf, got, want))

        if erred is not None:
            hard_fails.append((name, f"resolver error — {erred}", case.get("note")))
        elif xfail:
            if mism:
                xfail_confirmed.append((name, xfail, mism, case.get("note")))
            else:
                xpass.append((name, xfail, case.get("note")))
        elif mism:
            hard_fails.append((name, mism, case.get("note")))
        else:
            passed.append(name)

    # -- report ------------------------------------------------------------- #
    print(f"resolver eval — {len(CASES)} case(s), {len(resolver.rules)} fillable leaf rules\n")
    for n in passed:
        print(f"  PASS   {n}")
    for name, finding, mism, note in xfail_confirmed:
        print(f"  xfail  {name}  [{finding}] confirmed-open")
        for leaf, got, want in mism:
            print(f"           {leaf}: got {got!r}, correct {want!r}")
    for name, finding, note in xpass:
        print(f"  XPASS  {name}  [{finding}] NOW MATCHES — review: the gap may be closed; "
              f"update/remove the xfail and close {finding}")
    for name, detail, note in hard_fails:
        if isinstance(detail, list):
            print(f"  FAIL   {name}")
            for leaf, got, want in detail:
                print(f"           {leaf}: got {got!r}, expected {want!r}")
        else:
            print(f"  FAIL   {name}: {detail}")

    print("\n" + "=" * 64)
    print(f"pass={len(passed)} xfail={len(xfail_confirmed)} "
          f"xpass={len(xpass)} fail={len(hard_fails)}")
    if hard_fails:
        print(f"FAIL — {len(hard_fails)} hard failure(s)")
        return 1
    if xpass:
        print("PASS — but XPASS present: a known-open finding now matches; close it.")
    else:
        print("PASS — all non-xfail cases match; known-open findings still confirmed-open.")
    return 0


if __name__ == "__main__":
    sys.exit(run())
