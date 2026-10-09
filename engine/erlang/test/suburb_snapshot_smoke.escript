#!/usr/bin/env escript
%%
%% Behavior 37: the engine loads priv/suburbs/ at boot when the shipped snapshot differs
%% from the one last loaded (fh_engine_suburb_snapshot, its block). Boots the real
%% application three times on a fresh database, each boot in its own VM (the pgo pool
%% outlives an application:stop), and checks:
%%   1. empty table → every snapshot row and the sources load, inside the 60 s
%%      health-check delay, and the snapshot's sha is recorded;
%%   2. the same snapshot again → nothing rewritten (updated_at unchanged);
%%   3. a table holding an OLDER snapshot (sha recorded differs, a fact altered) → the
%%      boot refreshes every row back to the shipped facts.
%% Run from engine/erlang:
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
    [N1, S1, Ms1, U1, Sha1, _] = result(child("boot")),
    R1 = check(io_lib:format("empty table: loads all ~B rows and the sources (boot ~s ms)", [Want, Ms1]),
               list_to_integer(N1) =:= Want andalso list_to_integer(S1) >= 1 andalso Sha1 =/= "-"),
    R2 = check("the load fits the 60 s health-check delay", list_to_integer(Ms1) < 60000),
    [N2, _, _, U2, Sha2, _] = result(child("boot")),
    R3 = check("same snapshot: same row count, no row rewritten",
               list_to_integer(N2) =:= Want andalso U1 =:= U2 andalso Sha2 =:= Sha1),
    [_, _, _, _, _, Fact0] = result(child("age")),
    [N4, _, Ms4, U4, Sha4, Fact4] = result(child("boot")),
    R4 = check(io_lib:format("older snapshot recorded: refreshed every row (boot ~s ms)", [Ms4]),
               Fact0 =:= "aged" andalso Fact4 =/= "aged" andalso
               list_to_integer(N4) =:= Want andalso U4 =/= U2 andalso Sha4 =:= Sha1),
    case R1 andalso R2 andalso R3 andalso R4 of
        true -> io:format("~nALL PASSED~n"), halt(0);
        false -> io:format("~nFAILED~n"), halt(1)
    end;
main(["boot"]) ->
    logger:set_primary_config(level, none),
    T0 = erlang:monotonic_time(millisecond),
    {ok, _} = application:ensure_all_started(fh_engine),
    report(erlang:monotonic_time(millisecond) - T0);
main(["age"]) ->
    %% Make the table look loaded by an older snapshot: another sha, one fact changed.
    logger:set_primary_config(level, none),
    {ok, _} = application:ensure_all_started(fh_engine),
    #{command := update} = pgo:query(<<"UPDATE reference_snapshots SET sha256 = 'older' WHERE name = 'suburbs'">>, []),
    #{command := update} = pgo:query(<<"UPDATE suburbs SET facts_jsonb = '{\"census_total_persons\": \"aged\"}' WHERE sal_code = 'SAL10738'">>, []),
    report(0).

report(Ms) ->
    N = scalar("SELECT count(*) FROM suburbs"),
    S = scalar("SELECT count(*) FROM suburb_sources"),
    U = scalar("SELECT coalesce(extract(epoch FROM max(updated_at))::text, '-') FROM suburbs"),
    Sha = scalar("SELECT coalesce(max(sha256), '-') FROM reference_snapshots WHERE name = 'suburbs'"),
    F = scalar("SELECT facts_jsonb->>'census_total_persons' FROM suburbs WHERE sal_code = 'SAL10738'"),
    io:format("RESULT ~B ~B ~B ~s ~s ~s~n", [N, S, Ms, U, Sha, F]),
    halt(0).

result(Line) -> string:split(Line, " ", all).

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
