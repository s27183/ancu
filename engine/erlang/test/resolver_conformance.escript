#!/usr/bin/env escript
%%! -sname fh_resolver_conformance
%%
%% Conformance suite for fh_engine_resolver against the executable spec
%% tests/resolver_eval.py. Loads the SAME materialized artifact the engine loads
%% (priv/kb/artifact.json via fh_engine_kb), builds the leaf->rule map, and runs the
%% spec's worked examples through the Erlang interpreter — asserting identical
%% THREE-VALUED outcomes (true | false | undetermined). The two implementations must
%% stay in semantic lockstep; this is the cross-language check that they do.
%% See docs/architecture/resolver-semantics.md.
%%
%% A case asserts `expect` (joint leaf -> value, via eval_joint) and/or
%% `expect_per_applicant` (per-applicant leaf -> [v0, v1, ...], via eval_applicants).
%% Expected values may be true | false | undetermined.
%%
%% xfail protocol (mirrors resolver_eval.py): a confirmed-open xfail keeps the run
%% green; an xfail that now MATCHES surfaces loudly as the finding's close-signal.
%%
%% Run from engine/erlang with the build libs on the path (no Postgres needed):
%%   ERL_LIBS=_build/default/lib escript test/resolver_conformance.escript

-mode(compile).

main(_) ->
    ok = fh_engine_kb:load(),
    Rules = fh_engine_kb:rules(),
    io:format("resolver conformance — ~p fillable leaf rules~n~n", [map_size(Rules)]),
    Results = [run_case(C, Rules) || C <- cases()],
    Fails = [R || {fail, _} = R <- Results],
    Xpass = [R || {xpass, _} = R <- Results],
    io:format("~n================================================================~n"),
    case {Fails, Xpass} of
        {[], []} ->
            io:format("PASS — all cases match the spec (three-valued lockstep)~n"),
            halt(0);
        {[], _} ->
            io:format("PASS — but XPASS present: a known-open finding now matches; close it~n"),
            halt(0);  %% xpass is a signal, not a CI break (mirrors resolver_eval)
        _ ->
            io:format("FAIL — ~p hard failure(s)~n", [length(Fails)]),
            halt(1)
    end.

%% --- cases (mirror tests/resolver_eval.py CASES) ----------------------------

