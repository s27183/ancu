-module(fh_engine_mortgage).

%% The base-turn `mortgage_finance` fill — the RESOLVER half of a TWO-PATH component
%% (mortgage-finance-two-path.md). It assembles the `mortgage_plan` outcome's figures
%% and loan-path structure deterministically; the `lender_fit` leaves are left `null`
%% for the agent and folded in by merge_agent/2 after the sidecar replies.
%%
%% FOUR VARIANTS, shared component NAME (`mortgage_finance`): the Mode-A FHB path
%% (fill_fhb/2, two leaves: shortlist + rate), the Mode-B foreign-person path
%% (fill_fhb_foreign/2, two leaves: shortlist + rate — a DIFFERENT `mortgage_plan` shape,
%% blueprint fhb-foreign-au.md component 5, mode-b-wedge.md P2 slice 3), the Mode-C
%% domestic-investor path (fill_investor/2, five leaves: io/PI, rate, offset strategy,
%% uses_existing_ppor_equity, investor lender shortlist), and the Mode-D non-resident-investor
%% path (fill_investor_foreign/2, THREE leaves: io/PI, rate, non-resident lender shortlist —
%% no offset/PPOR-equity leaves, reconciled 2026-07-05: Mode D has no AU PPOR to release
%% equity from or point an offset at, see mode-d-wedge.md). fill/2 routes FIRST on the
%% `strategy_thesis` upstream (investor-only, unchanged), THEN — orthogonally, within the
%% non-investor path — on Args.firb_required_any (the SAME flag fh_engine_fill:buyer_profile/1
%% and the compliance FIRB gate key on). merge_agent/2 + agent_values_from_outcome/1 route on
%% the 2x2 `io_vs_pi_recommendation` (investor axis: C or D) x `firb_dependency_acknowledged`
%% (foreign axis: B or D) outcome keys. All discriminators are local shape/context sniffs —
%% no signature change, the FHB body is byte-identical (zero regression). Mirrors
%% fh_engine_cash / fh_engine_disposition (investor axis) and fh_engine_fill:buyer_profile/1
%% (foreign axis).
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
%% exported for the Mode-D non-resident-investor conformance suite:
-export([fill_investor_foreign/2, rate_estimate_foreign/0, deposit_pct_foreign/0]).
%% exported for cross-language conformance (tests/mortgage_eval.py mirrors these):
-export([recommended_path/1, has_fhg/1, loan_structure_base/0, key_assumptions/2,
         pre_approval_action_plan/0]).
%% exported for the Mode-B foreign-person conformance suite:
-export([recommended_path_foreign/1, deposit_required/1, loan_structure_base_foreign/0,
         pre_approval_action_plan_foreign/0]).
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
        true  ->
            case maps:get(firb_required_any, Args, false) of
                true  -> fill_investor_foreign(Args, Upstream);
                false -> fill_investor(Args, Upstream)
            end;
        false ->
            case maps:get(firb_required_any, Args, false) of
                true  -> fill_fhb_foreign(Args, Upstream);
                false -> fill_fhb(Args, Upstream)
            end
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

