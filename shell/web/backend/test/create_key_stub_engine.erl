-module(create_key_stub_engine).

%% A stub for the engine's POST /api/engine/plan-cards, used by create_key_smoke
%% (behavior 97): a canned 202 with fresh ids, after 300 ms so two concurrent creates
%% overlap at the shell, counting each accepted create in the smoke's ets table
%% `stub_creates` — the smoke asserts how many plans the engine was asked to make.

-export([init/2]).

init(Req0, State) ->
    {ok, _Body, Req1} = read_body(Req0, <<>>),
    timer:sleep(300),
    ets:update_counter(stub_creates, n, 1),
    Resp = #{<<"plan_card_id">> => fh_shell_util:uuid4(),
             <<"turn_id">>      => fh_shell_util:uuid4()},
    Req = cowboy_req:reply(202, #{<<"content-type">> => <<"application/json">>},
                           fh_shell_util:json_encode(Resp), Req1),
    {ok, Req, State}.

read_body(Req0, Acc) ->
    case cowboy_req:read_body(Req0) of
        {ok, Data, Req1}   -> {ok, <<Acc/binary, Data/binary>>, Req1};
        {more, Data, Req1} -> read_body(Req1, <<Acc/binary, Data/binary>>)
    end.
