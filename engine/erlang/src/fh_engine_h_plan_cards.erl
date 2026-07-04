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
%% (mode-b-wedge.md P5); investment+foreign → Mode D / investor-foreign-au
%% (mode-d-wedge.md P5). Every combination of the two axes is now in scope.

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
%% Foreign investor (Mode D, mode-d-wedge.md P5) — investment intent + foreign person.
%% Previously failed closed here (investment+foreign routed to {error,
%% unsupported_combination} rather than silently landing on the DOMESTIC investor
%% blueprint, which reasons about neither FIRB eligibility nor the foreign-buyer surcharge
%% — a compliance-misadvice risk, constraint 10). Now built and in scope.
blueprint_for(<<"investment">>, true) -> {<<"investor-foreign-au">>, <<"D">>};
%% Both `true`-foreign Intent values (owner_occupier, investment — intent_of/1 admits no
%% third) are now matched above; this is unreachable given today's two-value Intent axis,
%% kept as a defensive fallback should that axis ever grow. NOTE what this does NOT gate:
%% blueprint_for/2 only sees intent × foreign, never first-home — so a foreign NEXT-home
%% buyer (owner_occupier + foreign + not-first-home, the Mode-E gap's foreign twin) still
%% resolves to Mode B at this layer. The first-home restriction is a SHELL-ONLY gate
%% (Onboarding.svelte's `eligibleForeign` requires firstHome===true before submit) — there
%% is no engine-level backstop for that cell, unlike the investment+foreign case this
%% clause used to fail closed on.
blueprint_for(_, true) -> {error, unsupported_combination};
blueprint_for(<<"investment">>, false) -> {<<"investor-domestic-au">>, <<"C">>};
blueprint_for(_, false) -> {<<"fhb-domestic-au">>, <<"A">>}.
