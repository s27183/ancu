-module(fh_engine_fees).
%% Whole lifecycle -> honesty tiers; one owner per fact -> the engine -> the fee lines
%% Purpose:   behavior 83 — every cost a buyer cannot know until they hire someone or
%%            get a quote is a cash event of its own, with its band, who usually pays,
%%            what moves it and its source, for the components that own each phase
%%            (cash_position: buy; ownership_planning: own; disposition: dispose).
%% Holds:     the figures are the KB's: each owning doc's `lookup.fee_lines.entries`
%%            (docs listed in owners/0). An entry is emitted only when it applies to the
%%            plan's blueprint and state; a property-scoped entry (strata / house) is
%%            emitted with its `condition` while the property type is unknown and dropped
%%            once it is known not to apply. A percentage entry whose base is missing
%%            (rent before a property, sale before hold years) is not a figure: it is a
%%            pending line naming that input. A PLACEHOLDER entry (no band) is pending a
%%            quote. Every event is is_estimate unless its tier is REGULATED.
%% Rests on:  the fee_lines shape the owning docs share (behavior 83's Approach).
%% Known gaps: the % of the loan uses the band the caller passes (repayments' principal),
%%            not the buyer's own borrowing capacity.

-export([events/2, owners/0, buy_lines/1, committed/1, property_kind/1, line_band/1]).

%% Ctx: blueprint (binary), state (binary | undefined), property (house | strata |
%% undefined), source (the emitting component id), counterparty (the swimlane actor the
%% fees go to: `other` in modes A/B/E, `services` in C/D), and the bases a percentage
%% entry needs — price, loan, rent (per year), transfer, sale — each a [Lo, Hi] or null.
-type ctx() :: #{atom() => term()}.

%% Every doc that owns fee lines. A doc without a fee_lines lookup contributes none.
-spec owners() -> [binary()].
owners() ->
    [<<"kb.buyer-costs.inspections-conveyancing-fees">>,
     <<"kb.buyer-costs.broker-and-buyers-agent">>,
     <<"kb.buyer-costs.foreign-buyer-services">>,
     <<"kb.fx.typical-spreads-vnd-aud">>,
     <<"kb.investor.operating-expenses-typical-ratios">>,
     <<"kb.ongoing-costs.rates-water-strata">>,
     <<"kb.investor.property-management-fees">>,
     <<"kb.investor.annual-tax-return-investor">>,
     <<"kb.tax.quantity-surveyor-reports">>,
     <<"kb.investor.depreciation-report-quantity-surveyor">>,
     <<"kb.selling-costs.agent-legal">>,
     <<"kb.existing-home-sale.net-proceeds">>].

%% {Events, Pending} for the given phases. Pending: #{id, phase, needs}.
-spec events([binary()], ctx()) -> {[map()], [map()]}.
events(Phases, Ctx) ->
    Entries = [E || E <- all_entries(),
                    lists:member(maps:get(<<"phase">>, E), Phases),
                    applies(E, Ctx)],
    lists:foldr(fun(E, {Es, Ps}) ->
                        case amount(E, Ctx) of
                            {ok, Amount}   -> {[event(E, Amount, Ctx) | Es], Ps};
                            {needs, Input} -> {Es, [pending(E, Input) | Ps]}
                        end
                end, {[], []}, Entries).

%% the acquisition phases' lines (cash_position's share).
-spec buy_lines(ctx()) -> {[map()], [map()]}.
buy_lines(Ctx) ->
    events([<<"prepare">>, <<"pre_approve">>, <<"contract">>, <<"settle">>], Ctx).

%% what a total counts: every line the plan will pay for sure — not an optional one (a
%% buyer's agent) and not one whose property condition is still open. [0, 0] when none.
-spec committed([map()]) -> [integer()].
committed(Events) ->
    Rs = [maps:get(<<"amount">>, E) || E <- Events, counted(maps:get(<<"detail">>, E, #{}))],
    [lists:sum([L || [L, _] <- Rs]), lists:sum([H || [_, H] <- Rs])].

counted(D) ->
    maps:get(<<"optional">>, D, false) =/= true andalso maps:get(<<"condition">>, D, null) =:= null.

%% a property card's type → the fee lines' property scope. Apartments, units and
%% townhouses are usually strata-titled; a house is not. Anything else stays unknown.
-spec property_kind(term()) -> house | strata | undefined.
property_kind(T) when is_binary(T) ->
    case string:lowercase(T) of
        <<"house">>     -> house;
        <<"apartment">> -> strata;
        <<"unit">>      -> strata;
        <<"townhouse">> -> strata;
        _               -> undefined
    end;
property_kind(_) -> undefined.

%% one fee line's [Low, High] by id, for a reader that needs the figure outside a plan's
%% events (existing_home_disposal's discharge fee). null when the line has no band.
-spec line_band(binary()) -> [number()] | null.
line_band(Id) ->
    case [E || E <- all_entries(), maps:get(<<"id">>, E) =:= Id] of
        [E | _] ->
            case {maps:get(<<"low">>, E, null), maps:get(<<"high">>, E, null)} of
                {L, H} when is_number(L), is_number(H) -> [L, H];
                _ -> null
            end;
        [] -> null
    end.

all_entries() ->
    lists:append([entries(Slug) || Slug <- owners()]).

entries(Slug) ->
    case fh_engine_kb:kb_rules(Slug) of
        {ok, Cj} ->
            Lookup = maps:get(<<"lookup">>, Cj, #{}),
            [E#{<<"_owner">> => Slug}
             || E <- maps:get(<<"entries">>, maps:get(<<"fee_lines">>, Lookup, #{}), [])];
        _ -> []
    end.

applies(E, Ctx) ->
    A = maps:get(<<"applies">>, E, #{}),
    lists:member(maps:get(blueprint, Ctx), maps:get(<<"modes">>, A, []))
        andalso state_applies(maps:get(<<"states">>, A, <<"all">>), maps:get(state, Ctx, undefined))
        andalso property_applies(maps:get(<<"property">>, A, <<"any">>),
                                 maps:get(property, Ctx, undefined)).

state_applies(<<"all">>, _) -> true;
state_applies(States, S) when is_list(States), is_binary(S) -> lists:member(S, States);
state_applies(_, _) -> false.     %% a state-limited fee needs the state to be known

property_applies(<<"any">>, _) -> true;
property_applies(_, undefined) -> true;     %% unknown: shown with its condition
property_applies(P, Known) -> P =:= atom_to_binary(Known).

amount(E, Ctx) ->
    case {maps:get(<<"low">>, E, null), maps:get(<<"high">>, E, null)} of
        {L, H} when is_number(L), is_number(H) ->
            case maps:get(<<"basis">>, E, <<"fixed">>) of
                <<"fixed">> -> {ok, [round(L), round(H)]};
                Basis ->
                    {Key, Needs} = base(Basis),
                    case maps:get(Key, Ctx, null) of
                        [BL, BH] when is_number(BL), is_number(BH) ->
                            {ok, [round(BL * L / 100), round(BH * H / 100)]};
                        _ -> {needs, Needs}
                    end
            end;
        _ -> {needs, <<"quote">>}
    end.

base(<<"pct_of_price">>)    -> {price, <<"price">>};
base(<<"pct_of_loan">>)     -> {loan, <<"income">>};
base(<<"pct_of_rent">>)     -> {rent, <<"rent">>};
base(<<"pct_of_transfer">>) -> {transfer, <<"price">>};
base(<<"pct_of_sale">>)     -> {sale, <<"hold_years">>}.

event(E, Amount, Ctx) ->
    Tier = maps:get(<<"tier">>, E, <<"CONVENTION">>),
    PerYear = maps:get(<<"timing">>, E, <<"one_off">>) =:= <<"per_year">>,
    #{<<"id">>               => maps:get(<<"id">>, E),
      <<"phase">>            => maps:get(<<"phase">>, E),
      <<"label">>            => maps:get(<<"label">>, E),
      <<"direction">>        => <<"out">>,
      <<"amount">>           => Amount,
      <<"is_estimate">>      => Tier =/= <<"REGULATED">>,
      <<"timing">>           => case PerYear of true -> <<"recurring">>; false -> <<"one_off">> end,
      <<"period">>           => case PerYear of true -> <<"year">>; false -> null end,
      <<"counterparty">>     => maps:get(counterparty, Ctx, <<"services">>),
      <<"source_component">> => maps:get(source, Ctx),
      <<"group">>            => group(maps:get(<<"phase">>, E)),
      <<"detail">>           => detail(E, Tier, maps:get(property, Ctx, undefined))}.

%% the figure a fee line belongs to, so a link to the old lump (a playbook's budget_ref
%% "other_buying_costs") resolves to the sum of its lines.
group(<<"own">>)     -> null;
group(<<"dispose">>) -> <<"selling_costs">>;
group(_)             -> <<"other_buying_costs">>.

detail(E, Tier, Property) ->
    A = maps:get(<<"applies">>, E, #{}),
    #{<<"tier">>      => Tier,
      <<"basis">>     => maps:get(<<"basis">>, E, <<"fixed">>),
      <<"band">>      => [maps:get(<<"low">>, E, null), maps:get(<<"high">>, E, null)],
      <<"payer">>     => maps:get(<<"payer">>, E, null),
      <<"drivers">>   => maps:get(<<"drivers">>, E, null),
      <<"source">>    => maps:get(<<"source">>, E, null),
      <<"optional">>  => maps:get(<<"optional">>, E, false),
      <<"condition">> => case {maps:get(<<"property">>, A, <<"any">>), Property} of
                             {<<"any">>, _}  -> null;
                             {P, undefined}  -> P;    %% still open: shown as "if <P>"
                             {_, _}          -> null  %% known and it applies
                         end,
      <<"owner">>     => maps:get(<<"_owner">>, E)}.

pending(E, Needs) ->
    #{<<"id">> => maps:get(<<"id">>, E), <<"phase">> => maps:get(<<"phase">>, E),
      <<"needs">> => Needs, <<"label">> => maps:get(<<"label">>, E)}.
