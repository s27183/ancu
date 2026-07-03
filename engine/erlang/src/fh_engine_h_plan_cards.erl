-module(fh_engine_h_plan_cards).

%% POST /api/engine/plan-cards — create a plan card from onboarding inputs
%% (mode/state/target price range/target zone/intent) and start the base planning
%% turn (engine-contract §2.1, constraint #1 plan-first). Returns {plan_card_id,
%% turn_id}; events stream from GET .../events. Plan-first: no property required.

-export([init/2]).

%% Mode is a DERIVED label; the blueprint is selected by TWO independent onboarding axes
%% (engine-contract §9.1): `intent` (owner_occupier | investment) and a foreign-person
%% signal. owner_occupier+domestic → Mode A / fhb-domestic-au; investment+domestic →
%% Mode C / investor-domestic-au; owner_occupier+foreign → Mode B / fhb-foreign-au
%% (mode-b-wedge.md P5). investment+foreign (Mode D) is NOT YET IN SCOPE — see
%% blueprint_for/2's fail-closed clause.

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
    Foreign = foreign_of(Params),
    case blueprint_for(Intent, Foreign) of
        {error, unsupported_combination} ->
            {ok, fh_engine_http:reply_json(400,
                #{<<"error">> => <<"unsupported_combination">>}, Req), State};
        {Blueprint, Mode} ->
            %% Onboarding inputs become the initial household fact base (slice 2's
            %% buyer_profile / investor_profile fill enriches it). firb_required_any is
            %% the SAME flag every Mode-B resolver + the compliance FIRB gate key on
            %% (fh_engine_fill/mortgage/cash/ownership.erl, fh_engine_compliance.erl).
            Facts = #{
                <<"onboarding">> => Params,
                <<"derived">> => #{<<"firb_required_any">> => Foreign}
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
                firb_required_any => Foreign,
                %% Onboarding inputs ground the base turn's buyer_profile fill (constraint
                %% #1 plan-first; the deep facts — including visa_class — arrive via chat
                %% on a later refine turn, which will load the enriched profile from the
                %% profiles SOT; buyer_profile_foreign/1 asserts visa_class=null at base
                %% by design, mode-b-wedge.md P2).
                onboarding => Params
            }),
            Body = #{<<"plan_card_id">> => PlanCardId, <<"turn_id">> => TurnId},
            {ok, fh_engine_http:reply_json(202, Body, Req), State}
    end.

%% The intent axis of mode (engine-contract §9.1): owner_occupier | investment.
intent_of(Params) ->
    case maps:get(<<"intent">>, Params, <<"owner_occupier">>) of
        <<"investment">> -> <<"investment">>;
        _ -> <<"owner_occupier">>
    end.

%% The FIRB axis (mode-b-wedge.md P5) — ORTHOGONAL to intent (engine-contract §9.1's two
%% independent onboarding axes), never folded into a single wider intent-like enum.
%% Non-boolean/absent degrades to false (domestic), never a fail-open foreign assertion.
foreign_of(Params) ->
    maps:get(<<"foreign_person">>, Params, false) =:= true.

%% Select the blueprint + derived mode label from the two onboarding axes (mode-c-wedge.md
%% P5-activate + mode-b-wedge.md P5).
blueprint_for(<<"owner_occupier">>, true) -> {<<"fhb-foreign-au">>, <<"B">>};
%% Foreign investor (Mode D) is NOT YET IN SCOPE — only Mode B (foreign owner-occupier
%% FHB) is built this wedge. Fail closed rather than silently routing a foreign investor
%% onto the DOMESTIC investor blueprint, which reasons about neither FIRB eligibility nor
%% the foreign-buyer surcharge — a compliance-misadvice risk (constraint 10), not a UX
%% nicety. Onboarding.svelte is the primary backstop (never offers this combination past
%% the picker); this is the fail-closed structural gate behind it.
blueprint_for(_, true) -> {error, unsupported_combination};
blueprint_for(<<"investment">>, false) -> {<<"investor-domestic-au">>, <<"C">>};
blueprint_for(_, false) -> {<<"fhb-domestic-au">>, <<"A">>}.
