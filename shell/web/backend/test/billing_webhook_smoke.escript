#!/usr/bin/env escript
%%! -sname fh_shell_billing_webhook_smoke
%%
%% 8-S5e-2: the inbound Stripe webhook (billing.md §9). Boots fh_shell and drives
%% fh_shell_billing:handle_webhook/2 over hand-signed payloads (no live Stripe), then
%% one end-to-end HTTP POST through the route. Asserts:
%%
%%   SIGNATURE — a valid t=,v1= HMAC-SHA256 over `t.body` (STRIPE_WEBHOOK_SECRET) is
%%   accepted; a wrong-secret signature, a missing header, and a stale timestamp are
%%   each 400. (The verify is over the RAW bytes — we sign exactly what we send.)
%%
%%   ROUTING — checkout.session.completed BINDS the user↔subscription (tier from the
%%   session metadata); customer.subscription.updated maintains status/period/tier from
%%   the PRICE (so a plan change plus→pro is honoured); .deleted cancels; an event for
%%   an unknown subscription is a no-op (no_match); an unknown event type is ignored.
%%   Stripe's 8 statuses fold to our 3 (trialing→active, past_due→past_due).
%%
%%   ADD-ONS (8-S5f) — a mode=payment checkout.session.completed records a one-time charge
%%   (doc_review, $40), bound to the user via client_reference_id; idempotent on the
%%   PaymentIntent (a Stripe retry → duplicate, no second row); an unpaid completion is
%%   acked but not recorded.
%%
%%   GATE TIE — after a plus link, fh_shell_store:user_tier/1 reads plus; after cancel
%%   it falls back to free (the §7 gate honours only an active subscription, 8-S5d).
%%
%%   HTTP — POST /api/billing/webhook with a signed body returns 200 and persists the
%%   row (proves the route + raw-body read + handler, fh_shell_h_billing).
%%
%%   SHELL_DATABASE_URL=postgres://shell:shell_dev_pw@localhost:5434/ancu_shell?sslmode=disable \
%%   ERL_LIBS=_build/default/lib escript test/billing_webhook_smoke.escript

-mode(compile).

-define(SHELL_PORT, 8092).
-define(SECRET, <<"whsec_test_smoke_secret">>).
-define(PRICE_PLUS, <<"price_plus_smoke">>).
-define(PRICE_PRO, <<"price_pro_smoke">>).

