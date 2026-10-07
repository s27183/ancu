#!/usr/bin/env escript
%%! -sname fh_disposition_conformance
%%
%% Conformance suite for fh_engine_disposition (the base-turn `disposition` fill — the
%% TERMINAL financial component, lifecycle-simulation-model §8.5/§8.6). Loads the SAME
%% materialized artifact the engine loads (priv/kb/artifact.json via fh_engine_kb) and
%% asserts what the commit seam relies on:
%%   1. FIGURES — sale_proceeds / selling_costs / loan_payout / net_proceeds /
%%      full_horizon_net_position computed EXACTLY (growth-banded sale, commission-banded
%%      selling, P&I-amortised loan payout, interval-arithmetic net + full-horizon roll-up).
%%   2. PLACE-NEVER-RECOMPUTE — the full-horizon roll-up PLACES budget_envelope's acquire
%%      figure + ownership's hold band × H; net_proceeds is the exported interval arithmetic
%%      of the owned dispose figures ([[place-upstream-figures-dont-recompute]]).
%%   3. CGT (Mode-A main residence) — `cgt: null` always; `cgt_status` exempt for the clean
%%      owner-occupier resident case, to_verify once a trap applies; to_verify ⟹ net PENDING
%%      (Mode A NEVER estimates a taxable gain — [[verify-regulated-figures-by-postcondition]]).
%%   4. HONEST-PARTIAL — H unset ⟹ every projected figure null + the set-horizon invitation;
%%      H set but loan unknown ⟹ loan/net/full null, sale/selling banded; never a fabricated
%%      point ([[base-turn-honest-partial-output]]).
%%   5. dispose_cash_events — mirror the cash_event shape (phase=dispose, timing=one_off,
%%      source_component=disposition), honest-partial drop on null amount (purchase_journey
%%      PLACES these on the swimlane's Dispose column, TW3).
%%   6. GROWTH PLACEHOLDER surfaced + bilingual key_assumptions (the §8.4 ASIC discipline).
%%   7. LAYER-1 CONFORMANCE — every state passes fh_engine_outcome:validate/2 against the
%%      compiled `disposition` schema (the fail-closed commit-seam check is strict now).
%%
%% Run from engine/erlang with the build libs on the path (no Postgres needed):
%%   ERL_LIBS=_build/default/lib escript test/disposition_conformance.escript

-mode(compile).

main(_) ->
    ok = fh_engine_kb:load(),
    io:format("disposition conformance — fh_engine_disposition (terminal dispose-phase figure-owner)~n~n"),
    R = lists:flatten([figure_cases(), arithmetic_cases(), cgt_cases(),
                       investor_cases(), per_property_cases(),
                       honest_partial_cases(), event_cases(), assumption_cases(),
                       rate_source_cases(), layer1_cases()]),
    Fails = [X || X <- R, X =:= fail],
    io:format("~n================================================================~n"),
    case Fails of
        [] ->
            io:format("PASS — all ~p disposition anchors hold~n", [length(R)]),
            halt(0);
        _ ->
            io:format("FAIL — ~p anchor(s) mismatched~n", [length(Fails)]),
            halt(1)
    end.

%% --- fixtures ----------------------------------------------------------------
%% The canonical full upstream: H=10, target ceiling 800000, loan known (560000 @ 6.0%),
%% acquire band [200000,205000], hold band [2200,3600]/yr, clean owner-occupier resident.

profile(Occupancy) ->
    #{<<"hold_horizon_years">>     => 10,
      <<"target_price_range">>     => [600000, 800000],
      <<"intended_occupancy_use">> => Occupancy,
      <<"tax_residency">>          => <<"resident">>}.

