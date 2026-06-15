#!/usr/bin/env escript
%%! -sname fh_shell_plancard_proxy_smoke
%%
%% 8-S4a ablation: the single plan-card proxies over the full HTTP path
%% frontend -> shell backend, driving the real fh_shell_h_plan_cards (GET list) and
%% fh_shell_h_plan_card (GET read / POST messages) handlers. The point under test is
%% the shell-new logic: user-JWT auth, the OWNERSHIP gate (plan_card_views), and the
%% verbatim relay of the engine's status + body.
%%
%% The ENGINE is a stub (plancard_proxy_stub_engine) for the same reason as
%% onboarding_smoke: the real engine app would take the only `default` pgo pool, and
%% the shell needs it for its ownership read. Identity is a TEST-issued user JWT.
%%
%% Run from shell/web/backend with the shell's dev Postgres up:
%%
%%   SHELL_DATABASE_URL=postgres://shell:shell_dev_pw@localhost:5434/firsthomey_shell?sslmode=disable \
%%   ERL_LIBS=_build/default/lib escript test/plancard_proxy_smoke.escript

-mode(compile).

-define(SHELL_PORT, 8096).
-define(STUB_PORT, 8097).

main(_) ->
    os:putenv("FH_SHELL_HTTP_PORT", integer_to_list(?SHELL_PORT)),
    os:putenv("SHELL_JWT_SECRET", "plancard-proxy-smoke-secret"),
    {_Pub, Priv} = crypto:generate_key(eddsa, ed25519),
    os:putenv("SHELL_TENANT_ID", binary_to_list(uuid())),
    os:putenv("SHELL_TENANT_PRIVKEY", binary_to_list(base64:encode(Priv))),

    {ok, _} = application:ensure_all_started(fh_shell),
    {ok, _} = application:ensure_all_started(inets),

    %% --- stand up the stub engine (read + messages) + point the client at it ---
    StubMod = compile_load("test/plancard_proxy_stub_engine.erl"),
    Dispatch = cowboy_router:compile([{'_', [
        {"/api/engine/plan-cards/:id/messages", StubMod, [messages]},
        {"/api/engine/plan-cards/:id", StubMod, []}
    ]}]),
    {ok, _} = cowboy:start_clear(stub_engine_listener, [{port, ?STUB_PORT}],
                                 #{env => #{dispatch => Dispatch}}),
    os:putenv("ENGINE_BASE_URL",
              "http://localhost:" ++ integer_to_list(?STUB_PORT) ++ "/api/engine"),

    Base = "http://localhost:" ++ integer_to_list(?SHELL_PORT),

    %% --- a real user + a plan card the user OWNS (a plan_card_views row) ---
    Email = <<"plancard+", (uuid())/binary, "@example.com">>,
    UserId = scalar("INSERT INTO users (email) VALUES ($1) RETURNING user_id::text",
                    [Email]),
    CardId = uuid(),
    ok = fh_shell_store:insert_plan_card_view(UserId, CardId, <<"Cabramatta">>),

    Jwt = fh_shell_jwt:issue(#{user_id => UserId, email => Email,
                               roles => [<<"buyer">>], locale => <<"vi">>}),
    Auth = [{"authorization", "Bearer " ++ binary_to_list(Jwt)}],

    %% A second user's card the first user must NOT see (ownership boundary).
    OtherEmail = <<"other+", (uuid())/binary, "@example.com">>,
    OtherUser = scalar("INSERT INTO users (email) VALUES ($1) RETURNING user_id::text",
                       [OtherEmail]),
    OtherCard = uuid(),
    ok = fh_shell_store:insert_plan_card_view(OtherUser, OtherCard, <<"Footscray">>),

    %% --- LIST: the user's own cards ---
    {200, ListResp} = req(get, Base ++ "/api/plan-cards", Auth, <<>>),
    #{<<"plan_cards">> := Cards} = fh_shell_util:json_decode(ListResp),
    Mine = [C || C <- Cards, maps:get(<<"plan_card_id">>, C) =:= CardId],
    expect(length(Mine) =:= 1, "GET /api/plan-cards lists the user's card"),
    [#{<<"title">> := <<"Cabramatta">>, <<"created_at">> := Created}] = Mine,
    expect(is_binary(Created), "list row carries title + created_at"),
    NotTheirs = [C || C <- Cards, maps:get(<<"plan_card_id">>, C) =:= OtherCard],
    expect(NotTheirs =:= [], "list excludes another user's card"),

    {401, _} = req(get, Base ++ "/api/plan-cards", [], <<>>),
    expect(true, "GET /api/plan-cards with no user JWT -> 401"),

    %% --- READ: the owned card relays the engine's 200 + content verbatim ---
    {200, ReadResp} = req(get, Base ++ "/api/plan-cards/" ++ b2l(CardId), Auth, <<>>),
    #{<<"plan_card_id">> := CardId, <<"mode">> := <<"A">>,
      <<"content">> := #{<<"components">> := Comps}} = fh_shell_util:json_decode(ReadResp),
    expect(maps:is_key(<<"buyer_profile">>, Comps),
           "GET /api/plan-cards/:id relays the engine's filled content"),

    %% --- READ: a card the user does not own -> 404 (no existence disclosure) ---
    {404, NoOwnResp} = req(get, Base ++ "/api/plan-cards/" ++ b2l(OtherCard), Auth, <<>>),
    #{<<"error">> := <<"not_found">>} = fh_shell_util:json_decode(NoOwnResp),
    expect(true, "GET /api/plan-cards/:id for an unowned card -> 404"),

    %% --- READ: a never-seen but well-formed uuid -> 404 ---
    {404, _} = req(get, Base ++ "/api/plan-cards/" ++ b2l(uuid()), Auth, <<>>),
    expect(true, "GET /api/plan-cards/:id for an unknown card -> 404"),

    %% --- READ: a malformed id never reaches the $N::uuid bind -> calm 404 ---
    {404, _} = req(get, Base ++ "/api/plan-cards/not-a-uuid", Auth, <<>>),
    expect(true, "GET /api/plan-cards/:id with a malformed id -> 404 (not a 500)"),

    %% --- READ: no user JWT -> 401 ---
    {401, _} = req(get, Base ++ "/api/plan-cards/" ++ b2l(CardId), [], <<>>),
    expect(true, "GET /api/plan-cards/:id with no user JWT -> 401"),

    %% --- MESSAGES: ask about the owned card -> 202 relayed ---
    MsgBody = fh_shell_util:json_encode(#{<<"message">> => <<"Can I use FHSS?">>}),
    {202, MsgResp} = req(post, Base ++ "/api/plan-cards/" ++ b2l(CardId) ++ "/messages",
                         Auth, MsgBody),
    #{<<"plan_card_id">> := CardId, <<"turn_id">> := _} = fh_shell_util:json_decode(MsgResp),
    expect(true, "POST /api/plan-cards/:id/messages on an owned card -> 202 relayed"),

    %% --- MESSAGES: unowned card -> 404; no user JWT -> 401 ---
    {404, _} = req(post, Base ++ "/api/plan-cards/" ++ b2l(OtherCard) ++ "/messages",
                   Auth, MsgBody),
    expect(true, "POST .../messages on an unowned card -> 404"),
    {401, _} = req(post, Base ++ "/api/plan-cards/" ++ b2l(CardId) ++ "/messages",
                   [], MsgBody),
    expect(true, "POST .../messages with no user JWT -> 401"),

    io:format("~nALL PASSED~n"),
    halt(0).

%% --- helpers ---

compile_load(File) ->
    {ok, Mod, Bin} = compile:file(File, [binary, return_errors]),
    {module, Mod} = code:load_binary(Mod, File, Bin),
    Mod.

uuid() -> fh_shell_util:uuid4().
b2l(B) -> binary_to_list(B).

expect(true, Label)  -> io:format("  ok  ~s~n", [Label]);
expect(false, Label) -> io:format("FAIL  ~s~n", [Label]), halt(1).

req(Method, Url, Headers, Body) ->
    Request = case Method of
        get -> {Url, Headers};
        _   -> {Url, Headers, "application/json", Body}
    end,
    {ok, {{_, Status, _}, _, Resp}} =
        httpc:request(Method, Request, [], [{body_format, binary}]),
    {Status, Resp}.

scalar(SQL, Params) ->
    #{rows := [{Val}]} = pgo:query(SQL, Params),
    Val.
