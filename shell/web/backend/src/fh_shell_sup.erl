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
        fh_shell_http:child_spec()
    ],
    {ok, {SupFlags, Children}}.
