#!/usr/bin/env escript
%%! -sname fh_investor_profile_conformance
%%
%% Conformance suite for the `investor_profile` resolver (fh_engine_fill — the Mode-C
%% pipeline entry, the first investor base resolver). Loads the SAME materialized artifact
%% the engine loads (priv/kb/artifact.json via fh_engine_kb) and asserts what the commit
%% seam relies on:
%%   1. APPLICANT — a single domestic (citizen/PR) lead with the Mode-C delta: a per-
%%      applicant tax{} object (residency=resident, jurisdiction=AU), NO owner-occupier
%%      eligibility leaves; firb_required derived false via the shared resolver.
%%   2. HONEST-PARTIAL — at onboarding the deep facts are absent: assessable_income null,
%%      debts empty, existing_portfolio / traits / approx_borrowing_capacity / deposit /
%%      ppor-equity ABSENT (computed/gathered on a later unit / refine turn).
%%   3. FINANCIALS — when household_financials are threaded in, assessable_income + debts
%%      frame through the SAME IC3 helpers Mode A uses.
%%   4. NARRATION — one mode-neutral financials-pending constraint + one definitional
%%      Mode-C strength (domestic investor), both bilingual {vi,en} (decision-support).
%%   5. LAYER-1 CONFORMANCE — every state passes fh_engine_outcome:validate/3 against the
%%      compiled investor `profile` schema (the fail-closed commit seam).
%%   6. NO MODE-A REGRESSION — buyer_profile still dispatches and conforms to the FHB
%%      registry (the new clause is additive; distinct component name ⟹ zero Mode-A reach).
%%
%% Run from engine/erlang with the build libs on the path (no Postgres needed):
%%   ERL_LIBS=_build/default/lib escript test/investor_profile_conformance.escript

-mode(compile).

-define(INV, <<"investor-domestic-au">>).
-define(FHB, <<"fhb-domestic-au">>).

main(_) ->
    ok = fh_engine_kb:load(),
    io:format("investor_profile conformance — fh_engine_fill (Mode-C pipeline entry)~n~n"),
    R = lists:flatten([applicant_cases(), honest_partial_cases(), financials_cases(),
                       narration_cases(), layer1_cases(), no_regression_cases()]),
    Fails = [X || X <- R, X =:= fail],
    io:format("~n================================================================~n"),
    case Fails of
        [] ->
            io:format("PASS — all ~p investor_profile anchors hold~n", [length(R)]),
            halt(0);
        _ ->
            io:format("FAIL — ~p anchor(s) mismatched~n", [length(Fails)]),
            halt(1)
    end.

%% --- fixtures ----------------------------------------------------------------

onboarding() ->
    #{<<"state">> => <<"VIC">>,
      <<"target_price_range">> => [600000, 800000],
      <<"target_zone">> => [<<"Footscray">>],
      <<"intent">> => <<"investment">>}.

%% the base onboarding turn args (no deep financials — plan-first).
base_args() ->
    #{onboarding => onboarding(), intent => <<"investment">>}.

%% a refine-shaped args: household_financials threaded in from the profiles SOT.
financials_args() ->
    (base_args())#{household_financials =>
        #{<<"income">> => #{<<"assessable_income">> => 120000},
          <<"debts">>  => #{<<"hecs_balance">> => 20000,
                            <<"credit_card_limits_total">> => 8000}}}.

