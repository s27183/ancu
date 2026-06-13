# FirstHomey web shell — backend (Erlang/OTP)

Identity, the engine-JWT seam, and (later) commerce for the web shell. The design
lives in [`docs/architecture/shell-architecture.md`](../../../docs/architecture/shell-architecture.md);
this README is just how to run it. The shell and engine are **separate deployables**
with separate databases — the HTTP API is the only contract (engine-contract §9).

## What's here (8-S0)

- Boot + fail-closed migrations (`fh_shell_app/sup/db/migrations`), `/health`.
- The **two-JWT seam** (§3): `fh_shell_jwt` (user JWT, HS256) + `fh_shell_engine_jwt`
  (the ed25519 **tenant** JWT the engine verifies) + `fh_shell_engine_client`.
- Schema `001_init_shell.sql`: `users`, `magic_tokens`, `oauth_identities`,
  `plan_card_views`.

Login (Resend/Google), the engine proxy surfaces, and commerce land in later slices.

## Dev run

```sh
# 1. dev Postgres (port 5434, beside the engine's 5433)
docker compose -f compose.yaml up -d

# 2. compile
rebar3 compile

# 3. boot smoke — boots the app, applies 001, hits /health, round-trips a user
SHELL_DATABASE_URL='postgres://shell:shell_dev_pw@localhost:5434/firsthomey_shell?sslmode=disable' \
  ERL_LIBS=_build/default/lib escript test/boot_smoke.escript
```

## Seam round-trip (the keystone)

Proves the shell's tenant-JWT mint path verifies against the **real engine**. Needs
the engine's dev Postgres (5433) up and BOTH build libs on the path:

```sh
ENGINE_DATABASE_URL='postgres://engine:engine_dev_pw@localhost:5433/firsthomey_engine?sslmode=disable' \
  ERL_LIBS=_build/default/lib:../../../engine/erlang/_build/default/lib \
  escript test/seam_roundtrip.escript
```

## Runtime config (`.env`, one level up — never user-facing)

| Var | Purpose |
|---|---|
| `SHELL_DATABASE_URL` | the shell's Postgres (identity/commerce) |
| `SHELL_JWT_SECRET` | HS256 secret for the user JWT |
| `SHELL_TENANT_ID` | the shell's tenant_id, registered in the engine |
| `SHELL_TENANT_PRIVKEY` | base64 of the raw ed25519 private key (public half registered engine-side at provisioning) |
| `ENGINE_BASE_URL` | the engine gateway base (default `http://localhost:8080/api/engine`) |
| `FH_SHELL_HTTP_PORT` | listener port (default 8081) |
