#!/bin/bash
# Run one KB job as the ancuauto user (launchd calls this; behavior 145).
#
#   bash scripts/auto/run_job.sh <news-watch|kb-watch|kb-verify|suburb-watch|gate|canary>
#
# Regulated figures are grounded -> R-3 -> The KB update -> the runner's code is main's, never a job folder's
# The runner checkout (/Users/ancuauto/ancu) is brought to origin/main first, then this
# execs the Python from it: what runs as ancuauto is what Son merged, with git hooks off
# and no git config but the token header (autolib.git_env). A job's own folder is
# elsewhere (~/jobs) and nothing in it is ever run by the runner.
set -euo pipefail
export PATH="$HOME/.local/bin:$HOME/.cache/rebar3/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"
runner="${ANCU_AUTO_RUNNER:-$HOME/ancu}"
cd "$runner"
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null GIT_TERMINAL_PROMPT=0
git -c core.hooksPath=/dev/null -c core.fsmonitor=false fetch --quiet origin main
git -c core.hooksPath=/dev/null -c core.fsmonitor=false checkout --quiet --force --detach origin/main
case "${1:-}" in
  canary) exec /usr/bin/python3 scripts/auto/canary.py ;;
  gate)   exec /usr/bin/python3 scripts/auto/gate.py ;;
  *)      exec /usr/bin/python3 scripts/auto/runner.py "${1:?usage: run_job.sh <job>}" ;;
esac
