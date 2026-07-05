-module(fh_engine_existing_home_disposal).

%% The base-turn `existing_home_disposal` fill — Mode E ONLY (nexthome-domestic-au.md
%% component 3). Projects the net proceeds of selling the buyer's CURRENT home (already
%% owned, lived in) to fund the next purchase — DISTINCT from fh_engine_disposition, which
%% projects the FUTURE exit of the NEW property this plan is for. No other mode runs this
%% component (Modes A/B/C/D have no existing home to sell mid-plan).
%%
%% ONE-COMPUTER-PER-FIGURE ([[place-upstream-figures-dont-recompute]]). Selling costs and CGT
%% are REUSED, not re-derived: fh_engine_disposition:selling_costs/1, :cgt/1, and
%% :net_proceeds/4 are called directly (kb.selling-costs.agent-legal / kb.tax.cgt-main-
%% residence-exemption apply identically to a sale happening now as to a future one). The
%% only genuinely new computation here is the loan PAYOUT (kb.existing-home-sale.net-proceeds):
%% outstanding balance (user-attested) + a discharge-fee band (market convention) + a
%% fixed-rate break-cost flag (lender-calculated, NEVER estimated — the resolver surfaces
%% to_verify, never a guessed dollar figure).
%%
%% BRIDGING-FINANCE HANDOFF. A settlement-timing mismatch (the new purchase settling before
%% the existing home's sale) is a plain date/status comparison — detected here — but the
%% ECONOMICS (peak debt, capitalised interest) are a labelled placeholder
%% (kb.bridging-finance.mechanics, mode-e-wedge.md scoping decision #3): this resolver never
%% computes past the structural fact.
%%
%% HONEST-PARTIAL ([[base-turn-honest-partial-output]]). No onboarding capture of the
%% existing home's sale price / loan balance / settlement dates (plan-first, constraint #1)
%% — these arrive on a refine turn. At base, every figure is null except the labelled
%% qualitative flags; the structure computes a real figure the moment a refine turn supplies
%% the facts, with zero further code change.

-export([fill/2]).
%% exported for the conformance harness:
-export([total_payout/2, break_status/1, discharge_fee_band/0,
         cgt_for_existing_home/2, cgt_contribution/2,
         net_sale_proceeds/4, settlement_mismatch/2]).

-define(COPY,           <<"kb.copy.existing-home-disposal">>).
-define(DISPOSITION_COPY, <<"kb.copy.disposition">>).
-define(NET_PROCEEDS_KB, <<"kb.existing-home-sale.net-proceeds">>).
-define(SELLING,        <<"kb.selling-costs.agent-legal">>).
-define(CGT,             <<"kb.tax.cgt-main-residence-exemption">>).
-define(BRIDGING,        <<"kb.bridging-finance.mechanics">>).

%% --- entry -------------------------------------------------------------------

-spec fill(map(), map()) -> {map(), binary(), [map()]}.
fill(_Args, Upstream) ->
    Profile  = maps:get(<<"profile">>, Upstream, #{}),
    Existing = maps:get(<<"existing_home_ownership">>, Profile, #{}),

    SalePrice          = maps:get(<<"ppor_estimated_value">>, Existing, null),
    OutstandingBalance = maps:get(<<"ppor_outstanding_loan_balance">>, Existing, null),
    RateType           = maps:get(<<"ppor_loan_rate_type">>, Existing, null),
    RentalHistory       = maps:get(<<"ppor_rental_history">>, Existing, false),

    SaleRange = point(SalePrice),
    %% REUSED — same computer as fh_engine_disposition's own future-exit projection.
    Selling   = fh_engine_disposition:selling_costs(SaleRange),
    {BreakStatus, DischargeFee, TotalPayout} = total_payout(OutstandingBalance, RateType),
    {CgtAmt, CgtStatus} = cgt_for_existing_home(Profile, RentalHistory),
    CgtContrib = cgt_contribution(CgtAmt, CgtStatus),
    Net = net_sale_proceeds(SaleRange, Selling, TotalPayout, CgtContrib),

    %% Settlement-timing facts arrive the same way settlement_prep's dates do (structured
    %% attestation, not extraction) — honestly absent at base (no onboarding capture); the
    %% resolver never asserts a mismatch without both a date and a sale status known.
    Mismatch = settlement_mismatch(null, null),

    Outcome = #{
        <<"estimated_sale_price">> => SalePrice,
        <<"loan_payout">> => #{
            <<"outstanding_balance">> => OutstandingBalance,
            <<"discharge_fee">>       => DischargeFee,
            <<"break_cost_status">>   => BreakStatus,
            <<"total_payout">>        => TotalPayout
        },
        <<"selling_costs">>                   => Selling,
        <<"cgt">>                             => CgtAmt,
        <<"cgt_status">>                      => CgtStatus,
        <<"net_sale_proceeds">>               => Net,
        <<"settlement_timing_mismatch">>      => Mismatch,
        <<"bridging_finance_considered">>     => Mismatch,
        <<"bridging_finance_is_placeholder">> => true,
        <<"key_assumptions">> => key_assumptions(SalePrice, BreakStatus, DischargeFee, CgtStatus)
    },
    KbVersions = fh_engine_kb:kb_anchors(
        [?NET_PROCEEDS_KB, ?SELLING, ?CGT, ?BRIDGING, ?COPY]),
    {Outcome, <<"calculator">>, KbVersions}.

%% --- loan payout: outstanding balance + discharge fee; break cost NEVER estimated -----
%% variable-rate → not_applicable (the 1 Jul 2011 exit-fee ban, kb.existing-home-sale.net-
%% proceeds); fixed/unknown/absent → to_verify (the break cost is lender-calculated from
%% cost-of-funds, never a fixed %, so total_payout stays null rather than guessed).

-spec total_payout(number() | null, binary() | null) ->
          {binary(), [number()], [number()] | null}.
total_payout(Balance, RateType) ->
    Status = break_status(RateType),
    Fee = discharge_fee_band(),
    Total = payout_total(Balance, Status, Fee),
    {Status, Fee, Total}.

-spec break_status(binary() | null) -> binary().
break_status(<<"variable">>) -> <<"not_applicable">>;
break_status(_)              -> <<"to_verify">>.   %% fixed | unknown | absent → the safer default

payout_total(Balance, <<"not_applicable">>, [Lo, Hi]) when is_number(Balance) ->
    [Balance + Lo, Balance + Hi];
payout_total(_Balance, _Status, _Fee) ->
    null.

discharge_fee_band() ->
    [param(?NET_PROCEEDS_KB, <<"discharge_fee_low_aud">>),
     param(?NET_PROCEEDS_KB, <<"discharge_fee_high_aud">>)].

%% --- CGT: REUSE fh_engine_disposition's own main-residence-exemption computer ---------
%% disposition:cgt/1 reads Profile's `intended_occupancy_use` (which describes the NEW home
%% being bought) — for the EXISTING home we substitute a proxy occupancy signal derived from
%% its own rental history, so the SAME regulated logic (occupancy + tax_residency →
%% exempt/to_verify) applies to the right property. No new CGT rule is authored here.

