-module(fh_shell_h_suburbs).

%% GET /api/suburbs?state=NSW — the shell-side proxy that feeds the map home (8-S2).
%% The frontend never talks to the engine directly (shell-architecture.md §1); this
%% handler mints the tenant JWT and forwards to the engine's /api/engine/suburbs
%% (8-S1), relaying the engine's status + body verbatim.
%%
%% PUBLIC (no user JWT): the map is the pre-login landing surface and `suburbs` is
%% global CC-BY reference data. The shell still authenticates to the engine with a
%% short-lived tenant JWT scoped to the anonymous system principal
%% (fh_shell_engine_client). Login gates plan-cards + commerce in later slices, not
%% this read-only reference surface.

-export([init/2]).

init(Req0, State) ->
    case cowboy_req:method(Req0) of
        <<"GET">> ->
            St = cowboy_req:match_qs([{state, [], undefined}], Req0),
            #{state := StateParam} = St,
            {Status, Body} = fh_shell_engine_client:list_suburbs(StateParam),
            Req = cowboy_req:reply(Status,
                #{<<"content-type">> => <<"application/json">>}, Body, Req0),
            {ok, Req, State};
        _ ->
            {ok, fh_shell_http:reply_json(405,
                #{<<"error">> => <<"method_not_allowed">>}, Req0), State}
    end.
