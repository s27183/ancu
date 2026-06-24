#!/usr/bin/env python3
"""KB + blueprint artifact compiler (build-time, engine-owned).

Promotes the old structural sweep (tests/validate_build.py) into the compiler
§11.9 specifies: it parses every `docs/kb/*.md` and `docs/blueprints/*.md`,
**materializes the resolver-input registry**, runs the two missing gates
(reference-integrity + coverage), and **emits the artifact** the engine loads
into `persistent_term` at boot.

Why this lives in `engine/build/` (not `engine/python/` sidecars, not a repo-root
`build/`): it is engine-scoped on the two properties that matter — its output
(`engine/erlang/priv/kb/artifact.json`) and its sole consumer (the engine) are
both the engine. Build tooling lives within the half it serves, so `engine/` and
`shell/` stay independently deployable (constraint #11). It reads repo-root
`docs/` as shared-git-SOT input; that doesn't make it repo-scoped.

Grounding (architecture.md §11.9):
  - Registry = union of upstream components' `outcome_schema` fields, namespaced
    by outcome TYPE (`profile.*` ⊕ `applicant.*` ⊕ `property_fit.*` ⊕ `suburb.*`).
    Registry fields are namespaced BY CONSTRUCTION → a *bare* token (`location_tier`)
    cannot be a registry field; it is a resolver-local intermediate (§11.9:256),
    exempt from reference-integrity. No new `content_json` syntax to declare it
    (the declarative-fixed-vocabulary rule, §11.9:427).
  - `applicant.*` is the registry projection of the `profile.applicants` element
    (§11.9:246) — flat field names, type-enriched from the `applicants` parameter.
  - A `fills` rule names the leaf it produces (`{component}.{param-path}`, or an
    `applicant.*` derived-fact leaf); the gate is coverage (every fill maps to a
    real slot) + reference integrity (every `field`/key-dim resolves to a registry
    field or a resolver-local; every `ref` to a known leaf/slot; every `stacking`
    slug to a KB doc) — §11.9:428.

Scope: an in-scope SET of blueprints (Wedge 1a: `fhb-domestic-au`; Mode-C activation
adds `investor-domestic-au`). **Structural** gates (slug==path, renderer-in-enum,
pipeline-acyclic) are mode-independent and run over EVERY blueprint/doc — a B/C/D
blueprint is an authored part of the working agreement, so structural drift there is
real drift. **Semantic** gates (reference-integrity, coverage, type-compat) need a
materialized registry, so they run **per in-scope blueprint, each against its own
registry** (architecture §11.9 "the registry is per-blueprint"): outcome-type names
are shared across modes (`profile`, `disposition`) but their fields/enums diverge
(e.g. `disposition.cgt_status` is `[exempt, to_verify]` vs `[computed, to_verify]`),
so a single global registry could not represent both. A KB doc anchored by an in-scope
blueprint is gated against THAT blueprint's registry; a doc no in-scope blueprint
anchors (the unbuilt B/D modes) is parsed structurally and reported as INVENTORY,
never a failure (the standing scope call). The DAG-upstream *scoping* of the registry
(a field must be produced by a component upstream of its consumer, not merely exist
somewhere) is a documented future strengthening — see STRENGTHENINGS below.

STRENGTHENINGS (not v1):
  - DAG-scoped reference integrity (field ∈ consumer's ancestors, not global).
  - Full coverage direction (every resolver-fillable param HAS a rule), which
    needs the resolver/agent fill-path classification (agentic-boundary.md).
  - Type-compat for `applicant.firb_required` and other derived leaves whose
    type is not declared in a parameter (currently reported as type-unknown).
"""
import json
import re
import sys
import pathlib

ROOT = pathlib.Path(__file__).resolve().parents[2]
KB = ROOT / "docs" / "kb"
BP = ROOT / "docs" / "blueprints"
ARTIFACT_OUT = ROOT / "engine" / "erlang" / "priv" / "kb" / "artifact.json"

# The in-scope SET — every blueprint whose registry is materialized + semantically
# gated + emitted (architecture §11.9, engine-contract §9.1). The runtime selects the
# blueprint per plan-card from its blueprint_slug; activating one mode never dormants
# another. A blueprint outside this set is still structurally gated, but its semantic
# gates are deferred and its anchors reported as inventory.
IN_SCOPE_BLUEPRINTS = {"fhb-domestic-au", "investor-domestic-au"}

# architecture.md §11.9 renderer enum (13 members).
RENDERER_ENUM = {
    "summary-card", "swimlane-diagram", "checklist", "data-table", "calculator",
    "buying-strategy-card", "decision-trail", "risk-flag-list", "comparison-grid",
    "opportunity-card", "scheme-stack-card", "firb-workflow-card", "family-view-card",
}

# Declared external read-namespaces (not produced by a blueprint component):
# the property card + suburb enrichment (§11.9:244), and the per-journey `plan.*`
# input facts (§11.9 "the plan.* namespace" — sourced from plan_cards journey state,
# engine-contract §9.1, not a component outcome). Referenced fields under these
# resolve-as-external (existence unverifiable here), never a failure.
EXTERNAL_NS = {"suburb", "property", "property_card", "plan"}

NUMERIC_TYPES = {
    "integer", "money", "number", "percentage", "money_per_year", "money_per_month",
    "money_per_quarter", "money_per_week", "integer_0_100", "percentage_0_100",
    "integer_0_10", "money_range", "percentage_0_100",
}
NUMERIC_OPS = {"gte", "gt", "lte", "lt", "between"}
SET_OPS = {"in", "nin"}
ALL_OPS = NUMERIC_OPS | SET_OPS | {"eq", "neq"}

