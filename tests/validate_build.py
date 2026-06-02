#!/usr/bin/env python3
"""Whole-build validation sweep across all four blueprint modes.

Checks (per CLAUDE.md testing approach + architecture §11.9):
  1. slug == path invariant for every docs/kb/*.md
  2. every `**KB anchors:**` slug in every blueprint resolves to a file
  3. every `**Renderer:**` token (split on +) is in the §11.9 enum
  4. each blueprint's component pipeline is acyclic
"""
import re, sys, pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
KB = ROOT / "docs" / "kb"
BP = ROOT / "docs" / "blueprints"

# Authoritative enum — architecture.md §11.9 (line 467-481 table)
RENDERER_ENUM = {
    "summary-card", "swimlane-diagram", "checklist", "data-table", "calculator",
    "buying-strategy-card", "decision-trail", "risk-flag-list", "comparison-grid",
    "opportunity-card", "scheme-stack-card", "firb-workflow-card", "family-view-card",
}

fails = []
def check(cond, msg):
    if not cond:
        fails.append(msg)

# ---- 1. slug == path for every KB doc -------------------------------------
kb_docs = sorted(KB.rglob("*.md"))
print(f"[1] slug==path over {len(kb_docs)} KB docs")
for f in kb_docs:
    txt = f.read_text()
    m = re.search(r'^slug:\s*(\S+)', txt, re.M)
    rel = f.relative_to(ROOT / "docs").with_suffix("")
    expect = str(rel).replace("/", ".")
    check(m, f"    {f}: no slug")
    if m:
        check(m.group(1) == expect,
              f"    {f}: slug={m.group(1)} expect={expect}")
print(f"    {'OK' if not fails else 'FAILURES'} — {sum(1 for f in kb_docs)} checked")

def kb_file_exists(slug):
    return (ROOT / "docs" / (slug.replace(".", "/") + ".md")).is_file()

# ---- per-blueprint: anchors, renderers, pipeline ---------------------------
for bp in sorted(BP.glob("*.md")):
    txt = bp.read_text()
    print(f"\n[blueprint] {bp.name}")

    # 2. KB anchors resolve
    anchors = set()
    for line in re.findall(r'^\*\*KB anchors:\*\*(.*)$', txt, re.M):
        anchors.update(re.findall(r'kb\.[a-z0-9.\-]+', line))
    missing = sorted(a for a in anchors if not kb_file_exists(a))
    print(f"  [2] anchors: {len(anchors)} unique, {len(anchors)-len(missing)} resolve"
          + (f", MISSING {len(missing)}: {missing}" if missing else ""))

    # 3. renderers in enum
    bad_r = set()
    rtoks = set()
    for line in re.findall(r'^\*\*Renderer:\*\*(.*)$', txt, re.M):
        toks = re.findall(r'`([a-z\-]+)`', line)
        rtoks.update(toks)
        bad_r.update(t for t in toks if t not in RENDERER_ENUM)
    check(not bad_r, f"  {bp.name}: renderer(s) not in enum: {sorted(bad_r)}")
    print(f"  [3] renderers: {sorted(rtoks)}"
          + (f"  BAD: {sorted(bad_r)}" if bad_r else "  (all in enum)"))

    # 4. pipeline acyclic — parse the `producer -> outcome: NAME (reads: ...)` block
    producer = {}   # outcome_name -> component
    reads = {}      # component -> [outcome_names]
    for comp, out, rd in re.findall(
            r'^(\w+)\s*→\s*outcome:\s*(\w+)\s*(?:\(reads:\s*([^)]*)\))?', txt, re.M):
        producer[out] = comp
        reads[comp] = [x.strip() for x in rd.split(",") if x.strip()] if rd else []
    # build edges dep_component -> component
    nodes = set(reads)
    edges = {c: set() for c in nodes}
    externals = set()
    for comp, outs in reads.items():
        for o in outs:
            if o in producer:
                edges[comp].add(producer[o])   # comp depends on producer[o]
            else:
                externals.add(o)
    # cycle detect (DFS)
    WHITE, GRAY, BLACK = 0, 1, 2
    color = {c: WHITE for c in nodes}
    cyc = []
    def dfs(u, stack):
        color[u] = GRAY
        for v in edges[u]:
            if color[v] == GRAY:
                cyc.append(stack + [u, v]); return True
            if color[v] == WHITE and dfs(v, stack + [u]):
                return True
        color[u] = BLACK
        return False
    has_cycle = any(color[c] == WHITE and dfs(c, []) for c in nodes)
    check(not has_cycle, f"  {bp.name}: pipeline CYCLE {cyc}")
    print(f"  [4] pipeline: {len(nodes)} components, {sum(len(e) for e in edges.values())} edges, "
          f"externals={sorted(externals)} — {'ACYCLIC' if not has_cycle else 'CYCLE: '+str(cyc)}")

print("\n" + ("=" * 60))
if fails:
    print(f"FAIL — {len(fails)} problem(s):")
    for f in fails: print(f)
    sys.exit(1)
print("PASS — all structural checks green")
