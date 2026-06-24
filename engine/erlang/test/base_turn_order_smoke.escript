#!/usr/bin/env escript
%%! -sname fh_base_turn_order_smoke
%%
%% No-PG integration smoke for the W5/W6 base DAG ORDER. The unit harnesses feed each
%% resolver a synthetic Upstream, so they cannot catch a mis-ordered ?BASE_COMPONENTS.
%% This walks the REAL resolver chain in ?BASE_COMPONENTS order (the order fh_engine_turn
%% uses), accumulating Upstream by outcome_type exactly as the turn does, and proves the
%% two ordering invariants the two-spines wave introduced:
%%   - ownership_planning runs BEFORE purchase_journey, so the journey PLACES the Own-phase
%%     recurring cell from ongoing_obligations (the W5 9→10 forward edge actually resolves).
%%   - preparation runs after eligibility + cash_position, so its placed figures resolve.
%%   - phase_playbook runs LAST over the REAL cash_position, so its action budget_refs
%%     validate against the actual cash_event ids (a dead-link the synthetic unit can't see).
%% Every committed outcome also passes the Layer-1 gate (the commit-seam check).
%%
%% Pure given onboarding Args + the persistent_term artifact (no Postgres): state is passed
%% directly in onboarding (no target_zone) so cash_position takes projection_state's pure
%% branch. Run from engine/erlang:
%%   ERL_LIBS=_build/default/lib escript test/base_turn_order_smoke.escript

-mode(compile).

%% the real base DAG order (mirror of fh_engine_turn:?BASE_COMPONENTS) + outcome types.
order() ->
    [{<<"buyer_profile">>,      <<"profile">>},
     {<<"eligibility">>,        <<"scheme_stack">>},
     {<<"mortgage_finance">>,   <<"mortgage_plan">>},
     {<<"cash_position">>,      <<"budget_envelope">>},
     {<<"ownership_planning">>, <<"ongoing_obligations">>},
     {<<"purchase_journey">>,   <<"journey_swimlane">>},
     {<<"preparation">>,        <<"preparation_plan">>},
     {<<"phase_playbook">>,     <<"phase_playbook">>}].

main(_) ->
    ok = fh_engine_kb:load(),
    io:format("base-turn order smoke — real resolver chain, no PG~n~n"),
    Args = #{onboarding => #{<<"state">> => <<"NSW">>,
                             <<"target_price_range">> => [600000, 700000],
                             <<"target_zone">> => []},
             intent => <<"owner_occupier">>},
    %% walk the chain exactly as fh_engine_turn does: resolver/3 then validate/2 then
    %% accumulate the outcome under its outcome_type for the downstream components.
    {Upstream, Fails0} =
        lists:foldl(
          fun({Comp, Type}, {Up, Fails}) ->
              {Outcome, _Renderer, _Kb} = fh_engine_fill:resolver(Comp, Args, Up),
              F = try fh_engine_outcome:validate(<<"fhb-domestic-au">>, Type, Outcome), pass
                  catch _:Why -> io:format("  FAIL   ~s gate: ~p~n", [Comp, Why]), fail end,
              io:format("  ~s   ~s committed (~s)~n", [tag(F), Comp, Type]),
              {Up#{Type => Outcome}, [F | Fails]}
          end, {#{}, []}, order()),

    %% --- the ordering payoff: the journey placed the Own recurring cell ----------
    Journey = maps:get(<<"journey_swimlane">>, Upstream),
    Cells = maps:get(<<"cells">>, Journey),
    OwnRecur = [C || C <- Cells,
                     maps:get(<<"phase">>, C) =:= <<"own">>,
                     maps:get(<<"flow_marker">>, C) =:= <<"money_out">>,
                     maps:get(<<"source_component">>, C) =:= <<"ownership_planning">>],
    Ix = maps:get(<<"interactions">>, Journey),
    OwnIx = [I || I <- Ix, maps:get(<<"phase">>, I) =:= <<"own">>],

    %% --- the phase_playbook payoff: budget_refs validated against REAL cash_events ----
    Playbook = maps:get(<<"phase_playbook">>, Upstream),
    KeptRefs = [maps:get(<<"budget_ref">>, A)
                || P <- maps:get(<<"phases">>, Playbook),
                   A <- maps:get(<<"actions">>, P),
                   maps:get(<<"budget_ref">>, A) =/= null],

    R = [check("ownership_planning ran before purchase_journey → Own recurring cell PLACED",
               length(OwnRecur), 1),
         check("the Own recurring cell carries a real money_range amount",
               is_money_range(maps:get(<<"amount">>, hd(OwnRecur))), true),
         check("the Own interaction (you→government recurring) was derived",
               length(OwnIx) >= 1, true),
         check("phase_playbook ran last over REAL cash_position → budget_refs are LIVE "
               "(the KB doc's ids match cash_position's cash_event ids)",
               length(KeptRefs) >= 1, true)
         | Fails0],

    io:format("~n================================================================~n"),
    case [X || X <- R, X =:= fail] of
        [] -> io:format("PASS — base DAG order holds; placements resolve end-to-end~n"), halt(0);
        F  -> io:format("FAIL — ~p check(s) failed~n", [length(F)]), halt(1)
    end.

is_money_range([Lo, Hi]) when is_number(Lo), is_number(Hi) -> true;
is_money_range(_) -> false.

tag(pass) -> "ok  ";
tag(fail) -> "FAIL".

check(Label, Got, Want) ->
    case Got =:= Want of
        true  -> io:format("  PASS   ~ts~n", [Label]), pass;
        false -> io:format("  FAIL   ~ts = ~p, expected ~p~n", [Label, Got, Want]), fail
    end.
