#!/usr/bin/env escript
%%! -sname fh_base_components_nexthome_conformance
%%
%% Conformance suite for the Mode-E P5 base sequence (fh_engine_turn:base_components/1 —
%% the nexthome-domestic-au next-home spine, mode-e-wedge.md P5). Proves the wiring that
%% makes Mode-E cards LIVE: before this clause existed, an unknown blueprint slug fell
%% through to ?BASE_COMPONENTS (the Mode-A sequence), which SILENTLY DROPS
%% existing_home_disposal (order/2 filters to names present in the blueprint —
%% `eligibility` isn't one of nexthome-domestic-au's components) — the base turn would
%% have run without it, a genuine gap this clause closes.
%%
%% Loads the SAME materialized artifact the engine loads (priv/kb/artifact.json) and asserts:
%%   1. SET + ORDER — base_components(nexthome-domestic-au) is exactly the nine base/both-
%%      scope components in dependency order (a verbatim mirror of the Mode-A nine with
%%      `eligibility` swapped for `existing_home_disposal` in the SAME slot); the four
%%      per-property components are EXCLUDED.
%%   2. NO REGRESSION — base_components for fhb-domestic-au / investor-domestic-au /
%%      fhb-foreign-au / investor-foreign-au are all byte-identical (Modes A/B/C/D
%%      untouched by the new clause).
%%   3. DAG WALK — walking the nexthome order through fh_engine_fill:resolver/3,
%%      accumulating by outcome_type exactly as the turn does: every outcome validates
%%      against the nexthome-domestic-au registry; existing_home_disposal is present in
%%      upstream BEFORE cash_position runs (the real data dependency fill_fhb_nexthome/2
%%      needs); and cash_position's own MODE-E branch actually fired — not merely riding
%%      under the nexthome-domestic-au registry/order — proven by kb_versions EXCLUDING
%%      kb.scheme.fhg (fill_fhb_nexthome/2's own documented omission: a repeat buyer is
%%      never FHG-eligible), which fill_fhb/2 (Mode A) always includes. This signal is
%%      chosen over a null-value field check because every base-turn value on both sides
%%      is honestly null at base (no onboarding capture of the existing home's sale
%%      price) — kb_versions is the one signal that differs independent of user facts.
%%
%% Run from engine/erlang with the build libs on the path (no Postgres, no live model):
%%   ERL_LIBS=_build/default/lib escript test/base_components_nexthome_conformance.escript

-mode(compile).

-define(NEXTHOME, <<"nexthome-domestic-au">>).
-define(FHB, <<"fhb-domestic-au">>).
-define(INV, <<"investor-domestic-au">>).
-define(FHB_FOREIGN, <<"fhb-foreign-au">>).
-define(INV_FOREIGN, <<"investor-foreign-au">>).

main(_) ->
    ok = fh_engine_kb:load(),
    io:format("base_components nexthome conformance — fh_engine_turn:base_components/1 (Mode-E P5)~n~n"),
    R = lists:flatten([set_order_cases(), no_regression_cases(), dag_walk_cases()]),
    Fails = [X || X <- R, X =:= fail],
    io:format("~n================================================================~n"),
    case Fails of
        [] -> io:format("PASS — all ~p base_components_nexthome anchors hold~n", [length(R)]), halt(0);
        _  -> io:format("FAIL — ~p anchor(s) mismatched~n", [length(Fails)]), halt(1)
    end.

%% --- fixtures ----------------------------------------------------------------

nexthome_order() ->
    [<<"buyer_profile">>, <<"existing_home_disposal">>, <<"mortgage_finance">>,
     <<"cash_position">>, <<"ownership_planning">>, <<"disposition">>,
     <<"purchase_journey">>, <<"preparation">>, <<"phase_playbook">>].

fhb_order() ->
    [<<"buyer_profile">>, <<"eligibility">>, <<"mortgage_finance">>,
     <<"cash_position">>, <<"ownership_planning">>, <<"disposition">>,
     <<"purchase_journey">>, <<"preparation">>, <<"phase_playbook">>].

investor_order() ->
    [<<"investor_profile">>, <<"investment_strategy">>, <<"mortgage_finance">>,
     <<"yield_modelling">>, <<"tax_structure">>, <<"cash_position">>,
     <<"disposition">>, <<"ownership_planning_investor">>,
     <<"purchase_journey">>, <<"phase_playbook">>].

foreign_order() ->
    [<<"buyer_profile">>, <<"family_context">>, <<"firb_workflow">>,
     <<"mortgage_finance">>, <<"cash_position">>, <<"cross_border_funding">>,
     <<"ownership_planning">>].

foreign_investor_order() ->
    [<<"investor_profile_foreign">>, <<"firb_workflow">>, <<"investment_strategy">>,
     <<"mortgage_finance">>, <<"yield_modelling">>, <<"tax_structure_non_resident">>,
     <<"cash_position">>, <<"cross_border_funding">>,
     <<"ownership_planning_foreign_investor">>, <<"disposition">>].

