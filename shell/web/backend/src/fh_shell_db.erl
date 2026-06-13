-module(fh_shell_db).

%% Postgres connection pool for the shell's identity + commerce state. Thin wrapper
%% over pgo (the mandated client), a near-verbatim sibling of fh_engine_db — the only
%% difference is the env var: SHELL_DATABASE_URL, NOT ENGINE_DATABASE_URL. The engine
%% and shell are separate databases and the API is the only contract between them
%% (engine-contract §9.2/§9.3 — no cross-DB joins, ever). Keeping the two pool
%% wrappers separate (rather than sharing one) keeps that boundary visible in code.

-export([start_pool/0, pool/0]).

-define(POOL, default).

-spec pool() -> atom().
pool() -> ?POOL.

-spec start_pool() -> {ok, pid()} | {error, term()}.
start_pool() ->
    case os:getenv("SHELL_DATABASE_URL") of
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
