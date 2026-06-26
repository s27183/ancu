-module(fh_engine_settlement).

%% The `settlement_prep` investor-variant resolver (Mode C, Phase B per-property). It is
%% RESOLVER-ONLY — settlement_prep has zero agent leaves (no reasoning_domain); the whole
%% outcome is deterministic. It produces the `settlement_checklist` outcome.
%%
%% HONEST-PARTIAL ([[base-turn-honest-partial-output]], [[honest-deferral-not-rug]]). The
%% DEFINING output of settlement_prep — the *dated* critical path with at-risk detection — needs
%% `contract_signed_date` + `settlement_date`, which arrive `<from_document>` from a signed
%% contract. That per-property transaction-input surface is NOT built (the only Phase-B input
%% today is the source-supplied property_card of neutral PROPERTY facts; contract dates are facts
%% about the user's TRANSACTION, a separate cross-contract unit — mode-c-wedge.md "settlement_prep
%% B"). So this resolver fills the KNOWABLE STRUCTURE now and marks every date PENDING:
%%   - the standard settlement critical-path milestone sequence + dependency DAG (property-generic,
%%     KB-grounded), each due_date null + status pending;
%%   - the investor-specific milestones, with entity-setup CONDITIONED on the upstream
%%     recommended_entity (applicable iff a legal entity must be established — not personal_sole/joint);
%%   - the state-conditional building-insurance-timing RULE, resolver-selected from
%%     kb.insurance.timing-of-risk-pass.risk_passing_by_state (the RULE is knowable without dates).
%% No date is ever fabricated; `dates_status` = pending_contract; at_risk_milestones = [];
%% next_action_for_user asks the user to supply the contract dates to activate the dated path.
%%
%% This resolver is also the STATE-CONDITIONAL building-insurance fix that
%% kb.insurance.timing-of-risk-pass flagged ("the blueprint's single derived_from:settlement_date
%% hint is wrong for QLD, where risk passes the day after contract; surfaced for a separate
%% blueprint fix"): the insurance rule branches on state, not on settlement_date.
%%
%% FIGURE POSTURE. No regulated-financial figure here — milestones, dates and the insurance-timing
%% rule are process / statutory facts. The insurance rule's factual authority is the regulated KB
%% doc (timing-of-risk-pass, read against the primary Acts); the bilingual strings restate it
%% (kb.copy.settlement). settlement_prep is informational/process, NOT advice_adjacent.

-export([fill/2]).

-define(SETTLE, <<"kb.settlement.process-by-state">>).
-define(INS,    <<"kb.insurance.timing-of-risk-pass">>).
-define(ENTITY, <<"kb.investor.entity-setup-timeline">>).
-define(DEPREC, <<"kb.investor.depreciation-schedule-procurement">>).
-define(PM,     <<"kb.investor.property-management-appointment-timeline">>).
-define(COPY,   <<"kb.copy.settlement">>).

-spec fill(map(), map()) -> {map(), binary(), map()}.
fill(_Args, Upstream) ->
    Pf     = maps:get(<<"property_fit_investor">>, Upstream, #{}),
    Tax    = maps:get(<<"tax_optimised_structure">>, Upstream, #{}),
    State  = maps:get(<<"state">>, Pf, null),
    PType  = maps:get(<<"property_type">>, Pf, null),
    Entity = maps:get(<<"recommended_entity">>, Tax, null),
    Outcome = #{
        <<"dates_status">>             => <<"pending_contract">>,
        <<"settlement_date">>          => null,
        <<"critical_path_milestones">> => critical_path(),
        <<"investor_milestones">>      => investor_milestones(Entity),
        <<"insurance_timing_rule">>    => insurance_rule(State, PType),
        <<"at_risk_milestones">>       => [],
        <<"next_action_for_user">>     => copy(<<"next_action">>)
    },
    KbVersions = fh_engine_kb:kb_anchors([?SETTLE, ?INS, ?ENTITY, ?DEPREC, ?PM, ?COPY]),
    {Outcome, <<"checklist">>, KbVersions}.

%% the standard settlement critical-path sequence + dependency DAG (property-generic). Dates are
%% PENDING — every due_date null, status pending — until contract dates exist (settlement_prep B).
critical_path() ->
    [mil(<<"contract_signed">>,                 null),
     mil(<<"deposit_paid_to_trust">>,           <<"contract_signed">>),
     mil(<<"building_pest_satisfactory">>,      <<"contract_signed">>),
     mil(<<"finance_approval_unconditional">>,  <<"contract_signed">>),
     mil(<<"loan_documents_signed">>,           <<"finance_approval_unconditional">>),
     mil(<<"insurance_bound">>,                 <<"contract_signed">>),
     mil(<<"settlement_funds_released">>,       <<"loan_documents_signed">>),
     mil(<<"title_registered">>,                <<"settlement_funds_released">>),
     mil(<<"keys_received">>,                   <<"title_registered">>)].

mil(Id, Dep) ->
    #{<<"id">>         => Id,
      <<"name">>       => copy(<<"mil_", Id/binary>>),
      <<"due_date">>   => null,
      <<"status">>     => <<"pending">>,
      <<"dependency">> => Dep}.

%% the investor-specific milestones. entity-setup is conditioned on the upstream recommended_entity;
%% the rest are always-applicable for an investor (QS confirms what depreciation is claimable — not
%% pre-decided from build-year, which property_fit_investor does not carry).
investor_milestones(Entity) ->
    [inv(<<"entity_setup">>,                   entity_applicable(Entity)),
     inv(<<"quantity_surveyor_engaged">>,      true),
     inv(<<"depreciation_schedule_received">>, true),
     inv(<<"property_management_appointed">>,  true),
     inv(<<"landlord_insurance_bound">>,       true)].

inv(Id, Applicable) ->
    #{<<"id">>         => Id,
      <<"name">>       => copy(<<"inv_", Id/binary>>),
      <<"applicable">> => Applicable,
      <<"why">>        => copy(<<"inv_", Id/binary, "_why">>),
      <<"due_date">>   => null,
      <<"status">>     => <<"pending">>}.

%% entity setup is needed only when a legal entity must be ESTABLISHED — a company or trust. Sole
%% or joint ownership is just names on the title; null = entity not yet decided → not applicable.
entity_applicable(<<"personal_sole">>) -> false;
entity_applicable(<<"joint">>)         -> false;
entity_applicable(null)                -> false;
entity_applicable(E) when is_binary(E) -> true;
entity_applicable(_)                   -> false.

%% the state-conditional building-insurance-timing rule. NSW/VIC/QLD have a regulated per-state
%% rule (kb.insurance.timing-of-risk-pass); a known state outside that set gets the universal
%% lender-overlay + a to-verify; an unknown state → null (honest-partial, no rule fabricated). For
%% a strata lot the body corporate insures the building → append the contents-only note.
insurance_rule(State, PType)
  when State =:= <<"NSW">>; State =:= <<"VIC">>; State =:= <<"QLD">> ->
    maybe_strata(copy(<<"ins_rule_", State/binary>>), PType);
insurance_rule(State, PType) when is_binary(State) ->
    maybe_strata(copy(<<"ins_rule_other">>), PType);
insurance_rule(_, _) ->
    null.

maybe_strata(Rule, PType) when PType =:= <<"apartment">>; PType =:= <<"unit">> ->
    append_localized(Rule, copy(<<"ins_strata_note">>));
maybe_strata(Rule, _) ->
    Rule.

%% concatenate two {vi,en} values, each half independently (no io:format ~s — bilingual-content.md).
append_localized(#{<<"vi">> := V1, <<"en">> := E1}, #{<<"vi">> := V2, <<"en">> := E2}) ->
    #{<<"vi">> => <<V1/binary, " ", V2/binary>>,
      <<"en">> => <<E1/binary, " ", E2/binary>>};
append_localized(Rule, _) ->
    Rule.

%% a kb.copy.settlement template as a bilingual {vi,en} value (no placeholders → fetch directly).
-spec copy(binary()) -> fh_engine_i18n:localized().
copy(Id) ->
    fh_engine_kb:copy(?COPY, Id).
