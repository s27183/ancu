#!/usr/bin/env escript
%%! -sname fx_conformance
%% Behavior 123: the RBA feed yields VND and USD for one date, or nothing — a feed missing
%% either currency, with two dates, a non-number or an entity is refused, never guessed
%% (fh_shell_h_fx:parse/1). Offline: the reconstructed fixture and edits of it.
main(_) ->
    {ok, Feed} = file:read_file("test/fixtures/rba-cb-exchange-rates.xml"),
    Sub = fun(From, To) -> binary:replace(Feed, From, To) end,
    Want = {ok, #{date => <<"2026-10-16">>,
                  rates => #{<<"VND">> => <<"17970">>, <<"USD">> => <<"0.6947">>},
                  source => <<"https://www.rba.gov.au/statistics/frequency/exchange-rates.html">>}},
    Refused = fun({error, _}) -> true; (_) -> false end,
    Cases = [
        {"the fixture reads VND 17970, USD 0.6947 on 2026-10-16",
         Feed, fun(R) -> R =:= Want end},
        {"no VND item is refused",
         Sub(<<"<cb:targetCurrency>VND">>, <<"<cb:targetCurrency>EUR">>), Refused},
        {"two dates are refused",
         binary:replace(Feed, <<"<cb:period>2026-10-16">>, <<"<cb:period>2026-10-15">>), Refused},
        {"a value that is not a number is refused",
         Sub(<<"<cb:value>17970">>, <<"<cb:value>n/a">>), Refused},
        {"a zero value is refused",
         Sub(<<"<cb:value>0.6947">>, <<"<cb:value>0.0000">>), Refused},
        {"an entity is refused",
         <<"<?xml version=\"1.0\"?><!DOCTYPE a [<!ENTITY x \"y\">]><a>&x;</a>">>, Refused},
        {"an HTML error page is refused",
         <<"<html><body>Service unavailable</body></html>">>, Refused},
        {"not XML is refused", <<"Service unavailable">>, Refused}
    ],
    Fails = [Name || {Name, Input, Ok} <- Cases, not Ok(fh_shell_h_fx:parse(Input))],
    [io:format("FAIL ~s: ~p~n", [N, fh_shell_h_fx:parse(I)]) || {N, I, _} <- Cases, lists:member(N, Fails)],
    io:format("fx_conformance: ~B/~B~n", [length(Cases) - length(Fails), length(Cases)]),
    halt(case Fails of [] -> 0; _ -> 1 end).
