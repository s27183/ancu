# Local dev — run the whole stack

Three processes, each launched **from its own directory** — the same per-component
shape as production (each Erlang half is its own relx release / DO app; the frontend
is an `adapter-static` SPA). Start the **engine first** (the shell registers its tenant
key with it at boot), then the shell backend, then the frontend.

```
┌─ Postgres ─────────────┐   ┌─ Engine (Erlang) ─┐   ┌─ Shell backend ─┐   ┌─ Frontend ─┐
│ :5432 brew  shell DB   │←──│                   │   │  :8081          │←──│ :5173 vite │
│ :5433 docker engine DB │←──│  :8080  /api/engine│←─│  proxy + auth   │   │  (browser) │
└────────────────────────┘   └───────────────────┘   └─────────────────┘   └────────────┘
```

The tenant signing key is **minted and registered automatically** by the shell↔engine
handshake — you never run a key-gen escript. (How: [the handshake](#the-tenant-handshake-no-manual-keys).)

---

## Run it — `bin/dev`, one per component, three terminals

Each component has its own `bin/dev`. `cd` into the directory and run it — **in this order**
(engine first, so the shell's boot-time key registration lands):

```
cd engine/erlang      && bin/dev    # terminal 1 — engine PG (docker :5433) + engine :8080
cd shell/web/backend  && bin/dev    # terminal 2 — shell PG (brew :5432) + shell :8081
cd shell/web/frontend && bin/dev    # terminal 3 — frontend (vite) :5173 → open it
```

That's the whole thing. Each launcher is a thin wrapper around the standard dev command
(`rebar3 shell` for the Erlang halves, `npm run dev` for the frontend); it only adds the
one thing that component needs to come up locally (its database). `bin/dev reset` in either
Erlang dir wipes *that* component's dev DB.

**Prereqs** (one-time, all handled by the scripts except the runtimes themselves):
`rebar3`, `node`/`npm`, `docker`, `python3` on PATH, and homebrew `postgresql@18`. The shell
launcher starts the homebrew Postgres if it's down and creates `firsthomey_shell` if missing;
the engine launcher brings up the engine's docker Postgres — you don't run `createdb` or
`docker compose` by hand.

**Config — one `.env` at the repo root.** Both backends read the **single root `.env`**
(engine walks two levels up from `engine/erlang`, shell three from `shell/web/backend` — the
aleap/atp convention). Copy `.env.example` → `.env` and fill. It's already wired for a pure-local
run (autoprovision + zero-inbox magic-link on, both DB URLs set); no edits needed to start.

### What each launcher does

- **`engine/erlang/bin/dev`** — `docker compose -f engine/compose.yaml up -d`, waits for
  `:5433`, then `rebar3 shell`. Config (`ENGINE_DATABASE_URL`, `ENGINE_DEV_PROVISION=1` — the
  dev tenant-registration endpoint) comes from the root `.env`.
- **`shell/web/backend/bin/dev`** — ensures the homebrew shell DB, then `rebar3 shell`. It
  reads the root `.env`, migrates the `:5432` shell DB, and — because `SHELL_DEV_AUTOPROVISION=1`
  and no static key is set — mints an ed25519 keypair and POSTs its public half to the engine:
  ```
  [autoprovision] generated dev tenant key for 11111111-1111-1111-1111-111111111111
  [autoprovision] registered with engine at http://localhost:8080/api/engine/dev/tenants
  ```
  `engine unreachable` here means you started the shell before the engine — start the engine,
  then re-run it. (Login works without the engine; only plan-card creation needs it.)
- **`shell/web/frontend/bin/dev`** — `npm install` if needed, then `npm run dev`. Vite proxies
  `/api` and `/health` → the shell backend on `:8081`.

Real LLM planning is optional — the engine defaults to a stub sidecar that needs no API key
(see [the bottom](#optional-real-llm-planning)).

---

## Try it

- **Map** loads immediately (public reference data via the shell→engine proxy). Pick a
  state; click a suburb.
- **Sign in** (top-right). Enter any email → "Send sign-in link". With
  `AUTH_DEV_EXPOSE_LINK=1` the link is shown in the UI (and returned in the JSON) — click it,
  no inbox needed. Or use **Continue with Google** if you've set the Google keys.
- **Make a plan** from a suburb sheet → onboarding → "Create my plan". The shell mints a
  tenant JWT from its auto-provisioned key and the engine accepts it (HTTP **202**); the
  base turn runs on the stub planner.

---

## The tenant handshake (no manual keys)

The shell signs every engine call with a short-lived **tenant JWT** (ed25519); the engine
verifies it against the tenant's **public** key in its DB. In production those keys are
provisioned out-of-band. For local dev, two flags let the two processes do it themselves:

| Side | Flag | Effect |
|---|---|---|
| Engine | `ENGINE_DEV_PROVISION=1` | Opens `POST /api/engine/dev/tenants` (else it 404s). |
| Shell | `SHELL_DEV_AUTOPROVISION=1` | At boot: mint keypair → stash priv in memory → POST pub to the engine. |

The private key lives only in the shell process's memory — nothing is written to disk,
nothing is committed. A fresh keypair each boot; the engine upserts it idempotently.

> **Dev only.** `ENGINE_DEV_PROVISION` lets any caller register a tenant + key, which in
> production is a forge-any-user hole. Never set it outside local dev. If both flags are
> unset and a real `SHELL_TENANT_PRIVKEY` is configured, the production path runs unchanged.

---

## What needs what

| You want to… | Needs |
|---|---|
| Map + browse suburbs | engine (:8080) + engine DB (:5433) |
| Sign in (magic-link / Google) | shell backend + shell DB (:5432) only — no engine |
| Create a plan card | shell **and** engine, with both dev flags set |

## Ports

| Process | Port | Override |
|---|---|---|
| Engine HTTP | 8080 | `FH_ENGINE_HTTP_PORT` |
| Shell backend HTTP | 8081 | `FH_SHELL_HTTP_PORT` |
| Frontend (vite) | 5173 | — |
| Engine Postgres | 5433 | `ENGINE_DATABASE_URL` |
| Shell Postgres | 5432 | `SHELL_DATABASE_URL` |

## Real login backends (Resend + Google)

**You don't need either for local dev.** `AUTH_DEV_EXPOSE_LINK=1` shows the magic-link in
the UI (no inbox), and "Continue with Google" just shows a calm "unavailable" until
configured. Set these only to exercise the real flows. Both go in the root `.env`; restart
the shell launcher after editing.

### Resend — magic-link email

1. Sign up at [resend.com](https://resend.com).
2. **API Keys → Create API Key** → copy it (starts `re_…`).
3. Pick a **From** address:
   - **Quick dev:** `onboarding@resend.dev` works with no domain setup, but Resend only
     delivers it to *your own* account email — fine for testing your own login.
   - **Real recipients:** **Domains → Add Domain**, add the DNS records it shows, then use
     e.g. `FirstHomey <noreply@yourdomain.com>`.
4. In `.env` (repo root):
   ```
   RESEND_API_KEY=re_xxxxxxxx
   EMAIL_FROM=no-reply@yourdomain.com     # the verified sender address
   EMAIL_FROM_NAME=FirstHomey             # optional → "FirstHomey <no-reply@…>"
   ```
5. Restart the shell launcher. Magic-link requests now actually email. (Leaving
   `AUTH_DEV_EXPOSE_LINK=1` also still echoes the link; delete it to force real inbox use.)

The shell calls Resend only when `RESEND_API_KEY` is set; otherwise it logs the link to the
backend console (`[dev magic-link] …`).

### Google — OAuth sign-in

1. [Google Cloud Console](https://console.cloud.google.com) → create or pick a project.
2. **APIs & Services → OAuth consent screen** → **External** → fill app name + support
   email. While the app is in **Testing**, add your Google address under **Test users**
   (only test users can sign in until you publish). The shell requests only the **`openid`**
   and **`email`** scopes.
3. **APIs & Services → Credentials → Create credentials → OAuth client ID** →
   **Application type: Web application**.
4. **Authorized redirect URI** — exactly (scheme, port, and path must match):
   ```
   http://localhost:5173/api/auth/google/callback
   ```
   (This is `APP_BASE_URL` + `/api/auth/google/callback`.)
5. **Create** → copy the **Client ID** and **Client secret**.
6. In `.env` (repo root):
   ```
   GOOGLE_CLIENT_ID=xxxxxxxx.apps.googleusercontent.com
   GOOGLE_CLIENT_SECRET=xxxxxxxx
   ```
7. Restart the shell launcher. "Continue with Google" now runs the real consent flow.

Notes:
- Google must report `email_verified` (normal for Google accounts) or the shell rejects the
  sign-in.
- Identity is **keyed by email** — signing in with Google for an address that already used a
  magic link lands the *same* account.
- **Prod:** add the production redirect URI (`https://yourdomain/api/auth/google/callback`),
  set `APP_BASE_URL` to the prod origin, and publish the consent screen.

## Optional: real LLM planning

The engine defaults to `engine/python/planner_stub.py` (no API key). For the real
Anthropic-SDK planner, set on the **engine** process:

```
FH_PLANNER_SCRIPT=../python/planner.py
FH_SIDECAR_PYTHON=../../.venv/bin/python      # the venv with the SDK
# + Anthropic credentials per the planner
```

## Reset

```
cd engine/erlang     && bin/dev reset    # wipes the engine docker DB (down -v)
cd shell/web/backend && bin/dev reset    # drops firsthomey_shell
```

The next `bin/dev` in each dir recreates that component's schema on boot.

---

## Production (designed — packaging not yet built)

Local dev mirrors the production shape: **per component, each its own deployable** — the
aleap deployment model FirstHomey targets (aleap `docs/architecture/deployment.md`):

| Component | Dev (`bin/dev`) | Prod (designed) |
|---|---|---|
| Engine | `rebar3 shell` | relx release `bin/fh_engine` in a Docker container (DO App) |
| Shell backend | `rebar3 shell` | relx release `bin/fh_shell` in a Docker container (DO App) |
| Frontend | `npm run dev` (vite) | `npm run build` → `adapter-static` SPA on Cloudflare Pages |

Both Erlang halves already build as relx releases (`fh_engine`/`fh_shell`,
`extended_start_script`) and self-bootstrap their schema on boot (idempotent migration
replay), and the frontend is already `adapter-static`. The **two databases live on one
managed cluster** (different db segment), HTTP-only between apps, never a cross-DB join.

**Not yet built:** the DO packaging layer — per-component `Dockerfile` + `app.yaml`, the
out-of-band PG-cluster provisioning, the secret matrix (secrets in the dashboard, config in
`app.yaml`), DNS/domains, and the Cloudflare Pages wiring. The full as-designed prod
topology + runbook (the gaps table is the build checklist) lives in
[`architecture/deployment.md`](architecture/deployment.md). One divergence carried over:
FH's tenant seam is **ed25519** (`SHELL_TENANT_ID`/`SHELL_TENANT_PRIVKEY`, public key
registered with the engine), not aleap's shared-secret `TENANT_SLUG`/`TENANT_SIGNING_KEY`.
