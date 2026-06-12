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

-export([tenant_active_keys/1, upsert_tenant/2, add_signing_key/3]).
-export([create_profile/3, create_plan_card/6]).
-export([append_event/4, events_since/3]).
-export([append_audit/6]).
-export([snapshot_component/3, get_plan_card/2]).
-export([read_glue/3, append_session_turn/6]).

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

%% Events with event_id > LastEventId, in order → [{EventId, Type, PayloadMap}].
-spec events_since(binary(), binary(), integer()) -> [{integer(), binary(), map()}].
events_since(TenantId, PlanCardId, LastEventId) ->
    Res = query(
        "SELECT event_id, type, payload_jsonb FROM plan_card_events "
        "WHERE tenant_id = $1::uuid AND plan_card_id = $2::uuid AND event_id > $3 "
        "ORDER BY event_id ASC",
        [TenantId, PlanCardId, LastEventId]),
    [{Id, Type, decode_jsonb(Payload)} || {Id, Type, Payload} <- rows(Res)].

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

-spec get_plan_card(binary(), binary()) -> {ok, map()} | {error, not_found}.
get_plan_card(TenantId, PlanCardId) ->
    Res = query(
        "SELECT plan_card_id::text, blueprint_slug, intent, mode, status, content_jsonb "
        "FROM plan_cards WHERE tenant_id = $1::uuid AND plan_card_id = $2::uuid",
        [TenantId, PlanCardId]),
    case rows(Res) of
        [{Id, Bp, Intent, Mode, Status, Content}] ->
            {ok, #{
                <<"plan_card_id">> => Id,
                <<"blueprint_slug">> => Bp,
                <<"intent">> => Intent,
                <<"mode">> => Mode,
                <<"status">> => Status,
                <<"content">> => decode_jsonb(Content)
            }};
        [] ->
            {error, not_found}
    end.

%% --- Q&A conversation glue (sessions / session_turns; isolation-model §4) ----

%% The prior (user_text, assistant_text) pairs for this (user × plan card), oldest→
%% newest, bounded to a short recent window. GLUE for conversational coherence (pronoun
%% resolution), NOT agent grounding — the card re-grounds each turn (constraint #9,
%% agentic-flow §8). Empty list before the first Q&A turn.
-spec read_glue(binary(), binary(), binary()) -> [map()].
read_glue(TenantId, UserId, PlanCardId) ->
    Res = query(
        "SELECT st.user_text, st.assistant_text FROM session_turns st "
        "JOIN sessions s ON s.session_id = st.session_id "
        "WHERE s.tenant_id = $1::uuid AND s.user_id = $2::uuid "
        "  AND s.plan_card_id = $3::uuid "
        "ORDER BY st.ts ASC LIMIT 10",
        [TenantId, UserId, PlanCardId]),
    [#{<<"user_text">> => U, <<"assistant_text">> => A} || {U, A} <- rows(Res)].

%% Append one vendor-neutral glue pair after a Q&A turn's answer has been gated +
%% emitted. Ensures the (user × plan_card) session row first (session_id is one per
%% pair, engine-contract §9.1). Stores text only — never reasoning items / vendor format.
-spec append_session_turn(binary(), binary(), binary(), binary(), binary(), binary())
        -> ok.
append_session_turn(TenantId, UserId, PlanCardId, TurnId, UserText, AssistantText) ->
    _ = query(
        "INSERT INTO sessions (tenant_id, user_id, plan_card_id) "
        "VALUES ($1::uuid, $2::uuid, $3::uuid) "
        "ON CONFLICT (user_id, plan_card_id) DO NOTHING",
        [TenantId, UserId, PlanCardId]),
    _ = query(
        "INSERT INTO session_turns (turn_id, session_id, user_text, assistant_text) "
        "SELECT $1::uuid, s.session_id, $2, $3 FROM sessions s "
        "WHERE s.user_id = $4::uuid AND s.plan_card_id = $5::uuid",
        [TurnId, UserText, AssistantText, UserId, PlanCardId]),
    ok.

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
