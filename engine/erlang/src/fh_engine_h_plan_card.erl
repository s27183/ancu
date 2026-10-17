-module(fh_engine_h_plan_card).

%% GET /api/engine/plan-cards/:id — fetch the raw filled plan-card state (base +
%% addenda) for the owning tenant (engine-contract §2.1 plan-card primitives). The
%% engine returns typed outcomes; the shell projects to pixels (§1 invariant).
%% DELETE /api/engine/plan-cards/:id — remove the tenant's card (and its profile once
%% it has no other card): 204, or 404 for a card the tenant does not own. A running
%% turn is cancelled first. The shell's guest purge is the caller (behavior 45,
%% fh_engine_store:delete_plan_card/2).

-export([init/2]).
-export([card_state/1]).  % the list line's state (fh_engine_h_plan_cards)

init(Req0, State) ->
    case cowboy_req:method(Req0) of
        <<"GET">> -> handle_get(Req0, State);
        <<"DELETE">> -> handle_delete(Req0, State);
        _ ->
            {ok, fh_engine_http:reply_json(405,
                #{<<"error">> => <<"method_not_allowed">>}, Req0), State}
    end.

%% Whole lifecycle -> one computer per figure -> The engine -> a card served as a fill writes it today
%% Purpose:   behavior 110 (prod 2026-10-17): a card saved before a change to its budget read
%%            "—" on the statement and hub, beside a new card's full figures.
%% Holds:     the content served is fh_engine_journey:current/2 of the stored one: a stale
%%            lifecycle_budget refilled from the card's own outcomes, every other field as
%%            stored; nothing is written back, so the SSE replay of the stored log is unchanged.
%% Rests on:  the plan list reads through the same function (fh_engine_store:plan_card_summaries/2),
%%            so a list card equals the statement it opens.
%% Whole lifecycle -> honesty tiers -> The engine -> a served journey cites today's sources
%% Goal: behavior 114 — every step of a card's Hành trình shows its rule's source, a card
%%   filled before the steps carried one too.
%% Invariant: each step's grounding is fh_engine_phase_playbook:ground/3 for the plan's own
%%   state (its profile's onboarding, as a fill reads it), recomputed from today's KB on
%%   every read and never written back; a card whose state cannot be read is served as stored.
%% Capability: grounded/3, the content with its playbook steps grounded.
grounded(PlanCardId, Slug, Content) ->
    try
        State = case fh_engine_store:get_card_rerun_context(PlanCardId) of
                    {ok, #{facts := Facts}} ->
                        fh_engine_store:projection_state(maps:get(<<"onboarding">>, Facts, #{}));
                    _ -> undefined
                end,
        fh_engine_phase_playbook:ground(Slug, State, Content)
    catch C:W ->
        logger:warning("[plan_card] grounding ~s failed: ~p:~p", [PlanCardId, C, W]),
        Content
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
                    %% behavior 110: a card stored before the budget changed is served
                    %% with the budget a fill writes today (fh_engine_journey:current/2)
                    Slug = maps:get(<<"blueprint_slug">>, Card),
                    Content = grounded(PlanCardId, Slug,
                                       fh_engine_journey:current(Slug, maps:get(<<"content">>, Card))),
                    Body = Card#{<<"content">> => Content,
                                 <<"event_cursor">> => Cursor,
                                 <<"turn_running">> => Running,
                                 <<"ui_tabs">> => UiTabs,
                                 <<"state">> => card_state(PlanCardId)},
                    {ok, fh_engine_http:reply_json(200, Body, Req0), State};
                {error, not_found} ->
                    {ok, fh_engine_http:reply_json(404,
                        #{<<"error">> => <<"not_found">>}, Req0), State}
            end;
        {error, Status, Body} ->
            {ok, fh_engine_http:reply_json(Status, Body, Req0), State}
    end.

%% Whole lifecycle -> The engine -> the card names its state
%% Behavior 81: the planner page opens a plan without a suburb, so it cannot take the
%% state from a picked suburb as the map's sheet did; the plan's own state is the one the
%% fills used — projection_state/1 of the onboarding, the saved scenario's when there is
%% one (get_card_rerun_context/1 overlays it). null when it resolves to none (ALL scope
%% with no suburb), and the page then lets the visitor pick.
card_state(PlanCardId) ->
    case fh_engine_store:get_card_rerun_context(PlanCardId) of
        {ok, #{facts := Facts}} ->
            case fh_engine_store:projection_state(maps:get(<<"onboarding">>, Facts, #{})) of
                undefined -> null;
                S -> S
            end;
        _ -> null
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
