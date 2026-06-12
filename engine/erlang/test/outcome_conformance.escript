#!/usr/bin/env escript
%%! -sname fh_outcome_conformance
%%
%% Conformance suite for fh_engine_outcome:check/3 — the Layer-1 outcome-conformance
%% walk (outcome-conformance.md) — against the executable spec tests/outcome_validate.py.
%% Runs the SAME case set (synthetic type-tree + value) through the Erlang core and
%% asserts the SAME conform/reject VERDICT. Reason text is language-specific and
%% informative; the verdict is the contract the fail-closed seam depends on, so the
%% verdict is what the two implementations must agree on.
%%
%% This needs no artifact + no Postgres — check/3 is the pure core. But the build libs
%% must be on the path so the module is loadable:
%%   ERL_LIBS=_build/default/lib escript test/outcome_conformance.escript

-mode(compile).

-define(LOCALES, [<<"vi">>, <<"en">>]).

main(_) ->
    io:format("outcome conformance — fh_engine_outcome:check/3 vs tests/outcome_validate.py~n~n"),
    Results = [run_case(C) || C <- cases()],
    CaseFails = [R || {fail, _} = R <- Results],
    io:format("~n--- seam fail-closed (validate/2 against the real artifact) ---~n"),
    SeamFails = seam_cases(),
    Fails = CaseFails ++ SeamFails,
    io:format("~n================================================================~n"),
    case Fails of
        [] ->
            io:format("PASS — ~p check/3 cases + seam fail-closed proven (conform/reject lockstep)~n",
                      [length(Results)]),
            halt(0);
        _ ->
            io:format("FAIL — ~p mismatch(es)~n", [length(Fails)]),
            halt(1)
    end.

