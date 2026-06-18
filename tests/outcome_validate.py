#!/usr/bin/env python3
"""Outcome-conformance reference spec — the Layer-1 seam validator (outcome-conformance.md).

The engine commits every component fill through one seam (`fh_engine_turn` commit,
before `snapshot_component`). Layer 1 there is a structural, producer- and mode-agnostic
post-condition: does the fill match its declared `outcome_schema`? This file is the
REFERENCE implementation of that walk, in lockstep with the Erlang
`fh_engine_outcome:check/3` (proven by `engine/erlang/test/outcome_conformance.escript`,
which runs the SAME cases through the Erlang core and asserts identical verdicts).

The walk reads the parsed `{kind}` type-tree the compiler emits
(`registry.outcome_types`, via `parse_field_type` — materialize-parse-once: neither
implementation re-parses type strings). Three load-bearing clauses, plus graceful
pass-through for everything else:

  - `localized` → every required locale present, each a non-empty string, and the
    locales PAIRWISE-DISTINCT (the locale-agnostic anti-fallback: catches English copied
    into the `vi` slot). The vi-diacritic heuristic is NOT applied here — it is vi-specific
    and stays in the build/eval layer (outcome-conformance.md §3, "never load-bearing").
  - `enum`   → value ∈ declared options.
  - figure (`money`/`money_range`/`money_per_year`/`number`/`integer`/`integer_0_10`)
    → numbers all the way down: never a string (an LLM emits "$500k"), never a {vi,en}
    map. This IS the §98 guard, generalized — the agent cannot author a figure.

Nullability is implicit-universal: `null` conforms to ANY field (honest-partial fills
leave genuinely-unknown facts absent). `string`/`bool`/`date`/`object` scalars and
`unknown` kinds are NOT checked (the §3 string-nudge covers prose-mistyped-as-string at
BUILD time; runtime stays graceful so a name-only sub-field never crashes a turn).

Lockstep granularity is the VERDICT (conform vs reject) on each (tree, value) — the
reason strings differ by language and are informative, not contractual. A reject at the
seam is fail-closed: it crashes the supervised turn (the OTP idiom; §7). Run from repo root.
"""

import sys

LOCALES = ("vi", "en")

# §98: the numeric family. A money_range is a [lo, hi] list of numbers; the rest are a
# bare number. string/bool/date/object are scalars too but are NOT figures (not checked).
FIGURE_TYPES = {"money", "money_per_year", "number", "integer", "integer_0_10"}


def _is_num(v):
    # bool is a subclass of int in Python — exclude it; a figure is never a flag.
    return isinstance(v, (int, float)) and not isinstance(v, bool)


def _check_localized(value, locales):
    if not isinstance(value, dict):
        return f"localized field must be a {{locale}} map, got {type(value).__name__}"
    seen = []
    for loc in locales:
        if loc not in value:
            return f"localized missing locale {loc!r}"
        s = value[loc]
        if not isinstance(s, str) or not s.strip():
            return f"localized locale {loc!r} empty or non-string"
        seen.append(s)
    if len(set(seen)) != len(seen):
        return "localized locales not pairwise-distinct (English fallback copy?)"
    return None


def _check_scalar(stype, value):
    if stype == "money_range":
        if not (isinstance(value, list) and all(_is_num(x) for x in value)):
            return f"money_range must be a list of numbers, got {value!r}"
        return None
    if stype in FIGURE_TYPES:
        if not _is_num(value):
            return f"{stype} must be a number, got {type(value).__name__}"
        return None
    # string / bool / date / object — graceful (not a figure).
    return None


def check(tree, value, locales=LOCALES):
    """None if `value` conforms to the parsed type `tree`, else a short reason string."""
    if value is None:  # implicit-universal nullability
        return None
    kind = tree.get("kind")
    if kind == "localized":
        return _check_localized(value, locales)
    if kind == "enum":
        if value not in tree.get("options", []):
            return f"enum value {value!r} not in options {tree.get('options')}"
        return None
    if kind == "scalar":
        return _check_scalar(tree.get("type"), value)
    if kind == "array":
        if not isinstance(value, list):
            return f"expected array, got {type(value).__name__}"
        for i, el in enumerate(value):
            r = check(tree["element"], el, locales)
            if r:
                return f"[{i}] {r}"
        return None
    if kind == "object":
        if not isinstance(value, dict):
            return f"expected object, got {type(value).__name__}"
        for f, sub in tree.get("fields", {}).items():
            r = check(sub, value.get(f), locales)
            if r:
                return f".{f} {r}"
        return None
    # unknown / unrecognized — graceful (outcome-conformance.md §2)
    return None


