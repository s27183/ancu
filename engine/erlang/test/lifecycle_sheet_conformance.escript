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
         lists:sort([maps:get(<<"id">>, E) || E <- Own]) =:=
             [<<"council_rates_water">>, <<"loan_repayments">>, <<"maintenance_reserve">>]),
     chk(BP, "every amount is an ordered [lo, hi]", lists:all(fun(E) ->
            case maps:get(<<"amount">>, E) of [L, H] when is_number(L), is_number(H) -> L =< H; _ -> false end
        end, Ev)),
     chk(BP, "budget.buy = sum of prepare..settle out-events",
         maps:get(<<"buy">>, B) =:= sum([E || E <- Ev, maps:get(<<"direction">>, E) =:= <<"out">>,
             lists:member(maps:get(<<"phase">>, E), [<<"prepare">>, <<"pre_approve">>, <<"contract">>, <<"settle">>])])),
     chk(BP, "budget.own_per_year = sum of own out-events",
         maps:get(<<"own_per_year">>, B) =:= sum([E || E <- Own, maps:get(<<"direction">>, E) =:= <<"out">>])),
     chk(BP, "budget.sell = dispose out-events except loan_payout",
         maps:get(<<"sell">>, B) =:= sum([E || E <- Ph(<<"dispose">>), maps:get(<<"direction">>, E) =:= <<"out">>,
                                           maps:get(<<"id">>, E) =/= <<"loan_payout">>])),
     chk(BP, "no income: pending names loan_payout needing income",
         maps:get(<<"pending">>, B) =:= [#{<<"id">> => <<"loan_payout">>, <<"phase">> => <<"dispose">>, <<"needs">> => <<"income">>}]),
     chk(BP, "no horizon: sell null, every dispose line needs hold_years",
         maps:get(<<"sell">>, B0) =:= null andalso
         [maps:get(<<"needs">>, P) || P <- maps:get(<<"pending">>, B0)] =:= [<<"hold_years">>, <<"hold_years">>, <<"hold_years">>])].

chk(BP, Label, true)  -> io:format("  PASS   ~s: ~s~n", [BP, Label]), pass;
chk(BP, Label, false) -> io:format("  FAIL   ~s: ~s~n", [BP, Label]), fail.
