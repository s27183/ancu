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
%% MODE DISPATCH: fill/2 branches on the `tax_optimised_structure` upstream discriminator
%% (mirrors fh_engine_disposition) — Mode-A FHB → fill_fhb/2 (budget_envelope, below); Mode-C
%% investor → fill_investor/2 (budget_envelope_investor, a pure-resolver base scaffold).
%%
%% SCOPE (the FHB fill): the `stamp_duty.*` sub-tree only. The rest of budget_envelope
%% (other_buying_costs, reserve_buffer, deposit, totals, verdict) needs income/
%% savings facts that arrive on a refine turn → left null/pending here (honest
%% partial output — base-turn-honest-partial-output). Those are separate fills.

-export([fill/2]).
%% exported for the conformance harness (same anchors as the Python spec):
-export([duty/2, stamp_duty/3, registration_total/2]).

-define(COPY, <<"kb.copy.cash">>).   %% bilingual copy-templates (bilingual-content.md §3b)

%% --- entry -------------------------------------------------------------------

%% Mode discriminator (mirrors fh_engine_disposition:fill/2): only the investor blueprint runs
%% a `tax_structure` component, so its outcome's presence upstream marks the Mode-C investor
%% cash_position (budget_envelope_investor) vs the Mode-A FHB path (budget_envelope). Shared
%% component NAME + `calculator` renderer; different outcome TYPE + logic. The FHB body is
%% renamed fill_fhb/2 verbatim (byte-identical — zero regression); the investor body is new.
-spec fill(map(), map()) -> {map(), binary(), [map()]}.
fill(Args, Upstream) ->
    case maps:get(<<"tax_optimised_structure">>, Upstream, undefined) of
        undefined -> fill_fhb(Args, Upstream);
        _Tax      -> fill_investor(Args, Upstream)
    end.

%% --- Mode-A FHB cash_position (budget_envelope) ------------------------------

