#!/usr/bin/env escript
%%! -sname fh_shell_billing_admin_smoke
%%
%% 8-S5e-1: the ADMIN_EMAILS allowlist (billing.md §9). Two halves:
%%
%%   PREDICATE (pure ETS) — fh_shell_billing:is_admin/1 reads the allowlist that
%%   fh_shell_billing loaded at boot from ADMIN_EMAILS (comma-separated). It is
%%   case-insensitive + whitespace-trimmed (DB/JWT casing never matters), honours a
%%   multi-entry list, drops blanks, and is false for a non-admin / undefined.
%%
%%   END-TO-END (consumer) — an admin's usage event books usage_records.billed = FALSE
%%   (their turns meter normally — cost is real, kept for attribution — but are not
%%   charged, §9). Driven through the same usage_events stub as usage_consumer_smoke,
%%   here with the stub's known user made an admin. The MIRROR-IMAGE case (a non-admin
%%   → billed = true) is already proven by usage_consumer_smoke, kept green.
%%
%%   ADMIN_EMAILS is read at boot, so it (and the admin user's email) are fixed BEFORE
%%   application:ensure_all_started/1 — the email is minted up front, then the user row
%%   is inserted with that exact address after boot. The allowlist entry is intentionally
%%   UPPERCASED while the DB email is lowercase, proving the consumer path normalises
%%   both sides.
%%
%%   SHELL_DATABASE_URL=postgres://shell:shell_dev_pw@localhost:5434/firsthomey_shell?sslmode=disable \
%%   ERL_LIBS=_build/default/lib escript test/billing_admin_smoke.escript

-mode(compile).

-define(SHELL_PORT, 8094).
-define(STUB_PORT, 8095).

main(_) ->
    %% Fix the admin identity BEFORE boot: ADMIN_EMAILS is materialised in
    %% fh_shell_billing:init/1. AdminEmail is lowercase (uuid); we list it UPPERCASED
    %% alongside another admin, a blank, and surrounding whitespace to exercise parsing.
    AdminEmail = <<"admin+", (uuid())/binary, "@example.com">>,
    os:putenv("ADMIN_EMAILS",
              "  Ops@Example.com , " ++ string:uppercase(binary_to_list(AdminEmail)) ++ " , "),
    os:putenv("FH_SHELL_HTTP_PORT", integer_to_list(?SHELL_PORT)),
    os:putenv("SHELL_JWT_SECRET", "billing-admin-smoke-secret"),
    os:putenv("USAGE_CONSUMER_POLL_MS", "3600000"),   % 1h: only poll_now/0 drives it
    {_Pub, Priv} = crypto:generate_key(eddsa, ed25519),
    os:putenv("SHELL_TENANT_ID", binary_to_list(uuid())),
    os:putenv("SHELL_TENANT_PRIVKEY", binary_to_list(base64:encode(Priv))),

    {ok, _} = application:ensure_all_started(fh_shell),
    {ok, _} = application:ensure_all_started(inets),

    %% ── PREDICATE: is_admin/1 over the boot-loaded allowlist ─────────────────
    expect(fh_shell_billing:is_admin(AdminEmail) =:= true,
           "the admin email (lowercase) is on the allowlist"),
    expect(fh_shell_billing:is_admin(string:uppercase(AdminEmail)) =:= true,
           "lookup is case-insensitive (uppercased email still matches)"),
    expect(fh_shell_billing:is_admin(<<"  ", AdminEmail/binary, "  ">>) =:= true,
           "lookup trims surrounding whitespace"),
    expect(fh_shell_billing:is_admin(<<"ops@example.com">>) =:= true,
           "a second allowlist entry matches (multi-entry list parsed)"),
    expect(fh_shell_billing:is_admin(<<"nobody+", (uuid())/binary, "@example.com">>) =:= false,
           "a non-admin email is not on the allowlist"),
    expect(fh_shell_billing:is_admin(undefined) =:= false,
           "undefined is not an admin"),
    expect(fh_shell_billing:is_admin(<<>>) =:= false,
           "the empty binary is not an admin (blank entries were dropped at load)"),

    %% ── END-TO-END: an admin's usage event books billed = false ──────────────
    _ = pgo:query(<<"DELETE FROM usage_records">>, []),
    ok = supervisor:terminate_child(fh_shell_sup, fh_shell_usage_consumer),
    {ok, _} = supervisor:restart_child(fh_shell_sup, fh_shell_usage_consumer),

    StubMod = compile_load("test/usage_consumer_stub_engine.erl"),
    Dispatch = cowboy_router:compile([{'_', [
        {"/api/engine/usage_events", StubMod, []}
    ]}]),
    {ok, _} = cowboy:start_clear(billing_stub_listener, [{port, ?STUB_PORT}],
                                 #{env => #{dispatch => Dispatch}}),
    os:putenv("ENGINE_BASE_URL",
              "http://localhost:" ++ integer_to_list(?STUB_PORT) ++ "/api/engine"),

    %% The stub attributes events 1 & 2 to {usage_stub, user}; make that user the admin.
    AdminId = scalar("INSERT INTO users (email) VALUES ($1) RETURNING user_id::text",
                     [AdminEmail]),
    persistent_term:put({usage_stub, card}, uuid()),
    persistent_term:put({usage_stub, user}, AdminId),
    persistent_term:put({usage_stub, unknown_user}, uuid()),

    C1 = fh_shell_usage_consumer:poll_now(),
    expect(C1 =:= 3, "cursor advanced to 3 (highest seen)"),
    expect(count_for(AdminId) =:= 2, "2 usage_records mirrored for the admin user"),
    expect(billed(1) =:= false, "admin event 1 booked billed = false (attribution, no charge)"),
    expect(billed(2) =:= false, "admin event 2 booked billed = false"),
    %% the metered unit is still tokens: the admin's usage is fully counted, only the
    %% billed flag differs — so the period meter / gate treat an admin like anyone else.
    expect(total_for(AdminId, 1) =:= 76233, "admin usage still fully metered (tokens unaffected)"),

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

billed(EventId) ->
    scalar("SELECT billed FROM usage_records WHERE engine_event_id = $1", [EventId]).

scalar(SQL, Params) ->
    #{rows := [{Val}]} = pgo:query(list_to_binary(SQL), Params),
    Val.

expect(true, Label)  -> io:format("  ok  ~s~n", [Label]);
expect(false, Label) -> io:format("FAIL  ~s~n", [Label]), halt(1).
