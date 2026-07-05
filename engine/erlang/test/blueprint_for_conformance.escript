#!/usr/bin/env escript
%%! -sname fh_blueprint_for_conformance
%%
%% Conformance suite for fh_engine_h_plan_cards:blueprint_for/3 — the full three-axis
%% onboarding dispatch (intent × foreign × buyer_stage, mode-e-wedge.md P5). Proves the
%% complete truth table from fact-model-unification.md's "Mode is derived — three axes":
%%
%%                     owner_occupier                          investment
%%               first_home      next_home
%%   domestic         A              E                             C
%%   foreign           B      unsupported_combination               D
%%
%% plus `stage_of/1`'s FAIL-CLOSED defaulting for owner_occupier (absent/malformed
%% buyer_stage resolves to `undefined`, and blueprint_for/3 rejects it with 400
%% missing_buyer_stage — reread from the scoping decision's "never inferred or defaulted
%% to first_home": a silent next_home default was found, during this same P5 phase, to
%% silently misroute the flagship domestic-first-home audience whenever a caller omitted
%% the field — e.g. seam_smoke.escript, which predates buyer_stage — so "never defaulted"
%% is read here as "required", not "defaulted to the safer-sounding value"; investment
%% stays fully stage-agnostic, costing those callers nothing) and full no-regression on
%% the pre-existing two-axis blueprint_for/2 behaviour now that a third parameter has been
%% threaded through.
%%
%% Pure — no Postgres, no artifact load, just the exported dispatch functions. Run from
%% engine/erlang with the build libs on the path:
%%   ERL_LIBS=_build/default/lib escript test/blueprint_for_conformance.escript

-mode(compile).

main(_) ->
    io:format("blueprint_for/3 conformance — fh_engine_h_plan_cards (mode-e-wedge.md P5)~n~n"),
    R = lists:flatten([truth_table_cases(), stage_default_cases(), foreign_default_cases(),
                        intent_default_cases()]),
    Fails = [X || X <- R, X =:= fail],
    io:format("~n================================================================~n"),
    case Fails of
        [] -> io:format("PASS — all ~p blueprint_for anchors hold~n", [length(R)]), halt(0);
        _  -> io:format("FAIL — ~p anchor(s) mismatched~n", [length(Fails)]), halt(1)
    end.

%% --- 1. the full truth table --------------------------------------------------

truth_table_cases() ->
    [check("domestic + owner_occupier + first_home = Mode A",
           fh_engine_h_plan_cards:blueprint_for(<<"owner_occupier">>, false, <<"first_home">>),
           {<<"fhb-domestic-au">>, <<"A">>}),
     check("domestic + owner_occupier + next_home = Mode E",
           fh_engine_h_plan_cards:blueprint_for(<<"owner_occupier">>, false, <<"next_home">>),
           {<<"nexthome-domestic-au">>, <<"E">>}),
     check("domestic + investment (stage irrelevant, first_home) = Mode C",
           fh_engine_h_plan_cards:blueprint_for(<<"investment">>, false, <<"first_home">>),
           {<<"investor-domestic-au">>, <<"C">>}),
     check("domestic + investment (stage irrelevant, next_home) = Mode C",
           fh_engine_h_plan_cards:blueprint_for(<<"investment">>, false, <<"next_home">>),
           {<<"investor-domestic-au">>, <<"C">>}),
     check("foreign + owner_occupier + first_home = Mode B",
           fh_engine_h_plan_cards:blueprint_for(<<"owner_occupier">>, true, <<"first_home">>),
           {<<"fhb-foreign-au">>, <<"B">>}),
     check("foreign + owner_occupier + next_home = unsupported (Mode-E gap's foreign twin, "
           "decision #4 — now an ENGINE-level fail-closed, not just shell-gated)",
           fh_engine_h_plan_cards:blueprint_for(<<"owner_occupier">>, true, <<"next_home">>),
           {error, unsupported_combination}),
     check("foreign + investment (stage irrelevant, first_home) = Mode D",
           fh_engine_h_plan_cards:blueprint_for(<<"investment">>, true, <<"first_home">>),
           {<<"investor-foreign-au">>, <<"D">>}),
     check("foreign + investment (stage irrelevant, next_home) = Mode D",
           fh_engine_h_plan_cards:blueprint_for(<<"investment">>, true, <<"next_home">>),
           {<<"investor-foreign-au">>, <<"D">>}),
     check("foreign + investment (stage irrelevant, UNDEFINED — investment ignores stage "
           "entirely, so this is not the missing-buyer_stage cell) = Mode D",
           fh_engine_h_plan_cards:blueprint_for(<<"investment">>, true, undefined),
           {<<"investor-foreign-au">>, <<"D">>}),
     check("domestic + investment (stage irrelevant, UNDEFINED) = Mode C",
           fh_engine_h_plan_cards:blueprint_for(<<"investment">>, false, undefined),
           {<<"investor-domestic-au">>, <<"C">>}),
     check("domestic + owner_occupier + UNDEFINED buyer_stage fails closed "
           "(missing_buyer_stage, not a guessed mode)",
           fh_engine_h_plan_cards:blueprint_for(<<"owner_occupier">>, false, undefined),
           {error, missing_buyer_stage}),
     check("foreign + owner_occupier + UNDEFINED buyer_stage fails closed "
           "(missing_buyer_stage, not a guessed mode)",
           fh_engine_h_plan_cards:blueprint_for(<<"owner_occupier">>, true, undefined),
           {error, missing_buyer_stage})].

