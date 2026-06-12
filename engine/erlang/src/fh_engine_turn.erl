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
-export([running/3]).

%% Mode-A base turn: the resolver/agent components in DAG (topological) order. The
%% per-property components (property_assessment, buying_strategy, due_diligence,
%% settlement_prep) are NOT in the base turn. (Deriving this from a `scope` field in
%% the artifact is a follow-on; the Mode-A base sequence is fixed.)
-define(BASE_COMPONENTS,
        [<<"buyer_profile">>, <<"eligibility">>, <<"mortgage_finance">>,
         <<"cash_position">>, <<"ownership_planning">>]).

-spec start_link(map()) -> gen_statem:start_ret().
start_link(Args) ->
    gen_statem:start_link(?MODULE, Args, []).

-spec callback_mode() -> gen_statem:callback_mode_result().
callback_mode() -> state_functions.

%% Args :: #{tenant_id, plan_card_id, turn_id, mode, intent, firb_required_any, onboarding}
init(#{tenant_id := T, plan_card_id := PC, turn_id := Tn} = Args) ->
    fh_engine_turn_registry:set_pid(PC, Tn, self()),
    emit(T, PC, <<"turn_started">>,
         #{<<"plan_card_id">> => PC, <<"turn_id">> => Tn}),
    Components = base_components(),
    Data = Args#{components => Components, outcomes => #{}},
    {ok, running, Data, [{next_event, internal, step}]}.

%% --- running state ----------------------------------------------------------

%% Drive the DAG walk one component at a time.
running(internal, step, #{components := []} = Data) ->
    #{tenant_id := T, plan_card_id := PC, turn_id := Tn} = Data,
    emit(T, PC, <<"turn_completed">>,
         #{<<"plan_card_id">> => PC, <<"turn_id">> => Tn}),
    {stop, normal, Data};
running(internal, step, #{components := [Comp | Rest]} = Data) ->
    Name = maps:get(<<"name">>, Comp),
    case fill_path(Comp) of
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
            %% Two-path (mortgage-finance-two-path.md): run the RESOLVER half first
            %% (all figures + the loan-path structure), then spawn the sidecar to fill
            %% only the agent leaves, passing the resolver outcome as read-only
            %% grounding. The walk parks until the sidecar replies; merge_agent folds
            %% the leaves in (§98: the agent never authors a figure — slot-scoped merge).
            {RO, Renderer, KbVersions} =
                fh_engine_fill:resolver(Name, Data, maps:get(outcomes, Data)),
            Port = start_fill_port(Comp, Data, RO),
            Pending = #{kind => two_path, comp => Comp, resolver_outcome => RO,
                        renderer => Renderer, kb => KbVersions},
            {keep_state, Data#{components := Rest, port => Port, pending => Pending}};
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
               #{tenant_id := T, plan_card_id := PC, turn_id := Tn} = Data) ->
    %% Meter at the LLM-call boundary (engine-contract §4); persisted Erlang-side.
    emit(T, PC, <<"usage">>,
         P#{<<"plan_card_id">> => PC, <<"turn_id">> => Tn}),
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
    OutcomeType = maps:get(<<"outcome_type">>, Comp, Name),
    %% Layer 1 (outcome-conformance.md): the structural post-condition, BEFORE the
    %% regulated pipeline. Fail-closed — a non-conforming fill crashes this (supervised)
    %% turn rather than persisting a bad value (§7).
    ok = fh_engine_outcome:validate(OutcomeType, Outcome0),
    %% The Layer-1 attestation ASIC consumes (compliance-pipeline.md §2 — ASIC does not
    %% re-derive §98; one source of truth). Reaching here means validate/2 found the
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
                 G#{<<"plan_card_id">> => PC, <<"component_id">> => Name})
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
                <<"renderer">> => Renderer,
                <<"outcome">> => Outcome,
                <<"kb_versions">> => KbVersions,
                <<"fill_path">> => FillPath
            },
            fh_engine_store:snapshot_component(PC, Name, Entry),
            emit(T, PC, <<"component_filled">>, Entry#{<<"plan_card_id">> => PC}),
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

%% The in-scope blueprint's components, filtered to the base set, in DAG order.
base_components() ->
    {ok, All} = fh_engine_kb:components(fh_engine_kb:in_scope_blueprint()),
    ByName = maps:from_list([{maps:get(<<"name">>, C), C} || C <- All]),
    [maps:get(N, ByName) || N <- ?BASE_COMPONENTS, maps:is_key(N, ByName)].

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

component_scope(<<"buyer_profile">>) -> <<"base">>;
component_scope(_) -> <<"both">>.

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
    Params = case ResolverOutcome of
                 undefined -> Params0;
                 _         -> Params0#{<<"resolver_outcome">> => ResolverOutcome}
             end,
    Req = #{<<"method">> => <<"fill_component">>, <<"params">> => Params},
    port_command(Port, fh_engine_util:json_encode(Req)),
    Port.

%% The accumulated outcomes this component reads, keyed by outcome type (§11.9:
%% components read upstream OUTCOMES, not parameters).
upstream_for(Comp, Data) ->
    Outcomes = maps:get(outcomes, Data),
    Name = maps:get(<<"name">>, Comp),
    Reads = dag_reads(Name),
    maps:with(Reads, Outcomes).

dag_reads(Name) ->
    case fh_engine_kb:blueprint(fh_engine_kb:in_scope_blueprint()) of
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

python_exe() ->
    case os:getenv("FH_SIDECAR_PYTHON") of
        false ->
            case os:find_executable("python3") of
                false -> error(python3_not_found);
                P -> P
            end;
        P -> P
    end.

planner_script() ->
    case os:getenv("FH_PLANNER_SCRIPT") of
        false ->
            {ok, Cwd} = file:get_cwd(),
            %% rebar3 shell cwd = engine/erlang -> sidecars live at engine/python.
            filename:join([filename:dirname(Cwd), "python", "planner_stub.py"]);
        P -> P
    end.
