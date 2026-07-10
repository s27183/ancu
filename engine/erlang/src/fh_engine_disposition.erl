-module(fh_engine_disposition).

%% The base-turn `disposition` fill — the TERMINAL financial component (lifecycle-
%% simulation-model §8.6, the full temporal flow). It projects the dispose phase: the
%% sale proceeds (growth-projected over the hold horizon H), the selling costs, the loan
%% payout, the CGT, the net proceeds, and the full-horizon net position (buy → hold → sell).
%%
%% It is a RESOLVER fill (agentic-boundary.md): growth and CGT are the one genuinely
%% uncertain input the temporal flow introduces (§8.4), and they are removed from the LLM's
%% reach — banded, KB-grounded, resolver-computed. Reliability is structural, not a judge
%% ([[no-judge-ground-the-producer]], [[verify-regulated-figures-by-postcondition]]). NO agent
%% leaf.
%%
%% ONE-COMPUTER-PER-FIGURE ([[place-upstream-figures-dont-recompute]]). disposition OWNS the
%% dispose-phase figures (sale_proceeds, selling_costs, loan_payout, cgt, net_proceeds, the
%% dispose_cash_events) and the full-horizon roll-up. The roll-up PLACES the acquire figure
%% (budget_envelope.total_cash_required) and the hold figure (ongoing_obligations statutory
%% band annualised × H) — it never recomputes them. There is no second computer for the placed
%% figures; their conformance burden stays on cash_position / ownership_planning.
%%
%% HONEST-PARTIAL ([[base-turn-honest-partial-output]]). Mode-A default is long/indefinite hold
%% → H is null → no disposal projection until the user asks "what if I sell in N years?" (the
%% horizon structural what-if, engine-contract §10.5). With H unset, every projected figure is
%% null and the only key_assumption is the invitation to set a horizon. With H set but the loan
%% not yet known (expected_borrowing_capacity null at base, populated on a refine turn — the
%% reserve_buffer precedent), loan_payout / net_proceeds / full_horizon_net_position stay null;
%% sale_proceeds + selling_costs surface as banded estimates. No figure is ever fabricated.
%%
%% TWO CGT PATHS, ONE OUTCOME. fill/2 dispatches on the presence of a `tax_optimised_structure`
%% upstream (only the investor blueprint runs a tax_structure component) — same outcome type +
%% calculator renderer, two mode-appropriate computations:
%%
%%   MODE-A/B owner-occupier (fill_owner_occupier/2). The dwelling is the buyer's main residence
%%   → CGT-exempt (cgt = null, cgt_status = exempt) for the clean resident-for-tax case; to_verify
%%   once a trap applies (part rental / non-resident / land > 2 ha — kb.tax.cgt-main-residence-
%%   exemption). Mode A NEVER estimates a taxable gain.
%%
%%   MODE-C/D investor (fill_investor/3, cgt_investor/4). The property is NOT a main residence →
%%   the disposal is a taxable CGT event (kb.tax.cgt-50-percent-discount). cgt is a COMPUTED
%%   money_range (discounted gain × marginal rate) only for the clean case — resident individual,
%%   marginal rate known, no Div-43 cost-base clawback in play; to_verify (cgt = null → net
%%   PENDING) once a trap applies: a non-resident period, a trust/company/SMSF entity nuance, an
%%   unknown marginal rate, OR a depreciation clawback whose dollar the KB defers to a tax agent
%%   (kb.tax.depreciation-division-43-and-40 FLAGS the clawback, never asserts a dollar). The
%%   2026-27 Budget NG/CGT reform is surfaced as a flagged assumption (current law computed;
%%   post-1-July-2027 → to_verify). taxable_gain (the investor-only outcome field) carries the
%%   indicative discounted gain even on the to_verify path — what's computable is shown.

-export([fill/2]).
%% exported for the conformance harness:
-export([sale_proceeds/4, selling_costs/1, loan_payout/2, cgt/1,
         net_proceeds/4, full_horizon/4, dispose_cash_events/5]).
%% the Mode-C/D investor path (full CGT):
-export([cgt_investor/4, taxable_gain/3, loan_payout_investor/2, full_horizon_investor/4]).

