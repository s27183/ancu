#!/usr/bin/env escript
%%! -sname fh_base_components_investor_conformance
%%
%% Conformance suite for the P5-activate per-blueprint base sequence
%% (fh_engine_turn:base_components/1 — the Mode-C investor spine). Proves the wiring that
%% makes investor cards LIVE: the investor base SET + ORDER, and — the real new risk — that
%% the ORDER makes the three shared-name modules (mortgage_finance / cash_position /
%% disposition) fire their INVESTOR branch. Those modules discriminate by sniffing the
%% accumulated upstream (keyed by outcome_type), so a component must run AFTER the one
%% producing its discriminating outcome or it would silently take the FHB branch.
%%
%% Loads the SAME materialized artifact the engine loads (priv/kb/artifact.json) and asserts:
%%   1. SET + ORDER — base_components(investor-domestic-au) is exactly the eight property-
%%      AGNOSTIC investor components in the discriminator-respecting order; the four
%%      per-property components (property_assessment, buying_strategy, due_diligence,
%%      settlement_prep) are EXCLUDED.
%%   2. NO REGRESSION — base_components(fhb-domestic-au) is byte-identical to the Mode-A nine.
%%   3. DAG WALK — walking the investor order through fh_engine_fill:resolver/3, accumulating
%%      by outcome_type exactly as the turn does, every outcome validates against the investor
%%      registry AND the discriminating key is present in the upstream BEFORE each shared-name
%%      component runs (strategy_thesis before mortgage_finance; tax_optimised_structure before
%%      cash_position and disposition; budget_envelope_investor before disposition) — so each
%%      produces its INVESTOR shape (io_vs_pi_recommendation / lmi_payable / taxable_gain).
%%
%% Run from engine/erlang with the build libs on the path (no Postgres, no live model):
%%   ERL_LIBS=_build/default/lib escript test/base_components_investor_conformance.escript

-mode(compile).

-define(INV, <<"investor-domestic-au">>).
-define(FHB, <<"fhb-domestic-au">>).

main(_) ->
    ok = fh_engine_kb:load(),
    io:format("base_components investor conformance — fh_engine_turn:base_components/1 (P5-activate)~n~n"),
    R = lists:flatten([set_order_cases(), no_regression_cases(), dag_walk_cases()]),
    Fails = [X || X <- R, X =:= fail],
    io:format("~n================================================================~n"),
    case Fails of
        [] -> io:format("PASS — all ~p base_components_investor anchors hold~n", [length(R)]), halt(0);
        _  -> io:format("FAIL — ~p anchor(s) mismatched~n", [length(Fails)]), halt(1)
    end.

%% --- fixtures ----------------------------------------------------------------

investor_order() ->
    [<<"investor_profile">>, <<"investment_strategy">>, <<"mortgage_finance">>,
     <<"yield_modelling">>, <<"tax_structure">>, <<"cash_position">>,
     <<"ownership_planning_investor">>, <<"disposition">>].

fhb_order() ->
    [<<"buyer_profile">>, <<"eligibility">>, <<"mortgage_finance">>,
     <<"cash_position">>, <<"ownership_planning">>, <<"disposition">>,
     <<"purchase_journey">>, <<"preparation">>, <<"phase_playbook">>].

per_property() ->
    [<<"property_assessment">>, <<"buying_strategy">>,
     <<"due_diligence">>, <<"settlement_prep">>].

names(Comps) -> [maps:get(<<"name">>, C) || C <- Comps].

%% Minimal turn Args — the base turn carries `onboarding` + `intent`; the deep facts are
%% absent at base (honest-partial), exactly as a real onboarding turn.
args() -> #{onboarding => #{}, intent => <<"investment">>,
            blueprint_slug => ?INV, mode => <<"C">>}.

%% --- 1. set + order ----------------------------------------------------------

set_order_cases() ->
    Comps = fh_engine_turn:base_components(?INV),
    Got = names(Comps),
    Excluded = [N || N <- per_property(), lists:member(N, Got)],
    [check("investor base SET+ORDER = the eight-component investor spine",
           Got, investor_order()),
     check("per-property components EXCLUDED from the investor base set",
           Excluded, []),
     check("every base component carries its outcome_type (DAG accumulator key)",
           lists:all(fun(C) -> is_binary(maps:get(<<"outcome_type">>, C, undefined)) end, Comps),
           true)].

%% --- 2. no regression (fhb unchanged) ----------------------------------------

no_regression_cases() ->
    Got = names(fh_engine_turn:base_components(?FHB)),
    [check("FHB base SET+ORDER byte-identical to the Mode-A nine", Got, fhb_order())].

%% --- 3. DAG walk (the discriminator-firing proof) ----------------------------

dag_walk_cases() ->
    Comps = fh_engine_turn:base_components(?INV),
    {_Acc, Steps} = walk(args(), Comps),   %% Steps in run order
    %% Every accumulated outcome validates against the INVESTOR registry.
    ValCases = [check(<<"validates vs investor registry: ", (maps:get(name, S))/binary>>,
                      validates(maps:get(ot, S), maps:get(outcome, S)), ok)
                || S <- Steps],
    %% The discriminating key is present in the upstream BEFORE each shared-name component.
    Pre = fun(Name, Key) ->
              S = step(Name, Steps),
              check(<<Key/binary, " present before ", Name/binary, " runs (order is load-bearing)">>,
                    lists:member(Key, maps:get(pre_keys, S)), true)
          end,
    %% Each shared-name component produced its INVESTOR shape (a field absent from the FHB twin).
    Shape = fun(Name, Key) ->
                S = step(Name, Steps),
                check(<<Name/binary, " produced INVESTOR shape (", Key/binary, ")">>,
                      maps:is_key(Key, maps:get(outcome, S)), true)
            end,
    [Pre(<<"mortgage_finance">>, <<"strategy_thesis">>),
     Pre(<<"cash_position">>, <<"tax_optimised_structure">>),
     Pre(<<"disposition">>, <<"tax_optimised_structure">>),
     Pre(<<"disposition">>, <<"budget_envelope_investor">>),
     Shape(<<"mortgage_finance">>, <<"io_vs_pi_recommendation">>),
     Shape(<<"cash_position">>, <<"lmi_payable">>),
     Shape(<<"disposition">>, <<"taxable_gain">>)
     | ValCases].

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
    try fh_engine_outcome:validate(?INV, OutcomeType, Outcome)
    catch C:E -> {C, E} end.

%% --- helpers ----------------------------------------------------------------

check(Label, Got, Want) ->
    case Got =:= Want of
        true  -> io:format("  PASS   ~ts~n", [Label]), pass;
        false -> io:format("  FAIL   ~ts = ~p, expected ~p~n", [Label, Got, Want]), fail
    end.
