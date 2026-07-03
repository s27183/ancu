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
-export([surcharge_pct/1, surcharge_amount/2, sum_or_null/1, channel_costs/2]).
%% exported for the Mode-D foreign-investor conformance suite:
-export([fill_investor_foreign/2]).

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
-spec fill(map(), map()) -> {map(), binary(), [map()]}.
fill(Args, Upstream) ->
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
    Outcome = budget_envelope(Sd, State, RecPath, Range, Ceiling, Stack),
    KbVersions = fh_engine_kb:kb_anchors(
        [<<"kb.stamp-duty.calc-by-state">>,
         <<"kb.buyer-costs.inspections-conveyancing-fees">>,
         <<"kb.cash-reserve.lender-expectations">>, <<"kb.scheme.fhg">>]
        ++ concession_anchor(State, HasConc)),
    {Outcome, <<"calculator">>, KbVersions}.

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
    ChannelCosts = channel_costs(State, Ceiling),
    Deposit = maps:get(<<"deposit_required">>, Mortgage, null),
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
        <<"key_assumptions">>              => key_assumptions_foreign(Ceiling, State)
    },
    KbVersions = fh_engine_kb:kb_anchors(
        [<<"kb.stamp-duty.calc-by-state">>, <<"kb.foreign-buyer-surcharge.by-state">>,
         <<"kb.firb.fee-schedule-current">>, <<"kb.fx.typical-spreads-vnd-aud">>,
         <<"kb.buyer-costs.inspections-conveyancing-fees">>,
         <<"kb.cash-reserve.lender-expectations">>,
         <<"kb.lmi.calculation-for-foreign-persons">>]),
    {Outcome, <<"calculator">>, KbVersions}.

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

%% registration (exact, per state) + the shared due-diligence/legal convention band
%% (building/pest inspection, conveyancing, lender application fee — the SAME three
%% lines the investor variant sums, convention_band_investor/0). The FX transfer cost
%% is a real add-on but its amount is unknowable until the transfer sum is known (a
%% cross_border_funding fact) — deliberately EXCLUDED here and disclosed via
%% key_assumptions (assume_fx_not_included) rather than silently understated-without-
%% comment or blocking the whole total on one unknown line.
-spec channel_costs(binary() | undefined, integer() | null) -> integer() | null.
channel_costs(State, V) when is_integer(V) ->
    case registration_total(State, V) of
        null -> null;
        Reg  ->
            {Lo, Hi} = convention_band_investor(),
            Reg + round((Lo + Hi) / 2)
    end;
channel_costs(_State, _V) -> null.

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
%% disclosures (no first-home concession, FX not yet included, the no-LMI base
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
     copy(<<"assume_fx_not_included">>, #{}),
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
    ChannelCosts = channel_costs(State, Ceiling),
    Deposit = maps:get(<<"deposit_required_amount">>, Mortgage, null),
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
        <<"verdict">>                      => Verdict
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
