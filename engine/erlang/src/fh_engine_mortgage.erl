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
-define(COPY, <<"kb.copy.mortgage">>).   %% bilingual copy-templates (bilingual-content.md §3b)

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
%% 5%/3-month genuine-savings convention is pulled from the serviceability KB so there is
%% no magic literal; the user-facing copy is the bilingual {vi,en} template (kb.copy.mortgage)
%% interpolated by fh_engine_i18n:subst/2 — no Vietnamese literal in Erlang, no io:format ~s
%% (bilingual-content.md §3b). Informational/decision-support, not advice.
-spec pre_approval_action_plan() -> [fh_engine_i18n:localized()].
pre_approval_action_plan() ->
    Pct    = kb_param(?SERVICEABILITY, <<"genuine_savings_min_pct">>),
    Months = kb_param(?SERVICEABILITY, <<"genuine_savings_min_months">>),
    [ copy(<<"action_genuine_savings">>, #{<<"pct">> => Pct, <<"months">> => Months}),
      copy(<<"action_income_evidence">>, #{}),
      copy(<<"action_list_debts">>, #{}),
      copy(<<"action_compare_panel">>, #{}) ].

%% key_assumptions: the one regulated constant (the buffer) plus the conventions that
%% shape capacity, each flagged as a convention (not this buyer's actual lender policy),
%% and the honest-partial note that capacity is pending the income/debt facts. Bilingual
%% via kb.copy.mortgage; only the buffer figure is interpolated.
-spec key_assumptions(number(), boolean()) -> [fh_engine_i18n:localized()].
key_assumptions(BufferPp, HasFhg) ->
    Base = [ copy(<<"assume_buffer">>, #{<<"buffer_pp">> => BufferPp}),
             copy(<<"assume_conventions">>, #{}),
             copy(<<"assume_pending">>, #{}) ],
    case HasFhg of
        true  -> [copy(<<"assume_fhg">>, #{}) | Base];
        false -> Base
    end.

%% subst a kb.copy.mortgage template into a bilingual {vi,en} value.
-spec copy(binary(), #{binary() => fh_engine_i18n:param()}) -> fh_engine_i18n:localized().
copy(Id, Params) ->
    fh_engine_i18n:subst(fh_engine_kb:copy(?COPY, Id), Params).

%% --- KB access (matches fh_engine_ownership / fh_engine_cash) ----------------

buffer_pp() ->
    kb_param(?SERVICEABILITY, <<"apra_serviceability_buffer_pp">>).

kb_param(Slug, Key) ->
    {ok, Cj} = fh_engine_kb:kb_rules(Slug),
    Params = maps:get(<<"parameters">>, Cj),
    maps:get(<<"value">>, maps:get(Key, Params)).
