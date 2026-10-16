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
    R = lists:flatten([mode_cases(M) || M <- modes()]
                      ++ [detail_cases(M, S) || M <- modes(),
                                                S <- [<<"NSW">>, <<"VIC">>, <<"QLD">>, <<"WA">>]]),
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
     chk(BP, "no income: the payout is placed (price less deposit), never pending",
         lists:member(<<"dispose_loan_payout">>, [maps:get(<<"id">>, E) || E <- Ph(<<"dispose">>)])
             andalso not lists:any(fun(P) -> maps:get(<<"id">>, P) =:= <<"loan_payout">> end,
                                   maps:get(<<"pending">>, B))),
     chk(BP, "with income: the payout is placed, never summed into sell, never pending",
         with_income(BP, Intent, Firb))]
    ++ cost_cases(BP, Intent, Firb, Out, B)
    ++ [
     chk(BP, "no horizon: sell null, every dispose line needs hold_years",
         maps:get(<<"sell">>, B0) =:= null andalso
         lists:usort([maps:get(<<"needs">>, P) || P <- maps:get(<<"pending">>, B0),
                                                  maps:get(<<"phase">>, P) =:= <<"dispose">>]) =:= [<<"hold_years">>]),
     chk(BP, "no horizon: no cost over the hold, no total, Phí mua still shown",
         [maps:get(K, B0) || K <- [<<"hold_years">>, <<"costs_own">>, <<"costs_sell">>, <<"costs_total">>]]
             =:= [null, null, null, null]
         andalso maps:get(<<"costs_buy">>, B0) =/= null)].

%% Whole lifecycle -> information as is -> the base fill -> the statement's costs add up
%% (behavior 98, Expects 1-3). Every mode, every hold 5..30: Tổng phí = Phí mua + Phí giữ
%% nhà + Phí bán at both ends; Phí mua is the cash to buy less the deposit; Phí giữ nhà is
%% the yearly lines but the repayments × N plus the loan's interest over N; the deposit and
%% the principal repaid sit in into_home, never in the total; and the loan paid out is the
%% price less the deposit at the kind's rate.
cost_cases(BP, Intent, Firb, Out10, B10) ->
    Ev = events(Out10),
    Dep = sum([E || E <- Ev, maps:get(<<"id">>, E) =:= <<"deposit">>]),
    Add = fun(Rs) -> [lists:sum([L || [L, _] <- Rs]), lists:sum([H || [_, H] <- Rs])] end,
    Holds = fun(N) ->
        {ok, O} = fh_engine_simulate:run(BP, onboarding(N), Intent, #{}, Firb),
        B = budget(O),
        Own = [E || E <- events(O), maps:get(<<"phase">>, E) =:= <<"own">>, counted(E)],
        Disp = maps:get(<<"disposition">>, O),
        Loan = maps:get(<<"loan_over_hold">>, Disp),
        Yearly = sum([E || E <- Own, maps:get(<<"id">>, E) =/= <<"loan_repayments">>]),
        Into = maps:get(<<"into_home">>, B),
        maps:get(<<"hold_years">>, B) =:= N
            andalso maps:get(<<"costs_total">>, B) =:=
                    Add([maps:get(<<"costs_buy">>, B), maps:get(<<"costs_own">>, B), maps:get(<<"costs_sell">>, B)])
            andalso maps:get(<<"costs_sell">>, B) =:= maps:get(<<"sell">>, B)
            andalso maps:get(<<"costs_own">>, B) =:=
                    Add([[lists:nth(1, Yearly) * N, lists:nth(2, Yearly) * N], maps:get(<<"interest">>, Loan)])
            andalso maps:get(<<"principal_repaid">>, Into) =:= maps:get(<<"principal_repaid">>, Loan)
            andalso maps:get(<<"total">>, Into) =:= Add([Dep, maps:get(<<"principal_repaid">>, Loan)])
    end,
    Disp10 = maps:get(<<"disposition">>, Out10),
    Price = case Dep of [D, D] -> [800000, 800000]; _ -> [600000, 800000] end,
    Kind = fh_engine_disposition:loan_kind(#{blueprint_slug => BP},
                                           case Intent of <<"investor">> -> investor; _ -> owner end),
    Loan = [lists:nth(1, Price) - lists:nth(1, Dep), lists:nth(2, Price) - lists:nth(2, Dep)],
    [chk(BP, "Phí mua = the cash to buy less the deposit",
         Add([maps:get(<<"costs_buy">>, B10), Dep]) =:= maps:get(<<"buy">>, B10)),
     chk(BP, "into_home holds the deposit, apart from every cost",
         maps:get(<<"deposit">>, maps:get(<<"into_home">>, B10)) =:= Dep),
     chk(BP, "every hold 5..30: Tổng phí = Phí mua + Phí giữ nhà + Phí bán; interest, not principal, in Phí giữ nhà",
         lists:all(Holds, [5, 10, 15, 20, 30])),
     chk(BP, "the loan paid out is the price less the deposit at the mode's rate",
         maps:get(<<"loan_payout">>, Disp10) =:= fh_engine_disposition:loan_payout(Loan, Kind, 10)
             andalso maps:get(<<"principal">>, maps:get(<<"loan_over_hold">>, Disp10)) =:= Loan)].

%% Whole lifecycle -> every statement line opens its own detail -> the base fill -> every
%% line carries a detail (behavior 93, Expect 10). Measured 2026-10-16 before the change:
%% deposit, duty, registration, surcharge, the FIRB fee, a grant, LMI, the three own lines,
%% the sale price, the payout and CGT carried none, so the sheet opened a component card.
%% A line that is not a fee says how its figure is set, who pays and what moves it, in both
%% languages; fee lines keep their own (behavior 83).
detail_cases({BP, Intent, Firb}, State) ->
    Fin = #{<<"income">> => #{<<"assessable_income">> => 150000}},
    {ok, Out} = fh_engine_simulate:run(BP, (onboarding())#{<<"state">> => State}, Intent, Fin, Firb),
    Ev = events(Out),
    Label = <<BP/binary, " ", State/binary>>,
    Lines = [maps:get(<<"detail">>, E) || E <- Ev, maps:is_key(<<"how">>, maps:get(<<"detail">>, E, #{}))],
    [chk(Label, "every line carries a detail", lists:all(fun(E) -> maps:is_key(<<"detail">>, E) end, Ev)),
     chk(Label, "the deposit, duty-or-surcharge and own lines are explained in place",
         length(Lines) >= 5),
     chk(Label, "each line's how, payer and drivers are bilingual", lists:all(fun(D) ->
            lists:all(fun(K) -> bilingual(maps:get(K, D, null)) end,
                      [<<"how">>, <<"payer">>, <<"drivers">>])
        end, Lines)),
     chk(Label, "no detail text keeps an unfilled {param}", lists:all(fun(D) ->
            nomatch =:= re:run(term_to_binary(maps:get(<<"how">>, D)), <<"\\{[a-z_]+\\}">>)
        end, Lines))].

bilingual(#{<<"vi">> := Vi, <<"en">> := En}) -> Vi =/= <<>> andalso En =/= <<>>;
bilingual(_) -> false.

%% measured 2026-10-16 (behavior 83): disposition ids its payout dispose_loan_payout, and
%% the budget matched the bare id, so with income the payout was summed as a selling cost.
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

chk(BP, Label, true)  -> io:format("  PASS   ~ts: ~ts~n", [BP, Label]), pass;
chk(BP, Label, false) -> io:format("  FAIL   ~ts: ~ts~n", [BP, Label]), fail.
