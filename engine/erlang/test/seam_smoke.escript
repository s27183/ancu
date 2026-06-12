#!/usr/bin/env escript
%%! -sname fh_seam_smoke
%%
%% End-to-end smoke test for Wedge-1a #8 slice 1 (the Erlang<->Python seam).
%% Boots the engine, seeds a tenant + ed25519 signing key, mints a JWT, and drives
%% the real /api/engine/* HTTP/SSE surface — asserting the full event sequence, the
%% persisted event log, the content_jsonb snapshot, cancellation idempotency, and
%% auth rejection. Run from engine/erlang with the build libs on the path:
%%
%%   ENGINE_DATABASE_URL=postgres://engine:engine_dev_pw@localhost:5433/firsthomey_engine?sslmode=disable \
%%   ERL_LIBS=_build/default/lib escript test/seam_smoke.escript

-mode(compile).

main(_) ->
    os:putenv("FH_ENGINE_HTTP_PORT", "8091"),
    {ok, _} = application:ensure_all_started(fh_engine),
    {ok, _} = application:ensure_all_started(inets),
    Base = "http://localhost:8091/api/engine",

    %% --- seed tenant + ed25519 signing key (the shell's role in production) ---
    TenantId = fh_engine_util:uuid4(),
    UserId = fh_engine_util:uuid4(),
    {Pub, Priv} = crypto:generate_key(eddsa, ed25519),
    ok = fh_engine_store:upsert_tenant(TenantId, <<"smoke-tenant">>),
    ok = fh_engine_store:add_signing_key(TenantId, <<"ed25519">>, base64:encode(Pub)),
    Token = mint(TenantId, UserId, Priv),
    Auth = {"authorization", "Bearer " ++ binary_to_list(Token)},

    %% --- POST create plan card (plan-first: no property) ---
    CreateBody = fh_engine_util:json_encode(#{
        <<"state">> => <<"NSW">>,
        <<"target_price_range">> => [600000, 700000],
        <<"target_zone">> => [<<"Cabramatta">>, <<"Canley Vale">>],
        <<"intent">> => <<"owner_occupier">>
    }),
    {202, CreateResp} = req(post, Base ++ "/plan-cards", [Auth], CreateBody),
    #{<<"plan_card_id">> := PlanCardId, <<"turn_id">> := TurnId} =
        fh_engine_util:json_decode(CreateResp),
    expect(is_binary(PlanCardId) andalso is_binary(TurnId), "create returns ids"),
    io:format("created plan_card_id=~s~n", [PlanCardId]),

    %% --- SSE stream: collect the turn's events (replay + live, same handler) ---
    EvUrl = Base ++ "/plan-cards/" ++ binary_to_list(PlanCardId) ++ "/events",
    Types = collect_sse(EvUrl, Auth),
    io:format("event sequence: ~p~n", [Types]),
    expect(Types =:= expected_sequence(), "event sequence matches §4 taxonomy"),

    %% --- persisted event log is the SOT (count matches the stream) ---
    EventCount = scalar("SELECT count(*) FROM plan_card_events WHERE plan_card_id = $1",
                        [PlanCardId]),
    expect(EventCount =:= 23, "23 events persisted"),

    %% --- compliance audit trail (2b-4c, compliance-pipeline.md §5): one audit_events
    %%     row per (component, gate) = 3 × 5 = 15, every one `clear` on the Mode-A healthy
    %%     path; ASIC attests decision_support_boundary_held on the 2 advice-adjacent
    %%     components (mortgage_finance, eligibility). The audit trail is the regulated
    %%     record constraint #10 demands — a gate with no audit row is still a disclaimer. ---
    AuditCount = scalar("SELECT count(*) FROM audit_events WHERE plan_card_id = $1",
                        [PlanCardId]),
    expect(AuditCount =:= 15, "15 audit_events rows (3 gates × 5 components)"),
    ClearCount = scalar("SELECT count(*) FROM audit_events WHERE plan_card_id = $1 "
                        "AND compliance_jsonb->>'disposition' = 'clear'", [PlanCardId]),
    expect(ClearCount =:= 15, "all 15 audit rows disposition=clear (Mode-A healthy)"),
    AsicHeld = scalar("SELECT count(*) FROM audit_events WHERE plan_card_id = $1 "
                      "AND compliance_jsonb->>'gate' = 'asic' "
                      "AND compliance_jsonb->>'detail' = 'decision_support_boundary_held'",
                      [PlanCardId]),
    expect(AsicHeld =:= 2, "ASIC boundary_held on the 2 advice-adjacent components"),
    TwoPathAudit = scalar("SELECT count(*) FROM audit_events WHERE plan_card_id = $1 "
                          "AND fill_path = 'two_path'", [PlanCardId]),
    expect(TwoPathAudit =:= 3, "two_path fill_path audited (migration 002 widened the CHECK)"),

    %% --- content_jsonb snapshot holds all 5 base components ---
    {200, CardResp} = req(get, Base ++ "/plan-cards/" ++ binary_to_list(PlanCardId),
                          [Auth], <<>>),
    #{<<"content">> := #{<<"components">> := Components}} =
        fh_engine_util:json_decode(CardResp),
    expect(map_size(Components) =:= 5, "5 components snapshotted into content_jsonb"),
    expect(maps:is_key(<<"eligibility">>, Components), "eligibility component present"),

    %% --- cancel is idempotent: turn already finished -> 204 ---
    {204, _} = req(post, Base ++ "/plan-cards/" ++ binary_to_list(PlanCardId) ++ "/cancel",
                   [Auth], <<>>),

    %% --- auth: missing token -> 401; wrong key -> 403 ---
    {401, _} = req(get, Base ++ "/plan-cards/" ++ binary_to_list(PlanCardId), [], <<>>),
    {_, BadPriv} = crypto:generate_key(eddsa, ed25519),
    BadToken = mint(TenantId, UserId, BadPriv),
    BadAuth = {"authorization", "Bearer " ++ binary_to_list(BadToken)},
    {403, _} = req(get, Base ++ "/plan-cards/" ++ binary_to_list(PlanCardId),
                   [BadAuth], <<>>),

    io:format("~n==== SEAM SMOKE: ALL ASSERTIONS PASSED ====~n"),
    halt(0).

%% Base turn with Layer 2 live (2b-4c): each component now emits THREE compliance_gate
%% events (firb · asic · aml, each audited) immediately before its component_filled.
%% Order: buyer_profile/eligibility (resolver) → mortgage_finance (two_path; its `usage`
%% lands right after its component_filled, from the sidecar fill) → cash_position/
%% ownership_planning (resolver) → turn_completed. 1 + 5×(3 gate + 1 filled) + usage + 1 = 23.
expected_sequence() ->
    Gates = [<<"compliance_gate">>, <<"compliance_gate">>, <<"compliance_gate">>],
    CF = <<"component_filled">>,
    lists:flatten(
      [<<"turn_started">>,
       Gates, CF,                      %% buyer_profile (resolver)
       Gates, CF,                      %% eligibility    (resolver)
       Gates, CF, <<"usage">>,         %% mortgage_finance (two_path) + its usage
       Gates, CF,                      %% cash_position  (resolver)
       Gates, CF,                      %% ownership_planning (resolver)
       <<"turn_completed">>]).

%% --- helpers ---------------------------------------------------------------

mint(TenantId, UserId, Priv) ->
    Now = erlang:system_time(second),
    fh_engine_auth:sign(#{<<"tenant_id">> => TenantId, <<"user_id">> => UserId,
                          <<"iat">> => Now, <<"exp">> => Now + 3600}, Priv).

%% Plain request -> {StatusCode, BodyBinary}.
req(Method, Url, Headers, Body) ->
    Request = case Method of
        get -> {Url, Headers};
        post -> {Url, Headers, "application/json", Body}
    end,
    {ok, {{_, Status, _}, _, Resp}} =
        httpc:request(Method, Request, [], [{body_format, binary}]),
    {Status, Resp}.

%% Stream SSE via httpc, return the ordered list of `event:` types until stream end.
collect_sse(Url, Auth) ->
    {ok, ReqId} = httpc:request(get, {Url, [Auth]}, [],
                                [{sync, false}, {stream, self}]),
    Raw = sse_loop(ReqId, <<>>),
    parse_event_types(Raw).

sse_loop(ReqId, Acc) ->
    receive
        {http, {ReqId, stream_start, _Headers}} -> sse_loop(ReqId, Acc);
        {http, {ReqId, stream, Chunk}} -> sse_loop(ReqId, <<Acc/binary, Chunk/binary>>);
        {http, {ReqId, stream_end, _Headers}} -> Acc;
        {http, {ReqId, {error, Reason}}} -> error({sse_error, Reason})
    after 30000 ->   %% > the 15s SSE keepalive cadence — keepalives reset this each tick
        error(sse_timeout)
    end.

parse_event_types(Raw) ->
    Frames = binary:split(Raw, <<"\n\n">>, [global]),
    Pairs = lists:filtermap(fun parse_frame/1, Frames),
    %% Dedup by event id: httpc may reconnect mid-stream, and without Last-Event-ID the
    %% engine correctly replays from 0 — so a naive client sees the replay twice. A real
    %% SSE client dedups via Last-Event-ID; we do the same here (keep first-seen order).
    {_, Rev} = lists:foldl(fun({Id, Type}, {Seen, Acc}) ->
        case sets:is_element(Id, Seen) of
            true -> {Seen, Acc};
            false -> {sets:add_element(Id, Seen), [Type | Acc]}
        end
    end, {sets:new(), []}, Pairs),
    lists:reverse(Rev).

parse_frame(Frame) ->
    case re:run(Frame, <<"event: (.+)">>, [{capture, [1], binary}]) of
        {match, [Type]} ->
            Id = case re:run(Frame, <<"id: (\\d+)">>, [{capture, [1], binary}]) of
                     {match, [I]} -> binary_to_integer(I);
                     nomatch -> 0
                 end,
            {true, {Id, Type}};
        nomatch -> false
    end.

scalar(SQL, Params) ->
    #{rows := [{Val}]} = pgo:query(SQL, Params),
    Val.

expect(true, _Msg) -> ok;
expect(false, Msg) ->
    io:format("ASSERTION FAILED: ~s~n", [Msg]),
    halt(1).