# --- bilingual copy-template gate (outcome-conformance.md §9 step 1) ---------- #
# The required locale set, the single source of truth for the build-time half of
# the bilingual invariant. LIVES HERE for now; outcome-conformance.md §6 moves it to
# the artifact (so the seam check, the generated LocalizedText, and the shell all read
# one declaration). Keeping the gate driven off this constant makes that move a one-liner.
LOCALES = ("vi", "en")

# Per-locale anti-fallback heuristics — ISOLATED on purpose (outcome-conformance.md §3):
# the load-bearing, locale-agnostic check is "all locales present, non-empty, pairwise
# distinct"; these per-locale predicates are an extra net (a vi string copied from en would
# be all-ASCII), NEVER the core rule. Add zh -> add an entry, nothing else changes.
LOCALE_VALIDATORS = {
    "vi": (lambda s: any(ord(c) > 127 for c in s),
           "vi has no non-ASCII char (English copied into the vi slot?)"),
}


def check_copy_template(pair, locales=LOCALES):
    """Return an error string if a `copy` template is not well-formed in every locale,
    else None. Well-formed = a dict carrying every locale as a non-empty string, all
    pairwise-distinct (the anti-fallback), each passing its per-locale heuristic.

    Boundary (outcome-conformance.md §3): a template whose `vi` is legitimately all-ASCII
    (only proper nouns) would false-fail the vi heuristic — none exist today; when one
    appears, relax LOCALE_VALIDATORS for it. The gate is fail-closed so that relaxation is
    a conscious decision, not a silent gap."""
    if not isinstance(pair, dict):
        return "not a {locale: text} object"
    vals = []
    for loc in locales:
        v = pair.get(loc)
        if not isinstance(v, str) or not v:
            return f"missing/empty locale {loc!r}"
        check = LOCALE_VALIDATORS.get(loc)
        if check and not check[0](v):
            return check[1]
        vals.append(v)
    if len(set(vals)) != len(vals):
        return "locales not pairwise-distinct (English fallback in another slot?)"
    return None


# --------------------------------------------------------------------------- #
# Tolerant JSONC parsing (content_json blocks carry // and /* */ comments and
# trailing commas — json.loads alone fails on them).
# --------------------------------------------------------------------------- #
def strip_jsonc(s):
    """Remove // and /* */ comments (string-aware) and trailing commas."""
    out, i, n = [], 0, len(s)
    in_str, quote = False, ""
    while i < n:
        c = s[i]
        if in_str:
            out.append(c)
            if c == "\\" and i + 1 < n:
                out.append(s[i + 1]); i += 2; continue
            if c == quote:
                in_str = False
            i += 1; continue
        if c in ('"', "'"):
            in_str, quote = True, c; out.append(c); i += 1; continue
        if c == "/" and i + 1 < n and s[i + 1] == "/":
            while i < n and s[i] != "\n":
                i += 1
            continue
        if c == "/" and i + 1 < n and s[i + 1] == "*":
            i += 2
            while i + 1 < n and not (s[i] == "*" and s[i + 1] == "/"):
                i += 1
            i += 2; continue
        out.append(c); i += 1
    res = "".join(out)
    res = re.sub(r",(\s*[}\]])", r"\1", res)  # trailing commas
    return res


def parse_jsonc(block):
    return json.loads(strip_jsonc(block))


def fenced_jsonc_after(text, marker):
    """First ```jsonc fenced block after `marker`; None if marker/block absent."""
    pos = text.find(marker)
    if pos < 0:
        return None
    m = re.search(r"```jsonc\s*\n(.*?)\n```", text[pos:], re.S)
    return m.group(1) if m else None


def rules_block(text):
    """The `## Rules` content_json block, or None for a pure-prose doc."""
    pos = text.find("## Rules")
    if pos < 0:
        return None
    m = re.search(r"```jsonc\s*\n(.*?)\n```", text[pos:], re.S)
    return m.group(1) if m else None


def ui_tabs_block(text):
    """The blueprint's `ui_tabs` declaration (plan-card-lifecycle-restoration.md §3),
    or None. DISCOVERED, not marker-bound: scan every ```jsonc block and return the
    first that parses to a dict carrying a top-level `ui_tabs` key — so a wording
    change to the prose heading above it can't silently un-find the declaration."""
    for m in re.finditer(r"```jsonc\s*\n(.*?)\n```", text, re.S):
        try:
            obj = parse_jsonc(m.group(1))
        except Exception:  # noqa: BLE001 - a malformed sibling block isn't ours
            continue
        if isinstance(obj, dict) and "ui_tabs" in obj:
            return obj["ui_tabs"]
    return None


# --------------------------------------------------------------------------- #
# Type helpers
# --------------------------------------------------------------------------- #
def parse_type_string(s):
    """An outcome-schema field type string -> (base, options|None)."""
    s = s.strip()
    m = re.match(r"enum\s*\[([^\]]*)\]", s)
    if m:
        return "enum", [x.strip() for x in m.group(1).split(",") if x.strip()]
    if s.startswith("array<"):
        return "array", None
    return s, None


def split_top_level(s, sep=","):
    """Split on `sep` only at bracket depth 0 (so an `enum [a, b]` sub-type isn't cut)."""
    out, depth, cur = [], 0, []
    for ch in s:
        if ch in "[{(":
            depth += 1
        elif ch in "]})":
            depth -= 1
        if ch == sep and depth == 0:
            out.append("".join(cur))
            cur = []
        else:
            cur.append(ch)
    if cur:
        out.append("".join(cur))
    return out


