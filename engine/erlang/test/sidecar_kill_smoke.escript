#!/usr/bin/env escript
%%! -sname fh_sidecar_kill_smoke
%%
%% P-3's check: kill -9 a sidecar mid-fill and see the engine turn it into one clean
%% turn_failed, with nothing half-written.
%%
%% Reproducible -> P-3 · The sidecar is stateless and disposable -> Mechanisms -> sidecar killed mid-fill, turn fails clean
%% Falsifier (invariants.md P-3): `kill -9` on a sidecar mid-fill leaves the turn without a
%% `turn_failed`, or leaves a partial component in `plan_card_events`. A Mode A card's base
%% turn spawns one sidecar, for mortgage_finance (two_path); FH_PLANNER_SCRIPT points it
%% at test/hang_sidecar.py, which takes the frame and never replies. The smoke waits for
%% that sidecar to write its pid, kills it from outside with `kill -9`, then reads the
%% card's events back over the real SSE surface and from Postgres.
%%
%% Run from the repo root (needs a local port and the seat's private Postgres):
%%
%%   bash scripts/live_smoke.sh sidecar_kill_smoke

-mode(compile).

-define(PORT, "8096").

main(_) ->
    PidDir = pid_dir("fh_kill"),
    os:putenv("FH_ENGINE_HTTP_PORT", ?PORT),
    os:putenv("FH_PLANNER_SCRIPT", filename:absname("test/hang_sidecar.py")),
    os:putenv("FH_SIDECAR_PYTHON", os:find_executable("python3")),
    os:putenv("FH_HANG_PIDDIR", PidDir),
    quiet_boot(),
    {ok, _} = application:ensure_all_started(fh_engine),
    {ok, _} = application:ensure_all_started(inets),
    Base = "http://localhost:" ?PORT "/api/engine",
    Auth = seed_auth(<<"sidecar-kill-smoke">>),

    {PlanCardId, TurnId} = create(Base, Auth, mode_a_body()),
    io:format("created plan_card_id=~s (Mode A; mortgage_finance fills via the hang sidecar)~n",
              [PlanCardId]),

    OsPid = wait_for_pid(PidDir, 300),
    io:format("sidecar os pid ~s is mid-fill; kill -9~n", [OsPid]),
    _ = os:cmd("kill -9 " ++ OsPid),

    Types = collect_sse(sse_url(Base, PlanCardId), Auth),
    io:format("event sequence: ~p~n", [Types]),
    expect(lists:last(Types) =:= <<"turn_failed">>, "the stream ends on turn_failed (no hang)"),
    expect(not lists:member(<<"turn_completed">>, Types), "no turn_completed after the kill"),

    Failed = scalar("SELECT count(*) FROM plan_card_events WHERE plan_card_id = $1 "
                    "AND type = 'turn_failed' AND payload_jsonb->>'turn_id' = $2",
                    [PlanCardId, TurnId]),
    expect(Failed =:= 1, "exactly one turn_failed for the turn"),
    Code = scalar("SELECT payload_jsonb->>'code' FROM plan_card_events WHERE plan_card_id = $1 "
                  "AND type = 'turn_failed'", [PlanCardId]),
    expect(Code =:= <<"sidecar_crashed">>, "turn_failed code is sidecar_crashed"),
    Partial = scalar("SELECT count(*) FROM plan_card_events WHERE plan_card_id = $1 "
                     "AND type = 'component_filled' "
                     "AND payload_jsonb->>'component_id' = 'mortgage_finance'", [PlanCardId]),
    expect(Partial =:= 0, "no component_filled for mortgage_finance, the fill in flight"),
    Snap = scalar("SELECT count(*) FROM plan_cards WHERE plan_card_id = $1 "
                  "AND content_jsonb->'components' ? 'mortgage_finance'", [PlanCardId]),
    expect(Snap =:= 0, "mortgage_finance absent from the content_jsonb snapshot"),
    Usage = scalar("SELECT count(*) FROM plan_card_events WHERE plan_card_id = $1 "
                   "AND type = 'usage'", [PlanCardId]),
    expect(Usage =:= 0, "no usage event from the killed fill"),

    io:format("~n==== SIDECAR-KILL SMOKE (P-3): ALL ASSERTIONS PASSED ====~n"),
    halt(0).

%% --- shared harness (same shape as the seam smokes) ---------------------------

%% Boot reports (supervisor PROGRESS, ~30 KB a run) drown the assertions; the handler
%% keeps notice and up, whatever primary level fh_engine_app sets.
quiet_boot() ->
    ok = logger:set_handler_config(default, level, notice).

mode_a_body() ->
    fh_engine_util:json_encode(#{
        <<"state">> => <<"NSW">>,
        <<"target_price_range">> => [600000, 700000],
        <<"target_zone">> => [<<"Cabramatta">>, <<"Canley Vale">>],
        <<"intent">> => <<"owner_occupier">>,
        <<"buyer_stage">> => <<"first_home">>
    }).

