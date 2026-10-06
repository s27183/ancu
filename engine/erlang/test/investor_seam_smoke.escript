#!/usr/bin/env escript
%%! -sname fh_investor_seam_smoke
%%
%% Full-stack LIVE smoke for the Mode-C investor turn (P5-activate close-out; extended
%% 2026-07-10 to the 10-component spine — the B/C/D lifecycle-spine restructure, task 7).
%% Clones seam_smoke (the Mode-A harness) with intent=investment: boots the engine,
%% seeds a tenant + ed25519 signing key, mints a JWT, POSTs plan-card creation, and
%% drives the real /api/engine/* HTTP/SSE surface through the 10-component investor base
%% spine end-to-end — asserting the event sequence, the persisted log, the compliance
%% audit trail, the content_jsonb snapshot (incl. the live LLM-backed investor outcome
%% shapes AND the resolver-placed purchase_journey/phase_playbook), cancel idempotency,
%% and auth rejection. Proves the HTTP->turn glue for Mode C's restructured spine — the
%% link task 5/6 (ui_tabs + shell) built on top of but didn't themselves prove live.
%%
%% Run LIVE (real Opus sidecar fills — metered) from engine/erlang:
%%
%%   FH_PLANNER_SCRIPT=$(pwd)/../python/planner.py \
%%   FH_SIDECAR_PYTHON=$(pwd)/../../.venv/bin/python3 \
%%   ENGINE_DATABASE_URL=postgres://engine:engine_dev_pw@localhost:5433/firsthomey_engine?sslmode=disable \
%%   ERL_LIBS=_build/default/lib escript test/investor_seam_smoke.escript

-mode(compile).

main(_) ->
    os:putenv("FH_ENGINE_HTTP_PORT", "8092"),
    {ok, _} = application:ensure_all_started(fh_engine),
    {ok, _} = application:ensure_all_started(inets),
    Base = "http://localhost:8092/api/engine",

    %% --- seed tenant + ed25519 signing key (the shell's role in production) ---
    TenantId = fh_engine_util:uuid4(),
    UserId = fh_engine_util:uuid4(),
    {Pub, Priv} = crypto:generate_key(eddsa, ed25519),
    ok = fh_engine_store:upsert_tenant(TenantId, <<"investor-smoke-tenant">>),
    ok = fh_engine_store:add_signing_key(TenantId, <<"ed25519">>, base64:encode(Pub)),
    Token = mint(TenantId, UserId, Priv),
    Auth = {"authorization", "Bearer " ++ binary_to_list(Token)},

    %% --- POST create plan card: intent=investment -> Mode C (investor-domestic-au) ---
    CreateBody = fh_engine_util:json_encode(#{
        <<"state">> => <<"NSW">>,
        <<"target_price_range">> => [800000, 1000000],
        <<"target_zone">> => [<<"Cabramatta">>, <<"Canley Vale">>],
        <<"intent">> => <<"investment">>
    }),
    {202, CreateResp} = req(post, Base ++ "/plan-cards", [Auth], CreateBody),
    #{<<"plan_card_id">> := PlanCardId, <<"turn_id">> := TurnId} =
        fh_engine_util:json_decode(CreateResp),
    expect(is_binary(PlanCardId) andalso is_binary(TurnId), "create returns ids"),
    io:format("created plan_card_id=~s~n", [PlanCardId]),

    %% --- SSE stream: collect the turn's events (LIVE Opus fills -> longer wall-clock;
    %%     the 30s receive-window resets on each 15s keepalive, so a slow fill is fine) ---
    EvUrl = Base ++ "/plan-cards/" ++ binary_to_list(PlanCardId) ++ "/events",
    Types = collect_sse(EvUrl, Auth),
    io:format("event sequence: ~p~n", [Types]),
    expect(Types =:= expected_sequence(), "event sequence matches the investor spine"),

    %% --- persisted event log is the SOT (count matches the stream) ---
    EventCount = scalar("SELECT count(*) FROM plan_card_events WHERE plan_card_id = $1",
                        [PlanCardId]),
    expect(EventCount =:= 45, "45 events persisted (1 + 10×(3 gate + 1 filled) + 3 usage + 1)"),

    %% --- compliance audit trail: one audit_events row per (component, gate) = 3 × 10 = 30,
    %%     every one `clear` on the Mode-C healthy path. ASIC boundary_held lands ONLY on
    %%     mortgage_finance: the investor spine carries no `eligibility` (FHB-only), and
    %%     advice_adjacent/1 lists only mortgage_finance + eligibility. tax_structure,
    %%     investment_strategy, purchase_journey, and phase_playbook all clear with
    %%     no_advice_surface — the ASIC line is held at the producer (§98 figure-tightness,
    %%     schema-as-constraint enums; phase_playbook's risks are KB-grounded, never
    %%     LLM-authored), the audit `detail` is the attestation record. (Flagged: whether the
    %%     entity/strategy attestation should also record boundary_held is a separate
    %%     compliance-record refinement.) ---
    AuditCount = scalar("SELECT count(*) FROM audit_events WHERE plan_card_id = $1",
                        [PlanCardId]),
    expect(AuditCount =:= 30, "30 audit_events rows (3 gates × 10 components)"),
    ClearCount = scalar("SELECT count(*) FROM audit_events WHERE plan_card_id = $1 "
                        "AND compliance_jsonb->>'disposition' = 'clear'", [PlanCardId]),
    expect(ClearCount =:= 30, "all 30 audit rows disposition=clear (Mode-C healthy)"),
    AsicHeld = scalar("SELECT count(*) FROM audit_events WHERE plan_card_id = $1 "
                      "AND compliance_jsonb->>'gate' = 'asic' "
                      "AND compliance_jsonb->>'detail' = 'decision_support_boundary_held'",
                      [PlanCardId]),
    expect(AsicHeld =:= 1, "ASIC boundary_held on mortgage_finance only (no eligibility in Mode C)"),
    TwoPathAudit = scalar("SELECT count(*) FROM audit_events WHERE plan_card_id = $1 "
                          "AND fill_path = 'two_path'", [PlanCardId]),
    expect(TwoPathAudit =:= 9, "9 two_path audit rows (3 two-path components × 3 gates)"),

    %% --- content_jsonb snapshot holds all 10 investor base components ---
    {200, CardResp} = req(get, Base ++ "/plan-cards/" ++ binary_to_list(PlanCardId),
                          [Auth], <<>>),
    #{<<"content">> := #{<<"components">> := Components}} =
        fh_engine_util:json_decode(CardResp),
    expect(map_size(Components) =:= 10, "10 components snapshotted into content_jsonb"),
    [expect(maps:is_key(N, Components), binary_to_list(N) ++ " component present")
     || N <- [<<"investor_profile">>, <<"investment_strategy">>, <<"mortgage_finance">>,
              <<"yield_modelling">>, <<"tax_structure">>, <<"cash_position">>,
              <<"ownership_planning_investor">>, <<"disposition">>,
              <<"purchase_journey">>, <<"phase_playbook">>]],

    %% --- the genuine Mode-C proof: the LIVE LLM-backed investor outcomes actually landed
    %%     (not just that 8 slots exist). Each two-path component's agent leaf surfaced its
    %%     enum/bilingual value; the shared-name discriminators fired the investor branch. ---
    Out = fun(N) -> maps:get(<<"outcome">>, maps:get(N, Components)) end,
    Strat = Out(<<"investment_strategy">>),
    expect(is_binary(maps:get(<<"archetype">>, Strat, undefined)), "strategy archetype filled (live)"),
    expect(is_binary(maps:get(<<"gearing_type">>, Strat, undefined)), "strategy gearing_type filled (live)"),
    OL = maps:get(<<"one_liner">>, Strat, undefined),
    expect(is_map(OL) andalso maps:is_key(<<"vi">>, OL) andalso maps:is_key(<<"en">>, OL),
           "strategy one_liner bilingual {vi,en} (live)"),
    Mort = Out(<<"mortgage_finance">>),
    expect(is_binary(maps:get(<<"io_vs_pi_recommendation">>, Mort, undefined)),
           "mortgage io_vs_pi_recommendation filled (the investor discriminator, live)"),
    Tax = Out(<<"tax_structure">>),
    expect(is_binary(maps:get(<<"recommended_entity">>, Tax, undefined)),
           "tax recommended_entity filled (live)"),
    Disp = Out(<<"disposition">>),
    expect(maps:is_key(<<"taxable_gain">>, Disp), "disposition has investor taxable_gain field"),
    expect(maps:is_key(<<"cgt_status">>, Disp), "disposition has cgt_status field"),
    Cash = Out(<<"cash_position">>),
    expect(not maps:is_key(<<"stamp_duty">>, Cash),
           "cash_position is budget_envelope_investor (no stamp_duty — discriminator fired investor-side)"),
    expect(maps:is_key(<<"max_property_price_supported">>, Cash),
           "cash_position has investor max_property_price_supported field"),
    io:format("live investor outcomes: archetype=~s gearing=~s io_vs_pi=~s entity=~s~n",
              [maps:get(<<"archetype">>, Strat), maps:get(<<"gearing_type">>, Strat),
               maps:get(<<"io_vs_pi_recommendation">>, Mort),
               maps:get(<<"recommended_entity">>, Tax)]),

    %% --- the restructure's own proof: purchase_journey/phase_playbook fired the Mode-C
    %%     (not Mode-A) branch, live. At this base, property-less, income-less turn every
    %%     upstream cash_events source is honestly empty (no property, no income captured),
    %%     so cell amounts and budget_refs are correctly null throughout — that positive case
    %%     (a real amount/ref landing) is proven by cash_position_investor_conformance.escript's
    %%     per-property harvest assertions instead. What THIS live turn proves is that the
    %%     investor-specific KB content — not Mode A's — actually rendered through the real
    %%     resolver over HTTP/SSE: the six-actor set and the investor phase_playbook content. ---
    Journey = Out(<<"purchase_journey">>),
    JActorIds = [maps:get(<<"id">>, A) || A <- maps:get(<<"actors">>, Journey, [])],
    expect(lists:sort(JActorIds) =:=
             lists:sort([<<"you">>, <<"government">>, <<"lender">>,
                         <<"property_manager">>, <<"tenant">>, <<"services">>]),
           "purchase_journey six-actor investor set (property_manager/tenant, live)"),
    JPhaseIds = [maps:get(<<"id">>, P) || P <- maps:get(<<"phases">>, Journey, [])],
    expect(lists:member(<<"own">>, JPhaseIds), "purchase_journey has the own/Hold phase"),
    Playbook = Out(<<"phase_playbook">>),
    PbPhases = maps:get(<<"phases">>, Playbook, []),
    expect(length(PbPhases) > 0, "phase_playbook has phases (investor KB content live)"),
    OwnPbPhase = hd([P || P <- PbPhases, maps:get(<<"phase">>, P) =:= <<"own">>]),
    OwnActionIds = [maps:get(<<"id">>, A) || A <- maps:get(<<"actions">>, OwnPbPhase, [])],
    expect(lists:member(<<"lodge_annual_return">>, OwnActionIds),
           "phase_playbook own-phase carries the investor lodge_annual_return action (kb.journey.investor-phase-actions, live)"),

    io:format("live journey/playbook: actors=~p own_actions=~p~n", [JActorIds, OwnActionIds]),

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

    io:format("~n==== INVESTOR SEAM SMOKE: ALL ASSERTIONS PASSED ====~n"),
    halt(0).

%% The investor base spine (?BASE_COMPONENTS_INVESTOR, 10 components — purchase_journey/
%% phase_playbook added 2026-07-10, task 4). Each emits THREE compliance_gate events before
%% its component_filled; the THREE two-path components (investment_strategy, mortgage_finance,
%% tax_structure) each emit a `usage` right after their fill, from the sidecar. Order is
%% discriminator-load-bearing (strategy before mortgage; tax_structure + budget_envelope_investor
%% before disposition; tax before cash; disposition before ownership_planning_investor — NOT the
%% reverse); purchase_journey/phase_playbook run LAST (resolvers, no usage), mirroring the
%% Mode-E harness (mode_e_seam_smoke.escript).
%% 1 + 10×(3 gate + 1 filled) + 3 usage + 1 = 45.
expected_sequence() ->
    Gates = [<<"compliance_gate">>, <<"compliance_gate">>, <<"compliance_gate">>],
    CF = <<"component_filled">>,
    U = <<"usage">>,
    lists:flatten(
      [<<"turn_started">>,
       Gates, CF,           %% investor_profile            (resolver)
       Gates, CF, U,        %% investment_strategy         (two_path)
       Gates, CF, U,        %% mortgage_finance            (two_path)
       Gates, CF,           %% yield_modelling             (resolver)
       Gates, CF, U,        %% tax_structure               (two_path)
       Gates, CF,           %% cash_position               (resolver)
       Gates, CF,           %% disposition                 (resolver)
       Gates, CF,           %% ownership_planning_investor (resolver)
       Gates, CF,           %% purchase_journey            (resolver)
       Gates, CF,           %% phase_playbook              (resolver)
       <<"turn_completed">>]).

%% --- helpers (identical to seam_smoke) ---------------------------------------

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
