# The local KB jobs — how the KB update runs on Son's Mac

Regulated figures are grounded -> R-3 -> The KB update -> the KB jobs run on Son's Mac as ancuauto, confined, and publish only through the runner

**What this is.** Since behavior 145 (Son 2026-10-31: «I want to setup all auto update to
run from here (cron job?) instead of leaving it to CI on github») the KB update runs on
Son's Mac, not as claude.ai routines and not in GitHub Actions. Six launchd jobs run as a
separate macOS user, `ancuauto`, which cannot read Son's home. Each KB job starts a
headless `claude -p` agent that only edits files in a folder of its own; the runner —
code from `origin/main`, never from that folder — publishes what the agent left, and the
local gate merges it when verified. This page is how it fits together; each job's prompt
is in its own doc.

## The jobs

| Job | When (local time) | Prompt | Output |
|---|---|---|---|
| canary | 05:45 daily, and before every job | `scripts/auto/canary.py` | `canary: held`, or one issue for Son and no job runs |
| news-watch | 06:00 daily | [news-watch-routine.md](news-watch-routine.md) | one PR from `kb-watch-news-<date>`, or none |
| kb-watch | Monday 06:00 | [kb-watch-routine.md](kb-watch-routine.md) | one PR from `kb-watch-<date>`, and an issue when it needs Son |
| suburb-watch | 07:00 on the 1st | [suburb-watch-routine.md](suburb-watch-routine.md) | one issue when a suburb source has a newer release |
| kb-verify | 09:00 daily | [kb-verify-routine.md](kb-verify-routine.md) | a verdict, `kb-verified` or `kb-hold`, for each open `kb-watch-*` head |
| gate | 09:45 daily | `scripts/auto/gate.py` | each verified PR merged, or held with one issue |

launchd runs a missed time when the Mac wakes. Two jobs never overlap: each takes
`~/state/lock` and a second one logs "another job is running; skipped".

## One run

`/Library/LaunchDaemons/com.s27183.ancu-auto.<job>.plist` (from [ops/launchd](../../ops/launchd))
runs `scripts/auto/run_job.sh <job>` as `ancuauto`, which:

1. brings the runner checkout `/Users/ancuauto/ancu` to `origin/main` (git hooks off, no
   git config but the token header) and runs the Python from it — what runs is what Son
   merged;
2. `runner.py` fetches main and the open `kb-watch-*` branches, runs the canary, and stops
   unless it held;
3. clones the runner checkout into `~/jobs/<job>-<stamp>`, builds `.venv` with
   `uv sync --frozen` (for kb-verify, writes `.ancu-outbox/known.json`: the heads that
   already have a verdict) — git never runs there again;
4. runs the agent with the job's prompt (the block between `---8<---` lines in its doc,
   read from `origin/main`) under settings from `autolib.settings()`;
5. hands the folder to `publish.py`, which reads it with `os`:
   - every changed path must be a regular file under `docs/kb/` or `docs/sources/` with no
     secret in it, else the whole run is refused ("refused: <path>") and one issue says why;
   - the commit is built with a private index in the runner's repo, pushed to a new
     branch (never forced), and the PR opened from `.ancu-outbox/pr.md`;
   - `.ancu-outbox/issue.md` becomes one issue assigned to Son (a later run with the same
     title comments on it instead);
   - kb-verify's `.ancu-outbox/verdict-<branch>.md` (line 1 `kb-verified` or `kb-hold`,
     line 2 `sha <40 hex>`) is recorded in `~/state/verdicts.json` only when the sha is
     that branch's head, and posted on its PR.

The gate (`gate.py`) lists open PRs and, for a same-repo `kb-watch-*` head whose diff is
all `docs/kb/` and `docs/sources/`, runs the done checks at that head in a fresh clone,
asks `scripts/kb_gate.py` (main's copy) for a decision, and merges with
`--match-head-commit` only when the checks passed, kb_gate says merge and the local
verdict for that exact sha is `kb-verified`. A label or comment anyone else adds counts
for nothing. Anything else is held, with one comment and one issue. CI skips its
"done checks" job for such a head (the ruleset counts a skipped job as passed); every
other PR still runs it on GitHub.

## Confinement

The agent's settings (`autolib.settings`, checked by `selftest.py`):

- file tools: `Read(./**)` and `Edit(./**)` in `dontAsk` mode — nothing outside the folder;
- WebFetch: only the KB's source hosts (`kb_compiler`'s primary map, the same list
  `archive_source.py` enforces on every fetch);
- Bash: sandboxed, failing closed (`failIfUnavailable`, no unsandboxed escape), reading only
  the folder and the toolchain, writing only the folder, network only to the source hosts;
- environment: no GitHub key at all. The claude key is the agent's only key.

The `claude` CLI updates itself, so this is measured again before every job: the canary
plants a random token outside a fresh folder and asks an agent under the same settings to
make 16 escape attempts (absolute and `../` reads, Grep, Glob, Write, Edit, WebFetch
off-list, Bash `cat`, `python3 open()`, `curl file://`, the keychain, `gh auth token`,
`git credential fill`, the runner's token file, and a file of Son's) plus five controls
(a read inside, WebFetch and curl to a source host, `echo`, curl off-list). It holds only
when every attempt was made and refused, the token never appears, and the controls worked.

## Setup and the way back

Son, once, after the PR that carries this is merged:

    sudo sysadminctl -addUser ancuauto -fullName "ancu auto" -shell /bin/zsh
    sudo bash scripts/auto/install.sh
    sudo launchctl kickstart system/com.s27183.ancu-auto.canary

`install.sh` clones the public repo as `ancuauto`, installs claude, uv and rebar3 in its
home, asks for two keys (typed, never echoed): a `claude setup-token` key and a
fine-grained GitHub token for s27183/ancu only (Contents, Pull requests, Issues: read and
write), stored 0600 in `/Users/ancuauto/.config/ancu-auto/`, and bootstraps the six plists.
`--keys` asks for both again.

Logs: `/Users/Shared/ancu-auto/logs/<job>-<stamp>.log`, the agent's transcript beside it
as `.jsonl`; launchd's own output in `launchd-<job>.log`. A log line holding a secret's
shape is withheld. Job folders are pruned after 14 days.

To stop it: `sudo launchctl bootout system/com.s27183.ancu-auto.<job>` for each job;
`sudo sysadminctl -deleteUser ancuauto` and revoking the GitHub token remove it entirely.

## Checks

`bash scripts/auto/selftest.sh` (on the done checks' line) checks the settings, prompts,
plists and runner offline, and runs seeded properties (seed 145, 400 cases each) over the
publisher, the URL gate and the merge decision. `python3 scripts/auto/canary.py --seat`
runs the canary inside a Claude Code seat, where the Bash sandbox cannot nest and Bash must
be refused outright.
