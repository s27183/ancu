#!/usr/bin/env escript
%%! -sname fh_mortgage_finance_foreign_conformance
%%
%% Conformance suite for the `mortgage_finance` MODE-B (foreign-person) variant
%% (fh_engine_mortgage:fill_fhb_foreign/2 + merge_agent_fhb_foreign/2 — blueprint
%% fhb-foreign-au.md component 5, mode-b-wedge.md P2 slice 3). THIRD shared-name variant
%% (Mode A / Mode B / Mode C all named `mortgage_finance`): fill/2 routes on the
%% `strategy_thesis` upstream FIRST (investor axis, unchanged), then on
%% Args.firb_required_any (foreign axis, orthogonal — the SAME flag buyer_profile/1 and
%% the compliance FIRB gate key on) within the non-investor path. The Mode-A FHB body is
%% byte-identical (zero regression). Loads the SAME materialized artifact the engine
%% loads (priv/kb/artifact.json) and asserts:
%%   1. SCAFFOLD (resolver half) — the Mode-B mortgage_plan is a DIFFERENT seven-field
%%      shape from Mode A's nine (no debt_optimisations_to_action / pre_approval_expiry /
%%      reapplication_required / key_assumptions; adds deposit_required +
%%      firb_dependency_acknowledged=true, definitional). Honest-partial: capacity null
%%      (no income), recommended_path null (no visa captured), deposit_required a
%%      conservative 30%-of-ceiling estimate, the agent shortlist slot null.
%%   2. THE VISA-CLASS PATH HEURISTIC — recommended_path_foreign/1 resolves
%%      temp_resident_with_au_income for an AU-income-eligible visa (485/student/etc),
%%      standard_non_resident for a known non-AU-income visa, null when unset.
%%   3. MERGE (the §98 slot-scoped fold) — merge_agent_fhb_foreign folds the two leaves
%%      (shortlist + rate); every other field is byte-identical; the refresh round-trip
%%      (agent_values_from_outcome -> re-merge) is idempotent.
%%   4. NO REGRESSION — the Mode-A FHB path (no firb_required_any) is untouched: still
%%      the nine-field outcome, still passes Layer-1 validate/3, has NO
%%      firb_dependency_acknowledged/deposit_required fields, its 2-leaf merge still folds.
%%
%% Run from engine/erlang with the build libs on the path (no Postgres, no live model):
%%   ERL_LIBS=_build/default/lib escript test/mortgage_finance_foreign_conformance.escript

-mode(compile).

-define(FHB, <<"fhb-domestic-au">>).

main(_) ->
    ok = fh_engine_kb:load(),
    io:format("mortgage_finance_foreign conformance — fh_engine_mortgage (Mode-B)~n~n"),
    R = lists:flatten([scaffold_cases(), path_heuristic_cases(), merge_cases(),
                       no_regression_cases()]),
    Fails = [X || X <- R, X =:= fail],
    io:format("~n================================================================~n"),
    case Fails of
        [] -> io:format("PASS — all ~p mortgage_finance_foreign anchors hold~n", [length(R)]), halt(0);
        _  -> io:format("FAIL — ~p anchor(s) mismatched~n", [length(Fails)]), halt(1)
    end.

%% --- fixtures ----------------------------------------------------------------

fields() ->
    [<<"recommended_path">>, <<"expected_borrowing_capacity">>, <<"deposit_required">>,
     <<"recommended_lender_shortlist">>, <<"firb_dependency_acknowledged">>,
     <<"loan_structure_recommendation">>, <<"pre_approval_action_plan">>].

