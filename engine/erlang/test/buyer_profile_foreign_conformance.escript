#!/usr/bin/env escript
%%! -sname fh_buyer_profile_foreign_conformance
%%
%% Conformance suite for the `buyer_profile` Mode-B (foreign-person) variant
%% (fh_engine_fill:buyer_profile_foreign/1 — the Mode-B pipeline entry, blueprint
%% fhb-foreign-au.md component 1; a pure-resolver component, no agent leaves).
%% SHARED component NAME with the Mode-A FHB `buyer_profile` (unlike Mode C's distinct
%% `investor_profile`), and it is the pipeline entry — no upstream outcome exists yet to
%% sniff a shape from (the mechanism mortgage_finance/cash_position use). So
%% fh_engine_fill:buyer_profile/1 discriminates on Args.firb_required_any — the SAME flag
%% the compliance FIRB gate keys on (mode-b-wedge.md P2). Loads the SAME materialized
%% artifact the engine loads (priv/kb/artifact.json) and asserts:
%%   1. SCAFFOLD — the Mode-B branch asserts firb_status/firb_required/firb_required_any
%%      DEFINITIONALLY (no resolver derivation over a possibility set, unlike Mode A/C);
%%      every deep applicant fact (citizenship_status, visa_class, tax residency, income)
%%      is honest-partial null at onboarding; off_title_parties = [] (funder captured on
%%      refine); the canonical `profile` outcome shape carries target_price_range /
%%      target_zone / hold_horizon_years same as Mode A/C. Input-independent at base.
%%   2. NO REGRESSION — the Mode-A FHB path (Args.firb_required_any absent/false) is
%%      untouched: still routes to buyer_profile_domestic, still passes Layer-1
%%      fh_engine_outcome:validate/3 against fhb-domestic-au's `profile` schema.
%%
%% fhb-foreign-au has NO materialized registry until the P3 in-scope flip (mode-b-wedge.md),
%% so this suite does NOT call fh_engine_outcome:validate/3 against it — only the Mode-A
%% no-regression path is Layer-1-checked.
%%
%% Run from engine/erlang with the build libs on the path (no Postgres, no live model):
%%   ERL_LIBS=_build/default/lib escript test/buyer_profile_foreign_conformance.escript

-mode(compile).

-define(FHB, <<"fhb-domestic-au">>).

main(_) ->
    ok = fh_engine_kb:load(),
    io:format("buyer_profile_foreign conformance — fh_engine_fill (Mode-B pipeline entry)~n~n"),
    R = lists:flatten([scaffold_cases(), no_regression_cases()]),
    Fails = [X || X <- R, X =:= fail],
    io:format("~n================================================================~n"),
    case Fails of
        [] -> io:format("PASS — all ~p buyer_profile_foreign anchors hold~n", [length(R)]), halt(0);
        _  -> io:format("FAIL — ~p anchor(s) mismatched~n", [length(Fails)]), halt(1)
    end.

%% --- fixtures ----------------------------------------------------------------

fields() ->
    [<<"applicants">>, <<"applicant_count">>, <<"firb_required_any">>,
     <<"off_title_parties">>, <<"assessable_income">>, <<"approx_borrowing_capacity">>,
     <<"deposit_ready_for_purchase_amount">>, <<"debts">>, <<"target_price_range">>,
     <<"target_zone">>, <<"hold_horizon_years">>, <<"key_constraints">>, <<"key_strengths">>].

applicant_null_at_base() ->
    [<<"citizenship_status">>, <<"visa_class">>, <<"visa_grant_date">>,
     <<"residency_duration_months">>, <<"taxable_income_aud">>, <<"employment_status">>].

foreign_args() ->
    #{firb_required_any => true,
      onboarding => #{<<"target_price_range">> => [700000, 900000],
                       <<"target_zone">> => [<<"Footscray">>]}}.

