#!/usr/bin/env escript
%%! -sname fh_shell_qa_daily_cap_smoke
%%
%% Behavior 36: one question to the assistant per user per (Sydney) day.
%% POST /api/plan-cards/:id/messages claims today's question before the engine is
%% called (fh_shell_meter:claim_question/1 -> fh_shell_store, one SQL statement), answers
%% 429 daily_question_limit {limit, resets_at} when none is left, and gives the question
%% back when the engine does not start the turn. The engine is a stub that counts calls.
%%
%%   SHELL_DATABASE_URL=postgres://<user>@<socket dir, %2F-encoded>/<fresh db> \
%%   ERL_LIBS=_build/default/lib escript test/qa_daily_cap_smoke.escript

-mode(compile).

-define(SHELL_PORT, 8097).
-define(STUB_PORT, 8096).
-define(ADMIN, "admin+qa36@example.com").

main(_) ->
    os:putenv("FH_SHELL_HTTP_PORT", integer_to_list(?SHELL_PORT)),
    os:putenv("SHELL_JWT_SECRET", "qa-daily-cap-smoke-secret"),
    os:putenv("USAGE_CONSUMER_POLL_MS", "3600000"),
    os:putenv("ADMIN_EMAILS", ?ADMIN),
    os:unsetenv("FH_QA_DAILY_LIMIT"),
    {_Pub, Priv} = crypto:generate_key(eddsa, ed25519),
    os:putenv("SHELL_TENANT_ID", binary_to_list(uuid())),
    os:putenv("SHELL_TENANT_PRIVKEY", binary_to_list(base64:encode(Priv))),
    {ok, _} = application:ensure_all_started(fh_shell),
    {ok, _} = application:ensure_all_started(inets),

    persistent_term:put(qa_stub_calls, counters:new(1, [atomics])),
    Stub = compile_load("test/qa_daily_cap_stub_engine.erl"),
    Dispatch = cowboy_router:compile([{'_', [
        {"/api/engine/plan-cards/:id/messages", Stub, []}]}]),
    {ok, _} = cowboy:start_clear(qa_stub_listener, [{port, ?STUB_PORT}],
                                 #{env => #{dispatch => Dispatch}}),
    os:putenv("ENGINE_BASE_URL",
              "http://localhost:" ++ integer_to_list(?STUB_PORT) ++ "/api/engine"),

    expect(fh_shell_meter:daily_question_limit() =:= 1,
           "FH_QA_DAILY_LIMIT unset -> 1 question a day"),

    %% ── one user, one Sydney day: 202, then 429 with no engine call ──────────
    {U, Ask} = user_with_card(email()),
    {202, _} = Ask(good),
    Calls1 = calls(),
    {429, R2} = Ask(good),
    #{<<"error">> := <<"daily_question_limit">>, <<"limit">> := 1,
      <<"resets_at">> := ResetsAt} = fh_shell_util:json_decode(R2),
    expect(Calls1 =:= 1 andalso calls() =:= 1,
           "1st ask -> 202; 2nd the same day -> 429 daily_question_limit, engine not called"),
    expect(ResetsAt =:= scalar(
             "SELECT to_char((((now() AT TIME ZONE 'Australia/Sydney')::date + 1)::timestamp "
             "AT TIME ZONE 'Australia/Sydney') AT TIME ZONE 'UTC', "
             "'YYYY-MM-DD\"T\"HH24:MI:SS\"Z\"')", []),
           "resets_at = the next Sydney midnight, in UTC"),
    io:format("      resets_at ~s~n", [ResetsAt]),

    %% ── the day moves on: the user may ask again ──────────────────────────────
    _ = pgo:query(<<"UPDATE qa_daily_asks SET day = day - 1 WHERE user_id = $1::uuid">>, [U]),
    {202, _} = Ask(good),
    expect(calls() =:= 2, "the next Sydney day -> 202 again"),

    %% ── an admin is not capped ───────────────────────────────────────────────
    {_A, AdminAsk} = user_with_card(<<?ADMIN>>),
    {202, _} = AdminAsk(good),
    {202, _} = AdminAsk(good),
    expect(calls() =:= 4, "an ADMIN_EMAILS user -> 202 twice"),

    %% ── a start the engine refuses does not use the day ──────────────────────
    lists:foreach(fun(S) ->
        {_F, FAsk} = user_with_card(email()),
        persistent_term:put(qa_stub_status, S),
        {S, _} = FAsk(good),
        persistent_term:put(qa_stub_status, 202),
        {202, _} = FAsk(good),
        expect(true, lists:flatten(io_lib:format(
            "engine ~b on the 1st ask -> the 2nd still 202 (question given back)", [S])))
    end, [409, 500]),

    %% ── a malformed body does not use the day ────────────────────────────────
    {_B, BAsk} = user_with_card(email()),
    {400, _} = BAsk(<<"{not json">>),
    {202, _} = BAsk(good),
    expect(true, "invalid JSON -> 400, the day is still unused"),

    %% ── concurrency: two asks at once -> exactly one passes ──────────────────
    lists:foreach(fun(_) ->
        {_C, CAsk} = user_with_card(email()),
        Self = self(),
        [spawn(fun() -> {S, _} = CAsk(good), Self ! {done, S} end) || _ <- [1, 2, 3]],
        Got = lists:sort([receive {done, S} -> S after 10000 -> timeout end
                          || _ <- [1, 2, 3]]),
        case Got of
            [202, 429, 429] -> ok;
            _ -> io:format("FAIL  concurrent asks: ~p~n", [Got]), halt(1)
        end
    end, lists:seq(1, 10)),
    expect(true, "3 concurrent asks by a fresh user, 10 rounds -> exactly one 202 each round"),

    %% ── FH_QA_DAILY_LIMIT raises the cap ─────────────────────────────────────
    os:putenv("FH_QA_DAILY_LIMIT", "2"),
    {_L, LAsk} = user_with_card(email()),
    {202, _} = LAsk(good), {202, _} = LAsk(good), {429, _} = LAsk(good),
    expect(true, "FH_QA_DAILY_LIMIT=2 -> two asks, the third 429"),
    os:unsetenv("FH_QA_DAILY_LIMIT"),

    io:format("~nALL PASSED~n"),
    halt(0).

