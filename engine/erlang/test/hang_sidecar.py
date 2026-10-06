#!/usr/bin/env python3
"""A sidecar that takes its fill and never replies — the victim the kill smokes shoot.

Reproducible -> P-3 · The sidecar is stateless and disposable -> The sidecar -> a fill that hangs until killed
Set as FH_PLANNER_SCRIPT by sidecar_kill_smoke and concern_isolation_smoke. It reads the
engine's one `{packet,4}` request frame (so the turn is truly mid-fill), writes its own OS
pid to `$FH_HANG_PIDDIR/<pid>` so the smoke can `kill -9` it from outside, then blocks on
stdin: it never writes a reply, and it exits by itself only when the engine closes the
port (EOF), so no orphan outlives a run. No model, no token, no network.
"""

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
        return
    (length,) = struct.unpack(">I", header)
    if _readn(length) is None:
        return
    piddir = os.environ.get("FH_HANG_PIDDIR")
    if piddir:
        with open(os.path.join(piddir, str(os.getpid())), "w") as f:
            f.write(str(os.getpid()))
    # Never reply: wait for EOF (the engine closing the port) or a kill.
    while sys.stdin.buffer.read(1):
        pass


if __name__ == "__main__":
    main()
