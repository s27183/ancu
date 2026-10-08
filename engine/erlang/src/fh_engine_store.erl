-module(fh_engine_store).

%% Runtime-state data access over pgo (the mandated client). The engine is the SOT
%% for plan-card state and the typed-event log (engine-contract §9.1, principle 2);
%% every row is tenant-scoped (§3). jsonb values are passed as JSON text with an
%% explicit `$N::jsonb` cast and read back as raw JSON binaries (decoded in Erlang).
%%
%% UUID discipline: pgo decodes a `uuid` column to a raw 16-byte binary and cannot
%% re-bind one as a text param — so every id is READ back as `::text` (a 36-char
%% binary that round-trips cleanly) and every id param is BOUND with an explicit
%% `$N::uuid` cast (a `text` OID won't implicitly assign to a uuid column).

-export([tenant_active_keys/1, upsert_tenant/2, add_signing_key/3, ensure_signing_key/3]).
-export([create_profile/3, create_plan_card/6]).
-export([append_event/4, events_since/3, usage_events_since/3, max_event_id/2]).
-export([append_audit/6]).
-export([snapshot_component/3, get_plan_card/2, get_card_rerun_context/1, set_card_target/2]).
-export([attach_property/3, snapshot_addendum_component/4, set_transaction/3]).
-export([set_checklist_status/4, get_checklist_status/2]).
-export([card_kb_slugs/1, get_news_status/2, dismiss_news/2]).
-export([set_profile_financials/2, list_plan_card_ids_for_profile/1]).
-export([deploy_commit_sha/0, projection_state/1, list_active_plan_card_ids/0]).
-export([list_suburbs_by_state/1, list_all_suburbs/0, list_suburb_sources/0]).
-export([read_glue/3, append_session_turn/6, read_conversation/3]).

%% --- tenancy / auth ---------------------------------------------------------

%% Active signing keys for a tenant → [{Algo, PubKeyBin}]. PubKey stored base64.
-spec tenant_active_keys(binary()) -> [{binary(), binary()}].
tenant_active_keys(TenantId) ->
    Res = query(
        "SELECT algo, public_key FROM tenant_signing_keys "
        "WHERE tenant_id = $1::uuid AND status = 'active'",
        [TenantId]),
    [{Algo, PubB64} || {Algo, PubB64} <- rows(Res)].

-spec upsert_tenant(binary(), binary()) -> ok.
upsert_tenant(TenantId, Name) ->
    _ = query(
        "INSERT INTO tenants (tenant_id, name) VALUES ($1::uuid, $2) "
        "ON CONFLICT (tenant_id) DO NOTHING",
        [TenantId, Name]),
    ok.

-spec add_signing_key(binary(), binary(), binary()) -> ok.
add_signing_key(TenantId, Algo, PubKeyB64) ->
    _ = query(
        "INSERT INTO tenant_signing_keys (tenant_id, public_key, algo) "
        "VALUES ($1::uuid, $2, $3)",
        [TenantId, PubKeyB64, Algo]),
    ok.

%% Idempotent variant for the dev-provision handshake: insert only if this tenant
%% does not already have this exact public key active. Lets the shell re-register on
%% every dev boot without the engine accumulating duplicate rows for a stable key.
-spec ensure_signing_key(binary(), binary(), binary()) -> ok.
ensure_signing_key(TenantId, Algo, PubKeyB64) ->
    _ = query(
        "INSERT INTO tenant_signing_keys (tenant_id, public_key, algo) "
        "SELECT $1::uuid, $2, $3 WHERE NOT EXISTS ("
        "  SELECT 1 FROM tenant_signing_keys "
        "  WHERE tenant_id = $1::uuid AND public_key = $2 AND status = 'active')",
        [TenantId, PubKeyB64, Algo]),
    ok.

%% --- fact base / plan cards -------------------------------------------------

%% One household fact base per call (Wedge 1 creates fresh; accumulation is Wedge 2).
-spec create_profile(binary(), binary(), map()) -> {ok, binary()}.
create_profile(TenantId, UserId, Facts) ->
    Res = query(
        "INSERT INTO profiles (tenant_id, user_id, facts_jsonb) "
        "VALUES ($1::uuid, $2::uuid, $3::jsonb) RETURNING profile_id::text",
        [TenantId, UserId, fh_engine_util:json_encode(Facts)]),
    {ok, single(Res)}.

-spec create_plan_card(binary(), binary(), binary(), binary(), binary(), map())
    -> {ok, binary()}.
create_plan_card(TenantId, ProfileId, BlueprintSlug, Intent, Mode, Content) ->
    Res = query(
        "INSERT INTO plan_cards "
        "(tenant_id, profile_id, blueprint_slug, intent, mode, deploy_commit_sha, content_jsonb) "
        "VALUES ($1::uuid, $2::uuid, $3, $4, $5, $6, $7::jsonb) RETURNING plan_card_id::text",
        [TenantId, ProfileId, BlueprintSlug, Intent, Mode,
         deploy_commit_sha(), fh_engine_util:json_encode(Content)]),
    {ok, single(Res)}.

%% --- event log (SOT for Last-Event-ID replay, §4) ---------------------------

%% Append one typed event; returns its monotonic event_id. The stored payload is the
%% FULL event body the SSE layer streams (so replay and live frames are identical).
-spec append_event(binary(), binary(), binary(), map()) -> {ok, integer()}.
append_event(TenantId, PlanCardId, Type, Payload) ->
    Res = query(
        "INSERT INTO plan_card_events (tenant_id, plan_card_id, type, payload_jsonb) "
        "VALUES ($1::uuid, $2::uuid, $3, $4::jsonb) RETURNING event_id",
        [TenantId, PlanCardId, Type, fh_engine_util:json_encode(Payload)]),
    {ok, single(Res)}.

%% The card's latest event_id — the "as-of" cursor for a GET snapshot. A client that
%% subscribes to the SSE with this as Last-Event-ID replays only events AFTER the snapshot
%% (none for a settled card; a running turn's new events live) — so a stale OLD turn in the
%% append-only log can't be replayed over the fresh snapshot (plan-card-refresh.md / the
%% multi-turn replay fix). 0 when the card has no events yet.
-spec max_event_id(binary(), binary()) -> integer().
max_event_id(TenantId, PlanCardId) ->
    single(query(
        "SELECT COALESCE(MAX(event_id), 0) FROM plan_card_events "
        "WHERE tenant_id = $1::uuid AND plan_card_id = $2::uuid",
        [TenantId, PlanCardId])).

%% Events with event_id > LastEventId, in order → [{EventId, Type, PayloadMap}].
-spec events_since(binary(), binary(), integer()) -> [{integer(), binary(), map()}].
events_since(TenantId, PlanCardId, LastEventId) ->
    Res = query(
        "SELECT event_id, type, payload_jsonb FROM plan_card_events "
        "WHERE tenant_id = $1::uuid AND plan_card_id = $2::uuid AND event_id > $3 "
        "ORDER BY event_id ASC",
        [TenantId, PlanCardId, LastEventId]),
    [{Id, Type, decode_jsonb(Payload)} || {Id, Type, Payload} <- rows(Res)].

%% Tenant-wide `usage` event tail for the shell's pull-model outbox (billing.md §2,
%% engine-contract §9). Returns this TENANT's usage events with event_id > Cursor, in
%% order, capped at Limit → [{EventId, PayloadMap}]. Unlike events_since/3 this is NOT
%% scoped to one plan card: the shell mirrors ALL of its tenant's usage (the meter is
%% tenant/user-wide). event_id is the bigint IDENTITY → the consumer's cursor.
-spec usage_events_since(binary(), integer(), pos_integer()) -> [{integer(), map()}].
usage_events_since(TenantId, Cursor, Limit) ->
    Res = query(
        "SELECT event_id, payload_jsonb FROM plan_card_events "
        "WHERE tenant_id = $1::uuid AND type = 'usage' AND event_id > $2 "
        "ORDER BY event_id ASC LIMIT $3",
        [TenantId, Cursor, Limit]),
    [{Id, decode_jsonb(Payload)} || {Id, Payload} <- rows(Res)].

