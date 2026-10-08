-module(fh_shell_h_events).

%% GET /api/plan-cards/:id/events — the SSE streaming PROXY (8-S4b, the keystone of
%% 8-S4). The first streaming relay through the shell: it tails the engine's events
%% stream (fh_engine_h_events) and forwards frames downstream to the browser's
%% EventSource. This one channel carries BOTH the live projection-fill
%% (turn_started / component_filled / usage / terminal) and the Q&A answers
%% (text_delta), so the frontend opens it once (8-S4c/8-S4d).
%%
%% TRANSPARENT relay (not a re-framer): the engine owns the SSE contract (frame
%% format, ordering, the monotonic event_id, replay on Last-Event-ID, keepalives) —
%% engine-contract §4. The shell forwards the raw body chunks verbatim and forwards
%% the client's Last-Event-ID upstream so the ENGINE does the replay/dedup. The shell
%% adds nothing but identity (the tenant JWT) + authorization (the ownership gate).
%%
%% Mechanism: httpc {stream, self} delivers the upstream body as messages to THIS
%% cowboy handler process; info/3 relays each to cowboy_req:stream_body. A cowboy
%% `loop` handler is exactly the long-lived, message-driven shape this needs.
%%
%% Liveness: NO timers here (unlike the engine, which GENERATES keepalives) — the
%% relay is transparent, so the engine's keepalives flow through as ordinary chunks
%% and keep the connection alive (the listener's reset_idle_timeout_on_send lets an
%% outbound keepalive reset cowboy's idle_timeout — see fh_shell_http). The stream
%% ends on the engine's terminal event (stream_end → fin), an upstream error, or the
%% client disconnecting (terminate cancels the upstream request — see terminate/3).

-export([init/2, info/3, terminate/3]).

init(Req0, _State) ->
    case fh_shell_http:authenticate_user(Req0) of
        {ok, #{<<"user_id">> := UserId}} ->
            PlanCardId = cowboy_req:binding(id, Req0),
            case is_binary(PlanCardId)
                andalso fh_shell_util:is_uuid(PlanCardId)
                andalso fh_shell_store:owns_plan_card(UserId, PlanCardId)
            of
                true ->
                    start_relay(UserId, PlanCardId, Req0);
                false ->
                    {ok, fh_shell_http:reply_json(404,
                        #{<<"error">> => <<"not_found">>}, Req0), undefined}
            end;
        {error, Status, ErrBody} ->
            {ok, fh_shell_http:reply_json(Status, ErrBody, Req0), undefined}
    end.

%% The ownership gate has passed: open the upstream stream and enter the loop. We do
%% NOT stream_reply yet — we wait for the upstream stream_start so a non-2xx engine
%% reply (httpc delivers it as a full response, not a stream) relays its real status
%% instead of a premature 200.
start_relay(UserId, PlanCardId, Req0) ->
    LastEventId = last_event_id(Req0),
    case fh_shell_engine_client:stream_events(UserId, PlanCardId, LastEventId) of
        {ok, ReqId} ->
            %% Trap exits so a client disconnect reaches terminate/3 (see there).
            process_flag(trap_exit, true),
            {cowboy_loop, Req0, #{req_id => ReqId, replied => false}};
        {error, _Reason} ->
            {ok, fh_shell_http:reply_json(502,
                #{<<"error">> => <<"engine_unavailable">>}, Req0), undefined}
    end.

%% Upstream began streaming (2xx): open the downstream SSE response with canonical
%% event-stream headers (not the upstream's verbatim — the shell asserts the SSE
%% contract on its own edge).
info({http, {ReqId, stream_start, _Headers}}, Req, #{req_id := ReqId} = State) ->
    Req2 = cowboy_req:stream_reply(200, #{
        <<"content-type">>  => <<"text/event-stream">>,
        <<"cache-control">> => <<"no-cache">>,
        <<"connection">>    => <<"keep-alive">>
    }, Req),
    {ok, Req2, State#{replied := true}};
%% A body chunk (an SSE frame or a keepalive comment) — relayed verbatim.
info({http, {ReqId, stream, Chunk}}, Req, #{req_id := ReqId} = State) ->
    cowboy_req:stream_body(Chunk, nofin, Req),
    {ok, Req, State};
%% Upstream closed cleanly (the engine's terminal event already rode the last chunk).
info({http, {ReqId, stream_end, _Headers}}, Req, #{req_id := ReqId} = State) ->
    cowboy_req:stream_body(<<>>, fin, Req),
    {stop, Req, State};
%% Non-2xx upstream: httpc ignores {stream,self} for non-2xx and delivers the whole
%% response in one message. We have not replied yet → relay its status + body.
info({http, {ReqId, {{_, Status, _}, _Headers, Body}}}, Req,
     #{req_id := ReqId, replied := false} = State) ->
    Req2 = cowboy_req:reply(Status,
        #{<<"content-type">> => <<"application/json">>}, Body, Req),
    {stop, Req2, State};
%% Upstream transport error. If we already opened the SSE response, just close it
%% (the client will reconnect with Last-Event-ID); otherwise surface a 502.
info({http, {ReqId, {error, _Reason}}}, Req, #{req_id := ReqId, replied := Replied} = State) ->
    Req2 = case Replied of
        true ->
            cowboy_req:stream_body(<<>>, fin, Req),
            Req;
        false ->
            cowboy_req:reply(502,
                #{<<"content-type">> => <<"application/json">>},
                fh_shell_util:json_encode(#{<<"error">> => <<"engine_stream_error">>}), Req)
    end,
    {stop, Req2, State};
info(_Other, Req, State) ->
    {ok, Req, State}.

%% Reproducible -> P-1 · One process per concern -> The shell backend -> a cancelled browser stream ends its engine stream
%% A browser stream that closes — the user leaving a plan, a reload, an EventSource
%% close — cancels the engine stream it opened, so the next stream never waits behind
%% it. Two things make that true, and each alone is not enough (measured 2026-10-08,
%% test/sse_cancel_smoke.escript, OTP 29, inets 9.8, cowboy 2.14.2): cowboy stops a
%% loop handler on client disconnect with exit(Pid, shutdown), which kills it without
%% terminate/3 unless it traps exits (start_relay sets trap_exit, and cowboy_loop turns
%% the parent's 'EXIT' into terminate/3); and the cancel must name the profile the
%% request was opened on (fh_shell_sse) — on the default profile it is a no-op. Without
%% either, the orphaned engine stream holds its httpc keep-alive session and httpc
%% queues the next request to that host behind it: a new stream got no byte for 30 s+
%% (the smoke's freeze; 2026-10-07's "plan stuck computing until reload").
terminate(_Reason, _Req, #{req_id := ReqId}) ->
    _ = httpc:cancel_request(ReqId, fh_shell_sse),
    ok;
terminate(_Reason, _Req, _State) ->
    ok.

%% The client's Last-Event-ID — header (EventSource auto-reconnect) or ?last_event_id=,
%% mirroring the engine's own resolution order. Forwarded upstream so the engine
%% replays from there; undefined → no header → the engine starts from 0.
-spec last_event_id(cowboy_req:req()) -> binary() | undefined.
last_event_id(Req) ->
    case cowboy_req:header(<<"last-event-id">>, Req, undefined) of
        undefined ->
            case lists:keyfind(<<"last_event_id">>, 1, cowboy_req:parse_qs(Req)) of
                {_, V} -> V;
                false  -> undefined
            end;
        V -> V
    end.
