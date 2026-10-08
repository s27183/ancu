#!/usr/bin/env escript
%%! -sname fh_shell_commerce_migration_smoke
%%
%% Migration smoke for 8-S5a (002_commerce.sql — the shell commerce DB).
%% Boots fh_shell against a dev Postgres and asserts: 002 applied, the three
%% commerce tables exist, the rows round-trip (incl. defaults), the idempotency
%% key + CHECK constraints behave, and the runner's "already applied" path is a
%% clean no-op on a second run. Run from shell/web/backend:
%%
%%   SHELL_DATABASE_URL=postgres://shell:shell_dev_pw@localhost:5434/ancu_shell?sslmode=disable \
%%   ERL_LIBS=_build/default/lib escript test/commerce_migration_smoke.escript

-mode(compile).

main(_) ->
    os:putenv("FH_SHELL_HTTP_PORT", "8093"),
    {ok, _} = application:ensure_all_started(fh_shell),

    %% --- 002 migration recorded ---
    expect(scalar("SELECT count(*) FROM schema_migrations WHERE version = $1",
                  [<<"002">>]) =:= 1,
           "002_commerce migration recorded"),

    %% --- the three tables exist ---
    [ expect(scalar("SELECT count(*) FROM information_schema.tables "
                    "WHERE table_schema = 'public' AND table_name = $1", [T]) =:= 1,
             ["table exists: ", T])
      || T <- [<<"subscriptions">>, <<"usage_records">>, <<"charges">>] ],

    %% --- a user to own the commerce rows ---
    Email = <<"commerce+", (fh_shell_util:uuid4())/binary, "@example.com">>,
    #{command := insert} =
        pgo:query(<<"INSERT INTO users (email) VALUES ($1)">>, [Email]),
    [{Uid}] = rows("SELECT user_id FROM users WHERE email = $1", [Email]),

    %% --- subscriptions: defaults tier=free status=active ---
    #{command := insert} =
        pgo:query(<<"INSERT INTO subscriptions (user_id) VALUES ($1)">>, [Uid]),
    [{Tier, Status}] =
        rows("SELECT tier, status FROM subscriptions WHERE user_id = $1", [Uid]),
    expect(Tier =:= <<"free">> andalso Status =:= <<"active">>,
           "subscription defaults: tier=free status=active"),

    %% one subscription per user (UNIQUE user_id) — second insert rejected
    expect(insert_fails(<<"INSERT INTO subscriptions (user_id) VALUES ($1)">>, [Uid]),
           "subscriptions.user_id UNIQUE rejects a second row"),

    %% bad tier rejected by CHECK
    expect(insert_fails(<<"INSERT INTO subscriptions (user_id, tier) VALUES ($1, $2)">>,
                        [Uid, <<"platinum">>]),
           "subscriptions.tier CHECK rejects an unknown tier"),

    %% --- usage_records: idempotent on engine_event_id (a bigint — the engine's
    %%     plan_card_events.event_id; unique per run via the monotonic clock).
    %%     NEGATED: fh_shell_usage_consumer bootstraps its poll cursor from
    %%     MAX(engine_event_id) across this whole table (002_commerce.sql) — a
    %%     positive fixture id can jump the real consumer's cursor past every
    %%     future real event and silently wedge it. ---
    Ev = -erlang:system_time(microsecond),
    Ins = <<"INSERT INTO usage_records "
            "(user_id, engine_event_id, tokens_total, shadow_cost) "
            "VALUES ($1, $2, $3, $4) ON CONFLICT (engine_event_id) DO NOTHING">>,
    #{command := insert} = pgo:query(Ins, [Uid, Ev, 1234, 0.456789]),
    #{command := insert} = pgo:query(Ins, [Uid, Ev, 9999, 9.9]),   % replay, no-op
    expect(scalar("SELECT count(*) FROM usage_records WHERE engine_event_id = $1",
                  [Ev]) =:= 1,
           "usage_records ON CONFLICT (engine_event_id) is idempotent"),
    expect(scalar("SELECT tokens_total FROM usage_records WHERE engine_event_id = $1",
                  [Ev]) =:= 1234,
           "the replay did NOT overwrite the first row"),
    expect(scalar("SELECT billed FROM usage_records WHERE engine_event_id = $1",
                  [Ev]) =:= true,
           "usage_records.billed defaults true"),

    %% --- charges: kind CHECK ---
    #{command := insert} =
        pgo:query(<<"INSERT INTO charges (user_id, kind, amount) VALUES ($1, $2, $3)">>,
                  [Uid, <<"doc_review">>, 40.00]),
    expect(insert_fails(<<"INSERT INTO charges (user_id, kind, amount) VALUES ($1, $2, $3)">>,
                        [Uid, <<"bribe">>, 1.00]),
           "charges.kind CHECK rejects an unknown add-on"),

    %% --- runner is idempotent: re-run applies nothing, no crash ---
    ok = fh_shell_migrations:run(),
    expect(scalar("SELECT count(*) FROM schema_migrations WHERE version = $1",
                  [<<"002">>]) =:= 1,
           "second runner pass leaves 002 applied-once (no-op)"),

    io:format("~nALL PASSED~n"),
    halt(0).

%% --- helpers ---

expect(true, Label)  -> io:format("  ok  ~s~n", [flat(Label)]);
expect(false, Label) -> io:format("FAIL  ~s~n", [flat(Label)]), halt(1).

flat(L) when is_list(L) -> lists:flatten(L);
flat(B) when is_binary(B) -> B.

%% true iff the statement raises (a constraint violation surfaces as a pgo error,
%% which fh_engine/pgo turns into a throw/exit on the pool path).
insert_fails(SQL, Params) ->
    try pgo:query(SQL, Params) of
        #{command := _} -> false;
        {error, _}      -> true
    catch _:_ -> true
    end.

scalar(SQL, Params) ->
    [{V}] = rows(SQL, Params),
    V.

rows(SQL, Params) ->
    #{rows := Rows} = pgo:query(list_to_binary(SQL), Params),
    Rows.
