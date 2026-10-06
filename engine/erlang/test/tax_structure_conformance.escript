#!/usr/bin/env escript
%%! -sname fh_tax_structure_conformance
%%
%% Conformance suite for the `tax_structure` resolver + two-path merge (fh_engine_fill — the
%% investor base spine, blueprint component 6; a TWO-PATH component, the same class as
%% investment_strategy: a resolver scaffold + ONE entity_structuring agent leaf folded by
%% merge_agent/3). Loads the SAME materialized artifact the engine loads (priv/kb/artifact.json)
%% and asserts what the base-spine presence relies on:
%%   1. SCAFFOLD — the resolver owns the data-table renderer + the six tax anchors (the
%%      method/figure audit trail), computes the two KB-grounded CGT determinant CONSTANTS
%%      (cgt_discount_eligible = true, cost_base_depreciation_clawback = true) that the built
%%      disposition consumer reads, leaves the entity agent slot null, and leaves every figure
%%      null (honest-partial: property/rent-dependent OR blocked by the banded-vs-scalar /
%%      ATO-brackets decisions deferred to property_assessment). Input-independent at base.
%%   2. LAYER-1 CONFORMANCE — the scaffold passes fh_engine_outcome:validate/3 against the
%%      compiled `tax_optimised_structure` schema (null conforms to any field; the two bool
%%      constants conform); and so does the MERGED outcome once a real entity is folded.
%%   3. TWO-PATH MERGE — merge_agent/3 folds EXACTLY the one entity leaf (recommended_entity)
%%      and leaves every resolver figure untouched (§98 — the agent authors no figure/verdict);
%%      a stray figure key in the agent values is NOT folded; agent_values_from_outcome/2
%%      round-trips the stored entity (the base_resolver-refresh inverse).
%%   4. NO REGRESSION — the new clauses are additive: yield_modelling stays PURE-resolver (no
%%      merge), investment_strategy (two-path) still dispatches resolver + merge.
%%
%% Run from engine/erlang with the build libs on the path (no Postgres, no live model):
%%   ERL_LIBS=_build/default/lib escript test/tax_structure_conformance.escript

-mode(compile).

-define(INV, <<"investor-domestic-au">>).

main(_) ->
    ok = fh_engine_kb:load(),
    io:format("tax_structure conformance — fh_engine_fill (Mode-C two-path)~n~n"),
    R = lists:flatten([scaffold_cases(), layer1_cases(), two_path_cases(),
                       per_property_cases(), reform_cases(), no_regression_cases()]),
    Fails = [X || X <- R, X =:= fail],
    io:format("~n================================================================~n"),
    case Fails of
        [] -> io:format("PASS — all ~p tax_structure anchors hold~n", [length(R)]), halt(0);
        _  -> io:format("FAIL — ~p anchor(s) mismatched~n", [length(Fails)]), halt(1)
    end.

%% --- fixtures ----------------------------------------------------------------

%% the tax_optimised_structure figure fields — the twelve the registry declares plus
%% cash_events (added 2026-07-10, task 4: the hold-phase tax-refund leg
%% purchase_journey/phase_playbook's generic harvest reads, fh_engine_fill:tax_cash_events/1).
fields() ->
    [<<"recommended_entity">>, <<"negative_gearing_active">>,
     <<"annual_tax_refund_year_1">>, <<"after_tax_cash_flow_year_1">>,
     <<"after_tax_cash_flow_per_week">>, <<"total_depreciation_year_1">>,
     <<"cgt_discount_eligible">>, <<"cgt_marginal_rate">>,
     <<"cost_base_depreciation_clawback">>, <<"annual_compliance_cost">>,
     <<"setup_costs">>, <<"negative_gearing_reform_note">>, <<"cash_events">>].

%% the eight fields that are null at base (everything except the two CGT determinant constants
%% and the agent slot — which is also null pre-merge, but tracked separately below).
null_at_base() ->
    [<<"recommended_entity">>, <<"negative_gearing_active">>,
     <<"annual_tax_refund_year_1">>, <<"after_tax_cash_flow_year_1">>,
     <<"after_tax_cash_flow_per_week">>, <<"total_depreciation_year_1">>,
     <<"cgt_marginal_rate">>, <<"annual_compliance_cost">>, <<"setup_costs">>].

%% a realistic base investor upstream (profile + strategy_thesis present; property absent).
upstream() ->
    #{<<"profile">> => #{<<"applicant_count">> => 1,
                         <<"target_price_range">> => [600000, 800000],
                         <<"target_zone">> => [<<"Footscray">>]},
      <<"strategy_thesis">> => #{<<"archetype">> => <<"capital_growth">>,
                                 <<"hold_period_years">> => 10}}.

