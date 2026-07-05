#!/usr/bin/env escript
%%! -sname fh_mode_e_p3_scope_conformance
%%
%% Mode-E wedge P3 — the compiler flip + registry-selection proof
%% (mode-e-wedge.md P3: "Multi-blueprint activation: add nexthome-domestic-au to
%% IN_SCOPE_BLUEPRINTS, run the compiler, resolve any shared-anchor/outcome-key
%% conformance gaps"). Mirrors mode_d_p3_scope_conformance.escript's shape — the
%% per-card multi-blueprint MACHINERY already exists; this is the FIFTH stem's
%% flip + proof, not new machinery.
%%
%% A genuine, LARGER-than-Mode-D prerequisite surfaced flipping nexthome-domestic-au
%% in-scope: 10 of its 13 components (all but buyer_profile, existing_home_disposal,
%% cash_position) were prose-only ("Unchanged from Mode A", no inline KB anchors /
%% Parameters / Outcome-schema jsonc) — the compiler parses each blueprint file's
%% components INDEPENDENTLY (no cross-file JSON stitching), so a prose-only component
%% contributed NOTHING to nexthome-domestic-au's own registry. Empirically verified
%% BEFORE the fix: `fh_engine_kb:registry(<<"nexthome-domestic-au">>, <<"outcome_types">>)`
%% returned only `[profile, existing_home_disposal]` out of 13 components. This is
%% materially worse than what it silently breaks: `fh_engine_outcome:validate/3`
%% passes gracefully (`ok`) for ANY outcome type absent from a blueprint's registry
%% (fh_engine_outcome.erl:60-64, the "missing schema ⟹ pass-through" clause) — so the
%% commit-seam compliance gate was SILENTLY A NO-OP for 11 of Mode E's 13 components.
%% Fixed (2026-07-05) by inlining Mode A's exact schema verbatim into every "unchanged"
%% component (all 13 have a real Erlang resolver — has_resolver/1 — so Mode A's own
%% declared shape IS the one-and-only-correct registry declaration; no divergence to
%% author). Reconciled via a registry-key-set diff (Mode A's outcome-type keys minus
%% `scheme_stack`, plus `existing_home_disposal`) rather than freehand copying — this
%% escript's registry_cases/0 below encodes that same check so it never silently
%% regresses. This finding is BIGGER than the P3 tracker line implies — flagged in
%% mode-e-wedge.md's own P3 row, not just this comment.
%%
%% Separately flagged, NOT fixed here (an architecture decision for Son, not a P3
%% mechanical fix): `fh_engine_outcome:validate/3`'s missing-schema fail-OPEN behavior
%% is a compliance gap wider than Mode E — ANY blueprint author who forgets to inline a
%% component's outcome schema creates a silent, un-alarmed hole in the fail-closed
%% commit-seam gate. Whether validate/3 should instead fail-CLOSED on a missing schema
%% (and what that would break for genuinely-partial/future components) is out of this
%% escript's scope.
%%
%% Run from engine/erlang with the build libs on the path (no Postgres, no live model, no
%% gen_statem turn — base_components/1 has no Mode-E clause yet, P5):
%%   ERL_LIBS=_build/default/lib escript test/mode_e_p3_scope_conformance.escript

-mode(compile).

-define(FHB,      <<"fhb-domestic-au">>).
-define(NEXTHOME, <<"nexthome-domestic-au">>).

main(_) ->
    ok = fh_engine_kb:load(),
    io:format("Mode-E P3 — scope flip + registry-selection conformance~n~n"),
    R = lists:flatten([scope_cases(), registry_cases(), layer1_mode_e_cases(),
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
    [check("in_scope_blueprints has exactly the five bare stems",
           lists:sort(InScope),
           lists:sort([<<"fhb-domestic-au">>,
                       <<"fhb-foreign-au">>,
                       <<"investor-domestic-au">>,
                       <<"investor-foreign-au">>,
                       <<"nexthome-domestic-au">>])),
     check("nexthome-domestic-au blueprint resolves",
           element(1, fh_engine_kb:blueprint(?NEXTHOME)), ok)].

%% --- 2. the materialized registry itself ----------------------------------------
%% The discriminator the P3 finding turned on: enumerate Mode A's own outcome-type
%% keys (minus scheme_stack — Mode E has no eligibility component) plus
%% existing_home_disposal, and assert Mode E's registry carries EXACTLY that set —
%% not "at least", exactly, so a future prose-only regression fails loud here.

registry_cases() ->
    ModeAOutcomeTypes = fh_engine_kb:registry(?FHB, <<"outcome_types">>),
    ModeAKeys = maps:keys(ModeAOutcomeTypes),
    ExpectedKeys = lists:sort((ModeAKeys -- [<<"scheme_stack">>])
                              ++ [<<"existing_home_disposal">>]),
    ModeEOutcomeTypes = fh_engine_kb:registry(?NEXTHOME, <<"outcome_types">>),
    ModeEKeys = lists:sort(maps:keys(ModeEOutcomeTypes)),
    [check("nexthome-domestic-au registry carries EXACTLY the 13 expected outcome types "
           "(Mode A's 12 minus scheme_stack, plus existing_home_disposal)",
           ModeEKeys, ExpectedKeys),
     check("nexthome-domestic-au's profile.applicants tree IS Mode A's applicants tree "
           "verbatim (the per-applicant FIRB gate — constraint #10 — is genuinely "
           "unchanged, not a divergent registry)",
           maps:get(<<"applicants">>, maps:get(<<"profile">>, ModeEOutcomeTypes)),
           maps:get(<<"applicants">>, maps:get(<<"profile">>, ModeAOutcomeTypes))),
     check("nexthome-domestic-au's profile carries the Mode-E-only existing_home_ownership field",
           maps:is_key(<<"existing_home_ownership">>, maps:get(<<"profile">>, ModeEOutcomeTypes)),
           true),
     check("nexthome-domestic-au's mortgage_plan IS Mode A's mortgage_plan shape "
           "(verbatim reuse, verified P2)",
           maps:get(<<"mortgage_plan">>, ModeEOutcomeTypes),
           maps:get(<<"mortgage_plan">>, ModeAOutcomeTypes)),
     check("nexthome-domestic-au's existing_home_disposal is registered (the new type)",
           maps:is_key(<<"existing_home_disposal">>, ModeEOutcomeTypes), true),
     check("nexthome-domestic-au has NO scheme_stack type (eligibility dropped)",
           maps:is_key(<<"scheme_stack">>, ModeEOutcomeTypes), false)].

%% --- 3. Layer-1 conformance: REGISTRY SELECTION, not re-proving field arithmetic ---
%% Same fixtures mode_e_p2_conformance.escript already exercises (35/35 PASS) — the
%% point here is that fh_engine_outcome:validate/3 is called against nexthome-domestic-au
%% specifically (proving the P3 fix), not against fhb-domestic-au by accident. A
%% representative subset: the two Mode-E-specific resolvers (existing_home_disposal,
%% cash_position's fill_fhb_nexthome branch) plus three pure-reuse resolvers
%% (buyer_profile, mortgage_finance, disposition) — the remaining pure-reuse types
%% (property_fit, bid_plan, risk_assessment, settlement_checklist, ongoing_obligations,
%% journey_swimlane, preparation_plan, phase_playbook) are covered by the registry
%% key-set + shape-equality checks above (registry_cases/0), since their type trees are
%% verbatim-identical to Mode A's own (already exercised by fhb-domestic-au's own
%% conformance suites) — re-running all 13 resolvers here would re-prove field
%% arithmetic mode_e_p2_conformance.escript already covers, not registry selection.

onboarding() ->
    #{<<"target_price_range">> => [900000, 1100000],
      <<"state">> => <<"VIC">>}.

base_args() -> #{onboarding => onboarding(), firb_required_any => false}.

profile_with_facts(RateType, RentalHistory) ->
    #{<<"target_price_range">> => [900000, 1100000],
      <<"tax_residency">> => <<"resident">>,
      <<"existing_home_ownership">> => #{
          <<"currently_owns_ppor">> => true,
          <<"ppor_estimated_value">> => 800000,
          <<"ppor_outstanding_loan_balance">> => 400000,
          <<"ppor_loan_rate_type">> => RateType,
          <<"ppor_rental_history">> => RentalHistory
      }}.

