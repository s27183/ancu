-module(fh_shell_billing).

-behaviour(gen_server).

%% Commerce core (billing.md §9/§11) — Stripe subscription lifecycle, one-time add-on
%% charges, and the admin allowlist. Billing is SHELL-owned (constraint #11, principle 5):
%% the engine emits
%% `usage` (tokens, no cost) and never gates on money; this module + fh_shell_meter
%% are where money lives. Reshaped from aleap, whose rail-webhook verifier was the
%% "deferred GTM piece" — here the FirstHomey billing.md §9 contract IS in scope.
%%
%% This module is a gen_server for ONE reason: it owns the admin-email allowlist ETS
%% table (materialised at boot from ADMIN_EMAILS, billing.md §9). Everything else it
%% does is stateless (checkout-session creation, webhook verification + subscription
%% upsert) — pure functions / DB writes that need no process state. Same shape as
%% fh_shell_meter (a gen_server that owns its cache table but whose gate/1 is pure).
%%
%% 8-S5e-1: the admin allowlist.
%%   * ADMIN_EMAILS (comma-separated) → ETS at boot; is_admin/1 a lock-free read.
%%   * The usage consumer calls is_admin/1 to set usage_records.billed = false for an
%%     admin: their turns METER normally (cost is real, kept for attribution) but are
%%     not billed (§9). Conservative on a miss — an unknown email is billed (charged),
%%     never the reverse.
%% 8-S5e-2: the inbound Stripe webhook — handle_webhook/2.
%%   * Verifies the Stripe-Signature header (HMAC-SHA256 over `t.body`, the v1 scheme,
%%     STRIPE_WEBHOOK_SECRET, 300s replay tolerance) over the RAW body — the handler must
%%     pass the unparsed bytes (re-encoding would change them and break the signature).
%%   * Routes the subscription lifecycle: checkout.session.completed BINDS user↔sub
%%     (the only event carrying both); customer.subscription.created/updated/deleted
%%     maintain status (Stripe's 8 states folded to our 3) + period + tier (from the
%%     price). Tier change takes effect on the user's next pre-call gate (§7).
%% 8-S5e-3: the outbound Stripe Checkout — create_checkout_session/2.
%%   * POSTs (form-encoded, Basic-auth with STRIPE_SECRET_KEY) to create a mode=subscription
%%     Checkout Session for (user, tier) and returns its hosted `url`. The API base is
%%     env-overridable (STRIPE_API_BASE) so a test points it at a stub — the same posture
%%     as the Google token-exchange (GOOGLE_TOKEN_URL). client_reference_id + metadata.tier
%%     are what the webhook (8-S5e-2) reads back to bind the user and set the tier.

-export([start_link/0, is_admin/1, handle_webhook/2, create_checkout_session/2,
         create_addon_checkout/3]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).

-define(SERVER, ?MODULE).
-define(ADMIN_TAB, fh_shell_admin_emails).
-define(SIG_TOLERANCE_S, 300).   %% Stripe's default replay window (5 min)

%% ── API ─────────────────────────────────────────────────────────────────────

-spec start_link() -> {ok, pid()} | ignore | {error, term()}.
start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

%% Is this email on the admin allowlist (billing.md §9)? A lock-free public ETS read
%% from the caller's process. Email is normalised (trim + lowercase) before lookup so
%% the JWT/DB casing never matters. Fail-safe: if the table is not up yet (server
%% still booting), return false — i.e. bill the turn. The safe default for an admin
%% bypass is to CHARGE, never to silently exempt; the next read self-corrects.
-spec is_admin(binary() | undefined) -> boolean().
is_admin(Email) when is_binary(Email) ->
    Key = normalize(Email),
    try ets:member(?ADMIN_TAB, Key)
    catch error:badarg -> false
    end;
is_admin(_) -> false.

%% ── webhook (billing.md §9) ──────────────────────────────────────────────────

%% Process one inbound Stripe webhook: verify the signature over the RAW body, then
%% route the event. Returns a {Status, BodyMap} the handler relays verbatim. We ACK
%% (200) anything whose signature is valid — handled, ignored (unknown type), or even
%% malformed-after-verify — because a Stripe RETRY won't fix our parsing; only a
%% signature/secret failure is a 400. RawBody MUST be the exact bytes Stripe sent
%% (the handler reads them unparsed); SigHeader is the `stripe-signature` header.
-spec handle_webhook(binary(), binary() | undefined) ->
    {200 | 400, map()}.
handle_webhook(RawBody, SigHeader) ->
    case verify_signature(RawBody, SigHeader) of
        ok ->
            try route_event(fh_shell_util:json_decode(RawBody)) of
                Result -> {200, #{<<"received">> => true, <<"result">> => Result}}
            catch Class:Reason ->
                logger:warning("[billing] webhook body unparseable: ~p:~p", [Class, Reason]),
                {200, #{<<"received">> => true, <<"result">> => <<"unparsable">>}}
            end;
        {error, Reason} ->
            logger:warning("[billing] webhook signature rejected: ~p", [Reason]),
            {400, #{<<"error">> => <<"signature_verification_failed">>}}
    end.

%% Stripe-Signature: `t=<unix>,v1=<hex hmac>[,v1=<hex>...]`. The signed payload is
%% `<t>.<raw body>`; the MAC is HMAC-SHA256 keyed by STRIPE_WEBHOOK_SECRET, hex. We
%% reject if: the secret is unset (cannot verify → never trust an unverifiable call),
%% the header is missing/malformed, the timestamp is outside the replay window, or no
%% provided v1 matches (constant-time compare). t.body uses real wall-clock for the
%% recency check — that is the external protocol's anti-replay clock, NOT an internal
%% correctness/period decision (erlang-design-checklist §15 is about the latter).
-spec verify_signature(binary(), binary() | undefined) -> ok | {error, atom()}.
verify_signature(_RawBody, undefined) -> {error, no_signature_header};
verify_signature(RawBody, SigHeader) ->
    case webhook_secret() of
        undefined -> {error, secret_not_configured};
        Secret ->
            case parse_sig_header(SigHeader) of
                {ok, Ts, V1s} ->
                    case fresh_timestamp(Ts) of
                        true ->
                            Signed = <<Ts/binary, ".", RawBody/binary>>,
                            Expected = hmac_hex(Secret, Signed),
                            case lists:any(fun(V1) -> const_eq(Expected, V1) end, V1s) of
                                true  -> ok;
                                false -> {error, no_matching_signature}
                            end;
                        false -> {error, timestamp_out_of_tolerance}
                    end;
                error -> {error, malformed_signature_header}
            end
    end.

%% Split `t=..,v1=..,v1=..` into the timestamp + every v1 (ignore v0 and any other
%% scheme — only v1 is live; ignoring others prevents downgrade attacks).
-spec parse_sig_header(binary()) -> {ok, binary(), [binary()]} | error.
parse_sig_header(Header) ->
    Pairs = [binary:split(P, <<"=">>) || P <- binary:split(Header, <<",">>, [global])],
    Ts = first_val(<<"t">>, Pairs),
    V1s = [V || [<<"v1">>, V] <- Pairs],
    case Ts of
        undefined -> error;
        _ when V1s =:= [] -> error;
        _ -> {ok, Ts, V1s}
    end.

first_val(Key, Pairs) ->
    case [V || [K, V] <- Pairs, string:trim(K) =:= Key] of
        [V | _] -> V;
        []      -> undefined
    end.

-spec fresh_timestamp(binary()) -> boolean().
fresh_timestamp(TsBin) ->
    try
        Ts = binary_to_integer(string:trim(TsBin)),
        Now = erlang:system_time(second),
        abs(Now - Ts) =< ?SIG_TOLERANCE_S
    catch error:badarg -> false
    end.

hmac_hex(Secret, Data) ->
    binary:encode_hex(crypto:mac(hmac, sha256, Secret, Data), lowercase).

%% Constant-time compare (timing-attack safe) — crypto:hash_equals/2 only when the
%% lengths match, which it requires.
const_eq(A, B) when byte_size(A) =:= byte_size(B) -> crypto:hash_equals(A, B);
const_eq(_, _) -> false.

%% Route a verified event. Each clause does its DB write and returns a short tag for
%% the ack body / logs. An unknown type is ignored (still acked) — Stripe sends many
%% event types; we act on checkout.session.completed (subscription link OR add-on charge,
%% by mode) + the customer.subscription.* lifecycle (billing.md §9).
-spec route_event(map()) -> binary().
route_event(#{<<"type">> := <<"checkout.session.completed">>,
              <<"data">> := #{<<"object">> := Obj}}) ->
    handle_checkout_completed(Obj);
route_event(#{<<"type">> := Type,
              <<"data">> := #{<<"object">> := Obj}})
  when Type =:= <<"customer.subscription.created">>;
       Type =:= <<"customer.subscription.updated">>;
       Type =:= <<"customer.subscription.deleted">> ->
    SubId = get_bin(<<"id">>, Obj),
    Status = fold_status(get_bin(<<"status">>, Obj)),
    Item = first_item(Obj),
    Tier = tier_for_price(get_in(Item, [<<"price">>, <<"id">>])),
    PStart = get_epoch(<<"current_period_start">>, Item),
    PEnd   = get_epoch(<<"current_period_end">>, Item),
    case is_binary(SubId) of
        true ->
            {ok, Outcome} =
                fh_shell_store:update_subscription(SubId, Status, Tier, PStart, PEnd),
            logger:info("[billing] ~s sub=~s -> status=~s tier=~s (~p)",
                        [Type, SubId, Status, Tier, Outcome]),
            atom_to_binary(Outcome, utf8);
        false ->
            <<"missing_subscription_id">>
    end;
%% Every other type is acked 200 and ignored, invoice.* included (measured 2026-10-08:
%% read the clauses above). A renewal still lands through customer.subscription.updated,
%% which carries the new period; docs/architecture/billing.md:161 lists invoice.paid among
%% the handled events, which this code does not do (concluded: that line is the stale one).
route_event(#{<<"type">> := Type}) ->
    logger:debug("[billing] ignoring event type ~s", [Type]),
    <<"ignored">>;
route_event(_) ->
    <<"ignored">>.

%% A completed Checkout Session is either a tier SUBSCRIPTION (mode=subscription, 8-S5e)
%% or a one-time ADD-ON payment (mode=payment, 8-S5f). Dispatch on `mode`; if absent,
%% fall back to the shape (a `subscription` id → subscription; a `payment_intent` →
%% add-on) so older fixtures / belt-and-suspenders still route correctly.
-spec handle_checkout_completed(map()) -> binary().
handle_checkout_completed(#{<<"mode">> := <<"subscription">>} = Obj) ->
    link_checkout_subscription(Obj);
handle_checkout_completed(#{<<"mode">> := <<"payment">>} = Obj) ->
    record_addon_charge(Obj);
handle_checkout_completed(Obj) ->
    case get_bin(<<"subscription">>, Obj) of
        S when is_binary(S) -> link_checkout_subscription(Obj);
        _ ->
            case get_bin(<<"payment_intent">>, Obj) of
                P when is_binary(P) -> record_addon_charge(Obj);
                _ -> <<"incomplete_session">>
            end
    end.

%% Bind user↔subscription from the checkout session (the only event carrying both, §9).
link_checkout_subscription(Obj) ->
    UserId = get_bin(<<"client_reference_id">>, Obj),
    SubId  = get_bin(<<"subscription">>, Obj),
    Tier   = session_tier(Obj),
    case {UserId, SubId} of
        {U, S} when is_binary(U), is_binary(S) ->
            ok = fh_shell_store:link_subscription(U, S, Tier),
            logger:info("[billing] linked subscription user=~s sub=~s tier=~s", [U, S, Tier]),
            <<"linked">>;
        _ ->
            logger:warning("[billing] checkout.session.completed missing "
                           "client_reference_id/subscription: ~p", [Obj]),
            <<"incomplete_session">>
    end.

%% Record a one-time add-on from a PAID mode=payment session (billing.md §9). We record
%% only when payment_status = "paid" (a card payment); an async method can complete the
%% session "unpaid" and settle later via checkout.session.async_payment_succeeded — that
%% event is not wired in Wedge 1a (card-only), so an unpaid completion is ACKed but not
%% recorded. Everything reads off CONFIRMED session fields (no metadata-propagation
%% dependency): client_reference_id = user, metadata.kind = the add-on, amount_total =
%% the charged cents, payment_intent = the idempotency key, metadata.plan_card_id = the
%% optional context. record_charge/5 is idempotent on the PaymentIntent (webhook retries).
record_addon_charge(Obj) ->
    case get_bin(<<"payment_status">>, Obj) of
        <<"paid">> ->
            UserId     = get_bin(<<"client_reference_id">>, Obj),
            Kind       = session_meta(<<"kind">>, Obj),
            Cents      = get_int(<<"amount_total">>, Obj),
            PiId       = get_bin(<<"payment_intent">>, Obj),
            PlanCardId = session_meta(<<"plan_card_id">>, Obj),
            case {UserId, Kind, Cents} of
                {U, K, C} when is_binary(U), is_binary(K), is_integer(C) ->
                    {ok, Outcome} = fh_shell_store:record_charge(U, K, C, PiId, PlanCardId),
                    logger:info("[billing] add-on charge user=~s kind=~s cents=~B (~p)",
                                [U, K, C, Outcome]),
                    charge_result(Outcome);
                _ ->
                    logger:warning("[billing] mode=payment session missing "
                                   "client_reference_id/metadata.kind/amount_total: ~p", [Obj]),
                    <<"incomplete_session">>
            end;
        Other ->
            logger:info("[billing] mode=payment session not paid (~p) - acked, not recorded",
                        [Other]),
            <<"unpaid">>
    end.

charge_result(duplicate) -> <<"duplicate">>;
charge_result(_ChargeId) -> <<"charged">>.

%% ── checkout (billing.md §9) ─────────────────────────────────────────────────

%% Create a Stripe Checkout Session (mode=subscription) for UserId on Tier and return
%% its hosted URL. Only plus/pro are subscribable (free has no Stripe price). The user
%% binding rides on client_reference_id (the webhook reads it back) + metadata.tier; the
%% subscription's eventual tier is reconfirmed from the price, so these two are belt and
%% suspenders. Returns {ok, Url} | {error, Reason}; the handler maps a config gap to 503
%% and a Stripe/transport failure to 502.
-spec create_checkout_session(binary(), binary()) ->
    {ok, binary()} | {error, atom()}.
create_checkout_session(UserId, Tier) ->
    case {stripe_secret_key(), price_for_tier(Tier)} of
        {undefined, _} -> {error, secret_key_not_configured};
        {_, undefined} -> {error, price_not_configured};
        {Key, Price} ->
            Form = uri_string:compose_query([
                {"mode", "subscription"},
                {"line_items[0][price]", binary_to_list(Price)},
                {"line_items[0][quantity]", "1"},
                {"success_url", binary_to_list(success_url())},
                {"cancel_url", binary_to_list(cancel_url())},
                {"client_reference_id", binary_to_list(UserId)},
                {"metadata[user_id]", binary_to_list(UserId)},
                {"metadata[tier]", binary_to_list(Tier)}
            ]),
            post_checkout(Key, Form)
    end.

%% The subscribable tier's Stripe price; undefined for free or an unknown tier (free is
%% not a subscription) or an unconfigured price.
price_for_tier(<<"plus">>) -> price_env("STRIPE_PRICE_PLUS");
price_for_tier(<<"pro">>)  -> price_env("STRIPE_PRICE_PRO");
price_for_tier(_)          -> undefined.

%% Create a Stripe Checkout Session (mode=PAYMENT — a one-time charge) for an add-on
%% (billing.md §9) and return its hosted URL. The add-ons are ORTHOGONAL to the tier
%% subscription: doc_review ($40, the only self-serve add-on live in Wedge 1a), timnha
%% (curator-set price, no self-serve amount until the curator console lands), success_fee
%% (REA-paid ledger, never a buyer checkout). The amount is SERVER-determined per kind
%% (addon_amount_cents/1 — env-tunable; never client-supplied), priced inline via price_data
%% (one-time add-ons have per-engagement amounts, so an inline price beats pre-creating a
%% Stripe Price — the subscription path needs a recurring Price, this does not). The user
%% binding + add-on context ride client_reference_id + metadata (kind, plan_card_id), which
%% the webhook reads back off the mode=payment session (record_addon_charge/1). Returns
%% {ok, Url} | {error, Reason}; the handler maps a config gap to 503 and a Stripe/transport
%% failure to 502. PlanCardId is `undefined` when the add-on has no plan-card context.
-spec create_addon_checkout(binary(), binary(), binary() | undefined) ->
    {ok, binary()} | {error, atom()}.
create_addon_checkout(UserId, Kind, PlanCardId) ->
    case {stripe_secret_key(), addon_amount_cents(Kind)} of
        {undefined, _} -> {error, secret_key_not_configured};
        {_, undefined} -> {error, price_not_configured};
        {Key, Cents} ->
            Form = uri_string:compose_query(
                [{<<"mode">>, <<"payment">>},
                 {<<"line_items[0][price_data][currency]">>, addon_currency()},
                 {<<"line_items[0][price_data][unit_amount]">>, integer_to_binary(Cents)},
                 {<<"line_items[0][price_data][product_data][name]">>, addon_label(Kind)},
                 {<<"line_items[0][quantity]">>, <<"1">>},
                 {<<"success_url">>, success_url()},
                 {<<"cancel_url">>, cancel_url()},
                 {<<"client_reference_id">>, UserId},
                 {<<"metadata[user_id]">>, UserId},
                 {<<"metadata[kind]">>, Kind}
                 | plan_card_meta(PlanCardId)],
                [{encoding, utf8}]),
            post_checkout(Key, Form)
    end.

plan_card_meta(PlanCardId) when is_binary(PlanCardId) ->
    [{<<"metadata[plan_card_id]">>, PlanCardId}];
plan_card_meta(_) -> [].

%% The server-set price (cents) for an add-on kind. doc_review defaults to $40 (billing.md
%% §9), env-tunable. timnha has NO default (curator-set per engagement, $200–500 — not
%% self-serve until the curator console passes an explicit amount); success_fee is REA-paid
%% ledger, never a buyer checkout. undefined → price_not_configured (the handler → 503/400).
addon_amount_cents(<<"doc_review">>) -> amount_env("ADDON_AMOUNT_DOC_REVIEW", 4000);
addon_amount_cents(<<"timnha">>)     -> amount_env("ADDON_AMOUNT_TIMNHA", undefined);
addon_amount_cents(_)                -> undefined.

%% The product name shown on the Stripe-hosted checkout page (bilingual-friendly UTF-8 —
%% compose_query encodes it utf8, not via a byte-fragile formatter).
addon_label(<<"doc_review">>) -> <<(fh_shell_util:brand())/binary, " — Contract & Section 32 review"/utf8>>;
addon_label(<<"timnha">>)     -> <<(fh_shell_util:brand())/binary, " — Tìm Nhà property search"/utf8>>;
addon_label(_)                -> <<(fh_shell_util:brand())/binary, " add-on">>.

%% AUD, lowercase ISO per Stripe's unit_amount currency convention.
addon_currency() -> <<"aud">>.

post_checkout(Key, Form) ->
    Url = stripe_api_base() ++ "/v1/checkout/sessions",
    Auth = "Basic " ++ base64:encode_to_string(Key ++ ":"),
    Request = {Url, [{"authorization", Auth}], "application/x-www-form-urlencoded", Form},
    case httpc:request(post, Request, [], [{body_format, binary}]) of
        {ok, {{_, 200, _}, _, Resp}} ->
            case fh_shell_util:json_decode(Resp) of
                #{<<"url">> := SessionUrl} when is_binary(SessionUrl) -> {ok, SessionUrl};
                _ -> {error, no_session_url}
            end;
        {ok, {{_, Status, _}, _, Resp}} ->
            logger:warning("[billing] Stripe checkout create failed (~B): ~s", [Status, Resp]),
            {error, stripe_error};
        {error, Reason} ->
            logger:warning("[billing] Stripe checkout transport error: ~p", [Reason]),
            {error, transport_error}
    end.

stripe_secret_key() ->
    case os:getenv("STRIPE_SECRET_KEY") of
        false -> undefined;
        ""    -> undefined;
        K     -> K
    end.

%% Stripe API base, env-overridable so a test points it at a stub (default live API).
stripe_api_base() ->
    case os:getenv("STRIPE_API_BASE") of
        false -> "https://api.stripe.com";
        ""    -> "https://api.stripe.com";
        Base  -> Base
    end.

success_url() -> app_url(<<"/?checkout=success">>).
cancel_url()  -> app_url(<<"/?checkout=cancel">>).

%% APP_BASE_URL is the browser origin (same as fh_shell_h_auth) — checkout returns the
%% user there. Dev default is the vite server.
app_url(Path) ->
    Base = case os:getenv("APP_BASE_URL") of
        false -> <<"http://localhost:5173">>;
        ""    -> <<"http://localhost:5173">>;
        Val   -> list_to_binary(Val)
    end,
    <<Base/binary, Path/binary>>.

%% ── gen_server ──────────────────────────────────────────────────────────────

init([]) ->
    %% public so is_admin/1 reads lock-free from any process; this server is only the
    %% table's owning (long-lived) process. The set is static after boot.
    _ = ets:new(?ADMIN_TAB, [named_table, public, set, {read_concurrency, true}]),
    Emails = load_admin_emails(),
    [ets:insert(?ADMIN_TAB, {E, true}) || E <- Emails],
    logger:info("[billing] start admin_allowlist=~p entries", [length(Emails)]),
    {ok, #{}}.

handle_call(_Req, _From, State) ->
    {reply, {error, unsupported}, State}.

handle_cast(_Msg, State) -> {noreply, State}.
handle_info(_Info, State) -> {noreply, State}.
terminate(_Reason, _State) -> ok.
code_change(_, State, _) -> {ok, State}.

%% ── Internal ────────────────────────────────────────────────────────────────

%% ADMIN_EMAILS is a comma-separated list (e.g. "ops@x.com, son@panalogy-lab.com").
%% Each entry is trimmed + lowercased; blanks dropped. Absent/empty → no admins.
-spec load_admin_emails() -> [binary()].
load_admin_emails() ->
    case os:getenv("ADMIN_EMAILS") of
        false -> [];
        ""    -> [];
        Raw   ->
            Parts = binary:split(list_to_binary(Raw), <<",">>, [global]),
            [normalize(P) || P <- Parts, normalize(P) =/= <<>>]
    end.

-spec normalize(binary()) -> binary().
normalize(Email) ->
    string:lowercase(string:trim(Email)).

%% --- webhook helpers ---

webhook_secret() ->
    case os:getenv("STRIPE_WEBHOOK_SECRET") of
        false -> undefined;
        ""    -> undefined;
        S     -> list_to_binary(S)
    end.

%% A subscription's tier is the price it carries (the SOT for what the user pays for),
%% reverse-mapped from the STRIPE_PRICE_* env. An unknown/absent price → free (the
%% conservative floor — never grant a paid quota for a price we don't recognise). Free
%% has no Stripe price (no subscription), so it only appears via this fallback.
-spec tier_for_price(binary() | undefined) -> binary().
tier_for_price(PriceId) ->
    Pro  = price_env("STRIPE_PRICE_PRO"),
    Plus = price_env("STRIPE_PRICE_PLUS"),
    if  is_binary(PriceId), PriceId =:= Pro  -> <<"pro">>;
        is_binary(PriceId), PriceId =:= Plus -> <<"plus">>;
        true -> <<"free">>
    end.

price_env(Name) ->
    case os:getenv(Name) of
        false -> undefined;
        ""    -> undefined;
        V     -> list_to_binary(V)
    end.

%% The tier we stamped into the checkout session metadata (metadata.tier). Absent → free
%% (the subsequent customer.subscription.* event reconfirms tier from the price anyway).
session_tier(Obj) ->
    case get_in(Obj, [<<"metadata">>, <<"tier">>]) of
        T when is_binary(T) -> T;
        _ -> <<"free">>
    end.

%% A string field from the checkout session metadata (metadata.<Key>), or undefined.
%% Used for the add-on kind + plan_card_id we stamped at create_addon_checkout time.
session_meta(Key, Obj) ->
    case get_in(Obj, [<<"metadata">>, Key]) of
        V when is_binary(V) -> V;
        _ -> undefined
    end.

%% Fold Stripe's eight subscription statuses into our three (the subscriptions.status
%% CHECK: active|past_due|canceled). active/trialing → active (a trial gets quota);
%% past_due/unpaid → past_due; everything else (canceled/incomplete/incomplete_expired/
%% paused/unknown) → canceled. The §7 gate honours only 'active', so anything else falls
%% back to the free quota — the safe direction.
-spec fold_status(binary() | undefined) -> binary().
fold_status(<<"active">>)   -> <<"active">>;
fold_status(<<"trialing">>) -> <<"active">>;
fold_status(<<"past_due">>) -> <<"past_due">>;
fold_status(<<"unpaid">>)   -> <<"past_due">>;
fold_status(<<"canceled">>) -> <<"canceled">>;
fold_status(_)              -> <<"canceled">>.

%% The subscription's first item (current_period_* + price moved onto items, not the
%% subscription itself in current Stripe API versions). Empty map if absent.
first_item(Obj) ->
    case get_in(Obj, [<<"items">>, <<"data">>]) of
        [Item | _] when is_map(Item) -> Item;
        _ -> #{}
    end.

get_bin(Key, Map) ->
    case maps:get(Key, Map, undefined) of
        V when is_binary(V) -> V;
        _ -> undefined
    end.

%% A unix-epoch integer field (current_period_*), or null for the SQL bind.
get_epoch(Key, Map) ->
    case maps:get(Key, Map, null) of
        N when is_integer(N) -> N;
        _ -> null
    end.

%% An integer field (amount_total, in cents), or undefined when absent/non-integer.
get_int(Key, Map) ->
    case maps:get(Key, Map, undefined) of
        N when is_integer(N) -> N;
        _ -> undefined
    end.

%% An integer env value (e.g. an add-on amount in cents), Default when unset/blank/bad.
amount_env(Name, Default) ->
    case os:getenv(Name) of
        false -> Default;
        ""    -> Default;
        V     -> try list_to_integer(V) catch error:badarg -> Default end
    end.

%% Safe nested map fetch by a path of keys; undefined if any hop is missing/non-map.
get_in(Value, []) -> Value;
get_in(Map, [K | Rest]) when is_map(Map) ->
    get_in(maps:get(K, Map, undefined), Rest);
get_in(_, _) -> undefined.
