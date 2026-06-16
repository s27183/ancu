# FirstHomey shell backend image — Erlang/OTP only (cowboy + pgo). Identity +
# commerce; serves /api/* + /health. The frontend ships SEPARATELY to Cloudflare
# Pages (deployment.md §1/§4 step 7) — no bundle bake here.
#
# Build context = shell/web/ (shell/web/app.yaml sets source_dir: shell/web,
# dockerfile_path: shell/web/Dockerfile):
#   docker build -f shell/web/Dockerfile shell/web
#
# Reshaped from aleap's shell Dockerfile. FH divergence: NO config/ COPY (FH has no
# vm.args.src/sys.config — single-node, non-distributed; no ERLANG_COOKIE template).

# ── Stage 1: Erlang release ────────────────────────────────────────────────────────
FROM erlang:28-slim AS erlang-builder
WORKDIR /build
COPY backend/rebar.config backend/rebar.lock ./
COPY backend/src src/
COPY backend/priv priv/
RUN rebar3 as prod release
# -> /build/_build/prod/rel/fh_shell  (priv/ holds migrations/ 001..003)

# ── Stage 2: runtime ───────────────────────────────────────────────────────────────
# Runtime base MUST match the builder's glibc: erlang:28-slim is Debian 13 (trixie,
# glibc 2.38+), so ERTS binaries require GLIBC_2.38. bookworm (Debian 12) is too old
# -> "GLIBC_2.38 not found" crash loop. Use trixie-slim. (deployment.md §4 step 1.)
FROM debian:trixie-slim

# Runtime deps:
#   - libncurses6, libssl3: required by ERTS.
#   - ca-certificates: Erlang outbound TLS — engine HTTP calls, Stripe, Google OAuth,
#     Resend. Keep installed — do not purge.
RUN apt-get update && apt-get install -y --no-install-recommends \
    libncurses6 libssl3 ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /usr/share/doc /usr/share/man

COPY --from=erlang-builder /build/_build/prod/rel/fh_shell /opt/fh_shell

RUN groupadd --gid 1000 app && \
    useradd --uid 1000 --gid app --create-home --shell /bin/bash app && \
    chown -R app:app /opt/fh_shell

USER app

EXPOSE 8081
CMD ["/opt/fh_shell/bin/fh_shell", "foreground"]