main(_) ->
    os:putenv("FH_SHELL_HTTP_PORT", integer_to_list(?SHELL_PORT)),
    os:putenv("SHELL_JWT_SECRET", "billing-webhook-smoke-secret"),
    os:putenv("USAGE_CONSUMER_POLL_MS", "3600000"),
    os:putenv("STRIPE_WEBHOOK_SECRET", binary_to_list(?SECRET)),
    os:putenv("STRIPE_PRICE_PLUS", binary_to_list(?PRICE_PLUS)),
    os:putenv("STRIPE_PRICE_PRO", binary_to_list(?PRICE_PRO)),
    {_Pub, Priv} = crypto:generate_key(eddsa, ed25519),
    os:putenv("SHELL_TENANT_ID", binary_to_list(uuid())),
    os:putenv("SHELL_TENANT_PRIVKEY", binary_to_list(base64:encode(Priv))),
    {ok, _} = application:ensure_all_started(fh_shell),
    {ok, _} = application:ensure_all_started(inets),

    UserId = new_user(),
    SubId = <<"sub_", (uuid())/binary>>,

    %% ── SIGNATURE rejections ─────────────────────────────────────────────────
    Body0 = encode(checkout_completed(UserId, SubId, <<"plus">>)),
    {400, _} = fh_shell_billing:handle_webhook(Body0, undefined),
    expect(true, "missing signature header -> 400"),
    {400, _} = fh_shell_billing:handle_webhook(Body0, sign(<<"wrong_secret">>, now_s(), Body0)),
    expect(true, "wrong-secret signature -> 400"),
    {400, _} = fh_shell_billing:handle_webhook(Body0, sign(?SECRET, now_s() - 10000, Body0)),
    expect(true, "stale timestamp (outside 300s tolerance) -> 400"),

    %% ── checkout.session.completed: bind user↔sub, tier from metadata ─────────
    {200, R1} = fh_shell_billing:handle_webhook(Body0, sign(?SECRET, now_s(), Body0)),
    expect(maps:get(<<"result">>, R1) =:= <<"linked">>, "checkout.session.completed -> linked"),
    expect(sub_field(UserId, "tier") =:= <<"plus">>, "subscription tier=plus (from session metadata)"),
    expect(sub_field(UserId, "status") =:= <<"active">>, "subscription status=active after link"),
    expect(sub_field(UserId, "stripe_subscription_id") =:= SubId, "stripe_subscription_id bound"),
    expect(fh_shell_store:user_tier(UserId) =:= <<"plus">>, "gate tie: user_tier reads plus (8-S5d)"),

    %% ── customer.subscription.updated: status/period, tier from PRICE ─────────
    PStart = now_s(), PEnd = now_s() + 2592000,
    Upd = encode(sub_event(<<"customer.subscription.updated">>, SubId, <<"active">>,
                           ?PRICE_PRO, PStart, PEnd)),
    {200, R2} = fh_shell_billing:handle_webhook(Upd, sign(?SECRET, now_s(), Upd)),
    expect(maps:get(<<"result">>, R2) =:= <<"updated">>, "subscription.updated -> updated"),
    expect(sub_field(UserId, "tier") =:= <<"pro">>, "plan change plus->pro from price reverse-map"),
    expect(sub_epoch(UserId, "current_period_start") =:= PStart, "current_period_start stored"),
    expect(sub_epoch(UserId, "current_period_end") =:= PEnd, "current_period_end stored"),

    %% ── status fold (8 Stripe -> 3 ours) ─────────────────────────────────────
    Tri = encode(sub_event(<<"customer.subscription.updated">>, SubId, <<"trialing">>,
                           ?PRICE_PRO, PStart, PEnd)),
    {200, _} = fh_shell_billing:handle_webhook(Tri, sign(?SECRET, now_s(), Tri)),
    expect(sub_field(UserId, "status") =:= <<"active">>, "status fold trialing->active"),
    Pd = encode(sub_event(<<"customer.subscription.updated">>, SubId, <<"past_due">>,
                          ?PRICE_PRO, PStart, PEnd)),
    {200, _} = fh_shell_billing:handle_webhook(Pd, sign(?SECRET, now_s(), Pd)),
    expect(sub_field(UserId, "status") =:= <<"past_due">>, "status fold past_due->past_due"),
    expect(fh_shell_store:user_tier(UserId) =:= <<"free">>, "gate tie: past_due not honoured -> free"),

    %% ── deleted -> canceled; unknown sub -> no_match; unknown type -> ignored ─
    Del = encode(sub_event(<<"customer.subscription.deleted">>, SubId, <<"canceled">>,
                           ?PRICE_PRO, PStart, PEnd)),
    {200, _} = fh_shell_billing:handle_webhook(Del, sign(?SECRET, now_s(), Del)),
    expect(sub_field(UserId, "status") =:= <<"canceled">>, "subscription.deleted -> status canceled"),
    Unk = encode(sub_event(<<"customer.subscription.updated">>, <<"sub_nonexistent">>,
                           <<"active">>, ?PRICE_PRO, PStart, PEnd)),
    {200, R3} = fh_shell_billing:handle_webhook(Unk, sign(?SECRET, now_s(), Unk)),
    expect(maps:get(<<"result">>, R3) =:= <<"no_match">>, "event for unknown subscription -> no_match"),
    Other = encode(#{<<"type">> => <<"invoice.payment_failed">>, <<"data">> => #{<<"object">> => #{}}}),
    {200, R4} = fh_shell_billing:handle_webhook(Other, sign(?SECRET, now_s(), Other)),
    expect(maps:get(<<"result">>, R4) =:= <<"ignored">>, "unknown event type -> ignored"),

    %% ── checkout.session.completed (mode=payment): one-time add-on charge (8-S5f) ─
    ChUser = new_user(),
    Pi1 = <<"pi_", (uuid())/binary>>,
    PlanCardId = uuid(),
    Pay1 = encode(payment_completed(ChUser, Pi1, <<"doc_review">>, 4000, PlanCardId, <<"paid">>)),
    {200, RP1} = fh_shell_billing:handle_webhook(Pay1, sign(?SECRET, now_s(), Pay1)),
    expect(maps:get(<<"result">>, RP1) =:= <<"charged">>, "paid mode=payment session -> charged"),
    expect(charge_field(Pi1, "kind") =:= <<"doc_review">>, "charge kind recorded"),
    expect(charge_field(Pi1, "amount") =:= <<"40.00">>, "charge amount = $40 (4000 cents / 100)"),
    expect(charge_field(Pi1, "plan_card_id") =:= PlanCardId, "charge plan_card_id recorded"),
    expect(charge_field(Pi1, "user_id") =:= ChUser, "charge bound to the user (client_reference_id)"),

    %% idempotent on the PaymentIntent: a Stripe RETRY must not double-charge
    {200, RP2} = fh_shell_billing:handle_webhook(Pay1, sign(?SECRET, now_s(), Pay1)),
    expect(maps:get(<<"result">>, RP2) =:= <<"duplicate">>, "replayed payment session -> duplicate"),
    expect(charge_count(ChUser) =:= 1, "still exactly one charge row after replay"),

    %% an unpaid completion (async method) is acked but NOT recorded (Wedge 1a card-only)
    Pi2 = <<"pi_", (uuid())/binary>>,
    Pay2 = encode(payment_completed(ChUser, Pi2, <<"doc_review">>, 4000, PlanCardId, <<"unpaid">>)),
    {200, RP3} = fh_shell_billing:handle_webhook(Pay2, sign(?SECRET, now_s(), Pay2)),
    expect(maps:get(<<"result">>, RP3) =:= <<"unpaid">>,
           "unpaid mode=payment session -> unpaid (not recorded)"),
    expect(charge_count(ChUser) =:= 1, "no charge row for the unpaid session"),

    %% ── END-TO-END HTTP: signed POST through the route persists a row ─────────
    HUser = new_user(),
    HSub = <<"sub_", (uuid())/binary>>,
    HBody = encode(checkout_completed(HUser, HSub, <<"pro">>)),
    Url = "http://localhost:" ++ integer_to_list(?SHELL_PORT) ++ "/api/billing/webhook",
    Hdrs = [{"stripe-signature", binary_to_list(sign(?SECRET, now_s(), HBody))}],
    {200, _} = req(post, Url, Hdrs, HBody),
    expect(sub_field(HUser, "tier") =:= <<"pro">>, "HTTP POST /api/billing/webhook persisted (pro)"),
    %% an unsigned HTTP POST is rejected at the same surface
    {400, _} = req(post, Url, [], HBody),
    expect(true, "HTTP POST without a signature -> 400"),

    io:format("~nALL PASSED~n"),
    halt(0).

%% --- event builders ---

checkout_completed(UserId, SubId, Tier) ->
    #{<<"type">> => <<"checkout.session.completed">>,
      <<"data">> => #{<<"object">> => #{
          <<"client_reference_id">> => UserId,
          <<"subscription">> => SubId,
          <<"metadata">> => #{<<"tier">> => Tier}}}}.

sub_event(Type, SubId, Status, PriceId, PStart, PEnd) ->
    #{<<"type">> => Type,
      <<"data">> => #{<<"object">> => #{
          <<"id">> => SubId,
          <<"status">> => Status,
          <<"items">> => #{<<"data">> => [#{
              <<"price">> => #{<<"id">> => PriceId},
              <<"current_period_start">> => PStart,
              <<"current_period_end">> => PEnd}]}}}}.

