-module(fh_engine_h_attach_property).

%% POST /api/engine/plan-cards/:id/properties — attach a property to a plan card and run
%% the Phase-B (per-property) turn (mode-c-wedge.md "Phase B"; constraint #2 base + addenda).
%% The body is a NORMALIZED property_card (the neutral facts a source supplies — address,
%% suburb, state, price, property_type, year_built, land/internal area, strata facts). The
%% engine's contract is "given a property_card, run Phase B": what PRODUCES the card (user
%% URL paste, curator push, extension) is a separate, source-specific unit (CLAUDE.md items
%% 8/9), deferred. Returns {plan_card_id, property_id, turn_id}; per-property events stream
%% from .../events tagged with property_id.
%%
%% Slice A wires ONLY the investor `property_assessment` keystone (→ property_fit_investor):
%% a non-investor card or a card whose blueprint has no built per-property turn → 400. The
%% attach + turn-start are serialized by the per-card turn registry (409 if a turn is in
%% flight) — so a base turn and a Phase-B turn never race on the same card.

-export([init/2]).
-export([validate_card/2]).  %% the attach gate, exported for its conformance escript

init(Req0, State) ->
    case cowboy_req:method(Req0) of
        <<"POST">> -> handle_post(Req0, State);
        _ ->
            {ok, fh_engine_http:reply_json(405,
                #{<<"error">> => <<"method_not_allowed">>}, Req0), State}
    end.

handle_post(Req0, State) ->
    case fh_engine_http:authenticate(Req0) of
        {ok, #{tenant_id := T, user_id := U}} ->
            PlanCardId = cowboy_req:binding(id, Req0),
            case fh_engine_store:get_plan_card(T, PlanCardId) of
                {ok, Card} -> read_and_attach(T, U, PlanCardId, Card, Req0, State);
                {error, not_found} ->
                    {ok, fh_engine_http:reply_json(404,
                        #{<<"error">> => <<"not_found">>}, Req0), State}
            end;
        {error, Status, Body} ->
            {ok, fh_engine_http:reply_json(Status, Body, Req0), State}
    end.

read_and_attach(T, U, PlanCardId, Card, Req0, State) ->
    case fh_engine_http:read_json_body(Req0) of
        {ok, Body, Req1} -> attach(T, U, PlanCardId, Card, Body, Req1, State);
        {error, invalid_json} ->
            {ok, fh_engine_http:reply_json(400,
                #{<<"error">> => <<"invalid_json">>}, Req0), State}
    end.

attach(T, U, PlanCardId, Card, PropertyCard, Req, State) ->
    Slug = maps:get(<<"blueprint_slug">>, Card),
    case supports_phase_b(Slug) of
        false ->
            {ok, fh_engine_http:reply_json(400,
                #{<<"error">> => <<"phase_b_not_supported_for_blueprint">>,
                  <<"detail">> => <<"per-property attachment is wired for "
                                    "investor-domestic-au (Slice A) only">>}, Req), State};
        true ->
            case validate_card(Slug, PropertyCard) of
                {error, Field} ->
                    {ok, fh_engine_http:reply_json(400,
                        #{<<"error">> => <<"invalid_property_card">>,
                          <<"detail">> => Field}, Req), State};
                ok ->
                    start_phase_b(T, U, PlanCardId, Card, PropertyCard, Req, State)
            end
    end.

start_phase_b(T, U, PlanCardId, Card, PropertyCard, Req, State) ->
    PropertyId = fh_engine_util:uuid4(),
    %% Attach FIRST (establishes content.addenda.<pid>.components the turn snapshots into),
    %% then start the turn. The turn reads its property_card from its start args, so the
    %% write order vs the async turn is immaterial for grounding — but the addendum object
    %% must exist before snapshot_addendum_component runs (it does: attach is synchronous here).
    ok = fh_engine_store:attach_property(PlanCardId, PropertyId, PropertyCard),
    TurnId = fh_engine_util:uuid4(),
    case fh_engine_turn_registry:reserve(PlanCardId, TurnId) of
        {error, in_flight} ->
            {ok, fh_engine_http:reply_json(409,
                #{<<"error">> => <<"turn_in_flight">>,
                  <<"detail">> => <<"a turn is already running for this card">>}, Req), State};
        ok ->
            Mode = maps:get(<<"mode">>, Card, <<"C">>),
            Content = maps:get(<<"content">>, Card, #{}),
            {ok, _Pid} = fh_engine_turn_sup:start_turn(#{
                tenant_id => T,
                user_id => U,
                plan_card_id => PlanCardId,
                turn_id => TurnId,
                blueprint_slug => maps:get(<<"blueprint_slug">>, Card),
                mode => Mode,
                intent => maps:get(<<"intent">>, Card, <<"investment">>),
                firb_required_any => false,
                kind => property,
                property_id => PropertyId,
                property_card => PropertyCard,
                %% the base outcomes the per-property components read as upstream (the base
                %% turn already ran) — the turn re-keys these by outcome_type at init.
                base_components_snapshot => maps:get(<<"components">>, Content, #{})
            }),
            Body = #{<<"plan_card_id">> => PlanCardId,
                     <<"property_id">> => PropertyId,
                     <<"turn_id">> => TurnId},
            {ok, fh_engine_http:reply_json(202, Body, Req), State}
    end.

%% Slice A: only the investor blueprint has a built per-property turn (property_assessment).
supports_phase_b(<<"investor-domestic-au">>) -> true;
supports_phase_b(_)                          -> false.

%% The four neutral facts the property_assessment resolver copies into property_fit_investor;
%% price must be a number (it grounds the resolver-computed gross yield). The richer facts
%% (year_built, land_size, strata) are agent grounding — optional, validated by the fill.
%%
%% Honest-partial -> P-7 · One declaration per outcome shape -> The engine -> property_type gated by the compiled enum
%% A property is attached only if its plan's outcome can hold its property_type: the allowed
%% set is the blueprint's compiled property_fit outcome enum, read here — never a list kept
%% beside this module — so dual_occupancy, nrass, vacant_land or any unknown string gets a 400
%% naming the allowed types instead of a turn whose fill must fail on the enum (behavior 26,
%% #32). Measured 2026-10-08: test/attach_property_type_conformance.escript, 10 anchors pass
%% against priv/kb/artifact.json.
validate_card(Slug, Card) when is_map(Card) ->
    case maps:get(<<"price">>, Card, undefined) of
        P when is_number(P), P > 0 ->
            Required = [<<"state">>, <<"suburb">>, <<"property_type">>],
            case [F || F <- Required, not is_nonempty_binary(maps:get(F, Card, undefined))] of
                []      -> check_property_type(Slug, maps:get(<<"property_type">>, Card));
                [F | _] -> {error, <<F/binary, " is required">>}
            end;
        _ ->
            {error, <<"price (a positive number) is required">>}
    end;
validate_card(_, _) ->
    {error, <<"property_card must be a JSON object">>}.

check_property_type(Slug, Type) ->
    Allowed = allowed_property_types(Slug),
    case lists:member(Type, Allowed) of
        true  -> ok;
        false -> {error, iolist_to_binary([<<"property_type must be one of ">>,
                                           lists:join(<<", ">>, Allowed)])}
    end.

%% The property_type options of the blueprint's property_fit outcome (the one outcome type
%% whose name starts property_fit, e.g. property_fit_investor), from the compiled registry.
allowed_property_types(Slug) ->
    Types = fh_engine_kb:registry(Slug, <<"outcome_types">>),
    [Fit] = [V || {K, V} <- maps:to_list(Types), binary:match(K, <<"property_fit">>) =:= {0, 12}],
    maps:get(<<"options">>, maps:get(<<"property_type">>, Fit)).

is_nonempty_binary(B) when is_binary(B), B =/= <<>> -> true;
is_nonempty_binary(_)                               -> false.