budget()   -> #{<<"total_cash_required">> => [200000, 205000]}.
%% the REAL mortgage_plan shape: loan_structure_recommendation.rate holds the agent's
%% rate-STRUCTURE enum ("variable"/"fixed_1yr"/…), NOT a numeric rate. loan_payout amortises
%% at the KB representative product rate (6.0%), so it must NOT read this field as a number
%% (seam B); rate_source_cases/0 proves the independence directly.
mortgage() -> #{<<"expected_borrowing_capacity">> => 560000,
                <<"loan_structure_recommendation">> =>
                    #{<<"type">> => <<"principal_and_interest">>,
                      <<"rate">> => <<"variable">>, <<"offset">> => null}}.
ownership()-> #{<<"recurring_costs_estimate">> =>
                   #{<<"statutory_band">> => #{<<"low">> => 2200, <<"high">> => 3600}}}.

full_upstream() ->
    #{<<"profile">> => profile(<<"sole_occupier">>), <<"budget_envelope">> => budget(),
      <<"mortgage_plan">> => mortgage(), <<"ongoing_obligations">> => ownership()}.

fill(Upstream) ->
    {Outcome, Renderer, _Kb} = fh_engine_disposition:fill(#{}, Upstream),
    {Outcome, Renderer}.

g(Outcome, K) -> maps:get(K, Outcome).

%% --- investor (Mode C) fixtures ---------------------------------------------
%% Same H=10 / ceiling 800000 as Mode A (so sale_proceeds matches), but the investor upstream:
%% a tax_optimised_structure (the mode discriminator + CGT determinants), budget_envelope_investor
%% (loan_amount + acquire), and a cash_flow_projection (a negatively-geared −8000/yr hold).

inv_profile(Residency) ->
    #{<<"hold_horizon_years">> => 10,
      <<"target_price_range">> => [600000, 800000],
      <<"applicants">> => [#{<<"role">> => <<"primary">>,
                             <<"tax">>  => #{<<"residency_for_tax">> => Residency}}]}.

inv_tax(Entity, Rate, Clawback) -> inv_tax(Entity, Rate, Clawback, true).
inv_tax(Entity, Rate, Clawback, Eligible) ->
    #{<<"recommended_entity">>             => Entity,
      <<"cgt_discount_eligible">>          => Eligible,
      <<"cgt_marginal_rate">>              => Rate,
      <<"cost_base_depreciation_clawback">> => Clawback}.

inv_budget()   -> #{<<"total_cash_required">> => [200000, 205000], <<"loan_amount">> => 560000}.
inv_cashflow() -> #{<<"cash_flow_before_tax_year_1">> => -8000}.

inv_upstream(Profile, Tax) ->
    #{<<"profile">>                  => Profile,
      <<"budget_envelope_investor">> => inv_budget(),
      <<"cash_flow_projection">>     => inv_cashflow(),
      <<"tax_optimised_structure">>  => Tax}.

ev_ids(Outcome) -> [maps:get(<<"id">>, E) || E <- g(Outcome, <<"dispose_cash_events">>)].

%% --- 1. figures (exact) -----------------------------------------------------

figure_cases() ->
    {Outcome, Renderer} = fill(full_upstream()),
    [check("renderer = calculator", Renderer, <<"calculator">>),
     check("horizon_years = 10", g(Outcome, <<"horizon_years">>), 10),
     check("sale_proceeds = ceiling 800000 × growth band over H=10", g(Outcome, <<"sale_proceeds">>),
           [975196, 1303116]),
     check("selling_costs = commission band × sale + legal + marketing", g(Outcome, <<"selling_costs">>),
           [16428, 56109]),
     check("loan_payout = P&I remaining balance at year 10 (560000 @ 6.0%)", g(Outcome, <<"loan_payout">>),
           [468640, 468640]),
     check("net_proceeds = sale − selling − loan − cgt (interval arithmetic)", g(Outcome, <<"net_proceeds">>),
           [450447, 818048]),
     check("full_horizon_net_position = net − acquire − hold×H (placed)",
           g(Outcome, <<"full_horizon_net_position">>), [209447, 596048])].

%% --- 2. place-never-recompute: net/full are the exported interval arithmetic ---

