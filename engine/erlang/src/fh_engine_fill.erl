-module(fh_engine_fill).

%% Resolver fills — the deterministic, Erlang-side, in-process component fills
%% (agentic-boundary.md: resolver path; fill_path: resolver, no sidecar, no usage).
%% The turn's gen_statem (fh_engine_turn) walks the base DAG and calls resolver/3
%% for every component whose `agent_leaves` is empty.
%%
%% fill(ComponentName, Args, Upstream) -> {Outcome, Renderer, KbVersions}
%%   Args     :: the turn Args (carries `onboarding` — the create-plan-card inputs)
%%   Upstream :: #{OutcomeType => Outcome} accumulated from already-filled components
%%   Outcome  :: the component's typed outcome (a binary-keyed map)
%%
%% STATUS: all four base resolver components are REAL fills. `buyer_profile` projects
%% the onboarding fact base into the `profile` outcome and derives per-applicant FIRB
%% via fh_engine_resolver (§11.9 applicant.* semantics); `eligibility`
%% (fh_engine_eligibility) is the three-valued banded scheme_stack; `cash_position`
%% (fh_engine_cash) and `ownership_planning` (fh_engine_ownership) are mechanism-(B)
%% formula code over the KB tables (stamp-duty brackets / ongoing-cost bands). The Mode-C
%% investor variants reuse the same modules by name: `ownership_planning_investor` →
%% fh_engine_ownership:fill_investor/2 (a clean sibling — unique name, FHB fill/2 untouched).

-export([resolver/3, has_resolver/1, merge_agent/3, agent_values_from_outcome/2]).

-define(COPY, <<"kb.copy.profile">>).   %% buyer_profile bilingual copy-templates (bilingual-content.md §3b)

%% Does this component have a resolver fill? Empty `agent_leaves` → pure resolver;
%% non-empty + has_resolver → TWO-PATH (the turn runs the resolver, then folds the
%% agent leaves via merge_agent/3); non-empty + no resolver → pure agent (the sidecar
%% fills the whole outcome — the later per-property valuation/negotiation components).
-spec has_resolver(binary()) -> boolean().
has_resolver(<<"buyer_profile">>)      -> true;
has_resolver(<<"investor_profile">>)   -> true;
has_resolver(<<"eligibility">>)        -> true;
has_resolver(<<"cash_position">>)      -> true;
has_resolver(<<"ownership_planning">>) -> true;
has_resolver(<<"ownership_planning_investor">>) -> true;
has_resolver(<<"mortgage_finance">>)   -> true;
has_resolver(<<"investment_strategy">>) -> true;
has_resolver(<<"yield_modelling">>)    -> true;
has_resolver(<<"tax_structure">>)      -> true;
has_resolver(<<"property_assessment">>) -> true;
has_resolver(<<"purchase_journey">>)   -> true;
has_resolver(<<"preparation">>)        -> true;
has_resolver(<<"phase_playbook">>)     -> true;
has_resolver(<<"disposition">>)        -> true;
has_resolver(_)                        -> false.

-spec resolver(binary(), map(), map()) -> {map(), binary(), [map()]}.
resolver(<<"buyer_profile">>, Args, _Upstream) ->
    buyer_profile(Args);
resolver(<<"investor_profile">>, Args, _Upstream) ->
    investor_profile(Args);
resolver(<<"eligibility">>, Args, Upstream) ->
    fh_engine_eligibility:fill(Args, Upstream);
resolver(<<"cash_position">>, Args, Upstream) ->
    fh_engine_cash:fill(Args, Upstream);
resolver(<<"ownership_planning">>, Args, Upstream) ->
    fh_engine_ownership:fill(Args, Upstream);
resolver(<<"ownership_planning_investor">>, Args, Upstream) ->
    fh_engine_ownership:fill_investor(Args, Upstream);
resolver(<<"mortgage_finance">>, Args, Upstream) ->
    fh_engine_mortgage:fill(Args, Upstream);
resolver(<<"investment_strategy">>, _Args, Upstream) ->
    investment_strategy(Upstream);
resolver(<<"yield_modelling">>, _Args, Upstream) ->
    yield_modelling(Upstream);
resolver(<<"tax_structure">>, _Args, Upstream) ->
    tax_structure(Upstream);
resolver(<<"property_assessment">>, Data, _Upstream) ->
    property_assessment(maps:get(property_card, Data, #{}));
resolver(<<"purchase_journey">>, Args, Upstream) ->
    fh_engine_journey:fill(Args, Upstream);
resolver(<<"preparation">>, Args, Upstream) ->
    fh_engine_preparation:fill(Args, Upstream);
resolver(<<"phase_playbook">>, Args, Upstream) ->
    fh_engine_phase_playbook:fill(Args, Upstream);
resolver(<<"disposition">>, Args, Upstream) ->
    fh_engine_disposition:fill(Args, Upstream);
resolver(Other, _Args, _Upstream) ->
    erlang:error({no_resolver_fill_for, Other}).

%% Fold a two-path component's agent leaves (from the sidecar reply) into the outcome
%% the resolver assembled. The component module owns the slot mapping (it knows its own
%% outcome shape); the merge is slot-scoped so the agent cannot move a figure (§98).
-spec merge_agent(binary(), map(), map()) -> map().
merge_agent(<<"mortgage_finance">>, ResolverOutcome, AgentValues) ->
    fh_engine_mortgage:merge_agent(ResolverOutcome, AgentValues);
%% investment_strategy: the three investment_thesis leaves the sidecar authored
%% (archetype, gearing_type, one_liner). Slot-scoped fold — the agent reach is exactly
%% these three judgment fields; every other strategy_thesis field (the property-relative
%% targets, the alignment verdict, the carried horizon) is the resolver scaffold's and is
%% left untouched (the agent authors NO figure, NO verdict — the §98 property here too).
merge_agent(<<"investment_strategy">>, ResolverOutcome, AgentValues) ->
    ResolverOutcome#{
        <<"archetype">>    => maps:get(<<"archetype">>, AgentValues, null),
        <<"gearing_type">> => maps:get(<<"gearing_type">>, AgentValues, null),
        <<"one_liner">>    => maps:get(<<"one_liner">>, AgentValues, null)
    };
%% tax_structure: the SINGLE entity_structuring leaf the sidecar authored
%% (recommended_entity). Slot-scoped fold — the agent reach is exactly this one judgment
%% field; every figure (the CGT determinants, the null property/seam-deferred money) is the
%% resolver scaffold's and is left untouched (§98 — the agent authors NO figure, NO verdict).
merge_agent(<<"tax_structure">>, ResolverOutcome, AgentValues) ->
    ResolverOutcome#{
        <<"recommended_entity">> =>
            maps:get(<<"recommended_entity">>, AgentValues, null)
    };