%% --- compliance audit trail (compliance-pipeline.md §5) ---------------------

%% One audit_events row per (component, gate), written REGARDLESS of disposition — a
%% `clear` is as much the regulated trail as a `block` ("we checked FIRB, not required,
%% on this KB version, at this commit" is exactly the auditor's record). Attribution,
%% never cost: no token/price fields ever live here (metering is the `usage` stream, §1).
%% deploy_commit_sha is stamped engine-side for reproducibility (constraint #6).
-spec append_audit(binary(), binary(), binary(), binary(), [map()], map()) -> ok.
append_audit(TenantId, PlanCardId, ComponentId, FillPath, KbVersions, Compliance) ->
    _ = query(
        "INSERT INTO audit_events "
        "(tenant_id, plan_card_id, component_id, fill_path, kb_versions_jsonb, "
        " compliance_jsonb, deploy_commit_sha) "
        "VALUES ($1::uuid, $2::uuid, $3, $4, $5::jsonb, $6::jsonb, $7)",
        [TenantId, PlanCardId, ComponentId, FillPath,
         fh_engine_util:json_encode(KbVersions),
         fh_engine_util:json_encode(Compliance),
         deploy_commit_sha()]),
    ok.

%% --- plan-card content snapshot ---------------------------------------------

%% Merge a filled component's outcome into content_jsonb under components.<id>.
%% jsonb_set with create_missing=true; the `components` object is created on first
%% fill via coalesce.
-spec snapshot_component(binary(), binary(), map()) -> ok.
snapshot_component(PlanCardId, ComponentId, OutcomeEntry) ->
    _ = query(
        "UPDATE plan_cards SET "
        "content_jsonb = jsonb_set("
        "  CASE WHEN content_jsonb ? 'components' THEN content_jsonb "
        "       ELSE jsonb_set(content_jsonb, '{components}', '{}'::jsonb, true) END, "
        "  ARRAY['components', $2], $3::jsonb, true), "
        "updated_at = now() "
        "WHERE plan_card_id = $1::uuid",
        [PlanCardId, ComponentId, fh_engine_util:json_encode(OutcomeEntry)]),
    ok.

%% --- per-property addenda (Phase B, constraint #2 base + addenda) ------------

%% Attach a property to a plan card: create/refresh the addendum's property_card under
%% content.addenda.<property_id>, preserving any components already filled there. This
%% ESTABLISHES the addenda.<pid>.components object the per-property turn snapshots into —
%% so it MUST run before the Phase-B turn (the attach handler enforces the order). Addenda
%% are a SIBLING namespace to the base content.components (so the base refresh/rerun sweep,
%% which touches only components.*, leaves addenda untouched — the existing
%% per-property-addenda-preserved reservation, now literal). No new table: addenda live in
%% the same plan_cards row (properties is "OPTIONAL — not load-bearing", CLAUDE.md item 1).
-spec attach_property(binary(), binary(), map()) -> ok.
attach_property(PlanCardId, PropertyId, PropertyCard) ->
    _ = query(
        "UPDATE plan_cards SET "
        "content_jsonb = jsonb_set("
        "  CASE WHEN content_jsonb ? 'addenda' THEN content_jsonb "
        "       ELSE jsonb_set(content_jsonb, '{addenda}', '{}'::jsonb, true) END, "
        "  ARRAY['addenda', $2], "
        "  jsonb_build_object('property_card', $3::jsonb, 'components', "
        "    COALESCE(content_jsonb #> ARRAY['addenda', $2, 'components'], '{}'::jsonb)), "
        "  true), "
        "updated_at = now() "
        "WHERE plan_card_id = $1::uuid",
        [PlanCardId, PropertyId, fh_engine_util:json_encode(PropertyCard)]),
    ok.

%% Merge a filled per-property component's outcome into content.addenda.<pid>.components.<cid>
%% — the addendum sibling of snapshot_component/3. The parent addenda.<pid>.components object
%% is guaranteed by a prior attach_property/3 (which runs before the per-property turn), so a
%% plain jsonb_set with create_missing on the leaf suffices.
-spec snapshot_addendum_component(binary(), binary(), binary(), map()) -> ok.
snapshot_addendum_component(PlanCardId, PropertyId, ComponentId, OutcomeEntry) ->
    _ = query(
        "UPDATE plan_cards SET "
        "content_jsonb = jsonb_set(content_jsonb, "
        "  ARRAY['addenda', $2, 'components', $3], $4::jsonb, true), "
        "updated_at = now() "
        "WHERE plan_card_id = $1::uuid",
        [PlanCardId, PropertyId, ComponentId, fh_engine_util:json_encode(OutcomeEntry)]),
    ok.

%% Write the user-attested transaction facts into content.addenda.<pid>.transaction — the THIRD
%% per-property input layer (sibling of property_card + components; engine-contract §11,
%% `<from_transaction>`). The addendum object is guaranteed by a prior attach_property/3 (the
%% handler verifies the property is attached → 409 otherwise), so a plain jsonb_set with
%% create_missing on the leaf suffices. A re-submit overwrites; a later `<from_document>`
%% extraction writes the SAME slot.
-spec set_transaction(binary(), binary(), map()) -> ok.
set_transaction(PlanCardId, PropertyId, Transaction) ->
    _ = query(
        "UPDATE plan_cards SET "
        "content_jsonb = jsonb_set(content_jsonb, "
        "  ARRAY['addenda', $2, 'transaction'], $3::jsonb, true), "
        "updated_at = now() "
        "WHERE plan_card_id = $1::uuid",
        [PlanCardId, PropertyId, fh_engine_util:json_encode(Transaction)]),
    ok.

-spec get_plan_card(binary(), binary()) -> {ok, map()} | {error, not_found}.
get_plan_card(TenantId, PlanCardId) ->
    Res = query(
        "SELECT plan_card_id::text, blueprint_slug, intent, mode, status, "
        "       content_jsonb, checklist_status_jsonb "
        "FROM plan_cards WHERE tenant_id = $1::uuid AND plan_card_id = $2::uuid",
        [TenantId, PlanCardId]),
    case rows(Res) of
        [{Id, Bp, Intent, Mode, Status, Content, Checklist}] ->
            {ok, #{
                <<"plan_card_id">> => Id,
                <<"blueprint_slug">> => Bp,
                <<"intent">> => Intent,
                <<"mode">> => Mode,
                <<"status">> => Status,
                <<"content">> => decode_jsonb(Content),
                %% The card user-set layer (005) returned as a SIBLING of content,
                %% never merged into it: content is the computed snapshot (the SSE
                %% replay streams it raw), and attaching a user's own status flag to
                %% a checklist row is a render-time overlay, not a recompute. The
                %% client overlays this onto the current phase_playbook actions;
                %% '{}' (untouched card) reads as every action `not_started`.
                <<"checklist_status">> => decode_jsonb(Checklist)
            }};
        [] ->
            {error, not_found}
    end.

%% Reconstruct the base-turn inputs for an existing card (plan-card-refresh.md): join
%% the card to its profile so a re-run recomputes against the CURRENT profile facts +
%% the card's own mode/intent. Looked up by plan_card_id alone — the DEV re-run trust
%% model (the recompute is still tenant-scoped via the returned tenant_id). The returned
%% deploy_commit_sha is the card's creation SHA (the drift signal vs deploy_commit_sha/0).
-spec get_card_rerun_context(binary()) -> {ok, map()} | {error, not_found}.
get_card_rerun_context(PlanCardId) ->
    Res = query(
        "SELECT pc.tenant_id::text, pr.user_id::text, pc.mode, pc.intent, "
        "       pc.blueprint_slug, pc.status, pc.deploy_commit_sha, pr.facts_jsonb, "
        "       pc.target_jsonb "
        "FROM plan_cards pc JOIN profiles pr ON pr.profile_id = pc.profile_id "
        "WHERE pc.plan_card_id = $1::uuid",
        [PlanCardId]),
    case rows(Res) of
        [{Tenant, User, Mode, Intent, Bp, Status, Sha, Facts, Target}] ->
            {ok, #{tenant_id => Tenant, user_id => User, mode => Mode,
                   intent => Intent, blueprint_slug => Bp, status => Status,
                   deploy_commit_sha => Sha,
                   facts => overlay_target(decode_jsonb(Facts), decode_jsonb(Target))}};
        [] ->
            {error, not_found}
    end.

%% The plan-target overlay (lifecycle-simulation-model §4.3 / W7b). A non-empty overlay
%% (a saved refine scenario) is the card's CURRENT target — it fully supersedes the
%% profile onboarding for the recompute, so a refresh/refine/preview re-derives from the
%% saved scenario, not stale profile facts. Empty '{}' (every card before its first
%% refine) → the profile onboarding is used unchanged. The overlay holds the FULL
%% effective onboarding the refine wrote, so a `state` save's stripped pin stays stripped
%% (no patch-deletion semantics).
-spec overlay_target(map(), map()) -> map().
overlay_target(Facts, Target) when map_size(Target) > 0 ->
    Facts#{<<"onboarding">> => Target};
overlay_target(Facts, _Target) ->
    Facts.

%% Persist a refine's chosen scenario — the FULL effective onboarding — to the card's
%% plan-target overlay (W7b). target_* is a PLAN fact, so it lands on the card, never the
%% profile (which a sibling journey would share). Written AFTER the turn is reserved (so a
%% 409 never mutates the target); the turn itself reads its onboarding from its start args,
%% not from this column, so the write order vs the async turn is immaterial.
-spec set_card_target(binary(), map()) -> ok.
set_card_target(PlanCardId, Onboarding) ->
    _ = query(
        "UPDATE plan_cards SET target_jsonb = $2::jsonb, updated_at = now() "
        "WHERE plan_card_id = $1::uuid",
        [PlanCardId, fh_engine_util:json_encode(Onboarding)]),
    ok.

%% IC4 — write the household financial facts to the profiles SOT (the canonical
%% `household_financials` key, fact-model-unification.md). Reached via the addressed
%% plan card's profile (the handler's prior get_plan_card/2 enforces tenant-scope, so the
%% join keys on plan_card_id alone). FULL-REPLACE of the one key (the Budget cockpit owns
%% the full financials state and submits it whole — the set_card_target precedent, no
%% patch-deletion semantics); `onboarding`/`derived` are untouched. Returns the profile_id
%% so the caller can sweep every SIBLING journey that derives from this shared fact base
%% (a saved card is a computed SNAPSHOT — a changed input must re-derive all snapshots,
%% the same invariant the refresh sweep maintains for an artifact rebuild). {error,
%% not_found} if the card (hence profile) does not exist.
-spec set_profile_financials(binary(), map()) -> {ok, binary()} | {error, not_found}.
set_profile_financials(PlanCardId, HouseholdFinancials) ->
    Res = query(
        "UPDATE profiles p "
        "SET facts_jsonb = jsonb_set(p.facts_jsonb, '{household_financials}', $2::jsonb, true), "
        "    updated_at = now() "
        "FROM plan_cards pc "
        "WHERE pc.plan_card_id = $1::uuid AND pc.profile_id = p.profile_id "
        "RETURNING p.profile_id::text",
        [PlanCardId, fh_engine_util:json_encode(HouseholdFinancials)]),
    case rows(Res) of
        [{ProfileId}] -> {ok, ProfileId};
        []            -> {error, not_found}
    end.