arithmetic_cases() ->
    {Outcome, _} = fill(full_upstream()),
    Sale  = g(Outcome, <<"sale_proceeds">>),
    Sell  = g(Outcome, <<"selling_costs">>),
    Loan  = g(Outcome, <<"loan_payout">>),
    %% Mode-A exempt ⟹ cgt contributes [0,0]; the exported net_proceeds/4 takes that band.
    NetFromExport  = fh_engine_disposition:net_proceeds(Sale, Sell, Loan, [0, 0]),
    FullFromExport = fh_engine_disposition:full_horizon(NetFromExport, budget(), ownership(), 10),
    [check("net_proceeds matches the exported interval arithmetic (no second computer)",
           g(Outcome, <<"net_proceeds">>), NetFromExport),
     check("full_horizon matches the exported roll-up (places acquire + hold×H)",
           g(Outcome, <<"full_horizon_net_position">>), FullFromExport),
     %% interval discipline: net_lo subtracts the HIGH cost ends, net_hi the LOW ends
     check("net_lo = sale_lo − selling_hi − loan_hi − cgt_hi",
           hd(g(Outcome, <<"net_proceeds">>)), 975196 - 56109 - 468640 - 0),
     check("net_hi = sale_hi − selling_lo − loan_lo − cgt_lo",
           lists:last(g(Outcome, <<"net_proceeds">>)), 1303116 - 16428 - 468640 - 0)].

%% --- 3. CGT (Mode-A main residence) -----------------------------------------

cgt_cases() ->
    {Clean, _}  = fill(full_upstream()),
    %% a trap: the dwelling is partly rented ⟹ to_verify (Mode A never estimates a gain).
    Rented = (full_upstream())#{<<"profile">> => profile(<<"partial_rental">>)},
    {Trap, _}  = fill(Rented),
    [check("clean owner-occupier: cgt = null", g(Clean, <<"cgt">>), null),
     check("clean owner-occupier: cgt_status = exempt", g(Clean, <<"cgt_status">>), <<"exempt">>),
     check("rented trap: cgt = null (NEVER an estimated gain)", g(Trap, <<"cgt">>), null),
     check("rented trap: cgt_status = to_verify", g(Trap, <<"cgt_status">>), <<"to_verify">>),
     %% to_verify ⟹ cgt contribution unknown ⟹ net + full stay PENDING (not a $0-tax assertion)
     check("rented trap: net_proceeds PENDING (null) — cgt unknown, never assumed $0",
           g(Trap, <<"net_proceeds">>), null),
     check("rented trap: full_horizon PENDING (null)",
           g(Trap, <<"full_horizon_net_position">>), null),
     %% the exported cgt/1 verdict surface
     check("cgt/1 sole_occupier+resident → {null, exempt}",
           fh_engine_disposition:cgt(profile(<<"sole_occupier">>)), {null, <<"exempt">>}),
     check("cgt/1 partial_rental → {null, to_verify}",
           fh_engine_disposition:cgt(profile(<<"partial_rental">>)), {null, <<"to_verify">>})].

%% --- 3b. CGT (Mode-C investor — the full-CGT path) --------------------------
%% COMPUTED for the clean case (resident individual, rate known, no clawback); to_verify (cgt
%% null → net PENDING) once a trap applies, with the indicative discounted gain still surfaced.

