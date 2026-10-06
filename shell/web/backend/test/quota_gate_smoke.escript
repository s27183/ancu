#!/usr/bin/env escript
%%! -sname fh_shell_quota_gate_smoke
%%
%% 8-S5d: the §7 pre-call token-limit gate. Three halves:
%%
%%   PRICING (pure) — fh_shell_pricing:tier_token_limit/1 returns the §5 per-tier
%%   token quota (Free 1.0M / Plus 2.5M / Pro 5.0M), an unknown tier collapses to
%%   free (the conservative floor), and an env override (FH_LIMIT_FREE) takes effect.
%%
%%   TIER + GATE (DB + ETS) — fh_shell_store:user_tier/1 honours only an ACTIVE
%%   subscription (absent / canceled → free), and fh_shell_meter:gate/1 composes
%%   tier→limit vs the period token sum: `allow` under the limit, `{block, Info}`
%%   at/over it, and a higher tier lifts the limit so the same usage passes.
%%
%%   END-TO-END (HTTP) — POST /api/plan-cards/:id/messages for an over-limit user
%%   returns 402 quota_exceeded with {tier, used_tokens, limit_tokens}, BEFORE any
%%   engine call (so no engine stub is needed — the block short-circuits the proxy).
%%   The under-limit ALLOW path through this same handler is already proven by
%%   plancard_proxy_smoke (fresh user, default 1.0M limit, 0 usage → 202 relayed).
%%
%%   SHELL_DATABASE_URL=postgres://shell:shell_dev_pw@localhost:5434/firsthomey_shell?sslmode=disable \
%%   ERL_LIBS=_build/default/lib escript test/quota_gate_smoke.escript

-mode(compile).

-define(SHELL_PORT, 8099).

main(_) ->
    os:putenv("FH_SHELL_HTTP_PORT", integer_to_list(?SHELL_PORT)),
    os:putenv("SHELL_JWT_SECRET", "quota-gate-smoke-secret"),
    os:putenv("USAGE_CONSUMER_POLL_MS", "3600000"),  % keep the consumer idle
    os:putenv("METER_CACHE_TTL_MS", "3600000"),       % 1h: cache never expires mid-test
    {_Pub, Priv} = crypto:generate_key(eddsa, ed25519),
    os:putenv("SHELL_TENANT_ID", binary_to_list(uuid())),
    os:putenv("SHELL_TENANT_PRIVKEY", binary_to_list(base64:encode(Priv))),
    {ok, _} = application:ensure_all_started(fh_shell),
    {ok, _} = application:ensure_all_started(inets),

    %% ── PRICING: §5 tier limits (pure, defaults — before any FH_LIMIT env) ───
    expect(fh_shell_pricing:tier_token_limit(<<"free">>) =:= 1000000,
           "free tier limit defaults to 1.0M tokens (billing.md §5)"),
    expect(fh_shell_pricing:tier_token_limit(<<"plus">>) =:= 2500000,
           "plus tier limit defaults to 2.5M tokens"),
    expect(fh_shell_pricing:tier_token_limit(<<"pro">>) =:= 5000000,
           "pro tier limit defaults to 5.0M tokens"),
    expect(fh_shell_pricing:tier_token_limit(<<"bogus">>) =:= 1000000,
           "an unknown tier collapses to the free limit (conservative floor)"),
    expect(fh_shell_pricing:tier_token_limit(free) =:= 1000000,
           "the atom form resolves the same as the binary"),
    os:putenv("FH_LIMIT_FREE", "100"),
    expect(fh_shell_pricing:tier_token_limit(<<"free">>) =:= 100,
           "FH_LIMIT_FREE env override takes effect (limits are tunable, §5)"),

    %% ── TIER: only an active subscription is honoured ────────────────────────
    TUser = new_user(),
    expect(fh_shell_store:user_tier(TUser) =:= <<"free">>,
           "a user with no subscription row reads tier=free"),
    _ = pgo:query(<<"INSERT INTO subscriptions (user_id, tier, status) "
                    "VALUES ($1::uuid, 'plus', 'active')">>, [TUser]),
    expect(fh_shell_store:user_tier(TUser) =:= <<"plus">>,
           "an active plus subscription reads tier=plus"),
    _ = pgo:query(<<"UPDATE subscriptions SET status = 'canceled' "
                    "WHERE user_id = $1::uuid">>, [TUser]),
    expect(fh_shell_store:user_tier(TUser) =:= <<"free">>,
           "a canceled subscription falls back to free (no stale paid quota)"),

    %% ── GATE: period sum vs the tier limit (free limit now 100) ──────────────
    GUser = new_user(),
    expect(fh_shell_meter:gate(GUser) =:= allow,
           "gate allows a fresh free user (0 usage < 100 limit)"),
    ins_usage(GUser, 60),
    fh_shell_meter:invalidate(GUser),
    expect(fh_shell_meter:gate(GUser) =:= allow,
           "gate allows under the limit (60 < 100)"),
    ins_usage(GUser, 40),
    fh_shell_meter:invalidate(GUser),
    expect(fh_shell_meter:gate(GUser) =:=
               {block, #{tier => <<"free">>, used => 100, limit => 100}},
           "gate blocks at the limit (100 >= 100) with {tier, used, limit}"),

    %% a higher tier lifts the limit: the SAME 100 tokens pass on plus.
    PUser = new_user(),
    _ = pgo:query(<<"INSERT INTO subscriptions (user_id, tier, status) "
                    "VALUES ($1::uuid, 'plus', 'active')">>, [PUser]),
    ins_usage(PUser, 100),
    fh_shell_meter:invalidate(PUser),
    expect(fh_shell_meter:gate(PUser) =:= allow,
           "the plus tier lifts the limit - 100 tokens pass (100 < 2.5M)"),

    %% ── END-TO-END: an over-limit user POSTing a message gets 402 ────────────
    EUser = new_user(),
    CardId = uuid(),
    ok = fh_shell_store:insert_plan_card_view(EUser, CardId, <<"Cabramatta">>),
    ins_usage(EUser, 100),
    Jwt = fh_shell_jwt:issue(#{user_id => EUser, email => email(),
                               roles => [<<"buyer">>], locale => <<"vi">>}),
    Auth = [{"authorization", "Bearer " ++ binary_to_list(Jwt)}],
    Url = "http://localhost:" ++ integer_to_list(?SHELL_PORT)
          ++ "/api/plan-cards/" ++ binary_to_list(CardId) ++ "/messages",
    Body = fh_shell_util:json_encode(#{<<"message">> => <<"Can I use FHSS?">>}),
    {402, Resp} = req(post, Url, Auth, Body),
    #{<<"error">> := <<"quota_exceeded">>, <<"tier">> := <<"free">>,
      <<"used_tokens">> := 100, <<"limit_tokens">> := 100} =
        fh_shell_util:json_decode(Resp),
    expect(true, "POST .../messages over the limit -> 402 quota_exceeded (no engine call)"),

    io:format("~nALL PASSED~n"),
    halt(0).