%% IC4 — every active (non-retired) plan card on a profile: the bounded sibling set a
%% profile-fact write must refresh (a household has few journeys, so this is bounded by
%% construction, unlike the global list_active_plan_card_ids/0 fleet sweep).
-spec list_plan_card_ids_for_profile(binary()) -> [binary()].
list_plan_card_ids_for_profile(ProfileId) ->
    [Id || {Id} <- rows(query(
        "SELECT plan_card_id::text FROM plan_cards "
        "WHERE profile_id = $1::uuid AND status IS DISTINCT FROM 'retired'",
        [ProfileId]))].

%% The checklist-status slice of the card user-set layer (005). A toggle is a small
%% patch on the sparse map {"<phase>": {"<action_id>": "done"}}, with NO recompute and
%% NO `usage` (zero-cost user attestation). `done` sets the leaf (creating the phase
%% object on first tick via the same coalesce trick as snapshot_component); any other
%% status REMOVES the key (#- path), so an "untick" returns the action to the seed
%% `not_started` and the column stays sparse (no patch-deletion semantics on read).
%% Returns the FULL updated map (RETURNING — one round trip) so the caller can reply
%% with the reconciled state. Tenant-scope is enforced by the handler's prior
%% get_plan_card/2 ownership check, so the UPDATE keys on plan_card_id alone.
-spec set_checklist_status(binary(), binary(), binary(), binary()) -> {ok, map()}.
set_checklist_status(PlanCardId, Phase, ActionId, <<"done">>) ->
    Res = query(
        "UPDATE plan_cards SET "
        "checklist_status_jsonb = jsonb_set("
        "  CASE WHEN checklist_status_jsonb ? $2 THEN checklist_status_jsonb "
        "       ELSE jsonb_set(checklist_status_jsonb, ARRAY[$2], '{}'::jsonb, true) END, "
        "  ARRAY[$2, $3], $4::jsonb, true), "
        "updated_at = now() "
        "WHERE plan_card_id = $1::uuid "
        "RETURNING checklist_status_jsonb",
        [PlanCardId, Phase, ActionId, fh_engine_util:json_encode(<<"done">>)]),
    {ok, decode_jsonb(single(Res))};
set_checklist_status(PlanCardId, Phase, ActionId, _NotStarted) ->
    Res = query(
        "UPDATE plan_cards SET "
        "checklist_status_jsonb = checklist_status_jsonb #- ARRAY[$2, $3], "
        "updated_at = now() "
        "WHERE plan_card_id = $1::uuid "
        "RETURNING checklist_status_jsonb",
        [PlanCardId, Phase, ActionId]),
    {ok, decode_jsonb(single(Res))}.

-spec get_checklist_status(binary(), binary()) -> {ok, map()} | {error, not_found}.
get_checklist_status(TenantId, PlanCardId) ->
    Res = query(
        "SELECT checklist_status_jsonb FROM plan_cards "
        "WHERE tenant_id = $1::uuid AND plan_card_id = $2::uuid",
        [TenantId, PlanCardId]),
    case rows(Res) of
        [{Checklist}] -> {ok, decode_jsonb(Checklist)};
        []            -> {error, not_found}
    end.

%% --- news relevance + dismissed state (kb-update-runbook.md "authoring a news
%% note", plan-card-refresh.md kb_versions provenance) -----------------------

%% Every KB slug consulted across this card's fills, deduped — the relevance-
%% filter input fh_engine_kb:news_for_slugs/1 intersects against each news
%% note's affected_kb_slugs. No tenant filter here (plan_card_id is globally
%% unique); the caller enforces ownership via get_news_status/2 first.
%% Generic over any slug in audit_events.kb_versions_jsonb: a new news topic needs only a
%% KB doc the card's fills anchor and a note naming it in affected_kb_slugs — no change
%% here or in the pipeline (concluded 2026-10-08 from reading this query).
-spec card_kb_slugs(binary()) -> [binary()].
card_kb_slugs(PlanCardId) ->
    Res = query(
        "SELECT DISTINCT elem->>'slug' AS slug FROM audit_events, "
        "  LATERAL jsonb_array_elements(kb_versions_jsonb) AS elem "
        "WHERE plan_card_id = $1::uuid",
        [PlanCardId]),
    [Slug || {Slug} <- rows(Res), is_binary(Slug)].

%% The dismissed-news slice of the card user-set layer (007, same pattern as
%% checklist_status): {"<news_slug>": true}. Tenant-scoped — the ownership
%% check for the whole news read (GET .../news calls this first).
-spec get_news_status(binary(), binary()) -> {ok, map()} | {error, not_found}.
get_news_status(TenantId, PlanCardId) ->
    Res = query(
        "SELECT dismissed_news_jsonb FROM plan_cards "
        "WHERE tenant_id = $1::uuid AND plan_card_id = $2::uuid",
        [TenantId, PlanCardId]),
    case rows(Res) of
        [{Dismissed}] -> {ok, decode_jsonb(Dismissed)};
        []            -> {error, not_found}
    end.

%% Mark one news note dismissed for a card. One-way (no "undismiss" surfaced —
%% no product need for it yet); the same jsonb_set-with-create-missing pattern
%% as set_checklist_status/4's "done" clause. Tenant-scope is enforced by the
%% handler's prior get_news_status/2 ownership check, so the UPDATE keys on
%% plan_card_id alone.
-spec dismiss_news(binary(), binary()) -> {ok, map()}.
dismiss_news(PlanCardId, NewsSlug) ->
    Res = query(
        "UPDATE plan_cards SET "
        "dismissed_news_jsonb = jsonb_set(dismissed_news_jsonb, ARRAY[$2], 'true'::jsonb, true), "
        "updated_at = now() "
        "WHERE plan_card_id = $1::uuid "
        "RETURNING dismissed_news_jsonb",
        [PlanCardId, NewsSlug]),
    {ok, decode_jsonb(single(Res))}.

%% The PROJECTION state for the base plan (eligibility-resolution.md 2026-06-17 / G4):
%% state-specific schemes resolve from the SUBURB being planned, not the map browse-
%% filter `onboarding.state` (which may be "ALL"). Precedence, most-specific first:
%%   1. `target_sal`  — the pinned suburb's SAL (shell precision) → suburbs.state.
%%   2. `target_zone` — the zone's first suburb NAME → suburbs.state (a single state;
%%      ambiguous name across states → undefined, never a guess).
%%   3. `state`       — an explicit single-state filter the user chose (a real state,
%%      never the "ALL" sentinel) → used when no suburb pins the state.
%%   4. undefined     — no single state determinable → caller omits the state slice
%%      (fail-honest), never a wrong default.
%% Steps 1-2 hit the DB only when a SAL/zone is present; step 3 is pure (so the no-PG
%% conformance, which passes `state` directly, needs no database).
-spec projection_state(map()) -> binary() | undefined.
projection_state(Onboarding) ->
    case sal_state(maps:get(<<"target_sal">>, Onboarding, undefined)) of
        undefined ->
            case zone_state(maps:get(<<"target_zone">>, Onboarding, [])) of
                undefined -> explicit_state(maps:get(<<"state">>, Onboarding, undefined));
                S         -> S
            end;
        S -> S
    end.

