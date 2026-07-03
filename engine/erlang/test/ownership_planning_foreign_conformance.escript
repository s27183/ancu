#!/usr/bin/env escript
%%! -sname fh_ownership_planning_foreign_conformance
%%
%% Conformance suite for the `ownership_planning` MODE-B (foreign-person) variant
%% (fh_engine_ownership:fill_foreign/2 — blueprint fhb-foreign-au.md component 11,
%% mode-b-wedge.md P2 slice 5). THE FIRST REAL BRANCH `fill/2` has ever had (Mode A/B
%% share the component name `ownership_planning`, unlike Mode C's distinct
%% `ownership_planning_investor`) — discriminated by Args.firb_required_any, the SAME
%% flag every other Mode-B branch built in P2 keys on. The Mode-A body (fill_domestic/2,
%% renamed verbatim) is byte-identical — zero regression. Loads the SAME materialized
%% artifact the engine loads and asserts:
%%   1. SCAFFOLD — the Mode-B ongoing_obligations is a DIFFERENT 7-field shape (vacancy
%%      fee + non-resident tax framing, no land_tax_check/graduation_milestone/FHG).
%%      vacancy_fee_at_risk_amount = 2× firb_workflow's OWN fee (PLACED, never
%%      recomputed from price); current_year_occupancy_status / non_resident_tax_
%%      filing_required stay null (a flagged gap — no occupancy-intent field exists yet
%%      upstream); mode_switch_eligible starts false (no status-change evidence at base).
%%   2. THE VACANCY-FEE MULTIPLIER — vacancy_fee_at_risk/1 doubles a known fee, stays
%%      null when the fee itself is unknown (never a fabricated amount).
%%   3. NO REGRESSION — the Mode-A path (no firb_required_any) is untouched: still the
%%      land-tax/graduation/FHG shape, still passes Layer-1 validate/3, has NO
%%      vacancy_fee_at_risk_amount/mode_switch_eligible fields.
%%
%% Run from engine/erlang with the build libs on the path (no Postgres, no live model):
%%   ERL_LIBS=_build/default/lib escript test/ownership_planning_foreign_conformance.escript

-mode(compile).

-define(FHB, <<"fhb-domestic-au">>).

main(_) ->
    ok = fh_engine_kb:load(),
    io:format("ownership_planning_foreign conformance — fh_engine_ownership (Mode-B)~n~n"),
    R = lists:flatten([scaffold_cases(), multiplier_cases(), no_regression_cases()]),
    Fails = [X || X <- R, X =:= fail],
    io:format("~n================================================================~n"),
    case Fails of
        [] -> io:format("PASS — all ~p ownership_planning_foreign anchors hold~n", [length(R)]), halt(0);
        _  -> io:format("FAIL — ~p anchor(s) mismatched~n", [length(Fails)]), halt(1)
    end.

%% --- fixtures ----------------------------------------------------------------

fields() ->
    [<<"total_monthly_outgoings_estimate">>, <<"total_annual_outgoings_estimate">>,
     <<"vacancy_fee_at_risk_amount">>, <<"current_year_occupancy_status">>,
     <<"non_resident_tax_filing_required">>, <<"alert_triggers_armed">>,
     <<"mode_switch_eligible">>].

foreign_args() -> #{firb_required_any => true}.

