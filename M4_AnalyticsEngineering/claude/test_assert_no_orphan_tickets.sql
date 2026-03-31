-- tests/singular/assert_no_orphan_tickets.sql
-- Singular test: every ticket in fact_sales_support must have
-- a matching product in dim_product AND a matching category in dim_category.
-- Returns rows that FAIL (orphans). dbt fails if any rows returned.

SELECT
    f.ticket_id,
    f.product_id,
    f.category_id,
    f.snapshot_month,
    CASE
        WHEN p.product_id  IS NULL THEN 'missing dim_product'
        WHEN c.category_id IS NULL THEN 'missing dim_category'
    END AS orphan_reason

FROM {{ ref('fact_sales_support') }} f

LEFT JOIN {{ ref('dim_product') }}  p ON f.product_id  = p.product_id
LEFT JOIN {{ ref('dim_category') }} c ON f.category_id = c.category_id

WHERE p.product_id IS NULL
   OR c.category_id IS NULL