%% --- fill_fhb_foreign (resolver half, Mode-B foreign-person mortgage_plan) --
%% The Mode-B `mortgage_plan` is a DIFFERENT seven-field shape from Mode A's nine (no
%% debt_optimisations_to_action / pre_approval_expiry / reapplication_required / key_
%% assumptions; adds deposit_required + firb_dependency_acknowledged — blueprint
%% fhb-foreign-au.md component 5). borrowing_capacity/1 is REUSED unchanged (it already
%% honestly PENDs on profile.assessable_income, which buyer_profile_foreign also leaves
%% null at base — no foreign-income-shading enhancement needed yet since there is no
%% income to shade until a refine turn). recommended_lender_shortlist is the ONE agent
%% slot (reasoning over kb.lender.non-resident-friendly-shortlist's ACL-safe criteria —
%% the doc's own Notes: "the agent produces the shortlist by reasoning over these
%% criteria"), folded by merge_agent_fhb_foreign/2.
-spec fill_fhb_foreign(map(), map()) -> {map(), binary(), [map()]}.
fill_fhb_foreign(_Args, Upstream) ->
    Profile = maps:get(<<"profile">>, Upstream, #{}),
    Ceiling = ceiling(maps:get(<<"target_price_range">>, Profile, null)),
    Outcome = #{
        <<"recommended_path">> => recommended_path_foreign(Profile),
        <<"expected_borrowing_capacity">> => borrowing_capacity(Profile),
        <<"deposit_required">> => deposit_required(Ceiling),
        %% AGENT slot (lender_fit) — filled by merge_agent_fhb_foreign/2.
        <<"recommended_lender_shortlist">> => null,
        %% Mode B is ALWAYS FIRB-dependent (kb.lender.firb-approval-as-condition-precedent)
        %% — definitional, mirrors buyer_profile_foreign's firb_required=true.
        <<"firb_dependency_acknowledged">> => true,
        <<"loan_structure_recommendation">> => loan_structure_base_foreign(),
        <<"pre_approval_action_plan">> => pre_approval_action_plan_foreign()
    },
    KbVersions = fh_engine_kb:kb_anchors(
        [<<"kb.lender.non-resident-friendly-shortlist">>,
         <<"kb.lender.temp-resident-lending-policies">>,
         <<"kb.lender.485-visa-treatment">>,
         <<"kb.lender.foreign-buyer-deposit-requirements">>,
         <<"kb.lender.firb-approval-as-condition-precedent">>,
         <<"kb.lender.documentation-non-resident">>,
         <<"kb.fx.loan-currency-considerations">>]),
    {Outcome, <<"summary-card">>, KbVersions}.

%% kb.lender.485-visa-treatment: "path_applicable_when_au_income" — a temp resident
%% earning AUD employment income in Australia is assessed near-domestic. The TRUE test
%% is income CURRENCY, not the visa label alone (kb.lender.temp-resident-lending-policies:
%% assessment_axis_is_income_currency_not_visa) — but income facts are honestly PENDING
%% at base (buyer_profile_foreign), so this is a base-turn VISA-class proxy for the
%% AU-income-eligible set, refined once income_assessment_currency is knowable. Every
%% applicant unset (base default) -> undetermined (null), not a guess.
-spec recommended_path_foreign(map()) -> binary() | null.
recommended_path_foreign(Profile) ->
    Applicants = maps:get(<<"applicants">>, Profile, []),
    VisaClasses = [maps:get(<<"visa_class">>, A, null) || A <- Applicants],
    AuIncomeEligibleVisas = [<<"graduate_485">>, <<"student_500">>, <<"skilled_482">>,
                              <<"skilled_186">>, <<"spouse_309">>, <<"spouse_820">>],
    case lists:any(fun(V) -> lists:member(V, AuIncomeEligibleVisas) end, VisaClasses) of
        true  -> <<"temp_resident_with_au_income">>;
        false ->
            case lists:all(fun(V) -> V =:= null end, VisaClasses) of
                true  -> null;                          %% no visa captured yet
                false -> <<"standard_non_resident">>     %% a known, non-AU-income visa
            end
    end.

%% conservative base estimate: the typical non-resident deposit % (kb.lender.foreign-
%% buyer-deposit-requirements) against the conservative upper bound of
%% profile.target_price_range. Refines once the path/visa is known — a 485-with-AU-income
%% or joint-AU-partner path lowers this materially (kb.lender.485-visa-treatment /
%% foreign-buyer-deposit-requirements own the lower bands; not asserted here at base).
-spec deposit_required(integer() | null) -> integer() | null.
deposit_required(null) -> null;
deposit_required(Ceiling) ->
    Pct = sparam(<<"kb.lender.foreign-buyer-deposit-requirements">>,
                 <<"non_resident_deposit_pct_typical">>),
    round(Ceiling * Pct / 100).

%% Mode B FHB default: P&I (owner-occupier intent, blueprint constant) and AUD-
%% denominated — the loan is NEVER foreign-currency (kb.fx.loan-currency-considerations:
%% loan_currency_is_always_aud, fixed not a choice). `rate` is the agent leaf.
-spec loan_structure_base_foreign() -> map().
loan_structure_base_foreign() ->
    #{<<"type">> => <<"principal_and_interest">>,
      <<"currency">> => loan_currency(),
      <<"rate">> => null}.

loan_currency() ->
    true = kb_param(<<"kb.fx.loan-currency-considerations">>,
                     <<"loan_currency_is_always_aud">>),
    <<"AUD">>.