%% ── helpers ──────────────────────────────────────────────────────────────────

user_with_card(Email) ->
    U = scalar("INSERT INTO users (email) VALUES ($1) RETURNING user_id::text", [Email]),
    Card = uuid(),
    ok = fh_shell_store:insert_plan_card_view(U, Card, <<"Cabramatta">>),
    Jwt = fh_shell_jwt:issue(#{user_id => U, email => Email,
                               roles => [<<"buyer">>], locale => <<"vi">>}),
    Auth = [{"authorization", "Bearer " ++ binary_to_list(Jwt)}],
    Url = "http://localhost:" ++ integer_to_list(?SHELL_PORT)
          ++ "/api/plan-cards/" ++ binary_to_list(Card) ++ "/messages",
    Good = fh_shell_util:json_encode(#{<<"message">> => <<"Can I use FHSS?">>}),
    {U, ask_fun(Url, Auth, Good)}.

ask_fun(Url, Auth, Good) ->
    fun(good) -> req(Url, Auth, Good);
       (Body) -> req(Url, Auth, Body)
    end.

calls() -> counters:get(persistent_term:get(qa_stub_calls), 1).

uuid()  -> fh_shell_util:uuid4().
email() -> <<"qa36+", (uuid())/binary, "@example.com">>.

scalar(SQL, Params) ->
    #{rows := [{Val}]} = pgo:query(list_to_binary(SQL), Params),
    Val.

req(Url, Headers, Body) ->
    {ok, {{_, Status, _}, _, Resp}} =
        httpc:request(post, {Url, Headers, "application/json", Body}, [],
                      [{body_format, binary}]),
    {Status, Resp}.

compile_load(File) ->
    {ok, Mod, Bin} = compile:file(File, [binary, return_errors]),
    {module, Mod} = code:load_binary(Mod, File, Bin),
    Mod.

expect(true, Label)  -> io:format("  ok  ~ts~n", [Label]);
expect(false, Label) -> io:format("FAIL  ~ts~n", [Label]), halt(1).
