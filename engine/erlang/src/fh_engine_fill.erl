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
%% residence_assumptions/1 is exported for firb_residence_conformance: the base turn only ever
%% projects the {citizen, PR} set, so the scalar-PR and citizen-only households are exercised
%% through the same function the profiles call.
-export([residence_assumptions/1]).

-define(COPY, <<"kb.copy.profile">>).   %% buyer_profile bilingual copy-templates (bilingual-content.md §3b)
-define(ENTITY_SETUP, <<"kb.tax.entity-setup-costs">>).  %% INDICATIVE setup bands by entity
-define(TARGET_YIELD, <<"kb.investor.target-yield-by-archetype">>).  %% labelled-placeholder defaults

%% Does this component have a resolver fill? Empty `agent_leaves` → pure resolver;
%% non-empty + has_resolver → TWO-PATH (the turn runs the resolver, then folds the
%% agent leaves via merge_agent/3); non-empty + no resolver → pure agent (the sidecar
%% fills the whole outcome — the later per-property valuation/negotiation components).
-spec has_resolver(binary()) -> boolean().
has_resolver(<<"buyer_profile">>)      -> true;
has_resolver(<<"investor_profile">>)   -> true;
has_resolver(<<"investor_profile_foreign">>) -> true;
has_resolver(<<"eligibility">>)        -> true;
has_resolver(<<"cash_position">>)      -> true;
has_resolver(<<"ownership_planning">>) -> true;
has_resolver(<<"ownership_planning_investor">>) -> true;
has_resolver(<<"mortgage_finance">>)   -> true;
has_resolver(<<"firb_workflow">>)      -> true;
has_resolver(<<"family_context">>)     -> true;
has_resolver(<<"cross_border_funding">>) -> true;
has_resolver(<<"investment_strategy">>) -> true;
has_resolver(<<"yield_modelling">>)    -> true;
has_resolver(<<"tax_structure">>)      -> true;
has_resolver(<<"tax_structure_non_resident">>) -> true;
has_resolver(<<"ownership_planning_foreign_investor">>) -> true;
has_resolver(<<"property_assessment">>) -> true;
has_resolver(<<"purchase_journey">>)   -> true;
has_resolver(<<"preparation">>)        -> true;
has_resolver(<<"phase_playbook">>)     -> true;
has_resolver(<<"disposition">>)        -> true;
has_resolver(<<"buying_strategy">>)    -> true;
has_resolver(<<"settlement_prep">>)    -> true;
has_resolver(<<"due_diligence">>)      -> true;
has_resolver(<<"existing_home_disposal">>) -> true;
has_resolver(_)                        -> false.

%% Honest-partial -> P-2 · The database is the single source of truth -> The engine -> firb_required_any defaults false
%% Args.firb_required_any discriminates FIRB/foreign paths in several resolvers, and a
%% missing key reads as `false` with no error. Every new turn starter must thread it from
%% facts_jsonb.derived, as fh_engine_h_rerun does. Measured 2026-07-11 on a live Mode-D
%% what-if turn that did not thread it.
-spec resolver(binary(), map(), map()) -> {map(), binary(), [map()]}.
resolver(<<"buyer_profile">>, Args, _Upstream) ->
    buyer_profile(Args);
resolver(<<"investor_profile">>, Args, _Upstream) ->
    investor_profile(Args);
resolver(<<"investor_profile_foreign">>, Args, _Upstream) ->
    investor_profile_foreign(Args);
resolver(<<"eligibility">>, Args, Upstream) ->
    fh_engine_eligibility:fill(Args, Upstream);
resolver(<<"cash_position">>, Args, Upstream) ->
    fh_engine_cash:fill(Args, Upstream);
resolver(<<"ownership_planning">>, Args, Upstream) ->
    fh_engine_ownership:fill(Args, Upstream);
resolver(<<"ownership_planning_investor">>, Args, Upstream) ->
    fh_engine_ownership:fill_investor(Args, Upstream);
resolver(<<"ownership_planning_foreign_investor">>, Args, Upstream) ->
    fh_engine_ownership:fill_foreign_investor(Args, Upstream);
resolver(<<"mortgage_finance">>, Args, Upstream) ->
    fh_engine_mortgage:fill(Args, Upstream);
resolver(<<"firb_workflow">>, Args, Upstream) ->
    fh_engine_firb:fill(Args, Upstream);
resolver(<<"family_context">>, Args, Upstream) ->
    fh_engine_family:fill(Args, Upstream);
resolver(<<"cross_border_funding">>, Args, Upstream) ->
    fh_engine_cross_border:fill(Args, Upstream);
resolver(<<"investment_strategy">>, Args, Upstream) ->
    investment_strategy(Args, Upstream);
resolver(<<"yield_modelling">>, _Args, Upstream) ->
    yield_modelling(Upstream);
resolver(<<"tax_structure">>, _Args, Upstream) ->
    tax_structure(Upstream);
resolver(<<"tax_structure_non_resident">>, _Args, Upstream) ->
    tax_structure_non_resident(Upstream);
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
resolver(<<"existing_home_disposal">>, Args, Upstream) ->
    fh_engine_existing_home_disposal:fill(Args, Upstream);
resolver(<<"buying_strategy">>, Args, Upstream) ->
    fh_engine_buying:fill(Args, Upstream);
resolver(<<"settlement_prep">>, Args, Upstream) ->
    fh_engine_settlement:fill(Args, Upstream);
resolver(<<"due_diligence">>, Args, Upstream) ->
    fh_engine_due_diligence:fill(Args, Upstream);
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
    Archetype = maps:get(<<"archetype">>, AgentValues, null),
    ResolverOutcome#{
        <<"archetype">>    => Archetype,
        <<"gearing_type">> => maps:get(<<"gearing_type">>, AgentValues, null),
        <<"one_liner">>    => maps:get(<<"one_liner">>, AgentValues, null),
        %% target_gross_yield is DERIVED from the agent's archetype via the labelled-placeholder
        %% KB defaults (kb.investor.target-yield-by-archetype) — the archetype is the agent's, the
        %% mapping to a number is the resolver's, so the figure stays out of the LLM's reach (§98).
        %% This is what makes buying_strategy's yield-anchored discipline non-dormant. null for
        %% land_banking (not yield-driven) and for an absent archetype (honest-partial).
        <<"target_gross_yield">> => target_yield_for(Archetype)
    };
%% tax_structure: the SINGLE entity_structuring leaf the sidecar authored
%% (recommended_entity). Slot-scoped fold — the agent reach is exactly this one judgment
%% field; every figure (the CGT determinants, the null property/seam-deferred money) is the
%% resolver scaffold's and is left untouched (§98 — the agent authors NO figure, NO verdict).
%% setup_costs is DERIVED from the agent's entity via the KB band (entity_setup_band/1) — the
%% entity is the agent's, the band is the resolver's, so the figure stays out of the LLM's reach
%% (a stray setup_costs in AgentValues is ignored), the same split as target_gross_yield above.
merge_agent(<<"tax_structure">>, ResolverOutcome, AgentValues) ->
    Entity = maps:get(<<"recommended_entity">>, AgentValues, null),
    ResolverOutcome#{
        <<"recommended_entity">> => Entity,
        <<"setup_costs">>        => entity_setup_band(Entity)
    };
