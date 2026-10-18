-module(fh_shell_h_version).

%% Regulated figures are grounded -> P-7 -> The shell backend -> an open page learns a deploy replaced the KB (behavior 135)
%% GET /api/version — relays the engine's /api/engine/version ({"kb": <hash>}). PUBLIC,
%% like /api/news: every open page polls it once a minute while visible. `no-store`, so
%% neither the browser nor the Cloudflare Pages Function in front of it answers from a
%% cache and hides a new KB; the engine's own answer is a few bytes.

-export([init/2]).

init(Req0, State) ->
    case cowboy_req:method(Req0) of
        <<"GET">> ->
            {Status, Body} = fh_shell_engine_client:content_version(),
            Req = cowboy_req:reply(Status,
                #{<<"content-type">> => <<"application/json">>,
                  <<"cache-control">> => <<"no-store">>}, Body, Req0),
            {ok, Req, State};
        _ ->
            {ok, fh_shell_http:reply_json(405,
                #{<<"error">> => <<"method_not_allowed">>}, Req0), State}
    end.
