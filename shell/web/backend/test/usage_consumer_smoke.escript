#!/usr/bin/env escript
%%! -sname fh_shell_usage_consumer_smoke
%%
%% 8-S5b: the shell-side pull-model outbox consumer. Boots fh_shell, points the engine
%% client at a usage_events STUB, and drives fh_shell_usage_consumer — asserting: it
%% polls by cursor, resolves plan_card_id → user via plan_card_views, mirrors each
%% usage event into usage_records (tokens_total summed), SKIPS an unknown card, is
%% IDEMPOTENT on a re-poll (ON CONFLICT engine_event_id), and advances + propagates its
%% cursor. The consumer is auto-started under fh_shell_sup; the poll interval is set
%% huge so only the synchronous poll_now/0 drives it (no timer interference).
%%
%%   SHELL_DATABASE_URL=postgres://shell:shell_dev_pw@localhost:5434/firsthomey_shell?sslmode=disable \
%%   ERL_LIBS=_build/default/lib escript test/usage_consumer_smoke.escript

-mode(compile).

-define(SHELL_PORT, 8096).
-define(STUB_PORT, 8097).

main(_) ->
    os:putenv("FH_SHELL_HTTP_PORT", integer_to_list(?SHELL_PORT)),
    os:putenv("SHELL_JWT_SECRET", "usage-consumer-smoke-secret"),
    os:putenv("USAGE_CONSUMER_POLL_MS", "3600000"),   % 1h: only poll_now/0 drives it
    {_Pub, Priv} = crypto:generate_key(eddsa, ed25519),
    os:putenv("SHELL_TENANT_ID", binary_to_list(uuid())),
    os:putenv("SHELL_TENANT_PRIVKEY", binary_to_list(base64:encode(Priv))),

    {ok, _} = application:ensure_all_started(fh_shell),
    {ok, _} = application:ensure_all_started(inets),
    %% Re-runnable + deterministic: the stub emits fixed engine_event_ids 1-3 (UNIQUE),
    %% so clear any prior run's mirror rows, THEN restart the consumer so it re-bootstraps
    %% its cursor from the now-empty table (cursor=0) — the consumer that auto-started at
    %% boot may have read a stale MAX left by another smoke.
    _ = pgo:query(<<"DELETE FROM usage_records">>, []),
    ok = supervisor:terminate_child(fh_shell_sup, fh_shell_usage_consumer),
    {ok, _} = supervisor:restart_child(fh_shell_sup, fh_shell_usage_consumer),

    StubMod = compile_load("test/usage_consumer_stub_engine.erl"),
    Dispatch = cowboy_router:compile([{'_', [
        {"/api/engine/usage_events", StubMod, []}
    ]}]),
    {ok, _} = cowboy:start_clear(usage_stub_listener, [{port, ?STUB_PORT}],
                                 #{env => #{dispatch => Dispatch}}),
    os:putenv("ENGINE_BASE_URL",
              "http://localhost:" ++ integer_to_list(?STUB_PORT) ++ "/api/engine"),

    %% a known shell user the stub's events 1 & 2 attribute to; event 3 carries an
    %% unknown user_id (not in users) -> must be skipped (the FK would reject it).
    Email = <<"usage+", (uuid())/binary, "@example.com">>,
    UserId = scalar("INSERT INTO users (email) VALUES ($1) RETURNING user_id::text", [Email]),
    persistent_term:put({usage_stub, card}, uuid()),
    persistent_term:put({usage_stub, user}, UserId),
    persistent_term:put({usage_stub, unknown_user}, uuid()),

    %% --- first poll: mirror the 2 known events, skip the unknown, advance cursor ---
    C1 = fh_shell_usage_consumer:poll_now(),
    expect(C1 =:= 3, "cursor advanced to 3 (highest seen, incl. the skipped event)"),
    expect(count_for(UserId) =:= 2, "2 usage_records mirrored (the owned card's events)"),
    expect(total_for(UserId, 1) =:= 76233, "event 1 tokens_total = sum of 4 slices"),
    expect(total_for(UserId, 2) =:= 59855, "event 2 tokens_total = sum of 4 slices"),
    expect(scalar("SELECT count(*) FROM usage_records WHERE engine_event_id = 3", [])
           =:= 0, "unknown-user event skipped (not in users -> no row)"),
    expect(scalar("SELECT billed FROM usage_records WHERE engine_event_id = 1", [])
           =:= true, "non-admin user is billed (ADMIN_EMAILS unset -> is_admin false)"),
    %% 8-S5c: the consumer now values shadow_cost via fh_shell_pricing at the §4 Opus
    %% ceiling rates. The stub's event 1 IS the measured cold base fill (2005/2032/
    %% 33705/38491) -> $0.46; event 2 IS the cold chat turn (2001/979/44018/12857) ->
    %% $0.19 (billing.md §4, to the cent).
    expect(cents(scalar("SELECT shadow_cost::float8 FROM usage_records WHERE engine_event_id = 1", []))
           =:= 46, "event 1 shadow_cost = $0.46 (cold base, billing.md §4)"),
    expect(cents(scalar("SELECT shadow_cost::float8 FROM usage_records WHERE engine_event_id = 2", []))
           =:= 19, "event 2 shadow_cost = $0.19 (cold chat, billing.md §4)"),

    %% --- second poll: stub re-delivers the same batch → idempotent, no new rows ---
    C2 = fh_shell_usage_consumer:poll_now(),
    expect(C2 =:= 3, "cursor stable at 3 on re-poll"),
    expect(count_for(UserId) =:= 2, "re-poll is idempotent (ON CONFLICT engine_event_id)"),
    expect(persistent_term:get({usage_stub, last_after}) =:= <<"3">>,
           "consumer propagated its cursor as `after=3` on the second poll"),

    io:format("~nALL PASSED~n"),
    halt(0).

%% --- helpers ---

compile_load(File) ->
    {ok, Mod, Bin} = compile:file(File, [binary, return_errors]),
    {module, Mod} = code:load_binary(Mod, File, Bin),
    Mod.

uuid() -> fh_shell_util:uuid4().

count_for(UserId) ->
    scalar("SELECT count(*) FROM usage_records WHERE user_id = $1::uuid", [UserId]).

total_for(UserId, EventId) ->
    scalar("SELECT tokens_total FROM usage_records "
           "WHERE user_id = $1::uuid AND engine_event_id = $2", [UserId, EventId]).

scalar(SQL, Params) ->
    #{rows := [{Val}]} = pgo:query(list_to_binary(SQL), Params),
    Val.

cents(F) -> round(F * 100).

expect(true, Label)  -> io:format("  ok  ~s~n", [Label]);
expect(false, Label) -> io:format("FAIL  ~s~n", [Label]), halt(1).
