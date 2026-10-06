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

-export([create_plan_card/2, get_plan_card/2, post_message/3, get_conversation/2,
         simulate/3,
         refine/3, set_profile_financials/3, set_checklist_status/3,
         attach_property/3, set_transaction_dates/4, upload_document/4, stream_events/3,
         list_suburbs/1, get_usage_events/2, start_httpc_profiles/0,
         get_news/2, dismiss_news/3, list_all_news/0]).

%% Dedicated httpc profile for the LONG-LIVED SSE stream proxy (stream_events/3).
%% SSE requests run with {timeout, infinity} and hold an httpc session for the entire
%% EventSource lifetime. Keeping them on their OWN profile means a never-ending stream
%% can never occupy a slot in the DEFAULT profile's tiny connection pool (max_sessions
%% defaults to 2) and starve the plain request/response calls (get/simulate/refine/
%% create/suburbs/messages) that also run on the default profile — the bug where a
%% single held SSE made plain calls land behind it and hang forever. The streams are
%% isolated from EACH OTHER too: the profile's max_sessions is raised so each concurrent
%% stream gets its own connection rather than queueing behind another (which would just
%% move the same wedge into this profile). EVERY streaming / infinity-timeout request
%% MUST use this profile; plain RPC stays on the default profile.
%% Measured 2026-10-06 (OTP 29.1.1, inets 9.8, at b3-invariant-checks): with this split
%% ablated — streams on `default`, max_sessions 2 — test/sse_isolation_smoke.escript
%% still passes (4 held streams, get_plan_card and list_suburbs 200 in <5 ms). Read in
%% inets 9.8: a session stays `available = false` until its answer is sent
%% (httpc_internal.hrl:157, httpc_handler.erl:1366), so no request queues behind a
%% stream, and past max_sessions httpc_manager.erl:795 opens a `connection: close`
%% handler instead of waiting. So on this OTP the wedge described above does not occur
%% and the split is defence in depth; the smoke guards the outcome either way.
-define(SSE_PROFILE, fh_shell_sse).
-define(SSE_MAX_SESSIONS, 1024).
%% Headroom for concurrent plain RPC on the default profile (the map + plan + chat all
%% proxy at once); each call is sub-second so this is generous, not load-bearing.
-define(RPC_MAX_SESSIONS, 64).
%% A finite bound on every plain request/response call to the engine. All of them are
%% fast — create/refine answer 202 immediately (the turn runs async over SSE), get/
%% simulate are resolver-only reads — so this never truncates a legitimate call; it
%% turns any future pool wedge into a fast error the shell relays, never an infinite
%% browser spinner. The SSE stream legitimately keeps {timeout, infinity}.
-define(RPC_TIMEOUT_MS, 15000).

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

%% Start + configure the httpc profiles this module uses. Called ONCE at boot by
%% fh_shell_app (after inets is up). Idempotent: tolerates an already-started profile
%% so a hot reload / re-run doesn't crash boot. See ?SSE_PROFILE for the why.
-spec start_httpc_profiles() -> ok.
start_httpc_profiles() ->
    case inets:start(httpc, [{profile, ?SSE_PROFILE}]) of
        {ok, _Pid}                    -> ok;
        {error, {already_started, _}} -> ok
    end,
    ok = httpc:set_options([{max_sessions, ?SSE_MAX_SESSIONS}], ?SSE_PROFILE),
    %% Raise the DEFAULT profile (plain RPC) too — no SSE rides it any more, so its
    %% only job is short request/response calls; give them headroom under concurrency.
    ok = httpc:set_options([{max_sessions, ?RPC_MAX_SESSIONS}]),
    ok.

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
                      [{timeout, ?RPC_TIMEOUT_MS}], [{body_format, binary}]),
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
        httpc:request(get, {Url, Headers},
                      [{timeout, ?RPC_TIMEOUT_MS}], [{body_format, binary}]),
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
                      [{timeout, ?RPC_TIMEOUT_MS}], [{body_format, binary}]),
    {Status, Resp}.

