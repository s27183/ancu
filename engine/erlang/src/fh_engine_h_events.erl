-module(fh_engine_h_events).

%% GET /api/engine/plan-cards/:id/events — Server-Sent Events stream of the typed
%% event log for a plan card (engine-contract §4). Reconnect with `Last-Event-ID`
%% (header or ?last_event_id=) replays missed events.
%%
%% Ordering (the §4 guarantee): subscribe to the live pg group FIRST, THEN replay
%% from plan_card_events (the SOT) since Last-Event-ID, THEN stream live — deduping
%% on the monotonic event_id (an event appended-before-query lands in replay; one
%% appended-after lands live; one in both is dropped by the high-water mark). If the
%% turn already finished, the terminal event is in the replay and the stream closes.

-export([init/2, info/3, terminate/3]).

%% Safety cap so a wedged stream can't pin a connection forever; the turn always
%% emits a terminal event, so a healthy stream closes well before this.
-define(SSE_TIMEOUT, 120000).

init(Req0, _State) ->
    case fh_engine_http:authenticate(Req0) of
        {ok, #{tenant_id := T}} ->
            PlanCardId = cowboy_req:binding(id, Req0),
            case fh_engine_store:get_plan_card(T, PlanCardId) of
                {ok, _} -> start_stream(T, PlanCardId, Req0);
                {error, not_found} ->
                    {ok, fh_engine_http:reply_json(404,
                        #{<<"error">> => <<"not_found">>}, Req0), undefined}
            end;
        {error, Status, Body} ->
            {ok, fh_engine_http:reply_json(Status, Body, Req0), undefined}
    end.

start_stream(T, PlanCardId, Req0) ->
    LastEventId = last_event_id(Req0),
    ok = fh_engine_pubsub:subscribe(PlanCardId),
    Req = cowboy_req:stream_reply(200, #{
        <<"content-type">> => <<"text/event-stream">>,
        <<"cache-control">> => <<"no-cache">>,
        <<"connection">> => <<"keep-alive">>
    }, Req0),
    Replay = fh_engine_store:events_since(T, PlanCardId, LastEventId),
    MaxId = stream_all(Req, Replay, LastEventId),
    case terminal_in(Replay) of
        true ->
            finish(Req),
            {ok, Req, undefined};
        false ->
            TRef = erlang:send_after(?SSE_TIMEOUT, self(), sse_timeout),
            {cowboy_loop, Req,
             #{plan_card_id => PlanCardId, max_id => MaxId, tref => TRef}}
    end.

info({plan_card_event, PlanCardId, {Id, Type, Payload}}, Req,
     #{plan_card_id := PlanCardId, max_id := MaxId} = State) ->
    case Id > MaxId of
        true ->
            stream_event(Req, Id, Type, Payload),
            case terminal_type(Type) of
                true -> finish(Req), {stop, Req, State};
                false -> {ok, Req, State#{max_id := Id}}
            end;
        false ->
            {ok, Req, State}
    end;
info(sse_timeout, Req, State) ->
    finish(Req),
    {stop, Req, State};
info(_Other, Req, State) ->
    {ok, Req, State}.

terminate(_Reason, _Req, #{tref := TRef}) ->
    erlang:cancel_timer(TRef),
    ok;
terminate(_Reason, _Req, _State) ->
    ok.

%% --- internals --------------------------------------------------------------

stream_all(Req, Events, Acc0) ->
    lists:foldl(
        fun({Id, Type, P}, Acc) -> stream_event(Req, Id, Type, P), max(Id, Acc) end,
        Acc0, Events).

stream_event(Req, Id, Type, Payload) ->
    Frame = [<<"id: ">>, integer_to_binary(Id), <<"\n">>,
             <<"event: ">>, Type, <<"\n">>,
             <<"data: ">>, fh_engine_util:json_encode(Payload), <<"\n\n">>],
    cowboy_req:stream_body(Frame, nofin, Req).

finish(Req) ->
    cowboy_req:stream_body(<<>>, fin, Req).

terminal_in(Events) ->
    lists:any(fun({_, Type, _}) -> terminal_type(Type) end, Events).

terminal_type(<<"turn_completed">>) -> true;
terminal_type(<<"turn_cancelled">>) -> true;
terminal_type(<<"turn_failed">>) -> true;
terminal_type(_) -> false.

last_event_id(Req) ->
    case cowboy_req:header(<<"last-event-id">>, Req, undefined) of
        undefined ->
            case lists:keyfind(<<"last_event_id">>, 1, cowboy_req:parse_qs(Req)) of
                {_, V} -> to_int(V);
                false -> 0
            end;
        V -> to_int(V)
    end.

to_int(undefined) -> 0;
to_int(Bin) ->
    try binary_to_integer(Bin) catch _:_ -> 0 end.
