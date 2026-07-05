#!/usr/bin/env escript
%%! -sname fh_mode_e_p2_conformance
%%
%% Conformance suite for Mode-E P2 (the base-turn engine resolvers, nexthome-domestic-au.md,
%% mode-e-wedge.md P2). Loads the SAME materialized artifact the engine loads (priv/kb/
%% artifact.json via fh_engine_kb — regenerated this session to include the P1 KB docs;
%% in_scope_blueprints is UNCHANGED, still the 4 A/B/C/D entries — nexthome-domestic-au is
%% parsed/structurally-gated but not yet activated, P3's job) and asserts what the P2 wiring
%% relies on:
%%   1. existing_home_disposal (NEW) — honest-partial at base (no onboarding capture of the
%%      existing home's facts): every money figure null except the qualitative flags.
%%   2. existing_home_disposal — a variable-rate loan with known facts: total_payout,
%%      selling_costs (REUSED from fh_engine_disposition), cgt exempt (REUSED), and
%%      net_sale_proceeds all compute to a known figure.
%%   3. existing_home_disposal — a fixed-rate loan: break_cost_status = to_verify,
%%      total_payout stays null (never a guessed break cost), so net_sale_proceeds stays null
%%      too even though every other input is known (honest-partial propagates).
%%   4. existing_home_disposal — rental history on the existing home: cgt_status = to_verify
%%      (REUSED disposition logic via the occupancy proxy), net_sale_proceeds null.
%%   5. cash_position fill_fhb_nexthome — the Mode-E branch: NEED side identical to Mode A's
%%      fill_fhb (full stamp duty, no concession, since no scheme_stack exists) + the HAVE
%%      side folding existing_home_disposal.net_sale_proceeds via gap_range/verdict_from_gap.
%%   6. cash_position REGRESSION — fill/2 with no existing_home_disposal upstream still routes
%%      to fill_fhb/2 exactly as before (Mode A unaffected).
%%   7. mortgage_finance REUSE — fill/2 with no scheme_stack/no strategy_thesis still routes to
%%      fill_fhb/2, which already defaults gracefully to no-FHG (recommended_path never
%%      fhg_backed for a repeat buyer, zero code change needed).
%%   8. disposition REUSE — fill/2 with no tax_optimised_structure still routes to
%%      fill_owner_occupier/2 given Mode-E-shaped budget_envelope/mortgage_plan inputs.
%%
%% Run from engine/erlang with the build libs on the path (no Postgres needed):
%%   ERL_LIBS=_build/default/lib escript test/mode_e_p2_conformance.escript

-mode(compile).

main(_) ->
    ok = fh_engine_kb:load(),
    io:format("Mode-E P2 conformance — the base-turn engine resolvers~n~n"),
    R = lists:flatten([existing_home_base_case(), existing_home_variable_rate_case(),
                       existing_home_fixed_rate_case(), existing_home_rental_history_case(),
                       cash_position_nexthome_cases(), cash_position_regression_cases(),
                       mortgage_reuse_cases(), disposition_reuse_cases()]),
    Fails = [X || X <- R, X =:= fail],
    io:format("~n================================================================~n"),
    case Fails of
        [] ->
            io:format("PASS — all ~p Mode-E P2 anchors hold~n", [length(R)]),
            halt(0);
        _ ->
            io:format("FAIL — ~p anchor(s) mismatched~n", [length(Fails)]),
            halt(1)
    end.

%% --- fixtures ----------------------------------------------------------------

%% `state` passed directly (not `target_zone`) — the no-PG conformance convention
%% (fh_engine_store:projection_state/1's own doc comment), avoids a DB call.
onboarding() ->
    #{<<"target_price_range">> => [900000, 1100000],
      <<"state">> => <<"VIC">>}.

base_args() -> #{onboarding => onboarding(), firb_required_any => false}.

profile_no_existing_facts() ->
    #{<<"target_price_range">> => [900000, 1100000],
      <<"existing_home_ownership">> => #{
          <<"currently_owns_ppor">> => true,
          <<"ppor_estimated_value">> => null,
          <<"ppor_outstanding_loan_balance">> => null,
          <<"ppor_loan_rate_type">> => null,
          <<"ppor_rental_history">> => false
      }}.

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

