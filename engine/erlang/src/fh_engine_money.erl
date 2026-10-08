-module(fh_engine_money).

%% Shared money formatting for user-facing outcome notes — extracted from the
%% byte-identical copies that had grown in fh_engine_eligibility and fh_engine_cash
%% (the seam flagged when cash_position landed). Presentation only: a plain grouped
%% "$1,500,000" string. Arithmetic helpers stay with their component (e.g. cash's
%% `dollars/1` round-half-up is tied to the Python cross-language conformance and has
%% a single consumer).

-export([money/1]).

%% Honest-partial -> an honest-partial null carries its reason -> outcome notes -> money string
%% The last clause formats anything that is not an integer with ~p, so money(null) is the
%% binary "$null" (measured 2026-10-08: read this clause). It is the caller that decides a
%% figure is absent and says why; pass money/1 only a known amount. A "$null" in a note once
%% reached the user from fh_engine_ownership (fixed there, :472-476).
%% money as a plain "$1,500,000" string.
-spec money(integer() | number()) -> binary().
money(N) when is_integer(N), N < 0 -> iolist_to_binary([<<"-">>, money(-N)]);
money(N) when is_integer(N) ->
    iolist_to_binary([<<"$">>, group_thousands(integer_to_list(N))]);
money(N) -> iolist_to_binary(io_lib:format("$~p", [N])).

%% "1500000" -> "1,500,000". Chunk the reversed digits into 3s (right-to-left
%% groups), restore each group's order, then join the groups left-to-right.
group_thousands(Digits) ->
    Chunks = chunk3(lists:reverse(Digits)),
    Groups = lists:reverse([lists:reverse(C) || C <- Chunks]),
    lists:flatten(lists:join(",", Groups)).

chunk3([])            -> [];
chunk3([A, B, C | T]) -> [[A, B, C] | chunk3(T)];
chunk3(Rest)          -> [Rest].