%% property_assessment (Phase B): fold the rentability + valuation + synthesis leaves the
%% sidecar authored — the rent BAND, the four qualitative verdicts/scores, and the bilingual
%% strengths/concerns. Slot-scoped — the agent never touches the neutral facts (state/suburb/
%% price/property_type, the resolver's copy) nor authors a figure. The ONE derived figure,
%% rental_yield_gross_estimate, is resolver-COMPUTED here from the agent's rent band + the
%% price fact (§98 — the yield % is never agent-authored; the rent is an irreducible market
%% ESTIMATE surfaced as a band, not a regulated calculation [[match-enforcement-grade-to-property-kind]]).
merge_agent(<<"property_assessment">>, ResolverOutcome, AgentValues) ->
    Rent  = maps:get(<<"estimated_weekly_rent_range">>, AgentValues, null),
    Price = maps:get(<<"price">>, ResolverOutcome, null),
    ResolverOutcome#{
        <<"estimated_weekly_rent_range">>  => Rent,
        <<"viability_verdict">>            => maps:get(<<"viability_verdict">>, AgentValues, null),
        <<"capital_growth_outlook">>       => maps:get(<<"capital_growth_outlook">>, AgentValues, null),
        <<"depreciation_attractiveness">>  => maps:get(<<"depreciation_attractiveness">>, AgentValues, null),
        <<"land_quality_score">>           => maps:get(<<"land_quality_score">>, AgentValues, null),
        <<"investor_grade_overall">>       => maps:get(<<"investor_grade_overall">>, AgentValues, null),
        <<"key_strengths">>                => maps:get(<<"key_strengths">>, AgentValues, null),
        <<"key_concerns">>                 => maps:get(<<"key_concerns">>, AgentValues, null),
        <<"rental_yield_gross_estimate">>  => gross_yield(Rent, Price)
    };
merge_agent(Other, _ResolverOutcome, _AgentValues) ->
    erlang:error({no_agent_merge_for, Other}).

%% Recover a two-path component's stored agent-leaf VALUES (in the sidecar-reply shape
%% merge_agent/3 consumes) from a previously-committed outcome — the inverse of the merge.
%% A base_resolver refresh feeds these back through the SAME merge_agent/3 after re-running
%% the resolver half, so the resolver figures are always fresh and only the agent leaf's
%% SOURCE (snapshot here, sidecar on a full turn) varies. Component-owned, like merge_agent.
-spec agent_values_from_outcome(binary(), map()) -> map().
agent_values_from_outcome(<<"mortgage_finance">>, Stored) ->
    fh_engine_mortgage:agent_values_from_outcome(Stored);
%% investment_strategy: recover the three thesis leaves verbatim from the snapshot (the
%% inverse of merge_agent/3 above) so a base_resolver refresh re-runs the scaffold (fresh
%% renderer/kb_versions/carried-horizon) and re-attaches the stored thesis WITHOUT a sidecar
%% call — the agent re-authors nothing. Direct field map (no nesting, unlike mortgage's rate).
agent_values_from_outcome(<<"investment_strategy">>, Stored) ->
    #{<<"archetype">>    => maps:get(<<"archetype">>, Stored, null),
      <<"gearing_type">> => maps:get(<<"gearing_type">>, Stored, null),
      <<"one_liner">>    => maps:get(<<"one_liner">>, Stored, null)};
%% tax_structure: recover the single entity leaf verbatim from the snapshot (the inverse of
%% merge_agent/3 above) so a base_resolver refresh re-runs the scaffold (fresh
%% renderer/kb_versions/CGT determinants) and re-attaches the stored entity WITHOUT a sidecar
%% call — the agent re-authors nothing.
agent_values_from_outcome(<<"tax_structure">>, Stored) ->
    #{<<"recommended_entity">> => maps:get(<<"recommended_entity">>, Stored, null)};
%% property_assessment: recover the eight agent leaves verbatim from the snapshot (the
%% inverse of merge_agent/3 above). A per-property resolver-only refresh (Slice B+) re-runs
%% the resolver half (re-copies the facts, RE-COMPUTES the yield from the recovered rent +
%% price — idempotent) and re-attaches these without a sidecar call. Not exercised by the
%% base_resolver sweep (base-scope only; addenda untouched), built for symmetry + that path.
agent_values_from_outcome(<<"property_assessment">>, Stored) ->
    #{<<"estimated_weekly_rent_range">>  => maps:get(<<"estimated_weekly_rent_range">>, Stored, null),
      <<"viability_verdict">>            => maps:get(<<"viability_verdict">>, Stored, null),
      <<"capital_growth_outlook">>       => maps:get(<<"capital_growth_outlook">>, Stored, null),
      <<"depreciation_attractiveness">>  => maps:get(<<"depreciation_attractiveness">>, Stored, null),
      <<"land_quality_score">>           => maps:get(<<"land_quality_score">>, Stored, null),
      <<"investor_grade_overall">>       => maps:get(<<"investor_grade_overall">>, Stored, null),
      <<"key_strengths">>                => maps:get(<<"key_strengths">>, Stored, null),
      <<"key_concerns">>                 => maps:get(<<"key_concerns">>, Stored, null)};
agent_values_from_outcome(Other, _Stored) ->
    erlang:error({no_agent_reattach_for, Other}).

%% --- buyer_profile (real) ---------------------------------------------------
%% The pipeline entry: project the onboarding fact base into the `profile` outcome.
%% At the onboarding turn the deep applicant facts (citizenship, age, income,
%% ownership history) are not yet gathered — those arrive via chat/uploads on a
%% later refine turn (which will load the enriched profile from the profiles SOT).
%% So the base projection carries the onboarding subset + a minimal lead applicant;
%% FIRB derives conservatively (Mode A enters via a non-foreign lead → false).

