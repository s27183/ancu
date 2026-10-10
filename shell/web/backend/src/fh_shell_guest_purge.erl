-module(fh_shell_guest_purge).
-behaviour(gen_server).

%% Guest plans -> P-5 · Metering, not gating -> The shell backend -> a 7-day guest purge
%% Behavior 45 (Son, 2026-10-10): a guest plan nobody claims is deleted, shell and engine
%% side, 7 days after the guest was made — the notice's promise ("kept for 7 days on our
%% server"). Once at boot (after BOOT_DELAY_MS) and then every GUEST_PURGE_INTERVAL_S
%% (default 3600): list unclaimed guests older than fh_shell_guest:ttl/0, log the counts
%% BEFORE deleting (behavior 45's Irreversible check), then for each guest delete its cards
%% through the engine contract (DELETE /api/engine/plan-cards/:id, P-6 — never the engine
%% DB) and, only when every card is gone (204, or 404 already gone), its users row. A
%% guest whose card delete fails is left whole for the next run. Fail-soft: a run that
%% crashes logs and waits for the next tick; it never takes the shell down.

-export([start_link/0, run/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2]).

-define(BOOT_DELAY_MS, 30000).

-spec start_link() -> {ok, pid()} | {error, term()}.
start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

init([]) ->
    erlang:send_after(?BOOT_DELAY_MS, self(), tick),
    {ok, #{}}.

handle_call(_Msg, _From, State) -> {reply, ignored, State}.
handle_cast(_Msg, State) -> {noreply, State}.

handle_info(tick, State) ->
    try run()
    catch C:E:St -> logger:error("[guest-purge] run failed: ~p:~p ~p", [C, E, St])
    end,
    erlang:send_after(interval_ms(), self(), tick),
    {noreply, State};
handle_info(_Msg, State) ->
    {noreply, State}.

%% One purge pass. Returns {GuestsDeleted, CardsDeleted}.
-spec run() -> {non_neg_integer(), non_neg_integer()}.
run() ->
    Guests = fh_shell_store:expired_guests(fh_shell_guest:ttl()),
    Cards = lists:sum([length(Cs) || {_, Cs} <- Guests]),
    Pruned = fh_shell_store:prune_guest_creates(),
    case Guests of
        [] -> logger:info("[guest-purge] 0 guest(s) past ~Bs; ~B old cap row(s) pruned",
                          [fh_shell_guest:ttl(), Pruned]);
        _  -> logger:notice("[guest-purge] ~B guest(s) past ~Bs holding ~B card(s): deleting; "
                            "~B old cap row(s) pruned",
                            [length(Guests), fh_shell_guest:ttl(), Cards, Pruned])
    end,
    Results = [purge_guest(G, Cs) || {G, Cs} <- Guests],
    Done = [N || {ok, N} <- Results],
    Res = {length(Done), lists:sum(Done)},
    Guests =/= [] andalso
        logger:notice("[guest-purge] deleted ~B guest(s), ~B card(s); ~B left for next run",
                      [element(1, Res), element(2, Res), length(Guests) - length(Done)]),
    Res.

purge_guest(GuestId, Cards) ->
    Statuses = [{C, delete_card(GuestId, C)} || C <- Cards],
    case [S || {_, S} <- Statuses, S =/= 204, S =/= 404] of
        [] ->
            ok = fh_shell_store:delete_guest(GuestId),
            {ok, length(Cards)};
        _ ->
            logger:warning("[guest-purge] guest ~s kept: engine deletes ~p", [GuestId, Statuses]),
            kept
    end.

delete_card(GuestId, CardId) ->
    try fh_shell_engine_client:delete_plan_card(GuestId, CardId)
    catch C:E -> {C, E}
    end.

interval_ms() ->
    S = case os:getenv("GUEST_PURGE_INTERVAL_S") of
            false -> 3600;
            V -> try list_to_integer(V) of N when N >= 60 -> N; _ -> 3600 catch _:_ -> 3600 end
        end,
    S * 1000.