def validate(type_tree_fields, outcome, locales=LOCALES, components=()):
    """An outcome map against an outcome_type's {field: parsed_tree}. None or first reason.

    Runs the §13 placement/provenance pass after the type walk (graceful when `components`
    is empty — check 1 has nothing to resolve against)."""
    for f, sub in type_tree_fields.items():
        r = check(sub, outcome.get(f), locales)
        if r:
            return f"{f}{r}" if r[0] in ".[" else f"{f}: {r}"
    return check_placement(outcome, components)


# --- §13 placement & provenance (outcome-conformance.md §13) --------------------
# A SEMANTIC pass over the whole outcome (not the type-tree walk): the two-spines model
# adds PLACED figures, tagged with provenance + money-flow fields. Field-name driven, so it
# attaches to the invariant wherever it appears (every cash_event / cell), not to a hardcoded
# outcome list. Mirror of fh_engine_outcome:check_placement/2.

MONEY_MARKERS = {"money_out", "money_in"}
NONMONEY_MARKERS = {"none", "document", "milestone"}
MONEY_DIRECTIONS = {"out", "in"}


def _walk_maps(value):
    """Yield every dict nested anywhere in `value` (including `value` itself)."""
    if isinstance(value, dict):
        yield value
        for v in value.values():
            yield from _walk_maps(v)
    elif isinstance(value, list):
        for v in value:
            yield from _walk_maps(v)


def _amt_key(a):
    return tuple(a) if isinstance(a, list) else a


def _check_element(m, components):
    # check 1: provenance resolves (skip when the component set is unavailable).
    src = m.get("source_component")
    if isinstance(src, str) and components and src not in components:
        return f"source_component {src!r} is not a real component"
    # checks 2 govern PLACED elements — those carrying provenance (a cash_event / cell). A
    # derived interaction flow has `direction` but NO source_component → governed by check 3,
    # not here; skip it so its missing counterparty is not a false positive.
    if not isinstance(src, str):
        return None
    # check 2: money flow ⟹ counterparty (cash_event shape: carries `direction`).
    if m.get("direction") in MONEY_DIRECTIONS and m.get("counterparty") is None:
        return "money flow (cash_event) has no counterparty"
    # check 2 + inverse (cell shape: carries `flow_marker`).
    marker = m.get("flow_marker")
    if marker in MONEY_MARKERS:
        if m.get("counterparty") is None:
            return "money cell has no counterparty"
    elif marker in NONMONEY_MARKERS:
        if m.get("counterparty") is not None:
            return "non-money cell carries a counterparty"
        if m.get("amount") is not None:
            return "non-money cell carries an amount"
    return None


def _check_interactions(outcome):
    # check 3: every interaction flow corresponds to a placed money cell in this outcome.
    interactions, cells = outcome.get("interactions"), outcome.get("cells")
    if not isinstance(interactions, list) or not isinstance(cells, list):
        return None
    marker_dir = {"money_out": "out", "money_in": "in"}
    placed = {
        (c.get("phase"), marker_dir[c["flow_marker"]], _amt_key(c.get("amount")))
        for c in cells
        if isinstance(c, dict) and c.get("flow_marker") in marker_dir
    }
    for ix in interactions:
        if not isinstance(ix, dict):
            continue
        for fl in ix.get("flows", []) or []:
            if not isinstance(fl, dict):
                continue
            key = (ix.get("phase"), fl.get("direction"), _amt_key(fl.get("amount")))
            if key not in placed:
                return "interaction flow has no corresponding placed cell"
    return None


def check_placement(outcome, components=()):
    """None if `outcome`'s placements conform to §13, else a short reason string."""
    if not isinstance(outcome, dict):
        return None
    for m in _walk_maps(outcome):
        r = _check_element(m, components)
        if r:
            return r
    return _check_interactions(outcome)


# --- shared cases (mirrored by outcome_conformance.escript) ---------------------
# Each: a parsed type-tree + a value + the expected VERDICT (ok / reject). For reject
# cases `expect` is a substring of THIS spec's reason (informative; the escript only
# asserts the ok-vs-reject verdict matches, since reason text is language-specific).

