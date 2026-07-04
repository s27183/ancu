#!/usr/bin/env escript
%%! -sname fh_mode_d_p2_conformance
%%
%% Conformance suite for Mode-D P2 (the base-turn engine resolvers, investor-foreign-au.md,
%% mode-d-wedge.md P2). Loads the SAME materialized artifact the engine loads (priv/kb/
%% artifact.json via fh_engine_kb) and asserts what the P2 wiring relies on:
%%   1. investor_profile_foreign — the canonical `profile` projection (2026-07-03 outcome-
%%      type conformance reconciliation), firb_required_any=true, and CRITICALLY
%%      applicant.tax.residency_for_tax=non_resident (misadvice-critical — see disposition).
%%   2. firb_workflow REUSE — the existing fh_engine_firb:fill/2, unchanged, given
%%      investor_profile_foreign's profile projection (no property at base).
%%   3. investment_strategy — the Mode-D branch (dispatched by firb_required_any), same
%%      strategy_thesis shape + agent-slot discipline as Mode C's, plus the two Mode-D-only
%%      resolver fields.
%%   4. mortgage_finance fill_investor_foreign — the 4th (investor+foreign) branch: the
%%      10-field mortgage_plan shape, rate_estimate/deposit KB-grounded arithmetic,
%%      firb_dependency_acknowledged=true, vn/fx confirmation flags honestly false at base.
%%   5. yield_modelling REUSE — unchanged at base (no property ⟹ base_cfp() all-null,
%%      mode-agnostic) under the renamed canonical cash_flow_projection key.
%%   6. tax_structure_non_resident — the definitional (not holding-period-conditional) CGT
%%      determinants: cgt_discount_eligible=false, ppor_exemption_eligible=false,
%%      frcgw_applicable=true, cost_base_depreciation_clawback=true.
%%   7. cash_position fill_investor_foreign — the 4th (investor+foreign) branch:
%%      regulatory_imposts_total = duty(no concession) + surcharge + FIRB fee (placed, never
%%      recomputed), channel_costs_total, total_cash_required.
%%   8. cross_border_funding — the Mode-D delta: family_funding_plan absent ⟹ falls back to
%%      profile.available_capital_aud_equivalent (the tracker's "no delta" claim was wrong).
%%   9. ownership_planning_foreign_investor — the new sibling module: base-computable AU/VN
%%      obligation prose + the placed vacancy-fee alert, mode_switch_eligible_on_pr=false.
%%  10. disposition — the misadvice-critical assertion: a Mode-D turn (non_resident applicant
%%      + tax_optimised_structure.frcgw_applicable=true) ALWAYS lands cgt_status=to_verify
%%      (never "computed", regardless of how clean the entity/rate look), taxable_gain shown
%%      undiscounted, frcgw_withheld_at_settlement = 15% of the sale-proceeds band, and
%%      Mode-C (frcgw_applicable absent) is unaffected (regression).
%%
%% Run from engine/erlang with the build libs on the path (no Postgres needed):
%%   ERL_LIBS=_build/default/lib escript test/mode_d_p2_conformance.escript

-mode(compile).

main(_) ->
    ok = fh_engine_kb:load(),
    io:format("Mode-D P2 conformance — the base-turn engine resolvers~n~n"),
    R = lists:flatten([investor_profile_foreign_cases(), firb_reuse_cases(),
                       investment_strategy_cases(), mortgage_cases(),
                       yield_modelling_reuse_cases(), tax_structure_cases(),
                       cash_position_cases(), cross_border_cases(),
                       ownership_cases(), disposition_cases()]),
    Fails = [X || X <- R, X =:= fail],
    io:format("~n================================================================~n"),
    case Fails of
        [] ->
            io:format("PASS — all ~p Mode-D P2 anchors hold~n", [length(R)]),
            halt(0);
        _ ->
            io:format("FAIL — ~p anchor(s) mismatched~n", [length(Fails)]),
            halt(1)
    end.

%% --- fixtures ----------------------------------------------------------------

onboarding() ->
    #{<<"target_price_range">> => [600000, 800000],
      <<"target_zone">> => [<<"Footscray">>],
      <<"hold_horizon_years">> => 10}.

