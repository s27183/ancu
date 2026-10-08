#!/usr/bin/env escript
%%! -sname fh_mode_d_seam_smoke
%%
%% Full-stack LIVE smoke for the Mode-D foreign-investor turn. Clones investor_seam_smoke
%% (Mode C) with intent=investment + foreign_person=true: boots the engine, seeds a
%% tenant + ed25519 signing key, mints a JWT, POSTs plan-card creation, and drives the
%% real /api/engine/* HTTP/SSE surface through the 12-component investor-foreign-au base
%% spine end-to-end — asserting the event sequence, the persisted log, the compliance
%% audit trail (incl. the TWO advice-adjacent ASIC holds Mode D carries that Mode C
%% doesn't — firb_workflow + mortgage_finance), the content_jsonb snapshot (incl. the
%% live LLM-backed foreign-investor outcome shapes + the Mode-D-only misadvice-critical
%% disposition assertion), the live purchase_journey/phase_playbook Mode-D KB branch
%% (2026-07-10, task 10 — extends the spine from 10 to 12 components), cancel
%% idempotency, and auth rejection.
%%
%% Run LIVE (real sidecar fills — metered) from engine/erlang:
%%
%%   ERL_LIBS=_build/default/lib escript test/mode_d_seam_smoke.escript
%%
%% (FH_PLANNER_SCRIPT / FH_SIDECAR_PYTHON / ENGINE_DATABASE_URL come from the repo-root
%% .env, loaded at fh_engine_app boot — see firsthomey-local-dev-env memory.)

-mode(compile).

%% Regulated figures are grounded -> P-7 · One declaration per outcome shape -> The engine -> live smoke catches fixture drift
%% This live full-stack run caught `recommended_lender` vs `recommended_lender_shortlist`
%% AFTER resolver conformance passed, because the conformance fixtures were hand-written to
%% match the buggy Erlang. Measured 2026-07-04 by this smoke (commit 5527b41).

main(_) ->
    os:putenv("FH_ENGINE_HTTP_PORT", "8093"),
    {ok, _} = application:ensure_all_started(fh_engine),
    {ok, _} = application:ensure_all_started(inets),
    Base = "http://localhost:8093/api/engine",

    %% --- seed tenant + ed25519 signing key (the shell's role in production) ---
    TenantId = fh_engine_util:uuid4(),
    UserId = fh_engine_util:uuid4(),
    {Pub, Priv} = crypto:generate_key(eddsa, ed25519),
    ok = fh_engine_store:upsert_tenant(TenantId, <<"mode-d-smoke-tenant">>),
    ok = fh_engine_store:add_signing_key(TenantId, <<"ed25519">>, base64:encode(Pub)),
    Token = mint(TenantId, UserId, Priv),
    Auth = {"authorization", "Bearer " ++ binary_to_list(Token)},

    %% --- POST create plan card: intent=investment + foreign_person=true -> Mode D
    %%     (investor-foreign-au) ---
    CreateBody = fh_engine_util:json_encode(#{
        <<"state">> => <<"NSW">>,
        <<"target_price_range">> => [800000, 1000000],
        <<"target_zone">> => [<<"Cabramatta">>, <<"Canley Vale">>],
        <<"intent">> => <<"investment">>,
        <<"foreign_person">> => true
    }),
    {202, CreateResp} = req(post, Base ++ "/plan-cards", [Auth], CreateBody),
    #{<<"plan_card_id">> := PlanCardId, <<"turn_id">> := TurnId} =
        fh_engine_util:json_decode(CreateResp),
    expect(is_binary(PlanCardId) andalso is_binary(TurnId), "create returns ids"),
    io:format("created plan_card_id=~s~n", [PlanCardId]),

    %% --- SSE stream: collect the turn's events (LIVE sidecar fills -> longer wall-clock;
    %%     the 30s receive-window resets on each 15s keepalive, so a slow fill is fine) ---
    EvUrl = Base ++ "/plan-cards/" ++ binary_to_list(PlanCardId) ++ "/events",
    Types = collect_sse(EvUrl, Auth),
    io:format("event sequence: ~p~n", [Types]),
    expect(Types =:= expected_sequence(), "event sequence matches the Mode-D investor-foreign spine"),

    %% --- persisted event log is the SOT (count matches the stream) ---
    EventCount = scalar("SELECT count(*) FROM plan_card_events WHERE plan_card_id = $1",
                        [PlanCardId]),
    expect(EventCount =:= 53, "53 events persisted (1 + 12x(3 gate + 1 filled) + 3 usage + 1)"),

    %% --- compliance audit trail: one audit_events row per (component, gate) = 3 x 12 = 36,
    %%     every one `clear` on the Mode-D healthy path. ASIC boundary_held lands on BOTH
    %%     firb_workflow (FIRB eligibility/fee framing) AND mortgage_finance (lender fit) —
    %%     advice_adjacent/1 lists both for Mode B/D, unlike Mode C which carries no
    %%     firb_workflow component. tax_structure_non_resident and investment_strategy
    %%     record boundary_held too: their agent-authored entity and strategy leaves are
    %%     advice-adjacent (#27, 2026-10-06). purchase_journey/phase_playbook
    %%     (added task 8) also clear with no_advice_surface — same treatment Mode C's
    %%     equivalents get, neither is in advice_adjacent/1. ---
    AuditCount = scalar("SELECT count(*) FROM audit_events WHERE plan_card_id = $1",
                        [PlanCardId]),
    expect(AuditCount =:= 36, "36 audit_events rows (3 gates x 12 components)"),
    ClearCount = scalar("SELECT count(*) FROM audit_events WHERE plan_card_id = $1 "
                        "AND compliance_jsonb->>'disposition' = 'clear'", [PlanCardId]),
    expect(ClearCount =:= 36, "all 36 audit rows disposition=clear (Mode-D healthy)"),
    AsicHeld = scalar("SELECT count(*) FROM audit_events WHERE plan_card_id = $1 "
                      "AND compliance_jsonb->>'gate' = 'asic' "
                      "AND compliance_jsonb->>'detail' = 'decision_support_boundary_held'",
                      [PlanCardId]),
    expect(AsicHeld =:= 4, "ASIC boundary_held on firb_workflow, mortgage_finance, tax_structure_non_resident, investment_strategy"),
    TwoPathAudit = scalar("SELECT count(*) FROM audit_events WHERE plan_card_id = $1 "
                          "AND fill_path = 'two_path'", [PlanCardId]),
    expect(TwoPathAudit =:= 9, "9 two_path audit rows (3 two-path components x 3 gates)"),

    %% --- FIRB gate actually fired (constraint 10 — the established-dwelling-ban check) ---
    FirbGateRow = scalar("SELECT count(*) FROM audit_events WHERE plan_card_id = $1 "
                         "AND compliance_jsonb->>'gate' = 'firb'", [PlanCardId]),
    expect(FirbGateRow > 0, "FIRB gate fired at least once (Mode D constraint-10 check)"),

    %% --- content_jsonb snapshot holds all 10 Mode-D base components ---
    {200, CardResp} = req(get, Base ++ "/plan-cards/" ++ binary_to_list(PlanCardId),
                          [Auth], <<>>),
    #{<<"content">> := #{<<"components">> := Components}} =
        fh_engine_util:json_decode(CardResp),
    expect(map_size(Components) =:= 12, "12 components snapshotted into content_jsonb"),
    [expect(maps:is_key(N, Components), binary_to_list(N) ++ " component present")
     || N <- [<<"investor_profile_foreign">>, <<"firb_workflow">>, <<"investment_strategy">>,
              <<"mortgage_finance">>, <<"yield_modelling">>, <<"tax_structure_non_resident">>,
              <<"cash_position">>, <<"cross_border_funding">>,
              <<"ownership_planning_foreign_investor">>, <<"disposition">>,
              <<"purchase_journey">>, <<"phase_playbook">>]],

    %% --- the genuine Mode-D proof: the LIVE LLM-backed foreign-investor outcomes actually
    %%     landed (not just that 10 slots exist), AND the misadvice-critical Mode-D-only
    %%     disposition assertion (cgt_status ALWAYS to_verify for a non-resident applicant,
    %%     mode-d-wedge.md P2) holds live, not just in the resolver-level conformance fixture. ---
    Out = fun(N) -> maps:get(<<"outcome">>, maps:get(N, Components)) end,
    Strat = Out(<<"investment_strategy">>),
    expect(is_binary(maps:get(<<"archetype">>, Strat, undefined)), "strategy archetype filled (live)"),
    expect(is_binary(maps:get(<<"gearing_type">>, Strat, undefined)), "strategy gearing_type filled (live)"),
    OL = maps:get(<<"one_liner">>, Strat, undefined),
    expect(is_map(OL) andalso maps:is_key(<<"vi">>, OL) andalso maps:is_key(<<"en">>, OL),
           "strategy one_liner bilingual {vi,en} (live)"),
    Mort = Out(<<"mortgage_finance">>),
    expect(is_binary(maps:get(<<"io_vs_pi_recommendation">>, Mort, undefined)),
           "mortgage io_vs_pi_recommendation filled (live)"),
    RateOptionsNonResident = [<<"variable">>, <<"fixed_1yr">>, <<"fixed_2yr">>, <<"fixed_3yr">>],
    expect(lists:member(maps:get(<<"fixed_vs_variable">>, Mort, undefined), RateOptionsNonResident),
           "mortgage fixed_vs_variable filled (live, reconciled 2026-07-05 — was silently "
           "discarded; Mode D's own 4-option enum, no split_fixed_variable)"),
    Shortlist = maps:get(<<"recommended_lender_shortlist">>, Mort, undefined),
    expect(is_list(Shortlist) andalso length(Shortlist) > 0,
           "mortgage recommended_lender_shortlist filled (live, shortlist shape, not a singular pick)"),
    [TopLender | _] = Shortlist,
    expect(is_binary(maps:get(<<"lender">>, TopLender, undefined)), "shortlist entry has a lender name"),
    expect(is_binary(maps:get(<<"approval_likelihood">>, TopLender, undefined)),
           "shortlist entry has approval_likelihood (schema-as-constraint enum)"),
    LenderReasoning = maps:get(<<"reasoning">>, TopLender, undefined),
    expect(is_map(LenderReasoning) andalso maps:is_key(<<"vi">>, LenderReasoning)
           andalso maps:is_key(<<"en">>, LenderReasoning),
           "shortlist entry reasoning bilingual {vi,en} (live)"),
    Tax = Out(<<"tax_structure_non_resident">>),
    expect(is_binary(maps:get(<<"recommended_entity">>, Tax, undefined)),
           "tax recommended_entity filled (live)"),
    Firb = Out(<<"firb_workflow">>),
    expect(is_boolean(maps:get(<<"blocking_for_contract">>, Firb, undefined)),
           "firb_workflow blocking_for_contract verdict present (constraint-10 gate)"),
    Disp = Out(<<"disposition">>),
    expect(maps:get(<<"cgt_status">>, Disp, undefined) =:= <<"to_verify">>,
           "disposition cgt_status ALWAYS to_verify for Mode D non-resident applicant (misadvice-critical, live)"),
    expect(maps:get(<<"cgt">>, Disp, not_null) =:= null,
           "disposition cgt figure deferred to null (never asserted for a non-resident, live)"),
    expect(maps:is_key(<<"taxable_gain">>, Disp), "disposition still shows taxable_gain (undiscounted)"),
    Cash = Out(<<"cash_position">>),
    expect(not maps:is_key(<<"stamp_duty">>, Cash),
           "cash_position is budget_envelope_investor (no stamp_duty — investor-side discriminator fired)"),
    expect(maps:is_key(<<"regulatory_imposts_total">>, Cash),
           "cash_position has Mode-D regulatory_imposts_total (FIRB fee + surcharge + duty rollup)"),
    expect(not maps:is_key(<<"lmi_payable">>, Cash),
           "cash_position drops Mode-C's lmi_payable (Mode-D field-set divergence)"),
    io:format("live foreign-investor outcomes: archetype=~s gearing=~s io_vs_pi=~s rate=~s entity=~s cgt_status=~s~n",
              [maps:get(<<"archetype">>, Strat), maps:get(<<"gearing_type">>, Strat),
               maps:get(<<"io_vs_pi_recommendation">>, Mort),
               maps:get(<<"fixed_vs_variable">>, Mort),
               maps:get(<<"recommended_entity">>, Tax),
               maps:get(<<"cgt_status">>, Disp)]),

    %% --- purchase_journey/phase_playbook (task 8): proves the Mode-D KB branch actually
    %%     fires over the real HTTP/SSE surface, not a silent fallthrough to Mode A's
    %%     fill_fhb/{?ACTIONS,?RISKS} default (the fail-*silent* risk task 8 flagged and
    %%     verified statically — this is the live confirmation). Six-actor set is REUSED
    %%     from Mode C unchanged (kb.journey.investor-foreign-path's own rationale); the
    %%     dispose phase is honestly absent (no hold horizon set at base, same honest-
    %%     partial rule every mode's journey follows); the contract-phase action proves
    %%     the FIRB-specific phase-actions doc (kb.journey.investor-foreign-phase-actions),
    %%     not Mode C's investor-domestic content, is what actually resolved. ---
    Journey = Out(<<"purchase_journey">>),
    JActorIds = [maps:get(<<"id">>, A) || A <- maps:get(<<"actors">>, Journey, [])],
    expect(lists:sort(JActorIds) =:=
             lists:sort([<<"you">>, <<"government">>, <<"lender">>,
                         <<"property_manager">>, <<"tenant">>, <<"services">>]),
           "purchase_journey six-actor set, reused from Mode C unchanged (live)"),
    JPhaseIds = [maps:get(<<"id">>, P) || P <- maps:get(<<"phases">>, Journey, [])],
    expect(lists:member(<<"contract">>, JPhaseIds),
           "purchase_journey has the contract phase (FIRB gate narrated here)"),
    expect(not lists:member(<<"dispose">>, JPhaseIds),
           "purchase_journey has NO dispose phase (no hold horizon set at base, honest-partial)"),
    Playbook = Out(<<"phase_playbook">>),
    PbPhases = maps:get(<<"phases">>, Playbook, []),
    expect(length(PbPhases) > 0, "phase_playbook has phases (Mode-D foreign-investor KB content live)"),
    ContractPbPhase = hd([P || P <- PbPhases, maps:get(<<"phase">>, P) =:= <<"contract">>]),
    ContractActionIds = [maps:get(<<"id">>, A) || A <- maps:get(<<"actions">>, ContractPbPhase, [])],
    expect(lists:member(<<"submit_firb_application">>, ContractActionIds),
           "phase_playbook contract-phase carries the Mode-D submit_firb_application action "
           "(kb.journey.investor-foreign-phase-actions, live — not Mode C's content)"),
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

    io:format("~n==== MODE-D SEAM SMOKE: ALL ASSERTIONS PASSED ====~n"),
    halt(0).

%% The Mode-D foreign-investor base spine (?BASE_COMPONENTS_FOREIGN_INVESTOR, 12 components
%% since task 8 appended purchase_journey/phase_playbook). Each emits THREE compliance_gate
%% events before its component_filled; the THREE two-path components (investment_strategy,
%% mortgage_finance, tax_structure_non_resident) each emit a `usage` right after their fill,
%% from the sidecar. Order is discriminator-load-bearing (firb_workflow before mortgage/cash
%% so their FIRB reads are grounded; strategy before mortgage; tax before cash/disposition);
%% purchase_journey/phase_playbook run LAST, after disposition — appended at the tail per
%% task 8's own DAG note (Mode D's ownership_planning_foreign_investor already runs BEFORE
%% disposition here, the reverse of Mode C's order, so no reordering of the existing 10 was
%% needed, only an append).
%% 1 + 12x(3 gate + 1 filled) + 3 usage + 1 = 53.
expected_sequence() ->
    Gates = [<<"compliance_gate">>, <<"compliance_gate">>, <<"compliance_gate">>],
    CF = <<"component_filled">>,
    U = <<"usage">>,
    lists:flatten(
      [<<"turn_started">>,
       Gates, CF,           %% investor_profile_foreign             (resolver)
       Gates, CF,           %% firb_workflow                        (resolver)
       Gates, CF, U,        %% investment_strategy                  (two_path)
       Gates, CF, U,        %% mortgage_finance                     (two_path)
       Gates, CF,           %% yield_modelling                      (resolver)
       Gates, CF, U,        %% tax_structure_non_resident           (two_path)
       Gates, CF,           %% cash_position                        (resolver)
       Gates, CF,           %% cross_border_funding                 (resolver)
       Gates, CF,           %% ownership_planning_foreign_investor  (resolver)
       Gates, CF,           %% disposition                          (resolver)
       Gates, CF,           %% purchase_journey                     (resolver)
       Gates, CF,           %% phase_playbook                       (resolver)
       <<"turn_completed">>]).

%% --- helpers (identical to investor_seam_smoke) ------------------------------

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
