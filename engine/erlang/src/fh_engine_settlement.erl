-module(fh_engine_settlement).

%% The `settlement_prep` investor-variant resolver (Mode C, Phase B per-property). It is
%% RESOLVER-ONLY — settlement_prep has zero agent leaves (no reasoning_domain); the whole
%% outcome is deterministic. It produces the `settlement_checklist` outcome.
%%
%% TWO STATES, ONE RESOLVER (blueprint §10 fill-path posture; engine-contract §11). The
%% DEFINING output of settlement_prep — the *dated* critical path with at-risk detection —
%% needs `contract_signed_date` + `settlement_date`. These arrive via `<from_transaction>`:
%% facts the user ATTESTS about their transaction, supplied post-attach through the
%% transaction submit (a resolver-only re-fill, no usage). They ride `Args` under the
%% `transaction` key (the turn loads the addendum's transaction slot into Data, the sibling
%% of property_card). The same dates may LATER also be extracted `<from_document>` from the
%% uploaded signed contract (the heavier upload pipeline — due_diligence B; one fact layer,
%% two mechanisms).
%%
%% - DATES ABSENT → HONEST-PARTIAL ([[base-turn-honest-partial-output]]). The KNOWABLE
%%   STRUCTURE now, every date PENDING (`dates_status` = pending_contract):
%%     - the standard settlement critical-path milestone sequence + dependency DAG;
%%     - the investor-specific milestones, entity-setup CONDITIONED on the upstream
%%       recommended_entity (applicable iff a legal entity must be established);
%%     - the state-conditional building-insurance-timing RULE (knowable without dates).
%%   No date is ever fabricated; at_risk_milestones = []; next_action asks for the dates.
%%
%% - DATES PRESENT → `dates_status` = active. Each milestone gets a due_date, back-calculated
%%   from the two attested dates. TWO TIERS of date, and the distinction is load-bearing for
%%   the ASIC line ([[verify-regulated-figures-by-postcondition]] — never assert lender timing
%%   as fact):
%%     - STATUTORY/ANCHORED-EXACT, computed precisely: contract_signed = C (status `done` — we
%%       hold the signed date); cooling-off-bounded deposit + building/pest = C + the per-state
%%       cooling-off business days (kb.cooling-off.by-state); settlement_funds_released +
%%       title_registered + keys_received = S (one simultaneous electronic event,
%%       kb.pexa.settlement); insurance_bound = state-conditional (QLD risk passes the business
%%       day after contract → C+1bd; NSW/VIC → by settlement, kb.insurance.timing-of-risk-pass).
%%     - LENDER-POLICY-INDICATIVE, back-calculated from S as TYPICAL timing (kb.lender-docs.
%%       standard-timeline is explicit these "vary by lender and must be confirmed" — never
%%       asserted): finance_approval_unconditional = S-14d, loan_documents_signed = S-7d, each
%%       clamped into [C, S]. The indicative caveat rides next_action_active copy (not a
%%       per-milestone field — the outcome schema carries no tier slot, and the dated path
%%       stays WITHIN the committed schema).
%%   at_risk = a milestone whose due_date is strictly before today (the engine has NO
%%   per-milestone completion signal, so "at-risk" means "the date has passed — confirm
%%   status", NOT "we know it is incomplete"; the at_risk_reason copy states exactly that).
%%   Business-day arithmetic skips weekends only (no public-holiday calendar) — flagged in
%%   next_action_active copy as an honest approximation.
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

-define(SETTLE,  <<"kb.settlement.process-by-state">>).
-define(INS,     <<"kb.insurance.timing-of-risk-pass">>).
-define(ENTITY,  <<"kb.investor.entity-setup-timeline">>).
-define(DEPREC,  <<"kb.investor.depreciation-schedule-procurement">>).
-define(PM,      <<"kb.investor.property-management-appointment-timeline">>).
-define(COPY,    <<"kb.copy.settlement">>).
-define(COOLING, <<"kb.cooling-off.by-state">>).
-define(PEXA,    <<"kb.pexa.settlement">>).
-define(LENDER,  <<"kb.lender-docs.standard-timeline">>).

-spec fill(map(), map()) -> {map(), binary(), map()}.
fill(Args, Upstream) ->
    Pf     = maps:get(<<"property_fit_investor">>, Upstream, #{}),
    Tax    = maps:get(<<"tax_optimised_structure">>, Upstream, #{}),
    State  = maps:get(<<"state">>, Pf, null),
    PType  = maps:get(<<"property_type">>, Pf, null),
    Entity = maps:get(<<"recommended_entity">>, Tax, null),
    Outcome = case transaction_dates(maps:get(transaction, Args, undefined)) of
                  none    -> pending_outcome(State, PType, Entity);
                  {C, S}  -> active_outcome(State, PType, Entity, C, S)
              end,
    %% Record all nine anchors the resolver depends on (the three date-arithmetic anchors
    %% power the dated path; recorded always for a stable provenance set).
    KbVersions = fh_engine_kb:kb_anchors(
                   [?SETTLE, ?INS, ?ENTITY, ?DEPREC, ?PM, ?COPY,
                    ?COOLING, ?PEXA, ?LENDER]),
    {Outcome, <<"checklist">>, KbVersions}.

%% --- pending (dates absent — honest-partial) --------------------------------

pending_outcome(State, PType, Entity) ->
    #{<<"dates_status">>             => <<"pending_contract">>,
      <<"settlement_date">>          => null,
      <<"critical_path_milestones">> => critical_path_pending(),
      <<"investor_milestones">>      => investor_milestones_pending(Entity),
      <<"insurance_timing_rule">>    => insurance_rule(State, PType),
      <<"at_risk_milestones">>       => [],
      <<"next_action_for_user">>     => copy(<<"next_action">>)}.

%% the standard settlement critical-path sequence + dependency DAG (property-generic). Dates are
%% PENDING — every due_date null, status pending — until contract dates exist.
critical_path_pending() ->
    [mil_pending(<<"contract_signed">>,                 null),
     mil_pending(<<"deposit_paid_to_trust">>,           <<"contract_signed">>),
     mil_pending(<<"building_pest_satisfactory">>,      <<"contract_signed">>),
     mil_pending(<<"finance_approval_unconditional">>,  <<"contract_signed">>),
     mil_pending(<<"loan_documents_signed">>,           <<"finance_approval_unconditional">>),
     mil_pending(<<"insurance_bound">>,                 <<"contract_signed">>),
     mil_pending(<<"settlement_funds_released">>,       <<"loan_documents_signed">>),
     mil_pending(<<"title_registered">>,                <<"settlement_funds_released">>),
     mil_pending(<<"keys_received">>,                   <<"title_registered">>)].

mil_pending(Id, Dep) ->
    #{<<"id">>         => Id,
      <<"name">>       => copy(<<"mil_", Id/binary>>),
      <<"due_date">>   => null,
      <<"status">>     => <<"pending">>,
      <<"dependency">> => Dep}.

%% the investor-specific milestones. entity-setup is conditioned on the upstream recommended_entity;
%% the rest are always-applicable for an investor.
investor_milestones_pending(Entity) ->
    [inv_pending(<<"entity_setup">>,                   entity_applicable(Entity)),
     inv_pending(<<"quantity_surveyor_engaged">>,      true),
     inv_pending(<<"depreciation_schedule_received">>, true),
     inv_pending(<<"property_management_appointed">>,  true),
     inv_pending(<<"landlord_insurance_bound">>,       true)].

inv_pending(Id, Applicable) ->
    #{<<"id">>         => Id,
      <<"name">>       => copy(<<"inv_", Id/binary>>),
      <<"applicable">> => Applicable,
      <<"why">>        => copy(<<"inv_", Id/binary, "_why">>),
      <<"due_date">>   => null,
      <<"status">>     => <<"pending">>}.

