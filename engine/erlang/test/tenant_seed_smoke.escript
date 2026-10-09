#!/usr/bin/env escript
%%
%% Behavior 33: the engine registers the shell tenant's public key at boot from
%% SHELL_TENANT_ID / SHELL_TENANT_PUBKEY (fh_engine_app:seed_shell_tenant/0, its block).
%% Boots the real application twice on a fresh database, each boot in its own VM (the
%% pgo pool outlives an application:stop), and checks one tenant row and one active key
%% row; that a JWT signed by the matching private key verifies (fh_engine_auth); that a
%% half-set seed aborts boot; that neither set boots without seeding. Run from
%% engine/erlang:
%%
%%   createdb <db>
%%   ENGINE_DATABASE_URL=postgres://<user>@<socket dir, %2F-encoded>/<db> \
%%     ERL_LIBS=_build/default/lib escript test/tenant_seed_smoke.escript

-mode(compile).

-define(TID, "5b0e7a52-3c1d-4f7e-9a2b-1c3d4e5f6a7b").

main([]) ->
    os:putenv("FH_HTTP_IP", "127.0.0.1"),
    os:putenv("FH_ENGINE_HTTP_PORT", "8094"),
    os:unsetenv("ENGINE_DEV_PROVISION"),
    {Pub, Priv} = crypto:generate_key(eddsa, ed25519),
    os:putenv("SHELL_TENANT_ID", ?TID),
    os:putenv("SHELL_TENANT_PUBKEY", binary_to_list(base64:encode(Pub))),
    R1 = check("first boot -> 1 tenant row, 1 active key row", child("boot") =:= "1 1"),
    R2 = check("second boot -> still 1 tenant row, 1 active key row",
               child("boot") =:= "1 1"),
    os:putenv("FH_SMOKE_PRIV", binary_to_list(base64:encode(Priv))),
    R3 = check("a JWT signed by the shell's private key verifies at the engine",
               child("verify") =:= "verified"),
    os:unsetenv("SHELL_TENANT_PUBKEY"),
    R4 = check("SHELL_TENANT_ID without SHELL_TENANT_PUBKEY aborts boot",
               child("boot") =:= "boot_failed"),
    os:unsetenv("SHELL_TENANT_ID"),
    R5 = check("neither set -> boots, seeds nothing (dev, tests)",
               child("boot") =:= "1 1"),
    os:putenv("SHELL_TENANT_ID", "not-a-uuid"),
    os:putenv("SHELL_TENANT_PUBKEY", binary_to_list(base64:encode(Pub))),
    R6 = check("a malformed tenant id aborts boot", child("boot") =:= "boot_failed"),
    case lists:all(fun(X) -> X end, [R1, R2, R3, R4, R5, R6]) of
        true -> io:format("~nALL PASSED~n"), halt(0);
        false -> io:format("~nFAILED~n"), halt(1)
    end;
main(["boot"]) ->
    logger:set_primary_config(level, none),
    case application:ensure_all_started(fh_engine) of
        {ok, _} ->
            T = count("SELECT count(*) FROM tenants WHERE tenant_id = $1::uuid"),
            K = count("SELECT count(*) FROM tenant_signing_keys "
                      "WHERE tenant_id = $1::uuid AND status = 'active'"),
            io:format("RESULT ~B ~B~n", [T, K]);
        {error, _} ->
            io:format("RESULT boot_failed~n")
    end,
    halt(0);
main(["verify"]) ->
    logger:set_primary_config(level, none),
    {ok, _} = application:ensure_all_started(fh_engine),
    Priv = base64:decode(os:getenv("FH_SMOKE_PRIV")),
    Now = erlang:system_time(second),
    Jwt = fh_engine_auth:sign(#{<<"tenant_id">> => <<?TID>>,
                                <<"user_id">> => <<"0b6c2c1e-1111-4222-8333-944455566677">>,
                                <<"iat">> => Now, <<"exp">> => Now + 60}, Priv),
    case fh_engine_auth:verify_bearer(<<"Bearer ", Jwt/binary>>) of
        {ok, _} -> io:format("RESULT verified~n");
        Other -> io:format("RESULT ~0p~n", [Other])
    end,
    halt(0).

%% Run this escript with Phase in a fresh VM (the env set above is inherited); its
%% RESULT line is the answer.
child(Phase) ->
    Out = os:cmd("escript " ++ escript:script_name() ++ " " ++ Phase ++ " 2>&1"),
    case [L || "RESULT " ++ L <- string:split(Out, "\n", all)] of
        [R | _] -> R;
        [] -> io:format("    ~s output:~n~s~n", [Phase, Out]), none
    end.

count(Sql) ->
    #{rows := [{N}]} = pgo:query(Sql, [<<?TID>>]),
    N.

check(Label, true) -> io:format("  ok  ~s~n", [Label]), true;
check(Label, _) -> io:format("  FAIL ~s~n", [Label]), false.
