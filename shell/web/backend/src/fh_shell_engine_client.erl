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

-export([create_plan_card/2, list_suburbs/1]).

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
