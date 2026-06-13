-module(fh_shell_http).

%% The shell backend's HTTP gateway (:8081). cowboy listener embedded under
%% fh_shell_sup via ranch:child_spec (no standalone cowboy:start), exactly like the
%% engine's fh_engine_http. This module owns listener setup, routing, and the shared
%% request helpers (JSON reply + body read); handlers stay thin.
%%
%% 8-S0 surfaces only /health — the identity routes (/api/auth/*, /api/me), the
%% engine proxy (/api/plan-cards*, /api/suburbs), and commerce (/api/billing/*) land
%% in 8-S0b..8-S5 per shell-architecture.md §5. The shell backend is a proxy +
%% identity/commerce layer in front of the engine, not a re-implementation.

-export([child_spec/0, port/0]).
-export([reply_json/3, read_json_body/1]).

-spec child_spec() -> supervisor:child_spec().
child_spec() ->
    Dispatch = cowboy_router:compile(routes()),
    ranch:child_spec(fh_shell_listener, ranch_tcp,
        #{socket_opts => [{port, port()}], max_connections => 1024},
        cowboy_clear,
        #{env => #{dispatch => Dispatch}}).

routes() ->
    [{'_', [
        {"/health", fh_shell_health_handler, []}
    ]}].

-spec port() -> inet:port_number().
port() ->
    case os:getenv("FH_SHELL_HTTP_PORT") of
        false -> 8081;
        P -> list_to_integer(P)
    end.

%% --- request helpers shared by handlers ------------------------------------

-spec reply_json(cowboy:http_status(), map(), cowboy_req:req()) -> cowboy_req:req().
reply_json(Status, Body, Req) ->
    cowboy_req:reply(Status,
        #{<<"content-type">> => <<"application/json">>},
        fh_shell_util:json_encode(Body), Req).

-spec read_json_body(cowboy_req:req()) -> {ok, map(), cowboy_req:req()} | {error, term()}.
read_json_body(Req0) ->
    {ok, Bin, Req1} = read_all(Req0, <<>>),
    case Bin of
        <<>> -> {ok, #{}, Req1};
        _ ->
            try {ok, fh_shell_util:json_decode(Bin), Req1}
            catch _:_ -> {error, invalid_json}
            end
    end.

read_all(Req0, Acc) ->
    case cowboy_req:read_body(Req0) of
        {ok, Data, Req1} -> {ok, <<Acc/binary, Data/binary>>, Req1};
        {more, Data, Req1} -> read_all(Req1, <<Acc/binary, Data/binary>>)
    end.
