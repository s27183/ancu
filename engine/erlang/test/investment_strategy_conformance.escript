#!/usr/bin/env escript
%%! -sname fh_investment_strategy_conformance
%%
%% Conformance suite for the `investment_strategy` two-path component (fh_engine_fill —
%% the FIRST Mode-C agent-path component; blueprint component 3, the investor base spine).
%% Loads the SAME materialized artifact the engine loads (priv/kb/artifact.json) and
%% asserts what the two-path commit seam relies on:
%%   1. RESOLVER SCAFFOLD — the resolver half owns the renderer + the four-anchor
%%      kb_versions audit + the carried hold horizon, and leaves every agent slot and
%%      every property-relative target null (honest-partial; the agent authors no figure).
%%   2. MERGE — merge_agent/3 folds the three judgment leaves (archetype, gearing_type,
%%      one_liner) into the scaffold, slot-scoped: the targets / horizon / verdicts are
%%      byte-untouched (the §98 property — the agent cannot move a resolver field).
%%   3. REFRESH ROUND-TRIP — agent_values_from_outcome/2 recovers exactly those three
%%      leaves from a committed outcome, in the shape merge_agent/3 re-consumes (the
%%      base_resolver refresh re-attaches the stored thesis with no sidecar call).
%%   4. LAYER-1 CONFORMANCE — the scaffold AND the merged outcome pass
%%      fh_engine_outcome:validate/3 against the compiled `strategy_thesis` schema
%%      (one_liner is registry-typed `string` → scalar, unchecked → the bilingual {vi,en}
%%      passes; the real bilingual contract is the sidecar's Pydantic schema).
%%   5. NO MODE-A REGRESSION — the new fh_engine_fill clauses are additive: the
%%      mortgage_finance two-path merge/refresh dispatch still resolves (distinct names).
%%
%% Run from engine/erlang with the build libs on the path (no Postgres, no live model):
%%   ERL_LIBS=_build/default/lib escript test/investment_strategy_conformance.escript

-mode(compile).

-define(INV, <<"investor-domestic-au">>).

main(_) ->
    ok = fh_engine_kb:load(),
    io:format("investment_strategy conformance — fh_engine_fill (Mode-C two-path)~n~n"),
    R = lists:flatten([scaffold_cases(), merge_cases(), target_yield_cases(), refresh_cases(),
                       layer1_cases(), no_regression_cases()]),
    Fails = [X || X <- R, X =:= fail],
    io:format("~n================================================================~n"),
    case Fails of
        [] -> io:format("PASS — all ~p investment_strategy anchors hold~n", [length(R)]), halt(0);
        _  -> io:format("FAIL — ~p anchor(s) mismatched~n", [length(Fails)]), halt(1)
    end.

%% --- fixtures ----------------------------------------------------------------

%% upstream as the turn presents it: outcomes keyed by type. investment_strategy reads
%% `profile` (dag_reads); the scaffold carries hold_horizon_years off it.
upstream(Hold) ->
    #{<<"profile">> => #{<<"hold_horizon_years">> => Hold,
                         <<"target_price_range">> => [600000, 800000]}}.

scaffold(Hold) ->
    {O, Rend, Kb} = fh_engine_fill:resolver(<<"investment_strategy">>, #{}, upstream(Hold)),
    {O, Rend, Kb}.

%% the three judgment leaves the sidecar would author (archetype/gearing enums + a
%% bilingual one_liner) — the merge_agent input shape.
agent_leaves() ->
    #{<<"archetype">>    => <<"capital_growth">>,
      <<"gearing_type">> => <<"negatively_geared">>,
      <<"one_liner">>    => #{<<"vi">> => <<"Tập trung tăng trưởng vốn dài hạn."/utf8>>,
                              <<"en">> => <<"Long-horizon capital-growth focus.">>}}.

g(O, K) -> maps:get(K, O, undefined).

%% --- 1. resolver scaffold ---------------------------------------------------

