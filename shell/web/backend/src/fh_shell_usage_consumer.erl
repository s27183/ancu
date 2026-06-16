-module(fh_shell_usage_consumer).

-behaviour(gen_server).

%% Shell-side pull-model outbox consumer (billing.md §2/§6, engine-contract §9).
%% Polls GET /api/engine/usage_events?after=<cursor> every POLL_MS and writes one
%% idempotent usage_records row per engine `usage` event. Borrowed from aleap's
%% aleap_shell_usage_consumer and RESHAPED for FirstHomey's subscription model
%% (billing.md §3): this is a MIRROR, not a debit ledger — it accumulates token facts;
%% the period meter is an AGGREGATE over usage_records (8-S5c/d), no balance is moved
%% here, no money is touched (commerce + ASIC stay out of this loop, principle 5).
%%
%% User attribution: the engine `usage` event carries `user_id` (engine-contract §9 —
%% the acting user from the turn's JWT; == the card owner under the 8-S4a ownership
%% gate in Wedge 1a). The consumer attributes directly to it, skipping an event whose
%% user is unknown to the shell (defensive — the FK to users would reject it anyway).
%%
%% Cursor: the in-memory high-water mark is the highest engine_event_id we have
%% advanced past; bootstrap from MAX(engine_event_id) in usage_records (0 on a fresh
%% DB), floored by USAGE_CONSUMER_START_CURSOR for a forward-seeded cutover. NO
%% separate cursor table — the mirror is the cursor's durable home. Replay-safe: the
%% ON CONFLICT (engine_event_id) DO NOTHING makes a re-seen event a no-op.
%%
%% Failure handling: HTTP/DB errors log + retry on the next tick; the consumer never
%% crashes the node. If it does, the supervisor restarts it and the cursor reseeds.
%%
%% shadow_cost is valued at insert by fh_shell_pricing (8-S5c — §4 Opus ceiling rates;
%% dashboard/margin only, the enforced quota is tokens §3); a booked row invalidates the
%% user's fh_shell_meter cache (§6). admin-exemption is still deferred: billed defaults
%% true until 8-S5e adds the ADMIN_EMAILS allowlist.

