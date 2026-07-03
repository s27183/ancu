-module(fh_engine_ownership).

%% The base-turn `ownership_planning` fill — mechanism (B) formula code (the same
%% class as fh_engine_cash; agentic-boundary §40/§98, [[engine-seam-build-discipline]]).
%% It projects post-settlement ongoing costs + lifecycle alerts from onboarding-only
%% facts, honestly partial: the mortgage P&I (and any total that includes it) is
%% PENDING at base — no firm loan/rate, no upstream repayment field — so we surface
%% what IS knowable (the non-mortgage statutory cost band, the 1%-of-value maintenance
%% reserve, the PPOR land-tax status, and the armed lifecycle alerts) and leave the
%% rest null. Design + the computable/pending boundary: docs/architecture/ongoing-costs-projection.md.
%%
%% VERIFICATION DIFFERS from stamp duty: these are KB-curated INDICATIVE estimates,
%% not regulated figures with an official calculator. Conformance asserts the formula
%% reads the KB band + applies the stated arithmetic (ground truth = the KB params,
%% the SOT), NOT an external calculator. The one regulated postcondition is the PPOR
%% land-tax exemption status. KB supplies the data; code supplies the arithmetic.
%%
%% SCOPE (base turn): statutory cost band, maintenance reserve, land-tax status,
%% graduation target LVR, armed alerts. PENDING (refine/per-property): mortgage P&I +
%% totals, estimated graduation year, refi-window date, strata (needs property type),
%% utilities + building insurance (no KB band / property-specific).

-export([fill/2, fill_investor/2, fill_foreign_investor/2]).
%% exported for the conformance harness (same anchors as the Python spec):
-export([maintenance_target/1, statutory_band/0, land_tax_check/1,
         graduation_target_lvr/0, land_tax_threshold/1, has_fhg/1]).
%% exported for the Mode-B foreign-person conformance suite:
-export([fill_foreign/2, vacancy_fee_at_risk/1]).

-define(COPY, <<"kb.copy.ownership">>).   %% bilingual copy-templates (bilingual-content.md §3b)
-define(COPY_INV, <<"kb.copy.ownership-investor">>).  %% Mode-C investor copy doc
-define(COPY_FOREIGN, <<"kb.copy.ownership-foreign">>).  %% Mode-B foreign-person copy doc
-define(COPY_FOREIGN_INV, <<"kb.copy.ownership-foreign-investor">>).  %% Mode-D copy doc

%% --- entry -------------------------------------------------------------------

%% Mode DISPATCH (the FIRST real branch fill/2 has ever had — mode-b-wedge.md P2 slice 5):
%% Mode B reuses the SAME component name `ownership_planning` (unlike Mode C's distinct
%% `ownership_planning_investor`, dispatched separately by fh_engine_fill), discriminated
%% by Args.firb_required_any — the SAME flag buyer_profile/1, mortgage_finance, cash_
%% position, and the compliance FIRB gate all key on. fill_domestic/2 is the pre-existing
%% body, renamed verbatim (byte-identical — zero regression); fill_foreign/2 is new.
-spec fill(map(), map()) -> {map(), binary(), [map()]}.
fill(Args, Upstream) ->
    case maps:get(firb_required_any, Args, false) of
        true  -> fill_foreign(Args, Upstream);
        false -> fill_domestic(Args, Upstream)
    end.

