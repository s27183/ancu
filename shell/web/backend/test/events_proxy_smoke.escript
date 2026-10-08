#!/usr/bin/env escript
%%! -sname fh_shell_events_proxy_smoke
%%
%% 8-S4b ablation: the SSE streaming proxy over the full HTTP path
%% frontend -> shell backend, driving the real fh_shell_h_events loop handler — the
%% ownership gate (plan_card_views), the upstream httpc {stream,self} fetch, and the
%% transparent relay of frames downstream. The engine is a STREAMING stub
%% (events_proxy_stub_engine) for the same dual-`default`-pool reason as the other
%% shell smokes; identity is a test-issued user JWT.
%%
%% Run from shell/web/backend with the shell's dev Postgres up:
%%
%%   SHELL_DATABASE_URL=postgres://...@localhost:5432/ancu_shell?sslmode=disable \
%%   ERL_LIBS=_build/default/lib escript test/events_proxy_smoke.escript

-mode(compile).

-define(SHELL_PORT, 8098).
-define(STUB_PORT, 8099).

main(_) ->
    os:putenv("FH_SHELL_HTTP_PORT", integer_to_list(?SHELL_PORT)),
    os:putenv("SHELL_JWT_SECRET", "events-proxy-smoke-secret"),
    {_Pub, Priv} = crypto:generate_key(eddsa, ed25519),
    os:putenv("SHELL_TENANT_ID", binary_to_list(uuid())),
    os:putenv("SHELL_TENANT_PRIVKEY", binary_to_list(base64:encode(Priv))),

    {ok, _} = application:ensure_all_started(fh_shell),
    {ok, _} = application:ensure_all_started(inets),

    StubMod = compile_load("test/events_proxy_stub_engine.erl"),
    Dispatch = cowboy_router:compile([{'_', [
        {"/api/engine/plan-cards/:id/events", StubMod, []}
    ]}]),
    {ok, _} = cowboy:start_clear(stub_engine_listener, [{port, ?STUB_PORT}],
                                 #{env => #{dispatch => Dispatch}}),
    os:putenv("ENGINE_BASE_URL",
              "http://localhost:" ++ integer_to_list(?STUB_PORT) ++ "/api/engine"),

    Base = "http://localhost:" ++ integer_to_list(?SHELL_PORT),

    %% a user + a card they own, and a second user's card they must not see
    Email = <<"events+", (uuid())/binary, "@example.com">>,
    UserId = scalar("INSERT INTO users (email) VALUES ($1) RETURNING user_id::text", [Email]),
    CardId = uuid(),
    ok = fh_shell_store:insert_plan_card_view(UserId, CardId, <<"Cabramatta">>),

    OtherUser = scalar("INSERT INTO users (email) VALUES ($1) RETURNING user_id::text",
                       [<<"events-other+", (uuid())/binary, "@example.com">>]),
    OtherCard = uuid(),
    ok = fh_shell_store:insert_plan_card_view(OtherUser, OtherCard, <<"Footscray">>),

    %% an owned card whose ENGINE answers a non-2xx (uuid-shaped, "deadbeef…" prefix)
    ErrCard = <<"deadbeef-0000-4000-8000-000000000000">>,
    ok = fh_shell_store:insert_plan_card_view(UserId, ErrCard, <<"ErrZone">>),

    Jwt = fh_shell_jwt:issue(#{user_id => UserId, email => Email,
                               roles => [<<"buyer">>], locale => <<"vi">>}),
    Auth = [{"authorization", "Bearer " ++ binary_to_list(Jwt)}],

    %% --- POSITIVE: owned card streams; the relay forwards every frame verbatim ---
    {200, Hdrs, Body} = req(get, Base ++ "/api/plan-cards/" ++ b2l(CardId) ++ "/events", Auth),
    expect(ctype(Hdrs) =:= <<"text/event-stream">>,
           "owned card -> 200 text/event-stream (the SSE contract on the shell edge)"),
    expect(contains(Body, "event: turn_started"), "relayed the turn_started frame"),
    expect(contains(Body, "event: component_filled"), "relayed the component_filled frame"),
    expect(contains(Body, ":keepalive"), "relayed the engine's keepalive comment verbatim"),
    expect(contains(Body, "event: turn_completed"), "relayed the terminal frame; stream closed (fin)"),
    expect(contains(Body, "id: 3"), "relayed the monotonic event ids (engine owns them)"),

    %% --- non-2xx upstream relays its status + body (httpc full-response path) ---
    {503, _, ErrBody} = req(get, Base ++ "/api/plan-cards/" ++ b2l(ErrCard) ++ "/events", Auth),
    expect(contains(ErrBody, "engine_down"),
           "non-2xx engine reply relays through verbatim (503 engine_down)"),

    %% --- OWNERSHIP / AUTH ---
    {404, _, _} = req(get, Base ++ "/api/plan-cards/" ++ b2l(OtherCard) ++ "/events", Auth),
    expect(true, "unowned card -> 404"),
    {404, _, _} = req(get, Base ++ "/api/plan-cards/" ++ b2l(uuid()) ++ "/events", Auth),
    expect(true, "unknown card -> 404"),
    {404, _, _} = req(get, Base ++ "/api/plan-cards/not-a-uuid/events", Auth),
    expect(true, "malformed id -> 404 (not a 500)"),
    {401, _, _} = req(get, Base ++ "/api/plan-cards/" ++ b2l(CardId) ++ "/events", []),
    expect(true, "no user JWT -> 401"),

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

%% A sync httpc GET: the stub closes the stream (fin), so the request completes and
%% httpc reassembles the relayed body. Returns {Status, Headers, BodyBinary}.
req(Method, Url, Headers) ->
    {ok, {{_, Status, _}, RespHdrs, Resp}} =
        httpc:request(Method, {Url, Headers}, [], [{body_format, binary}]),
    {Status, RespHdrs, Resp}.

ctype(Hdrs) ->
    case lists:keyfind("content-type", 1, Hdrs) of
        {_, V} -> list_to_binary(string:lowercase(hd(string:split(V, ";"))));
        false  -> undefined
    end.

contains(Body, Sub) when is_binary(Body) ->
    string:find(Body, Sub) =/= nomatch.

scalar(SQL, Params) ->
    #{rows := [{Val}]} = pgo:query(SQL, Params),
    Val.
