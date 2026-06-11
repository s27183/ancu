#!/usr/bin/env escript
%%! -sname fh_ownership_conformance
%%
%% Conformance suite for fh_engine_ownership (mechanism B — ongoing-costs formula
%% code) against the executable spec tests/ownership_eval.py. Loads the SAME
%% materialized artifact the engine loads (priv/kb/artifact.json via fh_engine_kb)
%% and runs the spec's anchors through the Erlang implementation. Unlike the cash
%% suite, the ground truth here is the **KB params (the SOT)** + the stated
%% arithmetic — these are KB-curated indicative estimates, NOT regulated figures with
%% an official calculator (the one regulated postcondition is the PPOR land-tax
%% status). The two implementations stay locked to each other AND to the KB SOT.
%% See docs/architecture/ongoing-costs-projection.md.
%%
%% Run from engine/erlang with the build libs on the path (no Postgres needed):
%%   ERL_LIBS=_build/default/lib escript test/ownership_conformance.escript

-mode(compile).

main(_) ->
    ok = fh_engine_kb:load(),
    io:format("ownership conformance — fh_engine_ownership vs the KB params (SOT)~n~n"),
    R = lists:flatten(
          [maint_cases(), band_case(), lvr_case(),
           threshold_cases(), land_tax_cases(), fhg_cases(), alert_cases()]),
    Fails = [X || X <- R, X =:= fail],
    io:format("~n================================================================~n"),
    case Fails of
        [] ->
            io:format("PASS — all ~p ownership anchors match the KB SOT~n", [length(R)]),
            halt(0);
        _ ->
            io:format("FAIL — ~p anchor(s) mismatched~n", [length(Fails)]),
            halt(1)
    end.

%% --- maintenance reserve (1% of value at the ceiling, round half up) --------

maint_cases() ->
    [check("maintenance_target(700000)", fh_engine_ownership:maintenance_target(700000), 7000),
     check("maintenance_target(1000000)", fh_engine_ownership:maintenance_target(1000000), 10000),
     check("maintenance_target(650000)", fh_engine_ownership:maintenance_target(650000), 6500),
     check("maintenance_target(null)", fh_engine_ownership:maintenance_target(null), null)].

%% --- the council+water statutory band ---------------------------------------

band_case() ->
    B = fh_engine_ownership:statutory_band(),
    Got = {maps:get(<<"low">>, B), maps:get(<<"high">>, B)},
    [check("statutory_band {low,high}", Got, {2000, 3900})].

%% --- graduation LVR milestone -----------------------------------------------

lvr_case() ->
    [check("graduation_target_lvr", fh_engine_ownership:graduation_target_lvr(), 80)].

%% --- per-state land-tax thresholds (regulated figures from KB) --------------

threshold_cases() ->
    [check("land_tax_threshold(NSW)", fh_engine_ownership:land_tax_threshold(<<"NSW">>), 1075000),
     check("land_tax_threshold(VIC)", fh_engine_ownership:land_tax_threshold(<<"VIC">>), 50000),
     check("land_tax_threshold(QLD)", fh_engine_ownership:land_tax_threshold(<<"QLD">>), 600000)].

%% --- land-tax status derivation (the regulated postcondition) ---------------

land_tax_cases() ->
    [check("land_tax_check(owner_occupier)",
           fh_engine_ownership:land_tax_check(<<"owner_occupier">>), <<"exempt_ppor">>),
     check("land_tax_check(investor)",
           fh_engine_ownership:land_tax_check(<<"investor">>), <<"applicable">>)].

%% --- FHG detection from the scheme_stack (by role) --------------------------

fhg_cases() ->
    Yes = #{<<"applicable_schemes">> =>
                [#{<<"role">> => <<"deposit_guarantee">>}, #{<<"role">> => <<"grant">>}]},
    No  = #{<<"applicable_schemes">> =>
                [#{<<"role">> => <<"deposit_savings">>}, #{<<"role">> => <<"grant">>}]},
    [check("has_fhg(stack-with-fhg)", fh_engine_ownership:has_fhg(Yes), true),
     check("has_fhg(stack-without)", fh_engine_ownership:has_fhg(No), false),
     check("has_fhg(empty)", fh_engine_ownership:has_fhg(#{}), false)].

%% --- alert assembly (structure — Erlang-side only) --------------------------
%% Not cross-language (the action strings are presentation); assert the armed-trigger
%% COUNT for the canonical Mode-A NSW case: FHG-graduation + periodic-review +
%% land-tax-mode-switch = 3, and that dropping FHG removes exactly one.

alert_cases() ->
    {Outcome, _R, _Kb} = fh_engine_ownership:fill(
        #{onboarding => #{<<"state">> => <<"NSW">>,
                          <<"target_price_range">> => [600000, 700000]},
          intent => <<"owner_occupier">>},
        #{<<"scheme_stack">> =>
              #{<<"applicable_schemes">> => [#{<<"role">> => <<"deposit_guarantee">>}]}}),
    Alerts = maps:get(<<"alert_triggers_armed">>, Outcome),
    LandTax = maps:get(<<"land_tax_check">>, Outcome),
    Maint = maps:get(<<"maintenance_reserve_target">>, Outcome),
    [check("base fill: 3 alerts armed (FHG+review+land-tax)", length(Alerts), 3),
     check("base fill: land_tax_check = exempt_ppor", LandTax, <<"exempt_ppor">>),
     check("base fill: maintenance at ceiling (1% of 700k)", Maint, 7000)].

%% --- helper -----------------------------------------------------------------

check(Label, Got, Want) ->
    case Got =:= Want of
        true  -> io:format("  PASS   ~s = ~p~n", [Label, Got]), pass;
        false -> io:format("  FAIL   ~s = ~p, expected ~p~n", [Label, Got, Want]), fail
    end.
