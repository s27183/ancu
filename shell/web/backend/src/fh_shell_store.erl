-module(fh_shell_store).

%% Queries over the shell's OWN database (identity + the shell's *view* of engine
%% plan cards). Thin layer over pgo against the `default` pool (fh_shell_db), the
%% sibling of fh_engine_store — but a DIFFERENT database (engine-contract §9.2/§9.3:
%% the API is the only contract, NO cross-DB joins). engine_plan_card_id is a bare
%% uuid handle, not a FK into the engine.
%%
%% UUID discipline (same trap as fh_engine_store): pgo cannot implicitly assign a
%% text OID to a `uuid` column, so every uuid bind carries an explicit `$N::uuid`
%% cast and the value is passed as its canonical string binary.

-export([insert_plan_card_view/3, owns_plan_card/2, list_plan_card_views/1]).
-export([upsert_user_by_email/1, insert_magic_token/2, redeem_magic_token/1]).
-export([link_oauth/3]).
-export([user_tier/1, user_email/1, link_subscription/3, update_subscription/5]).
-export([record_charge/5]).
-export([claim_question/2, release_question/2]).
-export([create_guest/0, claim_guest/2]).
-export([claim_guest_create/3, release_guest_create/3]).

%% --- identity (login flow) --------------------------------------------------

%% Guest plans -> P-5 · Metering, not gating -> The shell database -> a guest is a users row
%% A visitor who builds a plan signed out becomes a users row with guest = true and no
%% email (005_guest_plans.sql), so ownership (plan_card_views) and metering
%% (usage_records) need no second path. Returns {UserId, Locale}.
-spec create_guest() -> {binary(), binary()}.
create_guest() ->
    #{rows := [{UserId, Locale}]} = query(
        "INSERT INTO users (guest) VALUES (true) RETURNING user_id::text, locale", []),
    {UserId, Locale}.

%% Sign-in claims a guest (behavior 45): in one transaction its plan views and its
%% metered spend move to the real user, then the guest row is deleted (its remaining
%% rows cascade). A view the real user already holds for the same card stays theirs.
%% The engine needs nothing: it keys a card by the profile it was made under and makes
%% a Q&A session with the asker's id on the first ask (fh_engine_h_messages), and a
%% guest never asks. A GuestId that is not a guest row moves nothing. Returns the
%% number of plan views moved.
-spec claim_guest(binary(), binary()) -> non_neg_integer().
claim_guest(GuestId, UserId) ->
    {ok, Moved} = pgo:transaction(fun() ->
        case query("SELECT 1 FROM users WHERE user_id = $1::uuid AND guest FOR UPDATE",
                   [GuestId]) of
            #{rows := []} -> {ok, 0};
            #{rows := [_]} ->
                #{num_rows := N} = query(
                    "UPDATE plan_card_views v SET user_id = $2::uuid, updated_at = now() "
                    "WHERE v.user_id = $1::uuid AND NOT EXISTS (SELECT 1 FROM plan_card_views w "
                    "WHERE w.user_id = $2::uuid AND w.engine_plan_card_id = v.engine_plan_card_id)",
                    [GuestId, UserId]),
                _ = query("UPDATE usage_records SET user_id = $2::uuid WHERE user_id = $1::uuid",
                          [GuestId, UserId]),
                _ = query("DELETE FROM users WHERE user_id = $1::uuid AND guest", [GuestId]),
                {ok, N}
        end
    end),
    Moved.

%% Find-or-create a user by email. First login creates the row (role defaults to
%% 'buyer', locale to 'vi' per 001_init_shell.sql); a returning user is found by the
%% UNIQUE(email). ON CONFLICT DO UPDATE (a no-op write of the same email) so RETURNING
%% yields the row on BOTH insert and conflict — DO NOTHING would return no row on
%% conflict. Returns the identity fields the user JWT carries (fh_shell_jwt:issue/1).
-spec upsert_user_by_email(binary()) ->
    {binary(), binary(), binary(), [binary()]}.
