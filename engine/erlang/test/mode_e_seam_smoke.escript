#!/usr/bin/env escript
%%! -sname fh_mode_e_seam_smoke
%%
%% End-to-end smoke test for Mode E (mode-e-wedge.md P5) — the missing HALF of P5's
%% "live-verified" claim: base_components_nexthome_conformance.escript and
%% blueprint_for_conformance.escript both prove below-the-seam correctness (DAG order,
%% resolver output, dispatch truth table) but neither exercises the two-path sidecar
%% fill, the FIRB→ASIC→AML compliance pipeline on Mode-E's OWN components, the
%% outcome-conformance gate at the commit seam, or SSE/PG persistence — the same real
%% HTTP/PG walk seam_smoke.escript (Mode A) / mode_b_seam_smoke.escript (Mode B) /
%% mode_d_seam_smoke.escript (Mode D) each already prove for their own mode. Mirrors
%% seam_smoke.escript's structure exactly; the only inputs that differ are
%% buyer_stage=next_home (no foreign_person) and the Mode-E component set/ASIC-adjacency
%% counts below.
%%
%% Boots the engine, seeds a tenant + ed25519 signing key, mints a JWT, and drives the
%% real /api/engine/* HTTP/SSE surface for a genuine domestic + owner_occupier +
%% next_home submission (fh_engine_h_plan_cards:blueprint_for/3 → nexthome-domestic-au).
%% Run from engine/erlang with the build libs on the path:
%%
%%   ENGINE_DATABASE_URL=postgres://engine:engine_dev_pw@localhost:5433/ancu_engine?sslmode=disable \
%%   ERL_LIBS=_build/default/lib escript test/mode_e_seam_smoke.escript

-mode(compile).

main(_) ->
    os:putenv("FH_ENGINE_HTTP_PORT", "8095"),
    {ok, _} = application:ensure_all_started(fh_engine),
    {ok, _} = application:ensure_all_started(inets),
    Base = "http://localhost:8095/api/engine",

    %% --- seed tenant + ed25519 signing key (the shell's role in production) ---
    TenantId = fh_engine_util:uuid4(),
    UserId = fh_engine_util:uuid4(),
    {Pub, Priv} = crypto:generate_key(eddsa, ed25519),
    ok = fh_engine_store:upsert_tenant(TenantId, <<"mode-e-smoke-tenant">>),
    ok = fh_engine_store:add_signing_key(TenantId, <<"ed25519">>, base64:encode(Pub)),
    Token = mint(TenantId, UserId, Priv),
    Auth = {"authorization", "Bearer " ++ binary_to_list(Token)},

    %% --- POST create plan card: intent=owner_occupier + buyer_stage=next_home ->
    %%     Mode E (nexthome-domestic-au), per fh_engine_h_plan_cards:blueprint_for/3
    %%     (mode-e-wedge.md P5) ---
    CreateBody = fh_engine_util:json_encode(#{
        <<"state">> => <<"NSW">>,
        <<"target_price_range">> => [900000, 1100000],
        <<"target_zone">> => [<<"Cabramatta">>, <<"Canley Vale">>],
        <<"intent">> => <<"owner_occupier">>,
        <<"buyer_stage">> => <<"next_home">>
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
    expect(EventCount =:= 39, "39 events persisted (1 + 9×(3 gate + 1 filled) + usage + 1) "
          "— structurally identical to Mode A's count: existing_home_disposal is a pure "
          "resolver in eligibility's exact slot, mortgage_finance is the sole two_path"),

    %% --- compliance audit trail: 3 gates × 9 components = 27 rows, all clear. Mode E has
    %%     only ONE advice-adjacent component (mortgage_finance) — existing_home_disposal
    %%     is NOT in fh_engine_compliance:advice_adjacent/1 (it mirrors disposition's own
    %%     treatment: a resolver-computed CGT/figure component with a to_verify flag, not a
    %%     scheme-applicability or lender-fit judgment) — so ASIC boundary_held is 1, not
    %%     Mode A's 2. ---
    AuditCount = scalar("SELECT count(*) FROM audit_events WHERE plan_card_id = $1",
                        [PlanCardId]),
    expect(AuditCount =:= 27, "27 audit_events rows (3 gates × 9 components)"),
    ClearCount = scalar("SELECT count(*) FROM audit_events WHERE plan_card_id = $1 "
                        "AND compliance_jsonb->>'disposition' = 'clear'", [PlanCardId]),
    expect(ClearCount =:= 27, "all 27 audit rows disposition=clear (Mode-E healthy)"),
    AsicHeld = scalar("SELECT count(*) FROM audit_events WHERE plan_card_id = $1 "
                      "AND compliance_jsonb->>'gate' = 'asic' "
                      "AND compliance_jsonb->>'detail' = 'decision_support_boundary_held'",
                      [PlanCardId]),
    expect(AsicHeld =:= 1, "ASIC boundary_held on the ONE advice-adjacent component "
          "(mortgage_finance only — existing_home_disposal is not advice-adjacent)"),
    TwoPathAudit = scalar("SELECT count(*) FROM audit_events WHERE plan_card_id = $1 "
                          "AND fill_path = 'two_path'", [PlanCardId]),
    expect(TwoPathAudit =:= 3, "two_path fill_path audited (3 gate rows for the one "
          "two_path component, mortgage_finance)"),

    %% --- content_jsonb snapshot holds all 9 base components, including the Mode-E-only
    %%     existing_home_disposal (NOT eligibility, which this blueprint has none of) ---
    {200, CardResp} = req(get, Base ++ "/plan-cards/" ++ binary_to_list(PlanCardId),
                          [Auth], <<>>),
    #{<<"content">> := #{<<"components">> := Components}} =
        fh_engine_util:json_decode(CardResp),
    expect(map_size(Components) =:= 9, "9 components snapshotted into content_jsonb"),
    expect(not maps:is_key(<<"eligibility">>, Components),
          "eligibility ABSENT — Mode E has no eligibility component (decision #2)"),
    expect(maps:is_key(<<"existing_home_disposal">>, Components),
          "existing_home_disposal component present (the Mode-E-only component)"),
    expect(maps:is_key(<<"purchase_journey">>, Components), "purchase_journey component present"),
    expect(maps:is_key(<<"disposition">>, Components), "disposition component present (terminal dispose figure-owner)"),
    %% Mode-E's genuine HAVE-side extension (mode-e-wedge.md P2/P3): cash_position's
    %% verdict/gap_or_surplus/cash_available fold in existing_home_disposal's
    %% net_sale_proceeds. At base every fact is honestly null (no onboarding capture of the
    %% existing home's sale price) — proving the FIELD is present (not its value), per the
    %% honest-partial convention this whole engine follows.
    #{<<"cash_position">> := #{<<"outcome">> := CashOutcome}} = Components,
    expect(maps:is_key(<<"cash_available">>, CashOutcome),
          "cash_position carries the Mode-E HAVE-side field (honestly null at base)"),
    expect(maps:get(<<"cash_available">>, CashOutcome) =:= null,
          "cash_available is honestly null at base (no existing-home facts yet)"),

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

    io:format("~n==== MODE-E SEAM SMOKE: ALL ASSERTIONS PASSED ====~n"),
    halt(0).

%% Base turn with Layer 2 live (2b-4c): each component emits THREE compliance_gate
%% events (firb · asic · aml, each audited) immediately before its component_filled.
%% Order = ?BASE_COMPONENTS_NEXTHOME (fh_engine_turn.erl, mode-e-wedge.md P5) — the
%% Mode-A nine with `eligibility` swapped for `existing_home_disposal` in the same slot:
%% buyer_profile → existing_home_disposal → mortgage_finance (two_path; its `usage` lands
%% right after its component_filled) → cash_position → ownership_planning → disposition →
%% purchase_journey → preparation → phase_playbook → turn_completed.
%% 1 + 9×(3 gate + 1 filled) + usage + 1 = 39.
expected_sequence() ->
    Gates = [<<"compliance_gate">>, <<"compliance_gate">>, <<"compliance_gate">>],
    CF = <<"component_filled">>,
    lists:flatten(
      [<<"turn_started">>,
       Gates, CF,                      %% buyer_profile          (resolver)
       Gates, CF,                      %% existing_home_disposal (resolver)
       Gates, CF, <<"usage">>,         %% mortgage_finance       (two_path) + its usage
       Gates, CF,                      %% cash_position          (resolver)
       Gates, CF,                      %% ownership_planning     (resolver)
       Gates, CF,                      %% disposition            (resolver)
       Gates, CF,                      %% purchase_journey       (resolver)
       Gates, CF,                      %% preparation            (resolver)
       Gates, CF,                      %% phase_playbook         (resolver)
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
