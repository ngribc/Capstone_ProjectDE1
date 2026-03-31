-- tests/singular/assert_dim_product_has_20_rows.sql
-- FakeStore has exactly 20 products. dim_product must have exactly 20 rows.
-- Fails if the API returned fewer products or if dedup removed valid rows.

SELECT
    COUNT(*) AS actual_count,
    20       AS expected_count,
    'dim_product does not have exactly 20 products' AS reason
FROM {{ ref('dim_product') }}
HAVING COUNT(*) != 20
