#!/usr/bin/env escript
%%! -sname fh_firb_residence_conformance
%%
%% Behavior 7 — an overseas-living buyer's FIRB status is stated right.
%%
%% Regulated figures are grounded -> P-7 · One declaration per outcome shape -> The engine -> FATR reg 35(1)(a) exempts citizens only
%% Loads the SAME materialized artifact the engine loads (priv/kb/artifact.json) and asserts:
%%   1. PREDICATE — kb.firb.status-determination's applicant.firb_required is unchanged:
%%      citizen [false], permanent_resident [false], temporary_resident [true],
%%      non_resident [true]. citizen → false is exact wherever they live (FATR 2015
%%      reg 35(1)(a)); PR → false assumes ordinarily resident.
%%   2. ASSUMPTION LINE — a domestic profile that may include a permanent resident states
%%      the ordinarily-resident assumption in key_assumptions, EN and VI (kb.copy.profile
%%      assume_pr_ordinarily_resident): the real Mode A base turn ({citizen, PR} set), the
%%      Mode C investor_profile base turn, and a scalar-PR household. A citizen-only
%%      household gets no such line.
%%   3. LAYER 1 — the base profiles still conform to fhb-domestic-au, nexthome-domestic-au
%%      and investor-domestic-au `profile` schemas, key_assumptions typed localized.
%%
%% Run from engine/erlang with the build libs on the path (no Postgres, no live model):
%%   ERL_LIBS=_build/default/lib escript test/firb_residence_conformance.escript

-mode(compile).

main(_) ->
    ok = fh_engine_kb:load(),
    io:format("firb_residence conformance — FIRB status for overseas-living buyers (behavior 7)~n~n"),
    R = lists:flatten([predicate_cases(), assumption_cases(), layer1_cases()]),
    Fails = [X || X <- R, X =:= fail],
    io:format("~n================================================================~n"),
    case Fails of
        [] -> io:format("PASS — all ~p firb_residence anchors hold~n", [length(R)]), halt(0);
        _  -> io:format("FAIL — ~p anchor(s) mismatched~n", [length(Fails)]), halt(1)
    end.

%% --- fixtures ----------------------------------------------------------------

firb(Status) ->
    fh_engine_resolver:eval_applicants(
        <<"applicant.firb_required">>, fh_engine_kb:rules(),
        #{<<"applicants">> => [#{<<"citizenship_status">> => Status}]}).

line() ->
    fh_engine_kb:copy(<<"kb.copy.profile">>, <<"assume_pr_ordinarily_resident">>).

base_args() ->
    #{onboarding => #{<<"target_price_range">> => [600000, 700000],
                       <<"target_zone">> => [<<"Footscray">>]}}.

mode_a() ->
    {O, _, _} = fh_engine_fill:resolver(<<"buyer_profile">>, base_args(), #{}),
    O.

mode_c() ->
    {O, _, _} = fh_engine_fill:resolver(<<"investor_profile">>, base_args(), #{}),
    O.

%% --- 1. the predicate, unchanged ----------------------------------------------

predicate_cases() ->
    [check("eval_applicants citizen -> [false]", firb(<<"citizen">>), [false]),
     check("eval_applicants permanent_resident -> [false]",
           firb(<<"permanent_resident">>), [false]),
     check("eval_applicants temporary_resident -> [true]",
           firb(<<"temporary_resident">>), [true]),
     check("eval_applicants non_resident -> [true]", firb(<<"non_resident">>), [true])].

%% --- 2. the ordinarily-resident line ------------------------------------------

assumption_cases() ->
    L = line(),
    En = maps:get(<<"en">>, L, <<>>),
    Vi = maps:get(<<"vi">>, L, <<>>),
    A = mode_a(),
    [AApp] = maps:get(<<"applicants">>, A),
    Pr = fh_engine_fill:residence_assumptions(
           [#{<<"citizenship_status">> => <<"permanent_resident">>}]),
    Citizens = fh_engine_fill:residence_assumptions(
           [#{<<"citizenship_status">> => <<"citizen">>},
            #{<<"citizenship_status">> => <<"citizen">>}]),
    Mixed = fh_engine_fill:residence_assumptions(
           [#{<<"citizenship_status">> => <<"citizen">>},
            #{<<"citizenship_status">> => <<"permanent_resident">>}]),
    [check("copy EN names the assumption (lives in Australia, 200 days)",
           has_all(En, [<<"assumes">>, <<"permanent resident">>, <<"lives in Australia">>,
                        <<"200">>]), true),
     check("copy EN names the consequence (foreign person, approval, established home)",
           has_all(En, [<<"foreign person">>, <<"approval">>, <<"established home">>]), true),
     check("copy EN says citizens need no approval wherever they live",
           has_all(En, [<<"citizens need no approval wherever they live">>]), true),
     check("copy VI present, distinct from EN, carries the same facts",
           Vi =/= <<>> andalso Vi =/= En andalso
           has_all(Vi, [<<"200">>, <<"FIRB">>, <<"thường trú nhân"/utf8>>,
                        <<"nhà đã qua sử dụng"/utf8>>, <<"Công dân Úc"/utf8>>]), true),
     check("Mode A base applicant is the {citizen, PR} set",
           maps:get(<<"citizenship_status">>, AApp),
           #{<<"oneof">> => [<<"citizen">>, <<"permanent_resident">>]}),
     check("Mode A base turn: key_assumptions = [the line] (EN + VI)",
           maps:get(<<"key_assumptions">>, A, undefined), [L]),
     check("Mode A base turn: firb_required_any still false",
           maps:get(<<"firb_required_any">>, A), false),
     check("Mode C base turn: key_assumptions = [the line]",
           maps:get(<<"key_assumptions">>, mode_c(), undefined), [L]),
     check("permanent_resident household: key_assumptions = [the line]", Pr, [L]),
     check("citizen + PR household: the line once", Mixed, [L]),
     check("citizen-only household: no such line", Citizens, [])].

%% --- 3. Layer 1 ----------------------------------------------------------------

layer1_cases() ->
    [check("Layer-1 conforms: Mode A profile vs fhb-domestic-au",
           validate(<<"fhb-domestic-au">>, mode_a()), ok),
     check("Layer-1 conforms: buyer_profile vs nexthome-domestic-au (Mode E)",
           validate(<<"nexthome-domestic-au">>, mode_a()), ok),
     check("Layer-1 conforms: Mode C profile vs investor-domestic-au",
           validate(<<"investor-domestic-au">>, mode_c()), ok),
     check("Layer-1 rejects an English-only key_assumptions entry (typed localized)",
           validate(<<"fhb-domestic-au">>,
                    (mode_a())#{<<"key_assumptions">> => [#{<<"en">> => <<"x">>}]}) =/= ok,
           true)].

validate(Blueprint, Outcome) ->
    try fh_engine_outcome:validate(Blueprint, <<"profile">>, Outcome), ok
    catch _:Why -> {error, Why} end.

%% --- helpers ----------------------------------------------------------------

has_all(Text, Needles) ->
    lists:all(fun(N) -> binary:match(Text, N) =/= nomatch end, Needles).

check(Label, Got, Want) ->
    case Got =:= Want of
        true  -> io:format("  PASS   ~ts~n", [Label]), pass;
        false -> io:format("  FAIL   ~ts = ~p, expected ~p~n", [Label, Got, Want]), fail
    end.
