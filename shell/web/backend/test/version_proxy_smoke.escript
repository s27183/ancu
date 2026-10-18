#!/usr/bin/env escript
%%! -sname fh_shell_version_proxy_smoke
%%
%% Behavior 135: the shell's PUBLIC /api/version proxy over the full HTTP path —
%% shell backend -> engine GET /api/engine/version (fh_engine_h_version,
%% fh_engine_kb:content_version/0) -> relayed with cache-control: no-store. Same
%% isolation as facts_proxy_smoke. Checks the hash is the artifact file's sha256
%% prefix; reloading the same file keeps it; loading a changed file moves it (and the
%% proxy reports the new one); the engine refuses an unauthenticated call (401); POST
%% is 405. Run from shell/web/backend with the KB artifact compiled:
%%
%%   ENGINE_DATABASE_URL=postgres://<user>@<socket dir, %2F-encoded>/<db> \
%%   ERL_LIBS=_build/default/lib:../../../engine/erlang/_build/default/lib \
%%   escript test/version_proxy_smoke.escript

-mode(compile).

main(_) ->
    os:putenv("FH_ENGINE_HTTP_PORT", "8096"),
    {ok, _} = application:ensure_all_started(fh_engine),
    {ok, _} = application:ensure_all_started(inets),

    TenantId = fh_engine_util:uuid4(),
    {Pub, Priv} = crypto:generate_key(eddsa, ed25519),
    ok = fh_engine_store:upsert_tenant(TenantId, <<"shell-web">>),
    ok = fh_engine_store:add_signing_key(TenantId, <<"ed25519">>, base64:encode(Pub)),

    os:putenv("SHELL_TENANT_ID", binary_to_list(TenantId)),
    os:putenv("SHELL_TENANT_PRIVKEY", binary_to_list(base64:encode(Priv))),
    os:putenv("ENGINE_BASE_URL", "http://localhost:8096/api/engine"),

    {ok, _} = application:ensure_all_started(cowboy),
    Dispatch = cowboy_router:compile(fh_shell_http:routes()),
    {ok, _} = cowboy:start_clear(fh_shell_listener, [{port, 8086}],
                                 #{env => #{dispatch => Dispatch}}),
    Base = "http://localhost:8086",

    Path = filename:join([code:priv_dir(fh_engine), "kb", "artifact.json"]),
    {ok, Bin} = file:read_file(Path),
    Want = binary:part(binary:encode_hex(crypto:hash(sha256, Bin), lowercase), 0, 16),

    {200, Hdrs, Resp} = req(get, Base ++ "/api/version"),
    #{<<"kb">> := V1} = fh_shell_util:json_decode(Resp),
    expect(V1 =:= Want, "the hash is the loaded artifact's sha256 prefix"),
    expect(proplists:get_value("cache-control", Hdrs) =:= "no-store",
           "the proxy answers cache-control: no-store"),

    ok = fh_engine_kb:load(Path),
    {200, _, R2} = req(get, Base ++ "/api/version"),
    expect(maps:get(<<"kb">>, fh_shell_util:json_decode(R2)) =:= V1,
           "reloading the same artifact keeps the hash"),

    Tmp = filename:join(os:getenv("TMPDIR", "/tmp"), "fh_version_smoke_artifact.json"),
    ok = file:write_file(Tmp, <<Bin/binary, "\n">>),
    ok = fh_engine_kb:load(Tmp),
    {200, _, R3} = req(get, Base ++ "/api/version"),
    V3 = maps:get(<<"kb">>, fh_shell_util:json_decode(R3)),
    expect(V3 =/= V1 andalso byte_size(V3) =:= 16, "a changed artifact moves the hash"),
    ok = fh_engine_kb:load(Path),
    ok = file:delete(Tmp),

    {401, _, _} = req(get, "http://localhost:8096/api/engine/version"),
    {405, _, _} = req(post, Base ++ "/api/version"),

    io:format("~n==== VERSION PROXY SMOKE: ALL ASSERTIONS PASSED ====~n"),
    halt(0).

req(get, Url) ->
    {ok, {{_, Status, _}, Hdrs, Resp}} =
        httpc:request(get, {Url, []}, [], [{body_format, binary}]),
    {Status, Hdrs, Resp};
req(post, Url) ->
    {ok, {{_, Status, _}, Hdrs, Resp}} =
        httpc:request(post, {Url, [], "application/json", <<>>}, [],
                      [{body_format, binary}]),
    {Status, Hdrs, Resp}.

expect(true, _Msg) -> ok;
expect(false, Msg) ->
    io:format("ASSERTION FAILED: ~s~n", [Msg]),
    halt(1).
