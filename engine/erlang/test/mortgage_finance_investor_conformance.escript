#!/usr/bin/env escript
%%! -sname fh_mortgage_finance_investor_conformance
%%
%% Conformance suite for the `mortgage_finance` INVESTOR variant
%% (fh_engine_mortgage:fill_investor/2 + merge_agent_investor/2 — the Mode-C investor loan
%% spine, blueprint component 4; a TWO-PATH component, agent_leaves = the FIVE lender_fit
%% leaves). SHARED component NAME with the Mode-A FHB `mortgage_finance`, so fh_engine_mortgage
%% discriminates: fill/2 routes on the `strategy_thesis` upstream (investor-only) and
%% merge_agent/2 + agent_values_from_outcome/1 route on the `io_vs_pi_recommendation` outcome
%% key (investor-only); the FHB bodies are byte-identical (zero regression). Loads the SAME
%% materialized artifact the engine loads (priv/kb/artifact.json) and asserts:
%%   1. SCAFFOLD (resolver half) — the variant owns the `summary-card` renderer + the eight
%%      investor lender/loan KB anchors; HONEST-PARTIAL: the resolver fills the loan-structure
%%      scaffold (IO term = KB convention) + the KB-grounded refinance framing, the three
%%      agent enum/list slots are null, debt_optimisations is [] and loan_cost is null
%%      (pending debts / loan amount). Input-independent at base. has_resolver true.
%%   2. LAYER-1 CONFORMANCE — the scaffold passes fh_engine_outcome:validate/3 against the
%%      compiled investor `mortgage_plan` schema.
%%   3. MERGE (the §98 slot-scoped fold) — merge_agent_investor folds the five leaves into the
%%      right outcome slots (io/PI + offset surfaced both top-level AND in the structure
%%      object); every resolver figure is byte-identical; agent_values_from_outcome inverts it
%%      (refresh round-trip) and a re-merge is idempotent. Merged outcome still validates.
%%   4. NO REGRESSION — the FHB `mortgage_finance` path is untouched (no strategy_thesis
%%      upstream → fill_fhb): still summary-card, capacity null at base, carries recommended_path
%%      + loan_structure_recommendation, has NO io_vs_pi_recommendation field, and its 2-leaf
%%      merge still folds (shortlist + rate).
%%
%% Run from engine/erlang with the build libs on the path (no Postgres, no live model):
%%   ERL_LIBS=_build/default/lib escript test/mortgage_finance_investor_conformance.escript

-mode(compile).

-define(INV, <<"investor-domestic-au">>).

main(_) ->
    ok = fh_engine_kb:load(),
    io:format("mortgage_finance_investor conformance — fh_engine_mortgage (Mode-C two-path)~n~n"),
    R = lists:flatten([scaffold_cases(), layer1_cases(), merge_cases(),
                       no_regression_cases()]),
    Fails = [X || X <- R, X =:= fail],
    io:format("~n================================================================~n"),
    case Fails of
        [] -> io:format("PASS — all ~p mortgage_finance_investor anchors hold~n", [length(R)]), halt(0);
        _  -> io:format("FAIL — ~p anchor(s) mismatched~n", [length(Fails)]), halt(1)
    end.

%% --- fixtures ----------------------------------------------------------------

%% the seven investor mortgage_plan fields the registry declares.
fields() ->
    [<<"recommended_loan_structure">>, <<"recommended_lender_shortlist">>,
     <<"io_vs_pi_recommendation">>, <<"offset_strategy_recommendation">>,
     <<"refinance_plan_for_portfolio_growth">>, <<"debt_optimisations_to_action">>,
     <<"loan_cost_estimate_year_1">>].

%% the three agent enum/list slots null at base.
agent_null_at_base() ->
    [<<"recommended_lender_shortlist">>, <<"io_vs_pi_recommendation">>,
     <<"offset_strategy_recommendation">>].

%% investor upstream: the strategy_thesis outcome marks the Mode-C path (fill/2 discriminator).
inv_upstream() ->
    #{<<"strategy_thesis">> => #{<<"gearing_type">> => <<"negatively_geared">>,
                                 <<"archetype">> => <<"capital_growth">>}}.

scaffold() ->
    fh_engine_fill:resolver(<<"mortgage_finance">>, #{}, inv_upstream()).

%% the five investor agent leaves the sidecar returns (LenderFitInvestorLeaves shape).
agent_values() ->
    #{<<"uses_existing_ppor_equity">> => true,
      <<"io_vs_pi_recommendation">> => <<"interest_only">>,
      <<"fixed_vs_variable">> => <<"variable">>,
      <<"offset_strategy_recommendation">> => <<"offset_pointed_at_ppor_for_tax_efficiency">>,
      <<"recommended_lender_shortlist">> =>
          [#{<<"lender">> => <<"Example Bank">>,
             <<"reasoning">> => #{<<"vi">> => <<"Danh sách để cân nhắc.">>,
                                  <<"en">> => <<"A shortlist to consider.">>},
             <<"approval_likelihood">> => <<"indicative">>}]}.

