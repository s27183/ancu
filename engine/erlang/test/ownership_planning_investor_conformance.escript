#!/usr/bin/env escript
%%! -sname fh_ownership_planning_investor_conformance
%%
%% Conformance suite for the `ownership_planning_investor` variant
%% (fh_engine_ownership:fill_investor/2 — the investor hold/operate base spine, blueprint
%% component 11; a PURE-resolver figure-owner, agent_leaves = [], the same class as
%% yield_modelling / disposition / cash_position-investor). UNIQUE component name — no
%% shared-name collision with the FHB `ownership_planning`, so fh_engine_fill dispatches it
%% to a clean sibling fill_investor/2 and the FHB fill/2 is untouched. Loads the SAME
%% materialized artifact the engine loads (priv/kb/artifact.json) and asserts:
%%   1. SCAFFOLD — the variant owns the `data-table` renderer + the six investor KB anchors;
%%      HONEST-PARTIAL: the two array fields (annual_tax_obligations, alert_triggers_armed)
%%      are filled bilingual + KB-grounded, the six post-acquisition figure fields are null,
%%      and `opportunities` is [] at base (the producer foundation; populates per-property).
%%      Input-independent at base. has_resolver true.
%%   2. LAYER-1 CONFORMANCE — the scaffold passes fh_engine_outcome:validate/3 against the
%%      compiled `portfolio_position` schema, including the localized-text ENFORCEMENT on
%%      annual_tax_obligations (each entry must be a non-blank {vi,en} pair).
%%   3. BILINGUAL — every obligation line and every alert {trigger,action} half is a
%%      well-formed {vi,en} pair (the engine produces localized content at the source).
%%   4. NO REGRESSION — the FHB `ownership_planning` path is untouched (unique-name dispatch):
%%      it still returns data-table with its armed alerts + land-tax status; yield_modelling
%%      stays pure-resolver.
%%
%% Run from engine/erlang with the build libs on the path (no Postgres, no live model):
%%   ERL_LIBS=_build/default/lib escript test/ownership_planning_investor_conformance.escript

-mode(compile).

-define(INV, <<"investor-domestic-au">>).
-define(FHB, <<"fhb-domestic-au">>).

main(_) ->
    ok = fh_engine_kb:load(),
    io:format("ownership_planning_investor conformance — fh_engine_ownership (Mode-C pure-resolver)~n~n"),
    R = lists:flatten([scaffold_cases(), layer1_cases(), bilingual_cases(),
                       no_regression_cases()]),
    Fails = [X || X <- R, X =:= fail],
    io:format("~n================================================================~n"),
    case Fails of
        [] -> io:format("PASS — all ~p ownership_planning_investor anchors hold~n", [length(R)]), halt(0);
        _  -> io:format("FAIL — ~p anchor(s) mismatched~n", [length(Fails)]), halt(1)
    end.

%% --- fixtures ----------------------------------------------------------------

%% the eight portfolio_position figure-bearing fields the registry declares (plus opportunities).
fields() ->
    [<<"monthly_net_cash_flow_actual">>, <<"ytd_cash_flow_vs_projection">>,
     <<"current_lvr">>, <<"equity_built">>, <<"ready_for_next_property">>,
     <<"portfolio_diversification_score">>, <<"annual_tax_obligations">>,
     <<"alert_triggers_armed">>, <<"opportunities">>].

%% the six post-acquisition figure fields that are null at base.
null_at_base() ->
    [<<"monthly_net_cash_flow_actual">>, <<"ytd_cash_flow_vs_projection">>,
     <<"current_lvr">>, <<"equity_built">>, <<"ready_for_next_property">>,
     <<"portfolio_diversification_score">>].

