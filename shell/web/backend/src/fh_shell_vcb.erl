-module(fh_shell_vcb).

%% Vietcombank's AUD buy and sell quote, served by GET /api/fx under `bank` beside the
%% Reserve Bank's rate (behavior 130; /facts shows it as a bank's reference price).

-export([current/0]).
-export([parse/1]).

-define(DEFAULT_FEED, "https://portal.vietcombank.com.vn/Usercontrols/TVPortal.TyGia/pXML.aspx").
-define(SOURCE, <<"https://www.vietcombank.com.vn/vi-VN/KHCN/Cong-cu-tien-ich/Ty-gia">>).
-define(BANK, <<"Vietcombank">>).
-define(RETRY_SECONDS, 3600).
-define(TIMEOUT_MS, 8000).
-define(CONNECT_TIMEOUT_MS, 4000).

%% Honest-partial -> P-2 · The database is the single source of truth -> The shell backend -> Vietcombank's AUD quote, the last good one kept
%% Purpose:   behavior 130 (Son 2026-10-18): a buyer sending money from Vietnam pays a
%%            bank's price, not the RBA's mid rate, so /facts also shows what Vietcombank
%%            buys 1 AUD for (cash, transfer) and sells it for, with the board's time.
%% Holds:     `bank` is only a quote the bank's board printed: the newest fx_bank_quotes
%%            row, the board read at most once an hour — its file asks for no more than one
%%            request in five minutes — when that row's checked_at is an hour old (or there
%%            is none). A read that fails (transport, status, no AUD row, a non-number, no
%%            time) writes nothing and the stored quote is served with its own time; with
%%            no row `bank` is null, never a quote from anywhere else. A failed read waits an
%%            hour (node-local, lost on restart) and concurrent requests read once (a
%%            global lock), as the RBA read does (fh_shell_h_fx). The quote is not a
%%            government figure; the page says whose it is.
%% Rests on:  migration 009 (fx_bank_quotes), httpc, xmerl_sax_parser; FH_VCB_FEED_URL
%%            points a dev stack or a test at another copy of the board.
-spec current() -> map() | null.
current() ->
    case newest() of
        {ok, Quote, false} -> Quote;
        {ok, _, true}      -> maybe_refresh(), served();
        none               -> maybe_refresh(), served();
        {error, _}         -> null
    end.

served() ->
    case newest() of
        {ok, Quote, _} -> Quote;
        _              -> null
    end.

feed_url() ->
    case os:getenv("FH_VCB_FEED_URL") of
        false -> ?DEFAULT_FEED;
        ""    -> ?DEFAULT_FEED;
        Url   -> Url
    end.

%% --- the stored row ---------------------------------------------------------

newest() ->
    SQL = <<"SELECT bank, "
            "to_char(quoted_at AT TIME ZONE 'Asia/Ho_Chi_Minh', 'YYYY-MM-DD\"T\"HH24:MI:SS\"+07:00\"'), "
            "buy_cash::text, buy_transfer::text, sell::text, source, "
            "checked_at < now() - interval '1 hour' "
            "FROM fx_bank_quotes WHERE bank = $1 ORDER BY quoted_at DESC LIMIT 1">>,
    case pgo:query(SQL, [?BANK]) of
        #{rows := [{Bank, Time, BuyCash, BuyTransfer, Sell, Source, Stale}]} ->
            {ok, #{<<"name">> => Bank,
                   <<"time">> => Time,
                   <<"buy_cash">> => json:decode(BuyCash),
                   <<"buy_transfer">> => json:decode(BuyTransfer),
                   <<"sell">> => json:decode(Sell),
                   <<"source">> => Source}, Stale};
        #{rows := []} ->
            none;
        {error, Err} ->
            logger:error("fx_bank_quotes read failed: ~p", [Err]),
            {error, Err}
    end.

