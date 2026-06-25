-module(fh_engine_mortgage).

%% The base-turn `mortgage_finance` fill — the RESOLVER half of a TWO-PATH component
%% (mortgage-finance-two-path.md). It assembles the `mortgage_plan` outcome's figures
%% and loan-path structure deterministically; the `lender_fit` leaves are left `null`
%% for the agent and folded in by merge_agent/2 after the sidecar replies.
%%
%% TWO VARIANTS, shared component NAME (`mortgage_finance`): the Mode-A FHB path (fill_fhb/2,
%% two leaves: shortlist + rate) and the Mode-C investor path (fill_investor/2, five leaves:
%% io/PI, rate, offset strategy, uses_existing_ppor_equity, investor lender shortlist). fill/2
%% routes on the `strategy_thesis` upstream (investor-only); merge_agent/2 +
%% agent_values_from_outcome/1 route on the `io_vs_pi_recommendation` outcome key
%% (investor-only). Both discriminators are local shape sniffs — no signature change, the FHB
%% bodies are byte-identical (zero regression). Mirrors fh_engine_cash / fh_engine_disposition.
%%
%% §98 (agentic-boundary): borrowing capacity is a COMPLIANCE-sensitive figure and must
%% be computed, never LLM-asserted. At the base turn income + committed debts are ABSENT
%% (buyer_profile leaves them pending), so capacity is honestly PENDING (null) — the same
%% honest-partial call as ownership P&I and cash deposit/loan. The capacity *formula*
%% (buffer-assessed) is a refine-turn concern; §98 keeps it resolver-computed there too.
%%
%% KB supplies the data (the 3.0pp APRA buffer is the one regulated constant; the rest
%% are flagged conventions); code supplies the assembly. No literals — every figure is a
%% KB param or a stated function of one.

-export([fill/2, merge_agent/2, agent_values_from_outcome/1]).
%% exported for cross-language conformance (tests/mortgage_eval.py mirrors these):
-export([recommended_path/1, has_fhg/1, loan_structure_base/0, key_assumptions/2,
         pre_approval_action_plan/0]).
%% exported for the serviceability conformance suite:
-export([borrowing_capacity/1, income_tax/1, hecs_repayment/1, net_annual_income/1,
         marginal_rate/1]).

-define(SERVICEABILITY, <<"kb.lender.serviceability-basics">>).
-define(HEM,    <<"kb.lender.hem-living-expenses">>).
-define(TAX,    <<"kb.tax.income-tax-resident-2025-26">>).
-define(HECS,   <<"kb.hecs.thresholds">>).
-define(CARD,   <<"kb.lender.credit-card-treatment">>).
-define(COPY, <<"kb.copy.mortgage">>).   %% bilingual copy-templates (bilingual-content.md §3b)

%% --- fill (resolver half) ---------------------------------------------------

%% MODE DISPATCH (mirrors fh_engine_cash / fh_engine_disposition): mortgage_finance is a
%% shared component NAME across the FHB and investor blueprints with DIFFERENT outcome
%% shapes (both typed `mortgage_plan`, distinct per-blueprint registries). Only the investor
%% blueprint runs an `investment_strategy` component upstream of mortgage_finance, so the
%% presence of its `strategy_thesis` outcome marks the Mode-C investor path; the Mode-A FHB
%% path reads `scheme_stack`. The FHB body is renamed fill_fhb/2 VERBATIM (byte-identical —
%% zero regression); the investor body (fill_investor/2) is new.
-spec fill(map(), map()) -> {map(), binary(), [map()]}.
fill(Args, Upstream) ->
    case maps:is_key(<<"strategy_thesis">>, Upstream) of
        true  -> fill_investor(Args, Upstream);
        false -> fill_fhb(Args, Upstream)
    end.

