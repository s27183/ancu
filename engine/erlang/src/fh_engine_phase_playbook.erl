-module(fh_engine_phase_playbook).

%% The base-turn `phase_playbook` fill (component 12) — the ACTIONABLE layer of the
%% legal/temporal spine (lifecycle-simulation-model §7; fhb-domestic-au.md §12). Behind
%% each Flow-view phase sheet it renders, per lifecycle phase, an ordered "what you do, in
%% what order" checklist (`checklist`) plus the often-seen risks + mitigations for that
%% phase (`risk-flag-list`). Where `purchase_journey` shows *what happens* on the swimlane,
%% this turns it into *what you do, and what to watch for*.
%%
%% RESOLVER fill, NO agent leaf (agentic-boundary.md; blueprint §12 "fill path: resolver").
%% Actions, ordering, risks and mitigations are bilingual KB content keyed by phase
%% (kb.journey.phase-actions, kb.risks.fhb-by-phase) — the model never authors the risk
%% list; reliability is structural, not a judge ([[no-judge-ground-the-producer]]).
%%
%% AUTHORS content, PLACES no figure. Unlike `purchase_journey`/`preparation` (figure-
%% projections), phase_playbook computes no amount: an action carries a `budget_ref` — the
%% *id* of a cash_event the calculator already computed — and the Budget view joins the
%% amount at render (one-computer-per-figure, [[place-upstream-figures-dont-recompute]],
%% extended to this consumer). The only upstream read is the cash_event id SET, used to
%% validate budget_ref. HONEST-PARTIAL: a budget_ref that names no cash_event present in
%% THIS buyer's budget_envelope is dropped to null — never a fabricated link.
%%
%% `status` is USER-ATTESTED: the resolver seeds every action `not_started` into this
%% computed snapshot; the user toggles it (PATCH /checklist-status), and the effective
%% value is stored in the card's USER-SET LAYER and overlaid at read so a recompute never
%% clobbers it (lifecycle-simulation-model §7.4a — the SAME mechanism
%% preparation.document_checklist[].status uses).
%%
%% Mode-general (phase-keyed actions + risks); Modes B/C/D reuse the schema + the same
%% checklist + risk-flag-list renderers with their own kb.journey.*/kb.risks.* content.

-export([fill/2]).
%% exported for the conformance harness:
-export([phase_order/0, build_phase/4]).

-define(ACTIONS, <<"kb.journey.phase-actions">>).  %% ordered actions per phase + bilingual copy
-define(RISKS,   <<"kb.risks.fhb-by-phase">>).     %% per-phase risks + mitigations + bilingual copy

%% The canonical lifecycle phase order (fh_engine_journey:phases/0; cash_event.phase).
-define(PHASE_ORDER,
        [<<"prepare">>, <<"pre_approve">>, <<"contract">>, <<"settle">>, <<"own">>]).

%% --- entry -------------------------------------------------------------------

-spec fill(map(), map()) -> {map(), binary(), [map()]}.
fill(_Args, Upstream) ->
    %% The only upstream read: the set of cash_event ids, for budget_ref validation.
    Budget    = maps:get(<<"budget_envelope">>, Upstream, #{}),
    Events    = maps:get(<<"cash_events">>, Budget, []),
    ValidRefs = sets:from_list([maps:get(<<"id">>, E) || E <- Events]),
    %% The authored structure (layout) + bilingual prose (copy) from the two KB docs.
    {ok, ActionsCj} = fh_engine_kb:kb_rules(?ACTIONS),
    {ok, RisksCj}   = fh_engine_kb:kb_rules(?RISKS),
    ActionsByPhase  = index(ActionsCj, <<"actions">>),
    RisksByPhase    = index(RisksCj, <<"risks">>),
    %% One entry per lifecycle phase, merging its actions + risks by phase id.
    Phases = [build_phase(P,
                          maps:get(P, ActionsByPhase, []),
                          maps:get(P, RisksByPhase, []),
                          ValidRefs)
              || P <- ?PHASE_ORDER],
    Outcome = #{
        <<"phases">> => Phases,
        <<"key_assumptions">> =>
            [actions_copy(<<"assumption_indicative">>),
             actions_copy(<<"assumption_informational">>)]
    },
    KbVersions = fh_engine_kb:kb_anchors([?ACTIONS, ?RISKS]),
    {Outcome, <<"checklist">>, KbVersions}.

