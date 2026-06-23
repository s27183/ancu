-module(fh_engine_h_checklist_status).

%% PATCH /api/engine/plan-cards/:id/checklist-status — toggle one phase action's
%% status in the card user-set layer (lifecycle-simulation-model.md §7,
%% structure-map.md Plane 4). Body:
%%   {"phase": "contract", "action_id": "pay_deposit", "status": "done"|"not_started"}
%%
%% This is USER-ATTESTED state, not a computed figure: it writes the second slice of
%% the card user-set tier (plan_cards.checklist_status_jsonb, 005), a sparse
%% {"<phase>": {"<action_id>": "done"}} map. A toggle is a small jsonb patch with NO
%% recompute and NO `usage` (engine meters work; this is zero-cost attestation). The
%% audit trail + live SSE fan-out is the `checklist_status_changed` plan_card_events
%% row appended here — the generic SSE layer (fh_engine_h_events) streams any
%% non-terminal type, so other open tabs see the toggle with no streaming change.
%%
%% Tenant-scoped exactly like /refine: get_plan_card(T, Id) confirms ownership before
%% any write. Validation is fail-closed on the closed enums (phase, status); action_id
%% is stored as given — an id the latest phase_playbook recompute doesn't name is
%% harmless (the client overlays status onto the CURRENT actions and ignores orphans,
%% honest-partial). Tightening action_id against the artifact lands with the
%% fh_engine_phase_playbook resolver that owns the canonical action list.

-export([init/2]).

%% The canonical legal/temporal phase enum (fh_engine_journey:phases/0), incl. the terminal
%% `dispose` (lifecycle-simulation-model §8.1) — so a dispose-phase action can be toggled.
-define(PHASES, [<<"prepare">>, <<"pre_approve">>, <<"contract">>, <<"settle">>, <<"own">>,
                 <<"dispose">>]).
-define(STATUSES, [<<"done">>, <<"not_started">>]).

init(Req0, State) ->
    case cowboy_req:method(Req0) of
        <<"PATCH">> -> handle_patch(Req0, State);
        _ ->
            {ok, fh_engine_http:reply_json(405,
                #{<<"error">> => <<"method_not_allowed">>}, Req0), State}
    end.

handle_patch(Req0, State) ->
    case fh_engine_http:authenticate(Req0) of
        {ok, #{tenant_id := T}} ->
            Id = cowboy_req:binding(id, Req0),
            %% Tenant-scope: confirm ownership before any write.
            case fh_engine_store:get_plan_card(T, Id) of
                {ok, _Card} -> read_and_apply(T, Id, Req0, State);
                {error, not_found} ->
                    {ok, fh_engine_http:reply_json(404,
                        #{<<"error">> => <<"not_found">>}, Req0), State}
            end;
        {error, Status, Body} ->
            {ok, fh_engine_http:reply_json(Status, Body, Req0), State}
    end.

read_and_apply(T, Id, Req0, State) ->
    case fh_engine_http:read_json_body(Req0) of
        {ok, Body, Req1} -> validate_and_apply(T, Id, Body, Req1, State);
        {error, invalid_json} ->
            {ok, fh_engine_http:reply_json(400,
                #{<<"error">> => <<"invalid_json">>}, Req0), State}
    end.

validate_and_apply(T, Id, Body, Req, State) ->
    Phase    = maps:get(<<"phase">>, Body, undefined),
    ActionId = maps:get(<<"action_id">>, Body, undefined),
    Status   = maps:get(<<"status">>, Body, undefined),
    case validate(Phase, ActionId, Status) of
        ok ->
            {ok, Map} = fh_engine_store:set_checklist_status(Id, Phase, ActionId, Status),
            emit(T, Id, Phase, ActionId, Status),
            {ok, fh_engine_http:reply_json(200,
                #{<<"plan_card_id">> => Id, <<"checklist_status">> => Map}, Req), State};
        {error, Field} ->
            {ok, fh_engine_http:reply_json(400,
                #{<<"error">> => <<"invalid_field">>, <<"field">> => Field}, Req), State}
    end.

validate(Phase, _ActionId, _Status) when not (is_binary(Phase)) ->
    {error, <<"phase">>};
validate(Phase, ActionId, Status) ->
    case lists:member(Phase, ?PHASES) of
        false -> {error, <<"phase">>};
        true ->
            case is_binary(ActionId) andalso ActionId =/= <<>> of
                false -> {error, <<"action_id">>};
                true ->
                    case lists:member(Status, ?STATUSES) of
                        false -> {error, <<"status">>};
                        true  -> ok
                    end
            end
    end.

%% Append the audit row + fan it out to live SSE subscribers (the canonical
%% fh_engine_turn:emit/4 pattern: append_event is the SOT, publish is the live push).
emit(Tenant, PlanCardId, Phase, ActionId, Status) ->
    Payload = #{<<"plan_card_id">> => PlanCardId, <<"phase">> => Phase,
                <<"action_id">> => ActionId, <<"status">> => Status},
    {ok, EventId} = fh_engine_store:append_event(
        Tenant, PlanCardId, <<"checklist_status_changed">>, Payload),
    fh_engine_pubsub:publish(PlanCardId, {EventId, <<"checklist_status_changed">>, Payload}),
    ok.
