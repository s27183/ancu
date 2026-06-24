#!/usr/bin/env escript
%%! -sname fh_tax_structure_conformance
%%
%% Conformance suite for the `tax_structure` resolver + two-path merge (fh_engine_fill — the
%% investor base spine, blueprint component 6; a TWO-PATH component, the same class as
%% investment_strategy: a resolver scaffold + ONE entity_structuring agent leaf folded by
%% merge_agent/3). Loads the SAME materialized artifact the engine loads (priv/kb/artifact.json)
%% and asserts what the base-spine presence relies on:
%%   1. SCAFFOLD — the resolver owns the data-table renderer + the six tax anchors (the
%%      method/figure audit trail), computes the two KB-grounded CGT determinant CONSTANTS
%%      (cgt_discount_eligible = true, cost_base_depreciation_clawback = true) that the built
%%      disposition consumer reads, leaves the entity agent slot null, and leaves every figure
%%      null (honest-partial: property/rent-dependent OR blocked by the banded-vs-scalar /
%%      ATO-brackets decisions deferred to property_assessment). Input-independent at base.
%%   2. LAYER-1 CONFORMANCE — the scaffold passes fh_engine_outcome:validate/3 against the
%%      compiled `tax_optimised_structure` schema (null conforms to any field; the two bool
%%      constants conform); and so does the MERGED outcome once a real entity is folded.
%%   3. TWO-PATH MERGE — merge_agent/3 folds EXACTLY the one entity leaf (recommended_entity)
%%      and leaves every resolver figure untouched (§98 — the agent authors no figure/verdict);
%%      a stray figure key in the agent values is NOT folded; agent_values_from_outcome/2
%%      round-trips the stored entity (the base_resolver-refresh inverse).
%%   4. NO REGRESSION — the new clauses are additive: yield_modelling stays PURE-resolver (no
%%      merge), investment_strategy (two-path) still dispatches resolver + merge.
%%
%% Run from engine/erlang with the build libs on the path (no Postgres, no live model):
%%   ERL_LIBS=_build/default/lib escript test/tax_structure_conformance.escript

-mode(compile).

-define(INV, <<"investor-domestic-au">>).

main(_) ->
    ok = fh_engine_kb:load(),
    io:format("tax_structure conformance — fh_engine_fill (Mode-C two-path)~n~n"),
    R = lists:flatten([scaffold_cases(), layer1_cases(), two_path_cases(),
                       no_regression_cases()]),
    Fails = [X || X <- R, X =:= fail],
    io:format("~n================================================================~n"),
    case Fails of
        [] -> io:format("PASS — all ~p tax_structure anchors hold~n", [length(R)]), halt(0);
        _  -> io:format("FAIL — ~p anchor(s) mismatched~n", [length(Fails)]), halt(1)
    end.

%% --- fixtures ----------------------------------------------------------------

%% the tax_optimised_structure figure fields (the eleven the registry declares).
fields() ->
    [<<"recommended_entity">>, <<"negative_gearing_active">>,
     <<"annual_tax_refund_year_1">>, <<"after_tax_cash_flow_year_1">>,
     <<"after_tax_cash_flow_per_week">>, <<"total_depreciation_year_1">>,
     <<"cgt_discount_eligible">>, <<"cgt_marginal_rate">>,
     <<"cost_base_depreciation_clawback">>, <<"annual_compliance_cost">>,
     <<"setup_costs">>].

%% the eight fields that are null at base (everything except the two CGT determinant constants
%% and the agent slot — which is also null pre-merge, but tracked separately below).
null_at_base() ->
    [<<"recommended_entity">>, <<"negative_gearing_active">>,
     <<"annual_tax_refund_year_1">>, <<"after_tax_cash_flow_year_1">>,
     <<"after_tax_cash_flow_per_week">>, <<"total_depreciation_year_1">>,
     <<"cgt_marginal_rate">>, <<"annual_compliance_cost">>, <<"setup_costs">>].

%% a realistic base investor upstream (profile + strategy_thesis present; property absent).
upstream() ->
    #{<<"profile">> => #{<<"applicant_count">> => 1,
                         <<"target_price_range">> => [600000, 800000],
                         <<"target_zone">> => [<<"Footscray">>]},
      <<"strategy_thesis">> => #{<<"archetype">> => <<"capital_growth">>,
                                 <<"hold_period_years">> => 10}}.