-define(COPY,    <<"kb.copy.disposition">>).
-define(GROWTH,  <<"kb.property.capital-growth-bands">>).
-define(SELLING, <<"kb.selling-costs.agent-legal">>).
-define(CGT,     <<"kb.tax.cgt-main-residence-exemption">>).
-define(SERVICEABILITY, <<"kb.lender.serviceability-basics">>).
%% Mode-C/D investor anchors (the full-CGT path): the 50% discount + by-entity rates, the
%% depreciation cost-base clawback, and the investment-loan rate premium.
-define(CGT_INV,  <<"kb.tax.cgt-50-percent-discount">>).
-define(DEPR,     <<"kb.tax.depreciation-division-43-and-40">>).
-define(SERV_INV, <<"kb.lender.serviceability-investment-loans">>).
%% Mode-D foreign-resident-investor anchors (the FRCGW withholding + VN-side note):
-define(FRCGW,    <<"kb.non-resident-tax.foreign-resident-cgt-withholding">>).

-define(LOAN_TERM_YEARS, 30).   %% standard P&I term; the amortisation default (mortgage_plan
                                %% carries no term at base — a documented constant, not a magic figure).

%% --- entry -------------------------------------------------------------------

-spec fill(map(), map()) -> {map(), binary(), [map()]}.
fill(_Args, Upstream) ->
    Profile = maps:get(<<"profile">>, Upstream, #{}),
    %% Mode discriminator: only the investor blueprint runs a `tax_structure` component, so its
    %% outcome's presence upstream marks the Mode-C/D investor path (full CGT) vs the Mode-A/B
    %% owner-occupier path (main-residence-exempt). Same outcome type + calculator renderer.
    case maps:get(<<"tax_optimised_structure">>, Upstream, undefined) of
        undefined -> fill_owner_occupier(Profile, Upstream);
        Tax       -> fill_investor(Profile, Tax, Upstream)
    end.

%% --- Mode-A/B owner-occupier (main-residence-exempt) -------------------------

fill_owner_occupier(Profile, Upstream) ->
    Budget    = maps:get(<<"budget_envelope">>, Upstream, #{}),
    Mortgage  = maps:get(<<"mortgage_plan">>, Upstream, #{}),
    Ownership = maps:get(<<"ongoing_obligations">>, Upstream, #{}),

    H        = horizon(Profile),
    Price    = price_basis(Profile),
    {GLow, GHigh, _IsPlaceholder} = growth_band(),

    Sale          = sale_proceeds(Price, H, GLow, GHigh),
    Selling       = selling_costs(Sale),
    Loan          = loan_payout(Mortgage, H),
    {Cgt, Status} = cgt(Profile),
    CgtContrib    = cgt_contribution(Cgt, Status),
    Net           = net_proceeds(Sale, Selling, Loan, CgtContrib),
    Full          = full_horizon(Net, Budget, Ownership, H),
    %% Mode-A/B/E four-actor swimlane (fh_engine_journey:actors/0) — the money-flow party for
    %% sale/selling is "other" there.
    Events        = dispose_cash_events(Sale, Selling, Loan, Cgt, <<"other">>),

    Outcome = #{
        <<"horizon_years">>             => H,
        <<"sale_proceeds">>             => Sale,
        <<"selling_costs">>             => Selling,
        <<"loan_payout">>               => Loan,
        <<"cgt">>                       => Cgt,
        <<"cgt_status">>                => Status,
        <<"net_proceeds">>              => Net,
        <<"full_horizon_net_position">> => Full,
        <<"dispose_cash_events">>       => Events,
        <<"key_assumptions">>           => assumptions(H, GLow, GHigh, Status, Loan)
    },
    KbVersions = fh_engine_kb:kb_anchors([?GROWTH, ?SELLING, ?CGT, ?SERVICEABILITY, ?COPY]),
    {Outcome, <<"calculator">>, KbVersions}.

%% --- Mode-C/D investor (full CGT) --------------------------------------------
%% Reuses the mode-general sale_proceeds/selling_costs/net_proceeds; differs in the upstream
%% sources (budget_envelope_investor + cash_flow_projection over the main-residence variants),
%% the investment-loan amortisation rate, the full-CGT computation, and a signed hold cash flow
%% rolled into the full-horizon position.

fill_investor(Profile, Tax, Upstream) ->
    Budget   = maps:get(<<"budget_envelope_investor">>, Upstream, #{}),
    CashFlow = maps:get(<<"cash_flow_projection">>, Upstream, #{}),

    H        = horizon(Profile),
    %% per-property (Phase B, Slice B3c): the ATTACHED property's exact price drives every dispose
    %% figure (sale_proceeds, taxable_gain, the net); at base: the target-range ceiling. So the
    %% dispose projection reflects THIS property, not the plan-wide range. [[place-upstream-figures-dont-recompute]]
    Price    = property_price(maps:get(<<"property_fit_investor">>, Upstream, #{}), Profile),
    {GLow, GHigh, _IsPlaceholder} = growth_band(),

    Sale                = sale_proceeds(Price, H, GLow, GHigh),
    Selling             = selling_costs(Sale),
    Loan                = loan_payout_investor(Budget, H),
    {Gain, Cgt, Status} = cgt_investor(Profile, Tax, Sale, Price),
    %% cgt IS the contribution: a money_range when computed, null (→ net PENDING) when to_verify.
    Net                 = net_proceeds(Sale, Selling, Loan, Cgt),
    Full                = full_horizon_investor(Net, Budget, CashFlow, H),
    %% Mode-C/D six-actor swimlane (fh_engine_journey:investor_actors/0) RENAMES "other" to
    %% "services" — a money cell counterparty of "other" is an actor id that doesn't exist in
    %% that set, so SwimlaneDiagram.svelte's by-declared-actor-id lookup silently drops the
    %% sale_proceeds/selling_costs cells the moment a hold horizon is set (found via review,
    %% 2026-07-10 — [[firsthomey-bcd-lifecycle-restructure]] task 10). Fixed at the source: the
    %% investor path (the ONLY caller of the six-actor set) passes "services" here.
    Events              = dispose_cash_events(Sale, Selling, Loan, Cgt, <<"services">>),
    %% Mode-D-only fields (frcgw_applicable is absent/false on Mode C's tax_optimised_structure
    %% ⟹ both null there — one function serves both modes, see frcgw_withheld/2's header note).
    FrcgwApplicable     = maps:get(<<"frcgw_applicable">>, Tax, false),
    Frcgw               = frcgw_withheld(Sale, FrcgwApplicable),
    VnNote              = vn_side_cgt_note(FrcgwApplicable),

    Outcome = #{
        <<"horizon_years">>             => H,
        <<"sale_proceeds">>             => Sale,
        <<"selling_costs">>             => Selling,
        <<"loan_payout">>               => Loan,
        <<"taxable_gain">>              => Gain,
        <<"cgt">>                       => Cgt,
        <<"cgt_status">>                => Status,
        %% Mode-D-only outcome fields — null (absent-equivalent) for Mode C, per the shared
        %% `disposition` type's field-superset precedent (investor-foreign-au.md
        %% "outcome-type conformance" note).
        <<"frcgw_withheld_at_settlement">> => Frcgw,
        <<"vn_side_cgt_note">>             => VnNote,
        <<"net_proceeds">>              => Net,
        <<"full_horizon_net_position">> => Full,
        <<"dispose_cash_events">>       => Events,
        <<"key_assumptions">>           => assumptions_investor(H, GLow, GHigh, Status, Loan, Frcgw)
    },
    FrcgwAnchors = case FrcgwApplicable of
                       true -> [?FRCGW];
                       _    -> []
                   end,
    KbVersions = fh_engine_kb:kb_anchors(
        [?GROWTH, ?SELLING, ?CGT_INV, ?DEPR, ?SERV_INV, ?COPY] ++ FrcgwAnchors),
    {Outcome, <<"calculator">>, KbVersions}.

%% --- inputs ------------------------------------------------------------------

%% H: the hold horizon (years). null = no disposal projection (Mode-A long/indefinite
%% default); the horizon structural what-if sets it (engine-contract §10.5).
horizon(Profile) ->
    case maps:get(<<"hold_horizon_years">>, Profile, null) of
        H when is_integer(H), H > 0 -> H;
        _                           -> null
    end.

%% the purchase-price basis: per-property (Phase B) the ATTACHED property's exact price (from
%% property_fit_investor — drives sale_proceeds, taxable_gain, loan, the net); at base the
%% target_price_range ceiling. The dispose figures thus reflect THIS property once attached.
property_price(Pf, Profile) ->
    case maps:get(<<"price">>, Pf, null) of
        P when is_number(P) -> P;
        _                   -> price_basis(Profile)
    end.

%% the base purchase-price basis: the target_price_range CEILING (the conservative upper bound
%% the every-financial-figure narrowing uses). null when no target is set.
price_basis(Profile) ->
    case maps:get(<<"target_price_range">>, Profile, null) of
        [_Lo, Hi] when is_number(Hi) -> Hi;
        _                            -> null
    end.

%% --- growth band (kb.property.capital-growth-bands — PLACEHOLDER) -------------

growth_band() ->
    {param(?GROWTH, <<"growth_band_low_pct_pa_nominal">>),
     param(?GROWTH, <<"growth_band_high_pct_pa_nominal">>),
     param(?GROWTH, <<"is_placeholder">>)}.

%% --- sale proceeds: purchase_price × (1 + rate)^H at both band ends ----------
%% PENDING (null) when H or price is unparameterised (honest-partial — never a point).

-spec sale_proceeds(number() | null, integer() | null, number(), number()) ->
          [integer()] | null.
sale_proceeds(null, _H, _GLow, _GHigh) -> null;
sale_proceeds(_Price, null, _GLow, _GHigh) -> null;
sale_proceeds(Price, H, GLow, GHigh) when is_number(Price), is_integer(H) ->
    [round(Price * math:pow(1 + GLow / 100, H)),
     round(Price * math:pow(1 + GHigh / 100, H))].

%% --- selling costs: commission% × sale_proceeds + legal + marketing ----------
%% Itself a money_range because the proceeds are banded (kb.selling-costs.agent-legal).

-spec selling_costs([integer()] | null) -> [integer()] | null.
selling_costs(null) -> null;
selling_costs([SaleLo, SaleHi]) ->
    CLow    = param(?SELLING, <<"agent_commission_low_pct">>),
    CHigh   = param(?SELLING, <<"agent_commission_high_pct">>),
    LegalLo = param(?SELLING, <<"legal_conveyancing_low_aud">>),
    LegalHi = param(?SELLING, <<"legal_conveyancing_high_aud">>),
    MktLo   = param(?SELLING, <<"marketing_low_aud">>),
    MktHi   = param(?SELLING, <<"marketing_high_aud">>),
    [round(CLow / 100 * SaleLo) + LegalLo + MktLo,
     round(CHigh / 100 * SaleHi) + LegalHi + MktHi].

%% --- loan payout: remaining principal at year H (amortisation) ---------------
%% null until the loan AMOUNT is known (expected_borrowing_capacity is null at base,
%% populated when income arrives via /profile — IC4; the reserve_buffer honest-partial
%% precedent). The amortisation RATE is NOT the agent's `loan_structure_recommendation.rate`
%% — that field holds the agent's rate-STRUCTURE enum (variable/fixed_1yr/…), a qualitative
%% leaf, never a numeric rate. §98 ([[verify-regulated-figures-by-postcondition]]): the
%% amortisation rate is a regulated figure → it is the KB representative product rate
%% (kb.lender.serviceability-basics), the SAME base the capacity assessment uses, so the
%% loan you can service and the balance you carry stay coherent. So loan_payout depends only
%% on the (resolver-computed) capacity + H + the KB rate — no LLM in its lineage; the whole
%% full-horizon position is a fully resolver-computed, KB-grounded figure.

-spec loan_payout(map(), integer() | null) -> [integer()] | null.
loan_payout(_Mortgage, null) -> null;
loan_payout(Mortgage, H) when is_integer(H) ->
    Capacity = maps:get(<<"expected_borrowing_capacity">>, Mortgage, null),
    case principal_band(Capacity) of
        null       -> null;
        [PLo, PHi] ->
            R = representative_rate(),
            [round(remaining_balance(PLo, R, ?LOAN_TERM_YEARS, H)),
             round(remaining_balance(PHi, R, ?LOAN_TERM_YEARS, H))]
    end.

%% the borrowing capacity → a [lo, hi] principal band; a scalar collapses to a point.
principal_band([Lo, Hi]) when is_number(Lo), is_number(Hi) -> [Lo, Hi];
principal_band(P) when is_number(P) -> [P, P];
principal_band(_) -> null.

%% the representative owner-occupier product rate (kb.lender.serviceability-basics) — the
%% capacity-assessment BASE WITHOUT the APRA stress buffer (the buffer is a serviceability
%% stress overlay, not the rate at which the loan actually amortises). A labelled CONVENTION
%% (surfaced in key_assumptions), never this buyer's actual product rate.
representative_rate() ->
    param(?SERVICEABILITY, <<"representative_product_rate_pct">>).

%% standard P&I remaining-balance at K years of an N-year loan at monthly rate r:
%% B_K = P · ((1+r)^N − (1+r)^K) / ((1+r)^N − 1); r = 0 → straight-line; K ≥ N → 0.
remaining_balance(P, AnnualRatePct, TermYears, ElapsedYears) when ElapsedYears >= TermYears ->
    _ = {P, AnnualRatePct}, 0.0;
remaining_balance(P, 0, TermYears, ElapsedYears) ->
    P * (TermYears - ElapsedYears) / TermYears;
remaining_balance(P, AnnualRatePct, TermYears, ElapsedYears) ->
    R = AnnualRatePct / 100 / 12,
    N = TermYears * 12,
    K = ElapsedYears * 12,
    P * (math:pow(1 + R, N) - math:pow(1 + R, K)) / (math:pow(1 + R, N) - 1).

%% --- investor loan payout: investment-loan amount amortised at the investment rate -----
%% reads budget_envelope_investor.loan_amount (the actual loan for THIS purchase, not a capacity)
%% and amortises at the KB representative owner-occupier rate PLUS the investment premium — both
%% KB-grounded, removed from the LLM's reach (§98). null until the loan amount is known.
-spec loan_payout_investor(map(), integer() | null) -> [integer()] | null.
loan_payout_investor(_Budget, null) -> null;
loan_payout_investor(Budget, H) when is_integer(H) ->
    case principal_band(maps:get(<<"loan_amount">>, Budget, null)) of
        null       -> null;
        [PLo, PHi] ->
            R = investor_rate(),
            [round(remaining_balance(PLo, R, ?LOAN_TERM_YEARS, H)),
             round(remaining_balance(PHi, R, ?LOAN_TERM_YEARS, H))]
    end.

%% the investment-loan amortisation rate: the owner-occupier representative rate
%% (kb.lender.serviceability-basics) + the investment premium (kb.lender.serviceability-
%% investment-loans). A labelled KB convention surfaced in key_assumptions, never a product rate.
investor_rate() ->
    representative_rate() + param(?SERV_INV, <<"investment_rate_premium_pp">>).

%% --- CGT: Mode-A main-residence exemption ------------------------------------
%% exempt (cgt = null) for the clean owner-occupier resident-for-tax case; to_verify once
%% a trap applies. Mode A NEVER estimates a taxable gain (kb.tax.cgt-main-residence-exemption).

-spec cgt(map()) -> {null, binary()}.
cgt(Profile) ->
    Occupancy = maps:get(<<"intended_occupancy_use">>, Profile, null),
    Residency = maps:get(<<"tax_residency">>, Profile, null),
    case {Occupancy, Residency} of
        {<<"sole_occupier">>, <<"resident">>} -> {null, <<"exempt">>};
        _                                     -> {null, <<"to_verify">>}
    end.

%% the CGT contribution to net_proceeds: exempt → $0 (a deduction of nothing); to_verify →
%% unknown (the gain is undetermined for Mode A → net_proceeds stays PENDING rather than
%% asserting a $0 tax that may not hold).
cgt_contribution(null, <<"exempt">>)    -> [0, 0];
cgt_contribution(_,    <<"to_verify">>) -> null.

%% --- CGT: Mode-C/D investor (taxable gain, 50% discount, depreciation clawback) ---
%% COMPUTED (a discounted-gain money_range, cgt_status = computed) only for the clean case: a
%% resident individual, marginal rate known, and NO Div-43 cost-base clawback in play. to_verify
%% (cgt = null → net PENDING) once a trap applies — a non-resident period, a trust/company/SMSF
%% entity nuance, an unknown marginal rate, OR a depreciation clawback whose dollar the KB defers
%% to a tax agent (kb.tax.depreciation-division-43-and-40 FLAGS the clawback, never asserts a
%% dollar). The indicative discounted gain is surfaced as taxable_gain on BOTH paths (what's
%% computable is shown). cgt = taxable_gain × marginal rate.

-spec cgt_investor(map(), map(), [integer()] | null, number() | null) ->
          {[integer()] | null, [integer()] | null, binary()}.
cgt_investor(Profile, Tax, Sale, Price) ->
    Entity   = maps:get(<<"recommended_entity">>, Tax, null),
    Rate     = maps:get(<<"cgt_marginal_rate">>, Tax, null),
    Eligible = maps:get(<<"cgt_discount_eligible">>, Tax, null),
    Clawback = maps:get(<<"cost_base_depreciation_clawback">>, Tax, null),
    %% the discount only when the holding clears 12 months (kb.tax.cgt-50-percent-discount); else
    %% 0% — the full nominal gain is taxable (held < 12 months OR eligibility undetermined: the
    %% conservative, higher-gain direction).
    Discount = case Eligible of
                   true -> param(?CGT_INV, <<"discount_pct_individual">>);
                   _    -> 0
               end,
    Gain = taxable_gain(Sale, Price, Discount),
    %% the clean computed case — an individual resident with a known rate and no clawback in play.
    %% Holding period sets the discount %, not clean-ness (a sub-12-month individual sale is still
    %% computed, just undiscounted). Trust/company/SMSF, a non-resident period, an unknown rate,
    %% or a live clawback ⟹ to_verify (defer the figure to a registered tax agent).
    Clean = all_resident(Profile)
            andalso lists:member(Entity, [<<"personal_sole">>, <<"personal_joint">>])
            andalso is_number(Rate)
            andalso Clawback =:= false,
    case Clean of
        true when is_list(Gain) ->
            [GLo, GHi] = Gain,
            {Gain, [round(GLo * Rate / 100), round(GHi * Rate / 100)], <<"computed">>};
        _ ->
            {Gain, null, <<"to_verify">>}
    end.

%% the indicative discounted gain: (sale − cost base) × (1 − discount), floored at 0 (a capital
%% loss yields no CGT here). The cost base is the conservative purchase-price basis — omitting
%% incidental acquisition costs RAISES the gain (the safe direction; their inclusion is a
%% to_verify refinement). Banded (sale is banded); null when sale or price is unparameterised.
-spec taxable_gain([integer()] | null, number() | null, number()) -> [integer()] | null.
taxable_gain(null, _Price, _Discount) -> null;
taxable_gain(_Sale, null, _Discount) -> null;
taxable_gain([SaleLo, SaleHi], Price, Discount) when is_number(Price) ->
    F = (100 - Discount) / 100,
    [max(0, round((SaleLo - Price) * F)),
     max(0, round((SaleHi - Price) * F))].

%% all owners resident-for-tax? a non-resident period apportions the discount away
%% (kb.tax.cgt-50-percent-discount) ⟹ to_verify. Empty applicants ⟹ [#{}] (the resolver's
%% idempotent treatment); the default residency is the clean "resident".
all_resident(Profile) ->
    lists:all(
        fun(A) ->
            T = maps:get(<<"tax">>, A, #{}),
            maps:get(<<"residency_for_tax">>, T, <<"resident">>) =:= <<"resident">>
        end, applicants(Profile)).

applicants(Profile) ->
    case maps:get(<<"applicants">>, Profile, []) of
        []                -> [#{}];
        L when is_list(L) -> L
    end.

%% --- net proceeds: sale − selling − loan − cgt -------------------------------
%% interval arithmetic; null when any required input is null (honest-partial).

-spec net_proceeds([integer()] | null, [integer()] | null,
                   [integer()] | null, [integer()] | null) -> [integer()] | null.
net_proceeds([SLo, SHi], [CLo, CHi], [LLo, LHi], [TLo, THi]) ->
    [round(SLo - CHi - LHi - THi), round(SHi - CLo - LLo - TLo)];
net_proceeds(_, _, _, _) -> null.

%% --- full-horizon net position: net − acquire-cash − hold-cost×H -------------
%% PLACES the acquire figure (budget_envelope.total_cash_required) and the hold figure
%% (ongoing_obligations statutory band × H); never recomputes them. null when any is null.

-spec full_horizon([integer()] | null, map(), map(), integer() | null) -> [integer()] | null.
full_horizon(null, _Budget, _Ownership, _H) -> null;
full_horizon(_Net, _Budget, _Ownership, null) -> null;
full_horizon([NLo, NHi], Budget, Ownership, H) when is_integer(H) ->
    case {money_range(maps:get(<<"total_cash_required">>, Budget, null)),
          hold_band(Ownership)} of
        {null, _} -> null;
        {_, null} -> null;
        {[AcqLo, AcqHi], [HoldLo, HoldHi]} ->
            [round(NLo - AcqHi - HoldHi * H),
             round(NHi - AcqLo - HoldLo * H)]
    end.

%% the annual hold cost band placed from ownership_planning's statutory band {low, high}.
hold_band(Ownership) ->
    Rec  = maps:get(<<"recurring_costs_estimate">>, Ownership, #{}),
    Band = maps:get(<<"statutory_band">>, Rec, #{}),
    case Band of
        #{<<"low">> := Lo, <<"high">> := Hi} when is_number(Lo), is_number(Hi) -> [Lo, Hi];
        _ -> null
    end.

%% --- investor full-horizon: net − acquire + signed hold cash flow × H ---------
%% PLACES the acquire figure (budget_envelope_investor.total_cash_required) and the hold figure
%% (cash_flow_projection.cash_flow_before_tax_year_1, SIGNED — negative for a negatively-geared
%% hold — applied flat over H as a documented year-1 simplification); never recomputes them. The
%% sign is the Mode-A contrast: an owner-occupier's hold band is pure cost (subtracted), an
%% investor's hold cash flow can be income or cost (added with its sign). null when net, acquire,
%% or the hold cash flow is unknown (honest-partial).
-spec full_horizon_investor([integer()] | null, map(), map(), integer() | null) ->
          [integer()] | null.
full_horizon_investor(null, _Budget, _CashFlow, _H) -> null;
full_horizon_investor(_Net, _Budget, _CashFlow, null) -> null;
full_horizon_investor([NLo, NHi], Budget, CashFlow, H) when is_integer(H) ->
    Acq = money_range(maps:get(<<"total_cash_required">>, Budget, null)),
    %% the hold cash flow is now a BAND (cash_flow_before_tax_year_1, §B0 banded surface), SIGNED.
    %% money_range/1 coerces a scalar to [v,v] too, so this stays backward-compatible.
    CF  = money_range(maps:get(<<"cash_flow_before_tax_year_1">>, CashFlow, null)),
    case {Acq, CF} of
        {null, _} -> null;
        {_, null} -> null;
        {[AcqLo, AcqHi], [CFLo, CFHi]} ->
            HoldLo = round(CFLo * H),
            HoldHi = round(CFHi * H),
            [NLo - AcqHi + HoldLo, NHi - AcqLo + HoldHi]
    end.

%% --- dispose_cash_events (the Dispose-phase entries of the shared spine) ------
%% Mirrors the cash_event shape exactly so purchase_journey PLACES them on the swimlane's
%% Dispose column (TW3). phase = "dispose", timing = one_off. Honest-partial: an event is
%% emitted only when its amount is present (a null-amount figure is dropped, never faked).

%% Cgt is null on the Mode-A/owner-occupier path (exempt/to_verify) and on the investor
%% to_verify path; a money_range on the investor computed path (the cgt event is then emitted).
%%
%% MoneyPartyId: the counterparty for sale_proceeds/selling_costs — MUST be an actor id that
%% exists in the caller's rendered swimlane actor set, since SwimlaneDiagram.svelte looks up
%% cells strictly by declared actor id and silently drops an orphaned one. "other" for the
%% Mode-A/B/E four-actor set (fh_engine_journey:actors/0); "services" for the Mode-C/D
%% six-actor set (fh_engine_journey:investor_actors/0). loan_payout/cgt use "lender"/
%% "government", which both actor sets carry unchanged.
-spec dispose_cash_events([integer()] | null, [integer()] | null,
                          [integer()] | null, [integer()] | null, binary()) -> [map()].
dispose_cash_events(Sale, Selling, Loan, Cgt, MoneyPartyId) ->
    Candidates = [
        event(<<"sale_proceeds">>, <<"event_sale_proceeds">>, <<"in">>,  Sale,    MoneyPartyId),
        event(<<"selling_costs">>, <<"event_selling_costs">>, <<"out">>, Selling, MoneyPartyId),
        event(<<"loan_payout">>,   <<"event_loan_payout">>,   <<"out">>, Loan,    <<"lender">>),
        event(<<"cgt">>,           <<"event_cgt">>,           <<"out">>, Cgt,     <<"government">>)
    ],
    [E || E <- Candidates, maps:get(<<"amount">>, E) =/= null].

event(Id, LabelCopyId, Dir, Amount, Counterparty) ->
    #{<<"id">>               => <<"dispose_", Id/binary>>,
      <<"phase">>            => <<"dispose">>,
      <<"label">>            => copy(LabelCopyId, #{}),
      <<"direction">>        => Dir,
      <<"amount">>           => Amount,
      <<"is_estimate">>      => true,
      <<"timing">>           => <<"one_off">>,
      <<"period">>           => null,
      <<"counterparty">>     => Counterparty,
      <<"source_component">> => <<"disposition">>}.

%% --- key_assumptions (bilingual, every line states a basis) ------------------

assumptions(null, _GLow, _GHigh, _Status, _Loan) ->
    %% no horizon set → the only assumption is the invitation to set one.
    [copy(<<"assumption_set_horizon">>, #{})];
assumptions(H, GLow, GHigh, Status, Loan) ->
    Base = [copy(<<"assumption_horizon">>, #{<<"years">> => H}),
            copy(<<"assumption_growth_placeholder">>, #{<<"low">> => GLow, <<"high">> => GHigh}),
            cgt_assumption(Status),
            copy(<<"assumption_selling_costs">>, #{})],
    %% the loan-rate basis is stated ONLY when a loan payout is actually shown (capacity
    %% known) — otherwise it would assert a basis for a figure that is PENDING.
    case Loan of
        null -> Base;
        _    -> Base ++ [copy(<<"assumption_loan_rate">>,
                              #{<<"rate">> => representative_rate(),
                                <<"term">> => ?LOAN_TERM_YEARS})]
    end.

cgt_assumption(<<"exempt">>)    -> copy(<<"assumption_cgt_exempt">>, #{});
cgt_assumption(<<"to_verify">>) -> copy(<<"assumption_cgt_to_verify">>, #{}).

%% --- investor key_assumptions (bilingual; the §8.4 ASIC discipline) ----------
%% reuses horizon / growth-placeholder / selling-cost / loan-rate lines (the loan-rate line
%% carries the investor rate via {rate} substitution); swaps in the investor CGT basis and adds
%% the 2026-27 Budget reform flag (current law computed; the reform may change it from 1 Jul 2027).
%% The FRCGW line (Mode D only) is appended LAST, only when the withheld figure is actually
%% shown — never asserting a basis for a null figure (mirrors the loan-rate line's own gate).
assumptions_investor(null, _GLow, _GHigh, _Status, _Loan, _Frcgw) ->
    [copy(<<"assumption_set_horizon">>, #{})];
assumptions_investor(H, GLow, GHigh, Status, Loan, Frcgw) ->
    Base = [copy(<<"assumption_horizon">>, #{<<"years">> => H}),
            copy(<<"assumption_growth_placeholder">>, #{<<"low">> => GLow, <<"high">> => GHigh}),
            cgt_assumption_investor(Status),
            copy(<<"assumption_cgt_reform">>, #{}),
            copy(<<"assumption_selling_costs">>, #{})],
    WithLoan = case Loan of
        null -> Base;
        _    -> Base ++ [copy(<<"assumption_loan_rate">>,
                              #{<<"rate">> => investor_rate(),
                                <<"term">> => ?LOAN_TERM_YEARS})]
    end,
    case Frcgw of
        null -> WithLoan;
        _    -> WithLoan ++ [copy(<<"assumption_frcgw">>, #{})]
    end.

cgt_assumption_investor(<<"computed">>)  -> copy(<<"assumption_cgt_computed">>, #{});
cgt_assumption_investor(<<"to_verify">>) -> copy(<<"assumption_cgt_investor_to_verify">>, #{}).

%% --- Mode-D: FRCGW withheld at settlement + the VN-side CGT note -------------
%% 15% of the PROJECTED sale-proceeds band (kb.non-resident-tax.foreign-resident-cgt-
%% withholding's frcgw_rate_percent — the rate/threshold-removal are REGULATED constants;
%% the doc's own "figures deferred to a registered tax agent" caveat is about the ACTUAL
%% settlement-day amount, which does not exist yet — this is the SAME indicative-projection
%% class as taxable_gain/sale_proceeds themselves: banded, assumption-flagged, resolver-
%% computed, never asserted as the real figure [[verify-regulated-figures-by-postcondition]]).
%% A mechanical function of the sale price alone (never the uncertain gain), so it is shown
%% even while cgt itself stays to_verify — "what's computable is shown", same discipline as
%% taxable_gain. null when FRCGW doesn't apply (Mode C) or sale_proceeds is unparameterised.
-spec frcgw_withheld([integer()] | null, boolean()) -> [integer()] | null.
frcgw_withheld(_Sale, false) -> null;
frcgw_withheld(null, true)   -> null;
frcgw_withheld([SLo, SHi], true) ->
    Pct = param(?FRCGW, <<"frcgw_rate_percent">>),
    [round(Pct / 100 * SLo), round(Pct / 100 * SHi)].

%% VN-side informational note (kb.au-vn-tax-treaty) — never a VN tax figure, points to the
%% buyer's own VN-based tax advisor (AU-side-full/VN-side-placeholder scoping decision). null
%% for Mode C (not a foreign-resident disposal at all).
-spec vn_side_cgt_note(boolean()) -> fh_engine_i18n:localized() | null.
vn_side_cgt_note(false) -> null;
vn_side_cgt_note(true)  -> copy(<<"vn_side_cgt_note">>, #{}).

%% --- helpers -----------------------------------------------------------------

%% a KB `parameters[Key].value` scalar (percentage / money / bool) — the fh_engine_cash
%% read pattern.
param(Slug, Key) ->
    {ok, Cj} = fh_engine_kb:kb_rules(Slug),
    Params = maps:get(<<"parameters">>, Cj),
    maps:get(<<"value">>, maps:get(Key, Params)).

%% normalise a money figure to a [lo, hi] range (a scalar collapses to a point); else null.
money_range([Lo, Hi]) when is_number(Lo), is_number(Hi) -> [Lo, Hi];
money_range(V) when is_number(V) -> [V, V];
money_range(_) -> null.

%% a bilingual {vi,en} copy line with {param} substitution (no Vietnamese in Erlang).
-spec copy(binary(), map()) -> fh_engine_i18n:localized().
copy(Id, Params) ->
    fh_engine_i18n:subst(fh_engine_kb:copy(?COPY, Id), Params).
