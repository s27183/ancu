#!/usr/bin/env escript
%%! -sname fh_shell_property_id_smoke
%%
%% Behavior 139: a property id can only name a property; it never steers the shell's
%% call to the engine. Drives the REAL shell (routes, auth, ownership, the :pid guard
%% in fh_shell_h_plan_card, fh_shell_engine_client) against a stub engine that records
%% every request it receives — method, path and query — and answers 202 {}.
%%
%%   Expect 1 — property: hostile :pid values sent to the transaction and documents
%%              routes of the user's OWN plan card answer 404 and the engine records
%%              no request (5000 cases, seed 139, plus the reviewer's payloads).
%%   Expect 2 — property: every engine client function that puts an id in a path
%%              sends each id as exactly one segment, no query, no fragment; an id
%%              httpc would normalize away (`.`, `..`) is refused and nothing is sent
%%              (5000 cases, seed 139).
%%   Expect 3 — a real uuid :pid on the user's own card still reaches the engine's
%%              transaction and documents routes with the body intact.
%%
%% Before the fix (7611a70) the reviewer's `..%2Fmessages%3F` reached the engine as
%% POST /plan-cards/<id>/messages (measured 2026-10-27).
%%
%% Run from shell/web/backend with a shell database (it migrates it at boot):
%%
%%   FH_HTTP_IP=127.0.0.1 DOTENV_PATH=/nonexistent SHELL_DATABASE_URL=postgres://<user>@<host>/<db> \
%%   ERL_LIBS=_build/default/lib escript test/property_id_smoke.escript

-mode(compile).
-export([init/2]).

-define(SEED, 139).
-define(CASES, 5000).

%% --- the stub engine: one catch-all handler that records and answers 202 {} ---
init(Req0, State) ->
    {ok, Body, Req} = cowboy_req:read_body(Req0),
    ets:insert(engine_seen, {erlang:unique_integer([monotonic]),
                             cowboy_req:method(Req), cowboy_req:path(Req),
                             cowboy_req:qs(Req), Body}),
    {ok, cowboy_req:reply(202, #{<<"content-type">> => <<"application/json">>},
                          <<"{}">>, Req), State}.

main(_) ->
    ShellPort = free_port(),
    os:putenv("FH_SHELL_HTTP_PORT", integer_to_list(ShellPort)),
    os:putenv("SHELL_JWT_SECRET", "property-id-smoke-secret"),
    {_Pub, Priv} = crypto:generate_key(eddsa, ed25519),
    os:putenv("SHELL_TENANT_ID", binary_to_list(uuid())),
    os:putenv("SHELL_TENANT_PRIVKEY", binary_to_list(base64:encode(Priv))),
    {ok, _} = application:ensure_all_started(fh_shell),
    {ok, _} = application:ensure_all_started(inets),
    ets:new(engine_seen, [named_table, public, ordered_set]),
    Dispatch = cowboy_router:compile([{'_', [{"/[...]", ?MODULE, []}]}]),
    {ok, _} = cowboy:start_clear(stub_engine, [{ip, {127,0,0,1}}, {port, 0}],
                                 #{env => #{dispatch => Dispatch}}),
    os:putenv("ENGINE_BASE_URL", "http://127.0.0.1:"
              ++ integer_to_list(ranch:get_port(stub_engine)) ++ "/api/engine"),
    Base = "http://127.0.0.1:" ++ integer_to_list(ShellPort),

    Email = <<"pid+", (uuid())/binary, "@example.com">>,
    UserId = scalar("INSERT INTO users (email) VALUES ($1) RETURNING user_id::text", [Email]),
    CardId = uuid(),
    ok = fh_shell_store:insert_plan_card_view(UserId, CardId, <<"Cabramatta">>),
    Jwt = fh_shell_jwt:issue(#{user_id => UserId, email => Email,
                               roles => [<<"buyer">>], locale => <<"vi">>}),
    Auth = [{"authorization", "Bearer " ++ binary_to_list(Jwt)}],

    rand:seed(exsss, ?SEED),

    %% ---- Expect 3: a real property id still works ----
    Pid = uuid(),
    TxBody = <<"{\"contract_signed_date\":\"2026-11-01\",\"settlement_date\":\"2026-12-15\"}">>,
    {TxS, _} = req(post, Base ++ card_path(CardId) ++ "/properties/" ++ binary_to_list(Pid)
                         ++ "/transaction", Auth, TxBody),
    DocBody = <<"{\"content_base64\":\"aGVsbG8=\",\"mime_type\":\"application/pdf\"}">>,
    {DocS, _} = req(post, Base ++ card_path(CardId) ++ "/properties/" ++ binary_to_list(Pid)
                          ++ "/documents", Auth, DocBody),
    Seen3 = drain(),
    WantTx = iolist_to_binary(["/api/engine/plan-cards/", CardId, "/properties/", Pid, "/transaction"]),
    WantDoc = iolist_to_binary(["/api/engine/plan-cards/", CardId, "/properties/", Pid, "/documents"]),
    expect(TxS =:= 202 andalso DocS =:= 202, "Expect 3: real uuid :pid relays 202 for transaction and documents"),
    expect([{P, Q} || {_, <<"POST">>, P, Q, _} <- Seen3] =:= [{WantTx, <<>>}, {WantDoc, <<>>}],
           "Expect 3: the engine saw exactly the two property routes of the user's own card"),
    expect([B || {_, _, _, _, B} <- Seen3] =:= [TxBody, DocBody],
           "Expect 3: each body reached the engine intact"),

    %% ---- Expect 1: hostile :pid values -> 404, engine never called ----
    Reviewer = [<<"..%2Fmessages%3F">>,
                iolist_to_binary(["..%2F..%2F", uuid(), "%2Fsimulate%3F"]),
                <<"..">>, <<".">>, <<"%2e%2e">>],
    Suffixed = [iolist_to_binary([uri_string:quote(uuid()), Suf])
                || Suf <- [<<"%0A">>, <<"%2Fx">>, <<"%3Fa">>, <<"%00">>, <<"%23">>, <<"%25">>]],
    Random = [uri_string:quote(gen_hostile()) || _ <- lists:seq(1, ?CASES)],
    Cases = Reviewer ++ Suffixed ++ Random,
    Bad1 = lists:filtermap(fun(Raw) ->
        Fails = [{Route, S} || Route <- ["transaction", "documents"],
                 {S, _} <- [req(post, Base ++ card_path(CardId) ++ "/properties/"
                                       ++ binary_to_list(Raw) ++ "/" ++ Route, Auth, <<"{}">>)],
                 S =/= 404],
        Seen = drain(),
        case {Fails, Seen} of
            {[], []} -> false;
            _ -> {true, {Raw, Fails, Seen}}
        end
    end, Cases),
    io:format("Expect 1: ~p cases, seed ~p: counterexamples ~p~n",
              [length(Cases), ?SEED, lists:sublist(Bad1, 5)]),
    expect(Bad1 =:= [], "Expect 1: every hostile :pid answered 404 and the engine saw nothing"),

    %% ---- Expect 2: every id the client puts in a path is one segment ----
    Fns = engine_client_calls(),
    Bad2 = lists:filtermap(fun(_) ->
        {Name, Call, Shape} = lists:nth(rand:uniform(length(Fns)), Fns),
        A = gen_id(), B = gen_id(),
        Result = try Call(UserId, A, B) catch error:{not_an_id, _} -> refused end,
        Seen = drain(),
        Got = [decoded({P, Q}) || {_, _, P, Q, _} <- Seen],
        Dot = fun(X) -> lists:member(X, [<<".">>, <<"..">>]) end,
        case {Result, Got} of
            {refused, []} ->
                %% refused only when an id it uses is a dot segment
                case Dot(A) orelse (Dot(B) andalso Name =/= get_plan_card) of
                    true -> false;
                    false -> {true, {Name, A, B, refused_without_cause}}
                end;
            {_, [_]} ->
                case Got =:= [decoded(Shape(A, B))] of
                    true -> false;
                    false -> {true, {Name, A, B, Got, Shape(A, B)}}
                end;
            _ -> {true, {Name, A, B, Result, Got}}
        end
    end, lists:seq(1, ?CASES)),
    io:format("Expect 2: ~p cases, seed ~p: counterexamples ~p~n",
              [?CASES, ?SEED, lists:sublist(Bad2, 5)]),
    expect(Bad2 =:= [], "Expect 2: each id reached the engine as exactly one segment"),

    io:format("~nproperty_id_smoke: ALL PASS~n"),
    halt(0).

%% Each engine client function that builds a path from an id, how to call it with two
%% generated ids, and the decoded path + query the engine must see. cowboy's path is
%% the raw (still-encoded) path, so the expectation encodes as the client must.
engine_client_calls() ->
    C = fun fh_shell_engine_client:get_plan_card/2,
    P = fun(Id, Suffix) -> {iolist_to_binary(["/api/engine/plan-cards/", q(Id), Suffix]), <<>>} end,
    [{get_plan_card,     fun(U, A, _) -> C(U, A) end, fun(A, _) -> P(A, "") end},
     {delete_plan_card,  fun(U, A, _) -> fh_shell_engine_client:delete_plan_card(U, A) end, fun(A, _) -> P(A, "") end},
     {post_message,      fun(U, A, _) -> fh_shell_engine_client:post_message(U, A, #{}) end, fun(A, _) -> P(A, "/messages") end},
     {get_conversation,  fun(U, A, _) -> fh_shell_engine_client:get_conversation(U, A) end, fun(A, _) -> P(A, "/conversation") end},
     {simulate,          fun(U, A, _) -> fh_shell_engine_client:simulate(U, A, #{}) end, fun(A, _) -> P(A, "/simulate") end},
     {refine,            fun(U, A, _) -> fh_shell_engine_client:refine(U, A, #{}) end, fun(A, _) -> P(A, "/refine") end},
     {set_profile_financials, fun(U, A, _) -> fh_shell_engine_client:set_profile_financials(U, A, #{}) end, fun(A, _) -> P(A, "/profile") end},
     {set_checklist_status, fun(U, A, _) -> fh_shell_engine_client:set_checklist_status(U, A, #{}) end, fun(A, _) -> P(A, "/checklist-status") end},
     {get_news,          fun(U, A, _) -> fh_shell_engine_client:get_news(U, A) end, fun(A, _) -> P(A, "/news") end},
     {dismiss_news,      fun(U, A, _) -> fh_shell_engine_client:dismiss_news(U, A, #{}) end, fun(A, _) -> P(A, "/news") end},
     {attach_property,   fun(U, A, _) -> fh_shell_engine_client:attach_property(U, A, #{}) end, fun(A, _) -> P(A, "/properties") end},
     {set_transaction_dates, fun(U, A, B) -> fh_shell_engine_client:set_transaction_dates(U, A, B, #{}) end,
                         fun(A, B) -> P(A, ["/properties/", q(B), "/transaction"]) end},
     {upload_document,   fun(U, A, B) -> fh_shell_engine_client:upload_document(U, A, B, #{}) end,
                         fun(A, B) -> P(A, ["/properties/", q(B), "/documents"]) end},
     {plan_card_summaries, fun(U, A, B) -> fh_shell_engine_client:plan_card_summaries(U, [A, B]) end,
                         fun(A, B) -> {<<"/api/engine/plan-cards">>, iolist_to_binary(["ids=", q(A), ",", q(B)])} end}].

%% Compare what the engine's router will see: the path split on `/` into segments, each
%% percent-decoded, and the query split on `,` the same way. httpc normalizes an encoded
%% unreserved character (`%2E` arrives as `.`), so raw bytes are not the oracle; the
%% segments are.
decoded({Path, Qs}) ->
    {[uri_string:unquote(S) || S <- binary:split(Path, <<"/">>, [global])],
     [uri_string:unquote(S) || S <- binary:split(Qs, <<",">>, [global])]}.

q(Id) -> uri_string:quote(Id).

%% A hostile id: 1-40 characters over hex, separators and the characters that could
%% steer a URL (path, query, fragment, percent, controls, space, backslash, non-ASCII).
%% An id for Expect 2: one in ten a bare dot segment, otherwise hostile text.
gen_id() ->
    case rand:uniform(10) of
        1 -> lists:nth(rand:uniform(2), [<<".">>, <<"..">>]);
        _ -> gen_hostile()
    end.

gen_hostile() ->
    Alpha = "0123456789abcdefABCDEF-./?#%&=:@,;+\\ \t\r\n\0ü",
    L = rand:uniform(40),
    unicode:characters_to_binary([lists:nth(rand:uniform(length(Alpha)), Alpha)
                                  || _ <- lists:seq(1, L)]).

free_port() ->
    {ok, S} = gen_tcp:listen(0, [{ip, {127,0,0,1}}]),
    {ok, Port} = inet:port(S),
    ok = gen_tcp:close(S),
    Port.

card_path(CardId) -> "/api/plan-cards/" ++ binary_to_list(CardId).

drain() ->
    timer:sleep(0),
    All = ets:tab2list(engine_seen),
    ets:delete_all_objects(engine_seen),
    All.

req(Method, Url, Headers, Body) ->
    Request = case Method of
        get -> {Url, Headers};
        _ -> {Url, Headers, "application/json", Body}
    end,
    {ok, {{_, S, _}, _, RespBody}} =
        httpc:request(Method, Request, [{timeout, 10000}, {autoredirect, false}],
                      [{body_format, binary}]),
    {S, RespBody}.

scalar(Sql, Params) ->
    #{rows := [{V}]} = pgo:query(Sql, Params, #{pool => fh_shell_db:pool()}),
    V.

uuid() -> fh_shell_util:uuid4().

expect(true, Msg) -> io:format("PASS  ~s~n", [Msg]);
expect(false, Msg) -> io:format("FAIL  ~s~n", [Msg]), halt(1).