%% A mode=payment checkout.session.completed (8-S5f, the one-time add-on path).
payment_completed(UserId, PiId, Kind, Cents, PlanCardId, PayStatus) ->
    #{<<"type">> => <<"checkout.session.completed">>,
      <<"data">> => #{<<"object">> => #{
          <<"mode">> => <<"payment">>,
          <<"payment_status">> => PayStatus,
          <<"payment_intent">> => PiId,
          <<"amount_total">> => Cents,
          <<"currency">> => <<"aud">>,
          <<"client_reference_id">> => UserId,
          <<"metadata">> => #{<<"kind">> => Kind, <<"plan_card_id">> => PlanCardId}}}}.

%% --- Stripe signing (mirror of fh_shell_billing:verify_signature) ---

sign(Secret, Ts, Body) ->
    TsBin = integer_to_binary(Ts),
    Mac = binary:encode_hex(
            crypto:mac(hmac, sha256, Secret, <<TsBin/binary, ".", Body/binary>>), lowercase),
    <<"t=", TsBin/binary, ",v1=", Mac/binary>>.

now_s() -> erlang:system_time(second).

%% --- helpers ---

uuid() -> fh_shell_util:uuid4().
encode(Map) -> fh_shell_util:json_encode(Map).

new_user() ->
    Email = <<"webhook+", (uuid())/binary, "@example.com">>,
    scalar("INSERT INTO users (email) VALUES ($1) RETURNING user_id::text", [Email]).

%% a subscription column for the user (text-cast so timestamps come back comparable).
sub_field(UserId, Col) ->
    scalar("SELECT " ++ Col ++ "::text FROM subscriptions WHERE user_id = $1::uuid", [UserId]).

%% the stored period bound as unix epoch (computed in SQL — no param round-trip).
sub_epoch(UserId, Col) ->
    scalar("SELECT extract(epoch FROM " ++ Col ++ ")::bigint "
           "FROM subscriptions WHERE user_id = $1::uuid", [UserId]).

%% a charges column for a given PaymentIntent (text-cast so amount/uuid come back comparable).
charge_field(PiId, Col) ->
    scalar("SELECT " ++ Col ++ "::text FROM charges WHERE stripe_payment_intent_id = $1", [PiId]).

charge_count(UserId) ->
    scalar("SELECT count(*)::bigint FROM charges WHERE user_id = $1::uuid", [UserId]).

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
