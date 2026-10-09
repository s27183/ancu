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
            ok = seed_shell_tenant(),         %% raises on a malformed seed -> aborts
            ok = fh_engine_suburb_snapshot:load(), %% when the shipped snapshot changed (its block)
            ok = fh_engine_kb:load(),         %% raises on failure -> boot aborts
            case fh_engine_sup:start_link() of
                {ok, SupPid} ->
                    maybe_dev_refresh_sweep(),
                    {ok, SupPid};
                Other ->
                    Other
            end;
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

%% Reproducible -> P-6 · Shells reach the engine only through the contract -> The engine -> the shell tenant seeded at boot
%% With SHELL_TENANT_ID and SHELL_TENANT_PUBKEY set (prod: do_deploy.py derives the
%% public key from the shell's SHELL_TENANT_PRIVKEY), the engine registers that tenant
%% and key itself, after migrations, idempotently (ensure_signing_key: one active row
%% per key, boot after boot). Why here: the engine's App Platform dev database is
%% reachable from the engine app only, so no out-of-band psql can register the key
%% (behavior 33, 2026-10-09). Only a PUBLIC key enters through env — a forged one
%% verifies nothing the private half did not sign. Both unset (dev, tests) -> a
%% no-op; one set without the other, a non-uuid id or a key that is not 32 bytes of
%% base64 aborts boot rather than serve a shell whose every call would 401.
-spec seed_shell_tenant() -> ok.
seed_shell_tenant() ->
    case {os:getenv("SHELL_TENANT_ID", ""), os:getenv("SHELL_TENANT_PUBKEY", "")} of
        {"", ""} ->
            ok;
        {Id, Pub} when Id =/= "", Pub =/= "" ->
            TenantId = list_to_binary(Id),
            PubB64 = list_to_binary(Pub),
            match = re:run(TenantId, "^[0-9a-fA-F-]{36}$", [{capture, none}]),
            32 = byte_size(base64:decode(PubB64)),
            ok = fh_engine_store:upsert_tenant(TenantId, <<"ancu-shell">>),
            ok = fh_engine_store:ensure_signing_key(TenantId, <<"ed25519">>, PubB64),
            logger:notice("shell tenant ~s seeded (ed25519 ~s)", [TenantId, PubB64]),
            ok;
        _ ->
            error({incomplete_tenant_seed, "set both SHELL_TENANT_ID and SHELL_TENANT_PUBKEY"})
    end.

%% DEV-ONLY (gated on ENGINE_DEV_PROVISION): after the tree is up, refresh saved cards
%% in place so a rebuild + restart picks up resolver/KB changes without a manual re-run
%% (plan-card-refresh.md — the rebuild IS the trigger). Spawned async so boot isn't
%% blocked; resolver-only (no LLM); a crash is isolated + logged, never aborts boot.
%% Prod refresh is an authenticated, throttled trigger, never this boot hook.
-spec maybe_dev_refresh_sweep() -> ok.
maybe_dev_refresh_sweep() ->
    case os:getenv("ENGINE_DEV_PROVISION") of
        V when V =:= "1"; V =:= "true" ->
            spawn(fun() ->
                try fh_engine_refresh:sweep(all)
                catch Class:Reason ->
                    logger:warning("[refresh-sweep] skipped: ~p:~p", [Class, Reason])
                end
            end),
            ok;
        _ ->
            ok
    end.

%% --- .env loader (borrowed from ATP mcp_app; cwd assumption reshaped to engine/.env) ---

-spec load_dotenv() -> ok.
load_dotenv() ->
    Path = case os:getenv("DOTENV_PATH") of
        false ->
            {ok, Cwd} = file:get_cwd(),
            %% cwd = engine/erlang → the single repo-root .env is two levels up
            %% (one .env for both backends, mirroring aleap/atp).
            filename:join([filename:dirname(filename:dirname(Cwd)), ".env"]);
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
