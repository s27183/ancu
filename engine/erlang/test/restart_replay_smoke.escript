#!/usr/bin/env escript
%%! -sname fh_restart_replay_smoke
%%
%% P-2's check: what a client streamed before an engine restart is exactly what it
%% replays after it.
%%
%% Reproducible -> P-2 · The database is the single source of truth -> Mechanisms -> streamed before restart equals replayed after
%% Falsifier (invariants.md P-2): after a forced engine restart, a card's replayed events
%% differ from what was streamed before it. A Mode B card (resolver-only, no sidecar) runs
%% its base turn and is read to its end over SSE, frames kept whole (id, event, data); its
%% projection is read with GET plan-cards/:id. Then the engine is restarted in this VM:
%% fh_engine and pgo are stopped — the cowboy listener, every turn and pubsub process and
%% the connection pool die — and started again from the database alone (KB reloaded,
%% migrations re-run). The card's events are replayed with `Last-Event-ID: 0` and the
%% projection read again: ids, types and payloads, and the projection, must be equal.
%% ENGINE_DEV_PROVISION=0 keeps the dev boot sweep from appending a refresh turn, which
%% would add events rather than change them.
%%
%% The usage half of the falsifier (a user's usage total) is not checked here: usage
%% events come only from metered planner fills, which a stub-free run cannot produce
%% without the LLM. A separate OS process is not needed: every process cache dies with
%% the stopped applications (concluded from fh_engine_sup and pgo's own supervision).
%%
%% Run from the repo root (needs a local port and the seat's private Postgres):
%%
%%   bash scripts/live_smoke.sh restart_replay_smoke

-mode(compile).

-define(PORT, "8090").

main(_) ->
    os:putenv("FH_ENGINE_HTTP_PORT", ?PORT),
    os:putenv("ENGINE_DEV_PROVISION", "0"),
    quiet_boot(),
    {ok, _} = application:ensure_all_started(fh_engine),
    {ok, _} = application:ensure_all_started(inets),
    Base = "http://localhost:" ?PORT "/api/engine",
    Auth = seed_auth(<<"restart-replay-smoke">>),

    {Card, _Turn} = create(Base, Auth, mode_b_body()),
    io:format("card ~s (Mode B)~n", [Card]),
    Before = stream(sse_url(Base, Card), [Auth]),
    expect(element(2, lists:last(Before)) =:= <<"turn_completed">>,
           "the stream before the restart ends turn_completed"),
    {200, CardBefore} = req(get, Base ++ "/plan-cards/" ++ binary_to_list(Card), [Auth], <<>>),
    io:format("streamed ~b events before the restart~n", [length(Before)]),

    EngineSup = whereis(fh_engine_sup),
    ok = application:stop(fh_engine),
    ok = application:stop(pgo),
    expect(whereis(fh_engine_sup) =:= undefined, "the engine's supervision tree is gone"),
    expect(element(1, httpc:request(get, {Base ++ "/health", []}, [{timeout, 2000}], []))
           =:= error,
           "the listener is down between stop and start"),
    {ok, _} = application:ensure_all_started(fh_engine),
    expect(is_pid(whereis(fh_engine_sup)) andalso whereis(fh_engine_sup) =/= EngineSup,
           "a new engine tree is up"),
    io:format("engine restarted~n"),

    After = stream(sse_url(Base, Card), [Auth, {"last-event-id", "0"}]),
    io:format("replayed ~b events after the restart~n", [length(After)]),
    expect([{I, T} || {I, T, _} <- After] =:= [{I, T} || {I, T, _} <- Before],
           "replayed ids and types equal the streamed ones, in order"),
    expect(After =:= Before, "replayed payloads equal the streamed ones, byte for byte"),
    {200, CardAfter} = req(get, Base ++ "/plan-cards/" ++ binary_to_list(Card), [Auth], <<>>),
    expect(fh_engine_util:json_decode(CardAfter) =:= fh_engine_util:json_decode(CardBefore),
           "the card's projection is unchanged by the restart"),

    io:format("~n==== RESTART-REPLAY SMOKE (P-2): ALL ASSERTIONS PASSED ====~n"),
    halt(0).

%% Read one SSE stream to its close; return its frames as [{Id, Type, Data}].
stream(Url, Headers) ->
    {ok, ReqId} = httpc:request(get, {Url, Headers}, [], [{sync, false}, {stream, self}]),
    Raw = sse_loop(ReqId, <<>>),
    [F || F <- [frame(B) || B <- binary:split(Raw, <<"\n\n">>, [global])], F =/= skip].

sse_loop(ReqId, Acc) ->
    receive
        {http, {ReqId, stream_start, _}} -> sse_loop(ReqId, Acc);
        {http, {ReqId, stream, Chunk}} -> sse_loop(ReqId, <<Acc/binary, Chunk/binary>>);
        {http, {ReqId, stream_end, _}} -> Acc;
        {http, {ReqId, {error, Reason}}} -> error({sse_error, Reason})
    after 30000 ->
        expect(false, "SSE stream hung 30s with no terminal event")
    end.

frame(Block) ->
    Lines = binary:split(Block, <<"\n">>, [global]),
    Get = fun(Key) ->
        case [V || L <- Lines, {0, _} <- [binary:match(L, Key)],
                   V <- [binary:part(L, byte_size(Key), byte_size(L) - byte_size(Key))]] of
            [V | _] -> V;
            [] -> undefined
        end
    end,
    case {Get(<<"id: ">>), Get(<<"event: ">>), Get(<<"data: ">>)} of
        {undefined, _, _} -> skip;
        {_, undefined, _} -> skip;
        {I, T, D} -> {binary_to_integer(I), T, D}
    end.

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

quiet_boot() ->
    ok = logger:set_handler_config(default, level, notice).

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

expect(true, _Msg) -> ok;
expect(false, Msg) ->
    io:format("ASSERTION FAILED: ~s~n", [Msg]),
    halt(1).