def parse_object_entity(tstr):
    """A nested-object outcome-field type string `{ f: type, ... }` (optionally
    `| null`) -> {field: meta{type,options}|None}; None if `tstr` is not an object.
    A sub-field written name-only (no `: type`) is type-unknown (None) — the same
    graceful state as a typeless applicant field. (registry-projection.md §2.)"""
    s = re.sub(r"\s*\|\s*null\s*$", "", tstr.strip()).strip()
    if not (s.startswith("{") and s.endswith("}")):
        return None
    fields = {}
    for part in split_top_level(s[1:-1]):
        part = part.strip()
        if not part:
            continue
        if ":" in part:
            name, _, typ = part.partition(":")
            base, opts = parse_type_string(typ.strip())
            fields[name.strip()] = {"type": base, "options": opts}
        else:
            fields[part] = None
    return fields


# The outcome-field type vocabulary the seam validator recognises (outcome-conformance.md
# §2). `localized_text` is the bilingual clause (the first clause of the general property);
# every other type is single-valued (a figure/enum/id — never a {vi,en} map, §98). A type
# outside this set parses to {"kind": "unknown"} and is NOT checked at the seam — graceful
# for a name-only sub-field or a per-property custom type (e.g. comparable_sale).
LOCALIZED_TYPE = "localized_text"
SCALAR_TYPES = {
    "string", "bool", "date", "object", "number",
    "money", "money_range", "money_per_year", "integer", "integer_0_10",
}


def parse_field_type(tstr):
    """An outcome-schema type string -> a recursive {kind: ...} tree the engine walks at
    the commit seam (outcome-conformance.md §2). Nullability is implicit-universal at the
    validator — an honest-partial `null` conforms to any field — so a trailing `| null` is
    stripped here rather than modelled. Single parser, Python-side: Erlang reads the tree,
    never re-parses type strings (one source of parsing, [[ground-design-choices]])."""
    s = re.sub(r"\s*\|\s*null\s*$", "", tstr.strip()).strip()
    m = re.match(r"enum\s*\[([^\]]*)\]$", s)
    if m:
        return {"kind": "enum",
                "options": [x.strip() for x in m.group(1).split(",") if x.strip()]}
    if s.startswith("array<") and s.endswith(">"):
        return {"kind": "array", "element": parse_field_type(s[6:-1])}
    if s.startswith("{") and s.endswith("}"):
        fields = {}
        for part in split_top_level(s[1:-1]):
            part = part.strip()
            if not part:
                continue
            name, sep, typ = part.partition(":")
            fields[name.strip()] = parse_field_type(typ.strip()) if sep else {"kind": "unknown"}
        return {"kind": "object", "fields": fields}
    if s == LOCALIZED_TYPE:
        return {"kind": "localized"}
    if s in SCALAR_TYPES:
        return {"kind": "scalar", "type": s}
    return {"kind": "unknown", "raw": s}


def string_leaf_paths(node, prefix=""):
    """Dotted paths of every `string`-typed scalar inside a parsed field type — the §3
    declarative-boundary nudge: prose mistakenly declared `string` (not localized_text)
    escapes the seam check, so the compiler REPORTS each for human review (info, not a
    hard fail — many strings are genuinely ids/codes/names)."""
    k = node.get("kind")
    if k == "scalar" and node.get("type") == "string":
        return [prefix or "<root>"]
    if k == "array":
        return string_leaf_paths(node["element"], prefix + "[]")
    if k == "object":
        out = []
        for f, sub in node["fields"].items():
            out += string_leaf_paths(sub, f"{prefix}.{f}" if prefix else f)
        return out
    return []


def flatten_param_slots(d, prefix=""):
    """Param dict -> {dotted_path: meta}. A node WITH a `type` key is a leaf slot
    (do not recurse into it — milestones/arrays carry nested `value`)."""
    slots = {}
    for k, v in d.items():
        path = f"{prefix}{k}"
        if isinstance(v, dict) and "type" in v:
            slots[path] = v
        elif isinstance(v, dict):
            slots.update(flatten_param_slots(v, path + "."))
    return slots


def flatten_element_meta(d, acc):
    """Applicant element -> {leaf_name: meta} (ownership_history flattened to the
    leaf name, matching the flat `applicant.*` projection)."""
    for k, v in d.items():
        if isinstance(v, dict) and "type" in v:
            acc[k] = {"type": v["type"], "options": v.get("options")}
        elif isinstance(v, dict):
            flatten_element_meta(v, acc)
    return acc


# --------------------------------------------------------------------------- #
# Blueprint parsing
# --------------------------------------------------------------------------- #
class Component:
    def __init__(self, name):
        self.name = name
        self.outcome_type = None
        self.outcome_fields = {}     # field -> type string
        self.param_slots = {}        # "{component}.path" -> meta
        self.anchors = []
        self.renderers = []


def parse_blueprint(path):
    text = path.read_text()
    slug = "blueprints." + path.stem
    comps = []
    # numbered component sections: "### 1. buyer_profile"
    heads = list(re.finditer(r"^### (\d+)\.\s+(\w+)\b", text, re.M))
    for idx, h in enumerate(heads):
        name = h.group(2)
        end = heads[idx + 1].start() if idx + 1 < len(heads) else len(text)
        body = text[h.end():end]
        c = Component(name)
        for line in re.findall(r"^\*\*KB anchors:\*\*(.*)$", body, re.M):
            c.anchors += re.findall(r"kb\.[a-z0-9.\-]+", line)
        for line in re.findall(r"^\*\*Renderer:\*\*(.*)$", body, re.M):
            c.renderers += re.findall(r"`([a-z\-]+)`", line)
        ob = fenced_jsonc_after(body, "**Outcome schema:**")
        if ob:
            o = parse_jsonc(ob)
            c.outcome_type = o.get("type")
            c.outcome_fields = o.get("fields", {})
        pb = fenced_jsonc_after(body, "**Parameters:**")
        if pb:
            params = parse_jsonc(pb)
            c.param_slots = flatten_param_slots(params, c.name + ".")
            c._params = params  # raw params; the identity component's drive applicant/entity types
        comps.append(c)
    # pipeline DAG: "producer → outcome: NAME (reads: a, b)"
    producer, reads = {}, {}
    for comp, out, rd in re.findall(
        r"^(\w+)\s*→\s*outcome:\s*(\w+)\s*(?:\(reads:\s*([^)]*)\))?", text, re.M
    ):
        producer[out] = comp
        reads[comp] = [x.strip() for x in rd.split(",") if x.strip()] if rd else []
    return slug, comps, producer, reads, ui_tabs_block(text)