-spec fill_fhb(map(), map()) -> {map(), binary(), [map()]}.
fill_fhb(_Args, Upstream) ->
    Profile = maps:get(<<"profile">>, Upstream, #{}),
    Stack   = maps:get(<<"scheme_stack">>, Upstream, #{}),
    HasFhg  = has_fhg(Stack),
    _TargetRange = maps:get(<<"target_price_range">>, Profile, null),
    Outcome = #{
        %% DETERMINATE from eligibility: FHG present → the 5%-deposit, no-LMI path is
        %% the recommended one for a Mode-A FHB; absent → pending the deposit %.
        <<"recommended_path">> => recommended_path(Stack),
        %% Serviceability resolver (§98 — removed from the LLM's reach): a banded,
        %% buffer-assessed capacity from the profile's FRAMED income/debt facts (profile
        %% holds facts, mortgage reasons). null until assessable_income is known —
        %% honest-partial, income arrives on a refine turn (IC3). Never LLM-authored.
        <<"expected_borrowing_capacity">> => borrowing_capacity(Profile),
        %% PENDING — needs the debt balances (HECS/cards/BNPL), absent at base.
        <<"debt_optimisations_to_action">> => [],
        %% AGENT slot (lender_fit) — filled by merge_agent/2 from the sidecar reply.
        <<"recommended_lender_shortlist">> => null,
        <<"loan_structure_recommendation">> => loan_structure_base(),
        <<"pre_approval_action_plan">> => pre_approval_action_plan(),
        %% F11 — null until pre-approval is granted (a refine/event turn).
        <<"pre_approval_expiry">> => null,
        <<"reapplication_required">> => false,
        <<"key_assumptions">> => key_assumptions(buffer_pp(), HasFhg)
    },
    KbVersions = fh_engine_kb:kb_anchors(
        [?SERVICEABILITY, <<"kb.lender.fhg-panel-list">>, <<"kb.lmi.calculation">>,
         <<"kb.lender.hecs-treatment-by-lender">>, <<"kb.lender.credit-card-treatment">>,
         <<"kb.lender.bnpl-treatment-2026">>]),
    {Outcome, <<"summary-card">>, KbVersions}.

%% --- fill_investor (resolver half, Mode-C investor mortgage_plan) -----------
%% The investor `mortgage_plan` (7 fields) is a TWO-PATH outcome like the FHB one: the
%% resolver owns the renderer, the kb_versions audit, the loan-structure scaffold, the
%% KB-grounded refinance framing, and EVERY figure; the FIVE lender_fit leaves (io/PI,
%% fixed_vs_variable, offset strategy, uses_existing_ppor_equity, lender shortlist) are
%% left null/[] for the agent and folded by merge_agent_investor/2 after the sidecar
%% replies. §98: borrowing capacity / loan cost are COMPLIANCE-sensitive figures — at the
%% base turn income, debts, and the property are ABSENT, so they are honestly PENDING
%% (null), the same honest-partial call as the FHB fill. No magic literal: the IO term and
%% the refinance LVR conventions are KB params (flagged conventions), not code constants.
-spec fill_investor(map(), map()) -> {map(), binary(), [map()]}.
fill_investor(_Args, _Upstream) ->
    Outcome = #{
        %% resolver scaffold; the agent folds repayment_type/rate/offset/uses_ppor_equity.
        <<"recommended_loan_structure">> => loan_structure_investor_base(),
        %% AGENT slots (lender_fit) — filled by merge_agent_investor/2 from the sidecar.
        <<"recommended_lender_shortlist">> => null,
        <<"io_vs_pi_recommendation">> => null,
        <<"offset_strategy_recommendation">> => null,
        %% resolver, KB-grounded conventions + null property/date-dependent fields.
        <<"refinance_plan_for_portfolio_growth">> => refinance_plan_base(),
        %% PENDING — needs the debt balances (HECS/cards/other), absent at base.
        <<"debt_optimisations_to_action">> => [],
        %% PENDING — needs the loan amount (a property/Phase-B figure). §98: never LLM-set.
        <<"loan_cost_estimate_year_1">> => null
    },
    KbVersions = fh_engine_kb:kb_anchors(
        [<<"kb.lender.investment-loan-policies">>,
         <<"kb.lender.investor-friendly-shortlist">>,
         <<"kb.loan.interest-only-vs-pi-investor">>,
         <<"kb.loan.offset-vs-redraw-investor">>,
         <<"kb.loan.refinance-strategies-portfolio-growth">>,
         <<"kb.lender.hecs-treatment-by-lender">>,
         <<"kb.loan.fixed-rate-roll-off-planning">>,
         <<"kb.lender.serviceability-investment-loans">>]),
    {Outcome, <<"summary-card">>, KbVersions}.

