#!/usr/bin/env bash
# Behavior 33: fill engine|shell app.yaml from .env + ancu-pg, validate, create or
# update the DO app. Prints names and ids, never a value (do_deploy.py, its block).
set -euo pipefail
exec python3 "$(dirname "$0")/do_deploy.py" apply "$1"
