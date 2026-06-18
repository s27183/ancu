-module(fh_engine_preparation).

%% The base-turn `preparation` fill (component 11) — the property-agnostic READINESS
%% layer (lifecycle-simulation-model §5, blueprint §11): the documents to gather, the
%% people to line up, the scheme applications to prepare, and the cash buffer to hold,
%% surfaced at onboarding with no property attached. It is the prototype's "Before you
%% buy" content, reclassified OUT of the per-property due_diligence (7).
%%
%% RESOLVER fill (agentic-boundary.md): the checklist items + people-to-engage roles are
%% generic Mode-A KB prose (kb.preparation.fhb-readiness); there is no agent leaf. It
%% PLACES, never computes ([[place-upstream-figures-dont-recompute]]): which scheme
%% applications appear is read from eligibility's scheme_stack, and the money-buffer
%% figures are read from cash_position's budget_envelope (one-computer-per-figure — the
%% buffer/verdict are the calculator's figures, referenced not recomputed). It reads only
%% upstream base outcomes, so it sits LAST in the base DAG and still owns no figure.
%%
%% HONEST-PARTIAL: document_checklist[].status is a USER-ATTESTED fact (the "Chưa có / Đã
%% có" toggle) — the resolver seeds every item `not_started`; the user sets it and it is
%% stored on the card. The reserve_buffer amount is null at base (the calculator leaves it
%% pending until a refine turn) and travels through as null — never a fabricated figure.

-export([fill/2]).
%% exported for the conformance harness:
-export([document_checklist/0, people_to_engage/0, scheme_applications/1, money_buffer/1]).

-define(COPY, <<"kb.preparation.fhb-readiness">>).   %% bilingual prose (no params)

%% stable ids for the generic FHB document set + the roles to engage (the doc's resolver
%% mapping). NOT the per-property contract/S32/inspection docs — those are due_diligence.
-define(DOC_IDS,    [<<"photo_id">>, <<"noa">>, <<"payslips">>,
                     <<"bank_statements">>, <<"deposit_evidence">>]).
-define(PERSON_IDS, [<<"broker">>, <<"conveyancer">>, <<"buyers_agent">>]).

%% --- entry -------------------------------------------------------------------

-spec fill(map(), map()) -> {map(), binary(), [map()]}.
fill(_Args, Upstream) ->
    Stack  = maps:get(<<"scheme_stack">>, Upstream, #{}),
    Budget = maps:get(<<"budget_envelope">>, Upstream, #{}),
    Outcome = #{
        <<"document_checklist">>             => document_checklist(),
        <<"people_to_engage">>               => people_to_engage(),
        <<"scheme_applications_to_prepare">> => scheme_applications(Stack),
        <<"money_buffer">>                   => money_buffer(Budget),
        <<"key_assumptions">> =>
            [copy(<<"assumption_indicative">>), copy(<<"assumption_informational">>)]
    },
    KbVersions = fh_engine_kb:kb_anchors([?COPY]),
    {Outcome, <<"checklist">>, KbVersions}.

%% --- the generic readiness content (KB prose, no figures) --------------------

%% one entry per doc id; status is user-attested → seeded not_started (the user sets it).
-spec document_checklist() -> [map()].
document_checklist() ->
    [#{<<"id">>     => Id,
       <<"item">>   => copy(<<"doc_", Id/binary, "_item">>),
       <<"why">>    => copy(<<"doc_", Id/binary, "_why">>),
       <<"status">> => <<"not_started">>} || Id <- ?DOC_IDS].

-spec people_to_engage() -> [map()].
people_to_engage() ->
    [#{<<"role">> => copy(<<"person_", Id/binary, "_role">>),
       <<"when">> => copy(<<"person_", Id/binary, "_when">>),
       <<"why">>  => copy(<<"person_", Id/binary, "_why">>)} || Id <- ?PERSON_IDS].

%% --- PLACED from scheme_stack (read, never recomputed) -----------------------

%% one entry per applicable scheme; the action prose is keyed by the scheme's ROLE (the
%% stable key), defaulting where no role-specific action copy exists (e.g. the FHOG grant).
-spec scheme_applications(map()) -> [map()].
scheme_applications(Stack) ->
    Schemes = maps:get(<<"applicable_schemes">>, Stack, []),
    [#{<<"scheme">> => role(S),
       <<"action">> => copy(action_id(role(S)))} || S <- Schemes].

role(S) -> maps:get(<<"role">>, S, <<"unknown">>).

action_id(<<"deposit_guarantee">>)     -> <<"scheme_action_fhg">>;
action_id(<<"deposit_savings">>)       -> <<"scheme_action_fhss">>;
action_id(<<"shared_equity">>)         -> <<"scheme_action_help_to_buy">>;
action_id(<<"stamp_duty_concession">>) -> <<"scheme_action_state_concession">>;
action_id(_)                           -> <<"scheme_action_default">>.   %% incl. grant (FHOG)

%% --- PLACED from budget_envelope (one-computer-per-figure) -------------------

%% the readiness read of the buffer the calculator owns: the genuine-savings verdict +
%% the reserve amount (null at base — the calculator leaves it pending). The notes narrate
%% the placed verdict; no figure is computed here.
-spec money_buffer(map()) -> map().
money_buffer(Budget) ->
    Verdict = maps:get(<<"genuine_savings_verdict">>, Budget, <<"unknown">>),
    Reserve = maps:get(<<"amount">>, maps:get(<<"reserve_buffer">>, Budget, #{}), null),
    #{<<"genuine_savings_verdict">> => Verdict,
      <<"reserve_buffer">>          => Reserve,
      <<"notes">> => [copy(<<"buffer_note_general">>), copy(buffer_note_id(Verdict))]}.

buffer_note_id(<<"meets">>)                     -> <<"buffer_note_meets">>;
buffer_note_id(<<"fails_recent_gift">>)         -> <<"buffer_note_fails_recent_gift">>;
buffer_note_id(<<"insufficient_track_record">>) -> <<"buffer_note_insufficient_track_record">>;
buffer_note_id(_)                               -> <<"buffer_note_unknown">>.

%% --- KB access ---------------------------------------------------------------

%% A bilingual {vi,en} line from the readiness KB doc. No params — the figures are
%% structured outcome fields, not interpolated — so the template is returned as-is.
-spec copy(binary()) -> fh_engine_i18n:localized().
copy(Id) ->
    fh_engine_kb:copy(?COPY, Id).