%% the investor base loan-structure scaffold: the IO term default (KB convention) + the
%% four agent slots (null until merge_agent_investor/2). Mirrors loan_structure_base/0.
-spec loan_structure_investor_base() -> map().
loan_structure_investor_base() ->
    #{<<"repayment_type">> => null,              %% agent (io_vs_pi)
      <<"rate">> => null,                        %% agent (fixed_vs_variable)
      <<"offset">> => null,                      %% agent (offset strategy)
      <<"uses_existing_ppor_equity">> => null,   %% agent
      <<"interest_only_period_years">> =>
          kb_param(<<"kb.loan.interest-only-vs-pi-investor">>,
                   <<"io_max_term_years_typical">>)}.

%% the KB-grounded refinance framing true at base (plan-first, pre-property): the usable-
%% equity LVR conventions + the load-bearing serviceability-retest insight; the figures and
%% dates that need a settled property (usable equity $, expiry/release dates) are null.
-spec refinance_plan_base() -> map().
refinance_plan_base() ->
    Refi = <<"kb.loan.refinance-strategies-portfolio-growth">>,
    #{<<"usable_equity_target_lvr_pct">> =>
          kb_param(Refi, <<"usable_equity_target_lvr_pct">>),
      <<"usable_equity_with_lmi_lvr_pct">> =>
          kb_param(Refi, <<"usable_equity_with_lmi_lvr_pct">>),
      <<"equity_release_triggers_serviceability_retest">> =>
          kb_param(Refi, <<"equity_release_triggers_serviceability_retest">>),
      <<"interest_only_term_years_typical">> =>
          kb_param(<<"kb.loan.interest-only-vs-pi-investor">>,
                   <<"io_max_term_years_typical">>),
      %% PENDING — need a settled property + loan balance + settlement date.
      <<"usable_equity_estimate">> => null,
      <<"io_period_expiry_date">> => null,
      <<"next_property_equity_release_target_date">> => null}.

%% --- merge_agent (fold the two lender_fit leaves into the resolver outcome) --
%% AgentValues carries ONLY the two qualitative leaves the sidecar authored; the merge
%% is slot-scoped, so the LLM cannot author or overwrite any figure (the §98 property,
%% verifiable: every other field — capacity, path, optimisations — is byte-identical).

-spec merge_agent(map(), map()) -> map().
merge_agent(ResolverOutcome, AgentValues) ->
    %% RO-shape discriminator: only the investor mortgage_plan carries io_vs_pi_recommendation
    %% (the FHB outcome has recommended_path / loan_structure_recommendation). Local sniff —
    %% no signature change, mirrors the fill/2 + cash discriminators.
    case maps:is_key(<<"io_vs_pi_recommendation">>, ResolverOutcome) of
        true  -> merge_agent_investor(ResolverOutcome, AgentValues);
        false -> merge_agent_fhb(ResolverOutcome, AgentValues)
    end.

-spec merge_agent_fhb(map(), map()) -> map().
merge_agent_fhb(ResolverOutcome, AgentValues) ->
    Shortlist = maps:get(<<"recommended_lender_shortlist">>, AgentValues, []),
    Rate      = maps:get(<<"fixed_vs_variable">>, AgentValues, null),
    LS0 = maps:get(<<"loan_structure_recommendation">>, ResolverOutcome),
    ResolverOutcome#{
        <<"recommended_lender_shortlist">> => Shortlist,
        <<"loan_structure_recommendation">> => LS0#{<<"rate">> => Rate}
    }.

