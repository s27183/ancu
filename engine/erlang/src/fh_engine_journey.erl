-module(fh_engine_journey).

%% The base-turn `purchase_journey` fill — the whole-of-journey lifecycle swimlane
%% (lifecycle-simulation-model.md; the legal/temporal spine the prototype led with). It is
%% a RESOLVER fill (agentic-boundary.md): the journey structure + bilingual cell prose are
%% generic Mode-A KB content (kb.journey.fhg-path); the money flows on the timeline are the
%% buyer's ALREADY-COMPUTED upstream figures, PLACED — never recomputed.
%%
%% TWO PROJECTIONS OF ONE LIFECYCLE (lifecycle-simulation-model §2). The swimlane and the
%% cash calculator read ONE shared primitive — `budget_envelope.cash_events` — so they
%% cannot disagree. This component builds two kinds of cell:
%%   - LEGAL/PROSE cells: one per meaningful (phase, actor), authored in kb.journey.fhg-path,
%%     flow_marker ∈ {none, document, milestone}, NO amount, counterparty=null. They are the
%%     legal-spine narrative; source_component = `purchase_journey` (it owns its own prose).
%%   - MONEY cells: GENERATED from cash_events. §2: "the swimlane's amount-bearing cells ARE
%%     cash events." Each event is placed as a cell at (phase, actor = event.counterparty) —
%%     the non-`you` party gets the row — with the cell's own counterparty = `you` (the buyer
%%     is the implicit other end of every event), flow_marker from direction, and the amount +
%%     source_component carried through verbatim. The Own phase adds one recurring money cell
%%     placed from ownership_planning's statutory band (cash_events is Prepare→Settle only).
%%
%% One-computer-per-figure (the load-bearing constraint, [[verify-regulated-figures-by-
%% postcondition]], [[place-upstream-figures-dont-recompute]]): every figure on the timeline is
%% read from budget_envelope / ongoing_obligations and dropped onto a cell. This component
%% computes NO figure of its own, so there is no second computer to verify — the conformance
%% burden stays entirely on cash_position / eligibility / ownership_planning. This is why it
%% runs LAST in the base DAG; its read of the downstream ownership_planning (9→10) is a
%% forward edge, still acyclic.
%%
%% `interactions` (lifecycle-simulation-model §2 "who pays whom"): because every money cell
%% names both ends (actor + counterparty=you), the who-pays/talks-to-whom view falls straight
%% out of the cells — derived by PLACEMENT, never recomputed.
%%
%% The journey_swimlane outcome is mode-general (phases × actors × cells); Modes B/C/D reuse
%% the schema + the mode-agnostic swimlane-diagram renderer with their own kb.journey.* doc +
%% resolver (plan-card-lifecycle-restoration.md §3.3). Mode A only here.

-export([fill/2]).
%% exported for the conformance harness:
-export([phases/0, actors/0, prose_cells/0, money_cells/2, interactions/1]).

-define(COPY, <<"kb.journey.fhg-path">>).   %% bilingual labels + cell prose (no params)

%% --- entry -------------------------------------------------------------------

