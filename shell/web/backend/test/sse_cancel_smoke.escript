#!/usr/bin/env escript
%%! -sname fh_shell_sse_cancel_smoke
%%
%% Behavior 29's check: a browser stream cancelled at any point through the shell
%% never freezes the next one, and never leaves its engine stream open behind it.
%%
%% Reproducible -> P-1 · One process per concern -> The shell backend -> a cancelled SSE stream and the one after it
%% Falsifier: after browser streams are cut — before the shell's first byte, mid-way
%% through slow upstream headers, or once live — a new stream through the shell does
%% not reach 200 and its first frame (a finished plan: its terminal frame) within
%% ?BOUND_MS; or the engine-side stream a cut browser stream opened is still running
%% ?LEAK_MS later. The browser is a raw TCP socket so a cut can land before any byte
%% comes back, which httpc cannot do. The engine is sse_cancel_stub_engine, which
%% reports each stream's process so the smoke can watch it end.
%%
%% Run from shell/web/backend (needs local ports and a shell database on the seat's
%% private Postgres; it boots the full shell app, migrations included):
%%
%%   SHELL_DATABASE_URL=postgres://<user>@<socket dir, %2F-escaped>/<db> \
%%   ERL_LIBS=_build/default/lib escript test/sse_cancel_smoke.escript

-mode(compile).

-define(SHELL_PORT, 8086).
-define(STUB_PORT, 8087).
-define(BOUND_MS, 2000).
-define(LEAK_MS, 3000).
-define(CUTS, 20).
-define(CLIENT, sse_cancel_client).

