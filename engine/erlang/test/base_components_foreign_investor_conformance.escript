#!/usr/bin/env escript
%%! -sname fh_base_components_foreign_investor_conformance
%%
%% Conformance suite for the Mode-D P5 base sequence (fh_engine_turn:base_components/1 —
%% the investor-foreign-au foreign-investor spine, mode-d-wedge.md P5). Mirrors Mode-B's
%% own base_components_foreign_conformance.escript pattern (mode-b-wedge.md P5): proves the
%% wiring that makes Mode-D cards LIVE — the base SET + ORDER, that the ORDER makes genuine
%% data available before each component that reads it, and that the shared-name components
%% (mortgage_finance / cash_position) dispatch on the real discriminator, not merely on
%% being under the investor-foreign-au registry.
%%
%% Mode D's shared-name modules use the SAME compound discriminator as Mode B/C's own:
%% strategy_thesis-presence (investor axis) THEN Args.firb_required_any (foreign axis,
%% orthogonal) — fh_engine_mortgage.erl / fh_engine_cash.erl, unchanged by this wedge.
%% So this suite proves the same two things Mode-B's does:
%%   1. DATA availability — the order satisfies each component's real Upstream reads,
%%      grounded against the .erl source (fh_engine_turn.erl's macro comment), not just
%%      the blueprint's ASCII sketch (which itself omits mortgage_finance — see the
%%      blueprint's own note under the diagram).
%%   2. DISCRIMINATOR is load-bearing — walking the SAME order with firb_required_any=false
%%      (strategy_thesis still present) produces the MODE-C shapes instead (not just a
%%      different order), proving the flag drives the branch.
%%
%% Loads the SAME materialized artifact the engine loads (priv/kb/artifact.json) and asserts:
%%   1. SET + ORDER — base_components(investor-foreign-au) is exactly the ten components in
%%      the blueprint's own Scope=base/both column, in dependency order; the four
%%      per-property components are EXCLUDED.
%%   2. NO REGRESSION — base_components/1 for fhb-domestic-au / investor-domestic-au /
%%      fhb-foreign-au all byte-identical (Mode A/B/C untouched by the new clause).
%%   3. DAG WALK (firb_required_any=true) — walking the Mode-D order through
%%      fh_engine_fill:resolver/3, accumulating by outcome_type exactly as the turn does,
%%      every outcome validates against the investor-foreign-au registry AND each real data
%%      dependency (profile before firb_workflow/investment_strategy; firb_status +
%%      strategy_thesis before mortgage_finance; strategy_thesis before yield_modelling;
%%      cash_flow_projection before tax_structure_non_resident; firb_status +
%%      tax_optimised_structure before cash_position; budget_envelope_investor before
%%      cross_border_funding; tax_optimised_structure + cash_flow_projection before
%%      ownership_planning_foreign_investor; strategy_thesis + cash_flow_projection +
%%      tax_optimised_structure + budget_envelope_investor before disposition) is present
%%      in upstream before the component that reads it runs.
%%   4. DISCRIMINATOR LOAD-BEARING (firb_required_any=false) — the SAME order, same
%%      blueprint_slug, but the flag flipped: mortgage_finance/cash_position must produce
%%      the MODE-C (domestic investor) shapes (the Mode-D-only fields ABSENT), proving the
%%      flag drives the branch, not merely being under the investor-foreign-au registry/order.
%%
%% Run from engine/erlang with the build libs on the path (no Postgres, no live model):
%%   ERL_LIBS=_build/default/lib escript test/base_components_foreign_investor_conformance.escript

-mode(compile).

-define(FHB_FOREIGN_INV, <<"investor-foreign-au">>).
-define(FHB, <<"fhb-domestic-au">>).
-define(INV, <<"investor-domestic-au">>).
-define(FHB_FOREIGN, <<"fhb-foreign-au">>).

main(_) ->
    ok = fh_engine_kb:load(),
    io:format("base_components foreign-investor conformance — fh_engine_turn:base_components/1 (Mode-D P5)~n~n"),
    R = lists:flatten([set_order_cases(), no_regression_cases(), dag_walk_cases(),
                       discriminator_cases()]),
    Fails = [X || X <- R, X =:= fail],
    io:format("~n================================================================~n"),
    case Fails of
        [] -> io:format("PASS — all ~p base_components_foreign_investor anchors hold~n", [length(R)]), halt(0);
        _  -> io:format("FAIL — ~p anchor(s) mismatched~n", [length(Fails)]), halt(1)
    end.

%% --- fixtures ----------------------------------------------------------------

foreign_investor_order() ->
    [<<"investor_profile_foreign">>, <<"firb_workflow">>, <<"investment_strategy">>,
     <<"mortgage_finance">>, <<"yield_modelling">>, <<"tax_structure_non_resident">>,
     <<"cash_position">>, <<"cross_border_funding">>,
     <<"ownership_planning_foreign_investor">>, <<"disposition">>].

fhb_order() ->
    [<<"buyer_profile">>, <<"eligibility">>, <<"mortgage_finance">>,
     <<"cash_position">>, <<"ownership_planning">>, <<"disposition">>,
     <<"purchase_journey">>, <<"preparation">>, <<"phase_playbook">>].

investor_order() ->
    [<<"investor_profile">>, <<"investment_strategy">>, <<"mortgage_finance">>,
     <<"yield_modelling">>, <<"tax_structure">>, <<"cash_position">>,
     <<"disposition">>, <<"ownership_planning_investor">>].

foreign_order() ->
    [<<"buyer_profile">>, <<"family_context">>, <<"firb_workflow">>,
     <<"mortgage_finance">>, <<"cash_position">>, <<"cross_border_funding">>,
     <<"ownership_planning">>].

per_property() ->
    [<<"property_assessment">>, <<"buying_strategy">>,
     <<"due_diligence">>, <<"settlement_prep">>].

names(Comps) -> [maps:get(<<"name">>, C) || C <- Comps].

%% Minimal turn Args — the base turn carries `onboarding` + `intent` + `firb_required_any`;
%% the deep facts (financials, visa/tax details) are absent at base (honest-partial), exactly
%% as a real onboarding turn. `state` (not `target_zone`) is used so cash_position's
%% projection_state/1 resolves via the PURE explicit_state/1 branch (mirrors
%% base_components_foreign_conformance.escript's own no-PG fixture convention).
args(FirbRequiredAny) ->
    #{onboarding => #{<<"target_price_range">> => [600000, 800000],
                      <<"hold_horizon_years">> => 10,
                      <<"state">> => <<"NSW">>},
      intent => <<"investment">>,
      blueprint_slug => ?FHB_FOREIGN_INV, mode => <<"D">>,
      firb_required_any => FirbRequiredAny}.

