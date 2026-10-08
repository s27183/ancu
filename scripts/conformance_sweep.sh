#!/usr/bin/env bash
# Run every conformance escript, engine and shell; exit 1 naming each one that fails.
#
#   bash scripts/conformance_sweep.sh [<dir holding *_conformance.escript>]
#
# Reproducible -> P-7 · One declaration per outcome shape -> Mechanisms -> every conformance escript, every done check
# The conformance escripts are offline (no Postgres, no LLM, no .env): the engine's load the
# compiled KB artifact and call the resolvers directly; the shell's start the shell's own
# listener and a stub engine on loopback ports. Three of them failed unnoticed from July to
# 2026-10-06 (#11) because nothing ran them all; this script is in architecture.md's
# `checks:` line so a failing anchor fails a step. Each escript's `%%! -sname` line is
# stripped into a temp copy: a distribution name needs a listen socket, refused in the seat's
# sandbox (measured 2026-10-06, `inet_tcp` eperm), and no conformance escript uses
# distribution. The engine must be compiled (`rebar3 compile`, an earlier done check) and the
# untracked artifact built by `.venv/bin/python engine/build/kb_compiler.py` — the done checks do
# not emit it (validate_build.py runs `--no-emit`), so a missing artifact, or one older than any
# blueprint or KB doc, fails here by name rather than testing yesterday's KB.
set -uo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
dir="${1:-$root/engine/erlang/test}"
tmp="$(mktemp -d "${TMPDIR:-/tmp}/conformance.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

art="$root/engine/erlang/priv/kb/artifact.json"
if [ ! -f "$art" ]; then
  echo "conformance sweep: no $art — run: .venv/bin/python engine/build/kb_compiler.py"; exit 1
fi
newer="$(find "$root/docs/blueprints" "$root/docs/kb" -type f -newer "$art" | head -3)"
if [ -n "$newer" ]; then
  echo "conformance sweep: the artifact is older than:"; echo "$newer" | sed 's/^/    /'
  echo "run: .venv/bin/python engine/build/kb_compiler.py"; exit 1
fi

# Each escript runs from its component's root, with that component's compiled libs:
# the engine's (resolvers, KB artifact) and, since behavior 29, the shell's
# (sse_cancel_conformance: the SSE relay against a stub engine on loopback ports, which the
# sandbox allows; only a distribution name is refused).
pass=0; failed=()
sweep() {  # <component dir> <escript dir>
  local f name
  for f in "$2"/*_conformance.escript; do
    [ -e "$f" ] || continue
    name="$(basename "$f" .escript)"
    sed 's/^%%! -sname.*$/%%!/' "$f" > "$tmp/$name.escript"
    if (cd "$1" && ERL_LIBS=_build/default/lib escript "$tmp/$name.escript") > "$tmp/$name.log" 2>&1; then
      pass=$((pass + 1))
    else
      failed+=("$name")
      echo "FAIL $name"
      grep -E "FAIL|error|exception" "$tmp/$name.log" | head -5 | sed 's/^/    /'
    fi
  done
}
if [ -n "${1:-}" ]; then
  sweep "$root/engine/erlang" "$dir"
else
  sweep "$root/engine/erlang" "$root/engine/erlang/test"
  sweep "$root/shell/web/backend" "$root/shell/web/backend/test"
fi

total=$((pass + ${#failed[@]}))
if [ "$total" -eq 0 ]; then
  echo "conformance sweep: no *_conformance.escript found"; exit 1
fi
echo "conformance sweep: $pass/$total passed"
[ "${#failed[@]}" -eq 0 ]
