#!/usr/bin/env bash
# Run every engine conformance escript; exit 1 naming each one that fails.
#
#   bash scripts/conformance_sweep.sh [<dir holding *_conformance.escript>]
#
# Reproducible -> P-7 · One declaration per outcome shape -> Mechanisms -> every conformance escript, every done check
# The conformance escripts are offline (no port, no Postgres, no LLM): they load the compiled
# KB artifact and call the resolvers directly. Three of them failed unnoticed from July to
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

cd "$root/engine/erlang"
export ERL_LIBS=_build/default/lib

pass=0; failed=()
for f in "$dir"/*_conformance.escript; do
  name="$(basename "$f" .escript)"
  sed 's/^%%! -sname.*$/%%!/' "$f" > "$tmp/$name.escript"
  if escript "$tmp/$name.escript" > "$tmp/$name.log" 2>&1; then
    pass=$((pass + 1))
  else
    failed+=("$name")
    echo "FAIL $name"
    grep -E "FAIL|error|exception" "$tmp/$name.log" | head -5 | sed 's/^/    /'
  fi
done

total=$((pass + ${#failed[@]}))
if [ "$total" -eq 0 ]; then
  echo "conformance sweep: no *_conformance.escript found in $dir"; exit 1
fi
echo "conformance sweep: $pass/$total passed"
[ "${#failed[@]}" -eq 0 ]