upsert_user_by_email(Email) ->
    #{rows := [{UserId, Role, Locale, Extra}]} = query(
        "INSERT INTO users (email) VALUES ($1) "
        "ON CONFLICT (email) DO UPDATE SET email = EXCLUDED.email "
        "RETURNING user_id::text, role, locale, extra_roles",
        [Email]),
    {UserId, Role, Locale, Extra}.

%% Store a magic-link token for Email: only the sha256 HASH is persisted (the raw
%% token rides the email link), with a 15-minute expiry. A fresh request simply
%% inserts another row; redemption is single-use per row (redeem_magic_token/1).
-spec insert_magic_token(binary(), binary()) -> ok.
insert_magic_token(Email, TokenHash) ->
    _ = query(
        "INSERT INTO magic_tokens (email, token_hash, expires_at) "
        "VALUES ($1, $2, now() + interval '15 minutes')",
        [Email, TokenHash]),
    ok.

%% Atomically redeem a token by its hash: the UPDATE matches only an unredeemed,
%% unexpired row and stamps redeemed_at in the same statement, so a concurrent or
%% repeated redemption of the same link finds nothing (single-use). Returns the
%% email to sign in, or not_found for an expired / already-used / unknown token.
-spec redeem_magic_token(binary()) -> {ok, binary()} | not_found.
redeem_magic_token(TokenHash) ->
    case query(
        "UPDATE magic_tokens SET redeemed_at = now() "
        "WHERE token_hash = $1 AND redeemed_at IS NULL AND expires_at > now() "
        "RETURNING email",
        [TokenHash])
    of
        #{rows := [{Email}]} -> {ok, Email};
        #{rows := []}        -> not_found
    end.

%% Link a Google subject to a user. Idempotent on (provider, subject). The user's
%% identity comes from the (Google-verified) email via upsert_user_by_email/1, so a
%% Google sign-in and a magic-link sign-in for the same address resolve to one user;
%% this row records the external subject for audit + future provider-first lookup.
-spec link_oauth(binary(), binary(), binary()) -> ok.
link_oauth(UserId, Provider, Subject) ->
    _ = query(
        "INSERT INTO oauth_identities (user_id, provider, subject) "
        "VALUES ($1::uuid, $2, $3) ON CONFLICT (provider, subject) DO NOTHING",
        [UserId, Provider, Subject]),
    ok.

%% Record the shell's view of a freshly-created engine plan card: the cross-boundary
%% handle + a best-effort display title. Idempotent on (user_id, engine_plan_card_id)
%% — a retried create must not duplicate the row. Display state only; the canonical
%% plan content lives in the engine (shell-architecture.md §2/§6).
-spec insert_plan_card_view(binary(), binary(), binary()) -> ok.
insert_plan_card_view(UserId, EnginePlanCardId, Title) ->
    _ = query(
        "INSERT INTO plan_card_views (user_id, engine_plan_card_id, title) "
        "VALUES ($1::uuid, $2::uuid, $3) "
        "ON CONFLICT (user_id, engine_plan_card_id) DO NOTHING",
        [UserId, EnginePlanCardId, Title]),
    ok.

