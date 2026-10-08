#!/usr/bin/env escript
%%! -sname fh_shell_news_proxy_smoke
%%
%% The shell's PUBLIC /api/news proxy feeding the homepage KB-news ticker
%% (kb-news-feature.md "Homepage ticker", 2026-07-08) over the FULL HTTP path —
%% frontend → shell backend (:8081) → engine GET /api/engine/news
%% (fh_engine_h_news_feed) → relayed verbatim. Same shape as
%% suburbs_proxy_smoke.escript: this drives the cowboy handler (route, the anon
%% tenant-JWT mint, the relay of status + body, the 405), not just the client
%% function.
%%
%% PUBLIC posture: no user JWT — the homepage ticker is pre-login chrome, and
%% news notes are global KB content, unfiltered by any one card's relevance
%% (distinct from GET /api/plan-cards/:id/news, covered by plancard_proxy_smoke,
%% which stays card-scoped and dismissable).
%%
%% Same dual-app caveat as suburbs_proxy_smoke: boots the engine app (its pool +
%% the /api/engine/news endpoint) and stands up ONLY the shell's cowboy listener
%% via fh_shell_http:routes/0 — not the full shell app (its `default` pool would
%% clash with the engine's). Needs the engine build lib + the engine's dev
%% Postgres (5433) with the KB artifact compiled (so it carries the HECS note).
%% Run from shell/web/backend:
%%
%%   ENGINE_DATABASE_URL=postgres://engine:engine_dev_pw@localhost:5433/ancu_engine?sslmode=disable \
%%   ERL_LIBS=_build/default/lib:../../../engine/erlang/_build/default/lib \
%%   escript test/news_proxy_smoke.escript

-mode(compile).

-define(NEWS_SLUG, <<"kb.news.2026-07-hecs-thresholds-2026-27">>).

main(_) ->
    %% --- boot the engine on its own port + provision the shell's signing key ---
    os:putenv("FH_ENGINE_HTTP_PORT", "8095"),
    {ok, _} = application:ensure_all_started(fh_engine),
    {ok, _} = application:ensure_all_started(inets),

    TenantId = fh_engine_util:uuid4(),
    {Pub, Priv} = crypto:generate_key(eddsa, ed25519),
    ok = fh_engine_store:upsert_tenant(TenantId, <<"shell-web">>),
    ok = fh_engine_store:add_signing_key(TenantId, <<"ed25519">>, base64:encode(Pub)),

    %% the compiled artifact must carry the HECS note for this to mean anything ---
    NewsFromArtifact = fh_engine_kb:all_news(),
    expect(lists:any(fun(E) -> maps:get(<<"news_slug">>, E) =:= ?NEWS_SLUG end, NewsFromArtifact),
           "compiled artifact's all_news/0 includes the HECS note"),

    %% --- the shell backend's runtime config (the env fh_shell_engine_jwt:mint reads) ---
    os:putenv("SHELL_TENANT_ID", binary_to_list(TenantId)),
    os:putenv("SHELL_TENANT_PRIVKEY", binary_to_list(base64:encode(Priv))),
    os:putenv("ENGINE_BASE_URL", "http://localhost:8095/api/engine"),

    %% --- stand up ONLY the shell's cowboy listener (real route table via
    %%     fh_shell_http:routes/0), same isolation as suburbs_proxy_smoke ---
    {ok, _} = application:ensure_all_started(cowboy),
    Dispatch = cowboy_router:compile(fh_shell_http:routes()),
    {ok, _} = cowboy:start_clear(fh_shell_listener, [{port, 8085}],
                                 #{env => #{dispatch => Dispatch}}),
    Base = "http://localhost:8085",

    %% --- POSITIVE: GET /api/news -> relayed 200, unfiltered, no Authorization
    %%     header (the surface is PUBLIC — same posture as /api/suburbs) ---
    {200, Resp} = req(get, Base ++ "/api/news"),
    #{<<"news">> := News} = fh_shell_util:json_decode(Resp),
    expect(lists:any(fun(E) -> maps:get(<<"news_slug">>, E) =:= ?NEWS_SLUG end, News),
           "public proxy relays the HECS note (tenant-independent, no user JWT)"),
    Item = hd([E || E <- News, maps:get(<<"news_slug">>, E) =:= ?NEWS_SLUG]),
    expect(maps:is_key(<<"summary_en">>, Item) andalso maps:is_key(<<"summary_vi">>, Item),
           "note carries bilingual summaries through the proxy"),

    %% --- method: POST -> 405 (the proxy is read-only) ---
    {405, _} = req(post, Base ++ "/api/news"),

    io:format("~n==== NEWS PROXY SMOKE: ALL ASSERTIONS PASSED ====~n"),
    halt(0).

%% --- helpers ---------------------------------------------------------------

req(get, Url) ->
    {ok, {{_, Status, _}, _, Resp}} =
        httpc:request(get, {Url, []}, [], [{body_format, binary}]),
    {Status, Resp};
req(post, Url) ->
    {ok, {{_, Status, _}, _, Resp}} =
        httpc:request(post, {Url, [], "application/json", <<>>}, [],
                      [{body_format, binary}]),
    {Status, Resp}.

expect(true, _Msg) -> ok;
expect(false, Msg) ->
    io:format("ASSERTION FAILED: ~s~n", [Msg]),
    halt(1).
