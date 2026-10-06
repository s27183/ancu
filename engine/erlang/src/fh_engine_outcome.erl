-module(fh_engine_outcome).

%% Layer-1 outcome conformance — the structural, producer- and mode-agnostic
%% post-condition at the fh_engine_turn commit seam (outcome-conformance.md). EVERY
%% fill (resolver, two-path merge, future 2c answer, refine turn, curator brief)
%% crosses this seam on its way to plan_cards.content_jsonb + the component_filled
%% event, so enforcing the invariant HERE holds it for any workflow that routes
%% content through the engine — which, by construction, is all of them.
%%
%% The invariant: every field of a fill matches its declared outcome_schema type. The
%% compiler materializes each outcome type as a parsed {kind} tree (registry.outcome_types,
%% via parse_field_type) so this consumer WALKS A TREE and never re-parses type strings
%% (materialize-parse-once; the byte-fragile Erlang side stays out of the parsing business).
%%
%% Three load-bearing clauses; everything else passes gracefully:
%%   - localized → every required locale present, each a non-empty binary, and the
%%     locales PAIRWISE-DISTINCT (the locale-agnostic anti-fallback — catches English
%%     copied into the `vi` slot). The vi-diacritic heuristic is deliberately NOT applied
%%     here: it is vi-specific and stays in the build/eval layer, never load-bearing at the
%%     fail-closed seam (outcome-conformance.md §3).
%%   - enum → value is one of the declared options.
%%   - figure (money/money_range/percentage_range/money_per_year/number/integer/integer_0_10)
%%     → numbers all the way down: never a binary ("$500k"), never a {vi,en} map. This IS the
%%     §98 guard, generalized — the agent cannot smuggle an authored figure past the schema.
%%     The *_range types are a [lo, hi] list (the banded surface, mode-c-wedge Slice B0).
%%
%% Nullability is implicit-universal: `null` conforms to ANY field (honest-partial fills
%% leave genuinely-unknown facts absent). string/bool/date/object scalars and `unknown`
%% kinds are NOT checked at runtime (the compiler's §3 string-nudge covers prose mistyped
%% as `string` at BUILD time; runtime stays graceful so a name-only sub-field never crashes
%% a turn).
%%
%% FAIL-CLOSED (§7): a non-conforming fill is `error/1` — it crashes the supervised turn
%% (let it surface, don't swallow; the OTP idiom). The reference spec + the shared case set
%% live in tests/outcome_validate.py; engine/erlang/test/outcome_conformance.escript runs the
%% SAME cases through check/3 and asserts identical conform/reject verdicts (the cross-language
%% lockstep — reason text is informative, the VERDICT is contractual).
%%
%% Bilingual -> P-7 · One declaration per outcome shape -> The engine -> fail-closed retype limit
%% Because this validator is fail-closed, a declaration can only be tightened as far as the
%% producer already emits: re-type a field `string` -> `localized_text` only where the
%% producer already writes a {vi, en} pair, or every fill of that component crashes its turn.
%% Concluded at 2b-4a from the fail-closed clause above (no runtime probe).

-export([validate/3, check/3, check_placement/2]).

%% The numeric family (§98). money_range / percentage_range are a [lo, hi] list of numbers;
%% the rest a bare number. string/bool/date/object are scalars too but are NOT figures.
-define(FIGURE_TYPES,
        [<<"money">>, <<"money_per_year">>, <<"number">>,
         <<"integer">>, <<"integer_0_10">>]).

%% §13 placement vocabulary — the money-flow markers/directions a placed element carries.
%% A cash_event carries `direction` (out/in); a swimlane cell carries `flow_marker`.
-define(MONEY_MARKERS,     [<<"money_out">>, <<"money_in">>]).
-define(NONMONEY_MARKERS,  [<<"none">>, <<"document">>, <<"milestone">>]).
-define(MONEY_DIRECTIONS,  [<<"out">>, <<"in">>]).

%% --- seam entry -------------------------------------------------------------

%% Look up the component's declared outcome type-tree from the artifact and walk the
%% fill against it. A type the artifact does not declare is refused
%% ({outcome_undeclared, Slug, Type}); every component's shape is declared, which
%% the compiler's GATE 12 enforces at build (P-7).
%%
%% Reproducible -> P-7 · One declaration per outcome shape -> The engine -> undeclared outcome refused
%% Until 2026-10-06 an undeclared type passed here unchecked, and the compiler did not
%% require a declaration: measured 2026-07-05, the registry held 2 of 13 types for
%% nexthome-domestic-au; measured 2026-10-06, six foreign-mode components compiled null.
%% Now GATE 12 fails the build on any of them (measured 2026-10-06: one schema block
%% removed → exit 1, artifact untouched), so this refusal is the backstop for a stale
%% artifact or a renamed type (Son, 2026-10-06, #25).
-spec validate(binary(), binary(), map()) -> ok.
validate(BlueprintSlug, OutcomeType, Outcome) ->
    OutcomeTypes = fh_engine_kb:registry(BlueprintSlug, <<"outcome_types">>),
    case maps:find(OutcomeType, OutcomeTypes) of
        error ->
            %% Undeclared: refused, not passed (P-7; Son, 2026-10-06, #25). The compiler's
            %% GATE 12 already fails the build on a component with no declared shape, so
            %% this is the backstop — reached only by a type the turn names that the
            %% loaded artifact does not declare (a stale artifact, a renamed type).
            error({outcome_undeclared, BlueprintSlug, OutcomeType});
        {ok, Fields} ->
            Locales = fh_engine_kb:locales(),
            case validate_fields(maps:to_list(Fields), Outcome, Locales) of
                ok ->
                    %% §13 placement/provenance clause — the same total-walk, a new clause.
                    %% Runs only when a schema exists (graceful otherwise, like the type walk).
                    case check_placement(Outcome, component_names(BlueprintSlug)) of
                        ok ->
                            ok;
                        {error, R} ->
                            error({outcome_nonconforming, OutcomeType, <<"placement">>, R})
                    end;
                {error, Field, Reason} ->
                    error({outcome_nonconforming, OutcomeType, Field, Reason})
            end
    end.

%% The set of real component names in the card's compiled blueprint — the ground truth
%% for §13 check 1 (provenance resolves). Empty (no artifact) ⟹ check 1 is graceful (it
%% has nothing to resolve against), consistent with the missing-schema pass-through.
component_names(BlueprintSlug) ->
    case fh_engine_kb:components(BlueprintSlug) of
        {ok, Comps} -> [maps:get(<<"name">>, C) || C <- Comps];
        _           -> []
    end.

validate_fields([], _Outcome, _Locales) ->
    ok;
validate_fields([{Field, Tree} | Rest], Outcome, Locales) ->
    Value = maps:get(Field, Outcome, null),
    case check(Tree, Value, Locales) of
        ok         -> validate_fields(Rest, Outcome, Locales);
        {error, R} -> {error, Field, R}
    end.

%% --- the pure recursive walk (mirror of tests/outcome_validate.py:check) ----

-spec check(map(), term(), [binary()]) -> ok | {error, binary()}.
check(_Tree, null, _Locales) ->
    ok;  %% implicit-universal nullability
check(#{<<"kind">> := <<"localized">>}, Value, Locales) ->
    check_localized(Value, Locales);
check(#{<<"kind">> := <<"enum">>, <<"options">> := Options}, Value, _Locales) ->
    case lists:member(Value, Options) of
        true  -> ok;
        false -> {error, reason(<<"enum value not in options">>, Value)}
    end;
check(#{<<"kind">> := <<"scalar">>, <<"type">> := Type}, Value, _Locales) ->
    check_scalar(Type, Value);
check(#{<<"kind">> := <<"array">>, <<"element">> := El}, Value, Locales)
  when is_list(Value) ->
    check_array(El, Value, Locales, 0);
check(#{<<"kind">> := <<"array">>}, Value, _Locales) ->
    {error, reason(<<"expected array">>, Value)};
check(#{<<"kind">> := <<"object">>, <<"fields">> := Fields}, Value, Locales)
  when is_map(Value) ->
    check_object(maps:to_list(Fields), Value, Locales);
check(#{<<"kind">> := <<"object">>}, Value, _Locales) ->
    {error, reason(<<"expected object">>, Value)};
check(_Tree, _Value, _Locales) ->
    ok.  %% unknown / unrecognized kind — graceful

%% --- clauses ----------------------------------------------------------------

check_localized(Value, Locales) when is_map(Value) ->
    case collect_locales(Locales, Value, []) of
        {error, R} ->
            {error, R};
        {ok, Vals} ->
            case length(lists:usort(Vals)) =:= length(Vals) of
                true  -> ok;
                false -> {error, <<"localized locales not pairwise-distinct">>}
            end
    end;
check_localized(Value, _Locales) ->
    {error, reason(<<"localized field must be a {locale} map">>, Value)}.

collect_locales([], _Value, Acc) ->
    {ok, lists:reverse(Acc)};
collect_locales([Loc | Rest], Value, Acc) ->
    case maps:find(Loc, Value) of
        error ->
            {error, <<"localized missing locale ", Loc/binary>>};
        {ok, S} when is_binary(S) ->
            case is_blank(S) of
                true  -> {error, <<"localized locale ", Loc/binary, " empty">>};
                false -> collect_locales(Rest, Value, [S | Acc])
            end;
        {ok, _} ->
            {error, <<"localized locale ", Loc/binary, " non-string">>}
    end.

%% Regulated figures are grounded -> P-7 · One declaration per outcome shape -> The engine -> figure type follows derivation
%% A registry figure is typed `*_range` iff it is derived from a range input, and scalar iff
%% it is an exact-point computation; a phase-polymorphic field is typed `*_range` and emits
%% [V, V] when exact. This strict two-way check bounds where a mismatch can surface.
%% Concluded 2026-06 (stated before only in mode-c-wedge.md).
check_scalar(Type, Value) when Type =:= <<"money_range">>; Type =:= <<"percentage_range">> ->
    %% a banded figure — a [lo, hi] list of numbers (the banded money/percentage surface,
    %% mode-c-wedge Slice B0: rent is a band, so income/yields/cash-flow built on it band too).
    case is_list(Value) andalso lists:all(fun erlang:is_number/1, Value) of
        true  -> ok;
        false -> {error, reason(<<Type/binary, " must be a list of numbers">>, Value)}
    end;
check_scalar(Type, Value) ->
    case lists:member(Type, ?FIGURE_TYPES) of
        true ->
            case is_number(Value) of
                true  -> ok;
                false -> {error, <<Type/binary, " must be a number">>}
            end;
        false ->
            ok  %% string / bool / date / object — graceful (not a figure)
    end.

check_array(_El, [], _Locales, _I) ->
    ok;
check_array(El, [H | T], Locales, I) ->
    case check(El, H, Locales) of
        ok ->
            check_array(El, T, Locales, I + 1);
        {error, R} ->
            {error, <<"[", (integer_to_binary(I))/binary, "] ", R/binary>>}
    end.

check_object([], _Value, _Locales) ->
    ok;
check_object([{Field, Tree} | Rest], Value, Locales) ->
    Sub = maps:get(Field, Value, null),
    case check(Tree, Sub, Locales) of
        ok         -> check_object(Rest, Value, Locales);
        {error, R} -> {error, <<".", Field/binary, " ", R/binary>>}
    end.

%% --- §13 placement & provenance (the two-spines clause) ---------------------
%%
%% A SEMANTIC pass over the whole outcome (not the type-tree walk): the two-spines model
%% adds PLACED figures — an outcome carries figures it did not compute, tagged with
%% provenance and money-flow fields. The invariant: *a placement carries provenance and
%% introduces no figure of its own* (outcome-conformance.md §13; lifecycle-simulation-model
%% §2). Field-name driven, so it attaches to the INVARIANT wherever it appears — every
%% cash_event / cell across any mode — not to a hardcoded outcome list ([[enforce-invariants-
%% not-workflows]] discover-don't-enumerate). Four checks; each stays single-outcome (§5):
%%   1. Provenance resolves — every element's `source_component` is a real component.
%%   2. Money flow ⟹ counterparty — a `direction`-bearing (cash_event) or money `flow_marker`
%%      (cell) element carries a counterparty; the inverse: a non-money cell carries neither
%%      counterparty nor amount.
%%   3. Interactions derive, not invent — every interactions[].flows[] entry matches a placed
%%      money cell (phase, direction, amount) in the same outcome.
%%   4. Figure-type still applies to each placed amount — already covered by the type walk.
-spec check_placement(map(), [binary()]) -> ok | {error, binary()}.
check_placement(Outcome, Components) ->
    case walk_elements(Outcome, Components) of
        ok  -> check_interactions(Outcome);
        Err -> Err
    end.

%% recurse every nested map/list; check each map as a placement element (checks 1 + 2).
walk_elements(M, Components) when is_map(M) ->
    case check_element(M, Components) of
        {error, R} -> {error, R};
        ok         -> walk_list(maps:values(M), Components)
    end;
walk_elements(L, Components) when is_list(L) ->
    walk_list(L, Components);
walk_elements(_, _) ->
    ok.

walk_list([], _) -> ok;
walk_list([H | T], Components) ->
    case walk_elements(H, Components) of
        ok  -> walk_list(T, Components);
        Err -> Err
    end.

check_element(M, Components) ->
    case provenance(M, Components) of
        {error, R} ->
            {error, R};
        ok ->
            %% checks 2 govern PLACED elements (those carrying provenance). A derived
            %% interaction flow has `direction` but no source_component → check 3 governs
            %% it; skip here so its absent counterparty is not a false positive.
            case maps:get(<<"source_component">>, M, null) of
                S when is_binary(S) -> money_flow(M);
                _                   -> ok
            end
    end.

%% check 1: a present source_component must name a real component (skip when the component
%% set is unavailable — nothing to resolve against).
provenance(M, Components) ->
    case maps:get(<<"source_component">>, M, null) of
        S when is_binary(S), Components =/= [] ->
            case lists:member(S, Components) of
                true  -> ok;
                false -> {error, <<"source_component not a real component: ", S/binary>>}
            end;
        _ ->
            ok
    end.

%% check 2 (+ inverse): a money flow carries a counterparty; a non-money cell carries none.
money_flow(M) ->
    Dir    = maps:get(<<"direction">>, M, null),
    Marker = maps:get(<<"flow_marker">>, M, null),
    Cp     = maps:get(<<"counterparty">>, M, null),
    Amount = maps:get(<<"amount">>, M, null),
    case lists:member(Dir, ?MONEY_DIRECTIONS) andalso Cp =:= null of
        true ->
            {error, <<"money flow (cash_event) has no counterparty">>};
        false ->
            case lists:member(Marker, ?MONEY_MARKERS) of
                true when Cp =:= null ->
                    {error, <<"money cell has no counterparty">>};
                true ->
                    ok;
                false ->
                    nonmoney_cell(Marker, Cp, Amount)
            end
    end.

nonmoney_cell(Marker, Cp, Amount) ->
    case lists:member(Marker, ?NONMONEY_MARKERS) of
        true when Cp =/= null     -> {error, <<"non-money cell carries a counterparty">>};
        true when Amount =/= null -> {error, <<"non-money cell carries an amount">>};
        _                         -> ok
    end.

%% check 3: every interaction flow corresponds to a placed money cell in the same outcome.
check_interactions(Outcome) ->
    Interactions = maps:get(<<"interactions">>, Outcome, null),
    Cells        = maps:get(<<"cells">>, Outcome, null),
    case is_list(Interactions) andalso is_list(Cells) of
        false -> ok;
        true  -> check_flows(Interactions, placed_cells(Cells))
    end.

%% the set of placed money cells keyed (phase, direction, amount) — the flow's source.
placed_cells(Cells) ->
    lists:foldl(
      fun(C, Acc) when is_map(C) ->
              case marker_dir(maps:get(<<"flow_marker">>, C, null)) of
                  null -> Acc;
                  D    -> [{maps:get(<<"phase">>, C, null), D,
                            maps:get(<<"amount">>, C, null)} | Acc]
              end;
         (_, Acc) -> Acc
      end, [], Cells).

marker_dir(<<"money_out">>) -> <<"out">>;
marker_dir(<<"money_in">>)  -> <<"in">>;
marker_dir(_)               -> null.

check_flows([], _) -> ok;
check_flows([Ix | Rest], Placed) when is_map(Ix) ->
    Phase = maps:get(<<"phase">>, Ix, null),
    case check_flow_list(maps:get(<<"flows">>, Ix, []), Phase, Placed) of
        ok  -> check_flows(Rest, Placed);
        Err -> Err
    end;
check_flows([_ | Rest], Placed) ->
    check_flows(Rest, Placed).

check_flow_list([], _, _) -> ok;
check_flow_list([F | Rest], Phase, Placed) when is_map(F) ->
    Key = {Phase, maps:get(<<"direction">>, F, null), maps:get(<<"amount">>, F, null)},
    case lists:member(Key, Placed) of
        true  -> check_flow_list(Rest, Phase, Placed);
        false -> {error, <<"interaction flow has no corresponding placed cell">>}
    end;
check_flow_list([_ | Rest], Phase, Placed) ->
    check_flow_list(Rest, Phase, Placed).

%% --- internals --------------------------------------------------------------

%% A binary is blank if empty or whitespace-only. (~p, not ~s, in reason/2 — ~s on a
%% >255-codepoint Vietnamese binary is the crash trap; ~p byte-escapes safely.)
is_blank(S) ->
    case string:trim(S) of
        <<>> -> true;
        ""   -> true;
        _    -> false
    end.

reason(Msg, Value) ->
    iolist_to_binary([Msg, ": ", io_lib:format("~p", [Value])]).