scaffold() ->
    fh_engine_fill:resolver(<<"ownership_planning">>, foreign_args(),
        #{<<"firb_status">> => #{<<"total_firb_fee_payable">> => 15100}}).

g(O, K) -> maps:get(K, O, undefined).

%% --- 1. scaffold (resolver half) ---------------------------------------------

scaffold_cases() ->
    {O, Rend, Kb} = scaffold(),
    {ONoFee, _, _} = fh_engine_fill:resolver(<<"ownership_planning">>, foreign_args(), #{}),
    KbSlugs = [maps:get(<<"slug">>, E) || E <- Kb],
    Alerts = g(O, <<"alert_triggers_armed">>),
    [check("renderer = data-table", Rend, <<"data-table">>),
     check("outcome has exactly the seven Mode-B ongoing_obligations fields",
           lists:sort(maps:keys(O)), lists:sort(fields())),
     check("total_monthly_outgoings_estimate = null (pending mortgage P&I)",
           g(O, <<"total_monthly_outgoings_estimate">>), null),
     check("total_annual_outgoings_estimate = null (as above)",
           g(O, <<"total_annual_outgoings_estimate">>), null),
     check("vacancy_fee_at_risk_amount = 30200 (2 x 15100, placed from firb_workflow)",
           g(O, <<"vacancy_fee_at_risk_amount">>), 30200),
     check("current_year_occupancy_status = null (occupancy intent not captured yet)",
           g(O, <<"current_year_occupancy_status">>), null),
     check("non_resident_tax_filing_required = null (as above)",
           g(O, <<"non_resident_tax_filing_required">>), null),
     check("mode_switch_eligible = false (no status-change evidence at base)",
           g(O, <<"mode_switch_eligible">>), false),
     check("alert_triggers_armed has two entries (vacancy + review)",
           length(Alerts), 2),
     check("kb_versions = the nine Mode-B ownership anchors",
           lists:sort(KbSlugs),
           lists:sort([<<"kb.ongoing-costs.rates-water-strata">>,
                       <<"kb.maintenance.budget-by-property-type">>,
                       <<"kb.graduation.lvr80">>, <<"kb.refinance.windows-and-triggers">>,
                       <<"kb.firb.vacancy-fee-rules-2026">>,
                       <<"kb.firb.vacancy-fee-double-from-2024">>,
                       <<"kb.non-resident-tax.cgt-no-ppor-exemption">>,
                       <<"kb.non-resident-tax.withholding-on-rental-income">>,
                       <<"kb.non-resident-tax.foreign-resident-cgt-withholding">>])),
     check("has_resolver true", fh_engine_fill:has_resolver(<<"ownership_planning">>), true),
     check("no firb_status upstream -> vacancy_fee_at_risk_amount null (honest, no fabrication)",
           g(ONoFee, <<"vacancy_fee_at_risk_amount">>), null)].

%% --- 2. the vacancy-fee multiplier -----------------------------------------------

multiplier_cases() ->
    [check("vacancy_fee_at_risk(null) = null", fh_engine_ownership:vacancy_fee_at_risk(null), null),
     check("vacancy_fee_at_risk(15100) = 30200", fh_engine_ownership:vacancy_fee_at_risk(15100), 30200),
     check("vacancy_fee_at_risk(60600) = 121200", fh_engine_ownership:vacancy_fee_at_risk(60600), 121200)].

%% --- 3. no regression (the Mode-A ownership_planning path) ----------------------

no_regression_cases() ->
    {Fhb, FhbRend, _} = fh_engine_fill:resolver(<<"ownership_planning">>,
        #{onboarding => #{<<"state">> => <<"NSW">>, <<"target_price_range">> => [600000, 700000]},
          intent => <<"owner_occupier">>},
        #{<<"scheme_stack">> => #{<<"applicable_schemes">> => []}}),
    V = try fh_engine_outcome:validate(?FHB, <<"ongoing_obligations">>, Fhb), ok
        catch _:Why -> {error, Why} end,
    [check("FHB ownership_planning renderer still data-table", FhbRend, <<"data-table">>),
     check("FHB has NO vacancy_fee_at_risk_amount field",
           maps:is_key(<<"vacancy_fee_at_risk_amount">>, Fhb), false),
     check("FHB has NO mode_switch_eligible field",
           maps:is_key(<<"mode_switch_eligible">>, Fhb), false),
     check("FHB still has land_tax_check (Mode-A-only shape)",
           maps:is_key(<<"land_tax_check">>, Fhb), true),
     check("FHB still has graduation_milestone (Mode-A-only shape)",
           maps:is_key(<<"graduation_milestone">>, Fhb), true),
     check("Layer-1 conforms: FHB ongoing_obligations (no regression)", V, ok)].

%% --- helpers ----------------------------------------------------------------

check(Label, Got, Want) ->
    case Got =:= Want of
        true  -> io:format("  PASS   ~ts~n", [Label]), pass;
        false -> io:format("  FAIL   ~ts = ~p, expected ~p~n", [Label, Got, Want]), fail
    end.
