#!/usr/bin/env escript
%%! -sname fh_suburbs_smoke
%%
%% Smoke test for 8-S1: GET /api/engine/suburbs (the shell map's raw-metric source,
%% suburb-data-foundation §2). Boots the engine, seeds a tenant + ed25519 key, mints
%% a JWT, and drives the real endpoint — asserting state filtering, the raw map facts
%% (centroid + Vietnamese ancestry + crime), the CC-BY attribution block (§6.1), the
%% required-state 400s, and auth rejection. Requires the suburbs table populated by
%% the build adapters (engine/build/suburbs). Run from engine/erlang:
%%
%%   ENGINE_DATABASE_URL=postgres://engine:engine_dev_pw@localhost:5433/firsthomey_engine?sslmode=disable \
%%     ERL_LIBS=_build/default/lib escript test/suburbs_smoke.escript

-mode(compile).

main(_) ->
    os:putenv("FH_ENGINE_HTTP_PORT", "8092"),
    {ok, _} = application:ensure_all_started(fh_engine),
    {ok, _} = application:ensure_all_started(inets),
    Base = "http://localhost:8092/api/engine",

    %% --- seed tenant + ed25519 signing key (the shell's role in production) ---
    TenantId = fh_engine_util:uuid4(),
    UserId = fh_engine_util:uuid4(),
    {Pub, Priv} = crypto:generate_key(eddsa, ed25519),
    ok = fh_engine_store:upsert_tenant(TenantId, <<"suburbs-smoke">>),
    ok = fh_engine_store:add_signing_key(TenantId, <<"ed25519">>, base64:encode(Pub)),
    Token = mint(TenantId, UserId, Priv),
    Auth = {"authorization", "Bearer " ++ binary_to_list(Token)},

    %% --- the suburbs table must be populated (build adapters) for this to mean anything ---
    Total = scalar("SELECT count(*) FROM suburbs", []),
    expect(Total > 10000, "suburbs table populated (build adapters ran)"),

    %% --- positive: GET /suburbs?state=NSW -> 200 with raw map facts ---
    {200, Resp} = req(get, Base ++ "/suburbs?state=NSW", [Auth], <<>>),
    #{<<"state">> := <<"NSW">>,
      <<"suburbs">> := Suburbs,
      <<"attribution">> := Attribution} = fh_engine_util:json_decode(Resp),
    expect(length(Suburbs) > 1000, "NSW returns its suburb set"),

    %% the row count matches the un-scoped DB count for the state (global, no tenant filter) ---
    NswCount = scalar("SELECT count(*) FROM suburbs WHERE state = $1", [<<"NSW">>]),
    expect(length(Suburbs) =:= NswCount, "all NSW rows returned (tenant-independent)"),

    %% Cabramatta carries the killer layer + centroid + crime, verbatim from facts_jsonb ---
    Cab = find_suburb(Suburbs, <<"Cabramatta">>),
    #{<<"centroid">> := #{<<"lat">> := Lat, <<"lon">> := Lon},
      <<"facts">> := Facts} = Cab,
    expect(is_float(Lat) andalso is_float(Lon), "Cabramatta has a centroid"),
    expect(close(Lat, -33.898) andalso close(Lon, 150.936), "centroid is Sydney SW"),
    Anc = maps:get(<<"vietnamese_ancestry_pct">>, Facts),
    expect(close(Anc, 37.82), "Cabramatta Vietnamese ancestry = 37.82% (raw, map-facing)"),
    expect(maps:is_key(<<"crime_incidents_per_1000">>, Facts),
           "crime rate present (map-only raw, no resolver band)"),

    %% --- attribution block: CC-BY strings the map strip must render (§6.1) ---
    expect(length(Attribution) >= 5, "attribution block lists the feed sources"),
    Abs = find_source(Attribution, <<"abs_census_2021">>),
    expect(is_map(Abs) andalso is_binary(maps:get(<<"attribution">>, Abs)),
           "abs_census_2021 attribution string present"),

    %% --- required state: missing -> 400 missing_state; invalid -> 400 invalid_state ---
    {400, MissResp} = req(get, Base ++ "/suburbs", [Auth], <<>>),
    #{<<"error">> := <<"missing_state">>} = fh_engine_util:json_decode(MissResp),
    {400, BadResp} = req(get, Base ++ "/suburbs?state=ZZ", [Auth], <<>>),
    #{<<"error">> := <<"invalid_state">>} = fh_engine_util:json_decode(BadResp),

    %% --- auth: missing token -> 401; wrong key -> 403 (engine verifies, not just parses) ---
    {401, _} = req(get, Base ++ "/suburbs?state=NSW", [], <<>>),
    {_, BadPriv} = crypto:generate_key(eddsa, ed25519),
    BadAuth = {"authorization", "Bearer " ++ binary_to_list(mint(TenantId, UserId, BadPriv))},
    {403, _} = req(get, Base ++ "/suburbs?state=NSW", [BadAuth], <<>>),

    io:format("~n==== SUBURBS SMOKE: ALL ASSERTIONS PASSED ====~n"),
    halt(0).

%% --- helpers ---------------------------------------------------------------

mint(TenantId, UserId, Priv) ->
    Now = erlang:system_time(second),
    fh_engine_auth:sign(#{<<"tenant_id">> => TenantId, <<"user_id">> => UserId,
                          <<"iat">> => Now, <<"exp">> => Now + 3600}, Priv).

find_suburb(Suburbs, Name) ->
    case [S || S <- Suburbs, maps:get(<<"name">>, S) =:= Name] of
        [S | _] -> S;
        [] -> error({suburb_not_found, Name})
    end.

find_source(Sources, Id) ->
    case [S || S <- Sources, maps:get(<<"source_id">>, S) =:= Id] of
        [S | _] -> S;
        [] -> error({source_not_found, Id})
    end.

%% Floats round-trip through JSON; compare within a small tolerance.
close(A, B) -> abs(A - B) < 0.01.

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

expect(true, _Msg) -> ok;
expect(false, Msg) ->
    io:format("ASSERTION FAILED: ~s~n", [Msg]),
    halt(1).