%% ── helpers ──────────────────────────────────────────────────────────────────

uuid()  -> fh_shell_util:uuid4().
email() -> <<"quota+", (uuid())/binary, "@example.com">>.

new_user() ->
    scalar("INSERT INTO users (email) VALUES ($1) RETURNING user_id::text", [email()]).

%% insert one usage_records row with a globally-unique engine_event_id, in-period.
%% engine_event_id is bigint UNIQUE and we INSERT without ON CONFLICT, so the key
%% must be unique across re-runs: system_time(microsecond) advances every call (a
%% full pgo round-trip separates them) and across VM restarts (wall clock). NEGATED:
%% fh_shell_usage_consumer bootstraps its poll cursor from MAX(engine_event_id) across
%% this whole table (002_commerce.sql) — a positive fixture id can jump the real
%% consumer's cursor past every future real event and silently wedge it.
ins_usage(UserId, Tok) ->
    Ev = -erlang:system_time(microsecond),
    pgo:query(<<"INSERT INTO usage_records (user_id, engine_event_id, tokens_total) "
                "VALUES ($1::uuid, $2, $3)">>, [UserId, Ev, Tok]).

scalar(SQL, Params) ->
    #{rows := [{Val}]} = pgo:query(list_to_binary(SQL), Params),
    Val.

req(Method, Url, Headers, Body) ->
    Request = {Url, Headers, "application/json", Body},
    {ok, {{_, Status, _}, _, Resp}} =
        httpc:request(Method, Request, [], [{body_format, binary}]),
    {Status, Resp}.

%% Bilingual -> R-4 · Reasoning within its runtime -> The shell backend -> escript stdout is latin1
%% Escript stdout is latin1: `~s` of a UTF-8 binary double-encodes it (café -> cafÃ©), and a
%% codepoint above 255 (an em-dash) in a `~s` label raises badarg; use `~ts` for any
%% non-ASCII label. Measured June 2026 (8-S5d, portfolio_position capture); re-measured
%% 2026-10-06 on OTP 29 by an escript printing <<"café"/utf8>> and [8212] with ~s and ~ts.
expect(true, Label)  -> io:format("  ok  ~s~n", [Label]);
expect(false, Label) -> io:format("FAIL  ~s~n", [Label]), halt(1).
