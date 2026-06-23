#!/usr/bin/env escript
%%! -sname fh_phase_playbook_conformance
%%
%% Conformance suite for fh_engine_phase_playbook (the base-turn `phase_playbook` fill,
%% component 12 — the actionable layer of the legal/temporal spine, blueprint §12 /
%% lifecycle-simulation-model §7). Loads the SAME materialized artifact the engine loads
%% (priv/kb/artifact.json via fh_engine_kb) and asserts:
%%   1. STRUCTURE — renderer=checklist; 6 phases in canonical order (incl. terminal dispose),
%%      each carrying its
%%      authored actions + risks; actions sorted by `order`; status seeded not_started;
%%      label/detail/item/action bilingual; severity in the closed enum.
%%   2. LAYER-1 CONFORMANCE — the outcome passes fh_engine_outcome:validate/2 against the
%%      compiled phase_playbook schema (the fail-closed commit-seam check) for full, empty
%%      and partial upstream.
%%   3. BUDGET_REF HONEST-PARTIAL — a budget_ref is kept ONLY when it names a cash_event
%%      present in this buyer's budget_envelope; otherwise dropped to null. component_ref
%%      is never figure-validated (passes through).
%%
%% NO upstream agent, NO Postgres. Run from engine/erlang with the build libs on the path:
%%   ERL_LIBS=_build/default/lib escript test/phase_playbook_conformance.escript

-mode(compile).

main(_) ->
    ok = fh_engine_kb:load(),
    io:format("phase_playbook conformance — fh_engine_phase_playbook "
              "(actionable Flow spine, author-content / link-never-place)~n~n"),
    R = lists:flatten([structure_cases(), conformance_cases(),
                       budget_ref_cases(), bilingual_case()]),
    Fails = [X || X <- R, X =:= fail],
    io:format("~n================================================================~n"),
    case Fails of
        [] ->
            io:format("PASS — all ~p phase_playbook anchors hold~n", [length(R)]),
            halt(0);
        _ ->
            io:format("FAIL — ~p anchor(s) mismatched~n", [length(Fails)]),
            halt(1)
    end.

%% --- synthetic upstream (the only read is cash_event ids for budget_ref) ------

full_upstream() ->
    #{<<"budget_envelope">> =>
          #{<<"cash_events">> =>
                [ev(<<"deposit">>), ev(<<"stamp_duty">>), ev(<<"other_buying_costs">>)]}}.

