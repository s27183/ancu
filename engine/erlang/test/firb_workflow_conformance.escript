#!/usr/bin/env escript
%%! -sname fh_firb_workflow_conformance
%%
%% Conformance suite for the NEW `firb_workflow` resolver (fh_engine_firb:fill/2 —
%% blueprint fhb-foreign-au.md component 4, mode-b-wedge.md P2 slice 2) and the
%% compliance FIRB gate it replaces the hard-block stub with (fh_engine_compliance:firb/4).
%% No shared-name variant to regress here (firb_workflow is wholly new — Mode A has no
%% equivalent, it REPLACES `eligibility`), so this suite asserts:
%%   1. SCAFFOLD (base, no property attached) — the conservative upper-bound fee estimate
%%      from profile.target_price_range, ban-window-derived eligibility (undetermined
%%      with no property yet), documents_outstanding, blocking_for_contract=true (no
%%      approval yet), has_resolver true.
%%   2. PER-PROPERTY REFINEMENT — a permitted new-build property resolves eligible=true;
%%      an established dwelling resolves eligible=false (still blocking either way, since
%%      approval_received is always false today).
%%   3. FEE BAND BOUNDARIES — the kb.firb.fee-tiers-by-value selection rule composed with
%%      kb.firb.fee-schedule-current's amounts, at every documented row + the increment
%%      formula above $5m (verified against the doc's own $40m/$1,181,700 anchor).
%%   4. THE FUNDER-CONDITIONAL DOCUMENT — off_title_parties[].funder.expected_to_fund
%%      adds the VN-funder passport to documents_outstanding.
%%   5. THE BAN WINDOW — ban_applies() reads kb.firb.established-dwelling-ban's dates
%%      (today is within 2025-04-01..2029-06-30).
%%   6. THE COMPLIANCE GATE — fh_engine_compliance:firb/4 no longer hard-blocks Mode B:
%%      firb_workflow's own commit clears (audits pending vs approved), any other Mode-B
%%      base component clears (pre-contract planning), Mode A is unchanged (not_required),
%%      and firb_workflow is now ASIC advice-adjacent.
%%
%% Run from engine/erlang with the build libs on the path (no Postgres, no live model):
%%   ERL_LIBS=_build/default/lib escript test/firb_workflow_conformance.escript

-mode(compile).

main(_) ->
    ok = fh_engine_kb:load(),
    io:format("firb_workflow conformance — fh_engine_firb + fh_engine_compliance:firb/4~n~n"),
    R = lists:flatten([scaffold_cases(), per_property_cases(), fee_band_cases(),
                       funder_document_cases(), ban_window_cases(), compliance_gate_cases()]),
    Fails = [X || X <- R, X =:= fail],
    io:format("~n================================================================~n"),
    case Fails of
        [] -> io:format("PASS — all ~p firb_workflow anchors hold~n", [length(R)]), halt(0);
        _  -> io:format("FAIL — ~p anchor(s) mismatched~n", [length(Fails)]), halt(1)
    end.

%% --- fixtures ----------------------------------------------------------------

fields() ->
    [<<"foreign_person_eligible">>, <<"firb_fee_tier">>, <<"total_firb_fee_payable">>,
     <<"current_stage">>, <<"approval_received">>, <<"approval_conditions">>,
     <<"days_to_expected_decision">>, <<"blocking_for_contract">>,
     <<"documents_outstanding">>].

base_profile() ->
    #{<<"target_price_range">> => [700000, 900000], <<"off_title_parties">> => []}.

funder_profile() ->
    #{<<"target_price_range">> => [700000, 900000],
      <<"off_title_parties">> => [#{<<"relationship">> => <<"parent">>,
                                    <<"funder">> => #{<<"expected_to_fund">> => true,
                                                       <<"residence_country">> => <<"VN">>}}]}.

g(O, K) -> maps:get(K, O, undefined).

%% --- 1. scaffold (base turn, no property) -------------------------------------

