#!/usr/bin/env escript
%%! -sname fh_shell_suburbs_proxy_smoke
%%
%% 8-S2a ablation: the shell's PUBLIC /api/suburbs proxy feeds the map home over the
%% FULL HTTP path — frontend → shell backend (:8081) → engine /api/engine/suburbs
%% (8-S1) → relayed verbatim (shell-architecture.md §1, map-stack.md). Unlike
%% seam_roundtrip (which calls the client function), this drives the cowboy handler:
%% route, qs-parse, the anon tenant-JWT mint, the relay of status + body, the 405.
%%
%% PUBLIC posture: no user JWT — the map is the pre-login landing, `suburbs` is global
%% CC-BY reference data. The shell still mints a short-lived tenant JWT (anon system
%% principal) so the engine authenticates the tenant (but does not scope by it).
%%
%% The proxy touches NO shell DB (pure passthrough), and both apps name their pgo
%% pool `default` (they are separate deployables — one VM each in prod). So this test
%% boots the engine app (its pool + the 8-S1 endpoint) and stands up ONLY the shell's
%% cowboy listener via fh_shell_http:routes/0 — not the full shell app, which would
%% start a second `default` pool against the engine DB. Needs the engine build lib +
%% the engine's dev Postgres (5433, populated by the build adapters). Run from
%% shell/web/backend:
%%
%%   ENGINE_DATABASE_URL=postgres://engine:engine_dev_pw@localhost:5433/firsthomey_engine?sslmode=disable \
%%   ERL_LIBS=_build/default/lib:../../../engine/erlang/_build/default/lib \
%%   escript test/suburbs_proxy_smoke.escript

-mode(compile).

main(_) ->
    %% --- boot the engine on its own port + provision the shell's signing key ---
    os:putenv("FH_ENGINE_HTTP_PORT", "8094"),
    {ok, _} = application:ensure_all_started(fh_engine),
    {ok, _} = application:ensure_all_started(inets),

    TenantId = fh_engine_util:uuid4(),
    {Pub, Priv} = crypto:generate_key(eddsa, ed25519),
    ok = fh_engine_store:upsert_tenant(TenantId, <<"shell-web">>),
    ok = fh_engine_store:add_signing_key(TenantId, <<"ed25519">>, base64:encode(Pub)),

    %% the engine DB must be populated (build adapters) for this to mean anything ---
    Total = scalar("SELECT count(*) FROM suburbs", []),
    expect(Total > 10000, "engine suburbs table populated (build adapters ran)"),

    %% --- the shell backend's runtime config (the env fh_shell_engine_jwt:mint reads) ---
    os:putenv("SHELL_TENANT_ID", binary_to_list(TenantId)),
    os:putenv("SHELL_TENANT_PRIVKEY", binary_to_list(base64:encode(Priv))),
    os:putenv("ENGINE_BASE_URL", "http://localhost:8094/api/engine"),

    %% --- stand up ONLY the shell's cowboy listener (real route table via
    %%     fh_shell_http:routes/0), not the full app (its `default` pool would
    %%     clash with the engine's + run shell migrations against the engine DB) ---
    {ok, _} = application:ensure_all_started(cowboy),
    Dispatch = cowboy_router:compile(fh_shell_http:routes()),
    {ok, _} = cowboy:start_clear(fh_shell_listener, [{port, 8084}],
                                 #{env => #{dispatch => Dispatch}}),
    Base = "http://localhost:8084",

    %% --- POSITIVE: GET /api/suburbs?state=NSW -> relayed 200 with the map facts.
    %%     No Authorization header: the surface is PUBLIC. ---
    {200, Resp} = req(get, Base ++ "/api/suburbs?state=NSW"),
    #{<<"state">> := <<"NSW">>,
      <<"suburbs">> := Suburbs,
      <<"attribution">> := Attribution} = fh_shell_util:json_decode(Resp),
    NswCount = scalar("SELECT count(*) FROM suburbs WHERE state = $1", [<<"NSW">>]),
    expect(length(Suburbs) =:= NswCount,
           "public proxy relays all NSW rows (tenant-independent, no user JWT)"),

    %% Cabramatta rides through verbatim — centroid + the killer Vietnamese layer ---
    Cab = find_suburb(Suburbs, <<"Cabramatta">>),
    #{<<"centroid">> := #{<<"lat">> := Lat, <<"lon">> := Lon},
      <<"facts">> := Facts} = Cab,
    expect(close(Lat, -33.898) andalso close(Lon, 150.936),
           "Cabramatta centroid relayed (Sydney SW)"),
    expect(close(maps:get(<<"vietnamese_ancestry_pct">>, Facts), 37.82),
           "Cabramatta Vietnamese ancestry 37.82% relayed (the map's killer layer)"),
    expect(length(Attribution) >= 5, "CC-BY attribution block relayed for the map strip"),

    %% --- the engine's required-state contract relays through the shell: missing
    %%     -> 400 missing_state, off-enum -> 400 invalid_state (one source of truth) ---
    {400, MissResp} = req(get, Base ++ "/api/suburbs"),
    #{<<"error">> := <<"missing_state">>} = fh_shell_util:json_decode(MissResp),
    {400, BadResp} = req(get, Base ++ "/api/suburbs?state=ZZ"),
    #{<<"error">> := <<"invalid_state">>} = fh_shell_util:json_decode(BadResp),

    %% --- method: POST -> 405 (the proxy is read-only) ---
    {405, _} = req(post, Base ++ "/api/suburbs"),

    io:format("~n==== SUBURBS PROXY SMOKE: ALL ASSERTIONS PASSED ====~n"),
    halt(0).

%% --- helpers ---------------------------------------------------------------

find_suburb(Suburbs, Name) ->
    case [S || S <- Suburbs, maps:get(<<"name">>, S) =:= Name] of
        [S | _] -> S;
        [] -> error({suburb_not_found, Name})
    end.

close(A, B) -> abs(A - B) < 0.01.

req(get, Url) ->
    {ok, {{_, Status, _}, _, Resp}} =
        httpc:request(get, {Url, []}, [], [{body_format, binary}]),
    {Status, Resp};
req(post, Url) ->
    {ok, {{_, Status, _}, _, Resp}} =
        httpc:request(post, {Url, [], "application/json", <<>>}, [],
                      [{body_format, binary}]),
    {Status, Resp}.

scalar(SQL, Params) ->
    #{rows := [{Val}]} = pgo:query(SQL, Params),
    Val.

expect(true, _Msg) -> ok;
expect(false, Msg) ->
    io:format("ASSERTION FAILED: ~s~n", [Msg]),
    halt(1).
