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

%% --- identity (login flow) --------------------------------------------------

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

%% --- internals --------------------------------------------------------------

-spec query(string(), list()) -> map().
query(SQL, Params) ->
    case pgo:query(SQL, Params) of
        #{command := _} = R -> R;
        {error, Err} -> error({pg_query_failed, Err, SQL})
    end.
