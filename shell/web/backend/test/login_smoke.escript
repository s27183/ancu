#!/usr/bin/env escript
%%! -sname fh_shell_login_smoke
%%
%% Login-slice ablation: the browser<->shell identity seam (shell-architecture.md §3),
%% driving the real fh_shell_h_auth + fh_shell_h_me + the session-cookie reader in
%% fh_shell_http:authenticate_user/1, end to end over HTTP against the shell's own DB.
%%
%% Covers, with NO external services:
%%   * magic link: request -> dev_link -> redeem -> session cookie -> /api/me;
%%     single-use (reuse fails), bad/missing token, calm redirects.
%%   * the cookie authenticates POST /api/plan-cards (closes the 8-S3 auth_required
%%     gap) — engine is the same stub as onboarding_smoke (the real engine is proven
%%     by seam_smoke; two `default` pgo pools can't co-boot, so we stub it).
%%   * logout clears the cookie.
%%   * Google OAuth: not-configured -> calm redirect; configured -> consent redirect
%%     + state cookie; CSRF state-mismatch rejected; the full code exchange ->
%%     id_token decode -> upsert + oauth link, via a stub token endpoint
%%     (GOOGLE_TOKEN_URL override + login_stub_google).
%%
%% Run from shell/web/backend with a shell Postgres reachable, e.g. the homebrew one:
%%
%%   SHELL_DATABASE_URL='postgres://son@localhost:5432/ancu_shell?sslmode=disable' \
%%   ERL_LIBS=_build/default/lib escript test/login_smoke.escript

-mode(compile).

-define(SHELL_PORT, 8096).
-define(ENGINE_STUB_PORT, 8097).
-define(GOOGLE_STUB_PORT, 8098).

main(_) ->
    Base = "http://localhost:" ++ integer_to_list(?SHELL_PORT),

    %% --- env (set BEFORE boot so the .env loader cannot override). Google creds are
    %%     set up front so the configured-path tests run; the not-configured test
    %%     unsets them transiently. ---
    os:putenv("FH_SHELL_HTTP_PORT", integer_to_list(?SHELL_PORT)),
    os:putenv("SHELL_JWT_SECRET", "login-smoke-secret"),
    os:putenv("APP_BASE_URL", Base),
    os:putenv("AUTH_DEV_EXPOSE_LINK", "1"),
    {_Pub, Priv} = crypto:generate_key(eddsa, ed25519),
    os:putenv("SHELL_TENANT_ID", binary_to_list(uuid())),
    os:putenv("SHELL_TENANT_PRIVKEY", binary_to_list(base64:encode(Priv))),

    {ok, _} = application:ensure_all_started(fh_shell),
    {ok, _} = application:ensure_all_started(inets),

    %% stub engine for the plan-cards relay (reuse the onboarding stub)
    EngineStub = compile_load("test/onboarding_stub_engine.erl"),
    start_listener(engine_stub, ?ENGINE_STUB_PORT,
                   [{"/api/engine/plan-cards", EngineStub, []}]),
    os:putenv("ENGINE_BASE_URL",
              "http://localhost:" ++ integer_to_list(?ENGINE_STUB_PORT) ++ "/api/engine"),

    %% stub Google token endpoint + point the exchange at it
    GoogleStub = compile_load("test/login_stub_google.erl"),
    start_listener(google_stub, ?GOOGLE_STUB_PORT, [{"/token", GoogleStub, []}]),
    os:putenv("GOOGLE_TOKEN_URL",
              "http://localhost:" ++ integer_to_list(?GOOGLE_STUB_PORT) ++ "/token"),

    test_magic_link(Base),
    test_plan_card_with_cookie(Base),
    test_logout(Base),
    test_me_unauthenticated(Base),
    test_google_not_configured(Base),
    test_google_configured(Base),

    io:format("~nALL PASSED~n"),
    halt(0).

%% --- magic link -------------------------------------------------------------

test_magic_link(Base) ->
    Email = <<"magic+", (uuid())/binary, "@example.com">>,

    %% request -> 202 + dev_link
    {202, _, ReqResp} = post_json(Base ++ "/api/auth/magic", #{<<"email">> => Email}),
    #{<<"sent">> := true, <<"dev_link">> := DevLink} = json(ReqResp),
    expect(is_binary(DevLink), "magic request -> 202 with dev_link"),

    %% redeem the link -> 302 ?signin=ok + a session cookie
    {302, VHeaders, _} = get_raw(binary_to_list(DevLink), []),
    expect(redirect_to(VHeaders, "/?signin=ok"), "redeem -> 302 ?signin=ok"),
    Jwt = session_cookie(VHeaders),
    expect(is_binary(Jwt), "redeem sets the fh_session cookie"),

    %% the cookie's JWT is valid and carries the email
    {ok, Claims} = fh_shell_jwt:verify(Jwt),
    expect(maps:get(<<"email">>, Claims) =:= Email, "session JWT carries the email"),

    %% the user row was created on first login
    UserCount = scalar("SELECT count(*) FROM users WHERE email = $1", [Email]),
    expect(UserCount =:= 1, "first login created the user"),

    %% /api/me with the cookie -> the session
    {200, _, MeResp} = get_raw(Base ++ "/api/me", [cookie(Jwt)]),
    #{<<"email">> := MeEmail} = json(MeResp),
    expect(MeEmail =:= Email, "/api/me returns the session via cookie"),

    %% single-use: redeeming the same link again fails calmly
    {302, ReuseHeaders, _} = get_raw(binary_to_list(DevLink), []),
    expect(redirect_to(ReuseHeaders, "/?signin=expired"),
           "reused link -> 302 ?signin=expired (single-use)"),

    %% a bogus / missing token redirect calmly
    {302, BadHeaders, _} =
        get_raw(Base ++ "/api/auth/magic/verify?token=not-a-real-token", []),
    expect(redirect_to(BadHeaders, "/?signin=expired"), "unknown token -> ?signin=expired"),
    {302, NoTokHeaders, _} = get_raw(Base ++ "/api/auth/magic/verify", []),
    expect(redirect_to(NoTokHeaders, "/?signin=invalid"), "no token -> ?signin=invalid"),

    %% missing email -> 400
    {400, _, _} = post_json(Base ++ "/api/auth/magic", #{}),
    expect(true, "magic request without email -> 400").

%% --- the cookie authenticates a plan-card create (8-S3 gap) -----------------

test_plan_card_with_cookie(Base) ->
    Email = <<"planner+", (uuid())/binary, "@example.com">>,
    Jwt = sign_in(Base, Email),

    Body = #{<<"state">> => <<"NSW">>,
            <<"target_price_range">> => [600000, 700000],
            <<"target_zone">> => [<<"Cabramatta">>],
            <<"intent">> => <<"owner_occupier">>},

    %% NO Authorization header — only the cookie
    {202, _, Resp} = post_json(Base ++ "/api/plan-cards", Body, [cookie(Jwt)]),
    #{<<"plan_card_id">> := PlanCardId} = json(Resp),
    UserId = maps:get(<<"user_id">>, element(2, fh_shell_jwt:verify(Jwt))),
    Views = scalar("SELECT count(*) FROM plan_card_views "
                   "WHERE user_id = $1::uuid AND engine_plan_card_id = $2::uuid",
                   [UserId, PlanCardId]),
    expect(Views =:= 1, "session cookie authenticates POST /api/plan-cards").

%% --- logout -----------------------------------------------------------------

test_logout(Base) ->
    {200, Headers, _} = post_json(Base ++ "/api/auth/logout", #{}),
    %% the Set-Cookie clears the session (empty value, Max-Age=0)
    SetCookie = header(Headers, "set-cookie"),
    expect(SetCookie =/= undefined andalso
           string:find(SetCookie, "fh_session=") =/= nomatch andalso
           string:find(SetCookie, "Max-Age=0") =/= nomatch,
           "logout clears the fh_session cookie").

%% --- /api/me signed out -----------------------------------------------------

test_me_unauthenticated(Base) ->
    {401, _, Resp} = get_raw(Base ++ "/api/me", []),
    #{<<"error">> := <<"missing_authorization">>} = json(Resp),
    expect(true, "/api/me without a session -> 401 missing_authorization").

%% --- Google: not configured -------------------------------------------------

test_google_not_configured(Base) ->
    %% transiently remove the client id so google_config/0 reports not_configured
    os:unsetenv("GOOGLE_CLIENT_ID"),
    os:unsetenv("GOOGLE_CLIENT_SECRET"),
    {302, Headers, _} = get_raw(Base ++ "/api/auth/google", []),
    expect(redirect_to(Headers, "/?signin=google_unavailable"),
           "google start, not configured -> calm redirect").

%% --- Google: configured (consent redirect, CSRF, full exchange) -------------

test_google_configured(Base) ->
    os:putenv("GOOGLE_CLIENT_ID", "stub-client-id.apps.googleusercontent.com"),
    os:putenv("GOOGLE_CLIENT_SECRET", "stub-client-secret"),

    %% start -> 302 to Google consent + a state cookie
    {302, StartHeaders, _} = get_raw(Base ++ "/api/auth/google", []),
    Loc = header(StartHeaders, "location"),
    expect(string:find(Loc, "accounts.google.com") =/= nomatch,
           "google start -> 302 to Google consent"),
    StateCookie = named_cookie(StartHeaders, "fh_oauth_state"),
    expect(is_binary(StateCookie) andalso byte_size(StateCookie) > 0,
           "google start sets the fh_oauth_state cookie"),

    %% CSRF: a callback whose state does not match the cookie is rejected
    {302, CsrfHeaders, _} = get_raw(
        Base ++ "/api/auth/google/callback?state=mismatch&code=abc",
        [{"cookie", "fh_oauth_state=" ++ binary_to_list(StateCookie)}]),
    expect(redirect_to(CsrfHeaders, "/?signin=error"),
           "google callback with mismatched state -> ?signin=error"),

    %% happy path: matching state + code -> stub exchange -> session
    StateStr = binary_to_list(StateCookie),
    {302, CbHeaders, _} = get_raw(
        Base ++ "/api/auth/google/callback?state=" ++ StateStr ++ "&code=auth-code",
        [{"cookie", "fh_oauth_state=" ++ StateStr}]),
    expect(redirect_to(CbHeaders, "/?signin=ok"), "google callback -> 302 ?signin=ok"),
    Jwt = session_cookie(CbHeaders),
    expect(is_binary(Jwt), "google callback sets the fh_session cookie"),
    {ok, Claims} = fh_shell_jwt:verify(Jwt),
    expect(maps:get(<<"email">>, Claims) =:= login_stub_google:email(),
           "google session JWT carries the verified email"),

    %% user upserted + the oauth identity linked
    UserCount = scalar("SELECT count(*) FROM users WHERE email = $1",
                       [login_stub_google:email()]),
    expect(UserCount =:= 1, "google sign-in upserted the user"),
    LinkCount = scalar(
        "SELECT count(*) FROM oauth_identities WHERE provider = 'google' AND subject = $1",
        [login_stub_google:subject()]),
    expect(LinkCount =:= 1, "google sign-in linked the oauth identity").

%% --- helpers ----------------------------------------------------------------

sign_in(Base, Email) ->
    {202, _, Resp} = post_json(Base ++ "/api/auth/magic", #{<<"email">> => Email}),
    #{<<"dev_link">> := DevLink} = json(Resp),
    {302, Headers, _} = get_raw(binary_to_list(DevLink), []),
    session_cookie(Headers).

cookie(Jwt) -> {"cookie", "fh_session=" ++ binary_to_list(Jwt)}.

%% the fh_session value from a response's Set-Cookie headers
session_cookie(Headers) -> named_cookie(Headers, "fh_session").

named_cookie(Headers, Name) ->
    SetCookies = [V || {K, V} <- Headers, string:lowercase(K) =:= "set-cookie"],
    Prefix = Name ++ "=",
    case lists:filtermap(fun(SC) -> cookie_value(SC, Prefix) end, SetCookies) of
        [Val | _] -> list_to_binary(Val);
        [] -> undefined
    end.

cookie_value(SetCookie, Prefix) ->
    case string:prefix(SetCookie, Prefix) of
        nomatch -> false;
        Rest ->
            [Val | _] = string:split(Rest, ";"),
            case Val of "" -> false; _ -> {true, Val} end
    end.

redirect_to(Headers, PathSuffix) ->
    case header(Headers, "location") of
        undefined -> false;
        Loc -> string:find(Loc, PathSuffix) =/= nomatch
    end.

header(Headers, Name) ->
    case [V || {K, V} <- Headers, string:lowercase(K) =:= Name] of
        [V | _] -> V;
        [] -> undefined
    end.

post_json(Url, Map) -> post_json(Url, Map, []).
post_json(Url, Map, Headers) ->
    Body = fh_shell_util:json_encode(Map),
    req(post, {Url, Headers, "application/json", Body}).

get_raw(Url, Headers) -> req(get, {Url, Headers}).

req(Method, Request) ->
    {ok, {{_, Status, _}, RespHeaders, Resp}} =
        httpc:request(Method, Request, [{autoredirect, false}], [{body_format, binary}]),
    {Status, RespHeaders, Resp}.

json(Bin) -> fh_shell_util:json_decode(Bin).

start_listener(Name, Port, Routes) ->
    Dispatch = cowboy_router:compile([{'_', Routes}]),
    {ok, _} = cowboy:start_clear(Name, [{port, Port}], #{env => #{dispatch => Dispatch}}).

compile_load(File) ->
    {ok, Mod, Bin} = compile:file(File, [binary, return_errors]),
    {module, Mod} = code:load_binary(Mod, File, Bin),
    Mod.

uuid() -> fh_shell_util:uuid4().

expect(true, Label)  -> io:format("  ok  ~s~n", [Label]);
expect(false, Label) -> io:format("FAIL  ~s~n", [Label]), halt(1).

scalar(SQL, Params) ->
    #{rows := [{Val}]} = pgo:query(SQL, Params),
    Val.
