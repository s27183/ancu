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
%% Mode C landed 2026-07-10 (kb.journey.investor-phase-actions / kb.risks.investor-by-phase);
%% Mode D landed 2026-07-10 (kb.journey.investor-foreign-phase-actions / kb.risks.investor-
%% foreign-by-phase); Mode B landed 2026-07-11 (kb.journey.fhb-foreign-phase-actions /
%% kb.risks.fhb-foreign-by-phase — task 12).
%%
%% MULTI-SOURCE HARVEST (2026-07-10, matches fh_engine_journey's harvest_cash_events/1,
%% [[unify-views-as-projections-of-one-primitive]]): ValidRefs is built from every upstream
%% outcome's `cash_events` field, not one hardcoded key — the same root fix, for the same
%% reason (a mode with more than one cash_events-bearing component, e.g. Mode C's
%% cash_position + yield_modelling + tax_structure, needs its budget_refs validated against
%% ALL of them, not just one).

-export([fill/2, ground/3]).
%% exported for the conformance harness:
-export([phase_order/0, build_phase/4, build_phase/6]).

-define(ACTIONS,          <<"kb.journey.phase-actions">>).   %% Mode A actions + bilingual copy
-define(RISKS,            <<"kb.risks.fhb-by-phase">>).      %% Mode A risks + bilingual copy
-define(INVESTOR_ACTIONS, <<"kb.journey.investor-phase-actions">>).  %% Mode C actions + copy
-define(INVESTOR_RISKS,   <<"kb.risks.investor-by-phase">>).         %% Mode C risks + copy
-define(INVESTOR_FOREIGN_ACTIONS, <<"kb.journey.investor-foreign-phase-actions">>).  %% Mode D actions + copy
-define(INVESTOR_FOREIGN_RISKS,   <<"kb.risks.investor-foreign-by-phase">>).         %% Mode D risks + copy
-define(FHB_FOREIGN_ACTIONS, <<"kb.journey.fhb-foreign-phase-actions">>).  %% Mode B actions + copy
-define(FHB_FOREIGN_RISKS,   <<"kb.risks.fhb-foreign-by-phase">>).         %% Mode B risks + copy

%% The canonical lifecycle phase order (fh_engine_journey:phases/0; cash_event.phase),
%% incl. the terminal `dispose` (lifecycle-simulation-model §8.1). The dispose phase carries
%% its own authored actions + risks (kb.journey.phase-actions / kb.risks.fhb-by-phase); a
%% phase with no authored content emits empty lists (honest-partial, build_phase/4).
-define(PHASE_ORDER,
        [<<"prepare">>, <<"pre_approve">>, <<"contract">>, <<"settle">>, <<"own">>,
         <<"dispose">>]).

%% --- entry -------------------------------------------------------------------

-spec fill(map(), map()) -> {map(), binary(), [map()]}.
fill(Args, Upstream) ->
    {ActionsDoc, RisksDoc} = docs(maps:get(blueprint_slug, Args, <<"fhb-domestic-au">>)),
    State = plan_state(Args),
    %% The only upstream read: the set of cash_event ids, for budget_ref validation —
    %% harvested from every upstream outcome that exposes the field.
    %% An event's `group` counts too: behavior 83 split other_buying_costs into one line per
    %% fee, each grouped under that id, so a ref to the group links all of its lines.
    ValidRefs = sets:from_list(lists:append([[maps:get(<<"id">>, E) | group(E)]
                                             || E <- harvest_cash_events(Upstream)])
                               ++ pending_ids(Upstream)
                               ++ held_lines(Args, Upstream)),
    %% The authored structure (layout) + bilingual prose (copy) from the two KB docs.
    {ok, ActionsCj} = fh_engine_kb:kb_rules(ActionsDoc),
    {ok, RisksCj}   = fh_engine_kb:kb_rules(RisksDoc),
    ActionsByPhase  = index(ActionsCj, <<"actions">>),
    RisksByPhase    = index(RisksCj, <<"risks">>),
    %% One entry per lifecycle phase, merging its actions + risks by phase id.
    Phases = [build_phase(P,
                          maps:get(P, ActionsByPhase, []),
                          maps:get(P, RisksByPhase, []),
                          ValidRefs, ActionsDoc, RisksDoc, State)
              || P <- ?PHASE_ORDER],
    Outcome = #{
        <<"phases">> => Phases,
        <<"key_assumptions">> =>
            [copy(ActionsDoc, <<"assumption_indicative">>),
             copy(ActionsDoc, <<"assumption_informational">>)]
    },
    KbVersions = fh_engine_kb:kb_anchors([ActionsDoc, RisksDoc]),
    {Outcome, <<"checklist">>, KbVersions}.

