#!/bin/bash
# Install the local KB jobs (behavior 145). Son runs it once, with sudo, after the PR that
# carries it is merged and after both users exist:
#
#   sudo sysadminctl -addUser ancuauto -fullName "ancu auto" -shell /bin/zsh
#   sudo sysadminctl -addUser ancuagent -fullName "ancu agent" -shell /bin/zsh
#   sudo bash scripts/auto/install.sh
#
# Regulated figures are grounded -> R-3 -> The KB update -> the runner (ancuauto) alone holds the GitHub key; the agent (ancuagent) holds only its claude key
# Invariant: what launchd runs is the runner checkout at origin/main in ancuauto's home,
#   never this working tree; the GitHub key is readable by ancuauto only and the claude key
#   by ancuagent only, both typed by Son here, never echoed, never in argv, never in this
#   repo; ancuagent runs nothing of ancuauto's but the root-owned wrapper's claude.
# Mechanism: an anonymous clone of the public repo as ancuauto (or a fetch); uv and rebar3
#   for ancuauto (the gate's done checks), claude for ancuagent, at the versions measured
#   2026-10-31 (claude auto-updates after; the canary measures it before every job); both
#   homes 0700; the group ancu-jobs holds both users and owns the shared jobs folder; the
#   wrapper /usr/local/libexec/ancu-agent (root:wheel 0755) and the one sudoers line, checked
#   with `visudo -cf` before it is moved in; key files 0600 in 0700 folders; a check that
#   ancuagent cannot read the GitHub key and that the wrapper runs as ancuagent; then the
#   six plists into /Library/LaunchDaemons, bootstrapped (bootout first: a re-run replaces
#   them). Re-running is safe; `--keys` asks for both keys again.
# Capability: exit 0 with one line per step and the kickstart command for the canary; exit 1
#   at the first check that fails, saying which.
set -euo pipefail

RUNNER_USER=ancuauto
AGENT_USER=ancuagent
GROUP=ancu-jobs
RH=/Users/$RUNNER_USER
AH=/Users/$AGENT_USER
RUNNER=$RH/ancu
SHARED=/Users/Shared/ancu-auto
WRAPPER=/usr/local/libexec/ancu-agent
SUDOERS=/etc/sudoers.d/ancu-auto
REPO=https://github.com/s27183/ancu.git
UV_VERSION=0.12.5
CLAUDE_VERSION=2.1.316
REBAR3_VERSION=3.27.0
JOBS=(canary news-watch kb-watch kb-verify gate suburb-watch)

[ "$(id -u)" = 0 ] || { echo "run with sudo: sudo bash scripts/auto/install.sh" >&2; exit 1; }
for u in "$RUNNER_USER" "$AGENT_USER"; do
  id "$u" >/dev/null 2>&1 || {
    echo "no user $u: first run  sudo sysadminctl -addUser $u -fullName \"${u/ancu/ancu }\" -shell /bin/zsh" >&2
    exit 1; }
done
as() {  # as <user> <command…>: a clean environment, that user's home and toolchain
  local u=$1 h=/Users/$1; shift
  sudo -u "$u" -H env -i HOME="$h" USER="$u" \
    PATH="$h/.local/bin:$h/.cache/rebar3/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin" \
    LANG=en_AU.UTF-8 "$@"
}
step() { echo "install: $*"; }
fail() { echo "install: FAILED — $*" >&2; exit 1; }
[ "${1:-}" = --keys ] && KEYS=1

step "group $GROUP with $RUNNER_USER and $AGENT_USER"
dseditgroup -o read "$GROUP" >/dev/null 2>&1 || dseditgroup -o create -r "ancu KB jobs" "$GROUP"
for u in "$RUNNER_USER" "$AGENT_USER"; do dseditgroup -o edit -a "$u" -t user "$GROUP"; done

step "homes and folders"
for u in "$RUNNER_USER" "$AGENT_USER"; do
  [ -d "/Users/$u" ] || createhomedir -c -u "$u" >/dev/null
  chown "$u:staff" "/Users/$u"; chmod 0700 "/Users/$u"
done
install -d -o "$RUNNER_USER" -g staff -m 0700 "$RH/state" "$RH/.config" "$RH/.config/ancu-auto"
install -d -o "$AGENT_USER" -g staff -m 0700 "$AH/.config" "$AH/.config/ancu-agent" "$AH/.claude-jobs"
install -d -o "$RUNNER_USER" -g staff -m 0755 "$SHARED" "$SHARED/logs" "$SHARED/python"
install -d -o "$RUNNER_USER" -g "$GROUP" -m 2770 "$SHARED/jobs"
install -d -o "$RUNNER_USER" -g "$GROUP" -m 2750 "$SHARED/settings"

step "runner checkout $RUNNER"
if [ -d "$RUNNER/.git" ]; then
  as "$RUNNER_USER" git -C "$RUNNER" -c core.hooksPath=/dev/null fetch --quiet origin main
