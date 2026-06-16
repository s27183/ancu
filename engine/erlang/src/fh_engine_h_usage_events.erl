-module(fh_engine_h_usage_events).

%% GET /api/engine/usage_events?after=<cursor>&limit=<n> — the engine side of the
%% shell's pull-model outbox (billing.md §2/§6, engine-contract §9). The shell's
%% fh_shell_usage_consumer polls this by cursor and mirrors each event into its own
%% usage_records (metering, never gating — principle 5; commerce stays shell-side).
%%
%% AUTHENTICATE the tenant JWT and SCOPE rows to the JWT's tenant_id. Unlike
%% fh_engine_h_suburbs (authenticates then ignores tenant — suburbs is global), this
%% IS tenant-scoped: usage is per-tenant billing data, never cross-tenant. The poll
%% carries the shell's system principal as user_id (the endpoint authorizes on tenant,
%% not user — the mirror is tenant-wide).
%%
%% `after` is the highest event_id the caller has mirrored (0 to start); we return
%% usage events with event_id > after, ASC, capped at `limit`. Each event is the stored
%% §9-flat usage payload (vendor-neutral, normalized in planner.py) + usage_event_id
%% (the bigint plan_card_events.event_id, the cursor). An empty result is valid — the
%% poller simply idles. `cursor` echoes the last id in the batch (or `after` if empty).

-export([init/2]).

-define(DEFAULT_LIMIT, 200).
-define(MAX_LIMIT, 1000).

init(Req0, State) ->
    case cowboy_req:method(Req0) of
        <<"GET">> -> handle_get(Req0, State);
        _ ->
            {ok, fh_engine_http:reply_json(405,
                #{<<"error">> => <<"method_not_allowed">>}, Req0), State}
    end.

handle_get(Req0, State) ->
    case fh_engine_http:authenticate(Req0) of
        {ok, #{tenant_id := TenantId}} ->
            Qs = cowboy_req:parse_qs(Req0),
            After = parse_int(proplists:get_value(<<"after">>, Qs), 0),
            Limit = clamp(parse_int(proplists:get_value(<<"limit">>, Qs),
                                    ?DEFAULT_LIMIT), 1, ?MAX_LIMIT),
            Rows = fh_engine_store:usage_events_since(TenantId, After, Limit),
            Events = [P#{<<"usage_event_id">> => Id} || {Id, P} <- Rows],
            Cursor = case Rows of
                         [] -> After;
                         _  -> element(1, lists:last(Rows))
                     end,
            Body = #{<<"events">> => Events,
                     <<"count">> => length(Events),
                     <<"cursor">> => Cursor},
            {ok, fh_engine_http:reply_json(200, Body, Req0), State};
        {error, Status, Body} ->
            {ok, fh_engine_http:reply_json(Status, Body, Req0), State}
    end.

parse_int(undefined, Default) -> Default;
parse_int(Bin, Default) when is_binary(Bin) ->
    try binary_to_integer(Bin)
    catch _:_ -> Default
    end.

clamp(N, Lo, _Hi) when N < Lo -> Lo;
clamp(N, _Lo, Hi) when N > Hi -> Hi;
clamp(N, _, _) -> N.
