-module(fh_shell_sup).
-behaviour(supervisor).

%% Root supervisor for the shell backend. At 8-S0 the only child is the cowboy
%% listener (embedded via ranch:child_spec, like the engine's fh_engine_http) — the
%% shell backend is a stateless proxy + identity/commerce layer in front of the
%% engine, so there is no per-turn process tree here (turns live engine-side). The
%% usage-consumer gen_server (8-S5b) and any future workers land under this sup.

-export([start_link/0, init/1]).

-spec start_link() -> {ok, pid()} | {error, term()}.
start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

-spec init([]) -> {ok, {supervisor:sup_flags(), [supervisor:child_spec()]}}.
init([]) ->
    SupFlags = #{strategy => one_for_one, intensity => 10, period => 10},
    Children = [
        fh_shell_http:child_spec(),
        %% Period token meter (8-S5c, billing.md §6) — owns the ETS meter cache. Starts
        %% BEFORE the consumer, which calls fh_shell_meter:invalidate/1 after booking a
        %% usage row (invalidate is fail-soft if the table isn't up yet, but ordering
        %% keeps the cache live from the first booking).
        #{id => fh_shell_meter,
          start => {fh_shell_meter, start_link, []},
          restart => permanent, shutdown => 5000, type => worker},
        %% Commerce core (8-S5e, billing.md §9) — owns the ADMIN_EMAILS allowlist ETS.
        %% Starts BEFORE the consumer, which calls fh_shell_billing:is_admin/1 to set
        %% usage_records.billed (is_admin is fail-safe to false if the table isn't up
        %% yet, but ordering keeps the allowlist live from the first booking).
        #{id => fh_shell_billing,
          start => {fh_shell_billing, start_link, []},
          restart => permanent, shutdown => 5000, type => worker},
        %% Pull-model usage outbox consumer (8-S5b, billing.md §2) — tails the engine's
        %% `usage` events into usage_records. Fail-soft: a poll against an unreachable
        %% engine logs + retries, never taking the shell down.
        #{id => fh_shell_usage_consumer,
          start => {fh_shell_usage_consumer, start_link, []},
          restart => permanent, shutdown => 5000, type => worker},
        %% Guest purge (behavior 45) — deletes unclaimed guests' plans after 7 days.
        #{id => fh_shell_guest_purge,
          start => {fh_shell_guest_purge, start_link, []},
          restart => permanent, shutdown => 5000, type => worker}
    ],
    {ok, {SupFlags, Children}}.
