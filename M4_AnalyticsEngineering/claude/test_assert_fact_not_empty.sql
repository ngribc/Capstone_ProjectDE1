-- tests/singular/assert_fact_not_empty.sql
-- Singular test: fact_sales_support must have at least 1 row after each run.
-- Catches silent pipeline failures where data was not loaded.

SELECT 'fact_sales_support is empty — pipeline may have failed' AS reason
WHERE (SELECT COUNT(*) FROM {{ ref('fact_sales_support') }}) = 0