scaffold() ->
    fh_engine_fill:resolver(<<"buyer_profile">>, foreign_args(), #{}).

g(O, K) -> maps:get(K, O, undefined).

%% --- 1. scaffold (Mode-B foreign-person branch) ------------------------------

scaffold_cases() ->
    {O, Rend, Kb} = scaffold(),
    %% the branch decision is input-independent of onboarding CONTENT (only
    %% firb_required_any picks the branch) — a bare onboarding still routes to the
    %% definitional foreign-person scaffold, it just carries forward null/[] for the
    %% target facts instead of the fixture's explicit values (the carry-forward is
    %% real, by design — buyer_profile's job — so the two outcomes legitimately differ
    %% on those three fields only).
    {OBare, _, _} = fh_engine_fill:resolver(<<"buyer_profile">>,
        #{firb_required_any => true, onboarding => #{}}, #{}),
    [BareApp] = maps:get(<<"applicants">>, OBare),
    KbSlugs = [maps:get(<<"slug">>, E) || E <- Kb],
    [App] = g(O, <<"applicants">>),
    Tax = maps:get(<<"tax">>, App),
    AppNull =
        [check(<<"applicant field null at base: ", F/binary>>, maps:get(F, App), null)
         || F <- applicant_null_at_base()],
    [check("renderer = summary-card", Rend, <<"summary-card">>),
     check("outcome has exactly the thirteen profile fields",
           lists:sort(maps:keys(O)), lists:sort(fields())),
     check("applicant_count = 1", g(O, <<"applicant_count">>), 1),
     check("applicants[0].role = primary", maps:get(<<"role">>, App), <<"primary">>),
     check("applicants[0].firb_status = foreign_person (definitional)",
           maps:get(<<"firb_status">>, App), <<"foreign_person">>),
     check("applicants[0].firb_required = true (definitional)",
           maps:get(<<"firb_required">>, App), true),
     check("applicants[0].tax.jurisdiction = AU", maps:get(<<"jurisdiction">>, Tax), <<"AU">>),
     check("applicants[0].tax.residency_for_tax null (pending)",
           maps:get(<<"residency_for_tax">>, Tax), null),
     check("applicants[0].tax.marginal_rate null (pending)",
           maps:get(<<"marginal_rate">>, Tax), null),
     check("firb_required_any = true (definitional, the F14 close)",
           g(O, <<"firb_required_any">>), true),
     check("off_title_parties = [] (funder captured on refine)",
           g(O, <<"off_title_parties">>), []),
     check("approx_borrowing_capacity = null (pending mortgage_finance foreign variant)",
           g(O, <<"approx_borrowing_capacity">>), null),
     check("deposit_ready_for_purchase_amount = null (pending savings/funder facts)",
           g(O, <<"deposit_ready_for_purchase_amount">>), null),
     check("target_price_range carried from onboarding",
           g(O, <<"target_price_range">>), [700000, 900000]),
     check("target_zone carried from onboarding",
           g(O, <<"target_zone">>), [<<"Footscray">>]),
     check("kb_versions = the four Mode-B profile anchors",
           lists:sort(KbSlugs),
           lists:sort([<<"kb.firb.status-determination">>,
                       <<"kb.firb.established-dwelling-ban">>,
                       <<"kb.visas.au-temporary-residency-classes">>,
                       <<"kb.au-temp-residents.banking-and-tax-basics">>])),
     check("has_resolver true", fh_engine_fill:has_resolver(<<"buyer_profile">>), true),
     check("branch decision is input-independent of onboarding content (bare onboarding "
           "still routes foreign)", maps:get(<<"firb_status">>, BareApp), <<"foreign_person">>),
     check("bare onboarding still carries firb_required_any = true",
           g(OBare, <<"firb_required_any">>), true),
     check("bare onboarding carries null target facts (no explicit onboarding to project)",
           {g(OBare, <<"target_price_range">>), g(OBare, <<"target_zone">>)}, {null, []})]
    ++ AppNull.

%% --- 2. no regression (the Mode-A FHB buyer_profile path) --------------------

no_regression_cases() ->
    %% Mode-A path: firb_required_any absent (defaults false) → buyer_profile_domestic.
    {Fhb, FhbRend, _} = fh_engine_fill:resolver(<<"buyer_profile">>,
        #{onboarding => #{<<"target_price_range">> => [600000, 700000]}}, #{}),
    [FhbApp] = maps:get(<<"applicants">>, Fhb),
    V = try fh_engine_outcome:validate(?FHB, <<"profile">>, Fhb), ok
        catch _:Why -> {error, Why} end,
    [check("FHB buyer_profile renderer still summary-card", FhbRend, <<"summary-card">>),
     check("FHB firb_required_any = false (non-foreign lead)",
           maps:get(<<"firb_required_any">>, Fhb), false),
     check("FHB applicant citizenship_status is the citizen/PR possibility-set (not null)",
           maps:get(<<"citizenship_status">>, FhbApp),
           #{<<"oneof">> => [<<"citizen">>, <<"permanent_resident">>]}),
     check("FHB applicant has NO firb_status field (Mode-B-only leaf)",
           maps:is_key(<<"firb_status">>, FhbApp), false),
     check("FHB applicant still carries owner_occupier_intent (Mode-A-only leaf, untouched)",
           maps:is_key(<<"owner_occupier_intent">>, FhbApp), true),
     check("Layer-1 conforms: FHB profile (no regression)", V, ok)].

%% --- helpers ----------------------------------------------------------------

check(Label, Got, Want) ->
    case Got =:= Want of
        true  -> io:format("  PASS   ~ts~n", [Label]), pass;
        false -> io:format("  FAIL   ~ts = ~p, expected ~p~n", [Label, Got, Want]), fail
    end.
