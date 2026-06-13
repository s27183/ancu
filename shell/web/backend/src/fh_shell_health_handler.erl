-module(fh_shell_health_handler).

%% GET /health — liveness probe (no auth). Mirrors the engine's health handler:
%% a 200 with a small JSON body is enough for a load balancer / the frontend's
%% startup check. Does not probe Postgres (boot already fail-closed on the pool +
%% migrations, so a live listener implies a migrated DB).

-behaviour(cowboy_handler).
-export([init/2]).

init(Req0, State) ->
    Req = fh_shell_http:reply_json(200, #{<<"status">> => <<"ok">>,
                                          <<"service">> => <<"fh_shell">>}, Req0),
    {ok, Req, State}.