# --------------------------------------------------------------------------- #
# Registry materialization (the foundation reasoning binds to)
# --------------------------------------------------------------------------- #
class Registry:
    def __init__(self):
        self.outcome_fields = {}     # outcome_type -> {field: type string}
        self.applicant_fields = {}   # field -> meta {type, options}|None
        self.entities = {}           # namespace -> {fields: {field: meta}, cardinality}
        self.param_slots = {}        # "{component}.path" -> meta  (leaf slots)
        self.leaves = {}             # leaf path -> [filling slugs]

    def field_meta(self, ns, rest):
        """(status, meta) for a dotted read token ns.rest.
        status ∈ {field, external, missing_ns, missing_field}."""
        # projected structured-entity namespaces (registry-projection.md): `applicant`
        # (per-element) + nested objects like `non_buying_partner` (singleton).
        if ns in self.entities:
            fields = self.entities[ns]["fields"]
            if rest in fields:
                return "field", fields[rest]
            return "missing_field", None
        if ns in EXTERNAL_NS:
            return "external", None
        if ns in self.outcome_fields:
            fields = self.outcome_fields[ns]
            if rest in fields:
                base, opts = parse_type_string(fields[rest])
                return "field", {"type": base, "options": opts}
            return "missing_field", None
        return "missing_ns", None

    def ref_exists(self, ref):
        if ref in self.leaves or ref in self.param_slots:
            return True
        if "." in ref:
            ns, _, rest = ref.partition(".")
            st, _ = self.field_meta(ns, rest)
            if st in ("field", "external"):
                return True
        return False


def build_registry(components):
    reg = Registry()
    bp_comp = None
    for c in components:
        if c.outcome_type:
            reg.outcome_fields.setdefault(c.outcome_type, {}).update(c.outcome_fields)
        reg.param_slots.update(c.param_slots)
        # The identity component is the one producing the canonical `profile` outcome —
        # `buyer_profile` (Mode A) or `investor_profile` (Mode C); keyed by outcome type,
        # not name, so the applicant/entity element types are sourced whichever mode runs.
        if c.outcome_type == "profile":
            bp_comp = c
    # applicant.* projection: names from the profile outcome element, types
    # enriched from the buyer_profile `applicants` parameter element.
    prof = reg.outcome_fields.get("profile", {})
    appl_str = prof.get("applicants", "")
    m = re.search(r"\{([^}]*)\}", appl_str)
    names = [x.strip() for x in m.group(1).split(",")] if m else []
    elem_meta = {}
    if bp_comp is not None and getattr(bp_comp, "_params", None):
        appl_param = bp_comp._params.get("applicants", {})
        val = appl_param.get("value")
        if isinstance(val, list) and val:
            flatten_element_meta(val[0], elem_meta)
    for name in names:
        reg.applicant_fields[name] = elem_meta.get(name)  # None => type-unknown
    # `applicant` is the PER-ELEMENT instance of the structured-entity rule (its types
    # are sourced from the parameter element above — the array entity's SOT, §2).
    reg.entities["applicant"] = {"fields": reg.applicant_fields, "cardinality": "per_element"}
    # SINGLETON object entities: every outcome field typed as a nested object `{ ... }`
    # projects its sub-fields into a namespace = the field name (registry-projection.md §1/§3).
    # `array<{...}>` fields (applicants) are NOT matched here — they are per-element entities
    # under an explicit alias (only `applicant` today). Types come from the producing
    # component's same-named PARAMETER when present (the entity's SOT — flattened like the
    # applicant element, so a nested `ownership_history` group flattens to leaf names), else
    # from inline type-string types. Purely additive: only makes previously-`missing_ns`
    # nested tokens resolvable, never changes an existing resolution.
    bp_params = getattr(bp_comp, "_params", None) or {}
    for fields in reg.outcome_fields.values():
        for fname, tstr in fields.items():
            inline = parse_object_entity(tstr)
            if inline is None:
                continue
            typed = {}
            param = bp_params.get(fname)
            if isinstance(param, dict):
                flatten_element_meta(param, typed)
            ent_fields = {n: (typed.get(n) if typed.get(n) is not None else inline.get(n))
                          for n in inline}
            reg.entities[fname] = {"fields": ent_fields, "cardinality": "singleton"}
    return reg


