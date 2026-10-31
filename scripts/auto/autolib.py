"""Shared pieces of the KB jobs that run on Son's Mac (behavior 145).

Regulated figures are grounded -> R-3 -> The KB update -> a job's agent edits only its own folder; every act outside it is the runner's
Invariant: the agent a job starts (claude -p) reads and writes only its job folder, fetches
  only the KB's source hosts, and holds no GitHub key; whatever leaves this Mac leaves
  through the runner (publish.py, gate.py), which runs from its own checkout, never from
  the agent's folder, and never runs git inside the agent's folder (a .git/config or
  .gitattributes the agent wrote would run code as the runner: core.fsmonitor, filters).
Mechanism: settings() builds the job's Claude Code settings — permission rules Read(./**)
  and Edit(./**) for the file tools, WebFetch(domain:…) per source host, dontAsk mode — and
  the Bash sandbox: failIfUnavailable with no unsandboxed escape, denyRead /Users with
  allowRead of the job folder and the toolchain only, network to the source hosts only.
  Measured 2026-10-31 on claude 2.1.314: a bare `Read` allow read a file outside the cwd,
  `Read(./**)` refused it (absolute, ../, Grep, Glob); `WebFetch(domain:*.gov.au)` matched
  www.rba.gov.au while `domain:austlii.edu.au` did not match www.austlii.edu.au (so each
  host goes in both forms); with the sandbox required and unable to start, Bash refused
  every command. Outside all of it, the jobs run as the macOS user ancuauto, which cannot
  open /Users/son (drwx------).
Capability: source_hosts(), settings(job_dir), prompt(job), allowed_path(p),
  changed_files(job_dir, base) and secret_hits(text) — the pure parts the runner, the
  publisher, the gate and selftest.sh share.
"""
from __future__ import annotations

import hashlib
import json
import os
import re
import subprocess
import sys
from pathlib import Path

RUNNER = Path(__file__).resolve().parents[2]       # the runner's own checkout
sys.path.insert(0, str(RUNNER / "engine" / "build"))
import kb_compiler  # noqa: E402  (stdlib only; its host lists are the KB's primaries)

REPO_SLUG = "s27183/ancu"
SON = "s27183"
HOME = Path(os.environ.get("ANCU_AUTO_HOME", str(Path.home())))
JOBS = HOME / "jobs"
STATE = HOME / "state"
CONF = HOME / ".config" / "ancu-auto"
GH_TOKEN_FILE = CONF / "gh-token"
CLAUDE_TOKEN_FILE = CONF / "claude-token"
CLAUDE_DIR = HOME / ".claude-jobs"
LOGS = Path(os.environ.get("ANCU_AUTO_LOGS", "/Users/Shared/ancu-auto/logs"))
OUTBOX = ".ancu-outbox"
ALLOWED_ROOTS = ("docs/kb/", "docs/sources/")

# job -> (its prompt's doc, the branch prefix its PR takes, the model, max turns)
JOBS_TABLE = {
    "news-watch": ("docs/architecture/news-watch-routine.md", "kb-watch-news-", "sonnet", 300),
    "kb-watch": ("docs/architecture/kb-watch-routine.md", "kb-watch-", "opus", 400),
    "kb-verify": ("docs/architecture/kb-verify-routine.md", None, "opus", 300),
    "suburb-watch": ("docs/architecture/suburb-watch-routine.md", None, "sonnet", 120),
}


def source_hosts() -> list[str]:
    """Every host suffix a KB doc may cite (kb_compiler's primaries), sorted."""
    hosts = set(kb_compiler.PRIMARY_GOV_LAW_HOSTS)
    for hs in kb_compiler.PRIMARY_PROVIDER_HOSTS.values():
        hosts.update(hs)
    return sorted(hosts)


def url_allowed(url: str) -> bool:
    """https on a source host, by kb_compiler's strict authority match (no userinfo,
    backslash, percent-escape, other port or scheme)."""
    host = kb_compiler.url_host(url)
    return bool(host) and kb_compiler.host_in(host, source_hosts())


def settings(job_dir: Path, home: Path = HOME) -> dict:
    """The Claude Code settings one job's agent runs under."""
    hosts = source_hosts()
    both = [d for h in hosts for d in (h, "*." + h)]
    return {
        "permissions": {
            "defaultMode": "dontAsk",
            "allow": ["Read(./**)", "Edit(./**)"] + [f"WebFetch(domain:{d})" for d in both],
            "deny": ["Read(//Users/**/.config/**)", "Read(//Users/**/.ssh/**)"],
        },
        "sandbox": {
            "enabled": True,
            "failIfUnavailable": True,
            "allowUnsandboxedCommands": False,
            "autoAllowBashIfSandboxed": True,
            "filesystem": {
                "denyRead": ["/Users"],
                "allowRead": [str(job_dir), str(home / ".local"), str(home / ".cache" / "uv"),
                              str(CLAUDE_DIR if home == HOME else home / ".claude-jobs")],
                "allowWrite": [str(job_dir)],
            },
            "network": {"allowedDomains": both},
        },
        "env": {"SHELL": "/bin/bash"},
    }


