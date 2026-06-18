-module(fh_engine_h_simulate).

%% POST /api/engine/plan-cards/:id/simulate — the simulate PREVIEW (engine-contract
%% §10.1). Body: {"overrides": {"target_price": <number>, "state": <"NSW"|...>}}.
%%
%% Recomputes the base plan under the structural what-if overrides and returns the
%% recomputed outcomes in the 200 BODY. A PREVIEW, not a turn: no persist, no
%% plan_card_events, no usage, no audit, serialization-exempt (fh_engine_simulate).
%% Runs only the Layer-1 structural gate; the full FIRB/ASIC/AML pipeline runs at
%% COMMIT (the refine turn, W7b — §10.3).
%%
%% Authenticated + tenant-scoped (unlike the dev-only /rerun): get_plan_card(T, Id)
%% confirms the card belongs to the caller's tenant (404 otherwise) BEFORE the facts
%% are read for the recompute.

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
            Id = cowboy_req:binding(id, Req0),
            %% Tenant-scope: confirm ownership before reading the card's facts.
            case fh_engine_store:get_plan_card(T, Id) of
                {ok, _Card} -> read_and_run(Id, Req0, State);
                {error, not_found} ->
                    {ok, fh_engine_http:reply_json(404,
                        #{<<"error">> => <<"not_found">>}, Req0), State}
            end;
        {error, Status, Body} ->
            {ok, fh_engine_http:reply_json(Status, Body, Req0), State}
    end.

read_and_run(Id, Req0, State) ->
    case fh_engine_http:read_json_body(Req0) of
        {ok, Body, Req1} -> run(Id, Body, Req1, State);
        {error, invalid_json} ->
            {ok, fh_engine_http:reply_json(400,
                #{<<"error">> => <<"invalid_json">>}, Req0), State}
    end.

run(Id, Body, Req, State) ->
    Overrides = maps:get(<<"overrides">>, Body, #{}),
    %% Ownership already confirmed; the facts live on the profile (facts_jsonb).
    case fh_engine_store:get_card_rerun_context(Id) of
        {error, not_found} ->
            {ok, fh_engine_http:reply_json(404,
                #{<<"error">> => <<"not_found">>}, Req), State};
        {ok, Ctx} ->
            Facts = maps:get(facts, Ctx),
            Onboarding0 = maps:get(<<"onboarding">>, Facts, #{}),
            Intent = maps:get(intent, Ctx, <<"owner_occupier">>),
            case fh_engine_simulate:apply_overrides(Overrides, Onboarding0) of
                {ok, Onboarding} -> preview(Id, Overrides, Onboarding, Intent, Req, State);
                {error, Reason}  -> reject(Reason, Req, State)
            end
    end.

preview(Id, Overrides, Onboarding, Intent, Req, State) ->
    try fh_engine_simulate:run(Onboarding, Intent) of
        {ok, Outcomes} ->
            Resp = #{<<"plan_card_id">> => Id,
                     <<"overrides">> => Overrides,
                     <<"outcomes">> => Outcomes},
            {ok, fh_engine_http:reply_json(200, Resp, Req), State}
    catch
        Class:Why:St ->
            %% A non-conforming resolver outcome is an engine bug, not user error — and
            %% fail-closed means the bad (unpersisted) outcome must never reach the
            %% client as a 200. Log + 500.
            logger:error("[simulate] recompute failed for card ~s: ~p:~p~n~p",
                         [Id, Class, Why, St]),
            {ok, fh_engine_http:reply_json(500,
                #{<<"error">> => <<"outcome_nonconforming">>}, Req), State}
    end.

reject(property_type_phase_b, Req, State) ->
    {ok, fh_engine_http:reply_json(400,
        #{<<"error">> => <<"override_not_supported">>,
          <<"field">> => <<"property_type">>,
          <<"detail">> => <<"property_type is a Phase-B (per-property) simulate "
                            "dimension; attach a property to vary it. Base simulate "
                            "accepts target_price and state.">>}, Req), State};
reject({unknown_override, K}, Req, State) ->
    {ok, fh_engine_http:reply_json(400,
        #{<<"error">> => <<"unknown_override">>, <<"field">> => K}, Req), State};
reject({invalid_override, K}, Req, State) ->
    {ok, fh_engine_http:reply_json(400,
        #{<<"error">> => <<"invalid_override">>, <<"field">> => K}, Req), State};
reject(not_a_map, Req, State) ->
    {ok, fh_engine_http:reply_json(400,
        #{<<"error">> => <<"invalid_overrides">>,
          <<"detail">> => <<"`overrides` must be an object">>}, Req), State}.