scaffold_cases() ->
    {O, Rend, Kb} = scaffold(10),
    {ONull, _, _} = scaffold(null),
    KbSlugs = [maps:get(<<"slug">>, E) || E <- Kb],
    [check("renderer = summary-card", Rend, <<"summary-card">>),
     check("agent slot archetype null at scaffold", g(O, <<"archetype">>), null),
     check("agent slot gearing_type null at scaffold", g(O, <<"gearing_type">>), null),
     check("agent slot one_liner null at scaffold", g(O, <<"one_liner">>), null),
     check("target_gross_yield null (honest-partial; needs archetype + property)",
           g(O, <<"target_gross_yield">>), null),
     check("target_capital_growth null (honest-partial)", g(O, <<"target_capital_growth">>), null),
     check("target_lvr null (honest-partial)", g(O, <<"target_lvr">>), null),
     check("exit_strategy null (judgment pending the thesis)", g(O, <<"exit_strategy">>), null),
     check("is_property_aligned_with_thesis null (no property at base)",
           g(O, <<"is_property_aligned_with_thesis">>), null),
     check("alignment_reasoning null (no property at base)", g(O, <<"alignment_reasoning">>), null),
     check("hold_period_years carried from upstream profile (=10)", g(O, <<"hold_period_years">>), 10),
     check("kb_versions = the five strategy anchors (incl. target-yield-by-archetype)",
           lists:sort(KbSlugs),
           lists:sort([<<"kb.investor.strategy-archetypes">>,
                       <<"kb.investor.gearing-types-and-implications">>,
                       <<"kb.investor.hold-period-considerations">>,
                       <<"kb.investor.exit-strategy-options">>,
                       <<"kb.investor.target-yield-by-archetype">>])),
     %% horizon honest-partial: unset onboarding horizon → null (long/indefinite default).
     check("hold_period_years null when upstream horizon unset",
           g(ONull, <<"hold_period_years">>), null)].

%% --- target_gross_yield derivation (Slice C unblock — the labelled-placeholder defaults) ----
%% target_gross_yield is DERIVED in merge_agent from the agent's archetype via
%% kb.investor.target-yield-by-archetype (indicative defaults). This is what makes the downstream
%% buying_strategy yield-anchored discipline non-dormant. The archetype is the agent's; the mapping
%% to a number is the resolver's (§98). land_banking (not yield-driven) and an absent archetype → null.

derive_yield(Archetype) ->
    AV = #{<<"archetype">> => Archetype, <<"gearing_type">> => null, <<"one_liner">> => null},
    M = fh_engine_fill:merge_agent(<<"investment_strategy">>, element(1, scaffold(10)), AV),
    g(M, <<"target_gross_yield">>).

