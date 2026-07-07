-module(fh_shell_http).

%% The shell backend's HTTP gateway (:8081). cowboy listener embedded under
%% fh_shell_sup via ranch:child_spec (no standalone cowboy:start), exactly like the
%% engine's fh_engine_http. This module owns listener setup, routing, and the shared
%% request helpers (JSON reply + body read); handlers stay thin.
%%
%% 8-S0 surfaces only /health — the identity routes (/api/auth/*, /api/me), the
%% engine proxy (/api/plan-cards*, /api/suburbs), and commerce (/api/billing/*) land
%% in 8-S0b..8-S5 per shell-architecture.md §5. The shell backend is a proxy +
%% identity/commerce layer in front of the engine, not a re-implementation.

-export([child_spec/0, port/0, routes/0]).
-export([reply_json/3, read_json_body/1, authenticate_user/1]).

-spec child_spec() -> supervisor:child_spec().
child_spec() ->
    Dispatch = cowboy_router:compile(routes()),
    ranch:child_spec(fh_shell_listener, ranch_tcp,
        #{socket_opts => [{port, port()}], max_connections => 1024},
        cowboy_clear,
        %% reset_idle_timeout_on_send: cowboy's idle_timeout (default 60s) is reset
        %% only on data RECEIVED, not sent, unless this is true (cowboy_http
        %% reset_idle_timeout_on_send, default false). The SSE proxy (fh_shell_h_events,
        %% 8-S4b) streams a long-lived response where the client sends nothing after
        %% the request — only the relayed keepalives flow, outbound. Without this the
        %% stream would be killed at 60s mid-fill; with it each relayed keepalive (15s)
        %% resets the timer, so the connection lives while the engine is producing and
        %% dies 60s after it stops. Harmless to ordinary fast request/response.
        #{env => #{dispatch => Dispatch}, reset_idle_timeout_on_send => true}).

%% Exported so a test can stand up the listener without booting the full app
%% (the app starts the Postgres pool + migrations; routes that don't touch the
%% shell DB — e.g. the public /api/suburbs proxy — are testable without it).
-spec routes() -> cowboy_router:routes().
routes() ->
    [{'_', [
        {"/health", fh_shell_health_handler, []},
        {"/api/suburbs", fh_shell_h_suburbs, []},
        {"/api/plan-cards", fh_shell_h_plan_cards, []},
        {"/api/plan-cards/:id/events", fh_shell_h_events, []},
        {"/api/plan-cards/:id/messages", fh_shell_h_plan_card, [messages]},
        {"/api/plan-cards/:id/simulate", fh_shell_h_plan_card, [simulate]},
        {"/api/plan-cards/:id/refine", fh_shell_h_plan_card, [refine]},
        {"/api/plan-cards/:id/profile", fh_shell_h_plan_card, [profile]},
        {"/api/plan-cards/:id/checklist-status", fh_shell_h_plan_card, [checklist_status]},
        {"/api/plan-cards/:id/news", fh_shell_h_plan_card, [news]},
        %% Phase-B per-property surface (Mode-C shell, Slice 1) — attach a property
        %% (→ an addendum + an AGENT turn, engine-contract §12) and submit its
        %% transaction dates (→ a resolver-only re-fill, §11). Both more specific than
        %% the bare `/:id`, so they precede it (cowboy matches in order).
        {"/api/plan-cards/:id/properties", fh_shell_h_plan_card, [properties]},
        {"/api/plan-cards/:id/properties/:pid/transaction", fh_shell_h_plan_card, [transaction]},
        %% due_diligence B (the `<from_document>` surface) — upload the lease for an attached
        %% property (→ a document-gated two-path re-fill, a metered LLM turn). More specific
        %% than the bare `/:id`, so it precedes it (cowboy matches in order).
        {"/api/plan-cards/:id/properties/:pid/documents", fh_shell_h_plan_card, [documents]},
        {"/api/plan-cards/:id", fh_shell_h_plan_card, []},
        %% Login flow (8-S login slice) — one handler, action per route opt.
        {"/api/auth/magic", fh_shell_h_auth, [magic_request]},
        {"/api/auth/magic/verify", fh_shell_h_auth, [magic_verify]},
        {"/api/auth/logout", fh_shell_h_auth, [logout]},
        {"/api/auth/google", fh_shell_h_auth, [google_start]},
        {"/api/auth/google/callback", fh_shell_h_auth, [google_callback]},
        {"/api/me", fh_shell_h_me, []},
        %% Commerce (8-S5e/8-S5f, billing.md §9). The webhook is Stripe-signed, not
        %% user-authenticated; subscribe (8-S5e-3) and charge (8-S5f) act on the
        %% caller's account.
        {"/api/billing/webhook", fh_shell_h_billing, [webhook]},
        {"/api/billing/subscribe", fh_shell_h_billing, [subscribe]},
        {"/api/billing/charge", fh_shell_h_billing, [charge]}
    ]}].

-spec port() -> inet:port_number().
port() ->
    case os:getenv("FH_SHELL_HTTP_PORT") of
        false -> 8081;
        P -> list_to_integer(P)
    end.

%% --- request helpers shared by handlers ------------------------------------

-spec reply_json(cowboy:http_status(), map(), cowboy_req:req()) -> cowboy_req:req().
reply_json(Status, Body, Req) ->
    cowboy_req:reply(Status,
        #{<<"content-type">> => <<"application/json">>},
        fh_shell_util:json_encode(Body), Req).

-spec read_json_body(cowboy_req:req()) -> {ok, map(), cowboy_req:req()} | {error, term()}.
read_json_body(Req0) ->
    {ok, Bin, Req1} = read_all(Req0, <<>>),
    case Bin of
        <<>> -> {ok, #{}, Req1};
        _ ->
            try {ok, fh_shell_util:json_decode(Bin), Req1}
            catch _:_ -> {error, invalid_json}
            end
    end.

read_all(Req0, Acc) ->
    case cowboy_req:read_body(Req0) of
        {ok, Data, Req1} -> {ok, <<Acc/binary, Data/binary>>, Req1};
        {more, Data, Req1} -> read_all(Req1, <<Acc/binary, Data/binary>>)
    end.

%% Validate the USER JWT (HS256, shell-architecture.md §3 — the browser<->shell
%% token, distinct from the ed25519 tenant JWT the shell mints for the engine).
%% Returns the validated claims or a ready-to-send {error, 401, BodyMap}. A failed
%% or absent token is uniformly 401 (re-login) — unlike the engine's 401/403 split,
%% a user session token has no "registered but wrong" case. The login flow sets the
%% token as the httpOnly `fh_session` cookie (fh_shell_h_auth), so the browser sends
%% it automatically; an explicit Authorization: Bearer is also accepted (programmatic
%% callers + tests). Cookie is preferred — it is the credential the SPA actually uses.
-spec authenticate_user(cowboy_req:req()) -> {ok, map()} | {error, 401, map()}.
authenticate_user(Req) ->
    case session_token(Req) of
        undefined ->
            {error, 401, #{<<"error">> => <<"missing_authorization">>}};
        Token ->
            case fh_shell_jwt:verify(Token) of
                {ok, Claims} -> {ok, Claims};
                {error, _Reason} ->
                    {error, 401, #{<<"error">> => <<"invalid_token">>}}
            end
    end.

-spec session_token(cowboy_req:req()) -> binary() | undefined.
session_token(Req) ->
    case bearer_token(Req) of
        undefined -> session_cookie(Req);
        Token -> Token
    end.

-spec bearer_token(cowboy_req:req()) -> binary() | undefined.
bearer_token(Req) ->
    case cowboy_req:header(<<"authorization">>, Req, undefined) of
        undefined -> undefined;
        Header ->
            case binary:split(Header, <<" ">>) of
                [<<"Bearer">>, Token] -> Token;
                _ -> undefined
            end
    end.

-spec session_cookie(cowboy_req:req()) -> binary() | undefined.
session_cookie(Req) ->
    case proplists:get_value(<<"fh_session">>, cowboy_req:parse_cookies(Req)) of
        <<>> -> undefined;
        Val -> Val
    end.