scaffold_cases() ->
    {O, Rend, Kb} = fh_engine_fill:resolver(<<"firb_workflow">>, #{},
                        #{<<"profile">> => base_profile()}),
    KbSlugs = [maps:get(<<"slug">>, E) || E <- Kb],
    [check("renderer = firb-workflow-card", Rend, <<"firb-workflow-card">>),
     check("outcome has exactly the nine firb_status fields",
           lists:sort(maps:keys(O)), lists:sort(fields())),
     check("foreign_person_eligible = null (ban applies, no property attached)",
           g(O, <<"foreign_person_eligible">>), null),
     check("firb_fee_tier = under_1m (conservative upper bound $900,000)",
           g(O, <<"firb_fee_tier">>), <<"under_1m">>),
     check("total_firb_fee_payable = 15100 (le_1m band)",
           g(O, <<"total_firb_fee_payable">>), 15100),
     check("current_stage = not_started", g(O, <<"current_stage">>), <<"not_started">>),
     check("approval_received = false", g(O, <<"approval_received">>), false),
     check("approval_conditions = []", g(O, <<"approval_conditions">>), []),
     check("days_to_expected_decision = null (no clock started)",
           g(O, <<"days_to_expected_decision">>), null),
     check("blocking_for_contract = true (no approval yet)",
           g(O, <<"blocking_for_contract">>), true),
     check("documents_outstanding = the five base documents (no funder)",
           lists:sort(g(O, <<"documents_outstanding">>)),
           lists:sort([<<"passport_au_member">>, <<"visa_grant_evidence">>,
                       <<"property_details_contract_or_listing">>,
                       <<"source_of_funds_evidence">>, <<"vendor_or_developer_details">>])),
     check("kb_versions = the ten FIRB anchors",
           lists:sort(KbSlugs),
           lists:sort([<<"kb.firb.established-dwelling-ban">>,
                       <<"kb.firb.eligible-property-types-foreign-persons">>,
                       <<"kb.firb.fee-tiers-by-value">>, <<"kb.firb.fee-schedule-current">>,
                       <<"kb.firb.application-process">>, <<"kb.firb.documents-required">>,
                       <<"kb.firb.timelines-standard">>,
                       <<"kb.firb.exemption-certificates-developer">>,
                       <<"kb.firb.approval-conditions-typical">>,
                       <<"kb.firb.penalties-non-compliance">>])),
     check("has_resolver true", fh_engine_fill:has_resolver(<<"firb_workflow">>), true)].

%% --- 2. per-property refinement -----------------------------------------------

per_property_cases() ->
    {OPermitted, _, _} = fh_engine_fill:resolver(<<"firb_workflow">>, #{},
        #{<<"profile">> => base_profile(),
          <<"property_fit">> => #{<<"property_type">> => <<"new_apartment">>,
                                  <<"price">> => 850000}}),
    {OEstablished, _, _} = fh_engine_fill:resolver(<<"firb_workflow">>, #{},
        #{<<"profile">> => base_profile(),
          <<"property_fit">> => #{<<"property_type">> => <<"established_house">>,
                                  <<"price">> => 900000}}),
    [check("permitted new-build: foreign_person_eligible = true",
           g(OPermitted, <<"foreign_person_eligible">>), true),
     check("permitted new-build: fee tier from property_fit.price ($850,000)",
           g(OPermitted, <<"firb_fee_tier">>), <<"under_1m">>),
     check("established dwelling (ban in force): foreign_person_eligible = false",
           g(OEstablished, <<"foreign_person_eligible">>), false),
     check("established dwelling: still blocking_for_contract = true",
           g(OEstablished, <<"blocking_for_contract">>), true)].

%% --- 3. fee band boundaries -----------------------------------------------------

fee_band_cases() ->
    [check("fee_tier(null) = null", fh_engine_firb:fee_tier(null), null),
     check("fee_amount(75000) = 4500 (lt_75000)", fh_engine_firb:fee_amount(75000), 4500),
     check("fee_amount(1000000) = 15100 (le_1m)", fh_engine_firb:fee_amount(1000000), 15100),
     check("fee_amount(2000000) = 30300 (le_2m)", fh_engine_firb:fee_amount(2000000), 30300),
     check("fee_amount(3000000) = 60600 (le_3m)", fh_engine_firb:fee_amount(3000000), 60600),
     check("fee_amount(4000000) = 90900 (le_4m)", fh_engine_firb:fee_amount(4000000), 90900),
     check("fee_amount(5000000) = 121200 (le_5m)", fh_engine_firb:fee_amount(5000000), 121200),
     check("fee_amount(6000000) = 151500 (increment formula, le_6m: 30300*(6-1))",
           fh_engine_firb:fee_amount(6000000), 151500),
     check("fee_amount(40000000) = 1181700 (doc's own $40m anchor)",
           fh_engine_firb:fee_amount(40000000), 1181700),
     check("fee_amount(40000001) = 1205200 (flat cap above $40m)",
           fh_engine_firb:fee_amount(40000001), 1205200),
     check("fee_tier(5000000) = 3m_to_5m", fh_engine_firb:fee_tier(5000000), <<"3m_to_5m">>),
     check("fee_tier(5000001) = over_5m", fh_engine_firb:fee_tier(5000001), <<"over_5m">>)].