%% --- active (dates present — the dated critical path) ------------------------

active_outcome(State, PType, Entity, C, S) ->
    Today = erlang:date(),
    Cp    = critical_path_dated(State, C, S, Today),
    Inv   = investor_milestones_dated(Entity, C, S, Today),
    #{<<"dates_status">>             => <<"active">>,
      <<"settlement_date">>          => fmt_date(S),
      <<"critical_path_milestones">> => Cp,
      <<"investor_milestones">>      => Inv,
      <<"insurance_timing_rule">>    => insurance_rule(State, PType),
      <<"at_risk_milestones">>       => at_risk(Cp ++ Inv),
      <<"next_action_for_user">>     => copy(<<"next_action_active">>)}.

%% Each milestone's due_date is back-calculated from the two attested dates. See the module
%% header for the per-milestone tier (statutory/anchored-exact vs lender-policy-indicative).
critical_path_dated(State, C, S, Today) ->
    CoolEnd = add_business_days(C, cooling_off_days(State)),
    Finance = clamp(sub_days(S, 14), C, S),
    LoanDoc = clamp(sub_days(S, 7),  C, S),
    InsDate = insurance_due_date(State, C, S),
    [mil_done(<<"contract_signed">>,                null, C),
     mil_dated(<<"deposit_paid_to_trust">>,         <<"contract_signed">>,                CoolEnd, Today),
     mil_dated(<<"building_pest_satisfactory">>,    <<"contract_signed">>,                CoolEnd, Today),
     mil_dated(<<"finance_approval_unconditional">>,<<"contract_signed">>,                Finance, Today),
     mil_dated(<<"loan_documents_signed">>,         <<"finance_approval_unconditional">>, LoanDoc, Today),
     mil_dated(<<"insurance_bound">>,               <<"contract_signed">>,                InsDate, Today),
     mil_dated(<<"settlement_funds_released">>,     <<"loan_documents_signed">>,          S,       Today),
     mil_dated(<<"title_registered">>,              <<"settlement_funds_released">>,      S,       Today),
     mil_dated(<<"keys_received">>,                 <<"title_registered">>,               S,       Today)].

