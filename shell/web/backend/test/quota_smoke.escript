#!/usr/bin/env escript
%%! -sname fh_shell_quota_smoke
%%
%% Behavior 62: GET /api/me/quota — what the visitor can still use for free, read from
%% the counters the gates claim (guest_daily_creates, qa_daily_asks, the period meter).
%% Never a token count or a cost in the reply.
%%
%%   SHELL_DATABASE_URL=postgres://<user>@<socket dir, %2F-encoded>/<fresh db> \
%%   ERL_LIBS=_build/default/lib escript test/quota_smoke.escript

-mode(compile).

-define(SHELL_PORT, 8099).
-define(ADMIN, "admin+quota62@example.com").

main(_) ->
    os:putenv("FH_SHELL_HTTP_PORT", integer_to_list(?SHELL_PORT)),
    os:putenv("SHELL_JWT_SECRET", "quota-smoke-secret"),
    os:putenv("USAGE_CONSUMER_POLL_MS", "3600000"),
    os:putenv("GUEST_PURGE_INTERVAL_S", "3600"),
    os:putenv("ADMIN_EMAILS", ?ADMIN),
    os:unsetenv("FH_QA_DAILY_LIMIT"),
    os:unsetenv("GUEST_DAILY_CREATES"),
    {_Pub, Priv} = crypto:generate_key(eddsa, ed25519),
    os:putenv("SHELL_TENANT_ID", binary_to_list(uuid())),
    os:putenv("SHELL_TENANT_PRIVKEY", binary_to_list(base64:encode(Priv))),
    {ok, _} = application:ensure_all_started(fh_shell),
    {ok, _} = application:ensure_all_started(inets),

    Addr = "203.0.113." ++ integer_to_list(rand:uniform(250)),

    %% ── no session: a guest-to-be ────────────────────────────────────────────
    G0 = get_quota([{"x-forwarded-for", Addr}]),
    expect(G0 =:= #{<<"kind">> => <<"guest">>, <<"keep_days">> => 7,
                    <<"plans_today">> => #{<<"used">> => 0, <<"limit">> => 3}},
           "no session -> guest, 0 of 3 plans today, kept 7 days"),

    %% ── this address built two plans today ───────────────────────────────────
    {ok, _} = fh_shell_store:claim_guest_create(addr, list_to_binary(Addr), 3),
    {ok, _} = fh_shell_store:claim_guest_create(addr, list_to_binary(Addr), 3),
    #{<<"plans_today">> := #{<<"used">> := 2}} = get_quota([{"x-forwarded-for", Addr}]),
    expect(true, "the address's two creates today -> used 2"),

    %% ── a guest session that used all three ──────────────────────────────────
    GuestId = scalar("INSERT INTO users (email) VALUES ($1) RETURNING user_id::text",
                     [<<"guest+", (uuid())/binary, "@guest.invalid">>]),
    [{ok, _} = fh_shell_store:claim_guest_create(guest, GuestId, 3) || _ <- [1, 2, 3]],
    GJwt = fh_shell_jwt:issue(#{user_id => GuestId, email => <<>>,
                                roles => [<<"guest">>], locale => <<"vi">>}),
    #{<<"kind">> := <<"guest">>, <<"plans_today">> := #{<<"used">> := 3}} =
        get_quota([{"x-forwarded-for", Addr}, bearer(GJwt)]),
    expect(true, "a guest who built 3 today -> used 3 (the higher of guest and address)"),

    %% ── a signed-in user ─────────────────────────────────────────────────────
    U = new_user(email()),
    U0 = get_quota([bearer(jwt(U))]),
    #{<<"kind">> := <<"user">>,
      <<"questions_today">> := #{<<"used">> := 0, <<"limit">> := 1},
      <<"allowance">> := #{<<"used_fraction">> := F0, <<"resets_at">> := Reset}} = U0,
    expect(F0 == 0 andalso is_binary(Reset), "a user with nothing used -> 0 of 1 questions, 0 of the allowance, a reset date"),
    expect(no_internal(U0), "no token count, tier or cost in the reply"),
    {ok, _} = fh_shell_store:claim_question(U, 1),
    #{<<"questions_today">> := #{<<"used">> := 1}} = get_quota([bearer(jwt(U))]),
    expect(true, "after one question today -> used 1"),

    %% ── an admin is unlimited, as the gates treat them ───────────────────────
    A = new_user(<<?ADMIN>>),
    #{<<"questions_today">> := <<"unlimited">>, <<"allowance">> := <<"unlimited">>} =
        get_quota([bearer(jwt(A, <<?ADMIN>>))]),
    expect(true, "an ADMIN_EMAILS user -> unlimited"),

    io:format("~nALL PASSED~n"),
    halt(0).

%% ── helpers ──────────────────────────────────────────────────────────────────

new_user(Email) ->
    U = scalar("INSERT INTO users (email) VALUES ($1) RETURNING user_id::text", [Email]),
    put({email, U}, Email),
    U.

jwt(U) -> jwt(U, get({email, U})).
jwt(U, Email) ->
    fh_shell_jwt:issue(#{user_id => U, email => Email,
                         roles => [<<"buyer">>], locale => <<"vi">>}).

bearer(Jwt) -> {"authorization", "Bearer " ++ binary_to_list(Jwt)}.

no_internal(M) ->
    Flat = fh_shell_util:json_encode(M),
    lists:all(fun(K) -> binary:match(Flat, K) =:= nomatch end,
              [<<"token">>, <<"tier">>, <<"cost">>]).

get_quota(Headers) ->
    Url = "http://localhost:" ++ integer_to_list(?SHELL_PORT) ++ "/api/me/quota",
    {ok, {{_, 200, _}, _, Body}} =
        httpc:request(get, {Url, Headers}, [], [{body_format, binary}]),
    fh_shell_util:json_decode(Body).

uuid()  -> fh_shell_util:uuid4().
email() -> <<"quota62+", (uuid())/binary, "@example.com">>.

scalar(SQL, Params) ->
    #{rows := [{Val}]} = pgo:query(list_to_binary(SQL), Params),
    Val.

expect(true, Label)  -> io:format("  ok  ~ts~n", [Label]);
expect(false, Label) -> io:format("FAIL  ~ts~n", [Label]), halt(1).