%% --- 4. the funder-conditional document -----------------------------------------

funder_document_cases() ->
    {OFunder, _, _} = fh_engine_fill:resolver(<<"firb_workflow">>, #{},
        #{<<"profile">> => funder_profile()}),
    [check("has_funder true for an expected_to_fund off_title party",
           fh_engine_firb:has_funder(maps:get(<<"off_title_parties">>, funder_profile())), true),
     check("documents_outstanding includes the VN-funder passport when a funder exists",
           lists:member(<<"passport_vn_funder_if_applicable">>,
                        g(OFunder, <<"documents_outstanding">>)), true),
     check("documents_outstanding is six documents with a funder",
           length(g(OFunder, <<"documents_outstanding">>)), 6)].

%% --- 5. the ban window ------------------------------------------------------------

ban_window_cases() ->
    [check("ban_applies() = true (today within 2025-04-01..2029-06-30)",
           fh_engine_firb:ban_applies(), true),
     check("eligible(false, undefined) = true (ban closed, purchase-eligible regardless)",
           fh_engine_firb:eligible(false, <<"established_house">>), true),
     check("eligible(true, <<\"new_house\">>) = true (permitted type)",
           fh_engine_firb:eligible(true, <<"new_house">>), true),
     check("eligible(true, <<\"established_apartment\">>) = false (banned)",
           fh_engine_firb:eligible(true, <<"established_apartment">>), false),
     check("eligible(true, undefined) = null (no property yet — undetermined)",
           fh_engine_firb:eligible(true, undefined), null)].

%% --- 6. the compliance FIRB gate -------------------------------------------------

compliance_gate_cases() ->
    Pending  = #{<<"blocking_for_contract">> => true},
    Approved = #{<<"blocking_for_contract">> => false},
    {_, GPending}  = fh_engine_compliance:run(<<"firb_workflow">>,
                        #{firb_required_any => true}, Pending, #{}),
    {_, GApproved} = fh_engine_compliance:run(<<"firb_workflow">>,
                        #{firb_required_any => true}, Approved, #{}),
    {_, GOther}    = fh_engine_compliance:run(<<"mortgage_finance">>,
                        #{firb_required_any => true}, #{}, #{}),
    {_, GModeA}    = fh_engine_compliance:run(<<"cash_position">>,
                        #{firb_required_any => false}, #{}, #{}),
    FirbGate = fun(Gates) -> hd([G || G <- Gates, maps:get(<<"gate">>, G) =:= <<"firb">>]) end,
    AsicGate = fun(Gates) -> hd([G || G <- Gates, maps:get(<<"gate">>, G) =:= <<"asic">>]) end,
    FGP = FirbGate(GPending), FGA = FirbGate(GApproved),
    FGO = FirbGate(GOther), FGM = FirbGate(GModeA),
    %% ASIC advice-adjacency is checked against firb_workflow itself (GPending's
    %% ComponentId), NOT mortgage_finance (GOther) — mortgage_finance was ALREADY
    %% advice-adjacent before this slice, so that would prove nothing new.
    AGFirb = AsicGate(GPending),
    [check("firb_workflow's own commit clears while pending (no longer a hard block)",
           maps:get(<<"disposition">>, FGP), <<"clear">>),
     check("firb_workflow pending detail = firb_approval_pending",
           maps:get(<<"detail">>, FGP), <<"firb_approval_pending">>),
     check("firb_workflow's own commit clears once approved",
           maps:get(<<"disposition">>, FGA), <<"clear">>),
     check("firb_workflow approved detail = firb_approved",
           maps:get(<<"detail">>, FGA), <<"firb_approved">>),
     check("another Mode-B base component clears (pre-contract planning)",
           maps:get(<<"disposition">>, FGO), <<"clear">>),
     check("other-component detail = pre_contract_planning",
           maps:get(<<"detail">>, FGO), <<"pre_contract_planning">>),
     check("Mode A unaffected: firb gate still not_required",
           {maps:get(<<"disposition">>, FGM), maps:get(<<"detail">>, FGM)},
           {<<"clear">>, <<"not_required">>}),
     check("firb_workflow is now ASIC advice-adjacent",
           maps:get(<<"detail">>, AGFirb), <<"decision_support_boundary_held">>)].

%% --- helpers ----------------------------------------------------------------

check(Label, Got, Want) ->
    case Got =:= Want of
        true  -> io:format("  PASS   ~ts~n", [Label]), pass;
        false -> io:format("  FAIL   ~ts = ~p, expected ~p~n", [Label, Got, Want]), fail
    end.
