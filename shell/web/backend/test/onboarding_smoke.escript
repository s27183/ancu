#!/usr/bin/env escript
%%! -sname fh_shell_onboarding_smoke
%%
%% 8-S3a ablation: the onboarding seam — POST /api/plan-cards over the full HTTP
%% path frontend -> shell backend, driving the real fh_shell_h_plan_cards handler:
%% user-JWT auth (HS256), the engine-client relay, and the shell's plan_card_views
%% insert (shell-architecture.md §5/§7, constraint #1 plan-first).
%%
%% The ENGINE is a stub (onboarding_stub_engine) — the engine's acceptance of the
%% onboarding body + the real base turn is already proven by the engine's
%% seam_smoke.escript (real Opus). Booting the real engine app here would take the
%% only `default` pgo pool, but the shell needs that pool for its plan_card_views
%% write — two `default` pools can't co-boot in one VM. So we boot the FULL shell
%% app (its pool + migrations + the real route table) and stand up a stub engine
%% listener beside it. Identity is a TEST-issued user JWT (the login flow is its own
%% later slice; 8-S0b proved the JWT primitives).
%%
%% Run from shell/web/backend with the shell's dev Postgres up:
%%
%%   SHELL_DATABASE_URL=postgres://shell:shell_dev_pw@localhost:5434/ancu_shell?sslmode=disable \
%%   ERL_LIBS=_build/default/lib escript test/onboarding_smoke.escript

-mode(compile).

-define(SHELL_PORT, 8093).
-define(STUB_PORT, 8095).

main(_) ->
    %% --- env the shell backend reads (user-JWT secret + the tenant-JWT mint
    %%     material; the stub ignores the tenant JWT but mint still requires a real
    %%     ed25519 key to sign). Set BEFORE boot so the .env loader can't override. ---
    os:putenv("FH_SHELL_HTTP_PORT", integer_to_list(?SHELL_PORT)),
    os:putenv("SHELL_JWT_SECRET", "onboarding-smoke-secret"),
    {_Pub, Priv} = crypto:generate_key(eddsa, ed25519),
    os:putenv("SHELL_TENANT_ID", binary_to_list(uuid())),
    os:putenv("SHELL_TENANT_PRIVKEY", binary_to_list(base64:encode(Priv))),

    {ok, _} = application:ensure_all_started(fh_shell),
    {ok, _} = application:ensure_all_started(inets),

    %% --- stand up the stub engine + point the client at it ---
    StubMod = compile_load("test/onboarding_stub_engine.erl"),
    Dispatch = cowboy_router:compile([{'_', [
        {"/api/engine/plan-cards", StubMod, []}
    ]}]),
    {ok, _} = cowboy:start_clear(stub_engine_listener, [{port, ?STUB_PORT}],
                                 #{env => #{dispatch => Dispatch}}),
    os:putenv("ENGINE_BASE_URL",
              "http://localhost:" ++ integer_to_list(?STUB_PORT) ++ "/api/engine"),

    Base = "http://localhost:" ++ integer_to_list(?SHELL_PORT),

    %% --- a real user (plan_card_views.user_id is a FK to users) + a user JWT ---
    Email = <<"onboard+", (uuid())/binary, "@example.com">>,
    UserId = scalar("INSERT INTO users (email) VALUES ($1) RETURNING user_id::text",
                    [Email]),
    Jwt = fh_shell_jwt:issue(#{user_id => UserId, email => Email,
                               roles => [<<"buyer">>], locale => <<"vi">>}),
    Auth = [{"authorization", "Bearer " ++ binary_to_list(Jwt)}],

    OnboardBody = fh_shell_util:json_encode(#{
        <<"state">> => <<"NSW">>,
        <<"target_price_range">> => [600000, 700000],
        <<"target_zone">> => [<<"Cabramatta">>],
        <<"intent">> => <<"owner_occupier">>
    }),

    %% --- POSITIVE: authenticated create -> 202 relayed + a plan_card_views row ---
    {202, Resp} = req(post, Base ++ "/api/plan-cards", Auth, OnboardBody),
    #{<<"plan_card_id">> := PlanCardId, <<"turn_id">> := _} =
        fh_shell_util:json_decode(Resp),
    expect(is_binary(PlanCardId), "create -> 202 with plan_card_id + turn_id"),

    ViewCount = scalar(
        "SELECT count(*) FROM plan_card_views "
        "WHERE user_id = $1::uuid AND engine_plan_card_id = $2::uuid",
        [UserId, PlanCardId]),
    expect(ViewCount =:= 1, "plan_card_views row written for the user"),

    Title = scalar(
        "SELECT title FROM plan_card_views "
        "WHERE user_id = $1::uuid AND engine_plan_card_id = $2::uuid",
        [UserId, PlanCardId]),
    expect(Title =:= <<"Cabramatta">>, "view title taken from the target zone"),

    %% --- AUTH: no Authorization header -> 401 missing_authorization ---
    {401, NoAuthResp} = req(post, Base ++ "/api/plan-cards", [], OnboardBody),
    #{<<"error">> := <<"missing_authorization">>} = fh_shell_util:json_decode(NoAuthResp),
    expect(true, "no user JWT -> 401 missing_authorization"),

    %% --- AUTH: a garbage Bearer token -> 401 invalid_token ---
    BadAuth = [{"authorization", "Bearer not.a.jwt"}],
    {401, BadResp} = req(post, Base ++ "/api/plan-cards", BadAuth, OnboardBody),
    #{<<"error">> := <<"invalid_token">>} = fh_shell_util:json_decode(BadResp),
    expect(true, "invalid user JWT -> 401 invalid_token"),

    %% --- RELAY: the engine's non-202 relays through verbatim (stub 400) ---
    BadStateBody = fh_shell_util:json_encode(#{<<"state">> => <<"ZZ">>}),
    {400, RelayResp} = req(post, Base ++ "/api/plan-cards", Auth, BadStateBody),
    #{<<"error">> := <<"invalid_state">>} = fh_shell_util:json_decode(RelayResp),
    expect(true, "engine 400 relays through verbatim (shell is not a re-validator)"),

    %% no orphaned view for the rejected create
    Orphans = scalar("SELECT count(*) FROM plan_card_views WHERE user_id = $1::uuid",
                     [UserId]),
    expect(Orphans =:= 1, "rejected create wrote no plan_card_views row"),

    io:format("~nALL PASSED~n"),
    halt(0).

%% --- helpers ---

compile_load(File) ->
    {ok, Mod, Bin} = compile:file(File, [binary, return_errors]),
    {module, Mod} = code:load_binary(Mod, File, Bin),
    Mod.

uuid() -> fh_shell_util:uuid4().

expect(true, Label)  -> io:format("  ok  ~s~n", [Label]);
expect(false, Label) -> io:format("FAIL  ~s~n", [Label]), halt(1).

req(Method, Url, Headers, Body) ->
    Request = case Method of
        get -> {Url, Headers};
        _   -> {Url, Headers, "application/json", Body}
    end,
    {ok, {{_, Status, _}, _, Resp}} =
        httpc:request(Method, Request, [], [{body_format, binary}]),
    {Status, Resp}.

scalar(SQL, Params) ->
    #{rows := [{Val}]} = pgo:query(SQL, Params),
    Val.
