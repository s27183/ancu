-module(billing_stripe_stub).

%% Stub for Stripe's POST /v1/checkout/sessions, used by billing_checkout_smoke
%% (8-S5e-3). fh_shell_billing:create_checkout_session/2 POSTs here when STRIPE_API_BASE
%% points at this listener (the GOOGLE_TOKEN_URL stub posture). It captures the
%% form-encoded params in persistent_term so the test can assert what we sent, and
%% returns a Checkout Session object with a `url` (the only field we consume).

-export([init/2]).

init(Req0, _Opts) ->
    {ok, KVs, Req1} = cowboy_req:read_urlencoded_body(Req0),
    persistent_term:put({stripe_stub, form}, KVs),
    Body = fh_shell_util:json_encode(
             #{<<"id">> => <<"cs_test_smoke">>,
               <<"url">> => <<"https://checkout.stripe.com/c/pay/cs_test_smoke">>}),
    Req = cowboy_req:reply(200, #{<<"content-type">> => <<"application/json">>}, Body, Req1),
    {ok, Req, []}.
