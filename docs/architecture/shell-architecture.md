# FirstHomey Shell Architecture

> The **shell** half of the engine/shell split — its runtime, identity, repo layout, and UX surfaces. This is the shell-side companion to [`engine-contract.md`](engine-contract.md): that doc defines the boundary *from the engine's side* (the primitives the engine exposes, the events it emits, the tokens it verifies); this one defines what sits *behind* the shell's edge of that boundary. Where the two touch — claims, event taxonomy, DB ownership — this doc cross-references rather than restates.
>
> Borrowed from [aleap's architecture](../../../aleap/docs/architecture/architecture.md) §"Shell — Web" and reshaped to FirstHomey's constraints (see [§9 Borrowed and reshaped](#9-borrowed-and-reshaped)). Read [`architecture.md` §11](architecture.md) first for the strategic engine/shell split; CLAUDE.md constraint #11 is the one-line version.

---

## 1. Roles: SvelteKit frontend, Erlang backend

The shell splits into two runtimes, the same way aleap's web shell does:

- **Frontend — SvelteKit.** Everything the buyer (or curator) sees: the map-first home, onboarding, the plan projection, the bilingual Q&A chat layer. Owns the constrained renderer vocabulary (constraint #7), route guards, locale display (vi default, en toggle — [`bilingual-content.md`](bilingual-content.md): the engine emits both `{vi, en}`; the shell *picks which to show*). Static + SSR; no business logic beyond presentation and calling its own backend.
- **Backend — Erlang/OTP.** Orchestration: user authentication (Resend magic-link + Google OAuth), the user session/JWT, **minting the engine tenant JWT** (the load-bearing identity seam), proxying `/api/engine/*` + SSE, commerce (subscription / per-addendum / success-fee), and the `usage` outbox consumer. Owns the shell's own Postgres.

The frontend never talks to the engine directly — it always goes through the Erlang backend, which holds the engine signing key and is the only place a tenant JWT is minted. This keeps the engine's signing trust in one auditable server process and lets the backend gate on commerce before a call ever reaches the engine (metering-not-gating, [`engine-contract.md`](engine-contract.md) §1).

```
                          ┌────────────────────────────────────┐
                          │  Engine  (already built)            │
                          │    Erlang gateway (Cowboy)  :8080   │
                          │    Python sidecars (per-turn)       │
                          │    Postgres: ancu_engine      │
                          │      profiles, plan_cards,          │
                          │      plan_card_events, sessions,    │
                          │      audit_events, suburbs          │
                          └───────────────┬─────────────────────┘
                                          ▲  │
                                          │  │ /api/engine/*  (+ SSE)
                                          │  │ Bearer = ed25519 tenant JWT
                                          │  │ {tenant_id, user_id, exp}
       Browser users ──▶┌─────────────────┴──▼──────────────────┐
       (login,          │  Shell — Web                          │
        onboarding,     │    SvelteKit frontend  (Cloudflare)   │
        map home,       │       map · onboarding · plan         │
        plan, chat)     │       projection · chat · i18n vi/en  │
                        │              │  user JWT (HS256)       │
                        │              ▼                         │
                        │    Erlang backend       :8081          │
                        │       Resend/Google → user session     │
                        │       mints engine tenant JWT          │
                        │       proxies /api/engine/* + SSE       │
                        │       commerce · usage consumer        │
                        │    Postgres: ancu_shell          │
                        │       users(+role), magic_tokens,      │
                        │       subscriptions, charges,          │
                        │       usage_records, timnha_requests   │
                        │                                        │
                        │   Routes (role-gated):                 │
                        │     /            buyer  (map home)      │
                        │     /curator/*   curator (Tìm Nhà)      │
                        │     /admin/*     admin                  │
                        └────────────────────────────────────────┘

       (Phase B)        ┌────────────────────────────────────────┐
                        │  Shell — Extension                      │
                        │    Browser extension (property capture) │
                        │    own tenant; mints its own JWT        │
                        └────────────────────────────────────────┘
```

**Wedge 1a is one web shell** with role-gated route groups (buyer · curator · admin), exactly as aleap folds customer/curator/admin into one shell. The browser **extension** (Phase B property capture, CLAUDE.md "Where to start building" #9) and a future **curator console** are separate *tenants* in the engine's eyes (`tenant_id ∈ web | extension | curator-console`, [`engine-contract.md`](engine-contract.md) §3) but Wedge 1a ships only `web`.

---

## 2. Ownership — who owns what

The engine ownership column is the inverse of [`engine-contract.md`](engine-contract.md) §8 "Out of scope for the engine." The shell owns identity, commerce, and presentation; the engine owns the agentic primitive, compliance, and metering.

| Engine owns | Web shell owns |
|---|---|
| `/api/engine/*` primitives + typed SSE events (§2/§4) | User account, login UX (Resend magic-link, Google OAuth), role assignment |
| Planning-agent execution (Python sidecars) | Subscription tier, per-addendum charges, REA success-fee ledger |
| `profiles` / `plan_cards` / `plan_card_events` / `sessions` (runtime SOT) | The shell's *view* of plan cards (title, archived, last-opened tab) |
| KB + blueprint artifact (git-authored, compiled; engine is sole reader) | Map rendering + renderer vocabulary (constraint #7) |
| Compliance pipeline (FIRB / ASIC / AML) — engine-owned because it gates **agent behavior** | Disclaimer **copy** + placement (the consequence of a `compliance_gate`) |
| `usage` metering (tokens, no cost) | `usage_records` (cost; mirror of engine `usage`, aggregated for billing) |
| `suburbs` reference data + a read endpoint (8-S1) | Locale **display** pick (vi/en), bilingual disclaimer placement |
| Tenant registry + `tenant_signing_keys` (verifies; never originates) | The ed25519 keypair — **mints** the tenant JWT; engine holds only the public half |

The engine never serves a login page, never sends an OAuth email, never debits a counter, never decides which language to display. The shell never reads an engine table directly (no cross-DB joins ever — [`engine-contract.md`](engine-contract.md) §9.3); it calls the API and merges in application code.

---

## 3. Auth — two JWTs

Two token domains, the same two-layer shape as aleap, with **one deliberate divergence**: FirstHomey's engine verifies an **EdDSA/ed25519** tenant JWT (aleap's engine uses HS256). So the shell-backend signs the engine token with an ed25519 *private* key whose public half is registered in the engine.

| Surface | Served by | Token | Validated by |
|---|---|---|---|
| `/api/*` (shell, public: `/api/auth/*`, `/health`) | Shell backend | — | (no auth) |
| `/api/*` (shell, authenticated) | Shell backend | **User JWT** (HS256, carries role + locale) | `fh_shell_auth_middleware` |
| `/api/engine/*` | Engine | **Tenant JWT** (EdDSA/ed25519, `{tenant_id, user_id, exp}`) | `fh_engine_auth` (already built) |

**User JWT (browser ↔ shell-backend).** Claims `{user_id, email, roles[], locale, iat, exp}`, signed with the shell's `SHELL_JWT_SECRET` (HS256). Frontend route guards + backend middleware enforce role; routes outside a user's roles 404, not 403 (minimize surface disclosure — aleap's rule). Issued by `fh_shell_jwt` after Resend/Google authentication.

**Tenant JWT (shell-backend → engine).** The seam the engine already verifies. The shell-backend holds the ed25519 private key; the engine holds the public key in `tenant_signing_keys`. Per request to `/api/engine/*`, `fh_shell_engine_jwt:mint/1` produces a fresh short-lived JWT with `{tenant_id, user_id, exp, iat}` and the optional curator-authorization claim ([`engine-contract.md`](engine-contract.md) §3). Verified against any active key for the tenant (key rotation = old + new both active — `fh_engine_auth:verify_sig/3`).

The full mint path is already exercised end-to-end by `engine/erlang/test/seam_smoke.escript:21` (commented *"the shell's role in production"*): `crypto:generate_key(eddsa, ed25519)` → `fh_engine_store:upsert_tenant` → `fh_engine_store:add_signing_key(TenantId, <<"ed25519">>, base64:encode(Pub))` → `fh_engine_auth:sign({tenant_id, user_id, exp}, Priv)` → `Bearer`. The shell-backend does exactly this; the only new code is wrapping it in an OTP app, registering the key once at provisioning (not per request), and minting per request.

**Chain.** Resend magic-link / Google OAuth → `fh_shell_login` authenticates → `fh_shell_jwt` issues the user JWT → browser carries it on `/api/*` → `fh_shell_engine_jwt` mints the tenant JWT → `/api/engine/*`.

---

## 4. Repository layout

Borrows aleap's `shell/web/{frontend,backend}` shape (replacing CLAUDE.md's earlier `shell/svelte/{frontend,backend}` — the `svelte/backend` name was misleading; the backend is Erlang, not Svelte. See [§9](#9-borrowed-and-reshaped)).

```
shell/
├── web/                                ← all browser users (buyer + curator + admin)
│   ├── frontend/                       SvelteKit (Cloudflare Pages adapter)
│   │   └── src/
│   │       ├── routes/
│   │       │   ├── +page.svelte         map-first home (suburb-intelligence map)
│   │       │   ├── auth/                login (magic link + OAuth callback)
│   │       │   ├── onboarding/          first-run: mode + applicant set capture
│   │       │   ├── plan/                plan projection (zone-default → per-suburb) + chat layer
│   │       │   ├── curator/             Tìm Nhà console (role-gated: curator)
│   │       │   └── admin/               user/role mgmt (role-gated: admin)
│   │       └── lib/                     components, stores (auth + locale), i18n (vi default, en)
│   ├── backend/                        Erlang/OTP (port 8081, Postgres ancu_shell)
│   │   ├── src/                        fh_shell_*  (see §5)
│   │   ├── priv/migrations/            ancu_shell schema
│   │   └── rebar.config
│   └── README.md
└── extension/                          ← Phase B browser extension (property capture); own tenant
```

The curator console is a role-gated *route group* inside the one web shell (aleap's pattern), not a separate deployable — until its consumer surface genuinely diverges (the forcing function, [`engine-contract.md`](engine-contract.md) §1). Tìm Nhà v1 is manual / spreadsheet-driven (CLAUDE.md #8); the console is its thin web surface.

---

## 5. Shell backend — Erlang modules

Mirrors aleap's `aleap_shell_*` naming so the two backends read alike. Wedge-1a-essential modules first; commerce + curator land later.

```
shell/web/backend/src/                  ← Erlang (port 8081, Postgres ancu_shell)
├── fh_shell_app.erl                    application entry, .env loader, cowboy routes
├── fh_shell_sup.erl                    root supervisor
├── fh_shell_db.erl                     PGO pool — ancu_shell
├── fh_shell_http.erl                   cowboy listener + routing + request helpers
├── fh_shell_health_handler.erl         /health
├── fh_shell_login.erl                  Resend magic-link, Google OAuth
├── fh_shell_jwt.erl                    user JWT (HS256) issue + verify (carries role + locale)
├── fh_shell_auth_middleware.erl        user JWT verification + role enforcement
├── fh_shell_engine_jwt.erl             mints the ed25519 tenant JWT (the seam)  ← 8-S0 keystone
├── fh_shell_engine_client.erl          calls /api/engine/* + proxies SSE; tenant-JWT per request
├── fh_shell_api_handler.erl            /api/me, /api/plan-cards (proxy), /api/suburbs (proxy)
├── fh_shell_billing.erl                subscription / per-addendum / success-fee (later phase)
├── fh_shell_curator_handler.erl        /api/curator/* — Tìm Nhà queue (role-gated; later)
└── fh_shell_usage_consumer.erl         tails engine `usage` by cursor → usage_records (later)
```

**Routes (shell backend, `:8081`):**

```
/api/auth/email, /api/auth/email/verify     fh_shell_login        (magic link)
/api/auth/google                            fh_shell_login        (OAuth)
/api/me                                      fh_shell_api_handler  (current user + roles + locale)
/api/plan-cards[...]                         fh_shell_api_handler  (proxy → engine, tenant-JWT)
/api/plan-cards/:id/events                   fh_shell_engine_client (SSE proxy)
/api/suburbs                                 fh_shell_api_handler  (proxy → engine 8-S1)
/api/billing/*                               fh_shell_billing      (later)
/api/curator/*                               fh_shell_curator_handler (curator role; later)
/health                                      fh_shell_health_handler
```

The shell-backend is a **proxy + identity/commerce layer** in front of the engine, not a re-implementation. `/api/plan-cards*` and `/api/suburbs` forward to `/api/engine/*` with a minted tenant JWT; the shell adds its own DB (titles, archive state, commerce) and merges in application code.

---

## 6. Shell database — `ancu_shell`

One Postgres, owned entirely by the shell. Never read by the engine; never joined cross-DB ([`engine-contract.md`](engine-contract.md) §9.2/§9.3). Holds identity, display state, and commerce — **never** canonical plan content (that's engine `plan_cards`).

| Table | Purpose |
|---|---|
| `users` | `{user_id, email, role, extra_roles[], locale, created_at}` — single user table, all roles; default `role='buyer'` on signup |
| `magic_tokens` | Resend magic-link issuance + single-use redemption |
| `oauth_identities` | Google OAuth subject ↔ user linkage |
| `plan_card_views` | The shell's view of an engine plan card: `{engine_plan_card_id, title, archived, last_opened_tab}` — *not* content |
| `subscriptions`, `subscription_periods` | $25/mo tier + period (commerce; later) |
| `charges` | One-time per-addendum document-review charges ($40); REA success-fee ledger (later) |
| `usage_records` | Mirror of engine `usage` (tokens → cost), aggregated for billing (pull-model outbox; later) |
| `timnha_requests` | Tìm Nhà request/queue state for the curator console (later) |

`role ∈ buyer | curator | admin`; default `buyer`. `curator`/`admin` are operator-granted, not signup-assignable (aleap's rule). Locale is a *display* preference (which of the engine's `{vi, en}` to show), default `vi`.

---

## 7. UX surfaces — map-first

The product is **map-first** (the one structural revision of `04-ux-model.md` §13.4's form-first flow, now reconciled there). The map is the home and the dashboard; plan cards pin to their zones.

- **Map home (`/`)** — full-bleed suburb-intelligence map (MapLibre GL JS via MIERUNE `svelte-maplibre-gl`; see [`map-stack.md`](map-stack.md)), zone-data overlays reading raw `facts_jsonb` (Vietnamese-community proximity is the killer layer, shipped first). Click a suburb (SAL) → sheet with a **zone-data tab** + a **planning tab**. Engine owns the suburb *data* (8-S1 read endpoint); the shell owns rendering.
- **Onboarding (first-run)** — mode + applicant-set capture (each person's FIRB status + intent — the highest-harm input, constraint #10) populates the persistent household fact base (`profiles`); target price range is a **user input** (VND→AUD slider, constraint #1), not zone data. One capture per household; zone + budget + intent are per-plan-card.
- **Plan projection (the planning tab)** — the base plan has **no standalone dashboard**; its only surface is the plan **projection** in a gradient from zone-default (no suburb pinned) → per-suburb (click narrows the overlay). The projection carries the **invariant core** (eligibility, borrowing, deposit, FHSS, scheme stack — identical in every suburb) plus the thin suburb overlay (stamp duty, FHG cap, proximity). Rendered from `component_filled` outcomes via the renderer vocabulary. Its only no-map form is an on-demand **export dossier** (`first_home_buyer_plan.html` as a deliverable, not a nav surface).
- **Chat layer (the planning tab)** — the 2c bilingual Q&A path (already built engine-side), VI-default + EN toggle. `text_delta {text, lang}` frames concatenated per language; shell picks display.

### 7.1 Mobile-native, minimal cognitive load

Every buyer-facing surface is designed phone-first (the diaspora buyer's primary device): one-handed, full-bleed canvas, touch targets, primary action in the thumb zone. Desktop is the **adjusted** variant — wider canvas, side-panel instead of bottom-sheet, hover affordances — never a separately-designed layout. The governing goal is **minimal cognitive load**, achieved by:

- **One primary decision per view.** Surface the single thing that matters now; defer the rest behind a tap. Tabs and hierarchical popup sheets (button-triggered) are the mechanisms; deep nesting and dense dashboards are the anti-pattern.
- **No scrolling to reach a decision.** Everything decision-critical sits above the fold or one tap away. (Long-form content — the export dossier, a full plan projection — may scroll; the rule is about *decisions*, not *length*.)
- **Obvious, consistent navigation.** The same action lives in the same place across surfaces; navigation signs are explicit, not discovered.
- **One language on the surface, the other on demand.** VI-default; never `{vi, en}` stacked (that doubles density and defeats minimal-load). The shell picks one per surface (see [`agentic-flow.md`](agentic-flow.md) on bilingual-first-class engine output); the second language is a tap away. The chat layer's VI-default + EN toggle (above) is the first instance.
- **Uncertainty reads as calm confidence.** Honest partials (`PENDING`, banded ranges, `to_verify`, bilingual disclaimers) render as reassurance, not error-noise. Subtle, affirmative color; regulated/uncertain content is *informed*, never alarming.
- **Never a blank wait.** Agent turns are slow (inference behind the engine seam) — stream, skeleton, show progress; no frozen screen.

**Boundary:** this governs buyer-facing surfaces. The curator console is a back-office tool and is desktop-first.

Full UX rationale: [`04-ux-model.md`](../04-ux-model.md) §13; the design conversation that set this direction is captured in the `firsthomey-shell-direction` working note.

---

## 8. Deployment shape (target)

Aleap-aligned: two backends + one frontend. Not yet provisioned.

| Service | Source | Runtime | Port | DB | Hosting (target) |
|---|---|---|---|---|---|
| Engine | `engine/` | Erlang/OTP + Python (one container) | 8080 | `ancu_engine` | TBD (aleap uses DO App Platform) |
| Shell backend | `shell/web/backend/` | Erlang/OTP | 8081 | `ancu_shell` | TBD |
| Shell frontend | `shell/web/frontend/` | SvelteKit (Cloudflare Pages adapter) | n/a | — | Cloudflare Pages |

**Local dev.** Engine against local `ancu_engine`; shell backend against `ancu_shell` (created when the shell lands). Each backend reads its own `DATABASE_URL` from `.env`. The shell-backend additionally holds `SHELL_JWT_SECRET` (user JWT), the engine tenant signing keypair, and Resend/Google credentials.

---

## 9. Borrowed and reshaped

Borrowed wholesale from aleap: the engine/shell runtime split, `shell/web/{frontend,backend}` layout, the two-JWT model (user JWT + shell-minted tenant JWT), role-gated route groups in one web shell, the pull-model `usage` outbox, "no cross-DB joins ever."

**Reshaped to FirstHomey's constraints:**

- **Tenant JWT is EdDSA/ed25519, not HS256.** FirstHomey's engine (`fh_engine_auth`) verifies ed25519 signatures against per-tenant public keys; aleap's verifies HS256. So the shell-backend holds an asymmetric *private* key and the engine holds only the public half — a stronger trust split (the engine cannot mint shell tokens even in principle).
- **The buyer is the customer; there is no API product.** aleap sells `legal_research` as an API (API-key issuance, `/mcp`, customer dashboards of keys/quota). FirstHomey's buyer pays for planning; `/mcp` is deferred ([`engine-contract.md`](engine-contract.md) §2.2). **Deliberately not borrowed:** API-key issuance/lifecycle machinery, the customer key dashboard, the `/mcp` transport surface.
- **Curator console is a web role-group, not a Mac plugin.** aleap runs curation flow-3 on Son's Mac via a Claude Code plugin (ADR 0008/0030). FirstHomey's Tìm Nhà v1 is manual/spreadsheet-driven inside the web shell (CLAUDE.md #8). **Deliberately not borrowed:** the `shell/plugin/` runtime; the `engine_jobs` worker queue (engine-side concern, not shell).
- **Map-first home.** aleap's shell is a dashboard of keys/usage; FirstHomey's is a suburb-intelligence map. The renderer vocabulary (constraint #7) and the plan projection model are FirstHomey-specific.

---

## Relationship to other docs

- [`engine-contract.md`](engine-contract.md) — the boundary from the engine's side: the surfaces this shell calls (§2), the events it renders (§4), the claims it mints (§3), DB ownership (§9). **This doc is its shell-side companion** — it does not restate the contract, only what sits behind the shell's edge of it.
- [`architecture.md` §11](architecture.md) — the strategic engine/shell split; constraint #11 in CLAUDE.md.
- [`isolation-model.md`](isolation-model.md) — plan card vs turn, per-card serialization (what the shell's plan-card views project over).
- [`bilingual-content.md`](bilingual-content.md) — why the engine emits `{vi, en}` and the shell only picks display.
- [`04-ux-model.md`](../04-ux-model.md) §13 — the UX model §7 implements.
- [`structure-map.md`](structure-map.md) — situates the shell in the system node-set across planes.
