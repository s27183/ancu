#!/usr/bin/env escript
%%
%% Behavior 37: the engine loads priv/suburbs/ into an empty `suburbs` table at boot
%% (fh_engine_suburb_snapshot, its block). Boots the real application twice on a fresh
%% database, each boot in its own VM (the pgo pool outlives an application:stop), and
%% checks: the first boot loads every snapshot row (and the sources), in under the 60 s
%% health-check delay; the second boot loads nothing (updated_at unchanged); a filled
%% table is never touched. Run from engine/erlang:
%%
%%   createdb <db>
%%   ENGINE_DATABASE_URL=postgres://<user>@<socket dir, %2F-encoded>/<db> \
%%     ERL_LIBS=_build/default/lib escript test/suburb_snapshot_smoke.escript

-mode(compile).

main([]) ->
    os:putenv("FH_HTTP_IP", "127.0.0.1"),
    os:putenv("FH_ENGINE_HTTP_PORT", "8095"),
    Want = snapshot_rows(),
    io:format("  snapshot holds ~B suburbs~n", [Want]),
    [N1, S1, Ms1, U1] = string:split(child("boot"), " ", all),
    R1 = check(io_lib:format("first boot loads all ~B rows and the sources (~s ms)", [Want, Ms1]),
               list_to_integer(N1) =:= Want andalso list_to_integer(S1) >= 1),
    R2 = check("first boot's load fits the 60 s health-check delay",
               list_to_integer(Ms1) < 60000),
    [N2, _, _, U2] = string:split(child("boot"), " ", all),
    R3 = check("second boot: same row count, no row rewritten",
               list_to_integer(N2) =:= Want andalso U1 =:= U2),
    case R1 andalso R2 andalso R3 of
        true -> io:format("~nALL PASSED~n"), halt(0);
        false -> io:format("~nFAILED~n"), halt(1)
    end;
main(["boot"]) ->
    logger:set_primary_config(level, none),
    T0 = erlang:monotonic_time(millisecond),
    {ok, _} = application:ensure_all_started(fh_engine),
    Ms = erlang:monotonic_time(millisecond) - T0,
    N = scalar("SELECT count(*) FROM suburbs"),
    S = scalar("SELECT count(*) FROM suburb_sources"),
    U = scalar("SELECT coalesce(extract(epoch FROM max(updated_at))::text, '-') FROM suburbs"),
    io:format("RESULT ~B ~B ~B ~s~n", [N, S, Ms, U]),
    halt(0).

snapshot_rows() ->
    {ok, Gz} = file:read_file("priv/suburbs/suburbs.json.gz"),
    length(json:decode(zlib:gunzip(Gz))).

%% Run this escript with Phase in a fresh VM; its RESULT line is the answer.
child(Phase) ->
    Out = os:cmd("escript " ++ escript:script_name() ++ " " ++ Phase ++ " 2>&1"),
    case [L || "RESULT " ++ L <- string:split(Out, "\n", all)] of
        [R | _] -> R;
        [] -> io:format("    ~s output:~n~s~n", [Phase, Out]), halt(1)
    end.

scalar(Sql) ->
    #{rows := [{V}]} = pgo:query(Sql, []),
    V.

check(Label, true) -> io:format("  ok  ~s~n", [Label]), true;
check(Label, _) -> io:format("  FAIL ~s~n", [Label]), false.
