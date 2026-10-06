-module(fh_engine_turn).
-behaviour(gen_statem).

%% One plan-card turn = one isolated gen_statem (principle 1; isolation-model.md).
%%
%% 2b-2b: the orchestrator is DETERMINISTIC Erlang (agentic-flow §1) — this
%% gen_statem WALKS THE BASE-TURN DAG and dispatches each component by its fill path
%% (agentic-boundary.md, materialized as the artifact's `agent_leaves`):
%%   - RESOLVER component (agent_leaves == []) → filled in-process by fh_engine_fill
%%     (no sidecar, no LLM, no `usage`; fill_path: resolver). Driven synchronously
%%     via an internal `step` event.
%%   - TWO-PATH component (agent_leaves =/= [] AND a resolver exists, e.g.
%%     mortgage_finance) → fh_engine_fill computes the figures + structure FIRST, then
%%     a disposable sidecar fills only the agent leaves (read-only `resolver_outcome`
%%     grounding); merge_agent/3 folds them in (fill_path: two_path; §98: the agent
%%     never authors a figure). See mortgage-finance-two-path.md.
%%   - AGENT component (agent_leaves =/= [], no resolver — the later per-property
%%     valuation/negotiation components) → the sidecar fills the whole outcome
%%     (fill_path: agent).
%%   Two-path + agent fills run a disposable Python sidecar (principle 3, {packet,4}
%%   JSON-RPC `fill_component`) that meters `usage`; the walk parks until it replies.
%%
%% Lifecycle: emit `turn_started` → step through the DAG (resolver fills inline;
%% agent fills via a per-fill disposable port) → each filled component runs the
%% compliance pipeline (§6), is persisted to plan_card_events (SOT) + snapshotted
%% into plan_cards.content_jsonb, and published to the per-card pg group for live
%% SSE → on the last component, emit `turn_completed` and stop.
%%
%% No wall-clock timeout (erlang-design-checklist §15): the sidecar port's
%% `exit_status` is the structural signal for a dead sidecar; a genuinely-hung LLM
%% call is bounded app-side in the sidecar (asyncio.wait_for) where the work happens.
%% Erlang owns lifecycle/persistence/streaming; the sidecar reasons.

-export([start_link/1]).
-export([callback_mode/0, init/1, terminate/3]).
-export([running/3, qa/3]).
-export([base_components/1]).
%% exported for the Phase-B wiring smoke (no-PG integration of the per-property turn):
-export([property_components/1, two_path_stored_leaf/2]).

%% Mode-A base turn: the resolver/agent components in DAG (topological) order. The
%% per-property components (property_assessment, buying_strategy, due_diligence,
%% settlement_prep) are NOT in the base turn. (Deriving this from a `scope` field in
%% the artifact is a follow-on; the Mode-A base sequence is fixed.)
%% NOTE the order: ownership_planning runs BEFORE purchase_journey, because the W5
%% two-spines journey PLACES ownership_planning.ongoing_obligations on the Own column
%% (forward edge 9→10, still acyclic — blueprint dependency graph). preparation (11)
%% reads only eligibility + cash_position and likewise places. phase_playbook (12) reads
%% cash_position (cash_event ids it links by budget_ref) + purchase_journey (the phase
%% set), so it sits LAST (forward edges, still acyclic).
%% disposition runs AFTER its figure-owners (cash_position, ownership_planning, mortgage_finance
%% — it places their figures) and BEFORE purchase_journey (which places disposition's
%% dispose_cash_events on the swimlane). [[place-upstream-figures-dont-recompute]] — the
%% placement need sets the DAG position.
-define(BASE_COMPONENTS,
        [<<"buyer_profile">>, <<"eligibility">>, <<"mortgage_finance">>,
         <<"cash_position">>, <<"ownership_planning">>, <<"disposition">>,
         <<"purchase_journey">>, <<"preparation">>, <<"phase_playbook">>]).

%% Mode-C (investor-domestic-au) base turn — the property-AGNOSTIC investor spine in DAG
%% order. EXCLUDES the per-property components (property_assessment, buying_strategy,
%% due_diligence, settlement_prep — all read property_fit_investor, absent at base). The
%% order is DISCRIMINATOR-load-bearing, not merely topological: the three shared-name
%% modules sniff the accumulated upstream (keyed by outcome_type) to pick their investor
%% branch, so each must run AFTER the component producing its discriminating outcome:
%%   - mortgage_finance keys on `strategy_thesis` present → after investment_strategy;
%%   - cash_position keys on `tax_optimised_structure` present → after tax_structure;
%%   - disposition keys on `tax_optimised_structure` present (cgt_investor path) → after
%%     tax_structure (+ budget_envelope_investor → after cash_position).
%% purchase_journey/phase_playbook landed 2026-07-10 (the B/C/D lifecycle-spine restructure,
%% task 4) — no preparation equivalent (Mode C has no FHB readiness layer). They run LAST,
%% after ownership_planning_investor, mirroring the FHB base DAG's "figure-owners, then the
%% spine that places them" position: purchase_journey harvests `cash_events` off cash_position/
%% yield_modelling/tax_structure + disposition.dispose_cash_events (fh_engine_journey's generic
%% multi-source harvest — no read of ownership_planning_investor.portfolio_position, which
%% carries no cash_events); phase_playbook then validates its budget_refs against the same
%% harvest and reads purchase_journey's phase set.
-define(BASE_COMPONENTS_INVESTOR,
        [<<"investor_profile">>, <<"investment_strategy">>, <<"mortgage_finance">>,
         <<"yield_modelling">>, <<"tax_structure">>, <<"cash_position">>,
         <<"disposition">>, <<"ownership_planning_investor">>,
         <<"purchase_journey">>, <<"phase_playbook">>]).

%% Mode-B (fhb-foreign-au) base turn — 7 of the blueprint's 11 components; EXCLUDES the
%% same 4 per-property components Mode A/C already exclude (property_assessment,
%% buying_strategy, due_diligence, settlement_prep — per the blueprint's own §-table
%% Scope column, mode-b-wedge.md P5). Order is topological AND satisfies the actual
%% resolver code reads (not just the blueprint's declared Inputs prose, which diverges
%% from code in two places — grounded directly against each fh_engine_*.erl module):
%%   - firb_workflow reads profile (buyer_profile) — no live property yet, so its
%%     property_fit read is honestly undefined at base;
%%   - mortgage_finance reads only profile (its blueprint-declared firb_status read is
%%     unused by fill_fhb_foreign/2 — doc/code divergence, harmless to order);
%%   - cash_position reads BOTH firb_status (firb_workflow) AND mortgage_plan
%%     (mortgage_finance) — a real code dependency on both preceding components;
%%   - cross_border_funding reads only family_funding_plan (family_context) — its
%%     blueprint-declared budget_envelope read is likewise unused by fill/2;
%%   - ownership_planning (foreign branch) reads firb_status (firb_workflow), not
%%     property_fit/profile as the blueprint prose implies.
%% Unlike Mode C's three shared-name branches (which sniff an upstream outcome_type),
%% Mode B's shared-name branches (mortgage_finance/cash_position/ownership_planning) key
%% on Args.firb_required_any — a turn-level flag, not upstream presence — so order here
%% is genuine DATA-dependency, not discriminator-selection.
%%
%% disposition added 2026-07-11 (task 11, plan-card-lifecycle-restoration.md §11.4 — Mode
%% B was the only mode with no dispose-phase figure owner). fh_engine_disposition:fill/2
%% dispatches Mode B onto the SAME fill_owner_occupier/2 path Mode A uses (keyed on the
%% absence of tax_optimised_structure upstream — Mode B never runs a tax_structure
%% component), so no new resolver code was needed, only the wiring + the buyer_profile
%% intended_occupancy_use field it reads (see fh_engine_fill.erl's buyer_profile_foreign/1).
%% Runs LAST, after cash_position + ownership_planning (it places their total_cash_required
%% + hold-cost figures into the full-horizon roll-up — same position as every other mode's
%% disposition). full_horizon_net_position stays honestly null for Mode B: ownership_
%% planning's foreign variant (fill_foreign/2) never computes a recurring_costs_estimate.
%% statutory_band the way Mode A's does — it is built around FIRB compliance monitoring
%% (vacancy fee, alerts), not a cost estimate, and a correct one would need the foreign-
%% owner land-tax surcharge, which kb.tax.land-tax-by-state deliberately never resolver-
%% computes for ANY mode ("a per-property estimate would mislead without the portfolio-
%% wide aggregate land value"). A disclosed, permanent gap, not a bug — the dispose-phase
%% figures (sale_proceeds/selling_costs/loan_payout/cgt/net_proceeds) this component was
%% added FOR all compute correctly regardless.
%% purchase_journey/phase_playbook appended 2026-07-11 (task 12, plan-card-lifecycle-
%% restoration.md §11.5/§11.8) — reuse Mode A's OWN four-actor swimlane shape (§3.3: "B =
%% A's shape + a FIRB gate + a transfer milestone + surcharge", not Mode C/D's six-actor
%% investor set), each with zero new resolver code beyond its own Mode-B prose/dispatch
%% branch (fh_engine_journey:fill_fhb_foreign/1, fh_engine_phase_playbook's fhb-foreign-au
%% clause). purchase_journey reads ongoing_obligations + disposition (both already earlier
%% in this list) plus cash_position's cash_events (task 12 also added a real
%% cash_events_foreign/5 to fh_engine_cash:fill_fhb_foreign/2 — Mode B's ceiling-estimate
%% figures are honestly computable at base, unlike Mode D's fill_investor_foreign/2, so
%% this is live money, not a permanently-null stub); phase_playbook reads only the
%% harvested cash_event id set. Both run LAST, after disposition — the same "figure-owners,
%% then the spine that places them" DAG shape every other mode uses.
-define(BASE_COMPONENTS_FOREIGN,
        [<<"buyer_profile">>, <<"family_context">>, <<"firb_workflow">>,
         <<"mortgage_finance">>, <<"cash_position">>, <<"cross_border_funding">>,
         <<"ownership_planning">>, <<"disposition">>,
         <<"purchase_journey">>, <<"phase_playbook">>]).

%% Mode-D (investor-foreign-au) base turn — the 10 `base`/`both`-scope components of the
%% blueprint's 14 (mode-d-wedge.md P5), EXCLUDING the 4 per-property-only ones
%% (property_assessment, buying_strategy, due_diligence, settlement_prep — same exclusion
%% discipline as A/B/C). Order is real-code-dependency order, grounded against each
%% fh_engine_*.erl module's actual Upstream reads (investor-foreign-au.md's own component
%% Inputs lines, not the blueprint's ASCII sketch — which itself omits mortgage_finance,
%% see the blueprint's own note under the diagram):
%%   - firb_workflow / investment_strategy both read only profile (property_fit is
%%     honestly absent at base, same treatment as Mode B's firb_workflow);
%%   - mortgage_finance (fill_investor_foreign) reads firb_status (firb_workflow) AND
%%     strategy_thesis (investment_strategy) — must follow both;
%%   - yield_modelling reads strategy_thesis only; ordered after mortgage_finance to match
%%     Mode C's existing convention (no data dependency between the two, but consistent
%%     placement avoids an arbitrary divergence);
%%   - tax_structure_non_resident reads cash_flow_projection (yield_modelling) — must
%%     follow it;
%%   - cash_position (fill_investor_foreign) reads firb_status AND tax_optimised_structure
%%     — must follow firb_workflow AND tax_structure_non_resident;
%%   - cross_border_funding reads budget_envelope_investor (cash_position) — must follow it;
%%   - ownership_planning_foreign_investor reads tax_optimised_structure + cash_flow_
%%     projection — must follow tax_structure_non_resident + yield_modelling; does NOT read
%%     disposition's figures (unlike Mode C's ownership_planning_investor/equity_release),
%%     so it need not precede disposition;
%%   - disposition reads strategy_thesis, cash_flow_projection, tax_optimised_structure,
%%     budget_envelope_investor — runs LAST among the base figure-owners (same position as
%%     every other mode's disposition).
%% purchase_journey/phase_playbook landed 2026-07-10 (task 8, the B/C/D lifecycle-spine
%% restructure). They run LAST, after disposition — mirroring every other mode's "figure-
%% owners, then the spine that places them" position, NOT Mode C's order verbatim: Mode D's
%% own ownership_planning_foreign_investor already runs BEFORE disposition here (unlike
%% Mode C, where ownership_planning_investor reads disposition's projected figures for its
%% equity_release opportunity — Mode D's ownership component has no such read, per the note
%% above), so simply appending the two new components at the end is correct without
%% reordering anything else. purchase_journey harvests cash_events off cash_position/
%% yield_modelling/tax_structure_non_resident + disposition.dispose_cash_events (the same
%% generic multi-source harvest Mode C uses, fh_engine_journey:harvest_cash_events/1 — no
%% Mode-D-specific journey code needed for this wiring); phase_playbook then validates its
%% budget_refs against the same harvest and reads purchase_journey's phase set.
-define(BASE_COMPONENTS_FOREIGN_INVESTOR,
        [<<"investor_profile_foreign">>, <<"firb_workflow">>, <<"investment_strategy">>,
         <<"mortgage_finance">>, <<"yield_modelling">>, <<"tax_structure_non_resident">>,
         <<"cash_position">>, <<"cross_border_funding">>,
         <<"ownership_planning_foreign_investor">>, <<"disposition">>,
         <<"purchase_journey">>, <<"phase_playbook">>]).

%% Mode-E (nexthome-domestic-au) base turn — 9 of the blueprint's 13 components (mode-e-
%% wedge.md P5), EXCLUDING the same 4 per-property components every mode already excludes
%% (property_assessment, buying_strategy, due_diligence, settlement_prep). A near-verbatim
%% mirror of the Mode-A nine (?BASE_COMPONENTS) with `eligibility` swapped for
%% `existing_home_disposal` in the SAME slot — grounded against the real resolver reads,
%% not just position-copied:
%%   - existing_home_disposal (fh_engine_existing_home_disposal:fill/2) reads only profile
%%     (buyer_profile) — same single upstream read as eligibility had in that slot;
%%   - cash_position's fill_fhb_nexthome/2 (fh_engine_cash.erl) discriminates on
%%     existing_home_disposal's PRESENCE in Upstream (mirrors how tax_optimised_structure
%%     marks Mode C's investor path) and folds its net_sale_proceeds into the HAVE side —
%%     a real data dependency, so existing_home_disposal MUST precede cash_position;
%%   - mortgage_finance/disposition are verified-reused-unchanged (mode-e-wedge.md P2) and
%%     read nothing existing_home_disposal-specific, so their position mirrors Mode A's
%%     precedent order rather than being data-forced.
%% Before this clause existed, an unknown slug fell through to ?BASE_COMPONENTS (the Mode-A
%% sequence), which silently DROPS existing_home_disposal (order/2 filters to names present
%% in the blueprint — `eligibility` isn't one of nexthome-domestic-au's components) —
%% the base turn would have run without it, a genuine gap this clause closes.
-define(BASE_COMPONENTS_NEXTHOME,
        [<<"buyer_profile">>, <<"existing_home_disposal">>, <<"mortgage_finance">>,
         <<"cash_position">>, <<"ownership_planning">>, <<"disposition">>,
         <<"purchase_journey">>, <<"preparation">>, <<"phase_playbook">>]).

