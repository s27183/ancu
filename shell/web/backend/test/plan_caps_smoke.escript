#!/usr/bin/env escript
%%! -sname fh_shell_plan_caps_smoke
%%
%% Behavior 111: a guest holds up to 7 plans, a signed-in visitor up to 28. Drives the
%% real shell app against the create-key stub engine (test/create_key_stub_engine.erl):
%%   - a guest makes 7 plans in one day; the 8th is 409 plans_full with the cap, no
%%     engine call and no daily claim;
%%   - the guest deletes one (DELETE /api/plan-cards/:id → 204): the slot frees, a
%%     create then works; deleting it again, or another visitor's plan, is 404;
%%   - a user holding 28 plans gets 409 on the 29th; a delete frees a slot;
%%   - two creates at once for the last slot make one plan.
%%
%% Run from shell/web/backend with a throwaway shell database:
%%
%%   SHELL_DATABASE_URL=postgres://<user>@<socket dir, %2F-escaped>/<db> \
%%   ERL_LIBS=_build/default/lib escript test/plan_caps_smoke.escript

-mode(compile).

-define(SHELL_PORT, 8095).
-define(STUB_PORT, 8096).

main(_) ->
    os:putenv("FH_SHELL_HTTP_PORT", integer_to_list(?SHELL_PORT)),
    os:putenv("FH_HTTP_IP", "127.0.0.1"),
    os:putenv("SHELL_JWT_SECRET", "plan-caps-smoke-secret"),
    os:unsetenv("GUEST_DAILY_CREATES"),
    {_Pub, Priv} = crypto:generate_key(eddsa, ed25519),
    os:putenv("SHELL_TENANT_ID", binary_to_list(uuid())),
    os:putenv("SHELL_TENANT_PRIVKEY", binary_to_list(base64:encode(Priv))),
    os:putenv("ENGINE_BASE_URL",
              "http://127.0.0.1:" ++ integer_to_list(?STUB_PORT) ++ "/api/engine"),
    {ok, _} = application:ensure_all_started(fh_shell),
    {ok, _} = application:ensure_all_started(inets),

    ets:new(stub_creates, [named_table, public]),
    ets:insert(stub_creates, {n, 0}),
    StubMod = compile_load("test/create_key_stub_engine.erl"),
    Dispatch = cowboy_router:compile([{'_', [{"/api/engine/plan-cards", StubMod, []}]}]),
    {ok, _} = cowboy:start_clear(plan_caps_stub, [{ip, {127,0,0,1}}, {port, ?STUB_PORT}],
                                 #{env => #{dispatch => Dispatch}}),

    Base = "http://127.0.0.1:" ++ integer_to_list(?SHELL_PORT),
    Addr = lists:flatten(io_lib:format("10.111.~B.~B", [rand:uniform(250), rand:uniform(250)])),
    Xff = {"x-forwarded-for", Addr},
    Body = fh_shell_util:json_encode(#{<<"state">> => <<"NSW">>,
                                       <<"target_price_range">> => [600000, 700000],
                                       <<"target_zone">> => [],
                                       <<"intent">> => <<"owner_occupier">>}),
    Create = fun(Hs) ->
        req(post, Base ++ "/api/plan-cards", [{"create-key", binary_to_list(uuid())} | Hs], Body)
    end,

    %% --- a guest: 7 plans in a day, the 8th refused ---
    {200, H1, _} = req(post, Base ++ "/api/auth/guest", [Xff], <<>>),
    Ck = {"cookie", "fh_session=" ++ session_cookie(H1)},
    GuestId = scalar("SELECT user_id::text FROM users WHERE guest "
                     "ORDER BY created_at DESC LIMIT 1", []),
    Made = [begin {202, _, R} = Create([Xff, Ck]),
                  maps:get(<<"plan_card_id">>, fh_shell_util:json_decode(R)) end
            || _ <- lists:seq(1, 7)],
    expect(views(GuestId) =:= 7 andalso stub_n() =:= 7, "a guest makes 7 plans in one day"),
    {409, _, F8} = Create([Xff, Ck]),
    expect(fh_shell_util:json_decode(F8) =:= #{<<"error">> => <<"plans_full">>,
                                                <<"limit">> => 7, <<"held">> => 7,
                                                <<"kind">> => <<"guest">>},
           "the 8th -> 409 plans_full, limit 7, held 7, kind guest"),
    expect(stub_n() =:= 7 andalso creates(guest, GuestId) =:= 7 andalso creates(addr, Addr) =:= 7,
           "the refused create called no engine and claimed no daily create"),
    #{<<"plans_saved">> := 7, <<"plans_limit">> := 7} = quota([Xff, Ck]),
    expect(true, "the quota reads 7 of 7"),

    %% --- delete one: the slot frees ---
    [Gone | _] = Made,
    {204, _, _} = req(delete, Base ++ "/api/plan-cards/" ++ binary_to_list(Gone), [Ck], <<>>),
    expect(views(GuestId) =:= 6, "DELETE /api/plan-cards/:id -> 204, the guest holds 6"),
    #{<<"plans_saved">> := 6} = quota([Xff, Ck]),
    expect(true, "the quota reads 6 of 7"),
    {404, _, _} = req(delete, Base ++ "/api/plan-cards/" ++ binary_to_list(Gone), [Ck], <<>>),
    expect(true, "deleting it again -> 404"),

    %% --- a signed-in user: 28, the 29th refused, another's plan not theirs ---
    Email = <<"caps+", (uuid())/binary, "@example.com">>,
    UserId = scalar("INSERT INTO users (email) VALUES ($1) RETURNING user_id::text", [Email]),
    Jwt = fh_shell_jwt:issue(#{user_id => UserId, email => Email,
                               roles => [<<"buyer">>], locale => <<"vi">>}),
    Auth = {"authorization", "Bearer " ++ binary_to_list(Jwt)},
    [ok = fh_shell_store:insert_plan_card_view(UserId, uuid(), <<"P">>) || _ <- lists:seq(1, 27)],
    {202, _, _} = Create([Auth]),
    {409, _, F29} = Create([Auth]),
    #{<<"error">> := <<"plans_full">>, <<"limit">> := 28, <<"held">> := 28,
      <<"kind">> := <<"user">>} = fh_shell_util:json_decode(F29),
    expect(views(UserId) =:= 28, "a user's 29th -> 409 plans_full, limit 28"),
    #{<<"plans_saved">> := 28, <<"plans_limit">> := 28} = quota([Auth]),
    expect(true, "the user's quota reads 28 of 28"),
    [Theirs | _] = tl(Made),
    {404, _, _} = req(delete, Base ++ "/api/plan-cards/" ++ binary_to_list(Theirs), [Auth], <<>>),
    expect(views(GuestId) =:= 6, "deleting another visitor's plan -> 404, nothing deleted"),
    Mine = scalar("SELECT engine_plan_card_id::text FROM plan_card_views "
                  "WHERE user_id = $1::uuid LIMIT 1", [UserId]),
    {204, _, _} = req(delete, Base ++ "/api/plan-cards/" ++ binary_to_list(Mine), [Auth], <<>>),

    %% --- the last slot, two creates at once: one plan ---
    Self = self(),
    [spawn(fun() -> {S, _, _} = Create([Auth]), Self ! {done, S} end) || _ <- [1, 2]],
    Got = lists:sort([receive {done, S} -> S after 10000 -> timeout end || _ <- [1, 2]]),
    expect(Got =:= [202, 409] andalso views(UserId) =:= 28,
           "a delete frees one slot; two creates at once for it -> one 202, one 409"),

    io:format("~nALL PASSED~n"),
    halt(0).