%% Active plan cards for the refresh sweep (plan-card-refresh.md). Coarse scope (all
%% non-retired); provenance-driven targeting (SHA/slug/blueprint) is a later refinement.
-spec list_active_plan_card_ids() -> [binary()].
list_active_plan_card_ids() ->
    [Id || {Id} <- rows(query(
        "SELECT plan_card_id::text FROM plan_cards "
        "WHERE status IS DISTINCT FROM 'retired'", []))].

sal_state(Sal) when is_binary(Sal) ->
    case rows(query("SELECT state FROM suburbs WHERE sal_code = $1", [Sal])) of
        [{S}] -> S;
        _     -> undefined
    end;
sal_state(_) -> undefined.

zone_state([Name | _]) when is_binary(Name) ->
    %% DISTINCT so a single state resolves even with several SAL rows; >1 (name reused
    %% across states) or 0 → undefined.
    case rows(query("SELECT DISTINCT state FROM suburbs WHERE name = $1", [Name])) of
        [{S}] -> S;
        _     -> undefined
    end;
zone_state(_) -> undefined.

explicit_state(S) when is_binary(S), S =/= <<"ALL">>, S =/= <<>> -> S;
explicit_state(_) -> undefined.

%% --- suburb reference surface (the shell map's raw-metric source) ------------
%%
%% GLOBAL reference data, NOT tenant-scoped: `suburbs` carries no tenant_id and a
%% WHERE tenant_id filter here would be a category error (suburb-data-foundation §1).
%% The handler still AUTHENTICATES the tenant JWT (a registered shell), but the row
%% selection is tenant-independent. This serves the MAP's raw projection (§2 "two
%% readers": shell renders the raw metrics; the resolver's coarse suburb.* band is a
%% separate internal <from_suburb> path). facts_jsonb is passed through verbatim —
%% the table is the superset, the shell decides what to render (§2/§4).
-spec list_suburbs_by_state(binary()) -> [map()].
list_suburbs_by_state(State) ->
    suburb_rows(query(
        "SELECT sal_code, name, state, lga_name, is_capital_city, "
        "centroid_lat, centroid_lon, facts_jsonb "
        "FROM suburbs WHERE state = $1 ORDER BY name",
        [State])).

