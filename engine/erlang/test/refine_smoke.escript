#!/usr/bin/env escript
%%! -sname fh_refine_smoke
%%
%% Live-PG smoke for W7b — the refine COMMIT path (engine-contract §10.2/§10.3,
%% lifecycle-simulation-model.md §4.3, fh_engine_h_refine). The companion to
%% simulate_smoke (which proves the PREVIEW below the seam): this drives the real
%% authenticated HTTP surface against Docker PG and asserts what only PG can show —
%% the plan-target overlay round-trip + the committed snapshot.
%%
%% SIDECAR-FREE by construction: refine is a base_resolver turn (resolver-only, the
%% two-path sidecar is skipped and the stored agent leaf re-attached), so unlike
%% seam_smoke this needs NO Python planner. The card is SEEDED directly in PG (not via
%% POST /plan-cards, which would run a full base turn needing the sidecar).
%%
%% Run from engine/erlang with Docker PG up (engine/compose.yaml, :5433):
%%   ENGINE_DATABASE_URL=postgres://engine:engine_dev_pw@localhost:5433/firsthomey_engine?sslmode=disable \
%%   ENGINE_DEV_PROVISION=0 ERL_LIBS=_build/default/lib escript test/refine_smoke.escript

-mode(compile).

main(_) ->
    os:putenv("FH_ENGINE_HTTP_PORT", "8092"),
    {ok, _} = application:ensure_all_started(fh_engine),
    {ok, _} = application:ensure_all_started(inets),
    Base = "http://localhost:8092/api/engine",
    io:format("refine smoke — W7b commit path (live PG, sidecar-free)~n~n"),

    %% --- seed tenant + ed25519 key, mint a JWT (the shell's role) ---
    TenantId = fh_engine_util:uuid4(),
    UserId = fh_engine_util:uuid4(),
    {Pub, Priv} = crypto:generate_key(eddsa, ed25519),
    ok = fh_engine_store:upsert_tenant(TenantId, <<"refine-smoke">>),
    ok = fh_engine_store:add_signing_key(TenantId, <<"ed25519">>, base64:encode(Pub)),
    Auth = {"authorization", "Bearer " ++ binary_to_list(mint(TenantId, UserId, Priv))},

    %% --- seed a card directly (bypass the create turn → no sidecar) ---
    %% target_zone [] so projection_state takes its pure NSW step-3 branch; the seed
    %% mortgage_plan is what a real create would compute, so the skipped two-path
    %% component re-attaches a realistic outcome.
    SeedOnboarding = #{<<"state">> => <<"NSW">>,
                       <<"target_price_range">> => [600000, 600000],
                       <<"target_zone">> => [],
                       <<"intent">> => <<"owner_occupier">>},
    {ok, SeedOutcomes} = fh_engine_simulate:run(<<"fhb-domestic-au">>, SeedOnboarding, <<"owner_occupier">>),
    SeedMortgage = maps:get(<<"mortgage_plan">>, SeedOutcomes),
    Facts = #{<<"onboarding">> => SeedOnboarding,
              <<"derived">> => #{<<"firb_required_any">> => false}},
    {ok, ProfileId} = fh_engine_store:create_profile(TenantId, UserId, Facts),
    Content = #{<<"components">> => #{
        <<"mortgage_finance">> =>
            #{<<"outcome">> => SeedMortgage, <<"renderer">> => <<"summary-card">>}}},
    {ok, CardId} = fh_engine_store:create_plan_card(
        TenantId, ProfileId, <<"fhb-domestic-au">>, <<"owner_occupier">>, <<"A">>, Content),
    io:format("seeded card ~s (no turn yet)~n", [CardId]),
    Url = Base ++ "/plan-cards/" ++ binary_to_list(CardId),

    %% the baseline budget (seed price) and the expected post-refine budget (preview of
    %% the overridden onboarding) — the commit must MATCH the preview (parity) and DIFFER
    %% from the baseline (the override flowed through).
    SeedBudget = maps:get(<<"budget_envelope">>, SeedOutcomes),
    {ok, OvOnboarding} =
        fh_engine_simulate:apply_overrides(#{<<"target_price">> => 900000}, SeedOnboarding),
    {ok, OvOutcomes} = fh_engine_simulate:run(<<"fhb-domestic-au">>, OvOnboarding, <<"owner_occupier">>),
    PreviewBudget = maps:get(<<"budget_envelope">>, OvOutcomes),
    expect(PreviewBudget =/= SeedBudget, "precondition: $900k preview differs from $600k baseline"),

    %% === 1. refine with a target_price what-if → 202 + overlay persisted ===
    {S1, R1} = req(post, Url ++ "/refine", [Auth],
                   fh_engine_util:json_encode(#{<<"overrides">> =>
                       #{<<"target_price">> => 900000}})),
    expect(S1 =:= 202, "refine target_price → 202"),
    #{<<"turn_id">> := _T1, <<"plan_card_id">> := CardId} = fh_engine_util:json_decode(R1),

    %% the overlay (plan.target) is written synchronously before the 202 → assert it now.
    OverlayRange = scalar("SELECT target_jsonb->'target_price_range' FROM plan_cards "
                          "WHERE plan_card_id = $1", [CardId]),
    expect(OverlayRange =:= <<"[900000, 900000]">>,
           "target_jsonb overlay holds the band→point [900000,900000]"),

    %% the overlay round-trips through the read path: the effective onboarding is overridden.
    {ok, Ctx} = fh_engine_store:get_card_rerun_context(CardId),
    EffRange = maps:get(<<"target_price_range">>,
                        maps:get(<<"onboarding">>, maps:get(facts, Ctx))),
    expect(EffRange =:= [900000, 900000],
           "get_card_rerun_context overlays the saved scenario onto onboarding"),

    %% === 2. the committed snapshot — resolver-only + flow-through + preview parity ===
    ok = await_completed(CardId),
    UsageCount = scalar("SELECT count(*) FROM plan_card_events "
                        "WHERE plan_card_id = $1 AND type = 'usage'", [CardId]),
    expect(UsageCount =:= 0, "resolver-only commit emitted NO usage (§10.2 no-meter)"),

    {200, CardResp} = req(get, Url, [Auth], <<>>),
    #{<<"content">> := #{<<"components">> := Comps}} = fh_engine_util:json_decode(CardResp),
    CommitBudget = maps:get(<<"outcome">>, maps:get(<<"cash_position">>, Comps)),
    expect(CommitBudget =/= SeedBudget,
           "the $900k override FLOWED THROUGH to the committed budget envelope"),
    expect(CommitBudget =:= PreviewBudget,
           "commit == preview (the saved snapshot matches what simulate would show)"),
    expect(maps:is_key(<<"mortgage_finance">>, Comps),
           "the skipped two-path mortgage_finance is preserved in the snapshot"),

    %% === 3. cumulative refine: a state what-if on the already-refined card ===
    {S3, _} = req(post, Url ++ "/refine", [Auth],
                  fh_engine_util:json_encode(#{<<"overrides">> => #{<<"state">> => <<"VIC">>}})),
    expect(S3 =:= 202, "a second refine (state=VIC) on the refined card → 202"),
    OverlayState = scalar("SELECT target_jsonb->>'state' FROM plan_cards "
                          "WHERE plan_card_id = $1", [CardId]),
    expect(OverlayState =:= <<"VIC">>, "state override accumulated into the overlay"),
    OverlayPriceStill = scalar("SELECT target_jsonb->'target_price_range' FROM plan_cards "
                               "WHERE plan_card_id = $1", [CardId]),
    expect(OverlayPriceStill =:= <<"[900000, 900000]">>,
           "the earlier $900k survives the state refine (cumulative, not reset)"),
    ok = await_completed_n(CardId, 2),

    %% === 4. override rejects (same atoms as /simulate) ===
    {S4a, _} = req(post, Url ++ "/refine", [Auth],
                   fh_engine_util:json_encode(#{<<"overrides">> =>
                       #{<<"property_type">> => <<"apartment">>}})),
    expect(S4a =:= 400, "property_type → 400 (Phase-B, rejected not silently dropped)"),
    {S4b, _} = req(post, Url ++ "/refine", [Auth],
                   fh_engine_util:json_encode(#{<<"overrides">> => #{<<"foo">> => 1}})),
    expect(S4b =:= 400, "unknown override key → 400"),

    %% === 5. auth + scope ===
    {S5a, _} = req(post, Url ++ "/refine", [],
                   fh_engine_util:json_encode(#{<<"overrides">> => #{}})),
    expect(S5a =:= 401, "no token → 401"),
    Bogus = Base ++ "/plan-cards/" ++ binary_to_list(fh_engine_util:uuid4()) ++ "/refine",
    {S5b, _} = req(post, Bogus, [Auth],
                   fh_engine_util:json_encode(#{<<"overrides">> => #{}})),
    expect(S5b =:= 404, "refine on a card the tenant doesn't own → 404"),

    io:format("~n==== REFINE SMOKE: ALL ASSERTIONS PASSED ====~n"),
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

%% Poll the event log until the (first) turn reaches a terminal event. Resolver-only
%% turns are fast, but async — so we await rather than race the GET.
await_completed(CardId) -> await_completed_n(CardId, 1).

await_completed_n(CardId, NTurns) -> await_completed_n(CardId, NTurns, 100).
await_completed_n(_CardId, _NTurns, 0) -> error(turn_did_not_complete);
await_completed_n(CardId, NTurns, Tries) ->
    Done = scalar("SELECT count(*) FROM plan_card_events WHERE plan_card_id = $1 "
                  "AND type IN ('turn_completed','turn_failed')", [CardId]),
    case Done >= NTurns of
        true  -> ok;
        false -> timer:sleep(100), await_completed_n(CardId, NTurns, Tries - 1)
    end.

scalar(SQL, Params) ->
    #{rows := [{Val}]} = pgo:query(SQL, Params),
    Val.

expect(true, Msg)  -> io:format("  PASS   ~ts~n", [Msg]);
expect(false, Msg) -> io:format("  FAIL   ~ts~n", [Msg]), halt(1).