cases() ->
    [
     %% -- scalar cases: the backward-compat guard (resolver-semantics §5). Pinned
     %%    facts → identical true|false, never undetermined.
     #{name => <<"fhss-single-eligible">>,
       facts => #{<<"applicants">> => [
           #{<<"age">> => 30, <<"ever_owned_au_property">> => false,
             <<"owner_occupier_intent">> => true, <<"prior_fhss_release">> => false}]},
       expect => [{<<"eligibility.fhss.eligible">>, true}]},

     #{name => <<"fhg-single-eligible-under-cap">>,
       facts => #{
           <<"applicants">> => [
               #{<<"citizenship_status">> => <<"citizen">>, <<"age">> => 30,
                 <<"ever_owned_au_property">> => false,
                 <<"years_since_last_au_property_interest">> => 0,
                 <<"owner_occupier_intent">> => true}],
           <<"property_fit">> => #{<<"state">> => <<"NSW">>, <<"price">> => 1200000},
           <<"locals">> => #{<<"location_tier">> => <<"capital_or_regional_centre">>}},
       expect => [{<<"eligibility.fhg.applicable_cap_for_location_property">>, 1500000},
                  {<<"eligibility.fhg.eligible">>, true}]},

     #{name => <<"fhg-single-over-cap">>,
       facts => #{
           <<"applicants">> => [
               #{<<"citizenship_status">> => <<"citizen">>, <<"age">> => 30,
                 <<"ever_owned_au_property">> => false,
                 <<"years_since_last_au_property_interest">> => 0,
                 <<"owner_occupier_intent">> => true}],
           <<"property_fit">> => #{<<"state">> => <<"NSW">>, <<"price">> => 1600000},
           <<"locals">> => #{<<"location_tier">> => <<"capital_or_regional_centre">>}},
       expect => [{<<"eligibility.fhg.eligible">>, false}]},

     %% -- three-valued cases: partial knowledge.
     %% Mode A → citizenship is the SET {citizen, permanent_resident}: `in [citizen,PR]`
     %% holds for ALL → true; `eq citizen` holds for SOME → undetermined.
     #{name => <<"citizenship-set-mode-a">>,
       facts => #{
           <<"applicants">> => [
               #{<<"citizenship_status">> =>
                     #{<<"oneof">> => [<<"citizen">>, <<"permanent_resident">>]},
                 <<"age">> => 30, <<"ever_owned_au_property">> => false,
                 <<"years_since_last_au_property_interest">> => 0,
                 <<"owner_occupier_intent">> => true,
                 <<"currently_owns_property">> => false}],
           <<"property_fit">> => #{<<"state">> => <<"NSW">>, <<"price">> => 1200000},
           <<"locals">> => #{<<"location_tier">> => <<"capital_or_regional_centre">>}},
       expect => [{<<"eligibility.fhg.eligible">>, true},
                  {<<"eligibility.help_to_buy.eligible">>, undetermined}]},

     %% prior_fhss_release absent → criterion undetermined → FHSS undetermined
     %% (bi-state gave false — wrongly ineligible). The absent → undetermined change.
     #{name => <<"absent-fact-undetermined">>,
       facts => #{<<"applicants">> => [
           #{<<"age">> => 30, <<"ever_owned_au_property">> => false,
             <<"owner_occupier_intent">> => true}]},
       expect => [{<<"eligibility.fhss.eligible">>, undetermined}]},

     %% W-B: owned AU property, WHEN unknown → any_of(ever_owned eq false → false,
     %% years_since gte 10 → undetermined) → undetermined → 'pending: 10+ years?'.
     #{name => <<"prior-owner-unknown-years">>,
       facts => #{
           <<"applicants">> => [
               #{<<"citizenship_status">> => <<"citizen">>, <<"age">> => 40,
                 <<"ever_owned_au_property">> => true,
                 <<"owner_occupier_intent">> => true}],
           <<"property_fit">> => #{<<"state">> => <<"NSW">>, <<"price">> => 1200000},
           <<"locals">> => #{<<"location_tier">> => <<"capital_or_regional_centre">>}},
       expect => [{<<"eligibility.fhg.eligible">>, undetermined}]},

     %% G3: location_tier absent → cap lookup returns its null default → the price
     %% criterion's rhs is null → undetermined (in Erlang term order `price ≤ null`
     %% was spuriously true; three-valued kills it). FHG → undetermined.
     #{name => <<"fhg-null-cap-rhs-undetermined">>,
       facts => #{
           <<"applicants">> => [
               #{<<"citizenship_status">> => <<"citizen">>, <<"age">> => 30,
                 <<"ever_owned_au_property">> => false,
                 <<"years_since_last_au_property_interest">> => 0,
                 <<"owner_occupier_intent">> => true}],
           <<"property_fit">> => #{<<"state">> => <<"NSW">>, <<"price">> => 1200000}},
           %% location_tier deliberately absent → cap lookup → null default.
       expect => [{<<"eligibility.fhg.eligible">>, undetermined}]},

     %% F13 close: FHSS is per-applicant. A qualifies; B previously owned AU property.
     %% Per-applicant verdicts [true, false] → the household derives eligible_applicants
     %% = [A]. (The bi-state joint-∀ leaf gave one false for the household — the old
     %% xfail. Now asserted per-applicant via eval_applicants → PASS, closing F13.)
     #{name => <<"fhss-two-applicants-one-qualifies">>,
       facts => #{<<"applicants">> => [
           #{<<"age">> => 30, <<"ever_owned_au_property">> => false,
             <<"owner_occupier_intent">> => true, <<"prior_fhss_release">> => false},
           #{<<"age">> => 32, <<"ever_owned_au_property">> => true,
             <<"owner_occupier_intent">> => true, <<"prior_fhss_release">> => false}]},
       expect_per_applicant => [{<<"eligibility.fhss.eligible">>, [true, false]}]}
    ].

%% --- runner -----------------------------------------------------------------

run_case(#{name := Name} = Case, Rules) ->
    Facts = maps:get(facts, Case),
    Xfail = maps:get(xfail, Case, undefined),
    Joint = lists:filtermap(
        fun({Leaf, Want}) ->
            mismatch(Leaf, fh_engine_resolver:eval_joint(Leaf, Rules, Facts), Want)
        end, maps:get(expect, Case, [])),
    PerAppl = lists:filtermap(
        fun({Leaf, Want}) ->
            mismatch(Leaf, fh_engine_resolver:eval_applicants(Leaf, Rules, Facts), Want)
        end, maps:get(expect_per_applicant, Case, [])),
    report(Name, Xfail, Joint ++ PerAppl).

mismatch(Leaf, Got, Want) ->
    case Got =:= Want of
        true  -> false;
        false -> {true, {Leaf, Got, Want}}
    end.

report(Name, undefined, []) ->
    io:format("  PASS   ~s~n", [Name]), pass;
report(Name, undefined, Mismatches) ->
    io:format("  FAIL   ~s~n", [Name]),
    [io:format("           ~s: got ~p, expected ~p~n", [L, G, W]) || {L, G, W} <- Mismatches],
    {fail, Name};
report(Name, F, []) ->
    io:format("  XPASS  ~s  [~s] NOW MATCHES — reshape closed the gap; "
              "remove the xfail and close ~s~n", [Name, F, F]),
    {xpass, Name};
report(Name, F, Mismatches) ->
    io:format("  xfail  ~s  [~s] confirmed-open~n", [Name, F]),
    [io:format("           ~s: got ~p, correct ~p~n", [L, G, W]) || {L, G, W} <- Mismatches],
    xfail.
