#!/usr/bin/env escript
%%! -sname fh_usage_events_smoke
%%
%% Engine half of 8-S5b (the shell's pull-model outbox source). Boots the engine,
%% seeds a tenant + a plan card, hand-appends `usage` events (flat §9 payload, the
%% shape planner.py now emits) plus a non-usage event, and drives
%% GET /api/engine/usage_events?after=&limit= — asserting: only `type='usage'` rows
%% return, the flat token fields + usage_event_id ride through, the cursor advances,
%% the `after` filter pages correctly, and the endpoint is tenant-authenticated. No
%% LLM: usage events are seeded directly, so this is deterministic + opus-free.
%%
%%   ENGINE_DATABASE_URL=postgres://engine:engine_dev_pw@localhost:5433/firsthomey_engine?sslmode=disable \
%%   ERL_LIBS=_build/default/lib escript test/usage_events_smoke.escript

-mode(compile).

main(_) ->
    os:putenv("FH_ENGINE_HTTP_PORT", "8094"),
    {ok, _} = application:ensure_all_started(fh_engine),
    {ok, _} = application:ensure_all_started(inets),
    Base = "http://localhost:8094/api/engine",

    TenantId = fh_engine_util:uuid4(),
    UserId = fh_engine_util:uuid4(),
    {Pub, Priv} = crypto:generate_key(eddsa, ed25519),
    ok = fh_engine_store:upsert_tenant(TenantId, <<"usage-smoke">>),
    ok = fh_engine_store:add_signing_key(TenantId, <<"ed25519">>, base64:encode(Pub)),
    Auth = {"authorization", "Bearer " ++ binary_to_list(mint(TenantId, UserId, Priv))},

    {ok, ProfileId} = fh_engine_store:create_profile(TenantId, UserId, #{}),
    {ok, CardId} = fh_engine_store:create_plan_card(
        TenantId, ProfileId, <<"blueprints.fhb-domestic-au">>,
        <<"owner_occupier">>, <<"A">>, #{}),

    %% Two usage events (flat §9 shape, carrying user_id) + one non-usage event between.
    U1 = usage_payload(CardId, UserId, 2005, 2032, 33705, 38491),
    {ok, Id1} = fh_engine_store:append_event(TenantId, CardId, <<"usage">>, U1),
    {ok, _} = fh_engine_store:append_event(TenantId, CardId, <<"component_filled">>,
                  #{<<"component_id">> => <<"buyer_profile">>}),
    U2 = usage_payload(CardId, UserId, 2001, 979, 44018, 12857),
    {ok, Id2} = fh_engine_store:append_event(TenantId, CardId, <<"usage">>, U2),

    %% --- full tail: only the 2 usage rows, non-usage filtered, flat fields intact ---
    #{<<"events">> := Events, <<"count">> := Count, <<"cursor">> := Cursor} =
        get_usage(Base, Auth, 0, 200),
    expect(Count =:= 2, "only the 2 usage events returned (component_filled filtered)"),
    expect(Cursor =:= Id2, "cursor = last usage event_id"),
    [E1, E2] = Events,
    expect(maps:get(<<"usage_event_id">>, E1) =:= Id1, "event carries usage_event_id (cursor)"),
    expect(maps:get(<<"input_tokens">>, E1) =:= 2005
           andalso maps:get(<<"output_tokens">>, E1) =:= 2032
           andalso maps:get(<<"cache_read_tokens">>, E1) =:= 33705
           andalso maps:get(<<"cache_creation_tokens">>, E1) =:= 38491,
           "flat §9 token fields ride through verbatim"),
    expect(maps:get(<<"plan_card_id">>, E1) =:= CardId, "plan_card_id present"),
    expect(maps:get(<<"user_id">>, E1) =:= UserId, "user_id rides the event (§9 attribution)"),
    expect(maps:get(<<"source">>, E2) =:= <<"agent_sdk">>, "source present"),

    %% --- paging: after=Id1 yields only the 2nd usage event ---
    #{<<"events">> := [Only], <<"count">> := 1} = get_usage(Base, Auth, Id1, 200),
    expect(maps:get(<<"usage_event_id">>, Only) =:= Id2, "after=Id1 pages to the next usage event"),

    %% --- after=Id2 is the drained tail: empty, cursor echoes after ---
    #{<<"count">> := 0, <<"cursor">> := Id2} = get_usage(Base, Auth, Id2, 200),
    expect(true, "drained tail: empty result, cursor echoes `after`"),

    %% --- auth: no tenant JWT -> 401 ---
    {401, _} = raw_get(Base ++ "/usage_events?after=0&limit=200", []),
    expect(true, "no tenant JWT -> 401"),

    io:format("~nALL PASSED~n"),
    halt(0).

%% --- helpers ---

usage_payload(CardId, UserId, In, Out, CacheR, CacheC) ->
    #{<<"plan_card_id">> => CardId,
      <<"user_id">> => UserId,
      <<"turn_id">> => fh_engine_util:uuid4(),
      <<"source">> => <<"agent_sdk">>,
      <<"source_detail">> => <<"mortgage_finance">>,
      <<"model">> => <<"claude-opus-4-8">>,
      <<"input_tokens">> => In,
      <<"output_tokens">> => Out,
      <<"cache_read_tokens">> => CacheR,
      <<"cache_creation_tokens">> => CacheC}.

get_usage(Base, Auth, After, Limit) ->
    Url = Base ++ "/usage_events?after=" ++ integer_to_list(After)
          ++ "&limit=" ++ integer_to_list(Limit),
    {200, Body} = raw_get(Url, [Auth]),
    fh_engine_util:json_decode(Body).

raw_get(Url, Headers) ->
    {ok, {{_, Status, _}, _, Body}} =
        httpc:request(get, {Url, Headers}, [], [{body_format, binary}]),
    {Status, Body}.

mint(TenantId, UserId, Priv) ->
    Now = erlang:system_time(second),
    Claims = #{<<"tenant_id">> => TenantId, <<"user_id">> => UserId,
               <<"iat">> => Now, <<"exp">> => Now + 120},
    fh_engine_auth:sign(Claims, Priv).

expect(true, Label)  -> io:format("  ok  ~s~n", [Label]);
expect(false, Label) -> io:format("FAIL  ~s~n", [Label]), halt(1).