%% Whole lifecycle -> the checklist links both ways -> phase_playbook -> what a step may link
%% Goal (behavior 95): owning and selling steps link their lines too, not only buying's.
%% Invariant: a budget_ref is kept only when it names a line this plan's statement shows —
%%   an event of any phase (cash_events, and disposition's dispose_cash_events), a line
%%   waiting on an input (an upstream `fee_pending`: rent before a property), or, while no
%%   hold is chosen, a selling fee line that applies to this plan's blueprint and state —
%%   the Bán sheet carries it as soon as a hold is (the statement previews one at once,
%%   behavior 93). Anything else is dropped to null, as before.
%% every upstream outcome that carries a `cash_events` or `dispose_cash_events` field.
harvest_cash_events(Upstream) ->
    [E || V <- maps:values(Upstream), is_map(V),
          K <- [<<"cash_events">>, <<"dispose_cash_events">>], E <- list(V, K), is_map(E)].

pending_ids(Upstream) ->
    [maps:get(<<"id">>, P) || V <- maps:values(Upstream), is_map(V),
                              P <- list(V, <<"fee_pending">>), is_map(P)].

list(V, K) ->
    case maps:get(K, V, []) of
        L when is_list(L) -> L;
        _ -> []
    end.

held_lines(Args, Upstream) ->
    case maps:get(<<"disposition">>, Upstream, undefined) of
        #{<<"horizon_years">> := null} ->
            Ctx = #{blueprint => maps:get(blueprint_slug, Args, <<"fhb-domestic-au">>),
                    state => case fh_engine_store:projection_state(maps:get(onboarding, Args, #{})) of
                                 S when is_binary(S) -> S;
                                 _ -> undefined
                             end},
            [<<"selling_costs">> | fh_engine_fees:line_ids([<<"dispose">>], Ctx)];
        _ -> []
    end.

docs(<<"investor-domestic-au">>) -> {?INVESTOR_ACTIONS, ?INVESTOR_RISKS};
docs(<<"investor-foreign-au">>)  -> {?INVESTOR_FOREIGN_ACTIONS, ?INVESTOR_FOREIGN_RISKS};
docs(<<"fhb-foreign-au">>)       -> {?FHB_FOREIGN_ACTIONS, ?FHB_FOREIGN_RISKS};
docs(_)                          -> {?ACTIONS, ?RISKS}.

plan_state(Args) ->
    case fh_engine_store:projection_state(maps:get(onboarding, Args, #{})) of
        S when is_binary(S) -> S;
        _ -> undefined
    end.

-spec phase_order() -> [binary()].
phase_order() -> ?PHASE_ORDER.

%% --- per-phase assembly ------------------------------------------------------

%% Merge one phase's actions + risks into a single phase entry. Actions are sorted by
%% `order` (temporal sequence within the phase); a phase with no authored risk emits an
%% empty list (honest-partial — never a fabricated risk). ActionsDoc/RisksDoc select which
%% mode's KB doc the bilingual copy resolves against (default Mode A's ?ACTIONS/?RISKS via
%% the two extra clauses below, for callers that predate the mode-dispatch).
-spec build_phase(binary(), [map()], [map()], sets:set()) -> map().
build_phase(Phase, ActionDefs, RiskDefs, ValidRefs) ->
    build_phase(Phase, ActionDefs, RiskDefs, ValidRefs, ?ACTIONS, ?RISKS).

-spec build_phase(binary(), [map()], [map()], sets:set(), binary(), binary()) -> map().
build_phase(Phase, ActionDefs, RiskDefs, ValidRefs, ActionsDoc, RisksDoc) ->
    build_phase(Phase, ActionDefs, RiskDefs, ValidRefs, ActionsDoc, RisksDoc, undefined).

build_phase(Phase, ActionDefs, RiskDefs, ValidRefs, ActionsDoc, RisksDoc, State) ->
    Actions = lists:sort(
                fun(A, B) -> maps:get(<<"order">>, A) =< maps:get(<<"order">>, B) end,
                [maps:merge(action(Phase, D, ValidRefs, ActionsDoc), grounding(D, State))
                 || D <- ActionDefs]),
    Risks   = [risk(Phase, D, RisksDoc) || D <- RiskDefs],
    #{<<"phase">>   => Phase,
      <<"actions">> => Actions,
      <<"risks">>   => Risks}.

%% An ordered, actionable checklist item. label/detail are bilingual copy keyed by
%% convention (action_<phase>_<id>_{label,detail}); status is seeded not_started (the
%% user-set layer overlays the effective value at read). budget_ref is kept only if it
%% names a real cash_event in this plan; component_ref is passed through verbatim (it may
%% point at a per-property component reached as backing detail — not validated here).
action(Phase, Def, ValidRefs, ActionsDoc) ->
    Id = maps:get(<<"id">>, Def),
    #{<<"id">>            => Id,
      <<"order">>         => maps:get(<<"order">>, Def),
      <<"budget_ref">>    => keep_valid(maps:get(<<"budget_ref">>, Def, null), ValidRefs),
      <<"component_ref">> => maps:get(<<"component_ref">>, Def, null),
      <<"label">>         => copy(ActionsDoc, ckey(<<"action">>, Phase, Id, <<"label">>)),
      <<"detail">>        => copy(ActionsDoc, ckey(<<"action">>, Phase, Id, <<"detail">>)),
      <<"status">>        => <<"not_started">>}.

%% An often-seen risk + its mitigation (risk-flag-list shape). item/action are bilingual
%% copy keyed by convention (risk_<phase>_<id>_{item,action}); severity from the layout.
risk(Phase, Def, RisksDoc) ->
    Id = maps:get(<<"id">>, Def),
    #{<<"severity">> => maps:get(<<"severity">>, Def),
      <<"item">>     => copy(RisksDoc, ckey(<<"risk">>, Phase, Id, <<"item">>)),
      <<"action">>   => copy(RisksDoc, ckey(<<"risk">>, Phase, Id, <<"action">>))}.