per_property() ->
    [<<"property_assessment">>, <<"buying_strategy">>,
     <<"due_diligence">>, <<"settlement_prep">>].

names(Comps) -> [maps:get(<<"name">>, C) || C <- Comps].

%% Minimal turn Args — the base turn carries `onboarding` + `intent`; the deep facts
%% (existing home sale price, loan balance) are absent at base (honest-partial), exactly
%% as a real onboarding turn. `state` (not `target_zone`) is used so cash_position's
%% projection_state/1 resolves via the PURE explicit_state/1 branch (no-PG escript).
args() ->
    #{onboarding => #{<<"target_price_range">> => [900000, 1100000],
                      <<"state">> => <<"NSW">>},
      intent => <<"owner_occupier">>,
      blueprint_slug => ?NEXTHOME, mode => <<"E">>}.

%% --- 1. set + order ----------------------------------------------------------

set_order_cases() ->
    Comps = fh_engine_turn:base_components(?NEXTHOME),
    Got = names(Comps),
    Excluded = [N || N <- per_property(), lists:member(N, Got)],
    [check("nexthome base SET+ORDER = the nine-component Mode-E spine",
           Got, nexthome_order()),
     check("per-property components EXCLUDED from the nexthome base set",
           Excluded, []),
     check("every base component carries its outcome_type (DAG accumulator key)",
           lists:all(fun(C) -> is_binary(maps:get(<<"outcome_type">>, C, undefined)) end, Comps),
           true)].

%% --- 2. no regression (A/B/C/D unchanged) -------------------------------------

no_regression_cases() ->
    [check("FHB base SET+ORDER byte-identical to the Mode-A nine",
           names(fh_engine_turn:base_components(?FHB)), fhb_order()),
     check("Investor base SET+ORDER byte-identical to the Mode-C ten",
           names(fh_engine_turn:base_components(?INV)), investor_order()),
     check("Foreign-FHB base SET+ORDER byte-identical to the Mode-B seven",
           names(fh_engine_turn:base_components(?FHB_FOREIGN)), foreign_order()),
     check("Foreign-investor base SET+ORDER byte-identical to the Mode-D ten",
           names(fh_engine_turn:base_components(?INV_FOREIGN)), foreign_investor_order())].

%% --- 3. DAG walk (data availability + discriminator-firing proof) ------------

dag_walk_cases() ->
    Comps = fh_engine_turn:base_components(?NEXTHOME),
    {_Acc, Steps} = walk(args(), Comps),
    ValCases = [check(<<"validates vs nexthome-domestic-au registry: ", (maps:get(name, S))/binary>>,
                      validates(maps:get(ot, S), maps:get(outcome, S)), ok)
                || S <- Steps],
    CashStep = step(<<"cash_position">>, Steps),
    [check("existing_home_disposal present before cash_position runs (real data dependency)",
           lists:member(<<"existing_home_disposal">>, maps:get(pre_keys, CashStep)), true),
     check("cash_position's Mode-E branch fired: kb_versions excludes kb.scheme.fhg "
           "(fill_fhb_nexthome/2's own documented omission — a repeat buyer is never "
           "FHG-eligible; fill_fhb/2 always includes it)",
           lists:any(fun(V) -> maps:get(<<"slug">>, V, undefined) =:= <<"kb.scheme.fhg">> end,
                     maps:get(kb, CashStep)),
           false)
     | ValCases].

%% Walk the ordered components through the resolver, accumulating by outcome_type exactly
%% as fh_engine_turn does. Returns the final accumulator + the per-step record (run order),
%% keeping kb_versions per step too (the discriminator-firing proof needs it).
walk(Args, Comps) ->
    {Acc, RevSteps} =
        lists:foldl(
          fun(C, {A, Log}) ->
              Name = maps:get(<<"name">>, C),
              OT = maps:get(<<"outcome_type">>, C, Name),
              {O, _R, Kb} = fh_engine_fill:resolver(Name, Args, A),
              Step = #{name => Name, ot => OT, pre_keys => maps:keys(A), outcome => O, kb => Kb},
              {A#{OT => O}, [Step | Log]}
          end, {#{}, []}, Comps),
    {Acc, lists:reverse(RevSteps)}.

step(Name, Steps) ->
    hd([S || S <- Steps, maps:get(name, S) =:= Name]).

validates(OutcomeType, Outcome) ->
    try fh_engine_outcome:validate(?NEXTHOME, OutcomeType, Outcome)
    catch C:E -> {C, E} end.

%% --- helpers ----------------------------------------------------------------

check(Label, Got, Want) ->
    case Got =:= Want of
        true  -> io:format("  PASS   ~ts~n", [Label]), pass;
        false -> io:format("  FAIL   ~ts = ~p, expected ~p~n", [Label, Got, Want]), fail
    end.
