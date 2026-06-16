#!/usr/bin/env escript
%%! -sname fh_shell_billing_checkout_smoke
%%
%% 8-S5e-3: the outbound Stripe Checkout (billing.md §9). Boots fh_shell, points
%% STRIPE_API_BASE at a stub Stripe (the GOOGLE_TOKEN_URL posture — no live Stripe),
%% and drives POST /api/billing/subscribe. Asserts:
%%
%%   HAPPY PATH — an authed user POSTing {tier: plus} gets 200 {url} (the stub's hosted
%%   URL), and the stub received the right form: mode=subscription, the plus price,
%%   client_reference_id = the user (so the webhook can bind it back), metadata.tier=plus.
%%   A pro subscribe sends the pro price.
%%
%%   GUARDS — free / an unknown tier is 400 (free is the default, not a checkout);
%%   an unauthenticated POST is 401; a missing STRIPE_SECRET_KEY is 503 (config gap,
%%   not the user's fault). create_checkout_session/2 directly reports the config errors.
%%
%%   SHELL_DATABASE_URL=postgres://shell:shell_dev_pw@localhost:5434/firsthomey_shell?sslmode=disable \
%%   ERL_LIBS=_build/default/lib escript test/billing_checkout_smoke.escript

-mode(compile).

-define(SHELL_PORT, 8090).
-define(STUB_PORT, 8091).
-define(PRICE_PLUS, <<"price_plus_smoke">>).
-define(PRICE_PRO, <<"price_pro_smoke">>).

main(_) ->
    os:putenv("FH_SHELL_HTTP_PORT", integer_to_list(?SHELL_PORT)),
    os:putenv("SHELL_JWT_SECRET", "billing-checkout-smoke-secret"),
    os:putenv("USAGE_CONSUMER_POLL_MS", "3600000"),
    os:putenv("STRIPE_SECRET_KEY", "sk_test_smoke"),
    os:putenv("STRIPE_PRICE_PLUS", binary_to_list(?PRICE_PLUS)),
    os:putenv("STRIPE_PRICE_PRO", binary_to_list(?PRICE_PRO)),
    os:putenv("STRIPE_API_BASE", "http://localhost:" ++ integer_to_list(?STUB_PORT)),
    os:putenv("APP_BASE_URL", "http://localhost:5173"),
    {_Pub, Priv} = crypto:generate_key(eddsa, ed25519),
    os:putenv("SHELL_TENANT_ID", binary_to_list(uuid())),
    os:putenv("SHELL_TENANT_PRIVKEY", binary_to_list(base64:encode(Priv))),
    {ok, _} = application:ensure_all_started(fh_shell),
    {ok, _} = application:ensure_all_started(inets),

    StubMod = compile_load("test/billing_stripe_stub.erl"),
    Dispatch = cowboy_router:compile([{'_', [
        {"/v1/checkout/sessions", StubMod, []}
    ]}]),
    {ok, _} = cowboy:start_clear(stripe_stub_listener, [{port, ?STUB_PORT}],
                                 #{env => #{dispatch => Dispatch}}),

    UserId = new_user(),
    Jwt = fh_shell_jwt:issue(#{user_id => UserId, email => email(),
                               roles => [<<"buyer">>], locale => <<"vi">>}),
    Auth = [{"authorization", "Bearer " ++ binary_to_list(Jwt)}],
    Url = "http://localhost:" ++ integer_to_list(?SHELL_PORT) ++ "/api/billing/subscribe",

    %% ── happy path: plus ─────────────────────────────────────────────────────
    {200, R1} = req(post, Url, Auth, json(#{<<"tier">> => <<"plus">>})),
    #{<<"url">> := SessionUrl} = decode(R1),
    expect(SessionUrl =:= <<"https://checkout.stripe.com/c/pay/cs_test_smoke">>,
           "subscribe(plus) -> 200 with the Stripe hosted url"),
    Form = persistent_term:get({stripe_stub, form}),
    expect(form(<<"mode">>, Form) =:= <<"subscription">>, "stripe form mode=subscription"),
    expect(form(<<"line_items[0][price]">>, Form) =:= ?PRICE_PLUS, "plus price sent"),
    expect(form(<<"client_reference_id">>, Form) =:= UserId,
           "client_reference_id = user (webhook binds it back)"),
    expect(form(<<"metadata[tier]">>, Form) =:= <<"plus">>, "metadata.tier=plus sent"),

    %% ── pro sends the pro price ───────────────────────────────────────────────
    {200, _} = req(post, Url, Auth, json(#{<<"tier">> => <<"pro">>})),
    expect(form(<<"line_items[0][price]">>, persistent_term:get({stripe_stub, form}))
               =:= ?PRICE_PRO, "subscribe(pro) sends the pro price"),

    %% ── guards ────────────────────────────────────────────────────────────────
    {400, _} = req(post, Url, Auth, json(#{<<"tier">> => <<"free">>})),
    expect(true, "subscribe(free) -> 400 (free is the default, not a checkout)"),
    {400, _} = req(post, Url, Auth, json(#{<<"tier">> => <<"bogus">>})),
    expect(true, "subscribe(unknown tier) -> 400"),
    {401, _} = req(post, Url, [], json(#{<<"tier">> => <<"plus">>})),
    expect(true, "subscribe without a session -> 401"),

    %% ── direct config-gap errors (create_checkout_session/2) ──────────────────
    expect(fh_shell_billing:create_checkout_session(UserId, <<"free">>)
               =:= {error, price_not_configured},
           "free has no price -> price_not_configured"),
    os:unsetenv("STRIPE_SECRET_KEY"),
    {503, _} = req(post, Url, Auth, json(#{<<"tier">> => <<"plus">>})),
    expect(true, "missing STRIPE_SECRET_KEY -> 503 (config gap)"),
    expect(fh_shell_billing:create_checkout_session(UserId, <<"plus">>)
               =:= {error, secret_key_not_configured},
           "no secret key -> secret_key_not_configured"),

    io:format("~nALL PASSED~n"),
    halt(0).

%% --- helpers ---

compile_load(File) ->
    {ok, Mod, Bin} = compile:file(File, [binary, return_errors]),
    {module, Mod} = code:load_binary(Mod, File, Bin),
    Mod.

uuid()  -> fh_shell_util:uuid4().
email() -> <<"checkout+", (uuid())/binary, "@example.com">>.
json(M) -> fh_shell_util:json_encode(M).
decode(B) -> fh_shell_util:json_decode(B).

new_user() ->
    scalar("INSERT INTO users (email) VALUES ($1) RETURNING user_id::text", [email()]).

form(Key, KVs) -> proplists:get_value(Key, KVs).

scalar(SQL, Params) ->
    #{rows := [{Val}]} = pgo:query(list_to_binary(SQL), Params),
    Val.

req(Method, Url, Headers, Body) ->
    Request = {Url, Headers, "application/json", Body},
    {ok, {{_, Status, _}, _, Resp}} =
        httpc:request(Method, Request, [], [{body_format, binary}]),
    {Status, Resp}.

expect(true, Label)  -> io:format("  ok  ~s~n", [Label]);
expect(false, Label) -> io:format("FAIL  ~s~n", [Label]), halt(1).
