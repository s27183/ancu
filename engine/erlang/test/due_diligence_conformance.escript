#!/usr/bin/env escript
%%! -sname fh_due_diligence_conformance
%%
%% Conformance suite for the `due_diligence` investor-variant resolver (fh_engine_due_diligence —
%% Mode C, Phase B per-property, blueprint component 9; RESOLVER-ONLY AT A, zero agent leaves —
%% its lease_interpretation leaf needs the uploaded lease → due_diligence B). Loads the SAME
%% materialized artifact the engine loads (priv/kb/artifact.json) and asserts what the investor
%% due-diligence assessment relies on:
%%   1. SCAFFOLD — the resolver owns the checklist renderer (the reachable primary; risk-flag-list
%%      is declared first but the procurement checklist is the always-populated A content) + the
%%      three investor anchors + the copy doc, is classified resolver with NO agent leaves, emits
%%      the ten risk_assessment_investor fields, and marks the honest-partial document state
%%      (docs_status=pending_upload, overall_verdict=pending_documents, high_severity_flags [],
%%      estimated_negotiation_lever null).
%%   2. DOCUMENT CHECKLIST — the four investor procurement documents in order, each a bilingual
%%      name + why, required known now, received/reviewed false (upload pipeline → B).
%%   3. THESIS FLAG (the one computable figure, §8.5) — rental_yield_below_thesis_threshold =
%%      property_fit_investor.rental_yield_gross_estimate < strategy_thesis.target_gross_yield;
%%      true → a concern fires; false → no concern; either input absent → null (never false from
%%      absent data); the figure is resolver-computed, not an agent slot.
%%   4. ACTIONS + QUESTIONS — the bilingual due-diligence actions before signing + vendor questions.
%%   5. LAYER-1 CONFORMANCE — the outcome passes fh_engine_outcome:validate/3 against the compiled
%%      risk_assessment_investor schema (enum, array<object>, array<localized_text>, bool|null,
%%      money_range|null, localized_text).
%%   6. HONEST-PARTIAL — no upstream at all → structure still fills, thesis flag null, no concern,
%%      document fields PENDING; nothing fabricated.
%%
%% Run from engine/erlang with the build libs on the path (no Postgres, no live model):
%%   ERL_LIBS=_build/default/lib escript test/due_diligence_conformance.escript

-mode(compile).

-define(INV, <<"investor-domestic-au">>).

main(_) ->
    ok = fh_engine_kb:load(),
    io:format("due_diligence conformance — fh_engine_due_diligence (Mode-C resolver-only at A, Slice C-dd)~n~n"),
    R = lists:flatten([scaffold_cases(), checklist_cases(), thesis_flag_cases(),
                       actions_questions_cases(), layer1_cases(), honest_partial_cases()]),
    Fails = [X || X <- R, X =:= fail],
    io:format("~n================================================================~n"),
    case Fails of
        [] -> io:format("PASS — all ~p due_diligence anchors hold~n", [length(R)]), halt(0);
        _  -> io:format("FAIL — ~p anchor(s) mismatched~n", [length(Fails)]), halt(1)
    end.

%% --- fixtures ----------------------------------------------------------------

fields() ->
    [<<"docs_status">>, <<"overall_verdict">>, <<"document_checklist">>,
     <<"rental_yield_below_thesis_threshold">>, <<"investor_specific_concerns">>,
     <<"actions_before_signing">>, <<"questions_for_vendor">>, <<"high_severity_flags">>,
     <<"estimated_negotiation_lever">>, <<"next_action_for_user">>].

pf(Yield) ->
    #{<<"suburb">> => <<"Cabramatta">>, <<"price">> => 920000,
      <<"property_type">> => <<"established_house">>,
      <<"rental_yield_gross_estimate">> => Yield}.

thesis(Target) -> #{<<"target_gross_yield">> => Target}.

upstream(Yield, Target) ->
    #{<<"property_fit_investor">> => pf(Yield),
      <<"strategy_thesis">> => thesis(Target)}.

