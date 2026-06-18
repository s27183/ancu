-module(fh_engine_refresh).

%% The refresh sweep (plan-card-refresh.md) — re-run saved cards' base plans after a
%% rebuild of the base-plan logic/artifact, or a workflow that changes the card basis.
%% RESOLVER-ONLY (kind => base_resolver): re-runs the deterministic fills + the two-path
%% resolver halves, re-attaching the existing agent leaves — NO LLM, deterministic,
%% instant. Reuses the per-card re-run primitive (get_card_rerun_context + start_turn);
%% base-scope only (per-property addenda + conversation untouched); one in-flight turn
%% per card (registry-gated — a running card is skipped, not double-filled).
%%
%% Triggers (one primitive, several callers): the dev boot-sweep (fh_engine_app, gated),
%% a workflow's final step, or a future authenticated prod admin trigger.
%%
%% Scope: `all` (every active base plan) for now. Provenance-driven targeting (build SHA
%% / kb_versions slug / blueprint) is the documented refinement — the per-fill provenance
%% already supports it; this coarse sweep logs its count so nothing is silently skipped.
%%
%% NOTE (concurrency): each card's turn is async and serialized per-card by the registry;
%% the sweep starts them without a global cap. Fine for the dev fleet; a prod sweep must
%% bound in-flight turns + the metering budget (plan-card-refresh.md §safety).

-export([sweep/1, refresh_card/1]).
%% Shared with fh_engine_h_refine (W7b): the base_resolver turn-start primitive and the
%% existing-leaf extraction. Refine is the refresh sweep driven by an OVERRIDDEN onboarding
%% (a saved what-if) instead of the card's current onboarding — same turn, same no-usage,
%% same re-attached agent leaves. One source so the two callers can never drift.
-export([start_base_resolver/4, existing_outcomes/1]).

-spec sweep(all) -> map().
sweep(all) ->
    Ids = fh_engine_store:list_active_plan_card_ids(),
    Results = [{Id, refresh_card(Id)} || Id <- Ids],
    Started = [Id || {Id, started} <- Results],
    Skipped = [{Id, R} || {Id, {skipped, R}} <- Results],
    logger:notice("[refresh-sweep] ~p active card(s): ~p started, ~p skipped ~p",
                  [length(Ids), length(Started), length(Skipped), Skipped]),
    #{total => length(Ids), started => length(Started),
      skipped => length(Skipped)}.

%% Re-run one card's base plan resolver-only. Returns `started` | {skipped, Reason}.
-spec refresh_card(binary()) -> started | {skipped, atom()}.
refresh_card(PlanCardId) ->
    case fh_engine_store:get_card_rerun_context(PlanCardId) of
        {error, not_found} ->
            {skipped, not_found};
        {ok, Ctx} ->
            TenantId = maps:get(tenant_id, Ctx),
            case fh_engine_store:get_plan_card(TenantId, PlanCardId) of
                {error, not_found} ->
                    {skipped, not_found};
                {ok, Card} ->
                    start(PlanCardId, Ctx, existing_outcomes(Card))
            end
    end.

start(PlanCardId, Ctx, Existing) ->
    Onboarding = maps:get(<<"onboarding">>, maps:get(facts, Ctx), #{}),
    case start_base_resolver(PlanCardId, Ctx, Existing, Onboarding) of
        {ok, _TurnId}       -> started;
        {error, in_flight}  -> {skipped, in_flight}
    end.

%% Reserve + start one card's base_resolver turn against an EXPLICIT onboarding (the
%% refresh sweep passes the card's current onboarding; a refine — W7b — passes the
%% overridden what-if). Resolver-only: re-runs the deterministic fills, SKIPS the two-path
%% sidecar and re-attaches the stored agent leaves from `Existing` (no LLM, no `usage`).
%% One in-flight turn per card (registry-gated → {error, in_flight}).
-spec start_base_resolver(binary(), map(), map(), map()) ->
    {ok, binary()} | {error, in_flight}.
start_base_resolver(PlanCardId, Ctx, Existing, Onboarding) ->
    TurnId = fh_engine_util:uuid4(),
    case fh_engine_turn_registry:reserve(PlanCardId, TurnId) of
        {error, in_flight} ->
            {error, in_flight};
        ok ->
            Derived = maps:get(<<"derived">>, maps:get(facts, Ctx), #{}),
            {ok, _Pid} = fh_engine_turn_sup:start_turn(#{
                tenant_id => maps:get(tenant_id, Ctx),
                user_id => maps:get(user_id, Ctx),
                plan_card_id => PlanCardId,
                turn_id => TurnId,
                mode => maps:get(mode, Ctx),
                intent => maps:get(intent, Ctx),
                firb_required_any => maps:get(<<"firb_required_any">>, Derived, false),
                onboarding => Onboarding,
                kind => base_resolver,
                existing_outcomes => Existing
            }),
            {ok, TurnId}
    end.

%% #{component_id => outcome} from the card's content snapshot — fed to the
%% resolver-only turn so two-path components re-attach their existing agent leaves.
-spec existing_outcomes(map()) -> map().
existing_outcomes(Card) ->
    Components = maps:get(<<"components">>, maps:get(<<"content">>, Card, #{}), #{}),
    maps:map(fun(_Name, Entry) -> maps:get(<<"outcome">>, Entry, #{}) end, Components).