pid_dir(Prefix) ->
    Tmp = case os:getenv("TMPDIR") of false -> "/tmp"; T -> T end,
    Dir = filename:join(Tmp, Prefix ++ "_" ++ integer_to_list(erlang:unique_integer([positive]))),
    ok = filelib:ensure_path(Dir),
    Dir.

wait_for_pid(_Dir, 0) ->
    expect(false, "the hang sidecar never started (no pid file in 30s)");
wait_for_pid(Dir, N) ->
    case file:list_dir(Dir) of
        {ok, [Pid | _]} -> Pid;
        _ -> timer:sleep(100), wait_for_pid(Dir, N - 1)
    end.

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

create(Base, Auth, Body) ->
    {202, Resp} = req(post, Base ++ "/plan-cards", [Auth], Body),
    #{<<"plan_card_id">> := PC, <<"turn_id">> := Tn} = fh_engine_util:json_decode(Resp),
    {PC, Tn}.

sse_url(Base, PC) -> Base ++ "/plan-cards/" ++ binary_to_list(PC) ++ "/events".

req(Method, Url, Headers, Body) ->
    Request = case Method of
        get -> {Url, Headers};
        post -> {Url, Headers, "application/json", Body}
    end,
    {ok, {{_, Status, _}, _, Resp}} =
        httpc:request(Method, Request, [], [{body_format, binary}]),
    {Status, Resp}.

collect_sse(Url, Auth) ->
    {ok, ReqId} = httpc:request(get, {Url, [Auth]}, [], [{sync, false}, {stream, self}]),
    parse_event_types(sse_loop(ReqId, <<>>)).

sse_loop(ReqId, Acc) ->
    receive
        {http, {ReqId, stream_start, _}} -> sse_loop(ReqId, Acc);
        {http, {ReqId, stream, Chunk}} -> sse_loop(ReqId, <<Acc/binary, Chunk/binary>>);
        {http, {ReqId, stream_end, _}} -> Acc;
        {http, {ReqId, {error, Reason}}} -> error({sse_error, Reason})
    after 30000 ->
        expect(false, "SSE stream hung 30s with no terminal event")
    end.

parse_event_types(Raw) ->
    Frames = binary:split(Raw, <<"\n\n">>, [global]),
    Pairs = lists:filtermap(fun parse_frame/1, Frames),
    {_, Rev} = lists:foldl(fun({Id, Type}, {Seen, Acc}) ->
        case sets:is_element(Id, Seen) of
            true -> {Seen, Acc};
            false -> {sets:add_element(Id, Seen), [Type | Acc]}
        end
    end, {sets:new(), []}, Pairs),
    lists:reverse(Rev).

parse_frame(Frame) ->
    case re:run(Frame, <<"event: (.+)">>, [{capture, [1], binary}]) of
        {match, [Type]} ->
            Id = case re:run(Frame, <<"id: (\\d+)">>, [{capture, [1], binary}]) of
                     {match, [I]} -> binary_to_integer(I);
                     nomatch -> 0
                 end,
            {true, {Id, Type}};
        nomatch -> false
    end.

scalar(SQL, Params) ->
    #{rows := [{Val}]} = pgo:query(SQL, Params),
    Val.

expect(true, _Msg) -> ok;
expect(false, Msg) ->
    io:format("ASSERTION FAILED: ~s~n", [Msg]),
    halt(1).
