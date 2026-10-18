-module(fh_shell_h_fx).

%% GET /api/fx — the Reserve Bank of Australia's latest 1 AUD in VND and USD, with the
%% RBA's date and the page it cites (behavior 123; /facts shows it). PUBLIC (no user
%% JWT), like /api/facts: the facts page opens before any sign-in.
%%
%%   200 {"date": "2026-10-16", "rates": {"VND": 17970, "USD": 0.6947},
%%        "source": "https://www.rba.gov.au/statistics/frequency/exchange-rates.html"}
%%        "bank": {"name": "Vietcombank", "time": "2026-10-18T10:10:02+07:00",
%%                 "buy_cash": 17558.08, "buy_transfer": 17735.44, "sell": 18303.86,
%%                 "source": "https://www.vietcombank.com.vn/…"} | null}
%%   404 {"error": "no_rate", "rates": null}   — nothing stored yet and the feed unread
%%
%% `bank` (behavior 130) is a bank's reference price, not a government figure; it is read
%% and kept by fh_shell_vcb, and null when no quote is stored.
%%
%% Unlike its neighbours this handler does not proxy the engine: the rate is not a KB
%% fact and no plan figure uses it, so the shell reads the RBA itself and keeps the rows
%% in its own database (fx_rates, migration 008).

-export([init/2]).
-export([parse/1]).

-define(DEFAULT_FEED, "https://www.rba.gov.au/rss/rss-cb-exchange-rates.xml").
-define(RETRY_SECONDS, 3600).
-define(TIMEOUT_MS, 8000).
-define(CONNECT_TIMEOUT_MS, 4000).
-define(CURRENCIES, [<<"VND">>, <<"USD">>]).

