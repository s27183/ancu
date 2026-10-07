#!/usr/bin/env escript
%%! -sname fh_state_projection_smoke
%%
%% Smoke for the projection-state derivation (eligibility-resolution.md 2026-06-17 / G4):
%% state-specific schemes resolve from the SUBURB being planned (target_zone via the
%% suburbs table), NOT the map browse-filter onboarding.state. Asserts the precedence
%% (zone → explicit-real-state → undefined, "ALL" never gates) AND that a zone-only card
%% (state="ALL") yields the full VIC scheme stack — the East-Melbourne fix. Needs the
%% suburbs table populated (build adapters) + the engine DB. Run from engine/erlang:
%%
%%   ENGINE_DATABASE_URL=postgres://engine:engine_dev_pw@localhost:5433/ancu_engine?sslmode=disable \
%%     ERL_LIBS=_build/default/lib escript test/state_projection_smoke.escript

-mode(compile).

main(_) ->
    os:putenv("FH_ENGINE_HTTP_PORT", "8094"),
    {ok, _} = application:ensure_all_started(fh_engine),
    io:format("state-projection smoke (zone -> state; ALL never gates)~n~n"),

    %% Precedence cases. East Melbourne is VIC in the suburbs table (verified unique).
    PS = fun(O) -> fh_engine_store:projection_state(O) end,
    C1 = check("zone=East Melbourne + state=ALL -> VIC",
               PS(#{<<"target_zone">> => [<<"East Melbourne">>], <<"state">> => <<"ALL">>}),
               <<"VIC">>),
    C2 = check("explicit state=VIC, no zone -> VIC (no-DB path)",
               PS(#{<<"state">> => <<"VIC">>}), <<"VIC">>),
    C3 = check("state=ALL, no zone -> undefined (ALL never gates)",
               PS(#{<<"state">> => <<"ALL">>}), undefined),
    C4 = check("empty onboarding -> undefined", PS(#{}), undefined),

    %% The integration: a zone-only card (the East-Melbourne shape) gets the VIC stack.
    Args = #{onboarding => #{<<"target_zone">> => [<<"East Melbourne">>], <<"state">> => <<"ALL">>}},
    Up = #{<<"profile">> => #{<<"target_price_range">> => [600000, 750000], <<"applicants">> => [#{}]}},
    {O, _, _} = fh_engine_eligibility:fill(Args, Up),
    Schemes = maps:get(<<"applicable_schemes">>, O),
    Duty = [S || S <- Schemes, maps:get(<<"role">>, S) =:= <<"stamp_duty_concession">>],
    C5 = check("zone-only card has a VIC duty concession with a money_range benefit",
               case Duty of
                   [D | _] -> is_list(maps:get(<<"benefit_value">>, D));
                   []      -> false
               end, true),

    Results = [C1, C2, C3, C4, C5],
    io:format("~n================================================================~n"),
    case [R || R <- Results, R =:= fail] of
        [] -> io:format("PASS — all ~p projection-state checks green~n", [length(Results)]), halt(0);
        F  -> io:format("FAIL — ~p/~p failed~n", [length(F), length(Results)]), halt(1)
    end.

check(Label, Got, Expected) ->
    case Got =:= Expected of
        true  -> io:format("  PASS   ~ts = ~p~n", [Label, Got]), pass;
        false -> io:format("  FAIL   ~ts = ~p, expected ~p~n", [Label, Got, Expected]), fail
    end.
