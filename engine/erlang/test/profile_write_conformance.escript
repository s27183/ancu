#!/usr/bin/env escript
%%! -sname fh_profile_write
%%
%% No-PG conformance for IC4 — the profile-write VALIDATION (fh_engine_h_profile:
%% validate_financials/1, the HARD fail-closed input contract). The handler's write +
%% profile-scoped refresh need Postgres (exercised end-to-end in IC6 / seam_smoke); the
%% validator is pure, so its accept/reject grid is unit-checkable here.
%%
%% Run from engine/erlang:
%%   ERL_LIBS=_build/default/lib escript test/profile_write_conformance.escript

-mode(compile).

main(_) ->
    io:format("IC4 profile-write validation — validate_financials/1, pure~n~n"),
    R = accept_checks() ++ reject_checks(),
    io:format("~n================================================================~n"),
    case [X || X <- R, X =:= fail] of
        [] -> io:format("PASS — the financials write contract holds (canonical, fail-closed)~n"), halt(0);
        F  -> io:format("FAIL — ~p check(s) failed~n", [length(F)]), halt(1)
    end.

accept_checks() ->
    io:format("accept — canonical shapes~n"),
    Full = #{<<"income">> => #{<<"assessable_income">> => 95000,
                               <<"foreign_sourced_component">> => 0},
             <<"debts">>  => #{<<"hecs_balance">> => 20000,
                               <<"credit_card_limits_total">> => 10000,
                               <<"personal_loans_balance">> => 0,
                               <<"car_loan_balance">> => 0,
                               <<"buy_now_pay_later_balance">> => 0}},
    [check("full canonical income+debts → ok", v(Full), ok),
     check("empty object (clear financials) → ok", v(#{}), ok),
     check("income-only → ok", v(#{<<"income">> => #{<<"assessable_income">> => 80000}}), ok),
     check("debts-only → ok", v(#{<<"debts">> => #{<<"hecs_balance">> => 5000}}), ok),
     check("zero is a valid non-negative figure → ok",
           v(#{<<"income">> => #{<<"assessable_income">> => 0}}), ok)].

reject_checks() ->
    io:format("~nreject — fail-closed~n"),
    [check("non-map body → {error,not_a_map}",
           v(<<"nope">>), {error, not_a_map}),
     check("unknown group (savings_and_deposit deferred) → unknown_group",
           tag(v(#{<<"savings_and_deposit">> => #{}})), unknown_group),
     check("the OLD ungrounded income field (primary_taxable_income) is rejected",
           tag(v(#{<<"income">> => #{<<"primary_taxable_income">> => 95000}})), unknown_field),
     check("unknown debt field → unknown_field",
           tag(v(#{<<"debts">> => #{<<"mortgage_balance">> => 1}})), unknown_field),
     check("a negative figure → non_negative_number_required",
           tag(v(#{<<"income">> => #{<<"assessable_income">> => -1}})),
           non_negative_number_required),
     check("a non-number figure → non_negative_number_required",
           tag(v(#{<<"debts">> => #{<<"hecs_balance">> => <<"lots">>}})),
           non_negative_number_required),
     check("income not an object → group_not_a_map",
           tag(v(#{<<"income">> => 5})), group_not_a_map)].

v(HF) -> fh_engine_h_profile:validate_financials(HF).

%% the error's leading tag, for shape-level assertions.
tag({error, T}) when is_atom(T) -> T;
tag({error, T}) when is_tuple(T) -> element(1, T);
tag(Other) -> {unexpected, Other}.

check(Label, Got, Want) ->
    case Got =:= Want of
        true  -> io:format("  PASS   ~ts~n", [Label]), pass;
        false -> io:format("  FAIL   ~ts = ~p, expected ~p~n", [Label, Got, Want]), fail
    end.
