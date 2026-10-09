-module(fh_shell_meter).

-behaviour(gen_server).

%% The period token meter (billing.md §6/§7). `period_tokens(UserId)` is the
%% authoritative Σ(tokens_total) over usage_records for the user's CURRENT billing
%% period — the quantity the pre-call gate (8-S5d) compares against the tier limit.
%%
%% Period boundary: [current_period_start, now). The window start is read from the
%% user's subscriptions row; a free user (no row, or a null period) defaults to the
%% start of the current calendar month. Crucially the boundary is computed IN SQL
%% (date_trunc('month', now())), so there is NO Erlang wall-clock here — the meter
%% reads a clock only via monotonic_time, and only for cache freshness, never for a
%% correctness/period decision (erlang-design-checklist §15). The free-tier period
%% policy (calendar month vs rolling-30d vs since-signup) is a product decision
%% finalized with the gate in 8-S5d; calendar-month is the documented default here.
%%
%% Cache: an ETS table (this gen_server owns it so it outlives requests) holds
%% {UserId, Tokens, ExpiryMs} with a short TTL (default 30s, billing.md §2). Reads
%% and the invalidate are lock-free public ETS ops from the caller's process; the
%% server only owns the table. On a miss/stale entry the caller recomputes the SQL
%% Σ and refills — concurrent misses recompute redundantly, which is harmless. The
%% usage consumer calls invalidate/1 after booking a row (§6), so a freshly metered
%% turn is reflected on the next read rather than waiting out the TTL.
%%
%% The SQL Σ is always the source of truth; the cache is only a hot-path accelerator
%% for the gate. A cold/empty cache never gives a wrong answer, only a slower one.

