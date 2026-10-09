-module(fh_engine_h_health).

%% GET /api/engine/health (and /health) — readiness probe (engine-contract §2.1). No auth: a load
%% balancer / orchestrator must reach it without a tenant token.

-export([init/2]).

init(Req0, State) ->
    Req = fh_engine_http:reply_json(200, #{<<"status">> => <<"ok">>}, Req0),
    {ok, Req, State}.
