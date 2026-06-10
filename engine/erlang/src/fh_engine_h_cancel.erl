-module(fh_engine_h_cancel).

%% POST /api/engine/plan-cards/:id/cancel — cancel an in-flight turn (engine-contract
%% §7). Idempotent: 204 when no turn is running (already finished); 202 when the
%% running turn was signalled. Caller's tenant must own the plan card.

-export([init/2]).

init(Req0, State) ->
    case cowboy_req:method(Req0) of
        <<"POST">> -> handle_post(Req0, State);
        _ ->
            {ok, fh_engine_http:reply_json(405,
                #{<<"error">> => <<"method_not_allowed">>}, Req0), State}
    end.

handle_post(Req0, State) ->
    case fh_engine_http:authenticate(Req0) of
        {ok, #{tenant_id := T}} ->
            PlanCardId = cowboy_req:binding(id, Req0),
            case fh_engine_store:get_plan_card(T, PlanCardId) of
                {ok, _} -> do_cancel(PlanCardId, Req0, State);
                {error, not_found} ->
                    {ok, fh_engine_http:reply_json(404,
                        #{<<"error">> => <<"not_found">>}, Req0), State}
            end;
        {error, Status, Body} ->
            {ok, fh_engine_http:reply_json(Status, Body, Req0), State}
    end.

do_cancel(PlanCardId, Req0, State) ->
    case fh_engine_turn_registry:lookup(PlanCardId) of
        {ok, #{pid := Pid}} when is_pid(Pid) ->
            gen_statem:cast(Pid, cancel),
            {ok, cowboy_req:reply(202, #{}, <<>>, Req0), State};
        _ ->
            %% No in-flight turn — already finished. Idempotent success.
            {ok, cowboy_req:reply(204, #{}, <<>>, Req0), State}
    end.
