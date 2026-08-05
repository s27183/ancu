-module(fh_engine_h_conversation).

%% GET /api/engine/plan-cards/:id/conversation — the Q&A thread's persisted history
%% (session_turns, fh_engine_store:read_conversation/3), distinct from the internal
%% read_glue/3 the qa turn uses for prompt coherence. Returns oldest→newest
%% {turns: [{turn_id, user_text, answer:{vi,en}, ts}]}, empty before the first Q&A
%% turn. The shell hydrates Chat.svelte's message list from this on mount, before
%% subscribing to the live /events stream — planCardStream.ts's documented TODO
%% ("a persistent thread is a later backend slice: engine GET conversation + proxy").

-export([init/2]).

init(Req0, State) ->
    case cowboy_req:method(Req0) of
        <<"GET">> -> handle_get(Req0, State);
        _ ->
            {ok, fh_engine_http:reply_json(405,
                #{<<"error">> => <<"method_not_allowed">>}, Req0), State}
    end.

handle_get(Req0, State) ->
    case fh_engine_http:authenticate(Req0) of
        {ok, #{tenant_id := T, user_id := U}} ->
            PlanCardId = cowboy_req:binding(id, Req0),
            case fh_engine_store:get_plan_card(T, PlanCardId) of
                {ok, _Card} ->
                    Turns = fh_engine_store:read_conversation(T, U, PlanCardId),
                    {ok, fh_engine_http:reply_json(200,
                        #{<<"turns">> => Turns}, Req0), State};
                {error, not_found} ->
                    {ok, fh_engine_http:reply_json(404,
                        #{<<"error">> => <<"not_found">>}, Req0), State}
            end;
        {error, Status, Body} ->
            {ok, fh_engine_http:reply_json(Status, Body, Req0), State}
    end.