main(_) ->
    os:putenv("FH_HTTP_IP", "127.0.0.1"),
    os:putenv("FH_SHELL_HTTP_PORT", integer_to_list(?SHELL_PORT)),
    os:putenv("SHELL_JWT_SECRET", "sse-cancel-smoke-secret"),
    {_Pub, Priv} = crypto:generate_key(eddsa, ed25519),
    os:putenv("SHELL_TENANT_ID", binary_to_list(uuid())),
    os:putenv("SHELL_TENANT_PRIVKEY", binary_to_list(base64:encode(Priv))),
    os:putenv("ENGINE_BASE_URL",
              "http://127.0.0.1:" ++ integer_to_list(?STUB_PORT) ++ "/api/engine"),
    ok = logger:set_handler_config(default, level, notice),

    {ok, _} = application:ensure_all_started(fh_shell),
    {ok, _} = application:ensure_all_started(inets),
    {ok, _} = inets:start(httpc, [{profile, ?CLIENT}]),
    ok = httpc:set_options([{max_sessions, 64}], ?CLIENT),

    register(sse_cancel_collector, spawn(fun() -> collect(#{}) end)),
    StubMod = compile_load("test/sse_cancel_stub_engine.erl"),
    Dispatch = cowboy_router:compile([{'_', [
        {"/api/engine/plan-cards/:id/events", StubMod, events}
    ]}]),
    {ok, _} = cowboy:start_clear(sse_cancel_stub,
                                 [{ip, {127, 0, 0, 1}}, {port, ?STUB_PORT}],
                                 #{env => #{dispatch => Dispatch}}),

    Email = <<"sse-cancel+", (uuid())/binary, "@example.com">>,
    UserId = scalar("INSERT INTO users (email) VALUES ($1) RETURNING user_id::text", [Email]),
    Jwt = fh_shell_jwt:issue(#{user_id => UserId, email => Email,
                               roles => [<<"buyer">>], locale => <<"vi">>}),
    Card = fun(Prefix) ->
        <<_:8/binary, Rest/binary>> = uuid(),
        C = <<Prefix:8/binary, Rest/binary>>,
        ok = fh_shell_store:insert_plan_card_view(UserId, C, <<"Kew">>),
        C
    end,
    Live = fun() -> Card(<<"0c0c0c0c">>) end,
    Slow = fun() -> Card(<<"aaaaaaaa">>) end,
    Done = fun() -> Card(<<"ffffffff">>) end,

    %% 1 · cut before the shell's first byte, on live plans
    PreCut = [cut(Live(), Jwt, 0) || _ <- lists:seq(1, ?CUTS)],
    next_streams_answer(Live, Done, Jwt,
        io_lib:format("~b streams cut before the first byte", [?CUTS])),

    %% 2 · cut while the engine is still sending its headers
    SlowCut = [cut(Slow(), Jwt, 100) || _ <- lists:seq(1, 5)],
    next_streams_answer(Live, Done, Jwt, "5 streams cut during slow engine headers"),

    %% 3 · cut once live, past turn_started (the user leaving a plan mid-fill)
    LiveCut = [cut(Live(), Jwt, turn_started) || _ <- lists:seq(1, 5)],
    next_streams_answer(Live, Done, Jwt, "5 live streams cut past turn_started"),

    %% 4 · every engine stream a cut browser stream opened has ended
    Cut = PreCut ++ SlowCut ++ LiveCut,
    timer:sleep(?LEAK_MS),
    Opened = [P || C <- Cut, P <- stub_pids(C)],
    Running = [P || P <- Opened, is_process_alive(P)],
    io:format("engine streams opened by cut browser streams: ~b, still running ~b ms "
              "later: ~b~n", [length(Opened), ?LEAK_MS, length(Running)]),
    expect(Running =:= [],
           "no engine stream outlives the browser stream that opened it"),

    io:format("~n==== SSE-CANCEL SMOKE (behavior 29): ALL ASSERTIONS PASSED ====~n"),
    halt(0).

%% A browser stream over raw TCP, cut at `0` (right after the request is written),
%% after N ms, or once turn_started has come back.
cut(CardId, Jwt, When) ->
    {ok, S} = gen_tcp:connect({127, 0, 0, 1}, ?SHELL_PORT,
                              [binary, {active, false}, {nodelay, true}]),
    ok = gen_tcp:send(S, ["GET /api/plan-cards/", CardId, "/events HTTP/1.1\r\n",
                          "host: 127.0.0.1\r\naccept: text/event-stream\r\n",
                          "authorization: Bearer ", Jwt, "\r\n\r\n"]),
    case When of
        0 -> ok;
        turn_started -> {ok, _} = read_until(S, <<>>, <<"turn_started">>);
        Ms -> timer:sleep(Ms)
    end,
    ok = gen_tcp:close(S),
    CardId.

read_until(S, Acc, Want) ->
    case binary:match(Acc, Want) of
        nomatch ->
            case gen_tcp:recv(S, 0, ?BOUND_MS) of
                {ok, B} -> read_until(S, <<Acc/binary, B/binary>>, Want);
                E -> expect(false, io_lib:format("a live stream to cut gave ~p", [E]))
            end;
        _ -> {ok, Acc}
    end.

%% After a batch of cuts: a fresh live stream reaches 200 + turn_started, and a
%% finished plan's stream reaches turn_completed and closes, each inside the bound.
next_streams_answer(Live, Done, Jwt, What) ->
    Auth = {"authorization", "Bearer " ++ binary_to_list(Jwt)},
    {LiveMs, LiveReq} = timed_stream(Live(), Auth, <<"turn_started">>),
    httpc:cancel_request(LiveReq, ?CLIENT),
    {DoneMs, _} = timed_stream(Done(), Auth, end_of_stream),
    io:format("after ~s: next live stream first frame in ~b ms, "
              "finished plan's stream closed in ~b ms~n", [What, LiveMs, DoneMs]),
    expect(LiveMs < ?BOUND_MS andalso DoneMs < ?BOUND_MS,
           ["the next streams answer inside the bound after ", What]).

timed_stream(CardId, Auth, Want) ->
    T0 = erlang:monotonic_time(millisecond),
    Url = "http://127.0.0.1:" ++ integer_to_list(?SHELL_PORT)
          ++ "/api/plan-cards/" ++ binary_to_list(CardId) ++ "/events",
    {ok, ReqId} = httpc:request(get, {Url, [Auth]}, [],
                                [{sync, false}, {stream, self}], ?CLIENT),
    wait(ReqId, <<>>, Want, T0),
    {erlang:monotonic_time(millisecond) - T0, ReqId}.

wait(ReqId, Acc, Want, T0) ->
    Left = max(0, ?BOUND_MS - (erlang:monotonic_time(millisecond) - T0)),
    Got = is_binary(Want) andalso binary:match(Acc, Want) =/= nomatch,
    case Got of
        true -> ok;
        false ->
            receive
                {http, {ReqId, stream_start, _}} -> wait(ReqId, Acc, Want, T0);
                {http, {ReqId, stream, C}} -> wait(ReqId, <<Acc/binary, C/binary>>, Want, T0);
                {http, {ReqId, stream_end, _}} when Want =:= end_of_stream ->
                    expect(binary:match(Acc, <<"turn_completed">>) =/= nomatch,
                           "a finished plan's stream carries turn_completed before it closes");
                {http, {ReqId, stream_end, _}} -> expect(false, "a live stream ended early");
                {http, {ReqId, {{_, Status, _}, _, Body}}} ->
                    expect(false, io_lib:format("a stream answered ~p: ~s", [Status, Body]));
                {http, {ReqId, {error, R}}} ->
                    expect(false, io_lib:format("a stream failed: ~p", [R]))
            after Left ->
                expect(false, io_lib:format("a stream gave nothing within ~b ms (~p)",
                                            [?BOUND_MS, Want]))
            end
    end.

%% The collector: engine stream pids by plan id, as the stub reports them.
collect(M) ->
    receive
        {stub_stream, Pid, Id} -> collect(M#{Id => [Pid | maps:get(Id, M, [])]});
        {get, Id, From} -> From ! {pids, maps:get(Id, M, [])}, collect(M)
    end.

stub_pids(Id) ->
    sse_cancel_collector ! {get, Id, self()},
    receive {pids, P} -> P after 1000 -> [] end.

compile_load(File) ->
    {ok, Mod, Bin} = compile:file(File, [binary, return_errors]),
    {module, Mod} = code:load_binary(Mod, File, Bin),
    Mod.

uuid() -> fh_shell_util:uuid4().

scalar(SQL, Params) ->
    #{rows := [{Val}]} = pgo:query(SQL, Params),
    Val.

expect(true, Label)  -> io:format("  ok  ~s~n", [Label]);
expect(false, Label) -> io:format("FAIL  ~s~n", [Label]), halt(1).
