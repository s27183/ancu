-module(fh_engine_kb).

%% The compiled KB + blueprint artifact, loaded into persistent_term at boot.
%%
%% engine-contract §9.1: KB + blueprints are NOT Postgres tables. They are
%% git-authored (docs/kb, docs/blueprints), compiled by the offline build agent
%% (engine/build/kb_compiler.py) into a versioned artifact (priv/kb/artifact.json),
%% and loaded into memory at deploy. Git is SOT; the artifact is a deterministic,
%% rebuildable projection. The engine is the SOLE reader — all KB/blueprint access
%% goes through these accessors, never a direct file read elsewhere.
%%
%% persistent_term is the right home: set-once-at-boot, read-mostly, large, and
%% shared by every turn's gen_statem. No copy-on-read, no gen_server bottleneck,
%% no runtime writes. (If a deploy ever needs hot-reload, that is an explicit
%% persistent_term:put/2 with the known global-GC cost — not a runtime path.)
%%
%% FAIL-CLOSED at boot (matching fh_engine_migrations): the engine cannot plan
%% without its rules + blueprints, so an unreadable/undecodable artifact aborts
%% boot rather than serving a runtime that would silently fail every turn.

-export([load/0, load/1]).
-export([schema_version/0, in_scope_blueprints/0, locales/0]).
-export([blueprint/1, components/1, component/2, ui_tabs/1]).
-export([kb/1, kb_content_md/1, kb_rules/1, kb_anchors/1, copy/2]).
-export([rules/0]).
-export([registry/1, registry/2]).
-export([news_for_slugs/1, all_news/0]).

-define(PT_KEY, {?MODULE, artifact}).

%% --- load -------------------------------------------------------------------

-spec load() -> ok.
load() ->
    load(default_path()).

-spec load(file:filename_all()) -> ok.
load(Path) ->
    case file:read_file(Path) of
        {ok, Bin} ->
            Artifact = fh_engine_util:json_decode(Bin),
            persistent_term:put(?PT_KEY, Artifact),
            #{<<"kb">> := Kb, <<"blueprints">> := Bps} = Artifact,
            logger:info("KB artifact loaded from ~s: ~p KB entries, ~p blueprints, "
                        "schema_version ~p, in_scope=~p",
                        [Path, map_size(Kb), map_size(Bps),
                         schema_version(), in_scope_blueprints()]),
            ok;
        {error, Reason} ->
            logger:error("KB artifact unreadable at ~s: ~p — engine cannot boot "
                         "without its compiled rules + blueprints", [Path, Reason]),
            error({kb_artifact_unreadable, Path, Reason})
    end.

default_path() ->
    filename:join([code:priv_dir(fh_engine), "kb", "artifact.json"]).

%% --- top-level accessors ----------------------------------------------------

-spec schema_version() -> integer().
schema_version() ->
    maps:get(<<"schema_version">>, artifact()).

%% The in-scope SET of blueprints (engine-contract §9.1): every blueprint whose
%% registry is materialized + emitted. The runtime selects the card's blueprint
%% from this set; modes coexist. (Bare stems, the form blueprint/1 qualifies.)
-spec in_scope_blueprints() -> [binary()].
in_scope_blueprints() ->
    maps:get(<<"in_scope_blueprints">>, artifact()).

%% The required locale set, the single SOT for outcome conformance (the seam
%% validate/2), the compiler copy-gate, and the shell display picker — carried in the
%% artifact (git is SOT). Adding a locale touches the compiler's LOCALES and this value.
-spec locales() -> [binary()].
locales() ->
    maps:get(<<"locales">>, artifact()).

%% --- blueprint accessors ----------------------------------------------------
%% Slugs accepted bare ("fhb-domestic-au") or fully-qualified
%% ("blueprints.fhb-domestic-au"); the artifact keys are fully-qualified.

-spec blueprint(binary()) -> {ok, map()} | {error, {blueprint_not_found, binary()}}.
blueprint(Slug) ->
    Bps = maps:get(<<"blueprints">>, artifact()),
    Key = qualify(<<"blueprints">>, Slug),
    case maps:find(Key, Bps) of
        {ok, Bp} -> {ok, Bp};
        error    -> {error, {blueprint_not_found, Slug}}
    end.

-spec components(binary()) -> {ok, [map()]} | {error, term()}.
components(Slug) ->
    case blueprint(Slug) of
        {ok, Bp} -> {ok, maps:get(<<"components">>, Bp)};
        Err      -> Err
    end.

