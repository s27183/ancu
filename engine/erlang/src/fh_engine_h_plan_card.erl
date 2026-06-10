-module(fh_engine_h_plan_card).

%% GET /api/engine/plan-cards/:id — fetch the raw filled plan-card state (base +
%% addenda) for the owning tenant (engine-contract §2.1 plan-card primitives). The
%% engine returns typed outcomes; the shell projects to pixels (§1 invariant).

-export([init/2]).

init(Req0, State) ->
    case cowboy_req:method(Req0) of
        <<"GET">> -> handle_get(Req0, State);
        _ ->
            {ok, fh_engine_http:reply_json(405,
                #{<<"error">> => <<"method_not_allowed">>}, Req0), State}
    end.

handle_get(Req0, State) ->
    case fh_engine_http:authenticate(Req0) of
        {ok, #{tenant_id := T}} ->
            PlanCardId = cowboy_req:binding(id, Req0),
            case fh_engine_store:get_plan_card(T, PlanCardId) of
                {ok, Card} ->
                    {ok, fh_engine_http:reply_json(200, Card, Req0), State};
                {error, not_found} ->
                    {ok, fh_engine_http:reply_json(404,
                        #{<<"error">> => <<"not_found">>}, Req0), State}
            end;
        {error, Status, Body} ->
            {ok, fh_engine_http:reply_json(Status, Body, Req0), State}
    end.