%% --- 1. set + order ----------------------------------------------------------

set_order_cases() ->
    Comps = fh_engine_turn:base_components(?FHB_FOREIGN_INV),
    Got = names(Comps),
    Excluded = [N || N <- per_property(), lists:member(N, Got)],
    [check("foreign-investor base SET+ORDER = the ten-component Mode-D spine",
           Got, foreign_investor_order()),
     check("per-property components EXCLUDED from the foreign-investor base set",
           Excluded, []),
     check("every base component carries its outcome_type (DAG accumulator key)",
           lists:all(fun(C) -> is_binary(maps:get(<<"outcome_type">>, C, undefined)) end, Comps),
           true)].

%% --- 2. no regression (A/B/C unchanged) ---------------------------------------

no_regression_cases() ->
    [check("FHB base SET+ORDER byte-identical to the Mode-A nine",
           names(fh_engine_turn:base_components(?FHB)), fhb_order()),
     check("Investor base SET+ORDER byte-identical to the Mode-C eight",
           names(fh_engine_turn:base_components(?INV)), investor_order()),
     check("Foreign-FHB base SET+ORDER byte-identical to the Mode-B seven",
           names(fh_engine_turn:base_components(?FHB_FOREIGN)), foreign_order())].

%% --- 3. DAG walk (firb_required_any=true — the real Mode-D turn) -------------

