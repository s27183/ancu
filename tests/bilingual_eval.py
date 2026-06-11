#!/usr/bin/env python3
"""Bilingual-content eval — the Python half of bilingual-content.md §7.

Two postcondition families, mirrored by `engine/erlang/test/bilingual_conformance.escript`:

  1. SCHEMA (the agent's output) — the user-facing free-text leaf `LenderRec.reasoning`
     is a `LocalizedText` ({vi, en}), forcing the LLM to author BOTH languages; and the
     §98 postcondition still holds (no number-typed field anywhere in `LenderFitLeaves`,
     so the LLM cannot author a regulated figure).

  2. AUTHORED COPY (the resolver's templates) — every template in the four copy docs
     (`kb.copy.{mortgage,eligibility,cash,ownership}`, as compiled into the artifact) is genuinely
     bilingual: vi and en both non-empty, vi != en, and vi carries a Vietnamese diacritic
     (a >127 codepoint). This is the build-time guard against an English string silently
     authored into the `vi` slot (English is ASCII). The diacritic heuristic is tuned to
     the current copy (every vi string has diacritics); a legitimately all-ASCII vi (only
     proper nouns) would false-fail — none exist today; relax per-template if one is added.

Run from repo root.
"""

import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
ARTIFACT = ROOT / "engine" / "erlang" / "priv" / "kb" / "artifact.json"
COPY_DOCS = ["kb.copy.mortgage", "kb.copy.eligibility", "kb.copy.cash", "kb.copy.ownership"]


# --- (1) schema postconditions ----------------------------------------------

def reasoning_is_localized():
    """LenderRec.reasoning must be a {vi, en} object of two strings."""
    sys.path.insert(0, str(ROOT / "engine" / "python"))
    from planner import LenderFitLeaves  # noqa: E402
    schema = LenderFitLeaves.model_json_schema()
    defs = schema.get("$defs", {})
    rec = defs.get("LenderRec", {})
    ref = rec.get("properties", {}).get("reasoning", {}).get("$ref", "")
    target = defs.get(ref.split("/")[-1], {})
    props = target.get("properties", {})
    ok = (props.get("vi", {}).get("type") == "string"
          and props.get("en", {}).get("type") == "string")
    return ok, ref.split("/")[-1] or "<none>"


def schema_has_no_number():
    sys.path.insert(0, str(ROOT / "engine" / "python"))
    from planner import LenderFitLeaves  # noqa: E402
    schema = LenderFitLeaves.model_json_schema()
    bad = []
    _walk_for_numbers(schema, schema.get("$defs", {}), bad, "LenderFitLeaves")
    return bad


def _walk_for_numbers(node, defs, bad, path):
    if not isinstance(node, dict):
        return
    if node.get("type") in ("number", "integer"):
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


# --- (2) authored-copy postconditions ---------------------------------------

def has_vietnamese(s):
    return any(ord(c) > 127 for c in s)


def check_template(tid, pair):
    """Return a failure string, or None if the {vi, en} template is well-formed."""
    if not isinstance(pair, dict) or set(pair) < {"vi", "en"}:
        return f"{tid}: not a {{vi, en}} object"
    vi, en = pair.get("vi", ""), pair.get("en", "")
    if not vi or not en:
        return f"{tid}: empty half (vi={vi!r}, en={en!r})"
    if vi == en:
        return f"{tid}: vi == en (English fallback in vi slot?)"
    if not has_vietnamese(vi):
        return f"{tid}: vi has no Vietnamese diacritic (English in vi slot?)"
    return None


def main():
    if not ARTIFACT.is_file():
        print(f"FAIL — artifact not found: {ARTIFACT.relative_to(ROOT)} "
              f"(run engine/build/kb_compiler.py first)")
        return 2
    artifact = json.loads(ARTIFACT.read_text())
    fails, n = [], 0

    # (1) schema
    n += 1
    ok, target = reasoning_is_localized()
    if not ok:
        fails.append(f"LenderRec.reasoning is not LocalizedText (resolved to {target})")

    n += 1
    bad = schema_has_no_number()
    if bad:
        fails.append(f"§98: number-typed field(s) in agent schema: {bad}")

    # (2) authored copy
    for slug in COPY_DOCS:
        entry = artifact["kb"].get(slug)
        if not entry:
            n += 1
            fails.append(f"{slug}: copy doc missing from artifact")
            continue
        copy = entry["content_json"].get("copy", {})
        if not copy:
            n += 1
            fails.append(f"{slug}: no copy block")
            continue
        for tid, pair in copy.items():
            n += 1
            f = check_template(f"{slug}/{tid}", pair)
            if f:
                fails.append(f)

    print("bilingual eval — schema + authored copy (bilingual-content.md §7)\n")
    if fails:
        for f in fails:
            print(f"  FAIL   {f}")
        print(f"\nFAIL — {len(fails)}/{n} bilingual checks failed")
        return 1
    print(f"PASS — all {n} bilingual checks green "
          f"({len(COPY_DOCS)} copy docs + agent schema)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
