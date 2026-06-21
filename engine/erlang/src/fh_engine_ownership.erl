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

-export([fill/2]).
%% exported for the conformance harness (same anchors as the Python spec):
-export([maintenance_target/1, statutory_band/0, land_tax_check/1,
         graduation_target_lvr/0, land_tax_threshold/1, has_fhg/1]).

-define(COPY, <<"kb.copy.ownership">>).   %% bilingual copy-templates (bilingual-content.md §3b)

%% --- entry -------------------------------------------------------------------

-spec fill(map(), map()) -> {map(), binary(), [map()]}.
fill(Args, Upstream) ->
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
