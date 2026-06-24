#!/usr/bin/env escript
%%! -sname fh_preparation_conformance
%%
%% Conformance suite for fh_engine_preparation (the base-turn `preparation` fill, component
%% 11 — the property-agnostic readiness layer, lifecycle-simulation-model §5 / blueprint §11).
%% Loads the SAME materialized artifact the engine loads (priv/kb/artifact.json via
%% fh_engine_kb) and asserts:
%%   1. STRUCTURE — renderer=checklist; the 5-doc generic checklist + 3 people-to-engage roles
%%      (generic KB content, present regardless of upstream); status seeded not_started.
%%   2. LAYER-1 CONFORMANCE — the outcome passes fh_engine_outcome:validate/2 against the
%%      compiled preparation_plan schema (the fail-closed commit-seam check), full + empty.
%%   3. PLACE-NEVER-COMPUTE — scheme_applications PLACED from scheme_stack (role→action map);
%%      money_buffer PLACED from budget_envelope (verdict + reserve, one-computer-per-figure).
%%   4. HONEST-PARTIAL — empty upstream ⟹ no scheme applications, verdict=unknown, reserve=null
%%      (never fabricated); the generic checklist + roles still stand.
%%
%% Run from engine/erlang with the build libs on the path (no Postgres needed):
%%   ERL_LIBS=_build/default/lib escript test/preparation_conformance.escript

-mode(compile).

main(_) ->
    ok = fh_engine_kb:load(),
    io:format("preparation conformance — fh_engine_preparation (readiness, place-never-compute)~n~n"),
    R = lists:flatten([structure_cases(), conformance_cases(), placement_cases(),
                       honest_partial_cases(), bilingual_case()]),
    Fails = [X || X <- R, X =:= fail],
    io:format("~n================================================================~n"),
    case Fails of
        [] ->
            io:format("PASS — all ~p preparation anchors hold~n", [length(R)]),
            halt(0);
        _ ->
            io:format("FAIL — ~p anchor(s) mismatched~n", [length(Fails)]),
            halt(1)
    end.

%% --- the canonical full-upstream fill (NSW FHB, FHG-backed) ------------------
%% scheme_stack carries four roles (deposit_guarantee, deposit_savings,
%% stamp_duty_concession, grant); budget_envelope carries a verdict + a reserve amount.

full_upstream() ->
    #{<<"scheme_stack">> =>
          #{<<"applicable_schemes">> =>
                [scheme(<<"deposit_guarantee">>), scheme(<<"deposit_savings">>),
                 scheme(<<"stamp_duty_concession">>), scheme(<<"grant">>)]},
      <<"budget_envelope">> =>
          #{<<"genuine_savings_verdict">> => <<"meets">>,
            <<"reserve_buffer">> =>
                #{<<"months_of_repayments_recommended">> => 3,
                  <<"amount">> => 15000, <<"notes">> => []}}}.

scheme(Role) -> #{<<"name">> => <<"X">>, <<"role">> => Role,
                  <<"benefit_value">> => null, <<"notes">> => []}.

