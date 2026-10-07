#!/usr/bin/env bash
# Start the whole dev stack — engine :8080, shell :8081, frontend :5173 — on 127.0.0.1,
# with both databases on this clone's private Postgres socket (.git/enacs-pg).
#
#   bash scripts/dev_stack.sh        (Ctrl-C, or killing it, stops all three)
#
# Reproducible -> P-2 · The database is the single source of truth -> the dev stack -> one script, loopback, private socket
# The per-component bin/dev launchers need docker (engine) and Son's shared :5432 (shell);
# a seat has neither, and runs this instead (behavior 24, 2026-10-07). It runs outside the
# sandbox as a granted Need because the root .env (the planner's token, sign-in settings)
# is unreadable inside it; the variables set here win over .env (OS env wins in both apps'
# loaders), so the databases and bind address are always these. FH_HTTP_IP keeps the two
# Erlang listeners off the LAN; vite gets --host 127.0.0.1.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
sock="$root/.git/enacs-pg"
enc="${sock//\//%2F}"
user="$(id -un)"
logs="$root/.git/enacs-dev-stack"
mkdir -p "$logs"

export FH_HTTP_IP=127.0.0.1
export FH_ENGINE_HTTP_PORT=8080 FH_SHELL_HTTP_PORT=8081
export ENGINE_DATABASE_URL="postgres://$user@$enc/ancu_engine"
export SHELL_DATABASE_URL="postgres://$user@$enc/ancu_shell"
export ENGINE_BASE_URL="http://127.0.0.1:8080/api/engine"   # the shell appends /dev/tenants, /plan-cards…

for db in ancu_engine ancu_shell; do
    createdb -h "$sock" "$db" 2>/dev/null || true   # exists → no-op
done

pids=()
stop() { kill "${pids[@]}" 2>/dev/null || true; }
trap stop EXIT INT TERM

wait_port() {   # $1 port, $2 name
    for _ in $(seq 60); do
        nc -z 127.0.0.1 "$1" 2>/dev/null && { echo "✓ $2 on 127.0.0.1:$1"; return 0; }
        sleep 1
    done
    echo "✗ $2 did not come up on :$1 — see $logs/$2.log" >&2
    exit 1
}

boot_erl() {    # $1 dir, $2 app, $3 name
    (cd "$root/$1" && rebar3 compile >"$logs/$3.compile.log" 2>&1)
    (cd "$root/$1" && exec env ERL_LIBS=_build/default/lib erl -noshell \
        -eval "{ok, _} = application:ensure_all_started($2)." >"$logs/$3.log" 2>&1) &
    pids+=($!)
}

boot_erl engine/erlang fh_engine engine
wait_port 8080 engine        # the shell registers its tenant key with the engine at boot
boot_erl shell/web/backend fh_shell shell
wait_port 8081 shell
(cd "$root/shell/web/frontend" && { [ -d node_modules ] || npm install; } \
    && exec npx vite dev --host 127.0.0.1 --port 5173 --strictPort >"$logs/frontend.log" 2>&1) &
pids+=($!)
wait_port 5173 frontend

echo "stack up — logs in $logs"
wait