-spec fill(map(), map()) -> {map(), binary(), [map()]}.
fill(_Args, Upstream) ->
    Budget        = maps:get(<<"budget_envelope">>, Upstream, #{}),
    Ownership     = maps:get(<<"ongoing_obligations">>, Upstream, #{}),
    Disposition   = maps:get(<<"disposition">>, Upstream, #{}),
    Events        = maps:get(<<"cash_events">>, Budget, []),
    DisposeEvents = maps:get(<<"dispose_cash_events">>, Disposition, []),
    %% Honest-partial: the terminal Dispose column (its prose + the placed dispose money
    %% cells) renders ONLY when a hold horizon H is set — disposition then emits
    %% dispose_cash_events; with H unset it emits none, so no empty Dispose column lands on
    %% the legal spine (lifecycle-simulation-model §8.2, the §7.2 honest-partial discipline).
    HasDispose    = DisposeEvents =/= [],
    DisposeCells  = case HasDispose of
                        true  -> dispose_prose_cells()
                                 ++ [money_cell_from_event(E) || E <- DisposeEvents];
                        false -> []
                    end,
    Cells = prose_cells() ++ money_cells(Events, Ownership) ++ DisposeCells,
    Outcome = #{
        <<"phases">>       => rendered_phases(HasDispose),
        <<"actors">>       => actors(),
        <<"cells">>        => Cells,
        <<"interactions">> => interactions(Cells),
        <<"key_assumptions">> =>
            [copy(<<"assumption_indicative">>), copy(<<"assumption_figures">>)]
    },
    KbVersions = fh_engine_kb:kb_anchors([?COPY]),
    {Outcome, <<"swimlane-diagram">>, KbVersions}.

%% --- the swimlane structure (Mode-A FHB: Prepare → … → Own → Dispose) --------

%% The canonical lifecycle phase enum (6 values, incl. the terminal `dispose`,
%% lifecycle-simulation-model §8.1 — mirrored by fh_engine_phase_playbook:?PHASE_ORDER and
%% fh_engine_h_checklist_status:?PHASES). The swimlane RENDERS `dispose` only when a horizon
%% is set (rendered_phases/1); the enum itself is fixed.
-spec phases() -> [map()].
phases() ->
    [phase(<<"prepare">>,     <<"phase_prepare">>),
     phase(<<"pre_approve">>, <<"phase_pre_approve">>),
     phase(<<"contract">>,    <<"phase_contract">>),
     phase(<<"settle">>,      <<"phase_settle">>),
     phase(<<"own">>,         <<"phase_own">>),
     phase(<<"dispose">>,     <<"phase_dispose">>)].

%% The rendered swimlane columns: the full enum when a horizon is set, else the 5
%% acquisition→own phases (the terminal Dispose column is dropped — honest-partial §8.2).
-spec rendered_phases(boolean()) -> [map()].
rendered_phases(true)  -> phases();
rendered_phases(false) -> [P || P <- phases(), maps:get(<<"id">>, P) =/= <<"dispose">>].

-spec actors() -> [map()].
actors() ->
    [actor(<<"you">>,        <<"actor_you">>),
     actor(<<"government">>, <<"actor_government">>),
     actor(<<"lender">>,     <<"actor_lender">>),
     actor(<<"other">>,      <<"actor_other">>)].

%% --- the legal/prose spine (one prose cell per meaningful (phase, actor)) ----
%% These carry NO figure — they are the legal narrative. The money flows are placed
%% separately by money_cells/2 (the financial spine), at their TRUE phase, in the
%% recipient's lane. So prepare/you is "save up" (the deposit OUTFLOW lands at contract);
%% settle/you is "pay the balance" (the individual out-events land in government/other).
-spec prose_cells() -> [map()].
prose_cells() ->
    [prose(<<"prepare">>, <<"you">>,        <<"cell_prepare_you">>,        <<"none">>),
     prose(<<"prepare">>, <<"government">>, <<"cell_prepare_government">>, <<"none">>),
     prose(<<"prepare">>, <<"lender">>,     <<"cell_prepare_lender">>,     <<"none">>),

     prose(<<"pre_approve">>, <<"you">>,        <<"cell_pre_approve_you">>,        <<"document">>),
     prose(<<"pre_approve">>, <<"government">>, <<"cell_pre_approve_government">>, <<"milestone">>),
     prose(<<"pre_approve">>, <<"lender">>,     <<"cell_pre_approve_lender">>,     <<"milestone">>),
     prose(<<"pre_approve">>, <<"other">>,      <<"cell_pre_approve_other">>,      <<"none">>),

     prose(<<"contract">>, <<"you">>,        <<"cell_contract_you">>,        <<"milestone">>),
     prose(<<"contract">>, <<"government">>, <<"cell_contract_government">>, <<"document">>),
     prose(<<"contract">>, <<"lender">>,     <<"cell_contract_lender">>,     <<"document">>),
     prose(<<"contract">>, <<"other">>,      <<"cell_contract_other">>,      <<"document">>),

     prose(<<"settle">>, <<"you">>,        <<"cell_settle_you">>,        <<"milestone">>),
     prose(<<"settle">>, <<"government">>, <<"cell_settle_government">>, <<"none">>),
     prose(<<"settle">>, <<"lender">>,     <<"cell_settle_lender">>,     <<"milestone">>),
     prose(<<"settle">>, <<"other">>,      <<"cell_settle_other">>,      <<"milestone">>),

     prose(<<"own">>, <<"you">>,        <<"cell_own_you">>,        <<"milestone">>),
     prose(<<"own">>, <<"government">>, <<"cell_own_government">>, <<"none">>),
     prose(<<"own">>, <<"lender">>,     <<"cell_own_lender">>,     <<"none">>)].

%% --- the Dispose-phase legal/prose spine (added only when a horizon is set) ----
%% The terminal column's narrative (kb.journey.fhg-path): the sale (you), the main-residence
%% CGT exemption (government), the loan discharge (lender), and the agent/conveyancer
%% (other). The money flows — sale_proceeds / selling_costs / loan_payout — are PLACED
%% separately from disposition's dispose_cash_events; these carry no figure.
-spec dispose_prose_cells() -> [map()].
dispose_prose_cells() ->
    [prose(<<"dispose">>, <<"you">>,        <<"cell_dispose_you">>,        <<"milestone">>),
     prose(<<"dispose">>, <<"government">>, <<"cell_dispose_government">>, <<"none">>),
     prose(<<"dispose">>, <<"lender">>,     <<"cell_dispose_lender">>,     <<"milestone">>),
     prose(<<"dispose">>, <<"other">>,      <<"cell_dispose_other">>,      <<"milestone">>)].

%% --- the financial spine, PLACED (the amount-bearing cells ARE cash events) --
%% One money cell per cash_event: placed at (phase, actor = event.counterparty), the
%% cell's own counterparty = `you` (the buyer is the implicit other end), marker from
%% direction, amount + source_component carried through verbatim. The Own phase appends
%% the recurring statutory band from ownership_planning (cash_events is Prepare→Settle).
-spec money_cells([map()], map()) -> [map()].
money_cells(Events, Ownership) ->
    [money_cell_from_event(E) || E <- Events] ++ own_recurring_cells(Ownership).

money_cell_from_event(E) ->
    money_cell(maps:get(<<"phase">>, E),
               maps:get(<<"counterparty">>, E),         %% the non-`you` party gets the row
               maps:get(<<"label">>, E),
               marker(maps:get(<<"direction">>, E)),
               maps:get(<<"amount">>, E),
               maps:get(<<"source_component">>, E)).

%% The Own-phase recurring outgoing: the council-rates + water statutory band from
%% ownership_planning, placed as a yearly money_out to government. Honest-partial: emit
%% only when the band carries a real [low, high] (never a fabricated figure).
own_recurring_cells(Ownership) ->
    Rec  = maps:get(<<"recurring_costs_estimate">>, Ownership, #{}),
    Band = maps:get(<<"statutory_band">>, Rec, #{}),
    case band_range(Band) of
        null  -> [];
        Range -> [money_cell(<<"own">>, <<"government">>, copy(<<"cell_own_recurring">>),
                             <<"money_out">>, Range, <<"ownership_planning">>)]
    end.

%% --- interactions: the who-pays/talks-to-whom view, DERIVED from money cells --
%% out ⟹ you → actor (you pay the counterparty); in ⟹ actor → you (the counterparty
%% pays you). Grouped by (from, to, phase); flows preserve cell order, the list is sorted
%% by lifecycle phase then party for a stable outcome.
-spec interactions([map()]) -> [map()].
interactions(Cells) ->
    Money = [C || C <- Cells,
                  lists:member(maps:get(<<"flow_marker">>, C),
                               [<<"money_out">>, <<"money_in">>])],
    Grouped = lists:foldl(fun add_flow/2, [], Money),
    Sorted = lists:sort(fun({Ka, _}, {Kb, _}) -> key_order(Ka) =< key_order(Kb) end,
                        Grouped),
    [#{<<"from_actor">> => From, <<"to_actor">> => To, <<"phase">> => Phase,
       <<"flows">> => lists:reverse(Flows)}
     || {{From, To, Phase}, Flows} <- Sorted].

add_flow(Cell, Acc) ->
    Phase  = maps:get(<<"phase">>, Cell),
    Actor  = maps:get(<<"actor">>, Cell),                %% the non-`you` party
    {From, To, Dir} =
        case maps:get(<<"flow_marker">>, Cell) of
            <<"money_out">> -> {<<"you">>, Actor, <<"out">>};
            <<"money_in">>  -> {Actor, <<"you">>, <<"in">>}
        end,
    Flow = #{<<"label">>     => maps:get(<<"item">>, Cell),
             <<"direction">> => Dir,
             <<"amount">>    => maps:get(<<"amount">>, Cell)},
    Key = {From, To, Phase},
    case lists:keytake(Key, 1, Acc) of
        {value, {Key, Flows}, Rest} -> [{Key, [Flow | Flows]} | Rest];
        false                       -> [{Key, [Flow]} | Acc]
    end.

%% lifecycle order for stable interactions: by phase, then from-actor, then to-actor.
key_order({From, To, Phase}) -> {phase_index(Phase), From, To}.

phase_index(<<"prepare">>)     -> 0;
phase_index(<<"pre_approve">>) -> 1;
phase_index(<<"contract">>)    -> 2;
phase_index(<<"settle">>)      -> 3;
phase_index(<<"own">>)         -> 4;
phase_index(<<"dispose">>)     -> 5;
phase_index(_)                 -> 9.

%% --- builders ----------------------------------------------------------------

phase(Id, CopyId) -> #{<<"id">> => Id, <<"label">> => copy(CopyId)}.
actor(Id, CopyId) -> #{<<"id">> => Id, <<"label">> => copy(CopyId)}.

%% a legal/prose cell: no figure, no flow counterparty; the journey owns its own prose.
prose(Phase, Actor, CopyId, Marker) ->
    cell(Phase, Actor, copy(CopyId), Marker, null, null, <<"purchase_journey">>).

%% a money cell: the placed figure rides in `amount`; counterparty is the buyer (`you`),
%% source_component traces the figure to its OWNER (cash_position / eligibility /
%% ownership_planning) for the placement/provenance gate.
money_cell(Phase, Actor, Item, Marker, Amount, Source) ->
    cell(Phase, Actor, Item, Marker, Amount, <<"you">>, Source).

cell(Phase, Actor, Item, Marker, Amount, Counterparty, Source) ->
    #{<<"phase">>            => Phase,
      <<"actor">>            => Actor,
      <<"item">>             => Item,
      <<"flow_marker">>      => Marker,
      <<"amount">>           => Amount,
      <<"counterparty">>     => Counterparty,
      <<"source_component">> => Source}.

marker(<<"out">>) -> <<"money_out">>;
marker(<<"in">>)  -> <<"money_in">>.

%% --- figure normalisers (place, never compute) -------------------------------

%% the ownership statutory_band {low, high} → a [lo, hi] money_range; anything else → null.
band_range(#{<<"low">> := Lo, <<"high">> := Hi}) when is_number(Lo), is_number(Hi) -> [Lo, Hi];
band_range(_) -> null.

%% A bilingual label/line from the journey KB doc. No params — the figures are structured
%% `amount` fields, not interpolated — so the template is returned as-is.
-spec copy(binary()) -> fh_engine_i18n:localized().
copy(Id) ->
    fh_engine_kb:copy(?COPY, Id).