-spec fill_fhb(map(), map()) -> {map(), binary(), [map()]}.
fill_fhb(Args, Upstream) ->
    Profile  = maps:get(<<"profile">>, Upstream, #{}),
    Stack    = maps:get(<<"scheme_stack">>, Upstream, #{}),
    %% mortgage_finance fills BEFORE cash_position in the base DAG, so its outcome is
    %% in Upstream (keyed by outcome type). recommended_path gates the deposit %
    %% (fhg_backed → the 5% no-LMI path); absent → the 5% floor + a note (deposit/2).
    Mortgage = maps:get(<<"mortgage_plan">>, Upstream, #{}),
    %% The PROJECTION state — the suburb being planned, not the map browse-filter
    %% (eligibility-resolution.md 2026-06-17 / G4). The SAME derivation eligibility
    %% uses, so the duty concession and the scheme-stack benefit can't disagree.
    State   = fh_engine_store:projection_state(maps:get(onboarding, Args, #{})),
    Range   = maps:get(<<"target_price_range">>, Profile, null),
    Ceiling = ceiling(Range),
    %% Gate the concession on eligibility's outcome, not a private state->scheme map
    %% (§6): apply a state concession iff scheme_stack carries one as applicable/
    %% pending. So the §3 tapers can all be encoded yet stay dormant until
    %% eligibility's state_catalog dispatches VIC/QLD — the two never disagree.
    HasConc = has_state_concession(Stack),
    RecPath = maps:get(<<"recommended_path">>, Mortgage, null),
    Sd = stamp_duty(State, HasConc, Ceiling),
    Outcome = budget_envelope(Sd, State, RecPath, Range, Ceiling, Stack),
    KbVersions = fh_engine_kb:kb_anchors(
        [<<"kb.stamp-duty.calc-by-state">>,
         <<"kb.buyer-costs.inspections-conveyancing-fees">>,
         <<"kb.cash-reserve.lender-expectations">>, <<"kb.scheme.fhg">>]
        ++ concession_anchor(State, HasConc)),
    {Outcome, <<"calculator">>, KbVersions}.

%% --- Mode-C investor cash_position (budget_envelope_investor) ----------------
%% A PURE-resolver figure-owner (agent_leaves = []; no two-path, no merge). The investor outcome
%% is nine POINT-summary figures (no range/breakdown subtrees, no cash_events — unlike the FHB
%% budget_envelope). It BRANCHES on the per-property keystone (Slice B3b):
%%   - BASE (plan-first: no property → property_fit_investor absent) → the all-null scaffold;
%%   - PER-PROPERTY (Phase-B, property_fit_investor present) → the cash-to-complete POINT figures
%%     off the EXACT attached price: actual_property_price, loan_amount (price × 80% LVR baseline),
%%     lvr, lmi_payable (0 at the baseline), total_cash_required (deposit + duty + acquisition adders).
%% Still honestly unknowable in BOTH cases:
%%   - max_property_price_supported → needs the investor mortgage_finance capacity (income/borrowing,
%%     a refine fact; the FHB path leaves it null too);
%%   - HAVE-side (gap_or_surplus, verdict) → need cash_available, captured on a refine turn.
%% The calculator renderer + the six cash KB anchors (method/figure audit trail) are carried
%% throughout; mitigation_options_if_short empty. Honest-partial (base-turn-honest-partial-output).
%% disposition's consumer reads total_cash_required via money_range/1 (scalar → [v,v]); it computes
%% the full-horizon ACQUIRE figure once disposition is re-run per-property (Slice B3c).
%%
%% SEAMS (flagged, not patched here):
%%   1. total_cash_required is typed scalar `money`, but the natural base computation is a
%%      money_range over the target price range — the banded-vs-scalar cross-contract seam,
%%      recurring from yield_modelling/tax_structure. Base parity with the FHB NEED-side ranges
%%      (deposit/duty/other-costs over the range) would be a registry+blueprint+shell redesign,
%%      not this resolver.
%%   2. budget_envelope_investor carries no cash_events field, so the investor acquire-phase
%%      financial spine is design-first (§8.5) — only disposition's dispose_cash_events + the
%%      yield/tax hold events exist on the investor temporal flow.
-spec fill_investor(map(), map()) -> {map(), binary(), [map()]}.
fill_investor(_Args, Upstream) ->
    %% Branch on the per-property keystone (Slice B3b): at base property_fit_investor is absent →
    %% the all-null scaffold; per-property (Phase-B) it carries the exact price → the cash-to-complete.
    Outcome = case maps:get(<<"property_fit_investor">>, Upstream, undefined) of
                  Pf when is_map(Pf), map_size(Pf) > 0 -> budget_envelope_investor(Pf);
                  _                                    -> budget_envelope_investor_base()
              end,
    KbVersions = fh_engine_kb:kb_anchors(
        [<<"kb.stamp-duty.calc-by-state">>,
         <<"kb.investor.deposit-requirements-investment-loans">>,
         <<"kb.lmi.calculation">>,
         <<"kb.buyer-costs.investor-additional-costs">>,
         <<"kb.tax.quantity-surveyor-reports">>,
         <<"kb.tax.entity-setup-costs">>]),
    {Outcome, <<"calculator">>, KbVersions}.

%% base (no property attached): every figure honestly unknowable.
budget_envelope_investor_base() ->
    #{<<"actual_property_price">>        => null,
      <<"max_property_price_supported">> => null,
      <<"total_cash_required">>          => null,
      <<"loan_amount">>                  => null,
      <<"lvr">>                          => null,
      <<"lmi_payable">>                  => null,
      <<"gap_or_surplus">>               => null,
      <<"verdict">>                      => null,
      <<"mitigation_options_if_short">>  => []}.

%% Slice B3b — the per-property cash-to-complete (NEED side), POINT figures off the attached
%% property's EXACT price (so scalar `money`, not banded): loan at the LVR baseline (80% — the
%% 20%-deposit/no-LMI planning baseline, deposit-requirements), the deposit, full stamp duty (no
%% FHB concession — investor; no foreign surcharge for a domestic investor), and the acquisition
%% adders. lmi_payable = 0 at the 80% baseline. The HAVE side (gap_or_surplus, verdict) and
%% max_property_price_supported (borrowing capacity → income, a refine fact) stay null — honest-
%% partial. Honest-partial too if the price/state are missing or the state's duty isn't modelled.
budget_envelope_investor(Pf) ->
    Price = maps:get(<<"price">>, Pf, null),
    State = maps:get(<<"state">>, Pf, null),
    case is_integer(Price) andalso Price > 0 andalso is_binary(State) of
        false -> budget_envelope_investor_base();
        true ->
            Lvr  = 100 - param_value(<<"kb.investor.deposit-requirements-investment-loans">>,
                                     <<"deposit_no_lmi_pct">>),
            Loan = round(Price * Lvr / 100),
            Duty = maps:get(<<"after_concession">>, stamp_duty(State, false, Price), null),
            Acq  = acquisition_costs_investor(State, Price),
            (budget_envelope_investor_base())#{
                <<"actual_property_price">> => Price,
                <<"loan_amount">>           => Loan,
                <<"lvr">>                   => Lvr,
                <<"lmi_payable">>           => 0,   %% 80% LVR baseline → no LMI (lmi.calculation 80% threshold)
                <<"total_cash_required">>   => total_cash_investor(Price - Loan, Duty, Acq)
            }
    end.

%% acquisition adders for an investor (kb.buyer-costs.investor-additional-costs): registration
%% (exact, per state) + the shared due-diligence/legal lines (building+pest inspection,
%% conveyancing, lender application fee) collapsed to a representative point. EXCLUDES the
%% owner-occupier / holding lines (moving, utility connections, and building insurance — the last
%% is a recurring OPERATING expense in yield_modelling, never an acquisition cost; no double-count).
%% The conditional adders (lease review if tenant-in-situ, QS report, entity setup) are surfaced as
%% considerations, not summed into the baseline cash. null when the state's registration isn't modelled.
acquisition_costs_investor(State, Price) ->
    case registration_total(State, Price) of
        null -> null;
        Reg  ->
            {Lo, Hi} = convention_band_investor(),
            Reg + round((Lo + Hi) / 2)
    end.

convention_band_investor() ->
    Keys = [<<"building_pest_inspection">>, <<"conveyancing">>, <<"lender_application_fee">>],
    {lists:sum([cost_param(K, <<"_low">>)  || K <- Keys]),
     lists:sum([cost_param(K, <<"_high">>) || K <- Keys])}.

%% = deposit + duty + acquisition adders; null if any contributing line is pending (honest-partial,
%% never a partial sum) — e.g. an unmodelled state's duty/registration.
total_cash_investor(Deposit, Duty, Acq)
  when is_integer(Deposit), is_integer(Duty), is_integer(Acq) ->
    Deposit + Duty + Acq;
total_cash_investor(_, _, _) ->
    null.

%% --- stamp_duty: the composition contract (§2) -------------------------------
%% before = standard_duty(V, state); after = concessional_duty (or before, no
%% concession); concession_applied = before - after. Evaluated at the range CEILING
%% (§6): the non-monotonic net duty is most-conservative-for-cash at the top of the
%% range (highest duty AND least concession both occur there).

-spec stamp_duty(binary() | undefined, boolean(), integer() | null) -> map().
%% No projection state (the zone didn't resolve to a single state — G4 fail-honest):
%% duty isn't estimable, say so. Takes precedence over the null-price clause.
stamp_duty(undefined, _HasConc, _V) ->
    pending_sd(copy(<<"note_state_unknown">>, #{}));
stamp_duty(_State, _HasConc, null) ->
    pending_sd(copy(<<"note_set_range">>, #{}));
stamp_duty(State, HasConc, V) when is_integer(V) ->
    case scale_for(State) of
        undefined ->
            pending_sd(copy(<<"note_state_unmodelled">>, #{<<"state">> => State}));
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

pending_sd(LocNote) ->
    #{<<"before_concession">>  => null,
      <<"concession_applied">> => null,
      <<"after_concession">>   => null,
      <<"notes">> => [LocNote]}.

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

%% --- budget_envelope (Decision 9: NEED side quantified; HAVE side + verdict pending) -
%% NEED side (what it costs to get in) = deposit + duty + other_buying_costs → a
%% money_range over the target price range. HAVE side (cash_available) and the verdict
%% stay null BY DESIGN: onboarding captures no savings (plan-first), so they compute on
%% a refine turn (eligibility-resolution.md §9). Honest-partial throughout.

budget_envelope(Sd, State, RecPath, Range, Ceiling, Stack) ->
    Deposit    = deposit(RecPath, Range),
    OtherCosts = other_buying_costs(State, Ceiling),
    Total      = total_cash_required(Deposit, Sd, OtherCosts),
    #{<<"stamp_duty">>         => Sd,
      <<"deposit">>            => Deposit,        %% NEED — money_range (Decision 9)
      <<"other_buying_costs">> => OtherCosts,     %% NEED — regulated reg + convention bands
      <<"reserve_buffer">>     => reserve_buffer(),%% post-settlement; amount pending (needs repayment)
      %% no property attached at base; capacity facts arrive on a refine turn
      <<"actual_property_price">>        => null,
      <<"max_property_price_supported">> => null,   %% needs mortgage_finance capacity
      <<"total_cash_required">>          => Total,   %% NEED side AT SETTLEMENT (money_range)
      <<"cash_available">>               => null,   %% HAVE side: needs savings (refine)
      <<"gap_or_surplus">>               => null,   %% needs cash_available
      <<"verdict">>                      => null,   %% PENDING by design (no savings at base)
      <<"genuine_savings_verdict">>      => <<"unknown">>,
      <<"cash_events">>                  => cash_events(Deposit, Sd, OtherCosts, Stack),
      <<"mitigation_options_if_short">>  => [],
      <<"key_assumptions">> => key_assumptions(Total, Ceiling)}.

%% --- cash_events (two-spines §2): the ACQUISITION financial spine ------------
%% PLACES already-computed figures as phased money events (one-computer-per-figure —
%% this computes NOTHING). Out-events are this component's own figures (deposit at
%% exchange, duty + transaction costs at settlement); the only in-event class is a
%% scheme GRANT (FHOG, role=grant) — an actual cash receipt at settlement, owned by
%% eligibility (source_component=eligibility, the provenance W6g gates).
%%
%% Why grant is the ONLY inflow (no double count, ASIC decision-support figure): the
%% duty concession is already netted into stamp_duty.after_concession (the reduced
%% out-event); FHG (deposit_guarantee) and Help to Buy (shared_equity) are AVOIDED
%% costs already reflected in the deposit/loan figures, not cash received; FHSS
%% (deposit_savings) is the buyer's own released super — it sits on the HAVE side
%% (cash_available), not as an inflow. Counting any of those as money_in would inflate
%% the cumulative cash-flow. This narrows the blueprint's "scheme grants/benefits".
%%
%% Acquisition phases only (Prepare→Settle): Own-phase recurring costs belong to
%% ownership_planning and are placed on the swimlane's Own column by purchase_journey
%% (cash_position cannot see downstream). Honest-partial: an event is emitted only when
%% its placed figure is non-null (the figure is the event; no figure → no event).
cash_events(Deposit, Sd, OtherCosts, Stack) ->
    Out = [
        event(<<"deposit">>, <<"contract">>, <<"event_deposit">>, <<"out">>,
              amount(maps:get(<<"minimum_required_amount">>, Deposit, null)),
              false, <<"other">>, <<"cash_position">>),
        event(<<"stamp_duty">>, <<"settle">>, <<"event_stamp_duty">>, <<"out">>,
              point(maps:get(<<"after_concession">>, Sd, null)),
              false, <<"government">>, <<"cash_position">>),
        event(<<"other_buying_costs">>, <<"settle">>, <<"event_other_costs">>, <<"out">>,
              amount(maps:get(<<"total">>, OtherCosts, null)),
              true, <<"other">>, <<"cash_position">>)
    ],
    In = grant_events(Stack),
    [E || E <- Out ++ In, maps:get(<<"amount">>, E) =/= null].

%% one in-event per applicable role=grant scheme (FHOG); benefit_value placed verbatim
%% (money_range, [0, amount] at base — honest), is_estimate mirrors the source flag.
grant_events(Stack) ->
    Grants = [S || S <- maps:get(<<"applicable_schemes">>, Stack, []),
                   maps:get(<<"role">>, S, <<>>) =:= <<"grant">>],
    [grant_event(I, S) || {I, S} <- lists:enumerate(Grants)].

grant_event(I, S) ->
    event(<<"grant_", (integer_to_binary(I))/binary>>, <<"settle">>,
          <<"event_grant">>, <<"in">>,
          amount(maps:get(<<"benefit_value">>, S, null)),
          maps:get(<<"benefit_is_estimate">>, S, false),
          <<"government">>, <<"eligibility">>).

%% acquisition events are all one_off (period=null); recurring/Own-phase events are
%% placed by purchase_journey, not here. The label is a no-param bilingual copy line.
event(Id, Phase, LabelCopyId, Dir, Amount, IsEst, Counterparty, Source) ->
    #{<<"id">>               => Id,
      <<"phase">>            => Phase,
      <<"label">>            => copy(LabelCopyId, #{}),
      <<"direction">>        => Dir,
      <<"amount">>           => Amount,
      <<"is_estimate">>      => IsEst,
      <<"timing">>           => <<"one_off">>,
      <<"period">>           => null,
      <<"counterparty">>     => Counterparty,
      <<"source_component">> => Source}.

%% place a money_range figure as-is; a scalar (duty) collapses to [v, v]; anything else
%% (null / malformed) → null, which the cash_events filter drops (place, never fabricate).
amount([Lo, Hi]) when is_number(Lo), is_number(Hi) -> [Lo, Hi];
amount(_) -> null.

point(V) when is_number(V) -> [V, V];
point(_) -> null.

%% need side computed → say so + the ceiling assumption; couldn't (no state/price) →
%% the prior stamp-only honest-partial note.
key_assumptions(null, Ceiling) ->
    [copy(<<"assume_stamp_only">>, #{})] ++ ceiling_assumption(Ceiling);
key_assumptions(_Total, Ceiling) ->
    [copy(<<"assume_need_side">>, #{})] ++ ceiling_assumption(Ceiling).

ceiling_assumption(null)    -> [];
ceiling_assumption(Ceiling) ->
    [copy(<<"assume_ceiling">>, #{<<"ceiling">> => money(Ceiling)})].

%% --- deposit (NEED): minimum required at the recommended-path LVR ------------
%% money_range over the price range; 5% on the FHG-backed path (no LMI), the same 5%
%% floor otherwise (the loan path confirms it). Pct sourced from kb.scheme.fhg — one
%% source, not a literal. Honest-partial: no price range → null amount + a note.
deposit(RecPath, [Lo, Hi]) when is_integer(Lo), is_integer(Hi) ->
    Pct  = deposit_pct(),
    Note = case RecPath of
               <<"fhg_backed">> -> copy(<<"deposit_min_fhg">>, #{<<"pct">> => Pct});
               _                -> copy(<<"deposit_min_floor">>, #{<<"pct">> => Pct})
           end,
    #{<<"minimum_required_percentage">> => Pct,
      <<"minimum_required_amount">>     => [pct_of(Pct, Lo), pct_of(Pct, Hi)],
      <<"notes">> => [Note]};
deposit(_RecPath, _Range) ->
    #{<<"minimum_required_percentage">> => null,
      <<"minimum_required_amount">>     => null,
      <<"notes">> => [copy(<<"note_set_range">>, #{})]}.

pct_of(Pct, V) -> round(Pct * V / 100).

deposit_pct() ->
    case fill_value(<<"kb.scheme.fhg">>, <<"eligibility.fhg.deposit_percentage_required">>) of
        P when is_number(P) -> P;
        _                   -> 5
    end.

%% --- other_buying_costs (NEED): regulated registration + convention bands ----
%% total = [reg + Σconv_low, reg + Σconv_high] (money_range). Registration is exact per
%% state (REGULATED, kb.buyer-costs); the inspection/conveyancing/insurance/utility/
%% moving lines are CONVENTION ranges (the buyer's own quotes bind). Evaluated at the
%% range ceiling (the duty-at-ceiling convention); only the convention band widens it.
other_buying_costs(undefined, _Ceiling) ->
    pending_costs(copy(<<"note_state_unknown">>, #{}));
other_buying_costs(_State, null) ->
    pending_costs(copy(<<"note_set_range">>, #{}));
other_buying_costs(State, V) when is_integer(V) ->
    case registration_total(State, V) of
        null -> pending_costs(copy(<<"note_state_unmodelled">>, #{<<"state">> => State}));
        Reg  ->
            {Lo, Hi} = convention_band(),
            #{<<"total">>             => [Reg + Lo, Reg + Hi],
              <<"registration_exact">> => Reg,
              <<"notes">> => [copy(<<"costs_banded">>, #{})]}
    end.

pending_costs(Note) ->
    #{<<"total">> => null, <<"registration_exact">> => null, <<"notes">> => [Note]}.

%% land-titles registration: transfer + mortgage, per state (kb.buyer-costs). NSW flat;
%% VIC/QLD add a value-based transfer component. Rounded to whole dollars (like duty).
registration_total(State, V) ->
    case reg_entry(State) of
        undefined -> null;
        E -> dollars(transfer_reg(E, V) + maps:get(<<"mortgage_registration_flat">>, E))
    end.

transfer_reg(E, V) ->
    case maps:get(<<"transfer_scales_with_value">>, E) of
        false -> maps:get(<<"transfer_registration_flat">>, E);
        true  -> transfer_scaled(E, V)
    end.

%% VIC: base + per-$1000 × whole $1,000s of consideration, capped. QLD: base + per-$10,000
%% × increments (or part) over the threshold. Discriminated by which keys the entry carries.
transfer_scaled(E, V) ->
    case maps:get(<<"transfer_registration_per_1000_consideration">>, E, undefined) of
        Per1000 when is_number(Per1000) ->
            Base = maps:get(<<"transfer_registration_base">>, E),
            Cap  = maps:get(<<"transfer_registration_max">>, E),
            erlang:min(Cap, Base + Per1000 * (V div 1000));
        undefined ->
            Base   = maps:get(<<"transfer_lodgement_base">>, E),
            Per10k = maps:get(<<"transfer_additional_per_10000_over_threshold">>, E),
            Thr    = maps:get(<<"transfer_additional_threshold">>, E),
            Base + Per10k * increments_over(V, Thr, 10000)
    end.

%% increments "or part of" a step over a threshold → round the excess UP.
increments_over(V, Thr, Step) when V > Thr -> ((V - Thr) + Step - 1) div Step;
increments_over(_V, _Thr, _Step)           -> 0.

reg_entry(State) ->
    Entries = maps:get(<<"entries">>,
        maps:get(<<"state_registration_fees">>,
                 lookup(<<"kb.buyer-costs.inspections-conveyancing-fees">>))),
    case lists:search(fun(E) -> maps:get(<<"state">>, E) =:= State end, Entries) of
        {value, E} -> E;
        false      -> undefined
    end.

%% Σ of the convention / lender-policy cost ranges (kb.buyer-costs params). The buyer's
%% own quotes bind; these are typical ranges only (CONVENTION). first_year_building_
%% insurance is the house figure (near-zero for strata — noted in costs_banded copy).
convention_band() ->
    Keys = [<<"building_pest_inspection">>, <<"conveyancing">>, <<"lender_application_fee">>,
            <<"first_year_building_insurance">>, <<"utility_connections">>, <<"moving_costs">>],
    Lo = lists:sum([cost_param(K, <<"_low">>)  || K <- Keys]),
    Hi = lists:sum([cost_param(K, <<"_high">>) || K <- Keys]),
    {Lo, Hi}.

cost_param(Key, Suffix) ->
    param_value(<<"kb.buyer-costs.inspections-conveyancing-fees">>,
                <<Key/binary, Suffix/binary>>).

%% --- reserve_buffer (post-settlement): amount pending at base ----------------
%% = months × monthly repayment; the repayment needs the loan rate (an agent/refine
%% fact), so amount is null at base (honest). The recommended months rides from
%% kb.cash-reserve so the renderer can show the target.
reserve_buffer() ->
    Months = param_value(<<"kb.cash-reserve.lender-expectations">>,
                         <<"recommended_post_settlement_reserve_months">>),
    #{<<"months_of_repayments_recommended">> => Months,
      <<"amount">> => null,
      <<"notes">> => [copy(<<"reserve_pending">>, #{<<"months">> => Months})]}.

%% --- total_cash_required (NEED, money_range) ---------------------------------
%% AT SETTLEMENT = deposit + duty(after concession) + other costs. EXCLUDES the
%% post-settlement reserve_buffer (a separate planning figure, pending at base). null
%% if any contributing line is pending (honest-partial — never a partial sum).
total_cash_required(#{<<"minimum_required_amount">> := [DLo, DHi]},
                    #{<<"after_concession">> := Duty},
                    #{<<"total">> := [OLo, OHi]})
  when is_integer(Duty), is_integer(DLo), is_integer(OLo) ->
    [DLo + Duty + OLo, DHi + Duty + OHi];
total_cash_required(_Deposit, _Sd, _OtherCosts) ->
    null.

%% --- user-facing duty notes (bilingual via kb.copy.cash) ---------------------

duty_notes(_State, true, _V, Saving) when Saving > 0 ->
    [copy(<<"duty_concession_applied">>, #{<<"saving">> => money(Saving)})];
duty_notes(_State, true, _V, _Saving) ->
    [copy(<<"duty_concession_phased_out">>, #{})];
duty_notes(_State, false, _V, _Saving) ->
    [copy(<<"duty_full">>, #{})].

concession_anchor(<<"NSW">>, true) -> [<<"kb.scheme.nsw.fhbas">>];
concession_anchor(<<"VIC">>, true) -> [<<"kb.scheme.vic.fhb-duty">>];
concession_anchor(<<"QLD">>, true) -> [<<"kb.scheme.qld.fhc">>];
concession_anchor(_State, _)       -> [].

%% --- KB access ---------------------------------------------------------------

%% subst a kb.copy.cash template into a bilingual {vi,en} value (no Vietnamese
%% literal in Erlang, no io:format ~s — bilingual-content.md §3b).
-spec copy(binary(), #{binary() => fh_engine_i18n:param()}) -> fh_engine_i18n:localized().
copy(Id, Params) ->
    fh_engine_i18n:subst(fh_engine_kb:copy(?COPY, Id), Params).

scale(Name) -> maps:get(Name, lookup(<<"kb.stamp-duty.calc-by-state">>)).

lookup(Slug) ->
    {ok, Cj} = fh_engine_kb:kb_rules(Slug),
    maps:get(<<"lookup">>, Cj).

thresholds(Slug, ExKey, CapKey) ->
    {param_money(Slug, ExKey), param_money(Slug, CapKey)}.

param_money(Slug, Key) -> param_value(Slug, Key).

%% a KB `parameters[Key].value` (money / integer / percentage — all scalars).
param_value(Slug, Key) ->
    {ok, Cj} = fh_engine_kb:kb_rules(Slug),
    Params = maps:get(<<"parameters">>, Cj),
    maps:get(<<"value">>, maps:get(Key, Params)).

%% a KB `fills` leaf value (e.g. kb.scheme.fhg eligibility.fhg.deposit_percentage_required);
%% null if the leaf is absent. Mirrors fh_engine_eligibility:fill_value/2.
fill_value(Slug, Leaf) ->
    {ok, Cj} = fh_engine_kb:kb_rules(Slug),
    case lists:search(fun(F) -> maps:get(<<"leaf">>, F, undefined) =:= Leaf end,
                      maps:get(<<"fills">>, Cj, [])) of
        {value, F} -> maps:get(<<"value">>, maps:get(<<"rule">>, F, #{}), null);
        false      -> null
    end.

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

%% round half up to whole dollars (duty is always >= 0). Defined identically in the
%% Python spec so the cross-language conformance is exact.
dollars(X) when X =< 0 -> 0;
dollars(X)            -> trunc(X + 0.5).

%% money as a plain "$1,500,000" string — shared formatter (fh_engine_money).
money(N) -> fh_engine_money:money(N).
