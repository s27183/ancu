-module(fh_engine_h_profile).

%% POST /api/engine/plan-cards/:id/profile — write the household financial facts to the
%% profiles SOT (IC4, the complement of IC3's read path). Body:
%%   {"household_financials": {"income": {"assessable_income": <n>,
%%                                        "foreign_sourced_component": <n>},
%%                             "debts": {"hecs_balance": <n>, ...}}}
%%
%% The canonical fact-model key (fact-model-unification.md §"unified schema"); the
%% `profile` outcome is its FLAT PROJECTION (that doc §97). Card-addressed (matches
%% /refine, /simulate, /checklist-status: get_plan_card(T, Id) confirms tenant ownership
%% before any write), but the facts are PROFILE-shared — so the write fans out to every
%% sibling journey on the same profile and each is re-derived (a saved card is a computed
%% SNAPSHOT; a changed input must re-derive all snapshots, the invariant the refresh sweep
%% maintains for an artifact rebuild — plan-card-refresh.md). Profile-scoped, NOT the
%% global fleet sweep: a household has few journeys, so the fan-out is bounded.
%%
%% The recompute is RESOLVER-ONLY (fh_engine_refresh:refresh_card/1 → base_resolver turn,
%% re-attaching the stored agent leaves) → NO `usage`, no LLM. The recomputed capacity
%% rides each card's existing /events SSE (the live optimistic-UI hand-off).
%%
%% Validation is HARD + fail-closed (the facts feed a regulated figure, §98): every money
%% field a non-negative number; unknown groups/fields rejected (no silent drop). FULL-
%% REPLACE of the household_financials key — the Budget cockpit owns the full state and
%% submits it whole (the set_card_target precedent, no patch-deletion). Scope is the
%% CONSUMED fields only (income.{assessable_income, foreign_sourced_component} + the five
%% debts the serviceability resolver reads); savings/income_stability/etc. are rejected
%% until their consumer is wired (write-reader pairing — no dead inputs).

-export([init/2]).
-export([validate_financials/1]).

%% Accepted fields = exactly those IC3 projects into the profile outcome (consumed).
-define(GROUP_KEYS,  [<<"income">>, <<"debts">>]).
-define(INCOME_KEYS, [<<"assessable_income">>, <<"foreign_sourced_component">>]).
-define(DEBT_KEYS,   [<<"hecs_balance">>, <<"credit_card_limits_total">>,
                      <<"personal_loans_balance">>, <<"car_loan_balance">>,
                      <<"buy_now_pay_later_balance">>]).

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
            %% Tenant-scope: confirm ownership before any write.
            case fh_engine_store:get_plan_card(T, Id) of
                {ok, _Card} -> read_and_apply(Id, Req0, State);
                {error, not_found} ->
                    {ok, fh_engine_http:reply_json(404,
                        #{<<"error">> => <<"not_found">>}, Req0), State}
            end;
        {error, Status, Body} ->
            {ok, fh_engine_http:reply_json(Status, Body, Req0), State}
    end.

read_and_apply(Id, Req0, State) ->
    case fh_engine_http:read_json_body(Req0) of
        {ok, Body, Req1} ->
            apply_write(Id, maps:get(<<"household_financials">>, Body, undefined),
                        Req1, State);
        {error, invalid_json} ->
            {ok, fh_engine_http:reply_json(400,
                #{<<"error">> => <<"invalid_json">>}, Req0), State}
    end.

apply_write(Id, Financials, Req, State) ->
    case validate_financials(Financials) of
        ok ->
            case fh_engine_store:set_profile_financials(Id, Financials) of
                {ok, ProfileId} ->
                    Recomputing = refresh_profile_cards(ProfileId),
                    {ok, fh_engine_http:reply_json(202,
                        #{<<"plan_card_id">> => Id,
                          <<"cards_recomputing">> => Recomputing}, Req), State};
                {error, not_found} ->
                    {ok, fh_engine_http:reply_json(404,
                        #{<<"error">> => <<"not_found">>}, Req), State}
            end;
        {error, Reason} ->
            {ok, fh_engine_http:reply_json(400,
                #{<<"error">> => <<"invalid_financials">>,
                  <<"detail">> => reason(Reason)}, Req), State}
    end.

%% Re-derive every active card on the profile (the addressed card + its siblings share the
%% changed fact base). Each is resolver-only + per-card serialized; a card already mid-turn
%% is skipped (it picks up the new facts on its next recompute — honest-partial). Returns
%% the count that actually started, so the response is honest about the fan-out.
refresh_profile_cards(ProfileId) ->
    Ids = fh_engine_store:list_plan_card_ids_for_profile(ProfileId),
    Results = [{Cid, fh_engine_refresh:refresh_card(Cid)} || Cid <- Ids],
    Started = [Cid || {Cid, started} <- Results],
    Skipped = [{Cid, R} || {Cid, {skipped, R}} <- Results],
    case Skipped of
        [] -> ok;
        _  -> logger:notice("[profile-write] ~p card(s) refreshed, ~p skipped ~p",
                            [length(Started), length(Skipped), Skipped])
    end,
    length(Started).

%% --- validation (pure, fail-closed) -----------------------------------------

-spec validate_financials(term()) -> ok | {error, term()}.
validate_financials(HF) when is_map(HF) ->
    case unknown_keys(HF, ?GROUP_KEYS) of
        [K | _] -> {error, {unknown_group, K}};
        [] ->
            case validate_group(maps:get(<<"income">>, HF, #{}), ?INCOME_KEYS, <<"income">>) of
                ok -> validate_group(maps:get(<<"debts">>, HF, #{}), ?DEBT_KEYS, <<"debts">>);
                E  -> E
            end
    end;
validate_financials(_) ->
    {error, not_a_map}.

validate_group(G, _Allowed, Group) when not is_map(G) ->
    {error, {group_not_a_map, Group}};
validate_group(G, Allowed, Group) ->
    case unknown_keys(G, Allowed) of
        [K | _] -> {error, {unknown_field, Group, K}};
        []      -> validate_numbers(maps:to_list(G), Group)
    end.

validate_numbers([], _Group) ->
    ok;
validate_numbers([{K, V} | Rest], Group) ->
    case is_number(V) andalso V >= 0 of
        true  -> validate_numbers(Rest, Group);
        false -> {error, {non_negative_number_required, Group, K}}
    end.

unknown_keys(Map, Allowed) ->
    [K || K <- maps:keys(Map), not lists:member(K, Allowed)].

%% A human-readable 400 detail (the structured reason is for the test/logs).
reason(not_a_map) ->
    <<"household_financials must be an object">>;
reason({group_not_a_map, G}) ->
    <<G/binary, " must be an object">>;
reason({unknown_group, K}) ->
    <<"unknown group: ", K/binary>>;
reason({unknown_field, G, K}) ->
    <<"unknown ", G/binary, " field: ", K/binary>>;
reason({non_negative_number_required, G, K}) ->
    <<G/binary, ".", K/binary, " must be a non-negative number">>.
