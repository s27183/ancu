-module(login_stub_google).

%% A stub for Google's OAuth token endpoint (https://oauth2.googleapis.com/token),
%% used by login_smoke.escript via the GOOGLE_TOKEN_URL override. It ignores the
%% posted form and returns a well-formed token response whose id_token carries a
%% fixed, email_verified identity — exactly the shape fh_shell_h_auth decodes. This
%% lets the smoke exercise the real exchange -> decode -> upsert -> link path without
%% reaching Google (the live consent screen can't be driven from a test).

-export([init/2, email/0, subject/0]).

email()   -> <<"gmail.user@example.com">>.
subject() -> <<"google-subject-123456">>.

init(Req, State) ->
    IdToken = make_id_token(),
    Body = fh_shell_util:json_encode(#{
        <<"access_token">> => <<"stub-access-token">>,
        <<"token_type">>   => <<"Bearer">>,
        <<"id_token">>     => IdToken
    }),
    Req1 = cowboy_req:reply(200,
        #{<<"content-type">> => <<"application/json">>}, Body, Req),
    {ok, Req1, State}.

%% header.payload.sig — only the payload is read by the handler (signature trusted
%% because, in production, the token comes directly from Google over TLS).
make_id_token() ->
    Header = b64(#{<<"alg">> => <<"RS256">>, <<"typ">> => <<"JWT">>}),
    Payload = b64(#{
        <<"sub">>            => subject(),
        <<"email">>          => email(),
        <<"email_verified">> => true,
        <<"iss">>            => <<"https://accounts.google.com">>
    }),
    <<Header/binary, ".", Payload/binary, ".stub-signature">>.

b64(Map) ->
    fh_shell_util:b64url_encode(fh_shell_util:json_encode(Map)).