fill(Args) ->
    {Outcome, Renderer, Kb} = fh_engine_fill:resolver(<<"investor_profile">>, Args, #{}),
    {Outcome, Renderer, Kb}.

g(Outcome, K)  -> maps:get(K, Outcome, undefined).
absent(Outcome, K) -> maps:get(K, Outcome, '$absent') =:= '$absent'.

%% --- 1. applicant (Mode-C definitional projection) --------------------------

applicant_cases() ->
    {O, Renderer, _} = fill(base_args()),
    [A | _] = g(O, <<"applicants">>),
    Tax = maps:get(<<"tax">>, A, #{}),
    [check("renderer = summary-card", Renderer, <<"summary-card">>),
     check("applicant_count = 1", g(O, <<"applicant_count">>), 1),
     check("lead role = primary", maps:get(<<"role">>, A), <<"primary">>),
     check("citizenship = {oneof citizen, permanent_resident} (same set as Mode A)",
           maps:get(<<"citizenship_status">>, A),
           #{<<"oneof">> => [<<"citizen">>, <<"permanent_resident">>]}),
     check("per-applicant tax.residency_for_tax = resident (CGT-discount determinant)",
           maps:get(<<"residency_for_tax">>, Tax), <<"resident">>),
     check("per-applicant tax.jurisdiction = AU (Mode D adds VN)",
           maps:get(<<"jurisdiction">>, Tax), <<"AU">>),
     check("tax.marginal_rate ABSENT (derived_from income → PENDING at base)",
           maps:is_key(<<"marginal_rate">>, Tax), false),
     check("NO owner_occupier_intent on the applicant (investor delta)",
           maps:is_key(<<"owner_occupier_intent">>, A), false),
     check("NO first-home ownership history on the applicant (investor delta)",
           maps:is_key(<<"ever_owned_au_property">>, A), false),
     check("applicant firb_required = false (domestic, resolver-derived)",
           maps:get(<<"firb_required">>, A), false),
     check("firb_required_any = false (Mode C domestic)", g(O, <<"firb_required_any">>), false),
     check("onboarding target_price_range carried to the DAG", g(O, <<"target_price_range">>),
           [600000, 800000]),
     check("onboarding target_zone carried", g(O, <<"target_zone">>), [<<"Footscray">>])].

%% --- 2. honest-partial (deep facts absent at onboarding) --------------------

honest_partial_cases() ->
    {O, _, _} = fill(base_args()),
    [check("assessable_income null (no financials captured)", g(O, <<"assessable_income">>), null),
     check("hold_horizon_years null (no horizon set)", g(O, <<"hold_horizon_years">>), null),
     check("existing_portfolio ABSENT (refine-turn fact)", absent(O, <<"existing_portfolio">>), true),
     check("traits ABSENT (refine-turn fact)", absent(O, <<"traits">>), true),
     check("approx_borrowing_capacity ABSENT (computed downstream by mortgage variant)",
           absent(O, <<"approx_borrowing_capacity">>), true),
     check("deposit_ready_for_purchase_amount ABSENT", absent(O, <<"deposit_ready_for_purchase_amount">>), true),
     check("ppor_equity_available_for_leverage ABSENT", absent(O, <<"ppor_equity_available_for_leverage">>), true),
     %% debts framed as an (empty) map — the IC3 passthrough, mirroring Mode A.
     check("debts = empty map (no debts captured, IC3 passthrough)", g(O, <<"debts">>), #{})].

%% --- 3. financials (IC3 helpers, same as Mode A) ----------------------------

financials_cases() ->
    {O, _, _} = fill(financials_args()),
    Debts = g(O, <<"debts">>),
    [check("assessable_income framed from household_financials", g(O, <<"assessable_income">>), 120000),
     check("foreign_sourced_income_component = 0 (domestic default)",
           g(O, <<"foreign_sourced_income_component">>), 0),
     check("debts.hecs_balance passed through", maps:get(<<"hecs_balance">>, Debts), 20000),
     check("debts.credit_card_limits_total passed through",
           maps:get(<<"credit_card_limits_total">>, Debts), 8000)].

%% --- 4. narration (bilingual, decision-support) -----------------------------

narration_cases() ->
    {O, _, Kb} = fill(base_args()),
    [Constraint | _] = g(O, <<"key_constraints">>),
    [Strength | _]   = g(O, <<"key_strengths">>),
    StrengthEn = maps:get(<<"en">>, Strength, <<>>),
    KbSlugs = [maps:get(<<"slug">>, E) || E <- Kb],
    [check("one key_constraint", length(g(O, <<"key_constraints">>)), 1),
     check("one key_strength", length(g(O, <<"key_strengths">>)), 1),
     check("constraint bilingual {vi,en} distinct", bilingual(Constraint), true),
     check("strength bilingual {vi,en} distinct", bilingual(Strength), true),
     check("strength is the domestic-investor one (not the FHB strength)",
           binary:match(StrengthEn, <<"investor">>) =/= nomatch, true),
     check("strength names the FIRB position (decision-support, definitional)",
           binary:match(StrengthEn, <<"FIRB">>) =/= nomatch, true),
     check("strength carries real Vietnamese (non-ASCII)",
           lists:any(fun(C) -> C > 127 end,
                     unicode:characters_to_list(maps:get(<<"vi">>, Strength, <<>>))), true),
     %% audit anchors recorded (the blueprint's investor_profile KB anchors).
     check("kb anchor: income-tax bracket table recorded",
           lists:member(<<"kb.tax.income-tax-resident-2026-27">>, KbSlugs), true),
     check("kb anchor: investment-loan serviceability recorded",
           lists:member(<<"kb.lender.serviceability-investment-loans">>, KbSlugs), true),
     check("kb anchor: investor experience levels recorded",
           lists:member(<<"kb.investor.experience-levels">>, KbSlugs), true)].

%% --- 5. Layer-1 conformance (the fail-closed seam) --------------------------

layer1_cases() ->
    States = [{<<"base">>, base_args()}, {<<"with_financials">>, financials_args()}],
    [begin
         {Outcome, _, _} = fill(Args),
         V = try fh_engine_outcome:validate(?INV, <<"profile">>, Outcome), ok
             catch _:Why -> {error, Why} end,
         check(<<"Layer-1 conforms (investor profile): ", Name/binary>>, V, ok)
     end || {Name, Args} <- States].

%% --- 6. no Mode-A regression ------------------------------------------------

no_regression_cases() ->
    A = #{onboarding => #{<<"target_price_range">> => [600000, 800000],
                          <<"target_zone">> => [<<"Footscray">>]},
          intent => <<"owner_occupier">>},
    {O, Renderer, _} = fh_engine_fill:resolver(<<"buyer_profile">>, A, #{}),
    [Ap | _] = maps:get(<<"applicants">>, O),
    V = try fh_engine_outcome:validate(?FHB, <<"profile">>, O), ok
        catch _:Why -> {error, Why} end,
    [check("buyer_profile still dispatches (renderer summary-card)", Renderer, <<"summary-card">>),
     check("buyer_profile keeps its Mode-A owner_occupier_intent leaf",
           maps:is_key(<<"owner_occupier_intent">>, Ap), true),
     check("buyer_profile Layer-1 conforms to the FHB registry (no regression)", V, ok)].

%% --- helpers ----------------------------------------------------------------

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