%% only stamp_duty present → deposit/other refs must drop, stamp_duty must be kept
%% (exercises keep_valid's false branch against a NON-empty set, not just absence).
partial_upstream() ->
    #{<<"budget_envelope">> => #{<<"cash_events">> => [ev(<<"stamp_duty">>)]}}.

ev(Id) -> #{<<"id">> => Id}.

fill(Upstream) ->
    {Outcome, Renderer, _Kb} = fh_engine_phase_playbook:fill(#{}, Upstream),
    {Outcome, Renderer}.

%% --- 1. structure -----------------------------------------------------------

structure_cases() ->
    {Outcome, Renderer} = fill(full_upstream()),
    Phases     = maps:get(<<"phases">>, Outcome),
    PhaseIds   = [maps:get(<<"phase">>, P) || P <- Phases],
    ActionCnt  = [length(maps:get(<<"actions">>, P)) || P <- Phases],
    RiskCnt    = [length(maps:get(<<"risks">>, P)) || P <- Phases],
    AllActions = all_actions(Outcome),
    AllRisks   = lists:flatmap(fun(P) -> maps:get(<<"risks">>, P) end, Phases),
    [check("renderer = checklist", Renderer, <<"checklist">>),
     check("6 phases in canonical lifecycle order (incl. terminal dispose)", PhaseIds,
           [<<"prepare">>, <<"pre_approve">>, <<"contract">>, <<"settle">>, <<"own">>,
            <<"dispose">>]),
     check("action counts per phase", ActionCnt, [5, 4, 7, 5, 4, 5]),
     check("risk counts per phase", RiskCnt, [2, 2, 6, 3, 2, 3]),
     check("every action status seeded not_started",
           lists:all(fun(A) -> maps:get(<<"status">>, A) =:= <<"not_started">> end, AllActions), true),
     check("actions within each phase sorted by order",
           lists:all(fun(P) -> sorted_by_order(maps:get(<<"actions">>, P)) end, Phases), true),
     check("2 key_assumptions", length(maps:get(<<"key_assumptions">>, Outcome)), 2),
     check("every action label+detail bilingual",
           lists:all(fun(A) -> bilingual(maps:get(<<"label">>, A)) andalso
                               bilingual(maps:get(<<"detail">>, A)) end, AllActions), true),
     check("every risk item+action bilingual",
           lists:all(fun(Rk) -> bilingual(maps:get(<<"item">>, Rk)) andalso
                                bilingual(maps:get(<<"action">>, Rk)) end, AllRisks), true),
     check("every risk severity in {low,medium,high}",
           lists:all(fun(Rk) -> lists:member(maps:get(<<"severity">>, Rk),
                                             [<<"low">>, <<"medium">>, <<"high">>]) end, AllRisks), true)].

%% --- 2. Layer-1 conformance (the fail-closed commit-seam check) -------------

conformance_cases() ->
    [begin
         {O, _} = fill(U),
         Ok = try fh_engine_outcome:validate(<<"phase_playbook">>, O), ok
              catch _:Why -> {error, Why} end,
         check(<<Name/binary, " fill conforms (Layer 1)">>, Ok, ok)
     end
     || {Name, U} <- [{<<"full">>, full_upstream()},
                      {<<"empty">>, #{}},
                      {<<"partial">>, partial_upstream()}]].

%% --- 3. budget_ref honest-partial (kept iff the cash_event exists) ----------

budget_ref_cases() ->
    {Full, _}    = fill(full_upstream()),
    {Empty, _}   = fill(#{}),
    {Partial, _} = fill(partial_upstream()),
    [check("full: 4 budget_refs kept (deposit x2, stamp_duty, other_buying_costs)",
           lists:sort(nonnull_refs(Full)),
           lists:sort([<<"deposit">>, <<"deposit">>, <<"stamp_duty">>, <<"other_buying_costs">>])),
     check("full: prepare/build_deposit budget_ref = deposit",
           budget_ref(Full, <<"prepare">>, <<"build_deposit">>), <<"deposit">>),
     check("empty: every budget_ref dropped to null (no cash_events)",
           nonnull_refs(Empty), []),
     check("partial(only stamp_duty): deposit/other refs drop, stamp_duty kept",
           lists:sort(nonnull_refs(Partial)), [<<"stamp_duty">>]),
     check("component_ref passes through even when budget_ref drops (empty)",
           component_ref(Empty, <<"prepare">>, <<"build_deposit">>), <<"cash_position">>)].

%% --- 4. bilingual spot check ------------------------------------------------

bilingual_case() ->
    {Outcome, _} = fill(full_upstream()),
    A     = find_action(Outcome, <<"prepare">>, <<"build_deposit">>),
    Label = maps:get(<<"label">>, A),
    Vi    = maps:get(<<"vi">>, Label),
    En    = maps:get(<<"en">>, Label),
    [Contract] = [P || P <- maps:get(<<"phases">>, Outcome),
                       maps:get(<<"phase">>, P) =:= <<"contract">>],
    [Risk | _] = maps:get(<<"risks">>, Contract),
    RVi = maps:get(<<"vi">>, maps:get(<<"item">>, Risk)),
    [check("action label: vi and en non-empty + distinct",
           byte_size(Vi) > 0 andalso byte_size(En) > 0 andalso Vi =/= En, true),
     check("action label: vi carries a non-ASCII char (real Vietnamese)",
           lists:any(fun(C) -> C > 127 end, unicode:characters_to_list(Vi)), true),
     check("risk item: vi carries a non-ASCII char (real Vietnamese)",
           lists:any(fun(C) -> C > 127 end, unicode:characters_to_list(RVi)), true)].

%% --- helpers ----------------------------------------------------------------

all_actions(Outcome) ->
    lists:flatmap(fun(P) -> maps:get(<<"actions">>, P) end, maps:get(<<"phases">>, Outcome)).

nonnull_refs(Outcome) ->
    [maps:get(<<"budget_ref">>, A) || A <- all_actions(Outcome),
                                      maps:get(<<"budget_ref">>, A) =/= null].

find_action(Outcome, Phase, Id) ->
    [P] = [Px || Px <- maps:get(<<"phases">>, Outcome), maps:get(<<"phase">>, Px) =:= Phase],
    [A] = [Ax || Ax <- maps:get(<<"actions">>, P), maps:get(<<"id">>, Ax) =:= Id],
    A.

budget_ref(Outcome, Phase, Id)    -> maps:get(<<"budget_ref">>, find_action(Outcome, Phase, Id)).
component_ref(Outcome, Phase, Id) -> maps:get(<<"component_ref">>, find_action(Outcome, Phase, Id)).

sorted_by_order(Actions) ->
    Orders = [maps:get(<<"order">>, A) || A <- Actions],
    Orders =:= lists:sort(Orders).

bilingual(M) ->
    is_map(M) andalso is_binary(maps:get(<<"vi">>, M, undefined))
              andalso is_binary(maps:get(<<"en">>, M, undefined)).

check(Label, Got, Want) ->
    case Got =:= Want of
        true  -> io:format("  PASS   ~ts~n", [Label]), pass;
        false -> io:format("  FAIL   ~ts = ~p, expected ~p~n", [Label, Got, Want]), fail
    end.
