-module(fh_engine_h_facts).

%% Reproducible -> P-2 · The database is the single source of truth -> The engine -> the first-visit facts read
%% GET /api/engine/facts — the compiled KB fact docs (fh_engine_kb:all_facts/0) the
%% first-visit sheet draws (behavior 42). Global KB content like /api/engine/news: the
%% tenant JWT is authenticated (a registered shell mints it), nothing is scoped by
%% tenant or card.

-export([init/2]).

init(Req0, State) ->
    case cowboy_req:method(Req0) of
        <<"GET">> ->
            case fh_engine_http:authenticate(Req0) of
                {ok, _Claims} ->
                    {ok, fh_engine_http:reply_json(200,
                        #{<<"facts">> => fh_engine_kb:all_facts()}, Req0), State};
                {error, Status, Body} ->
                    {ok, fh_engine_http:reply_json(Status, Body, Req0), State}
            end;
        _ ->
            {ok, fh_engine_http:reply_json(405,
                #{<<"error">> => <<"method_not_allowed">>}, Req0), State}
    end.
