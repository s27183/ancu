#!/usr/bin/env escript
%%! -sname fh_shell_create_key_smoke
%%
%% Behavior 97: a plan create survives the phone locking. Drives the real shell app
%% (its pool, migrations through 007, the route table) against a stub engine that
%% counts the creates it accepts:
%%   - POST /api/auth/guest makes a guest (cookie) for a browser with no session, and
%%     nothing for one that has a session;
%%   - a create sent twice with the same create-key makes one plan: the same
%%     plan_card_id both times, one engine create, one guest claim and one address claim;
%%   - two creates with the same key at the same moment still make one plan;
%%   - a signed-in user's repeat is the same; a malformed key is a 400;
%%   - an address at its create cap gets 429 from /api/auth/guest and no guest row.
%%
%% Run from shell/web/backend with a shell database reachable (a throwaway one):
%%
%%   SHELL_DATABASE_URL=postgres://<user>@<socket dir, %2F-escaped>/<db> \
%%   ERL_LIBS=_build/default/lib escript test/create_key_smoke.escript

-mode(compile).

-define(SHELL_PORT, 8097).
-define(STUB_PORT, 8098).

main(_) ->
    os:putenv("FH_SHELL_HTTP_PORT", integer_to_list(?SHELL_PORT)),
    os:putenv("FH_HTTP_IP", "127.0.0.1"),
    os:putenv("SHELL_JWT_SECRET", "create-key-smoke-secret"),
    %% the daily cap this test reaches (3); its default is 7 since behavior 111
    os:putenv("GUEST_DAILY_CREATES", "3"),
    {_Pub, Priv} = crypto:generate_key(eddsa, ed25519),
    os:putenv("SHELL_TENANT_ID", binary_to_list(uuid())),
    os:putenv("SHELL_TENANT_PRIVKEY", binary_to_list(base64:encode(Priv))),
    os:putenv("ENGINE_BASE_URL",
              "http://127.0.0.1:" ++ integer_to_list(?STUB_PORT) ++ "/api/engine"),

    {ok, _} = application:ensure_all_started(fh_shell),
    {ok, _} = application:ensure_all_started(inets),

    %% The stub engine: a canned 202 with fresh ids, after a short pause (so two
    %% concurrent creates overlap), counting each create in an ets counter.
    ets:new(stub_creates, [named_table, public]),
    ets:insert(stub_creates, {n, 0}),
    StubMod = compile_load("test/create_key_stub_engine.erl"),
    Dispatch = cowboy_router:compile([{'_', [{"/api/engine/plan-cards", StubMod, []}]}]),
    {ok, _} = cowboy:start_clear(create_key_stub, [{ip, {127,0,0,1}}, {port, ?STUB_PORT}],
                                 #{env => #{dispatch => Dispatch}}),

    Base = "http://127.0.0.1:" ++ integer_to_list(?SHELL_PORT),
    %% A fresh client address per run: the caps are per address and per Sydney day.
    Addr = lists:flatten(io_lib:format("10.97.~B.~B", [rand:uniform(250), rand:uniform(250)])),
    Xff = {"x-forwarded-for", Addr},
    Body = fh_shell_util:json_encode(#{<<"state">> => <<"NSW">>,
                                       <<"target_price_range">> => [600000, 700000],
                                       <<"target_zone">> => [],
                                       <<"intent">> => <<"owner_occupier">>}),

    %% --- a browser with no session becomes a guest before any create ---
    {200, H1, R1} = req(post, Base ++ "/api/auth/guest", [Xff], <<>>),
    #{<<"guest">> := true, <<"new">> := true} = fh_shell_util:json_decode(R1),
    Cookie = session_cookie(H1),
    expect(Cookie =/= undefined, "POST /api/auth/guest, no session -> 200, a guest cookie"),
    Ck = {"cookie", "fh_session=" ++ Cookie},
    {200, H2, R2} = req(post, Base ++ "/api/auth/guest", [Xff, Ck], <<>>),
    #{<<"guest">> := true, <<"new">> := false} = fh_shell_util:json_decode(R2),
    expect(session_cookie(H2) =:= undefined, "again with the cookie -> 200, nothing made"),
    GuestId = scalar("SELECT user_id::text FROM users WHERE guest "
                     "ORDER BY created_at DESC LIMIT 1", []),
    expect(creates(addr, Addr) =:= 0, "starting a guest claims no create"),

    %% --- the same tap sent twice: one plan ---
    Key = binary_to_list(uuid()),
    {202, _, C1} = req(post, Base ++ "/api/plan-cards", [Xff, Ck, {"create-key", Key}], Body),
    #{<<"plan_card_id">> := Id1} = fh_shell_util:json_decode(C1),
    {202, _, C2} = req(post, Base ++ "/api/plan-cards", [Xff, Ck, {"create-key", Key}], Body),
    #{<<"plan_card_id">> := Id2, <<"repeat">> := true} = fh_shell_util:json_decode(C2),
    expect(Id1 =:= Id2, "a repeat with the same key -> 202, the same plan_card_id"),
    expect(stub_n() =:= 1, "the engine made one plan"),
    expect(views(GuestId) =:= 1, "one plan_card_views row for the guest"),
    expect(creates(guest, GuestId) =:= 1, "one guest claim"),
    expect(creates(addr, Addr) =:= 1, "one address claim"),

    %% --- two at the same moment (a double tap): one plan ---
    Key2 = binary_to_list(uuid()),
    Self = self(),
    [spawn(fun() ->
        {202, _, R} = req(post, Base ++ "/api/plan-cards",
                          [Xff, Ck, {"create-key", Key2}], Body),
        Self ! {done, maps:get(<<"plan_card_id">>, fh_shell_util:json_decode(R))}
     end) || _ <- [1, 2]],
    [IdA, IdB] = [receive {done, I} -> I after 10000 -> timeout end || _ <- [1, 2]],
    expect(IdA =:= IdB andalso IdA =/= timeout, "two concurrent creates, one key -> one plan_card_id"),
    expect(stub_n() =:= 2, "the engine made one more plan, not two"),
    expect(creates(guest, GuestId) =:= 2, "one more guest claim"),

    %% --- a new key is a new plan ---
    {202, _, C3} = req(post, Base ++ "/api/plan-cards",
                       [Xff, Ck, {"create-key", binary_to_list(uuid())}], Body),
    #{<<"plan_card_id">> := Id3} = fh_shell_util:json_decode(C3),
    expect(Id3 =/= Id1 andalso stub_n() =:= 3, "another key -> another plan"),
    %% at the cap (3): a repeat of an earlier key still answers, a new key is refused
    {202, _, C4} = req(post, Base ++ "/api/plan-cards", [Xff, Ck, {"create-key", Key}], Body),
    #{<<"plan_card_id">> := Id1} = fh_shell_util:json_decode(C4),
    expect(true, "at the cap, a repeat of a made plan -> 202, that plan"),
    {429, _, _} = req(post, Base ++ "/api/plan-cards",
                      [Xff, Ck, {"create-key", binary_to_list(uuid())}], Body),
    expect(stub_n() =:= 3, "at the cap, a new key -> 429, no plan"),

    %% --- an address at its create cap starts no guest ---
    GuestsBefore = scalar("SELECT count(*) FROM users WHERE guest", []),
    {429, H5, R5} = req(post, Base ++ "/api/auth/guest", [Xff], <<>>),
    #{<<"error">> := <<"guest_daily_limit">>} = fh_shell_util:json_decode(R5),
    expect(session_cookie(H5) =:= undefined andalso
           scalar("SELECT count(*) FROM users WHERE guest", []) =:= GuestsBefore,
           "address at its cap -> /api/auth/guest 429, no guest made"),

    %% --- guest starts per address are bounded ---
    Addr2 = Addr ++ "1",
    Starts = [element(1, req(post, Base ++ "/api/auth/guest", [{"x-forwarded-for", Addr2}], <<>>))
              || _ <- lists:seq(1, fh_shell_guest:start_limit() + 1)],
    expect(lists:last(Starts) =:= 429 andalso
           length([S || S <- Starts, S =:= 200]) =:= fh_shell_guest:start_limit(),
           "an address starts at most start_limit() guests a day"),

    %% --- a signed-in user's repeat; a malformed key ---
    Email = <<"ck+", (uuid())/binary, "@example.com">>,
    UserId = scalar("INSERT INTO users (email) VALUES ($1) RETURNING user_id::text", [Email]),
    Jwt = fh_shell_jwt:issue(#{user_id => UserId, email => Email,
                               roles => [<<"buyer">>], locale => <<"vi">>}),
    Auth = {"authorization", "Bearer " ++ binary_to_list(Jwt)},
    Key3 = binary_to_list(uuid()),
    {202, _, U1} = req(post, Base ++ "/api/plan-cards", [Auth, {"create-key", Key3}], Body),
    {202, _, U2} = req(post, Base ++ "/api/plan-cards", [Auth, {"create-key", Key3}], Body),
    expect(maps:get(<<"plan_card_id">>, fh_shell_util:json_decode(U1)) =:=
               maps:get(<<"plan_card_id">>, fh_shell_util:json_decode(U2))
           andalso views(UserId) =:= 1,
           "signed in: the same key twice -> one plan"),
    {400, _, U3} = req(post, Base ++ "/api/plan-cards", [Auth, {"create-key", "bad key!"}], Body),
    #{<<"error">> := <<"invalid_create_key">>} = fh_shell_util:json_decode(U3),
    expect(views(UserId) =:= 1, "a malformed key -> 400, nothing made"),

    io:format("~nALL PASSED~n"),
    halt(0).

