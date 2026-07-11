#!/usr/bin/env escript
%%! -sname fh_mode_b_seam_smoke
%%
%% Full-stack LIVE smoke for the Mode-B foreign-buyer turn (mode-b-wedge.md P5 close-out —
%% the wedge's one honestly-recorded open gap: no live HTTP turn had been run yet, Docker
%% was down through the whole build). Clones investor_seam_smoke (the Mode-C harness) with
%% intent=owner_occupier + foreign_person=true: boots the engine, seeds a tenant + ed25519
%% signing key, mints a JWT, POSTs plan-card creation, and drives the real /api/engine/*
%% HTTP/SSE surface through the 8-component foreign-buyer base spine end-to-end — asserting
%% the event sequence, the persisted log, the FIRB→ASIC→AML compliance audit trail, and the
%% content_jsonb snapshot. Proves fh_engine_h_plan_cards:blueprint_for/2 dispatch + the
%% ?BASE_COMPONENTS_FOREIGN order + the fh_engine_firb resolver + the FIRB compliance gate's
%% Mode-B clause (P2 slice 2) all wire together over real HTTP — the one link P5 left
%% unproven-in-integration.
%%
%% disposition (component 8) added 2026-07-11 (task 11, plan-card-lifecycle-restoration.md
%% §11.4 — dispose-phase parity with Modes A/C/D). purchase_journey + phase_playbook
%% (components 9-10) added 2026-07-11 (task 12, §11.5/§11.8 — the same lifecycle-spine
%% components every other mode now carries). Updated here: 7 -> 8 -> 10 components, 21 -> 24
%% -> 30 audit rows, expected_sequence/0 gains two more (gates, component_filled) groups.
%%
%% UNLIKE Mode A/C: every Mode-B base component is RESOLVER-ONLY (zero agent_reasoning_required
%% leaves anywhere in the 10-component base spine — fhb-foreign-au.md's own "Fill-path
%% classification" prose, "Mode B's FIRB mechanics ... are all resolver", now also true of
%% disposition per fh_engine_disposition.erl's own module doc — "NO agent leaf" — and of
%% purchase_journey/phase_playbook, which reuse Mode A's resolver-only builders verbatim; the
%% only Mode-B-specific agent leaves live in property_assessment/due_diligence, both Phase-B-only,
%% not in the base set). So this smoke needs no CLAUDE_CODE_OAUTH_TOKEN / sidecar and emits
%% zero `usage` events — a genuine structural difference from Mode A/C's two-path base
%% components, not an oversight.
%%
%% Run from engine/erlang:
%%
%%   ENGINE_DATABASE_URL=postgres://engine:engine_dev_pw@localhost:5433/firsthomey_engine?sslmode=disable \
%%   ERL_LIBS=_build/default/lib escript test/mode_b_seam_smoke.escript

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
    ok = fh_engine_store:upsert_tenant(TenantId, <<"mode-b-smoke-tenant">>),
    ok = fh_engine_store:add_signing_key(TenantId, <<"ed25519">>, base64:encode(Pub)),
    Token = mint(TenantId, UserId, Priv),
    Auth = {"authorization", "Bearer " ++ binary_to_list(Token)},

    %% --- POST create plan card: intent=owner_occupier + foreign_person=true + buyer_stage
    %%     =first_home -> Mode B (fhb-foreign-au), per
    %%     fh_engine_h_plan_cards:blueprint_for/3 (mode-e-wedge.md P5 — buyer_stage is now
    %%     REQUIRED for owner_occupier; the engine fails closed on absent, never guesses) ---
    %% hold_horizon_years set (10y) so disposition's real computed dispose-phase figures
    %% land live, not just the H-unset null path (task 11's own conformance-escript precedent).
    CreateBody = fh_engine_util:json_encode(#{
        <<"state">> => <<"NSW">>,
        <<"target_price_range">> => [700000, 900000],
        <<"intent">> => <<"owner_occupier">>,
        <<"foreign_person">> => true,
        <<"buyer_stage">> => <<"first_home">>,
        <<"hold_horizon_years">> => 10
    }),
    {202, CreateResp} = req(post, Base ++ "/plan-cards", [Auth], CreateBody),
    #{<<"plan_card_id">> := PlanCardId, <<"turn_id">> := TurnId} =
        fh_engine_util:json_decode(CreateResp),
    expect(is_binary(PlanCardId) andalso is_binary(TurnId), "create returns ids"),
    io:format("created plan_card_id=~s~n", [PlanCardId]),

    %% --- SSE stream: collect the turn's events (all-resolver -> fast, no LLM wall-clock) ---
    EvUrl = Base ++ "/plan-cards/" ++ binary_to_list(PlanCardId) ++ "/events",
    Types = collect_sse(EvUrl, Auth),
    io:format("event sequence: ~p~n", [Types]),
    expect(Types =:= expected_sequence(), "event sequence matches the Mode-B foreign spine"),

    %% --- persisted event log is the SOT (count matches the stream) ---
    EventCount = scalar("SELECT count(*) FROM plan_card_events WHERE plan_card_id = $1",
                        [PlanCardId]),
    expect(EventCount =:= 42, "42 events persisted (1 + 10x(3 gate + 1 filled) + 0 usage + 1)"),

    %% --- compliance audit trail: one audit_events row per (component, gate) = 3 x 10 = 30,
    %%     every one `clear` on the Mode-B healthy path (fh_engine_compliance FIRB clause,
    %%     P2 slice 2 — base-turn pre-contract planning, none is the FATA notifiable action) ---
    AuditCount = scalar("SELECT count(*) FROM audit_events WHERE plan_card_id = $1",
                        [PlanCardId]),
    expect(AuditCount =:= 30, "30 audit_events rows (3 gates x 10 components)"),
    ClearCount = scalar("SELECT count(*) FROM audit_events WHERE plan_card_id = $1 "
                        "AND compliance_jsonb->>'disposition' = 'clear'", [PlanCardId]),
    expect(ClearCount =:= 30, "all 30 audit rows disposition=clear (Mode-B healthy)"),

    %% --- FIRB gate detail: firb_workflow's own commit audits which state it found
    %%     (blocking_for_contract still true at base-turn, no property/approval yet ->
    %%     firb_approval_pending); every OTHER component clears pre_contract_planning ---
    FirbPending = scalar("SELECT count(*) FROM audit_events WHERE plan_card_id = $1 "
                         "AND compliance_jsonb->>'gate' = 'firb' "
                         "AND component_id = 'firb_workflow' "
                         "AND compliance_jsonb->>'detail' = 'firb_approval_pending'",
                         [PlanCardId]),
    expect(FirbPending =:= 1, "firb_workflow's own FIRB gate detail = firb_approval_pending"),
    FirbPreContract = scalar("SELECT count(*) FROM audit_events WHERE plan_card_id = $1 "
                             "AND compliance_jsonb->>'gate' = 'firb' "
                             "AND component_id <> 'firb_workflow' "
                             "AND compliance_jsonb->>'detail' = 'pre_contract_planning'",
                             [PlanCardId]),
    expect(FirbPreContract =:= 9, "the other 9 components' FIRB gate detail = pre_contract_planning"),

    %% --- ASIC boundary_held on mortgage_finance + firb_workflow only (advice_adjacent/1) ---
    AsicHeld = scalar("SELECT count(*) FROM audit_events WHERE plan_card_id = $1 "
                      "AND compliance_jsonb->>'gate' = 'asic' "
                      "AND compliance_jsonb->>'detail' = 'decision_support_boundary_held'",
                      [PlanCardId]),
    expect(AsicHeld =:= 2, "ASIC boundary_held on mortgage_finance + firb_workflow (advice_adjacent)"),

    %% --- every component's fill_path is resolver (Mode B base has zero agent leaves) ---
    ResolverCount = scalar("SELECT count(*) FROM audit_events WHERE plan_card_id = $1 "
                           "AND fill_path = 'resolver'", [PlanCardId]),
    expect(ResolverCount =:= 30, "all 30 audit rows fill_path=resolver (no two_path in Mode B base)"),

    %% --- content_jsonb snapshot holds all 10 foreign-buyer base components ---
    {200, CardResp} = req(get, Base ++ "/plan-cards/" ++ binary_to_list(PlanCardId),
                          [Auth], <<>>),
    #{<<"content">> := #{<<"components">> := Components}} =
        fh_engine_util:json_decode(CardResp),
    expect(map_size(Components) =:= 10, "10 components snapshotted into content_jsonb"),
    [expect(maps:is_key(N, Components), binary_to_list(N) ++ " component present")
     || N <- [<<"buyer_profile">>, <<"family_context">>, <<"firb_workflow">>,
              <<"mortgage_finance">>, <<"cash_position">>, <<"cross_border_funding">>,
              <<"ownership_planning">>, <<"disposition">>,
              <<"purchase_journey">>, <<"phase_playbook">>]],

    %% --- the genuine Mode-B proof: the discriminated foreign-buyer outcome shapes actually
    %%     landed (not just that 7 slots exist) — mirrors base_components_foreign_conformance's
    %%     discriminator_cases, now proven over a REAL committed turn, not a fixture ---
    Out = fun(N) -> maps:get(<<"outcome">>, maps:get(N, Components)) end,
    Firb = Out(<<"firb_workflow">>),
    expect(maps:is_key(<<"foreign_person_eligible">>, Firb), "firb_status has foreign_person_eligible"),
    expect(maps:is_key(<<"blocking_for_contract">>, Firb), "firb_status has blocking_for_contract"),
    expect(maps:get(<<"blocking_for_contract">>, Firb) =:= true,
           "blocking_for_contract=true (no FIRB approval yet at base turn)"),
    Mort = Out(<<"mortgage_finance">>),
    expect(maps:is_key(<<"firb_dependency_acknowledged">>, Mort),
           "mortgage_plan has firb_dependency_acknowledged (the Mode-B discriminator, live)"),
    Cash = Out(<<"cash_position">>),
    expect(maps:is_key(<<"regulatory_imposts_total">>, Cash),
           "budget_envelope has regulatory_imposts_total (Mode-B discriminator, live)"),
    expect(not maps:is_key(<<"stamp_duty">>, Cash),
           "cash_position is budget_envelope foreign-variant (no bare stamp_duty field)"),
    Own = Out(<<"ownership_planning">>),
    expect(maps:is_key(<<"vacancy_fee_at_risk_amount">>, Own),
           "ongoing_obligations has vacancy_fee_at_risk_amount (Mode-B discriminator, live)"),

    %% --- disposition (task 11, plan-card-lifecycle-restoration.md §11.4): the two grounded
    %%     Mode-B-specific calls proven over a REAL committed turn, not a fixture — cgt_status
    %%     always to_verify (tax_residency deliberately unset) and full_horizon_net_position
    %%     always null (ownership_planning's foreign variant carries no statutory_band), while
    %%     the dispose-phase figures this component was added for compute live with H=10 set ---
    Disp = Out(<<"disposition">>),
    expect(maps:get(<<"cgt_status">>, Disp) =:= <<"to_verify">>,
           "disposition.cgt_status = to_verify (live, Mode B never routes to exempt)"),
    expect(maps:get(<<"full_horizon_net_position">>, Disp) =:= null,
           "disposition.full_horizon_net_position = null (live, the disclosed permanent gap)"),
    expect(maps:get(<<"sale_proceeds">>, Disp) =/= null,
           "disposition.sale_proceeds computed live (H=10, target_price_range known)"),
    expect(length(maps:get(<<"dispose_cash_events">>, Disp, [])) > 0,
           "disposition.dispose_cash_events non-empty live"),

    io:format("live foreign-buyer outcomes: foreign_person_eligible=~p blocking=~p "
              "firb_dependency_acknowledged=~p vacancy_fee_at_risk=~p cgt_status=~p~n",
              [maps:get(<<"foreign_person_eligible">>, Firb),
               maps:get(<<"blocking_for_contract">>, Firb),
               maps:get(<<"firb_dependency_acknowledged">>, Mort),
               maps:get(<<"vacancy_fee_at_risk_amount">>, Own),
               maps:get(<<"cgt_status">>, Disp)]),

    %% --- purchase_journey/phase_playbook (task 12): proves the Mode-B KB branch actually
    %%     fires over the real HTTP/SSE surface, not a silent fallthrough — Mode A's own
    %%     four-actor set is REUSED verbatim (§3.3: "B = A's shape + a FIRB gate + a
    %%     currency-transfer milestone + surcharge", not Mode C/D's six-actor investor set);
    %%     the dispose phase IS present here (unlike Mode D's own smoke) because this turn
    %%     sets hold_horizon_years=10 (line ~63), so disposition's real dispose_cash_events
    %%     already asserted non-empty above feed the swimlane's terminal column; the
    %%     contract-phase action proves the Mode-B-specific phase-actions doc
    %%     (kb.journey.fhb-foreign-phase-actions), not Mode A's domestic content, resolved. ---
    Journey = Out(<<"purchase_journey">>),
    JActorIds = [maps:get(<<"id">>, A) || A <- maps:get(<<"actors">>, Journey, [])],
    expect(lists:sort(JActorIds) =:=
             lists:sort([<<"you">>, <<"government">>, <<"lender">>, <<"other">>]),
           "purchase_journey four-actor set, reused from Mode A unchanged (live)"),
    JPhaseIds = [maps:get(<<"id">>, P) || P <- maps:get(<<"phases">>, Journey, [])],
    expect(lists:member(<<"contract">>, JPhaseIds),
           "purchase_journey has the contract phase (FIRB gate narrated here)"),
    expect(lists:member(<<"dispose">>, JPhaseIds),
           "purchase_journey HAS the dispose phase (hold_horizon_years=10 set at this turn)"),
    Playbook = Out(<<"phase_playbook">>),
    PbPhases = maps:get(<<"phases">>, Playbook, []),
    expect(length(PbPhases) > 0, "phase_playbook has phases (Mode-B foreign-buyer KB content live)"),
    ContractPbPhase = hd([P || P <- PbPhases, maps:get(<<"phase">>, P) =:= <<"contract">>]),
    ContractActionIds = [maps:get(<<"id">>, A) || A <- maps:get(<<"actions">>, ContractPbPhase, [])],
    expect(lists:member(<<"submit_firb_application">>, ContractActionIds),
           "phase_playbook contract-phase carries the Mode-B submit_firb_application action "
           "(kb.journey.fhb-foreign-phase-actions, live — not Mode A's domestic content)"),
    io:format("live journey/playbook: actors=~p phases=~p contract_actions=~p~n",
              [JActorIds, JPhaseIds, ContractActionIds]),

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

    %% --- investment + foreign now routes LIVE to Mode D (mode-d-wedge.md P5), not a
    %%     400 fail-closed — the fail-closed check this used to assert here is superseded;
    %%     Mode D's own creation/turn-completion path is covered by
    %%     test/base_components_foreign_investor_conformance.escript (DAG order + Layer-1)
    %%     and test/investor_seam_smoke.escript's live-turn walk. Only smoke that the
    %%     combination is ACCEPTED (202) and lands on the right blueprint/mode here — this
    %%     escript's job is Mode-B regression, not re-proving Mode-D's own turn. ---
    GoodCombo = fh_engine_util:json_encode(#{
        <<"state">> => <<"NSW">>,
        <<"target_price_range">> => [700000, 900000],
        <<"intent">> => <<"investment">>,
        <<"foreign_person">> => true
    }),
    {202, GoodComboResp} = req(post, Base ++ "/plan-cards", [Auth], GoodCombo),
    #{<<"plan_card_id">> := _} = fh_engine_util:json_decode(GoodComboResp),
    io:format("investment+foreign now live (Mode D, mode-d-wedge.md P5) — no regression here~n"),

    io:format("~n==== MODE-B SEAM SMOKE: ALL ASSERTIONS PASSED ====~n"),
    halt(0).

%% The Mode-B foreign-buyer base spine (?BASE_COMPONENTS_FOREIGN, 10 components). Every one is
%% RESOLVER (zero agent_reasoning_required leaves in the base set, disposition and purchase_
%% journey/phase_playbook included — see the module-doc comment above), so each emits exactly
%% THREE compliance_gate events then ONE component_filled, no `usage` at all.
%% 1 + 10x(3 gate + 1 filled) + 1 = 42.
expected_sequence() ->
    Gates = [<<"compliance_gate">>, <<"compliance_gate">>, <<"compliance_gate">>],
    CF = <<"component_filled">>,
    lists:flatten(
      [<<"turn_started">>,
       Gates, CF,   %% buyer_profile
       Gates, CF,   %% family_context
       Gates, CF,   %% firb_workflow
       Gates, CF,   %% mortgage_finance
       Gates, CF,   %% cash_position
       Gates, CF,   %% cross_border_funding
       Gates, CF,   %% ownership_planning
       Gates, CF,   %% disposition
       Gates, CF,   %% purchase_journey
       Gates, CF,   %% phase_playbook
       <<"turn_completed">>]).

%% --- helpers (identical to investor_seam_smoke / seam_smoke) -----------------

mint(TenantId, UserId, Priv) ->
    Now = erlang:system_time(second),
    fh_engine_auth:sign(#{<<"tenant_id">> => TenantId, <<"user_id">> => UserId,
                          <<"iat">> => Now, <<"exp">> => Now + 3600}, Priv).

req(Method, Url, Headers, Body) ->
    Request = case Method of
        get -> {Url, Headers};
        post -> {Url, Headers, "application/json", Body}
    end,
    {ok, {{_, Status, _}, _, Resp}} =
        httpc:request(Method, Request, [], [{body_format, binary}]),
    {Status, Resp}.

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
    after 30000 ->
        error(sse_timeout)
    end.

parse_event_types(Raw) ->
    Frames = binary:split(Raw, <<"\n\n">>, [global]),
    Pairs = lists:filtermap(fun parse_frame/1, Frames),
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
