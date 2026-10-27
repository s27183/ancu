#!/usr/bin/env escript
%%! -sname fh_sidecar_env_smoke
%%
%% Behavior 140, Expect 5: the sidecar gets only the env it needs.
%%
%% R-4 · Reasoning within its runtime -> The sidecar -> the sidecar gets only the env it needs
%% Falsifier: a sidecar spawned by the engine — for a plan fill or for a Q&A turn — sees
%% ENGINE_DATABASE_URL, SHELL_TENANT_*, a non-empty ANTHROPIC_API_KEY, or another engine
%% variable outside the allowlist in fh_engine_turn:sidecar_env_keep/1. The engine is
%% booted with canary values in each; FH_PLANNER_SCRIPT points at test/env_sidecar.py,
%% which writes the NAMES of its env (never the values) and exits without a reply. A Mode
%% A card's base turn spawns one fill sidecar; once that turn has failed, a question
%% spawns one Q&A sidecar.
%%
%% Run from engine/erlang with the seat's private Postgres:
%%
%%   ENGINE_DATABASE_URL=postgres://<user>@<encoded socket dir>/<db> \
%%   ERL_LIBS=_build/default/lib escript test/sidecar_env_smoke.escript

-mode(compile).

main(_) ->
    DumpDir = dump_dir(),
    Port = free_port(),
    os:putenv("FH_ENGINE_HTTP_PORT", integer_to_list(Port)),
    os:putenv("FH_PLANNER_SCRIPT", filename:absname("test/env_sidecar.py")),
    os:putenv("FH_SIDECAR_PYTHON", os:find_executable("python3")),
    os:putenv("FH_ENV_DUMPDIR", DumpDir),
    %% Canaries the sidecar must not receive (made-up values).
    os:putenv("ANTHROPIC_API_KEY", "sk-canary-not-a-key"),
    os:putenv("SOME_OTHER_SECRET", "canary-other"),
    %% What it must still receive.
    os:putenv("CLAUDE_CODE_OAUTH_TOKEN", "placeholder-canary"),
    os:putenv("FH_LEAF_MODEL", "opus"),
    ok = logger:set_handler_config(default, level, notice),
    {ok, _} = application:ensure_all_started(fh_engine),
    {ok, _} = application:ensure_all_started(inets),
    %% Set after boot (the app parses SHELL_TENANT_* at start); the spawn reads the env
    %% when it spawns, so these are in the engine's env for every sidecar below.
    os:putenv("SHELL_TENANT_ID", "canary-tenant"),
    os:putenv("SHELL_TENANT_PUBKEY", "canary-pubkey"),
    Base = "http://127.0.0.1:" ++ integer_to_list(Port) ++ "/api/engine",
    Auth = seed_auth(<<"sidecar-env-smoke">>),

    {202, Resp} = req(post, Base ++ "/plan-cards", [Auth], mode_a_body()),
    #{<<"plan_card_id">> := PC} = fh_engine_util:json_decode(Resp),
    Fill = wait_for_dump(DumpDir, "fill_component", 300),
    Qa = ask(Base, Auth, PC, DumpDir, 300),

    lists:foreach(fun({Kind, #{<<"env_names">> := Names, <<"cwd">> := Cwd} = R}) ->
        Forbidden = [N || N <- Names,
                     lists:member(N, [<<"ENGINE_DATABASE_URL">>, <<"SHELL_TENANT_ID">>,
                                      <<"SHELL_TENANT_PUBKEY">>, <<"SOME_OTHER_SECRET">>])],
        io:format("~s sidecar: ~p env names, cwd ~s, forbidden present ~p~n",
                  [Kind, length(Names), Cwd, Forbidden]),
        expect(Forbidden =:= [], Kind ++ ": no engine secret in the sidecar env"),
        expect(maps:get(<<"anthropic_api_key_nonempty">>, R) =:= false,
               Kind ++ ": ANTHROPIC_API_KEY absent or empty"),
        expect(lists:member(<<"CLAUDE_CODE_OAUTH_TOKEN">>, Names),
               Kind ++ ": CLAUDE_CODE_OAUTH_TOKEN still passed"),
        expect(lists:member(<<"FH_LEAF_MODEL">>, Names) andalso lists:member(<<"FH_ENV_DUMPDIR">>, Names),
               Kind ++ ": FH_* settings still passed")
    end, [{"fill", Fill}, {"qa", Qa}]),

    io:format("~n==== SIDECAR-ENV SMOKE (behavior 140): ALL ASSERTIONS PASSED ====~n"),
    halt(0).

%% The base turn fails when the stub exits without replying; until it settles a message
%% is 409 turn_in_flight. Retry the question until it is accepted, then wait for the
%% Q&A sidecar's dump.
ask(_Base, _Auth, _PC, _Dir, 0) ->
    expect(false, "no Q&A sidecar started in 30s");
ask(Base, Auth, PC, Dir, N) ->
    Url = Base ++ "/plan-cards/" ++ binary_to_list(PC) ++ "/messages",
    case req(post, Url, [Auth], <<"{\"message\":\"What is the FHOG?\"}">>) of
        {202, _} -> wait_for_dump(Dir, "qa", 300);
        {409, _} -> timer:sleep(100), ask(Base, Auth, PC, Dir, N - 1);
        Other -> expect(false, io_lib:format("question refused: ~p", [Other]))
    end.

wait_for_dump(_Dir, Method, 0) ->
    expect(false, "no " ++ Method ++ " sidecar dump in 30s");
wait_for_dump(Dir, Method, N) ->
    {ok, Files} = file:list_dir(Dir),
    case [F || F <- Files, lists:prefix(Method ++ "-", F)] of
        [F | _] ->
            {ok, Bin} = file:read_file(filename:join(Dir, F)),
            fh_engine_util:json_decode(Bin);
        [] -> timer:sleep(100), wait_for_dump(Dir, Method, N - 1)
    end.

mode_a_body() ->
    fh_engine_util:json_encode(#{
        <<"state">> => <<"NSW">>,
        <<"target_price_range">> => [600000, 700000],
        <<"target_zone">> => [<<"Cabramatta">>, <<"Canley Vale">>],
        <<"intent">> => <<"owner_occupier">>,
        <<"buyer_stage">> => <<"first_home">>
    }).

dump_dir() ->
    Tmp = case os:getenv("TMPDIR") of false -> "/tmp"; T -> T end,
    Dir = filename:join(Tmp, "fh_env_" ++ integer_to_list(erlang:unique_integer([positive]))),
    ok = filelib:ensure_path(filename:join(Dir, "x")),
    Dir.

free_port() ->
    {ok, S} = gen_tcp:listen(0, [{ip, {127,0,0,1}}]),
    {ok, P} = inet:port(S),
    ok = gen_tcp:close(S),
    P.

seed_auth(Name) ->
    TenantId = fh_engine_util:uuid4(),
    UserId = fh_engine_util:uuid4(),
    {Pub, Priv} = crypto:generate_key(eddsa, ed25519),
    ok = fh_engine_store:upsert_tenant(TenantId, Name),
    ok = fh_engine_store:add_signing_key(TenantId, <<"ed25519">>, base64:encode(Pub)),
    Now = erlang:system_time(second),
    Token = fh_engine_auth:sign(#{<<"tenant_id">> => TenantId, <<"user_id">> => UserId,
                                  <<"iat">> => Now, <<"exp">> => Now + 3600}, Priv),
    {"authorization", "Bearer " ++ binary_to_list(Token)}.

req(Method, Url, Headers, Body) ->
    Request = case Method of
        get -> {Url, Headers};
        post -> {Url, Headers, "application/json", Body}
    end,
    {ok, {{_, Status, _}, _, Resp}} =
        httpc:request(Method, Request, [], [{body_format, binary}]),
    {Status, Resp}.

expect(true, Msg) -> io:format("PASS  ~s~n", [Msg]);
expect(false, Msg) ->
    io:format("ASSERTION FAILED: ~s~n", [Msg]),
    halt(1).
