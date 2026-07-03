#!/usr/bin/env escript
%%! -sname fh_mode_b_p3_scope_conformance
%%
%% Mode-B wedge P3 — the compiler flip + per-card multi-blueprint runtime proof
%% (mode-b-wedge.md P3: "Add fhb-foreign-au to IN_SCOPE_BLUEPRINTS; green semantic
%% gates; re-emit artifact; prove per-card selection (A/C unchanged)"). The
%% per-card multi-blueprint MACHINERY already exists (Mode-C wedge P3, commit
%% e9620be) — fh_engine_kb:registry/1,2 + in_scope_blueprints/0 and
%% fh_engine_outcome:validate/3 already key on a blueprint_slug argument, built
%% generically for an N-blueprint in-scope SET, not hardcoded to two. So THIS
%% escript is the flip's proof, not new machinery: every one of the six P2
%% Mode-B resolver outputs (fh_engine_fill:resolver/3, same fixtures each
%% component's own P2 conformance suite already exercises) crosses the Layer-1
%% commit-seam (fh_engine_outcome:validate/3) against the NEWLY-MATERIALIZED
%% fhb-foreign-au registry — the registry existing + resolving + accepting real
%% Mode-B outcomes is the load-bearing claim P3 makes. Mirrors the modes-coexist
%% proof shape investor_profile_conformance.escript established at Mode-C P3
%% (validate a Mode-A outcome against ?FHB alongside the new-mode case, same
%% escript) — extended here to a THREE-way coexistence check (A validates
%% against fhb-domestic-au, C against investor-domestic-au, B against
%% fhb-foreign-au, all in the same artifact, none disturbing another).
%%
%% Run from engine/erlang with the build libs on the path (no Postgres, no live
%% model, no gen_statem turn — base_components/1 has no Mode-B clause yet, P5):
%%   ERL_LIBS=_build/default/lib escript test/mode_b_p3_scope_conformance.escript

-mode(compile).

-define(FHB, <<"fhb-domestic-au">>).
-define(FHB_FOREIGN, <<"fhb-foreign-au">>).
-define(INV, <<"investor-domestic-au">>).

main(_) ->
    ok = fh_engine_kb:load(),
    io:format("Mode-B P3 — scope flip + per-card selection conformance~n~n"),
    R = lists:flatten([scope_cases(), registry_cases(), layer1_mode_b_cases(),
                       modes_coexist_cases()]),
    Fails = [X || X <- R, X =:= fail],
    io:format("~n================================================================~n"),
    case Fails of
        [] -> io:format("PASS — all ~p P3 anchors hold~n", [length(R)]), halt(0);
        _  -> io:format("FAIL — ~p anchor(s) mismatched~n", [length(Fails)]), halt(1)
    end.

%% --- 1. the in-scope SET itself ------------------------------------------------

scope_cases() ->
    InScope = fh_engine_kb:in_scope_blueprints(),
    [check("in_scope_blueprints has exactly the three bare stems",
           lists:sort(InScope),
           lists:sort([<<"fhb-domestic-au">>,
                       <<"fhb-foreign-au">>,
                       <<"investor-domestic-au">>])),
     check("fhb-foreign-au blueprint resolves", element(1, fh_engine_kb:blueprint(?FHB_FOREIGN)), ok)].

%% --- 2. the materialized registry itself ----------------------------------------

registry_cases() ->
    OutcomeTypes = fh_engine_kb:registry(?FHB_FOREIGN, <<"outcome_types">>),
    ExpectedTypes = [<<"profile">>, <<"family_funding_plan">>, <<"property_fit">>,
                      <<"firb_status">>, <<"mortgage_plan">>, <<"budget_envelope">>,
                      <<"transfer_plan">>, <<"ongoing_obligations">>],
    Missing = [T || T <- ExpectedTypes, not maps:is_key(T, OutcomeTypes)],
    [check("fhb-foreign-au registry carries all 8 base+near outcome types", Missing, []),
     check("fhb-foreign-au registry is NOT the fhb-domestic-au registry (divergent shape)",
           maps:get(<<"budget_envelope">>, OutcomeTypes) =/=
               maps:get(<<"budget_envelope">>, fh_engine_kb:registry(?FHB, <<"outcome_types">>)),
           true)].

%% --- 3. Layer-1 conformance for all 6 P2 Mode-B resolver outputs ---------------
%% Same fixtures each component's own P2 conformance escript already exercises —
%% the point here is the REGISTRY SELECTION (validate against fhb-foreign-au, not
%% fhb-domestic-au/investor-domestic-au), not re-proving each component's field
%% arithmetic (already 213/213 PASS across the six P2 escripts).

layer1_mode_b_cases() ->
    Cases = [
        {<<"buyer_profile">>, <<"profile">>,
         #{firb_required_any => true,
           onboarding => #{<<"target_price_range">> => [700000, 900000],
                           <<"target_zone">> => [<<"Footscray">>]}},
         #{}},
        {<<"family_context">>, <<"family_funding_plan">>, #{},
         #{<<"profile">> => #{<<"off_title_parties">> => []}}},
        {<<"firb_workflow">>, <<"firb_status">>, #{},
         #{<<"profile">> => #{<<"target_price_range">> => [700000, 900000],
                              <<"off_title_parties">> => []}}},
        {<<"mortgage_finance">>, <<"mortgage_plan">>,
         #{firb_required_any => true},
         #{<<"profile">> => #{<<"target_price_range">> => [700000, 900000],
                              <<"applicants">> => [#{<<"visa_class">> => null}]}}},
        {<<"cash_position">>, <<"budget_envelope">>,
         #{firb_required_any => true, onboarding => #{<<"state">> => <<"NSW">>}},
         #{<<"profile">> => #{<<"target_price_range">> => [700000, 900000],
                              <<"deposit_ready_for_purchase_amount">> => 300000},
           <<"firb_status">> => #{<<"total_firb_fee_payable">> => 15100},
           <<"mortgage_plan">> => #{<<"deposit_required">> => 270000}}},
        {<<"ownership_planning">>, <<"ongoing_obligations">>,
         #{firb_required_any => true},
         #{<<"firb_status">> => #{<<"total_firb_fee_payable">> => 15100}}},
        {<<"cross_border_funding">>, <<"transfer_plan">>, #{},
         #{<<"family_funding_plan">> =>
               #{<<"contribution_breakdown">> =>
                     [#{<<"party">> => <<"parent">>, <<"amount_aud">> => 400000,
                       <<"currency_origin">> => <<"VND">>}]}}}
    ],
    [begin
         {Outcome, _Rend, _Kb} = fh_engine_fill:resolver(Component, Args, Upstream),
         V = try fh_engine_outcome:validate(?FHB_FOREIGN, OutcomeType, Outcome), ok
             catch _:Why -> {error, Why} end,
         check(<<"Layer-1 conforms (fhb-foreign-au): ", Component/binary>>, V, ok)
     end || {Component, OutcomeType, Args, Upstream} <- Cases].