%% --- per-property (Slice B3c): the ATTACHED price drives the dispose figures ----------------
%% disposition re-runs in the Phase-B turn with property_fit_investor present. The dispose GROSS
%% figures use the attached price (920k), not the profile-range ceiling (800k); loan_payout
%% computes off cash_position's loan_amount; but cgt stays to_verify (rate null + clawback true =
%% the regulated conservative posture) → net + full_horizon null. This is the correct gated state.
per_property_cases() ->
    Pf = #{<<"price">> => 920000, <<"state">> => <<"NSW">>,
           <<"property_type">> => <<"established_house">>},
    Up = (inv_upstream(inv_profile(<<"resident">>),
                       inv_tax(<<"personal_sole">>, null, true)))#{   %% rate null + clawback true
             <<"property_fit_investor">> => Pf},
    {O, _} = fill(Up),
    [SaleLo, _] = g(O, <<"sale_proceeds">>),
    [check("per-property: sale_proceeds uses the ATTACHED 920k (lo > 1.0M; the base 800k gives 975196)",
           SaleLo > 1000000, true),
     check("per-property: loan_payout computes (cash_position loan_amount present, B3b)",
           is_list(g(O, <<"loan_payout">>)), true),
     check("per-property: taxable_gain computes (indicative pre-clawback band)",
           is_list(g(O, <<"taxable_gain">>)), true),
     check("per-property: cgt_status = to_verify (rate null + clawback true — regulated posture)",
           g(O, <<"cgt_status">>), <<"to_verify">>),
     check("per-property: cgt null (to_verify)", g(O, <<"cgt">>), null),
     check("per-property: net_proceeds null (cgt to_verify)", g(O, <<"net_proceeds">>), null),
     check("per-property: full_horizon_net_position null (net null — correctly regulated-gated)",
           g(O, <<"full_horizon_net_position">>), null),
     %% base behaviour unchanged: NO property_fit_investor → the profile ceiling (800k) basis.
     check("base (no property): sale_proceeds still uses the 800k ceiling (lo = 975196)",
           begin {B, _} = fill(inv_upstream(inv_profile(<<"resident">>),
                                            inv_tax(<<"personal_sole">>, null, true))),
                 [BLo, _] = g(B, <<"sale_proceeds">>), BLo end, 975196)].

