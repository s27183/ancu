# Deployment — production topology & runbook

> **Audience:** whoever stands FirstHomey up or debugs a live deploy.
> **Scope:** the *as-designed* production topology, boot sequence, the env/secret
> matrix, the first-time deploy order, and the post-deploy smoke.
> **Status: PACKAGING BUILT (8-S deploy-build, June 2026) — out-of-band deploy steps
> remain.** The *packaging layer* now exists and is verified locally: `engine/Dockerfile`
> + `shell/web/Dockerfile` (both **build and boot** to their fail-closed DB gates — the
> engine compiles the KB artifact in-build, installs the native `claude` CLI + Python
> Agent-SDK deps; the shell runtime is `debian:trixie-slim` to match the builder glibc),
> `engine/app.yaml` + `shell/web/app.yaml` (DO App specs), and the Cloudflare Pages
> **Function** proxy (`shell/web/frontend/functions/api/[[path]].js` + `health.js`) for
> the relative-`/api/*` same-origin SPA. What remains is everything that needs your DO
> account + the real apex: the out-of-band `doctl databases create`, the secret values,
> DNS/DKIM, the tenant-pubkey `psql` insert, and the Cloudflare Pages env vars (§4 — all
> **billable / your-go**). The §6 table marks what is built vs still-open.
>
> Modeled on aleap's `docs/architecture/deployment.md`, **reshaped to FirstHomey's
> actual (simpler) topology** — see [§0 How FH differs from aleap](#0-how-fh-differs-from-aleap).
> Config sources of truth will be `engine/app.yaml`, `shell/web/app.yaml`,
> `shell/web/frontend/svelte.config.js`. When this doc and an app spec disagree, the
> app spec is right (or this doc is stale — fix it).

**Decisions locked for this spec** (see the slice's AskUserQuestion): region **`sgp1`**
(co-locate with existing bigsmallai infra; planning isn't latency-critical and it's
closest to future VN-located Mode-B/D users), frontend on **Cloudflare Pages**, a
**dedicated apex — `ancu.ai`** (registered 2026-07-06; the earlier `firsthomey.com.au`
placeholder is superseded). GitHub source: **`s27183/ancu`**.

---

## 0. How FH differs from aleap

aleap is the template; FirstHomey is a strict subset of its moving parts plus one
auth divergence. Carry over the *shape*, not these specifics:

| Concern | aleap | FirstHomey |
|---|---|---|
| Engine background work | long-running **job worker** (`engine_jobs`, claim→dispatch loop, `ALEAP_WORKER_COUNT`) | **none** — turns are ephemeral `gen_statem` (sup tree = `pubsub` + `turn_sup` + `http`); the Python sidecar is **stateless, spawned per-turn** via a `{packet,4}` port and exits |
| Object storage | DO Spaces (curator uploads + vendor PDF mirror) | **none in Wedge 1a** — Tìm Nhà curator flow deferred; user-URL-paste is synchronous, no bytes stored |
| Databases | `aleap_engine` + `aleap_shell` + **`lawdb`** | `ancu_engine` + `ancu_shell` — **two**, no `lawdb` |
| KB / corpus | `lawdb` vendor corpus | **compiled KB artifact** `priv/kb/artifact.json` baked into the engine image (git is SOT; rebuildable projection — constraint #6); fail-closed at boot |
| Engine runtime | Erlang + Python sidecar + worker | Erlang + **Python sidecar venv** (claude-agent-sdk / psycopg / pydantic) spawned per turn |
| Tenant seam | **HS256 shared secret** (`TENANT_SLUG`/`TENANT_SIGNING_KEY`, symmetric, no provisioning) | **ed25519** — shell holds the private key, engine holds the **registered public key** in `tenant_signing_keys`; the pubkey is provisioned **out-of-band** (§4 step 5) |
| `ensure_db_exists` on boot | yes (no-op on DO) | **not present** — FH connects straight to a pre-created DB |

Everything else mirrors aleap: compute split into two DO Apps, one managed PG cluster
with two databases, **HTTP-only** between apps (never a cross-DB JOIN — constraint #11 /
engine-contract §9.2), migrate-on-boot baked into the image, `adapter-static` SPA on
Cloudflare Pages, secrets in the dashboard, `deploy_on_push`.

---

## 1. Topology

| Service | Host | Domain | Spec |
|---|---|---|---|
| Frontend (SvelteKit `adapter-static` SPA) | Cloudflare Pages | `app.ancu.ai` | `shell/web/frontend/svelte.config.js` |
| Engine (Erlang gateway + **per-turn Python sidecar**) | DO App `ancu-engine`, **`basic-s` 1vcpu/2gb**, port 8080 | `engine.ancu.ai` | `engine/app.yaml` |
| Shell backend (Erlang; cowboy + pgo only) | DO App `ancu-shell`, `apps-s-1vcpu-1gb-fixed`, port 8081 | `api.ancu.ai` | `shell/web/app.yaml` |
| Databases `ancu_engine` + `ancu_shell` | DO Managed PG cluster `ancu-pg` (PG 16), **one cluster, two databases** — provisioned **out-of-band** (`doctl databases create`), NOT from an app spec | — | created out-of-band; reached via `ENGINE_DATABASE_URL` / `SHELL_DATABASE_URL` secrets |

**Compute is split, the PG cluster is shared, the databases are not.** Engine and shell
run as two independent DO Apps. The engine is the heavier one — it carries the **Python
Agent-SDK subprocess** spawned per turn (and whatever that SDK needs at runtime), so it
gets **2 GB**; the shell is cowboy + pgo only at **1 GB**. They talk **HTTP only**
(shell → engine's `/api/engine/*`, authenticated by the tenant JWT) — never a
cross-database JOIN.

The two databases live on one managed cluster (same host:port, same `doadmin` creds;
only the database segment of the URL differs); splittable into two clusters later
without either app knowing.

Everything sits in Singapore — the **DO App** region slug is **`sgp`**, the **managed PG
cluster** region is **`sgp1`** (as in aleap's specs) — co-located with the existing
bigsmallai stack; planning is not latency-critical, and it is the closest DO region to
the future VN-located Mode-B/D users.

> **The engine is internet-reachable but tenant-JWT-gated.** Only the shell (and later
> the curator console) calls it, server-side; the browser never hits the engine
> directly (the suburb map is proxied **through the shell** — `fh_shell_h_suburbs`).
> Public exposure is acceptable because every `/api/engine/*` call is verified against
> a registered tenant public key. The **dev-only** `POST /api/engine/dev/tenants`
> endpoint MUST stay closed in prod (`ENGINE_DEV_PROVISION` unset → it 404s).

---

## 2. Boot sequence (both Erlang apps, on container start)

Order is load-bearing and **fail-closed** (each step raises → boot aborts rather than
serving a half-initialised runtime). FH does **not** self-create its database — the DB
is pre-created out-of-band (§4), and the pool connects straight to it.

**Engine** (`fh_engine_app:start/2`):
1. `load_dotenv/0` — reads OS env (the root `.env` path resolution is a dev affordance;
   in prod all config arrives as container env vars, which win).
2. `fh_engine_db:start_pool/0` — **fatal** if `ENGINE_DATABASE_URL` is unset.
3. `fh_engine_migrations:run/0` — idempotent forward replay against `ancu_engine`,
   gated by the tracking table. **A migration failure is fatal.**
4. `fh_engine_kb:load/0` — loads the compiled **KB artifact** (`priv/kb/artifact.json`)
   into `persistent_term`. **An unreadable/absent artifact is fatal** (every planning
   turn depends on it).
5. `fh_engine_sup:start_link/0` — `pubsub` → `turn_sup` → `http` (listener last). **No
   job worker.** `ENGINE_DEV_PROVISION` MUST be unset in prod.

**Shell** (`fh_shell_app:start/2`):
1. `load_dotenv/0`.
2. `fh_shell_db:start_pool/0` — **fatal** if `SHELL_DATABASE_URL` is unset.
3. `fh_shell_migrations:run/0` — idempotent forward replay against `ancu_shell`.
   **Fatal on failure.**
4. `fh_shell_provision:maybe_autoprovision/0` — **a no-op in prod**: with
   `SHELL_DEV_AUTOPROVISION` unset and a static `SHELL_TENANT_PRIVKEY` set, it returns
   `ok` without minting or POSTing anything (the prod tenant key is provisioned
   out-of-band — §4 step 5).
5. `fh_shell_sup:start_link/0`.

**Baked into the engine image at build time** (`COPY` into the release's `priv/`):
- `priv/migrations/*.sql` — the schema.
- `priv/kb/artifact.json` — **recommended: compile it during the Docker build** from
  `docs/kb/**` + `docs/blueprints/**` via `engine/build/kb_compiler.py`, so the artifact
  always matches the deployed commit (git is SOT; the artifact is a rebuildable
  projection — constraint #6). This requires `docs/` + Python in the engine build
  context. (Fallback: `COPY` the committed `artifact.json` and ensure it's on `main`.)

The shell image bakes `priv/migrations/*.sql` and the **built frontend is NOT in the
shell image** — it ships to Cloudflare Pages (§4 step 6).

> **`FH_DEPLOY_COMMIT_SHA`** must be injected (build arg → env) on the engine; each
> filled plan card records it for the regulated audit trail (constraint #6). DO does not
> auto-inject the git SHA — set it from the build.

---

## 3. Environment & secrets matrix

Non-secret config is committed in the app specs; **secrets are set in the DO Dashboard**
(`App → Settings → Environment Variables`), **never** in git. Frontend env is set in the
Cloudflare Pages dashboard.

### Engine (`ancu-engine`) — `engine/app.yaml`

| Var | Kind | Value / note |
|---|---|---|
| `FH_ENGINE_HTTP_PORT` | config | `8080` |
| `FH_PLANNER_SCRIPT` | config | path to the real `planner.py` (NOT the stub default) |
| `FH_SIDECAR_PYTHON` | config | path to the bundled venv's `python` (the SDK deps) |
| `FH_DEPLOY_COMMIT_SHA` | config | audit trail (constraint #6). DO does **not** auto-inject the git SHA; the Dockerfile defaults it to `"unknown"`. For a real SHA, build via CI with `--build-arg FH_DEPLOY_COMMIT_SHA=$(git rev-parse HEAD)` — plain `deploy_on_push` builds stay `"unknown"`. |
| `ENGINE_DATABASE_URL` | **secret** | full `doadmin` string, db `ancu_engine`, `?sslmode=require`. Not DO-injected (App Platform won't provision the cluster from-spec). Derive from the out-of-band cluster (§4). |
| `CLAUDE_CODE_OAUTH_TOKEN` | **secret** | Anthropic Max subscription credit for the Agent-SDK planner (the prod runner; see billing.md). |
| `ANTHROPIC_API_KEY` | **secret** *(optional)* | only if a cash-billed fallback / shadow-costing path is enabled. |
| `ENGINE_DEV_PROVISION` | — | **MUST be unset** (dev-only tenant registration endpoint). |

> **No `ERLANG_COOKIE`.** FH's relx releases have no `config/vm.args.src`, so they run
> **non-distributed** (single-node DO App, no epmd, no remote console) — there is no
> cookie to set. (aleap templates a cookie into `vm.args.src`; FH doesn't, so the spec
> omits it. Add a `vm.args.src` + this secret only if remote-console/distribution is
> later wanted.)

Tenant **public** keys are NOT env vars — they live in the engine DB
(`tenant_signing_keys`), provisioned out-of-band (§4 step 5). The engine needs **no
CORS** (no browser calls it directly).

### Shell backend (`ancu-shell`) — `shell/web/app.yaml`

| Var | Kind | Value / note |
|---|---|---|
| `FH_SHELL_HTTP_PORT` | config | `8081` |
| `ENGINE_BASE_URL` | config | `https://engine.ancu.ai` (pre-DNS: the engine's `*.ondigitalocean.app` ingress) |
| `APP_BASE_URL` | config | `https://app.ancu.ai` — base for the magic-link + Google redirect URIs |
| `COOKIE_SECURE` | config | `1` (prod) — `fh_session` gets `Secure` |
| `EMAIL_FROM` / `EMAIL_FROM_NAME` | config | magic-link sender, e.g. `no-reply@ancu.ai` / `FirstHomey` |
| `STRIPE_API_BASE` | config | `https://api.stripe.com` (live default; explicit for clarity — never set the test stub in prod). |
| `ADDON_AMOUNT_DOC_REVIEW` | config | doc_review add-on price in cents (`4000` = $40). Optional; code defaults to 4000 (8-S5f). |
| `ADMIN_EMAILS` | config | comma-separated admin allowlist (charge-exempt, still metered — 8-S5e). Emails aren't secret but leave empty in-repo; set the real list in the Dashboard. |
| `SHELL_DATABASE_URL` | **secret** | `ancu_shell` DB on the shared cluster, `?sslmode=require`. Set manually post-cluster (DO doesn't cross-inject DB refs across apps). |
| `SHELL_JWT_SECRET` | **secret** | user-JWT HMAC (`openssl rand -hex 32`) |
| `SHELL_TENANT_ID` / `SHELL_TENANT_PRIVKEY` | **secret** | the ed25519 tenant identity — `SHELL_TENANT_PRIVKEY` is base64 of the private key; its **public** half is registered with the engine (§4 step 5). |
| `RESEND_API_KEY` | **secret** | `re_…` — set → magic-link emails via Resend; unset → link logged. |
| `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET` | **secret** | OAuth; redirect URI `https://app.ancu.ai/api/auth/google/callback`. |
| `STRIPE_SECRET_KEY` | **secret** | Stripe API key (8-S5e/8-S5f) — checkout create + webhook. |
| `STRIPE_WEBHOOK_SECRET` | **secret** | `whsec_…` — raw-body HMAC verification of Stripe webhooks. |
| `STRIPE_PRICE_PLUS` / `STRIPE_PRICE_PRO` | **secret** | recurring Price ids → tier reverse-map (8-S5e). |
| `SHELL_DEV_AUTOPROVISION` | — | **MUST be unset** (else the shell would mint an ephemeral key instead of using the static one). |
| `AUTH_DEV_EXPOSE_LINK` / `GOOGLE_TOKEN_URL` | — | **MUST be unset** (dev-only magic-link echo / Google-token stub override). |

> **No `ERLANG_COOKIE`** (same reason as the engine — non-distributed release, no
> `vm.args.src`). Stripe vars are shell-only — the engine never touches money (it
> meters; the shell gates). `STRIPE_PRICE_*` carry no secret value but are kept as
> SECRETs to avoid committing account-specific ids.

### Frontend (Cloudflare Pages) — dashboard

| Var | Kind | Value |
|---|---|---|
| `NODE_VERSION` | build | `20` |
| `VITE_PMTILES_URL` | **build** | Protomaps pmtiles basemap URL (8-S2d). Vite inlines `import.meta.env.VITE_*` at **build** time, so this is a Pages **build** env var. Unset → the `minimalStyle` fallback (no basemap, no regression). Prod target: the R2 pmtiles extract. |
| `SHELL_ORIGIN` | **runtime** | the shell backend origin the Pages **Function** proxies to (e.g. `https://api.ancu.ai`, or the shell `*.ondigitalocean.app` ingress pre-DNS). Read by `functions/api/[[path]].js` + `functions/health.js` at request time — a Pages **runtime** env var, NOT a `VITE_` build var. Unset → the proxy 503s. |

The frontend calls **relative `/api/*`** (no API-base env), so the browser sees **one
origin** (`app.ancu.ai`). Cloudflare Pages **cannot** proxy `/api/*` to an external origin
via `_redirects` (CF: *"Proxying will only support relative URLs on your site. You cannot
proxy external domains"*; 200-rewrites are unsupported), so the proxy is a **Pages
Function** — `shell/web/frontend/functions/api/[[path]].js` (catch-all) + `functions/health.js`
forward to `SHELL_ORIGIN`, relaying Set-Cookie and streaming SSE. Functions are invoked
**before** `_redirects`, so the `/* → /index.html 200` SPA fallback never intercepts
`/api/*` or `/health`. This keeps the host-only, `SameSite=Lax` session cookie and the
no-CORS backend working unchanged.

---

## 4. First-time deploy order

The cluster + databases are provisioned **out-of-band** first, then both apps connect to
already-existing databases. All `doctl … create` steps are **billable + your-go gates**.

> **Prerequisite — tracked build inputs.** The Dockerfiles will `COPY` lockfiles, `priv/`
> dirs, and (for the engine) `docs/` + the compiler. They **must be present on `main`** or
> the DO build fails at the COPY step. Ensure git tracks: `engine/erlang/rebar.lock`,
> `shell/web/backend/rebar.lock`, `engine/erlang/priv/migrations/*`, the engine's
> `priv/kb/` target dir (a `.gitkeep` if compiling in-build), `docs/kb/**`,
> `docs/blueprints/**`, `engine/build/kb_compiler.py`. Empty dirs need a `.gitkeep`;
> lockfiles must not be `.gitignore`d. (See [[git-tracking-hygiene]].)

1. **Author the packaging** (the missing layer — this slice's code): a `Dockerfile` per
   Erlang app (multi-stage: `rebar3 as prod release` → slim runtime). The **engine
   Dockerfile** is the heavy one. **Start from aleap's deployed `engine/Dockerfile`**
   (same Agent-SDK stack, proven in prod) — a 3-stage build: (1) `erlang:28-slim` →
   `rebar3 as prod release`; (2) `python:3.14-slim` → `uv export --frozen | uv pip
   install --system` the deps (claude-agent-sdk, psycopg, pydantic); (3) slim runtime
   that copies the python libs + the OTP release + the loose `engine/python` sidecar,
   `apt`-installs `libncurses6 libssl3 ca-certificates curl`, and installs the **Claude
   Code CLI as a standalone native binary** (`curl -fsSL https://claude.ai/install.sh |
   bash -s "$CLAUDE_CODE_VERSION"` — pinned, `DISABLE_AUTOUPDATER=1`, installed as the
   app user; **no Node** — the SDK finds `claude` via `shutil.which`). FH reshapes:
   `pyproject.toml`/`uv.lock` are at the **repo root** (not `engine/python/`), the
   sidecar is a **loose script** wired via `FH_PLANNER_SCRIPT`/`FH_SIDECAR_PYTHON` (not
   aleap's `PYTHONPATH` package), and the KB artifact is baked / `kb_compiler.py`-emitted
   — but mind the runtime file-reads (§6). Plus `engine/app.yaml` + `shell/web/app.yaml`
   (build context = repo root; no `databases:` block — App Platform won't provision the
   cluster from-spec). The **shell Dockerfile** is the simpler shape (Erlang release
   only, no Python) — but **its runtime base must match the builder's glibc** (aleap:
   `erlang:28-slim` builder → `debian:trixie-slim` runtime; bookworm is too old →
   `GLIBC_2.38 not found` crash loop). Both `app.yaml`s set a `health_check` on `/health`
   with `initial_delay_seconds: 60` — both apps run migrations (engine also loads the KB
   artifact) before serving, so a short delay avoids a boot-time failure flap.
2. **Cluster (out-of-band).** `doctl databases create ancu-pg --engine pg
   --version 16 --size db-s-1vcpu-1gb --num-nodes 1 --region sgp1`. Wait for `online`.
   DO clusters expose `doadmin` / `defaultdb` / `:25060` / `sslmode=require`.
3. **Databases (out-of-band).** Connect as `doadmin` (to `defaultdb`) and
   `CREATE DATABASE ancu_engine; CREATE DATABASE ancu_shell;` — both must
   pre-exist (FH has no `ensure_db_exists`; §2).
4. **Engine app.** Build `ENGINE_DATABASE_URL` from the cluster string (db segment →
   `ancu_engine`), inject it + the §3 engine secrets into a temp copy of
   `engine/app.yaml`, `doctl apps spec validate` → `doctl apps create --spec`. Boots →
   pool → migrations → KB artifact → sup tree.
   > **Don't fight autodetect.** The DO "Create App from repo" wizard scans the repo root
   > and reports *"No components detected"* (both Dockerfiles live in subdirs, neither at
   > root). Use the **App Spec editor** or `doctl apps create --spec`. Instance-size slugs
   > drift — confirm via `doctl apps tier instance-size list` (engine `basic-s` 2 GB,
   > shell `apps-s-1vcpu-1gb-fixed`).
5. **Register the shell's tenant public key with the engine (out-of-band).** Generate the
   ed25519 keypair once; set `SHELL_TENANT_ID` + base64(`SHELL_TENANT_PRIVKEY`) as shell
   secrets (step 6). Insert the **public** half into the engine DB — a `tenants` row +
   `tenant_signing_keys (tenant_id, public_key, algo='ed25519', status='active')` — via a
   one-off `psql` against `ancu_engine` (the same rows `fh_engine_store:upsert_tenant`
   + `ensure_signing_key` write in dev). This replaces aleap's "matching shared secret"
   step; it is the prod form of the handshake that `SHELL_DEV_AUTOPROVISION` does in dev.
   *(Future nicety: an authenticated admin provisioning endpoint — the carried-over
   8-S0b gap. Until then this manual insert is the procedure.)*
6. **Shell app.** Derive `SHELL_DATABASE_URL` (db segment → `ancu_shell`), inject it
   + the §3 shell secrets (the tenant id/privkey from step 5), validate,
   `doctl apps create --spec`. Boots → `ancu_shell` migrations →
   `maybe_autoprovision` no-ops (static key present). **Before DNS:** override
   `ENGINE_BASE_URL` to the engine's `*.ondigitalocean.app` ingress; revert to
   `engine.ancu.ai` once DNS lands.
7. **Frontend** on Cloudflare Pages — root dir `shell/web/frontend`, build
   `npm install && npm run build`, output `build`. The `/api/*` + `/health` proxy is the
   committed **Pages Function** (`functions/api/[[path]].js` + `functions/health.js`) — it
   is **not** a `_redirects` rule (CF can't proxy external origins via `_redirects`). Set
   the dashboard env vars from the §3 frontend table: `NODE_VERSION` + `VITE_PMTILES_URL`
   (**build**) and `SHELL_ORIGIN` (**runtime**, the shell origin the Function forwards to —
   the shell `*.ondigitalocean.app` ingress pre-DNS, `https://api.ancu.ai` after). This is
   what makes the relative-`/api` SPA + same-origin cookie work without CORS.
8. **Domains / DNS.** Add DNS for `app.ancu.ai` (Cloudflare Pages custom domain),
   `api.ancu.ai`, and `engine.ancu.ai` (the two DO apps' `domains:` blocks). The sender
   domain `ancu.ai` needs
   its **own DKIM/SPF** verified in Resend (a dedicated apex, not the pre-verified
   bigsmallai.com). Register the Google redirect URI `https://app.ancu.ai/api/auth/google/callback`.
   Wait for HTTPS certs.

`deploy_on_push: true` on both DO apps (branch `main`) + Cloudflare's git build mean
**every push to `main` redeploys** — after the one-time setup, deploys are just merges.

---

## 5. Post-deploy smoke

- [ ] `GET https://engine.ancu.ai/health` → 200; `GET https://api.ancu.ai/health` → 200.
- [ ] `https://app.ancu.ai/` loads the SPA; a deep link resolves via the SPA fallback
      (no 404 on refresh).
- [ ] **Magic-link login:** request a link, pull the token from the **shell DO log
      stream** (until Resend's `RESEND_API_KEY` is set), verify, confirm the `fh_session`
      cookie is set on `app.ancu.ai` with `Secure`.
- [ ] **Google login** (if configured): consent → callback → session cookie; an
      already-magic-linked email lands the **same** account (keyed by email).
- [ ] **Map** loads via the shell→engine proxy (`GET /api/engine/suburbs` through the
      shell), proving the tenant JWT verifies engine-side against the registered pubkey.
- [ ] **Create a plan card:** signed-in onboarding → `POST /api/plan-cards` → engine
      **202**; the base turn runs on the **real** planner (not the stub) and
      `component_filled` events stream back.
- [ ] Migration trackers have every expected row (engine + shell).
- [ ] `ENGINE_DEV_PROVISION` is unset → `POST /api/engine/dev/tenants` returns **404**.

---

## 6. Known gaps / not-yet-built (this slice's checklist)

| Gap | State | Action |
|---|---|---|
| **Dockerfiles** (engine + shell) | **BUILT + boot-verified** | `engine/Dockerfile` (4-stage: KB-compile → Erlang release → Python deps → runtime) + `shell/web/Dockerfile` (2-stage, `debian:trixie-slim` runtime). Both `docker build` clean and `foreground`-boot to their fail-closed DB gates locally. |
| **`engine/app.yaml` + `shell/web/app.yaml`** | **WRITTEN** | DO App specs authored; engine `basic-s` (2 GB), shell `apps-s-1vcpu-1gb-fixed`; build context per-service; no `databases:` block. Set `github.repo` (placeholder — FH has no remote yet) + run `doctl apps spec validate` before create. |
| **KB artifact in-image** | **DONE — compiled in Docker build** | engine Dockerfile stage 1 runs `kb_compiler.py` (pure stdlib), bakes `artifact.json` into the release `priv/kb/` (Erlang boot-load) **and** ships it at `/app/engine/erlang/priv/kb/artifact.json` (sidecar). `artifact.json` is gitignored (rebuildable projection — constraint #6); inputs (`docs/`, `engine/build/`) confirmed tracked. |
| **Agent-SDK runtime deps** | **DONE — verified in image** | native `claude` CLI 2.1.167 (`claude.ai/install.sh`, `DISABLE_AUTOUPDATER=1`, **no Node**) on PATH + Python 3.14 + claude-agent-sdk/psycopg/pydantic (all `import`-verified in the built image). Authed by `CLAUDE_CODE_OAUTH_TOKEN`; `_credit_env()` blanks `ANTHROPIC_API_KEY` in the subprocess. |
| **Sidecar reads repo files at runtime** | **resolved this slice → ship-in-image** | the engine image ships `docs/kb/**` + `artifact.json` in their repo-relative layout (`_REPO_ROOT = /app`) alongside `engine/python/planner.py` — verified present in the image. The cleaner "KB+schema on stdin" (truly-stateless sidecar, principle 3) is a **separate engine follow-up**, deliberately NOT folded into this packaging slice (one change at a time). |
| **Cloudflare Pages `/api` proxy** | **BUILT (Pages Function)** | `functions/api/[[path]].js` + `functions/health.js` proxy to `SHELL_ORIGIN` (relaying Set-Cookie + streaming SSE). `_redirects` **cannot** proxy external origins, confirmed vs CF docs; Functions run before `_redirects`. Set `SHELL_ORIGIN`/`VITE_PMTILES_URL`/`NODE_VERSION` in the Pages dashboard (§3). |
| **SSE through the Pages Function** | **watch — verify in prod** | the 8-S4b plan-card SSE stream now rides `/api/*` through the Pages Function. Workers stream `fetch` bodies, but **verify long-lived SSE duration/streaming** against CF Pages Function limits in the post-deploy smoke (§5); if capped, consider a dedicated SSE route. |
| **Prod tenant-pubkey provisioning** | manual `psql` insert (§4 step 5) | works; an authenticated admin endpoint is the future nicety (carried 8-S0b gap). |
| **`FH_DEPLOY_COMMIT_SHA` injection** | image defaults `"unknown"` | DO can't auto-inject the git SHA on `deploy_on_push`; build via CI with `--build-arg` for a real audit SHA (constraint #6). |
| **DNS + custom domains + DKIM/SPF** | none (your-go) | `app.ancu.ai`/`api.ancu.ai`/`engine.ancu.ai` + Resend domain verification for the dedicated apex. |
| **PG connection ceiling** | `db-s-1vcpu-1gb` ≈ 22 non-superuser slots | engine + shell pools consume most; bump cluster size if pools error under load. |
| **VN data residency (Decree 13/2023)** | out of Wedge-1a scope | Wedge 1a is Mode A (AU users); plan VN-side residency from Wedge 2 before onboarding VN-located users (CLAUDE.md). |
| **Stripe / commerce** | **landed (8-S5)** | shell-only secrets (`STRIPE_SECRET_KEY`/`STRIPE_WEBHOOK_SECRET`/`STRIPE_PRICE_*`) now in `shell/web/app.yaml` §3; engine carries none (it meters; the shell gates). |

---

## 7. Rollback

- **Frontend:** Cloudflare Deployments → promote a previous green build (instant), or
  revert the commit on `main`.
- **DO apps:** redeploy a prior `main` commit (DO keeps deployment history), or
  `doctl apps create-deployment` pinned to an earlier image. **Schema is the one-way
  door** — migrations are forward-replayed on boot; a code rollback does not roll back a
  migration. To undo one, apply its reverse by hand and delete the tracker row.

---

## 8. References

- [`engine-contract.md`](./engine-contract.md) — the stable engine↔shell HTTP contract this topology serves (§9.2 two-database rule).
- [`architecture.md`](./architecture.md) — engine/shell split, three-layer model, the compiled KB artifact (constraint #6).
- [`shell-architecture.md`](./shell-architecture.md) — the shell-side companion (identity, the two-JWT seam, the map proxy).
- [`../local-dev.md`](../local-dev.md) — the local mirror of this per-component topology (`bin/dev` per component).
- [`billing.md`](./billing.md) — the metering/commerce model the engine feeds (engine meters, shell gates).
- aleap `docs/architecture/deployment.md` — the runbook template this reshapes.
- aleap `engine/Dockerfile`, `shell/web/Dockerfile`, `engine/app.yaml`, `shell/web/app.yaml` — the **deployed, proven** packaging to lift from for the 8-S deploy-build slice (3-stage engine build + native `claude` binary install; trixie-slim shell runtime; out-of-band PG, no `databases:` block).
