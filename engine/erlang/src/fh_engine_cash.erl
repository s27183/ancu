-module(fh_engine_cash).

%% The base-turn `cash_position` fill — mechanism (B), the per-component FORMULA
%% code the declarative resolver can't express (agentic-boundary §40/§98; the
%% resolver is two mechanisms — see [[engine-seam-build-discipline]]). It composes
%% the statutory transfer-duty scale with the eligible first-home concession into
%% the `stamp_duty.{before_concession, concession_applied, after_concession}` leaves.
%%
%% Design + verification: docs/architecture/stamp-duty-concession-mechanics.md.
%% Every formula here reproduces the relevant state revenue office's own calculator
%% output to the dollar at the anchors locked in cash_duty_conformance.escript
%% (NSW $850k → after $9,853 / saving $22,809; VIC $700k → $24,713 / $12,357;
%% QLD $730k → $6,555). Regulated figures (ASIC decision-support line) — the
%% postcondition match IS the correctness criterion.
%%
%% SCOPE (this unit): the `stamp_duty.*` sub-tree only. The rest of budget_envelope
%% (other_buying_costs, reserve_buffer, deposit, totals, verdict) needs income/
%% savings facts that arrive on a refine turn → left null/pending here (honest
%% partial output — base-turn-honest-partial-output). Those are separate fills.

-export([fill/2]).
%% exported for the conformance harness (same anchors as the Python spec):
-export([duty/2, stamp_duty/3]).

%% --- entry -------------------------------------------------------------------

-spec fill(map(), map()) -> {map(), binary(), [map()]}.
fill(Args, Upstream) ->
    Profile = maps:get(<<"profile">>, Upstream, #{}),
    Stack   = maps:get(<<"scheme_stack">>, Upstream, #{}),
    State   = onboarding_state(Args, Profile),
    Ceiling = ceiling(maps:get(<<"target_price_range">>, Profile, null)),
    %% Gate the concession on eligibility's outcome, not a private state->scheme map
    %% (§6): apply a state concession iff scheme_stack carries one as applicable/
    %% pending. So the §3 tapers can all be encoded yet stay dormant until
    %% eligibility's state_catalog dispatches VIC/QLD — the two never disagree.
    HasConc = has_state_concession(Stack),
    Sd = stamp_duty(State, HasConc, Ceiling),
    Outcome = budget_envelope(Sd, Ceiling),
    KbVersions = fh_engine_kb:kb_anchors(
        [<<"kb.stamp-duty.calc-by-state">>,
         <<"kb.buyer-costs.inspections-conveyancing-fees">>]
        ++ concession_anchor(State, HasConc)),
    {Outcome, <<"calculator">>, KbVersions}.

%% --- stamp_duty: the composition contract (§2) -------------------------------
%% before = standard_duty(V, state); after = concessional_duty (or before, no
%% concession); concession_applied = before - after. Evaluated at the range CEILING
%% (§6): the non-monotonic net duty is most-conservative-for-cash at the top of the
%% range (highest duty AND least concession both occur there).

-spec stamp_duty(binary(), boolean(), integer() | null) -> map().
stamp_duty(_State, _HasConc, null) ->
    pending_sd(<<"Set a target price range to estimate transfer duty.">>);
stamp_duty(State, HasConc, V) when is_integer(V) ->
    case scale_for(State) of
        undefined ->
            pending_sd(iolist_to_binary(
                [<<"Transfer duty for ">>, State,
                 <<" is not yet modelled (NSW, VIC, QLD supported)."/utf8>>]));
        StdScale ->
            BeforeRaw = duty(V, StdScale),
            AfterRaw  = case HasConc of
                            true  -> state_after(State, V);
                            false -> BeforeRaw
                        end,
            Before = dollars(BeforeRaw),
            After  = dollars(AfterRaw),
            Saving = Before - After,
            #{<<"before_concession">>  => Before,
              <<"concession_applied">> => Saving,
              <<"after_concession">>   => After,
              <<"notes">> => duty_notes(State, HasConc, V, Saving)}
    end.

pending_sd(Why) ->
    #{<<"before_concession">>  => null,
      <<"concession_applied">> => null,
      <<"after_concession">>   => null,
      <<"notes">> => [Why]}.

%% --- the shared marginal-bracket kernel (§3) ---------------------------------
%% duty(V, ScaleName): base + marginal_rate% x (V - lower), with the per-$100
%% rounding (NSW/QLD), the VIC flat-on-total quirk, the QLD nil bracket, and the
%% NSW $20 minimum — all data-driven from the scale entries (calc-by-state.md), no
%% hardcoded rates. Shared by all four scales (NSW/VIC/QLD standard + QLD home-conc).

