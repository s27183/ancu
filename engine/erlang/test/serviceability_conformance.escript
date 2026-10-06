#!/usr/bin/env escript
%%! -sname fh_serviceability_conformance
%%
%% Conformance suite for fh_engine_mortgage's borrowing-capacity resolver (IC2 — the
%% serviceability core that unblocks the full-horizon net position). Loads the SAME
%% materialized artifact the engine loads (priv/kb/artifact.json via fh_engine_kb) and
%% asserts what disposition's loan_payout (and thus net/full-horizon) relies on:
%%   1. TAX — income tax from the 2026-27 resident schedule, to the dollar.
%%   2. HECS — the income-contingent compulsory repayment (nil below threshold, marginal
%%      bands, 10%-flat top band), to the dollar.
%%   3. CAPACITY — banded, buffer-assessed, from the profile's framed income/debt facts;
%%      the IC0 worked example reproduced exactly ([[verify-regulated-figures-by-postcondition]]
%%      — tax/buffer/HECS verifiable; the HEM + card bands carry the surfaced uncertainty).
%%   4. HONEST-PARTIAL — null capacity until assessable_income is known ([[base-turn-honest-partial-output]]).
%%   5. STRUCTURE — band ordered (lo =< hi), monotonic in income, clamped at 0, DTI-bounded.
%%
%% Run from engine/erlang with the build libs on the path (no Postgres needed):
%%   ERL_LIBS=_build/default/lib escript test/serviceability_conformance.escript

-mode(compile).

main(_) ->
    ok = fh_engine_kb:load(),
    io:format("serviceability conformance — fh_engine_mortgage:borrowing_capacity (IC2)~n~n"),
    R = lists:flatten([tax_cases(), hecs_cases(), capacity_cases(),
                       honest_partial_cases(), structure_cases()]),
    Fails = [X || X <- R, X =:= fail],
    io:format("~n================================================================~n"),
    case Fails of
        [] -> io:format("PASS — all ~p serviceability anchors hold~n", [length(R)]), halt(0);
        _  -> io:format("FAIL — ~p anchor(s) mismatched~n", [length(Fails)]), halt(1)
    end.

%% --- fixtures ---------------------------------------------------------------
%% the IC0 worked example: $95k assessable, $20k HECS balance, $10k card limit.
prof(Income, Debts) -> #{<<"assessable_income">> => Income, <<"debts">> => Debts}.
ic0_debts() -> #{<<"hecs_balance">> => 20000, <<"credit_card_limits_total">> => 10000}.

%% --- 1. income tax (2026-27 resident schedule, to the dollar) ----------------
%% Second bracket cut 16%->15% from 1 Jul 2026 (kb.tax.income-tax-resident-2026-27) —
%% figures below updated from the 2025-26 schedule accordingly.
tax_cases() ->
    [ chk("tax $18,200 (tax-free ceiling) = 0",      fh_engine_mortgage:income_tax(18200),  0)
    , chk("tax $45,000 (15% band) = 4,020",          fh_engine_mortgage:income_tax(45000),  4020)
    , chk("tax $95,000 (30% band) = 19,020",         fh_engine_mortgage:income_tax(95000),  19020)
    , chk("tax $135,000 (band base) = 31,020",       fh_engine_mortgage:income_tax(135000), 31020)
    , chk("tax $190,000 (band base) = 51,370",       fh_engine_mortgage:income_tax(190000), 51370)
    , chk("tax $200,000 (45% band) = 55,870",        fh_engine_mortgage:income_tax(200000), 55870)
    , chk("net $95,000 = 95,000 - 19,020 - 1,900",   fh_engine_mortgage:net_annual_income(95000), 74080)
    ].

%% --- 2. HECS compulsory repayment (income-contingent, 2026-27 schedule) ------
%% kb.hecs.thresholds' ENTRIES already carry the 2026-27 figures ($69,528 threshold,
%% per docs/kb/news/2026-07-hecs-thresholds-2026-27.md) — only its lookup KEY NAME
%% stays "repayment_schedule_2025_26" by deliberate choice (see that doc's own
%% "Rules" note: renaming it needs a coordinated fh_engine_mortgage.erl change,
%% flagged, not done in that citation pass). This escript's own fixtures below were
%% the actually-stale part — still asserting the OLD 2025-26 ($67,000 threshold)
%% figures against a resolver that was already computing the correct 2026-27 ones.
%% Re-verified 2026-07-09 by reading the live resolver output, not hand-derived:
%% hecs_repayment(95000) = 15% x (95000-69528) = 3,820.80 (was 4,200 @ $67,000);
%% hecs_repayment(125000) = 15% x (125000-69528) = 8,320.80 (was 8,700).
%% The $200,000 case is unchanged either way (flat 10% of total, threshold-independent).
hecs_cases() ->
    [ chk("hecs $60,000 (below threshold) = 0",      fh_engine_mortgage:hecs_repayment(60000),  0)
    , chk("hecs $95,000 (15% band, $69,528 threshold) = 3,820.80", fh_engine_mortgage:hecs_repayment(95000),  3820.80)
    , chk("hecs $125,000 (band edge, $69,528 threshold) = 8,320.80", fh_engine_mortgage:hecs_repayment(125000), 8320.80)
    , chk("hecs $200,000 (10% flat top band) = 20,000", fh_engine_mortgage:hecs_repayment(200000), 20000)
    ].

