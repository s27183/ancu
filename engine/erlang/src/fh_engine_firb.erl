-module(fh_engine_firb).

%% The base-turn `firb_workflow` fill (blueprint fhb-foreign-au.md component 4 — the
%% Mode-B/D REPLACEMENT for Mode A's `eligibility`; mode-b-wedge.md P2 slice 2). The
%% mandatory FIRB approval gate before contract signing (constraint #10) — this module
%% owns the AUTHORITATIVE foreign_person_eligible / blocking_for_contract verdicts
%% (property_assessment only ever emits a non-authoritative early warning).
%%
%% SCOPE (`both`, per the blueprint): a BASE estimate at onboarding — no property
%% attached yet, so the fee tier is picked at the CONSERVATIVE (upper-bound) end of
%% profile.target_price_range, and per-property eligibility stays honest-partial
%% (undetermined) until a property is attached; REFINED per-property once Upstream
%% carries property_fit.price / property_type. established_dwelling_ban_applies is a
%% pure calendar fact (kb.firb.established-dwelling-ban's ban_start_date/ban_end_date,
%% erlang:date() — the SAME "dates as parameter leaves + comparison in resolver code"
%% pattern fh_engine_settlement uses), computed either way.
%%
%% Eligibility derivation mirrors kb.firb.established-dwelling-ban's OWN declared `fills`
%% rule for firb_workflow.eligibility.foreign_person_can_purchase (any_of: NOT foreign OR
%% permitted property type). Mode B is always profile.firb_required_any = true
%% (buyer_profile_foreign, definitional — fh_engine_fill.erl), so the `any_of` collapses
%% to: ban window closed -> eligible regardless of type (approval still required, not a
%% purchase-eligibility question); ban in force -> eligible iff the KNOWN property type
%% is on the permitted list (kb.firb.eligible-property-types-foreign-persons); undetermined
%% (null) when no property is attached yet.
%%
%% Fee: kb.firb.fee-tiers-by-value's selection rule (smallest consideration-band ceiling
%% >= price) composed with kb.firb.fee-schedule-current's dated amounts — the
%% NON-ESTABLISHED table only (the established x3 table is an off-path edge case while
%% the ban is in force AND Mode B individual buyers are structurally confined to the
%% permitted-type path; flagged, not built, per honest-partial "no silent caps" — see
%% established_table_not_built/0).

-export([fill/2]).
-export([ban_applies/0, eligible/2, fee_tier/1, fee_amount/1,
         documents_outstanding/1, has_funder/1]).

%% --- entry ---------------------------------------------------------------------

-spec fill(map(), map()) -> {map(), binary(), [map()]}.
fill(_Args, Upstream) ->
    Profile = maps:get(<<"profile">>, Upstream, #{}),
    PropertyFit = maps:get(<<"property_fit">>, Upstream, undefined),
    BanApplies = ban_applies(),
    PropertyType = property_type(PropertyFit),
    Eligible = eligible(BanApplies, PropertyType),
    Price = price_for_tier(PropertyFit, Profile),
    Tier = fee_tier(Price),
    Fee = fee_amount(Price),
    OffTitleParties = maps:get(<<"off_title_parties">>, Profile, []),
    HasFunder = has_funder(OffTitleParties),
    Outcome = #{
        <<"foreign_person_eligible">> => Eligible,
        <<"firb_fee_tier">> => Tier,
        <<"total_firb_fee_payable">> => Fee,
        %% state machine — every Mode-B turn today is base (no application flow wired
        %% yet), so the stage is always not_started / not approved.
        <<"current_stage">> => <<"not_started">>,
        <<"approval_received">> => false,
        <<"approval_conditions">> => [],
        %% the 30-day statutory clock (kb.firb.timelines-standard) does not start until
        %% the fee is paid in full — no clock has started at not_started (honest-partial).
        <<"days_to_expected_decision">> => null,
        <<"blocking_for_contract">> => blocking(false, Eligible),
        <<"documents_outstanding">> => documents_outstanding(HasFunder)
    },
    KbVersions = fh_engine_kb:kb_anchors(
        [<<"kb.firb.established-dwelling-ban">>,
         <<"kb.firb.eligible-property-types-foreign-persons">>,
         <<"kb.firb.fee-tiers-by-value">>, <<"kb.firb.fee-schedule-current">>,
         <<"kb.firb.application-process">>, <<"kb.firb.documents-required">>,
         <<"kb.firb.timelines-standard">>, <<"kb.firb.exemption-certificates-developer">>,
         <<"kb.firb.approval-conditions-typical">>,
         <<"kb.firb.penalties-non-compliance">>]),
    {Outcome, <<"firb-workflow-card">>, KbVersions}.

%% --- eligibility ---------------------------------------------------------------

property_type(#{<<"property_type">> := PT}) -> PT;
property_type(_)                            -> undefined.

%% kb.firb.established-dwelling-ban: ban_start_date .. ban_end_date, resolver-derived
%% (no hardcoded window — self-expires 30 Jun 2029 with no blueprint/code edit).
ban_applies() ->
    Today = erlang:date(),
    Start = parse_date(kb_param(<<"kb.firb.established-dwelling-ban">>, <<"ban_start_date">>)),
    End   = parse_date(kb_param(<<"kb.firb.established-dwelling-ban">>, <<"ban_end_date">>)),
    (not is_before(Today, Start)) andalso (not is_before(End, Today)).

%% mirrors kb.firb.established-dwelling-ban's own `fills` rule for
%% firb_workflow.eligibility.foreign_person_can_purchase, specialised to Mode B
%% (profile.firb_required_any is always true — see buyer_profile_foreign):
eligible(false, _PropertyType) -> true;   %% ban window closed — purchase-eligible (approval still required)
eligible(true, undefined)      -> null;   %% ban in force, no property attached yet — undetermined
eligible(true, PropertyType)   -> lists:member(PropertyType, permitted_types()).

%% kb.firb.eligible-property-types-foreign-persons / kb.firb.established-dwelling-ban:
%% permitted_property_types_for_foreign_persons.
permitted_types() ->
    [<<"new_house">>, <<"new_apartment">>, <<"off_the_plan">>, <<"house_and_land">>,
     <<"vacant_residential_land">>].

%% blocking_for_contract = true while NOT approved OR foreign_person_eligible == false
%% (firb_status outcome schema note). Expressed as a function of ApprovalReceived so the
%% rule reads correctly once a later refine turn tracks a real approval state, not just
%% the base-turn constant (approval_received is always false today).
blocking(ApprovalReceived, Eligible) ->
    (not ApprovalReceived) orelse (Eligible =:= false).

%% --- fee -------------------------------------------------------------------------

%% BASE: no property yet -> conservative upper bound of profile.target_price_range
%% (an under-estimate the buyer discovers late is worse than an over-estimate they
%% discover is generous). PER-PROPERTY (refined): the specific property_fit.price.
price_for_tier(#{<<"price">> := Price}, _Profile) when is_integer(Price) -> Price;
price_for_tier(_PropertyFit, Profile) ->
    ceiling(maps:get(<<"target_price_range">>, Profile, null)).

ceiling([_Lo, Hi]) when is_integer(Hi) -> Hi;
ceiling(_)                             -> null.

%% kb.firb.fee-tiers-by-value: band := smallest ceiling >= consideration (the blueprint's
%% own coarse enum — matches firb_workflow.fee_calculation.property_value_tier options).
fee_tier(null)                          -> null;
fee_tier(Price) when Price =< 1000000   -> <<"under_1m">>;
fee_tier(Price) when Price =< 2000000   -> <<"1m_to_2m">>;
fee_tier(Price) when Price =< 3000000   -> <<"2m_to_3m">>;
fee_tier(Price) when Price =< 5000000   -> <<"3m_to_5m">>;
fee_tier(_Price)                        -> <<"over_5m">>.

%% kb.firb.fee-schedule-current: fee_schedule_residential_non_established_2025_26 (the
%% Mode-B path — see the module header on why the established x3 table is out of scope).
%% Bands lt_75000 / le_1m are the schedule's own steps; from le_2m the schedule's stated
%% increment_rule ("+$30,300 per $1m band to $40m, flat $1,205,200 above") is applied
%% directly rather than transcribing every band — verified against the listed rows
%% (le_2m=30300, le_3m=60600, le_4m=90900, le_5m=121200, matching 30300*(M-1) for
%% M=2..5) and the note's own $40m/$1,181,700 anchor (30300*39=1,181,700).
fee_amount(null)                          -> null;
fee_amount(Price) when Price =< 75000     -> 4500;
fee_amount(Price) when Price =< 1000000   -> 15100;
fee_amount(Price) when Price =< 40000000  -> 30300 * (ceil_millions(Price) - 1);
fee_amount(_Price)                        -> 1205200.

%% smallest whole-million band ceiling >= Price, floored at 2 (the increment rule's
%% first step); Price is already known > $1,000,000 at every call site.
ceil_millions(Price) -> max(2, (Price + 999999) div 1000000).

%% NOT BUILT: the established-dwelling fee table (3x the non-established amount,
%% kb.firb.fee-schedule-current: established_dwelling_fee_multiplier). Off-path while the
%% ban is in force (a Mode-B foreign person cannot purchase an established dwelling at
%% all — eligible/2 returns false/null, never routes here) and out of scope for a
%% first-home-buyer wedge even post-ban (2029-06-30+). Flagged here, not silently dropped.

%% --- documents ---------------------------------------------------------------------

%% the blueprint's own component-4 documents_required checklist (the USER-FACING
%% gather-list) — distinct from kb.firb.documents-required's APPLICATION FORM field list
%% (a different consumer: the ATO portal fields, not what the buyer physically gathers).
%% At base nothing is uploaded (no upload-tracking wired yet — the same honest-partial
%% convention as the DAG's externals:[uploaded_docs]), so every REQUIRED document is
%% outstanding; the VN-funder passport is conditionally required only once a funder
%% appears in off_title_parties (base default [] from buyer_profile_foreign -> not
%% required).
documents_outstanding(HasFunder) ->
    Base = [<<"passport_au_member">>, <<"visa_grant_evidence">>,
            <<"property_details_contract_or_listing">>, <<"source_of_funds_evidence">>,
            <<"vendor_or_developer_details">>],
    case HasFunder of
        true  -> [<<"passport_vn_funder_if_applicable">> | Base];
        false -> Base
    end.

has_funder(OffTitleParties) ->
    lists:any(fun(P) ->
        Funder = maps:get(<<"funder">>, P, #{}),
        maps:get(<<"expected_to_fund">>, Funder, false) =:= true
    end, OffTitleParties).

%% --- kb / date helpers --------------------------------------------------------------

kb_param(Slug, Key) ->
    {ok, Cj} = fh_engine_kb:kb_rules(Slug),
    Params = maps:get(<<"parameters">>, Cj),
    maps:get(<<"value">>, maps:get(Key, Params)).

parse_date(<<Y:4/binary, "-", M:2/binary, "-", D:2/binary>>) ->
    {binary_to_integer(Y), binary_to_integer(M), binary_to_integer(D)}.

is_before(D1, D2) ->
    calendar:date_to_gregorian_days(D1) < calendar:date_to_gregorian_days(D2).
