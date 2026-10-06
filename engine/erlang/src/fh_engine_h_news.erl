-module(fh_engine_h_news).

%% GET   /api/engine/plan-cards/:id/news — news notes relevant to this card,
%% minus ones the user already dismissed.
%% PATCH /api/engine/plan-cards/:id/news  body {"news_slug": "kb.news...."} —
%% mark one news note dismissed.
%%
%% "Relevant" = a compiled news note (docs/kb/news/*.md, kb-update-runbook.md
%% "authoring a news note") whose affected_kb_slugs intersects the KB slugs
%% this card has actually consulted across its fills (audit_events.kb_versions_jsonb,
%% plan-card-refresh.md provenance) — a lookup over already-recorded data, no new
%% capture mechanism. Dismissed state is USER-ATTESTED (007, the card user-set
%% layer, same tier as checklist_status) — never folded into content_jsonb.
%%
%% Tenant-scoped exactly like /checklist-status: get_news_status/2 confirms
%% ownership (and doubles as the dismissed-map read) before anything else runs.

-export([init/2]).

init(Req0, State) ->
    case cowboy_req:method(Req0) of
        <<"GET">>   -> handle_get(Req0, State);
        <<"PATCH">> -> handle_patch(Req0, State);
        _ ->
            {ok, fh_engine_http:reply_json(405,
                #{<<"error">> => <<"method_not_allowed">>}, Req0), State}
    end.

handle_get(Req0, State) ->
    with_owned_card(Req0, State, fun(T, Id, Dismissed, Req) ->
        Slugs = fh_engine_store:card_kb_slugs(Id),
        Items = fh_engine_kb:news_for_slugs(Slugs),
        Relevant = [I || I <- Items,
                          not maps:get(maps:get(<<"news_slug">>, I), Dismissed, false)],
        _ = T,
        {ok, fh_engine_http:reply_json(200,
            #{<<"plan_card_id">> => Id, <<"news">> => Relevant}, Req), State}
    end).

handle_patch(Req0, State) ->
    with_owned_card(Req0, State, fun(T, Id, _Dismissed, Req) ->
        read_and_dismiss(T, Id, Req, State)
    end).

read_and_dismiss(T, Id, Req0, State) ->
    case fh_engine_http:read_json_body(Req0) of
        {ok, Body, Req1} -> validate_and_dismiss(T, Id, Body, Req1, State);
        {error, invalid_json} ->
            {ok, fh_engine_http:reply_json(400,
                #{<<"error">> => <<"invalid_json">>}, Req0), State}
    end.

validate_and_dismiss(T, Id, Body, Req, State) ->
    case maps:get(<<"news_slug">>, Body, undefined) of
        NewsSlug when is_binary(NewsSlug), NewsSlug =/= <<>> ->
            {ok, Dismissed} = fh_engine_store:dismiss_news(Id, NewsSlug),
            emit_dismissed(T, Id, NewsSlug),
            {ok, fh_engine_http:reply_json(200,
                #{<<"plan_card_id">> => Id, <<"dismissed_news">> => Dismissed}, Req), State};
        _ ->
            {ok, fh_engine_http:reply_json(400,
                #{<<"error">> => <<"invalid_field">>, <<"field">> => <<"news_slug">>}, Req), State}
    end.

%% Shared ownership gate: authenticate, then confirm the card belongs to this
%% tenant via the same query that reads dismissed_news_jsonb (one round trip,
%% mirrors get_checklist_status/2's combined ownership+read).
with_owned_card(Req0, State, Fun) ->
    case fh_engine_http:authenticate(Req0) of
        {ok, #{tenant_id := T}} ->
            Id = cowboy_req:binding(id, Req0),
            case fh_engine_store:get_news_status(T, Id) of
                {ok, Dismissed} -> Fun(T, Id, Dismissed, Req0);
                {error, not_found} ->
                    {ok, fh_engine_http:reply_json(404,
                        #{<<"error">> => <<"not_found">>}, Req0), State}
            end;
        {error, Status, Body} ->
            {ok, fh_engine_http:reply_json(Status, Body, Req0), State}
    end.

%% Audit trail + live fan-out, the same append_event/publish pattern as
%% checklist-status — so an open PlanProjection in another tab hides the note too.
emit_dismissed(TenantId, PlanCardId, NewsSlug) ->
    Payload = #{<<"plan_card_id">> => PlanCardId, <<"news_slug">> => NewsSlug},
    {ok, EventId} = fh_engine_store:append_event(
        TenantId, PlanCardId, <<"news_dismissed">>, Payload),
    fh_engine_pubsub:publish(PlanCardId, {EventId, <<"news_dismissed">>, Payload}),
    ok.