investor_cases() ->
    Clean    = inv_upstream(inv_profile(<<"resident">>), inv_tax(<<"personal_sole">>, 37.0, false)),
    {C, CR}  = fill(Clean),
    Sale     = g(C, <<"sale_proceeds">>),
    Sell     = g(C, <<"selling_costs">>),
    Loan     = g(C, <<"loan_payout">>),
    Cgt      = g(C, <<"cgt">>),
    LoanExp  = fh_engine_disposition:loan_payout_investor(inv_budget(), 10),
    NetExp   = fh_engine_disposition:net_proceeds(Sale, Sell, Loan, Cgt),
    FullExp  = fh_engine_disposition:full_horizon_investor(NetExp, inv_budget(), inv_cashflow(), 10),
    Assumps  = g(C, <<"key_assumptions">>),
    Reform   = lists:any(fun(L) -> binary:match(maps:get(<<"en">>, L, <<>>), <<"2027">>) =/= nomatch end, Assumps),
    AllBilin = lists:all(fun bilingual/1, Assumps),
    %% held < 12 months (eligibility false) → 0% discount, full gain taxable, still computed.
    {U, _}   = fill(inv_upstream(inv_profile(<<"resident">>),
                                 inv_tax(<<"personal_sole">>, 37.0, false, false))),
    %% to_verify traps — clawback in play, a non-resident period, a trust entity, an unknown rate.
    {TV1, _} = fill(inv_upstream(inv_profile(<<"resident">>),     inv_tax(<<"personal_sole">>, 37.0, true))),
    {TV2, _} = fill(inv_upstream(inv_profile(<<"non_resident">>), inv_tax(<<"personal_sole">>, 37.0, false))),
    {TV3, _} = fill(inv_upstream(inv_profile(<<"resident">>),     inv_tax(<<"discretionary_trust">>, 37.0, false))),
    {TV4, _} = fill(inv_upstream(inv_profile(<<"resident">>),     inv_tax(<<"personal_sole">>, null, false))),
    [check("investor renderer = calculator", CR, <<"calculator">>),
     check("clean: taxable_gain = (sale − 800000 cost base) × 50% discount", g(C, <<"taxable_gain">>),
           [87598, 251558]),
     check("clean: cgt = taxable_gain × 37% marginal rate", Cgt, [32411, 93076]),
     check("clean: cgt_status = computed", g(C, <<"cgt_status">>), <<"computed">>),
     check("clean: loan_payout = investment-loan amortised @6.35% (no second computer)", Loan, LoanExp),
     check("clean: net_proceeds = exported interval arithmetic (sale−sell−loan−cgt)",
           g(C, <<"net_proceeds">>), NetExp),
     check("clean: full_horizon = net − acquire + signed hold×H (exported)",
           g(C, <<"full_horizon_net_position">>), FullExp),
     check("clean: 6 key_assumptions (horizon, growth, cgt, reform, selling, loan-rate)",
           length(Assumps), 6),
     check("clean: 2026-27 reform flag surfaced (1 Jul 2027)", Reform, true),
     check("clean: every investor assumption bilingual {vi,en}", AllBilin, true),
     check("clean: cgt dispose event emitted (out/government)", lists:member(<<"dispose_cgt">>, ev_ids(C)), true),
     %% Mode-C/D six-actor swimlane (fh_engine_journey:investor_actors/0) has NO "other" actor
     %% (renamed "services") — sale/selling MUST carry a counterparty that resolves in that set,
     %% or SwimlaneDiagram.svelte's by-declared-actor-id lookup silently drops the cell
     %% (2026-07-10 fix — see fh_engine_disposition:dispose_cash_events/5).
     check("clean: sale event counterparty = services (resolves in the investor 6-actor set)",
           maps:get(<<"counterparty">>, ev_by_id(g(C, <<"dispose_cash_events">>), <<"dispose_sale_proceeds">>)),
           <<"services">>),
     check("clean: selling_costs event counterparty = services",
           maps:get(<<"counterparty">>, ev_by_id(g(C, <<"dispose_cash_events">>), <<"dispose_selling_costs">>)),
           <<"services">>),
     %% exported cgt_investor/4 verdict surface
     check("cgt_investor/4 clean → {gain, cgt, computed}",
           fh_engine_disposition:cgt_investor(inv_profile(<<"resident">>),
               inv_tax(<<"personal_sole">>, 37.0, false), [975196, 1303116], 800000),
           {[87598, 251558], [32411, 93076], <<"computed">>}),
     %% held < 12 months: undiscounted, still computed
     check("held <12mo: taxable_gain undiscounted (0% discount)", g(U, <<"taxable_gain">>), [175196, 503116]),
     check("held <12mo: cgt = full gain × 37%", g(U, <<"cgt">>), [64823, 186153]),
     check("held <12mo: cgt_status = computed", g(U, <<"cgt_status">>), <<"computed">>),
     %% clawback trap: to_verify ⟹ cgt null ⟹ net/full PENDING; indicative gain STILL surfaced
     check("clawback: cgt_status = to_verify", g(TV1, <<"cgt_status">>), <<"to_verify">>),
     check("clawback: cgt = null (dollar deferred to a tax agent)", g(TV1, <<"cgt">>), null),
     check("clawback: net_proceeds PENDING", g(TV1, <<"net_proceeds">>), null),
     check("clawback: full_horizon PENDING", g(TV1, <<"full_horizon_net_position">>), null),
     check("clawback: indicative taxable_gain STILL surfaced", g(TV1, <<"taxable_gain">>), [87598, 251558]),
     check("clawback: cgt dispose event dropped (honest-partial)", lists:member(<<"dispose_cgt">>, ev_ids(TV1)), false),
     %% other traps: to_verify, cgt null
     check("non-resident period: cgt_status = to_verify", g(TV2, <<"cgt_status">>), <<"to_verify">>),
     check("non-resident period: cgt = null", g(TV2, <<"cgt">>), null),
     check("trust entity: cgt_status = to_verify", g(TV3, <<"cgt_status">>), <<"to_verify">>),
     check("trust entity: cgt = null", g(TV3, <<"cgt">>), null),
     check("rate unknown: cgt_status = to_verify", g(TV4, <<"cgt_status">>), <<"to_verify">>),
     check("rate unknown: cgt = null", g(TV4, <<"cgt">>), null)].

