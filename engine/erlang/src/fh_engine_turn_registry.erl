-module(fh_engine_turn_registry).

%% Thin API over the ETS table `fh_engine_turn_registry` (created + owned by
%% fh_engine_turn_sup so it outlives individual turns). Enforces the serialization
%% invariant — at most one in-flight turn per plan_card_id (engine-contract §4) — and
%% lets the cancel endpoint find a running turn by plan_card_id. Entries are
%% tenant-scoped by virtue of the caller having validated the tenant owns the card.

-export([reserve/2, set_pid/3, lookup/1, release/1]).

-define(TAB, fh_engine_turn_registry).

%% Atomically claim the plan card for a turn. {error, in_flight} if one is running.
-spec reserve(binary(), binary()) -> ok | {error, in_flight}.
reserve(PlanCardId, TurnId) ->
    case ets:insert_new(?TAB, {PlanCardId, #{turn_id => TurnId, pid => undefined}}) of
        true -> ok;
        false -> {error, in_flight}
    end.

-spec set_pid(binary(), binary(), pid()) -> ok.
set_pid(PlanCardId, TurnId, Pid) ->
    ets:insert(?TAB, {PlanCardId, #{turn_id => TurnId, pid => Pid}}),
    ok.

-spec lookup(binary()) -> {ok, map()} | {error, not_found}.
lookup(PlanCardId) ->
    case ets:lookup(?TAB, PlanCardId) of
        [{_, Entry}] -> {ok, Entry};
        [] -> {error, not_found}
    end.

-spec release(binary()) -> ok.
release(PlanCardId) ->
    ets:delete(?TAB, PlanCardId),
    ok.
