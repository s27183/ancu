-module(fh_engine_turn_sup).
-behaviour(supervisor).

%% Per-plan-card-turn supervisor. Modeled on ATP mcp_orchestrator_sup.
%%
%% simple_one_for_one + temporary children: one fh_engine_turn gen_statem per turn,
%% started on demand by the gateway (#8) via start_turn/_, and NOT restarted when it
%% finishes (a turn is a one-shot unit of work — principle 1, process isolation per
%% turn; isolation-model.md). intensity 0 because a crashed turn is a failed request,
%% not a reason to restart it.
%%
%% The ETS turn registry is created here (owned by this long-lived supervisor, like
%% ATP's orchestrator registry) so it survives individual turn crashes. Entries are
%% tenant-scoped (engine-contract §3) when #8 populates it.

-export([start_link/0, start_turn/1]).
-export([init/1]).

-define(REGISTRY, fh_engine_turn_registry).

-spec start_link() -> supervisor:startlink_ret().
start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

%% Start a turn process. Args shape is defined with the gen_statem in #8; kept
%% generic here so the gateway can spawn turns without this module changing.
-spec start_turn(list()) -> supervisor:startchild_ret().
start_turn(Args) ->
    supervisor:start_child(?MODULE, [Args]).

-spec init([]) -> {ok, {supervisor:sup_flags(), [supervisor:child_spec()]}}.
init([]) ->
    _ = ets:new(?REGISTRY, [named_table, public, set, {read_concurrency, true}]),
    SupFlags = #{strategy => simple_one_for_one, intensity => 0, period => 1},
    ChildSpec = #{
        id => fh_engine_turn,
        start => {fh_engine_turn, start_link, []},
        restart => temporary,
        type => worker
    },
    {ok, {SupFlags, [ChildSpec]}}.