%% tax_structure_non_resident (Mode D): identical single-leaf fold to tax_structure/2 above —
%% distinct component name, same shared `tax_optimised_structure` outcome type + agent-slot
%% shape, so the fold logic is byte-identical (a distinct clause keeps the outcome TYPE legible
%% at the call site, same discipline as fh_engine_mortgage's merge_agent_fhb_foreign/2).
merge_agent(<<"tax_structure_non_resident">>, ResolverOutcome, AgentValues) ->
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
%% buying_strategy: the SINGLE negotiation leaf the sidecar authored (negotiation_style).
%% Slot-scoped fold — the agent reach is exactly this one judgment field; every money figure
%% (the yield-anchored band, max_bid/walk_away, the conditions, the placed red flags) is the
%% resolver's and is left untouched (§98 — the agent authors NO price, NO figure).
merge_agent(<<"buying_strategy">>, ResolverOutcome, AgentValues) ->
    ResolverOutcome#{
        <<"negotiation_style">> =>
            maps:get(<<"negotiation_style">>, AgentValues, null)
    };
%% due_diligence (Mode C, Phase B — due_diligence B): fold the lease_interpretation leaves the
%% sidecar authored from the UPLOADED lease — the bilingual concerns, the high-severity lease
%% flags, the overall verdict, and the closing action. DOCUMENT-GATED two-path: this merge runs
%% ONLY on a `document` turn (effective_fill_path/2 fires the sidecar only when a lease is present
%% AND two_path_stored_leaf/2 returns `fresh` for kind=document), so reaching here means the lease
%% WAS reviewed → flip docs_status → reviewed and the lease checklist entry received/reviewed → true
%% (the other procurement items are not the uploaded doc). The agent's lease concerns APPEND to the
%% resolver's computable yield-vs-thesis concern; the resolver re-runs fresh each document turn so
%% there is no duplication. estimated_negotiation_lever (money) stays the resolver's null — no KB
%% methodology computes a lever from lease terms, and the agent authors NO figure (§98). The
%% declared PARAM leaf current_tenancy_unfavourable_terms (machine flags) informs the bilingual
%% concerns; it is not itself a risk_assessment_investor outcome field. (No agent_values_from_outcome
%% clause: due_diligence never takes the resolver-only reuse path — base_resolver never sweeps a
%% per-property component, a plain attach is resolver-only, a document turn is always fresh — so a
%% refresh that needed to reconstruct these merged lists cannot arise; the catch-all stays
%% fail-closed if a future trigger ever wrongly reaches it.)
merge_agent(<<"due_diligence">>, ResolverOutcome, AgentValues) ->
    ResolverConcerns = maps:get(<<"investor_specific_concerns">>, ResolverOutcome, []),
    AgentConcerns    = maps:get(<<"investor_specific_concerns">>, AgentValues, []),
    ResolverOutcome#{
        <<"docs_status">>                => <<"reviewed">>,
        <<"overall_verdict">>            => maps:get(<<"overall_verdict">>, AgentValues, null),
        <<"document_checklist">>         => mark_lease_reviewed(
                                              maps:get(<<"document_checklist">>, ResolverOutcome, [])),
        <<"investor_specific_concerns">> => ResolverConcerns ++ AgentConcerns,
        <<"high_severity_flags">>        => maps:get(<<"high_severity_flags">>, AgentValues, []),
        <<"next_action_for_user">>       => maps:get(<<"next_action_for_user">>, AgentValues,
                                              maps:get(<<"next_action_for_user">>, ResolverOutcome, null))
    };
merge_agent(Other, _ResolverOutcome, _AgentValues) ->
    erlang:error({no_agent_merge_for, Other}).

%% flip the lease document-checklist entry received/reviewed → true once the uploaded lease has
%% been interpreted (the other procurement items stay as the resolver set them — they are not the
%% uploaded doc). Pure list rewrite; an absent lease entry leaves the checklist unchanged.
mark_lease_reviewed(Checklist) when is_list(Checklist) ->
    [case maps:get(<<"id">>, Item, undefined) of
         <<"lease">> -> Item#{<<"received">> => true, <<"reviewed">> => true};
         _           -> Item
     end || Item <- Checklist];
mark_lease_reviewed(Other) ->
    Other.

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
%% tax_structure_non_resident: inverse of merge_agent(<<"tax_structure_non_resident">>, ...) —
%% byte-identical recovery shape to tax_structure's, distinct clause for the same reason as above.
agent_values_from_outcome(<<"tax_structure_non_resident">>, Stored) ->
    #{<<"recommended_entity">> => maps:get(<<"recommended_entity">>, Stored, null)};
%% buying_strategy: recover the single negotiation leaf verbatim from the snapshot (the inverse
%% of merge_agent/3) so a resolver-only refresh re-runs the scaffold (fresh anchored band off
%% the current rent + thesis) and re-attaches the stored style WITHOUT a sidecar call.
agent_values_from_outcome(<<"buying_strategy">>, Stored) ->
    #{<<"negotiation_style">> => maps:get(<<"negotiation_style">>, Stored, null)};
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

%% --- buyer_profile (dispatcher) ----------------------------------------------
%% Mode B (foreign-person) reuses the SAME component name as Mode A (unlike Mode C's
%% distinct `investor_profile`), and buyer_profile is the pipeline entry — no upstream
%% outcome exists yet to sniff a shape from (the mechanism mortgage_finance/cash_position
%% use to tell Mode A from Mode C). Discriminator: Args.firb_required_any — the SAME flag
%% the compliance FIRB gate already keys on (fh_engine_compliance:firb/4, gated on
%% Ctx.firb_required_any) and the one Mode-B/D onboarding sets today via
%% fh_engine_h_messages:firb_required_any/1. Reusing it gives resolver dispatch and the
%% compliance gate one definition of "a foreign-person turn" (mode-b-wedge.md P2).
buyer_profile(Args) ->
    case maps:get(firb_required_any, Args, false) of
        true  -> buyer_profile_foreign(Args);
        false -> buyer_profile_domestic(Args)
    end.

%% --- buyer_profile (Mode A, real) --------------------------------------------
%% The pipeline entry: project the onboarding fact base into the `profile` outcome.
%% At the onboarding turn the deep applicant facts (citizenship, age, income,
%% ownership history) are not yet gathered — those arrive via chat/uploads on a
%% later refine turn (which will load the enriched profile from the profiles SOT).
%% So the base projection carries the onboarding subset + a minimal lead applicant;
%% FIRB derives conservatively (Mode A enters via a non-foreign lead → false).

