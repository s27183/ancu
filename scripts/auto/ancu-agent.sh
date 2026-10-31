#!/bin/bash
# The only way a KB job's agent starts (behavior 145). install.sh copies this file to
# /usr/local/libexec/ancu-agent (root:wheel 0755), and /etc/sudoers.d/ancu-auto lets the
# runner user run it, and nothing else, as ancuagent:
#
#   sudo -n -u ancuagent /usr/local/libexec/ancu-agent <job folder> <claude args…>
#   sudo -n -u ancuagent /usr/local/libexec/ancu-agent --check
#
# Regulated figures are grounded -> R-3 -> The KB update -> the agent runs as a user that holds no GitHub key
# Invariant: the agent's process is ancuagent's, whose uid cannot read the GitHub key
#   (0600 in ancuauto's 0700 home), with only its own claude key, in a job folder under
#   /Users/Shared/ancu-auto/jobs, and an environment this file sets — nothing of the
#   runner's environment comes through.
# Mechanism: root owns this file, so neither user can change what it runs; it refuses any
#   folder not directly under the jobs folder, clears every environment variable, exports
#   only its own (the key read from ancuagent's 0600 file, never put in argv), sets umask
#   007 so the runner (group ancu-jobs) can read and prune what the agent writes, and execs
#   claude — so sudo's SIGTERM on a timeout reaches claude itself.
# Capability: exit as claude exits; 2 on a refused folder; `--check` prints the user it runs as.
set -euo pipefail
JOBS=/Users/Shared/ancu-auto/jobs
H=/Users/ancuagent
if [ "${1:-}" = --check ]; then
  echo "ancu-agent: runs as $(id -un)"
  exit 0
fi
dir="${1:?usage: ancu-agent <job folder> <claude args…>}"
shift
real="$(cd "$dir" 2>/dev/null && pwd -P)" || { echo "ancu-agent: no folder $dir" >&2; exit 2; }
name="${real##*/}"
if [ "$real" != "$JOBS/$name" ] || [[ ! "$name" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]]; then
  echo "ancu-agent: $dir is not a job folder under $JOBS" >&2
  exit 2
fi
key="$(cat "$H/.config/ancu-agent/claude-token")"
cd "$real"
umask 007
while IFS='=' read -r v _; do
  case "$v" in key|real|name|dir|H|JOBS) ;; *) unset "$v" 2>/dev/null || true ;; esac
done < <(env)
export PATH="$H/.local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"
export HOME="$H" USER=ancuagent LOGNAME=ancuagent SHELL=/bin/bash LANG=en_US.UTF-8
export TMPDIR=/private/tmp CLAUDE_CONFIG_DIR="$H/.claude-jobs"
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null GIT_TERMINAL_PROMPT=0
export CLAUDE_CODE_OAUTH_TOKEN="$key"
unset key
exec "$H/.local/bin/claude" "$@"
