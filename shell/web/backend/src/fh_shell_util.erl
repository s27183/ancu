-module(fh_shell_util).

%% Small shared helpers — a sibling of fh_engine_util. JSON is the OTP 27+ built-in
%% `json` module (no jsx dep); base64url is the JWT segment codec used by BOTH the
%% user JWT (HS256, fh_shell_jwt) and the tenant JWT (ed25519, fh_shell_engine_jwt).

-export([json_encode/1, json_decode/1]).
-export([uuid4/0, is_uuid/1]).
-export([b64url_encode/1, b64url_decode/1]).

-spec json_encode(term()) -> binary().
json_encode(Term) ->
    iolist_to_binary(json:encode(Term)).

-spec json_decode(binary()) -> term().
json_decode(Bin) ->
    json:decode(Bin).

%% RFC 4122 v4 UUID as a lowercase binary string (user_id, magic-token id, etc).
-spec uuid4() -> binary().
uuid4() ->
    <<A:48, _:4, B:12, _:2, C:62>> = crypto:strong_rand_bytes(16),
    <<P1:32, P2:16, P3:16, P4:16, P5:48>> = <<A:48, 4:4, B:12, 2:2, C:62>>,
    iolist_to_binary(io_lib:format(
        "~8.16.0b-~4.16.0b-~4.16.0b-~4.16.0b-~12.16.0b",
        [P1, P2, P3, P4, P5])).

%% Cheap RFC-4122 shape check (8-4-4-4-12 hex). Guards a URL :id binding before it
%% reaches a `$N::uuid` bind — pgo errors on a non-uuid cast — so a malformed id is
%% a calm 404, not a 500. Shape only: NOT a claim the uuid exists or is owned.
-spec is_uuid(binary()) -> boolean().
is_uuid(Bin) when is_binary(Bin) ->
    match =:= re:run(Bin,
        "^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-"
        "[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", [{capture, none}]);
is_uuid(_) -> false.

%% base64url without padding (JWT segments).
-spec b64url_encode(binary()) -> binary().
b64url_encode(Bin) ->
    base64:encode(Bin, #{mode => urlsafe, padding => false}).

-spec b64url_decode(binary()) -> binary().
b64url_decode(Bin) ->
    base64:decode(Bin, #{mode => urlsafe, padding => false}).