scaffold(Upstream) -> fh_engine_fill:resolver(<<"due_diligence">>, #{}, Upstream).

%% the compiled component's agent_leaves (the live turn's fill-path determinant).
agent_leaves(Name) ->
    {ok, All} = fh_engine_kb:components(?INV),
    [C] = [C0 || C0 <- All, maps:get(<<"name">>, C0) =:= Name],
    maps:get(<<"agent_leaves">>, C, undefined).

g(O, K) -> maps:get(K, O, undefined).

is_loc(M) -> is_map(M) andalso is_binary(maps:get(<<"vi">>, M, undefined))
                 andalso is_binary(maps:get(<<"en">>, M, undefined))
                 andalso maps:get(<<"vi">>, M) =/= <<>>
                 andalso maps:get(<<"en">>, M) =/= <<>>.

%% --- 1. scaffold -------------------------------------------------------------

scaffold_cases() ->
    {O, Rend, Kb} = scaffold(upstream(3.8, 4.0)),
    KbSlugs = [maps:get(<<"slug">>, E) || E <- Kb],
    [check("renderer = checklist (the reachable primary at A)", Rend, <<"checklist">>),
     check("outcome has exactly the ten risk_assessment_investor fields",
           lists:sort(maps:keys(O)), lists:sort(fields())),
     check("has_resolver true", fh_engine_fill:has_resolver(<<"due_diligence">>), true),
     %% the LIVE turn classifies fill_path by the compiled component's agent_leaves — a direct
     %% resolver call bypasses this, so assert it here: [] → resolver-only at A (the
     %% lease_interpretation leaf is deferred to B; a non-empty list would make the turn dispatch a
     %% sidecar filler that does not exist → turn_failed, the C-dd live-seam regression).
     check("compiled agent_leaves = [] → resolver-only at A (lease_interpretation leaf deferred to B)",
           agent_leaves(<<"due_diligence">>), []),
     check("docs_status = pending_upload (honest-partial — no uploaded documents)",
           g(O, <<"docs_status">>), <<"pending_upload">>),
     check("overall_verdict = pending_documents", g(O, <<"overall_verdict">>), <<"pending_documents">>),
     check("high_severity_flags empty (no documents → no extracted flags — B)",
           g(O, <<"high_severity_flags">>), []),
     check("estimated_negotiation_lever null (needs document findings — B)",
           g(O, <<"estimated_negotiation_lever">>), null),
     check("next_action_for_user is bilingual", is_loc(g(O, <<"next_action_for_user">>)), true),
     check("kb_versions = the four read anchors (3 investor + copy)",
           lists:sort(KbSlugs),
           lists:sort([<<"kb.investor.rental-appraisal-from-pm-agent">>,
                       <<"kb.investor.depreciation-report-quantity-surveyor">>,
                       <<"kb.investor.tenancy-in-situ-considerations">>,
                       <<"kb.copy.due-diligence">>]))].

%% --- 2. the document procurement checklist (structure now, status PENDING) --

checklist_cases() ->
    {O, _, _} = scaffold(upstream(3.8, 4.0)),
    Docs = g(O, <<"document_checklist">>),
    Ids  = [maps:get(<<"id">>, D) || D <- Docs],
    Req  = [{maps:get(<<"id">>, D), maps:get(<<"required">>, D)} || D <- Docs],
    [check("four procurement documents, in order", Ids,
           [<<"rental_appraisal">>, <<"depreciation_quote">>, <<"lease">>, <<"rental_history">>]),
     check("required known now (appraisal + depreciation required; lease/history conditional)",
           Req, [{<<"rental_appraisal">>, true}, {<<"depreciation_quote">>, true},
                 {<<"lease">>, false}, {<<"rental_history">>, false}]),
     check("every document has a bilingual name + why",
           lists:all(fun(D) -> is_loc(maps:get(<<"name">>, D))
                                   andalso is_loc(maps:get(<<"why">>, D)) end, Docs), true),
     check("every document received=false (upload pipeline not built — B)",
           lists:all(fun(D) -> maps:get(<<"received">>, D) =:= false end, Docs), true),
     check("every document reviewed=false (upload pipeline not built — B)",
           lists:all(fun(D) -> maps:get(<<"reviewed">>, D) =:= false end, Docs), true)].

