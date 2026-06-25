#!/usr/bin/env escript
%%! -sname fh_cash_position_investor_conformance
%%
%% Conformance suite for the `cash_position` INVESTOR variant (fh_engine_cash:fill_investor/2 —
%% the investor base spine, blueprint component 7; a PURE-resolver figure-owner, agent_leaves = [],
%% the same class as yield_modelling/disposition). cash_position is the first investor component
%% that SHARES a name with an FHB component: fh_engine_cash:fill/2 dispatches on the
%% `tax_optimised_structure` upstream discriminator (mirrors fh_engine_disposition) — present →
%% the investor budget_envelope_investor; absent → the Mode-A FHB budget_envelope. Loads the SAME
%% materialized artifact the engine loads (priv/kb/artifact.json) and asserts:
%%   1. SCAFFOLD — the investor branch owns the `calculator` renderer + the six cash KB anchors,
%%      and (plan-first: no property, no savings at base) leaves every one of the nine
%%      budget_envelope_investor figures null, mitigation_options_if_short empty. Input-independent
%%      at base. has_resolver true.
%%   2. LAYER-1 CONFORMANCE — the scaffold passes fh_engine_outcome:validate/3 against the
%%      compiled `budget_envelope_investor` schema (null conforms to any field; [] conforms to
%%      array<string>).
%%   3. MODE DISCRIMINATOR — tax_optimised_structure present routes to the investor branch (the
%%      9-field set, NO FHB stamp_duty key); absent routes to the FHB branch (a budget_envelope
%%      with a stamp_duty key, validating as budget_envelope). The two never cross.
%%   4. NO REGRESSION — the FHB path is byte-identical to its prior self (the discriminator is a
%%      pure rename + wrapper): an FHB-shaped upstream still produces the budget_envelope stamp_duty
%%      sub-tree; yield_modelling stays pure-resolver; cash_position has_resolver still true.
%%      (The dollar-exact FHB duty anchors are covered by cash_duty_conformance.escript.)
%%
%% Run from engine/erlang with the build libs on the path (no Postgres, no live model):
%%   ERL_LIBS=_build/default/lib escript test/cash_position_investor_conformance.escript

-mode(compile).

-define(INV, <<"investor-domestic-au">>).
-define(FHB, <<"fhb-domestic-au">>).

main(_) ->
    ok = fh_engine_kb:load(),
    io:format("cash_position investor conformance — fh_engine_cash (Mode-C pure-resolver)~n~n"),
    R = lists:flatten([scaffold_cases(), layer1_cases(), discriminator_cases(),
                       no_regression_cases(), per_property_cases()]),
    Fails = [X || X <- R, X =:= fail],
    io:format("~n================================================================~n"),
    case Fails of
        [] -> io:format("PASS — all ~p cash_position investor anchors hold~n", [length(R)]), halt(0);
        _  -> io:format("FAIL — ~p anchor(s) mismatched~n", [length(Fails)]), halt(1)
    end.

%% --- fixtures ----------------------------------------------------------------

%% the nine budget_envelope_investor figure fields the registry declares.
fields() ->
    [<<"actual_property_price">>, <<"max_property_price_supported">>,
     <<"total_cash_required">>, <<"loan_amount">>, <<"lvr">>, <<"lmi_payable">>,
     <<"gap_or_surplus">>, <<"verdict">>, <<"mitigation_options_if_short">>].

%% the eight fields that are null at base (everything except the empty mitigation list).
null_at_base() ->
    [<<"actual_property_price">>, <<"max_property_price_supported">>,
     <<"total_cash_required">>, <<"loan_amount">>, <<"lvr">>, <<"lmi_payable">>,
     <<"gap_or_surplus">>, <<"verdict">>].

%% an investor base upstream: profile + tax_optimised_structure present (the discriminator),
%% property_fit_investor absent (no property at base).
inv_upstream() ->
    #{<<"profile">> => #{<<"applicant_count">> => 1,
                        <<"target_price_range">> => [600000, 800000],
                        <<"target_zone">> => [<<"Footscray">>]},
      <<"tax_optimised_structure">> => #{<<"recommended_entity">> => <<"personal_sole">>,
                                         <<"cgt_discount_eligible">> => true}}.

