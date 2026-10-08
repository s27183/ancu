# FirstHomey engine image — Erlang/OTP gateway + per-turn Python Agent-SDK sidecar.
#
# Build context = REPO ROOT (engine/app.yaml sets source_dir: /), so the build can
# reach docs/ (KB sources), engine/build/ (the compiler), the repo-root
# pyproject.toml/uv.lock (sidecar deps), and engine/erlang/ (the OTP release).
#   docker build -f engine/Dockerfile .
#
# Reshaped from aleap's deployed engine/Dockerfile (same Agent-SDK stack, proven in
# prod — deployment.md §0/§4). FH divergences, deliberate:
#   - NO config/ COPY: FH has no vm.args.src/sys.config (single-node, non-distributed;
#     no ERLANG_COOKIE to template). aleap COPYs config/; FH has none.
#   - NO PYTHONPATH package: the sidecar is a LOOSE script wired via FH_PLANNER_SCRIPT
#     /FH_SIDECAR_PYTHON (aleap exposes an `aleap` package on PYTHONPATH).
#   - pyproject.toml/uv.lock are at the REPO ROOT (aleap: engine/python/).
#   - The KB artifact is COMPILED IN-BUILD (stage 1) from docs/ via kb_compiler.py
#     (git is SOT; artifact.json is a gitignored, rebuildable projection — constraint
#     #6), baked into the release priv/ AND shipped at the sidecar's repo-relative path
#     (planner.py reads _REPO_ROOT/engine/erlang/priv/kb/artifact.json — see stage 4).

# ── Stage 1: compile the KB+blueprint artifact (pure stdlib; no deps) ──────────────
# kb_compiler.py is json/re/sys/pathlib only; it resolves ROOT relative to its own
# path and validates docs/kb/** + docs/blueprints/** (structural + reference-integrity
# + coverage gates) before emitting. A failure here FAILS THE BUILD (fail-closed).
FROM python:3.14-slim AS kb-builder
WORKDIR /src
COPY docs docs/
COPY engine/build engine/build/
RUN python3 engine/build/kb_compiler.py
# -> /src/engine/erlang/priv/kb/artifact.json

# ── Stage 2: Erlang release (bake migrations + the artifact into priv before relx) ──
FROM erlang:28-slim AS erlang-builder
WORKDIR /build
COPY engine/erlang/rebar.config engine/erlang/rebar.lock ./
COPY engine/erlang/src src/
COPY engine/erlang/priv priv/
# Overlay the in-build artifact (priv/kb/artifact.json is gitignored, so it is NOT in
# the COPY above) so the engine loads it at boot via code:priv_dir(fh_engine).
COPY --from=kb-builder /src/engine/erlang/priv/kb/artifact.json priv/kb/artifact.json
RUN rebar3 as prod release
# -> /build/_build/prod/rel/fh_engine  (priv/ holds migrations/ + kb/artifact.json)

# ── Stage 3: Python sidecar deps (claude-agent-sdk / psycopg / pydantic) ───────────
FROM python:3.14-slim AS python-builder
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/
WORKDIR /app
COPY pyproject.toml uv.lock ./
RUN uv export --frozen --no-hashes --no-header --no-emit-project --format requirements-txt > /tmp/requirements.txt \
    && uv pip install --system -r /tmp/requirements.txt

# ── Stage 4: runtime ───────────────────────────────────────────────────────────────
FROM python:3.14-slim

# Runtime deps:
#   - libncurses6, libssl3: required by ERTS.
#   - ca-certificates: Erlang's pubkey_os_cacerts needs these for outbound TLS
#     (Anthropic). Keep installed — do not purge.
#   - curl: used once below to fetch the Claude Code installer. Kept (small).
RUN apt-get update && apt-get install -y --no-install-recommends \
    libncurses6 libssl3 ca-certificates curl \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /usr/share/doc /usr/share/man

# Python packages from the deps builder
COPY --from=python-builder /usr/local/lib/python3.14 /usr/local/lib/python3.14
COPY --from=python-builder /usr/local/bin /usr/local/bin

# Erlang OTP release
COPY --from=erlang-builder /build/_build/prod/rel/fh_engine /opt/fh_engine

# Python sidecar source (loose script — spawned per turn as a {packet,4} port).
# planner.py resolves _REPO_ROOT = Path(__file__).parents[2]; placing it at
# /app/engine/python makes _REPO_ROOT = /app, so its runtime reads resolve to
# /app/docs/kb/** and /app/engine/erlang/priv/kb/artifact.json (both COPYd below).
COPY engine/python /app/engine/python
COPY --from=kb-builder /src/docs/kb /app/docs/kb
COPY --from=erlang-builder /build/priv/kb/artifact.json /app/engine/erlang/priv/kb/artifact.json

# Non-root user with a home dir (Erlang cookie-file fallback for `foreground`)
RUN groupadd --gid 1000 app && \
    useradd --uid 1000 --gid app --create-home --shell /bin/bash app && \
    chown -R app:app /opt/fh_engine /app

USER app

# Sidecar wiring (also settable via engine/app.yaml; these are the image defaults).
#   FH_SIDECAR_PYTHON = the interpreter with the SDK deps (installed --system above)
#   FH_PLANNER_SCRIPT = the loose sidecar entrypoint the gateway spawns
ENV FH_SIDECAR_PYTHON=python3
ENV FH_PLANNER_SCRIPT=/app/engine/python/planner.py

# Claude Code CLI — the Agent SDK (claude-agent-sdk) shells out to a `claude` binary.
# It prefers the CLI bundled in its own wheel (claude_agent_sdk/_bundled/claude) and
# falls back to shutil.which("claude") only when the wheel has none (read in 0.2.159,
# subprocess_cli.py:254-260; on macOS the bundled one ran — 2.1.222 under 0.2.130,
# 2.1.281 under 0.2.159). So this pin is the fallback; the SDK version in uv.lock is
# what moves the CLI that actually runs. Installed as the STANDALONE NATIVE BINARY (no
# Node) via the official installer, as the app user (lands in /home/app/.local).
# Pinned (bump CLAUDE_CODE_VERSION deliberately); DISABLE_AUTOUPDATER keeps the image
# on the pin. The credit token (CLAUDE_CODE_OAUTH_TOKEN) is injected at runtime as a
# secret; the planner's _credit_env() blanks ANTHROPIC_API_KEY in the SDK subprocess.
# Version lifted from aleap's proven image (same SDK stack).
ARG CLAUDE_CODE_VERSION=2.1.167
ENV DISABLE_AUTOUPDATER=1
ENV PATH=/home/app/.local/bin:$PATH
RUN curl -fsSL https://claude.ai/install.sh | bash -s "${CLAUDE_CODE_VERSION}" \
    && claude --version

# Audit-trail commit SHA (constraint #6): each filled plan card records it. DO App
# Platform does NOT auto-inject the git SHA — pass --build-arg FH_DEPLOY_COMMIT_SHA=$(git rev-parse HEAD)
# from a CI build, or accept "unknown" for plain deploy_on_push builds (see
# deployment.md §2 / §6). NOT a secret.
ARG FH_DEPLOY_COMMIT_SHA=unknown
ENV FH_DEPLOY_COMMIT_SHA=${FH_DEPLOY_COMMIT_SHA}

EXPOSE 8080
CMD ["/opt/fh_engine/bin/fh_engine", "foreground"]
