#!/bin/bash
# Install the local KB jobs for the ancuauto user (behavior 145). Son runs it once, with sudo,
# after `sudo sysadminctl -addUser ancuauto …` and after the PR that carries it is merged:
#
#   sudo bash scripts/auto/install.sh
#
# Regulated figures are grounded -> R-3 -> The KB update -> the jobs run as ancuauto, from main, with keys only ancuauto reads
# Invariant: what launchd runs is the runner checkout at origin/main in ancuauto's home, never
#   this working tree; the two keys (claude, GitHub) live in files only ancuauto can read and
#   are typed by Son here, never echoed, never in argv, never in this repo.
# Mechanism: a fresh anonymous clone of the public repo as ancuauto (or a fetch if it exists);
#   claude, uv and rebar3 installed in ancuauto's home at the versions measured on 2026-10-31
#   (claude auto-updates after, and the canary measures it again before every job); the key
#   files written 0600 in a 0700 folder; the six plists copied from the runner checkout's
#   ops/launchd into /Library/LaunchDaemons and bootstrapped (bootout first, so a re-run
#   replaces them). Re-running is safe; `--keys` asks for both keys again.
# Capability: exit 0 with one line per step and the kickstart command for the canary.
set -euo pipefail

USER_NAME=ancuauto
H=/Users/$USER_NAME
RUNNER=$H/ancu
CONF=$H/.config/ancu-auto
LOGS=/Users/Shared/ancu-auto/logs
REPO=https://github.com/s27183/ancu.git
UV_VERSION=0.12.5
CLAUDE_VERSION=2.1.316
REBAR3_VERSION=3.27.0
JOBS=(canary news-watch kb-watch kb-verify gate suburb-watch)

[ "$(id -u)" = 0 ] || { echo "run with sudo: sudo bash scripts/auto/install.sh" >&2; exit 1; }
id "$USER_NAME" >/dev/null 2>&1 || {
  echo "no user $USER_NAME: first run  sudo sysadminctl -addUser ancuauto -fullName \"ancu auto\" -shell /bin/zsh" >&2
  exit 1; }
as() { sudo -u "$USER_NAME" -H env -i HOME="$H" USER="$USER_NAME" \
  PATH="$H/.local/bin:$H/.cache/rebar3/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin" \
  LANG=en_AU.UTF-8 "$@"; }
step() { echo "install: $*"; }

step "folders"
[ -d "$H" ] || createhomedir -c -u "$USER_NAME" >/dev/null
install -d -o "$USER_NAME" -g staff -m 0755 "$H"
install -d -o "$USER_NAME" -g staff -m 0755 "$H/jobs" "$H/state" /Users/Shared/ancu-auto "$LOGS"
install -d -o "$USER_NAME" -g staff -m 0700 "$H/.config" "$CONF" "$H/.claude-jobs"

step "runner checkout $RUNNER"
if [ -d "$RUNNER/.git" ]; then
  as git -C "$RUNNER" -c core.hooksPath=/dev/null fetch --quiet origin main
else
  as git -c core.hooksPath=/dev/null clone --quiet "$REPO" "$RUNNER"
fi
as git -C "$RUNNER" -c core.hooksPath=/dev/null checkout --quiet --force --detach origin/main
step "runner at $(as git -C "$RUNNER" rev-parse --short HEAD)"

step "claude $CLAUDE_VERSION"
[ -x "$H/.local/bin/claude" ] || as bash -c "curl -fsSL https://claude.ai/install.sh | bash -s $CLAUDE_VERSION"
as "$H/.local/bin/claude" --version

step "uv $UV_VERSION"
[ -x "$H/.local/bin/uv" ] || as bash -c \
  "curl -LsSf https://astral.sh/uv/$UV_VERSION/install.sh | env UV_NO_MODIFY_PATH=1 sh"
as "$H/.local/bin/uv" --version

step "rebar3 $REBAR3_VERSION"
if [ ! -x "$H/.cache/rebar3/bin/rebar3" ]; then
  as mkdir -p "$H/.cache/rebar3/bin"
  as curl -fsSL -o "$H/.cache/rebar3/bin/rebar3" \
    "https://github.com/erlang/rebar3/releases/download/$REBAR3_VERSION/rebar3"
  as chmod 0755 "$H/.cache/rebar3/bin/rebar3"
fi
as "$H/.cache/rebar3/bin/rebar3" version

ask_key() {  # $1 file, $2 what it is, $3 how to get it — typed, never echoed
  local f="$CONF/$1" v
  if [ -s "$f" ] && [ "${KEYS:-}" != 1 ]; then step "$1 kept"; return; fi
  echo "$2 — $3"
  read -rs -p "paste it (hidden), then Enter: " v; echo
  [ -n "$v" ] || { echo "empty; nothing written" >&2; exit 1; }
  ( umask 077; printf '%s\n' "$v" > "$f" )
  chown "$USER_NAME:staff" "$f"; chmod 0600 "$f"
  step "$1 written"
}
[ "${1:-}" = --keys ] && KEYS=1
ask_key claude-token "the claude key" "in another terminal run:  claude setup-token"
ask_key gh-token "the GitHub key" "a fine-grained token at github.com/settings/personal-access-tokens, \
repository s27183/ancu only: Contents, Pull requests and Issues read and write"

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
echo "  tail -5 $LOGS/launchd-canary.log"
