#!/usr/bin/env escript
%%! -sname fh_property_assessment_seam
%%
%% Full-stack LIVE smoke for the Mode-C Phase-B property_assessment keystone (Slice A).
%% Boots the engine, seeds a tenant + ed25519 key, mints a JWT, creates an investor plan
%% card (the base turn runs to completion), then ATTACHES a hand-fed property via
%% POST /plan-cards/:id/properties and drives the real per-property turn end-to-end against
%% live PG and the real planner.py sidecar. Asserts: the Phase-B event sequence (one two-path
%% fill), the persisted log, the per-property compliance audit, the addendum snapshot under
%% content.addenda.<pid> (the base content.components untouched — addenda is a sibling), and
%% the genuine keystone proof — the LIVE property_fit_investor outcome: facts COPIED from the
%% card, the agent's rent BAND present, and the gross yield RESOLVER-COMPUTED from band ÷ price
%% (§98 — the only derived figure is not agent-authored). Proves the attach→Phase-B-turn glue.
%%
%% Run LIVE (real Opus sidecar fill — metered) from engine/erlang:
%%
%%   FH_PLANNER_SCRIPT=$(pwd)/../python/planner.py \
%%   FH_SIDECAR_PYTHON=$(pwd)/../../.venv/bin/python3 \
%%   ENGINE_DATABASE_URL=postgres://engine:engine_dev_pw@localhost:5433/firsthomey_engine?sslmode=disable \
%%   ERL_LIBS=_build/default/lib escript test/property_assessment_seam.escript

-mode(compile).

