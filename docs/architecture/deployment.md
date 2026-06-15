# Deployment — production topology & runbook

> **Audience:** whoever stands FirstHomey up or debugs a live deploy.
> **Scope:** the *as-designed* production topology, boot sequence, the env/secret
> matrix, the first-time deploy order, and the post-deploy smoke.
> **Status: DESIGNED — packaging not yet built.** The runtime halves exist and run
> (relx releases, migrate-on-boot, `adapter-static` frontend); what this doc specifies
> and does **not** yet exist is the *packaging layer* — per-component `Dockerfile` +
> `app.yaml`, the managed-PG provisioning, the secret matrix, DNS, and the Cloudflare
> Pages wiring. The §6 gaps table is therefore also the build checklist for this slice.
>
> Modeled on aleap's `docs/architecture/deployment.md`, **reshaped to FirstHomey's
> actual (simpler) topology** — see [§0 How FH differs from aleap](#0-how-fh-differs-from-aleap).
> Config sources of truth will be `engine/app.yaml`, `shell/web/app.yaml`,
> `shell/web/frontend/svelte.config.js`. When this doc and an app spec disagree, the
> app spec is right (or this doc is stale — fix it).

**Decisions locked for this spec** (see the slice's AskUserQuestion): region **`sgp1`**
(co-locate with existing bigsmallai infra; planning isn't latency-critical and it's
closest to future VN-located Mode-B/D users), frontend on **Cloudflare Pages**, a
**dedicated apex**. Throughout, **`<apex>`** is your registered domain — placeholder
**`firsthomey.com.au`**; substitute your real apex everywhere it appears.

---

## 0. How FH differs from aleap

aleap is the template; FirstHomey is a strict subset of its moving parts plus one
auth divergence. Carry over the *shape*, not these specifics:

| Concern | aleap | FirstHomey |
|---|---|---|
| Engine background work | long-running **job worker** (`engine_jobs`, claim→dispatch loop, `ALEAP_WORKER_COUNT`) | **none** — turns are ephemeral `gen_statem` (sup tree = `pubsub` + `turn_sup` + `http`); the Python sidecar is **stateless, spawned per-turn** via a `{packet,4}` port and exits |
| Object storage | DO Spaces (curator uploads + vendor PDF mirror) | **none in Wedge 1a** — Tìm Nhà curator flow deferred; user-URL-paste is synchronous, no bytes stored |
| Databases | `aleap_engine` + `aleap_shell` + **`lawdb`** | `firsthomey_engine` + `firsthomey_shell` — **two**, no `lawdb` |
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
| Frontend (SvelteKit `adapter-static` SPA) | Cloudflare Pages | `app.<apex>` | `shell/web/frontend/svelte.config.js` |
| Engine (Erlang gateway + **per-turn Python sidecar**) | DO App `firsthomey-engine`, **`basic-s` 1vcpu/2gb**, port 8080 | `engine.<apex>` | `engine/app.yaml` *(to author)* |
| Shell backend (Erlang; cowboy + pgo only) | DO App `firsthomey-shell`, `apps-s-1vcpu-1gb-fixed`, port 8081 | `api.<apex>` | `shell/web/app.yaml` *(to author)* |
| Databases `firsthomey_engine` + `firsthomey_shell` | DO Managed PG cluster `firsthomey-pg` (PG 16), **one cluster, two databases** — provisioned **out-of-band** (`doctl databases create`), NOT from an app spec | — | created out-of-band; reached via `ENGINE_DATABASE_URL` / `SHELL_DATABASE_URL` secrets |

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
3. `fh_engine_migrations:run/0` — idempotent forward replay against `firsthomey_engine`,
   gated by the tracking table. **A migration failure is fatal.**
4. `fh_engine_kb:load/0` — loads the compiled **KB artifact** (`priv/kb/artifact.json`)
   into `persistent_term`. **An unreadable/absent artifact is fatal** (every planning
   turn depends on it).
5. `fh_engine_sup:start_link/0` — `pubsub` → `turn_sup` → `http` (listener last). **No
   job worker.** `ENGINE_DEV_PROVISION` MUST be unset in prod.

**Shell** (`fh_shell_app:start/2`):
1. `load_dotenv/0`.
2. `fh_shell_db:start_pool/0` — **fatal** if `SHELL_DATABASE_URL` is unset.
3. `fh_shell_migrations:run/0` — idempotent forward replay against `firsthomey_shell`.
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

### Engine (`firsthomey-engine`) — `engine/app.yaml`

| Var | Kind | Value / note |
|---|---|---|
| `FH_ENGINE_HTTP_PORT` | config | `8080` |
| `FH_PLANNER_SCRIPT` | config | path to the real `planner.py` (NOT the stub default) |
| `FH_SIDECAR_PYTHON` | config | path to the bundled venv's `python` (the SDK deps) |
| `FH_DEPLOY_COMMIT_SHA` | config | injected from the build — audit trail (constraint #6) |
| `ENGINE_DATABASE_URL` | **secret** | full `doadmin` string, db `firsthomey_engine`, `?sslmode=require`. Not DO-injected (App Platform won't provision the cluster from-spec). Derive from the out-of-band cluster (§4). |
| `CLAUDE_CODE_OAUTH_TOKEN` | **secret** | Anthropic Max subscription credit for the Agent-SDK planner (the prod runner; see billing.md). |
| `ANTHROPIC_API_KEY` | **secret** *(optional)* | only if a cash-billed fallback / shadow-costing path is enabled. |
| `ERLANG_COOKIE` | **secret** | distribution cookie |
| `ENGINE_DEV_PROVISION` | — | **MUST be unset** (dev-only tenant registration endpoint). |

Tenant **public** keys are NOT env vars — they live in the engine DB
(`tenant_signing_keys`), provisioned out-of-band (§4 step 5). The engine needs **no
CORS** (no browser calls it directly).

### Shell backend (`firsthomey-shell`) — `shell/web/app.yaml`

| Var | Kind | Value / note |
|---|---|---|
| `FH_SHELL_HTTP_PORT` | config | `8081` |
| `ENGINE_BASE_URL` | config | `https://engine.<apex>` (pre-DNS: the engine's `*.ondigitalocean.app` ingress) |
| `APP_BASE_URL` | config | `https://app.<apex>` — base for the magic-link + Google redirect URIs |
| `COOKIE_SECURE` | config | `1` (prod) — `fh_session` gets `Secure` |
| `EMAIL_FROM` / `EMAIL_FROM_NAME` | config | magic-link sender, e.g. `no-reply@<apex>` / `FirstHomey` |
| `SHELL_DATABASE_URL` | **secret** | `firsthomey_shell` DB on the shared cluster, `?sslmode=require`. Set manually post-cluster (DO doesn't cross-inject DB refs across apps). |
| `SHELL_JWT_SECRET` | **secret** | user-JWT HMAC (`openssl rand -hex 32`) |
| `SHELL_TENANT_ID` / `SHELL_TENANT_PRIVKEY` | **secret** | the ed25519 tenant identity — `SHELL_TENANT_PRIVKEY` is base64 of the private key; its **public** half is registered with the engine (§4 step 5). |
| `RESEND_API_KEY` | **secret** | `re_…` — set → magic-link emails via Resend; unset → link logged. |
| `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET` | **secret** | OAuth; redirect URI `https://app.<apex>/api/auth/google/callback`. |
| `ERLANG_COOKIE` | **secret** | distribution cookie |
| `SHELL_DEV_AUTOPROVISION` | — | **MUST be unset** (else the shell would mint an ephemeral key instead of using the static one). |

### Frontend (Cloudflare Pages) — dashboard

| Var | Value |
|---|---|
| `NODE_VERSION` | `20` |

The frontend calls **relative `/api/*`** (no API-base env). Cloudflare Pages must
**proxy `/api/*` and `/health` to the shell** (`api.<apex>` or the shell ingress) so the
browser sees one origin — see §4 step 6. This keeps the existing host-only,
`SameSite=Lax` session cookie and the no-CORS backend working unchanged.

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
2. **Cluster (out-of-band).** `doctl databases create firsthomey-pg --engine pg
   --version 16 --size db-s-1vcpu-1gb --num-nodes 1 --region sgp1`. Wait for `online`.
   DO clusters expose `doadmin` / `defaultdb` / `:25060` / `sslmode=require`.
3. **Databases (out-of-band).** Connect as `doadmin` (to `defaultdb`) and
   `CREATE DATABASE firsthomey_engine; CREATE DATABASE firsthomey_shell;` — both must
   pre-exist (FH has no `ensure_db_exists`; §2).
4. **Engine app.** Build `ENGINE_DATABASE_URL` from the cluster string (db segment →
   `firsthomey_engine`), inject it + the §3 engine secrets into a temp copy of
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
   one-off `psql` against `firsthomey_engine` (the same rows `fh_engine_store:upsert_tenant`
   + `ensure_signing_key` write in dev). This replaces aleap's "matching shared secret"
   step; it is the prod form of the handshake that `SHELL_DEV_AUTOPROVISION` does in dev.
   *(Future nicety: an authenticated admin provisioning endpoint — the carried-over
   8-S0b gap. Until then this manual insert is the procedure.)*
6. **Shell app.** Derive `SHELL_DATABASE_URL` (db segment → `firsthomey_shell`), inject it
   + the §3 shell secrets (the tenant id/privkey from step 5), validate,
   `doctl apps create --spec`. Boots → `firsthomey_shell` migrations →
   `maybe_autoprovision` no-ops (static key present). **Before DNS:** override
   `ENGINE_BASE_URL` to the engine's `*.ondigitalocean.app` ingress; revert to
   `engine.<apex>` once DNS lands.
7. **Frontend** on Cloudflare Pages — root dir `shell/web/frontend`, build
   `npm install && npm run build`, output `build`, env `NODE_VERSION`. **Add a proxy
   rule** so `/api/*` and `/health` reach the shell (a `_redirects`/`_routes` rewrite or
   a Pages Function to `https://api.<apex>/...`) — this is what makes the relative-`/api`
   SPA + same-origin cookie work without CORS.
8. **Domains / DNS.** Add DNS for `app.` (Cloudflare Pages custom domain), `api.`, and
   `engine.<apex>` (the two DO apps' `domains:` blocks). The sender domain `<apex>` needs
   its **own DKIM/SPF** verified in Resend (a dedicated apex, not the pre-verified
   bigsmallai.com). Register the Google redirect URI `https://app.<apex>/api/auth/google/callback`.
   Wait for HTTPS certs.

`deploy_on_push: true` on both DO apps (branch `main`) + Cloudflare's git build mean
**every push to `main` redeploys** — after the one-time setup, deploys are just merges.

---

## 5. Post-deploy smoke

- [ ] `GET https://engine.<apex>/health` → 200; `GET https://api.<apex>/health` → 200.
- [ ] `https://app.<apex>/` loads the SPA; a deep link resolves via the SPA fallback
      (no 404 on refresh).
- [ ] **Magic-link login:** request a link, pull the token from the **shell DO log
      stream** (until Resend's `RESEND_API_KEY` is set), verify, confirm the `fh_session`
      cookie is set on `app.<apex>` with `Secure`.
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
| **Dockerfiles** (engine + shell) | not written | engine = Erlang release + Python sidecar venv + KB artifact; shell = Erlang release only. |
| **`engine/app.yaml` + `shell/web/app.yaml`** | not written | DO App specs; build context = repo root; no `databases:` block. |
| **KB artifact in-image** | compiled locally to `priv/kb/artifact.json` | compile during Docker build (preferred) or `COPY` the committed file; ensure inputs tracked on `main`. |
| **Agent-SDK runtime deps** | **confirmed — aleap deploys this exact stack** | the engine image needs the **Claude Code CLI as a standalone native binary** (`claude.ai/install.sh`, pinned + `DISABLE_AUTOUPDATER=1`, **no Node**) on PATH, plus Python 3.14 + the venv (claude-agent-sdk / psycopg / pydantic). `claude_agent_sdk.query()` resolves `claude` via `shutil.which` (`setting_sources=[]`), authed by `CLAUDE_CODE_OAUTH_TOKEN` (`_credit_env()` blanks `ANTHROPIC_API_KEY` in the subprocess). Lift aleap's `engine/Dockerfile` install block verbatim. |
| **Sidecar reads repo files at runtime** | **confirmed — not yet fully stdin-fed** | `planner.py` resolves `_REPO_ROOT = parents[2]` and reads `docs/kb/lender/{serviceability-basics,fhg-panel-list}.md` (leaf-fill, no override) and `engine/erlang/priv/kb/artifact.json` (QA, override `FH_ARTIFACT_PATH`). So the engine image must **ship `docs/kb/**` + the artifact in their repo-relative layout** alongside `engine/python/planner.py` — OR finish the deferred "KB+schema on stdin" so the sidecar is truly stateless (principle 3; the cleaner fix). Decide this before the engine Dockerfile is final. |
| **Prod tenant-pubkey provisioning** | manual `psql` insert (§4 step 5) | works; an authenticated admin endpoint is the future nicety (carried 8-S0b gap). |
| **Cloudflare Pages `/api` proxy** | not configured | required for the relative-`/api` SPA + same-origin cookie (§4 step 7). |
| **DNS + custom domains + DKIM/SPF** | none | `app.`/`api.`/`engine.<apex>` + Resend domain verification for the dedicated apex. |
| **PG connection ceiling** | `db-s-1vcpu-1gb` ≈ 22 non-superuser slots | engine + shell pools consume most; bump cluster size if pools error under load. |
| **VN data residency (Decree 13/2023)** | out of Wedge-1a scope | Wedge 1a is Mode A (AU users); plan VN-side residency from Wedge 2 before onboarding VN-located users (CLAUDE.md). |
| **Stripe / commerce** | deferred (8-S5 chain) | no billing secrets yet; subscription/metering lands with the commerce slices. |

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