g(O, K) -> maps:get(K, O, undefined).

%% --- 1. scaffold (resolver half) ---------------------------------------------

scaffold_cases() ->
    {O, Rend, Kb} = scaffold(),
    %% input-independent at base: a different thesis content gives an identical outcome.
    {OBare, _, _} = fh_engine_fill:resolver(<<"mortgage_finance">>, #{},
                        #{<<"strategy_thesis">> => #{<<"gearing_type">> => <<"positive_geared">>}}),
    KbSlugs = [maps:get(<<"slug">>, E) || E <- Kb],
    LS = g(O, <<"recommended_loan_structure">>),
    Refi = g(O, <<"refinance_plan_for_portfolio_growth">>),
    AgentNull =
        [check(<<"agent slot null at base: ", F/binary>>, g(O, F), null)
         || F <- agent_null_at_base()],
    [check("renderer = summary-card", Rend, <<"summary-card">>),
     check("outcome has exactly the seven mortgage_plan fields",
           lists:sort(maps:keys(O)), lists:sort(fields())),
     check("debt_optimisations_to_action = [] (pending debts)",
           g(O, <<"debt_optimisations_to_action">>), []),
     check("loan_cost_estimate_year_1 = null (pending loan amount; §98 never LLM-set)",
           g(O, <<"loan_cost_estimate_year_1">>), null),
     check("loan_structure.repayment_type null (agent)", maps:get(<<"repayment_type">>, LS), null),
     check("loan_structure.rate null (agent)", maps:get(<<"rate">>, LS), null),
     check("loan_structure.offset null (agent)", maps:get(<<"offset">>, LS), null),
     check("loan_structure.uses_existing_ppor_equity null (agent)",
           maps:get(<<"uses_existing_ppor_equity">>, LS), null),
     check("loan_structure.interest_only_period_years = 5 (KB io_max_term_years_typical)",
           maps:get(<<"interest_only_period_years">>, LS), 5),
     check("refinance.usable_equity_target_lvr_pct = 80 (KB)",
           maps:get(<<"usable_equity_target_lvr_pct">>, Refi), 80),
     check("refinance.usable_equity_with_lmi_lvr_pct = 90 (KB)",
           maps:get(<<"usable_equity_with_lmi_lvr_pct">>, Refi), 90),
     check("refinance.equity_release_triggers_serviceability_retest = true (KB insight)",
           maps:get(<<"equity_release_triggers_serviceability_retest">>, Refi), true),
     check("refinance.usable_equity_estimate null (pending property)",
           maps:get(<<"usable_equity_estimate">>, Refi), null),
     check("kb_versions = the eight investor lender/loan anchors",
           lists:sort(KbSlugs),
           lists:sort([<<"kb.lender.investment-loan-policies">>,
                       <<"kb.lender.investor-friendly-shortlist">>,
                       <<"kb.loan.interest-only-vs-pi-investor">>,
                       <<"kb.loan.offset-vs-redraw-investor">>,
                       <<"kb.loan.refinance-strategies-portfolio-growth">>,
                       <<"kb.lender.hecs-treatment-by-lender">>,
                       <<"kb.loan.fixed-rate-roll-off-planning">>,
                       <<"kb.lender.serviceability-investment-loans">>])),
     check("has_resolver true", fh_engine_fill:has_resolver(<<"mortgage_finance">>), true),
     check("input-independent at base (same outcome for a different thesis)", OBare, O)]
    ++ AgentNull.

%% --- 2. Layer-1 conformance (the fail-closed commit seam) -------------------

layer1_cases() ->
    {O, _, _} = scaffold(),
    [check(<<"Layer-1 conforms: investor mortgage_plan (scaffold)">>,
           validate(?INV, <<"mortgage_plan">>, O), ok)].

validate(Bp, Type, O) ->
    try fh_engine_outcome:validate(Bp, Type, O), ok
    catch _:Why -> {error, Why} end.

%% --- 3. merge (the §98 slot-scoped fold + the refresh inverse) --------------

merge_cases() ->
    {O, _, _} = scaffold(),
    AV = agent_values(),
    M = fh_engine_fill:merge_agent(<<"mortgage_finance">>, O, AV),
    LS = g(M, <<"recommended_loan_structure">>),
    %% the refresh round-trip: recover the leaves, re-merge → idempotent.
    AV2 = fh_engine_fill:agent_values_from_outcome(<<"mortgage_finance">>, M),
    M2  = fh_engine_fill:merge_agent(<<"mortgage_finance">>, O, AV2),
    [check("merge: io_vs_pi_recommendation folded (top-level)",
           g(M, <<"io_vs_pi_recommendation">>), <<"interest_only">>),
     check("merge: offset_strategy_recommendation folded (top-level)",
           g(M, <<"offset_strategy_recommendation">>),
           <<"offset_pointed_at_ppor_for_tax_efficiency">>),
     check("merge: recommended_lender_shortlist folded",
           length(g(M, <<"recommended_lender_shortlist">>)), 1),
     check("merge: structure.repayment_type = io/PI choice",
           maps:get(<<"repayment_type">>, LS), <<"interest_only">>),
     check("merge: structure.rate = fixed_vs_variable choice",
           maps:get(<<"rate">>, LS), <<"variable">>),
     check("merge: structure.offset = offset choice",
           maps:get(<<"offset">>, LS), <<"offset_pointed_at_ppor_for_tax_efficiency">>),
     check("merge: structure.uses_existing_ppor_equity folded",
           maps:get(<<"uses_existing_ppor_equity">>, LS), true),
     %% slot-scoped (§98): the agent moved NO resolver figure.
     check("slot-scoped: refinance framing byte-identical",
           g(M, <<"refinance_plan_for_portfolio_growth">>),
           g(O, <<"refinance_plan_for_portfolio_growth">>)),
     check("slot-scoped: debt_optimisations untouched ([])",
           g(M, <<"debt_optimisations_to_action">>), []),
     check("slot-scoped: loan_cost untouched (null)",
           g(M, <<"loan_cost_estimate_year_1">>), null),
     check("slot-scoped: structure IO term untouched (5)",
           maps:get(<<"interest_only_period_years">>, LS), 5),
     check("merged outcome still validates", validate(?INV, <<"mortgage_plan">>, M), ok),
     %% refresh inverse: the recovered leaves equal the originals; re-merge is idempotent.
     check("agent_values_from_outcome recovers the five leaves", AV2, AV),
     check("re-merge from recovered leaves is idempotent", M2, M)].

%% --- 4. no regression (the FHB mortgage_finance path) ------------------------

no_regression_cases() ->
    %% FHB path: NO strategy_thesis upstream → fill_fhb (profile + scheme_stack).
    {Fhb, FhbRend, _} = fh_engine_fill:resolver(<<"mortgage_finance">>,
        #{onboarding => #{<<"state">> => <<"NSW">>,
                          <<"target_price_range">> => [600000, 700000]}},
        #{<<"profile">> => #{},
          <<"scheme_stack">> =>
              #{<<"applicable_schemes">> => [#{<<"role">> => <<"deposit_guarantee">>}]}}),
    %% FHB 2-leaf merge still folds (shortlist + rate).
    AVf = #{<<"recommended_lender_shortlist">> => [#{<<"lender">> => <<"X">>}],
            <<"fixed_vs_variable">> => <<"fixed_2yr">>},
    Mf = fh_engine_fill:merge_agent(<<"mortgage_finance">>, Fhb, AVf),
    LSf = maps:get(<<"loan_structure_recommendation">>, Mf, #{}),
    [check("FHB mortgage_finance renderer still summary-card", FhbRend, <<"summary-card">>),
     check("FHB carries recommended_path (fhg_backed via deposit_guarantee)",
           maps:get(<<"recommended_path">>, Fhb, undefined), <<"fhg_backed">>),
     check("FHB capacity null at base (no income)",
           maps:get(<<"expected_borrowing_capacity">>, Fhb, undefined), null),
     check("FHB has NO investor io_vs_pi_recommendation field",
           maps:is_key(<<"io_vs_pi_recommendation">>, Fhb), false),
     check("FHB 2-leaf merge folds the shortlist",
           length(maps:get(<<"recommended_lender_shortlist">>, Mf, [])), 1),
     check("FHB 2-leaf merge folds the rate into loan_structure_recommendation",
           maps:get(<<"rate">>, LSf, undefined), <<"fixed_2yr">>)].

%% --- helpers ----------------------------------------------------------------

check(Label, Got, Want) ->
    case Got =:= Want of
        true  -> io:format("  PASS   ~ts~n", [Label]), pass;
        false -> io:format("  FAIL   ~ts = ~p, expected ~p~n", [Label, Got, Want]), fail
    end.
