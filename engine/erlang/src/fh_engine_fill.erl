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
%% STATUS (2b-2b keystone): `buyer_profile` is a REAL fill — it projects the
%% onboarding fact base into the `profile` outcome and derives per-applicant FIRB
%% via fh_engine_resolver (the §11.9 applicant.* semantics). The other three
%% resolver components (`eligibility`, `cash_position`, `ownership_planning`) return
%% an explicitly **provisional** outcome (carrying <<"_provisional">> => true) — the
%% turn-walk + dispatch is proven now; their real fills land in the following units
%% (eligibility via the define-simulate-document discipline, as it is property-
%% agnostic banded all-applicants logic touching F7/F1; cash_position/ownership_
%% planning via the mechanism-(B) formula code over the KB bracket/fee tables).

-export([resolver/3]).

-spec resolver(binary(), map(), map()) -> {map(), binary(), [map()]}.
resolver(<<"buyer_profile">>, Args, _Upstream) ->
    buyer_profile(Args);
resolver(<<"eligibility">>, Args, Upstream) ->
    fh_engine_eligibility:fill(Args, Upstream);
resolver(<<"cash_position">>, _Args, _Upstream) ->
    provisional(<<"budget_envelope">>, <<"calculator">>,
                [<<"kb.stamp-duty.calc-by-state">>]);
resolver(<<"ownership_planning">>, _Args, _Upstream) ->
    provisional(<<"ongoing_obligations">>, <<"data-table">>,
                [<<"kb.land-tax.ppor-exemption">>]);
resolver(Other, _Args, _Upstream) ->
    erlang:error({no_resolver_fill_for, Other}).

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
        <<"intended_occupancy_use">> => <<"sole_occupier">>,
        <<"target_price_range">> => TargetRange,
        <<"target_zone">> => TargetZone,
        <<"key_constraints">> =>
            [<<"Applicant financial details (income, savings, debts) pending — "
               "the base plan refines as you answer."/utf8>>],
        <<"key_strengths">> =>
            [<<"First home buyer — full Mode A scheme access (pending eligibility "
               "checks)."/utf8>>]
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

%% --- provisional resolver fills (explicitly TODO) ---------------------------
%% A structurally-valid placeholder so the turn-walk runs green end-to-end while
%% the real mechanism-(A)/(B) fills are written. Marked <<"_provisional">> so it is
%% never mistaken for a real outcome; the smoke test asserts structure (fill_path,
%% no usage), not these values.

provisional(OutcomeType, Renderer, AnchorSlugs) ->
    Outcome = #{<<"_provisional">> => true,
                <<"outcome_type">> => OutcomeType},
    {Outcome, Renderer, fh_engine_kb:kb_anchors(AnchorSlugs)}.
