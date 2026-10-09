-module(fh_engine_suburb_snapshot).

%% Reproducible -> P-2 · The database is the single source of truth -> The engine -> the suburb snapshot loaded at boot
%% The map home reads the global `suburbs` table (fh_engine_h_suburbs). The build
%% adapters (engine/build/suburbs) fill it through ENGINE_DATABASE_URL, which the prod
%% engine's App Platform dev database does not expose outside the app, so their output
%% ships with the engine as priv/suburbs/ (scripts/export_suburbs.py) and the engine
%% loads it here, at boot after migrations, WHEN THE SHIPPED SNAPSHOT DIFFERS from the
%% one last loaded: the sha256 of both files is recorded in `reference_snapshots`
%% (migration 009). An empty table, or one filled by an older snapshot (or by none
%% recorded — prod's first fill predates 009), takes the shipped rows by an upsert on
%% sal_code; the same snapshot never rewrites a row, so a reboot is a no-op (behavior
%% 37, 2026-10-09: SEIFA deciles reached a prod table that was already filled).
%% A dev stack that ran the adapters after the snapshot was taken is overwritten by the
%% snapshot on its next boot only if the snapshot changed — re-export after an adapter
%% run (export_suburbs.py) keeps the two the same. Rows absent from a newer snapshot
%% are left in place (SAL codes are stable within an ASGS edition).
%% One transaction: sources, suburbs, the sha row — all or none.
%% No snapshot in priv (a test build) -> a no-op.

-export([load/0]).

-define(COLS, "sal_code, name, state, lga_name, is_capital_city, centroid_lat, "
              "centroid_lon, facts_jsonb, provenance_jsonb, boundary_jsonb").
-define(SET, "name = EXCLUDED.name, state = EXCLUDED.state, lga_name = EXCLUDED.lga_name, "
             "is_capital_city = EXCLUDED.is_capital_city, centroid_lat = EXCLUDED.centroid_lat, "
             "centroid_lon = EXCLUDED.centroid_lon, facts_jsonb = EXCLUDED.facts_jsonb, "
             "provenance_jsonb = EXCLUDED.provenance_jsonb, "
             "boundary_jsonb = EXCLUDED.boundary_jsonb, updated_at = now()").

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
            {ok, Gz} = file:read_file(SubFile),
            {ok, Sources} = file:read_file(SrcFile),
            Sha = binary:encode_hex(crypto:hash(sha256, [Gz, Sources]), lowercase),
            case recorded_sha() of
                Sha ->
                    logger:notice("suburb snapshot: ~s already loaded — skipped", [Sha]),
                    ok;
                _ ->
                    upsert(Gz, Sources, Sha)
            end
    end.

upsert(Gz, Sources, Sha) ->
    T0 = erlang:monotonic_time(millisecond),
    Suburbs = zlib:gunzip(Gz),
    Result = pgo:transaction(fun() ->
        #{rows := [{Before}]} = pgo:query(<<"SELECT count(*) FROM suburbs">>, []),
        #{command := insert} = pgo:query(
            <<"INSERT INTO suburb_sources SELECT * FROM "
              "jsonb_populate_recordset(NULL::suburb_sources, $1::text::jsonb) "
              "ON CONFLICT (source_id) DO UPDATE SET name = EXCLUDED.name, "
              "publisher = EXCLUDED.publisher, license = EXCLUDED.license, "
              "attribution = EXCLUDED.attribution, redistribution = EXCLUDED.redistribution, "
              "cadence = EXCLUDED.cadence, url = EXCLUDED.url, notes = EXCLUDED.notes">>,
            [Sources]),
        #{command := insert, num_rows := Rows} = pgo:query(
            %% Columns named: a key absent from the JSON (updated_at, stamped here) would
            %% otherwise insert NULL, not the column default.
            <<"INSERT INTO suburbs (" ?COLS ") SELECT " ?COLS " FROM "
              "jsonb_populate_recordset(NULL::suburbs, $1::text::jsonb) "
              "ON CONFLICT (sal_code) DO UPDATE SET " ?SET>>, [Suburbs]),
        #{command := insert} = pgo:query(
            <<"INSERT INTO reference_snapshots (name, sha256, row_count) "
              "VALUES ('suburbs', $1, $2) ON CONFLICT (name) DO UPDATE SET "
              "sha256 = EXCLUDED.sha256, row_count = EXCLUDED.row_count, loaded_at = now()">>,
            [Sha, Rows]),
        {Before, Rows}
    end),
    case Result of
        {Before, Rows} when is_integer(Rows) ->
            Verb = case Before of 0 -> "loaded"; _ -> "refreshed" end,
            logger:notice("suburb snapshot: ~s ~B suburbs in ~B ms (~s)",
                          [Verb, Rows, erlang:monotonic_time(millisecond) - T0, Sha]),
            ok;
        Other ->
            error({suburb_snapshot_failed, Other})
    end.

recorded_sha() ->
    case pgo:query(<<"SELECT sha256 FROM reference_snapshots WHERE name = 'suburbs'">>, []) of
        #{rows := [{Sha}]} -> Sha;
        #{rows := []} -> none
    end.