LOC = {"kind": "localized"}
MONEY = {"kind": "scalar", "type": "money"}
MRANGE = {"kind": "scalar", "type": "money_range"}
STR = {"kind": "scalar", "type": "string"}
ENUM = {"kind": "enum", "options": ["a", "b", "c"]}

CASES = [
    # localized clause
    {"name": "loc-ok", "tree": LOC,
     "value": {"vi": "Người mua nhà lần đầu", "en": "First home buyer"}, "ok": True},
    {"name": "loc-missing-locale", "tree": LOC,
     "value": {"en": "First home buyer"}, "ok": False, "expect": "missing locale"},
    {"name": "loc-empty-vi", "tree": LOC,
     "value": {"vi": "  ", "en": "First home buyer"}, "ok": False, "expect": "empty"},
    {"name": "loc-not-distinct", "tree": LOC,
     "value": {"vi": "First home buyer", "en": "First home buyer"}, "ok": False,
     "expect": "pairwise-distinct"},
    {"name": "loc-not-a-map", "tree": LOC, "value": "First home buyer", "ok": False,
     "expect": "{locale} map"},
    {"name": "loc-null-ok", "tree": LOC, "value": None, "ok": True},

    # enum clause
    {"name": "enum-ok", "tree": ENUM, "value": "b", "ok": True},
    {"name": "enum-bad", "tree": ENUM, "value": "z", "ok": False, "expect": "not in options"},

    # figure clause (§98)
    {"name": "money-ok", "tree": MONEY, "value": 500000, "ok": True},
    {"name": "money-null-ok", "tree": MONEY, "value": None, "ok": True},
    {"name": "money-as-string-rejected", "tree": MONEY, "value": "$500k", "ok": False,
     "expect": "must be a number"},
    {"name": "money-as-localized-rejected", "tree": MONEY,
     "value": {"vi": "500 nghìn", "en": "500k"}, "ok": False, "expect": "must be a number"},
    {"name": "money-as-bool-rejected", "tree": MONEY, "value": True, "ok": False,
     "expect": "must be a number"},
    {"name": "money_range-ok", "tree": MRANGE, "value": [600000, 700000], "ok": True},
    {"name": "money_range-string-elem-rejected", "tree": MRANGE,
     "value": [600000, "700k"], "ok": False, "expect": "list of numbers"},

    # string scalar — graceful (not a figure)
    {"name": "string-graceful", "tree": STR, "value": "Cabramatta", "ok": True},

    # array<localized> (key_constraints / key_strengths shape)
    {"name": "array-loc-ok", "tree": {"kind": "array", "element": LOC},
     "value": [{"vi": "ràng buộc tài chính", "en": "financial constraint"}], "ok": True},
    {"name": "array-loc-bad-elem", "tree": {"kind": "array", "element": LOC},
     "value": [{"vi": "ok khác", "en": "fine"}, {"en": "missing vi"}], "ok": False,
     "expect": "[1]"},
    {"name": "array-not-a-list", "tree": {"kind": "array", "element": LOC},
     "value": {"vi": "x", "en": "y"}, "ok": False, "expect": "expected array"},

    # object with a localized sub-field (rejected_schemes element shape)
    {"name": "object-loc-subfield-bad",
     "tree": {"kind": "object", "fields": {"name": STR, "reason": LOC}},
     "value": {"name": "FHG", "reason": {"vi": "", "en": "over cap"}}, "ok": False,
     "expect": ".reason"},

    # unknown kind — graceful
    {"name": "unknown-graceful", "tree": {"kind": "unknown", "raw": "comparable_sale"},
     "value": {"anything": 1}, "ok": True},
]


# --- shared placement cases (mirrored by outcome_conformance.escript) ------------
# Each: a whole outcome + a component set + the expected VERDICT through check_placement.
PLACEMENT_COMPS = ["cash_position", "eligibility", "ownership_planning", "purchase_journey"]


def _cell(phase, marker, cp, amount, src, **extra):
    return {"phase": phase, "flow_marker": marker, "counterparty": cp,
            "amount": amount, "source_component": src, **extra}


