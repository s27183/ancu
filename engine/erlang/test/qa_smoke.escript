#!/usr/bin/env escript
%%! -sname fh_qa_smoke
%%
%% 2c end-to-end smoke — the Q&A message turn over the real /api/engine/* surface.
%% 2c-1 cheap checks (endpoint + error paths, no LLM) + the 2c-3/2c-4 full turn: a real
%% opus Q&A pass with the KB-lookup tool, buffer-then-gate compliance, bilingual
%% text_delta, the audit trail, and glue persistence + reuse on a second turn. Makes
%% REAL opus calls — needs CLAUDE_CODE_OAUTH_TOKEN. Run from engine/erlang:
%%   set -a; source ../../.env; set +a
%%   ENGINE_DATABASE_URL=postgres://engine:engine_dev_pw@localhost:5433/firsthomey_engine?sslmode=disable \
%%   ERL_LIBS=_build/default/lib escript test/qa_smoke.escript

-mode(compile).

main(_) ->
    os:putenv("FH_ENGINE_HTTP_PORT", "8092"),
    {ok, _} = application:ensure_all_started(fh_engine),
    {ok, _} = application:ensure_all_started(inets),
    Base = "http://localhost:8092/api/engine",

    TenantId = fh_engine_util:uuid4(),
    UserId = fh_engine_util:uuid4(),
    {Pub, Priv} = crypto:generate_key(eddsa, ed25519),
    ok = fh_engine_store:upsert_tenant(TenantId, <<"qa-smoke-tenant">>),
    ok = fh_engine_store:add_signing_key(TenantId, <<"ed25519">>, base64:encode(Pub)),
    Token = mint(TenantId, UserId, Priv),
    Auth = {"authorization", "Bearer " ++ binary_to_list(Token)},

    %% --- seed a FILLED Mode-A plan card directly (re-grounding for the Q&A turn) ---
    {ok, ProfileId} = fh_engine_store:create_profile(TenantId, UserId,
        #{<<"onboarding">> => #{<<"state">> => <<"NSW">>}}),
    Content = #{<<"components">> => #{
        <<"eligibility">> => #{<<"outcome">> => #{
            <<"state">> => <<"NSW">>, <<"first_home_buyer">> => true,
            <<"scheme_stack">> => [<<"first_home_guarantee">>, <<"fhbas">>]}},
        <<"cash_position">> => #{<<"outcome">> => #{
            <<"target_price_range">> => [600000, 700000],
            <<"estimated_transfer_duty">> => 0}}}},
    {ok, PlanCardId} = fh_engine_store:create_plan_card(
        TenantId, ProfileId, <<"fhb-domestic-au">>, <<"owner_occupier">>, <<"A">>, Content),
    io:format("seeded plan_card_id=~s~n", [PlanCardId]),
    Url = Base ++ "/plan-cards/" ++ binary_to_list(PlanCardId) ++ "/messages",

    %% --- 2c-1 cheap checks (no LLM): error paths ---
    {400, _} = req(post, Url, [Auth], fh_engine_util:json_encode(#{<<"message">> => <<>>})),
    Bogus = binary_to_list(fh_engine_util:uuid4()),
    {404, _} = req(post, Base ++ "/plan-cards/" ++ Bogus ++ "/messages",
                   [Auth], fh_engine_util:json_encode(#{<<"message">> => <<"hi">>})),
    {401, _} = req(post, Url, [], fh_engine_util:json_encode(#{<<"message">> => <<"hi">>})),
    io:format("error paths (400/404/401) OK~n"),

    %% --- the real Q&A turn ---
    Q1 = fh_engine_util:json_encode(#{
        <<"message">> => <<"What is the First Home Guarantee, and does it cost extra?">>}),
    {202, R1} = req(post, Url, [Auth], Q1),
    #{<<"turn_id">> := _} = fh_engine_util:json_decode(R1),
    EvUrl = Base ++ "/plan-cards/" ++ binary_to_list(PlanCardId) ++ "/events",
    {Types, Max1} = collect_sse(EvUrl, Auth, 0),
    io:format("event sequence: ~p~n", [Types]),

    expect(hd(Types) =:= <<"turn_started">>, "turn_started first"),
    expect(lists:last(Types) =:= <<"turn_completed">>, "turn_completed last (terminal)"),
    expect(count(<<"compliance_gate">>, Types) =:= 3, "3 compliance_gate (firb·asic·aml)"),
    expect(lists:member(<<"text_delta">>, Types), "answer emitted as text_delta"),
    expect(lists:member(<<"usage">>, Types), "usage metered"),
    %% buffer-then-gate: every compliance_gate precedes every text_delta.
    expect(last_index(<<"compliance_gate">>, Types) < first_index(<<"text_delta">>, Types),
           "buffer-then-gate: gates before the answer is emitted"),

    %% --- the answer was emitted bilingual {vi, en} (text_delta lang tags) ---
    Langs = lists:sort(scalar_list(
        "SELECT payload_jsonb->>'lang' FROM plan_card_events "
        "WHERE plan_card_id = $1 AND type = 'text_delta' ORDER BY 1", [PlanCardId])),
    expect(Langs =:= [<<"en">>, <<"vi">>], "text_delta carries both vi and en"),

    %% --- the audit trail: 3 rows for the q_and_a producer, all clear (Mode-A healthy) ---
    QaAudit = scalar("SELECT count(*) FROM audit_events WHERE plan_card_id = $1 "
                     "AND component_id = 'q_and_a'", [PlanCardId]),
    expect(QaAudit =:= 3, "3 audit_events rows for q_and_a (firb·asic·aml)"),
    AsicHeld = scalar("SELECT count(*) FROM audit_events WHERE plan_card_id = $1 "
                      "AND compliance_jsonb->>'gate' = 'asic' "
                      "AND compliance_jsonb->>'detail' = 'decision_support_boundary_held'",
                      [PlanCardId]),
    expect(AsicHeld =:= 1, "ASIC attested decision_support_boundary_held on the answer"),

    %% --- glue persisted (one session_turn for this card/user) ---
    Glue1 = scalar("SELECT count(*) FROM session_turns st JOIN sessions s "
                   "ON s.session_id = st.session_id WHERE s.plan_card_id = $1", [PlanCardId]),
    expect(Glue1 =:= 1, "first Q&A turn persisted one glue pair"),

    %% --- a SECOND message: completes, and a second glue pair lands (the turn read the
    %%     prior glue via read_glue; we assert the turn ran + glue accumulated) ---
    Q2 = fh_engine_util:json_encode(#{<<"message">> => <<"And what deposit would I need?">>}),
    {202, _} = req(post, Url, [Auth], Q2),
    %% Reconnect with Last-Event-ID = turn-1's max, so the stream waits for turn 2's live
    %% events instead of closing on turn 1's replayed terminal.
    {Types2, _} = collect_sse(EvUrl, Auth, Max1),
    expect(lists:last(Types2) =:= <<"turn_completed">>, "second Q&A turn completes"),
    Glue2 = scalar("SELECT count(*) FROM session_turns st JOIN sessions s "
                   "ON s.session_id = st.session_id WHERE s.plan_card_id = $1", [PlanCardId]),
    expect(Glue2 =:= 2, "second Q&A turn accumulated a second glue pair"),

    io:format("~n==== QA SMOKE (2c end-to-end): ALL ASSERTIONS PASSED ====~n"),
    halt(0).

%% --- helpers ----------------------------------------------------------------

mint(TenantId, UserId, Priv) ->
    Now = erlang:system_time(second),
    fh_engine_auth:sign(#{<<"tenant_id">> => TenantId, <<"user_id">> => UserId,
                          <<"iat">> => Now, <<"exp">> => Now + 3600}, Priv).

req(Method, Url, Headers, Body) ->
    Request = case Method of
        get -> {Url, Headers};
        post -> {Url, Headers, "application/json", Body}
    end,
    {ok, {{_, Status, _}, _, Resp}} =
        httpc:request(Method, Request, [], [{body_format, binary}]),
    {Status, Resp}.

%% Returns {OrderedTypes, MaxEventId}. LastEventId > 0 → reconnect past that point.
collect_sse(Url, Auth, LastEventId) ->
    Headers = [Auth | case LastEventId of
                          0 -> [];
                          N -> [{"last-event-id", integer_to_list(N)}]
                      end],
    {ok, ReqId} = httpc:request(get, {Url, Headers}, [],
                                [{sync, false}, {stream, self}]),
    parse_event_types(sse_loop(ReqId, <<>>)).

sse_loop(ReqId, Acc) ->
    receive
        {http, {ReqId, stream_start, _H}} -> sse_loop(ReqId, Acc);
        {http, {ReqId, stream, Chunk}} -> sse_loop(ReqId, <<Acc/binary, Chunk/binary>>);
        {http, {ReqId, stream_end, _H}} -> Acc;
        {http, {ReqId, {error, Reason}}} -> error({sse_error, Reason})
    after 60000 ->   %% > the 15s keepalive cadence; an opus turn can be slow
        error(sse_timeout)
    end.

parse_event_types(Raw) ->
    Frames = binary:split(Raw, <<"\n\n">>, [global]),
    Pairs = lists:filtermap(fun parse_frame/1, Frames),
    {_, Rev, Max} = lists:foldl(fun({Id, Type}, {Seen, Acc, M}) ->
        M1 = max(M, Id),
        case sets:is_element(Id, Seen) of
            true -> {Seen, Acc, M1};
            false -> {sets:add_element(Id, Seen), [Type | Acc], M1}
        end
    end, {sets:new(), [], 0}, Pairs),
    {lists:reverse(Rev), Max}.

parse_frame(Frame) ->
    case re:run(Frame, <<"event: (.+)">>, [{capture, [1], binary}]) of
        {match, [Type]} ->
            Id = case re:run(Frame, <<"id: (\\d+)">>, [{capture, [1], binary}]) of
                     {match, [I]} -> binary_to_integer(I);
                     nomatch -> 0
                 end,
            {true, {Id, Type}};
        nomatch -> false
    end.

count(X, L) -> length([Y || Y <- L, Y =:= X]).
first_index(X, L) -> idx(X, L, 1).
last_index(X, L) -> length(L) + 1 - idx(X, lists:reverse(L), 1).
idx(X, [X | _], I) -> I;
idx(X, [_ | T], I) -> idx(X, T, I + 1);
idx(_, [], _) -> 0.

scalar(SQL, Params) ->
    #{rows := [{Val}]} = pgo:query(SQL, Params),
    Val.

scalar_list(SQL, Params) ->
    #{rows := Rows} = pgo:query(SQL, Params),
    [V || {V} <- Rows].

expect(true, _Msg) -> ok;
expect(false, Msg) ->
    io:format("ASSERTION FAILED: ~s~n", [Msg]),
    halt(1).
