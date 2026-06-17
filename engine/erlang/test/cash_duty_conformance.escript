#!/usr/bin/env escript
%%! -sname fh_cash_duty_conformance
%%
%% Conformance suite for fh_engine_cash (mechanism B — stamp-duty formula code)
%% against the executable spec tests/cash_duty_eval.py. Loads the SAME materialized
%% artifact the engine loads (priv/kb/artifact.json via fh_engine_kb) and runs the
%% spec's anchors through the Erlang implementation — asserting the figures match
%% the official revenue-office calculator output to the dollar. The two
%% implementations (Python spec + Erlang fh_engine_cash) stay locked to each other
%% AND to the regulated ground truth. See docs/architecture/stamp-duty-concession-mechanics.md.
%%
%% Run from engine/erlang with the build libs on the path (no Postgres needed):
%%   ERL_LIBS=_build/default/lib escript test/cash_duty_conformance.escript

-mode(compile).

main(_) ->
    ok = fh_engine_kb:load(),
    io:format("cash-duty conformance — fh_engine_cash vs the official figures~n~n"),
    K = [run_kernel(C) || C <- kernel_cases()],
    S = [run_stamp(C) || C <- stamp_cases()],
    R = [run_reg(C) || C <- reg_cases()],
    Fails = [X || X <- K ++ S ++ R, X =:= fail],
    io:format("~n================================================================~n"),
    case Fails of
        [] ->
            io:format("PASS — all ~p cash anchors match (~p kernel + ~p stamp_duty + ~p registration)~n",
                      [length(K) + length(S) + length(R), length(K), length(S), length(R)]),
            halt(0);
        _ ->
            io:format("FAIL — ~p anchor(s) mismatched~n", [length(Fails)]),
            halt(1)
    end.

%% --- kernel cases (mirror cash_duty_eval.py KERNEL_CASES) --------------------
%% {ScaleName, Value, ExpectedDuty} — expected rounded to the dollar (round half up).

kernel_cases() ->
    [{<<"nsw_standard_scale">>,        800000,  30412},
     {<<"nsw_standard_scale">>,        1000,    20},      %% $20 minimum applies
     {<<"vic_general_scale">>,         700000,  37070},
     {<<"vic_general_scale">>,         1500000, 82500},   %% flat-on-total quirk
     {<<"qld_standard_scale">>,        600000,  20025},
     {<<"qld_home_concession_scale">>, 730000,  18700},
     {<<"qld_home_concession_scale">>, 700000,  17350}].

run_kernel({Scale, V, Expected}) ->
    Got = rfup(fh_engine_cash:duty(V, Scale)),
    case Got =:= Expected of
        true  -> io:format("  PASS   duty(~s, ~p) = ~p~n", [Scale, V, Got]), pass;
        false -> io:format("  FAIL   duty(~s, ~p) = ~p, expected ~p~n",
                           [Scale, V, Got, Expected]), fail
    end.

%% --- stamp_duty cases (mirror cash_duty_eval.py DUTY_CASES) ------------------
%% {State, HasConcession, Value, Before, Saving, After}

stamp_cases() ->
    [{<<"NSW">>, true,  850000,  32662, 22809, 9853},
     {<<"NSW">>, true,  900000,  34912, 15206, 19706},
     {<<"NSW">>, true,  800000,  30412, 30412, 0},
     {<<"NSW">>, true,  750000,  28162, 28162, 0},
     {<<"NSW">>, true,  1000000, 39412, 0,     39412},
     {<<"NSW">>, false, 850000,  32662, 0,     32662},
     {<<"VIC">>, true,  700000,  37070, 12357, 24713},
     {<<"VIC">>, true,  650000,  34070, 22713, 11357},
     {<<"VIC">>, true,  600000,  31070, 31070, 0},
     {<<"VIC">>, true,  750000,  40070, 0,     40070},
     {<<"QLD">>, true,  730000,  25875, 19320, 6555},
     {<<"QLD">>, true,  700000,  24525, 24525, 0},
     {<<"QLD">>, true,  800000,  29025, 7175,  21850},
     {<<"QLD">>, true,  850000,  31275, 0,     31275}].

run_stamp({State, HasConc, V, Before, Saving, After}) ->
    Sd = fh_engine_cash:stamp_duty(State, HasConc, V),
    Got = {maps:get(<<"before_concession">>, Sd),
           maps:get(<<"concession_applied">>, Sd),
           maps:get(<<"after_concession">>, Sd)},
    Want = {Before, Saving, After},
    case Got =:= Want of
        true  -> io:format("  PASS   stamp_duty(~s, ~p, ~p) = ~p~n", [State, HasConc, V, Got]),
                 pass;
        false -> io:format("  FAIL   stamp_duty(~s, ~p, ~p) = ~p, expected ~p~n",
                           [State, HasConc, V, Got, Want]), fail
    end.

%% --- registration cases (mirror cash_duty_eval.py REG_CASES) ----------------
%% {State, Value, ExpectedTotalDollars} — transfer + mortgage registration, whole
%% dollars, against each registry's published schedule (REGULATED — Decision 9).

reg_cases() ->
    [{<<"NSW">>, 600000,  351},    %% flat $351.40 → $351 (price-independent)
     {<<"NSW">>, 850000,  351},    %% same flat fee at any price
     {<<"VIC">>, 700000,  1865},   %% 1739.50 + 125.70 = 1865.20
     {<<"VIC">>, 2000000, 3737},   %% transfer capped 3611 + 125.70 (proves the cap)
     {<<"QLD">>, 600000,  2452},   %% 2203.56 + 248.04 = 2451.60
     {<<"QLD">>, 180000,  496},    %% at threshold: 248.04 + 248.04
     {<<"QLD">>, 185000,  543}].   %% $5k over → 1 increment "or part" (round-up)

run_reg({State, V, Expected}) ->
    Got = fh_engine_cash:registration_total(State, V),
    case Got =:= Expected of
        true  -> io:format("  PASS   registration_total(~s, ~p) = ~p~n", [State, V, Got]), pass;
        false -> io:format("  FAIL   registration_total(~s, ~p) = ~p, expected ~p~n",
                           [State, V, Got, Expected]), fail
    end.

%% round half up to whole dollars — identical to fh_engine_cash:dollars/1 and the
%% Python spec's _dollars (duty is always >= 0 here).
rfup(X) when X =< 0 -> 0;
rfup(X)            -> trunc(X + 0.5).