base_profile() ->
    #{<<"target_price_range">> => [700000, 900000],
      <<"applicants">> => [#{<<"visa_class">> => null}]}.

foreign_args() -> #{firb_required_any => true}.

scaffold() ->
    fh_engine_fill:resolver(<<"mortgage_finance">>, foreign_args(),
        #{<<"profile">> => base_profile()}).

g(O, K) -> maps:get(K, O, undefined).

%% --- 1. scaffold (resolver half) ---------------------------------------------

scaffold_cases() ->
    {O, Rend, Kb} = scaffold(),
    %% input-independent of onboarding CONTENT for the fixed fields (firb_dependency,
    %% action plan) — a different profile still gives firb_dependency_acknowledged=true.
    {OBare, _, _} = fh_engine_fill:resolver(<<"mortgage_finance">>, foreign_args(),
        #{<<"profile">> => #{}}),
    KbSlugs = [maps:get(<<"slug">>, E) || E <- Kb],
    LS = g(O, <<"loan_structure_recommendation">>),
    [check("renderer = summary-card", Rend, <<"summary-card">>),
     check("outcome has exactly the seven Mode-B mortgage_plan fields",
           lists:sort(maps:keys(O)), lists:sort(fields())),
     check("recommended_path = null (no visa captured yet)",
           g(O, <<"recommended_path">>), null),
     check("expected_borrowing_capacity = null (no income captured)",
           g(O, <<"expected_borrowing_capacity">>), null),
     check("deposit_required = 270000 (30% of the $900,000 ceiling)",
           g(O, <<"deposit_required">>), 270000),
     check("recommended_lender_shortlist null (agent slot)",
           g(O, <<"recommended_lender_shortlist">>), null),
     check("firb_dependency_acknowledged = true (definitional)",
           g(O, <<"firb_dependency_acknowledged">>), true),
     check("loan_structure.type = principal_and_interest",
           maps:get(<<"type">>, LS), <<"principal_and_interest">>),
     check("loan_structure.currency = AUD (fixed, never foreign-currency)",
           maps:get(<<"currency">>, LS), <<"AUD">>),
     check("loan_structure.rate null (agent slot)", maps:get(<<"rate">>, LS), null),
     check("pre_approval_action_plan has five bilingual action items",
           length(g(O, <<"pre_approval_action_plan">>)), 5),
     check("kb_versions = the seven Mode-B lending anchors",
           lists:sort(KbSlugs),
           lists:sort([<<"kb.lender.non-resident-friendly-shortlist">>,
                       <<"kb.lender.temp-resident-lending-policies">>,
                       <<"kb.lender.485-visa-treatment">>,
                       <<"kb.lender.foreign-buyer-deposit-requirements">>,
                       <<"kb.lender.firb-approval-as-condition-precedent">>,
                       <<"kb.lender.documentation-non-resident">>,
                       <<"kb.fx.loan-currency-considerations">>])),
     check("has_resolver true", fh_engine_fill:has_resolver(<<"mortgage_finance">>), true),
     check("firb_dependency_acknowledged still true with an empty profile (definitional)",
           g(OBare, <<"firb_dependency_acknowledged">>), true),
     check("deposit_required null with no target_price_range",
           g(OBare, <<"deposit_required">>), null)].

%% --- 2. the visa-class path heuristic -----------------------------------------

path_heuristic_cases() ->
    AuIncomeProfile = #{<<"applicants">> => [#{<<"visa_class">> => <<"graduate_485">>}]},
    NonResidentProfile = #{<<"applicants">> => [#{<<"visa_class">> => <<"non_resident">>}]},
    UnsetProfile = #{<<"applicants">> => [#{<<"visa_class">> => null}]},
    [check("485 visa (AU income) -> temp_resident_with_au_income",
           fh_engine_mortgage:recommended_path_foreign(AuIncomeProfile),
           <<"temp_resident_with_au_income">>),
     check("non_resident visa (no AU income) -> standard_non_resident",
           fh_engine_mortgage:recommended_path_foreign(NonResidentProfile),
           <<"standard_non_resident">>),
     check("no visa captured -> null (undetermined, not a guess)",
           fh_engine_mortgage:recommended_path_foreign(UnsetProfile), null),
     check("deposit_required(null) = null", fh_engine_mortgage:deposit_required(null), null),
     check("deposit_required(1000000) = 300000 (30%)",
           fh_engine_mortgage:deposit_required(1000000), 300000)].

%% --- 3. merge (the §98 slot-scoped fold + the refresh inverse) --------------

merge_cases() ->
    {O, _, _} = scaffold(),
    AV = #{<<"recommended_lender_shortlist">> =>
               [#{<<"lender">> => <<"Example Bank">>,
                  <<"reasoning">> => #{<<"vi">> => <<"Phù hợp với hồ sơ không thường trú.">>,
                                       <<"en">> => <<"Fits a non-resident profile.">>},
                  <<"approval_likelihood">> => <<"indicative">>}],
           <<"fixed_vs_variable">> => <<"fixed_2yr">>},
    M = fh_engine_fill:merge_agent(<<"mortgage_finance">>, O, AV),
    LS = g(M, <<"loan_structure_recommendation">>),
    AV2 = fh_engine_fill:agent_values_from_outcome(<<"mortgage_finance">>, M),
    M2  = fh_engine_fill:merge_agent(<<"mortgage_finance">>, O, AV2),
    [check("merge: recommended_lender_shortlist folded",
           length(g(M, <<"recommended_lender_shortlist">>)), 1),
     check("merge: loan_structure.rate = fixed_vs_variable choice",
           maps:get(<<"rate">>, LS), <<"fixed_2yr">>),
     check("merge: loan_structure.type untouched (slot-scoped)",
           maps:get(<<"type">>, LS), <<"principal_and_interest">>),
     check("merge: loan_structure.currency untouched (slot-scoped)",
           maps:get(<<"currency">>, LS), <<"AUD">>),
     check("slot-scoped: deposit_required byte-identical",
           g(M, <<"deposit_required">>), g(O, <<"deposit_required">>)),
     check("slot-scoped: firb_dependency_acknowledged byte-identical",
           g(M, <<"firb_dependency_acknowledged">>), true),
     check("slot-scoped: pre_approval_action_plan byte-identical",
           g(M, <<"pre_approval_action_plan">>), g(O, <<"pre_approval_action_plan">>)),
     check("agent_values_from_outcome recovers the two leaves", AV2, AV),
     check("re-merge from recovered leaves is idempotent", M2, M)].

