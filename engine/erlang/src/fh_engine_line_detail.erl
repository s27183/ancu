-module(fh_engine_line_detail).
%% Whole lifecycle -> honesty tiers; one owner per fact -> the engine -> every line's detail
%% Purpose:   behavior 93 — every line of the lifecycle statement opens its own detail in
%%            place (what it is, how its figure is set, who pays, what moves it, its source),
%%            the fee lines' shape (fh_engine_fees, behavior 83) given to the lines that are
%%            not fees: the deposit, duty, registration, the foreign-buyer surcharge, the FIRB
%%            fee, a grant, LMI, the yearly own lines, the sale price, the loan payout, CGT.
%% Holds:     the words are the KB's: each line's entry sits in the doc that owns its figure
%%            (`lookup.line_details.entries`), named at the call site that places the figure
%%            — one owner per figure. `how` is filled with the figures the caller computed
%%            with (never another computer); `source` is an index into that doc's own
%%            `sources:` (by state where the source is a state's), so a detail can only cite
%%            what the doc cites, and a doc with no source for the plan's state gives none.
%%            A missing entry crashes (fail-closed, like fh_engine_kb:copy/2). An entry's
%%            `explains` names the components whose detail the line opens (behavior 95:
%%            the FIRB fee opens FIRB), as the fee lines' entries do.
%% Rests on:  the compiler's line_details gate (kb_compiler.py) — bilingual text, a known
%%            tier, every source index inside the doc's `sources:`.

-export([attach/4, attach_all/2, detail/3, beside/3, pct/1, pct_range/1, price/2, money_range/1]).

%% Ctx: state (binary | undefined) and params (#{binary() => fh_engine_i18n:param()}).
-type ctx() :: #{state => binary() | undefined, params => map()}.

%% the event with its detail; an event whose figure is unknown (amount null) is returned
%% as is — its caller drops it.
-spec attach(map(), binary(), binary(), ctx()) -> map().
attach(#{<<"amount">> := null} = Event, _Slug, _Id, _Ctx) -> Event;
attach(Event, Slug, Id, Ctx) -> Event#{<<"detail">> => detail(Slug, Id, Ctx)}.

%% every event whose id the spec names, given its detail; a fee line (which carries its
%% own, fh_engine_fees) and an id the spec does not name are left as they are.
-spec attach_all([map()], #{binary() => {binary(), binary(), ctx()}}) -> [map()].
attach_all(Events, Spec) ->
    [case {maps:is_key(<<"detail">>, E), maps:find(maps:get(<<"id">>, E), Spec)} of
         {false, {ok, {Slug, Id, Ctx}}} -> attach(E, Slug, Id, Ctx);
         _ -> E
     end || E <- Events].

%% the price a line was computed at, said as what it is: the top of the plan's price range
%% (ceiling) or the attached property's price (property). kb.copy.cash holds the words.
-spec price(ceiling | property, number()) -> fh_engine_i18n:localized().
price(Basis, V) ->
    Id = case Basis of ceiling -> <<"price_at_ceiling">>; property -> <<"price_of_property">> end,
    fh_engine_i18n:subst(fh_engine_kb:copy(<<"kb.copy.cash">>, Id),
                         #{<<"money">> => fh_engine_money:money(round(V))}).

%% a [lo, hi] money band as one phrase: "$570,000–$760,000", or one figure when lo = hi.
-spec money_range([number()]) -> binary().
money_range([V, V]) -> fh_engine_money:money(round(V));
money_range([Lo, Hi]) ->
    <<(fh_engine_money:money(round(Lo)))/binary, "–"/utf8, (fh_engine_money:money(round(Hi)))/binary>>.

-spec detail(binary(), binary(), ctx()) -> map().
detail(Slug, Id, Ctx) ->
    {Entry, Sources} = entry(Slug, Id),
    Params = maps:get(params, Ctx, #{}),
    #{<<"tier">>      => maps:get(<<"tier">>, Entry),
      <<"basis">>     => <<"fixed">>,
      <<"band">>      => [null, null],
      <<"how">>       => fh_engine_i18n:subst(maps:get(<<"how">>, Entry), Params),
      <<"payer">>     => maps:get(<<"payer">>, Entry, null),
      <<"drivers">>   => maps:get(<<"drivers">>, Entry, null),
      <<"note">>      => maps:get(<<"note">>, Entry, null),
      <<"source">>    => source(maps:get(<<"source">>, Entry, null), Sources,
                                maps:get(state, Ctx, undefined)),
      <<"optional">>  => false,
      <<"condition">> => null,
      <<"explains">>  => maps:get(<<"explains">>, Entry, []),
      <<"owner">>     => Slug}.

%% Whole lifecycle -> "information as is, not advice" -> the engine -> a line beside the totals
%% Goal: behavior 95 — where the money comes from (a foreign buyer's "Nguồn tiền") and what
%% the home earns (an investor's "Tiền thuê thu về") sit on the statement after a sheet's
%% divider, opening the details they explain, never summed: the bottom line stays what
%% you pay.
%% Invariant: its label and detail are the KB entry of the doc that owns the figure; its
%% amount is the owning outcome's own figure or null, and a null amount names its input.
%% Capability: one line {id, phase, label, amount, needs, timing, detail}.
-spec beside(binary(), binary(), {binary(), [number()] | null, binary() | null, binary()}) -> map().
beside(Slug, Id, {Phase, Amount, Needs, Timing}) ->
    {Entry, _} = entry(Slug, Id),
    #{<<"id">>     => Id,
      <<"phase">>  => Phase,
      <<"label">>  => maps:get(<<"label">>, Entry),
      <<"amount">> => Amount,
      <<"needs">>  => Needs,
      <<"timing">> => Timing,
      <<"detail">> => detail(Slug, Id, #{})}.

%% a percentage as both languages write it: 6 → "6", 6.35 → "6.35" / "6,35".
-spec pct(number()) -> fh_engine_i18n:localized().
pct(N) when is_integer(N) -> #{<<"vi">> => integer_to_binary(N), <<"en">> => integer_to_binary(N)};
pct(N) when is_float(N), N == trunc(N) -> pct(trunc(N));
pct(N) when is_float(N) ->
    En = float_to_binary(N, [{decimals, 2}, compact]),
    #{<<"vi">> => binary:replace(En, <<".">>, <<",">>), <<"en">> => En}.

%% a [low, high] rate band (behavior 98: a foreign buyer's rate carries the non-resident
%% premium band): one figure when the ends meet, else "6.5–7.5" / "6,5–7,5".
-spec pct_range([number()]) -> fh_engine_i18n:localized().
pct_range([Lo, Hi]) when Lo == Hi -> pct(Lo);
pct_range([Lo, Hi]) ->
    #{<<"vi">> := VLo, <<"en">> := ELo} = pct(Lo),
    #{<<"vi">> := VHi, <<"en">> := EHi} = pct(Hi),
    #{<<"vi">> => <<VLo/binary, "–"/utf8, VHi/binary>>, <<"en">> => <<ELo/binary, "–"/utf8, EHi/binary>>}.

entry(Slug, Id) ->
    {ok, Kb} = fh_engine_kb:kb(Slug),
    Lookup = maps:get(<<"lookup">>, maps:get(<<"content_json">>, Kb, #{}), #{}),
    Entries = maps:get(<<"entries">>, maps:get(<<"line_details">>, Lookup, #{}), []),
    case [E || E <- Entries, maps:get(<<"id">>, E) =:= Id] of
        [E | _] -> {E, maps:get(<<"sources">>, Kb, [])};
        []      -> error({line_detail_not_found, Slug, Id})
    end.

%% an index into the doc's sources, or a state → index map (a state the doc cites no
%% source for gives none).
source(null, _Sources, _State) -> null;
source(I, Sources, _State) when is_integer(I) -> url(I, Sources);
source(ByState, Sources, State) when is_map(ByState), is_binary(State) ->
    case maps:get(State, ByState, null) of
        I when is_integer(I) -> url(I, Sources);
        _ -> null
    end;
source(_, _, _) -> null.

url(I, Sources) when I >= 0, I < length(Sources) ->
    maps:get(<<"url">>, lists:nth(I + 1, Sources), null);
url(_, _) -> null.
