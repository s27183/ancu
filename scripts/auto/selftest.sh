#!/bin/bash
# Offline self-test of the local KB jobs (behavior 145); one of the done checks.
#   bash scripts/auto/selftest.sh
# Regulated figures are grounded -> R-3 -> The KB update -> selftest proves what the runner, publisher, archive gate and local gate let through
# The checks and the seeded properties are in selftest.py's block.
set -euo pipefail
cd "$(dirname "$0")/../.."
exec python3 scripts/auto/selftest.py "$@"
