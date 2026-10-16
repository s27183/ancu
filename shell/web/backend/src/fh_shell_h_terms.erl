-module(fh_shell_h_terms).

%% GET /api/terms — the shell-side proxy for the term list a tap explains (behavior 102):
%% mints the tenant JWT and relays the engine's /api/engine/terms status + body.
%% PUBLIC (no user JWT), like /api/facts: a first-time visitor reads the same terms.

-export([init/2]).

init(Req0, State) ->
    case cowboy_req:method(Req0) of
        <<"GET">> ->
            {Status, Body} = fh_shell_engine_client:list_terms(),
            Req = cowboy_req:reply(Status,
                #{<<"content-type">> => <<"application/json">>}, Body, Req0),
            {ok, Req, State};
        _ ->
            {ok, fh_shell_http:reply_json(405,
                #{<<"error">> => <<"method_not_allowed">>}, Req0), State}
    end.
