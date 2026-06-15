-module(plancard_proxy_stub_engine).

%% Stub for the engine's single plan-card resource — GET /api/engine/plan-cards/:id
%% and POST .../messages — used by plancard_proxy_smoke (8-S4a). The engine's real
%% behaviour (the DAG-walk fill, the kind:qa turn) is already proven by the engine's
%% seam_smoke.escript (real Opus); this stub lets the SHELL test exercise only the
%% shell-new logic — user-JWT auth, the OWNERSHIP gate, and the verbatim relay — in
%% one VM without the dual-`default`-pool clash. One handler, action per route opt
%% ([] = read -> 200 with a tiny canned projection, [messages] = ask -> 202).

-export([init/2]).

init(Req0, Opts) ->
    Id = cowboy_req:binding(id, Req0),
    {Status, Resp} = case {Opts, cowboy_req:method(Req0)} of
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
        _ ->
            {405, #{<<"error">> => <<"method_not_allowed">>}}
    end,
    Req = cowboy_req:reply(Status,
        #{<<"content-type">> => <<"application/json">>},
        fh_shell_util:json_encode(Resp), Req0),
    {ok, Req, Opts}.
