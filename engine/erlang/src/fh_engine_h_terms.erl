-module(fh_engine_h_terms).

%% Bilingual -> P-7 · The KB -> The engine -> the term list read
%% GET /api/engine/terms — the compiled KB terms (fh_engine_kb:all_terms/0) the web marks
%% and explains on a tap (behavior 102). Global KB content like /api/engine/facts: the
%% tenant JWT is authenticated (a registered shell mints it), nothing is scoped by
%% tenant or card.

-export([init/2]).

init(Req0, State) ->
    case cowboy_req:method(Req0) of
        <<"GET">> ->
            case fh_engine_http:authenticate(Req0) of
                {ok, _Claims} ->
                    {ok, fh_engine_http:reply_json(200,
                        #{<<"terms">> => fh_engine_kb:all_terms()}, Req0), State};
                {error, Status, Body} ->
                    {ok, fh_engine_http:reply_json(Status, Body, Req0), State}
            end;
        _ ->
            {ok, fh_engine_http:reply_json(405,
                #{<<"error">> => <<"method_not_allowed">>}, Req0), State}
    end.
