-module(events_proxy_stub_engine).

%% Stub for the engine's SSE events endpoint, used by events_proxy_smoke (8-S4b). The
%% real engine stream (pg fan-out + replay) is proven by the engine's seam_smoke; this
%% stub lets the SHELL test exercise only the shell-new logic — the OWNERSHIP gate and
%% the TRANSPARENT relay — without the dual-`default`-pool clash. It streams a short,
%% realistic SSE sequence (turn_started → component_filled → a keepalive comment →
%% turn_completed) then closes (fin), so a sync httpc read on the shell edge completes.
%% A card id whose uuid starts "deadbeef" yields a non-2xx, to prove the relay forwards
%% a non-streaming engine error verbatim (httpc ignores {stream,self} for non-2xx).

-export([init/2]).

init(Req0, _Opts) ->
    Id = cowboy_req:binding(id, Req0),
    case Id of
        <<"deadbeef", _/binary>> ->
            Req = cowboy_req:reply(503,
                #{<<"content-type">> => <<"application/json">>},
                fh_shell_util:json_encode(#{<<"error">> => <<"engine_down">>}), Req0),
            {ok, Req, []};
        _ ->
            Req = cowboy_req:stream_reply(200, #{
                <<"content-type">>  => <<"text/event-stream">>,
                <<"cache-control">> => <<"no-cache">>
            }, Req0),
            frame(Req, 1, <<"turn_started">>, #{<<"plan_card_id">> => Id}),
            frame(Req, 2, <<"component_filled">>,
                  #{<<"component_id">> => <<"buyer_profile">>,
                    <<"renderer">> => <<"summary-card">>}),
            cowboy_req:stream_body(<<":keepalive\n\n">>, nofin, Req),
            frame(Req, 3, <<"turn_completed">>, #{<<"plan_card_id">> => Id}),
            cowboy_req:stream_body(<<>>, fin, Req),
            {ok, Req, []}
    end.

frame(Req, IdN, Type, Payload) ->
    Data = [<<"id: ">>, integer_to_binary(IdN), <<"\n">>,
            <<"event: ">>, Type, <<"\n">>,
            <<"data: ">>, fh_shell_util:json_encode(Payload), <<"\n\n">>],
    cowboy_req:stream_body(Data, nofin, Req).
