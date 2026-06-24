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
%% formula code over the KB tables (stamp-duty brackets / ongoing-cost bands).

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
has_resolver(<<"mortgage_finance">>)   -> true;
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
resolver(<<"mortgage_finance">>, Args, Upstream) ->
    fh_engine_mortgage:fill(Args, Upstream);
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
