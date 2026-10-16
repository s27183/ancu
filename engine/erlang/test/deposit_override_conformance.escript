#!/usr/bin/env escript
%%! -sname fh_deposit_override_conformance
%%
%% Conformance suite for behavior 101's deposit override (Expect 5): the deposit a buyer
%% chooses on "Tài chính của bạn" walks the whole plan. Over fh_engine_simulate:run/5 on
%% a VIC home at 700 000 it asserts:
%%   1. OVERRIDE — apply_overrides takes `deposit` into onboarding deposit_amount; a
%%      negative or non-number deposit is refused.
%%   2. BOUNDS — cash_position's deposit_bounds is [the mode's floor, the price];
%%      check_deposit refuses below the floor and above the price, accepts inside.
%%   3. LOAN — the chosen deposit becomes the deposit event and the loan is price − deposit.
%%   4. LMI — above 80% LVR outside the FHG the lmi event is kb.lmi.calculation's band of
%%      the loan (fh_engine_lmi), and at or under 80% there is no lmi event.
%%   5. OUTRIGHT — at deposit = price the loan-tied lines are gone (LMI, application fee,
%%      valuation, broker, repayments, payout) and the FHG is rejected as not needed.
%%
%% Run from engine/erlang with the build libs on the path (no Postgres, no live model):
%%   ERL_LIBS=_build/default/lib escript test/deposit_override_conformance.escript

-mode(compile).

-define(PRICE, 700000).

main(_) ->
    ok = fh_engine_kb:load(),
    io:format("deposit override conformance — behavior 101~n~n"),
    R = lists:flatten([override_cases(), bounds_cases(), loan_cases(), lmi_cases(),
                       outright_cases()]),
    Fails = [X || X <- R, X =:= fail],
    io:format("~n================================================================~n"),
    case Fails of
        [] -> io:format("PASS — all ~p deposit override anchors hold~n", [length(R)]), halt(0);
        _  -> io:format("FAIL — ~p anchor(s) mismatched~n", [length(Fails)]), halt(1)
    end.

%% --- fixtures ----------------------------------------------------------------

onboarding() ->
    #{<<"state">> => <<"VIC">>, <<"target_price_range">> => [?PRICE, ?PRICE],
      <<"target_zone">> => [], <<"hold_horizon_years">> => 10}.

run(BP, Deposit) -> run(BP, <<"buy_first_home">>, Deposit).

