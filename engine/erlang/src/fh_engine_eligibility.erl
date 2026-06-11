-module(fh_engine_eligibility).

%% The base-turn `eligibility` fill — produces the `scheme_stack` outcome from the
%% `profile` fact base (with possibility sets) + `target_price_range`, deterministically
%% (resolver path; no LLM). It is the orchestrator over fh_engine_resolver per
%% docs/architecture/eligibility-resolution.md + resolver-semantics.md:
%%
%%   1. select schemes by state (decision 7) — federal always + the state's concessions;
%%      state-concession leaves are MULTI-filled, so read the per-slug rule (kb_rules/1),
%%      never the last-wins merged map.
%%   2. partition each scheme's top-level criteria into base (applicant.* + state) and
%%      property (price / property_type) by field namespace (decision 1).
%%   3. evaluate the base partition three-valued (joint Kleene-∀, or per-applicant for a
%%      `resolution: per_applicant` scheme — FHSS, the F13 close).
%%   4. band the property price vs target_price_range (decision 5): within / straddle
%%      (→ max_eligible_price) / above (→ price-ineligible).
%%   5. type-conditional schemes (FHOG, QLD set) frame on property_type, not reject (decision 6).
%%   6. collapse the three-valued verdict per the eligibility CONSUMER policy: true →
%%      applicable; undetermined → applicable-PENDING with a "confirm X" note (NEVER a
%%      hard reject); false → rejected with a reason.
%%   7. assemble applicable/rejected schemes, eligibility_basis, stacking_constraints
%%      and recommended_application_order from each scheme's KB `stacking` block.
%%
%% Scope (Wedge 1): NSW state concessions are wired; VIC/QLD get federal-only here +
%% their own walk-through (decision 6/7) — flagged, not silently dropped. HELD for
%% sign-off (G2): the non_buying_partner couple-as-one fold-in (decision 4).

-export([fill/2]).

-spec fill(map(), map()) -> {map(), binary(), [map()]}.
fill(Args, Upstream) ->
    Profile = maps:get(<<"profile">>, Upstream, #{}),
    Applicants = case maps:get(<<"applicants">>, Profile, []) of
                     []  -> [#{}];
                     As  -> As
                 end,
    State = onboarding_state(Args, Profile),
    Target = maps:get(<<"target_price_range">>, Profile, null),
    GlobalRules = fh_engine_kb:rules(),
    Facts = #{<<"applicants">> => Applicants,
              <<"property_fit">> => #{<<"state">> => State}},
    Schemes = catalog(State),
    Evaluated = [evaluate(S, GlobalRules, Facts, Target) || S <- Schemes],
    Outcome = assemble(Evaluated, State),
    KbVersions = fh_engine_kb:kb_anchors([maps:get(slug, S) || S <- Schemes]),
    {Outcome, <<"scheme-stack-card">>, KbVersions}.

%% --- scheme catalog (presentation metadata; rules read from the KB) ----------

catalog(State) -> federal() ++ state_catalog(State).

federal() ->
    [#{key => fhg, slug => <<"kb.scheme.fhg">>,
       leaf => <<"eligibility.fhg.eligible">>,
       name => <<"First Home Guarantee (FHG)">>, role => <<"deposit_guarantee">>,
       benefit => <<"Buy with a 5% deposit and no Lenders Mortgage Insurance.">>},
     #{key => fhss, slug => <<"kb.scheme.fhss">>,
       leaf => <<"eligibility.fhss.eligible">>,
       name => <<"First Home Super Saver (FHSS)">>, role => <<"deposit_savings">>,
       benefit => <<"Save your deposit inside super and release it tax-effectively.">>},
     #{key => help_to_buy, slug => <<"kb.scheme.help-to-buy">>,
       leaf => <<"eligibility.help_to_buy.eligible">>,
       name => <<"Help to Buy">>, role => <<"shared_equity">>,
       benefit => <<"Government co-buys an equity share, cutting the deposit and loan you need.">>}].

state_catalog(<<"NSW">>) ->
    [#{key => fhbas, slug => <<"kb.scheme.nsw.fhbas">>,
       leaf => <<"eligibility.state_concession.applicable">>,
       name => <<"NSW First Home Buyers Assistance (transfer duty)">>,
       role => <<"stamp_duty_concession">>,
       benefit => <<"Full or partial transfer-duty exemption.">>},
     #{key => fhog_nsw, slug => <<"kb.scheme.nsw.fhog">>,
       leaf => <<"eligibility.fhog.applicable">>,
       name => <<"NSW First Home Owner Grant">>, role => <<"grant">>,
       benefit => <<"$10,000 grant for an eligible new home.">>}];
