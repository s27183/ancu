#!/usr/bin/env escript
%%! -sname fh_bilingual_conformance
%%
%% Bilingual-content conformance (bilingual-content.md §7). Asserts the THREE
%% postconditions over the real mortgage + eligibility fills (the mortgage+eligibility
%% subset, 2g-4), loading the same materialized artifact the engine loads:
%%
%%   1. Both present, non-empty   — every user-facing free-text field is {vi, en}.
%%   2. vi is actually Vietnamese — vi =/= en AND vi carries a Vietnamese diacritic
%%                                  (a >127 UTF-8 byte). Catches an English string
%%                                  silently copied into the vi slot (English is ASCII).
%%   3. Figures/enums single-source — a number/enum/null field is NOT a {vi,en} map
%%                                  (no figure duplicated per language; §98 untouched).
%%
%% The vi-is-Vietnamese check is a heuristic tuned to OUR authored copy (every vi
%% string carries diacritics). Its boundary: a vi string that is legitimately all-ASCII
%% (e.g. only proper nouns) would false-fail — none exist in the current copy; if one is
%% added, relax the diacritic clause for that template and keep vi =/= en.
%%
%% Run from engine/erlang (no Postgres needed):
%%   ERL_LIBS=_build/default/lib escript test/bilingual_conformance.escript

-mode(compile).

main(_) ->
    ok = fh_engine_kb:load(),
    io:format("bilingual conformance — mortgage + eligibility + cash + ownership "
              "(bilingual-content.md §7)~n~n"),
    R = lists:flatten([mortgage_cases(), eligibility_cases(),
                       cash_cases(), ownership_cases()]),
    Fails = [X || X <- R, X =:= fail],
    io:format("~n================================================================~n"),
    case Fails of
        [] -> io:format("PASS — all ~p bilingual anchors green~n", [length(R)]), halt(0);
        _  -> io:format("FAIL — ~p anchor(s) mismatched~n", [length(Fails)]), halt(1)
    end.

%% --- mortgage --------------------------------------------------------------- %

mortgage_cases() ->
    {Outcome, _R, _Kb} = fh_engine_mortgage:fill(
        #{}, #{<<"profile">> => #{}, <<"scheme_stack">> => stack_fhg()}),
    KA = maps:get(<<"key_assumptions">>, Outcome),
    AP = maps:get(<<"pre_approval_action_plan">>, Outcome),
    [ %% (1)+(2): every assumption + action item is bilingual Vietnamese
      [loc_ok(io_lib:format("key_assumptions[~p]", [I]), V) || {I, V} <- enum(KA)],
      [loc_ok(io_lib:format("action_plan[~p]", [I]), V) || {I, V} <- enum(AP)],
      %% the buffer figure interpolated identically into BOTH languages (subst scalar):
      %% exactly one assumption mentions "3.0" and it is present in vi AND en.
      buffer_interpolated(KA),
      %% (3): capacity is a single-source scalar (null), never a {vi,en} map (§98)
      scalar_ok("expected_borrowing_capacity", maps:get(<<"expected_borrowing_capacity">>, Outcome)),
      %% merge preserves a bilingual agent reasoning untouched (slot-scoped)
      merge_preserves_bilingual() ].

%% the merge folds the agent's {vi,en} reasoning in without altering it.
merge_preserves_bilingual() ->
    {Resolver, _R, _Kb} = fh_engine_mortgage:fill(
        #{}, #{<<"profile">> => #{}, <<"scheme_stack">> => stack_fhg()}),
    Reasoning = #{<<"vi">> => <<"Ngân hàng lớn, có thể so sánh."/utf8>>,
                  <<"en">> => <<"A major lender; comparable.">>},
    Agent = #{<<"recommended_lender_shortlist">> =>
                  [#{<<"lender">> => <<"X">>, <<"reasoning">> => Reasoning,
                     <<"approval_likelihood">> => <<"indicative">>}],
              <<"fixed_vs_variable">> => <<"variable">>},
    Merged = fh_engine_mortgage:merge_agent(Resolver, Agent),
    [Rec | _] = maps:get(<<"recommended_lender_shortlist">>, Merged),
    loc_ok("merged lender reasoning", maps:get(<<"reasoning">>, Rec)).

%% --- eligibility ------------------------------------------------------------ %

