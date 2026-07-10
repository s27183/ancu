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
%% resolver (plan-card-lifecycle-restoration.md §3.3). Mode C landed 2026-07-10 (fill_investor/1,
%% kb.journey.investor-path — six actors, not Mode A's four); B/D still to come.
%%
%% MULTI-SOURCE HARVEST (2026-07-10, [[unify-views-as-projections-of-one-primitive]]): `Events`
%% is no longer read off one hardcoded outcome key. `harvest_cash_events/1` concatenates the
%% `cash_events` field off EVERY upstream outcome that exposes it — Mode A has exactly one
%% source (budget_envelope, unchanged behaviour); Mode C has four (budget_envelope_investor,
%% cash_flow_projection, tax_optimised_structure, + dispose_cash_events read separately below).
%% This is what lets a mode add a new cash_events-bearing component with ZERO change here —
%% the root fix, not a per-mode branch (advisor review, 2026-07-10 wiring pass).

-export([fill/2]).
%% exported for the conformance harness (Mode-A shape, UNCHANGED signatures):
-export([phases/0, actors/0, prose_cells/0, money_cells/2, interactions/1]).

-define(COPY,          <<"kb.journey.fhg-path">>).       %% Mode A bilingual labels + cell prose
-define(INVESTOR_COPY, <<"kb.journey.investor-path">>).  %% Mode C bilingual labels + cell prose
-define(INVESTOR_FOREIGN_COPY, <<"kb.journey.investor-foreign-path">>).  %% Mode D bilingual labels + cell prose

%% --- entry ---------------------------------------------------------------

-spec fill(map(), map()) -> {map(), binary(), [map()]}.
fill(Args, Upstream) ->
    case maps:get(blueprint_slug, Args, <<"fhb-domestic-au">>) of
        <<"investor-domestic-au">> -> fill_investor(Upstream);
        <<"investor-foreign-au">>  -> fill_investor_foreign(Upstream);
        _                          -> fill_fhb(Upstream)
    end.

%% --- Mode A (FHB) ----------------------------------------------------------

fill_fhb(Upstream) ->
    Ownership     = maps:get(<<"ongoing_obligations">>, Upstream, #{}),
    Disposition   = maps:get(<<"disposition">>, Upstream, #{}),
    Events        = harvest_cash_events(Upstream),
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

%% --- Mode C (investor) ------------------------------------------------------
%% Same placement discipline as fill_fhb/1: no figure computed here, every money cell IS a
%% harvested cash_event. No `ongoing_obligations` upstream (investor DAG has no equivalent
%% component) — money_cells/2's own_recurring_cells/1 half no-ops on an empty map, so it is
%% reused as-is (no Mode-C-specific money-cell code needed at all).
fill_investor(Upstream) ->
    Disposition   = maps:get(<<"disposition">>, Upstream, #{}),
    Events        = harvest_cash_events(Upstream),
    DisposeEvents = maps:get(<<"dispose_cash_events">>, Disposition, []),
    HasDispose    = DisposeEvents =/= [],
    DisposeCells  = case HasDispose of
                        true  -> investor_dispose_prose_cells()
                                 ++ [money_cell_from_event(E) || E <- DisposeEvents];
                        false -> []
                    end,
    Cells = investor_prose_cells() ++ money_cells(Events, #{}) ++ DisposeCells,
    Outcome = #{
        <<"phases">>       => investor_rendered_phases(HasDispose),
        <<"actors">>       => investor_actors(),
        <<"cells">>        => Cells,
        <<"interactions">> => interactions(Cells),
        <<"key_assumptions">> =>
            [investor_copy(<<"assumption_indicative">>), investor_copy(<<"assumption_figures">>),
             investor_copy(<<"assumption_no_fhb_schemes">>)]
    },
    KbVersions = fh_engine_kb:kb_anchors([?INVESTOR_COPY]),
    {Outcome, <<"swimlane-diagram">>, KbVersions}.

%% --- Mode D (foreign investor) ----------------------------------------------
%% Same placement discipline + same six-actor structure as fill_investor/1 (Mode C) — the
%% phases/actors builders are REUSED unchanged (investor_phases/0, investor_rendered_phases/1,
%% investor_actors/0), only the KB copy doc and the authored prose cells differ
%% (kb.journey.investor-foreign-path §"Actors" — the FX/transfer provider is a `services` cell,
%% not a new actor row; see that doc's rationale). Harvests cash_events the SAME generic way —
%% cash_position/yield_modelling/tax_structure_non_resident + disposition.dispose_cash_events —
%% with ZERO Mode-D-specific journey code beyond the prose (2026-07-10, task 8).
fill_investor_foreign(Upstream) ->
    Disposition   = maps:get(<<"disposition">>, Upstream, #{}),
    Events        = harvest_cash_events(Upstream),
    DisposeEvents = maps:get(<<"dispose_cash_events">>, Disposition, []),
    HasDispose    = DisposeEvents =/= [],
    DisposeCells  = case HasDispose of
                        true  -> investor_foreign_dispose_prose_cells()
                                 ++ [money_cell_from_event(E) || E <- DisposeEvents];
                        false -> []
                    end,
    Cells = investor_foreign_prose_cells() ++ money_cells(Events, #{}) ++ DisposeCells,
    Outcome = #{
        <<"phases">>       => investor_rendered_phases(HasDispose),
        <<"actors">>       => investor_actors(),
        <<"cells">>        => Cells,
        <<"interactions">> => interactions(Cells),
        <<"key_assumptions">> =>
            [investor_foreign_copy(<<"assumption_indicative">>),
             investor_foreign_copy(<<"assumption_figures">>),
             investor_foreign_copy(<<"assumption_no_fhb_schemes">>)]
    },
    KbVersions = fh_engine_kb:kb_anchors([?INVESTOR_FOREIGN_COPY]),
    {Outcome, <<"swimlane-diagram">>, KbVersions}.

%% every upstream outcome that carries a `cash_events` field, concatenated (order does not
%% matter for correctness — interactions/1 re-sorts by lifecycle phase regardless).
harvest_cash_events(Upstream) ->
    lists:flatten([maps:get(<<"cash_events">>, V, []) || V <- maps:values(Upstream), is_map(V)]).

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

%% --- Mode C (investor) structure: phases, actors, prose ----------------------
%% Same shape as the Mode-A builders above (phase/actor/prose/cell), pointed at
%% kb.journey.investor-path instead of kb.journey.fhg-path. Phase IDS are identical to
%% Mode A's (yield_modelling/tax_structure's own outcome text places figures "at phase
%% own" regardless of mode); only the actor set and the authored cell prose differ — six
%% actors (Property manager, Tenant added; "Other" renamed "Services") because rent is a
%% real actor-attributable cash flow (kb.journey.investor-path's own rationale).

investor_phases() ->
    [iphase(<<"prepare">>,     <<"phase_prepare">>),
     iphase(<<"pre_approve">>, <<"phase_pre_approve">>),
     iphase(<<"contract">>,    <<"phase_contract">>),
     iphase(<<"settle">>,      <<"phase_settle">>),
     iphase(<<"own">>,         <<"phase_own">>),
     iphase(<<"dispose">>,     <<"phase_dispose">>)].

investor_rendered_phases(true)  -> investor_phases();
investor_rendered_phases(false) -> [P || P <- investor_phases(), maps:get(<<"id">>, P) =/= <<"dispose">>].

investor_actors() ->
    [iactor(<<"you">>,              <<"actor_you">>),
     iactor(<<"government">>,       <<"actor_government">>),
     iactor(<<"lender">>,           <<"actor_lender">>),
     iactor(<<"property_manager">>, <<"actor_property_manager">>),
     iactor(<<"tenant">>,           <<"actor_tenant">>),
     iactor(<<"services">>,         <<"actor_services">>)].

%% The legal/prose spine (kb.journey.investor-path's authored `cell_<phase>_<actor>` keys).
%% flow_marker is a narrative-significance judgment (none = informational, document =
%% paperwork exchanged, milestone = a significant one-time event/payment), assigned by
%% the same reading each Mode-A cell already got — not KB-declared (the KB doc carries no
%% marker field). `cell_own_recurring` (authored, general "how the hold phase nets out"
%% prose) is intentionally NOT placed here: the four hold-phase money cells (rental_income/
%% operating_expenses/loan_interest/tax_refund, harvested from cash_events) already carry
%% this content per-counterparty; a fifth combined prose cell would duplicate them with no
%% actor slot of its own. Flagged, not silently dropped.
investor_prose_cells() ->
    [iprose(<<"prepare">>, <<"you">>,      <<"cell_prepare_you">>,       <<"none">>),
     iprose(<<"prepare">>, <<"lender">>,   <<"cell_prepare_lender">>,   <<"none">>),
     iprose(<<"prepare">>, <<"services">>, <<"cell_prepare_services">>, <<"none">>),

     iprose(<<"pre_approve">>, <<"you">>,      <<"cell_pre_approve_you">>,      <<"document">>),
     iprose(<<"pre_approve">>, <<"lender">>,   <<"cell_pre_approve_lender">>,   <<"milestone">>),
     iprose(<<"pre_approve">>, <<"services">>, <<"cell_pre_approve_services">>, <<"none">>),

     iprose(<<"contract">>, <<"you">>,             <<"cell_contract_you">>,              <<"milestone">>),
     iprose(<<"contract">>, <<"government">>,      <<"cell_contract_government">>,       <<"document">>),
     iprose(<<"contract">>, <<"lender">>,          <<"cell_contract_lender">>,           <<"document">>),
     iprose(<<"contract">>, <<"property_manager">>,<<"cell_contract_property_manager">>, <<"document">>),
     iprose(<<"contract">>, <<"tenant">>,          <<"cell_contract_tenant">>,           <<"document">>),
     iprose(<<"contract">>, <<"services">>,        <<"cell_contract_services">>,         <<"document">>),

     iprose(<<"settle">>, <<"you">>,              <<"cell_settle_you">>,              <<"milestone">>),
     iprose(<<"settle">>, <<"government">>,       <<"cell_settle_government">>,       <<"milestone">>),
     iprose(<<"settle">>, <<"lender">>,           <<"cell_settle_lender">>,           <<"milestone">>),
     iprose(<<"settle">>, <<"property_manager">>, <<"cell_settle_property_manager">>, <<"milestone">>),
     iprose(<<"settle">>, <<"services">>,         <<"cell_settle_services">>,         <<"milestone">>),

     iprose(<<"own">>, <<"you">>,              <<"cell_own_you">>,              <<"milestone">>),
     iprose(<<"own">>, <<"government">>,       <<"cell_own_government">>,       <<"none">>),
     iprose(<<"own">>, <<"lender">>,           <<"cell_own_lender">>,           <<"none">>),
     iprose(<<"own">>, <<"property_manager">>, <<"cell_own_property_manager">>, <<"none">>),
     iprose(<<"own">>, <<"tenant">>,           <<"cell_own_tenant">>,           <<"none">>),
     iprose(<<"own">>, <<"services">>,         <<"cell_own_services">>,         <<"none">>)].

%% The Dispose-phase legal/prose spine (added only when a horizon is set), same role as
%% Mode A's dispose_prose_cells/0. No `tenant` row — kb.journey.investor-path authors none
%% (a tenancy either ends before sale or transfers with the property; not a distinct
%% dispose-phase narrative beat the way property_manager's notice-period coordination is).
investor_dispose_prose_cells() ->
    [iprose(<<"dispose">>, <<"you">>,              <<"cell_dispose_you">>,              <<"milestone">>),
     iprose(<<"dispose">>, <<"government">>,       <<"cell_dispose_government">>,       <<"none">>),
     iprose(<<"dispose">>, <<"lender">>,           <<"cell_dispose_lender">>,           <<"milestone">>),
     iprose(<<"dispose">>, <<"property_manager">>, <<"cell_dispose_property_manager">>, <<"document">>),
     iprose(<<"dispose">>, <<"services">>,         <<"cell_dispose_services">>,         <<"milestone">>)].

iphase(Id, CopyId) -> #{<<"id">> => Id, <<"label">> => investor_copy(CopyId)}.
iactor(Id, CopyId) -> #{<<"id">> => Id, <<"label">> => investor_copy(CopyId)}.

iprose(Phase, Actor, CopyId, Marker) ->
    cell(Phase, Actor, investor_copy(CopyId), Marker, null, null, <<"purchase_journey">>).

investor_copy(Id) -> fh_engine_kb:copy(?INVESTOR_COPY, Id).

%% --- Mode D (foreign investor) structure: prose only -------------------------
%% phases/actors are the SAME builders as Mode C (investor_phases/0, investor_actors/0,
%% investor_rendered_phases/1) — reused unchanged, not redefined. Only the authored cell
%% prose differs, drawn from kb.journey.investor-foreign-path — FIRB gate content lands on
%% government/lender cells across pre_approve→contract→settle; the cross-border transfer
%% milestone lands on services cells across the same span (kb.journey.investor-foreign-
%% path's own "Phases" rationale — neither is a new phase or a new actor row).

investor_foreign_prose_cells() ->
    [diprose(<<"prepare">>, <<"you">>,      <<"cell_prepare_you">>,      <<"none">>),
     diprose(<<"prepare">>, <<"lender">>,   <<"cell_prepare_lender">>,   <<"none">>),
     diprose(<<"prepare">>, <<"services">>, <<"cell_prepare_services">>, <<"none">>),

     diprose(<<"pre_approve">>, <<"you">>,      <<"cell_pre_approve_you">>,      <<"document">>),
     diprose(<<"pre_approve">>, <<"lender">>,   <<"cell_pre_approve_lender">>,   <<"milestone">>),
     diprose(<<"pre_approve">>, <<"services">>, <<"cell_pre_approve_services">>, <<"document">>),

     diprose(<<"contract">>, <<"you">>,             <<"cell_contract_you">>,              <<"milestone">>),
     diprose(<<"contract">>, <<"government">>,      <<"cell_contract_government">>,       <<"document">>),
     diprose(<<"contract">>, <<"lender">>,          <<"cell_contract_lender">>,           <<"document">>),
     diprose(<<"contract">>, <<"property_manager">>,<<"cell_contract_property_manager">>, <<"document">>),
     diprose(<<"contract">>, <<"tenant">>,          <<"cell_contract_tenant">>,           <<"none">>),
     diprose(<<"contract">>, <<"services">>,        <<"cell_contract_services">>,         <<"milestone">>),

     diprose(<<"settle">>, <<"you">>,              <<"cell_settle_you">>,              <<"milestone">>),
     diprose(<<"settle">>, <<"government">>,       <<"cell_settle_government">>,       <<"milestone">>),
     diprose(<<"settle">>, <<"lender">>,           <<"cell_settle_lender">>,           <<"milestone">>),
     diprose(<<"settle">>, <<"property_manager">>, <<"cell_settle_property_manager">>, <<"milestone">>),
     diprose(<<"settle">>, <<"services">>,         <<"cell_settle_services">>,         <<"milestone">>),

     diprose(<<"own">>, <<"you">>,              <<"cell_own_you">>,              <<"milestone">>),
     diprose(<<"own">>, <<"government">>,       <<"cell_own_government">>,       <<"none">>),
     diprose(<<"own">>, <<"lender">>,           <<"cell_own_lender">>,           <<"none">>),
     diprose(<<"own">>, <<"property_manager">>, <<"cell_own_property_manager">>, <<"none">>),
     diprose(<<"own">>, <<"tenant">>,           <<"cell_own_tenant">>,           <<"none">>),
     diprose(<<"own">>, <<"services">>,         <<"cell_own_services">>,         <<"none">>)].

%% The Dispose-phase legal/prose spine, same role as Mode C's investor_dispose_prose_cells/0.
%% No `tenant` row (same rationale as Mode C — a tenancy ends before sale or transfers with
%% the property, not a distinct dispose-phase narrative beat).
investor_foreign_dispose_prose_cells() ->
    [diprose(<<"dispose">>, <<"you">>,              <<"cell_dispose_you">>,              <<"milestone">>),
     diprose(<<"dispose">>, <<"government">>,       <<"cell_dispose_government">>,       <<"none">>),
     diprose(<<"dispose">>, <<"lender">>,           <<"cell_dispose_lender">>,           <<"milestone">>),
     diprose(<<"dispose">>, <<"property_manager">>, <<"cell_dispose_property_manager">>, <<"document">>),
     diprose(<<"dispose">>, <<"services">>,         <<"cell_dispose_services">>,         <<"milestone">>)].

%% Mode-D's own prose builder (distinct from Mode C's iprose/4, which hardcodes
%% ?INVESTOR_COPY) — points at kb.journey.investor-foreign-path instead.
diprose(Phase, Actor, CopyId, Marker) ->
    cell(Phase, Actor, investor_foreign_copy(CopyId), Marker, null, null, <<"purchase_journey">>).

investor_foreign_copy(Id) -> fh_engine_kb:copy(?INVESTOR_FOREIGN_COPY, Id).
