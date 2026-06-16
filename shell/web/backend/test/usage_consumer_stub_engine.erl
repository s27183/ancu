-module(usage_consumer_stub_engine).

%% Stub for the engine's GET /api/engine/usage_events, used by usage_consumer_smoke
%% (8-S5b). The real endpoint (fh_engine_h_usage_events) is proven by the engine's
%% usage_events_smoke; this stub lets the SHELL test exercise only the shell-new logic
%% — the cursor poll, plan_card → user resolution via plan_card_views, the idempotent
%% mirror insert, and the skip of an unknown card — without the dual-`default`-pool
%% clash. It ignores auth (the JWT verification is the engine's, proven elsewhere) and
%% returns a fixed batch of 3 usage events REGARDLESS of `after` (so a second poll
%% re-delivers them, exercising ON CONFLICT idempotency). The `after` it received is
%% stashed in persistent_term so the test can assert the consumer advanced its cursor.

-export([init/2]).

init(Req0, _Opts) ->
    Qs = cowboy_req:parse_qs(Req0),
    After = proplists:get_value(<<"after">>, Qs, <<"0">>),
    persistent_term:put({usage_stub, last_after}, After),
    Card = persistent_term:get({usage_stub, card}),
    User = persistent_term:get({usage_stub, user}),
    Unknown = persistent_term:get({usage_stub, unknown_user}),
    Events = [ ev(1, Card, User, 2005, 2032, 33705, 38491),    % tokens_total 76233
               ev(2, Card, User, 2001, 979, 44018, 12857),     % tokens_total 59855
               ev(3, Card, Unknown, 7, 7, 7, 7) ],            % unknown user -> skipped
    Body = #{<<"events">> => Events, <<"count">> => 3, <<"cursor">> => 3},
    Req = cowboy_req:reply(200, #{<<"content-type">> => <<"application/json">>},
                           fh_shell_util:json_encode(Body), Req0),
    {ok, Req, []}.

ev(Id, Card, User, In, Out, CacheR, CacheC) ->
    #{<<"usage_event_id">> => Id,
      <<"plan_card_id">> => Card,
      <<"user_id">> => User,
      <<"turn_id">> => <<"00000000-0000-4000-8000-00000000000", (integer_to_binary(Id))/binary>>,
      <<"source">> => <<"agent_sdk">>,
      <<"source_detail">> => <<"mortgage_finance">>,
      <<"model">> => <<"claude-opus-4-8">>,
      <<"input_tokens">> => In,
      <<"output_tokens">> => Out,
      <<"cache_read_tokens">> => CacheR,
      <<"cache_creation_tokens">> => CacheC}.
