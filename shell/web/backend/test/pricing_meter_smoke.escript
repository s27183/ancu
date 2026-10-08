#!/usr/bin/env escript
%%! -sname fh_shell_pricing_meter_smoke
%%
%% 8-S5c: fh_shell_pricing (shadow-cost valuation) + fh_shell_meter (period token
%% meter). Two halves:
%%
%%   PRICING (pure, no DB) — asserts the §4 Opus-rate valuation reproduces billing.md
%%   §4 to the cent: the measured cold base fill values at $0.46, the cold chat turn
%%   at $0.19; cost_slices sum to the total; an env rate override takes effect and the
%%   default restores. This is the regulated-figure-by-postcondition discipline applied
%%   to an internal cost estimate — pricing that drifts from §4 fails here.
%%
%%   METER (DB + ETS) — asserts the period Σ over usage_records, the TTL cache (a stale
%%   entry is returned until invalidated), invalidate → fresh SQL Σ, the calendar-month
%%   period window (prior-month usage excluded), and the subscription window overriding
%%   the calendar default.
%%
%%   SHELL_DATABASE_URL=postgres://shell:shell_dev_pw@localhost:5434/ancu_shell?sslmode=disable \
%%   ERL_LIBS=_build/default/lib escript test/pricing_meter_smoke.escript

-mode(compile).

-define(SHELL_PORT, 8098).

main(_) ->
    os:putenv("FH_SHELL_HTTP_PORT", integer_to_list(?SHELL_PORT)),
    os:putenv("SHELL_JWT_SECRET", "pricing-meter-smoke-secret"),
    os:putenv("USAGE_CONSUMER_POLL_MS", "3600000"),  % keep the consumer idle
    os:putenv("METER_CACHE_TTL_MS", "3600000"),       % 1h: cache never expires mid-test
    {_Pub, Priv} = crypto:generate_key(eddsa, ed25519),
    os:putenv("SHELL_TENANT_ID", binary_to_list(uuid())),
    os:putenv("SHELL_TENANT_PRIVKEY", binary_to_list(base64:encode(Priv))),
    {ok, _} = application:ensure_all_started(fh_shell),

    %% ── PRICING: §4 oracle (pure) ───────────────────────────────────────────
    %% args are (input, output, cache_read, cache_write).
    C1 = fh_shell_pricing:shadow_cost(2005, 2032, 33705, 38491),  % measured cold base
    expect(cents(C1) =:= 46, "cold base fill values at $0.46 (billing.md §4)"),
    C2 = fh_shell_pricing:shadow_cost(2001, 979, 44018, 12857),   % measured cold chat
    expect(cents(C2) =:= 19, "cold chat turn values at $0.19 (billing.md §4)"),

    #{input := I, output := O, cache_read := R, cache_write := W} =
        fh_shell_pricing:cost_slices(2005, 2032, 33705, 38491),
    expect(abs((I + O + R + W) - C1) < 1.0e-9, "cost_slices sum to shadow_cost"),
    %% the 1h cache-write rate ($10/M) dominates a cold turn (billing.md §4).
    expect(W > I + O + R, "cache-write slice dominates the cold base cost"),

    expect(fh_shell_pricing:shadow_cost(0, 0, 0, 1000000) == 10.0,
           "default cache-write rate is $10/M (1M write = $10)"),
    os:putenv("FH_PRICE_CACHE_WRITE", "0"),
    expect(fh_shell_pricing:shadow_cost(0, 0, 0, 1000000) == 0.0,
           "FH_PRICE_CACHE_WRITE=0 env override zeroes the cache-write slice"),
    os:unsetenv("FH_PRICE_CACHE_WRITE"),
    expect(fh_shell_pricing:shadow_cost(0, 0, 0, 1000000) == 10.0,
           "default rate restored after unsetting the override"),

    %% ── METER: Σ, cache, invalidate, period window ──────────────────────────
    Email = <<"meter+", (uuid())/binary, "@example.com">>,
    UserId = scalar("INSERT INTO users (email) VALUES ($1) RETURNING user_id::text", [Email]),
    _ = pgo:query(<<"DELETE FROM usage_records WHERE user_id = $1::uuid">>, [UserId]),
    %% NEGATED: fh_shell_usage_consumer bootstraps its poll cursor from
    %% MAX(engine_event_id) across this whole table (002_commerce.sql) — a positive
    %% fixture id can jump the real consumer's cursor past every future real event
    %% and silently wedge it.
    Base = -erlang:system_time(microsecond),

    expect(fh_shell_meter:period_tokens(UserId) =:= 0,
           "empty period meter = 0 (and caches the 0)"),

    %% two in-period rows inserted DIRECTLY (not via the consumer), so the meter is
    %% NOT auto-invalidated — the cached 0 must persist (proves the TTL cache).
    ins_now(UserId, Base + 1, 100),
    ins_now(UserId, Base + 2, 200),
    expect(fh_shell_meter:period_tokens(UserId) =:= 0,
           "stale cache still returns 0 after a direct insert (TTL caching works)"),
    fh_shell_meter:invalidate(UserId),
    expect(fh_shell_meter:period_tokens(UserId) =:= 300,
           "after invalidate, SQL Sigma = 300 (100 + 200)"),

    %% a prior-month row is OUTSIDE the calendar-month window.
    ins_prev_month(UserId, Base + 3, 999),
    fh_shell_meter:invalidate(UserId),
    expect(fh_shell_meter:period_tokens(UserId) =:= 300,
           "prior-month usage excluded from the current calendar-month period"),

    %% a subscription window OVERRIDES the calendar default: a future period_start
    %% excludes every existing (this-month) row.
    _ = pgo:query(<<"INSERT INTO subscriptions (user_id, current_period_start) "
                    "VALUES ($1::uuid, now() + interval '1 day')">>, [UserId]),
    fh_shell_meter:invalidate(UserId),
    expect(fh_shell_meter:period_tokens(UserId) =:= 0,
           "subscription current_period_start (future) overrides calendar-month -> 0"),

    io:format("~nALL PASSED~n"),
    halt(0).

%% ── helpers ──────────────────────────────────────────────────────────────────

uuid() -> fh_shell_util:uuid4().

ins_now(UserId, Ev, Tok) ->
    pgo:query(<<"INSERT INTO usage_records (user_id, engine_event_id, tokens_total) "
                "VALUES ($1::uuid, $2, $3)">>, [UserId, Ev, Tok]).

ins_prev_month(UserId, Ev, Tok) ->
    pgo:query(<<"INSERT INTO usage_records (user_id, engine_event_id, tokens_total, created_at) "
                "VALUES ($1::uuid, $2, $3, date_trunc('month', now()) - interval '1 day')">>,
              [UserId, Ev, Tok]).

scalar(SQL, Params) ->
    #{rows := [{Val}]} = pgo:query(list_to_binary(SQL), Params),
    Val.

cents(F) -> round(F * 100).

expect(true, Label)  -> io:format("  ok  ~s~n", [Label]);
expect(false, Label) -> io:format("FAIL  ~s~n", [Label]), halt(1).
