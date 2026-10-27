#!/usr/bin/env python3
"""A sidecar that reports what it was given, then exits — the witness for behavior 140.

R-4 · Reasoning within its runtime -> The sidecar -> the sidecar gets only the env it needs
Set as FH_PLANNER_SCRIPT by sidecar_env_smoke. It reads the engine's one `{packet,4}`
request frame, writes `$FH_ENV_DUMPDIR/<method>-<pid>.json` with the request method, the
NAMES of its environment variables (never their values) and its cwd, then exits 1 without
a reply, so the turn fails cleanly. No model, no token, no network.
"""

import json
import os
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


def main():
    header = _readn(4)
    if header is None:
        return 1
    (length,) = struct.unpack(">I", header)
    body = _readn(length)
    if body is None:
        return 1
    method = json.loads(body).get("method", "?")
    names = sorted(os.environ)
    # The one value reported: whether ANTHROPIC_API_KEY is non-empty, never the value.
    report = {"method": method, "env_names": names, "cwd": os.getcwd(),
              "anthropic_api_key_nonempty": bool(os.environ.get("ANTHROPIC_API_KEY"))}
    with open(os.path.join(os.environ["FH_ENV_DUMPDIR"], f"{method}-{os.getpid()}.json"), "w") as f:
        json.dump(report, f)
    return 1


if __name__ == "__main__":
    sys.exit(main())
