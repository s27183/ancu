-- 008_fx_rates.sql — FirstHomey web shell: the Reserve Bank's AUD exchange rates (behavior
-- 123, Son 2026-10-18: /facts shows 1 AUD in VND and USD with the RBA's date).
--
-- One row per RBA date (rba_date, the feed's cb:period), written by fh_shell_h_fx when a
-- GET /api/fx finds the newest row's checked_at more than a day old and the feed reads
-- cleanly. The newest row is what /api/fx serves; an older one is kept, never rewritten.
--
-- * vnd, usd: 1 AUD in that currency, as the feed printed it (17970, 0.6947).
-- * source: the RBA page the rate cites (the item's link, fragment dropped);
--   feed_url: where this row was read (FH_FX_FEED_URL), so a dev fixture's row is told
--   apart from a live one.
-- * fetched_at: when the row was first written. checked_at: when the feed last returned
--   this date as its newest; a read on a weekend (no new date) only moves checked_at, so
--   the next read waits another day.
--
-- Way back: DROP TABLE fx_rates;
--
-- Conventions carried from 001-007: forward-only; NO in-file BEGIN/COMMIT (the runner
-- wraps the file in one pgo:transaction).

CREATE TABLE fx_rates (
    rba_date   date        PRIMARY KEY,
    vnd        numeric     NOT NULL CHECK (vnd > 0),
    usd        numeric     NOT NULL CHECK (usd > 0),
    source     text        NOT NULL,
    feed_url   text        NOT NULL,
    fetched_at timestamptz NOT NULL DEFAULT now(),
    checked_at timestamptz NOT NULL DEFAULT now()
);
