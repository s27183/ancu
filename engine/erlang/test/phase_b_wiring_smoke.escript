#!/usr/bin/env escript
%%! -sname fh_phase_b_wiring_smoke
%%
%% Phase-B WIRING smoke (Slice B2) — proves the per-property turn machinery WITHOUT Postgres or a
%% live/stub sidecar, the layer BELOW the full-stack property_assessment_seam (which is blocked by a
%% live-LLM environment issue independent of B2 — the committed baseline fails it identically). It
%% verifies the three things the gen_statem property-turn relies on for tax_structure to refresh its
%% per-property tax figures while REUSING the base entity (no sidecar/LLM/usage):
%%
%%   1. DAG POSITION — property_components(investor) puts tax_structure AFTER yield_modelling (reads
%%      its cash flow) and BEFORE cash_position/disposition (they read its refreshed CGT determinants).
%%   2. THE REUSE-VS-FRESH DECISION (two_path_stored_leaf/2) — on a `property` turn, a two-path
%%      component whose outcome_type is already in the seed (tax_structure, scope:both) → {reuse, _};
%%      a per-property component with no base outcome (property_assessment) → fresh (runs the sidecar).
%%      base_resolver always reuses (from existing_outcomes); base/other → fresh.
%%   3. THE REUSE-REFRESH COMPOSITION — exactly what the gen_statem's reuse branch does: re-run the
%%      resolver over the per-property upstream + re-attach the stored entity via
%%      agent_values_from_outcome → merge_agent. The entity is the BASE one; the figures are refreshed
%%      off the per-property cash_flow_projection (negative_gearing_active lights up).
%%
%% Run from engine/erlang with the build libs on the path (no Postgres, no sidecar, no model):
%%   ERL_LIBS=_build/default/lib escript test/phase_b_wiring_smoke.escript

-mode(compile).

-define(INV, <<"investor-domestic-au">>).

main(_) ->
    ok = fh_engine_kb:load(),
    io:format("Phase-B wiring smoke — tax_structure per-property refresh (Slice B2)~n~n"),
    R = lists:flatten([position_cases(), decision_cases(), reuse_refresh_cases()]),
    Fails = [X || X <- R, X =:= fail],
    io:format("~n================================================================~n"),
    case Fails of
        [] -> io:format("PASS — all ~p Phase-B wiring anchors hold~n", [length(R)]), halt(0);
        _  -> io:format("FAIL — ~p anchor(s) mismatched~n", [length(Fails)]), halt(1)
    end.

%% --- 1. DAG position ---------------------------------------------------------

position_cases() ->
    Comps = fh_engine_turn:property_components(?INV),
    Names = [maps:get(<<"name">>, C) || C <- Comps],
    Idx = fun(N) -> index_of(N, Names) end,
    [check("property_components includes tax_structure",
           lists:member(<<"tax_structure">>, Names), true),
     check("tax_structure runs AFTER yield_modelling (reads its cash flow)",
           Idx(<<"yield_modelling">>) < Idx(<<"tax_structure">>), true),
     check("tax_structure runs BEFORE cash_position (it reads tax determinants)",
           Idx(<<"tax_structure">>) < Idx(<<"cash_position">>), true),
     check("tax_structure runs BEFORE disposition (it reads tax determinants)",
           Idx(<<"tax_structure">>) < Idx(<<"disposition">>), true),
     check("property_components includes buying_strategy (Slice C)",
           lists:member(<<"buying_strategy">>, Names), true),
     check("buying_strategy runs AFTER cash_position (reads budget_envelope_investor)",
           Idx(<<"cash_position">>) < Idx(<<"buying_strategy">>), true),
     check("canonical order: PA → yield → tax → cash → disposition → buying_strategy",
           Names, [<<"property_assessment">>, <<"yield_modelling">>, <<"tax_structure">>,
                   <<"cash_position">>, <<"disposition">>, <<"buying_strategy">>])].

%% --- 2. the reuse-vs-fresh decision -----------------------------------------

%% comp maps as the artifact/commit shape them (name + outcome_type).
tax_comp() -> #{<<"name">> => <<"tax_structure">>, <<"outcome_type">> => <<"tax_optimised_structure">>}.
pa_comp()  -> #{<<"name">> => <<"property_assessment">>, <<"outcome_type">> => <<"property_fit_investor">>}.
buying_comp() -> #{<<"name">> => <<"buying_strategy">>, <<"outcome_type">> => <<"bid_plan_investor">>}.

