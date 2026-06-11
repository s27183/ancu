#!/usr/bin/env python3
"""FirstHomey planning sidecar — STUB (Wedge-1a #8; 2b-2b fill_component protocol).

Ablation stub: proves the Erlang<->Python seam WITHOUT an LLM — isolate transport /
lifecycle from reasoning (engine-seam-build-discipline). It is the DEFAULT sidecar
(`fh_engine_turn:planner_script/0`), so a plain run needs no API token; the real
Claude Agent SDK planner (`planner.py`) is opt-in via `FH_PLANNER_SCRIPT`.

2b-2b moved turn orchestration to Erlang: the turn's gen_statem walks the base DAG,
fills RESOLVER components in-process (no sidecar), and spawns a sidecar ONLY for an
agent / two-path component via `fill_component`. So this stub is a SINGLE-COMPONENT
filler matching planner.py's protocol (it is no longer a turn driver):

  request: {method: fill_component,
            params: {component_id, reasoning_domain, plan_card_id, upstream,
                     resolver_outcome?}}   # resolver_outcome present for a two-path comp
  reply:   component_filled  (canned schema-shaped outcome — Erlang stamps fill_path)
           usage             (zero tokens — a stub meters nothing, but the event keeps
                              the §4 sequence identical to the real planner's)
           fill_done         (this one fill is complete -> Erlang resumes the walk)
  then exit.

No LLM and no bundled `claude` binary -> no Node grandchild writes to fd 1, so the
protocol-stream isolation planner.py needs is unnecessary here.

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


# Canned agent-leaf outcomes keyed by reasoning_domain. `lender_fit` (mortgage_finance)
# is a TWO-PATH component (mortgage-finance-two-path.md): the sidecar authors ONLY the
# two lender_fit leaves; the figures + structure are the resolver's, and Erlang folds
# the leaves in. So this fixture is the two-leaf shape (NO money field — §98), matching
# planner.py's LenderFitLeaves. The per-property domains are pure-agent stubs (whole
# outcome). Schema-shaped fixtures, not real planning — they prove the outcome contract.
_FIXTURES = {
    "lender_fit": {
        "renderer": "summary-card",  # ignored for two-path (resolver supplies renderer)
        "kb_versions": [{"slug": "kb.lender.serviceability-basics"}],
        "outcome": {
            "recommended_lender_shortlist": [
                {"lender": "A major lender (FHG panel)",
                 "reasoning": "wide FHG panel; a broker can compare across it",
                 "approval_likelihood": "indicative"}],
            "fixed_vs_variable": "variable",
        },
    },
    "valuation": {
        "renderer": "summary-card", "kb_versions": [],
        "outcome": {"_stub": True, "estimated_value_range": [600000, 660000]},
    },
    "negotiation": {
        "renderer": "buying-strategy-card", "kb_versions": [],
        "outcome": {"_stub": True, "recommended_opening_offer": 590000},
    },
    "document_significance": {
        "renderer": "risk-flag-list", "kb_versions": [],
        "outcome": {"_stub": True, "flags": []},
    },
}


def _fixture(reasoning_domain):
    fx = _FIXTURES.get(reasoning_domain)
    if fx is not None:
        return fx
    # an unknown agent domain still gets a structurally-valid (clearly-stub) reply.
    return {"renderer": "summary-card", "kb_versions": [],
            "outcome": {"_stub": True, "reasoning_domain": reasoning_domain}}


def main():
    request = read_frame()
    if request is None:
        return
    params = request.get("params", {})
    component_id = params.get("component_id")
    fx = _fixture(params.get("reasoning_domain"))
    notify("component_filled", {
        "component_id": component_id,
        "renderer": fx["renderer"],
        "kb_versions": fx["kb_versions"],
        "outcome": fx["outcome"],
    })
    notify("usage", {"component_id": component_id, "source": "stub", "model": "stub",
                     "usage": {"input_tokens": 0, "output_tokens": 0}})
    notify("fill_done", {"component_id": component_id})


if __name__ == "__main__":
    main()