# --------------------------------------------------------------------------- #
# KB doc parsing
# --------------------------------------------------------------------------- #
def parse_kb_doc(path):
    text = path.read_text()
    slug_m = re.search(r"^slug:\s*(\S+)", text, re.M)
    eff_m = re.search(r"^effective_from:\s*(\S+)", text, re.M)
    ver_m = re.search(r"^last_verified:\s*(\S+)", text, re.M)
    rb = rules_block(text)
    content_json = None
    parse_error = None
    if rb is not None:
        try:
            content_json = parse_jsonc(rb)
        except Exception as e:  # noqa: BLE001 - report, do not crash the build
            parse_error = str(e)
    # content_md = everything before "## Rules"
    cut = text.find("## Rules")
    fm_end = text.find("---", 3)
    body_start = text.find("\n", fm_end) + 1 if fm_end > 0 else 0
    content_md = (text[body_start:cut] if cut > 0 else text[body_start:]).strip()
    return {
        "slug": slug_m.group(1) if slug_m else None,
        "effective_from": eff_m.group(1) if eff_m else None,
        "last_verified": ver_m.group(1) if ver_m else None,
        "content_md": content_md,
        "content_json": content_json,
        "parse_error": parse_error,
        "path": path,
    }


def iter_rule_fields(rule):
    """Yield ('field', token) and ('ref', token) and ('keydim', token) from a rule."""
    kind = rule.get("kind")
    if kind == "criteria":
        yield from _iter_criteria(rule)
    elif kind == "lookup":
        for dim in rule.get("key", []):
            yield "keydim", dim
        # a row value may itself be a ref — rare; not modelled
    # parameter: fixed value, no field references


def _iter_criteria(node):
    for crit in node.get("criteria", []):
        if "combine" in crit:
            yield from _iter_criteria(crit)
            continue
        if "field" in crit:
            yield "field", crit["field"], crit
        if "ref" in crit:
            yield "ref", crit["ref"], crit


# --------------------------------------------------------------------------- #
# Gates
# --------------------------------------------------------------------------- #
def check_type_compat(crit, meta):
    """Return an error string if the criterion is type-incompatible, else None.
    Skips silently when type is unknown (reported as 'unchecked' by the caller)."""
    if meta is None or meta.get("type") is None:
        return "unchecked"
    base = meta["type"]
    base, _ = parse_type_string(base) if isinstance(base, str) else (base, None)
    opts = meta.get("options")
    op = crit.get("op")
    has_value = "value" in crit
    val = crit.get("value")
    if op in NUMERIC_OPS:
        if base not in NUMERIC_TYPES:
            return f"numeric op '{op}' on non-numeric field type '{base}'"
        if op == "between" and not (isinstance(val, list) and len(val) == 2):
            return "op 'between' needs a 2-element value"
    if op in SET_OPS:
        if not isinstance(val, list):
            return f"set op '{op}' needs a list value"
        if base == "enum" and opts:
            bad = [v for v in val if v not in opts]
            if bad:
                return f"value(s) {bad} not in enum options {opts}"
    if op in ("eq", "neq") and has_value and base == "enum" and opts:
        if not isinstance(val, list) and val not in opts:
            return f"value {val!r} not in enum options {opts}"
    return None


def detect_cycle(producer, reads):
    """(cycle_path|None, externals) for a blueprint's `producer→outcome (reads:)` DAG.
    Structural + mode-independent — run over every blueprint, in-scope or not."""
    nodes = set(reads)
    edges = {c: set() for c in nodes}
    externals = set()
    for comp, outs in reads.items():
        for o in outs:
            if o in producer:
                edges[comp].add(producer[o])
            else:
                externals.add(o)
    color = {c: 0 for c in nodes}
    cyc = []

    def dfs(u, stack):
        color[u] = 1
        for v in edges.get(u, ()):
            if color.get(v) == 1:
                cyc.extend(stack + [u, v]); return True
            if color.get(v, 0) == 0 and dfs(v, stack + [u]):
                return True
        color[u] = 2
        return False

    has_cycle = any(color.get(c, 0) == 0 and dfs(c, []) for c in nodes)
    return (cyc if has_cycle else None), externals


def kb_exists(slug):
    """A `kb.*` slug resolves to a docs/ file (slug == path, GATE 1's inverse)."""
    return (ROOT / "docs" / (slug.replace(".", "/") + ".md")).is_file()