buyer_profile(Args) ->
    Onboarding = maps:get(onboarding, Args, #{}),
    %% IC3: the enriched household financial facts, loaded from the profiles SOT
    %% (facts_jsonb.household_financials — the canonical fact-model key, fact-model-
    %% unification.md §"unified schema") and threaded into the turn args. The `profile`
    %% outcome is the FLAT PROJECTION of this grouped storage (that doc §97). Absent at
    %% onboarding (plan-first) → empty → the framed financials stay PENDING (null/empty),
    %% the pre-IC3 honest-partial state; they arrive on a refine turn (constraint #1/#9).
    Financials = maps:get(household_financials, Args, #{}),
    TargetRange = maps:get(<<"target_price_range">>, Onboarding, null),
    TargetZone = maps:get(<<"target_zone">>, Onboarding, []),
    Intent = maps:get(intent, Args, <<"owner_occupier">>),
    %% Mode-A possibility-set projection (resolver-semantics.md): the base turn has
    %% only the onboarding inputs, so we project what Mode A DEFINITIONALLY guarantees
    %% plus one operational assumption (an adult buyer); genuinely-unknown facts are
    %% left ABSENT and resolve `undetermined` downstream (eligibility surfaces them as
    %% "confirm X", never a hard reject). The deep exact facts arrive via chat on a
    %% later refine turn (loaded from the profiles SOT), narrowing the sets to scalars.
    Applicant = #{
        <<"role">> => <<"primary">>,
        %% definitional — Mode A = Vietnamese-AU citizen OR PR; exact unknown, so a SET
        %% (`in [citizen,PR]` is definitely-true; `eq citizen`, for Help-to-Buy, undetermined).
        <<"citizenship_status">> =>
            #{<<"oneof">> => [<<"citizen">>, <<"permanent_resident">>]},
        %% definitional — first-home-buyer declaration (Mode A).
        <<"ever_owned_au_property">> => false,
        <<"currently_owns_property">> => false,
        %% definitional — the owner-occupier intent axis.
        <<"owner_occupier_intent">> => Intent =:= <<"owner_occupier">>,
        %% operational assumption (NOT in the mode definition) — a property buyer is an
        %% adult. A RANGE, so `age gte 18` is definitely-true without inventing an exact age.
        <<"age">> => #{<<"range">> => [18, null]}
        %% ABSENT (→ undetermined → "confirm"): exact citizen-vs-PR (the set narrows on
        %% refine), prior_fhss_release, assessable_income, years_since_last_au_property_interest.
    },
    %% Derive per-applicant firb_required through the resolver. Over the projected
    %% citizenship set, `in [temporary_resident, non_resident]` is definitely-false →
    %% firb_required=false (Mode A's non-foreign-lead entry, now resolver-derived).
    Facts = #{<<"applicants">> => [Applicant]},
    FirbTri = fh_engine_resolver:eval_applicants(
        <<"applicant.firb_required">>, fh_engine_kb:rules(), Facts),
    Applicants = [A#{<<"firb_required">> => tri_to_json(F)}
                  || {A, F} <- lists:zip([Applicant], FirbTri)],
    Outcome = #{
        <<"applicants">> => Applicants,
        <<"applicant_count">> => length(Applicants),
        %% conservative / fail-closed for FIRB: flag unless EVERY applicant is
        %% definitely non-foreign (`undetermined` errs toward requiring FIRB). Mode A → false.
        <<"firb_required_any">> => lists:any(fun(F) -> F =/= false end, FirbTri),
        %% single-buyer default (consistent with the single-lead onboarding): no
        %% non-buying partner declared. The couple-as-one schemes' partner gate (F4/G2)
        %% reads this — exists=false makes the gate pass; a refine turn that reveals a
        %% partner narrows it. (Their ownership facts arrive then, not at onboarding.)
        <<"non_buying_partner">> => #{<<"exists">> => false},
        <<"intended_occupancy_use">> => <<"sole_occupier">>,
        %% CGT-exemption determinants for disposition (kb.tax.cgt-main-residence-exemption):
        %% Mode-A definitional projection — a Vietnamese-AU citizen/PR buying a home to live
        %% in is an Australian resident for tax. sole_occupier + resident → main-residence
        %% exempt (cgt null). The overseas-move trap (non-resident at disposal) is a refine
        %% narrowing, not a base fact.
        <<"tax_residency">> => <<"resident">>,
        %% H: the hold horizon (years). null at base = Mode-A long/indefinite default → no
        %% disposal projection until the horizon what-if sets it (engine-contract §10.5).
        <<"hold_horizon_years">> => maps:get(<<"hold_horizon_years">>, Onboarding, null),
        <<"target_price_range">> => TargetRange,
        <<"target_zone">> => TargetZone,
        %% IC3 — neutral derived financials (facts, not verdicts): the framed income +
        %% raw debt facts the serviceability resolver reads downstream (profile holds
        %% facts; mortgage reasons — §11.9). assessable_income is the SHADED combined
        %% income; for the Mode-A wedge (PAYG base salary) shading is identity — the
        %% income-TYPE haircuts (rental/overtime/offshore) arrive with income types on a
        %% later refine turn. null/empty when no financials captured (capacity PENDING).
        <<"assessable_income">> => assessable_income(Financials),
        <<"foreign_sourced_income_component">> => foreign_sourced(Financials),
        <<"debts">> => debts(Financials),
        %% bilingual {vi,en} via kb.copy.profile (no Vietnamese in Erlang literals —
        %% the io:format ~s >255-codepoint trap; bilingual-content.md §3b).
        <<"key_constraints">> => [copy(<<"constraint_financials_pending">>, #{})],
        <<"key_strengths">>   => [copy(<<"strength_first_home_buyer">>, #{})]
    },
    KbVersions = fh_engine_kb:kb_anchors(
        [<<"kb.hecs.thresholds">>, <<"kb.firb.status-determination">>,
         <<"kb.lender.serviceability-basics">>]),
    {Outcome, <<"summary-card">>, KbVersions}.

%% --- investor_profile (Mode C, real) ----------------------------------------
%% The investor pipeline entry: project the onboarding fact base into the CANONICAL
%% `profile` outcome, investor lens (blueprint component 1). Same canonical, mode-
%% independent shape as buyer_profile (identity-layer unification, fact-model-
%% unification.md "Mode-C activation"); the investor deltas are (a) a per-applicant
%% tax{} object (residency + jurisdiction; marginal_rate derived_from income → PENDING
%% until captured) in place of the owner-occupier eligibility leaves (no
%% owner_occupier_intent / first-home ownership history — not eligibility-bearing for an
%% investor), and (b) a domestic-investor strength rather than the FHB one. The deep
%% investor facts (existing_portfolio, traits.experience_level, deposit, ppor equity,
%% borrowing capacity) arrive on a refine turn from the profiles SOT — null at onboarding
%% (plan-first, constraint #1/#9), honest-partial. Distinct component name from
%% buyer_profile ⟹ zero Mode-A reach (the FHB turn never selects this clause).
investor_profile(Args) ->
    Onboarding = maps:get(onboarding, Args, #{}),
    Financials = maps:get(household_financials, Args, #{}),
    TargetRange = maps:get(<<"target_price_range">>, Onboarding, null),
    TargetZone = maps:get(<<"target_zone">>, Onboarding, []),
    %% Mode-C definitional applicant: a domestic (citizen/PR) investor. citizenship is the
    %% SAME set as Mode A; the investor-specific leaf is the per-applicant tax{}.
    %% residency_for_tax=resident is the domestic default (drives the CGT 50% discount read
    %% by tax_structure / disposition); jurisdiction=AU (Mode D adds VN); marginal_rate
    %% ABSENT until income captured (a refine narrowing, derived_from taxable_income).
    Applicant = #{
        <<"role">> => <<"primary">>,
        <<"citizenship_status">> =>
            #{<<"oneof">> => [<<"citizen">>, <<"permanent_resident">>]},
        <<"tax">> => #{
            <<"residency_for_tax">> => <<"resident">>,
            <<"jurisdiction">> => <<"AU">>
        }
    },
    %% firb_required per applicant via the SAME resolver Mode A uses — over the citizen/PR
    %% set, `in [temporary_resident, non_resident]` is definitely-false → false (Mode C is
    %% domestic; a foreign co-investor would route to the FIRB path → Mode D).
    Facts = #{<<"applicants">> => [Applicant]},
    FirbTri = fh_engine_resolver:eval_applicants(
        <<"applicant.firb_required">>, fh_engine_kb:rules(), Facts),
    Applicants = [A#{<<"firb_required">> => tri_to_json(F)}
                  || {A, F} <- lists:zip([Applicant], FirbTri)],
    Outcome = #{
        <<"applicants">> => Applicants,
        <<"applicant_count">> => length(Applicants),
        %% conservative / fail-closed for FIRB (Mode C → false).
        <<"firb_required_any">> => lists:any(fun(F) -> F =/= false end, FirbTri),
        %% income facts framed the SAME way as Mode A (IC3 helpers reused); null/empty when
        %% no financials captured. Borrowing capacity stays PENDING — computed downstream by
        %% the mortgage_finance investor variant (a later unit), never here.
        <<"assessable_income">> => assessable_income(Financials),
        <<"foreign_sourced_income_component">> => foreign_sourced(Financials),
        <<"debts">> => debts(Financials),
        %% the onboarding target → DAG carrier (downstream investor yield/cash read these
        %% off profile.*, exactly as Mode A's downstream reads them).
        <<"target_price_range">> => TargetRange,
        <<"target_zone">> => TargetZone,
        %% null at base = no disposal projection until the horizon is set (for an investor H
        %% also arrives via strategy_thesis.hold_period_years — a later component).
        <<"hold_horizon_years">> => maps:get(<<"hold_horizon_years">>, Onboarding, null),
        %% bilingual {vi,en} via kb.copy.profile. One honest constraint (financials pending,
        %% mode-neutral, reused) + one definitional Mode-C strength (domestic investor: no
        %% FIRB / no foreign-buyer surcharge / resident CGT-discount eligible). Decision-
        %% support tone — states the position, not "you should invest" (ASIC line).
        <<"key_constraints">> => [copy(<<"constraint_financials_pending">>, #{})],
        <<"key_strengths">>   => [copy(<<"strength_domestic_investor">>, #{})]
        %% ABSENT (→ null → honest-partial): existing_portfolio, traits,
        %% deposit_ready_for_purchase_amount, ppor_equity_available_for_leverage,
        %% approx_borrowing_capacity — gathered on a refine turn (profiles SOT).
    },
    KbVersions = fh_engine_kb:kb_anchors(
        [<<"kb.tax.income-tax-resident-2025-26">>,
         <<"kb.lender.serviceability-investment-loans">>,
         <<"kb.investor.experience-levels">>]),
    {Outcome, <<"summary-card">>, KbVersions}.

%% --- investment_strategy (Mode C, two-path RESOLVER half) -------------------
%% The investor base spine (blueprint component 3 — replaces FHB eligibility): the
%% investment thesis. This is the FIRST Mode-C agent-path component, built TWO-PATH
%% (mortgage-finance-two-path.md): the SIDECAR (reasoning_domain investment_thesis)
%% authors the three IRREDUCIBLE judgment leaves — strategy_archetype, gearing_type, and
%% the bilingual thesis one_liner — and merge_agent/3 above folds them in. This function
%% is the RESOLVER half: the deterministic scaffold the agent is NOT trusted with —
%%   - the renderer (summary-card) + the kb_versions AUDIT TRAIL (the four strategy
%%     anchors), resolver-owned so the regulated audit can't be agent-omitted/fabricated;
%%   - hold_period_years CARRIED from the upstream profile (the user's onboarding horizon;
%%     it sets disposition's H downstream) — a deterministic carry, not a judgment;
%%   - every other strategy_thesis field left null = HONEST-PARTIAL. The property-relative
%%     targets (gross_yield / capital_growth / lvr) follow from BOTH the archetype (agent
%%     output, not yet known when this scaffold runs) AND a specific property (dag_reads
%%     property_fit_investor — per-property, ABSENT at base), so they resolve on a
%%     per-property turn; exit_strategy follows the archetype+horizon (judgment pending);
%%     is_property_aligned_with_thesis / alignment_reasoning are STRUCTURALLY null at base
%%     (there is no property to align the thesis to).
%% So the agent's reach is exactly the three judgment leaves — no figure, no verdict
%% (§98 / [[match-enforcement-grade-to-property-kind]]: the thesis is SOFT quality, forced
%% bilingual + enum by the sidecar's output schema; the targets are removed from its reach
%% by being resolver-null). Reads only the upstream `profile` outcome (dag_reads).
investment_strategy(Upstream) ->
    Profile = maps:get(<<"profile">>, Upstream, #{}),
    Outcome = #{
        %% AGENT slots (investment_thesis) — null here; merge_agent/3 folds the sidecar's
        %% three leaves. A base_resolver refresh re-attaches the stored ones (no LLM).
        <<"archetype">>    => null,
        <<"gearing_type">> => null,
        <<"one_liner">>    => null,
        %% property-relative targets — honest-partial null at base (need archetype + property).
        <<"target_gross_yield">>    => null,
        <<"target_capital_growth">> => null,
        <<"target_lvr">>            => null,
        %% the hold horizon: carry the user's onboarding intent off profile (= disposition's
        %% H). null when unset = the long/indefinite default (no disposal projection yet).
        <<"hold_period_years">> => maps:get(<<"hold_horizon_years">>, Profile, null),
        %% exit follows archetype+horizon → null at base (judgment pending the thesis).
        <<"exit_strategy">> => null,
        %% structural null at base — no property attached to align the thesis against.
        <<"is_property_aligned_with_thesis">> => null,
        <<"alignment_reasoning">> => null
    },
    KbVersions = fh_engine_kb:kb_anchors(
        [<<"kb.investor.strategy-archetypes">>,
         <<"kb.investor.gearing-types-and-implications">>,
         <<"kb.investor.hold-period-considerations">>,
         <<"kb.investor.exit-strategy-options">>]),
    {Outcome, <<"summary-card">>, KbVersions}.

%% --- tax_structure (Mode C, two-path RESOLVER half — base-spine presence) ----
%% The investor base spine (blueprint component 6): the tax-optimised ownership structure.
%% TWO-PATH like investment_strategy (mortgage-finance-two-path.md): the SIDECAR
%% (reasoning_domain entity_structuring) authors the ONE irreducible judgment leaf —
%% recommended_entity, the ownership structure to take to a registered tax agent — and
%% merge_agent/3 above folds it in. This function is the RESOLVER half: the deterministic
%% scaffold the agent is NOT trusted with — the renderer (data-table), the kb_versions audit
%% (the six tax anchors), and EVERY figure (§98 / [[no-judge-ground-the-producer]]: the CGT
%% determinants + the deferred money are resolver-owned, never agent-authored).
%%
%% FOUNDATION-FIRST PAYOFF ([[place-upstream-figures-dont-recompute]] inverse, completing a
%% built consumer). The already-built `disposition` (fh_engine_disposition:cgt_investor/4)
%% reads EXACTLY four tax_optimised_structure fields and its `Clean` test already defines
%% their contract: recommended_entity (∈ personal_sole/joint for the clean computed path),
%% cgt_marginal_rate (is_number), cgt_discount_eligible (true → 50% discount), and
%% cost_base_depreciation_clawback (=:= false for clean). So this base output is not
%% free-floating — it CLOSES wiring disposition already expects; the producer and consumer
%% were designed together.
%%
%% RESOLVER computes (KB-grounded boolean constants — no income, no property, no band):
%%   - cgt_discount_eligible = true: the blueprint default (kb.tax.cgt-50-percent-discount —
%%     a multi-year investment hold clears 12 months). [Doc seam, flagged not patched: the
%%     field's "true if held >12 months" semantics wants strategy_thesis.hold_period_years,
%%     but strategy_thesis is NOT a declared tax_structure input (profile + cash_flow_projection
%%     are); the constant matches the compiled blueprint. A hold-aware refinement needs the
%%     input declared.]
%%   - cost_base_depreciation_clawback = true: Div 43 capital works claimed reduces the cost
%%     base (kb.tax.depreciation-division-43-and-40, which FLAGS the clawback, never asserts a
%%     dollar). true → disposition's Clean is false → CGT to_verify: the conservative, honest
%%     outcome (the clawback dollar is deferred to a tax agent).
%%
%% HONEST-PARTIAL NULL AT BASE ([[base-turn-honest-partial-output]]), in two deferral classes:
%%   (a) property/rent-dependent — negative_gearing_active + the tax-refund / after-tax
%%       cash-flow / depreciation figures all hang off the rental cash flow (cash_flow_projection,
%%       null at base — no property). null → disposition CGT to_verify (the conservative net).
%%   (b) BLOCKED by an unresolved decision (null because a contract is undecided, NOT because the
%%       datum is unknown): cgt_marginal_rate needs an ATO income-tax-brackets KB doc (UNAUTHORED)
%%       + assessable_income — null → disposition CGT to_verify; setup_costs +
%%       annual_compliance_cost hit the SAME banded-vs-scalar seam flagged on yield_modelling
%%       (the KB gives BANDS — entity setup $1.5k–$4k, kb.tax.entity-setup-costs — but the
%%       registry types these scalar `money`; a scalar point would assert false precision, a band
%%       would fail Layer-1). Both land with property_assessment, where the banded/scalar call is
%%       resolved for the whole investor money surface.
%%
%% The agent's reach is exactly the one entity leaf — no figure, no verdict (the
%% entity-comparison KB is the most regulated content in the wedge; the sidecar's single-enum
%% output schema removes every figure from its reach, and the ASIC posture — a starting
%% structure to confirm with a licensed professional, never a directive — is enforced in the
%% entity_structuring prompt). [Doc/schema seam, flagged not patched: the regulated entity
%% recommendation has NO `reasoning` field in the compiled outcome — surfacing its reasoning is
%% a separate outcome-schema unit.] Reads only upstream; the base outcome is input-independent.
tax_structure(_Upstream) ->
    Outcome = #{
        %% AGENT slot (entity_structuring) — null here; merge_agent/3 folds the sidecar's one
        %% leaf. A base_resolver refresh re-attaches the stored entity (no LLM).
        <<"recommended_entity">> => null,
        %% RESOLVER — KB-grounded boolean constants (the CGT determinants disposition reads).
        <<"cgt_discount_eligible">>            => true,
        <<"cost_base_depreciation_clawback">> => true,
        %% NULL (a) property/rent-dependent — need cash_flow_projection (null at base).
        <<"negative_gearing_active">>     => null,
        <<"annual_tax_refund_year_1">>    => null,
        <<"after_tax_cash_flow_year_1">>  => null,
        <<"after_tax_cash_flow_per_week">> => null,
        <<"total_depreciation_year_1">>   => null,
        %% NULL (b) blocked by an unresolved decision — deferred with property_assessment.
        <<"cgt_marginal_rate">>     => null,   %% needs ATO-brackets KB + assessable_income
        <<"setup_costs">>           => null,   %% banded-vs-scalar seam (KB band vs scalar money)
        <<"annual_compliance_cost">> => null   %% banded-vs-scalar seam
    },
    KbVersions = fh_engine_kb:kb_anchors(
        [<<"kb.tax.entity-comparison-personal-trust-company-smsf">>,
         <<"kb.tax.negative-gearing-mechanics">>,
         <<"kb.tax.depreciation-division-43-and-40">>,
         <<"kb.tax.cgt-50-percent-discount">>,
         <<"kb.tax.quantity-surveyor-reports">>,
         <<"kb.tax.land-tax-by-state">>]),
    {Outcome, <<"data-table">>, KbVersions}.

%% --- yield_modelling (Mode C, pure RESOLVER — base-spine presence) -----------
%% The investor base spine (blueprint component 5): the rental cash-flow model. A PURE
%% resolver figure-owner — the same class as fh_engine_disposition (every cash_flow_projection
%% field is a figure/enum, NO free-text → empty agent_leaves, no two-path). The figures are
%% removed from the LLM's reach (§98 / [[no-judge-ground-the-producer]]): resolver-computed,
%% KB-grounded (the five Cluster-Y anchors), banded where the inputs are bands — never agent-
%% authored.
%%
%% HONEST-PARTIAL AT BASE ([[base-turn-honest-partial-output]]). The binding input is the
%% WEEKLY RENT, which the KB (kb.investor.rental-income-modelling) sources from
%% `estimated_weekly_rent_range` — an AGENT LEAF on `property_assessment`, a per-property
%% component that is ABSENT at base (and not yet built). There is no base rent source (suburb
%% median-rent data is not wired; the paid feeds are deferred). Every cash_flow_projection
%% figure hangs off that rent, so with no property the whole outcome resolves null — exactly as
%% disposition returns null when its horizon/price inputs are unset. The base-knowable items
%% (vacancy ~3%, PM 7.5%, growth 3% p.a.) are KB *assumptions*, and cash_flow_projection has no
%% field to carry them, so they stay in the KB until the arithmetic runs. null conforms to any
%% field (fh_engine_outcome implicit-universal nullability), so the scaffold passes Layer-1
%% trivially with NO banded-vs-scalar type decision forced here.
%%
%% THE CASH-FLOW ARITHMETIC (Slice B1) — branches on the per-property keystone. At base
%% property_fit_investor is absent → the honest-partial all-null scaffold (base_cfp/0). In the
%% Phase-B turn (after property_assessment) it is present → the banded rent-economics below. The
%% CROSS-CONTRACT seam it forced is decided in Slice B0: the rent is a band, so income/yields/
%% cash-flow are `money_range`/`percentage_range` `[lo, hi]` bands (not the old scalar typing),
%% matching disposition's banded surface + the calculator renderer (which collapses `[x,x]` to a
%% point). disposition's `cash_flow_before_tax_year_1` read coerces a scalar via money_range/1, so
%% the band propagates backward-compatibly. B1 computes the PRE-LOAN figures (determined by rent +
%% price + KB ratios); the POST-LOAN figures need budget_envelope_investor.loan_amount (a
%% cash_position-per-property figure, unbuilt) → null until Slice B3.
%%
%% One clause serves BOTH investor blueprints (resolver keys on component name): the Mode-D
%% `cash_flow_projection_foreign` variant also runs through here — fine at base (null conforms;
%% its FX-specific fields default null), the Mode-D figures deferred with Mode D. Reads only
%% upstream (no Args); the base outcome is input-independent (all null) — Upstream is taken for
%% shape symmetry with the other resolvers and the per-property branch to come.
yield_modelling(Upstream) ->
    Outcome = case maps:get(<<"property_fit_investor">>, Upstream, undefined) of
                  Pf when is_map(Pf), map_size(Pf) > 0 ->
                      cash_flow_projection(
                          maps:get(<<"estimated_weekly_rent_range">>, Pf, null),
                          maps:get(<<"price">>, Pf, null),
                          maps:get(<<"property_type">>, Pf, null));
                  _ ->
                      base_cfp()
              end,
    %% the five Cluster-Y anchors — the resolver-owned audit trail (method + bands), carried
    %% whether the figures are null (base) or computed (per-property) so the methodology is
    %% provenanced either way. When the POST-loan cluster computes (interest present, Slice B3a),
    %% add the four financing anchors — the loan/rate/LVR provenance for the regulated figures.
    YieldAnchors = [<<"kb.investor.rental-income-modelling">>,
                    <<"kb.investor.operating-expenses-typical-ratios">>,
                    <<"kb.investor.vacancy-rate-assumptions">>,
                    <<"kb.investor.cash-flow-modelling-methodology">>,
                    <<"kb.investor.property-management-fees">>],
    FinancingAnchors = case maps:get(<<"annual_interest_year_1">>, Outcome, null) of
                           null -> [];
                           _    -> [<<"kb.lender.serviceability-basics">>,
                                    <<"kb.lender.serviceability-investment-loans">>,
                                    <<"kb.investor.deposit-requirements-investment-loans">>,
                                    <<"kb.loan.interest-only-vs-pi-investor">>]
                       end,
    KbVersions = fh_engine_kb:kb_anchors(YieldAnchors ++ FinancingAnchors),
    {Outcome, <<"calculator">>, KbVersions}.

%% the honest-partial all-null cash_flow_projection scaffold — at base (no property) and for the
%% per-property fields B1 does not yet compute (the POST-loan figures need a loan; the geared
%% verdict + projections follow the post-loan cash flow → Slice B3). null conforms to any field.
base_cfp() ->
    #{
        <<"annual_rental_income_year_1">>      => null,
        <<"annual_operating_expenses_year_1">> => null,
        <<"annual_interest_year_1">>           => null,
        <<"cash_flow_before_tax_year_1">>      => null,
        <<"cash_flow_before_tax_per_week">>    => null,
        <<"gross_yield">>                  => null,
        <<"net_yield_pre_loan">>           => null,
        <<"net_yield_post_loan_pre_tax">>  => null,
        <<"year_5_projected_cash_flow">>   => null,
        <<"year_10_projected_cash_flow">>  => null,
        <<"is_positive_neutral_or_negative_geared_pre_tax">> => null
    }.

%% The banded rent-economics — every figure a [lo, hi] BAND because the weekly rent is a band
%% (the §B0 banded surface). Removed from the LLM's reach: resolver-computed, KB-grounded, never
%% agent-authored. Two layers:
%%   - PRE-LOAN (Slice B1): income, opex, gross yield, net-pre-loan yield — determined by (rent
%%     band, price, KB ratios) alone.
%%   - POST-LOAN (Slice B3a): interest, before-tax cash flow (annual + per-week), net-post-loan
%%     yield, the year-5/10 projection, and the geared position — they need a LOAN. The DAG runs
%%     yield BEFORE cash_position (yield → tax → cash), so the loan is not read from there; the KB
%%     cash-flow-modelling-methodology assigns interest to the financing structure, modelled here
%%     at a REPRESENTATIVE leverage (price × LVR baseline × the investor product rate, all
%%     KB-read). This equals what mortgage_finance would compute per-property (price × the same
%%     KB LVR), so it agrees with the intended mortgage_plan→yield wiring (blueprint §5 loan_costs)
%%     once that lands; it is honest representative leverage, flagged, refined when the actual deal
%%     financing (savings/capacity) is captured. [[place-upstream-figures-dont-recompute]]: read
%%     rent/price off property_fit_investor; never recompute them.
cash_flow_projection([RLo, RHi], Price, PType)
  when is_number(RLo), is_number(RHi), is_number(Price), Price > 0 ->
    %% income (kb.investor.rental-income-modelling): gross = weekly rent × 52; effective =
    %% gross × (1 − vacancy). EFFECTIVE is the load-bearing line every downstream figure uses.
    Weeks   = 52,     %% weeks_per_year (rental-income-modelling — the 52-week convention)
    Vacancy = 0.03,   %% default_vacancy_assumed_pct (vacancy-rate-assumptions; PLACEHOLDER
                      %% default — property_fit_investor carries no per-suburb vacancy figure)
    GrossLo = RLo * Weeks,
    GrossHi = RHi * Weeks,
    EffLo   = round(GrossLo * (1 - Vacancy)),
    EffHi   = round(GrossHi * (1 - Vacancy)),
    GrossYield = [round1(GrossLo / Price * 100), round1(GrossHi / Price * 100)],
    case opex_band(EffLo, EffHi, Price, PType) of
        {OpexLo, OpexHi} ->
            %% net pre-loan = (effective income − opex) ÷ price (interval subtraction:
            %% [a,b] − [c,d] = [a−d, b−c]).
            NetYieldPreLoan = [round1((EffLo - OpexHi) / Price * 100),
                               round1((EffHi - OpexLo) / Price * 100)],
            PreLoan = (base_cfp())#{
                <<"annual_rental_income_year_1">>      => [EffLo, EffHi],
                <<"annual_operating_expenses_year_1">> => [OpexLo, OpexHi],
                <<"gross_yield">>                      => GrossYield,
                <<"net_yield_pre_loan">>               => NetYieldPreLoan
            },
            post_loan(EffLo, EffHi, OpexLo, OpexHi, Price, PreLoan);
        none ->
            %% strata — the body-corporate levy (building cover + structural maintenance) is not
            %% carried in property_fit_investor, so opex would understate cost; null it (honest-
            %% partial, the KB no-double-count + conservative discipline). Income + gross yield
            %% still compute; the POST-loan cluster needs the full opex picture → null too. Strata
            %% opex (and its post-loan figures) land when the levy is wired (a later slice).
            (base_cfp())#{
                <<"annual_rental_income_year_1">> => [EffLo, EffHi],
                <<"gross_yield">>                 => GrossYield
            }
    end;
cash_flow_projection(_Rent, _Price, _PType) ->
    %% rent band or price missing/ill-formed → honest-partial null (never a false figure).
    base_cfp().

%% Slice B3a — the POST-loan cluster. Completes the cash-flow projection with a representative
%% investment loan: loan = price × LVR baseline (80%, the 20%-deposit/no-LMI planning baseline);
%% rate = OO representative product rate + the investment premium; interest-only basis (the
%% blueprint's loan_costs interest_only_period_years), so year-1 interest = loan × rate (a POINT
%% — loan and rate are points → interest is scalar `money`, not banded). The financing figures are
%% KB-read (no magic literal; single-source with disposition's amortisation rate).
post_loan(EffLo, EffHi, OpexLo, OpexHi, Price, Cfp) ->
    Lvr      = 100 - param(<<"kb.investor.deposit-requirements-investment-loans">>,
                           <<"deposit_no_lmi_pct">>),
    Rate     = param(<<"kb.lender.serviceability-basics">>, <<"representative_product_rate_pct">>)
             + param(<<"kb.lender.serviceability-investment-loans">>, <<"investment_rate_premium_pp">>),
    Growth   = param(<<"kb.investor.cash-flow-modelling-methodology">>,
                     <<"rent_growth_assumed_pct_pa">>) / 100,
    Interest = round(Price * Lvr / 100 * Rate / 100),
    %% before-tax cash flow = effective income − opex − interest (interval; interest is a point).
    CfLo = EffLo - OpexHi - Interest,
    CfHi = EffHi - OpexLo - Interest,
    Cfp#{
        <<"annual_interest_year_1">>        => Interest,
        <<"cash_flow_before_tax_year_1">>   => [CfLo, CfHi],
        <<"cash_flow_before_tax_per_week">> => [round(CfLo / 52), round(CfHi / 52)],
        <<"net_yield_post_loan_pre_tax">>   => [round1(CfLo / Price * 100), round1(CfHi / Price * 100)],
        <<"year_5_projected_cash_flow">>    => projected(EffLo, EffHi, OpexLo, OpexHi, Interest, Growth, 4),
        <<"year_10_projected_cash_flow">>   => projected(EffLo, EffHi, OpexLo, OpexHi, Interest, Growth, 9),
        <<"is_positive_neutral_or_negative_geared_pre_tax">> => geared(CfLo, CfHi)
    }.

%% the year-N projected before-tax cash flow: income & opex compounded at the growth rate for
%% N years (interest held flat — interest-only, loan constant). A band. Indicative, assumption-
%% driven (the KB growth convention), per cash-flow-modelling-methodology.
projected(EffLo, EffHi, OpexLo, OpexHi, Interest, Growth, Years) ->
    G = math:pow(1 + Growth, Years),
    [round(EffLo * G - OpexHi * G - Interest),
     round(EffHi * G - OpexLo * G - Interest)].

%% the pre-tax geared position from the before-tax cash-flow band: wholly negative → negative;
%% wholly positive → positive; straddling zero → neutral (the band's sign is undetermined).
geared(_CfLo, CfHi) when CfHi < 0 -> <<"negative">>;
geared(CfLo, _CfHi) when CfLo > 0 -> <<"positive">>;
geared(_CfLo, _CfHi)              -> <<"neutral">>.

%% a KB `parameters[Key].value` scalar (the fh_engine_disposition / fh_engine_cash read pattern).
param(Slug, Key) ->
    {ok, Cj} = fh_engine_kb:kb_rules(Slug),
    maps:get(<<"value">>, maps:get(Key, maps:get(<<"parameters">>, Cj))).

%% operating expenses (kb.investor.operating-expenses-typical-ratios + property-management-fees),
%% banded. A freestanding HOUSE carries its own building insurance + full maintenance; a STRATA
%% property carries building cover + structural maintenance inside the body-corporate levy (not
%% carried in property_fit_investor) → return `none` so opex stays null rather than understate cost.
opex_band(EffLo, EffHi, Price, PType) ->
    case is_house(PType) of
        false -> none;
        true ->
            %% fixed dollar bands (low/high), from operating-expenses-typical-ratios:
            %% council 1500–2500, water 700–1500, landlord-ins 300–700, building-ins(house) 1000–2000.
            FixedLo = 1500 + 700 + 300 + 1000,
            FixedHi = 2500 + 1500 + 700 + 2000,
            %% maintenance reserve — 0.5–1.0% of property value (maintenance_reserve_pct_of_value_*).
            MaintLo = 0.005 * Price,
            MaintHi = 0.010 * Price,
            %% property management — 7.5% of rent COLLECTED (effective income); scales with rent.
            PmLo = 0.075 * EffLo,
            PmHi = 0.075 * EffHi,
            {round(FixedLo + MaintLo + PmLo), round(FixedHi + MaintHi + PmHi)}
    end.

is_house(<<"established_house">>) -> true;
is_house(<<"new_house">>)        -> true;
is_house(<<"house_and_land">>)   -> true;
is_house(_)                      -> false.   %% apartments / off_the_plan → strata (levy-borne)

%% one-decimal rounding for a percentage-band endpoint (e.g. 3.50434 → 3.5).
round1(X) -> round(X * 10) / 10.

%% --- property_assessment (Mode C, two-path RESOLVER half — Phase-B keystone) --
%% The per-property pipeline entry (blueprint component 2, scope per-property): analyse a
%% SPECIFIC attached property with investor metrics. It produces `property_fit_investor` —
%% the §11.9 ONE access path through which every downstream per-property component reads
%% property data (never via basics.* params). Unbuilt until now (no property at base); it
%% lands with the Phase-B turn (mode-c-wedge.md "Phase B").
%%
%% TWO-PATH like the other Mode-C agent components, but with a DIFFERENT figure posture
%% ([[match-enforcement-grade-to-property-kind]]): the resolver copies the four NEUTRAL
%% facts the attachment supplies (state/suburb/price/property_type) and computes the ONE
%% derived figure (rental_yield_gross_estimate, at merge); the SIDECAR authors the
%% irreducible market judgments — the rent BAND (no deterministic rule pins it; no median-
%% rent feed is wired → agentic-boundary test #2) and the qualitative verdicts/scores. The
%% rent is a banded ESTIMATE, KB-grounded (the six property anchors), NOT a regulated
%% calculation, so it is legitimately agent-authored (unlike capacity/CGT/duty, which are
%% removed from the LLM's reach). The §98 line still holds: the only DERIVED figure (gross
%% yield = rent ÷ price) is resolver-computed in merge_agent/3, never agent-authored.
%%
%% Reads the attached property_card from the turn Data (threaded by the attach handler), NOT
%% an upstream outcome — the card is the per-property fact source, the profile is the upstream
%% (dag_reads = [profile], reached by the sidecar for the investor-lens reasoning). The agent
%% slots are null here; merge_agent/3 folds the sidecar leaves + computes the yield.
property_assessment(PropertyCard) ->
    Outcome = #{
        %% RESOLVER — neutral property facts copied verbatim from the attached card.
        <<"state">>         => maps:get(<<"state">>, PropertyCard, null),
        <<"suburb">>        => maps:get(<<"suburb">>, PropertyCard, null),
        <<"price">>         => num_or_null(maps:get(<<"price">>, PropertyCard, null)),
        <<"property_type">> => maps:get(<<"property_type">>, PropertyCard, null),
        %% AGENT slots (rentability + valuation + synthesis) — null; merge_agent/3 folds them.
        <<"estimated_weekly_rent_range">> => null,
        <<"viability_verdict">>           => null,
        <<"capital_growth_outlook">>      => null,
        <<"depreciation_attractiveness">> => null,
        <<"land_quality_score">>          => null,
        <<"investor_grade_overall">>      => null,
        <<"key_strengths">>               => null,
        <<"key_concerns">>                => null,
        %% RESOLVER-COMPUTED at merge from the agent's rent band + the price fact (§98 — the
        %% only derived figure, computed not agent-authored). null until merge.
        <<"rental_yield_gross_estimate">> => null
    },
    KbVersions = fh_engine_kb:kb_anchors(
        [<<"kb.property.rental-market-data-sources">>,
         <<"kb.property.growth-corridors-au">>,
         <<"kb.property.depreciation-by-build-year">>,
         <<"kb.property.investor-grade-features">>,
         <<"kb.property.comparables-methodology">>,
         <<"kb.strata.health-indicators-investor-lens">>]),
    {Outcome, <<"summary-card">>, KbVersions}.

%% Gross rental yield % = annualised mid-band weekly rent ÷ price × 100, 1 dp. null when
%% either input is missing or the band is malformed (honest-partial). Resolver-owned (§98).
gross_yield([Lo, Hi], Price)
  when is_number(Lo), is_number(Hi), is_number(Price), Price > 0 ->
    Mid = (Lo + Hi) / 2,
    round(Mid * 52 / Price * 100 * 10) / 10;
gross_yield(_Rent, _Price) ->
    null.

%% A number, or null for absent/non-numeric (the attach handler validates price presence;
%% this is the belt-and-braces so a malformed card never crashes the fill).
num_or_null(N) when is_number(N) -> N;
num_or_null(_)                   -> null.

%% A three-valued resolver verdict, made JSON-safe for the outcome snapshot:
%% true/false stay booleans; `undetermined` becomes an explicit marker (rather than
%% leaking the atom or collapsing silently to a bool).
tri_to_json(true)         -> true;
tri_to_json(false)        -> false;
tri_to_json(undetermined) -> <<"needs_determination">>.

%% --- IC3: framing the household financial facts into the profile outcome ------
%% buyer_profile PROJECTS the grouped fact-base storage into the flat profile outcome
%% (fact-model-unification.md §97); mortgage_finance REASONS over the projection
%% (serviceability). assessable_income is the canonical household income fact
%% (household_financials.income.assessable_income) — the gross assessable figure; lender
%% shading by income_stability / foreign_sourced_component is the reasoning layer's job.
%% null when no positive income is known — the honest-partial PENDING state that keeps
%% borrowing_capacity null.
-spec assessable_income(map()) -> number() | null.
assessable_income(Financials) ->
    Income = maps:get(<<"income">>, Financials, #{}),
    case maps:get(<<"assessable_income">>, Income, null) of
        I when is_number(I), I > 0 -> I;
        _                          -> null
    end.

%% F6 — the offshore/FX income portion lenders may haircut; passthrough (0 default,
%% the Mode-A domestic case). mortgage_finance reads this alongside the total.
-spec foreign_sourced(map()) -> number().
foreign_sourced(Financials) ->
    Income = maps:get(<<"income">>, Financials, #{}),
    num0(maps:get(<<"foreign_sourced_component">>, Income, 0)).

%% The raw debt facts (balances/limits) the serviceability resolver reads. Passthrough
%% of the household financials' debts sub-map; empty → no debt drag (no facts captured).
-spec debts(map()) -> map().
debts(Financials) ->
    case maps:get(<<"debts">>, Financials, #{}) of
        D when is_map(D) -> D;
        _                -> #{}
    end.

%% a number, or 0 for absent/non-numeric (matches fh_engine_mortgage:num0/1).
num0(N) when is_number(N) -> N;
num0(_)                   -> 0.

%% subst a kb.copy.profile template into a bilingual {vi,en} value (no Vietnamese
%% in Erlang literals; same mechanism as fh_engine_cash).
-spec copy(binary(), #{binary() => fh_engine_i18n:param()}) -> fh_engine_i18n:localized().
copy(Id, Params) ->
    fh_engine_i18n:subst(fh_engine_kb:copy(?COPY, Id), Params).
