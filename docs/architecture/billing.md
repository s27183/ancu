# Billing

> How FirstHomey charges for the planning agent — a **tiered subscription** with per-tier token limits, plus orthogonal one-time add-ons. Billing is **shell-owned**: the engine emits `usage` (tokens, no cost) and never debits, never gates on money. This is the shell-side companion to [`engine-contract.md`](engine-contract.md) §8 (commerce is out of scope for the engine) and fills in the *how* for the commerce structures named in [`shell-architecture.md`](shell-architecture.md) §5–§6.
>
> Borrowed from [ATP's billing](../../../atp/docs/architecture/billing.md) (the engine-meters/shell-bills split, the pull-model outbox, Stripe + admin bypass) and **reshaped from pay-as-you-go to subscription** — the one load-bearing divergence (see §3). Cost figures are **measured**, not estimated: see §4.

---

## 1. Separation of concerns

Billing lives in the shell backend (`fh_shell_billing`, `fh_shell_usage_consumer`), never the engine. The engine never reads a balance, never gates on a quota, never charges. This is constraint #11 (engine meters, shell gates) and [`docs/design/invariants.md`](../design/invariants.md) P-5, and it keeps **ASIC liability out of the agent loop** — the engine never decides whether work proceeds based on money.

| Layer | What it does |
|---|---|
| **Engine** | Emits one `usage` event per **LLM-call boundary** (`{tenant_id, user_id, plan_card_id, turn_id, source, model, input/output/cache tokens}`, [`engine-contract.md`](engine-contract.md) §9) — **no cost, no debit**. Resolver-only turns emit none (they cost nothing). |
| **Engine** | Writes an `audit_events` row per (component, gate) for compliance attribution — **no cost** ([`compliance-pipeline.md`](compliance-pipeline.md) §5). |
| **Shell** | Tails `usage` via cursor (pull-model outbox) → `usage_records`, computes the shadow cost, accumulates the period meter. |
| **Shell** | Pre-call gate: is the user's current-period token total under their tier limit? Block new agent turns at the limit; resolver-only turns always pass. |
| **Shell** | Stripe subscription lifecycle (checkout, webhook), tier assignment, one-time add-on charges, admin bypass. |

**Cost vs. billing.** *Cost* is what the infrastructure actually spends (real tokens, served on the Max-subscription credit path — §8). *Billing* is what the user is charged (their tier price, fixed per period). The two are decoupled: a tier's price is fixed; its cost varies with how many tokens the user burns — which is exactly why a tier must cap tokens (§3).

---

## 2. What carries over from ATP unchanged

The architecture is the same engine/shell shape ATP proved; only the *credit model* differs. Lifted directly:

- **Pull-model outbox** — a shell `gen_server` (`fh_shell_usage_consumer`) tails the engine's `usage` events by a monotonic cursor, writes each as one **idempotent** `usage_records` row (`ON CONFLICT (engine_event_id) DO NOTHING`). No RPC into engine tables, **no cross-DB joins ever** ([`engine-contract.md`](engine-contract.md) §9.3). Replay-safe.
- **Stripe checkout + webhook** with HMAC-SHA256 signature verification.
- **Admin bypass** via a JWT-claim email allowlist materialised at boot (ETS) — never a cross-DB lookup into the engine.
- **An ETS cache** in the shell backend for the hot-path balance/meter read (ATP uses a 30s TTL).

---

## 3. The reshape: pay-as-you-go → subscription

This is **not** a cosmetic swap. The two models are economically inverted, and the inversion is what forces per-tier token limits:

| | ATP (pay-as-you-go) | FirstHomey (subscription) |
|---|---|---|
| Revenue | ≈ cost per call (linear, self-balancing) | **fixed** per period (the tier price) |
| Cost | linear in tokens | **variable** in tokens |
| Per-user risk | none — a heavy user pays more | **real** — a heavy user in a cheap tier loses money |
| Ledger role | debit a prepaid `credit_balances` per event | **accumulate** period token usage; gate against the tier limit |

**Consequence:** a subscription tier *must* encode a usage limit to bound per-user cost. ATP's `credit_balances` / `credit_transactions` (a debit ledger) becomes FirstHomey's `subscriptions` (tier, Stripe id, period) + a **period-windowed token meter** (an aggregate over `usage_records`). The outbox consumer's job shifts from *debit a balance* to *increment a meter*; the shell gates when the meter crosses the tier's limit.

**The meter unit is tokens** — directly what the engine emits and what costs money. (Turns are shown in §4–§5 for human intuition, but the enforced quota is tokens.)

---

## 4. Cost basis — measured

Cost is **accounted at Claude Opus 4.8 direct-API rates** ("cost everything at Opus") even though production serves on the cheaper Max-subscription credit path (§8). This is deliberate and conservative: the shadow price is the *ceiling*, so the tier economics hold even if a turn ever spills to real direct-API.

**Opus 4.8 pricing** (verified June 2026, [finout](https://www.finout.io/blog/anthropic-api-pricing) / [apidog](https://apidog.com/blog/claude-opus-4-8-pricing/)):

| | $/M tokens | vs base input |
|---|---|---|
| Input | $5 | 1× |
| Output | $25 | 5× |
| Cache write (5 min) | $6.25 | 1.25× |
| Cache write (1 hour) | $10 | 2× |
| Cache read | $0.50 | 0.1× |

**Measured per-turn cost** (live Opus 4.8 through `seam_smoke` / `qa_smoke`, 2026-06-13, real `usage` tokens read from `plan_card_events`):

| Turn kind | input | output | cache-write (1h) | cache-read | **cold** | **warm** |
|---|---|---|---|---|---|---|
| Base fill (`mortgage_finance` `lender_fit`) | 2,005 | 2,032 | 38,491 | 33,705 | **$0.46** | **$0.10** |
| Chat (Q&A, 2 KB lookups) | 2,001 | 979 | 12,857 | 44,018 | **$0.19** | **$0.06** |

Two facts drive everything:

- **The 1-hour cache *write* ($10/M, 2×) dominates a cold turn** — $0.385 of the base turn's $0.46. The planner caches the prompt prefix at 1h TTL (`ephemeral_1h`).
- **Cache *reads* are cheap ($0.50/M)** — so chat (read-heavy) and every *warm* turn (prefix already cached within the hour) are far cheaper. A user's burst of turns within an hour pays one write + cheap reads.

So plan on **~$0.10–0.20/turn steady-state**, with **$0.46 as the cold-turn ceiling**. Resolver-only turns are **free** (no LLM call). Tuning lever, if cold turns ever dominate: switch the prefix to a 5-minute cache (1.25× write, $6.25/M) — cheaper write, shorter reuse window.

---

## 5. Tiers

Initial tiers, grounded in strategy §8.4 (free base plan + $25/mo advanced) and the §4 costs. Target ~60% gross margin at the shadow price (LLM cost ≤ 40% of tier price); steady-state (warm) margin runs ~80%. Limits are **calibrated against observed usage** once real `usage_records` accumulate — they are a starting point, not a constant.

| Tier | Price/mo | Cost budget (40%) | Token limit / period | ≈ turns/mo | Gates |
|---|---|---|---|---|---|
| **Free** | $0 | ~$4 (CAC) | 1.0M | ~16 | Base plan + map; capped chat/refresh |
| **Plus** | $25 | $10 | 2.5M | ~40 | + decision-trail history, comparison views (strategy §321) |
| **Pro** | $49 | $20 | 5.0M | ~80 | + Tìm Nhà priority, higher quota |

The **free tier is a deliberate customer-acquisition cost** (~$4/mo of real compute, $0 revenue) — consistent with strategy §321 ("free base plan maximises demand aggregation, which IS the asset"). It is funded by paid conversion.

**Tiers gate feature access + the token quota; they do not change cost rates.** A turn costs the same regardless of tier; the tier only sets how many a user gets.

---

## 6. Metering → billing pipeline

```
Engine LLM-call boundary
  → emit `usage` {tenant_id, user_id, plan_card_id, turn_id, source, model,
                  input_tokens, output_tokens, cache_read, cache_creation}   (no cost)
  → persisted to plan_card_events (SOT) + streamed on SSE

Shell fh_shell_usage_consumer (gen_server, cursor poll)
  ATOMIC, per event:
    INSERT INTO usage_records (..., engine_event_id, tokens, shadow_cost)
      ON CONFLICT (engine_event_id) DO NOTHING            -- idempotent replay
  → period meter = Σ tokens over usage_records in the current subscription period
  → ETS cache invalidated for that user
```

`shadow_cost` is computed at write time by `fh_shell_pricing` from the token breakdown × the §4 Opus rates (input/output/cache-write/cache-read each at their own rate). The **enforced quota** is the token sum, not the dollar cost — dollars are for the dashboard and margin analysis.

The **period meter** is the authoritative `Σ tokens` over `usage_records` for `[current_period_start, current_period_end)`. An ETS counter caches it for the pre-call gate (§7); the SQL sum is the source of truth on cache miss or rebuild.

---

## 7. Gating

The shell gates **before** a call reaches the engine (metering-not-gating: the engine would happily run the turn; the shell decides whether to let it):

```
on POST /api/plan-cards/:id/messages (or any agent-triggering call):
  tier_limit = tier_token_limit(user.tier)
  used       = period_meter(user)            -- ETS, falling back to SQL Σ
  if used >= tier_limit:
     → 402-style block; offer upgrade / next-period reset    (no engine call made)
  else:
     → mint tenant JWT, proxy to /api/engine/*
```

- **Resolver-only turns are never blocked** — they emit no `usage` and cost nothing (e.g. a `cash_position` recompute). The gate only guards agent (LLM) turns. The shell can't always know in advance whether a turn will be resolver-only, so the conservative gate is: *block new agent-eligible turns at the limit*; a turn that turns out resolver-only simply adds nothing to the meter.
- **At-limit behaviour** (soft grace vs hard stop) is a product decision; the recommended default is a **hard stop with an upgrade prompt + period-reset date**, since an unbounded overage reintroduces the per-user cost risk §3 exists to remove.
- **The daily question cap** (behavior 36) follows the token gate on `POST /api/plan-cards/:id/messages` only: one assistant question per user per Sydney calendar day (`FH_QA_DAILY_LIMIT`, default 1), claimed atomically in `qa_daily_asks` before the engine call and given back when the engine does not accept the turn (busy, failed). A blocked ask is `429 daily_question_limit {limit, resets_at}` (next Sydney midnight, UTC) with no engine call; `ADMIN_EMAILS` users are exempt. Plan building, properties and documents stay under the token limit alone.
- **Document-review turns** (attachments present → an extraction LLM-call boundary, [`engine-contract.md`](engine-contract.md) §5) are gated separately on the user's per-addendum entitlement (§9), *before* and independently of the chat quota.

---

## 8. Compute path

**Production serves on the Max-subscription credit path** (Claude Agent SDK + `CLAUDE_CODE_OAUTH_TOKEN`, aleap ADR 0031, already wired in `planner.py:_credit_env()`): the SDK's `claude` subprocess runs on subscription credit, with `ANTHROPIC_API_KEY` neutralised so the OAuth token wins. **Direct-API Opus is the ceiling fallback** for overflow. Cost *accounting* uses the Opus shadow rates (§4) regardless of which path actually served — the cheaper Max path is upside, not budgeted.

**Capacity is not the binding constraint.** Max 20x ($200/mo) post the May-2026 doubling: ~1,800 messages / 5-hour window, ~40 Opus hours/week, one pool shared across Claude chat + Code. At ~30s of Opus per turn (`lender_fit` measured 29.6s), ~40 Opus-hrs/week ≈ ~4,800 turns/week per seat → headroom for hundreds of Plus customers per seat. ([Claude Code usage limits 2026](https://www.morphllm.com/claude-code-usage-limits).)

**The real consideration is ToS, not throughput.** Max is a single-user consumer plan; serving a commercial multi-tenant product off Max-OAuth seats is off-label and Anthropic enforces aggressive limits. The measurement de-risks this: direct-API Opus 4.8 is cheap enough ($0.10–0.46/turn) that a Plus customer (~40 turns) costs ~$4–18 on the *legitimate* path against $25 revenue — so the fallback is economically safe, and the prudent posture is **Max-OAuth as the cost-saver, direct-API as the production-legitimate path the economics already support.** This is a live business call; the architecture is identical either way (the engine meters tokens regardless of vendor — vendor/model is engine `.env` config, never a user-facing claim, [`engine-contract.md`](engine-contract.md) §6).

---

## 9. Stripe + add-ons

**Subscription lifecycle** (`fh_shell_billing`):

```
User picks a tier
  → POST /api/billing/subscribe        (creates a Stripe Checkout session, mode=subscription)
  → Stripe hosted checkout → user pays
  → webhook POST /api/billing/webhook
       HMAC-SHA256 verify (STRIPE_WEBHOOK_SECRET)
       customer.subscription.created/updated/deleted, invoice.paid
  → upsert subscriptions {user_id, tier, stripe_subscription_id, status, period_start, period_end}
  → tier change takes effect on the user's next pre-call gate (§7)
```

**Add-ons are orthogonal one-time charges** (Stripe PaymentIntent, written to `charges`) — **not** folded into a tier:

| Add-on | Price | Trigger |
|---|---|---|
| Document review | $40 / property addendum | Section 32 / Contract of Sale upload (strategy §337) |
| Tìm Nhà property search | $200–500 / engagement | Curator-served shortlist (strategy §11.11) |
| Settlement success fee | $500–1,000 | At settlement (REA-paid; ledger) |

REA-side commerce (Tier 1/2 subscriptions, connection fees — strategy §8.5) reuses the same `subscriptions` / `charges` machinery under operator-granted roles; it is out of scope for Wedge 1a but the schema does not preclude it.

**Admin bypass:** `ADMIN_EMAILS` → ETS allowlist at boot; an admin's turns meter normally (cost is real, for attribution) but bill $0 — the `usage_records` row carries the idempotency key with `billed = false` so replay stays a no-op.

---

## 10. Shell DB — commerce tables

Owned entirely by `ancu_shell` (never read by the engine, [`shell-architecture.md`](shell-architecture.md) §6). Fleshing out the commerce rows named there:

```sql
subscriptions
├── user_id (uuid → users.id)
├── tier (text)                      free | plus | pro
├── stripe_subscription_id (text, nullable)
├── status (text)                    active | past_due | canceled
├── current_period_start, current_period_end (timestamptz)
└── updated_at

usage_records                        -- pull-model outbox mirror; one row per engine usage event
├── id (uuid)
├── user_id (uuid)
├── engine_event_id (text, UNIQUE)   -- idempotency key from plan_card_events
├── plan_card_id, turn_id (uuid)
├── source, model (text)
├── input_tokens, output_tokens, cache_read_tokens, cache_creation_tokens (int)
├── tokens_total (int)               -- the metered quantity
├── shadow_cost (numeric 12,6)       -- §4 Opus-rate valuation (dashboard / margin)
├── billed (bool)                    -- false for admin (attribution without charge)
└── created_at

charges                              -- one-time add-ons (§9)
├── id (uuid), user_id (uuid)
├── kind (text)                      doc_review | timnha | success_fee
├── amount (numeric 12,2)
├── stripe_payment_intent_id (text, nullable)
├── plan_card_id (uuid, nullable)    -- e.g. the addendum reviewed
└── created_at
```

The **period meter** is derived, not stored: `SELECT sum(tokens_total) FROM usage_records WHERE user_id=$1 AND created_at >= period_start` — cached in ETS for the gate. (`subscription_periods` as a separate table is optional; the `current_period_*` columns on `subscriptions` suffice for Wedge 1a.)

---

## 11. Key modules

| Module | Role |
|---|---|
| `fh_shell_usage_consumer` | Pull-model outbox: tails engine `usage` by cursor, idempotent `usage_records` insert |
| `fh_shell_pricing` | `shadow_cost` from tokens × §4 Opus rates; `tier_token_limit/1` |
| `fh_shell_billing` | Stripe subscription checkout + webhook; one-time add-on charges; admin allowlist |
| `fh_shell_meter` | Period-meter read (ETS cache + SQL Σ fallback); the §7 pre-call gate |

(All named consistent with [`shell-architecture.md`](shell-architecture.md) §5; `fh_shell_pricing` / `fh_shell_meter` are the two new modules this doc introduces beside the already-listed `fh_shell_billing` / `fh_shell_usage_consumer`.)

---

## Relationship to other docs

- [`engine-contract.md`](engine-contract.md) §8 (commerce out of scope), §9 (`usage` event schema + the pull-model outbox), §1 (metering-not-gating) — the engine side of this boundary.
- [`shell-architecture.md`](shell-architecture.md) §5–§6 — the modules and tables this doc details; §2 ownership.
- [`03-strategy.md`](../03-strategy.md) §8.4 (pricing direction), §8.5 (REA economics), Wedge 1a §321 / §337 (the GTM numbers these tiers implement).
- [`docs/design/invariants.md`](../design/invariants.md) P-5 — metering, not gating.
- [`compliance-pipeline.md`](compliance-pipeline.md) §5 — `audit_events` (attribution, no cost), the sibling of `usage`.
- [`structure-map.md`](structure-map.md) Plane 5 — situates commerce in the engine/shell node-set.
