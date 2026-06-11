-module(fh_engine_mortgage).

%% The base-turn `mortgage_finance` fill — the RESOLVER half of a TWO-PATH component
%% (mortgage-finance-two-path.md). It assembles the `mortgage_plan` outcome's figures
%% and loan-path structure deterministically; the two `lender_fit` leaves
%% (`recommended_lender_shortlist`, `loan_structure_recommendation.rate`) are left
%% `null` for the agent and folded in by merge_agent/2 after the sidecar replies.
%%
%% §98 (agentic-boundary): borrowing capacity is a COMPLIANCE-sensitive figure and must
%% be computed, never LLM-asserted. At the base turn income + committed debts are ABSENT
%% (buyer_profile leaves them pending), so capacity is honestly PENDING (null) — the same
%% honest-partial call as ownership P&I and cash deposit/loan. The capacity *formula*
%% (buffer-assessed) is a refine-turn concern; §98 keeps it resolver-computed there too.
%%
%% KB supplies the data (the 3.0pp APRA buffer is the one regulated constant; the rest
%% are flagged conventions); code supplies the assembly. No literals — every figure is a
%% KB param or a stated function of one.

-export([fill/2, merge_agent/2]).
%% exported for cross-language conformance (tests/mortgage_eval.py mirrors these):
-export([recommended_path/1, has_fhg/1, loan_structure_base/0, key_assumptions/2,
         pre_approval_action_plan/0]).

-define(SERVICEABILITY, <<"kb.lender.serviceability-basics">>).

%% --- fill (resolver half) ---------------------------------------------------

-spec fill(map(), map()) -> {map(), binary(), [map()]}.
fill(_Args, Upstream) ->
    Profile = maps:get(<<"profile">>, Upstream, #{}),
    Stack   = maps:get(<<"scheme_stack">>, Upstream, #{}),
    HasFhg  = has_fhg(Stack),
    _TargetRange = maps:get(<<"target_price_range">>, Profile, null),
    Outcome = #{
        %% DETERMINATE from eligibility: FHG present → the 5%-deposit, no-LMI path is
        %% the recommended one for a Mode-A FHB; absent → pending the deposit %.
        <<"recommended_path">> => recommended_path(Stack),
        %% PENDING — income/debts absent at base; §98: never LLM-authored.
        <<"expected_borrowing_capacity">> => null,
        %% PENDING — needs the debt balances (HECS/cards/BNPL), absent at base.
        <<"debt_optimisations_to_action">> => [],
        %% AGENT slot (lender_fit) — filled by merge_agent/2 from the sidecar reply.
        <<"recommended_lender_shortlist">> => null,
        <<"loan_structure_recommendation">> => loan_structure_base(),
        <<"pre_approval_action_plan">> => pre_approval_action_plan(),
        %% F11 — null until pre-approval is granted (a refine/event turn).
        <<"pre_approval_expiry">> => null,
        <<"reapplication_required">> => false,
        <<"key_assumptions">> => key_assumptions(buffer_pp(), HasFhg)
    },
    KbVersions = fh_engine_kb:kb_anchors(
        [?SERVICEABILITY, <<"kb.lender.fhg-panel-list">>, <<"kb.lmi.calculation">>,
         <<"kb.lender.hecs-treatment-by-lender">>, <<"kb.lender.credit-card-treatment">>,
         <<"kb.lender.bnpl-treatment-2026">>]),
    {Outcome, <<"summary-card">>, KbVersions}.

%% --- merge_agent (fold the two lender_fit leaves into the resolver outcome) --
%% AgentValues carries ONLY the two qualitative leaves the sidecar authored; the merge
%% is slot-scoped, so the LLM cannot author or overwrite any figure (the §98 property,
%% verifiable: every other field — capacity, path, optimisations — is byte-identical).

-spec merge_agent(map(), map()) -> map().
merge_agent(ResolverOutcome, AgentValues) ->
    Shortlist = maps:get(<<"recommended_lender_shortlist">>, AgentValues, []),
    Rate      = maps:get(<<"fixed_vs_variable">>, AgentValues, null),
    LS0 = maps:get(<<"loan_structure_recommendation">>, ResolverOutcome),
    ResolverOutcome#{
        <<"recommended_lender_shortlist">> => Shortlist,
        <<"loan_structure_recommendation">> => LS0#{<<"rate">> => Rate}
    }.

