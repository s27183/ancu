#!/usr/bin/env escript
%%! -sname fh_shell_boot_smoke
%%
%% Boot smoke for 8-S0a (the shell backend OTP skeleton). Boots fh_shell against a
%% dev Postgres, asserting: the boot-time migration applied (001_init_shell), the
%% cowboy listener answers /health 200, and the migrated schema round-trips a user
%% insert/select. Run from shell/web/backend with the build libs on the path:
%%
%%   SHELL_DATABASE_URL=postgres://shell:shell_dev_pw@localhost:5434/firsthomey_shell?sslmode=disable \
%%   ERL_LIBS=_build/default/lib escript test/boot_smoke.escript

-mode(compile).

main(_) ->
    os:putenv("FH_SHELL_HTTP_PORT", "8092"),
    {ok, _} = application:ensure_all_started(fh_shell),
    {ok, _} = application:ensure_all_started(inets),

    %% --- migration applied ---
    MigCount = scalar("SELECT count(*) FROM schema_migrations WHERE version = $1",
                      [<<"001">>]),
    expect(MigCount =:= 1, "001_init_shell migration recorded"),

    %% --- /health 200 ---
    {200, HealthBody} = req(get, "http://localhost:8092/health", [], <<>>),
    #{<<"status">> := <<"ok">>, <<"service">> := <<"fh_shell">>} =
        fh_shell_util:json_decode(HealthBody),
    expect(true, "/health returns 200 ok"),

    %% --- schema round-trips: insert a user, read it back with defaults ---
    Email = <<"smoke+", (fh_shell_util:uuid4())/binary, "@example.com">>,
    #{command := insert} =
        pgo:query(<<"INSERT INTO users (email) VALUES ($1)">>, [Email]),
    [{Role, Locale}] =
        rows("SELECT role, locale FROM users WHERE email = $1", [Email]),
    expect(Role =:= <<"buyer">> andalso Locale =:= <<"vi">>,
           "user defaults: role=buyer locale=vi"),

    io:format("~nALL PASSED~n"),
    halt(0).

%% --- helpers ---

expect(true, Label)  -> io:format("  ok  ~s~n", [Label]);
expect(false, Label) -> io:format("FAIL  ~s~n", [Label]), halt(1).

req(Method, Url, Headers, Body) ->
    Request = case Method of
        get -> {Url, Headers};
        _   -> {Url, Headers, "application/json", Body}
    end,
    {ok, {{_, Status, _}, _, RespBody}} =
        httpc:request(Method, Request, [], [{body_format, binary}]),
    {Status, RespBody}.

scalar(SQL, Params) ->
    [{V}] = rows(SQL, Params),
    V.

rows(SQL, Params) ->
    #{rows := Rows} = pgo:query(list_to_binary(SQL), Params),
    Rows.