store(#{time := Time, buy_cash := BuyCash, buy_transfer := BuyTransfer, sell := Sell}, Url) ->
    SQL = <<"INSERT INTO fx_bank_quotes "
            "(bank, quoted_at, buy_cash, buy_transfer, sell, source, feed_url) "
            "VALUES ($1, $2::text::timestamptz, $3::text::numeric, $4::text::numeric, "
            "$5::text::numeric, $6, $7) "
            "ON CONFLICT (bank, quoted_at) DO UPDATE SET checked_at = now()">>,
    case pgo:query(SQL, [?BANK, Time, BuyCash, BuyTransfer, Sell, ?SOURCE,
                         list_to_binary(Url)]) of
        #{command := insert} -> ok;
        {error, Err} ->
            logger:error("fx_bank_quotes write failed: ~p", [Err]),
            {error, Err}
    end.

%% --- reading the board ------------------------------------------------------

maybe_refresh() ->
    Now = erlang:monotonic_time(second),
    case persistent_term:get({?MODULE, failed_at}, undefined) of
        T when is_integer(T), Now - T < ?RETRY_SECONDS -> ok;
        _ ->
            LockId = {?MODULE, self()},
            case global:set_lock(LockId, [node()], 0) of
                false -> ok;
                true ->
                    try
                        case newest() of
                            {ok, _, false} -> ok;
                            _ -> refresh(Now)
                        end
                    after
                        global:del_lock(LockId, [node()])
                    end
            end
    end.

refresh(Now) ->
    Url = feed_url(),
    Result = case httpc:request(get, {Url, [{"user-agent", "maiancu-shell"}]},
                                [{timeout, ?TIMEOUT_MS},
                                 {connect_timeout, ?CONNECT_TIMEOUT_MS}],
                                [{body_format, binary}]) of
        {ok, {{_, 200, _}, _, Body}} ->
            case parse(Body) of
                {ok, Quote} -> store(Quote, Url);
                {error, _} = E -> E
            end;
        {ok, {{_, Status, _}, _, _}} -> {error, {status, Status}};
        {error, Reason} -> {error, Reason}
    end,
    case Result of
        ok ->
            logger:info("Vietcombank AUD quote read from ~s", [Url]);
        {error, Why} ->
            logger:warning("Vietcombank board ~s not read, serving the stored quote: ~p",
                           [Url, Why]),
            persistent_term:put({?MODULE, failed_at}, Now)
    end.

%% Parse Vietcombank's board (<ExrateList><DateTime>10/18/2026 10:10:02 AM</DateTime>
%% <Exrate CurrencyCode="AUD" Buy="17,558.08" Transfer="17,735.44" Sell="18,303.86"/>…)
%% into the AUD quote and its time as an ISO instant in Vietnam time. Exported for
%% test/fx_conformance.escript. SAX, entities refused: the board is fetched, not trusted.
-spec parse(binary()) -> {ok, #{time := binary(), buy_cash := binary(),
                                buy_transfer := binary(), sell := binary()}}
                       | {error, term()}.
parse(Bin) when is_binary(Bin) ->
    try xmerl_sax_parser:stream(Bin, [{event_fun, fun sax/3},
                                      {event_state, {undefined, undefined, undefined}},
                                      disallow_entities]) of
        {ok, {Time, _, Aud}, _Rest} -> validated(Time, Aud);
        Other -> {error, {unparsable, element(1, Other)}}
    catch
        _:Why -> {error, {unparsable, Why}}
    end.

%% State: {DateTimeText | undefined, Chars | undefined (inside <DateTime>), AudAttrs | undefined}
sax({startElement, _, "DateTime", _, _}, _, {T, _, A}) ->
    {T, [], A};
sax({characters, S}, _, {T, Acc, A}) when is_list(Acc) ->
    {T, [Acc, S], A};
sax({endElement, _, "DateTime", _}, _, {_, Acc, A}) when is_list(Acc) ->
    {string:trim(unicode:characters_to_binary(Acc)), undefined, A};
sax({startElement, _, "Exrate", _, Attrs}, _, {T, C, undefined}) ->
    Got = maps:from_list([{N, unicode:characters_to_binary(V)} || {_, _, N, V} <- Attrs]),
    case maps:get("CurrencyCode", Got, <<>>) of
        <<"AUD">> -> {T, C, Got};
        _         -> {T, C, undefined}
    end;
sax(_, _, State) ->
    State.

validated(undefined, _) -> {error, no_time};
validated(_, undefined) -> {error, {missing, <<"AUD">>}};
validated(Time, Aud) ->
    Nums = [{K, number(maps:get(A, Aud, <<>>))}
            || {K, A} <- [{buy_cash, "Buy"}, {buy_transfer, "Transfer"}, {sell, "Sell"}]],
    case {iso_time(Time), [K || {K, bad} <- Nums]} of
        {bad, _} -> {error, {bad_time, Time}};
        {_, [_ | _] = Bad} -> {error, {bad_value, Bad}};
        {Iso, []} -> {ok, maps:from_list([{time, Iso} | Nums])}
    end.

%% "17,558.08" -> <<"17558.08">>; "-" (no quote), "0" or text -> bad.
number(V) ->
    N = binary:replace(string:trim(V), <<",">>, <<>>, [global]),
    case re:run(N, <<"^[0-9]+(\\.[0-9]+)?$">>) of
        nomatch -> bad;
        _ -> case json:decode(N) == 0 of true -> bad; false -> N end
    end.

%% "10/18/2026 10:10:02 AM" (month/day/year, 12-hour, Vietnam time) ->
%% <<"2026-10-18T10:10:02+07:00">>.
iso_time(T) ->
    case re:run(T, <<"^([0-9]{1,2})/([0-9]{1,2})/([0-9]{4}) ([0-9]{1,2}):([0-9]{2}):([0-9]{2}) (AM|PM)$">>,
                [{capture, all_but_first, binary}]) of
        {match, [Mo, D, Y, H, Mi, S, AmPm]} ->
            H24 = case {binary_to_integer(H), AmPm} of
                {12, <<"AM">>} -> 0;
                {12, <<"PM">>} -> 12;
                {Hh, <<"PM">>} -> Hh + 12;
                {Hh, <<"AM">>} -> Hh
            end,
            Date = {binary_to_integer(Y), binary_to_integer(Mo), binary_to_integer(D)},
            case calendar:valid_date(Date) andalso H24 < 24 of
                true ->
                    {Yy, Mm, Dd} = Date,
                    iolist_to_binary(io_lib:format("~4..0B-~2..0B-~2..0BT~2..0B:~s:~s+07:00",
                                                   [Yy, Mm, Dd, H24, Mi, S]));
                false -> bad
            end;
        _ -> bad
    end.
