#!/usr/bin/env escript
%%! -sname fh_cash_position_foreign_conformance
%%
%% Conformance suite for the `cash_position` MODE-B (foreign-person) variant
%% (fh_engine_cash:fill_fhb_foreign/2 — blueprint fhb-foreign-au.md component 6,
%% mode-b-wedge.md P2 slice 4). THIRD shared-name branch (Mode A / Mode B / Mode C all
%% named `cash_position`): fill/2 routes on the `tax_optimised_structure` upstream FIRST
%% (investor axis, unchanged), then on Args.firb_required_any (foreign axis, orthogonal —
%% the SAME flag buyer_profile/1, mortgage_finance, and the compliance FIRB gate key on)
%% within the non-investor path. The Mode-A FHB body is byte-identical (zero regression).
%% Loads the SAME materialized artifact the engine loads and asserts:
%%   1. SCAFFOLD — the Mode-B budget_envelope is a THIRD, different 10-field shape from
%%      both Mode A's (duty subtree + cash_events) and Mode C's investor point-summary.
%%      actual_property_price / max_property_price_supported stay null (honest-partial
%%      naming discipline — no attached property, no borrowing capacity yet); the NEED
%%      side (regulatory_imposts_total, channel_costs_total, total_cash_required) is
%%      computed off the CONSERVATIVE ceiling — composed from PLACED figures (firb_status'
%%      own fee, mortgage_plan's own deposit), never recomputed.
%%   2. THE SURCHARGE SCHEDULE — every state's rate (kb.foreign-buyer-surcharge.by-state),
%%      ACT/NT nil, an unmodelled state null.
%%   3. THE GAP/VERDICT — surplus when capacity > required, short when capacity < required,
%%      null/null when either side is unknown (never a partial verdict).
%%   4. THE HONEST-PARTIAL COMPOSITION HELPERS — sum_or_null never returns a partial sum.
%%   5. NO REGRESSION — the Mode-A FHB path (no firb_required_any) is untouched: still the
%%      duty-subtree budget_envelope shape, still passes Layer-1 validate/3, has NO
%%      regulatory_imposts_total/channel_costs_total fields.
%%
%% Run from engine/erlang with the build libs on the path (no Postgres, no live model):
%%   ERL_LIBS=_build/default/lib escript test/cash_position_foreign_conformance.escript

-mode(compile).

-define(FHB, <<"fhb-domestic-au">>).

main(_) ->
    ok = fh_engine_kb:load(),
    io:format("cash_position_foreign conformance — fh_engine_cash (Mode-B)~n~n"),
    R = lists:flatten([scaffold_cases(), surcharge_schedule_cases(), gap_verdict_cases(),
                       composition_helper_cases(), no_regression_cases()]),
    Fails = [X || X <- R, X =:= fail],
    io:format("~n================================================================~n"),
    case Fails of
        [] -> io:format("PASS — all ~p cash_position_foreign anchors hold~n", [length(R)]), halt(0);
        _  -> io:format("FAIL — ~p anchor(s) mismatched~n", [length(Fails)]), halt(1)
    end.

%% --- fixtures ----------------------------------------------------------------

fields() ->
    [<<"max_property_price_supported">>, <<"actual_property_price">>,
     <<"total_cash_required">>, <<"regulatory_imposts_total">>, <<"channel_costs_total">>,
     <<"family_capacity_available">>, <<"gap_or_surplus">>, <<"verdict">>,
     <<"mitigation_options_if_short">>, <<"key_assumptions">>].

fixture_upstream(Capacity) ->
    #{<<"profile">> => #{<<"target_price_range">> => [700000, 900000],
                         <<"deposit_ready_for_purchase_amount">> => Capacity},
      <<"firb_status">> => #{<<"total_firb_fee_payable">> => 15100},
      <<"mortgage_plan">> => #{<<"deposit_required">> => 270000}}.

fixture_args() ->
    #{firb_required_any => true, onboarding => #{<<"state">> => <<"NSW">>}}.

scaffold() ->
    fh_engine_fill:resolver(<<"cash_position">>, fixture_args(), fixture_upstream(null)).

g(O, K) -> maps:get(K, O, undefined).

%% --- 1. scaffold (resolver half) ---------------------------------------------

scaffold_cases() ->
    {O, Rend, Kb} = scaffold(),
    KbSlugs = [maps:get(<<"slug">>, E) || E <- Kb],
    DutyAfter = maps:get(<<"after_concession">>,
                          fh_engine_cash:stamp_duty(<<"NSW">>, false, 900000)),
    Surcharge = fh_engine_cash:surcharge_amount(<<"NSW">>, 900000),
    ExpectedImposts = fh_engine_cash:sum_or_null([DutyAfter, Surcharge, 15100, 0]),
    ExpectedChannel = fh_engine_cash:channel_costs(<<"NSW">>, 900000),
    ExpectedTotal = fh_engine_cash:sum_or_null([270000, ExpectedImposts, ExpectedChannel]),
    [check("renderer = calculator", Rend, <<"calculator">>),
     check("outcome has exactly the ten Mode-B budget_envelope fields",
           lists:sort(maps:keys(O)), lists:sort(fields())),
     check("actual_property_price = null (no property attached — honest naming)",
           g(O, <<"actual_property_price">>), null),
     check("max_property_price_supported = null (no borrowing capacity yet)",
           g(O, <<"max_property_price_supported">>), null),
     check("regulatory_imposts_total = duty + surcharge + firb_fee + 0 (LMI)",
           g(O, <<"regulatory_imposts_total">>), ExpectedImposts),
     check("channel_costs_total = registration + convention band",
           g(O, <<"channel_costs_total">>), ExpectedChannel),
     check("total_cash_required = deposit + imposts + channel_costs",
           g(O, <<"total_cash_required">>), ExpectedTotal),
     check("family_capacity_available = null (deposit_ready_for_purchase_amount unset)",
           g(O, <<"family_capacity_available">>), null),
     check("gap_or_surplus = null (capacity unknown — never a partial verdict)",
           g(O, <<"gap_or_surplus">>), null),
     check("verdict = null (capacity unknown)", g(O, <<"verdict">>), null),
     check("mitigation_options_if_short = []", g(O, <<"mitigation_options_if_short">>), []),
     check("key_assumptions has four bilingual entries",
           length(g(O, <<"key_assumptions">>)), 4),
     check("kb_versions = the seven Mode-B cash anchors",
           lists:sort(KbSlugs),
           lists:sort([<<"kb.stamp-duty.calc-by-state">>,
                       <<"kb.foreign-buyer-surcharge.by-state">>,
                       <<"kb.firb.fee-schedule-current">>,
                       <<"kb.fx.typical-spreads-vnd-aud">>,
                       <<"kb.buyer-costs.inspections-conveyancing-fees">>,
                       <<"kb.cash-reserve.lender-expectations">>,
                       <<"kb.lmi.calculation-for-foreign-persons">>])),
     check("has_resolver true", fh_engine_fill:has_resolver(<<"cash_position">>), true)].

