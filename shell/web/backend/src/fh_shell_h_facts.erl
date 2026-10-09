-module(fh_shell_h_facts).

%% GET /api/facts — the shell-side proxy for the first-visit sheet's facts (behavior
%% 42): mints the tenant JWT and relays the engine's /api/engine/facts status + body.
%% PUBLIC (no user JWT), like /api/news: the sheet opens for a first-time visitor
%% before any sign-in.

-export([init/2]).

init(Req0, State) ->
    case cowboy_req:method(Req0) of
        <<"GET">> ->
            {Status, Body} = fh_shell_engine_client:list_facts(),
            Req = cowboy_req:reply(Status,
                #{<<"content-type">> => <<"application/json">>}, Body, Req0),
            {ok, Req, State};
        _ ->
            {ok, fh_shell_http:reply_json(405,
                #{<<"error">> => <<"method_not_allowed">>}, Req0), State}
    end.
