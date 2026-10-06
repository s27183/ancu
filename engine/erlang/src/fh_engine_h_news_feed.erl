-module(fh_engine_h_news_feed).

%% GET /api/engine/news — every compiled KB news note, unfiltered by relevance to any
%% one plan card (kb-news-feature.md "Homepage ticker", 2026-07-08). The per-card
%% GET /api/engine/plan-cards/:id/news (fh_engine_h_news) stays exactly as built —
%% relevance-filtered, dismissable; this is a deliberately DIFFERENT read: the
%% homepage's ambient "what's new in the KB" strip, not a per-buyer alert. No dismiss
%% here — there is no card to retire a note FROM (dismiss is a per-card user-attested
%% fact, migration 007); see kb-news-feature.md for why that's resolved, not deferred.
%%
%% AUTHENTICATE the tenant JWT (a registered shell mints it, same contract as
%% /suburbs), but do NOT scope by tenant or card: news notes are GLOBAL KB content.

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
                #{<<"news">> => fh_engine_kb:all_news()}, Req0), State};
        {error, Status, Body} ->
            {ok, fh_engine_http:reply_json(Status, Body, Req0), State}
    end.