def prompt(job: str, root: Path = RUNNER) -> str:
    """The job's prompt: the text between its doc's two `---8<---` lines."""
    doc = (root / JOBS_TABLE[job][0]).read_text(encoding="utf-8")
    parts = doc.split("---8<---\n")
    if len(parts) != 3:
        raise SystemExit(f"{JOBS_TABLE[job][0]}: expected one ---8<--- block")
    return parts[1].rstrip("\n")


def allowed_path(p: str) -> bool:
    """A path the publisher may commit: relative, normalised, under docs/kb or docs/sources,
    no dot segment, no control or backslash character."""
    if not p or p.startswith("/") or "\\" in p or any(ord(c) < 32 or ord(c) == 127 for c in p):
        return False
    segs = p.split("/")
    if any(s in ("", ".", "..") or s.startswith(".") for s in segs):
        return False
    return p.startswith(ALLOWED_ROOTS)


def git(repo: Path, *args: str, input: bytes | None = None, check: bool = True) -> str:
    """git in a repo the runner owns (never the agent's folder), hooks and fsmonitor off."""
    r = subprocess.run(["git", "-c", "core.hooksPath=/dev/null", "-c", "core.fsmonitor=false",
                        *args], cwd=repo, input=input, capture_output=True, env=git_env())
    if check and r.returncode:
        raise RuntimeError(f"git {' '.join(args)}: {r.stderr.decode(errors='replace').strip()}")
    return r.stdout.decode(errors="replace")


def git_env() -> dict:
    """The runner's git environment: no system or global config, the GitHub token as an
    extra header read from its file (environment, not argv: argv shows in ps)."""
    env = {"PATH": os.environ.get("PATH", "/usr/bin:/bin"), "HOME": str(HOME),
           "GIT_CONFIG_NOSYSTEM": "1", "GIT_CONFIG_GLOBAL": "/dev/null",
           "GIT_TERMINAL_PROMPT": "0"}
    if GH_TOKEN_FILE.is_file():
        import base64
        tok = GH_TOKEN_FILE.read_text().strip()
        basic = base64.b64encode(f"x-access-token:{tok}".encode()).decode()
        env.update({"GIT_CONFIG_COUNT": "1",
                    "GIT_CONFIG_KEY_0": "http.https://github.com/.extraheader",
                    "GIT_CONFIG_VALUE_0": f"AUTHORIZATION: basic {basic}"})
    return env


def blob_sha(data: bytes) -> str:
    return hashlib.sha1(b"blob %d\0" % len(data) + data).hexdigest()


SKIP_DIRS = {".git", OUTBOX, ".venv", "node_modules", "__pycache__", "_build"}


def walk(job_dir: Path) -> dict[str, Path]:
    """Every file under job_dir by relative path, symlinks included as themselves (never
    followed), the skipped folders left out wherever they are (what is skipped is never
    published). Reads the tree with os, not git."""
    out = {}
    for dirpath, dirnames, filenames in os.walk(job_dir, followlinks=False):
        rel_dir = os.path.relpath(dirpath, job_dir)
        dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS]
        for d in list(dirnames):
            if os.path.islink(os.path.join(dirpath, d)):
                out[os.path.normpath(os.path.join(rel_dir, d))] = Path(dirpath, d)
                dirnames.remove(d)
        for f in filenames:
            out[os.path.normpath(os.path.join(rel_dir, f))] = Path(dirpath, f)
    return out


def base_listing(repo: Path, base: str) -> dict[str, str]:
    """path -> blob sha of every tracked file at `base`, read in the runner's repo."""
    out = {}
    for line in git(repo, "ls-tree", "-r", "-z", base).split("\0"):
        if line:
            meta, path = line.split("\t", 1)
            out[path] = meta.split()[2]
    return out


def ignored(repo: Path, paths: list[str]) -> set[str]:
    """Which paths the base's .gitignore ignores, asked of the runner's repo."""
    if not paths:
        return set()
    r = git(repo, "check-ignore", "--no-index", "-z", "--stdin",
            input="\0".join(paths).encode() + b"\0", check=False)
    return {p for p in r.split("\0") if p}


def changed_files(job_dir: Path, listing: dict[str, str], ignore: set[str] | None = None
                  ) -> tuple[dict[str, Path], list[str], list[str]]:
    """Compare the agent's folder with the base: (changed or added -> file, deleted,
    problems). A symlink, or anything not a regular file, is a problem by itself."""
    files = walk(job_dir)
    ignore = ignore or set()
    changed, problems = {}, []
    for rel, p in files.items():
        if rel in ignore:
            continue
        if p.is_symlink() or not p.is_file():
            problems.append(f"{rel}: not a regular file")
            continue
        if listing.get(rel) != blob_sha(p.read_bytes()):
            changed[rel] = p
    deleted = [rel for rel in listing if rel not in files]
    return changed, deleted, problems


