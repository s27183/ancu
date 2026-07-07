#!/usr/bin/env escript
%%! -sname fh_news_smoke
%%
%% Live-PG smoke for the KB news feature (kb_compiler.py GATE 11, fh_engine_kb
%% news_for_slugs/1, fh_engine_h_news, migration 007). Proves: migration 007
%% applies at boot; a card's accumulated kb_versions (via a real
%% fh_engine_kb:kb_anchors/1 shape) correctly matches the compiled
%% kb.news.2026-07-hecs-thresholds-2026-27 note (whose affected_kb_slugs is
%% [kb.hecs.thresholds]); the GET relevance filter; the PATCH dismiss round-trip
%% (jsonb_set, the news_dismissed audit/SSE event); and fail-closed auth/tenant/
%% method/field cases.
%%
%% SIDECAR-FREE: the card is seeded directly in PG, and its kb_versions
%% provenance is seeded via a direct append_audit/6 call (no turn → no Python) —
%% the same shape fh_engine_turn stamps on a real fill.
%%
%% Run from engine/erlang with Docker PG up (engine/compose.yaml, :5433) and the
%% artifact compiled (engine/build/kb_compiler.py, so priv/kb/artifact.json
%% carries the HECS news note):
%%   ENGINE_DATABASE_URL=postgres://engine:engine_dev_pw@localhost:5433/firsthomey_engine?sslmode=disable \
%%   ENGINE_DEV_PROVISION=0 ERL_LIBS=_build/default/lib escript test/news_smoke.escript

-mode(compile).

-define(NEWS_SLUG, <<"kb.news.2026-07-hecs-thresholds-2026-27">>).
-define(KB_SLUG, <<"kb.hecs.thresholds">>).

main(_) ->
    os:putenv("FH_ENGINE_HTTP_PORT", "8094"),
    {ok, _} = application:ensure_all_started(fh_engine),
    {ok, _} = application:ensure_all_started(inets),
    Base = "http://localhost:8094/api/engine",
    io:format("news smoke (live PG, sidecar-free)~n~n"),

    %% === 0. the migration runner picked up 007 at boot ===
    M007 = scalar("SELECT count(*) FROM schema_migrations WHERE version = $1", [<<"007">>]),
    expect(M007 =:= 1, "migration 007_news_dismissed applied at boot"),

    %% === 0b. the compiled artifact carries the HECS news note ===
    NewsArtifact = fh_engine_kb:news_for_slugs([?KB_SLUG]),
    expect(lists:any(fun(E) -> maps:get(<<"news_slug">>, E) =:= ?NEWS_SLUG end, NewsArtifact),
           "artifact news_for_slugs([kb.hecs.thresholds]) includes the HECS note"),

    %% --- seed tenant + ed25519 key, mint a JWT (the shell's role) ---
    TenantId = fh_engine_util:uuid4(),
    UserId = fh_engine_util:uuid4(),
    {Pub, Priv} = crypto:generate_key(eddsa, ed25519),
    ok = fh_engine_store:upsert_tenant(TenantId, <<"news-smoke">>),
    ok = fh_engine_store:add_signing_key(TenantId, <<"ed25519">>, base64:encode(Pub)),
    Auth = {"authorization", "Bearer " ++ binary_to_list(mint(TenantId, UserId, Priv))},

    %% --- seed a card + its provenance directly (no turn → no sidecar) ---
    Facts = #{<<"onboarding">> => #{<<"state">> => <<"NSW">>}},
    {ok, ProfileId} = fh_engine_store:create_profile(TenantId, UserId, Facts),
    {ok, CardId} = fh_engine_store:create_plan_card(
        TenantId, ProfileId, <<"fhb-domestic-au">>, <<"owner_occupier">>, <<"A">>, #{}),
    io:format("seeded card ~s~n", [CardId]),
    Url = Base ++ "/plan-cards/" ++ binary_to_list(CardId) ++ "/news",

    %% === 1. a card with NO fills yet has consulted no KB slugs → no news ===
    {200, R1} = req(get, Url, [Auth], <<>>),
    #{<<"news">> := []} = fh_engine_util:json_decode(R1),
    io:format("  PASS   fresh card (no fills): news is []~n"),

    %% === 2. stamp the same kb_anchors shape a real fill would (buyer_profile
    %%    consulted kb.hecs.thresholds) ===
    KbVersions = fh_engine_kb:kb_anchors([?KB_SLUG]),
    ok = fh_engine_store:append_audit(
        TenantId, CardId, <<"buyer_profile">>, <<"resolver">>, KbVersions, #{}),

    %% === 3. GET now surfaces the relevant note ===
    {200, R3} = req(get, Url, [Auth], <<>>),
    #{<<"news">> := [Item]} = fh_engine_util:json_decode(R3),
    expect(maps:get(<<"news_slug">>, Item) =:= ?NEWS_SLUG,
           "after a fill consulting kb.hecs.thresholds: GET returns the HECS note"),
    expect(maps:get(<<"kb_slug">>, Item) =:= ?KB_SLUG, "note carries its kb_slug"),
    expect(maps:is_key(<<"summary_en">>, Item) andalso maps:is_key(<<"summary_vi">>, Item),
           "note carries bilingual summaries"),

    %% === 4. PATCH dismiss → 200, dismissed_news reflects it ===
    {200, R4} = req(patch, Url, [Auth], body(?NEWS_SLUG)),
    #{<<"dismissed_news">> := Dismissed} = fh_engine_util:json_decode(R4),
    expect(maps:get(?NEWS_SLUG, Dismissed, false) =:= true,
           "PATCH dismiss: dismissed_news carries the slug"),

    %% === 5. GET again: the dismissed note no longer appears ===
    {200, R5} = req(get, Url, [Auth], <<>>),
    #{<<"news">> := []} = fh_engine_util:json_decode(R5),
    io:format("  PASS   after dismiss: GET returns [] (relevant-but-dismissed filtered)~n"),

    %% === 6. the audit/SSE event trail — one news_dismissed row ===
    EvCount = scalar("SELECT count(*) FROM plan_card_events WHERE plan_card_id = $1 "
                     "AND type = 'news_dismissed'", [CardId]),
    expect(EvCount =:= 1, "one news_dismissed event appended"),

    %% === 7. fail-closed: missing news_slug, auth, tenant scope, method ===
    {S7a, _} = req(patch, Url, [Auth],
                   fh_engine_util:json_encode(#{<<"other_field">> => <<"x">>})),
    expect(S7a =:= 400, "missing news_slug → 400"),
    {S7b, _} = req(get, Url, [], <<>>),
    expect(S7b =:= 401, "no token → 401"),
    Bogus = Base ++ "/plan-cards/" ++ binary_to_list(fh_engine_util:uuid4()) ++ "/news",
    {S7c, _} = req(get, Bogus, [Auth], <<>>),
    expect(S7c =:= 404, "GET a card the tenant doesn't own → 404"),
    {S7d, _} = req(post, Url, [Auth], body(?NEWS_SLUG)),
    expect(S7d =:= 405, "POST (not GET/PATCH) → 405"),

    io:format("~n==== NEWS SMOKE: ALL ASSERTIONS PASSED ====~n"),
    halt(0).

%% --- helpers ----------------------------------------------------------------

body(NewsSlug) ->
    fh_engine_util:json_encode(#{<<"news_slug">> => NewsSlug}).

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
