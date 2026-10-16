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
%% not known (no price range or no deposit event upstream), loan_payout / net_proceeds /
%% full_horizon_net_position stay null; sale_proceeds + selling_costs surface as banded
%% estimates. No figure is ever fabricated. The loan is the price less the plan's deposit in
%% every mode (behavior 98, see loan_payout/3), so at base it is known whenever a range is.
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
-export([sale_proceeds/4, selling_costs/1, loan_payout/3, cgt/1,
         net_proceeds/4, full_horizon/4, dispose_cash_events/5]).
%% the Mode-C/D investor path (full CGT):
-export([cgt_investor/4, taxable_gain/3, full_horizon_investor/4]).
%% the one loan every phase uses (behavior 98): price less deposit, its kind's rate, and
%% its repayments split into interest and principal over the hold:
-export([principal/2, loan_kind/2, rate_band/1, loan_over_hold/3]).
%% the growth assumption line (copy key chosen by the band's is_placeholder flag):
-export([growth_assumption/3]).
%% the Own-phase loan-repayment band fh_engine_ownership places (behavior 82):
-export([annual_repayments/2]).
%% the rate and term that band is amortised at, for its line's detail (behavior 93):
-export([repayment_basis/1, loan_detail_slug/1]).

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
fill(Args, Upstream) ->
    Profile = maps:get(<<"profile">>, Upstream, #{}),
    %% Mode discriminator: only the investor blueprint runs a `tax_structure` component, so its
    %% outcome's presence upstream marks the Mode-C/D investor path (full CGT) vs the Mode-A/B
    %% owner-occupier path (main-residence-exempt). Same outcome type + calculator renderer.
    case maps:get(<<"tax_optimised_structure">>, Upstream, undefined) of
        undefined -> fill_owner_occupier(Args, Profile, Upstream);
        Tax       -> fill_investor(Args, Profile, Tax, Upstream)
    end.

%% --- Mode-A/B owner-occupier (main-residence-exempt) -------------------------

fill_owner_occupier(Args, Profile, Upstream) ->
    Budget    = maps:get(<<"budget_envelope">>, Upstream, #{}),
    Ownership = maps:get(<<"ongoing_obligations">>, Upstream, #{}),

    H        = horizon(Profile),
    Price    = price_basis(Profile),
    {GLow, GHigh, IsPlaceholder} = growth_band(),

    Kind          = loan_kind(Args, owner),
    Principal     = principal(price_range(Profile, Args), Budget),
    Sale          = sale_proceeds(Price, H, GLow, GHigh),
    Loan          = loan_payout(Principal, Kind, H),
    Fees          = dispose_fees(Args, Sale, Loan, <<"other">>),
    Selling       = selling_from(Sale, Fees),
    {Cgt, Status} = cgt(Profile),
    CgtContrib    = cgt_contribution(Cgt, Status),
    Net           = net_proceeds(Sale, Selling, Loan, CgtContrib),
    Full          = full_horizon(Net, Budget, Ownership, H),
    %% Mode-A/B/E four-actor swimlane (fh_engine_journey:actors/0) — the money-flow party for
    %% sale/selling is "other" there.
    Events        = dispose_details(dispose_cash_events(Sale, Fees, Loan, Cgt, <<"other">>),
                                    {ceiling, Price}, H, GLow, GHigh, Principal, Kind, null),

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
        <<"loan_over_hold">>            => loan_over_hold(Principal, Kind, H),
        <<"growth_pct_pa">>             => [GLow, GHigh],
        <<"fee_pending">>               => element(2, Fees),
        <<"key_assumptions">>           => assumptions(H, GLow, GHigh, IsPlaceholder, Status, Loan, Kind)
    },
    KbVersions = fh_engine_kb:kb_anchors(lists:usort([?GROWTH, ?SELLING, ?CGT, ?SERVICEABILITY, ?COPY,
                                                      loan_detail_slug(Kind)])),
    {Outcome, <<"calculator">>, KbVersions}.

%% --- Mode-C/D investor (full CGT) --------------------------------------------
%% Reuses the mode-general sale_proceeds/selling_costs/net_proceeds; differs in the upstream
%% sources (budget_envelope_investor + cash_flow_projection over the main-residence variants),
%% the investment-loan amortisation rate, the full-CGT computation, and a signed hold cash flow
%% rolled into the full-horizon position.

fill_investor(Args, Profile, Tax, Upstream) ->
    Budget   = maps:get(<<"budget_envelope_investor">>, Upstream, #{}),
    CashFlow = maps:get(<<"cash_flow_projection">>, Upstream, #{}),

    H        = horizon(Profile),
    %% per-property (Phase B, Slice B3c): the ATTACHED property's exact price drives every dispose
    %% figure (sale_proceeds, taxable_gain, the net); at base: the target-range ceiling. So the
    %% dispose projection reflects THIS property, not the plan-wide range. [[place-upstream-figures-dont-recompute]]
    Pf       = maps:get(<<"property_fit_investor">>, Upstream, #{}),
    Price    = property_price(Pf, Profile),
    {GLow, GHigh, IsPlaceholder} = growth_band(),
    %% the loan: the attached property's price (or the target range at base) less the plan's
    %% own deposit event — the same basis as the Own phase's repayments (behavior 98).
    Kind     = loan_kind(Args, investor),
    Principal = principal(case maps:get(<<"price">>, Pf, null) of
                              PP when is_number(PP) -> [PP, PP];
                              _                   -> price_range(Profile, Args)
                          end, Budget),

    Sale                = sale_proceeds(Price, H, GLow, GHigh),
    Loan                = loan_payout(Principal, Kind, H),
    Fees                = dispose_fees(Args, Sale, Loan, <<"services">>),
    Selling             = selling_from(Sale, Fees),
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
    Basis               = case maps:get(<<"price">>, maps:get(<<"property_fit_investor">>, Upstream, #{}), null) of
                              P when is_number(P) -> property;
                              _                   -> ceiling
                          end,
    Events              = dispose_details(dispose_cash_events(Sale, Fees, Loan, Cgt, <<"services">>),
                                          {Basis, Price}, H, GLow, GHigh, Principal,
                                          Kind, {maps:get(<<"cgt_marginal_rate">>, Tax, null),
                                                     maps:get(<<"cgt_discount_eligible">>, Tax, null)}),
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
        <<"loan_over_hold">>            => loan_over_hold(Principal, Kind, H),
        <<"growth_pct_pa">>             => [GLow, GHigh],
        <<"fee_pending">>               => element(2, Fees),
        <<"key_assumptions">>           => assumptions_investor(H, GLow, GHigh, IsPlaceholder, Status, Loan, Frcgw, Kind)
    },
    FrcgwAnchors = case FrcgwApplicable of
                       true -> [?FRCGW];
                       _    -> []
                   end,
    KbVersions = fh_engine_kb:kb_anchors(
        lists:usort([?GROWTH, ?SELLING, ?CGT_INV, ?DEPR, ?SERV_INV, ?COPY, loan_detail_slug(Kind)]
                    ++ FrcgwAnchors)),
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

%% the target price range the loan is taken against: the profile's, else onboarding's (the
%% range fh_engine_ownership prices the repayments on). null when neither is a [lo, hi].
price_range(Profile, Args) ->
    Onb = maps:get(<<"target_price_range">>, maps:get(onboarding, Args, #{}), null),
    case maps:get(<<"target_price_range">>, Profile, Onb) of
        [Lo, Hi] when is_number(Lo), is_number(Hi), Lo =< Hi -> [Lo, Hi];
        _ -> null
    end.

%% --- growth band (kb.property.capital-growth-bands) ---------------------------
%% {low %, high %, is_placeholder} — the flag selects the assumption line's copy key.

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

%% --- selling costs: the dispose fee lines -------------------------------------
%% Whole lifecycle -> honesty tiers; one owner per fact -> disposition -> sell fee lines
%% Purpose:   what selling costs, one line per fee (agent commission, marketing,
%%            conveyancing, mortgage discharge; the money sent back to Vietnam in B/D),
%%            each from its owning KB doc via fh_engine_fees (behavior 83), where one
%%            selling_costs figure summed three of them before.
%% Holds:     selling_costs = the sum of the lines the seller pays for sure
%%            (fh_engine_fees:committed/1: optional ones such as the transfer back are
%%            shown, not summed); a money_range because the proceeds are banded. The
%%            transfer base is the proceeds less the loan payout when that is known.
-spec selling_costs([integer()] | null) -> [integer()] | null.
selling_costs(Sale) ->
    %% the existing home's loan payout already carries the lender's discharge fee
    %% (existing_home_disposal:total_payout), so that line is left out here: counted once.
    %% The state's discharge registration is not in the payout and stays.
    selling_from(Sale, drop_discharge(dispose_fees(#{blueprint_slug => <<"nexthome-domestic-au">>},
                                                   Sale, null, <<"other">>))).

drop_discharge({Events, Pending}) ->
    {[E || E <- Events, not is_discharge(maps:get(<<"id">>, E))], Pending}.

is_discharge(<<"mortgage_discharge">>) -> true;
is_discharge(_)                       -> false.

selling_from(null, _Fees) -> null;
selling_from(_Sale, {Events, _}) -> fh_engine_fees:committed(Events).

dispose_fees(_Args, null, _Loan, _Other) -> {[], []};
dispose_fees(Args, Sale, Loan, Other) ->
    fh_engine_fees:events([<<"dispose">>],
        #{blueprint => maps:get(blueprint_slug, Args, <<"fhb-domestic-au">>),
          state => case fh_engine_store:projection_state(maps:get(onboarding, Args, #{})) of
                       S when is_binary(S) -> S; _ -> undefined end,
          property => undefined, source => <<"disposition">>, counterparty => Other,
          price => null, loan => null, rent => null, sale => Sale,
          transfer => after_loan(Sale, Loan)}).

after_loan([SL, SH], [LL, LH]) -> [max(0, SL - LH), max(0, SH - LL)];
after_loan(Sale, _) -> Sale.

%% --- the loan: one principal, one rate, one amortisation (behavior 98) ----------
%% Whole lifecycle -> each phase has its money lines -> disposition owns amortisation ->
%%   the loan behind repayments, interest and the payout.
%% Purpose:   one loan for every phase of a plan: the Own phase's repayments
%%            (fh_engine_ownership), the interest and principal over the hold the statement
%%            sums (fh_engine_journey lifecycle_budget) and the balance paid out at sale.
%% Holds:     the principal is the price less the plan's own deposit event in every mode
%%            (principal/2), so an $800k home with a 5% deposit is a $760,000 loan; the
%%            payout no longer reads the borrowing capacity (A, B, E) or
%%            budget_envelope_investor.loan_amount (C, D; null at base, so D's payout was
%%            pending). The rate is the kind's band (rate_band/1): the KB representative
%%            owner-occupier rate, + the investment premium for an investor, + the
%%            non-resident premium band (kb.lender.non-resident-friendly-shortlist, 50-150bp)
%%            for a foreign buyer (B, D) — the low end of a band at the low premium, the
%%            high end at the high. Never the agent's loan_structure_recommendation.rate,
%%            which holds a rate-STRUCTURE enum (§98, measured 2026-10-08).
%% Rests on:  standard P&I over ?LOAN_TERM_YEARS; at both ends, interest over H =
%%            repayments × H − (principal − balance at H), on the rounded figures shown, so
%%            the identity holds to the dollar (loan_over_hold/3).
%% Known gaps: the non-resident investment-loan premium the KB states in prose
%%            (non-resident-investment-loan-shortlist, a further ~100-200bp over the domestic
%%            investor rate) has no param, so D takes the owner-occupier non-resident band on
%%            top of the investment rate. A per-property investor's Own phase uses
%%            yield_modelling's interest line, not this split.

%% the plan's own deposit event (cash_position's figure, placed — never re-derived), off the
%% price band: a deposit band spanning the price band pairs end to end; a point deposit (B, C,
%% D compute at the ceiling) pairs with the ceiling only. null without a range or a deposit.
-spec principal([number()] | null, map()) -> [integer()] | null.
principal(null, _Budget) -> null;
principal([PLo, PHi], Budget) ->
    Deposits = [maps:get(<<"amount">>, E) || E <- maps:get(<<"cash_events">>, Budget, []),
                                             maps:get(<<"id">>, E, <<>>) =:= <<"deposit">>],
    case Deposits of
        [[D, D]] when is_number(D) -> nonneg([round(PHi - D), round(PHi - D)]);
        [[DLo, DHi]] when is_number(DLo), is_number(DHi) -> nonneg([round(PLo - DLo), round(PHi - DHi)]);
        _ -> null
    end.

nonneg([A, B]) when A >= 0, B >= 0 -> [A, B];
nonneg(_) -> null.

%% the loan's kind from the plan's mode: a foreign buyer (fhb-foreign-au, investor-foreign-au)
%% borrows at the non-resident rate.
-spec loan_kind(map(), owner | investor) -> owner | investor | owner_foreign | investor_foreign.
loan_kind(Args, Base) ->
    case {maps:get(blueprint_slug, Args, undefined), Base} of
        {<<"fhb-foreign-au">>, owner}         -> owner_foreign;
        {<<"investor-foreign-au">>, investor} -> investor_foreign;
        _                                     -> Base
    end.

%% the [low, high] annual rate % a loan of this kind amortises at (a point for A, C, E).
-spec rate_band(owner | investor | owner_foreign | investor_foreign) -> [number()].
rate_band(owner)            -> [representative_rate(), representative_rate()];
rate_band(investor)         -> [investor_rate(), investor_rate()];
rate_band(owner_foreign)    -> plus_premium(representative_rate());
rate_band(investor_foreign) -> plus_premium(investor_rate()).

plus_premium(R) ->
    Slug = <<"kb.lender.non-resident-friendly-shortlist">>,
    [two_dp(R + param(Slug, <<"non_resident_rate_premium_bp_low">>) / 100),
     two_dp(R + param(Slug, <<"non_resident_rate_premium_bp_high">>) / 100)].

two_dp(X) -> round(X * 100) / 100.

%% the balance left at year H, at both ends of the principal and rate bands; null until H and
%% the principal are known (honest-partial).
-spec loan_payout([number()] | null, atom(), integer() | null) -> [integer()] | null.
loan_payout(_Principal, _Kind, null) -> null;
loan_payout([PLo, PHi], Kind, H) when is_integer(H) ->
    [RLo, RHi] = rate_band(Kind),
    [round(remaining_balance(PLo, RLo, ?LOAN_TERM_YEARS, H)),
     round(remaining_balance(PHi, RHi, ?LOAN_TERM_YEARS, H))];
loan_payout(_, _, _) -> null.

%% the loan's repayments over H split into interest (a cost) and principal repaid (money into
%% the home), at both ends. Each band is ordered on its own: a higher rate on the same loan
%% repays less principal by H, so the principal band's ends can swap. null until H and the
%% principal are known.
-spec loan_over_hold([number()] | null, atom(), integer() | null) -> map() | null.
loan_over_hold([PLo, PHi], Kind, H) when is_integer(H), H > 0 ->
    [RepLo, RepHi] = annual_repayments([PLo, PHi], Kind),
    [PayLo, PayHi] = loan_payout([PLo, PHi], Kind, H),
    {PaidLo, PaidHi} = {round(PLo) - PayLo, round(PHi) - PayHi},
    #{<<"principal">>        => [round(PLo), round(PHi)],
      <<"rate">>             => rate_band(Kind),
      <<"years">>            => H,
      <<"repayments">>       => [RepLo * H, RepHi * H],
      <<"interest">>         => ordered(RepLo * H - PaidLo, RepHi * H - PaidHi),
      <<"principal_repaid">> => ordered(PaidLo, PaidHi)};
loan_over_hold(_, _, _) -> null.

ordered(A, B) when A =< B -> [A, B];
ordered(A, B)             -> [B, A].

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
remaining_balance(P, R0, TermYears, ElapsedYears) when R0 == 0 ->
    P * (TermYears - ElapsedYears) / TermYears;
remaining_balance(P, AnnualRatePct, TermYears, ElapsedYears) ->
    R = AnnualRatePct / 100 / 12,
    N = TermYears * 12,
    K = ElapsedYears * 12,
    P * (math:pow(1 + R, N) - math:pow(1 + R, K)) / (math:pow(1 + R, N) - 1).

%% --- annual loan repayments (the Own-phase per-year line, behavior 82) ---------
%% Whole lifecycle -> each phase has its money lines -> disposition owns amortisation ->
%%   the yearly P&I on a principal band.
%% Goal: the lifecycle sheet (behavior 82) shows a per-year cost to own; the biggest is
%%   the loan. Invariant: one computer per figure — the rate and the amortisation live
%%   here beside remaining_balance/4, so the yearly repayment and the balance paid out at
%%   sale stay on one basis. Component: fh_engine_ownership places the band as an own
%%   cash event. Capability: standard P&I over ?LOAN_TERM_YEARS at the kind's rate band
%%   (rate_band/1) — a labelled CONVENTION, never this buyer's product rate; null when the
%%   principal is unknown (honest-partial).
-spec annual_repayments([number()] | null, atom()) -> [integer()] | null.
annual_repayments([PLo, PHi], Kind) when is_number(PLo), is_number(PHi) ->
    {[RLo, RHi], _Term} = repayment_basis(Kind),
    [round(annual_pi(PLo, RLo, ?LOAN_TERM_YEARS)), round(annual_pi(PHi, RHi, ?LOAN_TERM_YEARS))];
annual_repayments(_, _) -> null.

%% {[low, high] annual rate %, term years} a loan of this kind is amortised at — one basis for
%% the yearly repayment, the payout at sale and both lines' details.
-spec repayment_basis(atom()) -> {[number()], pos_integer()}.
repayment_basis(Kind) -> {rate_band(Kind), ?LOAN_TERM_YEARS}.

annual_pi(P, R0, TermYears) when R0 == 0 -> P / TermYears;
annual_pi(P, AnnualRatePct, TermYears) ->
    R = AnnualRatePct / 100 / 12,
    N = TermYears * 12,
    12 * P * R / (1 - math:pow(1 + R, -N)).

%% the investment-loan amortisation rate: the owner-occupier representative rate
%% (kb.lender.serviceability-basics) + the investment premium (kb.lender.serviceability-
%% investment-loans). A labelled KB convention surfaced in key_assumptions, never a product rate.
investor_rate() ->
    two_dp(representative_rate() + param(?SERV_INV, <<"investment_rate_premium_pp">>)).

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

%% the CGT discount %: the individual discount once the holding clears 12 months
%% (kb.tax.cgt-50-percent-discount); else 0% — the full nominal gain is taxable (held < 12
%% months OR eligibility undetermined: the conservative, higher-gain direction).
cgt_discount(true) -> param(?CGT_INV, <<"discount_pct_individual">>);
cgt_discount(_)    -> 0.

-spec cgt_investor(map(), map(), [integer()] | null, number() | null) ->
          {[integer()] | null, [integer()] | null, binary()}.
cgt_investor(Profile, Tax, Sale, Price) ->
    Entity   = maps:get(<<"recommended_entity">>, Tax, null),
    Rate     = maps:get(<<"cgt_marginal_rate">>, Tax, null),
    Eligible = maps:get(<<"cgt_discount_eligible">>, Tax, null),
    Clawback = maps:get(<<"cost_base_depreciation_clawback">>, Tax, null),
    Discount = cgt_discount(Eligible),
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
-spec dispose_cash_events([integer()] | null, {[map()], [map()]},
                          [integer()] | null, [integer()] | null, binary()) -> [map()].
dispose_cash_events(Sale, {FeeEvents, _}, Loan, Cgt, MoneyPartyId) ->
    Candidates = [
        event(<<"sale_proceeds">>, <<"event_sale_proceeds">>, <<"in">>,  Sale,    MoneyPartyId),
        event(<<"loan_payout">>,   <<"event_loan_payout">>,   <<"out">>, Loan,    <<"lender">>),
        event(<<"cgt">>,           <<"event_cgt">>,           <<"out">>, Cgt,     <<"government">>)
    ],
    [E || E <- Candidates, maps:get(<<"amount">>, E) =/= null] ++ FeeEvents.

%% Whole lifecycle -> every statement line opens its own detail -> disposition -> the sell
%% lines' details (behavior 93).
%% Goal: the sale price, the loan paid out and CGT open in place like the sell fee lines.
%% Invariant: each detail names the figures this module computed the line with — the price
%% basis, the growth band and horizon, the principal, rate and term, the discount and the
%% marginal rate — from the doc that owns them (fh_engine_line_detail). The exported
%% dispose_cash_events/5 is left as it was; this wraps it.
dispose_details(Events, {Basis, Price}, H, GLow, GHigh, Principal, Kind, CgtRate)
  when is_number(Price), is_integer(H) ->
    Pct = fun fh_engine_line_detail:pct/1,
    {Rate, Term} = repayment_basis(Kind),
    ServSlug = loan_detail_slug(Kind),
    Sale = {?GROWTH, <<"sale_proceeds">>,
            #{params => #{<<"price">> => fh_engine_line_detail:price(Basis, Price),
                          <<"low">> => Pct(GLow), <<"high">> => Pct(GHigh), <<"years">> => H}}},
    Payout = case Principal of
                 [_, _] -> #{<<"dispose_loan_payout">> =>
                                 {ServSlug, <<"loan_payout">>,
                                  #{params => #{<<"principal">> =>
                                                    fh_engine_line_detail:money_range(Principal),
                                                <<"years">> => H, <<"term">> => Term,
                                                <<"rate">> => fh_engine_line_detail:pct_range(Rate)}}}};
                 _      -> #{}
             end,
    Cgt = case CgtRate of
              {R, Eligible} when is_number(R) ->
                  #{<<"dispose_cgt">> =>
                        {?CGT_INV, <<"cgt">>,
                         #{params => #{<<"discount">> => Pct(cgt_discount(Eligible)),
                                       <<"rate">> => Pct(R)}}}};
              _ -> #{}
          end,
    fh_engine_line_detail:attach_all(
        Events, maps:merge(#{<<"dispose_sale_proceeds">> => Sale}, maps:merge(Payout, Cgt)));
dispose_details(Events, _Price, _H, _GLow, _GHigh, _Principal, _Kind, _CgtRate) ->
    Events.

%% the KB doc whose line detail explains a loan line of this kind: a foreign buyer's names the
%% non-resident premium (behavior 98).
loan_detail_slug(owner)            -> ?SERVICEABILITY;
loan_detail_slug(investor)         -> ?SERV_INV;
loan_detail_slug(owner_foreign)    -> <<"kb.lender.non-resident-friendly-shortlist">>;
loan_detail_slug(investor_foreign) -> <<"kb.lender.non-resident-friendly-shortlist">>.

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

assumptions(null, _GLow, _GHigh, _IsPlaceholder, _Status, _Loan, _Kind) ->
    %% no horizon set → the only assumption is the invitation to set one.
    [copy(<<"assumption_set_horizon">>, #{})];
assumptions(H, GLow, GHigh, IsPlaceholder, Status, Loan, Kind) ->
    Base = [copy(<<"assumption_horizon">>, #{<<"years">> => H}),
            growth_assumption(GLow, GHigh, IsPlaceholder),
            cgt_assumption(Status),
            copy(<<"assumption_selling_costs">>, #{})],
    %% the loan-rate basis is stated ONLY when a loan payout is actually shown (capacity
    %% known) — otherwise it would assert a basis for a figure that is PENDING.
    case Loan of
        null -> Base;
        _    -> Base ++ [copy(<<"assumption_loan_rate">>,
                              #{<<"rate">> => fh_engine_line_detail:pct_range(rate_band(Kind)),
                                <<"term">> => ?LOAN_TERM_YEARS})]
    end.

%% The growth line's copy key follows the doc's `is_placeholder` flag: an unsourced band says
%% PLACEHOLDER; a band grounded in a named series names that series. So the flag, not this
%% module, decides what the user is told about the band's basis — re-grounding (or reverting)
%% the doc changes the prose with no engine edit, and a placeholder band can never reach a
%% user labelled as sourced (behavior 12; kb.copy.disposition).
-spec growth_assumption(number(), number(), boolean()) -> fh_engine_i18n:localized().
growth_assumption(GLow, GHigh, true) ->
    copy(<<"assumption_growth_placeholder">>, #{<<"low">> => GLow, <<"high">> => GHigh});
growth_assumption(GLow, GHigh, false) ->
    copy(<<"assumption_growth_sourced">>, #{<<"low">> => GLow, <<"high">> => GHigh}).

cgt_assumption(<<"exempt">>)    -> copy(<<"assumption_cgt_exempt">>, #{});
cgt_assumption(<<"to_verify">>) -> copy(<<"assumption_cgt_to_verify">>, #{}).

%% --- investor key_assumptions (bilingual; the §8.4 ASIC discipline) ----------
%% reuses horizon / growth / selling-cost / loan-rate lines (the loan-rate line
%% carries the investor rate via {rate} substitution); swaps in the investor CGT basis and adds
%% the 2026-27 Budget reform flag (current law computed; the reform may change it from 1 Jul 2027).
%% The FRCGW line (Mode D only) is appended LAST, only when the withheld figure is actually
%% shown — never asserting a basis for a null figure (mirrors the loan-rate line's own gate).
assumptions_investor(null, _GLow, _GHigh, _IsPlaceholder, _Status, _Loan, _Frcgw, _Kind) ->
    [copy(<<"assumption_set_horizon">>, #{})];
assumptions_investor(H, GLow, GHigh, IsPlaceholder, Status, Loan, Frcgw, Kind) ->
    Base = [copy(<<"assumption_horizon">>, #{<<"years">> => H}),
            growth_assumption(GLow, GHigh, IsPlaceholder),
            cgt_assumption_investor(Status),
            cgt_reform_assumption(Frcgw),
            copy(<<"assumption_selling_costs">>, #{})],
    WithLoan = case Loan of
        null -> Base;
        _    -> Base ++ [copy(<<"assumption_loan_rate">>,
                              #{<<"rate">> => fh_engine_line_detail:pct_range(rate_band(Kind)),
                                <<"term">> => ?LOAN_TERM_YEARS})]
    end,
    case Frcgw of
        null -> WithLoan;
        _    -> WithLoan ++ [copy(<<"assumption_frcgw">>, #{})]
    end.

%% Regulated figures are grounded -> a tax line matches its KB doc -> the reform flag
%% -> picks the resident or the foreign-resident wording.
%% A foreign resident gets no 50% discount for the foreign-resident period
%% (kb.tax.cgt-50-percent-discount; kb.non-resident-tax.cgt-no-ppor-exemption), so the
%% resident line "This uses current law (the 50% CGT discount)" is wrong on a Mode D plan
%% (seen 2026-10-08 in Chrome on an investor-foreign plan, behavior 31). Frcgw is non-null
%% exactly when tax_optimised_structure.frcgw_applicable is true, i.e. Mode D: the same
%% signal as the FRCGW line, so the two foreign lines appear together. The KB holds nothing
%% on the 1 Jul 2027 reform's foreign-resident terms, so the foreign line names the date and
%% defers to a tax agent (concluded).
cgt_reform_assumption(null) -> copy(<<"assumption_cgt_reform">>, #{});
cgt_reform_assumption(_)    -> copy(<<"assumption_cgt_reform_foreign">>, #{}).

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
