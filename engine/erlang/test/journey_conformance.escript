#!/usr/bin/env escript
%%! -sname fh_journey_conformance
%%
%% Conformance suite for fh_engine_journey (the base-turn purchase_journey swimlane fill,
%% lifecycle-simulation-model §2 — the two-spines model). Loads the SAME materialized
%% artifact the engine loads (priv/kb/artifact.json via fh_engine_kb) and asserts what the
%% commit seam relies on:
%%   1. STRUCTURE — 5 phases × 4 actors; the 18-cell legal/prose grid PLUS the money cells
%%      placed from cash_events + the Own-phase recurring band.
%%   2. LAYER-1 CONFORMANCE — the outcome passes fh_engine_outcome:validate/2 against the
%%      compiled journey_swimlane schema (the fail-closed commit-seam check), incl. cells'
%%      counterparty/source_component and the interactions array.
%%   3. PLACE-NEVER-COMPUTE — every money cell IS a cash_event placed at (phase, counterparty),
%%      carrying the EXACT upstream amount + provenance; the prose cells carry NO figure; and
%%      interactions derive from the money cells (out ⟹ you→actor, in ⟹ actor→you).
%%   4. HONEST-PARTIAL — empty upstream ⟹ no money cells at all (the prose grid stands alone);
%%      never a fabricated figure.
%%
%% Run from engine/erlang with the build libs on the path (no Postgres needed):
%%   ERL_LIBS=_build/default/lib escript test/journey_conformance.escript

-mode(compile).

main(_) ->
    ok = fh_engine_kb:load(),
    io:format("journey conformance — fh_engine_journey (two-spines place-never-compute)~n~n"),
    R = lists:flatten([structure_cases(), conformance_cases(), placement_cases(),
                       interaction_cases(), honest_partial_cases(), bilingual_case(),
                       dispose_cases()]),
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
%% budget_envelope carries the cash_events ACQUISITION spine (as fh_engine_cash emits it);
%% ongoing_obligations carries the Own-phase statutory band. The journey PLACES both.

full_upstream() ->
    #{<<"budget_envelope">> =>
          #{<<"cash_events">> =>
                [ev(<<"deposit">>, <<"contract">>, <<"out">>, [30000, 35000], <<"other">>, <<"cash_position">>),
                 ev(<<"stamp_duty">>, <<"settle">>, <<"out">>, [12000, 12000], <<"government">>, <<"cash_position">>),
                 ev(<<"other_buying_costs">>, <<"settle">>, <<"out">>, [8000, 14000], <<"other">>, <<"cash_position">>),
                 ev(<<"grant_1">>, <<"settle">>, <<"in">>, [0, 10000], <<"government">>, <<"eligibility">>)]},
      <<"ongoing_obligations">> =>
          #{<<"recurring_costs_estimate">> =>
                #{<<"statutory_band">> =>
                      #{<<"low">> => 2200, <<"high">> => 3600,
                        <<"period">> => <<"year">>,
                        <<"components">> => [<<"council_rates">>, <<"water">>]}}}}.

%% a synthetic cash_event (label is irrelevant to placement — the journey carries it through).
ev(Id, Phase, Dir, Amount, Counterparty, Source) ->
    #{<<"id">> => Id, <<"phase">> => Phase, <<"direction">> => Dir,
      <<"amount">> => Amount, <<"counterparty">> => Counterparty,
      <<"is_estimate">> => false, <<"timing">> => <<"one_off">>, <<"period">> => null,
      <<"source_component">> => Source,
      <<"label">> => #{<<"vi">> => <<"Khoản tiền"/utf8>>, <<"en">> => <<"A flow">>}}.