eligibility_cases() ->
    %% an eligible single Mode-A FHB (applicable schemes with bilingual notes)
    {Elig, _R1, _K1} = fh_engine_eligibility:fill(
        #{onboarding => #{<<"state">> => <<"NSW">>}}, eligible_profile()),
    Applicable = maps:get(<<"applicable_schemes">>, Elig),
    Stacking   = maps:get(<<"stacking_constraints">>, Elig),
    %% a rejected case (every applicant owns property -> reject reasons)
    {Rej, _R2, _K2} = fh_engine_eligibility:fill(
        #{onboarding => #{<<"state">> => <<"NSW">>}}, rejected_profile()),
    Rejected = maps:get(<<"rejected_schemes">>, Rej),
    [ %% (1)+(2): notes / reasons / stacking are bilingual Vietnamese
      [ [loc_ok(io_lib:format("applicable[~p].notes[~p]", [I, J]), N)
         || {J, N} <- enum(maps:get(<<"notes">>, S))]
        || {I, S} <- enum(Applicable)],
      [loc_ok(io_lib:format("stacking_constraints[~p]", [I]), V) || {I, V} <- enum(Stacking)],
      [loc_ok(io_lib:format("rejected[~p].reason", [I]), maps:get(<<"reason">>, S))
       || {I, S} <- enum(Rejected)],
      %% (3): enums/figures single-source — eligibility_basis enum, benefit_value scalar
      scalar_ok("eligibility_basis (enum)", maps:get(<<"eligibility_basis">>, Elig)),
      [scalar_ok(io_lib:format("applicable[~p].benefit_value", [I]),
                 maps:get(<<"benefit_value">>, S)) || {I, S} <- enum(Applicable)] ].

%% --- cash_position ---------------------------------------------------------- %

cash_cases() ->
    %% NSW with a stamp-duty concession in the stack and a ceiling that yields a
    %% positive saving -> the duty note is the "concession applied" bilingual template;
    %% key_assumptions carries the stamp-only + ceiling assumptions.
    {Conc, _R1, _K1} = fh_engine_cash:fill(
        #{onboarding => #{<<"state">> => <<"NSW">>}}, cash_upstream(true, [800000, 850000])),
    SdC = maps:get(<<"stamp_duty">>, Conc),
    KA  = maps:get(<<"key_assumptions">>, Conc),
    %% no concession in the stack -> the "full duty" bilingual note.
    {Full, _R2, _K2} = fh_engine_cash:fill(
        #{onboarding => #{<<"state">> => <<"NSW">>}}, cash_upstream(false, [800000, 850000])),
    SdF = maps:get(<<"stamp_duty">>, Full),
    [ %% (1)+(2): duty notes (both paths) + assumptions are bilingual Vietnamese
      [loc_ok(io_lib:format("cash.concession.notes[~p]", [I]), N)
       || {I, N} <- enum(maps:get(<<"notes">>, SdC))],
      [loc_ok(io_lib:format("cash.full_duty.notes[~p]", [I]), N)
       || {I, N} <- enum(maps:get(<<"notes">>, SdF))],
      [loc_ok(io_lib:format("cash.key_assumptions[~p]", [I]), V) || {I, V} <- enum(KA)],
      %% (3): the duty figures are single-source scalars, never {vi,en} maps (§98)
      scalar_ok("cash.before_concession", maps:get(<<"before_concession">>, SdC)),
      scalar_ok("cash.concession_applied", maps:get(<<"concession_applied">>, SdC)),
      scalar_ok("cash.after_concession", maps:get(<<"after_concession">>, SdC)) ].

%% --- ownership_planning ----------------------------------------------------- %

ownership_cases() ->
    %% FHG in the stack + owner-occupier -> all three lifecycle alerts armed, each a
    %% {trigger, action} pair of bilingual prose; recurring notes bilingual.
    {Own, _R, _K} = fh_engine_ownership:fill(
        #{onboarding => #{<<"state">> => <<"NSW">>, <<"target_price_range">> => [600000, 700000]},
          intent => <<"owner_occupier">>},
        #{<<"scheme_stack">> => #{<<"applicable_schemes">> =>
              [#{<<"role">> => <<"deposit_guarantee">>}]}}),
    Alerts = maps:get(<<"alert_triggers_armed">>, Own),
    Recurring = maps:get(<<"recurring_costs_estimate">>, Own),
    Notes = maps:get(<<"notes">>, Recurring),
    [ %% (1)+(2): each alert's trigger AND action are bilingual; recurring notes bilingual
      [ [loc_ok(io_lib:format("ownership.alert[~p].trigger", [I]), maps:get(<<"trigger">>, A)),
         loc_ok(io_lib:format("ownership.alert[~p].action", [I]), maps:get(<<"action">>, A))]
        || {I, A} <- enum(Alerts)],
      [loc_ok(io_lib:format("ownership.recurring.notes[~p]", [I]), N) || {I, N} <- enum(Notes)],
      %% (3): figures single-source — maintenance target + the statutory band bounds
      scalar_ok("ownership.maintenance_reserve_target",
                maps:get(<<"maintenance_reserve_target">>, Own)),
      scalar_ok("ownership.statutory_band.low",
                maps:get(<<"low">>, maps:get(<<"statutory_band">>, Recurring))) ].

%% --- postcondition checks --------------------------------------------------- %

%% (1)+(2): {vi,en}, both non-empty binaries, vi =/= en, vi carries a diacritic.
loc_ok(Label, #{<<"vi">> := Vi, <<"en">> := En})
  when is_binary(Vi), is_binary(En), byte_size(Vi) > 0, byte_size(En) > 0 ->
    case Vi =/= En andalso has_non_ascii(Vi) of
        true  -> ok(Label);
        false -> bad(Label, {vi, Vi, en, En})
    end;
loc_ok(Label, Other) -> bad(Label, {not_localized, Other}).

%% (3): a single-source scalar — NOT a {vi,en} map.
scalar_ok(Label, V) when is_map(V) ->
    case maps:is_key(<<"vi">>, V) of
        true  -> bad(Label, {unexpected_bilingual, V});
        false -> ok(Label)
    end;
scalar_ok(Label, _V) -> ok(Label).

%% the buffer figure (3.0) is interpolated into both halves of exactly one assumption.
buffer_interpolated(KA) ->
    Hits = [V || V <- KA,
                 binary:match(maps:get(<<"vi">>, V), <<"3.0">>) =/= nomatch,
                 binary:match(maps:get(<<"en">>, V), <<"3.0">>) =/= nomatch],
    case Hits of
        [_] -> ok("assume_buffer: 3.0 interpolated into vi AND en");
        _   -> bad("assume_buffer: 3.0 interpolated into vi AND en", {hits, length(Hits)})
    end.

has_non_ascii(Bin) -> lists:any(fun(B) -> B > 127 end, binary_to_list(Bin)).

ok(Label)       -> io:format("  PASS   ~s~n", [Label]), pass.
bad(Label, Why) -> io:format("  FAIL   ~s — ~p~n", [Label, Why]), fail.

enum(L) -> lists:zip(lists:seq(0, length(L) - 1), L).

%% --- fixtures --------------------------------------------------------------- %

stack_fhg() ->
    #{<<"applicable_schemes">> => [#{<<"role">> => <<"deposit_guarantee">>}]}.

%% cash upstream: a profile with a target range + a scheme_stack that does (or does
%% not) carry a stamp-duty concession (role stamp_duty_concession) — the gate on the
%% concession note path.
cash_upstream(HasConc, Range) ->
    Schemes = case HasConc of
                  true  -> [#{<<"role">> => <<"stamp_duty_concession">>}];
                  false -> []
              end,
    #{<<"profile">> => #{<<"target_price_range">> => Range, <<"state">> => <<"NSW">>},
      <<"scheme_stack">> => #{<<"applicable_schemes">> => Schemes}}.

eligible_profile() ->
    #{<<"profile">> => #{<<"applicants">> =>
          [#{<<"citizenship_status">> => <<"citizen">>, <<"age">> => 30,
             <<"ever_owned_au_property">> => false, <<"owner_occupier_intent">> => true,
             <<"currently_owns_property">> => false, <<"prior_fhss_release">> => false}],
      <<"target_price_range">> => [600000, 700000]}}.

rejected_profile() ->
    #{<<"profile">> => #{<<"applicants">> =>
          [#{<<"citizenship_status">> => <<"citizen">>, <<"age">> => 40,
             <<"ever_owned_au_property">> => true, <<"owner_occupier_intent">> => true,
             <<"currently_owns_property">> => false, <<"prior_fhss_release">> => false}],
      <<"target_price_range">> => [600000, 700000]}}.
