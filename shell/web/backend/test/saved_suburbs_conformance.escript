#!/usr/bin/env escript
%%! -sname saved_suburbs_conformance
%% Behavior 84: an older plan's title seeds a saved suburb only when it names exactly
%% one suburb; anything else is skipped, never guessed (fh_shell_h_saved_suburbs).
%% Offline: the pure seed_rows/2 against a fixture national list.
main(_) ->
    S = fun(Sal, Name, St) -> #{<<"sal_code">> => Sal, <<"name">> => Name, <<"state">> => St} end,
    Suburbs = [S(<<"SAL10660">>, <<"Cabramatta">>, <<"NSW">>),
               S(<<"SAL20001">>, <<"Richmond (Vic.)">>, <<"VIC">>),
               S(<<"SAL10002">>, <<"Twin">>, <<"NSW">>),
               S(<<"SAL30003">>, <<"Twin">>, <<"QLD">>)],
    Cases = [
        {"one match is seeded",
         [<<"Cabramatta">>], {[{<<"SAL10660">>, <<"Cabramatta">>, <<"NSW">>}], []}},
        {"a title naming no suburb is skipped",
         [<<"Richmond">>], {[], [<<"Richmond">>]}},
        {"a title naming two suburbs is skipped",
         [<<"Twin">>], {[], [<<"Twin">>]}},
        {"mixed, order kept",
         [<<"Cabramatta">>, <<"Nowhere">>, <<"Richmond (Vic.)">>],
         {[{<<"SAL10660">>, <<"Cabramatta">>, <<"NSW">>},
           {<<"SAL20001">>, <<"Richmond (Vic.)">>, <<"VIC">>}], [<<"Nowhere">>]}},
        {"no titles, nothing", [], {[], []}}
    ],
    Fails = [Name || {Name, Titles, Want} <- Cases,
                     fh_shell_h_saved_suburbs:seed_rows(Titles, Suburbs) =/= Want],
    [io:format("FAIL ~s~n", [N]) || N <- Fails],
    io:format("saved_suburbs_conformance: ~B/~B~n", [length(Cases) - length(Fails), length(Cases)]),
    halt(case Fails of [] -> 0; _ -> 1 end).