else
  as "$RUNNER_USER" git -c core.hooksPath=/dev/null clone --quiet "$REPO" "$RUNNER"
fi
as "$RUNNER_USER" git -C "$RUNNER" -c core.hooksPath=/dev/null checkout --quiet --force --detach origin/main
step "runner at $(as "$RUNNER_USER" git -C "$RUNNER" rev-parse --short HEAD)"

step "uv $UV_VERSION and rebar3 $REBAR3_VERSION for $RUNNER_USER"
[ -x "$RH/.local/bin/uv" ] || as "$RUNNER_USER" bash -c \
  "curl -LsSf https://astral.sh/uv/$UV_VERSION/install.sh | env UV_NO_MODIFY_PATH=1 sh"
as "$RUNNER_USER" "$RH/.local/bin/uv" --version
if [ ! -x "$RH/.cache/rebar3/bin/rebar3" ]; then
  as "$RUNNER_USER" mkdir -p "$RH/.cache/rebar3/bin"
  as "$RUNNER_USER" curl -fsSL -o "$RH/.cache/rebar3/bin/rebar3" \
    "https://github.com/erlang/rebar3/releases/download/$REBAR3_VERSION/rebar3"
  as "$RUNNER_USER" chmod 0755 "$RH/.cache/rebar3/bin/rebar3"
fi
as "$RUNNER_USER" "$RH/.cache/rebar3/bin/rebar3" version

step "claude $CLAUDE_VERSION for $AGENT_USER"
[ -x "$AH/.local/bin/claude" ] || as "$AGENT_USER" bash -c \
  "curl -fsSL https://claude.ai/install.sh | bash -s $CLAUDE_VERSION"
as "$AGENT_USER" "$AH/.local/bin/claude" --version

step "wrapper $WRAPPER and $SUDOERS"
install -d -o root -g wheel -m 0755 /usr/local/libexec
install -o root -g wheel -m 0755 "$RUNNER/scripts/auto/ancu-agent.sh" "$WRAPPER"
tmp="$(mktemp /tmp/ancu-auto-sudoers.XXXXXX)"
printf '# behavior 145: the KB runner starts its agent as ancuagent, through this wrapper only\n%s ALL=(%s) NOPASSWD: %s\n' \
  "$RUNNER_USER" "$AGENT_USER" "$WRAPPER" > "$tmp"
visudo -cf "$tmp" || { rm -f "$tmp"; fail "visudo -cf refused the sudoers line"; }
install -o root -g wheel -m 0440 "$tmp" "$SUDOERS"; rm -f "$tmp"
step "visudo -cf ok for $SUDOERS"

ask_key() {  # $1 file, $2 owner, $3 what it is, $4 how to get it — typed, never echoed
  local f=$1 owner=$2 v
  if [ -s "$f" ] && [ "${KEYS:-}" != 1 ]; then step "$(basename "$f") kept"; return; fi
  echo "$3 — $4"
  read -rs -p "paste it (hidden), then Enter: " v; echo
  [ -n "$v" ] || fail "empty; nothing written"
  ( umask 077; printf '%s\n' "$v" > "$f" )
  chown "$owner:staff" "$f"; chmod 0600 "$f"
  step "$(basename "$f") written for $owner"
}
ask_key "$AH/.config/ancu-agent/claude-token" "$AGENT_USER" "the claude key" \
  "in another terminal run:  claude setup-token"
ask_key "$RH/.config/ancu-auto/gh-token" "$RUNNER_USER" "the GitHub key" \
  "a fine-grained token at github.com/settings/personal-access-tokens, repository s27183/ancu only: Contents, Pull requests and Issues read and write"

step "checks"
if sudo -u "$AGENT_USER" test -r "$RH/.config/ancu-auto/gh-token"; then
  fail "ancuagent CAN read the GitHub key"
fi
step "ancuagent cannot read the GitHub key"
got="$(sudo -u "$RUNNER_USER" sudo -n -u "$AGENT_USER" "$WRAPPER" --check)" \
  || fail "ancuauto cannot run the wrapper as ancuagent"
[ "$got" = "ancu-agent: runs as $AGENT_USER" ] || fail "the wrapper said: $got"
step "$got (started by $RUNNER_USER through sudo)"

step "launchd jobs"
for job in "${JOBS[@]}"; do
  label=com.s27183.ancu-auto.$job
  src="$RUNNER/ops/launchd/$label.plist"
  dst=/Library/LaunchDaemons/$label.plist
  plutil -lint "$src" >/dev/null
  launchctl bootout "system/$label" 2>/dev/null || true
  install -o root -g wheel -m 0644 "$src" "$dst"
  launchctl bootstrap system "$dst"
  step "  $label"
done

step "done. First run, then read its log:"
echo "  sudo launchctl kickstart system/com.s27183.ancu-auto.canary"
echo "  tail -5 $SHARED/logs/launchd-canary.log"
