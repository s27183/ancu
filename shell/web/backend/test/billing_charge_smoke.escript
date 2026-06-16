#!/usr/bin/env escript
%%! -sname fh_shell_billing_charge_smoke
%%
%% 8-S5f: the outbound one-time add-on Checkout (billing.md §9). Boots fh_shell, points
%% STRIPE_API_BASE at a stub Stripe (the GOOGLE_TOKEN_URL posture — no live Stripe), and
%% drives POST /api/billing/charge. Add-ons are mode=PAYMENT checkout sessions (orthogonal
%% to the subscription tier), priced inline (price_data). Asserts:
%%
%%   HAPPY PATH — an authed user POSTing {kind: doc_review, plan_card_id} gets 200 {url},
%%   and the stub received the right form: mode=payment, the inline price_data (aud,
%%   unit_amount=4000 = the $40 default, a product name), client_reference_id = the user
%%   (so the webhook binds it back), metadata.kind=doc_review, metadata.plan_card_id.
%%   A charge without plan_card_id omits that metadata key.
%%
%%   GUARDS — timnha has no configured amount in Wedge 1a (curator-set) -> 503; success_fee
%%   is REA-paid ledger, not a buyer checkout -> 400 invalid_kind; an unknown kind -> 400;
%%   an unauthenticated POST -> 401; a missing STRIPE_SECRET_KEY -> 503 (config gap).
%%   create_addon_checkout/3 directly reports the config errors.
%%
%%   SHELL_DATABASE_URL=postgres://shell:shell_dev_pw@localhost:5434/firsthomey_shell?sslmode=disable \
%%   ERL_LIBS=_build/default/lib escript test/billing_charge_smoke.escript

-mode(compile).

-define(SHELL_PORT, 8096).
-define(STUB_PORT, 8097).

main(_) ->
    os:putenv("FH_SHELL_HTTP_PORT", integer_to_list(?SHELL_PORT)),
    os:putenv("SHELL_JWT_SECRET", "billing-charge-smoke-secret"),
    os:putenv("USAGE_CONSUMER_POLL_MS", "3600000"),
    os:putenv("STRIPE_SECRET_KEY", "sk_test_smoke"),
    os:putenv("STRIPE_API_BASE", "http://localhost:" ++ integer_to_list(?STUB_PORT)),
    os:putenv("APP_BASE_URL", "http://localhost:5173"),
    %% leave ADDON_AMOUNT_DOC_REVIEW unset -> the $40 default; ADDON_AMOUNT_TIMNHA unset
    %% -> timnha has no self-serve price (config gap).
    os:unsetenv("ADDON_AMOUNT_DOC_REVIEW"),
    os:unsetenv("ADDON_AMOUNT_TIMNHA"),
    {_Pub, Priv} = crypto:generate_key(eddsa, ed25519),
    os:putenv("SHELL_TENANT_ID", binary_to_list(uuid())),
    os:putenv("SHELL_TENANT_PRIVKEY", binary_to_list(base64:encode(Priv))),
    {ok, _} = application:ensure_all_started(fh_shell),
    {ok, _} = application:ensure_all_started(inets),

    StubMod = compile_load("test/billing_stripe_stub.erl"),
    Dispatch = cowboy_router:compile([{'_', [
        {"/v1/checkout/sessions", StubMod, []}
    ]}]),
    {ok, _} = cowboy:start_clear(stripe_addon_stub_listener, [{port, ?STUB_PORT}],
                                 #{env => #{dispatch => Dispatch}}),

    UserId = new_user(),
    PlanCardId = uuid(),
    Jwt = fh_shell_jwt:issue(#{user_id => UserId, email => email(),
                               roles => [<<"buyer">>], locale => <<"vi">>}),
    Auth = [{"authorization", "Bearer " ++ binary_to_list(Jwt)}],
    Url = "http://localhost:" ++ integer_to_list(?SHELL_PORT) ++ "/api/billing/charge",

    %% ── happy path: doc_review with a plan-card context ───────────────────────
    {200, R1} = req(post, Url, Auth,
                    json(#{<<"kind">> => <<"doc_review">>, <<"plan_card_id">> => PlanCardId})),
    #{<<"url">> := SessionUrl} = decode(R1),
    expect(SessionUrl =:= <<"https://checkout.stripe.com/c/pay/cs_test_smoke">>,
           "charge(doc_review) -> 200 with the Stripe hosted url"),
    Form = persistent_term:get({stripe_stub, form}),
    expect(form(<<"mode">>, Form) =:= <<"payment">>, "stripe form mode=payment (one-time)"),
    expect(form(<<"line_items[0][price_data][currency]">>, Form) =:= <<"aud">>,
           "inline price_data currency=aud"),
    expect(form(<<"line_items[0][price_data][unit_amount]">>, Form) =:= <<"4000">>,
           "doc_review unit_amount=4000 ($40 default, billing.md §9)"),
    expect(is_binary(form(<<"line_items[0][price_data][product_data][name]">>, Form)),
           "inline price_data carries a product name"),
    expect(form(<<"client_reference_id">>, Form) =:= UserId,
           "client_reference_id = user (webhook binds it back)"),
    expect(form(<<"metadata[kind]">>, Form) =:= <<"doc_review">>, "metadata.kind=doc_review"),
    expect(form(<<"metadata[plan_card_id]">>, Form) =:= PlanCardId, "metadata.plan_card_id sent"),

    %% ── doc_review WITHOUT a plan-card: that metadata key is absent ────────────
    {200, _} = req(post, Url, Auth, json(#{<<"kind">> => <<"doc_review">>})),
    expect(form(<<"metadata[plan_card_id]">>, persistent_term:get({stripe_stub, form}))
               =:= undefined,
           "no plan_card_id -> metadata.plan_card_id omitted"),

    %% ── guards ────────────────────────────────────────────────────────────────
    {503, _} = req(post, Url, Auth, json(#{<<"kind">> => <<"timnha">>})),
    expect(true, "timnha has no self-serve price in Wedge 1a -> 503 (config gap)"),
    {400, _} = req(post, Url, Auth, json(#{<<"kind">> => <<"success_fee">>})),
    expect(true, "success_fee is REA-paid ledger, not a buyer checkout -> 400 invalid_kind"),
    {400, _} = req(post, Url, Auth, json(#{<<"kind">> => <<"bogus">>})),
    expect(true, "unknown kind -> 400"),
    {401, _} = req(post, Url, [], json(#{<<"kind">> => <<"doc_review">>})),
    expect(true, "charge without a session -> 401"),

    %% ── direct config-gap errors (create_addon_checkout/3) ────────────────────
    expect(fh_shell_billing:create_addon_checkout(UserId, <<"timnha">>, undefined)
               =:= {error, price_not_configured},
           "timnha (no amount) -> price_not_configured"),
    expect(fh_shell_billing:create_addon_checkout(UserId, <<"success_fee">>, undefined)
               =:= {error, price_not_configured},
           "success_fee (no amount) -> price_not_configured"),
    os:unsetenv("STRIPE_SECRET_KEY"),
    {503, _} = req(post, Url, Auth, json(#{<<"kind">> => <<"doc_review">>})),
    expect(true, "missing STRIPE_SECRET_KEY -> 503 (config gap)"),
    expect(fh_shell_billing:create_addon_checkout(UserId, <<"doc_review">>, undefined)
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
email() -> <<"charge+", (uuid())/binary, "@example.com">>.
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