dag_walk_cases() ->
    Comps = fh_engine_turn:base_components(?FHB_FOREIGN_INV),
    {_Acc, Steps} = walk(args(true), Comps),
    ValCases = [check(<<"validates vs investor-foreign-au registry: ", (maps:get(name, S))/binary>>,
                      validates(maps:get(ot, S), maps:get(outcome, S)), ok)
                || S <- Steps],
    Pre = fun(Name, Key) ->
              S = step(Name, Steps),
              check(<<Key/binary, " present before ", Name/binary, " runs (real data dependency)">>,
                    lists:member(Key, maps:get(pre_keys, S)), true)
          end,
    [Pre(<<"firb_workflow">>, <<"profile">>),
     Pre(<<"investment_strategy">>, <<"profile">>),
     Pre(<<"mortgage_finance">>, <<"firb_status">>),
     Pre(<<"mortgage_finance">>, <<"strategy_thesis">>),
     Pre(<<"yield_modelling">>, <<"strategy_thesis">>),
     Pre(<<"tax_structure_non_resident">>, <<"cash_flow_projection">>),
     Pre(<<"cash_position">>, <<"firb_status">>),
     Pre(<<"cash_position">>, <<"tax_optimised_structure">>),
     Pre(<<"cross_border_funding">>, <<"budget_envelope_investor">>),
     Pre(<<"ownership_planning_foreign_investor">>, <<"tax_optimised_structure">>),
     Pre(<<"ownership_planning_foreign_investor">>, <<"cash_flow_projection">>),
     Pre(<<"disposition">>, <<"strategy_thesis">>),
     Pre(<<"disposition">>, <<"cash_flow_projection">>),
     Pre(<<"disposition">>, <<"tax_optimised_structure">>),
     Pre(<<"disposition">>, <<"budget_envelope_investor">>)
     | ValCases].

%% --- 4. discriminator load-bearing (SAME order, firb_required_any=false) -----
%% Not merely re-checking order — this proves the FLAG drives the branch. The same ten
%% components, same investor-foreign-au slug/order/registry, but with the flag flipped:
%% mortgage_finance/cash_position (both key on strategy_thesis-presence THEN
%% Args.firb_required_any) must now produce the MODE-C (domestic investor) shapes — their
%% Mode-D-only fields absent — because the branch reads Args.firb_required_any, not
%% blueprint_slug or component order.

discriminator_cases() ->
    Comps = fh_engine_turn:base_components(?FHB_FOREIGN_INV),
    {_Acc, Steps} = walk(args(false), Comps),
    Mortgage = maps:get(outcome, step(<<"mortgage_finance">>, Steps)),
    Cash = maps:get(outcome, step(<<"cash_position">>, Steps)),
    [check("firb_required_any=false: mortgage_finance drops the Mode-D-only field",
           maps:is_key(<<"firb_dependency_acknowledged">>, Mortgage), false),
     check("firb_required_any=false: cash_position drops the Mode-D-only field",
           maps:is_key(<<"regulatory_imposts_total">>, Cash), false)].

%% Walk the ordered components through the resolver, accumulating by outcome_type exactly
%% as fh_engine_turn does. Returns the final accumulator + the per-step record (run order).
walk(Args, Comps) ->
    {Acc, RevSteps} =
        lists:foldl(
          fun(C, {A, Log}) ->
              Name = maps:get(<<"name">>, C),
              OT = maps:get(<<"outcome_type">>, C, Name),
              {O, _R, _K} = fh_engine_fill:resolver(Name, Args, A),
              Step = #{name => Name, ot => OT, pre_keys => maps:keys(A), outcome => O},
              {A#{OT => O}, [Step | Log]}
          end, {#{}, []}, Comps),
    {Acc, lists:reverse(RevSteps)}.

step(Name, Steps) ->
    hd([S || S <- Steps, maps:get(name, S) =:= Name]).

validates(OutcomeType, Outcome) ->
    try fh_engine_outcome:validate(?FHB_FOREIGN_INV, OutcomeType, Outcome)
    catch C:E -> {C, E} end.

%% --- helpers ----------------------------------------------------------------

check(Label, Got, Want) ->
    case Got =:= Want of
        true  -> io:format("  PASS   ~ts~n", [Label]), pass;
        false -> io:format("  FAIL   ~ts = ~p, expected ~p~n", [Label, Got, Want]), fail
    end.