-export([start_link/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).

%% Ops / test surface: drive one poll synchronously, read the cursor.
-export([poll_now/0, cursor/0]).

-define(SERVER, ?MODULE).
-define(DEFAULT_POLL_MS, 5000).
-define(DEFAULT_BATCH, 200).

-record(state, {
    cursor    = 0 :: integer(),
    poll_ms       :: integer(),
    batch         :: integer(),
    timer_ref     :: reference() | undefined
}).

%% ── API ─────────────────────────────────────────────────────────────────────

-spec start_link() -> {ok, pid()} | ignore | {error, term()}.
start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

%% Trigger one poll synchronously (smoke tests / manual ops). Returns the cursor after.
-spec poll_now() -> integer().
poll_now() ->
    gen_server:call(?SERVER, poll_now, 30000).

-spec cursor() -> integer().
cursor() ->
    gen_server:call(?SERVER, cursor, 5000).

%% ── gen_server ──────────────────────────────────────────────────────────────

init([]) ->
    process_flag(trap_exit, true),
    PollMs = env_int("USAGE_CONSUMER_POLL_MS", ?DEFAULT_POLL_MS),
    Batch = env_int("USAGE_CONSUMER_BATCH", ?DEFAULT_BATCH),
    Cursor = bootstrap_cursor(),
    logger:info("[usage-consumer] start cursor=~p poll_ms=~p batch=~p",
                [Cursor, PollMs, Batch]),
    Tref = schedule_tick(PollMs),
    {ok, #state{cursor = Cursor, poll_ms = PollMs, batch = Batch, timer_ref = Tref}}.

handle_call(poll_now, _From, State) ->
    State1 = do_poll(State),
    {reply, State1#state.cursor, State1};
handle_call(cursor, _From, State) ->
    {reply, State#state.cursor, State};
handle_call(_Req, _From, State) ->
    {reply, {error, unsupported}, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(tick, State) ->
    State1 = do_poll(State),
    Tref = schedule_tick(State1#state.poll_ms),
    {noreply, State1#state{timer_ref = Tref}};
handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) -> ok.
code_change(_, State, _) -> {ok, State}.

%% ── Internal ────────────────────────────────────────────────────────────────

schedule_tick(Ms) ->
    erlang:send_after(Ms, self(), tick).

do_poll(#state{cursor = Cursor, batch = Batch} = State) ->
    case fh_shell_engine_client:get_usage_events(Cursor, Batch) of
        {ok, #{<<"events">> := Events}} ->
            ProcessedTo = process_events(Events, Cursor),
            State#state{cursor = ProcessedTo};
        {ok, Other} ->
            logger:warning("[usage-consumer] unexpected response: ~p", [Other]),
            State;
        {error, Reason} ->
            logger:warning("[usage-consumer] poll failed: ~p (cursor=~p)",
                           [Reason, Cursor]),
            State
    end.

%% Process events in order; return the highest engine_event_id seen (advanced past
%% even when skipped/failed — a skip is durable, re-fetching it each tick is waste;
%% on restart the cursor reseeds from the mirror's MAX, so a skipped event may be
%% re-seen once and re-skipped, which is harmless).
process_events([], Acc) -> Acc;
process_events([Ev | Rest], Acc) ->
    Id = maps:get(<<"usage_event_id">>, Ev, Acc),
    _ = handle_event(Ev),
    process_events(Rest, max(Id, Acc)).

handle_event(#{<<"usage_event_id">> := Id, <<"user_id">> := UserId} = Ev)
  when is_binary(UserId) ->
    case user_email(UserId) of
        {ok, Email} -> book_usage(Id, UserId, Email, Ev);
        not_found ->
            logger:debug("[usage-consumer] unknown user_id=~s (skip usage_event_id=~p)",
                         [UserId, Id]),
            {skip, unknown_user}
    end;
handle_event(Ev) ->
    logger:warning("[usage-consumer] malformed usage event: ~p", [Ev]),
    {skip, malformed}.

%% The shell user's email for this usage event's user_id, or not_found. The user_id is
%% the acting user from the engine JWT; it should already exist in the shell (it
%% authenticated here). A not_found is skipped — the usage_records FK to users would
%% reject it anyway. The email is needed to test the ADMIN_EMAILS allowlist (§9): an
%% admin's row books billed = false (attribution without charge). A DB error is treated
%% as not_found (fail-soft — the event re-fetches next tick; never crash the consumer).
user_email(UserId) ->
    case pgo:query(<<"SELECT email FROM users WHERE user_id = $1::uuid">>, [UserId]) of
        #{rows := [{Email} | _]} -> {ok, Email};
        #{rows := []}            -> not_found;
        {error, Reason} ->
            logger:warning("[usage-consumer] user_email(~s) failed: ~p", [UserId, Reason]),
            not_found
    end.

%% Mirror one usage event into usage_records, idempotently. tokens_total is the
%% metered unit = the sum of the four token slices (billing.md §3); shadow_cost is the
%% §4 Opus-rate valuation (fh_shell_pricing, 8-S5c — dashboard/margin only, the enforced
%% quota is tokens). billed = false for an admin (ADMIN_EMAILS allowlist, billing.md §9:
%% an admin's turns meter normally — cost is real, kept for attribution — but are not
%% charged); a non-admin (the common case) is billed true. After a row actually lands,
%% the user's period meter cache is invalidated (billing.md §6) so the next gate read
%% reflects this turn immediately.
book_usage(Id, UserId, Email, Ev) ->
    In = int(maps:get(<<"input_tokens">>, Ev, 0)),
    Out = int(maps:get(<<"output_tokens">>, Ev, 0)),
    CacheR = int(maps:get(<<"cache_read_tokens">>, Ev, 0)),
    CacheC = int(maps:get(<<"cache_creation_tokens">>, Ev, 0)),
    Total = In + Out + CacheR + CacheC,
    Shadow = fh_shell_pricing:shadow_cost(In, Out, CacheR, CacheC),
    Source = bin_or_null(maps:get(<<"source">>, Ev, null)),
    Model = bin_or_null(maps:get(<<"model">>, Ev, null)),
    PlanCardId = bin_or_null(maps:get(<<"plan_card_id">>, Ev, null)),
    TurnId = bin_or_null(maps:get(<<"turn_id">>, Ev, null)),
    Billed = not fh_shell_billing:is_admin(Email),
    SQL = <<"INSERT INTO usage_records "
            "(user_id, engine_event_id, plan_card_id, turn_id, source, model, "
            " input_tokens, output_tokens, cache_read_tokens, cache_creation_tokens, "
            " tokens_total, shadow_cost, billed) "
            "VALUES ($1::uuid, $2, $3::uuid, $4::uuid, $5, $6, $7, $8, $9, $10, $11, $12, $13) "
            "ON CONFLICT (engine_event_id) DO NOTHING">>,
    Params = [UserId, Id, PlanCardId, TurnId, Source, Model,
              In, Out, CacheR, CacheC, Total, Shadow, Billed],
    case pgo:query(SQL, Params) of
        #{command := insert, num_rows := N} when N >= 1 ->
            fh_shell_meter:invalidate(UserId),
            ok;
        #{command := insert} ->
            ok;   % ON CONFLICT DO NOTHING — replay, no new row, no cache churn
        {error, Reason} ->
            logger:warning("[usage-consumer] book usage_event_id=~p failed: ~p",
                           [Id, Reason]),
            {error, Reason}
    end.

%% Bootstrap the cursor from the mirror (no separate cursor table), floored by the
%% optional forward-seed env. Fresh DB → MAX is 0 → walk from the start.
bootstrap_cursor() ->
    max(mirror_max(), env_int("USAGE_CONSUMER_START_CURSOR", 0)).

mirror_max() ->
    case pgo:query(<<"SELECT COALESCE(MAX(engine_event_id), 0) FROM usage_records">>,
                   []) of
        #{rows := [{Max}]} when is_integer(Max) -> Max;
        _ -> 0
    end.

%% --- small helpers ---

int(N) when is_integer(N) -> N;
int(N) when is_float(N)   -> trunc(N);
int(_)                    -> 0.

bin_or_null(B) when is_binary(B) -> B;
bin_or_null(_)                   -> null.

env_int(Name, Default) ->
    case os:getenv(Name) of
        false -> Default;
        ""    -> Default;
        Str   -> try list_to_integer(Str) catch error:badarg -> Default end
    end.