buyer_profile_domestic(Args) ->
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
        %% off_title_parties[] is the canonical fact SOT (P0.4 / fact-model-unification.md
        %% "Mode-B activation"): people linked to the purchase but not on title — a
        %% non-buying partner (couple-as-one role) and/or a funder (Mode B). Base default
        %% is [] (single-lead onboarding); a refine turn that reveals an off-title party
        %% populates it. Read BY ROLE FLAG, not position (architecture §11.9 off_title.*).
        <<"off_title_parties">> => [],
        %% non_buying_partner is the DERIVED couple-as-one read-model the KB scheme gates
        %% read (F4/G2) — the dyadic ≤1 head of off_title_parties[] filtered by role flag.
        %% The role-flag FILTER lives here (Erlang), keeping the KB predicate language
        %% simple; exists=false makes the gate pass (base, no partner). couple_as_one_view/1
        %% enforces the dyadic invariant fail-closed.
        <<"non_buying_partner">> => couple_as_one_view([]),
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
        <<"key_strengths">>   => [copy(<<"strength_first_home_buyer">>, #{})],
        <<"key_assumptions">> => residence_assumptions(Applicants)
    },
    KbVersions = fh_engine_kb:kb_anchors(
        [<<"kb.hecs.thresholds">>, <<"kb.firb.status-determination">>,
         <<"kb.lender.serviceability-basics">>]),
    {Outcome, <<"summary-card">>, KbVersions}.

%% --- buyer_profile (Mode B, foreign-person variant, real) --------------------
%% The Mode-B pipeline entry (blueprint fhb-foreign-au.md component 1). EVERY Mode-B
%% applicant is a foreign person under FIRB BY DEFINITION — this is a mode-selection
%% constant, not a resolver derivation over a possibility set the way Mode A/C project
%% citizenship (there is no "might be foreign" branch inside Mode B; entering this
%% branch at all already means Args.firb_required_any = true). So firb_status =
%% foreign_person / firb_required = true / firb_required_any = true are asserted
%% directly (blueprint outcome note: "Published from a foreign mode (true
%% definitionally) = the F14 close"), and fh_engine_resolver:eval_applicants is not
%% invoked here (nothing to resolve — the fact is given, not derived).
%% The deep applicant facts (exact citizenship_status enum, visa_class, tax residency,
%% income) are genuinely UNKNOWN at onboarding — arrive via chat on a refine turn
%% (same honest-partial discipline as Mode A/C, applied to a foreign-person applicant
%% instead of a possibility-set one). Canonical `profile` outcome shape (identity-layer
%% conformance note, fhb-foreign-au.md component 1) — NOT a private profile_foreign
%% type, same as Mode A/C; target_price_range/target_zone/hold_horizon_years carried
%% through even though the blueprint's own outcome-fields listing omits them (every
%% other mode's profile carries them and downstream Mode-B components need them —
%% flagged as a blueprint-doc gap, not fixed here; see mode-b-wedge.md P2 notes).
buyer_profile_foreign(Args) ->
    Onboarding = maps:get(onboarding, Args, #{}),
    Financials = maps:get(household_financials, Args, #{}),
    TargetRange = maps:get(<<"target_price_range">>, Onboarding, null),
    TargetZone = maps:get(<<"target_zone">>, Onboarding, []),
    %% Mode-B definitional applicant: a foreign person under FIRB. The eligibility- and
    %% tax-bearing specifics (exact citizenship_status, visa_class, tax.residency_for_tax,
    %% taxable_income_aud, employment_status) are unfilled at onboarding — honest-partial
    %% null, captured on a refine turn. jurisdiction is fixed AU (Mode B reasons on the
    %% AU-side tax position only; VN-side parent tax is a labelled placeholder).
    Applicant = #{
        <<"role">> => <<"primary">>,
        <<"citizenship_status">> => null,
        <<"firb_status">> => <<"foreign_person">>,
        <<"firb_required">> => true,
        <<"visa_class">> => null,
        <<"visa_grant_date">> => null,
        <<"residency_duration_months">> => null,
        <<"taxable_income_aud">> => null,
        <<"tax">> => #{
            <<"residency_for_tax">> => null,
            <<"marginal_rate">> => null,
            <<"jurisdiction">> => <<"AU">>
        },
        <<"employment_status">> => null
    },
    Outcome = #{
        <<"applicants">> => [Applicant],
        <<"applicant_count">> => 1,
        %% definitional for Mode B (the household aggregate, the F14 close) — no
        %% resolver derivation needed, unlike Mode A/C's possibility-set projection.
        <<"firb_required_any">> => true,
        %% the VN funding parent (funder role, off_title_parties[].funder) is captured
        %% on a refine turn, not at onboarding — [] mirrors Mode A/C's honest-partial
        %% base default (single-lead onboarding).
        <<"off_title_parties">> => [],
        <<"assessable_income">> => assessable_income(Financials),
        %% non-resident-lender-flavoured borrowing capacity is computed downstream by
        %% mortgage_finance's foreign variant (blueprint note) — PENDING here.
        <<"approx_borrowing_capacity">> => null,
        %% AU-side savings + funder contributions are both unset at base (no savings
        %% captured, off_title_parties empty) — PENDING, refines once either arrives.
        <<"deposit_ready_for_purchase_amount">> => null,
        <<"debts">> => debts(Financials),
        <<"target_price_range">> => TargetRange,
        <<"target_zone">> => TargetZone,
        <<"hold_horizon_years">> => maps:get(<<"hold_horizon_years">>, Onboarding, null),
        %% disposition's CGT determinants (task 11, plan-card-lifecycle-restoration.md §11.4):
        %% intended_occupancy_use is DEFINITIONAL for Mode B, same call as Mode A's own —
        %% Mode B is an owner-occupier FHB by mode definition (sole_occupier), not a
        %% possibility-set projection. tax_residency is DELIBERATELY OMITTED, unlike Mode A's
        %% (which asserts "resident" — a citizen/PR is definitionally an AU tax resident).
        %% A Mode-B applicant's tax residency is genuinely unknown at base (foreign person,
        %% possibly a temp resident, possibly not yet in Australia) and CGT-consequential
        %% (the 2019 non-resident CGT main-residence-exemption removal — kb.tax.cgt-main-
        %% residence-exemption) — asserting "resident" would be an unsafe default exactly
        %% where the trap applies. Left unset, fh_engine_disposition:cgt/1 falls through to
        %% its to_verify branch (never exempt) — the honest, safe-by-construction result.
        <<"intended_occupancy_use">> => <<"sole_occupier">>,
        %% bilingual {vi,en} via kb.copy.profile. financials-pending is mode-neutral
        %% (reused from A/C); the Mode-B strength states the definitional position
        %% (a structured, FIRB-aware plan from day one) — decision-support tone, not
        %% "you should", same discipline as strength_domestic_investor.
        <<"key_constraints">> => [copy(<<"constraint_financials_pending">>, #{})],
        <<"key_strengths">>   => [copy(<<"strength_cross_border_family_plan">>, #{})]
    },
    KbVersions = fh_engine_kb:kb_anchors(
        [<<"kb.firb.established-dwelling-ban">>,
         <<"kb.visas.au-temporary-residency-classes">>,
         <<"kb.au-temp-residents.banking-and-tax-basics">>]),
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
        <<"key_strengths">>   => [copy(<<"strength_domestic_investor">>, #{})],
        <<"key_assumptions">> => residence_assumptions(Applicants)
        %% ABSENT (→ null → honest-partial): existing_portfolio, traits,
        %% deposit_ready_for_purchase_amount, ppor_equity_available_for_leverage,
        %% approx_borrowing_capacity — gathered on a refine turn (profiles SOT).
    },
    KbVersions = fh_engine_kb:kb_anchors(
        [<<"kb.firb.status-determination">>, <<"kb.tax.income-tax-resident-2026-27">>,
         <<"kb.lender.serviceability-investment-loans">>,
         <<"kb.investor.experience-levels">>]),
    {Outcome, <<"summary-card">>, KbVersions}.

%% --- investor_profile_foreign (Mode D, real) ----------------------------------
%% The Mode-D pipeline entry (blueprint investor-foreign-au.md component 1 — a straight
%% MERGE of Mode B's buyer_profile foreign-person lens + Mode C's investor_profile tax{}
%% lens, per fact-model-unification.md "Mode D adds no new identity-layer generalization —
%% only content"). Canonical `profile` outcome shape (2026-07-03 outcome-type conformance
%% reconciliation) — NOT a private investor_profile_foreign_summary type, same discipline as
%% buyer_profile_foreign. Distinct component name from both buyer_profile and investor_profile
%% ⟹ zero Mode-A/B/C reach.
%%
%% CRITICAL: applicant.tax.residency_for_tax = non_resident is DEFINITIONAL for Mode D — a
%% genuinely Vietnam-located investor is never an AU tax resident, not a possibility-set
%% projection the way Mode A/C project citizenship. This is the field
%% fh_engine_disposition:all_resident/1 reads to route the shared investor CGT path
%% (cgt_investor/4) to `to_verify` — never the resident "computed" path — for every Mode D
%% turn, by construction (misadvice-critical; see the blueprint's own "outcome-type
%% conformance" §cgt_status note). jurisdiction stays AU-only (the AU-side-full/VN-side-
%% placeholder scoping decision, mode-d-wedge.md 2026-07-03) — Mode D reasons on the AU tax
%% position; VN-side tax on the AU-sourced income is the buyer's own VN tax advisor's job.
investor_profile_foreign(Args) ->
    Onboarding = maps:get(onboarding, Args, #{}),
    Financials = maps:get(household_financials, Args, #{}),
    TargetRange = maps:get(<<"target_price_range">>, Onboarding, null),
    TargetZone = maps:get(<<"target_zone">>, Onboarding, []),
    %% Mode-D definitional applicant: a foreign person under FIRB (mirrors buyer_profile_
    %% foreign) AND non-resident for AU tax (definitional — never assessed for MODE C's
    %% resident possibility-set). The deep applicant facts (VN citizenship class, co-investor
    %% detail) are genuinely unknown at onboarding — captured via chat on a refine turn.
    Applicant = #{
        <<"role">> => <<"primary">>,
        <<"citizenship_status">> => null,
        <<"firb_status">> => <<"foreign_person">>,
        <<"firb_required">> => true,
        <<"tax">> => #{
            <<"residency_for_tax">> => <<"non_resident">>,
            <<"jurisdiction">> => <<"AU">>
        }
    },
    Outcome = #{
        <<"applicants">> => [Applicant],
        <<"applicant_count">> => 1,
        %% definitional for Mode D (the household aggregate, mirrors buyer_profile_foreign's
        %% F14 close) — no resolver derivation needed, unlike Mode A/C's possibility-set
        %% projection over citizenship.
        <<"firb_required_any">> => true,
        %% single-owner: the established-dwelling-ban window is fh_engine_firb's (ban_applies/0,
        %% exported for exactly this early-display read — [[place-upstream-figures-dont-recompute]],
        %% no second window-date literal here). firb_workflow (component 3) remains the
        %% AUTHORITATIVE per-property eligibility verdict once a property attaches.
        <<"established_property_eligible">> => not fh_engine_firb:ban_applies(),
        <<"new_build_only_constraint">> => true,
        %% co-investor (spouse/business-partner/family-pool) captured on a refine turn — []
        %% mirrors every other mode's honest-partial single-lead-onboarding base default.
        <<"off_title_parties">> => [],
        <<"assessable_income">> => assessable_income(Financials),
        <<"foreign_sourced_income_component">> => foreign_sourced(Financials),
        <<"debts">> => debts(Financials),
        <<"target_price_range">> => TargetRange,
        <<"target_zone">> => TargetZone,
        <<"hold_horizon_years">> => maps:get(<<"hold_horizon_years">>, Onboarding, null),
        %% Mode-D-specific (blueprint params: value "<initial>", no derivation rule) — genuinely
        %% unset at onboarding; captured on a refine turn (VN tax bracket, available capital,
        %% experience, goal, FX-volatility comfort).
        <<"vn_marginal_tax_rate">> => null,
        <<"available_capital_aud_equivalent">> => null,
        <<"experience_level">> => null,
        <<"primary_investment_goal">> => null,
        <<"currency_volatility_concern">> => null,
        %% bilingual {vi,en} via kb.copy.profile. financials-pending is mode-neutral (reused);
        %% the Mode-D strength states the definitional position (FIRB + non-resident tax +
        %% cross-border funding surfaced from day one) — decision-support tone, not "you
        %% should invest" (ASIC line).
        <<"key_constraints">> => [copy(<<"constraint_financials_pending">>, #{})],
        <<"key_strengths">>   => [copy(<<"strength_foreign_investor">>, #{})]
        %% ABSENT (→ null → honest-partial): existing_portfolio detail, prior_firb_approvals,
        %% source_of_funds_documentation_ready — gathered on a refine turn (profiles SOT).
    },
    KbVersions = fh_engine_kb:kb_anchors(
        [<<"kb.firb.established-dwelling-ban">>,
         <<"kb.vn-tax.brackets-2026">>, <<"kb.vn-tax.income-from-foreign-property">>,
         <<"kb.lender.non-resident-friendly-shortlist">>, <<"kb.investor.experience-levels">>]),
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
%%
%% MODE DISPATCH (mirrors fh_engine_mortgage/fh_engine_cash): `investment_strategy` is the
%% SAME component name across Mode C and Mode D, both producing the canonical `strategy_thesis`
%% type (investor-foreign-au.md "outcome-type conformance" note, 2026-07-03 reconciliation).
%% Discriminated by Args.firb_required_any — the same flag buyer_profile/1, mortgage_finance,
%% cash_position key on. The Mode-C body is renamed investment_strategy_domestic/1 VERBATIM
%% (byte-identical — zero regression); investment_strategy_foreign/1 is new.
investment_strategy(Args, Upstream) ->
    case maps:get(firb_required_any, Args, false) of
        true  -> investment_strategy_foreign(Upstream);
        false -> investment_strategy_domestic(Upstream)
    end.

investment_strategy_domestic(Upstream) ->
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
         <<"kb.investor.exit-strategy-options">>,
         <<"kb.investor.target-yield-by-archetype">>]),
    {Outcome, <<"summary-card">>, KbVersions}.

%% --- investment_strategy (Mode D, two-path RESOLVER half) --------------------
%% The Mode-D investment thesis (blueprint investor-foreign-au.md component 4): identical
%% two-path shape to investment_strategy_domestic/1 (same three agent leaves, same
%% merge_agent/3 + agent_values_from_outcome/2 clauses — no mode branch needed there), plus
%% two Mode-D-specific RESOLVER fields the blueprint does NOT mark agent_reasoning_required
%% (migration_pathway_alignment, currency_hedging_strategy — user-preference facts, not agent
%% judgment): honest-partial null at base, same as every other onboarding-captured leaf
%% (base-turn-honest-partial-output). hold_period_years carries the SAME upstream horizon
%% carry as the domestic variant (profile.hold_horizon_years — canonical across A/B/C/D).
investment_strategy_foreign(Upstream) ->
    Profile = maps:get(<<"profile">>, Upstream, #{}),
    Outcome = #{
        <<"archetype">>    => null,
        <<"gearing_type">> => null,
        <<"one_liner">>    => null,
        <<"target_gross_yield">>    => null,
        <<"target_capital_growth">> => null,
        <<"target_lvr">>            => null,
        <<"hold_period_years">> => maps:get(<<"hold_horizon_years">>, Profile, null),
        <<"exit_strategy">> => null,
        %% Mode-D-specific — genuinely unset at onboarding (blueprint params: value "<initial>",
        %% no derivation rule); captured on a refine turn.
        <<"migration_pathway_alignment">>  => null,
        <<"currency_hedging_strategy">>    => null,
        <<"is_property_aligned_with_thesis">> => null
    },
    KbVersions = fh_engine_kb:kb_anchors(
        [<<"kb.investor.strategy-archetypes">>,
         <<"kb.investor.gearing-types-and-implications">>,
         <<"kb.investor.hold-period-considerations">>,
         <<"kb.investor.exit-strategy-options">>,
         <<"kb.investor.target-yield-by-archetype">>,
         <<"kb.foreign-investor.thesis-archetypes">>,
         <<"kb.foreign-investor.currency-hedging-considerations">>,
         <<"kb.foreign-investor.future-migration-pathway-considerations">>]),
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
%% HONEST-PARTIAL NULL, in two deferral classes (Slice B2 lights up class (a)):
%%   (a) property/rent + income-dependent — negative_gearing_active + the tax-refund / after-tax
%%       cash-flow figures hang off the rental cash flow (cash_flow_projection from yield_modelling,
%%       which runs BEFORE this — DAG: yield→tax→cash) AND the marginal rate (profile.assessable_income).
%%       Each lights up only when its inputs are present (tax_figures/2): the gearing position needs
%%       only the cash flow (per-property turn); the money figures also need income (a refine turn —
%%       plan-first onboarding carries no income, exactly like mortgage borrowing capacity). null
%%       when absent → disposition CGT to_verify (the conservative net). total_depreciation stays
%%       null — the KB defers the Div-43/40 dollar to a QS (kb.tax.depreciation-division-43-and-40),
%%       never asserts it.
%%   (b) entity-dependent: setup_costs is placed at merge from the agent's entity as the KB band
%%       (entity_setup_band/1, kb.tax.entity-setup-costs; #12). annual_compliance_cost stays null —
%%       the KB's ongoing figures are text ("1000-3500+", "accounting + audit"), not a band yet.
%%
%% The agent's reach is exactly the one entity leaf — no figure, no verdict (the
%% entity-comparison KB is the most regulated content in the wedge; the sidecar's single-enum
%% output schema removes every figure from its reach, and the ASIC posture — a starting
%% structure to confirm with a licensed professional, never a directive — is enforced in the
%% entity_structuring prompt). Every figure below is resolver-computed, removed from the LLM's
%% reach (§98). [Doc/schema seam, flagged not patched: the regulated entity recommendation has NO
%% `reasoning` field in the compiled outcome — a separate outcome-schema unit. And the announced
%% negative-gearing reform (limited to new builds from 1 Jul 2027; an established post-Budget
%% purchase loses the wage offset — kb.tax.negative-gearing-mechanics) has no outcome field to flag
%% it: a separate blueprint-schema + renderer unit, material to the wedge's own target case.]
tax_structure(Upstream) ->
    Cfp     = maps:get(<<"cash_flow_projection">>, Upstream, #{}),
    Profile = maps:get(<<"profile">>, Upstream, #{}),
    Income  = maps:get(<<"assessable_income">>, Profile, null),
    Pf      = maps:get(<<"property_fit_investor">>, Upstream, undefined),
    %% scaffold (all-null figures + the two CGT determinant constants + the agent slot), then
    %% the per-property/income figures override it — base (no cash flow, no income) ⟹ unchanged.
    %% The reform note is property-conditional (ng_reform_note/1) and NEVER null (base ⟹ the
    %% general caveat), so it overrides the scaffold placeholder regardless of the figure inputs.
    Outcome0 = (maps:merge(tax_structure_scaffold(), tax_figures(Cfp, Income)))
                   #{<<"negative_gearing_reform_note">> => ng_reform_note(Pf)},
    Outcome  = Outcome0#{<<"cash_events">> => tax_cash_events(Outcome0)},
    KbVersions = fh_engine_kb:kb_anchors(
        [<<"kb.tax.entity-comparison-personal-trust-company-smsf">>,
         <<"kb.tax.negative-gearing-mechanics">>,
         <<"kb.tax.depreciation-division-43-and-40">>,
         <<"kb.tax.cgt-50-percent-discount">>,
         <<"kb.tax.quantity-surveyor-reports">>,
         <<"kb.tax.land-tax-by-state">>,
         ?ENTITY_SETUP]),
    {Outcome, <<"data-table">>, KbVersions}.

%% the input-independent scaffold: the entity agent slot (null pre-merge), the two KB-grounded CGT
%% determinant CONSTANTS the disposition consumer reads, and every figure null (overridden below).
tax_structure_scaffold() ->
    #{
        %% AGENT slot (entity_structuring) — null here; merge_agent/3 folds the sidecar's one
        %% leaf. A base_resolver refresh re-attaches the stored entity (no LLM).
        <<"recommended_entity">> => null,
        %% RESOLVER — KB-grounded boolean constants (the CGT determinants disposition reads).
        <<"cgt_discount_eligible">>           => true,
        <<"cost_base_depreciation_clawback">> => true,
        %% figures — null until their inputs arrive (tax_figures/2 overrides).
        <<"negative_gearing_active">>      => null,
        <<"annual_tax_refund_year_1">>     => null,
        <<"after_tax_cash_flow_year_1">>   => null,
        <<"after_tax_cash_flow_per_week">> => null,
        <<"total_depreciation_year_1">>    => null,  %% QS-deferred (no schedule in reach)
        <<"cgt_marginal_rate">>            => null,
        <<"setup_costs">>                  => null,  %% placed at merge from the entity (class b)
        <<"annual_compliance_cost">>       => null,  %% entity-cost banded-vs-scalar seam (class b)
        <<"negative_gearing_reform_note">> => null   %% placeholder — tax_structure/1 always overrides
    }.

%% the rent/cash-flow + income-dependent figures (class a), each honest-partial. Returns the
%% overrides merged onto the all-null scaffold (B2).
tax_figures(Cfp, Income) ->
    Cf     = maps:get(<<"cash_flow_before_tax_year_1">>, Cfp, null),
    Geared = maps:get(<<"is_positive_neutral_or_negative_geared_pre_tax">>, Cfp, null),
    Rate   = case Income of I when is_number(I) -> fh_engine_mortgage:marginal_rate(I); _ -> null end,
    Ng     = negative_gearing(Geared),
    maps:merge(
        #{<<"negative_gearing_active">> => Ng, <<"cgt_marginal_rate">> => Rate},
        refund_figures(Ng, Cf, Rate)).

%% negative gearing is ACTIVE iff the pre-tax cash position is a loss (yield's geared = negative);
%% never assert FALSE for a cash-positive/neutral property — depreciation (QS-deferred,
%% kb.tax.depreciation-division-43-and-40) can make it tax-negative while cash-positive, so the
%% tax position is undetermined → null (honest-partial). PLACES yield's classification (no recompute,
%% [[place-upstream-figures-dont-recompute]]).
negative_gearing(<<"negative">>) -> true;
negative_gearing(_)              -> null.

%% the negative-gearing refund + after-tax cash flow — computed ONLY when negatively geared AND the
%% marginal rate is known (income captured). after-tax = Cf × (1 − r); refund = −r × Cf (the tax
%% saving on the loss). Bands (Cf is banded, r a point). Depreciation is EXCLUDED from the loss
%% (QS-deferred) → understates the refund → MORE-negative after-tax = the conservative direction.
refund_figures(true, [CfLo, CfHi], Rate) when is_number(Rate) ->
    F = (100 - Rate) / 100,
    {AtLo, AtHi} = {round(CfLo * F), round(CfHi * F)},
    #{<<"annual_tax_refund_year_1">>     => [round(-Rate / 100 * CfHi), round(-Rate / 100 * CfLo)],
      <<"after_tax_cash_flow_year_1">>   => [AtLo, AtHi],
      <<"after_tax_cash_flow_per_week">> => [round(AtLo / 52), round(AtHi / 52)]};
refund_figures(_, _, _) ->
    #{}.

%% --- cash_events (investor hold-phase spine, the tax-refund leg) -------------
%% Mirrors fh_engine_cash's event shape; purchase_journey's generic multi-source harvest
%% places this on the swimlane's Own/Hold column with zero Mode-C-specific journey code
%% ([[unify-views-as-projections-of-one-primitive]]). Recurring/year (the Own phase is a
%% steady state, not a one-off). Honest-partial: no event when the refund is null (base, or
%% not negatively geared / income not yet captured).
tax_cash_events(Outcome) ->
    Out = [hold_event(<<"tax_refund">>, <<"event_tax_refund">>, <<"in">>,
                      maps:get(<<"annual_tax_refund_year_1">>, Outcome, null),
                      <<"government">>, <<"tax_structure">>, <<"kb.copy.tax-structure">>)],
    [E || E <- Out, maps:get(<<"amount">>, E) =/= null].

%% shared by tax_structure's/yield_modelling's Own-phase (recurring/year) cash events —
%% the counterpart to fh_engine_cash's event/8 (which builds the one_off acquisition
%% events); a scalar figure collapses to [v, v] (money_range, matching the registry type),
%% a band passes through as-is, null passes through (the caller filters it).
hold_event(Id, LabelCopyId, Dir, Amount, Counterparty, Source, CopyDoc) ->
    #{<<"id">>               => Id,
      <<"phase">>            => <<"own">>,
      <<"label">>            => fh_engine_kb:copy(CopyDoc, LabelCopyId),
      <<"direction">>        => Dir,
      <<"amount">>           => hold_amount(Amount),
      <<"is_estimate">>      => true,
      <<"timing">>           => <<"recurring">>,
      <<"period">>           => <<"year">>,
      <<"counterparty">>     => Counterparty,
      <<"source_component">> => Source}.

hold_amount([Lo, Hi]) when is_number(Lo), is_number(Hi) -> [Lo, Hi];
hold_amount(V) when is_number(V) -> [V, V];
hold_amount(_) -> null.

%% The announced 2026-27 Budget negative-gearing reform (NG limited to new builds from 1 Jul 2027;
%% PROPOSED, not yet law — kb.tax.negative-gearing-mechanics). Surfaced as a bilingual decision-
%% support caveat, removed from the LLM's reach (§98 / [[no-judge-ground-the-producer]]): the
%% resolver SELECTS the note by the attached property's established-vs-new classification; the agent
%% never authors it. The fact is the KB's (ATO-verified); this only renders it bilingually
%% (kb.copy.tax-structure). An ESTABLISHED purchase made now loses the wage offset; a NEW build keeps
%% it; absent a property (base), the applicability is per-property → the general caveat (honest-
%% partial). NEVER null — the reform is a public fact regardless of the property. Never models the
%% unenacted law as settled; the copy points to a registered tax agent (the ASIC/TPB line).
ng_reform_note(undefined) -> tax_copy(<<"reform_base">>);
ng_reform_note(Pf) ->
    case maps:get(<<"property_type">>, Pf, undefined) of
        <<"established_house">>     -> tax_copy(<<"reform_established">>);
        <<"established_apartment">> -> tax_copy(<<"reform_established">>);
        undefined                   -> tax_copy(<<"reform_base">>);
        _NewBuild                   -> tax_copy(<<"reform_new_build">>)
    end.

%% the tax_structure copy doc (distinct from the module-level ?COPY = kb.copy.profile that
%% buyer_profile/investor_profile use); read by slug at runtime, no substitution params.
tax_copy(Id) ->
    fh_engine_i18n:subst(fh_engine_kb:copy(<<"kb.copy.tax-structure">>, Id), #{}).

%% --- tax_structure_non_resident (Mode D, two-path RESOLVER half) -------------
%% The Mode-D investor base spine (blueprint investor-foreign-au.md component 7): the
%% non-resident tax-optimised ownership structure. TWO-PATH like tax_structure/1: the
%% SIDECAR (reasoning_domain entity_structuring, same domain, a non-resident-flavoured
%% entity enum) authors the ONE irreducible judgment leaf — recommended_entity — folded by
%% merge_agent(<<"tax_structure_non_resident">>, ...) below. DISTINCT component name from
%% Mode C's tax_structure (no shared-name collision — the two coexist, unlike mortgage_
%% finance/cash_position's within-name branching), but the SAME canonical `tax_optimised_
%% structure` outcome TYPE (2026-07-03 outcome-type conformance reconciliation) — this is
%% what lets the ALREADY-BUILT fh_engine_disposition/fh_engine_cash investor dispatch (which
%% sniffs `tax_optimised_structure`'s PRESENCE, not the producing component's name) route a
%% Mode-D turn onto the SAME investor path Mode C uses, with zero disposition/cash_position
%% mode-branch needed for that routing decision.
%%
%% RESOLVER computes (KB-grounded, DEFINITIONAL — no holding-period conditional the way Mode
%% C's cgt_discount_eligible is, per kb.tax.cgt-50-percent-discount's own foreign-resident
%% carve-out from 8 May 2012):
%%   - cgt_discount_eligible = false: NEVER available to a foreign resident (definitional).
%%   - ppor_exemption_eligible = false: MOOT, not removed — the property was never a main
%%     residence for a Mode-D investor (kb.non-resident.tax-treatment-overview's PPOR-moot
%%     reasoning; contrast Mode B's owner-occupier-turned-foreign-resident case, where the
%%     exemption WAS removed).
%%   - frcgw_applicable = true: definitional (kb.non-resident-tax.foreign-resident-cgt-
%%     withholding) — every foreign-resident vendor's sale is subject to the withholding
%%     mechanism; read by fh_engine_disposition to add the FRCGW figure.
%%   - cost_base_depreciation_clawback = true: Div 43 capital works claimed reduces the cost
%%     base (kb.tax.depreciation-division-43-and-40), same reasoning as Mode C's constant.
%%   - negative_gearing_available_against_au_income = true: a non-resident's AU-source rental
%%     loss can offset OTHER AU-source income (never foreign income) — structural, not
%%     figure-dependent (kb.non-resident.tax-treatment-overview).
%%   - rental_withholding_rate = null, WITH AN ASSESSMENT NOTE, not a rate: directly-held AU
%%     rental income is NOT subject to a final withholding tax — it is taxed by ASSESSMENT
%%     via a lodged return (kb.non-resident-tax.withholding-on-rental-income's own P1
%%     correction — see mode-d-wedge.md; do NOT hardcode a rate here, that would assert the
%%     wrong mechanism). annual_au_tax_payable_on_rental therefore needs the ASSESSED figure,
%%     which needs income + the non-resident marginal schedule — both absent at base.
%%
%% HONEST-PARTIAL NULL (no non-resident income-tax-bracket KB doc exists yet — flagged, not
%% invented; and the property/rent-dependent figures are absent at base, mirroring Mode C's
%% own tax_figures/2 deferral): cgt_marginal_rate, annual_au_tax_payable_on_rental,
%% annual_depreciation_year_1 (QS-deferred, same as Mode C's total_depreciation_year_1),
%% annual_compliance_cost_au (the entity-cost banded-vs-scalar seam, same class as Mode C's
%% setup_costs). vn_tax_treaty_relief_applicable stays null — VN-side tax relief is explicitly
%% out of the AU-side-full/VN-side-placeholder scope (mode-d-wedge.md 2026-07-03 scoping
%% decision); no AU-side treaty rate modification was identified during P1 authoring.
%%
%% The agent's reach is exactly the one entity leaf — no figure, no verdict (§98). Every
%% figure/boolean above is resolver-computed, removed from the LLM's reach.
tax_structure_non_resident(_Upstream) ->
    Outcome = #{
        %% AGENT slot (entity_structuring) — null here; merge_agent/3 folds the sidecar's
        %% one leaf (a non-resident-flavoured entity enum — personal_sole_non_resident etc.).
        <<"recommended_entity">> => null,
        %% RESOLVER — KB-grounded, definitional booleans (the CGT determinants disposition/
        %% cash_position read).
        <<"cgt_discount_eligible">>           => false,
        <<"ppor_exemption_eligible">>         => false,
        <<"frcgw_applicable">>                => true,
        <<"cost_base_depreciation_clawback">> => true,
        <<"negative_gearing_available_against_au_income">> => true,
        %% honest-partial null — no non-resident marginal-rate KB table built yet; no income
        %% captured at base regardless (household_financials empty at onboarding).
        <<"cgt_marginal_rate">> => null,
        %% assessment, not withholding — no rate applies (see the module note above).
        <<"rental_withholding_rate">> => null,
        <<"annual_au_tax_payable_on_rental">> => null,
        <<"annual_depreciation_year_1">> => null,
        <<"annual_compliance_cost_au">> => null,
        <<"vn_tax_treaty_relief_applicable">> => null,
        %% Honest empty (task 8, 2026-07-10): the hold-phase figure this would place an
        %% event from — annual_au_tax_payable_on_rental — is null at base AND per-property
        %% (no non-resident marginal-rate KB table exists yet, per this function's own note
        %% above). A helper here would be permanently-dead code; [] is conformant with the
        %% shared tax_optimised_structure type (Mode C's tax_structure emits the analogous
        %% empty array at base too) and honest — never a fabricated event.
        <<"cash_events">> => []
    },
    KbVersions = fh_engine_kb:kb_anchors(
        [<<"kb.non-resident.tax-treatment-overview">>,
         <<"kb.tax.cgt-50-percent-discount">>,
         <<"kb.non-resident.entity-options-au-property">>,
         <<"kb.au-vn-tax-treaty">>,
         <<"kb.tax.depreciation-division-43-and-40">>,
         <<"kb.non-resident-tax.withholding-on-rental-income">>,
         <<"kb.non-resident-tax.foreign-resident-cgt-withholding">>]),
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
    Outcome0 = case maps:get(<<"property_fit_investor">>, Upstream, undefined) of
                  Pf when is_map(Pf), map_size(Pf) > 0 ->
                      cash_flow_projection(
                          maps:get(<<"estimated_weekly_rent_range">>, Pf, null),
                          maps:get(<<"price">>, Pf, null),
                          maps:get(<<"property_type">>, Pf, null));
                  _ ->
                      base_cfp()
              end,
    Outcome = Outcome0#{<<"cash_events">> => yield_cash_events(Outcome0)},
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

%% --- cash_events (investor hold-phase spine, the rent/opex/interest legs) ----
%% Mirrors fh_engine_cash's event shape (via the shared hold_event/7); purchase_journey's
%% generic multi-source harvest places these on the swimlane's Own/Hold column with zero
%% Mode-C-specific journey code ([[unify-views-as-projections-of-one-primitive]]).
%% rental_income/operating_expenses are BANDS (the rent input is a band, §B0);
%% loan_interest is a POINT (representative-leverage interest) — hold_amount/1 collapses
%% either into the registry's money_range shape. Honest-partial: a null figure (base, or
%% the strata opex gap) drops its event, never a fabricated one.
yield_cash_events(Cfp) ->
    Out = [
        hold_event(<<"rental_income">>, <<"event_rental_income">>, <<"in">>,
                   maps:get(<<"annual_rental_income_year_1">>, Cfp, null),
                   <<"tenant">>, <<"yield_modelling">>, <<"kb.copy.yield">>),
        hold_event(<<"operating_expenses">>, <<"event_operating_expenses">>, <<"out">>,
                   maps:get(<<"annual_operating_expenses_year_1">>, Cfp, null),
                   <<"property_manager">>, <<"yield_modelling">>, <<"kb.copy.yield">>),
        hold_event(<<"loan_interest">>, <<"event_loan_interest">>, <<"out">>,
                   maps:get(<<"annual_interest_year_1">>, Cfp, null),
                   <<"lender">>, <<"yield_modelling">>, <<"kb.copy.yield">>)
    ],
    [E || E <- Out, maps:get(<<"amount">>, E) =/= null].

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

%% Derive the couple-as-one read-model from the canonical off_title_parties[] SOT
%% (P0.4 / fact-model-unification.md "Mode-B activation"). The KB couple-as-one scheme
%% gates (F4/G2) read the flat `non_buying_partner.*` view; the role-flag FILTER lives
%% HERE (Erlang), not in the declarative KB predicate language — complex array-filtering
%% belongs in the resolver, the predicate language stays simple. The couple-as-one subset
%% is DYADIC (a married/de-facto spouse is ≤1) — a domain law, not a Mode-A convenience —
%% so it is enforced FAIL-CLOSED: >1 flagged party is a contradiction (crash), never a
%% silent drop. The funder role (N-valued, Mode B) is read directly off the array by its
%% own consumers; it does not pass through this view.
-spec couple_as_one_view([map()]) -> map().
couple_as_one_view(OffTitleParties) ->
    Couple = [P || P <- OffTitleParties,
                   maps:get(<<"counts_for_couple_as_one">>, P, false) =:= true],
    case Couple of
        []       -> #{<<"exists">> => false};
        [Party]  -> couple_view(Party);
        _        -> error({couple_as_one_not_dyadic, length(Couple)})
    end.

%% project one off-title couple party's ownership_history into the flat non_buying_partner
%% fields the KB gates read (exists + the three ownership predicates).
-spec couple_view(map()) -> map().
couple_view(Party) ->
    OH = maps:get(<<"ownership_history">>, Party, #{}),
    #{<<"exists">> => true,
      <<"ever_owned_au_property">> =>
          maps:get(<<"ever_owned_au_property">>, OH, false),
      <<"ever_owned_and_occupied_residence">> =>
          maps:get(<<"ever_owned_and_occupied_residence">>, OH, false),
      <<"currently_owns_property">> =>
          maps:get(<<"currently_owns_property">>, OH, false)}.

%% Regulated figures are grounded -> P-7 · One declaration per outcome shape -> The engine -> FATR reg 35(1)(a) exempts citizens only
%% applicant.firb_required = false is exact for a citizen wherever they live, and for a
%% permanent resident only while they are ordinarily resident in Australia (200+ days of the
%% past 12 months) — kb.firb.status-determination. Onboarding asks "citizen or PR?" and never
%% where the buyer lives, so a domestic profile whose applicants MAY include a PR (the base
%% {citizen, PR} possibility set, or a scalar PR) states that assumption as a key_assumption,
%% EN + VI from kb.copy.profile. A residence question routing a PR abroad to Mode B/D was the
%% alternative; those modes are not launched (behavior 7). A citizen-only household gets [].
%% Read on legislation.gov.au 2026-10-07 (F2015L01854, compilation No. 20, 1 Nov 2025):
%% reg 35(1)(a) "an Australian citizen not ordinarily resident in Australia" — no PR limb.
residence_assumptions(Applicants) ->
    case lists:any(fun may_be_permanent_resident/1, Applicants) of
        true  -> [copy(<<"assume_pr_ordinarily_resident">>, #{})];
        false -> []
    end.

%% an absent / null citizenship on a domestic profile is unknown → may be a PR (state it).
may_be_permanent_resident(Applicant) ->
    case maps:get(<<"citizenship_status">>, Applicant, null) of
        #{<<"oneof">> := Set}       -> lists:member(<<"permanent_resident">>, Set);
        <<"permanent_resident">>    -> true;
        null                        -> true;
        _                           -> false
    end.

%% subst a kb.copy.profile template into a bilingual {vi,en} value (no Vietnamese
%% in Erlang literals; same mechanism as fh_engine_cash).
-spec copy(binary(), #{binary() => fh_engine_i18n:param()}) -> fh_engine_i18n:localized().
copy(Id, Params) ->
    fh_engine_i18n:subst(fh_engine_kb:copy(?COPY, Id), Params).

%% the default target gross yield for an archetype, from the labelled-placeholder KB defaults
%% (kb.investor.target-yield-by-archetype). null for land_banking (not yield-driven) and for an
%% absent/unknown archetype (honest-partial). The archetype is the agent's; this mapping to a
%% number is the resolver's (§98 — the figure stays out of the LLM's reach).
%% the default target gross yield for an archetype, from the labelled-placeholder KB defaults
%% (kb.investor.target-yield-by-archetype), via the existing param/2. The archetype is schema-
%% constrained to the six enum values (each has a param; land_banking's value is null = not
%% yield-driven); a null/absent archetype → null (honest-partial). The archetype is the agent's;
%% this mapping to a number is the resolver's (§98 — the figure stays out of the LLM's reach).
target_yield_for(Archetype) when is_binary(Archetype) ->
    param(?TARGET_YIELD, <<"target_gross_yield_", Archetype/binary>>);
target_yield_for(_) -> null.

%% Goal: regulated figures are grounded -> one computer per figure, honest about its tier ->
%% tax_structure's merge -> place the entity's setup band from kb.tax.entity-setup-costs.
%% The band is INDICATIVE market pricing, [lo, hi] AUD; hi null is an open-ended floor (company,
%% SMSF with LRBA). It stays a band and is not summed into total_cash_required: a range added to
%% a point total would change that figure's type (behavior 11, #12). An entity the KB does not
%% list, or none yet, is null (pending), never a guess.
entity_setup_band(Entity) when is_binary(Entity) ->
    {ok, Cj} = fh_engine_kb:kb_rules(?ENTITY_SETUP),
    Entries = maps:get(<<"entries">>,
                       maps:get(<<"entity_setup_cost_bands">>, maps:get(<<"lookup">>, Cj))),
    case [maps:get(<<"setup_first_year">>, E) || E <- Entries,
                                                 maps:get(<<"entity">>, E) =:= Entity] of
        [[Lo, Hi]] -> [Lo, Hi];
        _          -> null
    end;
entity_setup_band(_) -> null.
