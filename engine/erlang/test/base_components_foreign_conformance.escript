#!/usr/bin/env escript
%%! -sname fh_base_components_foreign_conformance
%%
%% Conformance suite for the Mode-B P5-activate base sequence
%% (fh_engine_turn:base_components/1 — the fhb-foreign-au foreign spine, mode-b-wedge.md
%% P5). Proves the wiring that makes Mode-B cards LIVE: the foreign base SET + ORDER, and
%% — the real new risk — that the ORDER makes genuine data available before each
%% component that reads it.
%%
%% Mode-B's three shared-name modules (mortgage_finance / cash_position / ownership_planning)
%% do NOT sniff upstream outcome-type presence the way Mode C's do — they key on
%% Args.firb_required_any, a turn-level flag set once at turn start (mode-b-wedge.md P2).
%% So this suite proves TWO different things, not one:
%%   1. DATA availability — the order satisfies each component's real Upstream reads
%%      (grounded against the .erl source, not just the blueprint's declared Inputs prose,
%%      which diverges from code in two places — see fh_engine_turn.erl's macro comment).
%%   2. DISCRIMINATOR is load-bearing — walking the SAME order with firb_required_any=false
%%      produces the MODE-A shapes instead (not just a different order), proving the flag,
%%      not the blueprint_slug/order alone, drives which branch fires.
%%
%% Loads the SAME materialized artifact the engine loads (priv/kb/artifact.json) and asserts:
%%   1. SET + ORDER — base_components(fhb-foreign-au) is exactly the seven components in
%%      the blueprint's own Scope=base/both column, in dependency order; the four
%%      per-property components are EXCLUDED.
%%   2. NO REGRESSION — base_components(fhb-domestic-au) / base_components(investor-domestic-au)
%%      byte-identical (Mode A/C untouched by the new clause).
%%   3. DAG WALK (firb_required_any=true) — walking the foreign order through
%%      fh_engine_fill:resolver/3, accumulating by outcome_type exactly as the turn does,
%%      every outcome validates against the fhb-foreign-au registry AND each real data
%%      dependency (firb_status+mortgage_plan before cash_position; profile before
%%      family_context/firb_workflow/mortgage_finance; family_funding_plan before
%%      cross_border_funding; firb_status before ownership_planning) is present in upstream
%%      before the component that reads it runs.
%%   4. DISCRIMINATOR LOAD-BEARING (firb_required_any=false) — the SAME order, same
%%      blueprint_slug, but the flag flipped: the three shared-name branches produce the
%%      MODE-A shapes (the Mode-B-unique fields are ABSENT), proving the flag drives the
%%      branch, not merely being under the fhb-foreign-au registry/order.
%%
%% Run from engine/erlang with the build libs on the path (no Postgres, no live model):
%%   ERL_LIBS=_build/default/lib escript test/base_components_foreign_conformance.escript

-mode(compile).

-define(FHB_FOREIGN, <<"fhb-foreign-au">>).
-define(FHB, <<"fhb-domestic-au">>).
-define(INV, <<"investor-domestic-au">>).

main(_) ->
    ok = fh_engine_kb:load(),
    io:format("base_components foreign conformance — fh_engine_turn:base_components/1 (Mode-B P5)~n~n"),
    R = lists:flatten([set_order_cases(), no_regression_cases(), dag_walk_cases(),
                       discriminator_cases()]),
    Fails = [X || X <- R, X =:= fail],
    io:format("~n================================================================~n"),
    case Fails of
        [] -> io:format("PASS — all ~p base_components_foreign anchors hold~n", [length(R)]), halt(0);
        _  -> io:format("FAIL — ~p anchor(s) mismatched~n", [length(Fails)]), halt(1)
    end.

%% --- fixtures ----------------------------------------------------------------

foreign_order() ->
    [<<"buyer_profile">>, <<"family_context">>, <<"firb_workflow">>,
     <<"mortgage_finance">>, <<"cash_position">>, <<"cross_border_funding">>,
     <<"ownership_planning">>].

fhb_order() ->
    [<<"buyer_profile">>, <<"eligibility">>, <<"mortgage_finance">>,
     <<"cash_position">>, <<"ownership_planning">>, <<"disposition">>,
     <<"purchase_journey">>, <<"preparation">>, <<"phase_playbook">>].

investor_order() ->
    [<<"investor_profile">>, <<"investment_strategy">>, <<"mortgage_finance">>,
     <<"yield_modelling">>, <<"tax_structure">>, <<"cash_position">>,
     <<"disposition">>, <<"ownership_planning_investor">>].

per_property() ->
    [<<"property_assessment">>, <<"buying_strategy">>,
     <<"due_diligence">>, <<"settlement_prep">>].

names(Comps) -> [maps:get(<<"name">>, C) || C <- Comps].

%% Minimal turn Args — the base turn carries `onboarding` + `intent` + `firb_required_any`;
%% the deep facts (income, visa_class) are absent at base (honest-partial), exactly as a
%% real onboarding turn. `state` (not `target_zone`) is used so cash_position's
%% projection_state/1 resolves via the PURE explicit_state/1 branch — target_zone
%% resolves via a suburbs-table DB lookup (zone_state/1), unavailable to this no-PG
%% escript (fh_engine_store.erl's own doc comment on projection_state/1).
args(FirbRequiredAny) ->
    #{onboarding => #{<<"target_price_range">> => [700000, 900000],
                      <<"state">> => <<"NSW">>},
      intent => <<"owner_occupier">>,
      blueprint_slug => ?FHB_FOREIGN, mode => <<"B">>,
      firb_required_any => FirbRequiredAny}.