%% fold the FIVE investor lender_fit leaves into the resolver outcome. Slot-scoped (§98):
%% the agent authors only these qualitative slots; every figure (the refinance framing, the
%% null loan cost, the debt optimisations) is the resolver's and is left untouched. The io/PI
%% and offset choices are surfaced both as the top-level enum field AND inside the structure
%% object (place-don't-recompute — one agent value, two read positions).
-spec merge_agent_investor(map(), map()) -> map().
merge_agent_investor(ResolverOutcome, AgentValues) ->
    Shortlist = maps:get(<<"recommended_lender_shortlist">>, AgentValues, []),
    IoPi      = maps:get(<<"io_vs_pi_recommendation">>, AgentValues, null),
    Offset    = maps:get(<<"offset_strategy_recommendation">>, AgentValues, null),
    Rate      = maps:get(<<"fixed_vs_variable">>, AgentValues, null),
    UsesPpor  = maps:get(<<"uses_existing_ppor_equity">>, AgentValues, null),
    LS0 = maps:get(<<"recommended_loan_structure">>, ResolverOutcome),
    ResolverOutcome#{
        <<"recommended_lender_shortlist">> => Shortlist,
        <<"io_vs_pi_recommendation">> => IoPi,
        <<"offset_strategy_recommendation">> => Offset,
        <<"recommended_loan_structure">> => LS0#{
            <<"repayment_type">> => IoPi,
            <<"rate">> => Rate,
            <<"offset">> => Offset,
            <<"uses_existing_ppor_equity">> => UsesPpor
        }
    }.

%% The INVERSE of merge_agent/2: recover the agent-leaf VALUES (in the sidecar-reply
%% shape merge_agent/2 consumes) from a previously-committed outcome. A base_resolver
%% refresh re-runs the resolver half (fresh capacity from the current income facts) and
%% re-attaches these stored leaves through the SAME merge_agent/2 — so the only thing
%% that varies by turn kind is the SOURCE of the agent values (sidecar reply vs stored
%% snapshot), never the freshness of the resolver figures. The agent re-authors nothing
%% (§98); the qualitative leaves are preserved verbatim from the snapshot.
-spec agent_values_from_outcome(map()) -> map().
agent_values_from_outcome(Stored) ->
    case maps:is_key(<<"io_vs_pi_recommendation">>, Stored) of
        true  -> agent_values_from_outcome_investor(Stored);
        false -> agent_values_from_outcome_fhb(Stored)
    end.

-spec agent_values_from_outcome_fhb(map()) -> map().
agent_values_from_outcome_fhb(Stored) ->
    LS = maps:get(<<"loan_structure_recommendation">>, Stored, #{}),
    #{<<"recommended_lender_shortlist">> =>
          maps:get(<<"recommended_lender_shortlist">>, Stored, []),
      <<"fixed_vs_variable">> => maps:get(<<"rate">>, LS, null)}.

%% inverse of merge_agent_investor/2: recover the five investor leaves verbatim from a
%% stored outcome (the refresh round-trip — re-run the resolver, re-attach these). The
%% rate + uses_ppor_equity live inside recommended_loan_structure; the enums are top-level.
-spec agent_values_from_outcome_investor(map()) -> map().
agent_values_from_outcome_investor(Stored) ->
    LS = maps:get(<<"recommended_loan_structure">>, Stored, #{}),
    #{<<"recommended_lender_shortlist">> =>
          maps:get(<<"recommended_lender_shortlist">>, Stored, []),
      <<"io_vs_pi_recommendation">> =>
          maps:get(<<"io_vs_pi_recommendation">>, Stored, null),
      <<"offset_strategy_recommendation">> =>
          maps:get(<<"offset_strategy_recommendation">>, Stored, null),
      <<"fixed_vs_variable">> => maps:get(<<"rate">>, LS, null),
      <<"uses_existing_ppor_equity">> =>
          maps:get(<<"uses_existing_ppor_equity">>, LS, null)}.

%% --- structure (KB-grounded, determinate) -----------------------------------

%% FHG in the eligibility scheme_stack (by role, deposit_guarantee) → the recommended
%% path is the FHG-backed 5%-deposit, no-LMI loan. Else pending the deposit %.
-spec recommended_path(map()) -> binary() | null.
recommended_path(Stack) ->
    case has_fhg(Stack) of
        true  -> <<"fhg_backed">>;
        false -> null
    end.

