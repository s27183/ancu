-module(fh_shell_app).
-behaviour(application).

%% Shell-backend boot. Mirrors fh_engine_app's order (it is the same shape, one
%% database simpler — no KB artifact):
%%   .env -> Postgres pool -> migrations (synchronous) -> supervision tree.
%% Migrations run BEFORE the tree accepts requests.
%%
%% FAIL-CLOSED, same reasoning as the engine: the shell's identity + commerce state
%% (users, magic tokens, subscriptions, the usage mirror) lives in Postgres, so a
%% missing SHELL_DATABASE_URL or a failed migration aborts boot rather than serving
%% a backend that would silently fail every login. The engine and shell are separate
%% databases (engine-contract §9.2); this pool is keyed on SHELL_DATABASE_URL.

-export([start/2, stop/1]).

-spec start(application:start_type(), term()) -> {ok, pid()} | {error, term()}.
start(_StartType, _StartArgs) ->
    logger:set_primary_config(level, info),
    load_dotenv(),
    case fh_shell_db:start_pool() of
        {ok, _PoolPid} ->
            logger:info("shell Postgres pool started"),
            ok = fh_shell_migrations:run(),  %% raises on failure -> boot aborts
            ok = fh_shell_provision:maybe_autoprovision(),  %% dev-only tenant handshake
            fh_shell_sup:start_link();
        {error, database_url_not_set} ->
            logger:error("SHELL_DATABASE_URL not set — shell backend cannot boot "
                         "without its identity/commerce database"),
            {error, shell_database_url_not_set};
        {error, DbErr} ->
            logger:error("Failed to start shell Postgres pool: ~p", [DbErr]),
            {error, {shell_db_pool, DbErr}}
    end.

-spec stop(term()) -> ok.
stop(_State) ->
    ok.

%% --- .env loader (mirrors fh_engine_app: ONE repo-root .env for both backends,
%% the aleap/atp convention). rebar3 shell cwd = shell/web/backend, so the repo
%% root is three levels up. ---

-spec load_dotenv() -> ok.
load_dotenv() ->
    Path = case os:getenv("DOTENV_PATH") of
        false ->
            {ok, Cwd} = file:get_cwd(),
            %% cwd = shell/web/backend → repo root is three levels up.
            filename:join(
                [filename:dirname(filename:dirname(filename:dirname(Cwd))), ".env"]);
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
