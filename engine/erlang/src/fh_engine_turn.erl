-module(fh_engine_turn).
-behaviour(gen_statem).

%% One plan-card turn = one isolated gen_statem (principle 1; isolation-model.md).
%% Slice 1 of Wedge-1a #8: drives the base planning turn end-to-end through the
%% Erlang↔Python seam.
%%
%% Lifecycle: emit `turn_started` → open a disposable Python sidecar port
%% (principle 3, {packet,4} length-prefixed JSON-RPC) → relay each `component_filled`
%% the sidecar emits through the compliance pipeline (§6) → persist to
%% plan_card_events (SOT) + snapshot into plan_cards.content_jsonb → publish to the
%% per-card pg group for live SSE → on `turn_completed`, emit the terminal event and
%% stop. A state-timeout fails a wedged sidecar (the "wedged-but-alive" guard; the
%% full ping/pong heartbeat lands with slice 2's slow inference). Erlang owns
%% lifecycle/persistence/streaming; the sidecar only reasons (slice 2) or stubs.

-export([start_link/1]).
-export([callback_mode/0, init/1, terminate/3]).
-export([running/3]).

%% Generous for the deterministic stub; slice 2 tunes per inference + adds heartbeat.
-define(TURN_TIMEOUT, 15000).

-spec start_link(map()) -> gen_statem:start_ret().
start_link(Args) ->
    gen_statem:start_link(?MODULE, Args, []).

-spec callback_mode() -> gen_statem:callback_mode_result().
callback_mode() -> state_functions.

%% Args :: #{tenant_id, plan_card_id, turn_id, mode, intent, firb_required_any}
init(#{tenant_id := T, plan_card_id := PC, turn_id := Tn, mode := Mode} = Args) ->
    fh_engine_turn_registry:set_pid(PC, Tn, self()),
    emit(T, PC, <<"turn_started">>,
         #{<<"plan_card_id">> => PC, <<"turn_id">> => Tn}),
    Port = start_port(PC, Mode),
    {ok, running, Args#{port => Port},
     [{state_timeout, ?TURN_TIMEOUT, port_timeout}]}.

%% --- running state ----------------------------------------------------------

running(info, {Port, {data, Frame}}, #{port := Port} = Data) ->
    handle_msg(fh_engine_util:json_decode(Frame), Data);
running(info, {Port, {exit_status, 0}}, #{port := Port} = Data) ->
    %% Clean exit but no turn_completed first — the sidecar dropped the turn.
    fail(Data, <<"sidecar_exited">>, <<"sidecar exited before completing the turn">>),
    {stop, normal, Data};
running(info, {Port, {exit_status, N}}, #{port := Port} = Data) ->
    fail(Data, <<"sidecar_crashed">>,
         iolist_to_binary(io_lib:format("sidecar exit status ~p", [N]))),
    {stop, normal, Data};
running(state_timeout, port_timeout, Data) ->
    close_port(Data),
    fail(Data, <<"sidecar_timeout">>, <<"sidecar produced no output in time">>),
    {stop, normal, Data};
running(cast, cancel, #{tenant_id := T, plan_card_id := PC, turn_id := Tn} = Data) ->
    close_port(Data),
    emit(T, PC, <<"turn_cancelled">>,
         #{<<"plan_card_id">> => PC, <<"turn_id">> => Tn}),
    {stop, normal, Data};
running(_EventType, _Event, Data) ->
    {keep_state, Data}.

%% --- sidecar message dispatch ----------------------------------------------

handle_msg(#{<<"method">> := <<"component_filled">>, <<"params">> := P},
           #{tenant_id := T, plan_card_id := PC} = Data) ->
    ComponentId = maps:get(<<"component_id">>, P),
    Outcome0 = maps:get(<<"outcome">>, P, #{}),
    Ctx = #{mode => maps:get(mode, Data),
            intent => maps:get(intent, Data, <<"owner_occupier">>),
            firb_required_any => maps:get(firb_required_any, Data, false)},
    {Outcome, Gates} = fh_engine_compliance:run(ComponentId, Ctx, Outcome0),
    lists:foreach(
        fun(G) -> emit(T, PC, <<"compliance_gate">>, G#{<<"plan_card_id">> => PC}) end,
        Gates),
    Entry = #{
        <<"component_id">> => ComponentId,
        <<"scope">> => maps:get(<<"scope">>, P, <<"base">>),
        <<"renderer">> => maps:get(<<"renderer">>, P, <<"summary-card">>),
        <<"outcome">> => Outcome,
        <<"kb_versions">> => maps:get(<<"kb_versions">>, P, []),
        <<"fill_path">> => maps:get(<<"fill_path">>, P, <<"agent">>)
    },
    fh_engine_store:snapshot_component(PC, ComponentId, Entry),
    emit(T, PC, <<"component_filled">>, Entry#{<<"plan_card_id">> => PC}),
    {keep_state, Data, [{state_timeout, ?TURN_TIMEOUT, port_timeout}]};
handle_msg(#{<<"method">> := <<"turn_completed">>},
           #{tenant_id := T, plan_card_id := PC, turn_id := Tn} = Data) ->
    close_port(Data),
    emit(T, PC, <<"turn_completed">>,
         #{<<"plan_card_id">> => PC, <<"turn_id">> => Tn}),
    {stop, normal, Data};
handle_msg(#{<<"method">> := <<"error">>, <<"params">> := P}, Data) ->
    close_port(Data),
    fail(Data, maps:get(<<"code">>, P, <<"sidecar_error">>),
         maps:get(<<"message">>, P, <<"">>)),
    {stop, normal, Data};
handle_msg(_Other, Data) ->
    {keep_state, Data, [{state_timeout, ?TURN_TIMEOUT, port_timeout}]}.

%% --- terminate --------------------------------------------------------------

terminate(_Reason, _State, #{plan_card_id := PC}) ->
    fh_engine_turn_registry:release(PC),
    ok.

%% --- internals --------------------------------------------------------------

emit(Tenant, PlanCardId, Type, Payload) ->
    {ok, EventId} = fh_engine_store:append_event(Tenant, PlanCardId, Type, Payload),
    fh_engine_pubsub:publish(PlanCardId, {EventId, Type, Payload}),
    ok.

fail(#{tenant_id := T, plan_card_id := PC, turn_id := Tn}, Code, Msg) ->
    emit(T, PC, <<"turn_failed">>,
         #{<<"plan_card_id">> => PC, <<"turn_id">> => Tn,
           <<"code">> => Code, <<"message">> => Msg}).

start_port(PlanCardId, Mode) ->
    PythonExe = python_exe(),
    Script = planner_script(),
    Port = open_port({spawn_executable, PythonExe},
                     [{args, [Script]}, {packet, 4}, binary, exit_status]),
    Req = #{<<"method">> => <<"run_base_turn">>,
            <<"params">> => #{<<"plan_card_id">> => PlanCardId, <<"mode">> => Mode}},
    port_command(Port, fh_engine_util:json_encode(Req)),
    Port.

close_port(#{port := Port}) ->
    case erlang:port_info(Port) of
        undefined -> ok;
        _ ->
            try port_close(Port) catch _:_ -> ok end,
            ok
    end.

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