%% --- 3. the computable thesis flag (§8.5 — resolver-computed, not an agent slot) -

flag(Yield, Target) ->
    {O, _, _} = scaffold(upstream(Yield, Target)),
    {g(O, <<"rental_yield_below_thesis_threshold">>), g(O, <<"investor_specific_concerns">>)}.

thesis_flag_cases() ->
    {Below, ConcernBelow}     = flag(3.8, 4.0),   %% yield below target
    {AtOrAbove, ConcernAbove} = flag(4.5, 4.0),   %% yield above target
    {NoYield, _}              = flag(null, 4.0),   %% no per-property yield
    {NoTarget, _}             = flag(3.8, null),   %% no strategy target
    [check("yield below target → flag true", Below, true),
     check("yield below target → the yield-below-thesis concern fires (bilingual detail)",
           length(ConcernBelow) =:= 1
               andalso maps:get(<<"id">>, hd(ConcernBelow)) =:= <<"rental_yield_below_thesis_threshold">>
               andalso is_loc(maps:get(<<"detail">>, hd(ConcernBelow))), true),
     check("yield at/above target → flag false", AtOrAbove, false),
     check("yield at/above target → no concern", ConcernAbove, []),
     check("no per-property yield → flag null (never false from absent data)", NoYield, null),
     check("no strategy target → flag null (never false from absent data)", NoTarget, null)].

%% --- 4. the bilingual actions + questions ------------------------------------

actions_questions_cases() ->
    {O, _, _} = scaffold(upstream(3.8, 4.0)),
    Acts = g(O, <<"actions_before_signing">>),
    Qs   = g(O, <<"questions_for_vendor">>),
    [check("four due-diligence actions before signing", length(Acts), 4),
     check("every action is bilingual", lists:all(fun is_loc/1, Acts), true),
     check("four vendor questions", length(Qs), 4),
     check("every vendor question is bilingual", lists:all(fun is_loc/1, Qs), true)].

%% --- 5. Layer-1 conformance (the fail-closed commit seam) -------------------

layer1_cases() ->
    {O1, _, _} = scaffold(upstream(3.8, 4.0)),   %% concern fires
    {O2, _, _} = scaffold(upstream(4.5, 4.0)),   %% no concern
    [check("Layer-1 conforms: outcome with a concern (enum, array<object>, array<localized_text>, bool)",
           validate(O1), ok),
     check("Layer-1 conforms: outcome with no concern + flag false",
           validate(O2), ok)].

validate(O) ->
    try fh_engine_outcome:validate(?INV, <<"risk_assessment_investor">>, O), ok
    catch _:Why -> {error, Why} end.

%% --- 6. honest-partial (no upstream → structure still, nothing fabricated) ---

honest_partial_cases() ->
    {O, _, _} = scaffold(#{}),
    Docs = g(O, <<"document_checklist">>),
    [check("no upstream: still four procurement documents (structure is KB-grounded)",
           length(Docs), 4),
     check("no upstream: thesis flag null (no yield, no target)",
           g(O, <<"rental_yield_below_thesis_threshold">>), null),
     check("no upstream: no concern fabricated", g(O, <<"investor_specific_concerns">>), []),
     check("no upstream: docs_status still pending_upload", g(O, <<"docs_status">>), <<"pending_upload">>),
     check("no upstream: still four bilingual actions",
           length(g(O, <<"actions_before_signing">>)), 4),
     check("no upstream: Layer-1 still conforms", validate(O), ok)].

%% --- helpers ----------------------------------------------------------------

check(Label, Got, Want) ->
    case Got =:= Want of
        true  -> io:format("  PASS   ~ts~n", [Label]), pass;
        false -> io:format("  FAIL   ~ts = ~p, expected ~p~n", [Label, Got, Want]), fail
    end.
