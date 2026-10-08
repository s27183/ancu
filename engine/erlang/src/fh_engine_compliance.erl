-module(fh_engine_compliance).

%% The compliance pipeline (Layer 2) — FIRB → ASIC → AML as a real gate, not a
%% pass-through (engine-contract §6, constraint #10, compliance-pipeline.md). Runs on
%% every committed outcome AFTER Layer 1 (fh_engine_outcome:validate/2) has rendered the
%% outcome structurally conforming. Engine-owned because it protects the agent's
%% behavior, not a shell's UX.
%%
%% Each gate produces a DISPOSITION (clear | annotate | branch | block) + a detail +
%% the Layer-1 verdict_refs it consumed. The turn (fh_engine_turn:commit) writes one
%% audit_events row per (component, gate) regardless of disposition, emits a
%% compliance_gate event, and FAILS the turn on a `block` (the outcome must not persist).
%%
%% Mode-A asymmetry (compliance-pipeline.md §1) — bind "what does this gate enforce?"
%% of each gate, in Mode A (domestic FHB, no foreign person, no fund custody):
%%   - FIRB → no body: firb_required_any is false, so there is no foreign applicant to
%%     branch. It asserts the precondition and writes a `clear`/not_required row. A Mode-B
%%     turn (firb_required_any = true) hits the DEFERRED body — guarded with a loud
%%     `block`/not_implemented so an accidental Mode-B turn fails, never passes silently.
%%   - ASIC → substantive: the decision-support boundary. It CONSUMES Layer 1's
%%     figure-type verdict (never re-derives §98 — one source of truth) and attests the
%%     boundary held. Substance is scoped to advice-adjacent components (lender fit,
%%     scheme applicability); a pure-arithmetic outcome has no advice surface.
%%   - AML → no body: the base turn has no fund custody / cross-border transfer. Asserts
%%     and writes a `clear`/no_fund_custody row; the deferred body keys on
%%     funds_provenance (Mode B/D or a refine turn carrying deposit facts).
%%
%% The deferred FIRB/AML bodies are structurally present but NOT built speculatively
%% ([[build-time-structure-vs-runtime-data]]) — they assert-and-clear in Mode A and flip
%% to a real branch/block the moment their trigger (a foreign applicant / a cross-border
%% deposit) appears. The Mode-A built-now path is `clear×3` + three audit rows.

-export([run/4, run_qa/3]).

%% run(ComponentId, Ctx, Outcome, Layer1Verdict) -> {Outcome1, [GateResult]}
%%   Ctx          :: #{mode, intent, firb_required_any, ...}
%%   Layer1Verdict:: the seam validator's attestation ASIC consumes (verdict_refs)
%%   GateResult   :: #{<<"gate">>, <<"disposition">>, <<"detail">>, <<"verdict_refs">>}
%%   disposition  :: <<"clear">> | <<"annotate">> | <<"branch">> | <<"block">>
%% The pipeline never mutates upstream facts; Outcome1 == Outcome in Mode A (ASIC flags,
%% it does not silently rewrite LLM prose — an un-audited content change would defeat the
%% trail; compliance-pipeline.md §8).
-spec run(binary(), map(), map(), map()) -> {map(), [map()]}.
run(ComponentId, Ctx, Outcome, Layer1Verdict) ->
    lists:foldl(
        fun(Stage, {Out, Gates}) ->
            {Out1, Gate} = Stage(ComponentId, Ctx, Out, Layer1Verdict),
            {Out1, Gates ++ [Gate]}
        end,
        {Outcome, []},
        [fun firb/4, fun asic/4, fun aml/4]).

%% --- FIRB -------------------------------------------------------------------

%% Mode A: no foreign applicant → assert-and-clear (unchanged).
%%
%% Mode B/D (mode-b-wedge.md P2 slice 2 — fh_engine_firb now exists): every Mode-B
%% component built so far (buyer_profile / firb_workflow / mortgage_finance /
%% cash_position / ownership_planning / family_context / cross_border_funding) is
%% BASE-TURN PRE-CONTRACT PLANNING — none of them is the FATA "notifiable action"
%% (signing/settling) the established-dwelling ban actually regulates, so all clear.
%% `firb_workflow`'s own commit is never blocked by its own blocking_for_contract
%% (that field is a FLAG for a LATER gate to read, not a reason to refuse the workflow's
%% own status) — the gate just audits which state it found (pending vs approved).
%%
%% NOT YET BUILT (a later slice, not silently dropped): the per-property CONTRACT gate
%% that reads firb_workflow's STORED blocking_for_contract across components and
%% actually refuses a buying_strategy bid_plan / settlement_prep milestone commit while
%% unapproved. Those Mode-B per-property resolvers don't exist yet (P2 tracker scope is
%% base-turn only) — Phase B (property addenda) isn't built for Mode B, so no live turn
%% can reach the per-property surface. (P5, 2026-07-03, added the base_components/1
%% Mode-B clause and a live HTTP turn now exercises this base-turn clause — proven by
%% mode_b_seam_smoke.escript, 21/21 audit rows clear — but that's the base-turn path
%% above, not the per-property CONTRACT gate this note is about.)
firb(<<"firb_workflow">>, #{firb_required_any := true}, Outcome, _Verdict) ->
    Detail = case maps:get(<<"blocking_for_contract">>, Outcome, true) of
                 true  -> <<"firb_approval_pending">>;
                 false -> <<"firb_approved">>
             end,
    {Outcome, gate(<<"firb">>, <<"clear">>, Detail, #{})};
firb(_ComponentId, #{firb_required_any := true}, Outcome, _Verdict) ->
    {Outcome, gate(<<"firb">>, <<"clear">>, <<"pre_contract_planning">>, #{})};
firb(_ComponentId, _Ctx, Outcome, _Verdict) ->
    {Outcome, gate(<<"firb">>, <<"clear">>, <<"not_required">>, #{})}.

%% --- ASIC -------------------------------------------------------------------

%% The decision-support boundary. ASIC CONSUMES Layer 1's figure-type verdict (the §98
%% guard already crashed the turn before here on any violation) and attests the boundary
%% held — it does not re-derive §98. Substance is scoped to advice-adjacent components;
%% a pure-arithmetic outcome (e.g. cash_position duty) has no advice surface → clear by
%% construction, still audited. The verdict_refs record WHAT ASIC attested to, so the
%% trail shows the §98 conformance in scope for this component, not just that it cleared.
asic(ComponentId, _Ctx, Outcome, Layer1Verdict) ->
    Detail = case advice_adjacent(ComponentId) of
                 true  -> <<"decision_support_boundary_held">>;
                 false -> <<"no_advice_surface">>
             end,
    {Outcome, gate(<<"asic">>, <<"clear">>, Detail, Layer1Verdict)}.

%% Components whose outcomes carry advice-adjacent content (compliance-pipeline.md §3).
advice_adjacent(<<"mortgage_finance">>)    -> true;   %% lender fit
advice_adjacent(<<"eligibility">>)         -> true;   %% scheme applicability
advice_adjacent(<<"firb_workflow">>)       -> true;   %% FIRB eligibility/fee framing (Mode B/D)
advice_adjacent(<<"property_assessment">>) -> true;   %% investment-viability verdict (Phase B)
advice_adjacent(<<"buying_strategy">>)     -> true;   %% bid plan / negotiation (Phase B) — ACL hedge
advice_adjacent(<<"due_diligence">>)       -> true;   %% risk surfacing / yield-vs-thesis (Phase B) — ACL hedge
advice_adjacent(<<"tax_structure">>)       -> true;   %% agent-authored recommended_entity (Mode C) — #27
advice_adjacent(<<"tax_structure_non_resident">>) -> true;  %% entity structuring for a non-resident (Mode D) — #27
advice_adjacent(<<"investment_strategy">>) -> true;   %% agent-authored archetype / gearing / thesis (C, D) — #27
advice_adjacent(_)                         -> false.

%% --- AML --------------------------------------------------------------------

%% Mode A: no cross-border transfer / no fund custody → assert-and-clear. Deferred body
%% keys on funds_provenance (absent at base; surfaces with a refine turn carrying deposit
%% facts) — route money transfer only to licensed partners, block informal VN routes.
aml(_ComponentId, _Ctx, Outcome, _Verdict) ->
    {Outcome, gate(<<"aml">>, <<"clear">>, <<"no_fund_custody">>, #{})}.

%% --- Q&A variant (compliance-pipeline.md §10) -------------------------------

%% The conversational producer: the "outcome" is a free-text bilingual answer, not a
%% structured component outcome. Same FIRB → ASIC → AML composition, but ASIC is the
%% SUBSTANTIVE gate here (free text can phrase advice in ways a typed schema forbids by
%% construction) and reads the answer TEXT. FIRB/AML assert-and-clear as in the base
%% turn (Mode A). Returns {Answer, [GateResult]} — ASIC flags (annotate), it never
%% rewrites the prose (§8).
-spec run_qa(map(), map(), map()) -> {map(), [map()]}.
run_qa(Ctx, Answer, Layer1Verdict) ->
    Cid = <<"q_and_a">>,
    {_, FirbG} = firb(Cid, Ctx, #{}, #{}),
    AsicG = asic_qa(Answer, Layer1Verdict),
    {_, AmlG} = aml(Cid, Ctx, #{}, #{}),
    {Answer, [FirbG, AsicG, AmlG]}.

%% ASIC on the free-text answer. A DETERMINISTIC backstop + the audit attestation — NOT
%% a semantic judge. Reliability of the prose is the producer's grounding job (KB + the
%% decision-support scaffold), never adjudication: an LLM-judge would only move the trust
%% problem (a judge needs a judge), so we don't have one. This gate does only what a
%% deterministic check can do reliably — attest the boundary + audit, and catch BLATANT
%% crossings the grounding should already have prevented:
%%   - an explicit licensed-advice claim → `block` (the answer must not reach the user);
%%   - an imperative personal recommendation → `annotate` (flag, never silent rewrite).
%% The pattern lists are intentionally small and high-precision (a false `block` on a
%% legitimate answer is its own harm). BOUNDARY: the patterns are English-side (scanning
%% bilingual prose semantically is exactly the judge problem we reject); the gross-case
%% backstop is not a semantic guarantee, and the audit row records ASIC ran regardless.
asic_qa(Answer, Layer1Verdict) ->
    Text = answer_text(Answer),
    case asic_scan(Text) of
        block ->
            gate(<<"asic">>, <<"block">>, <<"asic_advice_crossing">>, Layer1Verdict);
        annotate ->
            gate(<<"asic">>, <<"annotate">>, <<"reframed_as_information">>, Layer1Verdict);
        clear ->
            gate(<<"asic">>, <<"clear">>, <<"decision_support_boundary_held">>,
                 Layer1Verdict)
    end.

%% The answer's languages joined + lowercased for the pattern scan.
answer_text(Answer) when is_map(Answer) ->
    Parts = [V || V <- maps:values(Answer), is_binary(V)],
    Joined = iolist_to_binary(lists:join(<<" ">>, Parts)),
    unicode:characters_to_binary(string:lowercase(Joined));
answer_text(_) -> <<>>.

asic_scan(Text) ->
    case contains_any(Text, block_patterns()) of
        true -> block;
        false ->
            case contains_any(Text, annotate_patterns()) of
                true -> annotate;
                false -> clear
            end
    end.

%% Explicit licensed-advice framing — the egregious crossing the scaffold forbids.
block_patterns() ->
    [<<"as your financial adviser">>, <<"as your financial advisor">>,
     <<"as your credit adviser">>, <<"this is financial advice">>,
     <<"this is credit advice">>, <<"i am licensed">>,
     <<"guaranteed approval">>, <<"i guarantee">>].

%% Imperative personal recommendation — informational content phrased as a directive.
annotate_patterns() ->
    [<<"you should take">>, <<"you should choose">>, <<"i recommend you">>,
     <<"you must choose">>, <<"the best loan for you is">>,
     <<"the right loan for you is">>].

contains_any(_Text, []) -> false;
contains_any(Text, [P | Rest]) ->
    case binary:match(Text, P) of
        nomatch -> contains_any(Text, Rest);
        _       -> true
    end.

%% --- internals --------------------------------------------------------------

gate(Name, Disposition, Detail, VerdictRefs) ->
    #{<<"gate">> => Name,
      <<"disposition">> => Disposition,
      <<"detail">> => Detail,
      <<"verdict_refs">> => VerdictRefs}.
