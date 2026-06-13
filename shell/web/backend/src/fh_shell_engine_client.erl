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

-export([create_plan_card/2]).

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