%% --- structure (KB-grounded, determinate) -----------------------------------

%% FHG in the eligibility scheme_stack (by role, deposit_guarantee) → the recommended
%% path is the FHG-backed 5%-deposit, no-LMI loan. Else pending the deposit %.
-spec recommended_path(map()) -> binary() | null.
recommended_path(Stack) ->
    case has_fhg(Stack) of
        true  -> <<"fhg_backed">>;
        false -> null
    end.

%% detect the FHG in the eligibility scheme_stack by role (deposit_guarantee) — the
%% same projection ownership_planning uses (one decision, read from the outcome).
-spec has_fhg(map()) -> boolean().
has_fhg(Stack) ->
    Schemes = maps:get(<<"applicable_schemes">>, Stack, []),
    lists:any(fun(S) -> maps:get(<<"role">>, S, <<>>) =:= <<"deposit_guarantee">> end,
              Schemes).

%% Mode-A FHB default loan structure: P&I (blueprint constant). `rate` is the agent
%% leaf (null until merge_agent); offset is a refine-turn behavioural choice.
-spec loan_structure_base() -> map().
loan_structure_base() ->
    #{<<"type">> => <<"principal_and_interest">>,
      <<"rate">> => null,
      <<"offset">> => null}.

%% A generic, KB-grounded pre-approval action plan (process steps, not figures). The
%% 5%/3-month genuine-savings convention is pulled from the serviceability KB so there
%% is no magic literal; informational/decision-support, not advice.
-spec pre_approval_action_plan() -> [binary()].
pre_approval_action_plan() ->
    Pct    = kb_param(?SERVICEABILITY, <<"genuine_savings_min_pct">>),
    Months = kb_param(?SERVICEABILITY, <<"genuine_savings_min_months">>),
    [ iolist_to_binary(io_lib:format(
        "Build genuine-savings evidence: about ~p% of the purchase price held for ~p+ "
        "months (regular savings, not a sudden lump sum).", [Pct, Months])),
      <<"Gather income evidence (recent payslips; tax returns if self-employed).">>,
      <<"List current debts with their limits (HECS, credit cards, BNPL, personal/car "
        "loans) - limits, not balances, drive serviceability.">>,
      <<"Compare lenders across the First Home Guarantee panel, or engage a broker who "
        "covers many panel lenders.">> ].

%% key_assumptions: the one regulated constant (the buffer) plus the conventions that
%% shape capacity, each flagged as a convention (not this buyer's actual lender policy),
%% and the honest-partial note that capacity is pending the income/debt facts.
-spec key_assumptions(number(), boolean()) -> [binary()].
key_assumptions(BufferPp, HasFhg) ->
    Base = [
        iolist_to_binary(io_lib:format(
            "Borrowing capacity is assessed at your product rate + ~p percentage points "
            "(the APRA serviceability buffer - a regulated constant).", [BufferPp])),
        <<"Income shading (~80% of overtime/bonus/rental), the genuine-savings rule, and "
          "the high-DTI ceiling (about 6x income) are lender conventions, not your "
          "actual lender's policy - a broker confirms the specifics.">>,
        <<"Your borrowing capacity and debt-optimisation figures are pending - they "
          "compute once your income and debts are entered.">> ],
    case HasFhg of
        true  -> [<<"The First Home Guarantee lets you borrow with a 5% deposit and no "
                    "LMI; there is no rate premium for using the guarantee.">> | Base];
        false -> Base
    end.

%% --- KB access (matches fh_engine_ownership / fh_engine_cash) ----------------

buffer_pp() ->
    kb_param(?SERVICEABILITY, <<"apra_serviceability_buffer_pp">>).

kb_param(Slug, Key) ->
    {ok, Cj} = fh_engine_kb:kb_rules(Slug),
    Params = maps:get(<<"parameters">>, Cj),
    maps:get(<<"value">>, maps:get(Key, Params)).
