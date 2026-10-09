#!/usr/bin/env escript
%%! -sname fh_shell_facts_proxy_smoke
%%
%% Behavior 42: the shell's PUBLIC /api/facts proxy over the full HTTP path —
%% shell backend -> engine GET /api/engine/facts (fh_engine_h_facts,
%% fh_engine_kb:all_facts/0) -> relayed verbatim. Same isolation as
%% news_proxy_smoke: boots the engine app and only the shell's cowboy listener.
%% Checks both fact docs arrive with title, sources and facts; every fact names a
%% source index inside its doc's sources; quotes (the build's proof) are not shipped;
%% the engine refuses an unauthenticated call (401); POST is 405.
%% Run from shell/web/backend with the KB artifact compiled:
%%
%%   ENGINE_DATABASE_URL=postgres://<user>@<socket dir, %2F-encoded>/<db> \
%%   ERL_LIBS=_build/default/lib:../../../engine/erlang/_build/default/lib \
%%   escript test/facts_proxy_smoke.escript

-mode(compile).


main(_) ->
    %% --- boot the engine on its own port + provision the shell's signing key ---
    os:putenv("FH_ENGINE_HTTP_PORT", "8095"),
    {ok, _} = application:ensure_all_started(fh_engine),
    {ok, _} = application:ensure_all_started(inets),

    TenantId = fh_engine_util:uuid4(),
    {Pub, Priv} = crypto:generate_key(eddsa, ed25519),
    ok = fh_engine_store:upsert_tenant(TenantId, <<"shell-web">>),
    ok = fh_engine_store:add_signing_key(TenantId, <<"ed25519">>, base64:encode(Pub)),

    expect(length(fh_engine_kb:all_facts()) >= 2, "compiled artifact carries the fact docs"),

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

    {200, Resp} = req(get, Base ++ "/api/facts"),
    #{<<"facts">> := Docs} = fh_shell_util:json_decode(Resp),
    Slugs = [maps:get(<<"slug">>, D) || D <- Docs],
    expect(lists:member(<<"kb.facts.vietnamese-in-australia">>, Slugs) andalso
           lists:member(<<"kb.facts.australian-property">>, Slugs),
           "public proxy relays both fact docs"),
    lists:foreach(fun(D) ->
        #{<<"title">> := #{<<"en">> := _, <<"vi">> := _}, <<"sources">> := Srcs,
          <<"facts">> := Fs} = D,
        expect(Fs =/= [], "a doc carries facts"),
        lists:foreach(fun(F) ->
            Idx = maps:get(<<"source">>, F),
            expect(is_integer(Idx) andalso Idx >= 0 andalso Idx < length(Srcs),
                   "each fact's source index points into its doc's sources"),
            expect(not maps:is_key(<<"quotes">>, F), "quotes are not shipped")
        end, Fs)
    end, Docs),
    Vn = hd([D || D <- Docs, maps:get(<<"slug">>, D) =:= <<"kb.facts.vietnamese-in-australia">>]),
    Pop = hd([F || F <- maps:get(<<"facts">>, Vn), maps:get(<<"id">>, F) =:= <<"vietnam_born_population">>]),
    expect(maps:get(<<"value">>, Pop) =:= 318760, "the Vietnam-born figure arrives as compiled"),

    %% the engine route itself refuses a call without the tenant JWT ---
    {401, _} = req(get, "http://localhost:8095/api/engine/facts"),

    %% --- method: POST -> 405 (the proxy is read-only) ---
    {405, _} = req(post, Base ++ "/api/facts"),

    io:format("~n==== FACTS PROXY SMOKE: ALL ASSERTIONS PASSED ====~n"),
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
