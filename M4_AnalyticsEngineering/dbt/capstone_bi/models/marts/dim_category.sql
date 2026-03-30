{{ config(materialized='table') }}
SELECT
    ROW_NUMBER() OVER (ORDER BY category)  AS category_id,
    category                               AS category_name,
    REPLACE(category, ' ', '_')           AS category_slug,
    COUNT(*)                               AS total_products,
    ROUND(AVG(price_usd), 2)              AS avg_price_usd,
    CURRENT_TIMESTAMP                      AS dbt_updated_at
FROM {{ ref('stg_products') }}
WHERE category IS NOT NULL
GROUP BY category
