#!/usr/bin/env escript
%%! -sname fh_mode_d_p3_scope_conformance
%%
%% Mode-D wedge P3 — the compiler flip + per-card multi-blueprint runtime proof
%% (mode-d-wedge.md P3: "Add investor-foreign-au to IN_SCOPE_BLUEPRINTS; green semantic
%% gates; re-emit artifact; prove per-card selection (A/B/C unchanged)"). The per-card
%% multi-blueprint MACHINERY already exists (Mode-C wedge P3, commit e9620be) and was
%% already proven to generalize past two blueprints at Mode-B wedge P3 (commit 31ece08).
%% So this escript is the FOURTH stem's flip + proof, not new machinery — mirrors
%% mode_b_p3_scope_conformance.escript's shape exactly.
%%
%% A real prerequisite surfaced flipping investor-foreign-au in-scope (not just a
%% mechanical flip, unlike Mode B's): the compiler parses each blueprint file's
%% components INDEPENDENTLY (no cross-file JSON stitching) — a component whose "Outcome
%% schema"/"Parameters" are prose-only ("same as Mode B", no inline JSON) contributes
%% NOTHING to that blueprint's own registry, even though the underlying Erlang resolver
%% is genuinely reused unchanged. `firb_workflow` (component 3) was prose-only in
%% investor-foreign-au.md and broke the shared `kb.firb.established-dwelling-ban` /
%% `kb.firb.status-determination` anchor gates once semantic gates started running
%% against this blueprint. Fixed by inlining Mode B's JSON verbatim (P3, 2026-07-04) —
%% zero engine code change, doc-only. A second, genuine finding: `property_assessment`'s
%% outcome was wrongly kept private as `property_fit_investor_foreign` at P2 (P2 never
%% ran this blueprint's semantic gates, so the shared-discriminator dependency on
%% `firb_workflow` — which reads `Upstream.property_fit` verbatim, Mode B's key — was
%% invisible). Reconciled to the canonical `property_fit` (matching Mode A/B). The
%% `fh_engine_disposition`/`fh_engine_cash` investor paths still read `property_fit_investor`
%% (Mode C's key) — a real, correctly-DEFERRED seam (no property resolver runs at P2/P3;
%% decide when `property_assessment` itself is built, per mode-d-wedge.md open seams).
%%
%% Run from engine/erlang with the build libs on the path (no Postgres, no live model, no
%% gen_statem turn — base_components/1 has no Mode-D clause yet, P5):
%%   ERL_LIBS=_build/default/lib escript test/mode_d_p3_scope_conformance.escript

-mode(compile).

-define(FHB, <<"fhb-domestic-au">>).
-define(FHB_FOREIGN, <<"fhb-foreign-au">>).
-define(INV, <<"investor-domestic-au">>).
-define(INV_FOREIGN, <<"investor-foreign-au">>).

main(_) ->
    ok = fh_engine_kb:load(),
    io:format("Mode-D P3 — scope flip + per-card selection conformance~n~n"),
    R = lists:flatten([scope_cases(), registry_cases(), layer1_mode_d_cases(),
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
    [check("in_scope_blueprints has exactly the four bare stems",
           lists:sort(InScope),
           lists:sort([<<"fhb-domestic-au">>,
                       <<"fhb-foreign-au">>,
                       <<"investor-domestic-au">>,
                       <<"investor-foreign-au">>])),
     check("investor-foreign-au blueprint resolves",
           element(1, fh_engine_kb:blueprint(?INV_FOREIGN)), ok)].

%% --- 2. the materialized registry itself ----------------------------------------

registry_cases() ->
    OutcomeTypes = fh_engine_kb:registry(?INV_FOREIGN, <<"outcome_types">>),
    ExpectedTypes = [<<"profile">>, <<"property_fit">>, <<"firb_status">>,
                     <<"strategy_thesis">>, <<"mortgage_plan">>, <<"cash_flow_projection">>,
                     <<"tax_optimised_structure">>, <<"budget_envelope_investor">>,
                     <<"transfer_plan">>, <<"portfolio_position_foreign">>],
    Missing = [T || T <- ExpectedTypes, not maps:is_key(T, OutcomeTypes)],
    [check("investor-foreign-au registry carries all 10 base+near outcome types", Missing, []),
     check("investor-foreign-au registry is NOT the investor-domestic-au registry (divergent shape)",
           maps:get(<<"profile">>, OutcomeTypes) =/=
               maps:get(<<"profile">>, fh_engine_kb:registry(?INV, <<"outcome_types">>)),
           true),
     check("investor-foreign-au's property_fit is registered (the P3 reconciliation)",
           maps:is_key(<<"property_fit">>, OutcomeTypes), true)].

%% --- 3. Layer-1 conformance for all 10 P2 Mode-D resolver outputs ---------------
%% Same fixtures each component's own P2 conformance escript already exercises (see
%% mode_d_p2_conformance.escript) — the point here is the REGISTRY SELECTION (validate
%% against investor-foreign-au, not investor-domestic-au/fhb-foreign-au), not re-proving
%% each component's field arithmetic (already 82/82 PASS in the P2 suite).

onboarding() ->
    #{<<"target_price_range">> => [600000, 800000],
      <<"target_zone">> => [<<"Footscray">>],
      <<"hold_horizon_years">> => 10}.

base_args() -> #{onboarding => onboarding(), firb_required_any => true}.

layer1_mode_d_cases() ->
    {Profile, _, _} = fh_engine_fill:resolver(<<"investor_profile_foreign">>, base_args(), #{}),
    Upstream0 = #{<<"profile">> => Profile},
    {FirbStatus, _, _} = fh_engine_fill:resolver(<<"firb_workflow">>, #{}, Upstream0),
    {Strategy, _, _} = fh_engine_fill:resolver(<<"investment_strategy">>, base_args(), Upstream0),
    {MortgagePlan, _, _} = fh_engine_fill:resolver(<<"mortgage_finance">>,
        #{firb_required_any => true},
        Upstream0#{<<"firb_status">> => FirbStatus, <<"strategy_thesis">> => Strategy}),
    {Cfp, _, _} = fh_engine_fill:resolver(<<"yield_modelling">>, #{}, Upstream0),
    {TaxStruct, _, _} = fh_engine_fill:resolver(<<"tax_structure_non_resident">>,
        #{firb_required_any => true}, Upstream0#{<<"strategy_thesis">> => Strategy}),
    {BudgetEnv, _, _} = fh_engine_fill:resolver(<<"cash_position">>,
        #{firb_required_any => true, onboarding => #{<<"state">> => <<"NSW">>}},
        Upstream0#{<<"firb_status">> => FirbStatus, <<"tax_optimised_structure">> => TaxStruct}),
    {TransferPlan, _, _} = fh_engine_fill:resolver(<<"cross_border_funding">>, #{}, Upstream0),
    {Ownership, _, _} = fh_engine_fill:resolver(<<"ownership_planning_foreign_investor">>,
        #{firb_required_any => true}, Upstream0#{<<"firb_status">> => FirbStatus}),
    Cases = [
        {<<"profile">>, Profile},
        {<<"firb_status">>, FirbStatus},
        {<<"strategy_thesis">>, Strategy},
        {<<"mortgage_plan">>, MortgagePlan},
        {<<"cash_flow_projection">>, Cfp},
        {<<"tax_optimised_structure">>, TaxStruct},
        {<<"budget_envelope_investor">>, BudgetEnv},
        {<<"transfer_plan">>, TransferPlan},
        {<<"portfolio_position_foreign">>, Ownership}
    ],
    [begin
         V = try fh_engine_outcome:validate(?INV_FOREIGN, OutcomeType, Outcome), ok
             catch _:Why -> {error, Why} end,
         check(<<"Layer-1 conforms (investor-foreign-au): ", OutcomeType/binary>>, V, ok)
     end || {OutcomeType, Outcome} <- Cases].

%% --- 4. four-way modes-coexist (A/B/C/D, none disturbs another) -----------------

modes_coexist_cases() ->
    %% Mode A: buyer_profile against fhb-domestic-au (the pre-existing path).
    {OA, RendA, _} = fh_engine_fill:resolver(<<"buyer_profile">>,
        #{onboarding => #{<<"target_price_range">> => [600000, 800000],
                          <<"target_zone">> => [<<"Footscray">>]},
          intent => <<"owner_occupier">>}, #{}),
    VA = try fh_engine_outcome:validate(?FHB, <<"profile">>, OA), ok
         catch _:WhyA -> {error, WhyA} end,

    %% Mode B: buyer_profile against fhb-foreign-au.
    {OB, RendB, _} = fh_engine_fill:resolver(<<"buyer_profile">>,
        #{firb_required_any => true,
          onboarding => #{<<"target_price_range">> => [700000, 900000],
                          <<"target_zone">> => [<<"Footscray">>]}}, #{}),
    VB = try fh_engine_outcome:validate(?FHB_FOREIGN, <<"profile">>, OB), ok
         catch _:WhyB -> {error, WhyB} end,

    %% Mode C: buyer_profile against investor-domestic-au (the investor shape).
    {OC, RendC, _} = fh_engine_fill:resolver(<<"buyer_profile">>,
        #{onboarding => #{<<"target_price_range">> => [600000, 800000],
                          <<"target_zone">> => [<<"Footscray">>]},
          intent => <<"investor">>}, #{}),
    VC = try fh_engine_outcome:validate(?INV, <<"profile">>, OC), ok
         catch _:WhyC -> {error, WhyC} end,

    %% Mode D: investor_profile_foreign against investor-foreign-au (this P3 flip).
    {OD, RendD, _} = fh_engine_fill:resolver(<<"investor_profile_foreign">>, base_args(), #{}),
    VD = try fh_engine_outcome:validate(?INV_FOREIGN, <<"profile">>, OD), ok
         catch _:WhyD -> {error, WhyD} end,
    [ApD | _] = maps:get(<<"applicants">>, OD),

    [check("Mode A buyer_profile still dispatches (summary-card)", RendA, <<"summary-card">>),
     check("Mode A Layer-1 conforms to fhb-domestic-au (no regression)", VA, ok),
     check("Mode B buyer_profile still dispatches (summary-card)", RendB, <<"summary-card">>),
     check("Mode B Layer-1 conforms to fhb-foreign-au (no regression)", VB, ok),
     check("Mode C buyer_profile still dispatches (summary-card)", RendC, <<"summary-card">>),
     check("Mode C Layer-1 conforms to investor-domestic-au (no regression)", VC, ok),
     check("Mode D investor_profile_foreign dispatches (summary-card)", RendD, <<"summary-card">>),
     check("Mode D applicant carries residency_for_tax=non_resident (not A/B/C shape)",
           maps:get(<<"residency_for_tax">>, maps:get(<<"tax">>, ApD, #{}), undefined),
           <<"non_resident">>),
     check("Mode D Layer-1 conforms to investor-foreign-au (the P3 flip)", VD, ok)].

%% --- helpers ----------------------------------------------------------------

check(Label, Got, Want) ->
    case Got =:= Want of
        true  -> io:format("  PASS   ~ts~n", [Label]), pass;
        false -> io:format("  FAIL   ~ts = ~p, expected ~p~n", [Label, Got, Want]), fail
    end.
