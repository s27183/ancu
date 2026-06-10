-module(fh_engine_compliance).

%% The compliance extension pipeline (engine-contract §6, constraint #10). Runs a
%% FIXED sequence of gates over each proposed component outcome BEFORE it is committed
%% and streamed — FIRB → ASIC → AML. Engine-owned because it protects the agent's
%% behavior, not a shell's UX.
%%
%% Slice 1 wires the pipeline structurally: the three stages exist and run on every
%% component, but for Mode A (domestic, no foreign person) each is a pass-through —
%% FIRB has no foreign applicant to branch, ASIC has no advice-crossing to rewrite
%% (the stub emits decision-support shapes), AML has no fund custody. Slice 2 (real
%% sidecar) fills the stage bodies. Building the gate now, empty, is the point of
%% constraint #10: "the gate in the architecture, not as a disclaimer."

-export([run/3]).

%% run(ComponentId, Context, Outcome) -> {Outcome1, [GateEvent]}
%%   Context :: #{mode, firb_required_any, intent, ...}
%%   GateEvent :: #{gate := binary(), disposition := binary(), detail := binary()}
-spec run(binary(), map(), map()) -> {map(), [map()]}.
run(ComponentId, Context, Outcome) ->
    lists:foldl(
        fun(Stage, {Out, Gates}) ->
            {Out1, NewGates} = Stage(ComponentId, Context, Out),
            {Out1, Gates ++ NewGates}
        end,
        {Outcome, []},
        [fun firb/3, fun asic/3, fun aml/3]).

%% FIRB — branches on a foreign applicant (constraint #10). Mode A enters via a
%% non-foreign lead; firb_required_any flags a foreign co-applicant. Pass-through
%% until slice 2 enforces the established-dwelling ban / new-build-only filter.
firb(_ComponentId, #{firb_required_any := true}, Outcome) ->
    %% slice 2: enforce ban window + new-build-only; emit branch gate here.
    {Outcome, []};
firb(_ComponentId, _Context, Outcome) ->
    {Outcome, []}.

%% ASIC — decision-support boundary (no licensed financial/credit advice). Slice 2
%% inspects the outcome for advice-crossing and rewrites/flags. Pass-through now.
asic(_ComponentId, _Context, Outcome) ->
    {Outcome, []}.

%% AML — never custodian of funds; money-transfer guidance routes to licensed
%% partners; informal-channel routes blocked. Slice 2 inspects funds_provenance.
aml(_ComponentId, _Context, Outcome) ->
    {Outcome, []}.