init(Req0, State) ->
    case cowboy_req:method(Req0) of
        <<"GET">> ->
            Req = case current() of
                {ok, Rate} ->
                    %% Behavior 130: Vietcombank's quote rides beside the RBA's rate.
                    fh_shell_http:reply_json(200,
                        Rate#{<<"bank">> => fh_shell_vcb:current()}, Req0);
                none ->
                    fh_shell_http:reply_json(404,
                        #{<<"error">> => <<"no_rate">>, <<"rates">> => null}, Req0);
                {error, _} ->
                    fh_shell_http:reply_json(500,
                        #{<<"error">> => <<"fx_unavailable">>, <<"rates">> => null}, Req0)
            end,
            {ok, Req, State};
        _ ->
            {ok, fh_shell_http:reply_json(405,
                #{<<"error">> => <<"method_not_allowed">>}, Req0), State}
    end.

%% Honest-partial -> P-2 · The database is the single source of truth -> The shell backend -> the RBA's daily AUD rate, the last good one kept
%% /api/fx serves only a row the RBA's feed printed: the newest fx_rates row, read at most
%% once a day — when that row's checked_at is a day old (or there is none), the request
%% reads FH_FX_FEED_URL first. A read that fails (transport, status, or a feed without
%% both VND and USD for one date) writes nothing and the stored row is served with its own
%% date; with no row the reply is 404 no_rate, never a rate from anywhere else. A failed
%% read is not retried for an hour (a node-local timestamp, lost on restart: a retry
%% schedule is not a fact P-2 must keep), and concurrent requests do not read twice — one
%% takes a global lock and the rest serve the stored row. The feed URL is a setting so a
%% dev stack, whose sandbox cannot reach rba.gov.au over TLS, reads a saved copy
%% (test/fixtures/rba-cb-exchange-rates.xml, a reconstruction).
-spec current() -> {ok, map()} | none | {error, term()}.
current() ->
    case newest() of
        {ok, Rate, false} -> {ok, Rate};
        {ok, _Rate, true} -> maybe_refresh(), served();
        none              -> maybe_refresh(), served();
        {error, _} = E    -> E
    end.

served() ->
    case newest() of
        {ok, Rate, _Stale} -> {ok, Rate};
        Other              -> Other
    end.

-spec feed_url() -> string().
feed_url() ->
    case os:getenv("FH_FX_FEED_URL") of
        false -> ?DEFAULT_FEED;
        ""    -> ?DEFAULT_FEED;
        Url   -> Url
    end.

%% --- the stored row ---------------------------------------------------------

-spec newest() -> {ok, map(), boolean()} | none | {error, term()}.
newest() ->
    SQL = <<"SELECT rba_date::text, vnd::text, usd::text, source, "
            "checked_at < now() - interval '1 day' "
            "FROM fx_rates ORDER BY rba_date DESC LIMIT 1">>,
    case pgo:query(SQL, []) of
        #{rows := [{Date, Vnd, Usd, Source, Stale}]} ->
            {ok, #{<<"date">> => Date,
                   <<"rates">> => #{<<"VND">> => json:decode(Vnd),
                                    <<"USD">> => json:decode(Usd)},
                   <<"source">> => Source}, Stale};
        #{rows := []} ->
            none;
        {error, Err} ->
            logger:error("fx_rates read failed: ~p", [Err]),
            {error, Err}
    end.

-spec store(map(), string()) -> ok | {error, term()}.
store(#{date := Date, rates := #{<<"VND">> := Vnd, <<"USD">> := Usd}, source := Source},
      FeedUrl) ->
    SQL = <<"INSERT INTO fx_rates (rba_date, vnd, usd, source, feed_url) "
            "VALUES ($1::text::date, $2::text::numeric, $3::text::numeric, $4, $5) "
            "ON CONFLICT (rba_date) DO UPDATE SET checked_at = now()">>,
    case pgo:query(SQL, [Date, Vnd, Usd, Source, list_to_binary(FeedUrl)]) of
        #{command := insert} -> ok;
        {error, Err} ->
            logger:error("fx_rates write failed: ~p", [Err]),
            {error, Err}
    end.

%% --- reading the feed -------------------------------------------------------

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
                        %% another request may have read the feed while this one waited
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
                {ok, Rate} -> store_rate(Rate, Url);
                {error, _} = E -> E
            end;
        {ok, {{_, Status, _}, _, _}} -> {error, {status, Status}};
        {error, Reason} -> {error, Reason}
    end,
    case Result of
        ok ->
            ok;
        {error, Why} ->
            logger:warning("RBA feed ~s not read, serving the stored rate: ~p", [Url, Why]),
            persistent_term:put({?MODULE, failed_at}, Now)
    end.

store_rate(#{date := Date} = Rate, Url) ->
    case store(Rate, Url) of
        ok -> logger:info("RBA rate for ~s read from ~s", [Date, Url]), ok;
        E  -> E
    end.

%% Parse the RBA's RSS 1.0 + RSS-CB feed (one <item> per currency: cb:targetCurrency,
%% cb:value, cb:period, link) into the VND and USD rates of one date. Exported for
%% test/fx_conformance.escript. SAX, entities refused: the feed is fetched, not trusted.
-spec parse(binary()) -> {ok, #{date := binary(), rates := map(), source := binary()}}
                       | {error, term()}.
parse(Bin) when is_binary(Bin) ->
    Fun = fun sax/3,
    try xmerl_sax_parser:stream(Bin, [{event_fun, Fun},
                                      {event_state, {undefined, undefined, []}},
                                      disallow_entities]) of
        {ok, {_, _, Items}, _Rest} -> pick(lists:reverse(Items));
        Other -> {error, {unparsable, element(1, Other)}}
    catch
        _:Why -> {error, {unparsable, Why}}
    end.

-define(FIELDS, ["targetCurrency", "value", "period", "link"]).

%% State: {CurrentItem | undefined, {Field, Chars} | undefined, Items}
sax({startElement, _, "item", _, _}, _, {_, _, Items}) ->
    {#{}, undefined, Items};
sax({startElement, _, Local, _, _}, _, {Item, _, Items}) when is_map(Item) ->
    case lists:member(Local, ?FIELDS) of
        true  -> {Item, {Local, []}, Items};
        false -> {Item, undefined, Items}
    end;
sax({characters, S}, _, {Item, {Field, Acc}, Items}) ->
    {Item, {Field, [Acc, S]}, Items};
sax({endElement, _, "item", _}, _, {Item, _, Items}) when is_map(Item) ->
    {undefined, undefined, [Item | Items]};
sax({endElement, _, Local, _}, _, {Item, {Local, Acc}, Items}) ->
    Text = string:trim(unicode:characters_to_binary(Acc)),
    {maps:put(Local, Text, Item), undefined, Items};
sax(_, _, State) ->
    State.

pick(Items) ->
    Found = [{C, first_with(C, Items)} || C <- ?CURRENCIES],
    case [C || {C, none} <- Found] of
        [_ | _] = Missing -> {error, {missing, Missing}};
        [] ->
            Rows = [I || {_, I} <- Found],
            case lists:usort([maps:get("period", I, none) || I <- Rows]) of
                [Date] when is_binary(Date) ->
                    validated(Date, Found);
                Dates ->
                    {error, {periods, Dates}}
            end
    end.

first_with(C, Items) ->
    case [I || #{"targetCurrency" := T} = I <- Items, T =:= C] of
        [I | _] -> I;
        []      -> none
    end.

validated(Date, Found) ->
    DateOk = re:run(Date, <<"^[0-9]{4}-[0-9]{2}-[0-9]{2}$">>) =/= nomatch,
    Values = [{C, maps:get("value", I, <<>>)} || {C, I} <- Found],
    Bad = [C || {C, V} <- Values,
                re:run(V, <<"^[0-9]+(\\.[0-9]+)?$">>) =:= nomatch orelse json:decode(V) == 0],
    case {DateOk, Bad} of
        {false, _} -> {error, {bad_period, Date}};
        {true, [_ | _]} -> {error, {bad_value, Bad}};
        {true, []} ->
            {_, First} = hd(Found),
            {ok, #{date => Date,
                   rates => maps:from_list(Values),
                   source => source(maps:get("link", First, <<>>))}}
    end.

%% The page the rate cites: the item's link without its #fragment; the RBA's
%% exchange-rates page when the item has none.
source(<<"https://www.rba.gov.au/", _/binary>> = Link) ->
    hd(binary:split(Link, <<"#">>));
source(_) ->
    <<"https://www.rba.gov.au/statistics/frequency/exchange-rates.html">>.
