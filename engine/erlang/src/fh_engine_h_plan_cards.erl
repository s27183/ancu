-module(fh_engine_h_plan_cards).

%% POST /api/engine/plan-cards — create a plan card from onboarding inputs
%% (mode/state/target price range/target zone/intent) and start the base planning
%% turn (engine-contract §2.1, constraint #1 plan-first). Returns {plan_card_id,
%% turn_id}; events stream from GET .../events. Plan-first: no property required.

-export([init/2]).
%% exported for blueprint_for_conformance.escript (mode-e-wedge.md P5) — the pure
%% three-axis dispatch + its per-axis defaulting behaviour, no PG/HTTP needed to test it.
-export([blueprint_for/3, stage_of/1, foreign_of/1, intent_of/1]).

%% Mode is a DERIVED label; the blueprint is selected by THREE onboarding axes
%% (engine-contract §9.1; fact-model-unification.md "Mode is derived — three axes"):
%% `intent` (owner_occupier | investment), a foreign-person signal, and — orthogonal to
%% both, meaningful ONLY when intent=owner_occupier — `buyer_stage` (first_home |
%% next_home, mode-e-wedge.md P0/P5). owner_occupier+domestic+first_home → Mode A /
%% fhb-domestic-au; owner_occupier+domestic+next_home → Mode E / nexthome-domestic-au
%% (mode-e-wedge.md P5); investment+domestic → Mode C / investor-domestic-au (stage
%% axis irrelevant); owner_occupier+foreign+first_home → Mode B / fhb-foreign-au
%% (mode-b-wedge.md P5); investment+foreign → Mode D / investor-foreign-au (mode-d-wedge.md
%% P5, stage axis irrelevant). owner_occupier+foreign+next_home (the Mode-E gap's foreign
%% twin) fails closed — a real combinatorial cell, not yet built (mode-e-wedge.md decision
%% #4).

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
    Stage = stage_of(Params),
    case blueprint_for(Intent, Foreign, Stage) of
        {error, Reason} ->
            %% Two distinct 400 reasons (mode-e-wedge.md P5): unsupported_combination (a
            %% known cell not yet built, e.g. foreign+next-home) vs missing_buyer_stage (a
            %% required input simply absent) — kept as separate error codes rather than one
            %% generic reason, so a caller can tell "not yet supported" from "you forgot a
            %% field" without guessing from the same string.
            {ok, fh_engine_http:reply_json(400,
                #{<<"error">> => atom_to_binary(Reason, utf8)}, Req), State};
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

%% The buyer-stage axis (mode-e-wedge.md P0/P5) — ORTHOGONAL to intent/foreign, meaningful
%% ONLY when intent=owner_occupier (investment has no first-home concept; C/D ignore it).
%% self-DECLARED at onboarding, never derived from any fact on file.
%% NEITHER value is a safe silent default (unlike foreign_of/1, where false/domestic is the
%% genuinely-safer LESS-claims direction): first_home risks asserting FHG/FHSS entitlement
%% a repeat buyer can't claim (misadvice, constraint 10) — the risk the scoping decision
%% named — but silently defaulting absent input to next_home is its own footgun, not a fix:
%% it would silently route the Wedge-1a flagship audience (a genuine first-home buyer whose
%% caller omitted the field) to Mode E instead of Mode A, and it maps malformed input to a
%% VALID mode rather than surfacing the bad input (fail-OPEN on garbage — the same
%% anti-pattern already flagged in [[firsthomey-outcome-validate-fail-open-gap]]). So
%% absent/malformed degrades to `undefined` (neither value), and blueprint_for/3 fails
%% CLOSED on `undefined` for owner_occupier — a loud, debuggable 400, not a plausible-but-
%% wrong plan. "Self-declared, never defaulted to first_home" reads as "required", not
%% "defaulted to the safer-sounding value" — investment ignores buyer_stage entirely, so
%% requiring it for owner_occupier costs those callers nothing; the shell (the only caller,
%% mode-e-wedge.md P5) always sends it explicitly once `firstHome` is answered.
stage_of(Params) ->
    case maps:get(<<"buyer_stage">>, Params, undefined) of
        <<"first_home">> -> <<"first_home">>;
        <<"next_home">> -> <<"next_home">>;
        _ -> undefined
    end.

%% Select the blueprint + derived mode label from the three onboarding axes (mode-c-wedge.md
%% P5-activate + mode-b-wedge.md P5 + mode-d-wedge.md P5 + mode-e-wedge.md P5).
%% owner_occupier REQUIRES a resolved buyer_stage — fails closed (not defaulted) on
%% absent/malformed input; matched FIRST so it never falls through to a guessed mode.
blueprint_for(<<"owner_occupier">>, _Foreign, undefined) -> {error, missing_buyer_stage};
blueprint_for(<<"owner_occupier">>, true, <<"first_home">>) -> {<<"fhb-foreign-au">>, <<"B">>};
%% Foreign + next-home (the Mode-E gap's foreign twin, mode-e-wedge.md decision #4) — a
%% real combinatorial cell, not yet built: established-dwelling-ban interaction with an
%% existing AU property is a distinct regulated question from Mode B's. Previously this
%% cell fell through to Mode B with no engine-level backstop (shell-gate-only); now fails
%% closed here too, closing that gap.
blueprint_for(<<"owner_occupier">>, true, <<"next_home">>) -> {error, unsupported_combination};
%% Foreign investor (Mode D, mode-d-wedge.md P5) — investment intent + foreign person; the
%% stage axis is irrelevant to investment, so it is not matched here (any Stage value).
%% Previously failed closed here (investment+foreign routed to {error,
%% unsupported_combination} rather than silently landing on the DOMESTIC investor
%% blueprint, which reasons about neither FIRB eligibility nor the foreign-buyer surcharge
%% — a compliance-misadvice risk, constraint 10). Now built and in scope.
blueprint_for(<<"investment">>, true, _) -> {<<"investor-foreign-au">>, <<"D">>};
%% Both `true`-foreign Intent values (owner_occupier, investment — intent_of/1 admits no
%% third) are now matched above for every Stage; this is unreachable given today's
%% two-value Intent axis, kept as a defensive fallback should that axis ever grow.
blueprint_for(_, true, _) -> {error, unsupported_combination};
blueprint_for(<<"investment">>, false, _) -> {<<"investor-domestic-au">>, <<"C">>};
%% Domestic + owner_occupier is where the stage axis bites (mode-e-wedge.md P5):
%% next_home → Mode E / nexthome-domestic-au; first_home (the only other value Stage can
%% hold here — `undefined` was already caught above) → Mode A, the unchanged pre-P5
%% fallthrough.
blueprint_for(<<"owner_occupier">>, false, <<"next_home">>) -> {<<"nexthome-domestic-au">>, <<"E">>};
blueprint_for(_, false, _) -> {<<"fhb-domestic-au">>, <<"A">>}.
