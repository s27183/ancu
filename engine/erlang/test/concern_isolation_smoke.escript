#!/usr/bin/env escript
%%! -sname fh_concern_isolation_smoke
%%
%% P-1's check, engine half: one card's fill hanging and then killed does not stall or
%% fail another card's turn running beside it.
%%
%% Reproducible -> P-1 · One process per concern -> Mechanisms -> card A's sidecar hangs and dies while card B completes
%% Falsifier (invariants.md P-1): killing card A's sidecar mid-turn stalls or fails card B.
%% Card A is Mode A, whose base turn spawns one sidecar (mortgage_finance); FH_PLANNER_SCRIPT
%% points it at test/hang_sidecar.py, which takes the frame and never replies. With A held
%% mid-fill, card B (Mode B, resolver-only, no sidecar) is created and read to its end over
%% SSE: it must complete with all ten components while A's sidecar is still alive and A has
%% no terminal event. Then A's sidecar is `kill -9`ed: A ends turn_failed, and B's record is
%% unchanged by it.
%%
%% Run from the repo root (needs a local port and the seat's private Postgres):
%%
%%   bash scripts/live_smoke.sh concern_isolation_smoke

-mode(compile).

-define(PORT, "8097").

main(_) ->
    PidDir = pid_dir("fh_iso"),
    os:putenv("FH_ENGINE_HTTP_PORT", ?PORT),
    os:putenv("FH_PLANNER_SCRIPT", filename:absname("test/hang_sidecar.py")),
    os:putenv("FH_SIDECAR_PYTHON", os:find_executable("python3")),
    os:putenv("FH_HANG_PIDDIR", PidDir),
    quiet_boot(),
    {ok, _} = application:ensure_all_started(fh_engine),
    {ok, _} = application:ensure_all_started(inets),
    Base = "http://localhost:" ?PORT "/api/engine",
    Auth = seed_auth(<<"concern-isolation-smoke">>),

    {CardA, TurnA} = create(Base, Auth, mode_a_body()),
    OsPid = wait_for_pid(PidDir, 300),
    io:format("card A ~s: sidecar os pid ~s hangs mid-fill~n", [CardA, OsPid]),

    {CardB, TurnB} = create(Base, Auth, mode_b_body()),
    io:format("card B ~s: Mode B, resolver-only, created beside it~n", [CardB]),
    TypesB = collect_sse(sse_url(Base, CardB), Auth),
    io:format("card B event sequence: ~p~n", [TypesB]),
    expect(lists:last(TypesB) =:= <<"turn_completed">>, "card B ends turn_completed"),
    expect(not lists:member(<<"turn_failed">>, TypesB), "card B has no turn_failed"),
    expect(alive(OsPid), "card A's sidecar was still hanging while B completed"),
    expect(terminal_count(CardA) =:= 0, "card A had no terminal event while B completed"),
    BComponents = scalar("SELECT count(*) FROM plan_cards, "
                         "jsonb_object_keys(content_jsonb->'components') "
                         "WHERE plan_card_id = $1", [CardB]),
    expect(BComponents =:= 10, "card B's snapshot holds all ten components"),
    BEvents = event_count(CardB),

    io:format("kill -9 card A's sidecar ~s~n", [OsPid]),
    _ = os:cmd("kill -9 " ++ OsPid),
    TypesA = collect_sse(sse_url(Base, CardA), Auth),
    io:format("card A event sequence: ~p~n", [TypesA]),
    expect(lists:last(TypesA) =:= <<"turn_failed">>, "card A ends turn_failed"),
    FailedA = scalar("SELECT count(*) FROM plan_card_events WHERE plan_card_id = $1 "
                     "AND type = 'turn_failed' AND payload_jsonb->>'turn_id' = $2",
                     [CardA, TurnA]),
    expect(FailedA =:= 1, "exactly one turn_failed for card A's turn"),
    CompletedB = scalar("SELECT count(*) FROM plan_card_events WHERE plan_card_id = $1 "
                        "AND type = 'turn_completed' AND payload_jsonb->>'turn_id' = $2",
                        [CardB, TurnB]),
    expect(CompletedB =:= 1, "exactly one turn_completed for card B's turn"),
    expect(event_count(CardB) =:= BEvents, "card A's failure wrote nothing to card B"),

    io:format("~n==== CONCERN-ISOLATION SMOKE (P-1 engine): ALL ASSERTIONS PASSED ====~n"),
    halt(0).

alive(OsPid) ->
    os:cmd("kill -0 " ++ OsPid ++ " 2>/dev/null && echo yes") =:= "yes\n".

terminal_count(Card) ->
    scalar("SELECT count(*) FROM plan_card_events WHERE plan_card_id = $1 "
           "AND type IN ('turn_completed', 'turn_failed', 'turn_cancelled')", [Card]).

event_count(Card) ->
    scalar("SELECT count(*) FROM plan_card_events WHERE plan_card_id = $1", [Card]).

%% Mode B (fhb-foreign-au): owner_occupier + foreign_person, as mode_b_seam_smoke.
mode_b_body() ->
    fh_engine_util:json_encode(#{
        <<"state">> => <<"NSW">>,
        <<"target_price_range">> => [700000, 900000],
        <<"intent">> => <<"owner_occupier">>,
        <<"foreign_person">> => true,
        <<"buyer_stage">> => <<"first_home">>,
        <<"hold_horizon_years">> => 10
    }).

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