%% --- 3. capacity (the IC0 worked example, reproduced exactly) ----------------
%% Re-verified 2026-07-09 against the 2026-27 tax schedule (was 2025-26/16%; every
%% figure below is higher by the ~$268/yr net-income gain from the 15% second
%% bracket). The two cases with a hecs_balance (IC0, 200k-top-band) were ALREADY
%% computed against the correct 2026-27 HECS schedule (see the hecs_cases() note
%% above — the resolver/KB were never wrong; only this escript's own direct HECS
%% fixture was) — no further change needed here now that hecs_cases() is fixed too.
capacity_cases() ->
    [ chkL("IC0 [95k, card 10k, HECS] = [357302, 466670]",
           fh_engine_mortgage:borrowing_capacity(prof(95000, ic0_debts())), [357302, 466670])
    , chkL("95k, no debts = [444101, 543526]",
           fh_engine_mortgage:borrowing_capacity(prof(95000, #{})), [444101, 543526])
    , chkL("60k, no HECS (below threshold) = [197608, 297034]",
           fh_engine_mortgage:borrowing_capacity(prof(60000, #{<<"hecs_balance">> => 0})), [197608, 297034])
    , chkL("200k top band, card 15k = [850192, 964531]",
           fh_engine_mortgage:borrowing_capacity(prof(200000, #{<<"hecs_balance">> => 20000, <<"credit_card_limits_total">> => 15000})), [850192, 964531])
    ].

%% --- 4. honest-partial (null until income is known) --------------------------
honest_partial_cases() ->
    [ chkNull("no profile facts -> null",          fh_engine_mortgage:borrowing_capacity(#{}))
    , chkNull("assessable_income null -> null",     fh_engine_mortgage:borrowing_capacity(#{<<"assessable_income">> => null}))
    , chkNull("assessable_income 0 -> null",        fh_engine_mortgage:borrowing_capacity(prof(0, #{})))
    ].

%% --- 5. structure (ordering, clamp, monotonicity, DTI bound) -----------------
structure_cases() ->
    [Lo, Hi] = fh_engine_mortgage:borrowing_capacity(prof(95000, ic0_debts())),
    [CLo, _] = fh_engine_mortgage:borrowing_capacity(prof(30000, #{})),
    [_, AHi] = fh_engine_mortgage:borrowing_capacity(prof(95000, #{})),
    [_, BHi] = fh_engine_mortgage:borrowing_capacity(prof(130000, #{})),
    DtiCap = 6 * 95000,
    [ chkBool("band ordered lo =< hi",            Lo =< Hi)
    , chkBool("low income clamps lower bound at 0", CLo =:= 0)
    , chkBool("monotonic: 130k capacity > 95k",   BHi > AHi)
    , chkBool("DTI bound: 95k cap hi =< 6x income", Hi =< DtiCap)
    ].

%% --- harness ----------------------------------------------------------------
chk(Label, Got, Want) ->
    case near(Got, Want) of
        true  -> io:format("  ok   ~s~n", [Label]), ok;
        false -> io:format("  FAIL ~s (got ~p want ~p)~n", [Label, Got, Want]), fail
    end.

chkL(Label, Got, Want) ->
    case Got =:= Want of
        true  -> io:format("  ok   ~s~n", [Label]), ok;
        false -> io:format("  FAIL ~s (got ~p)~n", [Label, Got]), fail
    end.

chkNull(Label, Got) ->
    case Got of
        null -> io:format("  ok   ~s~n", [Label]), ok;
        _    -> io:format("  FAIL ~s (got ~p)~n", [Label, Got]), fail
    end.

chkBool(Label, true)  -> io:format("  ok   ~s~n", [Label]), ok;
chkBool(Label, _)     -> io:format("  FAIL ~s~n", [Label]), fail.

near(A, B) when is_number(A), is_number(B) -> abs(A - B) < 0.5;
near(_, _) -> false.
