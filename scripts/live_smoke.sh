#!/usr/bin/env bash
# Run one live escript smoke against this clone's private Postgres socket.
#
#   bash scripts/live_smoke.sh <smoke-name>
#
# Reproducible -> P-2 · The database is the single source of truth -> Mechanisms -> a live smoke named, not a free command
# A seat's granted Need may not start with `VAR=` (Claude Code exempts a command from the
# sandbox only after stripping a leading assignment on its safe list; ENGINE_DATABASE_URL and
# ERL_LIBS are not on it — read in the 2.1.292 binary 2026-10-07 (its a1 set; enacs read the
# prior release 2026-10-06 the same); measured here 2026-10-06: the VAR= form ran sandboxed, `inet_tcp` listen eperm). So the variables live in
# this script, and the allowlist below keeps the grant to the named smokes: a confirm pins
# this file, so adding a smoke here is a change Son re-confirms.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
sock="$root/.git/enacs-pg"
enc="${sock//\//%2F}"
user="$(id -un)"

case "${1:-}" in
  mode_b_seam_smoke|mode_d_seam_smoke|sidecar_kill_smoke|concern_isolation_smoke|restart_replay_smoke|horizon_refine_smoke)
    dir="$root/engine/erlang"
    export ENGINE_DATABASE_URL="postgres://$user@$enc/ancu_engine" ;;
  sse_isolation_smoke)
    dir="$root/shell/web/backend"
    export SHELL_DATABASE_URL="postgres://$user@$enc/ancu_shell" ;;
  *)
    echo "usage: bash scripts/live_smoke.sh <mode_b_seam_smoke|mode_d_seam_smoke|sidecar_kill_smoke|concern_isolation_smoke|restart_replay_smoke|horizon_refine_smoke|sse_isolation_smoke>" >&2
    exit 2 ;;
esac

export ERL_LIBS=_build/default/lib
cd "$dir"
exec escript "test/$1.escript"
