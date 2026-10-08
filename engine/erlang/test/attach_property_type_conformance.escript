#!/usr/bin/env escript
%%! -sname fh_attach_property_type_conformance
%%
%% Behavior 26 (#32): the attach gate fh_engine_h_attach_property:validate_card/2 refuses a
%% property_type the blueprint's compiled property_fit outcome enum cannot hold, naming the
%% allowed types, and accepts one it can. Loads the real artifact (no Postgres). Run from
%% engine/erlang:
%%   ERL_LIBS=_build/default/lib escript test/attach_property_type_conformance.escript

-mode(compile).

-define(SLUG, <<"investor-domestic-au">>).

main(_) ->
    ok = fh_engine_kb:load(),
    Card = fun(T) -> #{<<"price">> => 650000, <<"state">> => <<"VIC">>,
                       <<"suburb">> => <<"Footscray">>, <<"property_type">> => T} end,
    Refused = [<<"dual_occupancy">>, <<"nrass">>, <<"vacant_land">>, <<"foo">>],
    Accepted = [<<"established_house">>, <<"established_apartment">>, <<"new_house">>,
                <<"new_apartment">>, <<"off_the_plan">>, <<"house_and_land">>],
    R = [refused(T, fh_engine_h_attach_property:validate_card(?SLUG, Card(T))) || T <- Refused]
     ++ [accepted(T, fh_engine_h_attach_property:validate_card(?SLUG, Card(T))) || T <- Accepted],
    Fails = [X || X <- R, X =:= fail],
    io:format("~n"),
    case Fails of
        [] -> io:format("PASS — all ~p attach property_type anchors hold~n", [length(R)]), halt(0);
        _  -> io:format("FAIL — ~p anchor(s) mismatched~n", [length(Fails)]), halt(1)
    end.

refused(T, {error, <<"property_type must be one of ", Rest/binary>> = Msg}) ->
    case binary:match(Rest, <<"established_house">>) of
        nomatch -> io:format("FAIL ~s: message lacks the allowed types: ~s~n", [T, Msg]), fail;
        _       -> io:format("ok   ~s refused: ~s~n", [T, Msg]), pass
    end;
refused(T, Other) ->
    io:format("FAIL ~s: expected refusal, got ~p~n", [T, Other]), fail.

accepted(_T, ok) -> pass;
accepted(T, Other) ->
    io:format("FAIL ~s: expected ok, got ~p~n", [T, Other]), fail.