%% --- 2. the surcharge schedule -------------------------------------------------

surcharge_schedule_cases() ->
    [check("NSW surcharge = 9%", fh_engine_cash:surcharge_pct(<<"NSW">>), 9),
     check("VIC surcharge = 8%", fh_engine_cash:surcharge_pct(<<"VIC">>), 8),
     check("QLD surcharge = 8%", fh_engine_cash:surcharge_pct(<<"QLD">>), 8),
     check("WA surcharge = 7%", fh_engine_cash:surcharge_pct(<<"WA">>), 7),
     check("SA surcharge = 7%", fh_engine_cash:surcharge_pct(<<"SA">>), 7),
     check("TAS surcharge = 8%", fh_engine_cash:surcharge_pct(<<"TAS">>), 8),
     check("ACT surcharge = 0 (no duty surcharge)", fh_engine_cash:surcharge_pct(<<"ACT">>), 0),
     check("NT surcharge = 0 (no duty surcharge)", fh_engine_cash:surcharge_pct(<<"NT">>), 0),
     check("surcharge_amount(NSW, 1000000) = 90000",
           fh_engine_cash:surcharge_amount(<<"NSW">>, 1000000), 90000),
     check("surcharge_amount(ACT, 1000000) = 0",
           fh_engine_cash:surcharge_amount(<<"ACT">>, 1000000), 0),
     check("surcharge_amount(undefined, 1000000) = null (unknown state)",
           fh_engine_cash:surcharge_amount(undefined, 1000000), null),
     check("surcharge_amount(NSW, null) = null (no price)",
           fh_engine_cash:surcharge_amount(<<"NSW">>, null), null)].

%% --- 3. the gap / verdict -------------------------------------------------------

gap_verdict_cases() ->
    {OSurplus, _, _} = fh_engine_fill:resolver(<<"cash_position">>, fixture_args(),
        fixture_upstream(5000000)),
    {OShort, _, _} = fh_engine_fill:resolver(<<"cash_position">>, fixture_args(),
        fixture_upstream(10000)),
    [check("high capacity -> verdict = surplus", g(OSurplus, <<"verdict">>), <<"surplus">>),
     check("high capacity -> gap_or_surplus positive",
           g(OSurplus, <<"gap_or_surplus">>) > 0, true),
     check("low capacity -> verdict = short", g(OShort, <<"verdict">>), <<"short">>),
     check("low capacity -> gap_or_surplus negative",
           g(OShort, <<"gap_or_surplus">>) < 0, true)].

%% --- 4. the honest-partial composition helper -----------------------------------

composition_helper_cases() ->
    [check("sum_or_null([1,2,3]) = 6", fh_engine_cash:sum_or_null([1, 2, 3]), 6),
     check("sum_or_null([1,2,null]) = null (never a partial sum)",
           fh_engine_cash:sum_or_null([1, 2, null]), null),
     check("sum_or_null([]) = 0", fh_engine_cash:sum_or_null([]), 0)].

%% --- 5. no regression (the Mode-A FHB cash_position path) ----------------------

no_regression_cases() ->
    {Fhb, FhbRend, _} = fh_engine_fill:resolver(<<"cash_position">>,
        #{onboarding => #{<<"state">> => <<"NSW">>,
                          <<"target_price_range">> => [600000, 700000]}},
        #{<<"profile">> => #{},
          <<"scheme_stack">> => #{<<"applicable_schemes">> => []},
          <<"mortgage_plan">> => #{}}),
    V = try fh_engine_outcome:validate(?FHB, <<"budget_envelope">>, Fhb), ok
        catch _:Why -> {error, Why} end,
    [check("FHB cash_position renderer still calculator", FhbRend, <<"calculator">>),
     check("FHB has NO regulatory_imposts_total field",
           maps:is_key(<<"regulatory_imposts_total">>, Fhb), false),
     check("FHB has NO channel_costs_total field",
           maps:is_key(<<"channel_costs_total">>, Fhb), false),
     check("FHB still has the stamp_duty subtree (Mode-A-only shape)",
           maps:is_key(<<"stamp_duty">>, Fhb), true),
     check("Layer-1 conforms: FHB budget_envelope (no regression)", V, ok)].

%% --- helpers ----------------------------------------------------------------

check(Label, Got, Want) ->
    case Got =:= Want of
        true  -> io:format("  PASS   ~ts~n", [Label]), pass;
        false -> io:format("  FAIL   ~ts = ~p, expected ~p~n", [Label, Got, Want]), fail
    end.
