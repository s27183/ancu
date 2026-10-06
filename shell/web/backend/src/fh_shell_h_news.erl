-module(fh_shell_h_news).

%% GET /api/news — the shell-side proxy feeding the homepage news ticker
%% (kb-news-feature.md "Homepage ticker", 2026-07-08). Mints the tenant JWT and
%% forwards to the engine's /api/engine/news, relaying status + body verbatim.
%%
%% PUBLIC (no user JWT): same posture as /api/suburbs (fh_shell_h_suburbs) — global
%% KB content, and the map is the pre-login landing surface.

-export([init/2]).

init(Req0, State) ->
    case cowboy_req:method(Req0) of
        <<"GET">> ->
            {Status, Body} = fh_shell_engine_client:list_all_news(),
            Req = cowboy_req:reply(Status,
                #{<<"content-type">> => <<"application/json">>}, Body, Req0),
            {ok, Req, State};
        _ ->
            {ok, fh_shell_http:reply_json(405,
                #{<<"error">> => <<"method_not_allowed">>}, Req0), State}
    end.
