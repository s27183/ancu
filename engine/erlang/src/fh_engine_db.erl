-module(fh_engine_db).

%% Postgres connection pool for the engine's runtime state. Thin wrapper over pgo
%% (the mandated client). Starts the `default` pool from ENGINE_DATABASE_URL; query
%% helpers and the per-plan-card data access land with the gateway (#8). Migrations
%% live in fh_engine_migrations and use the pool started here.
%%
%% URL parsing borrowed from ATP mcp_db (keyed on ENGINE_DATABASE_URL, not
%% DATABASE_URL — the engine and shell are separate databases, engine-contract §9).

-export([start_pool/0, pool/0]).

-define(POOL, default).

-spec pool() -> atom().
pool() -> ?POOL.

-spec start_pool() -> {ok, pid()} | {error, term()}.
start_pool() ->
    case os:getenv("ENGINE_DATABASE_URL") of
        false ->
            {error, database_url_not_set};
        Url ->
            case parse_database_url(Url) of
                {ok, Config} -> pgo:start_pool(?POOL, Config);
                {error, _} = Err -> Err
            end
    end.

-spec parse_database_url(string()) -> {ok, map()} | {error, term()}.
parse_database_url(Url) ->
    case uri_string:parse(Url) of
        #{host := Host, path := Path} = Parsed ->
            Port = maps:get(port, Parsed, 5432),
            DbName = string:trim(Path, leading, "/"),
            {User, Pass} = parse_userinfo(maps:get(userinfo, Parsed, <<>>)),
            Query = maps:get(query, Parsed, <<>>),
            Config0 = #{
                host => Host,
                port => Port,
                user => User,
                password => Pass,
                database => DbName,
                pool_size => 10
            },
            Config = case requires_ssl(Query) of
                true  -> Config0#{ssl => true, ssl_options => [{verify, verify_none}]};
                false -> Config0
            end,
            {ok, Config};
        _ ->
            {error, {invalid_database_url, Url}}
    end.

-spec requires_ssl(binary() | string()) -> boolean().
requires_ssl(Query) when is_binary(Query) ->
    requires_ssl(binary_to_list(Query));
requires_ssl(Query) ->
    case lists:keyfind("sslmode", 1, uri_string:dissect_query(Query)) of
        {_, "disable"} -> false;
        {_, _} -> true;
        false -> false
    end.

-spec parse_userinfo(binary() | string()) -> {string(), string()}.
parse_userinfo(Info) when is_binary(Info) ->
    parse_userinfo(binary_to_list(Info));
parse_userinfo(Info) ->
    case string:split(Info, ":") of
        [User, Pass] -> {User, Pass};
        [User] -> {User, ""}
    end.
