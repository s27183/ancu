#!/usr/bin/env escript
%%! -sname fh_family_cross_border_conformance
%%
%% Conformance suite for the TWO NEW Mode-B components (fh_engine_family:fill/2 +
%% fh_engine_cross_border:fill/2 — blueprint fhb-foreign-au.md components 2 and 7,
%% mode-b-wedge.md P2 slice 6, the LAST P2 unit, closing Mode-B P2). Neither has a
%% shared-name collision (both wholly new components, wholly new modules) — no
%% no-regression cases needed. Loads the SAME materialized artifact the engine loads
%% and asserts:
%%   1. family_context SCAFFOLD — every family-specific fact is honestly empty/null at
%%      base (no funder captured yet, profile.off_title_parties = []); funding_
%%      complexity_score floors at 1 (never guesses a family's pattern).
%%   2. family_context WITH FUNDERS — total_capacity_aud sums captured funder amounts
%%      (never a partial sum); bilingual_coordination_required is COMPUTED from a
%%      non-AU funder's residence_country, never assumed true just because this is
%%      Mode B; funding_complexity_score scales with contributor count + non-AU origin.
%%   3. cross_border_funding SCAFFOLD — provider/dates stay null (genuinely unknown
%%      without a live quote / settlement date); vn_compliance_steps/au_compliance_
%%      steps/critical_path_dependencies are static, knowable process/order lists
%%      (assertable even while the VN threshold VALUES stay placeholder).
%%   4. cross_border_funding PLACE-DON'T-RECOMPUTE — total_transfer_amount_aud sums
%%      family_context's OWN VN-origin contribution_breakdown lines; estimated_fx_cost
%%      is null when the transfer amount is unknown, computed at the KB spread % once
%%      it is.
%%
%% Run from engine/erlang with the build libs on the path (no Postgres, no live model):
%%   ERL_LIBS=_build/default/lib escript test/family_context_cross_border_funding_conformance.escript

-mode(compile).

main(_) ->
    ok = fh_engine_kb:load(),
    io:format("family_context + cross_border_funding conformance (Mode-B, new components)~n~n"),
    R = lists:flatten([family_scaffold_cases(), family_funder_cases(),
                       cross_border_scaffold_cases(), cross_border_placement_cases()]),
    Fails = [X || X <- R, X =:= fail],
    io:format("~n================================================================~n"),
    case Fails of
        [] -> io:format("PASS — all ~p family/cross-border anchors hold~n", [length(R)]), halt(0);
        _  -> io:format("FAIL — ~p anchor(s) mismatched~n", [length(Fails)]), halt(1)
    end.

%% --- fixtures ----------------------------------------------------------------

g(O, K) -> maps:get(K, O, undefined).

vn_funder(Capacity) ->
    #{<<"relationship">> => <<"parent">>,
      <<"funder">> => #{<<"expected_to_fund">> => true,
                        <<"residence_country">> => <<"VN">>,
                        <<"contribution_capacity_aud">> => Capacity}}.

au_funder(Capacity) ->
    #{<<"relationship">> => <<"sibling">>,
      <<"funder">> => #{<<"expected_to_fund">> => true,
                        <<"residence_country">> => <<"AU">>,
                        <<"contribution_capacity_aud">> => Capacity}}.

family_fields() ->
    [<<"total_capacity_aud">>, <<"contribution_breakdown">>, <<"decision_authority">>,
     <<"bilingual_coordination_required">>, <<"funding_complexity_score">>,
     <<"documentation_gaps">>].

%% --- 1. family_context scaffold (base, no funder) -----------------------------

