-module(fh_engine_h_plan_cards).

%% POST /api/engine/plan-cards — create a plan card from onboarding inputs
%% (mode/state/target price range/target zone/intent) and start the base planning
%% turn (engine-contract §2.1, constraint #1 plan-first). Returns {plan_card_id,
%% turn_id}; events stream from GET .../events. Plan-first: no property required.

-export([init/2]).

%% Mode is a DERIVED label; the blueprint is selected by the onboarding `intent` axis
%% (engine-contract §9.1). Both domestic modes are in scope (mode-c-wedge.md P5-activate):
%% owner_occupier → Mode A / fhb-domestic-au; investment → Mode C / investor-domestic-au.
%% The foreign modes (B/D) are deferred. FIRB is false for both (domestic).

init(Req0, State) ->
    case cowboy_req:method(Req0) of
        <<"POST">> -> handle_post(Req0, State);
        _ ->
            Req = fh_engine_http:reply_json(405,
                #{<<"error">> => <<"method_not_allowed">>}, Req0),
            {ok, Req, State}
    end.

handle_post(Req0, State) ->
    case fh_engine_http:authenticate(Req0) of
        {ok, #{tenant_id := T, user_id := U}} ->
            case fh_engine_http:read_json_body(Req0) of
                {ok, Params, Req1} -> create(T, U, Params, Req1, State);
                {error, invalid_json} ->
                    {ok, fh_engine_http:reply_json(400,
                        #{<<"error">> => <<"invalid_json">>}, Req0), State}
            end;
        {error, Status, Body} ->
            {ok, fh_engine_http:reply_json(Status, Body, Req0), State}
    end.

create(T, U, Params, Req, State) ->
    Intent = intent_of(Params),
    {Blueprint, Mode} = blueprint_for(Intent),
    %% Onboarding inputs become the initial household fact base (slice 2's
    %% buyer_profile / investor_profile fill enriches it). Both domestic modes enter via
    %% a non-foreign lead (firb false; the per-applicant derivation runs in the profile fill).
    Facts = #{
        <<"onboarding">> => Params,
        <<"derived">> => #{<<"firb_required_any">> => false}
    },
    {ok, ProfileId} = fh_engine_store:create_profile(T, U, Facts),
    {ok, PlanCardId} = fh_engine_store:create_plan_card(
        T, ProfileId, Blueprint, Intent, Mode, #{}),
    TurnId = fh_engine_util:uuid4(),
    ok = fh_engine_turn_registry:reserve(PlanCardId, TurnId),
    {ok, _Pid} = fh_engine_turn_sup:start_turn(#{
        tenant_id => T,
        user_id => U,
        plan_card_id => PlanCardId,
        turn_id => TurnId,
        blueprint_slug => Blueprint,
        mode => Mode,
        intent => Intent,
        firb_required_any => false,
        %% Onboarding inputs ground the base turn's buyer_profile fill (constraint
        %% #1 plan-first; the deep facts arrive via chat on a later refine turn,
        %% which will load the enriched profile from the profiles SOT).
        onboarding => Params
    }),
    Body = #{<<"plan_card_id">> => PlanCardId, <<"turn_id">> => TurnId},
    {ok, fh_engine_http:reply_json(202, Body, Req), State}.

%% The intent axis of mode (engine-contract §9.1): owner_occupier | investment.
intent_of(Params) ->
    case maps:get(<<"intent">>, Params, <<"owner_occupier">>) of
        <<"investment">> -> <<"investment">>;
        _ -> <<"owner_occupier">>
    end.

%% Select the blueprint + derived mode label from the intent axis (mode-c-wedge.md
%% P5-activate). owner_occupier → Mode A; investment → Mode C. Both domestic / in scope.
blueprint_for(<<"investment">>) -> {<<"investor-domestic-au">>, <<"C">>};
blueprint_for(_)                -> {<<"fhb-domestic-au">>, <<"A">>}.