%% a KB-grounded, foreign-person-tuned action plan (process steps, not figures) — the
%% Mode-B mirror of pre_approval_action_plan/0. Bilingual via kb.copy.mortgage
%% (fh_engine_i18n:subst/2 — no Vietnamese literal, no io:format ~s). Informational/
%% decision-support, never advice (ASIC / ACL — kb.lender.non-resident-friendly-shortlist).
-spec pre_approval_action_plan_foreign() -> [fh_engine_i18n:localized()].
pre_approval_action_plan_foreign() ->
    Pct = kb_param(<<"kb.lender.foreign-buyer-deposit-requirements">>,
                   <<"non_resident_deposit_pct_typical">>),
    [ copy(<<"action_gather_visa_and_documents">>, #{}),
      copy(<<"action_start_firb_in_parallel">>, #{}),
      copy(<<"action_source_of_funds_evidence">>, #{}),
      copy(<<"action_understand_deposit_convention">>, #{<<"pct">> => Pct}),
      copy(<<"action_compare_non_resident_lenders">>, #{}) ].

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

%% --- fill_investor_foreign (resolver half, Mode-D non-resident-investor mortgage_plan) --
%% The Mode-D `mortgage_plan` (10 fields, investor-foreign-au.md component 5) — a FOURTH,
%% different shape from Mode A's/B's/C's, dispatched by the SAME strategy_thesis-presence
%% + firb_required_any compound discriminator fill/2 already uses. `recommended_lender_shortlist`
%% is the SAME shortlist shape Mode C's mortgage_plan uses (reconciled 2026-07-04 — the
%% blueprint originally drafted a singular `recommended_lender` top-pick string, which
%% collapsed the agent's lender_fit judgment to one named lender with no visible
%% alternative, the exact pattern CLAUDE.md's ACL/credit-advice guardrail warns against;
%% every other mode already surfaces a shortlist the user compares and picks from) —
%% agent-authored (folded by merge_agent_investor_foreign/2 below); `io_vs_pi_recommendation`
%% is the SAME agent leaf Mode C uses (reasoning_domain lender_fit).
%%
%% §98: `rate_estimate` (percentage_range) is a NUMERIC figure — never the agent's rate-
%% STRUCTURE enum the way Mode A/B/C's `loan_structure_recommendation.rate` is. It is
%% resolver-computed from KB conventions (representative product rate + the domestic-
%% investor premium + the non-resident-investment combination's own further premium band,
%% kb.lender.non-resident-investment-loan-shortlist — flagged as an indicative CONVENTION,
%% not a live quote) — removed from the LLM's reach, same discipline as every other rate/
%% capacity figure in this module. `expected_borrowing_capacity` reuses borrowing_capacity/1
%% UNCHANGED (honest-partial: no non-resident income-tax-bracket KB table exists yet, and no
%% income is captured at base regardless — same deferral tax_structure_non_resident makes).
%% `vn_income_acceptance_confirmed` / `fx_risk_acknowledged` are USER-confirmation states,
%% honestly false until a refine turn confirms them — never asserted true by the resolver.
-spec fill_investor_foreign(map(), map()) -> {map(), binary(), [map()]}.
fill_investor_foreign(_Args, Upstream) ->
    Profile = maps:get(<<"profile">>, Upstream, #{}),
    Ceiling = ceiling(maps:get(<<"target_price_range">>, Profile, null)),
    DepositPct = deposit_pct_foreign(),
    Outcome = #{
        %% AGENT slots (lender_fit) — filled by merge_agent_investor_foreign/2. Three, not
        %% Mode C's five: no offset/PPOR-equity leaves (Mode D has no AU PPOR) — reconciled
        %% 2026-07-05, see LenderFitNonResidentInvestorLeaves in planner.py.
        <<"recommended_lender_shortlist">> => null,
        <<"io_vs_pi_recommendation">> => null,
        <<"fixed_vs_variable">> => null,
        <<"expected_borrowing_capacity">> => borrowing_capacity(Profile),
        <<"deposit_required_percentage">> => DepositPct,
        <<"deposit_required_amount">> => deposit_amount_foreign(Ceiling, DepositPct),
        <<"rate_estimate">> => rate_estimate_foreign(),
        %% Mode D is ALWAYS FIRB-dependent (kb.lender.firb-approval-as-condition-precedent) —
        %% definitional, mirrors buyer_profile_foreign's / fill_fhb_foreign's firb_required=true.
        <<"firb_dependency_acknowledged">> => true,
        <<"vn_income_acceptance_confirmed">> => false,
        <<"fx_risk_acknowledged">> => false,
        %% PENDING — needs the loan amount (a property/Phase-B figure). §98: never LLM-set.
        <<"loan_cost_estimate_year_1">> => null
    },
    KbVersions = fh_engine_kb:kb_anchors(
        [<<"kb.lender.non-resident-investment-loan-shortlist">>,
         <<"kb.non-resident.investment-loan-deposit-requirements">>,
         <<"kb.lender.temp-resident-lending-policies">>,
         <<"kb.loan.interest-only-vs-pi-investor">>,
         <<"kb.lender.firb-approval-as-condition-precedent">>,
         <<"kb.fx.loan-currency-considerations">>]),
    {Outcome, <<"summary-card">>, KbVersions}.

%% the non-resident-investment deposit % (kb.non-resident.investment-loan-deposit-requirements):
%% midpoint of the 30-40% band — matches the blueprint's own stated default (35).
-spec deposit_pct_foreign() -> number().
deposit_pct_foreign() ->
    Slug = <<"kb.non-resident.investment-loan-deposit-requirements">>,
    Lo = kb_param(Slug, <<"non_resident_investment_deposit_pct_low">>),
    Hi = kb_param(Slug, <<"non_resident_investment_deposit_pct_high">>),
    (Lo + Hi) / 2.

-spec deposit_amount_foreign(integer() | null, number()) -> integer() | null.
deposit_amount_foreign(null, _Pct) -> null;
deposit_amount_foreign(Ceiling, Pct) -> round(Ceiling * Pct / 100).

%% domestic-investor rate + the non-resident-investment combination's further premium band
%% (kb.lender.non-resident-investment-loan-shortlist, ~100-200bp, flagged CONVENTION —
%% "not independently primary-verified this pass" per the doc's own Notes).
-spec rate_estimate_foreign() -> [number()].
rate_estimate_foreign() ->
    Base = kb_param(?SERVICEABILITY, <<"representative_product_rate_pct">>)
         + kb_param(<<"kb.lender.serviceability-investment-loans">>, <<"investment_rate_premium_pp">>),
    Slug = <<"kb.lender.non-resident-investment-loan-shortlist">>,
    LowBp  = kb_param(Slug, <<"rate_premium_above_domestic_investor_bp_low">>),
    HighBp = kb_param(Slug, <<"rate_premium_above_domestic_investor_bp_high">>),
    [round1(Base + LowBp / 100), round1(Base + HighBp / 100)].

round1(X) -> round(X * 10) / 10.

%% --- merge_agent (fold the two lender_fit leaves into the resolver outcome) --
%% AgentValues carries ONLY the two qualitative leaves the sidecar authored; the merge
%% is slot-scoped, so the LLM cannot author or overwrite any figure (the §98 property,
%% verifiable: every other field — capacity, path, optimisations — is byte-identical).

-spec merge_agent(map(), map()) -> map().
merge_agent(ResolverOutcome, AgentValues) ->
    %% RO-shape discriminator, a 2x2 over two independent axis flags (mirrors fh_engine_cash's
    %% compound investor+foreign dispatch): io_vs_pi_recommendation marks the investor axis
    %% (Mode C or D); firb_dependency_acknowledged marks the foreign axis (Mode B or D). The
    %% Mode-A FHB outcome carries neither. Local sniff — no signature change.
    HasIoPi = maps:is_key(<<"io_vs_pi_recommendation">>, ResolverOutcome),
    HasFirb = maps:is_key(<<"firb_dependency_acknowledged">>, ResolverOutcome),
    case {HasIoPi, HasFirb} of
        {true,  true}  -> merge_agent_investor_foreign(ResolverOutcome, AgentValues);
        {true,  false} -> merge_agent_investor(ResolverOutcome, AgentValues);
        {false, true}  -> merge_agent_fhb_foreign(ResolverOutcome, AgentValues);
        {false, false} -> merge_agent_fhb(ResolverOutcome, AgentValues)
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

%% Mode-B mirror of merge_agent_fhb/2 — identical two-leaf shape (shortlist + rate), a
%% distinct function paired with the firb_dependency_acknowledged discriminator so the
%% outcome TYPE (Mode A vs Mode B mortgage_plan) stays legible at the call site, even
%% though the fold logic is the same.
-spec merge_agent_fhb_foreign(map(), map()) -> map().
merge_agent_fhb_foreign(ResolverOutcome, AgentValues) ->
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

%% fold the THREE Mode-D agent leaves (recommended_lender_shortlist: the SAME shortlist
%% shape + fold as Mode C's merge_agent_investor/2 — reconciled 2026-07-04, was a singular
%% top-pick string that collapsed the agent's judgment to one named lender, the ACL-line
%% pattern CLAUDE.md's guardrail warns against; io_vs_pi_recommendation: the same
%% lender_fit leaf Mode C uses; fixed_vs_variable: reconciled 2026-07-05 — was already a
%% Mode-D blueprint Parameter and already computed by the shared Python leaf-fill, but was
%% silently discarded here, see mode-d-wedge.md). Deliberately only THREE, not Mode C's
%% five — merge_agent_investor/2's offset_strategy_recommendation + uses_existing_ppor_equity
%% presume an AU PPOR this investor does not have, so Mode D's OWN Python schema
%% (LenderFitNonResidentInvestorLeaves) never authors them; there is nothing to fold. Slot-
%% scoped (§98): every figure (capacity, deposit, rate_estimate, the firb/vn/fx acknowledgement
%% flags) is the resolver's, untouched.
-spec merge_agent_investor_foreign(map(), map()) -> map().
merge_agent_investor_foreign(ResolverOutcome, AgentValues) ->
    ResolverOutcome#{
        <<"recommended_lender_shortlist">> =>
            maps:get(<<"recommended_lender_shortlist">>, AgentValues, []),
        <<"io_vs_pi_recommendation">> => maps:get(<<"io_vs_pi_recommendation">>, AgentValues, null),
        <<"fixed_vs_variable">> => maps:get(<<"fixed_vs_variable">>, AgentValues, null)
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
    %% same 2x2 compound discriminator as merge_agent/2 — see that function's comment.
    HasIoPi = maps:is_key(<<"io_vs_pi_recommendation">>, Stored),
    HasFirb = maps:is_key(<<"firb_dependency_acknowledged">>, Stored),
    case {HasIoPi, HasFirb} of
        {true,  true}  -> agent_values_from_outcome_investor_foreign(Stored);
        {true,  false} -> agent_values_from_outcome_investor(Stored);
        {false, true}  -> agent_values_from_outcome_fhb_foreign(Stored);
        {false, false} -> agent_values_from_outcome_fhb(Stored)
    end.

-spec agent_values_from_outcome_fhb(map()) -> map().
agent_values_from_outcome_fhb(Stored) ->
    LS = maps:get(<<"loan_structure_recommendation">>, Stored, #{}),
    #{<<"recommended_lender_shortlist">> =>
          maps:get(<<"recommended_lender_shortlist">>, Stored, []),
      <<"fixed_vs_variable">> => maps:get(<<"rate">>, LS, null)}.

%% Mode-B mirror of agent_values_from_outcome_fhb/1 — identical shape, distinct function
%% paired with the firb_dependency_acknowledged discriminator (see merge_agent_fhb_foreign/2).
-spec agent_values_from_outcome_fhb_foreign(map()) -> map().
agent_values_from_outcome_fhb_foreign(Stored) ->
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

%% inverse of merge_agent_investor_foreign/2: recover the three Mode-D leaves verbatim
%% (all top-level, no nested loan_structure wrapper — Mode D's own outcome shape).
-spec agent_values_from_outcome_investor_foreign(map()) -> map().
agent_values_from_outcome_investor_foreign(Stored) ->
    #{<<"recommended_lender_shortlist">> =>
          maps:get(<<"recommended_lender_shortlist">>, Stored, []),
      <<"io_vs_pi_recommendation">> =>
          maps:get(<<"io_vs_pi_recommendation">>, Stored, null),
      <<"fixed_vs_variable">> =>
          maps:get(<<"fixed_vs_variable">>, Stored, null)}.

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

%% the conservative upper bound of a [Lo, Hi] target-price-range fact (no property yet).
%% Mirrors fh_engine_ownership:ceiling/1 / fh_engine_firb:ceiling/1.
ceiling([_Lo, Hi]) when is_integer(Hi) -> Hi;
ceiling(_)                             -> null.

buffer_pp() ->
    kb_param(?SERVICEABILITY, <<"apra_serviceability_buffer_pp">>).

kb_param(Slug, Key) ->
    {ok, Cj} = fh_engine_kb:kb_rules(Slug),
    Params = maps:get(<<"parameters">>, Cj),
    maps:get(<<"value">>, maps:get(Key, Params)).
