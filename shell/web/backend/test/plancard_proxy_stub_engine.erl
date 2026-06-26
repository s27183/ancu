-module(plancard_proxy_stub_engine).

%% Stub for the engine's single plan-card resource — GET /api/engine/plan-cards/:id,
%% POST .../messages, POST .../properties (attach), and POST .../properties/:pid/
%% transaction — used by plancard_proxy_smoke (8-S4a + Mode-C Slice 1). The engine's
%% real behaviour (the DAG-walk fill, the kind:qa turn, the Phase-B per-property turn)
%% is already proven by the engine's own seams (real Opus); this stub lets the SHELL
%% test exercise only the shell-new logic — user-JWT auth, the OWNERSHIP gate, the
%% meter gate, and the verbatim relay — in one VM without the dual-`default`-pool
%% clash. One handler, action per route opt. The attach/transaction branches ECHO the
%% forwarded body field + whether a Bearer arrived, so the smoke can prove the request
%% body AND the minted tenant JWT actually travelled through the proxy.

-export([init/2]).

init(Req0, Opts) ->
    Id = cowboy_req:binding(id, Req0),
    {ok, BodyBin, Req1} = read_all(Req0, <<>>),
    {Status, Resp} = case {Opts, cowboy_req:method(Req1)} of
        {[], <<"GET">>} ->
            {200, #{
                <<"plan_card_id">>   => Id,
                <<"blueprint_slug">> => <<"fhb-domestic-au">>,
                <<"intent">>         => <<"owner_occupier">>,
                <<"mode">>           => <<"A">>,
                <<"status">>         => <<"completed">>,
                <<"content">> => #{<<"components">> => #{
                    <<"buyer_profile">> => #{
                        <<"component_id">> => <<"buyer_profile">>,
                        <<"renderer">>     => <<"summary-card">>,
                        <<"fill_path">>    => <<"resolver">>,
                        <<"outcome">>      => #{<<"applicant_count">> => 1,
                                                <<"firb_required_any">> => false}}}}}};
        {[messages], <<"POST">>} ->
            {202, #{<<"plan_card_id">> => Id, <<"turn_id">> => fh_shell_util:uuid4()}};
        {[properties], <<"POST">>} ->
            %% attach: the engine generates property_id (server-side). Echo the
            %% forwarded `state` + the Bearer presence to prove the proxy carried both.
            PC = decode(BodyBin),
            {202, #{<<"plan_card_id">> => Id,
                    <<"property_id">>  => fh_shell_util:uuid4(),
                    <<"turn_id">>      => fh_shell_util:uuid4(),
                    <<"echo_state">>   => maps:get(<<"state">>, PC, null),
                    <<"saw_bearer">>   => saw_bearer(Req1)}};
        {[transaction], <<"POST">>} ->
            %% transaction: echo the :pid (proves the binding travelled) + a date.
            Pid = cowboy_req:binding(pid, Req1),
            Dates = decode(BodyBin),
            {202, #{<<"plan_card_id">>    => Id,
                    <<"property_id">>     => Pid,
                    <<"turn_id">>         => fh_shell_util:uuid4(),
                    <<"echo_settlement">> => maps:get(<<"settlement_date">>, Dates, null)}};
        _ ->
            {405, #{<<"error">> => <<"method_not_allowed">>}}
    end,
    Req = cowboy_req:reply(Status,
        #{<<"content-type">> => <<"application/json">>},
        fh_shell_util:json_encode(Resp), Req1),
    {ok, Req, Opts}.

read_all(Req0, Acc) ->
    case cowboy_req:read_body(Req0) of
        {ok, Data, Req1}   -> {ok, <<Acc/binary, Data/binary>>, Req1};
        {more, Data, Req1} -> read_all(Req1, <<Acc/binary, Data/binary>>)
    end.

decode(<<>>) -> #{};
decode(Bin)  -> fh_shell_util:json_decode(Bin).

saw_bearer(Req) ->
    case cowboy_req:header(<<"authorization">>, Req, undefined) of
        <<"Bearer ", _/binary>> -> true;
        _                       -> false
    end.