%% --- helpers ---

compile_load(File) ->
    {ok, Mod, Bin} = compile:file(File, [binary, return_errors]),
    {module, Mod} = code:load_binary(Mod, File, Bin),
    Mod.

uuid() -> fh_shell_util:uuid4().

stub_n() -> ets:lookup_element(stub_creates, n, 2).

views(UserId) ->
    scalar("SELECT count(*) FROM plan_card_views WHERE user_id = $1::uuid", [UserId]).

creates(Kind, Key) -> fh_shell_store:guest_creates_today(Kind, list_to_binary_(Key)).

list_to_binary_(B) when is_binary(B) -> B;
list_to_binary_(L) -> list_to_binary(L).

session_cookie(Headers) ->
    Found = [V || {K, V} <- Headers, string:lowercase(K) =:= "set-cookie",
                  lists:prefix("fh_session=", V)],
    case Found of
        [V | _] -> hd(string:split(lists:nthtail(length("fh_session="), V), ";"));
        [] -> undefined
    end.

expect(true, Label)  -> io:format("  ok  ~s~n", [Label]);
expect(false, Label) -> io:format("FAIL  ~s~n", [Label]), halt(1).

req(Method, Url, Headers, Body) ->
    Request = {Url, Headers, "application/json", Body},
    {ok, {{_, Status, _}, RespHeaders, Resp}} =
        httpc:request(Method, Request, [], [{body_format, binary}]),
    {Status, RespHeaders, Resp}.

scalar(SQL, Params) ->
    #{rows := [{Val}]} = pgo:query(SQL, Params),
    Val.