-spec phase_order() -> [binary()].
phase_order() -> ?PHASE_ORDER.

%% --- per-phase assembly ------------------------------------------------------

%% Merge one phase's actions + risks into a single phase entry. Actions are sorted by
%% `order` (temporal sequence within the phase); a phase with no authored risk emits an
%% empty list (honest-partial — never a fabricated risk).
-spec build_phase(binary(), [map()], [map()], sets:set()) -> map().
build_phase(Phase, ActionDefs, RiskDefs, ValidRefs) ->
    Actions = lists:sort(
                fun(A, B) -> maps:get(<<"order">>, A) =< maps:get(<<"order">>, B) end,
                [action(Phase, D, ValidRefs) || D <- ActionDefs]),
    Risks   = [risk(Phase, D) || D <- RiskDefs],
    #{<<"phase">>   => Phase,
      <<"actions">> => Actions,
      <<"risks">>   => Risks}.

%% An ordered, actionable checklist item. label/detail are bilingual copy keyed by
%% convention (action_<phase>_<id>_{label,detail}); status is seeded not_started (the
%% user-set layer overlays the effective value at read). budget_ref is kept only if it
%% names a real cash_event in this plan; component_ref is passed through verbatim (it may
%% point at a per-property component reached as backing detail — not validated here).
action(Phase, Def, ValidRefs) ->
    Id = maps:get(<<"id">>, Def),
    #{<<"id">>            => Id,
      <<"order">>         => maps:get(<<"order">>, Def),
      <<"budget_ref">>    => keep_valid(maps:get(<<"budget_ref">>, Def, null), ValidRefs),
      <<"component_ref">> => maps:get(<<"component_ref">>, Def, null),
      <<"label">>         => actions_copy(ckey(<<"action">>, Phase, Id, <<"label">>)),
      <<"detail">>        => actions_copy(ckey(<<"action">>, Phase, Id, <<"detail">>)),
      <<"status">>        => <<"not_started">>}.

%% An often-seen risk + its mitigation (risk-flag-list shape). item/action are bilingual
%% copy keyed by convention (risk_<phase>_<id>_{item,action}); severity from the layout.
risk(Phase, Def) ->
    Id = maps:get(<<"id">>, Def),
    #{<<"severity">> => maps:get(<<"severity">>, Def),
      <<"item">>     => risks_copy(ckey(<<"risk">>, Phase, Id, <<"item">>)),
      <<"action">>   => risks_copy(ckey(<<"risk">>, Phase, Id, <<"action">>))}.

%% --- helpers -----------------------------------------------------------------

%% Index a doc's layout.phases[] by phase id → the inner list under Key (actions|risks).
index(Cj, Key) ->
    Phases = maps:get(<<"phases">>, maps:get(<<"layout">>, Cj, #{}), []),
    maps:from_list([{maps:get(<<"phase">>, P), maps:get(Key, P, [])} || P <- Phases]).

%% honest-partial: keep a budget_ref only when it names a cash_event present in THIS
%% buyer's budget_envelope; otherwise drop it to null (never a fabricated link).
keep_valid(null, _ValidRefs) -> null;
keep_valid(Ref, ValidRefs) ->
    case sets:is_element(Ref, ValidRefs) of
        true  -> Ref;
        false -> null
    end.

%% Build a copy-template id by the doc's naming convention: <prefix>_<phase>_<id>_<suffix>.
ckey(Prefix, Phase, Id, Suffix) ->
    <<Prefix/binary, "_", Phase/binary, "_", Id/binary, "_", Suffix/binary>>.

actions_copy(Id) -> fh_engine_kb:copy(?ACTIONS, Id).
risks_copy(Id)   -> fh_engine_kb:copy(?RISKS, Id).
