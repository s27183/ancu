#!/usr/bin/env escript
%%! -sname fh_profile_enrichment
%%
%% No-PG conformance for IC3 — the income→capacity enrichment WIRING (the "Chưa có"
%% full-horizon unblock). Proves, via the pure resolver-only DAG walk (run/3) given an
%% enriched `financials` map (no Postgres, no sidecar):
%%
%%   1. buyer_profile FRAMES the household financial facts into the profile outcome:
%%      assessable_income (combined primary+secondary, identity shading for the Mode-A
%%      PAYG wedge), foreign_sourced_income_component, and the raw `debts` facts.
%%   2. mortgage_finance READS those framed facts → expected_borrowing_capacity is no
%%      longer null and matches the IC0 fixture to the dollar (the §98 resolver figure,
%%      cross-checked against serviceability_conformance.escript).
%%   3. REGRESSION: with no financials (the onboarding/plan-first base) the framed
%%      financials stay PENDING (assessable_income null, debts empty, capacity null) —
%%      the pre-IC3 honest-partial behaviour is preserved.
%%   4. LINK proof: capacity is the unblock for the dispose chain — loan_payout is null
%%      when capacity is null and non-null once capacity + a rate + H are present (the
%%      rate is the agent slot, supplied end-to-end in IC6; here injected to isolate the
%%      capacity link the "Chưa có" symptom turned on).
%%
%% Pure given onboarding + financials Args + the persistent_term artifact. Run from
%% engine/erlang:  ERL_LIBS=_build/default/lib escript test/profile_enrichment_conformance.escript

-mode(compile).

main(_) ->
    ok = fh_engine_kb:load(),
    io:format("IC3 profile-enrichment conformance — financials → capacity, no PG~n~n"),

    R = projection_checks() ++ regression_checks() ++ link_checks(),

    io:format("~n================================================================~n"),
    case [X || X <- R, X =:= fail] of
        [] -> io:format("PASS — income flows to a banded capacity; honest-partial preserved~n"), halt(0);
        F  -> io:format("FAIL — ~p check(s) failed~n", [length(F)]), halt(1)
    end.

%% --- 1. buyer_profile frames financials; mortgage reads them ----------------

projection_checks() ->
    io:format("financials → profile framing → mortgage capacity~n"),
    {ok, Rich}  = run(ic0_financials()),
    {ok, Fx}    = run(foreign_financials()),
    Profile = maps:get(<<"profile">>, Rich),
    Mort    = maps:get(<<"mortgage_plan">>, Rich),

    [check("profile.assessable_income projects household_financials.income.assessable_income (95000)",
           maps:get(<<"assessable_income">>, Profile, missing), 95000),
     check("profile.foreign_sourced_income_component defaults to 0 (Mode-A domestic)",
           maps:get(<<"foreign_sourced_income_component">>, Profile, missing), 0),
     check("profile.foreign_sourced_income_component passes the offshore portion through",
           maps:get(<<"foreign_sourced_income_component">>, maps:get(<<"profile">>, Fx), missing),
           15000),
     check("profile.debts carries the raw hecs_balance fact",
           maps:get(<<"hecs_balance">>, maps:get(<<"debts">>, Profile, #{}), missing), 20000),
     check("profile.debts carries the raw credit_card_limits_total fact",
           maps:get(<<"credit_card_limits_total">>, maps:get(<<"debts">>, Profile, #{}), missing),
           10000),
     check("mortgage.expected_borrowing_capacity is no longer null (income known)",
           maps:get(<<"expected_borrowing_capacity">>, Mort) =/= null, true),
     check("mortgage.expected_borrowing_capacity matches the IC0 fixture to the dollar",
           maps:get(<<"expected_borrowing_capacity">>, Mort), [350599, 459967])].

%% --- 2. regression: no financials → honest-partial PENDING ------------------

regression_checks() ->
    io:format("~nregression — no financials (plan-first base) stays PENDING~n"),
    {ok, Bare} = run(#{}),
    Profile = maps:get(<<"profile">>, Bare),
    Mort    = maps:get(<<"mortgage_plan">>, Bare),
    [check("profile.assessable_income is null with no income captured",
           maps:get(<<"assessable_income">>, Profile, missing), null),
     check("profile.debts is the empty map with no debts captured",
           maps:get(<<"debts">>, Profile, missing), #{}),
     check("mortgage.expected_borrowing_capacity stays null (pre-IC3 honest-partial)",
           maps:get(<<"expected_borrowing_capacity">>, Mort), null)].

%% --- 3. link: capacity is the dispose-chain unblock -------------------------

link_checks() ->
    io:format("~nlink — capacity unblocks loan_payout (the 'Chưa có' chain)~n"),
    {ok, Rich} = run(ic0_financials()),
    {ok, Bare} = run(#{}),
    H = 10,
    %% the resolver-only mortgage has no rate (the agent slot — IC6); inject a
    %% representative rate to isolate the CAPACITY link this test owns.
    Rate = 0.06,
    RichMort = inject_rate(maps:get(<<"mortgage_plan">>, Rich), Rate),
    BareMort = inject_rate(maps:get(<<"mortgage_plan">>, Bare), Rate),
    [check("loan_payout is null when capacity is null (the symptom: no income)",
           fh_engine_disposition:loan_payout(BareMort, H), null),
     check("loan_payout is NON-null once capacity + rate + H are present (unblocked)",
           fh_engine_disposition:loan_payout(RichMort, H) =/= null, true)].

%% --- fixtures ---------------------------------------------------------------

%% the IC0 worked case: $95k assessable, $20k HECS, $10k card limit → [350599,459967].
%% Canonical fact-base shape (household_financials.income.assessable_income).
ic0_financials() ->
    #{<<"income">> => #{<<"assessable_income">> => 95000},
      <<"debts">>  => #{<<"hecs_balance">> => 20000,
                        <<"credit_card_limits_total">> => 10000}}.

%% an offshore-income portion → F6 passthrough.
foreign_financials() ->
    #{<<"income">> => #{<<"assessable_income">> => 95000,
                        <<"foreign_sourced_component">> => 15000}}.

run(Financials) ->
    Onboarding = #{<<"state">> => <<"NSW">>,
                   <<"target_price_range">> => [600000, 600000],
                   <<"target_zone">> => [],
                   <<"hold_horizon_years">> => 10},
    fh_engine_simulate:run(Onboarding, <<"owner_occupier">>, Financials).

inject_rate(Mort, Rate) ->
    LS = maps:get(<<"loan_structure_recommendation">>, Mort, #{}),
    Mort#{<<"loan_structure_recommendation">> => LS#{<<"rate">> => Rate}}.

check(Label, Got, Want) ->
    case Got =:= Want of
        true  -> io:format("  PASS   ~ts~n", [Label]), pass;
        false -> io:format("  FAIL   ~ts = ~p, expected ~p~n", [Label, Got, Want]), fail
    end.
