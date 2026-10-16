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
%% exported for the Mode-B foreign-person conformance suite:
-export([surcharge_pct/1, surcharge_amount/2, sum_or_null/1, channel_costs/3]).
%% exported for the Mode-D foreign-investor conformance suite:
-export([fill_investor_foreign/2]).
%% exported for the Mode-E next-home conformance suite:
-export([fill_fhb_nexthome/2, gap_range/2, verdict_from_gap/1]).

-define(LENDER_POLICY, <<"kb.lender.investment-loan-policies">>).  %% security-category caps
-define(COPY, <<"kb.copy.cash">>).   %% bilingual copy-templates (bilingual-content.md §3b)
-define(SURCHARGE, <<"kb.foreign-buyer-surcharge.by-state">>).

%% --- entry -------------------------------------------------------------------

%% Mode discriminator (mirrors fh_engine_disposition:fill/2): only the investor blueprint runs
%% a `tax_structure` component, so its outcome's presence upstream marks the Mode-C investor
%% cash_position (budget_envelope_investor). Within the non-investor path, Args.firb_required_any
%% (the SAME flag buyer_profile/1, mortgage_finance's third branch, and the compliance FIRB
%% gate key on) orthogonally marks Mode B's foreign-person cash_position (a THIRD, different
%% budget_envelope shape — fill_fhb_foreign/2, below) vs Mode A's FHB path. Shared component
%% NAME + `calculator` renderer throughout; different outcome TYPE + logic per branch. The FHB
%% body is renamed fill_fhb/2 verbatim (byte-identical — zero regression); the investor body
%% and the Mode-B body are new/newer.
%% MODE-E DISCRIMINATOR: only the nexthome-domestic-au blueprint runs an
%% `existing_home_disposal` component upstream (nexthome-domestic-au.md component 3) — its
%% presence marks the Mode-E next-home path (fill_fhb_nexthome/2), checked BEFORE the
%% investor/foreign branches below since Mode E is domestic + owner-occupier, the same 2x2
%% cell as Mode A (mirrors how `tax_optimised_structure` presence marks the investor path).
-spec fill(map(), map()) -> {map(), binary(), [map()]}.
fill(Args, Upstream) ->
    case maps:is_key(<<"existing_home_disposal">>, Upstream) of
        true  -> fill_fhb_nexthome(Args, Upstream);
        false -> fill_dispatch(Args, Upstream)
    end.

fill_dispatch(Args, Upstream) ->
    case maps:get(<<"tax_optimised_structure">>, Upstream, undefined) of
        undefined ->
            case maps:get(firb_required_any, Args, false) of
                true  -> fill_fhb_foreign(Args, Upstream);
                false -> fill_fhb(Args, Upstream)
            end;
        _Tax ->
            case maps:get(firb_required_any, Args, false) of
                true  -> fill_investor_foreign(Args, Upstream);
                false -> fill_investor(Args, Upstream)
            end
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
    Dep  = home_deposit(Args, RecPath, Range, Ceiling),
    Fees = buy_fees(Args, State, Ceiling, maps:get(loan, Dep), null, undefined, <<"other">>),
    Outcome = budget_envelope(Sd, State, Ceiling, Stack, Fees, Dep),
    KbVersions = fh_engine_kb:kb_anchors(
        [<<"kb.stamp-duty.calc-by-state">>,
         <<"kb.buyer-costs.inspections-conveyancing-fees">>,
         <<"kb.cash-reserve.lender-expectations">>, <<"kb.scheme.fhg">>]
        ++ concession_anchor(State, HasConc) ++ fee_anchors(Fees)),
    {Outcome, <<"calculator">>, KbVersions}.