%% The "ALL" map scope — every state in one payload. `suburbs` is global reference
%% data (no tenant filter), so this is just the by-state query without the WHERE.
-spec list_all_suburbs() -> [map()].
list_all_suburbs() ->
    suburb_rows(query(
        "SELECT sal_code, name, state, lga_name, is_capital_city, "
        "centroid_lat, centroid_lon, facts_jsonb "
        "FROM suburbs ORDER BY state, name",
        [])).

suburb_rows(Res) ->
    [#{<<"sal_code">> => Sal,
       <<"name">> => Name,
       <<"state">> => St,
       <<"lga_name">> => Lga,
       <<"is_capital_city">> => Cap,
       <<"centroid">> => centroid(Lat, Lon),
       <<"facts">> => decode_jsonb(Facts)}
     || {Sal, Name, St, Lga, Cap, Lat, Lon, Facts} <- rows(Res)].

%% The source/license register (suburb_sources) → the attribution block the map's
%% attribution strip must render wherever a CC-BY layer shows (§6.1).
-spec list_suburb_sources() -> [map()].
list_suburb_sources() ->
    Res = query(
        "SELECT source_id, name, publisher, license, attribution "
        "FROM suburb_sources ORDER BY source_id", []),
    [#{<<"source_id">> => Id,
       <<"name">> => Name,
       <<"publisher">> => Pub,
       <<"license">> => Lic,
       <<"attribution">> => Attr}
     || {Id, Name, Pub, Lic, Attr} <- rows(Res)].

