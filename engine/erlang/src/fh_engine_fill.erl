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

-export([resolver/3, has_resolver/1, merge_agent/3]).

-define(COPY, <<"kb.copy.profile">>).   %% buyer_profile bilingual copy-templates (bilingual-content.md §3b)

%% Does this component have a resolver fill? Empty `agent_leaves` → pure resolver;
%% non-empty + has_resolver → TWO-PATH (the turn runs the resolver, then folds the
%% agent leaves via merge_agent/3); non-empty + no resolver → pure agent (the sidecar
%% fills the whole outcome — the later per-property valuation/negotiation components).
-spec has_resolver(binary()) -> boolean().
has_resolver(<<"buyer_profile">>)      -> true;
has_resolver(<<"eligibility">>)        -> true;
has_resolver(<<"cash_position">>)      -> true;
has_resolver(<<"ownership_planning">>) -> true;
has_resolver(<<"mortgage_finance">>)   -> true;
has_resolver(_)                        -> false.

-spec resolver(binary(), map(), map()) -> {map(), binary(), [map()]}.
resolver(<<"buyer_profile">>, Args, _Upstream) ->
    buyer_profile(Args);
resolver(<<"eligibility">>, Args, Upstream) ->
    fh_engine_eligibility:fill(Args, Upstream);
resolver(<<"cash_position">>, Args, Upstream) ->
    fh_engine_cash:fill(Args, Upstream);
resolver(<<"ownership_planning">>, Args, Upstream) ->
    fh_engine_ownership:fill(Args, Upstream);
resolver(<<"mortgage_finance">>, Args, Upstream) ->
    fh_engine_mortgage:fill(Args, Upstream);
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

%% --- buyer_profile (real) ---------------------------------------------------
%% The pipeline entry: project the onboarding fact base into the `profile` outcome.
%% At the onboarding turn the deep applicant facts (citizenship, age, income,
%% ownership history) are not yet gathered — those arrive via chat/uploads on a
%% later refine turn (which will load the enriched profile from the profiles SOT).
%% So the base projection carries the onboarding subset + a minimal lead applicant;
%% FIRB derives conservatively (Mode A enters via a non-foreign lead → false).

buyer_profile(Args) ->
    Onboarding = maps:get(onboarding, Args, #{}),
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
        <<"target_price_range">> => TargetRange,
        <<"target_zone">> => TargetZone,
        %% bilingual {vi,en} via kb.copy.profile (no Vietnamese in Erlang literals —
        %% the io:format ~s >255-codepoint trap; bilingual-content.md §3b).
        <<"key_constraints">> => [copy(<<"constraint_financials_pending">>, #{})],
        <<"key_strengths">>   => [copy(<<"strength_first_home_buyer">>, #{})]
    },
    KbVersions = fh_engine_kb:kb_anchors(
        [<<"kb.hecs.thresholds">>, <<"kb.firb.status-determination">>,
         <<"kb.lender.serviceability-basics">>]),
    {Outcome, <<"summary-card">>, KbVersions}.

%% A three-valued resolver verdict, made JSON-safe for the outcome snapshot:
%% true/false stay booleans; `undetermined` becomes an explicit marker (rather than
%% leaking the atom or collapsing silently to a bool).
tri_to_json(true)         -> true;
tri_to_json(false)        -> false;
tri_to_json(undetermined) -> <<"needs_determination">>.

%% subst a kb.copy.profile template into a bilingual {vi,en} value (no Vietnamese
%% in Erlang literals; same mechanism as fh_engine_cash).
-spec copy(binary(), #{binary() => fh_engine_i18n:param()}) -> fh_engine_i18n:localized().
copy(Id, Params) ->
    fh_engine_i18n:subst(fh_engine_kb:copy(?COPY, Id), Params).
