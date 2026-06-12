#!/usr/bin/env python3
"""2c-2 standalone smoke for the Q&A sidecar path (no Erlang).

Drives engine/python/planner.py with a real `qa` request frame over the {packet,4}
seam and asserts the reply frames: tool_use/tool_result (the KB-lookup machinery),
a bilingual qa_answer {vi,en}, usage, qa_done. Makes a REAL opus call — needs
CLAUDE_CODE_OAUTH_TOKEN in the environment (the subscription credit). Run:

  set -a; source .env; set +a
  python tests/qa_sidecar_smoke.py
"""
import json
import os
import struct
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PLANNER = os.path.join(REPO, "engine", "python", "planner.py")


def frame(obj):
    body = json.dumps(obj).encode("utf-8")
    return struct.pack(">I", len(body)) + body


def read_frames(buf):
    out, i = [], 0
    while i + 4 <= len(buf):
        (n,) = struct.unpack(">I", buf[i:i + 4])
        i += 4
        out.append(json.loads(buf[i:i + n].decode("utf-8")))
        i += n
    return out


# A realistic Mode-A base-filled card: eligibility surfaced, income/debts pending.
CARD = {
    "components": {
        "eligibility": {"outcome": {
            "state": "NSW", "first_home_buyer": True,
            "scheme_stack": ["first_home_guarantee", "fhbas_transfer_duty"],
            "fhg_eligible": "unknown_pending_income"}},
        "cash_position": {"outcome": {
            "target_price_range": [600000, 700000],
            "estimated_transfer_duty": 0, "duty_concession": "fhbas_full_exemption"}},
    }
}
REQ = {"method": "qa", "params": {
    "plan_card_id": "pc-smoke", "card": CARD, "glue": [],
    "message": "What is the First Home Guarantee, and does it cost extra?"}}


def main():
    if not os.environ.get("CLAUDE_CODE_OAUTH_TOKEN"):
        print("SKIP: CLAUDE_CODE_OAUTH_TOKEN not set (need the subscription credit)")
        return 2
    p = subprocess.run([sys.executable, PLANNER], input=frame(REQ),
                       capture_output=True, env=os.environ.copy(), timeout=700)
    frames = read_frames(p.stdout)
    methods = [f.get("method") for f in frames]
    print("frames:", methods)
    if p.stderr:
        print("--- sidecar stderr (tail) ---")
        print(p.stderr.decode("utf-8", "replace")[-1500:])

    def ok(cond, msg):
        print(("OK  " if cond else "FAIL ") + msg)
        if not cond:
            sys.exit(1)

    by = {}
    for f in frames:
        by.setdefault(f.get("method"), []).append(f.get("params", {}))

    ok("qa_answer" in by, "qa_answer frame present")
    ok("qa_done" in by, "qa_done frame present")
    ok("usage" in by, "usage frame present")

    ans = by["qa_answer"][0]["answer"]
    vi, en = ans.get("vi", ""), ans.get("en", "")
    ok(bool(vi) and bool(en), "answer carries both vi and en")
    ok(vi != en, "vi and en differ (not an English fallback)")
    ok(any(ord(c) > 127 for c in vi), "vi carries a diacritic (real Vietnamese)")
    ok(len(vi) <= 4000 and len(en) <= 4000, "answer within the prose backstop")

    # The tool is available; opus MAY or may not call it. If it did, the events must be
    # sanitized (no raw slug in the user-facing summary).
    if "tool_use" in by:
        tu = by["tool_use"][0]
        ok(tu.get("display_name") == "Searching the knowledge base",
           "tool_use sanitized (display_name, no slug)")
        ok("kb." not in json.dumps(tu), "tool_use carries no raw kb slug")
        print("  (KB lookup fired; consulted:", by["qa_answer"][0].get("kb_slugs"), ")")
    else:
        print("  (opus answered from grounding without a KB lookup — allowed)")

    print("\nVI:", vi[:160])
    print("EN:", en[:160])
    print("\n==== QA SIDECAR SMOKE (2c-2): PASSED ====")
    return 0


if __name__ == "__main__":
    sys.exit(main())