layer1_mode_e_cases() ->
    %% buyer_profile → profile
    {Profile, RendProfile, _} = fh_engine_fill:resolver(<<"buyer_profile">>, base_args(), #{}),
    VProfile = try fh_engine_outcome:validate(?NEXTHOME, <<"profile">>, Profile), ok
               catch _:WhyP -> {error, WhyP} end,

    %% existing_home_disposal (the NEW component) — variable-rate, known facts
    Upstream0 = #{<<"profile">> => profile_with_facts(<<"variable">>, false)},
    {Existing, RendExisting, _} = fh_engine_fill:resolver(<<"existing_home_disposal">>,
                                                           #{}, Upstream0),
    VExisting = try fh_engine_outcome:validate(?NEXTHOME, <<"existing_home_disposal">>, Existing), ok
                catch _:WhyE -> {error, WhyE} end,

    %% mortgage_finance — reused unchanged
    {MortgagePlan, _, _} = fh_engine_fill:resolver(<<"mortgage_finance">>, base_args(), Upstream0),
    VMortgage = try fh_engine_outcome:validate(?NEXTHOME, <<"mortgage_plan">>, MortgagePlan), ok
                catch _:WhyM -> {error, WhyM} end,

    %% cash_position — the Mode-E fill_fhb_nexthome branch (existing_home_disposal in Upstream)
    Upstream1 = Upstream0#{<<"mortgage_plan">> => #{<<"recommended_path">> => <<"lmi_5_to_20">>},
                           <<"existing_home_disposal">> => Existing},
    {BudgetEnvelope, RendCash, _} = fh_engine_fill:resolver(<<"cash_position">>, base_args(), Upstream1),
    VCash = try fh_engine_outcome:validate(?NEXTHOME, <<"budget_envelope">>, BudgetEnvelope), ok
            catch _:WhyC -> {error, WhyC} end,

    %% disposition — reused unchanged (owner-occupier path)
    ProfileForDispose = (profile_with_facts(<<"variable">>, false))#{
        <<"intended_occupancy_use">> => <<"sole_occupier">>},
    Upstream2 = #{<<"profile">> => ProfileForDispose,
                  <<"budget_envelope">> => #{<<"total_cash_required">> => [200000, 220000]},
                  <<"mortgage_plan">> => #{<<"expected_borrowing_capacity">> => null},
                  <<"ongoing_obligations">> => #{}},
    {Disposition, _, _} = fh_engine_fill:resolver(<<"disposition">>, #{}, Upstream2),
    VDisposition = try fh_engine_outcome:validate(?NEXTHOME, <<"disposition">>, Disposition), ok
                   catch _:WhyD -> {error, WhyD} end,

    [check("buyer_profile dispatches (summary-card)", RendProfile, <<"summary-card">>),
     check("Layer-1 conforms (nexthome-domestic-au): profile", VProfile, ok),
     check("existing_home_disposal dispatches (calculator)", RendExisting, <<"calculator">>),
     check("Layer-1 conforms (nexthome-domestic-au): existing_home_disposal", VExisting, ok),
     check("Layer-1 conforms (nexthome-domestic-au): mortgage_plan", VMortgage, ok),
     check("cash_position (fill_fhb_nexthome) dispatches (calculator)", RendCash, <<"calculator">>),
     check("Layer-1 conforms (nexthome-domestic-au): budget_envelope", VCash, ok),
     check("Layer-1 conforms (nexthome-domestic-au): disposition", VDisposition, ok)].

%% --- 4. five-way modes-coexist (A/B/C/D/E, none disturbs another) ---------------

modes_coexist_cases() ->
    %% Mode A: buyer_profile against fhb-domestic-au (the pre-existing path).
    {OA, RendA, _} = fh_engine_fill:resolver(<<"buyer_profile">>,
        #{onboarding => #{<<"target_price_range">> => [600000, 800000],
                          <<"target_zone">> => [<<"Footscray">>]},
          intent => <<"owner_occupier">>}, #{}),
    VA = try fh_engine_outcome:validate(?FHB, <<"profile">>, OA), ok
         catch _:WhyA -> {error, WhyA} end,

    %% Mode E: buyer_profile against nexthome-domestic-au (this P3 flip) — identical
    %% resolver call to Mode A's (buyer_profile/1 has no Mode-E branch; the registry
    %% VALIDATED against is the only thing that differs).
    {OE, RendE, _} = fh_engine_fill:resolver(<<"buyer_profile">>,
        #{onboarding => #{<<"target_price_range">> => [900000, 1100000],
                          <<"target_zone">> => [<<"Footscray">>]},
          intent => <<"owner_occupier">>}, #{}),
    VE = try fh_engine_outcome:validate(?NEXTHOME, <<"profile">>, OE), ok
         catch _:WhyE -> {error, WhyE} end,

    [check("Mode A buyer_profile still dispatches (summary-card)", RendA, <<"summary-card">>),
     check("Mode A Layer-1 conforms to fhb-domestic-au (no regression)", VA, ok),
     check("Mode E buyer_profile dispatches (summary-card)", RendE, <<"summary-card">>),
     check("Mode E Layer-1 conforms to nexthome-domestic-au (the P3 flip)", VE, ok)].

%% --- helpers ----------------------------------------------------------------

check(Label, Got, Want) ->
    case Got =:= Want of
        true  -> io:format("  PASS   ~ts~n", [Label]), pass;
        false -> io:format("  FAIL   ~ts = ~p, expected ~p~n", [Label, Got, Want]), fail
    end.
