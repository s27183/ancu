-module(fh_engine_suburb_snapshot).

%% Reproducible -> P-2 · The database is the single source of truth -> The engine -> the suburb snapshot loaded at boot
%% The map home reads the global `suburbs` table (fh_engine_h_suburbs). The build
%% adapters (engine/build/suburbs) fill it through ENGINE_DATABASE_URL, which the prod
%% engine's App Platform dev database does not expose outside the app, so their output
%% ships with the engine as priv/suburbs/ (scripts/export_suburbs.py) and the engine
%% inserts it here, at boot after migrations, ONLY when `suburbs` is empty: a filled
%% table — prod after its first boot, the dev stack after an adapter run — is never
%% touched, so a reboot rewrites nothing and adapter data is never clobbered by an
%% older file (behavior 37, 2026-10-09). Refreshing a filled table is not done here.
%% One transaction: sources, then suburbs via jsonb_populate_recordset — all or none.
%% No snapshot in priv (a test build) -> a no-op.

-export([load/0]).

-define(COLS, "sal_code, name, state, lga_name, is_capital_city, centroid_lat, "
              "centroid_lon, facts_jsonb, provenance_jsonb, boundary_jsonb").

-spec load() -> ok.
load() ->
    Dir = filename:join(code:priv_dir(fh_engine), "suburbs"),
    SubFile = filename:join(Dir, "suburbs.json.gz"),
    SrcFile = filename:join(Dir, "suburb_sources.json"),
    case filelib:is_regular(SubFile) andalso filelib:is_regular(SrcFile) of
        false ->
            logger:notice("suburb snapshot: none in priv — skipped"),
            ok;
        true ->
            case count(<<"SELECT count(*) FROM suburbs">>) of
                0 -> insert(SubFile, SrcFile);
                N -> logger:notice("suburb snapshot: suburbs holds ~B rows — not loaded", [N]),
                     ok
            end
    end.

insert(SubFile, SrcFile) ->
    T0 = erlang:monotonic_time(millisecond),
    {ok, Gz} = file:read_file(SubFile),
    Suburbs = zlib:gunzip(Gz),
    {ok, Sources} = file:read_file(SrcFile),
    Result = pgo:transaction(fun() ->
        #{command := insert} = pgo:query(
            <<"INSERT INTO suburb_sources SELECT * FROM "
              "jsonb_populate_recordset(NULL::suburb_sources, $1::text::jsonb) "
              "ON CONFLICT (source_id) DO NOTHING">>, [Sources]),
        #{command := insert, num_rows := Rows} = pgo:query(
            %% Columns named: a key absent from the JSON (updated_at, stamped here) would
            %% otherwise insert NULL, not the column default.
            <<"INSERT INTO suburbs (" ?COLS ") SELECT " ?COLS " FROM "
              "jsonb_populate_recordset(NULL::suburbs, $1::text::jsonb)">>, [Suburbs]),
        Rows
    end),
    case Result of
        Rows when is_integer(Rows) ->
            logger:notice("suburb snapshot: loaded ~B suburbs in ~B ms",
                          [Rows, erlang:monotonic_time(millisecond) - T0]),
            ok;
        Other ->
            error({suburb_snapshot_failed, Other})
    end.

count(Sql) ->
    #{rows := [{N}]} = pgo:query(Sql, []),
    N.