main(_) ->
    os:putenv("FH_ENGINE_HTTP_PORT", "8093"),
    {ok, _} = application:ensure_all_started(fh_engine),
    {ok, _} = application:ensure_all_started(inets),
    Base = "http://localhost:8093/api/engine",

    %% --- seed tenant + ed25519 signing key ---
    TenantId = fh_engine_util:uuid4(),
    UserId = fh_engine_util:uuid4(),
    {Pub, Priv} = crypto:generate_key(eddsa, ed25519),
    ok = fh_engine_store:upsert_tenant(TenantId, <<"property-smoke-tenant">>),
    ok = fh_engine_store:add_signing_key(TenantId, <<"ed25519">>, base64:encode(Pub)),
    Token = mint(TenantId, UserId, Priv),
    Auth = {"authorization", "Bearer " ++ binary_to_list(Token)},

    %% --- create an investor plan card; run the base turn to completion ---
    CreateBody = fh_engine_util:json_encode(#{
        <<"state">> => <<"NSW">>,
        <<"target_price_range">> => [800000, 1000000],
        <<"target_zone">> => [<<"Cabramatta">>, <<"Canley Vale">>],
        <<"intent">> => <<"investment">>
    }),
    {202, CreateResp} = req(post, Base ++ "/plan-cards", [Auth], CreateBody),
    #{<<"plan_card_id">> := PlanCardId} = fh_engine_util:json_decode(CreateResp),
    io:format("created investor plan_card_id=~s~n", [PlanCardId]),
    EvUrl = Base ++ "/plan-cards/" ++ binary_to_list(PlanCardId) ++ "/events",
    BaseTypes = collect_sse(EvUrl, Auth),
    expect(lists:last(BaseTypes) =:= <<"turn_completed">>, "base turn completed"),
    BaseLen = length(BaseTypes),
    io:format("base turn: ~p events~n", [BaseLen]),
    %% The base cursor: a reconnect from 0 would replay the base turn_completed (a terminal
    %% → the SSE handler closes immediately), so the Phase-B stream resumes FROM here
    %% (Last-Event-ID) to replay only the per-property tail — exactly the real SSE reconnect.
    Cursor = scalar("SELECT COALESCE(MAX(event_id),0) FROM plan_card_events "
                    "WHERE plan_card_id = $1", [PlanCardId]),

    %% --- attach a property → run the Phase-B per-property turn ---
    PropBody = fh_engine_util:json_encode(#{
        <<"address">> => <<"12 Park Road, Cabramatta NSW 2166">>,
        <<"suburb">> => <<"Cabramatta">>,
        <<"state">> => <<"NSW">>,
        <<"price">> => 920000,
        <<"property_type">> => <<"established_house">>,
        <<"year_built">> => 1995,
        <<"land_size_sqm">> => 580,
        <<"internal_area_sqm">> => 140,
        <<"bedrooms">> => 3,
        <<"bathrooms">> => 1,
        <<"car_spaces">> => 2
    }),
    {202, AttachResp} = req(post, Base ++ "/plan-cards/" ++ binary_to_list(PlanCardId)
                            ++ "/properties", [Auth], PropBody),
    #{<<"plan_card_id">> := PlanCardId, <<"property_id">> := PropertyId,
      <<"turn_id">> := PhaseBTurn} = fh_engine_util:json_decode(AttachResp),
    expect(is_binary(PropertyId) andalso is_binary(PhaseBTurn), "attach returns property_id + turn_id"),
    io:format("attached property_id=~s~n", [PropertyId]),

    %% --- SSE resumed from the base cursor: the Phase-B turn's events only (one two-path
    %%     component → 3 gate + 1 filled + 1 usage), wrapped by turn_started/turn_completed. ---
    PhaseBUrl = EvUrl ++ "?last_event_id=" ++ integer_to_list(Cursor),
    PhaseB = collect_sse(PhaseBUrl, Auth),
    io:format("phase-B event sequence: ~p~n", [PhaseB]),
    expect(PhaseB =:= expected_phase_b(), "Phase-B event sequence matches (one two-path fill)"),

    %% --- persisted log is the SOT: base + 7 Phase-B events ---
    EventCount = scalar("SELECT count(*) FROM plan_card_events WHERE plan_card_id = $1",
                        [PlanCardId]),
    expect(EventCount =:= BaseLen + 7, "Phase-B added 7 events (1 + 3 gate + 1 filled + 1 usage + 1)"),

    %% --- per-property compliance audit: 3 rows for property_assessment, all clear, two_path,
    %%     ASIC boundary_held (property_assessment is advice_adjacent — it carries a viability verdict) ---
    PaAudit = scalar("SELECT count(*) FROM audit_events WHERE plan_card_id = $1 "
                     "AND component_id = 'property_assessment'", [PlanCardId]),
    expect(PaAudit =:= 3, "3 audit rows for property_assessment (3 gates)"),
    PaClear = scalar("SELECT count(*) FROM audit_events WHERE plan_card_id = $1 "
                     "AND component_id = 'property_assessment' "
                     "AND compliance_jsonb->>'disposition' = 'clear'", [PlanCardId]),
    expect(PaClear =:= 3, "all 3 property_assessment audit rows disposition=clear"),
    PaTwoPath = scalar("SELECT count(*) FROM audit_events WHERE plan_card_id = $1 "
                       "AND component_id = 'property_assessment' AND fill_path = 'two_path'",
                       [PlanCardId]),
    expect(PaTwoPath =:= 3, "property_assessment audit rows are two_path"),
    PaAsic = scalar("SELECT count(*) FROM audit_events WHERE plan_card_id = $1 "
                    "AND component_id = 'property_assessment' "
                    "AND compliance_jsonb->>'gate' = 'asic' "
                    "AND compliance_jsonb->>'detail' = 'decision_support_boundary_held'",
                    [PlanCardId]),
    expect(PaAsic =:= 1, "property_assessment ASIC records boundary_held (advice_adjacent)"),

    %% --- content snapshot: the base components are UNTOUCHED; the addendum holds the
    %%     property_card + the property_assessment outcome under content.addenda.<pid> ---
    {200, CardResp} = req(get, Base ++ "/plan-cards/" ++ binary_to_list(PlanCardId),
                          [Auth], <<>>),
    #{<<"content">> := Content} = fh_engine_util:json_decode(CardResp),
    BaseComponents = maps:get(<<"components">>, Content, #{}),
    expect(map_size(BaseComponents) =:= 8, "base content.components still 8 (addenda is a sibling)"),
    Addenda = maps:get(<<"addenda">>, Content, #{}),
    Addendum = maps:get(PropertyId, Addenda, undefined),
    expect(is_map(Addendum), "addendum present under content.addenda.<property_id>"),
    AttachedCard = maps:get(<<"property_card">>, Addendum, undefined),
    expect(is_map(AttachedCard) andalso maps:get(<<"suburb">>, AttachedCard) =:= <<"Cabramatta">>,
           "addendum carries the attached property_card"),
    PaEntry = maps:get(<<"property_assessment">>,
                       maps:get(<<"components">>, Addendum, #{}), undefined),
    expect(is_map(PaEntry), "property_assessment snapshotted under the addendum"),
    expect(maps:get(<<"scope">>, PaEntry) =:= <<"per-property">>, "snapshot scope=per-property"),
    expect(maps:get(<<"fill_path">>, PaEntry) =:= <<"two_path">>, "snapshot fill_path=two_path"),

    %% --- the keystone proof: the LIVE property_fit_investor outcome ---
    Out = maps:get(<<"outcome">>, PaEntry),
    %% RESOLVER copied the neutral facts verbatim from the attached card.
    expect(maps:get(<<"state">>, Out) =:= <<"NSW">>, "state copied from card"),
    expect(maps:get(<<"suburb">>, Out) =:= <<"Cabramatta">>, "suburb copied from card"),
    expect(maps:get(<<"price">>, Out) =:= 920000, "price copied from card"),
    expect(maps:get(<<"property_type">>, Out) =:= <<"established_house">>, "property_type copied"),
    %% AGENT authored the rent BAND (the one irreducible market estimate) — a [lo, hi] list.
    [Lo, Hi] = maps:get(<<"estimated_weekly_rent_range">>, Out),
    expect(is_number(Lo) andalso is_number(Hi) andalso Lo =< Hi,
           "estimated_weekly_rent_range is a live [lo,hi] band, lo=<hi"),
    %% AGENT verdicts/scores in their enums / 0-10 bounds.
    expect(lists:member(maps:get(<<"viability_verdict">>, Out),
                        [<<"strong_investment">>, <<"acceptable_investment">>,
                         <<"marginal">>, <<"reconsider">>]), "viability_verdict in enum (live)"),
    expect(lists:member(maps:get(<<"capital_growth_outlook">>, Out),
                        [<<"strong">>, <<"moderate">>, <<"flat">>, <<"declining">>]),
           "capital_growth_outlook in enum (live)"),
    expect(lists:member(maps:get(<<"depreciation_attractiveness">>, Out),
                        [<<"strong">>, <<"moderate">>, <<"weak">>]),
           "depreciation_attractiveness in enum (live)"),
    Grade = maps:get(<<"investor_grade_overall">>, Out),
    expect(is_integer(Grade) andalso Grade >= 0 andalso Grade =< 10, "investor_grade_overall 0-10"),
    Land = maps:get(<<"land_quality_score">>, Out),
    expect(is_integer(Land) andalso Land >= 0 andalso Land =< 10, "land_quality_score 0-10"),
    %% bilingual strengths/concerns ({vi,en} arrays).
    Strengths = maps:get(<<"key_strengths">>, Out),
    expect(is_list(Strengths) andalso Strengths =/= [] andalso
           lists:all(fun(S) -> is_map(S) andalso maps:is_key(<<"vi">>, S)
                                   andalso maps:is_key(<<"en">>, S) end, Strengths),
           "key_strengths bilingual {vi,en} (live)"),
    %% §98 PROOF: the gross yield is RESOLVER-COMPUTED from the agent's band ÷ price, NOT
    %% agent-authored — it must equal round1(mid × 52 ÷ price × 100) exactly.
    Yield = maps:get(<<"rental_yield_gross_estimate">>, Out),
    ExpectedYield = round((Lo + Hi) / 2 * 52 / 920000 * 100 * 10) / 10,
    expect(Yield =:= ExpectedYield,
           "rental_yield_gross_estimate = resolver-computed mid-band ÷ price (§98)"),
    io:format("live property_fit: rent=[~p,~p]/wk yield=~p% verdict=~s grade=~p growth=~s~n",
              [Lo, Hi, Yield, maps:get(<<"viability_verdict">>, Out), Grade,
               maps:get(<<"capital_growth_outlook">>, Out)]),

    %% --- auth: missing token -> 401; wrong key -> 403 (attach surface too) ---
    {401, _} = req(post, Base ++ "/plan-cards/" ++ binary_to_list(PlanCardId) ++ "/properties",
                   [], PropBody),
    {_, BadPriv} = crypto:generate_key(eddsa, ed25519),
    BadAuth = {"authorization", "Bearer " ++ binary_to_list(mint(TenantId, UserId, BadPriv))},
    {403, _} = req(post, Base ++ "/plan-cards/" ++ binary_to_list(PlanCardId) ++ "/properties",
                   [BadAuth], PropBody),

    io:format("~n==== PROPERTY_ASSESSMENT SEAM (Slice A): ALL ASSERTIONS PASSED ====~n"),
    halt(0).

%% The Phase-B turn: one two-path component (property_assessment) → 3 compliance_gate, 1
%% component_filled, 1 usage (the sidecar fill), wrapped by turn_started/turn_completed.
expected_phase_b() ->
    [<<"turn_started">>,
     <<"compliance_gate">>, <<"compliance_gate">>, <<"compliance_gate">>,
     <<"component_filled">>, <<"usage">>,
     <<"turn_completed">>].

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
