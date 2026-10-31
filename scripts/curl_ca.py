"""The CA bundle the KB fetch scripts hand curl (behavior 145).

Regulated figures are grounded -> R-4 -> The KB update -> curl trusts certifi's bundle, so a source host's real chain verifies in the seat
Invariant: news_watch.py, visa_watch.py and archive_source.py verify every https source
  against a CA bundle that holds the roots the government hosts chain to; none of them
  turns verification off (`-k` is never passed).
Mechanism: measured 2026-10-31 in the attended seat: curl to https://www.rba.gov.au/ with
  macOS's /etc/ssl/cert.pem fails "self signed certificate in certificate chain" (the
  chain itself is RBA's real Sectigo one, read with `curl -kv`), and the same curl with
  `--cacert` the .venv's certifi bundle answers 200. So ca_args() returns
  `["--cacert", <certifi bundle>]` when certifi is importable (the scripts run under
  `.venv/bin/python`), else `CURL_CA_BUNDLE`'s file if set, else nothing (curl's default).
Capability: `ca_args()` → the curl arguments to add before the URL.
"""
from __future__ import annotations

import os


def ca_args() -> list[str]:
    try:
        import certifi
        return ["--cacert", certifi.where()]
    except ImportError:
        pass
    env = os.environ.get("CURL_CA_BUNDLE")
    return ["--cacert", env] if env and os.path.isfile(env) else []