%% --- 4. no regression (the Mode-A FHB mortgage_finance path) -----------------

no_regression_cases() ->
    {Fhb, FhbRend, _} = fh_engine_fill:resolver(<<"mortgage_finance">>,
        #{onboarding => #{<<"state">> => <<"NSW">>,
                          <<"target_price_range">> => [600000, 700000]}},
        #{<<"profile">> => #{},
          <<"scheme_stack">> =>
              #{<<"applicable_schemes">> => [#{<<"role">> => <<"deposit_guarantee">>}]}}),
    V = try fh_engine_outcome:validate(?FHB, <<"mortgage_plan">>, Fhb), ok
        catch _:Why -> {error, Why} end,
    AVf = #{<<"recommended_lender_shortlist">> => [#{<<"lender">> => <<"X">>}],
            <<"fixed_vs_variable">> => <<"fixed_2yr">>},
    Mf = fh_engine_fill:merge_agent(<<"mortgage_finance">>, Fhb, AVf),
    LSf = maps:get(<<"loan_structure_recommendation">>, Mf, #{}),
    [check("FHB mortgage_finance renderer still summary-card", FhbRend, <<"summary-card">>),
     check("FHB carries recommended_path (fhg_backed via deposit_guarantee)",
           maps:get(<<"recommended_path">>, Fhb, undefined), <<"fhg_backed">>),
     check("FHB has NO firb_dependency_acknowledged field",
           maps:is_key(<<"firb_dependency_acknowledged">>, Fhb), false),
     check("FHB has NO deposit_required field",
           maps:is_key(<<"deposit_required">>, Fhb), false),
     check("FHB still has the nine-field Mode-A shape (key_assumptions present)",
           maps:is_key(<<"key_assumptions">>, Fhb), true),
     check("Layer-1 conforms: FHB mortgage_plan (no regression)", V, ok),
     check("FHB 2-leaf merge still folds the shortlist",
           length(maps:get(<<"recommended_lender_shortlist">>, Mf, [])), 1),
     check("FHB 2-leaf merge still folds the rate",
           maps:get(<<"rate">>, LSf, undefined), <<"fixed_2yr">>)].

%% --- helpers ----------------------------------------------------------------

check(Label, Got, Want) ->
    case Got =:= Want of
        true  -> io:format("  PASS   ~ts~n", [Label]), pass;
        false -> io:format("  FAIL   ~ts = ~p, expected ~p~n", [Label, Got, Want]), fail
    end.