-export([start_link/0]).
-export([period_tokens/1, invalidate/1, gate/1, usage_summary/1]).
-export([claim_question/1, release_question/1, daily_question_limit/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).

-define(SERVER, ?MODULE).
-define(TAB, fh_shell_meter_cache).
-define(DEFAULT_TTL_MS, 30000).

%% ── API ─────────────────────────────────────────────────────────────────────

-spec start_link() -> {ok, pid()} | ignore | {error, term()}.
start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

%% Σ(tokens_total) for the user's current billing period. ETS-cached (TTL); on a
%% miss/stale entry computes the SQL Σ and refills. Returns 0 for an unknown user
%% or on a DB error (fail-soft — the gate treats a read failure as "no usage",
%% never blocking a user because the meter hiccupped; the next read self-heals).
-spec period_tokens(binary()) -> integer().
period_tokens(UserId) when is_binary(UserId) ->
    Now = erlang:monotonic_time(millisecond),
    case lookup_fresh(UserId, Now) of
        {ok, Tokens} -> Tokens;
        miss ->
            Tokens = sum_period(UserId),
            cache_put(UserId, Tokens, Now + ttl_ms()),
            Tokens
    end.

%% Drop the user's cached meter (called by the consumer after booking a usage row).
-spec invalidate(binary()) -> ok.
invalidate(UserId) when is_binary(UserId) ->
    try ets:delete(?TAB, UserId) catch error:badarg -> true end,
    ok.

%% The §7 pre-call gate: may an agent turn proceed for this user? Composes the three
%% pricing/usage sources — the user's honoured tier (fh_shell_store:user_tier/1) →
%% its token limit (fh_shell_pricing:tier_token_limit/1) versus the current-period
%% token sum (period_tokens/1, ETS-cached). `allow` while under the limit; `{block,
%% Info}` at/over it, which the handler turns into a 402 upgrade prompt.
%%
%% Only the always-agent messages endpoint calls this (billing.md §7): a Q&A turn is
%% never resolver-only, so gating it never blocks a free turn; and the base-plan
%% create turn is the free offering, deliberately ungated. The gate is fail-soft by
%% construction — period_tokens/1 returns 0 on a DB hiccup, so a metering outage
%% lets turns through rather than locking everyone out (the conservative direction
%% for a quota: under-count, never over-block).
%%
%% ADMIN EXEMPTION (billing.md §9's ADMIN_EMAILS allowlist): an admin is exempt from
%% the quota entirely, not just billed=false — before this, is_admin/1 only suppressed
%% the CHARGE (fh_shell_usage_consumer:book_usage/4); the gate itself never consulted
%% it, so an admin with no active paid subscription fell to the free tier's 1M-token
%% limit like anyone else. Usage still meters normally (attribution is unaffected,
%% billed stays false) — only the block is skipped.
-spec gate(binary()) ->
    allow | {block, #{tier := binary(), used := integer(), limit := integer()}}.
gate(UserId) when is_binary(UserId) ->
    case is_admin(UserId) of
        true -> allow;
        false ->
            Tier  = fh_shell_store:user_tier(UserId),
            Limit = fh_shell_pricing:tier_token_limit(Tier),
            Used  = period_tokens(UserId),
            case Used >= Limit of
                true  -> {block, #{tier => Tier, used => Used, limit => Limit}};
                false -> allow
            end
    end.

%% The daily assistant-question cap (behavior 36), beside the token gate it follows:
%% an admin is exempt here as there (claim `none`, nothing counted); everyone else
%% claims one of FH_QA_DAILY_LIMIT (default 1) questions for today in Sydney. The claim
%% is handed back to release_question/1 when the engine does not start the turn.
-spec claim_question(binary()) ->
    {ok, none | {binary(), binary()}} | {block, #{limit := integer(), resets_at := binary()}}.
claim_question(UserId) ->
    case is_admin(UserId) of
        true -> {ok, none};
        false ->
            Limit = daily_question_limit(),
            case fh_shell_store:claim_question(UserId, Limit) of
                {ok, Day}         -> {ok, {UserId, Day}};
                {limit, ResetsAt} -> {block, #{limit => Limit, resets_at => ResetsAt}}
            end
    end.

-spec release_question(none | {binary(), binary()}) -> ok.
release_question(none) -> ok;
release_question({UserId, Day}) -> fh_shell_store:release_question(UserId, Day).

-spec daily_question_limit() -> non_neg_integer().
daily_question_limit() ->
    case os:getenv("FH_QA_DAILY_LIMIT") of
        false -> 1;
        ""    -> 1;
        V     -> try list_to_integer(V) of N when N >= 0 -> N; _ -> 1 catch _:_ -> 1 end
    end.

%% UserId -> admin?, via the same email lookup the usage consumer uses. A DB miss (no
%% such user, or a transient error) is fail-SAFE the other direction from
%% period_tokens/1: treated as false (not-admin), so a lookup hiccup never over-exempts
%% a normal user from their quota — it only ever costs a real admin one gate check's
%% worth of the ordinary tier limit, self-healing on the next call.
-spec is_admin(binary()) -> boolean().
is_admin(UserId) ->
    case fh_shell_store:user_email(UserId) of
        {ok, Email} -> fh_shell_billing:is_admin(Email);
        not_found   -> false
    end.

%% The account-page read (8-S5g, the minimal usage view): tier, this-period tokens +
%% shadow cost, limit, period bounds. A FRESH SQL read (not the ETS-cached
%% period_tokens/1 path) — this is a once-per-page-load display, not the hot-path
%% gate, so the extra query is cheap and the display is never stale-by-cache-TTL. An
%% admin's `limit` reads as the atom `unlimited` (gate/1 exempts them; a numeric
%% limit here would misreport what actually governs their usage).
-spec usage_summary(binary()) -> map().
usage_summary(UserId) ->
    Tier = fh_shell_store:user_tier(UserId),
    Limit = case is_admin(UserId) of
        true  -> unlimited;
        false -> fh_shell_pricing:tier_token_limit(Tier)
    end,
    SQL = <<"SELECT COALESCE(SUM(u.tokens_total), 0), COALESCE(SUM(u.shadow_cost), 0), "
            "  to_char(p.start AT TIME ZONE 'UTC', 'YYYY-MM-DD\"T\"HH24:MI:SS\"Z\"'), "
            "  to_char(p.stop  AT TIME ZONE 'UTC', 'YYYY-MM-DD\"T\"HH24:MI:SS\"Z\"') "
            "FROM (SELECT "
            "  COALESCE((SELECT s.current_period_start FROM subscriptions s "
            "             WHERE s.user_id = $1::uuid), date_trunc('month', now())) AS start, "
            "  COALESCE((SELECT s.current_period_end FROM subscriptions s "
            "             WHERE s.user_id = $1::uuid), "
            "           date_trunc('month', now()) + interval '1 month') AS stop"
            ") p "
            "LEFT JOIN usage_records u ON u.user_id = $1::uuid AND u.created_at >= p.start "
            "GROUP BY p.start, p.stop">>,
    case pgo:query(SQL, [UserId]) of
        #{rows := [{Tokens, Cost, Start, Stop}]} ->
            #{tier => Tier, used_tokens => trunc_num(Tokens), shadow_cost => Cost,
              limit_tokens => Limit, period_start => Start, period_end => Stop};
        _ ->
            #{tier => Tier, used_tokens => 0, shadow_cost => 0.0,
              limit_tokens => Limit, period_start => null, period_end => null}
    end.

%% ── gen_server ──────────────────────────────────────────────────────────────

init([]) ->
    %% public so reads/invalidate are lock-free from any process; this server is
    %% only the table's owning (long-lived) process.
    _ = ets:new(?TAB, [named_table, public, set,
                       {read_concurrency, true}, {write_concurrency, true}]),
    logger:info("[meter] start ttl_ms=~p", [env_int("METER_CACHE_TTL_MS", ?DEFAULT_TTL_MS)]),
    {ok, #{}}.

handle_call(_Req, _From, State) ->
    {reply, {error, unsupported}, State}.

handle_cast(_Msg, State) -> {noreply, State}.
handle_info(_Info, State) -> {noreply, State}.
terminate(_Reason, _State) -> ok.
code_change(_, State, _) -> {ok, State}.

%% ── Internal ────────────────────────────────────────────────────────────────

lookup_fresh(UserId, Now) ->
    try ets:lookup(?TAB, UserId) of
        [{_, Tokens, Expiry}] when Expiry > Now -> {ok, Tokens};
        _ -> miss
    catch error:badarg -> miss   % table not yet created (server still starting)
    end.

cache_put(UserId, Tokens, Expiry) ->
    try ets:insert(?TAB, {UserId, Tokens, Expiry}) catch error:badarg -> true end,
    ok.

%% Σ(tokens_total) over the current period. The period start is COALESCEd in SQL:
%% the subscription's current_period_start, else the start of this calendar month.
sum_period(UserId) ->
    SQL = <<"SELECT COALESCE(SUM(u.tokens_total), 0) "
            "FROM usage_records u "
            "WHERE u.user_id = $1::uuid "
            "  AND u.created_at >= COALESCE("
            "        (SELECT s.current_period_start FROM subscriptions s "
            "          WHERE s.user_id = $1::uuid), "
            "        date_trunc('month', now()))">>,
    case pgo:query(SQL, [UserId]) of
        #{rows := [{Sum}]} when is_integer(Sum) -> Sum;
        #{rows := [{Sum}]} -> trunc_num(Sum);
        {error, Reason} ->
            logger:warning("[meter] sum_period(~s) failed: ~p", [UserId, Reason]),
            0
    end.

trunc_num(N) when is_integer(N) -> N;
trunc_num(N) when is_float(N)   -> trunc(N);
trunc_num(_)                    -> 0.

ttl_ms() ->
    env_int("METER_CACHE_TTL_MS", ?DEFAULT_TTL_MS).

env_int(Name, Default) ->
    case os:getenv(Name) of
        false -> Default;
        ""    -> Default;
        Str   -> try list_to_integer(Str) catch error:badarg -> Default end
    end.
