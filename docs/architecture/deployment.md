# Deployment — production topology & runbook

> **Audience:** whoever stands Mai An Cư up or debugs a live deploy.
> **Scope:** the *as-designed* production topology, boot sequence, the env/secret
> matrix, the first-time deploy order, and the post-deploy smoke.
> **Status: PACKAGING BUILT; first deploy is behavior 33 (2026-10-09).** The packaging
> layer exists and is verified locally: `engine/Dockerfile` + `shell/web/Dockerfile` (both
> **build and boot** to their fail-closed DB gates — the engine compiles the KB artifact
> in-build, installs the native `claude` CLI + Python Agent-SDK deps; the shell runtime is
> `debian:trixie-slim` to match the builder glibc), `engine/app.yaml` + `shell/web/app.yaml`
> (DO App specs, each with its own dev database), the Cloudflare Pages **Function** proxy
> (`shell/web/frontend/functions/api/[[path]].js` + `health.js`), and
> `scripts/do_deploy.py`, which fills the specs from `.env` and drives the DO API through
> the `DO_API_KEY` key socket (§4). The §6 table marks what is built vs still-open.
>
> Modeled on aleap's `docs/architecture/deployment.md`, **reshaped to FirstHomey's
> actual (simpler) topology** — see [§0 How FH differs from aleap](#0-how-fh-differs-from-aleap).
> Config sources of truth will be `engine/app.yaml`, `shell/web/app.yaml`,
> `shell/web/frontend/svelte.config.js`. When this doc and an app spec disagree, the
> app spec is right (or this doc is stale — fix it).

**Decisions locked for this spec:** region **`syd`** (Sydney — the site serves Australia;
Son 2026-10-09), frontend on **Cloudflare Pages**, the cheapest setup that runs
(~US$29/mo, below). GitHub source: **`s27183/ancu`**.

**Naming.** The product is **Mai An Cư**; its umbrella domain is **`maiancu.com`**
(Cloudflare zone; bought 2026-10-09). The app is served on the apex **`maiancu.com`**
(Son 2026-10-09: "i meant maiancu.com" — not a per-market subdomain), its API on
**`api.maiancu.com`**; `www` is not served yet. Mail is sent from
`no-reply@maiancu.com` (verified in Resend). The earlier `ancu.ai` apex (and before it
`firsthomey.com.au`) was never bought and is superseded; the DO apps keep the internal
names `ancu-engine` / `ancu-shell`.

---

## 0. How FH differs from aleap

aleap is the template; FirstHomey is a strict subset of its moving parts plus one
auth divergence. Carry over the *shape*, not these specifics:

| Concern | aleap | FirstHomey |
|---|---|---|
| Engine background work | long-running **job worker** (`engine_jobs`, claim→dispatch loop, `ALEAP_WORKER_COUNT`) | **none** — turns are ephemeral `gen_statem` (sup tree = `pubsub` + `turn_sup` + `http`); the Python sidecar is **stateless, spawned per-turn** via a `{packet,4}` port and exits |
| Object storage | DO Spaces (curator uploads + vendor PDF mirror) | **none in Wedge 1a** — Tìm Nhà curator flow deferred; user-URL-paste is synchronous, no bytes stored |
| Databases | `aleap_engine` + `aleap_shell` + **`lawdb`** | **two** App Platform dev databases, one per app — no `lawdb`, no shared cluster |
| KB / corpus | `lawdb` vendor corpus | **compiled KB artifact** `priv/kb/artifact.json` baked into the engine image (git is SOT; rebuildable projection — constraint #6); fail-closed at boot |
| Engine runtime | Erlang + Python sidecar + worker | Erlang + **Python sidecar venv** (claude-agent-sdk / psycopg / pydantic) spawned per turn |
| Tenant seam | **HS256 shared secret** (`TENANT_SLUG`/`TENANT_SIGNING_KEY`, symmetric, no provisioning) | **ed25519** — shell holds the private key, engine holds the **registered public key** in `tenant_signing_keys`; the engine registers the pubkey **at its own boot** from `SHELL_TENANT_PUBKEY` (§2) |
| `ensure_db_exists` on boot | yes (no-op on DO) | **not present** — each app connects straight to the dev database App Platform made for it |

Everything else mirrors aleap: compute split into two DO Apps, two databases,
**HTTP-only** between apps (never a cross-DB JOIN — constraint #11 /
engine-contract §9.2), migrate-on-boot baked into the image, `adapter-static` SPA on
Cloudflare Pages, secrets filled from `.env` by `scripts/do_deploy.py`, `deploy_on_push`.

---

## 1. Topology

| Service | Host | Domain | Spec |
|---|---|---|---|
| Frontend (SvelteKit `adapter-static` SPA) | Cloudflare Pages project `maiancu` | `maiancu.com` | `shell/web/frontend/svelte.config.js` |
| Engine (Erlang gateway + **per-turn Python sidecar**) | DO App `ancu-engine`, `apps-s-1vcpu-1gb-fixed` (US$10), port 8080 | its `*.ondigitalocean.app` ingress only | `engine/app.yaml` |
| Shell backend (Erlang; cowboy + pgo only) | DO App `ancu-shell`, `apps-s-1vcpu-0.5gb` (US$5), port 8081 | `api.maiancu.com` | `shell/web/app.yaml` |
| Databases | one App Platform **dev database** per app (PG 16, US$7 each), declared in the spec's `databases:` and bound as `${db.DATABASE_URL}` | — | the two app specs |

**Compute is split and so are the databases.** Engine and shell run as two independent
DO Apps. The engine is the heavier one — it carries the **Python Agent-SDK subprocess**
spawned per turn; the shell is cowboy + pgo only. They talk **HTTP only** (shell →
engine's `/api/engine/*`, authenticated by the tenant JWT) — never a cross-database JOIN.

**Dev databases** (Son 2026-10-09, "can we use a dev db (not a managed one)"): one
database each, reachable **from its own app only** (no psql from outside), no backups by
default, **destroyed with its app**. Fine while there is no user data; when real users
arrive, DO's "Convert to a Managed Database" upgrades each in place. Because nothing
outside the engine can reach its database, the shell's tenant public key reaches the
engine as an env value and the engine registers it at boot (§2).

**Sizing is the cheapest that runs and is unmeasured under load:** the 1 GB engine has
not been measured under a turn (the sandbox refused a memory measure). An OOM in the run
log (`do_deploy.py logs engine`) means `apps-s-1vcpu-2gb` (US$25); the shell likewise
steps up from 512 MB. Total today ≈ US$10 + 5 + 7 + 7 = **US$29/mo**.

Everything sits in Sydney (`syd`) — the site serves Australian property buyers.

> **The engine is internet-reachable but tenant-JWT-gated.** Only the shell (and later
> the curator console) calls it, server-side; the browser never hits the engine
> directly (the suburb map is proxied **through the shell** — `fh_shell_h_suburbs`).
> Public exposure is acceptable because every `/api/engine/*` call is verified against
> a registered tenant public key. The **dev-only** `POST /api/engine/dev/tenants`
> endpoint MUST stay closed in prod (`ENGINE_DEV_PROVISION` unset → it 404s).

---

## 2. Boot sequence (both Erlang apps, on container start)

Order is load-bearing and **fail-closed** (each step raises → boot aborts rather than
serving a half-initialised runtime). FH does **not** self-create its database — App Platform
creates each app's dev database with the app (§1), and the pool connects straight to it.

**Engine** (`fh_engine_app:start/2`):
1. `load_dotenv/0` — reads OS env (the root `.env` path resolution is a dev affordance;
   in prod all config arrives as container env vars, which win).
2. `fh_engine_db:start_pool/0` — **fatal** if `ENGINE_DATABASE_URL` is unset.
3. `fh_engine_migrations:run/0` — idempotent forward replay against `ancu_engine`,
   gated by the tracking table. **A migration failure is fatal.**
   Then `seed_shell_tenant/0` — with `SHELL_TENANT_ID` + `SHELL_TENANT_PUBKEY` set
   (prod), registers the shell tenant and its ed25519 public key, idempotently; a
   half-set or malformed seed is **fatal**; neither set (dev) is a no-op.
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
   `ok` without minting or POSTing anything (the engine registered the matching public
   key at its own boot).
5. `fh_shell_sup:start_link/0`.

**Baked into the engine image at build time** (`COPY` into the release's `priv/`):
- `priv/migrations/*.sql` — the schema.
- `priv/kb/artifact.json` — **recommended: compile it during the Docker build** from
  `docs/kb/**` + `docs/blueprints/**` via `engine/build/kb_compiler.py`, so the artifact
  always matches the deployed commit (git is SOT; the artifact is a rebuildable
  projection — constraint #6). This requires `docs/` + Python in the engine build
  context. (Fallback: `COPY` the committed `artifact.json` and ensure it's on `main`.)

The shell image bakes `priv/migrations/*.sql` and the **built frontend is NOT in the
shell image** — it ships to Cloudflare Pages (§4).

> **`FH_DEPLOY_COMMIT_SHA`** must be injected (build arg → env) on the engine; each
> filled plan card records it for the regulated audit trail (constraint #6). DO does not
> auto-inject the git SHA — set it from the build.

---

## 3. Environment & secrets matrix

Non-secret config is committed in the app specs; **secrets are filled from the repo-root
`.env` by `scripts/do_deploy.py apply`** into the spec it sends to the DO API (never git,
never the screen). Frontend env is set on the Pages project through the Cloudflare API.

### Credentials — every key, its scope, where it is held

| Key | Scope | Held in | Used by |
|---|---|---|---|
| `DO_API_KEY` | DigitalOcean API token (Son's DO account for Mai An Cư), read+write | Son's `.env`; served to the seat by `/bounds key DO_API_KEY@api.digitalocean.com` (the value never reaches it) | `scripts/do_deploy.py` — every DO call |
| `CLOUDFLARE_API_TOKEN` | Cloudflare token: zone `maiancu.com` DNS edit + the account's Pages edit | Son's `.env`; `/bounds key CLOUDFLARE_API_TOKEN@api.cloudflare.com` | DNS records + the Pages project's env and custom domain |
| `RESEND_API_KEY` | Resend, sending from the verified `maiancu.com` | `.env` → the shell's SECRET env | magic-link email (`fh_shell_mail`) |
| `CLAUDE_CODE_OAUTH_TOKEN` | Anthropic Max subscription credit | `.env` → the engine's SECRET env | the planner sidecar |
| `SHELL_JWT_SECRET` | user-session HMAC | `.env` → shell SECRET | `fh_shell_jwt` |
| `SHELL_TENANT_ID` / `SHELL_TENANT_PRIVKEY` | the shell's ed25519 tenant identity | `.env` → shell SECRET; the **public** half (derived by `do_deploy.py`) → engine plain env `SHELL_TENANT_PUBKEY` | tenant JWTs, shell → engine |
| `GOOGLE_*`, `STRIPE_*`, `ANTHROPIC_API_KEY` | optional | `.env` when set → SECRET env; dropped from the spec when absent | Google sign-in, commerce, a cash-billed fallback |
| the databases' credentials | each app's dev database | App Platform only (`${db.DATABASE_URL}`) | the app it belongs to — nobody else can connect |



### Engine (`ancu-engine`) — `engine/app.yaml`

| Var | Kind | Value / note |
|---|---|---|
| `FH_ENGINE_HTTP_PORT` | config | `8080` |
| `FH_PLANNER_SCRIPT` | config | path to the real `planner.py` (NOT the stub default) |
| `FH_SIDECAR_PYTHON` | config | path to the bundled venv's `python` (the SDK deps) |
| `FH_DEPLOY_COMMIT_SHA` | config | audit trail (constraint #6). DO does **not** auto-inject the git SHA; the Dockerfile defaults it to `"unknown"`. For a real SHA, build via CI with `--build-arg FH_DEPLOY_COMMIT_SHA=$(git rev-parse HEAD)` — plain `deploy_on_push` builds stay `"unknown"`. |
| `ENGINE_DATABASE_URL` | bound | `${db.DATABASE_URL}` — the engine's dev database (`?sslmode=require`), bound by App Platform at run time. |
| `SHELL_TENANT_ID` / `SHELL_TENANT_PUBKEY` | config (filled) | the shell's tenant id and ed25519 **public** key; `do_deploy.py` fills both from `.env`; the engine registers them at boot (§2). |
| `CLAUDE_CODE_OAUTH_TOKEN` | **secret** | Anthropic Max subscription credit for the Agent-SDK planner (the prod runner; see billing.md). |
| `ANTHROPIC_API_KEY` | **secret** *(optional)* | only if a cash-billed fallback / shadow-costing path is enabled. |
| `ENGINE_DEV_PROVISION` | — | **MUST be unset** (dev-only tenant registration endpoint). |

> **No `ERLANG_COOKIE`.** FH's relx releases have no `config/vm.args.src`, so they run
> **non-distributed** (single-node DO App, no epmd, no remote console) — there is no
> cookie to set. (aleap templates a cookie into `vm.args.src`; FH doesn't, so the spec
> omits it. Add a `vm.args.src` + this secret only if remote-console/distribution is
> later wanted.)

Tenant public keys live in the engine DB (`tenant_signing_keys`); the shell's arrives as
`SHELL_TENANT_PUBKEY` and is written there at boot. The engine needs **no CORS** (no
browser calls it directly).

### Shell backend (`ancu-shell`) — `shell/web/app.yaml`

| Var | Kind | Value / note |
|---|---|---|
| `FH_SHELL_HTTP_PORT` | config | `8081` |
| `ENGINE_BASE_URL` | config (filled) | the engine's `*.ondigitalocean.app` ingress — `do_deploy.py` reads it from the live `ancu-engine` |
| `APP_BASE_URL` | config | `https://maiancu.com` — base for the magic-link + Google redirect URIs |
| `COOKIE_SECURE` | config | `1` (prod) — `fh_session` gets `Secure` |
| `EMAIL_FROM` / `EMAIL_FROM_NAME` | config | magic-link sender `no-reply@maiancu.com`; the display name is the brand (`fh_shell_util:brand/0`) unless `EMAIL_FROM_NAME` overrides it — leave it unset |
| `STRIPE_API_BASE` | config | `https://api.stripe.com` (live default; explicit for clarity — never set the test stub in prod). |
| `ADDON_AMOUNT_DOC_REVIEW` | config | doc_review add-on price in cents (`4000` = $40). Optional; code defaults to 4000 (8-S5f). |
| `ADMIN_EMAILS` | config | comma-separated admin allowlist (charge-exempt, still metered — 8-S5e). Emails aren't secret but stay out of git: `do_deploy.py` fills it from `.env`. |
| `SHELL_DATABASE_URL` | bound | `${db.DATABASE_URL}` — the shell's own dev database. |
| `SHELL_JWT_SECRET` | **secret** | user-JWT HMAC (`openssl rand -hex 32`) |
| `SHELL_TENANT_ID` / `SHELL_TENANT_PRIVKEY` | **secret** | the ed25519 tenant identity — `SHELL_TENANT_PRIVKEY` is base64 of the private key; its **public** half reaches the engine as `SHELL_TENANT_PUBKEY` (§2). |
| `RESEND_API_KEY` | **secret** | `re_…` — set → magic-link emails via Resend; unset → link logged. |
| `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET` | **secret** | OAuth; redirect URI `https://maiancu.com/api/auth/google/callback`. |
| `STRIPE_SECRET_KEY` | **secret** | Stripe API key (8-S5e/8-S5f) — checkout create + webhook. |
| `STRIPE_WEBHOOK_SECRET` | **secret** | `whsec_…` — raw-body HMAC verification of Stripe webhooks. |
| `STRIPE_PRICE_PLUS` / `STRIPE_PRICE_PRO` | **secret** | recurring Price ids → tier reverse-map (8-S5e). |
| `SHELL_DEV_AUTOPROVISION` | — | **MUST be unset** (else the shell would mint an ephemeral key instead of using the static one). |
| `AUTH_DEV_EXPOSE_LINK` / `GOOGLE_TOKEN_URL` | — | **MUST be unset** (dev-only magic-link echo / Google-token stub override). |

> **No `ERLANG_COOKIE`** (same reason as the engine — non-distributed release, no
> `vm.args.src`). Stripe vars are shell-only — the engine never touches money (it
> meters; the shell gates). `STRIPE_PRICE_*` carry no secret value but are kept as
> SECRETs to avoid committing account-specific ids.

### Frontend (Cloudflare Pages project `maiancu`) — set by API

| Var | Kind | Value |
|---|---|---|
| `NODE_VERSION` | build | `20` |
| `VITE_PMTILES_URL` | **build** | Protomaps pmtiles basemap URL (8-S2d). Vite inlines `import.meta.env.VITE_*` at **build** time, so this is a Pages **build** env var. Unset → the `minimalStyle` fallback (no basemap, no regression). Prod target: the R2 pmtiles extract. |
| `SHELL_ORIGIN` | **runtime** | the shell backend origin the Pages **Function** proxies to (`https://api.maiancu.com`). Read by `functions/api/[[path]].js` + `functions/health.js` at request time — a Pages **runtime** env var, NOT a `VITE_` build var. Unset → the proxy 503s. |

The frontend calls **relative `/api/*`** (no API-base env), so the browser sees **one
origin** (`maiancu.com`). Cloudflare Pages **cannot** proxy `/api/*` to an external origin
via `_redirects` (CF: *"Proxying will only support relative URLs on your site. You cannot
proxy external domains"*; 200-rewrites are unsupported), so the proxy is a **Pages
Function** — `shell/web/frontend/functions/api/[[path]].js` (catch-all) + `functions/health.js`
forward to `SHELL_ORIGIN`, relaying Set-Cookie and streaming SSE. Functions are invoked
**before** `_redirects`, so the `/* → /index.html 200` SPA fallback never intercepts
`/api/*` or `/health`. This keeps the host-only, `SameSite=Lax` session cookie and the
no-CORS backend working unchanged.

---

## 4. First-time deploy order

Billable steps are behavior 33's Irreversible list; each is checked first (no app yet,
no record yet).

> **Prerequisite — tracked build inputs.** The Dockerfiles `COPY` lockfiles, `priv/`
> dirs, and (for the engine) `docs/` + the compiler. They **must be present on `main`** or
> the DO build fails at the COPY step: `engine/erlang/rebar.lock`,
> `shell/web/backend/rebar.lock`, `engine/erlang/priv/migrations/*`, the engine's
> `priv/kb/` target dir, `docs/kb/**`, `docs/blueprints/**`, `engine/build/kb_compiler.py`.

1. **Check the specs (read-only, no `.env`).** `python3 scripts/do_deploy.py propose
   engine` and `… propose shell` — DO validates each spec and prices it
   (`POST /v2/apps/propose`); nothing is created.
2. **GitHub access.** Son authorizes DigitalOcean's GitHub app for `s27183/ancu` (the
   apps build from `main`) and creates the Pages project `maiancu` connected to the repo
   (root `shell/web/frontend`, build `npm install && npm run build`, output `build`,
   branch `main`). Both are account-owner steps a token cannot do.
3. **Engine app.** `bash scripts/do_apply.sh engine` (outside the sandbox: it reads
   `.env`) — fills the secrets and `SHELL_TENANT_ID` / `SHELL_TENANT_PUBKEY` (the public
   key derived from `SHELL_TENANT_PRIVKEY`), validates, creates `ancu-engine` with its dev
   database. Boots → pool → migrations → tenant seed → KB artifact → sup tree.
4. **Shell app.** `bash scripts/do_apply.sh shell` — once the engine is live, its ingress
   becomes the shell's `ENGINE_BASE_URL`. Boots → migrations → `maybe_autoprovision`
   no-ops (static key present).
5. **DNS.** In the `maiancu.com` zone: `api` → a **DNS-only** CNAME to the shell's
   `*.ondigitalocean.app` ingress (DO issues the certificate for the `domains:` entry).
6. **Frontend.** On the Pages project, by API: `SHELL_ORIGIN=https://api.maiancu.com`
   (runtime), `NODE_VERSION`, `VITE_PMTILES_URL` (build), and the custom domain
   `maiancu.com`; then redeploy so the build picks up the build vars.
7. **Mail.** `maiancu.com` is verified in Resend (DKIM/SPF records in the zone:
   `resend._domainkey`, `send`); `EMAIL_FROM=no-reply@maiancu.com`. Register the Google
   redirect URI `https://maiancu.com/api/auth/google/callback` when Google sign-in is
   turned on.

Status at any time: `python3 scripts/do_deploy.py status`; a deployment's log:
`python3 scripts/do_deploy.py logs engine|shell [run|build|deploy]`.

`deploy_on_push: true` on both DO apps (branch `main`) + Cloudflare's git build mean
**every push to `main` redeploys** — after the one-time setup, deploys are just merges.
PRs therefore target `main` directly, one branch per behavior cut from `main`: merging a
PR is the deploy (Son 2026-10-09, retiring the `dev-son` integration branch). The gate
before a merge is the done checks run on the branch; there is no CI.

---

## 5. Post-deploy smoke

- [ ] `GET https://<ancu-engine ingress>/health` → 200; `GET https://api.maiancu.com/health` → 200.
- [ ] `https://maiancu.com/` loads the SPA; a deep link resolves via the SPA fallback
      (no 404 on refresh).
- [ ] **Magic-link login:** request a link at `maiancu.com`; the shell log says
      Resend accepted it; the email arrives from `Mai An Cư <no-reply@maiancu.com>`;
      clicking it sets `fh_session` on `maiancu.com` with `Secure`; a second click
      does not sign in.
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
| **`engine/app.yaml` + `shell/web/app.yaml`** | **WRITTEN, proposal-valid** | region `syd`; engine `apps-s-1vcpu-1gb-fixed`, shell `apps-s-1vcpu-0.5gb`; a dev database each; `POST /v2/apps/propose` accepts both (behavior 33). |
| **KB artifact in-image** | **DONE — compiled in Docker build** | engine Dockerfile stage 1 runs `kb_compiler.py` (pure stdlib), bakes `artifact.json` into the release `priv/kb/` (Erlang boot-load) **and** ships it at `/app/engine/erlang/priv/kb/artifact.json` (sidecar). `artifact.json` is gitignored (rebuildable projection — constraint #6); inputs (`docs/`, `engine/build/`) confirmed tracked. |
| **Agent-SDK runtime deps** | **DONE — verified in image** | native `claude` CLI 2.1.167 (`claude.ai/install.sh`, `DISABLE_AUTOUPDATER=1`, **no Node**) on PATH + Python 3.14 + claude-agent-sdk/psycopg/pydantic (all `import`-verified in the built image). Authed by `CLAUDE_CODE_OAUTH_TOKEN`; `_credit_env()` blanks `ANTHROPIC_API_KEY` in the subprocess. |
| **Sidecar reads repo files at runtime** | **resolved this slice → ship-in-image** | the engine image ships `docs/kb/**` + `artifact.json` in their repo-relative layout (`_REPO_ROOT = /app`) alongside `engine/python/planner.py` — verified present in the image. The cleaner "KB+schema on stdin" (truly-stateless sidecar, principle 3) is a **separate engine follow-up**, deliberately NOT folded into this packaging slice (one change at a time). |
| **Cloudflare Pages `/api` proxy** | **BUILT (Pages Function)** | `functions/api/[[path]].js` + `functions/health.js` proxy to `SHELL_ORIGIN` (relaying Set-Cookie + streaming SSE). `_redirects` **cannot** proxy external origins, confirmed vs CF docs; Functions run before `_redirects`. Set `SHELL_ORIGIN`/`VITE_PMTILES_URL`/`NODE_VERSION` in the Pages dashboard (§3). |
| **SSE through the Pages Function** | **watch — verify in prod** | the 8-S4b plan-card SSE stream now rides `/api/*` through the Pages Function. Workers stream `fetch` bodies, but **verify long-lived SSE duration/streaming** against CF Pages Function limits in the post-deploy smoke (§5); if capped, consider a dedicated SSE route. |
| **Prod tenant-pubkey provisioning** | **at engine boot** from `SHELL_TENANT_PUBKEY` | `engine/erlang/test/tenant_seed_smoke.escript`; rotating the key = a new `.env` value + re-apply both apps (the old key stays active until retired by hand). |
| **`FH_DEPLOY_COMMIT_SHA` injection** | image defaults `"unknown"` | DO can't auto-inject the git SHA on `deploy_on_push`; build via CI with `--build-arg` for a real audit SHA (constraint #6). |
| **DNS + custom domains + DKIM/SPF** | Resend verified (`maiancu.com`) | `api` CNAME + the Pages custom domain `maiancu.com` (behavior 33). |
| **Dev databases** | no backups, app-only, destroyed with the app | convert each to a managed database before real user data matters; check its connection limit against the pool size (10) if pools error. |
| **VN data residency (Decree 13/2023)** | out of Wedge-1a scope | Wedge 1a is Mode A (AU users); plan VN-side residency from Wedge 2 before onboarding VN-located users (CLAUDE.md). |
| **Stripe / commerce** | **landed (8-S5)** | shell-only secrets (`STRIPE_SECRET_KEY`/`STRIPE_WEBHOOK_SECRET`/`STRIPE_PRICE_*`) now in `shell/web/app.yaml` §3; engine carries none (it meters; the shell gates). |

---

## 7. Rollback

- **Frontend:** Cloudflare Deployments → promote a previous green build (instant), or
  revert the commit on `main`.
- **DO apps:** redeploy a prior `main` commit (DO keeps deployment history), or
  `POST /v2/apps/<id>/deployments` from an earlier commit. Deleting an app **destroys its
  dev database**. **Schema is the one-way
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
- aleap `engine/Dockerfile`, `shell/web/Dockerfile`, `engine/app.yaml`, `shell/web/app.yaml` — the **deployed, proven** packaging to lift from for the 8-S deploy-build slice (3-stage engine build + native `claude` binary install; trixie-slim shell runtime).