-spec duty(integer(), binary()) -> number().
duty(V, ScaleName) ->
    Scale   = scale(ScaleName),
    Entries = maps:get(<<"entries">>, Scale),
    Rounds  = maps:get(<<"rounds_marginal_to_part_of_100">>, Scale, false),
    B       = bracket_for(V, Entries),
    Raw     = bracket_duty(V, B, Rounds),
    erlang:max(Raw, maps:get(<<"min_duty">>, B, 0)).

%% the bracket whose [lower, upper] contains V (open top bracket: upper = null).
bracket_for(V, [E | Rest]) ->
    case maps:get(<<"upper_bound">>, E) of
        null                  -> E;
        Upper when V =< Upper -> E;
        _                     -> bracket_for(V, Rest)
    end.

bracket_duty(V, B, Rounds) ->
    case maps:get(<<"calc_type">>, B) of
        <<"nil">>           -> 0;
        <<"flat_on_total">> -> pct(maps:get(<<"flat_rate_pct">>, B), V);
        <<"marginal">>      ->
            Excess0 = V - maps:get(<<"lower_bound">>, B),
            Excess  = case Rounds of true -> roundup100(Excess0); false -> Excess0 end,
            maps:get(<<"base_duty">>, B) + pct(maps:get(<<"marginal_rate_pct">>, B), Excess)
    end.

pct(Rate, Amount) -> Rate * Amount / 100.

%% "for each $100, or part of $100": round the excess UP to the next whole $100.
roundup100(X) when X =< 0 -> 0;
roundup100(X)            -> ((X + 99) div 100) * 100.

%% --- the three per-state taper functions (§3) --------------------------------
%% Each is self-contained and correct at any V (returns full duty above its cap),
%% so they are safe to call regardless of the scheme_stack gate. Divisors are
%% DERIVED from the scheme docs' threshold params (cap - exemption), so they track
%% a threshold change rather than baking in a literal.

state_after(<<"NSW">>, V) -> nsw_after(V);
state_after(<<"VIC">>, V) -> vic_after(V);
state_after(<<"QLD">>, V) -> qld_after(V).

%% NSW FHBAS — phase out a threshold-pegged concession (Duties Act 1997 s.78A(2)).
nsw_after(V) ->
    {Ex, Cap} = thresholds(<<"kb.scheme.nsw.fhbas">>,
                           <<"home_exemption_threshold">>, <<"home_concession_cap">>),
    Std = <<"nsw_standard_scale">>,
    if
        V =< Ex  -> 0;
        V <  Cap -> duty(V, Std) - duty(Ex, Std) * (Cap - V) / (Cap - Ex);
        true     -> duty(V, Std)
    end.

%% VIC FHB duty — phase in the duty by a linear fraction (Duties Act 2000 s.57JA).
%% B is the GENERAL-scale duty: the band ($600k-$750k) sits above the $550k PPR cliff.
vic_after(V) ->
    {Ex, Cap} = thresholds(<<"kb.scheme.vic.fhb-duty">>,
                           <<"exemption_threshold">>, <<"concession_cap">>),
    Gen = <<"vic_general_scale">>,
    if
        V =< Ex  -> 0;
        V =< Cap -> duty(V, Gen) * (V - Ex) / (Cap - Ex);
        true     -> duty(V, Gen)
    end.

%% QLD FHC — second (home-concession) scale minus a stepped table; the max(0,..)
%% floor yields the <=$700k full exemption for free. Above the $800k cap: first-home
%% concession gone; the general home concession is deferred (doc unauthored, §7) →
%% standard duty (conservative).
qld_after(V) ->
    Cap = param_money(<<"kb.scheme.qld.fhc">>, <<"value_cap">>),
    case V =< Cap of
        true  -> erlang:max(0, duty(V, <<"qld_home_concession_scale">>) - fhc_amount(V));
        false -> duty(V, <<"qld_standard_scale">>)
    end.

%% the stepped first-home concession AMOUNT for V (fhc.md lookup): first band whose
%% max_value >= V (open tail: max_value = null → nil above $800k).
fhc_amount(V) ->
    Entries = maps:get(<<"entries">>,
        maps:get(<<"first_home_concession_amount">>, lookup(<<"kb.scheme.qld.fhc">>))),
    fhc_pick(V, Entries).

fhc_pick(V, [E | Rest]) ->
    case maps:get(<<"max_value">>, E) of
        null                -> maps:get(<<"amount">>, E);
        Max when V =< Max   -> maps:get(<<"amount">>, E);
        _                   -> fhc_pick(V, Rest)
    end.

%% --- budget_envelope (honest partial: stamp_duty filled, rest pending) --------

