-module(sse_cancel_stub_engine).

%% Stub engine for sse_cancel_conformance (behavior 29).
%%
%% Reproducible -> P-1 · One process per concern -> The shell backend -> engine streams a cancelled browser stream leaves behind
%% Every events handler registers its pid with the escript's collector (registered
%% `sse_cancel_collector`), so the escript can watch whether the upstream stream a
%% cancelled browser request opened ever closes. The plan id's first eight hex
%% digits pick the stream's shape:
%%   ffffffff… — finished: turn_started, turn_completed, fin (a plan already built);
%%   aaaaaaaa… — slow headers: 400 ms before the 200, then live;
%%   anything else — live: turn_started, then a keepalive every 200 ms, never a
%%   terminal frame (a plan mid-fill).

-export([init/2]).

init(Req0, events) ->
    Id = cowboy_req:binding(id, Req0),
    sse_cancel_collector ! {stub_stream, self(), Id},
    case Id of
        <<"aaaaaaaa", _/binary>> -> receive after 400 -> ok end;
        _ -> ok
    end,
    Req = cowboy_req:stream_reply(200, #{
        <<"content-type">>  => <<"text/event-stream">>,
        <<"cache-control">> => <<"no-cache">>
    }, Req0),
    frame(Req, 1, <<"turn_started">>, Id),
    case Id of
        <<"ffffffff", _/binary>> ->
            frame(Req, 2, <<"turn_completed">>, Id),
            cowboy_req:stream_body(<<>>, fin, Req),
            {ok, Req, []};
        _ ->
            hold(Req)
    end.

hold(Req) ->
    receive after 200 -> ok end,
    cowboy_req:stream_body(<<":keepalive\n\n">>, nofin, Req),
    hold(Req).

frame(Req, N, Type, Id) ->
    cowboy_req:stream_body([<<"id: ">>, integer_to_binary(N), <<"\nevent: ">>, Type,
                            <<"\ndata: ">>,
                            fh_shell_util:json_encode(#{<<"plan_card_id">> => Id}),
                            <<"\n\n">>], nofin, Req).