def semantic_gates(stem, comps, kb_docs, fails, info):
    """Materialize ONE blueprint's registry and run its SEMANTIC gates (architecture
    §11.9 "the registry is per-blueprint"): GATE 6 reference-integrity + GATE 7 coverage
    against THIS blueprint's registry, the §3 string-leaf nudge, the leaf->filler map,
    and multi-fill reporting. Appends to the shared fails/info lists (labelled by stem)
    and returns (reg, anchors, reg_stats)."""
    reg = build_registry(comps)
    anchors = set()
    for c in comps:
        anchors.update(c.anchors)

    # §3 nudge: outcome fields declared `string` (confirm not prose). Info, never a hard
    # fail (ids / scheme names / currency codes are legitimately `string`).
    n_string = 0
    for otype, fields in sorted(reg.outcome_fields.items()):
        for f, tstr in sorted(fields.items()):
            for path in string_leaf_paths(parse_field_type(tstr), f):
                info.append(f"[outcome-string] {stem}/{otype}.{path} — declared `string`; "
                            f"confirm not user-facing prose (else localized_text)")
                n_string += 1

    # leaf -> filler(s) map for this blueprint's anchored docs.
    for slug in anchors:
        doc = kb_docs.get(slug)
        if not doc or not doc.get("content_json"):
            continue
        for fill in doc["content_json"].get("fills", []):
            leaf = fill.get("leaf")
            if leaf:
                reg.leaves.setdefault(leaf, []).append(slug)

    # GATE 6 + 7: reference-integrity + coverage, against THIS registry.
    ref_checked = ref_unchecked_type = 0
    for slug in sorted(anchors):
        doc = kb_docs.get(slug)
        cj = doc.get("content_json") if doc else None
        if cj is None:
            continue
        for fill in cj.get("fills", []):
            leaf = fill.get("leaf")
            rule = fill.get("rule", {})
            # COVERAGE 7b: leaf maps to a real slot
            if leaf:
                if leaf.startswith("applicant."):
                    name = leaf.split(".", 1)[1]
                    if name not in reg.applicant_fields:
                        fails.append(f"[coverage] {stem}/{slug}: leaf {leaf} not an applicant field")
                elif leaf not in reg.param_slots:
                    fails.append(f"[coverage] {stem}/{slug}: leaf {leaf} not a declared slot")
            # REFERENCE-INTEGRITY 6a/6b/6d
            for item in iter_rule_fields(rule):
                tag, tok = item[0], item[1]
                crit = item[2] if len(item) > 2 else None
                if tag in ("field", "keydim"):
                    if "." not in tok:
                        info.append(f"[resolver-local] {stem}/{slug}: {tok}")  # bare → exempt
                        continue
                    ns, _, rest = tok.partition(".")
                    st, meta = reg.field_meta(ns, rest)
                    if st == "missing_ns":
                        fails.append(f"[ref-integrity] {stem}/{slug}: unknown namespace in {tok!r}")
                    elif st == "missing_field":
                        fails.append(f"[ref-integrity] {stem}/{slug}: {tok!r} not a registry field")
                    elif st == "external":
                        info.append(f"[external] {stem}/{slug}: {tok} (existence unverifiable)")
                    elif st == "field" and tag == "field" and crit is not None:
                        res = check_type_compat(crit, meta)
                        if res == "unchecked":
                            ref_unchecked_type += 1
                        elif res:
                            fails.append(f"[type] {stem}/{slug}: field {tok}: {res}")
                        else:
                            ref_checked += 1
                elif tag == "ref":
                    if not reg.ref_exists(tok):
                        fails.append(f"[ref-integrity] {stem}/{slug}: ref {tok!r} resolves to nothing")
        # COVERAGE 6c: stacking slugs resolve
        for stk in (cj.get("stacking") or {}).values():
            if isinstance(stk, list):
                for ref in stk:
                    if isinstance(ref, str) and ref.startswith("kb.") and not kb_exists(ref):
                        fails.append(f"[stacking] {stem}/{slug}: ref {ref} resolves to no KB doc")

    # multi-filled leaves: report (competitive slots like state_concession are by design;
    # a same-component non-slot collision would be a smell — surfaced, not auto-failed).
    for leaf, fillers in sorted({k: v for k, v in reg.leaves.items() if len(v) > 1}.items()):
        info.append(f"[multi-fill] {stem}/{leaf} <- {sorted(fillers)}")

    reg_stats = {
        "outcome_namespaces": sorted(reg.outcome_fields),
        "outcome_field_count": sum(len(v) for v in reg.outcome_fields.values()),
        "applicant_fields": len(reg.applicant_fields),
        "param_slots": len(reg.param_slots),
        "leaves": len(reg.leaves),
        "string_leaves": n_string,
        "type_checks_passed": ref_checked,
        "type_unchecked": ref_unchecked_type,
        "anchors": len(anchors),
    }
    return reg, anchors, reg_stats


