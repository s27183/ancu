-module(fh_engine_h_plan_card).

%% GET /api/engine/plan-cards/:id — fetch the raw filled plan-card state (base +
%% addenda) for the owning tenant (engine-contract §2.1 plan-card primitives). The
%% engine returns typed outcomes; the shell projects to pixels (§1 invariant).
%% DELETE /api/engine/plan-cards/:id — remove the tenant's card (and its profile once
%% it has no other card): 204, or 404 for a card the tenant does not own. A running
%% turn is cancelled first. The shell's guest purge is the caller (behavior 45,
%% fh_engine_store:delete_plan_card/2).

-export([init/2]).

init(Req0, State) ->
    case cowboy_req:method(Req0) of
        <<"GET">> -> handle_get(Req0, State);
        <<"DELETE">> -> handle_delete(Req0, State);
        _ ->
            {ok, fh_engine_http:reply_json(405,
                #{<<"error">> => <<"method_not_allowed">>}, Req0), State}
    end.

handle_get(Req0, State) ->
    case fh_engine_http:authenticate(Req0) of
        {ok, #{tenant_id := T}} ->
            PlanCardId = cowboy_req:binding(id, Req0),
            case fh_engine_store:get_plan_card(T, PlanCardId) of
                {ok, Card} ->
                    %% The snapshot's as-of cursor + whether a turn is in flight. The
                    %% shell relays these verbatim; the projection subscribes to the SSE
                    %% with `event_cursor` as Last-Event-ID so the replay can't regress
                    %% the fresh snapshot with an OLD turn from the append-only log, and
                    %% sets its done-state from `turn_running` (no terminal replays when
                    %% the cursor skips the history). See plan-card-refresh.md.
                    Cursor = fh_engine_store:max_event_id(T, PlanCardId),
                    Running = case fh_engine_turn_registry:lookup(PlanCardId) of
                                  {ok, _}            -> true;
                                  {error, not_found} -> false
                              end,
                    %% The blueprint's lifecycle-tab spine (engine-owned structure from
                    %% the artifact) travels with the card so the shell renders tabs, not
                    %% the raw component list (plan-card-lifecycle-restoration.md §5).
                    UiTabs = case fh_engine_kb:ui_tabs(maps:get(<<"blueprint_slug">>, Card)) of
                                 {ok, Tabs} -> Tabs;
                                 _          -> []
                             end,
                    Body = Card#{<<"event_cursor">> => Cursor,
                                 <<"turn_running">> => Running,
                                 <<"ui_tabs">> => UiTabs},
                    {ok, fh_engine_http:reply_json(200, Body, Req0), State};
                {error, not_found} ->
                    {ok, fh_engine_http:reply_json(404,
                        #{<<"error">> => <<"not_found">>}, Req0), State}
            end;
        {error, Status, Body} ->
            {ok, fh_engine_http:reply_json(Status, Body, Req0), State}
    end.

handle_delete(Req0, State) ->
    case fh_engine_http:authenticate(Req0) of
        {ok, #{tenant_id := T}} ->
            PlanCardId = cowboy_req:binding(id, Req0),
            case fh_engine_store:get_plan_card(T, PlanCardId) of
                {ok, _} ->
                    case fh_engine_turn_registry:lookup(PlanCardId) of
                        {ok, #{pid := Pid}} when is_pid(Pid) -> gen_statem:cast(Pid, cancel);
                        _ -> ok
                    end,
                    case fh_engine_store:delete_plan_card(T, PlanCardId) of
                        ok ->
                            logger:info("[plan-card] deleted ~s (tenant ~s)", [PlanCardId, T]),
                            {ok, cowboy_req:reply(204, #{}, <<>>, Req0), State};
                        {error, not_found} -> not_found(Req0, State)
                    end;
                {error, not_found} -> not_found(Req0, State)
            end;
        {error, Status, Body} ->
            {ok, fh_engine_http:reply_json(Status, Body, Req0), State}
    end.

not_found(Req0, State) ->
    {ok, fh_engine_http:reply_json(404, #{<<"error">> => <<"not_found">>}, Req0), State}.
