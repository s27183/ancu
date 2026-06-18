-module(fh_engine_journey).

%% The base-turn `purchase_journey` fill — the whole-of-journey lifecycle swimlane
%% (plan-card-lifecycle-restoration.md §7; the spine the prototype led with). It is a
%% RESOLVER fill (agentic-boundary.md): the journey structure + bilingual cell prose are
%% generic Mode-A KB content (kb.journey.fhg-path); the money flows on the timeline are
%% the buyer's ALREADY-COMPUTED upstream figures, PLACED — never recomputed.
%%
%% One-computer-per-figure (the load-bearing constraint, [[verify-regulated-figures-by-
%% postcondition]]): the regulated/derived figures (deposit, stamp duty, total cash to
%% settle, scheme benefit) are read from budget_envelope / scheme_stack and dropped onto
%% the relevant cells. This component computes NO figure of its own, so there is no second
%% computer to verify — the conformance burden stays entirely on cash_position/eligibility.
%% This is why it runs AFTER cash_position in the base DAG.
%%
%% The journey_swimlane outcome is mode-general (phases × actors × cells); Modes B/C/D
%% reuse the schema + the mode-agnostic swimlane-diagram renderer with their own
%% kb.journey.* doc + resolver (plan-card-lifecycle-restoration.md §3.3). Mode A only here.

-export([fill/2]).
%% exported for the conformance harness:
-export([phases/0, actors/0, cells/2]).

-define(COPY, <<"kb.journey.fhg-path">>).   %% bilingual labels + cell prose (no params)

%% --- entry -------------------------------------------------------------------

