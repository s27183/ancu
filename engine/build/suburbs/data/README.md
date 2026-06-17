# Staged build-time inputs

Some suburb adapters read a **human-staged file** instead of a live pull — when the
source is bot-walled or only offers a manual download (see the fetch-mechanism step in
[`../../../docs/architecture/suburb-adapter-workflow.md`](../../../docs/architecture/suburb-adapter-workflow.md)).
Drop the file(s) named below into this directory, then run the adapter.

| File(s) | Adapter | Source | In git? |
|---|---|---|---|
| `vpsr-median-house.xls`, `vpsr-median-unit.xls` | `vic_vpsr` (VIC price) | Victorian Property Sales Report (DTP) | **committed** — small + Cloudflare-walled (non-refetchable) |
| `lsg_stats_<YYYY>_q<N>.xlsx` | `sa_metro_price` (SA price) | Metro Median House Sales (SA DHUD) | **committed** — small + data.sa.gov.au walls automation (non-refetchable) |
| `Data_Tables_LGA_Recorded_Offences_Year_Ending_*.xlsx` | `csa_vic` (VIC crime) | Crime Statistics Agency Victoria | **gitignored** — 18 MB + refetchable (see below) |
| `division_Reported_Offences_Number.csv` | `qps` (QLD crime) | Queensland Police Service | **gitignored** — 21 MB + refetchable (see below) |

## CSA Victoria crime — how to refetch

The adapter reads sheet **`Table 03`** (Offences recorded by offence type, LGA, and
postcode or suburb/town) from the **LGA Recorded Offences** workbook.

1. Go to the CSA "Download data" page (load in a browser — the HTML index is UA-filtered):
   <https://www.crimestatistics.vic.gov.au/crime-statistics/latest-victorian-crime-data/download-data>
2. Download **"Data Tables LGA Recorded Offences — Year Ending <Month> <Year>"** (`.xlsx`).
   The file host itself is open; the current direct URL has the form
   `https://files.crimestatistics.vic.gov.au/<release-month>/Data_Tables_LGA_Recorded_Offences_Year_Ending_<Month>_<Year>.xlsx`
   (e.g. year ending December 2025 → `…/2026-03/Data_Tables_LGA_Recorded_Offences_Year_Ending_December_2025.xlsx`).
3. Save it into this directory. The adapter globs `Data_Tables_LGA_Recorded_Offences_*.xlsx`
   and takes the latest year-ending-December window it finds.

Licence: CC BY 4.0 — © State of Victoria (Crime Statistics Agency).

## QLD Police crime — how to refetch

The adapter reads offence counts by **police division** (not suburb — QPS publishes no
suburb-level data), monthly.

1. Open the dataset (the portal is behind an AWS WAF challenge — load it in a browser):
   <https://www.data.qld.gov.au/dataset/offence-numbers-police-divisions-monthly-from-july-2001>
2. Download the CSV resource (`division_Reported_Offences_Number.csv`, ~21 MB) into this directory.
3. The adapter takes the trailing 12 months ending at the latest month in the file and sums the
   three top-level QPS categories (Person + Property + Other) per division.

Licence: CC BY 4.0 — © State of Queensland (Queensland Police Service).

## SA metro median house price — how to refetch

The adapter reads sheet **`Sheet1`** (one row per suburb; columns `City | Suburb |
Sales/Median <prior-Q> | Sales/Median <latest-Q> | Median Change`), metro Adelaide only.

1. Open the dataset (data.sa.gov.au refuses curl/scripts — **load it in a browser**):
   <https://data.sa.gov.au/data/dataset/metro-median-house-sales>
2. Download the **latest quarter's XLSX** (`lsg_stats_<YYYY>_q<N>.xlsx`) into this directory.
   (Resolve resource download URLs programmatically via the data.gov.au CKAN harvester —
   `https://data.gov.au/data/api/3/action/package_show?id=metro-median-house-sales` —
   since the SA portal HTML/API is walled.)
3. The adapter globs `lsg_stats_*.xlsx`, takes the lexically-latest, and reads the latest
   `Median <q>Q <year>` column (discovered by header text) + its paired sales count.

Licence: **CC BY 3.0 AU** — © Government of South Australia (Department for Housing and
Urban Development). House-only; no free regional-SA equivalent (those suburbs keep null).
