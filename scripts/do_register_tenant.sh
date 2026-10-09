#!/usr/bin/env bash
# Behavior 33: register the shell tenant's ed25519 public key in ancu_engine
# (deployment.md §4 step 5). Prints the public key only (do_deploy.py, its block).
set -euo pipefail
exec python3 "$(dirname "$0")/do_deploy.py" register-tenant
