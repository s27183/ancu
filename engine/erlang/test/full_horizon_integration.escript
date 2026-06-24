#!/usr/bin/env escript
%%! -sname fh_full_horizon_integration
%%
%% IC6 integration assertion — the full-horizon UNBLOCK, end-to-end, no Postgres.
%%
%% The symptom this guards: a Mode-A card showed "Chưa có" / empty for the full-horizon net
%% position on every real plan ("Vị thế ròng cả hành trình"), because
%%   disposition.full_horizon_net_position ← net_proceeds ← loan_payout ← capacity
%% and TWO seams broke the chain:
%%   (A) the base_resolver refresh SKIPPED the two-path mortgage_finance, so entering income
%%       (/profile, IC4) never recomputed expected_borrowing_capacity — it stayed the stale
%%       null from the base turn. Fix: base_resolver re-runs the resolver HALF (fresh figures)
%%       and re-attaches the stored agent leaf through the SAME merge_agent (the resolver half
%%       is always fresh; only the agent-leaf SOURCE varies by turn kind).
%%   (B) disposition.loan_payout read loan_structure_recommendation.rate as a NUMERIC rate,
%%       but that field holds the agent's rate-STRUCTURE enum ("variable"). So loan_payout was
%%       null on every real card. Fix: amortise at the KB representative product rate
%%       (kb.lender.serviceability-basics) — a regulated figure removed from the LLM's reach
%%       (§98). full_horizon now has NO LLM in its lineage.
%%
%% This suite proves both, at the layer below the gen_statem (fill/2 + simulate are pure given
%% Args + the persistent_term artifact — [[proportionate-verification-honest-gaps]]):
%%   1. THE CHAIN (seam B + the unblock): fh_engine_simulate:run walks the real base DAG
%%      resolver-only (= the base_resolver commit minus persistence — the resolver-half-always-
%%      fresh invariant makes them identical). income SET ⟹ full_horizon NON-NULL/banded/ordered.
%%   2. THE REGRESSION ANCHOR: income ABSENT ⟹ capacity null ⟹ loan null ⟹ full_horizon NULL
%%      (the exact "Chưa có" symptom — this case must stay null, never fabricated).
%%   3. THE RE-ATTACH INVARIANT (seam A): the base_resolver merge yields a FRESH capacity (from
%%      current income) while PRESERVING the stored agent leaf (shortlist + rate-structure) —
%%      proving the skip→recompute fix keeps §98 (the agent re-authors no figure).
%%
%% Named residue (NOT re-run here — covered by seam_smoke/qa_smoke with Docker PG + real Opus):
%% the live agent authoring the rate-structure leaf, and the gen_statem/PG turn orchestration.
%%
%% Run from engine/erlang with the build libs on the path (no Postgres needed):
%%   ERL_LIBS=_build/default/lib escript test/full_horizon_integration.escript

-mode(compile).

%% the IC0 worked example: $95k assessable income, $20k HECS, $10k card limit.
financials() ->
    #{<<"income">> => #{<<"assessable_income">> => 95000},
      <<"debts">>  => #{<<"hecs_balance">> => 20000,
                        <<"credit_card_limits_total">> => 10000}}.

%% onboarding with a hold horizon set (H=10) so disposition projects the dispose phase; state
%% explicit + no target_zone ⟹ projection_state takes its pure (no-DB) branch.
onboarding() ->
    #{<<"state">> => <<"NSW">>,
      <<"target_price_range">> => [600000, 800000],
      <<"target_zone">> => [],
      <<"hold_horizon_years">> => 10}.

main(_) ->
    ok = fh_engine_kb:load(),
    io:format("full-horizon integration — income ⟹ full_horizon_net_position non-null (IC6)~n~n"),
    R = lists:flatten([chain_cases(), regression_cases(), reattach_cases()]),
    Fails = [X || X <- R, X =:= fail],
    io:format("~n================================================================~n"),
    case Fails of
        [] -> io:format("PASS — all ~p full-horizon integration anchors hold~n", [length(R)]), halt(0);
        _  -> io:format("FAIL — ~p anchor(s) mismatched~n", [length(Fails)]), halt(1)
    end.

%% --- 1. the chain: income SET ⟹ full_horizon non-null (seam B + the unblock) -

chain_cases() ->
    {ok, Out} = fh_engine_simulate:run(<<"fhb-domestic-au">>, onboarding(), <<"owner_occupier">>, financials()),
    Mortgage = maps:get(<<"mortgage_plan">>, Out),
    Disp     = maps:get(<<"disposition">>, Out),
    Cap      = maps:get(<<"expected_borrowing_capacity">>, Mortgage),
    Loan     = maps:get(<<"loan_payout">>, Disp),
    Net      = maps:get(<<"net_proceeds">>, Disp),
    Full     = maps:get(<<"full_horizon_net_position">>, Disp),
    [chkBool("income set ⟹ borrowing_capacity NON-NULL (the serviceability resolver fired)",
             is_band(Cap)),
     chkBool("loan_payout NON-NULL (amortised at the KB representative rate, not the agent enum)",
             is_band(Loan)),
     chkBool("net_proceeds NON-NULL", is_band(Net)),
     chkBool("full_horizon_net_position NON-NULL — the 'Chưa có' is unblocked end-to-end",
             is_band(Full)),
     chkBool("full_horizon is a banded [lo, hi] with lo =< hi (never a fabricated point)",
             ordered(Full)),
     chkBool("the chain is monotone: net ⊃ full (full subtracts acquire + hold×H from net)",
             hd(Net) >= hd(Full))].

