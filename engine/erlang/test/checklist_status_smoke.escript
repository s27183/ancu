#!/usr/bin/env escript
%%! -sname fh_checklist_status_smoke
%%
%% Live-PG smoke for the card user-set layer's checklist-status slice (005,
%% fh_engine_h_checklist_status, lifecycle-simulation-model.md §7). Closes the
%% honest gap from task 7: proves the migration runner picks up 005 at boot AND the
%% real authenticated PATCH round-trips against the engine DB — the tick (jsonb_set
%% coalesce trick), untick (#- path removal → sparse), the GET sibling field, the
%% audit/SSE `checklist_status_changed` event, fail-closed enum validation, and that
%% a toggle emits NO `usage` (zero-cost user attestation).
%%
%% SIDECAR-FREE: the card is seeded directly in PG (no create turn → no Python).
%%
%% Run from engine/erlang with Docker PG up (engine/compose.yaml, :5433):
%%   ENGINE_DATABASE_URL=postgres://engine:engine_dev_pw@localhost:5433/ancu_engine?sslmode=disable \
%%   ENGINE_DEV_PROVISION=0 ERL_LIBS=_build/default/lib escript test/checklist_status_smoke.escript

-mode(compile).

main(_) ->
    os:putenv("FH_ENGINE_HTTP_PORT", "8093"),
    {ok, _} = application:ensure_all_started(fh_engine),
    {ok, _} = application:ensure_all_started(inets),
    Base = "http://localhost:8093/api/engine",
    io:format("checklist-status smoke — task 7 (live PG, sidecar-free)~n~n"),

    %% === 0. the migration runner picked up 005 at boot ===
    M005 = scalar("SELECT count(*) FROM schema_migrations WHERE version = $1", [<<"005">>]),
    expect(M005 =:= 1, "migration 005_checklist_status applied at boot"),

    %% --- seed tenant + ed25519 key, mint a JWT (the shell's role) ---
    TenantId = fh_engine_util:uuid4(),
    UserId = fh_engine_util:uuid4(),
    {Pub, Priv} = crypto:generate_key(eddsa, ed25519),
    ok = fh_engine_store:upsert_tenant(TenantId, <<"checklist-smoke">>),
    ok = fh_engine_store:add_signing_key(TenantId, <<"ed25519">>, base64:encode(Pub)),
    Auth = {"authorization", "Bearer " ++ binary_to_list(mint(TenantId, UserId, Priv))},

    %% --- seed a card directly (no turn → no sidecar) ---
    Facts = #{<<"onboarding">> => #{<<"state">> => <<"NSW">>}},
    {ok, ProfileId} = fh_engine_store:create_profile(TenantId, UserId, Facts),
    {ok, CardId} = fh_engine_store:create_plan_card(
        TenantId, ProfileId, <<"fhb-domestic-au">>, <<"owner_occupier">>, <<"A">>, #{}),
    io:format("seeded card ~s~n", [CardId]),
    Url = Base ++ "/plan-cards/" ++ binary_to_list(CardId) ++ "/checklist-status",
    CardUrl = Base ++ "/plan-cards/" ++ binary_to_list(CardId),

    %% === 1. fresh card reads as an empty user-set layer (seed = all not_started) ===
    {200, C0} = req(get, CardUrl, [Auth], <<>>),
    #{<<"checklist_status">> := Empty} = fh_engine_util:json_decode(C0),
    expect(Empty =:= #{}, "fresh card: checklist_status is {} (seed reads as not_started)"),

    %% === 2. tick contract/pay_deposit=done → 200, phase obj created, full map back ===
    {S2, R2} = req(patch, Url, [Auth],
                   body(<<"contract">>, <<"pay_deposit">>, <<"done">>)),
    expect(S2 =:= 200, "tick contract/pay_deposit → 200"),
    #{<<"checklist_status">> := M2} = fh_engine_util:json_decode(R2),
    expect(M2 =:= #{<<"contract">> => #{<<"pay_deposit">> => <<"done">>}},
           "response map: {contract:{pay_deposit:done}}"),

    %% === 3. tick a second action in the same phase (phase obj already exists) ===
    {200, R3} = req(patch, Url, [Auth],
                    body(<<"contract">>, <<"review_contract">>, <<"done">>)),
    #{<<"checklist_status">> := M3} = fh_engine_util:json_decode(R3),
    expect(M3 =:= #{<<"contract">> =>
                        #{<<"pay_deposit">> => <<"done">>,
                          <<"review_contract">> => <<"done">>}},
           "second tick coexists in the same phase object"),

    %% === 4. the GET sibling field reflects the writes (not merged into content) ===
    {200, C4} = req(get, CardUrl, [Auth], <<>>),
    Dec4 = fh_engine_util:json_decode(C4),
    expect(maps:get(<<"checklist_status">>, Dec4) =:= M3,
           "GET returns checklist_status as a sibling of content"),
    expect(not maps:is_key(<<"checklist_status">>, maps:get(<<"content">>, Dec4)),
           "content is untouched (status is NOT merged into the computed snapshot)"),

    %% === 5. untick (#- removal → sparse, returns to the not_started seed) ===
    {200, R5} = req(patch, Url, [Auth],
                    body(<<"contract">>, <<"pay_deposit">>, <<"not_started">>)),
    #{<<"checklist_status">> := M5} = fh_engine_util:json_decode(R5),
    expect(M5 =:= #{<<"contract">> => #{<<"review_contract">> => <<"done">>}},
           "untick removes the key (sparse) — pay_deposit back to seed"),

    %% === 6. the audit/SSE event trail — one row per toggle, NO usage ===
    EvCount = scalar("SELECT count(*) FROM plan_card_events WHERE plan_card_id = $1 "
                     "AND type = 'checklist_status_changed'", [CardId]),
    expect(EvCount =:= 3, "three checklist_status_changed events (2 ticks + 1 untick)"),
    UsageCount = scalar("SELECT count(*) FROM plan_card_events WHERE plan_card_id = $1 "
                        "AND type = 'usage'", [CardId]),
    expect(UsageCount =:= 0, "a toggle emits NO usage (zero-cost attestation)"),

    %% === 7. fail-closed enum validation ===
    {S7a, _} = req(patch, Url, [Auth], body(<<"buying">>, <<"x">>, <<"done">>)),
    expect(S7a =:= 400, "unknown phase → 400"),
    {S7b, _} = req(patch, Url, [Auth], body(<<"contract">>, <<"x">>, <<"maybe">>)),
    expect(S7b =:= 400, "unknown status → 400"),
    {S7c, _} = req(patch, Url, [Auth],
                   fh_engine_util:json_encode(#{<<"phase">> => <<"contract">>,
                                                <<"status">> => <<"done">>})),
    expect(S7c =:= 400, "missing action_id → 400"),

    %% === 8. auth + tenant scope ===
    {S8a, _} = req(patch, Url, [], body(<<"contract">>, <<"x">>, <<"done">>)),
    expect(S8a =:= 401, "no token → 401"),
    Bogus = Base ++ "/plan-cards/" ++ binary_to_list(fh_engine_util:uuid4())
            ++ "/checklist-status",
    {S8b, _} = req(patch, Bogus, [Auth], body(<<"contract">>, <<"x">>, <<"done">>)),
    expect(S8b =:= 404, "PATCH a card the tenant doesn't own → 404"),

    %% === 9. wrong method → 405 ===
    {S9, _} = req(post, Url, [Auth], body(<<"contract">>, <<"x">>, <<"done">>)),
    expect(S9 =:= 405, "POST (not PATCH) → 405"),

    io:format("~n==== CHECKLIST-STATUS SMOKE: ALL ASSERTIONS PASSED ====~n"),
    halt(0).

%% --- helpers ----------------------------------------------------------------

body(Phase, ActionId, Status) ->
    fh_engine_util:json_encode(#{<<"phase">> => Phase, <<"action_id">> => ActionId,
                                 <<"status">> => Status}).

mint(TenantId, UserId, Priv) ->
    Now = erlang:system_time(second),
    fh_engine_auth:sign(#{<<"tenant_id">> => TenantId, <<"user_id">> => UserId,
                          <<"iat">> => Now, <<"exp">> => Now + 3600}, Priv).

req(Method, Url, Headers, Body) ->
    Request = case Method of
        get   -> {Url, Headers};
        post  -> {Url, Headers, "application/json", Body};
        patch -> {Url, Headers, "application/json", Body}
    end,
    {ok, {{_, Status, _}, _, Resp}} =
        httpc:request(Method, Request, [], [{body_format, binary}]),
    {Status, Resp}.

scalar(SQL, Params) ->
    #{rows := [{Val}]} = pgo:query(SQL, Params),
    Val.

expect(true, Msg)  -> io:format("  PASS   ~ts~n", [Msg]);
expect(false, Msg) -> io:format("  FAIL   ~ts~n", [Msg]), halt(1).