%% contract_signed is the one milestone we KNOW is complete (we hold the signed date) → `done`,
%% never at-risk.
mil_done(Id, Dep, Date) ->
    #{<<"id">>         => Id,
      <<"name">>       => copy(<<"mil_", Id/binary>>),
      <<"due_date">>   => fmt_date(Date),
      <<"status">>     => <<"done">>,
      <<"dependency">> => Dep}.

mil_dated(Id, Dep, Date, Today) ->
    #{<<"id">>         => Id,
      <<"name">>       => copy(<<"mil_", Id/binary>>),
      <<"due_date">>   => fmt_date(Date),
      <<"status">>     => date_status(Date, Today),
      <<"dependency">> => Dep}.

%% entity-setup, if applicable, had to be established BEFORE contract → due C, status `done`.
%% The post-settlement investor milestones get dates relative to settlement.
investor_milestones_dated(Entity, C, S, Today) ->
    [inv_entity(entity_applicable(Entity), C),
     inv_dated(<<"quantity_surveyor_engaged">>,      true, S,               Today),
     inv_dated(<<"depreciation_schedule_received">>, true, add_days(S, 14), Today),
     inv_dated(<<"property_management_appointed">>,  true, S,               Today),
     inv_dated(<<"landlord_insurance_bound">>,       true, S,               Today)].

inv_entity(false, _C) ->
    inv_pending(<<"entity_setup">>, false);
inv_entity(true, C) ->
    Base = inv_pending(<<"entity_setup">>, true),
    Base#{<<"due_date">> => fmt_date(C), <<"status">> => <<"done">>}.

inv_dated(Id, Applicable, Date, Today) ->
    Base = inv_pending(Id, Applicable),
    Base#{<<"due_date">> => fmt_date(Date), <<"status">> => date_status(Date, Today)}.

%% a milestone whose due_date is strictly in the past is at-risk; otherwise scheduled. No
%% completion signal exists, so at-risk is "the date has passed — confirm", not "incomplete".
date_status(Date, Today) ->
    case is_before(Date, Today) of
        true  -> <<"at_risk">>;
        false -> <<"scheduled">>
    end.

