#!/usr/bin/env escript
%%! -sname fh_mortgage_conformance
%%
%% Conformance suite for fh_engine_mortgage (the RESOLVER half of the two-path
%% mortgage_finance component) against the executable spec tests/mortgage_eval.py.
%% Loads the SAME materialized artifact the engine loads (priv/kb/artifact.json via
%% fh_engine_kb) and runs the spec's anchors through the Erlang implementation.
%%
%% mortgage_finance is TWO-PATH (mortgage-finance-two-path.md): the resolver assembles
%% the figures + structure, the agent authors only the two lender_fit leaves, Erlang
%% merges. At the base turn every figure is honestly PENDING — so this suite checks the
%% STRUCTURE + the §98 boundary (the agent never authors a figure; the merge is
%% slot-scoped), not arithmetic.
%%
%% Run from engine/erlang with the build libs on the path (no Postgres needed):
%%   ERL_LIBS=_build/default/lib escript test/mortgage_conformance.escript

-mode(compile).

main(_) ->
    ok = fh_engine_kb:load(),
    io:format("mortgage conformance — fh_engine_mortgage (two-path resolver half)~n~n"),
    R = lists:flatten(
          [path_cases(), fhg_cases(), loan_structure_case(),
           base_fill_cases(), merge_cases()]),
    Fails = [X || X <- R, X =:= fail],
    io:format("~n================================================================~n"),
    case Fails of
        [] ->
            io:format("PASS — all ~p mortgage anchors green~n", [length(R)]),
            halt(0);
        _ ->
            io:format("FAIL — ~p anchor(s) mismatched~n", [length(Fails)]),
            halt(1)
    end.

%% --- recommended_path from FHG presence -------------------------------------

path_cases() ->
    [check("recommended_path(fhg)", fh_engine_mortgage:recommended_path(stack_fhg()),
           <<"fhg_backed">>),
     check("recommended_path(no-fhg)", fh_engine_mortgage:recommended_path(stack_no_fhg()),
           null),
     check("recommended_path(empty)", fh_engine_mortgage:recommended_path(#{}), null)].

%% --- FHG detection (by role) ------------------------------------------------

fhg_cases() ->
    [check("has_fhg(fhg)", fh_engine_mortgage:has_fhg(stack_fhg()), true),
     check("has_fhg(no-fhg)", fh_engine_mortgage:has_fhg(stack_no_fhg()), false),
     check("has_fhg(empty)", fh_engine_mortgage:has_fhg(#{}), false)].

%% --- loan structure default (P&I; rate is the agent slot, null) -------------

loan_structure_case() ->
    LS = fh_engine_mortgage:loan_structure_base(),
    [check("loan_structure type = P&I", maps:get(<<"type">>, LS),
           <<"principal_and_interest">>),
     check("loan_structure rate = null (agent slot)", maps:get(<<"rate">>, LS), null)].

%% --- base fill: honest-partial PENDING figures (the §98-clean slots) --------

base_fill_cases() ->
    {Outcome, Renderer, _Kb} = fh_engine_mortgage:fill(
        #{onboarding => #{<<"state">> => <<"NSW">>,
                          <<"target_price_range">> => [600000, 700000]},
          intent => <<"owner_occupier">>},
        #{<<"profile">> => #{<<"target_price_range">> => [600000, 700000]},
          <<"scheme_stack">> => stack_fhg()}),
    [check("base fill: renderer = summary-card", Renderer, <<"summary-card">>),
     check("base fill: recommended_path = fhg_backed",
           maps:get(<<"recommended_path">>, Outcome), <<"fhg_backed">>),
     check("base fill: capacity PENDING (null) - s98",
           maps:get(<<"expected_borrowing_capacity">>, Outcome), null),
     check("base fill: debt-optimisations PENDING ([])",
           maps:get(<<"debt_optimisations_to_action">>, Outcome), []),
     check("base fill: lender shortlist = null (agent slot)",
           maps:get(<<"recommended_lender_shortlist">>, Outcome), null),
     check("base fill: loan_structure.rate = null (agent slot)",
           maps:get(<<"rate">>, maps:get(<<"loan_structure_recommendation">>, Outcome)),
           null),
     check("base fill: loan_structure.type = P&I",
           maps:get(<<"type">>, maps:get(<<"loan_structure_recommendation">>, Outcome)),
           <<"principal_and_interest">>)].

%% --- merge_agent: slot-scoped; the agent cannot move a figure (§98) ---------

merge_cases() ->
    {RO, _R, _Kb} = fh_engine_mortgage:fill(
        #{onboarding => #{<<"state">> => <<"NSW">>,
                          <<"target_price_range">> => [600000, 700000]},
          intent => <<"owner_occupier">>},
        #{<<"profile">> => #{<<"target_price_range">> => [600000, 700000]},
          <<"scheme_stack">> => stack_fhg()}),
    Shortlist = [#{<<"lender">> => <<"A major (FHG panel)">>,
                   <<"reasoning">> => <<"wide panel">>,
                   <<"approval_likelihood">> => <<"indicative">>}],
    AgentValues = #{<<"recommended_lender_shortlist">> => Shortlist,
                    <<"fixed_vs_variable">> => <<"variable">>},
    Merged = fh_engine_mortgage:merge_agent(RO, AgentValues),
    MergedLS = maps:get(<<"loan_structure_recommendation">>, Merged),
    [check("merge places shortlist",
           maps:get(<<"recommended_lender_shortlist">>, Merged), Shortlist),
     check("merge places rate", maps:get(<<"rate">>, MergedLS), <<"variable">>),
     check("merge leaves capacity null",
           maps:get(<<"expected_borrowing_capacity">>, Merged), null),
     check("merge leaves debt-optimisations empty",
           maps:get(<<"debt_optimisations_to_action">>, Merged), []),
     check("merge leaves recommended_path unchanged",
           maps:get(<<"recommended_path">>, Merged),
           maps:get(<<"recommended_path">>, RO)),
     check("merge leaves key_assumptions unchanged",
           maps:get(<<"key_assumptions">>, Merged),
           maps:get(<<"key_assumptions">>, RO)),
     check("merge leaves loan_structure.type unchanged",
           maps:get(<<"type">>, MergedLS), <<"principal_and_interest">>),
     %% the strongest §98 postcondition: everything EXCEPT the two agent slots is
     %% byte-identical between resolver outcome and merged outcome.
     check("merge is slot-scoped (only 2 slots differ)",
           map_diff_keys(RO, Merged), [<<"loan_structure_recommendation">>,
                                       <<"recommended_lender_shortlist">>])].

%% --- helpers ----------------------------------------------------------------

stack_fhg() ->
    #{<<"applicable_schemes">> =>
          [#{<<"role">> => <<"deposit_guarantee">>}, #{<<"role">> => <<"grant">>}]}.

stack_no_fhg() ->
    #{<<"applicable_schemes">> =>
          [#{<<"role">> => <<"deposit_savings">>}, #{<<"role">> => <<"grant">>}]}.

%% the sorted list of top-level keys whose value differs between two maps.
map_diff_keys(A, B) ->
    lists:sort([K || K <- maps:keys(A),
                     maps:get(K, A) =/= maps:get(K, B, make_ref())]).

check(Label, Got, Want) ->
    case Got =:= Want of
        true  -> io:format("  PASS   ~s = ~p~n", [Label, Got]), pass;
        false -> io:format("  FAIL   ~s = ~p, expected ~p~n", [Label, Got, Want]), fail
    end.