%% Fetch the Q&A thread's persisted history — GET
%% /api/engine/plan-cards/:id/conversation. The shell has confirmed ownership first.
%% Returns {StatusCode, ResponseBodyBinary}: 200 with {turns: [...]} (oldest→newest,
%% bilingual answers), empty before the first Q&A turn. Relayed verbatim.
-spec get_conversation(binary(), binary()) -> {non_neg_integer(), binary()}.
get_conversation(UserId, PlanCardId) ->
    Token = fh_shell_engine_jwt:mint(#{user_id => UserId}),
    Url = base_url() ++ "/plan-cards/" ++ binary_to_list(PlanCardId) ++ "/conversation",
    Headers = [{"authorization", "Bearer " ++ binary_to_list(Token)}],
    {ok, {{_, Status, _}, _, Resp}} =
        httpc:request(get, {Url, Headers},
                      [{timeout, ?RPC_TIMEOUT_MS}], [{body_format, binary}]),
    {Status, Resp}.

%% Preview a structural what-if (W9) — POST /api/engine/plan-cards/:id/simulate with
%% {overrides: {target_price|state}}. The shell has confirmed ownership first. The engine
%% recomputes the base plan resolver-only and returns the recomputed outcomes (keyed by
%% component_id, §10.1) in the 200 BODY — a PREVIEW: no persist, no turn, NO usage. So
%% unlike post_message this carries no meter gate (the shell does not gate a zero-cost
%% read; metering-not-gating). 400 on a rejected override (e.g. property_type). Relayed
%% verbatim — the engine owns the simulate contract.
-spec simulate(binary(), binary(), map()) -> {non_neg_integer(), binary()}.
simulate(UserId, PlanCardId, BodyMap) ->
    Token = fh_shell_engine_jwt:mint(#{user_id => UserId}),
    Url = base_url() ++ "/plan-cards/" ++ binary_to_list(PlanCardId) ++ "/simulate",
    Headers = [{"authorization", "Bearer " ++ binary_to_list(Token)}],
    Body = fh_shell_util:json_encode(BodyMap),
    {ok, {{_, Status, _}, _, Resp}} =
        httpc:request(post, {Url, Headers, "application/json", Body},
                      [{timeout, ?RPC_TIMEOUT_MS}], [{body_format, binary}]),
    {Status, Resp}.

%% Save a previewed structural what-if (W8) — POST /api/engine/plan-cards/:id/refine with
%% {overrides: {target_price|state}}, the COMMIT half of simulate (engine-contract §10.2).
%% The shell has confirmed ownership first. The engine persists the override inputs to the
%% plan-target overlay and runs a base_resolver turn that advances the single snapshot,
%% answering 202 {plan_card_id, turn_id}; the recomputed components stream over the SAME
%% /events SSE the live fill rides. Like simulate, this is resolver-only and emits NO usage
%% (the saved scenario re-runs deterministic fills + re-attaches the stored agent leaves —
%% not re-billed), so it carries NO meter gate. 409 if a turn is already in flight (one per
%% card); 400 on a rejected override. Relayed verbatim — the engine owns the refine contract.
-spec refine(binary(), binary(), map()) -> {non_neg_integer(), binary()}.
refine(UserId, PlanCardId, BodyMap) ->
    Token = fh_shell_engine_jwt:mint(#{user_id => UserId}),
    Url = base_url() ++ "/plan-cards/" ++ binary_to_list(PlanCardId) ++ "/refine",
    Headers = [{"authorization", "Bearer " ++ binary_to_list(Token)}],
    Body = fh_shell_util:json_encode(BodyMap),
    {ok, {{_, Status, _}, _, Resp}} =
        httpc:request(post, {Url, Headers, "application/json", Body},
                      [{timeout, ?RPC_TIMEOUT_MS}], [{body_format, binary}]),
    {Status, Resp}.

%% Write the household financial facts (IC4) — POST /api/engine/plan-cards/:id/profile with
%% {household_financials: {income, debts}}. The shell has confirmed ownership first. The
%% engine validates (400 invalid_financials), full-replaces the canonical household_financials
%% key on the profiles SOT, and re-derives every card on the profile (resolver-only, NO usage
%% — so NO meter gate); the recomputed capacity streams over each card's /events. Answers 202
%% {plan_card_id, cards_recomputing}. Relayed verbatim — the engine owns the financials contract.
-spec set_profile_financials(binary(), binary(), map()) -> {non_neg_integer(), binary()}.
set_profile_financials(UserId, PlanCardId, BodyMap) ->
    Token = fh_shell_engine_jwt:mint(#{user_id => UserId}),
    Url = base_url() ++ "/plan-cards/" ++ binary_to_list(PlanCardId) ++ "/profile",
    Headers = [{"authorization", "Bearer " ++ binary_to_list(Token)}],
    Body = fh_shell_util:json_encode(BodyMap),
    {ok, {{_, Status, _}, _, Resp}} =
        httpc:request(post, {Url, Headers, "application/json", Body},
                      [{timeout, ?RPC_TIMEOUT_MS}], [{body_format, binary}]),
    {Status, Resp}.

%% Toggle one phase action's checklist status — PATCH /api/engine/plan-cards/:id/
%% checklist-status with {phase, action_id, status} (the card user-set layer, task 7).
%% The shell has confirmed ownership first. USER-ATTESTED state, not a computed figure:
%% a small jsonb patch, NO recompute and NO usage — so, like simulate/refine, it carries
%% NO meter gate. The engine answers 200 with the AUTHORITATIVE checklist_status map (the
%% acting client renders engine state, not a local guess); 400 on a bad field. Relayed
%% verbatim — the engine owns the user-set contract.
-spec set_checklist_status(binary(), binary(), map()) -> {non_neg_integer(), binary()}.
set_checklist_status(UserId, PlanCardId, BodyMap) ->
    Token = fh_shell_engine_jwt:mint(#{user_id => UserId}),
    Url = base_url() ++ "/plan-cards/" ++ binary_to_list(PlanCardId) ++ "/checklist-status",
    Headers = [{"authorization", "Bearer " ++ binary_to_list(Token)}],
    Body = fh_shell_util:json_encode(BodyMap),
    {ok, {{_, Status, _}, _, Resp}} =
        httpc:request(patch, {Url, Headers, "application/json", Body},
                      [{timeout, ?RPC_TIMEOUT_MS}], [{body_format, binary}]),
    {Status, Resp}.

%% Fetch the KB news notes relevant to a card's consulted KB slugs, minus its own
%% dismissed set — GET /api/engine/plan-cards/:id/news (kb-news-feature.md). The
%% shell has confirmed ownership first. Zero-cost read (no usage, no turn): the
%% engine computes the relevance filter over already-stamped kb_versions
%% provenance, nothing new to compute. Relayed verbatim — the engine owns the
%% news-note contract (bilingual summary, affected_components, sources).
-spec get_news(binary(), binary()) -> {non_neg_integer(), binary()}.
get_news(UserId, PlanCardId) ->
    Token = fh_shell_engine_jwt:mint(#{user_id => UserId}),
    Url = base_url() ++ "/plan-cards/" ++ binary_to_list(PlanCardId) ++ "/news",
    Headers = [{"authorization", "Bearer " ++ binary_to_list(Token)}],
    {ok, {{_, Status, _}, _, Resp}} =
        httpc:request(get, {Url, Headers},
                      [{timeout, ?RPC_TIMEOUT_MS}], [{body_format, binary}]),
    {Status, Resp}.

%% Dismiss one news note — PATCH /api/engine/plan-cards/:id/news with
%% {news_slug}. The shell has confirmed ownership first. USER-ATTESTED state
%% (the card's dismissed_news_jsonb user-set layer, migration 007), not a
%% computed figure: NO usage, so — like checklist-status — NO meter gate. The
%% engine answers 200 with the AUTHORITATIVE dismissed_news map; 400 on a
%% missing news_slug. Relayed verbatim.
-spec dismiss_news(binary(), binary(), map()) -> {non_neg_integer(), binary()}.
dismiss_news(UserId, PlanCardId, BodyMap) ->
    Token = fh_shell_engine_jwt:mint(#{user_id => UserId}),
    Url = base_url() ++ "/plan-cards/" ++ binary_to_list(PlanCardId) ++ "/news",
    Headers = [{"authorization", "Bearer " ++ binary_to_list(Token)}],
    Body = fh_shell_util:json_encode(BodyMap),
    {ok, {{_, Status, _}, _, Resp}} =
        httpc:request(patch, {Url, Headers, "application/json", Body},
                      [{timeout, ?RPC_TIMEOUT_MS}], [{body_format, binary}]),
    {Status, Resp}.

%% Fetch every compiled KB news note, unfiltered — GET /api/engine/news
%% (kb-news-feature.md "Homepage ticker"). PUBLIC, same posture as list_suburbs/1:
%% the anonymous system principal, since this is global KB content and the homepage
%% ticker is pre-login chrome, not a per-buyer read. Relayed verbatim.
-spec list_all_news() -> {non_neg_integer(), binary()}.
list_all_news() ->
    Token = fh_shell_engine_jwt:mint(#{user_id => ?ANON_USER_ID}),
    Url = base_url() ++ "/news",
    Headers = [{"authorization", "Bearer " ++ binary_to_list(Token)}],
    {ok, {{_, Status, _}, _, Resp}} =
        httpc:request(get, {Url, Headers},
                      [{timeout, ?RPC_TIMEOUT_MS}], [{body_format, binary}]),
    {Status, Resp}.

%% Attach a normalized property_card — POST /api/engine/plan-cards/:id/properties (engine-
%% contract §12). The shell has confirmed ownership + the token-limit gate first. The engine
%% generates the property_id, writes the addendum (content.addenda.<pid>), and runs the Phase-B
%% per-property turn — an AGENT turn (property_assessment invokes the LLM, emits usage) — answering
%% 202 {plan_card_id, property_id, turn_id}; the per-property components stream over the SAME
%% /events SSE. 400 invalid_property_card / 400 phase_b_not_supported_for_blueprint (Slice A,
%% investor-only); 409 if a turn is already in flight. Relayed verbatim — the engine owns the
%% property_card contract.
-spec attach_property(binary(), binary(), map()) -> {non_neg_integer(), binary()}.
attach_property(UserId, PlanCardId, BodyMap) ->
    Token = fh_shell_engine_jwt:mint(#{user_id => UserId}),
    Url = base_url() ++ "/plan-cards/" ++ binary_to_list(PlanCardId) ++ "/properties",
    Headers = [{"authorization", "Bearer " ++ binary_to_list(Token)}],
    Body = fh_shell_util:json_encode(BodyMap),
    {ok, {{_, Status, _}, _, Resp}} =
        httpc:request(post, {Url, Headers, "application/json", Body},
                      [{timeout, ?RPC_TIMEOUT_MS}], [{body_format, binary}]),
    {Status, Resp}.

%% Submit the user-attested transaction dates — POST /api/engine/plan-cards/:id/properties/
%% :pid/transaction with {contract_signed_date, settlement_date} (engine-contract §11). The
%% shell has confirmed the user owns the card; the engine re-validates the addendum :pid exists
%% (409 property_not_attached) and the dates (400 with a typed code). A RESOLVER-ONLY re-fill:
%% it activates settlement_prep's dated path, emits NO usage (so the handler runs no meter gate),
%% and answers 202 {plan_card_id, property_id, turn_id}; the recomputed settlement_checklist
%% streams over the SAME /events SSE. Relayed verbatim — the engine owns the transaction contract.
-spec set_transaction_dates(binary(), binary(), binary(), map()) ->
    {non_neg_integer(), binary()}.
set_transaction_dates(UserId, PlanCardId, PropertyId, BodyMap) ->
    Token = fh_shell_engine_jwt:mint(#{user_id => UserId}),
    Url = base_url() ++ "/plan-cards/" ++ binary_to_list(PlanCardId)
          ++ "/properties/" ++ binary_to_list(PropertyId) ++ "/transaction",
    Headers = [{"authorization", "Bearer " ++ binary_to_list(Token)}],
    Body = fh_shell_util:json_encode(BodyMap),
    {ok, {{_, Status, _}, _, Resp}} =
        httpc:request(post, {Url, Headers, "application/json", Body},
                      [{timeout, ?RPC_TIMEOUT_MS}], [{body_format, binary}]),
    {Status, Resp}.

%% Upload a due-diligence DOCUMENT (the current lease) — POST /api/engine/plan-cards/:id/
%% properties/:pid/documents with {content_base64, mime_type?, filename?} (due_diligence B,
%% the `<from_document>` input surface). The shell has confirmed the user owns the card + the
%% token-limit gate first (UNLIKE the free transaction submit, this fires the lease_interpretation
%% leaf — a metered LLM call). The engine re-validates the addendum :pid exists (409
%% property_not_attached) and the document (400 invalid_document with a typed code), runs the
%% DOCUMENT-GATED two-path re-fill of due_diligence, and answers 202 {plan_card_id, property_id,
%% turn_id}; the reviewed risk_assessment_investor streams over the SAME /events SSE. The bytes
%% are transient (never persisted, engine-side). Relayed verbatim — the engine owns the contract.
-spec upload_document(binary(), binary(), binary(), map()) ->
    {non_neg_integer(), binary()}.
upload_document(UserId, PlanCardId, PropertyId, BodyMap) ->
    Token = fh_shell_engine_jwt:mint(#{user_id => UserId}),
    Url = base_url() ++ "/plan-cards/" ++ binary_to_list(PlanCardId)
          ++ "/properties/" ++ binary_to_list(PropertyId) ++ "/documents",
    Headers = [{"authorization", "Bearer " ++ binary_to_list(Token)}],
    Body = fh_shell_util:json_encode(BodyMap),
    {ok, {{_, Status, _}, _, Resp}} =
        httpc:request(post, {Url, Headers, "application/json", Body},
                      [{timeout, ?RPC_TIMEOUT_MS}], [{body_format, binary}]),
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
                  [{sync, false}, {stream, self}, {body_format, binary}],
                  ?SSE_PROFILE).

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
        httpc:request(get, {Url, Headers},
                      [{timeout, ?RPC_TIMEOUT_MS}], [{body_format, binary}]),
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
                       [{connect_timeout, 5000}, {timeout, ?RPC_TIMEOUT_MS}],
                       [{body_format, binary}]) of
        {ok, {{_, 200, _}, _, Body}} ->
            {ok, fh_shell_util:json_decode(Body)};
        {ok, {{_, Status, _}, _, Body}} ->
            {error, {http, Status, Body}};
        {error, Reason} ->
            {error, Reason}
    end.
