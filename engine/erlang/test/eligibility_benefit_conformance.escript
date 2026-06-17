#!/usr/bin/env escript
%%! -sname fh_eligibility_benefit_conformance
%%
%% Conformance suite for fh_engine_eligibility base-benefit quantification (Decision 8)
%% against the executable spec tests/eligibility_benefit_eval.py. Loads the SAME
%% materialized artifact the engine loads (priv/kb/artifact.json) and runs
%% fh_engine_eligibility:fill/2 for the named cases, asserting each applicable scheme's
%% benefit_value money_range + total_benefit_value match the spec's anchors to the dollar.
%% The duty endpoints trace to the official figures locked in cash_duty_eval (one computer
%% per figure — eligibility surfaces the shared fh_engine_cash duty saving). See
%% docs/architecture/eligibility-resolution.md §8.
%%
%% Run from engine/erlang with the build libs on the path (no Postgres needed):
%%   ERL_LIBS=_build/default/lib escript test/eligibility_benefit_conformance.escript

-mode(compile).

main(_) ->
    ok = fh_engine_kb:load(),
    io:format("eligibility base-benefit conformance — fh_engine_eligibility vs the spec~n~n"),
    Results = lists:flatten([run_case(C) || C <- cases()]),
    Fails = [R || R <- Results, R =:= fail],
    io:format("~n================================================================~n"),
    case Fails of
        [] ->
            io:format("PASS — all ~p benefit checks match the spec (duty + FHG LMI + FHOG + total)~n",
                      [length(Results)]),
            halt(0);
        _ ->
            io:format("FAIL — ~p/~p benefit checks failed~n", [length(Fails), length(Results)]),
            halt(1)
    end.

%% (state, [lo,hi], [{role|total, expected_money_range|null}])
cases() ->
    [{<<"VIC">>, [600000, 750000],
      [{<<"deposit_guarantee">>,     [14250, 28500]},
       {<<"stamp_duty_concession">>, [0, 31070]},
       {<<"grant">>,                 [0, 10000]},
       {<<"deposit_savings">>,       null},
       {<<"shared_equity">>,         null},
       {total,                       [14250, 69570]}]},
     {<<"NSW">>, [750000, 900000],
      [{<<"deposit_guarantee">>,     [17813, 34200]},
       {<<"stamp_duty_concession">>, [15206, 28162]},
       {<<"grant">>,                 [0, 10000]},
       {<<"deposit_savings">>,       null},
       {<<"shared_equity">>,         null},
       {total,                       [33019, 72362]}]}].

run_case({State, Range, Checks}) ->
    Args = #{onboarding => #{<<"state">> => State}},
    Upstream = #{<<"profile">> => #{<<"target_price_range">> => Range,
                                    <<"applicants">> => [#{}]}},
    {Outcome, _Renderer, _Kb} = fh_engine_eligibility:fill(Args, Upstream),
    ByRole = by_role(maps:get(<<"applicable_schemes">>, Outcome)),
    Total = maps:get(<<"total_benefit_value">>, Outcome),
    [check(State, Key, Expected, actual(Key, ByRole, Total)) || {Key, Expected} <- Checks].

actual(total, _ByRole, Total)   -> Total;
actual(Role, ByRole, _Total)    -> maps:get(Role, ByRole, missing).

by_role(Schemes) ->
    maps:from_list([{maps:get(<<"role">>, S), maps:get(<<"benefit_value">>, S)} || S <- Schemes]).

check(State, Key, Expected, Got) ->
    case Got =:= Expected of
        true ->
            io:format("  PASS   ~ts ~p = ~p~n", [State, Key, Got]),
            pass;
        false ->
            io:format("  FAIL   ~ts ~p = ~p, expected ~p~n", [State, Key, Got, Expected]),
            fail
    end.