state_catalog(_Other) ->
    %% VIC/QLD concessions need their own walk-through (QLD is a property-type
    %% partition, decision 6). Federal-only here for now — surfaced in the outcome.
    [].

%% --- per-scheme evaluation ---------------------------------------------------

evaluate(S, GlobalRules, Facts, Target) ->
    {ok, Cj} = fh_engine_kb:kb_rules(maps:get(slug, S)),
    Rule = scheme_rule(maps:get(leaf, S), Cj),
    Resolution = maps:get(<<"resolution">>, Cj, <<"joint">>),
    Stacking = maps:get(<<"stacking">>, Cj, #{}),
    {BaseCrits, PriceCrits, TypeCrits} =
        partition(maps:get(<<"criteria">>, Rule, [])),
    BaseNode = #{<<"combine">> => <<"all_of">>, <<"criteria">> => BaseCrits},
    Band = band_price(PriceCrits, GlobalRules, Facts),
    TypeConditional = TypeCrits =/= [],
    Disp = disposition(Resolution, BaseNode, BaseCrits, GlobalRules, Facts,
                       Band, TypeConditional, Target),
    S#{disposition => Disp, stacking => Stacking}.

%% the criteria rule for this leaf, from THIS doc's fills.
scheme_rule(Leaf, Cj) ->
    Fills = maps:get(<<"fills">>, Cj, []),
    case lists:search(fun(F) -> maps:get(<<"leaf">>, F, undefined) =:= Leaf end, Fills) of
        {value, F} -> maps:get(<<"rule">>, F, #{});
        false      -> erlang:error({eligibility_no_rule_for_leaf, Leaf})
    end.

%% partition top-level criteria by field namespace (decision 1). A nested combine
%% (no `field`) is applicant.*-only in the in-scope rules → base partition.
partition(Crits) ->
    lists:foldr(
        fun(C, {B, P, T}) ->
            case field_of(C) of
                <<"property_fit.price">>         -> {B, [C | P], T};
                <<"property_fit.property_type">> -> {B, P, [C | T]};
                _                                -> {[C | B], P, T}
            end
        end, {[], [], []}, Crits).

field_of(#{<<"field">> := F}) -> F;
field_of(_)                   -> undefined.

%% --- price banding (decision 5) ---------------------------------------------

band_price([], _GR, _Facts) -> no_constraint;
band_price([PriceCrit | _], GR, Facts) ->
    {CapLow, CapHigh} = cap_of(PriceCrit, GR, Facts),
    {band_pending, CapLow, CapHigh}.

%% a fixed price cap (`value`) → single threshold; a `ref` to the FHG (state,tier)
%% lookup → the state BAND: the capital-tier cap (upper) and rest-of-state (lower),
%% since location_tier is unknown at base.
cap_of(#{<<"value">> := V}, _GR, _Facts) -> {V, V};
cap_of(#{<<"ref">> := Ref}, GR, Facts) ->
    High = fh_engine_resolver:eval_joint(Ref, GR, with_tier(Facts, <<"capital_or_regional_centre">>)),
    Low  = fh_engine_resolver:eval_joint(Ref, GR, with_tier(Facts, <<"rest_of_state">>)),
    {Low, High};
cap_of(_, _GR, _Facts) -> {null, null}.

with_tier(Facts, Tier) ->
    Facts#{<<"locals">> => #{<<"location_tier">> => Tier}}.

%% resolve the band against the target price range → within | {straddle, Max} | {above, Cap}.
band_resolve(no_constraint, _Target) -> within;
band_resolve({band_pending, _Low, null}, _Target) -> unknown_cap;
band_resolve({band_pending, _Low, _High}, null) -> within;
band_resolve({band_pending, Low, High}, [Lo, Hi]) ->
    EffLow = case Low of null -> High; _ -> Low end,
    if
        Lo > High    -> {above, High};
        Hi =< EffLow -> within;
        true         -> {straddle, High}
    end.

%% --- disposition (the three-valued → eligibility-consumer collapse) ----------

disposition(<<"per_applicant">>, BaseNode, _BaseCrits, GR, Facts, _Band, _TypeCond, _Target) ->
    PerAppl = fh_engine_resolver:eval_node_applicants(BaseNode, GR, Facts),
    per_applicant_disp(PerAppl);
disposition(_Joint, BaseNode, BaseCrits, GR, Facts, Band, TypeCond, Target) ->
    case band_resolve(Band, Target) of
        {above, Cap} ->
            #{status => rejected,
              reason => iolist_to_binary([<<"Property price cap is ">>, money(Cap),
                                          <<"; your target starts above it.">>])};
        BandOut ->
            BaseTri = fh_engine_resolver:eval_node_joint(BaseNode, GR, Facts),
            joint_disp(BaseTri, BaseCrits, GR, Facts, BandOut, TypeCond)
    end.

joint_disp(false, BaseCrits, GR, Facts, _BandOut, _TypeCond) ->
    #{status => rejected, reason => reject_reason(BaseCrits, GR, Facts)};
joint_disp(true, _BaseCrits, _GR, _Facts, BandOut, TypeCond) ->
    Notes = band_notes(BandOut) ++ type_notes(TypeCond),
    Status = case TypeCond of true -> conditional; false -> eligible end,
    add_max(#{status => Status, notes => Notes}, BandOut);
joint_disp(undetermined, BaseCrits, GR, Facts, BandOut, TypeCond) ->
    Pending = pending_labels(BaseCrits, GR, Facts),
    Notes = [confirm_note(Pending) | band_notes(BandOut) ++ type_notes(TypeCond)],
    add_max(#{status => pending, notes => Notes}, BandOut).

per_applicant_disp(PerAppl) ->
    EligibleIdx = [I || {I, T} <- enumerate(PerAppl), T =:= true],
    case {lists:member(true, PerAppl), lists:member(undetermined, PerAppl)} of
        {true, _} ->
            #{status => eligible, eligible_applicants => EligibleIdx,
              notes => [<<"Assessed per applicant — each eligible person can run their own."/utf8>>]};
        {false, true} ->
            #{status => pending,
              notes => [<<"Confirm no previous First Home Super Saver release to finalise.">>]};
        {false, false} ->
            #{status => rejected, reason => <<"No applicant meets the FHSS criteria.">>}
    end.

add_max(Disp, {straddle, Max}) -> Disp#{max_eligible_price => Max};
add_max(Disp, _)               -> Disp.

%% --- reasons / pending attribution (per top-level base criterion) -----------

reject_reason(BaseCrits, GR, Facts) ->
    Failing = [label_of(C) || C <- BaseCrits, crit_tri(C, GR, Facts) =:= false],
    case Failing of
        [L | _] -> iolist_to_binary([<<"Does not meet: ">>, L, <<".">>]);
        []      -> <<"Does not meet the eligibility criteria.">>
    end.

pending_labels(BaseCrits, GR, Facts) ->
    [label_of(C) || C <- BaseCrits, crit_tri(C, GR, Facts) =:= undetermined].

crit_tri(C, GR, Facts) ->
    fh_engine_resolver:eval_node_joint(
        #{<<"combine">> => <<"all_of">>, <<"criteria">> => [C]}, GR, Facts).

confirm_note(Labels) ->
    iolist_to_binary([<<"Confirm ">>, join(Labels, <<", ">>), <<" to finalise.">>]).

band_notes({straddle, Max}) ->
    [iolist_to_binary([<<"Eligible for properties up to ">>, money(Max),
                       <<"; the exact cap depends on the suburb.">>])];
band_notes(_) -> [].

type_notes(true)  -> [<<"Available for an eligible new build or off-the-plan purchase.">>];
type_notes(false) -> [].

label_of(C) ->
    case field_of(C) of
        undefined                                       -> <<"ownership history">>;
        <<"applicant.citizenship_status">>              -> <<"Australian citizenship or permanent residency">>;
        <<"applicant.age">>                             -> <<"age 18 or over">>;
        <<"applicant.ever_owned_au_property">>          -> <<"first-home-buyer status">>;
        <<"applicant.owner_occupier_intent">>           -> <<"intention to live in the home">>;
        <<"applicant.prior_fhss_release">>              -> <<"no previous FHSS release">>;
        <<"applicant.currently_owns_property">>         -> <<"not currently owning property">>;
        <<"property_fit.state">>                        -> <<"a property in your state">>;
        _                                               -> <<"the eligibility details">>
    end.

%% --- assembly ----------------------------------------------------------------

assemble(Evaluated, State) ->
    Applicable = [E || E <- Evaluated, status(E) =/= rejected],
    Rejected   = [E || E <- Evaluated, status(E) =:= rejected],
    Outcome = #{
        <<"applicable_schemes">> => [to_applicable(E) || E <- Applicable],
        <<"rejected_schemes">> =>
            [#{<<"name">> => maps:get(name, E),
               <<"reason">> => maps:get(reason, maps:get(disposition, E))} || E <- Rejected],
        <<"eligibility_basis">> => basis(Evaluated),
        <<"recommended_application_order">> =>
            [maps:get(name, E) || E <- sort_by_order(Applicable)],
        <<"stacking_constraints">> => stacking_constraints(Applicable),
        <<"structuring_options">> => [],   %% multi-applicant refine-turn concern (decisions 3/4)
        <<"total_benefit_value">> => null  %% Mode-A base benefits are qualitative; quantified per-property
    },
    maybe_state_note(Outcome, State).

to_applicable(E) ->
    Disp = maps:get(disposition, E),
    #{<<"name">> => maps:get(name, E),
      <<"benefit_value">> => maps:get(benefit, E),
      <<"role">> => maps:get(role, E),
      <<"notes">> => status_prefix(Disp) ++ maps:get(notes, Disp, [])}.

%% surface the disposition as the lead note (renderer reads `notes`).
status_prefix(#{status := eligible})    -> [<<"Eligible.">>];
status_prefix(#{status := conditional}) -> [<<"Conditionally available.">>];
status_prefix(#{status := pending})     -> [<<"Likely eligible — pending a few details."/utf8>>];
status_prefix(_)                        -> [].

basis(Evaluated) ->
    case [E || E <- Evaluated, status(E) =/= rejected] of
        [] -> <<"ineligible">>;
        _  -> <<"all_applicants_eligible">>   %% single Mode-A lead; restructuring is a refine-turn concern
    end.

%% stacking_constraints: alternative_to edges among the APPLICABLE schemes. The pair
%% is canonicalised (names sorted) so the symmetric edge isn't emitted twice.
stacking_constraints(Applicable) ->
    BySlug = maps:from_list([{maps:get(slug, E), maps:get(name, E)} || E <- Applicable]),
    lists:usort(lists:flatmap(
        fun(E) ->
            Alts = maps:get(<<"alternative_to">>, maps:get(stacking, E, #{}), []),
            [alternatives_note(maps:get(name, E), maps:get(Alt, BySlug))
             || Alt <- Alts, maps:is_key(Alt, BySlug)]
        end, Applicable)).

alternatives_note(A, B) ->
    [X, Y] = lists:sort([A, B]),
    iolist_to_binary([X, <<" and ">>, Y, <<" are alternatives — choose one."/utf8>>]).

sort_by_order(Applicable) ->
    lists:sort(fun(A, B) -> order_hint(A) =< order_hint(B) end, Applicable).

order_hint(E) ->
    maps:get(<<"order_hint">>, maps:get(stacking, E, #{}), 999).

maybe_state_note(Outcome, <<"NSW">>) -> Outcome;
maybe_state_note(Outcome, _State) ->
    %% no silent cap: non-NSW state concessions aren't evaluated yet.
    Constraints = maps:get(<<"stacking_constraints">>, Outcome),
    Outcome#{<<"stacking_constraints">> =>
                 Constraints ++ [<<"State stamp-duty concessions for your state are not "
                                   "yet assessed here — federal schemes only."/utf8>>]}.

%% --- helpers -----------------------------------------------------------------

status(E) -> maps:get(status, maps:get(disposition, E)).

onboarding_state(Args, Profile) ->
    Onboarding = maps:get(onboarding, Args, #{}),
    case maps:get(<<"state">>, Onboarding, undefined) of
        undefined -> maps:get(<<"state">>, Profile, <<"NSW">>);
        S         -> S
    end.

enumerate(L) -> lists:zip(lists:seq(0, length(L) - 1), L).

join([], _Sep) -> <<>>;
join([X], _Sep) -> X;
join([X | Rest], Sep) -> iolist_to_binary([X, Sep, join(Rest, Sep)]).

%% money as a plain "$1,500,000" string.
money(N) when is_integer(N), N < 0 -> iolist_to_binary([<<"-">>, money(-N)]);
money(N) when is_integer(N) ->
    iolist_to_binary([<<"$">>, group_thousands(integer_to_list(N))]);
money(N) -> iolist_to_binary(io_lib:format("$~p", [N])).

%% "1500000" -> "1,500,000". Chunk the reversed digits into 3s (right-to-left
%% groups), restore each group's order, then join the groups left-to-right.
group_thousands(Digits) ->
    Chunks = chunk3(lists:reverse(Digits)),
    Groups = lists:reverse([lists:reverse(C) || C <- Chunks]),
    lists:flatten(lists:join(",", Groups)).

chunk3([])           -> [];
chunk3([A, B, C | T]) -> [[A, B, C] | chunk3(T)];
chunk3(Rest)         -> [Rest].