decision_cases() ->
    StoredTax = #{<<"recommended_entity">> => <<"discretionary_trust">>},
    %% a property turn: the seed (outcomes) holds the base tax_optimised_structure but NOT
    %% property_fit_investor (property_assessment never ran at base).
    PropData = #{kind => property,
                 outcomes => #{<<"tax_optimised_structure">> => StoredTax,
                               <<"profile">> => #{}}},
    %% base_resolver: stored leaves keyed by component NAME in existing_outcomes.
    RefreshData = #{kind => base_resolver,
                    existing_outcomes => #{<<"tax_structure">> => StoredTax}},
    [check("property turn + tax_structure in seed → reuse the stored outcome",
           fh_engine_turn:two_path_stored_leaf(PropData, tax_comp()), {reuse, StoredTax}),
     check("property turn + property_assessment NOT in seed → fresh (sidecar)",
           fh_engine_turn:two_path_stored_leaf(PropData, pa_comp()), fresh),
     check("property turn + buying_strategy NOT in seed → fresh (sidecar for negotiation leaf)",
           fh_engine_turn:two_path_stored_leaf(PropData, buying_comp()), fresh),
     check("base_resolver turn → reuse stored leaf from existing_outcomes",
           fh_engine_turn:two_path_stored_leaf(RefreshData, tax_comp()), {reuse, StoredTax}),
     check("base (full) turn → fresh (sidecar authors the leaves)",
           fh_engine_turn:two_path_stored_leaf(#{kind => base}, tax_comp()), fresh),
     check("no kind given → defaults to fresh",
           fh_engine_turn:two_path_stored_leaf(#{}, tax_comp()), fresh)].

%% --- 3. the reuse-refresh composition (resolver + re-attach + merge) ---------

%% drive the REAL yield_modelling producer for a negatively-geared house → the per-property cash flow.
real_cfp() ->
    Pf = #{<<"price">> => 920000, <<"property_type">> => <<"established_house">>,
           <<"estimated_weekly_rent_range">> => [620, 720]},
    {Cfp, _, _} = fh_engine_fill:resolver(<<"yield_modelling">>, #{},
                                          #{<<"property_fit_investor">> => Pf}),
    Cfp.

reuse_refresh_cases() ->
    Cfp = real_cfp(),
    Entity = <<"personal_joint">>,
    %% the seed's stored base tax_optimised_structure: the entity was decided at base; figures null.
    Stored = #{<<"recommended_entity">> => Entity,
               <<"cgt_discount_eligible">> => true,
               <<"negative_gearing_active">> => null},
    %% the per-property upstream the gen_statem hands the resolver (seed + per-property cash flow).
    Upstream = #{<<"profile">> => #{<<"target_price_range">> => [800000, 1000000]},
                 <<"cash_flow_projection">> => Cfp,
                 <<"tax_optimised_structure">> => Stored},
    %% replicate the gen_statem reuse branch EXACTLY (fh_engine_turn running/2 two_path/reuse):
    {RO, _Rend, _Kb} = fh_engine_fill:resolver(<<"tax_structure">>, #{}, Upstream),
    AgentValues = fh_engine_fill:agent_values_from_outcome(<<"tax_structure">>, Stored),
    Final = fh_engine_fill:merge_agent(<<"tax_structure">>, RO, AgentValues),
    Geared = maps:get(<<"is_positive_neutral_or_negative_geared_pre_tax">>, Cfp),
    [check("precondition: per-property cash flow is negatively geared",
           Geared, <<"negative">>),
     check("REFRESH: negative_gearing_active lights up off the per-property cash flow",
           maps:get(<<"negative_gearing_active">>, Final), true),
     check("REUSE: the entity is the BASE one, re-attached (no sidecar re-derivation)",
           maps:get(<<"recommended_entity">>, Final), Entity),
     check("the money figures stay null (no income in this upstream → marginal rate uncaptured)",
           maps:get(<<"cgt_marginal_rate">>, Final), null),
     check("the resolver half alone leaves the entity null (the re-attach is what restores it)",
           maps:get(<<"recommended_entity">>, RO), null),
     check("Layer-1 conforms on the refreshed+merged outcome",
           validate(Final), ok)].

%% --- helpers ----------------------------------------------------------------

validate(O) ->
    try fh_engine_outcome:validate(?INV, <<"tax_optimised_structure">>, O), ok
    catch _:Why -> {error, Why} end.

index_of(X, L) -> index_of(X, L, 1).
index_of(_, [], _) -> -1;
index_of(X, [X | _], I) -> I;
index_of(X, [_ | T], I) -> index_of(X, T, I + 1).

check(Label, Got, Want) ->
    case Got =:= Want of
        true  -> io:format("  PASS   ~ts~n", [Label]), pass;
        false -> io:format("  FAIL   ~ts = ~p, expected ~p~n", [Label, Got, Want]), fail
    end.