g(M, K) -> maps:get(K, M).

%% --- 1. existing_home_disposal — base case, honest-partial ------------------

existing_home_base_case() ->
    Upstream = #{<<"profile">> => profile_no_existing_facts()},
    {O, Renderer, Kb} = fh_engine_fill:resolver(<<"existing_home_disposal">>, #{}, Upstream),
    [check("renderer = calculator", Renderer, <<"calculator">>),
     check("estimated_sale_price null (no onboarding capture)", g(O, <<"estimated_sale_price">>), null),
     check("loan_payout.outstanding_balance null", maps:get(<<"outstanding_balance">>, g(O, <<"loan_payout">>)), null),
     check("loan_payout.total_payout null", maps:get(<<"total_payout">>, g(O, <<"loan_payout">>)), null),
     check("selling_costs null (no sale price to band)", g(O, <<"selling_costs">>), null),
     check("net_sale_proceeds null (honest-partial)", g(O, <<"net_sale_proceeds">>), null),
     check("settlement_timing_mismatch false (no dates known)", g(O, <<"settlement_timing_mismatch">>), false),
     check("bridging_finance_considered false", g(O, <<"bridging_finance_considered">>), false),
     check("bridging_finance_is_placeholder true (always)", g(O, <<"bridging_finance_is_placeholder">>), true),
     check("kb_anchors non-empty", length(Kb) > 0, true)].

%% --- 2. existing_home_disposal — variable-rate, known facts -----------------

existing_home_variable_rate_case() ->
    Upstream = #{<<"profile">> => profile_with_facts(<<"variable">>, false)},
    {O, _, _} = fh_engine_fill:resolver(<<"existing_home_disposal">>, #{}, Upstream),
    LoanPayout = g(O, <<"loan_payout">>),
    [check("break_cost_status = not_applicable (variable, exit-fee ban)",
           maps:get(<<"break_cost_status">>, LoanPayout), <<"not_applicable">>),
     check("discharge_fee is a [Lo, Hi] band", is_list(maps:get(<<"discharge_fee">>, LoanPayout)), true),
     check("total_payout computed (outstanding_balance + discharge_fee)",
           is_list(maps:get(<<"total_payout">>, LoanPayout)), true),
     check("cgt_status = exempt (sole occupier, resident, no rental history)",
           g(O, <<"cgt_status">>), <<"exempt">>),
     check("cgt = null (Mode-E never estimates a taxable gain, reused disposition logic)",
           g(O, <<"cgt">>), null),
     check("selling_costs computed (REUSED fh_engine_disposition:selling_costs/1)",
           is_list(g(O, <<"selling_costs">>)), true),
     check("net_sale_proceeds computed (all four contributing figures known)",
           is_list(g(O, <<"net_sale_proceeds">>)), true)].

%% --- 3. existing_home_disposal — fixed-rate: break cost NEVER estimated -----

existing_home_fixed_rate_case() ->
    Upstream = #{<<"profile">> => profile_with_facts(<<"fixed">>, false)},
    {O, _, _} = fh_engine_fill:resolver(<<"existing_home_disposal">>, #{}, Upstream),
    LoanPayout = g(O, <<"loan_payout">>),
    [check("break_cost_status = to_verify (fixed-rate)",
           maps:get(<<"break_cost_status">>, LoanPayout), <<"to_verify">>),
     check("total_payout NULL (break cost is an unknown addend, never guessed)",
           maps:get(<<"total_payout">>, LoanPayout), null),
     check("net_sale_proceeds NULL (honest-partial propagates from the unknown payout)",
           g(O, <<"net_sale_proceeds">>), null),
     check("selling_costs STILL computed (independent of the loan-payout unknown)",
           is_list(g(O, <<"selling_costs">>)), true)].

%% --- 4. existing_home_disposal — rental history flips CGT to to_verify -----

existing_home_rental_history_case() ->
    Upstream = #{<<"profile">> => profile_with_facts(<<"variable">>, true)},
    {O, _, _} = fh_engine_fill:resolver(<<"existing_home_disposal">>, #{}, Upstream),
    [check("cgt_status = to_verify (rental history breaks the clean exemption)",
           g(O, <<"cgt_status">>), <<"to_verify">>),
     check("net_sale_proceeds NULL (cgt_contribution unknown, honest-partial)",
           g(O, <<"net_sale_proceeds">>), null)].

%% --- 5. cash_position — the Mode-E branch (fill_fhb_nexthome) ---------------

cash_position_nexthome_cases() ->
    ExistingHome = #{<<"net_sale_proceeds">> => [350000, 380000]},
    Upstream = #{<<"profile">> => profile_with_facts(<<"variable">>, false),
                 <<"mortgage_plan">> => #{<<"recommended_path">> => <<"lmi_5_to_20">>},
                 <<"existing_home_disposal">> => ExistingHome},
    {O, Renderer, Kb} = fh_engine_cash:fill(base_args(), Upstream),
    Sd = g(O, <<"stamp_duty">>),
    [check("renderer = calculator", Renderer, <<"calculator">>),
     check("stamp_duty.concession_applied = 0 (no scheme_stack — full duty, correct for a repeat buyer)",
           maps:get(<<"concession_applied">>, Sd), 0),
     check("cash_available = existing_home_disposal.net_sale_proceeds (folded HAVE side)",
           g(O, <<"cash_available">>), [350000, 380000]),
     check("gap_or_surplus non-null (both sides known)", g(O, <<"gap_or_surplus">>) =/= null, true),
     check("verdict is one of surplus/tight/short",
           lists:member(g(O, <<"verdict">>), [<<"surplus">>, <<"tight">>, <<"short">>]), true),
     check("no kb.scheme.fhg anchor listed (never FHG-eligible)",
           lists:any(fun(A) -> maps:get(<<"slug">>, A, <<>>) =:= <<"kb:kb.scheme.fhg">> end, Kb), false)].

%% --- 6. cash_position — Mode-A regression (no existing_home_disposal) -------

cash_position_regression_cases() ->
    Upstream = #{<<"profile">> => #{<<"target_price_range">> => [900000, 1100000]},
                 <<"scheme_stack">> => #{<<"applicable_schemes">> => []},
                 <<"mortgage_plan">> => #{<<"recommended_path">> => <<"lmi_5_to_20">>}},
    {O, _, _} = fh_engine_cash:fill(base_args(), Upstream),
    [check("Mode-A regression: cash_available still null (no existing_home_disposal ⟹ fill_fhb/2, unchanged)",
           g(O, <<"cash_available">>), null),
     check("Mode-A regression: verdict still null at base", g(O, <<"verdict">>), null)].

%% --- 7. mortgage_finance — reused unchanged (no scheme_stack) ---------------

mortgage_reuse_cases() ->
    Upstream = #{<<"profile">> => profile_with_facts(<<"variable">>, false)},
    {O, _, _} = fh_engine_mortgage:fill(base_args(), Upstream),
    [check("recommended_path never fhg_backed for Mode E (no scheme_stack ⟹ has_fhg(#{}) = false)",
           g(O, <<"recommended_path">>) =/= <<"fhg_backed">>, true)].

%% --- 8. disposition — reused unchanged (owner-occupier path) ----------------

disposition_reuse_cases() ->
    ProfileBase = profile_with_facts(<<"variable">>, false),
    Profile = ProfileBase#{<<"intended_occupancy_use">> => <<"sole_occupier">>},
    Upstream = #{<<"profile">> => Profile,
                 <<"budget_envelope">> => #{<<"total_cash_required">> => [200000, 220000]},
                 <<"mortgage_plan">> => #{<<"expected_borrowing_capacity">> => null},
                 <<"ongoing_obligations">> => #{}},
    {O, Renderer, _} = fh_engine_disposition:fill(#{}, Upstream),
    [check("renderer = calculator", Renderer, <<"calculator">>),
     check("cgt_status = exempt (owner-occupier path, unchanged dispatch)",
           g(O, <<"cgt_status">>), <<"exempt">>),
     check("horizon_years null (no hold_horizon_years set — no disposal projection at base)",
           g(O, <<"horizon_years">>), null)].

%% --- helpers ------------------------------------------------------------------

check(Label, Got, Want) ->
    case Got =:= Want of
        true  -> io:format("  PASS   ~ts~n", [Label]), pass;
        false -> io:format("  FAIL   ~ts = ~p, expected ~p~n", [Label, Got, Want]), fail
    end.
