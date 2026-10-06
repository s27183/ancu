#!/usr/bin/env escript
%%! -sname fh_yield_modelling_conformance
%%
%% Conformance suite for the `yield_modelling` resolver (fh_engine_fill — the investor base
%% spine, blueprint component 5; a PURE-resolver figure-owner, the same class as
%% fh_engine_disposition). Loads the SAME materialized artifact the engine loads
%% (priv/kb/artifact.json) and asserts what the base-spine presence relies on:
%%   1. SCAFFOLD — the resolver owns the calculator renderer + the five Cluster-Y anchors
%%      (the method/band audit trail) and leaves EVERY cash_flow_projection figure null
%%      (honest-partial: the binding weekly-rent input is an agent leaf on the unbuilt,
%%      per-property property_assessment — no base rent source, so no base figure). The
%%      base outcome is input-independent (all null) — same for any upstream.
%%   2. LAYER-1 CONFORMANCE — the all-null scaffold passes fh_engine_outcome:validate/3
%%      against the compiled `cash_flow_projection` schema (null conforms to any field;
%%      no banded-vs-scalar type decision is forced at base).
%%   3. PURE RESOLVER — yield_modelling has a resolver and NO agent merge (it is not a
%%      two-path component): merge_agent/3 and agent_values_from_outcome/2 must NOT have a
%%      yield_modelling clause (calling them errors — the §98 figure-owner has no agent leaf).
%%   4. NO MODE-A/MODE-C REGRESSION — the new clauses are additive: investment_strategy
%%      (two-path) and mortgage_finance still dispatch (distinct names; no shadowing).
%%   5. PER-PROPERTY ARITHMETIC (Slice B1) — when property_fit_investor is in upstream (the
%%      Phase-B turn), the resolver branches and computes the banded PRE-LOAN rent-economics:
%%      effective income, opex, gross yield, net-pre-loan yield — each a [lo,hi] BAND (the §B0
%%      banded surface), resolver-computed to the exact figure (§98 removed-from-reach). A HOUSE
%%      carries full opex; a STRATA property nulls opex (the body-corporate levy is not carried
%%      → honest-partial). The POST-loan figures stay null (need the loan → Slice B3). The
%%      banded outcome conforms to the (now money_range/percentage_range) Layer-1 schema.
%%
%% Run from engine/erlang with the build libs on the path (no Postgres, no live model):
%%   ERL_LIBS=_build/default/lib escript test/yield_modelling_conformance.escript

-mode(compile).

-define(INV, <<"investor-domestic-au">>).

main(_) ->
    ok = fh_engine_kb:load(),
    io:format("yield_modelling conformance — fh_engine_fill (Mode-C pure resolver)~n~n"),
    R = lists:flatten([scaffold_cases(), layer1_cases(), pure_resolver_cases(),
                       no_regression_cases(), per_property_cases()]),
    Fails = [X || X <- R, X =:= fail],
    io:format("~n================================================================~n"),
    case Fails of
        [] -> io:format("PASS — all ~p yield_modelling anchors hold~n", [length(R)]), halt(0);
        _  -> io:format("FAIL — ~p anchor(s) mismatched~n", [length(Fails)]), halt(1)
    end.

%% --- fixtures ----------------------------------------------------------------

%% the cash_flow_projection figure fields (the eleven the registry declares) — these are the
%% ones that are null at base, so they double as the null-check fixture. cash_events (added
%% 2026-07-10, task 4) is NOT one of these: it's honest-EMPTY ([]) at base, not null, so it's
%% tracked separately via all_fields() below rather than folded into the null-check loop.
fields() ->
    [<<"annual_rental_income_year_1">>, <<"annual_operating_expenses_year_1">>,
     <<"annual_interest_year_1">>, <<"cash_flow_before_tax_year_1">>,
     <<"cash_flow_before_tax_per_week">>, <<"gross_yield">>,
     <<"net_yield_pre_loan">>, <<"net_yield_post_loan_pre_tax">>,
     <<"year_5_projected_cash_flow">>, <<"year_10_projected_cash_flow">>,
     <<"is_positive_neutral_or_negative_geared_pre_tax">>].

