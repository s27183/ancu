-module(fh_engine_lmi).

%% Regulated figures are grounded -> lenders mortgage insurance is the KB's indicative band
%%   -> fh_engine_lmi -> one premium for a loan at an LVR (behavior 101)
%% Purpose:   the LMI a buyer pays when the deposit is under 20% of the price and no scheme
%%            waives it (the FHG on its fhg_backed path), and the LMI the FHG avoids — one
%%            computer for cash_position's `lmi` line and eligibility's FHG benefit.
%% Holds:     kb.lmi.calculation alone: LMI above lvr_threshold_pct (80); the premium is the
%%            band's [low %, high %] of the loan for the LVR's band (81-85, 86-90, 91-95),
%%            each end floored at min_premium_aud_qbe. INDICATIVE — the insurer quotes the
%%            binding premium; the doc says so and the line detail repeats it.
%% Measured:  2026-10-16, the compiled artifact: bands 0.5-1.0 / 1.5-2.0 / 2.5-4.0, minimum
%%            1150. An LVR above 95 has no band (no lender lends there at base): none.

-export([premium/2, lvr/2, rates/1, threshold/0]).

-define(SLUG, <<"kb.lmi.calculation">>).

%% the premium for Loan on a home worth Price: [Lo, Hi], or none at or below the threshold
%% (or with no loan).
-spec premium(number(), number()) -> [integer()] | none.
premium(Loan, Price) when is_number(Loan), is_number(Price), Loan > 0, Price > 0 ->
    case rates(lvr(Loan, Price)) of
        none -> none;
        {RateLo, RateHi} ->
            Min = min_premium(),
            [erlang:max(Min, round(RateLo / 100 * Loan)),
             erlang:max(Min, round(RateHi / 100 * Loan))]
    end;
premium(_Loan, _Price) -> none.

%% the loan-to-value ratio in percent, rounded up to a whole percent (a 90.2% LVR is in
%% the 91-95 band, as an insurer reads it).
-spec lvr(number(), number()) -> integer().
lvr(Loan, Price) -> ceil_int(Loan * 100 / Price).

%% the KB band rates for an LVR: {LowPct, HighPct}, or none at or under the threshold or
%% above the top band.
-spec rates(integer()) -> {number(), number()} | none.
rates(Lvr) ->
    case Lvr =< threshold() of
        true -> none;
        false ->
            Pick = [E || E <- entries(), in_band(Lvr, maps:get(<<"lvr_band">>, E))],
            case Pick of
                [E | _] -> {maps:get(<<"indicative_rate_pct_of_loan_low">>, E),
                            maps:get(<<"indicative_rate_pct_of_loan_high">>, E)};
                [] -> none
            end
    end.

-spec threshold() -> number().
threshold() -> param(<<"lvr_threshold_pct">>).

in_band(Lvr, Band) ->
    [Lo, Hi] = [binary_to_integer(B) || B <- binary:split(Band, <<"-">>)],
    Lvr >= Lo andalso Lvr =< Hi.

entries() ->
    {ok, Cj} = fh_engine_kb:kb_rules(?SLUG),
    maps:get(<<"entries">>,
             maps:get(<<"indicative_premium_by_lvr_band">>, maps:get(<<"lookup">>, Cj))).

min_premium() -> param(<<"min_premium_aud_qbe">>).

param(Name) ->
    {ok, Cj} = fh_engine_kb:kb_rules(?SLUG),
    maps:get(<<"value">>, maps:get(Name, maps:get(<<"parameters">>, Cj))).

ceil_int(X) ->
    T = trunc(X),
    case X > T of true -> T + 1; false -> T end.
