-module(fh_engine_util).

%% Small shared helpers. JSON is the OTP 27+ built-in `json` module (no jsx dep);
%% these wrappers just pin the binary-in / binary-out shapes the rest of the engine
%% expects (json:encode returns iodata; json:decode returns binary-keyed maps).

-export([json_encode/1, json_decode/1]).
-export([uuid4/0]).
-export([b64url_encode/1, b64url_decode/1]).

-spec json_encode(term()) -> binary().
json_encode(Term) ->
    iolist_to_binary(json:encode(Term)).

-spec json_decode(binary()) -> term().
json_decode(Bin) ->
    json:decode(Bin).

%% RFC 4122 v4 UUID as a lowercase binary string. Used for turn_id (plan_card_id and
%% the rest come from Postgres gen_random_uuid()); a turn is engine-side ephemeral so
%% Erlang mints it.
-spec uuid4() -> binary().
uuid4() ->
    <<A:48, _:4, B:12, _:2, C:62>> = crypto:strong_rand_bytes(16),
    %% version nibble = 4, variant bits = 10
    <<P1:32, P2:16, P3:16, P4:16, P5:48>> = <<A:48, 4:4, B:12, 2:2, C:62>>,
    iolist_to_binary(io_lib:format(
        "~8.16.0b-~4.16.0b-~4.16.0b-~4.16.0b-~12.16.0b",
        [P1, P2, P3, P4, P5])).

%% base64url without padding (JWT segments).
-spec b64url_encode(binary()) -> binary().
b64url_encode(Bin) ->
    base64:encode(Bin, #{mode => urlsafe, padding => false}).

-spec b64url_decode(binary()) -> binary().
b64url_decode(Bin) ->
    base64:decode(Bin, #{mode => urlsafe, padding => false}).