budget_envelope(Sd, Ceiling) ->
    #{<<"stamp_duty">> => Sd,
      %% no property attached at base; capacity/savings facts arrive on a refine turn
      <<"actual_property_price">>        => null,
      <<"max_property_price_supported">> => null,   %% needs mortgage_finance capacity
      <<"total_cash_required">>          => null,   %% needs the other cost lines (separate fills)
      <<"cash_available">>               => null,   %% needs income/savings (pending)
      <<"gap_or_surplus">>               => null,
      <<"verdict">>                      => null,
      <<"genuine_savings_verdict">>      => <<"unknown">>,
      <<"mitigation_options_if_short">>  => [],
      <<"key_assumptions">> =>
          [<<"Stamp duty is the only settlement cost estimated so far; the full cash "
             "picture fills in as you add income, savings and a property.">>]
          ++ ceiling_assumption(Ceiling)}.

ceiling_assumption(null)    -> [];
ceiling_assumption(Ceiling) ->
    [iolist_to_binary([<<"Duty computed at the top of your target range (">>,
                       money(Ceiling), <<").">>])].

%% --- user-facing duty notes --------------------------------------------------

duty_notes(_State, true, _V, Saving) when Saving > 0 ->
    [iolist_to_binary([<<"Includes the first-home transfer-duty concession — about "/utf8>>,
                       money(Saving), <<" off — pending confirmation of your details."/utf8>>])];
duty_notes(_State, true, _V, _Saving) ->
    [<<"At the top of your target range the first-home duty concession no longer "
       "applies; a lower target may qualify.">>];
duty_notes(_State, false, _V, _Saving) ->
    [<<"Shown at full duty — no first-home concession applied at this price/state yet."/utf8>>].

concession_anchor(<<"NSW">>, true) -> [<<"kb.scheme.nsw.fhbas">>];
concession_anchor(<<"VIC">>, true) -> [<<"kb.scheme.vic.fhb-duty">>];
concession_anchor(<<"QLD">>, true) -> [<<"kb.scheme.qld.fhc">>];
concession_anchor(_State, _)       -> [].

%% --- KB access ---------------------------------------------------------------

scale(Name) -> maps:get(Name, lookup(<<"kb.stamp-duty.calc-by-state">>)).

lookup(Slug) ->
    {ok, Cj} = fh_engine_kb:kb_rules(Slug),
    maps:get(<<"lookup">>, Cj).

thresholds(Slug, ExKey, CapKey) ->
    {param_money(Slug, ExKey), param_money(Slug, CapKey)}.

param_money(Slug, Key) ->
    {ok, Cj} = fh_engine_kb:kb_rules(Slug),
    Params = maps:get(<<"parameters">>, Cj),
    maps:get(<<"value">>, maps:get(Key, Params)).

scale_for(<<"NSW">>) -> <<"nsw_standard_scale">>;
scale_for(<<"VIC">>) -> <<"vic_general_scale">>;
scale_for(<<"QLD">>) -> <<"qld_standard_scale">>;
scale_for(_)         -> undefined.

%% --- helpers -----------------------------------------------------------------

ceiling([_Lo, Hi]) when is_integer(Hi) -> Hi;
ceiling(_)                             -> null.

has_state_concession(Stack) ->
    Schemes = maps:get(<<"applicable_schemes">>, Stack, []),
    lists:any(fun(S) -> maps:get(<<"role">>, S, <<>>) =:= <<"stamp_duty_concession">> end,
              Schemes).

onboarding_state(Args, Profile) ->
    Onboarding = maps:get(onboarding, Args, #{}),
    case maps:get(<<"state">>, Onboarding, undefined) of
        undefined -> maps:get(<<"state">>, Profile, <<"NSW">>);
        S         -> S
    end.

%% round half up to whole dollars (duty is always >= 0). Defined identically in the
%% Python spec so the cross-language conformance is exact.
dollars(X) when X =< 0 -> 0;
dollars(X)            -> trunc(X + 0.5).

%% money as a plain "$1,500,000" string (local copy of the eligibility formatter —
%% extract to a shared fh_engine_money util as a separate refactor; flagged).
money(N) when is_integer(N), N < 0 -> iolist_to_binary([<<"-">>, money(-N)]);
money(N) when is_integer(N) ->
    iolist_to_binary([<<"$">>, group_thousands(integer_to_list(N))]);
money(N) -> iolist_to_binary(io_lib:format("$~p", [N])).

group_thousands(Digits) ->
    Chunks = chunk3(lists:reverse(Digits)),
    Groups = lists:reverse([lists:reverse(C) || C <- Chunks]),
    lists:flatten(lists:join(",", Groups)).

chunk3([])            -> [];
chunk3([A, B, C | T]) -> [[A, B, C] | chunk3(T)];
chunk3(Rest)          -> [Rest].