-spec fill_domestic(map(), map()) -> {map(), binary(), [map()]}.
fill_domestic(Args, Upstream) ->
    Onboarding = maps:get(onboarding, Args, #{}),
    Ceiling = ceiling(maps:get(<<"target_price_range">>, Onboarding, null)),
    Intent  = maps:get(intent, Args, <<"owner_occupier">>),
    State   = onboarding_state(Args),
    Stack   = maps:get(<<"scheme_stack">>, Upstream, #{}),
    HasFhg  = has_fhg(Stack),
    LandTax = land_tax_check(Intent),
    Outcome = ongoing_obligations(Ceiling, Intent, State, HasFhg, LandTax),
    KbVersions = fh_engine_kb:kb_anchors(
        [<<"kb.ongoing-costs.rates-water-strata">>,
         <<"kb.maintenance.budget-by-property-type">>,
         <<"kb.land-tax.ppor-exemption">>,
         <<"kb.graduation.lvr80">>,
         <<"kb.refinance.windows-and-triggers">>]),
    {Outcome, <<"data-table">>, KbVersions}.

%% --- Mode-B foreign-person ownership_planning (ongoing_obligations, 7-field) --
%% blueprint fhb-foreign-au.md component 11 (mode-b-wedge.md P2 slice 5) — vacancy-fee
%% monitoring + non-resident tax awareness, replacing Mode A's land-tax/graduation/FHG
%% framing (not applicable to a foreign person).
%%
%% PLACE, DON'T RECOMPUTE: vacancy_fee_at_risk_amount = the vacancy-fee MULTIPLIER
%% (kb.firb.vacancy-fee-double-from-2024, currently 2× for any vacancy year starting
%% on/after 9 Apr 2024 — every Mode-B purchase today) applied to firb_workflow's OWN
%% total_firb_fee_payable (Upstream.firb_status) — the dollar base is never re-derived
%% from price here, only the multiplier is code's job ([[place-upstream-figures-dont-recompute]]).
%%
%% HONEST-PARTIAL, a flagged gap not invented around: current_year_occupancy_status and
%% non_resident_tax_filing_required both depend on the property's OCCUPANCY INTENT
%% (kb.non-resident-tax.withholding-on-rental-income: filing is required only when the
%% property produces income) — but buyer_profile_foreign's outcome carries no occupancy-
%% intent field yet (the blueprint's own component-1 params has `intent.intended_use`,
%% never wired into the profile OUTCOME schema I built in P2 slice 1). Rather than guess
%% a default, both stay null (undetermined) until a refine turn captures occupancy intent.
%% mode_switch_eligible starts false — no PR/citizenship-grant evidence exists at base
%% (buyer_profile_foreign's applicant.citizenship_status/visa_class are null); it flips
%% true only on a future refine/event turn that reveals the status change (the tracker's
%% "mode_switch_eligible on PR grant" — that event-detection mechanism is itself a later
%% unit, not built here; this fill only sets the honest starting value).
-spec fill_foreign(map(), map()) -> {map(), binary(), [map()]}.
fill_foreign(_Args, Upstream) ->
    FirbStatus = maps:get(<<"firb_status">>, Upstream, #{}),
    Fee = maps:get(<<"total_firb_fee_payable">>, FirbStatus, null),
    Outcome = #{
        <<"total_monthly_outgoings_estimate">> => null,   %% pending: mortgage P&I unknown at base
        <<"total_annual_outgoings_estimate">>  => null,   %% pending: as above
        <<"vacancy_fee_at_risk_amount">>       => vacancy_fee_at_risk(Fee),
        <<"current_year_occupancy_status">>    => null,   %% pending: occupancy intent not yet captured
        <<"non_resident_tax_filing_required">> => null,   %% pending: as above
        <<"alert_triggers_armed">>             => foreign_alerts(Fee),
        <<"mode_switch_eligible">>             => false   %% honest starting value; no status-change evidence yet
    },
    KbVersions = fh_engine_kb:kb_anchors(
        [<<"kb.ongoing-costs.rates-water-strata">>,
         <<"kb.maintenance.budget-by-property-type">>,
         <<"kb.graduation.lvr80">>, <<"kb.refinance.windows-and-triggers">>,
         <<"kb.firb.vacancy-fee-rules-2026">>,
         <<"kb.firb.vacancy-fee-double-from-2024">>,
         <<"kb.non-resident-tax.cgt-no-ppor-exemption">>,
         <<"kb.non-resident-tax.withholding-on-rental-income">>,
         <<"kb.non-resident-tax.foreign-resident-cgt-withholding">>]),
    {Outcome, <<"data-table">>, KbVersions}.

%% kb.firb.vacancy-fee-double-from-2024: multiplier applied to firb_workflow's own fee
%% figure (kb.firb.fee-schedule-current, PLACED not recomputed). null if the fee itself
%% is unknown (honest-partial — never a fabricated amount).
-spec vacancy_fee_at_risk(integer() | null) -> integer() | null.
vacancy_fee_at_risk(null) -> null;
vacancy_fee_at_risk(Fee) when is_integer(Fee) ->
    Multiplier = kb_param(<<"kb.firb.vacancy-fee-double-from-2024">>,
                          <<"multiplier_on_or_after_cutover">>),
    Fee * Multiplier.

%% the vacancy-declaration reminder (armed unconditionally — every Mode-B owner is
%% liable to the regime, kb.firb.vacancy-fee-rules-2026's lodgement trap) + the SAME
%% periodic loan-review reminder Mode A arms (mode-neutral, kb.refinance.windows-and-
%% triggers — reused via review_alert/0, no duplication).
foreign_alerts(Fee) ->
    [vacancy_alert(Fee), review_alert()].

vacancy_alert(null) ->
    #{<<"trigger">> => cf(<<"alert_vacancy_trigger">>),
      <<"action">>  => cf(<<"alert_vacancy_action_amount_pending">>)};
vacancy_alert(Fee) when is_integer(Fee) ->
    #{<<"trigger">> => cf(<<"alert_vacancy_trigger">>),
      <<"action">>  => cfp(<<"alert_vacancy_action">>,
                           #{<<"amount">> => fh_engine_money:money(vacancy_fee_at_risk(Fee))})}.

%% --- Mode-C investor ownership_planning_investor (portfolio_position) --------
%%
%% A PURE-resolver figure-owner (agent_leaves = []; the same class as fh_engine_cash:
%% fill_investor / fh_engine_disposition / yield_modelling). UNIQUE component name —
%% no shared-name collision with the FHB `ownership_planning` (fill/2 above), so this is
%% a clean sibling dispatched directly by fh_engine_fill; the FHB fill/2 is untouched
%% (zero regression by construction).
%%
%% HONEST-PARTIAL, not all-null: portfolio_position carries two array fields whose content
%% is mode-level, property-agnostic, and KB-grounded — the standing annual obligations of an
%% investment property and the investor lifecycle alerts — so we fill them at base (the FHB
%% ownership precedent does the same with its statutory band + armed alerts). The six FIGURE
%% fields are post-acquisition actuals (tracked cash flow, current LVR, equity built,
%% diversification across a portfolio, ready-for-next derived from LVR) — plan-first there is
%% no property and no actuals, so each is null (three-valued for the bool).
%%
%% `opportunities` is the opportunity-card surface (§11.9 `{ kind, modeled_benefit, action }`).
%% PER-PROPERTY + FIGURE-BEARING: emitted only when a figure off THIS property exists — never
%% padding the generic `alert_triggers_armed` cadences (which are mode-level, property-agnostic).
%% Base turn (no property) → []. The one such figure at attach is `equity_release`: the projected
%% releasable equity at the hold horizon (the leverage-into-next thesis made concrete), PLACED from
%% `disposition`'s growth projection ([[place-upstream-figures-dont-recompute]] — this component
%% OWNS the modeled_benefit it derives from the placed bands, the same class as disposition deriving
%% net from sale/selling/loan; no second computer for the placed sale/loan figures). The other two
%% `kind`s are deferred honest-partial: `rent_review`'s real uplift needs the in-place lease
%% (due_diligence B), `scale_up`'s readiness needs post-settlement actuals (`current_lvr`/
%% `equity_built`, null until owned) — both stay in the enum, unemitted at attach so the card never
%% duplicates the alerts or fabricates a dollar ([[base-turn-honest-partial-output]]).
%%
%% This reads `disposition` (a NEW upstream edge, added 2026-06-27 — see the blueprint DAG), so
%% ownership_planning_investor now runs AFTER disposition in both the base and per-property orders
%% (fh_engine_turn). The figures are removed from the LLM's reach: equity_release is a deterministic
%% resolver band off disposition's already-banded, growth-assumption-flagged projection
%% ([[no-judge-ground-the-producer]], [[verify-regulated-figures-by-postcondition]]).
%%
%% Cadences are qualitative, not month-numbered: the owning KB docs frame review intervals as
%% "a default, not a deadline" — the specific intervals live as editable parameters, not in the
%% reminder copy. Renderers = data-table + opportunity-card (the §11.9 pair; the engine now carries
%% the full renderer list, so the second renderer is reached — engine-contract §4).

-spec fill_investor(map(), map()) -> {map(), binary(), [map()]}.
fill_investor(_Args, Upstream) ->
    Outcome = #{
        %% post-acquisition actuals — no property/actuals at base
        <<"monthly_net_cash_flow_actual">>     => null,
        <<"ytd_cash_flow_vs_projection">>      => null,
        <<"current_lvr">>                      => null,
        <<"equity_built">>                     => null,
        <<"ready_for_next_property">>          => null,   %% derives from current_lvr (three-valued)
        <<"portfolio_diversification_score">>  => null,   %% no portfolio at base (future-aggregate)
        %% base-computable: KB-grounded, property-agnostic
        <<"annual_tax_obligations">>           => annual_obligations(),
        <<"alert_triggers_armed">>             => investor_alerts(),
        %% per-property figure-bearing: [] at base / no horizon, the equity_release band otherwise
        <<"opportunities">>                    => opportunities(Upstream)
    },
    KbVersions = fh_engine_kb:kb_anchors(
        [<<"kb.investor.property-management-vs-self-managed">>,
         <<"kb.investor.annual-tax-return-investor">>,
         <<"kb.investor.cash-flow-tracking">>,
         <<"kb.investor.portfolio-review-cadence">>,
         <<"kb.investor.scale-up-using-equity">>,
         <<"kb.investor.deposit-requirements-investment-loans">>,
         <<"kb.investor.land-tax-aggregation">>]),
    {Outcome, <<"data-table">>, KbVersions}.

%% --- opportunities (the opportunity-card surface) ----------------------------
%% Per-property, figure-bearing, honest-partial. At attach the only such figure is
%% equity_release; [] when there is no property (base) or no hold horizon (disposition null).
-spec opportunities(map()) -> [map()].
opportunities(Upstream) ->
    equity_release_opportunity(maps:get(<<"disposition">>, Upstream, #{})).

%% equity_release: releasable equity projected at the hold horizon H, placed from disposition's
%% sale_proceeds (projected value at H) + loan_payout (loan balance at H). [] unless both bands
%% are present (H set + loan known) — honest-partial, never fabricated.
equity_release_opportunity(Disp) when is_map(Disp) ->
    Sale = maps:get(<<"sale_proceeds">>, Disp, null),
    Loan = maps:get(<<"loan_payout">>, Disp, null),
    H    = maps:get(<<"horizon_years">>, Disp, null),
    case releasable_equity(Sale, Loan) of
        null -> [];
        Band -> [#{<<"kind">>            => <<"equity_release">>,
                   <<"modeled_benefit">> => Band,
                   <<"action">>          =>
                       cip(<<"opportunity_equity_release_action">>,
                           #{<<"horizon">> => H})}]
    end;
equity_release_opportunity(_) -> [].

%% releasable at an 80% refinance LVR = 0.8 * projected value - projected loan balance, as a
%% conservative band (low value with high loan, high value with low loan), clamped >= 0. The
%% value basis is sale_proceeds (a refinance pays no selling cost / CGT). null unless both inputs
%% are bands and the high end is positive (no opportunity to surface otherwise).
-spec releasable_equity([integer()] | null, [integer()] | null) -> [integer()] | null.
releasable_equity([SLo, SHi], [LLo, LHi])
  when is_integer(SLo), is_integer(SHi), is_integer(LLo), is_integer(LHi) ->
    Pct = release_lvr_pct(),
    Lo = max(0, round(SLo * Pct / 100) - LHi),
    Hi = max(0, round(SHi * Pct / 100) - LLo),
    case Hi > 0 of
        true  -> [Lo, Hi];
        false -> null
    end;
releasable_equity(_, _) -> null.

%% the no-LMI refinance LVR (100 - the no-LMI deposit %), KB-grounded (shared with cash_position).
release_lvr_pct() ->
    100 - kb_param(<<"kb.investor.deposit-requirements-investment-loans">>,
                   <<"deposit_no_lmi_pct">>).

%% the standing annual obligations of an investment property — bilingual prose, KB-grounded
%% (annual-tax-return-investor + land-tax-aggregation + property-management). Static copy.
annual_obligations() ->
    [ci(<<"obligation_tax_return">>),
     ci(<<"obligation_depreciation_schedule">>),
     ci(<<"obligation_land_tax_assessment">>),
     ci(<<"obligation_pm_review">>),
     ci(<<"obligation_keep_records">>)].

%% investor lifecycle alerts (the alert_triggers_armed surface) — each a {trigger, action}
%% pair of bilingual prose. Qualitative cadences (the KB frames them as defaults, not deadlines).
investor_alerts() ->
    [alert(<<"alert_rent_review_trigger">>, <<"alert_rent_review_action">>),
     alert(<<"alert_refi_review_trigger">>, <<"alert_refi_review_action">>),
     alert(<<"alert_depreciation_refresh_trigger">>, <<"alert_depreciation_refresh_action">>),
     alert(<<"alert_land_tax_aggregation_trigger">>, <<"alert_land_tax_aggregation_action">>)].

alert(TriggerId, ActionId) ->
    #{<<"trigger">> => ci(TriggerId), <<"action">> => ci(ActionId)}.

%% the investor copy doc — static templates (no params), so the localized value is used as-is.
-spec ci(binary()) -> fh_engine_i18n:localized().
ci(Id) -> fh_engine_kb:copy(?COPY_INV, Id).

%% the investor copy doc WITH {param} substitution (the opportunity-card action carries {horizon}).
-spec cip(binary(), #{binary() => fh_engine_i18n:param()}) -> fh_engine_i18n:localized().
cip(Id, Params) -> fh_engine_i18n:subst(fh_engine_kb:copy(?COPY_INV, Id), Params).

%% the Mode-B foreign-person copy doc — static / with {param} substitution (mirrors ci/cip).
-spec cf(binary()) -> fh_engine_i18n:localized().
cf(Id) -> fh_engine_kb:copy(?COPY_FOREIGN, Id).

-spec cfp(binary(), #{binary() => fh_engine_i18n:param()}) -> fh_engine_i18n:localized().
cfp(Id, Params) -> fh_engine_i18n:subst(fh_engine_kb:copy(?COPY_FOREIGN, Id), Params).

%% --- Mode-D ownership_planning_foreign_investor (portfolio_position_foreign) -
%% investor-foreign-au.md component 13. A PURE-resolver figure-owner (agent_leaves = []; same
%% class as fill_investor/2). UNIQUE component name — no shared-name collision, so this is a
%% clean sibling dispatched directly by fh_engine_fill (like fill_investor/2's own
%% ownership_planning_investor); the FHB fill/2 and fill_investor/2 stay untouched.
%%
%% Per the blueprint's OWN declared inputs (property_fit_investor_foreign + tax_optimised_
%% structure + cash_flow_projection — NO `disposition` edge, unlike Mode C's own
%% ownership_planning_investor), this component does NOT place disposition's equity_release
%% figure and its `portfolio_position_foreign` outcome schema carries no `opportunities`
%% field at all — genuinely simpler than Mode C's own sibling, not an oversight (flagged +
%% confirmed against the blueprint's own outcome-schema field list, mode-d-wedge.md P2).
%%
%% HONEST-PARTIAL, not all-null: like Mode C's ownership_planning_investor, the two obligation
%% arrays + the alert cadences are mode-level, property-agnostic, KB-grounded prose, so they
%% fill at base. The vacancy-fee alert PLACES firb_workflow's own fee figure (vacancy_fee_
%% at_risk/1, reused verbatim from fill_foreign/2 above — [[place-upstream-figures-dont-
%% recompute]], no second computer). The post-acquisition actuals (cash flow after
%% withholding, FRCGW reserve, ready-for-next, vacancy status) are null at base — no property,
%% no actuals. mode_switch_eligible_on_pr starts false, the same honest starting value as
%% Mode B's mode_switch_eligible (no PR/citizenship-grant evidence exists at base).
-spec fill_foreign_investor(map(), map()) -> {map(), binary(), [map()]}.
fill_foreign_investor(_Args, Upstream) ->
    FirbStatus = maps:get(<<"firb_status">>, Upstream, #{}),
    Fee = maps:get(<<"total_firb_fee_payable">>, FirbStatus, null),
    Outcome = #{
        %% post-acquisition actuals — no property/actuals at base.
        <<"monthly_net_cash_flow_after_withholding">> => null,
        <<"vacancy_fee_at_risk_status">>               => null,
        <<"frcgw_reserve_at_exit">>                    => null,
        <<"ready_for_next_property">>                  => null,   %% three-valued; needs actuals
        %% base-computable: KB-grounded, property-agnostic prose.
        <<"annual_au_tax_obligations">> => annual_au_obligations(),
        <<"annual_vn_tax_obligations">> => annual_vn_obligations(),
        <<"alert_triggers_armed">>      => foreign_investor_alerts(Fee),
        %% honest starting value — no status-change evidence yet (mirrors fill_foreign/2's
        %% own mode_switch_eligible default; the change-detection mechanism is a later unit).
        <<"mode_switch_eligible_on_pr">> => false
    },
    KbVersions = fh_engine_kb:kb_anchors(
        [<<"kb.investor.property-management-vs-self-managed">>,
         <<"kb.investor.annual-tax-return-investor">>,
         <<"kb.investor.cash-flow-tracking">>,
         <<"kb.investor.portfolio-review-cadence">>,
         <<"kb.firb.vacancy-fee-rules-2026">>,
         <<"kb.firb.vacancy-fee-double-from-2024">>,
         <<"kb.foreign-investor.repatriation-strategy">>,
         <<"kb.non-resident-tax.foreign-resident-cgt-withholding">>,
         <<"kb.foreign-investor.absentee-owner-management">>]),
    {Outcome, <<"data-table">>, KbVersions}.

%% AU-side standing obligations — bilingual prose, KB-grounded (annual tax return by
%% assessment not withholding, land tax + foreign/absentee surcharge, PM review reused from
%% the investor copy doc — single-owner, no duplication of an already-owned line).
annual_au_obligations() ->
    [cfi(<<"obligation_au_tax_return">>),
     cfi(<<"obligation_land_tax_foreign_surcharge">>),
     ci(<<"obligation_pm_review">>)].

%% VN-side obligation — structurally knowable (a filing obligation exists) even though the
%% specific VN rule is a labelled placeholder (kb.vn-tax.*); points to the buyer's own VN tax
%% advisor, never states a VN tax rule (the AU-side-full/VN-side-placeholder scoping decision).
annual_vn_obligations() ->
    [cfi(<<"obligation_vn_tax_filing">>)].

%% Mode-D lifecycle alerts: the vacancy-declaration reminder (reused verbatim from
%% fill_foreign/2 — armed unconditionally, same lodgement-trap discipline) + the periodic
%% loan-review reminder (mode-neutral, reused) + AU/VN tax filing deadlines + the FX
%% repatriation opportunity + the PR-grant mode-switch reminder.
foreign_investor_alerts(Fee) ->
    [vacancy_alert(Fee), review_alert(),
     alert_fi(<<"alert_au_tax_filing_deadline_trigger">>, <<"alert_au_tax_filing_deadline_action">>),
     alert_fi(<<"alert_vn_tax_filing_deadline_trigger">>, <<"alert_vn_tax_filing_deadline_action">>),
     alert_fi(<<"alert_fx_repatriation_trigger">>, <<"alert_fx_repatriation_action">>),
     alert_fi(<<"alert_pr_mode_switch_trigger">>, <<"alert_pr_mode_switch_action">>)].

%% {trigger, action} pair from the Mode-D copy doc (mirrors alert/2, distinct doc source).
alert_fi(TriggerId, ActionId) ->
    #{<<"trigger">> => cfi(TriggerId), <<"action">> => cfi(ActionId)}.

%% the Mode-D copy doc — static templates (no params).
-spec cfi(binary()) -> fh_engine_i18n:localized().
cfi(Id) -> fh_engine_kb:copy(?COPY_FOREIGN_INV, Id).

%% --- the ongoing_obligations outcome (honest partial) ------------------------
%% Filled: maintenance_reserve_target, recurring_costs_estimate.statutory_band,
%% graduation_milestone.target_lvr, alert_triggers_armed. Null/pending: the two
%% outgoings totals (P&I-dominated), estimated graduation year, and the strata/
%% utilities/insurance cost lines.

ongoing_obligations(Ceiling, Intent, State, HasFhg, LandTax) ->
    #{<<"total_monthly_outgoings_estimate">> => null,   %% pending: mortgage P&I unknown at base
      <<"total_annual_outgoings_estimate">>  => null,   %% pending: as above
      <<"maintenance_reserve_target">>       => maintenance_target(Ceiling),
      <<"recurring_costs_estimate">>         => recurring_costs(),
      <<"graduation_milestone">> =>
          #{<<"target_lvr">>     => graduation_target_lvr(),
            <<"estimated_year">> => null},             %% pending: needs the LVR trajectory
      <<"alert_triggers_armed">> => alerts(HasFhg, LandTax, State, Intent),
      <<"land_tax_check">> => LandTax}.

%% maintenance reserve = reserve_pct% of property value, at the range ceiling
%% (conservative, consistent with cash_position). Pct from KB, not a literal. Null
%% when no target range is set yet.
-spec maintenance_target(integer() | null) -> integer() | null.
maintenance_target(null) -> null;
maintenance_target(V) when is_integer(V) ->
    Pct = kb_param(<<"kb.maintenance.budget-by-property-type">>,
                   <<"reserve_pct_of_value_default">>),
    dollars(Pct * V / 100).

%% the recurring NON-mortgage costs. statutory_band (council + water) is computable
%% from KB now; strata needs the property type (no property at base), utilities +
%% building insurance have no KB band / are property-specific (refine/per-property).
recurring_costs() ->
    #{<<"statutory_band">>     => statutory_band(),
      <<"strata_levies">>      => null,   %% pending: needs property type (apartment/townhouse)
      <<"utilities">>          => null,   %% pending: no KB band (electricity/gas) - refine
      <<"building_insurance">> => null,   %% pending: sum-insured is property-specific - per-property
      <<"notes">> =>
          [copy(<<"note_indicative">>, #{}),
           copy(<<"note_mortgage_pending">>, #{})]}.

%% council + water annual band (strata excluded - applies only to strata title).
-spec statutory_band() -> map().
statutory_band() ->
    Slug = <<"kb.ongoing-costs.rates-water-strata">>,
    CouncilLo = kb_param(Slug, <<"council_rates_indicative_aud_year_low">>),
    CouncilHi = kb_param(Slug, <<"council_rates_indicative_aud_year_high">>),
    WaterLo   = kb_param(Slug, <<"water_indicative_aud_year_low">>),
    WaterHi   = kb_param(Slug, <<"water_indicative_aud_year_high">>),
    #{<<"low">>        => CouncilLo + WaterLo,
      <<"high">>       => CouncilHi + WaterHi,
      <<"period">>     => <<"year">>,
      <<"components">> => [<<"council_rates">>, <<"water">>]}.

%% --- land tax (the one regulated postcondition) ------------------------------
%% PPOR is exempt in all three states; the Mode-A owner-occupier (sole_occupier
%% default) is exempt. A non-owner-occupier purchase is land-tax-applicable. At base
%% the only occupancy signal is the onboarding intent; partial_rental/granny_flat
%% (to_verify) arrive on a refine turn via intended_occupancy_use (F12).
-spec land_tax_check(binary()) -> binary().
land_tax_check(<<"owner_occupier">>) ->
    case kb_param(<<"kb.land-tax.ppor-exemption">>, <<"ppor_exempt_all_states">>) of
        true -> <<"exempt_ppor">>;
        _    -> <<"to_verify">>
    end;
land_tax_check(_NonOwnerOccupier) ->
    <<"applicable">>.

-spec land_tax_threshold(binary()) -> integer().
land_tax_threshold(<<"NSW">>) ->
    kb_param(<<"kb.land-tax.ppor-exemption">>, <<"nsw_general_threshold_aud">>);
land_tax_threshold(<<"VIC">>) ->
    kb_param(<<"kb.land-tax.ppor-exemption">>, <<"vic_threshold_aud">>);
land_tax_threshold(<<"QLD">>) ->
    kb_param(<<"kb.land-tax.ppor-exemption">>, <<"qld_threshold_individual_aud">>);
land_tax_threshold(<<"WA">>) ->
    kb_param(<<"kb.land-tax.ppor-exemption">>, <<"wa_general_threshold_aud">>);
land_tax_threshold(<<"TAS">>) ->
    kb_param(<<"kb.land-tax.ppor-exemption">>, <<"tas_general_threshold_aud">>);
land_tax_threshold(_) -> null.

%% --- lifecycle alerts (the opportunity-card surface) -------------------------
%% Armed from scheme_stack + KB triggers, valuable even while the cost totals are
%% pending: the FHG graduation window (if FHG is in the stack), the periodic rate
%% review cadence, and the land-tax mode-switch (PPOR exemption ends if the home is
%% later rented out).

alerts(HasFhg, LandTax, State, Intent) ->
    fhg_alert(HasFhg)
    ++ [review_alert()]
    ++ land_tax_alert(LandTax, State, Intent).

fhg_alert(true) ->
    Lvr = graduation_target_lvr(),
    [#{<<"trigger">> => copy(<<"alert_fhg_trigger">>, #{}),
       <<"action">>  => copy(<<"alert_fhg_action">>, #{<<"lvr">> => Lvr})}];
fhg_alert(false) -> [].

review_alert() ->
    Cadence = kb_param(<<"kb.refinance.windows-and-triggers">>,
                       <<"refinance_review_cadence_months">>),
    #{<<"trigger">> => copy(<<"alert_review_trigger">>, #{<<"cadence">> => Cadence}),
      <<"action">>  => copy(<<"alert_review_action">>, #{})}.

land_tax_alert(<<"exempt_ppor">>, State, <<"owner_occupier">>) ->
    %% Honest-partial: the land-tax threshold is state-specific, so it is null for any
    %% state we hold no figure for — notably the mode-independent base projection (State
    %% = "ALL"). Never interpolate the figure then (that leaked "$null"); use the
    %% no-figure copy variant. money/1 is only ever handed a known integer.
    Action = case land_tax_threshold(State) of
                 null ->
                     copy(<<"alert_landtax_action_nothreshold">>, #{});
                 Threshold ->
                     copy(<<"alert_landtax_action">>,
                          #{<<"state">> => State,
                            <<"threshold">> => fh_engine_money:money(Threshold)})
             end,
    [#{<<"trigger">> => copy(<<"alert_landtax_trigger">>, #{}),
       <<"action">>  => Action}];
land_tax_alert(_, _, _) -> [].

%% --- KB access + helpers -----------------------------------------------------

-spec graduation_target_lvr() -> integer().
graduation_target_lvr() ->
    kb_param(<<"kb.graduation.lvr80">>, <<"graduation_lvr_threshold_pct">>).

%% detect the FHG in the eligibility scheme_stack by role (deposit_guarantee),
%% not by name string - the role is the stable key.
-spec has_fhg(map()) -> boolean().
has_fhg(Stack) ->
    Schemes = maps:get(<<"applicable_schemes">>, Stack, []),
    lists:any(fun(S) -> maps:get(<<"role">>, S, <<>>) =:= <<"deposit_guarantee">> end,
              Schemes).

kb_param(Slug, Key) ->
    {ok, Cj} = fh_engine_kb:kb_rules(Slug),
    Params = maps:get(<<"parameters">>, Cj),
    maps:get(<<"value">>, maps:get(Key, Params)).

%% subst a kb.copy.ownership template into a bilingual {vi,en} value (no Vietnamese
%% literal in Erlang, no io:format ~s — bilingual-content.md §3b).
-spec copy(binary(), #{binary() => fh_engine_i18n:param()}) -> fh_engine_i18n:localized().
copy(Id, Params) ->
    fh_engine_i18n:subst(fh_engine_kb:copy(?COPY, Id), Params).

ceiling([_Lo, Hi]) when is_integer(Hi) -> Hi;
ceiling(_)                             -> null.

onboarding_state(Args) ->
    Onboarding = maps:get(onboarding, Args, #{}),
    maps:get(<<"state">>, Onboarding, <<"NSW">>).

%% round half up to whole dollars (value is always >= 0). Defined identically in the
%% Python spec so the cross-language conformance is exact (matches fh_engine_cash).
dollars(X) when X =< 0 -> 0;
dollars(X)            -> trunc(X + 0.5).
