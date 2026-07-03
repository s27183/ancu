-module(fh_engine_cross_border).

%% The base-turn `cross_border_funding` fill (blueprint fhb-foreign-au.md component 7,
%% NEW for Mode B — mode-b-wedge.md P2 slice 6, the LAST P2 unit, closing Mode-B P2). No
%% shared-name collision — a wholly new component, wholly new module. Reads
%% `family_context`'s outcome (VN-side contribution) and `cash_position`'s outcome
%% (the AU-side cash picture) — Inputs: family_context.outcome + cash_position.outcome.
%%
%% MODE-D DELTA (2026-07-03, flagged — the tracker's "no new decision needed" claim was
%% incomplete): Mode D has no `family_context` component (investor-foreign-au.md — Vietnam-
%% located investors are typically solo/couple, not parent-funding-child), so
%% `family_funding_plan` is never in Upstream on a Mode-D turn. transfer_amount/1 falls back
%% to `profile.available_capital_aud_equivalent` (investor_profile_foreign's own field) when
%% family_funding_plan is absent — the natural Mode-D substitute source, still PLACED never
%% recomputed. Both null at base regardless (no facts captured yet), so this is a genuine
%% code delta, not an observable-at-base one.
%%
%% VN-HALF PLACEHOLDER-BACKED (mode-b-wedge.md P1's own framing): `vn_compliance_steps`
%% draws on the three labelled-placeholder VN docs (kb.vn-capital-controls.*,
%% kb.vn-pdp.cross-border-data-transfer) — each PROCESS STEP (engage a licensed bank,
%% declare the purpose, confirm the current threshold) is knowable and asserted even
%% though the underlying regulated THRESHOLD VALUES those docs flag `is_placeholder`
%% stay unquoted here (never fabricated — the checklist item "confirm with your bank"
%% is honest; a specific dollar threshold would not be). `au_compliance_steps` draws on
%% the FULLY-GROUNDED P1 AML docs (kb.au-aml-ctf.*), REGULATED, not placeholder.
%%
%% PLACE, DON'T RECOMPUTE: total_transfer_amount_aud sums family_context's OWN
%% contribution_breakdown (VN-origin lines only), never re-derives a family capacity
%% figure independently.
%%
%% HONEST-PARTIAL: transfer_initiated_by_date / transfer_received_by_date stay null at
%% base (no settlement date exists yet — the same honest-partial discipline
%% fh_engine_settlement applies to its own dated milestones); critical_path_dependencies
%% is the STRUCTURAL 5-step sequence (kb.cross-border-settlement.coordination-best-
%% practices), assertable without dates since it is an ORDER, not a schedule.

-export([fill/2]).
%% exported for the conformance suite:
-export([transfer_amount/1, fx_cost/1, vn_compliance_steps/0, au_compliance_steps/0,
         critical_path_dependencies/0]).

-spec fill(map(), map()) -> {map(), binary(), [map()]}.
fill(_Args, Upstream) ->
    TransferAmount = case maps:is_key(<<"family_funding_plan">>, Upstream) of
        true ->
            FamilyPlan = maps:get(<<"family_funding_plan">>, Upstream, #{}),
            transfer_amount(maps:get(<<"contribution_breakdown">>, FamilyPlan, []));
        false ->
            %% Mode D: no family_context component — PLACE investor_profile_foreign's own
            %% capital fact instead (see the module header's "MODE-D DELTA" note).
            Profile = maps:get(<<"profile">>, Upstream, #{}),
            maps:get(<<"available_capital_aud_equivalent">>, Profile, null)
    end,
    Outcome = #{
        %% genuinely unknown without a live quote comparison across providers — the KB
        %% doc's own framing (kb.fx-providers.wise-ofx-bank-comparison) is a SELECTION
        %% FRAMEWORK, not a resolver-computable pick from facts alone at base.
        <<"provider">> => null,
        <<"total_transfer_amount_aud">> => TransferAmount,
        <<"estimated_fx_cost">> => fx_cost(TransferAmount),
        <<"vn_compliance_steps">> => vn_compliance_steps(),
        <<"au_compliance_steps">> => au_compliance_steps(),
        <<"transfer_initiated_by_date">> => null,
        <<"transfer_received_by_date">> => null,
        <<"critical_path_dependencies">> => critical_path_dependencies()
    },
    KbVersions = fh_engine_kb:kb_anchors(
        [<<"kb.fx-providers.wise-ofx-bank-comparison">>,
         <<"kb.fx.typical-spreads-vnd-aud">>,
         <<"kb.vn-capital-controls.sbv-thresholds-2026">>,
         <<"kb.vn-capital-controls.declared-purpose-categories">>,
         <<"kb.au-aml-ctf.bank-due-diligence-expectations">>,
         <<"kb.au-aml-ctf.source-of-funds-documentation">>,
         <<"kb.vn-pdp.cross-border-data-transfer">>]),
    {Outcome, <<"firb-workflow-card">>, KbVersions}.

%% sum family_context's OWN VN-origin contribution_breakdown lines (currency_origin =
%% VND) — PLACED, never a second computer for the family capacity figure. null when no
%% VN-origin line is captured yet (honest-partial, never 0 — matches
%% fh_engine_family:total_capacity/1's own null-not-zero discipline).
-spec transfer_amount([map()]) -> integer() | null.
transfer_amount(Breakdown) ->
    VnLines = [maps:get(<<"amount_aud">>, L, null)
               || L <- Breakdown, maps:get(<<"currency_origin">>, L, null) =:= <<"VND">>],
    case VnLines of
        [] -> null;
        _  ->
            case lists:any(fun(A) -> A =:= null end, VnLines) of
                true  -> null;
                false -> lists:sum(VnLines)
            end
    end.

%% kb.fx.typical-spreads-vnd-aud: planning_default_spread_pct (the conservative
%% specialist-route mid-point, seeds this figure per the doc's own Rules). null when the
%% transfer amount itself is unknown (never estimate a cost on an unknown base).
-spec fx_cost(integer() | null) -> integer() | null.
fx_cost(null) -> null;
fx_cost(Amount) when is_integer(Amount) ->
    Pct = kb_param(<<"kb.fx.typical-spreads-vnd-aud">>, <<"planning_default_spread_pct">>),
    round(Amount * Pct / 100).

%% VN-side process steps — knowable even though the underlying threshold VALUES
%% (kb.vn-capital-controls.*) are labelled placeholders; never a dollar figure or a
%% specific declared-purpose determination (that stays PENDING per the KB docs).
-spec vn_compliance_steps() -> [binary()].
vn_compliance_steps() ->
    [<<"engage_licensed_vn_bank_or_provider">>,
     <<"declare_transfer_purpose_as_property_investment">>,
     <<"confirm_current_sbv_threshold_and_documentation_with_bank">>].

%% AU-side process steps — the fully-grounded, REGULATED P1 AML/CTF docs (kb.au-aml-ctf.*),
%% not placeholder.
-spec au_compliance_steps() -> [binary()].
au_compliance_steps() ->
    [<<"pre_engage_au_bank_before_transfer">>,
     <<"prepare_source_of_funds_letter">>,
     <<"expect_enhanced_due_diligence">>].

%% kb.cross-border-settlement.coordination-best-practices: the 5-step critical path
%% (structural ORDER, assertable without dates — the schedule itself is per-property/
%% dated, a settlement_prep concern, out of P2 scope).
-spec critical_path_dependencies() -> [binary()].
critical_path_dependencies() ->
    [<<"firb_approval_in_force_through_settlement">>,
     <<"vn_outbound_transfer_initiated">>,
     <<"transfer_received_with_buffer">>,
     <<"au_ecdd_clearance">>,
     <<"funds_in_aud_trust">>].

%% --- KB access -----------------------------------------------------------------

kb_param(Slug, Key) ->
    {ok, Cj} = fh_engine_kb:kb_rules(Slug),
    Params = maps:get(<<"parameters">>, Cj),
    maps:get(<<"value">>, maps:get(Key, Params)).