SECRET_SHAPES = re.compile(r"(sk-ant-[A-Za-z0-9_-]{16,}|gh[opusr]_[A-Za-z0-9]{20,}|"
                           r"github_pat_[A-Za-z0-9_]{20,}|-----BEGIN [A-Z ]*PRIVATE KEY-----)")


def secrets() -> list[str]:
    out = []
    for f in (GH_TOKEN_FILE, CLAUDE_TOKEN_FILE):
        if f.is_file():
            v = f.read_text().strip()
            if len(v) >= 12:
                out.append(v)
    return out


def secret_hits(text: str, known: list[str] | None = None) -> list[str]:
    """What in `text` is a known secret value or has a secret's shape (never the value)."""
    hits = [f"known secret #{i}" for i, s in enumerate(known if known is not None else secrets())
            if s and s in text]
    hits += [f"{m.group(0)[:6]}… shape" for m in SECRET_SHAPES.finditer(text)]
    return hits


def write_json(path: Path, data) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(path.suffix + ".tmp")
    tmp.write_text(json.dumps(data, indent=2, sort_keys=True))
    tmp.replace(path)


# --- the agent run --------------------------------------------------------------------

def claude_bin(home: Path = HOME) -> str:
    """The claude CLI of the user running the job (its own install, auto-updated: the canary
    is what holds a new version), else the one on PATH."""
    own = home / ".local" / "bin" / "claude"
    if own.exists():
        return str(own)
    import shutil
    return shutil.which("claude") or "claude"


TOOLCHAIN_PATH = ":".join([str(HOME / ".local" / "bin"), str(HOME / ".cache" / "rebar3" / "bin"),
                           "/opt/homebrew/bin", "/usr/bin", "/bin", "/usr/sbin", "/sbin"])


def agent_env() -> dict:
    """The agent's environment: no GitHub token, no git config; the claude key from the job
    user's token file, or (in Son's seat, for the canary) the served-key variables."""
    env = {"PATH": TOOLCHAIN_PATH, "HOME": str(HOME), "SHELL": "/bin/bash", "LANG": "en_US.UTF-8",
           "CLAUDE_CONFIG_DIR": str(CLAUDE_DIR), "GIT_CONFIG_NOSYSTEM": "1",
           "GIT_CONFIG_GLOBAL": "/dev/null", "GIT_TERMINAL_PROMPT": "0",
           "TMPDIR": os.environ.get("TMPDIR", "/tmp")}
    if CLAUDE_TOKEN_FILE.is_file():
        env["CLAUDE_CODE_OAUTH_TOKEN"] = CLAUDE_TOKEN_FILE.read_text().strip()
    else:
        for k in ("ANTHROPIC_UNIX_SOCKET", "ANTHROPIC_BASE_URL", "CLAUDE_CODE_OAUTH_TOKEN"):
            if k in os.environ:
                env[k] = os.environ[k]
    return env


AGENT_TOOLS = "Read,Edit,Write,Grep,Glob,WebFetch,Bash"


def run_agent(job_dir: Path, text: str, model: str, max_turns: int, settings_file: Path,
              transcript: Path, timeout: int = 3 * 3600) -> int:
    """`claude -p` in job_dir under settings_file, no settings from anywhere else, no MCP, no
    session kept; its stream-json transcript goes to `transcript`. Returns the exit code."""
    cmd = [claude_bin(), "-p", text, "--output-format", "stream-json", "--verbose",
           "--model", model, "--max-turns", str(max_turns), "--tools", AGENT_TOOLS,
           "--settings", str(settings_file), "--setting-sources", "", "--strict-mcp-config",
           "--no-session-persistence"]
    transcript.parent.mkdir(parents=True, exist_ok=True)
    with open(transcript, "wb") as out:
        try:
            return subprocess.run(cmd, cwd=job_dir, env=agent_env(), stdin=subprocess.DEVNULL,
                                  stdout=out, stderr=subprocess.STDOUT, timeout=timeout).returncode
        except subprocess.TimeoutExpired:
            return 124


def stream_events(transcript: Path) -> list[dict]:
    out = []
    for line in transcript.read_text(errors="replace").splitlines():
        try:
            out.append(json.loads(line))
        except ValueError:
            pass
    return out


def tool_calls(events: list[dict]) -> list[dict]:
    """Each tool call in order: {id, name, input, result, error} (result text joined)."""
    calls, by_id = [], {}
    for e in events:
        m = e.get("message")
        content = m.get("content") if isinstance(m, dict) else None
        if not isinstance(content, list):
            continue
        for c in content:
            if c.get("type") == "tool_use":
                call = {"id": c.get("id"), "name": c.get("name"), "input": c.get("input") or {},
                        "result": "", "error": None}
                calls.append(call)
                by_id[call["id"]] = call
            elif c.get("type") == "tool_result" and c.get("tool_use_id") in by_id:
                r = c.get("content")
                if isinstance(r, list):
                    r = "\n".join(x.get("text", "") for x in r if isinstance(x, dict))
                by_id[c["tool_use_id"]]["result"] = str(r or "")
                by_id[c["tool_use_id"]]["error"] = bool(c.get("is_error"))
    return calls