%% The blueprint's ordered lifecycle-tab declaration (plan-card-lifecycle-restoration.md
%% §3) — the shell renders these tabs, not the raw component list. Missing on an older
%% artifact => [] (the shell falls back to its component order), never a crash.
-spec ui_tabs(binary()) -> {ok, [map()]} | {error, term()}.
ui_tabs(Slug) ->
    case blueprint(Slug) of
        {ok, Bp} -> {ok, maps:get(<<"ui_tabs">>, Bp, [])};
        Err      -> Err
    end.

-spec component(binary(), binary()) ->
    {ok, map()} | {error, {component_not_found, binary()}} | {error, term()}.
component(Slug, Name) ->
    case components(Slug) of
        {ok, Comps} ->
            case lists:search(fun(C) -> maps:get(<<"name">>, C) =:= Name end, Comps) of
                {value, C} -> {ok, C};
                false      -> {error, {component_not_found, Name}}
            end;
        Err -> Err
    end.

%% --- KB accessors -----------------------------------------------------------
%% A KB entry is {content_md, content_json, effective_from, last_verified}
%% (engine-contract §9.1). Slugs accepted bare or "kb."-qualified.

-spec kb(binary()) -> {ok, map()} | {error, {kb_not_found, binary()}}.
kb(Slug) ->
    Kb = maps:get(<<"kb">>, artifact()),
    Key = qualify(<<"kb">>, Slug),
    case maps:find(Key, Kb) of
        {ok, Entry} -> {ok, Entry};
        error       -> {error, {kb_not_found, Slug}}
    end.

%% Prose body — injected into the leaf-fill scaffold's <kb> block (agentic-flow §6).
-spec kb_content_md(binary()) -> {ok, binary()} | {error, term()}.
kb_content_md(Slug) ->
    case kb(Slug) of
        {ok, E} -> {ok, maps:get(<<"content_md">>, E)};
        Err     -> Err
    end.