run(BP, Intent, Deposit) ->
    Ob = case Deposit of
             none -> onboarding();
             D -> {ok, O} = fh_engine_simulate:apply_overrides(#{<<"deposit">> => D},
                                                              onboarding()),
                  O
         end,
    {ok, Out} = fh_engine_simulate:run(BP, Ob, Intent, #{}, false),
    Out.

cash(Out) ->
    maps:get(<<"budget_envelope">>, Out, maps:get(<<"budget_envelope_investor">>, Out, #{})).

events(Out) ->
    lists:flatten([maps:get(<<"cash_events">>, O, []) ++ maps:get(<<"dispose_cash_events">>, O, [])
                   || O <- maps:values(Out), is_map(O)]).

event(Out, Id) ->
    case [E || E <- events(Out), maps:get(<<"id">>, E) =:= Id] of
        [E | _] -> maps:get(<<"amount">>, E);
        [] -> absent
    end.

rejected_fhg(Out) ->
    Stack = maps:get(<<"scheme_stack">>, Out, #{}),
    lists:any(fun(S) -> binary:match(string:lowercase(maps:get(<<"name">>, S, <<>>)),
                                     <<"guarantee">>) =/= nomatch end,
              maps:get(<<"rejected_schemes">>, Stack, [])).

%% --- cases -------------------------------------------------------------------

override_cases() ->
    {ok, Ob} = fh_engine_simulate:apply_overrides(#{<<"deposit">> => 70000.4}, onboarding()),
    [check("deposit override → onboarding deposit_amount (rounded)",
           maps:get(<<"deposit_amount">>, Ob), 70000),
     check("negative deposit refused",
           fh_engine_simulate:apply_overrides(#{<<"deposit">> => -1}, onboarding()),
           {error, {invalid_override, <<"deposit">>}}),
     check("non-number deposit refused",
           fh_engine_simulate:apply_overrides(#{<<"deposit">> => <<"x">>}, onboarding()),
           {error, {invalid_override, <<"deposit">>}})].

bounds_cases() ->
    A = run(<<"fhb-domestic-au">>, none),
    BA = maps:get(<<"deposit_bounds">>, cash(A)),
    C = run(<<"investor-domestic-au">>, <<"buy_investment">>, none),
    BC = maps:get(<<"deposit_bounds">>, cash(C)),
    [check("Mode A floor = 5% (FHG)", maps:get(<<"min">>, BA), 35000),
     check("Mode A ceiling = the price", maps:get(<<"max">>, BA), ?PRICE),
     check("Mode C floor = 10% (with LMI)", maps:get(<<"min">>, BC), 70000),
     check("below the floor refused", fh_engine_simulate:check_deposit(#{<<"deposit">> => 10000}, A),
           {error, {deposit_out_of_bounds, 35000, ?PRICE}}),
     check("above the price refused", fh_engine_simulate:check_deposit(#{<<"deposit">> => 800000}, A),
           {error, {deposit_out_of_bounds, 35000, ?PRICE}}),
     check("inside accepted", fh_engine_simulate:check_deposit(#{<<"deposit">> => 140000}, A), ok),
     check("no deposit override → nothing to check", fh_engine_simulate:check_deposit(#{}, A), ok)].

loan_cases() ->
    A = run(<<"fhb-domestic-au">>, 140000),
    [check("chosen deposit is the deposit event", event(A, <<"deposit">>), [140000, 140000]),
     check("bounds report the chosen deposit",
           maps:get(<<"chosen">>, maps:get(<<"deposit_bounds">>, cash(A))), 140000),
     check("20% deposit → FHG rejected (no LMI to avoid)", rejected_fhg(A), true),
     check("20% deposit → no lmi line", event(A, <<"lmi">>), absent)].

lmi_cases() ->
    C = run(<<"investor-domestic-au">>, <<"buy_investment">>, 70000),
    Loan = ?PRICE - 70000,
    {Lo, Hi} = fh_engine_lmi:rates(fh_engine_lmi:lvr(Loan, ?PRICE)),
    [check("Mode C 10% → lmi = KB band of the 630k loan",
           event(C, <<"lmi">>), [round(Lo / 100 * Loan), round(Hi / 100 * Loan)]),
     check("Mode C 10% → the 86-90 band (1.5-2.0%)", event(C, <<"lmi">>), [9450, 12600]),
     check("no LMI at 80% LVR", fh_engine_lmi:premium(560000, ?PRICE), none),
     check("LMI floored at the minimum premium", fh_engine_lmi:premium(10000, 10600),
           [1150, 1150])].

outright_cases() ->
    A = run(<<"fhb-domestic-au">>, ?PRICE),
    Gone = [<<"lmi">>, <<"loan_application_fee">>, <<"lender_valuation">>, <<"mortgage_broker">>,
            <<"loan_repayments">>, <<"dispose_loan_payout">>],
    [check("outright → no " ++ binary_to_list(Id), event(A, Id), absent) || Id <- Gone] ++
    [check("outright → deposit is the whole price", event(A, <<"deposit">>), [?PRICE, ?PRICE]),
     check("outright → FHG rejected as not needed", rejected_fhg(A), true)].

%% --- harness -----------------------------------------------------------------

check(Name, Got, Want) when Got =:= Want ->
    io:format("  PASS   ~ts~n", [Name]), pass;
check(Name, Got, Want) ->
    io:format("  FAIL   ~ts = ~p (want ~p)~n", [Name, Got, Want]), fail.