%% NULL centroid (the 16 non-geographic pseudo-localities, §6) → JSON null, not a
%% {lat:null,lon:null} object — an absent location is absent, not a zero point.
centroid(null, _) -> null;
centroid(_, null) -> null;
centroid(Lat, Lon) -> #{<<"lat">> => Lat, <<"lon">> => Lon}.

%% --- Q&A conversation glue (sessions / session_turns; isolation-model §4) ----

%% The prior (user_text, assistant_text_en) pairs for this (user × plan card), oldest→
%% newest, bounded to a short recent window. GLUE for conversational coherence (pronoun
%% resolution), NOT agent grounding — the card re-grounds each turn (constraint #9,
%% agentic-flow §8). EN-only on purpose: this text only ever reaches the prompt, never
%% the user, so bilingual storage buys nothing here (unlike read_conversation/3 below).
%% Empty list before the first Q&A turn.
-spec read_glue(binary(), binary(), binary()) -> [map()].
read_glue(TenantId, UserId, PlanCardId) ->
    Res = query(
        "SELECT st.user_text, st.assistant_text_en FROM session_turns st "
        "JOIN sessions s ON s.session_id = st.session_id "
        "WHERE s.tenant_id = $1::uuid AND s.user_id = $2::uuid "
        "  AND s.plan_card_id = $3::uuid "
        "ORDER BY st.ts ASC LIMIT 10",
        [TenantId, UserId, PlanCardId]),
    [#{<<"user_text">> => U, <<"assistant_text">> => A} || {U, A} <- rows(Res)].

%% Append one turn after a Q&A turn's answer has been gated + emitted. Ensures the
%% (user × plan_card) session row first (session_id is one per pair, engine-contract
%% §9.1). `Answer` is the full bilingual {vi, en} map (commit_qa already has it in
%% hand) — persisted in BOTH locales so read_conversation/3 can hand the shell a real
%% history (bilingual-content.md: VI is co-equal, forced by schema at the source).
%% Stores text only — never reasoning items / vendor format.
-spec append_session_turn(binary(), binary(), binary(), binary(), binary(), map())
        -> ok.
append_session_turn(TenantId, UserId, PlanCardId, TurnId, UserText, Answer) ->
    AssistantEn = maps:get(<<"en">>, Answer, <<"">>),
    AssistantVi = maps:get(<<"vi">>, Answer, <<"">>),
    _ = query(
        "INSERT INTO sessions (tenant_id, user_id, plan_card_id) "
        "VALUES ($1::uuid, $2::uuid, $3::uuid) "
        "ON CONFLICT (user_id, plan_card_id) DO NOTHING",
        [TenantId, UserId, PlanCardId]),
    _ = query(
        "INSERT INTO session_turns "
        "  (turn_id, session_id, user_text, assistant_text_en, assistant_text_vi) "
        "SELECT $1::uuid, s.session_id, $2, $3, $4 FROM sessions s "
        "WHERE s.user_id = $5::uuid AND s.plan_card_id = $6::uuid",
        [TurnId, UserText, AssistantEn, AssistantVi, UserId, PlanCardId]),
    ok.

%% The full Q&A conversation for this (user × plan card), oldest→newest, UNCAPPED —
%% the shell-facing history read (GET .../conversation, fh_engine_h_conversation),
%% distinct from read_glue/3's capped internal-coherence read above. Each turn's
%% answer is bilingual {vi, en}; the shell picks display language same as text_delta.
%% Empty list before the first Q&A turn.
-spec read_conversation(binary(), binary(), binary()) -> [map()].
read_conversation(TenantId, UserId, PlanCardId) ->
    Res = query(
        "SELECT st.turn_id::text, st.user_text, "
        "  st.assistant_text_en, st.assistant_text_vi, "
        "  to_char(st.ts AT TIME ZONE 'UTC', 'YYYY-MM-DD\"T\"HH24:MI:SS\"Z\"') "
        "FROM session_turns st "
        "JOIN sessions s ON s.session_id = st.session_id "
        "WHERE s.tenant_id = $1::uuid AND s.user_id = $2::uuid "
        "  AND s.plan_card_id = $3::uuid "
        "ORDER BY st.ts ASC",
        [TenantId, UserId, PlanCardId]),
    [#{<<"turn_id">> => Tid, <<"user_text">> => U,
       <<"answer">> => #{<<"en">> => En, <<"vi">> => Vi},
       <<"ts">> => Ts}
     || {Tid, U, En, Vi, Ts} <- rows(Res)].

%% --- internals --------------------------------------------------------------

-spec query(string(), list()) -> map().
query(SQL, Params) ->
    case pgo:query(SQL, Params) of
        #{command := _} = R -> R;
        {error, Err} -> error({pg_query_failed, Err, SQL})
    end.

-spec rows(map()) -> [tuple()].
rows(#{rows := Rows}) -> Rows;
rows(_) -> [].

%% RETURNING a single column from a single row.
-spec single(map()) -> term().
single(#{rows := [{Val}]}) -> Val.

%% pgo returns jsonb columns as raw JSON binaries; decode to a map.
-spec decode_jsonb(binary() | map()) -> map().
decode_jsonb(Bin) when is_binary(Bin) -> fh_engine_util:json_decode(Bin);
decode_jsonb(Map) when is_map(Map) -> Map.

%% The deploy commit SHA stamped on each plan card (audit/reproducibility,
%% architecture §11.9). For the dev seam it reads FH_DEPLOY_COMMIT_SHA or 'dev'.
-spec deploy_commit_sha() -> binary().
deploy_commit_sha() ->
    case os:getenv("FH_DEPLOY_COMMIT_SHA") of
        false -> <<"dev">>;
        Sha -> list_to_binary(Sha)
    end.
