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

-export([run/4]).

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

%% Mode A: no foreign applicant → assert-and-clear. Mode B/D body deferred: assert the
%% precondition LOUDLY (block/not_implemented) so an accidental Mode-B turn fails rather
%% than silently passing an unenforced foreign-buyer path (compliance-pipeline.md §3).
firb(_ComponentId, #{firb_required_any := true}, Outcome, _Verdict) ->
    {Outcome, gate(<<"firb">>, <<"block">>, <<"not_implemented_mode_b">>, #{})};
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
advice_adjacent(<<"mortgage_finance">>) -> true;   %% lender fit
advice_adjacent(<<"eligibility">>)      -> true;   %% scheme applicability
advice_adjacent(_)                      -> false.

%% --- AML --------------------------------------------------------------------

%% Mode A: no cross-border transfer / no fund custody → assert-and-clear. Deferred body
%% keys on funds_provenance (absent at base; surfaces with a refine turn carrying deposit
%% facts) — route money transfer only to licensed partners, block informal VN routes.
aml(_ComponentId, _Ctx, Outcome, _Verdict) ->
    {Outcome, gate(<<"aml">>, <<"clear">>, <<"no_fund_custody">>, #{})}.

%% --- internals --------------------------------------------------------------

gate(Name, Disposition, Detail, VerdictRefs) ->
    #{<<"gate">> => Name,
      <<"disposition">> => Disposition,
      <<"detail">> => Detail,
      <<"verdict_refs">> => VerdictRefs}.