-spec fill(map(), map()) -> {map(), binary(), [map()]}.
fill(_Args, Upstream) ->
    Stack  = maps:get(<<"scheme_stack">>, Upstream, #{}),
    Budget = maps:get(<<"budget_envelope">>, Upstream, #{}),
    Outcome = #{
        <<"phases">> => phases(),
        <<"actors">> => actors(),
        <<"cells">>  => cells(Stack, Budget),
        <<"key_assumptions">> =>
            [copy(<<"assumption_indicative">>), copy(<<"assumption_figures">>)]
    },
    KbVersions = fh_engine_kb:kb_anchors([?COPY]),
    {Outcome, <<"swimlane-diagram">>, KbVersions}.

%% --- the swimlane structure (Mode-A FHB: Prepare → … → Own) ------------------

-spec phases() -> [map()].
phases() ->
    [phase(<<"prepare">>,     <<"phase_prepare">>),
     phase(<<"pre_approve">>, <<"phase_pre_approve">>),
     phase(<<"contract">>,    <<"phase_contract">>),
     phase(<<"settle">>,      <<"phase_settle">>),
     phase(<<"own">>,         <<"phase_own">>)].

-spec actors() -> [map()].
actors() ->
    [actor(<<"you">>,        <<"actor_you">>),
     actor(<<"government">>, <<"actor_government">>),
     actor(<<"lender">>,     <<"actor_lender">>),
     actor(<<"other">>,      <<"actor_other">>)].

%% One action per (phase, actor) that carries one. The money cells take their figure from
%% upstream; a money marker shows ONLY when its figure is present (honest-partial), else the
%% prose stands alone. document/milestone markers carry no figure.
-spec cells(map(), map()) -> [map()].
cells(Stack, Budget) ->
    Deposit = money_range(get_in(Budget, [<<"deposit">>, <<"minimum_required_amount">>])),
    Total   = money_range(maps:get(<<"total_cash_required">>, Budget, null)),
    Duty    = point(get_in(Budget, [<<"stamp_duty">>, <<"after_concession">>])),
    Benefit = money_range(maps:get(<<"total_benefit_value">>, Stack, null)),
    [
     money_cell(<<"prepare">>, <<"you">>, <<"cell_prepare_you">>, <<"money_out">>, Deposit),
     cell(<<"prepare">>, <<"government">>, <<"cell_prepare_government">>, <<"none">>, null),
     cell(<<"prepare">>, <<"lender">>, <<"cell_prepare_lender">>, <<"none">>, null),

     cell(<<"pre_approve">>, <<"you">>, <<"cell_pre_approve_you">>, <<"document">>, null),
     money_cell(<<"pre_approve">>, <<"government">>, <<"cell_pre_approve_government">>,
                <<"money_in">>, Benefit),
     cell(<<"pre_approve">>, <<"lender">>, <<"cell_pre_approve_lender">>, <<"milestone">>, null),
     cell(<<"pre_approve">>, <<"other">>, <<"cell_pre_approve_other">>, <<"none">>, null),

     cell(<<"contract">>, <<"you">>, <<"cell_contract_you">>, <<"milestone">>, null),
     cell(<<"contract">>, <<"government">>, <<"cell_contract_government">>, <<"document">>, null),
     cell(<<"contract">>, <<"lender">>, <<"cell_contract_lender">>, <<"document">>, null),
     cell(<<"contract">>, <<"other">>, <<"cell_contract_other">>, <<"document">>, null),

     money_cell(<<"settle">>, <<"you">>, <<"cell_settle_you">>, <<"money_out">>, Total),
     money_cell(<<"settle">>, <<"government">>, <<"cell_settle_government">>,
                <<"money_out">>, Duty),
     cell(<<"settle">>, <<"lender">>, <<"cell_settle_lender">>, <<"milestone">>, null),
     cell(<<"settle">>, <<"other">>, <<"cell_settle_other">>, <<"milestone">>, null),

     cell(<<"own">>, <<"you">>, <<"cell_own_you">>, <<"milestone">>, null),
     cell(<<"own">>, <<"government">>, <<"cell_own_government">>, <<"none">>, null),
     cell(<<"own">>, <<"lender">>, <<"cell_own_lender">>, <<"none">>, null)
    ].

%% --- builders ----------------------------------------------------------------

phase(Id, CopyId) -> #{<<"id">> => Id, <<"label">> => copy(CopyId)}.
actor(Id, CopyId) -> #{<<"id">> => Id, <<"label">> => copy(CopyId)}.

cell(Phase, Actor, CopyId, Marker, Amount) ->
    #{<<"phase">>       => Phase,
      <<"actor">>       => Actor,
      <<"item">>        => copy(CopyId),
      <<"flow_marker">> => Marker,
      <<"amount">>      => Amount}.

%% A money cell: the marker is shown only when its figure is present, else `none` (the
%% prose still renders) — honest-partial, never a money marker with no number behind it.
money_cell(Phase, Actor, CopyId, _Dir, null) ->
    cell(Phase, Actor, CopyId, <<"none">>, null);
money_cell(Phase, Actor, CopyId, Dir, Amount) ->
    cell(Phase, Actor, CopyId, Dir, Amount).

%% --- figure normalisers (place, never compute) -------------------------------

%% A money_range upstream figure stays a [lo, hi] of numbers; anything else (null,
%% malformed) becomes null. The journey never fabricates a figure.
money_range([Lo, Hi]) when is_number(Lo), is_number(Hi) -> [Lo, Hi];
money_range(_) -> null.

%% A point (scalar) upstream figure (stamp duty) is placed as a collapsed range [v, v]
%% so the renderer reads one money type; null stays null.
point(V) when is_number(V) -> [V, V];
point(_) -> null.

get_in(Map, []) -> Map;
get_in(Map, [K | Ks]) when is_map(Map) -> get_in(maps:get(K, Map, null), Ks);
get_in(_, _) -> null.

%% A bilingual label/line from the journey KB doc. No params — the figures are structured
%% `amount` fields, not interpolated — so the template is returned as-is.
-spec copy(binary()) -> fh_engine_i18n:localized().
copy(Id) ->
    fh_engine_kb:copy(?COPY, Id).
