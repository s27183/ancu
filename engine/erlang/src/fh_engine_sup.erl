-module(fh_engine_sup).
-behaviour(supervisor).

%% Top supervisor of the engine. Modeled on ATP mcp_sup. Strategy one_for_one:
%% children are independent subsystems; one falling over must not cascade.
%%
%% Children (Wedge 1a #8 slice 1):
%%   * fh_engine_pubsub — the pg scope for live event fan-out (turns publish, SSE
%%     handlers subscribe). Started FIRST so it exists before any turn runs.
%%   * fh_engine_turn_sup — the per-plan-card-turn supervisor (principle 1: one
%%     isolated gen_statem per turn) + the ETS turn registry.
%%   * fh_engine_http — the cowboy /api/engine/* listener (ranch child spec). Started
%%     LAST so the rest of the engine is ready before connections are accepted.
%% Migrations are NOT a child: they run once in fh_engine_app:start before this tree
%% starts (the DB must be migrated before any turn runs).

-export([start_link/0]).
-export([init/1]).

-spec start_link() -> supervisor:startlink_ret().
start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

-spec init([]) -> {ok, {supervisor:sup_flags(), [supervisor:child_spec()]}}.
init([]) ->
    SupFlags = #{
        strategy => one_for_one,
        intensity => 5,
        period => 10
    },
    Children = [
        fh_engine_pubsub:child_spec(),
        #{
            id => fh_engine_turn_sup,
            start => {fh_engine_turn_sup, start_link, []},
            restart => permanent,
            type => supervisor
        },
        fh_engine_http:child_spec()
    ],
    {ok, {SupFlags, Children}}.
