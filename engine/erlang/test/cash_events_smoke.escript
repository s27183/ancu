#!/usr/bin/env escript
%%! -sname fh_cash_events_smoke
%%
%% Focused unit smoke for W4 (two-spines): cash_position emits the cash_events
%% ACQUISITION spine on budget_envelope. No PG / port / HTTP — loads the compiled
%% KB artifact into persistent_term (as boot does), then calls fh_engine_cash:fill/2
%% with a synthetic NSW upstream (FHBAS duty concession + NSW FHOG grant) and asserts
%% the placed events, their phases/counterparties/provenance, and the no-double-count
%% rule (the duty concession does NOT appear as an in-event). Run from engine/erlang:
%%
%%   ERL_LIBS=_build/default/lib escript test/cash_events_smoke.escript

-mode(compile).

main(_) ->
    ok = fh_engine_kb:load(),

    %% --- synthetic upstream: NSW $600k-$700k, FHG-backed path -----------------
    %% scheme_stack carries a duty concession (FHBAS) AND a grant (FHOG). Only the
    %% grant must surface as an in-event; the concession is netted into the duty
    %% out-event (no double count).
    Stack = #{
        <<"applicable_schemes">> => [
            #{<<"name">> => <<"NSW First Home Owner Grant">>,
              <<"role">> => <<"grant">>,
              <<"benefit_value">> => [0, 10000],
              <<"benefit_is_estimate">> => false,
              <<"notes">> => []},
            #{<<"name">> => <<"First Home Guarantee (FHG)">>,
              <<"role">> => <<"deposit_guarantee">>,
              <<"benefit_value">> => [12000, 18000],
              <<"benefit_is_estimate">> => true,
              <<"notes">> => []},
            #{<<"name">> => <<"NSW FHBAS">>,
              <<"role">> => <<"stamp_duty_concession">>,
              <<"benefit_value">> => [20000, 22000],
              <<"benefit_is_estimate">> => false,
              <<"notes">> => []}
        ],
        <<"total_benefit_value">> => [32000, 50000]
    },
    Upstream = #{
        <<"profile">> => #{<<"target_price_range">> => [600000, 700000]},
        <<"scheme_stack">> => Stack,
        <<"mortgage_plan">> => #{<<"recommended_path">> => <<"fhg_backed">>}
    },
    %% pass `state` directly (no target_zone) so projection_state takes its pure,
    %% no-PG path (fh_engine_store:projection_state/1 step 3) — same as the conformance harness.
    Args = #{onboarding => #{<<"state">> => <<"NSW">>}},

    {Outcome, Renderer, _Kb} = fh_engine_cash:fill(Args, Upstream),
    Events = maps:get(<<"cash_events">>, Outcome),
    io:format("renderer: ~s~n", [Renderer]),
    io:format("cash_events (~p):~n", [length(Events)]),
    [io:format("  ~s | ~s | ~s | ~p | est=~p | cp=~s | src=~s | ~ts~n",
               [id(E), maps:get(<<"phase">>, E), maps:get(<<"direction">>, E),
                maps:get(<<"amount">>, E), maps:get(<<"is_estimate">>, E),
                maps:get(<<"counterparty">>, E), maps:get(<<"source_component">>, E),
                en(maps:get(<<"label">>, E))]) || E <- Events],

    %% --- assertions -----------------------------------------------------------
    expect(Renderer =:= <<"calculator">>, "renderer is calculator"),

    Out = [E || E <- Events, maps:get(<<"direction">>, E) =:= <<"out">>],
    In  = [E || E <- Events, maps:get(<<"direction">>, E) =:= <<"in">>],
    expect(length(Out) =:= 3, "three out-events (deposit, duty, other costs)"),
    expect(length(In) =:= 1, "exactly one in-event (the grant only)"),

    Dep = find(<<"deposit">>, Events),
    expect(maps:get(<<"phase">>, Dep) =:= <<"contract">>, "deposit placed at contract"),
    expect(maps:get(<<"counterparty">>, Dep) =:= <<"other">>, "deposit counterparty=other"),
    expect(maps:get(<<"source_component">>, Dep) =:= <<"cash_position">>, "deposit owned by cash_position"),
    %% 5% of [600k,700k] = [30000, 35000]
    expect(maps:get(<<"amount">>, Dep) =:= [30000, 35000], "deposit = 5% of range"),

    Duty = find(<<"stamp_duty">>, Events),
    expect(maps:get(<<"phase">>, Duty) =:= <<"settle">>, "duty placed at settle"),
    expect(maps:get(<<"counterparty">>, Duty) =:= <<"government">>, "duty counterparty=government"),
    [DLo, DHi] = maps:get(<<"amount">>, Duty),
    expect(DLo =:= DHi andalso is_integer(DLo), "duty is a collapsed point [v,v]"),
    expect(maps:get(<<"is_estimate">>, Duty) =:= false, "duty is not an estimate (regulated)"),

    Costs = find(<<"other_buying_costs">>, Events),
    expect(maps:get(<<"is_estimate">>, Costs) =:= true, "other costs flagged estimate (banded)"),

    [Grant] = In,
    expect(id(Grant) =:= <<"grant_1">>, "grant id is grant_1"),
    expect(maps:get(<<"phase">>, Grant) =:= <<"settle">>, "grant received at settle"),
    expect(maps:get(<<"counterparty">>, Grant) =:= <<"government">>, "grant counterparty=government"),
    expect(maps:get(<<"source_component">>, Grant) =:= <<"eligibility">>,
           "grant provenance = eligibility (placed, not owned by cash_position)"),
    expect(maps:get(<<"amount">>, Grant) =:= [0, 10000], "grant amount placed verbatim"),

    %% no-double-count: no in-event traces to the duty concession or FHG
    expect(length([E || E <- In, maps:get(<<"amount">>, E) =:= [20000, 22000]]) =:= 0,
           "duty concession is NOT an in-event (netted into duty out)"),
    expect(length([E || E <- In, maps:get(<<"amount">>, E) =:= [12000, 18000]]) =:= 0,
           "FHG (avoided LMI) is NOT an in-event"),

    %% every event carries a bilingual label with both locales
    expect(lists:all(fun(E) ->
        L = maps:get(<<"label">>, E),
        is_map(L) andalso is_binary(maps:get(<<"vi">>, L, undefined))
                   andalso is_binary(maps:get(<<"en">>, L, undefined))
    end, Events), "every event label is bilingual {vi,en}"),

    %% --- honest-partial: no state -> the state-dependent events drop ----------
    %% deposit (needs only the price range) and the grant (from scheme_stack) still
    %% place; duty + other_buying_costs need a state -> their figures are null -> the
    %% events are omitted (the figure is the event; no figure, no event). Never a
    %% null-amount event.
    Args2 = #{onboarding => #{}},
    {Outcome2, _, _} = fh_engine_cash:fill(Args2, Upstream),
    Events2 = maps:get(<<"cash_events">>, Outcome2),
    Ids2 = lists:sort([id(E) || E <- Events2]),
    expect(Ids2 =:= [<<"deposit">>, <<"grant_1">>],
           "no state -> only state-independent events place (deposit + grant); duty/costs drop"),
    expect(lists:all(fun(E) -> maps:get(<<"amount">>, E) =/= null end, Events2),
           "no null-amount events ever emitted"),

    %% --- the commit-seam gate accepts the outcome (runs in the turn, not fill/2) --
    ok = fh_engine_outcome:validate(<<"fhb-domestic-au">>, <<"budget_envelope">>, Outcome),
    expect(true, "outcome-conformance gate passes budget_envelope (incl. cash_events)"),

    io:format("~nALL ASSERTIONS PASSED~n"),
    ok.

id(E) -> maps:get(<<"id">>, E).
en(L) -> maps:get(<<"en">>, L).

find(Id, Events) ->
    [E] = [E || E <- Events, maps:get(<<"id">>, E) =:= Id],
    E.

expect(true, Msg)  -> io:format("  ok: ~s~n", [Msg]);
expect(false, Msg) -> io:format("  FAIL: ~s~n", [Msg]), halt(1).
