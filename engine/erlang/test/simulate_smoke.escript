#!/usr/bin/env escript
%%! -sname fh_simulate_smoke
%%
%% No-PG smoke for W7 — the simulate PREVIEW (engine-contract §10.1, fh_engine_simulate).
%% Proves the two halves without Postgres:
%%   1. apply_overrides/2 — the override mapping (target_price→point range; state→set +
%%      strip pin; property_type→reject; unknown/invalid/non-map→error).
%%   2. run/2 — the pure resolver-only DAG walk: all base outcomes recompute + pass the
%%      Layer-1 gate (run/2 crashes fail-closed otherwise), and a what-if override
%%      actually FLOWS THROUGH to the regulated figures (a different price / state yields
%%      a different budget envelope — the duty recompute the calculator relies on).
%%
%% Pure given onboarding Args + the persistent_term artifact: state is passed directly in
%% onboarding (no target_zone/target_sal) so cash_position takes projection_state's pure
%% step-3 branch. Run from engine/erlang:
%%   ERL_LIBS=_build/default/lib escript test/simulate_smoke.escript

-mode(compile).

main(_) ->
    ok = fh_engine_kb:load(),
    io:format("simulate preview smoke — apply_overrides + pure run/2, no PG~n~n"),

    R = override_mapping_checks() ++ run_walk_checks(),

    io:format("~n================================================================~n"),
    case [X || X <- R, X =:= fail] of
        [] -> io:format("PASS — override mapping + resolver-only preview hold~n"), halt(0);
        F  -> io:format("FAIL — ~p check(s) failed~n", [length(F)]), halt(1)
    end.

%% --- 1. apply_overrides/2 mapping -------------------------------------------

override_mapping_checks() ->
    io:format("apply_overrides/2 — override mapping~n"),
    %% an onboarding with a pinned zone + SAL, to prove `state` strips them.
    Pinned = #{<<"state">> => <<"NSW">>, <<"target_zone">> => [<<"Cabramatta">>],
               <<"target_sal">> => <<"SAL12345">>,
               <<"target_price_range">> => [600000, 700000]},

    TP = fh_engine_simulate:apply_overrides(#{<<"target_price">> => 850000}, Pinned),
    StateOv = fh_engine_simulate:apply_overrides(#{<<"state">> => <<"VIC">>}, Pinned),
    PType = fh_engine_simulate:apply_overrides(#{<<"property_type">> => <<"apartment">>}, Pinned),
    Unknown = fh_engine_simulate:apply_overrides(#{<<"foo">> => 1}, Pinned),
    BadTP = fh_engine_simulate:apply_overrides(#{<<"target_price">> => <<"lots">>}, Pinned),
    NotMap = fh_engine_simulate:apply_overrides([{<<"target_price">>, 1}], Pinned),

    [check("target_price → collapses target_price_range to a point [p,p]",
           range_of(TP), [850000, 850000]),
     check("target_price override leaves the pin untouched (price what-if keeps zone)",
           has_key(TP, <<"target_zone">>), true),
     check("state → sets the explicit state",
           state_of(StateOv), <<"VIC">>),
     check("state → STRIPS target_zone (projection_state step-3 pure branch wins)",
           has_key(StateOv, <<"target_zone">>), false),
     check("state → STRIPS target_sal",
           has_key(StateOv, <<"target_sal">>), false),
     check("property_type → rejected as a Phase-B dimension (no silent drop)",
           PType, {error, property_type_phase_b}),
     check("an unknown override key → {error,{unknown_override,_}}",
           Unknown, {error, {unknown_override, <<"foo">>}}),
     check("a non-number target_price → {error,{invalid_override,_}}",
           BadTP, {error, {invalid_override, <<"target_price">>}}),
     check("a non-map overrides body → {error,not_a_map}",
           NotMap, {error, not_a_map})].

%% --- 2. run/2 resolver-only walk --------------------------------------------

run_walk_checks() ->
    io:format("~nrun/2 — pure resolver-only preview walk~n"),
    Base   = onboarding(<<"NSW">>, [600000, 600000]),
    Dearer = onboarding(<<"NSW">>, [900000, 900000]),
    VicOb  = onboarding(<<"VIC">>, [600000, 600000]),

    %% run/2 crashes fail-closed if any outcome fails the Layer-1 gate; reaching {ok,_}
    %% for all three is itself the "every outcome conforms" proof.
    {ok, OutBase}   = fh_engine_simulate:run(Base, <<"owner_occupier">>),
    {ok, OutDearer} = fh_engine_simulate:run(Dearer, <<"owner_occupier">>),
    {ok, OutVic}    = fh_engine_simulate:run(VicOb, <<"owner_occupier">>),

    BudgetBase = maps:get(<<"budget_envelope">>, OutBase),
    BudgetDear = maps:get(<<"budget_envelope">>, OutDearer),
    BudgetVic  = maps:get(<<"budget_envelope">>, OutVic),

    [check("the preview returns all 7 base outcomes",
           lists:sort(maps:keys(OutBase)),
           lists:sort([<<"profile">>, <<"scheme_stack">>, <<"mortgage_plan">>,
                       <<"budget_envelope">>, <<"ongoing_obligations">>,
                       <<"journey_swimlane">>, <<"preparation_plan">>])),
     check("a higher target_price FLOWS THROUGH → a different budget envelope (duty recomputed)",
           BudgetBase =/= BudgetDear, true),
     check("a different state FLOWS THROUGH → a different budget envelope (state duty)",
           BudgetBase =/= BudgetVic, true),
     %% the journey (last placer) re-derives off the recomputed cash_events — prove the
     %% override reached the far end of the DAG, not just cash_position.
     check("the override reaches the journey spine (different journey under a dearer price)",
           maps:get(<<"journey_swimlane">>, OutBase)
               =/= maps:get(<<"journey_swimlane">>, OutDearer), true)].

%% --- helpers ----------------------------------------------------------------

onboarding(State, Range) ->
    #{<<"state">> => State, <<"target_price_range">> => Range, <<"target_zone">> => []}.

range_of({ok, Ob}) -> maps:get(<<"target_price_range">>, Ob);
range_of(Other)    -> {unexpected, Other}.

state_of({ok, Ob}) -> maps:get(<<"state">>, Ob);
state_of(Other)    -> {unexpected, Other}.

has_key({ok, Ob}, K) -> maps:is_key(K, Ob);
has_key(Other, _)    -> {unexpected, Other}.

check(Label, Got, Want) ->
    case Got =:= Want of
        true  -> io:format("  PASS   ~ts~n", [Label]), pass;
        false -> io:format("  FAIL   ~ts = ~p, expected ~p~n", [Label, Got, Want]), fail
    end.