%% --- 4. three-way modes-coexist (A/B/C, none disturbs another) -----------------

modes_coexist_cases() ->
    %% Mode A: buyer_profile against fhb-domestic-au (the pre-existing path).
    {OA, RendA, _} = fh_engine_fill:resolver(<<"buyer_profile">>,
        #{onboarding => #{<<"target_price_range">> => [600000, 800000],
                          <<"target_zone">> => [<<"Footscray">>]},
          intent => <<"owner_occupier">>}, #{}),
    VA = try fh_engine_outcome:validate(?FHB, <<"profile">>, OA), ok
         catch _:WhyA -> {error, WhyA} end,
    [ApA | _] = maps:get(<<"applicants">>, OA),

    %% Mode C: buyer_profile against investor-domestic-au (the investor shape).
    {OC, RendC, _} = fh_engine_fill:resolver(<<"buyer_profile">>,
        #{onboarding => #{<<"target_price_range">> => [600000, 800000],
                          <<"target_zone">> => [<<"Footscray">>]},
          intent => <<"investor">>}, #{}),
    VC = try fh_engine_outcome:validate(?INV, <<"profile">>, OC), ok
         catch _:WhyC -> {error, WhyC} end,

    %% Mode B: buyer_profile against fhb-foreign-au (this P3 flip).
    {OB, RendB, _} = fh_engine_fill:resolver(<<"buyer_profile">>,
        #{firb_required_any => true,
          onboarding => #{<<"target_price_range">> => [700000, 900000],
                          <<"target_zone">> => [<<"Footscray">>]}}, #{}),
    VB = try fh_engine_outcome:validate(?FHB_FOREIGN, <<"profile">>, OB), ok
         catch _:WhyB -> {error, WhyB} end,
    [ApB | _] = maps:get(<<"applicants">>, OB),

    [check("Mode A buyer_profile still dispatches (summary-card)", RendA, <<"summary-card">>),
     check("Mode A buyer_profile keeps owner_occupier_intent leaf",
           maps:is_key(<<"owner_occupier_intent">>, ApA), true),
     check("Mode A Layer-1 conforms to fhb-domestic-au (no regression)", VA, ok),
     check("Mode C buyer_profile still dispatches (summary-card)", RendC, <<"summary-card">>),
     check("Mode C Layer-1 conforms to investor-domestic-au (no regression)", VC, ok),
     check("Mode B buyer_profile dispatches (summary-card)", RendB, <<"summary-card">>),
     check("Mode B applicant carries firb_status=foreign_person (not Mode A/C shape)",
           maps:get(<<"firb_status">>, ApB, undefined), <<"foreign_person">>),
     check("Mode B Layer-1 conforms to fhb-foreign-au (the P3 flip)", VB, ok)].

%% --- helpers ----------------------------------------------------------------

check(Label, Got, Want) ->
    case Got =:= Want of
        true  -> io:format("  PASS   ~ts~n", [Label]), pass;
        false -> io:format("  FAIL   ~ts = ~p, expected ~p~n", [Label, Got, Want]), fail
    end.