%% --- 4. honest-partial ------------------------------------------------------

honest_partial_cases() ->
    %% (a) no horizon ⟹ no disposal projection at all.
    NoH = (full_upstream())#{<<"profile">> =>
               (profile(<<"sole_occupier">>))#{<<"hold_horizon_years">> => null}},
    {A, _} = fill(NoH),
    %% (b) horizon set, loan unknown (empty mortgage_plan — the reserve_buffer precedent).
    NoLoan = (full_upstream())#{<<"mortgage_plan">> => #{}},
    {B, _} = fill(NoLoan),
    [check("H=null: sale PENDING", g(A, <<"sale_proceeds">>), null),
     check("H=null: selling PENDING", g(A, <<"selling_costs">>), null),
     check("H=null: loan PENDING", g(A, <<"loan_payout">>), null),
     check("H=null: net PENDING", g(A, <<"net_proceeds">>), null),
     check("H=null: full PENDING", g(A, <<"full_horizon_net_position">>), null),
     check("H=null: zero dispose_cash_events", length(g(A, <<"dispose_cash_events">>)), 0),
     check("H=null: only the set-horizon invitation assumption",
           length(g(A, <<"key_assumptions">>)), 1),
     %% loan-pending: sale/selling banded, loan/net/full PENDING — no fabricated point.
     check("H set, loan unknown: sale banded", g(B, <<"sale_proceeds">>), [975196, 1303116]),
     check("H set, loan unknown: selling banded", g(B, <<"selling_costs">>), [16428, 56109]),
     check("H set, loan unknown: loan PENDING", g(B, <<"loan_payout">>), null),
     check("H set, loan unknown: net PENDING", g(B, <<"net_proceeds">>), null),
     check("H set, loan unknown: full PENDING", g(B, <<"full_horizon_net_position">>), null)].

%% --- 5. dispose_cash_events shape + honest-partial drop ---------------------