at_risk(Milestones) ->
    [#{<<"name">>   => maps:get(<<"name">>, M),
       <<"reason">> => copy(<<"at_risk_reason">>)}
     || M <- Milestones, maps:get(<<"status">>, M) =:= <<"at_risk">>].

%% per-state residential private-treaty cooling-off period (business days), kb.cooling-off.by-state:
%% NSW 5, VIC 3 (clear business days, approximated as 3 business days), QLD 5. Unknown → 5
%% (conservative). The deposit + building/pest milestones are bounded by the cooling-off window.
cooling_off_days(<<"NSW">>) -> 5;
cooling_off_days(<<"VIC">>) -> 3;
cooling_off_days(<<"QLD">>) -> 5;
cooling_off_days(_)         -> 5.

%% insurance_bound date is state-conditional (kb.insurance.timing-of-risk-pass): in QLD risk passes
%% to the buyer the first business day after contract → bind immediately; elsewhere by settlement.
insurance_due_date(<<"QLD">>, C, _S) -> add_business_days(C, 1);
insurance_due_date(_, _C, S)         -> S.

%% --- date arithmetic --------------------------------------------------------

%% parse an ISO yyyy-mm-dd binary to a calendar date tuple; the handler validates before storing,
%% so this is the defensive last line (bad/absent → none → pending branch).
transaction_dates(undefined) -> none;
transaction_dates(T) when is_map(T) ->
    case {parse_date(maps:get(<<"contract_signed_date">>, T, undefined)),
          parse_date(maps:get(<<"settlement_date">>, T, undefined))} of
        {{ok, C}, {ok, S}} -> {C, S};
        _                  -> none
    end;
transaction_dates(_) -> none.

parse_date(<<Y:4/binary, "-", M:2/binary, "-", D:2/binary>>) ->
    try
        Date = {binary_to_integer(Y), binary_to_integer(M), binary_to_integer(D)},
        case calendar:valid_date(Date) of
            true  -> {ok, Date};
            false -> error
        end
    catch _:_ -> error end;
parse_date(_) -> error.

fmt_date({Y, M, D}) ->
    iolist_to_binary(io_lib:format("~4..0w-~2..0w-~2..0w", [Y, M, D])).

add_days(Date, N) ->
    calendar:gregorian_days_to_date(calendar:date_to_gregorian_days(Date) + N).

sub_days(Date, N) -> add_days(Date, -N).

%% add N business days (skipping Sat/Sun; public holidays are NOT skipped — no calendar).
add_business_days(Date, 0) -> Date;
add_business_days(Date, N) when N > 0 ->
    Next = add_days(Date, 1),
    case calendar:day_of_the_week(Next) of
        W when W =< 5 -> add_business_days(Next, N - 1);
        _             -> add_business_days(Next, N)
    end.

is_before(D1, D2) ->
    calendar:date_to_gregorian_days(D1) < calendar:date_to_gregorian_days(D2).

%% clamp a date into [Lo, Hi] (by gregorian day).
clamp(D, Lo, Hi) ->
    G   = calendar:date_to_gregorian_days(D),
    GLo = calendar:date_to_gregorian_days(Lo),
    GHi = calendar:date_to_gregorian_days(Hi),
    calendar:gregorian_days_to_date(min(max(G, GLo), GHi)).

%% --- insurance-timing rule (knowable without dates) -------------------------

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

%% entity setup is needed only when a legal entity must be ESTABLISHED — a company or trust. Sole
%% or joint ownership is just names on the title; null = entity not yet decided → not applicable.
entity_applicable(<<"personal_sole">>) -> false;
entity_applicable(<<"joint">>)         -> false;
entity_applicable(null)                -> false;
entity_applicable(E) when is_binary(E) -> true;
entity_applicable(_)                   -> false.

%% a kb.copy.settlement template as a bilingual {vi,en} value (no placeholders → fetch directly).
-spec copy(binary()) -> fh_engine_i18n:localized().
copy(Id) ->
    fh_engine_kb:copy(?COPY, Id).