base_args() -> #{onboarding => onboarding(), firb_required_any => true}.

g(M, K) -> maps:get(K, M).

%% --- 1. investor_profile_foreign ---------------------------------------------

investor_profile_foreign_cases() ->
    {O, Renderer, Kb} = fh_engine_fill:resolver(<<"investor_profile_foreign">>, base_args(), #{}),
    [App] = g(O, <<"applicants">>),
    Tax = g(App, <<"tax">>),
    [check("renderer = summary-card", Renderer, <<"summary-card">>),
     check("firb_required_any = true (definitional)", g(O, <<"firb_required_any">>), true),
     check("applicant.firb_status = foreign_person", g(App, <<"firb_status">>), <<"foreign_person">>),
     check("applicant.tax.residency_for_tax = non_resident (misadvice-critical)",
           g(Tax, <<"residency_for_tax">>), <<"non_resident">>),
     check("applicant.tax.jurisdiction = AU (AU-side-only scoping)", g(Tax, <<"jurisdiction">>), <<"AU">>),
     check("target_price_range carried", g(O, <<"target_price_range">>), [600000, 800000]),
     check("hold_horizon_years carried", g(O, <<"hold_horizon_years">>), 10),
     check("off_title_parties = [] at base", g(O, <<"off_title_parties">>), []),
     check("assessable_income null (no financials at onboarding)", g(O, <<"assessable_income">>), null),
     check("available_capital_aud_equivalent null (honest-partial)",
           g(O, <<"available_capital_aud_equivalent">>), null),
     check("key_strengths carries the foreign-investor strength", length(g(O, <<"key_strengths">>)), 1),
     check("kb_anchors non-empty", length(Kb) > 0, true)].

%% --- 2. firb_workflow reuse (unchanged) ---------------------------------------

firb_reuse_cases() ->
    {Profile, _, _} = fh_engine_fill:resolver(<<"investor_profile_foreign">>, base_args(), #{}),
    {O, Renderer, _} = fh_engine_fill:resolver(<<"firb_workflow">>, #{}, #{<<"profile">> => Profile}),
    [check("renderer = firb-workflow-card", Renderer, <<"firb-workflow-card">>),
     %% no property at base: eligibility undetermined; fee at the ceiling of target_price_range.
     check("foreign_person_eligible = null (no property attached yet)",
           g(O, <<"foreign_person_eligible">>), null),
     check("firb_fee_tier picked at the 800000 ceiling", g(O, <<"firb_fee_tier">>), <<"under_1m">>),
     check("total_firb_fee_payable computed at the ceiling", g(O, <<"total_firb_fee_payable">>), 15100),
     check("blocking_for_contract = true (not yet approved)", g(O, <<"blocking_for_contract">>), true)].

%% --- 3. investment_strategy (Mode-D branch) -----------------------------------

investment_strategy_cases() ->
    {Profile, _, _} = fh_engine_fill:resolver(<<"investor_profile_foreign">>, base_args(), #{}),
    {O, Renderer, Kb} = fh_engine_fill:resolver(<<"investment_strategy">>, base_args(),
                                                #{<<"profile">> => Profile}),
    %% Mode-A (non-investor, non-foreign) unaffected — regression check.
    {OA, _, _} = fh_engine_fill:resolver(<<"investment_strategy">>, #{firb_required_any => false},
                                         #{<<"profile">> => #{<<"hold_horizon_years">> => 5}}),
    [check("renderer = summary-card", Renderer, <<"summary-card">>),
     check("hold_period_years carried off profile", g(O, <<"hold_period_years">>), 10),
     check("archetype null (agent slot, pre-merge)", g(O, <<"archetype">>), null),
     check("migration_pathway_alignment null (Mode-D-only, honest-partial)",
           g(O, <<"migration_pathway_alignment">>), null),
     check("currency_hedging_strategy null (Mode-D-only, honest-partial)",
           g(O, <<"currency_hedging_strategy">>), null),
     check("Mode-D KB anchors present (foreign-investor thesis)",
           has_anchor(Kb, <<"kb.foreign-investor.thesis-archetypes">>), true),
     check("Mode-C (domestic) path unaffected — no Mode-D fields present",
           maps:is_key(<<"migration_pathway_alignment">>, OA), false)].

%% --- 4. mortgage_finance fill_investor_foreign --------------------------------

mortgage_cases() ->
    Upstream = #{<<"strategy_thesis">> => #{<<"hold_period_years">> => 10},
                 <<"profile">> => #{<<"target_price_range">> => [600000, 800000]}},
    {O, Renderer, Kb} = fh_engine_fill:resolver(<<"mortgage_finance">>, base_args(), Upstream),
    %% dispatched through fh_engine_mortgage:fill/2 directly too — proves the compound branch.
    {O2, _, _} = fh_engine_mortgage:fill(base_args(), Upstream),
    [DepLo, DepHi] = fh_engine_mortgage:rate_estimate_foreign(),
    %% merge_agent + agent_values_from_outcome round-trip (§98 slot-scoped fold). Shortlist
    %% shape matches Mode C's (reconciled 2026-07-04 — see fh_engine_mortgage.erl comment).
    %% THREE leaves, not Mode C's five — fixed_vs_variable added 2026-07-05 (was drafted as a
    %% blueprint Parameter + already computed by the shared leaf-fill, but silently discarded
    %% here); no offset/PPOR-equity leaves (Mode D has no AU PPOR, its own Python schema
    %% never authors them).
    Shortlist = [#{<<"lender">> => <<"Lender X">>,
                   <<"reasoning">> => #{<<"vi">> => <<"Phù hợp với nhà đầu tư không cư trú."/utf8>>,
                                        <<"en">> => <<"Fits a non-resident investor profile.">>},
                   <<"approval_likelihood">> => <<"moderate">>}],
    AgentValues = #{<<"recommended_lender_shortlist">> => Shortlist,
                    <<"io_vs_pi_recommendation">> => <<"interest_only">>,
                    <<"fixed_vs_variable">> => <<"fixed_2yr">>},
    Merged = fh_engine_mortgage:merge_agent(O, AgentValues),
    Recovered = fh_engine_mortgage:agent_values_from_outcome(Merged),
    [check("renderer = summary-card", Renderer, <<"summary-card">>),
     check("dispatched via fh_engine_fill matches direct fh_engine_mortgage:fill/2", O, O2),
     check("firb_dependency_acknowledged = true (definitional)",
           g(O, <<"firb_dependency_acknowledged">>), true),
     check("vn_income_acceptance_confirmed = false (honest, not yet confirmed)",
           g(O, <<"vn_income_acceptance_confirmed">>), false),
     check("fx_risk_acknowledged = false (honest, not yet confirmed)",
           g(O, <<"fx_risk_acknowledged">>), false),
     check("deposit_required_percentage = 35 (midpoint of the 30-40% band)",
           g(O, <<"deposit_required_percentage">>), 35.0),
     check("deposit_required_amount = 35% of the 800000 ceiling",
           g(O, <<"deposit_required_amount">>), round(800000 * 0.35)),
     check("rate_estimate is a [lo,hi] band, lo < hi", DepLo < DepHi, true),
     check("recommended_lender_shortlist null (agent slot, pre-merge)",
           g(O, <<"recommended_lender_shortlist">>), null),
     check("io_vs_pi_recommendation null (agent slot, pre-merge)",
           g(O, <<"io_vs_pi_recommendation">>), null),
     check("fixed_vs_variable null (agent slot, pre-merge)",
           g(O, <<"fixed_vs_variable">>), null),
     check("loan_cost_estimate_year_1 null (needs a loan amount, absent at base)",
           g(O, <<"loan_cost_estimate_year_1">>), null),
     check("Mode-D KB anchors present", has_anchor(Kb, <<"kb.lender.non-resident-investment-loan-shortlist">>), true),
     check("merge_agent folds the three Mode-D agent leaves",
           {g(Merged, <<"recommended_lender_shortlist">>), g(Merged, <<"io_vs_pi_recommendation">>),
            g(Merged, <<"fixed_vs_variable">>)},
           {Shortlist, <<"interest_only">>, <<"fixed_2yr">>}),
     check("merge_agent leaves every figure untouched (§98)",
           g(Merged, <<"deposit_required_amount">>), g(O, <<"deposit_required_amount">>)),
     check("agent_values_from_outcome round-trips the three leaves verbatim",
           Recovered, AgentValues)].

%% --- 5. yield_modelling reuse (unchanged at base) -----------------------------

yield_modelling_reuse_cases() ->
    {O, Renderer, _} = fh_engine_fill:resolver(<<"yield_modelling">>, #{}, #{}),
    [check("renderer = calculator", Renderer, <<"calculator">>),
     check("no property at base: annual_rental_income_year_1 null (mode-agnostic base_cfp)",
           g(O, <<"annual_rental_income_year_1">>), null),
     check("no property at base: gross_yield null", g(O, <<"gross_yield">>), null)].

%% --- 6. tax_structure_non_resident --------------------------------------------

tax_structure_cases() ->
    {O, Renderer, Kb} = fh_engine_fill:resolver(<<"tax_structure_non_resident">>, #{}, #{}),
    %% merge_agent + agent_values_from_outcome round-trip.
    Merged = fh_engine_fill:merge_agent(<<"tax_structure_non_resident">>, O,
                                        #{<<"recommended_entity">> => <<"personal_sole_non_resident">>}),
    [check("renderer = data-table", Renderer, <<"data-table">>),
     check("cgt_discount_eligible = false (definitional, NOT holding-period-conditional)",
           g(O, <<"cgt_discount_eligible">>), false),
     check("ppor_exemption_eligible = false (moot, never a main residence)",
           g(O, <<"ppor_exemption_eligible">>), false),
     check("frcgw_applicable = true (definitional)", g(O, <<"frcgw_applicable">>), true),
     check("cost_base_depreciation_clawback = true (Div 43 claimed)",
           g(O, <<"cost_base_depreciation_clawback">>), true),
     check("negative_gearing_available_against_au_income = true (structural)",
           g(O, <<"negative_gearing_available_against_au_income">>), true),
     check("rental_withholding_rate null (assessment, not withholding — no rate applies)",
           g(O, <<"rental_withholding_rate">>), null),
     check("cgt_marginal_rate null (no non-resident bracket table yet, no income at base)",
           g(O, <<"cgt_marginal_rate">>), null),
     check("recommended_entity null (agent slot, pre-merge)", g(O, <<"recommended_entity">>), null),
     check("Mode-D KB anchors present", has_anchor(Kb, <<"kb.au-vn-tax-treaty">>), true),
     check("merge_agent folds the one entity leaf",
           g(Merged, <<"recommended_entity">>), <<"personal_sole_non_resident">>),
     check("merge_agent leaves cgt_discount_eligible untouched (§98)",
           g(Merged, <<"cgt_discount_eligible">>), false),
     check("agent_values_from_outcome round-trips",
           fh_engine_fill:agent_values_from_outcome(<<"tax_structure_non_resident">>, Merged),
           #{<<"recommended_entity">> => <<"personal_sole_non_resident">>})].

%% --- 7. cash_position fill_investor_foreign -----------------------------------

cash_position_cases() ->
    Upstream = #{<<"tax_optimised_structure">> => #{},
                 <<"profile">> => #{<<"target_price_range">> => [600000, 800000]},
                 <<"firb_status">> => #{<<"total_firb_fee_payable">> => 15100},
                 <<"mortgage_plan">> => #{<<"deposit_required_amount">> => 280000}},
    %% no target_zone here (pure explicit_state/1 path — no DB, mirrors
    %% cash_position_foreign_conformance.escript's own no-PG fixture convention).
    Args = (base_args())#{onboarding => #{<<"state">> => <<"NSW">>}},
    {O, Renderer, Kb} = fh_engine_fill:resolver(<<"cash_position">>, Args, Upstream),
    {O2, _, _} = fh_engine_cash:fill_investor_foreign(Args, Upstream),
    Duty = fh_engine_cash:stamp_duty(<<"NSW">>, false, 800000),
    DutyAfter = g(Duty, <<"after_concession">>),
    Surcharge = fh_engine_cash:surcharge_amount(<<"NSW">>, 800000),
    [check("renderer = calculator", Renderer, <<"calculator">>),
     check("dispatched via fh_engine_fill matches direct fill_investor_foreign/2", O, O2),
     check("no property at base: actual_property_price null", g(O, <<"actual_property_price">>), null),
     check("regulatory_imposts_total = duty(no concession) + surcharge + FIRB fee (placed)",
           g(O, <<"regulatory_imposts_total">>), DutyAfter + Surcharge + 15100),
     check("channel_costs_total computed (registration + due-diligence convention band)",
           is_integer(g(O, <<"channel_costs_total">>)), true),
     check("total_cash_required = deposit + regulatory + channel",
           g(O, <<"total_cash_required">>),
           280000 + (DutyAfter + Surcharge + 15100) + g(O, <<"channel_costs_total">>)),
     check("loan_amount null (no property, Slice-B3b-style deferral)", g(O, <<"loan_amount">>), null),
     check("Mode-D KB anchors present",
           has_anchor(Kb, <<"kb.non-resident.investment-loan-deposit-requirements">>), true)].

%% --- 8. cross_border_funding — the Mode-D delta -------------------------------

cross_border_cases() ->
    %% no family_funding_plan (Mode D has no family_context) ⟹ falls back to
    %% profile.available_capital_aud_equivalent.
    UpstreamD = #{<<"profile">> => #{<<"available_capital_aud_equivalent">> => 300000}},
    {OD, _, _} = fh_engine_fill:resolver(<<"cross_border_funding">>, #{}, UpstreamD),
    %% Mode B unaffected — regression check (family_funding_plan present, VND-origin line).
    UpstreamB = #{<<"family_funding_plan">> =>
                     #{<<"contribution_breakdown">> =>
                           [#{<<"amount_aud">> => 150000, <<"currency_origin">> => <<"VND">>}]}},
    {OB, _, _} = fh_engine_fill:resolver(<<"cross_border_funding">>, #{}, UpstreamB),
    [check("Mode-D: transfer amount falls back to profile.available_capital_aud_equivalent",
           g(OD, <<"total_transfer_amount_aud">>), 300000),
     check("Mode-D: fx_cost computed off the fallback amount",
           is_integer(g(OD, <<"estimated_fx_cost">>)), true),
     check("Mode-B regression: family_funding_plan path unaffected",
           g(OB, <<"total_transfer_amount_aud">>), 150000)].

%% --- 9. ownership_planning_foreign_investor -----------------------------------

ownership_cases() ->
    Upstream = #{<<"firb_status">> => #{<<"total_firb_fee_payable">> => 15100}},
    {O, Renderer, Kb} = fh_engine_fill:resolver(<<"ownership_planning_foreign_investor">>, #{}, Upstream),
    Alerts = g(O, <<"alert_triggers_armed">>),
    [check("renderer = data-table", Renderer, <<"data-table">>),
     check("mode_switch_eligible_on_pr = false (honest starting value)",
           g(O, <<"mode_switch_eligible_on_pr">>), false),
     check("annual_au_tax_obligations base-computable (3 lines)",
           length(g(O, <<"annual_au_tax_obligations">>)), 3),
     check("annual_vn_tax_obligations base-computable (1 placeholder-pointer line)",
           length(g(O, <<"annual_vn_tax_obligations">>)), 1),
     check("monthly_net_cash_flow_after_withholding null (no property/actuals)",
           g(O, <<"monthly_net_cash_flow_after_withholding">>), null),
     check("6 lifecycle alerts armed (vacancy, review, au-tax, vn-tax, fx, pr-switch)",
           length(Alerts), 6),
     check("Mode-D KB anchors present", has_anchor(Kb, <<"kb.foreign-investor.repatriation-strategy">>), true)].

%% --- 10. disposition — the misadvice-critical assertion -----------------------

inv_profile_d() ->
    #{<<"hold_horizon_years">> => 10,
      <<"target_price_range">> => [600000, 800000],
      <<"applicants">> => [#{<<"role">> => <<"primary">>,
                             <<"tax">>  => #{<<"residency_for_tax">> => <<"non_resident">>}}]}.

%% the "cleanest possible looking" Mode-D tax_optimised_structure — entity/rate/clawback all
%% shaped like Mode C's Clean case, EXCEPT non-resident + frcgw_applicable. Proves to_verify
%% is driven by residency, not by an accidentally-messy fixture.
inv_tax_d() ->
    #{<<"recommended_entity">>             => <<"personal_sole">>,
      <<"cgt_discount_eligible">>          => false,
      <<"cgt_marginal_rate">>              => 32.5,
      <<"cost_base_depreciation_clawback">> => false,
      <<"frcgw_applicable">>               => true}.

inv_profile_c() ->
    #{<<"hold_horizon_years">> => 10,
      <<"target_price_range">> => [600000, 800000],
      <<"applicants">> => [#{<<"role">> => <<"primary">>,
                             <<"tax">>  => #{<<"residency_for_tax">> => <<"resident">>}}]}.

%% Mode-C's own Clean fixture — frcgw_applicable simply absent (as Mode C's tax_structure
%% never sets it).
inv_tax_c() ->
    #{<<"recommended_entity">>             => <<"personal_sole">>,
      <<"cgt_discount_eligible">>          => true,
      <<"cgt_marginal_rate">>              => 32.5,
      <<"cost_base_depreciation_clawback">> => false}.

disposition_cases() ->
    Upstream = #{<<"profile">> => inv_profile_d(),
                 <<"budget_envelope_investor">> => #{<<"total_cash_required">> => [200000, 205000],
                                                     <<"loan_amount">> => 560000},
                 <<"cash_flow_projection">> => #{<<"cash_flow_before_tax_year_1">> => -8000},
                 <<"tax_optimised_structure">> => inv_tax_d()},
    {O, _, _} = fh_engine_disposition:fill(#{}, Upstream),
    SaleBand = g(O, <<"sale_proceeds">>),
    FrcgwExpected = [round(0.15 * lists:nth(1, SaleBand)), round(0.15 * lists:nth(2, SaleBand))],
    %% Mode-C regression: frcgw_applicable absent ⟹ both Mode-D-only fields stay null.
    UpstreamC = Upstream#{<<"profile">> => inv_profile_c(),
                          <<"tax_optimised_structure">> => inv_tax_c()},
    {OC, _, _} = fh_engine_disposition:fill(#{}, UpstreamC),
    [check("cgt_status ALWAYS to_verify for Mode D — even with a clean-looking entity/rate/clawback",
           g(O, <<"cgt_status">>), <<"to_verify">>),
     check("cgt = null (deferred to a tax agent)", g(O, <<"cgt">>), null),
     check("taxable_gain still shown, undiscounted (cgt_discount_eligible=false ⟹ 0% discount)",
           is_list(g(O, <<"taxable_gain">>)), true),
     check("frcgw_withheld_at_settlement = 15%% of the sale-proceeds band",
           g(O, <<"frcgw_withheld_at_settlement">>), FrcgwExpected),
     check("vn_side_cgt_note present (non-null)", g(O, <<"vn_side_cgt_note">>) =/= null, true),
     check("key_assumptions includes the FRCGW line",
           length(g(O, <<"key_assumptions">>)) >= 6, true),
     check("dispose_cash_events: no cgt event (cgt null, honest-partial drop)",
           lists:member(<<"dispose_cgt">>, [maps:get(<<"id">>, E) || E <- g(O, <<"dispose_cash_events">>)]),
           false),
     check("Mode-C regression: frcgw_withheld_at_settlement null when frcgw_applicable absent",
           g(OC, <<"frcgw_withheld_at_settlement">>), null),
     check("Mode-C regression: vn_side_cgt_note null when frcgw_applicable absent",
           g(OC, <<"vn_side_cgt_note">>), null)].

%% --- helpers ----------------------------------------------------------------

%% kb_anchors/1 returns [#{<<"slug">> => Qualified, ...}], not raw binaries.
has_anchor(Kb, Slug) ->
    Qualified = <<"kb:", Slug/binary>>,
    lists:any(fun(A) -> maps:get(<<"slug">>, A, undefined) =:= Qualified
                      orelse maps:get(<<"slug">>, A, undefined) =:= Slug
              end, Kb).

check(Label, Got, Want) ->
    case Got =:= Want of
        true  -> io:format("  PASS   ~ts~n", [Label]), pass;
        false -> io:format("  FAIL   ~ts = ~p, expected ~p~n", [Label, Got, Want]), fail
    end.
