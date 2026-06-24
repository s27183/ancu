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
%%
%% Run from engine/erlang with the build libs on the path (no Postgres, no live model):
%%   ERL_LIBS=_build/default/lib escript test/yield_modelling_conformance.escript

-mode(compile).

-define(INV, <<"investor-domestic-au">>).

main(_) ->
    ok = fh_engine_kb:load(),
    io:format("yield_modelling conformance — fh_engine_fill (Mode-C pure resolver)~n~n"),
    R = lists:flatten([scaffold_cases(), layer1_cases(), pure_resolver_cases(),
                       no_regression_cases()]),
    Fails = [X || X <- R, X =:= fail],
    io:format("~n================================================================~n"),
    case Fails of
        [] -> io:format("PASS — all ~p yield_modelling anchors hold~n", [length(R)]), halt(0);
        _  -> io:format("FAIL — ~p anchor(s) mismatched~n", [length(Fails)]), halt(1)
    end.

%% --- fixtures ----------------------------------------------------------------

%% the cash_flow_projection figure fields (the eleven the registry declares).
fields() ->
    [<<"annual_rental_income_year_1">>, <<"annual_operating_expenses_year_1">>,
     <<"annual_interest_year_1">>, <<"cash_flow_before_tax_year_1">>,
     <<"cash_flow_before_tax_per_week">>, <<"gross_yield">>,
     <<"net_yield_pre_loan">>, <<"net_yield_post_loan_pre_tax">>,
     <<"year_5_projected_cash_flow">>, <<"year_10_projected_cash_flow">>,
     <<"is_positive_neutral_or_negative_geared_pre_tax">>].

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
     check("outcome has exactly the eleven cash_flow_projection fields",
           lists:sort(maps:keys(O)), lists:sort(fields())),
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

%% --- helpers ----------------------------------------------------------------

check(Label, Got, Want) ->
    case Got =:= Want of
        true  -> io:format("  PASS   ~ts~n", [Label]), pass;
        false -> io:format("  FAIL   ~ts = ~p, expected ~p~n", [Label, Got, Want]), fail
    end.
