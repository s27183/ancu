-module(fh_engine_h_version).

%% GET /api/engine/version — {"kb": <hash>}, the hash of the KB artifact this engine
%% loaded at boot (fh_engine_kb:content_version/0). An open page polls it through the
%% shell's /api/version, a few bytes a minute instead of the ~190 KB of news, facts and
%% terms (measured 2026-10-19 on maiancu.com), and re-fetches those only when it moves
%% (behavior 135). Tenant JWT as /api/engine/news: global KB content, no card scope.

-export([init/2]).

init(Req0, State) ->
    case cowboy_req:method(Req0) of
        <<"GET">> -> handle_get(Req0, State);
        _ ->
            {ok, fh_engine_http:reply_json(405,
                #{<<"error">> => <<"method_not_allowed">>}, Req0), State}
    end.

handle_get(Req0, State) ->
    case fh_engine_http:authenticate(Req0) of
        {ok, _Claims} ->
            {ok, fh_engine_http:reply_json(200,
                #{<<"kb">> => fh_engine_kb:content_version()}, Req0), State};
        {error, Status, Body} ->
            {ok, fh_engine_http:reply_json(Status, Body, Req0), State}
    end.