scaffold(Upstream) ->
    fh_engine_fill:resolver(<<"tax_structure">>, #{}, Upstream).

g(O, K) -> maps:get(K, O, undefined).

%% --- 1. scaffold -------------------------------------------------------------

scaffold_cases() ->
    {O, Rend, Kb} = scaffold(upstream()),
    {OEmpty, _, _} = scaffold(#{}),     %% input-independent: empty upstream → same outcome.
    KbSlugs = [maps:get(<<"slug">>, E) || E <- Kb],
    NullChecks =
        [check(<<"figure null at base: ", F/binary>>, g(O, F), null) || F <- null_at_base()],
    EmptyChecks =
        [check(<<"input-independent (empty upstream) null: ", F/binary>>, g(OEmpty, F), null)
         || F <- null_at_base()],
    [check("renderer = data-table", Rend, <<"data-table">>),
     check("outcome has exactly the eleven tax_optimised_structure fields",
           lists:sort(maps:keys(O)), lists:sort(fields())),
     %% the two KB-grounded CGT determinant CONSTANTS the disposition consumer reads.
     check("cgt_discount_eligible = true (resolver constant)",
           g(O, <<"cgt_discount_eligible">>), true),
     check("cost_base_depreciation_clawback = true (resolver constant → disposition to_verify)",
           g(O, <<"cost_base_depreciation_clawback">>), true),
     %% those two constants are input-independent too.
     check("cgt_discount_eligible constant on empty upstream",
           g(OEmpty, <<"cgt_discount_eligible">>), true),
     check("cost_base_depreciation_clawback constant on empty upstream",
           g(OEmpty, <<"cost_base_depreciation_clawback">>), true),
     check("recommended_entity null pre-merge (agent slot)",
           g(O, <<"recommended_entity">>), null),
     check("kb_versions = the six tax anchors",
           lists:sort(KbSlugs),
           lists:sort([<<"kb.tax.entity-comparison-personal-trust-company-smsf">>,
                       <<"kb.tax.negative-gearing-mechanics">>,
                       <<"kb.tax.depreciation-division-43-and-40">>,
                       <<"kb.tax.cgt-50-percent-discount">>,
                       <<"kb.tax.quantity-surveyor-reports">>,
                       <<"kb.tax.land-tax-by-state">>])),
     check("has_resolver true (classified as resolver, two-path)",
           fh_engine_fill:has_resolver(<<"tax_structure">>), true)]
    ++ NullChecks ++ EmptyChecks.

%% --- 2. Layer-1 conformance (the fail-closed commit seam) -------------------

layer1_cases() ->
    {O, _, _} = scaffold(upstream()),
    Merged = fh_engine_fill:merge_agent(<<"tax_structure">>, O,
                                        #{<<"recommended_entity">> => <<"personal_joint">>}),
    [check(<<"Layer-1 conforms: scaffold (nulls + bool constants)">>, validate(O), ok),
     check(<<"Layer-1 conforms: merged outcome (real entity folded)">>, validate(Merged), ok)].

validate(O) ->
    try fh_engine_outcome:validate(?INV, <<"tax_optimised_structure">>, O), ok
    catch _:Why -> {error, Why} end.

%% --- 3. two-path merge (the one entity leaf; §98 figure-tight) ---------------

two_path_cases() ->
    {O, _, _} = scaffold(upstream()),
    %% the agent reply carries the entity AND (adversarially) a stray figure key; merge_agent
    %% must fold ONLY recommended_entity and leave every resolver figure untouched (§98).
    Agent = #{<<"recommended_entity">> => <<"discretionary_trust">>,
              <<"setup_costs">> => 9999,            %% a figure the agent must NOT be able to set
              <<"cgt_discount_eligible">> => false}, %% a determinant the agent must NOT flip
    Merged = fh_engine_fill:merge_agent(<<"tax_structure">>, O, Agent),
    %% round-trip: recover the stored entity in the merge_agent-input shape.
    AV = fh_engine_fill:agent_values_from_outcome(
           <<"tax_structure">>,
           Merged#{<<"recommended_entity">> => <<"discretionary_trust">>}),
    [check("merge folds recommended_entity",
           g(Merged, <<"recommended_entity">>), <<"discretionary_trust">>),
     check("merge leaves cgt_discount_eligible untouched (§98 — agent can't flip a determinant)",
           g(Merged, <<"cgt_discount_eligible">>), true),
     check("merge leaves setup_costs null (§98 — agent can't author a figure)",
           g(Merged, <<"setup_costs">>), null),
     check("merge leaves cost_base_depreciation_clawback untouched",
           g(Merged, <<"cost_base_depreciation_clawback">>), true),
     check("merge does not add stray keys (field set unchanged)",
           lists:sort(maps:keys(Merged)), lists:sort(fields())),
     check("agent_values_from_outcome round-trips the entity",
           maps:get(<<"recommended_entity">>, AV), <<"discretionary_trust">>)].

%% --- 4. no regression --------------------------------------------------------

no_regression_cases() ->
    %% yield_modelling stays PURE-resolver: no merge clause (calling it errors).
    YmErrs = errors(fun() -> fh_engine_fill:merge_agent(<<"yield_modelling">>, #{}, #{}) end),
    %% investment_strategy (two-path) still dispatches resolver + merge.
    {SO, SRend, _} = fh_engine_fill:resolver(<<"investment_strategy">>, #{},
                                             #{<<"profile">> => #{<<"hold_horizon_years">> => 10}}),
    SM = fh_engine_fill:merge_agent(<<"investment_strategy">>, SO,
                                    #{<<"archetype">> => <<"balanced">>,
                                      <<"gearing_type">> => <<"neutral_geared">>,
                                      <<"one_liner">> => #{<<"vi">> => <<"x"/utf8>>,
                                                           <<"en">> => <<"y">>}}),
    [check("yield_modelling still pure-resolver (no merge → error)", YmErrs, true),
     check("investment_strategy resolver still dispatches (summary-card)", SRend, <<"summary-card">>),
     check("investment_strategy merge still folds archetype",
           maps:get(<<"archetype">>, SM), <<"balanced">>),
     check("investment_strategy has_resolver still true",
           fh_engine_fill:has_resolver(<<"investment_strategy">>), true)].

%% --- helpers ----------------------------------------------------------------

errors(F) ->
    try F(), false catch _:_ -> true end.

check(Label, Got, Want) ->
    case Got =:= Want of
        true  -> io:format("  PASS   ~ts~n", [Label]), pass;
        false -> io:format("  FAIL   ~ts = ~p, expected ~p~n", [Label, Got, Want]), fail
    end.
