-module(fh_engine_pubsub).

%% Fan-out of typed events from a running turn to connected SSE handlers, over the
%% built-in `pg` process groups (no gproc dep). One group per plan_card_id. The DB
%% (plan_card_events) stays the SOT for replay; this is only the live push — an SSE
%% handler joins the group, replays from the DB since Last-Event-ID, then forwards
%% live messages, deduping by the monotonic event_id (engine-contract §4 ordering).

-export([child_spec/0, subscribe/1, publish/2]).

-define(SCOPE, fh_engine_pg).

%% Supervised pg scope process (started by fh_engine_sup before turns run).
-spec child_spec() -> supervisor:child_spec().
child_spec() ->
    #{id => ?SCOPE,
      start => {pg, start_link, [?SCOPE]},
      restart => permanent,
      type => worker}.

-spec subscribe(binary()) -> ok.
subscribe(PlanCardId) ->
    pg:join(?SCOPE, group(PlanCardId), self()),
    ok.

%% Push {plan_card_event, PlanCardId, {EventId, Type, PayloadMap}} to subscribers.
-spec publish(binary(), {integer(), binary(), map()}) -> ok.
publish(PlanCardId, Event) ->
    Members = pg:get_members(?SCOPE, group(PlanCardId)),
    lists:foreach(fun(Pid) -> Pid ! {plan_card_event, PlanCardId, Event} end, Members),
    ok.

group(PlanCardId) -> {plan_card, PlanCardId}.
