"""One run of a KB job on Son's Mac: canary, fresh folder, confined agent, publish (behavior 145).

Regulated figures are grounded -> R-3 -> The KB update -> a job runs its agent only after the canary held, in a folder of its own, and publishes only through the runner
Invariant: the agent never holds a GitHub key and never runs outside its folder; nothing it
  wrote runs as the runner — the runner's code comes from its own checkout at origin/main,
  and git never runs in the agent's folder once the agent has started.
Mechanism: run_job.sh brings the runner checkout to origin/main and execs this file from it.
  run() takes a lock, fetches main and the open kb-watch-* branches into the runner checkout,
  runs the canary (abort on anything but `held`, and file one issue for Son), clones the
  runner checkout into jobs/<job>-<stamp> with the remote-tracking branches copied in, builds
  .venv there with `uv sync --frozen`, then starts the agent with autolib.settings() and the
  job's prompt from its `---8<---` block, and hands the folder to publish.py, which reads it
  with os, never with git. Every step is logged to /Users/Shared/ancu-auto/logs/<job>-<stamp>.log
  with the agent's stream-json transcript beside it.
Capability: `run_job.sh <job>` (launchd) → `python3 runner.py <job>`; exit 0 when the job ran
  (with or without a PR), 1 when it stopped (canary, setup, publish refused), each with why.
"""
from __future__ import annotations

import fcntl
import shutil
import subprocess
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import autolib as A  # noqa: E402

KEEP_DAYS = 14


class Log:
    def __init__(self, path: Path):
        path.parent.mkdir(parents=True, exist_ok=True)
        self.f = open(path, "a", buffering=1)

    def __call__(self, msg: str) -> None:
        hits = A.secret_hits(msg)
        if hits:
            msg = f"(line withheld: it held {', '.join(hits)})"
        line = f"{time.strftime('%Y-%m-%dT%H:%M:%S%z')} {msg}"
        self.f.write(line + "\n")
        print(line, flush=True)


def fetch_runner(log: Log) -> str:
    """Bring origin/main and every kb-watch-* branch into the runner checkout; main's sha."""
    A.git(A.RUNNER, "fetch", "--prune", "origin", "+refs/heads/main:refs/remotes/origin/main",
          "+refs/heads/kb-watch-*:refs/remotes/origin/kb-watch-*")
    sha = A.git(A.RUNNER, "rev-parse", "origin/main").strip()
    log(f"origin/main at {sha[:10]}")
    return sha


def make_folder(job: str, stamp: str, base: str, log: Log) -> Path:
    """A fresh clone of the runner checkout at `base`, with its remote-tracking branches, and
    .venv built — all before the agent starts (after that, no git runs there)."""
    d = A.JOBS / f"{job}-{stamp}"
    A.JOBS.mkdir(parents=True, exist_ok=True)
    subprocess.run(["git", "-c", "core.hooksPath=/dev/null", "clone", "--quiet", "--no-checkout",
                    str(A.RUNNER), str(d)], check=True, env=A.git_env(), capture_output=True)
    A.git(d, "fetch", "--quiet", str(A.RUNNER), "+refs/remotes/origin/*:refs/remotes/origin/*")
    A.git(d, "checkout", "--quiet", "-B", "main", base)
    A.git(d, "branch", "--quiet", "--set-upstream-to=origin/main", "main")
    A.git(d, "remote", "set-url", "origin", f"https://github.com/{A.REPO_SLUG}.git")
    r = subprocess.run(["uv", "sync", "--frozen", "--quiet"], cwd=d, capture_output=True,
                       text=True, env={"PATH": A.TOOLCHAIN_PATH, "HOME": str(A.HOME)})
    if r.returncode:
        raise RuntimeError(f"uv sync: {r.stderr.strip()[-400:]}")
    log(f"folder {d} at {base[:10]}, .venv built")
    return d


def prune(log: Log) -> None:
    cutoff = time.time() - KEEP_DAYS * 86400
    for d in A.JOBS.glob("*-*"):
        if d.is_dir() and d.stat().st_mtime < cutoff:
            shutil.rmtree(d, ignore_errors=True)
            log(f"pruned {d.name}")


def run(job: str) -> int:
    stamp = time.strftime("%Y%m%dT%H%M%S")
    log = Log(A.LOGS / f"{job}-{stamp}.log")
    A.STATE.mkdir(parents=True, exist_ok=True)
    lock = open(A.STATE / "lock", "w")
    try:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        log(f"{job}: another job is running; skipped")
        return 1
    log(f"{job}: start, runner {A.git(A.RUNNER, 'rev-parse', 'HEAD').strip()[:10]}")
    prune(log)
    try:
        base = fetch_runner(log)
        r = subprocess.run([sys.executable, str(A.RUNNER / "scripts/auto/canary.py")],
                           capture_output=True, text=True)
        for line in (r.stdout + r.stderr).splitlines():
            log(f"  {line}")
        last = r.stdout.rstrip().splitlines()[-1:] or [""]
        if r.returncode or not last[0].startswith("canary: held"):
            log(f"{job}: stopped — the canary did not hold; the agent did not run")
            A.file_issue(f"ancu-auto: canary failed {time.strftime('%Y-%m-%d')}",
                       f"The confinement canary did not hold before `{job}` (log "
                       f"{A.LOGS}/{job}-{stamp}.log on Son's Mac). No job runs its agent until "
                       "it holds again.\n\n```\n" + r.stdout[-3000:] + "\n```\n", log)
            return 1
        doc, _prefix, model, turns = A.JOBS_TABLE[job]
        folder = make_folder(job, stamp, base, log)
        settings_file = A.STATE / f"settings-{job}-{stamp}.json"
        A.write_json(settings_file, A.settings(folder))
        transcript = A.LOGS / f"{job}-{stamp}.jsonl"
        log(f"{job}: agent {model}, max {turns} turns, prompt from {doc}")
        rc = A.run_agent(folder, A.prompt(job), model, turns, settings_file, transcript)
        calls = A.tool_calls(A.stream_events(transcript))
        log(f"{job}: agent exit {rc}, {len(calls)} tool calls, "
            f"{sum(1 for c in calls if c['error'])} refused or failed")
        settings_file.unlink(missing_ok=True)
        import publish
        return publish.publish(job, folder, base, stamp, log)
    except Exception as e:  # a job that breaks says why in its log, then stops
        log(f"{job}: stopped — {type(e).__name__}: {e}")
        return 1


if __name__ == "__main__":
    if len(sys.argv) != 2 or sys.argv[1] not in A.JOBS_TABLE:
        sys.exit(f"usage: runner.py {{{','.join(A.JOBS_TABLE)}}}")
    sys.exit(run(sys.argv[1]))
