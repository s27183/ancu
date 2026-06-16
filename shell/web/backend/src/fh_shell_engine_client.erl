-module(fh_shell_engine_client).

%% Calls the engine's /api/engine/* surface with a freshly minted tenant JWT
%% (shell-architecture.md §5 — the shell backend is a proxy + identity/commerce
%% layer in front of the engine, not a re-implementation). Per request: mint a
%% short-lived ed25519 tenant JWT (fh_shell_engine_jwt) scoped to the acting user,
%% attach it as Bearer, forward. The frontend never holds a tenant JWT and never
%% talks to the engine directly (§1).
%%
%% 8-S0 surfaces create_plan_card/2 (the seam's positive path). The full proxy set
%% (fetch state, SSE event proxy, messages, suburbs) lands as the shell UX surfaces
%% are built (8-S1..8-S4). HTTP via inets httpc (started by the shell app).

-export([create_plan_card/2, get_plan_card/2, post_message/3, stream_events/3,
         list_suburbs/1, get_usage_events/2]).

%% The system principal for unauthenticated reference-data reads. `suburbs` is
%% global CC-BY reference data; the map is the pre-login landing surface, so the
%% read carries no user. The engine authenticates the TENANT JWT but does not
%% scope suburbs by tenant or user (fh_engine_h_suburbs), so a nil user_id is a
%% faithful "no acting user" claim, not a spoof of a real one.
-define(ANON_USER_ID, <<"00000000-0000-0000-0000-000000000000">>).

-spec base_url() -> string().
base_url() ->
    case os:getenv("ENGINE_BASE_URL") of
        false -> "http://localhost:8080/api/engine";
        Url   -> Url
    end.

%% Create a plan card (plan-first: the onboarding payload, no property) on behalf of
%% UserId. Returns {StatusCode, ResponseBodyBinary}; the engine answers 202 with
%% {plan_card_id, turn_id} (the base turn runs async, streamed over SSE).
-spec create_plan_card(binary(), map()) -> {non_neg_integer(), binary()}.
create_plan_card(UserId, BodyMap) ->
    Token = fh_shell_engine_jwt:mint(#{user_id => UserId}),
    Url = base_url() ++ "/plan-cards",
    Headers = [{"authorization", "Bearer " ++ binary_to_list(Token)}],
    Body = fh_shell_util:json_encode(BodyMap),
    {ok, {{_, Status, _}, _, Resp}} =
        httpc:request(post, {Url, Headers, "application/json", Body},
                      [], [{body_format, binary}]),
    {Status, Resp}.

%% Fetch a plan card's filled content on behalf of UserId — the projection's data
%% source (8-S4, GET /api/engine/plan-cards/:id). The shell has already confirmed the
%% user owns this card (fh_shell_store:owns_plan_card/2) before calling. Returns
%% {StatusCode, ResponseBodyBinary}: the engine answers 200 with the typed outcomes
%% (content.components.*), 404 if the card is unknown to the tenant. Relayed verbatim.
-spec get_plan_card(binary(), binary()) -> {non_neg_integer(), binary()}.
get_plan_card(UserId, PlanCardId) ->
    Token = fh_shell_engine_jwt:mint(#{user_id => UserId}),
    Url = base_url() ++ "/plan-cards/" ++ binary_to_list(PlanCardId),
    Headers = [{"authorization", "Bearer " ++ binary_to_list(Token)}],
    {ok, {{_, Status, _}, _, Resp}} =
        httpc:request(get, {Url, Headers}, [], [{body_format, binary}]),
    {Status, Resp}.

%% Ask a question about a plan card (the Q&A path, 8-S4) — POST
%% /api/engine/plan-cards/:id/messages with the user's message. The shell has
%% confirmed ownership first. The engine starts a kind:qa turn and answers 202 with
%% {plan_card_id, turn_id}; the bilingual answer arrives later as text_delta frames on
%% the SSE stream (proxied in 8-S4b). 409 if a turn is already in flight (one per card).
-spec post_message(binary(), binary(), map()) -> {non_neg_integer(), binary()}.
post_message(UserId, PlanCardId, BodyMap) ->
    Token = fh_shell_engine_jwt:mint(#{user_id => UserId}),
    Url = base_url() ++ "/plan-cards/" ++ binary_to_list(PlanCardId) ++ "/messages",
    Headers = [{"authorization", "Bearer " ++ binary_to_list(Token)}],
    Body = fh_shell_util:json_encode(BodyMap),
    {ok, {{_, Status, _}, _, Resp}} =
        httpc:request(post, {Url, Headers, "application/json", Body},
                      [], [{body_format, binary}]),
    {Status, Resp}.

%% Open an async-streaming GET on the engine's SSE events endpoint (8-S4b) on behalf
%% of UserId — the channel both the live projection-fill and the Q&A answers ride.
%% MUST be called from the cowboy handler process: httpc with {stream, self} sends the
%% stream parts ({http, {ReqId, stream_start|stream|stream_end, _}}) to the CALLING
%% process, which is the process that relays them downstream (fh_shell_h_events).
%% Returns {ok, RequestId} | {error, Reason}. `timeout` is infinity (an SSE stream is
%% long-lived — the engine's terminal event or its 30-min inactivity guard ends it,
%% or the client disconnects); connect_timeout is finite so a dead engine fails fast.
%% LastEventId (the downstream client's, header-or-query) is forwarded so the ENGINE
%% owns replay/dedup (one source of truth, engine-contract §4).
-spec stream_events(binary(), binary(), binary() | undefined) ->
    {ok, term()} | {error, term()}.
stream_events(UserId, PlanCardId, LastEventId) ->
    Token = fh_shell_engine_jwt:mint(#{user_id => UserId}),
    Url = base_url() ++ "/plan-cards/" ++ binary_to_list(PlanCardId) ++ "/events",
    Headers = [{"authorization", "Bearer " ++ binary_to_list(Token)}
               | last_event_id_header(LastEventId)],
    httpc:request(get, {Url, Headers},
                  [{timeout, infinity}, {connect_timeout, 5000}],
                  [{sync, false}, {stream, self}, {body_format, binary}]).

-spec last_event_id_header(binary() | undefined) -> [{string(), string()}].
last_event_id_header(undefined) -> [];
last_event_id_header(Id) when is_binary(Id) ->
    [{"last-event-id", binary_to_list(Id)}].

%% Proxy GET /api/engine/suburbs?state=State — the map's raw-metric source (8-S1,
%% suburb-data-foundation §2). State is the engine's required query grain; `undefined`
%% forwards no param so the engine answers its own 400 missing_state (one source of
%% truth for valid states). Returns {StatusCode, ResponseBodyBinary} relayed verbatim:
%% the shell is a proxy, not a re-validator, for this read-only reference surface.
-spec list_suburbs(binary() | undefined) -> {non_neg_integer(), binary()}.
list_suburbs(State) ->
    Token = fh_shell_engine_jwt:mint(#{user_id => ?ANON_USER_ID}),
    Url = base_url() ++ "/suburbs" ++ state_query(State),
    Headers = [{"authorization", "Bearer " ++ binary_to_list(Token)}],
    {ok, {{_, Status, _}, _, Resp}} =
        httpc:request(get, {Url, Headers}, [], [{body_format, binary}]),
    {Status, Resp}.

-spec state_query(binary() | undefined) -> string().
state_query(undefined) -> "";
state_query(State) when is_binary(State) ->
    "?" ++ uri_string:compose_query([{<<"state">>, State}]).

%% Poll the engine's pull-model usage outbox (billing.md §2) for THIS tenant's usage
%% events with event_id > After, capped at Limit. Tenant-wide, not user-scoped: the
%% endpoint authorizes on the tenant JWT and ignores user_id, so mint with the system
%% principal (the nil-uuid, same faithful "no acting user" as list_suburbs — the usage
%% mirror is a tenant-level concern, not a user request). Returns the decoded envelope
%% {ok, #{<<"events">> := [...], <<"cursor">> := Int, <<"count">> := Int}} on 200, or
%% {error, Reason} on a non-200 / transport failure (the consumer logs + retries).
-spec get_usage_events(integer(), pos_integer()) -> {ok, map()} | {error, term()}.
get_usage_events(After, Limit) ->
    Token = fh_shell_engine_jwt:mint(#{user_id => ?ANON_USER_ID}),
    Query = uri_string:compose_query([{<<"after">>, integer_to_binary(After)},
                                      {<<"limit">>, integer_to_binary(Limit)}]),
    Url = base_url() ++ "/usage_events?" ++ Query,
    Headers = [{"authorization", "Bearer " ++ binary_to_list(Token)}],
    case httpc:request(get, {Url, Headers},
                       [{connect_timeout, 5000}], [{body_format, binary}]) of
        {ok, {{_, 200, _}, _, Body}} ->
            {ok, fh_shell_util:json_decode(Body)};
        {ok, {{_, Status, _}, _, Body}} ->
            {error, {http, Status, Body}};
        {error, Reason} ->
            {error, Reason}
    end.