-spec cgt_for_existing_home(map(), boolean()) -> {null, binary()}.
cgt_for_existing_home(Profile, RentalHistory) ->
    Occupancy = case RentalHistory of
                    true -> <<"partial_rental">>;
                    _    -> <<"sole_occupier">>
                end,
    ProxyProfile = Profile#{<<"intended_occupancy_use">> => Occupancy},
    fh_engine_disposition:cgt(ProxyProfile).

%% mirrors fh_engine_disposition's own (private) cgt_contribution/2 — trivial arithmetic
%% glue, not a second regulated computer: exempt → $0 deducted; to_verify → unknown gain,
%% net_sale_proceeds stays PENDING rather than asserting a $0 tax that may not hold.
cgt_contribution(null, <<"exempt">>)    -> [0, 0];
cgt_contribution(_,    <<"to_verify">>) -> null.

%% --- net sale proceeds: REUSE disposition's own interval-arithmetic net_proceeds/4 ----
-spec net_sale_proceeds([number()] | null, [number()] | null,
                        [number()] | null, [number()] | null) -> [number()] | null.
net_sale_proceeds(Sale, Selling, Loan, CgtContrib) ->
    fh_engine_disposition:net_proceeds(Sale, Selling, Loan, CgtContrib).

%% --- settlement-timing mismatch: a plain date/status comparison, no professional judgement.
%% Never asserts a mismatch without both a settlement date and a sale status; hands off to
%% kb.bridging-finance.mechanics (a placeholder) rather than computing bridging economics.
-spec settlement_mismatch(binary() | null, binary() | null) -> boolean().
settlement_mismatch(null, _Status) -> false;
settlement_mismatch(_Date, null)   -> false;
settlement_mismatch(_Date, Status)
  when Status =:= <<"under_contract">>; Status =:= <<"settled">> -> false;
settlement_mismatch(_Date, _Status) -> true.

%% --- key_assumptions (bilingual via kb.copy.existing-home-disposal + reused disposition copy)
key_assumptions(null, _Status, _Fee, _CgtStatus) ->
    [copy(<<"assumption_no_existing_home_facts">>, #{})];
key_assumptions(_Price, <<"not_applicable">>, [Lo, Hi], CgtStatus) ->
    [copy(<<"assumption_no_exit_fee_variable">>, #{}),
     copy(<<"assumption_discharge_fee">>, #{<<"low">> => money(Lo), <<"high">> => money(Hi)})]
    ++ [copy_disposition(<<"assumption_selling_costs">>, #{})]
    ++ cgt_assumption(CgtStatus);
key_assumptions(_Price, <<"to_verify">>, [Lo, Hi], CgtStatus) ->
    [copy(<<"assumption_break_cost_to_verify">>, #{}),
     copy(<<"assumption_discharge_fee">>, #{<<"low">> => money(Lo), <<"high">> => money(Hi)})]
    ++ [copy_disposition(<<"assumption_selling_costs">>, #{})]
    ++ cgt_assumption(CgtStatus).

cgt_assumption(<<"exempt">>)    -> [copy_disposition(<<"assumption_cgt_exempt">>, #{})];
cgt_assumption(<<"to_verify">>) -> [copy_disposition(<<"assumption_cgt_to_verify">>, #{})].

%% --- helpers -----------------------------------------------------------------

point(V) when is_number(V) -> [V, V];
point(_)                   -> null.

param(Slug, Key) ->
    {ok, Cj} = fh_engine_kb:kb_rules(Slug),
    Params = maps:get(<<"parameters">>, Cj),
    maps:get(<<"value">>, maps:get(Key, Params)).

-spec copy(binary(), #{binary() => fh_engine_i18n:param()}) -> fh_engine_i18n:localized().
copy(Id, Params) ->
    fh_engine_i18n:subst(fh_engine_kb:copy(?COPY, Id), Params).

%% reuses kb.copy.disposition's own CGT/selling-cost prose — one copy doc per regulated
%% concept, not a second fork per consuming component.
-spec copy_disposition(binary(), #{binary() => fh_engine_i18n:param()}) -> fh_engine_i18n:localized().
copy_disposition(Id, Params) ->
    fh_engine_i18n:subst(fh_engine_kb:copy(?DISPOSITION_COPY, Id), Params).

%% money as a plain "$1,500,000" string — shared formatter (fh_engine_money).
money(N) -> fh_engine_money:money(N).
