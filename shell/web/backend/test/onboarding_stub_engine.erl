-module(onboarding_stub_engine).

%% A stub for the engine's POST /api/engine/plan-cards, used by onboarding_smoke
%% (8-S3a). The engine's acceptance of the onboarding body + the real base turn is
%% already proven end-to-end by the engine's seam_smoke.escript (real Opus); this
%% stub lets the SHELL test exercise only the shell-new logic — user-JWT auth, the
%% plan_card_views insert, and the relay — in ONE VM without the dual-`default`-pool
%% clash (booting the real engine app would take the only `default` pgo pool, and
%% the shell needs that pool for its own DB write). Returns a canned 202 with fresh
%% ids; a sentinel state "ZZ" yields a 400 so the test can prove a non-202 relays
%% through verbatim.

-export([init/2]).

init(Req0, State) ->
    {ok, Body, Req1} = read_body(Req0, <<>>),
    Params = case Body of
        <<>> -> #{};
        _    -> fh_shell_util:json_decode(Body)
    end,
    {Status, Resp} = case maps:get(<<"state">>, Params, undefined) of
        <<"ZZ">> ->
            {400, #{<<"error">> => <<"invalid_state">>}};
        _ ->
            {202, #{<<"plan_card_id">> => fh_shell_util:uuid4(),
                    <<"turn_id">>      => fh_shell_util:uuid4()}}
    end,
    Req = cowboy_req:reply(Status,
        #{<<"content-type">> => <<"application/json">>},
        fh_shell_util:json_encode(Resp), Req1),
    {ok, Req, State}.

read_body(Req0, Acc) ->
    case cowboy_req:read_body(Req0) of
        {ok, Data, Req1}   -> {ok, <<Acc/binary, Data/binary>>, Req1};
        {more, Data, Req1} -> read_body(Req1, <<Acc/binary, Data/binary>>)
    end.
