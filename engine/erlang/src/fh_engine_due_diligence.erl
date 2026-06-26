-module(fh_engine_due_diligence).

%% The `due_diligence` investor-variant resolver (Mode C, Phase B per-property, blueprint
%% component 9). It is RESOLVER-ONLY AT A — due_diligence's one agent leaf
%% (investor_specific_flags.current_tenancy_unfavourable_terms, reasoning_domain
%% lease_interpretation) needs the *uploaded lease*, so it activates with B; no reasoning_domain
%% runs at A. It produces the `risk_assessment_investor` outcome.
%%
%% HONEST-PARTIAL ([[base-turn-honest-partial-output]], [[honest-deferral-not-rug]]). The DEFINING
%% risk-*surfacing* output — high_severity_flags, the negotiation lever, the lease-interpretation
%% concern — depends on UPLOADED DOCUMENTS, and the upload pipeline is NOT built (CLAUDE.md item 9;
%% the only Phase-B input today is the source-supplied property_card of neutral PROPERTY facts,
%% not the user's uploaded documents — a distinct input surface, mode-c-wedge.md "due_diligence B").
%% So this resolver fills the KNOWABLE STRUCTURE now:
%%   - the investor document PROCUREMENT checklist (what to gather + why), KB-grounded, property-
%%     generic; received/reviewed false until the upload pipeline (B);
%%   - the bilingual due-diligence actions before signing + the vendor/agent questions;
%%   - the COMPUTABLE rental_yield_below_thesis_threshold flag (the per-property yield vs the
%%     strategy target — resolver-computed, removed from the LLM's reach, §8.5);
%% and marks the document-dependent fields PENDING (docs_status=pending_upload,
%% overall_verdict=pending_documents, high_severity_flags [], estimated_negotiation_lever null),
%% never fabricating a finding. next_action_for_user asks the user to upload the documents.
%%
%% FIGURE POSTURE (§8.5, [[verify-regulated-figures-by-postcondition]]). The one figure here —
%% rental_yield_below_thesis_threshold — is a deterministic comparison of two upstream numbers
%% (property_fit_investor.rental_yield_gross_estimate vs strategy_thesis.target_gross_yield);
%% there is no agent slot for it. A property bid/risk figure is NOT an ASIC/AFSL matter (real
%% property is not a financial product; that line governs finance/credit — mortgage_finance /
%% eligibility); the constraint here is ACL misleading-conduct, met by KB-methodology computation
%% + the bilingual decision-support framing (kb.copy.due-diligence). due_diligence is nonetheless
%% marked advice_adjacent (fh_engine_compliance) as a consistent decision-support hedge.

-export([fill/2]).

-define(APPRAISAL, <<"kb.investor.rental-appraisal-from-pm-agent">>).
-define(DEPREC,    <<"kb.investor.depreciation-report-quantity-surveyor">>).
-define(TENANCY,   <<"kb.investor.tenancy-in-situ-considerations">>).
-define(COPY,      <<"kb.copy.due-diligence">>).

-spec fill(map(), map()) -> {map(), binary(), map()}.
fill(_Args, Upstream) ->
    Pf     = maps:get(<<"property_fit_investor">>, Upstream, #{}),
    Thesis = maps:get(<<"strategy_thesis">>, Upstream, #{}),
    Yield  = maps:get(<<"rental_yield_gross_estimate">>, Pf, null),
    Target = maps:get(<<"target_gross_yield">>, Thesis, null),
    Below  = yield_below(Yield, Target),
    Outcome = #{
        <<"docs_status">>                         => <<"pending_upload">>,
        <<"overall_verdict">>                     => <<"pending_documents">>,
        <<"document_checklist">>                  => document_checklist(),
        <<"rental_yield_below_thesis_threshold">> => Below,
        <<"investor_specific_concerns">>          => concerns(Below),
        <<"actions_before_signing">>              => actions(),
        <<"questions_for_vendor">>                => questions(),
        <<"high_severity_flags">>                 => [],
        <<"estimated_negotiation_lever">>         => null,
        <<"next_action_for_user">>                => copy(<<"next_action">>)
    },
    KbVersions = fh_engine_kb:kb_anchors([?APPRAISAL, ?DEPREC, ?TENANCY, ?COPY]),
    {Outcome, <<"checklist">>, KbVersions}.

%% the COMPUTABLE investor risk flag: is the per-property yield below the strategy target? Both
%% must be numbers (the per-property yield is set at attach; the target at base) — else null
%% (honest-partial, never false from absent data — [[base-turn-honest-partial-output]]).
yield_below(Yield, Target) when is_number(Yield), is_number(Target) -> Yield < Target;
yield_below(_, _)                                                   -> null.

%% the investor document procurement checklist — property-generic, KB-grounded. required + why
%% known now; received/reviewed false until the upload pipeline (due_diligence B).
document_checklist() ->
    [doc(<<"rental_appraisal">>,  true),
     doc(<<"depreciation_quote">>, true),
     doc(<<"lease">>,             false),
     doc(<<"rental_history">>,    false)].

doc(Id, Required) ->
    #{<<"id">>       => Id,
      <<"name">>     => copy(<<"doc_", Id/binary>>),
      <<"required">> => Required,
      <<"received">> => false,
      <<"reviewed">> => false,
      <<"why">>      => copy(<<"doc_", Id/binary, "_why">>)}.

%% surfaced concerns (risk-flag-list). At A only the computable yield-below-thesis concern fires;
%% the document-derived concerns follow in B. null/false → no concern (nothing fabricated).
concerns(true) ->
    [#{<<"id">>       => <<"rental_yield_below_thesis_threshold">>,
       <<"severity">> => <<"medium">>,
       <<"detail">>   => copy(<<"concern_yield_below_thesis">>)}];
concerns(_) ->
    [].

%% the due-diligence actions before signing — a fixed, property-generic bilingual list.
actions() ->
    [copy(<<"act_rental_appraisal">>),
     copy(<<"act_depreciation_estimate">>),
     copy(<<"act_review_building_pest">>),
     copy(<<"act_confirm_tenancy">>)].

%% the questions to ask the vendor / agent — a fixed, property-generic bilingual list.
questions() ->
    [copy(<<"q_tenanted">>),
     copy(<<"q_current_rent">>),
     copy(<<"q_rental_history">>),
     copy(<<"q_strata_levies">>)].

%% a kb.copy.due-diligence template as a bilingual {vi,en} value (no placeholders → fetch directly).
-spec copy(binary()) -> fh_engine_i18n:localized().
copy(Id) ->
    fh_engine_kb:copy(?COPY, Id).
