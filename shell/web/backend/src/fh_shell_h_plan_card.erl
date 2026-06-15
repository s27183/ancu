-module(fh_shell_h_plan_card).

%% The single plan-card RESOURCE (/api/plan-cards/:id and .../messages, 8-S4) — the
%% projection's data source (GET) + the bilingual Q&A path (POST messages). One
%% handler, action per route opt ([] = read, [messages] = ask), mirroring
%% fh_shell_h_auth. The frontend never talks to the engine directly (§1): this mints
%% the tenant JWT and relays the engine's status + body verbatim, the same proxy
%% posture as fh_shell_h_suburbs — the engine owns the plan-card contract.
%%
%% AUTHORIZATION — the new posture this slice introduces. Unlike the public suburbs
%% proxy or the create seam (no pre-existing row), these touch an EXISTING card, so
%% the acting user must OWN it. Every action runs one gate — authenticate the user
%% JWT, then confirm the (user, card) binding in the shell DB (plan_card_views) —
%% BEFORE minting a tenant JWT. The engine independently scopes by the tenant the JWT
%% names but treats user_id as opaque, so the user→card mapping lives only shell-side
%% (§9.3, no cross-DB join). A malformed / unknown / unowned id is a uniform 404: we
%% never disclose whether a card exists across the ownership boundary.

-export([init/2]).

init(Req0, Opts) ->
    case {Opts, cowboy_req:method(Req0)} of
        {[], <<"GET">>}          -> with_owned_card(Req0, Opts, fun read/4);
        {[messages], <<"POST">>} -> with_owned_card(Req0, Opts, fun ask/4);
        _ ->
            {ok, fh_shell_http:reply_json(405,
                #{<<"error">> => <<"method_not_allowed">>}, Req0), Opts}
    end.

%% The shared gate: authenticate → validate the :id shape → confirm ownership, then
%% hand (UserId, PlanCardId, Req, Opts) to the action. is_uuid guards the $N::uuid
%% bind so a garbage id is a calm 404, not a pgo crash.
with_owned_card(Req0, Opts, Action) ->
    case fh_shell_http:authenticate_user(Req0) of
        {ok, #{<<"user_id">> := UserId}} ->
            PlanCardId = cowboy_req:binding(id, Req0),
            case is_binary(PlanCardId)
                andalso fh_shell_util:is_uuid(PlanCardId)
                andalso fh_shell_store:owns_plan_card(UserId, PlanCardId)
            of
                true ->
                    Action(UserId, PlanCardId, Req0, Opts);
                false ->
                    {ok, fh_shell_http:reply_json(404,
                        #{<<"error">> => <<"not_found">>}, Req0), Opts}
            end;
        {error, Status, ErrBody} ->
            {ok, fh_shell_http:reply_json(Status, ErrBody, Req0), Opts}
    end.

%% GET /api/plan-cards/:id — fetch the filled plan-card content (the projection's
%% typed outcomes). Relayed verbatim from the engine.
read(UserId, PlanCardId, Req0, Opts) ->
    {Status, Body} = fh_shell_engine_client:get_plan_card(UserId, PlanCardId),
    {ok, relay(Status, Body, Req0), Opts}.

%% POST /api/plan-cards/:id/messages — ask a question (the kind:qa turn). The engine
%% owns the message contract (non-empty, in-flight serialization); a bad body relays
%% through. The bilingual answer arrives later as text_delta frames on the SSE stream
%% (proxied in 8-S4b), not in this reply — the engine answers 202 here.
ask(UserId, PlanCardId, Req0, Opts) ->
    case fh_shell_http:read_json_body(Req0) of
        {ok, Body, Req1} ->
            {Status, Resp} = fh_shell_engine_client:post_message(UserId, PlanCardId, Body),
            {ok, relay(Status, Resp, Req1), Opts};
        {error, invalid_json} ->
            {ok, fh_shell_http:reply_json(400,
                #{<<"error">> => <<"invalid_json">>}, Req0), Opts}
    end.

%% Relay the engine's already-encoded JSON body + status verbatim (same as the
%% suburbs proxy) — the engine is the source of truth for the plan-card contract, so
%% the shell does not re-decode/re-encode and cannot drift from it.
relay(Status, Body, Req) ->
    cowboy_req:reply(Status,
        #{<<"content-type">> => <<"application/json">>}, Body, Req).
