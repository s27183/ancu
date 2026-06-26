#!/usr/bin/env escript
%%! -sname fh_settlement_prep_conformance
%%
%% Conformance suite for the `settlement_prep` investor-variant resolver (fh_engine_settlement —
%% Mode C, Phase B per-property, blueprint component 10; RESOLVER-ONLY, zero agent leaves). Loads
%% the SAME materialized artifact the engine loads (priv/kb/artifact.json) and asserts what the
%% settlement checklist relies on:
%%   1. SCAFFOLD — the resolver owns the checklist renderer + the settlement/insurance/investor
%%      anchors, is classified resolver with NO agent leaves, emits the seven settlement_checklist
%%      fields, and marks the honest-partial date state (dates_status=pending_contract,
%%      settlement_date null, at_risk_milestones []).
%%   2. CRITICAL PATH — the nine standard milestones in order, each with the right dependency, a
%%      bilingual name, due_date null + status pending (dates PENDING until contract dates — B).
%%   3. INVESTOR MILESTONES — five, each bilingual name + why; entity-setup CONDITIONED on the
%%      upstream recommended_entity (company/trust → applicable; personal_sole/joint/null → not);
%%      QS/depreciation/PM/landlord-insurance always-applicable.
%%   4. INSURANCE RULE — state-conditional: NSW/VIC/QLD → the regulated per-state rule; a known
%%      other state → the universal lender-overlay; unknown state → null (honest, no fabrication);
%%      a strata lot (apartment/unit) → the contents-only note appended.
%%   5. LAYER-1 CONFORMANCE — the outcome passes fh_engine_outcome:validate/3 against the compiled
%%      settlement_checklist schema (enum, array<object>, localized_text|null, date|null).
%%   6. HONEST-PARTIAL — no upstream at all → structure still fills, every date null, insurance
%%      rule null, entity-setup not applicable; nothing fabricated.
%%
%% Run from engine/erlang with the build libs on the path (no Postgres, no live model):
%%   ERL_LIBS=_build/default/lib escript test/settlement_prep_conformance.escript

-mode(compile).

-define(INV, <<"investor-domestic-au">>).

main(_) ->
    ok = fh_engine_kb:load(),
    io:format("settlement_prep conformance — fh_engine_settlement (Mode-C resolver-only, Slice C-settle)~n~n"),
    R = lists:flatten([scaffold_cases(), critical_path_cases(), investor_milestone_cases(),
                       insurance_cases(), layer1_cases(), honest_partial_cases()]),
    Fails = [X || X <- R, X =:= fail],
    io:format("~n================================================================~n"),
    case Fails of
        [] -> io:format("PASS — all ~p settlement_prep anchors hold~n", [length(R)]), halt(0);
        _  -> io:format("FAIL — ~p anchor(s) mismatched~n", [length(Fails)]), halt(1)
    end.

%% --- fixtures ----------------------------------------------------------------

fields() ->
    [<<"dates_status">>, <<"settlement_date">>, <<"critical_path_milestones">>,
     <<"investor_milestones">>, <<"insurance_timing_rule">>, <<"at_risk_milestones">>,
     <<"next_action_for_user">>].

%% a VIC house with a company entity decided upstream.
pf(State, PType) ->
    #{<<"state">> => State, <<"suburb">> => <<"Footscray">>,
      <<"price">> => 920000, <<"property_type">> => PType}.

tax(Entity) -> #{<<"recommended_entity">> => Entity}.

upstream(State, PType, Entity) ->
    #{<<"property_fit_investor">> => pf(State, PType),
      <<"tax_optimised_structure">> => tax(Entity)}.

