-module(fh_engine_resolver).

%% The declarative rule interpreter — the deterministic resolver for content_json
%% `fills` rules (kind ∈ criteria | lookup | parameter). agentic-flow §1/§6: the
%% resolver runs Erlang-side inside the turn, reads KB-as-rules directly (no prompt,
%% no LLM, no usage). agentic-boundary.md is the rule for which leaves are resolver.
%%
%% THREE-VALUED (Kleene) — docs/architecture/resolver-semantics.md. A fact is a
%% possibility set: a scalar (pinned), a SET #{<<"oneof">> => [V,...]} (one of these,
%% unknown which — Mode A → citizenship {citizen, permanent_resident}), a RANGE
%% #{<<"range">> => [Lo, Hi]} (an interval over an ordered domain; Lo/Hi = null =
%% ∓∞), or absent (undefined). A criterion over a possibility set is three-valued:
%% `true` if it holds for ALL the set's values, `false` for NONE, else `undetermined`.
%% Combinators are strong Kleene (all_of → false if any false, else undetermined if
%% any undetermined, else true; any_of dual). An absent fact (undefined) → undetermined;
%% an unresolved threshold (Rhs null|undefined — e.g. the FHG cap lookup defaulting to
%% null when location_tier is absent) → undetermined (closes G3 — no spurious pass).
%% The verdict is policy-free; each CONSUMER collapses (eligibility undetermined →
%% applicable-pending; the compliance gate undetermined → deny, fail-closed).
%%
%% Backward-compat (resolver-semantics §5): when every referenced fact is a pinned
%% scalar, cmp/3 returns exactly true|false and never undetermined.
%%
%% CONFORMANCE: a 1:1 port of the executable spec tests/resolver_eval.py (Resolver /
%% _cmp / _sat / _cmp_range / K3 / token resolution). The two must stay in semantic
%% lockstep; engine/erlang/test/resolver_conformance.escript runs the spec's worked
%% examples against THIS module and asserts identical three-valued outcomes.
%%
%% Two entry points, by leaf semantics (the §11.9 applicant.* repoint):
%%   - eval_joint/3   — a JOINT leaf (eligibility.*): evaluated per applicant and
%%     Kleene-∀-combined. The consumer collapses the verdict.
%%   - eval_applicants/3 — a PER-APPLICANT leaf (FHSS by the KB `resolution` marker;
%%     applicant.firb_required): one three-valued verdict PER applicant, no collapse.
%%     The eligibility consumer derives eligible_applicants from it (the F13 close);
%%     buyer_profile collapses applicant.firb_required into profile.firb_required_any.
%%
%% Facts shape (binary-keyed maps, mirroring the spec's fact-set):
%%   #{<<"applicants">> => [#{<<field>> => Possibility, ...}, ...],  %% 1..N; [] -> [#{}]
%%     <<"property_fit">> => #{...}, <<"profile">> => #{...},
%%     <<"locals">> => #{<<bare_token>> => V, ...},   %% resolver-local intermediates
%%     <<"refs">>   => #{<<leaf>> => V, ...}}          %% pre-supplied refs
%% A Possibility is a scalar, #{<<"oneof">> => [...]}, #{<<"range">> => [Lo,Hi]}, or
%% absent. A missing fact (key absent) → undetermined (the resolver never invents a
%% pass, and no longer invents a fail either — it says "don't know").

-export([eval_joint/3, eval_applicants/3, eval_node_joint/3, eval_node_applicants/3]).

-type tri()   :: true | false | undetermined.
-type rules() :: #{binary() => map()}.
-type facts() :: map().

%% --- public entry points ----------------------------------------------------

-spec eval_joint(binary(), rules(), facts()) -> term().
eval_joint(Leaf, Rules, Facts) ->
    rule(get_rule(Leaf, Rules), Rules, Facts, [Leaf]).

-spec eval_applicants(binary(), rules(), facts()) -> [tri()].
eval_applicants(Leaf, Rules, Facts) ->
    Rule = get_rule(Leaf, Rules),
    [criteria(Rule, Rules, Facts, A, [Leaf]) || A <- applicants(Facts)].

%% Evaluate a raw criteria NODE (not a named leaf) — for the eligibility component's
%% base-partition evaluation (it partitions a scheme's criteria into base/property and
%% evals the base partition here). Refs inside resolve globally against Rules. Joint
%% Kleene-∀ across applicants; the per-applicant variant returns one verdict each.
-spec eval_node_joint(map(), rules(), facts()) -> tri().
eval_node_joint(Node, Rules, Facts) ->
    k3_all([criteria(Node, Rules, Facts, A, []) || A <- applicants(Facts)]).

-spec eval_node_applicants(map(), rules(), facts()) -> [tri()].
eval_node_applicants(Node, Rules, Facts) ->
    [criteria(Node, Rules, Facts, A, []) || A <- applicants(Facts)].

%% --- rule dispatch (mirrors resolver_eval._rule) ----------------------------

rule(#{<<"kind">> := <<"parameter">>} = Rule, _Rules, _Facts, _Stack) ->
    maps:get(<<"value">>, Rule, undefined);
rule(#{<<"kind">> := <<"lookup">>} = Rule, _Rules, Facts, _Stack) ->
    lookup(Rule, Facts);
rule(#{<<"kind">> := <<"criteria">>} = Rule, Rules, Facts, Stack) ->
    %% per-applicant Kleene-∀ (resolver_eval._criteria_joint)
    k3_all([criteria(Rule, Rules, Facts, A, Stack) || A <- applicants(Facts)]);
rule(Rule, _Rules, _Facts, _Stack) ->
    erlang:error({resolver_unknown_rule_kind, maps:get(<<"kind">>, Rule, undefined)}).

%% --- criteria (mirrors resolver_eval._criteria) — strong Kleene -------------

criteria(Node, Rules, Facts, Appl, Stack) ->
    Combine = maps:get(<<"combine">>, Node, <<"all_of">>),
    Results = [eval_crit(C, Rules, Facts, Appl, Stack)
               || C <- maps:get(<<"criteria">>, Node, [])],
    case Combine of
        <<"all_of">> -> k3_all(Results);
        <<"any_of">> -> k3_any(Results);
        Other        -> erlang:error({resolver_unknown_combine, Other})
    end.

eval_crit(#{<<"combine">> := _} = Nested, Rules, Facts, Appl, Stack) ->
    criteria(Nested, Rules, Facts, Appl, Stack);
eval_crit(Crit, Rules, Facts, Appl, Stack) ->
    Lhs = resolve_field(maps:get(<<"field">>, Crit), Facts, Appl),
    Rhs = case maps:is_key(<<"ref">>, Crit) of
              true  -> resolve_ref(maps:get(<<"ref">>, Crit), Rules, Facts, Stack);
              false -> maps:get(<<"value">>, Crit, undefined)
          end,
    cmp(maps:get(<<"op">>, Crit, undefined), Lhs, Rhs).

%% --- strong-Kleene (K3) combinators -----------------------------------------
%% A definite disqualifier wins over pending siblings (all_of → false); a definite
%% qualifier wins in any_of (→ true). This is the safety short-circuit: "pending"
%% never masks a real rejection.

k3_all(Results) ->
    case lists:member(false, Results) of
        true  -> false;
        false -> case lists:member(undetermined, Results) of
                     true  -> undetermined;
                     false -> true
                 end
    end.

k3_any(Results) ->
    case lists:member(true, Results) of
        true  -> true;
        false -> case lists:member(undetermined, Results) of
                     true  -> undetermined;
                     false -> false
                 end
    end.

%% --- lookup (mirrors resolver_eval._lookup) ---------------------------------

lookup(Rule, Facts) ->
    %% lookups read shared facts only (no applicant context).
    KeyVals = [resolve_field(Dim, Facts, #{}) || Dim <- maps:get(<<"key">>, Rule, [])],
    Rows = maps:get(<<"table">>, Rule, []),
    case lists:search(fun(Row) -> maps:get(<<"when">>, Row, undefined) =:= KeyVals end, Rows) of
        {value, Row} -> maps:get(<<"value">>, Row, undefined);
        false        -> maps:get(<<"default">>, Rule, undefined)
    end.

%% --- token resolution (mirrors resolver_eval._resolve_field/_resolve_ref) ----

resolve_field(Token, Facts, Appl) ->
    case binary:split(Token, <<".">>) of
        [_Bare] ->
            %% bare token — a resolver-local intermediate (e.g. location_tier)
            maps:get(Token, maps:get(<<"locals">>, Facts, #{}), undefined);
        [<<"applicant">>, Rest] ->
            maps:get(Rest, Appl, undefined);
        [Ns, Rest] ->
            case maps:get(Ns, Facts, undefined) of
                Scope when is_map(Scope) -> maps:get(Rest, Scope, undefined);
                _                        -> undefined
            end
    end.

resolve_ref(Ref, Rules, Facts, Stack) ->
    case lists:member(Ref, Stack) of
        true -> erlang:error({resolver_ref_cycle, Ref});
        false ->
            Refs = maps:get(<<"refs">>, Facts, #{}),
            case maps:is_key(Ref, Refs) of
                true -> maps:get(Ref, Refs);
                false ->
                    case maps:is_key(Ref, Rules) of
                        true  -> rule(maps:get(Ref, Rules), Rules, Facts, [Ref | Stack]);
                        false -> erlang:error({resolver_unresolved_ref, Ref})
                    end
            end
    end.

%% --- three-valued operator (mirrors resolver_eval._cmp) ---------------------
%% Absent fact (undefined) → undetermined; unresolved threshold (Rhs null|undefined)
%% → undetermined (G3). A scalar Lhs reduces to the two-valued predicate.

-spec cmp(binary(), term(), term()) -> tri().
cmp(_Op, undefined, _Rhs) -> undetermined;
cmp(_Op, _Lhs, undefined) -> undetermined;
cmp(_Op, _Lhs, null)      -> undetermined;
cmp(Op, Lhs, Rhs) when is_map(Lhs) ->
    case Lhs of
        #{<<"oneof">> := Members} -> oneof_cmp(Op, Members, Rhs);
        #{<<"range">>  := [Lo, Hi]} -> cmp_range(Op, Lo, Hi, Rhs);
        _ -> erlang:error({resolver_bad_possibility, Lhs})
    end;
cmp(Op, Lhs, Rhs) ->
    bool_to_tri(sat(Op, Lhs, Rhs)).

%% set: true if ALL members satisfy, false if NONE, else undetermined.
oneof_cmp(Op, Members, Rhs) ->
    Sats = [sat(Op, M, Rhs) || M <- Members],
    case lists:all(fun(X) -> X end, Sats) of
        true  -> true;
        false -> case lists:any(fun(X) -> X end, Sats) of
                     true  -> undetermined;
                     false -> false
                 end
    end.

%% range [Lo,Hi] (inclusive; null bound = unbounded) — the structural three-valued
%% relations. Helpers ask whether the WHOLE interval satisfies the ordered relation.
cmp_range(<<"gte">>, Lo, Hi, R) -> tri(lo_ge(Lo, R), hi_lt(Hi, R));
cmp_range(<<"gt">>,  Lo, Hi, R) -> tri(lo_gt(Lo, R), hi_le(Hi, R));
cmp_range(<<"lte">>, Lo, Hi, R) -> tri(hi_le(Hi, R), lo_gt(Lo, R));
cmp_range(<<"lt">>,  Lo, Hi, R) -> tri(hi_lt(Hi, R), lo_ge(Lo, R));
cmp_range(<<"eq">>,  Lo, Hi, R) ->
    Point = (Lo =/= null andalso Hi =/= null andalso Lo == R andalso Hi == R),
    Out   = below(Lo, R) orelse above(Hi, R),
    pick(Point, Out);
cmp_range(<<"neq">>, Lo, Hi, R) ->
    Point = (Lo =/= null andalso Hi =/= null andalso Lo == R andalso Hi == R),
    Out   = below(Lo, R) orelse above(Hi, R),
    %% neq is the negation of eq: false where eq is true, true where eq is false.
    pick(Out, Point);
cmp_range(<<"between">>, Lo, Hi, [A, B]) ->
    Within = (Lo =/= null andalso Lo >= A) andalso (Hi =/= null andalso Hi =< B),
    Outside = (Hi =/= null andalso Hi < A) orelse (Lo =/= null andalso Lo > B),
    tri(Within, Outside);
cmp_range(<<"between">>, _Lo, _Hi, _R) -> false;
cmp_range(Op, Lo, Hi, R) when Op =:= <<"in">>; Op =:= <<"nin">> ->
    %% only a degenerate point range is decidable against a discrete list.
    case Lo =/= null andalso Lo == Hi of
        true  -> bool_to_tri(sat(Op, Lo, R));
        false -> undetermined
    end;
cmp_range(Op, _Lo, _Hi, _R) ->
    erlang:error({resolver_unknown_op, Op}).

%% tri(IsTrue, IsFalse): true if the whole interval satisfies; false if none does;
%% else undetermined. (IsTrue and IsFalse are never both true for a valid interval.)
tri(true, _)     -> true;
tri(false, true) -> false;
tri(false, false) -> undetermined.

%% pick(IsTrue, IsFalse) — like tri/2 but for eq/neq where the "true" test is a
%% point match; same precedence (definite true, then definite false, else undet).
pick(true, _)      -> true;
pick(false, true)  -> false;
pick(false, false) -> undetermined.

%% whole-interval ordered relations (null bound = unbounded → relation can't hold
%% for the whole interval).
lo_ge(null, _R) -> false;
lo_ge(Lo, R)    -> Lo >= R.
lo_gt(null, _R) -> false;
lo_gt(Lo, R)    -> Lo > R.
hi_le(null, _R) -> false;
hi_le(Hi, R)    -> Hi =< R.
hi_lt(null, _R) -> false;
hi_lt(Hi, R)    -> Hi < R.
below(null, _R) -> false;   %% R strictly below the interval's lower bound
below(Lo, R)    -> R < Lo.
above(null, _R) -> false;   %% R strictly above the interval's upper bound
above(Hi, R)    -> R > Hi.

%% --- two-valued predicate at a concrete value (mirrors resolver_eval._sat) ---
%% `==` (not `=:=`) for eq/numeric, mirroring Python; binaries/atoms compare alike.

-spec sat(binary(), term(), term()) -> boolean().
sat(<<"eq">>,  P, R) -> P == R;
sat(<<"neq">>, P, R) -> P /= R;
sat(<<"gte">>, P, R) -> P >= R;
sat(<<"gt">>,  P, R) -> P > R;
sat(<<"lte">>, P, R) -> P =< R;
sat(<<"lt">>,  P, R) -> P < R;
sat(<<"in">>,  P, R) when is_list(R) -> lists:member(P, R);
sat(<<"nin">>, P, R) when is_list(R) -> not lists:member(P, R);
sat(<<"between">>, P, [Lo, Hi]) -> Lo =< P andalso P =< Hi;
sat(<<"between">>, _P, _R) -> false;
sat(Op, _P, _R) -> erlang:error({resolver_unknown_op, Op}).

bool_to_tri(true)  -> true;
bool_to_tri(false) -> false.

%% --- internals --------------------------------------------------------------

get_rule(Leaf, Rules) ->
    case maps:find(Leaf, Rules) of
        {ok, Rule} -> Rule;
        error      -> erlang:error({resolver_no_rule_for_leaf, Leaf})
    end.

%% facts.applicants or [#{}] — a rule with no applicant.* field yields the same
%% verdict for each, so ∀ is idempotent there (mirrors `facts.get("applicants") or [{}]`).
applicants(Facts) ->
    case maps:get(<<"applicants">>, Facts, []) of
        [] -> [#{}];
        L when is_list(L) -> L
    end.
