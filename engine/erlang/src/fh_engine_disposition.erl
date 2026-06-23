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
%% MODE-A CGT. The dwelling is the buyer's main residence → CGT-exempt (cgt = null,
%% cgt_status = exempt) for the clean owner-occupier resident-for-tax case; to_verify once a
%% trap applies (part rental / non-resident / land > 2 ha — kb.tax.cgt-main-residence-exemption).
%% Mode A NEVER estimates a taxable gain. The investor CGT math (50% discount, cost base) is
%% Modes C/D, design-first (§8.7).
%%
%% The disposition outcome + the calculator renderer are mode-general; Modes C/D reuse them with
%% the investor CGT computation, authored design-first when those modes ship.

-export([fill/2]).
%% exported for the conformance harness:
-export([sale_proceeds/4, selling_costs/1, loan_payout/2, cgt/1,
         net_proceeds/4, full_horizon/4, dispose_cash_events/4]).

-define(COPY,    <<"kb.copy.disposition">>).
-define(GROWTH,  <<"kb.property.capital-growth-bands">>).
-define(SELLING, <<"kb.selling-costs.agent-legal">>).
-define(CGT,     <<"kb.tax.cgt-main-residence-exemption">>).
-define(SERVICEABILITY, <<"kb.lender.serviceability-basics">>).

-define(LOAN_TERM_YEARS, 30).   %% standard P&I term; the amortisation default (mortgage_plan
                                %% carries no term at base — a documented constant, not a magic figure).

%% --- entry -------------------------------------------------------------------

-spec fill(map(), map()) -> {map(), binary(), [map()]}.
fill(_Args, Upstream) ->
    Profile   = maps:get(<<"profile">>, Upstream, #{}),
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
    Events        = dispose_cash_events(Sale, Selling, Loan, Cgt),

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

%% --- inputs ------------------------------------------------------------------

%% H: the hold horizon (years). null = no disposal projection (Mode-A long/indefinite
%% default); the horizon structural what-if sets it (engine-contract §10.5).
horizon(Profile) ->
    case maps:get(<<"hold_horizon_years">>, Profile, null) of
        H when is_integer(H), H > 0 -> H;
        _                           -> null
    end.

%% the purchase-price basis: the target_price_range CEILING at base (the conservative
%% upper bound the every-financial-figure narrowing uses); a specific property price
%% per-property (Phase B). null when no target is set.
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

%% --- dispose_cash_events (the Dispose-phase entries of the shared spine) ------
%% Mirrors the cash_event shape exactly so purchase_journey PLACES them on the swimlane's
%% Dispose column (TW3). phase = "dispose", timing = one_off. Honest-partial: an event is
%% emitted only when its amount is present (a null-amount figure is dropped, never faked).

-spec dispose_cash_events([integer()] | null, [integer()] | null,
                          [integer()] | null, null) -> [map()].
dispose_cash_events(Sale, Selling, Loan, Cgt) ->
    Candidates = [
        event(<<"sale_proceeds">>, <<"event_sale_proceeds">>, <<"in">>,  Sale,    <<"other">>),
        event(<<"selling_costs">>, <<"event_selling_costs">>, <<"out">>, Selling, <<"other">>),
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