%% --- 1. set + order ----------------------------------------------------------

set_order_cases() ->
    Comps = fh_engine_turn:base_components(?FHB_FOREIGN),
    Got = names(Comps),
    Excluded = [N || N <- per_property(), lists:member(N, Got)],
    [check("foreign base SET+ORDER = the seven-component Mode-B spine",
           Got, foreign_order()),
     check("per-property components EXCLUDED from the foreign base set",
           Excluded, []),
     check("every base component carries its outcome_type (DAG accumulator key)",
           lists:all(fun(C) -> is_binary(maps:get(<<"outcome_type">>, C, undefined)) end, Comps),
           true)].

%% --- 2. no regression (fhb + investor unchanged) ------------------------------

no_regression_cases() ->
    [check("FHB base SET+ORDER byte-identical to the Mode-A nine",
           names(fh_engine_turn:base_components(?FHB)), fhb_order()),
     check("Investor base SET+ORDER byte-identical to the Mode-C eight",
           names(fh_engine_turn:base_components(?INV)), investor_order())].

%% --- 3. DAG walk (firb_required_any=true — the real Mode-B turn) -------------

dag_walk_cases() ->
    Comps = fh_engine_turn:base_components(?FHB_FOREIGN),
    {_Acc, Steps} = walk(args(true), Comps),
    ValCases = [check(<<"validates vs fhb-foreign-au registry: ", (maps:get(name, S))/binary>>,
                      validates(maps:get(ot, S), maps:get(outcome, S)), ok)
                || S <- Steps],
    Pre = fun(Name, Key) ->
              S = step(Name, Steps),
              check(<<Key/binary, " present before ", Name/binary, " runs (real data dependency)">>,
                    lists:member(Key, maps:get(pre_keys, S)), true)
          end,
    [Pre(<<"family_context">>, <<"profile">>),
     Pre(<<"firb_workflow">>, <<"profile">>),
     Pre(<<"mortgage_finance">>, <<"profile">>),
     Pre(<<"cash_position">>, <<"firb_status">>),
     Pre(<<"cash_position">>, <<"mortgage_plan">>),
     Pre(<<"cross_border_funding">>, <<"family_funding_plan">>),
     Pre(<<"ownership_planning">>, <<"firb_status">>)
     | ValCases].

%% --- 4. discriminator load-bearing (SAME order, firb_required_any=false) -----
%% Not merely re-checking order — this proves the FLAG drives the branch. The same seven
%% components, same fhb-foreign-au slug/order/registry, but with the flag flipped: the
%% three shared-name modules must now produce the MODE-A shapes (their Mode-B-unique
%% fields absent), because they key on Args.firb_required_any, not on blueprint_slug or
%% component order.

discriminator_cases() ->
    Comps = fh_engine_turn:base_components(?FHB_FOREIGN),
    {_Acc, Steps} = walk(args(false), Comps),
    Profile = maps:get(outcome, step(<<"buyer_profile">>, Steps)),
    Mortgage = maps:get(outcome, step(<<"mortgage_finance">>, Steps)),
    Cash = maps:get(outcome, step(<<"cash_position">>, Steps)),
    Ownership = maps:get(outcome, step(<<"ownership_planning">>, Steps)),
    [check("firb_required_any=false: buyer_profile's own household flag flips",
           maps:get(<<"firb_required_any">>, Profile), false),
     check("firb_required_any=false: mortgage_finance drops the Mode-B-only field",
           maps:is_key(<<"firb_dependency_acknowledged">>, Mortgage), false),
     check("firb_required_any=false: cash_position drops the Mode-B-only field",
           maps:is_key(<<"regulatory_imposts_total">>, Cash), false),
     check("firb_required_any=false: ownership_planning drops the Mode-B-only field",
           maps:is_key(<<"vacancy_fee_at_risk_amount">>, Ownership), false)].

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
    try fh_engine_outcome:validate(?FHB_FOREIGN, OutcomeType, Outcome)
    catch C:E -> {C, E} end.

%% --- helpers ----------------------------------------------------------------

check(Label, Got, Want) ->
    case Got =:= Want of
        true  -> io:format("  PASS   ~ts~n", [Label]), pass;
        false -> io:format("  FAIL   ~ts = ~p, expected ~p~n", [Label, Got, Want]), fail
    end.