def run(emit=False):
    fails, warns, info = [], [], []
    stats = {}

    # ---- parse blueprints ------------------------------------------------- #
    # A blueprint is a DAG of components (constraint #5), so a file under
    # docs/blueprints/ with NEITHER components NOR a producer→outcome pipeline is
    # definitionally not a blueprint (e.g. scenarios.md is a scenario register) —
    # skip it, logged so the drop is visible. The condition is "no component
    # structure at all" (not "0 components") so the skip never swallows a real
    # blueprint: the B/C/D component-header regex now matches headers carrying
    # parenthetical/★ suffixes (`### N. name (variant)`), so all four modes parse
    # their components AND their DAG and are structurally gated (slug, renderer
    # enum, acyclicity) over every blueprint. (Every IN_SCOPE_BLUEPRINTS member is
    # asserted present below, so an in-scope mode can never be skipped unnoticed.)
    blueprints = {}
    for bp in sorted(BP.glob("*.md")):
        slug, comps, producer, reads, ui_tabs = parse_blueprint(bp)
        if not comps and not producer:
            info.append(f"[skip] {slug}: no component pipeline — not a blueprint (constraint #5)")
            continue
        blueprints[bp.stem] = (slug, comps, producer, reads, ui_tabs)

    missing_scope = sorted(b for b in IN_SCOPE_BLUEPRINTS if b not in blueprints)
    if missing_scope:
        for b in missing_scope:
            fails.append(f"in-scope blueprint {b} not found")
        return fails, warns, info, stats, None

    # ---- parse all KB docs (GATE 1 slug==path, GATE 5 parse — mode-independent) #
    kb_docs = {}
    for f in sorted(KB.rglob("*.md")):
        doc = parse_kb_doc(f)
        rel = f.relative_to(ROOT / "docs").with_suffix("")
        expect = str(rel).replace("/", ".")
        if doc["slug"] != expect:
            fails.append(f"[slug] {f}: slug={doc['slug']} expect={expect}")
        if doc["slug"]:
            kb_docs[doc["slug"]] = doc
        if doc["parse_error"]:
            fails.append(f"[content_json] {doc['slug']}: parse error: {doc['parse_error']}")
    stats["kb_docs"] = len(kb_docs)

    # ---- GATE 8: bilingual copy-template well-formedness (all docs) -------- #
    # Every `copy` template is localized in every LOCALES locale (outcome-conformance.md
    # §9 step 1 — the build-time half of the bilingual invariant, fail-closed at deploy).
    # DISCOVERED, not enumerated: runs over EVERY doc carrying a `copy` block, so a new
    # kb.copy.* doc is gated the instant it compiles — no list to extend. Mode-independent
    # (copy is content, not registry-scoped), so it does not gate on in-scope anchors.
    copy_templates = 0
    for slug, doc in sorted(kb_docs.items()):
        cj = doc.get("content_json")
        copy = cj.get("copy") if isinstance(cj, dict) else None
        if not isinstance(copy, dict):
            continue
        for tid, pair in copy.items():
            copy_templates += 1
            err = check_copy_template(pair)
            if err:
                fails.append(f"[copy] {slug}/{tid}: {err}")
    stats["copy_templates"] = copy_templates

    # ---- per-blueprint registry materialization + SEMANTIC gates ---------- #
    # The registry is per-blueprint (architecture §11.9): each in-scope blueprint is
    # materialized + GATE-6/7-gated against its OWN registry, and emitted as
    # blueprints[slug].registry. Outcome-type names shared across modes (`profile`,
    # `disposition`) diverge in fields/enums, so a single global registry could not
    # represent both — the runtime selects the card's blueprint and reads that registry.
    registries = {}                # stem -> Registry
    all_in_scope_anchors = set()   # union over the in-scope set, for the inventory tally
    stats["registry"] = {}
    for stem in sorted(IN_SCOPE_BLUEPRINTS):
        _, comps, _, _, _ = blueprints[stem]
        reg, anchors, reg_stats = semantic_gates(stem, comps, kb_docs, fails, info)
        registries[stem] = reg
        all_in_scope_anchors |= anchors
        stats["registry"][stem] = reg_stats

    # ---- GATE 2: every blueprint kb_anchor resolves ----------------------- #
    for stem, (_, bcomps, _, _, _) in blueprints.items():
        anchors = set(a for c in bcomps for a in c.anchors)
        missing = sorted(a for a in anchors if not kb_exists(a))
        if stem in IN_SCOPE_BLUEPRINTS:
            for a in missing:
                fails.append(f"[anchor] {stem}: missing KB doc {a}")
        elif missing:
            info.append(f"[inventory] {stem}: {len(missing)} unbuilt anchor(s) "
                        f"(out-of-scope mode): {missing}")

    # ---- GATE 3: renderers in enum (all blueprints — structural, mode-independent) #
    for stem, (_, bcomps, _, _, _) in blueprints.items():
        for c in bcomps:
            bad = [r for r in c.renderers if r not in RENDERER_ENUM]
            if bad:
                fails.append(f"[renderer] {stem}/{c.name}: not in enum: {bad}")

    # ---- GATE 4: pipeline acyclic (all blueprints — structural, mode-independent) #
    stats["dag"] = {}
    for stem, (_, _, bproducer, breads, _) in blueprints.items():
        cyc, externals = detect_cycle(bproducer, breads)
        if cyc:
            fails.append(f"[pipeline] {stem}: CYCLE: {cyc}")
        if stem in IN_SCOPE_BLUEPRINTS:
            stats["dag"][stem] = {"components": len(breads), "externals": sorted(externals)}

    # ---- GATE 9: ui_tabs reference-integrity (all blueprints — structural) - #
    # The lifecycle tab spine (plan-card-lifecycle-restoration.md §3): each blueprint
    # declares an ORDERED tab subset of the shared vocabulary; every component a tab
    # names must be a real component of THAT blueprint, every kind in the enum, every
    # tab_id unique. Structural + mode-independent (no registry needed) → runs over
    # every blueprint, so B/C/D declarations are validated now though their modes are
    # dormant (plan-card-lifecycle-restoration.md §4). This is the gate that makes
    # "blueprint-driven tabs" a checked property, not a claim.
    # kinds: "components" (render the named components), "synthesis" (a shell-composed
    # overview, e.g. OverviewCard), "qa" (a shell-owned chat surface over the engine Q&A
    # stream — components: [] by design; not a component_filled), "flow" (the legal/temporal
    # spine: the swimlane IS the navigation and each phase opens a drill-down sheet; it still
    # names the components whose data the sheet composes). See lifecycle-simulation-model.md §7.
    KIND_ENUM = {"synthesis", "components", "qa", "flow"}
    stats["ui_tabs"] = {}
    for stem, (_, bcomps, _, _, ui_tabs) in blueprints.items():
        if not ui_tabs:
            fails.append(f"[ui_tabs] {stem}: no ui_tabs declaration")
            continue
        cnames = {c.name for c in bcomps}
        seen = set()
        for t in ui_tabs:
            tid = t.get("tab_id")
            if not tid:
                fails.append(f"[ui_tabs] {stem}: a tab is missing tab_id")
                continue
            if tid in seen:
                fails.append(f"[ui_tabs] {stem}: duplicate tab_id {tid!r}")
            seen.add(tid)
            kind = t.get("kind", "components")
            if kind not in KIND_ENUM:
                fails.append(f"[ui_tabs] {stem}/{tid}: kind {kind!r} not in {sorted(KIND_ENUM)}")
            missing = [c for c in t.get("components", []) if c not in cnames]
            if missing:
                fails.append(f"[ui_tabs] {stem}/{tid}: components not in blueprint: {missing}")
        if stem in IN_SCOPE_BLUEPRINTS:
            stats["ui_tabs"][stem] = [t.get("tab_id") for t in ui_tabs]

    # deferred docs: a content_json doc no in-scope blueprint anchors (inventory).
    stats["deferred_docs"] = sum(
        1 for slug, doc in kb_docs.items()
        if doc.get("content_json") is not None and slug not in all_in_scope_anchors
    )

    artifact = None
    if not fails:
        artifact = build_artifact(blueprints, registries, kb_docs)
        if emit:
            ARTIFACT_OUT.parent.mkdir(parents=True, exist_ok=True)
            ARTIFACT_OUT.write_text(
                json.dumps(artifact, indent=2, sort_keys=True, ensure_ascii=False) + "\n"
            )

    return fails, warns, info, stats, artifact