%% the full field set the registry declares — fields() plus cash_events (the hold-phase
%% rent/opex/interest spine purchase_journey/phase_playbook's generic harvest reads,
%% fh_engine_fill:yield_cash_events/1).
all_fields() -> fields() ++ [<<"cash_events">>].

%% a realistic base investor upstream (profile + strategy_thesis present; property absent).
upstream() ->
    #{<<"profile">> => #{<<"target_price_range">> => [600000, 800000],
                         <<"target_zone">> => [<<"Footscray">>],
                         <<"hold_horizon_years">> => 10},
      <<"strategy_thesis">> => #{<<"archetype">> => <<"capital_growth">>,
                                 <<"hold_period_years">> => 10}}.

scaffold(Upstream) ->
    fh_engine_fill:resolver(<<"yield_modelling">>, #{}, Upstream).

g(O, K) -> maps:get(K, O, undefined).

%% --- 1. scaffold -------------------------------------------------------------

scaffold_cases() ->
    {O, Rend, Kb} = scaffold(upstream()),
    {OEmpty, _, _} = scaffold(#{}),     %% input-independent: empty upstream → same null outcome.
    KbSlugs = [maps:get(<<"slug">>, E) || E <- Kb],
    NullChecks =
        [check(<<"figure null at base: ", F/binary>>, g(O, F), null) || F <- fields()],
    EmptyChecks =
        [check(<<"input-independent (empty upstream) null: ", F/binary>>, g(OEmpty, F), null)
         || F <- fields()],
    [check("renderer = calculator", Rend, <<"calculator">>),
     check("outcome has exactly the twelve cash_flow_projection fields",
           lists:sort(maps:keys(O)), lists:sort(all_fields())),
     check("cash_events = [] at base (honest empty, every figure null)",
           g(O, <<"cash_events">>), []),
     check("kb_versions = the five Cluster-Y anchors",
           lists:sort(KbSlugs),
           lists:sort([<<"kb.investor.rental-income-modelling">>,
                       <<"kb.investor.operating-expenses-typical-ratios">>,
                       <<"kb.investor.vacancy-rate-assumptions">>,
                       <<"kb.investor.cash-flow-modelling-methodology">>,
                       <<"kb.investor.property-management-fees">>])),
     check("has_resolver true (classified as resolver, not pure-agent)",
           fh_engine_fill:has_resolver(<<"yield_modelling">>), true)]
    ++ NullChecks ++ EmptyChecks.

%% --- 2. Layer-1 conformance (the fail-closed commit seam) -------------------

layer1_cases() ->
    {O, _, _} = scaffold(upstream()),
    [check(<<"Layer-1 conforms: all-null scaffold (null conforms to any field)">>,
           validate(O), ok)].

validate(O) ->
    try fh_engine_outcome:validate(?INV, <<"cash_flow_projection">>, O), ok
    catch _:Why -> {error, Why} end.

%% --- 3. pure resolver (no agent leaf — §98 figure-owner) --------------------

pure_resolver_cases() ->
    %% yield_modelling is NOT two-path: it has no merge_agent/3 nor agent_values_from_outcome/2
    %% clause. Calling either must error (the catch-all no_*_for clause) — proving the agent has
    %% no reach into the cash-flow figures (they are resolver-owned, removed from the LLM).
    [check("no agent merge for yield_modelling (pure resolver)",
           errors(fun() -> fh_engine_fill:merge_agent(<<"yield_modelling">>, #{}, #{}) end), true),
     check("no agent re-attach for yield_modelling (pure resolver)",
           errors(fun() -> fh_engine_fill:agent_values_from_outcome(<<"yield_modelling">>, #{}) end),
           true)].

errors(F) ->
    try F(), false catch _:_ -> true end.

%% --- 4. no regression (additive clauses; distinct names) --------------------

no_regression_cases() ->
    %% investment_strategy (two-path) still dispatches its resolver scaffold + merge.
    {SO, SRend, _} = fh_engine_fill:resolver(<<"investment_strategy">>, #{},
                                             #{<<"profile">> => #{<<"hold_horizon_years">> => 10}}),
    SM = fh_engine_fill:merge_agent(<<"investment_strategy">>, SO,
                                    #{<<"archetype">> => <<"balanced">>,
                                      <<"gearing_type">> => <<"neutral_geared">>,
                                      <<"one_liner">> => #{<<"vi">> => <<"x"/utf8>>,
                                                           <<"en">> => <<"y">>}}),
    %% mortgage_finance (two-path) refresh re-attach still dispatches.
    AVm = fh_engine_fill:agent_values_from_outcome(
            <<"mortgage_finance">>,
            #{<<"recommended_lender_shortlist">> => [#{<<"lender">> => <<"X">>}],
              <<"loan_structure_recommendation">> => #{<<"rate">> => <<"variable">>}}),
    [check("investment_strategy resolver still dispatches (summary-card)", SRend, <<"summary-card">>),
     check("investment_strategy merge still folds archetype",
           maps:get(<<"archetype">>, SM), <<"balanced">>),
     check("mortgage_finance refresh still dispatches (rate recovered)",
           maps:get(<<"fixed_vs_variable">>, AVm), <<"variable">>),
     check("investment_strategy has_resolver still true",
           fh_engine_fill:has_resolver(<<"investment_strategy">>), true)].

%% --- 5. per-property arithmetic (Slice B1 — the banded rent-economics) -------

%% a house and a strata property attached (the property_fit_investor a Phase-B turn supplies).
house_upstream() ->
    (upstream())#{<<"property_fit_investor">> =>
        #{<<"estimated_weekly_rent_range">> => [620, 720],
          <<"price">> => 920000,
          <<"property_type">> => <<"established_house">>}}.

strata_upstream() ->
    (upstream())#{<<"property_fit_investor">> =>
        #{<<"estimated_weekly_rent_range">> => [500, 560],
          <<"price">> => 640000,
          <<"property_type">> => <<"established_apartment">>}}.

per_property_cases() ->
    {HO, HRend, HKb} = scaffold(house_upstream()),
    {SO, _, SKb} = scaffold(strata_upstream()),
    {IO, _, _} = scaffold((upstream())#{<<"property_fit_investor">> =>
                   #{<<"estimated_weekly_rent_range">> => null, <<"price">> => 920000,
                     <<"property_type">> => <<"established_house">>}}),
    HKbSlugs = [maps:get(<<"slug">>, E) || E <- HKb],
    %% strata's post-loan cluster stays null (opex null → no post_loan).
    PostLoanNull = [<<"annual_interest_year_1">>, <<"cash_flow_before_tax_year_1">>,
                    <<"cash_flow_before_tax_per_week">>, <<"net_yield_post_loan_pre_tax">>,
                    <<"year_5_projected_cash_flow">>, <<"year_10_projected_cash_flow">>,
                    <<"is_positive_neutral_or_negative_geared_pre_tax">>],
    [Y5Lo, Y5Hi] = g(HO, <<"year_5_projected_cash_flow">>),
    [Y10Lo, Y10Hi] = g(HO, <<"year_10_projected_cash_flow">>),
    %% HOUSE — pre-loan (B1) EXACT bands:
    %%   income [31273,36317]; opex [10445,18624]; gross [3.5,4.1]; net-pre [1.4,2.8]
    %% post-loan (B3a) — loan = 920k×80% = 736k; rate = 6.0+0.35 = 6.35%; interest-only:
    %%   interest = round(736000×6.35%) = 46736
    %%   CF       = [31273−18624−46736, 36317−10445−46736]   = [−34087, −20864] (negatively geared)
    %%   /week    = [round(−34087/52), round(−20864/52)]      = [−656, −401]
    %%   net-post = CF ÷ 920k × 100                            = [−3.7, −2.3]
    [check("house: renderer still calculator", HRend, <<"calculator">>),
     check("house: annual_rental_income_year_1 = effective band [31273,36317]",
           g(HO, <<"annual_rental_income_year_1">>), [31273, 36317]),
     check("house: annual_operating_expenses_year_1 = band [10445,18624]",
           g(HO, <<"annual_operating_expenses_year_1">>), [10445, 18624]),
     check("house: gross_yield = band [3.5,4.1]", g(HO, <<"gross_yield">>), [3.5, 4.1]),
     check("house: net_yield_pre_loan = band [1.4,2.8]", g(HO, <<"net_yield_pre_loan">>), [1.4, 2.8]),
     %% post-loan cluster (B3a):
     check("house: annual_interest_year_1 = 46736 (736k loan × 6.35%, scalar point)",
           g(HO, <<"annual_interest_year_1">>), 46736),
     check("house: cash_flow_before_tax_year_1 = band [-34087,-20864]",
           g(HO, <<"cash_flow_before_tax_year_1">>), [-34087, -20864]),
     check("house: cash_flow_before_tax_per_week = band [-656,-401]",
           g(HO, <<"cash_flow_before_tax_per_week">>), [-656, -401]),
     check("house: net_yield_post_loan_pre_tax = band [-3.7,-2.3]",
           g(HO, <<"net_yield_post_loan_pre_tax">>), [-3.7, -2.3]),
     check("house: geared position = negative (whole CF band < 0)",
           g(HO, <<"is_positive_neutral_or_negative_geared_pre_tax">>), <<"negative">>),
     %% year-5/10 projections — structural (income grows 3%, interest flat → CF improves over time).
     check("house: year_5 band well-formed (lo=<hi)", Y5Lo =< Y5Hi, true),
     check("house: year_10 band well-formed (lo=<hi)", Y10Lo =< Y10Hi, true),
     check("house: year_10 cash flow > year_5 (rent growth over fixed interest), lo",
           Y10Lo > Y5Lo, true),
     check("house: year_10 cash flow > year_5, hi", Y10Hi > Y5Hi, true),
     check("house: Layer-1 conforms (banded post-loan figures validate)", validate(HO), ok),
     %% provenance: the 5 Cluster-Y + 4 financing anchors when the post-loan cluster computes.
     check("house: kb_versions = 9 anchors (5 Cluster-Y + 4 financing)", length(HKbSlugs), 9),
     check("house: financing anchors present (serviceability-basics)",
           lists:member(<<"kb.lender.serviceability-basics">>, HKbSlugs), true),
     check("house: financing anchors present (deposit-requirements)",
           lists:member(<<"kb.investor.deposit-requirements-investment-loans">>, HKbSlugs), true)]
    %% STRATA — income + gross compute; opex + net + the WHOLE post-loan cluster null:
    %%   income = [25220,28246]; gross = [4.1,4.6]
    ++ [check("strata: annual_rental_income_year_1 = effective band [25220,28246]",
              g(SO, <<"annual_rental_income_year_1">>), [25220, 28246]),
        check("strata: gross_yield = band [4.1,4.6]", g(SO, <<"gross_yield">>), [4.1, 4.6]),
        check("strata: opex null (body-corporate levy not carried → honest-partial)",
              g(SO, <<"annual_operating_expenses_year_1">>), null),
        check("strata: net_yield_pre_loan null (follows opex)",
              g(SO, <<"net_yield_pre_loan">>), null),
        check("strata: kb_versions = 5 anchors (no post-loan → no financing anchors)",
              length(SKb), 5),
        check("strata: Layer-1 conforms", validate(SO), ok)]
    ++ [check(<<"strata: post-loan figure null (opex absent): ", F/binary>>, g(SO, F), null)
        || F <- PostLoanNull]
    %% ILL-FORMED — rent null → all figures null (never a false figure).
    ++ [check("ill-formed (rent null): annual_rental_income_year_1 null",
              g(IO, <<"annual_rental_income_year_1">>), null),
        check("ill-formed (rent null): gross_yield null", g(IO, <<"gross_yield">>), null),
        check("ill-formed (rent null): cash_flow_before_tax_year_1 null",
              g(IO, <<"cash_flow_before_tax_year_1">>), null)].

%% --- helpers ----------------------------------------------------------------

check(Label, Got, Want) ->
    case Got =:= Want of
        true  -> io:format("  PASS   ~ts~n", [Label]), pass;
        false -> io:format("  FAIL   ~ts = ~p, expected ~p~n", [Label, Got, Want]), fail
    end.
