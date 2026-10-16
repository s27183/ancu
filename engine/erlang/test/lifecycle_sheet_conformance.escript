#!/usr/bin/env escript
%%! -sname fh_lifecycle_sheet_conformance
%%
%% Whole lifecycle -> each phase has its money lines -> the base fill -> every mode's base
%% plan carries Buy, Own and Sell events (behavior 82, Expect 2).
%% The planner's one-page sheet lays out a plan card's cash events by phase and computes no
%% figure; so every mode's BASE fill (no income, no property) must already emit at least one
%% contract/settle event, one own event (recurring, per year) and one dispose event.
%% Measured 2026-10-16 before the change: no mode emitted an own event, Mode C no buy event.
%%
%% Run from engine/erlang: ERL_LIBS=_build/default/lib escript test/lifecycle_sheet_conformance.escript
-mode(compile).

modes() ->
    [{<<"fhb-domestic-au">>,      <<"owner_occupier">>, false},
     {<<"fhb-foreign-au">>,       <<"owner_occupier">>, true},
     {<<"investor-domestic-au">>, <<"investor">>,       false},
     {<<"investor-foreign-au">>,  <<"investor">>,       true},
     {<<"nexthome-domestic-au">>, <<"owner_occupier">>, false}].

onboarding() -> onboarding(10).
onboarding(H) ->
    #{<<"state">> => <<"VIC">>, <<"target_price_range">> => [600000, 800000],
      <<"target_zone">> => [], <<"hold_horizon_years">> => H}.

%% the purchase_journey outcome's lifecycle_budget (behavior 82 step 3)
budget(Out) ->
    [B] = [maps:get(<<"lifecycle_budget">>, O) || O <- maps:values(Out), is_map(O),
                                                  maps:is_key(<<"lifecycle_budget">>, O)],
    B.