%% Whole lifecycle -> honesty tiers -> phase_playbook -> where a step's rule comes from
%% Goal: behavior 114 (Son 2026-10-17) — every Hành trình step follows a cited government
%%   rule or says it is common practice, so "the journey rests on current rules" is true.
%% Invariant: `grounding` is `rule` with `source` {url, checked} — the first of the step's
%%   `rule` entries (kb.journey.* docs, GATE 16) whose doc cites a source for the plan's
%%   state, its url from that doc's `sources:` (fh_engine_line_detail:source/3, the same
%%   lookup a statement line uses) and `checked` its last_verified; `state_rule` with
%%   `rule_state` when the rule is a state's and no entry cites one for this state (no
%%   link is borrowed from another state); `practice` for a step no rule governs.
%% Capability: ground/3 recomputes it on a stored card at read, from today's KB.
grounding(#{<<"practice">> := true}, _State) ->
    #{<<"grounding">> => <<"practice">>, <<"source">> => null, <<"rule_state">> => null};
grounding(#{<<"rule">> := Rules}, State) when is_list(Rules), Rules =/= [] ->
    case cited(Rules, State) of
        {Url, Checked} ->
            #{<<"grounding">> => <<"rule">>,
              <<"source">> => #{<<"url">> => Url, <<"checked">> => Checked},
              <<"rule_state">> => null};
        none ->
            #{<<"grounding">> => <<"state_rule">>, <<"source">> => null,
              <<"rule_state">> => case State of undefined -> null; _ -> State end}
    end;
grounding(Def, _State) ->
    error({journey_step_ungrounded, maps:get(<<"id">>, Def, null)}).

cited([], _State) -> none;
cited([R | Rest], State) ->
    {ok, Kb} = fh_engine_kb:kb(maps:get(<<"kb">>, R)),
    case fh_engine_line_detail:source(maps:get(<<"source">>, R, null),
                                      maps:get(<<"sources">>, Kb, []), State) of
        Url when is_binary(Url) -> {Url, maps:get(<<"last_verified">>, Kb, null)};
        _ -> cited(Rest, State)
    end.

%% A stored card's phase_playbook with each step's grounding as today's KB gives it for
%% the plan's state (a card filled before behavior 114 has none; a re-verified doc moves
%% its `checked`). Anything not shaped as a playbook is returned as is.
-spec ground(binary(), binary() | undefined, term()) -> term().
ground(Slug, State, #{<<"components">> := #{<<"phase_playbook">> :=
                        #{<<"outcome">> := #{<<"phases">> := Phases} = O} = PP} = Comps} = Content)
  when is_list(Phases) ->
    {ActionsDoc, _} = docs(Slug),
    {ok, Cj} = fh_engine_kb:kb_rules(ActionsDoc),
    Defs = index(Cj, <<"actions">>),
    Grounded = [P#{<<"actions">> => [ground_action(A, maps:get(maps:get(<<"phase">>, P, null), Defs, []), State)
                                     || A <- maps:get(<<"actions">>, P, [])]}
                || P <- Phases, is_map(P)],
    Content#{<<"components">> := Comps#{<<"phase_playbook">> :=
        PP#{<<"outcome">> := O#{<<"phases">> := Grounded}}}};
ground(_Slug, _State, Content) -> Content.

ground_action(A, Defs, State) when is_map(A) ->
    Id = maps:get(<<"id">>, A, null),
    case [D || D <- Defs, maps:get(<<"id">>, D) =:= Id] of
        [D | _] -> maps:merge(A, grounding(D, State));
        []      -> A
    end;
ground_action(A, _Defs, _State) -> A.

%% --- helpers -----------------------------------------------------------------

%% Index a doc's layout.phases[] by phase id → the inner list under Key (actions|risks).
index(Cj, Key) ->
    Phases = maps:get(<<"phases">>, maps:get(<<"layout">>, Cj, #{}), []),
    maps:from_list([{maps:get(<<"phase">>, P), maps:get(Key, P, [])} || P <- Phases]).

group(E) ->
    case maps:get(<<"group">>, E, null) of
        G when is_binary(G) -> [G];
        _ -> []
    end.

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

copy(Doc, Id) -> fh_engine_kb:copy(Doc, Id).
