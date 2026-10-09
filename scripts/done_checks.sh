#!/usr/bin/env bash
# Run every done check: each backticked command of the `checks:` line in
# docs/design/architecture.md, in order, from the repo root. Prints `ok <command>` or
# `FAIL <command>` with its output, and exits 1 if any failed (it runs them all).
#
#   bash scripts/done_checks.sh
#
# Reproducible -> P-7 · One declaration per outcome shape -> Mechanisms -> the done checks, run by CI
# The `checks:` line is the one declaration of what "done" means; CI
# (.github/workflows/done-checks.yml) runs this script rather than a copy of the list, so
# a check added there gates every pull request into main the next time it runs — and
# main deploys on merge (deployment.md §4), so a failing check here blocks a deploy
# (behavior 38, 2026-10-09). Expects the untracked prerequisites a clean checkout lacks to
# be built first: `.venv` (`uv sync --frozen`), the KB artifact
# (`.venv/bin/python engine/build/kb_compiler.py`), shell/web/frontend/node_modules (`npm ci`).
set -uo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"
# the project's line, not the format line `checks: \`<command>\`` that defines it
line="$(grep -E '^[[:space:]]*checks: `' docs/design/architecture.md | grep -v '<command>' | tail -1)"
if [ -z "$line" ]; then echo "done checks: no checks: line in docs/design/architecture.md"; exit 1; fi

cmds=()
while IFS= read -r c; do [ -n "$c" ] && cmds+=("$c"); done < <(grep -oE '`[^`]+`' <<<"$line" | sed 's/^`//; s/`$//')

failed=0
for c in "${cmds[@]}"; do
  if out="$(bash -c "$c" 2>&1)"; then
    echo "ok   $c"
  else
    echo "FAIL $c"
    printf '%s\n' "$out" | tail -40 | sed 's/^/     /'
    failed=$((failed + 1))
  fi
done
echo "done checks: $(( ${#cmds[@]} - failed ))/${#cmds[@]} passed"
[ "$failed" -eq 0 ]