-spec start_link(map()) -> gen_statem:start_ret().
start_link(Args) ->
    gen_statem:start_link(?MODULE, Args, []).

-spec callback_mode() -> gen_statem:callback_mode_result().
callback_mode() -> state_functions.

%% Args (base) :: #{tenant_id, user_id, plan_card_id, turn_id, blueprint_slug, mode,
%%                  intent, firb_required_any, onboarding}
%% Args (qa)   :: the above with kind => qa, plus card, message, locale (2c-1).
%% `kind` selects the turn shape: a base/onboarding turn walks the DAG; a Q&A turn
%% runs one conversational pass over the filled card (agentic-flow.md §4).
init(#{tenant_id := T, plan_card_id := PC, turn_id := Tn} = Args) ->
    fh_engine_turn_registry:set_pid(PC, Tn, self()),
    emit(T, PC, <<"turn_started">>,
         #{<<"plan_card_id">> => PC, <<"turn_id">> => Tn}),
    case maps:get(kind, Args, base) of
        K when K =:= base; K =:= base_resolver ->
            %% base = full walk (resolver + two-path sidecar); base_resolver =
            %% resolver-only refresh (plan-card-refresh.md): two-path components run
            %% their resolver half and re-attach the EXISTING agent leaves, no sidecar.
            Components = base_components(maps:get(blueprint_slug, Args)),
            Data = Args#{components => Components, outcomes => #{}},
            {ok, running, Data, [{next_event, internal, step}]};
        property ->
            %% Phase-B per-property turn (mode-c-wedge.md "Phase B"): walk the per-property
            %% component set against an ATTACHED property. The base outcomes already exist
            %% (the base turn ran), so they are seeded as upstream (keyed by outcome_type) —
            %% property_assessment reads `profile` from here; downstream per-property
            %% components (Slice B+) read the rest. The attached property_card rides Args and
            %% reaches the resolver/sidecar; commits snapshot into content.addenda.<pid>.
            Slug = maps:get(blueprint_slug, Args),
            Components = property_components(Slug),
            Seed = outcomes_by_type(Slug, maps:get(base_components_snapshot, Args, #{})),
            Data = Args#{components => Components, outcomes => Seed},
            {ok, running, Data, [{next_event, internal, step}]};
        transaction ->
            %% A `<from_transaction>` re-fill (engine-contract §11): the user attested contract
            %% dates for an ALREADY-ATTACHED property → a RESOLVER-ONLY re-fill of settlement_prep
            %% alone (no sidecar, no usage). Components is the single settlement_prep def (picked
            %% from the per-property set). The seed is base ∪ addendum outcomes by outcome_type
            %% (the addendum wins for per-property types) — settlement_prep reads property_fit_
            %% investor (state/property_type) + tax_optimised_structure (recommended_entity), both
            %% in the addendum after the attach turn, NOT recomputed here. `transaction` rides Args
            %% and reaches the resolver (the dated branch reads it).
            Slug = maps:get(blueprint_slug, Args),
            Components = [C || C <- property_components(Slug),
                              maps:get(<<"name">>, C) =:= <<"settlement_prep">>],
            BaseSeed = outcomes_by_type(Slug, maps:get(base_components_snapshot, Args, #{})),
            AddSeed  = outcomes_by_type(Slug, maps:get(addendum_components_snapshot, Args, #{})),
            Seed = maps:merge(BaseSeed, AddSeed),
            Data = Args#{components => Components, outcomes => Seed},
            {ok, running, Data, [{next_event, internal, step}]};
        document ->
            %% A `<from_document>` re-fill (due_diligence B): the user UPLOADED the current lease
            %% for an ALREADY-ATTACHED property → a DOCUMENT-GATED two-path re-fill of due_diligence
            %% alone. Components is the single due_diligence def (picked from the per-property set).
            %% The seed is base ∪ addendum outcomes by outcome_type — due_diligence reads
            %% property_fit_investor (the market-rent reference) + strategy_thesis (the target yield),
            %% both already in the addendum/base after the attach turn, NOT recomputed here. The
            %% inline `document` rides Args and reaches the resolver-grounded lease_interpretation
            %% sidecar via start_fill_port; the bytes are transient (never persisted). effective_fill_
            %% path/2 sees the document present → due_diligence runs two-path (the sidecar fires).
            Slug = maps:get(blueprint_slug, Args),
            Components = [C || C <- property_components(Slug),
                              maps:get(<<"name">>, C) =:= <<"due_diligence">>],
            BaseSeed = outcomes_by_type(Slug, maps:get(base_components_snapshot, Args, #{})),
            AddSeed  = outcomes_by_type(Slug, maps:get(addendum_components_snapshot, Args, #{})),
            Seed = maps:merge(BaseSeed, AddSeed),
            Data = Args#{components => Components, outcomes => Seed},
            {ok, running, Data, [{next_event, internal, step}]};
        qa ->
            {ok, qa, Args, [{next_event, internal, start}]}
    end.

%% --- running state ----------------------------------------------------------

%% Drive the DAG walk one component at a time.
running(internal, step, #{components := []} = Data) ->
    #{tenant_id := T, plan_card_id := PC, turn_id := Tn} = Data,
    emit(T, PC, <<"turn_completed">>,
         #{<<"plan_card_id">> => PC, <<"turn_id">> => Tn}),
    {stop, normal, Data};
running(internal, step, #{components := [Comp | Rest]} = Data) ->
    Name = maps:get(<<"name">>, Comp),
    case effective_fill_path(Comp, Data) of
        resolver ->
            %% Resolver: fill in-process, commit, accumulate, advance.
            {Outcome, Renderer, KbVersions} =
                fh_engine_fill:resolver(Name, Data, maps:get(outcomes, Data)),
            case commit(Comp, <<"resolver">>, Renderer, KbVersions, Outcome, Data) of
                {ok, Data1} ->
                    {keep_state, Data1#{components := Rest},
                     [{next_event, internal, step}]};
                {blocked, G, _} ->
                    fail(Data, <<"compliance_block">>, gate_detail(G)),
                    {stop, normal, Data}
            end;
        two_path ->
            %% Two-path (mortgage-finance-two-path.md): the resolver half is a PURE
            %% function of (facts, upstream, artifact); the agent half is the qualitative
            %% lender_fit leaves. The two are INDEPENDENT (§98). So the resolver half is
            %% recomputed on EVERY base-DAG walk — only the AGENT half varies by turn kind,
            %% and only in its SOURCE: the sidecar (a full `base` turn) or the stored
            %% snapshot (a `base_resolver` refresh). A RESOLVER-ONLY refresh re-runs the
            %% resolver half (so a compliance-sensitive figure like borrowing_capacity
            %% recomputes when income arrives via /profile, IC4 — §98: a figure must equal
            %% f(current facts)) and RE-ATTACHES the stored agent leaves through the SAME
            %% merge_agent the sidecar path uses (no sidecar, no LLM, no usage). This is
            %% the preview/commit-parity invariant: fh_engine_simulate recomputes the
            %% resolver half too, so commit must compute it identically. The commit
            %% re-validates the re-attached leaf (fail-closed); a leaf that was gate-valid
            %% when first committed passes again (Wedge-1a cards are post-bilingual-gate).
            %% REUSE the stored agent leaf (resolver-only, no sidecar/LLM/usage) vs run the
            %% sidecar (fresh agent fill). Reuse when the agent judgment is already decided:
            %%   - base_resolver: the plan-card-refresh sweep (stored leaf from existing_outcomes);
            %%   - a `property` turn refreshing a scope:both two-path component whose base outcome is
            %%     in the seed (e.g. tax_structure — the entity was decided at base; the per-property
            %%     turn refreshes only its resolver figures off the per-property cash flow).
            %% Run the sidecar when the agent leaves are fresh: a base full turn, or a per-property
            %% component with no base outcome in the seed (e.g. property_assessment — rent/valuation
            %% for THIS property genuinely needs the agent).
            case two_path_stored_leaf(Data, Comp) of
                {reuse, Existing} ->
                    {RO, Renderer, KbVersions} =
                        fh_engine_fill:resolver(Name, Data, maps:get(outcomes, Data)),
                    AgentValues = fh_engine_fill:agent_values_from_outcome(Name, Existing),
                    Final = fh_engine_fill:merge_agent(Name, RO, AgentValues),
                    case commit(Comp, <<"two_path">>, Renderer, KbVersions, Final, Data) of
                        {ok, Data1} ->
                            {keep_state, Data1#{components := Rest},
                             [{next_event, internal, step}]};
                        {blocked, G, _} ->
                            fail(Data, <<"compliance_block">>, gate_detail(G)),
                            {stop, normal, Data}
                    end;
                fresh ->
                    {RO, Renderer, KbVersions} =
                        fh_engine_fill:resolver(Name, Data, maps:get(outcomes, Data)),
                    Port = start_fill_port(Comp, Data, RO),
                    Pending = #{kind => two_path, comp => Comp, resolver_outcome => RO,
                                renderer => Renderer, kb => KbVersions},
                    {keep_state, Data#{components := Rest, port => Port, pending => Pending}}
            end;
        agent ->
            %% Pure agent: the sidecar fills the whole outcome (no resolver half — the
            %% later per-property valuation/negotiation components). Park until it replies.
            Port = start_fill_port(Comp, Data, undefined),
            Pending = #{kind => agent, comp => Comp},
            {keep_state, Data#{components := Rest, port => Port, pending => Pending}}
    end;

running(info, {Port, {data, Frame}}, #{port := Port} = Data) ->
    handle_sidecar(fh_engine_util:json_decode(Frame), Data);
running(info, {Port, {exit_status, N}}, #{port := Port} = Data) ->
    fail(Data, <<"sidecar_crashed">>,
         iolist_to_binary(io_lib:format("sidecar exit status ~p before reply", [N]))),
    {stop, normal, Data};
running(cast, cancel, #{tenant_id := T, plan_card_id := PC, turn_id := Tn} = Data) ->
    close_port(Data),
    emit(T, PC, <<"turn_cancelled">>,
         #{<<"plan_card_id">> => PC, <<"turn_id">> => Tn}),
    {stop, normal, Data};
running(_EventType, _Event, Data) ->
    {keep_state, Data}.

%% --- qa state (2c-3) --------------------------------------------------------
%% A Q&A turn runs ONE conversational pass over the FILLED card (agentic-flow.md §4):
%% re-ground from `card` (passed in Args, constraint #9), assemble glue from `sessions`,
%% spawn the KB-lookup sidecar, forward its sanitized tool_use/tool_result LIVE, buffer
%% the bilingual answer, run it through the compliance pipeline (buffer-then-gate,
%% compliance-pipeline.md §10), and only THEN emit `text_delta{lang}` + persist the glue
%% pair. The answer text never streams token-by-token — buffer-then-gate is the whole
%% point (an ungated advice crossing on a regulated surface can't be un-shown).

qa(internal, start, #{tenant_id := T, user_id := U, plan_card_id := PC} = Data) ->
    Glue = fh_engine_store:read_glue(T, U, PC),
    Port = start_qa_port(Data, Glue),
    {keep_state, Data#{port => Port}};
qa(info, {Port, {data, Frame}}, #{port := Port} = Data) ->
    handle_qa_sidecar(fh_engine_util:json_decode(Frame), Data);
qa(info, {Port, {exit_status, N}}, #{port := Port} = Data) ->
    fail(Data, <<"sidecar_crashed">>,
         iolist_to_binary(io_lib:format("qa sidecar exit status ~p before reply", [N]))),
    {stop, normal, Data};
qa(cast, cancel, #{tenant_id := T, plan_card_id := PC, turn_id := Tn} = Data) ->
    close_port(Data),
    emit(T, PC, <<"turn_cancelled">>,
         #{<<"plan_card_id">> => PC, <<"turn_id">> => Tn}),
    {stop, normal, Data};
qa(_EventType, _Event, Data) ->
    {keep_state, Data}.

%% --- qa sidecar dispatch ----------------------------------------------------

%% tool_use / tool_result are machinery signals (already sanitized by the sidecar — no
%% raw KB / slug) and DO stream live, so the shell can show "looking up…".
handle_qa_sidecar(#{<<"method">> := <<"tool_use">>, <<"params">> := P},
                  #{tenant_id := T, plan_card_id := PC} = Data) ->
    emit(T, PC, <<"tool_use">>, P#{<<"plan_card_id">> => PC}),
    {keep_state, Data};
handle_qa_sidecar(#{<<"method">> := <<"tool_result">>, <<"params">> := P},
                  #{tenant_id := T, plan_card_id := PC} = Data) ->
    emit(T, PC, <<"tool_result">>, P#{<<"plan_card_id">> => PC}),
    {keep_state, Data};
handle_qa_sidecar(#{<<"method">> := <<"qa_answer">>, <<"params">> := P}, Data) ->
    %% Buffer-then-gate: the complete answer arrives here; gate it, THEN emit.
    case commit_qa(P, Data) of
        {ok, Data1} ->
            {keep_state, Data1};
        {blocked, Data1} ->
            %% turn_failed already emitted by commit_qa; the answer never reaches the user.
            close_port(Data1),
            {stop, normal, Data1}
    end;
handle_qa_sidecar(#{<<"method">> := <<"usage">>, <<"params">> := P},
                  #{tenant_id := T, user_id := U, plan_card_id := PC, turn_id := Tn} = Data) ->
    emit(T, PC, <<"usage">>,
         P#{<<"plan_card_id">> => PC, <<"turn_id">> => Tn, <<"user_id">> => U}),
    {keep_state, Data};
handle_qa_sidecar(#{<<"method">> := <<"qa_done">>},
                  #{tenant_id := T, plan_card_id := PC, turn_id := Tn} = Data) ->
    close_port(Data),
    emit(T, PC, <<"turn_completed">>,
         #{<<"plan_card_id">> => PC, <<"turn_id">> => Tn}),
    {stop, normal, Data};
handle_qa_sidecar(#{<<"method">> := <<"error">>, <<"params">> := P}, Data) ->
    close_port(Data),
    fail(Data, maps:get(<<"code">>, P, <<"qa_error">>),
         maps:get(<<"message">>, P, <<"">>)),
    {stop, normal, Data};
handle_qa_sidecar(_Other, Data) ->
    {keep_state, Data}.

%% Gate the buffered answer (two layers, compliance-pipeline.md §10), then emit it.
commit_qa(P, #{tenant_id := T, user_id := U, plan_card_id := PC, turn_id := Tn,
               mode := Mode, message := Msg} = Data) ->
    Answer = maps:get(<<"answer">>, P, #{}),
    Slugs = maps:get(<<"kb_slugs">>, P, []),
    KbVersions = [#{<<"slug">> => S} || S <- Slugs],
    %% Layer 1: the bilingual structural post-condition on the answer (both locales
    %% present, non-empty, pairwise-distinct). Fail-closed CRASH on a non-bilingual
    %% answer — a producer contract breach, not a regulated decision (§10). The figure/
    %% enum clauses are vacuous on free text.
    Locales = fh_engine_kb:locales(),
    ok = case fh_engine_outcome:check(#{<<"kind">> => <<"localized">>}, Answer, Locales) of
             ok -> ok;
             {error, R} -> error({qa_answer_nonconforming, R})
         end,
    Layer1Verdict = #{<<"layer">> => 1, <<"localized">> => <<"conformed">>,
                      <<"figure_type">> => <<"not_applicable">>},
    %% Layer 2: ASIC substantive on the free text; FIRB/AML assert-clear (Mode A).
    Ctx = #{mode => Mode, intent => maps:get(intent, Data, <<"owner_occupier">>),
            firb_required_any => maps:get(firb_required_any, Data, false)},
    {_, Gates} = fh_engine_compliance:run_qa(Ctx, Answer, Layer1Verdict),
    %% Audit + stream every gate, clear or not (the q_and_a producer; fill_path agent).
    lists:foreach(
        fun(G) ->
            ok = fh_engine_store:append_audit(T, PC, <<"q_and_a">>, <<"agent">>,
                                              KbVersions, G),
            emit(T, PC, <<"compliance_gate">>,
                 G#{<<"plan_card_id">> => PC, <<"component_id">> => <<"q_and_a">>})
        end, Gates),
    case blocking_gate(Gates) of
        {block, G} ->
            fail(Data, <<"asic_block">>, gate_detail(G)),
            {blocked, Data};
        none ->
            %% Cleared: NOW emit the answer, one text_delta per language (§4).
            emit_answer(T, PC, Answer),
            %% Persist the turn — full bilingual Answer (read_conversation/3 serves it
            %% to the shell; read_glue/3 still reads only the EN half for prompt glue).
            ok = fh_engine_store:append_session_turn(T, U, PC, Tn, Msg, Answer),
            {ok, Data}
    end.

emit_answer(T, PC, Answer) ->
    lists:foreach(
        fun(Lang) ->
            case maps:get(Lang, Answer, undefined) of
                undefined -> ok;
                Text ->
                    emit(T, PC, <<"text_delta">>,
                         #{<<"text">> => Text, <<"lang">> => Lang,
                           <<"plan_card_id">> => PC})
            end
        end, [<<"vi">>, <<"en">>]).

%% --- sidecar message dispatch (agent fills) ---------------------------------

handle_sidecar(#{<<"method">> := <<"component_filled">>, <<"params">> := P},
               #{pending := #{kind := two_path, comp := Comp, resolver_outcome := RO,
                              renderer := Renderer, kb := KbVersions}} = Data) ->
    %% Two-path: the sidecar reply carries ONLY the agent leaves; fold them into the
    %% resolver outcome (the renderer + KB are the resolver's). fill_path: two_path.
    Name = maps:get(<<"name">>, Comp),
    AgentValues = maps:get(<<"outcome">>, P, #{}),
    Final = fh_engine_fill:merge_agent(Name, RO, AgentValues),
    case commit(Comp, <<"two_path">>, Renderer, KbVersions, Final, Data) of
        {ok, Data1} ->
            {keep_state, Data1};
        {blocked, G, _} ->
            close_port(Data),
            fail(Data, <<"compliance_block">>, gate_detail(G)),
            {stop, normal, Data}
    end;
handle_sidecar(#{<<"method">> := <<"component_filled">>, <<"params">> := P},
               #{pending := #{kind := agent, comp := Comp}} = Data) ->
    Renderer = maps:get(<<"renderer">>, P, default_renderer(Comp)),
    KbVersions = maps:get(<<"kb_versions">>, P, []),
    Outcome = maps:get(<<"outcome">>, P, #{}),
    case commit(Comp, <<"agent">>, Renderer, KbVersions, Outcome, Data) of
        {ok, Data1} ->
            {keep_state, Data1};
        {blocked, G, _} ->
            close_port(Data),
            fail(Data, <<"compliance_block">>, gate_detail(G)),
            {stop, normal, Data}
    end;
handle_sidecar(#{<<"method">> := <<"usage">>, <<"params">> := P},
               #{tenant_id := T, user_id := U, plan_card_id := PC, turn_id := Tn} = Data) ->
    %% Meter at the LLM-call boundary (engine-contract §4); persisted Erlang-side.
    %% user_id rides the event (§9) so the shell's outbox attributes tokens without a
    %% join — the acting user (the JWT that created the turn; == card owner under the
    %% 8-S4a ownership gate in Wedge 1a).
    emit(T, PC, <<"usage">>,
         P#{<<"plan_card_id">> => PC, <<"turn_id">> => Tn, <<"user_id">> => U}),
    {keep_state, Data};
handle_sidecar(#{<<"method">> := <<"fill_done">>}, Data) ->
    %% The sidecar finished its single component fill; close the disposable port and
    %% resume the DAG walk. (Turn-level completion is the gen_statem's, not the
    %% sidecar's — emitted when the walk runs out of components.)
    close_port(Data),
    {keep_state, maps:remove(pending, maps:remove(port, Data)),
     [{next_event, internal, step}]};
handle_sidecar(#{<<"method">> := <<"error">>, <<"params">> := P}, Data) ->
    close_port(Data),
    fail(Data, maps:get(<<"code">>, P, <<"sidecar_error">>),
         maps:get(<<"message">>, P, <<"">>)),
    {stop, normal, Data};
handle_sidecar(_Other, Data) ->
    {keep_state, Data}.

%% --- terminate --------------------------------------------------------------

terminate(_Reason, _State, #{plan_card_id := PC}) ->
    fh_engine_turn_registry:release(PC),
    ok.

%% --- commit (compliance → persist → snapshot → publish) ---------------------

commit(Comp, FillPath, Renderer, KbVersions, Outcome0,
       #{tenant_id := T, plan_card_id := PC} = Data) ->
    Name = maps:get(<<"name">>, Comp),
    %% A Phase-B (per-property) turn carries property_id: its commits snapshot into the
    %% addendum namespace and tag every event so the shell attributes them to that property.
    PropId = maps:get(property_id, Data, undefined),
    OutcomeType = maps:get(<<"outcome_type">>, Comp, Name),
    %% Layer 1 (outcome-conformance.md): the structural post-condition, BEFORE the
    %% regulated pipeline. Fail-closed — a non-conforming fill crashes this (supervised)
    %% turn rather than persisting a bad value (§7).
    ok = fh_engine_outcome:validate(maps:get(blueprint_slug, Data), OutcomeType, Outcome0),
    %% The Layer-1 attestation ASIC consumes (compliance-pipeline.md §2 — ASIC does not
    %% re-derive §98; one source of truth). Reaching here means validate/3 found the
    %% outcome conforming (figures are figures, localized text is bilingual).
    Layer1Verdict = #{<<"layer">> => 1,
                      <<"outcome_type">> => OutcomeType,
                      <<"figure_type">> => <<"conformed">>,
                      <<"localized">> => <<"conformed">>},
    %% Layer 2: regulated dispositions over the conforming outcome.
    Ctx = #{mode => maps:get(mode, Data),
            intent => maps:get(intent, Data, <<"owner_occupier">>),
            firb_required_any => maps:get(firb_required_any, Data, false)},
    {Outcome, Gates} = fh_engine_compliance:run(Name, Ctx, Outcome0, Layer1Verdict),
    %% Audit + stream every gate, clear or not (compliance-pipeline.md §5): the
    %% audit_events row is the regulated trail; the compliance_gate event is its live signal.
    lists:foreach(
        fun(G) ->
            ok = fh_engine_store:append_audit(T, PC, Name, FillPath, KbVersions, G),
            emit(T, PC, <<"compliance_gate">>,
                 tag_property(G#{<<"plan_card_id">> => PC, <<"component_id">> => Name}, PropId))
        end, Gates),
    case blocking_gate(Gates) of
        {block, G} ->
            %% A regulated stop (§4): the outcome must NOT reach content_jsonb or
            %% component_filled. The audit row written above is the record.
            {blocked, G, Data};
        none ->
            Entry = #{
                <<"component_id">> => Name,
                <<"scope">> => component_scope(Name),
                %% renderer = renderers[0] (back-compat); renderers = the blueprint's ordered
                %% list from the artifact (SOT) so the shell reaches a composed component's 2nd
                %% renderer (engine-contract §4 — opportunity-card on ownership_planning_investor).
                <<"renderer">> => Renderer,
                <<"renderers">> => renderers_for(Comp, Renderer),
                <<"outcome">> => Outcome,
                <<"kb_versions">> => KbVersions,
                <<"fill_path">> => FillPath
            },
            %% Base commit → content.components.<id>; Phase-B commit → the addendum
            %% namespace content.addenda.<pid>.components.<id> (PropId set on a property turn).
            case PropId of
                undefined ->
                    fh_engine_store:snapshot_component(PC, Name, Entry);
                _ ->
                    fh_engine_store:snapshot_addendum_component(PC, PropId, Name, Entry)
            end,
            emit(T, PC, <<"component_filled">>,
                 tag_property(Entry#{<<"plan_card_id">> => PC}, PropId)),
            Outcomes = maps:get(outcomes, Data),
            {ok, Data#{outcomes := Outcomes#{OutcomeType => Outcome}}}
    end.

%% The first `block` disposition among the gates, if any (compliance-pipeline.md §4).
blocking_gate(Gates) ->
    case [G || G <- Gates, maps:get(<<"disposition">>, G) =:= <<"block">>] of
        [G | _] -> {block, G};
        []      -> none
    end.

gate_detail(G) -> maps:get(<<"detail">>, G, <<"blocked">>).

%% --- internals --------------------------------------------------------------

emit(Tenant, PlanCardId, Type, Payload) ->
    {ok, EventId} = fh_engine_store:append_event(Tenant, PlanCardId, Type, Payload),
    fh_engine_pubsub:publish(PlanCardId, {EventId, Type, Payload}),
    ok.

fail(#{tenant_id := T, plan_card_id := PC, turn_id := Tn}, Code, Msg) ->
    emit(T, PC, <<"turn_failed">>,
         #{<<"plan_card_id">> => PC, <<"turn_id">> => Tn,
           <<"code">> => Code, <<"message">> => Msg}).

%% The card's blueprint components, filtered to the base set, in DAG order. Exported as
%% the SINGLE source of the ordered base-resolver DAG: the simulate preview
%% (fh_engine_simulate) walks this same list, so the turn and the preview can never
%% drift on which components run or in what order (engine-contract §10.1).
%% BlueprintSlug selects BOTH the blueprint's component definitions AND the per-blueprint
%% base SET+ORDER (P5-activate, mode-c-wedge.md): fhb-domestic-au → the Mode-A sequence;
%% investor-domestic-au → the Mode-C investor spine (the discriminator-ordered set above);
%% fhb-foreign-au → the Mode-B foreign spine (mode-b-wedge.md P5); investor-foreign-au →
%% the Mode-D foreign-investor spine (mode-d-wedge.md P5); nexthome-domestic-au → the
%% Mode-E next-home spine (mode-e-wedge.md P5). The base set+order is an engine-owned
%% concern (these macros, not the artifact) — the blueprint declares dag_reads, not the
%% base/per-property split. An unknown slug falls through to the FHB sequence (the only
%% blueprint that created base turns pre-P5).
base_components(<<"investor-domestic-au">> = Slug) ->
    order(Slug, ?BASE_COMPONENTS_INVESTOR);
base_components(<<"fhb-foreign-au">> = Slug) ->
    order(Slug, ?BASE_COMPONENTS_FOREIGN);
base_components(<<"investor-foreign-au">> = Slug) ->
    order(Slug, ?BASE_COMPONENTS_FOREIGN_INVESTOR);
base_components(<<"nexthome-domestic-au">> = Slug) ->
    order(Slug, ?BASE_COMPONENTS_NEXTHOME);
base_components(Slug) ->
    order(Slug, ?BASE_COMPONENTS).

%% Whole lifecycle -> P-7 · One declaration per outcome shape -> The engine -> unknown component silently dropped
%% A name in a component list that the loaded artifact lacks is dropped without error
%% (the maps:is_key filter), so a new component needs a re-emitted artifact AND a test
%% asserting it is selected — otherwise its phase is simply missing from the plan.
%% Concluded 2026-10-06 from reading this function; no check guards it today.
order(BlueprintSlug, Names) ->
    {ok, All} = fh_engine_kb:components(BlueprintSlug),
    ByName = maps:from_list([{maps:get(<<"name">>, C), C} || C <- All]),
    [maps:get(N, ByName) || N <- Names, maps:is_key(N, ByName)].

%% Decide whether a two-path component reuses its stored agent leaf (resolver-only refresh, no
%% sidecar/LLM/usage) or runs the sidecar for a fresh agent fill:
%%   - base_resolver: always reuse — the plan-card-refresh sweep (stored leaf keyed by component
%%     name in existing_outcomes);
%%   - property turn: reuse iff the component's outcome_type is already in the seed (a scope:both
%%     two-path component whose agent judgment was decided at base — e.g. tax_structure's entity);
%%     a per-property component with no base outcome (property_assessment) is a fresh agent fill;
%%   - base (full) turn: always fresh (the sidecar authors the agent leaves).
two_path_stored_leaf(Data, Comp) ->
    Name = maps:get(<<"name">>, Comp),
    case maps:get(kind, Data, base) of
        base_resolver ->
            {reuse, maps:get(Name, maps:get(existing_outcomes, Data, #{}), #{})};
        property ->
            OutcomeType = maps:get(<<"outcome_type">>, Comp, Name),
            case maps:get(OutcomeType, maps:get(outcomes, Data), undefined) of
                undefined -> fresh;
                Existing  -> {reuse, Existing}
            end;
        _ ->
            fresh
    end.

%% The fill path of a base component (mortgage-finance-two-path.md §2): empty
%% `agent_leaves` → resolver (in-process); non-empty + a resolver exists → two_path
%% (resolver figures + agent leaves, Erlang-merged); non-empty + no resolver → agent
%% (the sidecar fills the whole outcome — the later per-property components).
fill_path(Comp) ->
    Name = maps:get(<<"name">>, Comp),
    case maps:get(<<"agent_leaves">>, Comp, []) of
        [] -> resolver;
        _  -> case fh_engine_fill:has_resolver(Name) of
                  true  -> two_path;
                  false -> agent
              end
    end.

%% The fill path ACTUALLY taken this turn — fill_path/1 (artifact-derived) refined by a runtime
%% input gate. due_diligence (due_diligence B) carries the lease_interpretation agent leaf, so
%% fill_path/1 reports two_path wherever it runs; but the leaf's irreducible input is the UPLOADED
%% lease, so the sidecar may fire only when a lease is present. A plain property attach (no
%% document in Data) runs due_diligence RESOLVER-ONLY (honest-partial: the procurement checklist +
%% the computable yield flag, no LLM call, no usage); a `document` turn (lease present) runs it
%% two-path. This is the one place the engine expresses "an agent leaf whose required input is
%% absent falls back to resolver-only" — it cannot be an artifact property (document-presence is a
%% runtime fact), and it preserves "resolver-only at A" for the no-lease path. Every other
%% component is unaffected (passes fill_path/1 through).
effective_fill_path(Comp, Data) ->
    case fill_path(Comp) of
        two_path ->
            case maps:get(<<"name">>, Comp) of
                <<"due_diligence">> ->
                    case maps:get(document, Data, undefined) of
                        undefined -> resolver;
                        _         -> two_path
                    end;
                _ -> two_path
            end;
        Other -> Other
    end.

%% reasoning_domain of an agent component = its agent leaves' shared domain.
reasoning_domain(Comp) ->
    case maps:get(<<"agent_leaves">>, Comp, []) of
        [#{<<"reasoning_domain">> := D} | _] -> D;
        _ -> null
    end.

default_renderer(Comp) ->
    case maps:get(<<"renderers">>, Comp, []) of
        [R | _] -> R;
        _ -> <<"summary-card">>
    end.

%% The component's ordered renderer list for the snapshot/event (engine-contract §4). The
%% artifact's `renderers` is the SOT; fall back to [Renderer] so a component the artifact
%% does not enumerate still carries a one-element list (renderer = renderers[0] invariant).
renderers_for(Comp, Renderer) ->
    case maps:get(<<"renderers">>, Comp, []) of
        [_ | _] = Rs -> Rs;
        _            -> [Renderer]
    end.

component_scope(<<"buyer_profile">>)    -> <<"base">>;
component_scope(<<"purchase_journey">>) -> <<"base">>;
component_scope(<<"preparation">>)      -> <<"base">>;
component_scope(<<"phase_playbook">>)   -> <<"base">>;
component_scope(<<"disposition">>)      -> <<"base">>;
component_scope(<<"family_context">>)   -> <<"base">>;   %% Mode-B (fhb-foreign-au §-table)
component_scope(<<"property_assessment">>) -> <<"per-property">>;
component_scope(_) -> <<"both">>.

%% Tag an event with property_id on a Phase-B (per-property) turn; a base turn (undefined)
%% leaves the event unchanged.
tag_property(Event, undefined) -> Event;
tag_property(Event, PropId)    -> Event#{<<"property_id">> => PropId}.

%% The per-property component set for a Phase-B turn, in DAG order. Slice A builds the keystone
%% (property_assessment → property_fit_investor); Slice B the downstream `both`-component re-fills
%% (yield_modelling/tax_structure/cash_position/disposition); Slice C the investor bid plan
%% (buying_strategy); Slice C-settle the settlement checklist (settlement_prep, resolver-only,
%% honest-partial — dated path gated on contract dates, structure filled now); Slice C-dd the
%% due-diligence assessment (due_diligence, resolver-only at A, honest-partial — document-risk
%% surfacing gated on the upload pipeline, the procurement checklist + computable yield-vs-thesis
%% flag filled now). Engine-owned set, like base_components/1. A non-investor blueprint has no
%% built per-property turn yet → empty.
property_components(<<"investor-domestic-au">> = Slug) ->
    %% Slice A: property_assessment (the keystone → property_fit_investor).
    %% Slice B1/B3a: yield_modelling re-fills per-property — its resolver branches on the
    %% property_fit_investor now in upstream and computes the banded cash_flow_projection.
    %% Slice B3b: cash_position re-fills per-property — the cash-to-complete off the exact price.
    %% Slice B2: tax_structure re-fills per-property — RESOLVER-ONLY (the entity agent leaf was
    %% decided at base, re-attached from the seed by two_path_stored_leaf/2; no sidecar/LLM/usage),
    %% refreshing the rent/income-dependent tax figures (negative gearing, after-tax cash flow) off
    %% the per-property cash_flow_projection. It runs AFTER yield_modelling (reads its cash flow)
    %% and BEFORE cash_position/disposition (they read its refreshed CGT determinants).
    %% Slice B3c: disposition re-fills per-property — price-aware (the attached price drives the
    %% dispose figures); reads cash_position (acquire) + yield_modelling (hold) for the full horizon.
    %% order/2 keeps the canonical order (property_assessment → yield_modelling → tax_structure →
    %% cash_position → disposition); each reads property_fit_investor (in upstream after property_assessment).
    %% Slice C (buying_strategy): the investor bid plan re-fills per-property — TWO-PATH (the one
    %% negotiation_style leaf runs the sidecar, fill_path two_path; bid_plan_investor is NOT a base
    %% outcome → two_path_stored_leaf/2 returns `fresh`). Its RESOLVER half computes the yield-anchored
    %% discipline band (removed from the LLM's reach) + thesis_alignment, reading property_fit_investor
    %% (rent/price), strategy_thesis (target_gross_yield), and budget_envelope_investor — all in the
    %% seed/upstream → runs LAST.
    %% Slice C-dd (due_diligence A): the investor due-diligence assessment re-fills per-property —
    %% RESOLVER-ONLY AT A (its one lease_interpretation leaf needs the uploaded lease → due_diligence
    %% B), so two_path_stored_leaf/2 is irrelevant; it never runs the sidecar. HONEST-PARTIAL: the
    %% document-risk surfacing needs uploaded documents (the upload pipeline not built — due_diligence
    %% B), so it fills the document PROCUREMENT checklist + the bilingual actions/questions + the
    %% COMPUTABLE rental_yield_below_thesis_threshold flag (per-property yield vs strategy target),
    %% marking the document-dependent fields PENDING. Reads property_fit_investor (yield) +
    %% strategy_thesis (target_gross_yield), both in the seed/upstream.
    %% Slice C-settle (settlement_prep A): the investor settlement checklist re-fills per-property —
    %% RESOLVER-ONLY (zero agent leaves), so two_path_stored_leaf/2 is irrelevant; it never runs the
    %% sidecar. HONEST-PARTIAL: the dated critical path needs contract dates (a transaction-input
    %% surface not built — settlement_prep B), so it fills the milestone STRUCTURE + dependency DAG,
    %% the upstream-conditioned investor milestones (entity-setup off tax_optimised_structure), and
    %% the state-conditional insurance RULE (off property_fit_investor.state) — every date PENDING.
    %% Reads property_fit_investor (state/property_type) + tax_optimised_structure (recommended_entity),
    %% both in the seed/upstream → runs LAST (after due_diligence, matching blueprint component 9 < 10).
    %% ownership_planning_investor (scope: both) re-fills per-property AT THE END: its opportunity-card
    %% `equity_release` PLACES disposition's projected sale_proceeds/loan_payout, so it must follow
    %% disposition. The post-acquisition actuals stay null (not owned yet); the per-property delta is
    %% the equity_release band — honest-partial, [] when no hold horizon is set (disposition null).
    order(Slug, [<<"property_assessment">>, <<"yield_modelling">>, <<"tax_structure">>,
                 <<"cash_position">>, <<"disposition">>, <<"buying_strategy">>,
                 <<"due_diligence">>, <<"settlement_prep">>,
                 <<"ownership_planning_investor">>]);
property_components(_Slug) ->
    [].

%% Rebuild the base turn's accumulated outcomes (keyed by outcome_type, as the walk keys
%% them) from a card's content.components snapshot (keyed by component_id) — so a Phase-B
%% turn reads the already-computed base outcomes as upstream without re-running the base
%% walk. Maps component_id → outcome_type via the artifact component defs.
outcomes_by_type(BlueprintSlug, ContentComponents) when is_map(ContentComponents) ->
    {ok, All} = fh_engine_kb:components(BlueprintSlug),
    TypeOf = maps:from_list(
        [{maps:get(<<"name">>, C), maps:get(<<"outcome_type">>, C, maps:get(<<"name">>, C))}
         || C <- All]),
    maps:fold(
        fun(CompId, Entry, Acc) ->
            case maps:find(CompId, TypeOf) of
                {ok, OutcomeType} ->
                    Acc#{OutcomeType => maps:get(<<"outcome">>, Entry, #{})};
                error ->
                    Acc
            end
        end, #{}, ContentComponents);
outcomes_by_type(_BlueprintSlug, _Other) ->
    #{}.

%% Spawn a disposable sidecar to fill ONE agent component. The sidecar receives the
%% component id + reasoning_domain + the upstream outcomes it reads (filtered by the
%% blueprint DAG `dag_reads`), fills, emits component_filled + usage, and exits.
start_fill_port(Comp, #{plan_card_id := PC} = Data, ResolverOutcome) ->
    PythonExe = python_exe(),
    Script = planner_script(),
    Port = open_port({spawn_executable, PythonExe},
                     [{args, [Script]}, {packet, 4}, binary, exit_status]),
    %% For a two-path component the resolver has already computed the figures; hand
    %% them to the sidecar as READ-ONLY grounding so the lender reasoning is grounded
    %% in the real path/FHG facts. `undefined` (pure-agent) → no grounding block.
    Params0 = #{<<"plan_card_id">> => PC,
                <<"component_id">> => maps:get(<<"name">>, Comp),
                <<"reasoning_domain">> => reasoning_domain(Comp),
                <<"upstream">> => upstream_for(Comp, Data)},
    Params1 = case ResolverOutcome of
                 undefined -> Params0;
                 _         -> Params0#{<<"resolver_outcome">> => ResolverOutcome}
             end,
    %% A per-property component (property_assessment) reasons over the attached property's
    %% full facts (year built, land size, strata) — richer than the four neutral facts the
    %% resolver copies into the outcome. Hand the whole card to the sidecar as grounding.
    Params2 = case maps:get(property_card, Data, undefined) of
                 undefined -> Params1;
                 Card      -> Params1#{<<"property_card">> => Card}
             end,
    %% due_diligence B: the uploaded lease (the `<from_document>` input) rides the envelope as
    %% inline base64 on a `document` turn — the sidecar extracts text deterministically (no LLM)
    %% and grounds the lease_interpretation leaf in it. Transient: never persisted (architecture
    %% §11.9). Absent on every other turn → no `document` block.
    Params = case maps:get(document, Data, undefined) of
                 undefined -> Params2;
                 Doc       -> Params2#{<<"document">> => Doc}
             end,
    Req = #{<<"method">> => <<"fill_component">>, <<"params">> => Params},
    port_command(Port, fh_engine_util:json_encode(Req)),
    Port.

%% Spawn a disposable sidecar for ONE Q&A turn. It receives the user message, the FILLED
%% card (re-grounding, constraint #9), and the conversational glue; it runs the streaming
%% KB-lookup loop, buffers a bilingual answer, and emits tool_use/tool_result (live) +
%% qa_answer (buffered) + usage + qa_done, then exits (principle 3).
start_qa_port(#{plan_card_id := PC, message := Msg, card := Card} = Data, Glue) ->
    PythonExe = python_exe(),
    Script = planner_script(),
    Port = open_port({spawn_executable, PythonExe},
                     [{args, [Script]}, {packet, 4}, binary, exit_status]),
    Locale = case maps:get(locale, Data, undefined) of
                 undefined -> null;
                 L -> L
             end,
    Params = #{<<"plan_card_id">> => PC,
               <<"message">> => Msg,
               <<"card">> => Card,
               <<"glue">> => Glue,
               <<"locale">> => Locale},
    Req = #{<<"method">> => <<"qa">>, <<"params">> => Params},
    port_command(Port, fh_engine_util:json_encode(Req)),
    Port.

%% The accumulated outcomes this component reads, keyed by outcome type (§11.9:
%% components read upstream OUTCOMES, not parameters).
upstream_for(Comp, Data) ->
    Outcomes = maps:get(outcomes, Data),
    Name = maps:get(<<"name">>, Comp),
    Reads = dag_reads(maps:get(blueprint_slug, Data), Name),
    maps:with(Reads, Outcomes).

dag_reads(BlueprintSlug, Name) ->
    case fh_engine_kb:blueprint(BlueprintSlug) of
        {ok, Bp} -> maps:get(Name, maps:get(<<"dag_reads">>, Bp, #{}), []);
        _        -> []
    end.

close_port(#{port := Port}) ->
    case erlang:port_info(Port) of
        undefined -> ok;
        _ ->
            try port_close(Port) catch _:_ -> ok end,
            ok
    end;
close_port(_Data) ->
    ok.

%% Reproducible -> P-3 · The sidecar is stateless and disposable -> The engine -> sidecar paths resolve against engine cwd
%% FH_SIDECAR_PYTHON and FH_PLANNER_SCRIPT are passed to open_port as given, so a relative
%% value resolves against the engine's cwd (engine/erlang), not the repo root: a
%% repo-root-relative value crashes open_port with enoent on the first fill. Measured
%% 2026-07-04: investor_seam_smoke with real sonnet.
python_exe() ->
    case os:getenv("FH_SIDECAR_PYTHON") of
        false ->
            case os:find_executable("python3") of
                false -> error(python3_not_found);
                P -> P
            end;
        P -> P
    end.

%% Reproducible -> P-3 · The sidecar is stateless and disposable -> The sidecar -> stub sidecar default
%% With FH_PLANNER_SCRIPT unset the sidecar is planner_stub.py, not planner.py: no model
%% runs, and a `usage` event with model `stub` / 0 tokens says so. The stub must mirror
%% planner.py's reply protocol. Measured 2026-06: 2b-2b stub drift surfaced as "sidecar
%% exit 0 before reply"; the Mode-C Slice C seam and property_assessment_seam both
%% misattributed stub output to a "degraded LLM".
planner_script() ->
    case os:getenv("FH_PLANNER_SCRIPT") of
        false ->
            {ok, Cwd} = file:get_cwd(),
            %% rebar3 shell cwd = engine/erlang -> sidecars live at engine/python.
            filename:join([filename:dirname(Cwd), "python", "planner_stub.py"]);
        P -> P
    end.
