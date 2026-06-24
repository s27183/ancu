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
    io:format("~n--- §13 placement & provenance (check_placement/2 lockstep) ---~n"),
    PlacementResults = [run_placement_case(C) || C <- placement_cases()],
    PlacementFails = [R || {fail, _} = R <- PlacementResults],
    io:format("~n--- seam fail-closed (validate/2 against the real artifact) ---~n"),
    SeamFails = seam_cases(),
    Fails = CaseFails ++ PlacementFails ++ SeamFails,
    io:format("~n================================================================~n"),
    case Fails of
        [] ->
            io:format("PASS — ~p check/3 + ~p placement cases + seam fail-closed proven (lockstep)~n",
                      [length(Results), length(PlacementResults)]),
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
    GoodOk = (catch fh_engine_outcome:validate(<<"fhb-domestic-au">>, <<"profile">>, Good)) =:= ok,
    BadCrash = case catch fh_engine_outcome:validate(<<"fhb-domestic-au">>, <<"profile">>, Bad) of
                   {'EXIT', {{outcome_nonconforming, <<"profile">>, <<"key_strengths">>, _}, _}} -> true;
                   _ -> false
               end,
    %% §13 seam: a budget_envelope whose type walk PASSES (a minimal cash_event: null label
    %% conforms, [1,2] is a money_range, "out" is a valid direction) but whose PLACEMENT
    %% fails — a money flow with counterparty=null — must crash fail-closed at validate/2,
    %% tagged `placement`, against the REAL artifact's component set (source=cash_position
    %% resolves, so the crash is check 2, not check 1). Proves the new clause runs at the seam.
    BadPlacement = #{<<"cash_events">> =>
                         [#{<<"direction">> => <<"out">>, <<"counterparty">> => null,
                            <<"amount">> => [1, 2], <<"source_component">> => <<"cash_position">>}]},
    PlacementCrash = case catch fh_engine_outcome:validate(<<"fhb-domestic-au">>, <<"budget_envelope">>, BadPlacement) of
                         {'EXIT', {{outcome_nonconforming, <<"budget_envelope">>, <<"placement">>, _}, _}} -> true;
                         _ -> false
                     end,
    F1 = assert("seam-conforming-profile-passes", GoodOk),
    F2 = assert("seam-nonconforming-crashes-fail-closed", BadCrash),
    F3 = assert("seam-placement-violation-crashes-fail-closed", PlacementCrash),
    F1 ++ F2 ++ F3.

%% --- §13 placement cases (mirror tests/outcome_validate.py PLACEMENT_CASES) --

placement_comps() ->
    [<<"cash_position">>, <<"eligibility">>, <<"ownership_planning">>, <<"purchase_journey">>].

pcell(Phase, Marker, Cp, Amount, Src) ->
    #{<<"phase">> => Phase, <<"flow_marker">> => Marker, <<"counterparty">> => Cp,
      <<"amount">> => Amount, <<"source_component">> => Src}.

placement_cases() ->
    C = placement_comps(),
    [
     %% check 1 — provenance resolves
     #{name => "prov-ok", comps => C, ok => true,
       outcome => #{<<"cells">> => [pcell(<<"prepare">>, <<"none">>, null, null, <<"cash_position">>)]}},
     #{name => "prov-bad-typo", comps => C, ok => false,
       outcome => #{<<"cells">> => [pcell(<<"prepare">>, <<"none">>, null, null, <<"buyer_profilex">>)]}},
     #{name => "prov-skip-when-no-components", comps => [], ok => true,
       outcome => #{<<"cells">> => [pcell(<<"prepare">>, <<"none">>, null, null, <<"buyer_profilex">>)]}},

     %% check 2 — money flow ⟹ counterparty (cash_event shape)
     #{name => "cashevent-out-no-cp", comps => C, ok => false,
       outcome => #{<<"cash_events">> =>
                        [#{<<"direction">> => <<"out">>, <<"counterparty">> => null,
                           <<"amount">> => [1, 2], <<"source_component">> => <<"cash_position">>}]}},
     #{name => "cashevent-out-ok", comps => C, ok => true,
       outcome => #{<<"cash_events">> =>
                        [#{<<"direction">> => <<"out">>, <<"counterparty">> => <<"other">>,
                           <<"amount">> => [1, 2], <<"source_component">> => <<"cash_position">>}]}},

     %% check 2 — money cell shape + inverse
     #{name => "cell-money-no-cp", comps => C, ok => false,
       outcome => #{<<"cells">> => [pcell(<<"settle">>, <<"money_out">>, null, [1, 2], <<"cash_position">>)]}},
     #{name => "nonmoney-cell-with-cp", comps => C, ok => false,
       outcome => #{<<"cells">> => [pcell(<<"contract">>, <<"document">>, <<"you">>, null, <<"purchase_journey">>)]}},
     #{name => "nonmoney-cell-with-amount", comps => C, ok => false,
       outcome => #{<<"cells">> => [pcell(<<"settle">>, <<"milestone">>, null, [1, 2], <<"purchase_journey">>)]}},

     %% check 3 — interactions derive, not invent
     #{name => "interactions-ok", comps => C, ok => true,
       outcome => #{<<"cells">> =>
                        [(pcell(<<"contract">>, <<"money_out">>, <<"you">>, [30000, 35000], <<"cash_position">>))
                         #{<<"actor">> => <<"other">>}],
                    <<"interactions">> =>
                        [#{<<"from_actor">> => <<"you">>, <<"to_actor">> => <<"other">>,
                           <<"phase">> => <<"contract">>,
                           <<"flows">> => [#{<<"direction">> => <<"out">>, <<"amount">> => [30000, 35000]}]}]}},
     #{name => "interactions-invented-flow", comps => C, ok => false,
       outcome => #{<<"cells">> =>
                        [(pcell(<<"contract">>, <<"money_out">>, <<"you">>, [30000, 35000], <<"cash_position">>))
                         #{<<"actor">> => <<"other">>}],
                    <<"interactions">> =>
                        [#{<<"from_actor">> => <<"you">>, <<"to_actor">> => <<"other">>,
                           <<"phase">> => <<"contract">>,
                           <<"flows">> => [#{<<"direction">> => <<"out">>, <<"amount">> => [99, 99]}]}]}},

     %% graceful — no placement fields
     #{name => "placement-graceful-no-fields", comps => C, ok => true,
       outcome => #{<<"key_assumptions">> => [#{<<"vi">> => <<"x">>, <<"en">> => <<"y">>}]}}
    ].

run_placement_case(#{name := Name, outcome := Outcome, comps := Comps, ok := ExpectOk}) ->
    Got = fh_engine_outcome:check_placement(Outcome, Comps),
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