family_scaffold_cases() ->
    {O, Rend, Kb} = fh_engine_fill:resolver(<<"family_context">>, #{},
        #{<<"profile">> => #{<<"off_title_parties">> => []}}),
    KbSlugs = [maps:get(<<"slug">>, E) || E <- Kb],
    [check("renderer = family-view-card", Rend, <<"family-view-card">>),
     check("outcome has exactly the six family_funding_plan fields",
           lists:sort(maps:keys(O)), lists:sort(family_fields())),
     check("total_capacity_aud = null (no funder captured, never 0)",
           g(O, <<"total_capacity_aud">>), null),
     check("contribution_breakdown = []", g(O, <<"contribution_breakdown">>), []),
     check("decision_authority = null (undetermined, prompt don't profile)",
           g(O, <<"decision_authority">>), null),
     check("bilingual_coordination_required = false (no confirmed non-AU party yet)",
           g(O, <<"bilingual_coordination_required">>), false),
     check("funding_complexity_score = 1 (floor, nothing captured)",
           g(O, <<"funding_complexity_score">>), 1),
     check("documentation_gaps = [] (nothing to flag yet)",
           g(O, <<"documentation_gaps">>), []),
     check("kb_versions = the three Mode-B family anchors",
           lists:sort(KbSlugs),
           lists:sort([<<"kb.vietnamese-family.financial-patterns">>,
                       <<"kb.cross-border.decision-authority-cultural">>,
                       <<"kb.bilingual.coordination-norms">>])),
     check("has_resolver true", fh_engine_fill:has_resolver(<<"family_context">>), true)].

%% --- 2. family_context with captured funders ------------------------------------

family_funder_cases() ->
    {O1, _, _} = fh_engine_fill:resolver(<<"family_context">>, #{},
        #{<<"profile">> => #{<<"off_title_parties">> => [vn_funder(400000)]}}),
    {O2, _, _} = fh_engine_fill:resolver(<<"family_context">>, #{},
        #{<<"profile">> => #{<<"off_title_parties">> => [vn_funder(400000), au_funder(100000)]}}),
    {ONullCapacity, _, _} = fh_engine_fill:resolver(<<"family_context">>, #{},
        #{<<"profile">> => #{<<"off_title_parties">> => [vn_funder(null)]}}),
    [Bd1] = g(O1, <<"contribution_breakdown">>),
    [check("one VN funder: total_capacity_aud = 400000", g(O1, <<"total_capacity_aud">>), 400000),
     check("one VN funder: breakdown has one line", length(g(O1, <<"contribution_breakdown">>)), 1),
     check("breakdown line: party = parent", maps:get(<<"party">>, Bd1), <<"parent">>),
     check("breakdown line: amount_aud = 400000", maps:get(<<"amount_aud">>, Bd1), 400000),
     check("breakdown line: currency_origin = VND", maps:get(<<"currency_origin">>, Bd1), <<"VND">>),
     check("one VN funder: bilingual_coordination_required = true",
           g(O1, <<"bilingual_coordination_required">>), true),
     check("one VN funder: funding_complexity_score = 2 (floor 1 + non-AU origin)",
           g(O1, <<"funding_complexity_score">>), 2),
     check("one VN funder: documentation_gaps has one entry",
           length(g(O1, <<"documentation_gaps">>)), 1),
     check("VN + AU funder: total_capacity_aud = 500000",
           g(O2, <<"total_capacity_aud">>), 500000),
     check("VN + AU funder: funding_complexity_score = 3 (floor 1 + 1 extra funder + non-AU)",
           g(O2, <<"funding_complexity_score">>), 3),
     check("VN + AU funder: bilingual_coordination_required = true (the VN funder alone triggers it)",
           g(O2, <<"bilingual_coordination_required">>), true),
     check("funder with unset capacity: total_capacity_aud = null (never a partial sum)",
           g(ONullCapacity, <<"total_capacity_aud">>), null)].

%% --- 3. cross_border_funding scaffold (base, no VN-origin breakdown) -----------

cb_fields() ->
    [<<"provider">>, <<"total_transfer_amount_aud">>, <<"estimated_fx_cost">>,
     <<"vn_compliance_steps">>, <<"au_compliance_steps">>, <<"transfer_initiated_by_date">>,
     <<"transfer_received_by_date">>, <<"critical_path_dependencies">>].

cross_border_scaffold_cases() ->
    {O, Rend, Kb} = fh_engine_fill:resolver(<<"cross_border_funding">>, #{},
        #{<<"family_funding_plan">> => #{<<"contribution_breakdown">> => []}}),
    KbSlugs = [maps:get(<<"slug">>, E) || E <- Kb],
    [check("renderer = firb-workflow-card", Rend, <<"firb-workflow-card">>),
     check("outcome has exactly the eight transfer_plan fields",
           lists:sort(maps:keys(O)), lists:sort(cb_fields())),
     check("provider = null (no live quote comparison at base)", g(O, <<"provider">>), null),
     check("total_transfer_amount_aud = null (no VN-origin contribution captured)",
           g(O, <<"total_transfer_amount_aud">>), null),
     check("estimated_fx_cost = null (transfer amount unknown)",
           g(O, <<"estimated_fx_cost">>), null),
     check("vn_compliance_steps has three process steps",
           length(g(O, <<"vn_compliance_steps">>)), 3),
     check("au_compliance_steps has three process steps",
           length(g(O, <<"au_compliance_steps">>)), 3),
     check("transfer_initiated_by_date = null (no settlement date yet)",
           g(O, <<"transfer_initiated_by_date">>), null),
     check("transfer_received_by_date = null (as above)",
           g(O, <<"transfer_received_by_date">>), null),
     check("critical_path_dependencies has the five-step structural sequence",
           length(g(O, <<"critical_path_dependencies">>)), 5),
     check("kb_versions = the seven Mode-B cross-border anchors",
           lists:sort(KbSlugs),
           lists:sort([<<"kb.fx-providers.wise-ofx-bank-comparison">>,
                       <<"kb.fx.typical-spreads-vnd-aud">>,
                       <<"kb.vn-capital-controls.sbv-thresholds-2026">>,
                       <<"kb.vn-capital-controls.declared-purpose-categories">>,
                       <<"kb.au-aml-ctf.bank-due-diligence-expectations">>,
                       <<"kb.au-aml-ctf.source-of-funds-documentation">>,
                       <<"kb.vn-pdp.cross-border-data-transfer">>])),
     check("has_resolver true", fh_engine_fill:has_resolver(<<"cross_border_funding">>), true)].

%% --- 4. cross_border_funding place-don't-recompute -------------------------------

cross_border_placement_cases() ->
    Breakdown = [#{<<"party">> => <<"parent">>, <<"amount_aud">> => 400000,
                  <<"currency_origin">> => <<"VND">>},
                 #{<<"party">> => <<"self">>, <<"amount_aud">> => 100000,
                  <<"currency_origin">> => <<"AUD">>}],
    {O, _, _} = fh_engine_fill:resolver(<<"cross_border_funding">>, #{},
        #{<<"family_funding_plan">> => #{<<"contribution_breakdown">> => Breakdown}}),
    [check("total_transfer_amount_aud sums ONLY the VND-origin line (400000, not 500000)",
           g(O, <<"total_transfer_amount_aud">>), 400000),
     check("estimated_fx_cost = 6000 (1.5% of 400000, the KB planning default spread)",
           g(O, <<"estimated_fx_cost">>), 6000),
     check("transfer_amount/1 direct call matches", fh_engine_cross_border:transfer_amount(Breakdown), 400000),
     check("fx_cost/1 direct call matches", fh_engine_cross_border:fx_cost(400000), 6000),
     check("fx_cost(null) = null", fh_engine_cross_border:fx_cost(null), null),
     check("transfer_amount([]) = null", fh_engine_cross_border:transfer_amount([]), null)].

%% --- helpers ----------------------------------------------------------------

check(Label, Got, Want) ->
    case Got =:= Want of
        true  -> io:format("  PASS   ~ts~n", [Label]), pass;
        false -> io:format("  FAIL   ~ts = ~p, expected ~p~n", [Label, Got, Want]), fail
    end.
