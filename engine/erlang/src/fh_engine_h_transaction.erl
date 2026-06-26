-module(fh_engine_h_transaction).

%% POST /api/engine/plan-cards/:id/properties/:pid/transaction — submit the user-attested
%% contract dates for an ALREADY-ATTACHED property and run a resolver-only re-fill that
%% activates settlement_prep's dated path (engine-contract §11; `<from_transaction>`, the
%% THIRD per-property input layer — facts the user ATTESTS about their transaction, distinct
%% from the source-supplied property_card and from the heavier `<from_document>` extraction).
%%
%% Body: {contract_signed_date, settlement_date} — both ISO yyyy-mm-dd; settlement strictly
%% after contract. The property must already be attached (else 409 — there is no addendum slot
%% to write into). No preview primitive (§11). Returns {plan_card_id, property_id, turn_id};
%% the resolver-only re-fill streams component_filled{fill_path: resolver} + turn_completed via
%% the existing .../events SSE (no usage event — a transaction submit is free).

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
        {ok, #{tenant_id := T, user_id := U}} ->
            PlanCardId = cowboy_req:binding(id, Req0),
            PropertyId = cowboy_req:binding(pid, Req0),
            case fh_engine_store:get_plan_card(T, PlanCardId) of
                {ok, Card} ->
                    read_and_submit(T, U, PlanCardId, PropertyId, Card, Req0, State);
                {error, not_found} ->
                    {ok, fh_engine_http:reply_json(404,
                        #{<<"error">> => <<"not_found">>}, Req0), State}
            end;
        {error, Status, Body} ->
            {ok, fh_engine_http:reply_json(Status, Body, Req0), State}
    end.

read_and_submit(T, U, PlanCardId, PropertyId, Card, Req0, State) ->
    Content = maps:get(<<"content">>, Card, #{}),
    Addenda = maps:get(<<"addenda">>, Content, #{}),
    case maps:find(PropertyId, Addenda) of
        error ->
            %% no addendum slot to write into — the property must be attached first (§11).
            {ok, fh_engine_http:reply_json(409,
                #{<<"error">> => <<"property_not_attached">>,
                  <<"detail">> => <<"attach the property before submitting its transaction dates">>},
                Req0), State};
        {ok, Addendum} ->
            case fh_engine_http:read_json_body(Req0) of
                {ok, Body, Req1} ->
                    submit(T, U, PlanCardId, PropertyId, Card, Content, Addendum, Body, Req1, State);
                {error, invalid_json} ->
                    {ok, fh_engine_http:reply_json(400,
                        #{<<"error">> => <<"invalid_json">>}, Req0), State}
            end
    end.

submit(T, U, PlanCardId, PropertyId, Card, Content, Addendum, Body, Req, State) ->
    case validate_dates(Body) of
        {error, Code} ->
            {ok, fh_engine_http:reply_json(400,
                #{<<"error">> => <<"invalid_transaction_dates">>,
                  <<"code">> => Code}, Req), State};
        {ok, Transaction} ->
            ok = fh_engine_store:set_transaction(PlanCardId, PropertyId, Transaction),
            start_refill(T, U, PlanCardId, PropertyId, Card, Content, Addendum, Transaction,
                         Req, State)
    end.

start_refill(T, U, PlanCardId, PropertyId, Card, Content, Addendum, Transaction, Req, State) ->
    TurnId = fh_engine_util:uuid4(),
    case fh_engine_turn_registry:reserve(PlanCardId, TurnId) of
        {error, in_flight} ->
            {ok, fh_engine_http:reply_json(409,
                #{<<"error">> => <<"turn_in_flight">>,
                  <<"detail">> => <<"a turn is already running for this card">>}, Req), State};
        ok ->
            Mode = maps:get(<<"mode">>, Card, <<"C">>),
            {ok, _Pid} = fh_engine_turn_sup:start_turn(#{
                tenant_id => T,
                user_id => U,
                plan_card_id => PlanCardId,
                turn_id => TurnId,
                blueprint_slug => maps:get(<<"blueprint_slug">>, Card),
                mode => Mode,
                intent => maps:get(<<"intent">>, Card, <<"investment">>),
                firb_required_any => false,
                kind => transaction,
                property_id => PropertyId,
                transaction => Transaction,
                %% settlement_prep reads base outcomes (profile) + the addendum's per-property
                %% outcomes (property_fit_investor, tax_optimised_structure) as upstream; the
                %% turn re-keys both by outcome_type at init.
                base_components_snapshot => maps:get(<<"components">>, Content, #{}),
                addendum_components_snapshot => maps:get(<<"components">>, Addendum, #{})
            }),
            Body = #{<<"plan_card_id">> => PlanCardId,
                     <<"property_id">> => PropertyId,
                     <<"turn_id">> => TurnId},
            {ok, fh_engine_http:reply_json(202, Body, Req), State}
    end.

%% both dates ISO yyyy-mm-dd + calendar-valid, and settlement strictly after contract. Returns
%% the normalized transaction map (binary keys — the shape the resolver + store expect).
validate_dates(Body) when is_map(Body) ->
    C = maps:get(<<"contract_signed_date">>, Body, undefined),
    S = maps:get(<<"settlement_date">>, Body, undefined),
    case {parse_date(C), parse_date(S)} of
        {{ok, CD}, {ok, SD}} ->
            case calendar:date_to_gregorian_days(SD) > calendar:date_to_gregorian_days(CD) of
                true  -> {ok, #{<<"contract_signed_date">> => C,
                                <<"settlement_date">> => S}};
                false -> {error, <<"settlement_not_after_contract">>}
            end;
        {error, _} -> {error, <<"contract_signed_date_invalid">>};
        {_, error} -> {error, <<"settlement_date_invalid">>}
    end;
validate_dates(_) ->
    {error, <<"body_must_be_object">>}.

parse_date(<<Y:4/binary, "-", M:2/binary, "-", D:2/binary>>) ->
    try
        Date = {binary_to_integer(Y), binary_to_integer(M), binary_to_integer(D)},
        case calendar:valid_date(Date) of
            true  -> {ok, Date};
            false -> error
        end
    catch _:_ -> error end;
parse_date(_) -> error.
