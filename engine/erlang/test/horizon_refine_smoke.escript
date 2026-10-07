#!/usr/bin/env escript
%%! -sname fh_horizon_refine_smoke
%%
%% Live-PG smoke: a hold-horizon refine proven through the commit seam (engine-contract
%% §10.2/§10.5). refine_smoke proves a target_price commit by polling the log; this one
%% proves the horizon what-if the way the frontend sees it — over the SSE stream from the
%% pre-refine cursor — and that the committed disposition equals the preview.
%%
%% Reproducible -> P-5 · Metering, not gating -> Mechanisms -> a horizon refine streams its commit and meters nothing
%%
%% Sidecar-free like refine_smoke (a refine is a resolver-only turn; the card is seeded in
%% PG). Run through the allowlist: `bash scripts/live_smoke.sh horizon_refine_smoke`.

-mode(compile).

main(_) ->
    os:putenv("FH_ENGINE_HTTP_PORT", "8093"),
    {ok, _} = application:ensure_all_started(fh_engine),
    {ok, _} = application:ensure_all_started(inets),
    Base = "http://localhost:8093/api/engine",
    io:format("horizon refine smoke — commit seam over SSE (live PG, sidecar-free)~n~n"),

    TenantId = fh_engine_util:uuid4(),
    UserId = fh_engine_util:uuid4(),
    {Pub, Priv} = crypto:generate_key(eddsa, ed25519),
    ok = fh_engine_store:upsert_tenant(TenantId, <<"horizon-refine-smoke">>),
    ok = fh_engine_store:add_signing_key(TenantId, <<"ed25519">>, base64:encode(Pub)),
    Auth = {"authorization", "Bearer " ++ binary_to_list(mint(TenantId, UserId, Priv))},

    %% --- seed a card directly (no create turn → no sidecar), as refine_smoke does ---
    SeedOnboarding = #{<<"state">> => <<"NSW">>,
                       <<"target_price_range">> => [600000, 600000],
                       <<"target_zone">> => [],
                       <<"intent">> => <<"owner_occupier">>},
    {ok, SeedOutcomes} = fh_engine_simulate:run(<<"fhb-domestic-au">>, SeedOnboarding, <<"owner_occupier">>),
    Facts = #{<<"onboarding">> => SeedOnboarding,
              <<"derived">> => #{<<"firb_required_any">> => false}},
    {ok, ProfileId} = fh_engine_store:create_profile(TenantId, UserId, Facts),
    Content = #{<<"components">> => #{
        <<"mortgage_finance">> =>
            #{<<"outcome">> => maps:get(<<"mortgage_plan">>, SeedOutcomes),
              <<"renderer">> => <<"summary-card">>}}},
    {ok, CardId} = fh_engine_store:create_plan_card(
        TenantId, ProfileId, <<"fhb-domestic-au">>, <<"owner_occupier">>, <<"A">>, Content),
    io:format("seeded card ~s~n", [CardId]),
    Url = Base ++ "/plan-cards/" ++ binary_to_list(CardId),

    %% the unset baseline vs the H=10 preview — the commit must equal the preview.
    Baseline = maps:get(<<"disposition">>, SeedOutcomes),
    {ok, OvOnboarding} = fh_engine_simulate:apply_overrides(#{<<"horizon">> => 10}, SeedOnboarding),
    {ok, OvOutcomes} = fh_engine_simulate:run(<<"fhb-domestic-au">>, OvOnboarding, <<"owner_occupier">>),
    Preview = maps:get(<<"disposition">>, OvOutcomes),
    expect(maps:get(<<"horizon_years">>, Preview) =:= 10, "precondition: the preview's disposition holds horizon_years 10"),
    expect(Preview =/= Baseline, "precondition: the H=10 preview differs from the unset baseline"),

    %% the cursor: the stream is read from the log's high-water mark before the refine,
    %% so it carries exactly the refine turn's events.
    Cursor = scalar("SELECT coalesce(max(event_id), 0) FROM plan_card_events "
                    "WHERE plan_card_id = $1", [CardId]),

    %% === Expect 1: refine {horizon:10} → 202; the overlay holds hold_horizon_years 10 ===
    {S1, R1} = req(post, Url ++ "/refine", [Auth],
                   fh_engine_util:json_encode(#{<<"overrides">> => #{<<"horizon">> => 10}})),
    expect(S1 =:= 202, "refine {horizon:10} → 202"),
    #{<<"plan_card_id">> := CardId} = fh_engine_util:json_decode(R1),
    OverlayH = scalar("SELECT target_jsonb->>'hold_horizon_years' FROM plan_cards "
                      "WHERE plan_card_id = $1", [CardId]),
    expect(OverlayH =:= <<"10">>, "target_jsonb overlay holds hold_horizon_years 10"),

    %% === Expect 2: SSE from the cursor → disposition filled at H=10, turn_completed, no usage ===
    Events = collect_sse(Url ++ "/events", [Auth, {"last-event-id", integer_to_list(Cursor)}]),
    Types = [T || {T, _} <- Events],
    io:format("  stream: ~p event(s), last ~s~n", [length(Types), lists:last(Types)]),
    expect(lists:last(Types) =:= <<"turn_completed">>, "the stream ends on turn_completed"),
    expect(not lists:member(<<"usage">>, Types), "no usage event on the stream (resolver-only, P-5)"),
    StreamedDisp = [maps:get(<<"outcome">>, P) || {<<"component_filled">>, P} <- Events,
                    maps:get(<<"component_id">>, P, undefined) =:= <<"disposition">>],
    expect(length(StreamedDisp) =:= 1, "exactly one component_filled for disposition streamed"),
    [Streamed] = StreamedDisp,
    expect(maps:get(<<"horizon_years">>, Streamed) =:= 10, "the streamed disposition carries horizon_years 10"),
    UsageCount = scalar("SELECT count(*) FROM plan_card_events "
                        "WHERE plan_card_id = $1 AND type = 'usage'", [CardId]),
    expect(UsageCount =:= 0, "the log holds no usage event for the card"),

    %% === Expect 3: GET card → disposition equals the H=10 preview, differs from baseline ===
    {200, CardResp} = req(get, Url, [Auth], <<>>),
    #{<<"content">> := #{<<"components">> := Comps}} = fh_engine_util:json_decode(CardResp),
    Committed = maps:get(<<"outcome">>, maps:get(<<"disposition">>, Comps)),
    expect(Committed =:= Preview, "committed disposition == fh_engine_simulate:run at H=10 (preview parity)"),
    expect(Committed =/= Baseline, "committed disposition differs from the unset baseline"),
    expect(Committed =:= Streamed, "committed disposition == the streamed one"),

    %% === Expect 4: {horizon:0} → 400 ===
    {S4, _} = req(post, Url ++ "/refine", [Auth],
                  fh_engine_util:json_encode(#{<<"overrides">> => #{<<"horizon">> => 0}})),
    expect(S4 =:= 400, "refine {horizon:0} → 400"),

    io:format("~n==== HORIZON REFINE SMOKE: ALL ASSERTIONS PASSED ====~n"),
    halt(0).

%% --- helpers ----------------------------------------------------------------

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

%% The handler closes the stream after the terminal event, so read to stream_end.
collect_sse(Url, Headers) ->
    {ok, ReqId} = httpc:request(get, {Url, Headers}, [], [{sync, false}, {stream, self}]),
    parse_events(sse_loop(ReqId, <<>>)).

sse_loop(ReqId, Acc) ->
    receive
        {http, {ReqId, stream_start, _}} -> sse_loop(ReqId, Acc);
        {http, {ReqId, stream, Chunk}} -> sse_loop(ReqId, <<Acc/binary, Chunk/binary>>);
        {http, {ReqId, stream_end, _}} -> Acc;
        {http, {ReqId, {error, Reason}}} -> error({sse_error, Reason})
    after 30000 -> error(sse_timeout)
    end.

%% [{Type, Payload}] in stream order, deduped on the event id.
parse_events(Raw) ->
    Frames = binary:split(Raw, <<"\n\n">>, [global]),
    {_, Rev} = lists:foldl(fun(F, {Seen, Acc}) ->
        case parse_frame(F) of
            false -> {Seen, Acc};
            {Id, Type, Data} ->
                case sets:is_element(Id, Seen) of
                    true -> {Seen, Acc};
                    false -> {sets:add_element(Id, Seen), [{Type, Data} | Acc]}
                end
        end
    end, {sets:new(), []}, Frames),
    lists:reverse(Rev).

parse_frame(Frame) ->
    case re:run(Frame, <<"event: (.+)">>, [{capture, [1], binary}]) of
        {match, [Type]} ->
            Id = case re:run(Frame, <<"id: (\\d+)">>, [{capture, [1], binary}]) of
                     {match, [I]} -> binary_to_integer(I);
                     nomatch -> 0
                 end,
            Data = case re:run(Frame, <<"data: (.+)">>, [{capture, [1], binary}]) of
                       {match, [D]} -> fh_engine_util:json_decode(D);
                       nomatch -> #{}
                   end,
            {Id, Type, Data};
        nomatch -> false
    end.

scalar(SQL, Params) ->
    #{rows := [{Val}]} = pgo:query(SQL, Params),
    Val.

expect(true, Msg)  -> io:format("  PASS   ~ts~n", [Msg]);
expect(false, Msg) -> io:format("  FAIL   ~ts~n", [Msg]), halt(1).