sum(Es) -> [lists:sum([L || #{<<"amount">> := [L, _]} <- Es]),
            lists:sum([H || #{<<"amount">> := [_, H]} <- Es])].

%% every event list in the outcomes: `cash_events` and disposition's `dispose_cash_events`
events(Out) ->
    lists:flatten([maps:get(<<"cash_events">>, O, []) ++ maps:get(<<"dispose_cash_events">>, O, [])
                   || O <- maps:values(Out), is_map(O)]).

main(_) ->
    ok = fh_engine_kb:load(),
    R = lists:flatten([mode_cases(M) || M <- modes()]),
    case [X || X <- R, X =:= fail] of
        [] -> io:format("PASS — all ~p lifecycle-sheet anchors hold~n", [length(R)]), halt(0);
        F  -> io:format("FAIL — ~p anchor(s) mismatched~n", [length(F)]), halt(1)
    end.

mode_cases({BP, Intent, Firb}) ->
    {ok, Out} = fh_engine_simulate:run(BP, onboarding(), Intent, #{}, Firb),
    Ev = events(Out),
    B = budget(Out),
    {ok, Out0} = fh_engine_simulate:run(BP, onboarding(null), Intent, #{}, Firb),
    B0 = budget(Out0),
    Ph = fun(P) -> [E || E <- Ev, maps:get(<<"phase">>, E) =:= P] end,
    Own = Ph(<<"own">>),
    [chk(BP, "a buy event (contract or settle)", Ph(<<"contract">>) ++ Ph(<<"settle">>) =/= []),
     chk(BP, "an own event", Own =/= []),
     chk(BP, "a sell event", Ph(<<"dispose">>) =/= []),
     chk(BP, "own events are recurring, per year", lists:all(fun(E) ->
            maps:get(<<"timing">>, E) =:= <<"recurring">> andalso maps:get(<<"period">>, E) =:= <<"year">>
        end, Own)),
     chk(BP, "own: rates+water, maintenance and repayments all present",
         [<<"council_rates_water">>, <<"loan_repayments">>, <<"maintenance_reserve">>] --
             [maps:get(<<"id">>, E) || E <- Own] =:= []),
     chk(BP, "own: every other own line is a fee line with its source (behavior 83)",
         lists:all(fun(E) -> maps:get(<<"source">>, maps:get(<<"detail">>, E, #{}), null) =/= null end,
                   [E || E <- Own, not lists:member(maps:get(<<"id">>, E),
                        [<<"council_rates_water">>, <<"loan_repayments">>, <<"maintenance_reserve">>])])),
     chk(BP, "every amount is an ordered [lo, hi]", lists:all(fun(E) ->
            case maps:get(<<"amount">>, E) of [L, H] when is_number(L), is_number(H) -> L =< H; _ -> false end
        end, Ev)),
     chk(BP, "budget.buy = sum of prepare..settle out-events",
         maps:get(<<"buy">>, B) =:= sum([E || E <- Ev, counted(E),
             lists:member(maps:get(<<"phase">>, E), [<<"prepare">>, <<"pre_approve">>, <<"contract">>, <<"settle">>])])),
     chk(BP, "budget.own_per_year = sum of own out-events",
         maps:get(<<"own_per_year">>, B) =:= sum([E || E <- Own, counted(E)])),
     chk(BP, "budget.sell = dispose out-events except loan_payout",
         maps:get(<<"sell">>, B) =:= sum([E || E <- Ph(<<"dispose">>), counted(E),
                                           maps:get(<<"id">>, E) =/= <<"dispose_loan_payout">>])),
     chk(BP, "no income: pending names loan_payout needing income (an investor: the price)",
         lists:member(#{<<"id">> => <<"loan_payout">>, <<"phase">> => <<"dispose">>, <<"needs">> => payout_needs(Intent)},
                      [maps:with([<<"id">>, <<"phase">>, <<"needs">>], P) || P <- maps:get(<<"pending">>, B)])),
     chk(BP, "with income: the payout is placed, never summed into sell, never pending",
         Intent =:= <<"investor">> orelse with_income(BP, Intent, Firb)),
     chk(BP, "no horizon: sell null, every dispose line needs hold_years",
         maps:get(<<"sell">>, B0) =:= null andalso
         lists:usort([maps:get(<<"needs">>, P) || P <- maps:get(<<"pending">>, B0),
                                                  maps:get(<<"phase">>, P) =:= <<"dispose">>]) =:= [<<"hold_years">>])].

%% measured 2026-10-16 (behavior 83): disposition ids its payout dispose_loan_payout, and
%% the budget matched the bare id, so with income the payout was summed as a selling cost.
%% an investor's payout waits on a property (budget_envelope_investor.loan_amount), not income.
payout_needs(<<"investor">>) -> <<"price">>;
payout_needs(_)              -> <<"income">>.

with_income(BP, Intent, Firb) ->
    Fin = #{<<"income">> => #{<<"assessable_income">> => 150000}},
    {ok, Out} = fh_engine_simulate:run(BP, onboarding(), Intent, Fin, Firb),
    B = budget(Out),
    Dispose = [E || E <- events(Out), maps:get(<<"phase">>, E) =:= <<"dispose">>],
    Payout = [E || E <- Dispose, maps:get(<<"id">>, E) =:= <<"dispose_loan_payout">>],
    Sell = sum([E || E <- Dispose, counted(E),
                     maps:get(<<"id">>, E) =/= <<"dispose_loan_payout">>]),
    Payout =/= [] andalso maps:get(<<"sell">>, B) =:= Sell
        andalso not lists:any(fun(P) -> maps:get(<<"id">>, P) =:= <<"loan_payout">> end,
                              maps:get(<<"pending">>, B)).

%% an out-event the totals count: not an optional fee line, not one whose property
%% condition is still open (behavior 83).
counted(E) ->
    maps:get(<<"direction">>, E) =:= <<"out">> andalso
        case maps:get(<<"detail">>, E, null) of
            D when is_map(D) -> maps:get(<<"optional">>, D) =/= true andalso
                                maps:get(<<"condition">>, D) =:= null;
            _ -> true
        end.

chk(BP, Label, true)  -> io:format("  PASS   ~s: ~s~n", [BP, Label]), pass;
chk(BP, Label, false) -> io:format("  FAIL   ~s: ~s~n", [BP, Label]), fail.
