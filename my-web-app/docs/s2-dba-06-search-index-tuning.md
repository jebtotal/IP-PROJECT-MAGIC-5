# S2-DBA-06: Customer/Product search index tuning

## Application query shapes

`api_list_records` in `app.py` selects all requested columns from
`customer_active` or `product_active`; the active views apply `NOT is_deleted`.
The search string is then matched against the configured business columns in
Python. Name, address, code, description, payment-term, and unit indexes cannot
accelerate that substring search without changing the app to filter in SQL.
The administrator's Inactive tab instead selects the base table with
`is_deleted = true`.

The primary keys already index `customer.custno` and `product.prodcode`. The
S2-DBA-06 migration adds only small, partial B-tree indexes on those keys for
inactive rows. It does not duplicate the primary-key indexes or add indexes
for the active-list fetch or Python-side text search.

## Scratch benchmark

The benchmark used PostgreSQL 18.7 through local PGlite (WebAssembly), without
the team's database or credentials. The existing base/sample-data, audit,
active-view, price-as-of, and validation migrations were applied to a fresh
in-memory database. The test copied the sample Customer/Product rows into
temporary tables and generated 5,000 fake rows per entity (1% marked
soft-deleted); generated rows, tables, and candidate indexes were temporary.
The benchmark contained 5,082 Customer rows (50 inactive) and 5,057 Product
rows (50 inactive), including the checked-in sample rows.
The benchmark query projections and filters match the API list selects. The
`EXPLAIN (ANALYZE, BUFFERS)` script is
`supabase/tests/s2_dba_06_customer_product_index_benchmark.sql`.

For each query, execution time is the median of nine `EXPLAIN ANALYZE` runs
after two warm-ups. Plans were sequential scans before the candidate indexes.
Afterward, active-list plans remained sequential scans, while inactive-filter
plans became index scans:

| Query | Plan before | Median before | Plan after | Median after |
| --- | --- | ---: | --- | ---: |
| Active Customer list | Seq Scan | 3.006 ms | Seq Scan | 1.477 ms |
| Active Product list | Seq Scan | 1.478 ms | Seq Scan | 1.444 ms |
| Inactive Customer filter | Seq Scan | 0.506 ms | Index Scan | 0.027 ms |
| Inactive Product filter | Seq Scan | 0.288 ms | Index Scan | 0.030 ms |

Before tuning, the Customer/Product indexes were their primary-key indexes
(`custno` and `prodcode`). After tuning, the catalog also contained
`customer_inactive_list_idx ON customer (custno) WHERE is_deleted` and
`product_inactive_list_idx ON product (prodcode) WHERE is_deleted`.

The active-list timing variation is noise; its plan and returned row count did
not improve, so no active-row or text-search index was added. The inactive
filters returned 50 of about 5,000 rows and used the partial indexes after
tuning. These timings are engine-local comparative results, not a prediction
of native Supabase latency. Re-run the scratch script with representative data
and `EXPLAIN (ANALYZE, BUFFERS)` on the target PostgreSQL version before
extrapolating production timings.

## Fresh-database verification

The relevant schema and S2 migrations were applied successfully in order on
the fresh in-memory PostgreSQL database. The new migration is idempotent and
should be applied after `20261122000600_s2_dba_03_validation_constraints.sql`.
Run it twice on a scratch database, then execute the benchmark SQL script.
The script uses temporary tables and rolls its test state back. No live-team
database, application code, or real data was used or changed.
