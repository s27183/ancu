# Engine migrations

Forward-only, numbered SQL migrations for the engine's Postgres (the **runtime
state** database — `docs/architecture/engine-contract.md` §9.1). The shell
databases (§9.2) and the compiled KB/blueprint artifact (git-authored, loaded
into `persistent_term` at boot — *not* Postgres) are out of scope here.

## Files

| File | What it creates |
|---|---|
| `001_init_engine.sql` | Core runtime state: `tenants`, `tenant_signing_keys`, `profiles` (the household fact base — Decision 1), `plan_cards` (per journey, FK → `profiles`), `plan_card_events`, `sessions` + `session_turns`, `audit_events`, `artifacts` |
| `002_audit_fill_path_two_path.sql` | Widens `audit_events.fill_path` CHECK to `{resolver, two_path, agent}` (the two-path fill added `two_path` — slice 2f) |
| `003_suburbs.sql` | The `suburb.*` reference surface: `suburbs` (SAL-keyed, **global — no `tenant_id`**, `facts_jsonb` metric set) + `suburb_sources` (per-feed license/redistribution register). Shared reference data, the third bucket — see [`suburb-data-foundation.md`](../../../../docs/architecture/suburb-data-foundation.md) |
| `004_plan_target_overlay.sql` | The `plan.target` overlay fields (Decision 1's plan-layer split) |
| `005_checklist_status.sql` | Checklist-status tracking columns |
| `006_mode_e.sql` | Widens `plan_cards.mode` CHECK to admit `'E'` (mode-e-wedge.md — 001's inline CHECK only anticipated the four modes known when it was authored) |
| `007_news_dismissed.sql` | `plan_cards.dismissed_news_jsonb` — per-card dismissed-news state (kb-update-runbook.md "authoring a news note"), the same card-user-set-layer pattern as 005 |
| `008_qa_conversation_bilingual.sql` | `session_turns` carries both locales, so the conversation-read endpoint returns a bilingual history |
| `009_reference_snapshots.sql` | `reference_snapshots` — the sha256 of the shipped reference snapshot a table last loaded, so the boot loader refreshes a filled `suburbs` only when the snapshot changes (behavior 37) |

Deferred to later migrations: the optional `properties` table (narrow-path
property data; addenda otherwise live in `plan_cards.content_jsonb` —
CLAUDE.md "Where to start building" 9).

## Applying

The runner is [`fh_engine_migrations`](../../src/fh_engine_migrations.erl). It runs
**at boot** inside `fh_engine_app:start/2`, *before* the supervision tree starts —
so a turn never runs against an unmigrated schema. Postgres ≥ 13 (uses
`gen_random_uuid()` via `pgcrypto` and `GENERATED ALWAYS AS IDENTITY`).

```
# dev: bring up Postgres, then boot the engine (which migrates)
docker compose -f engine/compose.yaml up -d
cd engine/erlang && rebar3 shell      # or release boot — start applies pending files
```

### Conventions the runner enforces

- **Forward-only, numbered.** Files applied in lexical order of the `NNN_` prefix.
- **No in-file `BEGIN`/`COMMIT`.** The runner wraps *each file* in a single
  `pgo:transaction`, so the file's statements **and** its `schema_migrations` row
  commit atomically or roll back together. An in-file transaction would fight the
  runner's (pgo binds a transaction to one pooled connection).
- **Version-tracked.** A `schema_migrations(version, filename, checksum, applied_at)`
  row per applied file; pending files are detected by version — already-applied
  files are skipped, not re-run.
- **Checksum forward-only guard.** If an already-applied file's bytes change, boot
  **aborts** (`migration_checksum_mismatch`). You add a new migration; you never
  edit an applied one.
- **Fail-closed.** Any migration error raises → application start aborts.

Statements are separated by a context-aware splitter (handles `'…'`, `"…"`,
`$tag$…$tag$`, `--` and `/* */`), so only a top-level `;` ends a statement.

> Verified end-to-end against the dev Docker Postgres: `001_init_engine.sql`
> applies (18 statements, one transaction), re-runs as a no-op, and the checksum
> guard aborts boot on a tampered file.