%% --- 2. stage_of/1 defaulting (fail-closed, not fail-open) --------------------
%% mode-e-wedge.md: absent/malformed buyer_stage must NEVER silently resolve to
%% first_home (a repeat buyer wrongly shown FHG/FHSS entitlement). Read here as
%% "required", not "defaulted to the other value" — a silent next_home default was found,
%% during this same phase, to silently misroute the flagship domestic-first-home audience
%% (seam_smoke.escript predates buyer_stage and sends none) — so stage_of/1 resolves
%% absent/malformed input to `undefined`, and blueprint_for/3's owner_occupier clauses
%% reject `undefined` outright (see truth_table_cases above) rather than guess either way.

stage_default_cases() ->
    [check("stage_of/1: absent buyer_stage resolves to undefined (neither value guessed)",
           fh_engine_h_plan_cards:stage_of(#{}), undefined),
     check("stage_of/1: malformed buyer_stage resolves to undefined",
           fh_engine_h_plan_cards:stage_of(#{<<"buyer_stage">> => <<"garbage">>}), undefined),
     check("stage_of/1: explicit first_home is honored",
           fh_engine_h_plan_cards:stage_of(#{<<"buyer_stage">> => <<"first_home">>}), <<"first_home">>),
     check("stage_of/1: explicit next_home is honored",
           fh_engine_h_plan_cards:stage_of(#{<<"buyer_stage">> => <<"next_home">>}), <<"next_home">>)].

%% --- 3. foreign_of/1 defaulting (no regression — the safe LESS-claims direction) ----

foreign_default_cases() ->
    [check("foreign_of/1: absent foreign_person degrades to false (domestic)",
           fh_engine_h_plan_cards:foreign_of(#{}), false),
     check("foreign_of/1: non-boolean foreign_person degrades to false",
           fh_engine_h_plan_cards:foreign_of(#{<<"foreign_person">> => <<"yes">>}), false),
     check("foreign_of/1: explicit true is honored",
           fh_engine_h_plan_cards:foreign_of(#{<<"foreign_person">> => true}), true)].

%% --- 4. intent_of/1 defaulting (no regression) --------------------------------

intent_default_cases() ->
    [check("intent_of/1: absent intent degrades to owner_occupier",
           fh_engine_h_plan_cards:intent_of(#{}), <<"owner_occupier">>),
     check("intent_of/1: explicit investment is honored",
           fh_engine_h_plan_cards:intent_of(#{<<"intent">> => <<"investment">>}), <<"investment">>)].

%% --- helpers ----------------------------------------------------------------

check(Label, Got, Want) ->
    case Got =:= Want of
        true  -> io:format("  PASS   ~ts~n", [Label]), pass;
        false -> io:format("  FAIL   ~ts = ~p, expected ~p~n", [Label, Got, Want]), fail
    end.
