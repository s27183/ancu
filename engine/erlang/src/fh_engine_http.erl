-module(fh_engine_http).

%% The /api/engine/* HTTP/SSE gateway (engine-contract §2.1). cowboy listener
%% embedded under fh_engine_sup via ranch:child_spec (no standalone cowboy:start).
%% This module owns listener setup, routing, and the request helpers (auth + JSON
%% reply + body read) the handler modules share. Handlers stay thin.
%%
%% Slice 1 surfaces the turn-execution + health endpoints; plan-card primitives
%% (fetch state), property attachment, artifact + usage endpoints land later.

-export([child_spec/0, port/0]).
-export([authenticate/1, reply_json/3, read_json_body/1]).

-spec child_spec() -> supervisor:child_spec().
child_spec() ->
    Dispatch = cowboy_router:compile(routes()),
    ranch:child_spec(fh_engine_listener, ranch_tcp,
        #{socket_opts => [{port, port()} | ip_opt()], max_connections => 1024},
        cowboy_clear,
        %% reset_idle_timeout_on_send: without this, cowboy resets idle_timeout
        %% (default 60s) only on data RECEIVED, not sent (cowboy_http
        %% reset_idle_timeout_on_send, default false). The SSE stream
        %% (fh_engine_h_events) keeps a long-lived turn alive with 15s keepalive
        %% comments, but those are OUTBOUND — so without this they don't reset the
        %% timer and the stream is killed at 60s mid-fill (a minutes-long leaf-fill
        %% is silent between events), forcing a client reconnect. This makes the
        %% keepalive design actually do its job. Harmless to fast request/response.
        #{env => #{dispatch => Dispatch}, reset_idle_timeout_on_send => true}).

routes() ->
    [{'_', [
        {"/api/engine/health",                  fh_engine_h_health,     []},
        %% The same probe at the root, as the shell serves it: deployment.md §5 and
        %% behavior 33's Expect check https://<engine ingress>/health.
        {"/health",                             fh_engine_h_health,     []},
        {"/api/engine/dev/tenants",             fh_engine_h_dev_provision, []},
        {"/api/engine/suburbs",                 fh_engine_h_suburbs,    []},
        {"/api/engine/news",                    fh_engine_h_news_feed,  []},
        {"/api/engine/facts",                   fh_engine_h_facts,      []},
        {"/api/engine/usage_events",            fh_engine_h_usage_events, []},
        {"/api/engine/plan-cards",              fh_engine_h_plan_cards, []},
        {"/api/engine/plan-cards/:id/events",   fh_engine_h_events,     []},
        {"/api/engine/plan-cards/:id/messages", fh_engine_h_messages,   []},
        {"/api/engine/plan-cards/:id/conversation", fh_engine_h_conversation, []},
        {"/api/engine/plan-cards/:id/cancel",   fh_engine_h_cancel,     []},
        {"/api/engine/plan-cards/:id/rerun",    fh_engine_h_rerun,      []},
        {"/api/engine/plan-cards/:id/simulate", fh_engine_h_simulate,   []},
        {"/api/engine/plan-cards/:id/refine",   fh_engine_h_refine,     []},
        {"/api/engine/plan-cards/:id/profile",  fh_engine_h_profile,    []},
        {"/api/engine/plan-cards/:id/checklist-status", fh_engine_h_checklist_status, []},
        {"/api/engine/plan-cards/:id/news",     fh_engine_h_news,       []},
        {"/api/engine/plan-cards/:id/properties", fh_engine_h_attach_property, []},
        {"/api/engine/plan-cards/:id/properties/:pid/transaction", fh_engine_h_transaction, []},
        {"/api/engine/plan-cards/:id/properties/:pid/documents", fh_engine_h_attach_document, []},
        {"/api/engine/plan-cards/:id",          fh_engine_h_plan_card,  []}
    ]}].

%% Reproducible -> P-2 · The database is the single source of truth -> The engine -> a loopback-only listener
%% FH_HTTP_IP (e.g. 127.0.0.1) binds the listener to that address; unset, ranch binds every
%% interface as before, so prod is unchanged. scripts/dev_stack.sh sets it: the seat's dev
%% stack runs outside the sandbox and must not serve the LAN (behavior 24, 2026-10-07).
-spec ip_opt() -> [{ip, inet:ip_address()}].
ip_opt() ->
    case os:getenv("FH_HTTP_IP") of
        false -> [];
        ""    -> [];
        S     -> {ok, Ip} = inet:parse_address(S), [{ip, Ip}]
    end.

-spec port() -> inet:port_number().
port() ->
    case os:getenv("FH_ENGINE_HTTP_PORT") of
        false -> 8080;
        P -> list_to_integer(P)
    end.

%% --- request helpers shared by handlers ------------------------------------

%% Validate the Bearer JWT (engine-contract §3). Returns the validated claims or a
%% ready-to-send {error, Status, BodyMap}.
-spec authenticate(cowboy_req:req()) ->
    {ok, map()} | {error, 401 | 403, map()}.
authenticate(Req) ->
    Header = cowboy_req:header(<<"authorization">>, Req, undefined),
    case fh_engine_auth:verify_bearer(Header) of
        {ok, Claims} -> {ok, Claims};
        {error, missing_authorization} ->
            {error, 401, #{<<"error">> => <<"missing_authorization">>}};
        {error, Reason} ->
            {error, 403, #{<<"error">> => <<"invalid_token">>,
                           <<"detail">> => atom_to_binary(Reason, utf8)}}
    end.

-spec reply_json(cowboy:http_status(), map(), cowboy_req:req()) -> cowboy_req:req().
reply_json(Status, Body, Req) ->
    cowboy_req:reply(Status,
        #{<<"content-type">> => <<"application/json">>},
        fh_engine_util:json_encode(Body), Req).

-spec read_json_body(cowboy_req:req()) -> {ok, map(), cowboy_req:req()} | {error, term()}.
read_json_body(Req0) ->
    {ok, Bin, Req1} = read_all(Req0, <<>>),
    case Bin of
        <<>> -> {ok, #{}, Req1};
        _ ->
            try {ok, fh_engine_util:json_decode(Bin), Req1}
            catch _:_ -> {error, invalid_json}
            end
    end.

read_all(Req0, Acc) ->
    case cowboy_req:read_body(Req0) of
        {ok, Data, Req1} -> {ok, <<Acc/binary, Data/binary>>, Req1};
        {more, Data, Req1} -> read_all(Req1, <<Acc/binary, Data/binary>>)
    end.