%% Evaluable rules — read directly by the resolver (agentic-flow §6: rules engine,
%% no prompt). The shape is the compiler's content_json (fills/criteria/lookup/...).
-spec kb_rules(binary()) -> {ok, map()} | {error, term()}.
kb_rules(Slug) ->
    case kb(Slug) of
        {ok, E} -> {ok, maps:get(<<"content_json">>, E, #{})};
        Err     -> Err
    end.

%% A bilingual copy-template: content_json.copy[TemplateId] -> {vi, en} pair with
%% `{param}` placeholders (bilingual-content.md §3b). The resolver pairs this with
%% fh_engine_i18n:subst/2 to produce user-facing {vi, en} content WITHOUT any Vietnamese
%% literal in Erlang (which would crash io:format ~s on its >255 codepoints). A missing
%% template is a build error — crash loudly (fail-closed), do not silently English-only.
-spec copy(binary(), binary()) -> fh_engine_i18n:localized().
copy(Slug, TemplateId) ->
    {ok, Cj} = kb_rules(Slug),
    case maps:find(TemplateId, maps:get(<<"copy">>, Cj, #{})) of
        {ok, Template} -> Template;
        error          -> error({kb_copy_not_found, Slug, TemplateId})
    end.

%% The kb_versions audit snapshot for a fill: slug -> {effective_from, last_verified}.
-spec kb_anchors([binary()]) -> [map()].
kb_anchors(Slugs) ->
    lists:filtermap(
        fun(Slug) ->
            case kb(Slug) of
                {ok, E} ->
                    {true, #{<<"slug">> => qualify(<<"kb">>, Slug),
                             <<"effective_from">> => maps:get(<<"effective_from">>, E),
                             <<"last_verified">> => maps:get(<<"last_verified">>, E)}};
                {error, _} -> false
            end
        end, Slugs).

%% --- news accessors ----------------------------------------------------------
%% A news entry: {kb_slug, affected_kb_slugs, affected_components, effective_from,
%% authored_date, sources, summary_en, summary_vi, diff} (kb-update-runbook.md
%% "authoring a news note"). affected_components ({blueprint_slug: [component_name,
%% ...]}) is reverse-indexed at compile time from Component.anchors
%% (kb-news-feature.md "Resolved design questions") — read-only pass-through here,
%% never re-derived at runtime. `sources` (GATE 11, fail-closed) pins the citation
%% the author had open for this specific dated diff — distinct from a fact doc's
%% own `sources:`, which tracks that doc's next re-verify; a news note is
%% immutable so its sources never go stale. Never anchored by a blueprint.
%% `maps:get(..., #{})` defaults so an older artifact predating this key reads as
%% "no news", never a crash (the ui_tabs missing-key posture).

%% News items relevant to a set of KB slugs a card has actually consulted (its
%% accumulated kb_versions across fills, plan-card-refresh.md) — the relevance
%% filter is a set intersection over affected_kb_slugs; no new lookup, the
%% provenance already exists. The caller (the news handler) subtracts the
%% card's dismissed set before replying.
-spec news_for_slugs([binary()]) -> [map()].
news_for_slugs(Slugs) ->
    SlugSet = sets:from_list(Slugs),
    News = maps:get(<<"news">>, artifact(), #{}),
    maps:fold(
        fun(NewsSlug, Entry, Acc) ->
            Affected = maps:get(<<"affected_kb_slugs">>, Entry, []),
            case lists:any(fun(S) -> sets:is_element(S, SlugSet) end, Affected) of
                true  -> [Entry#{<<"news_slug">> => NewsSlug} | Acc];
                false -> Acc
            end
        end, [], News).

%% Every compiled news note, unfiltered by relevance to any one card — the homepage
%% ticker's data source (kb-news-feature.md "Homepage ticker", 2026-07-08). Global
%% KB content, no card/tenant scoping (same posture as rules/0). Sorted newest
%% authored_date first so the ticker reads as "what's new," not compiler-map
%% insertion order.
-spec all_news() -> [map()].
all_news() ->
    News = maps:get(<<"news">>, artifact(), #{}),
    Entries = maps:fold(
        fun(NewsSlug, Entry, Acc) -> [Entry#{<<"news_slug">> => NewsSlug} | Acc] end,
        [], News),
    lists:sort(
        fun(A, B) ->
            maps:get(<<"authored_date">>, A, <<>>) >= maps:get(<<"authored_date">>, B, <<>>)
        end, Entries).

%% Every fill across all KB docs merged into one leaf -> rule map, the form the
%% resolver interprets (fh_engine_resolver). Refs resolve globally across docs;
%% a leaf filled by more than one doc takes the last (matching the executable spec
%% tests/resolver_eval.py load_rules — multi-fill leaves like eligibility.fhog.*
%% are reconciled by the eligibility component, not the raw interpreter).
-spec rules() -> #{binary() => map()}.
rules() ->
    Kb = maps:get(<<"kb">>, artifact()),
    maps:fold(
        fun(_Slug, Entry, Acc) ->
            Cj = maps:get(<<"content_json">>, Entry, #{}),
            lists:foldl(fun merge_fill/2, Acc, maps:get(<<"fills">>, Cj, []))
        end, #{}, Kb).

merge_fill(Fill, Acc) ->
    case {maps:get(<<"leaf">>, Fill, undefined), maps:get(<<"rule">>, Fill, undefined)} of
        {undefined, _} -> Acc;
        {_, undefined} -> Acc;
        {Leaf, Rule}   -> Acc#{Leaf => Rule}
    end.

%% --- registry (the materialized resolver-input surface) ---------------------

%% A blueprint's materialized registry (architecture §11.9 "the registry is
%% per-blueprint"): outcome_fields, outcome_types, applicant_fields, entities,
%% param_slots, leaves. The runtime selects the card's blueprint and reads ITS
%% registry — outcome-type names collide across modes (`disposition`: [exempt,…]
%% vs [computed,…]), so there is no single global registry. A blueprint outside the
%% in-scope set carries no registry → crashes loudly here (it is never planned, by
%% construction; fail-closed beats a silent wrong-registry validation).
-spec registry(binary()) -> map().
registry(BlueprintSlug) ->
    {ok, Bp} = blueprint(BlueprintSlug),
    maps:get(<<"registry">>, Bp).

-spec registry(binary(), binary()) -> term().
registry(BlueprintSlug, Section) ->
    maps:get(Section, registry(BlueprintSlug)).

%% --- internals --------------------------------------------------------------

artifact() ->
    persistent_term:get(?PT_KEY).

qualify(Prefix, Slug) ->
    PrefixDot = <<Prefix/binary, ".">>,
    Plen = byte_size(PrefixDot),
    case Slug of
        <<P:Plen/binary, _/binary>> when P =:= PrefixDot -> Slug;
        _ -> <<PrefixDot/binary, Slug/binary>>
    end.