%% --- Mode-E next-home cash_position (budget_envelope, SAME shape as Mode A) --
%% nexthome-domestic-au.md component 5. Reuses fill_fhb/2's entire NEED side unchanged
%% (deposit, stamp duty, other_buying_costs, reserve_buffer — computed by budget_envelope/6,
%% one computer) since a repeat buyer's transaction costs are structurally identical to a
%% first-home buyer's, less any concession. `Stack` naturally defaults to `#{}` (no
%% `eligibility` component exists for Mode E), so `has_state_concession(#{})` already
%% returns false — full stamp duty, which is the correct regulatory answer (every state's
%% first-home concession requires first-home status), not a gap.
%%
%% The ONE genuine extension: the HAVE side. Mode A's own budget_envelope/6 hardcodes
%% cash_available/gap_or_surplus/verdict to null (no source at base — honest-partial); Mode
%% E has a genuine source, existing_home_disposal.net_sale_proceeds (component 3, mode-e-
%% wedge.md P2) — folded in here via budget_envelope_nexthome/7, which calls budget_envelope/6
%% for the NEED side unchanged and only overrides the three HAVE-side fields.
-spec fill_fhb_nexthome(map(), map()) -> {map(), binary(), [map()]}.
fill_fhb_nexthome(Args, Upstream) ->
    Profile      = maps:get(<<"profile">>, Upstream, #{}),
    Stack        = maps:get(<<"scheme_stack">>, Upstream, #{}),
    Mortgage     = maps:get(<<"mortgage_plan">>, Upstream, #{}),
    ExistingHome = maps:get(<<"existing_home_disposal">>, Upstream, #{}),
    State   = fh_engine_store:projection_state(maps:get(onboarding, Args, #{})),
    Range   = maps:get(<<"target_price_range">>, Profile, null),
    Ceiling = ceiling(Range),
    HasConc = has_state_concession(Stack),
    RecPath = maps:get(<<"recommended_path">>, Mortgage, null),
    Sd = stamp_duty(State, HasConc, Ceiling),
    ExistingNet = maps:get(<<"net_sale_proceeds">>, ExistingHome, null),
    Dep  = home_deposit(Args, RecPath, Range, Ceiling),
    Fees = buy_fees(Args, State, Ceiling, maps:get(loan, Dep), null, undefined, <<"other">>),
    Outcome = budget_envelope_nexthome(Sd, State, Ceiling, Stack, ExistingNet, Fees, Dep),
    %% no kb.scheme.fhg / concession_anchor — a repeat buyer is never FHG-eligible or
    %% state-concession-eligible (both first-home-only), so no misleading anchor is listed.
    KbVersions = fh_engine_kb:kb_anchors(
        [<<"kb.stamp-duty.calc-by-state">>,
         <<"kb.buyer-costs.inspections-conveyancing-fees">>,
         <<"kb.cash-reserve.lender-expectations">>] ++ fee_anchors(Fees)),
    {Outcome, <<"calculator">>, KbVersions}.

%% budget_envelope/6 computes the NEED side (unchanged, one computer); this overrides only
%% the three HAVE-side fields it hardcodes to null, using existing_home_disposal's net
%% proceeds as the HAVE-side source.
budget_envelope_nexthome(Sd, State, Ceiling, Stack, ExistingNet, Fees, Dep) ->
    Base  = budget_envelope(Sd, State, Ceiling, Stack, Fees, Dep),
    Total = maps:get(<<"total_cash_required">>, Base),
    Gap   = gap_range(ExistingNet, Total),
    Base#{
        <<"cash_available">> => ExistingNet,
        <<"gap_or_surplus">> => Gap,
        <<"verdict">>        => verdict_from_gap(Gap)
    }.

%% conservative interval gap: worst-case low = least proceeds − most cost; worst-case high =
%% most proceeds − least cost. null when either side is unknown (honest-partial, mirrors
%% net_proceeds/4's own interval-arithmetic convention in fh_engine_disposition).
-spec gap_range([number()] | null, [number()] | null) -> [number()] | null.
gap_range(null, _Total) -> null;
gap_range(_ExistingNet, null) -> null;
gap_range([ELo, EHi], [TLo, THi]) ->
    [round(ELo - THi), round(EHi - TLo)].

%% three-way verdict — the budget_envelope schema's verdict enum is [surplus, tight, short]
%% (unlike Mode B/D's scalar-gap two-way surplus/short): a gap range spanning zero is
%% honestly "tight", not forced to either extreme.
-spec verdict_from_gap([number()] | null) -> binary() | null.
verdict_from_gap(null) -> null;
verdict_from_gap([GLo, _GHi]) when GLo >= 0 -> <<"surplus">>;
verdict_from_gap([_GLo, GHi]) when GHi < 0  -> <<"short">>;
verdict_from_gap(_) -> <<"tight">>.

%% --- Mode-B foreign-person cash_position (budget_envelope, 10-field shape) --
%% blueprint fhb-foreign-au.md component 6 (mode-b-wedge.md P2 slice 4). A THIRD,
%% different budget_envelope shape from both Mode A's (duty subtree + cash_events) and
%% Mode C's investor point-summary (loan_amount/lvr/lmi_payable) — ten fields:
%% max_property_price_supported, actual_property_price, total_cash_required,
%% regulatory_imposts_total, channel_costs_total, family_capacity_available,
%% gap_or_surplus, verdict, mitigation_options_if_short, key_assumptions.
%%
%% NAMING DISCIPLINE (honest-partial): actual_property_price / max_property_price_supported
%% stay null at base — "actual" means an ATTACHED property (none yet; mirrors Mode C's own
%% base scaffold literally) and "supported" needs borrowing capacity (null until income
%% arrives via mortgage_finance's foreign variant). But the NEED side (regulatory_imposts_
%% total, channel_costs_total, total_cash_required) is honestly COMPUTABLE at base off the
%% CONSERVATIVE upper bound of profile.target_price_range — the same ceiling-estimate
%% convention firb_workflow / mortgage_finance already use, and exactly what the blueprint's
%% own component scope calls for ("Base estimate against target price range").
%%
%% PLACE, DON'T RECOMPUTE: the FIRB fee is READ from firb_workflow's own outcome
%% (Upstream.firb_status.total_firb_fee_payable), never re-derived here
%% ([[place-upstream-figures-dont-recompute]]); the deposit is READ from mortgage_finance's
%% outcome (Upstream.mortgage_plan.deposit_required) the same way.
%%
%% A RESOLVED SEAM (flagged, not silently built both ways): the blueprint's own params
%% block names TWO capacity inputs (au_member_cash_aud <from_buyer_profile>,
%% vn_family_contribution_aud_equivalent <from_family_context>) that this component's
%% params would sum — but buyer_profile_foreign's OWN outcome schema already defines
%% profile.deposit_ready_for_purchase_amount as "AU-side savings + expected funder
%% contributions available" (a blueprint-authored COMBINED figure). Reading BOTH that and
%% family_context.family_funding_plan.total_capacity_aud would double-count the same
%% funds under two names. This fill reads profile.deposit_ready_for_purchase_amount as the
%% sole family_capacity_available source (single-owner); family_context's outcome is not
%% re-summed on top. Currently both are null at base regardless (no savings/funder facts
%% captured yet), so the choice has no observable effect until a refine turn — but it
%% decides which field a future refine-turn write lands on.
-spec fill_fhb_foreign(map(), map()) -> {map(), binary(), [map()]}.
fill_fhb_foreign(Args, Upstream) ->
    Profile    = maps:get(<<"profile">>, Upstream, #{}),
    FirbStatus = maps:get(<<"firb_status">>, Upstream, #{}),
    Mortgage   = maps:get(<<"mortgage_plan">>, Upstream, #{}),
    State   = fh_engine_store:projection_state(maps:get(onboarding, Args, #{})),
    Ceiling = ceiling(maps:get(<<"target_price_range">>, Profile, null)),
    %% no FHB concession — not available to a foreign person (blueprint:
    %% first_home_concession_applicable_for_foreign_person = false, definitional).
    Duty      = stamp_duty(State, false, Ceiling),
    DutyAfter = maps:get(<<"after_concession">>, Duty, null),
    Surcharge = surcharge_amount(State, Ceiling),
    FirbFee   = maps:get(<<"total_firb_fee_payable">>, FirbStatus, null),
    %% base convention: the mortgage variant's own deposit_required default (30%,
    %% kb.lender.foreign-buyer-deposit-requirements) is well above the 80%-LVR/20%-deposit
    %% LMI trigger, so LMI is not applicable at the base estimate (kb.lmi.calculation-for-
    %% foreign-persons: "typically $0" for a foreign-income borrower) — a KB-grounded
    %% convention, not a code-invented zero.
    Lmi = 0,
    RegulatoryImposts = sum_or_null([DutyAfter, Surcharge, FirbFee, Lmi]),
    BSlug = <<"kb.lender.foreign-buyer-deposit-requirements">>,
    BPct  = param_value(BSlug, <<"non_resident_deposit_pct_typical">>),
    {Deposit, Bounds, DepDetail} =
        own_deposit(Args, maps:get(<<"deposit_required">>, Mortgage, null), BPct, Ceiling,
                    {BSlug, <<"deposit">>, #{<<"pct">> => fh_engine_line_detail:pct(BPct)}}),
    Loan = minus(Ceiling, Deposit),
    Fees = buy_fees(Args, State, Ceiling, Loan,
                    sum_or_null([Deposit, RegulatoryImposts]), undefined, <<"other">>),
    ChannelCosts = channel_costs(State, Ceiling, Fees, Loan),
    TotalCashRequired = sum_or_null([Deposit, RegulatoryImposts, ChannelCosts]),
    FamilyCapacity = maps:get(<<"deposit_ready_for_purchase_amount">>, Profile, null),
    {GapOrSurplus, Verdict} = gap_and_verdict(FamilyCapacity, TotalCashRequired),
    Outcome = #{
        <<"max_property_price_supported">> => null,
        <<"actual_property_price">>        => null,
        <<"total_cash_required">>          => TotalCashRequired,
        <<"regulatory_imposts_total">>     => RegulatoryImposts,
        <<"channel_costs_total">>          => ChannelCosts,
        <<"family_capacity_available">>    => FamilyCapacity,
        <<"gap_or_surplus">>               => GapOrSurplus,
        <<"verdict">>                      => Verdict,
        <<"mitigation_options_if_short">>  => [],
        <<"cash_events">>                  =>
            line_details(cash_events_foreign(Deposit, DutyAfter, Surcharge, FirbFee,
                                             registration(State, Ceiling, Loan), Fees),
                         State, {ceiling, Ceiling}, Duty, DepDetail),
        <<"fee_pending">>                  => fee_pending(Fees),
        <<"deposit_bounds">>               => Bounds,
        <<"key_assumptions">>              => key_assumptions_foreign(Ceiling, State)
    },
    KbVersions = fh_engine_kb:kb_anchors(
        [<<"kb.stamp-duty.calc-by-state">>, <<"kb.foreign-buyer-surcharge.by-state">>,
         <<"kb.firb.fee-schedule-current">>, <<"kb.fx.typical-spreads-vnd-aud">>,
         <<"kb.buyer-costs.inspections-conveyancing-fees">>,
         <<"kb.cash-reserve.lender-expectations">>,
         <<"kb.lmi.calculation-for-foreign-persons">>]),
    {Outcome, <<"calculator">>, KbVersions}.

%% --- cash_events_foreign (Mode B's ACQUISITION financial spine, task 12) -----
%% Same placement discipline as cash_events/4 (Mode A): PLACES this function's own
%% already-computed figures as phased money events — computes nothing new. Unlike Mode
%% D's cash_position (fill_investor_foreign/2, permanently null at base — no cash_events
%% built there, an honest stub), Mode B's ceiling-estimate convention means Deposit/
%% DutyAfter/Surcharge/FirbFee/ChannelCosts are ALL honestly computable from
%% profile.target_price_range alone (no property attached yet) — so a real event-builder
%% is live, not dead, code.
%%
%% firb_fee is placed at CONTRACT, not settle: grounded in kb.firb.application-process
%% ("Pay the application fee ... the 30-day statutory decision clock does not start
%% until the correct fee is paid in full") — the fee is paid when the application is
%% lodged, which happens at or shortly after exchange (mirrors
%% kb.journey.fhb-foreign-phase-actions' own submit_firb_application action at
%% `contract`), well before settlement. deposit is placed at CONTRACT with counterparty
%% `other` (held in trust, not paid to the lender) — identical to Mode A's own deposit
%% event. stamp_duty / foreign_buyer_surcharge / other_buying_costs fall due at SETTLE,
%% same phase Mode A places its own stamp_duty/other_buying_costs events.
%%
%% Lmi is NOT an event: it is always 0 by the base convention (deposit_required is well
%% above the 80%-LVR/20%-deposit LMI trigger at this conservative estimate,
%% key_assumptions_foreign's own assume_no_lmi_at_conservative_deposit) — a zero-value
%% event would carry no real information, unlike Mode C's cash_events_investor/4 (where
%% LMI can genuinely be non-zero per-property).
%%
%% Mode D reuses it (#13, 2026-10-06) with Other = <<"services">>: its swimlane is Mode C's
%% six actors, which hold the conveyancer/trust chain as `services`, not Mode A/B's `other`.
-spec cash_events_foreign(number() | null, number() | null, number() | null,
                          number() | null, number() | null, fees()) -> [map()].
cash_events_foreign(Deposit, DutyAfter, Surcharge, FirbFee, Reg, Fees) ->
    cash_events_foreign(Deposit, DutyAfter, Surcharge, FirbFee, Reg, Fees, <<"other">>).

-spec cash_events_foreign(number() | null, number() | null, number() | null,
                          number() | null, number() | null, fees(), binary()) -> [map()].
cash_events_foreign(Deposit, DutyAfter, Surcharge, FirbFee, Reg, {FeeEvents, _}, Other) ->
    Out = [
        event(<<"deposit">>, <<"contract">>, <<"event_deposit">>, <<"out">>,
              point(Deposit), false, Other, <<"cash_position">>),
        event(<<"firb_fee">>, <<"contract">>, <<"event_firb_fee">>, <<"out">>,
              point(FirbFee), false, <<"government">>, <<"cash_position">>),
        event(<<"stamp_duty">>, <<"settle">>, <<"event_stamp_duty">>, <<"out">>,
              point(DutyAfter), false, <<"government">>, <<"cash_position">>),
        event(<<"foreign_buyer_surcharge">>, <<"settle">>, <<"event_foreign_buyer_surcharge">>, <<"out">>,
              point(Surcharge), false, <<"government">>, <<"cash_position">>),
        registration_event(Reg, <<"government">>)
    ],
    [E || E <- Out, maps:get(<<"amount">>, E) =/= null] ++ FeeEvents.

%% kb.foreign-buyer-surcharge.by-state: amount = dutiable value × rate (postcondition
%% vs the state revenue calculator, same discipline as stamp_duty/3). null for an
%% unmodelled/unknown state or price, honest-partial.
-spec surcharge_amount(binary() | undefined, integer() | null) -> integer() | null.
surcharge_amount(State, V) when is_integer(V) ->
    case surcharge_pct(State) of
        null -> null;
        Pct  -> dollars(V * Pct / 100)
    end;
surcharge_amount(_State, _V) -> null.

-spec surcharge_pct(binary() | undefined) -> number() | null.
surcharge_pct(<<"NSW">>) -> param_value(?SURCHARGE, <<"nsw_surcharge_pct">>);
surcharge_pct(<<"VIC">>) -> param_value(?SURCHARGE, <<"vic_surcharge_pct">>);
surcharge_pct(<<"QLD">>) -> param_value(?SURCHARGE, <<"qld_surcharge_pct">>);
surcharge_pct(<<"WA">>)  -> param_value(?SURCHARGE, <<"wa_surcharge_pct">>);
surcharge_pct(<<"SA">>)  -> param_value(?SURCHARGE, <<"sa_surcharge_pct">>);
surcharge_pct(<<"TAS">>) -> param_value(?SURCHARGE, <<"tas_surcharge_pct">>);
surcharge_pct(<<"ACT">>) -> 0;
surcharge_pct(<<"NT">>)  -> 0;
surcharge_pct(_)         -> null.

%% registration (exact, per state) + the midpoint of the buy fee lines the plan pays for
%% sure (fh_engine_fees:committed/1; behavior 83 — they replaced a three-line convention
%% band). Foreign-only lines (translation, FIRB help, the transfer from Vietnam) are among
%% them when their owning docs say they apply to the mode.
-spec channel_costs(binary() | undefined, integer() | null, fees()) -> integer() | null.
channel_costs(State, V, Fees) -> channel_costs(State, V, Fees, undefined).

%% with the loan: a plan bought outright registers no mortgage (registration/3).
channel_costs(State, V, {FeeEvents, _}, Loan) when is_integer(V) ->
    case registration(State, V, Loan) of
        null -> null;
        Reg  -> Reg + mid(fh_engine_fees:committed(FeeEvents))
    end;
channel_costs(_State, _V, _Fees, _Loan) -> null.

%% sum a list of contributing lines; null (never a partial sum) if ANY is unknown —
%% the honest-partial discipline for an aggregate total (mirrors total_cash_investor/3's
%% "null if any contributing line is pending").
-spec sum_or_null([number() | null]) -> number() | null.
sum_or_null(Lines) ->
    case lists:any(fun(L) -> L =:= null end, Lines) of
        true  -> null;
        false -> lists:sum(Lines)
    end.

%% surplus = capacity − required (positive = surplus); null/null when either side is
%% unknown (never a partial verdict). Bands are the same tight/short framing as Mode A's
%% own verdict; a real threshold-tuned "tight" band is a refine-turn concern once both
%% sides are consistently populated — base honestly resolves surplus/short only.
gap_and_verdict(null, _Required)         -> {null, null};
gap_and_verdict(_Capacity, null)         -> {null, null};
gap_and_verdict(Capacity, Required) ->
    Gap = Capacity - Required,
    Verdict = case Gap >= 0 of
                  true  -> <<"surplus">>;
                  false -> <<"short">>
              end,
    {Gap, Verdict}.

%% Mode-B key_assumptions: the shared ceiling-estimate framing (assume_ceiling, reused
%% from Mode A — no mode-specific claim) plus the three foreign-person-specific
%% disclosures (no first-home concession, the FX transfer estimated, the no-LMI base
%% convention). Bilingual via kb.copy.cash; interpolated params only.
-spec key_assumptions_foreign(integer() | null, binary() | undefined) ->
          [fh_engine_i18n:localized()].
key_assumptions_foreign(null, _State) ->
    [copy(<<"note_set_range">>, #{})];
key_assumptions_foreign(Ceiling, _State) ->
    DepositPct = param_value(<<"kb.lender.foreign-buyer-deposit-requirements">>,
                             <<"non_resident_deposit_pct_typical">>),
    [copy(<<"assume_ceiling">>, #{<<"ceiling">> => money(Ceiling)}),
     copy(<<"assume_no_concession_foreign_person">>, #{}),
     copy(<<"assume_fx_estimated">>, #{}),   %% the fx_spread_in fee line (behavior 83)
     copy(<<"assume_no_lmi_at_conservative_deposit">>, #{<<"pct">> => DepositPct})].

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
%%   2. RESOLVED (2026-07-10, the B/C/D lifecycle-spine restructure, task 4): budget_envelope_
%%      investor now carries `cash_events` (deposit/stamp_duty/other_buying_costs/lmi — see
%%      cash_events_investor/4 below), so purchase_journey's generic multi-source harvest can
%%      place the investor acquire-phase spine with zero Mode-C-specific journey code
%%      ([[unify-views-as-projections-of-one-primitive]]). entity_setup_costs is NOT an
%%      event: tax_optimised_structure.setup_costs is an INDICATIVE band placed after the
%%      entity agent runs (behavior 11, #12), shown on the tax card and kept out of the point
%%      cash total and its events.
-spec fill_investor(map(), map()) -> {map(), binary(), [map()]}.
fill_investor(Args, Upstream) ->
    %% Branch on the per-property keystone (Slice B3b): at base property_fit_investor is absent →
    %% the all-null scaffold plus the ceiling-basis acquisition events (behavior 82); per-property
    %% (Phase-B) it carries the exact price → the cash-to-complete.
    Outcome = case maps:get(<<"property_fit_investor">>, Upstream, undefined) of
                  Pf when is_map(Pf), map_size(Pf) > 0 -> budget_envelope_investor(Args, Pf);
                  _ -> {Events, Bounds} = base_cash_events_investor(Args, Upstream),
                       (budget_envelope_investor_base())#{
                           <<"cash_events">> => Events, <<"deposit_bounds">> => Bounds}
              end,
    KbVersions = fh_engine_kb:kb_anchors(
        [<<"kb.stamp-duty.calc-by-state">>,
         <<"kb.investor.deposit-requirements-investment-loans">>,
         <<"kb.lmi.calculation">>,
         <<"kb.buyer-costs.investor-additional-costs">>,
         <<"kb.tax.quantity-surveyor-reports">>,
         <<"kb.tax.entity-setup-costs">>,
         ?LENDER_POLICY]),
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
      <<"mitigation_options_if_short">>  => [],
      <<"key_assumptions">>              => [],
      <<"cash_events">>                  => [],
      <<"deposit_bounds">>               => null}.

%% Slice B3b — the per-property cash-to-complete (NEED side), POINT figures off the attached
%% property's EXACT price (so scalar `money`, not banded): loan at the LVR baseline (80% — the
%% 20%-deposit/no-LMI planning baseline, deposit-requirements), the deposit, full stamp duty (no
%% FHB concession — investor; no foreign surcharge for a domestic investor), and the acquisition
%% adders. lmi_payable = 0 at the 80% baseline. The HAVE side (gap_or_surplus, verdict) and
%% max_property_price_supported (borrowing capacity → income, a refine fact) stay null — honest-
%% partial. Honest-partial too if the price/state are missing or the state's duty isn't modelled.
budget_envelope_investor(Args, Pf) ->
    Price = maps:get(<<"price">>, Pf, null),
    State = maps:get(<<"state">>, Pf, null),
    case is_integer(Price) andalso Price > 0 andalso is_binary(State) of
        false -> budget_envelope_investor_base();
        true ->
            Kind = fh_engine_fees:property_kind(maps:get(<<"property_type">>, Pf, null)),
            #{lvr := Lvr, loan := Loan, deposit := Deposit, duty := Duty, acq := Acq,
              fees := Fees, lmi := Lmi, bounds := Bounds, detail := DepDetail} =
                investor_need(Args, State, Price, Kind),
            (budget_envelope_investor_base())#{
                <<"actual_property_price">> => Price,
                <<"loan_amount">>           => Loan,
                <<"lvr">>                   => Lvr,
                <<"lmi_payable">>           => lmi_point(Lmi),
                <<"total_cash_required">>   =>
                    plus_point(total_cash_investor(Deposit, Duty, Acq), lmi_point(Lmi)),
                <<"key_assumptions">>       =>
                    security_lvr_caveat(maps:get(<<"property_type">>, Pf, null)),
                <<"cash_events">>           =>
                    line_details(
                        cash_events_investor(Deposit, Duty, registration(State, Price, Loan),
                                             lmi_amount(Lmi), Fees),
                        State, {property, Price}, #{}, DepDetail, lmi_detail(Lmi, Loan, Price)),
                <<"fee_pending">>           => fee_pending(Fees),
                <<"deposit_bounds">>        => Bounds
            }
    end.

%% the NEED side at one price: the 80% LVR baseline loan, the deposit, full duty (no FHB
%% concession), the acquisition adders. Shared by the per-property figures and the base events.
%% behavior 101: the visitor's own deposit replaces the 20% baseline, floored at the doc's
%% minimum with LMI (deposit_min_with_lmi_pct); LMI follows kb.lmi.calculation above 80%.
investor_need(Args, State, Price, Kind) ->
    Slug    = <<"kb.investor.deposit-requirements-investment-loans">>,
    Base    = Price - round(Price * (100 - param_value(Slug, <<"deposit_no_lmi_pct">>)) / 100),
    {Deposit, Bounds, Detail} =
        own_deposit(Args, Base, param_value(Slug, <<"deposit_min_with_lmi_pct">>), Price,
                    investor_deposit_detail()),
    Loan    = Price - Deposit,
    Duty    = maps:get(<<"after_concession">>, stamp_duty(State, false, Price), null),
    Fees    = buy_fees(Args, State, Price, Loan, null, Kind, <<"services">>),
    Acq     = acquisition_costs_investor(State, Price, Fees, Loan),
    #{lvr => round(Loan * 100 / Price), loan => Loan, deposit => Deposit, duty => Duty,
      acq => Acq, fees => Fees, lmi => fh_engine_lmi:premium(Loan, Price),
      bounds => Bounds, detail => Detail}.

%% Whole lifecycle -> each phase has its money lines -> Mode C cash_position -> base events.
%% Goal: the lifecycle sheet (behavior 82) shows Mode C's cash to buy before a property is
%% attached. Invariant: honest-partial — the scalar fields stay null (no property, no price);
%% only the events carry figures, each labelled at the CONSERVATIVE ceiling of the target
%% range, the same basis Mode D's base cash_position uses (fill_investor_foreign/2).
%% Capability: deposit, duty, acquisition adders and LMI 0 at the ceiling; [] when the
%% state or range is missing. Measured 2026-10-16: before this Mode C emitted no buy event
%% at base (escript over fh_engine_simulate:run).
base_cash_events_investor(Args, Upstream) ->
    Profile = maps:get(<<"profile">>, Upstream, #{}),
    State   = fh_engine_store:projection_state(maps:get(onboarding, Args, #{})),
    Ceiling = ceiling(maps:get(<<"target_price_range">>, Profile,
                               maps:get(<<"target_price_range">>, maps:get(onboarding, Args, #{}), null))),
    case is_integer(Ceiling) andalso Ceiling > 0 andalso is_binary(State) of
        false -> {[], null};
        true  ->
            #{loan := Loan, deposit := Deposit, duty := Duty, fees := Fees, lmi := Lmi,
              bounds := Bounds, detail := Detail} =
                investor_need(Args, State, Ceiling, undefined),
            {line_details(
                cash_events_investor(Deposit, Duty, registration(State, Ceiling, Loan),
                                     lmi_amount(Lmi), Fees),
                State, {ceiling, Ceiling}, #{}, Detail, lmi_detail(Lmi, Loan, Ceiling)),
             Bounds}
    end.

%% Goal: regulated figures are grounded, honest about their tier -> a CONVENTION is stated as a
%% caveat, never folded into a figure -> Mode C cash_position -> flag a lender security cap.
%% Lenders commonly cap LVR at ~70-80% on high-density apartments (kb.lender.investment-loan-
%% policies, security_category_policy; CONVENTION — no primary source, policies sit behind broker
%% portals). The loan and deposit stay at the 80% baseline; an attached property whose type the
%% KB lists in lvr_cap_property_types adds one bilingual line, no lender named (#3, behavior 13).
security_lvr_caveat(PType) when is_binary(PType) ->
    case lists:member(PType, param_value(?LENDER_POLICY, <<"lvr_cap_property_types">>)) of
        true  -> [copy(<<"assumption_security_lvr_cap">>, #{})];
        false -> []
    end;
security_lvr_caveat(_) -> [].

%% --- cash_events_investor (the investor ACQUISITION financial spine) ---------
%% Mirrors cash_events/4's shape exactly (same event/8 builder) so purchase_journey's
%% generic multi-source harvest places these on the swimlane with zero Mode-C-specific
%% journey code. Counterparty swaps Mode A's generic "other" row for "services"
%% (kb.journey.investor-path's six-actor set — the deposit/other-buying-costs settlement
%% chain runs through the conveyancer/trust, not a party Mode A already has a row for).
%% Honest-partial: an event is emitted only when its figure is non-null.
cash_events_investor(Deposit, Duty, Reg, Lmi, {FeeEvents, _}) ->
    Out = [
        event(<<"deposit">>, <<"contract">>, <<"event_deposit">>, <<"out">>,
              point(Deposit), false, <<"services">>, <<"cash_position">>),
        event(<<"stamp_duty">>, <<"settle">>, <<"event_stamp_duty">>, <<"out">>,
              point(Duty), false, <<"government">>, <<"cash_position">>),
        registration_event(Reg, <<"government">>),
        event(<<"lmi">>, <<"settle">>, <<"event_lmi">>, <<"out">>,
              amount(Lmi), Lmi =/= [0, 0], <<"lender">>, <<"cash_position">>)
    ],
    [E || E <- Out, maps:get(<<"amount">>, E) =/= null] ++ FeeEvents.

%% acquisition adders for an investor (kb.buyer-costs.investor-additional-costs): registration
%% (exact, per state) + the shared due-diligence/legal lines (building+pest inspection,
%% conveyancing, lender application fee) collapsed to a representative point. EXCLUDES the
%% owner-occupier / holding lines (moving, utility connections, and building insurance — the last
%% is a recurring OPERATING expense in yield_modelling, never an acquisition cost; no double-count).
%% The conditional adders (lease review if tenant-in-situ, QS report, entity setup) are surfaced as
%% considerations, not summed into the baseline cash. null when the state's registration isn't modelled.
acquisition_costs_investor(State, Price, {FeeEvents, _}, Loan) ->
    case registration(State, Price, Loan) of
        null -> null;
        Reg  -> Reg + mid(fh_engine_fees:committed(FeeEvents))
    end.

%% = deposit + duty + acquisition adders; null if any contributing line is pending (honest-partial,
%% never a partial sum) — e.g. an unmodelled state's duty/registration.
total_cash_investor(Deposit, Duty, Acq)
  when is_integer(Deposit), is_integer(Duty), is_integer(Acq) ->
    Deposit + Duty + Acq;
total_cash_investor(_, _, _) ->
    null.

%% --- Mode-D foreign-investor cash_position (budget_envelope_investor, 9-field shape) --
%% investor-foreign-au.md component 8 — combines Mode B's foreign-buyer regulatory-impost
%% stack (FIRB fee + surcharge, no concession) with Mode C's investor cost stack, under the
%% REUSED `budget_envelope_investor` key (2026-07-03 outcome-type conformance reconciliation)
%% so fh_engine_disposition's existing full_horizon_investor/loan_payout_investor (which read
%% `total_cash_required`/`loan_amount` off exactly this key) route Mode D onto the SAME
%% acquire-figure placement Mode C uses, with zero disposition change for this seam.
%%
%% Mode D's declared field set drops Mode C's lmi_payable/mitigation_options_if_short and adds
%% regulatory_imposts_total/channel_costs_total (Mode B's own two rollup fields) — the same
%% "shared type, mode-specific field superset" pattern mortgage_plan/budget_envelope already
%% use live. loan_amount/lvr stay null at base (Slice-B3b-style per-property figures, unbuilt
%% for Mode D in P2 — mirrors Mode C's own budget_envelope_investor_base()).
%%
%% NAMING DISCIPLINE (honest-partial, mirrors fill_fhb_foreign/2's own note): actual_property_
%% price / max_property_price_supported stay null (no property attached; capacity unknown).
%% The NEED side (regulatory_imposts_total, channel_costs_total, total_cash_required) is
%% honestly COMPUTABLE at base off the CONSERVATIVE ceiling of profile.target_price_range —
%% the same convention firb_workflow / mortgage_finance / fill_fhb_foreign already use.
%%
%% PLACE, DON'T RECOMPUTE: the FIRB fee is READ from firb_workflow's outcome
%% (Upstream.firb_status.total_firb_fee_payable); the deposit is READ from mortgage_finance's
%% Mode-D outcome (Upstream.mortgage_plan.deposit_required_amount) — never re-derived here.
-spec fill_investor_foreign(map(), map()) -> {map(), binary(), [map()]}.
fill_investor_foreign(Args, Upstream) ->
    Profile    = maps:get(<<"profile">>, Upstream, #{}),
    FirbStatus = maps:get(<<"firb_status">>, Upstream, #{}),
    Mortgage   = maps:get(<<"mortgage_plan">>, Upstream, #{}),
    State   = fh_engine_store:projection_state(maps:get(onboarding, Args, #{})),
    Ceiling = ceiling(maps:get(<<"target_price_range">>, Profile, null)),
    %% no FHB concession — never available to an investor purchase (Mode C's own investor
    %% duty convention, HasConc=false); no foreign-buyer surcharge relief either.
    Duty      = stamp_duty(State, false, Ceiling),
    DutyAfter = maps:get(<<"after_concession">>, Duty, null),
    Surcharge = surcharge_amount(State, Ceiling),
    FirbFee   = maps:get(<<"total_firb_fee_payable">>, FirbStatus, null),
    RegulatoryImposts = sum_or_null([DutyAfter, Surcharge, FirbFee]),
    %% reuses the SAME due-diligence/legal + registration convention band Mode B's
    %% channel_costs/2 already sums (building/pest inspection, conveyancing, lender
    %% application fee + per-state registration) — investor-agnostic, no double build.
    DSlug = <<"kb.non-resident.investment-loan-deposit-requirements">>,
    DPct  = param_value(DSlug, <<"non_resident_investment_deposit_pct_low">>),
    {Deposit, Bounds, DepDetail} =
        own_deposit(Args, maps:get(<<"deposit_required_amount">>, Mortgage, null), DPct,
                    Ceiling, non_resident_deposit_detail()),
    Loan = minus(Ceiling, Deposit),
    Fees = buy_fees(Args, State, Ceiling, Loan,
                    sum_or_null([Deposit, RegulatoryImposts]), undefined, <<"services">>),
    ChannelCosts = channel_costs(State, Ceiling, Fees, Loan),
    TotalCashRequired = sum_or_null([Deposit, RegulatoryImposts, ChannelCosts]),
    %% the VN-side available capital (investor_profile_foreign's own field) is the HAVE side —
    %% null at base (genuinely uncaptured), same honest-partial call as Mode B's family
    %% capacity read.
    Capital = maps:get(<<"available_capital_aud_equivalent">>, Profile, null),
    {GapOrSurplus, Verdict} = gap_and_verdict(Capital, TotalCashRequired),
    Outcome = #{
        <<"max_property_price_supported">> => null,
        <<"actual_property_price">>        => null,
        <<"total_cash_required">>          => TotalCashRequired,
        <<"regulatory_imposts_total">>     => RegulatoryImposts,
        <<"channel_costs_total">>          => ChannelCosts,
        <<"loan_amount">>                  => null,
        <<"lvr">>                          => null,
        <<"gap_or_surplus">>               => GapOrSurplus,
        <<"verdict">>                      => Verdict,
        %% The acquisition spine at the range ceiling, the figures summed above and placed
        %% by Mode B's builder (#13, 2026-10-06; it was [] since task 8). Each event appears
        %% only when its figure is known, so an unknown state drops duty, surcharge and
        %% other costs. Mode D has no per-property cash_position turn in launch scope.
        <<"cash_events">>                  =>
            line_details(cash_events_foreign(Deposit, DutyAfter, Surcharge, FirbFee,
                                             registration(State, Ceiling, Loan), Fees,
                                             <<"services">>),
                         State, {ceiling, Ceiling}, Duty, DepDetail),
        <<"fee_pending">>                  => fee_pending(Fees),
        <<"deposit_bounds">>               => Bounds
    },
    KbVersions = fh_engine_kb:kb_anchors(
        [<<"kb.stamp-duty.calc-by-state">>, <<"kb.foreign-buyer-surcharge.by-state">>,
         <<"kb.firb.fee-schedule-current">>, <<"kb.fx.typical-spreads-vnd-aud">>,
         <<"kb.buyer-costs.inspections-conveyancing-fees">>,
         <<"kb.cash-reserve.lender-expectations">>,
         <<"kb.non-resident.investment-loan-deposit-requirements">>,
         <<"kb.tax.quantity-surveyor-reports">>, <<"kb.tax.entity-setup-costs">>]),
    {Outcome, <<"calculator">>, KbVersions}.

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

budget_envelope(Sd, State, Ceiling, Stack, Fees, Dep) ->
    Deposit    = maps:get(map, Dep),
    Lmi        = maps:get(lmi, Dep),
    OtherCosts = other_buying_costs(State, Ceiling, Fees, maps:get(loan, Dep)),
    Total      = plus_range(total_cash_required(Deposit, Sd, OtherCosts), Lmi),
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
      <<"cash_events">>                  =>
          line_details(cash_events(Deposit, Sd, OtherCosts, Stack, Fees)
                       ++ lmi_events(Lmi, <<"other">>),
                       State, {ceiling, Ceiling}, Sd, maps:get(detail, Dep),
                       lmi_detail(Lmi, maps:get(loan, Dep), Ceiling)),
      <<"fee_pending">>                  => fee_pending(Fees),
      <<"deposit_bounds">>               => maps:get(bounds, Dep),
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
cash_events(Deposit, Sd, OtherCosts, Stack, {FeeEvents, _}) ->
    Out = [
        event(<<"deposit">>, <<"contract">>, <<"event_deposit">>, <<"out">>,
              amount(maps:get(<<"minimum_required_amount">>, Deposit, null)),
              false, <<"other">>, <<"cash_position">>),
        event(<<"stamp_duty">>, <<"settle">>, <<"event_stamp_duty">>, <<"out">>,
              point(maps:get(<<"after_concession">>, Sd, null)),
              false, <<"government">>, <<"cash_position">>),
        registration_event(maps:get(<<"registration_exact">>, OtherCosts, null), <<"government">>)
    ],
    In = grant_events(Stack),
    [E || E <- Out ++ In, maps:get(<<"amount">>, E) =/= null] ++ FeeEvents.

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

%% --- other_buying_costs (NEED): regulated registration + the fee lines ----------
%% total = [reg + Σlow, reg + Σhigh] over the buy fee lines the plan pays for sure
%% (fh_engine_fees:committed/1 — not an optional line, not one whose property condition is
%% open). Registration is exact per state (REGULATED, kb.buyer-costs); each fee line is a
%% band its owning doc sources (behavior 83: the lines replaced one summed convention band,
%% so the buyer sees them one by one). Evaluated at the range ceiling (the duty-at-ceiling
%% convention); only the fee bands widen it.
other_buying_costs(undefined, _Ceiling, _Fees, _Loan) ->
    pending_costs(copy(<<"note_state_unknown">>, #{}));
other_buying_costs(_State, null, _Fees, _Loan) ->
    pending_costs(copy(<<"note_set_range">>, #{}));
other_buying_costs(State, V, {FeeEvents, _}, Loan) when is_integer(V) ->
    case registration(State, V, Loan) of
        null -> pending_costs(copy(<<"note_state_unmodelled">>, #{<<"state">> => State}));
        Reg  ->
            [Lo, Hi] = fh_engine_fees:committed(FeeEvents),
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

%% --- the fee lines (behavior 83) -------------------------------------------------
%% Whole lifecycle -> honesty tiers; one owner per fact -> cash_position -> buy fee lines
%% Purpose:   the acquisition fees a buyer cannot know until they get a quote, one event
%%            each (fh_engine_fees reads them from their owning KB docs), in place of the
%%            one other_buying_costs event that summed them; registration stays its own
%%            exact line (REGULATED, the state's fee).
%% Holds:     bases at the range ceiling (the duty convention): price = the ceiling, loan =
%%            the ceiling less the deposit, transfer (the money sent from Vietnam, modes B/D)
%%            = deposit + duty + surcharge + FIRB fee. A line whose base is unknown is in
%%            `fee_pending` naming the input, never a guessed figure.
-type fees() :: {[map()], [map()]}.

buy_fees(Args, State, Price, Loan, Transfer, Kind, Counterparty) ->
    fh_engine_fees:buy_lines(
      #{blueprint => maps:get(blueprint_slug, Args, <<"fhb-domestic-au">>),
        state => case State of S when is_binary(S) -> S; _ -> undefined end,
        property => Kind, source => <<"cash_position">>, counterparty => Counterparty,
        price => point(Price), loan => point(Loan), transfer => point(Transfer),
        rent => null, sale => null}).

fee_pending({_, Pending}) -> Pending.

fee_anchors({Events, _}) ->
    lists:usort([maps:get(<<"owner">>, maps:get(<<"detail">>, E)) || E <- Events]).

registration_event(Reg, Counterparty) ->
    (event(<<"registration">>, <<"settle">>, <<"event_registration">>, <<"out">>,
           point(Reg), false, Counterparty, <<"cash_position">>))#{
        <<"group">> => <<"other_buying_costs">>}.

%% Whole lifecycle -> every statement line opens its own detail -> cash_position -> the buy
%% lines' details (behavior 93).
%% Goal: a buy line that is not a fee (deposit, duty, registration, surcharge, FIRB fee, a
%% grant, LMI) opens in place like a fee line does, instead of a whole component card.
%% Invariant: the detail names the figures this module computed the line with — the price
%% basis (range ceiling or the attached property), the state, the deposit % — and the doc
%% that owns the figure (fh_engine_line_detail); never another computation.
%% Capability: the details every mode shares; Deposit is the mode's own deposit
%% {Slug, EntryId, Params} (its price phrase is added here). No price → no events to detail.
line_details(Events, State, Price, Sd, Deposit) ->
    line_details(Events, State, Price, Sd, Deposit, lmi_none_detail()).

line_details(Events, State, {Basis, Price}, Sd, {DepSlug, DepId, DepParams}, {LSlug, LId, LParams})
  when is_number(Price) ->
    PriceP = fh_engine_line_detail:price(Basis, Price),
    Ctx = fun(P) -> #{state => State, params => P} end,
    Spec0 = #{
        <<"deposit">> => {DepSlug, DepId, Ctx(DepParams#{<<"price">> => PriceP})},
        <<"stamp_duty">> => duty_detail(State, PriceP, Sd),
        <<"registration">> => {<<"kb.buyer-costs.inspections-conveyancing-fees">>,
                               <<"registration">>,
                               Ctx(#{<<"state">> => State, <<"price">> => PriceP})},
        <<"firb_fee">> => {<<"kb.firb.fee-schedule-current">>, <<"firb_fee">>,
                           Ctx(#{<<"price">> => PriceP})},
        <<"lmi">> => {LSlug, LId, Ctx(LParams)}},
    Spec1 = case surcharge_pct(State) of
                null -> Spec0;
                Pct  -> Spec0#{<<"foreign_buyer_surcharge">> =>
                                   {?SURCHARGE, <<"surcharge">>,
                                    Ctx(#{<<"pct">> => fh_engine_line_detail:pct(Pct),
                                          <<"price">> => PriceP, <<"state">> => State})}}
            end,
    Spec = maps:merge(Spec1, grant_details(Events, State)),
    fh_engine_line_detail:attach_all(Events, Spec);
line_details(Events, _State, _Price, _Sd, _Deposit, _Lmi) ->
    Events.

%% each mode's deposit line: the doc whose % the deposit was computed at.
home_deposit_detail(RecPath) ->
    Id = case RecPath of <<"fhg_backed">> -> <<"deposit_fhg">>; _ -> <<"deposit_floor">> end,
    {<<"kb.scheme.fhg">>, Id, #{<<"pct">> => fh_engine_line_detail:pct(deposit_pct())}}.

investor_deposit_detail() ->
    Slug = <<"kb.investor.deposit-requirements-investment-loans">>,
    {Slug, <<"deposit">>,
     #{<<"pct">> => fh_engine_line_detail:pct(param_value(Slug, <<"deposit_no_lmi_pct">>))}}.

non_resident_deposit_detail() ->
    Slug = <<"kb.non-resident.investment-loan-deposit-requirements">>,
    {Slug, <<"deposit">>,
     #{<<"pct">> => fh_engine_line_detail:pct(fh_engine_mortgage:deposit_pct_foreign()),
       <<"lo">> => fh_engine_line_detail:pct(
                       param_value(Slug, <<"non_resident_investment_deposit_pct_low">>)),
       <<"hi">> => fh_engine_line_detail:pct(
                       param_value(Slug, <<"non_resident_investment_deposit_pct_high">>))}}.

%% the duty line: the state's scale at the price, less the first-home concession where one
%% applied (the before/saving figures stamp_duty/3 computed).
duty_detail(State, PriceP, #{<<"concession_applied">> := Saving,
                             <<"before_concession">> := Before})
  when is_number(Saving), Saving > 0 ->
    {<<"kb.stamp-duty.calc-by-state">>, <<"stamp_duty_concession">>,
     #{state => State, params => #{<<"state">> => State, <<"price">> => PriceP,
                                   <<"before">> => money(Before),
                                   <<"saving">> => money(Saving)}}};
duty_detail(State, PriceP, _Sd) ->
    {<<"kb.stamp-duty.calc-by-state">>, <<"stamp_duty">>,
     #{state => State, params => #{<<"state">> => State, <<"price">> => PriceP}}}.

%% a grant line's detail is its state's FHOG doc; a state the KB holds no grant doc for
%% gives none (the line shows without one).
grant_details(Events, State) ->
    Slug = case State of
               <<"NSW">> -> <<"kb.scheme.nsw.fhog">>;
               <<"VIC">> -> <<"kb.scheme.vic.fhog">>;
               _         -> none
           end,
    maps:from_list([{Id, {Slug, <<"grant">>, #{state => State, params => #{}}}}
                    || Slug =/= none,
                       #{<<"id">> := <<"grant_", _/binary>> = Id} <- Events]).

%% --- the visitor's own deposit (behavior 101) ----------------------------------
%% Goal: built from their own situation -> the deposit is the buyer's choice -> cash_position
%%   -> the deposit event every loan figure follows
%% Purpose:   "Tài chính của bạn" lets a buyer put down more than the plan assumes, up to the
%%            whole price ("Mua đứt"). The onboarding fact `deposit_amount` (set by the
%%            `deposit` override, fh_engine_simulate) replaces the mode's assumed deposit at
%%            the price basis (the range ceiling, or the attached property's price).
%% Holds:     floor = the mode's KB minimum % of that price (A/E kb.scheme.fhg 5; B
%%            kb.lender.foreign-buyer-deposit-requirements typical 30; C kb.investor
%%            deposit_min_with_lmi_pct 10; D kb.non-resident low 30); max = the price. The
%%            handlers refuse a deposit outside them (deposit_out_of_bounds); a stored one
%%            the price later moved past is clamped here, never an error. The loan is the
%%            price less the deposit, so disposition's principal (read from this deposit
%%            event) and every loan-tied line follow it; a loan of 0 drops the mortgage
%%            registration and the loan fee lines (fh_engine_fees `applies.loan`).
%%            `deposit_bounds` carries {min, max, min_pct, assumed, chosen, price} to the sheet.
%% Measured:  2026-10-16, reading fh_engine_disposition principal/2 and the P&I formulas: a
%%            loan of 0 yields 0 repayments and interest, no division by the principal.

%% Mode A/E: the deposit map budget_envelope places, the loan at the ceiling, LMI (outside
%% the FHG's path, kb.lmi.calculation), the bounds, the line's detail.
home_deposit(Args, RecPath, [Lo, Hi] = Range, Ceiling) when is_integer(Lo), is_integer(Hi) ->
    Pct = deposit_pct(),
    Assumed = pct_of(Pct, Ceiling),
    case chosen_deposit(Args, Pct, Ceiling) of
        undefined ->
            Loan = Ceiling - Assumed,
            #{map => deposit(RecPath, Range), loan => Loan, lmi => home_lmi(RecPath, Loan, Ceiling),
              bounds => bounds(Pct, Ceiling, Assumed, null),
              detail => home_deposit_detail(RecPath)};
        D ->
            Loan = Ceiling - D,
            #{map => #{<<"minimum_required_percentage">> => Pct,
                       <<"minimum_required_amount">>     => [D, D],
                       <<"notes">> => [copy(<<"deposit_chosen">>,
                                            #{<<"amount">> => money(D)})]},
              loan => Loan, lmi => home_lmi(RecPath, Loan, Ceiling),
              bounds => bounds(Pct, Ceiling, Assumed, D),
              detail => chosen_detail(<<"kb.scheme.fhg">>, D, Ceiling, Pct)}
    end;
home_deposit(_Args, RecPath, Range, _Ceiling) ->
    #{map => deposit(RecPath, Range), loan => null, lmi => none, bounds => null,
      detail => home_deposit_detail(RecPath)}.

%% the FHG backs a deposit from 5% with no LMI; any other path pays it above 80% LVR.
home_lmi(<<"fhg_backed">>, _Loan, _Price) -> none;
home_lmi(_RecPath, Loan, Price) -> fh_engine_lmi:premium(Loan, Price).

%% Modes B/C/D: {Deposit, Bounds, Detail} — the chosen deposit or the mode's own (Assumed).
own_deposit(_Args, Assumed, _Pct, Price, Detail) when not is_integer(Price) ->
    {Assumed, null, Detail};
own_deposit(Args, Assumed, Pct, Price, {Slug, _Id, _P} = Detail) ->
    case chosen_deposit(Args, Pct, Price) of
        undefined -> {Assumed, bounds(Pct, Price, Assumed, null), Detail};
        D         -> {D, bounds(Pct, Price, Assumed, D), chosen_detail(Slug, D, Price, Pct)}
    end.

%% the visitor's deposit at this price, clamped into [floor, price]; undefined when unset.
chosen_deposit(Args, Pct, Price) ->
    case maps:get(<<"deposit_amount">>, maps:get(onboarding, Args, #{}), undefined) of
        D when is_number(D), is_integer(Price), Price > 0 ->
            erlang:min(Price, erlang:max(pct_of(Pct, Price), round(D)));
        _ -> undefined
    end.

bounds(Pct, Price, Assumed, Chosen) ->
    #{<<"min">> => pct_of(Pct, Price), <<"max">> => Price, <<"min_pct">> => Pct,
      <<"assumed">> => Assumed, <<"chosen">> => Chosen, <<"price">> => Price}.

%% the deposit line's detail when the buyer chose it: the doc whose minimum floors it.
chosen_detail(Slug, D, Price, MinPct) ->
    {Slug, <<"deposit_chosen">>,
     #{<<"amount">> => money(D),
       <<"pct">> => fh_engine_line_detail:pct(round(D * 1000 / Price) / 10),
       <<"min_pct">> => fh_engine_line_detail:pct(MinPct)}}.

%% the LMI line: an event where a premium applies (none → no line).
lmi_events(none, _Counterparty) -> [];
lmi_events([_, _] = R, Counterparty) ->
    [event(<<"lmi">>, <<"settle">>, <<"event_lmi">>, <<"out">>, R, true, Counterparty,
           <<"cash_position">>)].

lmi_amount(none) -> [0, 0];
lmi_amount(R)    -> R.

lmi_point(none)     -> 0;
lmi_point([Lo, Hi]) -> round((Lo + Hi) / 2).

%% the LMI line's detail: the band at this LVR (kb.lmi.calculation), or the investor
%% doc's "no LMI at 20%" when there is none.
lmi_detail(none, _Loan, _Price) -> lmi_none_detail();
lmi_detail([_, _], Loan, Price) ->
    Lvr = fh_engine_lmi:lvr(Loan, Price),
    {RLo, RHi} = fh_engine_lmi:rates(Lvr),
    {<<"kb.lmi.calculation">>, <<"lmi">>,
     #{<<"lvr">> => Lvr, <<"loan">> => money(Loan),
       <<"lo">> => fh_engine_line_detail:pct(RLo), <<"hi">> => fh_engine_line_detail:pct(RHi)}}.

lmi_none_detail() ->
    {<<"kb.investor.deposit-requirements-investment-loans">>, <<"lmi_none">>,
     #{<<"pct">> => param_value(<<"kb.investor.deposit-requirements-investment-loans">>,
                                <<"deposit_no_lmi_pct">>)}}.

plus_range(null, _) -> null;
plus_range(R, none) -> R;
plus_range([A, B], [C, D]) -> [A + C, B + D].

plus_point(null, _) -> null;
plus_point(V, L) -> V + L.

%% registration with the loan: no loan (bought outright) registers no mortgage.
registration(State, V, 0) ->
    case {registration_total(State, V), reg_entry(State)} of
        {null, _} -> null;
        {Reg, E}  -> dollars(Reg - maps:get(<<"mortgage_registration_flat">>, E))
    end;
registration(State, V, _Loan) -> registration_total(State, V).

minus(A, B) when is_number(A), is_number(B) -> A - B;
minus(_, _) -> null.

mid([Lo, Hi]) -> round((Lo + Hi) / 2).


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