target_yield_cases() ->
    [check("cash_flow → 5.5 (highest yield target)",      derive_yield(<<"cash_flow">>), 5.5),
     check("dual_income → 5.0",                            derive_yield(<<"dual_income">>), 5.0),
     check("value_add → 4.5",                              derive_yield(<<"value_add">>), 4.5),
     check("balanced → 4.0",                               derive_yield(<<"balanced">>), 4.0),
     check("capital_growth → 3.0 (lowest yield target)",   derive_yield(<<"capital_growth">>), 3.0),
     check("land_banking → null (not yield-driven)",       derive_yield(<<"land_banking">>), null),
     check("absent archetype → null (honest-partial)",
           g(fh_engine_fill:merge_agent(<<"investment_strategy">>, element(1, scaffold(10)), #{}),
             <<"target_gross_yield">>), null)].

%% --- 2. merge (slot-scoped fold; §98 — no figure moved) ---------------------

merge_cases() ->
    {Scaffold, _, _} = scaffold(10),
    AV = agent_leaves(),
    M = fh_engine_fill:merge_agent(<<"investment_strategy">>, Scaffold, AV),
    OneLiner = g(M, <<"one_liner">>),
    [check("merge folds archetype", g(M, <<"archetype">>), <<"capital_growth">>),
     check("merge folds gearing_type", g(M, <<"gearing_type">>), <<"negatively_geared">>),
     check("merge folds one_liner (bilingual {vi,en})",
           {maps:is_key(<<"vi">>, OneLiner), maps:is_key(<<"en">>, OneLiner)}, {true, true}),
     %% target_gross_yield is DERIVED from the agent's archetype via the labelled-placeholder KB
     %% defaults (capital_growth → 3.0) — the archetype is the agent's, the number is the resolver's
     %% (§98 — the LLM never authors the figure; it only picks the enum the resolver maps).
     check("merge DERIVES target_gross_yield from archetype (capital_growth → 3.0)",
           g(M, <<"target_gross_yield">>), 3.0),
     %% the other property-relative targets stay null (no derivation wired — honest-partial).
     check("merge leaves target_lvr untouched (null)", g(M, <<"target_lvr">>), null),
     check("merge leaves hold_period_years untouched (=10)", g(M, <<"hold_period_years">>), 10),
     check("merge leaves alignment verdict untouched (null)",
           g(M, <<"is_property_aligned_with_thesis">>), null)].

%% --- 3. refresh round-trip (inverse of the merge) ---------------------------

refresh_cases() ->
    {Scaffold, _, _} = scaffold(10),
    AV = agent_leaves(),
    M = fh_engine_fill:merge_agent(<<"investment_strategy">>, Scaffold, AV),
    Recovered = fh_engine_fill:agent_values_from_outcome(<<"investment_strategy">>, M),
    [check("agent_values_from_outcome recovers exactly the three leaves (== merge input)",
           Recovered, AV),
     %% re-attaching the recovered leaves through the SAME merge is idempotent.
     check("re-merge of recovered leaves is idempotent",
           fh_engine_fill:merge_agent(<<"investment_strategy">>, Scaffold, Recovered), M)].

%% --- 4. Layer-1 conformance (the fail-closed commit seam) -------------------

layer1_cases() ->
    {Scaffold, _, _} = scaffold(10),
    M = fh_engine_fill:merge_agent(<<"investment_strategy">>, Scaffold, agent_leaves()),
    [check(<<"Layer-1 conforms: scaffold">>, validate(Scaffold), ok),
     check(<<"Layer-1 conforms: merged (one_liner {vi,en} passes scalar/string)">>,
           validate(M), ok)].

validate(O) ->
    try fh_engine_outcome:validate(?INV, <<"strategy_thesis">>, O), ok
    catch _:Why -> {error, Why} end.

%% --- 5. no Mode-A regression (additive clauses; distinct names) -------------

no_regression_cases() ->
    %% the mortgage_finance two-path merge/refresh must still dispatch through the new
    %% fh_engine_fill clauses (they are additive — investment_strategy never shadows it).
    StoredM = #{<<"recommended_lender_shortlist">> => [#{<<"lender">> => <<"X">>}],
                <<"loan_structure_recommendation">> => #{<<"rate">> => <<"variable">>}},
    AVm = fh_engine_fill:agent_values_from_outcome(<<"mortgage_finance">>, StoredM),
    [check("mortgage_finance agent_values still dispatch (rate recovered)",
           maps:get(<<"fixed_vs_variable">>, AVm), <<"variable">>),
     check("mortgage_finance shortlist recovered",
           length(maps:get(<<"recommended_lender_shortlist">>, AVm)), 1),
     check("investment_strategy has_resolver true (two_path classified)",
           fh_engine_fill:has_resolver(<<"investment_strategy">>), true)].

%% --- helpers ----------------------------------------------------------------

check(Label, Got, Want) ->
    case Got =:= Want of
        true  -> io:format("  PASS   ~ts~n", [Label]), pass;
        false -> io:format("  FAIL   ~ts = ~p, expected ~p~n", [Label, Got, Want]), fail
    end.
