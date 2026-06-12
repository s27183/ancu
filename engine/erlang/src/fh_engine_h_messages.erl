-module(fh_engine_h_messages).

%% POST /api/engine/plan-cards/:id/messages — append a user message to the plan
%% card's Q&A thread and run a conversational (Q&A) turn over the *filled* card
%% (engine-contract §4 `user_input_required` resolution; agentic-flow.md §4 — one
%% thread per plan card, re-grounded each turn). Returns {plan_card_id, turn_id};
%% events (tool_use/tool_result/text_delta/usage + terminal) stream from .../events.
%%
%% A Q&A turn is a `kind: qa` turn — distinct from the base/onboarding turn (a DAG
%% walk). It respects the same serialization invariant (one in-flight turn per plan
%% card, fh_engine_turn_registry): a message arriving while a turn runs is 409. The
%% turn body (re-grounding, the KB-lookup sidecar, buffer-then-gate) lands in 2c-3;
%% 2c-1 wires the endpoint + the turn-start + the FSM `kind` branch.

-export([init/2]).

init(Req0, State) ->
    case cowboy_req:method(Req0) of
        <<"POST">> -> handle_post(Req0, State);
        _ ->
            {ok, fh_engine_http:reply_json(405,
                #{<<"error">> => <<"method_not_allowed">>}, Req0), State}
    end.

handle_post(Req0, State) ->
    case fh_engine_http:authenticate(Req0) of
        {ok, #{tenant_id := T, user_id := U}} ->
            PlanCardId = cowboy_req:binding(id, Req0),
            case fh_engine_store:get_plan_card(T, PlanCardId) of
                {ok, Card} -> read_and_start(T, U, PlanCardId, Card, Req0, State);
                {error, not_found} ->
                    {ok, fh_engine_http:reply_json(404,
                        #{<<"error">> => <<"not_found">>}, Req0), State}
            end;
        {error, Status, Body} ->
            {ok, fh_engine_http:reply_json(Status, Body, Req0), State}
    end.

read_and_start(T, U, PlanCardId, Card, Req0, State) ->
    case fh_engine_http:read_json_body(Req0) of
        {ok, Body, Req1} -> start_qa(T, U, PlanCardId, Card, Body, Req1, State);
        {error, invalid_json} ->
            {ok, fh_engine_http:reply_json(400,
                #{<<"error">> => <<"invalid_json">>}, Req0), State}
    end.

start_qa(T, U, PlanCardId, Card, Body, Req, State) ->
    case message_of(Body) of
        <<>> ->
            {ok, fh_engine_http:reply_json(400,
                #{<<"error">> => <<"empty_message">>}, Req), State};
        Message ->
            TurnId = fh_engine_util:uuid4(),
            case fh_engine_turn_registry:reserve(PlanCardId, TurnId) of
                ok ->
                    Mode = maps:get(<<"mode">>, Card, <<"A">>),
                    {ok, _Pid} = fh_engine_turn_sup:start_turn(#{
                        tenant_id => T,
                        user_id => U,
                        plan_card_id => PlanCardId,
                        turn_id => TurnId,
                        kind => qa,
                        mode => Mode,
                        intent => maps:get(<<"intent">>, Card, <<"owner_occupier">>),
                        firb_required_any => firb_required_any(Mode),
                        %% The filled card is the Q&A grounding (constraint #9 — the
                        %% agent grounds in current state, not history); re-injected
                        %% fresh each turn. 2c-3 reads it.
                        card => maps:get(<<"content">>, Card, #{}),
                        message => Message,
                        %% Bilingual-always: the engine emits {vi,en} and the shell
                        %% picks display, so no locale is required (Fork 1). A locale
                        %% hint, if a shell sends one, is carried but not load-bearing.
                        locale => maps:get(<<"locale">>, Body, undefined)
                    }),
                    Resp = #{<<"plan_card_id">> => PlanCardId, <<"turn_id">> => TurnId},
                    {ok, fh_engine_http:reply_json(202, Resp, Req), State};
                {error, in_flight} ->
                    %% Serialization invariant: at most one in-flight turn per card.
                    {ok, fh_engine_http:reply_json(409,
                        #{<<"error">> => <<"turn_in_flight">>}, Req), State}
            end
    end.

message_of(Body) ->
    case maps:get(<<"message">>, Body, <<>>) of
        M when is_binary(M) -> M;
        _ -> <<>>
    end.

%% Mode A/C are domestic (no foreign applicant); B/D carry a foreign person. The
%% Q&A turn passes this to the compliance pipeline exactly as the base turn does.
firb_required_any(<<"B">>) -> true;
firb_required_any(<<"D">>) -> true;
firb_required_any(_)       -> false.
