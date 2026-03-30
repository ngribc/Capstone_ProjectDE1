-- models/marts/dim_category.sql
-- Gold: dimensión de categorías derivada de productos

{{ config(materialized='table') }}

SELECT
    ROW_NUMBER() OVER (ORDER BY category) AS category_id,
    category                              AS category_name,
    REPLACE(category, ' ', '_')          AS category_slug
FROM (
    SELECT DISTINCT category
    FROM {{ ref('stg_products') }}
    WHERE category IS NOT NULL
)