def registry_payload(reg):
    """One blueprint's registry, in the artifact's machine-readable shape — the engine
    reads it by blueprint slug at runtime (engine-contract §9.1)."""
    return {
        "outcome_fields": reg.outcome_fields,
        # Parsed recursive type tree per outcome field (parse_field_type) — the
        # machine-readable form the seam validator walks (outcome-conformance.md §2);
        # `localized_text` -> {kind: localized}, figures -> {kind: scalar}, etc.
        "outcome_types": {
            otype: {f: parse_field_type(t) for f, t in fields.items()}
            for otype, fields in reg.outcome_fields.items()
        },
        "applicant_fields": {k: v for k, v in reg.applicant_fields.items()},
        "entities": {ns: {"fields": e["fields"], "cardinality": e["cardinality"]}
                     for ns, e in sorted(reg.entities.items())},
        "param_slots": sorted(reg.param_slots),
        "leaves": {k: sorted(v) for k, v in reg.leaves.items()},
    }


def build_artifact(blueprints, registries, kb_docs):
    kb = {
        slug: {
            "effective_from": d["effective_from"],
            "last_verified": d["last_verified"],
            "content_md": d["content_md"],
            "content_json": d["content_json"],
        }
        for slug, d in kb_docs.items()
    }
    bps = {}
    for stem, (slug, comps, producer, reads, ui_tabs) in blueprints.items():
        entry = {
            "ui_tabs": ui_tabs or [],
            "components": [
                {"name": c.name, "outcome_type": c.outcome_type,
                 "anchors": c.anchors, "renderers": c.renderers,
                 # Fill-path classification (blueprint "Fill-path classification"
                 # block; agentic-boundary.md). The agent-path leaves carry
                 # `agent_reasoning_required: true`; everything else resolves
                 # deterministically. The engine derives the component's path:
                 # empty -> pure resolver (no sidecar, no usage); non-empty -> the
                 # listed leaves are agent, the rest resolver (a two-path component
                 # like mortgage_finance). reasoning_domain selects the leaf-fill
                 # prompt module (agentic-flow §3).
                 "agent_leaves": [
                     {"leaf": path, "reasoning_domain": meta.get("reasoning_domain")}
                     for path, meta in sorted(c.param_slots.items())
                     if meta.get("agent_reasoning_required") is True
                 ]}
                for c in comps
            ],
            "dag_reads": reads,
        }
        # The per-blueprint registry — present only for the in-scope set (an
        # out-of-scope blueprint is structurally parsed but not semantically
        # materialized). architecture §11.9 "the registry is per-blueprint".
        if stem in registries:
            entry["registry"] = registry_payload(registries[stem])
        bps[slug] = entry
    return {
        "schema_version": 1,
        # The in-scope SET (bare stems, the same identifier fh_engine_kb:blueprint/1
        # qualifies). The runtime selects the card's blueprint from this set and reads
        # that blueprint's registry; modes coexist (engine-contract §9.1).
        "in_scope_blueprints": sorted(IN_SCOPE_BLUEPRINTS),
        # The locale set is the single source of truth (outcome-conformance.md §6): the
        # compiler copy gate, the seam validator, the generated LocalizedText, and the
        # shell's display picker all read it here. Adding a locale touches LOCALES + the
        # per-locale validator registry — nowhere else. Snapshotted into the artifact so
        # git stays SOT and every fill's audit trail carries the locale set it was checked
        # against.
        "locales": list(LOCALES),
        "kb": kb,
        "blueprints": bps,
    }


def main():
    emit = "--no-emit" not in sys.argv
    fails, warns, info, stats, artifact = run(emit=emit)

    for stem in sorted(stats.get("registry", {})):
        rs = stats["registry"][stem]
        print(f"[{stem}] registry: outcome_fields={rs['outcome_field_count']} "
              f"applicant_fields={rs['applicant_fields']} param_slots={rs['param_slots']} "
              f"leaves={rs['leaves']} | ref-integrity: checked={rs['type_checks_passed']} "
              f"unchecked={rs['type_unchecked']} anchors={rs['anchors']} | "
              f"dag={json.dumps(stats.get('dag', {}).get(stem, {}))} | "
              f"ui_tabs={json.dumps(stats.get('ui_tabs', {}).get(stem, []))}")
    print(f"in-scope blueprints: {sorted(IN_SCOPE_BLUEPRINTS)} | deferred docs: "
          f"{stats.get('deferred_docs')}")
    print(f"kb docs: {stats.get('kb_docs')}")
    print(f"copy templates: {stats.get('copy_templates')} (bilingual gate, "
          f"locales={'+'.join(LOCALES)})")
    if info:
        print(f"\nINFO ({len(info)}):")
        for m in info:
            print("  " + m)
    if warns:
        print(f"\nWARN ({len(warns)}):")
        for m in warns:
            print("  " + m)
    print("\n" + "=" * 64)
    if fails:
        print(f"FAIL — {len(fails)} problem(s):")
        for m in fails:
            print("  " + m)
        return 1
    if emit and artifact is not None:
        print(f"PASS — artifact emitted: {ARTIFACT_OUT.relative_to(ROOT)}")
        print(f"       {len(artifact['kb'])} KB entries, "
              f"{len(artifact['blueprints'])} blueprints, "
              f"{len(stats.get('registry', {}))} in-scope registries")
    else:
        print("PASS — all gates green (no emit)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