scaffold(Upstream) -> fh_engine_fill:resolver(<<"settlement_prep">>, #{}, Upstream).

g(O, K) -> maps:get(K, O, undefined).

is_loc(M) -> is_map(M) andalso is_binary(maps:get(<<"vi">>, M, undefined))
                 andalso is_binary(maps:get(<<"en">>, M, undefined))
                 andalso maps:get(<<"vi">>, M) =/= <<>>
                 andalso maps:get(<<"en">>, M) =/= <<>>.

%% --- 1. scaffold -------------------------------------------------------------

scaffold_cases() ->
    {O, Rend, Kb} = scaffold(upstream(<<"VIC">>, <<"established_house">>, <<"company">>)),
    KbSlugs = [maps:get(<<"slug">>, E) || E <- Kb],
    [check("renderer = checklist", Rend, <<"checklist">>),
     check("outcome has exactly the seven settlement_checklist fields",
           lists:sort(maps:keys(O)), lists:sort(fields())),
     check("has_resolver true", fh_engine_fill:has_resolver(<<"settlement_prep">>), true),
     check("dates_status = pending_contract (honest-partial — no contract dates)",
           g(O, <<"dates_status">>), <<"pending_contract">>),
     check("settlement_date null (PENDING until contract)", g(O, <<"settlement_date">>), null),
     check("at_risk_milestones empty (can't assess risk without dates)",
           g(O, <<"at_risk_milestones">>), []),
     check("next_action_for_user is bilingual", is_loc(g(O, <<"next_action_for_user">>)), true),
     check("kb_versions = the six read anchors",
           lists:sort(KbSlugs),
           lists:sort([<<"kb.settlement.process-by-state">>,
                       <<"kb.insurance.timing-of-risk-pass">>,
                       <<"kb.copy.settlement">>,
                       <<"kb.investor.entity-setup-timeline">>,
                       <<"kb.investor.depreciation-schedule-procurement">>,
                       <<"kb.investor.property-management-appointment-timeline">>]))].

%% --- 2. the critical path (structure now, dates PENDING) --------------------

critical_path_cases() ->
    {O, _, _} = scaffold(upstream(<<"VIC">>, <<"established_house">>, <<"company">>)),
    Mils = g(O, <<"critical_path_milestones">>),
    Ids  = [maps:get(<<"id">>, M) || M <- Mils],
    Deps = [{maps:get(<<"id">>, M), maps:get(<<"dependency">>, M)} || M <- Mils],
    ExpectedIds = [<<"contract_signed">>, <<"deposit_paid_to_trust">>,
                   <<"building_pest_satisfactory">>, <<"finance_approval_unconditional">>,
                   <<"loan_documents_signed">>, <<"insurance_bound">>,
                   <<"settlement_funds_released">>, <<"title_registered">>,
                   <<"keys_received">>],
    ExpectedDeps = [{<<"contract_signed">>, null},
                    {<<"deposit_paid_to_trust">>, <<"contract_signed">>},
                    {<<"building_pest_satisfactory">>, <<"contract_signed">>},
                    {<<"finance_approval_unconditional">>, <<"contract_signed">>},
                    {<<"loan_documents_signed">>, <<"finance_approval_unconditional">>},
                    {<<"insurance_bound">>, <<"contract_signed">>},
                    {<<"settlement_funds_released">>, <<"loan_documents_signed">>},
                    {<<"title_registered">>, <<"settlement_funds_released">>},
                    {<<"keys_received">>, <<"title_registered">>}],
    [check("nine critical-path milestones, in order", Ids, ExpectedIds),
     check("each milestone has the correct dependency (the DAG)", Deps, ExpectedDeps),
     check("every milestone name is bilingual",
           lists:all(fun(M) -> is_loc(maps:get(<<"name">>, M)) end, Mils), true),
     check("every due_date null (dates PENDING — settlement_prep B)",
           lists:all(fun(M) -> maps:get(<<"due_date">>, M) =:= null end, Mils), true),
     check("every status pending",
           lists:all(fun(M) -> maps:get(<<"status">>, M) =:= <<"pending">> end, Mils), true)].

%% --- 3. investor milestones (entity-setup conditioned) ----------------------

entity_applicable(Entity) ->
    {O, _, _} = scaffold(upstream(<<"VIC">>, <<"established_house">>, Entity)),
    Mils = g(O, <<"investor_milestones">>),
    [M] = [M0 || M0 <- Mils, maps:get(<<"id">>, M0) =:= <<"entity_setup">>],
    maps:get(<<"applicable">>, M).

investor_milestone_cases() ->
    {O, _, _} = scaffold(upstream(<<"VIC">>, <<"established_house">>, <<"company">>)),
    Mils = g(O, <<"investor_milestones">>),
    Ids  = [maps:get(<<"id">>, M) || M <- Mils],
    Always = fun(Id) ->
        [M] = [M0 || M0 <- Mils, maps:get(<<"id">>, M0) =:= Id],
        maps:get(<<"applicable">>, M)
    end,
    [check("five investor milestones, in order", Ids,
           [<<"entity_setup">>, <<"quantity_surveyor_engaged">>,
            <<"depreciation_schedule_received">>, <<"property_management_appointed">>,
            <<"landlord_insurance_bound">>]),
     check("every investor milestone has a bilingual name + why",
           lists:all(fun(M) -> is_loc(maps:get(<<"name">>, M))
                                   andalso is_loc(maps:get(<<"why">>, M)) end, Mils), true),
     check("entity_setup applicable for a company", entity_applicable(<<"company">>), true),
     check("entity_setup applicable for a trust", entity_applicable(<<"trust">>), true),
     check("entity_setup NOT applicable for personal_sole",
           entity_applicable(<<"personal_sole">>), false),
     check("entity_setup NOT applicable for joint", entity_applicable(<<"joint">>), false),
     check("entity_setup NOT applicable when entity undecided (null)",
           entity_applicable(null), false),
     check("QS engagement always applicable", Always(<<"quantity_surveyor_engaged">>), true),
     check("depreciation schedule always applicable",
           Always(<<"depreciation_schedule_received">>), true),
     check("PM appointment always applicable",
           Always(<<"property_management_appointed">>), true),
     check("landlord insurance always applicable",
           Always(<<"landlord_insurance_bound">>), true)].

%% --- 4. the state-conditional insurance rule --------------------------------

ins_rule(State, PType) ->
    {O, _, _} = scaffold(upstream(State, PType, <<"company">>)),
    g(O, <<"insurance_timing_rule">>).

insurance_cases() ->
    Nsw  = ins_rule(<<"NSW">>, <<"established_house">>),
    Vic  = ins_rule(<<"VIC">>, <<"established_house">>),
    Qld  = ins_rule(<<"QLD">>, <<"established_house">>),
    Sa   = ins_rule(<<"SA">>,  <<"established_house">>),
    Strat= ins_rule(<<"VIC">>, <<"apartment">>),
    Base = fh_engine_kb:copy(<<"kb.copy.settlement">>, <<"ins_rule_VIC">>),
    [check("NSW insurance rule is bilingual", is_loc(Nsw), true),
     check("VIC insurance rule is bilingual", is_loc(Vic), true),
     check("QLD insurance rule is bilingual", is_loc(Qld), true),
     check("NSW and QLD rules differ (state-conditional, not boilerplate)", Nsw =/= Qld, true),
     check("a known non-NSW/VIC/QLD state (SA) gets the universal lender-overlay rule",
           is_loc(Sa), true),
     check("SA rule is the generic one, not the VIC one", Sa =/= Vic, true),
     check("unknown/absent state → null (honest-partial, no rule fabricated)",
           ins_rule(null, <<"established_house">>), null),
     check("a strata lot (apartment) appends the contents-only note",
           byte_size(maps:get(<<"en">>, Strat)) > byte_size(maps:get(<<"en">>, Base)), true)].

%% --- 5. Layer-1 conformance (the fail-closed commit seam) -------------------

layer1_cases() ->
    {O, _, _} = scaffold(upstream(<<"QLD">>, <<"unit">>, <<"trust">>)),
    [check("Layer-1 conforms: full outcome (enum, array<object>, localized_text|null, date|null)",
           validate(O), ok)].

validate(O) ->
    try fh_engine_outcome:validate(?INV, <<"settlement_checklist">>, O), ok
    catch _:Why -> {error, Why} end.

%% --- 6. honest-partial (no upstream → structure still, nothing fabricated) ---

honest_partial_cases() ->
    {O, _, _} = scaffold(#{}),
    Mils = g(O, <<"critical_path_milestones">>),
    Inv  = g(O, <<"investor_milestones">>),
    [Ent] = [M || M <- Inv, maps:get(<<"id">>, M) =:= <<"entity_setup">>],
    [check("no upstream: still nine critical-path milestones (structure is KB-grounded)",
           length(Mils), 9),
     check("no upstream: still five investor milestones", length(Inv), 5),
     check("no upstream: entity_setup not applicable (entity undecided)",
           maps:get(<<"applicable">>, Ent), false),
     check("no upstream: insurance_timing_rule null (no state → no rule)",
           g(O, <<"insurance_timing_rule">>), null),
     check("no upstream: dates_status still pending_contract",
           g(O, <<"dates_status">>), <<"pending_contract">>),
     check("no upstream: Layer-1 still conforms", validate(O), ok)].

%% --- helpers ----------------------------------------------------------------

check(Label, Got, Want) ->
    case Got =:= Want of
        true  -> io:format("  PASS   ~ts~n", [Label]), pass;
        false -> io:format("  FAIL   ~ts = ~p, expected ~p~n", [Label, Got, Want]), fail
    end.
