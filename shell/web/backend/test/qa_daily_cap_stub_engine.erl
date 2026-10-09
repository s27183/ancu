%% Stub engine for qa_daily_cap_smoke (behavior 36): POST /api/engine/plan-cards/:id/
%% messages answers with the status the smoke last set (persistent_term qa_stub_status,
%% default 202) and counts every call it receives (counters ref qa_stub_calls), so the
%% smoke can prove a capped ask never reached the engine.
-module(qa_daily_cap_stub_engine).
-behaviour(cowboy_handler).
-export([init/2]).

init(Req0, Opts) ->
    counters:add(persistent_term:get(qa_stub_calls), 1, 1),
    {ok, _Body, Req1} = cowboy_req:read_body(Req0),
    Status = persistent_term:get(qa_stub_status, 202),
    Resp = case Status of
        202 -> <<"{\"turn_id\":\"00000000-0000-4000-8000-000000000001\"}">>;
        409 -> <<"{\"error\":\"turn_in_flight\"}">>;
        _   -> <<"{\"error\":\"internal\"}">>
    end,
    {ok, cowboy_req:reply(Status, #{<<"content-type">> => <<"application/json">>},
                          Resp, Req1), Opts}.