PLACEMENT_CASES = [
    # check 1 — provenance resolves
    {"name": "prov-ok",
     "outcome": {"cells": [_cell("prepare", "none", None, None, "cash_position")]},
     "comps": PLACEMENT_COMPS, "ok": True},
    {"name": "prov-bad-typo",
     "outcome": {"cells": [_cell("prepare", "none", None, None, "buyer_profilex")]},
     "comps": PLACEMENT_COMPS, "ok": False, "expect": "real component"},
    {"name": "prov-skip-when-no-components",
     "outcome": {"cells": [_cell("prepare", "none", None, None, "buyer_profilex")]},
     "comps": [], "ok": True},

    # check 2 — money flow ⟹ counterparty (cash_event shape)
    {"name": "cashevent-out-no-cp",
     "outcome": {"cash_events": [{"direction": "out", "counterparty": None,
                                  "amount": [1, 2], "source_component": "cash_position"}]},
     "comps": PLACEMENT_COMPS, "ok": False, "expect": "counterparty"},
    {"name": "cashevent-out-ok",
     "outcome": {"cash_events": [{"direction": "out", "counterparty": "other",
                                  "amount": [1, 2], "source_component": "cash_position"}]},
     "comps": PLACEMENT_COMPS, "ok": True},

    # check 2 — money cell shape + inverse
    {"name": "cell-money-no-cp",
     "outcome": {"cells": [_cell("settle", "money_out", None, [1, 2], "cash_position")]},
     "comps": PLACEMENT_COMPS, "ok": False, "expect": "counterparty"},
    {"name": "nonmoney-cell-with-cp",
     "outcome": {"cells": [_cell("contract", "document", "you", None, "purchase_journey")]},
     "comps": PLACEMENT_COMPS, "ok": False, "expect": "counterparty"},
    {"name": "nonmoney-cell-with-amount",
     "outcome": {"cells": [_cell("settle", "milestone", None, [1, 2], "purchase_journey")]},
     "comps": PLACEMENT_COMPS, "ok": False, "expect": "amount"},

    # check 3 — interactions derive, not invent
    {"name": "interactions-ok",
     "outcome": {
         "cells": [_cell("contract", "money_out", "you", [30000, 35000], "cash_position",
                         actor="other")],
         "interactions": [{"from_actor": "you", "to_actor": "other", "phase": "contract",
                           "flows": [{"direction": "out", "amount": [30000, 35000]}]}]},
     "comps": PLACEMENT_COMPS, "ok": True},
    {"name": "interactions-invented-flow",
     "outcome": {
         "cells": [_cell("contract", "money_out", "you", [30000, 35000], "cash_position",
                         actor="other")],
         "interactions": [{"from_actor": "you", "to_actor": "other", "phase": "contract",
                           "flows": [{"direction": "out", "amount": [99, 99]}]}]},
     "comps": PLACEMENT_COMPS, "ok": False, "expect": "no corresponding placed cell"},

    # graceful — an outcome with no placement fields (localized prose only)
    {"name": "placement-graceful-no-fields",
     "outcome": {"key_assumptions": [{"vi": "x", "en": "y"}]},
     "comps": PLACEMENT_COMPS, "ok": True},
]


def run():
    fails = []
    for c in CASES:
        reason = check(c["tree"], c["value"])
        got_ok = reason is None
        if got_ok != c["ok"]:
            fails.append((c["name"], f"verdict mismatch: ok={got_ok} expected ok={c['ok']} "
                                     f"(reason={reason!r})"))
            continue
        if not c["ok"] and "expect" in c and c["expect"] not in (reason or ""):
            fails.append((c["name"], f"reason {reason!r} lacks {c['expect']!r}"))
            continue
        print(f"  ok   {c['name']:34s} -> {'conform' if got_ok else reason}")

    print("\n  --- §13 placement & provenance ---")
    for c in PLACEMENT_CASES:
        reason = check_placement(c["outcome"], c["comps"])
        got_ok = reason is None
        if got_ok != c["ok"]:
            fails.append((c["name"], f"verdict mismatch: ok={got_ok} expected ok={c['ok']} "
                                     f"(reason={reason!r})"))
            continue
        if not c["ok"] and "expect" in c and c["expect"] not in (reason or ""):
            fails.append((c["name"], f"reason {reason!r} lacks {c['expect']!r}"))
            continue
        print(f"  ok   {c['name']:34s} -> {'conform' if got_ok else reason}")

    n = len(CASES) + len(PLACEMENT_CASES)
    print("\n================================================================")
    if fails:
        for name, why in fails:
            print(f"  FAIL {name}: {why}")
        print(f"FAIL — {len(fails)} case(s)")
        return 1
    print(f"PASS — {n} cases (Layer-1 walk + §13 placement)")
    return 0


if __name__ == "__main__":
    sys.exit(run())