%% detect the FHG in the eligibility scheme_stack by role (deposit_guarantee) — the
%% same projection ownership_planning uses (one decision, read from the outcome).
-spec has_fhg(map()) -> boolean().
has_fhg(Stack) ->
    Schemes = maps:get(<<"applicable_schemes">>, Stack, []),
    lists:any(fun(S) -> maps:get(<<"role">>, S, <<>>) =:= <<"deposit_guarantee">> end,
              Schemes).

%% Mode-A FHB default loan structure: P&I (blueprint constant). `rate` is the agent
%% leaf (null until merge_agent); offset is a refine-turn behavioural choice.
-spec loan_structure_base() -> map().
loan_structure_base() ->
    #{<<"type">> => <<"principal_and_interest">>,
      <<"rate">> => null,
      <<"offset">> => null}.

%% A generic, KB-grounded pre-approval action plan (process steps, not figures). The
%% 5%/3-month genuine-savings convention is pulled from the serviceability KB so there is
%% no magic literal; the user-facing copy is the bilingual {vi,en} template (kb.copy.mortgage)
%% interpolated by fh_engine_i18n:subst/2 — no Vietnamese literal in Erlang, no io:format ~s
%% (bilingual-content.md §3b). Informational/decision-support, not advice.
-spec pre_approval_action_plan() -> [fh_engine_i18n:localized()].
pre_approval_action_plan() ->
    Pct    = kb_param(?SERVICEABILITY, <<"genuine_savings_min_pct">>),
    Months = kb_param(?SERVICEABILITY, <<"genuine_savings_min_months">>),
    [ copy(<<"action_genuine_savings">>, #{<<"pct">> => Pct, <<"months">> => Months}),
      copy(<<"action_income_evidence">>, #{}),
      copy(<<"action_list_debts">>, #{}),
      copy(<<"action_compare_panel">>, #{}) ].

%% key_assumptions: the one regulated constant (the buffer) plus the conventions that
%% shape capacity, each flagged as a convention (not this buyer's actual lender policy),
%% and the honest-partial note that capacity is pending the income/debt facts. Bilingual
%% via kb.copy.mortgage; only the buffer figure is interpolated.
-spec key_assumptions(number(), boolean()) -> [fh_engine_i18n:localized()].
key_assumptions(BufferPp, HasFhg) ->
    Base = [ copy(<<"assume_buffer">>, #{<<"buffer_pp">> => BufferPp}),
             copy(<<"assume_conventions">>, #{}),
             copy(<<"assume_pending">>, #{}) ],
    case HasFhg of
        true  -> [copy(<<"assume_fhg">>, #{}) | Base];
        false -> Base
    end.

%% subst a kb.copy.mortgage template into a bilingual {vi,en} value.
-spec copy(binary(), #{binary() => fh_engine_i18n:param()}) -> fh_engine_i18n:localized().
copy(Id, Params) ->
    fh_engine_i18n:subst(fh_engine_kb:copy(?COPY, Id), Params).

%% --- borrowing capacity (the serviceability resolver) -----------------------
%% §98: a compliance-sensitive figure — banded, KB-grounded, resolver-computed,
%% NEVER LLM-authored ([[no-judge-ground-the-producer]]). Reads the buyer_profile
%% outcome's framed income/debt facts (profile holds facts; mortgage reasons —
%% CLAUDE.md, no debt data in mortgage's own params). null until assessable_income
%% is known (honest-partial — income/debts arrive on a refine turn, IC3).
%%
%% The band reflects the genuinely-uncertain inputs (the HEM living-expenses band,
%% PLACEHOLDER; the credit-card repayment band); tax / Medicare / APRA buffer / HECS
%% are verifiable regulated constants ([[verify-regulated-figures-by-postcondition]]).
%% Surplus = net income − living expenses − debt commitments; capacity = PV of that
%% surplus over the term at (representative rate + buffer); capped by the DTI ceiling.

-spec borrowing_capacity(map()) -> [integer()] | null.
borrowing_capacity(Profile) ->
    case assessable_income(Profile) of
        Income when is_number(Income), Income > 0 ->
            capacity_band(Income, maps:get(<<"debts">>, Profile, #{}));
        _ -> null
    end.

%% the buyer_profile outcome frames assessable_income (shaded combined income); null
%% at base (no income captured) → capacity PENDING.
assessable_income(Profile) ->
    case maps:get(<<"assessable_income">>, Profile, null) of
        I when is_number(I) -> I;
        _ -> null
    end.

capacity_band(Income, Debts) ->
    NetM   = net_annual_income(Income) / 12,
    HecsM  = hecs_monthly(Income, Debts),
    {CardLoM, CardHiM} = card_monthly_band(Debts),
    OtherM = other_loan_monthly(Debts),
    HemLo  = sparam(?HEM, <<"monthly_living_expenses_low">>),
    HemHi  = sparam(?HEM, <<"monthly_living_expenses_high">>),
    %% low expenses + low card repayment → MAX surplus → UPPER capacity bound; the
    %% high ends give the conservative LOWER bound. The band IS the surfaced uncertainty.
    SurplusHi = NetM - HemLo - HecsM - CardLoM - OtherM,
    SurplusLo = NetM - HemHi - HecsM - CardHiM - OtherM,
    PVF    = pv_factor(),
    DtiCap = dti_ceiling(Income, Debts),
    CapHi  = min(max(0.0, SurplusHi) * PVF, DtiCap),
    CapLo  = min(max(0.0, SurplusLo) * PVF, DtiCap),
    [round(CapLo), round(CapHi)].

%% net income: gross − income tax − Medicare (BEFORE HECS — HECS is counted as a
%% commitment in the surplus, not double-subtracted here).
-spec net_annual_income(number()) -> number().
net_annual_income(Income) ->
    Income - income_tax(Income) - medicare_levy(Income).

medicare_levy(Income) ->
    Income * sparam(?TAX, <<"medicare_levy_pct">>) / 100.

%% income tax from the 2025-26 resident marginal schedule (kb.tax lookup).
-spec income_tax(number()) -> number().
income_tax(Income) ->
    case find_band(Income, lookup_entries(?TAX, <<"resident_rates_2025_26">>)) of
        none -> 0;
        B    -> num(maps:get(<<"base_amount">>, B, 0))
                + num(maps:get(<<"marginal_rate_pct">>, B, 0)) / 100
                  * (Income - num(maps:get(<<"marginal_over">>, B, 0)))
    end.

%% the marginal tax rate (%) on the next dollar of income, INCLUDING the Medicare levy —
%% the rate at which a rental loss is refunded (negative gearing) and a discounted capital
%% gain is taxed (CGT). The 2025-26 resident bracket marginal rate + the 2% Medicare levy
%% (applied above the low-income phase-in; 0 below it, where the levy phases out and the
%% refund is immaterial). Schedule indexing stays in the one module that owns the TAX anchor
%% (kb.tax.income-tax-resident-2025-26); tax_structure / disposition read this, never re-index.
-spec marginal_rate(number()) -> number().
marginal_rate(Income) when is_number(Income) ->
    Bracket = case find_band(Income, lookup_entries(?TAX, <<"resident_rates_2025_26">>)) of
                  none -> 0;
                  B    -> num(maps:get(<<"marginal_rate_pct">>, B, 0))
              end,
    Medicare = case Income > sparam(?TAX, <<"medicare_low_income_single_threshold">>) of
                   true  -> sparam(?TAX, <<"medicare_levy_pct">>);
                   false -> 0
               end,
    Bracket + Medicare.

%% HECS compulsory repayment from the income-contingent schedule (kb.hecs lookup);
%% included only when a balance exists (the drag scales with income, not balance).
hecs_monthly(Income, Debts) ->
    case num0(maps:get(<<"hecs_balance">>, Debts, 0)) of
        Bal when Bal > 0 -> hecs_repayment(Income) / 12;
        _                -> 0
    end.

-spec hecs_repayment(number()) -> number().
hecs_repayment(Income) ->
    case find_band(Income, lookup_entries(?HECS, <<"repayment_schedule_2025_26">>)) of
        none -> 0;
        B ->
            case maps:get(<<"flat_rate_of_total_pct">>, B, undefined) of
                undefined ->
                    num(maps:get(<<"base_amount">>, B, 0))
                    + num(maps:get(<<"marginal_rate_pct">>, B, 0)) / 100
                      * (Income - num(maps:get(<<"marginal_over">>, B, 0)));
                Flat -> num(Flat) / 100 * Income
            end
    end.

%% credit cards: assessed on the LIMIT, banded by the assumed monthly repayment %.
card_monthly_band(Debts) ->
    Limit = num0(maps:get(<<"credit_card_limits_total">>, Debts, 0)),
    Lo = sparam(?CARD, <<"assumed_monthly_repayment_pct_of_limit_low">>),
    Hi = sparam(?CARD, <<"assumed_monthly_repayment_pct_of_limit_high">>),
    {Limit * Lo / 100, Limit * Hi / 100}.

%% personal / car / BNPL balances → a monthly commitment via the labelled convention.
other_loan_monthly(Debts) ->
    Bal = num0(maps:get(<<"personal_loans_balance">>, Debts, 0))
        + num0(maps:get(<<"car_loan_balance">>, Debts, 0))
        + num0(maps:get(<<"buy_now_pay_later_balance">>, Debts, 0)),
    Bal * sparam(?SERVICEABILITY, <<"consumer_loan_monthly_repayment_pct_of_balance">>) / 100.

%% the present-value annuity factor at (representative product rate + APRA buffer).
pv_factor() ->
    R = (sparam(?SERVICEABILITY, <<"representative_product_rate_pct">>)
         + sparam(?SERVICEABILITY, <<"apra_serviceability_buffer_pp">>)) / 100 / 12,
    N = sparam(?SERVICEABILITY, <<"loan_term_years">>) * 12,
    (1 - math:pow(1 + R, -N)) / R.

%% APRA high-DTI ceiling: new lending capped so total debt ≤ 6× gross income. HECS is
%% income-contingent (not a balance-debt here), so only hard consumer balances count.
dti_ceiling(Income, Debts) ->
    Existing = num0(maps:get(<<"credit_card_limits_total">>, Debts, 0))
             + num0(maps:get(<<"personal_loans_balance">>, Debts, 0))
             + num0(maps:get(<<"car_loan_balance">>, Debts, 0))
             + num0(maps:get(<<"buy_now_pay_later_balance">>, Debts, 0)),
    max(0.0, sparam(?SERVICEABILITY, <<"high_dti_threshold">>) * Income - Existing).

%% --- KB access (matches fh_engine_ownership / fh_engine_cash) ----------------

%% a numeric KB parameter value.
sparam(Slug, Key) -> num(kb_param(Slug, Key)).

%% the ordered entries of a KB lookup table.
lookup_entries(Slug, Table) ->
    {ok, Cj} = fh_engine_kb:kb_rules(Slug),
    Lookup = maps:get(<<"lookup">>, Cj),
    maps:get(<<"entries">>, maps:get(Table, Lookup)).

%% the applicable marginal band: the last (highest income_from) whose floor ≤ income.
%% Entries are authored ascending, so the last eligible is the active band.
find_band(Income, Bands) ->
    case [B || B <- Bands, num(maps:get(<<"income_from">>, B)) =< Income] of
        []       -> none;
        Eligible -> lists:last(Eligible)
    end.

num(N) when is_number(N) -> N.
num0(N) when is_number(N) -> N;
num0(_)                   -> 0.

buffer_pp() ->
    kb_param(?SERVICEABILITY, <<"apra_serviceability_buffer_pp">>).

kb_param(Slug, Key) ->
    {ok, Cj} = fh_engine_kb:kb_rules(Slug),
    Params = maps:get(<<"parameters">>, Cj),
    maps:get(<<"value">>, maps:get(Key, Params)).