%% a minimal FHB upstream (no tax_optimised_structure → routes to the FHB branch). State unknown
%% (onboarding empty) → stamp_duty pending; enough to prove the FHB shape, not its duty figures.
fhb_upstream() ->
    #{<<"profile">> => #{<<"target_price_range">> => [600000, 800000]},
      <<"scheme_stack">> => #{}, <<"mortgage_plan">> => #{}}.

inv_scaffold() ->
    fh_engine_fill:resolver(<<"cash_position">>, #{}, inv_upstream()).

g(O, K) -> maps:get(K, O, undefined).

%% --- 1. scaffold -------------------------------------------------------------

scaffold_cases() ->
    {O, Rend, Kb} = inv_scaffold(),
    %% input-independent at base: the only required key is the tax_optimised_structure
    %% discriminator; with it (and nothing else) the outcome is identical.
    {OBare, _, _} = fh_engine_fill:resolver(<<"cash_position">>, #{},
                                            #{<<"tax_optimised_structure">> => #{}}),
    KbSlugs = [maps:get(<<"slug">>, E) || E <- Kb],
    NullChecks =
        [check(<<"figure null at base: ", F/binary>>, g(O, F), null) || F <- null_at_base()],
    BareChecks =
        [check(<<"input-independent (bare upstream) null: ", F/binary>>, g(OBare, F), null)
         || F <- null_at_base()],
    [check("renderer = calculator", Rend, <<"calculator">>),
     check("outcome has exactly the nine budget_envelope_investor fields",
           lists:sort(maps:keys(O)), lists:sort(fields())),
     check("mitigation_options_if_short = [] (honest empty, no shortfall known)",
           g(O, <<"mitigation_options_if_short">>), []),
     check("kb_versions = the six cash anchors",
           lists:sort(KbSlugs),
           lists:sort([<<"kb.stamp-duty.calc-by-state">>,
                       <<"kb.investor.deposit-requirements-investment-loans">>,
                       <<"kb.lmi.calculation">>,
                       <<"kb.buyer-costs.investor-additional-costs">>,
                       <<"kb.tax.quantity-surveyor-reports">>,
                       <<"kb.tax.entity-setup-costs">>])),
     check("has_resolver true (classified as resolver, pure)",
           fh_engine_fill:has_resolver(<<"cash_position">>), true)]
    ++ NullChecks ++ BareChecks.

%% --- 2. Layer-1 conformance (the fail-closed commit seam) -------------------

layer1_cases() ->
    {O, _, _} = inv_scaffold(),
    [check(<<"Layer-1 conforms: investor scaffold (nulls + empty mitigation)">>,
           validate(?INV, <<"budget_envelope_investor">>, O), ok)].

validate(Bp, Type, O) ->
    try fh_engine_outcome:validate(Bp, Type, O), ok
    catch _:Why -> {error, Why} end.

%% --- 3. mode discriminator ---------------------------------------------------

discriminator_cases() ->
    {Inv, _, _} = fh_engine_fill:resolver(<<"cash_position">>, #{}, inv_upstream()),
    {Fhb, FhbRend, _} = fh_engine_fill:resolver(<<"cash_position">>, #{}, fhb_upstream()),
    [check("present → investor branch (nine-field set)",
           lists:sort(maps:keys(Inv)), lists:sort(fields())),
     check("present → investor branch has NO FHB stamp_duty key",
           maps:is_key(<<"stamp_duty">>, Inv), false),
     check("absent → FHB branch (budget_envelope has a stamp_duty key)",
           maps:is_key(<<"stamp_duty">>, Fhb), true),
     check("absent → FHB branch is NOT the investor field set",
           maps:is_key(<<"lvr">>, Fhb), false),
     check("FHB branch renderer = calculator", FhbRend, <<"calculator">>)].

%% --- 4. no regression --------------------------------------------------------

no_regression_cases() ->
    %% the FHB path still produces the budget_envelope stamp_duty sub-tree and validates as
    %% budget_envelope (the discriminator is a pure rename + wrapper — byte-identical FHB output).
    {Fhb, _, _} = fh_engine_fill:resolver(<<"cash_position">>, #{}, fhb_upstream()),
    %% yield_modelling stays PURE-resolver (no merge clause → calling it errors).
    YmErrs = errors(fun() -> fh_engine_fill:merge_agent(<<"yield_modelling">>, #{}, #{}) end),
    [check("FHB budget_envelope still validates", validate(?FHB, <<"budget_envelope">>, Fhb), ok),
     check("FHB stamp_duty sub-tree present (after_concession key)",
           maps:is_key(<<"after_concession">>, maps:get(<<"stamp_duty">>, Fhb, #{})), true),
     check("yield_modelling still pure-resolver (no merge → error)", YmErrs, true),
     check("cash_position has_resolver still true",
           fh_engine_fill:has_resolver(<<"cash_position">>), true)].

%% --- 5. per-property cash-to-complete (Slice B3b) ----------------------------

%% the investor upstream + an attached property (NSW established_house @ $920k — the seam fixture).
pf_upstream() ->
    (inv_upstream())#{<<"property_fit_investor">> =>
        #{<<"price">> => 920000, <<"state">> => <<"NSW">>,
          <<"suburb">> => <<"Cabramatta">>, <<"property_type">> => <<"established_house">>}}.

per_property_cases() ->
    {O, _, _} = fh_engine_fill:resolver(<<"cash_position">>, #{}, pf_upstream()),
    %% recompute the regulated components via the EXPORTED helpers (non-tautological):
    Duty  = maps:get(<<"after_concession">>, fh_engine_cash:stamp_duty(<<"NSW">>, false, 920000)),
    Reg   = fh_engine_cash:registration_total(<<"NSW">>, 920000),
    Total = g(O, <<"total_cash_required">>),
    Deposit = 920000 - 736000,                  %% 20% of price = 184000
    Acq   = Total - Deposit - Duty,             %% the acquisition adders (reg + conveyancing midpoint)
    [check("per-property: actual_property_price = 920000", g(O, <<"actual_property_price">>), 920000),
     check("per-property: loan_amount = 736000 (price × 80% LVR baseline)",
           g(O, <<"loan_amount">>), 736000),
     check("per-property: lvr = 80", g(O, <<"lvr">>), 80),
     check("per-property: lmi_payable = 0 (80% baseline → no LMI)", g(O, <<"lmi_payable">>), 0),
     check("per-property: total_cash_required is an integer scalar (price-point, NOT banded)",
           is_integer(Total), true),
     check("per-property: duty included (NSW standard, no concession) > 0", Duty > 0, true),
     check("per-property: total = deposit + duty + acquisition adders (acq > 0)",
           Total > Deposit + Duty, true),
     check("per-property: acquisition adders = registration + conveyancing/inspection midpoint",
           Acq > Reg andalso (Acq - Reg) > 500 andalso (Acq - Reg) < 8000, true),
     check("per-property: max_property_price_supported null (capacity → income/refine)",
           g(O, <<"max_property_price_supported">>), null),
     check("per-property: gap_or_surplus null (HAVE-side → refine)",
           g(O, <<"gap_or_surplus">>), null),
     check("per-property: verdict null (needs gap_or_surplus)", g(O, <<"verdict">>), null),
     check("per-property: Layer-1 conforms (scalar money figures)",
           validate(?INV, <<"budget_envelope_investor">>, O), ok)].

%% --- helpers ----------------------------------------------------------------

errors(F) ->
    try F(), false catch _:_ -> true end.

check(Label, Got, Want) ->
    case Got =:= Want of
        true  -> io:format("  PASS   ~ts~n", [Label]), pass;
        false -> io:format("  FAIL   ~ts = ~p, expected ~p~n", [Label, Got, Want]), fail
    end.
