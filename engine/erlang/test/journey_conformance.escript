#!/usr/bin/env escript
%%! -sname fh_journey_conformance
%%
%% Conformance suite for fh_engine_journey (the base-turn purchase_journey swimlane
%% fill, plan-card-lifecycle-restoration §7). Loads the SAME materialized artifact the
%% engine loads (priv/kb/artifact.json via fh_engine_kb) and asserts three things the
%% commit seam relies on:
%%   1. STRUCTURE — 5 phases × 4 actors × 18 cells, the Mode-A FHB lifecycle.
%%   2. LAYER-1 CONFORMANCE — the outcome passes fh_engine_outcome:validate/2 against the
%%      compiled journey_swimlane schema (the fail-closed commit-seam check), incl. every
%%      cell's bilingual `item` and every figure being a number (never a {vi,en} or string).
%%   3. PLACE-NEVER-COMPUTE — the money cells carry the EXACT upstream figures
%%      (budget_envelope/scheme_stack), and honest-partial holds: with empty upstream the
%%      money cells degrade to flow_marker=none + amount=null, never a fabricated figure.
%%
%% Run from engine/erlang with the build libs on the path (no Postgres needed):
%%   ERL_LIBS=_build/default/lib escript test/journey_conformance.escript

-mode(compile).

main(_) ->
    ok = fh_engine_kb:load(),
    io:format("journey conformance — fh_engine_journey (place-never-compute swimlane)~n~n"),
    R = lists:flatten([structure_cases(), conformance_cases(), placement_cases(),
                       honest_partial_cases(), bilingual_case()]),
    Fails = [X || X <- R, X =:= fail],
    io:format("~n================================================================~n"),
    case Fails of
        [] ->
            io:format("PASS — all ~p journey anchors hold~n", [length(R)]),
            halt(0);
        _ ->
            io:format("FAIL — ~p anchor(s) mismatched~n", [length(Fails)]),
            halt(1)
    end.

%% --- the canonical full-upstream fill (NSW FHB, FHG-backed) ------------------

full_upstream() ->
    #{<<"scheme_stack">> => #{<<"total_benefit_value">> => [30000, 45000]},
      <<"budget_envelope">> =>
          #{<<"deposit">> => #{<<"minimum_required_amount">> => [30000, 35000]},
            <<"stamp_duty">> => #{<<"after_concession">> => 12000},
            <<"total_cash_required">> => [45000, 60000]}}.

fill(Upstream) ->
    {Outcome, Renderer, _Kb} = fh_engine_journey:fill(#{}, Upstream),
    {Outcome, Renderer}.

%% --- 1. structure -----------------------------------------------------------

structure_cases() ->
    {Outcome, Renderer} = fill(full_upstream()),
    Phases = maps:get(<<"phases">>, Outcome),
    Actors = maps:get(<<"actors">>, Outcome),
    Cells  = maps:get(<<"cells">>, Outcome),
    [check("renderer = swimlane-diagram", Renderer, <<"swimlane-diagram">>),
     check("5 phases", length(Phases), 5),
     check("4 actors", length(Actors), 4),
     check("18 cells", length(Cells), 18)].

%% --- 2. Layer-1 conformance (the fail-closed commit-seam check) -------------

conformance_cases() ->
    {Outcome, _} = fill(full_upstream()),
    Full = try fh_engine_outcome:validate(<<"journey_swimlane">>, Outcome), ok
           catch _:Why -> {error, Why} end,
    {Empty, _} = fill(#{}),
    EmptyOk = try fh_engine_outcome:validate(<<"journey_swimlane">>, Empty), ok
              catch _:Why2 -> {error, Why2} end,
    [check("full fill conforms (Layer 1)", Full, ok),
     check("empty-upstream fill conforms (Layer 1)", EmptyOk, ok)].

%% --- 3. place-never-compute: the exact upstream figures land on the cells ----

placement_cases() ->
    {Outcome, _} = fill(full_upstream()),
    Cells = maps:get(<<"cells">>, Outcome),
    Deposit = cell_at(Cells, <<"prepare">>, <<"you">>),
    Benefit = cell_at(Cells, <<"pre_approve">>, <<"government">>),
    Total   = cell_at(Cells, <<"settle">>, <<"you">>),
    Duty    = cell_at(Cells, <<"settle">>, <<"government">>),
    [check("prepare/you deposit placed (money_out [30000,35000])",
           {marker(Deposit), amount(Deposit)}, {<<"money_out">>, [30000, 35000]}),
     check("pre_approve/government benefit placed (money_in [30000,45000])",
           {marker(Benefit), amount(Benefit)}, {<<"money_in">>, [30000, 45000]}),
     check("settle/you total placed (money_out [45000,60000])",
           {marker(Total), amount(Total)}, {<<"money_out">>, [45000, 60000]}),
     check("settle/government duty placed as collapsed point [12000,12000]",
           {marker(Duty), amount(Duty)}, {<<"money_out">>, [12000, 12000]})].

%% --- honest-partial: empty upstream -> money cells degrade, never fabricate --

honest_partial_cases() ->
    {Outcome, _} = fill(#{}),
    Cells = maps:get(<<"cells">>, Outcome),
    Deposit = cell_at(Cells, <<"prepare">>, <<"you">>),
    Total   = cell_at(Cells, <<"settle">>, <<"you">>),
    [check("empty: prepare/you degrades to none + null amount",
           {marker(Deposit), amount(Deposit)}, {<<"none">>, null}),
     check("empty: settle/you degrades to none + null amount",
           {marker(Total), amount(Total)}, {<<"none">>, null}),
     %% the prose still renders (the cell item is present even with no figure)
     check("empty: prepare/you keeps its prose item",
           is_map(maps:get(<<"item">>, Deposit)), true)].

%% --- bilingual spot check (vi/en both present, distinct, vi carries diacritic) #

bilingual_case() ->
    {Outcome, _} = fill(full_upstream()),
    Cells = maps:get(<<"cells">>, Outcome),
    Item = maps:get(<<"item">>, cell_at(Cells, <<"settle">>, <<"you">>)),
    Vi = maps:get(<<"vi">>, Item, <<>>),
    En = maps:get(<<"en">>, Item, <<>>),
    [check("settle/you item: vi and en both non-empty + distinct",
           byte_size(Vi) > 0 andalso byte_size(En) > 0 andalso Vi =/= En, true),
     check("settle/you item: vi carries a non-ASCII char (real Vietnamese)",
           lists:any(fun(C) -> C > 127 end, unicode:characters_to_list(Vi)), true)].

%% --- helpers ----------------------------------------------------------------

cell_at(Cells, Phase, Actor) ->
    case [C || C <- Cells,
               maps:get(<<"phase">>, C) =:= Phase,
               maps:get(<<"actor">>, C) =:= Actor] of
        [C | _] -> C;
        []      -> #{}
    end.

marker(Cell) -> maps:get(<<"flow_marker">>, Cell, undefined).
amount(Cell) -> maps:get(<<"amount">>, Cell, undefined).

check(Label, Got, Want) ->
    case Got =:= Want of
        true  -> io:format("  PASS   ~s~n", [Label]), pass;
        false -> io:format("  FAIL   ~s = ~p, expected ~p~n", [Label, Got, Want]), fail
    end.