event_cases() ->
    {Full, _}   = fill(full_upstream()),
    Events      = g(Full, <<"dispose_cash_events">>),
    Ids         = [maps:get(<<"id">>, E) || E <- Events],
    Sale        = ev_by_id(Events, <<"dispose_sale_proceeds">>),
    Loan        = ev_by_id(Events, <<"dispose_loan_payout">>),
    %% loan-pending ⟹ the loan event is dropped (honest-partial), sale+selling remain.
    {NoLoanF, _} = fill((full_upstream())#{<<"mortgage_plan">> => #{}}),
    NoLoanIds    = [maps:get(<<"id">>, E) || E <- g(NoLoanF, <<"dispose_cash_events">>)],
    [check("full: 3 dispose events (sale, selling, loan; cgt exempt ⟹ dropped)", length(Events), 3),
     check("full: event ids", Ids,
           [<<"dispose_sale_proceeds">>, <<"dispose_selling_costs">>, <<"dispose_loan_payout">>]),
     check("sale event: phase=dispose, direction=in, counterparty=other, src=disposition",
           {maps:get(<<"phase">>, Sale), maps:get(<<"direction">>, Sale),
            maps:get(<<"counterparty">>, Sale), maps:get(<<"source_component">>, Sale)},
           {<<"dispose">>, <<"in">>, <<"other">>, <<"disposition">>}),
     check("sale event: timing=one_off, is_estimate=true, amount carried",
           {maps:get(<<"timing">>, Sale), maps:get(<<"is_estimate">>, Sale),
            maps:get(<<"amount">>, Sale)},
           {<<"one_off">>, true, [975196, 1303116]}),
     check("loan event: out / lender", {maps:get(<<"direction">>, Loan),
            maps:get(<<"counterparty">>, Loan)}, {<<"out">>, <<"lender">>}),
     check("loan-pending: loan event dropped (honest-partial), sale+selling remain", NoLoanIds,
           [<<"dispose_sale_proceeds">>, <<"dispose_selling_costs">>])].

%% --- 6. growth placeholder surfaced + bilingual assumptions ------------------

assumption_cases() ->
    {Full, _} = fill(full_upstream()),
    Assumptions = g(Full, <<"key_assumptions">>),
    %% 5 lines when H set + loan known: horizon, growth placeholder, cgt basis, selling
    %% costs, the representative loan-rate basis (seam B — the amortisation rate is a
    %% labelled KB convention, surfaced).
    AllBilingual = lists:all(fun bilingual/1, Assumptions),
    AnyDiacritic = lists:any(
        fun(L) ->
            Vi = maps:get(<<"vi">>, L, <<>>),
            lists:any(fun(C) -> C > 127 end, unicode:characters_to_list(Vi))
        end, Assumptions),
    %% the growth placeholder line carries the band ends (2 / 5) substituted into prose.
    GrowthMentionsBand = lists:any(
        fun(L) ->
            En = maps:get(<<"en">>, L, <<>>),
            binary:match(En, <<"2">>) =/= nomatch andalso binary:match(En, <<"5">>) =/= nomatch
        end, Assumptions),
    LoanRateStated = lists:any(
        fun(L) ->
            En = maps:get(<<"en">>, L, <<>>),
            binary:match(En, <<"representative">>) =/= nomatch andalso
            binary:match(En, <<"amortises">>) =/= nomatch
        end, Assumptions),
    [check("H set + loan known: 5 key_assumptions (horizon, growth, cgt, selling, loan-rate)",
           length(Assumptions), 5),
     check("every key_assumption is bilingual {vi,en}, both non-empty + distinct", AllBilingual, true),
     check("a key_assumption carries real Vietnamese (non-ASCII)", AnyDiacritic, true),
     check("growth assumption surfaces the placeholder band (2 / 5 %)", GrowthMentionsBand, true),
     check("loan-rate assumption stated (representative rate, a labelled convention)", LoanRateStated, true)]
    ++ growth_key_cases().

%% the growth line's copy key follows is_placeholder: a placeholder band says PLACEHOLDER and
%% never names a source; a sourced band names ABS and never says PLACEHOLDER (behavior 12).
growth_key_cases() ->
    Pl  = fh_engine_disposition:growth_assumption(2, 5, true),
    Src = fh_engine_disposition:growth_assumption(3, 6, false),
    Has = fun(L, Lang, Sub) -> binary:match(maps:get(Lang, L), Sub) =/= nomatch end,
    [check("is_placeholder=true: the line says PLACEHOLDER, names no ABS source",
           {Has(Pl, <<"en">>, <<"PLACEHOLDER">>), Has(Pl, <<"en">>, <<"ABS">>)}, {true, false}),
     check("is_placeholder=false: the line names ABS Total Value of Dwellings (en + vi), no PLACEHOLDER",
           {Has(Src, <<"en">>, <<"ABS Total Value of Dwellings">>), Has(Src, <<"vi">>, <<"ABS">>),
            Has(Src, <<"en">>, <<"PLACEHOLDER">>), Has(Src, <<"vi">>, <<"TẠM"/utf8>>)},
           {true, true, false, false}),
     check("is_placeholder=false: the band ends substituted (3–6)",
           Has(Src, <<"en">>, <<"3–6%"/utf8>>), true)].

%% --- 8. seam (B): loan_payout is KB-rate-driven, NOT the agent rate field ----
%% loan_structure_recommendation.rate holds the agent's rate-STRUCTURE enum, never a numeric
%% rate. loan_payout amortises at the KB representative rate, so it must be INDEPENDENT of
%% that field — proven by feeding "variable", an absurd numeric, and an absent structure;
%% all yield the SAME payout (§98: the regulated figure has no LLM in its lineage).

rate_source_cases() ->
    Base = full_upstream(),
    M = fun(Mortgage) -> Base#{<<"mortgage_plan">> => Mortgage} end,
    {Variable, _} = fill(M(#{<<"expected_borrowing_capacity">> => 560000,
                             <<"loan_structure_recommendation">> => #{<<"rate">> => <<"variable">>}})),
    {Absurd, _}   = fill(M(#{<<"expected_borrowing_capacity">> => 560000,
                             <<"loan_structure_recommendation">> => #{<<"rate">> => 999.0}})),
    {NoLS, _}     = fill(M(#{<<"expected_borrowing_capacity">> => 560000})),
    Want = [468640, 468640],
    [check("loan_payout with rate=\"variable\" (enum string) = KB-rate amortised",
           g(Variable, <<"loan_payout">>), Want),
     check("loan_payout IGNORES an absurd numeric in the agent field (999%) — KB rate governs (§98)",
           g(Absurd, <<"loan_payout">>), Want),
     check("loan_payout with NO loan_structure_recommendation = same (capacity + KB rate only)",
           g(NoLS, <<"loan_payout">>), Want)].

%% --- 7. Layer-1 conformance across every state (the fail-closed seam) --------

layer1_cases() ->
    Fhb = <<"fhb-domestic-au">>,
    Inv = <<"investor-domestic-au">>,
    %% Each state validates against ITS blueprint's registry (per-blueprint registry,
    %% architecture §11.9): the owner-occupier states against fhb-domestic-au
    %% ([exempt, to_verify]), the investor states against investor-domestic-au
    %% ([computed, to_verify] + taxable_gain). P3 put BOTH blueprints in scope, so the
    %% investor COMPUTED path — deferred at P2 because the Mode-A enum lacked "computed"
    %% — validates here now; its figures are exactly asserted in investor_cases/0.
    States = [{<<"full">>,        Fhb, full_upstream()},
              {<<"rented">>,      Fhb, (full_upstream())#{<<"profile">> => profile(<<"partial_rental">>)}},
              {<<"no_horizon">>,  Fhb, (full_upstream())#{<<"profile">> =>
                                      (profile(<<"sole_occupier">>))#{<<"hold_horizon_years">> => null}}},
              {<<"loan_pending">>,Fhb, (full_upstream())#{<<"mortgage_plan">> => #{}}},
              {<<"investor_computed">>,  Inv, inv_upstream(inv_profile(<<"resident">>),
                                            inv_tax(<<"personal_sole">>, 37.0, false))},
              {<<"investor_to_verify">>, Inv, inv_upstream(inv_profile(<<"resident">>),
                                            inv_tax(<<"personal_sole">>, 37.0, true))},
              {<<"empty">>,       Fhb, #{}}],
    [begin
         {Outcome, _} = fill(Up),
         V = try fh_engine_outcome:validate(Slug, <<"disposition">>, Outcome), ok
             catch _:Why -> {error, Why} end,
         check(<<"Layer-1 conforms: ", Name/binary>>, V, ok)
     end || {Name, Slug, Up} <- States].

%% --- helpers ----------------------------------------------------------------

ev_by_id(Events, Id) ->
    case [E || E <- Events, maps:get(<<"id">>, E) =:= Id] of
        [E | _] -> E;
        []      -> #{}
    end.

bilingual(L) when is_map(L) ->
    Vi = maps:get(<<"vi">>, L, <<>>),
    En = maps:get(<<"en">>, L, <<>>),
    byte_size(Vi) > 0 andalso byte_size(En) > 0 andalso Vi =/= En;
bilingual(_) -> false.

check(Label, Got, Want) ->
    case Got =:= Want of
        true  -> io:format("  PASS   ~ts~n", [Label]), pass;
        false -> io:format("  FAIL   ~ts = ~p, expected ~p~n", [Label, Got, Want]), fail
    end.
