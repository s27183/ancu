"""Build-time suburb-data adapters (docs/architecture/suburb-data-foundation.md §6).

Each adapter fetches a gov feed, transforms it to a field-subset, and merge-upserts
into the engine `suburbs` table (migration 003) with per-field provenance. The
upsert is shared (`db.upsert_facts`) so adapters never clobber each other's fields;
only fetch+transform differs per source. Reference data — the third bucket
([[build-time-structure-vs-runtime-data]]): global (no tenant), feed-cadence refresh.
"""