%% Does UserId own a view of EnginePlanCardId? The shell's AUTHORIZATION gate for the
%% per-card proxies (read / messages): a user may only read or ask about a plan card
%% it created (recorded as a view at create time, insert_plan_card_view/3). The engine
%% independently scopes /api/engine/* by the tenant the JWT names, but the engine
%% treats user_id as opaque — so the user→card binding lives ONLY in the shell DB
%% (§9.3, no cross-DB join), and the shell must gate here BEFORE minting a tenant JWT.
-spec owns_plan_card(binary(), binary()) -> boolean().
owns_plan_card(UserId, EnginePlanCardId) ->
    case query(
        "SELECT 1 FROM plan_card_views "
        "WHERE user_id = $1::uuid AND engine_plan_card_id = $2::uuid",
        [UserId, EnginePlanCardId])
    of
        #{rows := [_ | _]} -> true;
        #{rows := []}      -> false
    end.

%% The user's plan cards (the shell's views), newest first, excluding archived — so a
%% returning user can reach a card to project/chat. Display handles only: the canonical
%% plan content lives in the engine, fetched per card by the read proxy. created_at is
%% rendered in UTC ISO-8601 in SQL (the column is the only timestamp the list needs).
-spec list_plan_card_views(binary()) -> [map()].
list_plan_card_views(UserId) ->
    #{rows := Rows} = query(
        "SELECT engine_plan_card_id::text, title, "
        "to_char(created_at AT TIME ZONE 'UTC', 'YYYY-MM-DD\"T\"HH24:MI:SS\"Z\"') "
        "FROM plan_card_views "
        "WHERE user_id = $1::uuid AND archived = false "
        "ORDER BY created_at DESC",
        [UserId]),
    [#{<<"plan_card_id">> => Id, <<"title">> => Title, <<"created_at">> => Created}
     || {Id, Title, Created} <- Rows].

%% --- commerce (the §7 pre-call gate) ----------------------------------------

%% The user's CURRENT billing tier for the §7 pre-call gate. Read from the single
%% subscriptions row (UNIQUE user_id, 002_commerce.sql); only an ACTIVE subscription
%% is honoured — an absent row, or one that is past_due / canceled, collapses to
%% 'free' (the conservative default: a lapsed subscriber falls back to the free
%% limit, never keeps a stale paid quota). billing.md §5/§9/§10. The tier maps to a
%% token limit via fh_shell_pricing:tier_token_limit/1.
-spec user_tier(binary()) -> binary().
user_tier(UserId) ->
    case query(
        "SELECT tier FROM subscriptions "
        "WHERE user_id = $1::uuid AND status = 'active'",
        [UserId])
    of
        #{rows := [{Tier} | _]} -> Tier;
        #{rows := []}           -> <<"free">>
    end.

%% A guest (behavior 45) has no email: {ok, null}, which is_admin/1 reads as not-admin,
%% so a guest's turns are metered like anyone's.
%% This user's email, for the ADMIN_EMAILS allowlist test (fh_shell_billing:is_admin/1,
%% billing.md §9) — used by both the usage consumer (billed=false attribution) and the
%% §7 pre-call gate (admin exemption). Calls pgo directly (NOT the raising query/2
%% above) so a DB error is fail-soft (-> not_found, the caller's admin check then
%% defaults to false) rather than crashing the caller — the same posture as
%% fh_shell_meter:sum_period/1's direct pgo call.
-spec user_email(binary()) -> {ok, binary() | null} | not_found.
user_email(UserId) ->
    case pgo:query("SELECT email FROM users WHERE user_id = $1::uuid", [UserId]) of
        #{rows := [{Email} | _]} -> {ok, Email};
        #{rows := []}            -> not_found;
        {error, Reason} ->
            logger:warning("[store] user_email(~s) failed: ~p", [UserId, Reason]),
            not_found
    end.

%% Bind a user to a Stripe subscription (billing.md §9, the checkout.session.completed
%% webhook). The session is the ONLY event that knows both user_id (client_reference_id)
%% and the subscription id, so this is where the (user ↔ stripe_subscription_id) binding
%% is recorded. Upsert by user_id (UNIQUE — one subscription row per user): a first
%% subscribe inserts, a re-subscribe / resubscribe updates the binding in place. Status
%% is set active here; the authoritative status/period/tier maintenance flows from the
%% customer.subscription.* events (update_subscription/5). Tier comes from the checkout
%% session metadata we set; the subscription events later reconfirm it from the price.
-spec link_subscription(binary(), binary(), binary()) -> ok.
link_subscription(UserId, StripeSubId, Tier) ->
    _ = query(
        "INSERT INTO subscriptions (user_id, tier, stripe_subscription_id, status) "
        "VALUES ($1::uuid, $2, $3, 'active') "
        "ON CONFLICT (user_id) DO UPDATE "
        "  SET tier = EXCLUDED.tier, "
        "      stripe_subscription_id = EXCLUDED.stripe_subscription_id, "
        "      status = 'active', updated_at = now()",
        [UserId, Tier, StripeSubId]),
    ok.

%% Maintain an existing subscription's lifecycle state from a customer.subscription.*
%% event (billing.md §9). Matched by stripe_subscription_id (the binding link_subscription/3
%% recorded) — NOT by user_id, since these events carry no user reference. Tier is derived
%% from the price (so a portal-driven plan change is honoured), status is folded from
%% Stripe's eight states into our three, and the period window is the subscription item's
%% current_period_* (Stripe moved these from the subscription to its items). PeriodStart/End
%% are unix-epoch integers (or null) → to_timestamp; the ::double precision cast resolves
%% to_timestamp's overload and maps null → null. Returns {ok, updated} when a row matched,
%% {ok, no_match} for an unknown subscription (e.g. an event before its session.completed,
%% or a subscription not created through our checkout) — the caller logs + acks either way.
%%
%% Honest-partial -> P-2 · The database is the single source of truth -> The shell database -> pgo timestamptz text param
%% pgo will not encode a text parameter cast `$n::timestamptz` inside extract(epoch …): it
%% raises badarg_encoding. Compute epochs in SQL or pass numbers, as the
%% to_timestamp($n::double precision) shape below does. Measured June 2026:
%% billing_webhook_smoke failed on the text form.
-spec update_subscription(binary(), binary(), binary(),
                          integer() | null, integer() | null) ->
    {ok, updated | no_match}.
update_subscription(StripeSubId, Status, Tier, PeriodStart, PeriodEnd) ->
    case query(
        "UPDATE subscriptions "
        "   SET status = $2, tier = $3, "
        "       current_period_start = to_timestamp($4::double precision), "
        "       current_period_end   = to_timestamp($5::double precision), "
        "       updated_at = now() "
        " WHERE stripe_subscription_id = $1",
        [StripeSubId, Status, Tier, PeriodStart, PeriodEnd])
    of
        #{num_rows := N} when N >= 1 -> {ok, updated};
        #{num_rows := 0}             -> {ok, no_match}
    end.

%% Record a one-time add-on charge (billing.md §9), written when a mode=payment
%% checkout.session.completed is processed (8-S5f). Add-ons are ORTHOGONAL to the tier
%% subscription — a charge never touches subscriptions/usage_records. AmountCents is the
%% session amount_total (smallest currency unit, server-determined per kind, never client
%% supplied); stored as dollars via `$3::numeric / 100` — exact, avoiding float→numeric
%% drift. PaymentIntentId is the Stripe PaymentIntent (the per-payment idempotency key);
%% `undefined` → NULL for a ledger-only charge (success_fee). PlanCardId is the optional
%% engine plan-card context — a bare cross-DB handle (§9.3), `undefined` → NULL. Idempotent
%% on the PaymentIntent (003_charge_idempotency.sql partial unique index): a RETRIED webhook
%% hits ON CONFLICT DO NOTHING → {ok, duplicate} (no double charge). Returns {ok, ChargeId}
%% on a fresh insert. A ledger charge (NULL PaymentIntent) is outside the partial index, so
%% it always inserts (each manual entry is distinct).
-spec record_charge(binary(), binary(), integer(),
                    binary() | undefined, binary() | undefined) ->
    {ok, binary()} | {ok, duplicate}.
record_charge(UserId, Kind, AmountCents, PaymentIntentId, PlanCardId) ->
    case query(
        "INSERT INTO charges "
        "  (user_id, kind, amount, stripe_payment_intent_id, plan_card_id) "
        "VALUES ($1::uuid, $2, $3::numeric / 100, $4, $5::uuid) "
        "ON CONFLICT (stripe_payment_intent_id) "
        "  WHERE stripe_payment_intent_id IS NOT NULL DO NOTHING "
        "RETURNING charge_id::text",
        [UserId, Kind, AmountCents, null_bin(PaymentIntentId), null_bin(PlanCardId)])
    of
        #{rows := [{ChargeId}]} -> {ok, ChargeId};
        #{rows := []}           -> {ok, duplicate}
    end.

%% --- internals --------------------------------------------------------------

%% undefined → SQL NULL; a binary passes through (so a nullable text/uuid bind is uniform).
null_bin(undefined) -> null;
null_bin(B) when is_binary(B) -> B.

%% Honest-partial -> P-5 · Metering, not gating -> The shell database -> the daily question cap, claimed in one statement
%% The daily assistant-question cap (behavior 36). One statement claims a question for
%% (user, today in Sydney): insert n=1, or increment while n < Limit. Postgres takes the
%% row lock on conflict, so two concurrent claims serialise and the WHERE re-checks the
%% fresh n: at most Limit claims succeed per day. The day is SQL's (Australia/Sydney),
%% never the Erlang wall clock. On a refused claim it returns the next Sydney midnight
%% as a UTC ISO-8601 string, for the client's "ask again tomorrow".
-spec claim_question(binary(), non_neg_integer()) ->
    {ok, binary()} | {limit, binary()}.
claim_question(UserId, Limit) when Limit >= 1 ->
    case query(
        "INSERT INTO qa_daily_asks (user_id, day, n) "
        "VALUES ($1::uuid, (now() AT TIME ZONE 'Australia/Sydney')::date, 1) "
        "ON CONFLICT (user_id, day) DO UPDATE SET n = qa_daily_asks.n + 1 "
        "WHERE qa_daily_asks.n < $2 "
        "RETURNING day::text",
        [UserId, Limit])
    of
        #{rows := [{Day}]} -> {ok, Day};
        #{rows := []}      -> {limit, next_sydney_midnight()}
    end;
claim_question(_UserId, _Limit) ->
    {limit, next_sydney_midnight()}.

%% Give back a claimed question (the engine did not start the turn). Keyed on the day
%% the claim returned, so a release just after midnight credits the right day. The day
%% travels as `$2::text::date`: pgo types a bare `$2::date` parameter as date and
%% refuses a binary for it (badarg_encoding, measured 2026-10-09 by
%% qa_daily_cap_smoke) — the same encoder the timestamptz block above meets.
-spec release_question(binary(), binary()) -> ok.
release_question(UserId, Day) ->
    _ = query(
        "UPDATE qa_daily_asks SET n = n - 1 "
        "WHERE user_id = $1::uuid AND day = $2::text::date AND n > 0",
        [UserId, Day]),
    ok.

%% Guest plans -> P-5 · Metering, not gating -> The shell database -> the guest daily create cap, claimed in one statement
%% The signed-out create cap (behavior 45): 3 plans a Sydney day per guest and per
%% client address. The same one-statement claim as claim_question/2, keyed by
%% (kind, key, day) in guest_daily_creates: kind 'guest' with the guest's user_id,
%% kind 'addr' with the client address. On a refused claim, the next Sydney midnight.
-spec claim_guest_create(guest | addr, binary(), pos_integer()) ->
    {ok, binary()} | {limit, binary()}.
claim_guest_create(Kind, Key, Limit) ->
    case query(
        "INSERT INTO guest_daily_creates (kind, key, day, n) "
        "VALUES ($1, $2, (now() AT TIME ZONE 'Australia/Sydney')::date, 1) "
        "ON CONFLICT (kind, key, day) DO UPDATE SET n = guest_daily_creates.n + 1 "
        "WHERE guest_daily_creates.n < $3 "
        "RETURNING day::text",
        [atom_to_binary(Kind), Key, Limit])
    of
        #{rows := [{Day}]} -> {ok, Day};
        #{rows := []}      -> {limit, next_sydney_midnight()}
    end.

%% Give a claimed create back (the engine did not accept the plan, or the other
%% counter refused it). Keyed on the claim's day, as release_question/2.
-spec release_guest_create(guest | addr, binary(), binary()) -> ok.
release_guest_create(Kind, Key, Day) ->
    _ = query(
        "UPDATE guest_daily_creates SET n = n - 1 "
        "WHERE kind = $1 AND key = $2 AND day = $3::text::date AND n > 0",
        [atom_to_binary(Kind), Key, Day]),
    ok.

next_sydney_midnight() ->
    #{rows := [{T}]} = query(
        "SELECT to_char((((now() AT TIME ZONE 'Australia/Sydney')::date + 1)::timestamp "
        "AT TIME ZONE 'Australia/Sydney') AT TIME ZONE 'UTC', "
        "'YYYY-MM-DD\"T\"HH24:MI:SS\"Z\"')",
        []),
    T.

-spec query(string(), list()) -> map().
query(SQL, Params) ->
    case pgo:query(SQL, Params) of
        #{command := _} = R -> R;
        {error, Err} -> error({pg_query_failed, Err, SQL})
    end.
