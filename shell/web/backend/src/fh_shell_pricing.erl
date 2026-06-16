-module(fh_shell_pricing).

%% Shadow-cost valuation for one usage event (billing.md §4/§6). PURE: no DB, no
%% process state, no side effects beyond reading os:getenv for the rate config.
%% Given the four token slices the engine records, returns the USD cost at the
%% Claude Opus 4.8 direct-API rates.
%%
%%   shadow_cost = (in·r_in + out·r_out + cache_read·r_cr + cache_write·r_cw)
%%                 / 1_000_000
%%
%% Reshaped from aleap_shell_pricing (memory: borrow-and-reshape) on TWO points,
%% both forced by FirstHomey's billing model (billing.md §3 — subscription, not
%% pay-as-you-go):
%%
%%   1. NO markup, NO flat per-call base. aleap charges a CLIENT a per-call price
%%      (COGS × markup + base); FirstHomey charges a fixed TIER price and meters
%%      tokens. shadow_cost is pure COGS — a margin/dashboard figure (§6: "dollars
%%      are for the dashboard and margin analysis"), never what the user is billed.
%%
%%   2. MODEL-INDEPENDENT — one rate table, not aleap's per-model rate keys.
%%      billing.md §4 is explicit: "Cost is accounted at Claude Opus 4.8 rates …
%%      regardless of which path actually served" — the Opus rate is the deliberate
%%      conservative CEILING. The engine in fact emits model="opus" (an SDK alias,
%%      planner.py LEAF_MODEL/QA_MODEL), so a per-model lookup would be both brittle
%%      and against the spec. The `model` column on usage_records is kept for the
%%      dashboard/audit, NOT for rate selection.
%%
%% The four slices are priced SEPARATELY (not collapsed onto one rate) because the
%% vendor bills base-input / output / cache-write / cache-read at four different
%% rates; collapsing would mis-cost (cache-write is 2× input, cache-read 0.1×).
%%
%% Rates default to the §4 measured Opus 4.8 figures so an unconfigured shell still
%% produces the conservative ceiling cost; they are env-tunable (USD per 1M tokens)
%% for when Opus pricing changes:
%%   FH_PRICE_IN          uncached base input    (default 5.0)
%%   FH_PRICE_OUT         generated output       (default 25.0)
%%   FH_PRICE_CACHE_READ  cache-read input       (default 0.5)
%%   FH_PRICE_CACHE_WRITE cache-creation (1h)    (default 10.0)
%%
%% The cache-write default is the 1-HOUR rate ($10/M): planner.py caches the prompt
%% prefix at ephemeral_1h (billing.md §4 — the 1h write dominates a cold turn).
%%
%% Post-condition (billing.md §4, measured 2026-06-13): a cold base fill
%% (in 2005, out 2032, cache-write 38491, cache-read 33705) values at $0.4626 ≈
%% $0.46; a cold chat turn (2001/979/12857/44018) at $0.1851 ≈ $0.19. The smoke
%% asserts both against this module — pricing that drifts from §4 fails the test.

-export([shadow_cost/4, cost_slices/4, tier_token_limit/1]).

%% ── API ─────────────────────────────────────────────────────────────────────

%% Total USD COGS for one event from its four token slices (the value written to
%% usage_records.shadow_cost). The DB column is numeric(12,6); pgo binds this float
%% and Postgres rounds to 6 dp.
-spec shadow_cost(integer(), integer(), integer(), integer()) -> float().
shadow_cost(In, Out, CacheRead, CacheWrite) ->
    #{input := I, output := O, cache_read := R, cache_write := W} =
        cost_slices(In, Out, CacheRead, CacheWrite),
    I + O + R + W.

%% Per-slice USD COGS — the four vendor-billed slices priced separately, for the
%% cost dashboard's breakdown. shadow_cost/4 is the sum of these; single-sourcing
%% the per-slice math here keeps the total and the breakdown from drifting.
-spec cost_slices(integer(), integer(), integer(), integer()) ->
    #{input := float(), output := float(),
      cache_read := float(), cache_write := float()}.
cost_slices(In, Out, CacheRead, CacheWrite) ->
    #{input      => num(In)        * rate("FH_PRICE_IN", 5.0)   / 1000000,
      output     => num(Out)       * rate("FH_PRICE_OUT", 25.0) / 1000000,
      cache_read => num(CacheRead) * rate("FH_PRICE_CACHE_READ", 0.5) / 1000000,
      cache_write=> num(CacheWrite)* rate("FH_PRICE_CACHE_WRITE", 10.0) / 1000000}.

%% The per-tier period TOKEN quota (billing.md §5/§7) — the quantity the §7 pre-call
%% gate (fh_shell_meter:gate/1) compares the user's current-period token sum against.
%% This lives beside shadow_cost because both are the §4/§5 pricing SOT; note the
%% enforced quota is TOKENS, not the shadow dollars (billing.md §3 — "the meter unit
%% is tokens").
%%
%% Defaults are the §5 figures (Free 1.0M / Plus 2.5M / Pro 5.0M). They are env-tunable
%% because §5 calls the limits "a starting point, not a constant" — calibrated against
%% observed usage once real usage_records accumulate. An unknown tier (or one the
%% caller could not resolve to active) collapses to the free limit: the conservative
%% floor, never grant a higher quota than the user's honoured tier.
-spec tier_token_limit(binary() | atom()) -> integer().
tier_token_limit(<<"plus">>) -> env_int("FH_LIMIT_PLUS", 2500000);
tier_token_limit(<<"pro">>)  -> env_int("FH_LIMIT_PRO", 5000000);
tier_token_limit(<<"free">>) -> env_int("FH_LIMIT_FREE", 1000000);
tier_token_limit(plus) -> tier_token_limit(<<"plus">>);
tier_token_limit(pro)  -> tier_token_limit(<<"pro">>);
tier_token_limit(free) -> tier_token_limit(<<"free">>);
tier_token_limit(_)    -> env_int("FH_LIMIT_FREE", 1000000).

%% ── Internal ────────────────────────────────────────────────────────────────

rate(EnvKey, Default) ->
    get_env_float(EnvKey, Default).

%% Read an env var as an integer (the token-limit tunables). Bad/missing → Default.
env_int(Key, Default) ->
    case os:getenv(Key) of
        false -> Default;
        ""    -> Default;
        Val   -> try list_to_integer(Val) catch error:badarg -> Default end
    end.

num(N) when is_integer(N) -> N;
num(N) when is_float(N)   -> N;
num(_)                    -> 0.

%% Read an env var as a float. Accepts "5.0" and "5"; bad/missing → Default.
get_env_float(Key, Default) ->
    case os:getenv(Key) of
        false -> Default;
        ""    -> Default;
        Val ->
            try list_to_float(Val)
            catch error:badarg ->
                try float(list_to_integer(Val))
                catch error:badarg -> Default
                end
            end
    end.
