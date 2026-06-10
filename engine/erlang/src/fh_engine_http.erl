-module(fh_engine_http).

%% The /api/engine/* HTTP/SSE gateway (engine-contract §2.1). cowboy listener
%% embedded under fh_engine_sup via ranch:child_spec (no standalone cowboy:start).
%% This module owns listener setup, routing, and the request helpers (auth + JSON
%% reply + body read) the handler modules share. Handlers stay thin.
%%
%% Slice 1 surfaces the turn-execution + health endpoints; plan-card primitives
%% (fetch state), property attachment, artifact + usage endpoints land later.

-export([child_spec/0, port/0]).
-export([authenticate/1, reply_json/3, read_json_body/1]).

-spec child_spec() -> supervisor:child_spec().
child_spec() ->
    Dispatch = cowboy_router:compile(routes()),
    ranch:child_spec(fh_engine_listener, ranch_tcp,
        #{socket_opts => [{port, port()}], max_connections => 1024},
        cowboy_clear,
        #{env => #{dispatch => Dispatch}}).

routes() ->
    [{'_', [
        {"/api/engine/health",                  fh_engine_h_health,     []},
        {"/api/engine/plan-cards",              fh_engine_h_plan_cards, []},
        {"/api/engine/plan-cards/:id/events",   fh_engine_h_events,     []},
        {"/api/engine/plan-cards/:id/cancel",   fh_engine_h_cancel,     []},
        {"/api/engine/plan-cards/:id",          fh_engine_h_plan_card,  []}
    ]}].

-spec port() -> inet:port_number().
port() ->
    case os:getenv("FH_ENGINE_HTTP_PORT") of
        false -> 8080;
        P -> list_to_integer(P)
    end.

%% --- request helpers shared by handlers ------------------------------------

%% Validate the Bearer JWT (engine-contract §3). Returns the validated claims or a
%% ready-to-send {error, Status, BodyMap}.
-spec authenticate(cowboy_req:req()) ->
    {ok, map()} | {error, 401 | 403, map()}.
authenticate(Req) ->
    Header = cowboy_req:header(<<"authorization">>, Req, undefined),
    case fh_engine_auth:verify_bearer(Header) of
        {ok, Claims} -> {ok, Claims};
        {error, missing_authorization} ->
            {error, 401, #{<<"error">> => <<"missing_authorization">>}};
        {error, Reason} ->
            {error, 403, #{<<"error">> => <<"invalid_token">>,
                           <<"detail">> => atom_to_binary(Reason, utf8)}}
    end.

-spec reply_json(cowboy:http_status(), map(), cowboy_req:req()) -> cowboy_req:req().
reply_json(Status, Body, Req) ->
    cowboy_req:reply(Status,
        #{<<"content-type">> => <<"application/json">>},
        fh_engine_util:json_encode(Body), Req).

-spec read_json_body(cowboy_req:req()) -> {ok, map(), cowboy_req:req()} | {error, term()}.
read_json_body(Req0) ->
    {ok, Bin, Req1} = read_all(Req0, <<>>),
    case Bin of
        <<>> -> {ok, #{}, Req1};
        _ ->
            try {ok, fh_engine_util:json_decode(Bin), Req1}
            catch _:_ -> {error, invalid_json}
            end
    end.

read_all(Req0, Acc) ->
    case cowboy_req:read_body(Req0) of
        {ok, Data, Req1} -> {ok, <<Acc/binary, Data/binary>>, Req1};
        {more, Data, Req1} -> read_all(Req1, <<Acc/binary, Data/binary>>)
    end.
