#!/usr/bin/env escript
%%! -sname fh_shell_sse_isolation_smoke
%%
%% P-1's check, shell half: SSE streams held open through the shell proxy do not
%% starve the plain proxied calls beside them.
%%
%% Reproducible -> P-1 · One process per concern -> Mechanisms -> held SSE streams vs plain proxied calls
%% Falsifier (invariants.md P-1): a held SSE stream through the shell makes a plain
%% proxied call wait behind it. The shell keeps every stream on its own httpc profile
%% (fh_shell_engine_client ?SSE_PROFILE) because httpc's default profile allows two
%% sessions per host and streams there once wedged get/suburbs until the 15 s RPC bound
%% failed them. This boots the full shell app against a stub engine
%% (sse_isolation_stub_engine) whose streams never end, opens ?STREAMS of them through
%% the shell — more than the default pool's two — and, with all of them open, times
%% `GET /api/plan-cards/:id` and `GET /api/suburbs` through the shell: each must answer
%% 200 within ?BOUND_MS, far inside the 15 s bound a wedge would hit. Then the streams
%% must still be open. It checks the outcome, not the profile split: on OTP 29.1.1 /
%% inets 9.8 it passes with the split ablated too (measured 2026-10-06; why, at
%% fh_shell_engine_client ?SSE_PROFILE).
%%
%% Run from the repo root (needs local ports and the seat's private Postgres):
%%
%%   bash scripts/live_smoke.sh sse_isolation_smoke

-mode(compile).

-define(SHELL_PORT, 8088).
-define(STUB_PORT, 8089).
-define(STREAMS, 4).
-define(BOUND_MS, 3000).
-define(CLIENT, sse_isolation_client).

main(_) ->
    os:putenv("FH_SHELL_HTTP_PORT", integer_to_list(?SHELL_PORT)),
    os:putenv("SHELL_JWT_SECRET", "sse-isolation-smoke-secret"),
    {_Pub, Priv} = crypto:generate_key(eddsa, ed25519),
    os:putenv("SHELL_TENANT_ID", binary_to_list(uuid())),
    os:putenv("SHELL_TENANT_PRIVKEY", binary_to_list(base64:encode(Priv))),
    os:putenv("ENGINE_BASE_URL",
              "http://localhost:" ++ integer_to_list(?STUB_PORT) ++ "/api/engine"),
    ok = logger:set_handler_config(default, level, notice),

    {ok, _} = application:ensure_all_started(fh_shell),
    {ok, _} = application:ensure_all_started(inets),
    %% The smoke's own client runs on its own profile, so its sockets to the shell
    %% never share a pool with the shell's sockets to the engine.
    {ok, _} = inets:start(httpc, [{profile, ?CLIENT}]),
    ok = httpc:set_options([{max_sessions, 64}], ?CLIENT),

    StubMod = compile_load("test/sse_isolation_stub_engine.erl"),
    Dispatch = cowboy_router:compile([{'_', [
        {"/api/engine/plan-cards/:id/events", StubMod, events},
        {"/api/engine/plan-cards/:id", StubMod, plan_card},
        {"/api/engine/suburbs", StubMod, suburbs}
    ]}]),
    {ok, _} = cowboy:start_clear(sse_isolation_stub, [{port, ?STUB_PORT}],
                                 #{env => #{dispatch => Dispatch}}),
    Base = "http://localhost:" ++ integer_to_list(?SHELL_PORT),

    Email = <<"sse-iso+", (uuid())/binary, "@example.com">>,
    UserId = scalar("INSERT INTO users (email) VALUES ($1) RETURNING user_id::text", [Email]),
    Cards = [uuid() || _ <- lists:seq(1, ?STREAMS + 1)],
    [ok = fh_shell_store:insert_plan_card_view(UserId, C, <<"Cabramatta">>) || C <- Cards],
    Jwt = fh_shell_jwt:issue(#{user_id => UserId, email => Email,
                               roles => [<<"buyer">>], locale => <<"vi">>}),
    Auth = {"authorization", "Bearer " ++ binary_to_list(Jwt)},
    [PlainCard | StreamCards] = Cards,

    Streams = [open_stream(Base ++ "/api/plan-cards/" ++ b2l(C) ++ "/events", Auth)
               || C <- StreamCards],
    expect(length(Streams) =:= ?STREAMS,
           io_lib:format("~b SSE streams open through the shell, each past turn_started",
                         [?STREAMS])),

    {S1, Ms1} = timed_get(Base ++ "/api/plan-cards/" ++ b2l(PlainCard), [Auth]),
    io:format("GET /api/plan-cards/:id -> ~b in ~b ms~n", [S1, Ms1]),
    expect(S1 =:= 200 andalso Ms1 < ?BOUND_MS,
           "get_plan_card answers 200 inside the bound while the streams are held"),
    {S2, Ms2} = timed_get(Base ++ "/api/suburbs?state=NSW", []),
    io:format("GET /api/suburbs -> ~b in ~b ms~n", [S2, Ms2]),
    expect(S2 =:= 200 andalso Ms2 < ?BOUND_MS,
           "list_suburbs answers 200 inside the bound while the streams are held"),

    expect(lists:all(fun still_open/1, Streams),
           "every stream is still open after the plain calls (keepalives still arriving)"),
    [httpc:cancel_request(R, ?CLIENT) || R <- Streams],

    io:format("~n==== SSE-ISOLATION SMOKE (P-1 shell): ALL ASSERTIONS PASSED ====~n"),
    halt(0).

%% Open one SSE request through the shell and wait until turn_started has come back.
open_stream(Url, Auth) ->
    {ok, ReqId} = httpc:request(get, {Url, [Auth]}, [],
                                [{sync, false}, {stream, self}], ?CLIENT),
    wait_frame(ReqId, <<>>, <<"turn_started">>, 5000),
    ReqId.

%% A held stream is open if another keepalive arrives on it within ~2 s.
still_open(ReqId) ->
    flush(ReqId),
    receive
        {http, {ReqId, stream, _}} -> true;
        {http, {ReqId, stream_end, _}} -> false;
        {http, {ReqId, {error, _}}} -> false
    after 2500 -> false
    end.

flush(ReqId) ->
    receive {http, {ReqId, stream, _}} -> flush(ReqId) after 0 -> ok end.

wait_frame(ReqId, Acc, Want, Ms) ->
    case binary:match(Acc, Want) of
        nomatch ->
            receive
                {http, {ReqId, stream_start, _}} -> wait_frame(ReqId, Acc, Want, Ms);
                {http, {ReqId, stream, C}} -> wait_frame(ReqId, <<Acc/binary, C/binary>>, Want, Ms);
                {http, {ReqId, stream_end, _}} -> expect(false, "a stream ended early");
                {http, {ReqId, {{_, Status, _}, _, Body}}} ->
                    io:format("stream got ~p: ~s~n", [Status, Body]),
                    expect(false, "a stream answered non-2xx");
                {http, {ReqId, {error, R}}} -> expect(false, io_lib:format("stream error ~p", [R]))
            after Ms -> expect(false, "a stream sent no turn_started within 5 s")
            end;
        _ -> ok
    end.

timed_get(Url, Headers) ->
    T0 = erlang:monotonic_time(millisecond),
    Status = case httpc:request(get, {Url, Headers}, [{timeout, 20000}],
                                [{body_format, binary}], ?CLIENT) of
        {ok, {{_, S, _}, _, _}} -> S;
        {error, _} -> 0
    end,
    {Status, erlang:monotonic_time(millisecond) - T0}.

compile_load(File) ->
    {ok, Mod, Bin} = compile:file(File, [binary, return_errors]),
    {module, Mod} = code:load_binary(Mod, File, Bin),
    Mod.

uuid() -> fh_shell_util:uuid4().
b2l(B) -> binary_to_list(B).

scalar(SQL, Params) ->
    #{rows := [{Val}]} = pgo:query(SQL, Params),
    Val.

expect(true, Label)  -> io:format("  ok  ~s~n", [Label]);
expect(false, Label) -> io:format("FAIL  ~s~n", [Label]), halt(1).
