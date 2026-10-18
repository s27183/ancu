-- 009_fx_bank_quotes.sql — FirstHomey web shell: a Vietnamese bank's AUD buy and sell
-- quote (behavior 130, Son 2026-10-18: /facts shows what Vietcombank buys and sells 1 AUD
-- for, beside the Reserve Bank's rate, labelled as a bank's reference price).
--
-- One row per quote time (bank, quoted_at), written by fh_shell_vcb when a GET /api/fx
-- finds the newest row's checked_at more than an hour old and the bank's XML reads
-- cleanly. The newest row is what /api/fx serves under `bank`; an older one is kept.
--
-- * quoted_at: the board's <DateTime>, Vietnam time (UTC+7), stored as an instant.
-- * buy_cash, buy_transfer, sell: VND for 1 AUD, as the board printed them without the
--   thousands commas (17558.08, 17735.44, 18303.86).
-- * source: the bank's rate page the quote cites; feed_url: where this row was read
--   (FH_VCB_FEED_URL), so a dev fixture's row is told apart from a live one.
-- * fetched_at: when the row was first written. checked_at: when the board last showed
--   this quote as its newest; an unchanged board only moves checked_at.
--
-- Way back: DROP TABLE fx_bank_quotes;
--
-- Conventions carried from 001-008: forward-only; NO in-file BEGIN/COMMIT (the runner
-- wraps the file in one pgo:transaction).

CREATE TABLE fx_bank_quotes (
    bank         text        NOT NULL,
    quoted_at    timestamptz NOT NULL,
    buy_cash     numeric     NOT NULL CHECK (buy_cash > 0),
    buy_transfer numeric     NOT NULL CHECK (buy_transfer > 0),
    sell         numeric     NOT NULL CHECK (sell > 0),
    source       text        NOT NULL,
    feed_url     text        NOT NULL,
    fetched_at   timestamptz NOT NULL DEFAULT now(),
    checked_at   timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (bank, quoted_at)
);