fill(Upstream) ->
    {Outcome, Renderer, _Kb} = fh_engine_journey:fill(#{}, Upstream),
    {Outcome, Renderer}.

%% --- 1. structure -----------------------------------------------------------

structure_cases() ->
    {Outcome, Renderer} = fill(full_upstream()),
    Phases = maps:get(<<"phases">>, Outcome),
    Actors = maps:get(<<"actors">>, Outcome),
    Cells  = maps:get(<<"cells">>, Outcome),
    Prose  = [C || C <- Cells, maps:get(<<"source_component">>, C) =:= <<"purchase_journey">>],
    Money  = [C || C <- Cells, lists:member(maps:get(<<"flow_marker">>, C),
                                            [<<"money_out">>, <<"money_in">>])],
    [check("renderer = swimlane-diagram", Renderer, <<"swimlane-diagram">>),
     check("5 phases", length(Phases), 5),
     check("4 actors", length(Actors), 4),
     check("18 prose cells (the legal grid)", length(Prose), 18),
     check("5 money cells (4 cash_events + 1 own recurring)", length(Money), 5),
     check("23 cells total", length(Cells), 23)].

%% --- 2. Layer-1 conformance (the fail-closed commit-seam check) -------------

conformance_cases() ->
    {Outcome, _} = fill(full_upstream()),
    Full = try fh_engine_outcome:validate(<<"fhb-domestic-au">>, <<"journey_swimlane">>, Outcome), ok
           catch _:Why -> {error, Why} end,
    {Empty, _} = fill(#{}),
    EmptyOk = try fh_engine_outcome:validate(<<"fhb-domestic-au">>, <<"journey_swimlane">>, Empty), ok
              catch _:Why2 -> {error, Why2} end,
    [check("full fill conforms (Layer 1, incl. counterparty/source/interactions)", Full, ok),
     check("empty-upstream fill conforms (Layer 1)", EmptyOk, ok)].

%% --- 3. place-never-compute: each money cell IS a cash_event placed ----------

placement_cases() ->
    {Outcome, _} = fill(full_upstream()),
    Cells = maps:get(<<"cells">>, Outcome),
    Deposit = money_at(Cells, <<"contract">>, <<"other">>, <<"money_out">>),
    Duty    = money_at(Cells, <<"settle">>, <<"government">>, <<"money_out">>),
    Costs   = money_at(Cells, <<"settle">>, <<"other">>, <<"money_out">>),
    Grant   = money_at(Cells, <<"settle">>, <<"government">>, <<"money_in">>),
    Recur   = money_at(Cells, <<"own">>, <<"government">>, <<"money_out">>),
    ProseSettleYou = cell_at(Cells, <<"settle">>, <<"you">>),
    [check("deposit placed at (contract, other) money_out [30000,35000], cp=you, src=cash_position",
           {amount(Deposit), cp(Deposit), src(Deposit)},
           {[30000, 35000], <<"you">>, <<"cash_position">>}),
     check("duty placed at (settle, government) money_out [12000,12000]",
           amount(Duty), [12000, 12000]),
     check("other costs placed at (settle, other) money_out [8000,14000]",
           amount(Costs), [8000, 14000]),
     check("grant placed at (settle, government) money_in [0,10000], src=eligibility (PLACED, not owned here)",
           {amount(Grant), src(Grant)}, {[0, 10000], <<"eligibility">>}),
     check("own recurring placed at (own, government) money_out [2200,3600], src=ownership_planning",
           {amount(Recur), src(Recur)}, {[2200, 3600], <<"ownership_planning">>}),
     %% the legal/prose cells carry NO figure and NO flow counterparty (source = the journey)
     check("settle/you prose cell carries no figure (amount null, counterparty null, src purchase_journey)",
           {amount(ProseSettleYou), cp(ProseSettleYou), src(ProseSettleYou)},
           {null, null, <<"purchase_journey">>})].

%% --- interactions: derived from the money cells (who pays whom) --------------

interaction_cases() ->
    {Outcome, _} = fill(full_upstream()),
    Ix = maps:get(<<"interactions">>, Outcome),
    %% expected directed pairs by phase (from the 5 money cells):
    %%   contract: you→other (deposit)
    %%   settle:   you→government (duty), you→other (costs), government→you (grant)
    %%   own:      you→government (recurring)
    DepIx   = ix_at(Ix, <<"you">>, <<"other">>, <<"contract">>),
    DutyIx  = ix_at(Ix, <<"you">>, <<"government">>, <<"settle">>),
    GrantIx = ix_at(Ix, <<"government">>, <<"you">>, <<"settle">>),
    RecurIx = ix_at(Ix, <<"you">>, <<"government">>, <<"own">>),
    [check("interaction you→other in contract exists (deposit)", flows_dir(DepIx), [<<"out">>]),
     check("interaction you→government in settle exists (duty)", flows_dir(DutyIx), [<<"out">>]),
     check("interaction government→you in settle exists (grant, direction in)",
           flows_dir(GrantIx), [<<"in">>]),
     check("interaction you→government in own exists (recurring)", flows_dir(RecurIx), [<<"out">>]),
     %% interactions are derived, not invented: every flow amount matches a placed cell figure
     check("grant interaction flow amount = the placed grant figure [0,10000]",
           [maps:get(<<"amount">>, F) || F <- flows(GrantIx)], [[0, 10000]]),
     %% phases are ordered (stable lifecycle order, not maps:to_list noise)
     check("interactions are in lifecycle-phase order",
           is_phase_ordered([maps:get(<<"phase">>, I) || I <- Ix]), true)].

%% --- honest-partial: empty upstream -> NO money cells, never fabricate -------

honest_partial_cases() ->
    {Outcome, _} = fill(#{}),
    Cells = maps:get(<<"cells">>, Outcome),
    Money = [C || C <- Cells, lists:member(maps:get(<<"flow_marker">>, C),
                                          [<<"money_out">>, <<"money_in">>])],
    Ix = maps:get(<<"interactions">>, Outcome),
    [check("empty: zero money cells (no cash_events, no own band)", length(Money), 0),
     check("empty: the 18-cell prose grid still stands", length(Cells), 18),
     check("empty: no interactions (nothing flows)", length(Ix), 0),
     check("empty: no cell carries a figure", lists:all(fun(C) -> amount(C) =:= null end, Cells), true),
     %% the prose still renders (a prose item is present)
     check("empty: prepare/you keeps its prose item",
           is_map(maps:get(<<"item">>, cell_at(Cells, <<"prepare">>, <<"you">>))), true)].

%% --- bilingual spot check (vi/en both present, distinct, vi carries diacritic) #

bilingual_case() ->
    {Outcome, _} = fill(full_upstream()),
    Cells = maps:get(<<"cells">>, Outcome),
    Item = maps:get(<<"item">>, cell_at(Cells, <<"own">>, <<"government">>)),
    Vi = maps:get(<<"vi">>, Item, <<>>),
    En = maps:get(<<"en">>, Item, <<>>),
    [check("own/government prose item: vi and en both non-empty + distinct",
           byte_size(Vi) > 0 andalso byte_size(En) > 0 andalso Vi =/= En, true),
     check("own/government prose item: vi carries a non-ASCII char (real Vietnamese)",
           lists:any(fun(C) -> C > 127 end, unicode:characters_to_list(Vi)), true)].

%% --- dispose: the terminal column appears ONLY with a horizon (TW3) ----------
%% lifecycle-simulation-model §8: the journey READS disposition.dispose_cash_events and
%% PLACES them on the Dispose column (same place-never-compute discipline). Honest-partial
%% §8.2: no disposition events ⟹ no Dispose column (the empty-upstream/empty-events cases).

%% a synthetic disposition outcome carrying the H=10 loan-known dispose flows (TW1 figures):
%% sale_proceeds (in, other), selling_costs (out, other), loan_payout (out, lender); CGT
%% exempt ⟹ no cgt event. Mirrors the cash_event shape disposition emits.
disposition_outcome() ->
    #{<<"dispose_cash_events">> =>
          [disp_ev(<<"sale_proceeds">>, <<"in">>,  [975196, 1303116], <<"other">>),
           disp_ev(<<"selling_costs">>, <<"out">>, [16428, 56109],    <<"other">>),
           disp_ev(<<"loan_payout">>,   <<"out">>, [468640, 468640],  <<"lender">>)]}.

disp_ev(Id, Dir, Amount, Counterparty) ->
    #{<<"id">> => <<"dispose_", Id/binary>>, <<"phase">> => <<"dispose">>,
      <<"direction">> => Dir, <<"amount">> => Amount, <<"counterparty">> => Counterparty,
      <<"is_estimate">> => true, <<"timing">> => <<"one_off">>, <<"period">> => null,
      <<"source_component">> => <<"disposition">>,
      <<"label">> => #{<<"vi">> => <<"Khoản bán"/utf8>>, <<"en">> => <<"A dispose flow">>}}.

dispose_cases() ->
    Up = (full_upstream())#{<<"disposition">> => disposition_outcome()},
    {Outcome, _} = fill(Up),
    Phases   = maps:get(<<"phases">>, Outcome),
    PhaseIds = [maps:get(<<"id">>, P) || P <- Phases],
    Cells    = maps:get(<<"cells">>, Outcome),
    DisposeProse = [C || C <- Cells, maps:get(<<"phase">>, C) =:= <<"dispose">>,
                        maps:get(<<"source_component">>, C) =:= <<"purchase_journey">>],
    Sale  = money_at(Cells, <<"dispose">>, <<"other">>,  <<"money_in">>),
    Loan  = money_at(Cells, <<"dispose">>, <<"lender">>, <<"money_out">>),
    %% honest-partial: a disposition outcome with NO dispose_cash_events ⟹ no Dispose column.
    {EmptyDisp, _} = fill((full_upstream())#{<<"disposition">> => #{<<"dispose_cash_events">> => []}}),
    EmptyIds = [maps:get(<<"id">>, P) || P <- maps:get(<<"phases">>, EmptyDisp)],
    Conform = try fh_engine_outcome:validate(<<"fhb-domestic-au">>, <<"journey_swimlane">>, Outcome), ok
              catch _:Why -> {error, Why} end,
    [check("dispose set: 6 phases, dispose last", PhaseIds,
           [<<"prepare">>, <<"pre_approve">>, <<"contract">>, <<"settle">>, <<"own">>,
            <<"dispose">>]),
     check("dispose set: 4 dispose prose cells (the legal narrative)", length(DisposeProse), 4),
     check("dispose set: sale placed at (dispose, other) money_in [975196,1303116], src=disposition",
           {amount(Sale), src(Sale)}, {[975196, 1303116], <<"disposition">>}),
     check("dispose set: loan payout placed at (dispose, lender) money_out [468640,468640]",
           amount(Loan), [468640, 468640]),
     check("dispose set: Layer-1 conforms with the Dispose column", Conform, ok),
     check("honest-partial: empty dispose_cash_events ⟹ no Dispose column (5 phases)",
           EmptyIds,
           [<<"prepare">>, <<"pre_approve">>, <<"contract">>, <<"settle">>, <<"own">>])].

%% --- helpers ----------------------------------------------------------------

%% first cell at (phase, actor) — used for the unique prose cells.
cell_at(Cells, Phase, Actor) ->
    case [C || C <- Cells,
               maps:get(<<"phase">>, C) =:= Phase,
               maps:get(<<"actor">>, C) =:= Actor,
               maps:get(<<"source_component">>, C) =:= <<"purchase_journey">>] of
        [C | _] -> C;
        []      -> #{}
    end.

%% the money cell at (phase, actor, marker) — a (phase, actor) can hold several cells.
money_at(Cells, Phase, Actor, Marker) ->
    case [C || C <- Cells,
               maps:get(<<"phase">>, C) =:= Phase,
               maps:get(<<"actor">>, C) =:= Actor,
               maps:get(<<"flow_marker">>, C) =:= Marker] of
        [C | _] -> C;
        []      -> #{}
    end.

ix_at(Ix, From, To, Phase) ->
    case [I || I <- Ix,
               maps:get(<<"from_actor">>, I) =:= From,
               maps:get(<<"to_actor">>, I) =:= To,
               maps:get(<<"phase">>, I) =:= Phase] of
        [I | _] -> I;
        []      -> #{}
    end.

flows(Ix)     -> maps:get(<<"flows">>, Ix, []).
flows_dir(Ix) -> [maps:get(<<"direction">>, F) || F <- flows(Ix)].

amount(Cell) -> maps:get(<<"amount">>, Cell, undefined).
cp(Cell)     -> maps:get(<<"counterparty">>, Cell, undefined).
src(Cell)    -> maps:get(<<"source_component">>, Cell, undefined).

is_phase_ordered(Phases) ->
    Idx = fun(<<"prepare">>) -> 0; (<<"pre_approve">>) -> 1; (<<"contract">>) -> 2;
             (<<"settle">>) -> 3; (<<"own">>) -> 4; (<<"dispose">>) -> 5; (_) -> 9 end,
    Nums = [Idx(P) || P <- Phases],
    Nums =:= lists:sort(Nums).

check(Label, Got, Want) ->
    case Got =:= Want of
        true  -> io:format("  PASS   ~ts~n", [Label]), pass;
        false -> io:format("  FAIL   ~ts = ~p, expected ~p~n", [Label, Got, Want]), fail
    end.
