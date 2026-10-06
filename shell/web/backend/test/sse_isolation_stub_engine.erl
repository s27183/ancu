-module(sse_isolation_stub_engine).

%% Stub engine for sse_isolation_smoke (P-1, shell half).
%%
%% Reproducible -> P-1 · One process per concern -> The shell backend -> an engine SSE stream that never ends
%% The events route sends turn_started, then a `:keepalive` comment every second and
%% never a terminal frame, so every stream the shell proxies stays open for as long as
%% its browser holds it: the shape that once wedged httpc's default pool. The plain
%% routes (`plan-cards/:id`, `suburbs`) answer at once, so any delay the smoke measures
%% on them is the shell's, not the stub's.

-export([init/2]).

init(Req0, events) ->
    Id = cowboy_req:binding(id, Req0),
    Req = cowboy_req:stream_reply(200, #{
        <<"content-type">>  => <<"text/event-stream">>,
        <<"cache-control">> => <<"no-cache">>
    }, Req0),
    Data = [<<"id: 1\nevent: turn_started\ndata: ">>,
            fh_shell_util:json_encode(#{<<"plan_card_id">> => Id}), <<"\n\n">>],
    cowboy_req:stream_body(Data, nofin, Req),
    hold(Req);
init(Req0, plan_card) ->
    Id = cowboy_req:binding(id, Req0),
    json(Req0, #{<<"plan_card_id">> => Id, <<"content">> => #{<<"components">> => #{}}});
init(Req0, suburbs) ->
    json(Req0, #{<<"state">> => <<"NSW">>, <<"suburbs">> => []}).

hold(Req) ->
    receive after 1000 -> ok end,
    cowboy_req:stream_body(<<":keepalive\n\n">>, nofin, Req),
    hold(Req).

json(Req0, Map) ->
    Req = cowboy_req:reply(200, #{<<"content-type">> => <<"application/json">>},
                           fh_shell_util:json_encode(Map), Req0),
    {ok, Req, []}.