fill(Upstream) ->
    {Outcome, Renderer, _Kb} = fh_engine_preparation:fill(#{}, Upstream),
    {Outcome, Renderer}.

%% --- 1. structure -----------------------------------------------------------

structure_cases() ->
    {Outcome, Renderer} = fill(full_upstream()),
    Docs   = maps:get(<<"document_checklist">>, Outcome),
    People = maps:get(<<"people_to_engage">>, Outcome),
    Ids    = [maps:get(<<"id">>, D) || D <- Docs],
    [check("renderer = checklist", Renderer, <<"checklist">>),
     check("5 document_checklist entries", length(Docs), 5),
     check("checklist ids are the generic FHB set",
           Ids, [<<"photo_id">>, <<"noa">>, <<"payslips">>, <<"bank_statements">>, <<"deposit_evidence">>]),
     check("every checklist status seeded not_started",
           lists:all(fun(D) -> maps:get(<<"status">>, D) =:= <<"not_started">> end, Docs), true),
     check("3 people_to_engage roles", length(People), 3),
     %% checklist + people carry bilingual prose (item/why, role/when/why)
     check("every checklist item+why is bilingual",
           lists:all(fun(D) -> bilingual(maps:get(<<"item">>, D)) andalso
                               bilingual(maps:get(<<"why">>, D)) end, Docs), true),
     check("every person role+when+why is bilingual",
           lists:all(fun(P) -> bilingual(maps:get(<<"role">>, P)) andalso
                               bilingual(maps:get(<<"when">>, P)) andalso
                               bilingual(maps:get(<<"why">>, P)) end, People), true)].

%% --- 2. Layer-1 conformance (the fail-closed commit-seam check) -------------

conformance_cases() ->
    {Full, _}  = fill(full_upstream()),
    FullOk = try fh_engine_outcome:validate(<<"fhb-domestic-au">>, <<"preparation_plan">>, Full), ok
             catch _:Why -> {error, Why} end,
    {Empty, _} = fill(#{}),
    EmptyOk = try fh_engine_outcome:validate(<<"fhb-domestic-au">>, <<"preparation_plan">>, Empty), ok
              catch _:Why2 -> {error, Why2} end,
    [check("full fill conforms (Layer 1)", FullOk, ok),
     check("empty-upstream fill conforms (Layer 1)", EmptyOk, ok)].

%% --- 3. place-never-compute: scheme_stack + budget_envelope are PLACED -------

placement_cases() ->
    {Outcome, _} = fill(full_upstream()),
    Apps = maps:get(<<"scheme_applications_to_prepare">>, Outcome),
    Buf  = maps:get(<<"money_buffer">>, Outcome),
    AppMap = maps:from_list([{maps:get(<<"scheme">>, A), A} || A <- Apps]),
    %% the role→action mapping (the grant has no role-specific action → default)
    ActionOf = fun(Role) -> en(maps:get(<<"action">>, maps:get(Role, AppMap))) end,
    FhgAction     = ActionOf(<<"deposit_guarantee">>),
    GrantAction   = ActionOf(<<"grant">>),
    DefaultAction = en(fh_engine_kb:copy(<<"kb.preparation.fhb-readiness">>, <<"scheme_action_default">>)),
    FhgExpected   = en(fh_engine_kb:copy(<<"kb.preparation.fhb-readiness">>, <<"scheme_action_fhg">>)),
    [check("one scheme application per applicable scheme (placed)", length(Apps), 4),
     check("deposit_guarantee → the FHG action prose", FhgAction, FhgExpected),
     check("grant → the default action prose (no role-specific copy)", GrantAction, DefaultAction),
     check("money_buffer verdict placed from budget_envelope", maps:get(<<"genuine_savings_verdict">>, Buf), <<"meets">>),
     check("money_buffer reserve placed from budget_envelope (15000)", maps:get(<<"reserve_buffer">>, Buf), 15000),
     %% the notes narrate the placed verdict: general + the verdict-specific note
     check("money_buffer notes = general + the verdict note (2)", length(maps:get(<<"notes">>, Buf)), 2)].

%% --- 4. honest-partial: empty upstream -> no applications, no fabricated figure

honest_partial_cases() ->
    {Outcome, _} = fill(#{}),
    Apps = maps:get(<<"scheme_applications_to_prepare">>, Outcome),
    Buf  = maps:get(<<"money_buffer">>, Outcome),
    Docs = maps:get(<<"document_checklist">>, Outcome),
    [check("empty: no scheme applications (nothing in scheme_stack)", length(Apps), 0),
     check("empty: verdict degrades to unknown (never fabricated)", maps:get(<<"genuine_savings_verdict">>, Buf), <<"unknown">>),
     check("empty: reserve_buffer stays null (the calculator owns it, pending)", maps:get(<<"reserve_buffer">>, Buf), null),
     %% the generic readiness content needs no upstream — it still stands
     check("empty: the generic 5-doc checklist still stands", length(Docs), 5)].

%% --- bilingual spot check ---------------------------------------------------

bilingual_case() ->
    {Outcome, _} = fill(full_upstream()),
    [Doc | _] = maps:get(<<"document_checklist">>, Outcome),
    Item = maps:get(<<"item">>, Doc),
    Vi = maps:get(<<"vi">>, Item, <<>>),
    En = maps:get(<<"en">>, Item, <<>>),
    [check("checklist item: vi and en both non-empty + distinct",
           byte_size(Vi) > 0 andalso byte_size(En) > 0 andalso Vi =/= En, true),
     check("checklist item: vi carries a non-ASCII char (real Vietnamese)",
           lists:any(fun(C) -> C > 127 end, unicode:characters_to_list(Vi)), true)].

%% --- helpers ----------------------------------------------------------------

bilingual(M) ->
    is_map(M) andalso is_binary(maps:get(<<"vi">>, M, undefined))
              andalso is_binary(maps:get(<<"en">>, M, undefined)).

en(M) -> maps:get(<<"en">>, M).

check(Label, Got, Want) ->
    case Got =:= Want of
        true  -> io:format("  PASS   ~ts~n", [Label]), pass;
        false -> io:format("  FAIL   ~ts = ~p, expected ~p~n", [Label, Got, Want]), fail
    end.
