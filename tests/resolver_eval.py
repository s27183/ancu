#!/usr/bin/env python3
"""Resolver eval harness — the rule-semantics detector (grounding-checklist §1 / #6).

The compiler ([`engine/build/kb_compiler.py`]) validates that every `content_json`
rule *references* real registry fields and that each `leaf` maps to a real slot —
structure and reference integrity. It never *executes* a rule. That is the blind
spot §1 names "rule *semantics*": a rule can reference all-valid fields and still
compute the wrong outcome.

This harness closes that class. It carries a small **reference resolver** that
interprets the emitted artifact's `content_json` rules (criteria / lookup /
parameter) against worked-example fact-sets and asserts each computed outcome leaf
against an expected value drawn from the KB prose (the ground truth). A mismatch
surfaces a rule-semantics bug. The reference resolver also doubles as the executable
spec the engine's production resolver (Python sidecar / Erlang `fh_engine_resolver`)
must conform to — `engine/erlang/test/resolver_conformance.escript` runs the same
worked examples against the Erlang port and asserts identical outcomes.

THREE-VALUED (Kleene) semantics — see `docs/architecture/resolver-semantics.md`.
A fact at base is often *partially known*: a **scalar** (pinned), a **set**
`{"oneof": [...]}` (one of these, unknown which — e.g. Mode A → citizenship is
`{citizen, permanent_resident}`), a **range** `{"range": [lo, hi]}` (an interval
over an ordered domain — `lo`/`hi` `None` = ∓∞), or **absent** (the universe). A
criterion over a possibility set is three-valued — `True` if it holds for ALL the
set's values, `False` for NONE, else `UNDET`. Combinators are strong Kleene
(`all_of` → `False` if any child false, else `UNDET` if any undetermined, else
`True`; `any_of` dual). A `None` `rhs` (e.g. the FHG cap `lookup` defaulting to
`null` when `location_tier` is absent) → `UNDET` — structurally closing G3 (no
spurious pass from a null threshold). The verdict is policy-free; each CONSUMER
collapses: `eligibility` `UNDET → applicable-pending`, the compliance gate
`UNDET → deny` (fail-closed).

Backward-compat guarantee (resolver-semantics §5): when every referenced fact is a
pinned **scalar**, the resolver returns exactly the old `True`/`False` and never
`UNDET`. The scalar CASES below are unchanged and are the guard for this property.

Applicant semantics: a criteria rule is evaluated PER APPLICANT. A **joint** scheme
∀-combines (Kleene) into one verdict (`leaf`); a **per-applicant** scheme (FHSS,
by the KB `resolution` marker) keeps the per-applicant list (`leaf_per_applicant`)
— the F13 close.

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


class _Undet:
    """The third truth value — 'could be either', distinct from True/False and from
    None (which means 'missing fact' / lookup default). A singleton."""
    __slots__ = ()
    def __repr__(self):
        return "UNDET"
    def __bool__(self):
        raise TypeError("UNDET is not a Python bool — collapse it with a consumer policy")


UNDET = _Undet()


# --------------------------------------------------------------------------- #
# Possibility-set helpers. A fact value is a scalar, a tagged set/range dict, or
# None (absent = the universe). Tagged dicts are the only new structure.
# --------------------------------------------------------------------------- #
def _is_oneof(v):
    return isinstance(v, dict) and "oneof" in v


def _is_range(v):
    return isinstance(v, dict) and "range" in v


def _sat(op, p, rhs):
    """The ordinary two-valued predicate at a concrete value `p` (rhs known, non-None)."""
    if op == "eq":
        return p == rhs
    if op == "neq":
        return p != rhs
    if op == "gte":
        return p >= rhs
    if op == "gt":
        return p > rhs
    if op == "lte":
        return p <= rhs
    if op == "lt":
        return p < rhs
    if op == "in":
        return p in rhs
    if op == "nin":
        return p not in rhs
    if op == "between":
        return isinstance(rhs, list) and len(rhs) == 2 and rhs[0] <= p <= rhs[1]
    raise ResolverError(f"unknown op {op!r}")


def _cmp_range(op, lo, hi, rhs):
    """Three-valued evaluation of `[lo,hi] op rhs` (inclusive interval; None = ∓∞)."""
    L = float("-inf") if lo is None else lo
    H = float("inf") if hi is None else hi
    if op == "gte":
        return True if L >= rhs else (False if H < rhs else UNDET)
    if op == "gt":
        return True if L > rhs else (False if H <= rhs else UNDET)
    if op == "lte":
        return True if H <= rhs else (False if L > rhs else UNDET)
    if op == "lt":
        return True if H < rhs else (False if L >= rhs else UNDET)
    if op == "eq":
        return True if (L == H == rhs) else (False if (rhs < L or rhs > H) else UNDET)
    if op == "neq":
        return False if (L == H == rhs) else (True if (rhs < L or rhs > H) else UNDET)
    if op == "between":
        if not (isinstance(rhs, list) and len(rhs) == 2):
            return False
        a, b = rhs
        if a <= L and H <= b:
            return True
        if H < a or L > b:
            return False
        return UNDET
    if op in ("in", "nin"):
        # a true interval can't be a discrete-list membership; only a degenerate
        # point range (lo == hi) is decidable.
        return _sat(op, L, rhs) if L == H else UNDET
    raise ResolverError(f"unknown op {op!r}")


def _cmp(op, lhs, rhs):
    """Apply a criterion operator three-valued over a possibility set `lhs`.
    Absent fact (lhs None) → UNDET; unresolved threshold (rhs None) → UNDET (G3).
    A scalar `lhs` reduces to the ordinary two-valued predicate (backward-compat)."""
    if lhs is None:
        return UNDET
    if rhs is None:
        return UNDET
    if _is_oneof(lhs):
        sats = [_sat(op, m, rhs) for m in lhs["oneof"]]
        if all(sats):
            return True
        if not any(sats):
            return False
        return UNDET
    if _is_range(lhs):
        lo, hi = lhs["range"]
        return _cmp_range(op, lo, hi, rhs)
    return _sat(op, lhs, rhs)


# --------------------------------------------------------------------------- #
# Strong-Kleene (K3) combinators. A definite disqualifier wins over pending
# siblings (all_of short-circuits to False); a definite qualifier wins in any_of.
# --------------------------------------------------------------------------- #
def _k3_all(results):
    if any(r is False for r in results):
        return False
    if any(r is UNDET for r in results):
        return UNDET
    return True


def _k3_any(results):
    if any(r is True for r in results):
        return True
    if any(r is UNDET for r in results):
        return UNDET
    return False


# --------------------------------------------------------------------------- #
# Reference resolver — interprets content_json rules against a fact-set.
#
# Fact-set shape (a worked example supplies it):
#   {
#     "applicants": [ {<applicant.* field>: <possibility>, ...}, ... ],  # 1..N
#     "property_fit": {<field>: <possibility>, ...},                      # shared
#     "profile":      {<field>: <possibility>, ...},                      # shared
#     "locals":  {<resolver-local intermediate>: value, ...},             # e.g. location_tier
#     "refs":    {<leaf>: value, ...},                                    # pre-supplied refs
#   }
# A <possibility> is a scalar, {"oneof":[...]}, {"range":[lo,hi]}, or absent.
# --------------------------------------------------------------------------- #
class Resolver:
    def __init__(self, rules):
        self.rules = rules  # leaf -> rule (merged across all in-scope docs)

    # -- public ------------------------------------------------------------- #
    def leaf(self, leaf, facts):
        """A JOINT leaf: ∀-combined (Kleene) across applicants → one verdict."""
        if leaf not in self.rules:
            raise ResolverError(f"no rule fills leaf {leaf!r}")
        return self._rule(self.rules[leaf], facts, (leaf,))

    def leaf_per_applicant(self, leaf, facts):
        """A PER-APPLICANT leaf (FHSS, by the KB `resolution` marker): the list of
        per-applicant three-valued verdicts (no collapse). The consumer derives
        `eligible_applicants` from it — the F13 close."""
        if leaf not in self.rules:
            raise ResolverError(f"no rule fills leaf {leaf!r}")
        rule = self.rules[leaf]
        if rule.get("kind") != "criteria":
            raise ResolverError(f"leaf {leaf!r} is not a criteria rule — per-applicant N/A")
        applicants = facts.get("applicants") or [{}]
        return [self._criteria(rule, facts, appl, (leaf,)) for appl in applicants]

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

    # -- criteria: per-applicant, Kleene ∀ ---------------------------------- #
    def _criteria_joint(self, node, facts, stack):
        """Evaluate the criteria tree once per applicant and Kleene-∀-combine: False
        if any applicant is False, UNDET if any is undetermined, else True. (Rules
        with no applicant.* field yield the same verdict per applicant, so ∀ is
        idempotent there.)"""
        applicants = facts.get("applicants") or [{}]
        return _k3_all([self._criteria(node, facts, appl, stack) for appl in applicants])

    def _criteria(self, node, facts, appl, stack):
        combine = node.get("combine", "all_of")
        results = []
        for crit in node.get("criteria", []):
            if "combine" in crit:
                results.append(self._criteria(crit, facts, appl, stack))
            else:
                results.append(self._leaf_crit(crit, facts, appl, stack))
        return _k3_all(results) if combine == "all_of" else _k3_any(results)

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
# KB prose, not what the current model happens to compute. A case asserts either
# `expect` (joint leaf -> value, via Resolver.leaf) and/or `expect_per_applicant`
# (per-applicant leaf -> [v0, v1, ...], via Resolver.leaf_per_applicant). Expected
# values may be True / False / UNDET.
# --------------------------------------------------------------------------- #
CASES = [
    # -- scalar cases: the backward-compat guard (resolver-semantics §5). Every
    #    referenced fact is pinned → identical to the old bi-state, never UNDET.
    {
        "name": "fhss-single-eligible",
        "note": "One applicant meeting every FHSS criterion, all facts pinned → eligible.",
        "facts": {"applicants": [
            {"age": 30, "ever_owned_au_property": False,
             "owner_occupier_intent": True, "prior_fhss_release": False},
        ]},
        "expect": {"eligibility.fhss.eligible": True},
    },
    {
        "name": "fhg-single-eligible-under-cap",
        "note": ("Citizen FHB, never owned, owner-occupier, NSW capital, $1.2M ≤ $1.5M cap. "
                 "Exercises nested any_of, the property_fit.price ↔ lookup-cap ref, and the "
                 "(state, location_tier) lookup. All facts pinned."),
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

    # -- three-valued cases: partial knowledge (the new semantics).
    {
        "name": "citizenship-set-mode-a",
        "note": ("Mode A → citizenship is the SET {citizen, permanent_resident}. "
                 "FHG's `in [citizen,PR]` holds for ALL the set → True; Help-to-Buy's "
                 "`eq citizen` holds for SOME → UNDET (pending: citizen vs PR). Other "
                 "facts pinned to isolate the set semantics."),
        "facts": {
            "applicants": [
                {"citizenship_status": {"oneof": ["citizen", "permanent_resident"]},
                 "age": 30, "ever_owned_au_property": False,
                 "years_since_last_au_property_interest": 0,
                 "owner_occupier_intent": True, "currently_owns_property": False},
            ],
            "property_fit": {"state": "NSW", "price": 1200000},
            "locals": {"location_tier": "capital_or_regional_centre"},
        },
        "expect": {
            "eligibility.fhg.eligible": True,
            "eligibility.help_to_buy.eligible": UNDET,
        },
    },
    {
        "name": "absent-fact-undetermined",
        "note": ("`prior_fhss_release` absent (not yet asked) → the criterion is UNDET, "
                 "so FHSS is UNDET — 'applicable, confirm you haven't released before'. "
                 "Bi-state gave False (wrongly ineligible). The absent → UNDET change."),
        "facts": {"applicants": [
            {"age": 30, "ever_owned_au_property": False, "owner_occupier_intent": True},
        ]},
        "expect": {"eligibility.fhss.eligible": UNDET},
    },
    {
        "name": "prior-owner-unknown-years",
        "note": ("W-B: owned AU property, but WHEN is unknown. FHG's any_of(ever_owned "
                 "eq false → False, years_since gte 10 → UNDET[absent]) → UNDET → 'pending: "
                 "10+ years since?'. Bi-state gave False — wrongly ineligible for someone "
                 "who may qualify under the 10-year rule."),
        "facts": {
            "applicants": [
                {"citizenship_status": "citizen", "age": 40,
                 "ever_owned_au_property": True, "owner_occupier_intent": True},
            ],
            "property_fit": {"state": "NSW", "price": 1200000},
            "locals": {"location_tier": "capital_or_regional_centre"},
        },
        "expect": {"eligibility.fhg.eligible": UNDET},
    },
    {
        "name": "fhg-null-cap-rhs-undetermined",
        "note": ("G3: `location_tier` absent → the cap lookup returns its null default → "
                 "the price criterion's rhs is None → UNDET (never a spurious pass). In "
                 "Erlang term order `price ≤ null` was spuriously True; in Python it would "
                 "TypeError. Three-valued (rhs None → UNDET) fixes both. So FHG → UNDET."),
        "facts": {
            "applicants": [
                {"citizenship_status": "citizen", "age": 30,
                 "ever_owned_au_property": False, "years_since_last_au_property_interest": 0,
                 "owner_occupier_intent": True},
            ],
            "property_fit": {"state": "NSW", "price": 1200000},
            # location_tier deliberately absent → cap lookup → null default.
        },
        "expect": {"eligibility.fhg.eligible": UNDET},
    },

    # -- F13 close: FHSS is per-applicant (KB `resolution: per_applicant`).
    {
        "name": "fhss-two-applicants-one-qualifies",
        "note": ("FHSS is per-person (KB: 'assessed per person … two eligible buyers can "
                 "each run their own FHSS'). A qualifies; B previously owned AU property. "
                 "Per-applicant verdicts [True, False] → the household derives "
                 "eligible_applicants=[A]. Closes F13 — the bi-state joint-∀ leaf computed "
                 "one False for the household (the old xfail). Now asserted per-applicant."),
        "facts": {"applicants": [
            {"age": 30, "ever_owned_au_property": False,
             "owner_occupier_intent": True, "prior_fhss_release": False},   # A: eligible
            {"age": 32, "ever_owned_au_property": True,
             "owner_occupier_intent": True, "prior_fhss_release": False},   # B: owned AU property
        ]},
        "expect_per_applicant": {"eligibility.fhss.eligible": [True, False]},
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


def _eval_case(resolver, case):
    """Return (mismatches, error). mismatches :: [(leaf, got, want)]."""
    mism = []
    for leaf, want in case.get("expect", {}).items():
        try:
            got = resolver.leaf(leaf, case["facts"])
        except ResolverError as e:
            return mism, f"{leaf}: {e}"
        if got is not want and got != want:
            mism.append((leaf, got, want))
    for leaf, want in case.get("expect_per_applicant", {}).items():
        try:
            got = resolver.leaf_per_applicant(leaf, case["facts"])
        except ResolverError as e:
            return mism, f"{leaf} (per-applicant): {e}"
        if got != want:
            mism.append((leaf + " [per-applicant]", got, want))
    return mism, None


def run():
    if not ARTIFACT.is_file():
        print(f"FAIL — artifact not found: {ARTIFACT.relative_to(ROOT)} "
              f"(run engine/build/kb_compiler.py first)")
        return 1
    artifact = json.loads(ARTIFACT.read_text())
    resolver = Resolver(load_rules(artifact))

    hard_fails, xfail_confirmed, xpass, passed = [], [], [], []

    for case in CASES:
        name, xfail = case["name"], case.get("xfail")
        mism, erred = _eval_case(resolver, case)

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
