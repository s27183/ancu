-module(fh_engine_app).
-behaviour(application).

%% Engine boot. Order is load-bearing (migrations README + engine-contract §9.1):
%%   .env -> Postgres pool -> migrations (synchronous) -> KB artifact -> supervision tree.
%% Migrations and the KB-artifact load both run BEFORE the tree accepts turns.
%% FAIL-CLOSED: the engine's runtime state (plan cards, events, sessions) lives in
%% Postgres and the regulated audit trail depends on a migrated schema; the planning
%% turn (resolver rules + leaf-fill KB) depends on the compiled artifact — so a
%% missing ENGINE_DATABASE_URL, a failed migration, or an unreadable artifact aborts
%% boot rather than serving a runtime that would silently fail every turn. (ATP's
%% mcp_app logs-and-continues; FirstHomey deliberately does not — see the
%% borrow-and-reshape note in fh_engine_migrations.)

-export([start/2, stop/1]).

-spec start(application:start_type(), term()) -> {ok, pid()} | {error, term()}.
start(_StartType, _StartArgs) ->
    logger:set_primary_config(level, info),
    load_dotenv(),
    case fh_engine_db:start_pool() of
        {ok, _PoolPid} ->
            logger:info("engine Postgres pool started"),
            ok = fh_engine_migrations:run(),  %% raises on failure -> boot aborts
            ok = fh_engine_kb:load(),         %% raises on failure -> boot aborts
            fh_engine_sup:start_link();
        {error, database_url_not_set} ->
            logger:error("ENGINE_DATABASE_URL not set — engine cannot boot without "
                         "its runtime-state database"),
            {error, engine_database_url_not_set};
        {error, DbErr} ->
            logger:error("Failed to start engine Postgres pool: ~p", [DbErr]),
            {error, {engine_db_pool, DbErr}}
    end.

-spec stop(term()) -> ok.
stop(_State) ->
    ok.

%% --- .env loader (borrowed from ATP mcp_app; cwd assumption reshaped to engine/.env) ---

-spec load_dotenv() -> ok.
load_dotenv() ->
    Path = case os:getenv("DOTENV_PATH") of
        false ->
            {ok, Cwd} = file:get_cwd(),
            %% rebar3 shell cwd = engine/erlang -> the engine .env is one level up.
            filename:join(filename:dirname(Cwd), ".env");
        P -> P
    end,
    case file:read_file(Path) of
        {ok, Bin} ->
            Lines = binary:split(Bin, [<<"\n">>, <<"\r\n">>], [global]),
            lists:foreach(fun parse_env_line/1, Lines),
            logger:info("Loaded .env from ~s", [Path]);
        {error, enoent} ->
            logger:info("No .env at ~s — using OS env vars", [Path]);
        {error, Reason} ->
            logger:warning("Failed to read .env (~s): ~p", [Path, Reason])
    end.

-spec parse_env_line(binary()) -> ok.
parse_env_line(Line) ->
    case string:trim(Line) of
        <<>> -> ok;
        <<"#", _/binary>> -> ok;
        Trimmed ->
            case binary:split(Trimmed, <<"=">>) of
                [Key, RawVal] ->
                    Val = strip_inline_comment(RawVal),
                    CleanVal = strip_quotes(string:trim(Val)),
                    KeyStr = binary_to_list(string:trim(Key)),
                    case os:getenv(KeyStr) of
                        false -> os:putenv(KeyStr, binary_to_list(CleanVal));
                        _     -> ok  %% OS env wins over .env
                    end;
                _ -> ok
            end
    end.

-spec strip_inline_comment(binary()) -> binary().
strip_inline_comment(Val) ->
    case binary:split(Val, <<" #">>) of
        [Before, _] -> string:trim(Before);
        [V]         -> V
    end.

-spec strip_quotes(binary()) -> binary().
strip_quotes(<<"\"", Rest/binary>>) when byte_size(Rest) >= 1 ->
    binary:part(Rest, 0, byte_size(Rest) - 1);
strip_quotes(<<"'", Rest/binary>>) when byte_size(Rest) >= 1 ->
    binary:part(Rest, 0, byte_size(Rest) - 1);
strip_quotes(Val) ->
    Val.