scaffold(Upstream) ->
    fh_engine_fill:resolver(<<"tax_structure">>, #{}, Upstream).

g(O, K) -> maps:get(K, O, undefined).

%% --- 1. scaffold -------------------------------------------------------------

scaffold_cases() ->
    {O, Rend, Kb} = scaffold(upstream()),
    {OEmpty, _, _} = scaffold(#{}),     %% input-independent: empty upstream → same outcome.
    KbSlugs = [maps:get(<<"slug">>, E) || E <- Kb],
    NullChecks =
        [check(<<"figure null at base: ", F/binary>>, g(O, F), null) || F <- null_at_base()],
    EmptyChecks =
        [check(<<"input-independent (empty upstream) null: ", F/binary>>, g(OEmpty, F), null)
         || F <- null_at_base()],
    [check("renderer = data-table", Rend, <<"data-table">>),
     check("outcome has exactly the thirteen tax_optimised_structure fields",
           lists:sort(maps:keys(O)), lists:sort(fields())),
     check("cash_events = [] at base (honest empty, refund null pre-income)",
           g(O, <<"cash_events">>), []),
     %% the two KB-grounded CGT determinant CONSTANTS the disposition consumer reads.
     check("cgt_discount_eligible = true (resolver constant)",
           g(O, <<"cgt_discount_eligible">>), true),
     check("cost_base_depreciation_clawback = true (resolver constant → disposition to_verify)",
           g(O, <<"cost_base_depreciation_clawback">>), true),
     %% those two constants are input-independent too.
     check("cgt_discount_eligible constant on empty upstream",
           g(OEmpty, <<"cgt_discount_eligible">>), true),
     check("cost_base_depreciation_clawback constant on empty upstream",
           g(OEmpty, <<"cost_base_depreciation_clawback">>), true),
     check("recommended_entity null pre-merge (agent slot)",
           g(O, <<"recommended_entity">>), null),
     check("kb_versions = the six tax anchors",
           lists:sort(KbSlugs),
           lists:sort([<<"kb.tax.entity-comparison-personal-trust-company-smsf">>,
                       <<"kb.tax.negative-gearing-mechanics">>,
                       <<"kb.tax.depreciation-division-43-and-40">>,
                       <<"kb.tax.cgt-50-percent-discount">>,
                       <<"kb.tax.quantity-surveyor-reports">>,
                       <<"kb.tax.land-tax-by-state">>])),
     check("has_resolver true (classified as resolver, two-path)",
           fh_engine_fill:has_resolver(<<"tax_structure">>), true)]
    ++ NullChecks ++ EmptyChecks.

%% --- 2. Layer-1 conformance (the fail-closed commit seam) -------------------

layer1_cases() ->
    {O, _, _} = scaffold(upstream()),
    Merged = fh_engine_fill:merge_agent(<<"tax_structure">>, O,
                                        #{<<"recommended_entity">> => <<"personal_joint">>}),
    [check(<<"Layer-1 conforms: scaffold (nulls + bool constants)">>, validate(O), ok),
     check(<<"Layer-1 conforms: merged outcome (real entity folded)">>, validate(Merged), ok)].

validate(O) ->
    try fh_engine_outcome:validate(?INV, <<"tax_optimised_structure">>, O), ok
    catch _:Why -> {error, Why} end.

%% --- 3. two-path merge (the one entity leaf; §98 figure-tight) ---------------

two_path_cases() ->
    {O, _, _} = scaffold(upstream()),
    %% the agent reply carries the entity AND (adversarially) a stray figure key; merge_agent
    %% must fold ONLY recommended_entity and leave every resolver figure untouched (§98).
    Agent = #{<<"recommended_entity">> => <<"discretionary_trust">>,
              <<"setup_costs">> => 9999,            %% a figure the agent must NOT be able to set
              <<"cgt_discount_eligible">> => false}, %% a determinant the agent must NOT flip
    Merged = fh_engine_fill:merge_agent(<<"tax_structure">>, O, Agent),
    %% round-trip: recover the stored entity in the merge_agent-input shape.
    AV = fh_engine_fill:agent_values_from_outcome(
           <<"tax_structure">>,
           Merged#{<<"recommended_entity">> => <<"discretionary_trust">>}),
    [check("merge folds recommended_entity",
           g(Merged, <<"recommended_entity">>), <<"discretionary_trust">>),
     check("merge leaves cgt_discount_eligible untouched (§98 — agent can't flip a determinant)",
           g(Merged, <<"cgt_discount_eligible">>), true),
     check("merge leaves setup_costs null (§98 — agent can't author a figure)",
           g(Merged, <<"setup_costs">>), null),
     check("merge leaves cost_base_depreciation_clawback untouched",
           g(Merged, <<"cost_base_depreciation_clawback">>), true),
     check("merge does not add stray keys (field set unchanged)",
           lists:sort(maps:keys(Merged)), lists:sort(fields())),
     check("agent_values_from_outcome round-trips the entity",
           maps:get(<<"recommended_entity">>, AV), <<"discretionary_trust">>)].

%% --- 5. per-property figures (Slice B2 — class (a) rent/income-dependent) ----
%% Drives the REAL yield_modelling producer (no fabricated cash-flow band — the producer→consumer
%% contract under test, not a hand-built upstream) for a negatively-geared house, then exercises
%% tax_structure on (a) a per-property turn with NO income → the gearing position lights up but the
%% money figures stay null (honest-partial — marginal rate needs income, a refine turn), (b) a
%% refine turn WITH income → marginal rate + negative-gearing refund + after-tax cash flow compute
%% (bands, derived from the real Cf × the rate helper), and (c) a positively-geared property →
%% negative_gearing_active null, never false (depreciation is QS-deferred → tax position undetermined).

house_pf() ->
    #{<<"price">> => 920000,
      <<"property_type">> => <<"established_house">>,
      <<"estimated_weekly_rent_range">> => [620, 720]}.

real_cfp() ->
    {Cfp, _, _} = fh_engine_fill:resolver(<<"yield_modelling">>, #{},
                                          #{<<"property_fit_investor">> => house_pf()}),
    Cfp.

per_property_cases() ->
    Cfp    = real_cfp(),
    [CfLo, CfHi] = maps:get(<<"cash_flow_before_tax_year_1">>, Cfp),
    Geared = maps:get(<<"is_positive_neutral_or_negative_geared_pre_tax">>, Cfp),
    Income = 120000,
    Rate   = fh_engine_mortgage:marginal_rate(Income),    %% 30 (b2 bracket) + 2 (Medicare) = 32
    F      = (100 - Rate) / 100,
    ExpAt     = [round(CfLo * F), round(CfHi * F)],
    [AtLo, AtHi] = ExpAt,
    ExpRefund = [round(-Rate / 100 * CfHi), round(-Rate / 100 * CfLo)],
    ExpWeek   = [round(AtLo / 52), round(AtHi / 52)],
    %% (a) per-property, NO income.
    {ONoInc, _, _} = scaffold(#{<<"cash_flow_projection">> => Cfp,
                               <<"profile">> => #{<<"target_price_range">> => [800000, 1000000]}}),
    %% (b) refine turn, income captured.
    {OInc, _, _} = scaffold(#{<<"cash_flow_projection">> => Cfp,
                            <<"profile">> => #{<<"assessable_income">> => Income}}),
    %% (c) positively-geared property (income present).
    PosCfp = Cfp#{<<"cash_flow_before_tax_year_1">> => [4000, 9000],
                  <<"is_positive_neutral_or_negative_geared_pre_tax">> => <<"positive">>},
    {OPos, _, _} = scaffold(#{<<"cash_flow_projection">> => PosCfp,
                            <<"profile">> => #{<<"assessable_income">> => Income}}),
    [check("precondition: real yield_modelling produces a negatively-geared house",
           Geared, <<"negative">>),
     %% (a) no income → gearing lights up, money figures null
     check("no-income: negative_gearing_active = true (gearing needs only the cash flow)",
           g(ONoInc, <<"negative_gearing_active">>), true),
     check("no-income: cgt_marginal_rate null (income absent)",
           g(ONoInc, <<"cgt_marginal_rate">>), null),
     check("no-income: annual_tax_refund_year_1 null (rate absent)",
           g(ONoInc, <<"annual_tax_refund_year_1">>), null),
     check("no-income: after_tax_cash_flow_year_1 null",
           g(ONoInc, <<"after_tax_cash_flow_year_1">>), null),
     check("no-income: after_tax_cash_flow_per_week null",
           g(ONoInc, <<"after_tax_cash_flow_per_week">>), null),
     check("no-income: total_depreciation_year_1 null (QS-deferred)",
           g(ONoInc, <<"total_depreciation_year_1">>), null),
     check("no-income: cgt_discount_eligible constant still true",
           g(ONoInc, <<"cgt_discount_eligible">>), true),
     check("no-income: field set still the thirteen",
           lists:sort(maps:keys(ONoInc)), lists:sort(fields())),
     check("no-income: Layer-1 conforms", validate(ONoInc), ok),
     %% (b) income → computed
     check("marginal_rate(120000) = 32 (b2 bracket 30 + Medicare 2)", Rate, 32),
     check("income: negative_gearing_active = true",
           g(OInc, <<"negative_gearing_active">>), true),
     check("income: cgt_marginal_rate = the computed rate",
           g(OInc, <<"cgt_marginal_rate">>), Rate),
     check("income: annual_tax_refund_year_1 = −r × Cf band (a positive refund on the loss)",
           g(OInc, <<"annual_tax_refund_year_1">>), ExpRefund),
     check("income: refund is positive (a saving, not a charge)",
           hd(ExpRefund) > 0, true),
     check("income: after_tax_cash_flow_year_1 = Cf × (1 − r) band",
           g(OInc, <<"after_tax_cash_flow_year_1">>), ExpAt),
     check("income: after_tax_cash_flow_per_week band",
           g(OInc, <<"after_tax_cash_flow_per_week">>), ExpWeek),
     check("income: after-tax less-negative than pre-tax (the refund softens the loss)",
           AtLo > CfLo andalso AtHi > CfHi, true),
     check("income: Layer-1 conforms (banded after-tax money_range)", validate(OInc), ok),
     %% (c) positive gearing → null, never false
     check("positive-geared: negative_gearing_active null (never false — depreciation undetermined)",
           g(OPos, <<"negative_gearing_active">>), null),
     check("positive-geared: annual_tax_refund_year_1 null (only negative gearing refunds)",
           g(OPos, <<"annual_tax_refund_year_1">>), null),
     check("positive-geared: cgt_marginal_rate still computed (income present)",
           g(OPos, <<"cgt_marginal_rate">>), Rate)].

%% --- 6. negative-gearing reform note (property-conditional, bilingual, §98) --
%% The note is resolver-SELECTED from property_fit_investor.property_type and removed from the
%% LLM's reach (no agent slot). NEVER null — the reform is a public fact. Three branches: base
%% (no property) → general caveat; established_* → the concrete wage-offset warning (the wedge's
%% own target case); new build → the keeps-it note. Each a well-formed bilingual {vi, en}.

pf(Type) -> #{<<"property_fit_investor">> => #{<<"property_type">> => Type}}.
note(Up) -> {O, _, _} = scaffold(Up), g(O, <<"negative_gearing_reform_note">>).
bilingual(#{<<"vi">> := V, <<"en">> := E})
  when is_binary(V), is_binary(E), byte_size(V) > 0, byte_size(E) > 0 -> true;
bilingual(_) -> false.

reform_cases() ->
    Base = note(upstream()),                          %% no property_fit_investor → base caveat
    Est  = note(pf(<<"established_house">>)),
    EstA = note(pf(<<"established_apartment">>)),
    New  = note(pf(<<"off_the_plan">>)),
    HL   = note(pf(<<"house_and_land">>)),
    PfNoType = note(#{<<"property_fit_investor">> => #{}}),  %% property present, type absent → base
    [check("reform note present at base (never null — general caveat)", bilingual(Base), true),
     check("reform note established is bilingual {vi,en}", bilingual(Est), true),
     check("reform note new-build is bilingual {vi,en}", bilingual(New), true),
     check("established_house and established_apartment → same established note", Est, EstA),
     check("off_the_plan and house_and_land → same new-build note", New, HL),
     check("property-conditional: established =/= new-build", Est =/= New, true),
     check("base caveat differs from the established note", Base =/= Est, true),
     check("property present but no type → base caveat (honest-partial)", PfNoType, Base)].

%% --- 4. no regression --------------------------------------------------------

no_regression_cases() ->
    %% yield_modelling stays PURE-resolver: no merge clause (calling it errors).
    YmErrs = errors(fun() -> fh_engine_fill:merge_agent(<<"yield_modelling">>, #{}, #{}) end),
    %% investment_strategy (two-path) still dispatches resolver + merge.
    {SO, SRend, _} = fh_engine_fill:resolver(<<"investment_strategy">>, #{},
                                             #{<<"profile">> => #{<<"hold_horizon_years">> => 10}}),
    SM = fh_engine_fill:merge_agent(<<"investment_strategy">>, SO,
                                    #{<<"archetype">> => <<"balanced">>,
                                      <<"gearing_type">> => <<"neutral_geared">>,
                                      <<"one_liner">> => #{<<"vi">> => <<"x"/utf8>>,
                                                           <<"en">> => <<"y">>}}),
    [check("yield_modelling still pure-resolver (no merge → error)", YmErrs, true),
     check("investment_strategy resolver still dispatches (summary-card)", SRend, <<"summary-card">>),
     check("investment_strategy merge still folds archetype",
           maps:get(<<"archetype">>, SM), <<"balanced">>),
     check("investment_strategy has_resolver still true",
           fh_engine_fill:has_resolver(<<"investment_strategy">>), true)].

%% --- helpers ----------------------------------------------------------------

errors(F) ->
    try F(), false catch _:_ -> true end.

check(Label, Got, Want) ->
    case Got =:= Want of
        true  -> io:format("  PASS   ~ts~n", [Label]), pass;
        false -> io:format("  FAIL   ~ts = ~p, expected ~p~n", [Label, Got, Want]), fail
    end.