scaffold() ->
    fh_engine_fill:resolver(<<"ownership_planning_investor">>, #{}, #{}).

g(O, K) -> maps:get(K, O, undefined).

%% --- 1. scaffold -------------------------------------------------------------

scaffold_cases() ->
    {O, Rend, Kb} = scaffold(),
    %% input-independent at base: a bare upstream gives an identical outcome.
    {OBare, _, _} = fh_engine_fill:resolver(<<"ownership_planning_investor">>,
                                            #{onboarding => #{}}, #{}),
    KbSlugs = [maps:get(<<"slug">>, E) || E <- Kb],
    NullChecks =
        [check(<<"figure null at base: ", F/binary>>, g(O, F), null) || F <- null_at_base()],
    BareChecks =
        [check(<<"input-independent null: ", F/binary>>, g(OBare, F), null) || F <- null_at_base()],
    [check("renderer = data-table", Rend, <<"data-table">>),
     check("outcome has exactly the nine portfolio_position fields",
           lists:sort(maps:keys(O)), lists:sort(fields())),
     check("annual_tax_obligations: 5 obligations filled",
           length(g(O, <<"annual_tax_obligations">>)), 5),
     check("alert_triggers_armed: 4 investor alerts filled",
           length(g(O, <<"alert_triggers_armed">>)), 4),
     check("opportunities = [] at base (producer foundation; populates per-property)",
           g(O, <<"opportunities">>), []),
     check("kb_versions = the six investor anchors",
           lists:sort(KbSlugs),
           lists:sort([<<"kb.investor.property-management-vs-self-managed">>,
                       <<"kb.investor.annual-tax-return-investor">>,
                       <<"kb.investor.cash-flow-tracking">>,
                       <<"kb.investor.portfolio-review-cadence">>,
                       <<"kb.investor.scale-up-using-equity">>,
                       <<"kb.investor.land-tax-aggregation">>])),
     check("has_resolver true (classified as resolver, pure)",
           fh_engine_fill:has_resolver(<<"ownership_planning_investor">>), true)]
    ++ NullChecks ++ BareChecks.

%% --- 2. Layer-1 conformance (the fail-closed commit seam) -------------------

layer1_cases() ->
    {O, _, _} = scaffold(),
    [check(<<"Layer-1 conforms: portfolio_position (incl. localized-text enforcement)">>,
           validate(?INV, <<"portfolio_position">>, O), ok)].

validate(Bp, Type, O) ->
    try fh_engine_outcome:validate(Bp, Type, O), ok
    catch _:Why -> {error, Why} end.

%% --- 3. bilingual (localized content produced at the source) ----------------

bilingual_cases() ->
    {O, _, _} = scaffold(),
    Obligations = g(O, <<"annual_tax_obligations">>),
    Alerts = g(O, <<"alert_triggers_armed">>),
    AlertHalves = lists:flatten([[maps:get(<<"trigger">>, A), maps:get(<<"action">>, A)]
                                 || A <- Alerts]),
    [check("every obligation is a well-formed {vi,en} pair",
           lists:all(fun localized/1, Obligations), true),
     check("every alert trigger/action is a well-formed {vi,en} pair",
           lists:all(fun localized/1, AlertHalves), true)].

localized(#{<<"vi">> := Vi, <<"en">> := En}) when is_binary(Vi), is_binary(En) ->
    byte_size(Vi) > 0 andalso byte_size(En) > 0 andalso Vi =/= En;
localized(_) -> false.

%% --- 4. no regression --------------------------------------------------------

no_regression_cases() ->
    %% the FHB ownership_planning is untouched (unique-name dispatch — no discriminator).
    {Fhb, FhbRend, _} = fh_engine_fill:resolver(<<"ownership_planning">>,
        #{onboarding => #{<<"state">> => <<"NSW">>,
                          <<"target_price_range">> => [600000, 700000]},
          intent => <<"owner_occupier">>},
        #{<<"scheme_stack">> =>
              #{<<"applicable_schemes">> => [#{<<"role">> => <<"deposit_guarantee">>}]}}),
    %% yield_modelling stays PURE-resolver (no merge clause → calling it errors).
    YmErrs = errors(fun() -> fh_engine_fill:merge_agent(<<"yield_modelling">>, #{}, #{}) end),
    [check("FHB ownership_planning renderer still data-table", FhbRend, <<"data-table">>),
     check("FHB ownership_planning still arms its alerts",
           length(maps:get(<<"alert_triggers_armed">>, Fhb, [])) > 0, true),
     check("FHB ownership_planning still emits land_tax_check (exempt_ppor)",
           maps:get(<<"land_tax_check">>, Fhb, undefined), <<"exempt_ppor">>),
     check("FHB ownership_planning has NO investor portfolio field",
           maps:is_key(<<"portfolio_diversification_score">>, Fhb), false),
     check("yield_modelling still pure-resolver (no merge → error)", YmErrs, true)].

%% --- helpers ----------------------------------------------------------------

errors(F) ->
    try F(), false catch _:_ -> true end.

check(Label, Got, Want) ->
    case Got =:= Want of
        true  -> io:format("  PASS   ~ts~n", [Label]), pass;
        false -> io:format("  FAIL   ~ts = ~p, expected ~p~n", [Label, Got, Want]), fail
    end.