%% Prove the SEAM ENTRY (validate/2), not just the pure walk: load the real artifact
%% (no Postgres needed — fh_engine_kb:load/0 reads priv/kb/artifact.json) and confirm a
%% conforming `profile` outcome passes while a non-conforming one CRASHES fail-closed with
%% {outcome_nonconforming, ...} (outcome-conformance.md §7 — prove the fail path, not just
%% assert it). The bad value: key_strengths is array<localized_text>, so a bare binary
%% element must reject at the real type-tree the engine loads.
seam_cases() ->
    ok = fh_engine_kb:load(),
    Good = #{<<"applicant_count">> => 1,
             <<"firb_required_any">> => false,
             <<"target_price_range">> => [600000, 700000],
             <<"key_strengths">> =>
                 [#{<<"vi">> => <<"mua lần đầu"/utf8>>, <<"en">> => <<"first home buyer">>}]},
    Bad = Good#{<<"key_strengths">> => [<<"english only, no localization">>]},
    GoodOk = (catch fh_engine_outcome:validate(<<"profile">>, Good)) =:= ok,
    BadCrash = case catch fh_engine_outcome:validate(<<"profile">>, Bad) of
                   {'EXIT', {{outcome_nonconforming, <<"profile">>, <<"key_strengths">>, _}, _}} -> true;
                   _ -> false
               end,
    F1 = assert("seam-conforming-profile-passes", GoodOk),
    F2 = assert("seam-nonconforming-crashes-fail-closed", BadCrash),
    F1 ++ F2.

assert(Name, true) ->
    io:format("  ok   ~-44s -> as expected~n", [Name]), [];
assert(Name, false) ->
    io:format("  FAIL ~-44s -> assertion failed~n", [Name]), [{fail, Name}].

run_case(#{name := Name, tree := Tree, value := Value, ok := ExpectOk}) ->
    Got = fh_engine_outcome:check(Tree, Value, ?LOCALES),
    GotOk = (Got =:= ok),
    case GotOk =:= ExpectOk of
        true ->
            io:format("  ok   ~-34s -> ~s~n", [Name, render(Got)]),
            {pass, Name};
        false ->
            io:format("  FAIL ~-34s -> got ~s, expected ~s~n",
                      [Name, render(Got), case ExpectOk of true -> "conform"; false -> "reject" end]),
            {fail, Name}
    end.

render(ok)            -> "conform";
render({error, R})    -> binary_to_list(<<"reject: ", R/binary>>).

%% --- cases (mirror tests/outcome_validate.py CASES) -------------------------

loc()    -> #{<<"kind">> => <<"localized">>}.
money()  -> #{<<"kind">> => <<"scalar">>, <<"type">> => <<"money">>}.
mrange() -> #{<<"kind">> => <<"scalar">>, <<"type">> => <<"money_range">>}.
str()    -> #{<<"kind">> => <<"scalar">>, <<"type">> => <<"string">>}.
enum()   -> #{<<"kind">> => <<"enum">>,
              <<"options">> => [<<"a">>, <<"b">>, <<"c">>]}.

cases() ->
    [
     %% localized clause
     #{name => "loc-ok", tree => loc(), ok => true,
       value => #{<<"vi">> => <<"Người mua nhà lần đầu"/utf8>>,
                  <<"en">> => <<"First home buyer">>}},
     #{name => "loc-missing-locale", tree => loc(), ok => false,
       value => #{<<"en">> => <<"First home buyer">>}},
     #{name => "loc-empty-vi", tree => loc(), ok => false,
       value => #{<<"vi">> => <<"  ">>, <<"en">> => <<"First home buyer">>}},
     #{name => "loc-not-distinct", tree => loc(), ok => false,
       value => #{<<"vi">> => <<"First home buyer">>,
                  <<"en">> => <<"First home buyer">>}},
     #{name => "loc-not-a-map", tree => loc(), ok => false,
       value => <<"First home buyer">>},
     #{name => "loc-null-ok", tree => loc(), ok => true, value => null},

     %% enum clause
     #{name => "enum-ok", tree => enum(), ok => true, value => <<"b">>},
     #{name => "enum-bad", tree => enum(), ok => false, value => <<"z">>},

     %% figure clause (§98)
     #{name => "money-ok", tree => money(), ok => true, value => 500000},
     #{name => "money-null-ok", tree => money(), ok => true, value => null},
     #{name => "money-as-string-rejected", tree => money(), ok => false,
       value => <<"$500k">>},
     #{name => "money-as-localized-rejected", tree => money(), ok => false,
       value => #{<<"vi">> => <<"500 nghìn"/utf8>>, <<"en">> => <<"500k">>}},
     #{name => "money-as-bool-rejected", tree => money(), ok => false, value => true},
     #{name => "money_range-ok", tree => mrange(), ok => true,
       value => [600000, 700000]},
     #{name => "money_range-string-elem-rejected", tree => mrange(), ok => false,
       value => [600000, <<"700k">>]},

     %% string scalar — graceful (not a figure)
     #{name => "string-graceful", tree => str(), ok => true, value => <<"Cabramatta">>},

     %% array<localized>
     #{name => "array-loc-ok", ok => true,
       tree => #{<<"kind">> => <<"array">>, <<"element">> => loc()},
       value => [#{<<"vi">> => <<"ràng buộc tài chính"/utf8>>,
                   <<"en">> => <<"financial constraint">>}]},
     #{name => "array-loc-bad-elem", ok => false,
       tree => #{<<"kind">> => <<"array">>, <<"element">> => loc()},
       value => [#{<<"vi">> => <<"ổn"/utf8>>, <<"en">> => <<"fine">>},
                 #{<<"en">> => <<"missing vi">>}]},
     #{name => "array-not-a-list", ok => false,
       tree => #{<<"kind">> => <<"array">>, <<"element">> => loc()},
       value => #{<<"vi">> => <<"x">>, <<"en">> => <<"y">>}},

     %% object with a localized sub-field
     #{name => "object-loc-subfield-bad", ok => false,
       tree => #{<<"kind">> => <<"object">>,
                 <<"fields">> => #{<<"name">> => str(), <<"reason">> => loc()}},
       value => #{<<"name">> => <<"FHG">>,
                  <<"reason">> => #{<<"vi">> => <<"">>, <<"en">> => <<"over cap">>}}},

     %% unknown kind — graceful
     #{name => "unknown-graceful", ok => true,
       tree => #{<<"kind">> => <<"unknown">>, <<"raw">> => <<"comparable_sale">>},
       value => #{<<"anything">> => 1}}
    ].
