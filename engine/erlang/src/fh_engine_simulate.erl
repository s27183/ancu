-module(fh_engine_simulate).

%% The simulate PREVIEW (engine-contract §10.1) — a pure, synchronous, resolver-only
%% recompute of the base plan under structural what-if overrides. It is a PREVIEW, NOT
%% a turn: no gen_statem, no persist (content_jsonb), no plan_card_events, no usage, no
%% audit_events, no event_cursor advance — so it is exempt from the per-card
%% serialization invariant (a preview can never race the snapshot).
%%
%% It walks the SAME base-resolver DAG the turn walks (fh_engine_turn:base_components/0,
%% the single source of the ordered list), calling fh_engine_fill:resolver/3 per
%% component and the Layer-1 structural gate (fh_engine_outcome:validate/2 — type walk +
%% the W6g placement/provenance check, fail-closed), accumulating outcomes by
%% outcome_type for the downstream components — exactly the base_turn_order_smoke chain.
%% The figures it returns are the SAME verified figures a save would commit (same
%% resolver code path; duty to the dollar). This is the structural answer to "make the
%% calculator interactive without a second, unverified computer".
%%
%% Two-path note: mortgage_finance is two-path (resolver figures + an agent lender
%% shortlist). simulate runs ONLY its resolver half — a figure what-if needs no LLM and
%% emits no usage; the agent leaf's inputs don't change under a price/state what-if.
%%
%% Purity: pure given (Onboarding, Intent) + the persistent_term artifact. The only DB
%% touch is projection_state/1's suburb read for a zone/SAL-pinned card (a READ, never a
%% write); a `state` override strips the pin so even that read is skipped (step-3 pure).
%%
%% Compliance (§10.3): the preview runs ONLY the structural gate. A figure what-if
%% (target_price / state / horizon) is deterministic and cannot move a FIRB/ASIC/AML
%% branch — the full pipeline runs at COMMIT (the refine turn, W7b), never here.

-export([apply_overrides/2, run/2, run/3]).

%% --- override mapping (engine-contract §10.1/§10.2) -------------------------
%%
%% Map the request `overrides` onto the card's onboarding fact base. Base simulate
%% accepts the structural facts the financial spine depends on: `target_price`, `state`,
%% and `horizon` (the dispose-phase hold years H, engine-contract §10.5). `property_type`
%% is a Phase-B (per-property) dimension — at base there is no property, so it moves ZERO
%% base financial figures (duty = f(state, price)); it is REJECTED with a clear reason,
%% never silently dropped (engine-contract §10.1, Fork A).
%%
%% apply_overrides(Overrides, Onboarding) ->
%%     {ok, Onboarding'} | {error, Reason}
%%   Reason :: property_type_phase_b
%%           | {unknown_override, binary()}
%%           | {invalid_override, binary()}
%%           | not_a_map
-spec apply_overrides(map(), map()) -> {ok, map()} | {error, term()}.
apply_overrides(Overrides, Onboarding) when is_map(Overrides) ->
    try {ok, lists:foldl(fun apply_one/2, Onboarding, maps:to_list(Overrides))}
    catch throw:Reason -> {error, Reason} end;
apply_overrides(_Overrides, _Onboarding) ->
    {error, not_a_map}.

%% target_price (a single number) → a POINT range [p, p]. The band collapses to a point
%% and re-runs from buyer_profile so the point flows to eligibility/cash/journey.
apply_one({<<"target_price">>, P}, Ob) when is_number(P), P > 0 ->
    Ob#{<<"target_price_range">> => [P, P]};
apply_one({<<"target_price">>, _}, _Ob) ->
    throw({invalid_override, <<"target_price">>});
%% state → set the explicit state AND strip target_sal/target_zone, so projection_state/1
%% step-3 (explicit, pure, no-DB) wins authoritatively over a stale pinned suburb/zone: a
%% state what-if is a base/zone-default projection. "ALL"/empty is not a single state.
apply_one({<<"state">>, S}, Ob)
  when is_binary(S), S =/= <<>>, S =/= <<"ALL">> ->
    maps:remove(<<"target_zone">>,
        maps:remove(<<"target_sal">>, Ob#{<<"state">> => S}));
apply_one({<<"state">>, _}, _Ob) ->
    throw({invalid_override, <<"state">>});
%% horizon → the hold horizon H (years), the dispose-phase structural what-if (engine-contract
%% §10.5, lifecycle-simulation-model §8). It sets hold_horizon_years on the fact base, which
%% buyer_profile projects into the profile outcome; disposition then projects the dispose figures
%% over H (sale proceeds, selling costs, net + full-horizon position). Exactly like target_price /
%% state — deterministic, resolver-only, no usage; it cannot move a FIRB/ASIC/AML branch (§10.3),
%% so it rides the structural-only preview gate and is inert at the Layer-2 commit pipeline. A
%% positive integer; clearing the projection is the ABSENCE of the override (the Mode-A long/
%% indefinite default), so 0/null is rejected, not a silent clear.
apply_one({<<"horizon">>, H}, Ob) when is_integer(H), H > 0 ->
    Ob#{<<"hold_horizon_years">> => H};
apply_one({<<"horizon">>, _}, _Ob) ->
    throw({invalid_override, <<"horizon">>});
%% property_type: a Phase-B per-property dimension — out of base scope (Fork A).
apply_one({<<"property_type">>, _}, _Ob) ->
    throw(property_type_phase_b);
apply_one({K, _}, _Ob) ->
    throw({unknown_override, K}).

%% --- the pure resolver-only walk --------------------------------------------
%%
%% run(Onboarding, Intent) -> {ok, #{OutcomeType => Outcome}}
%% Crashes (fail-closed) if any outcome fails the Layer-1 gate — that is an engine bug,
%% not a user error; the caller maps the crash to 500 and the (unpersisted) outcome never
%% reaches the client as a 200.
-spec run(map(), binary()) -> {ok, map()}.
run(Onboarding, Intent) ->
    run(Onboarding, Intent, #{}).

%% IC3: preview parity — the what-if recompute reads the same enriched financials the
%% persisted turn does (preview = commit minus persistence), so a structural what-if
%% surfaces capacity / full-horizon when the profile already carries income. Financials
%% are a profile fact, NOT a what-if dimension — they pass through unchanged.
-spec run(map(), binary(), map()) -> {ok, map()}.
run(Onboarding, Intent, Financials) ->
    Args = #{onboarding => Onboarding, intent => Intent,
             household_financials => Financials},
    Components = fh_engine_turn:base_components(),
    Outcomes =
        lists:foldl(
          fun(Comp, Up) ->
              Name = maps:get(<<"name">>, Comp),
              Type = maps:get(<<"outcome_type">>, Comp, Name),
              {Outcome, _Renderer, _Kb} = fh_engine_fill:resolver(Name, Args, Up),
              ok = fh_engine_outcome:validate(Type, Outcome),
              Up#{Type => Outcome}
          end, #{}, Components),
    {ok, Outcomes}.
