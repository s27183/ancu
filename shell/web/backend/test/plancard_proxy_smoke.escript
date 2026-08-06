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
        {"/api/engine/plan-cards/:id/properties", StubMod, [properties]},
        {"/api/engine/plan-cards/:id/properties/:pid/transaction", StubMod, [transaction]},
        {"/api/engine/plan-cards/:id/news", StubMod, [news]},
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

    %% --- ATTACH (Mode-C Slice 1): a property_card on the owned card -> 202 relayed,
    %% with the body field + the minted tenant JWT proven to have travelled through ---
    AttachBody = fh_shell_util:json_encode(#{<<"price">> => 920000,
                                             <<"state">> => <<"NSW">>,
                                             <<"suburb">> => <<"Cabramatta">>,
                                             <<"property_type">> => <<"established_house">>}),
    {202, AttResp} = req(post, Base ++ "/api/plan-cards/" ++ b2l(CardId) ++ "/properties",
                         Auth, AttachBody),
    #{<<"plan_card_id">> := CardId, <<"property_id">> := PropId,
      <<"echo_state">> := <<"NSW">>, <<"saw_bearer">> := true} =
        fh_shell_util:json_decode(AttResp),
    expect(is_binary(PropId),
           "POST .../properties on an owned card -> 202; body + tenant JWT forwarded, relayed verbatim"),

    %% --- ATTACH: ownership + auth gates (same posture as the other proxies) ---
    {404, _} = req(post, Base ++ "/api/plan-cards/" ++ b2l(OtherCard) ++ "/properties",
                   Auth, AttachBody),
    expect(true, "POST .../properties on an unowned card -> 404"),
    {401, _} = req(post, Base ++ "/api/plan-cards/" ++ b2l(CardId) ++ "/properties",
                   [], AttachBody),
    expect(true, "POST .../properties with no user JWT -> 401"),

    %% --- ATTACH: an over-limit user is GATED 402 before the engine (attach is an
    %% agent turn → metered, so it gates like `ask`, unlike the resolver-only proxies).
    %% A fresh user with usage at the default free limit (1.0M); the first gate read
    %% sees it (no cache to invalidate), short-circuiting before any engine call. ---
    OverUser = scalar("INSERT INTO users (email) VALUES ($1) RETURNING user_id::text",
                      [<<"over+", (uuid())/binary, "@example.com">>]),
    OverCard = uuid(),
    ok = fh_shell_store:insert_plan_card_view(OverUser, OverCard, <<"Cabramatta">>),
    %% engine_event_id must be NEGATIVE: fh_shell_usage_consumer bootstraps its poll
    %% cursor from MAX(engine_event_id) across this whole table (002_commerce.sql),
    %% so a positive fixture id — even a huge one meant only to be "unique" — can jump
    %% the real consumer's cursor past every future real event and silently wedge it.
    _ = pgo:query(<<"INSERT INTO usage_records (user_id, engine_event_id, tokens_total) "
                    "VALUES ($1::uuid, $2, $3)">>,
                  [OverUser, -erlang:system_time(microsecond), 1000000]),
    OverJwt = fh_shell_jwt:issue(#{user_id => OverUser, email => <<"over@example.com">>,
                                   roles => [<<"buyer">>], locale => <<"vi">>}),
    OverAuth = [{"authorization", "Bearer " ++ binary_to_list(OverJwt)}],
    {402, OverResp} = req(post, Base ++ "/api/plan-cards/" ++ b2l(OverCard) ++ "/properties",
                          OverAuth, AttachBody),
    #{<<"error">> := <<"quota_exceeded">>} = fh_shell_util:json_decode(OverResp),
    expect(true, "POST .../properties over the token limit -> 402 (attach gated like ask, before the engine)"),

    %% --- TRANSACTION (Mode-C Slice 1): dates on the owned card -> 202; the :pid + the
    %% body travel through the proxy (resolver-only re-fill, so NO meter gate) ---
    TxnPid = uuid(),
    TxnBody = fh_shell_util:json_encode(#{<<"contract_signed_date">> => <<"2026-06-01">>,
                                          <<"settlement_date">> => <<"2026-09-01">>}),
    {202, TxnResp} = req(post, Base ++ "/api/plan-cards/" ++ b2l(CardId)
                         ++ "/properties/" ++ b2l(TxnPid) ++ "/transaction", Auth, TxnBody),
    #{<<"plan_card_id">> := CardId, <<"property_id">> := TxnPid,
      <<"echo_settlement">> := <<"2026-09-01">>} = fh_shell_util:json_decode(TxnResp),
    expect(true, "POST .../properties/:pid/transaction on an owned card -> 202; :pid + body forwarded"),

    %% --- TRANSACTION: ownership + auth gates ---
    {404, _} = req(post, Base ++ "/api/plan-cards/" ++ b2l(OtherCard)
                   ++ "/properties/" ++ b2l(uuid()) ++ "/transaction", Auth, TxnBody),
    expect(true, "POST .../transaction on an unowned card -> 404"),
    {401, _} = req(post, Base ++ "/api/plan-cards/" ++ b2l(CardId)
                   ++ "/properties/" ++ b2l(TxnPid) ++ "/transaction", [], TxnBody),
    expect(true, "POST .../transaction with no user JWT -> 401"),

    %% --- NEWS (task 27): GET relays the engine's relevant-notes list verbatim ---
    {200, NewsResp} = req(get, Base ++ "/api/plan-cards/" ++ b2l(CardId) ++ "/news",
                          Auth, <<>>),
    #{<<"news">> := [NewsItem]} = fh_shell_util:json_decode(NewsResp),
    #{<<"news_slug">> := <<"kb.news.2026-07-hecs-thresholds-2026-27">>,
      <<"sources">> := [_ | _]} = NewsItem,
    expect(true, "GET .../news on an owned card -> 200; relayed verbatim"),

    {404, _} = req(get, Base ++ "/api/plan-cards/" ++ b2l(OtherCard) ++ "/news",
                   Auth, <<>>),
    expect(true, "GET .../news on an unowned card -> 404"),
    {401, _} = req(get, Base ++ "/api/plan-cards/" ++ b2l(CardId) ++ "/news", [], <<>>),
    expect(true, "GET .../news with no user JWT -> 401"),

    %% --- NEWS: PATCH dismiss relays the engine's authoritative dismissed_news map ---
    DismissBody = fh_shell_util:json_encode(
        #{<<"news_slug">> => <<"kb.news.2026-07-hecs-thresholds-2026-27">>}),
    {200, DismissResp} = req(patch, Base ++ "/api/plan-cards/" ++ b2l(CardId) ++ "/news",
                             Auth, DismissBody),
    #{<<"dismissed_news">> :=
        #{<<"kb.news.2026-07-hecs-thresholds-2026-27">> := true}} =
        fh_shell_util:json_decode(DismissResp),
    expect(true, "PATCH .../news on an owned card -> 200; dismissed_news relayed verbatim"),

    {404, _} = req(patch, Base ++ "/api/plan-cards/" ++ b2l(OtherCard) ++ "/news",
                   Auth, DismissBody),
    expect(true, "PATCH .../news on an unowned card -> 404"),
    {401, _} = req(patch, Base ++ "/api/plan-cards/" ++ b2l(CardId) ++ "/news", [], DismissBody),
    expect(true, "PATCH .../news with no user JWT -> 401"),

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
