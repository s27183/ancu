#!/usr/bin/env escript
%%! -sname fh_simulate_http_smoke
%%
%% Live-PG HTTP smoke for the simulate PREVIEW surface (engine-contract §10.1). W7 proved
%% the pure walk below the seam (simulate_smoke, no-PG) but left the HTTP path unexercised
%% against live PG; W9 makes the response SHAPE load-bearing (the shell merges the body by
%% component_id), so this closes that gap by driving the real authenticated HTTP endpoint
%% and asserting what only the wire shows: a 200 whose `outcomes` are keyed by COMPONENT_ID
%% (matching the committed snapshot), that an override flows through, and that NOTHING
%% persists (no event, no usage — it is a preview).
%%
%% SIDECAR-FREE (resolver-only), like refine_smoke: the card is SEEDED directly in PG (a
%% real create would run a full base turn needing the Python planner). Run from
%% engine/erlang with PG up (engine/compose.yaml :5433, or the brew :5432 fallback):
%%   ENGINE_DATABASE_URL=postgres://engine:engine_dev_pw@localhost:5433/ancu_engine?sslmode=disable \
%%   ENGINE_DEV_PROVISION=0 ERL_LIBS=_build/default/lib escript test/simulate_http_smoke.escript

-mode(compile).

main(_) ->
    os:putenv("FH_ENGINE_HTTP_PORT", "8093"),
    {ok, _} = application:ensure_all_started(fh_engine),
    {ok, _} = application:ensure_all_started(inets),
    Base = "http://localhost:8093/api/engine",
    io:format("simulate HTTP smoke — W9 preview surface (live PG, sidecar-free)~n~n"),

    %% --- seed tenant + ed25519 key, mint a JWT (the shell's role) ---
    TenantId = fh_engine_util:uuid4(),
    UserId = fh_engine_util:uuid4(),
    {Pub, Priv} = crypto:generate_key(eddsa, ed25519),
    ok = fh_engine_store:upsert_tenant(TenantId, <<"simulate-http-smoke">>),
    ok = fh_engine_store:add_signing_key(TenantId, <<"ed25519">>, base64:encode(Pub)),
    Auth = {"authorization", "Bearer " ++ binary_to_list(mint(TenantId, UserId, Priv))},

    %% --- seed a card directly (bypass the create turn → no sidecar) ---
    SeedOnboarding = #{<<"state">> => <<"NSW">>,
                       <<"target_price_range">> => [600000, 600000],
                       <<"target_zone">> => [],
                       <<"intent">> => <<"owner_occupier">>},
    Facts = #{<<"onboarding">> => SeedOnboarding,
              <<"derived">> => #{<<"firb_required_any">> => false}},
    {ok, ProfileId} = fh_engine_store:create_profile(TenantId, UserId, Facts),
    {ok, CardId} = fh_engine_store:create_plan_card(
        TenantId, ProfileId, <<"fhb-domestic-au">>, <<"owner_occupier">>, <<"A">>, #{}),
    io:format("seeded card ~s~n", [CardId]),
    Url = Base ++ "/plan-cards/" ++ binary_to_list(CardId) ++ "/simulate",

    %% === 1. a target_price what-if → 200, component_id-keyed outcomes ===
    {S1, R1} = req(post, Url, [Auth],
                   fh_engine_util:json_encode(#{<<"overrides">> =>
                       #{<<"target_price">> => 900000}})),
    expect(S1 =:= 200, "simulate target_price → 200"),
    #{<<"plan_card_id">> := CardId,
      <<"overrides">> := #{<<"target_price">> := 900000},
      <<"outcomes">> := Out900} = fh_engine_util:json_decode(R1),
    %% the body is keyed by COMPONENT_ID (the shell-facing contract), not outcome_type.
    expect(maps:is_key(<<"cash_position">>, Out900),
           "outcomes keyed by component_id (cash_position present, not budget_envelope)"),
    expect(not maps:is_key(<<"budget_envelope">>, Out900),
           "outcomes NOT keyed by outcome_type (no budget_envelope key)"),
    expect(maps:is_key(<<"mortgage_finance">>, Out900),
           "the two-path mortgage_finance is present (resolver half ran)"),
    expect(lists:all(fun(K) -> maps:is_key(K, Out900) end,
                     [<<"buyer_profile">>, <<"eligibility">>, <<"cash_position">>,
                      <<"ownership_planning">>, <<"purchase_journey">>, <<"preparation">>]),
           "all base component_ids present in the preview body"),

    %% === 2. the override FLOWS THROUGH — a baseline preview differs ===
    {200, R0} = req(post, Url, [Auth],
                    fh_engine_util:json_encode(#{<<"overrides">> => #{}})),
    #{<<"outcomes">> := Out600} = fh_engine_util:json_decode(R0),
    expect(maps:get(<<"cash_position">>, Out900) =/= maps:get(<<"cash_position">>, Out600),
           "a $900k what-if yields a different cash_position than the $600k baseline"),

    %% === 3. it is a PREVIEW — nothing persisted ===
    EventCount = scalar("SELECT count(*) FROM plan_card_events WHERE plan_card_id = $1",
                        [CardId]),
    expect(EventCount =:= 0, "simulate appended NO plan_card_events (preview, not a turn)"),
    UsageCount = scalar("SELECT count(*) FROM plan_card_events "
                        "WHERE plan_card_id = $1 AND type = 'usage'", [CardId]),
    expect(UsageCount =:= 0, "simulate emitted NO usage"),

    %% === 4. override reject + auth + scope (the §10.1 guards) ===
    {S4, _} = req(post, Url, [Auth],
                  fh_engine_util:json_encode(#{<<"overrides">> =>
                      #{<<"property_type">> => <<"apartment">>}})),
    expect(S4 =:= 400, "property_type → 400 (Phase-B, rejected not silently dropped)"),
    {S5, _} = req(post, Url, [],
                  fh_engine_util:json_encode(#{<<"overrides">> => #{}})),
    expect(S5 =:= 401, "no token → 401"),
    Bogus = Base ++ "/plan-cards/" ++ binary_to_list(fh_engine_util:uuid4()) ++ "/simulate",
    {S6, _} = req(post, Bogus, [Auth],
                  fh_engine_util:json_encode(#{<<"overrides">> => #{}})),
    expect(S6 =:= 404, "simulate on a card the tenant doesn't own → 404"),

    io:format("~n==== SIMULATE HTTP SMOKE: ALL ASSERTIONS PASSED ====~n"),
    halt(0).

%% --- helpers ----------------------------------------------------------------

mint(TenantId, UserId, Priv) ->
    Now = erlang:system_time(second),
    fh_engine_auth:sign(#{<<"tenant_id">> => TenantId, <<"user_id">> => UserId,
                          <<"iat">> => Now, <<"exp">> => Now + 3600}, Priv).

req(Method, Url, Headers, Body) ->
    Request = case Method of
        get -> {Url, Headers};
        post -> {Url, Headers, "application/json", Body}
    end,
    {ok, {{_, Status, _}, _, Resp}} =
        httpc:request(Method, Request, [], [{body_format, binary}]),
    {Status, Resp}.

scalar(SQL, Params) ->
    #{rows := [{Val}]} = pgo:query(SQL, Params),
    Val.

expect(true, Msg)  -> io:format("  PASS   ~ts~n", [Msg]);
expect(false, Msg) -> io:format("  FAIL   ~ts~n", [Msg]), halt(1).