%% --- 2. the regression anchor: income ABSENT ⟹ full_horizon NULL -------------
%% the exact "Chưa có" symptom. With no income the capacity is honestly PENDING and the whole
%% dispose roll-up stays null — it must NEVER be fabricated. This case failing (i.e. becoming
%% non-null) would mean a figure was invented; this case passing-as-null is the honest-partial
%% guard. (Sale/selling still band — they need only price + H, not income.)

regression_cases() ->
    {ok, Out} = fh_engine_simulate:run(<<"fhb-domestic-au">>, onboarding(), <<"owner_occupier">>, #{}),
    Mortgage = maps:get(<<"mortgage_plan">>, Out),
    Disp     = maps:get(<<"disposition">>, Out),
    [chkNull("income absent ⟹ borrowing_capacity PENDING (null)",
             maps:get(<<"expected_borrowing_capacity">>, Mortgage)),
     chkNull("income absent ⟹ loan_payout PENDING (null)",
             maps:get(<<"loan_payout">>, Disp)),
     chkNull("income absent ⟹ net_proceeds PENDING (null)",
             maps:get(<<"net_proceeds">>, Disp)),
     chkNull("income absent ⟹ full_horizon PENDING (null) — the 'Chưa có' symptom, honestly",
             maps:get(<<"full_horizon_net_position">>, Disp)),
     chkBool("sale_proceeds STILL banded (needs only price + H, not income) — honest-partial",
             is_band(maps:get(<<"sale_proceeds">>, Disp)))].

%% --- 3. the re-attach invariant (seam A): fresh figure, preserved leaf -------
%% Mirrors the base_resolver branch (fh_engine_turn): re-run the resolver HALF against the
%% CURRENT income facts, then re-attach the STORED agent leaf via the SAME merge_agent. The
%% capacity must be FRESH (not the stale stored null); the agent leaf must be PRESERVED.

reattach_cases() ->
    %% the resolver half against current income (a minimal upstream — mortgage reads profile +
    %% scheme_stack only). The profile carries the framed income/debt facts buyer_profile emits.
    Profile = #{<<"assessable_income">> => 95000,
                <<"debts">> => #{<<"hecs_balance">> => 20000, <<"credit_card_limits_total">> => 10000}},
    Args = #{onboarding => onboarding(), intent => <<"owner_occupier">>},
    Upstream = #{<<"profile">> => Profile, <<"scheme_stack">> => #{}},
    {RO, _Renderer, _Kb} = fh_engine_fill:resolver(<<"mortgage_finance">>, Args, Upstream),
    FreshCap = maps:get(<<"expected_borrowing_capacity">>, RO),

    %% a STORED outcome from a prior base agentic turn: STALE capacity (null — income was absent
    %% then) + the agent leaves it authored (a shortlist + the rate-structure enum).
    Stored = RO#{<<"expected_borrowing_capacity">> => null,
                 <<"recommended_lender_shortlist">> => [<<"lender_a">>, <<"lender_b">>],
                 <<"loan_structure_recommendation">> =>
                     #{<<"type">> => <<"principal_and_interest">>,
                       <<"rate">> => <<"variable">>, <<"offset">> => null}},

    AgentValues = fh_engine_fill:agent_values_from_outcome(<<"mortgage_finance">>, Stored),
    Final = fh_engine_fill:merge_agent(<<"mortgage_finance">>, RO, AgentValues),
    FinalCap = maps:get(<<"expected_borrowing_capacity">>, Final),
    FinalShortlist = maps:get(<<"recommended_lender_shortlist">>, Final),
    FinalRate = maps:get(<<"rate">>, maps:get(<<"loan_structure_recommendation">>, Final)),

    [chkBool("the resolver half recomputes a NON-NULL capacity from current income", is_band(FreshCap)),
     chk("re-attach keeps the capacity FRESH (resolver-computed), NOT the stale stored null",
         FinalCap, FreshCap),
     chk("re-attach PRESERVES the stored agent shortlist (the leaf, verbatim)",
         FinalShortlist, [<<"lender_a">>, <<"lender_b">>]),
     chk("re-attach PRESERVES the stored rate-STRUCTURE enum (the leaf, verbatim)",
         FinalRate, <<"variable">>),
     chkBool("§98 holds: capacity (a figure) is resolver-fresh, never sourced from the leaf",
             FinalCap =:= FreshCap andalso FreshCap =/= null)].

%% --- harness ----------------------------------------------------------------

is_band([Lo, Hi]) when is_number(Lo), is_number(Hi) -> true;
is_band(_) -> false.

ordered([Lo, Hi]) when is_number(Lo), is_number(Hi) -> Lo =< Hi;
ordered(_) -> false.

chk(Label, Got, Want) ->
    case Got =:= Want of
        true  -> io:format("  PASS   ~ts~n", [Label]), pass;
        false -> io:format("  FAIL   ~ts = ~p, expected ~p~n", [Label, Got, Want]), fail
    end.

chkBool(Label, true)  -> io:format("  PASS   ~ts~n", [Label]), pass;
chkBool(Label, _)     -> io:format("  FAIL   ~ts~n", [Label]), fail.

chkNull(Label, null)  -> io:format("  PASS   ~ts~n", [Label]), pass;
chkNull(Label, Got)   -> io:format("  FAIL   ~ts = ~p, expected null~n", [Label, Got]), fail.