compile_load(File) ->
    {ok, Mod, Bin} = compile:file(File, [binary, return_errors]),
    {module, Mod} = code:load_binary(Mod, File, Bin),
    Mod.

uuid() -> fh_shell_util:uuid4().
stub_n() -> ets:lookup_element(stub_creates, n, 2).

views(UserId) ->
    scalar("SELECT count(*)::int FROM plan_card_views WHERE user_id = $1::uuid", [UserId]).

creates(Kind, Key) when is_list(Key) -> creates(Kind, list_to_binary(Key));
creates(Kind, Key) -> fh_shell_store:guest_creates_today(Kind, Key).

quota(Headers) ->
    {200, _, B} = req(get, Base = "http://127.0.0.1:" ++ integer_to_list(?SHELL_PORT)
                      ++ "/api/me/quota", Headers, none),
    _ = Base,
    fh_shell_util:json_decode(B).

session_cookie(Headers) ->
    [V | _] = [V || {K, V} <- Headers, string:lowercase(K) =:= "set-cookie",
                    lists:prefix("fh_session=", V)],
    hd(string:split(lists:nthtail(length("fh_session="), V), ";")).

expect(true, Label)  -> io:format("  ok  ~ts~n", [Label]);
expect(false, Label) -> io:format("FAIL  ~ts~n", [Label]), halt(1).

req(Method, Url, Headers, none) ->
    {ok, {{_, Status, _}, RespHeaders, Resp}} =
        httpc:request(Method, {Url, Headers}, [], [{body_format, binary}]),
    {Status, RespHeaders, Resp};
req(delete, Url, Headers, _) -> req(delete, Url, Headers, none);
req(Method, Url, Headers, Body) ->
    {ok, {{_, Status, _}, RespHeaders, Resp}} =
        httpc:request(Method, {Url, Headers, "application/json", Body}, [],
                      [{body_format, binary}]),
    {Status, RespHeaders, Resp}.

scalar(SQL, Params) ->
    #{rows := [{Val}]} = pgo:query(SQL, Params),
    Val.
